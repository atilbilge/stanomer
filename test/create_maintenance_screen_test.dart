import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stanomer/core/l10n/app_localizations.dart';
import 'package:stanomer/features/maintenance/presentation/create_maintenance_screen.dart';
import 'package:stanomer/features/property/domain/property.dart';
import 'package:stanomer/features/auth/data/auth_providers.dart';

import 'package:stanomer/core/providers/agency_branding_provider.dart';
import 'package:stanomer/features/agency/domain/agency_color_scheme.dart';

void main() {
  group('CreateMaintenanceRequestScreen Tests', () {
    final mockProperty = Property(
      id: 'prop-123',
      name: 'Central Apartment 4B',
      address: 'Knez Mihailova 12, Belgrade',
      landlordId: 'landlord-1',
      tenantId: 'tenant-1',
      currency: 'EUR',
      defaultMonthlyRent: 650,
      defaultDepositAmount: 650,
      createdAt: DateTime(2026, 1, 1),
    );

    testWidgets('renders Header, Visual Category Selector, Priority Selector and Submit Button', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            propertyAgencyColorSchemeProvider(mockProperty).overrideWithValue(
              const AgencyColorScheme.defaultScheme(),
            ),
            currentUserProvider.overrideWith((ref) => null),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('tr'),
            home: CreateMaintenanceRequestScreen(property: mockProperty),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check Property Title in Header
      expect(find.text('Central Apartment 4B'), findsWidgets);

      // Check Category Options are present
      expect(find.text('Tesisat'), findsOneWidget);
      expect(find.text('Elektrik'), findsOneWidget);
      expect(find.text('Isınma'), findsOneWidget);

      // Check Priority Options are present
      expect(find.text('Normal'), findsOneWidget);
      expect(find.text('Acil'), findsOneWidget);

      // Check Submit Button
      expect(find.text('Arıza Bildirimini Gönder'), findsOneWidget);
    });

    testWidgets('shows validation error when title is empty and form is submitted', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            propertyAgencyColorSchemeProvider(mockProperty).overrideWithValue(
              const AgencyColorScheme.defaultScheme(),
            ),
            currentUserProvider.overrideWith((ref) => null),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('tr'),
            home: CreateMaintenanceRequestScreen(property: mockProperty),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap submit button without filling title
      final submitButton = find.text('Arıza Bildirimini Gönder');
      expect(submitButton, findsOneWidget);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Expect field required error
      expect(find.text('Bu alan zorunludur'), findsOneWidget);
    });
  });
}
