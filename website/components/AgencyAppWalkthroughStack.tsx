"use client";

import React, { useState, useEffect } from "react";
import { useLanguage } from "./LanguageProvider";
import {
  Building2,
  Home,
  CheckCircle2,
  Clock,
  AlertCircle,
  FileText,
  Wrench,
  Flame,
  DollarSign,
  Receipt,
  Zap,
  Eye,
  Check,
  X,
  Sparkles,
  Search,
  ArrowUpDown,
  FileCheck2,
  UserCheck,
  Users,
  ShieldCheck,
  CreditCard,
  KeyRound,
  FileSpreadsheet,
  Bell,
  Settings,
  LayoutDashboard,
  Wallet,
  Calendar,
  MapPin,
  ChevronRight,
  ChevronLeft,
  Plus,
  MoreVertical,
  ScrollText,
  History,
} from "lucide-react";

export function AgencyAppWalkthroughStack() {
  const { lang } = useLanguage();
  const [activeStep, setActiveStep] = useState(0);

  // Real-time scroll observer to automatically highlight the current card's step box
  useEffect(() => {
    const handleScroll = () => {
      const cardIds = [
        "walkthrough-card-0",
        "walkthrough-card-1",
        "walkthrough-card-2",
        "walkthrough-card-3",
        "walkthrough-card-4",
        "walkthrough-card-5",
      ];
      const triggerY = 220; // threshold near sticky top

      let currentActive = 0;
      for (let i = 0; i < cardIds.length; i++) {
        const el = document.getElementById(cardIds[i]);
        if (el) {
          const rect = el.getBoundingClientRect();
          if (rect.top <= triggerY) {
            currentActive = i;
          }
        }
      }
      setActiveStep((prev) => {
        if (prev !== currentActive) {
          const navBtn = document.getElementById(`walkthrough-nav-step-${currentActive}`);
          if (navBtn) {
            navBtn.scrollIntoView({ behavior: "smooth", inline: "center", block: "nearest" });
          }
        }
        return currentActive;
      });
    };

    window.addEventListener("scroll", handleScroll, { passive: true });
    handleScroll();
    return () => window.removeEventListener("scroll", handleScroll);
  }, []);

  const scrollToCard = (index: number) => {
    const el = document.getElementById(`walkthrough-card-${index}`);
    if (el) {
      const topOffset = 110 + index * 12;
      const elPosition = el.getBoundingClientRect().top + window.pageYOffset;
      window.scrollTo({
        top: elPosition - topOffset,
        behavior: "smooth",
      });
      const navBtn = document.getElementById(`walkthrough-nav-step-${index}`);
      if (navBtn) {
        navBtn.scrollIntoView({ behavior: "smooth", inline: "center", block: "nearest" });
      }
    }
  };

  const isTR = lang === "TR";
  const isSR = lang === "SR_LAT" || lang === "SR_CYR";

  const steps = [
    {
      num: 1,
      label: isTR
        ? "Acente Kokpiti"
        : isSR
        ? "Agencijski Kokpit"
        : "Agency Cockpit",
      short: isTR ? "Dashboard" : isSR ? "Kontrolna tabla" : "Dashboard",
    },
    {
      num: 2,
      label: isTR
        ? "Portföy Masası"
        : isSR
        ? "Portfolio Nekretnina"
        : "Property Portfolio",
      short: isTR ? "Portföy" : isSR ? "Portfolio" : "Portfolio",
    },
    {
      num: 3,
      label: isTR
        ? "Mülk 360° Detay"
        : isSR
        ? "360° Detalji Stana"
        : "Property 360° View",
      short: isTR ? "Mülk Detay" : isSR ? "Detalji" : "Details",
    },
    {
      num: 4,
      label: isTR
        ? "Finans & Onaylar"
        : isSR
        ? "Finansije i Odobrenja"
        : "Finance & Approvals",
      short: isTR ? "Finans" : isSR ? "Finansije" : "Finance",
    },
    {
      num: 5,
      label: isTR
        ? "Bakım & Arıza Masası"
        : isSR
        ? "Održavanje i Popravke"
        : "Maintenance & Repairs",
      short: isTR ? "Arıza Takibi" : isSR ? "Održavanje" : "Maintenance",
    },
    {
      num: 6,
      label: isTR
        ? "Dijital Mahsuplaşma"
        : isSR
        ? "Automatski Prebijanja"
        : "Digital Settlement",
      short: isTR ? "Mahsuplaşma" : isSR ? "Obračun" : "Settlement",
    },
  ];

  const cardHeightClass = "h-[520px] max-h-[520px]";
  const cardShadowClass =
    "shadow-[0_25px_60px_-15px_rgba(15,23,42,0.30),0_12px_24px_-8px_rgba(15,23,42,0.18)] ring-1 ring-slate-900/5";
  const card6ShadowClass =
    "shadow-[0_25px_60px_-15px_rgba(6,78,59,0.35),0_12px_24px_-8px_rgba(6,78,59,0.22)] ring-1 ring-emerald-950/15";

  return (
    <section className="relative py-16 sm:py-24 bg-gradient-to-b from-slate-50 via-amber-50/20 to-slate-50">
      {/* Sticky Step Navigator */}
      <div className="sticky top-16 z-50 bg-white/95 backdrop-blur-md py-2.5 sm:py-3 border-y border-slate-200 shadow-xs">
        <div className="max-w-5xl mx-auto px-2.5 sm:px-6 flex items-center justify-center sm:justify-between gap-1.5 sm:gap-2 overflow-x-auto no-scrollbar">
          {steps.map((step, idx) => {
            const isActive = activeStep === idx;
            return (
              <button
                key={idx}
                id={`walkthrough-nav-step-${idx}`}
                onClick={() => scrollToCard(idx)}
                title={step.label}
                aria-label={step.label}
                className={`flex items-center transition-all duration-200 flex-shrink-0 cursor-pointer ${
                  isActive
                    ? "bg-[#C4A47C] text-white shadow-sm gap-1.5 sm:gap-2 px-2.5 sm:px-3 py-1.5 rounded-full sm:rounded-xl"
                    : "hover:bg-slate-200/70 text-slate-600 sm:bg-slate-100/70 sm:gap-2 sm:px-3 sm:py-1.5 rounded-full sm:rounded-xl p-0"
                }`}
              >
                <span
                  className={`flex items-center justify-center font-bold transition-all duration-200 ${
                    isActive
                      ? "w-5 h-5 rounded-full text-[11px] bg-white text-[#8B6A3E]"
                      : "w-7 h-7 sm:w-5 sm:h-5 rounded-full text-[11px] bg-slate-100/90 sm:bg-white/80 text-slate-600 sm:text-slate-500 hover:bg-slate-200 sm:hover:bg-white"
                  }`}
                >
                  {step.num}
                </span>

                {/* Mobile: Active step label shows cleanly in active pill */}
                {isActive && (
                  <span className="text-[11px] font-bold leading-tight whitespace-nowrap sm:hidden pr-1">
                    {step.label}
                  </span>
                )}

                {/* Tablet (sm:): Short labels so all 6 fit easily */}
                <span className="hidden sm:inline md:hidden text-xs font-bold leading-tight whitespace-nowrap">
                  {step.short}
                </span>

                {/* Desktop (md:): Full descriptive labels */}
                <span className="hidden md:inline text-xs font-bold leading-tight whitespace-nowrap">
                  {step.label}
                </span>
              </button>
            );
          })}
        </div>
      </div>

      {/* Stacked Cards Container with ample scroll travel */}
      <div className="relative max-w-5xl mx-auto pt-6">

        {/* ═════════════════════════════════════════════════════════════════
            CARD 1: ACENTE KOKPİTİ (DASHBOARD) - EXACT STANOMER DEV UI
        ═════════════════════════════════════════════════════════════════ */}
        <div
          id="walkthrough-card-0"
          style={{ top: "110px", zIndex: 10, marginBottom: "60px", height: "520px", maxHeight: "520px" }}
          className={`sticky rounded-3xl bg-white border-2 border-slate-200/90 overflow-hidden transition-shadow duration-300 ${cardShadowClass} ${cardHeightClass}`}
        >
          {/* Top Window Header */}
          <div className="h-[40px] flex-shrink-0 bg-white px-4 sm:px-5 border-b border-slate-200/80 flex items-center justify-between gap-3">
            <div className="flex items-center gap-2.5">
              <div className="flex items-center gap-1.5">
                <span className="w-3 h-3 rounded-full bg-[#FF5F56] border border-[#E0443E]/40" />
                <span className="w-3 h-3 rounded-full bg-[#FFBD2E] border border-[#DEA123]/40" />
                <span className="w-3 h-3 rounded-full bg-[#27C93F] border border-[#1AAB29]/40" />
              </div>
              <div className="h-3.5 w-[1px] bg-slate-200 mx-1 hidden sm:block" />
              <span className="text-xs font-bold text-slate-900 tracking-tight flex items-center gap-1.5">
                Demo Real Estate
                <span className="text-[9px] font-bold text-amber-800 bg-amber-100/90 border border-amber-300 px-1.5 py-0.2 rounded">
                  {isTR ? "Örnek Acente" : isSR ? "Primer Agencije" : "Demo Agency"}
                </span>
                <span className="text-[10px] font-normal text-slate-400 hidden md:inline">• stanomer.online/app</span>
              </span>
            </div>
            <div className="flex items-center gap-2.5 text-slate-500">
              <div className="relative p-1 rounded-lg hover:bg-slate-100 cursor-pointer">
                <Bell className="w-3.5 h-3.5" />
                <span className="absolute top-1 right-1 w-1.5 h-1.5 rounded-full bg-rose-500" />
              </div>
              <Settings className="w-3.5 h-3.5" />
            </div>
          </div>

          {/* App Split Container */}
          <div className="flex h-[480px] bg-[#F8F7F4] overflow-hidden">
            {/* Real Stanomer Sidebar */}
            <div className="w-[165px] flex-shrink-0 bg-white border-r border-slate-200/80 p-3 hidden sm:flex flex-col justify-between select-none">
              <div className="space-y-4">
                <div className="flex items-center gap-2 px-1">
                  <div className="w-6 h-6 rounded-lg bg-[#C4A47C] text-white flex items-center justify-center font-black text-xs shadow-xs">
                    D
                  </div>
                  <div className="leading-tight">
                    <span className="text-[11px] font-black tracking-tight text-slate-900 block">DEMO</span>
                    <span className="text-[8px] font-bold tracking-widest text-[#A37D4C] block -mt-0.5">REAL ESTATE</span>
                  </div>
                </div>

                <nav className="space-y-1">
                  <div className="flex items-center gap-2 px-2.5 py-1.5 rounded-xl text-xs bg-[#F1ECE4] text-[#8B6A3E] font-bold shadow-xs">
                    <LayoutDashboard className="w-3.5 h-3.5 text-[#8B6A3E]" />
                    <span>{isTR ? "Genel Bakış" : isSR ? "Dashboard" : "Dashboard"}</span>
                  </div>
                  <div className="flex items-center gap-2 px-2.5 py-1.5 rounded-xl text-xs text-slate-600 hover:bg-slate-50 font-medium">
                    <Home className="w-3.5 h-3.5 text-slate-400" />
                    <span>{isTR ? "Portföy" : isSR ? "Portfolio" : "Portfolio"}</span>
                  </div>
                  <div className="flex items-center gap-2 px-2.5 py-1.5 rounded-xl text-xs text-slate-600 hover:bg-slate-50 font-medium">
                    <Wallet className="w-3.5 h-3.5 text-slate-400" />
                    <span>{isTR ? "Finans" : isSR ? "Finansije" : "Finance"}</span>
                  </div>
                  <div className="flex items-center gap-2 px-2.5 py-1.5 rounded-xl text-xs text-slate-600 hover:bg-slate-50 font-medium">
                    <Wrench className="w-3.5 h-3.5 text-slate-400" />
                    <span>{isTR ? "Bakım & Arıza" : isSR ? "Održavanje" : "Maintenance"}</span>
                  </div>
                </nav>
              </div>

              <div className="pt-2 border-t border-slate-100 flex items-center justify-between text-[10px] text-slate-400">
                <span>{isTR ? "Sürüm 2.0.2" : "Verzija 2.0.2"}</span>
                <span className="w-2 h-2 rounded-full bg-emerald-500" />
              </div>
            </div>

            {/* Dashboard Content Canvas */}
            <div className="flex-1 p-3.5 sm:p-4 flex flex-col justify-between overflow-hidden">
              <div className="space-y-3">
                {/* Greeting Card with Gold Accent */}
                <div className="bg-white rounded-2xl p-3 sm:p-3.5 border border-slate-200/80 shadow-xs flex items-center justify-between">
                  <div className="space-y-0.5">
                    <h4 className="text-xs sm:text-sm font-bold text-slate-900">
                      {isTR ? "Hoş Geldiniz, Demo Yönetici 👋" : isSR ? "Dobrodošli, Demo Admin 👋" : "Welcome, Demo Admin 👋"}
                    </h4>
                    <p className="text-[11px] text-slate-500 font-medium">
                      Demo Real Estate ({isTR ? "Örnek Acente" : isSR ? "Primer Agencije" : "Demo Agency"}) • admin@demo-realestate.rs
                    </p>
                  </div>
                  <div className="flex items-center gap-1.5">
                    <span className="px-2.5 py-1 rounded-full bg-amber-50 text-[#8B6A3E] text-[11px] font-bold border border-amber-200/60">
                      {isTR ? "68 Aktif Mülk" : isSR ? "68 Aktivnih nekretnina" : "68 Active Properties"}
                    </span>
                    <span className="px-2.5 py-1 rounded-full bg-emerald-50 text-emerald-800 text-[11px] font-bold border border-emerald-200/60">
                      {isTR ? "%96 Doluluk" : isSR ? "96% Popunjenost" : "96% Occupancy"}
                    </span>
                  </div>
                </div>

                {/* Real Notification Action Rows */}
                <div className="space-y-2">
                  <div className="bg-white rounded-2xl p-3 border border-slate-200/80 shadow-xs hover:border-[#C4A47C]/40 transition-colors flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <div className="w-8 h-8 rounded-xl bg-amber-50 border border-amber-200 flex items-center justify-center text-amber-700 font-bold text-xs flex-shrink-0">
                        ⏳
                      </div>
                      <div>
                        <h5 className="text-xs font-bold text-slate-900">
                          {isTR ? "Süresi Yaklaşan Sözleşmeler" : isSR ? "Ugovori koji uskoro ističu" : "Contracts Expiring Soon"}
                        </h5>
                        <p className="text-[11px] text-slate-500">
                          {isTR ? "Önümüzdeki 30 gün içinde 3 sözleşme sona eriyor" : isSR ? "3 ugovora ističu u narednih 30 dana" : "3 contracts expire in next 30 days"}
                        </p>
                      </div>
                    </div>
                    <span className="text-xs font-bold text-[#8B6A3E] hover:underline cursor-pointer flex-shrink-0">
                      {isTR ? "Yenilemeleri Gör →" : isSR ? "Pregledaj ugovore →" : "View Renewals →"}
                    </span>
                  </div>

                  <div className="bg-white rounded-2xl p-3 border border-slate-200/80 shadow-xs hover:border-[#C4A47C]/40 transition-colors flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <div className="w-8 h-8 rounded-xl bg-orange-50 border border-orange-200 flex items-center justify-center text-orange-700 font-bold text-xs flex-shrink-0">
                        🔧
                      </div>
                      <div>
                        <h5 className="text-xs font-bold text-slate-900">
                          {isTR ? "Bekleyen Bakım Talepleri" : isSR ? "Zahtevi za održavanje na čekanju" : "Pending Maintenance Requests"}
                        </h5>
                        <p className="text-[11px] text-slate-500">
                          {isTR ? "Acente veya ev sahibi onayı bekleyen 1 açık arıza" : isSR ? "1 otvoren kvar čeka odobrenje agencije" : "1 open issue awaiting agency approval"}
                        </p>
                      </div>
                    </div>
                    <span className="text-xs font-bold text-[#8B6A3E] hover:underline cursor-pointer flex-shrink-0">
                      {isTR ? "Talebi Aç →" : isSR ? "Upravljaj kvarom →" : "Open Request →"}
                    </span>
                  </div>

                  <div className="bg-white rounded-2xl p-3 border border-slate-200/80 shadow-xs hover:border-[#C4A47C]/40 transition-colors flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <div className="w-8 h-8 rounded-xl bg-blue-50 border border-blue-200 flex items-center justify-center text-blue-700 font-bold text-xs flex-shrink-0">
                        💳
                      </div>
                      <div>
                        <h5 className="text-xs font-bold text-slate-900">
                          {isTR ? "Ödeme Onay Kuyruğu" : isSR ? "Red za odobrenje plaćanja" : "Payment Approval Queue"}
                        </h5>
                        <p className="text-[11px] text-slate-500">
                          {isTR ? "3 yeni kiracı dekontu inceleme bekliyor (1.850 €)" : isSR ? "3 nove uplatnice čekaju verifikaciju (1.850 €)" : "3 new receipts awaiting verification (€1,850)"}
                        </p>
                      </div>
                    </div>
                    <span className="text-xs font-bold text-[#8B6A3E] hover:underline cursor-pointer flex-shrink-0">
                      {isTR ? "Hemen İncele →" : isSR ? "Otvori uplatnice →" : "Review Now →"}
                    </span>
                  </div>
                </div>
              </div>

              {/* Bottom Quick Action Bar */}
              <div className="flex items-center justify-between pt-1 border-t border-slate-200/60 text-xs">
                <div className="flex items-center gap-2 text-[11px] text-slate-500">
                  <span className="w-2 h-2 rounded-full bg-emerald-500" />
                  <span>{isTR ? "Tüm sistemler aktif & senkronize" : isSR ? "Sistem ažuran i sinhronizovan" : "All systems active & synced"}</span>
                </div>
                <div className="flex items-center gap-2">
                  <button className="px-2.5 py-1 rounded-xl bg-[#C4A47C] text-white font-bold text-[11px] hover:bg-[#B59461] transition-colors shadow-xs flex items-center gap-1">
                    <Plus className="w-3 h-3" />
                    <span>{isTR ? "Mülk Ekle" : isSR ? "Dodaj nekretninu" : "Add Property"}</span>
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Scroll travel spacer between Card 1 and Card 2 */}
        <div style={{ height: "65vh" }} aria-hidden="true" />

        {/* ═════════════════════════════════════════════════════════════════
            CARD 2: PORTFÖY MASASI (PORTFOLIO) - EXACT STANOMER DEV UI
        ═════════════════════════════════════════════════════════════════ */}
        <div
          id="walkthrough-card-1"
          style={{ top: "122px", zIndex: 20, marginBottom: "48px", height: "520px", maxHeight: "520px" }}
          className={`sticky rounded-3xl bg-white border-2 border-slate-200/90 overflow-hidden transition-shadow duration-300 ${cardShadowClass} ${cardHeightClass}`}
        >
          {/* Top Window Header */}
          <div className="h-[40px] flex-shrink-0 bg-white px-4 sm:px-5 border-b border-slate-200/80 flex items-center justify-between gap-3">
            <div className="flex items-center gap-2.5">
              <div className="flex items-center gap-1.5">
                <span className="w-3 h-3 rounded-full bg-[#FF5F56] border border-[#E0443E]/40" />
                <span className="w-3 h-3 rounded-full bg-[#FFBD2E] border border-[#DEA123]/40" />
                <span className="w-3 h-3 rounded-full bg-[#27C93F] border border-[#1AAB29]/40" />
              </div>
              <div className="h-3.5 w-[1px] bg-slate-200 mx-1 hidden sm:block" />
              <span className="text-xs font-bold text-slate-900 tracking-tight flex items-center gap-1.5">
                Demo Real Estate
                <span className="text-[10px] font-normal text-slate-400 hidden md:inline">• {isTR ? "Portföy Masası" : isSR ? "Portfolio" : "Portfolio"}</span>
              </span>
            </div>
            <div className="flex items-center gap-2.5 text-slate-500">
              <Bell className="w-3.5 h-3.5" />
              <Settings className="w-3.5 h-3.5" />
            </div>
          </div>

          {/* App Split Container */}
          <div className="flex h-[480px] bg-[#F8F7F4] overflow-hidden">
            {/* Real Stanomer Sidebar */}
            <div className="w-[165px] flex-shrink-0 bg-white border-r border-slate-200/80 p-3 hidden sm:flex flex-col justify-between select-none">
              <div className="space-y-4">
                <div className="flex items-center gap-2 px-1">
                  <div className="w-6 h-6 rounded-lg bg-[#C4A47C] text-white flex items-center justify-center font-black text-xs shadow-xs">
                    D
                  </div>
                  <div className="leading-tight">
                    <span className="text-[11px] font-black tracking-tight text-slate-900 block">DEMO</span>
                    <span className="text-[8px] font-bold tracking-widest text-[#A37D4C] block -mt-0.5">REAL ESTATE</span>
                  </div>
                </div>

                <nav className="space-y-1">
                  <div className="flex items-center gap-2 px-2.5 py-1.5 rounded-xl text-xs text-slate-600 hover:bg-slate-50 font-medium">
                    <LayoutDashboard className="w-3.5 h-3.5 text-slate-400" />
                    <span>{isTR ? "Genel Bakış" : isSR ? "Dashboard" : "Dashboard"}</span>
                  </div>
                  <div className="flex items-center gap-2 px-2.5 py-1.5 rounded-xl text-xs bg-[#F1ECE4] text-[#8B6A3E] font-bold shadow-xs">
                    <Home className="w-3.5 h-3.5 text-[#8B6A3E]" />
                    <span>{isTR ? "Portföy" : isSR ? "Portfolio" : "Portfolio"}</span>
                  </div>
                  <div className="flex items-center gap-2 px-2.5 py-1.5 rounded-xl text-xs text-slate-600 hover:bg-slate-50 font-medium">
                    <Wallet className="w-3.5 h-3.5 text-slate-400" />
                    <span>{isTR ? "Finans" : isSR ? "Finansije" : "Finance"}</span>
                  </div>
                  <div className="flex items-center gap-2 px-2.5 py-1.5 rounded-xl text-xs text-slate-600 hover:bg-slate-50 font-medium">
                    <Wrench className="w-3.5 h-3.5 text-slate-400" />
                    <span>{isTR ? "Bakım & Arıza" : isSR ? "Održavanje" : "Maintenance"}</span>
                  </div>
                </nav>
              </div>

              <div className="pt-2 border-t border-slate-100 flex items-center justify-between text-[10px] text-slate-400">
                <span>{isTR ? "Toplam 68 Mülk" : "Ukupno 68 stanova"}</span>
                <span className="w-2 h-2 rounded-full bg-emerald-500" />
              </div>
            </div>

            {/* Portfolio List Canvas */}
            <div className="flex-1 p-3.5 sm:p-4 flex flex-col justify-between overflow-hidden">
              <div className="space-y-2.5">
                {/* Search and Filters Bar from Screen */}
                <div className="bg-white rounded-2xl p-2.5 sm:p-3 border border-slate-200/80 shadow-xs space-y-2">
                  <div className="relative">
                    <Search className="w-3.5 h-3.5 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
                    <input
                      type="text"
                      readOnly
                      value=""
                      placeholder={isTR ? "Ev sahibi, kiracı, şehir veya mülk ara..." : isSR ? "Pretraži vlasnika, stanara, grad ili nekretninu..." : "Search owner, tenant, city or property..."}
                      className="w-full pl-8 pr-3 py-1.5 rounded-xl bg-slate-50 border border-slate-200 text-xs text-slate-800 placeholder-slate-400"
                    />
                  </div>

                  {/* Filter chips from screen */}
                  <div className="flex items-center gap-1.5 text-[10px] overflow-x-auto">
                    <span className="bg-[#C4A47C] text-white px-2.5 py-1 rounded-full font-bold shadow-xs whitespace-nowrap">
                      {isTR ? "Tümü (68)" : isSR ? "Sve (68)" : "All (68)"}
                    </span>
                    <span className="bg-white text-slate-600 border border-slate-200 px-2.5 py-1 rounded-full font-medium whitespace-nowrap">
                      {isTR ? "⚠️ Borçlu (2)" : isSR ? "⚠️ Sa dugom (2)" : "⚠️ Overdue (2)"}
                    </span>
                    <span className="bg-white text-slate-600 border border-slate-200 px-2.5 py-1 rounded-full font-medium whitespace-nowrap">
                      {isTR ? "🟢 Kirada (65)" : isSR ? "🟢 Zauzeto (65)" : "🟢 Occupied (65)"}
                    </span>
                    <span className="bg-white text-slate-600 border border-slate-200 px-2.5 py-1 rounded-full font-medium whitespace-nowrap">
                      {isTR ? "🟠 Boşta (3)" : isSR ? "🟠 Prazno (3)" : "🟠 Vacant (3)"}
                    </span>
                  </div>
                </div>

                {/* Real Property Cards with Debt Strip */}
                <div className="space-y-2">
                  {/* Property 1 */}
                  <div className="bg-white rounded-2xl p-3 border border-slate-200/80 shadow-xs hover:border-[#C4A47C]/40 transition-colors">
                    <div className="flex items-start justify-between">
                      <div className="space-y-1">
                        <div className="flex items-center gap-2">
                          <h5 className="text-xs font-bold text-slate-900">
                            Bulevar Evrope 82, Lamele B, Stan 15, Novi Sad
                          </h5>
                        </div>
                        <p className="text-[11px] text-slate-500">
                          {isTR ? "Ev Sahibi: Nikola Jovanović • Kiracı: Mirjana Marković" : isSR ? "Vlasnik: Nikola Jovanović • Stanar: Mirjana Marković" : "Landlord: Nikola Jovanović • Tenant: Mirjana Marković"}
                        </p>
                        <div className="flex items-center gap-2 text-[10px] text-slate-400">
                          <span>68 m² • 2.5 {isTR ? "Oda" : isSR ? "Soba" : "Rooms"} • 4. {isTR ? "Kat" : isSR ? "Sprat" : "Floor"}</span>
                          <span className="text-emerald-700 bg-emerald-50 px-1.5 py-0.2 rounded font-bold border border-emerald-200">
                            {isTR ? "Aktif Sözleşme" : isSR ? "Aktivni ugovor" : "Active Lease"}
                          </span>
                        </div>
                      </div>
                      <div className="text-right space-y-1">
                        <span className="text-xs sm:text-sm font-black text-slate-900 block">750 €</span>
                        <span className="text-[9px] text-emerald-600 bg-emerald-50 px-1.5 py-0.5 rounded font-bold">
                          {isTR ? "Borç Yok ✓" : isSR ? "Nema duga ✓" : "No Debt ✓"}
                        </span>
                      </div>
                    </div>
                  </div>

                  {/* Property 2: with Overdue Warning Bar */}
                  <div className="bg-white rounded-2xl p-3 border-l-4 border-l-rose-500 border-y border-r border-slate-200/80 shadow-xs">
                    <div className="flex items-start justify-between">
                      <div className="space-y-1">
                        <div className="flex items-center gap-2">
                          <h5 className="text-xs font-bold text-slate-900">
                            Bulevar Oslobođenja 45, Stan 8, Novi Sad
                          </h5>
                        </div>
                        <p className="text-[11px] text-slate-500">
                          {isTR ? "Ev Sahibi: Vladimir Petrović • Kiracı: Stefan Đorđević" : isSR ? "Vlasnik: Vladimir Petrović • Stanar: Stefan Đorđević" : "Landlord: Vladimir Petrović • Tenant: Stefan Đorđević"}
                        </p>
                        <div className="flex items-center gap-2 text-[10px]">
                          <span className="text-slate-400">45 m² • 1.5 {isTR ? "Oda" : isSR ? "Soba" : "Rooms"}</span>
                          <span className="text-rose-700 bg-rose-50 px-1.5 py-0.2 rounded font-bold border border-rose-200 flex items-center gap-1">
                            <AlertCircle className="w-2.5 h-2.5" />
                            {isTR ? "1 Gecikmiş Kira" : isSR ? "1 zakašnjela kirija" : "1 Overdue Rent"}
                          </span>
                        </div>
                      </div>
                      <div className="text-right space-y-1">
                        <span className="text-xs sm:text-sm font-black text-rose-700 block">650 €</span>
                        <button className="text-[10px] font-bold text-blue-600 hover:underline">
                          {isTR ? "Detayı Aç →" : isSR ? "Otvori detalje →" : "View Details →"}
                        </button>
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              {/* Bottom Quick Bar */}
              <div className="flex items-center justify-between pt-1 border-t border-slate-200/60 text-xs">
                <span className="text-[10px] text-slate-400">
                  {isTR ? "Gruplama: Yok • Sıralama: En Yeniler" : isSR ? "Grupisanje: Nema • Sortiraj: Najnovije" : "Grouping: None • Sort: Newest"}
                </span>
                <span className="font-bold text-[#8B6A3E] text-xs">
                  {isTR ? "Sayfa 1 / 7" : "Strana 1 od 7"}
                </span>
              </div>
            </div>
          </div>
        </div>

        {/* Scroll travel spacer between Card 2 and Card 3 */}
        <div style={{ height: "65vh" }} aria-hidden="true" />

        {/* ═════════════════════════════════════════════════════════════════
            CARD 3: MÜLK 360° DETAY - EXACT STANOMER PROPERTY DETAIL SCREEN
        ═════════════════════════════════════════════════════════════════ */}
        <div
          id="walkthrough-card-2"
          style={{ top: "134px", zIndex: 30, marginBottom: "36px", height: "520px", maxHeight: "520px" }}
          className={`sticky rounded-3xl bg-white border-2 border-slate-200/90 overflow-hidden transition-shadow duration-300 ${cardShadowClass} ${cardHeightClass}`}
        >
          {/* Top Window Header */}
          <div className="h-[40px] flex-shrink-0 bg-white px-4 sm:px-5 border-b border-slate-200/80 flex items-center justify-between gap-3">
            <div className="flex items-center gap-2.5">
              <div className="flex items-center gap-1.5">
                <span className="w-3 h-3 rounded-full bg-[#FF5F56] border border-[#E0443E]/40" />
                <span className="w-3 h-3 rounded-full bg-[#FFBD2E] border border-[#DEA123]/40" />
                <span className="w-3 h-3 rounded-full bg-[#27C93F] border border-[#1AAB29]/40" />
              </div>
              <div className="h-3.5 w-[1px] bg-slate-200 mx-1 hidden sm:block" />
              <span className="text-xs font-bold text-slate-900 tracking-tight flex items-center gap-1.5">
                Demo Real Estate
                <span className="text-[10px] font-normal text-slate-400 hidden md:inline">• Bulevar Evrope 82, Stan 15</span>
              </span>
            </div>
            <div className="flex items-center gap-2.5 text-slate-500">
              <Bell className="w-3.5 h-3.5" />
              <Settings className="w-3.5 h-3.5" />
            </div>
          </div>

          {/* App Split Container */}
          <div className="flex h-[480px] bg-[#F8F7F4] overflow-hidden">
            {/* Real Stanomer Sidebar */}
            <div className="w-[165px] flex-shrink-0 bg-white border-r border-slate-200/80 p-3 hidden sm:flex flex-col justify-between select-none">
              <div className="space-y-4">
                <div className="flex items-center gap-2 px-1">
                  <div className="w-6 h-6 rounded-lg bg-[#C4A47C] text-white flex items-center justify-center font-black text-xs shadow-xs">
                    D
                  </div>
                  <div className="leading-tight">
                    <span className="text-[11px] font-black tracking-tight text-slate-900 block">DEMO</span>
                    <span className="text-[8px] font-bold tracking-widest text-[#A37D4C] block -mt-0.5">REAL ESTATE</span>
                  </div>
                </div>

                <nav className="space-y-1">
                  <div className="flex items-center gap-2 px-2.5 py-1.5 rounded-xl text-xs text-slate-600 hover:bg-slate-50 font-medium">
                    <LayoutDashboard className="w-3.5 h-3.5 text-slate-400" />
                    <span>{isTR ? "Genel Bakış" : isSR ? "Dashboard" : "Dashboard"}</span>
                  </div>
                  <div className="flex items-center gap-2 px-2.5 py-1.5 rounded-xl text-xs bg-[#F1ECE4] text-[#8B6A3E] font-bold shadow-xs">
                    <Home className="w-3.5 h-3.5 text-[#8B6A3E]" />
                    <span>{isTR ? "Portföy" : isSR ? "Portfolio" : "Portfolio"}</span>
                  </div>
                  <div className="flex items-center gap-2 px-2.5 py-1.5 rounded-xl text-xs text-slate-600 hover:bg-slate-50 font-medium">
                    <Wallet className="w-3.5 h-3.5 text-slate-400" />
                    <span>{isTR ? "Finans" : isSR ? "Finansije" : "Finance"}</span>
                  </div>
                  <div className="flex items-center gap-2 px-2.5 py-1.5 rounded-xl text-xs text-slate-600 hover:bg-slate-50 font-medium">
                    <Wrench className="w-3.5 h-3.5 text-slate-400" />
                    <span>{isTR ? "Bakım & Arıza" : isSR ? "Održavanje" : "Maintenance"}</span>
                  </div>
                </nav>
              </div>

              <div className="pt-2 border-t border-slate-100 flex items-center justify-between text-[10px] text-slate-400">
                <span>ID: #PROP-8215</span>
                <span className="w-2 h-2 rounded-full bg-emerald-500" />
              </div>
            </div>

            {/* Property Detail Canvas (Real Stanomer PropertyDetailScreen) */}
            <div className="flex-1 p-3 sm:p-3.5 flex flex-col justify-between overflow-hidden">
              <div className="space-y-2">
                {/* 1. Ultra-Compact Role-Aware Hero Header (_PropertyDetailHeroHeader) */}
                <div className="w-full rounded-2xl bg-gradient-to-r from-[#0F172A] via-[#1E293B] to-[#0F172A] text-white p-3 border border-slate-700/60 shadow-md flex items-center justify-between">
                  <div className="flex items-center gap-2.5 min-w-0">
                    <div className="w-7 h-7 rounded-xl bg-white/10 hover:bg-white/20 border border-white/15 flex items-center justify-center cursor-pointer flex-shrink-0">
                      <ChevronLeft className="w-4 h-4 text-white" />
                    </div>
                    <div className="min-w-0">
                      <div className="flex items-center gap-2">
                        <h4 className="text-xs sm:text-sm font-black text-white truncate">
                          Bulevar Evrope 82, Stan 15
                        </h4>
                        <span className="bg-emerald-500/20 text-emerald-300 border border-emerald-500/40 text-[9px] font-bold px-1.5 py-0.2 rounded">
                          {isTR ? "🟢 Aktif Sözleşme" : isSR ? "🟢 Aktivan Ugovor" : "🟢 Active Lease"}
                        </span>
                      </div>
                      <div className="flex items-center gap-2 text-[10px] text-slate-300">
                        <span className="flex items-center gap-0.5">
                          <MapPin className="w-2.5 h-2.5 text-slate-400" />
                          Novi Sad
                        </span>
                        <span>• 68 m² • 2.5 {isTR ? "Oda" : isSR ? "Soba" : "Rooms"} • 4. {isTR ? "Kat" : isSR ? "Sprat" : "Floor"}</span>
                      </div>
                    </div>
                  </div>
                  <div className="text-right flex-shrink-0 pl-2">
                    <span className="text-sm font-black text-white block">750 €</span>
                    <span className="text-[9px] text-slate-300">{isTR ? "/ aylık kira" : isSR ? "/ mesečno" : "/ month"}</span>
                  </div>
                </div>

                {/* 2. Real Operational 4-Tab Bar (_buildMobileTabBar) */}
                <div className="bg-slate-200/80 p-1 rounded-xl flex items-center gap-1 text-xs select-none">
                  <div className="flex-1 bg-white rounded-lg py-1.5 px-2 flex items-center justify-center gap-1.5 shadow-xs font-bold text-[#8B6A3E] border border-slate-200/70">
                    <Wallet className="w-3.5 h-3.5 text-[#8B6A3E]" />
                    <span className="truncate">{isTR ? "Kira & Finans" : isSR ? "Kirija i Finansije" : "Rent & Finance"}</span>
                  </div>
                  <div className="flex-1 py-1.5 px-2 flex items-center justify-center gap-1.5 text-slate-600 hover:text-slate-900 font-medium cursor-pointer">
                    <ScrollText className="w-3.5 h-3.5 text-slate-400" />
                    <span className="truncate">{isTR ? "Sözleşme & Kiracı" : isSR ? "Ugovor i Stanar" : "Lease & Tenant"}</span>
                  </div>
                  <div className="flex-1 py-1.5 px-2 flex items-center justify-center gap-1.5 text-slate-600 hover:text-slate-900 font-medium cursor-pointer">
                    <Wrench className="w-3.5 h-3.5 text-slate-400" />
                    <span className="truncate">{isTR ? "Bakım & Arıza" : isSR ? "Održavanje" : "Maintenance"}</span>
                    <span className="bg-amber-100 text-amber-900 text-[9px] font-bold px-1 rounded-full">1</span>
                  </div>
                  <div className="flex-1 py-1.5 px-2 flex items-center justify-center gap-1.5 text-slate-600 hover:text-slate-900 font-medium cursor-pointer hidden md:flex">
                    <History className="w-3.5 h-3.5 text-slate-400" />
                    <span className="truncate">{isTR ? "İşlem Logları" : isSR ? "Dnevnik" : "Audit Log"}</span>
                  </div>
                </div>

                {/* 3. Real Financials Timeline View (_FinancialsTab from app) */}
                <div className="bg-white rounded-2xl p-2.5 sm:p-3 border border-slate-200/90 shadow-xs space-y-2">
                  <div className="flex items-center justify-between text-[11px] pb-1.5 border-b border-slate-100">
                    <span className="font-bold text-slate-800">
                      {isTR ? "Ekim 2026 Dönem Kayıtları" : isSR ? "Evidencija za Oktobar 2026" : "October 2026 Payment Records"}
                    </span>
                    <span className="text-[10px] text-emerald-700 bg-emerald-50 border border-emerald-200 px-2 py-0.5 rounded font-bold">
                      {isTR ? "Tahsilat: %100" : isSR ? "Naplata: 100%" : "Collected: 100%"}
                    </span>
                  </div>

                  {/* Payment Timeline Items */}
                  <div className="space-y-1.5">
                    {/* Item 1: Rent */}
                    <div className="flex items-center justify-between p-2 rounded-xl bg-slate-50 border border-slate-200/70 text-xs">
                      <div className="flex items-center gap-2.5">
                        <div className="w-7 h-7 rounded-lg bg-emerald-100 text-emerald-800 flex items-center justify-center flex-shrink-0">
                          <Home className="w-3.5 h-3.5" />
                        </div>
                        <div>
                          <p className="font-bold text-slate-900">{isTR ? "Aylık Kira Bedeli" : isSR ? "Mesečna kirija" : "Monthly Rent"}</p>
                          <p className="text-[10px] text-slate-500">
                            {isTR ? "Kiracı: Mirjana Marković • Vade: 05.10.2026" : isSR ? "Stanar: Mirjana Marković • Rok: 05.10.2026" : "Tenant: Mirjana Marković • Due: 05.10.2026"}
                          </p>
                        </div>
                      </div>
                      <div className="text-right">
                        <p className="font-black text-slate-900">750,00 €</p>
                        <span className="text-[9px] font-bold text-emerald-700 bg-emerald-100/80 px-1.5 py-0.2 rounded">
                          {isTR ? "✓ Tahsil Edildi" : isSR ? "✓ Naplaćeno" : "✓ Collected"}
                        </span>
                      </div>
                    </div>

                    {/* Item 2: Utility Bill (Informatika) */}
                    <div className="flex items-center justify-between p-2 rounded-xl bg-slate-50 border border-slate-200/70 text-xs">
                      <div className="flex items-center gap-2.5">
                        <div className="w-7 h-7 rounded-lg bg-amber-100 text-amber-800 flex items-center justify-center flex-shrink-0">
                          <Receipt className="w-3.5 h-3.5" />
                        </div>
                        <div>
                          <p className="font-bold text-slate-900">Informatika JKP Novi Sad</p>
                          <p className="text-[10px] text-slate-500">
                            {isTR ? "Merkezi Isıtma & Su • Fatura No: 2026-10-891" : isSR ? "Grejanje i komunalije • Račun: 2026-10-891" : "Heating & Utilities • Bill: 2026-10-891"}
                          </p>
                        </div>
                      </div>
                      <div className="text-right">
                        <p className="font-black text-slate-900">14.250 RSD</p>
                        <span className="text-[9px] font-bold text-amber-800 bg-amber-100 px-1.5 py-0.2 rounded">
                          {isTR ? "⏱️ Onay Bekliyor" : isSR ? "⏱️ Čeka odobrenje" : "⏱️ Pending"}
                        </span>
                      </div>
                    </div>

                    {/* Item 3: Electricity */}
                    <div className="flex items-center justify-between p-2 rounded-xl bg-slate-50 border border-slate-200/70 text-xs">
                      <div className="flex items-center gap-2.5">
                        <div className="w-7 h-7 rounded-lg bg-blue-100 text-blue-800 flex items-center justify-center flex-shrink-0">
                          <Zap className="w-3.5 h-3.5" />
                        </div>
                        <div>
                          <p className="font-bold text-slate-900">EPS Elektrovojvodina</p>
                          <p className="text-[10px] text-slate-500">
                            {isTR ? "Elektrik Tüketimi • Endeks: 14.820 kWh" : isSR ? "Utrošak električne energije • Stanje: 14.820 kWh" : "Electricity Consumption • Index: 14,820 kWh"}
                          </p>
                        </div>
                      </div>
                      <div className="text-right">
                        <p className="font-black text-slate-900">4.980 RSD</p>
                        <span className="text-[9px] font-bold text-emerald-700 bg-emerald-100/80 px-1.5 py-0.2 rounded">
                          {isTR ? "✓ Ödendi" : isSR ? "✓ Plaćeno" : "✓ Paid"}
                        </span>
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              {/* Bottom Quick Bar */}
              <div className="flex items-center justify-between pt-1 border-t border-slate-200/60 text-xs">
                <span className="text-[10px] text-slate-500">
                  {isTR ? "Ev Sahibi: Nikola Jovanović (%100) • Depozito: 1.500 €" : isSR ? "Vlasnik: Nikola Jovanović (100%) • Depozit: 1.500 €" : "Owner: Nikola Jovanović (100%) • Deposit: €1,500"}
                </span>
                <span className="font-bold text-[#8B6A3E] text-xs hover:underline cursor-pointer">
                  {isTR ? "Sözleşmeyi İncele →" : isSR ? "Pregledaj ugovor →" : "View Contract →"}
                </span>
              </div>
            </div>
          </div>
        </div>

        {/* Scroll travel spacer between Card 3 and Card 4 */}
        <div style={{ height: "65vh" }} aria-hidden="true" />

        {/* ═════════════════════════════════════════════════════════════════
            CARD 4: FINANSIJE & ODOBRENJE (FİNANS) - EXACT STANOMER DEV UI
        ═════════════════════════════════════════════════════════════════ */}
        <div
          id="walkthrough-card-3"
          style={{ top: "146px", zIndex: 40, marginBottom: "24px", height: "520px", maxHeight: "520px" }}
          className={`sticky rounded-3xl bg-white border-2 border-slate-200/90 overflow-hidden transition-shadow duration-300 ${cardShadowClass} ${cardHeightClass}`}
        >
          {/* Top Window Header */}
          <div className="h-[40px] flex-shrink-0 bg-white px-4 sm:px-5 border-b border-slate-200/80 flex items-center justify-between gap-3">
            <div className="flex items-center gap-2.5">
              <div className="flex items-center gap-1.5">
                <span className="w-3 h-3 rounded-full bg-[#FF5F56] border border-[#E0443E]/40" />
                <span className="w-3 h-3 rounded-full bg-[#FFBD2E] border border-[#DEA123]/40" />
                <span className="w-3 h-3 rounded-full bg-[#27C93F] border border-[#1AAB29]/40" />
              </div>
              <div className="h-3.5 w-[1px] bg-slate-200 mx-1 hidden sm:block" />
              <span className="text-xs font-bold text-slate-900 tracking-tight flex items-center gap-1.5">
                Demo Real Estate
                <span className="text-[10px] font-normal text-slate-400 hidden md:inline">• {isTR ? "Finans Masası" : isSR ? "Finansije" : "Finance"}</span>
              </span>
            </div>
            <div className="flex items-center gap-2.5 text-slate-500">
              <Bell className="w-3.5 h-3.5" />
              <Settings className="w-3.5 h-3.5" />
            </div>
          </div>

          {/* App Split Container */}
          <div className="flex h-[480px] bg-[#F8F7F4] overflow-hidden">
            {/* Real Stanomer Sidebar */}
            <div className="w-[165px] flex-shrink-0 bg-white border-r border-slate-200/80 p-3 hidden sm:flex flex-col justify-between select-none">
              <div className="space-y-4">
                <div className="flex items-center gap-2 px-1">
                  <div className="w-6 h-6 rounded-lg bg-[#C4A47C] text-white flex items-center justify-center font-black text-xs shadow-xs">
                    D
                  </div>
                  <div className="leading-tight">
                    <span className="text-[11px] font-black tracking-tight text-slate-900 block">DEMO</span>
                    <span className="text-[8px] font-bold tracking-widest text-[#A37D4C] block -mt-0.5">REAL ESTATE</span>
                  </div>
                </div>

                <nav className="space-y-1">
                  <div className="flex items-center gap-2 px-2.5 py-1.5 rounded-xl text-xs text-slate-600 hover:bg-slate-50 font-medium">
                    <LayoutDashboard className="w-3.5 h-3.5 text-slate-400" />
                    <span>{isTR ? "Genel Bakış" : isSR ? "Dashboard" : "Dashboard"}</span>
                  </div>
                  <div className="flex items-center gap-2 px-2.5 py-1.5 rounded-xl text-xs text-slate-600 hover:bg-slate-50 font-medium">
                    <Home className="w-3.5 h-3.5 text-slate-400" />
                    <span>{isTR ? "Portföy" : isSR ? "Portfolio" : "Portfolio"}</span>
                  </div>
                  <div className="flex items-center gap-2 px-2.5 py-1.5 rounded-xl text-xs bg-[#F1ECE4] text-[#8B6A3E] font-bold shadow-xs">
                    <Wallet className="w-3.5 h-3.5 text-[#8B6A3E]" />
                    <span>{isTR ? "Finans" : isSR ? "Finansije" : "Finance"}</span>
                  </div>
                  <div className="flex items-center gap-2 px-2.5 py-1.5 rounded-xl text-xs text-slate-600 hover:bg-slate-50 font-medium">
                    <Wrench className="w-3.5 h-3.5 text-slate-400" />
                    <span>{isTR ? "Bakım & Arıza" : isSR ? "Održavanje" : "Maintenance"}</span>
                  </div>
                </nav>
              </div>

              <div className="pt-2 border-t border-slate-100 flex items-center justify-between text-[10px] text-slate-400">
                <span>{isTR ? "Ekim 2026" : "Oktobar 2026"}</span>
                <span className="w-2 h-2 rounded-full bg-emerald-500" />
              </div>
            </div>

            {/* Finance Canvas (EXACT Stanomer Screenshot UI) */}
            <div className="flex-1 p-3.5 sm:p-4 flex flex-col justify-between overflow-hidden">
              <div className="space-y-2.5">
                {/* Header */}
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <Wallet className="w-4 h-4 text-[#A37D4C]" />
                    <span className="text-xs font-bold text-slate-800 uppercase tracking-wide">
                      {isTR ? "FİNANS VE ÖDEMELER" : isSR ? "FINANSIJE I PLAĆANJA" : "FINANCE & PAYMENTS"}
                    </span>
                  </div>
                  <span className="text-[11px] text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded font-bold border border-emerald-200">
                    {isTR ? "Tahsilat: %92" : "Naplata: 92%"}
                  </span>
                </div>

                {/* 2 Main Sub-Tabs: Aksiyon Alınacaklar vs Rapor (Exact Stanomer Breakdown) */}
                <div className="bg-slate-200/80 p-1 rounded-xl flex items-center gap-1 text-xs select-none">
                  <div className="flex-1 bg-white rounded-lg py-1.5 px-3 flex items-center justify-center gap-2 shadow-xs font-bold text-slate-900 border border-slate-200/70">
                    <AlertCircle className="w-3.5 h-3.5 text-amber-600 flex-shrink-0" />
                    <span>{isTR ? "Aksiyon Alınacaklar" : isSR ? "Potrebna akcija" : "Action Required"}</span>
                    <span className="bg-amber-100 text-amber-900 text-[10px] font-black px-1.5 py-0.5 rounded-full">
                      17
                    </span>
                  </div>
                  <div className="flex-1 py-1.5 px-3 flex items-center justify-center gap-2 text-slate-500 hover:text-slate-700 font-medium cursor-pointer">
                    <FileSpreadsheet className="w-3.5 h-3.5 text-slate-400 flex-shrink-0" />
                    <span>{isTR ? "Rapor" : isSR ? "Izveštaj" : "Report"}</span>
                  </div>
                </div>

                {/* 4 Exact KPI Cards From Screenshot */}
                <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
                  <div className="bg-[#FFFDF9] rounded-xl p-2 sm:p-2.5 border-2 border-[#C4A47C] shadow-xs">
                    <div className="flex items-center justify-between text-slate-600 text-[10px]">
                      <span className="flex items-center gap-1">⏱️ {isTR ? "Bekleyen" : isSR ? "Čekaju" : "Pending"}</span>
                      <span className="bg-[#C4A47C]/20 text-[#8B6A3E] font-bold px-1.5 rounded-full text-[9px]">3</span>
                    </div>
                    <p className="text-xs sm:text-sm font-black text-slate-900 mt-1">1.850,00 €</p>
                  </div>

                  <div className="bg-white rounded-xl p-2 sm:p-2.5 border border-slate-200 shadow-xs">
                    <div className="flex items-center justify-between text-slate-600 text-[10px]">
                      <span className="flex items-center gap-1">📄 {isTR ? "Girilmeyen" : isSR ? "Neuneti" : "Unentered"}</span>
                      <span className="bg-amber-100 text-amber-800 font-bold px-1.5 rounded-full text-[9px]">12</span>
                    </div>
                    <p className="text-xs sm:text-sm font-black text-slate-900 mt-1">240,00 €</p>
                  </div>

                  <div className="bg-rose-50/50 rounded-xl p-2 sm:p-2.5 border border-rose-200 shadow-xs">
                    <div className="flex items-center justify-between text-rose-800 text-[10px]">
                      <span className="flex items-center gap-1">⚠️ {isTR ? "Geciken" : isSR ? "Kašnjenja" : "Overdue"}</span>
                      <span className="bg-rose-200 text-rose-900 font-bold px-1.5 rounded-full text-[9px]">2</span>
                    </div>
                    <p className="text-xs sm:text-sm font-black text-rose-900 mt-1">1.400,00 €</p>
                  </div>

                  <div className="bg-emerald-50/50 rounded-xl p-2 sm:p-2.5 border border-emerald-200 shadow-xs">
                    <div className="flex items-center justify-between text-emerald-800 text-[10px]">
                      <span className="flex items-center gap-1">✓ {isTR ? "Onaylanan" : isSR ? "Odobreno" : "Approved"}</span>
                      <span className="bg-emerald-200 text-emerald-900 font-bold px-1.5 rounded-full text-[9px]">18</span>
                    </div>
                    <p className="text-xs sm:text-sm font-black text-emerald-900 mt-1">13.500,00 €</p>
                  </div>
                </div>

                {/* Filter Pills from Screenshot */}
                <div className="flex items-center gap-1.5 text-[10px] overflow-x-auto">
                  <span className="bg-[#B59461] text-white px-2.5 py-1 rounded-full font-bold shadow-xs whitespace-nowrap">
                    {isTR ? "Onay Kuyruğu (3)" : isSR ? "Red za odobrenje (3)" : "Approval Queue (3)"}
                  </span>
                  <span className="bg-white text-slate-600 border border-slate-200 px-2.5 py-1 rounded-full font-medium whitespace-nowrap">
                    {isTR ? "Girilmeyen Faturalar (12)" : isSR ? "Neuneti računi (12)" : "Unentered Bills (12)"}
                  </span>
                  <span className="bg-white text-slate-600 border border-slate-200 px-2.5 py-1 rounded-full font-medium whitespace-nowrap">
                    {isTR ? "Borçlular (2)" : isSR ? "Dužnici (2)" : "Debtors (2)"}
                  </span>
                  <span className="bg-white text-slate-600 border border-slate-200 px-2.5 py-1 rounded-full font-medium whitespace-nowrap">
                    {isTR ? "Ödeme Geçmişi" : isSR ? "Istorija plaćanja" : "Payment History"}
                  </span>
                </div>

                {/* Pending Transaction Card */}
                <div className="bg-white rounded-2xl p-3 border border-slate-200/90 shadow-xs space-y-2">
                  <div className="flex items-center justify-between">
                    <div>
                      <h5 className="text-xs font-bold text-slate-900">
                        {isTR ? "Bulevar Evrope 82, Daire 15 — Ekim 2026 Kirası" : isSR ? "Bulevar Evrope 82, Stan 15 — Oktobar 2026 Kirija" : "Bulevar Evrope 82, Apt 15 — October 2026 Rent"}
                      </h5>
                      <p className="text-[10px] text-slate-500">
                        {isTR ? "Kiracı: Mirjana Marković • Acente banka hesabına havale" : isSR ? "Stanar: Mirjana Marković • Uplata na račun agencije" : "Tenant: Mirjana Marković • Transfer to agency bank account"}
                      </p>
                    </div>
                    <span className="text-sm font-black text-slate-900">750,00 €</span>
                  </div>

                  <div className="bg-slate-50 rounded-lg p-2 border border-slate-200/60 flex items-center justify-between text-[11px]">
                    <div className="flex items-center gap-2 text-slate-700">
                      <FileText className="w-3.5 h-3.5 text-blue-600" />
                      <span className="font-mono text-[10px]">📎 intesa_uplata_kirija_okt.pdf</span>
                    </div>
                    <div className="flex items-center gap-1.5">
                      <button className="px-2 py-1 rounded bg-slate-100 text-slate-600 text-[10px] font-bold hover:bg-slate-200">
                        {isTR ? "Reddet" : isSR ? "Odbij" : "Reject"}
                      </button>
                      <button className="px-2.5 py-1 rounded bg-blue-600 text-white text-[10px] font-bold hover:bg-blue-700 shadow-xs">
                        {isTR ? "Acente Onayı Ver ✓" : isSR ? "Knjiži & Odobri ✓" : "Agency Approval ✓"}
                      </button>
                    </div>
                  </div>
                </div>
              </div>

              {/* Bottom Quick Note */}
              <div className="flex items-center justify-between pt-1 border-t border-slate-200/60 text-[10px] text-slate-400">
                <span>{isTR ? "Banka dekontları tek tıkla muhasebeye işlenir" : isSR ? "Uplatnice se jednim klikom knjiže u sistem" : "Receipts booked into accounting with one click"}</span>
                <span className="font-mono">REF: FIN-2026-901</span>
              </div>
            </div>
          </div>
        </div>

        {/* Scroll travel spacer between Card 4 and Card 5 */}
        <div style={{ height: "65vh" }} aria-hidden="true" />

        {/* ═════════════════════════════════════════════════════════════════
            CARD 5: BAKIM & ARIZA MASASI (MAINTENANCE) - EXACT STANOMER DEV UI
        ═════════════════════════════════════════════════════════════════ */}
        <div
          id="walkthrough-card-4"
          style={{ top: "158px", zIndex: 50, marginBottom: "12px", height: "520px", maxHeight: "520px" }}
          className={`sticky rounded-3xl bg-white border-2 border-slate-200/90 overflow-hidden transition-shadow duration-300 ${cardShadowClass} ${cardHeightClass}`}
        >
          {/* Top Window Header */}
          <div className="h-[40px] flex-shrink-0 bg-white px-4 sm:px-5 border-b border-slate-200/80 flex items-center justify-between gap-3">
            <div className="flex items-center gap-2.5">
              <div className="flex items-center gap-1.5">
                <span className="w-3 h-3 rounded-full bg-[#FF5F56] border border-[#E0443E]/40" />
                <span className="w-3 h-3 rounded-full bg-[#FFBD2E] border border-[#DEA123]/40" />
                <span className="w-3 h-3 rounded-full bg-[#27C93F] border border-[#1AAB29]/40" />
              </div>
              <div className="h-3.5 w-[1px] bg-slate-200 mx-1 hidden sm:block" />
              <span className="text-xs font-bold text-slate-900 tracking-tight flex items-center gap-1.5">
                Demo Real Estate
                <span className="text-[10px] font-normal text-slate-400 hidden md:inline">• {isTR ? "Bakım & Arıza Masası" : isSR ? "Održavanje" : "Maintenance"}</span>
              </span>
            </div>
            <div className="flex items-center gap-2.5 text-slate-500">
              <Bell className="w-3.5 h-3.5" />
              <Settings className="w-3.5 h-3.5" />
            </div>
          </div>

          {/* App Split Container */}
          <div className="flex h-[480px] bg-[#F8F7F4] overflow-hidden">
            {/* Real Stanomer Sidebar */}
            <div className="w-[165px] flex-shrink-0 bg-white border-r border-slate-200/80 p-3 hidden sm:flex flex-col justify-between select-none">
              <div className="space-y-4">
                <div className="flex items-center gap-2 px-1">
                  <div className="w-6 h-6 rounded-lg bg-[#C4A47C] text-white flex items-center justify-center font-black text-xs shadow-xs">
                    D
                  </div>
                  <div className="leading-tight">
                    <span className="text-[11px] font-black tracking-tight text-slate-900 block">DEMO</span>
                    <span className="text-[8px] font-bold tracking-widest text-[#A37D4C] block -mt-0.5">REAL ESTATE</span>
                  </div>
                </div>

                <nav className="space-y-1">
                  <div className="flex items-center gap-2 px-2.5 py-1.5 rounded-xl text-xs text-slate-600 hover:bg-slate-50 font-medium">
                    <LayoutDashboard className="w-3.5 h-3.5 text-slate-400" />
                    <span>{isTR ? "Genel Bakış" : isSR ? "Dashboard" : "Dashboard"}</span>
                  </div>
                  <div className="flex items-center gap-2 px-2.5 py-1.5 rounded-xl text-xs text-slate-600 hover:bg-slate-50 font-medium">
                    <Home className="w-3.5 h-3.5 text-slate-400" />
                    <span>{isTR ? "Portföy" : isSR ? "Portfolio" : "Portfolio"}</span>
                  </div>
                  <div className="flex items-center gap-2 px-2.5 py-1.5 rounded-xl text-xs text-slate-600 hover:bg-slate-50 font-medium">
                    <Wallet className="w-3.5 h-3.5 text-slate-400" />
                    <span>{isTR ? "Finans" : isSR ? "Finansije" : "Finance"}</span>
                  </div>
                  <div className="flex items-center gap-2 px-2.5 py-1.5 rounded-xl text-xs bg-[#F1ECE4] text-[#8B6A3E] font-bold shadow-xs">
                    <Wrench className="w-3.5 h-3.5 text-[#8B6A3E]" />
                    <span>{isTR ? "Bakım & Arıza" : isSR ? "Održavanje" : "Maintenance"}</span>
                  </div>
                </nav>
              </div>

              <div className="pt-2 border-t border-slate-100 flex items-center justify-between text-[10px] text-slate-400">
                <span>{isTR ? "Açık Biletler: 1" : "Otvoreni kvarovi: 1"}</span>
                <span className="w-2 h-2 rounded-full bg-emerald-500" />
              </div>
            </div>

            {/* Maintenance Canvas (Real Stanomer Maintenance Ticket Flow) */}
            <div className="flex-1 p-3.5 sm:p-4 flex flex-col justify-between overflow-hidden">
              <div className="space-y-2.5">
                {/* Header with Ticket ID */}
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <Wrench className="w-4 h-4 text-orange-600" />
                    <span className="text-xs font-bold text-slate-800 uppercase tracking-wide">
                      {isTR ? "BAKIM & ARIZA YÖNETİMİ" : isSR ? "OPERACIJE I ODRŽAVANJE" : "MAINTENANCE OPERATIONS"}
                    </span>
                  </div>
                  <span className="text-[10px] font-mono text-slate-500 bg-white px-2 py-0.5 rounded border border-slate-200">
                    TIK-2026-089
                  </span>
                </div>

                {/* 4-Step Maintenance Progress Bar from Flutter Code */}
                <div className="bg-white rounded-xl p-2.5 border border-slate-200/80 shadow-xs">
                  <div className="grid grid-cols-4 gap-1 text-center">
                    <div className="space-y-1">
                      <div className="h-1.5 rounded-full bg-emerald-500" />
                      <span className="text-[9px] font-bold text-emerald-800 block">
                        ✓ {isTR ? "Bildirildi" : isSR ? "Prijavljeno" : "Reported"}
                      </span>
                    </div>
                    <div className="space-y-1">
                      <div className="h-1.5 rounded-full bg-emerald-500" />
                      <span className="text-[9px] font-bold text-emerald-800 block">
                        ✓ {isTR ? "İncelendi" : isSR ? "Pregledano" : "Reviewed"}
                      </span>
                    </div>
                    <div className="space-y-1">
                      <div className="h-1.5 rounded-full bg-blue-600" />
                      <span className="text-[9px] font-bold text-blue-700 block">
                        ● {isTR ? "Usta Atandı" : isSR ? "Dodeljen majstor" : "Assigned"}
                      </span>
                    </div>
                    <div className="space-y-1">
                      <div className="h-1.5 rounded-full bg-slate-200" />
                      <span className="text-[9px] font-medium text-slate-400 block">
                        ○ {isTR ? "Çözüldü" : isSR ? "Završeno" : "Resolved"}
                      </span>
                    </div>
                  </div>
                </div>

                {/* Active Issue Card */}
                <div className="bg-white rounded-2xl p-3 border border-slate-200/90 shadow-xs space-y-2">
                  <div className="flex items-start justify-between">
                    <div>
                      <div className="flex items-center gap-2">
                        <h5 className="text-xs font-bold text-slate-900">
                          {isTR ? "Kombi Su Basıncı Düşüşü & Isıtma Arızası" : isSR ? "Pad pritiska u kotlu i problem sa grejanjem" : "Boiler Pressure Drop & Heating Issue"}
                        </h5>
                        <span className="bg-rose-100 text-rose-800 text-[9px] font-bold px-1.5 py-0.2 rounded">
                          {isTR ? "Yüksek Öncelik" : isSR ? "Visok prioritet" : "High Priority"}
                        </span>
                      </div>
                      <p className="text-[10px] text-slate-500 mt-0.5">
                        Bulevar Evrope 82, Stan 15 • {isTR ? "Bildiren: Mirjana Marković (Kiracı)" : isSR ? "Prijavila: Mirjana Marković (Stanar)" : "Reported by: Mirjana Marković (Tenant)"}
                      </p>
                    </div>
                    <span className="text-sm font-black text-slate-900">180,00 €</span>
                  </div>

                  {/* Assigned Craftsman / Payer Row from Stanomer DB */}
                  <div className="p-2 rounded-xl bg-slate-50 border border-slate-200/70 space-y-1.5 text-xs">
                    <div className="flex items-center justify-between text-[11px]">
                      <span className="text-slate-600 font-medium">
                        🔧 {isTR ? "Yetkili Servis:" : isSR ? "Ovlašćeni servis:" : "Authorized Service:"} <b>TermoServis Novi Sad (Goran M.)</b>
                      </span>
                      <span className="text-emerald-700 bg-emerald-50 px-1.5 py-0.5 rounded text-[10px] font-bold border border-emerald-200">
                        {isTR ? "Teklif Onaylandı ✓" : isSR ? "Ponuda prihvaćena ✓" : "Quote Approved ✓"}
                      </span>
                    </div>
                    <div className="flex items-center justify-between text-[10px] text-slate-500 pt-1 border-t border-slate-200/60">
                      <span>
                        💰 {isTR ? "Ödeme Sorumlusu:" : isSR ? "Trošak snosi:" : "Cost borne by:"} <b>{isTR ? "Ev Sahibi (Kira Mahsubu)" : isSR ? "Vlasnik (Odbitak od kirije)" : "Landlord (Rent Offset)"}</b>
                      </span>
                      <span className="font-mono">Faktura #INV-882</span>
                    </div>
                  </div>
                </div>
              </div>

              {/* Bottom Complete Job Button */}
              <div className="flex items-center justify-between pt-1 border-t border-slate-200/60 text-xs">
                <span className="text-[10px] text-slate-400">
                  {isTR ? "Arıza faturası bir sonraki kira ekstresine otomatik yansıtılır" : isSR ? "Faktura za radove se automatski prenosi na sledeći obračun kirije" : "Invoice will be automatically carried over to next rent statement"}
                </span>
                <button className="px-3 py-1 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-[11px] transition-colors shadow-xs">
                  {isTR ? "İşi Tamamla & Faturayı İşle →" : isSR ? "Završi radove i proknjiži →" : "Complete & Process →"}
                </button>
              </div>
            </div>
          </div>
        </div>

        {/* Scroll travel spacer between Card 5 and Card 6 */}
        <div style={{ height: "65vh" }} aria-hidden="true" />

        {/* ═════════════════════════════════════════════════════════════════
            CARD 6: DİJİTAL MAHSUPLAŞMA SİHİRBAZI - EXACT STANOMER DEV UI
        ═════════════════════════════════════════════════════════════════ */}
        <div
          id="walkthrough-card-5"
          style={{ top: "170px", zIndex: 60, marginBottom: "0px", height: "520px", maxHeight: "520px" }}
          className={`sticky rounded-3xl bg-white border-2 border-emerald-400/90 overflow-hidden transition-shadow duration-300 ${card6ShadowClass} ${cardHeightClass}`}
        >
          {/* Top Window Header */}
          <div className="h-[40px] flex-shrink-0 bg-emerald-900 text-white px-4 sm:px-5 border-b border-emerald-800 flex items-center justify-between gap-3">
            <div className="flex items-center gap-2.5">
              <div className="flex items-center gap-1.5">
                <span className="w-3 h-3 rounded-full bg-[#FF5F56] border border-[#E0443E]/40" />
                <span className="w-3 h-3 rounded-full bg-[#FFBD2E] border border-[#DEA123]/40" />
                <span className="w-3 h-3 rounded-full bg-[#27C93F] border border-[#1AAB29]/40" />
              </div>
              <div className="h-3.5 w-[1px] bg-emerald-700 mx-1 hidden sm:block" />
              <span className="text-xs font-bold text-white tracking-tight flex items-center gap-1.5">
                Demo Real Estate
                <span className="text-[10px] font-normal text-emerald-300 hidden md:inline">
                  • {isTR ? "Otomatik Mahsuplaşma & Net Hakediş" : isSR ? "Automatski Obračun i Neto Isplata" : "Automatic Settlement & Net Payout"}
                </span>
              </span>
            </div>
            <div className="flex items-center gap-2.5 text-emerald-200">
              <span className="text-[10px] bg-emerald-800/80 px-2 py-0.5 rounded font-mono">
                {isTR ? "KAPATILMIŞ DÖNEM" : isSR ? "ZAKLJUČEN PERIOD" : "CLOSED PERIOD"}
              </span>
            </div>
          </div>

          {/* App Split Container */}
          <div className="flex h-[480px] bg-[#F8F7F4] overflow-hidden">
            {/* Real Stanomer Sidebar */}
            <div className="w-[165px] flex-shrink-0 bg-white border-r border-slate-200/80 p-3 hidden sm:flex flex-col justify-between select-none">
              <div className="space-y-4">
                <div className="flex items-center gap-2 px-1">
                  <div className="w-6 h-6 rounded-lg bg-emerald-600 text-white flex items-center justify-center font-black text-xs shadow-xs">
                    D
                  </div>
                  <div className="leading-tight">
                    <span className="text-[11px] font-black tracking-tight text-slate-900 block">DEMO</span>
                    <span className="text-[8px] font-bold tracking-widest text-emerald-700 block -mt-0.5">REAL ESTATE</span>
                  </div>
                </div>

                <nav className="space-y-1">
                  <div className="flex items-center gap-2 px-2.5 py-1.5 rounded-xl text-xs text-slate-600 hover:bg-slate-50 font-medium">
                    <LayoutDashboard className="w-3.5 h-3.5 text-slate-400" />
                    <span>{isTR ? "Genel Bakış" : isSR ? "Dashboard" : "Dashboard"}</span>
                  </div>
                  <div className="flex items-center gap-2 px-2.5 py-1.5 rounded-xl text-xs text-slate-600 hover:bg-slate-50 font-medium">
                    <Home className="w-3.5 h-3.5 text-slate-400" />
                    <span>{isTR ? "Portföy" : isSR ? "Portfolio" : "Portfolio"}</span>
                  </div>
                  <div className="flex items-center gap-2 px-2.5 py-1.5 rounded-xl text-xs bg-emerald-50 text-emerald-800 font-bold shadow-xs">
                    <Receipt className="w-3.5 h-3.5 text-emerald-700" />
                    <span>{isTR ? "Mahsuplaşma" : isSR ? "Obračun" : "Settlement"}</span>
                  </div>
                  <div className="flex items-center gap-2 px-2.5 py-1.5 rounded-xl text-xs text-slate-600 hover:bg-slate-50 font-medium">
                    <Wrench className="w-3.5 h-3.5 text-slate-400" />
                    <span>{isTR ? "Bakım & Arıza" : isSR ? "Održavanje" : "Maintenance"}</span>
                  </div>
                </nav>
              </div>

              <div className="pt-2 border-t border-slate-100 flex items-center justify-between text-[10px] text-slate-400">
                <span>{isTR ? "Kayıt No: #SETT-1026" : "Obračun #SETT-1026"}</span>
                <span className="w-2 h-2 rounded-full bg-emerald-500" />
              </div>
            </div>

            {/* Settlement Canvas */}
            <div className="flex-1 p-3.5 sm:p-4 flex flex-col justify-between overflow-hidden">
              <div className="space-y-3">
                {/* Header */}
                <div className="flex items-center justify-between">
                  <div>
                    <h4 className="text-xs sm:text-sm font-black text-slate-900">
                      Bulevar Evrope 82, Stan 15 — {isTR ? "Ekim 2026 Otomatik Mahsuplaşma" : isSR ? "Oktobar 2026 Obračun i Poravnanje" : "October 2026 Settlement"}
                    </h4>
                    <p className="text-[10px] text-slate-500">
                      {isTR ? "Ev Sahibi: Nikola Jovanović • Kiracı: Mirjana Marković" : isSR ? "Vlasnik: Nikola Jovanović • Stanar: Mirjana Marković" : "Landlord: Nikola Jovanović • Tenant: Mirjana Marković"}
                    </p>
                  </div>
                  <span className="text-[10px] font-bold text-emerald-800 bg-emerald-100 px-2 py-0.5 rounded border border-emerald-200">
                    {isTR ? "Matematiksel Doğrulama ✓" : isSR ? "Tačnost 100% ✓" : "100% Verified ✓"}
                  </span>
                </div>

                {/* Calculation Ledger Card */}
                <div className="bg-white rounded-2xl p-3 border border-slate-200/90 shadow-xs space-y-2">
                  <div className="space-y-1.5 text-xs">
                    <div className="flex items-center justify-between pb-1 border-b border-slate-100">
                      <span className="text-slate-700 flex items-center gap-1.5">
                        <span className="w-2 h-2 rounded-full bg-emerald-500" />
                        {isTR ? "Aylık Tahsil Edilen Kira" : isSR ? "Mesečna naplaćena kirija" : "Monthly Collected Rent"}
                      </span>
                      <span className="font-bold text-slate-900">+750,00 €</span>
                    </div>

                    <div className="flex items-center justify-between pb-1 border-b border-slate-100 text-rose-700">
                      <span className="flex items-center gap-1.5">
                        <span className="w-2 h-2 rounded-full bg-rose-500" />
                        {isTR ? "Kombi Onarım Bedeli (Fatura No: #INV-882)" : isSR ? "Popravka kotla (Faktura #INV-882)" : "Boiler Repair (#INV-882)"}
                      </span>
                      <span className="font-bold">-180,00 €</span>
                    </div>

                    <div className="flex items-center justify-between pb-1 border-b border-slate-100 text-amber-800">
                      <span className="flex items-center gap-1.5">
                        <span className="w-2 h-2 rounded-full bg-amber-500" />
                        {isTR ? "Acente Yönetim Komisyonu (%10)" : isSR ? "Agencijska provizija (10%)" : "Agency Commission (10%)"}
                      </span>
                      <span className="font-bold">-75,00 €</span>
                    </div>

                    <div className="flex items-center justify-between pt-1 font-black text-sm bg-emerald-50/80 p-2 rounded-xl text-emerald-950 border border-emerald-200">
                      <span className="flex items-center gap-1.5">
                        <span>💰</span>
                        {isTR ? "Ev Sahibine Net Aktarılacak Tutar:" : isSR ? "Neto za isplatu vlasniku:" : "Net Payout to Landlord:"}
                      </span>
                      <span className="text-base text-emerald-700">495,00 €</span>
                    </div>
                  </div>
                </div>

                {/* Ev Sahibi Adına Acente Onayı Card */}
                <div className="bg-amber-50/60 rounded-xl p-2.5 border border-amber-200/80 flex items-center justify-between text-xs">
                  <div className="space-y-0.5">
                    <span className="text-[10px] font-bold text-amber-900 uppercase tracking-wide block">
                      {isTR ? "Ev Sahibi Adına Acente Onayı" : isSR ? "Odobrenje Agencije u Ime Vlasnika" : "Agency Approval on Behalf of Landlord"}
                    </span>
                    <p className="text-[10px] text-amber-900/80">
                      {isTR ? "08.10.2026 • 15:10 tarihinde otomatik hesap fişi oluşturuldu" : isSR ? "08.10.2026 • 15:10 kreiran automatski nalog za prenos" : "08.10.2026 • 15:10 automatic statement created"}
                    </p>
                  </div>
                  <div className="bg-amber-100 text-amber-900 border border-amber-300 rounded px-2 py-0.5 text-[10px] font-bold flex items-center gap-1">
                    <span>✓ {isTR ? "ONAYLANDI (Demo Real Estate)" : isSR ? "ODOBRENO (Demo Real Estate)" : "APPROVED (Demo Real Estate)"}</span>
                  </div>
                </div>
              </div>

              {/* Bottom Quick Note */}
              <div className="flex items-center justify-between pt-1 border-t border-slate-200/60 text-[10px] text-slate-400">
                <span>{isTR ? "Hesap ekstresi ve net transfer dekontu ev sahibi paneline anında iletildi" : isSR ? "Izvod i nalog za prenos automatski su poslati na portal vlasnika" : "Statement and net transfer slip instantly sent to landlord portal"}</span>
                <span className="font-mono text-emerald-700 font-bold">STATUS: OKTOBAR_ZATVOREN</span>
              </div>
            </div>
          </div>
        </div>

      </div>
    </section>
  );
}
