"use client";

import React from "react";
import {
  Activity,
  AlertTriangle,
  ArrowRight,
  CheckCircle2,
  ChevronRight,
  Clock,
  FileText,
  Home,
  Receipt,
  Wrench,
} from "lucide-react";
import {
  AgencyManagedProperty,
  AgencyRentPayment,
  AgencyContract,
  AgencyMaintenanceRequest,
  AgencyMaintStatusFilter,
  AgencyPanelTab,
} from "../types";
import { processRentPayments } from "../utils";

export interface PmCockpitCardsProps {
  managedProperties: AgencyManagedProperty[];
  managedPropertyStats?: {
    total: number;
    occupied: number;
    vacant: number;
    occupancyRate: number;
  };
  payments: AgencyRentPayment[];
  contracts: AgencyContract[];
  maintenanceRequests: AgencyMaintenanceRequest[];
  setActiveTab: (tab: AgencyPanelTab) => void;
  setPaymentStatusFilter?: (status: "all" | "awaiting" | "overdue" | "paid") => void;
  setPropOccupancyFilter?: (filter: "all" | "occupied" | "vacant" | "expiring" | "expired") => void;
  setMaintStatusFilter?: (status: AgencyMaintStatusFilter) => void;
  t: (key: string) => string;
}

export default function PmCockpitCards({
  managedProperties,
  managedPropertyStats = { total: 0, occupied: 0, vacant: 0, occupancyRate: 0 },
  payments,
  contracts,
  maintenanceRequests,
  setActiveTab,
  setPaymentStatusFilter,
  setPropOccupancyFilter,
  setMaintStatusFilter,
  t,
}: PmCockpitCardsProps) {
  const now = new Date();
  const todayStr = now.toISOString().split("T")[0];

  const isRentTitle = (title?: string | null): boolean => {
    const s = (title || "").trim().toLowerCase();
    return (
      s === "kira" ||
      s === "rent" ||
      s.includes("kira") ||
      s.includes("zakupnina") ||
      s.includes("kirija")
    );
  };

  const calculateCurrencyTotals = (items: AgencyRentPayment[]): Record<string, number> => {
    const totals: Record<string, number> = {};
    for (const item of items) {
      const amt = Number(item.amount) || 0;
      const curr = (item.currency || "EUR").toUpperCase();
      if (amt > 0) {
        totals[curr] = (totals[curr] || 0) + amt;
      }
    }
    return totals;
  };

  const formatCockpitCurrencyTotals = (
    totals: Record<string, number>,
    emptyText: string
  ): string => {
    const keys = Object.keys(totals).filter((k) => (totals[k] || 0) > 0);
    if (keys.length === 0) return emptyText;

    keys.sort((a, b) => {
      const order: Record<string, number> = { EUR: 1, RSD: 2, USD: 3 };
      const orderA = order[a] || 99;
      const orderB = order[b] || 99;
      if (orderA !== orderB) return orderA - orderB;
      return a.localeCompare(b);
    });

    const parts: string[] = [];
    for (const curr of keys) {
      const amount = totals[curr];
      if (curr === "EUR") {
        const formatted = amount.toLocaleString("de-DE", {
          minimumFractionDigits: 2,
          maximumFractionDigits: 2,
        });
        parts.push(`${formatted} €`);
      } else if (curr === "RSD") {
        if (amount >= 1000) {
          const k = (amount / 1000).toFixed(amount % 1000 === 0 ? 0 : 1);
          parts.push(`${k}k RSD`);
        } else {
          parts.push(`${Math.round(amount)} RSD`);
        }
      } else if (curr === "USD") {
        const formatted = amount.toLocaleString("de-DE", {
          minimumFractionDigits: 2,
          maximumFractionDigits: 2,
        });
        parts.push(`${formatted} $`);
      } else {
        parts.push(`${amount.toLocaleString("de-DE")} ${curr}`);
      }
    }
    return parts.length === 0 ? emptyText : parts.join(" + ");
  };

  // 1. Finans ve Tahsilat Hesaplamaları (PaymentsTab ile 1:1 SSOT)
  const deduplicatedPayments = processRentPayments(payments);
  const todayMidnight = new Date();
  todayMidnight.setHours(0, 0, 0, 0);

  const overdueList = deduplicatedPayments.filter((item) => {
    if (item.is_overdue !== undefined) return item.is_overdue;
    const status = (item.status as string) || "pending";
    if (status === "declared" || status === "disputed" || status === "paid" || status === "cancelled") {
      return false;
    }
    const amt = Number(item.amount) || 0;
    if (amt <= 0) return false;
    if (status === "overdue") return true;
    if (status === "pending" && item.due_date) {
      return new Date(item.due_date) < todayMidnight;
    }
    return false;
  });
  const overdueRentsList = overdueList.filter((p) => isRentTitle(p.title));
  const overdueBillsList = overdueList.filter((p) => !isRentTitle(p.title));
  const overdueRentCount = overdueRentsList.length;
  const overdueBillCount = overdueBillsList.length;
  const overdueTotals = calculateCurrencyTotals(overdueList);
  const overdueRentTotals = calculateCurrencyTotals(overdueRentsList);
  const overdueBillTotals = calculateCurrencyTotals(overdueBillsList);
  const isOverdueEmpty = overdueList.length === 0;

  // Card 2: Unentered Bills (PaymentsTab unenteredBillsList ile 1:1)
  const unenteredBillsList = deduplicatedPayments.filter((item) => {
    const status = (item.status as string) || "pending";
    if (status === "paid" || status === "declared" || status === "disputed") return false;
    const receiverType = item.receiver_type || "owner";
    const isOwnerExpense =
      (receiverType === "owner" || receiverType === "included") && !isRentTitle(item.title);
    if (!isOwnerExpense) return false;
    const amt = Number(item.amount) || 0;
    return amt === 0;
  });
  const unenteredBillsCount = unenteredBillsList.length;
  const unenteredBillsPropCount = new Set(unenteredBillsList.map((b) => b.property_id)).size;
  const isUnenteredBillsEmpty = unenteredBillsCount === 0;

  // Card 3: Pending Approvals (PaymentsTab pendingApprovalsList ile 1:1)
  const pendingApprovalsList = deduplicatedPayments.filter(
    (p) =>
      p.status === "disputed" ||
      (p.is_pending_approval ??
        (p.status === "declared" || (p.status === "pending" && Boolean(p.declared_at))))
  );
  const isPaymentDisputed = (p: AgencyRentPayment) => p.status === "disputed";
  const declaredRentsCount = pendingApprovalsList.filter(
    (p) => !isPaymentDisputed(p) && !p.is_maintenance && isRentTitle(p.title)
  ).length;
  const declaredBillsCount = pendingApprovalsList.filter(
    (p) => !isPaymentDisputed(p) && !p.is_maintenance && !isRentTitle(p.title)
  ).length;
  const declaredMaintenanceCount = pendingApprovalsList.filter(
    (p) => !isPaymentDisputed(p) && Boolean(p.is_maintenance)
  ).length;
  const disputedPaymentsCount = pendingApprovalsList.filter(isPaymentDisputed).length;
  const pendingApprovalsTotal = pendingApprovalsList.length;
  const isPendingApprovalsEmpty = pendingApprovalsTotal === 0;

  const totalFinancePending =
    (isOverdueEmpty ? 0 : overdueList.length) +
    (isUnenteredBillsEmpty ? 0 : unenteredBillsCount) +
    (isPendingApprovalsEmpty ? 0 : pendingApprovalsTotal);

  // 2. Sözleşme ve Portföy Hesaplamaları
  const managedPropIdSet = new Set(managedProperties.map((p) => p.id));

  // Her mülk için tekil/en güncel süresi dolmuş sözleşmeyi say (ManagedPropertiesTab ile 1:1)
  const expiredByProperty = new Map<string, AgencyContract>();
  contracts.forEach((c) => {
    if (!managedPropIdSet.has(c.property_id)) return;
    const isExpired =
      c.status === "expired" ||
      (c.status === "active" && Boolean(c.end_date && c.end_date < todayStr));
    if (!isExpired) return;
    const prev = expiredByProperty.get(c.property_id);
    if (!prev || (c.end_date || "") > (prev.end_date || "")) {
      expiredByProperty.set(c.property_id, c);
    }
  });
  const expiredContracts = Array.from(expiredByProperty.values());
  const expiredCount = expiredContracts.length;
  const expiredNegotiating = expiredContracts.filter(
    (c) => (c.status as string) === "negotiating"
  ).length;
  const expiredPendingAction = expiredCount - expiredNegotiating;
  const isExpiredEmpty = expiredCount === 0;

  // Her mülk için tekil/en güncel aktif sözleşmeyi say (ManagedPropertiesTab ile 1:1)
  const nowMs = Date.now();
  const expiringByProperty = new Map<string, AgencyContract>();
  contracts.forEach((c) => {
    if (!managedPropIdSet.has(c.property_id)) return;
    if (c.status !== "active" || !c.end_date) return;
    const diffDays = Math.ceil((new Date(c.end_date).getTime() - nowMs) / (1000 * 60 * 60 * 24));
    if (diffDays < 0 || diffDays > 60) return;
    const prev = expiringByProperty.get(c.property_id);
    if (!prev || (c.end_date || "") > (prev.end_date || "")) {
      expiringByProperty.set(c.property_id, c);
    }
  });
  const expiringContracts = Array.from(expiringByProperty.values());
  const expiringCount = expiringContracts.length;
  let t0 = 0,
    t15 = 0,
    t30 = 0,
    t60 = 0;
  expiringContracts.forEach((c) => {
    if (c.end_date) {
      const diff = Math.ceil((new Date(c.end_date).getTime() - nowMs) / (1000 * 60 * 60 * 24));
      if (diff <= 0) t0++;
      else if (diff <= 15) t15++;
      else if (diff <= 30) t30++;
      else if (diff <= 60) t60++;
    }
  });
  const isExpiringEmpty = expiringCount === 0;

  const withoutContractsProps = managedProperties.filter((p) => !p.is_occupied);
  const withoutContractsCount = withoutContractsProps.length;
  const vacantCount = withoutContractsProps.filter((p) => !p.tenant_id).length;
  const invitePendingCount = withoutContractsCount - vacantCount;
  const isWithoutContractsEmpty = withoutContractsCount === 0;

  const totalContractsPending =
    (isExpiredEmpty ? 0 : expiredCount) +
    (isExpiringEmpty ? 0 : expiringCount) +
    (isWithoutContractsEmpty ? 0 : withoutContractsCount);

  // 3. Operasyon ve Bakım Hesaplamaları
  // 3.1. Açık ve Bekleyen Talepler (Open / Pending Tickets)
  const openPendingRequests = maintenanceRequests.filter((r) => {
    const isResolved = r.status === "resolved" || r.status === "closed";
    const isInProgress = r.status === "in_progress";
    return (
      r.status === "open" ||
      r.status === "investigating" ||
      r.status === "pending" ||
      (!isResolved && !isInProgress)
    );
  });
  const openPendingCount = openPendingRequests.length;
  const openPendingUrgent = openPendingRequests.filter((r) => r.priority === "urgent").length;
  const openPendingHigh = openPendingRequests.filter((r) => r.priority === "high").length;
  const openPendingNormal = openPendingRequests.filter(
    (r) => r.priority === "normal" || r.priority === "low"
  ).length;
  let oldestOpenPendingDays = 0;
  openPendingRequests.forEach((r) => {
    if (r.created_at) {
      const diff = Math.floor(
        (Date.now() - new Date(r.created_at).getTime()) / (1000 * 60 * 60 * 24)
      );
      if (diff > oldestOpenPendingDays) oldestOpenPendingDays = diff;
    }
  });
  const isOpenPendingEmpty = openPendingCount === 0;

  // 3.2. İşlemde / Atanmış Talepler (In Progress / Assigned)
  const inProgressRequests = maintenanceRequests.filter(
    (r) => r.status === "in_progress"
  );
  const inProgressCount = inProgressRequests.length;
  const inProgressUrgent = inProgressRequests.filter((r) => r.priority === "urgent").length;
  const inProgressHigh = inProgressRequests.filter((r) => r.priority === "high").length;
  const inProgressNormal = inProgressRequests.filter(
    (r) => r.priority === "normal" || r.priority === "low"
  ).length;
  const isInProgressEmpty = inProgressCount === 0;

  // 3.3. Onay Bekleyen Masraflar (Pending Expense App)
  const pendingExpenseRequests = maintenanceRequests.filter((r) => {
    const cost = Number(r.cost_amount) || 0;
    if (cost <= 0) return false;
    const pStatus = r.payment_status || "pending_review";
    return (
      pStatus === "pending_review" ||
      pStatus === "pending_payment" ||
      pStatus === "pending_agency_approval" ||
      pStatus === "pending_opposite_approval" ||
      pStatus === "pending_landlord_approval" ||
      pStatus === "pending_tenant_approval"
    );
  });
  const pendingExpenseCount = pendingExpenseRequests.length;
  const pendingExpenseTotals: Record<string, number> = {};
  for (const r of pendingExpenseRequests) {
    const amt = Number(r.cost_amount) || 0;
    const curr = (r.currency || "EUR").toUpperCase();
    if (amt > 0) {
      pendingExpenseTotals[curr] = (pendingExpenseTotals[curr] || 0) + amt;
    }
  }
  const isPendingExpenseEmpty = pendingExpenseCount === 0;

  const totalOperationsPending =
    (isOpenPendingEmpty ? 0 : openPendingCount) +
    (isInProgressEmpty ? 0 : inProgressCount) +
    (isPendingExpenseEmpty ? 0 : pendingExpenseCount);

  return (
    <div className="space-y-6">
      {/* ── SECTION 1: FINANS VE TAHSİLAT KOKPİTİ ── */}
      <div className="space-y-3">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2.5">
            <div className="w-7 h-7 rounded-lg bg-sky-50 text-sky-600 border border-sky-200/60 flex items-center justify-center shrink-0">
              <Receipt className="w-3.5 h-3.5" />
            </div>
            <h4 className="text-sm font-bold text-[#1A1A1A] tracking-tight">
              {t("agency_pm_dash_sec_finance")}
            </h4>
          </div>

          <div
            className={`inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-[11px] font-bold border ${totalFinancePending > 0
              ? "bg-[#FBF1DC] text-[#8A5206] border-[#8A5206]/20"
              : "bg-[#E6F3EA] text-[#2A6E43] border-[#2A6E43]/20"
              }`}
          >
            <span
              className={`w-1.5 h-1.5 rounded-full ${totalFinancePending > 0 ? "bg-amber-500" : "bg-emerald-500"
                }`}
            />
            <span>
              {totalFinancePending > 0
                ? `${totalFinancePending} ${t("agency_pm_dash_status_actions_pending")}`
                : t("agency_pm_dash_status_all_good")}
            </span>
          </div>
        </div>

        {/* 3 Apple-Style Action Bento Cards */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-3.5">
          {/* Card 1: Geciken Borçlar */}
          <div
            onClick={() => {
              setPaymentStatusFilter?.("overdue");
              setActiveTab("payments");
            }}
            className={`bg-white rounded-[10px] border border-[#E5E3DF] p-4 sm:p-5 shadow-2xs hover:border-[#8A8A8A] transition-all cursor-pointer relative overflow-hidden group ${isOverdueEmpty ? "opacity-75" : ""
              }`}
          >
            <AlertTriangle className="absolute -right-4 -bottom-4 w-32 h-32 text-[#A33C29] opacity-[0.03] group-hover:scale-105 transition-transform pointer-events-none" />

            <div className="flex items-center justify-between">
              <div className="w-9 h-9 rounded-lg bg-[#FBEAE6] text-[#A33C29] border border-rose-100 flex items-center justify-center shrink-0">
                <AlertTriangle className="w-4 h-4" />
              </div>
              <div className="w-7 h-7 rounded-full border border-[#E5E3DF] bg-slate-50 flex items-center justify-center text-[#666666] group-hover:text-[#A33C29] group-hover:bg-[#FBEAE6] transition-colors">
                <ChevronRight className="w-3.5 h-3.5" />
              </div>
            </div>

            <p className="text-xs font-semibold text-[#666666] mt-2.5">
              {t("agency_pm_dash_overdue_debts_title")}
            </p>
            <p className="text-lg sm:text-xl font-bold text-[#1A1A1A] tracking-tight mt-0.5">
              {formatCockpitCurrencyTotals(overdueTotals, t("agency_pm_dash_no_overdue"))}
            </p>

            <div className="space-y-1 mt-2.5">
              {isOverdueEmpty ? (
                <p className="text-xs text-[#666666] font-medium">
                  {t("agency_pm_dash_empty_tooltip_overdue")}
                </p>
              ) : (
                <>
                  <div className="flex items-start gap-1.5 text-xs font-medium text-[#4A4A4A]">
                    <span className="w-1.5 h-1.5 rounded-full mt-1.5 shrink-0 bg-rose-500" />
                    <span>
                      {overdueRentCount} {t("agency_pm_dash_rent")} (
                      {formatCockpitCurrencyTotals(overdueRentTotals, "0")})
                    </span>
                  </div>
                  <div className="flex items-start gap-1.5 text-xs font-medium text-[#4A4A4A]">
                    <span className="w-1.5 h-1.5 rounded-full mt-1.5 shrink-0 bg-rose-500" />
                    <span>
                      {overdueBillCount} {t("agency_pm_dash_bill")} (
                      {formatCockpitCurrencyTotals(overdueBillTotals, "0")})
                    </span>
                  </div>
                </>
              )}
            </div>

            <div className="mt-3 pt-2.5 border-t border-slate-100 flex items-center justify-between text-[11px] font-bold text-[#A33C29]">
              <span>
                {isOverdueEmpty
                  ? t("agency_pm_dash_no_action_needed")
                  : t("agency_pm_dash_overdue_action")}
              </span>
              <ArrowRight className="w-3 h-3 group-hover:translate-x-1 transition-transform" />
            </div>
          </div>

          {/* Card 2: Girilmeyen Faturalar (Unentered Bills) */}
          <div
            onClick={() => {
              setPaymentStatusFilter?.("all");
              setActiveTab("payments");
            }}
            className={`bg-white rounded-[10px] border border-[#E5E3DF] p-4 sm:p-5 shadow-2xs hover:border-[#8A8A8A] transition-all cursor-pointer relative overflow-hidden group ${isUnenteredBillsEmpty ? "opacity-75" : ""
              }`}
          >
            <Clock className="absolute -right-4 -bottom-4 w-32 h-32 text-[#8A5206] opacity-[0.03] group-hover:scale-105 transition-transform pointer-events-none" />

            <div className="flex items-center justify-between">
              <div className="w-9 h-9 rounded-lg bg-[#FBF1DC] text-[#8A5206] border border-amber-100 flex items-center justify-center shrink-0">
                <Clock className="w-4 h-4" />
              </div>
              <div className="w-7 h-7 rounded-full border border-[#E5E3DF] bg-slate-50 flex items-center justify-center text-[#666666] group-hover:text-[#8A5206] group-hover:bg-[#FBF1DC] transition-colors">
                <ChevronRight className="w-3.5 h-3.5" />
              </div>
            </div>

            <p className="text-xs font-semibold text-[#666666] mt-2.5">
              {t("unenteredBillsTitle")}
            </p>
            <p className="text-lg sm:text-xl font-bold text-[#1A1A1A] tracking-tight mt-0.5">
              {unenteredBillsCount} {t("agency_pm_dash_bill")}
            </p>

            <div className="space-y-1 mt-2.5">
              {isUnenteredBillsEmpty ? (
                <p className="text-xs text-[#666666] font-medium">
                  {t("agency_pm_dash_unentered_bills_empty")}
                </p>
              ) : (
                <>
                  <div className="flex items-start gap-1.5 text-xs font-medium text-[#4A4A4A]">
                    <span className="w-1.5 h-1.5 rounded-full mt-1.5 shrink-0 bg-amber-500" />
                    <span>{t("agency_pm_dash_unentered_bills_desc")}</span>
                  </div>
                  <div className="flex items-start gap-1.5 text-xs font-medium text-[#4A4A4A]">
                    <span className="w-1.5 h-1.5 rounded-full mt-1.5 shrink-0 bg-amber-500" />
                    <span>
                      {unenteredBillsPropCount} {t("financeFilterProperties")}
                    </span>
                  </div>
                </>
              )}
            </div>

            <div className="mt-3 pt-2.5 border-t border-slate-100 flex items-center justify-between text-[11px] font-bold text-[#8A5206]">
              <span>
                {isUnenteredBillsEmpty
                  ? t("agency_pm_dash_no_action_needed")
                  : t("agency_pm_dash_unentered_bills_action")}
              </span>
              <ArrowRight className="w-3 h-3 group-hover:translate-x-1 transition-transform" />
            </div>
          </div>

          {/* Card 3: Bekleyen Onaylar */}
          <div
            onClick={() => {
              setPaymentStatusFilter?.("awaiting");
              setActiveTab("payments");
            }}
            className={`bg-white rounded-[10px] border border-[#E5E3DF] p-4 sm:p-5 shadow-2xs hover:border-[#8A8A8A] transition-all cursor-pointer relative overflow-hidden group ${isPendingApprovalsEmpty ? "opacity-75" : ""
              }`}
          >
            <CheckCircle2 className="absolute -right-4 -bottom-4 w-32 h-32 text-[#1B5888] opacity-[0.03] group-hover:scale-105 transition-transform pointer-events-none" />

            <div className="flex items-center justify-between">
              <div className="w-9 h-9 rounded-lg bg-[#E5EEF6] text-[#1B5888] border border-blue-100 flex items-center justify-center shrink-0">
                <Receipt className="w-4 h-4" />
              </div>
              <div className="w-7 h-7 rounded-full border border-[#E5E3DF] bg-slate-50 flex items-center justify-center text-[#666666] group-hover:text-[#1B5888] group-hover:bg-[#E5EEF6] transition-colors">
                <ChevronRight className="w-3.5 h-3.5" />
              </div>
            </div>

            <p className="text-xs font-semibold text-[#666666] mt-2.5">
              {t("agency_pm_dash_pending_approvals_title")}
            </p>
            <p className="text-lg sm:text-xl font-bold text-[#1A1A1A] tracking-tight mt-0.5">
              {pendingApprovalsTotal} {t("agency_pm_dash_operation_unit")}
            </p>

            <div className="space-y-1 mt-2.5">
              {isPendingApprovalsEmpty ? (
                <p className="text-xs text-[#666666] font-medium">
                  {t("agency_pm_dash_empty_tooltip_pending_approvals")}
                </p>
              ) : (
                <>
                  <div className="flex items-start gap-1.5 text-xs font-medium text-[#4A4A4A]">
                    <span className="w-1.5 h-1.5 rounded-full mt-1.5 shrink-0 bg-[#1B5888]" />
                    <span>
                      {declaredRentsCount} {t("agency_pm_dash_rent")} • {declaredBillsCount}{" "}
                      {t("agency_pm_dash_bill")}
                      {declaredMaintenanceCount > 0
                        ? ` • ${declaredMaintenanceCount} ${t("agency_pm_dash_sec_maintenance")}`
                        : ""}
                    </span>
                  </div>
                  {disputedPaymentsCount > 0 && (
                    <div className="flex items-start gap-1.5 text-xs font-bold text-[#A33C29]">
                      <span className="w-1.5 h-1.5 rounded-full mt-1.5 shrink-0 bg-rose-600 animate-pulse" />
                      <span>
                        {disputedPaymentsCount} {t("agency_pm_dash_disputed_payments")}
                      </span>
                    </div>
                  )}
                </>
              )}
            </div>

            <div className="mt-3 pt-2.5 border-t border-slate-100 flex items-center justify-between text-[11px] font-bold text-[#12406A]">
              <span>
                {isPendingApprovalsEmpty
                  ? t("agency_pm_dash_no_action_needed")
                  : t("agency_pm_dash_pending_approvals_action")}
              </span>
              <ArrowRight className="w-3 h-3 group-hover:translate-x-1 transition-transform" />
            </div>
          </div>
        </div>
      </div>

      {/* ── SECTION 2: SÖZLEŞME VE PORTFÖY KOKPİTİ ── */}
      <div className="space-y-3">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2.5">
            <div className="w-7 h-7 rounded-lg bg-[#E5EEF6] text-[#1B5888] border border-[#1B5888]/20 flex items-center justify-center shrink-0">
              <FileText className="w-3.5 h-3.5" />
            </div>
            <h4 className="text-sm font-bold text-[#1A1A1A] tracking-tight">
              {t("agency_pm_dash_sec_portfolio")}
            </h4>
          </div>

          <div
            className={`inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-[11px] font-bold border ${totalContractsPending > 0
              ? "bg-[#FBF1DC] text-[#8A5206] border-[#8A5206]/20"
              : "bg-[#E6F3EA] text-[#2A6E43] border-[#2A6E43]/20"
              }`}
          >
            <span
              className={`w-1.5 h-1.5 rounded-full ${totalContractsPending > 0 ? "bg-amber-500" : "bg-emerald-500"
                }`}
            />
            <span>
              {totalContractsPending > 0
                ? `${totalContractsPending} ${t("agency_pm_dash_status_actions_pending")}`
                : t("agency_pm_dash_status_all_good")}
            </span>
          </div>
        </div>

        {/* 3 Apple-Style Action Bento Cards */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-3.5">
          {/* Card 4: Süresi Dolan Sözleşmeler */}
          <div
            onClick={() => {
              setPropOccupancyFilter?.("expired");
              setActiveTab("managed_properties");
            }}
            className={`bg-white rounded-[10px] border border-[#E5E3DF] p-4 sm:p-5 shadow-2xs hover:border-[#8A8A8A] transition-all cursor-pointer relative overflow-hidden group ${isExpiredEmpty ? "opacity-75" : ""
              }`}
          >
            <AlertTriangle className="absolute -right-4 -bottom-4 w-32 h-32 text-[#A33C29] opacity-[0.03] group-hover:scale-105 transition-transform pointer-events-none" />

            <div className="flex items-center justify-between">
              <div className="w-9 h-9 rounded-lg bg-[#FBEAE6] text-[#A33C29] border border-rose-100 flex items-center justify-center shrink-0">
                <AlertTriangle className="w-4 h-4" />
              </div>
              <div className="w-7 h-7 rounded-full border border-[#E5E3DF] bg-slate-50 flex items-center justify-center text-[#666666] group-hover:text-[#A33C29] group-hover:bg-[#FBEAE6] transition-colors">
                <ChevronRight className="w-3.5 h-3.5" />
              </div>
            </div>

            <p className="text-xs font-semibold text-[#666666] mt-2.5">
              {t("agency_pm_dash_expired_contracts_title")}
            </p>
            <p className="text-lg sm:text-xl font-bold text-[#1A1A1A] tracking-tight mt-0.5">
              {expiredCount} {t("agency_pm_dash_contract_unit")}
            </p>

            <div className="space-y-1 mt-2.5">
              {isExpiredEmpty ? (
                <p className="text-xs text-[#666666] font-medium">
                  {t("agency_pm_dash_empty_tooltip_expired")}
                </p>
              ) : (
                <>
                  <div className="flex items-start gap-1.5 text-xs font-medium text-[#4A4A4A]">
                    <span className="w-1.5 h-1.5 rounded-full mt-1.5 shrink-0 bg-rose-500" />
                    <span>
                      {expiredPendingAction} {t("agency_pm_dash_action_pending")}
                    </span>
                  </div>
                  <div className="flex items-start gap-1.5 text-xs font-medium text-[#4A4A4A]">
                    <span className="w-1.5 h-1.5 rounded-full mt-1.5 shrink-0 bg-rose-500" />
                    <span>
                      {expiredNegotiating} {t("agency_pm_dash_in_negotiation")}
                    </span>
                  </div>
                </>
              )}
            </div>

            <div className="mt-3 pt-2.5 border-t border-slate-100 flex items-center justify-between text-[11px] font-bold text-[#A33C29]">
              <span>
                {isExpiredEmpty
                  ? t("agency_pm_dash_no_action_needed")
                  : t("agency_pm_dash_expired_action")}
              </span>
              <ArrowRight className="w-3 h-3 group-hover:translate-x-1 transition-transform" />
            </div>
          </div>

          {/* Card 5: Bitişi Yaklaşanlar */}
          <div
            onClick={() => {
              setPropOccupancyFilter?.("expiring");
              setActiveTab("managed_properties");
            }}
            className={`bg-white rounded-[10px] border border-[#E5E3DF] p-4 sm:p-5 shadow-2xs hover:border-[#8A8A8A] transition-all cursor-pointer relative overflow-hidden group ${isExpiringEmpty ? "opacity-75" : ""
              }`}
          >
            <Clock className="absolute -right-4 -bottom-4 w-32 h-32 text-orange-600 opacity-[0.03] group-hover:scale-105 transition-transform pointer-events-none" />

            <div className="flex items-center justify-between">
              <div className="w-9 h-9 rounded-lg bg-orange-50 text-orange-600 border border-orange-100 flex items-center justify-center shrink-0">
                <Clock className="w-4 h-4" />
              </div>
              <div className="w-7 h-7 rounded-full border border-[#E5E3DF] bg-slate-50 flex items-center justify-center text-[#666666] group-hover:text-orange-600 group-hover:bg-orange-50 transition-colors">
                <ChevronRight className="w-3.5 h-3.5" />
              </div>
            </div>

            <p className="text-xs font-semibold text-[#666666] mt-2.5">
              {t("agency_pm_dash_expiring_contracts_title")}
            </p>
            <p className="text-lg sm:text-xl font-bold text-[#1A1A1A] tracking-tight mt-0.5">
              {expiringCount} {t("agency_pm_dash_contract_unit")}
              <span className="text-[11px] font-bold text-[#666666] ml-1.5">
                ({t("agency_pm_dash_days_60_badge")})
              </span>
            </p>

            <div className="space-y-1 mt-2.5">
              {isExpiringEmpty ? (
                <p className="text-xs text-[#666666] font-medium">
                  {t("agency_pm_dash_empty_tooltip_expiring")}
                </p>
              ) : (
                <>
                  <div className="flex items-start gap-1.5 text-xs font-medium text-[#4A4A4A]">
                    <span className="w-1.5 h-1.5 rounded-full mt-1.5 shrink-0 bg-orange-500" />
                    <span>
                      {t("agency_pm_dash_today")}: {t0} • {t("agency_pm_dash_days_1_15")}: {t15}
                    </span>
                  </div>
                  <div className="flex items-start gap-1.5 text-xs font-medium text-[#4A4A4A]">
                    <span className="w-1.5 h-1.5 rounded-full mt-1.5 shrink-0 bg-orange-500" />
                    <span>
                      {t("agency_pm_dash_days_16_30")}: {t30} • {t("agency_pm_dash_months_1_2")}:{" "}
                      {t60}
                    </span>
                  </div>
                </>
              )}
            </div>

            <div className="mt-3 pt-2.5 border-t border-slate-100 flex items-center justify-between text-[11px] font-bold text-orange-700">
              <span>
                {isExpiringEmpty
                  ? t("agency_pm_dash_no_action_needed")
                  : t("agency_pm_dash_expiring_action")}
              </span>
              <ArrowRight className="w-3 h-3 group-hover:translate-x-1 transition-transform" />
            </div>
          </div>

          {/* Card 6: Kontratsız Mülkler */}
          <div
            onClick={() => {
              setPropOccupancyFilter?.("vacant");
              setActiveTab("managed_properties");
            }}
            className={`bg-white rounded-[10px] border border-[#E5E3DF] p-4 sm:p-5 shadow-2xs hover:border-[#8A8A8A] transition-all cursor-pointer relative overflow-hidden group ${isWithoutContractsEmpty ? "opacity-75" : ""
              }`}
          >
            <Home className="absolute -right-4 -bottom-4 w-32 h-32 text-[#4A4A4A] opacity-[0.03] group-hover:scale-105 transition-transform pointer-events-none" />

            <div className="flex items-center justify-between">
              <div className="w-9 h-9 rounded-lg bg-slate-100 text-[#4A4A4A] border border-[#E5E3DF] flex items-center justify-center shrink-0">
                <Home className="w-4 h-4" />
              </div>
              <div className="w-7 h-7 rounded-full border border-[#E5E3DF] bg-slate-50 flex items-center justify-center text-[#666666] group-hover:text-[#1B5888] group-hover:bg-[#E5EEF6] transition-colors">
                <ChevronRight className="w-3.5 h-3.5" />
              </div>
            </div>

            <p className="text-xs font-semibold text-[#666666] mt-2.5">
              {t("agency_pm_dash_vacant_props_title")}
            </p>
            <p className="text-lg sm:text-xl font-bold text-[#1A1A1A] tracking-tight mt-0.5">
              {withoutContractsCount} {t("agency_pm_dash_property_unit")}
            </p>

            <div className="space-y-1 mt-2.5">
              {isWithoutContractsEmpty ? (
                <p className="text-xs text-[#666666] font-medium">
                  {t("agency_pm_dash_empty_tooltip_without_contracts")}
                </p>
              ) : (
                <>
                  <div className="flex items-start gap-1.5 text-xs font-medium text-[#4A4A4A]">
                    <span className="w-1.5 h-1.5 rounded-full mt-1.5 shrink-0 bg-slate-500" />
                    <span>
                      {vacantCount} {t("agency_pm_dash_vacant")}
                    </span>
                  </div>
                  <div className="flex items-start gap-1.5 text-xs font-medium text-[#4A4A4A]">
                    <span className="w-1.5 h-1.5 rounded-full mt-1.5 shrink-0 bg-slate-500" />
                    <span>
                      {invitePendingCount} {t("agency_pm_dash_invite_pending")}
                    </span>
                  </div>
                </>
              )}
            </div>

            <div className="mt-3 pt-2.5 border-t border-slate-100 flex items-center justify-between text-[11px] font-bold text-[#4A4A4A]">
              <span>
                {isWithoutContractsEmpty
                  ? t("agency_pm_dash_no_action_needed")
                  : t("agency_pm_dash_without_contracts_action")}
              </span>
              <ArrowRight className="w-3 h-3 group-hover:translate-x-1 transition-transform" />
            </div>
          </div>
        </div>
      </div>

      {/* ── SECTION 3: OPERASYON VE BAKIM KOKPİTİ ── */}
      <div className="space-y-3">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2.5">
            <div className="w-7 h-7 rounded-lg bg-purple-50 text-purple-600 border border-purple-200/60 flex items-center justify-center shrink-0">
              <Wrench className="w-3.5 h-3.5" />
            </div>
            <h4 className="text-sm font-bold text-[#1A1A1A] tracking-tight">
              {t("agency_pm_dash_sec_maintenance")}
            </h4>
          </div>

          <div
            className={`inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-[11px] font-bold border ${totalOperationsPending > 0
              ? "bg-[#FBF1DC] text-[#8A5206] border-[#8A5206]/20"
              : "bg-[#E6F3EA] text-[#2A6E43] border-[#2A6E43]/20"
              }`}
          >
            <span
              className={`w-1.5 h-1.5 rounded-full ${totalOperationsPending > 0 ? "bg-amber-500" : "bg-emerald-500"
                }`}
            />
            <span>
              {totalOperationsPending > 0
                ? `${totalOperationsPending} ${t("agency_pm_dash_status_actions_pending")}`
                : t("agency_pm_dash_status_all_good")}
            </span>
          </div>
        </div>

        {/* 3 Grid Cards: Card 7A (Açık & Bekleyen) + Card 7B (İşlemde & Atanmış) + Card 7C (Onay Bekleyen Masraflar) */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-3.5">
          {/* Card 7A: Açık ve Bekleyen Talepler */}
          <div
            onClick={() => {
              setMaintStatusFilter?.("open");
              setActiveTab("maintenance");
            }}
            className={`bg-white rounded-[10px] border border-[#E5E3DF] p-4 sm:p-5 shadow-2xs hover:border-[#8A8A8A] transition-all cursor-pointer relative overflow-hidden group ${isOpenPendingEmpty ? "opacity-75" : ""
              }`}
          >
            <Wrench className="absolute -right-4 -bottom-4 w-32 h-32 text-purple-600 opacity-[0.03] group-hover:scale-105 transition-transform pointer-events-none" />

            <div className="flex items-center justify-between">
              <div className="w-9 h-9 rounded-lg bg-purple-50 text-purple-600 border border-purple-100 flex items-center justify-center shrink-0">
                <Wrench className="w-4 h-4" />
              </div>
              <div className="w-7 h-7 rounded-full border border-[#E5E3DF] bg-slate-50 flex items-center justify-center text-[#666666] group-hover:text-purple-600 group-hover:bg-purple-50 transition-colors">
                <ChevronRight className="w-3.5 h-3.5" />
              </div>
            </div>

            <p className="text-xs font-semibold text-[#666666] mt-2.5">
              {t("agency_pm_dash_card_open_tickets_title")}
            </p>
            <p className="text-lg sm:text-xl font-bold text-[#1A1A1A] tracking-tight mt-0.5">
              {openPendingCount} {t("agency_pm_dash_request_unit")}
            </p>

            <div className="space-y-1 mt-2.5">
              {isOpenPendingEmpty ? (
                <p className="text-xs text-[#666666] font-medium">
                  {t("agency_pm_dash_empty_open_tickets")}
                </p>
              ) : (
                <>
                  <div className="flex items-start gap-1.5 text-xs font-medium text-[#4A4A4A]">
                    <span className="w-1.5 h-1.5 rounded-full mt-1.5 shrink-0 bg-purple-500" />
                    <span>
                      {openPendingUrgent} {t("agency_maint_prio_urgent")},{" "}
                      {openPendingHigh} {t("agency_maint_prio_high")},{" "}
                      {openPendingNormal} {t("agency_maint_prio_normal")}
                    </span>
                  </div>
                  {oldestOpenPendingDays > 0 && (
                    <div className="flex items-start gap-1.5 text-xs font-medium text-[#4A4A4A]">
                      <span className="w-1.5 h-1.5 rounded-full mt-1.5 shrink-0 bg-purple-500" />
                      <span>
                        {t("agency_pm_dash_oldest_days").replace("{d}", String(oldestOpenPendingDays))}
                      </span>
                    </div>
                  )}
                </>
              )}
            </div>

            <div className="mt-3 pt-2.5 border-t border-slate-100 flex items-center justify-between text-[11px] font-bold text-purple-700">
              <span>
                {isOpenPendingEmpty
                  ? t("agency_pm_dash_no_action_needed")
                  : t("agency_pm_dash_card_open_tickets_action")}
              </span>
              <ArrowRight className="w-3 h-3 group-hover:translate-x-1 transition-transform" />
            </div>
          </div>

          {/* Card 7B: İşlemde ve Atanmış Talepler */}
          <div
            onClick={() => {
              setMaintStatusFilter?.("in_progress");
              setActiveTab("maintenance");
            }}
            className={`bg-white rounded-[10px] border border-[#E5E3DF] p-4 sm:p-5 shadow-2xs hover:border-[#8A8A8A] transition-all cursor-pointer relative overflow-hidden group ${isInProgressEmpty ? "opacity-75" : ""
              }`}
          >
            <Activity className="absolute -right-4 -bottom-4 w-32 h-32 text-sky-600 opacity-[0.03] group-hover:scale-105 transition-transform pointer-events-none" />

            <div className="flex items-center justify-between">
              <div className="w-9 h-9 rounded-lg bg-sky-50 text-sky-600 border border-sky-100 flex items-center justify-center shrink-0">
                <Activity className="w-4 h-4" />
              </div>
              <div className="w-7 h-7 rounded-full border border-[#E5E3DF] bg-slate-50 flex items-center justify-center text-[#666666] group-hover:text-sky-600 group-hover:bg-sky-50 transition-colors">
                <ChevronRight className="w-3.5 h-3.5" />
              </div>
            </div>

            <p className="text-xs font-semibold text-[#666666] mt-2.5">
              {t("agency_pm_dash_card_in_progress_title")}
            </p>
            <p className="text-lg sm:text-xl font-bold text-[#1A1A1A] tracking-tight mt-0.5">
              {inProgressCount} {t("agency_pm_dash_request_unit")}
            </p>

            <div className="space-y-1 mt-2.5">
              {isInProgressEmpty ? (
                <p className="text-xs text-[#666666] font-medium">
                  {t("agency_pm_dash_empty_in_progress")}
                </p>
              ) : (
                <>
                  <div className="flex items-start gap-1.5 text-xs font-medium text-[#4A4A4A]">
                    <span className="w-1.5 h-1.5 rounded-full mt-1.5 shrink-0 bg-sky-500" />
                    <span>
                      {inProgressUrgent} {t("agency_maint_prio_urgent")},{" "}
                      {inProgressHigh} {t("agency_maint_prio_high")},{" "}
                      {inProgressNormal} {t("agency_maint_prio_normal")}
                    </span>
                  </div>
                  <div className="flex items-start gap-1.5 text-xs font-medium text-[#666666]">
                    <span className="w-1.5 h-1.5 rounded-full mt-1.5 shrink-0 bg-slate-400" />
                    <span>{t("agency_pm_dash_card_in_progress_desc")}</span>
                  </div>
                </>
              )}
            </div>

            <div className="mt-3 pt-2.5 border-t border-slate-100 flex items-center justify-between text-[11px] font-bold text-sky-700">
              <span>
                {isInProgressEmpty
                  ? t("agency_pm_dash_no_action_needed")
                  : t("agency_pm_dash_card_in_progress_action")}
              </span>
              <ArrowRight className="w-3 h-3 group-hover:translate-x-1 transition-transform" />
            </div>
          </div>

          {/* Card 7C: Onay Bekleyen Masraflar */}
          <div
            onClick={() => {
              setMaintStatusFilter?.("pending_approval");
              setActiveTab("maintenance");
            }}
            className={`bg-white rounded-[10px] border border-[#E5E3DF] p-4 sm:p-5 shadow-2xs hover:border-[#8A8A8A] transition-all cursor-pointer relative overflow-hidden group ${isPendingExpenseEmpty ? "opacity-75" : ""
              }`}
          >
            <Receipt className="absolute -right-4 -bottom-4 w-32 h-32 text-[#8A5206] opacity-[0.03] group-hover:scale-105 transition-transform pointer-events-none" />

            <div className="flex items-center justify-between">
              <div className="w-9 h-9 rounded-lg bg-[#FBF1DC] text-[#8A5206] border border-amber-100 flex items-center justify-center shrink-0">
                <Receipt className="w-4 h-4" />
              </div>
              <div className="w-7 h-7 rounded-full border border-[#E5E3DF] bg-slate-50 flex items-center justify-center text-[#666666] group-hover:text-[#8A5206] group-hover:bg-[#FBF1DC] transition-colors">
                <ChevronRight className="w-3.5 h-3.5" />
              </div>
            </div>

            <p className="text-xs font-semibold text-[#666666] mt-2.5">
              {t("agency_pm_dash_card_pending_expense_title")}
            </p>
            <p className="text-lg sm:text-xl font-bold text-[#1A1A1A] tracking-tight mt-0.5">
              {formatCockpitCurrencyTotals(pendingExpenseTotals, t("agency_pm_dash_empty_pending_expense"))}
            </p>

            <div className="space-y-1 mt-2.5">
              {isPendingExpenseEmpty ? (
                <p className="text-xs text-[#666666] font-medium">
                  {t("agency_pm_dash_empty_pending_expense")}
                </p>
              ) : (
                <div className="flex items-start gap-1.5 text-xs font-medium text-[#4A4A4A]">
                  <span className="w-1.5 h-1.5 rounded-full mt-1.5 shrink-0 bg-amber-500" />
                  <span>
                    {pendingExpenseCount} {t("agency_pm_dash_request_unit")} (
                    {t("agency_pm_dash_card_pending_expense_desc")})
                  </span>
                </div>
              )}
            </div>

            <div className="mt-3 pt-2.5 border-t border-slate-100 flex items-center justify-between text-[11px] font-bold text-[#8A5206]">
              <span>
                {isPendingExpenseEmpty
                  ? t("agency_pm_dash_no_action_needed")
                  : t("agency_pm_dash_card_pending_expense_action")}
              </span>
              <ArrowRight className="w-3 h-3 group-hover:translate-x-1 transition-transform" />
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
