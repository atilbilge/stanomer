import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Agency Pending Approvals with Disputed Payments', () {
    test('filters include both declared and disputed payments in pending approval queue', () {
      final payments = [
        {'id': 'pay-1', 'title': 'Kira', 'status': 'declared', 'amount': 500.0},
        {'id': 'pay-2', 'title': 'Elektrik', 'status': 'disputed', 'amount': 150.0, 'dispute_reason': 'Tutar hatalı'},
        {'id': 'pay-3', 'title': 'Su', 'status': 'pending', 'amount': 50.0},
        {'id': 'pay-4', 'title': 'Aidat', 'status': 'paid', 'amount': 100.0},
      ];

      final pendingApprovals = payments.where((item) => item['status'] == 'declared' || item['status'] == 'disputed').toList();

      expect(pendingApprovals.length, 2);
      expect(pendingApprovals.map((e) => e['id']), containsAll(['pay-1', 'pay-2']));
      expect(pendingApprovals.any((e) => e['status'] == 'disputed'), isTrue);
      expect(pendingApprovals.firstWhere((e) => e['id'] == 'pay-2')['dispute_reason'], 'Tutar hatalı');
    });

    test('unentered and overdue lists exclude disputed and declared items', () {
      final payments = [
        {'id': 'pay-1', 'title': 'Kira', 'status': 'declared', 'amount': 500.0},
        {'id': 'pay-2', 'title': 'Elektrik', 'status': 'disputed', 'amount': 150.0},
        {'id': 'pay-3', 'title': 'Su', 'status': 'pending', 'amount': 0.0, 'receiver_type': 'owner'},
        {'id': 'pay-4', 'title': 'Aidat', 'status': 'paid', 'amount': 100.0},
      ];

      final unentered = payments.where((item) {
        final status = item['status'] as String? ?? 'pending';
        if (status == 'paid' || status == 'declared' || status == 'disputed') return false;
        return (item['amount'] as double) == 0;
      }).toList();

      final overdue = payments.where((item) {
        final status = item['status'] as String? ?? 'pending';
        if (status == 'declared' || status == 'disputed' || status == 'paid') return false;
        return (item['amount'] as double) > 0;
      }).toList();

      expect(unentered.length, 1);
      expect(unentered.first['id'], 'pay-3');
      expect(overdue.length, 0);
    });
  });
}
