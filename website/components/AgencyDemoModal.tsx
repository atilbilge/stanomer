"use client";

import React, { useState, useEffect } from "react";
import { createPortal } from "react-dom";
import Link from "next/link";
import { useLanguage } from "./LanguageProvider";
import {
  X,
  Check,
  ChevronRight,
  Info,
  ExternalLink,
  ShieldCheck,
  CheckCircle2,
  ArrowRight,
  Sparkles,
} from "lucide-react";
import { sendDemoVerification } from "../lib/agencyDemoClientService";

interface AgencyDemoModalProps {
  isOpen: boolean;
  onClose: () => void;
  defaultAgencyName?: string;
}

const SERBIAN_CITIES = [
  "Beograd",
  "Novi Sad",
  "Niš",
  "Kragujevac",
  "Subotica",
  "Pančevo",
  "Zrenjanin",
  "Čačak",
  "Kraljevo",
  "Novi Pazar",
  "Leskovac",
  "Smederevo",
  "Vranje",
  "Valjevo",
  "Kruševac",
  "Šabac",
  "Užice",
  "Sombor",
  "Požarevac",
  "Pirot",
  "Zaječar",
  "Kikinda",
  "Sremska Mitrovica",
  "Jagodina",
  "Vršac",
  "Bor",
  "Prokuplje",
  "Loznica",
  "Inđija",
  "Ruma",
  "Stara Pazova",
];

