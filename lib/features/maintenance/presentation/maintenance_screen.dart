import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/colors.dart';
import '../../property/domain/property.dart';
import '../../auth/data/auth_providers.dart';
import '../domain/maintenance_request.dart';
import '../data/maintenance_repository.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/connection_status_indicator.dart';

class MaintenanceScreen extends ConsumerWidget {
  final Property property;

  const MaintenanceScreen({super.key, required this.property});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);
    final isLandlord = property.landlordId == user?.id;
    final isTenant = property.tenantId == user?.id;
    final requestsAsync = ref.watch(maintenanceRequestsProvider(property.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.maintenance),
      ),
      body: Column(
        children: [
          ConnectionStatusIndicator(
            hasError: requestsAsync.hasError,
            onRetry: () => ref.invalidate(maintenanceRequestsProvider(property.id)),
          ),
          if (isTenant)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/maintenance/new', extra: property),
                  icon: const Icon(LucideIcons.plus, size: 20),
                  label: Text(loc.reportIssue),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: StanomerColors.tenant,
                  ),
                ),
              ),
            ),
          Expanded(
            child: () {
              if (requestsAsync.hasValue) {
                final requests = requestsAsync.value!;
                if (requests.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.shieldCheck, size: 48, color: StanomerColors.getRoleColor(user?.userMetadata?['role'])),
                        const SizedBox(height: 16),
                        Text(loc.noIssuesTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(loc.noIssuesMessage, textAlign: TextAlign.center, style: const TextStyle(color: StanomerColors.textSecondary)),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  itemCount: requests.length,
                  itemBuilder: (context, index) => _MaintenanceCard(
                    request: requests[index],
                    isLandlord: isLandlord,
                    property: property,
                  ),
                );
              } else if (requestsAsync.hasError) {
                return AppErrorView(
                  error: requestsAsync.error!,
                  onRetry: () => ref.invalidate(maintenanceRequestsProvider(property.id)),
                );
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            }(),
          ),
        ],
      ),
    );
  }
}

class _MaintenanceCard extends ConsumerWidget {
  final MaintenanceRequest request;
  final bool isLandlord;
  final Property property;

  const _MaintenanceCard({required this.request, required this.isLandlord, required this.property});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color statusColor = Colors.grey;
    String statusLabel = 'Unknown';
    switch (request.status) {
      case MaintenanceStatus.open:
        statusColor = Colors.orange;
        statusLabel = loc.statusActive; 
        break;
      case MaintenanceStatus.investigating:
        statusColor = Colors.blue;
        statusLabel = loc.statusInvestigating;
        break;
      case MaintenanceStatus.resolved:
        statusColor = StanomerColors.successPrimary;
        statusLabel = loc.statusResolved;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: StanomerColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: StanomerColors.borderDefault),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            await context.push(
              '/maintenance/detail',
              extra: {
                'property': property,
                'request': request,
              },
            );
            // Refresh the list when returning from detail
            ref.invalidate(maintenanceRequestsProvider(property.id));
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        statusLabel.toUpperCase(),
                        style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                    ),
                    if (request.priority == MaintenancePriority.urgent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: StanomerColors.alertPrimary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.alertCircle, size: 12, color: StanomerColors.alertPrimary),
                            const SizedBox(width: 4),
                            Text(
                              loc.priorityUrgent.toUpperCase(),
                              style: const TextStyle(color: StanomerColors.alertPrimary, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(request.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                if (request.description != null && request.description!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    request.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, color: StanomerColors.textSecondary),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(LucideIcons.tag, size: 14, color: StanomerColors.textTertiary),
                    const SizedBox(width: 6),
                    Text(_getCategoryLabel(request.category, loc), style: const TextStyle(fontSize: 12, color: StanomerColors.textTertiary)),
                    const Spacer(),
                    Text(
                      request.createdAt != null ? DateFormat('dd MMM, HH:mm').format(request.createdAt!) : '-',
                      style: const TextStyle(fontSize: 11, color: StanomerColors.textTertiary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getCategoryLabel(MaintenanceCategory cat, AppLocalizations loc) {
    switch (cat) {
      case MaintenanceCategory.plumbing: return loc.categoryPlumbing;
      case MaintenanceCategory.electrical: return loc.categoryElectrical;
      case MaintenanceCategory.heating: return loc.categoryHeating;
      case MaintenanceCategory.internet: return loc.categoryInternet;
      case MaintenanceCategory.other: return loc.categoryOther;
    }
  }


}
