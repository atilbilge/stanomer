"use client";

import React from "react";
import {
  Building2,
  PlusCircle,
  Wrench,
} from "lucide-react";
import {
  AgencyManagedProperty,
  AgencyRentPayment,
  AgencyContract,
  AgencyMaintenanceRequest,
  AgencyPanelTab,
} from "../types";
import PmCockpitCards from "./PmCockpitCards";

export interface PmDashboardTabProps {
  agencyName: string;
  managedProperties: AgencyManagedProperty[];
  managedPropertyStats: {
    total: number;
    occupied: number;
    vacant: number;
    occupancyRate: number;
  };
  payments: AgencyRentPayment[];
  contracts: AgencyContract[];
  maintenanceRequests: AgencyMaintenanceRequest[];
  setActiveTab: (tab: AgencyPanelTab) => void;
  setPaymentStatusFilter: (status: "all" | "awaiting" | "overdue" | "paid") => void;
  setPropOccupancyFilter: (filter: "all" | "occupied" | "vacant") => void;
  resetForm: () => void;
  setNewMaintPropId: (id: string) => void;
  setIsNewMaintModalOpen: (open: boolean) => void;
  isDemoMode?: boolean;
  isDemoVerified?: boolean;
  onRequestVerification?: () => void;
  t: (key: string) => string;
}

export default function PmDashboardTab({
  agencyName,
  managedProperties,
  managedPropertyStats,
  payments,
  contracts,
  maintenanceRequests,
  setActiveTab,
  setPaymentStatusFilter,
  setPropOccupancyFilter,
  resetForm,
  setNewMaintPropId,
  setIsNewMaintModalOpen,
  isDemoMode,
  isDemoVerified,
  onRequestVerification,
  t,
}: PmDashboardTabProps) {
  return (
    <div
      role="tabpanel"
      id="tabpanel-pm-dashboard"
      aria-labelledby="tab-pm-dashboard"
      className="space-y-6 animate-in fade-in duration-200"
    >
      {/* ── 1. WELCOME BANNER ── */}
      <div className="bg-white rounded-[10px] border border-[#E5E3DF] p-6 sm:p-7 shadow-2xs relative overflow-hidden group hover:shadow-xs transition-all">
        <Building2 className="absolute -right-6 -bottom-6 w-48 h-48 text-[#1A1A1A] opacity-[0.025] pointer-events-none group-hover:scale-105 transition-transform" />

        <div className="relative z-10 flex flex-col md:flex-row md:items-center md:justify-between gap-6">
          <div className="space-y-3">
            <div className="flex items-center gap-3">
              <div className="w-12 h-12 rounded-[10px] bg-gradient-to-br from-blue-600 to-slate-900 text-white flex items-center justify-center shadow-md shadow-blue-600/20 shrink-0">
                <Building2 className="w-6 h-6" />
              </div>

              <div className="inline-flex items-center gap-2 px-3 py-1.5 rounded-full bg-[#E6F3EA] border border-[#2A6E43]/20 text-xs font-bold text-[#2A6E43]">
                <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse shrink-0" />
                <span>Stanomer Property & Lease Management</span>
              </div>
            </div>

            <div>
              <h2 className="text-xl font-bold text-[#1A1A1A] tracking-tight mt-1">
                {agencyName || "Stanomer Real Estate"}
              </h2>
              <p className="text-xs sm:text-sm text-[#666666] max-w-2xl mt-1 leading-relaxed">
                {t("agency_pm_dash_subtitle")}
              </p>
            </div>
          </div>

          {/* Quick Action Buttons */}
          <div className="flex items-center gap-2.5 flex-wrap self-start md:self-auto shrink-0">
            <button
              type="button"
              onClick={() => {
                if (isDemoMode && !isDemoVerified) {
                  onRequestVerification?.();
                  return;
                }
                resetForm();
                setActiveTab("form");
              }}
              className="px-4 py-2.5 rounded-[10px] text-xs font-bold bg-[#1B5888] hover:bg-[#12406A] active:bg-[#12406A] text-white transition-colors flex items-center gap-2 shadow-xs cursor-pointer"
            >
              <PlusCircle className="w-4 h-4" />
              <span>{t("agency_panel_mob_new")}</span>
            </button>
            <button
              type="button"
              onClick={() => {
                if (isDemoMode && !isDemoVerified) {
                  onRequestVerification?.();
                  return;
                }
                setNewMaintPropId("");
                setIsNewMaintModalOpen(true);
              }}
              className="px-4 py-2.5 rounded-[10px] text-xs font-bold bg-slate-100 hover:bg-slate-200 text-[#4A4A4A] transition-colors flex items-center gap-2 border border-[#E5E3DF] cursor-pointer"
            >
              <Wrench className="w-4 h-4" />
              <span>{t("agency_prop_drawer_btn_new_ticket")}</span>
            </button>
          </div>
        </div>
      </div>

      {/* ── 2. THE 7 BENTO COCKPIT CARDS ── */}
      <PmCockpitCards
        managedProperties={managedProperties}
        managedPropertyStats={managedPropertyStats}
        payments={payments}
        contracts={contracts}
        maintenanceRequests={maintenanceRequests}
        setActiveTab={setActiveTab}
        setPaymentStatusFilter={setPaymentStatusFilter}
        setPropOccupancyFilter={setPropOccupancyFilter}
        t={t}
      />
    </div>
  );
}
