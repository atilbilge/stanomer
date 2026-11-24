"use client";

import React, { useState, useEffect, useRef } from "react";
import {
  ChevronLeft,
  Wrench,
  AlertTriangle,
  CheckCircle2,
  Clock,
  User,
  Phone,
  MessageCircle,
  MapPin,
  FileText,
  UploadCloud,
  DollarSign,
  ArrowRight,
  Send,
  Image as ImageIcon,
  Check,
  AlertCircle,
  Loader2,
  ExternalLink,
  ChevronRight,
  ShieldAlert,
  Building2,
  Calendar,
  X,
  Plus,
  Info,
  Zap,
  Search,
  RotateCcw,
} from "lucide-react";
import {
  AgencyMaintenanceRequest,
  AgencyManagedProperty,
  MaintenanceMessage,
  MaintenanceChargeItem,
} from "../types";
import { supabase } from "../../../lib/supabaseClient";
import {
  getMaintenanceCategoryMeta,
  MaintenanceCategoryBadge,
  getMaintenanceExpenseStatusLabel,
} from "../categoryAndPaymentIcons";

export interface MaintenanceDetailViewProps {
  request: AgencyMaintenanceRequest;
  property: AgencyManagedProperty | null;
  onBack: () => void;
  onUpdateRequest: (updated: AgencyMaintenanceRequest) => void;
  onNavigateToProperty?: (propertyId: string) => void;
  userId?: string | null;
  isDemoMode?: boolean;
  isDemoVerified?: boolean;
  onRequestVerification?: () => void;
  t: (key: string, params?: Record<string, any>) => string;
}

export function resolveDeclarationIntent(
  explicitIntent?: string | null,
  paidBy?: string | null,
  paymentStatus?: string | null
): string {
  if (explicitIntent) return explicitIntent;
  if (!paidBy) return "";
  if (paidBy === "tenant") {
    return paymentStatus === "paid" ? "self" : "reimburse";
  }
  if (paidBy === "landlord") {
    return paymentStatus === "paid" ? "self" : "tenant_due";
  }
  if (paidBy === "agency") {
    return "fixture_landlord";
  }
  return "";
}

export function getIntentTranslationKey(
  paidBy?: string | null,
  intent?: string | null
): string {
  if (!paidBy || !intent) return "";
  if (paidBy === "agency") {
    if (intent === "fixture_landlord") return "agency_maint_intent_agency_fixture";
    if (intent === "damage_tenant") return "agency_maint_intent_agency_damage";
  }
  return `agency_maint_intent_${paidBy}_${intent}`;
}

