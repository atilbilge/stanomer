"use client";

import React from "react";
import Link from "next/link";
import {
  ArrowRight,
  Building2,
  Check,
  CheckCircle2,
  ChevronRight,
  ExternalLink,
  Globe,
  Settings,
  Lock,
} from "lucide-react";
import {
  AgencyContract,
  AgencyLead,
  AgencyListingRow,
  AgencyMaintStatusFilter,
  AgencyMaintenanceRequest,
  AgencyManagedProperty,
  AgencyPanelTab,
  AgencyRentPayment,
  LeadType,
} from "../types";
import LeadCockpitCards from "./LeadCockpitCards";
import PmCockpitCards from "./PmCockpitCards";

export interface WelcomeTabProps {
  agencyName: string;
  agencyLogoUrl: string;
  agencyPhone: string;
  agencyAddress: string;
  showcaseUrl: string;
  isPortfolioEnabled?: boolean;
  isPropertyLeaseEnabled?: boolean;
  activeModules?: string[];
  isDemoMode: boolean;
  demoFocus: "presales" | "aftersales" | "both";
  setDemoFocus: (focus: "presales" | "aftersales" | "both") => void;
  listings: AgencyListingRow[];
  managedProperties: AgencyManagedProperty[];
  managedPropertyStats?: {
    total: number;
    occupied: number;
    vacant: number;
    occupancyRate: number;
  };
  leads?: AgencyLead[];
  payments?: AgencyRentPayment[];
  contracts?: AgencyContract[];
  maintenanceRequests?: AgencyMaintenanceRequest[];
  setActiveTab: (tab: AgencyPanelTab) => void;
  setStatusMessage: (msg: { type: "success" | "error"; text: string } | null) => void;
  setPaymentStatusFilter?: (status: "all" | "awaiting" | "overdue" | "paid") => void;
  setPropOccupancyFilter?: (filter: "all" | "occupied" | "vacant") => void;
  setLeadPoolFilter?: (filter: "all" | LeadType) => void;
  setLeadStatusFilter?: (filter: string) => void;
  setMaintStatusFilter?: (status: AgencyMaintStatusFilter) => void;
  moduleUpgradeRequested?: boolean;
  handleRequestModuleUpgrade?: () => void;
  handleActivateDemoModule?: (moduleKey: string) => void;
  t: (key: string) => string;
}

interface SetupStep {
  id: string;
  title: string;
  desc: string;
  targetTab: AgencyPanelTab;
  isCompleted: boolean;
}

