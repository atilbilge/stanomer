import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/notification_item.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(Supabase.instance.client);
});

final notificationsStreamProvider = StreamProvider.autoDispose<List<NotificationItem>>((ref) {
  final repo = ref.watch(notificationRepositoryProvider);
  return repo.streamNotifications();
});

final unreadNotificationsCountProvider = Provider.autoDispose<int>((ref) {
  final notifications = ref.watch(notificationsStreamProvider).value ?? [];
  return notifications.where((n) => !n.isRead).length;
});

class NotificationRepository {
  final SupabaseClient _client;

  NotificationRepository(this._client);

  Stream<List<NotificationItem>> streamNotifications() {
    final user = _client.auth.currentUser;
    if (user == null) return Stream.value([]);

    // We also trigger a cleanup of old notifications (>1 month) when streaming starts
    _client.rpc('delete_old_notifications').then((_) => null).catchError((_) => null);

    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .cast<dynamic>()
        .map((data) => (data as List).map((json) => NotificationItem.fromJson(json as Map<String, dynamic>)).toList());
  }

  Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    String? relatedId,
  }) async {
    await _client.from('notifications').insert({
      'user_id': userId,
      'title': title,
      'body': body,
      'type': type.name,
      'related_id': relatedId,
      'is_read': false,
    });
  }

  Future<void> markAsRead(String notificationId) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  Future<void> markAllAsRead() async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', user.id)
        .eq('is_read', false);
  }

  Future<void> deleteNotification(String notificationId) async {
    await _client.from('notifications').delete().eq('id', notificationId);
  }
}
