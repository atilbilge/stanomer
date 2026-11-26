"use client";

import React, { useEffect, useRef } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { Navbar } from "../../components/Navbar";
import { useLanguage } from "../../components/LanguageProvider";
import { AgencyPricingSection } from "../../components/AgencyPricingSection";
import {
  ArrowRight,
  Building2,
  CheckCircle2,
  CheckSquare,
  FileText,
  Globe,
  Home,
  Inbox,
  MessageCircle,
  Play,
  QrCode,
  ShieldCheck,
  Smartphone,
  Sparkles,
  Users,
  Wallet,
  Wrench,
} from "lucide-react";

export default function AgenciesPage() {
  const { t } = useLanguage();
  const router = useRouter();
  const demoBtnRef = useRef<HTMLAnchorElement | null>(null);

  useEffect(() => {
    if (typeof window !== "undefined" && window.location.hash) {
      const hash = window.location.hash.replace("#", "");
      if (hash) {
        const timer = setTimeout(() => {
          const el = document.getElementById(hash);
          if (el) {
            el.scrollIntoView({ behavior: "smooth" });
          }
        }, 150);
        return () => clearTimeout(timer);
      }
    }
  }, []);

  useEffect(() => {
    let idleTimer: ReturnType<typeof setTimeout> | null = null;
    const handleMouseMove = (e: MouseEvent) => {
      const btn = demoBtnRef.current;
      if (!btn) return;
      const vw = Math.max(1, window.innerWidth);
      const vh = Math.max(1, window.innerHeight);
      const pctX = Math.max(0, Math.min(100, (e.clientX / vw) * 100));
      const pctY = Math.max(0, Math.min(100, (e.clientY / vh) * 100));
      btn.style.setProperty("--demo-mx", `${pctX.toFixed(1)}%`);
      btn.style.setProperty("--demo-my", `${pctY.toFixed(1)}%`);
      btn.style.setProperty("--demo-mx-pct", `${pctX.toFixed(1)}%`);
      btn.style.setProperty("--demo-glow", "1");
      if (idleTimer) clearTimeout(idleTimer);
      idleTimer = setTimeout(() => {
        if (demoBtnRef.current) {
          demoBtnRef.current.style.setProperty("--demo-glow", "0.25");
        }
      }, 450);
    };
    window.addEventListener("mousemove", handleMouseMove, { passive: true });
    return () => {
      window.removeEventListener("mousemove", handleMouseMove);
      if (idleTimer) clearTimeout(idleTimer);
    };
  }, []);

  const portfolioCards = [
    {
      icon: Globe,
      tag: t("lp_mod_tab_portfolio"),
      title: t("lp_mod_portfolio_title"),
      desc: t("lp_mod_portfolio_desc"),
      bullets: [
        t("lp_mod_portfolio_b1"),
        t("lp_mod_portfolio_b2"),
        t("lp_mod_portfolio_b3"),
      ],
    },
    {
      icon: Inbox,
      tag: t("lp_mod_tab_crm"),
      title: t("lp_mod_crm_title"),
      desc: t("lp_mod_crm_desc"),
      bullets: [t("lp_mod_crm_b1"), t("lp_mod_crm_b2"), t("lp_mod_crm_b3")],
    },
  ];

  const propertyLeaseCards = [
    {
      icon: Home,
      tag: t("lp_mod_tab_properties"),
      title: t("lp_mod_properties_title"),
      desc: t("lp_mod_properties_desc"),
      bullets: [
        t("lp_mod_properties_b1"),
        t("lp_mod_properties_b2"),
        t("lp_mod_properties_b3"),
      ],
    },
    {
      icon: Wallet,
      tag: t("lp_mod_tab_finance"),
      title: t("lp_mod_finance_title"),
      desc: t("lp_mod_finance_desc"),
      bullets: [
        t("lp_mod_finance_b1"),
        t("lp_mod_finance_b2"),
        t("lp_mod_finance_b3"),
      ],
    },
  ];

  const tasksCard = {
    icon: CheckSquare,
    tag: t("lp_mod_tab_tasks"),
    title: t("lp_mod_tasks_title"),
    desc: t("lp_mod_tasks_desc"),
    bullets: [
      t("lp_mod_tasks_b1"),
      t("lp_mod_tasks_b2"),
      t("lp_mod_tasks_b3"),
    ],
  };

  return (
    <div className="min-h-screen bg-[#F8F7F5] flex flex-col font-sans text-[#1A1A1A] overflow-x-clip">
      <Navbar />
      <div className="h-[80px]" />

      {/* ===================================================================== */}
      {/* SECTION 1: AGENCY SUITE HERO                                          */}
      {/* ===================================================================== */}
      <section className="pt-10 pb-14 lg:pt-16 lg:pb-20 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto w-full">
        <div className="rounded-[16px] overflow-hidden border border-[#E5E3DF] bg-gradient-to-br from-[#0E3152] via-[#1B5888] to-[#12406A] text-white p-7 sm:p-10 lg:p-12 shadow-[0_18px_48px_rgba(18,64,106,0.18)] relative">
          <div
            aria-hidden="true"
            className="pointer-events-none absolute inset-0 opacity-55"
            style={{
              backgroundImage:
                "radial-gradient(rgba(229, 238, 246, 0.16) 1px, transparent 1px)",
              backgroundSize: "24px 24px",
            }}
          />
          <div
            aria-hidden="true"
            className="pointer-events-none absolute -right-24 -top-20 w-96 h-96 rounded-full bg-[#2A6E43]/30 blur-3xl"
          />

          <div className="relative z-10 grid grid-cols-1 lg:grid-cols-12 gap-8 items-center">
            <div className="lg:col-span-7 space-y-5">
              <div className="inline-flex items-center gap-2 px-3 py-1 rounded-[6px] bg-white/15 border border-white/20 text-[#E5EEF6] text-xs font-bold">
                <Sparkles className="w-3.5 h-3.5 text-[#FBF1DC]" />
                <span>{t("lp_hero_badge")}</span>
              </div>

              <h1 className="font-[family-name:var(--font-outfit)] text-3xl sm:text-4xl lg:text-[44px] font-bold text-white leading-[1.08] tracking-tight">
                {t("lp_hero_title")}
              </h1>

              <p className="text-sm sm:text-base text-[#D8E7F5] leading-relaxed max-w-2xl">
                {t("lp_hero_desc")}
              </p>

              <div className="flex flex-wrap items-center gap-3 pt-2">
                <Link
                  ref={demoBtnRef}
                  href="/agency-panel?launch_demo=1"
                  className="st-demo-glow-btn inline-flex items-center justify-center gap-2 px-6 py-3.5 rounded-[10px] border-[1.5px] border-white/80 text-[#0E3152] font-bold text-sm cursor-pointer"
                >
                  <Play className="w-4 h-4 text-[#1B5888] fill-[#1B5888]" />
                  <span>{t("lp_hero_cta_demo")}</span>
                  <ArrowRight className="w-4 h-4 text-[#1B5888]" />
                </Link>

                <Link
                  href="/agency-panel"
                  className="inline-flex items-center justify-center gap-2 px-6 py-3.5 rounded-[10px] bg-white/12 hover:bg-white/20 border border-white/25 text-white font-bold text-sm transition-colors"
                >
                  <Building2 className="w-4 h-4" />
                  <span>{t("lp_hero_cta_login")}</span>
                </Link>
              </div>

              <p className="text-xs text-[#C8DDF0] font-semibold flex items-center gap-1.5">
                <CheckCircle2 className="w-3.5 h-3.5 text-[#6EE7B7] shrink-0" />
                <span>{t("lp_hero_note")}</span>
              </p>
            </div>

            <div className="lg:col-span-5 grid grid-cols-2 gap-3 text-xs">
              {[
                { icon: Globe, title: t("agency_panel_demo_feat1_title"), desc: t("agency_panel_demo_feat1_desc") },
                { icon: Home, title: t("agency_panel_demo_feat2_title"), desc: t("agency_panel_demo_feat2_desc") },
                { icon: Wallet, title: t("agency_panel_demo_feat3_title"), desc: t("agency_panel_demo_feat3_desc") },
                { icon: CheckSquare, title: t("agency_panel_demo_feat4_title"), desc: t("agency_panel_demo_feat4_desc") },
              ].map((card) => {
                const Icon = card.icon;
                return (
                  <div
                    key={card.title}
                    className="rounded-[12px] bg-white/10 backdrop-blur-xs border border-white/15 p-4 space-y-2"
                  >
                    <div className="w-8 h-8 rounded-[8px] bg-white/15 flex items-center justify-center">
                      <Icon className="w-4 h-4 text-[#E5EEF6]" />
                    </div>
                    <p className="font-bold text-white text-xs leading-snug">{card.title}</p>
                    <p className="text-[#D8E7F5]/85 text-[11px] leading-relaxed">{card.desc}</p>
                  </div>
                );
              })}
            </div>
          </div>
        </div>
      </section>

      {/* ===================================================================== */}
      {/* SECTION 2: #section-portfolio — PORTFOLIO & DISTRIBUTION              */}
      {/* ===================================================================== */}
      <section
        id="section-portfolio"
        className="py-12 lg:py-16 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto w-full space-y-6 scroll-mt-24"
      >
        <div className="max-w-3xl space-y-2">
          <div className="flex flex-wrap items-center gap-2">
            <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-[6px] bg-[#E5EEF6] text-[#1B5888] text-xs font-bold">
              <Globe className="w-3.5 h-3.5" />
              <span>{t("nav_agency_mod_portfolio")}</span>
            </span>
            <span className="inline-flex items-center px-2 py-0.5 rounded-[6px] bg-white border border-[#E5E3DF] text-[#666666] text-[11px] font-semibold">
              {t("nav_agency_optional_badge")}
            </span>
          </div>
          <h2 className="font-[family-name:var(--font-outfit)] text-2xl sm:text-3xl font-bold text-[#1A1A1A] tracking-tight">
            {t("nav_agency_mod_portfolio")}
          </h2>
          <p className="text-sm sm:text-base text-[#4A4A4A] leading-relaxed">
            {t("agencies_anchor_portfolio_desc")}
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
          {portfolioCards.map((mod) => {
            const Icon = mod.icon;
            return (
              <div
                key={mod.tag}
                className="st-card p-6 flex flex-col justify-between space-y-4 hover:border-[#1B5888]/40 transition-colors"
              >
                <div className="space-y-3">
                  <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-[6px] bg-[#E5EEF6] text-[#1B5888] text-xs font-bold">
                    <Icon className="w-3.5 h-3.5" />
                    <span>{mod.tag}</span>
                  </span>
                  <h3 className="font-[family-name:var(--font-outfit)] text-lg font-bold text-[#1A1A1A] leading-snug">
                    {mod.title}
                  </h3>
                  <p className="text-xs sm:text-sm text-[#4A4A4A] leading-relaxed">{mod.desc}</p>
                </div>

                <ul className="space-y-2 pt-3 border-t border-[#E5E3DF] text-xs text-[#1A1A1A] font-medium">
                  {mod.bullets.map((b) => (
                    <li key={b} className="flex items-start gap-2">
                      <CheckCircle2 className="w-3.5 h-3.5 text-[#2A6E43] shrink-0 mt-0.5" />
                      <span>{b}</span>
                    </li>
                  ))}
                </ul>
              </div>
            );
          })}
        </div>
      </section>

      {/* ===================================================================== */}
      {/* SECTION 3: #section-property-lease — PROPERTY & LEASE MANAGEMENT      */}
      {/* ===================================================================== */}
      <section
        id="section-property-lease"
        className="py-14 lg:py-18 px-4 sm:px-6 lg:px-8 bg-white border-y border-[#E5E3DF] scroll-mt-24"
      >
        <span id="section-whitelabel" className="sr-only" />
        <div className="max-w-7xl mx-auto space-y-10">
          <div className="max-w-3xl space-y-2">
            <div className="flex flex-wrap items-center gap-2">
              <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-[6px] bg-[#E6F3EA] text-[#2A6E43] text-xs font-bold">
                <Home className="w-3.5 h-3.5" />
                <span>{t("nav_agency_mod_property")}</span>
              </span>
              <span className="inline-flex items-center px-2 py-0.5 rounded-[6px] bg-[#F8F7F5] border border-[#E5E3DF] text-[#666666] text-[11px] font-semibold">
                {t("nav_agency_optional_badge")}
              </span>
            </div>
            <h2 className="font-[family-name:var(--font-outfit)] text-2xl sm:text-3xl font-bold text-[#1A1A1A] tracking-tight">
              {t("nav_agency_mod_property")}
            </h2>
            <p className="text-sm sm:text-base text-[#4A4A4A] leading-relaxed">
              {t("agencies_anchor_property_desc")}
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
            {propertyLeaseCards.map((mod) => {
              const Icon = mod.icon;
              return (
                <div
                  key={mod.tag}
                  className="rounded-[10px] border border-[#E5E3DF] bg-[#F8F7F5] p-6 flex flex-col justify-between space-y-4 hover:border-[#2A6E43]/40 transition-colors"
                >
                  <div className="space-y-3">
                    <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-[6px] bg-[#E6F3EA] text-[#2A6E43] text-xs font-bold">
                      <Icon className="w-3.5 h-3.5" />
                      <span>{mod.tag}</span>
                    </span>
                    <h3 className="font-[family-name:var(--font-outfit)] text-lg font-bold text-[#1A1A1A] leading-snug">
                      {mod.title}
                    </h3>
                    <p className="text-xs sm:text-sm text-[#4A4A4A] leading-relaxed">{mod.desc}</p>
                  </div>

                  <ul className="space-y-2 pt-3 border-t border-[#E5E3DF] text-xs text-[#1A1A1A] font-medium">
                    {mod.bullets.map((b) => (
                      <li key={b} className="flex items-start gap-2">
                        <CheckCircle2 className="w-3.5 h-3.5 text-[#2A6E43] shrink-0 mt-0.5" />
                        <span>{b}</span>
                      </li>
                    ))}
                  </ul>
                </div>
              );
            })}
          </div>

          {/* Mobile App & Live Lifecycle */}
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-center pt-2">
            <div className="lg:col-span-7 space-y-4">
              <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-[6px] bg-[#E5EEF6] text-[#1B5888] text-xs font-bold">
                <Smartphone className="w-3.5 h-3.5" />
                <span>{t("lp_mobile_badge")}</span>
              </span>
              <h3 className="font-[family-name:var(--font-outfit)] text-xl sm:text-2xl font-bold text-[#1A1A1A] tracking-tight">
                {t("lp_mobile_title")}
              </h3>
              <p className="text-sm sm:text-base text-[#4A4A4A] leading-relaxed">
                {t("lp_mobile_desc")}
              </p>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 pt-1">
                <div className="rounded-[10px] border border-[#E5E3DF] bg-[#F8F7F5] p-4 space-y-1">
                  <div className="flex items-center gap-2 text-xs font-bold text-[#1B5888]">
                    <Globe className="w-4 h-4" />
                    <span>{t("lp_mod_portfolio_b2")}</span>
                  </div>
                </div>
                <div className="rounded-[10px] border border-[#E5E3DF] bg-[#F8F7F5] p-4 space-y-1">
                  <div className="flex items-center gap-2 text-xs font-bold text-[#2A6E43]">
                    <Users className="w-4 h-4" />
                    <span>{t("lp_mod_properties_b2")}</span>
                  </div>
                </div>
              </div>
            </div>

            <div className="lg:col-span-5">
              <div className="rounded-[12px] bg-[#F8F7F5] border border-[#E5E3DF] p-6 space-y-4">
                <div className="flex items-center justify-between pb-3 border-b border-[#E5E3DF]">
                  <span className="font-[family-name:var(--font-outfit)] font-bold text-sm text-[#1A1A1A]">
                    {t("lp_flow_title")}
                  </span>
                  <span className="font-mono text-[11px] font-bold text-[#2A6E43] bg-[#E6F3EA] px-2 py-0.5 rounded-[6px]">
                    Live Sync
                  </span>
                </div>
                <div className="space-y-3 text-xs">
                  {[
                    { num: "01", icon: Globe, title: t("lp_flow_s1_title"), desc: t("lp_flow_s1_desc") },
                    { num: "02", icon: FileText, title: t("lp_flow_s2_title"), desc: t("lp_flow_s2_desc") },
                    { num: "03", icon: Wallet, title: t("lp_flow_s3_title"), desc: t("lp_flow_s3_desc") },
                    { num: "04", icon: Wrench, title: t("lp_flow_s4_title"), desc: t("lp_flow_s4_desc") },
                  ].map((s) => (
                    <div key={s.num} className="flex items-start gap-3">
                      <span className="font-mono text-[11px] font-bold px-2 py-0.5 rounded-[6px] bg-[#E5EEF6] text-[#1B5888] shrink-0">
                        {s.num}
                      </span>
                      <div>
                        <p className="font-bold text-[#1A1A1A]">{s.title}</p>
                        <p className="text-[#666666] mt-0.5">{s.desc}</p>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ===================================================================== */}
      {/* SECTION 4: #section-tasks — TASK MANAGEMENT & REPORTING               */}
      {/* ===================================================================== */}
      <section
        id="section-tasks"
        className="py-12 lg:py-16 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto w-full space-y-6 scroll-mt-24"
      >
        <div className="max-w-3xl space-y-2">
          <div className="flex flex-wrap items-center gap-2">
            <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-[6px] bg-[#E5EEF6] text-[#1B5888] text-xs font-bold">
              <CheckSquare className="w-3.5 h-3.5" />
              <span>{t("nav_agency_mod_tasks")}</span>
            </span>
            <span className="inline-flex items-center px-2 py-0.5 rounded-[6px] bg-[#E6F3EA] text-[#2A6E43] text-[11px] font-bold">
              {t("nav_agency_included_badge")}
            </span>
          </div>
          <h2 className="font-[family-name:var(--font-outfit)] text-2xl sm:text-3xl font-bold text-[#1A1A1A] tracking-tight">
            {t("nav_agency_mod_tasks")}
          </h2>
          <p className="text-sm sm:text-base text-[#4A4A4A] leading-relaxed">
            {t("agencies_anchor_tasks_desc")}
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
          <div className="st-card p-6 flex flex-col justify-between space-y-4 hover:border-[#1B5888]/40 transition-colors">
            <div className="space-y-3">
              <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-[6px] bg-[#E5EEF6] text-[#1B5888] text-xs font-bold">
                <tasksCard.icon className="w-3.5 h-3.5" />
                <span>{tasksCard.tag}</span>
              </span>
              <h3 className="font-[family-name:var(--font-outfit)] text-lg font-bold text-[#1A1A1A] leading-snug">
                {tasksCard.title}
              </h3>
              <p className="text-xs sm:text-sm text-[#4A4A4A] leading-relaxed">{tasksCard.desc}</p>
            </div>
            <ul className="space-y-2 pt-3 border-t border-[#E5E3DF] text-xs text-[#1A1A1A] font-medium">
              {tasksCard.bullets.map((b) => (
                <li key={b} className="flex items-start gap-2">
                  <CheckCircle2 className="w-3.5 h-3.5 text-[#2A6E43] shrink-0 mt-0.5" />
                  <span>{b}</span>
                </li>
              ))}
            </ul>
          </div>

          <div className="rounded-[10px] border border-[#1B5888]/30 bg-gradient-to-br from-[#FFFFFF] to-[#E5EEF6]/60 p-6 flex flex-col justify-between space-y-4">
            <div className="space-y-3">
              <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-[6px] bg-[#1B5888] text-white text-xs font-bold">
                <ShieldCheck className="w-3.5 h-3.5" />
                <span>{t("lp_region_badge")}</span>
              </span>
              <h3 className="font-[family-name:var(--font-outfit)] text-lg font-bold text-[#1A1A1A] leading-snug">
                {t("lp_region_title")}
              </h3>
              <p className="text-xs sm:text-sm text-[#4A4A4A] leading-relaxed">
                {t("lp_region_desc")}
              </p>
            </div>
            <ul className="space-y-2 pt-3 border-t border-[#1B5888]/15 text-xs text-[#1A1A1A] font-medium">
              {[t("lp_region_p1"), t("lp_region_p2"), t("lp_region_p3"), t("lp_region_p4")].map((pt) => (
                <li key={pt} className="flex items-start gap-2">
                  <CheckCircle2 className="w-3.5 h-3.5 text-[#2A6E43] shrink-0 mt-0.5" />
                  <span>{pt}</span>
                </li>
              ))}
            </ul>
          </div>
        </div>
      </section>

      {/* ===================================================================== */}
      {/* SECTION 4: TRANSPARENT AGENCY PRICING CALCULATOR                      */}
      {/* ===================================================================== */}
      <AgencyPricingSection onOpenSimulation={() => router.push("/agency-panel?launch_demo=1")} />

      {/* ===================================================================== */}
      {/* SECTION 5: #section-referral — PARTNER REFERRAL STRIP                 */}
      {/* ===================================================================== */}
      <section
        id="section-referral"
        className="py-12 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto w-full scroll-mt-24"
      >
        <div className="st-card p-6 sm:p-8 flex flex-col md:flex-row md:items-center justify-between gap-6">
          <div className="space-y-2 max-w-2xl">
            <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-[6px] bg-[#E5EEF6] text-[#1B5888] text-xs font-bold">
              <QrCode className="w-3.5 h-3.5" />
              <span>{t("nav_agency_referral_title")}</span>
            </span>
            <h3 className="font-[family-name:var(--font-outfit)] text-xl font-bold text-[#1A1A1A]">
              {t("agencies_ref_title")}
            </h3>
            <p className="text-sm text-[#4A4A4A] leading-relaxed">
              {t("agencies_ref_subtitle")}
            </p>
          </div>
          <div className="flex flex-wrap items-center gap-3 shrink-0">
            <Link
              href="/agency-referral"
              className="st-btn-secondary px-5 py-2.5 text-xs sm:text-sm gap-2"
            >
              <QrCode className="w-4 h-4" />
              <span>{t("agencies_ref_cta_btn")}</span>
            </Link>
            <Link
              href="/agency-stats"
              className="text-xs font-bold text-[#1B5888] hover:underline px-2 py-2"
            >
              {t("footer_already_partner")}
            </Link>
          </div>
        </div>
      </section>

      {/* ===================================================================== */}
      {/* SECTION 6: BOTTOM CONVERSION CTA                                      */}
      {/* ===================================================================== */}
      <section className="py-12 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto w-full mb-6">
        <div className="rounded-[16px] bg-gradient-to-br from-[#0E3152] via-[#1B5888] to-[#12406A] text-white p-8 sm:p-12 text-center space-y-5 shadow-[0_14px_36px_rgba(18,64,106,0.2)]">
          <h2 className="font-[family-name:var(--font-outfit)] text-2xl sm:text-3xl font-bold text-white tracking-tight max-w-2xl mx-auto">
            {t("lp_cta_title")}
          </h2>
          <p className="text-sm sm:text-base text-[#D8E7F5] max-w-xl mx-auto leading-relaxed">
            {t("lp_cta_desc")}
          </p>
          <div className="flex flex-wrap items-center justify-center gap-3 pt-2">
            <Link
              href="/agency-panel?launch_demo=1"
              className="inline-flex items-center justify-center gap-2 px-6 py-3.5 rounded-[10px] bg-white text-[#0E3152] hover:bg-[#E5EEF6] font-bold text-sm transition-colors shadow-lg"
            >
              <Play className="w-4 h-4 text-[#1B5888] fill-[#1B5888]" />
              <span>{t("lp_hero_cta_demo")}</span>
              <ArrowRight className="w-4 h-4 text-[#1B5888]" />
            </Link>
            <a
              href="https://wa.me/381616036556"
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center justify-center gap-2 px-6 py-3.5 rounded-[10px] bg-white/12 hover:bg-white/20 border border-white/25 text-white font-bold text-sm transition-colors"
            >
              <MessageCircle className="w-4 h-4" />
              <span>{t("lp_cta_whatsapp")}</span>
            </a>
          </div>
        </div>
      </section>

      {/* FOOTER */}
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
            <a href="/agency-stats" className="hover:text-[#1B5888] transition-colors font-semibold">
              {t("footer_already_partner")}
            </a>
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
