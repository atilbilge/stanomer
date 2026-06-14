import 'dart:typed_data';
import 'package:universal_io/io.dart' as io;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stanomer/features/property/presentation/widgets/payment_responsibility_selector.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_filex/open_filex.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;
import '../domain/contract.dart';
import '../domain/property.dart';
import 'package:stanomer/core/utils/currency_utils.dart';
import '../data/property_repository.dart';
import '../../../core/utils/expense_utils.dart';
import '../../maintenance/domain/maintenance_request.dart';
import '../../maintenance/data/maintenance_repository.dart';
import '../domain/rent_payment.dart';
import '../domain/activity_log.dart';
import '../../auth/data/auth_providers.dart';
import '../../../core/services/document_storage_service.dart';
import 'package:path_provider/path_provider.dart';
import 'widgets/contract_file_picker.dart';

class PropertyDetailScreen extends ConsumerStatefulWidget {
  final Property property;
  final int initialTabIndex;

  const PropertyDetailScreen({super.key, required this.property, this.initialTabIndex = 0});

  @override
  ConsumerState<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends ConsumerState<PropertyDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTabIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);
    final role = user?.userMetadata?['role'] as String?;
    final roleColor = StanomerColors.getRoleColor(role);
    final currentIsLandlord = widget.property.landlordId == user?.id;
    final propertiesAsync = ref.watch(propertiesStreamProvider);
    
    // Find the current property in the stream to get up-to-date info
    final property = propertiesAsync.when(
      data: (list) => list.firstWhere((p) => p.id == widget.property.id, orElse: () => widget.property),
      loading: () => widget.property,
      error: (_, __) => widget.property,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(property.name),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: roleColor,
          labelColor: roleColor,
          unselectedLabelColor: StanomerColors.textTertiary,
          tabs: [
            Tab(text: loc.overview),
            Tab(text: loc.financials),
            Tab(text: loc.activity),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OverviewTab(property: property),
          _FinancialsTab(property: property),
          _ActivityTab(property: property),
        ],
      ),
    );
  }
}

class _OverviewTab extends ConsumerWidget {
  final Property property;
  const _OverviewTab({required this.property});

  void _showInviteDialog(BuildContext context, WidgetRef ref) {
    Contract? template;
    final contracts = ref.read(propertyContractsProvider(property.id)).value ?? [];
    
    if (contracts.isNotEmpty) {
      template = contracts.firstWhere((c) => c.status == ContractStatus.active, orElse: () => contracts.first);
    }

    context.push(
      '/invite-tenant',
      extra: {
        'property': property,
        'leaseTemplate': template,
      },
    );
  }

  void _showContractDetailsSheet(BuildContext context, Contract contract, String resolvedLandlordName, String resolvedTenantName, bool isTenant, bool isLandlord) {
    final loc = AppLocalizations.of(context)!;
    final roleColor = isTenant ? StanomerColors.successPrimary : StanomerColors.brandPrimary;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (_, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(loc.contractDetails, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push('/property-settings', extra: {
                      'property': property,
                      'initialTab': 'contract',
                    });
                  },
                  icon: Icon(LucideIcons.edit2, size: 16, color: roleColor),
                  label: Text(loc.editContract, style: TextStyle(color: roleColor, fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(foregroundColor: roleColor),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _ContractDetailRow(icon: LucideIcons.user, label: isTenant ? loc.landlord : loc.tenant, value: isTenant ? resolvedLandlordName : resolvedTenantName),
            _ContractDetailRow(icon: LucideIcons.banknote, label: loc.monthlyRent, value: CurrencyUtils.formatAmount(contract.monthlyRent, contract.currency)),
            if (contract.depositAmount != null)
              _ContractDetailRow(icon: LucideIcons.shield, label: loc.depositAmount, value: CurrencyUtils.formatAmount(contract.depositAmount!, contract.depositCurrency)),
            _ContractDetailRow(icon: LucideIcons.calendar, label: loc.startDate, value: contract.startDate != null ? DateFormat('dd/MM/yyyy').format(contract.startDate!) : '-'),
            _ContractDetailRow(icon: LucideIcons.calendarOff, label: loc.endDate, value: contract.endDate != null ? DateFormat('dd/MM/yyyy').format(contract.endDate!) : '-'),
            _ContractDetailRow(icon: LucideIcons.clock, label: loc.dueDay, value: '${contract.dueDay}'),
            if (contract.expensesConfig.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(loc.expensesHeader, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: StanomerColors.textTertiary)),
              const SizedBox(height: 8),
              ...contract.expensesConfig.map((e) => _ContractDetailRow(icon: LucideIcons.zap, label: e.name, value: e.receiver == PaymentReceiver.owner ? loc.roleLandlord : e.receiver == PaymentReceiver.utility ? loc.roleTenant : loc.included)),
            ],
            if (contract.contractUrl != null && contract.contractUrl!.isNotEmpty) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await _openFileOrUrl(context, contract.contractUrl!, mounted: context.mounted);
                  },
                  icon: const Icon(LucideIcons.externalLink, size: 18),
                  label: Text(loc.viewContract),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showPropertySettingsSheet(BuildContext context, bool isLandlord) {
    final loc = AppLocalizations.of(context)!;
    final roleColor = isLandlord ? StanomerColors.brandPrimary : StanomerColors.successPrimary;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.85,
        builder: (_, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(loc.propertySettingsLabel, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (isLandlord)
                  TextButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push('/property-settings', extra: {
                      'property': property,
                      'initialTab': 'property',
                    });
                  },
                  icon: Icon(LucideIcons.edit2, size: 16, color: roleColor),
                  label: Text(loc.editProperty, style: TextStyle(color: roleColor, fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(foregroundColor: roleColor),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _ContractDetailRow(icon: LucideIcons.home, label: loc.propertyName, value: property.name),
            _ContractDetailRow(icon: LucideIcons.mapPin, label: loc.address, value: property.address),
            _ContractDetailRow(icon: LucideIcons.banknote, label: loc.targetRent, value: CurrencyUtils.formatAmount(property.defaultMonthlyRent, property.currency)),
            if (property.defaultDepositAmount != null)
              _ContractDetailRow(icon: LucideIcons.shield, label: loc.depositAmount, value: CurrencyUtils.formatAmount(property.defaultDepositAmount!, property.defaultDepositCurrency)),
            _ContractDetailRow(icon: LucideIcons.clock, label: loc.dueDay, value: '${property.defaultDueDay}'),
            if (property.expensesTemplate.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(loc.expensesHeader, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: StanomerColors.textTertiary)),
              const SizedBox(height: 8),
              ...property.expensesTemplate.map((e) => _ContractDetailRow(icon: LucideIcons.zap, label: e.name, value: e.receiver == PaymentReceiver.owner ? loc.roleLandlord : e.receiver == PaymentReceiver.utility ? loc.roleTenant : loc.included)),
            ],
          ],
        ),
      ),
    );
  }


