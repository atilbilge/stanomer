
import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/expense_utils.dart';
import '../domain/property.dart';
import '../domain/contract.dart';
import '../../auth/data/auth_providers.dart';
import '../data/property_repository.dart';
import '../presentation/widgets/payment_responsibility_selector.dart';

class PropertySettingsScreen extends ConsumerStatefulWidget {
  final Property property;
  final String initialTab;
  const PropertySettingsScreen({super.key, required this.property, this.initialTab = 'contract'});

  @override
  ConsumerState<PropertySettingsScreen> createState() => _PropertySettingsScreenState();
}

class _PropertySettingsScreenState extends ConsumerState<PropertySettingsScreen> {
  late final ValueNotifier<String> settingsSectionNotifier;

  void _onSectionChanged() {
    if (mounted) setState(() {});
  }

  // Property controllers
  late TextEditingController _nameController;
  late TextEditingController _addressController;

  // Contract (property defaults) controllers
  late TextEditingController _rentController;
  late TextEditingController _depositController;
  late TextEditingController _dueDayController;
  late String _selectedCurrency;
  late String _depositCurrency;
  bool _isLoading = false;
  List<ExpenseItem> _expenses = [];

  // Contract (active contract) controllers
  late TextEditingController _contractRentController;
  late TextEditingController _contractDepositController;
  late TextEditingController _contractDueDayController;
  late String _contractCurrency;
  late String _contractDepositCurrency;
  List<ExpenseItem> _contractExpenses = [];
  DateTime? _contractStartDate;
  DateTime? _contractEndDate;
  bool _isContractLoading = false;
  String? _loadedContractId;

  @override
  void initState() {
    super.initState();
    settingsSectionNotifier = ValueNotifier(widget.initialTab);
    settingsSectionNotifier.addListener(_onSectionChanged);
    _nameController = TextEditingController(text: widget.property.name);
    _addressController = TextEditingController(text: widget.property.address);
    _rentController = TextEditingController(text: widget.property.defaultMonthlyRent.toStringAsFixed(0));
    _depositController = TextEditingController(text: widget.property.defaultDepositAmount?.toStringAsFixed(0) ?? '');
    _dueDayController = TextEditingController(text: widget.property.defaultDueDay.toString());
    _selectedCurrency = widget.property.currency;
    _depositCurrency = widget.property.defaultDepositCurrency;
    _expenses = List.from(widget.property.expensesTemplate.where((e) => e.name != 'Porez (Tax)'));
    // Contract controllers (empty; will be populated when active contract loads)
    _contractRentController = TextEditingController();
    _contractDepositController = TextEditingController();
    _contractDueDayController = TextEditingController();
    _contractCurrency = 'EUR';
    _contractDepositCurrency = 'EUR';
  }

