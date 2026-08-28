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
import 'package:stanomer/features/property/domain/activity_log.dart';
import 'package:stanomer/core/providers/agency_branding_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class _FakeAgencyBrandingNotifier extends StateNotifier<AgencyBrandingState> implements AgencyBrandingNotifier {
  _FakeAgencyBrandingNotifier() : super(const AgencyBrandingState());

  @override
  void clear() {}

  @override
  Future<void> updateBrandingForSession({
    required String role,
    required List<Property> properties,
    int selectedIndex = 0,
    String? contractAgencyId,
  }) async {}

  @override
  Future<void> loadFromProperty(Property? property) async {}
}

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

    final mockActivities = <ActivityLog>[
      ActivityLog(
        id: 'act-1',
        propertyId: mockProperty.id,
        userId: 'landlord-1',
        type: 'payment_created',
        metadata: {'title': 'Kira', 'amount': 800},
        createdAt: DateTime(2026, 1, 15),
      ),
    ];

    testWidgets('renders Ultra-Compact Header, Financials body, and Overview & Activity Pills', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => null),
            userRoleProvider.overrideWith((ref) => 'tenant'),
            agencyColorSchemeProvider.overrideWith((ref) => const AgencyColorScheme.agencyScheme()),
            agencyBrandingProvider.overrideWith((ref) => _FakeAgencyBrandingNotifier()),
            propertiesStreamProvider.overrideWith((ref) => Stream.value([mockProperty])),
            propertyProvider(mockProperty.id).overrideWith((ref) => Stream.value(mockProperty)),
            activeContractProvider(mockProperty.id).overrideWith((ref) => Stream.value(null)),
            propertyContractsProvider(mockProperty.id).overrideWith((ref) => Stream.value(<Contract>[])),
            activityLogsProvider(mockProperty.id).overrideWith((ref) => Stream.value(mockActivities)),
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

      // Check Overview (Info) and Activity (History) Action buttons are present in header
      expect(find.byIcon(LucideIcons.info), findsOneWidget);
      expect(find.byIcon(LucideIcons.history), findsOneWidget);
    });

    testWidgets('tapping overview pill opens Overview Modal Sheet with contract info on mobile', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => null),
            userRoleProvider.overrideWith((ref) => 'tenant'),
            agencyColorSchemeProvider.overrideWith((ref) => const AgencyColorScheme.agencyScheme()),
            agencyBrandingProvider.overrideWith((ref) => _FakeAgencyBrandingNotifier()),
            propertiesStreamProvider.overrideWith((ref) => Stream.value([mockProperty])),
            propertyProvider(mockProperty.id).overrideWith((ref) => Stream.value(mockProperty)),
            activeContractProvider(mockProperty.id).overrideWith((ref) => Stream.value(null)),
            propertyContractsProvider(mockProperty.id).overrideWith((ref) => Stream.value(<Contract>[])),
            activityLogsProvider(mockProperty.id).overrideWith((ref) => Stream.value(mockActivities)),
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

      // Tap on Overview Action Icon Button
      await tester.tap(find.byIcon(LucideIcons.info));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Check modal bottom sheet opened
      expect(find.text('Luxury Residence 10A'), findsWidgets);
    });

    testWidgets('tapping activity pill opens Overview & Activity Modal Sheet with Activity tab active', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => null),
            userRoleProvider.overrideWith((ref) => 'tenant'),
            agencyColorSchemeProvider.overrideWith((ref) => const AgencyColorScheme.agencyScheme()),
            agencyBrandingProvider.overrideWith((ref) => _FakeAgencyBrandingNotifier()),
            propertiesStreamProvider.overrideWith((ref) => Stream.value([mockProperty])),
            propertyProvider(mockProperty.id).overrideWith((ref) => Stream.value(mockProperty)),
            activeContractProvider(mockProperty.id).overrideWith((ref) => Stream.value(null)),
            propertyContractsProvider(mockProperty.id).overrideWith((ref) => Stream.value(<Contract>[])),
            activityLogsProvider(mockProperty.id).overrideWith((ref) => Stream.value(mockActivities)),
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

      // Tap on Activity Action Icon Button
      await tester.tap(find.byIcon(LucideIcons.history));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 500));

      // Check activity log description is visible inside sheet
      expect(find.text('Sistem borç kaydını otomatik oluşturdu'), findsOneWidget);
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
            agencyBrandingProvider.overrideWith((ref) => _FakeAgencyBrandingNotifier()),
            propertiesStreamProvider.overrideWith((ref) => Stream.value([mockProperty])),
            propertyProvider(mockProperty.id).overrideWith((ref) => Stream.value(mockProperty)),
            activeContractProvider(mockProperty.id).overrideWith((ref) => Stream.value(null)),
            propertyContractsProvider(mockProperty.id).overrideWith((ref) => Stream.value(<Contract>[])),
            activityLogsProvider(mockProperty.id).overrideWith((ref) => Stream.value(mockActivities)),
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

      // Both financials on left and overview/activity panel on right are displayed simultaneously on wide screen
      expect(find.text('Luxury Residence 10A'), findsWidgets);
      expect(find.text('Genel Bakış'), findsWidgets);
      expect(find.text('Aktivite'), findsWidgets);
    });
  });
}
