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
import 'package:stanomer/features/property/presentation/widgets/agency_contact_autocomplete.dart';

import 'package:stanomer/features/property/domain/property_owner.dart';
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

  group('AgencyContactAutocomplete Widget Tests', () {
    final testContacts = [
      const AgencyContact(
        name: 'Ahmet Yılmaz',
        email: 'ahmet@example.com',
        phone: '+905321112233',
        role: AgencyContactRole.landlord,
        propertySummary: '2 Mülk Sahibi',
      ),
      const AgencyContact(
        name: 'Marko Petrović',
        email: 'marko@example.com',
        phone: '+381601112233',
        idNumber: '123456789',
        role: AgencyContactRole.tenant,
        propertySummary: 'Daire 4 Kiracısı',
      ),
    ];

    testWidgets('Renders search field and options with badges', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      AgencyContact? selected;

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
              body: AgencyContactAutocomplete(
                onContactSelected: (c) => selected = c,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Kayıtlı Kişilerden Hızlı Doldur'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      // Tap on search field to trigger suggestions
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      // Suggestions should appear
      expect(find.text('Ahmet Yılmaz'), findsOneWidget);
      expect(find.text('Marko Petrović'), findsOneWidget);
      expect(find.text('Ev Sahibi'), findsOneWidget);
      expect(find.text('Kiracı'), findsOneWidget);

      // Select Marko (Tenant)
      await tester.tap(find.text('Marko Petrović'));
      await tester.pumpAndSettle();

      expect(selected, isNotNull);
      expect(selected!.name, 'Marko Petrović');
      expect(selected!.isTenant, isTrue);

      // Tenant notification card should appear
      expect(find.textContaining('kiracı olarak kayıtlıdır'), findsOneWidget);
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

      List<PropertyOwner> updatedOwners = [];

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
                  onOwnersChanged: (owners) => updatedOwners = owners,
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

      // Tap and type 'stefan'
      await tester.tap(emailFinder);
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

    testWidgets('Agency sees Quick Fill and selecting contact populates fields', (tester) async {
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
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('tr'),
            home: AddPropertyScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Autocomplete quick fill should be visible for agency
      expect(find.text('Kayıtlı Kişilerden Hızlı Doldur'), findsOneWidget);

      // Tap search box
      final searchInput = find.widgetWithText(TextField, 'Ev sahibi veya kiracı ara (İsim, e-posta, tel)...');
      expect(searchInput, findsOneWidget);
      await tester.tap(searchInput);
      await tester.pumpAndSettle();

      // Suggestions show Elena and Marko
      expect(find.text('Elena Ivanova'), findsOneWidget);
      expect(find.text('Marko Petrović'), findsOneWidget);

      // Select Elena (Landlord)
      await tester.tap(find.text('Elena Ivanova'));
      await tester.pumpAndSettle();

      // Check that landlord input fields are populated
      expect(find.widgetWithText(TextFormField, 'Elena Ivanova'), findsWidgets);
      expect(find.widgetWithText(TextFormField, 'elena@example.com'), findsWidgets);
      expect(find.widgetWithText(TextFormField, '+381659998877'), findsWidgets);
    });
  });
}
