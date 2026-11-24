"use client";

import React from "react";
import {
  ArrowRight,
  Building2,
  Calendar,
  ChevronRight,
  Inbox,
  MessageCircle,
  Phone,
  User,
} from "lucide-react";
import { AgencyLead, AgencyPanelTab, LeadType } from "../types";

export interface LeadCockpitCardsProps {
  leads: AgencyLead[];
  setActiveTab: (tab: AgencyPanelTab) => void;
  setLeadPoolFilter?: (filter: "all" | LeadType) => void;
  setLeadStatusFilter?: (filter: string) => void;
  t: (key: string) => string;
}

export default function LeadCockpitCards({
  leads = [],
  setActiveTab,
  setLeadPoolFilter,
  setLeadStatusFilter,
  t,
}: LeadCockpitCardsProps) {
  const openLeads = leads.filter(
    (l) => l.status !== "archived" && l.status !== "converted"
  );
  const newLeads = openLeads.filter((l) => l.status === "new");
  const ownerLeads = openLeads.filter((l) => l.lead_type === "owner_consignment");
  const viewingLeads = openLeads.filter((l) => l.lead_type === "viewing_request");
  const generalLeads = openLeads.filter((l) => l.lead_type === "general_inquiry");

  const recentOpenLeads = [...openLeads]
    .sort(
      (a, b) =>
        new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
    )
    .slice(0, 3);

  return (
    <div className="space-y-4">
      {/* Section Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2.5">
          <div className="w-7 h-7 rounded-lg bg-sky-50 text-sky-600 border border-sky-200/60 flex items-center justify-center shrink-0">
            <Inbox className="w-3.5 h-3.5" />
          </div>
          <div>
            <h4 className="text-sm font-bold text-[#1A1A1A] tracking-tight">
              {t("agency_welcome_open_leads_title")}
            </h4>
          </div>
        </div>

        <div className="flex items-center gap-2">
          <div
            className={`inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-[11px] font-bold border ${
              openLeads.length > 0
                ? "bg-[#FBF1DC] text-[#8A5206] border-[#8A5206]/20"
                : "bg-[#E6F3EA] text-[#2A6E43] border-[#2A6E43]/20"
            }`}
          >
            <span
              className={`w-1.5 h-1.5 rounded-full ${
                openLeads.length > 0 ? "bg-amber-500" : "bg-emerald-500"
              }`}
            />
            <span>
              {openLeads.length > 0
                ? `${openLeads.length} ${t("agency_pm_dash_status_actions_pending")}`
                : t("agency_welcome_lead_card_all_good")}
            </span>
          </div>

          <button
            type="button"
            onClick={() => {
              setLeadPoolFilter?.("all");
              setLeadStatusFilter?.("all");
              setActiveTab("leads");
            }}
            className="text-xs font-semibold text-[#1B5888] hover:text-[#12406A] flex items-center gap-1 cursor-pointer"
          >
            <span>{t("agency_welcome_lead_card_action")}</span>
            <ChevronRight className="w-3.5 h-3.5" />
          </button>
        </div>
      </div>

      {/* 4 Bento Action Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3.5">
        {/* Card 1: Yeni Gelen Talepler */}
        <div
          onClick={() => {
            setLeadPoolFilter?.("all");
            setLeadStatusFilter?.("new");
            setActiveTab("leads");
          }}
          className={`bg-white rounded-[10px] border border-[#E5E3DF] p-4 shadow-2xs hover:border-[#8A8A8A] transition-all cursor-pointer relative overflow-hidden group ${
            newLeads.length === 0 ? "opacity-75" : ""
          }`}
        >
          <Inbox className="absolute -right-3 -bottom-3 w-28 h-28 text-sky-600 opacity-[0.03] group-hover:scale-105 transition-transform pointer-events-none" />

          <div className="flex items-center justify-between">
            <div className="w-9 h-9 rounded-lg bg-sky-50 text-sky-600 border border-sky-100 flex items-center justify-center shrink-0">
              <Inbox className="w-4 h-4" />
            </div>
            <div className="w-7 h-7 rounded-full border border-[#E5E3DF] bg-slate-50 flex items-center justify-center text-[#666666] group-hover:text-sky-600 group-hover:bg-sky-50 transition-colors">
              <ChevronRight className="w-3.5 h-3.5" />
            </div>
          </div>

          <p className="text-xs font-semibold text-[#666666] mt-2.5">
            {t("agency_welcome_lead_card_new")}
          </p>
          <p className="text-lg sm:text-xl font-bold text-[#1A1A1A] tracking-tight mt-0.5">
            {newLeads.length} {t("agency_pm_dash_request_unit")}
          </p>

          <p className="text-[11px] text-[#666666] mt-2">
            {t("agency_welcome_lead_card_new_desc")}
          </p>

          <div className="mt-3 pt-2.5 border-t border-slate-100 flex items-center justify-between text-[11px] font-bold text-sky-700">
            <span>{t("agency_welcome_lead_card_action")}</span>
            <ArrowRight className="w-3 h-3 group-hover:translate-x-1 transition-transform" />
          </div>
        </div>

        {/* Card 2: Mülk Sahibi Başvuruları */}
        <div
          onClick={() => {
            setLeadPoolFilter?.("owner_consignment");
            setLeadStatusFilter?.("all");
            setActiveTab("leads");
          }}
          className={`bg-white rounded-[10px] border border-[#E5E3DF] p-4 shadow-2xs hover:border-[#8A8A8A] transition-all cursor-pointer relative overflow-hidden group ${
            ownerLeads.length === 0 ? "opacity-75" : ""
          }`}
        >
          <Building2 className="absolute -right-3 -bottom-3 w-28 h-28 text-emerald-600 opacity-[0.03] group-hover:scale-105 transition-transform pointer-events-none" />

          <div className="flex items-center justify-between">
            <div className="w-9 h-9 rounded-lg bg-emerald-50 text-emerald-600 border border-emerald-100 flex items-center justify-center shrink-0">
              <Building2 className="w-4 h-4" />
            </div>
            <div className="w-7 h-7 rounded-full border border-[#E5E3DF] bg-slate-50 flex items-center justify-center text-[#666666] group-hover:text-emerald-600 group-hover:bg-emerald-50 transition-colors">
              <ChevronRight className="w-3.5 h-3.5" />
            </div>
          </div>

          <p className="text-xs font-semibold text-[#666666] mt-2.5">
            {t("agency_welcome_lead_card_owners")}
          </p>
          <p className="text-lg sm:text-xl font-bold text-[#1A1A1A] tracking-tight mt-0.5">
            {ownerLeads.length} {t("agency_pm_dash_request_unit")}
          </p>

          <p className="text-[11px] text-[#666666] mt-2">
            {t("agency_welcome_lead_card_owners_desc")}
          </p>

          <div className="mt-3 pt-2.5 border-t border-slate-100 flex items-center justify-between text-[11px] font-bold text-emerald-700">
            <span>{t("agency_panel_leads_pool_owners")}</span>
            <ArrowRight className="w-3 h-3 group-hover:translate-x-1 transition-transform" />
          </div>
        </div>

        {/* Card 3: Ziyaret & Randevu Talepleri */}
        <div
          onClick={() => {
            setLeadPoolFilter?.("viewing_request");
            setLeadStatusFilter?.("all");
            setActiveTab("leads");
          }}
          className={`bg-white rounded-[10px] border border-[#E5E3DF] p-4 shadow-2xs hover:border-[#8A8A8A] transition-all cursor-pointer relative overflow-hidden group ${
            viewingLeads.length === 0 ? "opacity-75" : ""
          }`}
        >
          <Calendar className="absolute -right-3 -bottom-3 w-28 h-28 text-amber-600 opacity-[0.03] group-hover:scale-105 transition-transform pointer-events-none" />

          <div className="flex items-center justify-between">
            <div className="w-9 h-9 rounded-lg bg-amber-50 text-amber-600 border border-amber-100 flex items-center justify-center shrink-0">
              <Calendar className="w-4 h-4" />
            </div>
            <div className="w-7 h-7 rounded-full border border-[#E5E3DF] bg-slate-50 flex items-center justify-center text-[#666666] group-hover:text-amber-600 group-hover:bg-amber-50 transition-colors">
              <ChevronRight className="w-3.5 h-3.5" />
            </div>
          </div>

          <p className="text-xs font-semibold text-[#666666] mt-2.5">
            {t("agency_welcome_lead_card_viewings")}
          </p>
          <p className="text-lg sm:text-xl font-bold text-[#1A1A1A] tracking-tight mt-0.5">
            {viewingLeads.length} {t("agency_pm_dash_request_unit")}
          </p>

          <p className="text-[11px] text-[#666666] mt-2">
            {t("agency_welcome_lead_card_viewings_desc")}
          </p>

          <div className="mt-3 pt-2.5 border-t border-slate-100 flex items-center justify-between text-[11px] font-bold text-amber-700">
            <span>{t("agency_panel_leads_pool_viewings")}</span>
            <ArrowRight className="w-3 h-3 group-hover:translate-x-1 transition-transform" />
          </div>
        </div>

        {/* Card 4: Genel Danışmanlık */}
        <div
          onClick={() => {
            setLeadPoolFilter?.("general_inquiry");
            setLeadStatusFilter?.("all");
            setActiveTab("leads");
          }}
          className={`bg-white rounded-[10px] border border-[#E5E3DF] p-4 shadow-2xs hover:border-[#8A8A8A] transition-all cursor-pointer relative overflow-hidden group ${
            generalLeads.length === 0 ? "opacity-75" : ""
          }`}
        >
          <MessageCircle className="absolute -right-3 -bottom-3 w-28 h-28 text-purple-600 opacity-[0.03] group-hover:scale-105 transition-transform pointer-events-none" />

          <div className="flex items-center justify-between">
            <div className="w-9 h-9 rounded-lg bg-purple-50 text-purple-600 border border-purple-100 flex items-center justify-center shrink-0">
              <MessageCircle className="w-4 h-4" />
            </div>
            <div className="w-7 h-7 rounded-full border border-[#E5E3DF] bg-slate-50 flex items-center justify-center text-[#666666] group-hover:text-purple-600 group-hover:bg-purple-50 transition-colors">
              <ChevronRight className="w-3.5 h-3.5" />
            </div>
          </div>

          <p className="text-xs font-semibold text-[#666666] mt-2.5">
            {t("agency_panel_leads_pool_general")}
          </p>
          <p className="text-lg sm:text-xl font-bold text-[#1A1A1A] tracking-tight mt-0.5">
            {generalLeads.length} {t("agency_pm_dash_request_unit")}
          </p>

          <p className="text-[11px] text-[#666666] mt-2">
            {t("agency_panel_leads_desc")}
          </p>

          <div className="mt-3 pt-2.5 border-t border-slate-100 flex items-center justify-between text-[11px] font-bold text-purple-700">
            <span>{t("agency_panel_leads_pool_general")}</span>
            <ArrowRight className="w-3 h-3 group-hover:translate-x-1 transition-transform" />
          </div>
        </div>
      </div>

      {/* Mini Recent Leads Preview if any exist */}
      {recentOpenLeads.length > 0 && (
        <div className="bg-slate-50/70 rounded-[10px] border border-[#E5E3DF] p-3.5 space-y-2.5">
          <div className="flex items-center justify-between px-1">
            <span className="text-xs font-bold text-[#4A4A4A]">
              {t("agency_panel_leads_title")} ({openLeads.length})
            </span>
            <button
              type="button"
              onClick={() => {
                setLeadPoolFilter?.("all");
                setLeadStatusFilter?.("all");
                setActiveTab("leads");
              }}
              className="text-[11px] font-semibold text-[#1B5888] hover:underline cursor-pointer"
            >
              {t("agency_welcome_lead_card_action")} →
            </button>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-2.5">
            {recentOpenLeads.map((lead) => {
              const isOwner = lead.lead_type === "owner_consignment";
              const isViewing = lead.lead_type === "viewing_request";
              return (
                <div
                  key={lead.id}
                  onClick={() => {
                    setLeadPoolFilter?.(lead.lead_type);
                    setActiveTab("leads");
                  }}
                  className="bg-white p-3 rounded-lg border border-[#E5E3DF] hover:border-[#8A8A8A] transition-all cursor-pointer text-left space-y-1.5 shadow-2xs"
                >
                  <div className="flex items-center justify-between gap-2">
                    <span
                      className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${
                        isOwner
                          ? "bg-emerald-50 text-emerald-700 border border-emerald-200"
                          : isViewing
                          ? "bg-amber-50 text-amber-700 border border-amber-200"
                          : "bg-purple-50 text-purple-700 border border-purple-200"
                      }`}
                    >
                      {isOwner
                        ? t("agency_panel_leads_type_owner")
                        : isViewing
                        ? t("agency_panel_leads_type_viewing")
                        : t("agency_panel_leads_type_general")}
                    </span>

                    {lead.status === "new" && (
                      <span className="w-2 h-2 rounded-full bg-rose-500 animate-pulse shrink-0" />
                    )}
                  </div>

                  <p className="text-xs font-bold text-[#1A1A1A] truncate flex items-center gap-1.5">
                    <User className="w-3 h-3 text-[#666666] shrink-0" />
                    <span className="truncate">{lead.client_name}</span>
                  </p>

                  <div className="flex items-center gap-1.5 text-[11px] text-[#666666] truncate">
                    <Phone className="w-3 h-3 text-[#8A8A8A] shrink-0" />
                    <span className="truncate">{lead.client_phone || "-"}</span>
                  </div>

                  {lead.listing_title && (
                    <p className="text-[10px] text-[#8A8A8A] truncate">
                      {lead.listing_title}
                    </p>
                  )}
                </div>
              );
            })}
          </div>
        </div>
      )}
    </div>
  );
}
