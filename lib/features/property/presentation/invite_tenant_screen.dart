import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:universal_io/io.dart' as io;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stanomer/features/property/presentation/widgets/payment_responsibility_selector.dart';
import 'package:stanomer/features/property/presentation/widgets/contract_file_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/expense_utils.dart';
import '../../auth/data/auth_providers.dart';
import '../../auth/data/auth_repository.dart';
import '../data/property_repository.dart';
import '../domain/property.dart';
import '../domain/contract.dart';
import '../domain/tenant_secondary_contact.dart';
import 'widgets/tenant_secondary_contacts_section.dart';
import '../../../core/services/document_storage_service.dart';
import 'package:path_provider/path_provider.dart';

class InviteTenantScreen extends ConsumerStatefulWidget {
  final Property property;
  final Contract? existingContract;
  final Contract? leaseTemplate;

  const InviteTenantScreen({
    super.key, 
    required this.property, 
    this.existingContract,
    this.leaseTemplate,
  });

  @override
  ConsumerState<InviteTenantScreen> createState() => _InviteTenantScreenState();
}

class _InviteTenantScreenState extends ConsumerState<InviteTenantScreen> {
  final _emailController = TextEditingController();
  final _tenantNameController = TextEditingController();
  final _rentController = TextEditingController();
  final _depositController = TextEditingController();
  final _dueDayController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  String? _generatedLink;
  bool _isLeaseLocked = false;
  
  DateTime? _startDate;
  DateTime? _endDate;
  String _depositCurrency = 'EUR';
  List<ExpenseItem> _expenses = [];
  List<TenantSecondaryContact> _secondaryContacts = [];

  // File Upload State
  String? _contractFileName;
  Uint8List? _contractFileBytes;
  String? _contractFilePath;
  String? _existingContractUrl;

  // Tenant ID Document
  String? _tenantIdDocUrl;
  String? _tenantIdDocFileName;
  bool _isUploadingTenantIdDoc = false;

