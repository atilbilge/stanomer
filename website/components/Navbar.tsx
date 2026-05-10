"use client";

import React from "react";
import { useLanguage } from "./LanguageProvider";

export function Navbar() {
  const { lang, setLang } = useLanguage();

  return (
    <nav className="h-[80px] flex items-center fixed top-0 w-full z-[1000] bg-white/90 backdrop-blur-[12px] border-b border-[#EBEBEB]">
      <div className="max-w-[680px] mx-auto px-6 w-full flex justify-between items-center">
        {/* Logo */}
        <a href="/" className="flex items-center gap-[0.5rem] no-underline">
          <img src="/assets/logo.png" alt="Stanomer Logo" className="h-[32px] w-auto object-contain" />
          <span className="font-bold text-[1.4rem] text-brand-blue tracking-tight">Stanomer</span>
        </a>

        {/* Language Switcher */}
        <div className="flex items-center gap-[0.75rem]">
          {[
            { code: "TR", label: "TR" },
            { code: "EN", label: "EN" },
            { code: "SR_LAT", label: "SR" },
            { code: "SR_CYR", label: "СР" },
            { code: "RU", label: "RU" }
          ].map((l) => (
            <button
              key={l.code}
              onClick={() => setLang(l.code as any)}
              className={`text-[13px] font-semibold transition-all px-1.5 py-0.5 rounded ${
                lang === l.code ? "text-brand-blue bg-brand-blue/10" : "text-[#9CA3AF] hover:text-brand-blue"
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
