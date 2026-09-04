import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stanomer/core/l10n/app_localizations.dart';
import 'package:stanomer/features/maintenance/presentation/widgets/agency_property_picker_sheet.dart';
import 'package:stanomer/features/property/domain/property.dart';

void main() {
  group('AgencyPropertyPickerSheet Tests', () {
    final mockProperties = [
      Property(
        id: 'prop-1',
        name: 'Vila Zvezdara',
        address: 'Bulevar Kralja Aleksandra 120',
        city: 'Belgrade',
        unitNumber: '12',
        landlordId: 'landlord-1',
        agencyId: 'agency-1',
        currency: 'EUR',
        defaultMonthlyRent: 800,
      ),
      Property(
        id: 'prop-2',
        name: 'Dorcol Penthouse',
        address: 'Cara Dusana 45',
        city: 'Belgrade',
        unitNumber: '5B',
        landlordId: 'landlord-2',
        agencyId: 'agency-1',
        currency: 'EUR',
        defaultMonthlyRent: 1200,
      ),
      Property(
        id: 'prop-3',
        name: 'Novi Sad Modern Studio',
        address: 'Zmaj Jovina 10',
        city: 'Novi Sad',
        unitNumber: '3',
        landlordId: 'landlord-3',
        agencyId: 'agency-1',
        currency: 'EUR',
        defaultMonthlyRent: 450,
      ),
    ];

    testWidgets('renders properties list with titles, addresses, and header', (tester) async {
      Property? selected;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('tr'),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  selected = await showAgencyPropertyPickerSheet(
                    context: context,
                    properties: mockProperties,
                    primaryColor: const Color(0xFF0284C7),
                  );
                },
                child: const Text('Open Picker'),
              ),
            ),
          ),
        ),
      );

      // Open the sheet
      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      // Check header and localized strings
      expect(find.text('Mülk Seçin'), findsOneWidget);
      expect(find.text('Bakım talebi oluşturulacak mülkü seçiniz'), findsOneWidget);

      // Check all 3 properties are listed
      expect(find.text('Vila Zvezdara'), findsOneWidget);
      expect(find.text('Dorcol Penthouse'), findsOneWidget);
      expect(find.text('Novi Sad Modern Studio'), findsOneWidget);

      // Tap on the second property
      await tester.tap(find.text('Dorcol Penthouse'));
      await tester.pumpAndSettle();

      // Ensure picker dismissed and returned the chosen property
      expect(selected, isNotNull);
      expect(selected!.id, 'prop-2');
      expect(selected!.name, 'Dorcol Penthouse');
    });

    testWidgets('filters properties accurately when typing in search field', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('tr'),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showAgencyPropertyPickerSheet(
                  context: context,
                  properties: mockProperties,
                ),
                child: const Text('Open Picker'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      // Search for "Novi Sad"
      final searchFinder = find.byType(TextField);
      expect(searchFinder, findsOneWidget);
      await tester.enterText(searchFinder, 'Novi Sad');
      await tester.pumpAndSettle();

      // Only Novi Sad should remain visible
      expect(find.text('Novi Sad Modern Studio'), findsOneWidget);
      expect(find.text('Vila Zvezdara'), findsNothing);
      expect(find.text('Dorcol Penthouse'), findsNothing);

      // Search for non-existing query
      await tester.enterText(searchFinder, 'XYZ999');
      await tester.pumpAndSettle();

      expect(find.text('Aramanıza uygun mülk bulunamadı'), findsOneWidget);
    });

    testWidgets('marks initial selected property with badge', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('tr'),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showAgencyPropertyPickerSheet(
                  context: context,
                  properties: mockProperties,
                  initialSelectedProperty: mockProperties[0],
                ),
                child: const Text('Open Picker'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      // Check current badge
      expect(find.text('Mevcut'), findsOneWidget);
    });

    testWidgets('renders in Serbian (sr) with correct localized texts', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('sr'),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showAgencyPropertyPickerSheet(
                  context: context,
                  properties: mockProperties,
                  initialSelectedProperty: mockProperties[0],
                ),
                child: const Text('Open Picker'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      expect(find.text('Izaberite nekretninu'), findsOneWidget);
      expect(find.text('Izaberite nekretninu za prijavu kvara / održavanja'), findsOneWidget);
      expect(find.text('Trenutna'), findsOneWidget);
    });

    testWidgets('renders empty properties state when list is empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('tr'),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showAgencyPropertyPickerSheet(
                  context: context,
                  properties: const [],
                ),
                child: const Text('Open Picker'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      expect(find.text('Yönetilen mülk bulunamadı'), findsOneWidget);
    });
  });
}

