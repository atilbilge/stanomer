import 'package:universal_io/io.dart' as io;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:intl/intl.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/colors.dart';
import '../../property/domain/property.dart';
import '../../property/data/property_repository.dart';
import '../../auth/data/auth_providers.dart';
import '../domain/maintenance_request.dart';
import '../data/maintenance_repository.dart';
import '../../../core/services/document_storage_service.dart';
import 'package:path_provider/path_provider.dart';

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
  String _paymentStatus = 'pending_review';
  DateTime? _paymentDate;
  PlatformFile? _selectedInvoiceFile;

  MaintenanceCategory _selectedCategory = MaintenanceCategory.other;
  MaintenancePriority _selectedPriority = MaintenancePriority.normal;
  bool _isLoading = false;
  List<PlatformFile> _selectedFiles = [];

  @override
  void initState() {
    super.initState();
    _selectedCurrency = widget.property.currency.isNotEmpty ? widget.property.currency : 'EUR';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _costController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );

    if (result != null) {
      setState(() {
        _selectedFiles = [..._selectedFiles, ...result.files];
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
    final languageCode = Localizations.localeOf(context).languageCode.toLowerCase();
    if (!_formKey.currentState!.validate()) return;

    // Validate cost amount if entered
    double? costAmount;
    final costText = _costController.text.trim().replaceAll(',', '.');
    if (costText.isNotEmpty) {
      costAmount = double.tryParse(costText);
      if (costAmount == null || costAmount < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.errorWithDetails('Invalid cost amount')),
            backgroundColor: StanomerColors.alertPrimary,
          ),
        );
        return;
      }
    }

    if ((_paymentStatus == 'pending_payment' || _paymentStatus == 'paid') && costAmount != null && _paidBy == null) {
      String payerRequiredMsg;
      switch (languageCode) {
        case 'tr': payerRequiredMsg = 'Lütfen ödeme bekleyen veya ödenmiş kayıt için maliyet sorumlusunu (Kiracı veya Ev Sahibi) seçiniz.'; break;
        case 'sr': payerRequiredMsg = 'Molimo izaberite ko plaća trošak (Stanar ili Vlasnik).'; break;
        case 'ru': payerRequiredMsg = 'Пожалуйста, укажите кто оплачивает (Арендатор или Владелец).'; break;
        default: payerRequiredMsg = 'Please select who pays before setting payment status.'; break;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(payerRequiredMsg),
          backgroundColor: StanomerColors.alertPrimary,
        ),
      );
      return;
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
      final userProfileAsync = user?.id != null ? ref.read(profileProvider(user!.id)) : const AsyncValue<Map<String, dynamic>?>.data(null);
      final profileRole = userProfileAsync.value?['role'] as String? ?? user?.userMetadata?['role'] as String?;

      final isLandlord = widget.property.landlordId == user?.id || profileRole == 'landlord';
      final isAgency = widget.property.agencyId == user?.id || profileRole == 'agency';
      final isTenant = widget.property.tenantId == user?.id || profileRole == 'tenant' || (!isLandlord && !isAgency);

      final double? finalCostAmount = isTenant ? null : costAmount;
      final String? finalCurrency = (isTenant || finalCostAmount == null) ? null : _selectedCurrency;
      final String? finalPaidBy = isTenant ? null : _paidBy;
      final DateTime? finalPaymentDate = isTenant ? null : _paymentDate;
      final String finalPaymentStatus = isTenant ? 'pending_review' : _paymentStatus;
      final String? finalInvoicePdfUrl = isTenant ? null : invoicePdfUrl;

      await ref.read(maintenanceRepositoryProvider).createRequest(
        propertyId: widget.property.id,
        title: _titleController.text.trim(),
        category: _selectedCategory,
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
          SnackBar(content: Text(loc.errorWithDetails(e.toString())), backgroundColor: StanomerColors.alertPrimary),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final user = ref.watch(currentUserProvider);
    final userProfileAsync = user?.id != null ? ref.watch(profileProvider(user!.id)) : const AsyncValue<Map<String, dynamic>?>.data(null);
    final profileRole = userProfileAsync.value?['role'] as String? ?? user?.userMetadata?['role'] as String?;

    final isLandlord = widget.property.landlordId == user?.id || profileRole == 'landlord';
    final isAgency = widget.property.agencyId == user?.id || profileRole == 'agency';
    final isTenant = widget.property.tenantId == user?.id || profileRole == 'tenant' || (!isLandlord && !isAgency);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.reportIssue),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(loc.issueTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: StanomerColors.textTertiary)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: loc.issueTitle,
                ),
                validator: (val) => val == null || val.isEmpty ? loc.fieldRequired : null,
              ),
              const SizedBox(height: 20),
              
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(loc.issueCategory, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: StanomerColors.textTertiary)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<MaintenanceCategory>(
                          initialValue: _selectedCategory,
                          items: MaintenanceCategory.values.map((cat) => DropdownMenuItem(
                            value: cat,
                            child: Text(_getCategoryLabel(cat, loc)),
                          )).toList(),
                          onChanged: (val) => setState(() => _selectedCategory = val!),
                          decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(loc.issuePriority, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: StanomerColors.textTertiary)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<MaintenancePriority>(
                          initialValue: _selectedPriority,
                          items: MaintenancePriority.values.map((p) => DropdownMenuItem(
                            value: p,
                            child: Text(_getPriorityLabel(p, loc)),
                          )).toList(),
                          onChanged: (val) => setState(() => _selectedPriority = val!),
                          decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Text(loc.issueDescription, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: StanomerColors.textTertiary)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: loc.issueDescription,
                ),
              ),
              const SizedBox(height: 20),

              _buildPhotoSection(loc),
              
              if (!isTenant) ...[
                const SizedBox(height: 24),
                // ── Financial Section (Only for Landlords & Agency Managers) ──
                _buildFinancialSection(loc, isDark),
              ],
              const SizedBox(height: 32),
              
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: StanomerColors.getRoleColor(profileRole),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(loc.send),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinancialSection(AppLocalizations loc, bool isDark) {
    final languageCode = Localizations.localeOf(context).languageCode.toLowerCase();
    
    String sectionTitle;
    String sectionSubtitle;
    String costLabel;
    String paidByLabel;
    String tenantLabel;
    String landlordLabel;
    String unassignedLabel;
    String statusLabel;
    String pendingReviewLabel;
    String pendingReviewHint;
    String pendingPaymentLabel;
    String pendingPaymentHint;
    String paidLabel;
    String rejectedLabel;
    String paymentDateLabel;
    String notSelectedLabel;
    String invoicePdfLabel;
    String uploadPdfTitle;
    String uploadPdfSubtitle;
    String tenantLockedStatusNotice;

    switch (languageCode) {
      case 'tr':
        sectionTitle = 'FİNANSAL BİLGİLER & FATURA';
        sectionSubtitle = 'Arıza tamir maliyetini ve varsa faturayı ekleyin (İsteğe bağlı).';
        costLabel = 'Maliyet Tutarı';
        paidByLabel = 'Maliyet Sorumlusu (Ödeyen Taraf)';
        tenantLabel = 'Kiracı';
        landlordLabel = 'Ev Sahibi';
        unassignedLabel = 'Belirtilmedi';
        statusLabel = 'Fatura & Ödeme Durumu';
        pendingReviewLabel = 'İnceleme Bekliyor';
        pendingReviewHint = 'Fatura inceleniyor (Panoya yansımaz)';
        pendingPaymentLabel = 'Ödeme Bekliyor';
        pendingPaymentHint = 'Onaylandı • Borç/gider olarak yansır';
        paidLabel = 'Ödendi';
        rejectedLabel = 'Reddedildi';
        paymentDateLabel = 'Ödeme Tarihi';
        notSelectedLabel = 'Tarih seçilmedi';
        invoicePdfLabel = 'Fatura / Makbuz Belgesi';
        uploadPdfTitle = 'Fatura PDF Yükle';
        uploadPdfSubtitle = 'PDF belgesi seçmek için dokunun (Maks. 10MB)';
        tenantLockedStatusNotice = 'Kiracı masrafı kendisi ödemediği sürece ödeme statüsünü değiştiremez. Fatura "İnceleme Bekliyor" olarak yöneticiye iletilir.';
        break;
      case 'sr':
        sectionTitle = 'FINANSIJSKI PODACI & FAKTURA';
        sectionSubtitle = 'Dodajte trošak popravke i fakturu ako postoji (Opciono).';
        costLabel = 'Iznos troška';
        paidByLabel = 'Odgovoran za trošak (Platilac)';
        tenantLabel = 'Stanar';
        landlordLabel = 'Vlasnik';
        unassignedLabel = 'Nije navedeno';
        statusLabel = 'Status fakture i plaćanja';
        pendingReviewLabel = 'Čeka proveru';
        pendingReviewHint = 'Račun se proverava (Ne utiče na bilans)';
        pendingPaymentLabel = 'Čeka plaćanje';
        pendingPaymentHint = 'Odobreno • Evidentira se zaduženje';
        paidLabel = 'Plaćeno';
        rejectedLabel = 'Odbijeno';
        paymentDateLabel = 'Datum plaćanja';
        notSelectedLabel = 'Datum nije izabran';
        invoicePdfLabel = 'Faktura / Račun';
        uploadPdfTitle = 'Otpremi PDF račun';
        uploadPdfSubtitle = 'Dodirnite za izbor PDF-a (Maks. 10MB)';
        tenantLockedStatusNotice = 'Stanar ne može menjati status plaćanja ukoliko sam ne plaća trošak (biće sačuvano kao Čeka proveru).';
        break;
      case 'ru':
        sectionTitle = 'ФИНАНСОВЫЕ ДАННЫЕ И СЧЕТ';
        sectionSubtitle = 'Укажите расходы на ремонт и счет при наличии (Необязательно).';
        costLabel = 'Сумма расходов';
        paidByLabel = 'Кто оплачивает (Ответственный)';
        tenantLabel = 'Арендатор';
        landlordLabel = 'Владелец';
        unassignedLabel = 'Не указано';
        statusLabel = 'Статус счета и оплаты';
        pendingReviewLabel = 'На проверке';
        pendingReviewHint = 'Счет на проверке (Не влияет на баланс)';
        pendingPaymentLabel = 'Ожидает оплаты';
        pendingPaymentHint = 'Одобрено • Отражается к оплате';
        paidLabel = 'Оплачено';
        rejectedLabel = 'Отклонено';
        paymentDateLabel = 'Дата оплаты';
        notSelectedLabel = 'Дата не выбрана';
        invoicePdfLabel = 'Счет / Квитанция';
        uploadPdfTitle = 'Загрузить счет PDF';
        uploadPdfSubtitle = 'Нажмите для выбора PDF (Макс. 10MB)';
        tenantLockedStatusNotice = 'Арендатор не может изменить статус оплаты, если не оплачивает сам (сохраняется как На проверке).';
        break;
      default:
        sectionTitle = 'FINANCIAL DETAILS & INVOICE';
        sectionSubtitle = 'Record maintenance cost and vendor invoice (Optional).';
        costLabel = 'Cost Amount';
        paidByLabel = 'Cost Responsibility (Paid By)';
        tenantLabel = 'Tenant';
        landlordLabel = 'Landlord / Owner';
        unassignedLabel = 'Unassigned';
        statusLabel = 'Invoice & Payment Status';
        pendingReviewLabel = 'Pending Review';
        pendingReviewHint = 'Under review (Not reflected on balance)';
        pendingPaymentLabel = 'Pending Payment';
        pendingPaymentHint = 'Approved • Reflected as debt/expense';
        paidLabel = 'Paid';
        rejectedLabel = 'Rejected';
        paymentDateLabel = 'Payment Date';
        notSelectedLabel = 'Date not selected';
        invoicePdfLabel = 'Invoice / Receipt';
        uploadPdfTitle = 'Upload Invoice PDF';
        uploadPdfSubtitle = 'Tap to select PDF file (Max 10MB)';
        tenantLockedStatusNotice = 'Tenants cannot change payment status unless paying themselves (submitted as Pending Review).';
        break;
    }

    final user = ref.watch(currentUserProvider);
    final isTenant = user?.id != null && user!.id == widget.property.tenantId;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.6) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: StanomerColors.brandPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(LucideIcons.receipt, size: 16, color: StanomerColors.brandPrimary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sectionTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 0.6,
                        color: StanomerColors.textTertiary,
                      ),
                    ),
                    Text(
                      sectionSubtitle,
                      style: const TextStyle(fontSize: 11, color: StanomerColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // 1. Cost Amount & Currency
          Text(costLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: StanomerColors.textSecondary)),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _costController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    prefixIcon: const Icon(LucideIcons.circleDollarSign, size: 18),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      final parsed = double.tryParse(value.trim().replaceAll(',', '.'));
                      if (parsed == null || parsed < 0) {
                        return 'Invalid';
                      }
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedCurrency,
                  items: const [
                    DropdownMenuItem(value: 'EUR', child: Text('EUR (€)')),
                    DropdownMenuItem(value: 'RSD', child: Text('RSD')),
                    DropdownMenuItem(value: 'USD', child: Text('USD (\$)')),
                    DropdownMenuItem(value: 'TRY', child: Text('TRY (₺)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCurrency = val);
                  },
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2. Paid By Section (Read-only for Tenant, Segmented for Manager/Landlord)
          Text(paidByLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: StanomerColors.textSecondary)),
          const SizedBox(height: 6),
          if (isTenant)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                children: [
                  Icon(LucideIcons.lock, size: 16, color: StanomerColors.textTertiary),
                  SizedBox(width: 10),
                  Text(
                    'Yönetici Tarafından Belirlenecektir',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ],
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: _buildCreatePayerOption(
                    label: tenantLabel,
                    icon: LucideIcons.user,
                    isSelected: _paidBy == 'tenant',
                    activeColor: StanomerColors.tenant,
                    onTap: () => setState(() => _paidBy = 'tenant'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildCreatePayerOption(
                    label: landlordLabel,
                    icon: LucideIcons.home,
                    isSelected: _paidBy == 'landlord',
                    activeColor: StanomerColors.landlord,
                    onTap: () => setState(() => _paidBy = 'landlord'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildCreatePayerOption(
                    label: unassignedLabel,
                    icon: LucideIcons.helpCircle,
                    isSelected: _paidBy == null,
                    activeColor: StanomerColors.textSecondary,
                    onTap: () => setState(() => _paidBy = null),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),

          // 3. Payment Status (Notice for Tenant, 4-State Grid for Manager/Landlord)
          Text(statusLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: StanomerColors.textSecondary)),
          const SizedBox(height: 8),

          if (isTenant) ...[
            // Tenant locked banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEBF3FC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1A5EB8).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.info, size: 18, color: Color(0xFF1A5EB8)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tenantLockedStatusNotice,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1A5EB8),
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Management / Landlord full 4-state grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.2,
              children: [
                _buildCreatePaymentStatusTile(
                  label: pendingReviewLabel,
                  subtitle: pendingReviewHint,
                  icon: LucideIcons.fileSearch,
                  activeColor: const Color(0xFF1A5EB8),
                  isSelected: _paymentStatus == 'pending_review' || _paymentStatus == 'pending',
                  onTap: () => setState(() => _paymentStatus = 'pending_review'),
                ),
                _buildCreatePaymentStatusTile(
                  label: pendingPaymentLabel,
                  subtitle: pendingPaymentHint,
                  icon: LucideIcons.clock,
                  activeColor: StanomerColors.statusPending,
                  isSelected: _paymentStatus == 'pending_payment',
                  onTap: () => setState(() => _paymentStatus = 'pending_payment'),
                ),
                _buildCreatePaymentStatusTile(
                  label: paidLabel,
                  subtitle: 'Ödeme tamamlandı',
                  icon: LucideIcons.checkCircle2,
                  activeColor: StanomerColors.statusPaid,
                  isSelected: _paymentStatus == 'paid',
                  onTap: () => setState(() => _paymentStatus = 'paid'),
                ),
                _buildCreatePaymentStatusTile(
                  label: rejectedLabel,
                  subtitle: 'Geçersiz / Reddedildi',
                  icon: LucideIcons.xCircle,
                  activeColor: StanomerColors.alertPrimary,
                  isSelected: _paymentStatus == 'rejected',
                  onTap: () => setState(() => _paymentStatus = 'rejected'),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),

          // 4. Payment Date Picker
          Text(paymentDateLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: StanomerColors.textSecondary)),
          const SizedBox(height: 6),
          InkWell(
            onTap: () => _selectPaymentDate(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                borderRadius: BorderRadius.circular(12),
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.calendar, size: 16, color: StanomerColors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _paymentDate != null
                          ? DateFormat('dd MMMM yyyy').format(_paymentDate!)
                          : notSelectedLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: _paymentDate != null ? FontWeight.w600 : FontWeight.normal,
                        color: _paymentDate != null ? StanomerColors.textPrimary : StanomerColors.textTertiary,
                      ),
                    ),
                  ),
                  if (_paymentDate != null)
                    GestureDetector(
                      onTap: () => setState(() => _paymentDate = null),
                      child: const Icon(LucideIcons.x, size: 16, color: StanomerColors.textTertiary),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 5. Invoice PDF Section
          Text(invoicePdfLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: StanomerColors.textSecondary)),
          const SizedBox(height: 6),
          if (_selectedInvoiceFile != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: StanomerColors.brandPrimary.withValues(alpha: 0.08),
                border: Border.all(color: StanomerColors.brandPrimary.withValues(alpha: 0.4)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(LucideIcons.fileText, size: 22, color: Colors.red),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedInvoiceFile!.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${(_selectedInvoiceFile!.size / 1024).toStringAsFixed(1)} KB • PDF Seçildi',
                          style: const TextStyle(fontSize: 11, color: StanomerColors.brandPrimary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _removeInvoiceFile,
                    icon: const Icon(LucideIcons.trash2, size: 18, color: StanomerColors.alertPrimary),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            )
          else
            InkWell(
              onTap: _pickInvoicePdf,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: StanomerColors.brandPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(LucideIcons.uploadCloud, size: 18, color: StanomerColors.brandPrimary),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          uploadPdfTitle,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          uploadPdfSubtitle,
                          style: const TextStyle(fontSize: 11, color: StanomerColors.textTertiary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCreatePayerOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.12) : Colors.transparent,
          border: Border.all(
            color: isSelected ? activeColor : StanomerColors.borderDefault,
            width: isSelected ? 1.5 : 1.0,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: isSelected ? activeColor : StanomerColors.textTertiary),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? activeColor : StanomerColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreatePaymentStatusTile({
    required String label,
    required String subtitle,
    required IconData icon,
    required Color activeColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.1) : Colors.transparent,
          border: Border.all(
            color: isSelected ? activeColor : StanomerColors.borderDefault,
            width: isSelected ? 1.5 : 1.0,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSelected ? activeColor.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: isSelected ? activeColor : StanomerColors.textTertiary),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? activeColor : StanomerColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: isSelected ? activeColor.withValues(alpha: 0.8) : StanomerColors.textTertiary,
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
    );
  }

  Widget _buildPhotoSection(AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              loc.photos, 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: StanomerColors.textTertiary)
            ),
            TextButton.icon(
              onPressed: _pickImages,
              icon: const Icon(LucideIcons.camera, size: 16),
              label: Text(loc.add),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            ),
          ],
        ),
        if (_selectedFiles.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedFiles.length,
              itemBuilder: (context, index) {
                final file = _selectedFiles[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: StanomerColors.borderDefault),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: file.bytes != null 
                          ? Image.memory(file.bytes!, fit: BoxFit.cover)
                          : const Center(child: Icon(LucideIcons.image)),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeFile(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(LucideIcons.x, size: 14, color: Colors.white),
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

  String _getCategoryLabel(MaintenanceCategory cat, AppLocalizations loc) {
    switch (cat) {
      case MaintenanceCategory.plumbing: return loc.categoryPlumbing;
      case MaintenanceCategory.electrical: return loc.categoryElectrical;
      case MaintenanceCategory.heating: return loc.categoryHeating;
      case MaintenanceCategory.internet: return loc.categoryInternet;
      case MaintenanceCategory.appliance:
      case MaintenanceCategory.structural:
      case MaintenanceCategory.other:
      default:
        return loc.categoryOther;
    }
  }

  String _getPriorityLabel(MaintenancePriority p, AppLocalizations loc) {
    switch (p) {
      case MaintenancePriority.urgent:
      case MaintenancePriority.high:
        return loc.priorityUrgent;
      case MaintenancePriority.normal:
      case MaintenancePriority.medium:
      case MaintenancePriority.low:
      default:
        return loc.priorityNormal;
    }
  }
}

