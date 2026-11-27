"use client";

import React, { useState, useMemo } from "react";
import {
  ArrowUpRight,
  Building2,
  Calendar,
  Check,
  CheckSquare,
  ChevronDown,
  ChevronUp,
  Clock,
  Globe,
  Inbox,
  Mail,
  MapPin,
  MessageCircle,
  Phone,
  PlusCircle,
  RefreshCw,
  RotateCcw,
  Search,
  Send,
  SlidersHorizontal,
  User,
  UserCheck,
  X,
} from "lucide-react";
import {
  AgencyAssigneeOption,
  AgencyLead,
  AgencyTask,
  AgencyTaskPrefill,
  AgencyTaskStatus,
  LeadStatus,
} from "../types";
import {
  STATUS_TRANSLATION_KEYS,
  STATUS_TOOLTIP_KEYS,
  STATUS_STYLES,
  getAllowedStatusesForType,
} from "../constants";

export interface LeadsTabProps {
  leads: AgencyLead[];
  leadPoolFilter: "all" | "owner_consignment" | "viewing_request" | "general_inquiry";
  setLeadPoolFilter: (filter: "all" | "owner_consignment" | "viewing_request" | "general_inquiry") => void;
  leadPoolCounts: {
    all: number;
    owner_consignment: number;
    viewing_request: number;
    general_inquiry: number;
  };
  leadStatusFilter: string;
  setLeadStatusFilter: (status: any) => void;
  leadSearchQuery: string;
  setLeadSearchQuery: (q: string) => void;
  filteredLeads: AgencyLead[];
  newCommentText: Record<string, string>;
  setNewCommentText: React.Dispatch<React.SetStateAction<Record<string, string>>>;
  handleAddLeadComment: (leadId: string) => void;
  handleConvertLeadToListing: (lead: AgencyLead) => void;
  handleUpdateLeadStatus: (leadId: string, newStatus: LeadStatus) => void;
  onCreateTask?: (prefill: AgencyTaskPrefill) => void;
  tasks?: AgencyTask[];
  assignees?: AgencyAssigneeOption[];
  onQuickTaskStatus?: (task: AgencyTask, status: AgencyTaskStatus) => Promise<void>;
  activeLocale: string;
  t: (key: string) => string;
}

