import { supabase } from "./supabaseClient";
import { AgencyMaintenanceRequest, AgencyRentPayment } from "../app/agency-panel/types";

/**
 * Filter maintenance requests that are eligible for settlement in the payment plan,
 * matching Flutter property_detail_screen.dart:10607 (maintenanceSettlements).
 */
export function getEligibleMaintenanceSettlements(
  maintenanceRequests: AgencyMaintenanceRequest[],
  propertyId: string
): AgencyMaintenanceRequest[] {
  return maintenanceRequests.filter((r) => {
    if (r.property_id !== propertyId) return false;
    if (!r.cost_amount || r.cost_amount <= 0) return false;

    // Remaining active cost
    const settled = r.settled_amount || 0;
    const remaining = r.cost_amount - settled;
    if (remaining <= 0) return false;

    // Must be in active settlement status (not already paid or rejected)
    const isValidStatus =
      r.payment_status === "pending_payment" ||
      r.payment_status === "pending_review" ||
      r.payment_status === "pending_agency_approval" ||
      r.payment_status === "pending_opposite_approval";

    return isValidStatus;
  });
}

/**
 * Filter pending rent/bill payments that can be used to offset a maintenance expense,
 * matching Flutter property_detail_screen.dart:8549 (eligiblePayments).
 */
export function getEligibleRentPaymentsForOffset(
  allPayments: AgencyRentPayment[],
  propertyId: string,
  requestCurrency?: string | null,
  propertyCurrency: string = "EUR"
): AgencyRentPayment[] {
  const reqCurrency = (requestCurrency || propertyCurrency || "EUR").toUpperCase();

  return allPayments.filter((p) => {
    if (p.property_id !== propertyId) return false;
    if (p.status === "paid" || p.status === "declared") return false;
    if (p.paid_at) return false;
    if (p.amount <= 0) return false;

    const pCur = (p.currency || propertyCurrency || "EUR").toUpperCase();
    return p.status === "pending" && pCur === reqCurrency;
  });
}

export interface ExecuteRentOffsetParams {
  request: AgencyMaintenanceRequest;
  payment: AgencyRentPayment;
  offsetAmount: number;
  propertyId: string;
  actorId?: string | null;
  actorName?: string | null;
  isDemoMode?: boolean;
  t: (key: string, params?: Record<string, any>) => string;
}

export interface ExecuteRentOffsetResult {
  success: boolean;
  paymentNewAmount: number;
  remainingCredit: number;
  isFullySettled: boolean;
  updatedPayment: AgencyRentPayment;
  updatedRequest: AgencyMaintenanceRequest;
  error?: string;
}

/**
 * Execute deduction of a maintenance expense from an upcoming rent payment,
 * matching Flutter property_detail_screen.dart:9079 (_applyRentOffset) 1:1.
 */
