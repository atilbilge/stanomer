import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/colors.dart';
import '../data/notification_repository.dart';
import '../domain/notification_item.dart';
import '../../property/data/property_repository.dart';
import '../../maintenance/data/maintenance_repository.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/data/auth_providers.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/connection_status_indicator.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final notificationsAsync = ref.watch(notificationsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.notifications),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.checkCheck),
            tooltip: loc.markAllAsRead,
            onPressed: () => ref.read(notificationRepositoryProvider).markAllAsRead(),
          ),
        ],
      ),
      body: Column(
        children: [
          ConnectionStatusIndicator(
            hasError: notificationsAsync.hasError,
            onRetry: () => ref.invalidate(notificationsStreamProvider),
          ),
          Expanded(
            child: () {
              if (notificationsAsync.hasValue) {
                final notifications = notificationsAsync.value!;
                if (notifications.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.bellOff, size: 48, color: StanomerColors.textTertiary),
                        const SizedBox(height: 16),
                        Text(
                          loc.noNotifications,
                          style: const TextStyle(color: StanomerColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifications.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = notifications[index];
                    return _NotificationTile(item: item);
                  },
                );
              } else if (notificationsAsync.hasError) {
                return AppErrorView(
                  error: notificationsAsync.error!,
                  onRetry: () => ref.invalidate(notificationsStreamProvider),
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

class _NotificationTile extends ConsumerStatefulWidget {
  final NotificationItem item;
  const _NotificationTile({required this.item});

  @override
  ConsumerState<_NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends ConsumerState<_NotificationTile> {
  bool _isNavigating = false;

  Future<void> _ensureCorrectRole(String? propertyId, {String? forceRole}) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final currentRole = user.userMetadata?['role'];
    
    if (forceRole != null) {
      if (currentRole != forceRole) {
        await ref.read(authRepositoryProvider).updateProfile(role: forceRole);
      }
      return;
    }

    if (propertyId == null) return;

    // Try to find the property to determine the user's relationship to it
    final properties = await ref.read(propertiesFutureProvider.future);
    final property = properties.where((p) => p.id == propertyId).firstOrNull;

    if (property != null) {
      final targetRole = (property.landlordId == user.id) ? 'landlord' : 'tenant';
      if (currentRole != targetRole) {
        await ref.read(authRepositoryProvider).updateProfile(role: targetRole);
      }
    }
  }

  Future<void> _onTap() async {
    final loc = AppLocalizations.of(context)!;
    // 1. Mark as read
    if (!widget.item.isRead) {
      ref.read(notificationRepositoryProvider).markAsRead(widget.item.id);
    }

    if (widget.item.relatedId == null) return;

    setState(() => _isNavigating = true);
    
    try {
      final relatedId = widget.item.relatedId!;
      
      if (widget.item.type == NotificationType.maintenance) {
        final maintenanceRepo = ref.read(maintenanceRepositoryProvider);
        final request = await maintenanceRepo.getMaintenanceRequest(relatedId);
        
        if (request != null && mounted) {
          final properties = await ref.read(propertiesFutureProvider.future);
          final prop = properties.where((p) => p.id == request.propertyId).firstOrNull;
          
          if (prop != null && mounted) {
            await _ensureCorrectRole(prop.id);
            if (mounted) {
              context.push('/maintenance/detail', extra: {
                'property': prop,
                'request': request,
              });
            }
            return;
          }
        }
      } else if (widget.item.type == NotificationType.contract) {
        // Try to treat relatedId as a token first (Tenant Welcome/Acceptance case)
        try {
          final inviteData = await ref.read(propertyRepositoryProvider).getInviteByToken(relatedId);
          if (mounted) {
            await _ensureCorrectRole(null, forceRole: 'tenant');
            if (mounted) {
              context.push('/invite?token=$relatedId');
            }
            return;
          }
        } catch (e) {
          // Fallback: If not a token, it's a property ID (e.g., landlord's notification)
          await _ensureCorrectRole(relatedId);
          final properties = await ref.read(propertiesFutureProvider.future);
          final property = properties.where((p) => p.id == relatedId).firstOrNull;
          if (property != null && mounted) {
            context.push('/property-detail', extra: {
              'property': property,
              'initialTabIndex': 0, // Overview
            });
            return;
          }

          // EXTRA FALLBACK: If property not found in list, check pending invites explicitly
          final pendingInvites = await ref.read(pendingInvitesForUserProvider.future);
          final matchingInvite = pendingInvites.where((inv) {
            final p = inv['properties'] as Map<String, dynamic>?;
            return p?['id'] == relatedId;
          }).firstOrNull;

          if (matchingInvite != null && matchingInvite['token'] != null && mounted) {
            final token = matchingInvite['token'] as String;
            context.push('/invite?token=$token');
            return;
          }
        }
      } else if (widget.item.type == NotificationType.rent) {
        // For rent, we navigate to the property detail financials tab
        await _ensureCorrectRole(relatedId);
        final properties = await ref.read(propertiesFutureProvider.future);
        final property = properties.where((p) => p.id == relatedId).firstOrNull;
        
        if (property != null && mounted) {
          context.push('/property-detail', extra: {
            'property': property,
            'initialTabIndex': 1, // Financials
          });
          return;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.errorOpeningDetails(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _isNavigating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = widget.item.createdAt != null 
        ? DateFormat('dd MMM, HH:mm').format(widget.item.createdAt!) 
        : '';

    IconData icon;
    Color iconColor;
    switch (widget.item.type) {
      case NotificationType.rent:
        icon = LucideIcons.wallet;
        iconColor = Colors.green;
        break;
      case NotificationType.maintenance:
        icon = LucideIcons.wrench;
        iconColor = Colors.orange;
        break;
      case NotificationType.contract:
        icon = LucideIcons.fileText;
        iconColor = StanomerColors.brandPrimary;
        break;
    }

    return ListTile(
      onTap: _isNavigating ? null : _onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: iconColor),
      ),
      title: Text(
        widget.item.title,
        style: TextStyle(
          fontWeight: widget.item.isRead ? FontWeight.normal : FontWeight.bold,
          fontSize: 14,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(
            widget.item.body,
            style: TextStyle(
              color: widget.item.isRead ? StanomerColors.textTertiary : StanomerColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            date,
            style: const TextStyle(fontSize: 11, color: StanomerColors.textTertiary),
          ),
        ],
      ),
      trailing: _isNavigating 
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : (!widget.item.isRead ? Container(width: 8, height: 8, decoration: const BoxDecoration(color: StanomerColors.brandPrimary, shape: BoxShape.circle)) : null),
    );
  }
}