  @override
  void didUpdateWidget(PropertySettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.property != oldWidget.property) {
      _nameController.text = widget.property.name;
      _addressController.text = widget.property.address;
      _rentController.text = widget.property.defaultMonthlyRent.toStringAsFixed(0);
      _depositController.text = widget.property.defaultDepositAmount?.toStringAsFixed(0) ?? '';
      _dueDayController.text = widget.property.defaultDueDay.toString();
      _selectedCurrency = widget.property.currency;
      _depositCurrency = widget.property.defaultDepositCurrency;
      _expenses = List.from(widget.property.expensesTemplate.where((e) => e.name != 'Porez (Tax)'));
    }
  }

  @override
  void dispose() {
    settingsSectionNotifier.removeListener(_onSectionChanged);
    settingsSectionNotifier.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _rentController.dispose();
    _depositController.dispose();
    _dueDayController.dispose();
    _contractRentController.dispose();
    _contractDepositController.dispose();
    _contractDueDayController.dispose();
    super.dispose();
  }


  Future<void> _update() async {
    if (_expenses.any((e) => e.receiver == PaymentReceiver.unselected)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.selectPaymentReceiverWarning), backgroundColor: StanomerColors.alertPrimary),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(propertyRepositoryProvider);
      
      await repo.updateProperty(widget.property.copyWith(
            name: _nameController.text.trim(),
            address: _addressController.text.trim(),
            defaultMonthlyRent: double.parse(_rentController.text),
            defaultDepositAmount: _depositController.text.isNotEmpty ? double.parse(_depositController.text) : null,
            currency: _selectedCurrency,
            defaultDepositCurrency: _depositCurrency,
            defaultDueDay: int.tryParse(_dueDayController.text) ?? 1,
            taxType: TaxType.included,
            expensesTemplate: _expenses,
          ));
      
      ref.invalidate(propertiesStreamProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.propertyUpdatedSuccess)),
        );
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

    final user = ref.watch(currentUserProvider);
    final role = user?.userMetadata?['role'] as String?;
    final roleColor = StanomerColors.getRoleColor(role);
    final isLandlord = widget.property.landlordId == user?.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.propertySettingsLabel),
        backgroundColor: roleColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // ── Toggle ─────────────────────────────────────────────
        if (isLandlord)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'contract',
                  label: Text(loc.contractSettings, style: const TextStyle(fontSize: 12)),
                  icon: const Icon(LucideIcons.fileEdit, size: 15),
                ),
                ButtonSegment(
                  value: 'property',
                  label: Text(loc.propertySettingsLabel, style: const TextStyle(fontSize: 12)),
                  icon: const Icon(LucideIcons.home, size: 15),
                ),
              ],
              selected: {settingsSectionNotifier.value},
              onSelectionChanged: (val) => settingsSectionNotifier.value = val.first,
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: roleColor,
                selectedForegroundColor: Colors.white,
              ),
            ),
          ),

        // ── Panel ──────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: (isLandlord && settingsSectionNotifier.value == 'property')
                ? _buildPropertyPanel(loc, roleColor)
                : _buildContractPanel(loc, user, roleColor),
          ),
        ),
      ],
      ),
    );
  }

  Widget _buildContractPanel(AppLocalizations loc, User? user, Color roleColor) {
    final activeContractAsync = ref.watch(activeContractProvider(widget.property.id));
    final isLandlord = widget.property.landlordId == user?.id;
    final targetRole = isLandlord ? loc.tenant : loc.landlord;


    return activeContractAsync.when(
      data: (contract) {
        if (contract == null) {
          return Column(
            children: [
              const SizedBox(height: 40),
              const Icon(LucideIcons.fileText, size: 48, color: StanomerColors.textTertiary),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  loc.noActiveContract,
                  style: const TextStyle(color: StanomerColors.textTertiary),
                ),
              ),
            ],
          );
        }
        // Populate controllers lazily when a new contract loads
        if (_loadedContractId != contract.id) {
          _loadedContractId = contract.id;
          _contractRentController.text = contract.monthlyRent.toStringAsFixed(0);
          _contractDepositController.text = contract.depositAmount?.toStringAsFixed(0) ?? '';
          _contractDueDayController.text = contract.dueDay.toString();
          _contractCurrency = contract.currency;
          _contractDepositCurrency = contract.depositCurrency;
          _contractExpenses = List.from(contract.expensesConfig);
          _contractStartDate = contract.startDate;
          _contractEndDate = contract.endDate;
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: roleColor.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: roleColor.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                   Icon(LucideIcons.info, size: 16, color: roleColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      loc.contractTermsInfo,
                      style: TextStyle(fontSize: 12, color: roleColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (contract.isEnded) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: StanomerColors.textTertiary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: StanomerColors.borderDefault),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.fileX2, size: 16, color: StanomerColors.textTertiary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        loc.contractTerminatedOn(contract.endDate != null ? DateFormat('dd/MM/yyyy').format(contract.endDate!) : '-'),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: StanomerColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ] else if (contract.terminationApproved) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.calendarCheck, size: 16, color: Colors.orange),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        loc.contractWillEndOn(contract.endDate != null ? DateFormat('dd/MM/yyyy').format(contract.endDate!) : '-'),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (contract.status == ContractStatus.revisionRequested) ...[
              _buildNegotiationBanner(loc, contract, user?.id, roleColor),
              const SizedBox(height: 16),
            ],
            if (contract.status == ContractStatus.terminationRequested) ...[
              _buildTerminationBanner(loc, contract, user?.id, roleColor),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 32),
            _buildSectionHeader(loc.rentPaymentHeader, LucideIcons.banknote, roleColor),
            const SizedBox(height: 16),
            // Kira + Para birimi
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _contractRentController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: loc.monthlyRent),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      value: _contractCurrency,
                      items: const [
                        DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                        DropdownMenuItem(value: 'RSD', child: Text('RSD')),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _contractCurrency = val!;
                          _contractDepositCurrency = val; // Default deposit matches rent
                        });
                      },
                      decoration: InputDecoration(labelText: loc.currency),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _contractDepositController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: loc.depositAmount),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    value: _contractDepositCurrency,
                    items: const [
                      DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                      DropdownMenuItem(value: 'RSD', child: Text('RSD')),
                    ],
                    onChanged: (val) => setState(() => _contractDepositCurrency = val!),
                    decoration: InputDecoration(labelText: loc.currency),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contractDueDayController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: loc.dueDayOfMonth,
                prefixIcon: const Icon(LucideIcons.calendarDays, size: 20),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            // Tarihler
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _contractStartDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2040),
                      );
                      if (picked != null) {
                        setState(() {
                          _contractStartDate = picked;
                          // If end date is empty, automatically set it to 1 year after
                          if (_contractEndDate == null) {
                            _contractEndDate = DateTime(picked.year + 1, picked.month, picked.day);
                          }
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: loc.startDate,
                        prefixIcon: const Icon(LucideIcons.calendar, size: 18),
                      ),
                      child: Text(
                        _contractStartDate != null ? DateFormat('dd/MM/yyyy').format(_contractStartDate!) : '-',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _contractEndDate ?? DateTime.now().add(const Duration(days: 365)),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2040),
                      );
                      if (picked != null) setState(() => _contractEndDate = picked);
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: loc.endDate,
                        prefixIcon: const Icon(LucideIcons.calendarOff, size: 18),
                      ),
                      child: Text(
                        _contractEndDate != null ? DateFormat('dd/MM/yyyy').format(_contractEndDate!) : '-',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Masraflar
            _buildContractExpensesSection(loc, roleColor),
            const SizedBox(height: 24),
            // Belgeler
            _buildAdditionalDocumentsSection(loc, contract, roleColor),
            const SizedBox(height: 24),
            // Proposal info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.alertTriangle, size: 16, color: Colors.amber),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      loc.proposeChangesInfo(targetRole),
                      style: const TextStyle(fontSize: 12, color: Colors.amber),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(LucideIcons.send, size: 18),
              onPressed: (_isContractLoading || !_hasContractChanges(contract)) ? null : () async {
                if (_contractExpenses.any((e) => e.receiver == PaymentReceiver.unselected)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.selectPaymentReceiverWarning), backgroundColor: StanomerColors.alertPrimary),
                  );
                  return;
                }
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(loc.proposeChanges),
                    content: Text(loc.proposeChangesInfo(targetRole)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(loc.cancel)),
                      ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(loc.send)),
                    ],
                  ),
                );
                if (confirmed != true) return;
                setState(() => _isContractLoading = true);
                try {
                  final changes = <String, dynamic>{
                    'monthly_rent': double.tryParse(_contractRentController.text),
                    'currency': _contractCurrency,
                    if (_contractDepositController.text.isNotEmpty)
                      'deposit_amount': double.tryParse(_contractDepositController.text),
                    'deposit_currency': _contractDepositCurrency,
                    'due_day': int.tryParse(_contractDueDayController.text),
                    if (_contractStartDate != null) 'start_date': _contractStartDate!.toIso8601String(),
                    if (_contractEndDate != null) 'end_date': _contractEndDate!.toIso8601String(),
                    'tax_type': TaxType.included.name,
                    'expenses_config': _contractExpenses.map((e) => e.toJson()).toList(),
                  };
                  await ref.read(propertyRepositoryProvider).proposeContractChanges(contract.id, changes);
                  ref.invalidate(activeContractProvider(widget.property.id));
                  ref.invalidate(contractProposalProvider(contract.id));
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.revisionSent)),
                  );
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: StanomerColors.alertPrimary),
                  );
                } finally {
                  if (mounted) setState(() => _isContractLoading = false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: roleColor,
                foregroundColor: Colors.white,
              ),
              label: _isContractLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(loc.proposeChanges),
            ),
            if (contract.status == ContractStatus.active) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => _handleRequestTermination(contract),
                icon: const Icon(LucideIcons.calendarOff, size: 18),
                style: OutlinedButton.styleFrom(
                  foregroundColor: StanomerColors.alertPrimary,
                  side: const BorderSide(color: StanomerColors.alertPrimary),
                ),
                label: Text(loc.terminateContract),
              ),
            ],
            const SizedBox(height: 48),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(loc.errorWithDetails(e.toString()))),
    );
  }

  bool _hasContractChanges(Contract contract) {
    // Basic fields
    if (_contractRentController.text != contract.monthlyRent.toStringAsFixed(0)) return true;
    if (_contractCurrency != contract.currency) return true;
    
    final originalDeposit = contract.depositAmount?.toStringAsFixed(0) ?? '';
    if (_contractDepositController.text != originalDeposit) return true;
    if (_contractDepositCurrency != contract.depositCurrency) return true;
    
    if (_contractDueDayController.text != contract.dueDay.toString()) return true;
    
    if (_selectedCurrency != widget.property.currency) return true;
    if (_depositCurrency != widget.property.defaultDepositCurrency) return true;
    
    // Dates
    if (_contractStartDate != contract.startDate) return true;
    if (_contractEndDate != contract.endDate) return true;
    
    // Expenses
    if (_contractExpenses.length != contract.expensesConfig.length) return true;
    for (int i = 0; i < _contractExpenses.length; i++) {
      if (_contractExpenses[i] != contract.expensesConfig[i]) return true;
    }
    
    return false;
  }

  Widget _buildAdditionalDocumentsSection(AppLocalizations loc, Contract contract, Color roleColor) {
    final hasMainContract = contract.contractUrl != null && contract.contractUrl!.isNotEmpty;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(loc.documents.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: roleColor, letterSpacing: 1.1)),
        const SizedBox(height: 12),
        
        // Ana Sözleşme Yükleme Alanı (Eğer yoksa)
        if (!hasMainContract)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                const Icon(LucideIcons.fileWarning, color: Colors.orange, size: 32),
                const SizedBox(height: 12),
                Text(loc.noActiveContract, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: StanomerColors.textPrimary)),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => _uploadMainContract(contract),
                  icon: const Icon(LucideIcons.upload, size: 16),
                  label: Text(loc.uploadMainContract),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),

        if (!hasMainContract) const SizedBox(height: 16),

        Container(
          decoration: BoxDecoration(
            color: StanomerColors.bgCard, 
            borderRadius: BorderRadius.circular(16), 
            border: Border.all(color: StanomerColors.borderDefault),
          ),
          child: Column(
            children: [
              if (hasMainContract)
                ListTile(
                  leading: Icon(LucideIcons.fileSignature, color: roleColor, size: 20),
                  title: Text(loc.mainContract, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(contract.createdAt ?? DateTime.now()), style: const TextStyle(fontSize: 11)),
                  trailing: const Icon(LucideIcons.chevronRight, size: 16),
                  onTap: () async {
                    try {
                      final url = Uri.parse(contract.contractUrl!);
                      if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
                    } catch (_) {}
                  },
                ),
              if (hasMainContract && contract.additionalDocuments.isNotEmpty)
                Divider(height: 1, color: StanomerColors.borderDefault.withOpacity(0.5)),
              ...contract.additionalDocuments.asMap().entries.map((entry) {
                final index = entry.key;
                final doc = entry.value;
                return Column(
                  children: [
                    ListTile(
                      leading: const Icon(LucideIcons.fileText, color: StanomerColors.textTertiary, size: 20),
                      title: Text(doc.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      subtitle: doc.createdAt != null ? Text(DateFormat('dd/MM/yyyy').format(doc.createdAt!), style: const TextStyle(fontSize: 11)) : null,
                      trailing: IconButton(
                        icon: const Icon(LucideIcons.trash2, size: 16, color: StanomerColors.alertPrimary),
                        onPressed: () => _deleteDocument(contract, doc),
                      ),
                      onTap: () async {
                        try {
                          final url = Uri.parse(doc.url);
                          if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
                        } catch (_) {}
                      },
                    ),
                    if (index < contract.additionalDocuments.length - 1)
                      Divider(height: 1, color: StanomerColors.borderDefault.withValues(alpha: 0.5)),
                  ],
                );
              }),
              
              // Belge Ekleme Butonu (Liste içinde en altta veya liste boşsa ortada)
              Padding(
                padding: const EdgeInsets.all(12),
                child: OutlinedButton.icon(
                  onPressed: () => _uploadDocument(contract),
                  icon: Icon(LucideIcons.plus, size: 16, color: roleColor),
                  label: Text(loc.addDocument, style: TextStyle(color: roleColor, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: roleColor),
                    foregroundColor: roleColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _uploadDocument(Contract contract) async {
    final loc = AppLocalizations.of(context)!;
    final nameController = TextEditingController();
    
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.addDocument),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(hintText: loc.enterDocumentName),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(loc.cancel)),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, nameController.text), child: Text(loc.done)),
        ],
      ),
    );

    if (name == null || name.trim().isEmpty) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );

    if (result == null) return;
    
    List<int>? fileBytes = result.files.single.bytes?.toList();
    if (fileBytes == null && result.files.single.path != null) {
      fileBytes = await io.File(result.files.single.path!).readAsBytes();
    }

    if (fileBytes == null) return;

    setState(() => _isContractLoading = true);
    try {
      await ref.read(propertyRepositoryProvider).uploadContractDocument(
        contract.id,
        name.trim(),
        fileBytes,
        result.files.single.extension ?? 'pdf',
      );
      ref.invalidate(activeContractProvider(widget.property.id));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isContractLoading = false);
    }
  }

  Future<void> _uploadMainContract(Contract contract) async {
    final loc = AppLocalizations.of(context)!;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );

    if (result == null) return;

    List<int>? fileBytes = result.files.single.bytes?.toList();
    if (fileBytes == null && result.files.single.path != null) {
      fileBytes = await io.File(result.files.single.path!).readAsBytes();
    }

    if (fileBytes == null) return;

    setState(() => _isContractLoading = true);
    try {
      await ref.read(propertyRepositoryProvider).updateMainContract(
        contract.id,
        fileBytes,
        result.files.single.extension ?? 'pdf',
      );
      ref.invalidate(activeContractProvider(widget.property.id));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isContractLoading = false);
    }
  }

  Future<void> _deleteDocument(Contract contract, ContractDocument doc) async {
    final loc = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.deleteDocument),
        content: Text(loc.deleteDocumentConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(loc.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: StanomerColors.alertPrimary),
            child: Text(loc.delete),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isContractLoading = true);
    try {
      await ref.read(propertyRepositoryProvider).deleteContractDocument(contract.id, doc);
      ref.invalidate(activeContractProvider(widget.property.id));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isContractLoading = false);
    }
  }

  Future<void> _handleRequestTermination(Contract contract) async {
    final loc = AppLocalizations.of(context)!;
    final now = DateTime.now();
    
    // Pick date
    final effectiveLastDate = contract.endDate ?? now.add(const Duration(days: 365));
    final effectiveInitialDate = now.add(const Duration(days: 15));
    
    // Ensure initialDate is within firstDate and lastDate
    final safeInitialDate = effectiveInitialDate.isAfter(effectiveLastDate) 
        ? effectiveLastDate 
        : (effectiveInitialDate.isBefore(now) ? now : effectiveInitialDate);

    final picked = await showDatePicker(
      context: context,
      initialDate: safeInitialDate,
      firstDate: now,
      lastDate: effectiveLastDate,
      helpText: loc.terminationDate,
    );

    if (picked == null) return;

    // Confirm
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.confirmTerminationTitle),
        content: Text(loc.confirmTerminationMessage),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(loc.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: StanomerColors.alertPrimary),
            child: Text(loc.confirm),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isContractLoading = true);
    try {
      await ref.read(propertyRepositoryProvider).requestContractTermination(contract.id, picked);
      ref.invalidate(activeContractProvider(widget.property.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.terminationRequestSent)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.errorWithDetails(e.toString())), backgroundColor: StanomerColors.alertPrimary));
      }
    } finally {
      if (mounted) setState(() => _isContractLoading = false);
    }
  }

  Widget _buildNegotiationBanner(AppLocalizations loc, Contract contract, String? currentUserId, Color roleColor) {
    if (contract.status != ContractStatus.revisionRequested) return const SizedBox.shrink();
    
    final proposal = contract.proposedChanges;
    if (proposal == null) return const SizedBox.shrink();

    final isProposer = contract.proposedBy == currentUserId;


    // Helper to format currency
    String format(num? val, String curr) => CurrencyUtils.formatAmount(val?.toDouble() ?? 0, curr);

    List<Widget> changeItems = [];
    if (proposal.containsKey('monthly_rent')) {
      changeItems.add(_buildChangeRow(loc.monthlyRent, format(contract.monthlyRent, contract.currency), format(proposal['monthly_rent'], proposal['currency'] ?? contract.currency)));
    }
    if (proposal.containsKey('deposit_amount')) {
      changeItems.add(_buildChangeRow(loc.depositAmount, format(contract.depositAmount, contract.depositCurrency), format(proposal['deposit_amount'], proposal['deposit_currency'] ?? contract.depositCurrency)));
    }
    if (proposal.containsKey('due_day')) {
      changeItems.add(_buildChangeRow(loc.dueDay, contract.dueDay.toString(), proposal['due_day'].toString()));
    }
    if (proposal.containsKey('start_date') || proposal.containsKey('end_date')) {
      final oldRange = '${DateFormat('dd/MM/yy').format(contract.startDate!)} - ${DateFormat('dd/MM/yy').format(contract.endDate!)}';
      final newStart = proposal.containsKey('start_date') ? DateTime.parse(proposal['start_date']) : contract.startDate!;
      final newEnd = proposal.containsKey('end_date') ? DateTime.parse(proposal['end_date']) : contract.endDate!;
      final newRange = '${DateFormat('dd/MM/yy').format(newStart)} - ${DateFormat('dd/MM/yy').format(newEnd)}';
      changeItems.add(_buildChangeRow(loc.term, oldRange, newRange));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.fileEdit, size: 20, color: Colors.amber),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  loc.contractChangeProposal,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...changeItems,
          if (!isProposer) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isContractLoading ? null : () async {
                      setState(() => _isContractLoading = true);
                      try {
                        await ref.read(propertyRepositoryProvider).declineProposedChanges(contract.id);
                        ref.invalidate(activeContractProvider(widget.property.id));
                      } finally {
                        if (mounted) setState(() => _isContractLoading = false);
                      }
                    },
                    style: TextButton.styleFrom(foregroundColor: StanomerColors.alertPrimary),
                    child: Text(loc.decline),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isContractLoading ? null : () async {
                      setState(() => _isContractLoading = true);
                      try {
                        await ref.read(propertyRepositoryProvider).acceptProposedChanges(contract.id);
                        ref.invalidate(activeContractProvider(widget.property.id));
                      } finally {
                        if (mounted) setState(() => _isContractLoading = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: StanomerColors.successPrimary, foregroundColor: Colors.white),
                    child: Text(loc.accept),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 12),
            Text(
              loc.waitingForOtherParty,
              style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: StanomerColors.textTertiary),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _isContractLoading ? null : () async {
                setState(() => _isContractLoading = true);
                try {
                  await ref.read(propertyRepositoryProvider).declineProposedChanges(contract.id);
                  ref.invalidate(activeContractProvider(widget.property.id));
                } finally {
                  if (mounted) setState(() => _isContractLoading = false);
                }
              },
              child: Text(loc.cancelProposal, style: const TextStyle(color: StanomerColors.alertPrimary)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChangeRow(String label, String oldVal, String newVal) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: StanomerColors.textTertiary)),
          Text(oldVal, style: const TextStyle(fontSize: 12, decoration: TextDecoration.lineThrough, color: StanomerColors.textTertiary)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Icon(LucideIcons.arrowRight, size: 12, color: StanomerColors.textTertiary),
          ),
          Text(newVal, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: StanomerColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildTerminationBanner(AppLocalizations loc, Contract contract, String? currentUserId, Color roleColor) {
    if (contract.status != ContractStatus.terminationRequested) return const SizedBox.shrink();
    
    final proposal = contract.proposedChanges;
    if (proposal == null) return const SizedBox.shrink();

    final isTermination = proposal['is_termination'] == true;
    if (!isTermination) return const SizedBox.shrink();

    final dateStr = proposal['new_end_date'] as String?;
    final date = dateStr != null ? DateTime.parse(dateStr) : null;
    final formattedDate = date != null ? DateFormat('dd/MM/yyyy').format(date) : '-';
    
    final isProposer = contract.proposedBy == currentUserId;


    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: StanomerColors.alertPrimary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: StanomerColors.alertPrimary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.calendarOff, size: 20, color: StanomerColors.alertPrimary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loc.terminationRequested, style: const TextStyle(fontWeight: FontWeight.bold, color: StanomerColors.alertPrimary)),
                    const SizedBox(height: 2),
                    Text(loc.contractWillEndOn(formattedDate), style: const TextStyle(fontSize: 12, color: StanomerColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          if (!isProposer) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isContractLoading ? null : () async {
                      setState(() => _isContractLoading = true);
                      try {
                        await ref.read(propertyRepositoryProvider).declineProposedChanges(contract.id);
                        ref.invalidate(activeContractProvider(widget.property.id));
                      } finally {
                        if (mounted) setState(() => _isContractLoading = false);
                      }
                    },
                    style: TextButton.styleFrom(foregroundColor: StanomerColors.alertPrimary),
                    child: Text(loc.declineTermination),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isContractLoading ? null : () async {
                      setState(() => _isContractLoading = true);
                      try {
                        await ref.read(propertyRepositoryProvider).acceptProposedChanges(contract.id);
                        ref.invalidate(activeContractProvider(widget.property.id));
                      } finally {
                        if (mounted) setState(() => _isContractLoading = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: StanomerColors.successPrimary, foregroundColor: Colors.white),
                    child: Text(loc.approveTermination),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 12),
            Text(
              loc.awaitingApproval,
              style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: StanomerColors.textTertiary),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _isContractLoading ? null : () async {
                setState(() => _isContractLoading = true);
                try {
                  await ref.read(propertyRepositoryProvider).declineProposedChanges(contract.id);
                  ref.invalidate(activeContractProvider(widget.property.id));
                } finally {
                  if (mounted) setState(() => _isContractLoading = false);
                }
              },
              child: Text(loc.cancel, style: const TextStyle(color: StanomerColors.alertPrimary)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContractExpensesSection(AppLocalizations loc, Color roleColor) {
    if (_contractExpenses.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(loc.expensesHeader,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: StanomerColors.textTertiary, letterSpacing: 1.1)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(color: StanomerColors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: StanomerColors.borderDefault)),
          child: Column(
            children: _contractExpenses.asMap().entries.map((entry) {
              final index = entry.key;
              final expense = entry.value;
              final isIncluded = expense.receiver == PaymentReceiver.included;
              return Column(
                children: [
                  ListTile(
                    dense: true,
                    title: Text(expense.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: isIncluded 
                      ? Text(loc.included, style: const TextStyle(color: StanomerColors.successPrimary, fontSize: 11))
                      : null,
                    trailing: Switch.adaptive(
                      value: isIncluded,
                      activeColor: roleColor,
                      onChanged: ((val) => setState(() {
                        _contractExpenses[index] = expense.copyWith(receiver: val ? PaymentReceiver.included : PaymentReceiver.unselected);
                      })),
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
                                _contractExpenses[index] = expense.copyWith(receiver: newReceiver);
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  if (index < _contractExpenses.length - 1)
                    Divider(height: 1, color: StanomerColors.borderDefault.withValues(alpha: 0.5)),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPropertyPanel(AppLocalizations loc, Color roleColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Info banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: roleColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: roleColor.withValues(alpha: 0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Icon(LucideIcons.info, size: 16, color: roleColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  loc.defaultLeaseTermsSubtitle,
                  style: TextStyle(fontSize: 12, color: roleColor),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Ev kimlik bilgileri
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(labelText: loc.propertyName),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _addressController,
          maxLines: 2,
          decoration: InputDecoration(labelText: loc.address),
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        // Kira varsayılanları
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _rentController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: loc.monthlyRent),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: DropdownButtonFormField<String>(
                value: _selectedCurrency,
                items: const [
                  DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                  DropdownMenuItem(value: 'RSD', child: Text('RSD')),
                ],
                onChanged: (val) {
                  setState(() {
                    _selectedCurrency = val!;
                    _depositCurrency = val; // Default deposit matches rent
                  });
                },
                decoration: InputDecoration(labelText: loc.currency),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _depositController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: loc.depositAmount),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: DropdownButtonFormField<String>(
                value: _depositCurrency,
                items: const [
                  DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                  DropdownMenuItem(value: 'RSD', child: Text('RSD')),
                ],
                onChanged: (val) => setState(() => _depositCurrency = val!),
                decoration: InputDecoration(labelText: loc.currency),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _dueDayController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: loc.dueDayOfMonth,
            prefixIcon: const Icon(LucideIcons.calendarDays, size: 20),
          ),
        ),
        const SizedBox(height: 16),
        const SizedBox(height: 24),
        _buildExpensesSection(loc, roleColor),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isLoading ? null : _update,
          style: ElevatedButton.styleFrom(backgroundColor: roleColor, foregroundColor: Colors.white),
          child: _isLoading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(loc.saveChanges),
        ),
        const SizedBox(height: 48),
      ],
    );
  }


  Widget _buildExpensesSection(AppLocalizations loc, Color roleColor) {
    String getTooltip(String name) {
      return ExpenseUtils.getLocalizedTooltip(name, loc);
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
                      ? Text(loc.included, style: const TextStyle(color: StanomerColors.successPrimary, fontSize: 11))
                      : null,
                    trailing: Switch.adaptive(
                      value: isIncluded,
                      activeColor: roleColor,
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
}
