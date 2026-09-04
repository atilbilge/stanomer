import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/services/email_service.dart';
import '../../../../core/theme/colors.dart';
import '../../../agency/domain/agency_color_scheme.dart';
import '../../../agency/presentation/agency_dashboard_screen.dart';
import '../../../auth/data/auth_providers.dart';
import '../../data/property_repository.dart';

class TenantInviteShareSheet extends ConsumerStatefulWidget {
  final String propertyName;
  final String tenantName;
  final String tenantEmail;
  final String token;
  final String? propertyId;
  final String? propertyAddress;
  final String? contractId;
  final double? monthlyRent;
  final String? currency;
  final double? depositAmount;
  final DateTime? startDate;
  final VoidCallback? onInviteSent;

  const TenantInviteShareSheet({
    super.key,
    required this.propertyName,
    required this.tenantName,
    required this.tenantEmail,
    required this.token,
    this.propertyId,
    this.propertyAddress,
    this.contractId,
    this.monthlyRent,
    this.currency,
    this.depositAmount,
    this.startDate,
    this.onInviteSent,
  });

  static Future<void> show(
    BuildContext context, {
    required String propertyName,
    required String tenantName,
    required String tenantEmail,
    required String token,
    String? propertyId,
    String? propertyAddress,
    String? contractId,
    double? monthlyRent,
    String? currency,
    double? depositAmount,
    DateTime? startDate,
    VoidCallback? onInviteSent,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TenantInviteShareSheet(
        propertyName: propertyName,
        tenantName: tenantName,
        tenantEmail: tenantEmail,
        token: token,
        propertyId: propertyId,
        propertyAddress: propertyAddress,
        contractId: contractId,
        monthlyRent: monthlyRent,
        currency: currency,
        depositAmount: depositAmount,
        startDate: startDate,
        onInviteSent: onInviteSent,
      ),
    );
  }

