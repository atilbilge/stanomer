"use client";

import { useState, useEffect } from "react";
import Link from "next/link";
import { Navbar } from "../../components/Navbar";
import { useLanguage } from "../../components/LanguageProvider";
import { captureUtmParams, getStoredUtmParams } from "../../lib/utm";

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

  useEffect(() => {
    captureUtmParams();
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    try {
      const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || "https://thvbpifahvasyzmngpzp.supabase.co";
      const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRodmJwaWZhaHZhc3l6bW5ncHpwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODUyNjAxNzcsImV4cCI6MjEwMDgzNjE3N30.dNSz66kJcoSjflgCCrS7qw55efuDxF61TEMoYc3r4qU";

      const utm = getStoredUtmParams();

      const payload: Record<string, any> = {
        agency_name: formData.agencyName,
        email: formData.email.toLowerCase().trim(),
        website: formData.website
          ? (/^https?:\/\//i.test(formData.website.trim())
              ? formData.website.trim()
              : `https://${formData.website.trim()}`)
          : null,
        phone_number: formData.phoneNumber || null,
        special_requests: formData.specialRequests || null,
        status: "pending",
      };

      if (utm.utm_source) payload.utm_source = utm.utm_source;
      if (utm.utm_medium) payload.utm_medium = utm.utm_medium;
      if (utm.utm_campaign) payload.utm_campaign = utm.utm_campaign;

      const res = await fetch(`${supabaseUrl}/rest/v1/agency_demo_requests`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "apikey": supabaseKey,
          "Authorization": `Bearer ${supabaseKey}`,
          "Prefer": "return=representation"
        },
        body: JSON.stringify(payload)
      });

      if (res.ok || res.status === 201) {
        const data = await res.json();
        const token = Array.isArray(data) && data.length > 0 ? data[0].verification_token : null;
        if (token) {
          setVerificationToken(token);
          // Send Brevo transactional email directly from client (Static export compatible)
          try {
            const emailTranslations: Record<string, { subject: string; greeting: string; text: string; btn: string; fallback: string; footer: string }> = {
              TR: {
                subject: "Stanomer Acente Demo Talebi - E-posta Doğrulama",
                greeting: "Sayın",
                text: "Stanomer Emlak Ofisi paneli için yaptığınız demo başvurusunu aldık. Başvurunuzu tamamlamak ve hesabınızı aktifleştirmek için lütfen aşağıdaki butona tıklayarak e-posta adresinizi doğrulayınız:",
                btn: "E-posta Adresimi Doğrula",
                fallback: "Buton çalışmıyorsa aşağıdaki bağlantıyı tarayıcınıza kopyalayabilirsiniz:",
                footer: "Tüm hakları saklıdır. Bu e-posta otomatik olarak gönderilmiştir."
              },
              EN: {
                subject: "Stanomer Agency Demo Request - Email Verification",
                greeting: "Dear",
                text: "We have received your demo request for the Stanomer Real Estate Agency Panel. To complete your request and activate your account, please click the button below to verify your email address:",
                btn: "Verify My Email",
                fallback: "If the button above does not work, copy and paste the following link into your browser:",
                footer: "All rights reserved. This email was sent automatically."
              },
              SR_LAT: {
                subject: "Stanomer Zahtev za Demo Agencije - Potvrda Imejla",
                greeting: "Poštovani",
                text: "Primili smo vaš zahtev za demo verziju agencijskog panela Stanomer. Da biste završili zahtev i aktivirali nalog, molimo kliknite na dugme ispod kako biste potvrdili vašu imejl adresu:",
                btn: "Potvrdi Moj Imejl",
                fallback: "Ako dugme ne radi, kopirajte sledeći link u vaš pregledač:",
                footer: "Sva prava zadržana. Ovaj imejl je automatski poslat."
              },
              SR_CYR: {
                subject: "Stanomer Захтев за Демо Агенције - Потврда Имејла",
                greeting: "Поштовани",
                text: "Примили смо ваш захтев за демо верзију агенцијског панела Станомер. Да бисте завршили захтев и активирали налог, молимо кликните на дугме испод како бисте потврдили вашу имејл адресу:",
                btn: "Потврди Мој Имејл",
                fallback: "Ако дугме не ради, копирајте следећи линк у ваш прегледач:",
                footer: "Сва права задржана. Овај имејл је аутоматски послат."
              },
              RU: {
                subject: "Stanomer Запрос Демо-версии - Подтверждение Email",
                greeting: "Уважаемый(ая)",
                text: "Мы получили ваш запрос на демо-версию панели Stanomer для агентств недвижимости. Чтобы завершить запрос и активировать аккаунт, пожалуйста, нажмите кнопку ниже для подтверждения вашей электронной почты:",
                btn: "Подтвердить Мой Email",
                fallback: "Если кнопка не работает, скопируйте следующую ссылку в браузер:",
                footer: "Все права защищены. Это письмо отправлено автоматически."
              }
            };

            const selectedLang = (lang && emailTranslations[lang]) ? lang : "TR";
            const tEmail = emailTranslations[selectedLang];

            const apiKey = process.env.NEXT_PUBLIC_BREVO_API_KEY || "";
            const senderEmail = process.env.NEXT_PUBLIC_BREVO_SENDER_EMAIL || "atilbilge@gmail.com";
            const senderName = process.env.NEXT_PUBLIC_BREVO_SENDER_NAME || "Stanomer";

            const verifyUrl = `${window.location.origin}/agency-demo/verify?token=${token}`;

            const htmlContent = `
              <!DOCTYPE html>
              <html>
              <head>
                <meta charset="utf-8">
                <title>Stanomer - Email Verification</title>
                <style>
                  body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f8fafc; color: #1e293b; margin: 0; padding: 0; }
                  .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1); border: 1px solid #e2e8f0; }
                  .header { background-color: #2563eb; padding: 32px; text-align: center; color: #ffffff; }
                  .header h1 { margin: 0; font-size: 28px; font-weight: 800; letter-spacing: -0.5px; }
                  .content { padding: 40px 32px; text-align: center; }
                  .content h2 { font-size: 22px; color: #0f172a; margin-top: 0; }
                  .content p { font-size: 16px; line-height: 1.6; color: #475569; margin-bottom: 28px; }
                  .btn { display: inline-block; background-color: #2563eb; color: #ffffff !important; font-weight: 700; font-size: 16px; padding: 14px 32px; border-radius: 12px; text-decoration: none; transition: background-color 0.2s; }
                  .btn:hover { background-color: #1d4ed8; }
                  .footer { background-color: #f1f5f9; padding: 20px 32px; text-align: center; font-size: 13px; color: #94a3b8; border-top: 1px solid #e2e8f0; }
                  .link-box { margin-top: 24px; padding: 12px; background: #f8fafc; border: 1px solid #cbd5e1; border-radius: 8px; word-break: break-all; font-size: 12px; color: #64748b; }
                </style>
              </head>
              <body>
                <div class="container">
                  <div class="header">
                    <h1>Stanomer</h1>
                  </div>
                  <div class="content">
                    <h2>${tEmail.subject}</h2>
                    <p>${tEmail.greeting} <strong>${formData.agencyName.trim() || "Agency"}</strong>,</p>
                    <p>${tEmail.text}</p>
                    
                    <a href="${verifyUrl}" target="_blank" class="btn">${tEmail.btn}</a>

                    <div class="link-box">
                      ${tEmail.fallback}<br>
                      <a href="${verifyUrl}" style="color: #2563eb;">${verifyUrl}</a>
                    </div>
                  </div>
                  <div class="footer">
                    &copy; 2026 Stanomer. ${tEmail.footer}
                  </div>
                </div>
              </body>
              </html>
            `;

            await fetch("https://api.brevo.com/v3/smtp/email", {
              method: "POST",
              headers: {
                "accept": "application/json",
                "content-type": "application/json",
                "api-key": apiKey
              },
              body: JSON.stringify({
                sender: { name: senderName, email: senderEmail },
                to: [{ email: formData.email.toLowerCase().trim(), name: formData.agencyName.trim() || formData.email }],
                subject: tEmail.subject,
                htmlContent: htmlContent
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
