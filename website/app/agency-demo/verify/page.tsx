"use client";

import { useEffect, useState, Suspense } from "react";
import { useSearchParams } from "next/navigation";
import Link from "next/link";
import { Navbar } from "../../../components/Navbar";
import { useLanguage } from "../../../components/LanguageProvider";

function VerificationContent() {
  const { t } = useLanguage();
  const searchParams = useSearchParams();
  const token = searchParams.get("token");

  const [loading, setLoading] = useState(true);
  const [success, setSuccess] = useState(false);
  const [alreadyVerified, setAlreadyVerified] = useState(false);
  const [message, setMessage] = useState<string | null>(null);

  useEffect(() => {
    if (!token) {
      setLoading(false);
      setMessage(t("agency_demo_error_msg"));
      return;
    }

    const verifyToken = async () => {
      try {
        const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || "https://ustcsvvkzsmsgzbptvpm.supabase.co";
        const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVzdGNzdnZrenNtc2d6YnB0dnBtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUzMzY1NjIsImV4cCI6MjA5MDkxMjU2Mn0.g1A1GfLrebJ3MnQUaCmr45JGPPAPLU77XtUKP6doA4g";

        const res = await fetch(`${supabaseUrl}/rest/v1/rpc/verify_agency_demo_token`, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "apikey": supabaseKey,
            "Authorization": `Bearer ${supabaseKey}`
          },
          body: JSON.stringify({
            p_token: token
          })
        });

        const data = await res.json();

        if (res.ok && data?.success) {
          setSuccess(true);
          if (data.already_verified) {
            setAlreadyVerified(true);
          }
          setMessage(data.message || t("agency_demo_verified_desc"));
        } else {
          setSuccess(false);
          setMessage(data?.message || t("agency_demo_verify_failed"));
        }
      } catch (err) {
        setSuccess(false);
        setMessage(t("agency_demo_error_msg"));
      } finally {
        setLoading(false);
      }
    };

    verifyToken();
  }, [token]);

  return (
    <div className="min-h-screen bg-slate-50 flex flex-col justify-between font-sans">
      <Navbar />

      <div className="pt-28 pb-12 flex-grow flex flex-col justify-center sm:px-6 lg:px-8">
        <div className="sm:mx-auto sm:w-full sm:max-w-md text-center">
          <h2 className="text-3xl font-extrabold text-slate-900">
            {t("agency_demo_verify_page_title")}
          </h2>
        </div>

        <div className="mt-8 sm:mx-auto sm:w-full sm:max-w-lg">
          <div className="bg-white py-8 px-6 shadow-xl rounded-2xl sm:px-10 border border-slate-100 text-center">
            {loading ? (
              <div className="py-12">
                <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto mb-4"></div>
                <p className="text-slate-600 font-medium">{t("agency_demo_verifying")}</p>
              </div>
            ) : success ? (
              <div className="py-6">
                <div className="mx-auto flex items-center justify-center h-16 w-16 rounded-full bg-emerald-100 mb-6">
                  <svg className="h-8 w-8 text-emerald-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                  </svg>
                </div>
                <h3 className="text-2xl font-bold text-slate-900 mb-4">
                  {alreadyVerified ? t("agency_demo_already_verified") : t("agency_demo_verified_success")}
                </h3>
                <p className="text-slate-600 mb-8 text-base leading-relaxed max-w-md mx-auto">
                  {alreadyVerified ? t("agency_demo_already_verified_desc") : t("agency_demo_verified_desc")}
                </p>
                <Link
                  href="/"
                  className="inline-flex justify-center items-center px-6 py-3 border border-transparent text-base font-medium rounded-xl text-white bg-blue-600 hover:bg-blue-700 transition"
                >
                  {t("agency_demo_back_home")}
                </Link>
              </div>
            ) : (
              <div className="py-6">
                <div className="mx-auto flex items-center justify-center h-16 w-16 rounded-full bg-red-100 mb-6">
                  <svg className="h-8 w-8 text-red-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </div>
                <h3 className="text-2xl font-bold text-slate-900 mb-2">{t("agency_demo_verify_failed")}</h3>
                <p className="text-slate-600 mb-6 leading-relaxed">
                  {message}
                </p>
                <div className="flex flex-col sm:flex-row justify-center gap-4">
                  <Link
                    href="/agency-demo"
                    className="inline-flex justify-center items-center px-6 py-3 border border-transparent text-base font-medium rounded-xl text-white bg-blue-600 hover:bg-blue-700 transition"
                  >
                    {t("agency_demo_recreate_btn")}
                  </Link>
                  <Link
                    href="/"
                    className="inline-flex justify-center items-center px-6 py-3 border border-slate-300 text-base font-medium rounded-xl text-slate-700 bg-white hover:bg-slate-50 transition"
                  >
                    {t("agency_demo_back_home")}
                  </Link>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

export default function VerifyPage() {
  return (
    <Suspense fallback={
      <div className="min-h-screen bg-slate-50 flex items-center justify-center">
        <p className="text-slate-600 font-medium">Yükleniyor...</p>
      </div>
    }>
      <VerificationContent />
    </Suspense>
  );
}
