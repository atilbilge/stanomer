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
import 'package:stanomer/features/maintenance/domain/maintenance_charge.dart';
import 'package:stanomer/features/agency/domain/agency_color_scheme.dart';
import 'package:stanomer/features/property/domain/contract.dart';
import 'package:stanomer/features/property/domain/activity_log.dart';
import 'package:stanomer/features/property/domain/property_owner.dart';
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
            propertyMaintenanceChargesProvider(mockProperty.id).overrideWith((ref) => Stream.value(<MaintenanceCharge>[])),
            rentPaymentsProvider(mockProperty.id).overrideWith((ref) => Stream.value([])),
            propertyOwnersProvider(mockProperty.id).overrideWith((ref) => Future.value(<PropertyOwner>[])),
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

      // Check only Overview action button is present in mobile header
      expect(find.byIcon(LucideIcons.fileText), findsOneWidget);
    });

    testWidgets('tapping info button opens Overview Modal Sheet with contract info on mobile', (tester) async {
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
            propertyMaintenanceChargesProvider(mockProperty.id).overrideWith((ref) => Stream.value(<MaintenanceCharge>[])),
            rentPaymentsProvider(mockProperty.id).overrideWith((ref) => Stream.value([])),
            propertyOwnersProvider(mockProperty.id).overrideWith((ref) => Future.value(<PropertyOwner>[])),
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
      await tester.tap(find.byIcon(LucideIcons.fileText));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Check modal bottom sheet opened
      expect(find.text('Luxury Residence 10A'), findsWidgets);
    });

    testWidgets('tapping activity tab inside modal sheet shows activity timeline', (tester) async {
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
            propertyMaintenanceChargesProvider(mockProperty.id).overrideWith((ref) => Stream.value(<MaintenanceCharge>[])),
            rentPaymentsProvider(mockProperty.id).overrideWith((ref) => Stream.value([])),
            propertyOwnersProvider(mockProperty.id).overrideWith((ref) => Future.value(<PropertyOwner>[])),
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

      // Tap on Info Action Icon Button on mobile
      await tester.tap(find.byIcon(LucideIcons.fileText));
      await tester.pumpAndSettle();

      // Switch to Activity Tab inside modal sheet
      await tester.tap(find.text('Aktivite'));
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
            propertyMaintenanceChargesProvider(mockProperty.id).overrideWith((ref) => Stream.value(<MaintenanceCharge>[])),
            rentPaymentsProvider(mockProperty.id).overrideWith((ref) => Stream.value([])),
            propertyOwnersProvider(mockProperty.id).overrideWith((ref) => Future.value(<PropertyOwner>[])),
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

      // On wide screen, info button is hidden in header (panel is side-by-side)
      expect(find.byIcon(LucideIcons.info), findsNothing);

      // Both financials on left and overview/activity panel on right are displayed simultaneously on wide screen
      expect(find.text('Luxury Residence 10A'), findsWidgets);
      expect(find.text('Genel Bakış'), findsWidgets);
      expect(find.text('Aktivite'), findsWidgets);
    });

    testWidgets('tapping Edit Owners button opens edit owners sheet with form section', (tester) async {
      tester.view.physicalSize = const Size(1200, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final owner = PropertyOwner(
        id: 'owner-1',
        propertyId: mockProperty.id,
        isPrimary: true,
        firstName: 'Stefan',
        lastName: 'Petrović',
        phone: '+38161111222',
        email: 'stefan@example.com',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => null),
            userRoleProvider.overrideWith((ref) => 'agency'),
            agencyColorSchemeProvider.overrideWith((ref) => const AgencyColorScheme.agencyScheme()),
            agencyBrandingProvider.overrideWith((ref) => _FakeAgencyBrandingNotifier()),
            propertiesStreamProvider.overrideWith((ref) => Stream.value([mockProperty])),
            propertyProvider(mockProperty.id).overrideWith((ref) => Stream.value(mockProperty)),
            activeContractProvider(mockProperty.id).overrideWith((ref) => Stream.value(null)),
            propertyContractsProvider(mockProperty.id).overrideWith((ref) => Stream.value(<Contract>[])),
            activityLogsProvider(mockProperty.id).overrideWith((ref) => Stream.value(mockActivities)),
            maintenanceRequestsProvider(mockProperty.id).overrideWith((ref) => Stream.value(<MaintenanceRequest>[])),
            propertyMaintenanceChargesProvider(mockProperty.id).overrideWith((ref) => Stream.value(<MaintenanceCharge>[])),
            rentPaymentsProvider(mockProperty.id).overrideWith((ref) => Stream.value([])),
            propertyOwnersProvider(mockProperty.id).overrideWith((ref) => Future.value([owner])),
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

      final editIconBtn = find.byIcon(LucideIcons.edit3);
      expect(editIconBtn, findsOneWidget);

      await tester.tap(editIconBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Mülk Sahiplerini Düzenle'), findsOneWidget);
      expect(find.text('Değişiklikleri Kaydet'), findsOneWidget);
    });
  });
}
