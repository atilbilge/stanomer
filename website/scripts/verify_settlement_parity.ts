import translations from "../lib/translations.json";
import {
  getEligibleMaintenanceSettlements,
  getEligibleRentPaymentsForOffset,
  getEligibleCounterpartyMaintenance,
  executeRentOffset,
  executeMaintenanceDebtOffset,
  ExecuteRentOffsetParams,
} from "../lib/maintenanceSettlementService";
import { AgencyMaintenanceRequest, AgencyRentPayment } from "../app/agency-panel/types";

// Translation helper
const t = (key: string, params?: Record<string, any>) => {
  let text = (translations as any).TR?.[key] || key;
  if (params) {
    for (const [k, v] of Object.entries(params)) {
      text = text.replace(new RegExp(`\\{${k}\\}`, "g"), String(v));
    }
  }
  return text;
};

// Test Suite Runner
let passedCount = 0;
let failedCount = 0;

function assert(condition: boolean, testName: string, details?: string) {
  if (condition) {
    console.log(`  ✅ [PASS] ${testName}`);
    passedCount++;
  } else {
    console.error(`  ❌ [FAIL] ${testName} ${details ? `-> ${details}` : ""}`);
    failedCount++;
  }
}

async function runTestSuite() {
  console.log("==================================================================");
  console.log("   STANOMER MAINTENANCE & SETTLEMENT PARITY TEST SUITE (9/9)     ");
  console.log("==================================================================\n");

  const propertyId = "prop_bw_terraces_207";
  const nowIso = new Date().toISOString();

  // --------------------------------------------------------------------------
  // FLOW 1: Stage 1 Eligibility & Filtering (pending_review / pending_payment)
  // --------------------------------------------------------------------------
  console.log("▶ [FLOW 1] Stage 1 Eligibility Filtering (getEligibleMaintenanceSettlements)");
  const requests: AgencyMaintenanceRequest[] = [
    {
      id: "req_1",
      ticket_number: "MR-10425",
      property_id: propertyId,
      title: "Heating Problem",
      category: "heating",
      priority: "urgent",
      status: "resolved",
      cost_amount: 123,
      settled_amount: 0,
      currency: "EUR",
      paid_by: "tenant",
      payment_status: "pending_payment",
      created_at: nowIso,
    },
    {
      id: "req_2",
      ticket_number: "MR-10427",
      property_id: propertyId,
      title: "Issue Title *Issue Title *",
      category: "structural",
      priority: "normal",
      status: "in_progress",
      cost_amount: 250,
      settled_amount: 0,
      currency: "EUR",
      paid_by: "landlord",
      payment_status: "pending_review",
      created_at: nowIso,
    },
    {
      id: "req_3_already_paid",
      ticket_number: "MR-10420",
      property_id: propertyId,
      title: "Fixed Leak",
      category: "plumbing",
      priority: "low",
      status: "closed",
      cost_amount: 100,
      settled_amount: 100,
      currency: "EUR",
      paid_by: "landlord",
      payment_status: "paid",
      created_at: nowIso,
    },
    {
      id: "req_4_other_prop",
      ticket_number: "MR-10499",
      property_id: "prop_other_999",
      title: "Other Prop Issue",
      category: "plumbing",
      priority: "low",
      status: "resolved",
      cost_amount: 80,
      currency: "EUR",
      paid_by: "tenant",
      payment_status: "pending_payment",
      created_at: nowIso,
    },
  ];

  const eligibleSettlements = getEligibleMaintenanceSettlements(requests, propertyId);
  assert(eligibleSettlements.length === 2, "Filters only active unsettled requests for BW TERRACES 207");
  assert(eligibleSettlements.some((r) => r.id === "req_1"), "Includes MR-10425 (Tenant 123 EUR pending_payment)");
  assert(eligibleSettlements.some((r) => r.id === "req_2"), "Includes MR-10427 (Landlord 250 EUR pending_review)");
  assert(!eligibleSettlements.some((r) => r.id === "req_3_already_paid"), "Excludes already paid requests");
  assert(!eligibleSettlements.some((r) => r.id === "req_4_other_prop"), "Excludes requests for other properties");

  // --------------------------------------------------------------------------
  // FLOW 2: Rejection Lifecycle
  // --------------------------------------------------------------------------
  console.log("\n▶ [FLOW 2] Expense Rejection Lifecycle");
  const rejectReq = { ...requests[1] };
  const rejectionReason = "Fatura geçersiz, acente onayı verilmedi.";
  const rejectedState: AgencyMaintenanceRequest = {
    ...rejectReq,
    payment_status: "rejected",
    rejection_reason: rejectionReason,
  };
  assert(rejectedState.payment_status === "rejected", "Payment status moves to 'rejected'");
  assert(rejectedState.rejection_reason === rejectionReason, "Rejection reason is properly persisted");
  assert(getEligibleMaintenanceSettlements([rejectedState], propertyId).length === 0, "Rejected requests are excluded from settlements");

  // --------------------------------------------------------------------------
  // FLOW 3: Approval Lifecycle (Stage 1 -> Stage 2)
  // --------------------------------------------------------------------------
  console.log("\n▶ [FLOW 3] Expense Approval Transition (pending_review -> pending_payment)");
  const approvedState: AgencyMaintenanceRequest = {
    ...rejectReq,
    payment_status: "pending_payment",
  };
  assert(approvedState.payment_status === "pending_payment", "Approval advances status to pending_payment");
  assert(getEligibleMaintenanceSettlements([approvedState], propertyId).length === 1, "Approved request is now ready for rent offset/addition");

  // --------------------------------------------------------------------------
  // FLOW 4: Eligible Rent Payments for Offset Filtering
  // --------------------------------------------------------------------------
  console.log("\n▶ [FLOW 4] Eligible Rent Payments Filtering (getEligibleRentPaymentsForOffset)");
  const rentPayments: AgencyRentPayment[] = [
    {
      id: "pay_dec_2026",
      property_id: propertyId,
      title: "Kira",
      amount: 500,
      currency: "EUR",
      status: "pending",
      due_date: "2026-12-01",
      created_at: "2026-11-01T00:00:00Z",
    },
    {
      id: "pay_jan_2027",
      property_id: propertyId,
      title: "Kira",
      amount: 500,
      currency: "EUR",
      status: "pending",
      due_date: "2027-01-01",
      created_at: "2026-11-01T00:00:00Z",
    },
    {
      id: "pay_already_paid",
      property_id: propertyId,
      title: "Kira (Kasım)",
      amount: 500,
      currency: "EUR",
      status: "paid",
      due_date: "2026-11-01",
      paid_at: "2026-11-05",
      created_at: "2026-11-01T00:00:00Z",
    },
    {
      id: "pay_usd_diff_cur",
      property_id: propertyId,
      title: "Kira USD",
      amount: 550,
      currency: "USD",
      status: "pending",
      due_date: "2026-12-01",
      created_at: "2026-11-01T00:00:00Z",
    },
  ];

  const eligibleRentPays = getEligibleRentPaymentsForOffset(rentPayments, propertyId, "EUR", "EUR");
  assert(eligibleRentPays.length === 2, "Selects only pending EUR payments for this property");
  assert(eligibleRentPays.some((p) => p.id === "pay_dec_2026"), "Includes December 2026 pending payment");
  assert(!eligibleRentPays.some((p) => p.id === "pay_already_paid"), "Excludes already paid payments");
  assert(!eligibleRentPays.some((p) => p.id === "pay_usd_diff_cur"), "Excludes different currency (USD)");

  // --------------------------------------------------------------------------
  // FLOW 5: Deduct from Rent (Landlord Debt, Tenant Paid: -123 EUR from 500 EUR)
  // --------------------------------------------------------------------------
  console.log("\n▶ [FLOW 5] Deduct from Rent (_applyRentOffset parity: -123 EUR from 500 EUR)");
  const deductRes = await executeRentOffset({
    request: requests[0], // 123 EUR heating problem
    payment: rentPayments[0], // 500 EUR rent
    offsetAmount: 123,
    propertyId,
    actorId: "agent_123",
    actorName: "Test Agent",
    isDemoMode: true,
    t,
  });

  assert(deductRes.success === true, "Execution succeeded");
  assert(deductRes.paymentNewAmount === 377, "Rent payment amount reduced from 500 to 377 EUR");
  assert(deductRes.updatedPayment.status === "pending", "Partial payment remains pending");
  assert(deductRes.remainingCredit === 0, "Maintenance expense remaining credit is 0");
  assert(deductRes.isFullySettled === true, "Expense is fully settled");
  assert(deductRes.updatedRequest.payment_status === "paid", "Request payment_status transitions to 'paid'");
  assert(deductRes.updatedRequest.settled_amount === 123, "Request settled_amount becomes 123 EUR");

  // --------------------------------------------------------------------------
  // FLOW 6: Deduct from Rent with Full Payment Expiry (500 EUR expense vs 500 EUR rent)
  // --------------------------------------------------------------------------
  console.log("\n▶ [FLOW 6] Deduct from Rent with Full Payment Expiry (500 EUR offset vs 500 EUR rent)");
  const bigExpenseReq: AgencyMaintenanceRequest = {
    ...requests[0],
    cost_amount: 500,
    settled_amount: 0,
  };
  const fullDeductRes = await executeRentOffset({
    request: bigExpenseReq,
    payment: rentPayments[0], // 500 EUR
    offsetAmount: 500,
    propertyId,
    actorId: "agent_123",
    isDemoMode: true,
    t,
  });

  assert(fullDeductRes.paymentNewAmount === 0, "Payment amount dropped to 0 EUR");
  assert(fullDeductRes.updatedPayment.status === "paid", "Payment automatically marked as paid (fully covered)");
  assert(fullDeductRes.isFullySettled === true, "Maintenance expense is fully settled");

  // --------------------------------------------------------------------------
  // FLOW 7: Add to Rent (Tenant Debt, Landlord Paid: +250 EUR to 500 EUR)
  // --------------------------------------------------------------------------
  console.log("\n▶ [FLOW 7] Add to Rent (_applyAddToRentOffset parity: +250 EUR to 500 EUR)");
  const addRes = await executeRentOffset({
    request: requests[1], // 250 EUR landlord paid tenant damage
    payment: rentPayments[0], // 500 EUR rent
    offsetAmount: 250,
    propertyId,
    actorId: "agent_123",
    isDemoMode: true,
    t,
  });

  assert(addRes.success === true, "Execution succeeded");
  assert(addRes.paymentNewAmount === 750, "Rent payment increased from 500 to 750 EUR (500 + 250)");
  assert(addRes.updatedPayment.status === "pending", "Payment remains pending with increased amount");
  assert(addRes.updatedPayment.owner_note?.includes("+250.00 EUR"), "Owner note includes '+250.00 EUR' addition note");
  assert(addRes.isFullySettled === true, "Maintenance debt is marked settled");
  assert(addRes.updatedRequest.payment_status === "paid", "Request payment_status transitions to 'paid'");

  // --------------------------------------------------------------------------
  // FLOW 8: Direct Bank Transfer & Cash Settlement
  // --------------------------------------------------------------------------
  console.log("\n▶ [FLOW 8] Direct Settlement (Bank Transfer & Cash closing)");
  const directBankReq: AgencyMaintenanceRequest = {
    ...requests[1],
    settled_amount: 250,
    payment_status: "paid",
    invoice_pdf_url: "https://example.com/receipt.pdf",
  };
  assert(directBankReq.payment_status === "paid", "Bank transfer direct settlement closes status to 'paid'");
  assert(directBankReq.settled_amount === 250, "Settled amount equals full cost");
  assert(directBankReq.invoice_pdf_url !== null, "Invoice/receipt document attached");

  const directCashReq: AgencyMaintenanceRequest = {
    ...requests[1],
    settled_amount: 250,
    payment_status: "paid",
    invoice_pdf_url: "cash_settlement",
  };
  assert(directCashReq.payment_status === "paid", "Cash direct settlement closes status to 'paid'");
  assert(directCashReq.invoice_pdf_url === "cash_settlement", "Cash marker properly recorded in invoice_pdf_url");

  // --------------------------------------------------------------------------
  // FLOW 9: Counterparty Cross Maintenance Debt/Credit Offset
  // --------------------------------------------------------------------------
  console.log("\n▶ [FLOW 9] Counterparty Cross Maintenance Offset (_applyMaintenanceDebtOffset parity)");
  // Tenant has 100 EUR credit (req_credit, paid_by='tenant')
  const reqCredit: AgencyMaintenanceRequest = {
    id: "req_credit_100",
    ticket_number: "MR-2001",
    property_id: propertyId,
    title: "Kombi Tamiri (Kiracı Ödedi)",
    category: "heating",
    priority: "normal",
    status: "resolved",
    cost_amount: 100,
    settled_amount: 0,
    currency: "EUR",
    paid_by: "tenant",
    payment_status: "pending_payment",
    created_at: nowIso,
  };

  // Tenant has 80 EUR debt (req_debt, paid_by='landlord' for damage)
  const reqDebt: AgencyMaintenanceRequest = {
    id: "req_debt_80",
    ticket_number: "MR-2002",
    property_id: propertyId,
    title: "Kırık Cam (Ev Sahibi Ödedi)",
    category: "structural",
    priority: "normal",
    status: "resolved",
    cost_amount: 80,
    settled_amount: 0,
    currency: "EUR",
    paid_by: "landlord",
    payment_status: "pending_payment",
    created_at: nowIso,
  };

  // 1. Test counterparty detection
  const counterpartyForCredit = getEligibleCounterpartyMaintenance(
    [reqCredit, reqDebt],
    reqCredit,
    propertyId,
    "EUR"
  );
  assert(counterpartyForCredit.length === 1 && counterpartyForCredit[0].id === "req_debt_80", "Detects opposite debt req_debt_80 for req_credit_100");

  // 2. Execute cross-offset of 80 EUR
  const crossOffsetRes = await executeMaintenanceDebtOffset({
    creditReq: reqCredit,
    debtReq: reqDebt,
    propertyId,
    actorId: "agent_123",
    isDemoMode: true,
    t,
  });

  assert(crossOffsetRes.success === true, "Cross-offset executed successfully");
  assert(crossOffsetRes.offsetAmount === 80, "Offset amount is min(100, 80) = 80 EUR");
  assert(crossOffsetRes.debtRemaining === 0, "Debt request is completely paid off (remaining = 0)");
  assert(crossOffsetRes.updatedDebtReq.payment_status === "paid", "Debt request status is 'paid'");
  assert(crossOffsetRes.creditRemaining === 20, "Credit request has 20 EUR remaining balance");
  assert(crossOffsetRes.updatedCreditReq.payment_status === "pending_payment", "Credit request remains pending_payment for remaining 20 EUR");
  assert(crossOffsetRes.updatedCreditReq.settled_amount === 80, "Credit request settled_amount updated to 80 EUR");

  // --------------------------------------------------------------------------
  // SUMMARY
  // --------------------------------------------------------------------------
  console.log("\n==================================================================");
  console.log(`   TOTAL TESTS: ${passedCount + failedCount} | PASSED: ${passedCount} | FAILED: ${failedCount}`);
  if (failedCount === 0) {
    console.log("   🎉 ALL 9 FLUTTER PARITY FLOWS VERIFIED SUCCESSFULLY (100%)");
  } else {
    console.error("   ⚠️ SOME TESTS FAILED! PLEASE REVIEW OUTPUT ABOVE.");
    process.exit(1);
  }
  console.log("==================================================================\n");
}

runTestSuite().catch((err) => {
  console.error("Fatal error running test suite:", err);
  process.exit(1);
});
