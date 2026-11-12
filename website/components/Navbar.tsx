"use client";

import React, { useState, useEffect, useRef } from "react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useLanguage, Language } from "./LanguageProvider";
import { captureUtmParams } from "../lib/utm";
import {
  ChevronDown,
  Menu,
  X,
  ArrowUpRight,
  Users,
  BookOpen,
  Building2,
  Layers,
  QrCode,
  TrendingUp,
  Sparkles,
  Globe,
  MapPin,
  FileText,
  CheckCircle2,
  type LucideIcon
} from "lucide-react";

const quickGuideLabels: Record<Language, { belgrade: string; noviSad: string; lease: string; beliKarton: string }> = {
  TR: {
    belgrade: "Belgrad Rehberi",
    noviSad: "Novi Sad Rehberi",
    lease: "Kira Sözleşmesi",
    beliKarton: "Beli Karton"
  },
  EN: {
    belgrade: "Belgrade Guide",
    noviSad: "Novi Sad Guide",
    lease: "Lease Agreement",
    beliKarton: "Beli Karton"
  },
  SR_LAT: {
    belgrade: "Vodič za Beograd",
    noviSad: "Vodič za Novi Sad",
    lease: "Ugovor o zakupu",
    beliKarton: "Beli karton"
  },
  SR_CYR: {
    belgrade: "Водич за Београд",
    noviSad: "Водич за Нови Сад",
    lease: "Уговор о закупу",
    beliKarton: "Бели картон"
  },
  RU: {
    belgrade: "Гайд по Белграду",
    noviSad: "Гайд по Нови-Саду",
    lease: "Договор аренды",
    beliKarton: "Белый картон"
  }
};

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

  // Mobile
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

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
    }, 180);
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

  const isDirectoryActive =
    pathname?.startsWith("/real-estate-agencies") ||
    pathname?.startsWith("/acente-bul") ||
    pathname?.startsWith("/find-agency");
  const isIndividualsActive = !isDirectoryActive && (pathname === "/" || pathname?.startsWith("/guide"));
  const isAgenciesActive = pathname?.startsWith("/agencies") || pathname?.startsWith("/agency-") || pathname?.startsWith("/agency_");

  const currentLangConfig = languages.find((l) => l.code === lang) || languages[0];
  const guideLabels = quickGuideLabels[lang] || quickGuideLabels.EN;

  const menus: Record<"individuals" | "agencies", { href: string; icon: LucideIcon; color: string; title: string; desc: string }[]> = {
    individuals: [
      { href: "/#features", icon: Users, color: "text-blue-600", title: t("nav_ind_overview_title"), desc: t("nav_ind_overview_desc") },
      { href: "/guide", icon: BookOpen, color: "text-indigo-600", title: t("nav_ind_guides_title"), desc: t("nav_ind_guides_desc") }
    ],
    agencies: [
      { href: "/agencies", icon: Building2, color: "text-purple-600", title: t("nav_agency_overview_title"), desc: t("nav_agency_overview_desc") },
      { href: "/agencies#section-whitelabel", icon: Layers, color: "text-violet-600", title: t("nav_agency_whitelabel_title"), desc: t("nav_agency_whitelabel_desc") },
      { href: "/agency-referral", icon: QrCode, color: "text-indigo-600", title: t("nav_agency_referral_title"), desc: t("nav_agency_referral_desc") },
      { href: "/agency-stats", icon: TrendingUp, color: "text-emerald-600", title: t("nav_agency_stats_title"), desc: t("nav_agency_stats_desc") },
      { href: "/agency-demo", icon: Sparkles, color: "text-amber-500", title: t("nav_agency_demo_title"), desc: t("nav_agency_demo_desc") }
    ]
  };
  const guideLinks = [
    { href: belgradeGuideRoutes[lang] || belgradeGuideRoutes.EN, icon: MapPin, color: "text-rose-500", label: guideLabels.belgrade },
    { href: noviSadGuideRoutes[lang] || noviSadGuideRoutes.EN, icon: MapPin, color: "text-rose-500", label: guideLabels.noviSad },
    { href: leaseAgreementGuideRoutes[lang] || leaseAgreementGuideRoutes.EN, icon: FileText, color: "text-blue-600", label: guideLabels.lease },
    { href: beliKartonGuideRoutes[lang] || beliKartonGuideRoutes.EN, icon: CheckCircle2, color: "text-emerald-600", label: guideLabels.beliKarton }
  ];

  const focus = "focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-600";
  const panel = "absolute top-full mt-2 bg-white rounded-lg border border-slate-200 shadow-lg p-1.5 z-50 before:content-[''] before:absolute before:inset-x-0 before:bottom-full before:h-2";
  const itemCls = `block rounded-md px-3 py-2 hover:bg-slate-50 ${focus}`;
  const topCls = (active: boolean) =>
    `inline-flex items-center gap-1 px-3 py-2 rounded-md text-sm cursor-pointer ${focus} ${
      active ? "text-slate-900 font-semibold" : "text-slate-600 hover:text-slate-900"
    }`;

  const renderDropdown = (key: "individuals" | "agencies", label: string, active: boolean, withGuides: boolean) => (
    <div className="relative" onMouseEnter={() => handleMouseEnter(key)} onMouseLeave={handleMouseLeave}>
      <button
        type="button"
        aria-expanded={openDropdown === key}
        aria-controls={`nav-${key}-menu`}
        onClick={() => setOpenDropdown(openDropdown === key ? null : key)}
        className={topCls(!!active || openDropdown === key)}
      >
        {label}
        <ChevronDown className={`w-4 h-4 text-slate-400 transition-transform ${openDropdown === key ? "rotate-180" : ""}`} />
      </button>
      {openDropdown === key && (
        <div id={`nav-${key}-menu`} className={`${panel} left-0 w-80`}>
          {menus[key].map((m) => (
            <Link key={m.href} href={m.href} aria-current={pathname === m.href ? "page" : undefined} className={`${itemCls} flex items-start gap-3`}>
              <m.icon className={`w-4 h-4 mt-0.5 flex-shrink-0 ${m.color}`} aria-hidden="true" />
              <span>
                <span className="block text-sm font-medium text-slate-900">{m.title}</span>
                <span className="block text-xs text-slate-500 mt-0.5">{m.desc}</span>
              </span>
            </Link>
          ))}
          {withGuides && (
            <div className="mt-1.5 pt-1.5 border-t border-slate-100">
              {guideLinks.map((g) => (
                <Link key={g.href} href={g.href} className={`${itemCls} text-sm text-slate-600 hover:text-slate-900 py-1.5 flex items-center gap-3`}>
                  <g.icon className={`w-4 h-4 flex-shrink-0 ${g.color}`} aria-hidden="true" />
                  {g.label}
                </Link>
              ))}
            </div>
          )}
        </div>
      )}
    </div>
  );

  return (
    <nav
      ref={navRef}
      aria-label="Primary"
      className="h-[80px] flex items-center fixed top-0 w-full z-[1000] bg-white border-b border-slate-200"
    >
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 w-full flex justify-between items-center">
        <div className="flex items-center gap-6">
          <a href="/" className={`flex items-center gap-2 no-underline flex-shrink-0 rounded-md ${focus}`}>
            <img src="/assets/logo.png" alt="Stanomer Logo" className="h-[30px] w-auto object-contain" />
            <span className="font-bold text-xl text-slate-900 tracking-tight">Stanomer</span>
          </a>

          <div className="hidden md:flex items-center gap-1">
            {renderDropdown("individuals", t("nav_for_individuals"), isIndividualsActive, true)}
            {renderDropdown("agencies", t("nav_for_agencies"), isAgenciesActive, false)}
            <Link
              href="/real-estate-agencies"
              aria-current={isDirectoryActive ? "page" : undefined}
              className={`${topCls(!!isDirectoryActive)} group text-blue-700 hover:text-blue-800 hover:bg-blue-50 active:bg-blue-100 transition-colors`}
            >
              <span className="underline-offset-4 group-hover:underline">{t("nav_ind_agencies_title")}</span>
              <ArrowUpRight className="w-3.5 h-3.5 opacity-60 transition group-hover:opacity-100 group-hover:translate-x-0.5 group-hover:-translate-y-0.5" aria-hidden="true" />
            </Link>
          </div>
        </div>

        <div className="flex items-center gap-2 sm:gap-3">
          {/* Language */}
          <div className="relative hidden md:block" onMouseEnter={() => handleMouseEnter("language")} onMouseLeave={handleMouseLeave}>
            <button
              type="button"
              aria-expanded={openDropdown === "language"}
              aria-controls="nav-language-menu"
              aria-label="Language Selector"
              onClick={() => setOpenDropdown(openDropdown === "language" ? null : "language")}
              className={`inline-flex items-center gap-1 px-2.5 py-2 rounded-md text-sm text-slate-600 hover:text-slate-900 cursor-pointer ${focus}`}
            >
              {currentLangConfig.codeLabel}
              <ChevronDown className="w-4 h-4 text-slate-400" />
            </button>
            {openDropdown === "language" && (
              <div id="nav-language-menu" className={`${panel} right-0 w-48`}>
                {languages.map((l) => (
                  <button
                    key={l.code}
                    type="button"
                    aria-current={lang === l.code ? "true" : undefined}
                    onClick={() => {
                      handleLanguageClick(l.code);
                      setOpenDropdown(null);
                    }}
                    className={`w-full text-left cursor-pointer text-sm ${itemCls} ${lang === l.code ? "font-semibold text-slate-900" : "text-slate-600"}`}
                  >
                    {l.nativeLabel}
                  </button>
                ))}
              </div>
            )}
          </div>

          {/* Request Demo */}
          <Link
            href="/agency-demo"
            aria-current={pathname === "/agency-demo" ? "page" : undefined}
            className={`hidden lg:inline-flex items-center gap-1.5 px-3.5 py-2 rounded-md text-sm font-semibold text-purple-700 border border-purple-200 hover:bg-purple-50 hover:border-purple-300 transition-colors ${focus}`}
          >
            <Sparkles className="w-4 h-4" aria-hidden="true" />
            {t("agencies_cta_demo")}
          </Link>

          {/* Get the app */}
          <div className="relative hidden sm:block" onMouseEnter={() => handleMouseEnter("app")} onMouseLeave={handleMouseLeave}>
            <button
              type="button"
              aria-expanded={openDropdown === "app"}
              aria-controls="nav-app-menu"
              onClick={() => setOpenDropdown(openDropdown === "app" ? null : "app")}
              className={`inline-flex items-center gap-1.5 bg-blue-600 hover:bg-blue-700 text-white text-sm font-semibold px-4 py-2 rounded-md cursor-pointer ${focus}`}
            >
              {t("nav_btn_get_app")}
              <ChevronDown className="w-4 h-4" />
            </button>
            {openDropdown === "app" && (
              <div id="nav-app-menu" className={`${panel} right-0 w-64`}>
                <Link href={WEB_APP_URL} className={`${itemCls} flex items-start gap-3`}>
                  <Globe className="w-4 h-4 mt-0.5 text-sky-600 flex-shrink-0" aria-hidden="true" />
                  <span>
                    <span className="block text-sm font-medium text-slate-900">{t("nav_web_app_title")}</span>
                    <span className="block text-xs text-slate-500 mt-0.5">{t("nav_web_app_sub")}</span>
                  </span>
                </Link>
                <a href={IOS_APP_URL} target="_blank" rel="noopener noreferrer" className={itemCls}>
                  <span className="flex items-center justify-between text-sm font-medium text-slate-900">
                    App Store <ArrowUpRight className="w-3.5 h-3.5 text-slate-400" />
                  </span>
                  <span className="block text-xs text-slate-500 mt-0.5">{t("nav_app_store_sub")}</span>
                </a>
                <a href={ANDROID_APP_URL} target="_blank" rel="noopener noreferrer" className={itemCls}>
                  <span className="flex items-center justify-between text-sm font-medium text-slate-900">
                    Google Play <ArrowUpRight className="w-3.5 h-3.5 text-slate-400" />
                  </span>
                  <span className="block text-xs text-slate-500 mt-0.5">{t("nav_google_play_sub")}</span>
                </a>
              </div>
            )}
          </div>

          <button
            type="button"
            aria-expanded={mobileMenuOpen}
            aria-label="Toggle Menu"
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            className={`md:hidden p-2 rounded-md text-slate-700 hover:bg-slate-100 ${focus}`}
          >
            {mobileMenuOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
          </button>
        </div>
      </div>

      {/* Mobile drawer */}
      {mobileMenuOpen && (
        <div className="md:hidden fixed top-[80px] left-0 w-full h-[calc(100dvh-80px)] bg-white z-[999] overflow-y-auto px-5 py-4">
          {(["individuals", "agencies"] as const).map((key) => (
            <section key={key} className="py-3 border-b border-slate-100">
              <h2 className="text-xs font-semibold uppercase tracking-wide text-slate-400 mb-1">
                {key === "individuals" ? t("nav_for_individuals") : t("nav_for_agencies")}
              </h2>
              {menus[key].map((m) => (
                <Link key={m.href} href={m.href} onClick={() => setMobileMenuOpen(false)} className="block py-2 text-sm font-medium text-slate-900">
                  {m.title}
                </Link>
              ))}
              {key === "individuals" &&
                guideLinks.map((g) => (
                  <Link key={g.href} href={g.href} onClick={() => setMobileMenuOpen(false)} className="block py-1.5 text-sm text-slate-600">
                    {g.label}
                  </Link>
                ))}
            </section>
          ))}
          <Link
            href="/real-estate-agencies"
            aria-current={isDirectoryActive ? "page" : undefined}
            onClick={() => setMobileMenuOpen(false)}
            className="block py-4 border-b border-slate-100 text-sm font-medium text-slate-900"
          >
            {t("nav_ind_agencies_title")}
          </Link>

          <section className="py-3 border-b border-slate-100">
            <h2 className="text-xs font-semibold uppercase tracking-wide text-slate-400 mb-1">{t("nav_btn_get_app")}</h2>
            <Link href={WEB_APP_URL} onClick={() => setMobileMenuOpen(false)} className="block py-2 text-sm font-medium text-slate-900">
              {t("nav_web_app_title")}
            </Link>
            <a href={IOS_APP_URL} target="_blank" rel="noopener noreferrer" className="block py-2 text-sm text-slate-600">App Store</a>
            <a href={ANDROID_APP_URL} target="_blank" rel="noopener noreferrer" className="block py-2 text-sm text-slate-600">Google Play</a>
          </section>

          <section className="py-3">
            <h2 className="text-xs font-semibold uppercase tracking-wide text-slate-400 mb-2">{t("language") || "Language"}</h2>
            <div className="flex flex-wrap gap-2">
              {languages.map((l) => (
                <button
                  key={l.code}
                  type="button"
                  aria-current={lang === l.code ? "true" : undefined}
                  onClick={() => {
                    handleLanguageClick(l.code);
                    setMobileMenuOpen(false);
                  }}
                  className={`px-3 py-1.5 rounded-md text-sm border ${
                    lang === l.code ? "border-slate-900 text-slate-900 font-semibold" : "border-slate-200 text-slate-600"
                  }`}
                >
                  {l.codeLabel}
                </button>
              ))}
            </div>
          </section>
        </div>
      )}
    </nav>
  );
}
