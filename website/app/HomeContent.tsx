"use client";

import React from "react";
import { useLanguage } from "../components/LanguageProvider";
import { Apple, Play, Shield, Cloud, Heart, ClipboardList, FileText, Bell, Wrench, Globe } from "lucide-react";

export function HomeContent() {
  const { t } = useLanguage();

  return (
    <div className="min-h-screen flex flex-col font-sans bg-transparent text-gray-100">
      {/* Hero Section */}
      <section className="max-w-[680px] mx-auto px-6 pt-16 pb-6 w-full relative overflow-visible">
        {/* Glow Effects */}
        <div className="absolute top-1/4 left-1/4 -translate-x-1/2 -translate-y-1/2 w-80 h-80 rounded-full bg-brand-blue/30 blur-[120px] pointer-events-none z-0" />
        <div className="absolute bottom-1/4 right-1/4 translate-x-1/2 translate-y-1/2 w-64 h-64 rounded-full bg-brand-green/20 blur-[100px] pointer-events-none z-0" />

        <div className="relative z-10 bg-[#0F172A]/75 backdrop-blur-[20px] border border-white/15 rounded-3xl p-12 text-center shadow-[0_0_50px_rgba(59,130,246,0.15)] transition-all duration-300 hover:border-white/25">
          <div className="inline-flex items-center gap-1.5 px-3.5 py-1 rounded-full bg-brand-blue/15 border border-brand-blue/30 text-brand-blue text-[11px] font-bold uppercase tracking-wider mb-6 animate-pulse">
            <span className="w-1.5 h-1.5 rounded-full bg-brand-blue" />
            {t("hero_badge")}
          </div>
          <h1 className="text-[34px] font-extrabold text-white leading-tight mb-5 tracking-tight" dangerouslySetInnerHTML={{ __html: t("hero_title") }} />
          <p className="text-[15px] text-gray-300 leading-relaxed mb-8 max-w-[480px] mx-auto">
            {t("hero_desc")}
          </p>
          
          <div className="flex flex-wrap justify-center gap-3 mb-8">
            <a href="https://apps.apple.com/us/app/stanomer/id6762311157" target="_blank" className="flex items-center gap-2 px-5.5 py-2.5 bg-black border border-white/10 hover:border-white/25 text-white rounded-xl font-bold text-sm hover:scale-[1.02] active:scale-[0.98] transition-all">
              <Apple className="w-5 h-5" />
              App Store
            </a>
            <a href="https://play.google.com/store/apps/details?id=com.aboptima.stanomer" target="_blank" className="flex items-center gap-2 px-5.5 py-2.5 bg-gray-800/80 border border-white/10 hover:border-white/25 text-white rounded-xl font-bold text-sm hover:scale-[1.02] active:scale-[0.98] transition-all">
              <Play className="w-5 h-5 fill-current" />
              Google Play
            </a>
          </div>

          <div className="mb-6">
            <a href="/app/login" className="inline-flex items-center gap-2 px-8 py-3.5 bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-500 hover:to-indigo-500 text-white rounded-xl font-bold text-[15px] shadow-[0_0_20px_rgba(59,130,246,0.3)] hover:shadow-[0_0_25px_rgba(59,130,246,0.5)] hover:scale-[1.03] active:scale-[0.97] transition-all duration-300">
              {t("btn_web_app")}
            </a>
          </div>

          <p className="text-[12px] text-gray-400">
            {t("hero_note")}
          </p>
        </div>
      </section>

      {/* Pain Strip */}
      <section className="max-w-[680px] mx-auto px-6 py-3 w-full">
        <div className="bg-[#0F172A]/75 backdrop-blur-[16px] border border-white/10 rounded-xl p-6 text-[14px] text-gray-300 leading-relaxed" dangerouslySetInnerHTML={{ __html: t("pain_strip") }} />
      </section>

      {/* Roles Grid */}
      <section className="max-w-[680px] mx-auto px-6 py-6 w-full">
        <div className="text-[11px] font-bold text-gray-400 uppercase tracking-widest mb-4">
          {t("roles_label")}
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div className="bg-[#0F172A]/75 backdrop-blur-[16px] border border-white/10 rounded-2xl p-6">
            <h3 className="text-[18px] font-bold text-white mb-4">{t("roles_landlord")}</h3>
            <div className="space-y-3">
              {[1, 2, 3, 4].map((i) => (
                <div key={i} className="flex gap-3 text-[13px] text-gray-300 items-start py-2 border-b border-white/5 last:border-0">
                  <div className="w-1.5 h-1.5 rounded-full bg-brand-blue mt-1.5 flex-shrink-0" />
                  <span>{t(`roles_landlord_${i}`)}</span>
                </div>
              ))}
            </div>
          </div>
          <div className="bg-[#0F172A]/75 backdrop-blur-[16px] border border-white/10 rounded-2xl p-6">
            <h3 className="text-[18px] font-bold text-white mb-4">{t("roles_tenant")}</h3>
            <div className="space-y-3">
              {[1, 2, 3, 4].map((i) => (
                <div key={i} className="flex gap-3 text-[13px] text-gray-300 items-start py-2 border-b border-white/5 last:border-0">
                  <div className="w-1.5 h-1.5 rounded-full bg-brand-blue mt-1.5 flex-shrink-0" />
                  <span>{t(`roles_tenant_${i}`)}</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      </section>

      {/* Steps */}
      <section className="max-w-[680px] mx-auto px-6 py-6 w-full">
        <div className="bg-[#0F172A]/75 backdrop-blur-[16px] border border-white/10 rounded-2xl p-8">
          <h2 className="text-[20px] font-bold text-white mb-6">{t("steps_title")}</h2>
          <div className="space-y-8">
            {[1, 2, 3].map((i) => (
              <div key={i} className="flex gap-4">
                <div className="w-8 h-8 rounded-full border border-white/10 bg-[#0F172A] flex items-center justify-center text-[13px] font-bold text-white flex-shrink-0">
                  {i}
                </div>
                <div>
                  <h4 className="text-[15px] font-bold text-white mb-1">{t(`step_${i}_title`)}</h4>
                  <p className="text-[14px] text-gray-300 leading-relaxed">{t(`step_${i}_desc`)}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Trust Grid */}
      <section className="max-w-[680px] mx-auto px-6 py-6 w-full">
        <div className="text-[11px] font-bold text-gray-400 uppercase tracking-widest mb-4">
          {t("trust_label")}
        </div>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
          <div className="bg-[#0F172A]/75 backdrop-blur-[16px] border border-white/10 rounded-xl p-5 text-center">
            <Shield className="w-6 h-6 text-brand-blue mx-auto mb-3" />
            <h4 className="text-[14px] font-bold text-white mb-2">{t("trust_1_title")}</h4>
            <p className="text-[12px] text-gray-400 leading-normal">{t("trust_1_desc")}</p>
          </div>
          <div className="bg-[#0F172A]/75 backdrop-blur-[16px] border border-[#EBEBEB]/10 rounded-xl p-5 text-center">
            <Cloud className="w-6 h-6 text-brand-blue mx-auto mb-3" />
            <h4 className="text-[14px] font-bold text-white mb-2">{t("trust_2_title")}</h4>
            <p className="text-[12px] text-gray-400 leading-normal">{t("trust_2_desc")}</p>
          </div>
          <div className="bg-[#0F172A]/75 backdrop-blur-[16px] border border-[#EBEBEB]/10 rounded-xl p-5 text-center">
            <Heart className="w-6 h-6 text-brand-blue mx-auto mb-3" />
            <h4 className="text-[14px] font-bold text-white mb-2">{t("trust_3_title")}</h4>
            <p className="text-[12px] text-gray-400 leading-normal">{t("trust_3_desc")}</p>
          </div>
        </div>
      </section>

      {/* Features List */}
      <section className="max-w-[680px] mx-auto px-6 py-6 w-full">
        <div className="text-[11px] font-bold text-gray-400 uppercase tracking-widest mb-4">
          {t("features_label")}
        </div>
        <div className="space-y-0 border-t border-white/10">
          {[
            { i: 1, icon: ClipboardList },
            { i: 2, icon: FileText },
            { i: 3, icon: Bell },
            { i: 4, icon: Wrench },
            { i: 5, icon: Globe },
          ].map(({ i, icon: Icon }) => (
            <div key={i} className="flex gap-4 py-6 border-b border-white/10">
              <div className="w-10 h-10 rounded-lg bg-brand-blue/20 flex items-center justify-center flex-shrink-0 text-brand-blue">
                <Icon className="w-5 h-5" />
              </div>
              <div>
                <h4 className="text-[15px] font-bold text-white mb-1">{t(`feature_${i}_title`)}</h4>
                <p className="text-[14px] text-gray-300 leading-relaxed">{t(`feature_${i}_desc`)}</p>
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* Footer CTA */}
      <section className="max-w-[680px] mx-auto px-6 py-12 w-full">
        <div className="bg-[#0F172A]/75 backdrop-blur-[16px] border border-white/10 rounded-3xl p-10 text-center shadow-2xl">
          <h2 className="text-[24px] font-bold text-white mb-3">{t("footer_cta_title")}</h2>
          <p className="text-[14px] text-gray-300 leading-relaxed mb-8" dangerouslySetInnerHTML={{ __html: t("footer_cta_desc") }} />
          
          <div className="flex flex-wrap justify-center gap-3 mb-6">
            <a href="https://apps.apple.com/us/app/stanomer/id6762311157" target="_blank" className="flex items-center gap-2 px-5 py-2.5 bg-black border border-white/10 text-white rounded-lg font-bold text-sm hover:opacity-80 transition-all">
              <Apple className="w-5 h-5" />
              App Store
            </a>
            <a href="https://play.google.com/store/apps/details?id=com.aboptima.stanomer" target="_blank" className="flex items-center gap-2 px-5 py-2.5 bg-gray-800 border border-white/10 text-white rounded-lg font-bold text-sm hover:bg-gray-700 transition-all">
              <Play className="w-5 h-5 fill-current" />
              Google Play
            </a>
          </div>

          <div>
            <a href="/app/login" className="inline-flex items-center gap-2 px-7 py-3 bg-white text-gray-900 rounded-lg font-bold text-[14px] hover:bg-gray-100 transition-all">
              {t("btn_web_app")}
            </a>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="py-12 border-t border-white/10 mt-12 w-full">
        <div className="max-w-[680px] mx-auto px-6 text-center">
          <div className="flex items-center justify-center gap-2 opacity-50 mb-6">
            <div className="w-6 h-6 rounded bg-white flex items-center justify-center text-black text-xs font-bold">S</div>
            <span className="font-bold text-sm tracking-tight text-white">Stanomer</span>
          </div>
          
          <div className="flex flex-wrap justify-center gap-x-6 gap-y-2 mb-6 text-[12px] font-medium text-gray-400">
            <a href="/privacy" className="hover:text-brand-blue transition-colors">{t("footer_privacy")}</a>
            <a href="/terms" className="hover:text-brand-blue transition-colors">{t("footer_terms")}</a>
            <a href="/support" className="hover:text-brand-blue transition-colors">{t("footer_support")}</a>
          </div>

          <p className="text-gray-500 text-[11px]">
            © 2026 Stanomer. {t("footer_rights")}
          </p>
        </div>
      </footer>
    </div>
  );
}
