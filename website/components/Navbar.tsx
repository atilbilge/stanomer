"use client";

import React, { useState, useEffect, useRef } from "react";
import { usePathname, useRouter } from "next/navigation";
import { useLanguage, Language } from "./LanguageProvider";
import { captureUtmParams } from "../lib/utm";
import {
  ChevronDown,
  Menu,
  X,
  Building2,
  Users,
  BookOpen,
  Sparkles,
  Layers,
  QrCode,
  TrendingUp,
  Globe,
  Smartphone,
  ArrowRight,
  ExternalLink,
  CheckCircle2,
  MapPin,
  Calendar,
  KeyRound
} from "lucide-react";

const belgradeGuideRoutes: Record<Language, string> = {
  TR: "/guide/belgrad-kiralik-daire-rehberi",
  EN: "/guide/belgrade-apartment-rental-guide",
  SR_LAT: "/guide/vodic-za-izdavanje-stanova-beograd",
  SR_CYR: "/guide/vodic-za-izdavanje-stanova-beograd-cirilica",
  RU: "/guide/belgrade-apartment-rental-guide-ru"
};

const noviSadGuideRoutes: Record<Language, string> = {
  TR: "/guide/novi-sad-mulk-yonetimi-rehberi",
  EN: "/guide/novi-sad-property-management-guide",
  SR_LAT: "/guide/upravljanje-nekretninama-novi-sad",
  SR_CYR: "/guide/upravljanje-nekretninama-novi-sad-cirilica",
  RU: "/guide/novi-sad-property-management-guide-ru"
};

const leaseAgreementGuideRoutes: Record<Language, string> = {
  TR: "/guide/sirbistan-kira-sozlesmesi-rehberi",
  EN: "/guide/serbia-lease-agreement-guide",
  SR_LAT: "/guide/ugovor-o-zakupu-stana-srbija",
  SR_CYR: "/guide/ugovor-o-zakupu-stana-srbija-cirilica",
  RU: "/guide/serbia-lease-agreement-guide-ru"
};

const beliKartonGuideRoutes: Record<Language, string> = {
  TR: "/guide/dijital-gocmenlere-ev-kiralama-beli-karton",
  EN: "/guide/renting-to-foreigners-digital-nomads-beli-karton",
  SR_LAT: "/guide/izdavanje-stana-strancima-beli-karton",
  SR_CYR: "/guide/izdavanje-stana-strancima-beli-karton-cirilica",
  RU: "/guide/renting-to-foreigners-digital-nomads-beli-karton-ru"
};

const IOS_APP_URL = "https://apps.apple.com/us/app/stanomer/id6762311157";
const ANDROID_APP_URL = "https://play.google.com/store/apps/details?id=com.aboptima.stanomer";
const WEB_APP_URL = "/app";

type IndividualTab = "overview" | "guides" | "agencies";
type AgencyTab = "overview" | "whitelabel" | "referral" | "demo" | "stats";

const languages: { code: Language; codeLabel: string; nativeLabel: string; flag: string }[] = [
  { code: "EN", codeLabel: "EN", nativeLabel: "English", flag: "🇬🇧" },
  { code: "SR_LAT", codeLabel: "SR", nativeLabel: "Srpski (Lat)", flag: "🇷🇸" },
  { code: "SR_CYR", codeLabel: "СРБ", nativeLabel: "Српски (Ћир)", flag: "🇷🇸" },
  { code: "RU", codeLabel: "RU", nativeLabel: "Русский", flag: "🇷🇺" },
  { code: "TR", codeLabel: "TR", nativeLabel: "Türkçe", flag: "🇹🇷" }
];