export default function LeadsTab({
  leads,
  leadPoolFilter,
  setLeadPoolFilter,
  leadPoolCounts,
  leadStatusFilter,
  setLeadStatusFilter,
  leadSearchQuery,
  setLeadSearchQuery,
  filteredLeads,
  newCommentText,
  setNewCommentText,
  handleAddLeadComment,
  handleConvertLeadToListing,
  handleUpdateLeadStatus,
  onCreateTask,
  tasks = [],
  assignees = [],
  onQuickTaskStatus,
  activeLocale,
  t,
}: LeadsTabProps) {
  const [expandedLeadTaskIds, setExpandedLeadTaskIds] = useState<Set<string>>(new Set());

  const tasksByLeadId = useMemo(() => {
    const map = new Map<string, AgencyTask[]>();
    for (const tk of tasks) {
      if (tk.lead_id) {
        const list = map.get(tk.lead_id) || [];
        list.push(tk);
        map.set(tk.lead_id, list);
      }
    }
    return map;
  }, [tasks]);

  const assigneeMap = useMemo(
    () => new Map(assignees.map((a) => [a.id, a])),
    [assignees]
  );

  const toggleLeadTasks = (leadId: string) => {
    setExpandedLeadTaskIds((prev) => {
      const next = new Set(prev);
      if (next.has(leadId)) next.delete(leadId);
      else next.add(leadId);
      return next;
    });
  };

  const renderLeadTasksExpandButton = (leadId: string) => {
    const linked = tasksByLeadId.get(leadId) || [];
    if (linked.length === 0) return null;
    const isExpanded = expandedLeadTaskIds.has(leadId);
    return (
      <button
        type="button"
        onClick={(e) => {
          e.stopPropagation();
          toggleLeadTasks(leadId);
        }}
        className="inline-flex items-center gap-1 px-2 py-0.5 rounded-md bg-[#E5EEF6] hover:bg-[#1B5888] text-[#1B5888] hover:text-white text-[10px] font-bold transition-colors cursor-pointer"
      >
        <CheckSquare className="w-3 h-3" />
        <span>{linked.length}</span>
        {isExpanded ? <ChevronUp className="w-3 h-3" /> : <ChevronDown className="w-3 h-3" />}
      </button>
    );
  };

  const renderExpandedLeadTasks = (leadId: string) => {
    if (!expandedLeadTaskIds.has(leadId)) return null;
    const linked = tasksByLeadId.get(leadId) || [];
    if (linked.length === 0) return null;
    return (
      <div className="mt-2.5 pt-2 border-t border-slate-100">
        <div className="border-l-2 border-[#1B5888]/30 pl-2.5 space-y-1.5">
          {linked.map((tk) => {
            const assignee = tk.assigned_to ? assigneeMap.get(tk.assigned_to) : null;
            return (
              <div
                key={tk.id}
                className="flex items-center justify-between gap-2 bg-[#F8F7F5] rounded-[8px] border border-[#E5E3DF] px-2.5 py-1.5"
              >
                <div className="min-w-0 flex-1 flex items-center gap-2 flex-wrap">
                  <CheckSquare className="w-3 h-3 text-[#1B5888] shrink-0" />
                  <span
                    className={`text-[11px] font-semibold truncate ${
                      tk.status === "done" ? "line-through text-[#8A8A8A]" : "text-[#1A1A1A]"
                    }`}
                  >
                    {tk.title}
                  </span>
                  <span className="text-[10px] font-semibold px-1.5 py-0.5 rounded bg-white text-slate-600 border border-slate-200">
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
                    onChange={(e) => onQuickTaskStatus(tk, e.target.value as AgencyTaskStatus)}
                    className="px-1.5 py-0.5 rounded border border-[#E5E3DF] text-[10px] font-semibold bg-white shrink-0"
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
      </div>
    );
  };
  const [isFilterExpanded, setIsFilterExpanded] = useState<boolean>(true);
  const hasActiveFilters = leadSearchQuery.trim().length > 0 || leadStatusFilter !== "all";

  return (
<div
                  role="tabpanel"
                  id="tabpanel-leads"
                  aria-labelledby="tab-leads"
                  className="space-y-6"
                >
                  {/* Pool Navigation Tabs: 2x2 Grid on Mobile (< sm) & Bordered Horizontal Row on Desktop (>= sm) */}
                  {(() => {
                    const poolTabs = [
                      {
                        id: "all" as const,
                        label: t("agency_panel_leads_pool_all"),
                        count: leadPoolCounts.all,
                        icon: Inbox,
                      },
                      {
                        id: "owner_consignment" as const,
                        label: t("agency_panel_leads_pool_owners"),
                        count: leadPoolCounts.owner_consignment,
                        icon: Building2,
                      },
                      {
                        id: "viewing_request" as const,
                        label: t("agency_panel_leads_pool_viewings"),
                        count: leadPoolCounts.viewing_request,
                        icon: Calendar,
                      },
                      {
                        id: "general_inquiry" as const,
                        label: t("agency_panel_leads_pool_general"),
                        count: leadPoolCounts.general_inquiry,
                        icon: MessageCircle,
                      },
                    ];

                    return (
                      <div className="flex items-center gap-1 sm:gap-2 border-b border-[#E5E3DF] overflow-x-auto no-scrollbar">
                        {poolTabs.map((pool) => {
                          const IconComponent = pool.icon;
                          const isActive = leadPoolFilter === pool.id;
                          return (
                            <button
                              key={`tab-${pool.id}`}
                              type="button"
                              role="tab"
                              aria-selected={isActive}
                              onClick={() => {
                                setLeadPoolFilter(pool.id);
                                setLeadStatusFilter("all");
                              }}
                              className={`py-3 px-3 sm:px-4 text-xs font-bold border-b-2 transition-all flex items-center gap-2 cursor-pointer whitespace-nowrap -mb-px ${
                                isActive
                                  ? "border-[#1B5888] text-[#1B5888]"
                                  : "border-transparent text-[#666666] hover:text-[#1A1A1A] hover:border-slate-300"
                              }`}
                            >
                              <IconComponent
                                className={`w-4 h-4 shrink-0 ${
                                  isActive ? "text-[#1B5888]" : "text-[#8A8A8A]"
                                }`}
                              />
                              <span>{pool.label}</span>
                              <span
                                className={`text-[11px] px-2 py-0.5 rounded-full font-bold tabular-nums shrink-0 ml-0.5 ${
                                  isActive
                                    ? "bg-[#E5EEF6] text-[#1B5888]"
                                    : "bg-slate-100 text-[#666666]"
                                }`}
                              >
                                {pool.count}
                              </span>
                              {pool.id === "viewing_request" && leads.some((l) => l.lead_type === "viewing_request" && l.status === "new") && (
                                <span className="text-[10px] px-1.5 py-0.5 rounded-full font-bold bg-amber-500 text-white animate-pulse">
                                  {t("agency_panel_lead_new_viewing_badge")}
                                </span>
                              )}
                            </button>
                          );
                        })}
                      </div>
                    );
                  })()}

                  {/* New Viewing Lead Alert Banner when browsing another pool */}
                  {leadPoolFilter !== "all" && leadPoolFilter !== "viewing_request" && leads.some((l) => l.lead_type === "viewing_request" && l.status === "new") && (
                    <div className="bg-[#E5EEF6] border border-[#1B5888]/20 rounded-[10px] p-3 flex items-center justify-between gap-3 text-xs text-[#12406A] animate-fadeIn">
                      <div className="flex items-center gap-2 min-w-0">
                        <Calendar className="w-4 h-4 text-[#1B5888] shrink-0" />
                        <span className="font-semibold truncate">{t("agency_panel_lead_new_viewing_banner")}</span>
                      </div>
                      <button
                        type="button"
                        onClick={() => {
                          setLeadPoolFilter("viewing_request");
                          setLeadStatusFilter("all");
                        }}
                        className="px-3 py-1 bg-[#1B5888] text-white rounded-lg font-bold hover:bg-[#12406A] transition-colors shrink-0 cursor-pointer"
                      >
                        {t("agency_panel_lead_switch_to_viewings")}
                      </button>
                    </div>
                  )}

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
                        {/* Status Pills: Balanced Equal-Width Grid (No horizontal scroll, zero jagged teeth) */}
                        <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-2 pt-0.5">
                          {(() => {
                            const relevantStatuses: { id: string; label: string; desc: string; count: number }[] = [
                              {
                                id: "all",
                                label: t("agency_panel_filter_status_all"),
                                desc: t(STATUS_TOOLTIP_KEYS.all),
                                count:
                                  leadPoolFilter === "all"
                                    ? leads.length
                                    : leads.filter((l) => l.lead_type === leadPoolFilter).length,
                              },
                              {
                                id: "open",
                                label: t("agency_panel_filter_status_open"),
                                desc: t("agency_panel_filter_status_open_desc"),
                                count: leads.filter((l) => {
                                  if (leadPoolFilter !== "all" && l.lead_type !== leadPoolFilter) {
                                    return false;
                                  }
                                  return l.status !== "archived" && l.status !== "converted";
                                }).length,
                              },
                            ];

                            const statusList: LeadStatus[] =
                              leadPoolFilter === "all"
                                ? [
                                  "new",
                                  "contacted",
                                  "evaluation",
                                  "viewing_scheduled",
                                  "offer_made",
                                  "contract_signed",
                                  "converted",
                                  "archived",
                                ]
                                : getAllowedStatusesForType(leadPoolFilter);

                            for (const st of statusList) {
                              const count = leads.filter((l) => {
                                if (leadPoolFilter !== "all" && l.lead_type !== leadPoolFilter) {
                                  return false;
                                }
                                return l.status === st;
                              }).length;
                              relevantStatuses.push({
                                id: st,
                                label: t(STATUS_TRANSLATION_KEYS[st]),
                                desc: t(STATUS_TOOLTIP_KEYS[st]),
                                count,
                              });
                            }

                            return relevantStatuses.map((tab) => {
                              const isSelected = leadStatusFilter === tab.id;
                              return (
                                <button
                                  key={tab.id}
                                  type="button"
                                  onClick={() => setLeadStatusFilter(tab.id)}
                                  aria-label={`${tab.label}: ${tab.desc}`}
                                  className={`flex items-center justify-between gap-2 px-3 py-2 rounded-[10px] text-xs font-semibold transition-all cursor-pointer relative group hover:z-50 ${isSelected
                                    ? "bg-[#1B5888] text-white shadow-xs"
                                    : "bg-white hover:bg-slate-100 text-[#4A4A4A] border border-[#E5E3DF]"
                                    }`}
                                >
                                  <span className="truncate">{tab.label}</span>
                                  <span
                                    className={`text-[10px] px-1.5 py-0.5 rounded-full font-bold shrink-0 ${isSelected
                                      ? "bg-white/20 text-white"
                                      : "bg-slate-100 text-[#4A4A4A]"
                                      }`}
                                  >
                                    {tab.count}
                                  </span>

                                  {/* Fast Floating Tooltip on Hover */}
                                  <div className="absolute bottom-full left-1/2 -translate-x-1/2 mb-2 px-2.5 py-1.5 bg-slate-900 text-white text-[11px] font-normal leading-snug rounded-lg shadow-2xl whitespace-normal w-52 max-w-[85vw] text-center opacity-0 pointer-events-none group-hover:opacity-100 transition-opacity duration-100 delay-0 z-[9999]">
                                    <div className="font-bold text-white text-xs mb-0.5">{tab.label}</div>
                                    <div className="text-slate-300 text-[11px] leading-tight mb-1.5">{tab.desc}</div>
                                    <div className={`pt-1 border-t border-slate-700/80 text-[10px] font-semibold flex items-center justify-center gap-1 ${
                                      isSelected ? "text-emerald-400" : "text-amber-300"
                                    }`}>
                                      <span>{isSelected ? t("agency_panel_status_active_hint") : t("agency_panel_status_filter_hint")}</span>
                                    </div>
                                    <div className="absolute top-full left-1/2 -translate-x-1/2 -mt-1 border-4 border-transparent border-t-slate-900" />
                                  </div>
                                </button>
                              );
                            });
                          })()}
                        </div>

                        {/* Live Search Input */}
                        <div className="relative bg-white rounded-[8px] border border-[#E2E8F0] shadow-2xs">
                          <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2 pointer-events-none" />
                          <input
                            type="search"
                            value={leadSearchQuery}
                            onChange={(e) => setLeadSearchQuery(e.target.value)}
                            placeholder={t("agency_panel_lead_search_ph")}
                            className="w-full pl-9 pr-8 py-2 text-xs sm:text-sm bg-transparent rounded-[8px] text-[#0F172A] placeholder:text-slate-400 focus:outline-hidden focus:ring-2 focus:ring-[#1B5888]/20 focus:border-[#1B5888]"
                          />
                          {leadSearchQuery && (
                            <button
                              type="button"
                              onClick={() => setLeadSearchQuery("")}
                              className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600 cursor-pointer"
                              aria-label="Clear search"
                            >
                              <X className="w-3.5 h-3.5" />
                            </button>
                          )}
                        </div>

                        {/* Reset Filters Bar */}
                        {hasActiveFilters && (
                          <div className="pt-2 border-t border-slate-200/60 flex items-center justify-between">
                            <span className="text-slate-400 font-semibold text-xs">
                              {t("financeActiveFilterPrefix")}:
                            </span>
                            <button
                              type="button"
                              onClick={() => {
                                setLeadStatusFilter("all");
                                setLeadSearchQuery("");
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

                  {/* Empty State */}
                  {filteredLeads.length === 0 ? (
                    <div className="bg-white rounded-[10px] border border-[#E5E3DF] p-12 text-center shadow-xs">
                      <div className="w-14 h-14 rounded-[10px] bg-slate-50 border border-[#E5E3DF] text-[#666666] flex items-center justify-center mx-auto mb-3">
                        <Inbox className="w-7 h-7" />
                      </div>
                      <h3 className="text-base font-bold text-[#1A1A1A]">
                        {t("agency_panel_leads_empty_title")}
                      </h3>
                      <p className="text-xs text-[#666666] max-w-md mx-auto mt-1 leading-relaxed">
                        {t("agency_panel_leads_empty_desc")}
                      </p>
                    </div>
                  ) : (
                    /* ========================================================== */
                    /* LIST VIEW (DETAILED CARDS WITH COMMENT THREAD)              */
                    /* ========================================================== */
                    <div className="space-y-4">
                      {filteredLeads.map((lead) => {
                        const cleanPhoneDigits = (lead.client_phone || "")
                          .replace(/[^\d+]/g, "")
                          .replace(/^\+/, "");
                        const isOwnerConsignment = lead.lead_type === "owner_consignment";
                        const isViewing = lead.lead_type === "viewing_request";
                        const allowedStatuses = getAllowedStatusesForType(lead.lead_type);
                        const currentStatusColor = STATUS_STYLES[lead.status] || STATUS_STYLES.new;
                        const leadComments = lead.comments || [];

                        return (
                          <div
                            key={lead.id}
                            className="bg-white rounded-[10px] border border-[#E5E3DF] p-5 shadow-xs hover:border-[#8A8A8A] transition-all space-y-4"
                          >
                            {/* Card Header: Type Badge, Transaction, Date, Status Selector */}
                            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-3 border-b border-slate-100">
                              <div className="flex flex-wrap items-center gap-2">
                                {/* Type Badge */}
                                <span
                                  className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg text-xs font-bold ${isOwnerConsignment
                                    ? "bg-[#FBF1DC] text-[#8A5206] border border-[#8A5206]/20"
                                    : isViewing
                                      ? "bg-[#E5EEF6] text-blue-900 border border-[#1B5888]/20"
                                      : "bg-slate-100 text-[#1A1A1A] border border-[#E5E3DF]"
                                    }`}
                                >
                                  {isOwnerConsignment ? (
                                    <Building2 className="w-3.5 h-3.5 text-[#8A5206]" />
                                  ) : isViewing ? (
                                    <Calendar className="w-3.5 h-3.5 text-[#1B5888]" />
                                  ) : (
                                    <Inbox className="w-3.5 h-3.5 text-[#4A4A4A]" />
                                  )}
                                  <span>
                                    {isOwnerConsignment
                                      ? t("agency_panel_leads_type_owner")
                                      : isViewing
                                        ? t("agency_panel_leads_type_viewing")
                                        : t("agency_panel_leads_type_general")}
                                  </span>
                                </span>

                                {/* Transaction Type Tag */}
                                {lead.transaction_type && (
                                  <span className="px-2 py-0.5 rounded-md text-[11px] font-semibold bg-slate-100 text-[#4A4A4A] border border-[#E5E3DF] uppercase tracking-wide">
                                    {lead.transaction_type === "prodaja"
                                      ? t("agency_panel_tx_sale_short")
                                      : t("agency_panel_tx_rent_short")}
                                  </span>
                                )}

                                {/* Created Time */}
                                <span className="text-[11px] text-[#666666]">
                                  {new Date(lead.created_at).toLocaleDateString(activeLocale, {
                                    day: "numeric",
                                    month: "short",
                                    hour: "2-digit",
                                    minute: "2-digit",
                                  })}
                                </span>

                                {/* Demo lead indicator */}
                                {lead.id.startsWith("lead-0") && (
                                  <span className="px-1.5 py-0.2 rounded text-[10px] font-mono bg-slate-100 text-[#666666]">
                                    {t("agency_panel_leads_demo_tag")}
                                  </span>
                                )}
                              </div>

                              {/* Dynamic Status Selector Dropdown */}
                              <div className="flex items-center gap-2 shrink-0">
                                <label
                                  htmlFor={`lead-status-${lead.id}`}
                                  className="text-xs text-[#666666] font-medium"
                                >
                                  {t("agency_panel_leads_status_label")}:
                                </label>
                                <select
                                  id={`lead-status-${lead.id}`}
                                  value={lead.status}
                                  onChange={(e) =>
                                    handleUpdateLeadStatus(
                                      lead.id,
                                      e.target.value as AgencyLead["status"]
                                    )
                                  }
                                  className={`text-xs font-bold px-2.5 py-1.5 rounded-[10px] border cursor-pointer focus:outline-none focus:ring-2 focus:ring-blue-500 ${currentStatusColor.bg} ${currentStatusColor.text} ${currentStatusColor.border}`}
                                >
                                  {allowedStatuses.map((st) => (
                                    <option key={st} value={st}>
                                      ● {t(STATUS_TRANSLATION_KEYS[st])}
                                    </option>
                                  ))}
                                </select>
                              </div>
                            </div>

                            {/* Card Main Body: Client Info & Comments Thread */}
                            <div className="grid grid-cols-1 lg:grid-cols-12 gap-5 items-start">
                              {/* Left Col: Client & Property Details */}
                              <div className="lg:col-span-5 space-y-3">
                                <div>
                                  <h4 className="text-base font-bold text-[#1A1A1A]">
                                    {lead.client_name}
                                  </h4>
                                  <div className="flex flex-wrap items-center gap-x-3 gap-y-1 text-xs text-[#4A4A4A] mt-1">
                                    <a
                                      href={`tel:${lead.client_phone}`}
                                      className="inline-flex items-center gap-1 font-semibold text-[#12406A] hover:underline"
                                    >
                                      <Phone className="w-3.5 h-3.5" />
                                      <span>{lead.client_phone}</span>
                                    </a>
                                    {lead.client_email && (
                                      <a
                                        href={`mailto:${lead.client_email}`}
                                        className="inline-flex items-center gap-1 text-[#666666] hover:text-[#1A1A1A]"
                                      >
                                        <Mail className="w-3.5 h-3.5" />
                                        <span>{lead.client_email}</span>
                                      </a>
                                    )}
                                  </div>
                                </div>

                                {/* Property Specifications */}
                                {(lead.location || lead.area_sqm || lead.expected_price) && (
                                  <div className="pt-1 flex flex-wrap items-center gap-2 text-xs">
                                    {lead.location && (
                                      <span className="inline-flex items-center gap-1 text-[#4A4A4A] bg-slate-50 px-2.5 py-1 rounded-lg border border-[#E5E3DF]">
                                        <MapPin className="w-3.5 h-3.5 text-[#1B5888] shrink-0" />
                                        <span>{lead.location}</span>
                                      </span>
                                    )}
                                    {lead.area_sqm && (
                                      <span className="bg-slate-50 text-[#4A4A4A] px-2 py-1 rounded-lg border border-[#E5E3DF] font-medium">
                                        {lead.area_sqm} m²
                                      </span>
                                    )}
                                    {lead.expected_price && (
                                      <span className="bg-[#E6F3EA] text-[#2A6E43] px-2.5 py-1 rounded-lg border border-[#2A6E43]/20 font-bold">
                                        €{Number(lead.expected_price).toLocaleString()}
                                      </span>
                                    )}
                                  </div>
                                )}

                                {/* Attached / Converted Listing */}
                                {lead.listing_title && (
                                  <div className="p-2.5 rounded-[10px] bg-[#E5EEF6]/70 border border-[#1B5888]/20 text-xs">
                                    <span className="text-xs font-semibold text-blue-800 block mb-0.5">
                                      {t("agency_panel_linked_listing")}
                                    </span>
                                    <p className="font-semibold text-blue-950 line-clamp-1">
                                      {lead.listing_title}
                                    </p>
                                  </div>
                                )}

                                {/* Client's Message / Notes */}
                                {lead.notes && (
                                  <div className="p-3 rounded-[10px] bg-slate-50 border border-[#E5E3DF] text-xs">
                                    <span className="text-xs font-semibold text-[#666666] block mb-1">
                                      {t("agency_panel_leads_notes_label")}:
                                    </span>
                                    <p className="text-[#1A1A1A] leading-relaxed whitespace-pre-line">
                                      &ldquo;{lead.notes}&rdquo;
                                    </p>
                                  </div>
                                )}
                              </div>

                              {/* Right Col: Timeline & Comment History */}
                              <div className="lg:col-span-7 bg-slate-50/70 rounded-[10px] border border-[#E5E3DF] p-4 space-y-3">
                                <div className="flex items-center justify-between">
                                  <h5 className="text-xs font-bold text-[#1A1A1A] flex items-center gap-1.5">
                                    <Clock className="w-3.5 h-3.5 text-[#666666]" />
                                    <span>{t("agency_panel_comments_title")}</span>
                                  </h5>
                                  <span className="text-[10px] font-semibold text-[#666666] bg-white px-2 py-0.5 rounded-full border border-[#E5E3DF]">
                                    {leadComments.length}
                                  </span>
                                </div>

                                {/* Comments List */}
                                <div className="space-y-2 max-h-48 overflow-y-auto pr-1">
                                  {leadComments.length === 0 ? (
                                    <p className="text-xs text-[#666666] italic py-2">
                                      {t("agency_panel_comments_empty")}
                                    </p>
                                  ) : (
                                    leadComments.map((comment) => {
                                      const isViewingSys =
                                        comment.text.includes("İlan üzerinden yer görme randevu talebi") ||
                                        comment.text.includes("yer görme randevu talebi gönderildi") ||
                                        comment.text === "Zahtev za razgledanje poslat sa sajta" ||
                                        comment.text === "Захтев за разгледање послат са сајта" ||
                                        comment.text === "Viewing request submitted via website" ||
                                        comment.text === "Запрос на просмотр отправлен с сайта";

                                      const isOwnerSys =
                                        comment.text.includes("mülk sahibi başvurusu yapıldı") ||
                                        comment.text === "Prijava vlasnika nekretnine poslata sa sajta" ||
                                        comment.text === "Пријава власника некретнине послата са сајta" ||
                                        comment.text === "Property owner inquiry submitted via website" ||
                                        comment.text === "Заявка собственника отправлена с сайта";

                                      const isSys = isViewingSys || isOwnerSys;
                                      const displayText = isViewingSys
                                        ? t("agency_panel_lead_viewing_sys_comment")
                                        : isOwnerSys
                                          ? t("agency_panel_lead_owner_sys_comment")
                                          : comment.text;

                                      const displayAuthor = isSys
                                        ? t("agency_panel_lead_sys_author")
                                        : comment.author_name;

                                      return (
                                        <div
                                          key={comment.id}
                                          className={`p-2.5 rounded-[10px] text-xs space-y-1 shadow-2xs ${isSys
                                            ? "bg-slate-50 border border-[#E5E3DF]"
                                            : "bg-white border border-[#E5E3DF]"
                                            }`}
                                        >
                                          <div className="flex items-center justify-between text-[10px] text-[#666666]">
                                            {isSys ? (
                                              <span className="font-semibold text-[#12406A] bg-[#E5EEF6] border border-[#1B5888]/20 px-1.5 py-0.5 rounded text-[10px] flex items-center gap-1">
                                                <Globe className="w-2.5 h-2.5 text-[#1B5888]" />
                                                <span>{displayAuthor}</span>
                                              </span>
                                            ) : (
                                              <span className="font-bold text-[#4A4A4A] flex items-center gap-1">
                                                <User className="w-3 h-3 text-[#1B5888]" />
                                                <span>{displayAuthor}</span>
                                              </span>
                                            )}
                                            <span>
                                              {new Date(comment.created_at).toLocaleString(activeLocale, {
                                                day: "numeric",
                                                month: "short",
                                                hour: "2-digit",
                                                minute: "2-digit",
                                              })}
                                            </span>
                                          </div>
                                          <p
                                            className={`leading-relaxed ${isSys
                                              ? "text-[#4A4A4A] font-medium"
                                              : "text-[#1A1A1A] whitespace-pre-line"
                                              }`}
                                          >
                                            {displayText}
                                          </p>
                                        </div>
                                      );
                                    })
                                  )}
                                </div>

                                {/* Add Comment Input */}
                                < form
                                  onSubmit={(e) => {
                                    e.preventDefault();
                                    handleAddLeadComment(lead.id);
                                  }}
                                  className="flex items-center gap-2 pt-1"
                                >
                                  <input
                                    type="text"
                                    value={newCommentText[lead.id] || ""}
                                    onChange={(e) =>
                                      setNewCommentText((prev) => ({
                                        ...prev,
                                        [lead.id]: e.target.value,
                                      }))
                                    }
                                    placeholder={t("agency_panel_comments_placeholder")}
                                    className="flex-1 px-3 py-2 bg-white rounded-[10px] border border-[#8A8A8A] text-xs focus:ring-2 focus:ring-blue-500 focus:outline-none placeholder:text-[#666666]"
                                  />
                                  <button
                                    type="submit"
                                    disabled={!(newCommentText[lead.id] || "").trim()}
                                    className="px-3.5 py-2 rounded-[10px] bg-slate-900 hover:bg-slate-800 disabled:opacity-40 disabled:cursor-not-allowed text-white text-xs font-bold transition-colors cursor-pointer flex items-center gap-1 shrink-0"
                                  >
                                    <Send className="w-3.5 h-3.5" />
                                    <span>{t("agency_panel_comments_add_btn")}</span>
                                  </button>
                                </form>
                              </div>
                            </div>

                            {/* Card Footer Actions */}
                            <div className="pt-3 border-t border-slate-100 flex flex-wrap items-center justify-between gap-2.5">
                              <div className="flex flex-wrap items-center gap-2">
                                {/* WhatsApp Button */}
                                {cleanPhoneDigits && (
                                  <a
                                    href={`https://wa.me/${cleanPhoneDigits}?text=${encodeURIComponent(
                                      `Poštovani ${lead.client_name}, kontaktiramo Vas povodom Vašeg upita na Stanomer agencijskoj vitrini.`
                                    )}`}
                                    target="_blank"
                                    rel="noopener noreferrer"
                                    className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-[10px] bg-[#1B5888] hover:bg-[#12406A] active:bg-[#12406A] text-white text-xs font-bold shadow-xs transition-colors"
                                  >
                                    <MessageCircle className="w-3.5 h-3.5" />
                                    <span>{t("agency_panel_leads_act_whatsapp")}</span>
                                  </a>
                                )}

                                {/* Phone Call Button */}
                                <a
                                  href={`tel:${lead.client_phone}`}
                                  className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-[10px] bg-slate-100 hover:bg-slate-200 text-[#1A1A1A] text-xs font-bold transition-colors"
                                >
                                  <Phone className="w-3.5 h-3.5" />
                                  <span>{t("agency_panel_leads_act_call")}</span>
                                </a>
                              </div>

                              {/* Convert to Listing Action */}
                              {renderLeadTasksExpandButton(lead.id)}
                              {onCreateTask && (
                                <button
                                  type="button"
                                  onClick={() =>
                                    onCreateTask({
                                      source_type: "lead",
                                      lead_id: lead.id,
                                      title: `${lead.client_name}${lead.listing_title ? ` • ${lead.listing_title}` : ""}`,
                                      description: lead.notes || undefined,
                                    })
                                  }
                                  className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-[10px] border border-[#E5E3DF] bg-white hover:bg-slate-50 text-[#1A1A1A] text-xs font-bold transition-colors cursor-pointer"
                                >
                                  <span>{t("agency_tasks_quick_assign_btn")}</span>
                                </button>
                              )}

                              {isOwnerConsignment && (
                                <div>
                                  {lead.status === "converted" ? (
                                    <span className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-[10px] bg-[#E6F3EA] border border-[#2A6E43]/20 text-[#2A6E43] text-xs font-bold">
                                      <Check className="w-3.5 h-3.5 text-[#2A6E43]" />
                                      <span>{t("agency_panel_status_converted")}</span>
                                    </span>
                                  ) : (
                                    <button
                                      type="button"
                                      onClick={() => handleConvertLeadToListing(lead)}
                                      className="inline-flex items-center gap-1.5 px-3.5 py-1.5 rounded-[10px] bg-[#E5EEF6] border border-[#1B5888]/20 hover:bg-[#E5EEF6] text-[#12406A] text-xs font-bold transition-colors cursor-pointer"
                                    >
                                      <PlusCircle className="w-3.5 h-3.5" />
                                      <span>{t("agency_panel_leads_act_convert")}</span>
                                    </button>
                                  )}
                                </div>
                              )}
                            </div>
                            {renderExpandedLeadTasks(lead.id)}
                          </div>
                        );
                      })}
                    </div>
                  )}
                </div>
  );
}
