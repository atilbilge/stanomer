"use client";

import React from "react";
import { useLanguage } from "./LanguageProvider";
import { Navbar } from "./Navbar";
import { Crown, Trash2, ShieldCheck, FileText, Headphones } from "lucide-react";

export function LegalLayout({ children, activeTab }: { children: React.ReactNode, activeTab: "privacy" | "terms" | "support" }) {
  const { t } = useLanguage();

  return (
    <div className="min-h-screen flex flex-col font-sans bg-transparent text-gray-100">
      <Navbar />

      {/* Spacer */}
      <div className="h-[80px]" />

      {/* Main Content */}
      <main className="flex-grow max-w-[680px] mx-auto px-8 py-12 w-full bg-[#0F172A]/75 backdrop-blur-[16px] rounded-3xl border border-white/10 shadow-2xl my-8">
        {/* Tab Switcher */}
        <div className="flex gap-1 bg-gray-800/50 p-1 rounded-xl mb-12 w-fit">
          <a
            href="/privacy"
            className={`px-6 py-2 rounded-lg text-[13px] font-semibold transition-all flex items-center gap-2 ${
              activeTab === "privacy" ? "bg-gray-700 text-white shadow-sm" : "text-gray-400 hover:text-gray-200"
            }`}
          >
            <ShieldCheck className="w-4 h-4" />
            {t("privacy_title")}
          </a>
          <a
            href="/terms"
            className={`px-6 py-2 rounded-lg text-[13px] font-semibold transition-all flex items-center gap-2 ${
              activeTab === "terms" ? "bg-gray-700 text-white shadow-sm" : "text-gray-400 hover:text-gray-200"
            }`}
          >
            <FileText className="w-4 h-4" />
            {t("terms_title")}
          </a>
          <a
            href="/support"
            className={`px-6 py-2 rounded-lg text-[13px] font-semibold transition-all flex items-center gap-2 ${
              activeTab === "support" ? "bg-gray-700 text-white shadow-sm" : "text-gray-400 hover:text-gray-200"
            }`}
          >
            <Headphones className="w-4 h-4" />
            {t("support_title")}
          </a>
        </div>

        <div className="text-gray-200">
          {children}
        </div>

        {/* Legal Sections */}
        <section className="mt-16 grid md:grid-cols-2 gap-6 pt-16 border-t border-white/10">
          <div className="p-6 rounded-2xl bg-brand-green/10 border border-brand-green/20">
            <div className="w-10 h-10 rounded-full bg-brand-green/20 flex items-center justify-center mb-4">
              <Crown className="w-5 h-5 text-brand-green" />
            </div>
            <h3 className="text-brand-green text-[15px] font-bold mb-2">{t("restore_purchases_title")}</h3>
            <p className="text-gray-300 text-[13px] leading-relaxed">
              {t("restore_purchases_desc")}
            </p>
          </div>
          
          <div className="p-6 rounded-2xl bg-red-950/20 border border-red-900/30">
            <div className="w-10 h-10 rounded-full bg-red-900/20 flex items-center justify-center mb-4">
              <Trash2 className="w-5 h-5 text-red-400" />
            </div>
            <h3 className="text-red-400 text-[15px] font-bold mb-2">{t("delete_account_title")}</h3>
            <p className="text-gray-300 text-[13px] leading-relaxed">
              {t("delete_account_desc")}
            </p>
          </div>
        </section>
      </main>

      {/* Footer */}
      <footer className="py-12 border-t border-white/10 mt-24">
        <div className="max-w-[680px] mx-auto px-6 text-center">
          <div className="flex items-center justify-center gap-2 opacity-50 mb-4">
            <div className="w-6 h-6 rounded bg-white flex items-center justify-center text-black text-xs font-bold">S</div>
            <span className="font-bold text-sm text-white">Stanomer</span>
          </div>
          <p className="text-gray-500 text-xs">
            © 2026 Stanomer. All rights reserved.
          </p>
        </div>
      </footer>
    </div>
  );
}
