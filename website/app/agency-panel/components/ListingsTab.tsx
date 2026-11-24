"use client";

import React, { useState, useMemo } from "react";
import Link from "next/link";
import {
  AlertCircle,
  ArrowRight,
  Building2,
  Check,
  CheckCircle2,
  ChevronDown,
  ChevronUp,
  Edit3,
  Euro,
  ExternalLink,
  Eye,
  EyeOff,
  FileSignature,
  Home,
  KeyRound,
  Layers,
  Lock,
  MapPin,
  Plus,
  RefreshCw,
  RotateCcw,
  Rss,
  Search,
  SlidersHorizontal,
  Trash2,
  UserCheck,
  X,
} from "lucide-react";
import { AgencyListingRow, AgencyManagedProperty, AgencyPanelTab } from "../types";
import { PORTAL_LIST } from "../constants";
import { TRANSACTION_TYPES, PROPERTY_TYPES, getDictLabel } from "../../../lib/serbianRealEstateDict";
import { validate4ZidaListing, validateHaloOglasiListing } from "../../../lib/portalValidators";

export interface CloseAndHandoverParams {
  listing: AgencyListingRow;
  closingStatus: "rented" | "sold" | "reserved";
  closingPrice: number;
  closingNotes: string;
  handoverToPm: boolean;
  targetPropertyMode: "new" | "existing";
  existingPropertyId?: string;
  landlordName?: string;
  landlordPhone?: string;
  landlordEmail?: string;
  createContract: boolean;
  tenantName?: string;
  tenantPhone?: string;
  tenantEmail?: string;
  startDate?: string;
  endDate?: string;
  depositAmount?: number;
  dueDay?: number;
}

export interface ListingsTabProps {
  listings: AgencyListingRow[];
  loadingListings: boolean;
  userId: string | null;
  isDemoMode: boolean;
  showcaseUrl: string;
  fetchAgencyListings: (uid: string) => void;
  handleAddNewListingClick: () => void;
  loadListingIntoForm: (item: AgencyListingRow) => void;
  togglePublishStatus: (item: AgencyListingRow) => void;
  handleDeleteListing: (item: AgencyListingRow) => void;
  setActiveTab: (tab: AgencyPanelTab) => void;
  t: (key: string) => string;
  lang: "TR" | "EN" | "SR_LAT" | "SR_CYR" | "RU";
  activeModules?: string[];
  managedProperties?: AgencyManagedProperty[];
  onCloseAndHandoverListing?: (params: CloseAndHandoverParams) => Promise<void>;
  onInspectManagedProperty?: (propertyId: string) => void;
}

