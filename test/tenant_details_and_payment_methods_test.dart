import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stanomer/core/l10n/app_localizations.dart';
import 'package:stanomer/features/auth/data/auth_providers.dart';
import 'package:stanomer/features/property/domain/contract.dart';
import 'package:stanomer/features/property/domain/property.dart';
import 'package:stanomer/features/property/domain/rent_payment.dart';
import 'package:stanomer/features/property/domain/tenant_secondary_contact.dart';
import 'package:stanomer/features/property/presentation/invite_tenant_screen.dart';
import 'package:stanomer/features/property/presentation/property_settings_screen.dart';
import 'package:stanomer/features/property/data/property_repository.dart';
import 'package:stanomer/features/agency/domain/agency_color_scheme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  group('Tenant Secondary Contact Tests', () {
    test('TenantSecondaryContact toJson and fromJson', () {
      final contact = TenantSecondaryContact(
        fullName: 'Ana Petrović',
        relationship: 'Family Member',
        phone: '+381601112233',
        email: 'ana@example.com',
      );

      final json = contact.toJson();
      expect(json['full_name'], 'Ana Petrović');
      expect(json['relationship'], 'Family Member');
      expect(json['phone'], '+381601112233');
      expect(json['email'], 'ana@example.com');

      final fromJson = TenantSecondaryContact.fromJson(json);
      expect(fromJson.fullName, 'Ana Petrović');
      expect(fromJson.relationship, 'Family Member');
      expect(fromJson.phone, '+381601112233');
      expect(fromJson.email, 'ana@example.com');
    });

    test('TenantSecondaryContact handles empty and null fields safely', () {
      final fromJson = TenantSecondaryContact.fromJson({
        'full_name': 'Nikola',
      });
      expect(fromJson.fullName, 'Nikola');
      expect(fromJson.relationship, '');
      expect(fromJson.phone, isNull);
      expect(fromJson.email, isNull);
    });
  });

  group('ExpenseItem Payment Method Tests', () {
    test('Defaults to bank_transfer', () {
      final item = ExpenseItem(name: 'Struja');
      expect(item.paymentMethod, 'bank_transfer');
      expect(item.isCash, isFalse);

      final json = item.toJson();
      expect(json['payment_method'], 'bank_transfer');
    });

    test('Custom payment method cash works', () {
      final item = ExpenseItem(
        name: 'Voda',
        paymentMethod: 'cash',
      );
      expect(item.paymentMethod, 'cash');
      expect(item.isCash, isTrue);

      final json = item.toJson();
      expect(json['payment_method'], 'cash');

      final parsed = ExpenseItem.fromJson(json);
      expect(parsed.paymentMethod, 'cash');
      expect(parsed.isCash, isTrue);
    });

    test('copyWith properly updates paymentMethod', () {
      final item = ExpenseItem(name: 'Grejanje');
      final updated = item.copyWith(paymentMethod: 'cash');
      expect(updated.paymentMethod, 'cash');
      expect(updated.isCash, isTrue);
    });
  });

  group('Contract Model Tenant Details Tests', () {
    test('Contract with tenant details and secondary contacts', () {
      final contractJson = {
        'id': 'contract-123',
        'property_id': 'prop-456',
        'monthly_rent': 500.0,
        'currency': 'EUR',
        'deposit_currency': 'EUR',
        'due_day': 5,
        'start_date': '2026-09-01T00:00:00.000Z',
        'end_date': '2027-09-01T00:00:00.000Z',
        'status': 'active',
        'tenant_name': 'Petar Petrović',
        'tenant_id_number': 'JMBG1234567890123',
        'tenant_phone': '+381609998877',
        'tenant_notes': 'Has a trained guide dog',
        'tenant_id_document_url': 'https://example.com/id.pdf',
        'tenant_secondary_contacts': [
          {
            'full_name': 'Milica Assistant',
            'relationship': 'Personal Assistant',
            'phone': '+381608887766',
            'email': 'milica@example.com',
          }
        ],
        'expenses_config': [
          {
            'name': 'Internet',
            'receiver': 'owner',
            'payment_method': 'cash',
          }
        ],
      };

      final contract = Contract.fromJson(contractJson);
      expect(contract.tenantName, 'Petar Petrović');
      expect(contract.tenantIdNumber, 'JMBG1234567890123');
      expect(contract.tenantPhone, '+381609998877');
      expect(contract.tenantNotes, 'Has a trained guide dog');
      expect(contract.tenantIdDocumentUrl, 'https://example.com/id.pdf');
      expect(contract.tenantSecondaryContacts.length, 1);
      expect(contract.tenantSecondaryContacts.first.fullName, 'Milica Assistant');
      expect(contract.tenantSecondaryContacts.first.relationship, 'Personal Assistant');
      expect(contract.expensesConfig.first.isCash, isTrue);

      final mapped = contract.toJson();
      expect(mapped['tenant_name'], 'Petar Petrović');
      expect(mapped['tenant_id_number'], 'JMBG1234567890123');
      expect(mapped['tenant_phone'], '+381609998877');
      expect(mapped['tenant_notes'], 'Has a trained guide dog');
      expect(mapped['tenant_id_document_url'], 'https://example.com/id.pdf');
      expect((mapped['tenant_secondary_contacts'] as List).length, 1);
    });
  });

  group('RentPayment Payment Method Tests', () {
    test('RentPayment defaults to bank_transfer and supports cash', () {
      final paymentBank = RentPayment(
        id: 'pm-1',
        propertyId: 'prop-1',
        title: 'Kira',
        amount: 500,
        currency: 'EUR',
        dueDate: DateTime(2026, 9, 5),
        status: 'pending',
      );
      expect(paymentBank.paymentMethod, 'bank_transfer');
      expect(paymentBank.isCashPayment, isFalse);

      final paymentCash = RentPayment(
        id: 'pm-2',
        propertyId: 'prop-1',
        title: 'Depozito',
        amount: 500,
        currency: 'EUR',
        dueDate: DateTime(2026, 9, 5),
        status: 'paid',
        paymentMethod: 'cash',
      );
      expect(paymentCash.paymentMethod, 'cash');
      expect(paymentCash.isCashPayment, isTrue);

      final json = paymentCash.toJson();
      expect(json['payment_method'], 'cash');

      final fromJson = RentPayment.fromJson(json);
      expect(fromJson.paymentMethod, 'cash');
      expect(fromJson.isCashPayment, isTrue);
    });
  });

  group('InviteTenantScreen Extra Details & Payment Method Visibility Tests', () {
    final independentProperty = Property(
      id: 'prop-independent',
      name: 'Standalone Flat',
      address: 'Main St 10',
      city: 'Belgrade',
      landlordId: 'landlord-user',
      currency: 'EUR',
      defaultMonthlyRent: 500,
      expensesTemplate: [
        ExpenseItem(name: 'Struja', receiver: PaymentReceiver.utility),
      ],
    );

    final agencyProperty = Property(
      id: 'prop-agency',
      name: 'Agency Managed Apt',
      address: 'Center St 5',
      city: 'Belgrade',
      landlordId: 'landlord-user',
      agencyId: 'agency-user',
      currency: 'EUR',
      defaultMonthlyRent: 800,
      expensesTemplate: [
        ExpenseItem(name: 'Struja', receiver: PaymentReceiver.utility),
      ],
    );

    const landlordUser = User(
      id: 'landlord-user',
      appMetadata: {},
      userMetadata: {'role': 'landlord'},
      aud: 'authenticated',
      createdAt: '2026-01-01',
    );

    const agencyUser = User(
      id: 'agency-user',
      appMetadata: {},
      userMetadata: {'role': 'agency'},
      aud: 'authenticated',
      createdAt: '2026-01-01',
    );

    testWidgets('Independent landlord does NOT see extra tenant details or expense payment methods', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => landlordUser),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('tr'),
            home: InviteTenantScreen(property: independentProperty),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Independent landlord should see standard tenant fields:
      expect(find.textContaining('Kiracı Adı & Soyadı'), findsOneWidget);
      expect(find.text('Telefon'), findsOneWidget);
      // Independent landlord: email is optional
      expect(find.text('Kiracının E-postası (İsteğe Bağlı)'), findsOneWidget);
      expect(find.text('Kiracının E-postası *'), findsNothing);

      // Independent landlord must NOT see the 5 extra agency fields:
      // 1. ID Number
      expect(find.text('Kimlik / Pasaport / JMBG'), findsNothing);
      // 2. Tenant Notes
      expect(find.text('Kiracıya İlişkin Notlar (İsteğe Bağlı)'), findsNothing);
      // 3. ID Document upload
      expect(find.text('Kiracı Kimlik Belgesi / Pasaport'), findsNothing);
      // 4. Secondary contacts
      expect(find.text('Ek İletişim Kişileri'), findsNothing);
      expect(find.text('Kişi Ekle'), findsNothing);
      // 5. Expense Payment Method chips
      expect(find.text('Ödeme Yöntemi:'), findsNothing);
    });

    testWidgets('Agency-managed property DOES see extra tenant details, expense payment methods, and mandatory email', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => agencyUser),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('tr'),
            home: InviteTenantScreen(property: agencyProperty),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Agency should see standard fields
      expect(find.textContaining('Kiracı Adı & Soyadı'), findsOneWidget);
      expect(find.text('Telefon'), findsOneWidget);
      // Agency: email is mandatory
      expect(find.text('Kiracının E-postası *'), findsOneWidget);

      // Agency MUST see all 5 extra fields:
      // 1. ID Number
      expect(find.text('Kimlik / Pasaport / JMBG'), findsOneWidget);
      // 2. Tenant Notes
      expect(find.text('Kiracıya İlişkin Notlar (İsteğe Bağlı)'), findsOneWidget);
      // 3. ID Document upload
      expect(find.text('Kiracı Kimlik Belgesi / Pasaport'), findsOneWidget);
      // 4. Secondary contacts
      expect(find.text('Ek İletişim Kişileri'), findsOneWidget);
      expect(find.text('Kişi Ekle'), findsOneWidget);
      // 5. Expense Payment Method chips
      expect(find.text('Ödeme Yöntemi:'), findsOneWidget);
      expect(find.text('Banka'), findsOneWidget);
      expect(find.text('Nakit'), findsOneWidget);
    });

    testWidgets('Email validation: Optional for independent landlord, but invalid email format still fails', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => landlordUser),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('tr'),
            home: InviteTenantScreen(property: independentProperty),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final emailFormField = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Kiracının E-postası (İsteğe Bağlı)'),
      );

      // Independent landlord: empty/null is valid (optional)
      expect(emailFormField.validator!(''), isNull);
      expect(emailFormField.validator!(null), isNull);
      expect(emailFormField.validator!('   '), isNull);

      // Invalid format is rejected
      expect(emailFormField.validator!('not-an-email'), 'Geçerli bir e-posta adresi giriniz');

      // Valid email is accepted
      expect(emailFormField.validator!('tenant@example.com'), isNull);
    });

    testWidgets('Email validation: Mandatory for agency property', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => agencyUser),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('tr'),
            home: InviteTenantScreen(property: agencyProperty),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final emailFormField = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Kiracının E-postası *'),
      );

      // Agency: empty or whitespace must return fieldRequired
      expect(emailFormField.validator!(''), 'Bu alan zorunludur');
      expect(emailFormField.validator!(null), 'Bu alan zorunludur');
      expect(emailFormField.validator!('   '), 'Bu alan zorunludur');

      // Valid email is accepted
      expect(emailFormField.validator!('agency.tenant@example.com'), isNull);
    });
  });

  group('PropertySettingsScreen Contract & Property Settings Visibility Tests', () {
    final independentProperty = Property(
      id: 'prop-independent',
      name: 'Standalone Flat',
      address: 'Main St 10',
      city: 'Belgrade',
      landlordId: 'landlord-user',
      currency: 'EUR',
      defaultMonthlyRent: 500,
      expensesTemplate: [
        ExpenseItem(name: 'Struja', receiver: PaymentReceiver.utility),
      ],
    );

    final agencyProperty = Property(
      id: 'prop-agency',
      name: 'Agency Managed Apt',
      address: 'Center St 5',
      city: 'Belgrade',
      landlordId: 'landlord-user',
      agencyId: 'agency-user',
      currency: 'EUR',
      defaultMonthlyRent: 800,
      expensesTemplate: [
        ExpenseItem(name: 'Struja', receiver: PaymentReceiver.utility),
      ],
    );

    final testContract = Contract(
      id: 'contract-test',
      propertyId: 'prop-agency',
      landlordId: 'landlord-user',
      monthlyRent: 800,
      currency: 'EUR',
      depositCurrency: 'EUR',
      dueDay: 5,
      inviteeEmail: 'tenant@example.com',
      token: 'tok-123',
      expensesConfig: [
        ExpenseItem(name: 'Struja', receiver: PaymentReceiver.utility),
      ],
    );

    final testIndependentContract = Contract(
      id: 'contract-independent',
      propertyId: 'prop-independent',
      landlordId: 'landlord-user',
      monthlyRent: 500,
      currency: 'EUR',
      depositCurrency: 'EUR',
      dueDay: 5,
      inviteeEmail: 'tenant@example.com',
      token: 'tok-indep',
      expensesConfig: [
        ExpenseItem(name: 'Struja', receiver: PaymentReceiver.utility),
      ],
    );

    const landlordUser = User(
      id: 'landlord-user',
      appMetadata: {},
      userMetadata: {'role': 'landlord'},
      aud: 'authenticated',
      createdAt: '2026-01-01',
    );

    const agencyUser = User(
      id: 'agency-user',
      appMetadata: {},
      userMetadata: {'role': 'agency'},
      aud: 'authenticated',
      createdAt: '2026-01-01',
    );

    testWidgets('Contract Tab: Independent landlord does NOT see extra tenant details or expense payment methods', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => landlordUser),
            userRoleProvider.overrideWithValue('landlord'),
            agencyColorSchemeProvider.overrideWithValue(const AgencyColorScheme.landlordScheme()),
            activeContractProvider(independentProperty.id).overrideWith((ref) => Stream.value(testIndependentContract)),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('tr'),
            home: PropertySettingsScreen(property: independentProperty, initialTab: 'contract'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Independent landlord should NOT see extra tenant details:
      expect(find.text('Kimlik / Pasaport / JMBG'), findsNothing);
      expect(find.text('Kiracıya İlişkin Notlar'), findsNothing);
      expect(find.text('Kiracı Kimlik Belgesi / Pasaport'), findsNothing);
      expect(find.text('Ek İletişim Kişileri'), findsNothing);
      expect(find.text('Kiracının E-postası'), findsNothing);
      // Independent landlord should NOT see payment method chips in expenses:
      expect(find.text('Ödeme Yöntemi:'), findsNothing);
    });

    testWidgets('Contract Tab: Agency-managed property DOES see extra tenant details and expense payment methods', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => agencyUser),
            userRoleProvider.overrideWithValue('agency'),
            agencyColorSchemeProvider.overrideWithValue(const AgencyColorScheme.agencyScheme()),
            activeContractProvider(agencyProperty.id).overrideWith((ref) => Stream.value(testContract)),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('tr'),
            home: PropertySettingsScreen(property: agencyProperty, initialTab: 'contract'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Agency property MUST see extra tenant details:
      expect(find.text('Kiracının E-postası'), findsOneWidget);
      expect(find.text('tenant@example.com'), findsOneWidget);
      expect(find.text('Kimlik / Pasaport / JMBG'), findsOneWidget);
      expect(find.text('Kiracıya İlişkin Notlar'), findsOneWidget);
      expect(find.text('Kiracı Kimlik Belgesi / Pasaport'), findsOneWidget);
      expect(find.text('Ek İletişim Kişileri'), findsOneWidget);
      // Agency property MUST see payment method chips in expenses:
      expect(find.text('Ödeme Yöntemi:'), findsOneWidget);
      expect(find.text('Banka'), findsOneWidget);
      expect(find.text('Nakit'), findsOneWidget);
    });

    testWidgets('Property Tab: Independent landlord does NOT see physical specs or expense payment methods', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => landlordUser),
            userRoleProvider.overrideWithValue('landlord'),
            agencyColorSchemeProvider.overrideWithValue(const AgencyColorScheme.landlordScheme()),
            activeContractProvider(independentProperty.id).overrideWith((ref) => Stream.value(testIndependentContract)),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('tr'),
            home: PropertySettingsScreen(property: independentProperty, initialTab: 'property'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Standard fields are visible:
      expect(find.byType(TextFormField), findsWidgets);
      // Physical specs MUST NOT be visible for independent landlord:
      expect(find.byIcon(LucideIcons.doorOpen), findsNothing);
      expect(find.text('Banka'), findsNothing);
      expect(find.text('Nakit'), findsNothing);
    });

    testWidgets('Property Tab: Agency-managed property DOES see physical specs and expense payment methods', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => agencyUser),
            userRoleProvider.overrideWithValue('agency'),
            agencyColorSchemeProvider.overrideWithValue(const AgencyColorScheme.agencyScheme()),
            activeContractProvider(agencyProperty.id).overrideWith((ref) => Stream.value(testContract)),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('tr'),
            home: PropertySettingsScreen(property: agencyProperty, initialTab: 'property'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Physical specs MUST be visible:
      expect(find.byIcon(LucideIcons.doorOpen), findsOneWidget);
      expect(find.text('Banka'), findsOneWidget);
      expect(find.text('Nakit'), findsOneWidget);
    });
  });
}