  static ({String subject, String body, String html}) buildTenantInviteEmail({
    required String agencyName,
    required String agencyEmail,
    required String address,
    required String tenantName,
    required String tenantEmail,
    double? monthlyRent,
    String? currency,
    double? depositAmount,
    DateTime? startDate,
    String languageCode = 'tr',
  }) {
    final s = _TenantEmailPreviewStrings.forLang(languageCode);

    final effectiveAddress = address.trim().isNotEmpty ? address.trim() : s.addressFallback;
    final effectiveTenantName = tenantName.trim().isNotEmpty ? tenantName.trim() : s.tenantFallback;
    final effectiveAgencyName = agencyName.trim().isNotEmpty ? agencyName.trim() : s.agencyFallback;
    final effectiveEmail = tenantEmail.trim();
    final effectiveAgencyEmail = agencyEmail.trim().isNotEmpty ? agencyEmail.trim() : 'info@stanomer.online';

    final subject = s.getSubject(effectiveAddress);

    final rentInfo = (monthlyRent != null && monthlyRent > 0)
        ? '${monthlyRent.toStringAsFixed(0)} ${currency ?? "EUR"}'
        : null;

    final depositInfo = (depositAmount != null && depositAmount > 0)
        ? '${depositAmount.toStringAsFixed(0)} ${currency ?? "EUR"}'
        : null;

    final startDateFormatted = startDate != null
        ? DateFormat('dd/MM/yyyy').format(startDate)
        : null;

    final termsSummary = [
      if (rentInfo != null) '• ${s.monthlyRentLabel}: $rentInfo',
      if (depositInfo != null) '• ${s.depositLabel}: $depositInfo',
      if (startDateFormatted != null) '• ${s.startDateLabel}: $startDateFormatted',
    ].join('\n');

    final hasTerms = rentInfo != null || depositInfo != null || startDateFormatted != null;
    final termsHtmlTable = hasTerms
        ? '''
              <table role="presentation" cellpadding="0" cellspacing="0" width="100%" style="background-color:#f4f6f8; border-radius:6px; margin:20px 0;">
                <tr>
                  <td style="padding:16px 20px;">
                    <p style="margin:0 0 8px 0; font-weight:bold; color:#1a5eb8;">${s.agreementSummaryTitle}</p>
                    <table role="presentation" cellpadding="0" cellspacing="0" width="100%" style="font-size:14px; color:#333333;">
                      ${rentInfo != null ? '<tr><td style="padding:4px 0;">${s.monthlyRentLabel}</td><td style="padding:4px 0; text-align:right; font-weight:bold;">$rentInfo</td></tr>' : ''}
                      ${depositInfo != null ? '<tr><td style="padding:4px 0;">${s.depositLabel}</td><td style="padding:4px 0; text-align:right; font-weight:bold;">$depositInfo</td></tr>' : ''}
                      ${startDateFormatted != null ? '<tr><td style="padding:4px 0;">${s.startDateLabel}</td><td style="padding:4px 0; text-align:right; font-weight:bold;">$startDateFormatted</td></tr>' : ''}
                    </table>
                  </td>
                </tr>
              </table>'''
        : '';

    final isTurkish = s.htmlLang == 'tr';
    final plainQuestionText = isTurkish
        ? '${s.questionsPrefix}$effectiveAgencyEmail üzerinden ulaşabilirsiniz.'
        : '${s.questionsPrefix}$effectiveAgencyEmail${s.questionsSuffix}';

    final body = '''${s.salutationPrefix}$effectiveTenantName,

${s.introPrefix}$effectiveAgencyName${s.introMid}$effectiveAddress${s.introSuffix}
${termsSummary.isNotEmpty ? '\n${s.agreementSummaryTitle}:\n$termsSummary\n' : ''}
${s.toGetStarted}

1. ${s.openWebApp} (https://www.stanomer.online/app)${s.orDownloadApp}(https://apps.apple.com/us/app/stanomer/id6762311157 ve https://play.google.com/store/apps/details?id=com.aboptima.stanomer)
2. ${s.signUpPrefix}$effectiveEmail${s.signUpSuffix}

${s.warningPrefix}$effectiveEmail${s.warningSuffix}

${s.afterRegistration}

$plainQuestionText

${s.bestRegards}
${s.teamPrefix}$effectiveAgencyName${s.teamSuffix}''';

    final htmlQuestions = isTurkish
        ? '''<p>Herhangi bir sorunuz olursa bize
                <a href="mailto:$effectiveAgencyEmail" style="color:#1a5eb8; text-decoration:none;">buradan ulaşabilirsiniz</a>.
              </p>'''
        : '''<p>${s.questionsPrefix}
                <a href="mailto:$effectiveAgencyEmail" style="color:#1a5eb8; text-decoration:none;">$effectiveAgencyEmail</a>${s.questionsSuffix}
              </p>''';

    final html = '''<!DOCTYPE html>
<html lang="${s.htmlLang}">
<head>
<meta charset="UTF-8">
<title>${s.htmlTitle}</title>
</head>
<body style="margin:0; padding:0; background-color:#f4f6f8; font-family: Arial, Helvetica, sans-serif;">
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color:#f4f6f8; padding:24px 0;">
    <tr>
      <td align="center">
        <table role="presentation" width="600" cellpadding="0" cellspacing="0" style="background-color:#ffffff; border-radius:8px; overflow:hidden;">

          <!-- Header -->
          <tr>
            <td style="background-color:#1a5eb8; padding:24px 32px;">
              <span style="color:#ffffff; font-size:20px; font-weight:bold;">Stanomer</span>
            </td>
          </tr>

          <!-- Body -->
          <tr>
            <td style="padding:32px; color:#222222; font-size:15px; line-height:1.6;">
              <p>${s.salutationPrefix}<strong>$effectiveTenantName</strong>,</p>

              <p>${s.introPrefix}<strong>$effectiveAgencyName</strong>${s.introMid}<strong>$effectiveAddress</strong>${s.introSuffix}</p>
$termsHtmlTable
              <p style="margin-top:24px; margin-bottom:8px;"><strong>${s.toGetStarted}</strong></p>
              <ol style="margin:0; padding-left:20px;">
                <li style="margin-bottom:8px;">
                  <a href="https://www.stanomer.online/app" style="color:#1a5eb8; text-decoration:none; font-weight:bold;">${s.openWebApp}</a>
                  ${s.orDownloadApp.trim()}
                  <a href="https://apps.apple.com/us/app/stanomer/id6762311157" style="color:#1a5eb8; text-decoration:none; font-weight:bold;">App Store</a>
                  /
                  <a href="https://play.google.com/store/apps/details?id=com.aboptima.stanomer" style="color:#1a5eb8; text-decoration:none; font-weight:bold;">Google Play</a>
                </li>
                <li>
                  ${s.signUpPrefix}<strong>$effectiveEmail</strong>${s.signUpSuffix}
                </li>
              </ol>

              <table role="presentation" cellpadding="0" cellspacing="0" style="background-color:#fff4e5; border-left:4px solid #c8503a; border-radius:4px; margin:24px 0;">
                <tr>
                  <td style="padding:14px 16px; font-size:14px; color:#7a3b1e;">
                    ${s.warningPrefix}<strong>$effectiveEmail</strong>${s.warningSuffix}
                  </td>
                </tr>
              </table>

              <p>${s.afterRegistration}</p>

              $htmlQuestions

              <p style="margin-top:32px;">${s.bestRegards}<br><strong>${s.teamPrefix}$effectiveAgencyName${s.teamSuffix}</strong></p>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="background-color:#f4f6f8; padding:16px 32px; font-size:12px; color:#888888; text-align:center;">
              ${s.getFooter(effectiveAgencyName)}
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>''';

    return (subject: subject, body: body, html: html);
  }

  @override
  ConsumerState<TenantInviteShareSheet> createState() => _TenantInviteShareSheetState();
}

