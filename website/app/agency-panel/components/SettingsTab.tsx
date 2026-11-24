"use client";

import React, { useState, useEffect } from "react";
import Link from "next/link";
import { ShowcaseTemplate, ShowcasePalette, ShowcaseRadius, ContactChannels, ShowcaseCurrency } from "../types";
import { SERBIAN_CITIES } from "../constants";
import { Language } from "../../../components/LanguageProvider";
import {
  AlertCircle,
  Building2,
  Check,
  CheckCircle2,
  Coins,
  Copy,
  ExternalLink,
  Globe,
  Languages,
  RefreshCw,
  Settings,
  ShieldCheck,
  Upload,
} from "lucide-react";

export interface SettingsTabProps {
  agencyName: string;
  setAgencyName: (n: string) => void;
  agencyPhone: string;
  setAgencyPhone: (p: string) => void;
  agencyEmail: string;
  setAgencyEmail: (e: string) => void;
  agencyWebsite: string;
  setAgencyWebsite: (w: string) => void;
  agencyCity: string;
  setAgencyCity: (c: string) => void;
  agencyAddress: string;
  setAgencyAddress: (a: string) => void;
  agencyLogoUrl: string;
  setAgencyLogoUrl: (u: string) => void;
  agencySlug: string;
  setAgencySlug: (s: string) => void;
  agencyCustomDomain: string;
  setAgencyCustomDomain: (d: string) => void;
  contactChannels: ContactChannels;
  setContactChannels: (ch: ContactChannels) => void;
  showcaseTemplate: ShowcaseTemplate;
  handleSelectTemplate: (t: ShowcaseTemplate) => void;
  showcasePalette: ShowcasePalette;
  setShowcasePalette: (p: ShowcasePalette) => void;
  showcaseRadius: ShowcaseRadius;
  setShowcaseRadius: (r: ShowcaseRadius) => void;
  showcaseLanguages: Language[];
  setShowcaseLanguages: (langs: Language[]) => void;
  showcaseCurrencies: ShowcaseCurrency[];
  setShowcaseCurrencies: (currs: ShowcaseCurrency[]) => void;
  showcaseDefaultCurrency: ShowcaseCurrency;
  setShowcaseDefaultCurrency: (cur: ShowcaseCurrency) => void;
  showcaseUrl: string;
  dnsCheckResult: {
    valid: boolean;
    reason?: string;
    recordType?: string;
    expectedTarget?: string;
  } | null;
  setDnsCheckResult: (res: any) => void;
  dnsCheckLoading: boolean;
  handleVerifyDns: () => void;
  handleSaveAgencyProfile: (e: React.FormEvent) => void;
  savingProfile: boolean;
  uploadingLogo: boolean;
  handleLogoFileUpload: (e: React.ChangeEvent<HTMLInputElement>) => void;
  userId: string | null;
  t: (key: string) => string;
}

