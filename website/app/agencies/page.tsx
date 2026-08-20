"use client";

import React from "react";
import Link from "next/link";
import { Navbar } from "../../components/Navbar";
import { useLanguage } from "../../components/LanguageProvider";
import {
  Palette,
  ShieldCheck,
  UserCheck,
  CheckCircle2,
  ArrowRight,
  Sparkles,
  Building2,
  QrCode,
  Clock,
  Eye,
  BarChart3,
  ChevronDown,
} from "lucide-react";

export default function AgenciesPage() {
  const { t } = useLanguage();

  const comparisonRows = [
    {
      label: t("agencies_cmp_row1_label"),
      v1: t("agencies_cmp_row1_v1"),
      v2: t("agencies_cmp_row1_v2"),
    },
    {
      label: t("agencies_cmp_row2_label"),
      v1: t("agencies_cmp_row2_v1"),
      v2: t("agencies_cmp_row2_v2"),
    },
    {
      label: t("agencies_cmp_row3_label"),
      v1: t("agencies_cmp_row3_v1"),
      v2: t("agencies_cmp_row3_v2"),
    },
    {
      label: t("agencies_cmp_row4_label"),
      v1: t("agencies_cmp_row4_v1"),
      v2: t("agencies_cmp_row4_v2"),
    },
  ];

  const referralReasons = [
    { icon: Clock, text: t("agencies_ref_why_1"), color: "bg-violet-100 text-violet-600" },
    { icon: Eye, text: t("agencies_ref_why_2"), color: "bg-emerald-100 text-emerald-600" },
    { icon: BarChart3, text: t("agencies_ref_why_3"), color: "bg-amber-100 text-amber-600" },
    { icon: BarChart3, text: t("agencies_ref_why_4"), color: "bg-blue-100 text-blue-600" },
  ];

  return (
    <div className="min-h-screen bg-slate-50 flex flex-col font-sans text-slate-900 overflow-x-hidden">
      <Navbar />

      {/* Spacer for fixed Navbar */}
      <div className="h-[80px]" />

      {/* ═══════════════════════════════════════════
          HERO — CHOICE SECTION
      ═══════════════════════════════════════════ */}
      <section className="relative pt-16 pb-20 md:pt-24 md:pb-28 px-4 sm:px-6 lg:px-8 max-w-5xl mx-auto w-full text-center">
        <div className="absolute top-0 left-1/4 w-96 h-96 bg-blue-400/10 rounded-full blur-3xl -z-10 pointer-events-none" />
        <div className="absolute bottom-0 right-1/4 w-96 h-96 bg-violet-400/10 rounded-full blur-3xl -z-10 pointer-events-none" />

        <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-blue-50 border border-blue-200/80 text-blue-700 text-xs sm:text-sm font-semibold tracking-wide shadow-sm mb-6">
          <Sparkles className="w-4 h-4 text-blue-600 animate-pulse" />
          <span>{t("agencies_hero_badge")}</span>
        </div>

        <h1 className="text-3xl sm:text-4xl lg:text-5xl font-extrabold text-slate-900 tracking-tight leading-[1.15] mb-5">
          {t("agencies_hero_select_title")}
        </h1>

        <p className="text-base sm:text-lg text-slate-600 leading-relaxed max-w-2xl mx-auto mb-10">
          {t("agencies_hero_select_subtitle")}
        </p>

        {/* Two choice cards */}
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-5 max-w-2xl mx-auto">
          <a
            href="#section-whitelabel"
            className="group flex flex-col items-center gap-4 p-7 rounded-2xl bg-white border-2 border-blue-200 hover:border-blue-500 hover:shadow-xl hover:shadow-blue-500/10 transition-all duration-300 cursor-pointer text-left"
          >
            <div className="w-14 h-14 rounded-2xl bg-blue-100 text-blue-600 flex items-center justify-center group-hover:scale-110 transition-transform">
              <Building2 className="w-7 h-7" />
            </div>
            <div>
              <p className="font-extrabold text-slate-900 text-base sm:text-lg leading-tight mb-1">
                {t("agencies_hero_option1_label")}
              </p>
              <p className="text-xs text-slate-500 leading-relaxed">White-Label Partner Panel</p>
            </div>
            <div className="mt-auto flex items-center gap-1.5 text-blue-600 text-sm font-semibold">
              <span>{t("agencies_hero_option1_label")}</span>
              <ChevronDown className="w-4 h-4" />
            </div>
          </a>

          <a
            href="#section-referral"
            className="group flex flex-col items-center gap-4 p-7 rounded-2xl bg-white border-2 border-violet-200 hover:border-violet-500 hover:shadow-xl hover:shadow-violet-500/10 transition-all duration-300 cursor-pointer text-left"
          >
            <div className="w-14 h-14 rounded-2xl bg-violet-100 text-violet-600 flex items-center justify-center group-hover:scale-110 transition-transform">
              <QrCode className="w-7 h-7" />
            </div>
            <div>
              <p className="font-extrabold text-slate-900 text-base sm:text-lg leading-tight mb-1">
                {t("agencies_hero_option2_label")}
              </p>
              <p className="text-xs text-slate-500 leading-relaxed">Referral Partner</p>
            </div>
            <div className="mt-auto flex items-center gap-1.5 text-violet-600 text-sm font-semibold">
              <span>{t("agencies_hero_option2_label")}</span>
              <ChevronDown className="w-4 h-4" />
            </div>
          </a>
        </div>
      </section>

      {/* ═══════════════════════════════════════════
          SECTION 1 — WHITE-LABEL (OPTION 1)
      ═══════════════════════════════════════════ */}
      <section
        id="section-whitelabel"
        className="relative pt-12 pb-20 md:pt-20 md:pb-32 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto w-full scroll-mt-24"
      >
        <div className="mb-8 flex justify-center lg:justify-start">
          <span className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full bg-blue-600 text-white text-sm font-bold tracking-wide shadow-md">
            <Building2 className="w-4 h-4" />
            {t("agencies_wl_section_title")}
          </span>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 lg:gap-8 items-center">

          {/* Left Side: Copy & CTAs */}
          <div className="lg:col-span-7 space-y-6 text-left">
            <h2 className="text-3xl sm:text-4xl lg:text-5xl font-extrabold text-slate-900 tracking-tight leading-[1.15]">
              {t("agencies_hero_title")}
            </h2>
            <p className="text-base sm:text-lg text-slate-600 leading-relaxed max-w-2xl">
              {t("agencies_hero_subtitle")}
            </p>
            <div className="pt-4 flex flex-col sm:flex-row gap-4 sm:items-center">
              <Link
                href="/agency-demo"
                className="inline-flex justify-center items-center gap-2.5 px-7 py-4 rounded-xl text-white bg-blue-600 hover:bg-blue-700 font-bold text-base shadow-xl shadow-blue-500/25 transition-all transform hover:-translate-y-0.5 active:translate-y-0"
              >
                <span>{t("agencies_cta_demo")}</span>
                <ArrowRight className="w-5 h-5" />
              </Link>
            </div>
          </div>

          {/* Right Side: White-Label Product Mockup */}
          <div className="lg:col-span-5 relative flex justify-center items-center">
            <div className="absolute inset-0 bg-blue-400/20 rounded-full blur-3xl transform scale-90 -z-10" />
            <div className="w-full max-w-md bg-white/90 backdrop-blur-md rounded-2xl p-5 border border-slate-200/80 shadow-2xl space-y-4 transform -rotate-1 hover:rotate-0 transition duration-500">

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

              <div className="absolute -bottom-3 -left-3 bg-white text-slate-800 px-3.5 py-2 rounded-xl shadow-lg border border-slate-200 text-xs font-bold flex items-center gap-2">
                <span className="w-2.5 h-2.5 rounded-full bg-blue-600" />
                <span>{t("agencies_mockup_white_label_badge")}</span>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ═══════════════════════════════════════════
          SECTION 2 — VALUE PROPOSITION
      ═══════════════════════════════════════════ */}
      <section className="py-16 md:py-24 bg-white border-y border-slate-200/80 px-4 sm:px-6 lg:px-8">
        <div className="max-w-7xl mx-auto space-y-16">
          <div className="text-center max-w-3xl mx-auto space-y-3">
            <h2 className="text-2xl sm:text-3xl font-extrabold text-slate-900 tracking-tight">
              {t("agencies_val_title")}
            </h2>
            <div className="w-16 h-1 bg-blue-600 mx-auto rounded-full" />
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            <div className="bg-slate-50/80 p-8 rounded-2xl border border-slate-200/80 hover:shadow-xl hover:bg-white transition-all duration-300 group">
              <div className="w-14 h-14 rounded-2xl bg-blue-100 text-blue-600 flex items-center justify-center mb-6 group-hover:scale-110 transition-transform">
                <Palette className="w-7 h-7" />
              </div>
              <h3 className="text-xl font-bold text-slate-900 mb-3">{t("agencies_val_1_title")}</h3>
              <p className="text-slate-600 text-sm leading-relaxed">{t("agencies_val_1_desc")}</p>
            </div>

            <div className="bg-slate-50/80 p-8 rounded-2xl border border-slate-200/80 hover:shadow-xl hover:bg-white transition-all duration-300 group">
              <div className="w-14 h-14 rounded-2xl bg-amber-100 text-amber-600 flex items-center justify-center mb-6 group-hover:scale-110 transition-transform">
                <ShieldCheck className="w-7 h-7" />
              </div>
              <h3 className="text-xl font-bold text-slate-900 mb-3">{t("agencies_val_2_title")}</h3>
              <p className="text-slate-600 text-sm leading-relaxed">{t("agencies_val_2_desc")}</p>
            </div>

            <div className="bg-slate-50/80 p-8 rounded-2xl border border-slate-200/80 hover:shadow-xl hover:bg-white transition-all duration-300 group">
              <div className="w-14 h-14 rounded-2xl bg-emerald-100 text-emerald-600 flex items-center justify-center mb-6 group-hover:scale-110 transition-transform">
                <UserCheck className="w-7 h-7" />
              </div>
              <h3 className="text-xl font-bold text-slate-900 mb-3">{t("agencies_val_3_title")}</h3>
              <p className="text-slate-600 text-sm leading-relaxed">{t("agencies_val_3_desc")}</p>
            </div>
          </div>
        </div>
      </section>

      {/* ═══════════════════════════════════════════
          SECTION 3 — HOW IT WORKS (Checklist)
      ═══════════════════════════════════════════ */}
      <section className="py-16 md:py-24 bg-slate-50 px-4 sm:px-6 lg:px-8">
        <div className="max-w-5xl mx-auto space-y-12">
          <div className="text-center max-w-3xl mx-auto space-y-4">
            <h2 className="text-2xl sm:text-3xl font-extrabold text-slate-900 tracking-tight">
              {t("agencies_how_title")}
            </h2>
            <p className="text-slate-600 text-base leading-relaxed">{t("agencies_how_intro")}</p>
          </div>

          <div className="space-y-4">
            {[t("agencies_how_1"), t("agencies_how_2"), t("agencies_how_3")].map((item, idx) => (
              <div key={idx} className="bg-white p-6 sm:p-7 rounded-2xl border border-slate-200 shadow-sm hover:shadow-md transition flex items-start gap-4">
                <div className="w-8 h-8 rounded-full bg-emerald-100 text-emerald-600 flex items-center justify-center flex-shrink-0 mt-0.5">
                  <CheckCircle2 className="w-5 h-5 text-emerald-600" />
                </div>
                <p className="text-base sm:text-lg font-bold text-slate-900">{item}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ═══════════════════════════════════════════
          SECTION 4 — REFERRAL (OPTION 2)
      ═══════════════════════════════════════════ */}
      <section
        id="section-referral"
        className="relative py-20 md:py-32 px-4 sm:px-6 lg:px-8 bg-white border-t border-slate-200/80 scroll-mt-24"
      >
        <div className="absolute top-0 right-0 w-96 h-96 bg-violet-400/10 rounded-full blur-3xl pointer-events-none" />
        <div className="absolute bottom-0 left-0 w-64 h-64 bg-fuchsia-400/10 rounded-full blur-3xl pointer-events-none" />

        <div className="max-w-7xl mx-auto relative z-10">
          <div className="mb-8 flex justify-center lg:justify-start">
            <span className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full bg-violet-600 text-white text-sm font-bold tracking-wide shadow-md">
              <QrCode className="w-4 h-4" />
              {t("agencies_ref_section_title")}
            </span>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 lg:gap-10 items-start">

            {/* Left: QR Mockup Card */}
            <div className="lg:col-span-5 relative flex justify-center items-center">
              <div className="absolute inset-0 bg-violet-400/20 rounded-full blur-3xl transform scale-90 -z-10" />
              <div className="w-full max-w-md bg-white/90 backdrop-blur-md rounded-2xl p-5 border border-slate-200/80 shadow-2xl space-y-4 transform rotate-1 hover:rotate-0 transition duration-500">

                <div className="flex items-center justify-between pb-3 border-b border-slate-100">
                  <div className="flex items-center gap-2.5">
                    <div className="w-8 h-8 rounded-lg bg-violet-500/20 flex items-center justify-center">
                      <Building2 className="w-4 h-4 text-violet-600" />
                    </div>
                    <div>
                      <p className="text-xs font-bold text-slate-900">{t("agencies_ref_qr_card_agency").toUpperCase()}</p>
                      <p className="text-[10px] text-slate-400">Referral Partner</p>
                    </div>
                  </div>
                  <span className="text-[10px] font-semibold bg-violet-50 text-violet-700 px-2 py-0.5 rounded-md border border-violet-200">
                    {t("agencies_ref_qr_card_badge")}
                  </span>
                </div>

                {/* QR code visual */}
                <div className="flex flex-col items-center gap-3 py-2">
                  <div className="relative w-36 h-36 bg-slate-900 rounded-xl p-3 shadow-inner flex items-center justify-center">
                    <div className="grid grid-cols-7 gap-0.5 w-full h-full">
                      {Array.from({ length: 49 }).map((_, i) => {
                        const row = Math.floor(i / 7);
                        const col = i % 7;
                        const isCorner =
                          (row < 2 && col < 2) ||
                          (row < 2 && col > 4) ||
                          (row > 4 && col < 2);
                        const isRandom = Math.abs(Math.sin(i * 7.3 + 1.1)) > 0.52;
                        const filled = isCorner || isRandom;
                        return (
                          <div
                            key={i}
                            className={`rounded-sm ${filled ? "bg-white" : "bg-transparent"}`}
                          />
                        );
                      })}
                    </div>
                    <div className="absolute inset-0 flex items-center justify-center">
                      <div className="w-8 h-8 rounded-md bg-violet-600 flex items-center justify-center shadow-lg">
                        <QrCode className="w-4 h-4 text-white" />
                      </div>
                    </div>
                  </div>
                  <p className="text-xs font-bold text-slate-700">{t("agencies_ref_qr_card_scan_label")}</p>
                </div>

                <div className="grid grid-cols-2 gap-2.5">
                  <div className="bg-slate-50 p-3 rounded-xl border border-slate-100">
                    <p className="text-[10px] text-slate-500 font-medium">{t("agencies_ref_qr_card_users")}</p>
                    <p className="text-lg font-extrabold text-violet-700">{t("agencies_ref_qr_card_count")}</p>
                  </div>
                  <div className="bg-violet-50/60 p-3 rounded-xl border border-violet-100">
                    <p className="text-[10px] text-violet-600 font-medium">{t("agencies_ref_qr_card_title")}</p>
                    <p className="text-sm font-extrabold text-violet-800 leading-tight mt-0.5">✓ Active</p>
                  </div>
                </div>

                <div className="absolute -bottom-3 -right-3 bg-white text-slate-800 px-3.5 py-2 rounded-xl shadow-lg border border-slate-200 text-xs font-bold flex items-center gap-2">
                  <span className="w-2.5 h-2.5 rounded-full bg-violet-600" />
                  <span>{t("agencies_ref_qr_card_title")}</span>
                </div>
              </div>
            </div>

            {/* Right: Copy + Reasons + CTA */}
            <div className="lg:col-span-7 space-y-8">
              <div className="space-y-4">
                <h2 className="text-3xl sm:text-4xl font-extrabold text-slate-900 tracking-tight leading-tight">
                  {t("agencies_ref_section_title")}
                </h2>
                <p className="text-base sm:text-lg text-slate-600 leading-relaxed">
                  {t("agencies_ref_intro")}
                </p>
              </div>

              <div>
                <h3 className="text-lg font-bold text-slate-800 mb-4">{t("agencies_ref_why_title")}</h3>
                <div className="space-y-3">
                  {referralReasons.map((reason, idx) => (
                    <div
                      key={idx}
                      className="bg-slate-50 p-5 rounded-2xl border border-slate-200 hover:shadow-md hover:bg-white transition-all duration-300 flex items-start gap-4"
                    >
                      <div className={`w-8 h-8 rounded-full flex items-center justify-center flex-shrink-0 mt-0.5 ${reason.color}`}>
                        <CheckCircle2 className="w-5 h-5" />
                      </div>
                      <p className="text-sm sm:text-base font-semibold text-slate-800 leading-snug">
                        {reason.text}
                      </p>
                    </div>
                  ))}
                </div>
              </div>

              <div className="pt-2 space-y-3">
                <p className="text-slate-600 text-sm sm:text-base italic">{t("agencies_ref_cta_subtitle")}</p>
                <Link
                  href="/agency-referral"
                  className="inline-flex justify-center items-center gap-2.5 px-7 py-4 rounded-xl text-white bg-violet-600 hover:bg-violet-700 font-bold text-base shadow-xl shadow-violet-500/25 transition-all transform hover:-translate-y-0.5 active:translate-y-0"
                >
                  <span>{t("agencies_ref_cta_btn")}</span>
                  <ArrowRight className="w-5 h-5" />
                </Link>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ═══════════════════════════════════════════
          SECTION 5 — COMPARISON TABLE
      ═══════════════════════════════════════════ */}
      <section className="py-16 md:py-24 bg-slate-50 border-t border-slate-200/80 px-4 sm:px-6 lg:px-8">
        <div className="max-w-4xl mx-auto space-y-10">
          <div className="text-center space-y-3">
            <h2 className="text-2xl sm:text-3xl font-extrabold text-slate-900 tracking-tight">
              {t("agencies_cmp_title")}
            </h2>
            <div className="w-16 h-1 bg-violet-500 mx-auto rounded-full" />
          </div>

          <div className="overflow-x-auto rounded-2xl border border-slate-200 shadow-lg">
            <table className="w-full text-sm">
              <thead>
                <tr className="bg-slate-900 text-white">
                  <th className="px-5 py-4 text-left font-semibold text-slate-400 w-1/3 rounded-tl-2xl">&nbsp;</th>
                  <th className="px-5 py-4 text-center font-extrabold text-blue-300 w-1/3">
                    <div className="flex items-center justify-center gap-2">
                      <Building2 className="w-4 h-4" />
                      <span>{t("agencies_cmp_col1")}</span>
                    </div>
                  </th>
                  <th className="px-5 py-4 text-center font-extrabold text-violet-300 w-1/3 rounded-tr-2xl">
                    <div className="flex items-center justify-center gap-2">
                      <QrCode className="w-4 h-4" />
                      <span>{t("agencies_cmp_col2")}</span>
                    </div>
                  </th>
                </tr>
              </thead>
              <tbody>
                {comparisonRows.map((row, idx) => (
                  <tr
                    key={idx}
                    className={`border-t border-slate-200 ${idx % 2 === 0 ? "bg-white" : "bg-slate-50/60"}`}
                  >
                    <td className="px-5 py-4 font-bold text-slate-700">{row.label}</td>
                    <td className="px-5 py-4 text-center text-slate-600">
                      <div className="flex items-center justify-center gap-2">
                        <span className="w-2 h-2 rounded-full bg-blue-400 flex-shrink-0" />
                        {row.v1}
                      </div>
                    </td>
                    <td className="px-5 py-4 text-center text-slate-600">
                      <div className="flex items-center justify-center gap-2">
                        <span className="w-2 h-2 rounded-full bg-violet-400 flex-shrink-0" />
                        {row.v2}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </section>

      {/* ═══════════════════════════════════════════
          SECTION 6 — BOTTOM CTA BAND
      ═══════════════════════════════════════════ */}
      <section className="py-16 md:py-20 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto w-full mb-12">
        <div className="bg-gradient-to-r from-slate-900 via-blue-950 to-slate-900 rounded-3xl p-8 sm:p-14 text-center text-white border border-slate-800 shadow-2xl relative overflow-hidden">
          <div className="absolute -top-24 -right-24 w-72 h-72 bg-blue-500/20 rounded-full blur-3xl pointer-events-none" />
          <div className="absolute -bottom-24 -left-24 w-72 h-72 bg-amber-500/10 rounded-full blur-3xl pointer-events-none" />

          <div className="relative z-10 max-w-3xl mx-auto space-y-8">
            <h2 className="text-2xl sm:text-3xl lg:text-4xl font-extrabold tracking-tight leading-tight">
              {t("agencies_bottom_title")}
            </h2>

            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              <Link
                href="/agency-demo"
                className="inline-flex justify-center items-center gap-2 px-8 py-4 rounded-xl text-white bg-blue-600 hover:bg-blue-500 font-bold text-base shadow-xl shadow-blue-600/30 transition"
              >
                <Building2 className="w-5 h-5" />
                <span>{t("agencies_cta_demo")}</span>
                <ArrowRight className="w-5 h-5" />
              </Link>
              <Link
                href="/agency-referral"
                className="inline-flex justify-center items-center gap-2 px-8 py-4 rounded-xl text-white bg-violet-600 hover:bg-violet-500 font-bold text-base shadow-xl shadow-violet-600/30 transition"
              >
                <QrCode className="w-5 h-5" />
                <span>{t("agencies_ref_cta_btn")}</span>
                <ArrowRight className="w-5 h-5" />
              </Link>
            </div>
          </div>
        </div>
      </section>

      {/* FOOTER */}
      <footer className="py-12 border-t border-slate-200/80 bg-white w-full mt-auto">
        <div className="max-w-7xl mx-auto px-6 text-center">
          <div className="flex items-center justify-center gap-2 opacity-60 mb-6">
            <img src="/assets/logo.png" alt="Stanomer Logo" className="w-6 h-6 object-contain" />
            <span className="font-bold text-sm tracking-tight text-slate-900">Stanomer</span>
          </div>

          <div className="flex flex-wrap justify-center gap-x-6 gap-y-2 mb-6 text-xs font-medium text-slate-600">
            <a href="/agency-stats" className="hover:text-violet-600 transition-colors font-bold text-violet-600">Zaten Partnerimiz misiniz? Referanslarınızı Görüntüleyin →</a>
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

