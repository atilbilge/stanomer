"use client";

import { useEffect, useState, Suspense } from "react";
import { useSearchParams } from "next/navigation";
import Link from "next/link";
import { Navbar } from "../../../components/Navbar";
import { useLanguage } from "../../../components/LanguageProvider";
import { Sparkles, ArrowRight, RefreshCw, AlertTriangle, CheckCircle2 } from "lucide-react";

function VerificationContent() {
  const { lang, t, setLang } = useLanguage();
  const searchParams = useSearchParams();
  const token = searchParams.get("token");
  const rawUrlLang = searchParams.get("lang") || searchParams.get("locale");

  const [loading, setLoading] = useState(true);
  const [success, setSuccess] = useState(false);
  const [agencyName, setAgencyName] = useState<string | null>(null);
  const [targetUrl, setTargetUrl] = useState<string>("/dev-app/");
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  // Synchronize language from URL if present
  useEffect(() => {
    if (rawUrlLang) {
      let clean = rawUrlLang.toUpperCase().replace("-", "_");
      if (clean === "SR" || clean === "RS" || clean === "SRB") clean = "SR_LAT";
      if (["TR", "EN", "SR_LAT", "SR_CYR", "RU"].includes(clean)) {
        setLang(clean as any);
      }
    }
  }, [rawUrlLang, setLang]);

  // Determine active language and Flutter locale
  let activeLang = "SR_LAT";
  if (rawUrlLang) {
    let clean = rawUrlLang.toUpperCase().replace("-", "_");
    if (clean === "SR" || clean === "RS" || clean === "SRB") clean = "SR_LAT";
    if (["TR", "EN", "SR_LAT", "SR_CYR", "RU"].includes(clean)) activeLang = clean;
  } else if (lang) {
    activeLang = lang;
  }

  let flutterLocale = "sr_Latn";
  if (activeLang === "TR") flutterLocale = "tr";
  else if (activeLang === "EN") flutterLocale = "en";
  else if (activeLang === "RU") flutterLocale = "ru";
  else if (activeLang === "SR_CYR") flutterLocale = "sr_Cyrl";
  else if (activeLang === "SR_LAT") flutterLocale = "sr_Latn";

  const isTR = activeLang === "TR";
  const isSR = activeLang === "SR_LAT" || activeLang === "SR_CYR";

  useEffect(() => {
    if (!token) {
      setLoading(false);
      setErrorMessage(
        isTR
          ? "Geçersiz veya eksik demo bağlantısı."
          : isSR
          ? "Nevažeći ili nepotpun link za demo nalog."
          : "Invalid or missing demo access link."
      );
      return;
    }

    const verifyAndLogin = async () => {
      try {
        const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || "https://thvbpifahvasyzmngpzp.supabase.co";
        const supabaseKey =
          process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ||
          "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRodmJwaWZhaHZhc3l6bW5ncHpwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODUyNjAxNzcsImV4cCI6MjEwMDgzNjE3N30.dNSz66kJcoSjflgCCrS7qw55efuDxF61TEMoYc3r4qU";

        // 1. Verify demo token and provision agency sandbox user on Dev Supabase
        const res = await fetch(`${supabaseUrl}/rest/v1/rpc/verify_agency_demo_token`, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            apikey: supabaseKey,
            Authorization: `Bearer ${supabaseKey}`,
          },
          body: JSON.stringify({
            p_token: token,
          }),
        });

        const data = await res.json();

        if (res.ok && data?.success) {
          setSuccess(true);
          setAgencyName(data.agency_name || null);

          // 2. Perform browser authentication with Supabase
          if (data.email && data.temp_password) {
            try {
              const authRes = await fetch(`${supabaseUrl}/auth/v1/token?grant_type=password`, {
                method: "POST",
                headers: {
                  "Content-Type": "application/json",
                  apikey: supabaseKey,
                },
                body: JSON.stringify({
                  email: data.email,
                  password: data.temp_password,
                }),
              });

              if (authRes.ok) {
                const sessionData = await authRes.json();
                if (typeof window !== "undefined") {
                  try {
                    const hostRef = new URL(supabaseUrl).hostname.split(".")[0];
                    localStorage.setItem(`sb-${hostRef}-auth-token`, JSON.stringify(sessionData));
                  } catch (_) {}
                }
              }
            } catch (authErr) {
              console.warn("Direct session initialization note:", authErr);
            }
          }

          // 2.2 Store Flutter app locale and stanomer website lang
          if (typeof window !== "undefined") {
            try {
              localStorage.setItem("flutter.app_locale", flutterLocale);
              localStorage.setItem("stanomer_lang", activeLang);
            } catch (_) {}
          }

          // 2.5 Auto-trigger agency theme & logo scraping if website is configured
          if (data.user_id) {
            try {
              fetch(`${supabaseUrl}/rest/v1/profiles?id=eq.${data.user_id}&select=website_url`, {
                headers: {
                  apikey: supabaseKey,
                  Authorization: `Bearer ${supabaseKey}`,
                },
              })
                .then((r) => r.json())
                .then((rows) => {
                  const siteUrl = rows?.[0]?.website_url;
                  if (siteUrl && typeof siteUrl === "string" && siteUrl.trim()) {
                    fetch("/api/scrape-agency-theme", {
                      method: "POST",
                      headers: { "Content-Type": "application/json" },
                      body: JSON.stringify({
                        url: siteUrl.trim(),
                        agency_id: data.user_id,
                      }),
                    }).catch(() => {});
                  }
                })
                .catch(() => {});
            } catch (_) {}
          }

          // 3. Target URL for the Flutter Dev App with token and language
          const appUrl = `/dev-app?demo_token=${encodeURIComponent(token)}&lang=${encodeURIComponent(flutterLocale)}`;
          setTargetUrl(appUrl);

          // 4. Auto-redirect to the dev app so user doesn't have to do anything
          setTimeout(() => {
            if (typeof window !== "undefined") {
              window.location.href = appUrl;
            }
          }, 1400);
        } else {
          setSuccess(false);
          setErrorMessage(
            data?.message ||
              (isTR
                ? "Test datanız silindi veya süresi doldu."
                : isSR
                ? "Vaši test podaci su obrisani ili je link istekao."
                : "Your test data has expired or was cleared.")
          );
        }
      } catch (err: any) {
        setSuccess(false);
        setErrorMessage(
          isTR
            ? "Giriş yapılırken bir sorun oluştu. Lütfen bağlantınızı kontrol ediniz."
            : isSR
            ? "Došlo je do greške prilikom prijave. Proverite vašu internet vezu."
            : "An error occurred while connecting to your demo. Please check your connection."
        );
      } finally {
        setLoading(false);
      }
    };

    verifyAndLogin();
  }, [token]);

  return (
    <div className="min-h-screen bg-slate-50 flex flex-col justify-between font-sans">
      <Navbar />

      <div className="pt-28 pb-12 flex-grow flex flex-col justify-center sm:px-6 lg:px-8">
        <div className="mt-8 sm:mx-auto sm:w-full sm:max-w-lg px-4">
          <div className="bg-white py-10 px-6 shadow-2xl rounded-3xl sm:px-10 border border-slate-100 text-center">
            {loading ? (
              <div className="py-12 space-y-4">
                <div className="relative mx-auto w-16 h-16">
                  <div className="animate-spin rounded-full h-16 w-16 border-4 border-blue-600 border-t-transparent"></div>
                  <div className="absolute inset-0 flex items-center justify-center">
                    <Sparkles className="w-6 h-6 text-blue-600" />
                  </div>
                </div>
                <h3 className="text-xl font-bold text-slate-900">
                  {isTR ? "Acente Kokpitiniz Hazırlanıyor..." : isSR ? "Otvaranje Agencijskog Panela..." : "Preparing Your Agency Cockpit..."}
                </h3>
                <p className="text-slate-500 text-sm">
                  {isTR ? "Tek tıkla güvenli giriş yapılıyor..." : isSR ? "Povezivanje jednim klikom..." : "Connecting via magic link..."}
                </p>
              </div>
            ) : success ? (
              <div className="py-4 space-y-6">
                <div className="mx-auto flex items-center justify-center h-20 w-20 rounded-full bg-emerald-100 ring-8 ring-emerald-50 text-emerald-600 animate-in zoom-in-75 duration-300">
                  <CheckCircle2 className="h-10 w-10" />
                </div>

                <div>
                  <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-blue-50 text-blue-700 text-xs font-bold mb-3 border border-blue-100">
                    <Sparkles className="w-3.5 h-3.5 text-amber-500" />
                    <span>{agencyName ? `${agencyName} Demo Sandbox` : "Stanomer Agency Sandbox"}</span>
                  </div>
                  <h3 className="text-2xl font-black text-slate-900">
                    {isTR ? "Giriş Yapıldı! Panelinize Aktarılıyorsunuz..." : isSR ? "Prijavljeni ste! Panel se otvara..." : "Connected! Opening Your Panel..."}
                  </h3>
                  <p className="text-slate-600 text-xs sm:text-sm mt-2 leading-relaxed max-w-md mx-auto">
                    {isTR
                      ? "Acenteniz için 3 günlük sandbox ortamınız başarıyla açıldı. Birkaç saniye içinde doğrudan kokpitinize yönlendirileceksiniz."
                      : isSR
                      ? "Vaš 3-dnevni sandbox nalog je uspešno aktiviran. Za nekoliko sekundi bićete automatski prebačeni u panel."
                      : "Your 3-day agency sandbox has been activated. You will be redirected to your dashboard in a few seconds."}
                  </p>
                </div>

                {/* Direct Action Button */}
                <div className="pt-2">
                  <a
                    href={targetUrl}
                    className="w-full inline-flex justify-center items-center gap-3 px-8 py-4 rounded-2xl text-white bg-gradient-to-r from-blue-600 via-indigo-600 to-blue-700 hover:from-blue-700 hover:to-indigo-700 font-black text-sm sm:text-base shadow-xl shadow-blue-500/30 transform hover:scale-[1.02] active:scale-[0.98] transition cursor-pointer"
                  >
                    <span>{isTR ? "Acente Panelini Aç (Doğrudan Bağlan)" : isSR ? "Otvorite Agencijski Panel" : "Launch Agency Panel Now"}</span>
                    <ArrowRight className="w-5 h-5" />
                  </a>
                </div>

                {/* Sandbox Features Tip */}
                <div className="p-4 bg-slate-50 rounded-2xl border border-slate-200/80 text-left space-y-1.5 text-xs text-slate-600">
                  <p className="font-bold text-slate-800 flex items-center gap-1.5">
                    <span>💡</span>
                    <span>{isTR ? "Panelde Sizi Neler Bekliyor?" : isSR ? "Šta vas čeka u panelu?" : "What to do next?"}</span>
                  </p>
                  <p className="leading-relaxed">
                    {isTR
                      ? "Panel açıldığında üstteki asistan çubuğundan 'Temayı Al' ile web sitenizden logonuzu ve kurumsal renklerinizi çekebilir; 'Örnek Portföy Üret' ile anında 5 mülk, ev sahipleri ve kiracılardan oluşan canlı portföyü test edebilirsiniz."
                      : isSR
                      ? "Kada se panel otvori, kliknite na 'Preuzmi temu' da automatski povučete vaš logo i boje, ili 'Generiši primer portfolija' za trenutni test sa 5 nekretnina, vlasnicima i zakupcima."
                      : "Once in the dashboard, use 'Fetch Theme' to automatically load your agency logo and colors, and 'Generate Sample Portfolio' to test 5 realistic properties with active tenants and owners."}
                  </p>
                </div>
              </div>
            ) : (
              <div className="py-6 space-y-6">
                <div className="mx-auto flex items-center justify-center h-20 w-20 rounded-full bg-amber-100 ring-8 ring-amber-50 text-amber-600">
                  <AlertTriangle className="h-10 w-10" />
                </div>

                <div>
                  <h3 className="text-2xl font-black text-slate-900">
                    {isTR ? "Test Datanız Silindi veya Süresi Doldu" : isSR ? "Test podaci su obrisani ili je link istekao" : "Test Data Expired or Cleared"}
                  </h3>
                  <p className="text-slate-600 text-sm mt-2 leading-relaxed max-w-md mx-auto">
                    {errorMessage ||
                      (isTR
                        ? "3 günlük deneme süreniz sona erdiği için sandbox verileriniz güvenlik gereği silinmiştir. Dilediğiniz an tek tıkla yeni bir test portföyü oluşturabilirsiniz."
                        : isSR
                        ? "Vaš 3-dnevni test period je istekao i podaci su obrisani. Možete u bilo kom trenutku ponovo kreirati novi primer portfolija."
                        : "Your 3-day trial period has ended and test data was cleared. You can recreate a fresh sample portfolio anytime.")}
                  </p>
                </div>

                <div className="pt-2 flex flex-col sm:flex-row justify-center gap-3">
                  <Link
                    href="/agencies"
                    className="inline-flex justify-center items-center gap-2 px-7 py-3.5 rounded-xl text-white bg-blue-600 hover:bg-blue-700 font-bold text-sm shadow-lg shadow-blue-500/25 transition"
                  >
                    <RefreshCw className="w-4 h-4" />
                    <span>{isTR ? "Yeniden Test Portföyü Oluştur" : isSR ? "Kreirajte Novi Test Portfolio" : "Recreate Sample Portfolio"}</span>
                  </Link>
                  <Link
                    href="/"
                    className="inline-flex justify-center items-center px-5 py-3.5 border border-slate-200 text-sm font-semibold rounded-xl text-slate-700 bg-white hover:bg-slate-50 transition"
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
    <Suspense
      fallback={
        <div className="min-h-screen bg-slate-50 flex items-center justify-center">
          <p className="text-slate-600 font-medium">Yükleniyor...</p>
        </div>
      }
    >
      <VerificationContent />
    </Suspense>
  );
}
