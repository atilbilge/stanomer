import re

with open('lib/features/property/presentation/property_detail_screen.dart', 'r') as f:
    content = f.read()

card_regex = r"""  @override
  Widget build\(BuildContext context\) \{
    final isTr = widget.isTr;
    final proposalAsync = ref.watch\(contractProposalProvider\(widget.contract.id\)\);

    return Container\(
      decoration: BoxDecoration\(
        color: Colors.orange.withOpacity\(0.07\),
        borderRadius: BorderRadius.circular\(16\),
        border: Border.all\(color: Colors.orange.withOpacity\(0.3\), width: 1.5\),
      \),
      padding: const EdgeInsets.all\(16\),
      child: Column\(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: \[
          Row\(
            children: \[
              const Icon\(LucideIcons.alertTriangle, size: 18, color: Colors.orange\),
              const SizedBox\(width: 8\),
              Expanded\(
                child: Text\(
                  isTr \? 'Kontrat Değişikliği Teklifi' : 'Contract Change Proposal',
                  style: const TextStyle\(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.orange\),
                \),
              \),
            \],
          \),
          const SizedBox\(height: 12\),
          if \(widget.isLandlord\)
            Text\(
              isTr
                  \? 'Değişiklik teklifiniz kiracının onayını bekliyor.'
                  : 'Your change proposal is awaiting tenant approval.',
              style: const TextStyle\(fontSize: 13, color: StanomerColors.textSecondary\),
            \),
          if \(widget.isTenant\)
            proposalAsync.when\(
              data: \(proposal\) \{
                if \(proposal == null\) return const SizedBox.shrink\(\);
                return Column\(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: \[
                    Text\(
                      isTr \? 'Ev sahibi aşağıdaki değişiklikleri teklif ediyor:' : 'The landlord proposes the following changes:',
                      style: const TextStyle\(fontSize: 13, color: StanomerColors.textSecondary\),
                    \),
                    const SizedBox\(height: 12\),
                    _buildProposalRow\(isTr \? 'Aylık Kira' : 'Monthly Rent',
                      '\$\{widget.contract.monthlyRent.toStringAsFixed\(0\)\} \$\{widget.contract.currency\}',
                      proposal\['monthly_rent'\] \!= null \? '\$\{\(proposal\['monthly_rent'\] as num\).toStringAsFixed\(0\)\} \$\{proposal\['currency'\] \?\? widget.contract.currency\}' : null\),
                    _buildProposalRow\(isTr \? 'Depozito' : 'Deposit',
                      widget.contract.depositAmount \!= null \? '\$\{widget.contract.depositAmount\!.toStringAsFixed\(0\)\} \$\{widget.contract.currency\}' : '-',
                      proposal\['deposit_amount'\] \!= null \? '\$\{\(proposal\['deposit_amount'\] as num\).toStringAsFixed\(0\)\} \$\{proposal\['currency'\] \?\? widget.contract.currency\}' : null\),
                    _buildProposalRow\(isTr \? 'Ödeme Günü' : 'Due Day',
                      '\$\{widget.contract.dueDay\}',
                      proposal\['due_day'\] \!= null \? '\$\{proposal\['due_day'\]\}' : null\),
                    _buildProposalRow\(isTr \? 'Vergi' : 'Tax',
                      widget.contract.taxType == TaxType.included \? \(isTr \? 'Dahil' : 'Included'\) : '\+%15',
                      proposal\['tax_type'\] \!= null \? \(proposal\['tax_type'\] == 'included' \? \(isTr \? 'Dahil' : 'Included'\) : '\+%15'\) : null\),
                    const SizedBox\(height: 16\),
                    Row\(
                      children: \[
                        Expanded\(
                          child: OutlinedButton.icon\(
                            onPressed: _loading \? null : _decline,
                            icon: const Icon\(LucideIcons.x, size: 16\),
                            label: Text\(isTr \? 'Reddet' : 'Decline'\),
                            style: OutlinedButton.styleFrom\(
                              foregroundColor: StanomerColors.alertPrimary,
                              side: const BorderSide\(color: StanomerColors.alertPrimary\),
                            \),
                          \),
                        \),
                        const SizedBox\(width: 12\),
                        Expanded\(
                          child: FilledButton.icon\(
                            onPressed: _loading \? null : _accept,
                            icon: const Icon\(LucideIcons.check, size: 16\),
                            label: Text\(isTr \? 'Kabul Et' : 'Accept'\),
                            style: FilledButton.styleFrom\(backgroundColor: StanomerColors.successPrimary\),
                          \),
                        \),
                      \],
                    \),
                  \],
                \);
              \},
              loading: \(\) => const Center\(child: CircularProgressIndicator\(\)\),
              error: \(e, _\) => Text\('Error: \$e'\),
            \),
        \],
      \),
    \);
  \}"""

