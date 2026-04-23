import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stanomer/features/property/presentation/widgets/payment_responsibility_selector.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/colors.dart';
import '../data/property_repository.dart';
import '../domain/property.dart';
import '../domain/contract.dart';
import 'package:stanomer/core/utils/currency_utils.dart';
import 'package:stanomer/core/utils/expense_utils.dart';

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
  final _rentController = TextEditingController();
  final _depositController = TextEditingController();
  final _dueDayController = TextEditingController(text: '1');
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
      _rentController.text = p.defaultMonthlyRent.toStringAsFixed(0);
      _depositController.text = p.defaultDepositAmount?.toStringAsFixed(0) ?? '';
      _selectedCurrency = p.currency;
      _depositCurrency = p.defaultDepositCurrency;
      _nameManuallyEdited = true;
      _dueDayController.text = p.defaultDueDay.toString();
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
    _rentController.dispose();
    _depositController.dispose();
    _dueDayController.dispose();
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

      if (isEdit) {
        await repo.updateProperty(widget.property!.copyWith(
          address: _addressController.text.trim(),
          name: _nameController.text.trim(),
          defaultMonthlyRent: double.parse(_rentController.text),
          defaultDepositAmount: _depositController.text.isNotEmpty 
              ? double.parse(_depositController.text) 
              : null,
          currency: _selectedCurrency,
          defaultDepositCurrency: _depositCurrency,
          defaultDueDay: int.tryParse(_dueDayController.text) ?? 1,
          taxType: TaxType.included,
          expensesTemplate: _expenses,
        ));
      } else {
        await repo.createProperty(
          address: _addressController.text.trim(),
          name: _nameController.text.trim(),
          defaultMonthlyRent: double.parse(_rentController.text),
          defaultDepositAmount: _depositController.text.isNotEmpty 
              ? double.parse(_depositController.text) 
              : null,
          currency: _selectedCurrency,
          defaultDepositCurrency: _depositCurrency,
          defaultDueDay: int.tryParse(_dueDayController.text) ?? 1,
          taxType: TaxType.included,
          expensesTemplate: _expenses,
        );
      }
      
      if (mounted) {
        // propertiesStreamProvider is a Supabase .stream(), it updates automatically
        ref.invalidate(propertiesFutureProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEdit ? loc.propertyUpdatedSuccess : loc.propertyAddedSuccess)),
        );
        context.pop();
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
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: loc.propertyName,
                  hintText: loc.propertyNameHint,
                  prefixIcon: const Icon(LucideIcons.tag, size: 20),
                ),
                onChanged: (val) => _nameManuallyEdited = true,
                validator: (val) => val == null || val.isEmpty ? loc.fieldRequired : null,
              ),
              
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
                        if (double.tryParse(val) == null) return 'Invalid number';
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
