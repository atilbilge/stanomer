import 'package:universal_io/io.dart' as io;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/document_storage_service.dart';
import '../../../core/utils/currency_utils.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/colors.dart';
import '../../property/domain/property.dart';
import '../../auth/data/auth_providers.dart';
import '../../property/data/property_repository.dart';
import '../../agency/presentation/agency_dashboard_screen.dart';
import '../domain/maintenance_request.dart';
import '../domain/maintenance_message.dart';
import '../domain/maintenance_charge.dart';
import '../data/maintenance_repository.dart';

class MaintenanceDetailScreen extends ConsumerStatefulWidget {
  final Property property;
  final MaintenanceRequest request;

  const MaintenanceDetailScreen({
    super.key,
    required this.property,
    required this.request,
  });

  @override
  ConsumerState<MaintenanceDetailScreen> createState() => _MaintenanceDetailScreenState();
}

class _MaintenanceDetailScreenState extends ConsumerState<MaintenanceDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage({String? photoUrl}) async {
    final loc = AppLocalizations.of(context)!;
    final text = _messageController.text.trim();
    if (text.isEmpty && photoUrl == null) return;

    setState(() => _isSending = true);
    try {
      await ref.read(maintenanceRepositoryProvider).addMessage(
        widget.request.id,
        widget.property.id,
        text,
        photoUrl: photoUrl,
      );
      _messageController.clear();
      // Scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.errorWithDetails(e.toString())), backgroundColor: StanomerColors.alertPrimary),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _sendPhoto() async {
    final loc = AppLocalizations.of(context)!;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result == null) return;

      final platformFile = result.files.single;
      List<int>? fileBytes = platformFile.bytes?.toList();

      if (fileBytes == null && !kIsWeb && platformFile.path != null) {
        fileBytes = await io.File(platformFile.path!).readAsBytes();
      }

      if (fileBytes == null) return;

      setState(() => _isSending = true);

      final isCloudAllowed = ref.read(cloudUploadAllowedProvider);
      String photoRef;

      if (isCloudAllowed) {
        photoRef = await ref.read(maintenanceRepositoryProvider).uploadMaintenancePhoto(
          requestId: widget.request.id,
          fileName: platformFile.name,
          bytes: Uint8List.fromList(fileBytes),
        );
      } else {
        final appDir = await getApplicationDocumentsDirectory();
        final storedDir = io.Directory('${appDir.path}/stored_documents');
        if (!await storedDir.exists()) {
          await storedDir.create(recursive: true);
        }
        final fileName = 'maintenance_${widget.request.id}_${DateTime.now().millisecondsSinceEpoch}_${p.basename(platformFile.name)}';
        final destPath = '${storedDir.path}/$fileName';
        await io.File(destPath).writeAsBytes(fileBytes);
        photoRef = 'local://$destPath';
      }

