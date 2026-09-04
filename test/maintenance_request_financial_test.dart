import 'package:flutter_test/flutter_test.dart';
import 'package:stanomer/features/maintenance/domain/maintenance_request.dart';

void main() {
  group('MaintenanceRequest Financial Section Tests', () {
    test('should parse from Map/JSON with all financial fields', () {
      final json = {
        'id': 'req-123',
        'property_id': 'prop-456',
        'contract_id': 'con-789',
        'reporter_id': 'user-001',
        'title': 'Broken AC unit',
        'description': 'Water leaking from indoor unit',
        'category': 'appliance',
        'status': 'in_progress',
        'priority': 'urgent',
        'photos_urls': ['https://example.com/p1.jpg'],
        'cost_amount': 250.50,
        'currency': 'EUR',
        'paid_by': 'landlord',
        'payment_date': '2026-08-26T12:00:00.000Z',
        'payment_status': 'paid',
        'invoice_pdf_url': 'https://example.com/invoice.pdf',
        'created_at': '2026-08-26T10:00:00.000Z',
        'updated_at': '2026-08-26T12:30:00.000Z',
      };

      final request = MaintenanceRequest.fromMap(json);

      expect(request.id, 'req-123');
      expect(request.propertyId, 'prop-456');
      expect(request.contractId, 'con-789');
      expect(request.reporterId, 'user-001');
      expect(request.title, 'Broken AC unit');
      expect(request.category, MaintenanceCategory.appliance);
      expect(request.status, MaintenanceStatus.inProgress);
      expect(request.priority, MaintenancePriority.urgent);
      expect(request.photosUrls, ['https://example.com/p1.jpg']);
      expect(request.costAmount, 250.50);
      expect(request.currency, 'EUR');
      expect(request.paidBy, 'landlord');
      expect(request.paymentDate, DateTime.parse('2026-08-26T12:00:00.000Z'));
      expect(request.paymentStatus, 'paid');
      expect(request.invoicePdfUrl, 'https://example.com/invoice.pdf');
    });

    test('should convert to Map/JSON correctly including financial fields', () {
      final request = MaintenanceRequest(
        id: 'req-999',
        propertyId: 'prop-111',
        reporterId: 'user-222',
        title: 'Pipe Leak',
        costAmount: 12000.0,
        currency: 'RSD',
        paidBy: 'tenant',
        paymentStatus: 'pending',
        invoicePdfUrl: 'https://example.com/invoice_rsd.pdf',
      );

      final map = request.toMap();

      expect(map['id'], 'req-999');
      expect(map['property_id'], 'prop-111');
      expect(map['cost_amount'], 12000.0);
      expect(map['currency'], 'RSD');
      expect(map['paid_by'], 'tenant');
      expect(map['payment_status'], 'pending');
      expect(map['invoice_pdf_url'], 'https://example.com/invoice_rsd.pdf');
    });

    test('should support copyWith for financial fields', () {
      final initial = MaintenanceRequest(
        id: 'req-001',
        propertyId: 'prop-001',
        reporterId: 'user-001',
        title: 'Heater Repair',
        paymentStatus: 'pending',
      );

      final updated = initial.copyWith(
        costAmount: 180.0,
        currency: 'EUR',
        paidBy: 'landlord',
        paymentStatus: 'paid',
        paymentDate: DateTime.utc(2026, 8, 26),
        invoicePdfUrl: 'https://example.com/heater_invoice.pdf',
      );

      expect(updated.costAmount, 180.0);
      expect(updated.currency, 'EUR');
      expect(updated.paidBy, 'landlord');
      expect(updated.paymentStatus, 'paid');
      expect(updated.financialStatus, MaintenancePaymentStatus.paid);
      expect(updated.paymentDate, DateTime.utc(2026, 8, 26));
      expect(updated.invoicePdfUrl, 'https://example.com/heater_invoice.pdf');
      expect(initial.costAmount, isNull);
      expect(initial.paymentStatus, 'pending');
      expect(initial.financialStatus, MaintenancePaymentStatus.pendingReview);
    });

    test('should correctly resolve 4-tier MaintenancePaymentStatus from strings', () {
      expect(
        const MaintenanceRequest(id: '1', propertyId: '1', reporterId: '1', title: 'T', paymentStatus: 'pending_review').financialStatus,
        MaintenancePaymentStatus.pendingReview,
      );
      expect(
        const MaintenanceRequest(id: '2', propertyId: '1', reporterId: '1', title: 'T', paymentStatus: 'pending_payment').financialStatus,
        MaintenancePaymentStatus.pendingPayment,
      );
      expect(
        const MaintenanceRequest(id: '3', propertyId: '1', reporterId: '1', title: 'T', paymentStatus: 'paid').financialStatus,
        MaintenancePaymentStatus.paid,
      );
      expect(
        const MaintenanceRequest(id: '4', propertyId: '1', reporterId: '1', title: 'T', paymentStatus: 'rejected').financialStatus,
        MaintenancePaymentStatus.rejected,
      );
      expect(
        const MaintenanceRequest(id: '5', propertyId: '1', reporterId: '1', title: 'T', paymentStatus: 'legacy_pending').financialStatus,
        MaintenancePaymentStatus.pendingReview,
      );
    });

    test('displayId should use database ticketNumber when available and fallback when null', () {
      // 1. With database-backed ticketNumber
      const withTicket = MaintenanceRequest(
        id: 'req-uuid-1',
        ticketNumber: 'MR-10001',
        propertyId: 'p1',
        reporterId: 'u1',
        title: 'Broken window',
      );
      expect(withTicket.ticketNumber, 'MR-10001');
      expect(withTicket.displayId, '#MR-10001');

      // 2. With # prefix already present
      const withHashTicket = MaintenanceRequest(
        id: 'req-uuid-2',
        ticketNumber: '#MR-10002',
        propertyId: 'p1',
        reporterId: 'u1',
        title: 'Broken lock',
      );
      expect(withHashTicket.displayId, '#MR-10002');

      // 3. Backward-compatibility: ticketNumber is null (e.g. production DB / unmigrated row)
      const withoutTicket = MaintenanceRequest(
        id: 'req-uuid-3',
        ticketNumber: null,
        propertyId: 'p1',
        reporterId: 'u1',
        title: 'Leaking pipe',
      );
      final fallbackId = withoutTicket.displayId;
      expect(fallbackId, startsWith('#MR-'));
      expect(fallbackId.length, 9); // e.g. #MR-12345
    });

    test('should serialize and deserialize ticket_number via fromMap/toMap', () {
      final json = {
        'id': 'uuid-abc',
        'ticket_number': 'MR-10450',
        'property_id': 'prop-1',
        'reporter_id': 'user-1',
        'title': 'Test Request',
      };

      final parsed = MaintenanceRequest.fromMap(json);
      expect(parsed.ticketNumber, 'MR-10450');
      expect(parsed.displayId, '#MR-10450');

      final exported = parsed.toMap();
      expect(exported['ticket_number'], 'MR-10450');
    });
  });
}