export async function executeRentOffset({
  request,
  payment,
  offsetAmount,
  propertyId,
  actorId,
  actorName,
  isDemoMode,
  t,
}: ExecuteRentOffsetParams): Promise<ExecuteRentOffsetResult> {
  const currentCost = request.cost_amount || 0;
  const currentSettled = request.settled_amount || 0;
  const activeRemaining = Math.max(0, currentCost - currentSettled);

  // Distinguish between Deduct from Rent (tenant paid for landlord repairs) vs Add to Rent (landlord/agency paid for tenant damage)
  const isAddToRent =
    request.paid_by === "landlord" ||
    (request.paid_by === "agency" && request.declaration_intent === "damage_tenant");

  const effectiveOffset = isAddToRent
    ? activeRemaining
    : Math.min(offsetAmount, activeRemaining, payment.amount);

  const paymentNewAmount = isAddToRent
    ? payment.amount + effectiveOffset
    : Math.max(0, payment.amount - effectiveOffset);

  const remainingCredit = Math.max(0, activeRemaining - effectiveOffset);
  const isFullySettled = remainingCredit <= 0;
  const newSettledAmount = currentSettled + effectiveOffset;

  const nowIso = new Date().toISOString();
  const cur = payment.currency || request.currency || "EUR";
  const formattedOffset = `${effectiveOffset.toFixed(2)} ${cur}`;
  const newNoteEntry = isAddToRent
    ? t("maintenanceAddedToRentNote", {
        ticket: request.ticket_number,
        amount: formattedOffset,
        title: request.title,
      })
    : t("maintenanceOffsetFromRentNote", {
        amount: formattedOffset,
        title: request.title,
      });
  const note = payment.owner_note
    ? `${payment.owner_note} • ${newNoteEntry}`
    : newNoteEntry;

  try {
    if (!isDemoMode) {
      // 1. Update rent payment in Supabase
      if (!isAddToRent && paymentNewAmount <= 0) {
        // Fully paid via offset
        await supabase
          .from("rent_payments")
          .update({
            status: "paid",
            paid_at: nowIso,
            owner_note: note,
            updated_at: nowIso,
          })
          .eq("id", payment.id);
      } else {
        // Partially paid (deduction) or Increased amount (addition)
        await supabase
          .from("rent_payments")
          .update({
            amount: paymentNewAmount,
            owner_note: note,
            updated_at: nowIso,
          })
          .eq("id", payment.id);
      }

      // 2. Update maintenance request in Supabase
      await supabase
        .from("maintenance_requests")
        .update({
          settled_amount: isFullySettled ? currentCost : newSettledAmount,
          payment_status: isFullySettled ? "paid" : "pending_payment",
          payment_date: nowIso,
          updated_at: nowIso,
        })
        .eq("id", request.id);

      // 3. Update maintenance_charges in Supabase (if existing)
      try {
        const { data: charges } = await supabase
          .from("maintenance_charges")
          .select("*")
          .eq("maintenance_request_id", request.id);

        if (charges && charges.length > 0) {
          const charge = charges[0];
          const newChargeSettled = (charge.settled_amount || 0) + effectiveOffset;
          await supabase
            .from("maintenance_charges")
            .update({
              settled_amount: isFullySettled ? charge.amount : newChargeSettled,
              status: isFullySettled ? "paid" : "approved",
              settlement_method: "rent_offset",
              updated_at: nowIso,
            })
            .eq("id", charge.id);
        }
      } catch (cErr) {
        console.warn("Charge sync warning:", cErr);
      }

      // 4. Insert message in maintenance discussion
      let activeUserId = actorId;
      if (!activeUserId) {
        const { data: authData } = await supabase.auth.getUser();
        activeUserId = authData?.user?.id || null;
      }

      const paymentMonthStr = payment.due_date ? payment.due_date.slice(0, 7) : "";
      const targetTitle = `${payment.title || t("agency_chip_rent")} (${paymentMonthStr})`;
      const remainingMsg =
        remainingCredit > 0
          ? ` (${remainingCredit.toFixed(2)} ${cur})`
          : ` (${t("agency_maint_status_paid")})`;

      const chatMsg = isAddToRent
        ? t("maintenanceAddActivityMsg", {
            amount: formattedOffset,
            paymentTitle: targetTitle,
            newAmount: `${paymentNewAmount.toFixed(2)} ${cur}`,
          })
        : t("maintenanceOffsetActivityMsg", {
            amount: formattedOffset,
            paymentTitle: targetTitle,
          }) + remainingMsg;

      await supabase.from("maintenance_messages").insert({
        request_id: request.id,
        sender_id: activeUserId,
        user_id: activeUserId,
        message: chatMsg,
        photo_url: request.invoice_pdf_url,
      });

      // 5. Insert activity log
      await supabase.from("activity_logs").insert({
        property_id: propertyId,
        user_id: activeUserId,
        action_type: isAddToRent ? "maintenance_add_to_rent" : "maintenance_offset",
        entity_type: "maintenance_request",
        entity_id: request.id,
        metadata: {
          offset_amount: effectiveOffset,
          is_add_to_rent: isAddToRent,
          payment_id: payment.id,
          payment_title: payment.title,
          payment_new_amount: paymentNewAmount,
          remaining_credit: remainingCredit,
          is_fully_settled: isFullySettled,
          ticket_number: request.ticket_number,
        },
        created_at: nowIso,
      });
    }

    const updatedPayment: AgencyRentPayment = {
      ...payment,
      amount: paymentNewAmount,
      status: !isAddToRent && paymentNewAmount <= 0 ? "paid" : payment.status,
      paid_at: !isAddToRent && paymentNewAmount <= 0 ? nowIso : payment.paid_at,
      owner_note: note,
    };

    const updatedRequest: AgencyMaintenanceRequest = {
      ...request,
      settled_amount: isFullySettled ? currentCost : newSettledAmount,
      payment_status: isFullySettled ? "paid" : "pending_payment",
      payment_date: nowIso,
    };

    return {
      success: true,
      paymentNewAmount,
      remainingCredit,
      isFullySettled,
      updatedPayment,
      updatedRequest,
    };
  } catch (err: any) {
    console.error("executeRentOffset error:", err);
    return {
      success: false,
      paymentNewAmount: payment.amount,
      remainingCredit: activeRemaining,
      isFullySettled: false,
      updatedPayment: payment,
      updatedRequest: request,
      error: err.message || "Offset execution failed",
    };
  }
}

