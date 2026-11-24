"use client";

import React, { useState, useEffect } from "react";
import { X, CheckCircle2, ShieldCheck, ArrowRight, Loader2, Mail, Phone, Building2, Lock } from "lucide-react";
import { useLanguage } from "../../../components/LanguageProvider";

interface DemoVerificationModalProps {
  isOpen: boolean;
  onClose: () => void;
  initialAgencyName?: string;
  initialEmail?: string;
  initialPhone?: string;
  onSuccess?: (email: string) => void;
}

export default function DemoVerificationModal({
  isOpen,
  onClose,
  initialAgencyName = "",
  initialEmail = "",
  initialPhone = "",
  onSuccess,
}: DemoVerificationModalProps) {
  const { lang, t } = useLanguage();

  const [agencyName, setAgencyName] = useState(initialAgencyName);
  const [email, setEmail] = useState(initialEmail);
  const [phone, setPhone] = useState(initialPhone);
  const [loading, setLoading] = useState(false);
  const [submitted, setSubmitted] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  useEffect(() => {
    if (isOpen) {
      setSubmitted(false);
      setErrorMessage(null);
      if (initialAgencyName && !agencyName) setAgencyName(initialAgencyName);
      if (initialEmail && !email) setEmail(initialEmail);
      if (initialPhone && !phone) setPhone(initialPhone);
    }
  }, [isOpen, initialAgencyName, initialEmail, initialPhone]);

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMessage(null);

    const cleanEmail = email.trim().toLowerCase();
    const cleanPhone = phone.trim();
    const cleanName = agencyName.trim() || "Agency";

    if (!cleanEmail) {
      setErrorMessage(t("fieldRequired"));
      return;
    }
    if (!cleanPhone) {
      setErrorMessage(t("fieldRequired"));
      return;
    }

    setLoading(true);

    try {
      const res = await fetch("/api/send-demo-verification", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          email: cleanEmail,
          agencyName: cleanName,
          phone: cleanPhone,
          lang: lang || "TR",
        }),
      });

      const data = await res.json();
      if (!res.ok || !data.success) {
        throw new Error(data.message || t("agency_demo_error_msg"));
      }

      setSubmitted(true);
      if (typeof window !== "undefined") {
        try {
          const cur = localStorage.getItem("stanomer_agency_demo");
          let parsed = cur ? JSON.parse(cur) : {};
          localStorage.setItem(
            "stanomer_agency_demo",
            JSON.stringify({
              ...parsed,
              email: cleanEmail,
              phone: cleanPhone,
              agencyName: cleanName,
            })
          );
        } catch (_) {}
      }

      onSuccess?.(cleanEmail);
    } catch (err: any) {
      console.error("Demo verification request error:", err);
      setErrorMessage(err.message || t("agency_demo_error_msg"));
    } finally {
      setLoading(false);
    }
  };

  return (
    <div
      role="dialog"
      aria-modal="true"
      className="fixed inset-0 z-[99999] flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-xs animate-in fade-in duration-200"
    >
      <div className="fixed inset-0 -z-10" onClick={onClose} aria-hidden="true" />

      <div className="relative w-full max-w-lg bg-white rounded-[16px] shadow-[0_25px_70px_rgba(15,41,66,0.35)] border-2 border-[#1B5888]/30 overflow-hidden text-left animate-in zoom-in-95 duration-200">
        {/* Distinct Branded Gatekeeper Header */}
        <div className="relative bg-gradient-to-br from-[#0F2942] via-[#153B61] to-[#1B5888] px-6 py-5 text-white">
          <button
            type="button"
            onClick={onClose}
            className="absolute top-4 right-4 text-white/70 hover:text-white hover:bg-white/10 p-1.5 rounded-lg transition-colors cursor-pointer"
            aria-label={t("close")}
          >
            <X className="w-5 h-5" />
          </button>

          <div className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full bg-amber-400/20 border border-amber-300/40 text-amber-200 text-[11px] font-bold mb-3">
            <Lock className="w-3 h-3" />
            <span>{t("demo_preview_banner_badge")}</span>
          </div>

          <div className="flex items-start gap-3 pr-6">
            <div className="w-10 h-10 rounded-[10px] bg-white/15 text-white flex items-center justify-center shrink-0 border border-white/20">
              <ShieldCheck className="w-5 h-5" />
            </div>
            <div className="space-y-1">
              <h3 className="text-base font-bold text-white leading-snug">
                {submitted ? t("demo_gatekeeper_success_title") : t("demo_gatekeeper_title")}
              </h3>
              {!submitted && (
                <p className="text-xs text-blue-100/90 leading-relaxed">
                  {t("demo_gatekeeper_desc")}
                </p>
              )}
            </div>
          </div>
        </div>

        <div className="p-6 sm:p-7">
        {submitted ? (
          <div className="text-center py-2 space-y-4">
            <div className="w-14 h-14 rounded-full bg-[#E5EEF6] text-[#1B5888] flex items-center justify-center mx-auto">
              <CheckCircle2 className="w-8 h-8" />
            </div>
            <div className="space-y-1">
              <p className="text-xs text-[#666666] leading-relaxed max-w-sm mx-auto">
                <strong className="text-[#1A1A1A]">{email}</strong> {t("demo_gatekeeper_success_desc")}
              </p>
            </div>
            <div className="pt-2">
              <button
                type="button"
                onClick={onClose}
                className="w-full py-2.5 px-4 rounded-[10px] bg-[#1B5888] hover:bg-[#12406A] active:bg-[#12406A] text-white text-xs font-bold transition-colors cursor-pointer shadow-xs"
              >
                {t("understood")}
              </button>
            </div>
          </div>
        ) : (
          <form onSubmit={handleSubmit} className="space-y-4">
            {errorMessage && (
              <div className="p-3 rounded-lg bg-rose-50 border border-rose-200 text-rose-700 text-xs font-semibold">
                {errorMessage}
              </div>
            )}

            <div className="space-y-3 pt-1">
              <div>
                <label className="text-xs font-bold text-[#4A4A4A] block mb-1">
                  {t("demo_gatekeeper_field_name")}
                </label>
                <div className="relative">
                  <Building2 className="w-4 h-4 text-[#8A8A8A] absolute left-3 top-1/2 -translate-y-1/2" />
                  <input
                    type="text"
                    value={agencyName}
                    onChange={(e) => setAgencyName(e.target.value)}
                    placeholder="Stanomer Nekretnine"
                    className="w-full pl-9 pr-3 py-2 text-xs font-semibold rounded-[10px] border border-[#E5E3DF] text-[#1A1A1A] focus:outline-hidden focus:border-[#1B5888]"
                  />
                </div>
              </div>

              <div>
                <label className="text-xs font-bold text-[#4A4A4A] block mb-1">
                  {t("demo_gatekeeper_field_email")} *
                </label>
                <div className="relative">
                  <Mail className="w-4 h-4 text-[#8A8A8A] absolute left-3 top-1/2 -translate-y-1/2" />
                  <input
                    type="email"
                    required
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder="partner@stanomer.online"
                    className="w-full pl-9 pr-3 py-2 text-xs font-semibold rounded-[10px] border border-[#E5E3DF] text-[#1A1A1A] focus:outline-hidden focus:border-[#1B5888]"
                  />
                </div>
              </div>

              <div>
                <label className="text-xs font-bold text-[#4A4A4A] block mb-1">
                  {t("demo_gatekeeper_field_phone")} *
                </label>
                <div className="relative">
                  <Phone className="w-4 h-4 text-[#8A8A8A] absolute left-3 top-1/2 -translate-y-1/2" />
                  <input
                    type="tel"
                    required
                    value={phone}
                    onChange={(e) => setPhone(e.target.value)}
                    placeholder="+381 60 123 4567"
                    className="w-full pl-9 pr-3 py-2 text-xs font-semibold rounded-[10px] border border-[#E5E3DF] text-[#1A1A1A] focus:outline-hidden focus:border-[#1B5888]"
                  />
                </div>
              </div>
            </div>

            <div className="pt-2 flex items-center justify-end gap-2.5">
              <button
                type="button"
                onClick={onClose}
                className="py-2.5 px-4 rounded-[10px] border border-[#E5E3DF] text-xs font-bold text-[#4A4A4A] hover:bg-[#F8F7F5] transition-colors cursor-pointer"
              >
                {t("cancel")}
              </button>
              <button
                type="submit"
                disabled={loading}
                className="py-2.5 px-5 rounded-[10px] bg-[#1B5888] hover:bg-[#12406A] active:bg-[#12406A] text-white text-xs font-bold transition-colors flex items-center gap-2 cursor-pointer disabled:opacity-60 shadow-xs"
              >
                {loading ? (
                  <>
                    <Loader2 className="w-4 h-4 animate-spin" />
                    <span>{t("demo_gatekeeper_sending")}</span>
                  </>
                ) : (
                  <>
                    <span>{t("demo_gatekeeper_btn_send")}</span>
                    <ArrowRight className="w-3.5 h-3.5" />
                  </>
                )}
              </button>
            </div>
          </form>
        )}
        </div>
      </div>
    </div>
  );
}
