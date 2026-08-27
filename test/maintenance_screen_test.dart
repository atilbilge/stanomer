import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stanomer/core/l10n/app_localizations.dart';
import 'package:stanomer/features/maintenance/presentation/maintenance_screen.dart';
import 'package:stanomer/features/maintenance/domain/maintenance_request.dart';
import 'package:stanomer/features/maintenance/data/maintenance_repository.dart';
import 'package:stanomer/features/property/domain/property.dart';

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

    testWidgets('shows empty state when no requests exist', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
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
  });
}
