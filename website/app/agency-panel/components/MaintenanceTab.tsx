"use client";

import React, { useState, useMemo, useEffect } from "react";
import {
  AlertTriangle,
  ArrowDownUp,
  Building2,
  Calendar,
  CheckCircle2,
  CheckSquare,
  ChevronDown,
  ChevronUp,
  Clock,
  Home,
  Layers,
  MapPin,
  MessageCircle,
  Plus,
  RefreshCw,
  RotateCcw,
  Search,
  SlidersHorizontal,
  Tag,
  User,
  UserCheck,
  Wallet,
  Wrench,
  X,
} from "lucide-react";
import {
  AgencyAssigneeOption,
  AgencyMaintenanceRequest,
  AgencyManagedProperty,
  AgencyMaintStatusFilter,
  AgencyTask,
  AgencyTaskPrefill,
  AgencyTaskStatus,
} from "../types";
import MaintenanceDetailView from "./MaintenanceDetailView";
import {
  MaintenanceCategoryBadge,
  getMaintenanceExpenseStatusLabel,
} from "../categoryAndPaymentIcons";

export interface MaintenanceTabProps {
  maintenanceRequests: AgencyMaintenanceRequest[];
  loadingMaintenance: boolean;
  maintenanceStats: {
    openCount: number;
    inProgressCount: number;
    resolvedCount: number;
    urgentCount: number;
    totalCost: number;
  };
  filteredMaintenanceRequests: AgencyMaintenanceRequest[];
  managedProperties: AgencyManagedProperty[];
  setNewMaintPropId: (id: string) => void;
  setIsNewMaintModalOpen: (open: boolean) => void;
  maintStatusFilter: AgencyMaintStatusFilter;
  setMaintStatusFilter: (status: AgencyMaintStatusFilter) => void;
  maintSearchQuery: string;
  setMaintSearchQuery: (q: string) => void;
  updatingMaintId: string | null;
  handleUpdateMaintenanceStatus: (id: string, newStatus: "open" | "in_progress" | "resolved") => void;
  onSelectRequest: (req: AgencyMaintenanceRequest) => void;
  selectedRequest?: AgencyMaintenanceRequest | null;
  onBackFromDetail?: () => void;
  onUpdateRequest?: (updated: AgencyMaintenanceRequest) => void;
  onNavigateToProperty?: (propertyId: string) => void;
  onCreateTask?: (prefill: AgencyTaskPrefill) => void;
  tasks?: AgencyTask[];
  assignees?: AgencyAssigneeOption[];
  onQuickTaskStatus?: (task: AgencyTask, status: AgencyTaskStatus) => Promise<void>;
  userId?: string | null;
  isDemoMode?: boolean;
  isDemoVerified?: boolean;
  onRequestVerification?: () => void;
  t: (key: string, params?: Record<string, any>) => string;
}

