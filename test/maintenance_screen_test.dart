import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stanomer/core/l10n/app_localizations.dart';
import 'package:stanomer/core/providers/agency_branding_provider.dart';
import 'package:stanomer/features/agency/domain/agency_color_scheme.dart';
import 'package:stanomer/features/agency/presentation/agency_dashboard_screen.dart';
import 'package:stanomer/features/maintenance/presentation/maintenance_screen.dart';
import 'package:stanomer/features/maintenance/domain/maintenance_request.dart';
import 'package:stanomer/features/maintenance/data/maintenance_repository.dart';
import 'package:stanomer/features/property/domain/property.dart';
import 'package:stanomer/features/property/data/property_repository.dart';
import 'package:stanomer/features/auth/data/auth_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;

void main() {
  group('MaintenanceScreen Tests', () {
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

    final mockRequests = [
      MaintenanceRequest(
        id: 'req-1',
        propertyId: 'prop-123',
        reporterId: 'tenant-1',
        title: 'Mutfak Musluğu Sızdırıyor',
        category: MaintenanceCategory.plumbing,
        description: 'Lavabonun altından su damlatıyor.',
        status: MaintenanceStatus.open,
        priority: MaintenancePriority.urgent,
        costAmount: 45.0,
        currency: 'EUR',
        paidBy: 'tenant',
        paymentStatus: 'pending_payment',
        createdAt: DateTime(2026, 8, 20),
      ),
      MaintenanceRequest(
        id: 'req-2',
        propertyId: 'prop-123',
        reporterId: 'tenant-1',
        title: 'Klima Bakımı',
        category: MaintenanceCategory.heating,
        description: 'Yıllık filtre temizliği yapıldı.',
        status: MaintenanceStatus.resolved,
        priority: MaintenancePriority.normal,
        costAmount: 30.0,
        currency: 'EUR',
        paidBy: 'landlord',
        paymentStatus: 'paid',
        createdAt: DateTime(2026, 8, 10),
      ),
    ];

    testWidgets('renders Hero Header, Stat Deck, Search and Request Cards', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            propertyAgencyColorSchemeProvider(mockProperty).overrideWithValue(
              const AgencyColorScheme.defaultScheme(),
            ),
            agencyPropertiesProvider.overrideWith(
              (ref) => Stream.value([mockProperty]),
            ),
            maintenanceRequestsProvider(mockProperty.id).overrideWith(
              (ref) => Stream.value(mockRequests),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('tr'),
            home: MaintenanceScreen(property: mockProperty),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check Property Title in Header
      expect(find.text('Central Apartment 4B'), findsWidgets);

      // Check Maintenance Requests are rendered
      expect(find.text('Mutfak Musluğu Sızdırıyor'), findsOneWidget);
      expect(find.text('Klima Bakımı'), findsOneWidget);

      // Check Urgent Badge
      expect(find.text('ACIL'), findsOneWidget);
    });

    testWidgets('shows empty state with CTA for tenant when no requests exist', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const tenantUser = User(
        id: 'tenant-1',
        appMetadata: {},
        userMetadata: {'role': 'tenant'},
        aud: 'authenticated',
        createdAt: '2026-01-01',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            propertyAgencyColorSchemeProvider(mockProperty).overrideWithValue(
              const AgencyColorScheme.defaultScheme(),
            ),
            agencyPropertiesProvider.overrideWith(
              (ref) => Stream.value([mockProperty]),
            ),
            currentUserProvider.overrideWith((ref) => tenantUser),
            profileProvider('tenant-1').overrideWith((ref) => Stream.value({'role': 'tenant'})),
            maintenanceRequestsProvider(mockProperty.id).overrideWith(
              (ref) => Stream.value([]),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('tr'),
            home: MaintenanceScreen(property: mockProperty),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check No Issues message
      expect(find.text('Kayıtlı sorun yok'), findsOneWidget);
      expect(find.text('Sorun Bildir'), findsWidgets);
    });

    testWidgets('agency user sees floating action button and empty state message', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const agencyUser = User(
        id: 'agency-1',
        appMetadata: {},
        userMetadata: {'role': 'agency'},
        aud: 'authenticated',
        createdAt: '2026-01-01',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            propertyAgencyColorSchemeProvider(mockProperty).overrideWithValue(
              const AgencyColorScheme.defaultScheme(),
            ),
            agencyPropertiesProvider.overrideWith(
              (ref) => Stream.value([mockProperty]),
            ),
            currentUserProvider.overrideWith((ref) => agencyUser),
            profileProvider('agency-1').overrideWith((ref) => Stream.value({'role': 'agency'})),
            maintenanceRequestsProvider(mockProperty.id).overrideWith(
              (ref) => Stream.value([]),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('tr'),
            home: MaintenanceScreen(property: mockProperty),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check No Issues message is visible
      expect(find.text('Kayıtlı sorun yok'), findsOneWidget);
      // Floating action button with Sorun Bildir / Report issue is visible
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });
}

