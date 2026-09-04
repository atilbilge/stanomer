import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/env_config.dart';

class EmailService {
  /// Sends a transactional email using Brevo (Sendinblue) REST API.
  static Future<bool> sendEmail({
    required String toEmail,
    required String toName,
    required String subject,
    required String textContent,
    String? htmlContent,
    String? replyToEmail,
    String? replyToName,
  }) async {
    final apiKey = EnvConfig.brevoApiKey;
    if (apiKey.isEmpty) {
      debugPrint('[EmailService] Brevo API key is not configured.');
      return false;
    }

    final trimmedToEmail = toEmail.trim();
    if (trimmedToEmail.isEmpty || !trimmedToEmail.contains('@')) {
      debugPrint('[EmailService] Invalid recipient email: $toEmail');
      return false;
    }

    try {
      final payload = <String, dynamic>{
        'sender': {
          'name': EnvConfig.brevoSenderName,
          'email': EnvConfig.brevoSenderEmail,
        },
        'to': [
          {
            'email': trimmedToEmail,
            'name': toName.trim().isNotEmpty ? toName.trim() : trimmedToEmail,
          }
        ],
        'subject': subject,
        'textContent': textContent,
      };

      if (replyToEmail != null && replyToEmail.trim().isNotEmpty && replyToEmail.contains('@')) {
        payload['replyTo'] = {
          'email': replyToEmail.trim(),
          if (replyToName != null && replyToName.trim().isNotEmpty)
            'name': replyToName.trim(),
        };
      }

      final generatedHtml = htmlContent ?? _generateBasicHtml(textContent);
      payload['htmlContent'] = generatedHtml;

      final response = await http.post(
        Uri.parse('https://api.brevo.com/v3/smtp/email'),
        headers: {
          'accept': 'application/json',
          'content-type': 'application/json',
          'api-key': apiKey,
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('[EmailService] Brevo email sent successfully: ${response.body}');
        return true;
      } else {
        debugPrint('[EmailService] Brevo API error (${response.statusCode}): ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('[EmailService] Exception while sending email via Brevo: $e');
      return false;
    }
  }

  static String _generateBasicHtml(String text) {
    final escaped = const HtmlEscape().convert(text);
    final withBreaks = escaped.replaceAll('\n', '<br/>');
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; line-height: 1.6; color: #1e293b; margin: 0; padding: 24px; background-color: #f8fafc; }
    .card { max-width: 580px; margin: 0 auto; background: #ffffff; border: 1px solid #e2e8f0; border-radius: 12px; padding: 28px; box-shadow: 0 2px 8px rgba(0,0,0,0.04); }
    .content { font-size: 15px; color: #334155; }
    .footer { margin-top: 28px; padding-top: 16px; border-top: 1px solid #e2e8f0; font-size: 12px; color: #94a3b8; text-align: center; }
  </style>
</head>
<body>
  <div class="card">
    <div class="content">
      $withBreaks
    </div>
    <div class="footer">
      Stanomer &bull; Mülk Yönetim Platformu
    </div>
  </div>
</body>
</html>
''';
  }
}
