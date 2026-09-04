import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stanomer/core/l10n/app_localizations.dart';
import 'package:stanomer/features/agency/domain/agency_color_scheme.dart';
import 'package:stanomer/features/auth/data/auth_providers.dart';
import 'package:stanomer/features/property/domain/contract.dart';
import 'package:stanomer/features/property/domain/property.dart';
import 'package:stanomer/features/property/presentation/widgets/tenant_invite_share_sheet.dart';

void main() {
  group('Tenant Invite Email Flow & Template Tests', () {
    test('buildTenantInviteEmail generates compliant subject, plain text and formatted HTML body', () {
      final emailData = TenantInviteShareSheet.buildTenantInviteEmail(
        agencyName: 'Stanomer Gayrimenkul',
        agencyEmail: 'acente@stanomer.com',
        address: 'Barbaros Bulvarı No: 42, Beşiktaş',
        tenantName: 'Mehmet Demir',
        tenantEmail: 'mehmet.demir@example.com',
        monthlyRent: 25000,
        currency: 'TRY',
        depositAmount: 50000,
        startDate: DateTime(2026, 9, 1),
      );

      // Subject check
      expect(emailData.subject, contains('[Barbaros Bulvarı No: 42, Beşiktaş] mülkü için kira daveti'));

      // Plain text check
      expect(emailData.body, contains('Merhaba Mehmet Demir'));
      expect(emailData.body, contains('Barbaros Bulvarı No: 42, Beşiktaş'));
      expect(emailData.body, contains('25000 TRY'));
      expect(emailData.body, contains('50000 TRY'));
      expect(emailData.body, contains('mehmet.demir@example.com'));
      expect(emailData.body, contains('https://www.stanomer.online'));

      // HTML template styling and content checks
      final html = emailData.html;
      expect(html, contains('Stanomer Gayrimenkul'));
      expect(html, contains('Barbaros Bulvarı No: 42, Beşiktaş'));
      expect(html, contains('Merhaba <strong>Mehmet Demir</strong>'));
      expect(html, contains('25000 TRY'));
      expect(html, contains('50000 TRY'));
      expect(html, contains('01/09/2026'));
      expect(html, contains('mehmet.demir@example.com'));

      // HTML Brand Header & Design Consistency (#1a5eb8, #fff4e5, #c8503a, card styling)
      expect(html, contains('#1a5eb8')); // Stanomer primary brand blue header
      expect(html, contains('#fff4e5')); // Notice callout background
      expect(html, contains('4px solid #c8503a')); // Warning left border
      expect(html, contains('App Store'));
      expect(html, contains('Google Play'));
      expect(html, contains('acente@stanomer.com'));
    });

    test('buildTenantInviteEmail handles empty/fallback values gracefully', () {
      final emailData = TenantInviteShareSheet.buildTenantInviteEmail(
        agencyName: '',
        agencyEmail: '',
        address: '',
        tenantName: '',
        tenantEmail: 'kiraci@test.com',
      );

      expect(emailData.subject, contains('[Mülk] mülkü için kira daveti'));
      expect(emailData.body, contains('Merhaba Kiracı'));
      expect(emailData.html, contains('Emlak Acentesi'));
      expect(emailData.html, contains('kiraci@test.com'));
    });

    testWidgets('TenantInviteShareSheet renders preview, switches between Visual and Plain Text, and shows send button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            agencyColorSchemeProvider.overrideWithValue(const AgencyColorScheme.agencyScheme()),
            profileFutureProvider.overrideWith((ref) async => {
              'company_name': 'Optimal Gayrimenkul',
              'full_name': 'Ahmet Danışman',
              'email': 'acente@optimal.com',
            }),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('tr'),
            home: Scaffold(
              body: TenantInviteShareSheet(
                propertyName: 'Moda 2+1 Daire',
                propertyAddress: 'Caferağa Mah. Moda Cad. No:15, Kadıköy',
                tenantName: 'Can Yılmaz',
                tenantEmail: 'can.yilmaz@example.com',
                token: 'token_abc_123',
                propertyId: 'prop-agency-1',
                contractId: 'contract-agency-1',
                monthlyRent: 30000,
                currency: 'TRY',
                depositAmount: 60000,
                startDate: DateTime(2026, 9, 15),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check header and tenant information
      expect(find.text('Kiracı Davet E-postası'), findsOneWidget);
      expect(find.text('Can Yılmaz'), findsWidgets);
      expect(find.text('can.yilmaz@example.com'), findsWidgets);

      // Check preview toggle tabs
      expect(find.text('Görsel'), findsOneWidget);
      expect(find.text('Düz Metin'), findsOneWidget);

      // Visual preview is default selected
      expect(find.textContaining('Can Yılmaz'), findsWidgets);
      expect(find.textContaining('30000 TRY'), findsWidgets);

      // Send action button
      expect(find.text('Kiracıya Davet Maili Gönder'), findsOneWidget);

      // Tap Plain Text tab
      await tester.tap(find.text('Düz Metin'));
      await tester.pumpAndSettle();

      // Plain text preview displayed
      expect(find.textContaining('Can Yılmaz'), findsWidgets);
      expect(find.textContaining('Başlangıç Tarihi:'), findsWidgets);

      // Tap back to Visual tab
      await tester.tap(find.text('Görsel'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Sözleşme Özeti'), findsWidgets);
    });

    test('buildTenantInviteEmail generates localized templates for EN, SR, RU, and SR (Cyrillic)', () {
      const agency = 'Axia Exclusive';
      const agencyEmail = 'office@axiaexclusive.com';
      const address = 'Zlatna ulica 14, Sprat 2 1800';
      const tenant = 'Luka Jovanović';
      const tenantEmail = 'luka@tenant.com';
      final startDate = DateTime(2026, 6, 1);

      // 1. English (en)
      final en = TenantInviteShareSheet.buildTenantInviteEmail(
        agencyName: agency,
        agencyEmail: agencyEmail,
        address: address,
        tenantName: tenant,
        tenantEmail: tenantEmail,
        monthlyRent: 500,
        currency: 'EUR',
        depositAmount: 500,
        startDate: startDate,
        languageCode: 'en',
      );
      expect(en.subject, contains('[$address] lease agreement notification'));
      expect(en.html, contains('<title>Stanomer - Tenant Notification</title>'));
      expect(en.html, contains('Hello <strong>$tenant</strong>'));
      expect(en.html, contains('Agreement Summary'));
      expect(en.html, contains('Monthly Rent'));
      expect(en.html, contains('Deposit'));
      expect(en.html, contains('Start Date'));
      expect(en.html, contains('500 EUR'));
      expect(en.html, contains('01/06/2026'));
      expect(en.html, contains('Be sure to use the <strong>$tenantEmail</strong> address'));
      expect(en.html, contains('This email was sent to you by $agency as a tenant notification email.'));
      expect(en.body, contains('Hello Luka Jovanović'));

      // 2. Serbian Latin (sr)
      final sr = TenantInviteShareSheet.buildTenantInviteEmail(
        agencyName: agency,
        agencyEmail: agencyEmail,
        address: address,
        tenantName: tenant,
        tenantEmail: tenantEmail,
        monthlyRent: 500,
        currency: 'EUR',
        depositAmount: 500,
        startDate: startDate,
        languageCode: 'sr',
      );
      expect(sr.subject, contains('[$address] obaveštenje o ugovoru o zakupu'));
      expect(sr.html, contains('<title>Stanomer - Obaveštenje za stanara</title>'));
      expect(sr.html, contains('Zdravo <strong>$tenant</strong>'));
      expect(sr.html, contains('Pregled ugovora'));
      expect(sr.html, contains('Mesečna kirija'));
      expect(sr.html, contains('Depozit'));
      expect(sr.html, contains('Datum početka'));
      expect(sr.html, contains('Prilikom registracije obavezno koristite <strong>$tenantEmail</strong> adresu'));
      expect(sr.html, contains('Ovaj imejl vam je poslala kompanija $agency kao obaveštenje za stanara.'));
      expect(sr.body, contains('Zdravo Luka Jovanović'));

      // 3. Russian (ru)
      final ru = TenantInviteShareSheet.buildTenantInviteEmail(
        agencyName: agency,
        agencyEmail: agencyEmail,
        address: address,
        tenantName: tenant,
        tenantEmail: tenantEmail,
        monthlyRent: 500,
        currency: 'EUR',
        depositAmount: 500,
        startDate: startDate,
        languageCode: 'ru',
      );
      expect(ru.subject, contains('[$address] уведомление о договоре аренды'));
      expect(ru.html, contains('<title>Stanomer - Уведомление для арендатора</title>'));
      expect(ru.html, contains('Здравствуйте, <strong>$tenant</strong>'));
      expect(ru.html, contains('Сводка договора'));
      expect(ru.html, contains('Ежемесячная аренда'));
      expect(ru.html, contains('Депозит'));
      expect(ru.html, contains('Дата начала'));
      expect(ru.html, contains('Обязательно используйте адрес <strong>$tenantEmail</strong> при регистрации'));
      expect(ru.html, contains('Это письмо было отправлено вам компанией $agency в качестве уведомительного письма для арендатора.'));
      expect(ru.body, contains('Здравствуйте, Luka Jovanović'));

      // 4. Serbian Cyrillic (sr_Cyrl)
      final srCyrl = TenantInviteShareSheet.buildTenantInviteEmail(
        agencyName: agency,
        agencyEmail: agencyEmail,
        address: address,
        tenantName: tenant,
        tenantEmail: tenantEmail,
        monthlyRent: 500,
        currency: 'EUR',
        depositAmount: 500,
        startDate: startDate,
        languageCode: 'sr_Cyrl',
      );
      expect(srCyrl.subject, contains('[$address] обавештење о уговору о закупу'));
      expect(srCyrl.html, contains('<title>Stanomer - Обавештење за станара</title>'));
      expect(srCyrl.html, contains('Здраво <strong>$tenant</strong>'));
      expect(srCyrl.html, contains('Преглед уговора'));
      expect(srCyrl.html, contains('Месечна кирија'));
      expect(srCyrl.html, contains('Депозит'));
      expect(srCyrl.html, contains('Датум почетка'));
      expect(srCyrl.html, contains('Приликом регистрације обавезно користите <strong>$tenantEmail</strong> адресу'));
      expect(srCyrl.html, contains('Овај имејл вам је послала компанија $agency као обавештење за станара.'));
      expect(srCyrl.body, contains('Здраво Luka Jovanović'));
    });

    testWidgets('TenantInviteShareSheet language selector switches preview language dynamically', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            agencyColorSchemeProvider.overrideWithValue(const AgencyColorScheme.agencyScheme()),
            profileFutureProvider.overrideWith((ref) async => {
              'company_name': 'Axia Exclusive',
              'full_name': 'Axia Agent',
              'email': 'office@axiaexclusive.com',
            }),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('tr'),
            home: Scaffold(
              body: TenantInviteShareSheet(
                propertyName: 'Zlatna ulica Stan',
                propertyAddress: 'Zlatna ulica 14, Sprat 2 1800',
                tenantName: 'Luka Jovanović',
                tenantEmail: 'luka@tenant.com',
                token: 'tok-123',
                propertyId: 'prop-1',
                contractId: 'contract-1',
                monthlyRent: 500,
                currency: 'EUR',
                depositAmount: 500,
                startDate: DateTime(2026, 6, 1),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Language chips are visible: TR, EN, SR, RU, SR (Ћир)
      expect(find.text('TR'), findsOneWidget);
      expect(find.text('EN'), findsOneWidget);
      expect(find.text('SR'), findsOneWidget);
      expect(find.text('RU'), findsOneWidget);
      expect(find.text('SR (Ћир)'), findsOneWidget);

      // Default TR has Turkish subject
      expect(find.textContaining('mülkü için kira daveti'), findsWidgets);

      // Switch to EN
      await tester.tap(find.text('EN'));
      await tester.pumpAndSettle();
      expect(find.textContaining('lease agreement notification'), findsWidgets);
      expect(find.textContaining('Agreement Summary'), findsWidgets);

      // Switch to SR
      await tester.tap(find.text('SR'));
      await tester.pumpAndSettle();
      expect(find.textContaining('obaveštenje o ugovoru o zakupu'), findsWidgets);
      expect(find.textContaining('Pregled ugovora'), findsWidgets);

      // Switch to RU
      await tester.tap(find.text('RU'));
      await tester.pumpAndSettle();
      expect(find.textContaining('уведомление о договоре аренды'), findsWidgets);
      expect(find.textContaining('Сводка договора'), findsWidgets);

      // Switch to SR (Ћир)
      await tester.tap(find.text('SR (Ћир)'));
      await tester.pumpAndSettle();
      expect(find.textContaining('обавештење о уговору о закупу'), findsWidgets);
      expect(find.textContaining('Преглед уговора'), findsWidgets);
    });

    test('Agency managed property vs Independent landlord property logic', () {
      final agencyProperty = Property(
        id: 'prop-1',
        name: 'Acente Dairesi',
        address: 'Bebek Mah. Cevdetpaşa Cad.',
        agencyId: 'agency-uuid-123',
        defaultMonthlyRent: 20000,
      );

      final independentProperty = Property(
        id: 'prop-2',
        name: 'Bireysel Ev Sahibi Dairesi',
        address: 'Göztepe Mah.',
        agencyId: null,
        defaultMonthlyRent: 15000,
      );

      final agencyContract = Contract(
        id: 'c-1',
        propertyId: agencyProperty.id,
        landlordId: 'landlord-uuid',
        agencyId: 'agency-uuid-123',
        inviteeEmail: 'kiraci1@test.com',
        monthlyRent: 20000,
        token: 'token-agency',
      );

      final independentContract = Contract(
        id: 'c-2',
        propertyId: independentProperty.id,
        landlordId: 'landlord-uuid',
        agencyId: null,
        inviteeEmail: 'kiraci2@test.com',
        monthlyRent: 15000,
        token: 'token-independent',
      );

      final isAgencyManaged1 = (agencyProperty.agencyId != null && agencyProperty.agencyId!.isNotEmpty) ||
          (agencyContract.agencyId != null && agencyContract.agencyId!.isNotEmpty);

      final isAgencyManaged2 = (independentProperty.agencyId != null && independentProperty.agencyId!.isNotEmpty) ||
          (independentContract.agencyId != null && independentContract.agencyId!.isNotEmpty);

      expect(isAgencyManaged1, isTrue, reason: 'Properties with agencyId should be detected as agency-managed');
      expect(isAgencyManaged2, isFalse, reason: 'Properties without agencyId should be detected as independent landlord');
    });
  });
}