class _TenantEmailPreviewStrings {
  final String htmlLang;
  final String htmlTitle;
  final String subjectTemplate;
  final String tenantFallback;
  final String agencyFallback;
  final String addressFallback;
  final String salutationPrefix;
  String get salutationSuffix => ',';
  final String introPrefix;
  final String introMid;
  final String introSuffix;
  final String agreementSummaryTitle;
  final String monthlyRentLabel;
  final String depositLabel;
  final String startDateLabel;
  final String toGetStarted;
  final String openWebApp;
  final String orDownloadApp;
  final String signUpPrefix;
  final String signUpSuffix;
  final String warningPrefix;
  final String warningSuffix;
  final String afterRegistration;
  final String questionsPrefix;
  final String questionsSuffix;
  final String bestRegards;
  final String teamPrefix;
  final String teamSuffix;
  final String footerTemplate;
  final String emailFallback;
  final String htmlBadgeLabel;

  const _TenantEmailPreviewStrings({
    required this.htmlLang,
    required this.htmlTitle,
    required this.subjectTemplate,
    required this.tenantFallback,
    required this.agencyFallback,
    required this.addressFallback,
    required this.salutationPrefix,
    required this.introPrefix,
    required this.introMid,
    required this.introSuffix,
    required this.agreementSummaryTitle,
    required this.monthlyRentLabel,
    required this.depositLabel,
    required this.startDateLabel,
    required this.toGetStarted,
    required this.openWebApp,
    required this.orDownloadApp,
    required this.signUpPrefix,
    required this.signUpSuffix,
    required this.warningPrefix,
    required this.warningSuffix,
    required this.afterRegistration,
    required this.questionsPrefix,
    required this.questionsSuffix,
    required this.bestRegards,
    this.teamPrefix = '',
    this.teamSuffix = '',
    required this.footerTemplate,
    required this.emailFallback,
    required this.htmlBadgeLabel,
  });

  String getSubject(String address) => subjectTemplate.replaceAll('{address}', address);
  String getFooter(String agencyName) => footerTemplate.replaceAll('{agency}', agencyName);

