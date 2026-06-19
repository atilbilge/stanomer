"use client";

import React from "react";
import { useLanguage } from "./LanguageProvider";
import { Navbar } from "./Navbar";
import { Crown, Trash2, ShieldCheck, FileText, Headphones, History } from "lucide-react";

export function LegalLayout({ children, activeTab }: { children: React.ReactNode, activeTab: "privacy" | "terms" | "support" | "changelog" }) {
  const { t } = useLanguage();

  return (
    <div className="min-h-screen flex flex-col font-sans bg-transparent text-gray-900">
      <Navbar />

      {/* Spacer */}
      <div className="h-[80px]" />

      {/* Main Content */}
      <main className="flex-grow max-w-[680px] mx-auto px-4 sm:px-8 py-8 md:py-12 w-full bg-white/80 backdrop-blur-[16px] rounded-2xl md:rounded-3xl border border-gray-200 shadow-xl my-4 md:my-8">
        {/* Tab Switcher */}
        <div className="grid grid-cols-2 sm:flex sm:flex-row gap-1 bg-gray-100/80 p-1 rounded-xl mb-8 md:mb-12 w-full sm:w-fit border border-gray-200/50">
          <a
            href="/privacy"
            className={`px-3 sm:px-6 py-2.5 sm:py-2 rounded-lg text-[12px] sm:text-[13px] font-semibold transition-all flex items-center justify-center gap-2 ${
              activeTab === "privacy" ? "bg-white text-gray-900 border border-gray-200/60 shadow-sm" : "text-gray-500 hover:text-gray-800"
            }`}
          >
            <ShieldCheck className="w-4 h-4 flex-shrink-0" />
            {t("privacy_title")}
          </a>
          <a
            href="/terms"
            className={`px-3 sm:px-6 py-2.5 sm:py-2 rounded-lg text-[12px] sm:text-[13px] font-semibold transition-all flex items-center justify-center gap-2 ${
              activeTab === "terms" ? "bg-white text-gray-900 border border-gray-200/60 shadow-sm" : "text-gray-500 hover:text-gray-800"
            }`}
          >
            <FileText className="w-4 h-4 flex-shrink-0" />
            {t("terms_title")}
          </a>
          <a
            href="/changelog"
            className={`px-3 sm:px-6 py-2.5 sm:py-2 rounded-lg text-[12px] sm:text-[13px] font-semibold transition-all flex items-center justify-center gap-2 ${
              activeTab === "changelog" ? "bg-white text-gray-900 border border-gray-200/60 shadow-sm" : "text-gray-500 hover:text-gray-800"
            }`}
          >
            <History className="w-4 h-4 flex-shrink-0" />
            {t("footer_changelog")}
          </a>
          <a
            href="/support"
            className={`px-3 sm:px-6 py-2.5 sm:py-2 rounded-lg text-[12px] sm:text-[13px] font-semibold transition-all flex items-center justify-center gap-2 ${
              activeTab === "support" ? "bg-white text-gray-900 border border-gray-200/60 shadow-sm" : "text-gray-500 hover:text-gray-800"
            }`}
          >
            <Headphones className="w-4 h-4 flex-shrink-0" />
            {t("support_title")}
          </a>
        </div>

        <div className="text-gray-800">
          {children}
        </div>

        {/* Legal Sections */}
        <section className="mt-8 md:mt-16 grid md:grid-cols-2 gap-6 pt-8 md:pt-16 border-t border-gray-200">
          <div className="p-6 rounded-2xl bg-brand-green/10 border border-brand-green/20">
            <div className="w-10 h-10 rounded-full bg-brand-green/20 flex items-center justify-center mb-4">
              <Crown className="w-5 h-5 text-brand-green" />
            </div>
            <h3 className="text-brand-green text-[15px] font-bold mb-2">{t("restore_purchases_title")}</h3>
            <p className="text-gray-600 text-[13px] leading-relaxed">
              {t("restore_purchases_desc")}
            </p>
          </div>
          
          <div className="p-6 rounded-2xl bg-red-50/80 border border-red-200/60">
            <div className="w-10 h-10 rounded-full bg-red-100 flex items-center justify-center mb-4">
              <Trash2 className="w-5 h-5 text-red-600" />
            </div>
            <h3 className="text-red-700 text-[15px] font-bold mb-2">{t("delete_account_title")}</h3>
            <p className="text-gray-600 text-[13px] leading-relaxed">
              {t("delete_account_desc")}
            </p>
          </div>
        </section>
      </main>

      {/* Footer */}
      <footer className="py-12 border-t border-gray-200 mt-24">
        <div className="max-w-[680px] mx-auto px-6 text-center">
          <div className="flex items-center justify-center gap-2 opacity-50 mb-4">
            <img src="/assets/logo.png" alt="Stanomer Logo" className="w-6 h-6 object-contain" />
            <span className="font-bold text-sm text-gray-800">Stanomer</span>
          </div>

          <div className="flex flex-wrap justify-center gap-x-6 gap-y-2 mb-6 text-[12px] font-medium text-gray-500">
            <a href="/privacy" className="hover:text-brand-blue transition-colors">{t("footer_privacy")}</a>
            <a href="/terms" className="hover:text-brand-blue transition-colors">{t("footer_terms")}</a>
            <a href="/changelog" className="hover:text-brand-blue transition-colors">{t("footer_changelog")}</a>
            <a href="/support" className="hover:text-brand-blue transition-colors">{t("footer_support")}</a>
          </div>

          <p className="text-gray-500 text-xs">
            © 2026 Stanomer. All rights reserved.
          </p>
        </div>
      </footer>
    </div>
  );
}