export default function MaintenanceTab({
  maintenanceRequests,
  loadingMaintenance,
  maintenanceStats,
  filteredMaintenanceRequests,
  managedProperties,
  setNewMaintPropId,
  setIsNewMaintModalOpen,
  maintStatusFilter,
  setMaintStatusFilter,
  maintSearchQuery,
  setMaintSearchQuery,
  updatingMaintId,
  handleUpdateMaintenanceStatus,
  onSelectRequest,
  selectedRequest = null,
  onBackFromDetail,
  onUpdateRequest,
  onNavigateToProperty,
  onCreateTask,
  tasks = [],
  assignees = [],
  onQuickTaskStatus,
  userId = null,
  isDemoMode = false,
  isDemoVerified,
  onRequestVerification,
  t,
}: MaintenanceTabProps) {
  // ── 1. Search & Detailed Filters State (Matches PaymentsTab Architecture) ──
  const [isFilterExpanded, setIsFilterExpanded] = useState<boolean>(true);
  const [searchQuery, setSearchQuery] = useState<string>(maintSearchQuery || "");
  const [periodPreset, setPeriodPreset] = useState<"all_time" | "this_month" | "last_month" | "this_year">("all_time");
  const [selectedPropertyId, setSelectedPropertyId] = useState<string>("all");
  const [selectedLandlord, setSelectedLandlord] = useState<string>("all");
  const [selectedCategory, setSelectedCategory] = useState<string>("all");
  const [expandedMaintTaskIds, setExpandedMaintTaskIds] = useState<Set<string>>(new Set());

  const tasksByMaintId = useMemo(() => {
    const map = new Map<string, AgencyTask[]>();
    for (const tk of tasks) {
      if (tk.maintenance_request_id) {
        const list = map.get(tk.maintenance_request_id) || [];
        list.push(tk);
        map.set(tk.maintenance_request_id, list);
      }
    }
    return map;
  }, [tasks]);

  const assigneeMap = useMemo(
    () => new Map(assignees.map((a) => [a.id, a])),
    [assignees]
  );

  const toggleMaintTasks = (maintId: string) => {
    setExpandedMaintTaskIds((prev) => {
      const next = new Set(prev);
      if (next.has(maintId)) next.delete(maintId);
      else next.add(maintId);
      return next;
    });
  };
  const [selectedPriority, setSelectedPriority] = useState<string>("all");
  const [selectedExpenseStatus, setSelectedExpenseStatus] = useState<string>("all");
  const [sortBy, setSortBy] = useState<"newest" | "oldest" | "priority_desc" | "cost_desc" | "cost_asc">("newest");

  // ── 2. Middle Tier Selected Segment (Summary Cards) ──
  const [selectedSegment, setSelectedSegment] = useState<AgencyMaintStatusFilter>(
    maintStatusFilter || "all"
  );

  // Sync external filter from parent (e.g. clicked from WelcomeTab cockpit)
  useEffect(() => {
    if (maintStatusFilter) {
      setSelectedSegment(maintStatusFilter);
    }
  }, [maintStatusFilter]);

  const handleSegmentChange = (seg: AgencyMaintStatusFilter) => {
    setSelectedSegment(seg);
    if (setMaintStatusFilter) {
      setMaintStatusFilter(seg);
    }
  };

  // Sync external search query
  useEffect(() => {
    if (maintSearchQuery !== undefined && maintSearchQuery !== searchQuery) {
      setSearchQuery(maintSearchQuery);
    }
  }, [maintSearchQuery]);

  const handleSearchChange = (val: string) => {
    setSearchQuery(val);
    if (setMaintSearchQuery) {
      setMaintSearchQuery(val);
    }
  };

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

  // Filter Helper: checks if a date falls in periodPreset
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

  // Check if active filters exist
  const hasActiveFilters = useMemo(() => {
    return (
      searchQuery.trim().length > 0 ||
      periodPreset !== "all_time" ||
      selectedPropertyId !== "all" ||
      selectedLandlord !== "all" ||
      selectedCategory !== "all" ||
      selectedPriority !== "all" ||
      selectedExpenseStatus !== "all" ||
      sortBy !== "newest"
    );
  }, [
    searchQuery,
    periodPreset,
    selectedPropertyId,
    selectedLandlord,
    selectedCategory,
    selectedPriority,
    selectedExpenseStatus,
    sortBy,
  ]);

  const handleResetFilters = () => {
    handleSearchChange("");
    setPeriodPreset("all_time");
    setSelectedPropertyId("all");
    setSelectedLandlord("all");
    setSelectedCategory("all");
    setSelectedPriority("all");
    setSelectedExpenseStatus("all");
    setSortBy("newest");
    setSelectedSegment("all");
    if (setMaintStatusFilter) {
      setMaintStatusFilter("all");
    }
  };

  // ── Scoped requests matching top Search & Detailed Filters ──
  const scopedRequests = useMemo(() => {
    return maintenanceRequests.filter((m) => {
      // 1. Period preset
      if (periodPreset !== "all_time" && m.created_at) {
        if (!isDateInPeriod(m.created_at, periodPreset)) return false;
      }

      // 2. Search query
      if (searchQuery.trim()) {
        const q = searchQuery.toLowerCase().trim();
        const matchTicket = (m.ticket_number || "").toLowerCase().includes(q);
        const matchTitle = (m.title || "").toLowerCase().includes(q);
        const matchDesc = (m.description || "").toLowerCase().includes(q);
        const matchProp =
          (m.property_title || "").toLowerCase().includes(q) ||
          (m.property_address || "").toLowerCase().includes(q);
        const matchReporter = (m.reporter_name || "").toLowerCase().includes(q);
        if (!matchTicket && !matchTitle && !matchDesc && !matchProp && !matchReporter) {
          return false;
        }
      }

      // 3. Property
      if (selectedPropertyId !== "all" && m.property_id !== selectedPropertyId) {
        return false;
      }

      // 4. Landlord
      if (selectedLandlord !== "all") {
        const prop = propertiesMap[m.property_id];
        if (prop?.landlord_name !== selectedLandlord) return false;
      }

      // 5. Category
      if (selectedCategory !== "all") {
        if (
          (selectedCategory === "appliance" || selectedCategory === "appliances") &&
          (m.category === "appliance" || m.category === "appliances")
        ) {
          // match
        } else if (m.category !== selectedCategory) {
          return false;
        }
      }

      // 6. Priority
      if (selectedPriority !== "all" && m.priority !== selectedPriority) {
        return false;
      }

      // 7. Expense status
      if (selectedExpenseStatus !== "all") {
        const hasExpense =
          m.cost_amount !== null &&
          m.cost_amount !== undefined &&
          Number(m.cost_amount) > 0;
        const pStatus = m.payment_status || "pending_review";

        if (selectedExpenseStatus === "has_expense" && !hasExpense) return false;
        if (selectedExpenseStatus === "no_expense" && hasExpense) return false;
        if (selectedExpenseStatus === "pending_review" && (!hasExpense || pStatus !== "pending_review")) return false;
        if (selectedExpenseStatus === "pending_payment" && (!hasExpense || pStatus !== "pending_payment")) return false;
        if (selectedExpenseStatus === "paid" && (!hasExpense || pStatus !== "paid")) return false;
        if (selectedExpenseStatus === "rejected" && (!hasExpense || pStatus !== "rejected")) return false;
      }

      return true;
    });
  }, [
    maintenanceRequests,
    periodPreset,
    searchQuery,
    selectedPropertyId,
    selectedLandlord,
    selectedCategory,
    selectedPriority,
    selectedExpenseStatus,
    propertiesMap,
  ]);

  // ── Summary metrics for middle-tier KPI cards (computed dynamically from scopedRequests) ──
  const summaryMetrics = useMemo(() => {
    let openCount = 0;
    let inProgressCount = 0;
    let pendingApprovalCount = 0;
    let resolvedCount = 0;
    let totalCost = 0;

    scopedRequests.forEach((m) => {
      const isResolved = m.status === "resolved" || m.status === "closed";
      const isInProgress = m.status === "in_progress";
      const isOpen = m.status === "open" || m.status === "investigating" || m.status === "pending" || (!isResolved && !isInProgress);

      if (isResolved) resolvedCount++;
      else if (isInProgress) inProgressCount++;
      else if (isOpen) openCount++;

      const hasExpense = m.cost_amount !== null && m.cost_amount !== undefined && Number(m.cost_amount) > 0;
      if (hasExpense) {
        totalCost += Number(m.cost_amount) || 0;
        const pStatus = m.payment_status || "pending_review";
        if (
          pStatus === "pending_review" ||
          pStatus === "pending_payment" ||
          pStatus === "pending_agency_approval" ||
          pStatus === "pending_opposite_approval" ||
          pStatus === "pending_landlord_approval" ||
          pStatus === "pending_tenant_approval"
        ) {
          pendingApprovalCount++;
        }
      }
    });

    return {
      allCount: scopedRequests.length,
      openCount,
      inProgressCount,
      pendingApprovalCount,
      resolvedCount,
      totalCost,
    };
  }, [scopedRequests]);

  // ── Final displayed list filtered by middle-tier selectedSegment & sorted by sortBy ──
  const displayedRequests = useMemo(() => {
    let list = scopedRequests.filter((m) => {
      const isResolved = m.status === "resolved" || m.status === "closed";
      const isInProgress = m.status === "in_progress";
      const isOpen = m.status === "open" || m.status === "investigating" || m.status === "pending" || (!isResolved && !isInProgress);

      if (selectedSegment === "all") return true;
      if (selectedSegment === "open") return isOpen;
      if (selectedSegment === "in_progress") return isInProgress;
      if (selectedSegment === "pending_approval") {
        const hasExpense = m.cost_amount !== null && m.cost_amount !== undefined && Number(m.cost_amount) > 0;
        const pStatus = m.payment_status || "pending_review";
        return (
          hasExpense &&
          (pStatus === "pending_review" ||
            pStatus === "pending_payment" ||
            pStatus === "pending_agency_approval" ||
            pStatus === "pending_opposite_approval" ||
            pStatus === "pending_landlord_approval" ||
            pStatus === "pending_tenant_approval")
        );
      }
      if (selectedSegment === "resolved") return isResolved;
      return true;
    });

    return [...list].sort((a, b) => {
      if (sortBy === "oldest") {
        return new Date(a.created_at || 0).getTime() - new Date(b.created_at || 0).getTime();
      }
      if (sortBy === "priority_desc") {
        const pRank: Record<string, number> = { urgent: 4, high: 3, normal: 2, low: 1 };
        return (pRank[b.priority || "normal"] || 0) - (pRank[a.priority || "normal"] || 0);
      }
      if (sortBy === "cost_desc") {
        return (Number(b.cost_amount) || 0) - (Number(a.cost_amount) || 0);
      }
      if (sortBy === "cost_asc") {
        return (Number(a.cost_amount) || 0) - (Number(b.cost_amount) || 0);
      }
      return new Date(b.created_at || 0).getTime() - new Date(a.created_at || 0).getTime();
    });
  }, [scopedRequests, selectedSegment, sortBy]);

  // If a request is selected for detail view
  if (selectedRequest) {
    const prop =
      managedProperties.find((p) => p.id === selectedRequest.property_id) || null;
    return (
      <div
        role="tabpanel"
        id="tabpanel-maintenance"
        aria-labelledby="tab-maintenance"
        className="space-y-6 animate-in fade-in duration-200"
      >
        <MaintenanceDetailView
          request={selectedRequest}
          property={prop}
          onBack={onBackFromDetail || (() => { })}
          onUpdateRequest={onUpdateRequest || (() => { })}
          onNavigateToProperty={onNavigateToProperty}
          userId={userId}
          isDemoMode={isDemoMode}
          isDemoVerified={isDemoVerified}
          onRequestVerification={onRequestVerification}
          t={t}
        />
      </div>
    );
  }

  return (
    <div
      role="tabpanel"
      id="tabpanel-maintenance"
      aria-labelledby="tab-maintenance"
      className="space-y-6 animate-in fade-in duration-200"
    >
      {/* ── Top Tier: Collapsible Search & Detailed Filters Panel ── */}
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
            {/* Row 1: Search Input & Period Preset Selector */}
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
              <div className="sm:col-span-2 relative bg-white rounded-[8px] border border-[#E2E8F0] shadow-2xs">
                <Search className="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" />
                <input
                  type="text"
                  value={searchQuery}
                  onChange={(e) => handleSearchChange(e.target.value)}
                  placeholder={t("agency_maint_search_placeholder")}
                  className="w-full pl-10 pr-9 py-2.5 text-[#0F172A] placeholder:text-slate-400 rounded-[8px] focus:outline-hidden focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500"
                />
                {searchQuery && (
                  <button
                    type="button"
                    onClick={() => handleSearchChange("")}
                    className="absolute right-3 top-1/2 -translate-y-1/2 p-1 text-slate-400 hover:text-slate-600 rounded-full cursor-pointer"
                  >
                    <X className="w-3.5 h-3.5" />
                  </button>
                )}
              </div>

              {/* Period Selector */}
              <div className="relative bg-white rounded-[8px] border border-[#E2E8F0] shadow-2xs">
                <select
                  value={periodPreset}
                  onChange={(e) => setPeriodPreset(e.target.value as any)}
                  className="w-full pl-9 pr-8 py-2.5 font-semibold text-[#0F172A] bg-transparent rounded-[8px] appearance-none focus:outline-hidden focus:ring-2 focus:ring-blue-500/20 cursor-pointer"
                >
                  <option value="all_time">{t("periodAllTime")}</option>
                  <option value="this_month">{t("periodThisMonth")}</option>
                  <option value="last_month">{t("periodLastMonth")}</option>
                  <option value="this_year">{t("periodThisYear")}</option>
                </select>
                <Calendar className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none" />
                <ChevronDown className="w-4 h-4 text-slate-400 absolute right-3 top-1/2 -translate-y-1/2 pointer-events-none" />
              </div>
            </div>

            {/* Row 2: Property, Landlord, Category, Priority */}
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3">
              {/* Properties */}
              <div className="relative bg-white rounded-[8px] border border-[#E2E8F0] shadow-2xs">
                <select
                  value={selectedPropertyId}
                  onChange={(e) => setSelectedPropertyId(e.target.value)}
                  className="w-full pl-9 pr-8 py-2.5 font-medium text-[#0F172A] bg-transparent rounded-[8px] appearance-none focus:outline-hidden focus:ring-2 focus:ring-blue-500/20 cursor-pointer truncate"
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

              {/* Landlords */}
              <div className="relative bg-white rounded-[8px] border border-[#E2E8F0] shadow-2xs">
                <select
                  value={selectedLandlord}
                  onChange={(e) => setSelectedLandlord(e.target.value)}
                  className="w-full pl-9 pr-8 py-2.5 font-medium text-[#0F172A] bg-transparent rounded-[8px] appearance-none focus:outline-hidden focus:ring-2 focus:ring-blue-500/20 cursor-pointer truncate"
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

              {/* Category */}
              <div className="relative bg-white rounded-[8px] border border-[#E2E8F0] shadow-2xs">
                <select
                  value={selectedCategory}
                  onChange={(e) => setSelectedCategory(e.target.value)}
                  className="w-full pl-9 pr-8 py-2.5 font-medium text-[#0F172A] bg-transparent rounded-[8px] appearance-none focus:outline-hidden focus:ring-2 focus:ring-blue-500/20 cursor-pointer"
                >
                  <option value="all">{t("agency_maint_filter_all_categories")}</option>
                  <option value="plumbing">{t("agency_maint_cat_plumbing")}</option>
                  <option value="electrical">{t("agency_maint_cat_electrical")}</option>
                  <option value="heating">{t("agency_maint_cat_heating")}</option>
                  <option value="appliances">{t("agency_maint_cat_appliances")}</option>
                  <option value="internet">{t("agency_maint_cat_internet")}</option>
                  <option value="structural">{t("agency_maint_cat_structural")}</option>
                  <option value="other">{t("agency_maint_cat_other")}</option>
                </select>
                <Tag className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none" />
                <ChevronDown className="w-4 h-4 text-slate-400 absolute right-3 top-1/2 -translate-y-1/2 pointer-events-none" />
              </div>

              {/* Priority */}
              <div className="relative bg-white rounded-[8px] border border-[#E2E8F0] shadow-2xs">
                <select
                  value={selectedPriority}
                  onChange={(e) => setSelectedPriority(e.target.value)}
                  className="w-full pl-9 pr-8 py-2.5 font-medium text-[#0F172A] bg-transparent rounded-[8px] appearance-none focus:outline-hidden focus:ring-2 focus:ring-blue-500/20 cursor-pointer"
                >
                  <option value="all">{t("agency_maint_filter_all_priorities")}</option>
                  <option value="urgent">{t("agency_maint_priority_urgent")}</option>
                  <option value="high">{t("agency_maint_priority_high")}</option>
                  <option value="normal">{t("agency_maint_priority_normal")}</option>
                  <option value="low">{t("agency_maint_priority_low")}</option>
                </select>
                <AlertTriangle className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none" />
                <ChevronDown className="w-4 h-4 text-slate-400 absolute right-3 top-1/2 -translate-y-1/2 pointer-events-none" />
              </div>
            </div>

            {/* Row 3: Expense Status & Sorting */}
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              {/* Expense / Settlement Status */}
              <div className="relative bg-white rounded-[8px] border border-[#E2E8F0] shadow-2xs">
                <select
                  value={selectedExpenseStatus}
                  onChange={(e) => setSelectedExpenseStatus(e.target.value)}
                  className="w-full pl-9 pr-8 py-2.5 font-medium text-[#0F172A] bg-transparent rounded-[8px] appearance-none focus:outline-hidden focus:ring-2 focus:ring-blue-500/20 cursor-pointer"
                >
                  <option value="all">{t("agency_maint_filter_all_expense_statuses")}</option>
                  <option value="has_expense">{t("agency_maint_filter_has_expense")}</option>
                  <option value="no_expense">{t("agency_maint_filter_no_expense_only")}</option>
                  <option value="pending_review">{t("agency_maint_status_pending_review")}</option>
                  <option value="pending_payment">{t("agency_maint_status_pending_payment")}</option>
                  <option value="paid">{t("agency_maint_status_paid")}</option>
                  <option value="rejected">{t("agency_maint_status_rejected")}</option>
                </select>
                <Wallet className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none" />
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
                  <option value="priority_desc">{t("agency_maint_sort_priority_desc")}</option>
                  <option value="cost_desc">{t("sortByAmountDesc")}</option>
                  <option value="cost_asc">{t("sortByAmountAsc")}</option>
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
                  onClick={handleResetFilters}
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

      {/* ── Middle Tier: Summary Filter Cards (KPI Cards with Click-to-Filter) ── */}
      <div className="grid grid-cols-2 md:grid-cols-5 gap-3">
        {/* 1. All Requests */}
        <div
          onClick={() => handleSegmentChange("all")}
          className={`p-3.5 rounded-[10px] border transition-all cursor-pointer ${selectedSegment === "all"
              ? "bg-slate-100/90 border-[#1B5888] ring-2 ring-[#1B5888]/30 shadow-xs"
              : "bg-white border-[#E2E8F0] hover:bg-slate-50"
            }`}
        >
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-slate-500 truncate">
              {t("agency_maint_filter_all")}
            </span>
            <div className="w-6 h-6 rounded-full bg-slate-100 text-[#1B5888] flex items-center justify-center">
              <Wrench className="w-3.5 h-3.5 text-[#1B5888] shrink-0" />
            </div>
          </div>
          <div className="flex items-baseline gap-2 mt-1.5">
            <div className="text-xl font-semibold text-[#0F172A] font-mono tabular-nums">
              {summaryMetrics.allCount}
            </div>
            <span className="text-[11px] text-slate-400 font-medium">
              €{summaryMetrics.totalCost.toLocaleString()}
            </span>
          </div>
        </div>

        {/* 2. Action Required / Open */}
        <div
          onClick={() => handleSegmentChange("open")}
          className={`p-3.5 rounded-[10px] border transition-all cursor-pointer ${selectedSegment === "open"
              ? "bg-amber-50/80 border-amber-300 ring-2 ring-amber-400/40 shadow-xs"
              : "bg-white border-[#E2E8F0] hover:bg-slate-50"
            }`}
        >
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-slate-500 truncate">
              {t("agency_maint_stat_open")}
            </span>
            <div className="w-6 h-6 rounded-full bg-amber-50 text-amber-600 flex items-center justify-center">
              <AlertTriangle className="w-3.5 h-3.5 text-amber-600 shrink-0" />
            </div>
          </div>
          <div className="flex items-baseline gap-2 mt-1.5">
            <div className="text-xl font-semibold text-[#0F172A] font-mono tabular-nums">
              {summaryMetrics.openCount}
            </div>
            {summaryMetrics.openCount > 0 && (
              <span className="w-2 h-2 rounded-full bg-rose-500 animate-pulse" />
            )}
          </div>
        </div>

        {/* 3. In Progress */}
        <div
          onClick={() => handleSegmentChange("in_progress")}
          className={`p-3.5 rounded-[10px] border transition-all cursor-pointer ${selectedSegment === "in_progress"
              ? "bg-blue-50/80 border-blue-300 ring-2 ring-blue-400/40 shadow-xs"
              : "bg-white border-[#E2E8F0] hover:bg-slate-50"
            }`}
        >
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-slate-500 truncate">
              {t("agency_maint_stat_in_progress")}
            </span>
            <div className="w-6 h-6 rounded-full bg-blue-50 text-blue-600 flex items-center justify-center">
              <Clock className="w-3.5 h-3.5 text-blue-600 shrink-0" />
            </div>
          </div>
          <div className="text-xl font-semibold text-[#0F172A] mt-1.5 font-mono tabular-nums">
            {summaryMetrics.inProgressCount}
          </div>
        </div>

        {/* 4. Financial Approval Pending */}
        <div
          onClick={() => handleSegmentChange("pending_approval")}
          className={`p-3.5 rounded-[10px] border transition-all cursor-pointer ${selectedSegment === "pending_approval"
              ? "bg-purple-50/80 border-purple-300 ring-2 ring-purple-400/40 shadow-xs"
              : "bg-white border-[#E2E8F0] hover:bg-slate-50"
            }`}
        >
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-slate-500 truncate">
              {t("agency_maint_stat_pending_approval")}
            </span>
            <div className="w-6 h-6 rounded-full bg-purple-50 text-purple-600 flex items-center justify-center">
              <Wallet className="w-3.5 h-3.5 text-purple-600 shrink-0" />
            </div>
          </div>
          <div className="flex items-baseline gap-2 mt-1.5">
            <div className="text-xl font-semibold text-[#0F172A] font-mono tabular-nums">
              {summaryMetrics.pendingApprovalCount}
            </div>
            {summaryMetrics.pendingApprovalCount > 0 && (
              <span className="w-2 h-2 rounded-full bg-purple-500" />
            )}
          </div>
        </div>

        {/* 5. Resolved / Closed */}
        <div
          onClick={() => handleSegmentChange("resolved")}
          className={`p-3.5 rounded-[10px] border transition-all cursor-pointer ${selectedSegment === "resolved"
              ? "bg-emerald-50/80 border-emerald-300 ring-2 ring-emerald-400/40 shadow-xs"
              : "bg-white border-[#E2E8F0] hover:bg-slate-50"
            }`}
        >
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-slate-500 truncate">
              {t("agency_maint_stat_resolved")}
            </span>
            <div className="w-6 h-6 rounded-full bg-emerald-50 text-emerald-600 flex items-center justify-center">
              <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600 shrink-0" />
            </div>
          </div>
          <div className="text-xl font-semibold text-[#0F172A] mt-1.5 font-mono tabular-nums">
            {summaryMetrics.resolvedCount}
          </div>
        </div>
      </div>

      {/* ── Bottom Tier: Filtered Maintenance Requests Table ── */}
      {loadingMaintenance ? (
        <div className="p-12 text-center text-xs text-[#666666] flex items-center justify-center gap-2">
          <RefreshCw className="w-4 h-4 animate-spin" />
          <span>{t("agency_panel_loading")}</span>
        </div>
      ) : displayedRequests.length === 0 ? (
        <div className="bg-white rounded-[10px] border border-[#E5E3DF] p-12 text-center shadow-xs space-y-3">
          <div className="w-12 h-12 rounded-[10px] bg-slate-100 text-[#666666] flex items-center justify-center mx-auto">
            <Wrench className="w-6 h-6" />
          </div>
          <h3 className="text-base font-bold text-[#1A1A1A]">
            {t("agency_maint_empty_title")}
          </h3>
          <p className="text-xs text-[#666666] max-w-md mx-auto leading-relaxed">
            {t("agency_maint_empty_desc")}
          </p>
          {hasActiveFilters && (
            <button
              type="button"
              onClick={handleResetFilters}
              className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-[8px] text-xs font-semibold text-[#1B5888] bg-blue-50 hover:bg-blue-100 transition-colors cursor-pointer mt-2"
            >
              <RotateCcw className="w-3.5 h-3.5" />
              <span>{t("financeFilterReset")}</span>
            </button>
          )}
        </div>
      ) : (
        <>
          {/* Desktop Table View */}
          <div className="hidden md:block bg-white rounded-[10px] border border-[#E5E3DF] shadow-xs overflow-hidden">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="border-b border-[#E5E3DF] bg-slate-50/75 text-[11px] font-bold text-[#666666] uppercase tracking-wider">
                  <th className="py-3 px-4">{t("agency_maint_col_ticket")}</th>
                  <th className="py-3 px-4">{t("agency_maint_col_property")}</th>
                  <th className="py-3 px-4">{t("agency_maint_col_issue")}</th>
                  <th className="py-3 px-4">{t("agency_maint_col_priority")}</th>
                  <th className="py-3 px-4">{t("agency_maint_col_status")}</th>
                  <th className="py-3 px-4">{t("agency_maint_col_cost")}</th>
                  <th className="py-3 px-4">{t("agency_maint_col_expense_status")}</th>
                  <th className="py-3 px-4 text-right">{t("agency_maint_col_actions")}</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 text-xs text-[#4A4A4A]">
                {displayedRequests.map((m) => {
                  const isResolved = m.status === "resolved" || m.status === "closed";
                  const isInProgress = m.status === "in_progress";

                  const catLabel =
                    m.category === "plumbing"
                      ? t("agency_maint_cat_plumbing")
                      : m.category === "electrical"
                        ? t("agency_maint_cat_electrical")
                        : m.category === "heating"
                          ? t("agency_maint_cat_heating")
                          : m.category === "appliance"
                            ? t("agency_maint_cat_appliance")
                            : m.category === "appliances"
                              ? t("agency_maint_cat_appliances")
                              : m.category === "internet"
                                ? t("agency_maint_cat_internet")
                                : m.category === "structural"
                                  ? t("agency_maint_cat_structural")
                                  : t("agency_maint_cat_other");

                  const prioLabel =
                    m.priority === "urgent"
                      ? t("agency_maint_priority_urgent")
                      : m.priority === "high"
                        ? t("agency_maint_priority_high")
                        : m.priority === "low"
                          ? t("agency_maint_priority_low")
                          : t("agency_maint_priority_normal");

                  const payerLabel =
                    m.paid_by === "landlord"
                      ? t("agency_maint_payer_landlord")
                      : m.paid_by === "tenant"
                        ? t("agency_maint_payer_tenant")
                        : m.paid_by === "agency"
                          ? t("agency_maint_payer_agency")
                          : "-";

                  const linkedTasks = tasksByMaintId.get(m.id) || [];
                  const isTasksExpanded = expandedMaintTaskIds.has(m.id);

                  return (
                    <React.Fragment key={m.id}>
                    <tr
                      onClick={() => onSelectRequest(m)}
                      className="hover:bg-slate-50/80 transition-colors cursor-pointer group"
                    >
                      <td className="py-3.5 px-4">
                        <div className="font-mono font-bold text-[#1A1A1A] group-hover:text-blue-600 transition-colors">
                          {m.ticket_number}
                        </div>
                        <MaintenanceCategoryBadge
                          category={m.category}
                          label={catLabel}
                          className="mt-1"
                        />
                        {linkedTasks.length > 0 && (
                          <button
                            type="button"
                            onClick={(e) => {
                              e.stopPropagation();
                              toggleMaintTasks(m.id);
                            }}
                            className="mt-1.5 inline-flex items-center gap-1 px-2 py-0.5 rounded-md bg-[#E5EEF6] hover:bg-[#1B5888] text-[#1B5888] hover:text-white text-[10px] font-bold transition-colors cursor-pointer"
                          >
                            <CheckSquare className="w-3 h-3" />
                            <span>{linkedTasks.length}</span>
                            {isTasksExpanded ? (
                              <ChevronUp className="w-3 h-3" />
                            ) : (
                              <ChevronDown className="w-3 h-3" />
                            )}
                          </button>
                        )}
                      </td>
                      <td className="py-3.5 px-4">
                        <div className="font-bold text-[#1A1A1A]">
                          {m.property_title || "Daire"}
                        </div>
                        {m.property_address && (
                          <div className="text-[11px] text-[#666666] flex items-center gap-1 mt-0.5">
                            <MapPin className="w-3 h-3 text-[#666666] shrink-0" />
                            <span className="truncate max-w-[180px]">{m.property_address}</span>
                          </div>
                        )}
                        {m.reporter_name && (
                          <div className="text-[11px] text-[#4A4A4A] flex items-center gap-1 mt-1 font-medium">
                            <User className="w-3 h-3 text-[#666666] shrink-0" />
                            <span>{m.reporter_name}</span>
                          </div>
                        )}
                      </td>
                      <td className="py-3.5 px-4 max-w-xs">
                        <div className="font-semibold text-[#1A1A1A] line-clamp-1">{m.title}</div>
                        {m.description && (
                          <p className="text-[11px] text-[#666666] line-clamp-2 mt-0.5 leading-relaxed">
                            {m.description}
                          </p>
                        )}
                      </td>
                      <td className="py-3.5 px-4">
                        <span className="inline-flex items-center gap-1.5 px-2 py-0.5 rounded-md border border-[#E5E3DF] bg-white text-[11px] font-medium text-[#4A4A4A] shadow-2xs">
                          <span
                            className={`w-1.5 h-1.5 rounded-full ${m.priority === "urgent"
                                ? "bg-rose-500 ring-2 ring-rose-500/20"
                                : m.priority === "high"
                                  ? "bg-amber-500 ring-2 ring-amber-500/20"
                                  : m.priority === "low"
                                    ? "bg-slate-300"
                                    : "bg-slate-400"
                              }`}
                          />
                          {prioLabel}
                        </span>
                      </td>
                      <td className="py-3.5 px-4">
                        {isResolved ? (
                          <span className="inline-flex items-center gap-1.5 px-2 py-0.5 rounded-md border border-[#E5E3DF] bg-white text-[11px] font-medium text-[#4A4A4A] shadow-2xs">
                            <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 ring-2 ring-emerald-500/20" />
                            {t("agency_maint_status_resolved")}
                          </span>
                        ) : isInProgress ? (
                          <span className="inline-flex items-center gap-1.5 px-2 py-0.5 rounded-md border border-[#E5E3DF] bg-white text-[11px] font-medium text-[#4A4A4A] shadow-2xs">
                            <span className="w-1.5 h-1.5 rounded-full bg-blue-500 ring-2 ring-blue-500/20" />
                            {t("agency_maint_status_in_progress")}
                          </span>
                        ) : (
                          <span className="inline-flex items-center gap-1.5 px-2 py-0.5 rounded-md border border-[#E5E3DF] bg-white text-[11px] font-medium text-[#4A4A4A] shadow-2xs">
                            <span className="w-1.5 h-1.5 rounded-full bg-amber-500 ring-2 ring-amber-500/20" />
                            {t("agency_maint_status_open")}
                          </span>
                        )}
                      </td>
                      <td className="py-3.5 px-4">
                        <div className="font-semibold text-[#1A1A1A] font-mono tabular-nums">
                          {m.cost_amount ? `€${Number(m.cost_amount).toLocaleString()}` : "-"}
                        </div>
                        {m.cost_amount && Number(m.settled_amount || 0) > 0 && (() => {
                          const orig = Number(m.cost_amount) || 0;
                          const settd = Number(m.settled_amount) || 0;
                          const rem = Math.max(0, orig - settd);
                          const cur = m.currency || "EUR";
                          return (
                            <div
                              className={`text-[10px] font-semibold mt-0.5 ${rem > 0 ? "text-amber-700" : "text-emerald-700"
                                }`}
                            >
                              {rem > 0
                                ? t("agency_maint_offset_and_remaining", {
                                  offset: `${settd.toLocaleString()} ${cur}`,
                                  remaining: `${rem.toLocaleString()} ${cur}`,
                                })
                                : t("agency_maint_offset_fully_settled", {
                                  offset: `${settd.toLocaleString()} ${cur}`,
                                })}
                            </div>
                          );
                        })()}
                        <div className="text-[10px] text-[#666666] mt-0.5">
                          {payerLabel}
                        </div>
                      </td>
                      <td className="py-3.5 px-4 whitespace-nowrap">
                        {(() => {
                          const hasExpense =
                            m.cost_amount !== null &&
                            m.cost_amount !== undefined &&
                            Number(m.cost_amount) > 0;
                          if (!hasExpense) {
                            return (
                              <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-md text-[11px] font-semibold bg-slate-100 text-slate-500 border border-slate-200">
                                <span className="w-1.5 h-1.5 rounded-full bg-slate-400" />
                                <span>{t("agency_maint_status_no_expense")}</span>
                              </span>
                            );
                          }

                          const pStatus = m.payment_status || "pending_review";
                          const isPaid = pStatus === "paid";
                          const isRejected = pStatus === "rejected";
                          const isPendingPayment = pStatus === "pending_payment";

                          const badgeStyle = isPaid
                            ? "bg-emerald-50 text-emerald-800 border-emerald-200"
                            : isRejected
                              ? "bg-rose-50 text-rose-800 border-rose-200"
                              : isPendingPayment
                                ? "bg-blue-50 text-blue-800 border-blue-200"
                                : "bg-amber-50 text-amber-800 border-amber-200";

                          const dotStyle = isPaid
                            ? "bg-emerald-500"
                            : isRejected
                              ? "bg-rose-500"
                              : isPendingPayment
                                ? "bg-blue-500"
                                : "bg-amber-500";

                          return (
                            <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-md text-[11px] font-semibold border ${badgeStyle}`}>
                              <span className={`w-1.5 h-1.5 rounded-full ${dotStyle}`} />
                              <span>{getMaintenanceExpenseStatusLabel(pStatus, t)}</span>
                            </span>
                          );
                        })()}
                      </td>
                      <td className="py-3.5 px-3 text-right">
                        <div className="flex flex-wrap items-center justify-end gap-1.5">
                          {onCreateTask && (
                            <button
                              type="button"
                              title={t("agency_tasks_quick_assign_btn")}
                              aria-label={t("agency_tasks_quick_assign_btn")}
                              onClick={(e) => {
                                e.stopPropagation();
                                onCreateTask({
                                  source_type: "maintenance",
                                  maintenance_request_id: m.id,
                                  property_id: m.property_id,
                                  title: m.title,
                                  description: m.description || undefined,
                                  priority:
                                    m.priority === "urgent"
                                      ? "urgent"
                                      : m.priority === "high"
                                        ? "high"
                                        : "medium",
                                });
                              }}
                              className="p-1.5 rounded-lg border border-[#E5E3DF] bg-white text-[#1B5888] hover:bg-[#E5EEF6] transition-colors cursor-pointer shrink-0"
                            >
                              <CheckSquare className="w-4 h-4" />
                            </button>
                          )}

                          {m.reporter_phone && (
                            <a
                              href={`https://wa.me/${m.reporter_phone.replace(/[^0-9]/g, "")}?text=${encodeURIComponent(
                                t("agency_maint_whatsapp_msg", { ticketNumber: m.ticket_number || "" })
                              )}`}
                              target="_blank"
                              rel="noopener noreferrer"
                              title="WhatsApp"
                              onClick={(e) => e.stopPropagation()}
                              className="p-1.5 rounded-lg bg-[#E6F3EA] text-[#2A6E43] hover:bg-[#E6F3EA] transition-colors"
                            >
                              <MessageCircle className="w-4 h-4" />
                            </a>
                          )}

                          {!isResolved && !isInProgress && (
                            <button
                              type="button"
                              disabled={updatingMaintId === m.id}
                              onClick={(e) => {
                                e.stopPropagation();
                                handleUpdateMaintenanceStatus(m.id, "in_progress");
                              }}
                              className="px-2.5 py-1.5 rounded-[10px] text-xs font-semibold bg-[#E5EEF6] text-[#12406A] hover:bg-[#E5EEF6] transition-colors cursor-pointer disabled:opacity-50"
                            >
                              {t("agency_maint_act_start")}
                            </button>
                          )}

                          {!isResolved && (
                            <button
                              type="button"
                              disabled={updatingMaintId === m.id}
                              onClick={(e) => {
                                e.stopPropagation();
                                handleUpdateMaintenanceStatus(m.id, "resolved");
                              }}
                              className="px-2.5 py-1.5 rounded-[10px] text-xs font-bold bg-[#1B5888] text-white hover:bg-emerald-700 transition-colors shadow-xs cursor-pointer disabled:opacity-50"
                            >
                              {t("agency_maint_act_resolve")}
                            </button>
                          )}

                          {isResolved && (
                            <button
                              type="button"
                              disabled={updatingMaintId === m.id}
                              onClick={(e) => {
                                e.stopPropagation();
                                handleUpdateMaintenanceStatus(m.id, "open");
                              }}
                              className="px-2.5 py-1.5 rounded-[10px] text-xs font-semibold bg-slate-100 text-[#4A4A4A] hover:bg-slate-200 transition-colors cursor-pointer disabled:opacity-50"
                            >
                              {t("agency_maint_act_reopen")}
                            </button>
                          )}
                        </div>
                      </td>
                    </tr>
                    {isTasksExpanded && linkedTasks.length > 0 && (
                      <tr className="bg-[#F8F7F5]/80">
                        <td colSpan={8} className="py-2.5 pl-10 pr-4">
                          <div className="border-l-2 border-[#1B5888]/30 pl-3 space-y-2">
                            {linkedTasks.map((tk) => {
                              const assignee = tk.assigned_to ? assigneeMap.get(tk.assigned_to) : null;
                              return (
                                <div
                                  key={tk.id}
                                  className="flex items-center justify-between gap-3 bg-white rounded-[8px] border border-[#E5E3DF] px-3 py-2"
                                >
                                  <div className="min-w-0 flex-1 flex items-center gap-2.5 flex-wrap">
                                    <CheckSquare className="w-3.5 h-3.5 text-[#1B5888] shrink-0" />
                                    <span
                                      className={`text-xs font-semibold truncate ${
                                        tk.status === "done" ? "line-through text-[#8A8A8A]" : "text-[#1A1A1A]"
                                      }`}
                                    >
                                      {tk.title}
                                    </span>
                                    <span className="text-[10px] font-semibold px-1.5 py-0.5 rounded bg-slate-100 text-slate-600 border border-slate-200">
                                      {t(`agency_tasks_priority_${tk.priority}`)}
                                    </span>
                                    {tk.due_date && (
                                      <span className="text-[10px] text-[#666666] inline-flex items-center gap-1">
                                        <Calendar className="w-3 h-3" />
                                        {tk.due_date}
                                      </span>
                                    )}
                                    <span className="text-[10px] text-[#666666] inline-flex items-center gap-1">
                                      <UserCheck className="w-3 h-3" />
                                      {assignee ? assignee.name : t("agency_tasks_unassigned")}
                                    </span>
                                  </div>

                                  {onQuickTaskStatus && (
                                    <select
                                      value={tk.status}
                                      onClick={(e) => e.stopPropagation()}
                                      onChange={(e) =>
                                        onQuickTaskStatus(tk, e.target.value as AgencyTaskStatus)
                                      }
                                      className="px-2 py-1 rounded-md border border-[#E5E3DF] text-[11px] font-semibold bg-white shrink-0"
                                    >
                                      <option value="todo">{t("agency_tasks_status_todo")}</option>
                                      <option value="in_progress">{t("agency_tasks_status_in_progress")}</option>
                                      <option value="done">{t("agency_tasks_status_done")}</option>
                                    </select>
                                  )}
                                </div>
                              );
                            })}
                          </div>
                        </td>
                      </tr>
                    )}
                    </React.Fragment>
                  );
                })}
              </tbody>
            </table>
          </div>

          {/* Mobile Card View */}
          <div className="md:hidden space-y-3">
            {displayedRequests.map((m) => {
              const isResolved = m.status === "resolved" || m.status === "closed";
              const isInProgress = m.status === "in_progress";
              const catLabel =
                m.category === "plumbing"
                  ? t("agency_maint_cat_plumbing")
                  : m.category === "electrical"
                    ? t("agency_maint_cat_electrical")
                    : m.category === "heating"
                      ? t("agency_maint_cat_heating")
                      : m.category === "appliance"
                        ? t("agency_maint_cat_appliance")
                        : m.category === "appliances"
                          ? t("agency_maint_cat_appliances")
                          : m.category === "internet"
                            ? t("agency_maint_cat_internet")
                            : m.category === "structural"
                              ? t("agency_maint_cat_structural")
                              : t("agency_maint_cat_other");

              return (
                <div
                  key={m.id}
                  onClick={() => onSelectRequest(m)}
                  className="bg-white p-4 rounded-[10px] border border-[#E5E3DF] shadow-xs space-y-3 cursor-pointer hover:border-blue-400 active:scale-[0.99] transition-all"
                >
                  <div className="flex items-start justify-between gap-2">
                    <div className="min-w-0">
                      <div className="flex items-center gap-2">
                        <span className="font-mono font-bold text-xs text-[#1A1A1A]">{m.ticket_number}</span>
                        <MaintenanceCategoryBadge
                          category={m.category}
                          label={catLabel}
                        />
                      </div>
                      <h4 className="font-bold text-[#1A1A1A] text-sm mt-1">{m.title}</h4>
                      <p className="text-xs text-[#666666] truncate mt-0.5">{m.property_title}</p>
                    </div>
                    {isResolved ? (
                      <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-[#E6F3EA] text-[#2A6E43] border border-[#2A6E43]/20 shrink-0">
                        {t("agency_maint_status_resolved")}
                      </span>
                    ) : isInProgress ? (
                      <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-[#E5EEF6] text-[#12406A] border border-[#1B5888]/20 shrink-0">
                        {t("agency_maint_status_in_progress")}
                      </span>
                    ) : (
                      <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-[#FBF1DC] text-[#8A5206] border border-[#8A5206]/20 shrink-0">
                        {t("agency_maint_status_open")}
                      </span>
                    )}
                  </div>

                  {m.description && (
                    <p className="text-xs text-[#4A4A4A] bg-slate-50 p-2.5 rounded-[10px] leading-relaxed line-clamp-2">
                      {m.description}
                    </p>
                  )}

                  <div className="flex items-center justify-between text-xs pt-1 border-t border-slate-100 text-[#666666]">
                    <div className="space-y-1">
                      <span className="block font-medium">{m.reporter_name || t("payerTenant")}</span>
                      {(() => {
                        const hasExpense =
                          m.cost_amount !== null &&
                          m.cost_amount !== undefined &&
                          Number(m.cost_amount) > 0;
                        const pStatus = m.payment_status || "pending_review";
                        return (
                          <span
                            className={`inline-flex items-center gap-1 text-[10px] font-semibold px-2 py-0.5 rounded-md border ${!hasExpense
                                ? "bg-slate-100 text-slate-500 border-slate-200"
                                : pStatus === "paid"
                                  ? "bg-emerald-50 text-emerald-800 border-emerald-200"
                                  : pStatus === "rejected"
                                    ? "bg-rose-50 text-rose-800 border-rose-200"
                                    : pStatus === "pending_payment"
                                      ? "bg-blue-50 text-blue-800 border-blue-200"
                                      : "bg-amber-50 text-amber-800 border-amber-200"
                              }`}
                          >
                            {!hasExpense
                              ? t("agency_maint_status_no_expense")
                              : getMaintenanceExpenseStatusLabel(pStatus, t)}
                          </span>
                        );
                      })()}
                    </div>
                    <div className="text-right">
                      <span className="font-bold text-[#1A1A1A] block">
                        {m.cost_amount ? `€${Number(m.cost_amount).toLocaleString()}` : "-"}
                      </span>
                      {m.cost_amount && Number(m.settled_amount || 0) > 0 && (() => {
                        const orig = Number(m.cost_amount) || 0;
                        const settd = Number(m.settled_amount) || 0;
                        const rem = Math.max(0, orig - settd);
                        const cur = m.currency || "EUR";
                        return (
                          <span
                            className={`text-[10px] font-semibold block ${rem > 0 ? "text-amber-700" : "text-emerald-700"
                              }`}
                          >
                            {rem > 0
                              ? t("agency_maint_offset_and_remaining", {
                                offset: `${settd.toLocaleString()} ${cur}`,
                                remaining: `${rem.toLocaleString()} ${cur}`,
                              })
                              : t("agency_maint_offset_fully_settled", {
                                offset: `${settd.toLocaleString()} ${cur}`,
                              })}
                          </span>
                        );
                      })()}
                    </div>
                  </div>

                  <div className="flex items-center gap-2 pt-1">
                    {!isResolved && (
                      <button
                        type="button"
                        disabled={updatingMaintId === m.id}
                        onClick={(e) => {
                          e.stopPropagation();
                          handleUpdateMaintenanceStatus(m.id, "resolved");
                        }}
                        className="flex-1 py-2 px-3 rounded-[10px] text-xs font-bold bg-[#1B5888] text-white hover:bg-emerald-700 transition-colors shadow-xs cursor-pointer flex items-center justify-center gap-1.5"
                      >
                        <CheckCircle2 className="w-3.5 h-3.5" />
                        <span>{t("agency_maint_act_resolve")}</span>
                      </button>
                    )}
                    {isResolved && (
                      <button
                        type="button"
                        disabled={updatingMaintId === m.id}
                        onClick={(e) => {
                          e.stopPropagation();
                          handleUpdateMaintenanceStatus(m.id, "open");
                        }}
                        className="flex-1 py-2 px-3 rounded-[10px] text-xs font-semibold bg-slate-100 text-[#4A4A4A] hover:bg-slate-200 transition-colors cursor-pointer flex items-center justify-center gap-1.5"
                      >
                        <span>{t("agency_maint_act_reopen")}</span>
                      </button>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        </>
      )}
    </div>
  );
}
