"use client";

import React from "react";
import { useLanguage } from "./LanguageProvider";
import { Crown, Trash2, ShieldCheck, FileText, ChevronDown, Menu } from "lucide-react";

export function LegalLayout({ children, activeTab }: { children: React.ReactNode, activeTab: "privacy" | "terms" | "support" }) {
  const { lang, setLang, t } = useLanguage();

  return (
    <div className="min-h-screen flex flex-col font-sans bg-bg-light">
      {/* Navbar (Identical to landing page) */}
      <nav className="h-[80px] flex items-center fixed top-0 w-full z-[1000] bg-white/90 backdrop-blur-[12px] border-b border-[#EBEBEB]">
        <div className="max-w-[1200px] mx-auto px-8 w-full flex justify-between items-center">
          {/* Mobile Menu Toggle (matching landing) */}
          <button className="lg:hidden text-brand-blue p-2">
            <Menu className="w-6 h-6" />
          </button>

          {/* Logo */}
          <a href="/" className="flex items-center gap-[0.8rem] no-underline">
            <img src="/assets/logo.png" alt="Stanomer Logo" className="h-[48px] w-auto object-contain" />
            <span className="font-bold text-[1.8rem] text-brand-blue tracking-tight">Stanomer</span>
          </a>

          {/* Nav Links (Desktop) */}
          <div className="hidden lg:flex items-center gap-[2.5rem]">
            <a href="/#features" className="no-underline text-[#4A4A4A] font-bold hover:text-brand-blue transition-colors">Özellikler</a>
            <a href="/#roles" className="no-underline text-[#4A4A4A] font-bold hover:text-brand-blue transition-colors">Roller</a>
          </div>

          {/* Actions */}
          <div className="flex items-center gap-[1.5rem]">
            <a 
              href="/app" 
              className="hidden lg:block bg-brand-blue text-white px-[1.5rem] py-[0.8rem] rounded-[10px] font-extrabold no-underline hover:shadow-lg transition-all"
            >
              Uygulamaya Git
            </a>

            <div className="lang-switcher">
              <select 
                value={lang} 
                onChange={(e) => setLang(e.target.value as any)}
                className="bg-white border border-[#EBEBEB] px-[0.6rem] py-[0.4rem] rounded-[8px] font-semibold text-brand-blue cursor-pointer outline-none text-sm"
              >
                <option value="TR">TR</option>
                <option value="EN">EN</option>
                <option value="SR_LAT">SR (Lat)</option>
                <option value="SR_CYR">SR (Кри)</option>
              </select>
            </div>
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
            © {new Date().getFullYear()} Stanomer PropTech. All rights reserved.
          </p>
        </div>
      </footer>
    </div>
  );
}
