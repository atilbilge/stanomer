// lib/features/agency/data/agency_repository.dart
// Fetches agency profile data from Supabase profiles table

import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/agency_profile.dart';

class AgencyRepository {
  final SupabaseClient _client;

  AgencyRepository(this._client);

  /// Fetches agency profile by agency_id (profiles.id where role = 'agency')
  Future<AgencyProfile?> getAgencyProfile(String agencyId) async {
    try {
      final data = await _client
          .from('profiles')
          .select('id, full_name, company_name, logo_url, email, color_scheme')
          .eq('id', agencyId)
          .maybeSingle();

      if (data == null) return null;
      return AgencyProfile.fromJson(data);
    } catch (e, stack) {
      print('ERROR [AgencyRepository.getAgencyProfile]: $e\n$stack');
      return null;
    }
  }

  /// Fetches all properties managed by this agency
  Future<List<Map<String, dynamic>>> getAgencyProperties(String agencyId) async {
    final data = await _client
        .from('properties')
        .select('*, landlord:profiles!landlord_id(full_name, email), tenant:profiles!tenant_id(full_name, email)')
        .eq('agency_id', agencyId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  /// Fetches pending rent payments for properties managed by this agency
  Future<List<Map<String, dynamic>>> getAgencyPendingPayments(String agencyId) async {
    // Get all property IDs first
    final properties = await getAgencyProperties(agencyId);
    final propertyIds = properties.map((p) => p['id'] as String).toList();

    if (propertyIds.isEmpty) return [];

    final data = await _client
        .from('rent_payments')
        .select('*, property:properties(*, landlord:profiles!landlord_id(full_name, email), tenant:profiles!tenant_id(full_name, email)), tenant:profiles!tenant_id(full_name, email, phone_number)')
        .inFilter('property_id', propertyIds)
        .eq('status', 'declared')
        .order('due_date');

    return List<Map<String, dynamic>>.from(data);
  }

  /// Fetches ALL rent payments (pending, declared, paid, overdue, disputed) for properties managed by this agency
  Future<List<Map<String, dynamic>>> getAgencyAllPayments(String agencyId) async {
    final properties = await getAgencyProperties(agencyId);
    final propertyIds = properties.map((p) => p['id'] as String).toList();

    if (propertyIds.isEmpty) return [];

    final data = await _client
        .from('rent_payments')
        .select('*, property:properties(*, landlord:profiles!landlord_id(full_name, email), tenant:profiles!tenant_id(full_name, email)), tenant:profiles!tenant_id(full_name, email, phone_number)')
        .inFilter('property_id', propertyIds)
        .order('due_date', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  /// Fetches all properties owned by this landlord
  Future<List<Map<String, dynamic>>> getLandlordProperties(String landlordId) async {
    final data = await _client
        .from('properties')
        .select('*, landlord:profiles!landlord_id(full_name, email), tenant:profiles!tenant_id(full_name, email)')
        .eq('landlord_id', landlordId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  /// Fetches pending rent payments for properties owned by this landlord
  Future<List<Map<String, dynamic>>> getLandlordPendingPayments(String landlordId) async {
    final properties = await getLandlordProperties(landlordId);
    final propertyIds = properties.map((p) => p['id'] as String).toList();

    if (propertyIds.isEmpty) return [];

    final data = await _client
        .from('rent_payments')
        .select('*, property:properties(*, landlord:profiles!landlord_id(full_name, email), tenant:profiles!tenant_id(full_name, email)), tenant:profiles!tenant_id(full_name, email, phone_number)')
        .inFilter('property_id', propertyIds)
        .eq('status', 'declared')
        .order('due_date');

    return List<Map<String, dynamic>>.from(data);
  }

  /// Fetches ALL rent payments for properties owned by this landlord
  Future<List<Map<String, dynamic>>> getLandlordAllPayments(String landlordId) async {
    final properties = await getLandlordProperties(landlordId);
    final propertyIds = properties.map((p) => p['id'] as String).toList();

    if (propertyIds.isEmpty) return [];

    final data = await _client
        .from('rent_payments')
        .select('*, property:properties(*, landlord:profiles!landlord_id(full_name, email), tenant:profiles!tenant_id(full_name, email)), tenant:profiles!tenant_id(full_name, email, phone_number)')
        .inFilter('property_id', propertyIds)
        .order('due_date', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  /// Marks a payment as cash paid directly by agency
  Future<void> markPaymentAsCashPaid(String paymentId) async {
    await _client.from('rent_payments').update({
      'status': 'paid',
      'declared_at': DateTime.now().toIso8601String(),
    }).eq('id', paymentId);
  }

  /// Approves a declared payment as paid
  Future<void> approvePayment(String paymentId) async {
    await _client.from('rent_payments').update({
      'status': 'paid',
      'paid_at': DateTime.now().toIso8601String(),
    }).eq('id', paymentId);
  }

  /// Rejects a declared payment back to pending
  Future<void> rejectPayment(String paymentId, {String? reason}) async {
    await _client.from('rent_payments').update({
      'status': 'pending',
      'receipt_url': null,
      'declared_at': null,
      'dispute_reason': reason,
    }).eq('id', paymentId);
  }
}