  @override
  void initState() {
    super.initState();
    final contract = widget.existingContract ?? widget.leaseTemplate;
    
    if (widget.existingContract == null && widget.leaseTemplate != null) {
      _isLeaseLocked = true;
    }

    if (contract != null) {
      _emailController.text = widget.existingContract != null ? contract.inviteeEmail : '';
      _tenantNameController.text = contract.tenantName ?? (widget.existingContract != null ? widget.property.tenantName ?? '' : '');
      _idNumberController.text = contract.tenantIdNumber ?? '';
      _phoneController.text = contract.tenantPhone ?? '';
      _notesController.text = contract.tenantNotes ?? '';
      _tenantIdDocUrl = contract.tenantIdDocumentUrl;
      _secondaryContacts = List.from(contract.tenantSecondaryContacts);
      
      _rentController.text = contract.monthlyRent.toStringAsFixed(0);
      _depositController.text = contract.depositAmount?.toStringAsFixed(0) ?? '';
      _dueDayController.text = contract.dueDay.toString();
      _startDate = contract.startDate;
      _endDate = contract.endDate;
      _depositCurrency = contract.depositCurrency;
      _expenses = List.from(contract.expensesConfig);
      _existingContractUrl = contract.contractUrl;
    } else {
      _rentController.text = widget.property.defaultMonthlyRent.toStringAsFixed(0);
      _depositController.text = widget.property.defaultDepositAmount?.toStringAsFixed(0) ?? '';
      _depositCurrency = widget.property.defaultDepositCurrency;
      _dueDayController.text = widget.property.defaultDueDay.toString();
      _expenses = List.from(widget.property.expensesTemplate.where((e) => e.name != 'Porez (Tax)'));
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _tenantNameController.dispose();
    _rentController.dispose();
    _depositController.dispose();
    _dueDayController.dispose();
    _idNumberController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({bool isStartDate = true}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStartDate ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: StanomerColors.getRoleColor(ref.read(authRepositoryProvider).currentUser?.userMetadata?['role'])),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // If end date is empty, automatically set it to 1 year after
          if (_endDate == null) {
            _endDate = DateTime(_startDate!.year + 1, _startDate!.month, _startDate!.day);
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _pickTenantIdDoc() async {
    final result = await pickContractFile(context);
    if (result != null && result.files.single.name.isNotEmpty) {
      final file = result.files.single;
      Uint8List? fileBytes = file.bytes;
      if (fileBytes == null && !kIsWeb && file.path != null) {
        fileBytes = await io.File(file.path!).readAsBytes();
      }
      if (fileBytes != null) {
        setState(() => _isUploadingTenantIdDoc = true);
        try {
          final repo = ref.read(propertyRepositoryProvider);
          final uploadedUrl = await repo.uploadTenantDocument(
            propertyId: widget.property.id,
            fileName: file.name,
            bytes: fileBytes,
          );
          if (mounted) {
            setState(() {
              _tenantIdDocUrl = uploadedUrl;
              _tenantIdDocFileName = file.name;
              _isUploadingTenantIdDoc = false;
            });
          }
        } catch (e) {
          if (mounted) {
            setState(() => _isUploadingTenantIdDoc = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
            );
          }
        }
      }
    }
  }

  Future<void> _pickFile() async {
    final result = await pickContractFile(context);

    if (result != null && result.files.single.name.isNotEmpty) {
      List<int>? fileBytes = result.files.single.bytes?.toList();
      if (fileBytes == null && !kIsWeb && result.files.single.path != null) {
        fileBytes = await io.File(result.files.single.path!).readAsBytes();
      }

      setState(() {
        _contractFileName = result.files.single.name;
        _contractFileBytes = fileBytes != null ? Uint8List.fromList(fileBytes) : null;
        try {
          _contractFilePath = kIsWeb ? null : result.files.single.path;
        } catch (_) {
          _contractFilePath = null;
        }
      });
    }
  }

  Future<void> _submit() async {
    final loc = AppLocalizations.of(context)!;
    
    // Mandatory Date Validation
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.datesMandatory),
          backgroundColor: StanomerColors.alertPrimary,
        ),
      );
      return;
    }

    final currentUserEmail = ref.read(currentUserProvider)?.email;
    final emailText = _emailController.text.trim();
    if (emailText.isNotEmpty && currentUserEmail != null && emailText.toLowerCase() == currentUserEmail.toLowerCase()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.cannotInviteSelf),
          backgroundColor: StanomerColors.alertPrimary,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(propertyRepositoryProvider);
      
      // Upload file if selected
      String? contractUrl = _existingContractUrl;
      if (_contractFileName != null) {
        if (ref.read(cloudUploadAllowedProvider)) {
          contractUrl = await repo.uploadContract(
            _contractFileName!,
            filePath: _contractFilePath,
            bytes: _contractFileBytes,
          );
        } else {
          final io.File localFile;
          if (_contractFilePath != null) {
            localFile = io.File(_contractFilePath!);
          } else {
            final tempDir = await getTemporaryDirectory();
            localFile = io.File('${tempDir.path}/$_contractFileName');
            await localFile.writeAsBytes(_contractFileBytes!);
          }
          contractUrl = await ref.read(documentStorageServiceProvider).saveDocument(localFile);
        }
      }

      final finalRent = double.parse(_rentController.text);
      final profileAsync = ref.read(profileFutureProvider);
      final user = ref.read(currentUserProvider);
      final inviterName = profileAsync.value?['full_name'] 
          ?? widget.existingContract?.inviterName 
          ?? user?.userMetadata?['full_name'] 
          ?? widget.property.landlordName 
          ?? 'Landlord';

