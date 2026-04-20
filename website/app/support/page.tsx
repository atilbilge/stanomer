"use client";

import React from "react";
import { LegalLayout } from "../../components/LegalLayout";
import { useLanguage } from "../../components/LanguageProvider";
import { Mail, Clock, Headphones } from "lucide-react";

export default function SupportPage() {
  const { t } = useLanguage();

  return (
    <LegalLayout activeTab="support">
      <div className="space-y-8 animate-in fade-in slide-in-from-bottom-4 duration-700">
        <section>
          <div className="flex items-center gap-3 mb-6">
            <div className="p-2 rounded-lg bg-brand-blue/10 text-brand-blue">
              <Headphones className="w-5 h-5" />
            </div>
            <h2 className="text-2xl font-bold text-gray-900">{t("support_title")}</h2>
          </div>
          
          <div className="bg-white border border-gray-100 rounded-2xl p-8 shadow-sm">
            <p className="text-gray-600 mb-8 leading-relaxed">
              {t("support_desc")}
            </p>

            <div className="flex flex-col sm:flex-row gap-4">
              <a 
                href="mailto:aboptimasoftware@gmail.com"
                className="flex items-center gap-3 px-6 py-4 rounded-xl border border-gray-100 hover:border-brand-blue hover:bg-brand-blue/5 transition-all group"
              >
                <Mail className="w-5 h-5 text-brand-blue group-hover:scale-110 transition-transform" />
                <div>
                  <p className="text-xs font-bold text-gray-400 uppercase tracking-wider mb-0.5">{t("support_email_label")}</p>
                  <p className="text-brand-blue font-semibold">aboptimasoftware@gmail.com</p>
                </div>
              </a>

              <div className="flex items-center gap-3 px-6 py-4 rounded-xl border border-gray-100 bg-gray-50/50">
                <Clock className="w-5 h-5 text-gray-400" />
                <div>
                  <p className="text-xs font-bold text-gray-400 uppercase tracking-wider mb-0.5">Response Time</p>
                  <p className="text-gray-600 font-semibold">24-48 Hours</p>
                </div>
              </div>
            </div>
          </div>
        </section>

        <div className="p-6 rounded-2xl bg-brand-blue/5 border border-brand-blue/10 text-sm text-brand-blue/80 italic">
          Tip: You can also reach support directly through the Stanomer mobile app settings.
        </div>
      </div>
    </LegalLayout>
  );
}