export default function MaintenanceDetailView({
  request,
  property,
  onBack,
  onUpdateRequest,
  onNavigateToProperty,
  userId = null,
  isDemoMode = false,
  isDemoVerified = false,
  onRequestVerification,
  t,
}: MaintenanceDetailViewProps) {
  // Status update
  const isLocalOnlyDemo = isDemoMode && (!userId || userId === "demo");
  const [updatingStatus, setUpdatingStatus] = useState(false);

  // Financial Form State
  const [isEditingFinancials, setIsEditingFinancials] = useState(false);
  const [costAmount, setCostAmount] = useState<string>("");
  const [currency, setCurrency] = useState<string>("EUR");
  const [paymentDate, setPaymentDate] = useState<string>(() => new Date().toISOString().split("T")[0]);
  const [paidBy, setPaidBy] = useState<"tenant" | "landlord" | "agency" | "">("");
  const [declarationIntent, setDeclarationIntent] = useState<string>("");
  const [financialNote, setFinancialNote] = useState<string>("");
  const [invoiceFile, setInvoiceFile] = useState<File | null>(null);
  const [savingFinancials, setSavingFinancials] = useState(false);
  const [financialError, setFinancialError] = useState<string | null>(null);

  // Approval / Rejection
  const [isRejecting, setIsRejecting] = useState(false);
  const [rejectionReason, setRejectionReason] = useState("");
  const [approving, setApproving] = useState(false);

  // Detail Tabs State: "messages" (with Overview pinned above) | "financials"
  const [activeDetailTab, setActiveDetailTab] = useState<"messages" | "financials">("messages");

  // Messages / Activity State
  const [messages, setMessages] = useState<MaintenanceMessage[]>([]);
  const [loadingMessages, setLoadingMessages] = useState(false);
  const [newMessageText, setNewMessageText] = useState("");
  const [messagePhotoFile, setMessagePhotoFile] = useState<File | null>(null);
  const [sendingMessage, setSendingMessage] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  // Charges
  const [charges, setCharges] = useState<MaintenanceChargeItem[]>([]);

  useEffect(() => {
    if (!request) return;

    setIsEditingFinancials(false);
    setIsRejecting(false);
    setFinancialError(null);

    // Init form from request
    setCostAmount(request.cost_amount ? request.cost_amount.toString() : "");
    setCurrency(request.currency || (property?.currency ? property.currency : "EUR"));
    setPaymentDate(request.payment_date ? request.payment_date.split("T")[0] : new Date().toISOString().split("T")[0]);
    const initPayer = request.paid_by || (request.cost_amount ? "tenant" : "");
    setPaidBy(initPayer);

    const initIntent = resolveDeclarationIntent(
      request.declaration_intent,
      initPayer,
      request.payment_status
    );
    setDeclarationIntent(initIntent);
    setFinancialNote("");
    setInvoiceFile(null);

    loadMessages(request.id);
    loadCharges(request.id);
  }, [request.id]);

  async function loadMessages(reqId: string) {
    setLoadingMessages(true);
    try {
      if (isLocalOnlyDemo) {
        setMessages([
          {
            id: "msg-demo-1",
            request_id: reqId,
            sender_id: "system",
            sender_name: "System",
            sender_role: "system",
            message: t("agency_maint_msg_ticket_created"),
            created_at: request.created_at || new Date().toISOString(),
          },
        ]);
        return;
      }

      const { data, error } = await supabase
        .from("maintenance_messages")
        .select("id, request_id, sender_id, message, photo_url, created_at")
        .eq("request_id", reqId)
        .order("created_at", { ascending: true });

      if (error) {
        console.warn("Could not load maintenance messages:", error);
        setMessages([]);
        return;
      }

      const senderIds = Array.from(new Set((data || []).map((m: any) => m.sender_id).filter(Boolean)));
      let senderMap = new Map<string, { full_name?: string; role?: string }>();
      if (senderIds.length > 0) {
        const { data: profs } = await supabase
          .from("profiles")
          .select("id, full_name, role")
          .in("id", senderIds);
        if (profs) {
          senderMap = new Map(profs.map((p: any) => [p.id, { full_name: p.full_name, role: p.role }]));
        }
      }

      const formatted: MaintenanceMessage[] = (data || []).map((m: any) => {
        const p = senderMap.get(m.sender_id);
        return {
          id: m.id,
          request_id: m.request_id,
          sender_id: m.sender_id,
          sender_name: p?.full_name || null,
          sender_role: p?.role || null,
          message: m.message,
          photo_url: m.photo_url,
          created_at: m.created_at,
        };
      });

      setMessages(formatted);
    } catch (e) {
      console.error("Error loading messages:", e);
      setMessages([]);
    } finally {
      setLoadingMessages(false);
    }
  }

  async function loadCharges(reqId: string) {
    try {
      if (isLocalOnlyDemo) return;
      const { data } = await supabase
        .from("maintenance_charges")
        .select("*")
        .eq("maintenance_request_id", reqId);
      if (data) {
        const typedCharges = data as MaintenanceChargeItem[];
        setCharges(typedCharges);
        if (typedCharges.length > 0 && request?.paid_by) {
          const ch = typedCharges[0];
          let inferred = "";
          if (request.paid_by === "agency") {
            inferred =
              ch.debtor_id && ch.debtor_id !== property?.landlord_id
                ? "damage_tenant"
                : "fixture_landlord";
          } else if (request.paid_by === "tenant") {
            inferred =
              ch.charge_type === "direct_charge" && ch.debtor_id === property?.tenant_id
                ? "self"
                : "reimburse";
          } else if (request.paid_by === "landlord") {
            inferred =
              ch.debtor_id && ch.debtor_id === property?.landlord_id
                ? "self"
                : "tenant_due";
          }
          if (inferred) setDeclarationIntent(inferred);
        }
      }
    } catch (_) { }
  }

  // Status Change
  async function handleStatusChange(newStatus: AgencyMaintenanceRequest["status"]) {
    if (isDemoMode && !isDemoVerified) {
      onRequestVerification?.();
      return;
    }
    if (!request) return;
    setUpdatingStatus(true);
    try {
      const nowIso = new Date().toISOString();
      const updates: any = {
        status: newStatus,
        updated_at: nowIso,
        resolved_at: newStatus === "resolved" ? nowIso : newStatus === "open" ? null : request.resolved_at,
      };

      if (!isLocalOnlyDemo) {
        const { error } = await supabase
          .from("maintenance_requests")
          .update(updates)
          .eq("id", request.id);
        if (error) throw error;

        let activeUserId = userId || property?.agency_id || property?.landlord_id || null;
        if (!activeUserId) {
          const { data: authData } = await supabase.auth.getUser();
          activeUserId = authData?.user?.id || null;
        }

        await supabase.from("maintenance_messages").insert({
          request_id: request.id,
          sender_id: activeUserId,
          user_id: activeUserId,
          message: t("agency_maint_msg_status_updated", {
            status: t("agency_maint_status_" + newStatus),
          }),
        });
      }

      const updatedReq = {
        ...request,
        ...updates,
      };
      onUpdateRequest(updatedReq);
    } catch (err) {
      console.error("Error updating status:", err);
    } finally {
      setUpdatingStatus(false);
    }
  }

  // Upload Invoice / Receipt Helper
  async function uploadInvoice(file: File, reqId: string, propId: string): Promise<string | null> {
    const ext = file.name.split(".").pop();
    const cleanFileName = `${propId}_${reqId}_${Date.now()}.${ext}`;
    const storagePath = `${userId || "agency"}/${cleanFileName}`;

    let { data, error } = await supabase.storage
      .from("invoices")
      .upload(storagePath, file, { upsert: true });

    if (error) {
      const fallback = await supabase.storage
        .from("maintenance")
        .upload(`receipts/${cleanFileName}`, file, { upsert: true });
      if (fallback.error) throw fallback.error;
      const publicUrlObj = supabase.storage
        .from("maintenance")
        .getPublicUrl(`receipts/${cleanFileName}`);
      return publicUrlObj.data?.publicUrl || null;
    }

    const { data: publicUrlData } = supabase.storage
      .from("invoices")
      .getPublicUrl(storagePath);

    return publicUrlData?.publicUrl || null;
  }

  // Save Financial Details
  async function handleSaveFinancials(e: React.FormEvent) {
    e.preventDefault();
    if (isDemoMode && !isDemoVerified) {
      onRequestVerification?.();
      return;
    }
    if (!request) return;

    const targetPropertyId = property?.id || request.property_id;

    const amountNum = parseFloat(costAmount);
    if (isNaN(amountNum) || amountNum <= 0) {
      setFinancialError(t("agency_maint_val_cost"));
      return;
    }

    if (!paidBy) {
      setFinancialError(t("agency_maint_val_payer"));
      return;
    }

    const effectiveIntent =
      declarationIntent ||
      resolveDeclarationIntent(null, paidBy, request.payment_status);

    if (!effectiveIntent) {
      setFinancialError(t("agency_maint_val_intent"));
      return;
    }

    setSavingFinancials(true);
    setFinancialError(null);

    try {
      let invoiceUrl = request.invoice_pdf_url || null;
      if (invoiceFile && !isLocalOnlyDemo && targetPropertyId) {
        invoiceUrl = await uploadInvoice(invoiceFile, request.id, targetPropertyId);
      }

      let targetPaymentStatus = "pending_payment";
      if (effectiveIntent === "self") {
        targetPaymentStatus = "paid";
      }

      const dbUpdates: any = {
        cost_amount: amountNum,
        currency: currency,
        paid_by: paidBy,
        payment_status: targetPaymentStatus,
        payment_date: paymentDate ? new Date(paymentDate).toISOString() : new Date().toISOString(),
        invoice_pdf_url: invoiceUrl,
        updated_at: new Date().toISOString(),
      };

      if (!isLocalOnlyDemo) {
        const { data: updatedRows, error: reqErr } = await supabase
          .from("maintenance_requests")
          .update(dbUpdates)
          .eq("id", request.id)
          .select("id");
        if (reqErr) throw reqErr;
        if (!updatedRows || updatedRows.length === 0) {
          throw new Error("Update blocked by permissions or record not found (0 rows updated).");
        }

        let resolvedLandlordId: string | null = property?.landlord_id || null;
        let resolvedTenantId: string | null = property?.tenant_id || null;
        if (targetPropertyId && (!resolvedLandlordId || !resolvedTenantId)) {
          const { data: freshProp } = await supabase
            .from("properties")
            .select("landlord_id, tenant_id")
            .eq("id", targetPropertyId)
            .maybeSingle();
          if (freshProp) {
            resolvedLandlordId = resolvedLandlordId || freshProp.landlord_id || null;
            resolvedTenantId = resolvedTenantId || freshProp.tenant_id || null;
          }
        }

        let chargeType: "direct_charge" | "agency_advance" | "reimbursement" = "direct_charge";
        let debtorId: string | null = resolvedTenantId || request.reporter_id || null;
        let creditorId: string | null = resolvedLandlordId;

        if (paidBy === "agency") {
          chargeType = "agency_advance";
          if (effectiveIntent === "fixture_landlord") {
            debtorId = resolvedLandlordId;
            creditorId = property?.agency_id || userId || null;
          } else {
            debtorId = resolvedTenantId || request.reporter_id || null;
            creditorId = property?.agency_id || userId || null;
          }
        } else if (paidBy === "tenant") {
          chargeType = effectiveIntent === "self" ? "direct_charge" : "reimbursement";
          debtorId = effectiveIntent === "self" ? (resolvedTenantId || request.reporter_id || null) : resolvedLandlordId;
          creditorId = resolvedTenantId || request.reporter_id || null;
        } else {
          chargeType = "direct_charge";
          debtorId = resolvedTenantId || request.reporter_id || null;
          creditorId = resolvedLandlordId;
        }

        const settlementMethod = effectiveIntent === "self" ? "separate_payment" : "rent_offset";
        const chargeStatus = targetPaymentStatus === "paid" ? "paid" : "approved";

        if (targetPropertyId) {
          const { data: existingCharges } = await supabase
            .from("maintenance_charges")
            .select("id")
            .eq("maintenance_request_id", request.id);

          if (existingCharges && existingCharges.length > 0) {
            const { error: chUpdErr } = await supabase
              .from("maintenance_charges")
              .update({
                title: request.title,
                charge_type: chargeType,
                approver_role: "agency",
                debtor_id: debtorId,
                creditor_id: creditorId,
                amount: amountNum,
                currency: currency,
                status: chargeStatus,
                settlement_method: settlementMethod,
                receipt_url: invoiceUrl,
                paid_at: targetPaymentStatus === "paid" ? new Date().toISOString() : null,
                updated_at: new Date().toISOString(),
              })
              .eq("id", existingCharges[0].id);
            if (chUpdErr) console.warn("maintenance_charges update warning:", chUpdErr);
          } else {
            const { error: chInsErr } = await supabase.from("maintenance_charges").insert({
              maintenance_request_id: request.id,
              property_id: targetPropertyId,
              created_by: userId || null,
              title: request.title,
              charge_type: chargeType,
              approver_role: "agency",
              debtor_id: debtorId,
              creditor_id: creditorId,
              amount: amountNum,
              currency: currency,
              status: chargeStatus,
              settlement_method: settlementMethod,
              receipt_url: invoiceUrl,
              paid_at: targetPaymentStatus === "paid" ? new Date().toISOString() : null,
            });
            if (chInsErr) console.warn("maintenance_charges insert warning:", chInsErr);
          }
        }

        let activeUserId = userId || property?.agency_id || property?.landlord_id || null;
        if (!activeUserId) {
          const { data: authData } = await supabase.auth.getUser();
          activeUserId = authData?.user?.id || null;
        }

        const noteText = financialNote.trim() ? `\n${t("agency_maint_note_label")}: "${financialNote.trim()}"` : "";
        const intentText = t(getIntentTranslationKey(paidBy, effectiveIntent));
        await supabase.from("maintenance_messages").insert({
          request_id: request.id,
          sender_id: activeUserId,
          user_id: activeUserId,
          message: `${t("agency_maint_payer_" + paidBy)}: ${amountNum.toFixed(2)} ${currency}\n${t("agency_maint_intent_label")}: ${intentText}\n(${t("agency_maint_status_" + targetPaymentStatus)})${noteText}`,
          photo_url: invoiceUrl,
        });
      }

      const updated: AgencyMaintenanceRequest = {
        ...request,
        ...dbUpdates,
        declaration_intent: effectiveIntent,
      };

      onUpdateRequest(updated);
      setIsEditingFinancials(false);
      loadCharges(request.id);
      loadMessages(request.id);
    } catch (err: any) {
      console.error("Error saving financials:", err);
      setFinancialError(err.message || t("agency_maint_save_error"));
    } finally {
      setSavingFinancials(false);
    }
  }

  // Agency Approves Expense (or marks an already-pending_payment debt as collected/paid)
  async function handleApproveExpense(forceMarkPaid = false) {
    if (isDemoMode && !isDemoVerified) {
      onRequestVerification?.();
      return;
    }
    if (!request) return;
    setApproving(true);
    try {
      const nowIso = new Date().toISOString();

      // Determine target payment_status (matching Flutter _handleApproveExpense 1:1):
      // - Direct "Mark as Collected / Paid" action (forceMarkPaid) -> "paid"
      // - Counterparty payment proof review on an already-approved debt -> "paid"
      // - Tenant/Landlord self-covered expense (no inter-party debt) -> "paid"
      // - Tenant fixture reimbursement or Landlord tenant-damage charge (creates inter-party debt) -> "pending_payment"
      const isPaymentProofConfirmation =
        request.payment_status === "pending_review" &&
        Boolean(request.invoice_pdf_url) &&
        (resolvedPayer === "agency" || resolvedPayer === "landlord");

      let nextPaymentStatus: "paid" | "pending_payment" = "paid";
      if (!forceMarkPaid && !isPaymentProofConfirmation) {
        if (resolvedPayer === "tenant") {
          nextPaymentStatus = resolvedIntent === "self" ? "paid" : "pending_payment";
        } else if (resolvedPayer === "landlord") {
          nextPaymentStatus = resolvedIntent === "self" ? "paid" : "pending_payment";
        } else if (resolvedPayer === "agency") {
          nextPaymentStatus = "paid";
        }
      }

      const updates: any = {
        payment_status: nextPaymentStatus,
        updated_at: nowIso,
      };
      if (nextPaymentStatus === "paid") {
        updates.settled_amount = request.cost_amount || 0;
        updates.payment_date = nowIso;
      }

      if (!isLocalOnlyDemo) {
        await supabase
          .from("maintenance_requests")
          .update(updates)
          .eq("id", request.id);

        await supabase
          .from("maintenance_charges")
          .update({
            status: nextPaymentStatus === "paid" ? "paid" : "approved",
            ...(nextPaymentStatus === "paid"
              ? { settled_amount: request.cost_amount || 0, paid_at: nowIso }
              : {}),
            approved_by: userId || null,
            approved_at: nowIso,
            updated_at: nowIso,
          })
          .eq("maintenance_request_id", request.id);

        let activeUserId = userId || property?.agency_id || property?.landlord_id || null;
        if (!activeUserId) {
          const { data: authData } = await supabase.auth.getUser();
          activeUserId = authData?.user?.id || null;
        }

        await supabase.from("maintenance_messages").insert({
          request_id: request.id,
          sender_id: activeUserId,
          user_id: activeUserId,
          message: `${t("agency_maint_msg_approved")}: ${request.cost_amount || 0} ${request.currency || "EUR"}`,
        });
      }

      const updated: AgencyMaintenanceRequest = {
        ...request,
        ...updates,
      };
      onUpdateRequest(updated);
      loadCharges(request.id);
      loadMessages(request.id);
    } catch (err) {
      console.error("Approve error:", err);
    } finally {
      setApproving(false);
    }
  }

  // Agency Rejects Expense
  async function handleRejectExpense() {
    if (isDemoMode && !isDemoVerified) {
      onRequestVerification?.();
      return;
    }
    if (!request || !rejectionReason.trim()) return;
    setApproving(true);
    try {
      const nowIso = new Date().toISOString();
      const isPaymentReceiptRejection =
        request.payment_status === "pending_review" &&
        Boolean(request.invoice_pdf_url) &&
        (resolvedPayer === "agency" || resolvedPayer === "landlord");

      const targetStatus = isPaymentReceiptRejection ? "pending_payment" : "rejected";
      const targetChargeStatus = isPaymentReceiptRejection ? "approved" : "rejected";

      const updates: any = {
        payment_status: targetStatus,
        rejection_reason: rejectionReason.trim(),
        ...(isPaymentReceiptRejection ? { invoice_pdf_url: null } : {}),
        updated_at: nowIso,
      };

      if (!isLocalOnlyDemo) {
        await supabase
          .from("maintenance_requests")
          .update(updates)
          .eq("id", request.id);

        await supabase
          .from("maintenance_charges")
          .update({
            status: targetChargeStatus,
            ...(isPaymentReceiptRejection ? { receipt_url: null } : {}),
            updated_at: nowIso,
          })
          .eq("maintenance_request_id", request.id);

        let activeUserId = userId || property?.agency_id || property?.landlord_id || null;
        if (!activeUserId) {
          const { data: authData } = await supabase.auth.getUser();
          activeUserId = authData?.user?.id || null;
        }

        await supabase.from("maintenance_messages").insert({
          request_id: request.id,
          sender_id: activeUserId,
          user_id: activeUserId,
          message: `${t("agency_maint_msg_rejected")}\n${t("agency_maint_rejection_reason_label")}: ${rejectionReason.trim()}`,
        });
      }

      const updated: AgencyMaintenanceRequest = {
        ...request,
        ...updates,
      };
      onUpdateRequest(updated);
      setIsRejecting(false);
      setRejectionReason("");
      loadCharges(request.id);
      loadMessages(request.id);
    } catch (err) {
      console.error("Reject error:", err);
    } finally {
      setApproving(false);
    }
  }

  // Send Chat Message
  async function handleSendMessage(e: React.FormEvent) {
    e.preventDefault();
    if (isDemoMode && !isDemoVerified) {
      onRequestVerification?.();
      return;
    }
    if (!request) return;
    if (!newMessageText.trim() && !messagePhotoFile) return;

    setSendingMessage(true);
    try {
      let photoUrl: string | null = null;
      if (messagePhotoFile && !isDemoMode) {
        const ext = messagePhotoFile.name.split(".").pop();
        const pPath = `chat_${request.id}_${Date.now()}.${ext}`;
        const { data: upData, error: upErr } = await supabase.storage
          .from("maintenance-photos")
          .upload(pPath, messagePhotoFile, { upsert: true });

        if (!upErr && upData) {
          const { data: pubData } = supabase.storage
            .from("maintenance-photos")
            .getPublicUrl(pPath);
          photoUrl = pubData?.publicUrl || null;
        }
      }

      const messageContent = newMessageText.trim();

      if (!isLocalOnlyDemo) {
        let activeUserId = userId || property?.agency_id || property?.landlord_id || null;
        if (!activeUserId) {
          const { data: authData } = await supabase.auth.getUser();
          activeUserId = authData?.user?.id || null;
        }

        const { error } = await supabase.from("maintenance_messages").insert({
          request_id: request.id,
          sender_id: activeUserId,
          user_id: activeUserId,
          message: messageContent,
          photo_url: photoUrl,
        });
        if (error) throw error;
        loadMessages(request.id);
      } else {
        const optimisticMsg: MaintenanceMessage = {
          id: `msg-${Date.now()}`,
          request_id: request.id,
          sender_id: userId || "me",
          sender_name: t("agency_maint_payer_agency"),
          sender_role: "agency",
          message: messageContent,
          photo_url: photoUrl,
          created_at: new Date().toISOString(),
        };
        setMessages((prev) => [...prev, optimisticMsg]);
      }

      setNewMessageText("");
      setMessagePhotoFile(null);
    } catch (err) {
      console.error("Send message error:", err);
    } finally {
      setSendingMessage(false);
    }
  }

  const isResolved = request.status === "resolved" || request.status === "closed";
  const isInProgress = request.status === "in_progress";
  const hasExpense = request.cost_amount !== null && request.cost_amount !== undefined && Number(request.cost_amount) > 0;
  const isPendingReview =
    hasExpense &&
    (request.payment_status === "pending_review" ||
      request.payment_status === "pending_agency_approval" ||
      request.payment_status === "pending_opposite_approval");

  const effectiveOriginalCost = Number(request.cost_amount) || 0;
  const effectiveSettledCost = Number(request.settled_amount) || 0;
  const effectiveRemainingCost = Math.max(0, effectiveOriginalCost - effectiveSettledCost);
  const hasPartial = effectiveSettledCost > 0 && effectiveRemainingCost > 0;
  const effectiveCurrency = request.currency || (property?.currency ? property.currency : "EUR");

  const displayedCostAmount =
    hasPartial && request.payment_status === "pending_payment"
      ? effectiveRemainingCost
      : effectiveOriginalCost;

  const resolvedPayer = request.paid_by || (request.cost_amount ? "tenant" : "");
  const effectiveChargeStatus = charges.length > 0 ? charges[0].status : request.charge_status;
  const effectiveChargeType = charges.length > 0 ? charges[0].charge_type : request.charge_type;
  const isPaymentProofReview =
    request.payment_status === "pending_review" &&
    Boolean(request.invoice_pdf_url) &&
    (resolvedPayer === "agency" || resolvedPayer === "landlord");
  const chargeDerivedIntent =
    charges.length > 0
      ? resolvedPayer === "agency"
        ? charges[0].debtor_id && charges[0].debtor_id !== property?.landlord_id
          ? "damage_tenant"
          : "fixture_landlord"
        : resolvedPayer === "tenant"
          ? charges[0].charge_type === "direct_charge" && charges[0].debtor_id === property?.tenant_id
            ? "self"
            : "reimburse"
          : resolvedPayer === "landlord"
            ? charges[0].debtor_id && charges[0].debtor_id === property?.landlord_id
              ? "self"
              : "tenant_due"
            : null
      : null;
  const resolvedIntent = resolveDeclarationIntent(
    chargeDerivedIntent || request.declaration_intent,
    resolvedPayer,
    request.payment_status
  );

  const formatEuropeanDate = (dStr?: string | null) => {
    if (!dStr) return "-";
    const parts = dStr.split("T")[0].split("-");
    if (parts.length === 3) {
      return `${parts[2]}.${parts[1]}.${parts[0]}`;
    }
    return dStr;
  };

  const getFinancialSummarySentence = () => {
    if (!hasExpense) {
      return t("agency_maint_summary_no_expense");
    }

    if (request.payment_status === "rejected") {
      return t("agency_maint_summary_rejected");
    }

    if (resolvedPayer === "tenant") {
      if (resolvedIntent === "reimburse") {
        if (request.payment_status === "paid") {
          return t("agency_maint_summary_tenant_reimburse_paid");
        }
        if (request.payment_status === "pending_payment") {
          return t("agency_maint_summary_tenant_reimburse_pending");
        }
        return t("agency_maint_summary_tenant_reimburse_review");
      }

      if (resolvedIntent === "self" || request.payment_status === "paid") {
        if (request.payment_status === "paid") {
          return t("agency_maint_summary_tenant_self_paid");
        }
        return t("agency_maint_summary_tenant_self_pending");
      }

      return t("agency_maint_summary_tenant_reimburse_pending");
    }

    if (resolvedPayer === "landlord") {
      if (resolvedIntent === "self") {
        if (request.payment_status === "paid") {
          return t("agency_maint_summary_landlord_self_paid");
        }
        return t("agency_maint_summary_landlord_self_pending");
      }

      if (resolvedIntent === "tenant_due") {
        if (request.payment_status === "paid") {
          return t("agency_maint_summary_landlord_tenant_due_paid");
        }
        if (isPaymentProofReview) {
          return t("agency_maint_summary_payment_review");
        }
        if (request.payment_status === "pending_payment") {
          return t("agency_maint_summary_landlord_tenant_due_approved");
        }
        return t("agency_maint_summary_landlord_tenant_due_pending");
      }

      if (request.payment_status === "paid") {
        return t("agency_maint_summary_landlord_self_paid");
      }
      return t("agency_maint_summary_landlord_self_pending");
    }

    if (resolvedPayer === "agency") {
      if (request.payment_status === "paid") {
        return t("agency_maint_summary_agency_paid");
      }
      if (isPaymentProofReview) {
        return t("agency_maint_summary_payment_review");
      }
      if (resolvedIntent === "damage_tenant") {
        return t("agency_maint_summary_agency_damage_pending");
      }
      return t("agency_maint_summary_agency_fixture_pending");
    }

    return t("agency_maint_summary_no_expense");
  };

  return (
    <div className="space-y-6 animate-in fade-in duration-200">
      {/* 1. Back Button & ID Bar */}
      <div className="flex items-center justify-between gap-4">
        <button
          type="button"
          onClick={onBack}
          className="inline-flex items-center gap-1.5 font-bold text-sm text-[#1B5888] hover:text-[#12406A] transition-colors cursor-pointer"
        >
          <ChevronLeft className="w-4 h-4" />
          <span>{t("agency_maint_btn_back_to_list")}</span>
        </button>

        <span className="text-xs text-slate-400 font-mono">
          #{request.ticket_number || request.id.slice(0, 8)}
        </span>
      </div>

      {/* 2. Main Header Card (matching Managed Properties Card Style) */}
      <div className="bg-white rounded-[10px] border border-slate-200/80 p-5 sm:p-6 shadow-xs space-y-4">
        <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
          <div className="flex items-center gap-4 min-w-0">
            {(() => {
              const catMeta = getMaintenanceCategoryMeta(request.category);
              const CatIcon = catMeta.icon;
              return (
                <div
                  className={`w-12 h-12 rounded-xl flex items-center justify-center shrink-0 shadow-xs ${catMeta.bgClass} ${catMeta.textClass} border ${catMeta.borderClass}`}
                >
                  <CatIcon className="w-6 h-6" />
                </div>
              );
            })()}
            <div className="min-w-0 space-y-1">
              <div className="flex items-center gap-2 flex-wrap">
                <span className="font-mono font-bold text-xs text-[#1B5888] bg-blue-50 border border-blue-200/60 px-2.5 py-0.5 rounded-full">
                  {request.ticket_number}
                </span>
                <MaintenanceCategoryBadge
                  category={request.category}
                  label={t("agency_maint_cat_" + request.category)}
                />
                <span
                  className={`inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-semibold ${request.priority === "urgent"
                    ? "bg-rose-50 text-rose-700 border border-rose-200"
                    : request.priority === "high"
                      ? "bg-amber-50 text-amber-700 border border-amber-200"
                      : "bg-slate-100 text-slate-700 border border-slate-200"
                    }`}
                >
                  <span
                    className={`w-1.5 h-1.5 rounded-full ${request.priority === "urgent"
                      ? "bg-rose-500"
                      : request.priority === "high"
                        ? "bg-amber-500"
                        : "bg-slate-400"
                      }`}
                  />
                  {t("agency_maint_priority_" + request.priority)}
                </span>
              </div>
              <h2 className="text-xl sm:text-2xl font-bold text-slate-900 tracking-tight truncate">
                {request.title}
              </h2>
              {onNavigateToProperty && (request.property_id || property?.id) ? (
                <button
                  type="button"
                  onClick={() => onNavigateToProperty(request.property_id || property!.id)}
                  className="text-xs sm:text-sm text-slate-500 hover:text-[#1B5888] transition-colors truncate flex items-center gap-1.5 group cursor-pointer text-left"
                  title={t("agency_maint_view_property_details")}
                >
                  <MapPin className="w-3.5 h-3.5 text-slate-400 group-hover:text-[#1B5888] shrink-0 transition-colors" />
                  <span className="font-semibold text-slate-700 group-hover:text-[#1B5888] group-hover:underline">
                    {request.property_title || property?.title || "Daire"}
                  </span>
                  {request.property_address && <span>• {request.property_address}</span>}
                  <ExternalLink className="w-3 h-3 text-slate-400 group-hover:text-[#1B5888] shrink-0 opacity-70 group-hover:opacity-100 transition-all ml-0.5" />
                </button>
              ) : (
                <p className="text-xs sm:text-sm text-slate-500 truncate flex items-center gap-1.5">
                  <MapPin className="w-3.5 h-3.5 text-slate-400 shrink-0" />
                  <span className="font-semibold text-slate-700">
                    {request.property_title || property?.title || "Daire"}
                  </span>
                  {request.property_address && <span>• {request.property_address}</span>}
                </p>
              )}
            </div>
          </div>

          {/* Status Dropdown on Header */}
          <div className="flex items-center gap-3 shrink-0">
            <div className="text-right">
              <span className="text-[11px] font-semibold text-slate-500 block">
                {t("agency_maint_col_status")}
              </span>
              <div className="flex items-center gap-2 mt-1">
                <select
                  value={request.status}
                  disabled={updatingStatus}
                  onChange={(e) => handleStatusChange(e.target.value as any)}
                  className="px-3.5 py-2 rounded-xl border border-slate-200 bg-slate-50 text-xs font-bold text-slate-800 focus:ring-2 focus:ring-blue-500/20 focus:outline-hidden cursor-pointer"
                >
                  <option value="open">{t("agency_maint_status_open")}</option>
                  <option value="investigating">{t("agency_maint_status_investigating")}</option>
                  <option value="in_progress">{t("agency_maint_status_in_progress")}</option>
                  <option value="resolved">{t("agency_maint_status_resolved")}</option>
                  <option value="closed">{t("agency_maint_status_closed")}</option>
                </select>
                {updatingStatus && <Loader2 className="w-4 h-4 animate-spin text-[#1B5888]" />}
              </div>
            </div>
          </div>
        </div>

        {/* Metadata Bar: Reporter & Dates */}
        <div className="pt-3 border-t border-slate-100 flex flex-wrap items-center justify-between gap-3 text-xs">
          {/* Reporter Info */}
          <div className="flex items-center gap-2.5 flex-wrap">
            <div className="flex items-center gap-1.5 text-slate-700">
              <User className="w-3.5 h-3.5 text-[#1B5888]" />
              <span className="text-slate-400">{t("agency_maint_reporter_label")}:</span>
              <span className="font-bold text-slate-900">
                {request.reporter_name || t("payerTenant")}
              </span>
            </div>

            {request.reporter_phone && (
              <>
                <span className="text-slate-300">•</span>
                <a
                  href={`tel:${request.reporter_phone}`}
                  className="inline-flex items-center gap-1 text-slate-600 hover:text-[#1B5888] font-mono hover:underline"
                >
                  <Phone className="w-3 h-3 text-slate-400" />
                  <span>{request.reporter_phone}</span>
                </a>
                <a
                  href={`https://wa.me/${request.reporter_phone.replace(/[^0-9]/g, "")}?text=${encodeURIComponent(
                    t("agency_maint_whatsapp_msg", { ticketNumber: request.ticket_number || "" })
                  )}`}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center gap-1 px-2 py-0.5 rounded-md text-[11px] font-bold text-emerald-800 bg-[#E6F3EA] border border-[#2A6E43]/20 hover:bg-emerald-100 transition-colors shadow-2xs"
                >
                  <MessageCircle className="w-3 h-3 text-[#2A6E43]" />
                  <span>WhatsApp</span>
                </a>
              </>
            )}
          </div>

          {/* Dates (Created, Updated, Resolved) */}
          <div className="flex items-center gap-3 text-xs text-slate-500 flex-wrap">
            <div className="flex items-center gap-1.5">
              <Calendar className="w-3.5 h-3.5 text-slate-400" />
              <span className="text-slate-400">{t("agency_maint_col_created")}:</span>
              <span className="font-medium text-slate-700">
                {formatEuropeanDate(request.created_at)}
              </span>
            </div>

            <span className="text-slate-300">•</span>

            <div className="flex items-center gap-1.5">
              <Clock className="w-3.5 h-3.5 text-slate-400" />
              <span className="text-slate-400">{t("agency_maint_col_updated")}:</span>
              <span className="font-medium text-slate-700">
                {formatEuropeanDate(request.updated_at)}
              </span>
            </div>

            {request.resolved_at && (
              <>
                <span className="text-slate-300">•</span>
                <div className="inline-flex items-center gap-1 px-2 py-0.5 rounded-md text-[11px] font-bold text-emerald-800 bg-emerald-50 border border-emerald-200">
                  <CheckCircle2 className="w-3 h-3 text-emerald-600" />
                  <span>{t("agency_maint_col_resolved")}:</span>
                  <span>{formatEuropeanDate(request.resolved_at)}</span>
                </div>
              </>
            )}
          </div>
        </div>
      </div>

      {/* 3. In-Place Detail Sections Grid: 2/3 Main + 1/3 Sidebar */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Left Column (2 Cols) */}
        <div className="lg:col-span-2 space-y-6">
          {/* Detail Tabs Navigation Bar */}
          <div className="flex items-center gap-1 sm:gap-2 border-b border-[#E5E3DF] overflow-x-auto no-scrollbar">
            <button
              type="button"
              role="tab"
              aria-selected={activeDetailTab === "messages"}
              onClick={() => setActiveDetailTab("messages")}
              className={`py-3 px-3 sm:px-4 text-xs font-bold border-b-2 transition-all flex items-center gap-2 cursor-pointer whitespace-nowrap -mb-px ${
                activeDetailTab === "messages"
                  ? "border-[#1B5888] text-[#1B5888]"
                  : "border-transparent text-[#666666] hover:text-[#1A1A1A] hover:border-slate-300"
              }`}
            >
              <MessageCircle className={`w-4 h-4 shrink-0 ${activeDetailTab === "messages" ? "text-[#1B5888]" : "text-[#8A8A8A]"}`} />
              <span>{t("agency_maint_drawer_tab_messages")}</span>
              <span
                className={`text-[11px] px-2 py-0.5 rounded-full font-bold tabular-nums shrink-0 ml-0.5 ${
                  activeDetailTab === "messages"
                    ? "bg-[#E5EEF6] text-[#1B5888]"
                    : "bg-slate-100 text-[#666666]"
                }`}
              >
                {messages.length}
              </span>
            </button>

            <button
              type="button"
              role="tab"
              aria-selected={activeDetailTab === "financials"}
              onClick={() => setActiveDetailTab("financials")}
              className={`py-3 px-3 sm:px-4 text-xs font-bold border-b-2 transition-all flex items-center gap-2 cursor-pointer whitespace-nowrap -mb-px ${
                activeDetailTab === "financials"
                  ? "border-[#1B5888] text-[#1B5888]"
                  : "border-transparent text-[#666666] hover:text-[#1A1A1A] hover:border-slate-300"
              }`}
            >
              <DollarSign className={`w-4 h-4 shrink-0 ${activeDetailTab === "financials" ? "text-[#1B5888]" : "text-[#8A8A8A]"}`} />
              <span>{t("agency_maint_drawer_tab_financials")}</span>
              {isPendingReview && (
                <span className="w-2 h-2 rounded-full bg-amber-500 animate-pulse" />
              )}
            </button>
          </div>

          {/* TAB 1: Messages & Activity Log (with Pinned Issue Details & Photos) */}
          {activeDetailTab === "messages" && (
            <div className="space-y-4 animate-in fade-in duration-150">
              {/* Pinned Issue Details & Photos Hero Card */}
              <div className="bg-white rounded-[10px] border border-slate-200/80 p-5 shadow-xs space-y-3.5">
                <div className="flex items-center justify-between">
                  <h3 className="text-xs font-bold text-slate-800 flex items-center gap-2">
                    <Wrench className="w-4 h-4 text-[#1B5888]" />
                    <span>{t("agency_maint_drawer_tab_overview")}</span>
                  </h3>
                  {request.photos_urls && request.photos_urls.length > 0 && (
                    <span className="text-[11px] font-semibold text-slate-500 flex items-center gap-1.5">
                      <ImageIcon className="w-3.5 h-3.5 text-slate-400" />
                      <span>
                        {request.photos_urls.length} {t("agency_maint_photos_heading").toLowerCase()}
                      </span>
                    </span>
                  )}
                </div>

                <div className="bg-slate-50 border border-slate-100 rounded-[8px] p-3.5 text-xs text-slate-700 leading-relaxed whitespace-pre-wrap">
                  {request.description || t("agency_maint_empty_desc")}
                </div>

                {/* Horizontal Photos Carousel */}
                {request.photos_urls && request.photos_urls.length > 0 && (
                  <div className="pt-1">
                    <div className="flex items-center gap-2.5 overflow-x-auto pb-1.5 scrollbar-thin">
                      {request.photos_urls.map((url, idx) => (
                        <a
                          key={idx}
                          href={url}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="group relative w-20 h-20 sm:w-24 sm:h-24 shrink-0 rounded-[8px] overflow-hidden border border-slate-200 bg-slate-100 block shadow-2xs hover:border-[#1B5888] transition-all cursor-pointer"
                        >
                          <img
                            src={url}
                            alt={`Photo ${idx + 1}`}
                            className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-200"
                          />
                          <div className="absolute inset-0 bg-black/0 group-hover:bg-black/30 flex items-center justify-center transition-colors">
                            <ExternalLink className="w-4 h-4 text-white opacity-0 group-hover:opacity-100 transition-opacity" />
                          </div>
                        </a>
                      ))}
                    </div>
                  </div>
                )}
              </div>

              {/* Activity & Messages Card */}
              <div className="bg-white rounded-[10px] border border-slate-200/80 p-5 sm:p-6 shadow-xs space-y-4">
                <h3 className="text-xs font-bold text-slate-800 flex items-center gap-2">
                  <MessageCircle className="w-4 h-4 text-[#1B5888]" />
                  <span>
                    {t("agency_maint_drawer_tab_messages")} ({messages.length})
                  </span>
                </h3>

                {/* Message Stream */}
                <div className="space-y-3 max-h-[380px] overflow-y-auto pr-1">
                  {loadingMessages ? (
                    <div className="p-8 text-center text-xs text-slate-500 flex items-center justify-center gap-2">
                      <Loader2 className="w-4 h-4 animate-spin" />
                      <span>{t("agency_panel_loading")}</span>
                    </div>
                  ) : messages.length === 0 ? (
                    <div className="p-8 text-center text-xs text-slate-400 bg-slate-50 rounded-xl">
                      {t("agency_maint_no_messages")}
                    </div>
                  ) : (
                    messages.map((m) => {
                      const isAgencySender = m.sender_role === "agency" || m.sender_id === userId;
                      const isSystemSender = m.sender_role === "system" || m.sender_id === "system";

                      if (isSystemSender) {
                        return (
                          <div key={m.id} className="text-center my-2">
                            <span className="inline-block px-3 py-1 rounded-full bg-slate-100 text-[11px] text-slate-600 font-medium">
                              {m.message}
                            </span>
                          </div>
                        );
                      }

                      return (
                        <div
                          key={m.id}
                          className={`flex flex-col ${isAgencySender ? "items-end" : "items-start"}`}
                        >
                          <div className="flex items-center gap-1.5 text-[10px] text-slate-500 mb-1 px-1">
                            <span className="font-bold text-slate-700">
                              {m.sender_name || (isAgencySender ? t("agency_maint_payer_agency") : t("payerTenant"))}
                            </span>
                            <span>•</span>
                            <span>{formatEuropeanDate(m.created_at)}</span>
                          </div>

                          <div
                            className={`p-3.5 rounded-[10px] max-w-[85%] text-xs shadow-2xs space-y-2 leading-relaxed ${isAgencySender
                              ? "bg-[#1B5888] text-white rounded-tr-none"
                              : "bg-slate-100 text-slate-800 rounded-tl-none border border-slate-200/60"
                              }`}
                          >
                            <p className="whitespace-pre-wrap">{m.message}</p>

                            {m.photo_url && (
                              <a
                                href={m.photo_url}
                                target="_blank"
                                rel="noopener noreferrer"
                                className="block rounded-lg overflow-hidden border border-white/20 max-w-[200px]"
                              >
                                <img
                                  src={m.photo_url}
                                  alt="Attachment"
                                  className="w-full h-auto object-cover hover:scale-105 transition-transform"
                                />
                              </a>
                            )}
                          </div>
                        </div>
                      );
                    })
                  )}
                  <div ref={messagesEndRef} />
                </div>

                {/* Quick Reply Form */}
                <form onSubmit={handleSendMessage} className="pt-3 border-t border-slate-100 flex items-center gap-2">
                  <label
                    className="p-2.5 rounded-xl border border-slate-200 text-slate-500 hover:text-[#1B5888] hover:bg-slate-50 cursor-pointer shrink-0 transition-colors"
                    title={t("agency_maint_btn_attach_photo")}
                  >
                    <input
                      type="file"
                      accept="image/*"
                      className="hidden"
                      onChange={(e) => {
                        if (e.target.files && e.target.files[0]) {
                          setMessagePhotoFile(e.target.files[0]);
                        }
                      }}
                    />
                    <ImageIcon className="w-4 h-4" />
                  </label>

                  <div className="flex-1 relative">
                    <input
                      type="text"
                      value={newMessageText}
                      onChange={(e) => setNewMessageText(e.target.value)}
                      placeholder={t("agency_maint_msg_input_placeholder")}
                      className="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 text-xs text-slate-800 focus:ring-2 focus:ring-blue-500/20 focus:border-[#1B5888]"
                    />
                    {messagePhotoFile && (
                      <div className="absolute right-2 top-1/2 -translate-y-1/2 flex items-center gap-1 px-2 py-0.5 rounded-md bg-blue-50 text-blue-700 text-[10px] font-bold">
                        <span className="truncate max-w-[90px]">{messagePhotoFile.name}</span>
                        <button type="button" onClick={() => setMessagePhotoFile(null)}>
                          <X className="w-3 h-3" />
                        </button>
                      </div>
                    )}
                  </div>

                  <button
                    type="submit"
                    disabled={sendingMessage || (!newMessageText.trim() && !messagePhotoFile)}
                    className="p-2.5 rounded-xl bg-[#1B5888] text-white hover:bg-blue-700 transition-colors shadow-xs cursor-pointer disabled:opacity-40 shrink-0"
                  >
                    {sendingMessage ? (
                      <Loader2 className="w-4 h-4 animate-spin" />
                    ) : (
                      <Send className="w-4 h-4" />
                    )}
                  </button>
                </form>
              </div>
            </div>
          )}

          {/* TAB 2: Financials & Settlement */}
          {activeDetailTab === "financials" && (
            <div className="space-y-4 animate-in fade-in duration-150">
              {/* Financials & Settlement Card */}
              <div className="bg-white rounded-[10px] border border-slate-200/80 p-5 sm:p-6 shadow-xs space-y-5">
                <div className="flex items-center justify-between pb-3 border-b border-slate-100">
                  <h3 className="text-xs font-bold text-slate-800 flex items-center gap-2">
                    <DollarSign className="w-4 h-4 text-[#1B5888]" />
                    <span>{t("agency_maint_drawer_tab_financials")}</span>
                  </h3>

                  {!isEditingFinancials && (
                    <button
                      type="button"
                      onClick={() => {
                        if (isDemoMode && !isDemoVerified) {
                          onRequestVerification?.();
                          return;
                        }
                        setIsEditingFinancials(true);
                      }}
                      className="px-3.5 py-1.5 rounded-xl border border-slate-300 text-xs font-bold text-slate-700 hover:bg-slate-50 transition-colors cursor-pointer bg-white"
                    >
                      {!hasExpense
                        ? t("agency_maint_btn_declare_expense")
                        : t("agency_maint_btn_edit_financials")}
                    </button>
                  )}
                </div>

                {/* Financial Overview Banner */}
                <div className="bg-slate-50/80 rounded-xl border border-slate-200/80 p-5 space-y-4">
                  <div className="flex items-start justify-between gap-4">
                    <div>
                      <span className="text-[11px] font-semibold text-slate-500 block">
                        {t("agency_maint_financial_heading")}
                      </span>
                      <div className="flex items-baseline gap-2 mt-1">
                        <span className="text-3xl font-extrabold font-mono text-slate-900">
                          {hasExpense ? `€${effectiveOriginalCost.toLocaleString()}` : "€0.00"}
                        </span>
                        <span className="text-xs font-semibold text-slate-500">
                          {effectiveCurrency}
                        </span>
                      </div>
                      {effectiveSettledCost > 0 && (
                        <div
                          className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-md text-[11px] font-semibold mt-2 border ${effectiveRemainingCost > 0
                            ? "bg-amber-500/10 border-amber-200/80 text-amber-800"
                            : "bg-emerald-500/10 border-emerald-200/80 text-emerald-800"
                            }`}
                        >
                          {effectiveRemainingCost > 0 ? (
                            <Info className="w-3.5 h-3.5 text-amber-600 shrink-0" />
                          ) : (
                            <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600 shrink-0" />
                          )}
                          <span>
                            {effectiveRemainingCost > 0
                              ? t("agency_maint_offset_and_remaining", {
                                offset: `${effectiveSettledCost.toLocaleString()} ${effectiveCurrency}`,
                                remaining: `${effectiveRemainingCost.toLocaleString()} ${effectiveCurrency}`,
                              })
                              : t("agency_maint_offset_fully_settled", {
                                offset: `${effectiveSettledCost.toLocaleString()} ${effectiveCurrency}`,
                              })}
                          </span>
                        </div>
                      )}
                    </div>

                    <span
                      className={`inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold border ${!hasExpense
                        ? "bg-slate-100 text-slate-600 border-slate-200"
                        : request.payment_status === "paid"
                          ? "bg-emerald-50 text-emerald-800 border-emerald-200"
                          : request.payment_status === "rejected"
                            ? "bg-rose-50 text-rose-800 border-rose-200"
                            : request.payment_status === "pending_payment"
                              ? "bg-blue-50 text-blue-800 border-blue-200"
                              : "bg-amber-50 text-amber-800 border-amber-200"
                        }`}
                    >
                      <span
                        className={`w-2 h-2 rounded-full ${!hasExpense
                          ? "bg-slate-400"
                          : request.payment_status === "paid"
                            ? "bg-emerald-500"
                            : request.payment_status === "rejected"
                              ? "bg-rose-500"
                              : request.payment_status === "pending_payment"
                                ? "bg-blue-500"
                                : "bg-amber-500"
                          }`}
                      />
                      {!hasExpense
                        ? t("agency_maint_status_no_expense")
                        : getMaintenanceExpenseStatusLabel(request.payment_status, t)}
                    </span>
                  </div>

                  {/* Financial Attributes Grid */}
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 pt-3 border-t border-slate-200/80">
                    <div>
                      <span className="text-[11px] text-slate-500 block">
                        {t("agency_maint_payer_label")}
                      </span>
                      <span className="text-xs font-bold text-slate-800">
                        {resolvedPayer ? t("agency_maint_payer_" + resolvedPayer) : "-"}
                      </span>
                    </div>

                    <div>
                      <span className="text-[11px] text-slate-500 block">
                        {t("agency_maint_intent_label")}
                      </span>
                      <span className="text-xs font-bold text-slate-800">
                        {resolvedIntent && resolvedPayer
                          ? t(getIntentTranslationKey(resolvedPayer, resolvedIntent))
                          : "-"}
                      </span>
                    </div>
                  </div>

                  {/* Attached Invoice / Receipt Link */}
                  {request.invoice_pdf_url && (
                    <div className="pt-3 border-t border-slate-200/80 flex items-center justify-between">
                      <div className="flex items-center gap-2 text-xs font-semibold text-slate-800">
                        <FileText className="w-4 h-4 text-[#1B5888]" />
                        <span>{t("agency_maint_invoice_doc_label")}</span>
                      </div>
                      <a
                        href={request.invoice_pdf_url}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-white border border-slate-200 text-xs font-bold text-[#1B5888] hover:bg-slate-50 transition-colors shadow-2xs"
                      >
                        <ExternalLink className="w-3.5 h-3.5" />
                        <span>{t("agency_maint_btn_view_invoice")}</span>
                      </a>
                    </div>
                  )}
                </div>

                {/* No expense declared prompt */}
                {!hasExpense && !isEditingFinancials && (
                  <div className="bg-slate-50/70 rounded-xl border border-dashed border-slate-300 p-6 text-center space-y-3">
                    <div className="w-10 h-10 rounded-full bg-slate-200/80 text-slate-600 flex items-center justify-center mx-auto">
                      <DollarSign className="w-5 h-5" />
                    </div>
                    <div className="space-y-1">
                      <h4 className="text-xs font-bold text-slate-800">
                        {t("agency_maint_no_expense_title")}
                      </h4>
                      <p className="text-[11px] text-slate-500 max-w-md mx-auto leading-relaxed">
                        {t("agency_maint_no_expense_desc")}
                      </p>
                    </div>
                    <button
                      type="button"
                      onClick={() => {
                        if (isDemoMode && !isDemoVerified) {
                          onRequestVerification?.();
                          return;
                        }
                        setIsEditingFinancials(true);
                      }}
                      className="inline-flex items-center gap-1.5 px-4 py-2 rounded-lg bg-[#1B5888] text-white text-xs font-bold hover:bg-blue-700 transition-colors shadow-2xs cursor-pointer"
                    >
                      <Plus className="w-3.5 h-3.5" />
                      <span>{t("agency_maint_btn_declare_expense")}</span>
                    </button>
                  </div>
                )}

                {/* Agency Direct Collection / Mark as Paid Bar (when pending_payment) */}
                {hasExpense && request.payment_status === "pending_payment" && !isEditingFinancials && (
                  <div className="bg-emerald-50/60 rounded-xl border border-emerald-200/80 p-4 space-y-3">
                    <div className="flex items-start gap-2.5">
                      <CheckCircle2 className="w-5 h-5 text-emerald-600 shrink-0 mt-0.5" />
                      <div>
                        <h4 className="text-xs font-bold text-emerald-900">
                          {t("agency_maint_collect_heading")}
                        </h4>
                        <p className="text-[11px] text-emerald-700 mt-0.5">
                          {t("agency_maint_collect_desc")}
                        </p>
                      </div>
                    </div>
                    <div className="flex items-center gap-2 pt-1">
                      <button
                        type="button"
                        disabled={approving}
                        onClick={() => handleApproveExpense(true)}
                        className="inline-flex items-center gap-1.5 px-4 py-2 rounded-xl text-xs font-bold bg-emerald-600 text-white hover:bg-emerald-700 transition-colors shadow-xs cursor-pointer disabled:opacity-50"
                      >
                        {approving ? <Loader2 className="w-4 h-4 animate-spin" /> : <CheckCircle2 className="w-4 h-4" />}
                        <span>{t("agency_maint_btn_mark_collected")}</span>
                      </button>
                    </div>
                  </div>
                )}

                {/* Agency Review & Approval Bar */}
                {hasExpense && isPendingReview && !isEditingFinancials && (
                  <div className={`rounded-xl border p-4 space-y-3 ${isPaymentProofReview ? "bg-emerald-50/50 border-emerald-200/80" : "bg-amber-50/60 border-amber-200/80"}`}>
                    <div className="flex items-start justify-between gap-3">
                      <div className="flex items-center gap-2">
                        {isPaymentProofReview ? (
                          <CheckCircle2 className="w-5 h-5 text-emerald-600 shrink-0" />
                        ) : (
                          <ShieldAlert className="w-5 h-5 text-amber-600 shrink-0" />
                        )}
                        <div>
                          <h4 className={`text-xs font-bold ${isPaymentProofReview ? "text-emerald-900" : "text-amber-900"}`}>
                            {isPaymentProofReview
                              ? t("agency_maint_payment_review_heading")
                              : t("agency_maint_review_heading")}
                          </h4>
                          <p className={`text-[11px] mt-0.5 ${isPaymentProofReview ? "text-emerald-700" : "text-amber-700"}`}>
                            {isPaymentProofReview
                              ? t("agency_maint_payment_review_desc")
                              : t("agency_maint_review_desc")}
                          </p>
                        </div>
                      </div>
                    </div>

                    {!isRejecting ? (
                      <div className="flex items-center gap-2 pt-1">
                        <button
                          type="button"
                          disabled={approving}
                          onClick={() => handleApproveExpense(false)}
                          className={`inline-flex items-center gap-1.5 px-4 py-2 rounded-xl text-xs font-bold text-white transition-colors shadow-xs cursor-pointer disabled:opacity-50 ${isPaymentProofReview ? "bg-emerald-600 hover:bg-emerald-700" : "bg-[#1B5888] hover:bg-emerald-700"}`}
                        >
                          {approving ? <Loader2 className="w-4 h-4 animate-spin" /> : <Check className="w-4 h-4" />}
                          <span>
                            {isPaymentProofReview
                              ? t("agency_maint_btn_confirm_payment")
                              : t("agency_maint_btn_approve_expense")}
                          </span>
                        </button>

                        <button
                          type="button"
                          disabled={approving}
                          onClick={() => {
                            if (isDemoMode && !isDemoVerified) {
                              onRequestVerification?.();
                              return;
                            }
                            setIsRejecting(true);
                          }}
                          className="inline-flex items-center gap-1.5 px-4 py-2 rounded-xl text-xs font-bold bg-white border border-rose-200 text-rose-700 hover:bg-rose-50 transition-colors shadow-2xs cursor-pointer disabled:opacity-50"
                        >
                          <X className="w-4 h-4" />
                          <span>
                            {isPaymentProofReview
                              ? t("agency_maint_btn_reject_payment")
                              : t("agency_maint_btn_reject_expense")}
                          </span>
                        </button>
                      </div>
                    ) : (
                      <div className="space-y-2 pt-2 border-t border-amber-200/60">
                        <label className="text-xs font-bold text-amber-900 block">
                          {t("agency_maint_rejection_reason_label")} *
                        </label>
                        <textarea
                          required
                          value={rejectionReason}
                          onChange={(e) => setRejectionReason(e.target.value)}
                          rows={2}
                          placeholder={t("agency_maint_rejection_reason_placeholder")}
                          className="w-full p-2.5 rounded-lg border border-amber-300 bg-white text-xs text-slate-900 focus:ring-2 focus:ring-amber-500/20 focus:border-amber-500"
                        />
                        <div className="flex items-center justify-end gap-2">
                          <button
                            type="button"
                            onClick={() => {
                              setIsRejecting(false);
                              setRejectionReason("");
                            }}
                            className="px-3 py-1.5 rounded-lg text-xs font-semibold text-slate-600 hover:bg-slate-100"
                          >
                            {t("agency_maint_close")}
                          </button>
                          <button
                            type="button"
                            disabled={approving || !rejectionReason.trim()}
                            onClick={handleRejectExpense}
                            className="px-3.5 py-1.5 rounded-lg text-xs font-bold bg-rose-600 text-white hover:bg-rose-700 transition-colors shadow-xs disabled:opacity-50"
                          >
                            {approving ? <Loader2 className="w-3.5 h-3.5 animate-spin" /> : t("agency_maint_btn_reject_expense")}
                          </button>
                        </div>
                      </div>
                    )}
                  </div>
                )}

                {/* Rejection Note Display */}
                {request.payment_status === "rejected" && request.rejection_reason && (
                  <div className="p-4 rounded-xl bg-rose-50 border border-rose-200 space-y-1">
                    <span className="text-[11px] font-bold text-rose-800 block">
                      {t("agency_maint_rejection_reason_label")}
                    </span>
                    <p className="text-xs text-rose-700 leading-relaxed font-medium">
                      {request.rejection_reason}
                    </p>
                  </div>
                )}

                {/* Inline Financial Edit Form */}
                {isEditingFinancials && (
                  <form
                    onSubmit={handleSaveFinancials}
                    className="bg-white rounded-xl border border-[#1B5888]/40 p-5 space-y-4 shadow-sm animate-in fade-in"
                  >
                    <div className="flex items-center justify-between pb-3 border-b border-slate-100">
                      <h4 className="text-xs font-bold text-slate-800 flex items-center gap-1.5">
                        <DollarSign className="w-4 h-4 text-[#1B5888]" />
                        <span>
                          {!hasExpense
                            ? t("agency_maint_declare_heading")
                            : t("agency_maint_btn_edit_financials")}
                        </span>
                      </h4>
                      <button
                        type="button"
                        onClick={() => setIsEditingFinancials(false)}
                        className="text-xs text-slate-500 hover:text-slate-800"
                      >
                        {t("agency_maint_close")}
                      </button>
                    </div>

                    {financialError && (
                      <div className="p-3 rounded-lg bg-rose-50 text-rose-700 text-xs border border-rose-200 flex items-center gap-2">
                        <AlertCircle className="w-4 h-4 shrink-0" />
                        <span>{financialError}</span>
                      </div>
                    )}

                    {/* Cost, Currency & Payment Date */}
                    <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                      <div className="sm:col-span-1">
                        <label className="text-xs font-bold text-slate-800 block mb-1">
                          {t("agency_maint_cost_label")} *
                        </label>
                        <input
                          type="number"
                          step="0.01"
                          min="0"
                          required
                          value={costAmount}
                          onChange={(e) => setCostAmount(e.target.value)}
                          placeholder="0.00"
                          className="w-full px-3 py-2 rounded-lg border border-slate-200 text-sm font-mono focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500"
                        />
                      </div>
                      <div>
                        <label className="text-xs font-bold text-slate-800 block mb-1">
                          {t("agency_props_field_currency")}
                        </label>
                        <select
                          value={currency}
                          onChange={(e) => setCurrency(e.target.value)}
                          className="w-full px-3 py-2 rounded-lg border border-slate-200 text-xs font-bold text-slate-800"
                        >
                          <option value="EUR">EUR (€)</option>
                          <option value="RSD">RSD (дин)</option>
                        </select>
                      </div>
                      <div>
                        <label className="text-xs font-bold text-slate-800 block mb-1">
                          {t("agency_maint_payment_date_label")}
                        </label>
                        <input
                          type="date"
                          value={paymentDate}
                          onChange={(e) => setPaymentDate(e.target.value)}
                          className="w-full px-3 py-2 rounded-lg border border-slate-200 text-xs text-slate-800 bg-white"
                        />
                      </div>
                    </div>

                    {/* Who Paid */}
                    <div>
                      <label className="text-xs font-bold text-slate-800 block mb-1.5">
                        {t("agency_maint_payer_label")} *
                      </label>
                      <div className="grid grid-cols-3 gap-2">
                        {(["tenant", "landlord", "agency"] as const).map((p) => (
                          <button
                            key={p}
                            type="button"
                            onClick={() => {
                              setPaidBy(p);
                              if (p === "tenant") setDeclarationIntent("reimburse");
                              else if (p === "landlord") setDeclarationIntent("self");
                              else if (p === "agency") setDeclarationIntent("fixture_landlord");
                            }}
                            className={`py-2 px-3 rounded-lg text-xs font-bold border transition-all cursor-pointer ${paidBy === p
                              ? "bg-[#1B5888] text-white border-[#1B5888] shadow-xs"
                              : "bg-white text-slate-700 border-slate-200 hover:bg-slate-50"
                              }`}
                          >
                            {t("agency_maint_payer_" + p)}
                          </button>
                        ))}
                      </div>
                    </div>

                    {/* Settlement Intent based on Payer */}
                    {paidBy && (
                      <div className="space-y-1.5 animate-in fade-in">
                        <label className="text-xs font-bold text-slate-800 block">
                          {t("agency_maint_intent_label")} *
                        </label>

                        {paidBy === "tenant" && (
                          <div className="space-y-2">
                            <label
                              className={`flex items-start gap-2.5 p-3 rounded-lg border cursor-pointer transition-colors ${declarationIntent === "reimburse"
                                ? "bg-blue-50/70 border-blue-400 text-blue-900"
                                : "bg-white border-slate-200 hover:bg-slate-50 text-slate-800"
                                }`}
                            >
                              <input
                                type="radio"
                                name="intent"
                                value="reimburse"
                                checked={declarationIntent === "reimburse"}
                                onChange={() => setDeclarationIntent("reimburse")}
                                className="mt-0.5 text-[#1B5888]"
                              />
                              <div className="text-xs">
                                <span className="font-bold block">
                                  {t("agency_maint_intent_tenant_reimburse")}
                                </span>
                                <span className="text-[11px] text-slate-500">
                                  {t("agency_maint_intent_tenant_reimburse_sub")}
                                </span>
                              </div>
                            </label>

                            <label
                              className={`flex items-start gap-2.5 p-3 rounded-lg border cursor-pointer transition-colors ${declarationIntent === "self"
                                ? "bg-blue-50/70 border-blue-400 text-blue-900"
                                : "bg-white border-slate-200 hover:bg-slate-50 text-slate-800"
                                }`}
                            >
                              <input
                                type="radio"
                                name="intent"
                                value="self"
                                checked={declarationIntent === "self"}
                                onChange={() => setDeclarationIntent("self")}
                                className="mt-0.5 text-[#1B5888]"
                              />
                              <div className="text-xs">
                                <span className="font-bold block">
                                  {t("agency_maint_intent_tenant_self")}
                                </span>
                                <span className="text-[11px] text-slate-500">
                                  {t("agency_maint_intent_tenant_self_sub")}
                                </span>
                              </div>
                            </label>
                          </div>
                        )}

                        {paidBy === "landlord" && (
                          <div className="space-y-2">
                            <label
                              className={`flex items-start gap-2.5 p-3 rounded-lg border cursor-pointer transition-colors ${declarationIntent === "self"
                                ? "bg-blue-50/70 border-blue-400 text-blue-900"
                                : "bg-white border-slate-200 hover:bg-slate-50 text-slate-800"
                                }`}
                            >
                              <input
                                type="radio"
                                name="intent"
                                value="self"
                                checked={declarationIntent === "self"}
                                onChange={() => setDeclarationIntent("self")}
                                className="mt-0.5 text-[#1B5888]"
                              />
                              <div className="text-xs">
                                <span className="font-bold block">
                                  {t("agency_maint_intent_landlord_self")}
                                </span>
                                <span className="text-[11px] text-slate-500">
                                  {t("agency_maint_intent_landlord_self_sub")}
                                </span>
                              </div>
                            </label>

                            <label
                              className={`flex items-start gap-2.5 p-3 rounded-lg border cursor-pointer transition-colors ${declarationIntent === "tenant_due"
                                ? "bg-blue-50/70 border-blue-400 text-blue-900"
                                : "bg-white border-slate-200 hover:bg-slate-50 text-slate-800"
                                }`}
                            >
                              <input
                                type="radio"
                                name="intent"
                                value="tenant_due"
                                checked={declarationIntent === "tenant_due"}
                                onChange={() => setDeclarationIntent("tenant_due")}
                                className="mt-0.5 text-[#1B5888]"
                              />
                              <div className="text-xs">
                                <span className="font-bold block">
                                  {t("agency_maint_intent_landlord_tenant_due")}
                                </span>
                                <span className="text-[11px] text-slate-500">
                                  {t("agency_maint_intent_landlord_tenant_due_sub")}
                                </span>
                              </div>
                            </label>
                          </div>
                        )}

                        {paidBy === "agency" && (
                          <div className="space-y-2">
                            <label
                              className={`flex items-start gap-2.5 p-3 rounded-lg border cursor-pointer transition-colors ${declarationIntent === "fixture_landlord"
                                ? "bg-blue-50/70 border-blue-400 text-blue-900"
                                : "bg-white border-slate-200 hover:bg-slate-50 text-slate-800"
                                }`}
                            >
                              <input
                                type="radio"
                                name="intent"
                                value="fixture_landlord"
                                checked={declarationIntent === "fixture_landlord"}
                                onChange={() => setDeclarationIntent("fixture_landlord")}
                                className="mt-0.5 text-[#1B5888]"
                              />
                              <div className="text-xs">
                                <span className="font-bold block">
                                  {t("agency_maint_intent_agency_fixture")}
                                </span>
                                <span className="text-[11px] text-slate-500">
                                  {t("agency_maint_intent_agency_fixture_sub")}
                                </span>
                              </div>
                            </label>

                            <label
                              className={`flex items-start gap-2.5 p-3 rounded-lg border cursor-pointer transition-colors ${declarationIntent === "damage_tenant"
                                ? "bg-blue-50/70 border-blue-400 text-blue-900"
                                : "bg-white border-slate-200 hover:bg-slate-50 text-slate-800"
                                }`}
                            >
                              <input
                                type="radio"
                                name="intent"
                                value="damage_tenant"
                                checked={declarationIntent === "damage_tenant"}
                                onChange={() => setDeclarationIntent("damage_tenant")}
                                className="mt-0.5 text-[#1B5888]"
                              />
                              <div className="text-xs">
                                <span className="font-bold block">
                                  {t("agency_maint_intent_agency_damage")}
                                </span>
                                <span className="text-[11px] text-slate-500">
                                  {t("agency_maint_intent_agency_damage_sub")}
                                </span>
                              </div>
                            </label>
                          </div>
                        )}
                      </div>
                    )}

                    {/* Upload Invoice Document */}
                    <div>
                      <label className="text-xs font-bold text-slate-800 block mb-1">
                        {t("agency_maint_invoice_doc_label")}
                      </label>
                      <div className="flex items-center gap-2">
                        <label className="flex-1 border border-dashed border-slate-300 rounded-lg p-2.5 text-center cursor-pointer hover:bg-slate-50 transition-colors">
                          <input
                            type="file"
                            accept="application/pdf,image/*"
                            className="hidden"
                            onChange={(e) => {
                              if (e.target.files && e.target.files[0]) {
                                setInvoiceFile(e.target.files[0]);
                              }
                            }}
                          />
                          <span className="text-xs text-slate-600 flex items-center justify-center gap-1.5">
                            <UploadCloud className="w-4 h-4 text-[#1B5888]" />
                            <span>{invoiceFile ? invoiceFile.name : t("agency_maint_upload_invoice_btn")}</span>
                          </span>
                        </label>

                        {invoiceFile && (
                          <button
                            type="button"
                            onClick={() => setInvoiceFile(null)}
                            className="p-2 text-rose-600 hover:bg-rose-50 rounded-lg"
                          >
                            <X className="w-4 h-4" />
                          </button>
                        )}
                      </div>
                    </div>

                    {/* Financial Note */}
                    <div>
                      <label className="text-xs font-bold text-slate-800 block mb-1">
                        {t("agency_maint_note_label")}
                      </label>
                      <input
                        type="text"
                        value={financialNote}
                        onChange={(e) => setFinancialNote(e.target.value)}
                        placeholder={t("agency_maint_financial_note_placeholder")}
                        className="w-full px-3 py-2 rounded-lg border border-slate-200 text-xs focus:ring-2 focus:ring-[#1B5888]/20 focus:border-[#1B5888]"
                      />
                    </div>

                    <div className="flex items-center justify-end gap-2 pt-2 border-t border-slate-100">
                      <button
                        type="button"
                        onClick={() => setIsEditingFinancials(false)}
                        className="px-3 py-1.5 rounded-lg border border-slate-200 text-xs font-semibold text-slate-600 hover:bg-slate-50 cursor-pointer"
                      >
                        {t("agency_maint_close")}
                      </button>
                      <button
                        type="submit"
                        disabled={savingFinancials}
                        className="px-4 py-1.5 rounded-[10px] bg-[#1B5888] text-white text-xs font-bold hover:bg-[#15466d] transition-colors shadow-xs cursor-pointer disabled:opacity-50 flex items-center gap-1.5"
                      >
                        {savingFinancials && <Loader2 className="w-3.5 h-3.5 animate-spin" />}
                        <span>
                          {!hasExpense
                            ? t("agency_maint_btn_declare_expense")
                            : t("agency_maint_btn_save_financials")}
                        </span>
                      </button>
                    </div>
                  </form>
                )}
              </div>
            </div>
          )}
        </div>

      {/* Right Column (1 Col) - Context Cards */}
      <div className="space-y-6">
        {/* Quick Actions Card (Flutter Parity) */}
        <div className="bg-white rounded-[10px] border border-slate-200/80 p-5 shadow-xs space-y-3.5">
          <div className="flex items-center gap-2 pb-2 border-b border-slate-100">
            <div className="p-1.5 rounded-lg bg-amber-500/10 text-amber-600">
              <Zap className="w-4 h-4" />
            </div>
            <div>
              <h4 className="text-xs font-bold text-slate-800 tracking-wide uppercase">
                {t("agency_maint_quick_actions")}
              </h4>
            </div>
          </div>

          <div className="space-y-2 pt-0.5">
            {/* 1. İnceleniyor (Investigating) */}
            <button
              type="button"
              disabled={updatingStatus || request.status === "investigating"}
              onClick={() => handleStatusChange("investigating")}
              className={`w-full inline-flex items-center justify-center gap-2 px-3.5 py-2.5 rounded-[10px] text-xs font-bold border transition-all ${request.status === "investigating"
                ? "bg-[#E5EEF6] text-[#1B5888] border-[#1B5888]/20 shadow-2xs cursor-default"
                : "bg-white text-[#1B5888] border-[#1B5888]/20 hover:bg-[#E5EEF6]/50 cursor-pointer shadow-2xs hover:border-[#1B5888]/40"
                } disabled:opacity-80`}
            >
              {updatingStatus && request.status !== "investigating" ? (
                <Loader2 className="w-4 h-4 animate-spin text-[#1B5888]" />
              ) : request.status === "investigating" ? (
                <Check className="w-4 h-4 text-[#1B5888]" />
              ) : (
                <Search className="w-4 h-4 text-[#1B5888]" />
              )}
              <span>
                {t("agency_maint_status_investigating")}
              </span>
            </button>

            {/* 2. Usta Gönderildi / İşlemde (In Progress) */}
            <button
              type="button"
              disabled={updatingStatus || request.status === "in_progress"}
              onClick={() => handleStatusChange("in_progress")}
              className={`w-full inline-flex items-center justify-center gap-2 px-3.5 py-2.5 rounded-[10px] text-xs font-bold border transition-all ${request.status === "in_progress"
                ? "bg-amber-50/80 text-amber-800 border-amber-200 shadow-2xs cursor-default"
                : "bg-white text-amber-700 border-amber-200 hover:bg-amber-50/50 cursor-pointer shadow-2xs hover:border-amber-300"
                } disabled:opacity-80`}
            >
              {updatingStatus && request.status !== "in_progress" ? (
                <Loader2 className="w-4 h-4 animate-spin text-amber-600" />
              ) : request.status === "in_progress" ? (
                <Check className="w-4 h-4 text-amber-600" />
              ) : (
                <Wrench className="w-4 h-4 text-amber-600" />
              )}
              <span>
                {t("agency_maint_status_in_progress")}
              </span>
            </button>

            {/* 3. Çözüldü (Resolved) */}
            <button
              type="button"
              disabled={updatingStatus || request.status === "resolved"}
              onClick={() => handleStatusChange("resolved")}
              className={`w-full inline-flex items-center justify-center gap-2 px-3.5 py-2.5 rounded-[10px] text-xs font-bold transition-all shadow-2xs ${request.status === "resolved"
                ? "bg-[#1B5888] text-white opacity-90 cursor-default"
                : "bg-[#1B5888] text-white hover:bg-[#15466d] cursor-pointer active:scale-[0.99]"
                } disabled:opacity-80`}
            >
              {updatingStatus && request.status !== "resolved" ? (
                <Loader2 className="w-4 h-4 animate-spin text-white" />
              ) : request.status === "resolved" ? (
                <Check className="w-4 h-4 text-white" />
              ) : (
                <CheckCircle2 className="w-4 h-4 text-white" />
              )}
              <span>
                {t("agency_maint_status_resolved")}
              </span>
            </button>

            {/* 4. Reopen Ticket (if resolved or closed) */}
            {(request.status === "resolved" || request.status === "closed") && (
              <button
                type="button"
                disabled={updatingStatus}
                onClick={() => handleStatusChange("open")}
                className="w-full inline-flex items-center justify-center gap-2 px-3 py-2 rounded-[10px] text-xs font-semibold text-slate-600 bg-slate-50 border border-slate-200 hover:bg-slate-100 transition-colors cursor-pointer pt-1"
              >
                <RotateCcw className="w-3.5 h-3.5 text-slate-500" />
                <span>{t("agency_maint_btn_reopen")}</span>
              </button>
            )}
          </div>
        </div>

        {/* Financial Summary Card */}
        <div className="bg-white rounded-[10px] border border-slate-200/80 p-5 shadow-xs space-y-3.5">
          {/* Header: Finansal Durum Özeti & Status Badge - Alt Alta */}
          <div className="flex flex-col items-start gap-1.5 pb-1">
            <h4 className="text-xs font-bold text-slate-800 flex items-center gap-2">
              <DollarSign className="w-4 h-4 text-[#1B5888]" />
              <span>{t("agency_maint_financial_summary_title")}</span>
            </h4>
            <span
              className={`inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-[11px] font-bold border ${!hasExpense
                ? "bg-slate-100 text-slate-600 border-slate-200"
                : request.payment_status === "paid"
                  ? "bg-emerald-50 text-emerald-800 border-emerald-200"
                  : request.payment_status === "rejected"
                    ? "bg-rose-50 text-rose-800 border-rose-200"
                    : request.payment_status === "pending_payment"
                      ? "bg-blue-50 text-blue-800 border-blue-200"
                      : "bg-amber-50 text-amber-800 border-amber-200"
                }`}
            >
              <span
                className={`w-1.5 h-1.5 rounded-full ${!hasExpense
                  ? "bg-slate-400"
                  : request.payment_status === "paid"
                    ? "bg-emerald-500"
                    : request.payment_status === "rejected"
                      ? "bg-rose-500"
                      : request.payment_status === "pending_payment"
                        ? "bg-blue-500"
                        : "bg-amber-500"
                  }`}
              />
              {!hasExpense
                ? t("agency_maint_status_no_expense")
                : getMaintenanceExpenseStatusLabel(request.payment_status, t)}
            </span>
          </div>

          {/* Amount Box */}
          <div className="bg-slate-50/80 rounded-[8px] border border-slate-200/80 p-3.5">
            <span className="text-[11px] text-slate-500 block font-medium">
              {t("agency_maint_modal_cost_amount_label")}
            </span>
            <div className="flex items-baseline gap-1.5 mt-0.5">
              <span className="text-2xl font-extrabold font-mono text-slate-900">
                {hasExpense ? `€${effectiveOriginalCost.toLocaleString()}` : "€0.00"}
              </span>
              <span className="text-xs font-bold text-slate-500">
                {effectiveCurrency}
              </span>
            </div>
            {effectiveSettledCost > 0 && (
              <div
                className={`flex items-center gap-1.5 px-2 py-1 rounded-md text-[10.5px] font-semibold mt-2 border ${effectiveRemainingCost > 0
                  ? "bg-amber-50 border-amber-200/80 text-amber-800"
                  : "bg-emerald-50 border-emerald-200/80 text-emerald-800"
                  }`}
              >
                {effectiveRemainingCost > 0 ? (
                  <Info className="w-3 h-3 text-amber-600 shrink-0" />
                ) : (
                  <CheckCircle2 className="w-3 h-3 text-emerald-600 shrink-0" />
                )}
                <span>
                  {effectiveRemainingCost > 0
                    ? t("agency_maint_offset_and_remaining", {
                      offset: `${effectiveSettledCost.toLocaleString()} ${effectiveCurrency}`,
                      remaining: `${effectiveRemainingCost.toLocaleString()} ${effectiveCurrency}`,
                    })
                    : t("agency_maint_offset_fully_settled", {
                      offset: `${effectiveSettledCost.toLocaleString()} ${effectiveCurrency}`,
                    })}
                </span>
              </div>
            )}
          </div>

          {/* One-Sentence Financial Status Summary Banner */}
          <div
            className={`p-3 rounded-[8px] text-[11px] leading-relaxed flex items-start gap-2.5 border ${!hasExpense
              ? "bg-slate-50 border-slate-200/80 text-slate-600"
              : request.payment_status === "paid"
                ? "bg-emerald-50/70 border-emerald-200/80 text-emerald-800"
                : request.payment_status === "rejected"
                  ? "bg-rose-50/70 border-rose-200/80 text-rose-800"
                  : request.payment_status === "pending_payment"
                    ? "bg-blue-50/70 border-blue-200/80 text-blue-800"
                    : "bg-amber-50/70 border-amber-200/80 text-amber-900"
              }`}
          >
            <Info
              className={`w-4 h-4 shrink-0 mt-0.5 ${!hasExpense
                ? "text-slate-400"
                : request.payment_status === "paid"
                  ? "text-emerald-600"
                  : request.payment_status === "rejected"
                    ? "text-rose-600"
                    : request.payment_status === "pending_payment"
                      ? "text-blue-600"
                      : "text-amber-600"
                }`}
            />
            <span className="font-medium">{getFinancialSummarySentence()}</span>
          </div>

          {/* Financial Details Rows - Clean stacked layout for full readability without clipping */}
          <div className="space-y-2.5 text-xs divide-y divide-slate-100 pt-0.5">
            <div className="flex justify-between items-center py-1">
              <span className="text-slate-500 font-medium">{t("agency_maint_payer_label")}</span>
              <span className="font-bold text-slate-800">
                {resolvedPayer ? t("agency_maint_payer_" + resolvedPayer) : "-"}
              </span>
            </div>

            {resolvedIntent && resolvedPayer && (
              <div className="pt-2 flex flex-col gap-1">
                <span className="text-slate-500 font-medium text-[11px]">{t("agency_maint_intent_label")}</span>
                <span className="font-semibold text-slate-800 text-xs leading-normal">
                  {t(getIntentTranslationKey(resolvedPayer, resolvedIntent))}
                </span>
              </div>
            )}

            {(charges[0]?.paid_at || charges[0]?.contractor_payment_date) && (
              <div className="flex justify-between items-center pt-2">
                <span className="text-slate-500 font-medium">{t("agency_maint_payment_date_label")}</span>
                <span className="font-bold text-slate-800">
                  {formatEuropeanDate(charges[0]?.paid_at || charges[0]?.contractor_payment_date)}
                </span>
              </div>
            )}

            <div className="pt-2 flex flex-col gap-1">
              <span className="text-slate-500 font-medium text-[11px]">{t("agency_maint_invoice_doc_label")}</span>
              <div className="pt-0.5">
                {request.invoice_pdf_url && request.invoice_pdf_url !== "cash_settlement" ? (
                  <a
                    href={request.invoice_pdf_url}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-flex items-center gap-1.5 font-bold text-[#1B5888] hover:underline text-xs"
                    title={t("agency_maint_btn_view_invoice")}
                  >
                    <FileText className="w-3.5 h-3.5 shrink-0" />
                    <span>{t("agency_maint_btn_view_invoice")}</span>
                    <ExternalLink className="w-3 h-3 text-slate-400" />
                  </a>
                ) : (
                  <span className="text-slate-400 italic text-xs">
                    {t("agency_maint_no_invoice_attached")}
                  </span>
                )}
              </div>
            </div>
          </div>

          {/* Quick Action Button */}
          <div className="pt-1 space-y-2">
            {hasExpense && request.payment_status === "pending_payment" && (
              <button
                type="button"
                disabled={approving}
                onClick={() => handleApproveExpense(true)}
                className="w-full inline-flex items-center justify-center gap-1.5 px-3 py-2 rounded-[10px] text-xs font-bold bg-emerald-600 text-white hover:bg-emerald-700 transition-colors cursor-pointer shadow-xs disabled:opacity-50"
              >
                {approving ? <Loader2 className="w-3.5 h-3.5 animate-spin" /> : <CheckCircle2 className="w-3.5 h-3.5" />}
                <span>{t("agency_maint_btn_mark_collected")}</span>
              </button>
            )}
            {!hasExpense ? (
              <button
                type="button"
                onClick={() => {
                  if (isDemoMode && !isDemoVerified) {
                    onRequestVerification?.();
                    return;
                  }
                  setActiveDetailTab("financials");
                  setIsEditingFinancials(true);
                }}
                className="w-full inline-flex items-center justify-center gap-1.5 px-3 py-2 rounded-[10px] text-xs font-bold bg-[#1B5888] text-white hover:bg-[#15466d] transition-colors cursor-pointer shadow-xs"
              >
                <Plus className="w-3.5 h-3.5" />
                <span>{t("agency_maint_btn_declare_expense")}</span>
              </button>
            ) : (
              <button
                type="button"
                onClick={() => {
                  setActiveDetailTab("financials");
                }}
                className="w-full inline-flex items-center justify-center gap-1.5 px-3 py-2 rounded-[8px] text-xs font-bold text-slate-700 bg-slate-50 border border-slate-200 hover:bg-[#E5EEF6] hover:text-[#1B5888] hover:border-[#1B5888] transition-colors cursor-pointer shadow-2xs group"
              >
                <span>{t("agency_maint_view_full_financials")}</span>
                <ChevronRight className="w-3.5 h-3.5 text-slate-400 group-hover:text-[#1B5888] group-hover:translate-x-0.5 transition-all" />
              </button>
            )}
          </div>
        </div>
      </div>
    </div>
    </div >
  );
}