      if (widget.existingContract != null) {
        await repo.updateContractTerms(
          widget.existingContract!.id,
          monthlyRent: finalRent,
          depositAmount: _depositController.text.isNotEmpty ? double.parse(_depositController.text) : null,
          depositCurrency: _depositCurrency,
          dueDay: int.parse(_dueDayController.text),
          startDate: _startDate!,
          endDate: _endDate!,
          taxType: TaxType.included,
          expensesConfig: _expenses,
          contractUrl: contractUrl,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.revisionSent)),
          );
          Navigator.pop(context);
        }
      } else {
        // Her durumda contracts tablosunu kullan (hem ilk hem ek kiracı)
        final contract = await repo.createContract(
          propertyId: widget.property.id,
          inviteeEmail: emailText.isEmpty ? null : emailText,
          monthlyRent: finalRent,
          depositAmount: _depositController.text.isNotEmpty ? double.parse(_depositController.text) : null,
          currency: widget.property.currency,
          depositCurrency: _depositCurrency,
          dueDay: int.parse(_dueDayController.text),
          startDate: _startDate!,
          endDate: _endDate!,
          taxType: TaxType.included,
          expensesConfig: (widget.property.agencyId != null && widget.property.agencyId!.isNotEmpty) || (ref.read(currentUserProvider)?.userMetadata?['role'] == 'agency' || ref.read(currentUserProvider)?.id == widget.property.agencyId)
              ? _expenses
              : _expenses.map((e) => e.copyWith(paymentMethod: 'bank_transfer')).toList(),
          inviterName: inviterName,
          contractUrl: contractUrl,
          tenantName: _tenantNameController.text.trim().isEmpty ? null : _tenantNameController.text.trim(),
          tenantIdNumber: ((widget.property.agencyId != null && widget.property.agencyId!.isNotEmpty) || (ref.read(currentUserProvider)?.userMetadata?['role'] == 'agency' || ref.read(currentUserProvider)?.id == widget.property.agencyId)) && _idNumberController.text.trim().isNotEmpty
              ? _idNumberController.text.trim()
              : null,
          tenantPhone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          tenantNotes: ((widget.property.agencyId != null && widget.property.agencyId!.isNotEmpty) || (ref.read(currentUserProvider)?.userMetadata?['role'] == 'agency' || ref.read(currentUserProvider)?.id == widget.property.agencyId)) && _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
          tenantIdDocumentUrl: ((widget.property.agencyId != null && widget.property.agencyId!.isNotEmpty) || (ref.read(currentUserProvider)?.userMetadata?['role'] == 'agency' || ref.read(currentUserProvider)?.id == widget.property.agencyId))
              ? _tenantIdDocUrl
              : null,
          tenantSecondaryContacts: ((widget.property.agencyId != null && widget.property.agencyId!.isNotEmpty) || (ref.read(currentUserProvider)?.userMetadata?['role'] == 'agency' || ref.read(currentUserProvider)?.id == widget.property.agencyId))
              ? _secondaryContacts
              : const [],
        );
        
        setState(() {
          _generatedLink = 'stanomer://invite?token=${contract.token}';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: StanomerColors.alertPrimary),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isTr = loc.localeName == 'tr';
    final isSr = loc.localeName.startsWith('sr');
    final optionalSuffix = isTr
        ? '(İsteğe Bağlı)'
        : (isSr
            ? '(Opciono)'
            : (loc.localeName.startsWith('ru') ? '(Необязательно)' : '(Optional)'));

    final user = ref.watch(currentUserProvider);
    final role = user?.userMetadata?['role'] as String?;
    final roleColor = StanomerColors.getRoleColor(role);
    final isAgencyUser = role == 'agency' || user?.id == widget.property.agencyId;
    final isManagedByAgency = widget.property.agencyId != null && widget.property.agencyId!.isNotEmpty;
    final showAgencyTenantDetails = isManagedByAgency || isAgencyUser;

    if (isManagedByAgency && !isAgencyUser) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.existingContract != null ? loc.editContract : loc.inviteTenant),
          backgroundColor: roleColor,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.building2, size: 36, color: Color(0xFF2563EB)),
                ),
                const SizedBox(height: 16),
                Text(
                  loc.localeName == 'tr' ? 'Mülk Acente Yönetiminde' : 'Property Managed by Agency',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 8),
                Text(
                  loc.localeName == 'tr'
                      ? 'Bu mülk acente tarafından yönetilmektedir. Kiracı daveti ve sözleşme işlemleri yalnızca yetkili acente tarafından gerçekleştirilebilir.'
                      : (loc.localeName == 'ru'
                          ? 'Этот объект управляется агентством. Приглашение арендаторов и договоры оформляются агентством.'
                          : (loc.localeName.startsWith('sr')
                              ? 'Ovom nekretninom upravlja agencija. Poziv stanara i ugovore vodi agencija.'
                              : 'This property is managed by an agency. Tenant invitations and contracts can only be handled by the agency.')),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.4),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.maybePop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: StanomerColors.brandPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    loc.localeName == 'tr'
                        ? 'Geri Dön'
                        : (loc.localeName == 'ru'
                            ? 'Назад'
                            : (loc.localeName.startsWith('sr')
                                ? 'Nazad'
                                : 'Go Back')),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingContract != null 
            ? loc.editContract
            : loc.inviteTenant),
        backgroundColor: roleColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_generatedLink == null) ...[
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(loc.roleTenant.toUpperCase(), LucideIcons.user, roleColor),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _tenantNameController,
                      decoration: InputDecoration(
                        labelText: '${isTr ? "Kiracı Adı & Soyadı" : (isSr ? "Ime i prezime zakupca" : "Tenant Full Name")} *',
                        prefixIcon: const Icon(LucideIcons.user, size: 20),
                        hintText: isTr ? "Örn: Ahmet Yılmaz" : (isSr ? "Npr: Marko Petrović" : "E.g. John Doe"),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty) ? loc.fieldRequired : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      enabled: widget.existingContract == null,
                      decoration: InputDecoration(
                        labelText: showAgencyTenantDetails
                            ? '${loc.tenantEmail} *'
                            : '${loc.tenantEmail} $optionalSuffix',
                        prefixIcon: const Icon(LucideIcons.mail, size: 20),
                        hintText: "kiraci@email.com",
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (val) {
                        final text = val?.trim() ?? '';
                        if (text.isEmpty) {
                          if (showAgencyTenantDetails) {
                            return loc.fieldRequired;
                          }
                          return null;
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(text)) {
                          return isTr
                              ? 'Geçerli bir e-posta adresi giriniz'
                              : (loc.localeName == 'ru'
                                  ? 'Введите корректный e-mail'
                                  : (isSr
                                      ? 'Unesite validnu email adresu'
                                      : 'Please enter a valid email address'));
                        }
                        final currentUserEmail = ref.read(currentUserProvider)?.email;
                        if (currentUserEmail != null && text.toLowerCase() == currentUserEmail.toLowerCase()) {
                          return loc.cannotInviteSelf;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    if (showAgencyTenantDetails) ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _idNumberController,
                              decoration: InputDecoration(
                                labelText: isTr ? 'Kimlik / Pasaport / JMBG' : (isSr ? 'Br. l.k. / Pasoša / JMBG' : 'ID / Passport / JMBG'),
                                prefixIcon: const Icon(LucideIcons.idCard, size: 20),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: isTr ? 'Telefon' : (isSr ? 'Telefon' : 'Phone'),
                                prefixIcon: const Icon(LucideIcons.phone, size: 20),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: isTr ? 'Kiracıya İlişkin Notlar (İsteğe Bağlı)' : (isSr ? 'Napomene o zakupcu (Opciono)' : 'Tenant Notes (Optional)'),
                          prefixIcon: const Icon(LucideIcons.fileText, size: 20),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Kiracı Kimlik Belgesi Yükleme
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: StanomerColors.borderDefault),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _tenantIdDocUrl != null ? LucideIcons.fileCheck2 : LucideIcons.fileUp,
                              size: 20,
                              color: _tenantIdDocUrl != null ? Colors.green : roleColor,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isTr ? 'Kiracı Kimlik Belgesi / Pasaport' : (isSr ? 'Lični dokument / Pasoš zakupca' : 'Tenant ID Document / Passport'),
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _tenantIdDocUrl != null
                                        ? (_tenantIdDocFileName ?? (isTr ? 'Kimlik belgesi yüklendi' : 'ID document uploaded'))
                                        : (isTr ? 'PDF veya fotoğraf formatında yükleyebilirsiniz' : (isSr ? 'Otpremite u PDF ili formatu slike' : 'Upload PDF or photo copy')),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: _tenantIdDocUrl != null ? Colors.green.shade700 : StanomerColors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            if (_isUploadingTenantIdDoc)
                              const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            else if (_tenantIdDocUrl != null)
                              IconButton(
                                icon: const Icon(LucideIcons.trash2, size: 18, color: Colors.redAccent),
                                onPressed: () => setState(() {
                                  _tenantIdDocUrl = null;
                                  _tenantIdDocFileName = null;
                                }),
                              )
                            else
                              OutlinedButton.icon(
                                onPressed: _pickTenantIdDoc,
                                icon: const Icon(LucideIcons.upload, size: 14),
                                label: Text(isTr ? 'Yükle' : (isSr ? 'Otpremi' : 'Upload'), style: const TextStyle(fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: roleColor,
                                  side: BorderSide(color: roleColor.withValues(alpha: 0.5)),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // İkincil İletişim Kişileri
                      TenantSecondaryContactsSection(
                        initialContacts: _secondaryContacts,
                        onContactsChanged: (contacts) {
                          _secondaryContacts = contacts;
                        },
                      ),
                    ] else ...[
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: isTr ? 'Telefon' : (isSr ? 'Telefon' : 'Phone'),
                          prefixIcon: const Icon(LucideIcons.phone, size: 20),
                        ),
                      ),
                    ],

                    if (_isLeaseLocked) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: StanomerColors.brandPrimarySurface.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: StanomerColors.brandPrimary.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.info, size: 16, color: StanomerColors.brandPrimary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                loc.leaseLockedWarning,
                                style: const TextStyle(fontSize: 11, color: StanomerColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),
                    _buildSectionHeader(loc.rentPaymentHeader, LucideIcons.banknote, roleColor),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _rentController,
                            enabled: !_isLeaseLocked,
                            decoration: InputDecoration(
                              labelText: loc.monthlyRent,
                              prefixIcon: const Icon(LucideIcons.coins, size: 20),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (val) => (val == null || val.isEmpty) ? loc.fieldRequired : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            decoration: BoxDecoration(
                              color: StanomerColors.bgPage,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: StanomerColors.borderDefault),
                            ),
                            child: Text(widget.property.currency, textAlign: TextAlign.center),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _depositController,
                            enabled: !_isLeaseLocked,
                            decoration: InputDecoration(
                              labelText: loc.depositAmount,
                              prefixIcon: const Icon(LucideIcons.shieldCheck, size: 20),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (val) {
                              if (val != null && val.isNotEmpty && double.tryParse(val) == null) return 'Invalid number';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: DropdownButtonFormField<String>(
                            value: _depositCurrency,
                            decoration: InputDecoration(
                              labelText: loc.currency,
                            ),
                            items: const [
                              DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                              DropdownMenuItem(value: 'RSD', child: Text('RSD')),
                            ],
                            onChanged: _isLeaseLocked ? null : (val) => setState(() => _depositCurrency = val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _dueDayController,
                      enabled: !_isLeaseLocked,
                      decoration: InputDecoration(
                        labelText: loc.dueDay,
                        prefixIcon: const Icon(LucideIcons.calendarClock, size: 20),
                      ),
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: 32),
                    _buildSectionHeader(loc.datesAndContract, LucideIcons.calendar, roleColor),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildDatePicker(context, true, loc)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildDatePicker(context, false, loc)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildFilePicker(loc),

                    const SizedBox(height: 32),
                    _buildSectionHeader(loc.expenseSettingsHeader, LucideIcons.receipt, roleColor),
                    const SizedBox(height: 16),
                    _buildExpensesSection(loc, roleColor, showAgencyTenantDetails),

                    const SizedBox(height: 48),
                    ElevatedButton(
                      onPressed: _isLoading ? null : () {
                        if (_formKey.currentState!.validate()) {
                          if (_expenses.any((e) => e.receiver == PaymentReceiver.unselected)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(loc.selectPaymentReceiverWarning), backgroundColor: StanomerColors.alertPrimary),
                            );
                            return;
                          }
                          _submit();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                        backgroundColor: widget.existingContract != null ? Colors.orange : roleColor,
                      ),
                      child: _isLoading 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(widget.existingContract != null 
                            ? loc.sendRevision
                            : loc.inviteTenant),
                    ),
                  ],
                ),
              ),
            ] else ...[
              _buildGeneratedLinkSection(context, loc, roleColor),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color roleColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: roleColor),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: roleColor, letterSpacing: 1.2)),
          ],
        ),
        const SizedBox(height: 8),
        const Divider(),
      ],
    );
  }


  Widget _buildDatePicker(BuildContext context, bool isStart, AppLocalizations loc) {
    final date = isStart ? _startDate : _endDate;
    return InkWell(
      onTap: _isLeaseLocked ? null : () => _pickDate(isStartDate: isStart),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: StanomerColors.bgPage,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: date == null ? Colors.red.withValues(alpha: 0.5) : StanomerColors.borderDefault),
        ),
        child: Row(
          children: [
            Icon(isStart ? LucideIcons.calendar : LucideIcons.calendarX, size: 18, color: StanomerColors.textTertiary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                date != null ? DateFormat('dd.MM.yyyy').format(date) : (isStart ? loc.contractStartDate : loc.contractEndDate),
                style: TextStyle(color: date != null ? StanomerColors.textPrimary : StanomerColors.textTertiary, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilePicker(AppLocalizations loc) {
    return InkWell(
      onTap: _isLeaseLocked ? null : _pickFile,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: StanomerColors.bgPage,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: StanomerColors.borderDefault),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.filePlus, size: 20, color: StanomerColors.textTertiary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _contractFileName ?? (_existingContractUrl != null ? loc.existingFileKept : loc.uploadContract),
                style: TextStyle(color: (_contractFileName != null || _existingContractUrl != null) ? StanomerColors.textPrimary : StanomerColors.textTertiary, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesSection(AppLocalizations loc, Color roleColor, bool showAgencyTenantDetails) {
    final isTr = loc.localeName == 'tr';
    final isSr = loc.localeName.startsWith('sr');
    return Material(
      color: StanomerColors.bgCard,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: StanomerColors.borderDefault),
        ),
      child: Column(
        children: _expenses.map((expense) {
          final index = _expenses.indexOf(expense);
          final isIncluded = expense.receiver == PaymentReceiver.included;
          
          return Column(
            children: [
              ListTile(
                dense: true,
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        ExpenseUtils.getLocalizedExpenseName(expense.name, loc),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        softWrap: true,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message: ExpenseUtils.getLocalizedTooltip(expense.name, loc),
                      triggerMode: TooltipTriggerMode.tap,
                      child: const Icon(LucideIcons.info, size: 14, color: StanomerColors.textTertiary),
                    ),
                  ],
                ),
                subtitle: isIncluded 
                  ? Text(loc.includedInRent, 
                      style: const TextStyle(color: StanomerColors.successPrimary, fontSize: 11))
                  : null,
                trailing: Switch.adaptive(
                  value: isIncluded,
                  activeColor: roleColor,
                  onChanged: _isLeaseLocked ? null : (val) {
                    setState(() {
                      _expenses[index] = expense.copyWith(
                        receiver: val ? PaymentReceiver.included : PaymentReceiver.unselected,
                      );
                    });
                  },
                ),
              ),
              if (!isIncluded)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.tenantPaysTo,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: StanomerColors.textTertiary),
                      ),
                      const SizedBox(height: 6),
                      PaymentResponsibilitySelector(
                        value: expense.receiver,
                        onChanged: _isLeaseLocked ? null : (PaymentReceiver newReceiver) {
                          setState(() {
                            _expenses[index] = expense.copyWith(receiver: newReceiver);
                          });
                        },
                      ),
                      if (showAgencyTenantDetails) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              isTr ? 'Ödeme Yöntemi:' : (isSr ? 'Način plaćanja:' : 'Payment Method:'),
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: StanomerColors.textTertiary),
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: Text(isTr ? 'Banka' : (isSr ? 'Banka' : 'Bank'), style: const TextStyle(fontSize: 11)),
                              avatar: const Icon(LucideIcons.landmark, size: 13),
                              selected: expense.paymentMethod != 'cash',
                              onSelected: _isLeaseLocked ? null : (_) {
                                setState(() {
                                  _expenses[index] = expense.copyWith(paymentMethod: 'bank_transfer');
                                });
                              },
                              selectedColor: const Color(0xFFEFF6FF),
                              labelStyle: TextStyle(
                                color: expense.paymentMethod != 'cash' ? const Color(0xFF1D4ED8) : StanomerColors.textSecondary,
                                fontWeight: expense.paymentMethod != 'cash' ? FontWeight.bold : FontWeight.normal,
                              ),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            const SizedBox(width: 6),
                            ChoiceChip(
                              label: Text(isTr ? 'Nakit' : (isSr ? 'Gotovina' : 'Cash'), style: const TextStyle(fontSize: 11)),
                              avatar: const Icon(LucideIcons.banknote, size: 13),
                              selected: expense.paymentMethod == 'cash',
                              onSelected: _isLeaseLocked ? null : (_) {
                                setState(() {
                                  _expenses[index] = expense.copyWith(paymentMethod: 'cash');
                                });
                              },
                              selectedColor: const Color(0xFFFEF3C7),
                              labelStyle: TextStyle(
                                color: expense.paymentMethod == 'cash' ? const Color(0xFFB45309) : StanomerColors.textSecondary,
                                fontWeight: expense.paymentMethod == 'cash' ? FontWeight.bold : FontWeight.normal,
                              ),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              if (index < _expenses.length - 1)
                Divider(height: 1, color: StanomerColors.borderDefault.withValues(alpha: 0.5)),
            ],
          );
        }).toList().cast<Widget>(),
        ),
      ),
    );
  }

  Widget _buildGeneratedLinkSection(BuildContext context, AppLocalizations loc, Color roleColor) {
    final link = _generatedLink!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(LucideIcons.checkCircle2, color: roleColor, size: 64),
        const SizedBox(height: 16),
        Text(
          loc.inviteCreatedSuccess,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 32),

        // ── Link kutusu ──────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: StanomerColors.bgPage,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: StanomerColors.borderDefault),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  link,
                  style: const TextStyle(fontSize: 13, color: StanomerColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.copy, size: 18),
                tooltip: loc.copyLink,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: link));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.copyLink)),
                  );
                },
              ),
              IconButton(
                icon: const Icon(LucideIcons.share2, size: 18),
                tooltip: loc.share,
                onPressed: () => Share.share(link),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // ── QR Kod ──────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              QrImageView(
                data: link,
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(LucideIcons.share2, size: 16),
                    label: Text(loc.share),
                    onPressed: () => Share.share(link),
                    style: OutlinedButton.styleFrom(foregroundColor: roleColor),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 48),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(backgroundColor: roleColor),
          child: Text(loc.done),
        ),
      ],
    );
  }
}
