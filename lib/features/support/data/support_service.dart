import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:universal_io/io.dart';

final supportServiceProvider = Provider((ref) => SupportService());

class SupportService {
  Future<bool> sendTicket({
    required String subject,
    required String email,
    required String category,
    required String message,
  }) async {
    try {
      final Uri url;
      if (kIsWeb) {
        final uriBase = Uri.base;
        if (uriBase.host == 'localhost') {
          url = Uri.parse('https://stanomer.vercel.app/api/notion');
        } else {
          url = Uri.parse('/api/notion');
        }
      } else {
        url = Uri.parse('https://stanomer.vercel.app/api/notion');
      }

      String platform = 'Unknown';
      if (kIsWeb) {
        platform = 'Web';
      } else if (Platform.isAndroid) {
        platform = 'Android';
      } else if (Platform.isIOS) {
        platform = 'iOS';
      }

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'subject': subject,
          'email': email,
          'category': category,
          'message': message,
          'platform': platform,
          'appVersion': '1.1.0',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        debugPrint('Notion API Error: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Support Service Error: $e');
      return false;
    }
  }
}
