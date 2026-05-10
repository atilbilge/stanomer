"use client";

import React from "react";
import { useLanguage } from "../components/LanguageProvider";
import { Apple, Play, ArrowRight, Shield, Cloud, Heart, ClipboardList, FileText, Bell, Wrench, Globe } from "lucide-react";

export function HomeContent() {
  const { t } = useLanguage();

  return (
    <div className="min-h-screen flex flex-col font-sans bg-bg-light">
      {/* Hero Section */}
      <section className="max-w-[680px] mx-auto px-6 pt-12 pb-6">
        <div className="bg-white border border-[#EBEBEB] rounded-3xl p-12 text-center shadow-sm">
          <div className="inline-block px-3 py-1 rounded-lg bg-brand-blue/10 text-brand-blue text-[11px] font-bold uppercase tracking-wider mb-6">
            {t("hero_badge")}
          </div>
          <h1 className="text-[30px] font-bold text-gray-900 leading-tight mb-4" dangerouslySetInnerHTML={{ __html: t("hero_title") }} />
          <p className="text-[15px] text-gray-600 leading-relaxed mb-8 max-w-[480px] mx-auto">
            {t("hero_desc")}
          </p>
          
          <div className="flex flex-wrap justify-center gap-3 mb-6">
            <a href="https://apps.apple.com/us/app/stanomer/id6762311157" target="_blank" className="flex items-center gap-2 px-5 py-2.5 bg-black text-white rounded-lg font-bold text-sm hover:opacity-80 transition-all">
              <Apple className="w-5 h-5" />
              App Store
            </a>
            <a href="https://play.google.com/store/apps/details?id=com.aboptima.stanomer" target="_blank" className="flex items-center gap-2 px-5 py-2.5 bg-white border border-gray-200 text-gray-900 rounded-lg font-bold text-sm hover:bg-gray-50 transition-all">
              <Play className="w-5 h-5 fill-current" />
              Google Play
            </a>
          </div>

          <div className="mb-6">
            <a href="https://app.stanomer.com" target="_blank" className="inline-flex items-center gap-2 px-7 py-3 bg-gray-900 text-white rounded-lg font-medium text-[14px] hover:opacity-90 transition-all">
              {t("btn_web_app")}
            </a>
          </div>

          <p className="text-[12px] text-gray-400">
            {t("hero_note")}
          </p>
        </div>
      </section>

      {/* Pain Strip */}
      <section className="max-w-[680px] mx-auto px-6 py-3">
        <div className="bg-white border border-[#EBEBEB] rounded-xl p-6 text-[14px] text-gray-600 leading-relaxed" dangerouslySetInnerHTML={{ __html: t("pain_strip") }} />
      </section>

      {/* Roles Grid */}
      <section className="max-w-[680px] mx-auto px-6 py-6">
        <div className="text-[11px] font-bold text-gray-400 uppercase tracking-widest mb-4">
          {t("roles_label")}
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div className="bg-white border border-[#EBEBEB] rounded-2xl p-6">
            <h3 className="text-[18px] font-bold text-gray-900 mb-4">{t("roles_landlord")}</h3>
            <div className="space-y-3">
              {[1, 2, 3, 4].map((i) => (
                <div key={i} className="flex gap-3 text-[13px] text-gray-600 items-start py-2 border-b border-gray-50 last:border-0">
                  <div className="w-1.5 h-1.5 rounded-full bg-brand-blue mt-1.5 flex-shrink-0" />
                  <span>{t(`roles_landlord_${i}`)}</span>
                </div>
              ))}
            </div>
          </div>
          <div className="bg-white border border-[#EBEBEB] rounded-2xl p-6">
            <h3 className="text-[18px] font-bold text-gray-900 mb-4">{t("roles_tenant")}</h3>
            <div className="space-y-3">
              {[1, 2, 3, 4].map((i) => (
                <div key={i} className="flex gap-3 text-[13px] text-gray-600 items-start py-2 border-b border-gray-50 last:border-0">
                  <div className="w-1.5 h-1.5 rounded-full bg-brand-blue mt-1.5 flex-shrink-0" />
                  <span>{t(`roles_tenant_${i}`)}</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      </section>

      {/* Steps */}
      <section className="max-w-[680px] mx-auto px-6 py-6">
        <div className="bg-white border border-[#EBEBEB] rounded-2xl p-8">
          <h2 className="text-[20px] font-bold text-gray-900 mb-6">{t("steps_title")}</h2>
          <div className="space-y-8">
            {[1, 2, 3].map((i) => (
              <div key={i} className="flex gap-4">
                <div className="w-8 h-8 rounded-full border border-gray-200 bg-white flex items-center justify-center text-[13px] font-bold text-gray-900 flex-shrink-0">
                  {i}
                </div>
                <div>
                  <h4 className="text-[15px] font-bold text-gray-900 mb-1">{t(`step_${i}_title`)}</h4>
                  <p className="text-[14px] text-gray-600 leading-relaxed">{t(`step_${i}_desc`)}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Trust Grid */}
      <section className="max-w-[680px] mx-auto px-6 py-6">
        <div className="text-[11px] font-bold text-gray-400 uppercase tracking-widest mb-4">
          {t("trust_label")}
        </div>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
          <div className="bg-white border border-[#EBEBEB] rounded-xl p-5 text-center">
            <Shield className="w-6 h-6 text-brand-blue mx-auto mb-3" />
            <h4 className="text-[14px] font-bold text-gray-900 mb-2">{t("trust_1_title")}</h4>
            <p className="text-[12px] text-gray-500 leading-normal">{t("trust_1_desc")}</p>
          </div>
          <div className="bg-white border border-[#EBEBEB] rounded-xl p-5 text-center">
            <Cloud className="w-6 h-6 text-brand-blue mx-auto mb-3" />
            <h4 className="text-[14px] font-bold text-gray-900 mb-2">{t("trust_2_title")}</h4>
            <p className="text-[12px] text-gray-500 leading-normal">{t("trust_2_desc")}</p>
          </div>
          <div className="bg-white border border-[#EBEBEB] rounded-xl p-5 text-center">
            <Heart className="w-6 h-6 text-brand-blue mx-auto mb-3" />
            <h4 className="text-[14px] font-bold text-gray-900 mb-2">{t("trust_3_title")}</h4>
            <p className="text-[12px] text-gray-500 leading-normal">{t("trust_3_desc")}</p>
          </div>
        </div>
      </section>

      {/* Features List */}
      <section className="max-w-[680px] mx-auto px-6 py-6">
        <div className="text-[11px] font-bold text-gray-400 uppercase tracking-widest mb-4">
          {t("features_label")}
        </div>
        <div className="space-y-0 border-t border-[#EBEBEB]">
          {[
            { i: 1, icon: ClipboardList },
            { i: 2, icon: FileText },
            { i: 3, icon: Bell },
            { i: 4, icon: Wrench },
            { i: 5, icon: Globe },
          ].map(({ i, icon: Icon }) => (
            <div key={i} className="flex gap-4 py-6 border-b border-[#EBEBEB]">
              <div className="w-10 h-10 rounded-lg bg-brand-blue/10 flex items-center justify-center flex-shrink-0 text-brand-blue">
                <Icon className="w-5 h-5" />
              </div>
              <div>
                <h4 className="text-[15px] font-bold text-gray-900 mb-1">{t(`feature_${i}_title`)}</h4>
                <p className="text-[14px] text-gray-600 leading-relaxed">{t(`feature_${i}_desc`)}</p>
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* Footer CTA */}
      <section className="max-w-[680px] mx-auto px-6 py-12">
        <div className="bg-white border border-[#EBEBEB] rounded-3xl p-10 text-center shadow-sm">
          <h2 className="text-[24px] font-bold text-gray-900 mb-3">{t("footer_cta_title")}</h2>
          <p className="text-[14px] text-gray-600 leading-relaxed mb-8" dangerouslySetInnerHTML={{ __html: t("footer_cta_desc") }} />
          
          <div className="flex flex-wrap justify-center gap-3 mb-6">
            <a href="https://apps.apple.com/us/app/stanomer/id6762311157" target="_blank" className="flex items-center gap-2 px-5 py-2.5 bg-black text-white rounded-lg font-bold text-sm hover:opacity-80 transition-all">
              <Apple className="w-5 h-5" />
              App Store
            </a>
            <a href="https://play.google.com/store/apps/details?id=com.aboptima.stanomer" target="_blank" className="flex items-center gap-2 px-5 py-2.5 bg-white border border-gray-200 text-gray-900 rounded-lg font-bold text-sm hover:bg-gray-50 transition-all">
              <Play className="w-5 h-5 fill-current" />
              Google Play
            </a>
          </div>

          <div>
            <a href="https://app.stanomer.com" target="_blank" className="inline-flex items-center gap-2 px-7 py-3 bg-gray-900 text-white rounded-lg font-medium text-[14px] hover:opacity-90 transition-all">
              {t("btn_web_app")}
            </a>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="py-12 border-t border-gray-100 mt-12">
        <div className="max-w-[680px] mx-auto px-6 text-center">
          <div className="flex items-center justify-center gap-2 opacity-40 grayscale mb-6">
            <div className="w-6 h-6 rounded bg-black flex items-center justify-center text-white text-xs font-bold">S</div>
            <span className="font-bold text-sm tracking-tight">Stanomer</span>
          </div>
          
          <div className="flex flex-wrap justify-center gap-x-6 gap-y-2 mb-6 text-[12px] font-medium text-gray-500">
            <a href="/privacy" className="hover:text-brand-blue transition-colors">{t("footer_privacy")}</a>
            <a href="/terms" className="hover:text-brand-blue transition-colors">{t("footer_terms")}</a>
            <a href="/support" className="hover:text-brand-blue transition-colors">{t("footer_support")}</a>
          </div>

          <p className="text-gray-400 text-[11px]">
            © 2026 Stanomer. {t("footer_rights")}
          </p>
        </div>
      </footer>
    </div>
  );
}
