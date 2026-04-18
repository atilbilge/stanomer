"use client";

import React from "react";
import { useLanguage } from "./LanguageProvider";
import { Crown, Trash2, ShieldCheck, FileText, ChevronDown } from "lucide-react";

export function LegalLayout({ children, activeTab }: { children: React.ReactNode, activeTab: "privacy" | "terms" }) {
  const { lang, setLang, t } = useLanguage();

  return (
    <div className="min-h-screen flex flex-col font-sans bg-gray-50/50">
      {/* Header */}
      <nav className="fixed top-0 w-full h-20 z-[1000] bg-white/90 backdrop-blur-xl border-b border-gray-100">
        <div className="max-w-[1200px] mx-auto px-8 h-full flex justify-between items-center">
          {/* Logo */}
          <a href="/" className="flex items-center gap-3 no-underline">
            <img src="/assets/logo.png" alt="Stanomer Logo" className="h-12 w-auto object-contain" />
            <span className="font-bold text-[1.85rem] text-brand-blue tracking-tight">Stanomer</span>
          </a>

          {/* Navigation & Actions */}
          <div className="flex items-center gap-10">
            {/* Desktop Nav Links */}
            <div className="hidden lg:flex items-center gap-10 font-semibold text-gray-700">
              <a href="/#features" className="hover:text-brand-blue transition-colors">Özellikler</a>
              <a href="/#roles" className="hover:text-brand-blue transition-colors">Roller</a>
            </div>

            <div className="flex items-center gap-6">
              {/* Go to App Button */}
              <a 
                href="/app" 
                className="hidden md:block px-6 py-2.5 bg-brand-blue text-white rounded-[10px] font-bold hover:shadow-lg hover:-translate-y-0.5 transition-all"
              >
                {t("nav_app") || "Uygulamaya Git"}
              </a>

              {/* Language Switcher */}
              <div className="relative group">
                <button className="flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-gray-50 border border-gray-100 text-sm font-bold text-gray-700 hover:bg-white hover:shadow-sm transition-all focus:outline-none">
                  {lang === "SR_LAT" ? "SR (Lat)" : lang === "SR_CYR" ? "SR (Кри)" : lang}
                  <ChevronDown className="w-4 h-4 opacity-50" />
                </button>
                <div className="absolute right-0 top-full mt-2 w-36 bg-white rounded-xl shadow-xl border border-gray-100 opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all p-1.5 overflow-hidden ring-1 ring-black/5">
                  {(["TR", "EN", "SR_LAT", "SR_CYR"] as const).map((l) => (
                    <button
                      key={l}
                      onClick={() => setLang(l)}
                      className={`w-full text-left px-3 py-2 rounded-lg text-sm font-bold transition-colors ${
                        lang === l ? "bg-brand-blue/10 text-brand-blue" : "text-gray-600 hover:bg-gray-50"
                      }`}
                    >
                      {l === "SR_LAT" ? "SR (Lat)" : l === "SR_CYR" ? "SR (Кри)" : l}
                    </button>
                  ))}
                </div>
              </div>
            </div>
          </div>
        </div>
      </nav>

      {/* Spacer for fixed header */}
      <div className="h-20" />

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
            © {new Date().getFullYear()} Stanomer PropTech. All rights reserved.
          </p>
        </div>
      </footer>
    </div>
  );
}
