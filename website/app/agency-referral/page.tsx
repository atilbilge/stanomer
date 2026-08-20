"use client";

import React, { useState, useEffect, useRef } from "react";
import QRCode from "qrcode";
import { Navbar } from "../../components/Navbar";
import { useLanguage } from "../../components/LanguageProvider";
import {
  QrCode,
  Download,
  Printer,
  CheckCircle2,
  Sparkles,
  Building2,
  User,
  Mail,
  Phone,
  MapPin,
  Globe,
  Users,
  HelpCircle,
  ArrowRight,
  ShieldCheck,
  RotateCcw,
  Search
} from "lucide-react";

interface ReferralPartner {
  id?: string;
  agency_name: string;
  contact_name: string;
  email: string;
  phone: string;
  city: string;
  website?: string;
  agency_size?: string;
  referral_source?: string;
  slug: string;
  referral_code: string;
}

export default function AgencyReferralPage() {
  const { t, lang } = useLanguage();

  // Form states
  const [agencyName, setAgencyName] = useState("");
  const [contactName, setContactName] = useState("");
  const [email, setEmail] = useState("");
  const [phone, setPhone] = useState("");
  const [city, setCity] = useState("Belgrade");
  const [website, setWebsite] = useState("");
  const [agencySize, setAgencySize] = useState("");
  const [referralSource, setReferralSource] = useState("");

  const [loading, setLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState("");
  const [referralStats, setReferralStats] = useState<{
    totalReferred: number;
    landlordCount: number;
    tenantCount: number;
  } | null>(null);

  const [activeTab, setActiveTab] = useState<"register" | "lookup">("register");
  const [lookupEmail, setLookupEmail] = useState("");

  const [partnerResult, setPartnerResult] = useState<ReferralPartner | null>(null);
  const [isExisting, setIsExisting] = useState(false);
  const [fromLookup, setFromLookup] = useState(false);
  const [resendingEmail, setResendingEmail] = useState(false);
  const [resendEmailSuccess, setResendEmailSuccess] = useState(false);

  // QR Code canvas reference
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const [qrDataUrl, setQrDataUrl] = useState<string>("");

  // Generate QR Code on canvas when partnerResult changes
  useEffect(() => {
    if (partnerResult?.slug) {
      const codeToken = partnerResult.referral_code || partnerResult.slug;
      const targetUrl = `stanomer://referral?token=${codeToken}`;

      if (canvasRef.current) {
        QRCode.toCanvas(
          canvasRef.current,
          targetUrl,
          {
            width: 1000,
            margin: 2,
            color: {
              dark: "#0f172a",
              light: "#ffffff"
            }
          },
          (err) => {
            if (err) console.error("QR Code canvas render error:", err);
            else if (canvasRef.current) {
              setQrDataUrl(canvasRef.current.toDataURL("image/png"));
            }
          }
        );
      } else {
        QRCode.toDataURL(
          targetUrl,
          {
            width: 1000,
            margin: 2,
            color: {
              dark: "#0f172a",
              light: "#ffffff"
            }
          },
          (err, url) => {
            if (!err && url) setQrDataUrl(url);
          }
        );
      }
    }
  }, [partnerResult]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMessage("");

    if (!agencyName.trim() || !contactName.trim() || !email.trim() || !city.trim()) {
      setErrorMessage(t("ref_submit_error_required") || "Lütfen tüm zorunlu alanları doldurunuz.");
      return;
    }

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email.trim())) {
      setErrorMessage(t("ref_submit_error_email") || "Geçerli bir e-posta adresi giriniz.");
      return;
    }

    setLoading(true);

    try {
      let formattedWebsite = website.trim();
      if (formattedWebsite && !/^https?:\/\//i.test(formattedWebsite)) {
        formattedWebsite = `https://${formattedWebsite}`;
      }

      const response = await fetch("/api/register-referral-agency", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          agencyName: agencyName.trim(),
          contactName: contactName.trim(),
          email: email.trim(),
          phone: phone.trim(),
          city: city.trim(),
          website: formattedWebsite || undefined,
          agencySize: agencySize || undefined,
          referralSource: referralSource || undefined,
          lang: lang || "TR"
        })
      });

      const data = await response.json();

      if (response.ok && data.success && data.partner) {
        setPartnerResult(data.partner);
        setIsExisting(!!data.isExisting);
        setFromLookup(false);
        setResendEmailSuccess(false);
        if (data.stats) setReferralStats(data.stats);
      } else {
        setErrorMessage(data.message || "Bir hata oluştu. Lütfen tekrar deneyiniz.");
      }
    } catch (err: any) {
      console.error("Referral registration error:", err);
      setErrorMessage("Bağlantı hatası oluştu. Lütfen tekrar deneyiniz.");
    } finally {
      setLoading(false);
    }
  };

  const handleLookup = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMessage("");

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(lookupEmail.trim())) {
      setErrorMessage(t("invalid_email") || "Geçerli bir e-posta adresi giriniz.");
      return;
    }

    setLoading(true);

    try {
      const response = await fetch("/api/lookup-referral-agency", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          email: lookupEmail.trim(),
          lang: lang || "TR"
        })
      });

      const data = await response.json();

      if (response.ok && data.success && data.partner) {
        setPartnerResult(data.partner);
        setIsExisting(true);
        setFromLookup(true);
        setResendEmailSuccess(false);
        if (data.stats) setReferralStats(data.stats);
      } else {
        setErrorMessage(t("ref_lookup_not_found") || data.message || "Bu e-posta adresi ile kayıtlı bir acente bulunamadı.");
      }
    } catch (err: any) {
      console.error("Referral lookup error:", err);
      setErrorMessage(t("error_msg") || "Bağlantı hatası oluştu. Lütfen tekrar deneyiniz.");
    } finally {
      setLoading(false);
    }
  };

  const handleResendEmail = async () => {
    if (!partnerResult || resendingEmail) return;
    setResendingEmail(true);
    try {
      const response = await fetch("/api/send-referral-qr", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          email: partnerResult.email,
          agencyName: partnerResult.agency_name,
          slug: partnerResult.slug,
          referralCode: partnerResult.referral_code,
          lang: lang || "TR"
        })
      });
      if (response.ok) {
        setResendEmailSuccess(true);
      }
    } catch (e) {
      console.error("Resend QR email error:", e);
    } finally {
      setResendingEmail(false);
    }
  };

  const handleDownloadPNG = () => {
    if (!qrDataUrl && !canvasRef.current) return;
    const dataUrl = qrDataUrl || (canvasRef.current ? canvasRef.current.toDataURL("image/png") : "");
    if (!dataUrl) return;

    const link = document.createElement("a");
    link.href = dataUrl;
    link.download = `stanomer-qr-${partnerResult?.slug || "referral"}.png`;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  const handlePrintPDF = () => {
    window.print();
  };

  return (
    <div className="min-h-screen bg-slate-50 flex flex-col font-sans text-slate-900 overflow-x-hidden">
      <Navbar />

      {/* Spacer for fixed Navbar */}
      <div className="h-[80px]" />

      {/* Printable Poster Section (Visible only when printing) */}
      {partnerResult && (
        <div className="hidden print:block fixed inset-0 bg-white p-12 text-slate-900 z-[9999]">
          <div className="max-w-xl mx-auto border-4 border-slate-900 rounded-3xl p-10 text-center space-y-8 h-full flex flex-col justify-between">
            {/* Header */}
            <div className="space-y-3">
              <div className="flex items-center justify-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-violet-600 text-white flex items-center justify-center font-extrabold text-xl">
                  S
                </div>
                <span className="text-3xl font-black tracking-tight text-slate-900">Stanomer</span>
              </div>
              <p className="text-sm font-semibold text-slate-500 tracking-wider uppercase">
                {t("ref_poster_subtitle")}
              </p>
            </div>

            {/* Poster Headline */}
            <div className="space-y-2 py-4 border-y-2 border-slate-100">
              <h1 className="text-3xl font-extrabold text-slate-900 leading-tight">
                {t("ref_poster_headline")}
              </h1>
              <p className="text-base text-slate-600 max-w-md mx-auto">
                {t("ref_poster_tagline")}
              </p>
            </div>

            {/* QR Code */}
            <div className="flex flex-col items-center justify-center space-y-4 py-4">
              <div className="p-4 bg-slate-900 rounded-2xl shadow-xl border border-slate-800">
                {qrDataUrl && (
                  <img src={qrDataUrl} alt="Stanomer QR Code" className="w-64 h-64 object-contain rounded-lg" />
                )}
              </div>
              <div>
                <p className="text-xl font-black text-violet-700 tracking-wide">
                  {partnerResult.agency_name.toUpperCase()}
                </p>
                <p className="text-xs font-mono text-slate-400 mt-1">
                  REFERRAL CODE: {partnerResult.slug}
                </p>
              </div>
            </div>

            {/* Instructions */}
            <div className="bg-violet-50 p-6 rounded-2xl border border-violet-200 text-slate-800 text-sm space-y-1">
              <p className="font-bold text-violet-900">{t("ref_poster_how_title")}</p>
              <p className="text-xs text-slate-700 leading-relaxed">
                {t("ref_poster_how_desc")}
              </p>
            </div>

            {/* Footer */}
            <div className="text-xs text-slate-400 pt-4">
              www.stanomer.online &bull; {t("ref_qr_card_footer")}
            </div>
          </div>
        </div>
      )}

      {/* Standard Screen Content */}
      <main className="flex-1 py-12 md:py-20 px-4 sm:px-6 lg:px-8 max-w-4xl mx-auto w-full print:hidden">

        {/* Top Decorative Blob */}
        <div className="absolute top-20 left-1/2 -translate-x-1/2 w-full max-w-4xl h-96 bg-violet-400/10 rounded-full blur-3xl -z-10 pointer-events-none" />

        {/* HEADER */}
        <div className="text-center space-y-4 mb-10">
          <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-violet-50 border border-violet-200/80 text-violet-700 text-xs sm:text-sm font-semibold tracking-wide shadow-sm">
            <QrCode className="w-4 h-4 text-violet-600 animate-pulse" />
            <span>Referral Partner Program</span>
          </div>

          <h1 className="text-3xl sm:text-4xl lg:text-5xl font-extrabold text-slate-900 tracking-tight leading-[1.15]">
            {t("ref_form_title")}
          </h1>

          <p className="text-base sm:text-lg text-slate-600 leading-relaxed max-w-2xl mx-auto">
            {t("ref_form_subtitle")}
          </p>
        </div>

        {/* STATE 1: FORM & LOOKUP TABS */}
        {!partnerResult ? (
          <div className="bg-white rounded-3xl p-6 sm:p-10 border border-slate-200/80 shadow-xl relative overflow-hidden space-y-8">
            
            {/* Tab Switcher */}
            <div className="flex bg-slate-100 p-1.5 rounded-2xl max-w-md mx-auto">
              <button
                type="button"
                onClick={() => { setActiveTab("register"); setErrorMessage(""); }}
                className={`flex-1 py-2.5 px-4 rounded-xl text-xs sm:text-sm font-bold transition-all cursor-pointer ${
                  activeTab === "register"
                    ? "bg-white text-violet-700 shadow-md"
                    : "text-slate-500 hover:text-slate-900"
                }`}
              >
                {t("agencies_ref_cta_btn") || "Yeni Acente Kaydı"}
              </button>

              <button
                type="button"
                onClick={() => { setActiveTab("lookup"); setErrorMessage(""); }}
                className={`flex-1 py-2.5 px-4 rounded-xl text-xs sm:text-sm font-bold transition-all cursor-pointer flex items-center justify-center gap-1.5 ${
                  activeTab === "lookup"
                    ? "bg-white text-violet-700 shadow-md"
                    : "text-slate-500 hover:text-slate-900"
                }`}
              >
                <Search className="w-3.5 h-3.5" />
                <span>{t("ref_lookup_tab") || "Referans İstatistikleri & QR Gör"}</span>
              </button>
            </div>

            {/* Error Banner */}
            {errorMessage && (
              <div className="bg-rose-50 border border-rose-200 text-rose-700 p-4 rounded-xl text-sm font-semibold flex items-center gap-3">
                <span className="w-2 h-2 rounded-full bg-rose-600 flex-shrink-0" />
                <span>{errorMessage}</span>
              </div>
            )}

            {/* TAB 1: REGISTER */}
            {activeTab === "register" ? (
              <form onSubmit={handleSubmit} className="space-y-6">
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-6">

                  {/* Agency Name */}
                  <div className="space-y-2">
                    <label className="block text-xs font-bold text-slate-700 tracking-wider">
                      {t("ref_field_agency_name")} <span className="text-violet-600">*</span>
                    </label>
                    <div className="relative">
                      <Building2 className="w-5 h-5 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
                      <input
                        type="text"
                        required
                        value={agencyName}
                        onChange={(e) => setAgencyName(e.target.value)}
                        placeholder={t("ref_placeholder_agency_name")}
                        className="w-full pl-11 pr-4 py-3.5 bg-slate-50 border border-slate-200 rounded-xl text-sm text-slate-900 placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-violet-500 focus:bg-white transition"
                      />
                    </div>
                  </div>

                  {/* Contact Name */}
                  <div className="space-y-2">
                    <label className="block text-xs font-bold text-slate-700 tracking-wider">
                      {t("ref_field_contact_name")} <span className="text-violet-600">*</span>
                    </label>
                    <div className="relative">
                      <User className="w-5 h-5 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
                      <input
                        type="text"
                        required
                        value={contactName}
                        onChange={(e) => setContactName(e.target.value)}
                        placeholder={t("ref_placeholder_contact_name")}
                        className="w-full pl-11 pr-4 py-3.5 bg-slate-50 border border-slate-200 rounded-xl text-sm text-slate-900 placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-violet-500 focus:bg-white transition"
                      />
                    </div>
                  </div>

                  {/* Email */}
                  <div className="space-y-2">
                    <label className="block text-xs font-bold text-slate-700 tracking-wider">
                      {t("ref_field_email")} <span className="text-violet-600">*</span>
                    </label>
                    <div className="relative">
                      <Mail className="w-5 h-5 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
                      <input
                        type="email"
                        required
                        value={email}
                        onChange={(e) => setEmail(e.target.value)}
                        placeholder={t("ref_placeholder_email")}
                        className="w-full pl-11 pr-4 py-3.5 bg-slate-50 border border-slate-200 rounded-xl text-sm text-slate-900 placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-violet-500 focus:bg-white transition"
                      />
                    </div>
                  </div>

                  {/* Phone (Optional) */}
                  <div className="space-y-2">
                    <label className="block text-xs font-bold text-slate-700 tracking-wider">
                      {t("ref_field_phone")}
                    </label>
                    <div className="relative">
                      <Phone className="w-5 h-5 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
                      <input
                        type="tel"
                        value={phone}
                        onChange={(e) => setPhone(e.target.value)}
                        placeholder="+381 61 123 4567"
                        className="w-full pl-11 pr-4 py-3.5 bg-slate-50 border border-slate-200 rounded-xl text-sm text-slate-900 placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-violet-500 focus:bg-white transition"
                      />
                    </div>
                  </div>

                  {/* City / Region */}
                  <div className="space-y-2">
                    <label className="block text-xs font-bold text-slate-700 tracking-wider">
                      {t("ref_field_city")} <span className="text-violet-600">*</span>
                    </label>
                    <div className="relative">
                      <MapPin className="w-5 h-5 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2 pointer-events-none" />
                      <select
                        value={city}
                        onChange={(e) => setCity(e.target.value)}
                        className="w-full pl-11 pr-4 py-3.5 bg-slate-50 border border-slate-200 rounded-xl text-sm text-slate-900 focus:outline-none focus:ring-2 focus:ring-violet-500 focus:bg-white transition appearance-none cursor-pointer"
                      >
                        <option value="Belgrade">Belgrade / Beograd</option>
                        <option value="Novi Sad">Novi Sad</option>
                        <option value="Niš">Niš</option>
                        <option value="Subotica">Subotica</option>
                        <option value="Kragujevac">Kragujevac</option>
                        <option value="Podgorica">Podgorica</option>
                        <option value="Diğer">{t("ref_city_other")}</option>
                      </select>
                    </div>
                  </div>

                  {/* Agency Size (Optional) */}
                  <div className="space-y-2">
                    <label className="block text-xs font-bold text-slate-700 tracking-wider">
                      {t("ref_field_agency_size")}
                    </label>
                    <div className="relative">
                      <Users className="w-5 h-5 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2 pointer-events-none" />
                      <select
                        value={agencySize}
                        onChange={(e) => setAgencySize(e.target.value)}
                        className="w-full pl-11 pr-4 py-3.5 bg-slate-50 border border-slate-200 rounded-xl text-sm text-slate-900 focus:outline-none focus:ring-2 focus:ring-violet-500 focus:bg-white transition appearance-none cursor-pointer"
                      >
                        <option value="">{t("ref_select_placeholder")}</option>
                        <option value="1-9">{t("ref_size_1_9")}</option>
                        <option value="10-49">{t("ref_size_10_49")}</option>
                        <option value="50+">{t("ref_size_50_plus")}</option>
                      </select>
                    </div>
                  </div>

                  {/* Website (Optional) */}
                  <div className="space-y-2">
                    <label className="block text-xs font-bold text-slate-700 tracking-wider">
                      {t("ref_field_website")}
                    </label>
                    <div className="relative">
                      <Globe className="w-5 h-5 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
                      <input
                        type="text"
                        value={website}
                        onChange={(e) => setWebsite(e.target.value)}
                        placeholder={t("ref_placeholder_website")}
                        className="w-full pl-11 pr-4 py-3.5 bg-slate-50 border border-slate-200 rounded-xl text-sm text-slate-900 placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-violet-500 focus:bg-white transition"
                      />
                    </div>
                  </div>

                  {/* Referral Source (Optional) */}
                  <div className="space-y-2">
                    <label className="block text-xs font-bold text-slate-700 tracking-wider">
                      {t("ref_field_source")}
                    </label>
                    <div className="relative">
                      <HelpCircle className="w-5 h-5 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2 pointer-events-none" />
                      <select
                        value={referralSource}
                        onChange={(e) => setReferralSource(e.target.value)}
                        className="w-full pl-11 pr-4 py-3.5 bg-slate-50 border border-slate-200 rounded-xl text-sm text-slate-900 focus:outline-none focus:ring-2 focus:ring-violet-500 focus:bg-white transition appearance-none cursor-pointer"
                      >
                        <option value="">{t("ref_select_placeholder")}</option>
                        <option value="Tavsiye">{t("ref_src_recommendation")}</option>
                        <option value="Sosyal Medya">{t("ref_src_social")}</option>
                        <option value="Google">{t("ref_src_google")}</option>
                        <option value="Emlak İlan Sitesi">{t("ref_src_portal")}</option>
                        <option value="Diğer">{t("ref_src_other")}</option>
                      </select>
                    </div>
                  </div>

                </div>

                <div className="pt-4">
                  <button
                    type="submit"
                    disabled={loading}
                    className="w-full flex items-center justify-center gap-3 py-4 px-8 rounded-xl bg-violet-600 hover:bg-violet-700 text-white font-bold text-base shadow-xl shadow-violet-500/25 transition-all transform hover:-translate-y-0.5 active:translate-y-0 disabled:opacity-50 disabled:pointer-events-none cursor-pointer"
                  >
                    {loading ? (
                      <>
                        <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin" />
                        <span>{t("ref_processing")}</span>
                      </>
                    ) : (
                      <>
                        <span>{t("ref_submit_btn")}</span>
                        <ArrowRight className="w-5 h-5" />
                      </>
                    )}
                  </button>
                </div>
              </form>
            ) : (
              /* TAB 2: LOOKUP BY EMAIL */
              <form onSubmit={handleLookup} className="space-y-6 max-w-md mx-auto py-4">
                <div className="text-center space-y-2">
                  <h3 className="text-lg font-bold text-slate-900">
                    {t("ref_lookup_title")}
                  </h3>
                  <p className="text-xs text-slate-500">
                    {t("ref_lookup_subtitle")}
                  </p>
                </div>

                <div className="space-y-2">
                  <label className="block text-xs font-bold text-slate-700 tracking-wider">
                    {t("ref_field_email")} <span className="text-violet-600">*</span>
                  </label>
                  <div className="relative">
                    <Mail className="w-5 h-5 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
                    <input
                      type="email"
                      required
                      value={lookupEmail}
                      onChange={(e) => setLookupEmail(e.target.value)}
                      placeholder={t("ref_placeholder_email")}
                      className="w-full pl-11 pr-4 py-3.5 bg-slate-50 border border-slate-200 rounded-xl text-sm text-slate-900 placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-violet-500 focus:bg-white transition"
                    />
                  </div>
                </div>

                <button
                  type="submit"
                  disabled={loading}
                  className="w-full flex items-center justify-center gap-3 py-4 px-8 rounded-xl bg-violet-600 hover:bg-violet-700 text-white font-bold text-base shadow-xl shadow-violet-500/25 transition-all cursor-pointer disabled:opacity-50"
                >
                  {loading ? (
                    <>
                      <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin" />
                      <span>{t("ref_fetching")}</span>
                    </>
                  ) : (
                    <>
                      <span>{t("ref_lookup_btn") || "İstatistiklerimi Getir"}</span>
                      <ArrowRight className="w-5 h-5" />
                    </>
                  )}
                </button>
              </form>
            )}

          </div>
        ) : (
          /* STATE 2: RESULT & QR DELIVERY & LIVE STATS */
          <div className="space-y-8 animate-fadeIn">

            {/* Hidden canvas for high-res rendering */}
            <canvas ref={canvasRef} className="hidden" />

            {/* Success & Dashboard Card */}
            <div className="bg-white rounded-3xl p-6 sm:p-10 border border-slate-200/80 shadow-2xl space-y-8 text-center">

              {/* Status Badge */}
              <div className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full bg-emerald-50 border border-emerald-200 text-emerald-700 text-xs sm:text-sm font-bold tracking-wide">
                <CheckCircle2 className="w-4 h-4 text-emerald-600" />
                <span>
                  {isExisting
                    ? t("ref_result_existing_badge")
                    : t("ref_result_title")}
                </span>
              </div>

              {/* LIVE REFERRAL STATS WIDGET */}
              {referralStats && (
                <div className="bg-gradient-to-br from-violet-900 via-slate-900 to-slate-950 p-6 sm:p-8 rounded-3xl text-white shadow-xl max-w-xl mx-auto space-y-4 text-left border border-violet-700/50">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <Sparkles className="w-5 h-5 text-amber-400" />
                      <h3 className="font-extrabold text-sm sm:text-base tracking-wide text-white">
                        {t("ref_stats_title")}
                      </h3>
                    </div>
                    <span className="text-[10px] font-bold bg-emerald-500/20 text-emerald-400 px-2.5 py-1 rounded-full border border-emerald-500/30">
                      {t("ref_live_badge")}
                    </span>
                  </div>

                  <div className="grid grid-cols-3 gap-3 pt-2">
                    <div className="bg-white/10 backdrop-blur-md p-3.5 rounded-2xl border border-white/10 text-center">
                      <p className="text-2xl sm:text-3xl font-black text-amber-400">
                        {referralStats.totalReferred}
                      </p>
                      <p className="text-[11px] font-semibold text-slate-300 mt-1">
                        {t("ref_stat_total") || "Toplam Kullanıcı"}
                      </p>
                    </div>

                    <div className="bg-white/10 backdrop-blur-md p-3.5 rounded-2xl border border-white/10 text-center">
                      <p className="text-2xl sm:text-3xl font-black text-emerald-400">
                        {referralStats.landlordCount}
                      </p>
                      <p className="text-[11px] font-semibold text-slate-300 mt-1">
                        {t("ref_stat_landlords") || "Ev Sahibi"}
                      </p>
                    </div>

                    <div className="bg-white/10 backdrop-blur-md p-3.5 rounded-2xl border border-white/10 text-center">
                      <p className="text-2xl sm:text-3xl font-black text-cyan-400">
                        {referralStats.tenantCount}
                      </p>
                      <p className="text-[11px] font-semibold text-slate-300 mt-1">
                        {t("ref_stat_tenants") || "Kiracı"}
                      </p>
                    </div>
                  </div>
                </div>
              )}

              {/* QR Code Container */}
              <div className="space-y-4">
                <div className="inline-block p-6 bg-slate-900 rounded-3xl shadow-2xl border border-slate-800 relative">
                  {qrDataUrl ? (
                    <img
                      src={qrDataUrl}
                      alt="Stanomer QR Code"
                      className="w-56 h-56 object-contain rounded-lg"
                    />
                  ) : (
                    <div className="w-56 h-56 bg-slate-100 flex items-center justify-center rounded-lg">
                      <QrCode className="w-12 h-12 text-slate-400 animate-pulse" />
                    </div>
                  )}
                </div>

                <div className="space-y-1 text-center">
                  <p className="text-xs font-bold tracking-wider text-slate-400 uppercase">
                    Referral Code / Slug
                  </p>
                  <p className="text-base font-extrabold font-mono text-violet-400 tracking-wide bg-slate-800/80 py-1.5 px-3 rounded-lg border border-slate-700 inline-block">
                    {partnerResult.slug}
                  </p>
                </div>
              </div>

              {/* Download & Print Buttons */}
              <div className="flex flex-col sm:flex-row gap-4 justify-center max-w-md mx-auto pt-2">
                <button
                  onClick={handleDownloadPNG}
                  className="flex-1 inline-flex justify-center items-center gap-2 px-6 py-3.5 rounded-xl bg-violet-600 hover:bg-violet-700 text-white font-bold text-sm shadow-xl shadow-violet-500/20 transition transform hover:-translate-y-0.5 active:translate-y-0 cursor-pointer"
                >
                  <Download className="w-4 h-4" />
                  <span>{t("ref_download_png")}</span>
                </button>

                <button
                  onClick={handlePrintPDF}
                  className="flex-1 inline-flex justify-center items-center gap-2 px-6 py-3.5 rounded-xl bg-slate-900 hover:bg-slate-800 text-white font-bold text-sm shadow-lg transition transform hover:-translate-y-0.5 active:translate-y-0 cursor-pointer"
                >
                  <Printer className="w-4 h-4" />
                  <span>{t("ref_download_pdf")}</span>
                </button>
              </div>

              {/* Usage Guide Box */}
              <div className="bg-slate-50 border border-slate-200 p-6 rounded-2xl text-left space-y-2 text-sm text-slate-700 max-w-xl mx-auto">
                <div className="flex items-center gap-2 font-bold text-slate-900">
                  <ShieldCheck className="w-5 h-5 text-violet-600" />
                  <span>{t("ref_usage_title")}</span>
                </div>
                <p className="text-xs sm:text-sm leading-relaxed text-slate-600">
                  {t("ref_usage_guide")}
                </p>
              </div>

              {/* Notice / Resend Action depending on registration vs lookup */}
              {!fromLookup ? (
                /* Newly Registered: Show email sent confirmation */
                <div className="bg-violet-50/70 border border-violet-200/80 p-4 rounded-xl text-xs sm:text-sm text-violet-800 font-medium flex items-start justify-center gap-2 max-w-xl mx-auto">
                  <CheckCircle2 className="w-4 h-4 text-violet-600 flex-shrink-0 mt-0.5" />
                  <span className="min-w-0 break-all">
                    <span dangerouslySetInnerHTML={{ __html: t("ref_email_sent_to").replace("{{email}}", `<strong>${partnerResult.email}</strong>`) }} />
                  </span>
                </div>
              ) : (
                /* Looked Up via Tab 2: Show optional "Send to My Email" button without spamming automatically */
                <div className="max-w-xl mx-auto">
                  {resendEmailSuccess ? (
                    <div className="bg-emerald-50 border border-emerald-200 p-3.5 rounded-xl text-xs sm:text-sm text-emerald-800 font-medium flex items-center justify-center gap-2">
                      <CheckCircle2 className="w-4 h-4 text-emerald-600 flex-shrink-0" />
                      <span>{t("ref_resend_email_success")}</span>
                    </div>
                  ) : (
                    <button
                      type="button"
                      onClick={handleResendEmail}
                      disabled={resendingEmail}
                      className="inline-flex items-center justify-center gap-2 px-5 py-2.5 rounded-xl bg-violet-100 hover:bg-violet-200 text-violet-800 text-xs sm:text-sm font-bold transition cursor-pointer disabled:opacity-50"
                    >
                      <Mail className="w-4 h-4 text-violet-600" />
                      <span>
                        {resendingEmail ? t("ref_resending_email") : t("ref_resend_email_btn")}
                      </span>
                    </button>
                  )}
                </div>
              )}

              {/* Reset / Create Another button */}
              <div className="pt-2">
                <button
                  onClick={() => {
                    setPartnerResult(null);
                    setReferralStats(null);
                    setAgencyName("");
                    setContactName("");
                    setEmail("");
                    setPhone("");
                    setWebsite("");
                    setAgencySize("");
                  }}
                  className="inline-flex items-center gap-2 text-xs font-bold text-slate-500 hover:text-slate-800 transition cursor-pointer"
                >
                  <RotateCcw className="w-3.5 h-3.5" />
                  <span>{t("ref_reset_btn")}</span>
                </button>
              </div>

            </div>

          </div>
        )}

      </main>

      {/* FOOTER */}
      <footer className="py-12 border-t border-slate-200/80 bg-white w-full mt-auto print:hidden">
        <div className="max-w-7xl mx-auto px-6 text-center">
          <div className="flex items-center justify-center gap-2 opacity-60 mb-6">
            <img src="/assets/logo.png" alt="Stanomer Logo" className="w-6 h-6 object-contain" />
            <span className="font-bold text-sm tracking-tight text-slate-900">Stanomer</span>
          </div>

          <div className="flex flex-wrap justify-center gap-x-6 gap-y-2 mb-6 text-xs font-medium text-slate-600">
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