  void _showPastContractsSheet(BuildContext context, List<Contract> pastContracts) {
    final loc = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (_, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text(loc.pastContracts, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (pastContracts.isEmpty)
              Center(child: Text(loc.noFinancialRecords, style: const TextStyle(color: StanomerColors.textTertiary)))
            else
              ...pastContracts.map((c) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey.shade100,
                  child: const Icon(LucideIcons.fileText, size: 18, color: StanomerColors.textTertiary),
                ),
                title: Text(c.inviteeEmail, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${c.status.label(loc)} • ${CurrencyUtils.formatAmount(c.monthlyRent, c.currency)}', style: const TextStyle(fontSize: 12)),
                trailing: c.startDate != null ? Text(DateFormat('MM/yyyy').format(c.startDate!), style: const TextStyle(fontSize: 12, color: StanomerColors.textTertiary)) : null,
              )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;

    
    final propertyAsync = ref.watch(propertyProvider(property.id));
    final activeContractAsync = ref.watch(activeContractProvider(property.id));
    final contractsAsync = ref.watch(propertyContractsProvider(property.id));
    
    return propertyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.alertCircle, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text('Error loading property: $e', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  ref.invalidate(propertyProvider(property.id));
                  ref.invalidate(propertiesStreamProvider);
                }, 
                icon: const Icon(LucideIcons.refreshCw, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (liveProperty) {
        if (liveProperty == null) return const Center(child: Text('Property not found'));
        final user = ref.watch(currentUserProvider);
        final role = user?.userMetadata?['role'] as String?;
        final roleColor = StanomerColors.getRoleColor(role);
        final isLandlord = user?.id == liveProperty.landlordId;
        final isTenant = !isLandlord && user != null;

        final landlordProfileAsync = ref.watch(profileProvider(liveProperty.landlordId));
        final tenantProfileAsync = liveProperty.tenantId != null ? ref.watch(profileProvider(liveProperty.tenantId!)) : const AsyncValue.data(null);

        return activeContractAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.alertCircle, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text('Error loading contract: $e', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => ref.invalidate(activeContractProvider(property.id)), 
                    icon: const Icon(LucideIcons.refreshCw, size: 18),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (activeContract) {
            final effectiveIsTenant = isTenant;
            final effectiveIsLandlord = isLandlord;

            final currentRent = activeContract?.monthlyRent ?? liveProperty.defaultMonthlyRent;
            final currentCurrency = activeContract?.currency ?? liveProperty.currency;

            final resolvedLandlordName = landlordProfileAsync.value?['full_name'] ?? liveProperty.landlordName ?? activeContract?.inviterName ?? 'Landlord';
            final resolvedTenantName = tenantProfileAsync.value?['full_name'] ?? liveProperty.tenantName ?? activeContract?.inviteeEmail ?? 'Tenant';
            final resolvedLandlordEmail = landlordProfileAsync.value?['email'] ?? '';
            final resolvedTenantEmail = tenantProfileAsync.value?['email'] ?? activeContract?.inviteeEmail ?? '';

            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // ── Mülk ve Kira Özeti (Rent Banner) ───────────────────
                if (activeContract != null) ...[
                  Card(
                    clipBehavior: Clip.antiAlias,
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  loc.monthlyRent.toUpperCase(),
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: roleColor, letterSpacing: 1),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  CurrencyUtils.formatAmount(currentRent, currentCurrency),
                                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: StanomerColors.textPrimary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          _StatusBadge(
                            label: activeContract == null 
                                ? loc.statusVacant
                              : (activeContract.isEnded 
                                ? loc.ended
                                : (activeContract.status == ContractStatus.pending 
                                  ? loc.statusPending
                                  : (activeContract.status == ContractStatus.negotiating
                                    ? loc.statusNegotiating
                                    : (activeContract.status == ContractStatus.revisionRequested 
                                      ? loc.pendingApproval 
                                      : (activeContract.status == ContractStatus.terminationRequested 
                                        ? loc.terminationRequested 
                                        : (activeContract.status == ContractStatus.inactive ? loc.statusInactive : loc.activeLease)))))),
                            color: activeContract == null 
                                ? StanomerColors.textTertiary
                              : (activeContract.isEnded 
                                ? StanomerColors.textTertiary 
                                : (activeContract.status == ContractStatus.pending || activeContract.status == ContractStatus.negotiating || activeContract.status == ContractStatus.revisionRequested || activeContract.status == ContractStatus.terminationRequested
                                  ? Colors.orange 
                                  : (activeContract.status == ContractStatus.inactive ? StanomerColors.textTertiary : StanomerColors.successPrimary))),
                            isFilled: true,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Contract Info Card ─────────────────────────────────
                  const SizedBox(height: 16),
                  Card(
                    clipBehavior: Clip.antiAlias,
                    margin: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                          child: Text(loc.contractInfo, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: StanomerColors.textPrimary)),
                        ),
                        const Divider(height: 1),
                        
                        if (effectiveIsTenant)
                          _InfoRow(icon: LucideIcons.user, label: loc.landlord, value: resolvedLandlordName, iconColor: roleColor),
                        if (effectiveIsLandlord)
                          _InfoRow(icon: LucideIcons.user, label: loc.tenant, value: resolvedTenantName, iconColor: roleColor),
                          
                        const Divider(height: 1, indent: 20, endIndent: 20),
                        _InfoRow(icon: LucideIcons.calendar, label: activeContract.status == ContractStatus.inactive ? loc.terminationDate : loc.term,
                          value: activeContract.status == ContractStatus.inactive 
                            ? (activeContract.endDate != null ? DateFormat('dd/MM/yyyy').format(activeContract.endDate!) : '-')
                            : '${activeContract.startDate != null ? DateFormat('dd/MM/yy').format(activeContract.startDate!) : '?'} – ${activeContract.endDate != null ? DateFormat('dd/MM/yy').format(activeContract.endDate!) : '?'}',
                          iconColor: roleColor,
                        ),
                          
                        const Divider(height: 1, indent: 20, endIndent: 20),
                        _InfoRow(
                          icon: LucideIcons.fileText, 
                          label: loc.documents, 
                          value: ((activeContract.contractUrl != null && activeContract.contractUrl!.isNotEmpty ? 1 : 0) + activeContract.additionalDocuments.length).toString(),
                          onTap: () => _showDocumentsSheet(context, ref, activeContract, canManage: effectiveIsLandlord),
                          iconColor: roleColor,
                        ),
                        
                        const Divider(height: 1),
                        InkWell(
                          onTap: () => _showContractDetailsSheet(context, activeContract, resolvedLandlordName, resolvedTenantName, effectiveIsTenant, effectiveIsLandlord),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            child: Row(
                              children: [
                                Text(loc.contractDetails, style: TextStyle(fontSize: 13, color: roleColor, fontWeight: FontWeight.w600)),
                                const SizedBox(width: 4),
                                Icon(LucideIcons.chevronRight, size: 16, color: roleColor),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // If no contract, just show the target rent banner
                  Card(
                    clipBehavior: Clip.antiAlias,
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(loc.targetRent.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: roleColor, letterSpacing: 1)),
                          const SizedBox(height: 8),
                          Text(CurrencyUtils.formatAmount(currentRent, currentCurrency), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: StanomerColors.textPrimary)),
                        ],
                      ),
                    ),
                  ),
                ],

                // ── Değişiklik Teklifi Kartı ────────────────────────────
                if (activeContract != null && (activeContract.status == ContractStatus.revisionRequested || activeContract.status == ContractStatus.negotiating)) ...[
                  const SizedBox(height: 16),
                  _ProposalReviewCard(
                    contract: activeContract,
                    isTenant: effectiveIsTenant,
                    isLandlord: effectiveIsLandlord,
                    propertyId: liveProperty.id,
                    landlordName: resolvedLandlordName,
                    tenantName: resolvedTenantName,
                    landlordEmail: resolvedLandlordEmail,
                    tenantEmail: resolvedTenantEmail,
                  ),
                ],

                // ── Fesih Talebi Kartı ──────────────────────────────────
                if (activeContract != null && activeContract.status == ContractStatus.terminationRequested) ...[
                  const SizedBox(height: 16),
                  _TerminationBanner(
                    contract: activeContract,
                    currentUser: user,
                    propertyId: liveProperty.id,
                  ),
                ],

                // ── Planned Termination Banner ────────────────────────
                if (activeContract != null && activeContract.terminationApproved && !activeContract.isEnded) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.calendarCheck, size: 20, color: Colors.orange),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loc.terminationApproved,
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                loc.contractWillEndOn(activeContract.endDate != null ? DateFormat('dd/MM/yyyy').format(activeContract.endDate!) : '-'),
                                style: const TextStyle(fontSize: 12, color: StanomerColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                // ── Fesih Bildirimi (Bitti İse) ────────────────────────
                if (activeContract != null && activeContract.isEnded) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: StanomerColors.textTertiary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: StanomerColors.borderDefault),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.fileX2, size: 20, color: StanomerColors.textTertiary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            loc.contractTerminatedOn(activeContract.endDate != null ? DateFormat('dd/MM/yyyy').format(activeContract.endDate!) : '-'),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: StanomerColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── Bekleyen Davetler (Landlord) ───────────────────────
                if (effectiveIsLandlord) ...[
                  const SizedBox(height: 16),
                  contractsAsync.when(
                    data: (contracts) {
                      final pending = contracts.where((c) => c.status == ContractStatus.pending || c.status == ContractStatus.negotiating).toList();
                      if (pending.isEmpty && activeContract == null) {
                        return _NoContractsEmptyState(onInvite: () => _showInviteDialog(context, ref));
                      }
                      if (pending.isEmpty) return const SizedBox.shrink();

                      return _SectionCard(
                        title: loc.sentInvitation,
                        children: pending.map((c) => _ContractTile(contract: c, propertyId: liveProperty.id, isLandlord: true)).toList(),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error: $e'),
                  ),
                ],

                // ── Mülk İşlemleri (Property Actions) ──────────────────
                const SizedBox(height: 16),
                Card(
                  clipBehavior: Clip.antiAlias,
                  margin: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                        child: Text(loc.propertyActions, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: StanomerColors.textPrimary)),
                      ),
                      const Divider(height: 1),

                      _ModernNavRow(
                        icon: LucideIcons.wrench,
                        title: loc.maintenance,
                        subtitle: isTenant ? loc.reportIssue : '${loc.maintenance} & ${loc.issues}',
                        iconColor: roleColor,
                        onTap: () async {
                          if (isTenant) {
                            try {
                              // Check if there are any existing requests
                              final requests = await ref.read(maintenanceRequestsProvider(property.id).future);
                              if (requests.isEmpty) {
                                // If empty, go directly to creation screen
                                if (context.mounted) context.push('/maintenance/new', extra: property);
                                return;
                              }
                            } catch (e) {
                              // If error (network etc), fallback to list screen
                            }
                          }
                          if (context.mounted) context.push('/maintenance', extra: property);
                        },
                      ),

                      if (effectiveIsLandlord) ...[
                        const Divider(height: 1, indent: 20, endIndent: 20),
                        contractsAsync.when(
                          data: (contracts) {
                            final oldContracts = contracts.where((c) => c.status == ContractStatus.declined || c.status == ContractStatus.expired).toList();
                            return _ModernNavRow(
                              icon: LucideIcons.history,
                              title: loc.pastContracts,
                              subtitle: loc.previousLeasesCount(oldContracts.length),
                              iconColor: roleColor,
                              onTap: () => _showPastContractsSheet(context, oldContracts),
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ],

                      if (effectiveIsLandlord) ...[
                        const Divider(height: 1, indent: 20, endIndent: 20),
                        _ModernNavRow(
                          icon: LucideIcons.settings,
                          title: loc.propertySettingsLabel,
                          subtitle: liveProperty.name,
                          iconColor: roleColor,
                          onTap: () => context.push('/property-settings', extra: {
                            'property': property,
                            'initialTab': 'property',
                          }),
                        ),
                      ],

                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ── Yardımcı Widget'lar ──────────────────────────────────────────────────────

  void _showDocumentsSheet(BuildContext context, WidgetRef ref, Contract contract, {bool canManage = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: _DocumentsSheetContent(
            contractId: contract.id,
            propertyId: contract.propertyId,
            canManage: canManage,
          ),
        ),
      ),
    );
  }

class _DocumentsSheetContent extends ConsumerStatefulWidget {
  final String contractId;
  final String propertyId;
  final bool canManage;

  const _DocumentsSheetContent({
    required this.contractId,
    required this.propertyId,
    required this.canManage,
  });

  @override
  ConsumerState<_DocumentsSheetContent> createState() => _DocumentsSheetContentState();
}

class _DocumentsSheetContentState extends ConsumerState<_DocumentsSheetContent> {
  bool _isLoading = false;

  bool _isImage(String url) {
    final cleanUrl = url.split('?').first.toLowerCase();
    return cleanUrl.endsWith('.jpg') ||
        cleanUrl.endsWith('.jpeg') ||
        cleanUrl.endsWith('.png') ||
        cleanUrl.endsWith('.webp') ||
        cleanUrl.endsWith('.gif');
  }

  Widget _buildThumbnail(String url) {
    final isImage = _isImage(url);
    if (isImage) {
      final isRemote = url.startsWith('http://') || url.startsWith('https://');
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 48,
          height: 48,
          color: Colors.grey.shade200,
          child: isRemote
              ? Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(LucideIcons.image, size: 20, color: Colors.grey),
                )
              : Image.file(
                  io.File(url),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(LucideIcons.image, size: 20, color: Colors.grey),
                ),
        ),
      );
    } else {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 48,
          height: 48,
          color: Colors.red.shade50,
          child: const Center(
            child: Icon(LucideIcons.fileText, color: Colors.red, size: 24),
          ),
        ),
      );
    }
  }

  Future<void> _uploadContract(bool isMainContract) async {
    final loc = AppLocalizations.of(context)!;
    String name = 'Main Contract';

    if (!isMainContract) {
      final nameController = TextEditingController();
      final enteredName = await showDialog<String>(
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
      if (enteredName == null || enteredName.isEmpty) return;
      name = enteredName;
    }

    if (!mounted) return;
    final result = await pickContractFile(context);
    if (result == null) return;

    List<int>? fileBytes = result.files.single.bytes?.toList();

    if (fileBytes == null && result.files.single.path != null) {
      fileBytes = await io.File(result.files.single.path!).readAsBytes();
    }
    if (fileBytes == null) return;

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(propertyRepositoryProvider);
      final isCloudAllowed = ref.read(cloudUploadAllowedProvider);

      if (isMainContract) {
        if (isCloudAllowed) {
          await repo.updateMainContract(
            widget.contractId,
            fileBytes,
            result.files.single.extension ?? 'pdf',
          );
        } else {
          final io.File localFile;
          if (result.files.single.path != null) {
            localFile = io.File(result.files.single.path!);
          } else {
            final tempDir = await getTemporaryDirectory();
            localFile = io.File('${tempDir.path}/${result.files.single.name}');
            await localFile.writeAsBytes(fileBytes);
          }
          final localPath = await ref.read(documentStorageServiceProvider).saveDocument(localFile);
          await repo.updateMainContractLocal(widget.contractId, localPath);
        }
      } else {
        if (isCloudAllowed) {
          await repo.uploadContractDocument(
            widget.contractId,
            name,
            fileBytes,
            result.files.single.extension ?? 'pdf',
          );
        } else {
          final io.File localFile;
          if (result.files.single.path != null) {
            localFile = io.File(result.files.single.path!);
          } else {
            final tempDir = await getTemporaryDirectory();
            localFile = io.File('${tempDir.path}/${result.files.single.name}');
            await localFile.writeAsBytes(fileBytes);
          }
          final localPath = await ref.read(documentStorageServiceProvider).saveDocument(localFile);
          await repo.addAdditionalDocument(widget.contractId, name, localPath);
        }
      }
      ref.invalidate(activeContractProvider(widget.propertyId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteMainContract(Contract contract) async {
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

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(propertyRepositoryProvider);
      
      final url = contract.contractUrl;
      if (url != null && !url.startsWith('http://') && !url.startsWith('https://')) {
        try {
          final file = io.File(url);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (_) {}
      }

      await repo.deleteMainContract(widget.contractId);
      ref.invalidate(activeContractProvider(widget.propertyId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAdditionalDoc(ContractDocument doc) async {
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

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(propertyRepositoryProvider);
      
      if (!doc.url.startsWith('http://') && !doc.url.startsWith('https://')) {
        try {
          final file = io.File(doc.url);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (_) {}
      }

      await repo.deleteContractDocument(widget.contractId, doc);
      ref.invalidate(activeContractProvider(widget.propertyId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final contractAsync = ref.watch(activeContractProvider(widget.propertyId));
    final user = ref.read(currentUserProvider);
    final role = user?.userMetadata?['role'] as String?;
    final roleColor = StanomerColors.getRoleColor(role);

    return contractAsync.when(
      data: (contract) {
        if (contract == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final hasMainContract = contract.contractUrl != null && contract.contractUrl!.isNotEmpty;

        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(loc.documents, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  // STORAGE INFO BANNER
                  (() {
                    final isCloudAllowed = ref.watch(cloudUploadAllowedProvider);
                    final bannerBgColor = isCloudAllowed ? const Color(0xFFEDF7ED) : const Color(0xFFFFF8E1);
                    final bannerBorderColor = isCloudAllowed ? const Color(0xFFC8E6C9) : const Color(0xFFFFECB3);
                    final bannerIconColor = isCloudAllowed ? const Color(0xFF2E7D32) : const Color(0xFFF57F17);
                    final bannerIcon = isCloudAllowed ? LucideIcons.shieldCheck : LucideIcons.smartphone;
                    final bannerText = isCloudAllowed ? loc.invoiceCloudSecureDesc : loc.invoiceLocalOnlyDesc;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: bannerBgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: bannerBorderColor),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(bannerIcon, size: 18, color: bannerIconColor),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              bannerText,
                              style: TextStyle(
                                fontSize: 12,
                                color: isCloudAllowed ? const Color(0xFF1B5E20) : const Color(0xFF5D4037),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  })(),
                  
                  Text(
                    loc.mainContract.toUpperCase(),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: roleColor, letterSpacing: 1.1),
                  ),
                  const SizedBox(height: 8),
                  if (hasMainContract)
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: StanomerColors.borderDefault),
                      ),
                      child: ListTile(
                        leading: _buildThumbnail(contract.contractUrl!),
                        title: Text(loc.mainContract, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        subtitle: Text(
                          contract.createdAt != null
                              ? DateFormat('dd/MM/yyyy').format(contract.createdAt!)
                              : '-',
                          style: const TextStyle(fontSize: 11),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(LucideIcons.eye, color: roleColor, size: 18),
                              onPressed: () => _openFileOrUrl(context, contract.contractUrl!, mounted: mounted),
                            ),
                            if (widget.canManage)
                              IconButton(
                                icon: const Icon(LucideIcons.trash2, color: StanomerColors.alertPrimary, size: 18),
                                onPressed: () => _deleteMainContract(contract),
                              ),
                          ],
                        ),
                      ),
                    )
                  else if (widget.canManage)
                    GestureDetector(
                      onTap: () => _uploadContract(true),
                      child: CustomPaint(
                        painter: DashedRectPainter(
                          color: roleColor.withValues(alpha: 0.5),
                          borderRadius: 12,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.uploadCloud, color: roleColor, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                loc.uploadMainContract,
                                style: TextStyle(color: roleColor, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(loc.noActiveContract, style: const TextStyle(color: StanomerColors.textTertiary, fontSize: 12)),
                    ),

                  const SizedBox(height: 24),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        loc.additionalDocuments.toUpperCase(),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: roleColor, letterSpacing: 1.1),
                      ),
                      if (widget.canManage)
                        TextButton.icon(
                          onPressed: () => _uploadContract(false),
                          icon: Icon(LucideIcons.plus, size: 14, color: roleColor),
                          label: Text(loc.add, style: TextStyle(color: roleColor, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (contract.additionalDocuments.isNotEmpty)
                    Column(
                      children: contract.additionalDocuments.map((doc) {
                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: StanomerColors.borderDefault),
                          ),
                          child: ListTile(
                            leading: _buildThumbnail(doc.url),
                            title: Text(doc.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            subtitle: Text(
                              doc.createdAt != null
                                  ? DateFormat('dd/MM/yyyy').format(doc.createdAt!)
                                  : '-',
                              style: const TextStyle(fontSize: 11),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(LucideIcons.eye, color: roleColor, size: 18),
                                  onPressed: () => _openFileOrUrl(context, doc.url, mounted: mounted),
                                ),
                                if (widget.canManage)
                                  IconButton(
                                    icon: const Icon(LucideIcons.trash2, color: StanomerColors.alertPrimary, size: 18),
                                    onPressed: () => _deleteAdditionalDoc(doc),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          loc.noDocumentsYet,
                          style: const TextStyle(color: StanomerColors.textTertiary, fontSize: 12),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black26,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => SizedBox(
        height: 200,
        child: Center(child: Text('Error loading documents: $e')),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const Divider(),
            const SizedBox(height: 4),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final Color? iconColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 18, color: iconColor ?? StanomerColors.textTertiary),
            const SizedBox(width: 14),
            Text(label, style: const TextStyle(fontSize: 14, color: StanomerColors.textSecondary)),
            const Spacer(),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: StanomerColors.textPrimary)),
            if (onTap != null) ...[
              const SizedBox(width: 8),
              const Icon(LucideIcons.chevronRight, size: 14, color: StanomerColors.textTertiary),
            ],
          ],
        ),
      ),
    );
  }
}

class _ContractDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ContractDetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: StanomerColors.textTertiary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: StanomerColors.textTertiary, fontWeight: FontWeight.bold)),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? badge;
  final VoidCallback onTap;
  const _NavRow({required this.icon, required this.label, required this.onTap, this.badge});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: StanomerColors.brandPrimary),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: StanomerColors.brandPrimary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                child: Text(badge!, style: const TextStyle(fontSize: 11, color: StanomerColors.brandPrimary, fontWeight: FontWeight.bold)),
              ),
            const SizedBox(width: 8),
            const Icon(LucideIcons.chevronRight, size: 16, color: StanomerColors.textTertiary),
          ],
        ),
      ),
    );
  }
}





class _ContractTile extends ConsumerWidget {
  final Contract contract;
  final String propertyId;
  final bool isLandlord;
  const _ContractTile({
    required this.contract, 
    required this.propertyId,
    required this.isLandlord,
  });

  void _showShareSheet(BuildContext context, AppLocalizations loc) {
    final link = 'stanomer://invite?token=${contract.token}';
    final roleColor = StanomerColors.brandPrimary;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text(loc.shareInviteLink, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            // QR Kod
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: QrImageView(
                data: link,
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            // Link kutusu
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
                    child: Text(link, style: const TextStyle(fontSize: 12, color: StanomerColors.textSecondary), overflow: TextOverflow.ellipsis),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.copy, size: 18),
                    tooltip: loc.copyLink,
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: link));
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(loc.copyLink)));
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
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(LucideIcons.share2, size: 18),
                label: Text(loc.share),
                onPressed: () => Share.share(link),
                style: ElevatedButton.styleFrom(backgroundColor: roleColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;

    final isPending = contract.status == ContractStatus.pending;
    final isNegotiating = contract.status == ContractStatus.negotiating || contract.status == ContractStatus.revisionRequested;
    final inviteDate = contract.createdAt != null ? DateFormat('dd/MM/yyyy').format(contract.createdAt!) : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: (isPending || isNegotiating) ? Colors.blue.shade50 : Colors.green.shade50,
                child: Icon(
                  isNegotiating ? LucideIcons.messageSquare : (isPending ? LucideIcons.mail : LucideIcons.check),
                  size: 18,
                  color: (isPending || isNegotiating) ? Colors.blue : Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // E-posta
                    if (contract.inviteeEmail.isNotEmpty)
                      Text(contract.inviteeEmail, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))
                    else
                      Text(loc.noEmailProvided, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: StanomerColors.textTertiary)),
                    // Kira bilgisi
                    Text(
                      '${contract.status.label(loc)} • ${contract.monthlyRent} ${contract.currency}',
                      style: const TextStyle(fontSize: 12, color: StanomerColors.textTertiary),
                    ),
                    // Davet tarihi
                    if (inviteDate != null)
                      Text(
                        loc.invitedOn(inviteDate),
                        style: const TextStyle(fontSize: 11, color: StanomerColors.textTertiary),
                      ),
                  ],
                ),
              ),
              // Düzenle butonu (sadece ev sahibi)
              if (isLandlord && (isPending || isNegotiating))
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(LucideIcons.edit2, size: 18, color: StanomerColors.brandPrimary),
                  onPressed: () {
                    context.push(
                      '/invite-tenant',
                      extra: {
                        'property': ref.read(propertiesStreamProvider).value!.firstWhere((p) => p.id == propertyId), 
                        'contract': contract,
                      },
                    );
                  },
                  tooltip: loc.editContract,
                ),
              // Paylaş butonu (sadece ev sahibi, sadece pending)
              if (isLandlord && isPending)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(LucideIcons.share2, size: 18, color: StanomerColors.brandPrimary),
                  onPressed: () => _showShareSheet(context, loc),
                  tooltip: loc.share,
                ),
            ],
          ),
          if (contract.tenantFeedback != null && contract.tenantFeedback!.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: const BorderRadius.all(StanomerRadius.md),
                border: Border.all(color: Colors.orange.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.messageSquare, size: 12, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        '${loc.tenant}:',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    contract.tenantFeedback!,
                    style: const TextStyle(fontSize: 12, color: StanomerColors.textPrimary),
                  ),
                ],
              ),
            ),
          if (isLandlord && (isPending || isNegotiating))
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: TextButton(
                  onPressed: () async {
                    final isNeg = contract.status == ContractStatus.negotiating;
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(isNeg ? loc.confirmDeclineRevisionTitle : loc.confirmCancelInvitationTitle),
                        content: Text(isNeg ? loc.confirmDeclineRevisionMessage : loc.confirmCancelInvitationMessage),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(loc.cancel)),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true), 
                            style: TextButton.styleFrom(foregroundColor: StanomerColors.alertPrimary),
                            child: Text(isNeg ? loc.decline : loc.confirmCancelInvitationTitle),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      if (isNeg) {
                        await ref.read(propertyRepositoryProvider).declineProposedChanges(contract.id);
                        ref.invalidate(propertyContractsProvider(propertyId));
                        ref.invalidate(activeContractProvider(propertyId));
                        ref.invalidate(propertyProvider(propertyId));
                      } else {
                        await ref.read(propertyRepositoryProvider).cancelInvite(contract.id);
                        ref.invalidate(propertyContractsProvider(propertyId));
                        ref.invalidate(activeContractProvider(propertyId));
                        ref.invalidate(propertyProvider(propertyId));
                        ref.invalidate(propertyFinancialStatusProvider(propertyId));
                        ref.invalidate(propertiesStreamProvider);
                        if (context.mounted) Navigator.pop(context);
                      }
                    }
                  },
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    contract.status == ContractStatus.negotiating 
                      ? loc.declineRevisionRequest 
                      : loc.cancel, 
                    style: const TextStyle(color: StanomerColors.alertPrimary, fontSize: 13)
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FinancialsTab extends ConsumerStatefulWidget {
  final Property property;
  const _FinancialsTab({required this.property});

  @override
  ConsumerState<_FinancialsTab> createState() => _FinancialsTabState();
}

