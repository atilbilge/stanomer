"use client";

import React, { useEffect } from "react";
import { usePathname, useRouter } from "next/navigation";
import { useLanguage, Language } from "./LanguageProvider";
import { captureUtmParams } from "../lib/utm";

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

export function Navbar() {
  const { lang, setLang } = useLanguage();
  const pathname = usePathname();
  const router = useRouter();

  useEffect(() => {
    captureUtmParams();
  }, []);

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

  return (
    <nav className="h-[80px] flex items-center fixed top-0 w-full z-[1000] bg-white/80 backdrop-blur-[16px] border-b border-gray-200/80">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 w-full flex justify-between items-center">
        {/* Logo */}
        <a href="/" className="flex items-center gap-[0.5rem] no-underline">
          <img src="/assets/logo.png" alt="Stanomer Logo" className="h-[32px] w-auto object-contain" style={{ height: "32px", width: "auto" }} />
          <span className="font-bold text-[1.4rem] text-gray-900 tracking-tight">Stanomer</span>
        </a>

        {/* Language Switcher in Site Header */}
        <div className="flex items-center gap-1.5 sm:gap-2">
          {[
            { code: "EN", label: "EN" },
            { code: "SR_LAT", label: "SR" },
            { code: "SR_CYR", label: "СРБ" },
            { code: "RU", label: "RU" },
            { code: "TR", label: "TR" }
          ].map((l) => (
            <button
              key={l.code}
              type="button"
              onClick={() => handleLanguageClick(l.code as Language)}
              className={`text-[12px] sm:text-[13px] font-semibold transition-all px-2 py-1 rounded-md cursor-pointer ${
                lang === l.code 
                  ? "text-brand-blue bg-brand-blue/15 shadow-sm font-bold border border-brand-blue/20" 
                  : "text-gray-500 hover:text-gray-900 hover:bg-gray-100"
              }`}
            >
              {l.label}
            </button>
          ))}
        </div>
      </div>
    </nav>
  );
}
