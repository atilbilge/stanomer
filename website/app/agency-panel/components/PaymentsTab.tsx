"use client";

import React, { useState, useMemo } from "react";
import {
  AlertCircle,
  AlertTriangle,
  ArrowDownUp,
  ArrowLeftRight,
  Building,
  Building2,
  Calendar,
  Check,
  CheckCircle2,
  ChevronDown,
  ChevronRight,
  ChevronUp,
  Clock,
  Eye,
  FileBarChart,
  FileQuestion,
  FileSpreadsheet,
  FileText,
  HandCoins,
  Home,
  Layers,
  LayoutGrid,
  MapPin,
  MoreHorizontal,
  Phone,
  Receipt,
  RefreshCw,
  RotateCcw,
  Search,
  Share2,
  ShieldCheck,
  SlidersHorizontal,
  TableProperties,
  Tag,
  User,
  UserCheck,
  Wrench,
  X,
  Info,
  Printer,
  Copy,
  CheckCheck,
} from "lucide-react";
import {
  AgencyRentPayment,
  AgencyManagedProperty,
  AgencyMaintenanceRequest,
  AgencyContract,
} from "../types";
import { processRentPayments } from "../utils";
import { PaymentTypeIconBadge } from "../categoryAndPaymentIcons";

export interface PaymentsTabProps {
  payments: AgencyRentPayment[];
  loadingPayments: boolean;
  paymentStats: {
    collected: number;
    awaitingApproval: number;
    overdue: number;
    totalVolume: number;
    count: number;
  };
  filteredPayments: AgencyRentPayment[];
  processingPaymentId: string | null;
  paymentStatusFilter: "all" | "awaiting" | "overdue" | "paid";
  setPaymentStatusFilter: (status: "all" | "awaiting" | "overdue" | "paid") => void;
  paymentSearchQuery: string;
  setPaymentSearchQuery: (q: string) => void;
  selectedReceiptPayment: AgencyRentPayment | null;
  setSelectedReceiptPayment: (p: AgencyRentPayment | null) => void;
  handleApprovePayment: (p: AgencyRentPayment) => void;
  handleRejectPayment: (p: AgencyRentPayment) => void;
  isDemoMode: boolean;
  activeLocale: string;
  agencyName?: string;
  t: (key: string) => string;
  tSafe: (key: string, replacements?: Record<string, string | number>) => string;
  managedProperties?: AgencyManagedProperty[];
  maintenanceRequests?: AgencyMaintenanceRequest[];
  contracts?: AgencyContract[];
  onInspectPayment?: (payment: AgencyRentPayment) => void;
}