  static _TenantEmailPreviewStrings forLang(String languageCode) {
    final norm = languageCode.replaceAll('_', '-').toLowerCase();
    if (norm.startsWith('en')) {
      return const _TenantEmailPreviewStrings(
        htmlLang: 'en',
        htmlTitle: 'Stanomer - Tenant Notification',
        subjectTemplate: '[{address}] lease agreement notification',
        tenantFallback: 'Tenant',
        agencyFallback: 'Real Estate Agency',
        addressFallback: 'Property',
        salutationPrefix: 'Hello ',
        introPrefix: 'As ',
        introMid: ', we have added your lease agreement for the property located at ',
        introSuffix: ' to the Stanomer application. This allows you to view all operations related to your leasing process, such as rent payments, receipts, expenses, and maintenance requests, in real-time and track them transparently.',
        agreementSummaryTitle: 'Agreement Summary',
        monthlyRentLabel: 'Monthly Rent',
        depositLabel: 'Deposit',
        startDateLabel: 'Start Date',
        toGetStarted: 'To get started:',
        openWebApp: 'Open the web application',
        orDownloadApp: ' or download the mobile app: ',
        signUpPrefix: 'Sign up using your ',
        signUpSuffix: ' address.',
        warningPrefix: '⚠️ Be sure to use the ',
        warningSuffix: ' address when signing up, otherwise your lease agreement will not match with your account.',
        afterRegistration: 'Once registered, contract details and property information will appear in your account.',
        questionsPrefix: 'If you have any questions, you can reach us at ',
        questionsSuffix: '.',
        bestRegards: 'Best regards,',
        teamSuffix: ' team',
        footerTemplate: 'This email was sent to you by {agency} as a tenant notification email.',
        emailFallback: 'email',
        htmlBadgeLabel: 'HTML Email',
      );
    }
    if (norm == 'sr-cyrl') {
      return const _TenantEmailPreviewStrings(
        htmlLang: 'sr-Cyrl',
        htmlTitle: 'Stanomer - Обавештење за станара',
        subjectTemplate: '[{address}] обавештење о уговору о закупу',
        tenantFallback: 'Станар',
        agencyFallback: 'Агенција за некретнине',
        addressFallback: 'Некретнина',
        salutationPrefix: 'Здраво ',
        introPrefix: 'Као ',
        introMid: ', додали смо ваш уговор о закупу за некретнину на адреси ',
        introSuffix: ' у Станомер апликацију. На овај начин можете у реалном времену прегледати све процесе у вези са вашим закупом, као што су уплате кирије, рачуни, трошкови и захтеви за одржавање, и пратити их на транспарентан начин.',
        agreementSummaryTitle: 'Преглед уговора',
        monthlyRentLabel: 'Месечна кирија',
        depositLabel: 'Депозит',
        startDateLabel: 'Датум почетка',
        toGetStarted: 'За почетак:',
        openWebApp: 'Отворите веб апликацију',
        orDownloadApp: ' или преузмите мобилну апликацију: ',
        signUpPrefix: 'Региструјте се помоћу ваше ',
        signUpSuffix: ' адресе.',
        warningPrefix: '⚠️ Приликом регистрације обавезно користите ',
        warningSuffix: ' адресу, у супротном се ваш уговор о закупу неће повезати са вашим налогом.',
        afterRegistration: 'Након регистрације, детаљи уговора и информације о некретнини појавиће се на вашем налогу.',
        questionsPrefix: 'Ако имате било каквих питања, можете нам се обратити преко ',
        questionsSuffix: '.',
        bestRegards: 'С поштовањем,',
        teamSuffix: ' тим',
        footerTemplate: 'Овај имејл вам је послала компанија {agency} као обавештење за станара.',
        emailFallback: 'имејл',
        htmlBadgeLabel: 'HTML имејл',
      );
    }
    if (norm.startsWith('sr')) {
      return const _TenantEmailPreviewStrings(
        htmlLang: 'sr',
        htmlTitle: 'Stanomer - Obaveštenje za stanara',
        subjectTemplate: '[{address}] obaveštenje o ugovoru o zakupu',
        tenantFallback: 'Stanar',
        agencyFallback: 'Agencija za nekretnine',
        addressFallback: 'Nekretnina',
        salutationPrefix: 'Zdravo ',
        introPrefix: 'Kao ',
        introMid: ', dodali smo vaš ugovor o zakupu za nekretninu na adresi ',
        introSuffix: ' u Stanomer aplikaciju. Na ovaj način možete u realnom vremenu pregledati sve procese u vezi sa vašim zakupom, kao što su uplate kirije, računi, troškovi i zahtevi za održavanje, i pratiti ih na transparentan način.',
        agreementSummaryTitle: 'Pregled ugovora',
        monthlyRentLabel: 'Mesečna kirija',
        depositLabel: 'Depozit',
        startDateLabel: 'Datum početka',
        toGetStarted: 'Za početak:',
        openWebApp: 'Otvorite veb aplikaciju',
        orDownloadApp: ' ili preuzmite mobilnu aplikaciju: ',
        signUpPrefix: 'Registrujte se pomoću vaše ',
        signUpSuffix: ' adrese.',
        warningPrefix: '⚠️ Prilikom registracije obavezno koristite ',
        warningSuffix: ' adresu, u suprotnom se vaš ugovor o zakupu neće povezati sa vašim nalogom.',
        afterRegistration: 'Nakon registracije, detalji ugovora i informacije o nekretnini pojaviće se na vašem nalogu.',
        questionsPrefix: 'Ako imate bilo kakvih pitanja, možete nam se obratiti preko ',
        questionsSuffix: '.',
        bestRegards: 'S poštovanjem,',
        teamSuffix: ' tim',
        footerTemplate: 'Ovaj imejl vam je poslala kompanija {agency} kao obaveštenje za stanara.',
        emailFallback: 'imejl',
        htmlBadgeLabel: 'HTML imejl',
      );
    }
    if (norm.startsWith('ru')) {
      return const _TenantEmailPreviewStrings(
        htmlLang: 'ru',
        htmlTitle: 'Stanomer - Уведомление для арендатора',
        subjectTemplate: '[{address}] уведомление о договоре аренды',
        tenantFallback: 'Арендатор',
        agencyFallback: 'Агентство недвижимости',
        addressFallback: 'Недвижимость',
        salutationPrefix: 'Здравствуйте, ',
        introPrefix: 'Компания ',
        introMid: ' добавила ваш договор аренды на недвижимость по адресу ',
        introSuffix: ' в приложение Stanomer. Благодаря этому вы сможете в режиме реального времени просматривать все операции, связанные с процессом аренды, такие как арендные платежи, квитанции, расходы и запросы на обслуживание, а также прозрачно отслеживать их.',
        agreementSummaryTitle: 'Сводка договора',
        monthlyRentLabel: 'Ежемесячная аренда',
        depositLabel: 'Депозит',
        startDateLabel: 'Дата начала',
        toGetStarted: 'Для начала:',
        openWebApp: 'Откройте веб-приложение',
        orDownloadApp: ' или загрузите мобильное приложение: ',
        signUpPrefix: 'Зарегистрируйтесь, используя ваш адрес ',
        signUpSuffix: '.',
        warningPrefix: '⚠️ Обязательно используйте адрес ',
        warningSuffix: ' при регистрации, иначе ваш договор аренды не привяжется к вашей учетной записи.',
        afterRegistration: 'После регистрации детали договора и информация о недвижимости появятся в вашем аккаунте.',
        questionsPrefix: 'Если у вас возникнут вопросы, вы можете связаться с нами по адресу ',
        questionsSuffix: '.',
        bestRegards: 'С уважением,',
        teamPrefix: 'команда ',
        footerTemplate: 'Это письмо было отправлено вам компанией {agency} в качестве уведомительного письма для арендатора.',
        emailFallback: 'эл. почта',
        htmlBadgeLabel: 'HTML email',
      );
    }
    // Default: 'tr'
    return const _TenantEmailPreviewStrings(
      htmlLang: 'tr',
      htmlTitle: 'Stanomer - Kira Bildirimi',
      subjectTemplate: '[{address}] mülkü için kira daveti',
      tenantFallback: 'Kiracı',
      agencyFallback: 'Emlak Acentesi',
      addressFallback: 'Mülk',
      salutationPrefix: 'Merhaba ',
      introPrefix: '',
      introMid: ' olarak, ',
      introSuffix: ' adresli mülk için kira sözleşmenizi Stanomer uygulamasına ekledik. Bu sayede kira ödemeleri, dekontlar, masraflar ve bakım talepleri gibi kiralama sürecinizle ilgili tüm işlemleri anlık olarak görüntüleyebilir, şeffaf bir şekilde takip edebilirsiniz.',
      agreementSummaryTitle: 'Sözleşme Özeti',
      monthlyRentLabel: 'Aylık Kira',
      depositLabel: 'Depozito',
      startDateLabel: 'Başlangıç Tarihi',
      toGetStarted: 'Başlamak için:',
      openWebApp: 'Web uygulamasını açın',
      orDownloadApp: ' ya da mobil uygulamayı indirin: ',
      signUpPrefix: '',
      signUpSuffix: ' adresiniz ile kayıt olun.',
      warningPrefix: '⚠️ Kayıt olurken mutlaka ',
      warningSuffix: ' adresini kullanın, aksi halde kira sözleşmeniz hesabınızla eşleşmez.',
      afterRegistration: 'Kayıt olduktan sonra sözleşme detayları ve mülk bilgileri hesabınızda görünecektir.',
      questionsPrefix: 'Herhangi bir sorunuz olursa bize ',
      questionsSuffix: '.',
      bestRegards: 'Saygılarımızla,',
      teamSuffix: ' ekibi',
      footerTemplate: 'Bu e-posta {agency} tarafından size kira bildirim daveti olarak gönderilmiştir.',
      emailFallback: 'e-posta',
      htmlBadgeLabel: 'HTML E-posta',
    );
  }
}