/**
 * Filter counterparty maintenance requests eligible for cross-offset,
 * matching Flutter property_detail_screen.dart:8557 (eligibleCounterpartyMaintenance).
 */
export function getEligibleCounterpartyMaintenance(
  allRequests: AgencyMaintenanceRequest[],
  currentReq: AgencyMaintenanceRequest,
  propertyId: string,
  propertyCurrency: string = "EUR"
): AgencyMaintenanceRequest[] {
  const isAddToRent =
    currentReq.paid_by === "landlord" ||
    (currentReq.paid_by === "agency" && currentReq.declaration_intent === "damage_tenant");
  const reqCurrency = (currentReq.currency || propertyCurrency || "EUR").toUpperCase();

  return allRequests.filter((m) => {
    if (m.id === currentReq.id) return false;
    if (m.property_id !== propertyId) return false;
    if (m.payment_status === "paid" || m.payment_status === "rejected") return false;

    const mCost = m.cost_amount || 0;
    const mSettled = m.settled_amount || 0;
    const mRemaining = Math.max(0, mCost - mSettled);
    if (mRemaining <= 0) return false;

    const mCurrency = (m.currency || propertyCurrency || "EUR").toUpperCase();
    if (mCurrency !== reqCurrency) return false;
    if (m.payment_status !== "pending_payment") return false;

    // Opposite responsibility
    return isAddToRent ? m.paid_by === "tenant" : m.paid_by === "landlord";
  });
}

export interface ExecuteMaintenanceDebtOffsetParams {
  creditReq: AgencyMaintenanceRequest;
  debtReq: AgencyMaintenanceRequest;
  propertyId: string;
  actorId?: string | null;
  isDemoMode?: boolean;
  t: (key: string, params?: Record<string, any>) => string;
}

export interface ExecuteMaintenanceDebtOffsetResult {
  success: boolean;
  offsetAmount: number;
  creditRemaining: number;
  debtRemaining: number;
  updatedCreditReq: AgencyMaintenanceRequest;
  updatedDebtReq: AgencyMaintenanceRequest;
  error?: string;
}

/**
 * Cross-offset between two counterparty maintenance requests,
 * matching Flutter property_detail_screen.dart:9222 (_applyMaintenanceDebtOffset).
 */
