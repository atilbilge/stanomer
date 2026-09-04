import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stanomer/core/l10n/app_localizations.dart';
import 'package:stanomer/features/agency/domain/agency_color_scheme.dart';
import 'package:stanomer/features/auth/data/auth_providers.dart';
import 'package:stanomer/features/property/presentation/widgets/ownership_share_sheet.dart';

import 'package:stanomer/features/property/domain/property_owner.dart';

void main() {
  group('OwnershipShareSheet Tests', () {
    testWidgets('Renders multiple owners, switches preview on selection, and provides separate send actions', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            agencyColorSchemeProvider.overrideWithValue(const AgencyColorScheme.agencyScheme()),
            profileFutureProvider.overrideWith((ref) async => {
              'company_name': 'Optimal Emlak',
              'full_name': 'Ahmet Danışman',
              'email': 'acente@optimal.com',
            }),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('tr'),
            home: Scaffold(
              body: OwnershipShareSheet(
                propertyName: 'Göztepe Dairesi',
                propertyAddress: 'Bağdat Caddesi No: 120, Kadıköy',
                landlordName: 'Ali Yılmaz',
                landlordEmail: 'ali@example.com',
                token: 'test_token_123',
                propertyId: 'prop-uuid-multi',
                owners: [
                  PropertyOwner(
                    firstName: 'Ali',
                    lastName: 'Yılmaz',
                    email: 'ali@example.com',
                    isPrimary: true,
                    ownershipPercentage: 50,
                  ),
                  PropertyOwner(
                    firstName: 'Ayşe',
                    lastName: 'Yılmaz',
                    email: 'ayse@example.com',
                    isPrimary: false,
                    ownershipPercentage: 50,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify header and both owners
      expect(find.text('Ev Sahipleri (2)'), findsOneWidget);
      expect(find.text('0/2 Onaylandı'), findsOneWidget);
      expect(find.text('Ali Yılmaz'), findsOneWidget);
      expect(find.text('Ayşe Yılmaz'), findsOneWidget);
      expect(find.text('ali@example.com'), findsOneWidget);
      expect(find.text('ayse@example.com'), findsOneWidget);
      expect(find.text('Gönderilmedi'), findsNWidgets(2));

      // Verify initial selected owner (Ali Yılmaz)
      expect(find.text('E-posta Önizlemesi (Ali Yılmaz)'), findsOneWidget);
      expect(find.textContaining('Merhaba Ali Yılmaz'), findsOneWidget);
      expect(find.text('Ali Yılmaz İçin Davet Maili Gönder'), findsOneWidget);
      expect(find.textContaining('Tüm Ev Sahiplerine Ayrı Ayrı Gönder'), findsOneWidget);

      // Tap on the second owner (Ayşe Yılmaz)
      await tester.tap(find.text('Ayşe Yılmaz'));
      await tester.pumpAndSettle();

      // Verify preview updated for Ayşe Yılmaz
      expect(find.text('E-posta Önizlemesi (Ayşe Yılmaz)'), findsOneWidget);
      expect(find.textContaining('Merhaba Ayşe Yılmaz'), findsOneWidget);
      expect(find.text('Ayşe Yılmaz İçin Davet Maili Gönder'), findsOneWidget);
    });
    testWidgets('Renders landlord info and email invite action button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            agencyColorSchemeProvider.overrideWithValue(const AgencyColorScheme.agencyScheme()),
            profileFutureProvider.overrideWith((ref) async => {
              'company_name': 'Optimal Emlak',
              'full_name': 'Ahmet Danışman',
              'email': 'acente@optimal.com',
            }),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('tr'),
            home: Scaffold(
              body: OwnershipShareSheet(
                propertyName: 'Göztepe Dairesi',
                propertyAddress: 'Bağdat Caddesi No: 120, Kadıköy',
                landlordName: 'Mehmet Öz',
                landlordEmail: 'mehmet@example.com',
                token: 'test_token_123',
                propertyId: 'prop-uuid-1',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check landlord name and email display
      expect(find.text('Mehmet Öz'), findsOneWidget);
      expect(find.text('mehmet@example.com'), findsOneWidget);

      // Check email preview header, subject, and body
      expect(find.text('Gönderilecek E-posta Önizlemesi'), findsOneWidget);
      expect(find.text('KONU'), findsOneWidget);
      expect(find.text('İÇERİK'), findsOneWidget);
      expect(find.text('[Bağdat Caddesi No: 120, Kadıköy] mülkünüz Stanomer\'e eklendi'), findsOneWidget);
      expect(find.textContaining('Merhaba Mehmet Öz'), findsOneWidget);
      expect(find.textContaining('Optimal Emlak olarak'), findsOneWidget);

      // Check email action button
      expect(find.text('Ev Sahibine Davet Maili Gönder'), findsOneWidget);
      expect(find.byIcon(Icons.copy), findsNothing); // Should be LucideIcons
    });

    testWidgets('Email button is disabled when landlord email is empty', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            agencyColorSchemeProvider.overrideWithValue(const AgencyColorScheme.agencyScheme()),
            profileFutureProvider.overrideWith((ref) async => {
              'company_name': 'Optimal Emlak',
              'email': 'acente@optimal.com',
            }),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('tr'),
            home: Scaffold(
              body: OwnershipShareSheet(
                propertyName: 'Göztepe Dairesi',
                landlordName: 'Mehmet Öz',
                landlordEmail: '',
                token: 'test_token_123',
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('E-posta Adresi Tanımsız'), findsOneWidget);
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    test('Email template matches user prompt specification verbatim', () {
      final emailContent = OwnershipShareSheet.buildLandlordInviteEmail(
        agencyName: 'Optima Emlak',
        agencyEmail: 'info@optimaemlak.com',
        address: 'Bağdat Caddesi No: 42, Kadıköy',
        landlordName: 'Ahmet Yılmaz',
        landlordEmail: 'ahmet@yilmaz.com',
      );

      expect(emailContent.subject, equals('[Bağdat Caddesi No: 42, Kadıköy] mülkünüz Stanomer\'e eklendi'));
      
      final expectedBody = '''Merhaba Ahmet Yılmaz,

Optima Emlak olarak, Bağdat Caddesi No: 42, Kadıköy adresli mülkünüzü Stanomer uygulamasına ekledik. 
Bu sayede kira ödemeleri, masraflar ve bakım süreçleri gibi mülkünüzle ilgili 
tüm işlemleri anlık olarak görüntüleyebilir, şeffaf bir şekilde takip edebilirsiniz.

Başlamak için:

1. Web uygulamasını açın (https://www.stanomer.online/app) ya da mobil uygulamayı indirin. 
(https://apps.apple.com/us/app/stanomer/id6762311157 ve https://play.google.com/store/apps/details?id=com.aboptima.stanomer)
2. ahmet@yilmaz.com adresiniz ile kayıt olun.

⚠️ Kayıt olurken mutlaka ahmet@yilmaz.com adresini kullanın, aksi halde mülkünüz 
hesabınızla eşleşmez.

Kayıt olduktan sonra mülkünüze dair tüm detaylar hesabınızda görünecektir.

Herhangi bir sorunuz olursa bize info@optimaemlak.com üzerinden ulaşabilirsiniz.

Saygılarımızla,
Optima Emlak ekibi''';

      expect(emailContent.body, equals(expectedBody));

      // Check HTML template structure and links
      expect(emailContent.html, contains('<!DOCTYPE html>'));
      expect(emailContent.html, contains('<title>Stanomer - Mülk Bildirimi</title>'));
      expect(emailContent.html, contains('Merhaba <strong>Ahmet Yılmaz</strong>,'));
      expect(emailContent.html, contains('<strong>Optima Emlak</strong> olarak, <strong>Bağdat Caddesi No: 42, Kadıköy</strong>'));
      expect(emailContent.html, contains('<a href="https://www.stanomer.online/app"'));
      expect(emailContent.html, contains('<a href="https://apps.apple.com/us/app/stanomer/id6762311157"'));
      expect(emailContent.html, contains('<a href="https://play.google.com/store/apps/details?id=com.aboptima.stanomer"'));
      expect(emailContent.html, contains('<strong>ahmet@yilmaz.com</strong>'));
      expect(emailContent.html, contains('<a href="mailto:info@optimaemlak.com"'));
      expect(emailContent.html, contains('<strong>Optima Emlak ekibi</strong>'));
      expect(emailContent.html, contains('Bu e-posta Optima Emlak tarafından size mülk yönetim bildirimi olarak gönderilmiştir.'));
    });

    testWidgets('Shows E-posta Yok badge for owner without email and Gönderilmedi for owner with email', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            agencyColorSchemeProvider.overrideWithValue(const AgencyColorScheme.agencyScheme()),
            profileFutureProvider.overrideWith((ref) async => {
              'company_name': 'Optimal Emlak',
              'full_name': 'Ahmet Danışman',
              'email': 'acente@optimal.com',
            }),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('tr'),
            home: Scaffold(
              body: OwnershipShareSheet(
                propertyName: 'Moda Apartmanı',
                landlordName: 'Can Demir',
                landlordEmail: 'can@demir.com',
                token: 'token_mixed_123',
                propertyId: 'prop-mixed-1',
                owners: [
                  PropertyOwner(
                    firstName: 'Can',
                    lastName: 'Demir',
                    email: 'can@demir.com',
                    isPrimary: true,
                    ownershipPercentage: 50,
                  ),
                  PropertyOwner(
                    firstName: 'Selin',
                    lastName: 'Demir',
                    email: null,
                    isPrimary: false,
                    ownershipPercentage: 50,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Ev Sahipleri (2)'), findsOneWidget);
      expect(find.text('0/2 Onaylandı'), findsOneWidget);
      expect(find.text('Gönderilmedi'), findsOneWidget);
      expect(find.text('E-posta Yok'), findsOneWidget);
      expect(find.text('E-posta adresi belirtilmemiş'), findsOneWidget);
    });

    testWidgets('Email preview renders formatted visual card by default and can toggle to plain text', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            agencyColorSchemeProvider.overrideWithValue(const AgencyColorScheme.agencyScheme()),
            profileFutureProvider.overrideWith((ref) async => {
              'company_name': 'Optimal Emlak',
              'full_name': 'Ahmet Danışman',
              'email': 'acente@optimal.com',
            }),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('tr'),
            home: Scaffold(
              body: OwnershipShareSheet(
                propertyName: 'Moda Dairesi',
                propertyAddress: 'Moda Caddesi No: 45, Kadıköy',
                landlordName: 'Kemal Yıldız',
                landlordEmail: 'kemal@yildiz.com',
                token: 'token_preview_123',
                propertyId: 'prop-preview-1',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Formatted preview is default
      expect(find.text('Görsel'), findsOneWidget);
      expect(find.text('Düz Metin'), findsOneWidget);
      expect(find.text('HTML E-posta'), findsOneWidget);
      expect(find.text('Stanomer'), findsOneWidget);
      expect(find.text('Web uygulamasını açın'), findsOneWidget);
      expect(find.text('App Store'), findsOneWidget);
      expect(find.text('Google Play'), findsOneWidget);
      expect(find.textContaining('⚠️ Kayıt olurken mutlaka'), findsOneWidget);
      expect(find.textContaining('Alıcıya bu formatta gidecektir'), findsOneWidget);

      // Tap 'Düz Metin' toggle
      await tester.tap(find.text('Düz Metin'));
      await tester.pumpAndSettle();

      // In plain text mode, HTML badge and sub-indicator disappear
      expect(find.text('HTML E-posta'), findsNothing);
      expect(find.textContaining('Alıcıya bu formatta gidecektir'), findsNothing);
      expect(find.text('(Düz Metin)'), findsOneWidget);

      // Tap back to 'Görsel' toggle
      await tester.tap(find.text('Görsel'));
      await tester.pumpAndSettle();

      expect(find.text('HTML E-posta'), findsOneWidget);
      expect(find.text('(Görsel)'), findsOneWidget);
    });

    test('Multi-language buildLandlordInviteEmail generates correct HTML and body for en, sr, ru, sr_Cyrl', () {
      const agencyName = 'Optima Agency';
      const agencyEmail = 'info@optima.com';
      const address = 'Kralja Petra 12, Belgrade';
      const landlordName = 'Jovan Jovanovic';
      const landlordEmail = 'jovan@example.com';

      // 1. English
      final enEmail = OwnershipShareSheet.buildLandlordInviteEmail(
        agencyName: agencyName,
        agencyEmail: agencyEmail,
        address: address,
        landlordName: landlordName,
        landlordEmail: landlordEmail,
        languageCode: 'en',
      );
      expect(enEmail.subject, equals('[$address] your property has been added to Stanomer'));
      expect(enEmail.html, contains('<html lang="en">'));
      expect(enEmail.html, contains('<title>Stanomer - Property Notification</title>'));
      expect(enEmail.html, contains('Hello <strong>Jovan Jovanovic</strong>,'));
      expect(enEmail.html, contains('As <strong>Optima Agency</strong>, we have added your property located at <strong>Kralja Petra 12, Belgrade</strong>'));
      expect(enEmail.html, contains('⚠️ Be sure to use the <strong>jovan@example.com</strong> address when signing up'));
      expect(enEmail.html, contains('<strong>Optima Agency team</strong>'));
      expect(enEmail.html, contains('This email was sent to you by Optima Agency as a property management notification.'));
      expect(enEmail.body, contains('Hello Jovan Jovanovic,'));
      expect(enEmail.body, contains('To get started:'));

      // 2. Serbian Latin
      final srEmail = OwnershipShareSheet.buildLandlordInviteEmail(
        agencyName: agencyName,
        agencyEmail: agencyEmail,
        address: address,
        landlordName: landlordName,
        landlordEmail: landlordEmail,
        languageCode: 'sr',
      );
      expect(srEmail.subject, equals('[$address] vaša nekretnina je dodata u Stanomer'));
      expect(srEmail.html, contains('<html lang="sr">'));
      expect(srEmail.html, contains('<title>Stanomer - Obaveštenje o nekretnini</title>'));
      expect(srEmail.html, contains('Zdravo <strong>Jovan Jovanovic</strong>,'));
      expect(srEmail.html, contains('Kao <strong>Optima Agency</strong>, dodali smo vašu nekretninu na adresi <strong>Kralja Petra 12, Belgrade</strong>'));
      expect(srEmail.html, contains('⚠️ Prilikom registracije obavezno koristite <strong>jovan@example.com</strong> adresu'));
      expect(srEmail.html, contains('<strong>Optima Agency tim</strong>'));
      expect(srEmail.html, contains('Ovaj imejl vam je poslao Optima Agency kao obaveštenje o upravljanju nekretninom.'));
      expect(srEmail.body, contains('Zdravo Jovan Jovanovic,'));
      expect(srEmail.body, contains('Za početak:'));

      // 3. Russian
      final ruEmail = OwnershipShareSheet.buildLandlordInviteEmail(
        agencyName: agencyName,
        agencyEmail: agencyEmail,
        address: address,
        landlordName: landlordName,
        landlordEmail: landlordEmail,
        languageCode: 'ru',
      );
      expect(ruEmail.subject, equals('[$address] ваша недвижимость добавлена в Stanomer'));
      expect(ruEmail.html, contains('<html lang="ru">'));
      expect(ruEmail.html, contains('<title>Stanomer - Уведомление о недвижимости</title>'));
      expect(ruEmail.html, contains('Здравствуйте, <strong>Jovan Jovanovic</strong>,'));
      expect(ruEmail.html, contains('Компания <strong>Optima Agency</strong> добавила вашу недвижимость по адресу <strong>Kralja Petra 12, Belgrade</strong>'));
      expect(ruEmail.html, contains('⚠️ Обязательно используйте адрес <strong>jovan@example.com</strong> при регистрации'));
      expect(ruEmail.html, contains('<strong>команда Optima Agency</strong>'));
      expect(ruEmail.html, contains('Это письмо было отправлено вам компанией Optima Agency в качестве уведомления об управлении недвижимостью.'));
      expect(ruEmail.body, contains('Здравствуйте, Jovan Jovanovic,'));
      expect(ruEmail.body, contains('Для начала:'));

      // 4. Serbian Cyrillic
      final srCyrlEmail = OwnershipShareSheet.buildLandlordInviteEmail(
        agencyName: agencyName,
        agencyEmail: agencyEmail,
        address: address,
        landlordName: landlordName,
        landlordEmail: landlordEmail,
        languageCode: 'sr_Cyrl',
      );
      expect(srCyrlEmail.subject, equals('[$address] ваша некретнина је додата у Станомер'));
      expect(srCyrlEmail.html, contains('<html lang="sr-Cyrl">'));
      expect(srCyrlEmail.html, contains('<title>Stanomer - Обавештење о некретнини</title>'));
      expect(srCyrlEmail.html, contains('Здраво <strong>Jovan Jovanovic</strong>,'));
      expect(srCyrlEmail.html, contains('Као <strong>Optima Agency</strong>, додали смо вашу некретнину на адреси <strong>Kralja Petra 12, Belgrade</strong>'));
      expect(srCyrlEmail.html, contains('⚠️ Приликом регистрације обавезно користите <strong>jovan@example.com</strong> адресу'));
      expect(srCyrlEmail.html, contains('<strong>Optima Agency тим</strong>'));
      expect(srCyrlEmail.html, contains('Овај имејл вам је послао Optima Agency као обавештење о управљању некретнином.'));
      expect(srCyrlEmail.body, contains('Здраво Jovan Jovanovic,'));
      expect(srCyrlEmail.body, contains('За почетак:'));
    });

    testWidgets('Language selector toggles template language in preview box', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            agencyColorSchemeProvider.overrideWithValue(const AgencyColorScheme.agencyScheme()),
            profileFutureProvider.overrideWith((ref) async => {
              'company_name': 'Optimal Real Estate',
              'full_name': 'Alex Agent',
              'email': 'agent@optimal.com',
            }),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('tr'),
            home: Scaffold(
              body: OwnershipShareSheet(
                propertyName: 'Belgrade Flat',
                propertyAddress: 'Terazije 1, Belgrade',
                landlordName: 'Marko Markovic',
                landlordEmail: 'marko@example.com',
                token: 'token_lang_123',
                propertyId: 'prop-lang-1',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially Turkish (default)
      expect(find.text('Dil:'), findsOneWidget);
      expect(find.text('TR'), findsOneWidget);
      expect(find.text('EN'), findsOneWidget);
      expect(find.text('SR'), findsOneWidget);
      expect(find.text('RU'), findsOneWidget);
      expect(find.text('SR (Ћир)'), findsOneWidget);

      expect(find.text('[Terazije 1, Belgrade] mülkünüz Stanomer\'e eklendi'), findsOneWidget);
      expect(find.textContaining('Merhaba Marko Markovic'), findsOneWidget);

      // Tap EN
      await tester.tap(find.text('EN'));
      await tester.pumpAndSettle();

      expect(find.text('[Terazije 1, Belgrade] your property has been added to Stanomer'), findsOneWidget);
      expect(find.textContaining('Hello Marko Markovic'), findsOneWidget);
      expect(find.text('Open the web application'), findsOneWidget);
      expect(find.textContaining('⚠️ Be sure to use the'), findsOneWidget);

      // Tap SR
      await tester.tap(find.text('SR'));
      await tester.pumpAndSettle();

      expect(find.text('[Terazije 1, Belgrade] vaša nekretnina je dodata u Stanomer'), findsOneWidget);
      expect(find.textContaining('Zdravo Marko Markovic'), findsOneWidget);
      expect(find.text('Otvorite veb aplikaciju'), findsOneWidget);
      expect(find.textContaining('⚠️ Prilikom registracije obavezno koristite'), findsOneWidget);

      // Tap RU
      await tester.tap(find.text('RU'));
      await tester.pumpAndSettle();

      expect(find.text('[Terazije 1, Belgrade] ваша недвижимость добавлена в Stanomer'), findsOneWidget);
      expect(find.textContaining('Здравствуйте, Marko Markovic'), findsOneWidget);
      expect(find.text('Откройте веб-приложение'), findsOneWidget);
      expect(find.textContaining('⚠️ Обязательно используйте адрес'), findsOneWidget);

      // Tap SR (Ћир)
      await tester.tap(find.text('SR (Ћир)'));
      await tester.pumpAndSettle();

      expect(find.text('[Terazije 1, Belgrade] ваша некретнина је додата у Станомер'), findsOneWidget);
      expect(find.textContaining('Здраво Marko Markovic'), findsOneWidget);
      expect(find.text('Отворите веб апликацију'), findsOneWidget);
      expect(find.textContaining('⚠️ Приликом регистрације обавезно користите'), findsOneWidget);
    });
  });
}