export default function SettingsTab({
  agencyName,
  setAgencyName,
  agencyPhone,
  setAgencyPhone,
  agencyEmail,
  setAgencyEmail,
  agencyWebsite,
  setAgencyWebsite,
  agencyCity,
  setAgencyCity,
  agencyAddress,
  setAgencyAddress,
  agencyLogoUrl,
  setAgencyLogoUrl,
  agencySlug,
  setAgencySlug,
  agencyCustomDomain,
  setAgencyCustomDomain,
  contactChannels,
  setContactChannels,
  showcaseTemplate,
  handleSelectTemplate,
  showcasePalette,
  setShowcasePalette,
  showcaseRadius,
  setShowcaseRadius,
  showcaseLanguages,
  setShowcaseLanguages,
  showcaseCurrencies,
  setShowcaseCurrencies,
  showcaseDefaultCurrency,
  setShowcaseDefaultCurrency,
  showcaseUrl,
  dnsCheckResult,
  setDnsCheckResult,
  dnsCheckLoading,
  handleVerifyDns,
  handleSaveAgencyProfile,
  savingProfile,
  uploadingLogo,
  handleLogoFileUpload,
  userId,
  t,
}: SettingsTabProps) {
  const [copiedField, setCopiedField] = useState<string | null>(null);
  const [activeSubTab, setActiveSubTab] = useState<"identity" | "website">("identity");
  const [useCustomDomain, setUseCustomDomain] = useState<boolean>(() =>
    Boolean(agencyCustomDomain && agencyCustomDomain.trim().length > 0)
  );

  useEffect(() => {
    if (agencyCustomDomain && agencyCustomDomain.trim().length > 0) {
      setUseCustomDomain(true);
    }
  }, [agencyCustomDomain]);

  const copyToClipboard = (textToCopy: string, fieldKey: string) => {
    if (typeof navigator !== "undefined" && navigator.clipboard) {
      navigator.clipboard.writeText(textToCopy);
      setCopiedField(fieldKey);
      setTimeout(() => setCopiedField(null), 2000);
    }
  };

  return (
    <div
      role="tabpanel"
      id="tabpanel-settings"
      aria-labelledby="tab-settings"
      className="max-w-4xl mx-auto space-y-6"
    >
      {/* Sub-tab Navigation Switcher */}
      <div className="flex items-center gap-1 sm:gap-2 border-b border-[#E5E3DF] overflow-x-auto no-scrollbar">
        <button
          type="button"
          role="tab"
          aria-selected={activeSubTab === "identity"}
          onClick={() => setActiveSubTab("identity")}
          className={`py-3 px-3 sm:px-4 text-xs font-bold border-b-2 transition-all flex items-center gap-2 cursor-pointer whitespace-nowrap -mb-px ${
            activeSubTab === "identity"
              ? "border-[#1B5888] text-[#1B5888]"
              : "border-transparent text-[#666666] hover:text-[#1A1A1A] hover:border-[#E5E3DF]"
          }`}
        >
          <Building2 className={`w-4 h-4 shrink-0 ${activeSubTab === "identity" ? "text-[#1B5888]" : "text-[#8A8A8A]"}`} />
          <span>{t("agency_settings_subtab_identity")}</span>
        </button>

        <button
          type="button"
          role="tab"
          aria-selected={activeSubTab === "website"}
          onClick={() => setActiveSubTab("website")}
          className={`py-3 px-3 sm:px-4 text-xs font-bold border-b-2 transition-all flex items-center gap-2 cursor-pointer whitespace-nowrap -mb-px ${
            activeSubTab === "website"
              ? "border-[#1B5888] text-[#1B5888]"
              : "border-transparent text-[#666666] hover:text-[#1A1A1A] hover:border-[#E5E3DF]"
          }`}
        >
          <Globe className={`w-4 h-4 shrink-0 ${activeSubTab === "website" ? "text-[#1B5888]" : "text-[#8A8A8A]"}`} />
          <span>{t("agency_settings_subtab_website")}</span>
        </button>
      </div>

      <form onSubmit={handleSaveAgencyProfile} className="space-y-6">
        {/* SUBTAB 1: KURUMSAL KİMLİK & İLETİŞİM */}
        {activeSubTab === "identity" && (
          <section
            aria-labelledby="agency-identity-heading"
            className="bg-white rounded-[10px] border border-[#E5E3DF] p-5 sm:p-6 shadow-xs space-y-6"
          >
          <div className="border-b border-[#E5E3DF]/70 pb-3">
            <h3
              id="agency-identity-heading"
              className="text-base font-bold text-[#1A1A1A] flex items-center gap-2"
            >
              <Building2 className="w-4 h-4 text-[#1B5888]" />
              <span>{t("agency_panel_grp_profile_title")}</span>
            </h3>
            <p className="text-xs text-[#666666] mt-0.5">
              {t("agency_panel_grp_profile_desc")}
            </p>
          </div>

          {/* Logo Management Row */}
          <div>
            <label className="block text-xs font-semibold text-[#4A4A4A] mb-1.5">
              {t("agency_panel_logo_label")}
            </label>
            <div className="flex flex-col sm:flex-row sm:items-center gap-3">
              {/* Logo Preview Thumbnail */}
              <div className="w-14 h-14 rounded-[10px] border border-[#E5E3DF] bg-[#F8F7F5] flex items-center justify-center overflow-hidden shrink-0">
                {agencyLogoUrl ? (
                  <img
                    src={agencyLogoUrl}
                    alt={agencyName}
                    className="w-full h-full object-contain p-1"
                  />
                ) : (
                  <span className="text-sm font-bold text-[#666666]">
                    {agencyName ? agencyName.charAt(0).toUpperCase() : "A"}
                  </span>
                )}
              </div>

              {/* URL input + File Upload button */}
              <div className="flex-1 space-y-1">
                <div className="flex gap-2">
                  <input
                    id="prof-logo"
                    type="url"
                    value={agencyLogoUrl}
                    onChange={(e) => setAgencyLogoUrl(e.target.value)}
                    placeholder="https://.../logo.png"
                    className="flex-1 px-3 py-2 rounded-[10px] border border-[#E5E3DF] text-xs focus:border-[#1B5888] focus:ring-2 focus:ring-[#1B5888]/20 focus:outline-none"
                  />
                  <label
                    htmlFor="prof-logo-file"
                    className="inline-flex items-center gap-1.5 px-3 py-2 rounded-[10px] bg-[#F8F7F5] hover:bg-[#EFECE6] border border-[#E5E3DF] text-xs font-semibold text-[#4A4A4A] cursor-pointer shrink-0 transition-colors"
                  >
                    <Upload className="w-3.5 h-3.5" />
                    <span>
                      {uploadingLogo
                        ? t("agency_panel_photos_uploading")
                        : t("agency_panel_logo_upload")}
                    </span>
                  </label>
                  <input
                    id="prof-logo-file"
                    type="file"
                    accept="image/*"
                    onChange={handleLogoFileUpload}
                    className="sr-only"
                  />
                </div>
                <p className="text-[11px] text-[#666666]">
                  {t("agency_panel_logo_hint")}
                </p>
              </div>
            </div>
          </div>

          {/* Primary Contact Details (2x2 Grid) */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label
                htmlFor="prof-company"
                className="block text-xs font-semibold text-[#4A4A4A] mb-1"
              >
                {t("agency_panel_company_label")}
              </label>
              <input
                id="prof-company"
                type="text"
                autoComplete="organization"
                required
                value={agencyName}
                onChange={(e) => setAgencyName(e.target.value)}
                placeholder="Stanomer Nekretnine d.o.o."
                className="w-full px-3 py-2 rounded-[10px] border border-[#E5E3DF] text-sm focus:border-[#1B5888] focus:ring-2 focus:ring-[#1B5888]/20 focus:outline-none"
              />
            </div>

            <div>
              <label
                htmlFor="prof-phone"
                className="block text-xs font-semibold text-[#4A4A4A] mb-1"
              >
                {t("agency_panel_phone_label")}
              </label>
              <input
                id="prof-phone"
                type="tel"
                autoComplete="tel"
                value={agencyPhone}
                onChange={(e) => setAgencyPhone(e.target.value)}
                placeholder="+381 64 123 4567"
                className="w-full px-3 py-2 rounded-[10px] border border-[#E5E3DF] text-sm focus:border-[#1B5888] focus:ring-2 focus:ring-[#1B5888]/20 focus:outline-none"
              />
            </div>

            <div>
              <label
                htmlFor="prof-email"
                className="block text-xs font-semibold text-[#4A4A4A] mb-1"
              >
                {t("agency_panel_email_label")}
              </label>
              <input
                id="prof-email"
                type="email"
                autoComplete="email"
                value={agencyEmail}
                onChange={(e) => setAgencyEmail(e.target.value)}
                placeholder="info@agencija.rs"
                className="w-full px-3 py-2 rounded-[10px] border border-[#E5E3DF] text-sm focus:border-[#1B5888] focus:ring-2 focus:ring-[#1B5888]/20 focus:outline-none"
              />
            </div>

            <div>
              <label
                htmlFor="prof-website"
                className="block text-xs font-semibold text-[#4A4A4A] mb-1"
              >
                {t("agency_panel_website_label")}
              </label>
              <input
                id="prof-website"
                type="url"
                autoComplete="url"
                value={agencyWebsite}
                onChange={(e) => setAgencyWebsite(e.target.value)}
                placeholder="https://www.agencija.rs"
                className="w-full px-3 py-2 rounded-[10px] border border-[#E5E3DF] text-sm focus:border-[#1B5888] focus:ring-2 focus:ring-[#1B5888]/20 focus:outline-none"
              />
            </div>
          </div>

          {/* Address & City Row */}
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 pt-1">
            <div>
              <label
                htmlFor="prof-city"
                className="block text-xs font-semibold text-[#4A4A4A] mb-1"
              >
                {t("agency_panel_city_label")}
              </label>
              <select
                id="prof-city"
                value={agencyCity || "Beograd"}
                onChange={(e) => setAgencyCity(e.target.value)}
                className="w-full px-3 py-2 rounded-[10px] border border-[#E5E3DF] text-sm bg-white focus:border-[#1B5888] focus:ring-2 focus:ring-[#1B5888]/20 focus:outline-none cursor-pointer"
              >
                {agencyCity && !SERBIAN_CITIES.includes(agencyCity as any) && (
                  <option value={agencyCity}>{agencyCity}</option>
                )}
                {SERBIAN_CITIES.map((c) => (
                  <option key={c} value={c}>
                    {c}
                  </option>
                ))}
              </select>
            </div>

            <div className="sm:col-span-2">
              <label
                htmlFor="prof-address"
                className="block text-xs font-semibold text-[#4A4A4A] mb-1"
              >
                {t("agency_panel_address_label")}
              </label>
              <input
                id="prof-address"
                type="text"
                autoComplete="street-address"
                value={agencyAddress}
                onChange={(e) => setAgencyAddress(e.target.value)}
                placeholder="Knez Mihailova 14, Stari Grad"
                className="w-full px-3 py-2 rounded-[10px] border border-[#E5E3DF] text-sm focus:border-[#1B5888] focus:ring-2 focus:ring-[#1B5888]/20 focus:outline-none"
              />
            </div>
          </div>

            {/* Floating Messenger Channels */}
            <div className="pt-2 border-t border-[#E5E3DF]/70">
              <span className="block text-xs font-bold text-[#1A1A1A] mb-2">
                {t("agency_panel_channels_label")}
              </span>
              <div className="flex flex-wrap gap-2.5">
                {[
                  {
                    id: "both" as const,
                    label: t("agency_panel_ch_both"),
                    dot: "#10b981",
                  },
                  {
                    id: "whatsapp" as const,
                    label: t("agency_panel_ch_whatsapp"),
                    dot: "#25D366",
                  },
                  {
                    id: "viber" as const,
                    label: t("agency_panel_ch_viber"),
                    dot: "#7360F2",
                  },
                  {
                    id: "none" as const,
                    label: t("agency_panel_ch_none"),
                    dot: "#94a3b8",
                  },
                ].map((ch) => (
                  <button
                    key={ch.id}
                    type="button"
                    onClick={() => setContactChannels(ch.id)}
                    className={`inline-flex items-center gap-2 px-3 py-1.5 rounded-[10px] border text-xs font-semibold cursor-pointer transition-colors ${
                      contactChannels === ch.id
                        ? "border-[#1B5888] bg-[#1B5888] text-white shadow-xs"
                        : "border-[#E5E3DF] bg-white text-[#4A4A4A] hover:bg-[#F8F7F5]"
                    }`}
                  >
                    <span
                      className="w-2.5 h-2.5 rounded-full"
                      style={{ backgroundColor: ch.dot }}
                    />
                    <span>{ch.label}</span>
                  </button>
                ))}
              </div>
            </div>
          </section>
        )}

        {/* SUBTAB 2: VİTRİN WEB SİTESİ ÖZELLEŞTİRME */}
        {activeSubTab === "website" && (
          <div className="space-y-6">
            {/* 1. Web Adresi & Alan Adı (Custom Showcase Web URL or Custom Domain) */}
            <section
              aria-labelledby="custom-domain-heading"
              className="bg-white rounded-[10px] border border-[#E5E3DF] p-5 sm:p-6 shadow-xs space-y-5"
            >
              <div className="border-b border-[#E5E3DF]/70 pb-3 flex flex-col sm:flex-row sm:items-center justify-between gap-2">
                <div>
                  <h3
                    id="custom-domain-heading"
                    className="text-base font-bold text-[#1A1A1A] flex items-center gap-2"
                  >
                    <Globe className="w-4 h-4 text-[#1B5888]" />
                    <span>{t("agency_panel_web_address_title")}</span>
                  </h3>
                  <p className="text-xs text-[#666666] mt-0.5">
                    {t("agency_panel_web_address_desc")}
                  </p>
                </div>
                {agencyCustomDomain && useCustomDomain && (
                  <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[11px] font-bold bg-[#E6F3EA] text-[#2A6E43] border border-[#2A6E43]/20 self-start sm:self-auto">
                    <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
                    <span>{agencyCustomDomain}</span>
                  </span>
                )}
              </div>

              {/* Checkbox: Custom Domain kullanmak istiyorum */}
              <div className="p-3.5 rounded-[10px] bg-[#F8F7F5] border border-[#E5E3DF] flex items-start gap-3">
                <input
                  id="use-custom-domain"
                  type="checkbox"
                  checked={useCustomDomain}
                  onChange={(e) => {
                    const checked = e.target.checked;
                    setUseCustomDomain(checked);
                    if (!checked) {
                      setAgencyCustomDomain("");
                      setDnsCheckResult(null);
                    }
                  }}
                  className="mt-0.5 w-4 h-4 rounded text-[#1B5888] border-[#8A8A8A] focus:ring-2 focus:ring-[#1B5888] cursor-pointer"
                />
                <label htmlFor="use-custom-domain" className="cursor-pointer select-none">
                  <span className="block text-xs font-bold text-[#1A1A1A]">
                    {t("agency_panel_use_custom_domain_checkbox")}
                  </span>
                  <span className="block text-[11px] text-[#666666] mt-0.5">
                    {t("agency_panel_use_custom_domain_checkbox_desc")}
                  </span>
                </label>
              </div>

              {/* IF NOT using custom domain: Show Custom Showcase Web URL (Slug) */}
              {!useCustomDomain && (
                <div className="space-y-1.5 pt-1">
                  <label
                    htmlFor="prof-slug"
                    className="block text-xs font-semibold text-[#4A4A4A]"
                  >
                    {t("agency_panel_slug_label")}
                  </label>
                  <div className="flex items-center rounded-[10px] border border-[#E5E3DF] overflow-hidden focus-within:ring-2 focus-within:ring-[#1B5888]/20 focus-within:border-[#1B5888] bg-[#F8F7F5]">
                    <span className="px-3 py-2 text-xs text-[#666666] font-mono select-none border-r border-[#E5E3DF] shrink-0">
                      stanomer.online/agencija/
                    </span>
                    <input
                      id="prof-slug"
                      type="text"
                      value={agencySlug}
                      onChange={(e) =>
                        setAgencySlug(
                          e.target.value
                            .toLowerCase()
                            .replace(/[^a-z0-9_-]/g, "")
                        )
                      }
                      placeholder="agencija-nekretnine"
                      className="flex-1 px-3 py-2 text-sm bg-white focus:outline-none font-medium text-[#1A1A1A]"
                    />
                  </div>
                  <p className="text-[11px] text-[#666666]">
                    {t("agency_panel_slug_hint")}
                  </p>
                </div>
              )}

              {/* IF using custom domain: Show Custom Domain & CNAME Connection panel */}
              {useCustomDomain && (
                <div className="space-y-5 pt-1">
                  {/* Custom Domain Input & Verify Button */}
                  <div className="space-y-3">
                    <label
                      htmlFor="prof-custom-domain"
              className="block text-xs font-semibold text-[#4A4A4A]"
            >
              {t("agency_panel_custom_domain_label")}
            </label>
            <div className="flex flex-col sm:flex-row gap-2">
              <div className="relative flex-1">
                <Globe className="w-4 h-4 text-[#666666] absolute left-3 top-1/2 -translate-y-1/2" />
                <input
                  id="prof-custom-domain"
                  type="text"
                  value={agencyCustomDomain}
                  onChange={(e) => {
                    const val = e.target.value
                      .toLowerCase()
                      .replace(/^https?:\/\//, "")
                      .replace(/\/.*$/, "")
                      .replace(/:\d+$/, "")
                      .trim();
                    setAgencyCustomDomain(val);
                    setDnsCheckResult(null);
                  }}
                  placeholder={t("agency_panel_custom_domain_placeholder")}
                  className="w-full pl-9 pr-3 py-2.5 rounded-[10px] border border-[#E5E3DF] text-sm focus:border-[#1B5888] focus:ring-2 focus:ring-[#1B5888]/20 focus:outline-none"
                />
              </div>
              <button
                type="button"
                onClick={handleVerifyDns}
                disabled={!agencyCustomDomain.trim() || dnsCheckLoading}
                className="inline-flex items-center justify-center gap-1.5 px-4 py-2.5 rounded-[10px] bg-[#1B5888] hover:bg-[#15466d] active:bg-[#12406A] disabled:opacity-50 disabled:cursor-not-allowed text-white text-xs font-bold transition-colors cursor-pointer shrink-0 shadow-xs"
              >
                <RefreshCw className={`w-3.5 h-3.5 ${dnsCheckLoading ? "animate-spin" : ""}`} />
                <span>
                  {dnsCheckLoading
                    ? t("agency_panel_dns_verifying")
                    : t("agency_panel_dns_verify_btn")}
                </span>
              </button>
            </div>
            <p className="text-[11px] text-[#666666]">
              {t("agency_panel_custom_domain_hint")}
            </p>

            {/* Live Test / DNS Check Result Box */}
            {dnsCheckResult && (
              <div
                className={`p-3.5 rounded-[10px] border text-xs flex items-start gap-2.5 ${dnsCheckResult.valid
                  ? "bg-[#E6F3EA] border-[#2A6E43]/20 text-[#2A6E43]"
                  : "bg-[#FBF1DC] border-[#8A5206]/20 text-[#8A5206]"
                  }`}
              >
                {dnsCheckResult.valid ? (
                  <CheckCircle2 className="w-4 h-4 text-[#2A6E43] shrink-0 mt-0.5" />
                ) : (
                  <AlertCircle className="w-4 h-4 text-[#8A5206] shrink-0 mt-0.5" />
                )}
                <div className="flex-1 space-y-1">
                  <p className="font-semibold">
                    {dnsCheckResult.valid
                      ? t("agency_panel_dns_msg_success")
                      : dnsCheckResult.reason === "invalid_domain"
                        ? t("agency_panel_dns_msg_invalid")
                        : dnsCheckResult.reason === "dns_error"
                          ? t("agency_panel_dns_msg_error")
                          : t("agency_panel_dns_msg_not_found")}
                  </p>
                  {dnsCheckResult.valid && (
                    <div className="pt-1 flex flex-wrap items-center gap-2">
                      <span className="font-mono text-[11px] bg-[#E6F3EA] text-emerald-900 px-2 py-0.5 rounded">
                        CNAME &rarr; {dnsCheckResult.expectedTarget || "cname.stanomer.online"}
                      </span>
                      <a
                        href={`https://${agencyCustomDomain}`}
                        target="_blank"
                        rel="noreferrer"
                        className="inline-flex items-center gap-1 text-[#2A6E43] hover:underline font-bold text-[11px]"
                      >
                        <span>https://{agencyCustomDomain}</span>
                        <ExternalLink className="w-3 h-3" />
                      </a>
                    </div>
                  )}
                </div>
              </div>
            )}
          </div>

          {/* DNS & CNAME Setup Guide Table */}
          <div className="rounded-[10px] border border-[#E5E3DF] bg-[#F8F7F5] p-4 space-y-4">
            <div className="flex items-center justify-between">
              <h4 className="text-xs font-bold text-[#1A1A1A] flex items-center gap-1.5">
                <Settings className="w-3.5 h-3.5 text-[#1B5888]" />
                <span>{t("agency_panel_cname_guide_title")}</span>
              </h4>
            </div>

            {/* Option 1: Subdomain or www (Recommended) */}
            <div className="bg-white rounded-lg border border-[#E5E3DF] p-3 space-y-2">
              <span className="text-xs font-bold text-[#4A4A4A] block">
                {t("agency_panel_cname_opt1_title")}
              </span>
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-2 text-xs">
                <div className="p-2 rounded bg-[#F8F7F5] border border-[#E5E3DF]/70">
                  <span className="text-[10px] text-[#666666] block font-semibold">
                    {t("agency_panel_cname_type")}
                  </span>
                  <span className="font-mono font-bold text-[#1A1A1A]">CNAME</span>
                </div>
                <div className="p-2 rounded bg-[#F8F7F5] border border-[#E5E3DF]/70 flex items-center justify-between">
                  <div>
                    <span className="text-[10px] text-[#666666] block font-semibold">
                      {t("agency_panel_cname_host")}
                    </span>
                    <span className="font-mono font-bold text-[#1A1A1A]">www</span>
                  </div>
                  <button
                    type="button"
                    onClick={() => copyToClipboard("www", "host_www")}
                    className="text-[10px] text-[#1B5888] hover:text-blue-800 font-semibold cursor-pointer px-1.5 py-0.5 rounded hover:bg-[#E5EEF6] transition-colors"
                  >
                    {copiedField === "host_www" ? (
                      <Check className="w-3 h-3 text-[#2A6E43]" />
                    ) : (
                      <Copy className="w-3 h-3" />
                    )}
                  </button>
                </div>
                <div className="p-2 rounded bg-[#F8F7F5] border border-[#E5E3DF]/70 flex items-center justify-between">
                  <div className="truncate pr-1">
                    <span className="text-[10px] text-[#666666] block font-semibold">
                      {t("agency_panel_cname_target")}
                    </span>
                    <span className="font-mono font-bold text-[#1A1A1A] truncate block">
                      cname.stanomer.online
                    </span>
                  </div>
                  <button
                    type="button"
                    onClick={() => copyToClipboard("cname.stanomer.online", "target_cname")}
                    className="text-[10px] text-[#1B5888] hover:text-blue-800 font-semibold cursor-pointer px-1.5 py-0.5 rounded hover:bg-[#E5EEF6] transition-colors shrink-0"
                  >
                    {copiedField === "target_cname" ? (
                      <Check className="w-3 h-3 text-[#2A6E43]" />
                    ) : (
                      <Copy className="w-3 h-3" />
                    )}
                  </button>
                </div>
              </div>
            </div>

            {/* Option 2: Root Domain Apex */}
            <div className="bg-white rounded-lg border border-[#E5E3DF] p-3 space-y-2">
              <span className="text-xs font-bold text-[#4A4A4A] block">
                {t("agency_panel_cname_opt2_title")}
              </span>
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-2 text-xs">
                <div className="p-2 rounded bg-[#F8F7F5] border border-[#E5E3DF]/70">
                  <span className="text-[10px] text-[#666666] block font-semibold">
                    {t("agency_panel_cname_type")}
                  </span>
                  <span className="font-mono font-bold text-[#1A1A1A]">A</span>
                </div>
                <div className="p-2 rounded bg-[#F8F7F5] border border-[#E5E3DF]/70 flex items-center justify-between">
                  <div>
                    <span className="text-[10px] text-[#666666] block font-semibold">
                      {t("agency_panel_cname_host")}
                    </span>
                    <span className="font-mono font-bold text-[#1A1A1A]">@</span>
                  </div>
                  <button
                    type="button"
                    onClick={() => copyToClipboard("@", "host_apex")}
                    className="text-[10px] text-[#1B5888] hover:text-blue-800 font-semibold cursor-pointer px-1.5 py-0.5 rounded hover:bg-[#E5EEF6] transition-colors"
                  >
                    {copiedField === "host_apex" ? (
                      <Check className="w-3 h-3 text-[#2A6E43]" />
                    ) : (
                      <Copy className="w-3 h-3" />
                    )}
                  </button>
                </div>
                <div className="p-2 rounded bg-[#F8F7F5] border border-[#E5E3DF]/70 flex items-center justify-between">
                  <div>
                    <span className="text-[10px] text-[#666666] block font-semibold">
                      {t("agency_panel_cname_target")}
                    </span>
                    <span className="font-mono font-bold text-[#1A1A1A]">76.76.21.21</span>
                  </div>
                  <button
                    type="button"
                    onClick={() => copyToClipboard("76.76.21.21", "target_ip")}
                    className="text-[10px] text-[#1B5888] hover:text-blue-800 font-semibold cursor-pointer px-1.5 py-0.5 rounded hover:bg-[#E5EEF6] transition-colors shrink-0"
                  >
                    {copiedField === "target_ip" ? (
                      <Check className="w-3 h-3 text-[#2A6E43]" />
                    ) : (
                      <Copy className="w-3 h-3" />
                    )}
                  </button>
                </div>
              </div>
            </div>

                    {/* SSL Note */}
                    <div className="flex items-center gap-2 text-[11px] text-[#666666] bg-[#E5EEF6]/60 border border-blue-100 p-2.5 rounded-lg">
                      <ShieldCheck className="w-4 h-4 text-[#1B5888] shrink-0" />
                      <span>{t("agency_panel_dns_ssl_note")}</span>
                    </div>
                  </div>
                </div>
              )}
            </section>

            {/* 2. Vitrin Web Sitesi Tasarımı */}
            <section
              aria-labelledby="agency-showcase-heading"
              className="bg-white rounded-[10px] border border-[#E5E3DF] p-5 sm:p-6 shadow-xs space-y-6"
            >
              <div className="border-b border-[#E5E3DF]/70 pb-3">
                <h3
                  id="agency-showcase-heading"
                  className="text-base font-bold text-[#1A1A1A] flex items-center gap-2"
                >
                  <Globe className="w-4 h-4 text-[#1B5888]" />
                  <span>{t("agency_panel_grp_showcase_title")}</span>
                </h3>
                <p className="text-xs text-[#666666] mt-0.5">
                  {t("agency_settings_subtab_website_desc")}
                </p>
              </div>

          {/* Template Selection */}
          <div>
            <span className="block text-xs font-bold text-[#1A1A1A] mb-2.5">
              {t("agency_panel_template_label")}
            </span>
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3.5">
              {/* Modern Corporate */}
              <button
                type="button"
                onClick={() => handleSelectTemplate("stanomer_modern")}
                className={`text-left p-3.5 rounded-[10px] border-2 transition-all cursor-pointer relative ${showcaseTemplate === "stanomer_modern"
                  ? "border-[#1B5888] bg-[#E5EEF6]/30 shadow-xs"
                  : "border-[#E5E3DF] hover:border-[#8A8A8A] bg-white"
                  }`}
              >
                <div className="h-16 rounded-lg bg-gradient-to-r from-slate-900 to-blue-950 p-2.5 mb-2.5 flex flex-col justify-between">
                  <div className="flex items-center justify-between">
                    <span className="w-12 h-2 rounded-full bg-blue-400/60" />
                    <span className="px-1.5 py-0.5 rounded bg-[#1B5888] text-[9px] font-bold text-white">
                      MODERN
                    </span>
                  </div>
                  <div className="grid grid-cols-3 gap-1.5">
                    <div className="h-5 rounded bg-white/90" />
                    <div className="h-5 rounded bg-white/90" />
                    <div className="h-5 rounded bg-white/90" />
                  </div>
                </div>
                <div className="flex items-center justify-between">
                  <p className="text-xs font-bold text-[#1A1A1A]">
                    {t("agency_panel_tpl_stanomer_title")}
                  </p>
                  {showcaseTemplate === "stanomer_modern" && (
                    <CheckCircle2 className="w-4 h-4 text-[#1B5888] shrink-0" />
                  )}
                </div>
                <p className="text-[11px] text-[#666666] mt-1 leading-snug">
                  {t("agency_panel_tpl_stanomer_desc")}
                </p>
              </button>

              {/* Quiet Luxury */}
              <button
                type="button"
                onClick={() => handleSelectTemplate("quiet_luxury")}
                className={`text-left p-3.5 rounded-[10px] border-2 transition-all cursor-pointer relative ${showcaseTemplate === "quiet_luxury"
                  ? "border-[#c8a97e] bg-[#090B0E]/5 shadow-xs"
                  : "border-[#E5E3DF] hover:border-[#8A8A8A] bg-white"
                  }`}
              >
                <div
                  className="h-16 rounded-lg p-2.5 mb-2.5 flex flex-col justify-between"
                  style={{
                    background:
                      "linear-gradient(135deg, #090B0E 0%, #003c52 100%)",
                  }}
                >
                  <div className="flex items-center justify-between">
                    <span
                      className="w-14 h-2 rounded-full"
                      style={{ backgroundColor: "#c8a97e" }}
                    />
                    <span
                      className="px-1.5 py-0.5 rounded text-[9px] font-bold"
                      style={{
                        backgroundColor: "#c8a97e",
                        color: "#090B0E",
                      }}
                    >
                      QUIET LUXURY
                    </span>
                  </div>
                  <div className="grid grid-cols-3 gap-1.5">
                    <div
                      className="h-5 rounded-xs"
                      style={{ backgroundColor: "#EAE6DF" }}
                    />
                    <div
                      className="h-5 rounded-xs"
                      style={{ backgroundColor: "#EAE6DF" }}
                    />
                    <div
                      className="h-5 rounded-xs"
                      style={{ backgroundColor: "#EAE6DF" }}
                    />
                  </div>
                </div>
                <div className="flex items-center justify-between">
                  <p className="text-xs font-bold text-[#1A1A1A]">
                    {t("agency_panel_tpl_luxury_title")}
                  </p>
                  {showcaseTemplate === "quiet_luxury" && (
                    <CheckCircle2 className="w-4 h-4 text-[#c8a97e] shrink-0" />
                  )}
                </div>
                <p className="text-[11px] text-[#666666] mt-1 leading-snug">
                  {t("agency_panel_tpl_luxury_desc")}
                </p>
              </button>

              {/* Nordic Minimalist */}
              <button
                type="button"
                onClick={() => handleSelectTemplate("minimal_light")}
                className={`text-left p-3.5 rounded-[10px] border-2 transition-all cursor-pointer relative ${showcaseTemplate === "minimal_light"
                  ? "border-[#1B5888] bg-[#E5EEF6]/40 shadow-xs"
                  : "border-[#E5E3DF] hover:border-[#8A8A8A] bg-white"
                  }`}
              >
                <div className="h-16 rounded-lg bg-stone-100 border border-stone-200 p-2.5 mb-2.5 flex flex-col justify-between">
                  <div className="flex items-center justify-between">
                    <span className="w-12 h-2 rounded-full bg-stone-800" />
                    <span className="px-1.5 py-0.5 rounded bg-stone-900 text-[9px] font-bold text-white">
                      EDITORIAL
                    </span>
                  </div>
                  <div className="grid grid-cols-3 gap-1.5">
                    <div className="h-5 rounded bg-white border border-stone-200" />
                    <div className="h-5 rounded bg-white border border-stone-200" />
                    <div className="h-5 rounded bg-white border border-stone-200" />
                  </div>
                </div>
                <div className="flex items-center justify-between">
                  <p className="text-xs font-bold text-[#1A1A1A]">
                    {t("agency_panel_tpl_minimal_title")}
                  </p>
                  {showcaseTemplate === "minimal_light" && (
                    <CheckCircle2 className="w-4 h-4 text-[#1A1A1A] shrink-0" />
                  )}
                </div>
                <p className="text-[11px] text-[#666666] mt-1 leading-snug">
                  {t("agency_panel_tpl_minimal_desc")}
                </p>
              </button>

              {/* Kolm (Dark Minimalist) */}
              <button
                type="button"
                onClick={() => handleSelectTemplate("kolm_dark")}
                className={`text-left p-3.5 rounded-[10px] border-2 transition-all cursor-pointer relative ${showcaseTemplate === "kolm_dark"
                  ? "border-[#5EF0B8] bg-[#212427]/5 shadow-xs"
                  : "border-[#E5E3DF] hover:border-[#8A8A8A] bg-white"
                  }`}
              >
                <div className="h-16 rounded-lg bg-[#212427] border border-[#3C434A] p-2.5 mb-2.5 flex flex-col justify-between">
                  <div className="flex items-center justify-between">
                    <span className="w-12 h-2 rounded-full bg-[#5EF0B8]" />
                    <span className="px-1.5 py-0.5 rounded bg-[#5EF0B8] text-[9px] font-bold text-[#111815]">
                      KOLM
                    </span>
                  </div>
                  <div className="grid grid-cols-3 gap-1.5">
                    <div className="h-5 rounded bg-[#2A2E32] border border-[#3C434A]" />
                    <div className="h-5 rounded bg-[#2A2E32] border border-[#3C434A]" />
                    <div className="h-5 rounded bg-[#2A2E32] border border-[#3C434A]" />
                  </div>
                </div>
                <div className="flex items-center justify-between">
                  <p className="text-xs font-bold text-[#1A1A1A]">
                    {t("agency_panel_tpl_kolm_title")}
                  </p>
                  {showcaseTemplate === "kolm_dark" && (
                    <CheckCircle2 className="w-4 h-4 text-[#5EF0B8] shrink-0" />
                  )}
                </div>
                <p className="text-[11px] text-[#666666] mt-1 leading-snug">
                  {t("agency_panel_tpl_kolm_desc")}
                </p>
              </button>

              {/* Lumira (Coastal Ocean) */}
              <button
                type="button"
                onClick={() => handleSelectTemplate("lumira")}
                className={`text-left p-3.5 rounded-[10px] border-2 transition-all cursor-pointer relative ${showcaseTemplate === "lumira"
                  ? "border-[#FF6B5A] bg-[#ECF3F8]/50 shadow-xs"
                  : "border-[#E5E3DF] hover:border-[#8A8A8A] bg-white"
                  }`}
              >
                <div className="h-16 rounded-lg bg-[#ECF3F8] border border-[#C5D6E2] p-2.5 mb-2.5 flex flex-col justify-between">
                  <div className="flex items-center justify-between">
                    <span className="w-12 h-2 rounded-full bg-[#164A6E]" />
                    <span className="px-1.5 py-0.5 rounded bg-[#FF6B5A] text-[9px] font-bold text-[#1A0B0A]">
                      LUMIRA
                    </span>
                  </div>
                  <div className="grid grid-cols-3 gap-1.5">
                    <div className="h-5 rounded bg-white border border-[#C5D6E2]" />
                    <div className="h-5 rounded bg-white border border-[#C5D6E2]" />
                    <div className="h-5 rounded bg-white border border-[#C5D6E2]" />
                  </div>
                </div>
                <div className="flex items-center justify-between">
                  <p className="text-xs font-bold text-[#1A1A1A]">
                    {t("agency_panel_tpl_lumira_title")}
                  </p>
                  {showcaseTemplate === "lumira" && (
                    <CheckCircle2 className="w-4 h-4 text-[#FF6B5A] shrink-0" />
                  )}
                </div>
                <p className="text-[11px] text-[#666666] mt-1 leading-snug">
                  {t("agency_panel_tpl_lumira_desc")}
                </p>
              </button>

              {/* Aldervik (Nordic Editorial) */}
              <button
                type="button"
                onClick={() => handleSelectTemplate("aldervik")}
                className={`text-left p-3.5 rounded-[10px] border-2 transition-all cursor-pointer relative ${showcaseTemplate === "aldervik"
                  ? "border-[#FFB020] bg-[#F3EFEA]/60 shadow-xs"
                  : "border-[#E5E3DF] hover:border-[#8A8A8A] bg-white"
                  }`}
              >
                <div className="h-16 rounded-lg bg-[#1C293D] p-2.5 mb-2.5 flex flex-col justify-between">
                  <div className="flex items-center justify-between">
                    <span className="w-12 h-2 rounded-full bg-[#DAD3CA]" />
                    <span className="px-1.5 py-0.5 rounded bg-[#FFB020] text-[9px] font-bold text-[#1C293D]">
                      ALDERVIK
                    </span>
                  </div>
                  <div className="grid grid-cols-3 gap-1.5">
                    <div className="h-5 rounded bg-[#F3EFEA] border border-[#DAD3CA]" />
                    <div className="h-5 rounded bg-[#F3EFEA] border border-[#DAD3CA]" />
                    <div className="h-5 rounded bg-[#F3EFEA] border border-[#DAD3CA]" />
                  </div>
                </div>
                <div className="flex items-center justify-between">
                  <p className="text-xs font-bold text-[#1A1A1A]">
                    {t("agency_panel_tpl_aldervik_title")}
                  </p>
                  {showcaseTemplate === "aldervik" && (
                    <CheckCircle2 className="w-4 h-4 text-[#FFB020] shrink-0" />
                  )}
                </div>
                <p className="text-[11px] text-[#666666] mt-1 leading-snug">
                  {t("agency_panel_tpl_aldervik_desc")}
                </p>
              </button>

              {/* Sage (Botanical Earth) */}
              <button
                type="button"
                onClick={() => handleSelectTemplate("sage")}
                className={`text-left p-3.5 rounded-[10px] border-2 transition-all cursor-pointer relative ${showcaseTemplate === "sage"
                  ? "border-[#24473A] bg-[#F6F4EE]/60 shadow-xs"
                  : "border-[#E5E3DF] hover:border-[#8A8A8A] bg-white"
                  }`}
              >
                <div className="h-16 rounded-lg bg-[#24473A] p-2.5 mb-2.5 flex flex-col justify-between">
                  <div className="flex items-center justify-between">
                    <span className="w-12 h-2 rounded-full bg-[#E6EDE8]" />
                    <span className="px-1.5 py-0.5 rounded bg-[#D9663B] text-[9px] font-bold text-[#1F0E07]">
                      SAGE
                    </span>
                  </div>
                  <div className="grid grid-cols-3 gap-1.5">
                    <div className="h-5 rounded-lg bg-white border border-[#DDD6C8]" />
                    <div className="h-5 rounded-lg bg-white border border-[#DDD6C8]" />
                    <div className="h-5 rounded-lg bg-white border border-[#DDD6C8]" />
                  </div>
                </div>
                <div className="flex items-center justify-between">
                  <p className="text-xs font-bold text-[#1A1A1A]">
                    {t("agency_panel_tpl_sage_title")}
                  </p>
                  {showcaseTemplate === "sage" && (
                    <CheckCircle2 className="w-4 h-4 text-[#24473A] shrink-0" />
                  )}
                </div>
                <p className="text-[11px] text-[#666666] mt-1 leading-snug">
                  {t("agency_panel_tpl_sage_desc")}
                </p>
              </button>

              {/* Onyx (Monolithic Noir Gold) */}
              <button
                type="button"
                onClick={() => handleSelectTemplate("onyx_dark")}
                className={`text-left p-3.5 rounded-[10px] border-2 transition-all cursor-pointer relative ${showcaseTemplate === "onyx_dark"
                  ? "border-[#D4B26A] bg-[#0F0F10]/5 shadow-xs"
                  : "border-[#E5E3DF] hover:border-[#8A8A8A] bg-white"
                  }`}
              >
                <div className="h-16 rounded-lg bg-[#0F0F10] border border-[#3A3A3E] p-2.5 mb-2.5 flex flex-col justify-between">
                  <div className="flex items-center justify-between">
                    <span className="w-14 h-2 rounded-full bg-[#D4B26A]" />
                    <span className="px-1.5 py-0.5 rounded bg-[#D4B26A] text-[9px] font-bold text-[#1A1405] tracking-wider">
                      ONYX
                    </span>
                  </div>
                  <div className="grid grid-cols-3 gap-1.5">
                    <div className="h-5 rounded-xs bg-[#2A2A2D] border border-[#3A3A3E]" />
                    <div className="h-5 rounded-xs bg-[#2A2A2D] border border-[#3A3A3E]" />
                    <div className="h-5 rounded-xs bg-[#2A2A2D] border border-[#3A3A3E]" />
                  </div>
                </div>
                <div className="flex items-center justify-between">
                  <p className="text-xs font-bold text-[#1A1A1A]">
                    {t("agency_panel_tpl_onyx_title")}
                  </p>
                  {showcaseTemplate === "onyx_dark" && (
                    <CheckCircle2 className="w-4 h-4 text-[#D4B26A] shrink-0" />
                  )}
                </div>
                <p className="text-[11px] text-[#666666] mt-1 leading-snug">
                  {t("agency_panel_tpl_onyx_desc")}
                </p>
              </button>
            </div>
          </div>

          {/* Brand Accent Palette */}
          <div>
            <span className="block text-xs font-bold text-[#1A1A1A] mb-2">
              {t("agency_panel_palette_label")}
            </span>
            <div className="flex flex-wrap gap-2.5">
              {[
                {
                  id: "royal_blue" as const,
                  label: t("agency_panel_pal_blue"),
                  swatch: "#2563eb",
                },
                {
                  id: "champagne_gold" as const,
                  label: t("agency_panel_pal_gold"),
                  swatch: "#c8a97e",
                },
                {
                  id: "emerald_prestige" as const,
                  label: t("agency_panel_pal_emerald"),
                  swatch: "#059669",
                },
                {
                  id: "burgundy_classic" as const,
                  label: t("agency_panel_pal_burgundy"),
                  swatch: "#be123c",
                },
                {
                  id: "kolm_mint" as const,
                  label: t("agency_panel_pal_mint"),
                  swatch: "#5EF0B8",
                },
                {
                  id: "lumira_coral" as const,
                  label: t("agency_panel_pal_coral"),
                  swatch: "#FF6B5A",
                },
                {
                  id: "aldervik_amber" as const,
                  label: t("agency_panel_pal_amber"),
                  swatch: "#FFB020",
                },
                {
                  id: "sage_terracotta" as const,
                  label: t("agency_panel_pal_terracotta"),
                  swatch: "#D9663B",
                },
                {
                  id: "onyx_brass" as const,
                  label: t("agency_panel_pal_brass"),
                  swatch: "#D4B26A",
                },
              ].map((pal) => (
                <button
                  key={pal.id}
                  type="button"
                  onClick={() => setShowcasePalette(pal.id)}
                  className={`inline-flex items-center gap-2 px-3 py-1.5 rounded-[10px] border text-xs font-semibold cursor-pointer transition-colors ${showcasePalette === pal.id
                    ? "border-[#1B5888] bg-[#1B5888] text-white shadow-xs"
                    : "border-[#E5E3DF] bg-white text-[#4A4A4A] hover:bg-[#F8F7F5]"
                    }`}
                >
                  <span
                    className="w-3.5 h-3.5 rounded-full border border-white/40 shrink-0"
                    style={{ backgroundColor: pal.swatch }}
                  />
                  <span>{pal.label}</span>
                </button>
              ))}
            </div>
          </div>

          {/* Corner Radius Selection */}
          <div>
            <span className="block text-xs font-bold text-[#1A1A1A] mb-2">
              {t("agency_panel_radius_label")}
            </span>
            <div className="flex flex-wrap gap-2.5">
              {[
                {
                  id: "sharp" as const,
                  label: t("agency_panel_radius_sharp"),
                  previewClass: "rounded-none",
                },
                {
                  id: "subtle" as const,
                  label: t("agency_panel_radius_subtle"),
                  previewClass: "rounded-xs",
                },
                {
                  id: "rounded" as const,
                  label: t("agency_panel_radius_rounded"),
                  previewClass: "rounded-lg",
                },
                {
                  id: "pill" as const,
                  label: t("agency_panel_radius_pill"),
                  previewClass: "rounded-full",
                },
              ].map((rad) => (
                <button
                  key={rad.id}
                  type="button"
                  onClick={() => setShowcaseRadius(rad.id)}
                  className={`inline-flex items-center gap-2 px-3 py-1.5 rounded-[10px] border text-xs font-semibold cursor-pointer transition-colors ${showcaseRadius === rad.id
                    ? "border-[#1B5888] bg-[#1B5888] text-white shadow-xs"
                    : "border-[#E5E3DF] bg-white text-[#4A4A4A] hover:bg-[#F8F7F5]"
                    }`}
                >
                  <span
                    className={`w-3.5 h-3.5 border-2 ${showcaseRadius === rad.id
                      ? "border-white bg-white/20"
                      : "border-slate-400 bg-slate-100"
                      } ${rad.previewClass}`}
                  />
                  <span>{rad.label}</span>
                </button>
              ))}
            </div>
          </div>

          {/* Showcase Languages */}
          <div>
            <div className="flex items-center gap-1.5 mb-1">
              <Languages className="w-3.5 h-3.5 text-[#1B5888]" />
              <span className="block text-xs font-bold text-[#1A1A1A]">
                {t("agency_panel_showcase_languages_label")}
              </span>
            </div>
            <p className="text-[11px] text-[#666666] mb-2.5">
              {t("agency_panel_showcase_languages_hint")}
            </p>
            <div className="flex flex-wrap gap-2">
              {[
                { id: "SR_LAT" as const, label: "SR (Latinica)" },
                { id: "SR_CYR" as const, label: "СР (Ћирилица)" },
                { id: "EN" as const, label: "EN (English)" },
                { id: "RU" as const, label: "RU (Русский)" },
                { id: "TR" as const, label: "TR (Türkçe)" },
              ].map((langItem) => {
                const isSelected = showcaseLanguages.includes(langItem.id);
                return (
                  <button
                    key={langItem.id}
                    type="button"
                    onClick={() => {
                      if (isSelected) {
                        if (showcaseLanguages.length > 1) {
                          setShowcaseLanguages(
                            showcaseLanguages.filter((l) => l !== langItem.id)
                          );
                        }
                      } else {
                        setShowcaseLanguages([...showcaseLanguages, langItem.id]);
                      }
                    }}
                    className={`inline-flex items-center gap-1.5 px-3 py-1.5 rounded-[10px] border text-xs font-semibold cursor-pointer transition-colors ${
                      isSelected
                        ? "border-[#1B5888] bg-[#E5EEF6] text-[#1B5888] shadow-xs"
                        : "border-[#E5E3DF] bg-white text-[#666666] hover:bg-[#F8F7F5]"
                    }`}
                  >
                    <CheckCircle2
                      className={`w-3.5 h-3.5 ${
                        isSelected ? "text-[#1B5888]" : "text-transparent"
                      }`}
                    />
                    <span>{langItem.label}</span>
                  </button>
                );
              })}
            </div>
          </div>

          {/* Showcase Currencies & Default Currency */}
          <div className="space-y-3.5">
            <div>
              <div className="flex items-center gap-1.5 mb-1">
                <Coins className="w-3.5 h-3.5 text-[#1B5888]" />
                <span className="block text-xs font-bold text-[#1A1A1A]">
                  {t("agency_panel_showcase_currencies_label")}
                </span>
              </div>
              <p className="text-[11px] text-[#666666] mb-2.5">
                {t("agency_panel_showcase_currencies_hint")}
              </p>
              <div className="flex flex-wrap gap-2">
                {[
                  { id: "EUR" as const, label: t("agency_panel_currency_eur") },
                  { id: "RSD" as const, label: t("agency_panel_currency_rsd") },
                  { id: "USD" as const, label: t("agency_panel_currency_usd") },
                ].map((curItem) => {
                  const isSelected = showcaseCurrencies.includes(curItem.id);
                  return (
                    <button
                      key={curItem.id}
                      type="button"
                      onClick={() => {
                        if (isSelected) {
                          if (showcaseCurrencies.length > 1) {
                            const remaining = showcaseCurrencies.filter(
                              (c) => c !== curItem.id
                            );
                            setShowcaseCurrencies(remaining);
                            if (showcaseDefaultCurrency === curItem.id) {
                              setShowcaseDefaultCurrency(remaining[0]);
                            }
                          }
                        } else {
                          setShowcaseCurrencies([
                            ...showcaseCurrencies,
                            curItem.id,
                          ]);
                        }
                      }}
                      className={`inline-flex items-center gap-1.5 px-3 py-1.5 rounded-[10px] border text-xs font-semibold cursor-pointer transition-colors ${
                        isSelected
                          ? "border-[#1B5888] bg-[#E5EEF6] text-[#1B5888] shadow-xs"
                          : "border-[#E5E3DF] bg-white text-[#666666] hover:bg-[#F8F7F5]"
                      }`}
                    >
                      <CheckCircle2
                        className={`w-3.5 h-3.5 ${
                          isSelected ? "text-[#1B5888]" : "text-transparent"
                        }`}
                      />
                      <span>{curItem.label}</span>
                    </button>
                  );
                })}
              </div>
            </div>

            {showcaseCurrencies.length > 1 && (
              <div className="bg-[#FAF9F5] p-3 rounded-lg border border-[#E5E3DF]">
                <span className="block text-xs font-semibold text-[#1A1A1A] mb-2">
                  {t("agency_panel_showcase_default_currency_label")}
                </span>
                <div className="flex flex-wrap gap-2">
                  {showcaseCurrencies.map((cur) => {
                    const label =
                      cur === "EUR"
                        ? t("agency_panel_currency_eur")
                        : cur === "RSD"
                        ? t("agency_panel_currency_rsd")
                        : t("agency_panel_currency_usd");
                    const isDefault = showcaseDefaultCurrency === cur;
                    return (
                      <button
                        key={cur}
                        type="button"
                        onClick={() => setShowcaseDefaultCurrency(cur)}
                        className={`px-3 py-1 rounded-[8px] text-xs font-semibold cursor-pointer transition-colors ${
                          isDefault
                            ? "bg-[#1B5888] text-white shadow-xs"
                            : "bg-white border border-[#E5E3DF] text-[#4A4A4A] hover:bg-[#F8F7F5]"
                        }`}
                      >
                        {label}
                      </button>
                    );
                  })}
                </div>
              </div>
            )}
          </div>
        </section>
      </div>
    )}

    {/* SAVE ACTION BAR */}
        <div className="flex items-center justify-end gap-3 pt-1">
          <button
            type="submit"
            disabled={savingProfile}
            className="w-full sm:w-auto inline-flex items-center justify-center gap-2 py-3 px-6 rounded-[10px] bg-[#1B5888] hover:bg-[#15466d] active:bg-[#12406A] disabled:opacity-60 text-white text-sm font-semibold cursor-pointer shadow-xs transition-colors"
          >
            {savingProfile ? (
              <>
                <RefreshCw className="w-4 h-4 animate-spin" />
                <span>{t("agency_panel_saving")}</span>
              </>
            ) : (
              <>
                <Check className="w-4 h-4" />
                <span>{t("agency_panel_save_all_settings")}</span>
              </>
            )}
          </button>
        </div>
      </form>
    </div>
  );
}