      await _sendMessage(photoUrl: photoRef);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.errorUploadingPhoto(e.toString())), backgroundColor: StanomerColors.alertPrimary),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final user = ref.watch(currentUserProvider);
    final userProfileAsync = user?.id != null ? ref.watch(profileProvider(user!.id)) : const AsyncValue<Map<String, dynamic>?>.data(null);
    final profileRole = userProfileAsync.value?['role'] as String? ?? user?.userMetadata?['role'] as String?;

    final isLandlord = widget.property.landlordId == user?.id || profileRole == 'landlord';
    final isAgency = widget.property.agencyId == user?.id || profileRole == 'agency';
    final isTenant = widget.property.tenantId == user?.id || profileRole == 'tenant' || (!isLandlord && !isAgency);
    final hasAgency = widget.property.agencyId != null && widget.property.agencyId!.isNotEmpty;

    final requestsAsync = ref.watch(maintenanceRequestsProvider(widget.property.id));
    final liveRequest = requestsAsync.maybeWhen(
      data: (list) => list.firstWhere((r) => r.id == widget.request.id, orElse: () => widget.request),
      orElse: () => widget.request,
    );

    final messagesAsync = ref.watch(maintenanceMessagesProvider(liveRequest.id));

    // Status details
    Color statusColor = const Color(0xFF64748B);
    Color statusBg = const Color(0xFFF1F5F9);
    Color statusDot = const Color(0xFF94A3B8);
    String statusLabel = 'Bilinmiyor';

    switch (liveRequest.status) {
      case MaintenanceStatus.open:
        statusBg = const Color(0xFFFFFBEB);
        statusColor = const Color(0xFFB45309);
        statusDot = const Color(0xFFD97706);
        statusLabel = loc.statusOpen;
        break;
      case MaintenanceStatus.investigating:
        statusBg = const Color(0xFFEFF6FF);
        statusColor = const Color(0xFF1D4ED8);
        statusDot = const Color(0xFF2563EB);
        statusLabel = loc.statusInvestigating;
        break;
      case MaintenanceStatus.inProgress:
        statusBg = const Color(0xFFFFF7ED);
        statusColor = const Color(0xFFC2410C);
        statusDot = const Color(0xFFEA580C);
        statusLabel = loc.statusInProgress;
        break;
      case MaintenanceStatus.resolved:
        statusBg = const Color(0xFFECFDF5);
        statusColor = const Color(0xFF065F46);
        statusDot = const Color(0xFF10B981);
        statusLabel = loc.statusResolved;
        break;
      case MaintenanceStatus.closed:
        statusBg = const Color(0xFFF1F5F9);
        statusColor = const Color(0xFF64748B);
        statusDot = const Color(0xFF94A3B8);
        statusLabel = loc.statusClosed;
        break;
      case MaintenanceStatus.pending:
        statusBg = const Color(0xFFFFFBEB);
        statusColor = const Color(0xFFD97706);
        statusDot = const Color(0xFFF59E0B);
        statusLabel = loc.statusPending;
        break;
      case MaintenanceStatus.cancelled:
        statusBg = const Color(0xFFFEF2F2);
        statusColor = const Color(0xFFDC2626);
        statusDot = const Color(0xFFEF4444);
        statusLabel = loc.statusCancelled;
        break;
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0F17) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          liveRequest.title.isNotEmpty ? liveRequest.title : loc.issueDetails,
          overflow: TextOverflow.ellipsis,
        ),
        leading: Navigator.canPop(context)
            ? BackButton(onPressed: () => Navigator.maybePop(context))
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/dashboard'),
              ),
        actions: [
          // Status Indicator Pill
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(color: statusDot, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),

          // Actions (e.g. Delete if allowed)
          if (isTenant && liveRequest.status == MaintenanceStatus.open) ...[
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(LucideIcons.trash2, size: 18, color: Color(0xFFDC2626)),
              tooltip: loc.deleteRequest,
              onPressed: () => _confirmDelete(context, ref, liveRequest),
            ),
          ],
          const SizedBox(width: 14),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 920;

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left 65%: Main Discussion & Timeline Stream
                Expanded(
                  flex: 65,
                  child: Column(
                    children: [
                      Expanded(
                        child: _buildMainConversationStream(
                          liveRequest: liveRequest,
                          messagesAsync: messagesAsync,
                          user: user,
                          loc: loc,
                          isDark: isDark,
                        ),
                      ),
                      if (liveRequest.status == MaintenanceStatus.resolved)
                        _buildResolvedFooter(liveRequest, isTenant, loc)
                      else
                        _buildMessageComposer(loc, isDark),
                    ],
                  ),
                ),

                // Right 35%: SaaS Bento Sidebar (Financials + Metadata + Actions)
                Container(
                  width: 360,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    border: Border(
                      left: BorderSide(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                      ),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSidebarFinancialsCard(
                          request: liveRequest,
                          loc: loc,
                          isDark: isDark,
                          isTenant: isTenant,
                          isLandlord: isLandlord,
                          isAgency: isAgency,
                          hasAgency: hasAgency,
                          messagesAsync: messagesAsync,
                        ),
                        const SizedBox(height: 16),
                        _buildSidebarPropertyCard(liveRequest, loc, isDark),
                        const SizedBox(height: 16),
                        if ((isLandlord || isAgency) && liveRequest.status != MaintenanceStatus.resolved)
                          _buildSidebarManagementActions(liveRequest, loc, isDark),
                      ],
                    ),
                  ),
                ),
              ],
            );
          } else {
            // Mobile / Narrow Stack
            return Column(
              children: [
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Column(
                            children: [
                              _buildSidebarFinancialsCard(
                                request: liveRequest,
                                loc: loc,
                                isDark: isDark,
                                isTenant: isTenant,
                                isLandlord: isLandlord,
                                isAgency: isAgency,
                                hasAgency: hasAgency,
                                messagesAsync: messagesAsync,
                              ),
                              const SizedBox(height: 12),
                              _buildSidebarPropertyCard(liveRequest, loc, isDark),
                              if ((isLandlord || isAgency) && liveRequest.status != MaintenanceStatus.resolved) ...[
                                const SizedBox(height: 12),
                                _buildSidebarManagementActions(liveRequest, loc, isDark),
                              ],
                            ],
                          ),
                        ),
                      ),
                      SliverFillRemaining(
                        hasScrollBody: true,
                        child: _buildMainConversationStream(
                          liveRequest: liveRequest,
                          messagesAsync: messagesAsync,
                          user: user,
                          loc: loc,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ),
                if (liveRequest.status == MaintenanceStatus.resolved)
                  _buildResolvedFooter(liveRequest, isTenant, loc)
                else
                  _buildMessageComposer(loc, isDark),
              ],
            );
          }
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Main Conversation Stream & Description Hero Card
  // ---------------------------------------------------------------------------
  Widget _buildMainConversationStream({
    required MaintenanceRequest liveRequest,
    required AsyncValue<List<MaintenanceMessage>> messagesAsync,
    required dynamic user,
    required AppLocalizations loc,
    required bool isDark,
  }) {
    return messagesAsync.when(
      data: (messages) {
        final allItems = [
          // 1. Hero Ticket Details Card (Top of stream)
          _IssueHeroCard(
            property: widget.property,
            request: liveRequest,
            loc: loc,
            isDark: isDark,
          ),

          // 2. Chat & Activity Messages
          ...messages.map((m) {
            return _MessageBubble(
              userId: m.userId,
              message: m.message,
              photoUrl: m.photoUrl,
              isMe: m.userId == user?.id,
              createdAt: m.createdAt,
              landlordId: widget.property.landlordId,
              tenantId: widget.property.tenantId,
              agencyId: widget.property.agencyId,
            );
          }),
        ];

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          reverse: true,
          itemCount: allItems.length,
          itemBuilder: (context, index) => allItems.reversed.toList()[index],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF5E6AD2))),
      error: (e, _) => Center(child: Text(loc.errorWithDetails(e.toString()))),
    );
  }

  // ---------------------------------------------------------------------------
  // Sidebar: Stripe / Ramp Style Financials Bento Box
  // ---------------------------------------------------------------------------
  Widget _buildSidebarFinancialsCard({
    required MaintenanceRequest request,
    required AppLocalizations loc,
    required bool isDark,
    required bool isTenant,
    required bool isLandlord,
    required bool isAgency,
    required bool hasAgency,
    AsyncValue<List<MaintenanceMessage>>? messagesAsync,
  }) {
    final currency = request.currency ?? (widget.property.currency.isNotEmpty ? widget.property.currency : 'EUR');

    final messages = messagesAsync?.value ?? [];
    final offsetMessages = messages.where((m) =>
      m.message.startsWith('🏠') ||
      m.message.contains('mahsup') ||
      m.message.contains('offset') ||
      m.message.contains('зачтен') ||
      m.message.contains('prebijen')
    ).toList();

    double offsetSumFromMessages = 0.0;
    for (final msg in offsetMessages) {
      final match = RegExp(r'(\d+(?:[.,]\d+)?)\s*(?:EUR|RSD|USD|TRY|TL|€|\$|₽|din|dinar)').firstMatch(msg.message);
      if (match != null) {
        final raw = match.group(1)?.replaceAll(',', '.') ?? '0';
        offsetSumFromMessages += double.tryParse(raw) ?? 0.0;
      }
    }

    final double effectiveSettled = request.settledAmount > 0 ? request.settledAmount : offsetSumFromMessages;
    final double effectiveRemaining = request.settledAmount > 0
        ? request.remainingAmount
        : (request.costAmount ?? 0.0);
    final double effectiveOriginal = request.settledAmount > 0
        ? (request.costAmount ?? 0.0)
        : (effectiveRemaining + effectiveSettled);
    final bool hasPartial = effectiveSettled > 0 && effectiveRemaining > 0;

    final formattedCost = request.costAmount != null
        ? CurrencyUtils.formatAmount(hasPartial && request.financialStatus == MaintenancePaymentStatus.pendingPayment ? effectiveRemaining : effectiveOriginal, currency, useSymbol: true)
        : null;

    final isPayerTenant = request.paidBy == 'tenant';
    final isPayerLandlord = request.paidBy == 'landlord';

    final lastDeclarationMsg = messagesAsync?.maybeWhen(
      data: (msgs) => msgs.cast<MaintenanceMessage?>().lastWhere(
        (m) => m != null && m.message.startsWith('📄'),
        orElse: () => null,
      ),
      orElse: () => null,
    );
    final bool isLastDeclaredByTenant = lastDeclarationMsg != null && lastDeclarationMsg.userId.isNotEmpty
        ? lastDeclarationMsg.userId == widget.property.tenantId
        : (request.reporterId == widget.property.tenantId);

    String payerLabel = loc.unassigned;
    if (isPayerTenant) {
      payerLabel = loc.payerTenantPaidOrWillPay;
    } else if (isPayerLandlord) {
      payerLabel = loc.payerLandlordWillCover;
    }

    String finStatusLabel = '';
    Color finStatusColor = const Color(0xFF64748B);
    Color finStatusBg = const Color(0xFFF1F5F9);
    IconData finStatusIcon = LucideIcons.clock;

    switch (request.financialStatus) {
      case MaintenancePaymentStatus.pendingAgencyApproval:
        finStatusLabel = loc.financialStatusPendingAgencyApproval;
        finStatusColor = const Color(0xFFD97706);
        finStatusBg = const Color(0xFFFFFBEB);
        finStatusIcon = LucideIcons.clock;
        break;
      case MaintenancePaymentStatus.pendingOppositeApproval:
        finStatusLabel = loc.financialStatusPendingOppositeApproval;
        finStatusColor = const Color(0xFF2563EB);
        finStatusBg = const Color(0xFFEFF6FF);
        finStatusIcon = LucideIcons.scale;
        break;
      case MaintenancePaymentStatus.pendingReview:
        finStatusLabel = loc.financialStatusPendingReview;
        finStatusColor = const Color(0xFF1D4ED8);
        finStatusBg = const Color(0xFFEFF6FF);
        finStatusIcon = LucideIcons.fileSearch;
        break;
      case MaintenancePaymentStatus.pendingPayment:
        if (isPayerTenant) {
          finStatusLabel = loc.localeName == 'tr'
              ? 'Mahsup Bekliyor'
              : (loc.localeName == 'ru' ? 'К зачету' : (loc.localeName.startsWith('sr') ? 'Za prebijanje' : 'Ready for Offset'));
          finStatusColor = const Color(0xFF2563EB);
          finStatusBg = const Color(0xFFEFF6FF);
          finStatusIcon = LucideIcons.repeat;
        } else {
          finStatusLabel = loc.localeName == 'tr'
              ? 'Ödeme Bekliyor'
              : (loc.localeName == 'ru' ? 'Ожидает оплаты' : (loc.localeName.startsWith('sr') ? 'Čeka uplatu' : 'Pending Payment'));
          finStatusColor = const Color(0xFFB45309);
          finStatusBg = const Color(0xFFFFFBEB);
          finStatusIcon = LucideIcons.clock;
        }
        break;
      case MaintenancePaymentStatus.paid:
        finStatusLabel = loc.financialStatusPaid;
        finStatusColor = const Color(0xFF059669);
        finStatusBg = const Color(0xFFECFDF5);
        finStatusIcon = LucideIcons.checkCircle2;
        break;
      case MaintenancePaymentStatus.rejected:
        finStatusLabel = loc.financialStatusRejected;
        finStatusColor = const Color(0xFFDC2626);
        finStatusBg = const Color(0xFFFEF2F2);
        finStatusIcon = LucideIcons.xCircle;
        break;
    }

    final allMessages = messagesAsync?.value ?? [];
    final hasPaymentSubmission = allMessages.any((m) =>
      m.message.contains('dekont') ||
      m.message.contains('receipt') ||
      m.message.contains('квитанция') ||
      m.message.contains('uplatnic') ||
      m.message.contains('nakit') ||
      m.message.contains('cash') ||
      m.message.contains('наличными') ||
      m.message.contains('gotovin')
    );

    final hasFinancials = request.costAmount != null || (request.invoicePdfUrl != null && request.invoicePdfUrl!.isNotEmpty);
    final canAgencyEdit = isAgency;
    final canLandlordEdit = !hasAgency && isLandlord && (!hasFinancials || request.financialStatus == MaintenancePaymentStatus.pendingReview);
    final canTenantEdit = !hasAgency && isTenant && (!hasFinancials || request.financialStatus == MaintenancePaymentStatus.pendingReview);

    bool canApproveExpense = false;
    String approvalTitle = '';
    String approvalSubtitle = '';
    String waitingOnText = '';

    if (hasAgency) {
      canApproveExpense = isAgency;
      approvalTitle = loc.agencyExpenseApproval;
      approvalSubtitle = isLastDeclaredByTenant
          ? loc.tenantDeclaredExpenseSubtitle(formattedCost ?? '')
          : loc.landlordDeclaredExpenseSubtitle(formattedCost ?? '');
      if (!isAgency) {
        waitingOnText = loc.propertyManagedByAgencyNotice;
      }
    } else {
      if (isPayerTenant) {
        // Tenant paid for fixture / maintenance -> Landlord reimburses or offsets from rent
        canApproveExpense = isLandlord;
        approvalTitle = loc.landlordExpenseApproval;
        approvalSubtitle = loc.confirmTenantReimburseApprovalMsg(formattedCost ?? '');
        if (isTenant) {
          waitingOnText = loc.expenseSubmittedForLandlordReview;
        }
      } else {
        // Landlord paid upfront for usage damage -> Charged to tenant (Add to rent)
        if (hasPaymentSubmission) {
          // Tenant has uploaded payment proof / declared cash payment -> Landlord confirms receipt of payment
          canApproveExpense = isLandlord;
          approvalTitle = loc.confirmReceiptBtn;
          approvalSubtitle = loc.localeName == 'tr'
              ? 'Kiracının yaptığı ${formattedCost ?? ''} tutarındaki ödemeyi aldığınızı ve borcu kapattığınızı onaylıyor musunuz?'
              : (loc.localeName == 'ru'
                  ? 'Вы подтверждаете получение платежа на сумму ${formattedCost ?? ''} от арендатора и закрытие долга?'
                  : (loc.localeName.startsWith('sr')
                      ? 'Da li potvrđujete prijem uplate od ${formattedCost ?? ''} od stanara i zatvaranje duga?'
                      : 'Do you confirm receiving the payment of ${formattedCost ?? ''} from the tenant and closing the debt?'));
          if (isTenant) {
            waitingOnText = loc.waitingForOwnerApproval;
          }
        } else {
          // Initial declaration: Landlord charged tenant for usage damage -> Tenant confirms the debt
          canApproveExpense = isTenant;
          approvalTitle = loc.tenantExpenseApproval;
          approvalSubtitle = loc.confirmLandlordTenantDueApprovalMsg(formattedCost ?? '');
          if (isLandlord) {
            waitingOnText = loc.expenseSubmittedForTenantReview;
          }
        }
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.7) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.5) : const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5E6AD2).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(LucideIcons.walletCards, size: 14, color: Color(0xFF5E6AD2)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      loc.financialDetails.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
                if (canAgencyEdit)
                  InkWell(
                    onTap: () => _showEditFinancialsSheet(context, request),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5E6AD2).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.pencil, size: 11, color: Color(0xFF5E6AD2)),
                          const SizedBox(width: 4),
                          Text(
                            hasFinancials ? loc.edit : loc.add,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF5E6AD2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (canLandlordEdit && hasFinancials)
                  InkWell(
                    onTap: () => _showEditFinancialsSheet(context, request, isLandlordDeclaration: true),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.pencil, size: 11, color: Color(0xFF2563EB)),
                          const SizedBox(width: 4),
                          Text(
                            loc.update,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (canTenantEdit && hasFinancials)
                  InkWell(
                    onTap: () => _showEditFinancialsSheet(context, request, isTenantDeclaration: true),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.pencil, size: 11, color: Color(0xFF059669)),
                          const SizedBox(width: 4),
                          Text(
                            loc.update,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!hasFinancials) ...[
                  // Empty State Box
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.4) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(LucideIcons.circleSlash, size: 16, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 8),
                            Text(
                              loc.noFinancialRecordTitle,
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          loc.noFinancialRecordDesc,
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  if (isTenant) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showEditFinancialsSheet(context, request, isTenantDeclaration: true),
                        icon: const Icon(LucideIcons.receiptText, size: 14),
                        label: Text(loc.iPaidSubmitReceipt),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ] else if (isLandlord) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showEditFinancialsSheet(context, request, isLandlordDeclaration: true),
                        icon: const Icon(LucideIcons.receiptText, size: 14),
                        label: Text(loc.iPaidSubmitReceipt),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ] else if (isAgency) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showEditFinancialsSheet(context, request),
                        icon: const Icon(LucideIcons.plus, size: 14),
                        label: Text(loc.addCostInvoice),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5E6AD2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ] else ...[
                  // Hero Amount & Financial Status Badge Row
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              formattedCost ?? loc.unassigned,
                              style: TextStyle(
                                fontSize: formattedCost != null ? 24 : 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (hasPartial && request.financialStatus == MaintenancePaymentStatus.pendingPayment) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFFBEB),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFFDE68A)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(LucideIcons.scissors, size: 10, color: Color(0xFFB45309)),
                                      const SizedBox(width: 3.5),
                                      Text(
                                        loc.localeName == 'tr'
                                            ? 'Kalan'
                                            : (loc.localeName == 'ru'
                                                ? 'Остаток'
                                                : (loc.localeName.startsWith('sr') ? 'Preostalo' : 'Remaining')),
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFB45309),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                decoration: BoxDecoration(
                                  color: finStatusBg,
                                  borderRadius: BorderRadius.circular(6),
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
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: finStatusColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (hasPartial) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD97706).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.info, size: 11, color: Color(0xFFD97706)),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  loc.localeName == 'tr'
                                      ? 'Orijinal Tutar: ${CurrencyUtils.formatAmount(effectiveOriginal, currency, useSymbol: true)} (${CurrencyUtils.formatAmount(effectiveSettled, currency, useSymbol: true)} mahsup edildi)'
                                      : (loc.localeName == 'ru'
                                          ? 'Исходная сумма: ${CurrencyUtils.formatAmount(effectiveOriginal, currency, useSymbol: true)} (${CurrencyUtils.formatAmount(effectiveSettled, currency, useSymbol: true)} зачтено)'
                                          : (loc.localeName.startsWith('sr')
                                              ? 'Originalni iznos: ${CurrencyUtils.formatAmount(effectiveOriginal, currency, useSymbol: true)} (${CurrencyUtils.formatAmount(effectiveSettled, currency, useSymbol: true)} prebijeno)'
                                              : 'Original: ${CurrencyUtils.formatAmount(effectiveOriginal, currency, useSymbol: true)} (${CurrencyUtils.formatAmount(effectiveSettled, currency, useSymbol: true)} offset)')),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFB45309),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Financial Settlement Resolution Banner
                  if (request.financialStatus == MaintenancePaymentStatus.pendingPayment && request.costAmount != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB45309).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFB45309).withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFB45309).withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(LucideIcons.repeat, size: 13, color: Color(0xFFB45309)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isPayerLandlord
                                      ? loc.landlordReimbursement
                                      : loc.tenantToPay,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF92400E)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isPayerLandlord
                                      ? loc.landlordReimburseDesc
                                      : loc.tenantToPayDesc,
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF78350F), height: 1.35),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ] else if (request.financialStatus == MaintenancePaymentStatus.paid && request.costAmount != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF059669).withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(LucideIcons.checkCircle2, size: 13, color: Color(0xFF059669)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isPayerLandlord
                                      ? loc.coveredByLandlord
                                      : loc.coveredByTenant,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF065F46)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isPayerLandlord
                                      ? loc.coveredByLandlordClosedDesc
                                      : loc.coveredByTenantClosedDesc,
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF047857), height: 1.35),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ] else if (request.financialStatus == MaintenancePaymentStatus.rejected && request.costAmount != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE11D48).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE11D48).withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE11D48).withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(LucideIcons.xCircle, size: 13, color: Color(0xFFE11D48)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  loc.financialStatusRejected,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF9F1239)),
                                ),
                                if (request.rejectionReason != null && request.rejectionReason!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    request.rejectionReason!,
                                    style: const TextStyle(fontSize: 11, color: Color(0xFFBE123C), height: 1.35),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Details Grid Container
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.3) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        // Row 1: Payer
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(LucideIcons.userCheck, size: 13, color: Color(0xFF64748B)),
                                const SizedBox(width: 6),
                                Text(
                                  loc.costPayerLabel,
                                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isPayerTenant
                                    ? const Color(0xFF059669).withValues(alpha: 0.1)
                                    : (isPayerLandlord ? const Color(0xFF2563EB).withValues(alpha: 0.1) : const Color(0xFF64748B).withValues(alpha: 0.1)),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isPayerTenant ? LucideIcons.user : (isPayerLandlord ? LucideIcons.home : LucideIcons.helpCircle),
                                    size: 11,
                                    color: isPayerTenant ? const Color(0xFF059669) : (isPayerLandlord ? const Color(0xFF2563EB) : const Color(0xFF64748B)),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    payerLabel,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isPayerTenant ? const Color(0xFF059669) : (isPayerLandlord ? const Color(0xFF2563EB) : const Color(0xFF64748B)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Row 2: Date
                        if (request.paymentDate != null) ...[
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(LucideIcons.calendar, size: 13, color: Color(0xFF64748B)),
                                  const SizedBox(width: 6),
                                  Text(
                                    loc.paymentDate,
                                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                              Text(
                                DateFormat('dd.MM.yyyy').format(request.paymentDate!),
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                    // Receipt / Invoice Box
                    if (request.invoicePdfUrl != null && request.invoicePdfUrl!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () async {
                          final uri = Uri.parse(request.invoicePdfUrl!);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626).withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(LucideIcons.fileText, size: 14, color: Color(0xFFDC2626)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      loc.receiptInvoiceDocument,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                    ),
                                    Text(
                                      loc.clickToViewDocument,
                                      style: const TextStyle(fontSize: 10.5, color: Color(0xFFDC2626), fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(LucideIcons.externalLink, size: 14, color: Color(0xFFDC2626)),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // Offset & Balance History Box
                    if (offsetMessages.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(LucideIcons.history, size: 13, color: Color(0xFF64748B)),
                                const SizedBox(width: 6),
                                Text(
                                  loc.localeName == 'tr'
                                      ? 'Mahsuplaşma & Bakiye Geçmişi'
                                      : (loc.localeName == 'ru'
                                          ? 'История зачетов'
                                          : (loc.localeName.startsWith('sr')
                                              ? 'Istorija prebijanja'
                                              : 'Offset & Balance History')),
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...offsetMessages.map((msg) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2.5),
                              child: Text(
                                msg.message,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                  height: 1.35,
                                ),
                              ),
                            )),
                          ],
                        ),
                      ),
                    ],

                  // Approval Action Box
                  if ((request.financialStatus == MaintenancePaymentStatus.pendingReview ||
                       request.financialStatus == MaintenancePaymentStatus.pendingAgencyApproval ||
                       request.financialStatus == MaintenancePaymentStatus.pendingOppositeApproval) &&
                      request.costAmount != null) ...[
                    if (canApproveExpense) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1D4ED8).withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF1D4ED8).withValues(alpha: 0.25)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(LucideIcons.shieldCheck, size: 15, color: Color(0xFF1D4ED8)),
                                const SizedBox(width: 6),
                                Text(
                                  approvalTitle,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              approvalSubtitle,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF475569), height: 1.35),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _handleApproveExpense(
                                      request: request,
                                      hasAgency: hasAgency,
                                      isPayerTenant: isPayerTenant,
                                      isPayerLandlord: isPayerLandlord,
                                      isTenantApproving: isTenant,
                                      isLandlordApproving: isLandlord,
                                      isAgencyApproving: isAgency,
                                      isLastDeclaredByTenant: isLastDeclaredByTenant,
                                      hasPaymentSubmission: hasPaymentSubmission,
                                    ),
                                    icon: const Icon(LucideIcons.check, size: 14),
                                    label: Text(loc.approve),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF059669),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 9),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _handleRejectExpense(
                                      request: request,
                                      hasAgency: hasAgency,
                                      isTenantRejecting: isTenant,
                                      isLandlordRejecting: isLandlord,
                                      isAgencyRejecting: isAgency,
                                    ),
                                    icon: const Icon(LucideIcons.x, size: 14),
                                    label: Text(loc.reject),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFFDC2626),
                                      side: const BorderSide(color: Color(0xFFFCA5A5)),
                                      padding: const EdgeInsets.symmetric(vertical: 9),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ] else if (waitingOnText.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF64748B).withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF64748B).withValues(alpha: 0.15)),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.info, size: 14, color: Color(0xFF64748B)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                waitingOnText,
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.35),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],

                  // Rejected Alert Box
                  if (request.financialStatus == MaintenancePaymentStatus.rejected) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626).withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.25)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(LucideIcons.alertCircle, size: 15, color: Color(0xFFDC2626)),
                              const SizedBox(width: 6),
                              Text(
                                loc.financialStatusRejected,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFDC2626)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            loc.expenseRejectedDesc,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF475569), height: 1.35),
                          ),
                          const SizedBox(height: 10),
                          if (isTenant) ...[
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _showEditFinancialsSheet(context, request, isTenantDeclaration: true),
                                icon: Icon(request.paidBy == 'tenant' ? LucideIcons.rotateCcw : LucideIcons.receiptText, size: 14),
                                label: Text(
                                  request.paidBy == 'tenant'
                                      ? loc.resubmitExpenseIPaid
                                      : loc.iPaidSubmitReceipt,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF059669),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          ] else if (isLandlord) ...[
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _showEditFinancialsSheet(context, request, isLandlordDeclaration: true),
                                icon: Icon(isLastDeclaredByTenant ? LucideIcons.pencil : (request.paidBy == 'landlord' ? LucideIcons.rotateCcw : LucideIcons.receiptText), size: 14),
                                label: Text(
                                  isLastDeclaredByTenant
                                      ? (loc.localeName == 'tr' ? 'Yeni Masraf Tutarı Gir' : (loc.localeName == 'ru' ? 'Ввести новую сумму' : (loc.localeName.startsWith('sr') ? 'Unesi novi iznos troška' : 'Enter New Expense Amount')))
                                      : (request.paidBy == 'landlord' ? loc.resubmitExpenseIPaid : loc.iPaidSubmitReceipt),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          ] else if (isAgency) ...[
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _showEditFinancialsSheet(context, request),
                                icon: const Icon(LucideIcons.pencil, size: 14),
                                label: Text(loc.reEditFinancials),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF5E6AD2),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sidebar: Property Context Card
  // ---------------------------------------------------------------------------
  Widget _buildSidebarPropertyCard(MaintenanceRequest request, AppLocalizations loc, bool isDark) {
    final prop = widget.property;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.6) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(LucideIcons.building, size: 14, color: Color(0xFF3B82F6)),
              ),
              const SizedBox(width: 8),
              Text(
                loc.propertyInfo.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            prop.name.isNotEmpty ? prop.name : loc.myProperty,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          if (prop.address.isNotEmpty) ...[
            const SizedBox(height: 3),
            Row(
              children: [
                const Icon(LucideIcons.mapPin, size: 12, color: Color(0xFF94A3B8)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    prop.address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sidebar: Quick Management Actions
  // ---------------------------------------------------------------------------
  Widget _buildSidebarManagementActions(MaintenanceRequest request, AppLocalizations loc, bool isDark) {
    final isInvestigating = request.status == MaintenanceStatus.investigating;
    final isInProgress = request.status == MaintenanceStatus.inProgress;
    final isResolved = request.status == MaintenanceStatus.resolved;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.7) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.5) : const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(LucideIcons.zap, size: 14, color: Color(0xFFD97706)),
                ),
                const SizedBox(width: 8),
                Text(
                  loc.quickActions.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 1. İnceleniyor
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: isInvestigating ? null : () => _updateStatus(ref, MaintenanceStatus.investigating),
                    icon: Icon(
                      isInvestigating ? LucideIcons.check : LucideIcons.search,
                      size: 15,
                    ),
                    label: Text(
                      isInvestigating
                          ? '${loc.statusInvestigating} (✓)'
                          : loc.statusInvestigating,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isInvestigating ? const Color(0xFF64748B) : const Color(0xFF2563EB),
                      backgroundColor: isInvestigating ? const Color(0xFF2563EB).withValues(alpha: 0.08) : Colors.transparent,
                      side: BorderSide(
                        color: isInvestigating ? const Color(0xFF2563EB).withValues(alpha: 0.3) : const Color(0xFFBFDBFE),
                        width: 1.2,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // 2. Usta Gönderildi
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: isInProgress ? null : () => _updateStatus(ref, MaintenanceStatus.inProgress),
                    icon: Icon(
                      isInProgress ? LucideIcons.check : LucideIcons.wrench,
                      size: 15,
                    ),
                    label: Text(
                      isInProgress
                          ? '${loc.statusInProgress} (✓)'
                          : loc.statusInProgress,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isInProgress ? const Color(0xFF64748B) : const Color(0xFFD97706),
                      backgroundColor: isInProgress ? const Color(0xFFD97706).withValues(alpha: 0.08) : Colors.transparent,
                      side: BorderSide(
                        color: isInProgress ? const Color(0xFFD97706).withValues(alpha: 0.3) : const Color(0xFFFDE68A),
                        width: 1.2,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // 3. Çözüldü
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isResolved ? null : () => _updateStatus(ref, MaintenanceStatus.resolved),
                    icon: const Icon(LucideIcons.checkCircle2, size: 15),
                    label: Text(
                      isResolved
                          ? '${loc.statusResolved} (✓)'
                          : loc.statusResolved,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF059669).withValues(alpha: 0.4),
                      disabledForegroundColor: Colors.white.withValues(alpha: 0.8),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                      textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom Message Composer (Slack / Linear Style)
  // ---------------------------------------------------------------------------
  Widget _buildMessageComposer(AppLocalizations loc, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            InkWell(
              onTap: _isSending ? null : _sendPhoto,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(LucideIcons.paperclip, size: 18, color: Color(0xFF64748B)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: TextField(
                  controller: _messageController,
                  maxLines: 4,
                  minLines: 1,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    hintText: loc.commentHint,
                    hintStyle: const TextStyle(fontSize: 13.5, color: Color(0xFF94A3B8)),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            InkWell(
              onTap: _isSending ? null : () => _sendMessage(),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF5E6AD2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(LucideIcons.send, size: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResolvedFooter(MaintenanceRequest request, bool isTenant, AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      color: const Color(0xFFECFDF5),
      child: Column(
        children: [
          const Icon(LucideIcons.checkCircle2, size: 36, color: Color(0xFF059669)),
          const SizedBox(height: 8),
          Text(
            loc.issueResolvedStatus,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF065F46)),
          ),
          if (isTenant) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => _reopen(ref),
              icon: const Icon(LucideIcons.rotateCcw, size: 16),
              label: Text(loc.reopenIssue),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF059669)),
            ),
          ],
        ],
      ),
    );
  }

  void _showEditFinancialsSheet(
    BuildContext context,
    MaintenanceRequest request, {
    bool isTenantDeclaration = false,
    bool isLandlordDeclaration = false,
  }) {
    final user = ref.read(currentUserProvider);
    final userProfileAsync = user?.id != null ? ref.read(profileProvider(user!.id)) : const AsyncValue<Map<String, dynamic>?>.data(null);
    final profileRole = userProfileAsync.value?['role'] as String? ?? user?.userMetadata?['role'] as String?;

    final isLandlord = widget.property.landlordId == user?.id || profileRole == 'landlord';
    final isAgency = widget.property.agencyId == user?.id || profileRole == 'agency';
    final isTenant = widget.property.tenantId == user?.id || profileRole == 'tenant' || (!isLandlord && !isAgency);
    final hasAgency = widget.property.agencyId != null && widget.property.agencyId!.isNotEmpty;
    final hasFinancials = request.costAmount != null || (request.invoicePdfUrl != null && request.invoicePdfUrl!.isNotEmpty);
    final isDeclaring = isTenantDeclaration || isLandlordDeclaration;

    // If managed by an agency and financials already exist, ONLY the agency can modify full details,
    // UNLESS the tenant/landlord is submitting or re-submitting an expense declaration ("I Paid")
    if (hasAgency && hasFinancials && !isAgency && !isDeclaring) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Localizations.localeOf(context).languageCode.toLowerCase() == 'tr'
                ? 'Mülk acente yönetimindedir. Finansal bilgileri yalnızca acente düzenleyebilir.'
                : 'Property is managed by an agency. Only the agency can edit financial details.',
          ),
          backgroundColor: const Color(0xFF475569),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditFinancialsSheet(
        property: widget.property,
        request: request,
        isTenantDeclaration: isTenantDeclaration || (isTenant && !isAgency && !isLandlord && !isLandlordDeclaration),
        isLandlordDeclaration: isLandlordDeclaration,
      ),
    );
  }

  Future<void> _updateStatus(WidgetRef ref, MaintenanceStatus status) async {
    final loc = AppLocalizations.of(context)!;
    final user = ref.read(currentUserProvider);
    final userProfileAsync = user?.id != null ? ref.read(profileProvider(user!.id)) : const AsyncValue<Map<String, dynamic>?>.data(null);
    final profileRole = userProfileAsync.value?['role'] as String? ?? user?.userMetadata?['role'] as String?;
    final fullName = (userProfileAsync.value?['full_name'] as String?)?.trim();

    final isLandlord = widget.property.landlordId == user?.id || profileRole == 'landlord';
    final isAgency = widget.property.agencyId == user?.id || profileRole == 'agency';

    String actorLabel;
    if (fullName != null && fullName.isNotEmpty) {
      if (isAgency) {
        actorLabel = '$fullName (${loc.agencyManager})';
      } else if (isLandlord) {
        actorLabel = '$fullName (${loc.payerLandlord})';
      } else {
        actorLabel = '$fullName (${loc.payerTenant})';
      }
    } else {
      if (isAgency) {
        actorLabel = loc.agencyManager;
      } else if (isLandlord) {
        actorLabel = loc.payerLandlord;
      } else {
        actorLabel = loc.payerTenant;
      }
    }

    String logMessage;
    switch (status) {
      case MaintenanceStatus.investigating:
        logMessage = loc.actorStatusInvestigating(actorLabel);
        break;
      case MaintenanceStatus.inProgress:
        logMessage = loc.actorStatusInProgress(actorLabel);
        break;
      case MaintenanceStatus.resolved:
        logMessage = loc.actorStatusResolved(actorLabel);
        break;
      case MaintenanceStatus.closed:
        logMessage = loc.actorStatusClosed(actorLabel);
        break;
      case MaintenanceStatus.open:
        logMessage = loc.actorMarkedActive(actorLabel);
        break;
      default:
        logMessage = loc.actorUpdatedStatus(actorLabel, status.name);
        break;
    }

    try {
      await ref.read(maintenanceRepositoryProvider).updateStatus(widget.request.id, widget.property.id, status);
      try {
        await ref.read(maintenanceRepositoryProvider).addMessage(
          widget.request.id,
          widget.property.id,
          logMessage,
        );
      } catch (_) {}

      ref.invalidate(maintenanceRequestsProvider(widget.property.id));
      ref.invalidate(maintenanceMessagesProvider(widget.request.id));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.errorUpdatingStatus(e.toString())), backgroundColor: StanomerColors.alertPrimary),
        );
      }
    }
  }

  Future<void> _reopen(WidgetRef ref) async {
    final loc = AppLocalizations.of(context)!;
    final user = ref.read(currentUserProvider);
    final userProfileAsync = user?.id != null ? ref.read(profileProvider(user!.id)) : const AsyncValue<Map<String, dynamic>?>.data(null);
    final fullName = (userProfileAsync.value?['full_name'] as String?)?.trim();
    final actorLabel = (fullName != null && fullName.isNotEmpty)
        ? '$fullName (${loc.payerTenant})'
        : loc.payerTenant;

    try {
      await ref.read(maintenanceRepositoryProvider).reopenRequest(widget.request.id, widget.property.id);
      try {
        await ref.read(maintenanceRepositoryProvider).addMessage(
          widget.request.id,
          widget.property.id,
          loc.actorStatusReopened(actorLabel),
        );
      } catch (_) {}

      ref.invalidate(maintenanceRequestsProvider(widget.property.id));
      ref.invalidate(maintenanceMessagesProvider(widget.request.id));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.errorReopeningRequest(e.toString())), backgroundColor: StanomerColors.alertPrimary),
        );
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, MaintenanceRequest request) async {
    final loc = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.deleteRequest),
        content: Text(loc.areYouSure),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(loc.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(loc.remove, style: const TextStyle(color: StanomerColors.alertPrimary)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(maintenanceRepositoryProvider).deleteRequest(request.id, widget.property.id);
      if (context.mounted) context.pop();
    }
  }

  Future<void> _handleApproveExpense({
    required MaintenanceRequest request,
    required bool hasAgency,
    required bool isPayerTenant,
    required bool isPayerLandlord,
    required bool isTenantApproving,
    required bool isLandlordApproving,
    required bool isAgencyApproving,
    required bool isLastDeclaredByTenant,
    required bool hasPaymentSubmission,
  }) async {
    final loc = AppLocalizations.of(context)!;
    final currency = request.currency ?? (widget.property.currency.isNotEmpty ? widget.property.currency : 'EUR');
    final formattedCost = request.costAmount != null
        ? CurrencyUtils.formatAmount(request.costAmount!, currency, useSymbol: true)
        : '';

    String approverRoleName;
    if (isAgencyApproving) {
      approverRoleName = loc.agencyManager;
    } else if (isLandlordApproving) {
      approverRoleName = loc.payerLandlord;
    } else {
      approverRoleName = loc.payerTenant;
    }

    String targetPaidBy = request.paidBy ?? (isPayerTenant ? 'tenant' : 'landlord');
    String targetPaymentStatus;
    String detailMsg;

    if (isAgencyApproving) {
      // Agency approving an expense:
      if (request.financialStatus == MaintenancePaymentStatus.pendingOppositeApproval) {
        targetPaymentStatus = 'pending_payment';
        detailMsg = targetPaidBy == 'landlord'
            ? '${loc.landlordReimbursement} (${loc.financialStatusPendingPayment})'
            : '${loc.tenantToPay} (${loc.financialStatusPendingPayment})';
      } else if (request.financialStatus == MaintenancePaymentStatus.pendingAgencyApproval) {
        targetPaymentStatus = 'paid';
        detailMsg = targetPaidBy == 'landlord'
            ? '${loc.coveredByLandlord} (${loc.financialStatusPaid})'
            : '${loc.coveredByTenant} (${loc.financialStatusPaid})';
      } else if (targetPaidBy == 'landlord' || isPayerLandlord) {
        // Landlord covers / tenant gets reimbursed or deducted from rent
        targetPaidBy = 'landlord';
        targetPaymentStatus = 'pending_payment';
        detailMsg = '${loc.landlordReimbursement} (${loc.financialStatusPendingPayment})';
      } else {
        // Tenant responsibility
        if (isLastDeclaredByTenant) {
          targetPaidBy = 'tenant';
          targetPaymentStatus = 'paid';
          detailMsg = '${loc.coveredByTenant} (${loc.financialStatusPaid})';
        } else {
          targetPaidBy = 'tenant';
          targetPaymentStatus = 'pending_payment';
          detailMsg = '${loc.tenantToPay} (${loc.financialStatusPendingPayment})';
        }
      }
    } else if (isPayerTenant || targetPaidBy == 'tenant') {
      // Tenant declared fixture reimbursement claim -> Landlord approves -> moves to pending_payment for rent offset
      targetPaidBy = 'tenant';
      targetPaymentStatus = 'pending_payment';
      detailMsg = '${loc.landlordReimbursement} (${loc.financialStatusPendingPayment})';
    } else {
      // Landlord declared damage claim (paidBy == 'landlord')
      if (hasPaymentSubmission) {
        // Landlord confirms tenant's payment -> moves to paid
        targetPaidBy = 'landlord';
        targetPaymentStatus = 'paid';
        detailMsg = '${loc.confirmReceiptBtn} (${loc.financialStatusPaid})';
      } else {
        // Tenant accepts initial damage charge -> moves to pending_payment for tenant to pay
        targetPaidBy = 'landlord';
        targetPaymentStatus = 'pending_payment';
        detailMsg = '${loc.tenantToPay} (${loc.financialStatusPendingPayment})';
      }
    }

    try {
      await ref.read(maintenanceRepositoryProvider).updateFinancialDetails(
        requestId: request.id,
        propertyId: widget.property.id,
        costAmount: request.costAmount,
        currency: request.currency,
        paidBy: targetPaidBy,
        paymentDate: request.paymentDate ?? DateTime.now(),
        paymentStatus: targetPaymentStatus,
        invoicePdfUrl: request.invoicePdfUrl,
        rejectionReason: null,
        rejectedBy: null,
      );

      await ref.read(maintenanceRepositoryProvider).addMessage(
        request.id,
        widget.property.id,
        loc.agencyExpenseApprovedMsg(formattedCost, approverRoleName, detailMsg),
        photoUrl: request.invoicePdfUrl,
      );

      ref.invalidate(maintenanceRequestsProvider(widget.property.id));
      ref.invalidate(maintenanceMessagesProvider(request.id));
      ref.invalidate(propertyFinancialStatusProvider(widget.property.id));
      ref.invalidate(rentPaymentsProvider(widget.property.id));
      ref.invalidate(propertiesStreamProvider);
      ref.invalidate(propertiesFutureProvider);
      ref.invalidate(agencyPropertiesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.expenseApprovedSuccess),
            backgroundColor: const Color(0xFF059669),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.errorWithDetails(e.toString())),
            backgroundColor: StanomerColors.alertPrimary,
          ),
        );
      }
    }
  }

  Future<void> _handleRejectExpense({
    required MaintenanceRequest request,
    required bool hasAgency,
    required bool isTenantRejecting,
    required bool isLandlordRejecting,
    required bool isAgencyRejecting,
  }) async {
    final loc = AppLocalizations.of(context)!;
    String approverRoleName;
    if (isAgencyRejecting) {
      approverRoleName = loc.agencyManager;
    } else if (isLandlordRejecting) {
      approverRoleName = loc.payerLandlord;
    } else {
      approverRoleName = loc.payerTenant;
    }

    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(LucideIcons.xCircle, color: Color(0xFFDC2626), size: 20),
            const SizedBox(width: 8),
            Text(loc.rejectExpenseTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.rejectExpenseConfirm,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: loc.rejectionReasonOptional,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(loc.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            child: Text(loc.reject),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final reason = reasonController.text.trim();
      final user = ref.read(currentUserProvider);
      await ref.read(maintenanceRepositoryProvider).updateFinancialDetails(
        requestId: request.id,
        propertyId: widget.property.id,
        costAmount: request.costAmount,
        currency: request.currency,
        paidBy: request.paidBy,
        paymentDate: request.paymentDate,
        paymentStatus: 'rejected',
        invoicePdfUrl: request.invoicePdfUrl,
        rejectionReason: reason.isNotEmpty ? reason : null,
        rejectedBy: user?.id,
      );

      await ref.read(maintenanceRepositoryProvider).addMessage(
        request.id,
        widget.property.id,
        '${loc.agencyExpenseRejectedMsg(approverRoleName)}${reason.isNotEmpty ? '\n${loc.reasonLabel(reason)}' : ''}',
      );

      ref.invalidate(maintenanceRequestsProvider(widget.property.id));
      ref.invalidate(maintenanceMessagesProvider(request.id));
      ref.invalidate(propertyFinancialStatusProvider(widget.property.id));
      ref.invalidate(rentPaymentsProvider(widget.property.id));
      ref.invalidate(propertiesStreamProvider);
      ref.invalidate(propertiesFutureProvider);
      ref.invalidate(agencyPropertiesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.expenseRejectedSuccess),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorWithDetails(e.toString())),
            backgroundColor: StanomerColors.alertPrimary,
          ),
        );
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Issue Hero Card (Header & Description at the start of discussion)
// ---------------------------------------------------------------------------
class _IssueHeroCard extends StatelessWidget {
  final Property property;
  final MaintenanceRequest request;
  final AppLocalizations loc;
  final bool isDark;

