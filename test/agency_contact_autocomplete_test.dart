import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stanomer/core/l10n/app_localizations.dart';
import 'package:stanomer/features/auth/data/auth_providers.dart';
import 'package:stanomer/features/agency/domain/agency_contact.dart';
import 'package:stanomer/features/agency/domain/agency_color_scheme.dart';
import 'package:stanomer/core/providers/agency_branding_provider.dart';
import 'package:stanomer/features/property/data/property_repository.dart';
import 'package:stanomer/features/property/presentation/add_property_screen.dart';
import 'package:stanomer/features/property/presentation/widgets/property_owners_form_section.dart';

void main() {
  group('AgencyContact Domain Model Tests', () {
    test('Landlord contact properties and roles', () {
      const contact = AgencyContact(
        name: 'Ahmet Yılmaz',
        email: 'ahmet@example.com',
        phone: '+905321112233',
        role: AgencyContactRole.landlord,
        propertySummary: '2 Mülk Sahibi',
      );

      expect(contact.isLandlord, isTrue);
      expect(contact.isTenant, isFalse);
      expect(contact.name, 'Ahmet Yılmaz');
      expect(contact.propertySummary, '2 Mülk Sahibi');
    });

    test('Tenant contact properties and roles', () {
      const contact = AgencyContact(
        name: 'Marko Petrović',
        email: 'marko@example.com',
        phone: '+381601112233',
        idNumber: 'JMBG1234567890123',
        role: AgencyContactRole.tenant,
        propertySummary: 'Daire 4 Kiracısı',
      );

      expect(contact.isTenant, isTrue);
      expect(contact.isLandlord, isFalse);
      expect(contact.idNumber, 'JMBG1234567890123');
      expect(contact.propertySummary, 'Daire 4 Kiracısı');
    });
  });

  group('PropertyOwnersFormSection Inline Autocomplete Tests', () {
    final testContacts = [
      const AgencyContact(
        name: 'Stefan Nemanja',
        email: 'stefan@example.com',
        phone: '+38163123456',
        idNumber: 'ID998877',
        role: AgencyContactRole.landlord,
        propertySummary: 'Novi Beograd 12',
      ),
      const AgencyContact(
        name: 'Jelena Karleusa',
        email: 'jelena@tenant.com',
        phone: '+381647778899',
        idNumber: 'PASSPORT4455',
        role: AgencyContactRole.tenant,
        propertySummary: 'Dorćol Apt 5',
      ),
    ];

    testWidgets('Typing in email field opens autocomplete and populates card', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            agencyContactsProvider.overrideWith((ref) => Future.value(testContacts)),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('tr'),
            home: Scaffold(
              body: SingleChildScrollView(
                child: PropertyOwnersFormSection(
                  initialOwners: const [],
                  tempPropertyId: 'test_prop',
                  onOwnersChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Email field inside PropertyOwnersFormSection
      final emailFinder = find.widgetWithText(TextFormField, 'E-posta Adresi (Ana Malik İçin Zorunlu) *');
      expect(emailFinder, findsOneWidget);

      // Tapping on empty email field should NOT show suggestions dropdown
      await tester.tap(emailFinder);
      await tester.pumpAndSettle();
      expect(find.text('Stefan Nemanja'), findsNothing);
      expect(find.text('Ev Sahibi'), findsNothing);

      // Now type 'stefan' -> suggestions dropdown should display Stefan
      await tester.enterText(emailFinder, 'stefan');
      await tester.pumpAndSettle();

      // Suggestions dropdown should display Stefan
      expect(find.text('Stefan Nemanja'), findsOneWidget);
      expect(find.text('Ev Sahibi'), findsOneWidget);

      // Tap Stefan
      await tester.tap(find.text('Stefan Nemanja'));
      await tester.pumpAndSettle();

      // Fields should be populated
      expect(find.widgetWithText(TextFormField, 'Stefan'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Nemanja'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'stefan@example.com'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, '+38163123456'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'ID998877'), findsOneWidget);

      // Confirmation badge shown
      expect(find.text('Kayıtlı ev sahibi bilgileri otomatik dolduruldu.'), findsOneWidget);
    });

    testWidgets('Selecting a tenant in email field populates card and shows tenant warning', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            agencyContactsProvider.overrideWith((ref) => Future.value(testContacts)),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('tr'),
            home: Scaffold(
              body: SingleChildScrollView(
                child: PropertyOwnersFormSection(
                  initialOwners: const [],
                  tempPropertyId: 'test_prop',
                  onOwnersChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final emailFinder = find.widgetWithText(TextFormField, 'E-posta Adresi (Ana Malik İçin Zorunlu) *');
      expect(emailFinder, findsOneWidget);

      // Tap and type 'jelena'
      await tester.tap(emailFinder);
      await tester.enterText(emailFinder, 'jelena');
      await tester.pumpAndSettle();

      expect(find.text('Jelena Karleusa'), findsOneWidget);
      expect(find.text('Kiracı'), findsOneWidget);

      // Tap Jelena
      await tester.tap(find.text('Jelena Karleusa'));
      await tester.pumpAndSettle();

      // Fields should be populated
      expect(find.widgetWithText(TextFormField, 'Jelena'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Karleusa'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'jelena@tenant.com'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, '+381647778899'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'PASSPORT4455'), findsOneWidget);

      // Tenant alert banner shown
      expect(find.textContaining('kiracı olarak kayıtlıdır'), findsOneWidget);
    });
  });

  group('AddPropertyScreen Agency Contact Integration Tests', () {
    const agencyUser = User(
      id: 'agency-user-id',
      appMetadata: {},
      userMetadata: {'role': 'agency'},
      aud: 'authenticated',
      createdAt: '2026-01-01',
    );

    final testContacts = [
      const AgencyContact(
        name: 'Elena Ivanova',
        email: 'elena@example.com',
        phone: '+381659998877',
        role: AgencyContactRole.landlord,
        propertySummary: 'Vračar Apt',
      ),
      const AgencyContact(
        name: 'Marko Petrović',
        email: 'marko@example.com',
        phone: '+381601112233',
        idNumber: 'JMBG9876543210',
        role: AgencyContactRole.tenant,
        propertySummary: 'Dorćol Apt',
      ),
    ];

    testWidgets('Quick Fill is removed and inline email autocomplete works in AddPropertyScreen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => agencyUser),
            userRoleProvider.overrideWithValue('agency'),
            hasAgencyBrandingProvider.overrideWithValue(false),
            propertiesStreamProvider.overrideWith((ref) => Stream.value([])),
            agencyColorSchemeProvider.overrideWithValue(const AgencyColorScheme.agencyScheme()),
            agencyContactsProvider.overrideWith((ref) => Future.value(testContacts)),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('tr'),
            home: const AddPropertyScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Quick Fill card should NO LONGER be present
      expect(find.text('Kayıtlı Kişilerden Hızlı Doldur'), findsNothing);

      // In the Property Owner card, type into the email field
      final emailField = find.widgetWithText(TextFormField, 'E-posta Adresi (Ana Malik İçin Zorunlu) *');
      expect(emailField, findsOneWidget);

      await tester.tap(emailField);
      await tester.enterText(emailField, 'elena');
      await tester.pumpAndSettle();

      // Suggestions show Elena
      expect(find.text('Elena Ivanova'), findsOneWidget);
      expect(find.text('Ev Sahibi'), findsOneWidget);

      // Select Elena (Landlord)
      await tester.tap(find.text('Elena Ivanova'));
      await tester.pumpAndSettle();

      // Check that landlord input fields are populated (exactly one form on screen now!)
      expect(find.widgetWithText(TextFormField, 'Elena'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Ivanova'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'elena@example.com'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, '+381659998877'), findsOneWidget);
    });
  });
}
