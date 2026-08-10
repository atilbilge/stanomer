import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final agencyDemoServiceProvider = Provider((ref) => AgencyDemoService());

class AgencyDemoService {
  final SupabaseClient _supabase;

  AgencyDemoService([SupabaseClient? supabase])
      : _supabase = supabase ?? Supabase.instance.client;

  Future<bool> submitDemoRequest({
    required String agencyName,
    required String email,
    String? website,
    String? phoneNumber,
    String? specialRequests,
  }) async {
    try {
      await _supabase.from('agency_demo_requests').insert({
        'agency_name': agencyName.trim(),
        'email': email.trim().toLowerCase(),
        'website': website?.trim(),
        'phone_number': phoneNumber?.trim(),
        'special_requests': specialRequests?.trim(),
        'status': 'pending',
      });
      return true;
    } catch (e) {
      debugPrint('Agency Demo Request Submission Error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> verifyDemoToken(String token) async {
    try {
      final response = await _supabase.rpc(
        'verify_agency_demo_token',
        params: {'p_token': token},
      );
      return Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint('Agency Demo Token Verification Error: $e');
      return {
        'success': false,
        'message': 'Doğrulama sırasında hata oluştu: $e',
      };
    }
  }
}