card_replace = """  @override
  Widget build(BuildContext context) {
    final isTr = widget.isTr;
    final user = ref.watch(currentUserProvider);
    final proposalAsync = ref.watch(contractProposalProvider(widget.contract.id));

    return Container(
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.3), width: 1.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.alertTriangle, size: 18, color: Colors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isTr ? 'Kontrat Değişikliği Teklifi' : 'Contract Change Proposal',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.orange),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          proposalAsync.when(
            data: (proposalData) {
              if (proposalData == null) return const SizedBox.shrink();
              final proposal = proposalData['changes'] as Map<String, dynamic>;
              final proposedBy = proposalData['proposed_by'] as String?;
              final isMyProposal = proposedBy == user?.id;

              if (isMyProposal) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isTr
                          ? 'Değişiklik teklifiniz karşı tarafın onayını bekliyor.'
                          : 'Your change proposal is awaiting the other party\\'s approval.',
                      style: const TextStyle(fontSize: 13, color: StanomerColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _loading ? null : _decline, // Decline effectively cancels it
                      icon: const Icon(LucideIcons.x, size: 16),
                      label: Text(isTr ? 'Teklifi İptal Et' : 'Cancel Proposal'),
                      style: TextButton.styleFrom(foregroundColor: StanomerColors.alertPrimary),
                    ),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isTr ? 'Karşı taraf aşağıdaki değişiklikleri teklif ediyor:' : 'The other party proposes the following changes:',
                    style: const TextStyle(fontSize: 13, color: StanomerColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  _buildProposalRow(isTr ? 'Aylık Kira' : 'Monthly Rent',
                    '${widget.contract.monthlyRent.toStringAsFixed(0)} ${widget.contract.currency}',
                    proposal['monthly_rent'] != null ? '${(proposal['monthly_rent'] as num).toStringAsFixed(0)} ${proposal['currency'] ?? widget.contract.currency}' : null),
                  _buildProposalRow(isTr ? 'Depozito' : 'Deposit',
                    widget.contract.depositAmount != null ? '${widget.contract.depositAmount!.toStringAsFixed(0)} ${widget.contract.currency}' : '-',
                    proposal['deposit_amount'] != null ? '${(proposal['deposit_amount'] as num).toStringAsFixed(0)} ${proposal['currency'] ?? widget.contract.currency}' : null),
                  _buildProposalRow(isTr ? 'Ödeme Günü' : 'Due Day',
                    '${widget.contract.dueDay}',
                    proposal['due_day'] != null ? '${proposal['due_day']}' : null),
                  _buildProposalRow(isTr ? 'Vergi' : 'Tax',
                    widget.contract.taxType == TaxType.included ? (isTr ? 'Dahil' : 'Included') : '+%15',
                    proposal['tax_type'] != null ? (proposal['tax_type'] == 'included' ? (isTr ? 'Dahil' : 'Included') : '+%15') : null),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _loading ? null : _decline,
                          icon: const Icon(LucideIcons.x, size: 16),
                          label: Text(isTr ? 'Reddet' : 'Decline'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: StanomerColors.alertPrimary,
                            side: const BorderSide(color: StanomerColors.alertPrimary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _loading ? null : _accept,
                          icon: const Icon(LucideIcons.check, size: 16),
                          label: Text(isTr ? 'Kabul Et' : 'Accept'),
                          style: FilledButton.styleFrom(backgroundColor: StanomerColors.successPrimary),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }"""

content = re.sub(card_regex, card_replace, content)

with open('lib/features/property/presentation/property_detail_screen.dart', 'w') as f:
    f.write(content)