export default function PaymentsTab({
  payments,
  loadingPayments,
  paymentStats,
  filteredPayments,
  processingPaymentId,
  paymentStatusFilter,
  setPaymentStatusFilter,
  paymentSearchQuery,
  setPaymentSearchQuery,
  selectedReceiptPayment,
  setSelectedReceiptPayment,
  handleApprovePayment,
  handleRejectPayment,
  isDemoMode,
  activeLocale,
  agencyName,
  t,
  tSafe,
  managedProperties = [],
  maintenanceRequests = [],
  contracts = [],
  onInspectPayment,
}: PaymentsTabProps) {
  // 1. Sub-Tab (0: Action Required, 1: Report)
  const [financeSubTab, setFinanceSubTab] = useState<0 | 1>(0);

  // 2. Selected Segment in each sub-tab
  const [selectedSegment, setSelectedSegment] = useState<number>(0);

  // 3. Search & Detailed Filters state
  const [isFilterExpanded, setIsFilterExpanded] = useState<boolean>(true);
  const [searchQuery, setSearchQuery] = useState<string>("");
  const [periodPreset, setPeriodPreset] = useState<"all_time" | "this_month" | "last_month" | "this_year">("all_time");
  const [selectedLandlord, setSelectedLandlord] = useState<string>("all");
  const [selectedPropertyId, setSelectedPropertyId] = useState<string>("all");
  const [selectedType, setSelectedType] = useState<string>("all");
  const [groupBy, setGroupBy] = useState<"none" | "landlord" | "city" | "status">("none");
  const [sortBy, setSortBy] = useState<"newest" | "oldest" | "amount_desc" | "amount_asc" | "name_asc" | "landlord_asc">("newest");
  const [viewMode, setViewMode] = useState<"table" | "grid">("table");

  // 4. Modals state
  const [isExportModalOpen, setIsExportModalOpen] = useState(false);
  const [copiedExport, setCopiedExport] = useState(false);
  const [viewingReceiptUrl, setViewingReceiptUrl] = useState<string | null>(null);

  // Property Map lookup
  const propertiesMap = useMemo(() => {
    const map: Record<string, AgencyManagedProperty> = {};
    managedProperties.forEach((p) => {
      map[p.id] = p;
    });
    return map;
  }, [managedProperties]);

  // Landlord List for filter dropdown
  const landlordList = useMemo(() => {
    const set = new Set<string>();
    managedProperties.forEach((p) => {
      if (p.landlord_name && p.landlord_name.trim()) {
        set.add(p.landlord_name.trim());
      }
    });
    return Array.from(set).sort();
  }, [managedProperties]);

  // Today reference
  const todayStr = useMemo(() => new Date().toISOString().split("T")[0], []);

  // Date Formatter: dd MMM yyyy (e.g. 01 Nov 2026) matching Flutter DateFormat('dd MMM yyyy')
  const formatDueDate = (dateStr?: string | null) => {
    if (!dateStr) return "—";
    const d = new Date(dateStr);
    if (isNaN(d.getTime())) return "—";
    const day = String(d.getDate()).padStart(2, "0");
    const month = d.toLocaleDateString(activeLocale, { month: "short" });
    const year = d.getFullYear();
    return `${day} ${month} ${year}`;
  };

  const formatPaymentTitle = (title?: string | null) => {
    if (!title) return t("agency_financials_rent");
    const lower = title.trim().toLowerCase();
    if (lower === "kira" || lower === "rent" || lower === "kirija" || lower === "кирија") {
      return t("agency_financials_rent");
    }
    return title;
  };

  // Filter Helper: checks if a date falls in periodPreset
  // Filter Helper: checks if a date falls in periodPreset (100% Flutter Parity)
  const isDateInPeriod = (dateStr?: string, period: string = "all_time") => {
    if (period === "all_time" || !dateStr) return true;
    let year: number;
    let month: number;
    if (/^\d{4}-\d{2}/.test(dateStr)) {
      const parts = dateStr.split("-");
      year = parseInt(parts[0], 10);
      month = parseInt(parts[1], 10) - 1;
    } else {
      const d = new Date(dateStr);
      year = d.getFullYear();
      month = d.getMonth();
    }
    const now = new Date();
    if (period === "this_month") {
      return year === now.getFullYear() && month === now.getMonth();
    }
    if (period === "last_month") {
      const lastMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1);
      return year === lastMonth.getFullYear() && month === lastMonth.getMonth();
    }
    if (period === "this_year") {
      return year === now.getFullYear();
    }
    return true;
  };

  // Helper: check if item is a rent payment (Flutter SSOT)
  const isRent = (item: AgencyRentPayment) => {
    const t = (item.title || "").trim().toLowerCase();
    return t === "kira" || t === "rent" || t.includes("kira") || t.includes("zakupnina") || t.includes("kirija");
  };

  // Helper: check if item is a maintenance expense (Flutter SSOT)
  const isMaintenance = (item: AgencyRentPayment) => item.is_maintenance === true;

  // Check if active filters exist
  const hasActiveFilters = useMemo(() => {
    return (
      searchQuery.trim().length > 0 ||
      selectedLandlord !== "all" ||
      selectedPropertyId !== "all" ||
      selectedType !== "all" ||
      groupBy !== "none" ||
      sortBy !== "newest" ||
      (financeSubTab === 1 && periodPreset !== "this_month")
    );
  }, [searchQuery, selectedLandlord, selectedPropertyId, selectedType, groupBy, sortBy, financeSubTab, periodPreset]);

  // ── Group and deduplicate payments by property, month & title (EXACT Flutter Parity from agency_dashboard_screen.dart:176-215) ──
  const deduplicatedPayments = useMemo(() => {
    return processRentPayments(payments);
  }, [payments]);

  // Scoped payments matching global filters (Search, Landlord, Property, Type, and Period for Report tab)
  const scopedPayments = useMemo(() => {
    return deduplicatedPayments.filter((p) => {
      // 1. Period filter (only applied in Report tab, exactly like Flutter: if (_financeSubTab != 0))
      // Flutter SSOT (agency_dashboard_screen.dart:2414): due_date ?? declared_at ?? created_at (NEVER paid_at)
      if (financeSubTab === 1 && periodPreset !== "all_time") {
        const dateToCheck = p.due_date || p.declared_at || p.created_at;
        if (!isDateInPeriod(dateToCheck, periodPreset)) return false;
      }

      // 2. Search query
      if (searchQuery.trim()) {
        const q = searchQuery.toLowerCase().trim();
        const prop = propertiesMap[p.property_id];
        const matches =
          (p.title && p.title.toLowerCase().includes(q)) ||
          (p.tenant_name && p.tenant_name.toLowerCase().includes(q)) ||
          (p.property_title && p.property_title.toLowerCase().includes(q)) ||
          (prop?.title && prop.title.toLowerCase().includes(q)) ||
          (prop?.landlord_name && prop.landlord_name.toLowerCase().includes(q)) ||
          (prop?.city && prop.city.toLowerCase().includes(q));
        if (!matches) return false;
      }

      // 3. Landlord
      if (selectedLandlord !== "all") {
        const prop = propertiesMap[p.property_id];
        if (prop?.landlord_name !== selectedLandlord) return false;
      }

      // 4. Property
      if (selectedPropertyId !== "all" && p.property_id !== selectedPropertyId) return false;

      // 5. Type (100% Flutter Parity)
      if (selectedType !== "all") {
        if (selectedType === "rent" && (!isRent(p) || isMaintenance(p))) return false;
        if ((selectedType === "bill" || selectedType === "bills") && (isRent(p) || isMaintenance(p))) return false;
        if (selectedType === "maintenance" && !isMaintenance(p)) return false;
      }

      return true;
    });
  }, [
    deduplicatedPayments,
    financeSubTab,
    periodPreset,
    searchQuery,
    selectedLandlord,
    selectedPropertyId,
    selectedType,
    propertiesMap,
  ]);

  // KPI Calculations for Action Required (Tab 0) - EXACT FLUTTER SSOT (includes declared & disputed)
  const pendingApprovalsList = useMemo(() => {
    return scopedPayments.filter(
      (p) =>
        p.status === "disputed" ||
        (p.is_pending_approval ??
          (p.status === "declared" || (p.status === "pending" && Boolean(p.declared_at))))
    );
  }, [scopedPayments]);

  const unenteredBillsList = useMemo(() => {
    return scopedPayments.filter((item) => {
      const status = item.status || "pending";
      if (status === "paid" || status === "declared" || status === "disputed") return false;
      const receiverType = item.receiver_type || "owner";
      const isOwnerExpense = (receiverType === "owner" || receiverType === "included") && !isRent(item);
      if (!isOwnerExpense) return false;

      const amt = Number(item.amount) || 0;
      return amt === 0;
    });
  }, [scopedPayments]);

  const overduePaymentsList = useMemo(() => {
    const now = new Date();
    now.setHours(0, 0, 0, 0);

    return scopedPayments.filter((item) => {
      if (item.is_overdue !== undefined) return item.is_overdue;
      const status = item.status || "pending";
      if (status === "declared" || status === "disputed" || status === "paid") return false;
      const amt = Number(item.amount) || 0;
      if (amt <= 0) return false;

      if (status === "overdue") return true;
      if (status === "pending" && item.due_date) {
        const dueDate = new Date(item.due_date);
        if (dueDate < now) return true;
      }
      return false;
    });
  }, [scopedPayments]);

  const unpaidMaintenanceList = useMemo(() => {
    return scopedPayments.filter((p) => p.is_unpaid_maintenance ?? (p.is_maintenance && p.status !== "paid"));
  }, [scopedPayments]);

  const tenantOffsetsList = useMemo(() => {
    return scopedPayments.filter((p) => p.is_tenant_offset ?? (p.owner_note && p.owner_note.toLowerCase().includes("mahsup")));
  }, [scopedPayments]);

  // KPI Calculations for Report (Tab 1) - Scoped by Period (e.g. "This Month") - 100% Flutter Parity
  const rentCollectedList = useMemo(() => {
    return scopedPayments.filter((p) => {
      if (p.status !== "paid") return false;
      return isRent(p);
    });
  }, [scopedPayments]);

  const billsToInstitutionsList = useMemo(() => {
    return scopedPayments.filter((p) => {
      if (p.status !== "paid") return false;
      if (isRent(p)) return false;
      if (isMaintenance(p)) return false;
      return p.receiver_type === "included";
    });
  }, [scopedPayments]);

  const maintenancePaidList = useMemo(() => {
    return scopedPayments.filter((p) => {
      if (!isMaintenance(p)) return false;
      return p.status === "paid" || (p as any).payment_status === "paid";
    });
  }, [scopedPayments]);

  const maintenanceOwedList = useMemo(() => {
    return scopedPayments.filter((p) => {
      if (!isMaintenance(p)) return false;
      return p.status !== "paid" && (p.payment_method === "agency" || p.owner_note?.toLowerCase().includes("acente"));
    });
  }, [scopedPayments]);

  // Check if any property or payment involves included expenses (for card visibility, 100% Flutter parity)
  const hasIncludedExpenses = useMemo(() => {
    return scopedPayments.some((p) => p.receiver_type === "included" || p.is_bills_to_institutions);
  }, [scopedPayments]);

  const formatKpiAmount = (list: AgencyRentPayment[]) => {
    const totalsByCurrency = new Map<string, number>();
    for (const p of list) {
      const amt = Number(p.amount) || 0;
      if (amt === 0) continue;
      const cur = (p.currency || "EUR").toUpperCase();
      totalsByCurrency.set(cur, (totalsByCurrency.get(cur) || 0) + amt);
    }
    if (totalsByCurrency.size === 0) return "0";

    const orderedCurrencies = Array.from(totalsByCurrency.keys()).sort((a, b) => {
      if (a === "EUR") return -1;
      if (b === "EUR") return 1;
      return a.localeCompare(b);
    });

    return orderedCurrencies
      .map((cur) => {
        const val = totalsByCurrency.get(cur) || 0;
        const formatted = val.toLocaleString("de-DE", {
          minimumFractionDigits: 2,
          maximumFractionDigits: 2,
        });
        return `${formatted} ${cur === "EUR" ? "€" : cur}`;
      })
      .join(" + ");
  };

  // Filtered List based on Sub-Tab and Segment
  const displayedPayments = useMemo(() => {
    let list: AgencyRentPayment[] = [];

    // 1. Base list determined by Sub-Tab and Segment
    if (financeSubTab === 0) {
      // Action Required
      if (selectedSegment === 0) list = pendingApprovalsList;
      else if (selectedSegment === 1) list = unenteredBillsList;
      else if (selectedSegment === 2) list = overduePaymentsList;
      else if (selectedSegment === 8) list = unpaidMaintenanceList;
      else if (selectedSegment === 10) list = tenantOffsetsList;
      else list = [...pendingApprovalsList, ...overduePaymentsList, ...unenteredBillsList];
    } else {
      // Report
      if (selectedSegment === 3) list = rentCollectedList;
      else if (selectedSegment === 5) list = billsToInstitutionsList;
      else if (selectedSegment === 6) list = maintenancePaidList;
      else if (selectedSegment === 7) list = maintenanceOwedList;
      else list = rentCollectedList;
    }

    // 2. Sort
    const sorted = [...list];
    sorted.sort((a, b) => {
      switch (sortBy) {
        case "newest": {
          const cmp = (b.due_date || "").localeCompare(a.due_date || "");
          if (cmp !== 0) return cmp;
          const propA = propertiesMap[a.property_id];
          const propB = propertiesMap[b.property_id];
          if (propA?.created_at && propB?.created_at) {
            return propA.created_at.localeCompare(propB.created_at);
          }
          return (a.created_at || "").localeCompare(b.created_at || "");
        }
        case "oldest": {
          const cmp = (a.due_date || "").localeCompare(b.due_date || "");
          if (cmp !== 0) return cmp;
          return (a.created_at || "").localeCompare(b.created_at || "");
        }
        case "amount_desc":
          return (b.amount || 0) - (a.amount || 0);
        case "amount_asc":
          return (a.amount || 0) - (b.amount || 0);
        case "name_asc":
          return (a.property_title || "").localeCompare(b.property_title || "");
        case "landlord_asc": {
          const lA = propertiesMap[a.property_id]?.landlord_name || "";
          const lB = propertiesMap[b.property_id]?.landlord_name || "";
          return lA.localeCompare(lB);
        }
        default:
          return 0;
      }
    });

    return sorted;
  }, [
    financeSubTab,
    selectedSegment,
    pendingApprovalsList,
    unenteredBillsList,
    overduePaymentsList,
    unpaidMaintenanceList,
    tenantOffsetsList,
    rentCollectedList,
    billsToInstitutionsList,
    maintenancePaidList,
    maintenanceOwedList,
    sortBy,
    propertiesMap,
  ]);

  // Grouped Payments
  const groupedPayments = useMemo(() => {
    if (groupBy === "none") {
      return [{ groupName: null, items: displayedPayments }];
    }
    const map = new Map<string, AgencyRentPayment[]>();
    displayedPayments.forEach((p) => {
      const prop = propertiesMap[p.property_id];
      let g = "";
      if (groupBy === "landlord") {
        g = prop?.landlord_name || t("vacantLabel");
      } else if (groupBy === "city") {
        g = prop?.city || "-";
      } else if (groupBy === "status") {
        g = p.status === "paid" ? t("statusClean") : (p.status === "overdue" ? t("statusOverdue") : t("statusPending"));
      }
      if (!map.has(g)) map.set(g, []);
      map.get(g)!.push(p);
    });
    return Array.from(map.entries()).map(([groupName, items]) => ({
      groupName,
      items,
    }));
  }, [displayedPayments, groupBy, propertiesMap, t]);

  // Totals calculations
  const totalVolumeInDisplay = useMemo(() => {
    return displayedPayments.reduce((acc, p) => acc + (p.amount || 0), 0);
  }, [displayedPayments]);

  // Effective Report Titles matching Flutter AgencyFinanceReportSheet
  const effectivePeriodTitle = useMemo(() => {
    switch (periodPreset) {
      case "this_month":
        return t("periodThisMonth");
      case "last_month":
        return t("periodLastMonth");
      case "this_year":
        return t("periodThisYear");
      default:
        return t("periodAllTime");
    }
  }, [periodPreset, t]);

  const effectiveSegmentTitle = useMemo(() => {
    if (financeSubTab === 0) {
      switch (selectedSegment) {
        case 0:
          return t("financePendingApprovals");
        case 1:
          return t("unenteredBillsTitle");
        case 2:
          return t("financeOverduePayments");
        case 8:
          return t("unpaidMaintenanceTitle");
        case 9:
          return t("unpaidBillsToInstitutionsTitle");
        case 10:
          return t("financeTenantOffsets");
        default:
          return t("financeSubTabActionRequired");
      }
    } else {
      switch (selectedSegment) {
        case 3:
          return t("financeRentCollected");
        case 5:
          return t("financeBillsToInstitutions");
        case 6:
          return t("financeMaintenancePaid");
        case 7:
          return t("financeMaintenanceOwedToAgency");
        default:
          return t("financeRentCollected");
      }
    }
  }, [financeSubTab, selectedSegment, t]);

  // Generate plain text report matching Flutter AgencyFinanceReportSheet
  const generatePlainTextReport = () => {
    const displayAgency = agencyName || "Stanomer";
    const totalsStr = formatKpiAmount(displayedPayments);
    const now = new Date();
    const day = String(now.getDate()).padStart(2, "0");
    const month = String(now.getMonth() + 1).padStart(2, "0");
    const year = now.getFullYear();
    const hours = String(now.getHours()).padStart(2, "0");
    const minutes = String(now.getMinutes()).padStart(2, "0");
    const nowFormatted = `${day}.${month}.${year} ${hours}:${minutes}`;

    let text = `📊 STANOMER | ${(t("exportReportSheetTitle") || "FİNANSAL RAPOR").toUpperCase()}\n`;
    text += `━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n`;
    text += `🏢 ${t("agency") || "Acente"}: ${displayAgency}\n`;
    text += `📅 ${t("period") || "Dönem"}: ${effectivePeriodTitle}\n`;
    text += `📂 ${t("filter") || "Filtre / Tür"}: ${effectiveSegmentTitle}\n`;
    text += `🕒 ${t("reportDate") || "Rapor Tarihi"}: ${nowFormatted}\n\n`;
    text += `ÖZET BİLGİLER\n`;
    text += `• Toplam İşlem: ${displayedPayments.length}\n`;
    text += `• Toplam Tutar: ${totalsStr}\n\n`;
    text += `İŞLEM DETAYLARI\n`;

    if (displayedPayments.length === 0) {
      text += `Seçili dönem için işlem bulunamadı.\n`;
    } else {
      displayedPayments.forEach((p, idx) => {
        const prop = propertiesMap[p.property_id];
        const propTitle = p.property_title || prop?.title || "Mülk";
        const propAddr = p.property_address || prop?.address || "";
        const landlord = p.landlord_name || prop?.landlord_name || "-";
        const tenant = p.tenant_name || "-";
        const amt = Number(p.amount) || 0;
        const curSym = p.currency === "RSD" ? "RSD" : "€";
        const amtStr = `${amt.toLocaleString("de-DE", { minimumFractionDigits: 2, maximumFractionDigits: 2 })} ${curSym}`;
        const dueDate = p.due_date ? formatDueDate(p.due_date) : "-";

        let statusLabel = "🕒 BEKLEMEDE";
        if (p.status === "paid") statusLabel = "✅ ÖDENDİ";
        else if (p.status === "declared") statusLabel = "⏳ BİLDİRİLDİ";
        else if (p.status === "disputed") statusLabel = "⚠️ İTİRAZLI";

        text += `${idx + 1}. ${propTitle}${propAddr ? ` (${propAddr})` : ""}\n`;
        text += `   • ${formatPaymentTitle(p.title)}: ${amtStr} | Vade: ${dueDate}\n`;
        text += `   • Ev Sahibi: ${landlord} | Kiracı: ${tenant}\n`;
        text += `   • Durum: ${statusLabel}\n\n`;
      });
    }

    text += `━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n`;
    text += `stanomer.online aracılığıyla oluşturulmuştur\n`;
    return text;
  };

  // Generate executive HTML print report matching Flutter Web openHtmlPrintView
  const generateHtmlReport = () => {
    const displayAgency = agencyName || "Stanomer";
    const totalsStr = formatKpiAmount(displayedPayments);
    const now = new Date();
    const day = String(now.getDate()).padStart(2, "0");
    const month = String(now.getMonth() + 1).padStart(2, "0");
    const year = now.getFullYear();
    const hours = String(now.getHours()).padStart(2, "0");
    const minutes = String(now.getMinutes()).padStart(2, "0");
    const nowFormatted = `${day}.${month}.${year} ${hours}:${minutes}`;

    const rowsHtml = displayedPayments.length === 0
      ? `<tr><td colspan="8" style="text-align:center; padding: 24px; color:#64748b;">Seçili dönem için işlem bulunamadı.</td></tr>`
      : displayedPayments.map((p, idx) => {
          const prop = propertiesMap[p.property_id];
          const propTitle = p.property_title || prop?.title || "Mülk";
          const propAddr = p.property_address || prop?.address || "";
          const landlord = p.landlord_name || prop?.landlord_name || "-";
          const tenant = p.tenant_name || "-";
          const amt = Number(p.amount) || 0;
          const curSym = p.currency === "RSD" ? "RSD" : "€";
          const amtStr = `${amt.toLocaleString("de-DE", { minimumFractionDigits: 2, maximumFractionDigits: 2 })} ${curSym}`;
          const dueDate = p.due_date ? formatDueDate(p.due_date) : "-";

          let badgeClass = "badge-pending";
          let statusText = "Beklemede";
          if (p.status === "paid") {
            badgeClass = "badge-paid";
            statusText = "Ödendi";
          } else if (p.status === "declared") {
            badgeClass = "badge-declared";
            statusText = "Bildirildi";
          } else if (p.status === "disputed") {
            badgeClass = "badge-disputed";
            statusText = "İtirazlı";
          }

          return `<tr>
            <td style="text-align:center; color:#64748b;">${idx + 1}</td>
            <td><strong>${propTitle}</strong><br><span style="font-size:11px; color:#64748b;">${propAddr}</span></td>
            <td>${formatPaymentTitle(p.title)}</td>
            <td>${landlord}</td>
            <td>${tenant}</td>
            <td style="text-align:center;">${dueDate}</td>
            <td style="text-align:right; font-weight:700;">${amtStr}</td>
            <td style="text-align:center;"><span class="badge ${badgeClass}">${statusText}</span></td>
          </tr>`;
        }).join("");

    return `<!DOCTYPE html>
<html lang="${activeLocale}">
<head>
  <meta charset="UTF-8">
  <title>Rapor - ${displayAgency} (${effectivePeriodTitle})</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
      margin: 0;
      padding: 32px 40px;
      color: #0f172a;
      background-color: #ffffff;
      -webkit-print-color-adjust: exact;
      print-color-adjust: exact;
    }
    .header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      border-bottom: 2px solid #2563EB;
      padding-bottom: 16px;
      margin-bottom: 24px;
    }
    .agency-title {
      font-size: 24px;
      font-weight: 800;
      color: #2563EB;
      margin: 0;
    }
    .report-subtitle {
      font-size: 13px;
      color: #64748b;
      margin-top: 4px;
    }
    .kpi-row {
      display: flex;
      gap: 16px;
      margin-bottom: 24px;
    }
    .kpi-box {
      flex: 1;
      background-color: #f8fafc;
      border: 1px solid #e2e8f0;
      border-radius: 12px;
      padding: 14px 18px;
    }
    .kpi-label {
      font-size: 11px;
      font-weight: 700;
      color: #64748b;
      letter-spacing: 0.3px;
    }
    .kpi-value {
      font-size: 20px;
      font-weight: 800;
      color: #0f172a;
      margin-top: 6px;
    }
    table {
      width: 100%;
      border-collapse: collapse;
      font-size: 12.5px;
      margin-bottom: 30px;
    }
    th {
      background-color: #f1f5f9;
      color: #334155;
      font-weight: 700;
      padding: 10px 12px;
      text-align: left;
      border-bottom: 1px solid #cbd5e1;
    }
    td {
      padding: 10px 12px;
      border-bottom: 1px solid #f1f5f9;
      vertical-align: middle;
    }
    tr:nth-child(even) {
      background-color: #fbfcfe;
    }
    .badge {
      display: inline-block;
      padding: 4px 8px;
      border-radius: 6px;
      font-size: 11px;
      font-weight: 700;
    }
    .badge-paid { background-color: #dcfce7; color: #166534; }
    .badge-pending { background-color: #fef3c7; color: #92400e; }
    .badge-declared { background-color: #e0e7ff; color: #3730a3; }
    .badge-disputed { background-color: #fee2e2; color: #991b1b; }
    .footer {
      border-top: 1px solid #e2e8f0;
      padding-top: 14px;
      display: flex;
      justify-content: space-between;
      font-size: 11px;
      color: #94a3b8;
    }
    .action-bar {
      display: flex;
      justify-content: flex-end;
      gap: 10px;
      margin-bottom: 24px;
      padding-bottom: 14px;
      border-bottom: 1px dashed #e2e8f0;
    }
    .btn-action {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      border-radius: 8px;
      padding: 8px 16px;
      font-size: 13px;
      font-weight: 700;
      cursor: pointer;
      border: none;
      transition: opacity 0.2s;
    }
    .btn-action:hover { opacity: 0.9; }
    .btn-print { background-color: #2563EB; color: #ffffff; }
    .btn-close { background-color: #f1f5f9; color: #475569; border: 1px solid #cbd5e1; }
    @media print {
      body { padding: 15mm 15mm; }
      .no-print { display: none !important; }
    }
  </style>
</head>
<body>
  <div class="no-print action-bar">
    <button onclick="window.print()" class="btn-action btn-print">
      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="6 9 6 2 18 2 18 9"></polyline><path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2"></path><rect x="6" y="14" width="12" height="8"></rect></svg>
      <span>Yazdır / PDF</span>
    </button>
    <button onclick="window.close()" class="btn-action btn-close">
      <span>Kapat</span>
    </button>
  </div>

  <div class="header">
    <div>
      <h1 class="agency-title">${displayAgency}</h1>
      <div class="report-subtitle">Finansal Rapor • ${effectiveSegmentTitle}</div>
    </div>
    <div style="text-align:right;">
      <div style="font-size:13px; font-weight:700; color:#0f172a;">Dönem: ${effectivePeriodTitle}</div>
      <div style="font-size:11px; color:#64748b; margin-top:3px;">Oluşturulma: ${nowFormatted}</div>
    </div>
  </div>

  <div class="kpi-row">
    <div class="kpi-box">
      <div class="kpi-label">İşlem Sayısı</div>
      <div class="kpi-value">${displayedPayments.length}</div>
    </div>
    <div class="kpi-box">
      <div class="kpi-label">Toplam Tutar</div>
      <div class="kpi-value">${totalsStr}</div>
    </div>
    <div class="kpi-box">
      <div class="kpi-label">Filtre / Kategori</div>
      <div class="kpi-value" style="font-size:16px;">${effectiveSegmentTitle}</div>
    </div>
  </div>

  <table>
    <thead>
      <tr>
        <th style="text-align:center; width:30px;">#</th>
        <th>Mülk</th>
        <th>Kalem</th>
        <th>Ev Sahibi</th>
        <th>Kiracı</th>
        <th style="text-align:center;">Vade</th>
        <th style="text-align:right;">Tutar</th>
        <th style="text-align:center;">Durum</th>
      </tr>
    </thead>
    <tbody>
      ${rowsHtml}
    </tbody>
  </table>

  <div class="footer">
    <div>Stanomer Gayrimenkul Teknolojileri • www.stanomer.online</div>
    <div>Sayfa 1 / 1</div>
  </div>

  <script>
    function triggerPrint() {
      setTimeout(function() {
        window.print();
      }, 350);
    }
    if (document.readyState === 'complete') {
      triggerPrint();
    } else {
      window.addEventListener('load', triggerPrint);
    }
  </script>
</body>
</html>`;
  };

  // Print or PDF Handler (Blob URL in new tab)
  const handlePrintOrPdf = () => {
    const htmlContent = generateHtmlReport();
    const blob = new Blob([htmlContent], { type: "text/html;charset=utf-8" });
    const url = URL.createObjectURL(blob);
    window.open(url, "_blank");
    setTimeout(() => {
      URL.revokeObjectURL(url);
    }, 300000);
  };

  // Copy to Clipboard (WhatsApp & Viber)
  const handleCopyToClipboard = async () => {
    const text = generatePlainTextReport();
    try {
      await navigator.clipboard.writeText(text);
      setCopiedExport(true);
      setTimeout(() => setCopiedExport(false), 3000);
    } catch {
      // fallback
    }
  };

  return (
    <div
      role="tabpanel"
      id="tabpanel-payments"
      aria-labelledby="tab-payments"
      className="space-y-4"
    >
      {/* Real Data Notice in Demo */}
      {isDemoMode && (
        <div className="flex items-center gap-2.5 p-3 rounded-xl bg-[#FBF1DC] border border-[#8A5206]/20 text-[#8A5206] text-xs font-semibold shadow-2xs">
          <AlertTriangle className="w-4 h-4 text-[#8A5206] shrink-0" />
          <span>{tSafe("agency_demo_warn_real_data")}</span>
        </div>
      )}

      {/* Finance Sub-Tab Selector (Action Required vs Report) */}
      <div className="flex items-center gap-1 sm:gap-2 border-b border-[#E5E3DF] overflow-x-auto no-scrollbar">
        <button
          type="button"
          role="tab"
          aria-selected={financeSubTab === 0}
          onClick={() => {
            setFinanceSubTab(0);
            setSelectedSegment(0);
            setPeriodPreset("all_time");
          }}
          className={`py-3 px-3 sm:px-4 text-xs font-bold border-b-2 transition-all flex items-center gap-2 cursor-pointer whitespace-nowrap -mb-px ${
            financeSubTab === 0
              ? "border-[#1B5888] text-[#1B5888]"
              : "border-transparent text-[#666666] hover:text-[#1A1A1A] hover:border-slate-300"
          }`}
        >
          <AlertCircle
            className={`w-4 h-4 shrink-0 ${
              financeSubTab === 0 ? "text-[#1B5888]" : "text-[#8A8A8A]"
            }`}
          />
          <span>{t("financeSubTabActionRequired")}</span>
        </button>

        <button
          type="button"
          role="tab"
          aria-selected={financeSubTab === 1}
          onClick={() => {
            setFinanceSubTab(1);
            setSelectedSegment(3);
            setPeriodPreset("this_month");
          }}
          className={`py-3 px-3 sm:px-4 text-xs font-bold border-b-2 transition-all flex items-center gap-2 cursor-pointer whitespace-nowrap -mb-px ${
            financeSubTab === 1
              ? "border-[#1B5888] text-[#1B5888]"
              : "border-transparent text-[#666666] hover:text-[#1A1A1A] hover:border-slate-300"
          }`}
        >
          <FileBarChart
            className={`w-4 h-4 shrink-0 ${
              financeSubTab === 1 ? "text-[#1B5888]" : "text-[#8A8A8A]"
            }`}
          />
          <span>{t("financeSubTabReport")}</span>
        </button>
      </div>

      {/* Collapsible Search & Detailed Filters Panel */}
      <div className="bg-[#F8FAFC] border border-[#E2E8F0] rounded-[10px] p-4 shadow-2xs space-y-3">
        <div
          onClick={() => setIsFilterExpanded(!isFilterExpanded)}
          className="flex items-center justify-between cursor-pointer select-none text-[#1B5888] hover:text-[#15466d] transition-colors"
        >
          <div className="flex items-center gap-2 font-bold text-xs sm:text-sm">
            <SlidersHorizontal className="w-4 h-4 text-[#1B5888]" />
            <span>{t("searchAndFilterPanel")}</span>
            {hasActiveFilters && (
              <span className="px-2 py-0.5 rounded-md text-[10px] font-bold bg-[#1B5888]/10 text-[#1B5888]">
                {t("filterActiveLabel")}
              </span>
            )}
          </div>
          <button type="button" className="p-1 rounded-md text-slate-400 hover:text-slate-600 cursor-pointer">
            {isFilterExpanded ? <ChevronUp className="w-4 h-4" /> : <ChevronDown className="w-4 h-4" />}
          </button>
        </div>

        {isFilterExpanded && (
          <div className="space-y-3 pt-1 text-xs">
            {/* Search Input & Period Selector */}
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
              <div className="sm:col-span-2 relative bg-white rounded-[8px] border border-[#E2E8F0] shadow-2xs">
                <Search className="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" />
                <input
                  type="text"
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  placeholder={t("searchPlaceholder")}
                  className="w-full pl-10 pr-9 py-2.5 text-[#0F172A] placeholder:text-slate-400 rounded-[8px] focus:outline-hidden focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500"
                />
                {searchQuery && (
                  <button
                    type="button"
                    onClick={() => setSearchQuery("")}
                    className="absolute right-3 top-1/2 -translate-y-1/2 p-1 text-slate-400 hover:text-slate-600 rounded-full cursor-pointer"
                  >
                    <X className="w-3.5 h-3.5" />
                  </button>
                )}
              </div>

              {/* Period Selector */}
              <div className="relative bg-white rounded-[8px] border border-[#E2E8F0] shadow-2xs">
                {financeSubTab === 0 ? (
                  <div className="w-full px-3.5 py-2.5 font-semibold text-slate-700 flex items-center gap-2">
                    <Calendar className="w-4 h-4 text-slate-400" />
                    <span>{t("periodAllTime")}</span>
                  </div>
                ) : (
                  <>
                    <select
                      value={periodPreset}
                      onChange={(e) => setPeriodPreset(e.target.value as any)}
                      className="w-full pl-9 pr-8 py-2.5 font-semibold text-[#0F172A] bg-transparent rounded-[8px] appearance-none focus:outline-hidden focus:ring-2 focus:ring-blue-500/20 cursor-pointer"
                    >
                      <option value="this_month">{t("periodThisMonth")}</option>
                      <option value="last_month">{t("periodLastMonth")}</option>
                      <option value="this_year">{t("periodThisYear")}</option>
                      <option value="all_time">{t("periodAllTime")}</option>
                    </select>
                    <Calendar className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none" />
                    <ChevronDown className="w-4 h-4 text-slate-400 absolute right-3 top-1/2 -translate-y-1/2 pointer-events-none" />
                  </>
                )}
              </div>
            </div>

            {/* Dropdowns Row: Landlords, Properties, Type */}
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
              {/* Landlords */}
              <div className="relative bg-white rounded-[8px] border border-[#E2E8F0] shadow-2xs">
                <select
                  value={selectedLandlord}
                  onChange={(e) => setSelectedLandlord(e.target.value)}
                  className="w-full pl-9 pr-8 py-2.5 font-medium text-[#0F172A] bg-transparent rounded-[8px] appearance-none focus:outline-hidden focus:ring-2 focus:ring-blue-500/20 cursor-pointer"
                >
                  <option value="all">{t("financeFilterLandlords")}: All</option>
                  {landlordList.map((l) => (
                    <option key={l} value={l}>
                      {l}
                    </option>
                  ))}
                </select>
                <UserCheck className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none" />
                <ChevronDown className="w-4 h-4 text-slate-400 absolute right-3 top-1/2 -translate-y-1/2 pointer-events-none" />
              </div>

              {/* Properties */}
              <div className="relative bg-white rounded-[8px] border border-[#E2E8F0] shadow-2xs">
                <select
                  value={selectedPropertyId}
                  onChange={(e) => setSelectedPropertyId(e.target.value)}
                  className="w-full pl-9 pr-8 py-2.5 font-medium text-[#0F172A] bg-transparent rounded-[8px] appearance-none focus:outline-hidden focus:ring-2 focus:ring-blue-500/20 cursor-pointer"
                >
                  <option value="all">{t("financeFilterProperties")}: All</option>
                  {managedProperties.map((p) => (
                    <option key={p.id} value={p.id}>
                      {p.title}
                    </option>
                  ))}
                </select>
                <Home className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none" />
                <ChevronDown className="w-4 h-4 text-slate-400 absolute right-3 top-1/2 -translate-y-1/2 pointer-events-none" />
              </div>

              {/* Type */}
              <div className="relative bg-white rounded-[8px] border border-[#E2E8F0] shadow-2xs">
                <select
                  value={selectedType}
                  onChange={(e) => setSelectedType(e.target.value)}
                  className="w-full pl-9 pr-8 py-2.5 font-medium text-[#0F172A] bg-transparent rounded-[8px] appearance-none focus:outline-hidden focus:ring-2 focus:ring-blue-500/20 cursor-pointer"
                >
                  <option value="all">{t("financeFilterType")}: All</option>
                  <option value="rent">Rent (Kira)</option>
                  <option value="bills">Bills (Fatura)</option>
                  <option value="maintenance">Maintenance (Bakım)</option>
                </select>
                <Tag className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none" />
                <ChevronDown className="w-4 h-4 text-slate-400 absolute right-3 top-1/2 -translate-y-1/2 pointer-events-none" />
              </div>
            </div>

            {/* Grouping & Sorting Row */}
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              {/* Grouping */}
              <div className="relative bg-white rounded-[8px] border border-[#E2E8F0] shadow-2xs">
                <select
                  value={groupBy}
                  onChange={(e) => setGroupBy(e.target.value as any)}
                  className="w-full pl-9 pr-8 py-2.5 font-medium text-[#0F172A] bg-transparent rounded-[8px] appearance-none focus:outline-hidden focus:ring-2 focus:ring-blue-500/20 cursor-pointer"
                >
                  <option value="none">{t("groupNone")}</option>
                  <option value="landlord">{t("groupByLandlord")}</option>
                  <option value="city">{t("groupByCity")}</option>
                  <option value="status">{t("groupByStatus")}</option>
                </select>
                <Layers className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none" />
                <ChevronDown className="w-4 h-4 text-slate-400 absolute right-3 top-1/2 -translate-y-1/2 pointer-events-none" />
              </div>

              {/* Sorting */}
              <div className="relative bg-white rounded-[8px] border border-[#E2E8F0] shadow-2xs">
                <select
                  value={sortBy}
                  onChange={(e) => setSortBy(e.target.value as any)}
                  className="w-full pl-9 pr-8 py-2.5 font-medium text-[#0F172A] bg-transparent rounded-[8px] appearance-none focus:outline-hidden focus:ring-2 focus:ring-blue-500/20 cursor-pointer"
                >
                  <option value="newest">{t("sortByNewest")}</option>
                  <option value="oldest">{t("sortByOldest")}</option>
                  <option value="amount_desc">{t("sortByAmountDesc")}</option>
                  <option value="amount_asc">{t("sortByAmountAsc")}</option>
                  <option value="name_asc">{t("sortByNameAsc")}</option>
                  <option value="landlord_asc">{t("sortByLandlordAsc")}</option>
                </select>
                <ArrowDownUp className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none" />
                <ChevronDown className="w-4 h-4 text-slate-400 absolute right-3 top-1/2 -translate-y-1/2 pointer-events-none" />
              </div>
            </div>

            {/* Reset Filters Button */}
            {hasActiveFilters && (
              <div className="flex justify-end pt-1">
                <button
                  type="button"
                  onClick={() => {
                    setSearchQuery("");
                    setSelectedLandlord("all");
                    setSelectedPropertyId("all");
                    setSelectedType("all");
                    setGroupBy("none");
                    setSortBy("newest");
                    if (financeSubTab === 1) setPeriodPreset("this_month");
                  }}
                  className="inline-flex items-center gap-1.5 text-xs font-bold text-rose-600 hover:text-rose-700 cursor-pointer transition-colors"
                >
                  <RotateCcw className="w-3.5 h-3.5" />
                  <span>{t("financeFilterReset")}</span>
                </button>
              </div>
            )}
          </div>
        )}
      </div>

      {/* KPI Cards Row (Flutter Parity) */}
      {financeSubTab === 0 ? (
        /* Action Required Cards */
        <div className="grid grid-cols-2 md:grid-cols-5 gap-3">
          {/* 1. Pending Approvals */}
          <div
            onClick={() => setSelectedSegment(0)}
            className={`p-3.5 rounded-[10px] border transition-all cursor-pointer ${
              selectedSegment === 0
                ? "bg-amber-50/80 border-amber-300 ring-2 ring-amber-400/40 shadow-xs"
                : "bg-white border-[#E2E8F0] hover:bg-slate-50"
            }`}
          >
            <div className="flex items-center justify-between">
              <span className="text-xs font-semibold text-slate-500 truncate">
                {t("financePendingApprovals")}
              </span>
              <div className="w-6 h-6 rounded-full bg-amber-50 text-amber-500 flex items-center justify-center">
                <Clock className="w-4 h-4 text-amber-500 shrink-0" />
              </div>
            </div>
            <div className="text-xl font-semibold text-[#0F172A] mt-1.5 font-mono">
              {pendingApprovalsList.length}
            </div>
          </div>

          {/* 2. Unentered Bills */}
          <div
            onClick={() => setSelectedSegment(1)}
            className={`p-3.5 rounded-[10px] border transition-all cursor-pointer ${
              selectedSegment === 1
                ? "bg-[#FEF6EE] border-[#EA580C] ring-2 ring-[#EA580C]/20 shadow-xs"
                : "bg-white border-[#E2E8F0] hover:bg-slate-50"
            }`}
          >
            <div className="flex items-center justify-between">
              <span className="text-xs font-semibold text-slate-500 truncate">
                {t("unenteredBillsTitle")}
              </span>
              <div className="w-6 h-6 rounded-full bg-[#EA580C]/10 text-[#EA580C] flex items-center justify-center">
                <FileQuestion className="w-4 h-4 text-[#EA580C] shrink-0" />
              </div>
            </div>
            <div className="text-xl font-semibold text-[#0F172A] mt-1.5 font-mono">
              {unenteredBillsList.length}
            </div>
          </div>

          {/* 3. Overdue Payments */}
          <div
            onClick={() => setSelectedSegment(2)}
            className={`p-3.5 rounded-[10px] border transition-all cursor-pointer ${
              selectedSegment === 2
                ? "bg-rose-50/80 border-rose-300 ring-2 ring-rose-400/40 shadow-xs"
                : "bg-white border-[#E2E8F0] hover:bg-slate-50"
            }`}
          >
            <div className="flex items-center justify-between">
              <span className="text-xs font-semibold text-slate-500 truncate">
                {t("financeOverduePayments")}
              </span>
              <div className="w-6 h-6 rounded-full bg-rose-50 text-rose-500 flex items-center justify-center">
                <AlertTriangle className="w-4 h-4 text-rose-500 shrink-0" />
              </div>
            </div>
            <div className="text-xl font-semibold text-rose-600 mt-1.5 font-mono">
              {overduePaymentsList.length}
            </div>
          </div>

          {/* 4. Unpaid Maintenance */}
          <div
            onClick={() => setSelectedSegment(8)}
            className={`p-3.5 rounded-[10px] border transition-all cursor-pointer ${
              selectedSegment === 8
                ? "bg-red-50/80 border-red-300 ring-2 ring-red-400/40 shadow-xs"
                : "bg-white border-[#E2E8F0] hover:bg-slate-50"
            }`}
          >
            <div className="flex items-center justify-between">
              <span className="text-xs font-semibold text-slate-500 truncate">
                {t("financeUnpaidMaintenance")}
              </span>
              <div className="w-6 h-6 rounded-full bg-red-50 text-red-500 flex items-center justify-center">
                <Wrench className="w-4 h-4 text-red-500 shrink-0" />
              </div>
            </div>
            <div className="text-xl font-semibold text-[#0F172A] mt-1.5 font-mono">
              {unpaidMaintenanceList.length}
            </div>
          </div>

          {/* 5. Tenant Offsets */}
          <div
            onClick={() => setSelectedSegment(10)}
            className={`p-3.5 rounded-[10px] border transition-all cursor-pointer col-span-2 md:col-span-1 ${
              selectedSegment === 10
                ? "bg-teal-50/80 border-teal-300 ring-2 ring-teal-400/40 shadow-xs"
                : "bg-white border-[#E2E8F0] hover:bg-slate-50"
            }`}
          >
            <div className="flex items-center justify-between">
              <span className="text-xs font-semibold text-slate-500 truncate">
                {t("financeTenantOffsets")}
              </span>
              <div className="w-6 h-6 rounded-full bg-teal-50 text-teal-600 flex items-center justify-center">
                <ArrowLeftRight className="w-4 h-4 text-teal-600 shrink-0" />
              </div>
            </div>
            <div className="text-xl font-semibold text-[#0F172A] mt-1.5 font-mono">
              {tenantOffsetsList.length}
            </div>
          </div>
        </div>
      ) : (
        /* Report Cards (100% Flutter Parity) */
        <div className={`grid grid-cols-1 sm:grid-cols-2 ${hasIncludedExpenses ? "lg:grid-cols-4" : "lg:grid-cols-3"} gap-3`}>
          {/* 1. Rent Collected */}
          <div
            onClick={() => setSelectedSegment(3)}
            className={`p-3.5 rounded-[10px] border transition-all cursor-pointer ${
              selectedSegment === 3
                ? "bg-emerald-50/60 border-emerald-500 ring-1 ring-emerald-500 shadow-xs"
                : "bg-white border-[#E2E8F0] hover:bg-slate-50/80 shadow-xs"
            }`}
          >
            <div className="flex items-center justify-between">
              <div className="p-1.5 rounded-[8px] bg-emerald-500/10 text-emerald-600">
                <Home className="w-4 h-4" />
              </div>
              <div className="px-2 py-0.5 rounded-[6px] bg-emerald-500/10 text-emerald-600 text-xs font-bold font-mono">
                {rentCollectedList.length}
              </div>
            </div>
            <div className="mt-2.5 text-xs font-semibold text-slate-500 truncate">
              {t("financeRentCollected")}
            </div>
            <div className="mt-1 text-[15px] font-bold text-[#0F172A] tracking-tight font-mono">
              {formatKpiAmount(rentCollectedList)}
            </div>
          </div>

          {/* 2. Bills Paid to Institutions (Only if hasIncludedExpenses) */}
          {hasIncludedExpenses && (
            <div
              onClick={() => setSelectedSegment(5)}
              className={`p-3.5 rounded-[10px] border transition-all cursor-pointer ${
                selectedSegment === 5
                  ? "bg-purple-50/60 border-purple-500 ring-1 ring-purple-500 shadow-xs"
                  : "bg-white border-[#E2E8F0] hover:bg-slate-50/80 shadow-xs"
              }`}
            >
              <div className="flex items-center justify-between">
                <div className="p-1.5 rounded-[8px] bg-purple-500/10 text-purple-600">
                  <Building2 className="w-4 h-4" />
                </div>
                <div className="px-2 py-0.5 rounded-[6px] bg-purple-500/10 text-purple-600 text-xs font-bold font-mono">
                  {billsToInstitutionsList.length}
                </div>
              </div>
              <div className="mt-2.5 text-xs font-semibold text-slate-500 truncate">
                {t("financeBillsToInstitutions")}
              </div>
              <div className="mt-1 text-[15px] font-bold text-[#0F172A] tracking-tight font-mono">
                {formatKpiAmount(billsToInstitutionsList)}
              </div>
            </div>
          )}

          {/* 3. Maintenance Paid */}
          <div
            onClick={() => setSelectedSegment(6)}
            className={`p-3.5 rounded-[10px] border transition-all cursor-pointer ${
              selectedSegment === 6
                ? "bg-emerald-50/60 border-emerald-500 ring-1 ring-emerald-500 shadow-xs"
                : "bg-white border-[#E2E8F0] hover:bg-slate-50/80 shadow-xs"
            }`}
          >
            <div className="flex items-center justify-between">
              <div className="p-1.5 rounded-[8px] bg-emerald-500/10 text-emerald-600">
                <Wrench className="w-4 h-4" />
              </div>
              <div className="px-2 py-0.5 rounded-[6px] bg-emerald-500/10 text-emerald-600 text-xs font-bold font-mono">
                {maintenancePaidList.length}
              </div>
            </div>
            <div className="mt-2.5 text-xs font-semibold text-slate-500 truncate">
              {t("financeMaintenancePaid")}
            </div>
            <div className="mt-1 text-[15px] font-bold text-[#0F172A] tracking-tight font-mono">
              {formatKpiAmount(maintenancePaidList)}
            </div>
          </div>

          {/* 4. Maintenance Owed to Agency */}
          <div
            onClick={() => setSelectedSegment(7)}
            className={`p-3.5 rounded-[10px] border transition-all cursor-pointer ${
              selectedSegment === 7
                ? "bg-amber-50/60 border-amber-500 ring-1 ring-amber-500 shadow-xs"
                : "bg-white border-[#E2E8F0] hover:bg-slate-50/80 shadow-xs"
            }`}
          >
            <div className="flex items-center justify-between">
              <div className="p-1.5 rounded-[8px] bg-amber-500/10 text-amber-600">
                <HandCoins className="w-4 h-4" />
              </div>
              <div className="px-2 py-0.5 rounded-[6px] bg-amber-500/10 text-amber-600 text-xs font-bold font-mono">
                {maintenanceOwedList.length}
              </div>
            </div>
            <div className="mt-2.5 text-xs font-semibold text-slate-500 truncate flex items-center gap-1">
              <span>{t("financeMaintenanceOwedToAgency")}</span>
              <Info className="w-3.5 h-3.5 text-slate-400" />
            </div>
            <div className="mt-1 text-[15px] font-bold text-[#0F172A] tracking-tight font-mono">
              {formatKpiAmount(maintenanceOwedList)}
            </div>
          </div>
        </div>
      )}

      {/* View Mode & Counter Toolbar */}
      <div className="flex items-center justify-between pt-1">
        {/* Count Badge */}
        <div className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-slate-100/90 border border-slate-200/60 text-slate-700 text-xs font-bold">
          <Receipt className="w-3.5 h-3.5 text-slate-500" />
          <span>
            {displayedPayments.length} {t("paymentRequests").toLowerCase()}
          </span>
        </div>

        <div className="flex items-center gap-2">
          {/* Export Report Button */}
          <button
            type="button"
            onClick={() => setIsExportModalOpen(true)}
            disabled={displayedPayments.length === 0}
            className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-[10px] text-xs font-semibold bg-[#E5EEF6] hover:bg-[#d5e4f1] text-[#1B5888] border border-[#1B5888]/20 transition-colors cursor-pointer disabled:opacity-40"
          >
            <FileSpreadsheet className="w-3.5 h-3.5" />
            <span>{t("financeExportReport")}</span>
          </button>

          {/* View Mode Switcher */}
          <div className="flex items-center bg-white border border-[#E2E8F0] rounded-[10px] p-0.5 shadow-2xs">
            <button
              type="button"
              onClick={() => setViewMode("table")}
              title={t("viewModeTable")}
              className={`p-1.5 rounded-lg transition-colors cursor-pointer ${
                viewMode === "table"
                  ? "bg-slate-100 text-[#0F172A]"
                  : "text-slate-400 hover:text-slate-600"
              }`}
            >
              <TableProperties className="w-4 h-4" />
            </button>
            <button
              type="button"
              onClick={() => setViewMode("grid")}
              title={t("viewModeGrid")}
              className={`p-1.5 rounded-lg transition-colors cursor-pointer ${
                viewMode === "grid"
                  ? "bg-slate-100 text-[#0F172A]"
                  : "text-slate-400 hover:text-slate-600"
              }`}
            >
              <LayoutGrid className="w-4 h-4" />
            </button>
          </div>
        </div>
      </div>

      {/* Payments List / Table */}
      {loadingPayments ? (
        <div className="p-12 text-center text-xs text-slate-500 flex items-center justify-center gap-2">
          <RefreshCw className="w-4 h-4 animate-spin text-blue-600" />
          <span>{t("agency_panel_loading")}</span>
        </div>
      ) : displayedPayments.length === 0 ? (
        <div className="bg-white rounded-[10px] border border-[#E5E3DF] p-12 text-center shadow-xs space-y-3">
          <div className="w-12 h-12 rounded-[10px] bg-slate-100 text-[#666666] flex items-center justify-center mx-auto">
            <Receipt className="w-6 h-6" />
          </div>
          <h3 className="text-base font-bold text-[#1A1A1A]">
            {t("agency_payments_empty_title")}
          </h3>
          <p className="text-xs text-[#666666] max-w-md mx-auto leading-relaxed">
            {t("agency_payments_empty_desc")}
          </p>
        </div>
      ) : viewMode === "table" ? (
        /* High-Density Table View (Flutter Parity) */
        <div className="bg-white rounded-[10px] border border-[#E2E8F0] shadow-xs overflow-x-auto">
          <table className="w-full text-left border-collapse min-w-[840px]">
            <thead>
              <tr className="border-b border-[#E2E8F0] bg-[#F8FAFC] text-[11px] font-semibold text-slate-500 tracking-wider">
                <th className="py-3.5 px-4">{t("colPropertyAndType")}</th>
                <th className="py-3.5 px-4">
                  {t("agency_props_col_landlord")} / {t("roleTenant")}
                </th>
                <th className="py-3.5 px-4">{t("colDueDate")}</th>
                <th className="py-3.5 px-4">{t("colAmount")}</th>
                <th className="py-3.5 px-4">{t("statusLabel")}</th>
                <th className="py-3.5 px-4 text-right sticky right-0 bg-[#F8FAFC] z-20 shadow-[-6px_0_10px_rgba(0,0,0,0.03)] border-l border-[#E2E8F0]/80">{t("colAction")}</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 text-xs text-slate-700">
              {groupedPayments.map((group, groupIdx) => (
                <React.Fragment key={group.groupName || groupIdx}>
                  {group.groupName && (
                    <tr className="bg-slate-50/80 border-y border-[#E2E8F0]">
                      <td colSpan={6} className="py-2.5 px-4 font-bold text-xs text-slate-700">
                        <div className="flex items-center gap-2">
                          <Tag className="w-3.5 h-3.5 text-blue-600" />
                          <span>{group.groupName}</span>
                          <span className="text-[11px] font-semibold text-slate-400">
                            ({group.items.length})
                          </span>
                        </div>
                      </td>
                    </tr>
                  )}

                  {group.items.map((p) => {
                    const prop = propertiesMap[p.property_id];
                    const isDisputed = p.status === "disputed";
                    const isOverdue =
                      !isDisputed &&
                      (p.is_overdue ??
                        (p.status === "overdue" ||
                          (p.status === "pending" && p.due_date && p.due_date < todayStr && (p.amount || 0) > 0)));
                    const isAwaiting =
                      !isDisputed &&
                      (p.is_pending_approval ??
                        (p.status === "declared" || (p.status === "pending" && Boolean(p.declared_at))));
                    const isPaid = p.status === "paid";
                    const isUnentered =
                      p.is_unentered_bill ??
                      (p.status !== "paid" &&
                        p.status !== "declared" &&
                        p.status !== "disputed" &&
                        (p.receiver_type === "owner" || p.receiver_type === "included" || !p.receiver_type) &&
                        !isRent(p) &&
                        (p.amount || 0) === 0);

                    const daysOverdue =
                      isOverdue && p.due_date
                        ? Math.max(
                            0,
                            Math.floor(
                              (new Date().getTime() - new Date(p.due_date).getTime()) /
                                (1000 * 60 * 60 * 24)
                            )
                          )
                        : 0;

                    return (
                      <tr
                        key={p.id}
                        onClick={() => onInspectPayment?.(p)}
                        className="hover:bg-slate-50/80 transition-colors cursor-pointer group"
                      >
                        {/* 1. Property & Type */}
                        <td className="py-3.5 px-4">
                          <div className="flex items-center gap-2.5">
                            <PaymentTypeIconBadge
                              title={p.title}
                              isMaintenance={p.is_maintenance}
                              size="sm"
                            />
                            <div className="min-w-0">
                              <div className="font-bold text-xs text-[#0F172A] truncate max-w-[220px]">
                                {p.property_title || prop?.title || "-"}
                              </div>
                              <div className="flex items-center gap-1.5 mt-0.5">
                                <span className="inline-flex items-center px-1.5 py-0.5 rounded text-[10px] font-bold bg-slate-100 text-slate-700">
                                  {formatPaymentTitle(p.title)}
                                </span>
                                {prop?.city && (
                                  <span className="text-[10px] text-slate-400">
                                    · {prop.city}
                                  </span>
                                )}
                              </div>
                            </div>
                          </div>
                        </td>

                        {/* 2. Landlord / Tenant */}
                        <td className="py-3.5 px-4">
                          <div className="space-y-1">
                            <div className="flex items-center gap-1 text-[11px] font-semibold text-slate-800 truncate max-w-[180px]">
                              <UserCheck className="w-3.5 h-3.5 text-blue-600 shrink-0" />
                              <span>{prop?.landlord_name || prop?.landlord_email || t("groupLandlordPendingInvite")}</span>
                            </div>
                            <div className="flex items-center gap-1 text-[11px] text-slate-500 truncate max-w-[180px]">
                              <User className="w-3.5 h-3.5 text-slate-400 shrink-0" />
                              <span>{p.tenant_name ? p.tenant_name : t("tenantLabel")}</span>
                            </div>
                          </div>
                        </td>

                        {/* 3. Due Date */}
                        <td className="py-3.5 px-4">
                          <div
                            className={`font-semibold text-xs ${
                              isOverdue ? "text-rose-600 font-bold" : "text-slate-800"
                            }`}
                          >
                            {formatDueDate(p.due_date)}
                          </div>
                          {isOverdue && daysOverdue > 0 && (
                            <div className="text-[10px] font-bold text-rose-500 mt-0.5">
                              {tSafe("daysOverdueText", { count: daysOverdue })}
                            </div>
                          )}
                        </td>

                        {/* 4. Amount */}
                        <td className="py-3.5 px-4">
                          <div className="font-bold text-xs text-[#0F172A]">
                            {p.amount ? `${p.amount.toLocaleString()} ${p.currency || "EUR"}` : "—"}
                          </div>
                          {p.payment_method === "cash" && (
                            <span className="inline-flex items-center px-1.5 py-0.5 rounded text-[9px] font-bold bg-amber-100 text-amber-800 mt-0.5">
                              {t("cashBadge")}
                            </span>
                          )}
                        </td>

                        {/* 5. Status Badge */}
                        <td className="py-3.5 px-4">
                          {isPaid ? (
                            <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-md text-[11px] font-bold bg-[#ECFDF5] text-[#059669] border border-[#A7F3D0]">
                              <Check className="w-3 h-3 text-[#059669]" />
                              <span>{t("statusClean")}</span>
                            </span>
                          ) : isDisputed ? (
                            <div className="space-y-1">
                              <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-md text-[11px] font-bold bg-[#FFF1F2] text-[#E11D48] border border-[#FDA4AF]">
                                <AlertCircle className="w-3 h-3 text-[#E11D48]" />
                                <span>{t("agency_maint_status_disputed")}</span>
                              </span>
                              {p.dispute_reason && (
                                <p className="text-[10px] font-semibold text-[#9F1239] max-w-[200px] truncate" title={p.dispute_reason}>
                                  {p.dispute_reason}
                                </p>
                              )}
                            </div>
                          ) : isAwaiting ? (
                            <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-md text-[11px] font-bold bg-amber-50 text-amber-800 border border-amber-200">
                              <Clock className="w-3 h-3 text-amber-600" />
                              <span>{t("financePendingApprovals")}</span>
                            </span>
                          ) : isOverdue ? (
                            <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-md text-[11px] font-bold bg-[#FFF1F2] text-[#E11D48] border border-[#FECDD3]">
                              <AlertTriangle className="w-3 h-3 text-[#E11D48]" />
                              <span>{t("statusOverdue")}</span>
                            </span>
                          ) : isUnentered ? (
                            <span className="inline-flex items-center px-2.5 py-1 rounded-md text-[11px] font-bold bg-[#FFF7ED] text-[#C2410C] border border-[#FFEDD5]">
                              {t("unenteredBillsTitle")}
                            </span>
                          ) : (
                            <span className="inline-flex items-center px-2 py-0.5 rounded-md text-[11px] font-semibold bg-slate-100 text-slate-600 border border-slate-200">
                              {t("statusPending")}
                            </span>
                          )}
                        </td>

                        {/* 6. Action */}
                        <td className="py-3.5 px-4 text-right sticky right-0 bg-white group-hover:bg-[#F8FAFC] z-10 shadow-[-6px_0_10px_rgba(0,0,0,0.04)] border-l border-slate-100 transition-colors">
                          <div className="flex items-center justify-end gap-1.5">
                            {/* Receipt Button */}
                            {p.receipt_url && p.receipt_url !== "CASH" && (
                              <button
                                type="button"
                                onClick={(e) => {
                                  e.stopPropagation();
                                  setViewingReceiptUrl(p.receipt_url || null);
                                }}
                                title={t("viewReceipt")}
                                className="p-1.5 rounded-lg text-blue-600 hover:bg-blue-50 transition-colors cursor-pointer"
                              >
                                <FileText className="w-4 h-4" />
                              </button>
                            )}

                            {/* Review Dispute for Disputed Payments (Flutter Parity) */}
                            {isDisputed && (
                              <button
                                type="button"
                                onClick={(e) => {
                                  e.stopPropagation();
                                  onInspectPayment?.(p);
                                }}
                                title={t("agency_payments_btn_review_dispute")}
                                className="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg text-[11px] font-bold bg-[#FFF1F2] text-[#E11D48] border border-[#FDA4AF] hover:bg-rose-100 transition-colors cursor-pointer"
                              >
                                <AlertCircle className="w-3.5 h-3.5" />
                                <span>{t("agency_payments_btn_review_dispute")}</span>
                              </button>
                            )}

                            {/* Approve / Reject for Awaiting Approval */}
                            {isAwaiting && (
                              <>
                                <button
                                  type="button"
                                  disabled={processingPaymentId === p.id}
                                  onClick={(e) => {
                                    e.stopPropagation();
                                    handleApprovePayment(p);
                                  }}
                                  title={t("agency_payments_btn_approve")}
                                  className="p-1.5 rounded-lg text-emerald-600 hover:bg-emerald-50 transition-colors cursor-pointer disabled:opacity-40"
                                >
                                  <Check className="w-4 h-4" />
                                </button>
                                <button
                                  type="button"
                                  disabled={processingPaymentId === p.id}
                                  onClick={(e) => {
                                    e.stopPropagation();
                                    handleRejectPayment(p);
                                  }}
                                  title={t("agency_payments_btn_reject")}
                                  className="p-1.5 rounded-lg text-rose-600 hover:bg-rose-50 transition-colors cursor-pointer disabled:opacity-40"
                                >
                                  <X className="w-4 h-4" />
                                </button>
                              </>
                            )}

                            {/* Chevron Detail Button (Matching Flutter _FinanceTableRow) */}
                            <button
                              type="button"
                              onClick={() => onInspectPayment?.(p)}
                              title={t("agency_prop_drawer_btn_view")}
                              className="p-1.5 rounded-lg text-slate-400 group-hover:text-blue-600 hover:bg-blue-50 transition-colors cursor-pointer"
                            >
                              <ChevronRight className="w-4 h-4" />
                            </button>
                          </div>
                        </td>
                      </tr>
                    );
                  })}
                </React.Fragment>
              ))}
            </tbody>
          </table>
        </div>
      ) : (
        /* Grid View */
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {displayedPayments.map((p) => {
            const prop = propertiesMap[p.property_id];
            const isDisputed = p.status === "disputed";
            const isOverdue =
              !isDisputed &&
              (p.is_overdue ??
                (p.status === "overdue" ||
                  (p.status === "pending" && p.due_date && p.due_date < todayStr && (p.amount || 0) > 0)));
            const isAwaiting =
              !isDisputed &&
              (p.is_pending_approval ??
                (p.status === "declared" || (p.status === "pending" && Boolean(p.declared_at))));
            const isPaid = p.status === "paid";
            const isUnentered =
              p.is_unentered_bill ??
              (p.status !== "paid" &&
                p.status !== "declared" &&
                p.status !== "disputed" &&
                (p.receiver_type === "owner" || p.receiver_type === "included" || !p.receiver_type) &&
                !isRent(p) &&
                (p.amount || 0) === 0);

            return (
              <div
                key={p.id}
                onClick={() => onInspectPayment?.(p)}
                className="bg-white rounded-2xl border border-[#E2E8F0] p-4 shadow-xs space-y-3 hover:shadow-md transition-all cursor-pointer group"
              >
                <div className="flex items-start justify-between gap-2">
                  <div className="flex items-center gap-2.5 min-w-0">
                    <PaymentTypeIconBadge
                      title={p.title}
                      isMaintenance={p.is_maintenance}
                      size="md"
                    />
                    <div className="min-w-0">
                      <h4 className="font-bold text-sm text-[#0F172A] truncate">
                        {p.property_title || prop?.title || "-"}
                      </h4>
                      <p className="text-xs text-slate-500 truncate mt-0.5">
                        {formatPaymentTitle(p.title)} {prop?.city ? `· ${prop.city}` : ""}
                      </p>
                    </div>
                  </div>

                  <span className="font-bold text-sm text-[#0F172A] shrink-0">
                    {p.amount ? `${p.amount.toLocaleString()} ${p.currency || "EUR"}` : "—"}
                  </span>
                </div>

                <div className="bg-slate-50 rounded-xl p-2.5 space-y-1.5 text-xs">
                  <div className="flex items-center justify-between">
                    <span className="text-slate-500">{t("agency_props_col_landlord")}</span>
                    <span className="font-semibold text-slate-800">{prop?.landlord_name || prop?.landlord_email || t("groupLandlordPendingInvite")}</span>
                  </div>
                  <div className="flex items-center justify-between">
                    <span className="text-slate-500">{t("roleTenant")}</span>
                    <span className="font-semibold text-slate-800">{p.tenant_name ? p.tenant_name : t("tenantLabel")}</span>
                  </div>
                  <div className="flex items-center justify-between pt-1 border-t border-slate-200/60">
                    <span className="text-slate-500">{t("colDueDate")}</span>
                    <span className={isOverdue ? "font-bold text-rose-600" : "font-medium text-slate-800"}>
                      {formatDueDate(p.due_date)}
                    </span>
                  </div>
                </div>

                {isDisputed && p.dispute_reason && (
                  <div className="p-2.5 rounded-xl bg-[#FFF1F2] border border-[#FFE4E6] flex items-start gap-2 text-xs text-[#9F1239]">
                    <AlertCircle className="w-3.5 h-3.5 text-[#E11D48] shrink-0 mt-0.5" />
                    <span className="font-medium line-clamp-2">
                      {t("agency_pay_dispute_reason")}: {p.dispute_reason}
                    </span>
                  </div>
                )}

                <div className="flex items-center justify-between pt-1">
                  {isPaid ? (
                    <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-md text-[11px] font-bold bg-[#ECFDF5] text-[#059669]">
                      <Check className="w-3 h-3" />
                      <span>{t("statusClean")}</span>
                    </span>
                  ) : isDisputed ? (
                    <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-md text-[11px] font-bold bg-[#FFF1F2] text-[#E11D48] border border-[#FDA4AF]">
                      <AlertCircle className="w-3 h-3" />
                      <span>{t("agency_maint_status_disputed")}</span>
                    </span>
                  ) : isAwaiting ? (
                    <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-md text-[11px] font-bold bg-amber-50 text-amber-800">
                      <Clock className="w-3 h-3" />
                      <span>{t("financePendingApprovals")}</span>
                    </span>
                  ) : isOverdue ? (
                    <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-md text-[11px] font-bold bg-[#FFF1F2] text-[#E11D48]">
                      <AlertTriangle className="w-3 h-3" />
                      <span>{t("statusOverdue")}</span>
                    </span>
                  ) : isUnentered ? (
                    <span className="inline-flex items-center px-2.5 py-0.5 rounded-md text-[11px] font-bold bg-[#FFF7ED] text-[#C2410C] border border-[#FFEDD5]">
                      {t("unenteredBillsTitle")}
                    </span>
                  ) : (
                    <span className="inline-flex items-center px-2 py-0.5 rounded-md text-[11px] font-semibold bg-slate-100 text-slate-600">
                      {t("statusPending")}
                    </span>
                  )}

                  <div className="flex items-center gap-1">
                    {p.receipt_url && p.receipt_url !== "CASH" && (
                      <button
                        type="button"
                        onClick={(e) => {
                          e.stopPropagation();
                          setViewingReceiptUrl(p.receipt_url || null);
                        }}
                        className="p-1.5 rounded-lg text-blue-600 hover:bg-blue-50"
                        title={t("viewReceipt")}
                      >
                        <FileText className="w-4 h-4" />
                      </button>
                    )}
                    {isDisputed && (
                      <button
                        type="button"
                        onClick={(e) => {
                          e.stopPropagation();
                          onInspectPayment?.(p);
                        }}
                        className="px-2.5 py-1 rounded-lg text-xs font-bold bg-[#FFF1F2] text-[#E11D48] border border-[#FDA4AF] hover:bg-rose-100"
                      >
                        {t("agency_payments_btn_review_dispute")}
                      </button>
                    )}
                    {isAwaiting && (
                      <button
                        type="button"
                        disabled={processingPaymentId === p.id}
                        onClick={() => handleApprovePayment(p)}
                        className="px-2.5 py-1 rounded-lg text-xs font-bold bg-emerald-600 text-white hover:bg-emerald-700"
                      >
                        {t("agency_payments_btn_approve")}
                      </button>
                    )}
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Export / Share Report Modal (100% Flutter Parity with AgencyFinanceReportSheet) */}
      {isExportModalOpen && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-3xl max-w-md w-full p-6 shadow-2xl space-y-5 border border-slate-100">
            {/* Header Row */}
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-blue-500/10 text-blue-600 flex items-center justify-center">
                  <FileSpreadsheet className="w-5 h-5" />
                </div>
                <div>
                  <h3 className="text-base font-extrabold text-[#0F172A]">
                    {t("exportReportSheetTitle")}
                  </h3>
                  <p className="text-xs text-slate-500 font-medium">
                    {agencyName || "Stanomer"} • {effectivePeriodTitle}
                  </p>
                </div>
              </div>
              <button
                type="button"
                onClick={() => setIsExportModalOpen(false)}
                className="p-1.5 rounded-xl text-slate-400 hover:text-slate-600 hover:bg-slate-100 transition-colors cursor-pointer"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* KPI Preview Card */}
            <div className="p-4 bg-slate-50/80 rounded-[10px] border border-slate-200/80 grid grid-cols-2 gap-4">
              <div>
                <span className="text-xs font-semibold text-slate-500 block">
                  {t("exportReportTotalAmount")}
                </span>
                <span className="text-lg font-black text-blue-600 mt-1 block">
                  {formatKpiAmount(displayedPayments)}
                </span>
              </div>
              <div className="border-l border-slate-200/80 pl-4">
                <span className="text-xs font-semibold text-slate-500 block">
                  {t("exportReportFilteredItems")}
                </span>
                <span className="text-base font-extrabold text-[#0F172A] mt-1 block">
                  {tSafe("exportReportTransactionsCount", { count: displayedPayments.length })}
                </span>
              </div>
            </div>

            {/* Action Buttons Row */}
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 pt-1">
              {/* 1. Print / PDF Button */}
              <button
                type="button"
                onClick={handlePrintOrPdf}
                className="py-2.5 px-4 rounded-[10px] text-xs sm:text-sm font-semibold bg-[#1B5888] hover:bg-[#15466d] text-white transition-colors shadow-2xs flex items-center justify-center gap-2 cursor-pointer"
              >
                <Printer className="w-4 h-4" />
                <span className="text-xs">{t("exportReportPrintPdf")}</span>
              </button>

              {/* 2. Copy Text Button */}
              <button
                type="button"
                onClick={handleCopyToClipboard}
                className="py-2.5 px-4 rounded-[10px] text-xs sm:text-sm font-semibold border border-[#E5E3DF] hover:bg-slate-50 text-[#4A4A4A] transition-colors flex items-center justify-center gap-2 cursor-pointer"
              >
                {copiedExport ? (
                  <>
                    <CheckCheck className="w-4 h-4 text-emerald-600" />
                    <span className="text-xs text-emerald-700">{t("exportReportCopyText")}</span>
                  </>
                ) : (
                  <>
                    <Copy className="w-4 h-4 text-emerald-600" />
                    <span className="text-xs">{t("exportReportCopyText")}</span>
                  </>
                )}
              </button>
            </div>

            {/* Copied Success Feedback Toast */}
            {copiedExport && (
              <div className="p-2.5 rounded-[10px] bg-emerald-50 border border-emerald-200 text-emerald-800 text-xs font-semibold flex items-center gap-2">
                <CheckCheck className="w-4 h-4 text-emerald-600 shrink-0" />
                <span>{t("exportReportCopiedSuccess")}</span>
              </div>
            )}
          </div>
        </div>
      )}

      {/* Viewing Receipt Image Dialog */}
      {viewingReceiptUrl && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-2xl max-w-lg w-full p-4 shadow-2xl space-y-3">
            <div className="flex items-center justify-between">
              <h3 className="text-sm font-bold text-[#0F172A]">{t("viewReceipt")}</h3>
              <button
                type="button"
                onClick={() => setViewingReceiptUrl(null)}
                className="p-1 rounded-lg text-slate-400 hover:text-slate-600 cursor-pointer"
              >
                <X className="w-5 h-5" />
              </button>
            </div>
            <div className="max-h-[70vh] overflow-auto rounded-xl bg-slate-50 flex items-center justify-center p-2">
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img
                src={viewingReceiptUrl}
                alt={t("viewReceipt")}
                className="max-h-[65vh] w-auto object-contain rounded-lg shadow-xs"
              />
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