export default function WelcomeTab({
  agencyName,
  agencyLogoUrl,
  agencyPhone,
  agencyAddress,
  showcaseUrl,
  isPortfolioEnabled = true,
  isPropertyLeaseEnabled = true,
  activeModules,
  isDemoMode,
  demoFocus,
  setDemoFocus,
  listings,
  managedProperties,
  managedPropertyStats,
  leads = [],
  payments = [],
  contracts = [],
  maintenanceRequests = [],
  setActiveTab,
  setStatusMessage,
  setPaymentStatusFilter,
  setPropOccupancyFilter,
  setLeadPoolFilter,
  setLeadStatusFilter,
  setMaintStatusFilter,
  moduleUpgradeRequested = false,
  handleRequestModuleUpgrade,
  handleActivateDemoModule,
  t,
}: WelcomeTabProps) {
  // Derive effective module states
  const hasPortfolio = activeModules
    ? activeModules.includes("portfolio_distribution")
    : isPortfolioEnabled;
  const hasPropertyLease = activeModules
    ? activeModules.includes("property_lease_management")
    : isPropertyLeaseEnabled;

  const hasProfileConfigured = Boolean(agencyLogoUrl || agencyPhone || agencyAddress);
  const hasListings = listings.length > 0;
  const hasManagedProperties = managedProperties.length > 0;
  const hasContracts =
    managedProperties.some((p) => p.is_occupied || Boolean(p.active_contract_id)) ||
    contracts.length > 0;

  // Determine whether each module's setup steps are completely satisfied
  const isPortfolioSetupCompleted = hasProfileConfigured && hasListings;
  const isPropertyLeaseSetupCompleted =
    hasProfileConfigured && hasManagedProperties && hasContracts;

  // Dynamically assemble onboarding steps tailored to the agency's subscribed/selected modules
  const steps: SetupStep[] = [];

  if (hasPortfolio && hasPropertyLease) {
    // Scenario 1: Full Suite (Both Portfolio & Property Lease Management)
    steps.push({
      id: "profile",
      title: t("agency_welcome_step_profile_title"),
      desc: t("agency_welcome_step_profile_desc"),
      targetTab: "settings",
      isCompleted: hasProfileConfigured,
    });
    steps.push({
      id: "listing",
      title: t("agency_welcome_step_listing_title"),
      desc: t("agency_welcome_step_listing_desc"),
      targetTab: "form",
      isCompleted: hasListings,
    });
    steps.push({
      id: "property",
      title: t("agency_welcome_step_add_property_title"),
      desc: t("agency_welcome_step_add_property_desc"),
      targetTab: "managed_properties",
      isCompleted: hasManagedProperties,
    });
    steps.push({
      id: "payments",
      title: t("agency_welcome_step_payments_title"),
      desc: t("agency_welcome_step_payments_desc"),
      targetTab: "payments",
      isCompleted: hasContracts || hasManagedProperties,
    });
  } else if (hasPortfolio && !hasPropertyLease) {
    // Scenario 2: Portfolio & Distribution ONLY
    steps.push({
      id: "profile",
      title: t("agency_welcome_step_profile_title"),
      desc: t("agency_welcome_step_profile_desc"),
      targetTab: "settings",
      isCompleted: hasProfileConfigured,
    });
    steps.push({
      id: "listing",
      title: t("agency_welcome_step_listing_title"),
      desc: t("agency_welcome_step_listing_desc"),
      targetTab: "form",
      isCompleted: hasListings,
    });
    steps.push({
      id: "portals",
      title: t("agency_welcome_step_portals_title"),
      desc: t("agency_welcome_step_portals_desc"),
      targetTab: "xml",
      isCompleted: hasListings,
    });
    steps.push({
      id: "crm",
      title: t("agency_welcome_step_crm_title"),
      desc: t("agency_welcome_step_crm_desc"),
      targetTab: "leads",
      isCompleted: leads.length > 0,
    });
  } else if (!hasPortfolio && hasPropertyLease) {
    // Scenario 3: Property & Lease Management ONLY
    steps.push({
      id: "profile",
      title: t("agency_welcome_step_pm_profile_title"),
      desc: t("agency_welcome_step_pm_profile_desc"),
      targetTab: "settings",
      isCompleted: hasProfileConfigured,
    });
    steps.push({
      id: "property",
      title: t("agency_welcome_step_add_property_title"),
      desc: t("agency_welcome_step_add_property_desc"),
      targetTab: "managed_properties",
      isCompleted: hasManagedProperties,
    });
    steps.push({
      id: "contract",
      title: t("agency_welcome_step_contract_title"),
      desc: t("agency_welcome_step_contract_desc"),
      targetTab: "managed_properties",
      isCompleted: hasContracts,
    });
    steps.push({
      id: "payments",
      title: t("agency_welcome_step_payments_title"),
      desc: t("agency_welcome_step_payments_desc"),
      targetTab: "payments",
      isCompleted: hasContracts || hasManagedProperties,
    });
  } else {
    // Scenario 4: Initial / No Modules Active
    steps.push({
      id: "profile",
      title: t("agency_welcome_step_profile_title"),
      desc: t("agency_welcome_step_profile_desc"),
      targetTab: "settings",
      isCompleted: hasProfileConfigured,
    });
    steps.push({
      id: "packages",
      title: t("agency_account_packages_title"),
      desc: t("agency_welcome_modules_sec_desc"),
      targetTab: "account_settings",
      isCompleted: false,
    });
  }

  const completedSteps = steps.filter((s) => s.isCompleted).length;
  const totalSteps = steps.length;
  const progressPct = totalSteps > 0 ? Math.round((completedSteps / totalSteps) * 100) : 0;
  const allSetupStepsDone = totalSteps > 0 && completedSteps === totalSteps;

  return (
    <div
      role="tabpanel"
      id="tabpanel-welcome"
      aria-labelledby="tab-welcome"
      className="space-y-6 animate-in fade-in duration-200"
    >
      {/* Section 1: Executive Agency Overview Header */}
      <div className="bg-white rounded-[10px] border border-[#E5E3DF] p-5 sm:p-6 shadow-2xs relative overflow-hidden">
        <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-5 relative z-10">
          <div className="flex items-start gap-4">
            {agencyLogoUrl ? (
              <img
                src={agencyLogoUrl}
                alt={agencyName || "Agency Logo"}
                className="w-14 h-14 rounded-[10px] object-contain bg-white border border-[#E5E3DF] shadow-2xs shrink-0"
              />
            ) : (
              <div className="w-14 h-14 rounded-[10px] bg-[#1B5888] text-white flex items-center justify-center font-bold text-xl shadow-xs shrink-0 font-mono">
                {agencyName ? agencyName.charAt(0).toUpperCase() : "A"}
              </div>
            )}
            <div>
              <div className="flex items-center gap-2 flex-wrap">
                <h2 className="text-xl sm:text-2xl font-bold tracking-tight text-[#1A1A1A]">
                  {agencyName || "Stanomer Partner Agency"}
                </h2>
                {isDemoMode ? (
                  <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-md border border-[#8A5206]/20 bg-[#FBF1DC] text-[11px] font-semibold text-[#8A5206]">
                    <span className="w-1.5 h-1.5 rounded-full bg-amber-500 animate-pulse" />
                    {t("agency_panel_demo_mode_label")}
                  </span>
                ) : (
                  <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-md border border-[#E5E3DF] bg-white text-[11px] font-medium text-[#4A4A4A]">
                    <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 ring-2 ring-emerald-500/20" />
                    {t("agency_panel_active_agency_label")}
                  </span>
                )}
              </div>
              <p className="text-xs sm:text-sm text-[#666666] mt-1 max-w-2xl leading-relaxed">
                {t("agency_welcome_sub")}
              </p>
            </div>
          </div>

          {/* Quick Utility Links (Showcase & Feed) */}
          <div className="flex items-center gap-2 flex-wrap self-start md:self-auto shrink-0">
            {hasPortfolio ? (
              <Link
                href={showcaseUrl}
                target="_blank"
                className="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-[10px] bg-white border-[1.5px] border-[#1B5888] hover:bg-[#E5EEF6] text-[#1B5888] text-xs font-semibold transition-colors shrink-0"
                title={t("agency_panel_preview_tpl")}
              >
                <Globe className="w-3.5 h-3.5 text-[#666666]" />
                <span>{t("agency_panel_preview_tpl")}</span>
                <ExternalLink className="w-3 h-3 text-[#666666]" />
              </Link>
            ) : (
              <button
                type="button"
                onClick={() => setActiveTab("account_settings")}
                className="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-[10px] bg-white border-[1.5px] border-[#D1CFCA] hover:bg-[#FAF9F7] text-[#4A4A4A] text-xs font-semibold transition-colors shrink-0 cursor-pointer"
                title={t("agency_panel_menu_account_settings")}
              >
                <Globe className="w-3.5 h-3.5 text-[#666666]" />
                <span>{t("agency_panel_preview_tpl")}</span>
                <span className="p-1 rounded bg-amber-50 text-amber-700 border border-amber-200 font-bold inline-flex items-center">
                  <Lock className="w-2.5 h-2.5" />
                </span>
              </button>
            )}
            <button
              type="button"
              onClick={() => setActiveTab("settings")}
              className="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-[10px] bg-[#1B5888] hover:bg-[#12406A] active:bg-[#12406A] text-white text-xs font-bold shadow-xs transition-colors cursor-pointer shrink-0"
            >
              <Settings className="w-3.5 h-3.5" />
              <span>{t("agency_panel_menu_settings")}</span>
            </button>
          </div>
        </div>
      </div>

      {/* Section 2: Onboarding Setup Guide (Hidden once 100% completed) */}
      {!allSetupStepsDone && (
        <div className="bg-white rounded-[10px] border border-[#E5E3DF] p-5 shadow-2xs space-y-4">
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
            <div>
              <h3 className="text-sm font-bold text-[#1A1A1A] tracking-tight flex items-center gap-2">
                <CheckCircle2 className="w-4 h-4 text-[#4A4A4A]" />
                <span>{t("agency_welcome_onboarding_title")}</span>
              </h3>
              <p className="text-xs text-[#666666] mt-0.5">
                {t("agency_welcome_onboarding_progress")
                  .replace("{completed}", String(completedSteps))
                  .replace("{total}", String(totalSteps))}
              </p>
            </div>
            <div className="w-full sm:w-48 flex items-center gap-2">
              <div className="flex-1 h-1.5 bg-slate-100 rounded-full overflow-hidden">
                <div
                  className="h-full bg-[#1B5888] rounded-full transition-all duration-300"
                  style={{ width: `${progressPct}%` }}
                />
              </div>
              <span className="text-[11px] font-mono font-bold text-[#4A4A4A] tabular-nums">
                {progressPct}%
              </span>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-3 pt-1">
            {steps.map((step, idx) => {
              return (
                <div
                  key={step.id}
                  onClick={() => setActiveTab(step.targetTab)}
                  className={`p-3.5 rounded-lg border text-left cursor-pointer transition-all flex items-start gap-3 ${step.isCompleted
                    ? "bg-slate-50/50 border-[#E5E3DF] hover:bg-slate-50"
                    : "bg-white border-[#E5E3DF] hover:border-[#8A8A8A] shadow-2xs"
                    }`}
                >
                  <div
                    className={`w-6 h-6 rounded-md flex items-center justify-center shrink-0 mt-0.5 ${step.isCompleted
                      ? "bg-[#1B5888] text-white"
                      : "border border-[#E5E3DF] text-[#666666]"
                      }`}
                  >
                    {step.isCompleted ? (
                      <Check className="w-3.5 h-3.5 stroke-[3]" />
                    ) : (
                      <span className="text-[11px] font-mono font-bold">{idx + 1}</span>
                    )}
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-xs font-bold text-[#1A1A1A]">{step.title}</p>
                    <p className="text-[11px] text-[#666666] mt-0.5 leading-relaxed">
                      {step.desc}
                    </p>
                  </div>
                  <ChevronRight className="w-4 h-4 text-[#666666] shrink-0 self-center" />
                </div>
              );
            })}
          </div>
        </div>
      )}

      {/* Section 2.5: Portfolio & Distribution Cockpit (Open Client Inquiries & CRM Cards) */}
      {hasPortfolio && isPortfolioSetupCompleted && (
        <LeadCockpitCards
          leads={leads}
          setActiveTab={setActiveTab}
          setLeadPoolFilter={setLeadPoolFilter}
          setLeadStatusFilter={setLeadStatusFilter}
          t={t}
        />
      )}

      {/* Section 2.7: Property & Lease Management Cockpit (The 7 Core Action Cards) */}
      {hasPropertyLease && isPropertyLeaseSetupCompleted && (
        <div className="space-y-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2.5">
              <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-blue-600 to-slate-900 text-white flex items-center justify-center shadow-xs shrink-0">
                <Building2 className="w-4 h-4" />
              </div>
              <div>
                <h3 className="text-sm sm:text-base font-bold text-[#1A1A1A] tracking-tight">
                  {t("agency_welcome_sec_pm_cockpit")}
                </h3>
                <p className="text-xs text-[#666666]">
                  {t("agency_welcome_sec_pm_cockpit_desc")}
                </p>
              </div>
            </div>
            <button
              type="button"
              onClick={() => setActiveTab("managed_properties")}
              className="text-xs font-semibold text-[#1B5888] hover:text-[#12406A] flex items-center gap-1 cursor-pointer"
            >
              <span>{t("agency_pm_dash_btn_view_properties")}</span>
              <ChevronRight className="w-3.5 h-3.5" />
            </button>
          </div>

          <PmCockpitCards
            managedProperties={managedProperties}
            managedPropertyStats={managedPropertyStats}
            payments={payments}
            contracts={contracts}
            maintenanceRequests={maintenanceRequests}
            setActiveTab={setActiveTab}
            setPaymentStatusFilter={setPaymentStatusFilter}
            setPropOccupancyFilter={setPropOccupancyFilter}
            setMaintStatusFilter={setMaintStatusFilter}
            t={t}
          />
        </div>
      )}
    </div>
  );
}
