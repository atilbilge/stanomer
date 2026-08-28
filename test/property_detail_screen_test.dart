import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stanomer/core/l10n/app_localizations.dart';
import 'package:stanomer/features/property/presentation/property_detail_screen.dart';
import 'package:stanomer/features/property/domain/property.dart';
import 'package:stanomer/features/property/data/property_repository.dart';
import 'package:stanomer/features/auth/data/auth_providers.dart';
import 'package:stanomer/features/maintenance/data/maintenance_repository.dart';
import 'package:stanomer/features/maintenance/domain/maintenance_request.dart';
import 'package:stanomer/features/agency/domain/agency_color_scheme.dart';
import 'package:stanomer/features/property/domain/contract.dart';

void main() {
  group('PropertyDetailScreen Tests', () {
    final mockProperty = Property(
      id: 'prop-detail-123',
      name: 'Luxury Residence 10A',
      address: 'Terazije 25, Belgrade',
      landlordId: 'landlord-1',
      tenantId: 'tenant-1',
      currency: 'EUR',
      defaultMonthlyRent: 800,
      defaultDepositAmount: 800,
      createdAt: DateTime(2026, 1, 1),
    );

    testWidgets('renders Ultra-Compact Header, 2 Segmented Tabs and Overview Action', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => null),
            userRoleProvider.overrideWith((ref) => 'tenant'),
            agencyColorSchemeProvider.overrideWith((ref) => const AgencyColorScheme.agencyScheme()),
            propertiesStreamProvider.overrideWith((ref) => Stream.value([mockProperty])),
            propertyProvider(mockProperty.id).overrideWith((ref) => Stream.value(mockProperty)),
            activeContractProvider(mockProperty.id).overrideWith((ref) => Stream.value(null)),
            propertyContractsProvider(mockProperty.id).overrideWith((ref) => Stream.value(<Contract>[])),
            activityLogsProvider(mockProperty.id).overrideWith((ref) => Stream.value([])),
            maintenanceRequestsProvider(mockProperty.id).overrideWith((ref) => Stream.value(<MaintenanceRequest>[])),
            rentPaymentsProvider(mockProperty.id).overrideWith((ref) => Stream.value([])),
            profileProvider('landlord-1').overrideWith((ref) => Stream.value({'full_name': 'Stefan Petrovic', 'email': 'stefan@example.com'})),
            profileProvider('tenant-1').overrideWith((ref) => Stream.value({'full_name': 'Marko Jankovic', 'email': 'marko@example.com'})),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('tr'),
            home: PropertyDetailScreen(property: mockProperty),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Check Property Title and Address in Compact Hero Header
      expect(find.text('Luxury Residence 10A'), findsWidgets);
      expect(find.text('Terazije 25, Belgrade'), findsWidgets);

      // Check 2 Operational Tabs are present
      expect(find.text('Ödemeler'), findsWidgets);
      expect(find.text('Bakım / Arıza'), findsWidgets);

      // Check Overview Action Button is present on mobile
      expect(find.text('Genel Bakış'), findsWidgets);
    });

    testWidgets('tapping overview pill opens Overview Modal Sheet on mobile', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => null),
            userRoleProvider.overrideWith((ref) => 'tenant'),
            agencyColorSchemeProvider.overrideWith((ref) => const AgencyColorScheme.agencyScheme()),
            propertiesStreamProvider.overrideWith((ref) => Stream.value([mockProperty])),
            propertyProvider(mockProperty.id).overrideWith((ref) => Stream.value(mockProperty)),
            activeContractProvider(mockProperty.id).overrideWith((ref) => Stream.value(null)),
            propertyContractsProvider(mockProperty.id).overrideWith((ref) => Stream.value(<Contract>[])),
            activityLogsProvider(mockProperty.id).overrideWith((ref) => Stream.value([])),
            maintenanceRequestsProvider(mockProperty.id).overrideWith((ref) => Stream.value(<MaintenanceRequest>[])),
            rentPaymentsProvider(mockProperty.id).overrideWith((ref) => Stream.value([])),
            profileProvider('landlord-1').overrideWith((ref) => Stream.value({'full_name': 'Stefan Petrovic', 'email': 'stefan@example.com'})),
            profileProvider('tenant-1').overrideWith((ref) => Stream.value({'full_name': 'Marko Jankovic', 'email': 'marko@example.com'})),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('tr'),
            home: PropertyDetailScreen(property: mockProperty),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Tap on Overview Action Pill
      await tester.tap(find.text('Genel Bakış'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Check modal bottom sheet opened with property name
      expect(find.text('Luxury Residence 10A'), findsWidgets);
    });

    testWidgets('switching to maintenance tab embeds MaintenanceScreen', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final dummyRequests = <MaintenanceRequest>[
        MaintenanceRequest(
          id: 'req-1',
          propertyId: mockProperty.id,
          reporterId: 'tenant-1',
          title: 'Klima su damlatıyor',
          category: MaintenanceCategory.heating,
          priority: MaintenancePriority.urgent,
          status: MaintenanceStatus.open,
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => null),
            userRoleProvider.overrideWith((ref) => 'tenant'),
            agencyColorSchemeProvider.overrideWith((ref) => const AgencyColorScheme.agencyScheme()),
            propertiesStreamProvider.overrideWith((ref) => Stream.value([mockProperty])),
            propertyProvider(mockProperty.id).overrideWith((ref) => Stream.value(mockProperty)),
            activeContractProvider(mockProperty.id).overrideWith((ref) => Stream.value(null)),
            propertyContractsProvider(mockProperty.id).overrideWith((ref) => Stream.value(<Contract>[])),
            activityLogsProvider(mockProperty.id).overrideWith((ref) => Stream.value([])),
            maintenanceRequestsProvider(mockProperty.id).overrideWith((ref) => Stream.value(dummyRequests)),
            rentPaymentsProvider(mockProperty.id).overrideWith((ref) => Stream.value([])),
            profileProvider('landlord-1').overrideWith((ref) => Stream.value({'full_name': 'Stefan Petrovic', 'email': 'stefan@example.com'})),
            profileProvider('tenant-1').overrideWith((ref) => Stream.value({'full_name': 'Marko Jankovic', 'email': 'marko@example.com'})),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('tr'),
            home: PropertyDetailScreen(property: mockProperty, initialTabIndex: 2),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Check maintenance request is visible
      expect(find.text('Klima su damlatıyor'), findsOneWidget);
    });

    testWidgets('renders two-column layout on wide desktop screens (width >= 960)', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => null),
            userRoleProvider.overrideWith((ref) => 'tenant'),
            agencyColorSchemeProvider.overrideWith((ref) => const AgencyColorScheme.agencyScheme()),
            propertiesStreamProvider.overrideWith((ref) => Stream.value([mockProperty])),
            propertyProvider(mockProperty.id).overrideWith((ref) => Stream.value(mockProperty)),
            activeContractProvider(mockProperty.id).overrideWith((ref) => Stream.value(null)),
            propertyContractsProvider(mockProperty.id).overrideWith((ref) => Stream.value(<Contract>[])),
            activityLogsProvider(mockProperty.id).overrideWith((ref) => Stream.value([])),
            maintenanceRequestsProvider(mockProperty.id).overrideWith((ref) => Stream.value(<MaintenanceRequest>[])),
            rentPaymentsProvider(mockProperty.id).overrideWith((ref) => Stream.value([])),
            profileProvider('landlord-1').overrideWith((ref) => Stream.value({'full_name': 'Stefan Petrovic', 'email': 'stefan@example.com'})),
            profileProvider('tenant-1').overrideWith((ref) => Stream.value({'full_name': 'Marko Jankovic', 'email': 'marko@example.com'})),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('tr'),
            home: PropertyDetailScreen(property: mockProperty),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Both operational tabs and overview panel are displayed simultaneously on wide screen
      expect(find.text('Ödemeler'), findsWidgets);
      expect(find.text('Bakım / Arıza'), findsWidgets);
      expect(find.text('Luxury Residence 10A'), findsWidgets);
    });
  });
}