export function AgencyDemoModal({
  isOpen,
  onClose,
  defaultAgencyName = "",
}: AgencyDemoModalProps) {
  const { lang, t } = useLanguage();

  const [mounted, setMounted] = useState(false);
  const [agencyName, setAgencyName] = useState(defaultAgencyName);
  const [email, setEmail] = useState("");
  const [city, setCity] = useState("");
  const [phone, setPhone] = useState("");
  const [honeypot, setHoneypot] = useState("");

  // Module selections
  const [listingsSelected, setListingsSelected] = useState(true);
  const [rentalSelected, setRentalSelected] = useState(true);

  // Accordion state for "Peek at what you'll get"
  const [isPeekOpen, setIsPeekOpen] = useState(false);

  const [loading, setLoading] = useState(false);
  const [submitted, setSubmitted] = useState(false);
  const [createdToken, setCreatedToken] = useState<string | null>(null);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  useEffect(() => {
    setMounted(true);
  }, []);

  useEffect(() => {
    if (isOpen) {
      setSubmitted(false);
      setErrorMessage(null);
      setHoneypot("");
      setCreatedToken(null);
      if (defaultAgencyName && !agencyName) {
        setAgencyName(defaultAgencyName);
      }
    }
  }, [isOpen, defaultAgencyName]);

  // Lock body scroll when modal is open
  useEffect(() => {
    if (isOpen) {
      document.body.style.overflow = "hidden";
    } else {
      document.body.style.overflow = "";
    }
    return () => {
      document.body.style.overflow = "";
    };
  }, [isOpen]);

  if (!isOpen || !mounted) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMessage(null);

    if (!agencyName.trim() || !email.trim()) {
      setErrorMessage(t("agency_demo_err_agency_required"));
      return;
    }

    if (!listingsSelected && !rentalSelected) {
      setErrorMessage(t("agency_demo_err_min_module"));
      return;
    }

    // Bot honeypot check
    if (honeypot.trim() !== "") {
      setSubmitted(true);
      return;
    }

    setLoading(true);

    try {
      const moduleKeys: string[] = [];
      if (listingsSelected) moduleKeys.push("portfolio_distribution");
      if (rentalSelected) moduleKeys.push("property_lease_management");

      const derivedFocus: "presales" | "aftersales" | "both" =
        listingsSelected && rentalSelected
          ? "both"
          : listingsSelected
          ? "presales"
          : "aftersales";

      const res = await sendDemoVerification({
        email: email.toLowerCase().trim(),
        agencyName: agencyName.trim(),
        city: city || null,
        phone: phone.trim() || null,
        selectedModules: moduleKeys,
        focus: derivedFocus,
        lang: lang || "TR",
        honeypot: honeypot.trim(),
      });

      if (res.token) {
        setCreatedToken(res.token);
      }

      if (typeof window !== "undefined") {
        try {
          localStorage.setItem(
            "stanomer_agency_demo",
            JSON.stringify({
              token: res.token || "demo-session",
              isVerified: false,
              agencyName: agencyName.trim(),
              email: email.toLowerCase().trim(),
              phone: phone.trim() || null,
              city: city || "Beograd",
              focus: derivedFocus,
              active_modules: moduleKeys,
              expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
              locale: lang || "SR_LAT",
            })
          );
        } catch (_) {}
      }

      setSubmitted(true);
    } catch (err: any) {
      console.error("[AgencyDemoModal Error]", err);
      setErrorMessage(err.message || t("agency_demo_error_msg"));
    } finally {
      setLoading(false);
    }
  };

  const directVerifyUrl = createdToken
    ? `/agency-demo/verify?token=${encodeURIComponent(createdToken)}&lang=${encodeURIComponent(lang || "TR")}`
    : null;

  return createPortal(
    <div className="fixed inset-0 z-[999999] flex items-center justify-center p-3 sm:p-4 md:p-6 bg-slate-900/60 backdrop-blur-sm animate-in fade-in duration-200">
      {/* Backdrop click dismiss */}
      <div className="fixed inset-0 -z-10" onClick={onClose} aria-hidden="true" />

      {/* Modal Card */}
      <div className="relative w-full max-w-xl md:max-w-2xl bg-white rounded-[18px] sm:rounded-[20px] shadow-[0_24px_64px_rgba(0,0,0,0.18)] border border-[#E5E3DF] flex flex-col max-h-[92vh] overflow-hidden text-left">
        {/* Top Dismiss Button */}
        <button
          onClick={onClose}
          type="button"
          className="absolute top-4 right-4 sm:top-5 sm:right-5 w-8 h-8 rounded-full bg-slate-100 hover:bg-slate-200 active:bg-slate-300 text-slate-500 hover:text-slate-800 transition flex items-center justify-center cursor-pointer z-30"
          aria-label="Close"
        >
          <X className="w-4 h-4" />
        </button>

        {submitted ? (
          /* Success Screen */
          <div className="p-6 sm:p-10 text-center space-y-5 my-auto overflow-y-auto">
            <div className="w-16 h-16 rounded-full bg-[#EAF5EE] text-[#2A6E43] flex items-center justify-center mx-auto">
              <CheckCircle2 className="w-9 h-9" />
            </div>
            <h3 className="text-xl sm:text-2xl font-bold text-[#1A1A1A] tracking-tight">
              {t("agency_demo_success_title")}
            </h3>
            <p className="text-sm text-[#4A4A4A] leading-relaxed max-w-md mx-auto">
              <strong className="text-[#1A1A1A]">{email}</strong> {t("agency_demo_success_desc")}
            </p>

            <div className="pt-3 flex flex-col sm:flex-row items-center justify-center gap-3">
              <button
                type="button"
                onClick={onClose}
                className="w-full sm:w-auto px-6 py-3 rounded-[10px] bg-[#1B5888] hover:bg-[#12406A] active:bg-[#12406A] text-white font-bold text-sm transition cursor-pointer shadow-sm"
              >
                {t("agency_demo_back_home")}
              </button>
            </div>
          </div>
        ) : (
          /* Form Content: Scrollable Body + Sticky CTA */
          <form onSubmit={handleSubmit} className="flex flex-col flex-1 min-h-0">
            {/* Scrollable Body */}
            <div className="flex-1 overflow-y-auto p-5 sm:p-7 space-y-5 sm:space-y-6 overscroll-contain">
              {/* Header: Pills + Title + Subtitle */}
              <div className="space-y-3">
                {/* Clean Badges (Zero Emojis!) */}
                <div className="flex flex-wrap items-center gap-2 pr-8">
                  <span className="inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold bg-[#EAF5EE] text-[#2A6E43] border border-[#2A6E43]/20">
                    {t("agency_demo_badge")}
                  </span>
                  <span className="inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold bg-[#EAF5EE] text-[#2A6E43] border border-[#2A6E43]/20">
                    {t("agency_demo_trust_speed")}
                  </span>
                  <span className="inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold bg-[#EAF5EE] text-[#2A6E43] border border-[#2A6E43]/20">
                    {t("agency_demo_trust_card")}
                  </span>
                </div>

                <h3 className="text-xl sm:text-2xl md:text-[26px] font-bold text-[#1A1A1A] tracking-tight leading-tight">
                  {t("agency_demo_title")}
                </h3>
                <p className="text-xs sm:text-sm text-[#666666] leading-relaxed">
                  {t("agency_demo_subtitle")}
                </p>
              </div>

              {/* Error Message */}
              {errorMessage && (
                <div className="p-3.5 rounded-[10px] bg-[#FBEAE6] border border-[#B5432E]/30 text-[#A33C29] text-xs font-semibold">
                  {errorMessage}
                </div>
              )}

              {/* Form Fields: 2-Column Grid */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                {/* Agency Name */}
                <div>
                  <label className="block text-xs font-bold text-[#1A1A1A] mb-1.5">
                    {t("agency_demo_label_agency")}{" "}
                    <span className="text-[#C53030]">*</span>
                  </label>
                  <input
                    type="text"
                    required
                    value={agencyName}
                    onChange={(e) => setAgencyName(e.target.value)}
                    placeholder={t("agency_demo_ph_agency")}
                    className="w-full h-[46px] px-3.5 rounded-[10px] border border-[#D1CFCA] focus:border-[#1B5888] focus:ring-2 focus:ring-[#1B5888]/20 text-sm font-medium text-[#1A1A1A] placeholder:text-[#999999] outline-none transition bg-white"
                  />
                </div>

                {/* Email */}
                <div>
                  <label className="block text-xs font-bold text-[#1A1A1A] mb-1.5">
                    {t("agency_demo_label_email")}{" "}
                    <span className="text-[#C53030]">*</span>
                  </label>
                  <input
                    type="email"
                    required
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder={t("agency_demo_ph_email")}
                    className="w-full h-[46px] px-3.5 rounded-[10px] border border-[#D1CFCA] focus:border-[#1B5888] focus:ring-2 focus:ring-[#1B5888]/20 text-sm font-medium text-[#1A1A1A] placeholder:text-[#999999] outline-none transition bg-white"
                  />
                </div>

                {/* City */}
                <div>
                  <label className="block text-xs font-bold text-[#1A1A1A] mb-1.5">
                    {t("agency_demo_label_city")}
                  </label>
                  <div className="relative">
                    <select
                      value={city}
                      onChange={(e) => setCity(e.target.value)}
                      className="w-full h-[46px] px-3.5 pr-8 rounded-[10px] border border-[#D1CFCA] focus:border-[#1B5888] focus:ring-2 focus:ring-[#1B5888]/20 text-sm font-medium text-[#1A1A1A] outline-none transition bg-white cursor-pointer appearance-none"
                    >
                      <option value="">{t("agency_demo_select_city")}</option>
                      {SERBIAN_CITIES.map((c) => (
                        <option key={c} value={c}>
                          {c}
                        </option>
                      ))}
                      <option value="Other">{t("ref_city_other")}</option>
                    </select>
                    <div className="pointer-events-none absolute inset-y-0 right-0 flex items-center px-3 text-slate-500">
                      <ChevronRight className="w-4 h-4 rotate-90" />
                    </div>
                  </div>
                </div>

                {/* Phone */}
                <div>
                  <label className="block text-xs font-bold text-[#1A1A1A] mb-1.5">
                    {t("agency_demo_label_phone")}
                  </label>
                  <input
                    type="tel"
                    value={phone}
                    onChange={(e) => setPhone(e.target.value)}
                    placeholder={t("agency_demo_ph_phone")}
                    className="w-full h-[46px] px-3.5 rounded-[10px] border border-[#D1CFCA] focus:border-[#1B5888] focus:ring-2 focus:ring-[#1B5888]/20 text-sm font-medium text-[#1A1A1A] placeholder:text-[#999999] outline-none transition bg-white"
                  />
                </div>
              </div>

              {/* Invisible Honeypot Anti-Bot Field */}
              <div
                className="absolute opacity-0 -z-50 pointer-events-none h-0 w-0 overflow-hidden"
                aria-hidden="true"
              >
                <label htmlFor="agency_contact_code">Do not fill this</label>
                <input
                  type="text"
                  id="agency_contact_code"
                  name="agency_contact_code"
                  tabIndex={-1}
                  autoComplete="off"
                  value={honeypot}
                  onChange={(e) => setHoneypot(e.target.value)}
                />
              </div>

              {/* Module Selection: "What would you like to try?" */}
              <div className="space-y-2.5">
                <div className="flex items-center justify-between">
                  <span className="text-xs sm:text-sm font-bold text-[#1A1A1A]">
                    {t("agency_demo_section_modules")}
                  </span>
                  <span className="text-[11px] sm:text-xs text-[#777777]">
                    {t("agency_demo_pick_both")}
                  </span>
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3.5">
                  {/* Card 1: Listings, Showcase Website & Portals */}
                  <div
                    onClick={() => setListingsSelected(!listingsSelected)}
                    role="button"
                    tabIndex={0}
                    className={`rounded-[14px] p-4 text-left transition cursor-pointer flex flex-col justify-between border-2 ${
                      listingsSelected
                        ? "border-[#1B5888] bg-[#F4F8FB] shadow-xs"
                        : "border-[#E5E3DF] bg-white hover:border-[#D1CFCA]"
                    }`}
                  >
                    <div>
                      <div className="flex items-start gap-2.5">
                        <div
                          className={`w-5 h-5 rounded-[5px] flex items-center justify-center shrink-0 mt-0.5 transition ${
                            listingsSelected
                              ? "bg-[#1B5888] text-white"
                              : "border-2 border-[#CCCCCC] bg-white"
                          }`}
                        >
                          {listingsSelected && (
                            <Check className="w-3.5 h-3.5 stroke-[2.5]" />
                          )}
                        </div>
                        <div>
                          <h4 className="text-sm font-bold text-[#1A1A1A] leading-snug">
                            {t("agency_demo_module_listings_title")}
                          </h4>
                          <span className="text-[11px] font-semibold text-[#1B5888] block mt-0.5">
                            {t("agency_demo_module_listings_subtitle")}
                          </span>
                        </div>
                      </div>
                      <p className="text-xs text-[#555555] leading-relaxed mt-2 pl-7.5">
                        {t("agency_demo_module_listings_desc")}
                      </p>
                    </div>

                    <div className="flex flex-wrap gap-1.5 mt-3 pt-2 border-t border-[#E5E3DF]/60">
                      <span className="px-2 py-0.5 rounded-[6px] text-[11px] font-semibold bg-white border border-[#D5D3CE] text-[#333333]">
                        {t("agency_demo_pill_portals")}
                      </span>
                      <span className="px-2 py-0.5 rounded-[6px] text-[11px] font-semibold bg-white border border-[#D5D3CE] text-[#333333]">
                        {t("agency_demo_pill_showcase")}
                      </span>
                      <span className="px-2 py-0.5 rounded-[6px] text-[11px] font-semibold bg-white border border-[#D5D3CE] text-[#333333]">
                        {t("agency_demo_pill_leads")}
                      </span>
                      <span className="px-2 py-0.5 rounded-[6px] text-[11px] font-semibold bg-white border border-[#D5D3CE] text-[#333333]">
                        {t("agency_demo_pill_single_entry")}
                      </span>
                    </div>
                  </div>

                  {/* Card 2: Rental & Property Management */}
                  <div
                    onClick={() => setRentalSelected(!rentalSelected)}
                    role="button"
                    tabIndex={0}
                    className={`rounded-[14px] p-4 text-left transition cursor-pointer flex flex-col justify-between border-2 ${
                      rentalSelected
                        ? "border-[#1B5888] bg-[#F4F8FB] shadow-xs"
                        : "border-[#E5E3DF] bg-white hover:border-[#D1CFCA]"
                    }`}
                  >
                    <div>
                      <div className="flex items-start gap-2.5">
                        <div
                          className={`w-5 h-5 rounded-[5px] flex items-center justify-center shrink-0 mt-0.5 transition ${
                            rentalSelected
                              ? "bg-[#1B5888] text-white"
                              : "border-2 border-[#CCCCCC] bg-white"
                          }`}
                        >
                          {rentalSelected && (
                            <Check className="w-3.5 h-3.5 stroke-[2.5]" />
                          )}
                        </div>
                        <div>
                          <h4 className="text-sm font-bold text-[#1A1A1A] leading-snug">
                            {t("agency_demo_module_rental_title")}
                          </h4>
                          <span className="text-[11px] font-semibold text-[#2A6E43] block mt-0.5">
                            {t("agency_demo_module_rental_subtitle")}
                          </span>
                        </div>
                      </div>
                      <p className="text-xs text-[#555555] leading-relaxed mt-2 pl-7.5">
                        {t("agency_demo_module_rental_desc")}
                      </p>
                    </div>

                    <div className="flex flex-wrap gap-1.5 mt-3 pt-2 border-t border-[#E5E3DF]/60">
                      <span className="px-2 py-0.5 rounded-[6px] text-[11px] font-semibold bg-white border border-[#D5D3CE] text-[#333333]">
                        {t("agency_demo_pill_rent_tracking")}
                      </span>
                      <span className="px-2 py-0.5 rounded-[6px] text-[11px] font-semibold bg-white border border-[#D5D3CE] text-[#333333]">
                        {t("agency_demo_pill_infostan")}
                      </span>
                      <span className="px-2 py-0.5 rounded-[6px] text-[11px] font-semibold bg-white border border-[#D5D3CE] text-[#333333]">
                        {t("agency_demo_pill_ledger")}
                      </span>
                    </div>
                  </div>
                </div>
              </div>

              {/* Accordion / Peek at What You'll Get */}
              <div className="space-y-3 pt-1">
                <button
                  type="button"
                  onClick={() => setIsPeekOpen(!isPeekOpen)}
                  className="w-full p-3 rounded-[12px] bg-[#F7F5F0] hover:bg-[#EFECE6] border border-[#E5E3DF] flex items-center justify-between text-left transition cursor-pointer group"
                >
                  <div className="flex items-center gap-2">
                    <ChevronRight
                      className="w-4 h-4 text-[#1B5888] transition-transform duration-200"
                      style={{
                        transform: isPeekOpen ? "rotate(90deg)" : "rotate(0deg)",
                      }}
                    />
                    <span className="text-xs sm:text-sm font-bold text-[#1A1A1A] group-hover:text-[#1B5888] transition-colors">
                      {t("agency_demo_peek_title")}
                    </span>
                  </div>
                  <span className="text-[11px] text-[#666666] font-medium hidden sm:inline">
                    {listingsSelected && rentalSelected
                      ? t("agency_demo_pick_both")
                      : listingsSelected
                      ? t("agency_demo_module_listings_title")
                      : rentalSelected
                      ? t("agency_demo_module_rental_title")
                      : ""}
                  </span>
                </button>

                {/* Expanded Peek Content */}
                {isPeekOpen && (
                  <div className="p-4 rounded-[14px] bg-[#F9F8F6] border border-[#E5E3DF] space-y-4 animate-in fade-in duration-200">
                    {/* CRITICAL TRUST REQUIREMENT: Transparent Portal Simulation Notice */}
                    {listingsSelected && (
                      <div className="p-3.5 rounded-[10px] bg-[#FEF6E7] border border-[#F3D79B] text-[#7A4D05] text-xs leading-relaxed flex items-start gap-2.5">
                        <Info className="w-4 h-4 text-[#D97706] shrink-0 mt-0.5" />
                        <div className="space-y-1">
                          <span className="font-bold block text-[#B45309]">
                            {t("agency_demo_sim_notice_title")}
                          </span>
                          <p>{t("agency_demo_portal_simulated_notice")}</p>
                        </div>
                      </div>
                    )}

                    {/* Listings Preview */}
                    {listingsSelected && (
                      <div className="rounded-[12px] bg-white border border-[#E5E3DF] p-3.5 space-y-3">
                        <div className="flex items-center justify-between border-b border-[#E5E3DF] pb-2 text-xs">
                          <span className="font-bold text-[#1A1A1A] flex items-center gap-1.5">
                            <Sparkles className="w-3.5 h-3.5 text-[#1B5888]" />
                            {t("agency_demo_module_listings_title")}
                          </span>
                          <span className="text-[11px] text-[#888888] font-mono">
                            {t("agency_demo_mock_showcase_url")}
                          </span>
                        </div>

                        <div className="flex items-center justify-between bg-[#F7F5F0] rounded-[8px] p-2.5 text-xs">
                          <div className="space-y-0.5">
                            <div className="flex items-center gap-2">
                              <span className="font-bold text-[#1B5888] text-[10px] px-1.5 py-0.5 bg-[#E6F0F7] rounded">
                                {t("agency_demo_mock_listing_tag")}
                              </span>
                              <span className="font-semibold text-[#1A1A1A]">
                                Beograd, Vračar • 68 m²
                              </span>
                            </div>
                            <span className="text-[11px] text-[#666666] font-semibold">
                              {t("agency_demo_mock_listing_price")}
                            </span>
                          </div>
                          <span className="px-2 py-0.5 rounded text-[10px] font-bold bg-[#E6F3EA] text-[#2A6E43] border border-[#2A6E43]/20">
                            {t("agency_demo_mock_sync_single")}
                          </span>
                        </div>

                        {/* Portal Distribution Rows with Simulation Badges */}
                        <div className="grid grid-cols-2 gap-2 pt-1 text-[11px]">
                          <div className="p-2 rounded-[8px] bg-white border border-[#E5E3DF] flex items-center justify-between">
                            <span className="font-bold text-[#1A1A1A]">4zida.rs</span>
                            <span className="text-[10px] font-semibold text-[#B45309] bg-[#FEF6E7] px-1.5 py-0.5 rounded border border-[#F3D79B]">
                              {t("agency_demo_mock_simulation_badge")}
                            </span>
                          </div>
                          <div className="p-2 rounded-[8px] bg-white border border-[#E5E3DF] flex items-center justify-between">
                            <span className="font-bold text-[#1A1A1A]">Halo Oglasi</span>
                            <span className="text-[10px] font-semibold text-[#B45309] bg-[#FEF6E7] px-1.5 py-0.5 rounded border border-[#F3D79B]">
                              {t("agency_demo_mock_simulation_badge")}
                            </span>
                          </div>
                        </div>
                      </div>
                    )}

                    {/* Rental Management Preview */}
                    {rentalSelected && (
                      <div className="rounded-[12px] bg-white border border-[#E5E3DF] p-3.5 space-y-2.5">
                        <div className="flex items-center justify-between border-b border-[#E5E3DF] pb-2 text-xs">
                          <span className="font-bold text-[#1A1A1A] flex items-center gap-1.5">
                            <ShieldCheck className="w-3.5 h-3.5 text-[#2A6E43]" />
                            {t("agency_demo_module_rental_title")}
                          </span>
                          <span className="text-[11px] text-[#2A6E43] font-semibold">
                            {t("agency_demo_pill_ledger")}
                          </span>
                        </div>

                        <div className="space-y-1.5 text-xs">
                          <div className="flex items-center justify-between p-2 rounded-[6px] bg-[#F7F5F0]">
                            <span className="text-[#4A4A4A] font-medium">
                              {t("agency_demo_mock_rent_label")}
                            </span>
                            <span className="font-bold text-[#2A6E43] px-2 py-0.5 bg-[#E6F3EA] rounded text-[11px]">
                              {t("agency_demo_mock_rent_paid")}
                            </span>
                          </div>
                          <div className="flex items-center justify-between p-2 rounded-[6px] bg-[#F7F5F0]">
                            <span className="text-[#4A4A4A] font-medium">
                              {t("agency_demo_mock_bill_label")}
                            </span>
                            <span className="font-semibold text-[#1A1A1A] text-[11px]">
                              {t("agency_demo_mock_bill_status")}
                            </span>
                          </div>
                          <div className="flex items-center justify-between p-2 rounded-[6px] bg-[#F7F5F0]">
                            <span className="text-[#4A4A4A] font-medium">
                              {t("agency_demo_mock_contract_label")}
                            </span>
                            <span className="font-bold text-[#B45309] px-2 py-0.5 bg-[#FEF6E7] rounded text-[11px]">
                              {t("agency_demo_mock_contract_status")}
                            </span>
                          </div>
                        </div>
                      </div>
                    )}

                    {!listingsSelected && !rentalSelected && (
                      <p className="text-xs text-[#C53030] text-center font-semibold py-2">
                        {t("agency_demo_err_min_module")}
                      </p>
                    )}
                  </div>
                )}
              </div>
            </div>

            {/* Sticky Bottom CTA: Always visible without scrolling! */}
            <div className="sticky bottom-0 bg-white/95 backdrop-blur-md border-t border-[#E5E3DF] p-4 sm:p-5 z-20 space-y-2.5">
              <button
                type="submit"
                disabled={loading || (!listingsSelected && !rentalSelected)}
                className="w-full py-3.5 px-6 rounded-[10px] bg-[#1B5888] hover:bg-[#12406A] active:bg-[#12406A] text-white font-bold text-sm sm:text-base shadow-[0_1px_2px_rgba(0,0,0,0.06),0_4px_12px_rgba(27,88,136,0.18)] flex items-center justify-center gap-2 transition disabled:opacity-40 cursor-pointer min-h-[48px]"
              >
                {loading ? (
                  <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin" />
                ) : (
                  <span>{t("agency_demo_open_panel")}</span>
                )}
              </button>

              <p className="text-xs text-center text-[#666666] leading-normal">
                {t("agency_demo_terms_agreement_prefix")}{" "}
                <Link
                  href="/terms"
                  target="_blank"
                  className="underline hover:text-[#1B5888] transition font-medium"
                >
                  {t("terms_title")}
                </Link>{" "}
                {t("agency_demo_and")}{" "}
                <Link
                  href="/privacy"
                  target="_blank"
                  className="underline hover:text-[#1B5888] transition font-medium"
                >
                  {t("agency_demo_privacy_link")}
                </Link>
                .
              </p>
            </div>
          </form>
        )}
      </div>
    </div>,
    document.body
  );
}
