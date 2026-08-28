import 'package:universal_io/io.dart' as io;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/colors.dart';
import '../../../core/services/document_storage_service.dart';
import '../../property/domain/property.dart';
import '../../property/data/property_repository.dart';
import '../../auth/data/auth_providers.dart';
import '../domain/maintenance_request.dart';
import '../data/maintenance_repository.dart';

class CreateMaintenanceRequestScreen extends ConsumerStatefulWidget {
  final Property property;

  const CreateMaintenanceRequestScreen({super.key, required this.property});

  @override
  ConsumerState<CreateMaintenanceRequestScreen> createState() => _CreateMaintenanceRequestScreenState();
}

class _CreateMaintenanceRequestScreenState extends ConsumerState<CreateMaintenanceRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _costController = TextEditingController();

  late String _selectedCurrency;
  String? _paidBy;
  String? _paymentStatus;
  DateTime? _paymentDate;
  PlatformFile? _selectedInvoiceFile;

  MaintenanceCategory? _selectedCategory;
  MaintenancePriority _selectedPriority = MaintenancePriority.normal;
  bool _isLoading = false;
  List<PlatformFile> _selectedFiles = [];

  @override
  void initState() {
    super.initState();
    final initialCur = widget.property.currency.isNotEmpty ? widget.property.currency : 'EUR';
    _selectedCurrency = (initialCur.toUpperCase() == 'RSD') ? 'RSD' : 'EUR';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _costController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    if (_selectedFiles.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('En fazla 5 fotoğraf ekleyebilirsiniz.'),
          backgroundColor: Color(0xFFE11D48),
        ),
      );
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );

    if (result != null) {
      setState(() {
        final remaining = 5 - _selectedFiles.length;
        final toAdd = result.files.take(remaining).toList();
        _selectedFiles = [..._selectedFiles, ...toAdd];
      });
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  Future<void> _pickInvoicePdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedInvoiceFile = result.files.first;
      });
    }
  }

  void _removeInvoiceFile() {
    setState(() {
      _selectedInvoiceFile = null;
    });
  }

  Future<void> _selectPaymentDate(BuildContext context) async {
    final initial = _paymentDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _paymentDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    final loc = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            loc.localeName == 'tr'
                ? 'Lütfen bir sorun kategorisi seçiniz.'
                : (loc.localeName == 'ru'
                    ? 'Пожалуйста, выберите категорию проблемы.'
                    : (loc.localeName.startsWith('sr')
                        ? 'Molimo izaberite kategoriju problema.'
                        : 'Please select an issue category.')),
          ),
          backgroundColor: const Color(0xFFE11D48),
        ),
      );
      return;
    }

    // Validate cost amount if entered
    double? costAmount;
    final costText = _costController.text.trim().replaceAll(',', '.');
    if (costText.isNotEmpty) {
      costAmount = double.tryParse(costText);
      if (costAmount == null || costAmount < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.errorWithDetails('Invalid cost amount')),
            backgroundColor: const Color(0xFFE11D48),
          ),
        );
        return;
      }
    }

    final user = ref.read(currentUserProvider);
    final userProfileAsync = user?.id != null
        ? ref.read(profileProvider(user!.id))
        : const AsyncValue<Map<String, dynamic>?>.data(null);
    final profileRole = userProfileAsync.value?['role'] as String? ??
        user?.userMetadata?['role'] as String?;

    final isLandlord = widget.property.landlordId == user?.id || profileRole == 'landlord';
    final isAgency = widget.property.agencyId == user?.id || profileRole == 'agency';
    final isTenant = widget.property.tenantId == user?.id ||
        profileRole == 'tenant' ||
        (!isLandlord && !isAgency);

    if (!isTenant && costAmount != null && costAmount > 0) {
      if (_paidBy == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.pleaseSelectCostPayer),
            backgroundColor: const Color(0xFFE11D48),
          ),
        );
        return;
      }
      if (_paymentStatus == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.pleaseSelectDeclarationIntent),
            backgroundColor: const Color(0xFFE11D48),
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      final activeContract = await ref.read(activeContractProvider(widget.property.id).future);
      final tempRequestId = DateTime.now().millisecondsSinceEpoch.toString();

      // 1. Upload photos first
      final List<String> uploadedUrls = [];
      final isCloudAllowed = ref.read(cloudUploadAllowedProvider);
      for (var file in _selectedFiles) {
        List<int>? fileBytes = file.bytes?.toList();
        if (fileBytes == null && !kIsWeb && file.path != null) {
          fileBytes = await io.File(file.path!).readAsBytes();
        }

        if (fileBytes != null) {
          final String url;
          if (isCloudAllowed) {
            url = await ref.read(maintenanceRepositoryProvider).uploadMaintenancePhoto(
                  requestId: tempRequestId,
                  fileName: file.name,
                  bytes: Uint8List.fromList(fileBytes),
                );
          } else {
            final io.File localFile;
            if (!kIsWeb && file.path != null) {
              localFile = io.File(file.path!);
            } else {
              final tempDir = await getTemporaryDirectory();
              localFile = io.File('${tempDir.path}/${file.name}');
              await localFile.writeAsBytes(fileBytes);
            }
            url = await ref.read(documentStorageServiceProvider).saveDocument(localFile);
          }
          uploadedUrls.add(url);
        }
      }

      // 2. Upload Invoice PDF if selected
      String? invoicePdfUrl;
      if (_selectedInvoiceFile != null) {
        List<int>? invoiceBytes = _selectedInvoiceFile!.bytes?.toList();
        if (invoiceBytes == null && !kIsWeb && _selectedInvoiceFile!.path != null) {
          invoiceBytes = await io.File(_selectedInvoiceFile!.path!).readAsBytes();
        }
        if (invoiceBytes != null) {
          invoicePdfUrl = await ref.read(maintenanceRepositoryProvider).uploadMaintenanceInvoice(
                propertyId: widget.property.id,
                requestId: tempRequestId,
                fileName: _selectedInvoiceFile!.name,
                bytes: Uint8List.fromList(invoiceBytes),
              );
        }
      }

      // 3. Create the request with financial fields
      final user = ref.read(currentUserProvider);
      final userProfileAsync = user?.id != null
          ? ref.read(profileProvider(user!.id))
          : const AsyncValue<Map<String, dynamic>?>.data(null);
      final profileRole = userProfileAsync.value?['role'] as String? ??
          user?.userMetadata?['role'] as String?;

      final isLandlord = widget.property.landlordId == user?.id || profileRole == 'landlord';
      final isAgency = widget.property.agencyId == user?.id || profileRole == 'agency';
      final isTenant = widget.property.tenantId == user?.id ||
          profileRole == 'tenant' ||
          (!isLandlord && !isAgency);

      final double? finalCostAmount = isTenant ? null : costAmount;
      final String? finalCurrency =
          (isTenant || finalCostAmount == null) ? null : _selectedCurrency;
      final String? finalPaidBy = isTenant ? null : _paidBy;
      final DateTime? finalPaymentDate = isTenant ? null : _paymentDate;
      final String finalPaymentStatus = isTenant ? 'pending_review' : (_paymentStatus ?? 'pending_review');
      final String? finalInvoicePdfUrl = isTenant ? null : invoicePdfUrl;

      await ref.read(maintenanceRepositoryProvider).createRequest(
            propertyId: widget.property.id,
            title: _titleController.text.trim(),
            category: _selectedCategory!,
            priority: _selectedPriority,
            description: _descriptionController.text.trim(),
            contractId: activeContract?.id,
            photosUrls: uploadedUrls,
            costAmount: finalCostAmount,
            currency: finalCurrency,
            paidBy: finalPaidBy,
            paymentDate: finalPaymentDate,
            paymentStatus: finalPaymentStatus,
            invoicePdfUrl: finalInvoicePdfUrl,
          );

      // Invalidate the provider so the list refreshes immediately
      ref.invalidate(maintenanceRequestsProvider(widget.property.id));

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.maintenanceRequestSuccess)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.errorWithDetails(e.toString())),
            backgroundColor: const Color(0xFFE11D48),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);
    final userProfileAsync = user?.id != null
        ? ref.watch(profileProvider(user!.id))
        : const AsyncValue<Map<String, dynamic>?>.data(null);
    final profileRole = userProfileAsync.value?['role'] as String? ??
        user?.userMetadata?['role'] as String?;

    final isLandlord = widget.property.landlordId == user?.id || profileRole == 'landlord';
    final isAgency = widget.property.agencyId == user?.id || profileRole == 'agency';
    final isTenant = widget.property.tenantId == user?.id ||
        profileRole == 'tenant' ||
        (!isLandlord && !isAgency);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  // 1. Dynamic Hero Header with Back Button and Property Context
                  SliverToBoxAdapter(
                    child: _CreateMaintenanceHeader(
                      property: widget.property,
                    ),
                  ),

                  // 2. Form Body
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── A. Category Selector (Visual Cards) ──
                            _buildSectionLabel(
                              icon: LucideIcons.layers,
                              title: loc.categorySelectorTitle,
                              isRequired: true,
                            ),
                            const SizedBox(height: 10),
                            _VisualCategorySelector(
                              selectedCategory: _selectedCategory,
                              onSelectCategory: (cat) => setState(() => _selectedCategory = cat),
                            ),
                            const SizedBox(height: 24),

                            // ── B. Priority Selector (Segmented Cards) ──
                            _buildSectionLabel(
                              icon: LucideIcons.shieldAlert,
                              title: loc.prioritySelectorTitle,
                              isRequired: true,
                            ),
                            const SizedBox(height: 10),
                            _SegmentedPrioritySelector(
                              selectedPriority: _selectedPriority,
                              onSelectPriority: (p) => setState(() => _selectedPriority = p),
                            ),
                            const SizedBox(height: 24),

                            // ── C. Issue Title & Description ──
                            _buildSectionLabel(
                              icon: LucideIcons.fileText,
                              title: loc.issueTitle,
                              isRequired: true,
                            ),
                            const SizedBox(height: 8),
                            _buildTitleInput(loc),
                            const SizedBox(height: 20),

                            _buildSectionLabel(
                              icon: LucideIcons.alignLeft,
                              title: loc.issueDescription,
                              isRequired: false,
                            ),
                            const SizedBox(height: 8),
                            _buildDescriptionInput(loc),
                            const SizedBox(height: 24),

                            // ── D. Photo Attachments Tray ──
                            _buildSectionLabel(
                              icon: LucideIcons.camera,
                              title: loc.photos,
                              subtitle: loc.photosSubtitle,
                              isRequired: false,
                            ),
                            const SizedBox(height: 10),
                            _PhotoAttachmentDropzone(
                              selectedFiles: _selectedFiles,
                              onPickImages: _pickImages,
                              onRemoveFile: _removeFile,
                            ),

                            // ── E. Financial Section (Landlord & Agency Only) ──
                            if (!isTenant) ...[
                              const SizedBox(height: 28),
                              _CreateMaintenanceFinancialCard(
                                costController: _costController,
                                selectedCurrency: _selectedCurrency,
                                onCurrencyChanged: (cur) => setState(() => _selectedCurrency = cur),
                                paidBy: _paidBy,
                                onPaidByChanged: (payer) => setState(() {
                                  _paidBy = payer;
                                  _paymentStatus = null;
                                }),
                                paymentStatus: _paymentStatus,
                                onPaymentStatusChanged: (status) => setState(() => _paymentStatus = status),
                                paymentDate: _paymentDate,
                                onSelectPaymentDate: () => _selectPaymentDate(context),
                                onClearPaymentDate: () => setState(() => _paymentDate = null),
                                selectedInvoiceFile: _selectedInvoiceFile,
                                onPickInvoicePdf: _pickInvoicePdf,
                                onRemoveInvoiceFile: _removeInvoiceFile,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Sticky Bottom Submit Action ──
            _buildBottomSubmitBar(loc),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool isRequired,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: const Color(0xFF0F766E)),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.2,
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(
                  color: Color(0xFFE11D48),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11.5,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTitleInput(AppLocalizations loc) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: _titleController,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0F172A),
        ),
        decoration: InputDecoration(
          hintText: loc.issueTitleHint,
          hintStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.normal,
            color: Color(0xFF94A3B8),
          ),
          prefixIcon: const Icon(LucideIcons.penLine, size: 18, color: Color(0xFF64748B)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        ),
        validator: (val) => val == null || val.trim().isEmpty ? loc.fieldRequired : null,
      ),
    );
  }

  Widget _buildDescriptionInput(AppLocalizations loc) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: _descriptionController,
        maxLines: 4,
        style: const TextStyle(
          fontSize: 13.5,
          color: Color(0xFF0F172A),
          height: 1.4,
        ),
        decoration: InputDecoration(
          hintText: loc.issueDescriptionHint,
          hintStyle: const TextStyle(
            fontSize: 13,
            color: Color(0xFF94A3B8),
            height: 1.4,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(14),
        ),
      ),
    );
  }

  Widget _buildBottomSubmitBar(AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F766E),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              disabledBackgroundColor: const Color(0xFF0F766E).withValues(alpha: 0.6),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.send, size: 18, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        loc.sendRequestBtn,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// ── Dynamic Hero Header Component ─────────────────────────────