  const _IssueHeroCard({
    required this.property,
    required this.request,
    required this.loc,
    required this.isDark,
  });

  IconData _getCategoryIcon(MaintenanceCategory cat) {
    switch (cat) {
      case MaintenanceCategory.plumbing: return LucideIcons.droplets;
      case MaintenanceCategory.electrical: return LucideIcons.zap;
      case MaintenanceCategory.heating: return LucideIcons.flame;
      case MaintenanceCategory.internet: return LucideIcons.wifi;
      case MaintenanceCategory.appliance: return LucideIcons.tv;
      case MaintenanceCategory.structural: return LucideIcons.building2;
      default: return LucideIcons.wrench;
    }
  }

  Color _getCategoryColor(MaintenanceCategory cat) {
    switch (cat) {
      case MaintenanceCategory.plumbing: return const Color(0xFF0284C7);
      case MaintenanceCategory.electrical: return const Color(0xFFD97706);
      case MaintenanceCategory.heating: return const Color(0xFFEA580C);
      case MaintenanceCategory.internet: return const Color(0xFF2563EB);
      case MaintenanceCategory.appliance: return const Color(0xFF059669);
      case MaintenanceCategory.structural: return const Color(0xFF4F46E5);
      default: return const Color(0xFF7C3AED);
    }
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

  @override
  Widget build(BuildContext context) {
    final categoryColor = _getCategoryColor(request.category);
    final categoryIcon = _getCategoryIcon(request.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Category & Priority
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: categoryColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(categoryIcon, size: 12, color: categoryColor),
                    const SizedBox(width: 5),
                    Text(
                      _getCategoryLabel(request.category, loc).toUpperCase(),
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: categoryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (request.priority == MaintenancePriority.urgent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE11D48).withValues(alpha: 0.2)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.alertTriangle, size: 12, color: Color(0xFFE11D48)),
                      SizedBox(width: 4),
                      Text(
                        'ACİL MÜDAHALE',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFE11D48),
                        ),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              if (request.createdAt != null)
                Text(
                  DateFormat('dd MMMM yyyy, HH:mm').format(request.createdAt!),
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Title
          Text(
            request.title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),

          // Description
          if (request.description != null && request.description!.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                ),
              ),
              child: Text(
                request.description!,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                ),
              ),
            ),

