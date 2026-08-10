"use client";

import React from "react";
import Link from "next/link";
import { Navbar } from "../../components/Navbar";
import { useLanguage } from "../../components/LanguageProvider";
import { Palette, ShieldCheck, UserCheck, CheckCircle2, ArrowRight, Sparkles, Building2, ChevronRight } from "lucide-react";

export default function AgenciesPage() {
  const { t } = useLanguage();

  return (
    <div className="min-h-screen bg-slate-50 flex flex-col font-sans text-slate-900 overflow-x-hidden">
      <Navbar />

      {/* Spacer for fixed Navbar */}
      <div className="h-[80px]" />

      {/* SECTION 1: HERO SECTION (Above-the-Fold) */}
      <section className="relative pt-12 pb-20 md:pt-20 md:pb-32 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto w-full">
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 lg:gap-8 items-center">
          
          {/* Left Side: Copy & Dual CTAs */}
          <div className="lg:col-span-7 space-y-6 text-left">
            <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-blue-50 border border-blue-200/80 text-blue-700 text-xs sm:text-sm font-semibold tracking-wide shadow-sm">
              <Sparkles className="w-4 h-4 text-blue-600 animate-pulse" />
              <span>{t("agencies_hero_badge")}</span>
            </div>

            <h1 className="text-3xl sm:text-4xl lg:text-5xl font-extrabold text-slate-900 tracking-tight leading-[1.15]">
              {t("agencies_hero_title")}
            </h1>

            <p className="text-base sm:text-lg text-slate-600 leading-relaxed max-w-2xl">
              {t("agencies_hero_subtitle")}
            </p>

            {/* Side-by-Side CTA Buttons */}
            <div className="pt-4 flex flex-col sm:flex-row gap-4 sm:items-center">
              <Link
                href="/agency-demo"
                className="inline-flex justify-center items-center gap-2.5 px-7 py-4 rounded-xl text-white bg-blue-600 hover:bg-blue-700 font-bold text-base shadow-xl shadow-blue-500/25 transition-all transform hover:-translate-y-0.5 active:translate-y-0"
              >
                <span>{t("agencies_cta_demo")}</span>
                <ArrowRight className="w-5 h-5" />
              </Link>

              <Link
                href="/agency-demo"
                className="inline-flex justify-center items-center gap-2 px-7 py-4 rounded-xl text-slate-800 bg-white hover:bg-slate-100 border border-slate-300 font-semibold text-base shadow-sm transition-all hover:border-slate-400"
              >
                <span>{t("agencies_cta_free")}</span>
                <ChevronRight className="w-4 h-4 text-slate-400" />
              </Link>
            </div>
          </div>

          {/* Right Side: White-Label Product Mockup Showcase */}
          <div className="lg:col-span-5 relative flex justify-center items-center">
            {/* Background Glow */}
            <div className="absolute inset-0 bg-blue-400/20 rounded-full blur-3xl transform scale-90 -z-10" />

            {/* Dashboard Backdrop Mockup */}
            <div className="w-full max-w-md bg-white/90 backdrop-blur-md rounded-2xl p-5 border border-slate-200/80 shadow-2xl space-y-4 transform -rotate-1 hover:rotate-0 transition duration-500">
              
              {/* Fake Agency Header */}
              <div className="flex items-center justify-between pb-3 border-b border-slate-100">
                <div className="flex items-center gap-2.5">
                  <div className="w-8 h-8 rounded-lg bg-amber-500/20 text-amber-600 flex items-center justify-center font-bold text-xs">
                    <Building2 className="w-4 h-4 text-amber-600" />
                  </div>
                  <div>
                    <p className="text-xs font-bold text-slate-900">ABC REAL ESTATE</p>
                    <p className="text-[10px] text-slate-400">White-Label Partner Panel</p>
                  </div>
                </div>
                <span className="text-[10px] font-semibold bg-emerald-50 text-emerald-700 px-2 py-0.5 rounded-md border border-emerald-200">
                  {t("agencies_mockup_active_agency")}
                </span>
              </div>

              {/* Stats Grid Mockup */}
              <div className="grid grid-cols-2 gap-2.5">
                <div className="bg-slate-50 p-3 rounded-xl border border-slate-100">
                  <p className="text-[10px] text-slate-500 font-medium">{t("agencies_mockup_active_portfolio")}</p>
                  <p className="text-lg font-extrabold text-slate-900">{t("agencies_mockup_apartments_count")}</p>
                </div>
                <div className="bg-blue-50/60 p-3 rounded-xl border border-blue-100">
                  <p className="text-[10px] text-blue-600 font-medium">{t("agencies_mockup_monthly_collected")}</p>
                  <p className="text-lg font-extrabold text-blue-700">€28,500</p>
                </div>
              </div>

              {/* Mobile Phone Mockup Overlay */}
              <div className="bg-slate-900 text-white rounded-xl p-4 shadow-lg space-y-2.5 border border-slate-800">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <div className="w-6 h-6 rounded-md bg-amber-500 flex items-center justify-center font-bold text-[10px] text-slate-950">
                      ABC
                    </div>
                    <span className="text-xs font-semibold text-slate-200">{t("agencies_mockup_mobile_ui")}</span>
                  </div>
                  <span className="w-2 h-2 rounded-full bg-emerald-400 animate-ping" />
                </div>
                <div className="bg-slate-800/90 p-2.5 rounded-lg text-xs space-y-1">
                  <p className="text-slate-400 text-[10px]">{t("agencies_mockup_tenant_notif")}</p>
                  <p className="font-semibold text-emerald-400">{t("agencies_mockup_rent_collected")}</p>
                  <p className="text-[10px] text-slate-300">{t("agencies_mockup_auto_notif_sent")}</p>
                </div>
              </div>

              {/* Floating Badge */}
              <div className="absolute -bottom-3 -left-3 bg-white text-slate-800 px-3.5 py-2 rounded-xl shadow-lg border border-slate-200 text-xs font-bold flex items-center gap-2">
                <span className="w-2.5 h-2.5 rounded-full bg-blue-600" />
                <span>{t("agencies_mockup_white_label_badge")}</span>
              </div>
            </div>
          </div>

        </div>
      </section>

      {/* SECTION 2: VALUE PROPOSITION (Feature Grid) */}
      <section className="py-16 md:py-24 bg-white border-y border-slate-200/80 px-4 sm:px-6 lg:px-8">
        <div className="max-w-7xl mx-auto space-y-16">
          <div className="text-center max-w-3xl mx-auto space-y-3">
            <h2 className="text-2xl sm:text-3xl font-extrabold text-slate-900 tracking-tight">
              {t("agencies_val_title")}
            </h2>
            <div className="w-16 h-1 bg-blue-600 mx-auto rounded-full" />
          </div>

          {/* 3-Column Feature Grid */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            
            {/* Feature 1: White-Label Branding */}
            <div className="bg-slate-50/80 p-8 rounded-2xl border border-slate-200/80 hover:shadow-xl hover:bg-white transition-all duration-300 group">
              <div className="w-14 h-14 rounded-2xl bg-blue-100 text-blue-600 flex items-center justify-center mb-6 group-hover:scale-110 transition-transform">
                <Palette className="w-7 h-7" />
              </div>
              <h3 className="text-xl font-bold text-slate-900 mb-3">
                {t("agencies_val_1_title")}
              </h3>
              <p className="text-slate-600 text-sm leading-relaxed">
                {t("agencies_val_1_desc")}
              </p>
            </div>

            {/* Feature 2: Full Authority Portfolio Management */}
            <div className="bg-slate-50/80 p-8 rounded-2xl border border-slate-200/80 hover:shadow-xl hover:bg-white transition-all duration-300 group">
              <div className="w-14 h-14 rounded-2xl bg-amber-100 text-amber-600 flex items-center justify-center mb-6 group-hover:scale-110 transition-transform">
                <ShieldCheck className="w-7 h-7" />
              </div>
              <h3 className="text-xl font-bold text-slate-900 mb-3">
                {t("agencies_val_2_title")}
              </h3>
              <p className="text-slate-600 text-sm leading-relaxed">
                {t("agencies_val_2_desc")}
              </p>
            </div>

            {/* Feature 3: Seamless Integration */}
            <div className="bg-slate-50/80 p-8 rounded-2xl border border-slate-200/80 hover:shadow-xl hover:bg-white transition-all duration-300 group">
              <div className="w-14 h-14 rounded-2xl bg-emerald-100 text-emerald-600 flex items-center justify-center mb-6 group-hover:scale-110 transition-transform">
                <UserCheck className="w-7 h-7" />
              </div>
              <h3 className="text-xl font-bold text-slate-900 mb-3">
                {t("agencies_val_3_title")}
              </h3>
              <p className="text-slate-600 text-sm leading-relaxed">
                {t("agencies_val_3_desc")}
              </p>
            </div>

          </div>
        </div>
      </section>

      {/* SECTION 3: HOW IT WORKS & COMPARISON (Checklist Cards) */}
      <section className="py-16 md:py-24 bg-slate-50 px-4 sm:px-6 lg:px-8">
        <div className="max-w-5xl mx-auto space-y-12">
          <div className="text-center max-w-3xl mx-auto space-y-4">
            <h2 className="text-2xl sm:text-3xl font-extrabold text-slate-900 tracking-tight">
              {t("agencies_how_title")}
            </h2>
            <p className="text-slate-600 text-base leading-relaxed">
              {t("agencies_how_intro")}
            </p>
          </div>

          {/* Checklist Comparison Cards */}
          <div className="space-y-4">
            
            {/* Check Item 1 */}
            <div className="bg-white p-6 sm:p-7 rounded-2xl border border-slate-200 shadow-sm hover:shadow-md transition flex items-start gap-4">
              <div className="w-8 h-8 rounded-full bg-emerald-100 text-emerald-600 flex items-center justify-center flex-shrink-0 mt-0.5">
                <CheckCircle2 className="w-5 h-5 text-emerald-600" />
              </div>
              <div className="space-y-1">
                <p className="text-base sm:text-lg font-bold text-slate-900">
                  {t("agencies_how_1")}
                </p>
              </div>
            </div>

            {/* Check Item 2 */}
            <div className="bg-white p-6 sm:p-7 rounded-2xl border border-slate-200 shadow-sm hover:shadow-md transition flex items-start gap-4">
              <div className="w-8 h-8 rounded-full bg-emerald-100 text-emerald-600 flex items-center justify-center flex-shrink-0 mt-0.5">
                <CheckCircle2 className="w-5 h-5 text-emerald-600" />
              </div>
              <div className="space-y-1">
                <p className="text-base sm:text-lg font-bold text-slate-900">
                  {t("agencies_how_2")}
                </p>
              </div>
            </div>

            {/* Check Item 3 */}
            <div className="bg-white p-6 sm:p-7 rounded-2xl border border-slate-200 shadow-sm hover:shadow-md transition flex items-start gap-4">
              <div className="w-8 h-8 rounded-full bg-emerald-100 text-emerald-600 flex items-center justify-center flex-shrink-0 mt-0.5">
                <CheckCircle2 className="w-5 h-5 text-emerald-600" />
              </div>
              <div className="space-y-1">
                <p className="text-base sm:text-lg font-bold text-slate-900">
                  {t("agencies_how_3")}
                </p>
              </div>
            </div>

          </div>
        </div>
      </section>

      {/* SECTION 4: BOTTOM CTA BAND */}
      <section className="py-16 md:py-20 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto w-full mb-12">
        <div className="bg-gradient-to-r from-slate-900 via-blue-950 to-slate-900 rounded-3xl p-8 sm:p-14 text-center text-white border border-slate-800 shadow-2xl relative overflow-hidden">
          
          {/* Background Glow Overlay */}
          <div className="absolute -top-24 -right-24 w-72 h-72 bg-blue-500/20 rounded-full blur-3xl pointer-events-none" />
          <div className="absolute -bottom-24 -left-24 w-72 h-72 bg-amber-500/10 rounded-full blur-3xl pointer-events-none" />

          <div className="relative z-10 max-w-3xl mx-auto space-y-8">
            <h2 className="text-2xl sm:text-3xl lg:text-4xl font-extrabold tracking-tight leading-tight">
              {t("agencies_bottom_title")}
            </h2>

            <div className="flex flex-col sm:flex-row justify-center gap-4">
              <Link
                href="/agency-demo"
                className="inline-flex justify-center items-center gap-2 px-8 py-4 rounded-xl text-white bg-blue-600 hover:bg-blue-500 font-bold text-base shadow-xl shadow-blue-600/30 transition"
              >
                <span>{t("agencies_cta_demo")}</span>
                <ArrowRight className="w-5 h-5" />
              </Link>

              <Link
                href="/agency-demo"
                className="inline-flex justify-center items-center gap-2 px-8 py-4 rounded-xl text-slate-200 bg-slate-800/80 hover:bg-slate-800 border border-slate-700 font-semibold text-base transition"
              >
                <span>{t("agencies_cta_free")}</span>
              </Link>
            </div>
          </div>
        </div>
      </section>

    </div>
  );
}
