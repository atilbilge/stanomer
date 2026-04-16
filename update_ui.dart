import 'dart:io';

void main() {
  final file = File('lib/features/property/presentation/property_detail_screen.dart');
  String content = file.readAsStringSync();

  // 1. Replace Kira özet bannerı
  final bannerRegex = RegExp(r'// ── Kira özet bannerı ──────────────────────────────────\n\s*Container\([\s\S]*?if \(activeContract \!= null\)\s*Container\([\s\S]*?\),\s*\],\s*\)\s*\],\s*\),\s*\),\s*\],\s*\),\s*\),');
  content = content.replaceFirst(bannerRegex, '''// ── Kira özet bannerı ──────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: StanomerColors.brandPrimary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.monthlyRent.toUpperCase(),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.8), letterSpacing: 1),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '\${currentRent.toStringAsFixed(0)} \$currentCurrency',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      Divider(color: Colors.white.withOpacity(0.2), height: 1),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isTr ? 'KİRACI' : 'TENANT',
                                style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.8), letterSpacing: 0.5),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                resolvedTenantName.isNotEmpty && resolvedTenantName != 'Tenant' ? resolvedTenantName : (isTr ? 'Kiracı Yok' : 'No Tenant'),
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                              ),
                            ],
                          ),
                          if (activeContract != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: activeContract.status == ContractStatus.revisionRequested ? Colors.orange.shade100 : Colors.green.shade50,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                activeContract.status == ContractStatus.revisionRequested
                                    ? (isTr ? 'Onay Bekliyor' : 'Pending Approval')
                                    : (isTr ? 'Aktif Kontrat' : 'Active lease'),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: activeContract.status == ContractStatus.revisionRequested ? Colors.orange.shade800 : Colors.green.shade800,
                                ),
                              ),
                            ),
                        ],
                      )
                    ],
                  ),
                ),
                
                // ── Sıradaki Ödeme Kartı ───────────────────────────────
                if (activeContract != null) ...[
                  const SizedBox(height: 16),
                  Builder(
                    builder: (context) {
                      final now = DateTime.now();
                      DateTime nextDue = DateTime(now.year, now.month, activeContract.dueDay);
                      if (nextDue.isBefore(DateTime(now.year, now.month, now.day))) {
                        nextDue = DateTime(now.year, now.month + 1, activeContract.dueDay);
                      }
                      final daysRemaining = nextDue.difference(DateTime(now.year, now.month, now.day)).inDays;
                      
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: StanomerColors.borderDefault),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: StanomerColors.brandPrimary.withOpacity(0.08),
                              radius: 20,
                              child: const Icon(LucideIcons.calendar, color: StanomerColors.brandPrimary, size: 20),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isTr ? 'Sıradaki ödeme' : 'Next payment due',
                                    style: const TextStyle(fontSize: 12, color: StanomerColors.textTertiary, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '\${DateFormat('d MMMM yyyy', loc.localeName).format(nextDue)} · \$daysRemaining \${isTr ? 'gün kaldı' : 'days left'}',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: StanomerColors.textPrimary),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '\${currentRent.toStringAsFixed(0)} \${currentCurrency == 'EUR' ? '€' : currentCurrency}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: StanomerColors.brandPrimary),
                            ),
                          ],
                        ),
                      );
                    }
                  ),
                ],''');

  // 2. Kontrat Bilgileri Kartı
  final contractInfoRegex = RegExp(r'// ── Kontrat Bilgileri Kartı ─────────────────────────────\n\s*if \(activeContract \!= null\) \.\.\.\[[\s\S]*?\]\s*,\s*\],\s*\),\s*\],');
  content = content.replaceFirst(contractInfoRegex, '''// ── Kontrat Bilgileri Kartı ─────────────────────────────
                if (activeContract != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: StanomerColors.borderDefault),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                          child: Text(
                            isTr ? 'Kontrat bilgileri' : 'Contract info',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                        Divider(height: 1, color: StanomerColors.borderDefault.withOpacity(0.5)),
                        
                        if (effectiveIsTenant)
                          _ModernContractRow(icon: LucideIcons.user, label: isTr ? 'Ev Sahibi' : 'Landlord', value: resolvedLandlordName),
                        if (effectiveIsLandlord)
                          _ModernContractRow(icon: LucideIcons.user, label: isTr ? 'Kiracı' : 'Tenant', value: resolvedTenantName),
                        Divider(height: 1, color: StanomerColors.borderDefault.withOpacity(0.5)),
                        
                        Builder(
                          builder: (context) {
                            String termText = '-';
                            String remainingText = '';
                            if (activeContract.startDate != null && activeContract.endDate != null) {
                               termText = '\${DateFormat('dd MMM yyyy', loc.localeName).format(activeContract.startDate!)} – \${DateFormat('dd MMM yyyy', loc.localeName).format(activeContract.endDate!)}';
                               final days = activeContract.endDate!.difference(DateTime.now()).inDays;
                               remainingText = days > 0 ? '\$days \${isTr ? 'gün kaldı' : 'days remaining'}' : (isTr ? 'Süresi doldu' : 'Expired');
                            }
                            return _ModernContractRow(
                              icon: LucideIcons.calendarDays, 
                              label: isTr ? 'Kontrat süresi' : 'Lease term', 
                              value: termText,
                              subtitle: remainingText.isNotEmpty ? remainingText : null,
                            );
                          }
                        ),
                        Divider(height: 1, color: StanomerColors.borderDefault.withOpacity(0.5)),
                        
                        _ModernContractRow(
                          icon: LucideIcons.clock, 
                          label: isTr ? 'Ödeme günü' : 'Payment due', 
                          value: isTr ? 'Her ayın \${activeContract.dueDay}. günü' : 'Every month on the \${activeContract.dueDay}\${_getOrdinal(activeContract.dueDay)}'
                        ),
                        Divider(height: 1, color: StanomerColors.borderDefault.withOpacity(0.5)),
                        
                        InkWell(
                          onTap: () => _showContractDetailsSheet(context, activeContract, resolvedLandlordName, resolvedTenantName, effectiveIsTenant, effectiveIsLandlord),
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  isTr ? 'Kontrat detaylarını gör' : 'View contract details',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: StanomerColors.brandPrimary),
                                ),
                                const Icon(LucideIcons.chevronRight, size: 16, color: StanomerColors.textTertiary),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],''');

  // 3. Bekleyen davetler
  final pendingRegex = RegExp(r'// ── Bekleyen Davetler \(Landlord\) ───────────────────────\n\s*if \(effectiveIsLandlord\) \.\.\.\[[\s\S]*?\]\s*,\s*\],\s*\),');
  content = content.replaceFirst(pendingRegex, '''// ── Bekleyen Davetler (Landlord) ───────────────────────
                if (effectiveIsLandlord) ...[
                  const SizedBox(height: 16),
                  contractsAsync.when(
                    data: (contracts) {
                      final pending = contracts.where((c) => c.status == ContractStatus.pending || c.status == ContractStatus.negotiating).toList();
                      if (pending.isEmpty && activeContract == null) {
                        return _NoContractsEmptyState(onInvite: () => _showInviteDialog(context, ref));
                      }
                      if (pending.isEmpty) return const SizedBox.shrink();

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: StanomerColors.borderDefault),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                              child: Text(isTr ? 'Bekleyen Davetler' : 'Pending Invitations', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            ),
                            Divider(height: 1, color: StanomerColors.borderDefault.withOpacity(0.5)),
                            ...pending.asMap().entries.map((entry) {
                              final isLast = entry.key == pending.length - 1;
                              return Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: _ContractTile(contract: entry.value, propertyId: liveProperty.id, isLandlord: true),
                                  ),
                                  if (!isLast) Divider(height: 1, color: StanomerColors.borderDefault.withOpacity(0.5)),
                                ],
                              );
                            }),
                          ],
                        ),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error: \$e'),
                  ),
                ],''');

  // 4. Navigasyon
  final navRegex = RegExp(r'// ── Navigasyon Linkleri ────────────────────────────────\n\s*const SizedBox\(height: 16\),\n\s*Card\([\s\S]*?\]\s*,\s*\)\s*,\s*\),');
  content = content.replaceFirst(navRegex, '''// ── Navigasyon Linkleri ────────────────────────────────
                const SizedBox(height: 16),
                if (effectiveIsLandlord)
                  contractsAsync.when(
                    data: (contracts) {
                      final oldContracts = contracts.where((c) => c.status == ContractStatus.declined || c.status == ContractStatus.expired).toList();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _ModernNavRow(
                          icon: LucideIcons.history,
                          title: isTr ? 'Eski kontratlar' : 'Past contracts',
                          subtitle: '\${oldContracts.length} \${isTr ? 'eski kontrat' : 'previous leases'}',
                          onTap: () => _showPastContractsSheet(context, oldContracts),
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                _ModernNavRow(
                  icon: LucideIcons.settings,
                  title: isTr ? 'Ev ayarları' : 'Property settings',
                  subtitle: liveProperty.name,
                  onTap: () => _showPropertySettingsSheet(context),
                ),''');


  String helpers = '''

String _getOrdinal(int number) {
  if (number >= 11 && number <= 13) return 'th';
  switch (number % 10) {
    case 1: return 'st';
    case 2: return 'nd';
    case 3: return 'rd';
    default: return 'th';
  }
}

class _ModernContractRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;

  const _ModernContractRow({required this.icon, required this.label, required this.value, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: StanomerColors.textTertiary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: StanomerColors.textTertiary)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(subtitle!, style: const TextStyle(fontSize: 12, color: StanomerColors.brandPrimary, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernNavRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ModernNavRow({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: StanomerColors.borderDefault),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: StanomerColors.brandPrimary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: StanomerColors.brandPrimary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: StanomerColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 13, color: StanomerColors.textSecondary)),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, size: 16, color: StanomerColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
''';

  content = content + helpers;
  file.writeAsStringSync(content);
  print('done');
}
