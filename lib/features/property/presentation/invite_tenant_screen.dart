import 'dart:typed_data';
import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stanomer/features/property/presentation/widgets/payment_responsibility_selector.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/expense_utils.dart';
import '../../auth/data/auth_providers.dart';
import '../../auth/data/auth_repository.dart';
import '../data/property_repository.dart';
import '../domain/property.dart';
import '../domain/contract.dart';

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
  final _nameController = TextEditingController();
  final _rentController = TextEditingController();
  final _depositController = TextEditingController();
  final _dueDayController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  String? _generatedLink;
  bool _isInitialized = false;
  bool _isLeaseLocked = false;
  
  DateTime? _startDate;
  DateTime? _endDate;
  String _depositCurrency = 'EUR';
  List<ExpenseItem> _expenses = [];

  // File Upload State
  String? _contractFileName;
  Uint8List? _contractFileBytes;
  String? _contractFilePath;
  String? _existingContractUrl;

  @override
  void initState() {
    super.initState();
    final contract = widget.existingContract ?? widget.leaseTemplate;
    
    if (widget.existingContract == null && widget.leaseTemplate != null) {
      _isLeaseLocked = true;
    }

    if (contract != null) {
      _emailController.text = widget.existingContract != null ? contract.inviteeEmail : '';
      _nameController.text = contract.inviterName ?? '';
      
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
    _nameController.dispose();
    _rentController.dispose();
    _depositController.dispose();
    _dueDayController.dispose();
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

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png', 'jpeg'],
      withData: true,
    );

    if (result != null && result.files.single.name.isNotEmpty) {
      List<int>? fileBytes = result.files.single.bytes?.toList();
      if (fileBytes == null && result.files.single.path != null) {
        fileBytes = await io.File(result.files.single.path!).readAsBytes();
      }

      setState(() {
        _contractFileName = result.files.single.name;
        _contractFileBytes = fileBytes != null ? Uint8List.fromList(fileBytes) : null;
        try {
          _contractFilePath = result.files.single.path;
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
    if (_emailController.text.trim().toLowerCase() == currentUserEmail?.toLowerCase()) {
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
        contractUrl = await repo.uploadContract(
          _contractFileName!,
          filePath: _contractFilePath,
          bytes: _contractFileBytes,
        );
      }

      final finalRent = double.parse(_rentController.text);
      final newName = _nameController.text.trim();

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
      } else if (_isLeaseLocked) {
        // Subsequent tenant joining via Invitation table
        final token = await repo.createInvitation(
          propertyId: widget.property.id,
          inviteeEmail: _emailController.text.trim(),
          inviterName: newName,
        );
        
        setState(() {
          _generatedLink = 'stanomer://invite?token=$token';
          _isLoading = false;
        });
      } else {
        // First tenant / Master Contract
        final contract = await repo.createContract(
          propertyId: widget.property.id,
          inviteeEmail: _emailController.text.trim(),
          monthlyRent: finalRent,
          depositAmount: _depositController.text.isNotEmpty ? double.parse(_depositController.text) : null,
          currency: widget.property.currency,
          depositCurrency: _depositCurrency,
          dueDay: int.parse(_dueDayController.text),
          startDate: _startDate!,
          endDate: _endDate!,
          taxType: TaxType.included,
          expensesConfig: _expenses,
          inviterName: newName,
          contractUrl: contractUrl,
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
    final profileAsync = ref.watch(profileFutureProvider);

    if (!_isInitialized) {
      profileAsync.whenData((profile) {
        if (profile != null && profile['full_name'] != null && _nameController.text.isEmpty) {
          _nameController.text = profile['full_name'];
          _isInitialized = true;
        }
      });
    }

    final user = ref.watch(currentUserProvider);
    final role = user?.userMetadata?['role'] as String?;
    final roleColor = StanomerColors.getRoleColor(role);

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
                    _buildSectionHeader(loc.partiesHeader, LucideIcons.users, roleColor),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: loc.yourName,
                        prefixIcon: const Icon(LucideIcons.user, size: 20),
                      ),
                      validator: (val) => (val == null || val.isEmpty) ? loc.fieldRequired : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      enabled: widget.existingContract == null,
                      decoration: InputDecoration(
                        labelText: loc.tenantEmail,
                        prefixIcon: const Icon(LucideIcons.mail, size: 20),
                        hintText: "kiraci@email.com",
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return loc.fieldRequired;
                        final currentUserEmail = ref.read(currentUserProvider)?.email;
                        if (val.trim().toLowerCase() == currentUserEmail?.toLowerCase()) {
                          return loc.cannotInviteSelf;
                        }
                        return null;
                      },
                    ),

                    if (_isLeaseLocked) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: StanomerColors.brandPrimarySurface.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: StanomerColors.brandPrimary.withOpacity(0.2)),
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
                    _buildExpensesSection(loc, roleColor),

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
          border: Border.all(color: date == null ? Colors.red.withOpacity(0.5) : StanomerColors.borderDefault),
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

  Widget _buildExpensesSection(AppLocalizations loc, Color roleColor) {
    return Container(
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
                    ],
                  ),
                ),
              if (index < _expenses.length - 1)
                Divider(height: 1, color: StanomerColors.borderDefault.withValues(alpha: 0.5)),
            ],
          );
        }).toList().cast<Widget>(),
      ),
    );
  }

  Widget _buildGeneratedLinkSection(BuildContext context, AppLocalizations loc, Color roleColor) {
    return Column(
      children: [
        Icon(LucideIcons.checkCircle2, color: roleColor, size: 64),
        const SizedBox(height: 24),
        Text(loc.inviteCreatedSuccess, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: StanomerColors.bgPage, borderRadius: BorderRadius.circular(12), border: Border.all(color: StanomerColors.borderDefault)),
          child: Row(
            children: [
              Expanded(child: Text(_generatedLink!, style: const TextStyle(fontSize: 13, color: StanomerColors.textSecondary))),
              IconButton(
                icon: const Icon(LucideIcons.copy, size: 20),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _generatedLink!));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.copyLink)));
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 48),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: Text(loc.done),
        ),
      ],
    );
  }
}
