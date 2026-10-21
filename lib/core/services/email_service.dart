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

  /// Sends a localized password reset email with a 6-digit verification code.
  static Future<bool> sendPasswordResetEmail({
    required String toEmail,
    required String toName,
    required String resetCode,
    String? resetToken,
    required String localeCode,
  }) async {
    final lang = localeCode.toLowerCase().split('_').first;
    final name = toName.trim().isNotEmpty ? toName.trim() : toEmail.split('@').first;

    String subject;
    String textContent;
    String greeting;
    String desc;
    String codeLabel;
    String warning;
    String footerText;

    if (lang == 'tr') {
      subject = 'Stanomer Doğrulama Kodu: $resetCode';
      greeting = 'Merhaba $name,';
      desc = 'Stanomer hesabınız için şifre sıfırlama talebinde bulundunuz. Şifrenizi yenilemek için aşağıdaki 6 haneli doğrulama kodunu uygulamadaki ekrana giriniz:';
      codeLabel = 'Doğrulama Kodunuz:';
      warning = 'Bu kod 1 saat boyunca geçerlidir. Bu talebi siz yapmadıysanız bu e-postayı güvenle silebilirsiniz; hesabınız korunmaktadır.';
      footerText = 'Stanomer &bull; Mülk Yönetim Platformu';
      textContent = '''$greeting

$desc

$codeLabel $resetCode

$warning
''';
    } else if (lang == 'ru') {
      subject = 'Stanomer Проверочный код: $resetCode';
      greeting = 'Здравствуйте, $name!';
      desc = 'Вы запросили сброс пароля для вашей учетной записи Stanomer. Введите следующий 6-значный проверочный код в приложении для обновления пароля:';
      codeLabel = 'Ваш проверочный код:';
      warning = 'Этот код действителен в течение 1 часа. Если вы не запрашивали сброс, просто проигнорируйте это письмо; ваш аккаунт в безопасности.';
      footerText = 'Stanomer &bull; Платформа управления недвижимостью';
      textContent = '''$greeting

$desc

$codeLabel $resetCode

$warning
''';
    } else if (lang == 'sr') {
      subject = 'Stanomer verifikacioni kod: $resetCode';
      greeting = 'Zdravo $name,';
      desc = 'Zatražili ste resetovanje lozinke za vaš Stanomer nalog. Unesite sledeći 6-cifreni verifikacioni kod u aplikaciju da biste promenili lozinku:';
      codeLabel = 'Vaš verifikacioni kod:';
      warning = 'Ovaj kod važi 1 sat. Ako niste zatražili promenu lozinke, možete bezbedno ignorisati ovu poruku; vaš nalog je siguran.';
      footerText = 'Stanomer &bull; Platforma za upravljanje nekretninama';
      textContent = '''$greeting

$desc

$codeLabel $resetCode

$warning
''';
    } else {
      // Default to English ('en')
      subject = 'Stanomer Verification Code: $resetCode';
      greeting = 'Hello $name,';
      desc = 'You requested to reset your Stanomer account password. Please enter the following 6-digit verification code in the app to proceed:';
      codeLabel = 'Your Verification Code:';
      warning = 'This code will expire in 1 hour. If you did not request a password reset, you can safely ignore this email; your account remains secure.';
      footerText = 'Stanomer &bull; Property Management Platform';
      textContent = '''$greeting

$desc

$codeLabel $resetCode

$warning
''';
    }

    final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; line-height: 1.6; color: #1e293b; margin: 0; padding: 24px; background-color: #f1f5f9; }
    .card { max-width: 520px; margin: 0 auto; background: #ffffff; border: 1px solid #e2e8f0; border-radius: 16px; padding: 32px; box-shadow: 0 4px 16px rgba(0,0,0,0.06); }
    .header { text-align: center; margin-bottom: 24px; }
    .brand { font-size: 24px; font-weight: 800; color: #0f172a; letter-spacing: -0.5px; }
    .brand span { color: #2563eb; }
    .greeting { font-size: 17px; font-weight: 600; color: #0f172a; margin-bottom: 12px; }
    .text { font-size: 15px; color: #475569; margin-bottom: 20px; line-height: 1.6; }
    .code-box { background: #f8fafc; border: 2px dashed #cbd5e1; border-radius: 12px; padding: 24px; text-align: center; margin: 24px 0; }
    .code-label { font-size: 12px; font-weight: 600; text-transform: uppercase; letter-spacing: 1px; color: #64748b; margin-bottom: 8px; }
    .code-value { font-family: ui-monospace, Menlo, Monaco, "Courier New", monospace; font-size: 38px; font-weight: 800; letter-spacing: 10px; color: #1e293b; margin: 0; }
    .warning { font-size: 13px; color: #94a3b8; border-top: 1px solid #f1f5f9; padding-top: 18px; margin-top: 24px; }
    .footer { font-size: 12px; color: #94a3b8; text-align: center; margin-top: 24px; }
  </style>
</head>
<body>
  <div class="card">
    <div class="header">
      <div class="brand">Stano<span>mer</span></div>
    </div>
    <div class="greeting">$greeting</div>
    <div class="text">$desc</div>
    
    <div class="code-box">
      <div class="code-label">$codeLabel</div>
      <div class="code-value">$resetCode</div>
    </div>

    <div class="warning">$warning</div>
  </div>
  <div class="footer">$footerText</div>
</body>
</html>
''';

    return sendEmail(
      toEmail: toEmail,
      toName: toName,
      subject: subject,
      textContent: textContent,
      htmlContent: htmlContent,
    );
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

