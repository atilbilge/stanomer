"use client";

import React, { useState, useEffect } from "react";
import Link from "next/link";
import { useLanguage } from "../components/LanguageProvider";
import { InteractiveFlow } from "../components/InteractiveFlow";
import {
  Shield,
  Cloud,
  Heart,
  ClipboardList,
  FileText,
  Bell,
  Wrench,
  Globe,
  Sparkles,
  ArrowRight,
  CheckCircle2,
  Check,
  Building2,
  Calendar,
  AlertCircle
} from "lucide-react";

export function HomeContent() {
  const { t } = useLanguage();
  const [deviceOS, setDeviceOS] = useState<string | null>(null);

  useEffect(() => {
    const userAgent = window.navigator.userAgent || window.navigator.vendor;
    const isIOS =
      /iPad|iPhone|iPod/.test(userAgent) ||
      (window.navigator.platform === "MacIntel" && window.navigator.maxTouchPoints > 1);
    const isAndroid = /android/i.test(userAgent);

    if (isIOS) {
      setDeviceOS("ios");
    } else if (isAndroid) {
      setDeviceOS("android");
    } else {
      setDeviceOS("desktop");
    }
  }, []);

  return (
    <div className="min-h-screen flex flex-col font-sans bg-transparent text-slate-900 overflow-x-hidden">

      {/* ========================================================================= */}
      {/* SECTION 1: HERO SECTION (Left-Aligned 2-Column + Realistic Mockup)        */}
      {/* ========================================================================= */}
      <section className="relative pt-12 pb-16 md:pt-20 md:pb-24 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto w-full">
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 lg:gap-8 items-center">
          
          {/* Left Side: Headline & CTAs */}
          <div className="lg:col-span-7 space-y-6 text-left">
            <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-blue-50 border border-blue-200/80 text-blue-700 text-xs sm:text-sm font-semibold tracking-wide shadow-sm">
              <Sparkles className="w-4 h-4 text-blue-600 animate-pulse" />
              <span>{t("hero_badge")}</span>
            </div>

            <h1
              className="text-3xl sm:text-4xl lg:text-5xl font-extrabold text-slate-900 tracking-tight leading-[1.15]"
              dangerouslySetInnerHTML={{ __html: t("hero_title") }}
            />

            <p className="text-base sm:text-lg text-slate-600 leading-relaxed max-w-2xl">
              {t("hero_desc")}
            </p>

            {/* Store & Web Buttons */}
            <div className="pt-2 space-y-3">
              {deviceOS === null || deviceOS === "desktop" ? (
                <div className="flex flex-wrap items-center gap-3">
                  <a
                    href="https://apps.apple.com/us/app/stanomer/id6762311157"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-flex transition-opacity hover:opacity-85"
                  >
                    <img
                      src="https://upload.wikimedia.org/wikipedia/commons/9/91/Download_on_the_App_Store_RGB_blk.svg"
                      alt="Download on the App Store"
                      className="h-10 w-[135px] block"
                    />
                  </a>
                  <a
                    href="https://play.google.com/store/apps/details?id=com.aboptima.stanomer"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-flex transition-opacity hover:opacity-85"
                  >
                    <img
                      src="https://upload.wikimedia.org/wikipedia/commons/7/78/Google_Play_Store_badge_EN.svg"
                      alt="Get it on Google Play"
                      className="h-10 w-[135px] block"
                    />
                  </a>
                  <a
                    href="/app"
                    className="h-10 inline-flex items-center justify-center gap-2 bg-slate-900 hover:bg-slate-800 text-white active:scale-[0.98] font-semibold text-xs tracking-wide px-5 rounded-xl border border-slate-900 shadow-md transition-all"
                  >
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      width="18"
                      height="18"
                      viewBox="0 0 24 24"
                      fill="none"
                      stroke="currentColor"
                      strokeWidth="2"
                      strokeLinecap="round"
                      strokeLinejoin="round"
                    >
                      <circle cx="12" cy="12" r="10"></circle>
                      <line x1="2" y1="12" x2="22" y2="12"></line>
                      <path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"></path>
                    </svg>
                    <span>{t("btn_web_app")}</span>
                  </a>
                </div>
              ) : deviceOS === "ios" ? (
                <div className="flex flex-wrap gap-3">
                  <a
                    href="https://apps.apple.com/us/app/stanomer/id6762311157"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-flex transition-opacity hover:opacity-85"
                  >
                    <img
                      src="https://upload.wikimedia.org/wikipedia/commons/9/91/Download_on_the_App_Store_RGB_blk.svg"
                      alt="Download on the App Store"
                      className="h-10 w-[135px] block"
                    />
                  </a>
                </div>
              ) : (
                <div className="flex flex-wrap gap-3">
                  <a
                    href="https://play.google.com/store/apps/details?id=com.aboptima.stanomer"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-flex transition-opacity hover:opacity-85"
                  >
                    <img
                      src="https://upload.wikimedia.org/wikipedia/commons/7/78/Google_Play_Store_badge_EN.svg"
                      alt="Get it on Google Play"
                      className="h-10 w-[135px] block"
                    />
                  </a>
                </div>
              )}

              <p className="text-xs text-slate-500 font-medium">
                {t("hero_note")}
              </p>
            </div>
          </div>

          {/* Right Side: Clean Card Container with Realistic Property Mockup */}
          <div className="lg:col-span-5 relative flex justify-center items-center">
            {/* Background Glow */}
            <div className="absolute inset-0 bg-blue-500/15 rounded-full blur-3xl transform scale-95 -z-10" />

            {/* Product Card Container */}
            <div className="w-full max-w-md bg-white/95 backdrop-blur-md rounded-2xl p-5 border border-slate-200/90 shadow-2xl space-y-4 transform hover:scale-[1.01] transition duration-300">
              
              {/* Card Header: Property Identity */}
              <div className="flex items-center justify-between pb-3 border-b border-slate-100">
                <div className="flex items-center gap-3">
                  <div className="w-9 h-9 rounded-xl bg-blue-100 text-blue-600 flex items-center justify-center font-bold text-sm">
                    🏢
                  </div>
                  <div>
                    <p className="text-xs font-bold text-slate-900">Beograd Daire 12</p>
                    <p className="text-[10px] text-slate-500 font-medium">Milan Jovanović • Aktif Kiracı</p>
                  </div>
                </div>
                <span className="text-[10px] font-bold bg-emerald-50 text-emerald-700 px-2.5 py-1 rounded-md border border-emerald-200/80 inline-flex items-center gap-1">
                  <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse" />
                  Aktif Kontrat
                </span>
              </div>

              {/* Property Stats & Status */}
              <div className="grid grid-cols-2 gap-2.5">
                <div className="bg-slate-50 p-3 rounded-xl border border-slate-100">
                  <p className="text-[10px] text-slate-500 font-semibold">Aylık Kira</p>
                  <p className="text-base font-extrabold text-slate-900">€650 <span className="text-[10px] text-emerald-600 font-bold ml-1">✓ Ödendi</span></p>
                </div>
                <div className="bg-blue-50/70 p-3 rounded-xl border border-blue-100">
                  <p className="text-[10px] text-blue-600 font-semibold">Kontrat Süresi</p>
                  <p className="text-base font-extrabold text-blue-700">234 Gün Kalan</p>
                </div>
              </div>

              {/* Live Rent Notification Box */}
              <div className="bg-slate-900 text-white rounded-xl p-3.5 shadow-lg space-y-2 border border-slate-800">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <span className="text-xs font-bold text-slate-200">Ağustos 2026 Kira Ödemesi</span>
                  </div>
                  <span className="text-[10px] font-bold bg-emerald-500/20 text-emerald-400 px-2 py-0.5 rounded">
                    Onaylandı
                  </span>
                </div>
                <div className="bg-slate-800/90 p-2.5 rounded-lg text-xs space-y-1">
                  <div className="flex justify-between text-[10px] text-slate-300">
                    <span>Dekont Numarası: #TRX-8921</span>
                    <span>12 Ağustos 2026</span>
                  </div>
                  <p className="text-[11px] font-semibold text-emerald-300">€650 banka transferi onaylandı</p>
                </div>
              </div>

              {/* Maintenance Ticket Status */}
              <div className="bg-amber-50/80 border border-amber-200/80 rounded-xl p-3 flex items-center justify-between">
                <div className="flex items-center gap-2.5">
                  <div className="w-6 h-6 rounded-md bg-amber-200 text-amber-800 flex items-center justify-center text-xs font-bold">
                    🔧
                  </div>
                  <div>
                    <p className="text-[11px] font-bold text-amber-950">Kombi Yıllık Bakımı</p>
                    <p className="text-[10px] text-amber-700">Teknisyen randevusu tamamlandı</p>
                  </div>
                </div>
                <span className="text-[10px] font-bold text-amber-800 bg-amber-100 px-2 py-0.5 rounded">
                  Tamamlandı
                </span>
              </div>

            </div>
          </div>

        </div>
      </section>

      {/* ========================================================================= */}
      {/* SECTION 2: SORUN ANLATIMI ("Tanıdık Geliyor Mu?" - 3 Bullets Format)       */}
      {/* ========================================================================= */}
      <section className="py-12 md:py-16 bg-white/70 backdrop-blur-md border-y border-slate-200/80 px-4 sm:px-6 lg:px-8">
        <div className="max-w-5xl mx-auto space-y-8">
          
          <div className="text-center max-w-2xl mx-auto space-y-2">
            <h2 className="text-2xl sm:text-3xl font-extrabold text-slate-900 tracking-tight">
              {t("pain_strip_title")}
            </h2>
            <div className="w-12 h-1 bg-blue-600 mx-auto rounded-full" />
          </div>

          {/* 3 Pain Cards */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            
            <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm hover:shadow-md transition space-y-3">
              <div className="w-10 h-10 rounded-xl bg-red-100 text-red-600 flex items-center justify-center font-bold text-lg">
                📄
              </div>
              <p className="text-sm font-semibold text-slate-800 leading-relaxed">
                {t("pain_strip_1")}
              </p>
            </div>

            <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm hover:shadow-md transition space-y-3">
              <div className="w-10 h-10 rounded-xl bg-amber-100 text-amber-600 flex items-center justify-center font-bold text-lg">
                💬
              </div>
              <p className="text-sm font-semibold text-slate-800 leading-relaxed">
                {t("pain_strip_2")}
              </p>
            </div>

            <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm hover:shadow-md transition space-y-3">
              <div className="w-10 h-10 rounded-xl bg-blue-100 text-blue-600 flex items-center justify-center font-bold text-lg">
                🔍
              </div>
              <p className="text-sm font-semibold text-slate-800 leading-relaxed">
                {t("pain_strip_3")}
              </p>
            </div>

          </div>

          {/* Summary Banner */}
          <div className="bg-blue-50/90 border border-blue-200/80 rounded-2xl p-4 text-center">
            <p className="text-sm sm:text-base font-bold text-blue-900">
              ✨ {t("pain_strip_summary")}
            </p>
          </div>

        </div>
      </section>

      {/* ========================================================================= */}
      {/* SECTION 3: EV SAHİBİ / KİRACI SEGMENT KARTLARI + ACENTE TEASER           */}
      {/* ========================================================================= */}
      <section className="py-16 md:py-20 px-4 sm:px-6 lg:px-8 max-w-5xl mx-auto w-full">
        <div className="text-center mb-8">
          <div className="text-[11px] font-bold text-slate-500 uppercase tracking-widest mb-2">
            {t("roles_label")}
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          
          {/* Landlord Card */}
          <div className="bg-white/90 backdrop-blur-md border border-slate-200/80 rounded-2xl p-7 shadow-sm hover:shadow-md transition space-y-5">
            <div className="flex items-center gap-3 pb-3 border-b border-slate-100">
              <div className="w-10 h-10 rounded-xl bg-blue-100 text-blue-600 flex items-center justify-center font-bold text-xl">
                🏠
              </div>
              <h3 className="text-xl font-bold text-slate-900">{t("roles_landlord")}</h3>
            </div>
            
            <div className="space-y-3">
              {[1, 2, 3, 4].map((i) => (
                <div key={i} className="flex items-start gap-3 text-sm text-slate-700">
                  <div className="w-5 h-5 rounded-full bg-blue-50 text-blue-600 flex items-center justify-center flex-shrink-0 mt-0.5">
                    <Check className="w-3.5 h-3.5 stroke-[3]" />
                  </div>
                  <span className="font-medium">{t(`roles_landlord_${i}`)}</span>
                </div>
              ))}
            </div>
          </div>

          {/* Tenant Card */}
          <div className="bg-white/90 backdrop-blur-md border border-slate-200/80 rounded-2xl p-7 shadow-sm hover:shadow-md transition space-y-5">
            <div className="flex items-center gap-3 pb-3 border-b border-slate-100">
              <div className="w-10 h-10 rounded-xl bg-emerald-100 text-emerald-600 flex items-center justify-center font-bold text-xl">
                🔑
              </div>
              <h3 className="text-xl font-bold text-slate-900">{t("roles_tenant")}</h3>
            </div>

            <div className="space-y-3">
              {[1, 2, 3, 4].map((i) => (
                <div key={i} className="flex items-start gap-3 text-sm text-slate-700">
                  <div className="w-5 h-5 rounded-full bg-emerald-50 text-emerald-600 flex items-center justify-center flex-shrink-0 mt-0.5">
                    <Check className="w-3.5 h-3.5 stroke-[3]" />
                  </div>
                  <span className="font-medium">{t(`roles_tenant_${i}`)}</span>
                </div>
              ))}
            </div>
          </div>

        </div>

        {/* Light Agency Teaser Bar (Link to /agencies) */}
        <div className="mt-8 bg-gradient-to-r from-blue-50/90 via-indigo-50/50 to-white backdrop-blur-md border border-blue-200/80 rounded-2xl p-5 text-center text-sm text-slate-800 shadow-sm flex flex-col sm:flex-row items-center justify-between gap-3">
          <span className="font-medium text-slate-700">
            {t("agency_teaser_text")}
          </span>
          <Link
            href="/agencies"
            className="inline-flex items-center justify-center px-4 py-2 text-xs font-bold text-white bg-blue-600 hover:bg-blue-700 rounded-xl transition shadow-sm whitespace-nowrap flex-shrink-0"
          >
            {t("agency_teaser_link")}
          </Link>
        </div>

      </section>

      {/* ========================================================================= */}
      {/* SECTION 4: NASIL ÇALIŞIR — BİREYSEL İNTERAKTİF AKIŞ                         */}
      {/* ========================================================================= */}
      <section className="py-8">
        <InteractiveFlow />
      </section>

      {/* ========================================================================= */}
      {/* SECTION 5: NELER YAPABİLİRSİNİZ (3-Column Feature Cards Grid)              */}
      {/* ========================================================================= */}
      <section className="py-16 md:py-24 bg-white border-y border-slate-200/80 px-4 sm:px-6 lg:px-8">
        <div className="max-w-7xl mx-auto space-y-16">
          
          <div className="text-center max-w-3xl mx-auto space-y-3">
            <div className="text-[11px] font-bold text-blue-600 uppercase tracking-widest">
              {t("features_label")}
            </div>
            <h2 className="text-2xl sm:text-3xl font-extrabold text-slate-900 tracking-tight">
              Mülk Yönetiminde İhtiyacınız Olan Her Şey
            </h2>
            <div className="w-16 h-1 bg-blue-600 mx-auto rounded-full" />
          </div>

          {/* 3-Column Feature Grid (Matching Agencies Style) */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            
            {/* Feature 1 */}
            <div className="bg-slate-50/80 p-8 rounded-2xl border border-slate-200/80 hover:shadow-xl hover:bg-white transition-all duration-300 group">
              <div className="w-14 h-14 rounded-2xl bg-blue-100 text-blue-600 flex items-center justify-center mb-6 group-hover:scale-110 transition-transform">
                <ClipboardList className="w-7 h-7" />
              </div>
              <h3 className="text-xl font-bold text-slate-900 mb-3">
                {t("feature_1_title")}
              </h3>
              <p className="text-slate-600 text-sm leading-relaxed">
                {t("feature_1_desc")}
              </p>
            </div>

            {/* Feature 2 */}
            <div className="bg-slate-50/80 p-8 rounded-2xl border border-slate-200/80 hover:shadow-xl hover:bg-white transition-all duration-300 group">
              <div className="w-14 h-14 rounded-2xl bg-indigo-100 text-indigo-600 flex items-center justify-center mb-6 group-hover:scale-110 transition-transform">
                <FileText className="w-7 h-7" />
              </div>
              <h3 className="text-xl font-bold text-slate-900 mb-3">
                {t("feature_2_title")}
              </h3>
              <p className="text-slate-600 text-sm leading-relaxed">
                {t("feature_2_desc")}
              </p>
            </div>

            {/* Feature 3 */}
            <div className="bg-slate-50/80 p-8 rounded-2xl border border-slate-200/80 hover:shadow-xl hover:bg-white transition-all duration-300 group">
              <div className="w-14 h-14 rounded-2xl bg-emerald-100 text-emerald-600 flex items-center justify-center mb-6 group-hover:scale-110 transition-transform">
                <Bell className="w-7 h-7" />
              </div>
              <h3 className="text-xl font-bold text-slate-900 mb-3">
                {t("feature_3_title")}
              </h3>
              <p className="text-slate-600 text-sm leading-relaxed">
                {t("feature_3_desc")}
              </p>
            </div>

            {/* Feature 4 */}
            <div className="bg-slate-50/80 p-8 rounded-2xl border border-slate-200/80 hover:shadow-xl hover:bg-white transition-all duration-300 group">
              <div className="w-14 h-14 rounded-2xl bg-amber-100 text-amber-600 flex items-center justify-center mb-6 group-hover:scale-110 transition-transform">
                <Wrench className="w-7 h-7" />
              </div>
              <h3 className="text-xl font-bold text-slate-900 mb-3">
                {t("feature_4_title")}
              </h3>
              <p className="text-slate-600 text-sm leading-relaxed">
                {t("feature_4_desc")}
              </p>
            </div>

            {/* Feature 5 */}
            <div className="bg-slate-50/80 p-8 rounded-2xl border border-slate-200/80 hover:shadow-xl hover:bg-white transition-all duration-300 group">
              <div className="w-14 h-14 rounded-2xl bg-purple-100 text-purple-600 flex items-center justify-center mb-6 group-hover:scale-110 transition-transform">
                <Globe className="w-7 h-7" />
              </div>
              <h3 className="text-xl font-bold text-slate-900 mb-3">
                {t("feature_5_title")}
              </h3>
              <p className="text-slate-600 text-sm leading-relaxed">
                {t("feature_5_desc")}
              </p>
            </div>

            {/* Feature 6 */}
            <div className="bg-slate-50/80 p-8 rounded-2xl border border-slate-200/80 hover:shadow-xl hover:bg-white transition-all duration-300 group">
              <div className="w-14 h-14 rounded-2xl bg-teal-100 text-teal-600 flex items-center justify-center mb-6 group-hover:scale-110 transition-transform">
                <Shield className="w-7 h-7" />
              </div>
              <h3 className="text-xl font-bold text-slate-900 mb-3">
                {t("feature_6_title")}
              </h3>
              <p className="text-slate-600 text-sm leading-relaxed">
                {t("feature_6_desc")}
              </p>
            </div>

          </div>
        </div>
      </section>

      {/* ========================================================================= */}
      {/* SECTION 6: GÜVENLİK VE KOLAYLIK (3-Column Trust Cards Grid)              */}
      {/* ========================================================================= */}
      <section className="py-16 md:py-24 bg-slate-50 px-4 sm:px-6 lg:px-8">
        <div className="max-w-7xl mx-auto space-y-12">
          
          <div className="text-center max-w-3xl mx-auto space-y-3">
            <div className="text-[11px] font-bold text-slate-500 uppercase tracking-widest">
              {t("trust_label")}
            </div>
            <h2 className="text-2xl sm:text-3xl font-extrabold text-slate-900 tracking-tight">
              Verileriniz Güvende, İçiniz Rahat
            </h2>
            <div className="w-16 h-1 bg-blue-600 mx-auto rounded-full" />
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            
            <div className="bg-white p-8 rounded-2xl border border-slate-200 shadow-sm hover:shadow-md transition text-center space-y-4">
              <div className="w-14 h-14 rounded-2xl bg-blue-100 text-blue-600 flex items-center justify-center mx-auto">
                <Shield className="w-7 h-7" />
              </div>
              <h3 className="text-xl font-bold text-slate-900">{t("trust_1_title")}</h3>
              <p className="text-slate-600 text-sm leading-relaxed">{t("trust_1_desc")}</p>
            </div>

            <div className="bg-white p-8 rounded-2xl border border-slate-200 shadow-sm hover:shadow-md transition text-center space-y-4">
              <div className="w-14 h-14 rounded-2xl bg-indigo-100 text-indigo-600 flex items-center justify-center mx-auto">
                <Cloud className="w-7 h-7" />
              </div>
              <h3 className="text-xl font-bold text-slate-900">{t("trust_2_title")}</h3>
              <p className="text-slate-600 text-sm leading-relaxed">{t("trust_2_desc")}</p>
            </div>

            <div className="bg-white p-8 rounded-2xl border border-slate-200 shadow-sm hover:shadow-md transition text-center space-y-4">
              <div className="w-14 h-14 rounded-2xl bg-emerald-100 text-emerald-600 flex items-center justify-center mx-auto">
                <Heart className="w-7 h-7" />
              </div>
              <h3 className="text-xl font-bold text-slate-900">{t("trust_3_title")}</h3>
              <p className="text-slate-600 text-sm leading-relaxed">{t("trust_3_desc")}</p>
            </div>

          </div>
        </div>
      </section>

      {/* ========================================================================= */}
      {/* SECTION 7: FİYATLANDIRMA / PRICING (2-Column Table)                        */}
      {/* ========================================================================= */}
      <section className="py-16 md:py-24 bg-white border-t border-slate-200/80 px-4 sm:px-6 lg:px-8">
        <div className="max-w-5xl mx-auto space-y-12">
          
          <div className="text-center max-w-3xl mx-auto space-y-3">
            <div className="text-[11px] font-bold text-blue-600 uppercase tracking-widest">
              {t("pricing_label")}
            </div>
            <h2 className="text-2xl sm:text-3xl font-extrabold text-slate-900 tracking-tight">
              {t("pricing_title")}
            </h2>
            <div className="w-16 h-1 bg-blue-600 mx-auto rounded-full" />
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-8 items-stretch">
            
            {/* Free Plan Card */}
            <div className="bg-slate-50/90 border border-slate-200 rounded-3xl p-8 flex flex-col justify-between shadow-sm hover:shadow-md transition space-y-6 relative overflow-hidden">
              <div className="space-y-5">
                <div className="flex items-center justify-between">
                  <span className="text-xs font-bold bg-emerald-100 text-emerald-800 px-3 py-1 rounded-full uppercase tracking-wider">
                    {t("pricing_free_badge")}
                  </span>
                </div>

                <div>
                  <h3 className="text-2xl font-bold text-slate-900">{t("pricing_free_title")}</h3>
                  <p className="text-sm text-slate-600 mt-1">{t("pricing_free_desc")}</p>
                </div>

                <div className="flex items-baseline gap-1">
                  <span className="text-4xl font-extrabold text-slate-900">{t("pricing_free_price")}</span>
                  <span className="text-slate-500 text-sm font-medium">{t("pricing_free_period")}</span>
                </div>

                <div className="pt-4 border-t border-slate-200/80 space-y-3">
                  {[1, 2, 3, 4].map((i) => (
                    <div key={i} className="flex items-center gap-3 text-sm text-slate-700">
                      <div className="w-5 h-5 rounded-full bg-emerald-100 text-emerald-600 flex items-center justify-center flex-shrink-0">
                        <Check className="w-3.5 h-3.5 stroke-[3]" />
                      </div>
                      <span>{t(`pricing_free_feat_${i}`)}</span>
                    </div>
                  ))}
                </div>
              </div>

              <div className="pt-6">
                <a
                  href="/app"
                  className="w-full inline-flex justify-center items-center gap-2 px-6 py-3.5 rounded-xl text-white bg-blue-600 hover:bg-blue-700 font-bold text-sm shadow-md transition"
                >
                  <span>{t("pricing_free_btn")}</span>
                  <ArrowRight className="w-4 h-4" />
                </a>
              </div>
            </div>

            {/* Pro / Agency Plan Card */}
            <div className="bg-gradient-to-br from-slate-900 via-blue-950 to-slate-900 border border-slate-800 rounded-3xl p-8 flex flex-col justify-between text-white shadow-xl space-y-6 relative overflow-hidden">
              {/* Background Glow */}
              <div className="absolute -top-16 -right-16 w-48 h-48 bg-blue-500/20 rounded-full blur-2xl pointer-events-none" />

              <div className="space-y-5 relative z-10">
                <div className="flex items-center justify-between">
                  <span className="text-xs font-bold bg-blue-500/20 text-blue-300 border border-blue-400/30 px-3 py-1 rounded-full uppercase tracking-wider">
                    {t("pricing_pro_badge")}
                  </span>
                </div>

                <div>
                  <h3 className="text-2xl font-bold text-white">{t("pricing_pro_title")}</h3>
                  <p className="text-sm text-slate-300 mt-1">{t("pricing_pro_desc")}</p>
                </div>

                <div className="flex items-baseline gap-1">
                  <span className="text-3xl font-extrabold text-white">{t("pricing_pro_price")}</span>
                  <span className="text-slate-400 text-sm font-medium">{t("pricing_pro_period")}</span>
                </div>

                <div className="pt-4 border-t border-slate-800 space-y-3">
                  {[1, 2, 3, 4].map((i) => (
                    <div key={i} className="flex items-center gap-3 text-sm text-slate-200">
                      <div className="w-5 h-5 rounded-full bg-blue-500/20 text-blue-400 flex items-center justify-center flex-shrink-0">
                        <Check className="w-3.5 h-3.5 stroke-[3]" />
                      </div>
                      <span>{t(`pricing_pro_feat_${i}`)}</span>
                    </div>
                  ))}
                </div>
              </div>

              <div className="pt-6 relative z-10">
                <Link
                  href="/agencies"
                  className="w-full inline-flex justify-center items-center gap-2 px-6 py-3.5 rounded-xl text-slate-900 bg-white hover:bg-slate-100 font-bold text-sm shadow-md transition"
                >
                  <span>{t("pricing_pro_btn")}</span>
                </Link>
              </div>
            </div>

          </div>

        </div>
      </section>

      {/* ========================================================================= */}
      {/* SECTION 8: KAPANIŞ CTA BANDI (Agencies Dark Navy Banner Style)           */}
      {/* ========================================================================= */}
      <section className="py-16 md:py-20 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto w-full mb-12">
        <div className="bg-gradient-to-r from-slate-900 via-blue-950 to-slate-900 rounded-3xl p-8 sm:p-14 text-center text-white border border-slate-800 shadow-2xl relative overflow-hidden">
          
          {/* Background Glow Overlay */}
          <div className="absolute -top-24 -right-24 w-72 h-72 bg-blue-500/20 rounded-full blur-3xl pointer-events-none" />
          <div className="absolute -bottom-24 -left-24 w-72 h-72 bg-emerald-500/10 rounded-full blur-3xl pointer-events-none" />

          <div className="relative z-10 max-w-3xl mx-auto space-y-6">
            <h2 className="text-2xl sm:text-3xl lg:text-4xl font-extrabold tracking-tight leading-tight">
              {t("footer_cta_title")}
            </h2>

            <p
              className="text-slate-300 text-sm sm:text-base leading-relaxed max-w-xl mx-auto"
              dangerouslySetInnerHTML={{ __html: t("footer_cta_desc") }}
            />

            {/* CTAs */}
            <div className="pt-4 flex flex-col sm:flex-row items-center justify-center gap-4">
              {deviceOS === null || deviceOS === "desktop" ? (
                <>
                  <a
                    href="https://apps.apple.com/us/app/stanomer/id6762311157"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-flex transition-opacity hover:opacity-85"
                  >
                    <img
                      src="https://upload.wikimedia.org/wikipedia/commons/9/91/Download_on_the_App_Store_RGB_blk.svg"
                      alt="Download on the App Store"
                      className="h-11 w-[145px] block invert"
                    />
                  </a>
                  <a
                    href="https://play.google.com/store/apps/details?id=com.aboptima.stanomer"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-flex transition-opacity hover:opacity-85"
                  >
                    <img
                      src="https://upload.wikimedia.org/wikipedia/commons/7/78/Google_Play_Store_badge_EN.svg"
                      alt="Get it on Google Play"
                      className="h-11 w-[145px] block"
                    />
                  </a>
                  <a
                    href="/app"
                    className="h-11 inline-flex items-center justify-center gap-2 bg-blue-600 hover:bg-blue-500 text-white font-bold text-sm px-6 rounded-xl shadow-lg transition"
                  >
                    <span>{t("btn_web_app")}</span>
                    <ArrowRight className="w-4 h-4" />
                  </a>
                </>
              ) : deviceOS === "ios" ? (
                <a
                  href="https://apps.apple.com/us/app/stanomer/id6762311157"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex transition-opacity hover:opacity-85"
                >
                  <img
                    src="https://upload.wikimedia.org/wikipedia/commons/9/91/Download_on_the_App_Store_RGB_blk.svg"
                    alt="Download on the App Store"
                    className="h-11 w-[145px] block invert"
                  />
                </a>
              ) : (
                <a
                  href="https://play.google.com/store/apps/details?id=com.aboptima.stanomer"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex transition-opacity hover:opacity-85"
                >
                  <img
                    src="https://upload.wikimedia.org/wikipedia/commons/7/78/Google_Play_Store_badge_EN.svg"
                    alt="Get it on Google Play"
                    className="h-11 w-[145px] block"
                  />
                </a>
              )}
            </div>

          </div>
        </div>
      </section>

      {/* ========================================================================= */}
      {/* FOOTER                                                                    */}
      {/* ========================================================================= */}
      <footer className="py-12 border-t border-slate-200/80 bg-white w-full">
        <div className="max-w-7xl mx-auto px-6 text-center">
          <div className="flex items-center justify-center gap-2 opacity-60 mb-6">
            <img src="/assets/logo.png" alt="Stanomer Logo" className="w-6 h-6 object-contain" />
            <span className="font-bold text-sm tracking-tight text-slate-900">Stanomer</span>
          </div>
          
          <div className="flex flex-wrap justify-center gap-x-6 gap-y-2 mb-6 text-xs font-medium text-slate-600">
            <a href="/guide" className="hover:text-blue-600 transition-colors font-bold text-blue-600">{t("footer_guide")}</a>
            <a href="/privacy" className="hover:text-blue-600 transition-colors">{t("footer_privacy")}</a>
            <a href="/terms" className="hover:text-blue-600 transition-colors">{t("footer_terms")}</a>
            <a href="/changelog" className="hover:text-blue-600 transition-colors">{t("footer_changelog")}</a>
            <a href="/support" className="hover:text-blue-600 transition-colors">{t("footer_support")}</a>
          </div>

          <p className="text-slate-400 text-xs">
            © 2026 Stanomer. {t("footer_rights")}
          </p>
        </div>
      </footer>

    </div>
  );
}
