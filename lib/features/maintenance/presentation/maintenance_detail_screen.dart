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
import '../../../core/services/document_storage_service.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/colors.dart';
import '../../property/domain/property.dart';
import '../../auth/data/auth_providers.dart';
import '../../property/data/property_repository.dart';
import '../domain/maintenance_request.dart';
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
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
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
        // ── Cloud path: upload to Supabase and get a public URL ──
        photoRef = await ref.read(maintenanceRepositoryProvider).uploadMaintenancePhoto(
          requestId: widget.request.id,
          fileName: platformFile.name,
          bytes: Uint8List.fromList(fileBytes),
        );
      } else {
        // ── Local path: save bytes to the app's documents directory ──
        final appDir = await getApplicationDocumentsDirectory();
        final storedDir = io.Directory('${appDir.path}/stored_documents');
        if (!await storedDir.exists()) {
          await storedDir.create(recursive: true);
        }
        final fileName = 'maintenance_${widget.request.id}_${DateTime.now().millisecondsSinceEpoch}_${p.basename(platformFile.name)}';
        final destPath = '${storedDir.path}/$fileName';
        await io.File(destPath).writeAsBytes(fileBytes);
        // Store the local path prefixed so the UI knows it's local
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
    final user = ref.watch(currentUserProvider);
    final userProfileAsync = user?.id != null ? ref.watch(profileProvider(user!.id)) : const AsyncValue<Map<String, dynamic>?>.data(null);
    final profileRole = userProfileAsync.value?['role'] as String? ?? user?.userMetadata?['role'] as String?;

    final isLandlord = widget.property.landlordId == user?.id || profileRole == 'landlord';
    final isAgency = widget.property.agencyId == user?.id || profileRole == 'agency';
    final isTenant = widget.property.tenantId == user?.id || profileRole == 'tenant' || (!isLandlord && !isAgency);

    final requestsAsync = ref.watch(maintenanceRequestsProvider(widget.property.id));
    final liveRequest = requestsAsync.maybeWhen(
      data: (list) => list.firstWhere((r) => r.id == widget.request.id, orElse: () => widget.request),
      orElse: () => widget.request,
    );

    final roleColor = isAgency
        ? const Color(0xFF8B5CF6)
        : (isLandlord ? StanomerColors.landlord : StanomerColors.tenant);
    final messagesAsync = ref.watch(maintenanceMessagesProvider(liveRequest.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.issueDetails),
        backgroundColor: roleColor,
        foregroundColor: Colors.white,
        actions: [
          if (isTenant && liveRequest.status == MaintenanceStatus.open)
            IconButton(
              icon: const Icon(LucideIcons.trash2, color: Colors.white),
              onPressed: () => _confirmDelete(context, ref, liveRequest),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(liveRequest, loc),
          const Divider(height: 1),
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty && liveRequest.description == null && liveRequest.photosUrls.isEmpty) {
                  return Center(child: Text(loc.noIssuesMessage, style: const TextStyle(color: StanomerColors.textTertiary)));
                }
                
                final allItems = [
                  if (liveRequest.description != null && liveRequest.description!.isNotEmpty || liveRequest.photosUrls.isNotEmpty)
                    _MessageBubble(
                      userId: liveRequest.reporterId,
                      message: liveRequest.description ?? '',
                      isMe: liveRequest.reporterId == user?.id,
                      createdAt: liveRequest.createdAt ?? DateTime.now(),
                      isDescription: true,
                      initialPhotos: liveRequest.photosUrls,
                      landlordId: widget.property.landlordId,
                      tenantId: widget.property.tenantId,
                      agencyId: widget.property.agencyId,
                    ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  reverse: true,
                  itemCount: allItems.length,
                  itemBuilder: (context, index) => allItems.reversed.toList()[index],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(loc.errorWithDetails(e.toString()))),
            ),
          ),
          if (liveRequest.status == MaintenanceStatus.resolved)
            _buildResolvedFooter(liveRequest, isTenant || isLandlord || isAgency, loc, roleColor)
          else
            _buildMessageInput(loc, roleColor),
          if ((isLandlord || isAgency) && liveRequest.status != MaintenanceStatus.resolved)
            _buildManagementActions(liveRequest, loc, roleColor),
        ],
      ),
    );
  }

  Widget _buildHeader(MaintenanceRequest request, AppLocalizations loc) {
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
      padding: const EdgeInsets.all(20),
      color: Theme.of(context).cardColor,
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
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                request.createdAt != null ? DateFormat('dd MMM yyyy, HH:mm').format(request.createdAt!) : '-',
                style: const TextStyle(fontSize: 12, color: StanomerColors.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(request.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(LucideIcons.tag, size: 14, color: StanomerColors.textTertiary),
              const SizedBox(width: 6),
              Text(_getCategoryLabel(request.category, loc), style: const TextStyle(fontSize: 13, color: StanomerColors.textSecondary)),
              if (request.priority == MaintenancePriority.urgent) ...[
                const SizedBox(width: 16),
                const Icon(LucideIcons.alertCircle, size: 14, color: StanomerColors.alertPrimary),
                const SizedBox(width: 6),
                Text(loc.priorityUrgent, style: const TextStyle(fontSize: 13, color: StanomerColors.alertPrimary, fontWeight: FontWeight.bold)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput(AppLocalizations loc, Color roleColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: StanomerColors.borderDefault)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _isSending ? null : _sendPhoto,
            icon: const Icon(LucideIcons.camera, color: StanomerColors.textSecondary),
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: loc.commentHint,
                filled: true,
                fillColor: Theme.of(context).cardColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              maxLines: null,
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: _isSending ? null : () => _sendMessage(),
            icon: _isSending 
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(LucideIcons.send, size: 20),
            style: IconButton.styleFrom(backgroundColor: roleColor),
          ),
        ],
      ),
    );
  }

  Widget _buildResolvedFooter(MaintenanceRequest request, bool isTenant, AppLocalizations loc, Color roleColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      width: double.infinity,
      color: StanomerColors.successPrimary.withValues(alpha: 0.05),
      child: Column(
        children: [
          Icon(LucideIcons.checkCircle2, size: 40, color: StanomerColors.successPrimary.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(
            loc.issueResolvedStatus,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, color: StanomerColors.textPrimary),
          ),
          if (isTenant) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => _reopen(ref),
              icon: const Icon(LucideIcons.rotateCcw, size: 18),
              label: Text(loc.reopenIssue),
              style: TextButton.styleFrom(foregroundColor: roleColor),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildManagementActions(MaintenanceRequest request, AppLocalizations loc, Color roleColor) {
    final languageCode = Localizations.localeOf(context).languageCode.toLowerCase();
    
    String technicianSentLabel;
    switch (languageCode) {
      case 'tr':
        technicianSentLabel = 'Usta Gönderildi';
        break;
      case 'sr':
        technicianSentLabel = 'Poslat majstor';
        break;
      case 'ru':
        technicianSentLabel = 'Мастер отправлен';
        break;
      default:
        technicianSentLabel = 'Technician Sent';
        break;
    }

    final isInvestigating = request.status == MaintenanceStatus.investigating;
    final isInProgress = request.status == MaintenanceStatus.inProgress;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      color: Theme.of(context).cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              languageCode == 'tr' ? 'DURUMU GÜNCELLE' : (languageCode == 'sr' ? 'AŽURIRAJ STATUS' : 'UPDATE STATUS'),
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: StanomerColors.textTertiary, letterSpacing: 0.5),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // 1. Araştırılıyor / İnceleniyor
                OutlinedButton.icon(
                  onPressed: isInvestigating ? null : () => _updateStatus(ref, MaintenanceStatus.investigating),
                  icon: Icon(
                    LucideIcons.search,
                    size: 16,
                    color: isInvestigating ? Colors.grey : roleColor,
                  ),
                  label: Text(loc.statusInvestigating),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isInvestigating ? Colors.grey : roleColor,
                    side: BorderSide(color: isInvestigating ? Colors.grey.shade300 : roleColor),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(width: 8),

                // 2. Usta Gönderildi / İşlemde
                OutlinedButton.icon(
                  onPressed: isInProgress ? null : () => _updateStatus(ref, MaintenanceStatus.inProgress),
                  icon: Icon(
                    LucideIcons.wrench,
                    size: 16,
                    color: isInProgress ? Colors.grey : const Color(0xFFD97706),
                  ),
                  label: Text(technicianSentLabel),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isInProgress ? Colors.grey : const Color(0xFFD97706),
                    side: BorderSide(color: isInProgress ? Colors.grey.shade300 : const Color(0xFFF59E0B)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(width: 8),

                // 3. Çözüldü
                ElevatedButton.icon(
                  onPressed: () => _updateStatus(ref, MaintenanceStatus.resolved),
                  icon: const Icon(LucideIcons.checkCheck, size: 16),
                  label: Text(loc.statusResolved),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: StanomerColors.successPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
              ],
            ),
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
      case MaintenanceCategory.appliance:
      case MaintenanceCategory.structural:
      case MaintenanceCategory.other:
      default:
        return loc.categoryOther;
    }
  }

  Future<void> _updateStatus(WidgetRef ref, MaintenanceStatus status) async {
    final loc = AppLocalizations.of(context)!;
    try {
      await ref.read(maintenanceRepositoryProvider).updateStatus(widget.request.id, widget.property.id, status);
      ref.invalidate(maintenanceRequestsProvider(widget.property.id));
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
    try {
      await ref.read(maintenanceRepositoryProvider).reopenRequest(widget.request.id, widget.property.id);
      ref.invalidate(maintenanceRequestsProvider(widget.property.id));
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
}

class _MessageBubble extends ConsumerWidget {
  final String userId;
  final String message;
  final String? photoUrl;
  final bool isMe;
  final DateTime createdAt;
  final bool isDescription;
  final List<String> initialPhotos;
  final String? landlordId;
  final String? tenantId;
  final String? agencyId;

  const _MessageBubble({
    required this.userId,
    required this.message,
    this.photoUrl,
    required this.isMe,
    required this.createdAt,
    this.isDescription = false,
    this.initialPhotos = const [],
    this.landlordId,
    this.tenantId,
    this.agencyId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final loc = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode.toLowerCase();

    final profileAsync = userId.isNotEmpty ? ref.watch(profileProvider(userId)) : const AsyncValue<Map<String, dynamic>?>.data(null);

    String defaultUserText;
    switch (languageCode) {
      case 'tr': defaultUserText = 'Kullanıcı'; break;
      case 'sr': defaultUserText = 'Korisnik'; break;
      case 'ru': defaultUserText = 'Пользователь'; break;
      default: defaultUserText = 'User'; break;
    }

    String youText;
    switch (languageCode) {
      case 'tr': youText = 'Siz'; break;
      case 'sr': youText = 'Vi'; break;
      case 'ru': youText = 'Вы'; break;
      default: youText = 'You'; break;
    }

    final landlordRoleText = loc.roleLandlord;
    final tenantRoleText = loc.roleTenant;
    String agencyRoleText;
    switch (languageCode) {
      case 'tr': agencyRoleText = 'Acente'; break;
      case 'sr': agencyRoleText = 'Agencija'; break;
      case 'ru': agencyRoleText = 'Агентство'; break;
      default: agencyRoleText = 'Agency'; break;
    }

    String senderName = isMe ? youText : defaultUserText;
    String roleLabel = defaultUserText;
    Color roleBadgeColor = StanomerColors.brandPrimary;
    IconData roleIcon = LucideIcons.user;

    // Determine role based on property IDs or profile role
    if (userId.isNotEmpty && userId == landlordId) {
      roleLabel = landlordRoleText;
      roleBadgeColor = const Color(0xFF10B981); // Emerald Green
      roleIcon = LucideIcons.home;
    } else if (userId.isNotEmpty && userId == tenantId) {
      roleLabel = tenantRoleText;
      roleBadgeColor = const Color(0xFF3B82F6); // Blue
      roleIcon = LucideIcons.user;
    } else if (userId.isNotEmpty && userId == agencyId) {
      roleLabel = agencyRoleText;
      roleBadgeColor = const Color(0xFF8B5CF6); // Purple
      roleIcon = LucideIcons.building;
    }

    profileAsync.whenData((profile) {
      if (profile != null) {
        final fn = (profile['full_name'] as String?)?.trim();
        final em = (profile['email'] as String?)?.trim();
        if (fn != null && fn.isNotEmpty) {
          senderName = fn;
        } else if (em != null && em.isNotEmpty) {
          senderName = em;
        }

        final userRole = (profile['role'] as String?)?.toLowerCase();
        if ((roleLabel == defaultUserText || roleLabel == 'Kullanıcı' || roleLabel == 'User') && userRole != null) {
          if (userRole == 'landlord') {
            roleLabel = landlordRoleText;
            roleBadgeColor = const Color(0xFF10B981);
            roleIcon = LucideIcons.home;
          } else if (userRole == 'tenant') {
            roleLabel = tenantRoleText;
            roleBadgeColor = const Color(0xFF3B82F6);
            roleIcon = LucideIcons.user;
          } else if (userRole == 'agency') {
            roleLabel = agencyRoleText;
            roleBadgeColor = const Color(0xFF8B5CF6);
            roleIcon = LucideIcons.building;
          }
        }
      }
    });

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Sender Header (Name & Role Badge)
          Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 4, right: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isMe) ...[
                  Text(
                    senderName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: roleBadgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: roleBadgeColor.withValues(alpha: 0.3), width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(roleIcon, size: 10, color: roleBadgeColor),
                      const SizedBox(width: 3),
                      Text(
                        roleLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: roleBadgeColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 6),
                  Text(
                    senderName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Message Bubble Container
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDescription 
                ? (isDark ? Colors.grey.shade800 : Colors.grey.shade100)
                : (isMe 
                    ? roleBadgeColor 
                    : (isDark ? const Color(0xFF1E293B) : Colors.grey.shade100)),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isDescription)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      AppLocalizations.of(context)!.issueDescription.toUpperCase(),
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                    ),
                  ),
                if (initialPhotos.isNotEmpty) ...[
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: initialPhotos.length,
                      itemBuilder: (context, idx) => Padding(
                        padding: const EdgeInsets.only(right: 8, bottom: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _InteractiveImage(url: initialPhotos[idx]),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (photoUrl != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _InteractiveImage(url: photoUrl!),
                    ),
                  ),
                ],
                if (message.isNotEmpty)
                  Text(
                    message,
                    style: TextStyle(
                      color: isDescription 
                        ? (isDark ? Colors.white : StanomerColors.textPrimary)
                        : (isMe ? Colors.white : (isDark ? Colors.white : StanomerColors.textPrimary)),
                      fontSize: 15,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('HH:mm').format(createdAt),
            style: const TextStyle(fontSize: 10, color: StanomerColors.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _InteractiveImage extends StatelessWidget {
  final String url;
  const _InteractiveImage({required this.url});

  bool get _isLocal => url.startsWith('local://');
  String get _localPath => url.replaceFirst('local://', '');

  Widget _buildImage({double? width, double? height, BoxFit fit = BoxFit.cover}) {
    if (_isLocal) {
      if (kIsWeb) {
        return Container(
          width: width ?? 100,
          height: height ?? 100,
          color: Colors.grey.shade300,
          child: const Icon(LucideIcons.imageOff, color: Colors.grey),
        );
      }
      return Image.file(
        io.File(_localPath),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => Container(
          width: width ?? 100,
          height: height ?? 100,
          color: Colors.grey.shade300,
          child: const Icon(LucideIcons.imageOff, color: Colors.grey),
        ),
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
          width: width ?? 100,
          height: height ?? 100,
          color: Colors.grey.shade200,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },
      errorBuilder: (_, __, ___) => Container(
        width: width ?? 100,
        height: height ?? 100,
        color: Colors.grey.shade300,
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
            backgroundColor: Colors.black,
            child: Stack(
              children: [
                Center(child: _buildImage(fit: BoxFit.contain)),
                Positioned(
                  top: 40,
                  right: 20,
                  child: IconButton(
                    icon: const Icon(LucideIcons.x, color: Colors.white, size: 30),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: _buildImage(width: 100, height: 100),
    );
  }
}