export default function ListingsTab({
  listings,
  loadingListings,
  userId,
  isDemoMode,
  showcaseUrl,
  fetchAgencyListings,
  handleAddNewListingClick,
  loadListingIntoForm,
  togglePublishStatus,
  handleDeleteListing,
  setActiveTab,
  t,
  lang,
  activeModules = ["portfolio_distribution", "property_lease_management"],
  managedProperties = [],
  onCloseAndHandoverListing,
  onInspectManagedProperty,
}: ListingsTabProps) {
  const [portfolioTxFilter, setPortfolioTxFilter] = useState<string>("all");
  const [portfolioStatusFilter, setPortfolioStatusFilter] = useState<string>("all");
  const [portfolioSearch, setPortfolioSearch] = useState<string>("");
  const [isFilterExpanded, setIsFilterExpanded] = useState<boolean>(true);

  // Lifecycle Bridge: Closing & Handover Modal State
  const [closingTarget, setClosingTarget] = useState<AgencyListingRow | null>(null);
  const [closingStatus, setClosingStatus] = useState<"rented" | "sold" | "reserved">("rented");
  const [closingPrice, setClosingPrice] = useState<string>("");
  const [closingNotes, setClosingNotes] = useState<string>("");
  const [handoverToPm, setHandoverToPm] = useState<boolean>(true);
  const [targetPropertyMode, setTargetPropertyMode] = useState<"new" | "existing">("new");
  const [selectedExistingPropId, setSelectedExistingPropId] = useState<string>("");
  const [landlordName, setLandlordName] = useState<string>("");
  const [landlordPhone, setLandlordPhone] = useState<string>("");
  const [landlordEmail, setLandlordEmail] = useState<string>("");
  const [createContractNow, setCreateContractNow] = useState<boolean>(true);
  const [tenantName, setTenantName] = useState<string>("");
  const [tenantPhone, setTenantPhone] = useState<string>("");
  const [tenantEmail, setTenantEmail] = useState<string>("");
  const [contractStartDate, setContractStartDate] = useState<string>("");
  const [contractEndDate, setContractEndDate] = useState<string>("");
  const [contractDeposit, setContractDeposit] = useState<string>("");
  const [contractDueDay, setContractDueDay] = useState<string>("1");
  const [isSubmittingClose, setIsSubmittingClose] = useState<boolean>(false);

  const hasPmModule =
    activeModules.includes("property_lease_management") ||
    activeModules.includes("property_lease");

  const openClosingModal = (item: AgencyListingRow) => {
    setClosingTarget(item);
    const defaultStat = item.transaction_type === "prodaja" ? "sold" : "rented";
    setClosingStatus(defaultStat);
    const basePrice = item.closing_price ?? item.price ?? 0;
    setClosingPrice(basePrice ? String(basePrice) : "");
    setClosingNotes(item.closing_notes || "");

    const matchedProp =
      managedProperties.find(
        (mp) =>
          mp.id === item.managed_property_id ||
          mp.last_listing_id === item.id ||
          (mp.title && item.title && mp.title.trim().toLowerCase() === item.title.trim().toLowerCase())
      ) || null;

    if (matchedProp) {
      setTargetPropertyMode("existing");
      setSelectedExistingPropId(matchedProp.id);
    } else {
      setTargetPropertyMode("new");
      setSelectedExistingPropId(managedProperties[0]?.id || "");
    }

    setHandoverToPm(hasPmModule && defaultStat === "rented");
    setCreateContractNow(true);
    setLandlordName("");
    setLandlordPhone("");
    setLandlordEmail("");
    setTenantName("");
    setTenantPhone("");
    setTenantEmail("");

    const today = new Date();
    const startIso = today.toISOString().split("T")[0];
    const nextYear = new Date(today);
    nextYear.setFullYear(nextYear.getFullYear() + 1);
    const endIso = nextYear.toISOString().split("T")[0];

    setContractStartDate(startIso);
    setContractEndDate(endIso);
    setContractDeposit(basePrice ? String(basePrice) : "");
    setContractDueDay("1");
  };

  const handleConfirmCloseAndHandover = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!closingTarget || !onCloseAndHandoverListing) return;
    setIsSubmittingClose(true);
    try {
      const priceNum = Number(closingPrice) || Number(closingTarget.price) || 0;
      const depNum = Number(contractDeposit) || priceNum;
      const dueNum = Math.min(28, Math.max(1, Number(contractDueDay) || 1));

      const effectiveTenantName =
        tenantName.trim() || (createContractNow ? t("roleTenant") : "");

      await onCloseAndHandoverListing({
        listing: closingTarget,
        closingStatus,
        closingPrice: priceNum,
        closingNotes: closingNotes.trim(),
        handoverToPm: hasPmModule && closingStatus === "rented" && handoverToPm,
        targetPropertyMode,
        existingPropertyId: targetPropertyMode === "existing" ? selectedExistingPropId : undefined,
        landlordName: landlordName.trim() || undefined,
        landlordPhone: landlordPhone.trim() || undefined,
        landlordEmail: landlordEmail.trim() || undefined,
        createContract:
          hasPmModule &&
          closingStatus === "rented" &&
          handoverToPm &&
          createContractNow,
        tenantName: effectiveTenantName || undefined,
        tenantPhone: tenantPhone.trim() || undefined,
        tenantEmail: tenantEmail.trim() || undefined,
        startDate: contractStartDate || undefined,
        endDate: contractEndDate || undefined,
        depositAmount: depNum,
        dueDay: dueNum,
      });
      setClosingTarget(null);
    } finally {
      setIsSubmittingClose(false);
    }
  };

  const hasActiveFilters =
    portfolioTxFilter !== "all" ||
    portfolioStatusFilter !== "all" ||
    portfolioSearch.trim().length > 0;

  const handleResetFilters = () => {
    setPortfolioTxFilter("all");
    setPortfolioStatusFilter("all");
    setPortfolioSearch("");
  };

  // Scoped listings (filtered by search & transaction type — feeds summary filter cards dynamically)
  const scopedListings = useMemo(() => {
    return listings.filter((item) => {
      if (portfolioTxFilter !== "all" && item.transaction_type !== portfolioTxFilter) {
        return false;
      }
      if (portfolioSearch.trim()) {
        const q = portfolioSearch.toLowerCase().trim();
        const text = `${item.title || ""} ${item.city || ""} ${item.municipality || ""} ${item.neighborhood || ""} ${item.address || ""} ${item.external_ref || ""}`.toLowerCase();
        if (!text.includes(q)) return false;
      }
      return true;
    });
  }, [listings, portfolioTxFilter, portfolioSearch]);

  const listingStats = useMemo(() => {
    return {
      total: scopedListings.length,
      live: scopedListings.filter((l) => l.is_published).length,
      paused: scopedListings.filter((l) => !l.is_published).length,
    };
  }, [scopedListings]);

  const filteredListings = useMemo(() => {
    return scopedListings.filter((item) => {
      if (portfolioStatusFilter === "live" && !item.is_published) {
        return false;
      }
      if (portfolioStatusFilter === "paused" && item.is_published) {
        return false;
      }
      if (portfolioStatusFilter === "rented" && item.listing_status !== "rented") {
        return false;
      }
      if (portfolioStatusFilter === "sold" && item.listing_status !== "sold") {
        return false;
      }
      return true;
    });
  }, [scopedListings, portfolioStatusFilter]);

  return (
<div
                  role="tabpanel"
                  id="tabpanel-listings"
                  aria-labelledby="tab-listings"
                  className="space-y-6"
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
                        <div className="flex flex-col md:flex-row items-stretch md:items-center justify-between gap-3">
                          <div className="flex flex-1 flex-col sm:flex-row items-stretch sm:items-center gap-3">
                            {/* Search Input */}
                            <div className="relative flex-1 bg-white rounded-[8px] border border-[#E2E8F0] shadow-2xs">
                              <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
                              <input
                                type="text"
                                value={portfolioSearch}
                                onChange={(e) => setPortfolioSearch(e.target.value)}
                                placeholder={t("agency_panel_search_placeholder")}
                                className="w-full pl-9 pr-8 py-2 text-xs sm:text-sm bg-transparent rounded-[8px] text-[#0F172A] placeholder:text-slate-400 focus:outline-hidden focus:ring-2 focus:ring-[#1B5888]/20 focus:border-[#1B5888]"
                              />
                              {portfolioSearch && (
                                <button
                                  type="button"
                                  onClick={() => setPortfolioSearch("")}
                                  className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600 cursor-pointer"
                                  aria-label="Clear search"
                                >
                                  <X className="w-3.5 h-3.5" />
                                </button>
                              )}
                            </div>

                            {/* Transaction Filter */}
                            <div className="w-full sm:w-44 bg-white rounded-[8px] border border-[#E2E8F0] shadow-2xs">
                              <select
                                value={portfolioTxFilter}
                                onChange={(e) => setPortfolioTxFilter(e.target.value)}
                                className="w-full px-3 py-2 text-xs sm:text-sm bg-transparent text-[#0F172A] font-medium cursor-pointer rounded-[8px] focus:outline-hidden focus:ring-2 focus:ring-[#1B5888]/20 focus:border-[#1B5888]"
                              >
                                <option value="all">{t("agency_panel_filter_all_tx")}</option>
                                {Object.values(TRANSACTION_TYPES).map((opt) => (
                                  <option key={opt.key} value={opt.key}>
                                    {getDictLabel(opt, lang)}
                                  </option>
                                ))}
                              </select>
                            </div>

                            {/* Status Filter */}
                            <div className="w-full sm:w-48 bg-white rounded-[8px] border border-[#E2E8F0] shadow-2xs">
                              <select
                                value={portfolioStatusFilter}
                                onChange={(e) => setPortfolioStatusFilter(e.target.value)}
                                className="w-full px-3 py-2 text-xs sm:text-sm bg-transparent text-[#0F172A] font-medium cursor-pointer rounded-[8px] focus:outline-hidden focus:ring-2 focus:ring-[#1B5888]/20 focus:border-[#1B5888]"
                              >
                                <option value="all">{t("agency_panel_filter_status_all")}</option>
                                <option value="live">{t("agency_panel_filter_status_live")}</option>
                                <option value="paused">{t("agency_panel_filter_status_paused")}</option>
                                <option value="rented">{t("agency_bridge_filter_rented")}</option>
                                <option value="sold">{t("agency_bridge_filter_sold")}</option>
                              </select>
                            </div>
                          </div>

                          {/* Action Buttons */}
                          <div className="flex items-center gap-2 self-end md:self-auto shrink-0">
                            {userId && userId !== "demo" && (
                              <button
                                type="button"
                                onClick={() => fetchAgencyListings(userId)}
                                className="p-2 rounded-[10px] border border-[#E2E8F0] bg-white hover:bg-slate-50 text-[#4A4A4A] cursor-pointer transition-colors shadow-2xs"
                                title={t("agency_panel_refresh")}
                              >
                                <RefreshCw className={`w-4 h-4 ${loadingListings ? "animate-spin" : ""}`} />
                              </button>
                            )}

                            <button
                              type="button"
                              onClick={handleAddNewListingClick}
                              className="inline-flex items-center gap-2 px-3.5 py-2 rounded-[10px] bg-[#1B5888] hover:bg-[#15466d] text-white text-xs sm:text-sm font-semibold shadow-2xs cursor-pointer transition-colors"
                            >
                              <Plus className="w-4 h-4" />
                              <span>{t("agency_panel_btn_new_listing")}</span>
                            </button>
                          </div>
                        </div>

                        {/* Reset Filters Bar */}
                        {hasActiveFilters && (
                          <div className="pt-2 border-t border-slate-200/60 flex items-center justify-between">
                            <span className="text-slate-400 font-semibold text-xs">
                              {t("financeActiveFilterPrefix")}:
                            </span>
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

                  {/* ── Middle Tier: Interactive Summary Filter Cards (Scoped by Search & Tx Filter) ── */}
                  <div className="grid grid-cols-2 lg:grid-cols-4 gap-3 sm:gap-4">
                    {/* Card 1: Total / All */}
                    <div
                      onClick={() => setPortfolioStatusFilter("all")}
                      className={`p-4 sm:p-5 rounded-[10px] border transition-all cursor-pointer ${
                        portfolioStatusFilter === "all"
                          ? "bg-[#E5EEF6]/60 border-[#1B5888] ring-2 ring-[#1B5888]/25 shadow-xs"
                          : "bg-white border-[#E5E3DF] hover:bg-[#F8F7F5] shadow-2xs"
                      }`}
                    >
                      <div className="flex items-center justify-between mb-2">
                        <span className="text-xs font-semibold text-[#666666]">
                          {t("agency_panel_stats_total")}
                        </span>
                        <div className="w-7 h-7 rounded-lg bg-[#E5EEF6] text-[#1B5888] flex items-center justify-center">
                          <Layers className="w-3.5 h-3.5" />
                        </div>
                      </div>
                      <p className="text-2xl font-bold text-[#1A1A1A] font-mono tabular-nums tracking-tight">
                        {listingStats.total}
                      </p>
                    </div>

                    {/* Card 2: Live / Published */}
                    <div
                      onClick={() => setPortfolioStatusFilter("live")}
                      className={`p-4 sm:p-5 rounded-[10px] border transition-all cursor-pointer ${
                        portfolioStatusFilter === "live"
                          ? "bg-[#E6F3EA]/80 border-[#2A6E43] ring-2 ring-[#2A6E43]/25 shadow-xs"
                          : "bg-white border-[#E5E3DF] hover:bg-[#F8F7F5] shadow-2xs"
                      }`}
                    >
                      <div className="flex items-center justify-between mb-2">
                        <span className="text-xs font-semibold text-[#666666]">
                          {t("agency_panel_stats_live")}
                        </span>
                        <div className="w-7 h-7 rounded-lg bg-[#E6F3EA] text-[#2A6E43] flex items-center justify-center">
                          <Eye className="w-3.5 h-3.5" />
                        </div>
                      </div>
                      <p className="text-2xl font-bold text-[#2A6E43] font-mono tabular-nums tracking-tight">
                        {listingStats.live}
                      </p>
                    </div>

                    {/* Card 3: Paused / Unpublished */}
                    <div
                      onClick={() => setPortfolioStatusFilter("paused")}
                      className={`p-4 sm:p-5 rounded-[10px] border transition-all cursor-pointer ${
                        portfolioStatusFilter === "paused"
                          ? "bg-[#FBF1DC]/80 border-[#8A5206] ring-2 ring-[#8A5206]/25 shadow-xs"
                          : "bg-white border-[#E5E3DF] hover:bg-[#F8F7F5] shadow-2xs"
                      }`}
                    >
                      <div className="flex items-center justify-between mb-2">
                        <span className="text-xs font-semibold text-[#666666]">
                          {t("agency_panel_stats_paused")}
                        </span>
                        <div className="w-7 h-7 rounded-lg bg-[#F8F7F5] text-[#4A4A4A] flex items-center justify-center border border-[#E5E3DF]">
                          <EyeOff className="w-3.5 h-3.5" />
                        </div>
                      </div>
                      <p className="text-2xl font-bold text-[#4A4A4A] font-mono tabular-nums tracking-tight">
                        {listingStats.paused}
                      </p>
                    </div>

                    {/* Card 4: XML Feeds Quick Link */}
                    <div
                      onClick={() => setActiveTab("xml")}
                      className="bg-white p-4 sm:p-5 rounded-[10px] border border-[#E5E3DF] shadow-2xs hover:border-[#1B5888]/40 hover:bg-[#F8F7F5] transition-all cursor-pointer flex flex-col justify-between group"
                    >
                      <div className="flex items-center justify-between mb-2">
                        <span className="text-xs font-semibold text-[#666666]">
                          {t("agency_panel_menu_xml")}
                        </span>
                        <div className="w-7 h-7 rounded-lg bg-[#E5EEF6] text-[#1B5888] flex items-center justify-center group-hover:bg-[#1B5888] group-hover:text-white transition-colors">
                          <Rss className="w-3.5 h-3.5" />
                        </div>
                      </div>
                      <div className="flex items-center justify-between">
                        <p className="text-base font-bold text-[#1A1A1A] tracking-tight">
                          {PORTAL_LIST.filter((p) => p.status === "live").length} {t("agency_panel_stats_portals_active")}
                        </p>
                        <ArrowRight className="w-4 h-4 text-[#666666] group-hover:text-[#1B5888] transition-colors" />
                      </div>
                    </div>
                  </div>

                  {/* Listings Grid */}
                  {listings.length === 0 ? (
                    <div className="bg-white rounded-[10px] border border-[#E5E3DF] p-12 text-center shadow-xs">
                      <Building2 className="w-12 h-12 text-slate-300 mx-auto mb-3" />
                      <h3 className="text-base font-bold text-[#1A1A1A]">
                        {t("agency_panel_empty_title")}
                      </h3>
                      <p className="text-xs text-[#666666] mt-1 max-w-md mx-auto">
                        {t("agency_panel_empty_desc")}
                      </p>
                      <button
                        type="button"
                        onClick={handleAddNewListingClick}
                        className="mt-5 inline-flex items-center gap-2 px-4 py-2.5 rounded-[10px] bg-[#1B5888] hover:bg-[#12406A] active:bg-[#12406A] text-white text-xs font-semibold shadow-xs cursor-pointer"
                      >
                        <Plus className="w-4 h-4" />
                        <span>{t("agency_panel_btn_new_listing")}</span>
                      </button>
                    </div>
                  ) : filteredListings.length === 0 ? (
                    <div className="bg-white rounded-[10px] border border-[#E5E3DF] p-12 text-center shadow-xs">
                      <Search className="w-10 h-10 text-slate-300 mx-auto mb-3" />
                      <h3 className="text-base font-bold text-[#1A1A1A]">
                        {t("agency_panel_search_no_results_title")}
                      </h3>
                      <p className="text-xs text-[#666666] mt-1">
                        {t("agency_panel_search_no_results_desc")}
                      </p>
                      <button
                        type="button"
                        onClick={() => {
                          setPortfolioSearch("");
                          setPortfolioTxFilter("all");
                          setPortfolioStatusFilter("all");
                        }}
                        className="mt-4 px-3.5 py-2 rounded-[10px] bg-slate-100 hover:bg-slate-200 text-xs font-semibold text-[#4A4A4A] cursor-pointer"
                      >
                        {t("agency_panel_clear_filters_btn")}
                      </button>
                    </div>
                  ) : (
                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
                      {filteredListings.map((item) => {
                        const coverUrl =
                          item.listing_images?.find((i) => i.is_cover)?.url ||
                          item.listing_images?.[0]?.url;
                        const displayPrice = item.price ?? 0;
                        const txItem =
                          (item.transaction_type && TRANSACTION_TYPES[item.transaction_type]) ||
                          TRANSACTION_TYPES.izdavanje;
                        const txLabel = getDictLabel(txItem, lang);
                        const propItem =
                          (item.property_type && PROPERTY_TYPES[item.property_type]) ||
                          PROPERTY_TYPES.apartment;
                        const propTypeLabel = getDictLabel(propItem, lang);

                        return (
                          <div
                            key={item.id}
                            className="bg-white rounded-[10px] border border-[#E5E3DF] overflow-hidden shadow-2xs hover:border-[#8A8A8A] hover:shadow-xs transition-all flex flex-col"
                          >
                            {/* Image Container with Badges */}
                            <div className="relative h-48 bg-slate-100 overflow-hidden">
                              {coverUrl ? (
                                <img
                                  src={coverUrl}
                                  alt={item.title || "Property"}
                                  className="w-full h-full object-cover"
                                />
                              ) : (
                                <div className="w-full h-full flex flex-col items-center justify-center text-[#666666]">
                                  <Building2 className="w-10 h-10 mb-1" />
                                  <span className="text-xs">{t("agency_panel_no_photo")}</span>
                                </div>
                              )}

                              {/* Badges on Image */}
                              <div className="absolute top-3 left-3 flex flex-wrap gap-1.5">
                                <span className="text-[11px] font-bold px-2.5 py-1 rounded-md bg-white/95 text-[#1A1A1A] shadow-xs backdrop-blur-xs">
                                  {txLabel}
                                </span>
                                <span className="text-[11px] font-medium px-2 py-1 rounded-md bg-slate-900/80 text-white shadow-xs backdrop-blur-xs">
                                  {propTypeLabel}
                                </span>
                              </div>

                              <div className="absolute top-3 right-3 flex items-center gap-1.5 flex-wrap justify-end">
                                {item.listing_status === "rented" && (
                                  <span className="text-[11px] font-bold px-2.5 py-1 rounded-md shadow-xs backdrop-blur-xs bg-indigo-600 text-white">
                                    {t("agency_bridge_status_rented")}
                                  </span>
                                )}
                                {item.listing_status === "sold" && (
                                  <span className="text-[11px] font-bold px-2.5 py-1 rounded-md shadow-xs backdrop-blur-xs bg-amber-600 text-white">
                                    {t("agency_bridge_status_sold")}
                                  </span>
                                )}
                                {item.listing_status === "reserved" && (
                                  <span className="text-[11px] font-bold px-2.5 py-1 rounded-md shadow-xs backdrop-blur-xs bg-purple-600 text-white">
                                    {t("agency_bridge_status_reserved")}
                                  </span>
                                )}
                                <span
                                  className={`text-[11px] font-bold px-2.5 py-1 rounded-md shadow-xs backdrop-blur-xs ${item.is_published
                                    ? "bg-emerald-500 text-white"
                                    : "bg-slate-700/90 text-white"
                                    }`}
                                >
                                  {item.is_published
                                    ? t("agency_panel_status_live")
                                    : t("agency_panel_status_paused")}
                                </span>
                              </div>

                              {item.external_ref && (
                                <div className="absolute bottom-2.5 left-3">
                                  <span className="text-[10px] font-mono font-semibold bg-black/60 text-white px-2 py-0.5 rounded backdrop-blur-xs">
                                    #{item.external_ref}
                                  </span>
                                </div>
                              )}

                              {(() => {
                                const linkedProp = managedProperties.find(
                                  (mp) => mp.id === item.managed_property_id || mp.last_listing_id === item.id
                                );
                                const linkedPropId = item.managed_property_id || linkedProp?.id;
                                if (!linkedPropId) return null;
                                return (
                                  <div className="absolute bottom-2.5 right-3">
                                    <button
                                      type="button"
                                      onClick={() => {
                                        if (onInspectManagedProperty) {
                                          onInspectManagedProperty(linkedPropId);
                                        } else {
                                          setActiveTab("managed_properties");
                                        }
                                      }}
                                      className="text-[10px] font-bold bg-[#1B5888]/95 hover:bg-[#12406A] text-white px-2 py-1 rounded-md shadow-xs backdrop-blur-xs inline-flex items-center gap-1 cursor-pointer transition-colors"
                                      title={t("agency_bridge_view_in_pm")}
                                    >
                                      <Home className="w-3 h-3" />
                                      <span>{t("agency_bridge_linked_prop_badge")}</span>
                                    </button>
                                  </div>
                                );
                              })()}
                            </div>

                            {/* Card Content */}
                            <div className="p-4 sm:p-5 flex-1 flex flex-col justify-between">
                              <div>
                                <div className="flex items-baseline justify-between gap-2 mb-2">
                                  <span className="text-lg font-bold text-[#12406A] flex items-center">
                                    <Euro className="w-4 h-4 mr-0.5" />
                                    {displayPrice.toLocaleString()} {item.currency || "EUR"}
                                  </span>
                                  {item.area_sqm && item.area_sqm > 0 && (
                                    <span className="text-xs text-[#666666] font-medium">
                                      ~{Math.round(displayPrice / item.area_sqm).toLocaleString()} €/m²
                                    </span>
                                  )}
                                </div>

                                <h4 className="font-bold text-[#1A1A1A] text-sm line-clamp-1 mb-1" title={item.title || ""}>
                                  {item.title || t("agency_panel_untitled_listing")}
                                </h4>

                                <p className="text-xs text-[#666666] flex items-center gap-1 line-clamp-1 mb-3">
                                  <MapPin className="w-3.5 h-3.5 text-[#666666] shrink-0" />
                                  <span>
                                    {[item.city, item.municipality, item.neighborhood]
                                      .filter(Boolean)
                                      .join(" • ") || t("agency_panel_no_location")}
                                  </span>
                                </p>

                                {/* Specs row */}
                                <div className="flex items-center gap-2 text-xs text-[#4A4A4A] bg-slate-50 p-2.5 rounded-[10px] border border-slate-100 mb-3">
                                  {item.area_sqm ? (
                                    <span className="font-semibold">{item.area_sqm} m²</span>
                                  ) : null}
                                  {item.room_count ? (
                                    <>
                                      <span>•</span>
                                      <span>{item.room_count} {t("agency_panel_unit_rooms")}</span>
                                    </>
                                  ) : null}
                                  {item.floor ? (
                                    <>
                                      <span>•</span>
                                      <span>{item.floor}. {t("agency_panel_unit_floor")}</span>
                                    </>
                                  ) : null}
                                </div>

                                {/* Portal Syndication indicators with 4zida pre-flight badge */}
                                <div className="flex items-center gap-1.5 text-[10px] text-[#666666] mb-4 flex-wrap">
                                  <span className="font-medium mr-0.5">{t("agency_panel_portals_label")}</span>
                                  {PORTAL_LIST.filter((p) => p.status === "live").map((p) => {
                                    const val =
                                      p.id === "4zida"
                                        ? validate4ZidaListing(item)
                                        : p.id === "halooglasi"
                                          ? validateHaloOglasiListing(item)
                                          : null;
                                    const isReady = val ? val.isReady : true;
                                    return (
                                      <span
                                        key={p.id}
                                        title={
                                          val
                                            ? isReady
                                              ? `${p.name}: ${t("agency_panel_validator_ready_desc")}`
                                              : `${p.name}: ` +
                                              val.errors
                                                .map((e) => t(e.key) || e.defaultText)
                                                .join(", ")
                                            : undefined
                                        }
                                        className={`px-1.5 py-0.5 rounded font-mono inline-flex items-center gap-1 ${item.is_published
                                          ? val && !isReady
                                            ? "bg-[#FBF1DC] text-[#8A5206] border border-[#8A5206]/20"
                                            : "bg-[#F8F7F5] text-[#666666] border border-[#E5E3DF]"
                                          : "bg-slate-50 text-[#666666]"
                                          }`}
                                      >
                                        <span>{p.name.split(".")[0]}</span>
                                        {val && (
                                          isReady ? (
                                            <Check className="w-2.5 h-2.5 text-[#2A6E43] stroke-[3]" />
                                          ) : (
                                            <AlertCircle className="w-2.5 h-2.5 text-[#8A5206]" />
                                          )
                                        )}
                                      </span>
                                    );
                                  })}
                                </div>
                              </div>

                              {/* Action Buttons */}
                              <div className="pt-3 border-t border-slate-100 flex items-center justify-between gap-2 flex-wrap">
                                <div className="flex items-center gap-1.5 flex-wrap">
                                  <button
                                    type="button"
                                    onClick={() => loadListingIntoForm(item)}
                                    className="inline-flex items-center gap-1 px-2.5 py-1.5 rounded-lg bg-[#E5EEF6] hover:bg-[#d6e5f3] text-xs font-semibold text-[#12406A] cursor-pointer transition-colors"
                                  >
                                    <Edit3 className="w-3.5 h-3.5" />
                                    <span>{t("agency_panel_edit_btn")}</span>
                                  </button>

                                  <button
                                    type="button"
                                    onClick={() => togglePublishStatus(item)}
                                    className={`inline-flex items-center gap-1 px-2.5 py-1.5 rounded-lg text-xs font-semibold cursor-pointer transition-colors ${item.is_published
                                      ? "bg-[#FBF1DC] text-[#8A5206] hover:bg-[#f5e5c4]"
                                      : "bg-[#E6F3EA] text-[#2A6E43] hover:bg-[#d6ebd9]"
                                      }`}
                                    title={
                                      item.is_published
                                        ? t("agency_panel_pause_btn")
                                        : t("agency_panel_publish_btn")
                                    }
                                  >
                                    {item.is_published ? (
                                      <>
                                        <EyeOff className="w-3.5 h-3.5" />
                                        <span className="hidden sm:inline">{t("agency_panel_pause_btn")}</span>
                                      </>
                                    ) : (
                                      <>
                                        <Eye className="w-3.5 h-3.5" />
                                        <span className="hidden sm:inline">{t("agency_panel_publish_btn")}</span>
                                      </>
                                    )}
                                  </button>

                                  {onCloseAndHandoverListing && (
                                    <button
                                      type="button"
                                      onClick={() => openClosingModal(item)}
                                      className={`inline-flex items-center gap-1 px-2.5 py-1.5 rounded-lg text-xs font-semibold cursor-pointer transition-colors ${
                                        item.listing_status === "rented" || item.listing_status === "sold"
                                          ? "bg-indigo-600 text-white hover:bg-indigo-700"
                                          : "bg-indigo-50 hover:bg-indigo-100 text-indigo-700 border border-indigo-200/80"
                                      }`}
                                      title={
                                        item.transaction_type === "prodaja"
                                          ? t("agency_bridge_btn_close_sale")
                                          : t("agency_bridge_btn_close_listing")
                                      }
                                    >
                                      <KeyRound className="w-3.5 h-3.5" />
                                      <span>
                                        {item.listing_status === "rented"
                                          ? t("agency_bridge_status_rented")
                                          : item.listing_status === "sold"
                                            ? t("agency_bridge_status_sold")
                                            : item.transaction_type === "prodaja"
                                              ? t("agency_bridge_btn_close_sale")
                                              : t("agency_bridge_btn_close_listing")}
                                      </span>
                                    </button>
                                  )}

                                  {(() => {
                                    const linkedProp = managedProperties.find(
                                      (mp) => mp.id === item.managed_property_id || mp.last_listing_id === item.id
                                    );
                                    const linkedPropId = item.managed_property_id || linkedProp?.id;
                                    if (!linkedPropId) return null;
                                    return (
                                      <button
                                        type="button"
                                        onClick={() => {
                                          if (onInspectManagedProperty) {
                                            onInspectManagedProperty(linkedPropId);
                                          } else {
                                            setActiveTab("managed_properties");
                                          }
                                        }}
                                        className="inline-flex items-center gap-1 px-2.5 py-1.5 rounded-lg bg-[#E6F3EA] hover:bg-[#d6ebd9] text-[#2A6E43] text-xs font-bold cursor-pointer transition-colors"
                                      >
                                        <Home className="w-3.5 h-3.5" />
                                        <span>{t("agency_bridge_view_in_pm")}</span>
                                      </button>
                                    );
                                  })()}
                                </div>

                                <div className="flex items-center gap-1.5">
                                  <Link
                                    href={`${showcaseUrl}#listing-${item.id}`}
                                    target="_blank"
                                    className="p-1.5 rounded-lg text-[#666666] hover:text-[#12406A] hover:bg-[#E5EEF6] transition-colors"
                                    title={t("agency_panel_view_showcase")}
                                  >
                                    <ExternalLink className="w-4 h-4" />
                                  </Link>

                                  <button
                                    type="button"
                                    onClick={() => handleDeleteListing(item)}
                                    className="p-1.5 rounded-lg text-[#666666] hover:text-[#A33C29] hover:bg-[#FBEAE6] transition-colors cursor-pointer"
                                    title={t("agency_panel_delete_btn")}
                                  >
                                    <Trash2 className="w-4 h-4" />
                                  </button>
                                </div>
                              </div>
                            </div>
                          </div>
                        );
                      })}
                    </div>
                  )}

                  {/* ── LIFECYCLE BRIDGE MODAL: Close Listing & Handover to Property Management ── */}
                  {closingTarget && (
                    <div
                      className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/50 backdrop-blur-xs animate-in fade-in duration-200"
                      onClick={() => {
                        if (!isSubmittingClose) setClosingTarget(null);
                      }}
                    >
                      <div
                        className="bg-white rounded-2xl border border-slate-200 shadow-2xl max-w-xl w-full max-h-[90vh] overflow-y-auto p-6 space-y-5 animate-in zoom-in-95 duration-150"
                        onClick={(e) => e.stopPropagation()}
                      >
                        {/* Modal Header */}
                        <div className="flex items-start justify-between gap-3 border-b border-slate-100 pb-4">
                          <div className="flex items-center gap-3">
                            <div className="w-10 h-10 rounded-xl bg-indigo-50 text-indigo-600 flex items-center justify-center shrink-0">
                              <KeyRound className="w-5 h-5" />
                            </div>
                            <div>
                              <h3 className="text-base font-bold text-slate-900">
                                {t("agency_bridge_modal_title")}
                              </h3>
                              <p className="text-xs text-slate-500 mt-0.5">
                                {t("agency_bridge_modal_sub")}
                              </p>
                            </div>
                          </div>
                          <button
                            type="button"
                            disabled={isSubmittingClose}
                            onClick={() => setClosingTarget(null)}
                            className="p-1.5 rounded-lg text-slate-400 hover:text-slate-700 hover:bg-slate-100 transition-colors cursor-pointer"
                          >
                            <X className="w-4 h-4" />
                          </button>
                        </div>

                        <form onSubmit={handleConfirmCloseAndHandover} className="space-y-4">
                          {/* Listing Summary Strip */}
                          <div className="p-3.5 rounded-xl bg-slate-50 border border-slate-200/80 flex items-center justify-between gap-3">
                            <div className="min-w-0">
                              <p className="text-xs font-bold text-slate-900 truncate">
                                {closingTarget.title || t("agency_panel_untitled_listing")}
                              </p>
                              <p className="text-[11px] text-slate-500 truncate mt-0.5">
                                {[closingTarget.city, closingTarget.municipality, closingTarget.address]
                                  .filter(Boolean)
                                  .join(" • ")}
                              </p>
                            </div>
                            <span className="text-xs font-bold text-[#12406A] bg-[#E5EEF6] px-2.5 py-1 rounded-lg shrink-0">
                              €{(closingTarget.price ?? 0).toLocaleString()}
                            </span>
                          </div>

                          {/* Closing Status & Final Price */}
                          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                            <div>
                              <label className="text-xs font-bold text-slate-700 block mb-1">
                                {t("agency_bridge_closing_type_label")}
                              </label>
                              <select
                                value={closingStatus}
                                onChange={(e) => {
                                  const nextStat = e.target.value as "rented" | "sold" | "reserved";
                                  setClosingStatus(nextStat);
                                  if (nextStat !== "rented") {
                                    setHandoverToPm(false);
                                  } else if (hasPmModule) {
                                    setHandoverToPm(true);
                                  }
                                }}
                                className="w-full text-xs font-semibold rounded-xl border border-slate-200 px-3 py-2.5 text-slate-900 bg-white focus:outline-hidden focus:border-[#1B5888]"
                              >
                                <option value="rented">{t("agency_bridge_status_rented")}</option>
                                <option value="sold">{t("agency_bridge_status_sold")}</option>
                                <option value="reserved">{t("agency_bridge_status_reserved")}</option>
                              </select>
                            </div>

                            <div>
                              <label className="text-xs font-bold text-slate-700 block mb-1">
                                {t("agency_bridge_closing_price_label")} ({closingTarget.currency || "EUR"})
                              </label>
                              <input
                                type="number"
                                step="1"
                                value={closingPrice}
                                onChange={(e) => {
                                  setClosingPrice(e.target.value);
                                  if (!contractDeposit || contractDeposit === closingPrice) {
                                    setContractDeposit(e.target.value);
                                  }
                                }}
                                className="w-full text-xs font-semibold rounded-xl border border-slate-200 px-3 py-2.5 text-slate-900 focus:outline-hidden focus:border-[#1B5888]"
                              />
                            </div>
                          </div>

                          <div>
                            <label className="text-xs font-bold text-slate-700 block mb-1">
                              {t("agency_bridge_closing_notes_label")}
                            </label>
                            <input
                              type="text"
                              value={closingNotes}
                              onChange={(e) => setClosingNotes(e.target.value)}
                              placeholder={t("agency_bridge_closing_notes_placeholder")}
                              className="w-full text-xs rounded-xl border border-slate-200 px-3 py-2 text-slate-900 focus:outline-hidden focus:border-[#1B5888]"
                            />
                          </div>

                          {/* Property & Lease Management Handover Section (when closingStatus === "rented") */}
                          {closingStatus === "rented" && (
                            hasPmModule ? (
                              <div className="rounded-xl border border-indigo-200 bg-indigo-50/40 p-4 space-y-4">
                                <label className="flex items-start gap-3 cursor-pointer select-none">
                                  <input
                                    type="checkbox"
                                    checked={handoverToPm}
                                    onChange={(e) => setHandoverToPm(e.target.checked)}
                                    className="mt-0.5 w-4 h-4 rounded border-indigo-300 text-indigo-600 focus:ring-indigo-500 cursor-pointer"
                                  />
                                  <div>
                                    <span className="text-xs font-bold text-slate-900 flex items-center gap-1.5">
                                      <Home className="w-3.5 h-3.5 text-indigo-600" />
                                      <span>{t("agency_bridge_handover_toggle")}</span>
                                    </span>
                                    <p className="text-[11px] text-slate-600 mt-0.5">
                                      {t("agency_bridge_handover_toggle_desc")}
                                    </p>
                                  </div>
                                </label>

                                {handoverToPm && (
                                  <div className="space-y-4 pt-2 border-t border-indigo-200/60">
                                    {/* Target Property Mode Selector */}
                                    <div className="grid grid-cols-2 gap-2">
                                      <button
                                        type="button"
                                        onClick={() => setTargetPropertyMode("new")}
                                        className={`px-3 py-2 rounded-xl text-xs font-bold border transition-all cursor-pointer flex items-center justify-center gap-1.5 ${
                                          targetPropertyMode === "new"
                                            ? "bg-[#1B5888] text-white border-[#1B5888] shadow-2xs"
                                            : "bg-white text-slate-700 border-slate-200 hover:bg-slate-50"
                                        }`}
                                      >
                                        <Plus className="w-3.5 h-3.5" />
                                        <span>{t("agency_bridge_mode_new_prop")}</span>
                                      </button>
                                      <button
                                        type="button"
                                        disabled={managedProperties.length === 0}
                                        onClick={() => setTargetPropertyMode("existing")}
                                        className={`px-3 py-2 rounded-xl text-xs font-bold border transition-all cursor-pointer flex items-center justify-center gap-1.5 disabled:opacity-40 ${
                                          targetPropertyMode === "existing"
                                            ? "bg-[#1B5888] text-white border-[#1B5888] shadow-2xs"
                                            : "bg-white text-slate-700 border-slate-200 hover:bg-slate-50"
                                        }`}
                                      >
                                        <Building2 className="w-3.5 h-3.5" />
                                        <span>{t("agency_bridge_mode_existing_prop")}</span>
                                      </button>
                                    </div>

                                    {targetPropertyMode === "existing" && managedProperties.length > 0 ? (
                                      <div>
                                        <label className="text-xs font-bold text-slate-700 block mb-1">
                                          {t("agency_bridge_select_prop_label")}
                                        </label>
                                        <select
                                          value={selectedExistingPropId}
                                          onChange={(e) => setSelectedExistingPropId(e.target.value)}
                                          className="w-full text-xs font-semibold rounded-xl border border-slate-200 px-3 py-2.5 text-slate-900 bg-white focus:outline-hidden focus:border-[#1B5888]"
                                        >
                                          {managedProperties.map((mp) => (
                                            <option key={mp.id} value={mp.id}>
                                              {mp.title} {mp.address ? `(${mp.address})` : ""}
                                            </option>
                                          ))}
                                        </select>
                                      </div>
                                    ) : (
                                      <div className="bg-white rounded-xl border border-slate-200/80 p-3.5 space-y-3">
                                        <p className="text-xs font-bold text-slate-800">
                                          {t("agency_bridge_landlord_section_title")}
                                        </p>
                                        <div className="grid grid-cols-1 sm:grid-cols-3 gap-2.5">
                                          <div>
                                            <label className="text-[11px] font-semibold text-slate-600 block mb-1">
                                              {t("agency_bridge_landlord_name_label")}
                                            </label>
                                            <input
                                              type="text"
                                              value={landlordName}
                                              onChange={(e) => setLandlordName(e.target.value)}
                                              className="w-full text-xs rounded-lg border border-slate-200 px-2.5 py-1.5 text-slate-900 focus:outline-hidden focus:border-[#1B5888]"
                                            />
                                          </div>
                                          <div>
                                            <label className="text-[11px] font-semibold text-slate-600 block mb-1">
                                              {t("agency_bridge_landlord_phone_label")}
                                            </label>
                                            <input
                                              type="text"
                                              value={landlordPhone}
                                              onChange={(e) => setLandlordPhone(e.target.value)}
                                              className="w-full text-xs rounded-lg border border-slate-200 px-2.5 py-1.5 text-slate-900 focus:outline-hidden focus:border-[#1B5888]"
                                            />
                                          </div>
                                          <div>
                                            <label className="text-[11px] font-semibold text-slate-600 block mb-1">
                                              {t("agency_bridge_landlord_email_label")}
                                            </label>
                                            <input
                                              type="email"
                                              value={landlordEmail}
                                              onChange={(e) => setLandlordEmail(e.target.value)}
                                              className="w-full text-xs rounded-lg border border-slate-200 px-2.5 py-1.5 text-slate-900 focus:outline-hidden focus:border-[#1B5888]"
                                            />
                                          </div>
                                        </div>
                                      </div>
                                    )}

                                    {/* New Contract & Tenant Definition */}
                                    <div className="bg-white rounded-xl border border-slate-200/80 p-3.5 space-y-3">
                                      <label className="flex items-center gap-2.5 cursor-pointer select-none">
                                        <input
                                          type="checkbox"
                                          checked={createContractNow}
                                          onChange={(e) => setCreateContractNow(e.target.checked)}
                                          className="w-4 h-4 rounded border-slate-300 text-[#1B5888] focus:ring-[#1B5888] cursor-pointer"
                                        />
                                        <span className="text-xs font-bold text-slate-900 flex items-center gap-1.5">
                                          <FileSignature className="w-3.5 h-3.5 text-[#1B5888]" />
                                          <span>{t("agency_bridge_create_contract_toggle")}</span>
                                        </span>
                                      </label>

                                      {createContractNow && (
                                        <div className="space-y-3 pt-2 border-t border-slate-100">
                                          <div className="grid grid-cols-1 sm:grid-cols-3 gap-2.5">
                                            <div>
                                              <label className="text-[11px] font-semibold text-slate-600 block mb-1">
                                                {t("agency_bridge_tenant_name_label")}
                                              </label>
                                              <input
                                                type="text"
                                                value={tenantName}
                                                onChange={(e) => setTenantName(e.target.value)}
                                                placeholder={t("roleTenant")}
                                                className="w-full text-xs rounded-lg border border-slate-200 px-2.5 py-1.5 text-slate-900 focus:outline-hidden focus:border-[#1B5888]"
                                              />
                                            </div>
                                            <div>
                                              <label className="text-[11px] font-semibold text-slate-600 block mb-1">
                                                {t("agency_bridge_tenant_phone_label")}
                                              </label>
                                              <input
                                                type="text"
                                                value={tenantPhone}
                                                onChange={(e) => setTenantPhone(e.target.value)}
                                                className="w-full text-xs rounded-lg border border-slate-200 px-2.5 py-1.5 text-slate-900 focus:outline-hidden focus:border-[#1B5888]"
                                              />
                                            </div>
                                            <div>
                                              <label className="text-[11px] font-semibold text-slate-600 block mb-1">
                                                {t("agency_bridge_tenant_email_label")}
                                              </label>
                                              <input
                                                type="email"
                                                value={tenantEmail}
                                                onChange={(e) => setTenantEmail(e.target.value)}
                                                className="w-full text-xs rounded-lg border border-slate-200 px-2.5 py-1.5 text-slate-900 focus:outline-hidden focus:border-[#1B5888]"
                                              />
                                            </div>
                                          </div>

                                          <div className="grid grid-cols-2 sm:grid-cols-4 gap-2.5">
                                            <div>
                                              <label className="text-[11px] font-semibold text-slate-600 block mb-1">
                                                {t("agency_bridge_contract_start_label")}
                                              </label>
                                              <input
                                                type="date"
                                                value={contractStartDate}
                                                onChange={(e) => setContractStartDate(e.target.value)}
                                                className="w-full text-xs rounded-lg border border-slate-200 px-2 py-1.5 text-slate-900 focus:outline-hidden focus:border-[#1B5888]"
                                              />
                                            </div>
                                            <div>
                                              <label className="text-[11px] font-semibold text-slate-600 block mb-1">
                                                {t("agency_bridge_contract_end_label")}
                                              </label>
                                              <input
                                                type="date"
                                                value={contractEndDate}
                                                onChange={(e) => setContractEndDate(e.target.value)}
                                                className="w-full text-xs rounded-lg border border-slate-200 px-2 py-1.5 text-slate-900 focus:outline-hidden focus:border-[#1B5888]"
                                              />
                                            </div>
                                            <div>
                                              <label className="text-[11px] font-semibold text-slate-600 block mb-1">
                                                {t("agency_bridge_contract_deposit_label")}
                                              </label>
                                              <input
                                                type="number"
                                                value={contractDeposit}
                                                onChange={(e) => setContractDeposit(e.target.value)}
                                                className="w-full text-xs rounded-lg border border-slate-200 px-2.5 py-1.5 text-slate-900 focus:outline-hidden focus:border-[#1B5888]"
                                              />
                                            </div>
                                            <div>
                                              <label className="text-[11px] font-semibold text-slate-600 block mb-1">
                                                {t("agency_bridge_contract_due_day_label")}
                                              </label>
                                              <input
                                                type="number"
                                                min={1}
                                                max={28}
                                                value={contractDueDay}
                                                onChange={(e) => setContractDueDay(e.target.value)}
                                                className="w-full text-xs rounded-lg border border-slate-200 px-2.5 py-1.5 text-slate-900 focus:outline-hidden focus:border-[#1B5888]"
                                              />
                                            </div>
                                          </div>
                                        </div>
                                      )}
                                    </div>
                                  </div>
                                )}
                              </div>
                            ) : (
                              <div className="rounded-xl border border-amber-200 bg-amber-50/70 p-4 flex items-start gap-3">
                                <Lock className="w-4 h-4 text-amber-700 shrink-0 mt-0.5" />
                                <div className="space-y-2">
                                  <p className="text-xs font-bold text-amber-900">
                                    {t("agency_bridge_pm_upsell_title")}
                                  </p>
                                  <p className="text-[11px] text-amber-800 leading-relaxed">
                                    {t("agency_bridge_pm_upsell_desc")}
                                  </p>
                                  <button
                                    type="button"
                                    onClick={() => {
                                      setClosingTarget(null);
                                      setActiveTab("account_settings");
                                    }}
                                    className="inline-flex items-center gap-1.5 text-xs font-bold text-[#1B5888] hover:underline cursor-pointer"
                                  >
                                    <span>{t("agency_account_menu_label")}</span>
                                    <ArrowRight className="w-3.5 h-3.5" />
                                  </button>
                                </div>
                              </div>
                            )
                          )}

                          {/* Modal Footer */}
                          <div className="flex items-center justify-end gap-2.5 pt-3 border-t border-slate-100">
                            <button
                              type="button"
                              disabled={isSubmittingClose}
                              onClick={() => setClosingTarget(null)}
                              className="px-4 py-2 rounded-xl text-xs font-bold text-slate-600 hover:bg-slate-100 transition-colors cursor-pointer"
                            >
                              {t("agency_panel_cancel_btn")}
                            </button>
                            <button
                              type="submit"
                              disabled={isSubmittingClose}
                              className="px-4 py-2.5 rounded-xl text-xs font-bold bg-[#1B5888] hover:bg-[#12406A] text-white shadow-xs transition-colors cursor-pointer disabled:opacity-50 inline-flex items-center gap-1.5"
                            >
                              <CheckCircle2 className="w-4 h-4" />
                              <span>
                                {isSubmittingClose
                                  ? "..."
                                  : hasPmModule && closingStatus === "rented" && handoverToPm
                                    ? t("agency_bridge_btn_confirm_close_and_handover")
                                    : t("agency_bridge_btn_confirm_close_only")}
                              </span>
                            </button>
                          </div>
                        </form>
                      </div>
                    </div>
                  )}

                </div>
  );
}
