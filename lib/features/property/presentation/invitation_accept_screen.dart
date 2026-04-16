import 'package:stanomer/features/property/domain/contract.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/colors.dart';
import '../data/property_repository.dart';
import '../domain/property.dart';
import 'package:stanomer/core/utils/currency_utils.dart';
import 'package:stanomer/core/utils/expense_utils.dart';

class InvitationAcceptScreen extends ConsumerStatefulWidget {
  final String token;

  const InvitationAcceptScreen({super.key, required this.token});

  @override
  ConsumerState<InvitationAcceptScreen> createState() => _InvitationAcceptScreenState();
}

class _InvitationAcceptScreenState extends ConsumerState<InvitationAcceptScreen> {
  bool _isLoading = true;
  bool _isProcessing = false;
  Contract? _contract;
  Property? _property;
  String? _error;
  bool _termsAccepted = false;
  String? _inviteType; // 'contract' or 'invitation'

  @override
  void initState() {
    super.initState();
    _fetchInvite();
  }

  Future<void> _fetchInvite() async {
    try {
      final data = await ref.read(propertyRepositoryProvider).getInviteByToken(widget.token);
      
      if (mounted) {
        setState(() {
          _inviteType = data['type'];
          
          if (_inviteType == 'contract') {
            _contract = Contract.fromJson(data);
          } else if (_inviteType == 'invitation') {
            // Use the active contract terms for display if available
            if (data['active_contract'] != null) {
              _contract = Contract.fromJson(data['active_contract']);
            }
          }

          if (data['properties'] != null) {
            _property = Property.fromJson(data['properties']);
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _accept() async {
    final loc = AppLocalizations.of(context)!;
    if (!_termsAccepted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.acceptTermsWarning)),
        );
      return;
    }

    setState(() => _isProcessing = true);
    try {
      if (_inviteType == 'contract') {
        await ref.read(propertyRepositoryProvider).acceptContract(widget.token);
      } else {
        await ref.read(propertyRepositoryProvider).acceptInvite(widget.token);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.invitationAcceptedSuccess), backgroundColor: StanomerColors.successPrimary),
        );
        ref.invalidate(propertiesStreamProvider);
        ref.invalidate(pendingInvitesForUserProvider);
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: StanomerColors.alertPrimary),
        );
      }
    }
  }

  Future<void> _proposeRevision() async {
    final loc = AppLocalizations.of(context)!;
    final feedbackController = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.proposeRevision),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(loc.revisionTermsQuestion),
            const SizedBox(height: 16),
            TextField(
              controller: feedbackController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: loc.enterNotesHint,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(loc.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, feedbackController.text),
            child: Text(loc.submit),
          ),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty && mounted) {
      setState(() => _isProcessing = true);
      try {
        await ref.read(propertyRepositoryProvider).proposeRevision(widget.token, result.trim());
        if (mounted) {
          // Optimistically update local state so the feedback shows immediately
          setState(() {
            _contract = _contract?.copyWith(
              status: ContractStatus.negotiating,
              tenantFeedback: result.trim(),
            );
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.revisionSent)),
          );
          // Also refresh from server in background
          await _fetchInvite();
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: StanomerColors.alertPrimary),
          );
        }
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _decline() async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.confirmDeclineInviteTitle),
        content: Text(loc.confirmDeclineInviteMessage),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(loc.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: StanomerColors.alertPrimary),
            child: Text(loc.declineInvitation),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isProcessing = true);
      try {
        await ref.read(propertyRepositoryProvider).declineInvite(widget.token);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.invitationDeclinedSuccess)),
          );
          ref.invalidate(pendingInvitesForUserProvider);
          context.go('/dashboard');
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: StanomerColors.alertPrimary),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null || _contract == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.alertTriangle, size: 48, color: StanomerColors.alertPrimary),
                const SizedBox(height: 16),
                Text(loc.inviteNotFound, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                if (_error != null) Text(_error!, style: const TextStyle(fontSize: 12, color: StanomerColors.textTertiary)),
                const SizedBox(height: 24),
                ElevatedButton(onPressed: () => context.go('/dashboard'), child: Text(loc.login)),
              ],
            ),
          ),
        ),
      );
    }

    final isNegotiating = _contract!.status == ContractStatus.negotiating;


    return Scaffold(
      appBar: AppBar(title: Text(loc.invitationDetails)),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width < 360 ? 12.0 : 20.0,
          vertical: 24.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(LucideIcons.fileSignature, size: 64, color: StanomerColors.brandPrimary),
            const SizedBox(height: 24),
            Text(
              _inviteType == 'invitation'
                ? loc.joinPropertyInvitation
                : (isNegotiating 
                  ? loc.feedbackSent
                  : loc.rentalProposal),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _inviteType == 'invitation'
                ? loc.invitedToJoinProperty(_property?.name ?? "")
                : (isNegotiating 
                  ? loc.waitingForLandlord
                  : loc.reviewContractTerms),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: StanomerColors.textTertiary),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            _buildAgreementSummaryCard(loc),
            
            if (!isNegotiating) ...[
              const SizedBox(height: 24),
              _buildTermsCheckbox(loc),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: (_isProcessing || !_termsAccepted) ? null : _accept,
                child: _isProcessing 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(loc.acceptInvitation),
              ),
              if (_inviteType == 'contract') ...[
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _isProcessing ? null : _proposeRevision,
                  child: Text(loc.proposeRevision),
                ),
              ],
              const SizedBox(height: 12),
              TextButton(
                onPressed: _isProcessing ? null : _decline,
                style: TextButton.styleFrom(foregroundColor: StanomerColors.textTertiary),
                child: Text(loc.declineInvitation),
              ),
            ] else ...[
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: StanomerColors.brandPrimarySurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: StanomerColors.borderDefault),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.yourNote,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _contract!.tenantFeedback ?? '',
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () => context.go('/dashboard'),
                child: Text(loc.backToDashboard),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAgreementSummaryCard(AppLocalizations loc) {

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: StanomerColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: StanomerColors.borderDefault),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryRow(
            icon: LucideIcons.banknote,
            label: loc.monthlyRent,
            value: CurrencyUtils.formatAmount(_contract!.monthlyRent, _contract!.currency),
          ),
          if (_contract!.depositAmount != null)
            _SummaryRow(
              icon: LucideIcons.shieldCheck,
              label: loc.depositAmount,
              value: CurrencyUtils.formatAmount(_contract!.depositAmount!, _contract!.depositCurrency),
            ),
          _SummaryRow(
            icon: LucideIcons.calendarClock,
            label: loc.dueDay,
            value: '${_contract!.dueDay}. ${loc.day}',
          ),
          const Divider(height: 32),
          Text(
            loc.expenseDistribution,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 12),
          ..._contract!.expensesConfig.map((exp) {
            String receiverText;
            Color receiverColor;
            
            switch (exp.receiver) {
              case PaymentReceiver.included:
                receiverText = loc.includedInRent;
                receiverColor = StanomerColors.successPrimary;
                break;
              case PaymentReceiver.utility:
                receiverText = loc.tenantPaysUtility;
                receiverColor = StanomerColors.alertPrimary;
                break;
              case PaymentReceiver.owner:
                receiverText = loc.tenantPaysLandlord;
                receiverColor = StanomerColors.brandPrimary;
                break;
              case PaymentReceiver.unselected:
                receiverText = loc.notSelected;
                receiverColor = StanomerColors.alertPrimary;
                break;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      ExpenseUtils.getLocalizedExpenseName(exp.name, loc),
                      style: const TextStyle(fontSize: 13),
                      softWrap: true,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    receiverText,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: receiverColor,
                    ),
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTermsCheckbox(AppLocalizations loc) {

    return Row(
      children: [
        Checkbox(
          value: _termsAccepted,
          onChanged: (val) => setState(() => _termsAccepted = val ?? false),
          activeColor: StanomerColors.brandPrimary,
        ),
        Expanded(
          child: Text(
            loc.acceptTermsAndDistribution,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _SummaryRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(icon, size: 18, color: StanomerColors.brandPrimary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(color: StanomerColors.textSecondary, fontSize: 13),
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
        ],
      ),
    );
  }
}