          // Photos Lightbox Gallery
          if (request.photosUrls.isNotEmpty) ...[
            const SizedBox(height: 14),
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: request.photosUrls.length,
                itemBuilder: (context, idx) => Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _InteractiveImage(url: request.photosUrls[idx]),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Linear Message Bubble
// ---------------------------------------------------------------------------
class _MessageBubble extends ConsumerWidget {
  final String userId;
  final String message;
  final String? photoUrl;
  final bool isMe;
  final DateTime createdAt;
  final String? landlordId;
  final String? tenantId;
  final String? agencyId;

  const _MessageBubble({
    required this.userId,
    required this.message,
    this.photoUrl,
    required this.isMe,
    required this.createdAt,
    this.landlordId,
    this.tenantId,
    this.agencyId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profileAsync = userId.isNotEmpty ? ref.watch(profileProvider(userId)) : const AsyncValue<Map<String, dynamic>?>.data(null);

    String senderName = isMe ? loc.roleYou : loc.roleUser;
    String roleLabel = loc.roleUser;
    Color roleBadgeColor = const Color(0xFF5E6AD2);
    IconData roleIcon = LucideIcons.user;

    if (userId.isNotEmpty && userId == landlordId) {
      roleLabel = loc.payerLandlord;
      roleBadgeColor = const Color(0xFF2563EB);
      roleIcon = LucideIcons.home;
    } else if (userId.isNotEmpty && userId == tenantId) {
      roleLabel = loc.payerTenant;
      roleBadgeColor = const Color(0xFF059669);
      roleIcon = LucideIcons.user;
    } else if (userId.isNotEmpty && userId == agencyId) {
      roleLabel = loc.agencyManager;
      roleBadgeColor = const Color(0xFF7C3AED);
      roleIcon = LucideIcons.building;
    }

    profileAsync.whenData((profile) {
      if (profile != null) {
        final fn = (profile['full_name'] as String?)?.trim();
        if (fn != null && fn.isNotEmpty) senderName = fn;
      }
    });

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: roleBadgeColor.withValues(alpha: 0.15),
              child: Text(
                senderName.isNotEmpty ? senderName[0].toUpperCase() : 'U',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: roleBadgeColor),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Header (Name + Role + Time)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      senderName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: roleBadgeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(roleIcon, size: 9, color: roleBadgeColor),
                          const SizedBox(width: 3),
                          Text(
                            roleLabel,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: roleBadgeColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('HH:mm').format(createdAt),
                      style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
                const SizedBox(height: 5),

                // Message bubble
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe
                        ? const Color(0xFF5E6AD2)
                        : (isDark ? const Color(0xFF1E293B) : Colors.white),
                    borderRadius: BorderRadius.circular(12),
                    border: isMe
                        ? null
                        : Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (photoUrl != null && photoUrl!.isNotEmpty) ...[
                        if (photoUrl!.toLowerCase().endsWith('.pdf') || photoUrl!.toLowerCase().contains('.pdf')) ...[
                          InkWell(
                            onTap: () async {
                              final uri = Uri.parse(photoUrl!);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? Colors.white.withValues(alpha: 0.15)
                                    : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isMe
                                      ? Colors.white.withValues(alpha: 0.3)
                                      : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.fileText,
                                    size: 15,
                                    color: isMe ? Colors.white : const Color(0xFFDC2626),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      loc.localeName == 'tr'
                                          ? 'Fatura / Belgeyi Görüntüle'
                                          : (loc.localeName == 'ru'
                                              ? 'Посмотреть счет'
                                              : (loc.localeName.startsWith('sr')
                                                  ? 'Pogledaj račun'
                                                  : 'View Invoice / Document')),
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: isMe ? Colors.white : const Color(0xFF2563EB),
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ] else ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _InteractiveImage(url: photoUrl!),
                          ),
                        ],
                        if (message.isNotEmpty) const SizedBox(height: 8),
                      ],
                      if (message.isNotEmpty)
                        Text(
                          message,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: isMe
                                ? Colors.white
                                : (isDark ? Colors.white : const Color(0xFF0F172A)),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 10),
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF5E6AD2).withValues(alpha: 0.15),
              child: const Text(
                'ME',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF5E6AD2)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Lightbox Image
// ---------------------------------------------------------------------------
class _InteractiveImage extends StatelessWidget {
  final String url;
  const _InteractiveImage({required this.url});

  bool get _isLocal => url.startsWith('local://');
  String get _localPath => url.replaceFirst('local://', '');

  Widget _buildImage({double? width, double? height, BoxFit fit = BoxFit.cover}) {
    if (url.toLowerCase().endsWith('.pdf') || url.toLowerCase().contains('.pdf')) {
      return Container(
        width: width ?? 90,
        height: height ?? 90,
        color: const Color(0xFFF1F5F9),
        child: const Center(
          child: Icon(LucideIcons.fileText, size: 28, color: Color(0xFFDC2626)),
        ),
      );
    }
    if (_isLocal) {
      if (kIsWeb) {
        return Container(
          width: width ?? 90,
          height: height ?? 90,
          color: Colors.grey.shade300,
          child: const Icon(LucideIcons.imageOff, color: Colors.grey),
        );
      }
      return Image.file(
        io.File(_localPath),
        width: width,
        height: height,
        fit: fit,
      );
    }
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: width ?? 90,
          height: height ?? 90,
          color: const Color(0xFFF1F5F9),
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF5E6AD2))),
        );
      },
      errorBuilder: (_, __, ___) => Container(
        width: width ?? 90,
        height: height ?? 90,
        color: const Color(0xFFF1F5F9),
        child: const Icon(LucideIcons.imageOff, color: Colors.grey),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => Dialog.fullscreen(
            backgroundColor: Colors.black.withValues(alpha: 0.9),
            child: Stack(
              children: [
                Center(child: _buildImage(fit: BoxFit.contain)),
                Positioned(
                  top: 40,
                  right: 20,
                  child: IconButton(
                    icon: const Icon(LucideIcons.x, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: _buildImage(width: 90, height: 90),
    );
  }
}

// =============================================================================
// Financial Details Edit / Declare Payment Bottom Sheet
// =============================================================================
class _EditFinancialsSheet extends ConsumerStatefulWidget {
  final Property property;
  final MaintenanceRequest request;
  final bool isTenantDeclaration;
  final bool isLandlordDeclaration;

  const _EditFinancialsSheet({
    required this.property,
    required this.request,
    this.isTenantDeclaration = false,
    this.isLandlordDeclaration = false,
  });

  @override
  ConsumerState<_EditFinancialsSheet> createState() => _EditFinancialsSheetState();
}

class _EditFinancialsSheetState extends ConsumerState<_EditFinancialsSheet> {
  late final TextEditingController _costController;
  late final TextEditingController _noteController;
  late String _selectedCurrency;
  String? _paidBy;
  String? _declarationIntent;
  late String _paymentStatus;
  DateTime? _paymentDate;
  String? _existingInvoiceUrl;
  PlatformFile? _selectedInvoiceFile;
  bool _isSaving = false;
  String? _validationError;

  bool get _isDeclaration => widget.isTenantDeclaration || widget.isLandlordDeclaration;

  void _clearValidationError() {
    if (_validationError != null) {
      setState(() => _validationError = null);
    }
  }

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
    _noteController.addListener(_clearValidationError);
    final isRejected = widget.request.paymentStatus == 'rejected';
    final isDifferentPayer = (widget.isLandlordDeclaration && widget.request.paidBy == 'tenant') ||
        (widget.isTenantDeclaration && widget.request.paidBy == 'landlord') ||
        (widget.isLandlordDeclaration && isRejected);

    if (isDifferentPayer) {
      _costController = TextEditingController();
      _existingInvoiceUrl = null;
    } else {
      _costController = TextEditingController(
        text: widget.request.costAmount != null ? widget.request.costAmount!.toString() : '',
      );
      _existingInvoiceUrl = widget.request.invoicePdfUrl;
    }
    _costController.addListener(_clearValidationError);

    final initialCur = widget.request.currency ??
        (widget.property.currency.isNotEmpty ? widget.property.currency : 'EUR');
    _selectedCurrency = (initialCur.toUpperCase() == 'RSD') ? 'RSD' : 'EUR';

    if (widget.isLandlordDeclaration) {
      _declarationIntent = null;
      _paidBy = null;
      _paymentStatus = 'pending_review';
    } else if (widget.isTenantDeclaration) {
      _declarationIntent = null;
      _paidBy = null;
      _paymentStatus = 'pending_review';
    } else {
      _declarationIntent = null;
      _paidBy = widget.request.paidBy;
      _paymentStatus = widget.request.paymentStatus == 'pending'
          ? 'pending_review'
          : widget.request.paymentStatus;
    }
    _paymentDate = widget.request.paymentDate ?? (_isDeclaration ? DateTime.now() : null);
  }

  @override
  void dispose() {
    _costController.removeListener(_clearValidationError);
    _noteController.removeListener(_clearValidationError);
    _costController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickInvoicePdf() async {
    _clearValidationError();
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      allowMultiple: false,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedInvoiceFile = result.files.first;
      });
    }
  }

  void _removeSelectedInvoice() {
    _clearValidationError();
    setState(() => _selectedInvoiceFile = null);
  }

  void _removeExistingInvoice() {
    _clearValidationError();
    setState(() => _existingInvoiceUrl = null);
  }

  Future<void> _selectPaymentDate(BuildContext context) async {
    final initial = _paymentDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _paymentDate = picked);
    }
  }

  Future<void> _save() async {
    final loc = AppLocalizations.of(context)!;
    double? costAmount;
    final costText = _costController.text.trim().replaceAll(',', '.');
    if (costText.isNotEmpty) {
      costAmount = double.tryParse(costText);
    }

    if (_isDeclaration) {
      if (costAmount == null || costAmount <= 0) {
        setState(() => _validationError = loc.pleaseEnterValidCost);
        return;
      }
      if (_declarationIntent == null) {
        setState(() => _validationError = loc.pleaseSelectDeclarationIntent);
        return;
      }
      if (_selectedInvoiceFile == null && (_existingInvoiceUrl == null || _existingInvoiceUrl!.isEmpty)) {
        setState(() => _validationError = loc.pleaseUploadReceipt);
        return;
      }
    } else {
      if (costText.isNotEmpty && (costAmount == null || costAmount < 0)) {
        setState(() => _validationError = loc.errorWithDetails('Invalid cost amount'));
        return;
      }
    }

    final String? finalPaidBy = widget.isLandlordDeclaration
        ? (_declarationIntent == 'tenant_due' ? 'tenant' : 'landlord')
        : (widget.isTenantDeclaration
            ? (_declarationIntent == 'reimburse' ? 'landlord' : 'tenant')
            : _paidBy);

    final bool isAgencyManaged = widget.property.agencyId != null && widget.property.agencyId!.isNotEmpty;
    final String finalPaymentStatus;
    if (_isDeclaration) {
      if (isAgencyManaged) {
        if (widget.isTenantDeclaration) {
          finalPaymentStatus = (_declarationIntent == 'reimburse')
              ? 'pending_opposite_approval'
              : 'pending_agency_approval';
        } else {
          finalPaymentStatus = (_declarationIntent == 'tenant_due')
              ? 'pending_opposite_approval'
              : 'pending_agency_approval';
        }
      } else {
        finalPaymentStatus = 'pending_review';
      }
    } else {
      finalPaymentStatus = _paymentStatus;
    }

    if (!_isDeclaration && costAmount != null && costAmount > 0 && finalPaidBy == null) {
      setState(() => _validationError = loc.pleaseSelectCostPayer);
      return;
    }

    setState(() {
      _validationError = null;
      _isSaving = true;
    });
    try {
      String? invoicePdfUrl = _existingInvoiceUrl;
      if (_selectedInvoiceFile != null) {
        List<int>? invoiceBytes = _selectedInvoiceFile!.bytes?.toList();
        if (invoiceBytes == null && !kIsWeb && _selectedInvoiceFile!.path != null) {
          invoiceBytes = await io.File(_selectedInvoiceFile!.path!).readAsBytes();
        }
        if (invoiceBytes != null) {
          invoicePdfUrl = await ref.read(maintenanceRepositoryProvider).uploadMaintenanceInvoice(
            propertyId: widget.property.id,
            requestId: widget.request.id,
            fileName: _selectedInvoiceFile!.name,
            bytes: Uint8List.fromList(invoiceBytes),
          );
        }
      }

      await ref.read(maintenanceRepositoryProvider).updateFinancialDetails(
        requestId: widget.request.id,
        propertyId: widget.property.id,
        costAmount: costAmount,
        currency: costAmount != null ? _selectedCurrency : null,
        paidBy: finalPaidBy,
        paymentDate: _paymentDate,
        paymentStatus: finalPaymentStatus,
        invoicePdfUrl: invoicePdfUrl,
      );

      // If user declared payment, log an activity message into discussion thread
      if (_isDeclaration && costAmount != null) {
        final declarantName = widget.isLandlordDeclaration
            ? loc.payerLandlord
            : loc.payerTenant;
        final String intentBadge = widget.isLandlordDeclaration
            ? (_declarationIntent == 'tenant_due' ? loc.intentLandlordTenantDueBadge : loc.intentLandlordSelfBadge)
            : (_declarationIntent == 'reimburse' ? loc.intentTenantReimburseBadge : loc.intentTenantSelfBadge);
        final note = _noteController.text.trim();
        final noteSection = note.isNotEmpty
            ? '\n\n📝 ${loc.noteLabel}: "$note"'
            : '';

        final String statusNote = widget.isLandlordDeclaration && widget.request.paymentStatus == 'rejected'
            ? (loc.localeName == 'tr' ? 'Yeni Masraf Belirlendi' : 'New Expense Entered')
            : loc.receiptInvoiceDocument;

        try {
          await ref.read(maintenanceRepositoryProvider).addMessage(
            widget.request.id,
            widget.property.id,
            '📄 $declarantName: ${costAmount.toStringAsFixed(2)} $_selectedCurrency\n📌 ${loc.settlementIntentTitle}: $intentBadge\n($statusNote • ${loc.financialStatusPendingReview})$noteSection',
            photoUrl: invoicePdfUrl,
          );
        } catch (_) {}
      }

      if (costAmount != null && costAmount > 0) {
        final isAgencyManaged = widget.property.agencyId != null && widget.property.agencyId!.isNotEmpty;
        final chargeType = _declarationIntent == 'reimburse'
            ? 'reimbursement'
            : (finalPaidBy == 'landlord' ? 'direct_charge' : 'direct_charge');
        final approverRole = isAgencyManaged ? 'agency' : 'counterparty';
        final debtorId = finalPaidBy == 'landlord' ? widget.property.landlordId : widget.property.tenantId;
        final creditorId = finalPaidBy == 'landlord' ? widget.property.tenantId : widget.property.landlordId;

        try {
          await ref.read(maintenanceRepositoryProvider).createMaintenanceCharge(
            MaintenanceCharge(
              id: '',
              maintenanceRequestId: widget.request.id,
              propertyId: widget.property.id,
              createdBy: ref.read(currentUserProvider)?.id,
              title: widget.request.title,
              chargeType: chargeType,
              approverRole: approverRole,
              debtorId: debtorId,
              creditorId: creditorId,
              amount: costAmount,
              settledAmount: 0.0,
              currency: _selectedCurrency,
              status: finalPaymentStatus == 'paid' ? 'paid' : (finalPaymentStatus == 'pending_payment' ? 'approved' : 'pending'),
              settlementMethod: finalPaymentStatus == 'paid' ? 'separate_payment' : 'rent_offset',
              receiptUrl: invoicePdfUrl,
              declaredAt: _paymentDate ?? DateTime.now(),
              paidAt: finalPaymentStatus == 'paid' ? (_paymentDate ?? DateTime.now()) : null,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
        } catch (e) {
          // Log non-fatal error during dual-write transition
          debugPrint('Error inserting maintenance charge: $e');
        }
      }

      ref.invalidate(maintenanceChargesProvider(widget.request.id));
      ref.invalidate(propertyMaintenanceChargesProvider(widget.property.id));
      ref.invalidate(agencyMaintenanceChargesProvider);
      ref.invalidate(maintenanceRequestsProvider(widget.property.id));
      ref.invalidate(maintenanceMessagesProvider(widget.request.id));
      ref.invalidate(propertyFinancialStatusProvider(widget.property.id));
      ref.invalidate(rentPaymentsProvider(widget.property.id));
      ref.invalidate(propertiesStreamProvider);
      ref.invalidate(propertiesFutureProvider);
      ref.invalidate(agencyPropertiesProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isDeclaration
                  ? loc.expenseApprovedSuccess
                  : loc.profileUpdated,
            ),
            backgroundColor: const Color(0xFF059669),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _validationError = loc.errorWithDetails(e.toString());
        });
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context)!;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isLandlordDeclaration
                            ? (widget.request.paymentStatus == 'rejected'
                                ? (loc.localeName == 'tr' ? 'Yeni Masraf Tutarı Gir' : (loc.localeName == 'ru' ? 'Ввести новую сумму' : (loc.localeName.startsWith('sr') ? 'Unesi novi iznos troška' : 'Enter New Expense Amount')))
                                : (loc.localeName == 'tr' ? 'Masraf Tutarı Belirle' : loc.editFinancialDetails))
                            : (_isDeclaration
                                ? loc.iPaidSubmitReceipt
                                : loc.editFinancialDetails),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      if (_isDeclaration) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.isLandlordDeclaration
                              ? (loc.localeName == 'tr'
                                  ? 'Masraf tutarını ve sorumluluk detayını belirleyin'
                                  : (loc.localeName == 'ru'
                                      ? 'Укажите сумму расхода и распределение ответственности'
                                      : (loc.localeName.startsWith('sr') ? 'Navedite iznos i odgovornost za trošak' : 'Specify the expense amount and responsibility')))
                              : loc.enterAmountAttachReceipt,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(LucideIcons.x, size: 18),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Cost & Currency
            Text(
              _isDeclaration
                  ? '${loc.amountPaid} *'
                  : loc.costAmount,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _costController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: '0.00',
                      prefixIcon: const Icon(LucideIcons.circleDollarSign, size: 16),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedCurrency,
                    items: const [
                      DropdownMenuItem(value: 'EUR', child: Text('EUR (€)')),
                      DropdownMenuItem(value: 'RSD', child: Text('RSD')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCurrency = val);
                    },
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Declaration Intent Cards (Only for I Paid flow)
            if (_isDeclaration) ...[
              Text(
                '${loc.settlementIntentTitle} *',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 8),
              if (widget.isTenantDeclaration) ...[
                _buildIntentCard(
                  title: loc.intentTenantSelfTitle,
                  subtitle: loc.intentTenantSelfSub,
                  badge: loc.intentTenantSelfBadge,
                  icon: LucideIcons.user,
                  isSelected: _declarationIntent == 'self',
                  color: const Color(0xFF059669),
                  onTap: () => setState(() => _declarationIntent = 'self'),
                ),
                const SizedBox(height: 8),
                _buildIntentCard(
                  title: loc.intentTenantReimburseTitle,
                  subtitle: loc.intentTenantReimburseSub,
                  badge: loc.intentTenantReimburseBadge,
                  icon: LucideIcons.home,
                  isSelected: _declarationIntent == 'reimburse',
                  color: const Color(0xFF2563EB),
                  onTap: () => setState(() => _declarationIntent = 'reimburse'),
                ),
              ] else if (widget.isLandlordDeclaration) ...[
                _buildIntentCard(
                  title: loc.intentLandlordSelfTitle,
                  subtitle: loc.intentLandlordSelfSub,
                  badge: loc.intentLandlordSelfBadge,
                  icon: LucideIcons.home,
                  isSelected: _declarationIntent == 'self',
                  color: const Color(0xFF059669),
                  onTap: () => setState(() => _declarationIntent = 'self'),
                ),
                const SizedBox(height: 8),
                _buildIntentCard(
                  title: loc.intentLandlordTenantDueTitle,
                  subtitle: loc.intentLandlordTenantDueSub,
                  badge: loc.intentLandlordTenantDueBadge,
                  icon: LucideIcons.user,
                  isSelected: _declarationIntent == 'tenant_due',
                  color: const Color(0xFFB45309),
                  onTap: () => setState(() => _declarationIntent = 'tenant_due'),
                ),
              ],
              const SizedBox(height: 16),
            ],

            // Payer (Only visible when not declaring)
            if (!_isDeclaration) ...[
              Text(
                '${loc.whoPaidTheCost} *',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _buildPayerChip(
                      label: loc.payerTenant,
                      icon: LucideIcons.user,
                      isSelected: _paidBy == 'tenant',
                      activeColor: const Color(0xFF059669),
                      onTap: () => setState(() => _paidBy = 'tenant'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildPayerChip(
                      label: loc.payerLandlord,
                      icon: LucideIcons.home,
                      isSelected: _paidBy == 'landlord',
                      activeColor: const Color(0xFF2563EB),
                      onTap: () => setState(() => _paidBy = 'landlord'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Payment Status (Only when not declaring)
              Text(
                loc.paymentInvoiceStatus,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: [
                  'pending_agency_approval',
                  'pending_opposite_approval',
                  'pending_review',
                  'pending_payment',
                  'paid',
                  'rejected',
                ].contains(_paymentStatus)
                    ? _paymentStatus
                    : 'pending_review',
                isExpanded: true,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'pending_agency_approval',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.clock, size: 15, color: Color(0xFFD97706)),
                        const SizedBox(width: 8),
                        Text(
                          loc.financialStatusPendingAgencyApproval,
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFFD97706)),
                        ),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'pending_opposite_approval',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.scale, size: 15, color: Color(0xFF2563EB)),
                        const SizedBox(width: 8),
                        Text(
                          loc.financialStatusPendingOppositeApproval,
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF2563EB)),
                        ),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'pending_review',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.fileSearch, size: 15, color: Color(0xFF1D4ED8)),
                        const SizedBox(width: 8),
                        Text(
                          loc.financialStatusPendingReview,
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF1D4ED8)),
                        ),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'pending_payment',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.clock, size: 15, color: Color(0xFFB45309)),
                        const SizedBox(width: 8),
                        Text(
                          loc.financialStatusPendingPayment,
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFFB45309)),
                        ),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'paid',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.checkCircle2, size: 15, color: Color(0xFF059669)),
                        const SizedBox(width: 8),
                        Text(
                          loc.financialStatusPaid,
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF059669)),
                        ),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'rejected',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.xCircle, size: 15, color: Color(0xFFDC2626)),
                        const SizedBox(width: 8),
                        Text(
                          loc.financialStatusRejected,
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFFDC2626)),
                        ),
                      ],
                    ),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _paymentStatus = val);
                },
              ),
              const SizedBox(height: 16),
            ],

            // Payment Date
            Text(
              _isDeclaration
                  ? loc.paymentDate
                  : loc.paymentDueDate,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: () => _selectPaymentDate(context),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.calendar, size: 15, color: Color(0xFF64748B)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _paymentDate != null ? DateFormat('dd MMMM yyyy').format(_paymentDate!) : loc.noDate,
                        style: const TextStyle(fontSize: 12.5),
                      ),
                    ),
                    if (_paymentDate != null)
                      GestureDetector(
                        onTap: () => setState(() => _paymentDate = null),
                        child: const Icon(LucideIcons.x, size: 14, color: Color(0xFF94A3B8)),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Invoice / Receipt Upload
            Text(
              _isDeclaration
                  ? '${loc.receiptInvoiceDocument} *'
                  : loc.uploadReceiptInvoice,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 6),
            if (_selectedInvoiceFile != null)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF5E6AD2).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF5E6AD2).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.fileText, size: 18, color: Color(0xFFDC2626)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedInvoiceFile!.name,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: _removeSelectedInvoice,
                      icon: const Icon(LucideIcons.trash2, size: 16, color: Color(0xFFDC2626)),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              )
            else if (_existingInvoiceUrl != null && _existingInvoiceUrl!.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.fileCheck2, size: 18, color: Color(0xFF059669)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        loc.existingDocument,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                    TextButton(onPressed: _pickInvoicePdf, child: Text(loc.change)),
                    IconButton(
                      onPressed: _removeExistingInvoice,
                      icon: const Icon(LucideIcons.trash2, size: 16, color: Color(0xFFDC2626)),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: _pickInvoicePdf,
                icon: const Icon(LucideIcons.uploadCloud, size: 15),
                label: Text(
                  _isDeclaration
                      ? loc.uploadReceiptInvoice
                      : loc.uploadInvoiceDoc,
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),

            const SizedBox(height: 16),

            // Description / Note field
            Text(
              loc.descriptionOrNoteOptional,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _noteController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: loc.enterExpenseNoteHint,
                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),

            if (_validationError != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.alertCircle, color: Color(0xFFDC2626), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _validationError!,
                        style: const TextStyle(
                          color: Color(0xFF991B1B),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _validationError = null),
                      child: const Icon(LucideIcons.x, color: Color(0xFF991B1B), size: 16),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isDeclaration
                    ? (widget.isLandlordDeclaration ? const Color(0xFF2563EB) : const Color(0xFF059669))
                    : const Color(0xFF5E6AD2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(
                      _isDeclaration
                          ? loc.submitExpenseReview
                          : loc.saveChanges,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayerChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.1) : Colors.transparent,
          border: Border.all(color: isSelected ? activeColor : const Color(0xFFCBD5E1)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, size: 15, color: isSelected ? activeColor : const Color(0xFF64748B)),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? activeColor : const Color(0xFF64748B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntentCard({
    required String title,
    required String subtitle,
    required String badge,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: isDark ? 0.15 : 0.06)
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSelected ? color.withValues(alpha: 0.15) : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSelected ? LucideIcons.checkCircle2 : icon,
                color: isSelected ? color : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? color : (isDark ? Colors.white : const Color(0xFF0F172A)),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: color),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
