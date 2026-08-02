import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
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
import 'package:stanomer/core/utils/currency_utils.dart';
import 'package:stanomer/core/utils/expense_utils.dart';
import '../../auth/data/auth_providers.dart';
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
      if (p.expensesTemplate.isNotEmpty) {
        _expenses = List.from(p.expensesTemplate.where((e) => e.name != 'Porez (Tax)'));
      }
    }
    _addressController.addListener(_onAddressChanged);
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
          landlordName: _landlordNameController.text.trim(),
          landlordPhone: _landlordPhoneController.text.trim(),
          landlordEmail: _landlordEmailController.text.trim(),
        ));
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
          landlordName: _landlordNameController.text.trim(),
          landlordPhone: _landlordPhoneController.text.trim(),
          landlordEmail: _landlordEmailController.text.trim(),
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
              landlordName: _landlordNameController.text.trim(),
              landlordEmail: _landlordEmailController.text.trim(),
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
    final isAgency = userRole == 'agency';

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
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Acentenin Eklediği Mülkü Devralın',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: StanomerColors.textPrimary),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Acente tarafından girilen mülkü QR kod okutarak veya davet kodu ile hesabınıza ekleyin.',
                                  style: TextStyle(fontSize: 12, color: StanomerColors.textTertiary),
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
                          label: const Text('QR Kod Okut / Davet Kodu Gir', style: TextStyle(fontWeight: FontWeight.bold)),
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
                const SizedBox(height: 28),
              ],

              // --- SECTION: PROPERTY DETAILS ---
              _buildSectionHeader(
                loc.propertyDetailsHeader,
                LucideIcons.home,
              ),
              const SizedBox(height: 16),
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

              if (isAgency) ...[
                const SizedBox(height: 32),
                _buildSectionHeader(
                  'Ev Sahibi İletişim Bilgileri',
                  LucideIcons.userCheck,
                  subtitle: 'Acente mülk eklerken ev sahibi bilgileri girilir. Kayıttan sonra ev sahibine sahiplik QR/Linki gönderilir.',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _landlordNameController,
                  decoration: const InputDecoration(
                    labelText: 'Ev Sahibinin Adı Soyadı *',
                    prefixIcon: Icon(LucideIcons.user, size: 20),
                  ),
                  validator: (val) => isAgency && (val == null || val.trim().isEmpty) ? loc.fieldRequired : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _landlordEmailController,
                  decoration: const InputDecoration(
                    labelText: 'Ev Sahibinin E-posta Adresi',
                    hintText: 'ornek@email.com (İsteğe bağlı)',
                    prefixIcon: Icon(LucideIcons.mail, size: 20),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _landlordPhoneController,
                  decoration: const InputDecoration(
                    labelText: 'Ev Sahibinin Telefon Numarası',
                    hintText: '+90 5xx xxx xx xx',
                    prefixIcon: Icon(LucideIcons.phone, size: 20),
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
                          _depositCurrency = val; // Default deposit to match rent
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 24),
              
              const SizedBox(height: 48),
              ElevatedButton(
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
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(isEdit ? loc.saveChanges : loc.addProperty),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
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
