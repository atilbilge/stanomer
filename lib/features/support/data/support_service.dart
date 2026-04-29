import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:universal_io/io.dart';

final supportServiceProvider = Provider((ref) => SupportService());

class SupportService {
  static const String _notionToken = String.fromEnvironment('NOTION_TOKEN');
  static const String _databaseId = String.fromEnvironment('NOTION_DATABASE_ID');

  Future<bool> sendTicket({
    required String subject,
    required String email,
    required String category,
    required String message,
  }) async {
    try {
      final url = Uri.parse('https://api.notion.com/v1/pages');
      
      String platform = 'Unknown';
      if (kIsWeb) {
        platform = 'Web';
      } else if (Platform.isAndroid) {
        platform = 'Android';
      } else if (Platform.isIOS) {
        platform = 'iOS';
      }

      final dateStr = DateTime.now().toIso8601String().split('T')[0];

      final body = {
        'parent': {'database_id': _databaseId},
        'properties': {
          'Subject': {
            'title': [
              {
                'text': {'content': subject}
              }
            ]
          },
          'User Email': {'email': email},
          'Category': {
            'rich_text': [
              {
                'text': {'content': category}
              }
            ]
          },
          'Message': {
            'rich_text': [
              {
                'text': {'content': message}
              }
            ]
          },
          'Status': {
            'rich_text': [
              {
                'text': {'content': 'Open'}
              }
            ]
          },
          'Priority': {
            'rich_text': [
              {
                'text': {'content': 'Normal'}
              }
            ]
          },
          'Platform': {
            'rich_text': [
              {
                'text': {'content': platform}
              }
            ]
          },
          'App Version': {
            'rich_text': [
              {
                'text': {'content': '1.1.0'}
              }
            ]
          },
          'Created Date': {
            'date': {'start': dateStr}
          }
        }
      };

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $_notionToken',
          'Notion-Version': '2022-06-28',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
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
