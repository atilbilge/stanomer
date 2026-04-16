import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/data/auth_providers.dart';
import '../domain/maintenance_request.dart';
import '../domain/maintenance_message.dart';

final maintenanceRepositoryProvider = Provider<MaintenanceRepository>((ref) {
  return MaintenanceRepository(Supabase.instance.client);
});

final maintenanceRequestsProvider = StreamProvider.autoDispose.family<List<MaintenanceRequest>, String>((ref, propertyId) {
  final repo = ref.watch(maintenanceRepositoryProvider);
  return repo.getMaintenanceRequestsStream(propertyId);
});

final maintenanceMessagesProvider = StreamProvider.autoDispose.family<List<MaintenanceMessage>, String>((ref, requestId) {
  final repo = ref.watch(maintenanceRepositoryProvider);
  return repo.getMaintenanceMessagesStream(requestId);
});

class MaintenanceRepository {
  final SupabaseClient _client;

  MaintenanceRepository(this._client);

  Stream<List<MaintenanceRequest>> getMaintenanceRequestsStream(String propertyId) {
    return _client
        .from('maintenance_requests')
        .stream(primaryKey: ['id'])
        .eq('property_id', propertyId)
        .order('created_at', ascending: false)
        .cast<dynamic>()
        .map((data) => (data as List).map((json) => MaintenanceRequest.fromJson(json as Map<String, dynamic>)).toList());
  }

  Future<MaintenanceRequest?> getMaintenanceRequest(String requestId) async {
    final response = await _client
        .from('maintenance_requests')
        .select()
        .eq('id', requestId)
        .maybeSingle();
    
    if (response == null) return null;
    return MaintenanceRequest.fromJson(response);
  }

  Stream<List<MaintenanceMessage>> getMaintenanceMessagesStream(String requestId) {
    return _client
        .from('maintenance_messages')
        .stream(primaryKey: ['id'])
        .eq('request_id', requestId)
        .order('created_at', ascending: true)
        .cast<dynamic>()
        .map((data) => (data as List).map((json) => MaintenanceMessage.fromJson(json as Map<String, dynamic>)).toList());
  }

  Future<String> uploadMaintenancePhoto({
    required String requestId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final extension = fileName.split('.').last.toLowerCase();
    final contentType = extension == 'pdf' ? 'application/pdf' : 'image/$extension';
    final path = '${user.id}/${requestId}_${DateTime.now().millisecondsSinceEpoch}.$extension';

    await _client.storage.from('maintenance').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType),
        );

    return _client.storage.from('maintenance').getPublicUrl(path);
  }

  Future<void> createRequest({
    required String propertyId,
    required String title,
    required MaintenanceCategory category,
    required MaintenancePriority priority,
    String? description,
    String? contractId,
    List<String>? photosUrls,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final data = await _client.from('maintenance_requests').insert({
      'property_id': propertyId,
      'reporter_id': user.id,
      'contract_id': contractId,
      'title': title,
      'category': category.name,
      'priority': priority.name,
      'description': description,
      'status': 'open',
      'photos_urls': photosUrls ?? [],
    }).select().single();

    await _logActivity(
      propertyId: propertyId,
      type: 'maintenance_created',
      metadata: {
        'request_id': data['id'],
        'title': title,
        'has_photos': (photosUrls?.length ?? 0) > 0,
      },
    );

    final landlordId = await _getLandlordId(propertyId);
    await _createNotification(
      userId: landlordId,
      title: 'New Maintenance Request',
      body: 'A new maintenance request has been submitted: $title',
      type: 'maintenance',
      relatedId: data['id'],
    );
  }

  Future<void> updateStatus(String requestId, String propertyId, MaintenanceStatus newStatus) async {
    await _client
        .from('maintenance_requests')
        .update({'status': newStatus.name})
        .eq('id', requestId);

    await _logActivity(
      propertyId: propertyId,
      type: 'maintenance_status_updated',
      metadata: {
        'request_id': requestId,
        'new_status': newStatus.name,
      },
    );

    final reporterId = await _getReporterId(requestId);
    await _createNotification(
      userId: reporterId,
      title: 'Maintenance Update',
      body: 'Your maintenance request status has been updated to ${newStatus.name}',
      type: 'maintenance',
      relatedId: requestId,
    );
  }

  Future<void> deleteRequest(String requestId, String propertyId) async {
    await _client.from('maintenance_requests').delete().eq('id', requestId);
    
    await _logActivity(
      propertyId: propertyId,
      type: 'maintenance_deleted',
      metadata: {
        'request_id': requestId,
      },
    );
  }

  Future<void> addMessage(String requestId, String propertyId, String message, {String? photoUrl}) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _client.from('maintenance_messages').insert({
      'request_id': requestId,
      'user_id': user.id,
      'message': message,
      'photo_url': photoUrl,
    });

    await _logActivity(
      propertyId: propertyId,
      type: 'maintenance_message_added',
      metadata: {
        'request_id': requestId,
        'has_photo': photoUrl != null,
        'message_preview': message.isEmpty ? (photoUrl != null ? '[Photo]' : '') : (message.length > 50 ? '${message.substring(0, 47)}...' : message),
      },
    );

    final landlordId = await _getLandlordId(propertyId);
    final reporterId = await _getReporterId(requestId);
    final recipientId = (user.id == landlordId) ? reporterId : landlordId;

    await _createNotification(
      userId: recipientId,
      title: 'Arıza Kaydı Yorumu',
      body: message.isEmpty ? (photoUrl != null ? 'Bir fotoğraf gönderdi' : '') : (message.length > 50 ? '${message.substring(0, 47)}...' : message),
      type: 'maintenance',
      relatedId: requestId,
    );
  }

  Future<void> reopenRequest(String requestId, String propertyId) async {
    await _client
        .from('maintenance_requests')
        .update({'status': 'open'})
        .eq('id', requestId);

    await _logActivity(
      propertyId: propertyId,
      type: 'maintenance_reopened',
      metadata: {
        'request_id': requestId,
      },
    );

    final landlordId = await _getLandlordId(propertyId);
    await _createNotification(
      userId: landlordId,
      title: 'Request Reopened',
      body: 'A maintenance request has been reopened.',
      type: 'maintenance',
      relatedId: requestId,
    );
  }

  Future<void> _logActivity({
    required String propertyId,
    required String type,
    required Map<String, dynamic> metadata,
  }) async {
    final user = _client.auth.currentUser;
    await _client.from('activity_logs').insert({
      'property_id': propertyId,
      'user_id': user?.id,
      'type': type,
      'metadata': metadata,
    });
  }

  Future<void> _createNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    String? relatedId,
  }) async {
    // Don't notify the user about their own action
    final currentUser = _client.auth.currentUser;
    if (currentUser?.id == userId) return;

    await _client.from('notifications').insert({
      'user_id': userId,
      'title': title,
      'body': body,
      'type': type,
      'related_id': relatedId,
    });
  }

  Future<String> _getLandlordId(String propertyId) async {
    final data = await _client.from('properties').select('landlord_id').eq('id', propertyId).single();
    return data['landlord_id'] as String;
  }

  Future<String> _getReporterId(String requestId) async {
    final data = await _client.from('maintenance_requests').select('reporter_id').eq('id', requestId).single();
    return data['reporter_id'] as String;
  }
}
