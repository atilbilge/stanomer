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
import 'widgets/property_specs_form_section.dart';
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

              // --- SECTION: PROPERTY OWNERS (DEDICATED FOR AGENCY / MANAGED PROPERTIES) ---
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
                const SizedBox(height: 32),
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
                // 2. DETAILED ENTRY MODE (PREMIUM CARDS)
                // ==========================================
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(LucideIcons.mapPin, size: 18, color: Color(0xFF2563EB)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  loc.propertyAndLocationInfo,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  loc.localeName == 'tr'
                                      ? 'Açık adres, şehir ve mülk rumuzu'
                                      : 'Full address, city and property title',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
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
                      TextFormField(
                        controller: _cityController,
                        decoration: InputDecoration(
                          labelText: loc.localeName == 'tr' ? 'Şehir' : 'City',
                          hintText: loc.localeName == 'tr' ? 'Örn: Belgrad, İstanbul' : 'e.g. Belgrade',
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
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                PropertySpecsFormSection(
                  propertyType: _propertyType,
                  onPropertyTypeChanged: (val) => setState(() => _propertyType = val),
                  unitNumberController: _unitNumberController,
                  roomCount: _roomCount,
                  onRoomCountChanged: (val) => setState(() => _roomCount = val),
                  areaController: _areaController,
                  floor: _floor,
                  onFloorChanged: (val) => setState(() => _floor = val),
                  totalFloorsController: _totalFloorsController,
                  furnishing: _furnishing,
                  onFurnishingChanged: (val) => setState(() => _furnishing = val),
                  heatingType: _heatingType,
                  onHeatingTypeChanged: (val) => setState(() => _heatingType = val),
                  selectedAmenities: _selectedAmenities,
                  onAmenitiesChanged: (val) => setState(() => _selectedAmenities = val),
                  descriptionController: _descriptionController,
                ),
              ],

              const SizedBox(height: 32),
              
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
