import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stanomer/features/property/presentation/widgets/payment_responsibility_selector.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/colors.dart';
import '../../agency/presentation/agency_dashboard_screen.dart';
import '../data/property_repository.dart';
import '../domain/property.dart';
import '../domain/contract.dart';
import 'package:stanomer/core/utils/expense_utils.dart';
import '../../../core/providers/agency_branding_provider.dart';
import '../../auth/data/auth_providers.dart';
import '../domain/property_owner.dart';
import 'widgets/property_owners_form_section.dart';
import 'widgets/ownership_share_sheet.dart';
import 'join_property_sheet.dart';

class AddPropertyScreen extends ConsumerStatefulWidget {
  final Property? property;
  const AddPropertyScreen({super.key, this.property});

  @override
  ConsumerState<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends ConsumerState<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _rentController = TextEditingController();
  final _depositController = TextEditingController();
  final _dueDayController = TextEditingController(text: '1');
  final _landlordNameController = TextEditingController();
  final _landlordPhoneController = TextEditingController();
  final _landlordEmailController = TextEditingController();

  List<PropertyOwner> _owners = [];
  final _ownersFormKey = GlobalKey<PropertyOwnersFormSectionState>();
  late String _tempPropertyId;

  // --- Detailed Property Fields Controllers & State ---
  bool _isDetailed = false;
  String? _propertyType; // 'apartment', 'house', 'commercial', 'garage'
  final _unitNumberController = TextEditingController();
  String? _roomCount; // 'studio', '1.0', '1.5', '2.0', '2.5', '3.0', '3.5', '4.0', '5.0+'
  final _areaController = TextEditingController();
  String? _floor; // 'suteren', 'prizemlje', 'visoko_prizemlje', '1', '2', '3', '4+'...
  final _totalFloorsController = TextEditingController();
  String? _furnishing; // 'furnished', 'semi_furnished', 'unfurnished'
  String? _heatingType; // 'cg', 'eg', 'gas', 'underfloor', 'ta'
  Set<String> _selectedAmenities = <String>{};
  final _descriptionController = TextEditingController();

  String _selectedCurrency = 'EUR';
  String _depositCurrency = 'EUR';
  bool _isLoading = false;
  bool _nameManuallyEdited = false;

  List<ExpenseItem> _expenses = [
    const ExpenseItem(name: 'Infostan', receiver: PaymentReceiver.included),
    const ExpenseItem(name: 'Struja (Electricity)', receiver: PaymentReceiver.included),
    const ExpenseItem(name: 'Internet/TV', receiver: PaymentReceiver.included),
    const ExpenseItem(name: 'Održavanje zgrade (Maintenance)', receiver: PaymentReceiver.included),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.property != null) {
      final p = widget.property!;
      _nameController.text = p.name;
      _addressController.text = p.address;
      _cityController.text = p.city ?? '';
      _rentController.text = p.defaultMonthlyRent.toStringAsFixed(0);
      _depositController.text = p.defaultDepositAmount?.toStringAsFixed(0) ?? '';
      _selectedCurrency = p.currency;
      _depositCurrency = p.defaultDepositCurrency;
      _nameManuallyEdited = true;
      _dueDayController.text = p.defaultDueDay.toString();
      _landlordNameController.text = p.landlordName ?? '';
      _landlordPhoneController.text = p.landlordPhone ?? '';
      _landlordEmailController.text = p.landlordEmail ?? '';
      
      // Detailed fields
      _isDetailed = p.isDetailed;
      _propertyType = p.propertyType;
      _unitNumberController.text = p.unitNumber ?? '';
      _roomCount = p.roomCount;
      _areaController.text = p.areaSqm != null 
          ? (p.areaSqm! % 1 == 0 ? p.areaSqm!.toInt().toString() : p.areaSqm!.toString())
          : '';
      _floor = p.floor == 'bodrum' ? 'suteren' : p.floor;
      _totalFloorsController.text = p.totalFloors?.toString() ?? '';
      _furnishing = p.furnishing;
      _heatingType = p.heatingType;
      _selectedAmenities = Set.from(p.amenities);
      _descriptionController.text = p.description ?? '';

      if (p.expensesTemplate.isNotEmpty) {
        _expenses = List.from(p.expensesTemplate.where((e) => e.name != 'Porez (Tax)'));
      }
    } else {
      final hasAgencyBranding = ref.read(hasAgencyBrandingProvider);
      if (hasAgencyBranding) {
        _isDetailed = true;
      }
    }
    _addressController.addListener(_onAddressChanged);
    _descriptionController.addListener(() => setState(() {}));