class _FinancialsTabState extends ConsumerState<_FinancialsTab> {
  bool _isPickingFile = false;
  String? _uploadingPaymentId;
  final Set<String> _expandedPaymentIds = {};

  Future<bool> _showConfirmDialog({
    required String title,
    required String message,
  }) async {
    final loc = AppLocalizations.of(context)!;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: StanomerColors.brandPrimary,
              foregroundColor: Colors.white,
            ),
            child: Text(loc.confirm),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _handlePaymentDeclaration(RentPayment payment, String monthName, FilePickerResult? result, {bool isCash = false}) async {
    final messenger = ScaffoldMessenger.of(context);
    final loc = AppLocalizations.of(context)!;

    try {
      if (isCash) {
        final noteController = TextEditingController();
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(loc.paidInCash),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ExpenseUtils.getLocalizedExpenseName(payment.title, loc), style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: noteController,
                  decoration: InputDecoration(
                    labelText: loc.explanationOptional,
                    hintText: loc.explanationHint,
                  ),
                  maxLines: 2,
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text(loc.cancel)),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: StanomerColors.brandPrimary, foregroundColor: Colors.white),
                child: Text(loc.confirm),
              ),
            ],
          ),
        );

        if (confirmed != true) return;

        setState(() => _uploadingPaymentId = payment.id);

        await ref.read(propertyRepositoryProvider).declareRentAsPaid(
          payment.id, 
          widget.property.id, 
          monthName,
          payment.dueDate,
          receiptUrl: 'CASH', // Use 'CASH' as a safe marker for elden ödeme
          note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
        );

        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(content: Text(loc.paymentDeclaredHand)),
        );
      } else if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        setState(() {
          _uploadingPaymentId = payment.id;
        });

        // 2. Upload the receipt
        List<int>? fileBytes = file.bytes?.toList();
        if (fileBytes == null && file.path != null) {
          fileBytes = await io.File(file.path!).readAsBytes();
        }

        if (fileBytes == null) {
          if (mounted) {
            messenger.showSnackBar(
              SnackBar(content: Text(loc.fileUnreadable)),
            );
          }
          return;
        }

        final String receiptUrl;
        if (ref.read(cloudUploadAllowedProvider)) {
          receiptUrl = await ref.read(propertyRepositoryProvider).uploadReceipt(
            file.name,
            bytes: Uint8List.fromList(fileBytes),
          );
        } else {
          final io.File localFile;
          if (file.path != null) {
            localFile = io.File(file.path!);
          } else {
            final tempDir = await getTemporaryDirectory();
            localFile = io.File('${tempDir.path}/${file.name}');
            await localFile.writeAsBytes(fileBytes);
          }
          receiptUrl = await ref.read(documentStorageServiceProvider).saveDocument(localFile);
        }

        // 3. Declare as paid with the URL
        await ref.read(propertyRepositoryProvider).declareRentAsPaid(
          payment.id, 
          widget.property.id, 
          monthName,
          payment.dueDate,
          receiptUrl: receiptUrl,
        );

        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(content: Text(loc.paymentDeclaredSuccess(ExpenseUtils.getLocalizedExpenseName(payment.title, loc)))),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<FilePickerResult?> _pickReceiptFile() async {
    final source = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        final l = AppLocalizations.of(context)!;
        String pdfText = 'Select Document (PDF)';
        String imgText = 'Select Photo / Gallery';
        if (l.localeName == 'tr') {
          pdfText = 'Belge Seç (PDF)';
          imgText = 'Fotoğraf Seç / Galeri';
        } else if (l.localeName.startsWith('sr')) {
          pdfText = 'Izaberi dokument (PDF)';
          imgText = 'Izaberi sliku / Galerija';
        } else if (l.localeName == 'ru') {
          pdfText = 'Выбрать документ (PDF)';
          imgText = 'Выбрать фото / Галерея';
        }
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  l.invoiceUploadLimitDesc,
                  style: const TextStyle(
                    fontSize: 12,
                    color: StanomerColors.textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(LucideIcons.fileText),
                title: Text(pdfText),
                onTap: () => Navigator.pop(ctx, 'pdf'),
              ),
              ListTile(
                leading: const Icon(LucideIcons.image),
                title: Text(imgText),
                onTap: () => Navigator.pop(ctx, 'image'),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return null;

    return await (source == 'pdf'
        ? FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['pdf', 'PDF'],
            withData: true,
          )
        : FilePicker.platform.pickFiles(
            type: FileType.image,
            withData: true,
          ));
  }

  Future<void> _handleInvoiceUpload(RentPayment payment, String monthName) async {
    final loc = AppLocalizations.of(context)!;
    final amountController = TextEditingController(text: payment.amount > 0 ? payment.amount.toStringAsFixed(2) : '');
    final noteController = TextEditingController(text: payment.ownerNote ?? '');
    String selectedCurrency = payment.currency.isEmpty || payment.currency == 'EUR' ? 'RSD' : payment.currency; // Default to RSD as requested
    FilePickerResult? selectedFile;
    bool isExistingRemoved = false;

    Future<FilePickerResult?> pickInvoiceFile(StateSetter setDialogState) async {
      final source = await showModalBottomSheet<String>(
        context: context,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        builder: (ctx) {
          final l = AppLocalizations.of(context)!;
          String pdfText = 'Select Document (PDF)';
          String imgText = 'Select Photo / Gallery';
          if (l.localeName == 'tr') {
            pdfText = 'Belge Seç (PDF)';
            imgText = 'Fotoğraf Seç / Galeri';
          } else if (l.localeName.startsWith('sr')) {
            pdfText = 'Izaberi dokument (PDF)';
            imgText = 'Izaberi sliku / Galerija';
          } else if (l.localeName == 'ru') {
            pdfText = 'Выбрать документ (PDF)';
            imgText = 'Выбрать фото / Галерея';
          }
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    l.invoiceUploadLimitDesc,
                    style: const TextStyle(
                      fontSize: 12,
                      color: StanomerColors.textTertiary,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(LucideIcons.fileText),
                  title: Text(pdfText),
                  onTap: () => Navigator.pop(ctx, 'pdf'),
                ),
                ListTile(
                  leading: const Icon(LucideIcons.image),
                  title: Text(imgText),
                  onTap: () => Navigator.pop(ctx, 'image'),
                ),
              ],
            ),
          );
        },
      );

      if (source == null) return null;

      final result = await (source == 'pdf'
          ? FilePicker.platform.pickFiles(
              type: FileType.custom,
              allowedExtensions: ['pdf', 'PDF'],
              withData: true,
            )
          : FilePicker.platform.pickFiles(
              type: FileType.image,
              withData: true,
            ));

      if (result != null) {
        setDialogState(() => selectedFile = result);
      }
      return result;
    }

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isCloudAllowed = ref.read(cloudUploadAllowedProvider);
          final storageInfo = isCloudAllowed ? loc.invoiceCloudSecureDesc : loc.invoiceLocalOnlyDesc;
          
          final mediaQuery = MediaQuery.of(context);
          final isLandscape = mediaQuery.orientation == Orientation.landscape;
          final isTablet = mediaQuery.size.shortestSide >= 600;
          final useSingleRowActions = isLandscape || isTablet;

          final url = payment.invoiceUrl;
          final isRemote = url != null && (url.startsWith('http://') || url.startsWith('https://'));
          final localFileExists = url != null && !isRemote && io.File(url).existsSync();
          final isMissingLocal = url != null && !isRemote && !localFileExists && !isExistingRemoved;

          return AlertDialog(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: loc.setAmountUploadInvoice,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: StanomerColors.textPrimary,
                            ),
                          ),
                          if (useSingleRowActions) ...[
                            TextSpan(
                              text: ' ($monthName · ${ExpenseUtils.getLocalizedExpenseName(payment.title, loc)})',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.normal,
                                color: StanomerColors.textTertiary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (!useSingleRowActions) ...[
                      const SizedBox(height: 4),
                      // Subtitle (Month & Title)
                      Text(
                        '$monthName · ${ExpenseUtils.getLocalizedExpenseName(payment.title, loc)}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: StanomerColors.textTertiary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    // Amount & Currency Input
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: amountController,
                            decoration: InputDecoration(
                              labelText: loc.amount,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: DropdownButtonFormField<String>(
                            value: selectedCurrency,
                            decoration: InputDecoration(
                              labelText: loc.currency,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                            ),
                            items: ['EUR', 'RSD'].map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
                            onChanged: (val) {
                              if (val != null) setDialogState(() => selectedCurrency = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Note Input
                    TextField(
                      controller: noteController,
                      decoration: InputDecoration(
                        labelText: loc.explanationOptional,
                        hintText: loc.localeName == 'tr' ? 'Fatura ile ilgili not ekle...' : loc.explanationHint,
                      ),
                      maxLines: useSingleRowActions ? 1 : 2,
                    ),
                    const SizedBox(height: 20),
                    // File Selection or Preview Area
                    (() {
                      final showNewPreview = selectedFile != null;
                      final showExistingPreview = !showNewPreview && payment.invoiceUrl != null && !isExistingRemoved;

                      if (showNewPreview) {
                        final file = selectedFile!.files.first;
                        final ext = file.extension?.toLowerCase() ?? '';
                        final isImage = ['png', 'jpg', 'jpeg', 'gif', 'webp'].contains(ext) ||
                            file.name.toLowerCase().endsWith('.png') ||
                            file.name.toLowerCase().endsWith('.jpg') ||
                            file.name.toLowerCase().endsWith('.jpeg');
                        
                        Widget imageWidget;
                        if (isImage) {
                          if (file.bytes != null) {
                            imageWidget = Image.memory(file.bytes!, fit: BoxFit.cover);
                          } else if (file.path != null) {
                            imageWidget = Image.file(io.File(file.path!), fit: BoxFit.cover);
                          } else {
                            imageWidget = const Icon(LucideIcons.image, size: 24, color: Colors.grey);
                          }
                        } else {
                          imageWidget = const Icon(LucideIcons.fileText, size: 24, color: Colors.red);
                        }

                        return Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey.shade50,
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  width: 56,
                                  height: 56,
                                  color: isImage ? Colors.grey.shade200 : Colors.red.shade50,
                                  child: imageWidget,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      file.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        if (file.path != null) ...[
                                          GestureDetector(
                                            onTap: () => _openFileOrUrl(context, file.path!, mounted: context.mounted),
                                            child: Text(
                                              loc.viewInvoice,
                                              style: const TextStyle(
                                                color: StanomerColors.brandPrimary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                decoration: TextDecoration.underline,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                        ],
                                        GestureDetector(
                                          onTap: () => setDialogState(() => selectedFile = null),
                                          child: Text(
                                            loc.remove,
                                            style: const TextStyle(
                                              color: StanomerColors.alertPrimary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              decoration: TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      if (showExistingPreview) {
                        if (isMissingLocal) {
                          return Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.amber.shade300),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.amber.shade50,
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(LucideIcons.alertTriangle, color: Colors.amber.shade800, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        loc.billMissingLocalDesc,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.amber.shade900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () => pickInvoiceFile(setDialogState),
                                    icon: const Icon(LucideIcons.upload, size: 16),
                                    label: Text(loc.localeName == 'tr' ? 'Yeni Fatura Yükle' : 'Upload New Bill'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.amber.shade900,
                                      side: BorderSide(color: Colors.amber.shade600),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final isImage = url!.toLowerCase().endsWith('.png') ||
                            url.toLowerCase().endsWith('.jpg') ||
                            url.toLowerCase().endsWith('.jpeg') ||
                            url.toLowerCase().endsWith('.webp') ||
                            url.toLowerCase().endsWith('.gif');

                        Widget imageWidget;
                        if (isImage) {
                          if (isRemote) {
                            imageWidget = Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(LucideIcons.image, size: 24, color: Colors.grey));
                          } else {
                            imageWidget = Image.file(io.File(url), fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(LucideIcons.image, size: 24, color: Colors.grey));
                          }
                        } else {
                          imageWidget = const Icon(LucideIcons.fileText, size: 24, color: Colors.red);
                        }

                        return Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey.shade50,
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  width: 56,
                                  height: 56,
                                  color: isImage ? Colors.grey.shade200 : Colors.red.shade50,
                                  child: imageWidget,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      url.split('/').last,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        GestureDetector(
                                          onTap: () => _openFileOrUrl(context, url, mounted: context.mounted),
                                          child: Text(
                                            loc.viewInvoice,
                                            style: const TextStyle(
                                              color: StanomerColors.brandPrimary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              decoration: TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        GestureDetector(
                                          onTap: () => setDialogState(() => isExistingRemoved = true),
                                          child: Text(
                                            loc.remove,
                                            style: const TextStyle(
                                              color: StanomerColors.alertPrimary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              decoration: TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // Default dashed card (only shown in portrait mode when no file exists/is selected)
                      if (useSingleRowActions) {
                        return const SizedBox.shrink();
                      }

                      return SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => pickInvoiceFile(setDialogState),
                          icon: const Icon(LucideIcons.upload, size: 18),
                          label: Text(loc.uploadInvoice),
                        ),
                      );
                    })(),

                    if (!useSingleRowActions && !isMissingLocal) ...[
                      const SizedBox(height: 16),
                      // Separate Storage Banner
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: isCloudAllowed ? const Color(0xFFEDF7ED) : const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isCloudAllowed ? const Color(0xFFC8E6C9) : const Color(0xFF90CAF9),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              isCloudAllowed ? LucideIcons.checkSquare : LucideIcons.info,
                              size: 18,
                              color: isCloudAllowed ? const Color(0xFF2E7D32) : const Color(0xFF1565C0),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                isCloudAllowed ? loc.invoiceCloudSecureDesc : loc.invoiceLocalOnlyDesc,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isCloudAllowed ? const Color(0xFF2E7D32) : const Color(0xFF1565C0),
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (useSingleRowActions && selectedFile == null && (payment.invoiceUrl == null || isExistingRemoved)) ...[
                      const SizedBox(height: 16),
                      Text(
                        storageInfo,
                        style: TextStyle(
                          fontSize: 11,
                          color: isCloudAllowed ? const Color(0xFF2E7D32) : const Color(0xFF1565C0),
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],

                    const SizedBox(height: 24),
                    // Actions
                    Row(
                      children: [
                        if (useSingleRowActions) ...[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => pickInvoiceFile(setDialogState),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: BorderSide(
                                  color: (selectedFile != null || (payment.invoiceUrl != null && !isExistingRemoved)) ? StanomerColors.successPrimary : StanomerColors.brandPrimary,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (selectedFile != null || (payment.invoiceUrl != null && !isExistingRemoved)) ...[
                                    const Icon(
                                      LucideIcons.checkSquare,
                                      size: 18,
                                      color: StanomerColors.successPrimary,
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Flexible(
                                    child: Text(
                                      (selectedFile != null || (payment.invoiceUrl != null && !isExistingRemoved))
                                          ? (loc.localeName == 'tr' ? 'Değiştir' : 'Change File')
                                          : loc.uploadInvoice,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: (selectedFile != null || (payment.invoiceUrl != null && !isExistingRemoved)) ? StanomerColors.successPrimary : StanomerColors.brandPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: Color(0xFFC8C8C8)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              loc.cancel,
                              style: const TextStyle(
                                color: StanomerColors.textSecondary,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: useSingleRowActions ? 8 : 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final amountString = amountController.text.replaceAll(',', '.');
                              final amount = double.tryParse(amountString);
                              
                              if (amount == null || amount < 0) return;
                              
                              Navigator.pop(context);
                              
                              setState(() => _uploadingPaymentId = payment.id);
                              try {
                                // Default to existing invoice URL if no new file is selected, or null if removed
                                String? invoiceUrl = isExistingRemoved ? null : payment.invoiceUrl;
                                
                                if (selectedFile != null) {
                                  final file = selectedFile!.files.first;
                                  if (ref.read(cloudUploadAllowedProvider)) {
                                    invoiceUrl = await ref.read(propertyRepositoryProvider).uploadReceipt(
                                      'invoice_${file.name}',
                                      bytes: file.bytes,
                                    );
                                  } else {
                                    final io.File localFile;
                                    if (file.path != null) {
                                      localFile = io.File(file.path!);
                                    } else {
                                      final tempDir = await getTemporaryDirectory();
                                      localFile = io.File('${tempDir.path}/${file.name}');
                                      await localFile.writeAsBytes(file.bytes!);
                                    }
                                    invoiceUrl = await ref.read(documentStorageServiceProvider).saveDocument(localFile);
                                  }
                                }

                                await ref.read(propertyRepositoryProvider).setPaymentInvoice(
                                  payment.id, 
                                  widget.property.id, 
                                  monthName, 
                                  payment.dueDate, 
                                  amount, 
                                  invoiceUrl,
                                  currency: selectedCurrency,
                                  ownerNote: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
                                );
                              } finally {
                                if (mounted) {
                                  setState(() => _uploadingPaymentId = null);
                                  ref.invalidate(rentPaymentsProvider(widget.property.id));
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: StanomerColors.brandPrimary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              loc.save,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }


  Future<void> _handleDispute(RentPayment payment, String monthName) async {
    final messenger = ScaffoldMessenger.of(context);
    final loc = AppLocalizations.of(context)!;
    final reasonController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.confirmDisputeTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ExpenseUtils.getLocalizedExpenseName(payment.title, loc), style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: loc.disputeReason,
                hintText: loc.disputeReasonHint,
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) return;
              
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              
              try {
                await ref.read(propertyRepositoryProvider).disputeRentPayment(
                  payment.id, 
                  widget.property.id, 
                  reason
                );
                
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(loc.disputeSentSuccess)),
                  );
                  ref.invalidate(rentPaymentsProvider(widget.property.id));
                }
              } catch (e) {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(loc.errorWithDetails(e.toString())), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: StanomerColors.alertPrimary,
              foregroundColor: Colors.white,
            ),
            child: Text(loc.dispute),
          ),
        ],
      ),
    );
  }


  List<ActivityLog> _getPaymentActivityLogs(RentPayment payment, List<ActivityLog> allLogs, String locale) {
    final paymentDueDateStr = payment.dueDate.toIso8601String().split('T').first;
    final paymentMonthStr = DateFormat('MMMM yyyy', locale).format(payment.dueDate).toUpperCase();
    
    final logs = allLogs.where((log) {
      // 1. Precise match on payment_id
      if (log.metadata['payment_id'] == payment.id) return true;
      
      // 2. Fallback for older logs where payment_id is missing in metadata
      if (log.metadata['payment_id'] == null) {
        final logDueDate = log.metadata['due_date'];
        final logMonth = log.metadata['month'];
        
        bool isDateMatch = false;
        if (logDueDate is String) {
          final logDueDateStr = logDueDate.split('T').first;
          isDateMatch = (logDueDateStr == paymentDueDateStr);
        } else if (logMonth is String) {
          isDateMatch = (logMonth.toUpperCase() == paymentMonthStr);
        }
        
        if (isDateMatch) {
          final logType = log.type;
          if (payment.title == 'Kira') {
            return logType == 'rent_declared' ||
                   logType == 'rent_approved' ||
                   logType == 'rent_rejected' ||
                   logType == 'rent_disputed' ||
                   logType == 'rent_auto_approved' ||
                   logType == 'payment_toggle';
          } else {
            // For utility bills, match invoice_uploaded/invoice_entered logs if the amount matches
            if (logType == 'invoice_uploaded' || logType == 'invoice_entered') {
              final logAmount = log.metadata['amount'];
              if (logAmount is num && logAmount.toDouble() == payment.amount) {
                return true;
              }
            }
          }
        }
      }
      
      return false;
    }).toList();

    // Sort chronologically (oldest first)
    logs.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    // Prepend synthesized creation log only for Rent (Kira)
    if (payment.title == 'Kira') {
      final creationLog = ActivityLog(
        id: 'creation_${payment.id}',
        propertyId: payment.propertyId,
        userId: null, // represents system
        type: 'payment_created',
        createdAt: payment.createdAt ?? payment.dueDate.subtract(const Duration(days: 15)),
        metadata: {},
      );
      return [creationLog, ...logs];
    }

    return logs;
  }

  String _formatPaymentLogDescription({
    required ActivityLog log,
    required Property property,
    required RentPayment payment,
    required AppLocalizations loc,
  }) {
    final isLandlordActor = log.userId == property.landlordId;
    final isTenantActor = log.userId == property.tenantId;
    
    final landlordName = property.landlordName ?? (loc.localeName == 'tr' ? 'Ev Sahibi' : 'Landlord');
    final tenantName = property.tenantName ?? (loc.localeName == 'tr' ? 'Kiracı' : 'Tenant');
    final actorName = isLandlordActor ? landlordName : (isTenantActor ? tenantName : (loc.localeName == 'tr' ? 'Sistem' : 'System'));

    final isTr = loc.localeName == 'tr';
    final isRu = loc.localeName == 'ru';
    final isSr = loc.localeName.startsWith('sr');

    switch (log.type) {
      case 'payment_created':
        final isRent = payment.title == 'Kira';
        if (isTr) {
          return isRent 
              ? 'Sistem borç kaydını otomatik oluşturdu'
              : 'Sistem masraf kaydını otomatik oluşturdu';
        } else if (isRu) {
          return isRent
              ? 'Система автоматически создала запись о начислении'
              : 'Система автоматически создала запись о расходах';
        } else if (isSr) {
          return isRent
              ? 'Sistem je automatski kreirao zaduženje'
              : 'Sistem je automatski kreirao stavku troška';
        } else {
          return isRent
              ? 'System automatically created the due record'
              : 'System automatically created the expense record';
        }
      case 'rent_declared':
        final isCash = log.metadata['is_cash'] == true;
        if (isTr) {
          return isCash 
              ? '$actorName ödemeyi bildirdi (Nakit)'
              : '$actorName makbuz yükleyerek ödemeyi bildirdi';
        } else if (isRu) {
          return isCash
              ? '$actorName сообщил об оплате (Наличные)'
              : '$actorName сообщил об оплате, загрузив квитанцию';
        } else if (isSr) {
          return isCash
              ? '$actorName je prijavio uplatu (Gotovina)'
              : '$actorName je učitao uplatnicu i prijavio uplatu';
        } else {
          return isCash
              ? '$actorName declared payment (Cash)'
              : '$actorName declared payment by uploading a receipt';
        }
      case 'rent_approved':
        if (isTr) {
          return '$actorName ödemeyi onayladı';
        } else if (isRu) {
          return '$actorName одобрил платеж';
        } else if (isSr) {
          return '$actorName je odobrio plaćanje';
        } else {
          return '$actorName approved payment';
        }
      case 'rent_rejected':
        if (isTr) {
          return '$actorName ödemeyi reddetti';
        } else if (isRu) {
          return '$actorName отклонил платеж';
        } else if (isSr) {
          return '$actorName je odbio plaćanje';
        } else {
          return '$actorName rejected payment';
        }
      case 'rent_disputed':
        final reason = log.metadata['reason'] ?? '';
        if (isTr) {
          return '$actorName ödemeye itiraz etti${reason.isNotEmpty ? ': $reason' : ''}';
        } else if (isRu) {
          return '$actorName оспорил платеж${reason.isNotEmpty ? ': $reason' : ''}';
        } else if (isSr) {
          return '$actorName je osporio plaćanje${reason.isNotEmpty ? ': $reason' : ''}';
        } else {
          return '$actorName objected to the payment${reason.isNotEmpty ? ': $reason' : ''}';
        }
      case 'invoice_uploaded':
        final amount = log.metadata['amount'] ?? 0.0;
        final currency = log.metadata['currency'] ?? 'RSD';
        final formattedAmount = CurrencyUtils.formatAmount(amount is num ? amount.toDouble() : 0.0, currency.toString());
        if (isTr) {
          return '$actorName fatura yükledi ($formattedAmount)';
        } else if (isRu) {
          return '$actorName загрузил счет ($formattedAmount)';
        } else if (isSr) {
          return '$actorName je učitao račun ($formattedAmount)';
        } else {
          return '$actorName uploaded a bill ($formattedAmount)';
        }
      case 'invoice_entered':
        final amount = log.metadata['amount'] ?? 0.0;
        final currency = log.metadata['currency'] ?? 'RSD';
        final formattedAmount = CurrencyUtils.formatAmount(amount is num ? amount.toDouble() : 0.0, currency.toString());
        if (isTr) {
          return '$actorName masraf detayı girdi ($formattedAmount)';
        } else if (isRu) {
          return '$actorName ввел данные расхода ($formattedAmount)';
        } else if (isSr) {
          return '$actorName je uneo detalje troška ($formattedAmount)';
        } else {
          return '$actorName entered bill details ($formattedAmount)';
        }
      case 'payment_toggle':
        final paid = log.metadata['paid'] == true;
        if (isTr) {
          return '$actorName ödemeyi ${paid ? 'Ödendi' : 'Bekliyor'} olarak işaretledi';
        } else if (isRu) {
          return '$actorName отметил платеж как ${paid ? 'Оплачен' : 'В ожидании'}';
        } else if (isSr) {
          return '$actorName je označio plaćanje kao ${paid ? 'Plaćeno' : 'Na čekanju'}';
        } else {
          return '$actorName marked payment as ${paid ? 'Paid' : 'Pending'}';
        }
      case 'rent_auto_approved':
        if (isTr) {
          return 'Ödeme sistem tarafından otomatik olarak onaylandı';
        } else if (isRu) {
          return 'Платеж был автоматически одобрен системой';
        } else if (isSr) {
          return 'Plaćanje je automatski odobreno od strane sistema';
        } else {
          return 'Payment was automatically approved by the system';
        }
      default:
        return log.type;
    }
  }


  Widget _buildPaymentCard({
    required BuildContext context,
    required RentPayment payment,
    required Property property,
    required bool isLandlord,
    required bool isTenant,
    required Color roleColor,

    required AppLocalizations loc,
    required IconData Function(String) iconForTitle,
    required Color Function(String) colorForTitle,
    required List<ActivityLog> allLogs,
  }) {
    final status = payment.status;
    final isPaid = status == 'paid';
    final isDeclared = status == 'declared';
    final isPending = status == 'pending';
    final isDisputed = status == 'disputed';
    // An expense row is "awaiting invoice" when landlord hasn't set the amount yet
    final isOwnerExpense = payment.receiverType == 'owner' && payment.title != 'Kira';
    final isAwaitingInvoice = isOwnerExpense && payment.amount == 0 && isPending;
    final isCash = payment.receiptUrl == 'CASH';
    final monthName = DateFormat('MMMM yyyy', loc.localeName).format(payment.dueDate);
    final catColor = colorForTitle(payment.title);
    final catIcon  = iconForTitle(payment.title);

    Color borderColor = StanomerColors.borderDefault;
    Color bgColor = Theme.of(context).cardColor;
    
    if (isDeclared) {
      borderColor = Colors.amber.shade600;
      bgColor = Colors.amber.withValues(alpha: 0.04);
    }
    if (isDisputed) {
      borderColor = StanomerColors.alertPrimary.withValues(alpha: 0.4);
      bgColor = StanomerColors.alertPrimary.withValues(alpha: 0.02);
    }
    if (isAwaitingInvoice && isLandlord) borderColor = StanomerColors.brandPrimary.withValues(alpha: 0.4);

    final isExpanded = _expandedPaymentIds.contains(payment.id);
    final paymentLogs = _getPaymentActivityLogs(payment, allLogs, loc.localeName);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: (isDeclared || isDisputed || (isAwaitingInvoice && isLandlord)) ? 1.5 : 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Collapsed Header Row (Single Line)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedPaymentIds.remove(payment.id);
                } else {
                  _expandedPaymentIds.add(payment.id);
                }
              });
            },
            child: Row(
              children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(color: catColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                  child: Icon(catIcon, color: catColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isAwaitingInvoice)
                        Text(
                          loc.awaitingInvoice,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: StanomerColors.brandPrimary.withValues(alpha: 0.8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      else
                        Text(
                          CurrencyUtils.formatAmount(payment.amount, payment.currency),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: StanomerColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 2),
                      Text(
                        ExpenseUtils.getLocalizedExpenseName(payment.title, loc),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: StanomerColors.textTertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Status badge
                if (isAwaitingInvoice)
                  _StatusBadge(label: isTenant ? loc.noInvoice : (loc.localeName == 'tr' ? 'Tutar Girilmedi' : 'No Amount'), color: StanomerColors.brandPrimary)
                else if (isPaid)
                  _StatusBadge(label: loc.paidHeader, color: Colors.green)
                else if (isDeclared)
                  _StatusBadge(label: isLandlord ? (loc.localeName == 'tr' ? 'Onay Bekliyor' : 'Awaiting Approval') : loc.awaitingHeader, color: Colors.orange)
                else if (isDisputed)
                  _StatusBadge(label: loc.disputedHeader, color: StanomerColors.alertPrimary)
                else if (isPending)
                  _StatusBadge(label: loc.localeName == 'tr' ? 'Bekliyor' : 'Pending', color: Colors.grey),
                const SizedBox(width: 8),
                Icon(
                  isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                  size: 20,
                  color: StanomerColors.textTertiary,
                ),
              ],
            ),
          ),
          
          // Expanded Content Area
          if (isExpanded) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            // Transaction History & Document Preview Section
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.localeName == 'tr' ? 'İşlem Geçmişi' : 'Transaction History',
                        style: const TextStyle(fontSize: 11, color: StanomerColors.textTertiary, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      if (paymentLogs.isEmpty)
                        Text(
                          loc.localeName == 'tr' 
                              ? 'Henüz bir işlem yok' 
                              : (loc.localeName == 'ru'
                                  ? 'История операций пуста'
                                  : (loc.localeName.startsWith('sr')
                                      ? 'Još nema transakcija'
                                      : 'No transactions yet')),
                          style: const TextStyle(fontSize: 12, color: StanomerColors.textSecondary, fontStyle: FontStyle.italic),
                        )
                      else
                        ...paymentLogs.map((log) {
                          final dateStr = DateFormat('dd.MM.yyyy, HH:mm').format(log.createdAt.toLocal());
                          final desc = _formatPaymentLogDescription(log: log, property: property, payment: payment, loc: loc);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 5),
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: StanomerColors.textTertiary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        desc,
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: StanomerColors.textSecondary),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        dateStr,
                                        style: const TextStyle(fontSize: 10, color: StanomerColors.textTertiary),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
                // Documents buttons (if any documents exist)
                if ((payment.receiptUrl != null && !isCash) || payment.invoiceUrl != null) ...[
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        loc.localeName == 'tr' ? 'Dokümanlar' : 'Documents',
                        style: const TextStyle(fontSize: 11, color: StanomerColors.textTertiary, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (payment.invoiceUrl != null) ...[
                            GestureDetector(
                              onTap: () => _openFileOrUrl(context, payment.invoiceUrl!, mounted: mounted),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: StanomerColors.brandPrimary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(LucideIcons.fileText, size: 12, color: StanomerColors.brandPrimary),
                                    const SizedBox(width: 4),
                                    Text(
                                      loc.viewInvoice,
                                      style: const TextStyle(fontSize: 11, color: StanomerColors.brandPrimary, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (payment.receiptUrl != null && !isCash) const SizedBox(width: 6),
                          ],
                          if (payment.receiptUrl != null && !isCash)
                            GestureDetector(
                              onTap: () => _openFileOrUrl(context, payment.receiptUrl!, mounted: mounted),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(LucideIcons.fileText, size: 12, color: Colors.green),
                                    const SizedBox(width: 4),
                                    Text(
                                      loc.viewReceipt,
                                      style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ],
            ),
            
            // Info Banners (Paid in Cash, Dispute Reason, Explanation/Note)
            if (isCash || (isDisputed && payment.disputeReason != null) || payment.ownerNote != null) ...[
              const SizedBox(height: 12),
              if (isCash)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.hand, size: 14, color: Colors.amber.shade800),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          loc.paidInCash,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.amber.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
              if (isDisputed && payment.disputeReason != null) ...[
                if (isCash) const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: StanomerColors.alertPrimary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: StanomerColors.alertPrimary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(LucideIcons.alertTriangle, size: 14, color: StanomerColors.alertPrimary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${loc.disputeReason}: ${payment.disputeReason}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: StanomerColors.alertPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (payment.ownerNote != null) ...[
                if (isCash || isDisputed) const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: StanomerColors.textSecondary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: StanomerColors.borderDefault),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(LucideIcons.info, size: 14, color: StanomerColors.textSecondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${loc.explanationOptional.split(' (').first}: ${payment.ownerNote}',
                          style: const TextStyle(fontSize: 12, color: StanomerColors.textSecondary, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
            
            // Actions Section
            if (isLandlord || (isTenant && isPending && !isAwaitingInvoice && !isDisputed)) ...[
              const SizedBox(height: 16),
              if (isLandlord) ...[
                if (isDeclared)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final confirmed = await _showConfirmDialog(
                              title: loc.confirmApprovePaymentTitle,
                              message: loc.confirmApprovePaymentMessage,
                            );
                            if (confirmed) {
                              await ref.read(propertyRepositoryProvider).approveRentPayment(payment.id, property.id, monthName, payment.dueDate);
                              ref.invalidate(rentPaymentsProvider(property.id));
                            }
                          },
                          icon: const Icon(LucideIcons.checkCircle, size: 16),
                          label: Text(loc.approve),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final confirmed = await _showConfirmDialog(
                              title: loc.confirmRejectPaymentTitle,
                              message: loc.confirmRejectPaymentMessage,
                            );
                            if (confirmed) {
                              await ref.read(propertyRepositoryProvider).rejectRentPayment(payment.id, property.id, monthName, payment.dueDate);
                              ref.invalidate(rentPaymentsProvider(property.id));
                            }
                          },
                          icon: const Icon(LucideIcons.xCircle, size: 16),
                          label: Text(loc.reject),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  )
                else if ((isOwnerExpense || (payment.title == 'Kira' && isDisputed)) && (isPending || isDisputed))
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _handleInvoiceUpload(payment, monthName),
                      icon: Icon(isDisputed ? LucideIcons.edit3 : LucideIcons.filePlus, size: 16),
                      label: Text(isDisputed ? loc.updateLabel : (isAwaitingInvoice ? loc.enterBill : loc.updateLabel)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDisputed ? StanomerColors.alertPrimary : StanomerColors.brandPrimary,
                        side: BorderSide(color: isDisputed ? StanomerColors.alertPrimary : StanomerColors.brandPrimary),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                else if (!isOwnerExpense && !isDeclared && isPending)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final titleStr = loc.localeName == 'tr' 
                            ? 'Ödendi Olarak İşaretle' 
                            : (loc.localeName == 'ru'
                                ? 'Отметить как оплачено'
                                : (loc.localeName.startsWith('sr')
                                    ? 'Označi kao plaćeno'
                                    : 'Mark as Paid'));
                        
                        final messageStr = loc.localeName == 'tr'
                            ? 'Kira ödemesini doğrudan almış olarak ödendi olarak işaretlemek istiyor musunuz?'
                            : (loc.localeName == 'ru'
                                ? 'Вы хотите отметить этот платеж за аренду как оплаченный?'
                                : (loc.localeName.startsWith('sr')
                                    ? 'Da li želite da označite ovo plaćanje zakupnine kao plaćeno?'
                                    : 'Do you want to mark this rent payment as paid?'));

                        final confirmed = await _showConfirmDialog(
                          title: titleStr,
                          message: messageStr,
                        );
                        if (confirmed) {
                          await ref.read(propertyRepositoryProvider).approveRentPayment(payment.id, property.id, monthName, payment.dueDate);
                          ref.invalidate(rentPaymentsProvider(property.id));
                        }
                      },
                      icon: const Icon(LucideIcons.checkCircle, size: 16),
                      label: Text(
                        loc.localeName == 'tr' 
                            ? 'Ödendi Olarak İşaretle' 
                            : (loc.localeName == 'ru'
                                ? 'Отметить как оплачено'
                                : (loc.localeName.startsWith('sr')
                                    ? 'Označi kao plaćeno'
                                    : 'Mark as Paid')),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ] else if (isTenant && isPending && !isAwaitingInvoice && !isDisputed) ...[
                if (_uploadingPaymentId == payment.id)
                  const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)))
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isPickingFile ? null : () {
                        showModalBottomSheet(
                          context: context,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          builder: (ctx) => SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 20),
                                    child: Text(loc.takeAction, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                  ),
                                  ListTile(
                                    leading: Icon(LucideIcons.fileText, color: roleColor),
                                    title: Text(loc.uploadReceipt),
                                    onTap: () async {
                                      Navigator.pop(ctx);
                                      setState(() => _isPickingFile = true);
                                      try {
                                        final result = await _pickReceiptFile();
                                        if (!mounted) return;
                                        if (result != null) await _handlePaymentDeclaration(payment, monthName, result);
                                      } finally {
                                        if (mounted) setState(() => _isPickingFile = false);
                                      }
                                    },
                                  ),
                                  ListTile(
                                    leading: Icon(LucideIcons.hand, color: roleColor),
                                    title: Text(loc.paidInCash),
                                    onTap: () async {
                                      Navigator.pop(ctx);
                                      await _handlePaymentDeclaration(payment, monthName, null, isCash: true);
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(LucideIcons.alertCircle, color: StanomerColors.alertPrimary),
                                    title: Text(loc.dispute),
                                    onTap: () {
                                      Navigator.pop(ctx);
                                      _handleDispute(payment, monthName);
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(LucideIcons.arrowRightCircle, size: 16),
                      label: Text(loc.takeAction),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: roleColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ],
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isLandlord = user?.id == widget.property.landlordId;
    final isTenant = user?.id == widget.property.tenantId;
    final roleColor = StanomerColors.getRoleColor(isLandlord ? 'landlord' : (isTenant ? 'tenant' : null));

    final property = widget.property;
    final loc = AppLocalizations.of(context)!;
    final paymentsAsync = ref.watch(rentPaymentsProvider(property.id));
    final activeContractAsync = ref.watch(activeContractProvider(property.id));
    final activitiesAsync = ref.watch(activityLogsProvider(property.id));


    return activeContractAsync.when(
      data: (activeContract) {
        return paymentsAsync.when(
          data: (payments) {
            if (payments.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.calendarX, size: 48, color: StanomerColors.textTertiary),
                    const SizedBox(height: 16),
                    Text(
                      loc.noFinancialRecords,
                      style: const TextStyle(color: StanomerColors.textSecondary, fontWeight: FontWeight.w600),
                    ),
                    if (activeContract == null && isLandlord)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(32, 8, 32, 0),
                        child: Text(
                          loc.noContractsMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12, color: StanomerColors.textTertiary),
                        ),
                      ),
                  ],
                ),
              );
            }

            // ── Summary counters ──────────────────────────────────────
            final pendingCount  = payments.where((p) => p.status == 'pending' && p.amount > 0).length;
            final awaitingCount = payments.where((p) => p.status == 'declared').length;
            final paidCount     = payments.where((p) => p.status == 'paid').length;

            // ── Group payments by month ───────────────────────────────
            final Map<String, List<RentPayment>> grouped = {};
            for (final p in payments) {
              final key = DateFormat('MMMM yyyy', loc.localeName).format(p.dueDate).toUpperCase();
              grouped.putIfAbsent(key, () => []).add(p);
            }

            // ── Helper: icon per category ─────────────────────────────
            IconData _iconForTitle(String title) {
              final t = title.toLowerCase();
              if (t == 'kira' || t == 'rent') return LucideIcons.home;
              if (t.contains('internet') || t.contains('tv')) return LucideIcons.wifi;
              if (t.contains('elektr') || t.contains('electr')) return LucideIcons.zap;
              if (t.contains('su') || t.contains('water')) return LucideIcons.droplets;
              if (t.contains('info') || t.contains('aidat') || t.contains('maintenance')) return LucideIcons.building;
              return LucideIcons.receipt;
            }

            Color _colorForTitle(String title) {
              final t = title.toLowerCase();
              if (t == 'kira' || t == 'rent') return StanomerColors.brandPrimary;
              if (t.contains('internet') || t.contains('tv')) return Colors.indigo;
              if (t.contains('elektr') || t.contains('electr')) return Colors.amber.shade700;
              if (t.contains('su') || t.contains('water')) return Colors.blue;
              if (t.contains('info') || t.contains('aidat') || t.contains('maintenance')) return Colors.brown.shade400;
              return StanomerColors.textSecondary;
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                // ── Summary bar ───────────────────────────────────────
                Row(
                  children: [
                    _SummaryChip(
                      label: loc.pendingHeader,
                      subLabel: isTenant 
                        ? loc.waitingForYourPayment
                        : loc.waitingForTenantPayment,
                      count: pendingCount,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    _SummaryChip(
                      label: loc.awaitingHeader,
                      subLabel: isTenant 
                        ? loc.waitingForOwnerApproval
                        : loc.waitingForYourApproval,
                      count: awaitingCount,
                      color: Colors.amber.shade700,
                    ),
                    const SizedBox(width: 8),
                    _SummaryChip(
                      label: loc.paidHeader,
                      subLabel: loc.processCompleted,
                      count: paidCount,
                      color: Colors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Month groups (Accordion) ──────────────────────────
                for (final monthKey in grouped.keys) ...[
                  Builder(
                    builder: (context) {
                      final monthPayments = grouped[monthKey]!;
                      
                      // Calculate counts
                      int pendingCountM = 0;
                      int awaitingCountM = 0;
                      int paidCountM = 0;
                      int totalPayableCount = 0;
                      int completedCount = 0;
                      Map<String, double> sentAmounts = {};

                      for (final p in monthPayments) {
                        final isAwaitingInv = p.receiverType == 'owner' && p.title != 'Kira' && p.amount == 0;
                        final isIncluded = p.receiverType == 'owner' && p.title != 'Kira' && p.amount == 0 && !isAwaitingInv; // Based on prior logic if needed, but practically we dropped included. Wait, included was receiverType == 'included'.
                        // Let's rely on standard status
                        if (p.status == 'pending') pendingCountM++;
                        if (p.status == 'declared') awaitingCountM++;
                        if (p.status == 'paid') paidCountM++;

                        // Payable items (excluding awaiting invoice if amount is 0, wait, it IS an item)
                        if (!isIncluded) {
                           totalPayableCount++;
                           if (p.status == 'declared' || p.status == 'paid') {
                              completedCount++;
                              sentAmounts[p.currency] = (sentAmounts[p.currency] ?? 0.0) + p.amount;
                           }
                        }
                      }

                      final isComplete = completedCount == totalPayableCount && totalPayableCount > 0;
                      final headerColor = isComplete ? Colors.blue.shade600 : Colors.amber.shade700;
                      final sentText = sentAmounts.isEmpty ? '0,00' : sentAmounts.entries.map((e) => CurrencyUtils.formatAmount(e.value, e.key)).join(' + ');

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isComplete ? Colors.blue.shade200 : Colors.amber.shade300, width: 1.5),
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            initiallyExpanded: true,
                            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      monthKey,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: StanomerColors.textPrimary, letterSpacing: 0.5),
                                    ),
                                    // Status badges for the month
                                    Row(
                                      children: [
                                        if (pendingCountM > 0) _MiniBadge(count: pendingCountM, color: Colors.grey),
                                        if (awaitingCountM > 0) _MiniBadge(count: awaitingCountM, color: Colors.amber.shade700),
                                        if (paidCountM > 0) _MiniBadge(count: paidCountM, color: Colors.green),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Progress Info
                                Row(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: totalPayableCount == 0 ? 0 : completedCount / totalPayableCount,
                                          backgroundColor: headerColor.withValues(alpha: 0.15),
                                          valueColor: AlwaysStoppedAnimation<Color>(headerColor),
                                          minHeight: 6,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      loc.progressSummary(completedCount, totalPayableCount, sentAmounts.length),
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: headerColor),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            children: monthPayments.map((payment) {
                              final allLogs = activitiesAsync.value ?? [];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _buildPaymentCard(
                                  context: context,
                                  payment: payment,
                                  property: property,
                                  isLandlord: isLandlord,
                                  isTenant: isTenant,
                                  roleColor: roleColor,
                                  loc: loc,
                                  iconForTitle: _iconForTitle,
                                  colorForTitle: _colorForTitle,
                                  allLogs: allLogs,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    }
                  ),
                ],
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('Error: $e')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(loc.errorWithDetails(e.toString()))),
    );
  }
}

class _SettingsTab extends ConsumerStatefulWidget {
  final Property property;
  final TabController tabController;
  final ValueNotifier<String> settingsSectionNotifier;
  const _SettingsTab({super.key, required this.property, required this.tabController, required this.settingsSectionNotifier});

  @override
  ConsumerState<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends ConsumerState<_SettingsTab> {
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
    widget.settingsSectionNotifier.addListener(_onSectionChanged);
    _nameController = TextEditingController(text: widget.property.name);
    _addressController = TextEditingController(text: widget.property.address);
    _rentController = TextEditingController(text: widget.property.defaultMonthlyRent.toStringAsFixed(2));
    _depositController = TextEditingController(text: widget.property.defaultDepositAmount?.toStringAsFixed(2) ?? '');
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
  void didUpdateWidget(_SettingsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.property != oldWidget.property) {
      _nameController.text = widget.property.name;
      _addressController.text = widget.property.address;
      _rentController.text = widget.property.defaultMonthlyRent.toStringAsFixed(2);
      _depositController.text = widget.property.defaultDepositAmount?.toStringAsFixed(2) ?? '';
      _dueDayController.text = widget.property.defaultDueDay.toString();
      _selectedCurrency = widget.property.currency;
      _depositCurrency = widget.property.defaultDepositCurrency;
      _expenses = List.from(widget.property.expensesTemplate.where((e) => e.name != 'Porez (Tax)'));
    }
  }

  @override
  void dispose() {
    widget.settingsSectionNotifier.removeListener(_onSectionChanged);
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
    final isLandlord = widget.property.landlordId == user?.id;

    return Column(
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
              selected: {widget.settingsSectionNotifier.value},
              onSelectionChanged: (val) => widget.settingsSectionNotifier.value = val.first,
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: StanomerColors.brandPrimary,
                selectedForegroundColor: Colors.white,
              ),
            ),
          ),

        // ── Panel ──────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: (isLandlord && widget.settingsSectionNotifier.value == 'property')
                ? _buildPropertyPanel(loc)
                : _buildContractPanel(loc, isLandlord),
          ),
        ),
      ],
    );
  }

  Widget _buildContractPanel(AppLocalizations loc, bool isLandlord) {
    final activeContractAsync = ref.watch(activeContractProvider(widget.property.id));
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
          _contractRentController.text = contract.monthlyRent.toStringAsFixed(2);
          _contractDepositController.text = contract.depositAmount?.toStringAsFixed(2) ?? '';
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
                color: StanomerColors.brandPrimary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: StanomerColors.brandPrimary.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.info, size: 16, color: StanomerColors.brandPrimary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      loc.contractTermsInfo,
                      style: const TextStyle(fontSize: 12, color: StanomerColors.brandPrimary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Kira + Para birimi
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _contractRentController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: loc.monthlyRent),
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
            const SizedBox(height: 16),
            const SizedBox(height: 24),
            // Masraflar
            _buildContractExpensesSection(loc),
            const SizedBox(height: 24),
            // Proposal info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.alertTriangle, size: 16, color: Colors.amber),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      loc.proposeChangesInfo(isLandlord ? loc.tenant : loc.landlord),
                      style: const TextStyle(fontSize: 12, color: Colors.amber),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(LucideIcons.send, size: 18),
              onPressed: _isContractLoading ? null : () async {
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
                    content: Text(loc.proposeChangesInfo(isLandlord ? loc.tenant : loc.landlord)),
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
                    SnackBar(content: Text(loc.errorWithDetails(e.toString())), backgroundColor: StanomerColors.alertPrimary),
                  );
                } finally {
                  if (mounted) setState(() => _isContractLoading = false);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700),
              label: _isContractLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(loc.proposeChanges),
            ),
            const SizedBox(height: 48),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(loc.errorWithDetails(e.toString()))),
    );
  }

  Widget _buildContractExpensesSection(AppLocalizations loc) {
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
                      activeColor: StanomerColors.brandPrimary,
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

  Widget _buildPropertyPanel(AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Info banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: StanomerColors.brandPrimarySurface.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: StanomerColors.brandPrimary.withValues(alpha: 0.15)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(LucideIcons.info, size: 16, color: StanomerColors.brandPrimary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  loc.defaultLeaseTermsSubtitle,
                  style: const TextStyle(fontSize: 12, color: StanomerColors.brandPrimary),
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
        _buildExpensesSection(loc),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isLoading ? null : _update,
          child: _isLoading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(loc.saveChanges),
        ),
        const SizedBox(height: 48),
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
                      children: [
                        Text(expense.name, style: const TextStyle(fontWeight: FontWeight.w600)),
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

class _ProposalReviewCard extends ConsumerStatefulWidget {
  final Contract contract;
  final bool isTenant;
  final bool isLandlord;

  final String propertyId;
  final String landlordName;
  final String tenantName;
  final String landlordEmail;
  final String tenantEmail;

  const _ProposalReviewCard({
    required this.contract,
    required this.isTenant,
    required this.isLandlord,

    required this.propertyId,
    required this.landlordName,
    required this.tenantName,
    required this.landlordEmail,
    required this.tenantEmail,
  });

  @override
  ConsumerState<_ProposalReviewCard> createState() => _ProposalReviewCardState();
}

class _ProposalReviewCardState extends ConsumerState<_ProposalReviewCard> {
  bool _loading = false;

  String _formatExpenses(dynamic expenses, AppLocalizations loc) {
    if (expenses == null) return '-';
    List expList;
    if (expenses is List) {
      expList = expenses;
    } else {
      return '-';
    }
    if (expList.isEmpty) return '-';

    return expList.map((e) {
      if (e is Map) {
        final name = e['name'] as String? ?? '-';
        final receiver = e['receiver'] as String?;
        final localizedName = ExpenseUtils.getLocalizedExpenseName(name, loc);
        final recText = receiver == 'owner' ? loc.tenantPaysLandlord
                      : receiver == 'utility' ? loc.tenantPaysUtility
                      : loc.includedInRent;
        return '$localizedName ($recText)';
      } else {
        // e is ExpenseItem type
        final dynamic item = e;
        try {
          final localizedName = ExpenseUtils.getLocalizedExpenseName(item.name, loc);
          final recText = item.receiver.toString().contains('owner') ? loc.tenantPaysLandlord
                        : item.receiver.toString().contains('utility') ? loc.tenantPaysUtility
                        : loc.includedInRent;
          return '$localizedName ($recText)';
        } catch (_) {
          return '';
        }
      }
    }).join(', ');
  }

  Future<void> _accept() async {
    final loc = AppLocalizations.of(context)!;
    setState(() => _loading = true);
    try {
      await ref.read(propertyRepositoryProvider).acceptProposedChanges(widget.contract.id);
      ref.invalidate(activeContractProvider(widget.propertyId));
      ref.invalidate(contractProposalProvider(widget.contract.id));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.changesAccepted)),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.errorWithDetails(e.toString())), backgroundColor: StanomerColors.alertPrimary),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _decline() async {
    final loc = AppLocalizations.of(context)!;
    setState(() => _loading = true);
    try {
      await ref.read(propertyRepositoryProvider).declineProposedChanges(widget.contract.id);
      ref.invalidate(activeContractProvider(widget.propertyId));
      ref.invalidate(contractProposalProvider(widget.contract.id));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.changesDeclined)),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.errorWithDetails(e.toString())), backgroundColor: StanomerColors.alertPrimary),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);
    final proposalAsync = ref.watch(contractProposalProvider(widget.contract.id));

    return Container(
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3), width: 1.5),
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
                  loc.contractChangeProposal,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.orange),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          proposalAsync.when(
            data: (proposalData) {
              if (proposalData == null) return const SizedBox.shrink();
              final proposal = proposalData['changes'] as Map<String, dynamic>? ?? {};
              final feedback = proposalData['tenant_feedback'] as String?;
              final isNegotiating = widget.contract.status == ContractStatus.negotiating;
              final proposedBy = proposalData['proposed_by'] as String?;
              
              // Robust check for who proposed the changes:
              bool isMyProposal;
              if (isNegotiating) {
                // In early negotiation, the tenant is always the proposer.
                // If I am the landlord, it's NOT my proposal.
                isMyProposal = widget.isLandlord ? false : true;
              } else {
                // In active contract revisions, we rely on the proposed_by ID.
                isMyProposal = proposedBy == user?.id;
              }

              if (isMyProposal) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.awaitingApprovalInfo,
                      style: const TextStyle(fontSize: 13, color: StanomerColors.textSecondary, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    if (isNegotiating && feedback != null) ...[
                      Text(
                        loc.yourMessage,
                        style: const TextStyle(fontSize: 12, color: StanomerColors.textTertiary, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        feedback,
                        style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 16),
                    ],
                    _buildProposalRow(loc.monthlyRent,
                      CurrencyUtils.formatAmount(widget.contract.monthlyRent, widget.contract.currency),
                      proposal['monthly_rent'] != null ? CurrencyUtils.formatAmount((proposal['monthly_rent'] as num).toDouble(), proposal['currency'] ?? widget.contract.currency) : null),
                    _buildProposalRow(loc.depositAmount,
                      widget.contract.depositAmount != null ? CurrencyUtils.formatAmount(widget.contract.depositAmount!, widget.contract.depositCurrency) : '-',
                      proposal['deposit_amount'] != null ? CurrencyUtils.formatAmount((proposal['deposit_amount'] as num).toDouble(), proposal['deposit_currency'] ?? proposal['currency'] ?? widget.contract.depositCurrency) : null),
                    _buildProposalRow(loc.dueDay,
                      '${widget.contract.dueDay}',
                      proposal['due_day'] != null ? '${proposal['due_day']}' : null),
                    _buildProposalRow(loc.expenseConfiguration,
                      _formatExpenses(widget.contract.expensesConfig, loc),
                      proposal['expenses_config'] != null ? _formatExpenses(proposal['expenses_config'], loc) : null),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _loading ? null : _decline, // Decline effectively cancels it
                      icon: const Icon(LucideIcons.x, size: 16),
                      label: Text(loc.cancelProposal),
                      style: TextButton.styleFrom(foregroundColor: StanomerColors.alertPrimary),
                    ),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Builder(builder: (context) {
                    String proposerName = '';
                    String proposerEmail = '';
                    if (proposedBy == widget.contract.landlordId) {
                      proposerName = widget.landlordName;
                      proposerEmail = widget.landlordEmail;
                    } else if (proposedBy == widget.contract.tenantId) {
                      proposerName = widget.tenantName;
                      proposerEmail = widget.tenantEmail;
                    }
                    
                    final emailText = proposerEmail.isNotEmpty ? ' ($proposerEmail)' : '';
                    return Text(
                      loc.proposesChanges('$proposerName$emailText'),
                      style: const TextStyle(fontSize: 13, color: StanomerColors.textSecondary, fontWeight: FontWeight.w600),
                    );
                  }),
                  const SizedBox(height: 12),
                  if (isNegotiating && feedback != null) ...[
                    Text(
                      loc.revisionRequestLabel,
                      style: const TextStyle(fontSize: 12, color: StanomerColors.textTertiary, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      feedback,
                      style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _buildProposalRow(loc.monthlyRent,
                    CurrencyUtils.formatAmount(widget.contract.monthlyRent, widget.contract.currency),
                    proposal['monthly_rent'] != null ? CurrencyUtils.formatAmount((proposal['monthly_rent'] as num).toDouble(), proposal['currency'] ?? widget.contract.currency) : null),
                  _buildProposalRow(loc.depositAmount,
                    widget.contract.depositAmount != null ? CurrencyUtils.formatAmount(widget.contract.depositAmount!, widget.contract.currency) : '-',
                    proposal['deposit_amount'] != null ? CurrencyUtils.formatAmount((proposal['deposit_amount'] as num).toDouble(), proposal['currency'] ?? widget.contract.currency) : null),
                  _buildProposalRow(loc.dueDay,
                    '${widget.contract.dueDay}',
                    proposal['due_day'] != null ? '${proposal['due_day']}' : null),
                  _buildProposalRow(loc.expenseConfiguration,
                    _formatExpenses(widget.contract.expensesConfig, loc),
                    proposal['expenses_config'] != null ? _formatExpenses(proposal['expenses_config'], loc) : null),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _loading ? null : _decline,
                          icon: const Icon(LucideIcons.x, size: 16),
                          label: Text(loc.decline),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: StanomerColors.alertPrimary,
                            side: BorderSide(color: StanomerColors.alertPrimary.withValues(alpha: 0.5)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _loading ? null : _accept,
                          icon: _loading
                              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(LucideIcons.check, size: 16),
                          label: Text(loc.accept),
                          style: ElevatedButton.styleFrom(backgroundColor: StanomerColors.successPrimary),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
            loading: () => const Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))),
            error: (e, _) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildProposalRow(String label, String current, String? proposed) {
    if (proposed == null || proposed == current) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(fontSize: 12, color: StanomerColors.textTertiary, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(current, style: const TextStyle(fontSize: 13, decoration: TextDecoration.lineThrough, color: StanomerColors.textTertiary)),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Icon(LucideIcons.chevronRight, size: 14, color: Colors.orange)),
                Text(proposed, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.orange)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsReadRow extends StatelessWidget {
  final String label;
  final String value;
  const _SettingsReadRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(fontSize: 12, color: StanomerColors.textTertiary, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _ActivityTab extends ConsumerWidget {
  final Property property;
  const _ActivityTab({required this.property});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final activitiesAsync = ref.watch(activityLogsProvider(property.id));

    return activitiesAsync.when(
      data: (activities) {
        if (activities.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.history, size: 48, color: StanomerColors.textTertiary),
                const SizedBox(height: 16),
                Text(
                  loc.noActivityLogs,
                  style: const TextStyle(color: StanomerColors.textSecondary),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: activities.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final log = activities[index];
            final date = DateFormat('dd MMM, HH:mm', loc.localeName).format(log.createdAt);
            
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: StanomerColors.brandPrimary.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (index != activities.length - 1)
                      Container(
                        width: 2,
                        height: 40,
                        color: StanomerColors.borderPrimary,
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getLogDescription(log, context, loc.localeName),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        date,
                        style: const TextStyle(fontSize: 12, color: StanomerColors.textTertiary),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }

  String _getLogDescription(ActivityLog log, BuildContext context, String locale) {
    final loc = AppLocalizations.of(context)!;
    
    // Attempt to format date from metadata, fallback to 'month' string
    String month;
    if (log.metadata['due_date'] != null) {
      try {
        final date = DateTime.parse(log.metadata['due_date']);
        month = DateFormat('MMMM yyyy', locale).format(date);
      } catch (_) {
        month = log.metadata['month'] ?? '';
      }
    } else {
      month = log.metadata['month'] ?? '';
    }
    
    switch (log.type) {
      case 'rent_disputed':
        final reason = log.metadata['reason'] ?? '';
        return loc.logRentDisputed(month, reason);
      case 'invoice_uploaded':
        final amount = log.metadata['amount'] ?? 0;
        final currency = log.metadata['currency'] ?? 'RSD';
        return locale == 'tr' 
          ? '$month için fatura yüklendi: $amount $currency' 
          : 'Invoice uploaded for $month: $amount $currency';
      case 'invoice_entered':
        final amount = log.metadata['amount'] ?? 0;
        final currency = log.metadata['currency'] ?? 'RSD';
        return locale == 'tr' 
          ? '$month için masraf detayı girildi: $amount $currency' 
          : 'Expense details entered for $month: $amount $currency';
      case 'rent_declared':
        return loc.logRentDeclared(month);
      case 'rent_approved':
        return loc.logRentApproved(month);
      case 'rent_rejected':
        return loc.logRentRejected(month);
      case 'payment_toggle':
        final paid = log.metadata['paid'] == true;
        if (paid) {
          return loc.logMarkedAsPaid(month);
        } else {
          return loc.logMarkedAsPending(month);
        }
      case 'rent_auto_approved':
        return loc.logAutoApproved(month);
      case 'maintenance_created':
        return loc.logMaintenanceCreated(log.metadata['title'] ?? '');
      case 'maintenance_status_updated':
        final status = log.metadata['new_status'] ?? '';
        return loc.logMaintenanceStatusUpdated(_getMaintenanceStatusLabel(status, loc));
      case 'maintenance_message_added':
        return loc.logMaintenanceMessageAdded;
      case 'maintenance_reopened':
        return loc.logMaintenanceReopened;
      default:
        return log.type;
    }
  }

  String _getMaintenanceStatusLabel(String status, AppLocalizations loc) {
    switch (status) {
      case 'open':
        return loc.statusActive;
      case 'investigating':
        return loc.statusInvestigating;
      case 'resolved':
        return loc.statusResolved;
      default:
        return status;
    }
  }
}

class _NoContractsEmptyState extends StatelessWidget {
  final VoidCallback onInvite;

  const _NoContractsEmptyState({required this.onInvite});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: StanomerColors.brandPrimarySurface.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.fileSignature,
              size: 40,
              color: StanomerColors.brandPrimary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            loc.noContractsTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: StanomerColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            loc.noContractsMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: StanomerColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: onInvite,
            icon: const Icon(LucideIcons.userPlus, size: 18),
            label: Text(loc.inviteFirstTenant),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


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
  final Color? iconColor;

  const _ModernNavRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (iconColor ?? StanomerColors.brandPrimary).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: iconColor ?? StanomerColors.brandPrimary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: StanomerColors.textPrimary)),
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

// ── Status Badge ──────────────────────────────────────────────────────────────
class _TerminationBanner extends ConsumerStatefulWidget {
  final Contract contract;
  final User? currentUser;
  final String propertyId;

  const _TerminationBanner({
    required this.contract,
    required this.currentUser,
    required this.propertyId,
  });

  @override
  ConsumerState<_TerminationBanner> createState() => _TerminationBannerState();
}

class _TerminationBannerState extends ConsumerState<_TerminationBanner> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final proposal = widget.contract.proposedChanges;
    if (proposal == null) return const SizedBox.shrink();

    final isTermination = proposal['is_termination'] == true;
    if (!isTermination) return const SizedBox.shrink();

    final dateStr = proposal['new_end_date'] as String?;
    final date = dateStr != null ? DateTime.parse(dateStr) : null;
    final formattedDate = date != null ? DateFormat('dd/MM/yyyy').format(date) : '-';
    
    final isProposer = widget.contract.proposedBy == widget.currentUser?.id;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: StanomerColors.alertPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: StanomerColors.alertPrimary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () async {
                      setState(() => _isLoading = true);
                      try {
                        await ref.read(propertyRepositoryProvider).declineProposedChanges(widget.contract.id);
                        ref.invalidate(activeContractProvider(widget.propertyId));
                      } finally {
                        if (mounted) setState(() => _isLoading = false);
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: StanomerColors.alertPrimary,
                      side: const BorderSide(color: StanomerColors.alertPrimary),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(loc.declineTermination, style: const TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () async {
                      setState(() => _isLoading = true);
                      try {
                        await ref.read(propertyRepositoryProvider).acceptProposedChanges(widget.contract.id);
                        ref.invalidate(activeContractProvider(widget.propertyId));
                      } finally {
                        if (mounted) setState(() => _isLoading = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: StanomerColors.successPrimary,
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(loc.approveTermination, style: const TextStyle(fontSize: 12)),
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
              onPressed: _isLoading ? null : () async {
                setState(() => _isLoading = true);
                try {
                  await ref.read(propertyRepositoryProvider).declineProposedChanges(widget.contract.id);
                  ref.invalidate(activeContractProvider(widget.propertyId));
                } finally {
                  if (mounted) setState(() => _isLoading = false);
                }
              },
              child: Text(loc.cancel, style: const TextStyle(color: StanomerColors.alertPrimary, fontSize: 12)),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool isFilled;
  const _StatusBadge({required this.label, required this.color, this.isFilled = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isFilled ? color : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isFilled ? Colors.transparent : color.withValues(alpha: 0.35), width: 1),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: isFilled ? Colors.white : color),
      ),
    );
  }
}

// ── Summary Chip ──────────────────────────────────────────────────────────────
class _SummaryChip extends StatelessWidget {
  final String label;
  final String subLabel;
  final int count;
  final Color color;
  const _SummaryChip({required this.label, required this.subLabel, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: StanomerColors.borderDefault),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: StanomerColors.textTertiary, letterSpacing: 0.8),
            ),
            const SizedBox(height: 2),
            Text(
              '$count',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: count > 0 ? color : StanomerColors.textTertiary),
            ),
            const SizedBox(height: 2),
            Text(
              subLabel,
              style: const TextStyle(fontSize: 8, color: StanomerColors.textTertiary, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Mini Badge (for Accordion Headers) ────────────────────────────────────────
class _MiniBadge extends StatelessWidget {
  final int count;
  final Color color;
  const _MiniBadge({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count.toString(),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }
}

class DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dashLength;
  final double borderRadius;

  DashedRectPainter({
    this.color = const Color(0xFFC8C8C8),
    this.strokeWidth = 1.0,
    this.gap = 4.0,
    this.dashLength = 6.0,
    this.borderRadius = 8.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(borderRadius),
      ));

    final dashedPath = Path();
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        dashedPath.addPath(
          metric.extractPath(distance, distance + dashLength),
          Offset.zero,
        );
        distance += dashLength + gap;
      }
    }
    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant DashedRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gap != gap ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.borderRadius != borderRadius;
  }
}

Future<void> _openFileOrUrl(BuildContext context, String pathOrUrl, {required bool mounted}) async {
  if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
    final uri = Uri.parse(pathOrUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  } else {
    final file = io.File(pathOrUrl);
    if (!file.existsSync()) {
      if (mounted) {
        final loc = AppLocalizations.of(context)!;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(loc.cannotOpenDocument),
            content: Text(loc.documentMissingLocalDesc),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(loc.ok),
              ),
            ],
          ),
        );
      }
      return;
    }
    final result = await OpenFilex.open(pathOrUrl);
    if (result.type != ResultType.done && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot open local file: ${result.message}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