export async function executeMaintenanceDebtOffset({
  creditReq,
  debtReq,
  propertyId,
  actorId,
  isDemoMode,
  t,
}: ExecuteMaintenanceDebtOffsetParams): Promise<ExecuteMaintenanceDebtOffsetResult> {
  const creditCost = creditReq.cost_amount || 0;
  const creditSettled = creditReq.settled_amount || 0;
  const creditAvail = Math.max(0, creditCost - creditSettled);

  const debtCost = debtReq.cost_amount || 0;
  const debtSettled = debtReq.settled_amount || 0;
  const debtAvail = Math.max(0, debtCost - debtSettled);

  const offsetAmount = Math.min(creditAvail, debtAvail);
  const creditRemaining = Math.max(0, creditAvail - offsetAmount);
  const debtRemaining = Math.max(0, debtAvail - offsetAmount);

  const isCreditFullySettled = creditRemaining <= 0;
  const isDebtFullySettled = debtRemaining <= 0;

  const nowIso = new Date().toISOString();
  const cur = creditReq.currency || debtReq.currency || "EUR";
  const formattedOffset = `${offsetAmount.toFixed(2)} ${cur}`;

  try {
    if (!isDemoMode) {
      // 1. Update debtReq in Supabase
      const newDebtSettled = debtSettled + offsetAmount;
      await supabase
        .from("maintenance_requests")
        .update({
          settled_amount: isDebtFullySettled ? debtCost : newDebtSettled,
          payment_status: isDebtFullySettled ? "paid" : "pending_payment",
          payment_date: nowIso,
          updated_at: nowIso,
        })
        .eq("id", debtReq.id);

      // 2. Update creditReq in Supabase
      const newCreditSettled = creditSettled + offsetAmount;
      await supabase
        .from("maintenance_requests")
        .update({
          settled_amount: isCreditFullySettled ? creditCost : newCreditSettled,
          payment_status: isCreditFullySettled ? "paid" : "pending_payment",
          payment_date: nowIso,
          updated_at: nowIso,
        })
        .eq("id", creditReq.id);

      // Sync charges
      try {
        await supabase
          .from("maintenance_charges")
          .update({
            settled_amount: isDebtFullySettled ? debtCost : newDebtSettled,
            status: isDebtFullySettled ? "paid" : "approved",
            settlement_method: "cross_maintenance_offset",
            updated_at: nowIso,
          })
          .eq("maintenance_request_id", debtReq.id);

        await supabase
          .from("maintenance_charges")
          .update({
            settled_amount: isCreditFullySettled ? creditCost : newCreditSettled,
            status: isCreditFullySettled ? "paid" : "approved",
            settlement_method: "cross_maintenance_offset",
            updated_at: nowIso,
          })
          .eq("maintenance_request_id", creditReq.id);
      } catch (cErr) {
        console.warn("Charges sync warning:", cErr);
      }

      // Messages in discussions
      let activeUserId = actorId;
      if (!activeUserId) {
        const { data: authData } = await supabase.auth.getUser();
        activeUserId = authData?.user?.id || null;
      }

      const debtRemMsg = debtRemaining > 0 ? ` (${debtRemaining.toFixed(2)} ${cur})` : " (Tamamen kapatıldı)";
      await supabase.from("maintenance_messages").insert({
        request_id: debtReq.id,
        sender_id: activeUserId,
        user_id: activeUserId,
        message: t("maintCrossOffsetActivityDebt", {
          amount: formattedOffset,
          title: creditReq.title,
          rem: debtRemMsg,
        }),
      });

      const creditRemMsg = creditRemaining > 0 ? ` (${creditRemaining.toFixed(2)} ${cur})` : " (Mahsuplaşma tamamlandı)";
      await supabase.from("maintenance_messages").insert({
        request_id: creditReq.id,
        sender_id: activeUserId,
        user_id: activeUserId,
        message: t("maintCrossOffsetActivityCredit", {
          amount: formattedOffset,
          title: debtReq.title,
          rem: creditRemMsg,
        }),
      });

      // Activity log
      await supabase.from("activity_logs").insert({
        property_id: propertyId,
        user_id: activeUserId,
        action_type: "maintenance_cross_offset",
        entity_type: "maintenance_request",
        entity_id: creditReq.id,
        metadata: {
          credit_req_id: creditReq.id,
          debt_req_id: debtReq.id,
          offset_amount: offsetAmount,
          credit_remaining: creditRemaining,
          debt_remaining: debtRemaining,
        },
        created_at: nowIso,
      });
    }

    const updatedCreditReq: AgencyMaintenanceRequest = {
      ...creditReq,
      settled_amount: isCreditFullySettled ? creditCost : creditSettled + offsetAmount,
      payment_status: isCreditFullySettled ? "paid" : "pending_payment",
      payment_date: nowIso,
    };

    const updatedDebtReq: AgencyMaintenanceRequest = {
      ...debtReq,
      settled_amount: isDebtFullySettled ? debtCost : debtSettled + offsetAmount,
      payment_status: isDebtFullySettled ? "paid" : "pending_payment",
      payment_date: nowIso,
    };

    return {
      success: true,
      offsetAmount,
      creditRemaining,
      debtRemaining,
      updatedCreditReq,
      updatedDebtReq,
    };
  } catch (err: any) {
    console.error("executeMaintenanceDebtOffset error:", err);
    return {
      success: false,
      offsetAmount: 0,
      creditRemaining: creditAvail,
      debtRemaining: debtAvail,
      updatedCreditReq: creditReq,
      updatedDebtReq: debtReq,
      error: err.message || "Cross offset failed",
    };
  }
}
