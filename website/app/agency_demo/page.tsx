"use client";

import { useState } from "react";
import Link from "next/link";
import { Navbar } from "../../components/Navbar";
import { useLanguage } from "../../components/LanguageProvider";

export default function AgencyDemoPage() {
  const { lang, t } = useLanguage();

  const [formData, setFormData] = useState({
    agencyName: "",
    email: "",
    website: "",
    phoneNumber: "",
    specialRequests: "",
  });

  const [loading, setLoading] = useState(false);
  const [submitted, setSubmitted] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const [verificationToken, setVerificationToken] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    try {
      const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || "https://thvbpifahvasyzmngpzp.supabase.co";
      const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRodmJwaWZhaHZhc3l6bW5ncHpwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODUyNjAxNzcsImV4cCI6MjEwMDgzNjE3N30.dNSz66kJcoSjflgCCrS7qw55efuDxF61TEMoYc3r4qU";

      const res = await fetch(`${supabaseUrl}/rest/v1/agency_demo_requests`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "apikey": supabaseKey,
          "Authorization": `Bearer ${supabaseKey}`,
          "Prefer": "return=representation"
        },
        body: JSON.stringify({
          agency_name: formData.agencyName,
          email: formData.email.toLowerCase().trim(),
          website: formData.website
            ? (/^https?:\/\//i.test(formData.website.trim())
                ? formData.website.trim()
                : `https://${formData.website.trim()}`)
            : null,
          phone_number: formData.phoneNumber || null,
          special_requests: formData.specialRequests || null,
          status: "pending"
        })
      });

      if (res.ok || res.status === 201) {
        const data = await res.json();
        const token = Array.isArray(data) && data.length > 0 ? data[0].verification_token : null;
        if (token) {
          setVerificationToken(token);
          // Trigger Brevo transactional email delivery with active language
          try {
            await fetch("/api/send-demo-verification", {
              method: "POST",
              headers: { "Content-Type": "application/json" },
              body: JSON.stringify({
                email: formData.email.toLowerCase().trim(),
                agencyName: formData.agencyName.trim(),
                verificationToken: token,
                lang: lang
              })
            });
          } catch (emailErr) {
            console.warn("E-posta gönderim tetiklemesinde hata:", emailErr);
          }
        }
        setSubmitted(true);
      } else {
        throw new Error("Form gönderilemedi.");
      }
    } catch (err: any) {
      setError(t("agency_demo_error_msg"));
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-slate-50 flex flex-col justify-between font-sans">
      <Navbar />

      <div className="pt-28 pb-12 flex-grow flex flex-col justify-center sm:px-6 lg:px-8">
        <div className="sm:mx-auto sm:w-full sm:max-w-md text-center">
          <h2 className="text-3xl font-extrabold text-slate-900">
            {t("agency_demo_title")}
          </h2>
          <p className="mt-2 text-sm text-slate-600">
            {t("agency_demo_subtitle")}
          </p>
        </div>

        <div className="mt-8 sm:mx-auto sm:w-full sm:max-w-xl">
          <div className="bg-white py-8 px-6 shadow-xl rounded-2xl sm:px-10 border border-slate-100">
            {submitted ? (
              <div className="text-center py-8">
                <div className="mx-auto flex items-center justify-center h-16 w-16 rounded-full bg-blue-100 mb-6">
                  <svg className="h-8 w-8 text-blue-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 002-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                  </svg>
                </div>
                <h3 className="text-2xl font-bold text-slate-900 mb-2">
                  {t("agency_demo_success_title")}
                </h3>
                <p className="text-slate-600 mb-6 leading-relaxed">
                  <strong className="text-slate-800">{formData.email}</strong> {t("agency_demo_success_desc")}
                </p>

                <Link
                  href="/"
                  className="inline-flex justify-center items-center px-6 py-3 border border-transparent text-base font-medium rounded-xl text-white bg-blue-600 hover:bg-blue-700 transition"
                >
                  {t("agency_demo_back_home")}
                </Link>
              </div>
            ) : (
              <form onSubmit={handleSubmit} className="space-y-6">
                {error && (
                  <div className="p-4 rounded-xl bg-red-50 text-red-700 text-sm font-medium border border-red-100">
                    {error}
                  </div>
                )}

                <div>
                  <label className="block text-sm font-semibold text-slate-700 mb-1">
                    {t("agency_demo_name")} <span className="text-red-500">*</span>
                  </label>
                  <input
                    type="text"
                    required
                    value={formData.agencyName}
                    onChange={(e) => setFormData({ ...formData, agencyName: e.target.value })}
                    placeholder={t("agency_demo_name_placeholder")}
                    className="w-full px-4 py-3 rounded-xl border border-slate-200 focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none transition"
                  />
                </div>

                <div>
                  <label className="block text-sm font-semibold text-slate-700 mb-1">
                    {t("agency_demo_email")} <span className="text-red-500">*</span>
                  </label>
                  <input
                    type="email"
                    required
                    value={formData.email}
                    onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                    placeholder={t("agency_demo_email_placeholder")}
                    className="w-full px-4 py-3 rounded-xl border border-slate-200 focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none transition"
                  />
                </div>

                <div>
                  <label className="block text-sm font-semibold text-slate-700 mb-1">
                    {t("agency_demo_website")}
                  </label>
                  <input
                    type="text"
                    value={formData.website}
                    onChange={(e) => setFormData({ ...formData, website: e.target.value })}
                    placeholder={t("agency_demo_website_placeholder")}
                    className="w-full px-4 py-3 rounded-xl border border-slate-200 focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none transition"
                  />
                </div>

                <div>
                  <label className="block text-sm font-semibold text-slate-700 mb-1">
                    {t("agency_demo_phone")}
                  </label>
                  <input
                    type="tel"
                    value={formData.phoneNumber}
                    onChange={(e) => setFormData({ ...formData, phoneNumber: e.target.value })}
                    placeholder={t("agency_demo_phone_placeholder")}
                    className="w-full px-4 py-3 rounded-xl border border-slate-200 focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none transition"
                  />
                </div>

                <div>
                  <label className="block text-sm font-semibold text-slate-700 mb-1">
                    {t("agency_demo_notes")}
                  </label>
                  <textarea
                    rows={4}
                    value={formData.specialRequests}
                    onChange={(e) => setFormData({ ...formData, specialRequests: e.target.value })}
                    placeholder={t("agency_demo_notes_placeholder")}
                    className="w-full px-4 py-3 rounded-xl border border-slate-200 focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none transition"
                  />
                </div>

                <button
                  type="submit"
                  disabled={loading}
                  className="w-full py-4 px-6 rounded-xl text-white bg-blue-600 hover:bg-blue-700 font-bold text-base shadow-lg shadow-blue-500/25 transition disabled:opacity-50"
                >
                  {loading ? t("agency_demo_submitting") : t("agency_demo_submit")}
                </button>
              </form>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
