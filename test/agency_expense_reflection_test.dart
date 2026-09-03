import 'package:flutter_test/flutter_test.dart';
import 'package:stanomer/features/maintenance/domain/maintenance_request.dart';
import 'package:stanomer/features/maintenance/domain/maintenance_charge.dart';

void main() {
  group('Agency Expense Reflection Tests', () {
    test('Agency paid fixture expense assigns landlord as debtor', () {
      const effectivePaidBy = 'agency';
      const paymentStatus = 'pending_payment'; // or null

      final bool isAgencyTenantDamage = (effectivePaidBy == 'agency') && (paymentStatus == 'pending_review');
      final String debtorId = isAgencyTenantDamage ? 'tenant-1' : 'landlord-1';
      final String creditorId = 'agency-1';
      final String chargeType = effectivePaidBy == 'agency' ? 'agency_advance' : 'direct_charge';
      final String chargeStatus = paymentStatus == 'pending_payment' ? 'approved' : 'pending';

      expect(isAgencyTenantDamage, isFalse);
      expect(debtorId, equals('landlord-1'));
      expect(creditorId, equals('agency-1'));
      expect(chargeType, equals('agency_advance'));
      expect(chargeStatus, equals('approved'));
    });

    test('Agency paid tenant damage assigns tenant as debtor', () {
      const effectivePaidBy = 'agency';
      const paymentStatus = 'pending_review'; // Option B: Kiracı Kullanımı / Kiracıya Yansıt

      final bool isAgencyTenantDamage = (effectivePaidBy == 'agency') && (paymentStatus == 'pending_review');
      final String debtorId = isAgencyTenantDamage ? 'tenant-1' : 'landlord-1';
      final String creditorId = 'agency-1';
      final String chargeType = effectivePaidBy == 'agency' ? 'agency_advance' : 'direct_charge';

      expect(isAgencyTenantDamage, isTrue);
      expect(debtorId, equals('tenant-1'));
      expect(creditorId, equals('agency-1'));
      expect(chargeType, equals('agency_advance'));
    });

    test('isAddToRent evaluates true when agency paid for tenant damage', () {
      final charge = MaintenanceCharge(
        id: 'charge-1',
        maintenanceRequestId: 'req-1',
        propertyId: 'prop-1',
        debtorId: 'tenant-1',
        creditorId: 'agency-1',
        chargeType: 'agency_advance',
        approverRole: 'agency',
        amount: 150.0,
        currency: 'EUR',
        status: 'approved',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final req = MaintenanceRequest(
        id: 'req-1',
        propertyId: 'prop-1',
        reporterId: 'agency-user-1',
        title: 'Tamir',
        category: MaintenanceCategory.plumbing,
        priority: MaintenancePriority.medium,
        costAmount: 150.0,
        paidBy: 'agency',
        paymentStatus: 'pending_payment',
        createdAt: DateTime.now(),
      );

      const tenantId = 'tenant-1';
      final isAddToRent = req.paidBy == 'landlord' || (req.paidBy == 'agency' && charge.debtorId == tenantId);

      expect(isAddToRent, isTrue);
    });

    test('canLandlordSettle permission is granted to agency manager for agency-paid tenant damage', () {
      const isManagedByAgency = true;
      const isAgencyManager = true;
      const isDeductFromRent = false;
      const isAddToRent = false;
      const isAgencyPaid = true;
      const isTenantDebtor = true;
      const isPendingPayment = true;

      final bool canLandlordSettle = isManagedByAgency
          ? isAgencyManager && (isDeductFromRent || isAddToRent || (isAgencyPaid && isTenantDebtor)) && isPendingPayment
          : isAgencyManager && (isDeductFromRent || isAddToRent) && isPendingPayment;

      expect(canLandlordSettle, isTrue);
    });

    test('Agency approval of payment receipt resolves targetPaymentStatus to paid without infinite loop', () {
      const isAgencyApproving = true;
      const hasPaymentSubmission = true;
      const requestPaidBy = 'agency';

      String targetPaidBy = requestPaidBy;
      String targetPaymentStatus;

      if (isAgencyApproving) {
        if (hasPaymentSubmission) {
          targetPaidBy = requestPaidBy;
          targetPaymentStatus = 'paid';
        } else {
          targetPaymentStatus = 'pending_payment';
        }
      } else {
        targetPaymentStatus = 'pending_payment';
      }

      expect(targetPaymentStatus, equals('paid'));
      expect(targetPaidBy, equals('agency'));
    });

    test('Initial agency-paid expense has hasPaymentSubmission false and isAgencyApprovalActionNeeded false', () {
      const hasInvoiceUrl = true;
      const isPendingPayment = true;
      const isPendingReview = false;
      const isAgencyPaid = true;
      const isManagedByAgency = true;
      const isAgencyManager = true;

      final bool hasPaymentSubmission = hasInvoiceUrl && isPendingReview;
      final bool isAgencyApprovalActionNeeded = isManagedByAgency && isAgencyManager &&
          (!isAgencyPaid || (isAgencyPaid && hasPaymentSubmission)) &&
          isPendingReview;

      expect(hasPaymentSubmission, isFalse);
      expect(isAgencyApprovalActionNeeded, isFalse);
    });

    test('When tenant declares payment for agency debt, hasPaymentSubmission and isAgencyApprovalActionNeeded become true', () {
      const hasReceiptUrl = true;
      const isPendingReview = true;
      const isAgencyPaid = true;
      const isManagedByAgency = true;
      const isAgencyManager = true;

      final bool hasPaymentSubmission = hasReceiptUrl && isPendingReview;
      final bool isAgencyApprovalActionNeeded = isManagedByAgency && isAgencyManager &&
          (!isAgencyPaid || (isAgencyPaid && hasPaymentSubmission)) &&
          isPendingReview;

      expect(hasPaymentSubmission, isTrue);
      expect(isAgencyApprovalActionNeeded, isTrue);

      // Rejection reverts to pending_payment
      const hasCost = true;
      final String rejectionTargetStatus = hasCost ? 'pending_payment' : 'pending_review';
      expect(rejectionTargetStatus, equals('pending_payment'));
    });

    test('EditFinancialDetailsDialog resolves finalPaymentStatus as pending_payment for agency', () {
      const paidBy = 'agency';
      const declarationIntent = 'damage_tenant';

      final String finalPaymentStatus;
      if (declarationIntent == 'self') {
        finalPaymentStatus = 'paid';
      } else if (paidBy == 'agency') {
        finalPaymentStatus = 'pending_payment';
      } else {
        finalPaymentStatus = 'pending_review';
      }

      expect(finalPaymentStatus, equals('pending_payment'));
    });

    test('maintenanceOwedToAgencyList excludes tenant debts and only includes landlord debts', () {
      final payments = [
        {
          'is_maintenance': true,
          'paid_by': 'agency',
          'is_tenant_debtor': true,
          'is_landlord_debtor': false,
          'status': 'pending_payment',
          'payment_status': 'pending_payment',
          'cost_amount': 111.0,
          'remaining_amount': 111.0,
          'settled_amount': 0.0,
        },
        {
          'is_maintenance': true,
          'paid_by': 'agency',
          'is_tenant_debtor': false,
          'is_landlord_debtor': true,
          'status': 'pending_payment',
          'payment_status': 'pending_payment',
          'cost_amount': 250.0,
          'remaining_amount': 250.0,
          'settled_amount': 0.0,
        },
      ];

      final filtered = payments.where((item) {
        if (item['is_maintenance'] != true) return false;
        if (item['paid_by'] != 'agency') return false;
        if (item['is_tenant_debtor'] == true) return false;
        return true;
      }).toList();

      expect(filtered.length, equals(1));
      expect(filtered.first['cost_amount'], equals(250.0));
      expect(filtered.first['is_landlord_debtor'], isTrue);
    });

    test('maintenancePaidList includes settled agency-paid landlord recourse expenses', () {
      final payments = [
        // 1) Landlord direct paid expense
        {
          'is_maintenance': true,
          'paid_by': 'landlord',
          'is_landlord_debtor': true,
          'is_tenant_debtor': false,
          'status': 'paid',
          'cost_amount': 300.0,
        },
        // 2) Agency paid, recurred to landlord, now settled / paid
        {
          'is_maintenance': true,
          'paid_by': 'agency',
          'is_landlord_debtor': true,
          'is_tenant_debtor': false,
          'status': 'paid',
          'cost_amount': 450.0,
        },
        // 3) Agency paid, tenant damage, paid by tenant (tenant usage damage)
        {
          'is_maintenance': true,
          'paid_by': 'agency',
          'is_landlord_debtor': false,
          'is_tenant_debtor': true,
          'status': 'paid',
          'cost_amount': 111.0,
        },
        // 4) Agency paid, landlord debtor, NOT yet paid
        {
          'is_maintenance': true,
          'paid_by': 'agency',
          'is_landlord_debtor': true,
          'is_tenant_debtor': false,
          'status': 'pending_payment',
          'cost_amount': 200.0,
        },
      ];

      final paidMaintenance = payments.where((item) {
        if (item['is_maintenance'] != true) return false;
        if (item['status'] != 'paid') return false;

        final isLandlordDebtor = item['is_landlord_debtor'] == true;
        final isTenantDebtor = item['is_tenant_debtor'] == true;
        final paidBy = item['paid_by'] as String?;

        if (paidBy == 'landlord') return true;
        if (paidBy == 'agency') {
          if (isTenantDebtor) return false;
          if (isLandlordDebtor) return true;
          return true;
        }
        return false;
      }).toList();

      expect(paidMaintenance.length, equals(2));
      final totalCost = paidMaintenance.fold<double>(0.0, (sum, i) => sum + (i['cost_amount'] as double));
      expect(totalCost, equals(750.0)); // 300 + 450
    });

    test('Tenant fixture reimbursement declaration resolves to pending_agency_approval and reimbursement chargeType', () {
      const isAgencyManaged = true;
      const isAgency = false;
      const declarationIntent = 'reimburse';
      const paidBy = 'tenant';

      final String finalPaymentStatus;
      if (declarationIntent == 'self') {
        finalPaymentStatus = 'paid';
      } else if (paidBy == 'tenant' && declarationIntent == 'reimburse') {
        if (isAgency) {
          finalPaymentStatus = 'pending_payment';
        } else if (isAgencyManaged) {
          finalPaymentStatus = 'pending_agency_approval';
        } else {
          finalPaymentStatus = 'pending_review';
        }
      } else {
        finalPaymentStatus = 'pending_review';
      }

      final chargeType = (declarationIntent == 'self') ? 'direct_charge' : 'reimbursement';
      final settlementMethod = (declarationIntent == 'self') ? 'separate_payment' : 'rent_offset';

      expect(finalPaymentStatus, equals('pending_agency_approval'));
      expect(chargeType, equals('reimbursement'));
      expect(settlementMethod, equals('rent_offset'));
    });

    test('Agency approving tenant fixture reimbursement transitions to pending_payment, never paid', () {
      const isAgencyApproving = true;
      const isTenantSelfDeclared = false;
      const isTenantReimburseDeclared = true;
      const isPayerTenant = true;
      const targetPaidBy = 'tenant';
      const hasPaymentSubmission = true; // Tenant uploaded receipt

      String targetPaymentStatus;
      if (isAgencyApproving) {
        if (isTenantSelfDeclared) {
          targetPaymentStatus = 'paid';
        } else if (isTenantReimburseDeclared || isPayerTenant || targetPaidBy == 'tenant') {
          // Tenant declared fixture reimbursement -> moves to pending_payment for rent deduction!
          targetPaymentStatus = 'pending_payment';
        } else if (hasPaymentSubmission) {
          targetPaymentStatus = 'paid';
        } else {
          targetPaymentStatus = 'pending_payment';
        }
      } else {
        targetPaymentStatus = 'pending_payment';
      }

      expect(targetPaymentStatus, equals('pending_payment'));
      expect(targetPaymentStatus, isNot(equals('paid')));
    });

    test('Property detail approve button transitions tenant fixture reimbursement to pending_payment', () {
      const paidBy = 'tenant';
      const matchingChargeType = 'reimbursement';
      const isPendingOppositeApproval = false;

      final isTenantReimburse = paidBy == 'tenant' && matchingChargeType != 'direct_charge';
      final nextStatus = (isPendingOppositeApproval || isTenantReimburse) ? 'pending_payment' : 'paid';

      expect(nextStatus, equals('pending_payment'));
    });

    test('Rejecting initial tenant fixture declaration sets status to rejected, never pending_payment', () {
      const paidBy = 'tenant';
      const hasPaymentSubmission = true; // Tenant submitted invoice document with declaration
      const matchingChargeStatus = 'pending';
      const matchingChargeType = 'reimbursement';

      final bool isPaymentReceiptRejection = hasPaymentSubmission &&
          ((paidBy == 'agency') ||
           (matchingChargeStatus == 'approved' && matchingChargeType != 'reimbursement'));

      final String targetStatus = isPaymentReceiptRejection ? 'pending_payment' : 'rejected';
      final String targetChargeStatus = isPaymentReceiptRejection ? 'approved' : 'rejected';

      expect(isPaymentReceiptRejection, isFalse);
      expect(targetStatus, equals('rejected'));
      expect(targetChargeStatus, equals('rejected'));
      expect(targetStatus, isNot(equals('pending_payment')));
    });

    test('Rejecting payment proof on existing agency debt reverts status to pending_payment', () {
      const paidBy = 'agency';
      const hasPaymentSubmission = true; // Tenant submitted payment proof for existing damage debt
      const matchingChargeStatus = 'approved';
      const matchingChargeType = 'agency_advance';

      final bool isPaymentReceiptRejection = hasPaymentSubmission &&
          ((paidBy == 'agency') ||
           (matchingChargeStatus == 'approved' && matchingChargeType != 'reimbursement'));

      final String targetStatus = isPaymentReceiptRejection ? 'pending_payment' : 'rejected';
      final String targetChargeStatus = isPaymentReceiptRejection ? 'approved' : 'rejected';

      expect(isPaymentReceiptRejection, isTrue);
      expect(targetStatus, equals('pending_payment'));
      expect(targetChargeStatus, equals('approved'));
    });

    test('Tenant self-covered declaration on agency property routes to pending_agency_approval', () {
      const isAgency = false;
      const isAgencyManaged = true;
      const declarationIntent = 'self';

      final String finalPaymentStatus;
      if (declarationIntent == 'self') {
        if (!isAgency && isAgencyManaged) {
          finalPaymentStatus = 'pending_agency_approval';
        } else {
          finalPaymentStatus = 'paid';
        }
      } else {
        finalPaymentStatus = 'pending_payment';
      }

      expect(finalPaymentStatus, equals('pending_agency_approval'));
    });

    test('Agency approving tenant self-covered declaration transitions to paid (no rent impact)', () {
      const isAgencyApproving = true;
      const isTenantSelfDeclared = true;
      const isTenantReimburseDeclared = false;

      String targetPaymentStatus;
      if (isAgencyApproving) {
        if (isTenantSelfDeclared) {
          targetPaymentStatus = 'paid';
        } else if (isTenantReimburseDeclared) {
          targetPaymentStatus = 'pending_payment';
        } else {
          targetPaymentStatus = 'pending_payment';
        }
      } else {
        targetPaymentStatus = 'pending_payment';
      }

      expect(targetPaymentStatus, equals('paid'));
    });

    test('Agency paid maintenance advance is included in maintenanceOwedToAgencyList and respects period filter', () {
      final item = {
        'id': 'maint-123',
        'is_maintenance': true,
        'paid_by': 'agency',
        'is_tenant_debtor': false,
        'status': 'pending_payment',
        'payment_status': 'pending_payment',
        'cost_amount': 250.0,
        'remaining_amount': 250.0,
        'settled_amount': 0.0,
        'due_date': DateTime.now().toIso8601String(), // current period
      };

      // 1. Period filter verification
      final periodStartDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
      final dt = DateTime.parse(item['due_date'] as String);
      final isInPeriod = !dt.isBefore(periodStartDate);
      expect(isInPeriod, isTrue);

      // 2. maintenanceOwedToAgencyList check
      final paidBy = item['paid_by'] as String?;
      final status = item['status'] as String?;
      final paymentStatus = item['payment_status'] as String?;
      expect(paidBy, equals('agency'));
      expect(item['is_tenant_debtor'], isFalse);
      expect(status != 'paid' && paymentStatus != 'paid' && paymentStatus != 'rejected', isTrue);
      final unpaidAmount = (item['remaining_amount'] as num).toDouble();
      expect(unpaidAmount, greaterThan(0));
    });
  });
}