    _tempPropertyId = widget.property?.id ?? 'temp_${DateTime.now().millisecondsSinceEpoch}';
    if (widget.property != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          final existingOwners = await ref.read(propertyRepositoryProvider).getPropertyOwners(widget.property!.id);
          if (mounted && existingOwners.isNotEmpty) {
            setState(() {
              _owners = existingOwners;
            });
          }
        } catch (_) {}
      });
    }
  }

  @override
  void dispose() {
    _addressController.removeListener(_onAddressChanged);
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _rentController.dispose();
    _depositController.dispose();
    _dueDayController.dispose();
    _landlordNameController.dispose();
    _landlordPhoneController.dispose();
    _landlordEmailController.dispose();
    _unitNumberController.dispose();
    _areaController.dispose();
    _totalFloorsController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onAddressChanged() {
    if (!_nameManuallyEdited) {
      final address = _addressController.text.trim();
      if (address.isNotEmpty) {
        _nameController.text = address;
      }
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    final hasAgencyBranding = ref.read(hasAgencyBrandingProvider);
    setState(() {
      _nameController.clear();
      _addressController.clear();
      _cityController.clear();
      _rentController.clear();
      _depositController.clear();
      _dueDayController.text = '1';
      _landlordNameController.clear();
      _landlordPhoneController.clear();
      _landlordEmailController.clear();
      _unitNumberController.clear();
      _areaController.clear();
      _totalFloorsController.clear();
      _descriptionController.clear();
      _propertyType = null;
      _roomCount = null;
      _floor = null;
      _furnishing = null;
      _heatingType = null;
      _selectedAmenities = <String>{};
      _isDetailed = hasAgencyBranding;
      _nameManuallyEdited = false;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final loc = AppLocalizations.of(context)!;

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(propertyRepositoryProvider);
      final isEdit = widget.property != null;

      Property? createdProp;
      final cityText = _cityController.text.trim();
      final cityVal = cityText.isEmpty ? null : cityText;

      final unitNumberVal = _unitNumberController.text.trim().isEmpty ? null : _unitNumberController.text.trim();
      final areaVal = double.tryParse(_areaController.text.trim());
      final totalFloorsVal = int.tryParse(_totalFloorsController.text.trim());
      final descriptionVal = _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim();

      final hasAgencyBranding = ref.read(hasAgencyBrandingProvider);
      final isDetailedFinal = hasAgencyBranding || _isDetailed;

      List<PropertyOwner> finalOwners = _owners;
      if (_ownersFormKey.currentState != null) {
        if (!_ownersFormKey.currentState!.validate()) {
          setState(() => _isLoading = false);
          return;
        }
        finalOwners = _ownersFormKey.currentState!.getOwners();
      }

      String effLandlordName = _landlordNameController.text.trim();
      String effLandlordPhone = _landlordPhoneController.text.trim();
      String effLandlordEmail = _landlordEmailController.text.trim();

      if (finalOwners.isNotEmpty) {
        final primary = finalOwners.firstWhere((o) => o.isPrimary, orElse: () => finalOwners.first);
        effLandlordName = primary.displayName;
        effLandlordPhone = primary.phone ?? '';
        effLandlordEmail = primary.email ?? '';
      }

      if (isEdit) {
        await repo.updateProperty(widget.property!.copyWith(
          address: _addressController.text.trim(),
          name: _nameController.text.trim(),
          city: cityVal,
          defaultMonthlyRent: double.parse(_rentController.text),
          defaultDepositAmount: _depositController.text.isNotEmpty 
              ? double.parse(_depositController.text) 
              : null,
          currency: _selectedCurrency,
          defaultDepositCurrency: _depositCurrency,
          defaultDueDay: int.tryParse(_dueDayController.text) ?? 1,
          taxType: TaxType.included,
          expensesTemplate: _expenses,
          landlordName: effLandlordName,
          landlordPhone: effLandlordPhone,
          landlordEmail: effLandlordEmail,
          isDetailed: isDetailedFinal,
          propertyType: _propertyType,
          unitNumber: unitNumberVal,
          roomCount: _roomCount,
          areaSqm: areaVal,
          floor: _floor,
          totalFloors: totalFloorsVal,
          furnishing: _furnishing,
          heatingType: _heatingType,
          amenities: _selectedAmenities.toList(),
          description: descriptionVal,
        ));
        if (finalOwners.isNotEmpty) {
          await repo.savePropertyOwners(widget.property!.id, finalOwners);
        }
      } else {
        createdProp = await repo.createProperty(
          address: _addressController.text.trim(),
          name: _nameController.text.trim(),
          city: cityVal,
          defaultMonthlyRent: double.parse(_rentController.text),
          defaultDepositAmount: _depositController.text.isNotEmpty 
              ? double.parse(_depositController.text) 
              : null,
          currency: _selectedCurrency,
          defaultDepositCurrency: _depositCurrency,
          defaultDueDay: int.tryParse(_dueDayController.text) ?? 1,
          taxType: TaxType.included,
          expensesTemplate: _expenses,
          landlordName: effLandlordName,
          landlordPhone: effLandlordPhone,
          landlordEmail: effLandlordEmail,
          isDetailed: isDetailedFinal,
          propertyType: _propertyType,
          unitNumber: unitNumberVal,
          roomCount: _roomCount,
          areaSqm: areaVal,
          floor: _floor,
          totalFloors: totalFloorsVal,
          furnishing: _furnishing,
          heatingType: _heatingType,
          amenities: _selectedAmenities.toList(),
          description: descriptionVal,
          owners: finalOwners.isNotEmpty ? finalOwners : null,
        );
      }
      
      if (mounted) {
        ref.invalidate(propertiesFutureProvider);
        ref.invalidate(agencyPropertiesProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEdit ? loc.propertyUpdatedSuccess : loc.propertyAddedSuccess)),
        );

        final userRole = ref.read(userRoleProvider);
        final isAgency = userRole == 'agency';

        context.pop();

        if (isAgency && createdProp != null) {
          final token = await repo.getLandlordOwnershipInviteToken(createdProp.id);
          if (token != null && token.isNotEmpty && context.mounted) {
            OwnershipShareSheet.show(
              context,
              propertyName: createdProp.name,
              landlordName: effLandlordName,
              landlordEmail: effLandlordEmail,
              token: token,
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: StanomerColors.alertPrimary),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isEdit = widget.property != null;
    final userRole = ref.watch(userRoleProvider);
    final hasAgencyBranding = ref.watch(hasAgencyBrandingProvider);
    final isAgency = userRole == 'agency' || hasAgencyBranding;
    final isDetailedActive = hasAgencyBranding || _isDetailed;

    final propertiesAsync = ref.watch(propertiesStreamProvider);
    final hasAgencyManagedProperty = (propertiesAsync.value ?? []).any((p) => p.agencyId != null && p.agencyId!.isNotEmpty);
    final isAgencyClient = (userRole == 'landlord') && (hasAgencyManagedProperty || hasAgencyBranding);

    if (!isEdit && isAgencyClient) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.addProperty)),
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
                  loc.localeName == 'tr' ? 'Acente Yönetiminde' : (loc.localeName.startsWith('sr') ? 'Upravlja agencija' : 'Managed by Agency'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  loc.localeName == 'tr'
                      ? 'Mülkleriniz acente tarafından yönetilmektedir. Yeni mülk ekleme işlemleri yalnızca bağlı olduğunuz acente tarafından yapılabilir.'
                      : (loc.localeName.startsWith('sr')
                          ? 'Vašim nekretninama upravlja agencija. Dodavanje novih nekretnina može izvršiti samo vaša agencija.'
                          : 'Your properties are managed by an agency. Adding new properties can only be done by your managing agency.'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: StanomerColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.pop(),
                  child: Text(loc.cancel),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.property != null ? loc.editProperty : loc.addProperty),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!isAgency && !isEdit) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: StanomerColors.brandPrimary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: StanomerColors.brandPrimary.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: StanomerColors.brandPrimary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(LucideIcons.qrCode, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  loc.agencyPropertyTakeoverTitle,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: StanomerColors.textPrimary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  loc.agencyPropertyTakeoverDesc,
                                  style: const TextStyle(fontSize: 12, color: StanomerColors.textTertiary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            context.pop();
                            JoinPropertySheet.show(context);
                          },
                          icon: const Icon(LucideIcons.scanLine, size: 18),
                          label: Text(loc.scanQrOrEnterInviteCodeBtn, style: const TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: StanomerColors.brandPrimary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Main section header "PROPERTY INFO" with Detailed Entry Toggle right next to it
              _buildPropertyInfoHeaderWithToggle(loc),
              const SizedBox(height: 16),

              if (!isDetailedActive) ...[
                // ==========================================
                // 1. STANDARD ENTRY MODE (3 BASIC FIELDS)
                // ==========================================
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: loc.address,
                    prefixIcon: const Icon(LucideIcons.mapPin, size: 20),
                  ),
                  validator: (val) => val == null || val.isEmpty ? loc.fieldRequired : null,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cityController,
                  decoration: InputDecoration(
                    labelText: loc.localeName == 'tr' ? 'Şehir (İl / Şehir)' : 'City',
                    hintText: loc.localeName == 'tr' ? 'Örn: İstanbul, Belgrad' : 'e.g. Istanbul, Belgrade',
                    prefixIcon: const Icon(LucideIcons.building, size: 20),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: loc.propertyName,
                    hintText: loc.propertyNameHint,
                    prefixIcon: const Icon(LucideIcons.tag, size: 20),
                  ),
                  onChanged: (val) => _nameManuallyEdited = true,
                  validator: (val) => val == null || val.isEmpty ? loc.fieldRequired : null,
                ),
              ] else ...[
                // ==========================================
                // 2. DETAILED ENTRY MODE (RICH SECTIONS)
                // ==========================================
                
                // Section 1: Property and Location
                _buildStepHeader(1, loc.propertyAndLocationInfo),
                const SizedBox(height: 16),
                _buildPropertyTypeSegmented(loc),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: loc.address,
                    hintText: loc.addressDetailedHint,
                    prefixIcon: const Icon(LucideIcons.mapPin, size: 20),
                  ),
                  validator: (val) => val == null || val.isEmpty ? loc.fieldRequired : null,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _cityController,
                        decoration: InputDecoration(
                          labelText: loc.localeName == 'tr' ? 'Şehir' : 'City',
                          hintText: loc.localeName == 'tr' ? 'Örn: Belgrad, İstanbul' : 'e.g. Belgrade',
                          prefixIcon: const Icon(LucideIcons.building, size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _unitNumberController,
                        decoration: InputDecoration(
                          labelText: loc.unitNumberLabel,
                          hintText: loc.unitNumberHint,
                          prefixIcon: const Icon(LucideIcons.doorOpen, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: loc.propertyName,
                    hintText: loc.propertyNameHint,
                    prefixIcon: const Icon(LucideIcons.tag, size: 20),
                  ),
                  onChanged: (val) => _nameManuallyEdited = true,
                  validator: (val) => val == null || val.isEmpty ? loc.fieldRequired : null,
                ),

                const SizedBox(height: 32),

                // Section 2: Structural and Financial Metrics
                _buildStepHeader(2, loc.structuralAndFinancialMetrics),
                const SizedBox(height: 16),
                _buildRoomCountPills(loc),
                const SizedBox(height: 16),
                _buildMetricsRow(loc),

                const SizedBox(height: 32),

                // Section 3: Equipment and Heating Standards
                _buildStepHeader(3, loc.equipmentAndHeatingStandards),
                const SizedBox(height: 16),
                _buildFurnishingCards(loc),
                const SizedBox(height: 16),
                _buildHeatingTypeDropdown(loc),

                const SizedBox(height: 32),

                // Section 4: Amenities and Extended Details
                _buildStepHeader(4, loc.featuredAmenitiesLabel),
                const SizedBox(height: 16),
                _buildAmenitiesGrid(loc),
                const SizedBox(height: 16),
                _buildDescriptionField(loc),
              ],

              // --- SECTION: PROPERTY OWNERS (DEDICATED SECTION) ---
              if (isAgency || (widget.property != null && (widget.property!.landlordName?.isNotEmpty == true || widget.property!.agencyId != null))) ...[
                PropertyOwnersFormSection(
                  key: _ownersFormKey,
                  tempPropertyId: _tempPropertyId,
                  initialOwners: _owners.isNotEmpty
                      ? _owners
                      : [
                          PropertyOwner(
                            isPrimary: true,
                            firstName: _landlordNameController.text.trim(),
                            phone: _landlordPhoneController.text.trim(),
                            email: _landlordEmailController.text.trim(),
                          )
                        ],
                  onOwnersChanged: (owners) {
                    _owners = owners;
                    if (owners.isNotEmpty) {
                      final primary = owners.firstWhere((o) => o.isPrimary, orElse: () => owners.first);
                      _landlordNameController.text = primary.displayName;
                      _landlordPhoneController.text = primary.phone ?? '';
                      _landlordEmailController.text = primary.email ?? '';
                    }
                  },
                ),
              ],

              if (isAgency) ...[
                const SizedBox(height: 32),
                _buildSectionHeader(
                  loc.localeName == 'tr'
                      ? 'Ev Sahibi İletişim Bilgileri'
                      : (loc.localeName == 'ru'
                          ? 'Контактная информация арендодателя'
                          : (loc.localeName.startsWith('sr')
                              ? 'Kontakt podaci stanodavca'
                              : 'Landlord Contact Information')),
                  LucideIcons.userCheck,
                  subtitle: loc.localeName == 'tr'
                      ? 'Acente mülk eklerken ev sahibi bilgileri girilir. Kayıttan sonra ev sahibine sahiplik QR/Linki gönderilir.'
                      : (loc.localeName == 'ru'
                          ? 'Введите данные арендодателя при добавлении объекта. После создания будет отправлен QR/ссылка на владение.'
                          : (loc.localeName.startsWith('sr')
                              ? 'Unesite podatke stanodavca pri dodavanju nekretnine. QR/Link za preuzimanje vlasništva biće dostupan nakon kreiranja.'
                              : 'Enter landlord details when adding property. An ownership QR/Link will be shared after creation.')),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _landlordNameController,
                  decoration: InputDecoration(
                    labelText: loc.localeName == 'tr'
                        ? 'Ev Sahibinin Adı Soyadı *'
                        : (loc.localeName == 'ru'
                            ? 'ФИО арендодателя *'
                            : (loc.localeName.startsWith('sr')
                                ? 'Ime i prezime stanodavca *'
                                : 'Landlord Full Name *')),
                    prefixIcon: const Icon(LucideIcons.user, size: 20),
                  ),
                  validator: (val) => isAgency && (val == null || val.trim().isEmpty) ? loc.fieldRequired : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _landlordEmailController,
                  decoration: InputDecoration(
                    labelText: isAgency
                        ? (loc.localeName == 'tr' ? 'Ev Sahibinin E-posta Adresi *' : (loc.localeName == 'ru' ? 'Email арендодателя *' : (loc.localeName.startsWith('sr') ? 'Email stanodavca *' : 'Landlord Email *')))
                        : (loc.localeName == 'tr' ? 'Ev Sahibinin E-posta Adresi' : (loc.localeName == 'ru' ? 'Email арендодателя' : (loc.localeName.startsWith('sr') ? 'Email stanodavca' : 'Landlord Email'))),
                    hintText: 'ornek@email.com',
                    prefixIcon: const Icon(LucideIcons.mail, size: 20),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) {
                    if (!isAgency) return null;
                    if (val == null || val.trim().isEmpty) {
                      return loc.fieldRequired;
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val.trim())) {
                      return loc.localeName == 'tr'
                          ? 'Geçerli bir e-posta adresi giriniz'
                          : (loc.localeName == 'ru'
                              ? 'Введите корректный e-mail'
                              : (loc.localeName.startsWith('sr')
                                  ? 'Unesite validnu email adresu'
                                  : 'Please enter a valid email address'));
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _landlordPhoneController,
                  decoration: InputDecoration(
                    labelText: loc.localeName == 'tr'
                        ? 'Ev Sahibinin Telefon Numarası'
                        : (loc.localeName == 'ru'
                            ? 'Номер телефона арендодателя'
                            : (loc.localeName.startsWith('sr')
                                ? 'Broj telefona stanodavca'
                                : 'Landlord Phone Number')),
                    hintText: '+90 5xx xxx xx xx',
                    prefixIcon: const Icon(LucideIcons.phone, size: 20),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ],
              
              const SizedBox(height: 40),
              
              // --- SECTION: DEFAULT CONTRACT TERMS ---
              _buildSectionHeader(
                loc.defaultLeaseTermsHeader,
                LucideIcons.fileText,
                subtitle: loc.defaultLeaseTermsSubtitle,
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _rentController,
                      decoration: InputDecoration(
                        labelText: loc.monthlyRent,
                        prefixIcon: const Icon(LucideIcons.banknote, size: 20),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val == null || val.isEmpty) return loc.fieldRequired;
                        if (double.tryParse(val) == null) return loc.invalidNumber;
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      value: _selectedCurrency,
                      decoration: InputDecoration(
                        labelText: loc.currency,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                        DropdownMenuItem(value: 'RSD', child: Text('RSD')),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedCurrency = val!;
                          _depositCurrency = val;
                        });
                      },
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
                      decoration: InputDecoration(
                        labelText: loc.depositAmount,
                        prefixIcon: const Icon(LucideIcons.shield, size: 20),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val != null && val.isNotEmpty && double.tryParse(val) == null) return loc.invalidNumber;
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
                      onChanged: (val) => setState(() => _depositCurrency = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildDueDayField(loc),
              const SizedBox(height: 24),
              _buildExpensesSection(loc),
              const SizedBox(height: 48),

              // Action Buttons
              Row(
                children: [
                  if (isDetailedActive) ...[
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: _resetForm,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        child: Text(loc.clearFormBtn, style: const TextStyle(color: Color(0xFF475569))),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {
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
                      icon: _isLoading ? const SizedBox.shrink() : const Icon(LucideIcons.check, size: 18),
                      label: _isLoading 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(isEdit ? loc.saveChanges : loc.addProperty, style: const TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: StanomerColors.brandPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- COMPONENT BUILDERS ---

  Widget _buildPropertyInfoHeaderWithToggle(AppLocalizations loc) {
    final hasAgencyBranding = ref.watch(hasAgencyBrandingProvider);
    final isLocked = hasAgencyBranding;
    final isDetailedActive = isLocked ? true : _isDetailed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.home, size: 18, color: StanomerColors.brandPrimary),
                const SizedBox(width: 8),
                Text(
                  loc.propertyDetailsHeader,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: StanomerColors.brandPrimary,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: isLocked ? null : () => setState(() => _isDetailed = !_isDetailed),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDetailedActive ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDetailedActive ? const Color(0xFF93C5FD) : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isLocked ? LucideIcons.lock : LucideIcons.sparkles,
                      size: 13,
                      color: isDetailedActive ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      loc.detailedEntry,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: isDetailedActive ? FontWeight.w700 : FontWeight.w600,
                        color: isDetailedActive ? const Color(0xFF1D4ED8) : const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      height: 20,
                      width: 32,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: Switch.adaptive(
                          value: isDetailedActive,
                          activeColor: const Color(0xFF2563EB),
                          onChanged: isLocked ? null : (val) => setState(() => _isDetailed = val),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Divider(),
      ],
    );
  }

  Widget _buildStepHeader(int step, String title) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Center(
            child: Text(
              '$step',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2563EB),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPropertyTypeSegmented(AppLocalizations loc) {
    final types = [
      {'id': 'apartment', 'label': loc.propertyTypeApartment, 'icon': LucideIcons.building},
      {'id': 'house', 'label': loc.propertyTypeHouse, 'icon': LucideIcons.home},
      {'id': 'commercial', 'label': loc.propertyTypeCommercial, 'icon': LucideIcons.briefcase},
      {'id': 'garage', 'label': loc.propertyTypeGarage, 'icon': LucideIcons.warehouse},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.propertyTypeLabel,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: types.map((t) {
              final isSelected = _propertyType == t['id'];
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _propertyType = t['id'] as String),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          t['icon'] as IconData,
                          size: 15,
                          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            t['label'] as String,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRoomCountPills(AppLocalizations loc) {
    final rooms = ['studio', '1.0', '1.5', '2.0', '2.5', '3.0', '3.5', '4.0', '5.0+'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.roomCountLabel,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: rooms.map((r) {
            final isSelected = _roomCount == r;
            final label = r == 'studio' ? (loc.localeName == 'tr' ? 'Stüdyo' : 'Studio') : r;
            return ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (_) => setState(() => _roomCount = r),
              selectedColor: const Color(0xFFEFF6FF),
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF475569),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMetricsRow(AppLocalizations loc) {
    final floorDropdown = DropdownButtonFormField<String>(
      value: _floor,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: loc.floorLevelLabel,
        prefixIcon: const Icon(LucideIcons.layers, size: 20),
      ),
      items: [
        DropdownMenuItem(value: 'suteren', child: Text(loc.floorSuteren, overflow: TextOverflow.ellipsis)),
        DropdownMenuItem(value: 'prizemlje', child: Text(loc.floorPrizemlje, overflow: TextOverflow.ellipsis)),
        DropdownMenuItem(value: 'visoko_prizemlje', child: Text(loc.floorVisokoPrizemlje, overflow: TextOverflow.ellipsis)),
        DropdownMenuItem(value: '1', child: Text(loc.floorNth('1'), overflow: TextOverflow.ellipsis)),
        DropdownMenuItem(value: '2', child: Text(loc.floorNth('2'), overflow: TextOverflow.ellipsis)),
        DropdownMenuItem(value: '3', child: Text(loc.floorNth('3'), overflow: TextOverflow.ellipsis)),
        DropdownMenuItem(value: '4', child: Text(loc.floorNth('4'), overflow: TextOverflow.ellipsis)),
        DropdownMenuItem(value: '5', child: Text(loc.floorNth('5'), overflow: TextOverflow.ellipsis)),
        DropdownMenuItem(value: '6', child: Text(loc.floorNth('6'), overflow: TextOverflow.ellipsis)),
        DropdownMenuItem(value: '7', child: Text(loc.floorNth('7'), overflow: TextOverflow.ellipsis)),
        DropdownMenuItem(value: '8', child: Text(loc.floorNth('8'), overflow: TextOverflow.ellipsis)),
        DropdownMenuItem(value: '9', child: Text(loc.floorNth('9'), overflow: TextOverflow.ellipsis)),
        DropdownMenuItem(value: '10+', child: Text(loc.floorNth('10+'), overflow: TextOverflow.ellipsis)),
        DropdownMenuItem(value: 'potkrovlje', child: Text(loc.floorPotkrovlje, overflow: TextOverflow.ellipsis)),
        DropdownMenuItem(value: 'other', child: Text(loc.floorOther, overflow: TextOverflow.ellipsis)),
      ],
      onChanged: (val) => setState(() => _floor = val),
    );

    final areaField = TextFormField(
      controller: _areaController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: loc.areaSqmLabel,
        hintText: '85',
        suffixText: 'm²',
        prefixIcon: const Icon(LucideIcons.maximize2, size: 20),
      ),
    );

    final totalFloorsField = TextFormField(
      controller: _totalFloorsController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: loc.totalFloorsLabel,
        hintText: '6',
        prefixIcon: const Icon(LucideIcons.building2, size: 20),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: areaField),
                  const SizedBox(width: 12),
                  Expanded(child: totalFloorsField),
                ],
              ),
              const SizedBox(height: 16),
              floorDropdown,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: areaField),
            const SizedBox(width: 12),
            Expanded(flex: 3, child: floorDropdown),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: totalFloorsField),
          ],
        );
      },
    );
  }

  Widget _buildFurnishingCards(AppLocalizations loc) {
    final options = [
      {
        'id': 'furnished',
        'title': loc.furnishingFurnished,
        'desc': loc.furnishingFurnishedDesc,
        'icon': LucideIcons.armchair,
      },
      {
        'id': 'semi_furnished',
        'title': loc.furnishingSemi,
        'desc': loc.furnishingSemiDesc,
        'icon': LucideIcons.utensils,
      },
      {
        'id': 'unfurnished',
        'title': loc.furnishingUnfurnished,
        'desc': loc.furnishingUnfurnishedDesc,
        'icon': LucideIcons.box,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.furnishingLabel,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
        ),
        const SizedBox(height: 8),
        Column(
          children: options.map((opt) {
            final isSelected = _furnishing == opt['id'];
            return GestureDetector(
              onTap: () => setState(() => _furnishing = opt['id'] as String),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? LucideIcons.checkCircle2 : LucideIcons.circle,
                      size: 18,
                      color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      opt['icon'] as IconData,
                      size: 16,
                      color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            opt['title'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            opt['desc'] as String,
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildHeatingTypeDropdown(AppLocalizations loc) {
    return DropdownButtonFormField<String>(
      value: _heatingType,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: loc.heatingTypeLabel,
        prefixIcon: const Icon(LucideIcons.flame, size: 20),
      ),
      items: [
        DropdownMenuItem(value: 'cg', child: Text(loc.heatingCg, overflow: TextOverflow.ellipsis)),
        DropdownMenuItem(value: 'eg', child: Text(loc.heatingEg, overflow: TextOverflow.ellipsis)),
        DropdownMenuItem(value: 'gas', child: Text(loc.heatingGas, overflow: TextOverflow.ellipsis)),
        DropdownMenuItem(value: 'underfloor', child: Text(loc.heatingUnderfloor, overflow: TextOverflow.ellipsis)),
        DropdownMenuItem(value: 'ta', child: Text(loc.heatingTa, overflow: TextOverflow.ellipsis)),
      ],
      onChanged: (val) => setState(() => _heatingType = val),
    );
  }

  Widget _buildAmenitiesGrid(AppLocalizations loc) {
    final amenities = [
      {'id': 'pets_allowed', 'label': loc.amenityPets, 'icon': LucideIcons.pawPrint},
      {'id': 'elevator', 'label': loc.amenityElevator, 'icon': LucideIcons.arrowUpCircle},
      {'id': 'balcony', 'label': loc.amenityBalcony, 'icon': LucideIcons.sunMedium},
      {'id': 'parking', 'label': loc.amenityParking, 'icon': LucideIcons.car},
      {'id': 'storage', 'label': loc.amenityStorage, 'icon': LucideIcons.package},
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: amenities.map((a) {
        final id = a['id'] as String;
        final isChecked = _selectedAmenities.contains(id);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isChecked) {
                _selectedAmenities.remove(id);
              } else {
                _selectedAmenities.add(id);
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isChecked ? const Color(0xFFEFF6FF) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isChecked ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                width: isChecked ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isChecked ? LucideIcons.checkSquare : LucideIcons.square,
                  size: 16,
                  color: isChecked ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
                ),
                const SizedBox(width: 8),
                Icon(
                  a['icon'] as IconData,
                  size: 15,
                  color: isChecked ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                ),
                const SizedBox(width: 6),
                Text(
                  a['label'] as String,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isChecked ? FontWeight.w700 : FontWeight.w500,
                    color: isChecked ? const Color(0xFF1E3A8A) : const Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDescriptionField(AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              loc.extendedDescriptionLabel,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
            ),
            Text(
              '${_descriptionController.text.length} / 2000',
              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          maxLength: 2000,
          maxLines: 4,
          buildCounter: (ctx, {required currentLength, required isFocused, maxLength}) => null,
          decoration: InputDecoration(
            hintText: loc.extendedDescriptionHint,
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: StanomerColors.brandPrimary),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: StanomerColors.brandPrimary,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: StanomerColors.textTertiary,
            ),
          ),
        ],
        const SizedBox(height: 8),
        const Divider(),
      ],
    );
  }

  Widget _buildDueDayField(AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.dueDayOfMonth,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _dueDayController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: '1 - 31',
            prefixIcon: const Icon(LucideIcons.calendarDays),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return null;
            final day = int.tryParse(value);
            if (day == null || day < 1 || day > 31) {
              return loc.enterDayBetween1and31;
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildExpensesSection(AppLocalizations loc) {
    String getTooltip(String name) {
      switch (name) {
        case 'Infostan': return loc.infoTooltip;
        case 'Struja (Electricity)': return loc.electricityTooltip;
        case 'Internet/TV': return loc.internetTooltip;
        case 'Održavanje zgrade (Maintenance)': return loc.maintenanceTooltip;
        default: return '';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.expenseConfiguration,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: StanomerColors.textTertiary,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: StanomerColors.bgCard,
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
                          message: getTooltip(expense.name),
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
                      activeColor: StanomerColors.brandPrimary,
                      onChanged: (val) {
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
                            onChanged: (PaymentReceiver newReceiver) {
                              setState(() {
                                _expenses[index] = expense.copyWith(receiver: newReceiver);
                              });
                            },
                          ),
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
      ],
    );
  }
}
