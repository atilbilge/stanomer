"use client";

import React from "react";
import { useLanguage } from "./LanguageProvider";
import { Crown, Trash2, ShieldCheck, FileText, ChevronDown, Menu, Headphones } from "lucide-react";

export function LegalLayout({ children, activeTab }: { children: React.ReactNode, activeTab: "privacy" | "terms" | "support" }) {
  const { lang, setLang, t } = useLanguage();

  return (
    <div className="min-h-screen flex flex-col font-sans bg-bg-light">
      {/* Navbar (Identical to landing page) */}
      <nav className="h-[80px] flex items-center fixed top-0 w-full z-[1000] bg-white/90 backdrop-blur-[12px] border-b border-[#EBEBEB]">
        <div className="max-w-[1200px] mx-auto px-8 w-full flex justify-between items-center">
          {/* Logo */}
          <a href="/" className="flex items-center gap-[0.8rem] no-underline">
            <img src="/assets/logo.png" alt="Stanomer Logo" className="h-[32px] w-auto object-contain" />
            <span className="font-bold text-[1.5rem] text-brand-blue tracking-tight">Stanomer</span>
          </a>

          {/* Language Switcher */}
          <div className="flex items-center gap-[1rem]">
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
                className={`text-[0.9rem] font-bold transition-all ${
                  lang === l.code ? "text-brand-blue scale-110" : "text-[#999] hover:text-brand-blue"
                }`}
              >
                {l.label}
              </button>
            ))}
          </div>
        </div>
      </nav>

      {/* Spacer */}
      <div className="h-[80px]" />

      {/* Main Content */}
      <main className="flex-grow max-w-4xl mx-auto px-4 py-12 w-full">
        {/* Tab Switcher */}
        <div className="flex gap-1 bg-gray-100/50 p-1 rounded-xl mb-12 w-fit">
          <a
            href="/privacy"
            className={`px-6 py-2 rounded-lg text-sm font-semibold transition-all flex items-center gap-2 ${
              activeTab === "privacy" ? "bg-white text-gray-900 shadow-sm" : "text-gray-500 hover:text-gray-700"
            }`}
          >
            <ShieldCheck className="w-4 h-4" />
            {t("privacy_title")}
          </a>
          <a
            href="/terms"
            className={`px-6 py-2 rounded-lg text-sm font-semibold transition-all flex items-center gap-2 ${
              activeTab === "terms" ? "bg-white text-gray-900 shadow-sm" : "text-gray-500 hover:text-gray-700"
            }`}
          >
            <FileText className="w-4 h-4" />
            {t("terms_title")}
          </a>
          <a
            href="/support"
            className={`px-6 py-2 rounded-lg text-sm font-semibold transition-all flex items-center gap-2 ${
              activeTab === "support" ? "bg-white text-gray-900 shadow-sm" : "text-gray-500 hover:text-gray-700"
            }`}
          >
            <Headphones className="w-4 h-4" />
            {t("support_title")}
          </a>
        </div>

        {children}

        {/* Legal Sections */}
        <section className="mt-16 grid md:grid-cols-2 gap-6 pt-16 border-t border-gray-100">
          <div className="p-6 rounded-2xl bg-brand-green/5 border border-brand-green/10">
            <div className="w-10 h-10 rounded-full bg-brand-green/10 flex items-center justify-center mb-4">
              <Crown className="w-5 h-5 text-brand-green" />
            </div>
            <h3 className="text-brand-green text-lg font-bold mb-2">{t("restore_purchases_title")}</h3>
            <p className="text-gray-600 text-sm leading-relaxed">
              {t("restore_purchases_desc")}
            </p>
          </div>
          
          <div className="p-6 rounded-2xl bg-red-50 border border-red-100">
            <div className="w-10 h-10 rounded-full bg-red-100 flex items-center justify-center mb-4">
              <Trash2 className="w-5 h-5 text-red-600" />
            </div>
            <h3 className="text-red-600 text-lg font-bold mb-2">{t("delete_account_title")}</h3>
            <p className="text-gray-600 text-sm leading-relaxed">
              {t("delete_account_desc")}
            </p>
          </div>
        </section>
      </main>

      {/* Footer */}
      <footer className="py-12 border-t border-gray-100 mt-24">
        <div className="max-w-4xl mx-auto px-4 text-center">
          <div className="flex items-center justify-center gap-2 opacity-40 grayscale mb-4">
            <div className="w-6 h-6 rounded bg-black flex items-center justify-center text-white text-xs font-bold">S</div>
            <span className="font-bold text-sm">Stanomer</span>
          </div>
          <p className="text-gray-400 text-xs">
            © 2026 Stanomer. All rights reserved.
          </p>
        </div>
      </footer>
    </div>
  );
}