class _CreateMaintenanceHeader extends StatelessWidget {
  final Property property;

  const _CreateMaintenanceHeader({
    required this.property,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF064E3B),
            Color(0xFF0F766E),
            Color(0xFF115E59),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F766E).withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Ambient Background Glow
          Positioned(
            right: -25,
            top: -25,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(16, topPadding + 8, 16, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Back Button
                InkWell(
                  onTap: () => Navigator.maybePop(context),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                    ),
                    child: const Icon(LucideIcons.chevronLeft, color: Colors.white, size: 18),
                  ),
                ),
                const SizedBox(width: 10),

                // Title & Subtitle with page icon
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        loc.reportIssue,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.plusCircle,
                            size: 11,
                            color: Colors.white.withValues(alpha: 0.82),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              loc.reportIssueSubtitle,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.82),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Property Context Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.home, size: 11, color: Colors.white70),
                      const SizedBox(width: 4),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 110),
                        child: Text(
                          property.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ── Visual Category Grid Selector ──────────────────────────────
class _VisualCategorySelector extends StatelessWidget {
  final MaintenanceCategory? selectedCategory;
  final ValueChanged<MaintenanceCategory> onSelectCategory;

  const _VisualCategorySelector({
    required this.selectedCategory,
    required this.onSelectCategory,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    final categories = [
      _CategoryMeta(MaintenanceCategory.plumbing, loc.categoryPlumbing, LucideIcons.droplets, const Color(0xFF0284C7)),
      _CategoryMeta(MaintenanceCategory.electrical, loc.categoryElectrical, LucideIcons.zap, const Color(0xFFD97706)),
      _CategoryMeta(MaintenanceCategory.heating, loc.categoryHeating, LucideIcons.flame, const Color(0xFFEA580C)),
      _CategoryMeta(MaintenanceCategory.appliance, loc.categoryAppliance, LucideIcons.tv, const Color(0xFF9333EA)),
      _CategoryMeta(MaintenanceCategory.internet, loc.categoryInternet, LucideIcons.wifi, const Color(0xFF4F46E5)),
      _CategoryMeta(MaintenanceCategory.structural, loc.categoryStructural, LucideIcons.building2, const Color(0xFF475569)),
      _CategoryMeta(MaintenanceCategory.other, loc.categoryOther, LucideIcons.wrench, const Color(0xFF0F766E)),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((item) {
        final isSelected = selectedCategory == item.category;
        return InkWell(
          onTap: () => onSelectCategory(item.category),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? item.color.withValues(alpha: 0.12) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? item.color : const Color(0xFFE2E8F0),
                width: isSelected ? 1.6 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.icon,
                  size: 15,
                  color: isSelected ? item.color : const Color(0xFF64748B),
                ),
                const SizedBox(width: 7),
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? item.color : const Color(0xFF334155),
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 6),
                  Icon(LucideIcons.check, size: 13, color: item.color),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CategoryMeta {
  final MaintenanceCategory category;
  final String name;
  final IconData icon;
  final Color color;

  const _CategoryMeta(this.category, this.name, this.icon, this.color);
}

/// ── Segmented Priority Selector (Normal vs. Urgent) ────────────
class _SegmentedPrioritySelector extends StatelessWidget {
  final MaintenancePriority selectedPriority;
  final ValueChanged<MaintenancePriority> onSelectPriority;

  const _SegmentedPrioritySelector({
    required this.selectedPriority,
    required this.onSelectPriority,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isNormal = selectedPriority == MaintenancePriority.normal ||
        selectedPriority == MaintenancePriority.low ||
        selectedPriority == MaintenancePriority.medium;
    final isUrgent = selectedPriority == MaintenancePriority.urgent ||
        selectedPriority == MaintenancePriority.high;

    return Row(
      children: [
        // 1. Normal Priority
        Expanded(
          child: InkWell(
            onTap: () => onSelectPriority(MaintenancePriority.normal),
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isNormal ? const Color(0xFF0F766E).withValues(alpha: 0.1) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isNormal ? const Color(0xFF0F766E) : const Color(0xFFE2E8F0),
                  width: isNormal ? 1.6 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isNormal
                          ? const Color(0xFF0F766E).withValues(alpha: 0.18)
                          : const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.checkCircle2,
                      size: 16,
                      color: isNormal ? const Color(0xFF0F766E) : const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.priorityNormal,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isNormal ? const Color(0xFF0F766E) : const Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          loc.priorityNormalDesc,
                          style: TextStyle(
                            fontSize: 10,
                            color: isNormal ? const Color(0xFF0F766E) : const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // 2. Urgent Priority
        Expanded(
          child: InkWell(
            onTap: () => onSelectPriority(MaintenancePriority.urgent),
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUrgent ? const Color(0xFFFFF1F2) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isUrgent ? const Color(0xFFE11D48) : const Color(0xFFE2E8F0),
                  width: isUrgent ? 1.6 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isUrgent
                        ? const Color(0xFFE11D48).withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isUrgent ? const Color(0xFFFECDD3) : const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.alertTriangle,
                      size: 16,
                      color: isUrgent ? const Color(0xFFE11D48) : const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.priorityUrgent,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isUrgent ? const Color(0xFFE11D48) : const Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          loc.priorityUrgentDesc,
                          style: TextStyle(
                            fontSize: 10,
                            color: isUrgent ? const Color(0xFFE11D48) : const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// ── Multi-Photo Attachment Dropzone ────────────────────────────
class _PhotoAttachmentDropzone extends StatelessWidget {
  final List<PlatformFile> selectedFiles;
  final VoidCallback onPickImages;
  final ValueChanged<int> onRemoveFile;

  const _PhotoAttachmentDropzone({
    required this.selectedFiles,
    required this.onPickImages,
    required this.onRemoveFile,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Upload Action Button / Dropzone
        InkWell(
          onTap: onPickImages,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(LucideIcons.camera, size: 18, color: Color(0xFF0F766E)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.addPhotoFromGallery,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        loc.photosSubtitle,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${selectedFiles.length} / 5',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Photo Preview Strip
        if (selectedFiles.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: selectedFiles.length,
              itemBuilder: (context, index) {
                final file = selectedFiles[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Stack(
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: file.bytes != null
                            ? Image.memory(file.bytes!, fit: BoxFit.cover)
                            : const Center(child: Icon(LucideIcons.image, color: Color(0xFF94A3B8))),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => onRemoveFile(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black87,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(LucideIcons.x, size: 12, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

/// ── Modernized Financial Card (Landlord & Agency Only) ─────────
class _CreateMaintenanceFinancialCard extends StatelessWidget {
  final TextEditingController costController;
  final String selectedCurrency;
  final ValueChanged<String> onCurrencyChanged;
  final String? paidBy;
  final ValueChanged<String> onPaidByChanged;
  final String? paymentStatus;
  final ValueChanged<String> onPaymentStatusChanged;
  final DateTime? paymentDate;
  final VoidCallback onSelectPaymentDate;
  final VoidCallback onClearPaymentDate;
  final PlatformFile? selectedInvoiceFile;
  final VoidCallback onPickInvoicePdf;
  final VoidCallback onRemoveInvoiceFile;

  const _CreateMaintenanceFinancialCard({
    required this.costController,
    required this.selectedCurrency,
    required this.onCurrencyChanged,
    required this.paidBy,
    required this.onPaidByChanged,
    required this.paymentStatus,
    required this.onPaymentStatusChanged,
    required this.paymentDate,
    required this.onSelectPaymentDate,
    required this.onClearPaymentDate,
    required this.selectedInvoiceFile,
    required this.onPickInvoicePdf,
    required this.onRemoveInvoiceFile,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF0F766E).withValues(alpha: 0.25), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F766E).withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(LucideIcons.receipt, size: 15, color: Color(0xFF0F766E)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      loc.financialSectionTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 12),

              // 1. Tutar & Para Birimi, 2. Payment Date, 3. Ödeyecek Taraf
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // 1. Cost & Currency
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.costAmountLabel,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF334155)),
                          ),
                          const SizedBox(height: 5),
                          _buildCostInput(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 2. Payment Date
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.paymentDate,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF334155)),
                          ),
                          const SizedBox(height: 5),
                          _buildDateSelector(loc),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 3. Paid By (Payer)
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${loc.paidByLabel} *',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF334155)),
                          ),
                          const SizedBox(height: 5),
                          _buildPayerSelector(loc, paidBy),
                        ],
                      ),
                    ),
                  ],
                )
              else ...[
                // Mobile: 1. Cost & Currency
                Text(
                  loc.costAmountLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF334155)),
                ),
                const SizedBox(height: 5),
                _buildCostInput(),
                const SizedBox(height: 10),
                // Mobile: 2. Payment Date + 3. Paid By
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.paymentDate,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF334155)),
                          ),
                          const SizedBox(height: 5),
                          _buildDateSelector(loc),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${loc.paidByLabel} *',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF334155)),
                          ),
                          const SizedBox(height: 5),
                          _buildPayerSelector(loc, paidBy),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 14),

              // 4. Payment Purpose & Settlement Request
              Text(
                '${loc.settlementIntentTitle} *',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 8),

              if (paidBy == null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.info, size: 16, color: Color(0xFF64748B)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          loc.pleaseSelectCostPayer,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ),
                    ],
                  ),
                )
              else if (paidBy == 'tenant') ...[
                // Option 1 (Tenant Self Usage)
                _buildPurposeOptionCard(
                  title: loc.intentTenantSelfTitle,
                  subtitle: loc.intentTenantSelfSub,
                  badgeLabel: loc.intentTenantSelfBadge,
                  badgeColor: const Color(0xFF059669),
                  icon: LucideIcons.user,
                  isSelected: paymentStatus == 'paid',
                  onTap: () => onPaymentStatusChanged('paid'),
                ),
                const SizedBox(height: 8),
                // Option 2 (Tenant Deduct from Rent)
                _buildPurposeOptionCard(
                  title: loc.intentTenantReimburseTitle,
                  subtitle: loc.intentTenantReimburseSub,
                  badgeLabel: loc.intentTenantReimburseBadge,
                  badgeColor: const Color(0xFF2563EB),
                  icon: LucideIcons.home,
                  isSelected: paymentStatus == 'pending_payment',
                  onTap: () => onPaymentStatusChanged('pending_payment'),
                ),
              ] else ...[
                // Option 1 (Landlord Covered Fixture)
                _buildPurposeOptionCard(
                  title: loc.intentLandlordSelfTitle,
                  subtitle: loc.intentLandlordSelfSub,
                  badgeLabel: loc.intentLandlordSelfBadge,
                  badgeColor: const Color(0xFF059669),
                  icon: LucideIcons.home,
                  isSelected: paymentStatus == 'paid',
                  onTap: () => onPaymentStatusChanged('paid'),
                ),
                const SizedBox(height: 8),
                // Option 2 (Landlord Add to Rent)
                _buildPurposeOptionCard(
                  title: loc.intentLandlordTenantDueTitle,
                  subtitle: loc.intentLandlordTenantDueSub,
                  badgeLabel: loc.intentLandlordTenantDueBadge,
                  badgeColor: const Color(0xFFD97706),
                  icon: LucideIcons.user,
                  isSelected: paymentStatus == 'pending_payment',
                  onTap: () => onPaymentStatusChanged('pending_payment'),
                ),
              ],
              const SizedBox(height: 14),

              // 5. Upload Invoice
              Text(
                loc.invoicePdfLabel,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 6),
              _buildInvoiceUploader(loc),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCostInput() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(LucideIcons.circleDollarSign, size: 15, color: Color(0xFF64748B)),
          ),
          Expanded(
            child: TextFormField(
              controller: costController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                hintText: '0.00',
                hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          Container(width: 1, height: 22, color: const Color(0xFFE2E8F0)),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedCurrency,
              items: const [
                DropdownMenuItem(value: 'EUR', child: Text('EUR (€)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                DropdownMenuItem(value: 'RSD', child: Text('RSD', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
              ],
              onChanged: (val) {
                if (val != null) onCurrencyChanged(val);
              },
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayerSelector(AppLocalizations loc, String? currentPayer) {
    return Container(
      height: 40,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildPayerChip(
              label: loc.tenant,
              icon: LucideIcons.user,
              isSelected: currentPayer == 'tenant',
              activeColor: StanomerColors.tenant,
              onTap: () => onPaidByChanged('tenant'),
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: _buildPayerChip(
              label: loc.landlord,
              icon: LucideIcons.home,
              isSelected: currentPayer == 'landlord',
              activeColor: StanomerColors.landlord,
              onTap: () => onPaidByChanged('landlord'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector(AppLocalizations loc) {
    return InkWell(
      onTap: onSelectPaymentDate,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.calendar, size: 14, color: Color(0xFF64748B)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                paymentDate != null
                    ? DateFormat('dd MMM yyyy').format(paymentDate!)
                    : loc.selectDate,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: paymentDate != null ? FontWeight.w600 : FontWeight.normal,
                  color: paymentDate != null ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (paymentDate != null)
              GestureDetector(
                onTap: onClearPaymentDate,
                child: const Icon(LucideIcons.x, size: 14, color: Color(0xFF94A3B8)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurposeOptionCard({
    required String title,
    required String subtitle,
    required String badgeLabel,
    required Color badgeColor,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? badgeColor.withValues(alpha: 0.04) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? badgeColor : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: badgeColor.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected
                    ? badgeColor.withValues(alpha: 0.12)
                    : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 17,
                color: isSelected ? badgeColor : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(width: 12),
            // Title & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF64748B),
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: badgeColor.withValues(alpha: 0.25)),
              ),
              child: Text(
                badgeLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: badgeColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceUploader(AppLocalizations loc) {
    if (selectedInvoiceFile != null) {
      return Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1F2),
          border: Border.all(color: const Color(0xFFFECDD3)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.fileText, size: 16, color: Color(0xFFE11D48)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${selectedInvoiceFile!.name} (${(selectedInvoiceFile!.size / 1024).toStringAsFixed(1)} KB)',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11.5, color: Color(0xFF9F1239)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            GestureDetector(
              onTap: onRemoveInvoiceFile,
              child: const Icon(LucideIcons.trash2, size: 16, color: Color(0xFFE11D48)),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: onPickInvoicePdf,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          border: Border.all(color: const Color(0xFFCBD5E1)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.uploadCloud, size: 16, color: Color(0xFF0F766E)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                loc.uploadPdfTitle,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF0F766E)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayerChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: isSelected ? activeColor : const Color(0xFF64748B)),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? activeColor : const Color(0xFF64748B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
