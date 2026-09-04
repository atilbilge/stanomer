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
import '../../domain/property_owner.dart';

class OwnershipShareSheet extends ConsumerStatefulWidget {
  final String propertyName;
  final String landlordName;
  final String landlordEmail;
  final String token;
  final String? propertyId;
  final String? propertyAddress;
  final List<PropertyOwner>? owners;

  const OwnershipShareSheet({
    super.key,
    required this.propertyName,
    required this.landlordName,
    required this.landlordEmail,
    required this.token,
    this.propertyId,
    this.propertyAddress,
    this.owners,
  });

  static Future<void> show(
    BuildContext context, {
    required String propertyName,
    required String landlordName,
    required String landlordEmail,
    required String token,
    String? propertyId,
    String? propertyAddress,
    List<PropertyOwner>? owners,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => OwnershipShareSheet(
        propertyName: propertyName,
        landlordName: landlordName,
        landlordEmail: landlordEmail,
        token: token,
        propertyId: propertyId,
        propertyAddress: propertyAddress,
        owners: owners,
      ),
    );
  }

  static ({String subject, String body, String html}) buildLandlordInviteEmail({
    required String agencyName,
    required String agencyEmail,
    required String address,
    required String landlordName,
    required String landlordEmail,
    String languageCode = 'tr',
  }) {
    final normalizedLang = languageCode.replaceAll('_', '-').toLowerCase();

    final String fallbackAddress;
    final String fallbackLandlordName;
    final String fallbackAgencyName;

    if (normalizedLang.startsWith('en')) {
      fallbackAddress = 'Property';
      fallbackLandlordName = 'Property Owner';
      fallbackAgencyName = 'Real Estate Agency';
    } else if (normalizedLang == 'sr-cyrl') {
      fallbackAddress = 'Некретнина';
      fallbackLandlordName = 'Власник';
      fallbackAgencyName = 'Агенција за некретнине';
    } else if (normalizedLang.startsWith('sr')) {
      fallbackAddress = 'Nekretnina';
      fallbackLandlordName = 'Vlasnik';
      fallbackAgencyName = 'Agencija za nekretnine';
    } else if (normalizedLang.startsWith('ru')) {
      fallbackAddress = 'Недвижимость';
      fallbackLandlordName = 'Владелец';
      fallbackAgencyName = 'Агентство недвижимости';
    } else {
      fallbackAddress = 'Mülk';
      fallbackLandlordName = 'Ev Sahibi';
      fallbackAgencyName = 'Emlak Acentesi';
    }

    final effectiveAddress = address.trim().isNotEmpty ? address.trim() : fallbackAddress;
    final effectiveLandlordName = landlordName.trim().isNotEmpty ? landlordName.trim() : fallbackLandlordName;
    final effectiveAgencyName = agencyName.trim().isNotEmpty ? agencyName.trim() : fallbackAgencyName;
    final effectiveEmail = landlordEmail.trim();
    final effectiveAgencyEmail = agencyEmail.trim().isNotEmpty ? agencyEmail.trim() : 'info@stanomer.online';

    const webLink = 'https://www.stanomer.online/app';
    const iosLink = 'https://apps.apple.com/us/app/stanomer/id6762311157';
    const androidLink = 'https://play.google.com/store/apps/details?id=com.aboptima.stanomer';

    // 1. English (en)
    if (normalizedLang.startsWith('en')) {
      final subject = '[$effectiveAddress] your property has been added to Stanomer';
      final body = '''Hello $effectiveLandlordName,

As $effectiveAgencyName, we have added your property located at $effectiveAddress to the Stanomer application. 
This allows you to view all processes related to your property, such as rent payments, expenses, and maintenance processes, in real-time and track them transparently.

To get started:

1. Open the web application ($webLink) or download the mobile app:
($iosLink and $androidLink)
2. Sign up using your $effectiveEmail address.

⚠️ Be sure to use the $effectiveEmail address when signing up, otherwise your property will not match with your account.

Once registered, all details regarding your property will appear in your account.

If you have any questions, you can reach us at $effectiveAgencyEmail.

Best regards,
$effectiveAgencyName team''';

      final html = '''<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Stanomer - Property Notification</title>
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
              <p>Hello <strong>$effectiveLandlordName</strong>,</p>

              <p>As <strong>$effectiveAgencyName</strong>, we have added your property located at <strong>$effectiveAddress</strong> to the Stanomer application. 
              This allows you to view all processes related to your property, such as rent payments, expenses, and maintenance processes, in real-time and track them transparently.</p>

              <p style="margin-top:24px; margin-bottom:8px;"><strong>To get started:</strong></p>
              <ol style="margin:0; padding-left:20px;">
                <li style="margin-bottom:8px;">
                  <a href="$webLink" style="color:#1a5eb8; text-decoration:none; font-weight:bold;">Open the web application</a>
                  or download the mobile app:
                  <a href="$iosLink" style="color:#1a5eb8; text-decoration:none; font-weight:bold;">App Store</a>
                  /
                  <a href="$androidLink" style="color:#1a5eb8; text-decoration:none; font-weight:bold;">Google Play</a>
                </li>
                <li>
                  Sign up using your <strong>$effectiveEmail</strong> address.
                </li>
              </ol>

              <table role="presentation" cellpadding="0" cellspacing="0" style="background-color:#fff4e5; border-left:4px solid #c8503a; border-radius:4px; margin:24px 0;">
                <tr>
                  <td style="padding:14px 16px; font-size:14px; color:#7a3b1e;">
                    ⚠️ Be sure to use the <strong>$effectiveEmail</strong> address when signing up, otherwise your property will not match with your account.
                  </td>
                </tr>
              </table>

              <p>Once registered, all details regarding your property will appear in your account.</p>

              <p>If you have any questions, you can
                <a href="mailto:$effectiveAgencyEmail" style="color:#1a5eb8; text-decoration:none;">reach us here</a>.
              </p>

              <p style="margin-top:32px;">Best regards,<br><strong>$effectiveAgencyName team</strong></p>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="background-color:#f4f6f8; padding:16px 32px; font-size:12px; color:#888888; text-align:center;">
              This email was sent to you by $effectiveAgencyName as a property management notification.
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

    // 2. Serbian Cyrillic (sr-Cyrl)
    if (normalizedLang == 'sr-cyrl' || normalizedLang == 'sr_cyrl') {
      final subject = '[$effectiveAddress] ваша некретнина је додата у Станомер';
      final body = '''Здраво $effectiveLandlordName,

Као $effectiveAgencyName, додали смо вашу некретнину на адреси $effectiveAddress у Станомер апликацију. 
На овај начин можете у реалном времену прегледати све процесе везане за вашу некретнину, као што су уплате кирије, трошкови и процеси одржавања, и пратити их на транспарентан начин.

За почетак:

1. Отворите веб апликацију ($webLink) или преузмите мобилну апликацију:
($iosLink и $androidLink)
2. Региструјте се помоћу ваше $effectiveEmail адресе.

⚠️ Приликом регистрације обавезно користите $effectiveEmail адресу, у супротном се ваша некретнина неће повезати са вашим налогом.

Након регистрације, сви детаљи у вези са вашом некретнином појавиће се на вашем налогу.

Ако имате било каквих питања, можете нам се обратити на $effectiveAgencyEmail.

С поштовањем,
$effectiveAgencyName тим''';

      final html = '''<!DOCTYPE html>
<html lang="sr-Cyrl">
<head>
<meta charset="UTF-8">
<title>Stanomer - Обавештење о некретнини</title>
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
              <p>Здраво <strong>$effectiveLandlordName</strong>,</p>

              <p>Као <strong>$effectiveAgencyName</strong>, додали смо вашу некретнину на адреси <strong>$effectiveAddress</strong> у Станомер апликацију. 
              На овај начин можете у реалном времену прегледати све процесе везане за вашу некретнину, као што су уплате кирије, трошкови и процеси одржавања, и пратити их на транспарентан начин.</p>

              <p style="margin-top:24px; margin-bottom:8px;"><strong>За почетак:</strong></p>
              <ol style="margin:0; padding-left:20px;">
                <li style="margin-bottom:8px;">
                  <a href="$webLink" style="color:#1a5eb8; text-decoration:none; font-weight:bold;">Отворите веб апликацију</a>
                  или преузмите мобилну апликацију:
                  <a href="$iosLink" style="color:#1a5eb8; text-decoration:none; font-weight:bold;">App Store</a>
                  /
                  <a href="$androidLink" style="color:#1a5eb8; text-decoration:none; font-weight:bold;">Google Play</a>
                </li>
                <li>
                  Региструјте се помоћу ваше <strong>$effectiveEmail</strong> адресе.
                </li>
              </ol>

              <table role="presentation" cellpadding="0" cellspacing="0" style="background-color:#fff4e5; border-left:4px solid #c8503a; border-radius:4px; margin:24px 0;">
                <tr>
                  <td style="padding:14px 16px; font-size:14px; color:#7a3b1e;">
                    ⚠️ Приликом регистрације обавезно користите <strong>$effectiveEmail</strong> адресу, у супротном се ваша некретнина неће повезати са вашим налогом.
                  </td>
                </tr>
              </table>

              <p>Након регистрације, сви детаљи у вези са вашом некретнином појавиће се на вашем налогу.</p>

              <p>Ако имате било каквих питања, можете нам
                <a href="mailto:$effectiveAgencyEmail" style="color:#1a5eb8; text-decoration:none;">се обратити овде</a>.
              </p>

              <p style="margin-top:32px;">С поштовањем,<br><strong>$effectiveAgencyName тим</strong></p>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="background-color:#f4f6f8; padding:16px 32px; font-size:12px; color:#888888; text-align:center;">
              Овај имејл вам је послао $effectiveAgencyName као обавештење о управљању некретнином.
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

    // 3. Serbian Latin (sr)
    if (normalizedLang.startsWith('sr')) {
      final subject = '[$effectiveAddress] vaša nekretnina je dodata u Stanomer';
      final body = '''Zdravo $effectiveLandlordName,

Kao $effectiveAgencyName, dodali smo vašu nekretninu na adresi $effectiveAddress u Stanomer aplikaciju. 
Na ovaj način možete u realnom vremenu pregledati sve procese vezane za vašu nekretninu, kao što su uplate kirije, troškovi i procesi održavanja, i pratiti ih na transparentan način.

Za početak:

1. Otvorite veb aplikaciju ($webLink) ili preuzmite mobilnu aplikaciju:
($iosLink i $androidLink)
2. Registrujte se pomoću vaše $effectiveEmail adrese.

⚠️ Prilikom registracije obavezno koristite $effectiveEmail adresu, u suprotnom se vaša nekretnina neće povezati sa vašim nalogom.

Nakon registracije, svi detalji u vezi sa vašom nekretninom pojaviće se na vašem nalogu.

Ako imate bilo kakvih pitanja, možete nam se obratiti na $effectiveAgencyEmail.

S poštovanjem,
$effectiveAgencyName tim''';

      final html = '''<!DOCTYPE html>
<html lang="sr">
<head>
<meta charset="UTF-8">
<title>Stanomer - Obaveštenje o nekretnini</title>
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
              <p>Zdravo <strong>$effectiveLandlordName</strong>,</p>

              <p>Kao <strong>$effectiveAgencyName</strong>, dodali smo vašu nekretninu na adresi <strong>$effectiveAddress</strong> u Stanomer aplikaciju. 
              Na ovaj način možete u realnom vremenu pregledati sve procese vezane za vašu nekretninu, kao što su uplate kirije, troškovi i procesi održavanja, i pratiti ih na transparentan način.</p>

              <p style="margin-top:24px; margin-bottom:8px;"><strong>Za početak:</strong></p>
              <ol style="margin:0; padding-left:20px;">
                <li style="margin-bottom:8px;">
                  <a href="$webLink" style="color:#1a5eb8; text-decoration:none; font-weight:bold;">Otvorite veb aplikaciju</a>
                  ili preuzmite mobilnu aplikaciju:
                  <a href="$iosLink" style="color:#1a5eb8; text-decoration:none; font-weight:bold;">App Store</a>
                  /
                  <a href="$androidLink" style="color:#1a5eb8; text-decoration:none; font-weight:bold;">Google Play</a>
                </li>
                <li>
                  Registrujte se pomoću vaše <strong>$effectiveEmail</strong> adrese.
                </li>
              </ol>

              <table role="presentation" cellpadding="0" cellspacing="0" style="background-color:#fff4e5; border-left:4px solid #c8503a; border-radius:4px; margin:24px 0;">
                <tr>
                  <td style="padding:14px 16px; font-size:14px; color:#7a3b1e;">
                    ⚠️ Prilikom registracije obavezno koristite <strong>$effectiveEmail</strong> adresu, u suprotnom se vaša nekretnina neće povezati sa vašim nalogom.
                  </td>
                </tr>
              </table>

              <p>Nakon registracije, svi detalji u vezi sa vašom nekretninom pojaviće se na vašem nalogu.</p>

              <p>Ako imate bilo kakvih pitanja, možete nam
                <a href="mailto:$effectiveAgencyEmail" style="color:#1a5eb8; text-decoration:none;">se obratiti ovde</a>.
              </p>

              <p style="margin-top:32px;">S poštovanjem,<br><strong>$effectiveAgencyName tim</strong></p>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="background-color:#f4f6f8; padding:16px 32px; font-size:12px; color:#888888; text-align:center;">
              Ovaj imejl vam je poslao $effectiveAgencyName kao obaveštenje o upravljanju nekretninom.
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

    // 4. Russian (ru)
    if (normalizedLang.startsWith('ru')) {
      final subject = '[$effectiveAddress] ваша недвижимость добавлена в Stanomer';
      final body = '''Здравствуйте, $effectiveLandlordName,

Компания $effectiveAgencyName добавила вашу недвижимость по адресу $effectiveAddress в приложение Stanomer. 
Благодаря этому вы сможете в режиме реального времени просматривать все операции, связанные с вашей недвижимостью, такие как арендные платежи, расходы и процессы обслуживания, а также прозрачно отслеживать их.

Для начала:

1. Откройте веб-приложение ($webLink) или загрузите мобильное приложение:
($iosLink и $androidLink)
2. Зарегистрируйтесь, используя ваш адрес $effectiveEmail.

⚠️ Обязательно используйте адрес $effectiveEmail при регистрации, иначе ваша недвижимость не привяжется к вашей учетной записи.

После регистрации все данные о вашей недвижимости появятся в вашем аккаунте.

Если у вас возникнут вопросы, вы можете связаться с нами по адресу $effectiveAgencyEmail.

С уважением,
команда $effectiveAgencyName''';

      final html = '''<!DOCTYPE html>
<html lang="ru">
<head>
<meta charset="UTF-8">
<title>Stanomer - Уведомление о недвижимости</title>
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
              <p>Здравствуйте, <strong>$effectiveLandlordName</strong>,</p>

              <p>Компания <strong>$effectiveAgencyName</strong> добавила вашу недвижимость по адресу <strong>$effectiveAddress</strong> в приложение Stanomer. 
              Благодаря этому вы сможете в режиме реального времени просматривать все операции, связанные с вашей недвижимостью, такие как арендные платежи, расходы и процессы обслуживания, а также прозрачно отслеживать их.</p>

              <p style="margin-top:24px; margin-bottom:8px;"><strong>Для начала:</strong></p>
              <ol style="margin:0; padding-left:20px;">
                <li style="margin-bottom:8px;">
                  <a href="$webLink" style="color:#1a5eb8; text-decoration:none; font-weight:bold;">Откройте веб-приложение</a>
                  или загрузите мобильное приложение:
                  <a href="$iosLink" style="color:#1a5eb8; text-decoration:none; font-weight:bold;">App Store</a>
                  /
                  <a href="$androidLink" style="color:#1a5eb8; text-decoration:none; font-weight:bold;">Google Play</a>
                </li>
                <li>
                  Зарегистрируйтесь, используя ваш адрес <strong>$effectiveEmail</strong>.
                </li>
              </ol>

              <table role="presentation" cellpadding="0" cellspacing="0" style="background-color:#fff4e5; border-left:4px solid #c8503a; border-radius:4px; margin:24px 0;">
                <tr>
                  <td style="padding:14px 16px; font-size:14px; color:#7a3b1e;">
                    ⚠️ Обязательно используйте адрес <strong>$effectiveEmail</strong> при регистрации, иначе ваша недвижимость не привяжется к вашей учетной записи.
                  </td>
                </tr>
              </table>

              <p>После регистрации все данные о вашей недвижимости появятся в вашем аккаунте.</p>

              <p>Если у вас возникнут вопросы, вы можете
                <a href="mailto:$effectiveAgencyEmail" style="color:#1a5eb8; text-decoration:none;">связаться с нами здесь</a>.
              </p>

              <p style="margin-top:32px;">С уважением,<br><strong>команда $effectiveAgencyName</strong></p>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="background-color:#f4f6f8; padding:16px 32px; font-size:12px; color:#888888; text-align:center;">
              Это письмо было отправлено вам компанией $effectiveAgencyName в качестве уведомления об управлении недвижимостью.
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

    // 5. Turkish (tr) - Default
    final subject = '[$effectiveAddress] mülkünüz Stanomer\'e eklendi';

    final body = '''Merhaba $effectiveLandlordName,

$effectiveAgencyName olarak, $effectiveAddress adresli mülkünüzü Stanomer uygulamasına ekledik. 
Bu sayede kira ödemeleri, masraflar ve bakım süreçleri gibi mülkünüzle ilgili 
tüm işlemleri anlık olarak görüntüleyebilir, şeffaf bir şekilde takip edebilirsiniz.

Başlamak için:

1. Web uygulamasını açın ($webLink) ya da mobil uygulamayı indirin. 
($iosLink ve $androidLink)
2. $effectiveEmail adresiniz ile kayıt olun.

⚠️ Kayıt olurken mutlaka $effectiveEmail adresini kullanın, aksi halde mülkünüz 
hesabınızla eşleşmez.

Kayıt olduktan sonra mülkünüze dair tüm detaylar hesabınızda görünecektir.

Herhangi bir sorunuz olursa bize $effectiveAgencyEmail üzerinden ulaşabilirsiniz.

Saygılarımızla,
$effectiveAgencyName ekibi''';

    final html = '''<!DOCTYPE html>
<html lang="tr">
<head>
<meta charset="UTF-8">
<title>Stanomer - Mülk Bildirimi</title>
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
              <p>Merhaba <strong>$effectiveLandlordName</strong>,</p>

              <p><strong>$effectiveAgencyName</strong> olarak, <strong>$effectiveAddress</strong> adresli mülkünüzü Stanomer uygulamasına ekledik.
              Bu sayede kira ödemeleri, masraflar ve bakım süreçleri gibi mülkünüzle ilgili tüm işlemleri
              anlık olarak görüntüleyebilir, şeffaf bir şekilde takip edebilirsiniz.</p>

              <p style="margin-top:24px; margin-bottom:8px;"><strong>Başlamak için:</strong></p>
              <ol style="margin:0; padding-left:20px;">
                <li style="margin-bottom:8px;">
                  <a href="$webLink" style="color:#1a5eb8; text-decoration:none; font-weight:bold;">Web uygulamasını açın</a>
                  ya da mobil uygulamayı indirin:
                  <a href="$iosLink" style="color:#1a5eb8; text-decoration:none; font-weight:bold;">App Store</a>
                  /
                  <a href="$androidLink" style="color:#1a5eb8; text-decoration:none; font-weight:bold;">Google Play</a>
                </li>
                <li>
                  <strong>$effectiveEmail</strong> adresiniz ile kayıt olun.
                </li>
              </ol>

              <table role="presentation" cellpadding="0" cellspacing="0" style="background-color:#fff4e5; border-left:4px solid #c8503a; border-radius:4px; margin:24px 0;">
                <tr>
                  <td style="padding:14px 16px; font-size:14px; color:#7a3b1e;">
                    ⚠️ Kayıt olurken mutlaka <strong>$effectiveEmail</strong> adresini kullanın, aksi halde mülkünüz hesabınızla eşleşmez.
                  </td>
                </tr>
              </table>

              <p>Kayıt olduktan sonra mülkünüze dair tüm detaylar hesabınızda görünecektir.</p>

              <p>Herhangi bir sorunuz olursa bize
                <a href="mailto:$effectiveAgencyEmail" style="color:#1a5eb8; text-decoration:none;">buradan ulaşabilirsiniz</a>.
              </p>

              <p style="margin-top:32px;">Saygılarımızla,<br><strong>$effectiveAgencyName ekibi</strong></p>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="background-color:#f4f6f8; padding:16px 32px; font-size:12px; color:#888888; text-align:center;">
              Bu e-posta $effectiveAgencyName tarafından size mülk yönetim bildirimi olarak gönderilmiştir.
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
  ConsumerState<OwnershipShareSheet> createState() => _OwnershipShareSheetState();
}

enum LandlordInviteStatus {
  confirmed,
  pending,
  notSent,
  noEmail,
}

class _EmailPreviewStrings {
  final String salutationPrefix;
  String get salutationSuffix => ',';
  final String introPrefix;
  final String introMid;
  final String introSuffix;
  final String toGetStarted;
  final String openWebApp;
  final String orDownloadApp;
  final String signUpPrefix;
  final String signUpSuffix;
  final String warningPrefix;
  final String warningSuffix;
  final String afterRegistration;
  final String questionsPrefix;
  final String reachUsText;
  final String questionsSuffix;
  final String bestRegards;
  final String teamPrefix;
  final String teamSuffix;
  final String footerTemplate;
  final String emailFallback;
  final String htmlBadgeLabel;

  const _EmailPreviewStrings({
    required this.salutationPrefix,
    required this.introPrefix,
    required this.introMid,
    required this.introSuffix,
    required this.toGetStarted,
    required this.openWebApp,
    required this.orDownloadApp,
    required this.signUpPrefix,
    required this.signUpSuffix,
    required this.warningPrefix,
    required this.warningSuffix,
    required this.afterRegistration,
    required this.questionsPrefix,
    required this.reachUsText,
    required this.questionsSuffix,
    required this.bestRegards,
    this.teamPrefix = '',
    this.teamSuffix = '',
    required this.footerTemplate,
    required this.emailFallback,
    required this.htmlBadgeLabel,
  });

  String getFooter(String agencyName) {
    return footerTemplate.replaceAll('{agency}', agencyName);
  }

  static _EmailPreviewStrings forLang(String languageCode) {
    final norm = languageCode.replaceAll('_', '-').toLowerCase();
    if (norm.startsWith('en')) {
      return const _EmailPreviewStrings(
        salutationPrefix: 'Hello ',
        introPrefix: 'As ',
        introMid: ', we have added your property located at ',
        introSuffix: ' to the Stanomer application. This allows you to view all processes related to your property, such as rent payments, expenses, and maintenance processes, in real-time and track them transparently.',
        toGetStarted: 'To get started:',
        openWebApp: 'Open the web application',
        orDownloadApp: ' or download the mobile app: ',
        signUpPrefix: 'Sign up using your ',
        signUpSuffix: ' address.',
        warningPrefix: '⚠️ Be sure to use the ',
        warningSuffix: ' address when signing up, otherwise your property will not match with your account.',
        afterRegistration: 'Once registered, all details regarding your property will appear in your account.',
        questionsPrefix: 'If you have any questions, you can ',
        reachUsText: 'reach us here',
        questionsSuffix: '.',
        bestRegards: 'Best regards,',
        teamSuffix: ' team',
        footerTemplate: 'This email was sent to you by {agency} as a property management notification.',
        emailFallback: 'email',
        htmlBadgeLabel: 'HTML Email',
      );
    }
    if (norm == 'sr-cyrl') {
      return const _EmailPreviewStrings(
        salutationPrefix: 'Здраво ',
        introPrefix: 'Као ',
        introMid: ', додали смо вашу некретнину на адреси ',
        introSuffix: ' у Станомер апликацију. На овај начин можете у реалном времену прегледати све процесе везане за вашу некретнину, као што су уплате кирије, трошкови и процеси одржавања, и пратити их на транспарентан начин.',
        toGetStarted: 'За почетак:',
        openWebApp: 'Отворите веб апликацију',
        orDownloadApp: ' или преузмите мобилну апликацију: ',
        signUpPrefix: 'Региструјте се помоћу ваше ',
        signUpSuffix: ' адресе.',
        warningPrefix: '⚠️ Приликом регистрације обавезно користите ',
        warningSuffix: ' адресу, у супротном се ваша некретнина неће повезати са вашим налогом.',
        afterRegistration: 'Након регистрације, сви детаљи у вези са вашом некретнином појавиће се на вашем налогу.',
        questionsPrefix: 'Ако имате било каквих питања, можете нам ',
        reachUsText: 'се обратити овде',
        questionsSuffix: '.',
        bestRegards: 'С поштовањем,',
        teamSuffix: ' тим',
        footerTemplate: 'Овај имејл вам је послао {agency} као обавештење о управљању некретнином.',
        emailFallback: 'имејл',
        htmlBadgeLabel: 'HTML имејл',
      );
    }
    if (norm.startsWith('sr')) {
      return const _EmailPreviewStrings(
        salutationPrefix: 'Zdravo ',
        introPrefix: 'Kao ',
        introMid: ', dodali smo vašu nekretninu na adresi ',
        introSuffix: ' u Stanomer aplikaciju. Na ovaj način možete u realnom vremenu pregledati sve procese vezane za vašu nekretninu, kao što su uplate kirije, troškovi i procesi održavanja, i pratiti ih na transparentan način.',
        toGetStarted: 'Za početak:',
        openWebApp: 'Otvorite veb aplikaciju',
        orDownloadApp: ' ili preuzmite mobilnu aplikaciju: ',
        signUpPrefix: 'Registrujte se pomoću vaše ',
        signUpSuffix: ' adrese.',
        warningPrefix: '⚠️ Prilikom registracije obavezno koristite ',
        warningSuffix: ' adresu, u suprotnom se vaša nekretnina neće povezati sa vašim nalogom.',
        afterRegistration: 'Nakon registracije, svi detalji u vezi sa vašom nekretninom pojaviće se na vašem nalogu.',
        questionsPrefix: 'Ako imate bilo kakvih pitanja, možete nam ',
        reachUsText: 'se obratiti ovde',
        questionsSuffix: '.',
        bestRegards: 'S poštovanjem,',
        teamSuffix: ' tim',
        footerTemplate: 'Ovaj imejl vam je poslao {agency} kao obaveštenje o upravljanju nekretninom.',
        emailFallback: 'imejl',
        htmlBadgeLabel: 'HTML imejl',
      );
    }
    if (norm.startsWith('ru')) {
      return const _EmailPreviewStrings(
        salutationPrefix: 'Здравствуйте, ',
        introPrefix: 'Компания ',
        introMid: ' добавила вашу недвижимость по адресу ',
        introSuffix: ' в приложение Stanomer. Благодаря этому вы сможете в режиме реального времени просматривать все операции, связанные с вашей недвижимостью, такие как арендные платежи, расходы и процессы обслуживания, а также прозрачно отслеживать их.',
        toGetStarted: 'Для начала:',
        openWebApp: 'Откройте веб-приложение',
        orDownloadApp: ' или загрузите мобильное приложение: ',
        signUpPrefix: 'Зарегистрируйтесь, используя ваш адрес ',
        signUpSuffix: '.',
        warningPrefix: '⚠️ Обязательно используйте адрес ',
        warningSuffix: ' при регистрации, иначе ваша недвижимость не привяжется к вашей учетной записи.',
        afterRegistration: 'После регистрации все данные о вашей недвижимости появятся в вашем аккаунте.',
        questionsPrefix: 'Если у вас возникнут вопросы, вы можете ',
        reachUsText: 'связаться с нами здесь',
        questionsSuffix: '.',
        bestRegards: 'С уважением,',
        teamPrefix: 'команда ',
        footerTemplate: 'Это письмо было отправлено вам компанией {agency} в качестве уведомления об управлении недвижимостью.',
        emailFallback: 'эл. почта',
        htmlBadgeLabel: 'HTML email',
      );
    }
    // Default: 'tr'
    return const _EmailPreviewStrings(
      salutationPrefix: 'Merhaba ',
      introPrefix: '',
      introMid: ' olarak, ',
      introSuffix: ' adresli mülkünüzü Stanomer uygulamasına ekledik. Bu sayede kira ödemeleri, masraflar ve bakım süreçleri gibi mülkünüzle ilgili tüm işlemleri anlık olarak görüntüleyebilir, şeffaf bir şekilde takip edebilirsiniz.',
      toGetStarted: 'Başlamak için:',
      openWebApp: 'Web uygulamasını açın',
      orDownloadApp: ' ya da mobil uygulamayı indirin: ',
      signUpPrefix: '',
      signUpSuffix: ' adresiniz ile kayıt olun.',
      warningPrefix: '⚠️ Kayıt olurken mutlaka ',
      warningSuffix: ' adresini kullanın, aksi halde mülkünüz hesabınızla eşleşmez.',
      afterRegistration: 'Kayıt olduktan sonra mülkünüze dair tüm detaylar hesabınızda görünecektir.',
      questionsPrefix: 'Herhangi bir sorunuz olursa bize ',
      reachUsText: 'buradan ulaşabilirsiniz',
      questionsSuffix: '.',
      bestRegards: 'Saygılarımızla,',
      teamSuffix: ' ekibi',
      footerTemplate: 'Bu e-posta {agency} tarafından size mülk yönetim bildirimi olarak gönderilmiştir.',
      emailFallback: 'e-posta',
      htmlBadgeLabel: 'HTML E-posta',
    );
  }
}

class _OwnershipShareSheetState extends ConsumerState<OwnershipShareSheet> {
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;
  bool _isAccepted = false;
  bool _isPrimaryConfirmed = false;
  DateTime? _lastEmailSentAt;
  bool _isSendingEmail = false;
  bool _isSendingAll = false;
  bool _showPlainTextView = false;
  String _selectedLanguage = 'tr';
  bool _localeInitialized = false;

  late List<PropertyOwner> _owners;
  int _selectedOwnerIndex = 0;
  final Map<String, DateTime> _ownerLastSentMap = {};
  final Map<String, bool> _ownerConfirmedMap = {};
  final Map<String, bool> _ownerPendingMap = {};
  final Map<String, String> _ownerTokenMap = {};

  @override
  void initState() {
    super.initState();
    _initOwners();
    _listenForAcceptance();
    _fetchOwnersAndLogs();
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

  void _initOwners() {
    if (widget.owners != null && widget.owners!.isNotEmpty) {
      _owners = List.from(widget.owners!);
    } else if (widget.landlordName.isNotEmpty || widget.landlordEmail.isNotEmpty) {
      _owners = [
        PropertyOwner(
          firstName: widget.landlordName,
          email: widget.landlordEmail,
          isPrimary: true,
        )
      ];
    } else {
      _owners = [];
    }
  }

  PropertyOwner get _currentOwner {
    if (_owners.isEmpty) {
      return PropertyOwner(
        firstName: widget.landlordName,
        email: widget.landlordEmail,
        isPrimary: true,
      );
    }
    return _owners[_selectedOwnerIndex.clamp(0, _owners.length - 1)];
  }

  DateTime? _getLastSentForOwner(PropertyOwner owner) {
    final email = (owner.email ?? '').toLowerCase().trim();
    if (email.isNotEmpty && _ownerLastSentMap.containsKey(email)) {
      return _ownerLastSentMap[email];
    }
    return _lastEmailSentAt;
  }

  LandlordInviteStatus _getStatusForOwner(PropertyOwner owner) {
    final email = (owner.email ?? '').trim().toLowerCase();
    if (email.isEmpty) {
      return LandlordInviteStatus.noEmail;
    }

    final isConfirmed = _ownerConfirmedMap[email] == true ||
        (owner.isPrimary && _isPrimaryConfirmed) ||
        (_owners.length <= 1 && _isAccepted);

    if (isConfirmed) {
      return LandlordInviteStatus.confirmed;
    }

    final isSent = _ownerLastSentMap.containsKey(email);
    final isPending = _ownerPendingMap[email] == true;
    if (isSent || isPending) {
      return LandlordInviteStatus.pending;
    }

    return LandlordInviteStatus.notSent;
  }

  Future<void> _fetchOwnersAndLogs() async {
    try {
      final client = Supabase.instance.client;
      final repo = ref.read(propertyRepositoryProvider);

      // 1. Fetch activity logs
      if (widget.propertyId != null && widget.propertyId!.isNotEmpty) {
        final res = await client
            .from('activity_logs')
            .select('created_at, metadata')
            .eq('property_id', widget.propertyId!)
            .eq('type', 'landlord_invite_email_sent')
            .order('created_at', ascending: false);

        if (res.isNotEmpty && mounted) {
          final map = <String, DateTime>{};
          DateTime? latestOverall;
          for (final row in res) {
            final createdAtStr = row['created_at'] as String?;
            final meta = row['metadata'] as Map<String, dynamic>?;
            if (createdAtStr != null) {
              final dt = DateTime.tryParse(createdAtStr)?.toLocal();
              if (dt != null) {
                latestOverall ??= dt;
                final email = (meta?['landlord_email'] as String?)?.toLowerCase().trim();
                if (email != null && email.isNotEmpty && !map.containsKey(email)) {
                  map[email] = dt;
                }
              }
            }
          }
          setState(() {
            _ownerLastSentMap.addAll(map);
            _lastEmailSentAt = latestOverall;
          });
        }
      } else {
        final res = await client
            .from('activity_logs')
            .select('created_at, metadata')
            .contains('metadata', {'token': widget.token})
            .eq('type', 'landlord_invite_email_sent')
            .order('created_at', ascending: false)
            .limit(1);

        if (res.isNotEmpty && mounted) {
          final createdAtStr = res.first['created_at'] as String?;
          if (createdAtStr != null) {
            final dt = DateTime.tryParse(createdAtStr)?.toLocal();
            if (dt != null) {
              setState(() {
                _lastEmailSentAt = dt;
                final email = widget.landlordEmail.toLowerCase().trim();
                if (email.isNotEmpty) {
                  _ownerLastSentMap[email] = dt;
                }
              });
            }
          }
        }
      }

      // 2. Fetch invitations for confirmation status
      if (widget.propertyId != null && widget.propertyId!.isNotEmpty) {
        final invites = await repo.getLandlordInvitationsForProperty(widget.propertyId!);
        if (invites.isNotEmpty && mounted) {
          final confirmedMap = <String, bool>{};
          final pendingMap = <String, bool>{};
          final tokenMap = <String, String>{};
          for (final inv in invites) {
            final email = (inv['invitee_email'] as String?)?.toLowerCase().trim();
            final status = inv['status'] as String?;
            final token = inv['token'] as String?;
            if (email != null && email.isNotEmpty) {
              if (token != null && token.isNotEmpty) tokenMap[email] = token;
              if (status == 'accepted') {
                confirmedMap[email] = true;
              } else if (status == 'pending') {
                pendingMap[email] = true;
              }
            }
            if (inv['token'] == widget.token && status == 'accepted') {
              _isAccepted = true;
              _isPrimaryConfirmed = true;
            }
          }
          setState(() {
            _ownerConfirmedMap.addAll(confirmedMap);
            _ownerPendingMap.addAll(pendingMap);
            _ownerTokenMap.addAll(tokenMap);
          });
        }

        // Check property landlord_id
        final propRes = await client
            .from('properties')
            .select('landlord_id, landlord_email')
            .eq('id', widget.propertyId!)
            .maybeSingle();

        if (propRes != null && propRes['landlord_id'] != null && mounted) {
          final lEmail = (propRes['landlord_email'] as String?)?.toLowerCase().trim();
          setState(() {
            _isPrimaryConfirmed = true;
            if (lEmail != null && lEmail.isNotEmpty) {
              _ownerConfirmedMap[lEmail] = true;
            }
            if (_owners.length <= 1) {
              _isAccepted = true;
            }
          });
        }
      } else {
        // Query by token
        final invRes = await client
            .from('invitations')
            .select('status, invitee_email')
            .eq('token', widget.token)
            .maybeSingle();
        if (invRes != null && mounted) {
          final status = invRes['status'] as String?;
          final email = (invRes['invitee_email'] as String?)?.toLowerCase().trim();
          if (status == 'accepted') {
            setState(() {
              _isAccepted = true;
              _isPrimaryConfirmed = true;
              if (email != null) _ownerConfirmedMap[email] = true;
            });
          }
        }
      }

      // 3. Fetch owners from database if not passed
      if ((widget.owners == null || widget.owners!.isEmpty) &&
          widget.propertyId != null &&
          widget.propertyId!.isNotEmpty) {
        final fetched = await repo.getPropertyOwners(widget.propertyId!);
        if (fetched.isNotEmpty && mounted) {
          setState(() {
            _owners = fetched;
            if (_selectedOwnerIndex >= _owners.length) {
              _selectedOwnerIndex = 0;
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching owners and logs: $e');
    }
  }

  void _listenForAcceptance() {
    try {
      final client = Supabase.instance.client;
      final repo = ref.read(propertyRepositoryProvider);

      if (widget.propertyId != null && widget.propertyId!.isNotEmpty) {
        _subscription = repo.getLandlordInvitationsStreamForProperty(widget.propertyId!).listen((data) {
          if (!mounted) return;
          bool changed = false;
          final updatedConfirmed = Map<String, bool>.from(_ownerConfirmedMap);
          for (final row in data) {
            if (row['target_role'] != 'landlord') continue;
            final email = (row['invitee_email'] as String?)?.toLowerCase().trim();
            final isAccepted = row['status'] == 'accepted';
            if (email != null && email.isNotEmpty && isAccepted) {
              if (updatedConfirmed[email] != true) {
                updatedConfirmed[email] = true;
                changed = true;
              }
            }
            if (row['token'] == widget.token && isAccepted && !_isAccepted) {
              _isAccepted = true;
              _isPrimaryConfirmed = true;
              changed = true;
            }
          }
          if (changed && mounted) {
            setState(() {
              _ownerConfirmedMap.clear();
              _ownerConfirmedMap.addAll(updatedConfirmed);
            });
            ref.invalidate(agencyPropertiesProvider);
            ref.invalidate(propertiesFutureProvider);

            if (_owners.length <= 1 && _isAccepted) {
              Future.delayed(const Duration(milliseconds: 2000), () {
                if (mounted) Navigator.of(context).pop();
              });
            }
          }
        });
      } else {
        _subscription = client
            .from('invitations')
            .stream(primaryKey: ['id'])
            .eq('token', widget.token)
            .listen((data) {
              if (data.isNotEmpty && mounted) {
                final status = data.first['status'] as String?;
                if (status == 'accepted' && !_isAccepted) {
                  setState(() {
                    _isAccepted = true;
                    _isPrimaryConfirmed = true;
                    final email = widget.landlordEmail.toLowerCase().trim();
                    if (email.isNotEmpty) _ownerConfirmedMap[email] = true;
                  });
                  ref.invalidate(agencyPropertiesProvider);
                  ref.invalidate(propertiesFutureProvider);
                  Future.delayed(const Duration(milliseconds: 2000), () {
                    if (mounted) Navigator.of(context).pop();
                  });
                }
              }
            });
      }
    } catch (e) {
      debugPrint('Error listening to invitation realtime stream: $e');
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  ({String subject, String body, String html, String agencyName, String agencyEmail, String ownerName, String ownerEmail}) _buildEmailDetailsForOwner(PropertyOwner owner) {
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

    final ownerName = owner.displayName.isNotEmpty
        ? owner.displayName
        : (widget.landlordName.isNotEmpty ? widget.landlordName : '');

    final ownerEmail = (owner.email != null && owner.email!.trim().isNotEmpty)
        ? owner.email!.trim()
        : widget.landlordEmail.trim();

    final email = OwnershipShareSheet.buildLandlordInviteEmail(
      agencyName: agencyName,
      agencyEmail: agencyEmail,
      address: address,
      landlordName: ownerName,
      landlordEmail: ownerEmail,
      languageCode: _selectedLanguage,
    );

    return (
      subject: email.subject,
      body: email.body,
      html: email.html,
      agencyName: agencyName,
      agencyEmail: agencyEmail,
      ownerName: ownerName,
      ownerEmail: ownerEmail,
    );
  }

  ({
    String subject,
    String body,
    String html,
    String agencyName,
    String agencyEmail,
    String ownerName,
    String ownerEmail,
    String address,
  }) _buildEmailDetails() {
    final address = (widget.propertyAddress != null && widget.propertyAddress!.trim().isNotEmpty)
        ? widget.propertyAddress!.trim()
        : widget.propertyName;

    final details = _buildEmailDetailsForOwner(_currentOwner);
    return (
      subject: details.subject,
      body: details.body,
      html: details.html,
      agencyName: details.agencyName,
      agencyEmail: details.agencyEmail,
      ownerName: details.ownerName,
      ownerEmail: details.ownerEmail,
      address: address,
    );
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
      String ownerName,
      String ownerEmail,
      String address,
    }) details,
    Color primaryColor,
  ) {
    const brandBlue = Color(0xFF1A5EB8);
    const brandBg = Color(0xFFF4F6F8);
    const warningBg = Color(0xFFFFF4E5);
    const warningBorder = Color(0xFFC8503A);
    const warningText = Color(0xFF7A3B1E);

    final s = _EmailPreviewStrings.forLang(_selectedLanguage);

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
                        text: details.ownerName,
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
                      TextSpan(
                        text: s.introSuffix,
                      ),
                    ],
                  ),
                ),
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
                              text: details.ownerEmail.isNotEmpty ? details.ownerEmail : s.emailFallback,
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
                // Warning Callout Box matching HTML table: #fff4e5 with 4px #c8503a left border
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
                          text: details.ownerEmail.isNotEmpty ? details.ownerEmail : s.emailFallback,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: s.warningSuffix,
                        ),
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
                        s.reachUsText,
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

  Widget _buildStatusBadge(LandlordInviteStatus status) {
    final loc = AppLocalizations.of(context)!;
    switch (status) {
      case LandlordInviteStatus.confirmed:
        return Container(
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
        );
      case LandlordInviteStatus.pending:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.clock, size: 12, color: Color(0xFFB45309)),
              const SizedBox(width: 4),
              Text(
                loc.invitePending,
                style: const TextStyle(
                  color: Color(0xFFB45309),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      case LandlordInviteStatus.notSent:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.mail, size: 12, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                loc.statusNotSent,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      case LandlordInviteStatus.noEmail:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.alertCircle, size: 12, color: Colors.orange.shade800),
              const SizedBox(width: 4),
              Text(
                loc.statusNoEmail,
                style: TextStyle(
                  color: Colors.orange.shade800,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
    }
  }

  Future<bool> _sendInviteEmailForOwner(PropertyOwner owner, {bool showSnackBar = true}) async {
    final loc = AppLocalizations.of(context)!;
    final details = _buildEmailDetailsForOwner(owner);
    final email = details.ownerEmail.trim();

    if (email.isEmpty) {
      if (showSnackBar && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.noEmailForUserError(details.ownerName))),
        );
      }
      return false;
    }

    try {
      // Ensure invitation token exists in invitations table for this owner
      String tokenToUse = _ownerTokenMap[email.toLowerCase()] ?? widget.token;
      if (!_ownerTokenMap.containsKey(email.toLowerCase()) &&
          widget.propertyId != null &&
          widget.propertyId!.isNotEmpty) {
        try {
          final repo = ref.read(propertyRepositoryProvider);
          final createdToken = await repo.createLandlordOwnershipInvite(
            propertyId: widget.propertyId!,
            landlordEmail: email,
            landlordName: details.ownerName,
            landlordPhone: owner.phone,
          );
          tokenToUse = createdToken;
          _ownerTokenMap[email.toLowerCase()] = createdToken;
          _ownerPendingMap[email.toLowerCase()] = true;
        } catch (e) {
          debugPrint('Silent error creating invite record for owner: $e');
        }
      }

      final success = await EmailService.sendEmail(
        toEmail: email,
        toName: details.ownerName,
        subject: details.subject,
        textContent: details.body,
        htmlContent: details.html,
        replyToEmail: details.agencyEmail.isNotEmpty ? details.agencyEmail : null,
        replyToName: details.agencyName.isNotEmpty ? details.agencyName : null,
      );

      if (!mounted) return false;

      if (success) {
        final now = DateTime.now();
        try {
          final client = Supabase.instance.client;
          final user = client.auth.currentUser;

          if (widget.propertyId != null && widget.propertyId!.isNotEmpty) {
            await client.from('activity_logs').insert({
              'property_id': widget.propertyId,
              'user_id': user?.id,
              'type': 'landlord_invite_email_sent',
              'metadata': {
                'landlord_name': details.ownerName,
                'landlord_email': email,
                'token': tokenToUse,
                'sent_at': now.toIso8601String(),
                'provider': 'brevo',
              },
            });
          }
        } catch (e) {
          debugPrint('Error logging activity for landlord invite email: $e');
        }

        if (mounted) {
          setState(() {
            _ownerLastSentMap[email.toLowerCase()] = now;
            _lastEmailSentAt = now;
            _ownerPendingMap[email.toLowerCase()] = true;
          });
          if (showSnackBar) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(LucideIcons.checkCircle, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(loc.landlordInviteSentSuccess(email))),
                  ],
                ),
                backgroundColor: const Color(0xFF16A34A),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
        return true;
      } else {
        if (showSnackBar && mounted) {
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
        return false;
      }
    } catch (e) {
      debugPrint('Error sending invite email: $e');
      if (showSnackBar && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.emailSendGenericError(e.toString())),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return false;
    }
  }

  Future<void> _sendInviteEmail() async {
    setState(() => _isSendingEmail = true);
    try {
      await _sendInviteEmailForOwner(_currentOwner, showSnackBar: true);
    } finally {
      if (mounted) {
        setState(() => _isSendingEmail = false);
      }
    }
  }

  Future<void> _sendInviteEmailToAll() async {
    final loc = AppLocalizations.of(context)!;
    final validOwners = _owners.where((o) => (o.email != null && o.email!.trim().isNotEmpty)).toList();
    if (validOwners.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.noEmailAddressDefined)),
      );
      return;
    }

    setState(() => _isSendingAll = true);
    int successCount = 0;

    try {
      for (final owner in validOwners) {
        final ok = await _sendInviteEmailForOwner(owner, showSnackBar: false);
        if (ok) successCount++;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.checkCheck, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(loc.allOwnersInviteSentSuccess(successCount.toString(), validOwners.length.toString())),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingAll = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final maxHeight = MediaQuery.of(context).size.height * 0.90;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    if (_isAccepted) {
      return Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: StanomerColors.successPrimary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.checkCircle2,
                    color: StanomerColors.successPrimary,
                    size: 56,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  loc.landlordAcceptedInviteTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: StanomerColors.textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  loc.landlordOwnershipTransferredDesc(widget.propertyName),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: StanomerColors.textTertiary),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: StanomerColors.successPrimary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(loc.ok, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
                    child: Icon(LucideIcons.keyRound, color: primaryColor, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.landlordInviteEmailTitle,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          (widget.propertyAddress != null && widget.propertyAddress!.trim().isNotEmpty)
                              ? widget.propertyAddress!
                              : widget.propertyName,
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
              if (_owners.length > 1) ...[
                // Multiple Owners Section
                () {
                  final confirmedCount = _owners.where((o) => _getStatusForOwner(o) == LandlordInviteStatus.confirmed).length;
                  return Row(
                    children: [
                      Text(
                        loc.landlordsListHeader(_owners.length.toString()),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: StanomerColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: confirmedCount == _owners.length && _owners.isNotEmpty
                              ? const Color(0xFFDCFCE7)
                              : (confirmedCount > 0 ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: confirmedCount == _owners.length && _owners.isNotEmpty
                                ? const Color(0xFF86EFAC)
                                : (confirmedCount > 0 ? const Color(0xFFFDE68A) : Colors.transparent),
                          ),
                        ),
                        child: Text(
                          loc.ownersConfirmedRatio(confirmedCount.toString(), _owners.length.toString()),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: confirmedCount == _owners.length && _owners.isNotEmpty
                                ? const Color(0xFF15803D)
                                : (confirmedCount > 0 ? const Color(0xFFB45309) : const Color(0xFF64748B)),
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (_owners.any((o) => o.email != null && o.email!.trim().isNotEmpty))
                        TextButton.icon(
                          onPressed: _isSendingAll || _isSendingEmail ? null : _sendInviteEmailToAll,
                          icon: _isSendingAll
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(LucideIcons.send, size: 14),
                          label: Text(_isSendingAll ? loc.sendingState : loc.sendToAllBtn),
                          style: TextButton.styleFrom(
                            foregroundColor: primaryColor,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  );
                }(),
                const SizedBox(height: 8),
                Column(
                  children: _owners.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final owner = entry.value;
                    final isSelected = idx == _selectedOwnerIndex;
                    final ownerEmail = (owner.email ?? '').trim();
                    final lastSent = _getLastSentForOwner(owner);
                    final hasEmail = ownerEmail.isNotEmpty;
                    final status = _getStatusForOwner(owner);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryColor.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? primaryColor : StanomerColors.borderDefault,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          setState(() {
                            _selectedOwnerIndex = idx;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: isSelected ? primaryColor : Colors.grey.shade200,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${idx + 1}',
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.grey.shade700,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            owner.displayName,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13.5,
                                              color: isSelected ? primaryColor : StanomerColors.textPrimary,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (owner.isPrimary) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: primaryColor.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              loc.primaryOwnerBadge,
                                              style: TextStyle(color: primaryColor, fontSize: 10, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                        if (owner.ownershipPercentage > 0 && owner.ownershipPercentage < 100) ...[
                                          const SizedBox(width: 6),
                                          Text(
                                            '%${owner.ownershipPercentage.toInt()}',
                                            style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      hasEmail ? ownerEmail : loc.noEmailSpecified,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: hasEmail ? StanomerColors.textTertiary : Colors.orange.shade700,
                                        fontStyle: hasEmail ? FontStyle.normal : FontStyle.italic,
                                      ),
                                    ),
                                    if (lastSent != null) ...[
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          const Icon(LucideIcons.send, size: 10, color: Color(0xFF15803D)),
                                          const SizedBox(width: 4),
                                          Text(
                                            loc.lastSentAt(DateFormat('d MMM, HH:mm', Localizations.localeOf(context).languageCode).format(lastSent)),
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
                              const SizedBox(width: 8),
                              _buildStatusBadge(status),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ] else ...[
                // Single Owner Card
                () {
                  final currentStatus = _getStatusForOwner(_currentOwner);
                  final currentLastSent = _getLastSentForOwner(_currentOwner);

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: StanomerColors.borderDefault),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.userCheck, color: primaryColor, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _currentOwner.displayName.isNotEmpty
                                    ? _currentOwner.displayName
                                    : loc.landlord,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              if ((_currentOwner.email ?? '').isNotEmpty)
                                Text(
                                  _currentOwner.email!,
                                  style: const TextStyle(fontSize: 12, color: StanomerColors.textTertiary),
                                ),
                              if (currentLastSent != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(LucideIcons.send, size: 10, color: Color(0xFF15803D)),
                                    const SizedBox(width: 4),
                                    Text(
                                      loc.lastSentAt(DateFormat('d MMM, HH:mm', Localizations.localeOf(context).languageCode).format(currentLastSent)),
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
                        const SizedBox(width: 8),
                        _buildStatusBadge(currentStatus),
                      ],
                    ),
                  );
                }(),
              ],
              if (_getStatusForOwner(_currentOwner) == LandlordInviteStatus.confirmed) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.checkCircle2, color: Color(0xFF16A34A), size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          loc.ownerConfirmedBanner(_currentOwner.displayName),
                          style: const TextStyle(
                            color: Color(0xFF15803D),
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              // Email Preview Box (Subject & Body)
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
                              _owners.length > 1
                                  ? loc.emailPreviewForOwner(_currentOwner.displayName)
                                  : loc.emailPreviewTitle,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
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
                                          loc.tabPlainText,
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
              () {
                final currentStatus = _getStatusForOwner(_currentOwner);
                final currentLastSent = _getLastSentForOwner(_currentOwner);
                final isCurrentConfirmed = currentStatus == LandlordInviteStatus.confirmed;
                final hasCurrentSent = currentLastSent != null;

                final btnLabel = _isSendingEmail
                    ? loc.sendingState
                    : ((_currentOwner.email ?? '').trim().isEmpty
                        ? loc.noEmailAddressDefined
                        : (_owners.length > 1
                            ? (isCurrentConfirmed || hasCurrentSent
                                ? loc.resendInviteForOwnerBtn(_currentOwner.displayName)
                                : loc.sendInviteForOwnerBtn(_currentOwner.displayName))
                            : (isCurrentConfirmed || hasCurrentSent
                                ? loc.resendInviteEmailBtn
                                : loc.sendLandlordInviteEmailBtn)));

                return ElevatedButton.icon(
                  onPressed: (_currentOwner.email ?? '').trim().isEmpty || _isSendingEmail || _isSendingAll
                      ? null
                      : _sendInviteEmail,
                  icon: _isSendingEmail
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Icon(
                          isCurrentConfirmed
                              ? LucideIcons.checkCheck
                              : (hasCurrentSent ? LucideIcons.mailCheck : LucideIcons.send),
                          size: 18,
                        ),
                  label: Text(
                    btnLabel,
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
                );
              }(),
              if (_owners.length > 1) ...[
                const SizedBox(height: 10),
                () {
                  final validOwners = _owners.where((o) => (o.email ?? '').trim().isNotEmpty).toList();
                  final allConfirmed = validOwners.isNotEmpty &&
                      validOwners.every((o) => _getStatusForOwner(o) == LandlordInviteStatus.confirmed);

                  final allBtnLabel = _isSendingAll
                      ? loc.sendingAllState
                      : (allConfirmed
                          ? loc.resendToAllOwnersBtn(validOwners.length.toString())
                          : loc.sendToAllOwnersBtn(validOwners.length.toString()));

                  return OutlinedButton.icon(
                    onPressed: _isSendingAll || _isSendingEmail ? null : _sendInviteEmailToAll,
                    icon: _isSendingAll
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(LucideIcons.sendHorizontal, size: 16),
                    label: Text(
                      allBtnLabel,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                      side: BorderSide(color: primaryColor.withValues(alpha: 0.5)),
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  );
                }(),
              ],
              const SizedBox(height: 12),
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