class _TenantInviteShareSheetState extends ConsumerState<TenantInviteShareSheet> {
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;
  bool _isContractActive = false;
  DateTime? _lastEmailSentAt;
  bool _isSendingEmail = false;
  bool _showPlainTextView = false;
  String _selectedLanguage = 'tr';
  bool _localeInitialized = false;

  @override
  void initState() {
    super.initState();
    _fetchLogsAndContractStatus();
    _listenForContractStatus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_localeInitialized) {
      final locale = Localizations.localeOf(context);
      final code = locale.scriptCode == 'Cyrl' ? 'sr_Cyrl' : locale.languageCode;
      if (['tr', 'en', 'sr', 'ru', 'sr_Cyrl'].contains(code)) {
        _selectedLanguage = code;
      }
      _localeInitialized = true;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchLogsAndContractStatus() async {
    try {
      final client = Supabase.instance.client;

      // 1. Check activity logs for previous sends
      if (widget.propertyId != null && widget.propertyId!.isNotEmpty) {
        final res = await client
            .from('activity_logs')
            .select('created_at, metadata')
            .eq('property_id', widget.propertyId!)
            .eq('type', 'tenant_invite_email_sent')
            .order('created_at', ascending: false)
            .limit(1);

        if (res.isNotEmpty && mounted) {
          final createdAtStr = res.first['created_at'] as String?;
          if (createdAtStr != null) {
            final dt = DateTime.tryParse(createdAtStr)?.toLocal();
            if (dt != null) {
              setState(() => _lastEmailSentAt = dt);
            }
          }
        }
      }

      // 2. Check contract status
      if (widget.contractId != null && widget.contractId!.isNotEmpty) {
        final cRes = await client
            .from('contracts')
            .select('status')
            .eq('id', widget.contractId!)
            .maybeSingle();
        if (cRes != null && cRes['status'] == 'active' && mounted) {
          setState(() => _isContractActive = true);
        }
      } else if (widget.token.isNotEmpty) {
        final cRes = await client
            .from('contracts')
            .select('status')
            .eq('token', widget.token)
            .maybeSingle();
        if (cRes != null && cRes['status'] == 'active' && mounted) {
          setState(() => _isContractActive = true);
        }
      }
    } catch (e) {
      debugPrint('Error fetching tenant invite logs: $e');
    }
  }

  void _listenForContractStatus() {
    try {
      final client = Supabase.instance.client;
      if (widget.contractId != null && widget.contractId!.isNotEmpty) {
        _subscription = client
            .from('contracts')
            .stream(primaryKey: ['id'])
            .eq('id', widget.contractId!)
            .listen((data) {
              if (data.isNotEmpty && mounted) {
                final status = data.first['status'] as String?;
                if (status == 'active' && !_isContractActive) {
                  setState(() => _isContractActive = true);
                  ref.invalidate(agencyPropertiesProvider);
                  ref.invalidate(propertiesStreamProvider);
                }
              }
            });
      }
    } catch (e) {
      debugPrint('Error listening to contract status: $e');
    }
  }

  ({
    String subject,
    String body,
    String html,
    String agencyName,
    String agencyEmail,
    String tenantName,
    String tenantEmail,
    String address,
  }) _buildEmailDetails() {
    final address = (widget.propertyAddress != null && widget.propertyAddress!.trim().isNotEmpty)
        ? widget.propertyAddress!.trim()
        : widget.propertyName;

    final user = ref.watch(currentUserProvider);
    final profileData = ref.watch(profileFutureProvider).value;

    final rawAgencyName = (profileData?['company_name'] as String?)?.isNotEmpty == true
        ? profileData!['company_name'] as String
        : ((profileData?['full_name'] as String?)?.isNotEmpty == true
            ? profileData!['full_name'] as String
            : (user?.userMetadata?['company_name'] as String? ??
                user?.userMetadata?['full_name'] as String? ??
                ''));

    final agencyName = rawAgencyName.trim();
    final agencyEmail = (profileData?['email'] as String?)?.isNotEmpty == true
        ? profileData!['email'] as String
        : (user?.email ?? '');

    final tenantName = widget.tenantName.trim();
    final tenantEmail = widget.tenantEmail.trim();

    final email = TenantInviteShareSheet.buildTenantInviteEmail(
      agencyName: agencyName,
      agencyEmail: agencyEmail,
      address: address,
      tenantName: tenantName,
      tenantEmail: tenantEmail,
      monthlyRent: widget.monthlyRent,
      currency: widget.currency,
      depositAmount: widget.depositAmount,
      startDate: widget.startDate,
      languageCode: _selectedLanguage,
    );

    return (
      subject: email.subject,
      body: email.body,
      html: email.html,
      agencyName: agencyName,
      agencyEmail: agencyEmail,
      tenantName: tenantName,
      tenantEmail: tenantEmail,
      address: address,
    );
  }

  Future<void> _sendInviteEmail() async {
    final loc = AppLocalizations.of(context)!;
    final details = _buildEmailDetails();
    final email = details.tenantEmail;

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.tenantNoEmailError)),
      );
      return;
    }

    setState(() => _isSendingEmail = true);

    try {
      final success = await EmailService.sendEmail(
        toEmail: email,
        toName: details.tenantName,
        subject: details.subject,
        textContent: details.body,
        htmlContent: details.html,
        replyToEmail: details.agencyEmail.isNotEmpty ? details.agencyEmail : null,
        replyToName: details.agencyName.isNotEmpty ? details.agencyName : null,
      );

      if (!mounted) return;

      if (success) {
        final now = DateTime.now();
        try {
          final client = Supabase.instance.client;
          final user = client.auth.currentUser;

          if (widget.propertyId != null && widget.propertyId!.isNotEmpty) {
            await client.from('activity_logs').insert({
              'property_id': widget.propertyId,
              'user_id': user?.id,
              'type': 'tenant_invite_email_sent',
              'metadata': {
                'tenant_name': details.tenantName,
                'tenant_email': email,
                'token': widget.token,
                'contract_id': widget.contractId,
                'sent_at': now.toIso8601String(),
                'provider': 'brevo',
              },
            });
          }
        } catch (e) {
          debugPrint('Error logging tenant invite email activity: $e');
        }

        if (mounted) {
          setState(() {
            _lastEmailSentAt = now;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(LucideIcons.checkCircle, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(loc.tenantInviteSentSuccess(email))),
                ],
              ),
              backgroundColor: const Color(0xFF16A34A),
              behavior: SnackBarBehavior.floating,
            ),
          );
          widget.onInviteSent?.call();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(LucideIcons.alertCircle, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(loc.emailSendFailedError)),
                ],
              ),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error sending tenant invite email: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.emailSendGenericError(e.toString())),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingEmail = false);
      }
    }
  }

  Widget _buildLanguageSelector(Color primaryColor) {
    const supportedLangs = [
      ('tr', 'TR', 'Türkçe'),
      ('en', 'EN', 'English'),
      ('sr', 'SR', 'Srpski'),
      ('ru', 'RU', 'Русский'),
      ('sr_Cyrl', 'SR (Ћир)', 'Српски (ћирилица)'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Icon(LucideIcons.globe, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Text(
            AppLocalizations.of(context)?.languageLabel ?? 'Dil:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: supportedLangs.map((item) {
                  final code = item.$1;
                  final label = item.$2;
                  final tooltip = item.$3;
                  final isSelected = _selectedLanguage == code;

                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Tooltip(
                      message: tooltip,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          if (!isSelected) {
                            setState(() => _selectedLanguage = code);
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? primaryColor : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? primaryColor : Colors.grey.shade300,
                              width: 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: primaryColor.withValues(alpha: 0.25),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    )
                                  ]
                                : null,
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? Colors.white : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormattedEmailPreview(
    ({
      String subject,
      String body,
      String html,
      String agencyName,
      String agencyEmail,
      String tenantName,
      String tenantEmail,
      String address,
    }) details,
    Color primaryColor,
  ) {
    const brandBlue = Color(0xFF1A5EB8);
    const brandBg = Color(0xFFF4F6F8);
    const warningBg = Color(0xFFFFF4E5);
    const warningBorder = Color(0xFFC8503A);
    const warningText = Color(0xFF7A3B1E);

    final s = _TenantEmailPreviewStrings.forLang(_selectedLanguage);
    final isTurkish = s.htmlLang == 'tr';

    return Container(
      decoration: BoxDecoration(
        color: brandBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header banner matching HTML template: #1a5eb8
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            color: brandBlue,
            child: Row(
              children: [
                const Text(
                  'Stanomer',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    s.htmlBadgeLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // White email card body matching HTML template
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Salutation
                Text.rich(
                  TextSpan(
                    text: s.salutationPrefix,
                    style: const TextStyle(fontSize: 13.5, color: Color(0xFF222222), height: 1.5),
                    children: [
                      TextSpan(
                        text: details.tenantName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: s.salutationSuffix),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Intro text
                Text.rich(
                  TextSpan(
                    text: s.introPrefix,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF222222), height: 1.55),
                    children: [
                      TextSpan(
                        text: details.agencyName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: s.introMid),
                      TextSpan(
                        text: details.address,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: s.introSuffix),
                    ],
                  ),
                ),
                if (widget.monthlyRent != null && widget.monthlyRent! > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.agreementSummaryTitle,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1A5EB8)),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(s.monthlyRentLabel, style: const TextStyle(fontSize: 12, color: Color(0xFF333333))),
                            Text(
                              '${widget.monthlyRent!.toStringAsFixed(0)} ${widget.currency ?? "EUR"}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                            ),
                          ],
                        ),
                        if (widget.depositAmount != null && widget.depositAmount! > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(s.depositLabel, style: const TextStyle(fontSize: 12, color: Color(0xFF333333))),
                              Text(
                                '${widget.depositAmount!.toStringAsFixed(0)} ${widget.currency ?? "EUR"}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                              ),
                            ],
                          ),
                        ],
                        if (widget.startDate != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(s.startDateLabel, style: const TextStyle(fontSize: 12, color: Color(0xFF333333))),
                              Text(
                                DateFormat("dd/MM/yyyy").format(widget.startDate!),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                // Next steps title
                Text(
                  s.toGetStarted,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF222222),
                  ),
                ),
                const SizedBox(height: 8),
                // Step 1: Web & App Store links
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '1. ',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF222222),
                      ),
                    ),
                    Expanded(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          InkWell(
                            onTap: () => launchUrl(
                              Uri.parse('https://www.stanomer.online/app'),
                              mode: LaunchMode.externalApplication,
                            ),
                            child: Text(
                              s.openWebApp,
                              style: const TextStyle(
                                fontSize: 13,
                                color: brandBlue,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          Text(
                            s.orDownloadApp,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF222222)),
                          ),
                          InkWell(
                            onTap: () => launchUrl(
                              Uri.parse('https://apps.apple.com/us/app/stanomer/id6762311157'),
                              mode: LaunchMode.externalApplication,
                            ),
                            child: const Text(
                              'App Store',
                              style: TextStyle(
                                fontSize: 13,
                                color: brandBlue,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          const Text(' / ', style: TextStyle(fontSize: 13, color: Color(0xFF222222))),
                          InkWell(
                            onTap: () => launchUrl(
                              Uri.parse('https://play.google.com/store/apps/details?id=com.aboptima.stanomer'),
                              mode: LaunchMode.externalApplication,
                            ),
                            child: const Text(
                              'Google Play',
                              style: TextStyle(
                                fontSize: 13,
                                color: brandBlue,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Step 2: Register with email
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '2. ',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF222222),
                      ),
                    ),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: s.signUpPrefix,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF222222)),
                          children: [
                            TextSpan(
                              text: details.tenantEmail.isNotEmpty ? details.tenantEmail : s.emailFallback,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: s.signUpSuffix),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Warning Callout Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: warningBg,
                    border: const Border(
                      left: BorderSide(color: warningBorder, width: 4),
                    ),
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(6)),
                  ),
                  child: Text.rich(
                    TextSpan(
                      text: s.warningPrefix,
                      style: const TextStyle(fontSize: 12.5, color: warningText, height: 1.45),
                      children: [
                        TextSpan(
                          text: details.tenantEmail.isNotEmpty ? details.tenantEmail : s.emailFallback,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: s.warningSuffix),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  s.afterRegistration,
                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF444444)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      s.questionsPrefix,
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF444444)),
                    ),
                    InkWell(
                      onTap: details.agencyEmail.isNotEmpty
                          ? () => launchUrl(Uri.parse('mailto:${details.agencyEmail}'))
                          : null,
                      child: Text(
                        isTurkish
                            ? 'buradan ulaşabilirsiniz'
                            : (details.agencyEmail.isNotEmpty ? details.agencyEmail : 'info@stanomer.online'),
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: brandBlue,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    Text(s.questionsSuffix, style: const TextStyle(fontSize: 12.5, color: Color(0xFF444444))),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  s.bestRegards,
                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF555555)),
                ),
                Text(
                  '${s.teamPrefix}${details.agencyName}${s.teamSuffix}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF222222),
                  ),
                ),
              ],
            ),
          ),
          // Footer matching HTML template: #f4f6f8
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: brandBg,
            child: Text(
              s.getFooter(details.agencyName),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF888888),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final maxHeight = MediaQuery.of(context).size.height * 0.90;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final primaryColor = ref.watch(agencyColorSchemeProvider).primary;
    final emailDetails = _buildEmailDetails();

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: bottomInset + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(LucideIcons.userCheck, color: primaryColor, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.tenantInviteEmailTitle,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          emailDetails.address,
                          style: const TextStyle(fontSize: 12, color: StanomerColors.textTertiary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Tenant Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: StanomerColors.borderDefault),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(LucideIcons.user, color: primaryColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            emailDetails.tenantName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            emailDetails.tenantEmail,
                            style: const TextStyle(fontSize: 12, color: StanomerColors.textTertiary),
                          ),
                          if (_lastEmailSentAt != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(LucideIcons.send, size: 10, color: Color(0xFF15803D)),
                                const SizedBox(width: 4),
                                Text(
                                  loc.lastSentAt(DateFormat("dd/MM/yyyy HH:mm").format(_lastEmailSentAt!)),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF15803D),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (_isContractActive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF86EFAC)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.checkCheck, size: 12, color: Color(0xFF16A34A)),
                            const SizedBox(width: 4),
                            Text(
                              loc.statusApproved,
                              style: const TextStyle(
                                color: Color(0xFF15803D),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _lastEmailSentAt != null ? const Color(0xFFFEF3C7) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _lastEmailSentAt != null ? const Color(0xFFFDE68A) : Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _lastEmailSentAt != null ? LucideIcons.clock : LucideIcons.mail,
                              size: 12,
                              color: _lastEmailSentAt != null ? const Color(0xFFB45309) : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _lastEmailSentAt != null ? loc.invitePending : loc.statusNotSent,
                              style: TextStyle(
                                color: _lastEmailSentAt != null ? const Color(0xFFB45309) : Colors.grey.shade700,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Email Preview Box
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: StanomerColors.borderDefault),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Preview Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          Icon(LucideIcons.mail, size: 16, color: primaryColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              loc.emailPreviewTitle,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: StanomerColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Toggle between Formatted (HTML) and Plain Text
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.all(2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  borderRadius: BorderRadius.circular(6),
                                  onTap: () => setState(() => _showPlainTextView = false),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: !_showPlainTextView ? Colors.white : Colors.transparent,
                                      borderRadius: BorderRadius.circular(6),
                                      boxShadow: !_showPlainTextView
                                          ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2)]
                                          : null,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          LucideIcons.layoutTemplate,
                                          size: 11,
                                          color: !_showPlainTextView ? primaryColor : Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          loc.tabVisual,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: !_showPlainTextView ? FontWeight.bold : FontWeight.w500,
                                            color: !_showPlainTextView ? primaryColor : Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                InkWell(
                                  borderRadius: BorderRadius.circular(6),
                                  onTap: () => setState(() => _showPlainTextView = true),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _showPlainTextView ? Colors.white : Colors.transparent,
                                      borderRadius: BorderRadius.circular(6),
                                      boxShadow: _showPlainTextView
                                          ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2)]
                                          : null,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          LucideIcons.alignLeft,
                                          size: 11,
                                          color: _showPlainTextView ? primaryColor : Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Düz Metin',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: _showPlainTextView ? FontWeight.bold : FontWeight.w500,
                                            color: _showPlainTextView ? primaryColor : Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              Clipboard.setData(ClipboardData(
                                text: '${loc.subjectHeader}: ${emailDetails.subject}\n\n${emailDetails.body}',
                              ));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(loc.emailCopiedToast)),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(LucideIcons.copy, size: 13, color: Colors.grey.shade600),
                                  const SizedBox(width: 4),
                                  Text(
                                    loc.copy,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: StanomerColors.borderDefault),
                    _buildLanguageSelector(primaryColor),
                    const Divider(height: 1, color: StanomerColors.borderDefault),
                    // Subject Row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.subjectHeader,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            emailDetails.subject,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: StanomerColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: StanomerColors.borderDefault),
                    // Body Section
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                loc.contentHeader,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _showPlainTextView ? '(${loc.tabPlainText})' : '(${loc.tabVisual})',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              if (!_showPlainTextView)
                                Text(
                                  loc.recipientWillReceiveThisFormat,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade500,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            constraints: BoxConstraints(
                              maxHeight: _showPlainTextView ? 180 : 340,
                            ),
                            child: SingleChildScrollView(
                              child: _showPlainTextView
                                  ? SelectableText(
                                      emailDetails.body,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        height: 1.45,
                                        color: Colors.grey.shade800,
                                      ),
                                    )
                                  : _buildFormattedEmailPreview(emailDetails, primaryColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _isSendingEmail ? null : _sendInviteEmail,
                icon: _isSendingEmail
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(
                        _lastEmailSentAt != null ? LucideIcons.mailCheck : LucideIcons.send,
                        size: 18,
                      ),
                label: Text(
                  _isSendingEmail
                      ? loc.sendingState
                      : (_lastEmailSentAt != null ? loc.resendInviteEmailBtn : loc.sendTenantInviteEmailBtn),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade600,
                  minimumSize: const Size.fromHeight(48),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: Text(
                  loc.cancel,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
