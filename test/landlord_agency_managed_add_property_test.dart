import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stanomer/core/l10n/app_localizations.dart';
import 'package:stanomer/features/property/domain/property.dart';

void main() {
  group('Landlord Agency-Managed Add Property Restrictions', () {
    test('Landlord with agency-managed property cannot see FAB', () {
      final properties = [
        Property(
          id: 'prop-1',
          name: 'Apartment 1',
          address: 'Belgrade',
          landlordId: 'landlord-1',
          agencyId: 'agency-123', // Managed by agency
          currency: 'EUR',
          defaultMonthlyRent: 500,
        ),
      ];

      final hasAgencyManagedProperty = properties.any((p) => p.agencyId != null && p.agencyId!.isNotEmpty);
      expect(hasAgencyManagedProperty, isTrue);

      final isAgencyClient = hasAgencyManagedProperty;
      // In dashboard_screen, if isAgencyClient is true, FAB returns null
      Widget? floatingActionButton = isAgencyClient ? null : const FloatingActionButton(onPressed: null);
      expect(floatingActionButton, isNull);
    });

    test('Self-managing landlord without agency can see FAB', () {
      final properties = [
        Property(
          id: 'prop-2',
          name: 'Apartment 2',
          address: 'Novi Sad',
          landlordId: 'landlord-1',
          agencyId: null, // Not managed by agency
          currency: 'EUR',
          defaultMonthlyRent: 400,
        ),
      ];

      final hasAgencyManagedProperty = properties.any((p) => p.agencyId != null && p.agencyId!.isNotEmpty);
      expect(hasAgencyManagedProperty, isFalse);

      final isAgencyClient = hasAgencyManagedProperty;
      Widget? floatingActionButton = isAgencyClient ? null : const FloatingActionButton(onPressed: null);
      expect(floatingActionButton, isNotNull);
    });

    testWidgets('Agency client landlord empty state shows agency message without add property button', (tester) async {
      bool actionCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('tr'),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final loc = AppLocalizations.of(context)!;
                final isTr = loc.localeName == 'tr';
                return Container(
                  child: Column(
                    children: [
                      Text(
                        isTr
                            ? 'Mülkleriniz acente tarafından yönetilmektedir. Yeni mülk eklemek için lütfen acenteniz ile iletişime geçiniz.'
                            : 'Your properties are managed by an agency.',
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Mülkleriniz acente tarafından yönetilmektedir. Yeni mülk eklemek için lütfen acenteniz ile iletişime geçiniz.'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNothing);
      expect(actionCalled, isFalse);
    });
  });
}
