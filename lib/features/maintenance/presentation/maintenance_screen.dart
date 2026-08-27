import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/colors.dart';
import '../../property/domain/property.dart';
import '../../property/data/property_repository.dart';
import '../../auth/data/auth_providers.dart';
import '../domain/maintenance_request.dart';
import '../data/maintenance_repository.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/connection_status_indicator.dart';
import 'package:url_launcher/url_launcher.dart';

class MaintenanceScreen extends ConsumerWidget {
  final Property property;

  const MaintenanceScreen({super.key, required this.property});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);
    final userProfileAsync = user?.id != null ? ref.watch(profileProvider(user!.id)) : const AsyncValue<Map<String, dynamic>?>.data(null);
    final profileRole = userProfileAsync.value?['role'] as String? ?? user?.userMetadata?['role'] as String?;

    final isLandlord = property.landlordId == user?.id || profileRole == 'landlord';
    final isAgency = property.agencyId == user?.id || profileRole == 'agency';
    final isTenant = property.tenantId == user?.id || profileRole == 'tenant' || (!isLandlord && !isAgency);
    final requestsAsync = ref.watch(maintenanceRequestsProvider(property.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.maintenance),
        leading: Navigator.canPop(context)
            ? BackButton(onPressed: () => Navigator.maybePop(context))
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/dashboard'),
              ),
      ),
      body: Column(
        children: [
          ConnectionStatusIndicator(
            hasError: requestsAsync.hasError,
            onRetry: () => ref.invalidate(maintenanceRequestsProvider(property.id)),
          ),
          if (isTenant || isAgency)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/maintenance/new', extra: property),
                  icon: const Icon(LucideIcons.plus, size: 20),
                  label: Text(loc.reportIssue),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAgency ? StanomerColors.brandPrimary : StanomerColors.tenant,
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

    final languageCode = Localizations.localeOf(context).languageCode.toLowerCase();

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
      case MaintenanceStatus.inProgress:
        statusColor = const Color(0xFFD97706);
        switch (languageCode) {
          case 'tr': statusLabel = 'Usta Gönderildi'; break;
          case 'sr': statusLabel = 'Poslat majstor'; break;
          case 'ru': statusLabel = 'Мастер отправлен'; break;
          default: statusLabel = 'Technician Sent'; break;
        }
        break;
      case MaintenanceStatus.resolved:
        statusColor = StanomerColors.successPrimary;
        statusLabel = loc.statusResolved;
        break;
      case MaintenanceStatus.closed:
        statusColor = Colors.grey;
        statusLabel = languageCode == 'tr' ? 'Kapatıldı' : (languageCode == 'sr' ? 'Zatvoreno' : (languageCode == 'ru' ? 'Закрыто' : 'Closed'));
        break;
      case MaintenanceStatus.pending:
        statusColor = Colors.amber;
        statusLabel = languageCode == 'tr' ? 'Beklemede' : (languageCode == 'sr' ? 'Na čekanju' : (languageCode == 'ru' ? 'В ожидании' : 'Pending'));
        break;
      case MaintenanceStatus.cancelled:
        statusColor = Colors.red;
        statusLabel = languageCode == 'tr' ? 'İptal Edildi' : (languageCode == 'sr' ? 'Otkazano' : (languageCode == 'ru' ? 'Отменено' : 'Cancelled'));
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
                _buildFinancialRow(request, context, loc, languageCode, isDark),
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

  Widget _buildFinancialRow(MaintenanceRequest request, BuildContext context, AppLocalizations loc, String languageCode, bool isDark) {
    if (request.costAmount == null && request.invoicePdfUrl == null) {
      return const SizedBox.shrink();
    }

    String tenantLabel;
    String landlordLabel;
    String pendingReviewLabel;
    String pendingPaymentLabel;
    String paidLabel;
    String rejectedLabel;

    switch (languageCode) {
      case 'tr':
        tenantLabel = 'Kiracı';
        landlordLabel = 'Ev Sahibi';
        pendingReviewLabel = 'İnceleme Bekliyor';
        pendingPaymentLabel = 'Ödeme Bekliyor';
        paidLabel = 'Ödendi';
        rejectedLabel = 'Reddedildi';
        break;
      case 'sr':
        tenantLabel = 'Stanar';
        landlordLabel = 'Vlasnik';
        pendingReviewLabel = 'Čeka proveru';
        pendingPaymentLabel = 'Čeka plaćanje';
        paidLabel = 'Plaćeno';
        rejectedLabel = 'Odbijeno';
        break;
      case 'ru':
        tenantLabel = 'Арендатор';
        landlordLabel = 'Владелец';
        pendingReviewLabel = 'На проверке';
        pendingPaymentLabel = 'Ожидает оплаты';
        paidLabel = 'Оплачено';
        rejectedLabel = 'Отклонено';
        break;
      default:
        tenantLabel = 'Tenant';
        landlordLabel = 'Landlord';
        pendingReviewLabel = 'Pending Review';
        pendingPaymentLabel = 'Pending Payment';
        paidLabel = 'Paid';
        rejectedLabel = 'Rejected';
        break;
    }

    Color finStatusColor;
    Color finStatusBg;
    IconData finStatusIcon;
    String finStatusLabel;

    switch (request.financialStatus) {
      case MaintenancePaymentStatus.pendingReview:
        finStatusColor = const Color(0xFF1A5EB8);
        finStatusBg = isDark ? const Color(0xFF1A5EB8).withValues(alpha: 0.2) : const Color(0xFFEBF3FC);
        finStatusIcon = LucideIcons.fileSearch;
        finStatusLabel = languageCode == 'tr' ? '🔍 Onay Bekliyor' : pendingReviewLabel;
        break;
      case MaintenancePaymentStatus.pendingPayment:
        finStatusColor = const Color(0xFFB06C10);
        finStatusBg = isDark ? const Color(0xFFB06C10).withValues(alpha: 0.2) : const Color(0xFFFEF6E8);
        finStatusIcon = LucideIcons.repeat;
        if (request.paidBy == 'landlord') {
          finStatusLabel = languageCode == 'tr'
              ? '🔄 Kiradan Düşülecek'
              : (languageCode == 'sr' ? 'Odbija se od kirije' : 'Reimburse Tenant');
        } else if (request.paidBy == 'tenant') {
          finStatusLabel = languageCode == 'tr'
              ? '🔄 Kiraya Eklenecek'
              : (languageCode == 'sr' ? 'Dodaje se na kiriju' : 'Add to Rent');
        } else {
          finStatusLabel = pendingPaymentLabel;
        }
        break;
      case MaintenancePaymentStatus.paid:
        finStatusColor = const Color(0xFF059669);
        finStatusBg = isDark ? const Color(0xFF059669).withValues(alpha: 0.2) : const Color(0xFFE6F7F0);
        finStatusIcon = LucideIcons.checkCircle2;
        if (request.paidBy == 'landlord') {
          finStatusLabel = languageCode == 'tr'
              ? ' Ev Sahibi Ödedi'
              : (languageCode == 'sr' ? 'Vlasnik platio' : 'Paid by Landlord');
        } else if (request.paidBy == 'tenant') {
          finStatusLabel = languageCode == 'tr'
              ? ' Kiracı Ödedi'
              : (languageCode == 'sr' ? 'Stanar platio' : 'Paid by Tenant');
        } else {
          finStatusLabel = paidLabel;
        }
        break;
      case MaintenancePaymentStatus.rejected:
        finStatusColor = const Color(0xFFC8503A);
        finStatusBg = isDark ? const Color(0xFFC8503A).withValues(alpha: 0.2) : const Color(0xFFFDF0EE);
        finStatusIcon = LucideIcons.xCircle;
        finStatusLabel = languageCode == 'tr' ? '❌ Reddedildi' : rejectedLabel;
        break;
    }

    final currency = request.currency ?? (property.currency.isNotEmpty ? property.currency : 'EUR');

    String dateLabel = '';
    IconData dateIcon = LucideIcons.calendar;
    Color dateColor = const Color(0xFF64748B);
    Color dateBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);

    if (request.financialStatus == MaintenancePaymentStatus.paid) {
      final pDate = request.paymentDate ?? request.updatedAt ?? request.createdAt;
      final dateStr = pDate != null ? DateFormat('dd.MM.yyyy').format(pDate) : '-';
      dateLabel = languageCode == 'tr'
          ? 'Ödeme Tarihi: $dateStr'
          : (languageCode == 'sr' ? 'Plaćeno: $dateStr' : (languageCode == 'ru' ? 'Оплачено: $dateStr' : 'Paid Date: $dateStr'));
      dateIcon = LucideIcons.checkCircle2;
      dateColor = const Color(0xFF065F46);
      dateBg = isDark ? const Color(0xFF065F46).withValues(alpha: 0.2) : const Color(0xFFECFDF5);
    } else if (request.paymentDate != null) {
      final dateStr = DateFormat('dd.MM.yyyy').format(request.paymentDate!);
      dateLabel = languageCode == 'tr'
          ? 'Vade / Son Ödeme: $dateStr'
          : (languageCode == 'sr' ? 'Rok za plaćanje: $dateStr' : (languageCode == 'ru' ? 'Срок оплаты: $dateStr' : 'Due Date: $dateStr'));
      dateIcon = LucideIcons.clock;
      dateColor = const Color(0xFFB45309);
      dateBg = isDark ? const Color(0xFFB45309).withValues(alpha: 0.2) : const Color(0xFFFFFBEB);
    } else if (request.createdAt != null) {
      final dateStr = DateFormat('dd.MM.yyyy').format(request.createdAt!);
      dateLabel = languageCode == 'tr'
          ? 'Bildirim: $dateStr'
          : (languageCode == 'sr' ? 'Datum prijave: $dateStr' : (languageCode == 'ru' ? 'Дата заявки: $dateStr' : 'Date: $dateStr'));
      dateIcon = LucideIcons.calendar;
      dateColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
      dateBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    }

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Amount + Payer + Status Badge
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Cost Amount + Payer badge
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (request.costAmount != null) ...[
                    Text(
                      '${request.costAmount!.toStringAsFixed(2)} $currency',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (request.paidBy != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: (request.paidBy == 'tenant' ? StanomerColors.tenant : StanomerColors.landlord).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            request.paidBy == 'tenant' ? LucideIcons.user : LucideIcons.home,
                            size: 10,
                            color: request.paidBy == 'tenant' ? StanomerColors.tenant : StanomerColors.landlord,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            request.paidBy == 'tenant' ? tenantLabel : landlordLabel,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: request.paidBy == 'tenant' ? StanomerColors.tenant : StanomerColors.landlord,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),

              // Payment Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: finStatusBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: finStatusColor.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(finStatusIcon, size: 11, color: finStatusColor),
                    const SizedBox(width: 4),
                    Text(
                      finStatusLabel,
                      style: TextStyle(
                        color: finStatusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Row 2: Date info + Clickable Invoice Link
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Date Badge (Due Date or Payment Date)
              if (dateLabel.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: dateBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(dateIcon, size: 11, color: dateColor),
                      const SizedBox(width: 4),
                      Text(
                        dateLabel,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: dateColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Clickable Invoice Link
              if (request.invoicePdfUrl != null && request.invoicePdfUrl!.isNotEmpty) ...[
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      final uri = Uri.parse(request.invoicePdfUrl!);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.fileText, size: 11, color: Colors.red),
                          const SizedBox(width: 4),
                          Text(
                            languageCode == 'tr'
                                ? 'Fatura Görüntüle ↗'
                                : (languageCode == 'sr' ? 'Pogledaj račun ↗' : (languageCode == 'ru' ? 'Смотреть счет ↗' : 'View Invoice ↗')),
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _getCategoryLabel(MaintenanceCategory cat, AppLocalizations loc) {
    switch (cat) {
      case MaintenanceCategory.plumbing: return loc.categoryPlumbing;
      case MaintenanceCategory.electrical: return loc.categoryElectrical;
      case MaintenanceCategory.heating: return loc.categoryHeating;
      case MaintenanceCategory.internet: return loc.categoryInternet;
      case MaintenanceCategory.appliance: return loc.categoryAppliance;
      case MaintenanceCategory.structural: return loc.categoryStructural;
      case MaintenanceCategory.other:
        return loc.categoryOther;
    }
  }
}
