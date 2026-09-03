import 'package:flutter_test/flutter_test.dart';
import 'package:stanomer/features/property/domain/rent_payment.dart';

void main() {
  group('Mark as Paid with Receipt & Note Tests', () {
    test('RentPayment model properly deserializes receipt_url and owner_note', () {
      final json = {
        'id': 'pay-123',
        'property_id': 'prop-1',
        'month': 'Ocak 2026',
        'amount': 500.0,
        'currency': 'EUR',
        'due_date': '2026-01-15T00:00:00Z',
        'status': 'paid',
        'title': 'Kira',
        'receipt_url': 'https://example.com/receipt.pdf',
        'owner_note': 'Elden nakit teslim alındı',
      };

      final payment = RentPayment.fromJson(json);
      expect(payment.id, 'pay-123');
      expect(payment.status, 'paid');
      expect(payment.receiptUrl, 'https://example.com/receipt.pdf');
      expect(payment.ownerNote, 'Elden nakit teslim alındı');
    });

    test('RentPayment handles null receipt_url and owner_note', () {
      final json = {
        'id': 'pay-456',
        'property_id': 'prop-1',
        'month': 'Şubat 2026',
        'amount': 600.0,
        'currency': 'RSD',
        'due_date': '2026-02-15T00:00:00Z',
        'status': 'paid',
        'title': 'Elektrik',
      };

      final payment = RentPayment.fromJson(json);
      expect(payment.id, 'pay-456');
      expect(payment.status, 'paid');
      expect(payment.receiptUrl, isNull);
      expect(payment.ownerNote, isNull);
    });
  });
}
