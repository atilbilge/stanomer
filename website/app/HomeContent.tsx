"use client";

import React, { useState, useEffect, useRef } from "react";
import Link from "next/link";
import { useLanguage } from "../components/LanguageProvider";
import {
  ArrowRight,
  Building2,
  Check,
  CheckCircle2,
  CheckSquare,
  ChevronDown,
  FileText,
  Globe,
  Home,
  Inbox,
  MessageCircle,
  Play,
  ShieldCheck,
  Smartphone,
  Sparkles,
  Users,
  Wallet,
  Wrench,
  X,
} from "lucide-react";

type ModuleKey = "portfolio" | "crm" | "properties" | "finance" | "tasks";

export function HomeContent() {
  const { t } = useLanguage();
  const [activeModule, setActiveModule] = useState<ModuleKey>("portfolio");
  const [openFaq, setOpenFaq] = useState<number | null>(0);
  const heroDemoBtnRef = useRef<HTMLAnchorElement | null>(null);

  useEffect(() => {
    let idleTimer: ReturnType<typeof setTimeout> | null = null;
    const handleMouseMove = (e: MouseEvent) => {
      const btn = heroDemoBtnRef.current;
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
        if (heroDemoBtnRef.current) {
          heroDemoBtnRef.current.style.setProperty("--demo-glow", "0.25");
        }
      }, 450);
    };
    window.addEventListener("mousemove", handleMouseMove, { passive: true });
    return () => {
      window.removeEventListener("mousemove", handleMouseMove);
      if (idleTimer) clearTimeout(idleTimer);
    };
  }, []);

  const modules: {
    id: ModuleKey;
    label: string;
    icon: React.ComponentType<{ className?: string }>;
    title: string;
    desc: string;
    bullets: string[];
  }[] = [
    {
      id: "portfolio",
      label: t("lp_mod_tab_portfolio"),
      icon: Globe,
      title: t("lp_mod_portfolio_title"),
      desc: t("lp_mod_portfolio_desc"),
      bullets: [
        t("lp_mod_portfolio_b1"),
        t("lp_mod_portfolio_b2"),
        t("lp_mod_portfolio_b3"),
      ],
    },
    {
      id: "crm",
      label: t("lp_mod_tab_crm"),
      icon: Inbox,
      title: t("lp_mod_crm_title"),
      desc: t("lp_mod_crm_desc"),
      bullets: [t("lp_mod_crm_b1"), t("lp_mod_crm_b2"), t("lp_mod_crm_b3")],
    },
    {
      id: "properties",
      label: t("lp_mod_tab_properties"),
      icon: Home,
      title: t("lp_mod_properties_title"),
      desc: t("lp_mod_properties_desc"),
      bullets: [
        t("lp_mod_properties_b1"),
        t("lp_mod_properties_b2"),
        t("lp_mod_properties_b3"),
      ],
    },
    {
      id: "finance",
      label: t("lp_mod_tab_finance"),
      icon: Wallet,
      title: t("lp_mod_finance_title"),
      desc: t("lp_mod_finance_desc"),
      bullets: [
        t("lp_mod_finance_b1"),
        t("lp_mod_finance_b2"),
        t("lp_mod_finance_b3"),
      ],
    },
    {
      id: "tasks",
      label: t("lp_mod_tab_tasks"),
      icon: CheckSquare,
      title: t("lp_mod_tasks_title"),
      desc: t("lp_mod_tasks_desc"),
      bullets: [
        t("lp_mod_tasks_b1"),
        t("lp_mod_tasks_b2"),
        t("lp_mod_tasks_b3"),
      ],
    },
  ];

  const currentModule = modules.find((m) => m.id === activeModule) || modules[0];

  const faqs = [
    { q: t("lp_faq_q1"), a: t("lp_faq_a1") },
    { q: t("lp_faq_q2"), a: t("lp_faq_a2") },
    { q: t("lp_faq_q3"), a: t("lp_faq_a3") },
    { q: t("lp_faq_q4"), a: t("lp_faq_a4") },
    { q: t("lp_faq_q5"), a: t("lp_faq_a5") },
  ];

  const renderModulePreview = (modId: ModuleKey) => {
    if (modId === "portfolio") {
      return (
        <div className="space-y-3">
          <div className="flex items-center justify-between gap-2 pb-2.5 border-b border-[#E5E3DF]">
            <div className="flex items-center gap-2">
              <Building2 className="w-4 h-4 text-[#1B5888]" />
              <span className="text-xs font-bold text-[#1A1A1A]">{t("lp_mod_tab_portfolio")}</span>
            </div>
            <div className="flex items-center gap-1.5">
              <span className="px-2 py-0.5 rounded-[6px] bg-[#E6F3EA] text-[#2A6E43] text-[10px] font-bold">
                4zida.rs XML ✓
              </span>
              <span className="px-2 py-0.5 rounded-[6px] bg-[#E6F3EA] text-[#2A6E43] text-[10px] font-bold">
                Halo Oglasi ✓
              </span>
            </div>
          </div>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div className="rounded-[10px] border border-[#E5E3DF] bg-[#F8F7F5] p-3 space-y-2">
              <div className="flex items-center justify-between">
                <span className="text-xs font-bold text-[#1A1A1A]">BW Terraces 207</span>
                <span className="font-mono text-xs font-bold text-[#1B5888]">€1,450/mo</span>
              </div>
              <p className="text-[11px] text-[#666666]">Beograd · 2.5 · 74 m² · 8F</p>
              <div className="flex items-center gap-1.5 flex-wrap">
                <span className="px-2 py-0.5 rounded-[5px] bg-[#E6F3EA] text-[#2A6E43] text-[10px] font-bold">
                  {t("agency_panel_demo_pill_published")}
                </span>
                <span className="px-2 py-0.5 rounded-[5px] bg-[#E5EEF6] text-[#1B5888] text-[10px] font-bold">
                  2 {t("agency_tasks_page_title")}
                </span>
              </div>
            </div>
            <div className="rounded-[10px] border border-[#E5E3DF] bg-[#F8F7F5] p-3 space-y-2">
              <div className="flex items-center justify-between">
                <span className="text-xs font-bold text-[#1A1A1A]">Njegoševa 24</span>
                <span className="font-mono text-xs font-bold text-[#1B5888]">€650/mo</span>
              </div>
              <p className="text-[11px] text-[#666666]">Novi Sad · 2.0 · 54 m² · 3F</p>
              <div className="flex items-center gap-1.5 flex-wrap">
                <span className="px-2 py-0.5 rounded-[5px] bg-[#E6F3EA] text-[#2A6E43] text-[10px] font-bold">
                  {t("agency_panel_demo_pill_published")}
                </span>
                <span className="px-2 py-0.5 rounded-[5px] bg-white border border-[#E5E3DF] text-[#4A4A4A] text-[10px] font-mono">
                  /agencija/demo
                </span>
              </div>
            </div>
          </div>
          <div className="rounded-[8px] bg-[#0E3152] text-[#C8DDF0] font-mono text-[11px] p-3 overflow-x-auto">
            <code>
              &lt;listing id=&quot;ST-207&quot; portal=&quot;4zida,halo&quot; status=&quot;validated&quot;&gt;€1,450&lt;/listing&gt;
            </code>
          </div>
        </div>
      );
    }

    if (modId === "crm") {
      return (
        <div className="space-y-3">
          <div className="flex items-center justify-between pb-2.5 border-b border-[#E5E3DF]">
            <div className="flex items-center gap-2">
              <Inbox className="w-4 h-4 text-[#1B5888]" />
              <span className="text-xs font-bold text-[#1A1A1A]">{t("lp_mod_tab_crm")}</span>
            </div>
            <span className="px-2 py-0.5 rounded-[6px] bg-[#FBF1DC] text-[#8A5206] text-[10px] font-bold">
              3 Active Leads
            </span>
          </div>
          {[
            { name: "Marko Petrović", prop: "BW Terraces 207", badge: "Viewing", tasks: 2, cls: "bg-[#E5EEF6] text-[#1B5888]" },
            { name: "Ana Nikolić", prop: "Vračar 3.0 · 82 m²", badge: "Owner", tasks: 1, cls: "bg-[#FBF1DC] text-[#8A5206]" },
            { name: "Dmitry Volkov", prop: "Njegoševa 24", badge: "Viewing", tasks: 1, cls: "bg-[#E6F3EA] text-[#2A6E43]" },
          ].map((lead) => (
            <div
              key={lead.name}
              className="rounded-[10px] border border-[#E5E3DF] bg-[#F8F7F5] p-3 flex items-center justify-between gap-2"
            >
              <div className="min-w-0">
                <p className="text-xs font-bold text-[#1A1A1A] truncate">{lead.name}</p>
                <p className="text-[11px] text-[#666666] truncate">{lead.prop}</p>
              </div>
              <div className="flex items-center gap-1.5 shrink-0">
                <span className={`px-2 py-0.5 rounded-[5px] text-[10px] font-bold ${lead.cls}`}>
                  {lead.badge}
                </span>
                <span className="px-2 py-0.5 rounded-[5px] bg-white border border-[#E5E3DF] text-[#1B5888] text-[10px] font-bold inline-flex items-center gap-1">
                  <CheckSquare className="w-3 h-3" />
                  {lead.tasks}
                </span>
              </div>
            </div>
          ))}
        </div>
      );
    }

    if (modId === "properties") {
      return (
        <div className="space-y-3">
          <div className="flex items-center justify-between pb-2.5 border-b border-[#E5E3DF]">
            <div className="flex items-center gap-2">
              <Home className="w-4 h-4 text-[#1B5888]" />
              <span className="text-xs font-bold text-[#1A1A1A]">{t("lp_mod_tab_properties")}</span>
            </div>
            <span className="px-2 py-0.5 rounded-[6px] bg-[#E6F3EA] text-[#2A6E43] text-[10px] font-bold">
              94% Occupied
            </span>
          </div>
          <div className="rounded-[10px] border border-[#E5E3DF] bg-[#F8F7F5] p-3.5 space-y-2.5">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-xs font-bold text-[#1A1A1A]">BW Terraces 207</p>
                <p className="text-[11px] text-[#666666]">Hercegovačka 16, Beograd</p>
              </div>
              <span className="px-2 py-0.5 rounded-[6px] bg-[#E6F3EA] text-[#2A6E43] text-[10px] font-bold">
                {t("agency_panel_demo_pill_lease")}
              </span>
            </div>
            <div className="grid grid-cols-3 gap-2 pt-2 border-t border-[#E5E3DF] text-[11px]">
              <div>
                <span className="text-[#666666] block">Rent</span>
                <span className="font-mono font-bold text-[#1A1A1A]">€1,450</span>
              </div>
              <div>
                <span className="text-[#666666] block">Deposit</span>
                <span className="font-mono font-bold text-[#1A1A1A]">€1,450</span>
              </div>
              <div>
                <span className="text-[#666666] block">Portal</span>
                <span className="font-bold text-[#2A6E43]">Connected ✓</span>
              </div>
            </div>
          </div>
          <div className="flex items-center gap-2 text-[11px] text-[#1B5888] font-semibold bg-[#E5EEF6] rounded-[8px] px-3 py-2">
            <FileText className="w-3.5 h-3.5 shrink-0" />
            <span>{t("lp_mod_properties_b2")}</span>
          </div>
        </div>
      );
    }

    if (modId === "finance") {
      return (
        <div className="space-y-3">
          <div className="flex items-center justify-between pb-2.5 border-b border-[#E5E3DF]">
            <div className="flex items-center gap-2">
              <Wallet className="w-4 h-4 text-[#1B5888]" />
              <span className="text-xs font-bold text-[#1A1A1A]">{t("lp_mod_tab_finance")}</span>
            </div>
            <span className="font-mono text-[11px] font-bold text-[#2A6E43]">EUR · RSD</span>
          </div>
          <div className="grid grid-cols-2 gap-2.5">
            <div className="rounded-[10px] border border-[#E5E3DF] bg-[#E6F3EA]/60 p-3">
              <span className="text-[10px] font-semibold text-[#2A6E43] block">Collected (EUR)</span>
              <span className="font-mono text-lg font-bold text-[#2A6E43]">€18,450</span>
            </div>
            <div className="rounded-[10px] border border-[#E5E3DF] bg-[#E5EEF6]/70 p-3">
              <span className="text-[10px] font-semibold text-[#1B5888] block">Utilities (RSD)</span>
              <span className="font-mono text-lg font-bold text-[#1B5888]">142,800 RSD</span>
            </div>
          </div>
          <div className="rounded-[10px] border border-[#E5E3DF] bg-[#F8F7F5] divide-y divide-[#E5E3DF] text-xs">
            <div className="px-3 py-2 flex items-center justify-between">
              <span className="font-semibold text-[#1A1A1A]">BW Terraces 207 · Rent</span>
              <span className="font-mono font-bold text-[#2A6E43]">+€1,450</span>
            </div>
            <div className="px-3 py-2 flex items-center justify-between">
              <span className="font-semibold text-[#1A1A1A]">Infostan & Struja</span>
              <span className="font-mono font-bold text-[#1B5888]">14,200 RSD</span>
            </div>
            <div className="px-3 py-2 flex items-center justify-between">
              <span className="font-semibold text-[#1A1A1A]">Maintenance Offset</span>
              <span className="font-mono font-bold text-[#8A5206]">-€85</span>
            </div>
          </div>
        </div>
      );
    }

    return (
      <div className="space-y-3">
        <div className="flex items-center justify-between pb-2.5 border-b border-[#E5E3DF]">
          <div className="flex items-center gap-2">
            <CheckSquare className="w-4 h-4 text-[#1B5888]" />
            <span className="text-xs font-bold text-[#1A1A1A]">{t("lp_mod_tab_tasks")}</span>
          </div>
          <span className="px-2 py-0.5 rounded-[6px] bg-[#E5EEF6] text-[#1B5888] text-[10px] font-bold">
            Kanban · List
          </span>
        </div>
        <div className="grid grid-cols-3 gap-2 text-[11px]">
          <div className="rounded-[8px] bg-[#F8F7F5] border border-[#E5E3DF] p-2 space-y-1.5">
            <div className="font-bold text-[#4A4A4A] flex items-center justify-between">
              <span>{t("agency_tasks_status_todo")}</span>
              <span className="font-mono text-[10px]">2</span>
            </div>
            <div className="rounded-[6px] bg-white border border-[#E5E3DF] p-2 space-y-1">
              <p className="font-bold text-[#1A1A1A] leading-tight">Key handover</p>
              <span className="inline-block px-1.5 py-0.5 rounded bg-[#E5EEF6] text-[#1B5888] text-[9px] font-bold">
                Property
              </span>
            </div>
          </div>
          <div className="rounded-[8px] bg-[#E5EEF6]/40 border border-[#1B5888]/20 p-2 space-y-1.5">
            <div className="font-bold text-[#1B5888] flex items-center justify-between">
              <span>{t("agency_tasks_status_in_progress")}</span>
              <span className="font-mono text-[10px]">1</span>
            </div>
            <div className="rounded-[6px] bg-white border border-[#E5E3DF] p-2 space-y-1">
              <p className="font-bold text-[#1A1A1A] leading-tight">AC service</p>
              <span className="inline-block px-1.5 py-0.5 rounded bg-[#FBEAE6] text-[#A33C29] text-[9px] font-bold">
                Maintenance
              </span>
            </div>
          </div>
          <div className="rounded-[8px] bg-[#E6F3EA]/50 border border-[#2A6E43]/20 p-2 space-y-1.5">
            <div className="font-bold text-[#2A6E43] flex items-center justify-between">
              <span>{t("agency_tasks_status_done")}</span>
              <span className="font-mono text-[10px]">4</span>
            </div>
            <div className="rounded-[6px] bg-white border border-[#E5E3DF] p-2 space-y-1">
              <p className="font-bold text-[#8A8A8A] line-through leading-tight">XML audit</p>
              <span className="inline-block px-1.5 py-0.5 rounded bg-[#E6F3EA] text-[#2A6E43] text-[9px] font-bold">
                Listing
              </span>
            </div>
          </div>
        </div>
      </div>
    );
  };

  return (
    <div className="min-h-screen flex flex-col font-sans bg-[#F8F7F5] text-[#1A1A1A] overflow-x-hidden">
      {/* ========================================================================= */}
      {/* SECTION 1: HERO — END-TO-END AGENCY OPERATING SYSTEM                      */}
      {/* ========================================================================= */}
      <section className="relative pt-10 pb-14 lg:pt-16 lg:pb-20 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto w-full">
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-10 lg:gap-8 items-center">
          {/* Left Copy & CTAs */}
          <div className="lg:col-span-6 space-y-5">
            <div className="inline-flex items-center gap-2 px-3 py-1 rounded-[6px] bg-[#E5EEF6] border border-[#1B5888]/20 text-[#12406A] text-xs font-bold">
              <Sparkles className="w-3.5 h-3.5 text-[#1B5888]" />
              <span>{t("lp_hero_badge")}</span>
            </div>

            <h1 className="font-[family-name:var(--font-outfit)] text-3xl sm:text-4xl lg:text-[46px] font-bold text-[#1A1A1A] tracking-tight leading-[1.08]">
              {t("lp_hero_title")}
            </h1>

            <p className="text-sm sm:text-base text-[#4A4A4A] leading-relaxed max-w-xl">
              {t("lp_hero_desc")}
            </p>

            <div className="flex flex-wrap items-center gap-3 pt-2">
              <Link
                ref={heroDemoBtnRef}
                href="/agency-panel"
                className="st-demo-glow-btn inline-flex items-center justify-center gap-2 px-6 py-3.5 rounded-[10px] border-[1.5px] border-[#1B5888] text-[#12406A] font-bold text-sm cursor-pointer"
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

            <p className="text-xs text-[#666666] font-semibold flex items-center gap-1.5">
              <CheckCircle2 className="w-3.5 h-3.5 text-[#2A6E43] shrink-0" />
              <span>{t("lp_hero_note")}</span>
            </p>
          </div>

          {/* Right Branded Animated Agency Suite Hero Canvas */}
          <div className="lg:col-span-6">
            <div className="relative overflow-hidden rounded-[16px] bg-gradient-to-br from-[#0E3152] via-[#1B5888] to-[#12406A] text-white p-6 sm:p-8 border border-[#3B82B8]/40 shadow-[0_18px_48px_rgba(18,64,106,0.22)]">
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
                className="pointer-events-none absolute -right-24 top-10 w-80 h-80 rounded-full bg-[#2A6E43]/30 blur-3xl"
              />

              {/* Animated Lifecycle Diagram */}
              <div className="relative z-10 w-full max-w-[440px] mx-auto">
                <div className="relative h-[238px]">
                  <svg
                    viewBox="0 0 440 238"
                    className="absolute inset-0 w-full h-full pointer-events-none"
                    aria-hidden="true"
                  >
                    <path
                      className="st-flow"
                      d="M312 80 C346 80 342 36 360 32"
                      fill="none"
                      stroke="#6EE7B7"
                      strokeWidth="2"
                    />
                    <path
                      className="st-flow"
                      d="M312 138 C346 138 342 182 360 186"
                      fill="none"
                      stroke="#6EE7B7"
                      strokeWidth="2"
                    />
                    <path
                      className="st-flow"
                      d="M128 78 C98 72 90 40 74 32"
                      fill="none"
                      stroke="#93C5FD"
                      strokeWidth="1.7"
                    />
                    <path
                      className="st-flow"
                      d="M128 144 C98 152 90 184 72 194"
                      fill="none"
                      stroke="#93C5FD"
                      strokeWidth="1.7"
                    />
                  </svg>

                  {/* Center Property Card */}
                  <div className="absolute left-1/2 -translate-x-1/2 top-[16px] w-[188px] bg-white rounded-[10px] border border-[#E5E3DF] text-[#1A1A1A] shadow-[0_16px_36px_rgba(8,24,44,0.36)] overflow-hidden">
                    <svg
                      viewBox="0 0 224 68"
                      className="w-full h-[68px] block"
                      role="img"
                      aria-label="Stanomer property card"
                    >
                      <rect width="224" height="68" fill="#E5EEF6" />
                      <circle cx="184" cy="18" r="9" fill="#A33C29" opacity="0.88" />
                      <rect x="28" y="24" width="54" height="44" rx="2" fill="#1B5888" />
                      <rect x="84" y="12" width="52" height="56" rx="2" fill="#12406A" />
                      <rect x="138" y="32" width="54" height="36" rx="2" fill="#2A6E43" />
                      <g fill="#E5EEF6" opacity="0.92">
                        <rect x="38" y="33" width="9" height="8" rx="1.5" />
                        <rect x="58" y="33" width="9" height="8" rx="1.5" />
                        <rect x="38" y="47" width="9" height="8" rx="1.5" />
                        <rect x="58" y="47" width="9" height="8" rx="1.5" />
                        <rect x="95" y="22" width="9" height="8" rx="1.5" />
                        <rect x="114" y="22" width="9" height="8" rx="1.5" />
                        <rect x="95" y="36" width="9" height="8" rx="1.5" />
                        <rect x="114" y="36" width="9" height="8" rx="1.5" />
                        <rect x="149" y="41" width="9" height="8" rx="1.5" />
                        <rect x="168" y="41" width="9" height="8" rx="1.5" />
                      </g>
                    </svg>
                    <div className="p-2.5">
                      <div className="font-[family-name:var(--font-outfit)] font-bold text-xs text-[#1A1A1A] leading-tight truncate">
                        Njegoševa 24, Novi Sad
                      </div>
                      <div className="text-[10px] text-[#666666] mt-0.5 mb-1.5">
                        2.0 · 54 m² · 3F
                      </div>
                      <div className="flex items-center justify-between gap-1.5">
                        <span className="font-mono font-medium text-xs text-[#1B5888]">
                          €650/mo
                        </span>
                        <span className="inline-flex items-center px-1.5 py-0.5 rounded-[5px] bg-[#E6F3EA] text-[#2A6E43] text-[9.5px] font-bold">
                          {t("agency_panel_demo_pill_published")}
                        </span>
                      </div>
                    </div>
                  </div>

                  {/* Right Portal Pills */}
                  <div className="absolute right-0 top-[14px] bg-white text-[#1A1A1A] rounded-[8px] px-2.5 py-1.5 shadow-lg border border-[#E5E3DF] flex items-center gap-1.5 text-[10.5px] font-bold">
                    <span className="w-2 h-2 rounded-full bg-[#2A6E43] shrink-0" />
                    <span>4zida.rs</span>
                  </div>
                  <div className="absolute right-0 top-[168px] bg-white text-[#1A1A1A] rounded-[8px] px-2.5 py-1.5 shadow-lg border border-[#E5E3DF] flex items-center gap-1.5 text-[10.5px] font-bold">
                    <span className="w-2 h-2 rounded-full bg-[#2A6E43] shrink-0" />
                    <span>Halo Oglasi</span>
                  </div>

                  {/* Floating Lifecycle Pills */}
                  <div className="st-bob-1 absolute left-0 top-[10px] bg-[#0E3152]/92 backdrop-blur-xs border border-[#4D8DC0]/40 rounded-[8px] px-2.5 py-1.5 text-[10px] font-semibold text-white shadow-md flex items-center gap-1.5">
                    <FileText className="w-3 h-3 text-[#E5EEF6] shrink-0" />
                    <span>{t("agency_panel_demo_pill_lease")}</span>
                  </div>
                  <div className="st-bob-2 absolute left-0 top-[172px] bg-[#0E3152]/92 backdrop-blur-xs border border-[#4D8DC0]/40 rounded-[8px] px-2.5 py-1.5 text-[10px] font-semibold text-white shadow-md flex items-center gap-1.5">
                    <Wallet className="w-3 h-3 text-[#6EE7B7] shrink-0" />
                    <span>{t("agency_panel_demo_pill_rent")}</span>
                    <span className="font-mono text-[#6EE7B7] font-medium">+€650</span>
                  </div>
                  <div className="st-bob-3 absolute left-1/2 -translate-x-1/2 bottom-0 bg-[#0E3152]/92 backdrop-blur-xs border border-[#4D8DC0]/40 rounded-[8px] px-2.5 py-1.5 text-[10px] font-semibold text-white shadow-md flex items-center gap-1.5 whitespace-nowrap">
                    <CheckSquare className="w-3 h-3 text-[#FBF1DC] shrink-0" />
                    <span>{t("agency_panel_demo_pill_tasks")}</span>
                  </div>
                </div>
              </div>

              {/* Mini KPI Strip inside Hero Visual */}
              <div className="relative z-10 mt-5 pt-4 border-t border-white/15 grid grid-cols-3 gap-2.5 text-center">
                <div className="rounded-[8px] bg-white/10 border border-white/15 py-2 px-2">
                  <div className="font-mono text-sm sm:text-base font-bold text-white">2x XML</div>
                  <div className="text-[10px] text-[#C8DDF0]">4zida · Halo</div>
                </div>
                <div className="rounded-[8px] bg-white/10 border border-white/15 py-2 px-2">
                  <div className="font-mono text-sm sm:text-base font-bold text-[#6EE7B7]">EUR · RSD</div>
                  <div className="text-[10px] text-[#C8DDF0]">{t("lp_mod_tab_finance")}</div>
                </div>
                <div className="rounded-[8px] bg-white/10 border border-white/15 py-2 px-2">
                  <div className="font-mono text-sm sm:text-base font-bold text-white">Kanban</div>
                  <div className="text-[10px] text-[#C8DDF0]">{t("lp_mod_tab_tasks")}</div>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Trust Capabilities Strip */}
        <div className="mt-10 pt-6 border-t border-[#E5E3DF] flex flex-wrap items-center justify-between gap-3">
          {[
            { icon: Globe, text: t("lp_trust_xml") },
            { icon: Wallet, text: t("lp_trust_currency") },
            { icon: Smartphone, text: t("lp_trust_mobile") },
            { icon: Users, text: t("lp_trust_roles") },
            { icon: ShieldCheck, text: t("lp_trust_langs") },
          ].map((item) => {
            const Icon = item.icon;
            return (
              <div
                key={item.text}
                className="inline-flex items-center gap-2 px-3 py-1.5 rounded-[8px] bg-white border border-[#E5E3DF] text-xs font-semibold text-[#4A4A4A]"
              >
                <Icon className="w-3.5 h-3.5 text-[#1B5888] shrink-0" />
                <span>{item.text}</span>
              </div>
            );
          })}
        </div>
      </section>

      {/* ========================================================================= */}
      {/* SECTION 2: PROBLEM VS SOLUTION COMPARISON                                 */}
      {/* ========================================================================= */}
      <section className="py-14 lg:py-18 px-4 sm:px-6 lg:px-8 bg-white border-y border-[#E5E3DF]">
        <div className="max-w-7xl mx-auto space-y-8">
          <div className="max-w-2xl space-y-2">
            <span className="inline-flex items-center px-2.5 py-1 rounded-[6px] bg-[#E5EEF6] text-[#1B5888] text-xs font-bold">
              {t("lp_compare_badge")}
            </span>
            <h2 className="font-[family-name:var(--font-outfit)] text-2xl sm:text-3xl font-bold text-[#1A1A1A] tracking-tight">
              {t("lp_compare_title")}
            </h2>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {/* Before */}
            <div className="rounded-[12px] border border-[#E5E3DF] bg-[#F8F7F5] p-6 space-y-4">
              <div className="flex items-center gap-2 text-sm font-bold text-[#A33C29]">
                <span className="w-6 h-6 rounded-full bg-[#FBEAE6] flex items-center justify-center">
                  <X className="w-3.5 h-3.5 text-[#A33C29]" />
                </span>
                <span>{t("lp_compare_before_title")}</span>
              </div>
              <ul className="space-y-3 text-sm text-[#4A4A4A]">
                {[
                  t("lp_compare_before_1"),
                  t("lp_compare_before_2"),
                  t("lp_compare_before_3"),
                  t("lp_compare_before_4"),
                ].map((line) => (
                  <li key={line} className="flex items-start gap-2.5">
                    <X className="w-4 h-4 text-[#A33C29] shrink-0 mt-0.5" />
                    <span>{line}</span>
                  </li>
                ))}
              </ul>
            </div>

            {/* After */}
            <div className="rounded-[12px] border border-[#1B5888]/30 bg-gradient-to-br from-[#FFFFFF] to-[#E5EEF6]/45 p-6 space-y-4 shadow-[0_2px_12px_rgba(27,88,136,0.08)]">
              <div className="flex items-center gap-2 text-sm font-bold text-[#2A6E43]">
                <span className="w-6 h-6 rounded-full bg-[#E6F3EA] flex items-center justify-center">
                  <Check className="w-3.5 h-3.5 text-[#2A6E43]" />
                </span>
                <span>{t("lp_compare_after_title")}</span>
              </div>
              <ul className="space-y-3 text-sm text-[#1A1A1A] font-medium">
                {[
                  t("lp_compare_after_1"),
                  t("lp_compare_after_2"),
                  t("lp_compare_after_3"),
                  t("lp_compare_after_4"),
                ].map((line) => (
                  <li key={line} className="flex items-start gap-2.5">
                    <CheckCircle2 className="w-4 h-4 text-[#2A6E43] shrink-0 mt-0.5" />
                    <span>{line}</span>
                  </li>
                ))}
              </ul>
            </div>
          </div>
        </div>
      </section>

      {/* ========================================================================= */}
      {/* SECTION 3: INTERACTIVE 5-MODULE SUITE SHOWCASE                            */}
      {/* ========================================================================= */}
      <section className="py-14 lg:py-20 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto w-full space-y-8">
        <div className="max-w-3xl space-y-2">
          <span className="inline-flex items-center px-2.5 py-1 rounded-[6px] bg-[#E5EEF6] text-[#1B5888] text-xs font-bold">
            {t("lp_modules_badge")}
          </span>
          <h2 className="font-[family-name:var(--font-outfit)] text-2xl sm:text-3xl font-bold text-[#1A1A1A] tracking-tight">
            {t("lp_modules_title")}
          </h2>
          <p className="text-sm sm:text-base text-[#4A4A4A] leading-relaxed">
            {t("lp_modules_subtitle")}
          </p>
        </div>

        {/* Module Selector Pills */}
        <div className="flex flex-wrap gap-2">
          {modules.map((mod) => {
            const Icon = mod.icon;
            const isActive = mod.id === activeModule;
            return (
              <button
                key={mod.id}
                type="button"
                onClick={() => setActiveModule(mod.id)}
                className={`inline-flex items-center gap-2 px-4 py-2.5 rounded-[10px] text-xs sm:text-sm font-bold transition-all cursor-pointer border ${
                  isActive
                    ? "bg-[#1B5888] text-white border-[#1B5888] shadow-xs"
                    : "bg-white text-[#4A4A4A] border-[#E5E3DF] hover:border-[#1B5888]/40 hover:text-[#1A1A1A]"
                }`}
              >
                <Icon className="w-4 h-4 shrink-0" />
                <span>{mod.label}</span>
              </button>
            );
          })}
        </div>

        {/* Active Module Detail + Live UI Preview */}
        <div className="st-card p-6 sm:p-8 grid grid-cols-1 lg:grid-cols-12 gap-8 items-center">
          <div className="lg:col-span-6 space-y-4">
            <h3 className="font-[family-name:var(--font-outfit)] text-xl sm:text-2xl font-bold text-[#1A1A1A] leading-snug">
              {currentModule.title}
            </h3>
            <p className="text-sm text-[#4A4A4A] leading-relaxed">
              {currentModule.desc}
            </p>
            <ul className="space-y-2.5 pt-1">
              {currentModule.bullets.map((b) => (
                <li key={b} className="flex items-start gap-2.5 text-sm text-[#1A1A1A] font-medium">
                  <CheckCircle2 className="w-4 h-4 text-[#2A6E43] shrink-0 mt-0.5" />
                  <span>{b}</span>
                </li>
              ))}
            </ul>
            <div className="pt-2">
              <Link
                href="/agency-panel"
                className="inline-flex items-center gap-2 text-sm font-bold text-[#1B5888] hover:text-[#12406A]"
              >
                <span>{t("lp_hero_cta_demo")}</span>
                <ArrowRight className="w-4 h-4" />
              </Link>
            </div>
          </div>

          <div className="lg:col-span-6">
            <div className="rounded-[12px] border border-[#E5E3DF] bg-white p-4 sm:p-5 shadow-[0_4px_20px_rgba(18,64,106,0.07)]">
              {renderModulePreview(activeModule)}
            </div>
          </div>
        </div>
      </section>

      {/* ========================================================================= */}
      {/* SECTION 4: 4-STAGE END-TO-END LIFECYCLE                                   */}
      {/* ========================================================================= */}
      <section className="py-14 lg:py-18 px-4 sm:px-6 lg:px-8 bg-white border-y border-[#E5E3DF]">
        <div className="max-w-7xl mx-auto space-y-8">
          <div className="max-w-2xl space-y-2">
            <span className="inline-flex items-center px-2.5 py-1 rounded-[6px] bg-[#E5EEF6] text-[#1B5888] text-xs font-bold">
              {t("lp_flow_badge")}
            </span>
            <h2 className="font-[family-name:var(--font-outfit)] text-2xl sm:text-3xl font-bold text-[#1A1A1A] tracking-tight">
              {t("lp_flow_title")}
            </h2>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
            {[
              { num: "01", icon: Globe, title: t("lp_flow_s1_title"), desc: t("lp_flow_s1_desc") },
              { num: "02", icon: FileText, title: t("lp_flow_s2_title"), desc: t("lp_flow_s2_desc") },
              { num: "03", icon: Wallet, title: t("lp_flow_s3_title"), desc: t("lp_flow_s3_desc") },
              { num: "04", icon: Wrench, title: t("lp_flow_s4_title"), desc: t("lp_flow_s4_desc") },
            ].map((step) => {
              const Icon = step.icon;
              return (
                <div
                  key={step.num}
                  className="rounded-[12px] border border-[#E5E3DF] bg-[#F8F7F5] p-5 space-y-3"
                >
                  <div className="flex items-center justify-between">
                    <span className="font-mono text-xs font-bold px-2 py-0.5 rounded-[6px] bg-[#E5EEF6] text-[#1B5888]">
                      {step.num}
                    </span>
                    <Icon className="w-4 h-4 text-[#1B5888]" />
                  </div>
                  <h3 className="font-[family-name:var(--font-outfit)] text-base font-bold text-[#1A1A1A]">
                    {step.title}
                  </h3>
                  <p className="text-xs text-[#4A4A4A] leading-relaxed">{step.desc}</p>
                </div>
              );
            })}
          </div>
        </div>
      </section>

      {/* ========================================================================= */}
      {/* SECTION 5: BUILT FOR SERBIA + CLIENT MOBILE APP ADVANTAGE                 */}
      {/* ========================================================================= */}
      <section className="py-14 lg:py-20 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto w-full">
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-stretch">
          {/* Local Market Readiness */}
          <div className="lg:col-span-7 st-card p-6 sm:p-8 flex flex-col justify-between space-y-5">
            <div className="space-y-3">
              <span className="inline-flex items-center px-2.5 py-1 rounded-[6px] bg-[#E5EEF6] text-[#1B5888] text-xs font-bold">
                {t("lp_region_badge")}
              </span>
              <h2 className="font-[family-name:var(--font-outfit)] text-2xl font-bold text-[#1A1A1A] tracking-tight">
                {t("lp_region_title")}
              </h2>
              <p className="text-sm text-[#4A4A4A] leading-relaxed">{t("lp_region_desc")}</p>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 pt-2">
              {[
                t("lp_region_p1"),
                t("lp_region_p2"),
                t("lp_region_p3"),
                t("lp_region_p4"),
              ].map((pt) => (
                <div
                  key={pt}
                  className="rounded-[10px] border border-[#E5E3DF] bg-[#F8F7F5] p-3.5 flex items-start gap-2.5 text-xs font-semibold text-[#1A1A1A]"
                >
                  <CheckCircle2 className="w-4 h-4 text-[#2A6E43] shrink-0 mt-0.5" />
                  <span>{pt}</span>
                </div>
              ))}
            </div>
          </div>

          {/* Mobile App Client Portal Card */}
          <div className="lg:col-span-5 rounded-[12px] bg-gradient-to-br from-[#0E3152] to-[#1B5888] text-white p-6 sm:p-8 border border-[#3B82B8]/40 flex flex-col justify-between space-y-6">
            <div className="space-y-3">
              <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-[6px] bg-white/15 border border-white/20 text-[#E5EEF6] text-xs font-bold">
                <Smartphone className="w-3.5 h-3.5" />
                <span>{t("lp_mobile_badge")}</span>
              </span>
              <h2 className="font-[family-name:var(--font-outfit)] text-2xl font-bold text-white tracking-tight">
                {t("lp_mobile_title")}
              </h2>
              <p className="text-sm text-[#D8E7F5] leading-relaxed">{t("lp_mobile_desc")}</p>
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
                    className="h-10 w-[132px] block invert"
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
                    className="h-10 w-[132px] block"
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

      {/* ========================================================================= */}
      {/* SECTION 6: FAQ ACCORDION                                                  */}
      {/* ========================================================================= */}
      <section className="py-14 px-4 sm:px-6 lg:px-8 bg-white border-t border-[#E5E3DF]">
        <div className="max-w-4xl mx-auto space-y-6">
          <div className="space-y-2 text-center">
            <span className="inline-flex items-center px-2.5 py-1 rounded-[6px] bg-[#E5EEF6] text-[#1B5888] text-xs font-bold">
              {t("lp_faq_badge")}
            </span>
            <h2 className="font-[family-name:var(--font-outfit)] text-2xl sm:text-3xl font-bold text-[#1A1A1A] tracking-tight">
              {t("lp_faq_title")}
            </h2>
          </div>

          <div className="divide-y divide-[#E5E3DF] border border-[#E5E3DF] rounded-[12px] bg-[#F8F7F5] overflow-hidden">
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
                      className={`w-4 h-4 text-[#666666] shrink-0 transition-transform ${
                        isOpen ? "rotate-180 text-[#1B5888]" : ""
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

      {/* ========================================================================= */}
      {/* SECTION 7: FINAL CONVERSION BANNER                                        */}
      {/* ========================================================================= */}
      <section className="py-14 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto w-full">
        <div className="relative overflow-hidden rounded-[16px] bg-gradient-to-br from-[#0E3152] via-[#1B5888] to-[#12406A] text-white p-8 sm:p-12 text-center space-y-5 shadow-[0_14px_36px_rgba(18,64,106,0.2)]">
          <h2 className="font-[family-name:var(--font-outfit)] text-2xl sm:text-3xl lg:text-4xl font-bold text-white tracking-tight max-w-2xl mx-auto">
            {t("lp_cta_title")}
          </h2>
          <p className="text-sm sm:text-base text-[#D8E7F5] max-w-xl mx-auto leading-relaxed">
            {t("lp_cta_desc")}
          </p>
          <div className="flex flex-wrap items-center justify-center gap-3 pt-2">
            <Link
              href="/agency-panel"
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

      {/* ========================================================================= */}
      {/* FOOTER                                                                    */}
      {/* ========================================================================= */}
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
