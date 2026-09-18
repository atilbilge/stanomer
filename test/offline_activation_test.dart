import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stanomer/core/l10n/app_localizations.dart';
import 'package:stanomer/features/agency/domain/agency_color_scheme.dart';
import 'package:stanomer/features/auth/data/auth_providers.dart';
import 'package:stanomer/features/property/presentation/widgets/tenant_invite_share_sheet.dart';
import 'package:stanomer/features/property/presentation/widgets/ownership_share_sheet.dart';
import 'package:stanomer/features/property/domain/property.dart';
import 'package:stanomer/features/property/domain/contract.dart';
import 'package:stanomer/features/agency/presentation/agency_dashboard_screen.dart';

void main() {
  group('Offline Activation ("Davetsiz Hemen Başlat") Tests', () {
    testWidgets('TenantInviteShareSheet shows Davetsiz Hemen Başlat for agency role', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            agencyColorSchemeProvider.overrideWithValue(const AgencyColorScheme.agencyScheme()),
            userRoleProvider.overrideWithValue('agency'),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('tr'),
            home: Scaffold(
              body: TenantInviteShareSheet(
                propertyName: 'Test Dairesi',
                tenantName: 'Can Yılmaz',
                tenantEmail: 'can@example.com',
                token: 'token_123',
                contractId: 'contract_123',
                propertyId: 'prop_123',
                monthlyRent: 30000,
                currency: 'EUR',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check that "Davetsiz Hemen Başlat" button is rendered
      expect(find.text('Davetsiz Hemen Başlat'), findsOneWidget);
    });

    testWidgets('TenantInviteShareSheet does NOT show Davetsiz Hemen Başlat for landlord role', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            agencyColorSchemeProvider.overrideWithValue(const AgencyColorScheme.agencyScheme()),
            userRoleProvider.overrideWithValue('landlord'),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('tr'),
            home: Scaffold(
              body: TenantInviteShareSheet(
                propertyName: 'Test Dairesi',
                tenantName: 'Can Yılmaz',
                tenantEmail: 'can@example.com',
                token: 'token_123',
                contractId: 'contract_123',
                propertyId: 'prop_123',
                monthlyRent: 30000,
                currency: 'EUR',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check that "Davetsiz Hemen Başlat" button is NOT rendered for landlord
      expect(find.text('Davetsiz Hemen Başlat'), findsNothing);
    });

    testWidgets('OwnershipShareSheet shows Davetsiz Hemen Başlat for agency role', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            agencyColorSchemeProvider.overrideWithValue(const AgencyColorScheme.agencyScheme()),
            userRoleProvider.overrideWithValue('agency'),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('tr'),
            home: Scaffold(
              body: OwnershipShareSheet(
                propertyName: 'Test Mülk',
                landlordName: 'Ahmet Bey',
                landlordEmail: 'ahmet@example.com',
                token: 'token_landlord_123',
                propertyId: 'prop_123',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check that "Davetsiz Hemen Başlat" button is rendered for unconfirmed owner
      expect(find.text('Davetsiz Hemen Başlat'), findsOneWidget);
    });

    testWidgets('OwnershipShareSheet does NOT show Davetsiz Hemen Başlat for landlord role', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            agencyColorSchemeProvider.overrideWithValue(const AgencyColorScheme.agencyScheme()),
            userRoleProvider.overrideWithValue('landlord'),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('tr'),
            home: Scaffold(
              body: OwnershipShareSheet(
                propertyName: 'Test Mülk',
                landlordName: 'Ahmet Bey',
                landlordEmail: 'ahmet@example.com',
                token: 'token_landlord_123',
                propertyId: 'prop_123',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check that "Davetsiz Hemen Başlat" button is NOT rendered for landlord
      expect(find.text('Davetsiz Hemen Başlat'), findsNothing);
    });

    testWidgets('PortfolioDirectStatusHelper formats direct landlord and direct tenant properly', (tester) async {
      late AppLocalizations loc;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('tr'),
          home: Builder(
            builder: (context) {
              loc = AppLocalizations.of(context)!;
              return const Placeholder();
            },
          ),
        ),
      );

      // 1. Direct Landlord (accepted invite offline without registered user)
      const directProp = Property(
        id: 'p1',
        name: 'Daire 1',
        address: 'Adres 1',
        defaultMonthlyRent: 500,
        landlordName: 'Mehmet Demir',
      );

      final landlordRes = PortfolioDirectStatusHelper.resolveLandlordDisplay(
        property: directProp,
        landlordInvites: [
          {'target_role': 'landlord', 'status': 'accepted', 'token': 'tok1'}
        ],
        loc: loc,
      );
      expect(landlordRes.isDirect, isTrue);
      expect(landlordRes.name, 'Mehmet Demir (direct)');

      // 2. Claimed Landlord (registered user)
      final claimedProp = directProp.copyWith(landlordId: 'user_landlord_1');
      final claimedRes = PortfolioDirectStatusHelper.resolveLandlordDisplay(
        property: claimedProp,
        landlordInvites: [],
        loc: loc,
      );
      expect(claimedRes.isDirect, isFalse);
      expect(claimedRes.name, 'Mehmet Demir');

      // 3. Direct Tenant (active contract without digital user)
      final tenantRes = PortfolioDirectStatusHelper.resolveTenantDisplay(
        property: directProp.copyWith(tenantName: 'Ayşe Yılmaz', tenantId: null),
        contract: Contract(
          id: 'c1',
          propertyId: 'p1',
          landlordId: 'l1',
          inviteeEmail: 'ayse@example.com',
          token: 'mock-token-1',
          monthlyRent: 500,
          currency: 'EUR',
          startDate: DateTime(2026, 1, 1),
          status: ContractStatus.active,
          tenantName: 'Ayşe Yılmaz',
        ),
        tenantProfileName: null,
        loc: loc,
      );
      expect(tenantRes.isDirect, isTrue);
      expect(tenantRes.name, 'Ayşe Yılmaz (direct)');

      // 4. Claimed Tenant (registered user)
      final claimedTenantRes = PortfolioDirectStatusHelper.resolveTenantDisplay(
        property: directProp.copyWith(tenantName: 'Ayşe Yılmaz', tenantId: 'user_tenant_1'),
        contract: Contract(
          id: 'c1',
          propertyId: 'p1',
          landlordId: 'l1',
          inviteeEmail: 'ayse@example.com',
          token: 'mock-token-2',
          monthlyRent: 500,
          currency: 'EUR',
          startDate: DateTime(2026, 1, 1),
          status: ContractStatus.active,
          tenantName: 'Ayşe Yılmaz',
          tenantId: 'user_tenant_1',
        ),
        tenantProfileName: 'Ayşe Yılmaz',
        loc: loc,
      );
      expect(claimedTenantRes.isDirect, isFalse);
      expect(claimedTenantRes.name, 'Ayşe Yılmaz');
    });
  });
}
