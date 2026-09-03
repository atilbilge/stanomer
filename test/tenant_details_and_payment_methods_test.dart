import 'package:flutter_test/flutter_test.dart';
import 'package:stanomer/features/property/domain/contract.dart';
import 'package:stanomer/features/property/domain/rent_payment.dart';
import 'package:stanomer/features/property/domain/tenant_secondary_contact.dart';

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
      expect(contract.tenantIdNumber, 'JMBG1234567890123');
      expect(contract.tenantPhone, '+381609998877');
      expect(contract.tenantNotes, 'Has a trained guide dog');
      expect(contract.tenantIdDocumentUrl, 'https://example.com/id.pdf');
      expect(contract.tenantSecondaryContacts.length, 1);
      expect(contract.tenantSecondaryContacts.first.fullName, 'Milica Assistant');
      expect(contract.tenantSecondaryContacts.first.relationship, 'Personal Assistant');
      expect(contract.expensesConfig.first.isCash, isTrue);

      final mapped = contract.toJson();
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
}
