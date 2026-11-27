"use client";

import React, { useState, useEffect, useRef } from "react";
import Link from "next/link";
import { useLanguage } from "../components/LanguageProvider";
import {
  ArrowRight,
  Building2,
  Calculator,
  Check,
  CheckCircle2,
  CheckSquare,
  ChevronDown,
  FileText,
  Globe,
  Home,
  MessageCircle,
  Play,
  ShieldCheck,
  Smartphone,
  Wallet,
  Wrench,
} from "lucide-react";

type ApartmentStep = "listing" | "lease" | "ledger";

export function HomeContent() {
  const { t } = useLanguage();
  const [step, setStep] = useState<ApartmentStep>("ledger");
  const [openFaq, setOpenFaq] = useState<number | null>(0);
  const heroDemoBtnRef = useRef<HTMLAnchorElement | null>(null);
  const closingDemoBtnRef = useRef<HTMLAnchorElement | null>(null);

  useEffect(() => {
    let idleTimer: ReturnType<typeof setTimeout> | null = null;
    const handleMouseMove = (e: MouseEvent) => {
      const vw = Math.max(1, window.innerWidth);
      const vh = Math.max(1, window.innerHeight);
      const pctX = Math.max(0, Math.min(100, (e.clientX / vw) * 100));
      const pctY = Math.max(0, Math.min(100, (e.clientY / vh) * 100));
      [heroDemoBtnRef.current, closingDemoBtnRef.current].forEach((btn) => {
        if (!btn) return;
        btn.style.setProperty("--demo-mx", `${pctX.toFixed(1)}%`);
        btn.style.setProperty("--demo-my", `${pctY.toFixed(1)}%`);
        btn.style.setProperty("--demo-mx-pct", `${pctX.toFixed(1)}%`);
        btn.style.setProperty("--demo-glow", "1");
      });
      if (idleTimer) clearTimeout(idleTimer);
      idleTimer = setTimeout(() => {
        [heroDemoBtnRef.current, closingDemoBtnRef.current].forEach((btn) => {
          if (btn) btn.style.setProperty("--demo-glow", "0.25");
        });
      }, 450);
    };
    window.addEventListener("mousemove", handleMouseMove, { passive: true });
    return () => {
      window.removeEventListener("mousemove", handleMouseMove);
      if (idleTimer) clearTimeout(idleTimer);
    };
  }, []);

  const steps: { id: ApartmentStep; label: string }[] = [
    { id: "listing", label: t("lp_card_step1") },
    { id: "lease", label: t("lp_card_step2") },
    { id: "ledger", label: t("lp_card_step3") },
  ];

  const faqs = [
    { q: t("lp_faq_q1"), a: t("lp_faq_a1") },
    { q: t("lp_faq_q2"), a: t("lp_faq_a2") },
    { q: t("lp_faq_q3"), a: t("lp_faq_a3") },
    { q: t("lp_faq_q4"), a: t("lp_faq_a4") },
  ];

  return (
    <div className="min-h-screen flex flex-col font-sans bg-[#F8F7F5] text-[#1A1A1A] overflow-x-hidden">
      {/* ===================================================================== */}
      {/* SECTION 1: EDITORIAL HERO + INTERACTIVE LIVE APARTMENT CARD           */}
      {/* ===================================================================== */}
      <section className="pt-12 pb-16 lg:pt-20 lg:pb-24 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto w-full">
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-10 lg:gap-12 items-center">
          {/* Left Copy & CTAs */}
          <div className="lg:col-span-6 space-y-6">
            <h1 className="font-[family-name:var(--font-outfit)] text-3xl sm:text-4xl lg:text-5xl font-bold text-[#1A1A1A] tracking-tight leading-[1.12]">
              {t("lp_hero_title")}
            </h1>

            <p className="text-base sm:text-lg text-slate-600 leading-relaxed max-w-2xl">
              {t("lp_hero_desc")}
            </p>

            <div className="flex flex-wrap items-center gap-3 pt-1">
              <Link
                ref={heroDemoBtnRef}
                href="/agency-panel?launch_demo=1"
                className="st-demo-glow-btn inline-flex items-center justify-center gap-2 px-6 py-3.5 rounded-[10px] border border-[#1B5888]/45 text-[#12406A] font-bold text-sm cursor-pointer"
              >
                <Play className="w-4 h-4 text-[#1B5888] fill-[#1B5888]" />
                <span>{t("lp_hero_cta_demo")}</span>
                <ArrowRight className="w-4 h-4 text-[#1B5888]" />
              </Link>

              <Link
                href="/agency-panel"
                className="st-btn-primary px-6 py-3.5 text-sm gap-2"
              >
                <span>{t("lp_hero_cta_login")}</span>
                <ArrowRight className="w-4 h-4" />
              </Link>
            </div>

            <p className="text-xs text-[#666666] font-medium pt-1">
              {t("lp_hero_note")}
            </p>
          </div>

          {/* Right Interactive Live Apartment Ledger Card */}
          <div className="lg:col-span-6">
            <div className="rounded-[12px] bg-white border border-[#E5E3DF] shadow-[0_8px_28px_rgba(18,64,106,0.06)] overflow-hidden">
              {/* Apartment Header */}
              <div className="px-5 py-4 border-b border-[#E5E3DF] flex items-center justify-between gap-3 bg-[#F8F7F5]/60">
                <div className="min-w-0">
                  <div className="flex items-center gap-2">
                    <Building2 className="w-4 h-4 text-[#1B5888] shrink-0" />
                    <span className="font-[family-name:var(--font-outfit)] font-bold text-sm sm:text-base text-[#1A1A1A] truncate">
                      Njegoševa 24, Novi Sad
                    </span>
                  </div>
                  <p className="font-mono text-xs text-[#666666] mt-0.5">
                    2.0 · 54 m² · 3F
                  </p>
                </div>
                <span className="font-mono text-sm font-bold text-[#1B5888] bg-[#E5EEF6] px-2.5 py-1 rounded-[6px] shrink-0">
                  €650/mo
                </span>
              </div>

              {/* 3 Interactive Lifecycle Step Tabs */}
              <div className="grid grid-cols-3 border-b border-[#E5E3DF] bg-white">
                {steps.map((s) => {
                  const active = step === s.id;
                  return (
                    <button
                      key={s.id}
                      type="button"
                      onClick={() => setStep(s.id)}
                      className={`py-3 px-2 sm:px-3 text-xs font-bold transition-colors cursor-pointer border-b-2 text-center truncate ${active
                          ? "border-[#1B5888] text-[#1B5888] bg-[#E5EEF6]/35"
                          : "border-transparent text-[#666666] hover:text-[#1A1A1A] hover:bg-[#F8F7F5]"
                        }`}
                    >
                      {s.label}
                    </button>
                  );
                })}
              </div>

              {/* Structured Ledger Rows (changes by active step) */}
              <div className="divide-y divide-[#E5E3DF] text-xs sm:text-sm">
                {step === "listing" && (
                  <>
                    <div className="px-5 py-3.5 flex items-center justify-between gap-3">
                      <span className="font-semibold text-[#1A1A1A]">4zida.rs</span>
                      <span className="inline-flex items-center gap-1.5 font-mono text-xs font-semibold text-[#2A6E43] bg-[#E6F3EA] px-2.5 py-1 rounded-[6px]">
                        <Check className="w-3.5 h-3.5" />
                        {t("lp_card_xml_synced")}
                      </span>
                    </div>
                    <div className="px-5 py-3.5 flex items-center justify-between gap-3">
                      <span className="font-semibold text-[#1A1A1A]">Halo Oglasi</span>
                      <span className="inline-flex items-center gap-1.5 font-mono text-xs font-semibold text-[#2A6E43] bg-[#E6F3EA] px-2.5 py-1 rounded-[6px]">
                        <Check className="w-3.5 h-3.5" />
                        {t("lp_card_xml_synced")}
                      </span>
                    </div>
                    <div className="px-5 py-3.5 flex items-center justify-between gap-3">
                      <span className="font-semibold text-[#1A1A1A]">{t("lp_card_showcase_live")}</span>
                      <span className="font-mono text-xs text-[#1B5888]">/agencija/demo</span>
                    </div>
                    <div className="px-5 py-3.5 flex items-center justify-between gap-3 bg-[#F8F7F5]/60">
                      <span className="text-[#4A4A4A]">{t("lp_mod_tab_crm")}</span>
                      <span className="font-mono text-xs font-bold text-[#1A1A1A]">
                        {t("lp_card_inquiries_count")}
                      </span>
                    </div>
                  </>
                )}

                {step === "lease" && (
                  <>
                    <div className="px-5 py-3.5 flex items-center justify-between gap-3">
                      <span className="font-semibold text-[#1A1A1A]">{t("lp_card_lease_active")}</span>
                      <span className="font-mono text-xs font-semibold text-[#1B5888] bg-[#E5EEF6] px-2.5 py-1 rounded-[6px]">
                        01.11.2026 – 01.11.2027
                      </span>
                    </div>
                    <div className="px-5 py-3.5 flex items-center justify-between gap-3">
                      <span className="font-semibold text-[#1A1A1A]">{t("lp_card_deposit_held")}</span>
                      <span className="font-mono text-xs font-bold text-[#1A1A1A]">€650.00</span>
                    </div>
                    <div className="px-5 py-3.5 flex items-center justify-between gap-3">
                      <span className="font-semibold text-[#1A1A1A]">{t("lp_card_invites_sent")}</span>
                      <span className="inline-flex items-center gap-1.5 text-xs font-semibold text-[#2A6E43]">
                        <CheckCircle2 className="w-3.5 h-3.5" />
                        iOS · Android
                      </span>
                    </div>
                    <div className="px-5 py-3.5 flex items-center justify-between gap-3 bg-[#F8F7F5]/60">
                      <span className="text-[#4A4A4A]">Infostan · Struja · Internet</span>
                      <span className="font-mono text-xs font-bold text-[#1A1A1A]">EUR / RSD</span>
                    </div>
                  </>
                )}

                {step === "ledger" && (
                  <>
                    <div className="px-5 py-3.5 flex items-center justify-between gap-3">
                      <span className="font-semibold text-[#1A1A1A]">{t("lp_card_rent_paid")}</span>
                      <span className="font-mono text-xs font-bold text-[#2A6E43] bg-[#E6F3EA] px-2.5 py-1 rounded-[6px]">
                        €650.00
                      </span>
                    </div>
                    <div className="px-5 py-3.5 flex items-center justify-between gap-3">
                      <span className="font-semibold text-[#1A1A1A]">{t("lp_card_infostan_approved")}</span>
                      <span className="font-mono text-xs font-bold text-[#1A1A1A]">14,200 RSD</span>
                    </div>
                    <div className="px-5 py-3.5 flex items-center justify-between gap-3">
                      <span className="font-semibold text-[#1A1A1A]">4zida.rs · Halo Oglasi</span>
                      <span className="inline-flex items-center gap-1.5 font-mono text-xs font-semibold text-[#2A6E43]">
                        <Check className="w-3.5 h-3.5" />
                        {t("lp_card_xml_synced")}
                      </span>
                    </div>
                    <div className="px-5 py-3.5 flex items-center justify-between gap-3 bg-[#F8F7F5]/60">
                      <span className="text-[#4A4A4A]">{t("lp_card_mobile_synced")}</span>
                      <span className="inline-flex items-center gap-1.5 text-xs font-semibold text-[#1B5888]">
                        <Smartphone className="w-3.5 h-3.5" />
                        iOS · Android
                      </span>
                    </div>
                  </>
                )}
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ===================================================================== */}
      {/* SECTION 2: TWO MODULES. ONE LEDGER. (2+1 ARCHITECTURAL HAIRLINE GRID) */}
      {/* ===================================================================== */}
      <section className="py-16 lg:py-20 px-4 sm:px-6 lg:px-8 bg-white border-y border-[#E5E3DF]">
        <div className="max-w-7xl mx-auto space-y-10">
          <div className="flex flex-col md:flex-row md:items-end justify-between gap-4">
            <div className="max-w-2xl space-y-2">
              <h2 className="font-[family-name:var(--font-outfit)] text-2xl sm:text-3xl lg:text-4xl font-bold text-[#1A1A1A] tracking-tight">
                {t("lp_grid_title")}
              </h2>
              <p className="text-sm sm:text-base text-[#4A4A4A] leading-relaxed">
                {t("lp_grid_subtitle")}
              </p>
            </div>
            <Link
              href="/agencies#section-pricing"
              className="inline-flex items-center gap-2 text-sm font-bold text-[#1B5888] hover:text-[#12406A] shrink-0"
            >
              <Calculator className="w-4 h-4" />
              <span>{t("lp_grid_pricing_link")}</span>
              <ArrowRight className="w-4 h-4" />
            </Link>
          </div>

          {/* 2+1 Hairline Grid */}
          <div className="rounded-[12px] border border-[#E5E3DF] overflow-hidden divide-y divide-[#E5E3DF] bg-white">
            <div className="grid grid-cols-1 lg:grid-cols-2 divide-y lg:divide-y-0 lg:divide-x divide-[#E5E3DF]">
              {/* Module 1: Portfolio & Distribution */}
              <div className="p-6 sm:p-8 flex flex-col justify-between space-y-6">
                <div className="space-y-4">
                  <div className="flex items-center justify-between gap-3">
                    <div className="flex items-center gap-2.5">
                      <Globe className="w-5 h-5 text-[#1B5888]" />
                      <h3 className="font-[family-name:var(--font-outfit)] text-xl font-bold text-[#1A1A1A]">
                        {t("nav_agency_mod_portfolio")}
                      </h3>
                    </div>
                    <span className="text-[11px] font-semibold text-[#666666] bg-[#F8F7F5] border border-[#E5E3DF] px-2.5 py-0.5 rounded-[6px] shrink-0">
                      {t("nav_agency_optional_badge")}
                    </span>
                  </div>

                  <p className="text-sm text-[#4A4A4A] leading-relaxed">
                    {t("agencies_anchor_portfolio_desc")}
                  </p>

                  <ul className="space-y-2.5 pt-1 text-sm text-[#1A1A1A]">
                    {[
                      t("lp_mod_portfolio_b1"),
                      t("lp_mod_portfolio_b2"),
                      t("lp_mod_crm_b1"),
                    ].map((item) => (
                      <li key={item} className="flex items-start gap-2.5">
                        <Check className="w-4 h-4 text-[#1B5888] shrink-0 mt-0.5" />
                        <span>{item}</span>
                      </li>
                    ))}
                  </ul>
                </div>

                <div>
                  <Link
                    href="/agencies#section-portfolio"
                    className="inline-flex items-center gap-1.5 text-sm font-bold text-[#1B5888] hover:text-[#12406A]"
                  >
                    <span>{t("lp_grid_explore")}</span>
                    <ArrowRight className="w-4 h-4" />
                  </Link>
                </div>
              </div>

              {/* Module 2: Property & Lease Management */}
              <div className="p-6 sm:p-8 flex flex-col justify-between space-y-6">
                <div className="space-y-4">
                  <div className="flex items-center justify-between gap-3">
                    <div className="flex items-center gap-2.5">
                      <Home className="w-5 h-5 text-[#2A6E43]" />
                      <h3 className="font-[family-name:var(--font-outfit)] text-xl font-bold text-[#1A1A1A]">
                        {t("nav_agency_mod_property")}
                      </h3>
                    </div>
                    <span className="text-[11px] font-semibold text-[#666666] bg-[#F8F7F5] border border-[#E5E3DF] px-2.5 py-0.5 rounded-[6px] shrink-0">
                      {t("nav_agency_optional_badge")}
                    </span>
                  </div>

                  <p className="text-sm text-[#4A4A4A] leading-relaxed">
                    {t("agencies_anchor_property_desc")}
                  </p>

                  <ul className="space-y-2.5 pt-1 text-sm text-[#1A1A1A]">
                    {[
                      t("lp_mod_properties_b1"),
                      t("lp_mod_finance_b1"),
                      t("lp_mod_finance_b2"),
                    ].map((item) => (
                      <li key={item} className="flex items-start gap-2.5">
                        <Check className="w-4 h-4 text-[#2A6E43] shrink-0 mt-0.5" />
                        <span>{item}</span>
                      </li>
                    ))}
                  </ul>
                </div>

                <div>
                  <Link
                    href="/agencies#section-property-lease"
                    className="inline-flex items-center gap-1.5 text-sm font-bold text-[#2A6E43] hover:text-[#1f5533]"
                  >
                    <span>{t("lp_grid_explore")}</span>
                    <ArrowRight className="w-4 h-4" />
                  </Link>
                </div>
              </div>
            </div>

            {/* Bottom Included Foundation: Team & Tasks + EOP & AML Compliance */}
            <div className="grid grid-cols-1 lg:grid-cols-2 divide-y lg:divide-y-0 lg:divide-x divide-[#E5E3DF] bg-[#F8F7F5]/65">
              <div className="p-6 sm:px-8 sm:py-6 flex flex-col justify-between gap-4">
                <div className="space-y-1.5">
                  <div className="flex flex-wrap items-center gap-2.5">
                    <CheckSquare className="w-5 h-5 text-[#1B5888]" />
                    <h3 className="font-[family-name:var(--font-outfit)] text-lg font-bold text-[#1A1A1A]">
                      {t("nav_agency_mod_tasks")}
                    </h3>
                    <span className="text-[11px] font-bold text-[#2A6E43] bg-[#E6F3EA] px-2.5 py-0.5 rounded-[6px]">
                      {t("nav_agency_included_badge")}
                    </span>
                  </div>
                  <p className="text-sm text-[#4A4A4A] leading-relaxed">
                    {t("agencies_anchor_tasks_desc")}
                  </p>
                </div>
                <div>
                  <Link
                    href="/agencies#section-tasks"
                    className="inline-flex items-center gap-1.5 text-sm font-bold text-[#1B5888] hover:text-[#12406A]"
                  >
                    <span>{t("lp_grid_explore")}</span>
                    <ArrowRight className="w-4 h-4" />
                  </Link>
                </div>
              </div>

              <div className="p-6 sm:px-8 sm:py-6 flex flex-col justify-between gap-4">
                <div className="space-y-1.5">
                  <div className="flex flex-wrap items-center gap-2.5">
                    <ShieldCheck className="w-5 h-5 text-[#1B5888]" />
                    <h3 className="font-[family-name:var(--font-outfit)] text-lg font-bold text-[#1A1A1A]">
                      {t("nav_agency_mod_compliance")}
                    </h3>
                    <span className="text-[11px] font-bold text-[#2A6E43] bg-[#E6F3EA] px-2.5 py-0.5 rounded-[6px]">
                      {t("nav_agency_included_badge")}
                    </span>
                  </div>
                  <p className="text-sm text-[#4A4A4A] leading-relaxed">
                    {t("agencies_anchor_compliance_desc")}
                  </p>
                </div>
                <div>
                  <Link
                    href="/agencies#section-compliance"
                    className="inline-flex items-center gap-1.5 text-sm font-bold text-[#1B5888] hover:text-[#12406A]"
                  >
                    <span>{t("lp_grid_explore")}</span>
                    <ArrowRight className="w-4 h-4" />
                  </Link>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ===================================================================== */}
      {/* SECTION 3: YOUR TEAM ON WEB. OWNERS & TENANTS ON MOBILE.              */}
      {/* ===================================================================== */}
      <section className="py-16 lg:py-20 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto w-full space-y-8">
        <div className="max-w-2xl space-y-2">
          <h2 className="font-[family-name:var(--font-outfit)] text-2xl sm:text-3xl lg:text-4xl font-bold text-[#1A1A1A] tracking-tight">
            {t("lp_split_title")}
          </h2>
          <p className="text-sm sm:text-base text-[#4A4A4A] leading-relaxed">
            {t("lp_split_desc")}
          </p>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-stretch">
          {/* Left: Agency Web Panel Approvals */}
          <div className="lg:col-span-7 rounded-[12px] bg-white border border-[#E5E3DF] p-6 sm:p-7 flex flex-col justify-between space-y-6">
            <div className="flex items-center justify-between pb-4 border-b border-[#E5E3DF]">
              <span className="font-[family-name:var(--font-outfit)] font-bold text-sm text-[#1A1A1A]">
                {t("lp_split_web_label")}
              </span>
              <span className="font-mono text-xs text-[#666666]">EUR · RSD · 5 {t("language")}</span>
            </div>

            <div className="divide-y divide-[#E5E3DF]">
              {[
                {
                  icon: FileText,
                  title: t("lp_split_row1_title"),
                  status: t("lp_split_row1_status"),
                  amount: "14,200 RSD",
                  tone: "text-[#1B5888] bg-[#E5EEF6]",
                },
                {
                  icon: Wallet,
                  title: t("lp_split_row2_title"),
                  status: t("lp_split_row2_status"),
                  amount: "€650.00",
                  tone: "text-[#2A6E43] bg-[#E6F3EA]",
                },
                {
                  icon: Wrench,
                  title: t("lp_split_row3_title"),
                  status: t("lp_split_row3_status"),
                  amount: "−€85.00",
                  tone: "text-[#8A5206] bg-[#FBF1DC]",
                },
              ].map((row) => {
                const Icon = row.icon;
                return (
                  <div key={row.title} className="py-4 first:pt-0 last:pb-0 flex items-center justify-between gap-4">
                    <div className="flex items-center gap-3 min-w-0">
                      <div className="w-9 h-9 rounded-[8px] bg-[#F8F7F5] border border-[#E5E3DF] flex items-center justify-center shrink-0">
                        <Icon className="w-4 h-4 text-[#1B5888]" />
                      </div>
                      <div className="min-w-0">
                        <p className="text-sm font-bold text-[#1A1A1A] truncate">{row.title}</p>
                        <p className="text-xs text-[#666666]">{row.status}</p>
                      </div>
                    </div>
                    <span className={`font-mono text-xs font-bold px-2.5 py-1 rounded-[6px] shrink-0 ${row.tone}`}>
                      {row.amount}
                    </span>
                  </div>
                );
              })}
            </div>

            <div className="pt-4 border-t border-[#E5E3DF] flex flex-wrap gap-x-5 gap-y-2 text-xs text-[#4A4A4A] font-medium">
              <span>{t("lp_region_p1")}</span>
              <span>·</span>
              <span>{t("lp_region_p2")}</span>
            </div>
          </div>

          {/* Right: Clean Solid Navy Mobile App Panel */}
          <div className="lg:col-span-5 rounded-[12px] bg-[#12406A] text-white p-6 sm:p-7 flex flex-col justify-between space-y-6">
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <span className="text-xs font-bold text-[#C8DDF0] uppercase tracking-wider">
                  {t("lp_split_phone_label")}
                </span>
                <Smartphone className="w-4 h-4 text-[#C8DDF0]" />
              </div>

              {/* Clean Phone Screen Card */}
              <div className="rounded-[12px] bg-white text-[#1A1A1A] p-4 space-y-3 border border-white/10">
                <div className="flex items-center justify-between border-b border-[#E5E3DF] pb-2.5">
                  <div>
                    <p className="font-[family-name:var(--font-outfit)] font-bold text-sm">Njegoševa 24</p>
                    <p className="text-[11px] text-[#666666]">{t("lp_split_phone_status")}</p>
                  </div>
                  <CheckCircle2 className="w-5 h-5 text-[#2A6E43] shrink-0" />
                </div>
                <div className="flex items-center justify-between text-xs">
                  <span className="text-[#4A4A4A]">{t("lp_card_rent_paid")}</span>
                  <span className="font-mono font-bold text-[#2A6E43]">€650.00</span>
                </div>
                <div className="flex items-center justify-between text-xs">
                  <span className="text-[#4A4A4A]">{t("lp_card_infostan_approved")}</span>
                  <span className="font-mono font-bold text-[#1A1A1A]">14,200 RSD</span>
                </div>
              </div>
            </div>

            <div className="space-y-3">
              <div className="flex flex-wrap items-center gap-2.5">
                <a
                  href="https://apps.apple.com/us/app/stanomer/id6762311157"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex transition-opacity hover:opacity-85"
                >
                  <img
                    src="https://upload.wikimedia.org/wikipedia/commons/9/91/Download_on_the_App_Store_RGB_blk.svg"
                    alt="App Store"
                    className="h-9 w-[122px] block invert"
                  />
                </a>
                <a
                  href="https://play.google.com/store/apps/details?id=com.aboptima.stanomer"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex transition-opacity hover:opacity-85"
                >
                  <img
                    src="https://upload.wikimedia.org/wikipedia/commons/7/78/Google_Play_Store_badge_EN.svg"
                    alt="Google Play"
                    className="h-9 w-[122px] block"
                  />
                </a>
              </div>
              <a
                href="/app"
                className="inline-flex items-center gap-1.5 text-xs font-bold text-[#E5EEF6] hover:text-white underline underline-offset-4"
              >
                <span>{t("lp_mobile_web_btn")}</span>
                <ArrowRight className="w-3.5 h-3.5" />
              </a>
            </div>
          </div>
        </div>
      </section>

      {/* ===================================================================== */}
      {/* SECTION 4: COMPACT FAQ                                                */}
      {/* ===================================================================== */}
      <section className="py-14 px-4 sm:px-6 lg:px-8 bg-white border-t border-[#E5E3DF]">
        <div className="max-w-4xl mx-auto space-y-6">
          <h2 className="font-[family-name:var(--font-outfit)] text-2xl sm:text-3xl font-bold text-[#1A1A1A] tracking-tight">
            {t("lp_faq_title")}
          </h2>

          <div className="divide-y divide-[#E5E3DF] border border-[#E5E3DF] rounded-[12px] overflow-hidden">
            {faqs.map((item, idx) => {
              const isOpen = openFaq === idx;
              return (
                <div key={item.q} className="bg-white">
                  <button
                    type="button"
                    onClick={() => setOpenFaq(isOpen ? null : idx)}
                    className="w-full px-5 py-4 text-left flex items-center justify-between gap-4 cursor-pointer hover:bg-[#F8F7F5]/60 transition-colors"
                  >
                    <span className="text-sm font-bold text-[#1A1A1A]">{item.q}</span>
                    <ChevronDown
                      className={`w-4 h-4 text-[#666666] shrink-0 transition-transform ${isOpen ? "rotate-180 text-[#1B5888]" : ""
                        }`}
                    />
                  </button>
                  {isOpen && (
                    <div className="px-5 pb-4 text-xs sm:text-sm text-[#4A4A4A] leading-relaxed">
                      {item.a}
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        </div>
      </section>

      {/* ===================================================================== */}
      {/* SECTION 5: MINIMAL TYPOGRAPHIC CLOSING STRIP                          */}
      {/* ===================================================================== */}
      <section className="py-16 px-4 sm:px-6 lg:px-8 border-t border-[#E5E3DF] bg-[#F8F7F5]">
        <div className="max-w-7xl mx-auto flex flex-col md:flex-row md:items-center justify-between gap-6">
          <div className="space-y-1.5 max-w-xl">
            <h2 className="font-[family-name:var(--font-outfit)] text-2xl sm:text-3xl font-bold text-[#1A1A1A] tracking-tight">
              {t("lp_cta_title")}
            </h2>
            <p className="text-sm text-[#4A4A4A] leading-relaxed">
              {t("lp_cta_desc")}
            </p>
          </div>

          <div className="flex flex-wrap items-center gap-3 shrink-0">
            <Link
              ref={closingDemoBtnRef}
              href="/agency-panel?launch_demo=1"
              className="st-demo-glow-btn inline-flex items-center justify-center gap-2 px-6 py-3.5 rounded-[10px] border border-[#1B5888]/45 text-[#12406A] font-bold text-sm cursor-pointer"
            >
              <Play className="w-4 h-4 text-[#1B5888] fill-[#1B5888]" />
              <span>{t("lp_hero_cta_demo")}</span>
              <ArrowRight className="w-4 h-4 text-[#1B5888]" />
            </Link>
            <a
              href="https://wa.me/381616036556"
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center justify-center gap-2 px-5 py-3.5 rounded-[10px] bg-white hover:bg-[#E5EEF6]/50 border border-[#E5E3DF] text-[#1A1A1A] font-bold text-sm transition-colors"
            >
              <MessageCircle className="w-4 h-4 text-[#2A6E43]" />
              <span>{t("lp_cta_whatsapp")}</span>
            </a>
          </div>
        </div>
      </section>

      {/* ===================================================================== */}
      {/* FOOTER                                                                */}
      {/* ===================================================================== */}
      <footer className="py-10 border-t border-[#E5E3DF] bg-white w-full mt-auto">
        <div className="max-w-7xl mx-auto px-6 text-center">
          <div className="flex items-center justify-center gap-2 opacity-75 mb-5">
            <img src="/assets/logo.png" alt="Stanomer Logo" className="w-6 h-6 object-contain" />
            <span className="font-[family-name:var(--font-outfit)] font-bold text-sm tracking-tight text-[#1A1A1A]">
              Stanomer
            </span>
          </div>

          <div className="flex flex-wrap justify-center gap-x-6 gap-y-2 mb-5 text-xs font-medium text-[#4A4A4A]">
            <Link href="/agency-panel" className="hover:text-[#1B5888] transition-colors font-bold text-[#1B5888]">
              {t("lp_hero_cta_login")}
            </Link>
            <Link href="/agencies#section-pricing" className="hover:text-[#1B5888] transition-colors font-semibold">
              {t("nav_agency_pricing")}
            </Link>
            <a href="/guide" className="hover:text-[#1B5888] transition-colors font-semibold">
              {t("footer_guide")}
            </a>
            <a href="/privacy" className="hover:text-[#1B5888] transition-colors">
              {t("footer_privacy")}
            </a>
            <a href="/terms" className="hover:text-[#1B5888] transition-colors">
              {t("footer_terms")}
            </a>
            <a href="/changelog" className="hover:text-[#1B5888] transition-colors">
              {t("footer_changelog")}
            </a>
            <a href="/support" className="hover:text-[#1B5888] transition-colors">
              {t("footer_support")}
            </a>
          </div>

          <p className="text-[#666666] text-xs">© 2026 Stanomer. {t("footer_rights")}</p>
        </div>
      </footer>
    </div>
  );
}
