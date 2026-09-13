"use client";

import React, { useState, useEffect } from "react";
import { createPortal } from "react-dom";
import { useLanguage } from "./LanguageProvider";
import {
  Building2,
  Globe,
  Mail,
  Sparkles,
  CheckCircle2,
  X,
  ArrowRight,
} from "lucide-react";

interface AgencyDemoModalProps {
  isOpen: boolean;
  onClose: () => void;
  defaultAgencyName?: string;
}

export function AgencyDemoModal({
  isOpen,
  onClose,
  defaultAgencyName = "",
}: AgencyDemoModalProps) {
  const { lang, t } = useLanguage();

  const [mounted, setMounted] = useState(false);
  const [agencyName, setAgencyName] = useState(defaultAgencyName);
  const [email, setEmail] = useState("");
  const [website, setWebsite] = useState("");
  const [honeypot, setHoneypot] = useState("");

  useEffect(() => {
    setMounted(true);
  }, []);

  const [loading, setLoading] = useState(false);
  const [submitted, setSubmitted] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  useEffect(() => {
    if (isOpen) {
      setSubmitted(false);
      setErrorMessage(null);
      setHoneypot("");
    }
  }, [isOpen]);

  if (!isOpen) return null;

  const isTR = lang === "TR";
  const isSR = lang === "SR_LAT" || lang === "SR_CYR";

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMessage(null);

    if (!agencyName.trim() || !email.trim()) {
      setErrorMessage(
        isTR
          ? "Lütfen acente adını ve e-posta adresinizi giriniz."
          : isSR
          ? "Molimo unesite naziv agencije i vašu imejl adresu."
          : "Please enter your agency name and email address."
      );
      return;
    }

    // 1. Invisible Honeypot check (Catches bots that auto-fill hidden fields)
    if (honeypot.trim() !== "") {
      setSubmitted(true);
      return;
    }

    setLoading(true);

    try {
      const formattedWebsite = website.trim()
        ? (/^https?:\/\//i.test(website.trim())
            ? website.trim()
            : `https://${website.trim()}`)
        : null;

      const res = await fetch("/api/send-demo-verification", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          email: email.toLowerCase().trim(),
          agencyName: agencyName.trim(),
          website: formattedWebsite,
          lang: lang || "TR",
          honeypot: honeypot.trim(),
        }),
      });

      const data = await res.json();

      if (!res.ok) {
        throw new Error(data.message || "İstek işlenirken bir hata oluştu.");
      }

      setSubmitted(true);
    } catch (err: any) {
      console.error("[AgencyDemoModal Error]", err);
      setErrorMessage(
        err.message ||
          (isTR
            ? "Bir sorun oluştu. Lütfen bağlantınızı kontrol edip tekrar deneyin."
            : isSR
            ? "Došlo je do greške. Molimo proverite vezu i pokušajte ponovo."
            : "An error occurred. Please check your connection and try again.")
      );
    } finally {
      setLoading(false);
    }
  };

  if (!isOpen || !mounted) return null;

  return createPortal(
    <div className="fixed inset-0 z-[999999] overflow-y-auto bg-slate-900/70 backdrop-blur-sm animate-in fade-in duration-200">
      <div className="flex min-h-full items-center justify-center p-4 sm:p-6">
        <div className="relative w-full max-w-lg bg-white rounded-3xl shadow-2xl border border-slate-100 overflow-hidden text-left my-8">
          {/* Close Button */}
          <button
            onClick={onClose}
            className="absolute top-5 right-5 w-9 h-9 flex items-center justify-center rounded-full bg-slate-100 text-slate-500 hover:bg-slate-200 hover:text-slate-800 transition z-10"
          >
            <X className="w-5 h-5" />
          </button>

        {/* Modal Header */}
        <div className="bg-gradient-to-br from-blue-600 to-indigo-700 p-7 text-white">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-white/20 backdrop-blur-md text-xs font-semibold mb-3">
            <Sparkles className="w-3.5 h-3.5 text-amber-300" />
            <span>
              {isTR ? "İnteraktif Acente Simülasyonu" : isSR ? "Interaktivna Simulacija Panela" : "Interactive Agency Simulation"}
            </span>
          </div>
          <h3 className="text-xl sm:text-2xl font-black tracking-tight leading-tight">
            {isTR
              ? "Acentenizi Anında Simüle Edin"
              : isSR
              ? "Simulirajte Panel za Vašu Agenciju"
              : "Simulate Your Agency Panel"}
          </h3>
          <p className="text-blue-100 text-xs sm:text-sm mt-1.5 leading-relaxed">
            {isTR
              ? "Logonuz, kurumsal renkleriniz ve örnek portföyünüzle panelin nasıl görüneceğini görmek için bilgilerinizi girin. 3 günlük ücretsiz sandbox anında açılır."
              : isSR
              ? "Unesite podatke da vidite kako panel izgleda sa vašim logotipom, bojama i primerom portfolija. Besplatan 3-dnevni sandbox nalog se odmah aktivira."
              : "Enter your details to see the panel branded with your logo, colors, and sample portfolio. A 3-day sandbox is instantly activated."}
          </p>
        </div>

        {/* Modal Body */}
        <div className="p-7">
          {submitted ? (
            <div className="text-center py-6 space-y-4">
              <div className="w-16 h-16 rounded-full bg-emerald-100 text-emerald-600 flex items-center justify-center mx-auto">
                <CheckCircle2 className="w-9 h-9" />
              </div>
              <h4 className="text-xl font-extrabold text-slate-900">
                {isTR ? "Giriş Bağlantınız Gönderildi!" : isSR ? "Link za Prijavu je Poslat!" : "Login Link Sent!"}
              </h4>
              <p className="text-sm text-slate-600 leading-relaxed max-w-sm mx-auto">
                {isTR ? (
                  <>
                    <strong className="text-slate-900">{email}</strong> adresine tek tıkla giriş yapabileceğiniz özel demo erişim bağlantısı gönderildi.
                  </>
                ) : isSR ? (
                  <>
                    Poslali smo pristupni link na <strong className="text-slate-900">{email}</strong>. Kliknite na link u imejlu da otvorite panel.
                  </>
                ) : (
                  <>
                    We sent a 1-click access link to <strong className="text-slate-900">{email}</strong>. Check your inbox to enter your panel.
                  </>
                )}
              </p>
              <div className="pt-2">
                <button
                  onClick={onClose}
                  className="px-6 py-2.5 rounded-xl bg-slate-900 text-white font-semibold text-sm hover:bg-slate-800 transition"
                >
                  {isTR ? "Anladım, Kapat" : isSR ? "Razumem, zatvori" : "Close"}
                </button>
              </div>
            </div>
          ) : (
            <form onSubmit={handleSubmit} className="space-y-4">
              {errorMessage && (
                <div className="p-3 rounded-xl bg-rose-50 border border-rose-200 text-rose-700 text-xs font-medium">
                  {errorMessage}
                </div>
              )}

              {/* Agency Name */}
              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1.5">
                  {isTR ? "Acente Adı *" : isSR ? "Naziv Agencije *" : "Agency Name *"}
                </label>
                <div className="relative">
                  <div className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-slate-400">
                    <Building2 className="w-4 h-4" />
                  </div>
                  <input
                    type="text"
                    required
                    value={agencyName}
                    onChange={(e) => setAgencyName(e.target.value)}
                    placeholder={isTR ? "Örn: Kula Nekretnine" : isSR ? "Npr: Kula Nekretnine" : "e.g. Apex Real Estate"}
                    className="w-full pl-10 pr-4 py-2.5 rounded-xl border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 font-medium text-slate-900"
                  />
                </div>
              </div>

              {/* Email */}
              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1.5">
                  {isTR ? "E-posta Adresiniz *" : isSR ? "Vaša Imejl Adresa *" : "Your Email Address *"}
                </label>
                <div className="relative">
                  <div className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-slate-400">
                    <Mail className="w-4 h-4" />
                  </div>
                  <input
                    type="email"
                    required
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder="ornek@acente.com"
                    className="w-full pl-10 pr-4 py-2.5 rounded-xl border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 font-medium text-slate-900"
                  />
                </div>
              </div>

              {/* Website */}
              <div>
                <div className="flex items-center justify-between mb-1.5">
                  <label className="block text-xs font-bold text-slate-700">
                    {isTR ? "Web Sitesi" : isSR ? "Veb Sajt" : "Website"}
                  </label>
                  <span className="text-[11px] text-blue-600 font-medium">
                    {isTR ? "Logo & renkleri çekmek için" : isSR ? "Za automatski logo i boje" : "For logo & brand colors"}
                  </span>
                </div>
                <div className="relative">
                  <div className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-slate-400">
                    <Globe className="w-4 h-4" />
                  </div>
                  <input
                    type="text"
                    value={website}
                    onChange={(e) => setWebsite(e.target.value)}
                    placeholder="kulanekretnine.rs"
                    className="w-full pl-10 pr-4 py-2.5 rounded-xl border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 font-medium text-slate-900"
                  />
                </div>
              </div>

              {/* Invisible Honeypot anti-bot trap */}
              <div className="absolute opacity-0 -z-50 pointer-events-none h-0 w-0 overflow-hidden" aria-hidden="true">
                <label htmlFor="agency_contact_code">Do not fill this field</label>
                <input
                  type="text"
                  id="agency_contact_code"
                  name="agency_contact_code"
                  tabIndex={-1}
                  autoComplete="off"
                  value={honeypot}
                  onChange={(e) => setHoneypot(e.target.value)}
                />
              </div>

              {/* Submit CTA */}
              <button
                type="submit"
                disabled={loading}
                className="w-full mt-2 py-3.5 px-6 rounded-xl bg-blue-600 hover:bg-blue-700 active:bg-blue-800 text-white font-bold text-sm shadow-lg shadow-blue-500/25 flex items-center justify-center gap-2 transition disabled:opacity-50"
              >
                {loading ? (
                  <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin" />
                ) : (
                  <>
                    <span>
                      {isTR
                        ? "Simülasyon Panelini Başlat"
                        : isSR
                        ? "Pokrenite Simulaciju Panela"
                        : "Launch Panel Simulation"}
                    </span>
                    <ArrowRight className="w-4 h-4" />
                  </>
                )}
              </button>

              <p className="text-[11px] text-center text-slate-400 pt-1">
                {isTR
                  ? "🔒 Kredi kartı gerekmez. Verileriniz 3 gün sonra otomatik silinir."
                  : isSR
                  ? "🔒 Nije potrebna kreditna kartica. Podaci se brišu nakon 3 dana."
                  : "🔒 No credit card required. Sandbox data is deleted after 3 days."}
              </p>
            </form>
          )}
          </div>
        </div>
      </div>
    </div>,
    document.body
  );
}