export function Navbar() {
  const { lang, setLang, t } = useLanguage();
  const pathname = usePathname();
  const router = useRouter();

  // Dropdowns
  const [openDropdown, setOpenDropdown] = useState<"individuals" | "agencies" | "app" | "language" | null>(null);
  const [activeInd, setActiveInd] = useState<IndividualTab>("overview");
  const [activeAgency, setActiveAgency] = useState<AgencyTab>("overview");

  // Mobile
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [mobileExpanded, setMobileExpanded] = useState<"individuals" | "agencies" | null>("individuals");

  const navRef = useRef<HTMLDivElement>(null);
  const closeTimeoutRef = useRef<NodeJS.Timeout | null>(null);

  useEffect(() => {
    captureUtmParams();
  }, []);

  // Close dropdown on outside click or ESC
  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (navRef.current && !navRef.current.contains(event.target as Node)) {
        setOpenDropdown(null);
      }
    }
    function handleKeyDown(event: KeyboardEvent) {
      if (event.key === "Escape") {
        setOpenDropdown(null);
        setMobileMenuOpen(false);
      }
    }
    document.addEventListener("mousedown", handleClickOutside);
    document.addEventListener("keydown", handleKeyDown);
    return () => {
      document.removeEventListener("mousedown", handleClickOutside);
      document.removeEventListener("keydown", handleKeyDown);
    };
  }, []);

  // Close menus on route change
  useEffect(() => {
    setOpenDropdown(null);
    setMobileMenuOpen(false);
  }, [pathname]);

  const handleMouseEnter = (type: "individuals" | "agencies" | "app" | "language") => {
    if (closeTimeoutRef.current) clearTimeout(closeTimeoutRef.current);
    setOpenDropdown(type);
  };

  const handleMouseLeave = () => {
    closeTimeoutRef.current = setTimeout(() => {
      setOpenDropdown(null);
    }, 150);
  };

  const isBeliKartonGuide = !!pathname && (
    pathname.includes("beli-karton") ||
    pathname.includes("digital-nomads") ||
    pathname.includes("strancima")
  );
  const isLeaseAgreementGuide = !!pathname && !isBeliKartonGuide && (
    pathname.includes("lease-agreement") ||
    pathname.includes("ugovor-o-zakupu") ||
    pathname.includes("kira-sozlesmesi")
  );
  const isNoviSadGuide = !!pathname && !isLeaseAgreementGuide && !isBeliKartonGuide && (pathname.includes("novi-sad") || pathname.includes("upravljanje-nekretninama"));
  const isBelgradeGuide = !!pathname && !isLeaseAgreementGuide && !isBeliKartonGuide && (
    pathname.includes("belgrade") || 
    pathname.includes("belgrad") || 
    pathname.includes("beograd")
  );

  const handleLanguageClick = (targetLang: Language) => {
    setLang(targetLang);
    if (isBeliKartonGuide) {
      const targetPath = beliKartonGuideRoutes[targetLang] || beliKartonGuideRoutes.EN;
      router.push(targetPath);
    } else if (isLeaseAgreementGuide) {
      const targetPath = leaseAgreementGuideRoutes[targetLang] || leaseAgreementGuideRoutes.EN;
      router.push(targetPath);
    } else if (isNoviSadGuide) {
      const targetPath = noviSadGuideRoutes[targetLang] || noviSadGuideRoutes.EN;
      router.push(targetPath);
    } else if (isBelgradeGuide) {
      const targetPath = belgradeGuideRoutes[targetLang] || belgradeGuideRoutes.EN;
      router.push(targetPath);
    }
  };

  const isIndividualsActive = pathname === "/" || pathname?.startsWith("/guide") || pathname?.startsWith("/real-estate-agencies") || pathname?.startsWith("/acente-bul") || pathname?.startsWith("/find-agency");
  const isAgenciesActive = pathname?.startsWith("/agencies") || pathname?.startsWith("/agency-") || pathname?.startsWith("/agency_");

  const currentLangConfig = languages.find((l) => l.code === lang) || languages[0];

  return (
    <nav ref={navRef} className="h-[80px] flex items-center fixed top-0 w-full z-[1000] bg-white border-b border-slate-200 shadow-sm transition-all">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 w-full flex justify-between items-center">
        
        {/* Left: Brand Logo & Mega Menu Dropdowns */}
        <div className="flex items-center gap-6 lg:gap-8">
          {/* Logo */}
          <a href="/" className="flex items-center gap-2.5 no-underline group flex-shrink-0">
            <img 
              src="/assets/logo.png" 
              alt="Stanomer Logo" 
              className="h-[32px] w-auto object-contain transition-transform duration-300 group-hover:scale-105" 
            />
            <span className="font-extrabold text-[1.4rem] text-slate-900 tracking-tight">Stanomer</span>
          </a>

          {/* Desktop Navigation Links */}
          <div className="hidden md:flex items-center gap-1.5">
            
            {/* 1. INDIVIDUALS MEGA DROPDOWN (Blue Theme) */}
            <div 
              className="relative"
              onMouseEnter={() => handleMouseEnter("individuals")}
              onMouseLeave={handleMouseLeave}
            >
              <button
                type="button"
                onClick={() => setOpenDropdown(openDropdown === "individuals" ? null : "individuals")}
                className={`inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl text-sm font-bold transition-all ${
                  openDropdown === "individuals" || isIndividualsActive
                    ? "text-blue-600 bg-blue-50/80 font-extrabold"
                    : "text-slate-700 hover:text-slate-900 hover:bg-slate-100/70"
                }`}
              >
                <span>{t("nav_for_individuals")}</span>
                <ChevronDown className={`w-4 h-4 transition-transform duration-200 ${openDropdown === "individuals" ? "rotate-180 text-blue-600" : "text-slate-400"}`} />
              </button>

              {openDropdown === "individuals" && (
                <div className="absolute top-full left-0 mt-2 w-[620px] bg-white rounded-3xl shadow-2xl border border-slate-200 p-3 grid grid-cols-12 gap-3 animate-in fade-in slide-in-from-top-2 duration-200 z-50">
                  
                  {/* Left Column: Menu Items */}
                  <div className="col-span-6 space-y-1 pr-1">
                    {/* Item 1: Overview */}
                    <a
                      href="/#features"
                      onMouseEnter={() => setActiveInd("overview")}
                      className={`flex items-center justify-between p-3 rounded-2xl transition-all cursor-pointer ${
                        activeInd === "overview"
                          ? "bg-blue-50/90 border border-blue-200/80 shadow-sm"
                          : "hover:bg-slate-50 border border-transparent"
                      }`}
                    >
                      <div className="flex items-center gap-3">
                        <div className={`w-9 h-9 rounded-xl flex items-center justify-center transition-colors ${
                          activeInd === "overview" ? "bg-blue-600 text-white shadow-md shadow-blue-500/20" : "bg-blue-100 text-blue-600"
                        }`}>
                          <Users className="w-4 h-4" />
                        </div>
                        <div>
                          <div className={`text-sm font-extrabold ${activeInd === "overview" ? "text-blue-700" : "text-slate-900"}`}>
                            {t("nav_ind_overview_title")}
                          </div>
                          <div className="text-[11px] text-slate-500 line-clamp-1">
                            {t("nav_ind_overview_desc")}
                          </div>
                        </div>
                      </div>
                      <ArrowRight className={`w-4 h-4 transition-transform ${activeInd === "overview" ? "text-blue-600 translate-x-0.5" : "text-slate-300 opacity-0"}`} />
                    </a>

                    {/* Item 2: Rental Guides */}
                    <a
                      href="/guide"
                      onMouseEnter={() => setActiveInd("guides")}
                      className={`flex items-center justify-between p-3 rounded-2xl transition-all cursor-pointer ${
                        activeInd === "guides"
                          ? "bg-indigo-50/90 border border-indigo-200/80 shadow-sm"
                          : "hover:bg-slate-50 border border-transparent"
                      }`}
                    >
                      <div className="flex items-center gap-3">
                        <div className={`w-9 h-9 rounded-xl flex items-center justify-center transition-colors ${
                          activeInd === "guides" ? "bg-indigo-600 text-white shadow-md shadow-indigo-500/20" : "bg-indigo-100 text-indigo-600"
                        }`}>
                          <BookOpen className="w-4 h-4" />
                        </div>
                        <div>
                          <div className={`text-sm font-extrabold ${activeInd === "guides" ? "text-indigo-700" : "text-slate-900"}`}>
                            {t("nav_ind_guides_title")}
                          </div>
                          <div className="text-[11px] text-slate-500 line-clamp-1">
                            {t("nav_ind_guides_desc")}
                          </div>
                        </div>
                      </div>
                      <ArrowRight className={`w-4 h-4 transition-transform ${activeInd === "guides" ? "text-indigo-600 translate-x-0.5" : "text-slate-300 opacity-0"}`} />
                    </a>

                    {/* Item 3: Find Agency */}
                    <a
                      href="/real-estate-agencies"
                      onMouseEnter={() => setActiveInd("agencies")}
                      className={`flex items-center justify-between p-3 rounded-2xl transition-all cursor-pointer ${
                        activeInd === "agencies"
                          ? "bg-emerald-50/90 border border-emerald-200/80 shadow-sm"
                          : "hover:bg-slate-50 border border-transparent"
                      }`}
                    >
                      <div className="flex items-center gap-3">
                        <div className={`w-9 h-9 rounded-xl flex items-center justify-center transition-colors ${
                          activeInd === "agencies" ? "bg-emerald-600 text-white shadow-md shadow-emerald-500/20" : "bg-emerald-100 text-emerald-600"
                        }`}>
                          <Building2 className="w-4 h-4" />
                        </div>
                        <div>
                          <div className={`text-sm font-extrabold ${activeInd === "agencies" ? "text-emerald-700" : "text-slate-900"}`}>
                            {t("nav_ind_agencies_title")}
                          </div>
                          <div className="text-[11px] text-slate-500 line-clamp-1">
                            {t("nav_ind_agencies_desc")}
                          </div>
                        </div>
                      </div>
                      <ArrowRight className={`w-4 h-4 transition-transform ${activeInd === "agencies" ? "text-emerald-600 translate-x-0.5" : "text-slate-300 opacity-0"}`} />
                    </a>
                  </div>

                  {/* Right Column: Interactive Illustration & Description Card */}
                  <div className="col-span-6 bg-gradient-to-br from-slate-50 to-blue-50/40 rounded-2xl p-4 border border-slate-100 flex flex-col justify-between relative overflow-hidden">
                    {activeInd === "overview" && (
                      <div className="space-y-3 animate-in fade-in duration-200">
                        {/* Mini Visual Illustration */}
                        <div className="bg-white rounded-xl p-3 border border-slate-200/80 shadow-sm space-y-2">
                          <div className="flex items-center justify-between">
                            <span className="text-[10px] font-extrabold uppercase px-2 py-0.5 rounded-md bg-blue-100 text-blue-700">
                              {t("nav_card_active_contract")}
                            </span>
                            <span className="text-xs font-bold text-emerald-600 flex items-center gap-1">
                              <CheckCircle2 className="w-3.5 h-3.5" /> €650 {t("nav_card_paid")}
                            </span>
                          </div>
                          <div className="h-1.5 w-full bg-slate-100 rounded-full overflow-hidden">
                            <div className="h-full bg-blue-600 rounded-full w-2/3"></div>
                          </div>
                          <div className="flex justify-between text-[10px] text-slate-400 font-semibold">
                            <span>{t("nav_card_tenant_sample")}</span>
                            <span>{t("nav_card_days_left")}</span>
                          </div>
                        </div>

                        <div>
                          <h4 className="text-xs font-extrabold text-slate-900 mb-1">{t("nav_ind_overview_title")}</h4>
                          <p className="text-[11px] text-slate-600 leading-relaxed">{t("nav_preview_ind_overview_sub")}</p>
                        </div>
                        <a href="/#features" className="inline-flex items-center gap-1 text-xs font-extrabold text-blue-600 hover:text-blue-700">
                          <span>{t("nav_preview_explore")}</span>
                          <ArrowRight className="w-3.5 h-3.5" />
                        </a>
                      </div>
                    )}

                    {activeInd === "guides" && (
                      <div className="space-y-3 animate-in fade-in duration-200">
                        {/* Mini Visual Illustration */}
                        <div className="bg-white rounded-xl p-3 border border-slate-200/80 shadow-sm flex items-center gap-2.5">
                          <div className="w-10 h-10 rounded-lg bg-indigo-50 border border-indigo-100 flex items-center justify-center text-indigo-600 flex-shrink-0">
                            <BookOpen className="w-5 h-5" />
                          </div>
                          <div className="space-y-1 text-[11px]">
                            <div className="font-extrabold text-slate-900">{t("nav_card_guides_count")}</div>
                            <div className="text-slate-500 text-[10px]">{t("nav_card_guides_cities")}</div>
                          </div>
                        </div>

                        <div>
                          <h4 className="text-xs font-extrabold text-slate-900 mb-1">{t("nav_ind_guides_title")}</h4>
                          <p className="text-[11px] text-slate-600 leading-relaxed">{t("nav_preview_ind_guides_sub")}</p>
                        </div>
                        <a href="/guide" className="inline-flex items-center gap-1 text-xs font-extrabold text-indigo-600 hover:text-indigo-700">
                          <span>{t("nav_preview_explore")}</span>
                          <ArrowRight className="w-3.5 h-3.5" />
                        </a>
                      </div>
                    )}

                    {activeInd === "agencies" && (
                      <div className="space-y-3 animate-in fade-in duration-200">
                        {/* Mini Visual Illustration */}
                        <div className="bg-white rounded-xl p-3 border border-slate-200/80 shadow-sm space-y-1.5">
                          <div className="flex items-center gap-2">
                            <MapPin className="w-4 h-4 text-emerald-600" />
                            <span className="text-xs font-extrabold text-slate-900">{t("nav_card_directory_title")}</span>
                          </div>
                          <div className="text-[10px] text-slate-500 font-medium">{t("nav_card_directory_sub")}</div>
                        </div>

                        <div>
                          <h4 className="text-xs font-extrabold text-slate-900 mb-1">{t("nav_ind_agencies_title")}</h4>
                          <p className="text-[11px] text-slate-600 leading-relaxed">{t("nav_preview_ind_agencies_sub")}</p>
                        </div>
                        <a href="/real-estate-agencies" className="inline-flex items-center gap-1 text-xs font-extrabold text-emerald-600 hover:text-emerald-700">
                          <span>{t("nav_preview_explore")}</span>
                          <ArrowRight className="w-3.5 h-3.5" />
                        </a>
                      </div>
                    )}
                  </div>

                </div>
              )}
            </div>

            {/* 2. AGENCIES MEGA DROPDOWN (Purple / Violet Theme) */}
            <div 
              className="relative"
              onMouseEnter={() => handleMouseEnter("agencies")}
              onMouseLeave={handleMouseLeave}
            >
              <button
                type="button"
                onClick={() => setOpenDropdown(openDropdown === "agencies" ? null : "agencies")}
                className={`inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl text-sm font-bold transition-all ${
                  openDropdown === "agencies" || isAgenciesActive
                    ? "text-purple-700 bg-purple-50 font-extrabold"
                    : "text-slate-700 hover:text-slate-900 hover:bg-slate-100/70"
                }`}
              >
                <span>{t("nav_for_agencies")}</span>
                <ChevronDown className={`w-4 h-4 transition-transform duration-200 ${openDropdown === "agencies" ? "rotate-180 text-purple-700" : "text-slate-400"}`} />
              </button>

              {openDropdown === "agencies" && (
                <div className="absolute top-full left-0 mt-2 w-[680px] bg-white rounded-3xl shadow-2xl border border-slate-200 p-3 grid grid-cols-12 gap-3 animate-in fade-in slide-in-from-top-2 duration-200 z-50">
                  
                  {/* Left Column: Menu Items */}
                  <div className="col-span-6 space-y-1 pr-1">
                    {/* Item 1: Overview */}
                    <a
                      href="/agencies"
                      onMouseEnter={() => setActiveAgency("overview")}
                      className={`flex items-center justify-between p-2.5 rounded-2xl transition-all cursor-pointer ${
                        activeAgency === "overview"
                          ? "bg-purple-50/90 border border-purple-200/80 shadow-sm"
                          : "hover:bg-slate-50 border border-transparent"
                      }`}
                    >
                      <div className="flex items-center gap-2.5">
                        <div className={`w-8 h-8 rounded-xl flex items-center justify-center transition-colors ${
                          activeAgency === "overview" ? "bg-purple-600 text-white shadow-md shadow-purple-500/20" : "bg-purple-100 text-purple-700"
                        }`}>
                          <Building2 className="w-4 h-4" />
                        </div>
                        <div>
                          <div className={`text-xs font-extrabold ${activeAgency === "overview" ? "text-purple-900" : "text-slate-900"}`}>
                            {t("nav_agency_overview_title")}
                          </div>
                          <div className="text-[10px] text-slate-500 line-clamp-1">
                            {t("nav_agency_overview_desc")}
                          </div>
                        </div>
                      </div>
                      <ArrowRight className={`w-3.5 h-3.5 transition-transform ${activeAgency === "overview" ? "text-purple-600 translate-x-0.5" : "text-slate-300 opacity-0"}`} />
                    </a>

                    {/* Item 2: White-label */}
                    <a
                      href="/agencies#section-whitelabel"
                      onMouseEnter={() => setActiveAgency("whitelabel")}
                      className={`flex items-center justify-between p-2.5 rounded-2xl transition-all cursor-pointer ${
                        activeAgency === "whitelabel"
                          ? "bg-purple-50/70 border border-purple-200/60 shadow-sm"
                          : "hover:bg-slate-50 border border-transparent"
                      }`}
                    >
                      <div className="flex items-center gap-2.5">
                        <div className={`w-8 h-8 rounded-xl flex items-center justify-center transition-colors ${
                          activeAgency === "whitelabel" ? "bg-purple-700 text-white shadow-md" : "bg-slate-100 text-slate-700"
                        }`}>
                          <Layers className="w-4 h-4" />
                        </div>
                        <div>
                          <div className={`text-xs font-extrabold ${activeAgency === "whitelabel" ? "text-purple-950" : "text-slate-800"}`}>
                            {t("nav_agency_whitelabel_title")}
                          </div>
                          <div className="text-[10px] text-slate-500 line-clamp-1">
                            {t("nav_agency_whitelabel_desc")}
                          </div>
                        </div>
                      </div>
                      <ArrowRight className={`w-3.5 h-3.5 transition-transform ${activeAgency === "whitelabel" ? "text-purple-700 translate-x-0.5" : "text-slate-300 opacity-0"}`} />
                    </a>

                    {/* Item 3: Referral */}
                    <a
                      href="/agency-referral"
                      onMouseEnter={() => setActiveAgency("referral")}
                      className={`flex items-center justify-between p-2.5 rounded-2xl transition-all cursor-pointer ${
                        activeAgency === "referral"
                          ? "bg-indigo-50/90 border border-indigo-200/80 shadow-sm"
                          : "hover:bg-slate-50 border border-transparent"
                      }`}
                    >
                      <div className="flex items-center gap-2.5">
                        <div className={`w-8 h-8 rounded-xl flex items-center justify-center transition-colors ${
                          activeAgency === "referral" ? "bg-indigo-600 text-white shadow-md shadow-indigo-500/20" : "bg-indigo-100 text-indigo-600"
                        }`}>
                          <QrCode className="w-4 h-4" />
                        </div>
                        <div>
                          <div className={`text-xs font-extrabold ${activeAgency === "referral" ? "text-indigo-700" : "text-slate-900"}`}>
                            {t("nav_agency_referral_title")}
                          </div>
                          <div className="text-[10px] text-slate-500 line-clamp-1">
                            {t("nav_agency_referral_desc")}
                          </div>
                        </div>
                      </div>
                      <ArrowRight className={`w-3.5 h-3.5 transition-transform ${activeAgency === "referral" ? "text-indigo-600 translate-x-0.5" : "text-slate-300 opacity-0"}`} />
                    </a>

                    {/* Item 4: Demo (Highlighted Violet CTA) */}
                    <a
                      href="/agency-demo"
                      onMouseEnter={() => setActiveAgency("demo")}
                      className={`flex items-center justify-between p-2.5 rounded-2xl transition-all cursor-pointer ${
                        activeAgency === "demo"
                          ? "bg-purple-100/90 border border-purple-300 shadow-sm"
                          : "bg-purple-50/60 hover:bg-purple-100/70 border border-purple-200/70"
                      }`}
                    >
                      <div className="flex items-center gap-2.5">
                        <div className="w-8 h-8 rounded-xl bg-gradient-to-br from-purple-600 to-indigo-600 text-white flex items-center justify-center shadow-sm">
                          <Sparkles className="w-4 h-4" />
                        </div>
                        <div>
                          <div className="text-xs font-extrabold text-purple-950 flex items-center gap-1.5">
                            <span>{t("nav_agency_demo_title")}</span>
                            <span className="text-[9px] font-extrabold uppercase px-1.5 py-0.2 rounded-md bg-purple-600 text-white">Demo</span>
                          </div>
                          <div className="text-[10px] text-purple-800/80 line-clamp-1">
                            {t("nav_agency_demo_desc")}
                          </div>
                        </div>
                      </div>
                      <ArrowRight className="w-3.5 h-3.5 text-purple-700" />
                    </a>

                    {/* Item 5: Stats Portal */}
                    <a
                      href="/agency-stats"
                      onMouseEnter={() => setActiveAgency("stats")}
                      className={`flex items-center justify-between p-2.5 rounded-2xl transition-all cursor-pointer ${
                        activeAgency === "stats"
                          ? "bg-slate-100/90 border border-slate-300 shadow-sm"
                          : "hover:bg-slate-50 border border-transparent"
                      }`}
                    >
                      <div className="flex items-center gap-2.5">
                        <div className={`w-8 h-8 rounded-xl flex items-center justify-center transition-colors ${
                          activeAgency === "stats" ? "bg-slate-700 text-white" : "bg-slate-100 text-slate-600"
                        }`}>
                          <TrendingUp className="w-4 h-4" />
                        </div>
                        <div>
                          <div className={`text-xs font-extrabold ${activeAgency === "stats" ? "text-slate-900" : "text-slate-800"}`}>
                            {t("nav_agency_stats_title")}
                          </div>
                          <div className="text-[10px] text-slate-500 line-clamp-1">
                            {t("nav_agency_stats_desc")}
                          </div>
                        </div>
                      </div>
                      <ArrowRight className={`w-3.5 h-3.5 transition-transform ${activeAgency === "stats" ? "text-slate-700 translate-x-0.5" : "text-slate-300 opacity-0"}`} />
                    </a>
                  </div>

                  {/* Right Column: Interactive Illustration & Description Card */}
                  <div className="col-span-6 bg-gradient-to-br from-purple-50/50 via-white to-indigo-50/40 rounded-2xl p-4 border border-purple-100 flex flex-col justify-between relative overflow-hidden">
                    {activeAgency === "overview" && (
                      <div className="space-y-3 animate-in fade-in duration-200">
                        <div className="bg-white rounded-xl p-3 border border-slate-200/80 shadow-sm space-y-2">
                          <div className="flex items-center justify-between">
                            <span className="text-[10px] font-extrabold uppercase px-2 py-0.5 rounded-md bg-purple-100 text-purple-800">
                              {t("nav_card_agency_panel")}
                            </span>
                            <span className="text-[10px] font-bold text-slate-500">{t("nav_card_portfolio_count")}</span>
                          </div>
                          <div className="grid grid-cols-2 gap-2 text-center">
                            <div className="bg-slate-50 p-1.5 rounded-lg border border-slate-100">
                              <div className="text-xs font-black text-slate-800">€9.400</div>
                              <div className="text-[9px] text-slate-400 font-semibold">{t("nav_card_monthly_rent")}</div>
                            </div>
                            <div className="bg-slate-50 p-1.5 rounded-lg border border-slate-100">
                              <div className="text-xs font-black text-purple-600">%100</div>
                              <div className="text-[9px] text-slate-400 font-semibold">{t("nav_card_collection_rate")}</div>
                            </div>
                          </div>
                        </div>

                        <div>
                          <h4 className="text-xs font-extrabold text-slate-900 mb-1">{t("nav_agency_overview_title")}</h4>
                          <p className="text-[11px] text-slate-600 leading-relaxed">{t("nav_preview_agency_overview_sub")}</p>
                        </div>
                        <a href="/agencies" className="inline-flex items-center gap-1 text-xs font-extrabold text-purple-700 hover:text-purple-800">
                          <span>{t("nav_preview_explore")}</span>
                          <ArrowRight className="w-3.5 h-3.5" />
                        </a>
                      </div>
                    )}

                    {activeAgency === "whitelabel" && (
                      <div className="space-y-3 animate-in fade-in duration-200">
                        <div className="bg-white rounded-xl p-3 border border-slate-200/80 shadow-sm flex items-center gap-3">
                          <div className="w-10 h-10 rounded-lg bg-purple-900 text-white flex items-center justify-center font-black text-xs">
                            LOGO
                          </div>
                          <div className="space-y-0.5">
                            <div className="text-xs font-bold text-slate-900">{t("nav_card_brand_identity")}</div>
                            <div className="text-[10px] text-slate-500">{t("nav_card_brand_identity_sub")}</div>
                          </div>
                        </div>

                        <div>
                          <h4 className="text-xs font-extrabold text-slate-900 mb-1">{t("nav_agency_whitelabel_title")}</h4>
                          <p className="text-[11px] text-slate-600 leading-relaxed">{t("nav_preview_agency_whitelabel_sub")}</p>
                        </div>
                        <a href="/agencies#section-whitelabel" className="inline-flex items-center gap-1 text-xs font-extrabold text-purple-700 hover:text-purple-800">
                          <span>{t("nav_preview_explore")}</span>
                          <ArrowRight className="w-3.5 h-3.5" />
                        </a>
                      </div>
                    )}

                    {activeAgency === "referral" && (
                      <div className="space-y-3 animate-in fade-in duration-200">
                        <div className="bg-white rounded-xl p-3 border border-slate-200/80 shadow-sm flex items-center gap-3">
                          <div className="w-10 h-10 rounded-lg bg-indigo-50 border border-indigo-200 flex items-center justify-center text-indigo-600">
                            <QrCode className="w-5 h-5" />
                          </div>
                          <div className="space-y-0.5">
                            <div className="text-xs font-bold text-indigo-950">{t("nav_card_qr_title")}</div>
                            <div className="text-[10px] text-indigo-600 font-semibold">stanomer://referral?token=...</div>
                          </div>
                        </div>

                        <div>
                          <h4 className="text-xs font-extrabold text-slate-900 mb-1">{t("nav_agency_referral_title")}</h4>
                          <p className="text-[11px] text-slate-600 leading-relaxed">{t("nav_preview_agency_referral_sub")}</p>
                        </div>
                        <a href="/agency-referral" className="inline-flex items-center gap-1 text-xs font-extrabold text-indigo-600 hover:text-indigo-700">
                          <span>{t("nav_preview_explore")}</span>
                          <ArrowRight className="w-3.5 h-3.5" />
                        </a>
                      </div>
                    )}

                    {activeAgency === "demo" && (
                      <div className="space-y-3 animate-in fade-in duration-200">
                        <div className="bg-gradient-to-r from-purple-600 to-indigo-600 text-white rounded-xl p-3 shadow-md space-y-1">
                          <div className="flex items-center justify-between text-xs font-black">
                            <span className="flex items-center gap-1.5"><Calendar className="w-3.5 h-3.5" /> {t("nav_card_live_demo")}</span>
                            <span className="text-[10px] bg-white/20 px-2 py-0.5 rounded-full">15 Dk</span>
                          </div>
                          <div className="text-[10px] text-purple-100">{t("nav_card_live_demo_sub")}</div>
                        </div>

                        <div>
                          <h4 className="text-xs font-extrabold text-slate-900 mb-1">{t("nav_agency_demo_title")}</h4>
                          <p className="text-[11px] text-slate-600 leading-relaxed">{t("nav_preview_agency_demo_sub")}</p>
                        </div>
                        <a href="/agency-demo" className="inline-flex items-center gap-1 text-xs font-extrabold text-purple-700 hover:text-purple-800">
                          <span>{t("nav_preview_explore")}</span>
                          <ArrowRight className="w-3.5 h-3.5" />
                        </a>
                      </div>
                    )}

                    {activeAgency === "stats" && (
                      <div className="space-y-3 animate-in fade-in duration-200">
                        <div className="bg-white rounded-xl p-3 border border-slate-200/80 shadow-sm flex items-center gap-3">
                          <div className="w-10 h-10 rounded-lg bg-purple-50 border border-purple-100 flex items-center justify-center text-purple-600">
                            <KeyRound className="w-5 h-5" />
                          </div>
                          <div className="space-y-0.5">
                            <div className="text-xs font-bold text-slate-900">{t("nav_card_otp_title")}</div>
                            <div className="text-[10px] text-slate-500">{t("nav_card_otp_sub")}</div>
                          </div>
                        </div>

                        <div>
                          <h4 className="text-xs font-extrabold text-slate-900 mb-1">{t("nav_agency_stats_title")}</h4>
                          <p className="text-[11px] text-slate-600 leading-relaxed">{t("nav_preview_agency_stats_sub")}</p>
                        </div>
                        <a href="/agency-stats" className="inline-flex items-center gap-1 text-xs font-extrabold text-purple-700 hover:text-purple-800">
                          <span>{t("nav_preview_explore")}</span>
                          <ArrowRight className="w-3.5 h-3.5" />
                        </a>
                      </div>
                    )}
                  </div>

                </div>
              )}
            </div>

          </div>
        </div>

        {/* Right: Language Switcher Dropdown & App Launcher */}
        <div className="flex items-center gap-2.5 sm:gap-3">
          
          {/* LANGUAGE SELECTOR DROPDOWN (Desktop) */}
          <div 
            className="relative hidden md:block"
            onMouseEnter={() => handleMouseEnter("language")}
            onMouseLeave={handleMouseLeave}
          >
            <button
              type="button"
              onClick={() => setOpenDropdown(openDropdown === "language" ? null : "language")}
              className="inline-flex items-center gap-2 px-3 py-2 rounded-xl text-xs font-extrabold text-slate-700 hover:text-slate-900 hover:bg-slate-100/70 border border-slate-200/80 transition-all cursor-pointer shadow-sm"
              aria-label="Language Selector"
            >
              <span className="text-slate-400 font-medium">{t("language") || "Language"}:</span>
              <span className="text-sm leading-none">{currentLangConfig.flag}</span>
              <span className="text-slate-900 font-extrabold">{currentLangConfig.codeLabel}</span>
              <ChevronDown className={`w-3.5 h-3.5 text-slate-400 transition-transform duration-200 ${openDropdown === "language" ? "rotate-180 text-blue-600" : ""}`} />
            </button>

            {openDropdown === "language" && (
              <div className="absolute top-full right-0 mt-2 w-52 bg-white rounded-2xl shadow-2xl border border-slate-200 p-1.5 animate-in fade-in slide-in-from-top-2 duration-200 z-50 space-y-0.5">
                {languages.map((l) => (
                  <button
                    key={l.code}
                    type="button"
                    onClick={() => {
                      handleLanguageClick(l.code as Language);
                      setOpenDropdown(null);
                    }}
                    className={`w-full flex items-center justify-between px-3 py-2 rounded-xl text-xs transition-all cursor-pointer ${
                      lang === l.code
                        ? "bg-blue-50 text-blue-700 border border-blue-200/60 font-black shadow-xs"
                        : "text-slate-700 hover:bg-slate-50 hover:text-slate-900 border border-transparent font-bold"
                    }`}
                  >
                    <div className="flex items-center gap-2.5">
                      <span className="text-base leading-none">{l.flag}</span>
                      <span>{l.nativeLabel}</span>
                    </div>
                    <span className={`text-[10px] uppercase font-black px-1.5 py-0.5 rounded-md ${
                      lang === l.code ? "bg-blue-600 text-white" : "bg-slate-100 text-slate-500"
                    }`}>
                      {l.codeLabel}
                    </span>
                  </button>
                ))}
              </div>
            )}
          </div>

          {/* APP LAUNCHER DROPDOWN (Desktop) */}
          <div 
            className="relative hidden sm:block"
            onMouseEnter={() => handleMouseEnter("app")}
            onMouseLeave={handleMouseLeave}
          >
            <button
              type="button"
              onClick={() => setOpenDropdown(openDropdown === "app" ? null : "app")}
              className="inline-flex items-center gap-2 bg-gradient-to-r from-blue-600 via-indigo-600 to-blue-700 hover:from-blue-700 hover:to-indigo-700 text-white text-xs sm:text-sm font-extrabold px-4 py-2.5 rounded-xl shadow-md shadow-blue-500/20 hover:shadow-lg hover:shadow-blue-500/30 active:scale-[0.98] transition-all cursor-pointer"
            >
              <Smartphone className="w-4 h-4" />
              <span>{t("nav_btn_get_app")}</span>
              <ChevronDown className={`w-3.5 h-3.5 transition-transform duration-200 ${openDropdown === "app" ? "rotate-180" : ""}`} />
            </button>

            {openDropdown === "app" && (
              <div className="absolute top-full right-0 mt-2 w-72 bg-white rounded-3xl shadow-2xl border border-slate-200 p-2.5 animate-in fade-in slide-in-from-top-2 duration-200 z-50">
                {/* 1. Web App */}
                <a
                  href={WEB_APP_URL}
                  className="flex items-center gap-3 p-3 rounded-2xl bg-slate-900 hover:bg-slate-800 text-white transition-all shadow-md group/web"
                >
                  <div className="w-9 h-9 rounded-xl bg-white/10 flex items-center justify-center flex-shrink-0">
                    <Globe className="w-5 h-5 text-blue-300" />
                  </div>
                  <div className="flex-grow">
                    <div className="text-xs font-extrabold flex items-center justify-between">
                      <span>{t("nav_web_app_title")}</span>
                      <ArrowRight className="w-3.5 h-3.5 text-blue-300 group-hover/web:translate-x-0.5 transition-transform" />
                    </div>
                    <div className="text-[11px] text-slate-300 font-normal">
                      {t("nav_web_app_sub")}
                    </div>
                  </div>
                </a>

                <div className="relative my-2.5">
                  <div className="absolute inset-0 flex items-center">
                    <div className="w-full border-t border-slate-100" />
                  </div>
                  <div className="relative flex justify-center text-[10px] uppercase font-bold text-slate-400">
                    <span className="bg-white px-2">{t("nav_card_mobile_apps")}</span>
                  </div>
                </div>

                {/* 2. iOS App Store */}
                <a
                  href={IOS_APP_URL}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="flex items-center gap-3 p-2.5 rounded-xl hover:bg-slate-50 text-slate-800 transition-colors group/ios"
                >
                  <div className="w-8 h-8 rounded-lg bg-slate-100 flex items-center justify-center flex-shrink-0 text-slate-800">
                    <svg className="w-4 h-4 fill-current" viewBox="0 0 24 24">
                      <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M15.97 6.38c.62-.75 1.04-1.8 0.92-2.85-.9.04-1.98.6-2.61 1.34-.56.64-1.04 1.71-.91 2.74 1 .08 2.02-.51 2.6-1.23z"/>
                    </svg>
                  </div>
                  <div>
                    <div className="text-xs font-extrabold text-slate-900 group-hover/ios:text-blue-600 transition-colors flex items-center gap-1">
                      <span>App Store</span>
                      <ExternalLink className="w-3 h-3 text-slate-400" />
                    </div>
                    <div className="text-[11px] text-slate-500 font-medium">
                      {t("nav_app_store_sub")}
                    </div>
                  </div>
                </a>

                {/* 3. Android Google Play */}
                <a
                  href={ANDROID_APP_URL}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="flex items-center gap-3 p-2.5 rounded-xl hover:bg-slate-50 text-slate-800 transition-colors group/and"
                >
                  <div className="w-8 h-8 rounded-lg bg-emerald-50 text-emerald-600 flex items-center justify-center flex-shrink-0">
                    <svg className="w-4 h-4 fill-current" viewBox="0 0 24 24">
                      <path d="M3.609 1.814L13.792 12 3.61 22.186c-.198-.225-.31-.53-.31-.886V2.7c0-.356.112-.661.31-.886zm11.238 11.241l2.455 2.455-12.01 6.848 9.555-9.303zm0-2.11L5.292 1.642l12.01 6.848-2.455 2.455zm1.488 1.055l3.524 2.008c.691.394.691 1.04 0 1.434l-3.524 2.008-2.228-2.225 2.228-2.225z"/>
                    </svg>
                  </div>
                  <div>
                    <div className="text-xs font-extrabold text-slate-900 group-hover/and:text-emerald-600 transition-colors flex items-center gap-1">
                      <span>Google Play</span>
                      <ExternalLink className="w-3 h-3 text-slate-400" />
                    </div>
                    <div className="text-[11px] text-slate-500 font-medium">
                      {t("nav_google_play_sub")}
                    </div>
                  </div>
                </a>
              </div>
            )}
          </div>

          {/* Mobile Hamburger Button */}
          <button
            type="button"
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            className="md:hidden p-2 rounded-xl text-slate-700 hover:text-slate-900 hover:bg-slate-100 focus:outline-none"
            aria-label="Toggle Menu"
          >
            {mobileMenuOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
          </button>
        </div>

      </div>

      {/* MOBILE FULLSCREEN / SLIDE-DOWN DRAWER */}
      {mobileMenuOpen && (
        <div className="md:hidden fixed top-[80px] left-0 w-full h-[calc(100vh-80px)] bg-white z-[999] overflow-y-auto px-5 py-6 space-y-6 animate-in fade-in duration-200">
          
          {/* Segment Selector Tabs */}
          <div className="flex bg-slate-100 p-1 rounded-2xl border border-slate-200">
            <button
              type="button"
              onClick={() => setMobileExpanded("individuals")}
              className={`flex-1 py-2.5 text-xs font-extrabold rounded-xl transition-all ${
                mobileExpanded === "individuals"
                  ? "bg-white text-blue-600 shadow-sm"
                  : "text-slate-600 hover:text-slate-900"
              }`}
            >
              {t("nav_for_individuals")}
            </button>
            <button
              type="button"
              onClick={() => setMobileExpanded("agencies")}
              className={`flex-1 py-2.5 text-xs font-extrabold rounded-xl transition-all ${
                mobileExpanded === "agencies"
                  ? "bg-white text-purple-700 shadow-sm"
                  : "text-slate-600 hover:text-slate-900"
              }`}
            >
              {t("nav_for_agencies")}
            </button>
          </div>

          {/* Tab 1: Individuals Menu */}
          {mobileExpanded === "individuals" && (
            <div className="space-y-2">
              <a
                href="/#features"
                onClick={() => setMobileMenuOpen(false)}
                className="flex items-center gap-3 p-3 rounded-2xl bg-slate-50 hover:bg-blue-50 border border-slate-100 transition-colors"
              >
                <div className="w-10 h-10 rounded-xl bg-blue-100 text-blue-600 flex items-center justify-center flex-shrink-0">
                  <Users className="w-5 h-5" />
                </div>
                <div>
                  <div className="text-sm font-bold text-slate-900">{t("nav_ind_overview_title")}</div>
                  <div className="text-xs text-slate-500">{t("nav_ind_overview_desc")}</div>
                </div>
              </a>

              <a
                href="/guide"
                onClick={() => setMobileMenuOpen(false)}
                className="flex items-center gap-3 p-3 rounded-2xl bg-slate-50 hover:bg-indigo-50 border border-slate-100 transition-colors"
              >
                <div className="w-10 h-10 rounded-xl bg-indigo-100 text-indigo-600 flex items-center justify-center flex-shrink-0">
                  <BookOpen className="w-5 h-5" />
                </div>
                <div>
                  <div className="text-sm font-bold text-slate-900">{t("nav_ind_guides_title")}</div>
                  <div className="text-xs text-slate-500">{t("nav_ind_guides_desc")}</div>
                </div>
              </a>

              <a
                href="/real-estate-agencies"
                onClick={() => setMobileMenuOpen(false)}
                className="flex items-center gap-3 p-3 rounded-2xl bg-slate-50 hover:bg-emerald-50 border border-slate-100 transition-colors"
              >
                <div className="w-10 h-10 rounded-xl bg-emerald-100 text-emerald-600 flex items-center justify-center flex-shrink-0">
                  <Building2 className="w-5 h-5" />
                </div>
                <div>
                  <div className="text-sm font-bold text-slate-900">{t("nav_ind_agencies_title")}</div>
                  <div className="text-xs text-slate-500">{t("nav_ind_agencies_desc")}</div>
                </div>
              </a>
            </div>
          )}

          {/* Tab 2: Agencies Menu (Purple accents) */}
          {mobileExpanded === "agencies" && (
            <div className="space-y-2">
              <a
                href="/agencies"
                onClick={() => setMobileMenuOpen(false)}
                className="flex items-center gap-3 p-3 rounded-2xl bg-slate-50 hover:bg-purple-50 border border-slate-100 transition-colors"
              >
                <div className="w-10 h-10 rounded-xl bg-purple-100 text-purple-700 flex items-center justify-center flex-shrink-0">
                  <Building2 className="w-5 h-5" />
                </div>
                <div>
                  <div className="text-sm font-bold text-slate-900">{t("nav_agency_overview_title")}</div>
                  <div className="text-xs text-slate-500">{t("nav_agency_overview_desc")}</div>
                </div>
              </a>

              <a
                href="/agencies#section-whitelabel"
                onClick={() => setMobileMenuOpen(false)}
                className="flex items-center gap-3 p-3 rounded-2xl bg-slate-50 hover:bg-purple-50 border border-slate-100 transition-colors"
              >
                <div className="w-10 h-10 rounded-xl bg-purple-100 text-purple-700 flex items-center justify-center flex-shrink-0">
                  <Layers className="w-5 h-5" />
                </div>
                <div>
                  <div className="text-sm font-bold text-slate-900">{t("nav_agency_whitelabel_title")}</div>
                  <div className="text-xs text-slate-500">{t("nav_agency_whitelabel_desc")}</div>
                </div>
              </a>

              <a
                href="/agency-referral"
                onClick={() => setMobileMenuOpen(false)}
                className="flex items-center gap-3 p-3 rounded-2xl bg-slate-50 hover:bg-indigo-50 border border-slate-100 transition-colors"
              >
                <div className="w-10 h-10 rounded-xl bg-indigo-100 text-indigo-600 flex items-center justify-center flex-shrink-0">
                  <QrCode className="w-5 h-5" />
                </div>
                <div>
                  <div className="text-sm font-bold text-slate-900">{t("nav_agency_referral_title")}</div>
                  <div className="text-xs text-slate-500">{t("nav_agency_referral_desc")}</div>
                </div>
              </a>

              <a
                href="/agency-demo"
                onClick={() => setMobileMenuOpen(false)}
                className="flex items-center gap-3 p-3 rounded-2xl bg-gradient-to-r from-purple-600/10 via-indigo-600/10 to-purple-700/10 border border-purple-300 transition-colors"
              >
                <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-purple-600 to-indigo-600 text-white flex items-center justify-center flex-shrink-0 shadow-sm">
                  <Sparkles className="w-5 h-5" />
                </div>
                <div className="flex-grow">
                  <div className="text-sm font-extrabold text-purple-950 flex items-center justify-between">
                    <span>{t("nav_agency_demo_title")}</span>
                    <span className="text-[10px] font-extrabold uppercase px-2 py-0.5 rounded-full bg-purple-600 text-white">Demo</span>
                  </div>
                  <div className="text-xs text-purple-800/80">{t("nav_agency_demo_desc")}</div>
                </div>
              </a>

              <a
                href="/agency-stats"
                onClick={() => setMobileMenuOpen(false)}
                className="flex items-center gap-3 p-3 rounded-2xl bg-slate-50 hover:bg-purple-50 border border-slate-100 transition-colors"
              >
                <div className="w-10 h-10 rounded-xl bg-purple-100 text-purple-700 flex items-center justify-center flex-shrink-0">
                  <TrendingUp className="w-5 h-5" />
                </div>
                <div>
                  <div className="text-sm font-bold text-slate-900">{t("nav_agency_stats_title")}</div>
                  <div className="text-xs text-slate-500">{t("nav_agency_stats_desc")}</div>
                </div>
              </a>
            </div>
          )}

          {/* Mobile Direct Action Buttons */}
          <div className="pt-4 border-t border-slate-200 space-y-2.5">
            <div className="text-xs font-bold text-slate-400 uppercase tracking-wider mb-2">
              {t("nav_btn_get_app")}
            </div>

            <a
              href={WEB_APP_URL}
              onClick={() => setMobileMenuOpen(false)}
              className="flex items-center justify-between w-full p-3.5 rounded-2xl bg-slate-900 text-white font-extrabold text-sm shadow-md"
            >
              <div className="flex items-center gap-2.5">
                <Globe className="w-5 h-5 text-blue-300" />
                <span>{t("nav_web_app_title")}</span>
              </div>
              <ArrowRight className="w-4 h-4 text-blue-300" />
            </a>

            <div className="grid grid-cols-2 gap-2 pt-1">
              <a
                href={IOS_APP_URL}
                target="_blank"
                rel="noopener noreferrer"
                className="flex items-center justify-center gap-2 p-3 rounded-2xl bg-slate-100 hover:bg-slate-200 text-slate-900 font-bold text-xs border border-slate-200 transition-colors"
              >
                <svg className="w-4 h-4 fill-current" viewBox="0 0 24 24">
                  <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M15.97 6.38c.62-.75 1.04-1.8 0.92-2.85-.9.04-1.98.6-2.61 1.34-.56.64-1.04 1.71-.91 2.74 1 .08 2.02-.51 2.6-1.23z"/>
                </svg>
                <span>App Store</span>
              </a>

              <a
                href={ANDROID_APP_URL}
                target="_blank"
                rel="noopener noreferrer"
                className="flex items-center justify-center gap-2 p-3 rounded-2xl bg-slate-100 hover:bg-slate-200 text-slate-900 font-bold text-xs border border-slate-200 transition-colors"
              >
                <svg className="w-4 h-4 fill-current text-emerald-600" viewBox="0 0 24 24">
                  <path d="M3.609 1.814L13.792 12 3.61 22.186c-.198-.225-.31-.53-.31-.886V2.7c0-.356.112-.661.31-.886zm11.238 11.241l2.455 2.455-12.01 6.848 9.555-9.303zm0-2.11L5.292 1.642l12.01 6.848-2.455 2.455zm1.488 1.055l3.524 2.008c.691.394.691 1.04 0 1.434l-3.524 2.008-2.228-2.225 2.228-2.225z"/>
                </svg>
                <span>Google Play</span>
              </a>
            </div>
          </div>

          {/* Mobile Language Switcher (Side-by-side row) */}
          <div className="pt-4 border-t border-slate-200">
            <div className="text-xs font-bold text-slate-400 uppercase tracking-wider mb-2.5">
              {t("language") || "Dil / Language"}
            </div>
            <div className="grid grid-cols-5 gap-1.5 bg-slate-100 p-1.5 rounded-2xl border border-slate-200">
              {languages.map((l) => (
                <button
                  key={l.code}
                  type="button"
                  onClick={() => {
                    handleLanguageClick(l.code as Language);
                    setMobileMenuOpen(false);
                  }}
                  className={`py-2 flex flex-col items-center justify-center gap-1 rounded-xl transition-all ${
                    lang === l.code 
                      ? "bg-white text-blue-700 shadow-sm font-black border border-slate-200/60" 
                      : "text-slate-600 hover:text-slate-900 font-semibold"
                  }`}
                >
                  <span className="text-sm leading-none">{l.flag}</span>
                  <span className="text-[11px] font-extrabold">{l.codeLabel}</span>
                </button>
              ))}
            </div>
          </div>


        </div>
      )}
    </nav>
  );
}
