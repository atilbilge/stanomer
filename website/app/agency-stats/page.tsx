"use client";

import React, { useState, useEffect, useRef } from "react";
import QRCode from "qrcode";
import { Navbar } from "../../components/Navbar";
import { useLanguage } from "../../components/LanguageProvider";
import {
  QrCode,
  Mail,
  KeyRound,
  ArrowRight,
  Sparkles,
  TrendingUp,
  Building2,
  CheckCircle2,
  ShieldCheck,
  LogOut,
  Download,
  Users,
  UserCheck,
  AlertCircle
} from "lucide-react";

import {
  ReferralPartner,
  requestAgencyOtp,
  verifyAgencyOtp,
  lookupReferralAgency
} from "../../lib/referralClientService";

interface PartnerInfo {
  id: string;
  agency_name: string;
  contact_name?: string;
  email: string;
  slug: string;
  referral_code: string;
  city?: string;
}

interface StatsData {
  totalReferred: number;
  landlordCount: number;
  tenantCount: number;
}

interface TrendItem {
  label: string;
  count: number;
}

export default function AgencyStatsPage() {
  const { t } = useLanguage();

  // Screen States: "email" | "otp" | "dashboard"
  const [screenState, setScreenState] = useState<"email" | "otp" | "dashboard">("email");

  // Form inputs
  const [email, setEmail] = useState("");
  const [otpCode, setOtpCode] = useState("");

  const [loading, setLoading] = useState(false);
  const [initialChecking, setInitialChecking] = useState(true);
  const [errorMessage, setErrorMessage] = useState("");
  const [infoMessage, setInfoMessage] = useState("");

  // Data states
  const [partner, setPartner] = useState<PartnerInfo | null>(null);
  const [stats, setStats] = useState<StatsData | null>(null);
  const [trend, setTrend] = useState<TrendItem[]>([]);

  // QR Code canvas reference
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const [qrDataUrl, setQrDataUrl] = useState<string>("");

  // 1. Check existing session on mount
  useEffect(() => {
    async function checkSession() {
      try {
        // Try localStorage first
        const localPartnerStr = localStorage.getItem("stanomer_agency_partner");
        if (localPartnerStr) {
          const localPartner = JSON.parse(localPartnerStr);
          if (localPartner?.email) {
            setPartner(localPartner);
            const lookup = await lookupReferralAgency(localPartner.email);
            if (lookup.stats) setStats(lookup.stats);
            setScreenState("dashboard");
            setInitialChecking(false);
            return;
          }
        }

        const res = await fetch("/api/agency-stats/dashboard");
        if (res.ok) {
          const contentType = res.headers.get("content-type") || "";
          if (contentType.includes("application/json")) {
            const data = await res.json();
            if (data.success && data.partner) {
              setPartner(data.partner);
              setStats(data.stats);
              setTrend(data.trend || []);
              setScreenState("dashboard");
            }
          }
        }
      } catch (e) {
        console.warn("Session check warning:", e);
      } finally {
        setInitialChecking(false);
      }
    }

    checkSession();
  }, []);

  // Generate QR Code preview on dashboard state
  useEffect(() => {
    if (partner?.slug && screenState === "dashboard") {
      const codeToken = partner.referral_code || partner.slug;
      const targetUrl = `stanomer://referral?token=${codeToken}`;

      if (canvasRef.current) {
        QRCode.toCanvas(
          canvasRef.current,
          targetUrl,
          {
            width: 400,
            margin: 2,
            color: {
              dark: "#0f172a",
              light: "#ffffff"
            }
          },
          (err) => {
            if (err) console.error("QR Code error:", err);
            else if (canvasRef.current) {
              setQrDataUrl(canvasRef.current.toDataURL("image/png"));
            }
          }
        );
      }
    }
  }, [partner, screenState]);

  // Handle OTP Request
  const handleRequestOtp = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMessage("");
    setInfoMessage("");

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email.trim())) {
      setErrorMessage(t("invalid_email") || "Geçerli bir e-posta adresi giriniz.");
      return;
    }

    setLoading(true);

    try {
      const data = await requestAgencyOtp(email.trim());

      if (data.isRateLimited) {
        setErrorMessage(data.message);
      } else if (data.success) {
        setInfoMessage(data.message);
        setScreenState("otp");
      } else {
        setErrorMessage(data.message || t("error_msg"));
      }
    } catch (err: any) {
      console.error("Request OTP Error:", err);
      setErrorMessage(t("error_msg") || "Bağlantı hatası oluştu.");
    } finally {
      setLoading(false);
    }
  };

  // Handle OTP Verify
  const handleVerifyOtp = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMessage("");

    if (!otpCode.trim() || otpCode.trim().length !== 6) {
      setErrorMessage(t("stats_otp_label") || "Lütfen 6 haneli doğrulama kodunu giriniz.");
      return;
    }

    setLoading(true);

    try {
      const data = await verifyAgencyOtp(email.trim(), otpCode.trim());

      if (data.success && data.partner) {
        setPartner(data.partner);
        // Load stats
        const lookup = await lookupReferralAgency(data.partner.email);
        if (lookup.stats) setStats(lookup.stats);
        setScreenState("dashboard");
      } else {
        setErrorMessage(data.message || "Hatalı doğrulama kodu.");
      }
    } catch (err: any) {
      console.error("Verify OTP Error:", err);
      setErrorMessage(t("error_msg") || "Bağlantı hatası oluştu.");
    } finally {
      setLoading(false);
    }
  };

  // Handle Logout
  const handleLogout = async () => {
    setLoading(true);
    try {
      localStorage.removeItem("stanomer_agency_partner");
      await fetch("/api/agency-stats/logout", { method: "POST" });
    } catch (e) {
      console.error("Logout error:", e);
    } finally {
      setLoading(false);
      setPartner(null);
      setStats(null);
      setTrend([]);
      setEmail("");
      setOtpCode("");
      setScreenState("email");
    }
  };

  if (initialChecking) {
    return (
      <div className="min-h-screen bg-slate-50 flex items-center justify-center text-slate-900 font-sans">
        <div className="flex items-center gap-3">
          <div className="w-6 h-6 border-2 border-violet-600 border-t-transparent rounded-full animate-spin" />
          <span className="text-sm font-semibold text-slate-600">Yükleniyor...</span>
        </div>
      </div>
    );
  }

  // Find max count for relative trend graph scaling
  const maxTrendCount = Math.max(...trend.map((t) => t.count), 1);

  return (
    <div className="min-h-screen bg-slate-50 flex flex-col font-sans text-slate-900 overflow-x-hidden">
      <Navbar />

      {/* Spacer for fixed Navbar */}
      <div className="h-[80px]" />

      <main className="flex-1 py-12 md:py-20 px-4 sm:px-6 lg:px-8 max-w-4xl mx-auto w-full flex flex-col justify-center">

        {/* Top Decorative Background Glow */}
        <div className="absolute top-20 left-1/2 -translate-x-1/2 w-full max-w-4xl h-96 bg-violet-400/10 rounded-full blur-3xl -z-10 pointer-events-none" />

        {/* ═══════════════════════════════════════════
            STATE 1: EMAIL ENTRY
        ═══════════════════════════════════════════ */}
        {screenState === "email" && (
          <div className="max-w-md mx-auto w-full space-y-8 animate-fadeIn">
            
            <div className="text-center space-y-3">
              <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-violet-50 border border-violet-200/80 text-violet-700 text-xs sm:text-sm font-semibold tracking-wide shadow-sm">
                <Building2 className="w-4 h-4 text-violet-600" />
                <span>{t("stats_portal_badge")}</span>
              </div>

              <h1 className="text-3xl sm:text-4xl font-extrabold text-slate-900 tracking-tight leading-tight">
                {t("stats_email_title")}
              </h1>

              <p className="text-sm text-slate-600 leading-relaxed max-w-sm mx-auto">
                {t("stats_email_subtitle")}
              </p>
            </div>

            <div className="bg-white rounded-3xl p-6 sm:p-8 border border-slate-200/80 shadow-xl space-y-6">
              
              {errorMessage && (
                <div className="bg-rose-50 border border-rose-200 text-rose-700 p-4 rounded-2xl text-xs sm:text-sm font-semibold flex items-center gap-3">
                  <AlertCircle className="w-4 h-4 text-rose-600 flex-shrink-0" />
                  <span>{errorMessage}</span>
                </div>
              )}

              <form onSubmit={handleRequestOtp} className="space-y-6">
                <div className="space-y-2">
                  <label className="block text-xs font-bold text-slate-700 tracking-wider">
                    {t("stats_field_email")} <span className="text-violet-600">*</span>
                  </label>
                  <div className="relative">
                    <Mail className="w-5 h-5 text-slate-400 absolute left-4 top-1/2 -translate-y-1/2" />
                    <input
                      type="email"
                      required
                      value={email}
                      onChange={(e) => setEmail(e.target.value)}
                      placeholder={t("stats_placeholder_email")}
                      className="w-full pl-12 pr-4 py-4 bg-slate-50 border border-slate-200 rounded-2xl text-sm text-slate-900 placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-violet-500 focus:bg-white transition"
                    />
                  </div>
                </div>

                <button
                  type="submit"
                  disabled={loading}
                  className="w-full flex items-center justify-center gap-3 py-4 px-8 rounded-2xl bg-violet-600 hover:bg-violet-700 text-white font-bold text-base shadow-xl shadow-violet-500/25 transition-all transform hover:-translate-y-0.5 active:translate-y-0 disabled:opacity-50 cursor-pointer"
                >
                  {loading ? (
                    <>
                      <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin" />
                      <span>{t("stats_sending_code")}</span>
                    </>
                  ) : (
                    <>
                      <span>{t("stats_btn_send_code")}</span>
                      <ArrowRight className="w-5 h-5" />
                    </>
                  )}
                </button>
              </form>

              <div className="pt-2 text-center text-xs text-slate-500 border-t border-slate-100">
                {t("stats_otp_note")}
              </div>

            </div>

          </div>
        )}

        {/* ═══════════════════════════════════════════
            STATE 2: OTP CODE ENTRY
        ═══════════════════════════════════════════ */}
        {screenState === "otp" && (
          <div className="max-w-md mx-auto w-full space-y-8 animate-fadeIn">

            <div className="text-center space-y-3">
              <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-emerald-50 border border-emerald-200 text-emerald-700 text-xs sm:text-sm font-semibold tracking-wide shadow-sm">
                <KeyRound className="w-4 h-4 text-emerald-600" />
                <span>{t("stats_otp_title")}</span>
              </div>

              <h1 className="text-3xl sm:text-4xl font-extrabold text-slate-900 tracking-tight">
                {t("stats_otp_title")}
              </h1>

              <p className="text-sm text-slate-600 leading-relaxed">
                <strong className="text-slate-900">{email}</strong> {t("stats_otp_subtitle")}
              </p>
            </div>

            <div className="bg-white rounded-3xl p-6 sm:p-8 border border-slate-200/80 shadow-xl space-y-6">

              {infoMessage && (
                <div className="bg-violet-50 border border-violet-200 text-violet-800 p-4 rounded-2xl text-xs sm:text-sm font-semibold flex items-center gap-3">
                  <CheckCircle2 className="w-4 h-4 text-violet-600 flex-shrink-0" />
                  <span>{infoMessage}</span>
                </div>
              )}

              {errorMessage && (
                <div className="bg-rose-50 border border-rose-200 text-rose-700 p-4 rounded-2xl text-xs sm:text-sm font-semibold flex items-center gap-3">
                  <AlertCircle className="w-4 h-4 text-rose-600 flex-shrink-0" />
                  <span>{errorMessage}</span>
                </div>
              )}

              <form onSubmit={handleVerifyOtp} className="space-y-6">
                <div className="space-y-2 text-center">
                  <label className="block text-xs font-bold text-slate-700 tracking-wider uppercase">
                    {t("stats_otp_label")}
                  </label>
                  <input
                    type="text"
                    maxLength={6}
                    required
                    value={otpCode}
                    onChange={(e) => setOtpCode(e.target.value.replace(/\D/g, ""))}
                    placeholder="123456"
                    className="w-full py-4 text-center tracking-[0.5em] text-2xl font-mono font-extrabold bg-slate-50 border border-slate-200 rounded-2xl text-slate-900 placeholder:text-slate-300 placeholder:tracking-normal focus:outline-none focus:ring-2 focus:ring-violet-500 focus:bg-white transition"
                  />
                </div>

                <button
                  type="submit"
                  disabled={loading || otpCode.length !== 6}
                  className="w-full flex items-center justify-center gap-3 py-4 px-8 rounded-2xl bg-violet-600 hover:bg-violet-700 text-white font-bold text-base shadow-xl shadow-violet-500/25 transition-all cursor-pointer disabled:opacity-50"
                >
                  {loading ? (
                    <>
                      <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin" />
                      <span>{t("stats_verifying")}</span>
                    </>
                  ) : (
                    <>
                      <span>{t("stats_btn_login")}</span>
                      <ArrowRight className="w-5 h-5" />
                    </>
                  )}
                </button>
              </form>

              <div className="flex items-center justify-between text-xs text-slate-500 pt-2 border-t border-slate-100">
                <button
                  type="button"
                  onClick={() => { setScreenState("email"); setErrorMessage(""); setInfoMessage(""); }}
                  className="hover:text-slate-900 transition cursor-pointer"
                >
                  {t("stats_change_email")}
                </button>

                <button
                  type="button"
                  onClick={handleRequestOtp}
                  disabled={loading}
                  className="text-violet-600 hover:text-violet-700 font-semibold transition cursor-pointer"
                >
                  {t("stats_resend_code")}
                </button>
              </div>

            </div>

          </div>
        )}

        {/* ═══════════════════════════════════════════
            STATE 3: AUTHENTICATED DASHBOARD
        ═══════════════════════════════════════════ */}
        {screenState === "dashboard" && partner && (
          <div className="space-y-8 animate-fadeIn">
            
            {/* Header & Logout bar */}
            <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 bg-white p-6 rounded-3xl border border-slate-200/80 shadow-lg">
              <div className="space-y-1">
                <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-emerald-50 text-emerald-700 text-xs font-bold border border-emerald-200">
                  <ShieldCheck className="w-3.5 h-3.5" />
                  <span>{t("stats_dash_badge")}</span>
                </div>
                <h1 className="text-2xl sm:text-3xl font-extrabold text-slate-900 tracking-tight">
                  {partner.agency_name} {t("stats_dash_title_suffix")}
                </h1>
                <p className="text-xs text-slate-500">
                  {partner.email} &bull; {partner.city} &bull; Referral Code: <code className="text-violet-600 font-mono font-bold bg-violet-50 px-2 py-0.5 rounded border border-violet-200">{partner.slug}</code>
                </p>
              </div>

              <button
                onClick={handleLogout}
                disabled={loading}
                className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 hover:text-slate-900 text-xs font-bold border border-slate-200 transition cursor-pointer"
              >
                <LogOut className="w-4 h-4" />
                <span>{t("stats_logout")}</span>
              </button>
            </div>

            {/* 3 STAT CARDS */}
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-6">

              {/* Total Referral Count Card */}
              <div className="bg-gradient-to-br from-violet-900 via-slate-900 to-slate-950 p-6 sm:p-8 rounded-3xl text-white shadow-xl space-y-3 border border-violet-700/50">
                <div className="flex items-center justify-between text-violet-200">
                  <span className="text-xs font-bold tracking-wider uppercase">{t("stats_total_card")}</span>
                  <div className="p-2 bg-white/10 rounded-xl backdrop-blur-md">
                    <Sparkles className="w-5 h-5 text-amber-400" />
                  </div>
                </div>
                <p className="text-4xl sm:text-5xl font-black text-amber-400">
                  {stats?.totalReferred ?? 0}
                </p>
                <p className="text-xs text-slate-300 font-medium">
                  {t("stats_total_sub")}
                </p>
              </div>

              {/* Landlords Breakdown Card */}
              <div className="bg-white p-6 sm:p-8 rounded-3xl border border-slate-200/80 shadow-lg space-y-3">
                <div className="flex items-center justify-between text-slate-500">
                  <span className="text-xs font-bold tracking-wider uppercase">{t("stats_landlords_card")}</span>
                  <div className="p-2 bg-emerald-50 rounded-xl">
                    <Building2 className="w-5 h-5 text-emerald-600" />
                  </div>
                </div>
                <p className="text-4xl font-extrabold text-emerald-600">
                  {stats?.landlordCount ?? 0}
                </p>
                <p className="text-xs text-slate-500">
                  {t("stats_landlords_sub")}
                </p>
              </div>

              {/* Tenants Breakdown Card */}
              <div className="bg-white p-6 sm:p-8 rounded-3xl border border-slate-200/80 shadow-lg space-y-3">
                <div className="flex items-center justify-between text-slate-500">
                  <span className="text-xs font-bold tracking-wider uppercase">{t("stats_tenants_card")}</span>
                  <div className="p-2 bg-cyan-50 rounded-xl">
                    <UserCheck className="w-5 h-5 text-cyan-600" />
                  </div>
                </div>
                <p className="text-4xl font-extrabold text-cyan-600">
                  {stats?.tenantCount ?? 0}
                </p>
                <p className="text-xs text-slate-500">
                  {t("stats_tenants_sub")}
                </p>
              </div>

            </div>

            {/* TIME-BASED TREND GRAPH */}
            <div className="bg-white p-6 sm:p-8 rounded-3xl border border-slate-200/80 shadow-lg space-y-6">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <TrendingUp className="w-5 h-5 text-violet-600" />
                  <h3 className="text-lg font-bold text-slate-900">
                    {t("stats_trend_title")}
                  </h3>
                </div>
                <span className="text-xs text-slate-500 font-medium">{t("stats_trend_sub")}</span>
              </div>

              {/* Bar Chart Visualization */}
              <div className="pt-4 pb-2">
                {trend.length > 0 ? (
                  <div className="flex items-end justify-between gap-2 sm:gap-4 h-48 px-2 border-b border-slate-100">
                    {trend.map((item, idx) => {
                      const heightPercent = Math.max(Math.round((item.count / maxTrendCount) * 100), 8);
                      return (
                        <div key={idx} className="flex-1 flex flex-col items-center gap-2 h-full justify-end group">
                          <span className="text-xs font-bold text-violet-600 opacity-80 group-hover:opacity-100 transition">
                            {item.count}
                          </span>
                          <div
                            style={{ height: `${heightPercent}%` }}
                            className="w-full max-w-[48px] bg-gradient-to-t from-violet-600 to-violet-400 rounded-t-xl group-hover:from-violet-700 group-hover:to-violet-500 transition-all shadow-md shadow-violet-500/20"
                          />
                          <span className="text-[11px] font-semibold text-slate-500 mt-2">
                            {item.label}
                          </span>
                        </div>
                      );
                    })}
                  </div>
                ) : (
                  <div className="py-12 text-center text-xs text-slate-400">
                    {t("stats_trend_empty")}
                  </div>
                )}
              </div>
            </div>

            {/* QR CODE PREVIEW & RE-DOWNLOAD LINK */}
            <div className="bg-white p-6 sm:p-8 rounded-3xl border border-slate-200/80 shadow-lg flex flex-col sm:flex-row items-center gap-6 justify-between">
              
              {/* Hidden Canvas */}
              <canvas ref={canvasRef} className="hidden" />

              <div className="flex items-center gap-4">
                <div className="p-3 bg-slate-900 rounded-2xl shadow-md border border-slate-800">
                  {qrDataUrl ? (
                    <img src={qrDataUrl} alt="Acente QR Code" className="w-24 h-24 object-contain rounded-lg" />
                  ) : (
                    <div className="w-24 h-24 bg-slate-800 rounded-lg flex items-center justify-center">
                      <QrCode className="w-8 h-8 text-slate-400 animate-pulse" />
                    </div>
                  )}
                </div>
                <div className="space-y-1">
                  <p className="text-base font-bold text-slate-900">{t("stats_qr_title")}</p>
                  <p className="text-xs font-mono text-violet-700 font-bold bg-violet-50 px-2.5 py-1 rounded-md border border-violet-200 inline-block">
                    {partner.slug}
                  </p>
                  <p className="text-xs text-slate-500 pt-1">
                    {t("stats_qr_sub")}
                  </p>
                </div>
              </div>

              <a
                href="/agency-referral"
                className="inline-flex items-center justify-center gap-2 px-6 py-3.5 rounded-2xl bg-violet-600 hover:bg-violet-700 text-white text-xs font-bold shadow-xl shadow-violet-500/20 transition transform hover:-translate-y-0.5 cursor-pointer flex-shrink-0"
              >
                <Download className="w-4 h-4" />
                <span>{t("stats_qr_download_btn")}</span>
              </a>

            </div>

            {/* PRIVACY NOTICE BANNER */}
            <div className="bg-violet-50/70 border border-violet-200/80 p-5 rounded-2xl text-xs text-slate-700 leading-relaxed flex items-start gap-3">
              <ShieldCheck className="w-5 h-5 text-violet-600 flex-shrink-0 mt-0.5" />
              <div dangerouslySetInnerHTML={{ __html: t("stats_privacy_notice") }} />
            </div>

          </div>
        )}

      </main>

      {/* FOOTER */}
      <footer className="py-12 border-t border-slate-200/80 bg-white w-full mt-auto">
        <div className="max-w-7xl mx-auto px-6 text-center space-y-4">
          <div className="flex items-center justify-center gap-2 opacity-60">
            <img src="/assets/logo.png" alt="Stanomer Logo" className="w-5 h-5 object-contain" />
            <span className="font-bold text-xs tracking-tight text-slate-900">Stanomer</span>
          </div>

          <div className="flex flex-wrap justify-center gap-x-6 gap-y-2 mb-4 text-xs font-medium text-slate-600">
            <a href="/agencies" className="hover:text-violet-600 transition-colors font-bold text-violet-600">Acenteler</a>
            <a href="/privacy" className="hover:text-violet-600 transition-colors">{t("footer_privacy")}</a>
            <a href="/terms" className="hover:text-violet-600 transition-colors">{t("footer_terms")}</a>
            <a href="/support" className="hover:text-violet-600 transition-colors">{t("footer_support")}</a>
          </div>

          <p className="text-slate-400 text-xs">
            © 2026 Stanomer. {t("footer_rights")}
          </p>
        </div>
      </footer>

    </div>
  );
}
