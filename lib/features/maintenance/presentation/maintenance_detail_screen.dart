import 'dart:typed_data';
import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/colors.dart';
import '../../property/domain/property.dart';
import '../../auth/data/auth_providers.dart';
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

      if (result != null) {
        final platformFile = result.files.single;
        List<int>? fileBytes = platformFile.bytes?.toList();
        
        if (fileBytes == null && platformFile.path != null) {
          fileBytes = await io.File(platformFile.path!).readAsBytes();
        }

        if (fileBytes == null) return;

        setState(() => _isSending = true);
        
        final url = await ref.read(maintenanceRepositoryProvider).uploadMaintenancePhoto(
          requestId: widget.request.id,
          fileName: platformFile.name,
          bytes: Uint8List.fromList(fileBytes),
        );

        await _sendMessage(photoUrl: url);
      }
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
    final isLandlord = widget.property.landlordId == user?.id;
    final isTenant = widget.property.tenantId == user?.id;
    
    final requestsAsync = ref.watch(maintenanceRequestsProvider(widget.property.id));
    final liveRequest = requestsAsync.maybeWhen(
      data: (list) => list.firstWhere((r) => r.id == widget.request.id, orElse: () => widget.request),
      orElse: () => widget.request,
    );

    final roleColor = StanomerColors.getRoleColor(isLandlord ? 'landlord' : (isTenant ? 'tenant' : null));
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
                      message: liveRequest.description ?? '',
                      isMe: liveRequest.reporterId == user?.id,
                      createdAt: liveRequest.createdAt ?? DateTime.now(),
                      isDescription: true,
                      initialPhotos: liveRequest.photosUrls,
                      roleColor: liveRequest.reporterId == widget.property.landlordId ? StanomerColors.landlord : StanomerColors.tenant,
                    ),
                  ...messages.map((m) {
                    final isSenderLandlord = m.userId == widget.property.landlordId;
                    return _MessageBubble(
                      message: m.message,
                      photoUrl: m.photoUrl,
                      isMe: m.userId == user?.id,
                      createdAt: m.createdAt,
                      roleColor: isSenderLandlord ? StanomerColors.landlord : StanomerColors.tenant,
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
            _buildResolvedFooter(liveRequest, isTenant, loc, roleColor)
          else
            _buildMessageInput(loc, roleColor),
          if (isLandlord && liveRequest.status != MaintenanceStatus.resolved)
            _buildLandlordActions(liveRequest, loc, roleColor),
        ],
      ),
    );
  }

  Widget _buildHeader(MaintenanceRequest request, AppLocalizations loc) {
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

  Widget _buildLandlordActions(MaintenanceRequest request, AppLocalizations loc, Color roleColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: Row(
        children: [
          if (request.status == MaintenanceStatus.open) ...[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _updateStatus(ref, MaintenanceStatus.investigating),
                icon: const Icon(LucideIcons.search, size: 18),
                label: Text(loc.statusInvestigating),
                style: OutlinedButton.styleFrom(
                  foregroundColor: roleColor,
                  side: BorderSide(color: roleColor),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _updateStatus(ref, MaintenanceStatus.resolved),
              style: ElevatedButton.styleFrom(
                backgroundColor: roleColor,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(LucideIcons.check, size: 18),
              label: Text(loc.statusResolved),
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
      case MaintenanceCategory.other: return loc.categoryOther;
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

class _MessageBubble extends StatelessWidget {
  final String message;
  final String? photoUrl;
  final bool isMe;
  final DateTime createdAt;
  final bool isDescription;
  final List<String> initialPhotos;
  final Color roleColor;

  const _MessageBubble({
    required this.message,
    this.photoUrl,
    required this.isMe,
    required this.createdAt,
    this.isDescription = false,
    this.initialPhotos = const [],
    this.roleColor = StanomerColors.brandPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDescription 
                ? (isDark ? Colors.grey.shade800 : Colors.grey.shade100)
                : roleColor,
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
                      color: (isDescription && !isDark) ? StanomerColors.textPrimary : Colors.white,
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
                Center(child: Image.network(url)),
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
      child: Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 100,
            height: 100,
            color: Colors.grey.shade200,
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        },
      ),
    );
  }
}
