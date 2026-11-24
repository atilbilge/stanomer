"use client";

import { useEffect, useState, Suspense } from "react";
import { useSearchParams } from "next/navigation";
import Link from "next/link";
import { Navbar } from "../../../components/Navbar";
import { useLanguage } from "../../../components/LanguageProvider";
import { Sparkles, ArrowRight, RefreshCw, AlertTriangle, CheckCircle2 } from "lucide-react";
import { AgencyDemoModal } from "../../../components/AgencyDemoModal";
import { supabase } from "../../../lib/supabaseClient";

function VerificationContent() {
  const { lang, t, setLang } = useLanguage();
  const searchParams = useSearchParams();
  const token = searchParams.get("token");
  const rawUrlLang = searchParams.get("lang") || searchParams.get("locale");
  const editSite = searchParams.get("edit_site");

  const [loading, setLoading] = useState(true);
  const [success, setSuccess] = useState(false);
  const [wasExpired, setWasExpired] = useState(false);
  const [agencyName, setAgencyName] = useState<string | null>(null);
  const [targetUrl, setTargetUrl] = useState<string>("/dev-app/");
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [isDemoModalOpen, setIsDemoModalOpen] = useState(false);

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
        const supabaseUrl = "https://nbcbfmhztnnhfnapvaet.supabase.co";
        const supabaseKey =
          "sb_publishable_kY2aoizXZkGz2DsG6-sg-Q_Vm2Ef2mq";

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
          if (data.was_expired) {
            setWasExpired(true);
          }

          // 2. Perform browser authentication with Supabase SDK (guarantees valid session storage & JWT)
          if (data.email && data.temp_password) {
            try {
              const { error: signInErr } = await supabase.auth.signInWithPassword({
                email: data.email,
                password: data.temp_password,
              });
              if (signInErr) {
                console.warn("Supabase signInWithPassword error:", signInErr);
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
            } catch (_) { }
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
                    // Trigger scraper API (Site HTML -> Brandfetch -> Google Favicon)
                    fetch("/api/scrape-agency-theme", {
                      method: "POST",
                      headers: { "Content-Type": "application/json" },
                      body: JSON.stringify({
                        url: siteUrl.trim(),
                        agency_id: data.user_id,
                      }),
                    }).catch(() => {
                      // Fallback: direct Google favicon with www normalization
                      try {
                        let cleanUrl = siteUrl.trim();
                        if (!/^https?:\/\//i.test(cleanUrl)) cleanUrl = "https://" + cleanUrl;
                        let domain = new URL(cleanUrl).hostname;
                        if (domain.includes(".") && !domain.startsWith("www.")) domain = `www.${domain}`;
                        const faviconUrl = `https://images.weserv.nl/?url=www.google.com/s2/favicons?domain=${encodeURIComponent(domain)}%26sz=128`;
                        fetch(`${supabaseUrl}/rest/v1/profiles?id=eq.${data.user_id}`, {
                          method: "PATCH",
                          headers: {
                            "Content-Type": "application/json",
                            apikey: supabaseKey,
                            Authorization: `Bearer ${supabaseKey}`,
                          },
                          body: JSON.stringify({
                            logo_url: faviconUrl,
                            updated_at: new Date().toISOString(),
                          }),
                        }).catch(() => { });
                      } catch (_) { }
                    });
                  }
                })
                .catch(() => { });
            } catch (_) { }
          }

          // 3. Store verified status in localStorage for /agency-panel
          if (typeof window !== "undefined") {
            try {
              const currentDemo = localStorage.getItem("stanomer_agency_demo");
              let parsedDemo = currentDemo ? JSON.parse(currentDemo) : {};
              localStorage.setItem(
                "stanomer_agency_demo",
                JSON.stringify({
                  ...parsedDemo,
                  token: token,
                  agencyName: data.agency_name || parsedDemo.agencyName || "Agency",
                  email: data.email || parsedDemo.email,
                  userId: data.user_id,
                  isVerified: true,
                  expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
                })
              );
            } catch (_) { }
          }

          // 4. Target URL for the Next.js Agency Panel with token and language
          let appUrl = `/agency-panel?verified_demo=1&demo_token=${encodeURIComponent(token)}&lang=${encodeURIComponent(activeLang)}`;
          setTargetUrl(appUrl);

          // 5. Auto-redirect to the agency panel
          setTimeout(() => {
            if (typeof window !== "undefined") {
              window.location.href = appUrl;
            }
          }, 1200);
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
          <div className="bg-white py-10 px-6 shadow-md rounded-3xl sm:px-10 border border-slate-100 text-center">
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
                  <h3 className="text-2xl font-semibold text-slate-900">
                    {isTR ? "Giriş Yapıldı! Panelinize Aktarılıyorsunuz..." : isSR ? "Prijavljeni ste! Panel se otvara..." : "Connected! Opening Your Panel..."}
                  </h3>
                  {wasExpired && (
                    <div className="mt-3 inline-flex items-center gap-2 px-4 py-2 rounded-full bg-amber-50 text-amber-800 text-xs font-bold border border-amber-200 shadow-sm animate-in fade-in duration-300">
                      <span>
                        {isTR
                          ? "Demo erişim süreniz 7 gün daha uzatıldı ve portföyünüz hazırlandı."
                          : isSR
                            ? "Vaš pristup demou je produžen za još 7 dana i portfolio je pripremljen."
                            : "Your demo access has been renewed for 7 days and your portfolio is ready."}
                      </span>
                    </div>
                  )}
                  <p className="text-slate-600 text-xs sm:text-sm mt-2 leading-relaxed max-w-md mx-auto">
                    {isTR
                      ? "Acenteniz için 7 günlük sandbox ortamınız başarıyla açıldı. Birkaç saniye içinde doğrudan kokpitinize yönlendirileceksiniz."
                      : isSR
                        ? "Vaš 7-dnevni sandbox nalog je uspešno aktiviran. Za nekoliko sekundi bićete automatski prebačeni u panel."
                        : "Your 7-day agency sandbox has been activated. You will be redirected to your dashboard in a few seconds."}
                  </p>
                </div>

                {/* Direct Action Button */}
                <div className="pt-2">
                  <a
                    href={targetUrl}
                    className="w-full inline-flex justify-center items-center gap-3 px-8 py-4 rounded-2xl text-white bg-blue-600 hover:from-blue-700 hover:to-indigo-700 font-semibold text-sm sm:text-base shadow-md shadow-blue-500/30 transform hover:scale-[1.02] active:scale-[0.98] transition cursor-pointer"
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
                  <h3 className="text-2xl font-semibold text-slate-900">
                    {isTR ? "Test Datanız Silindi veya Süresi Doldu" : isSR ? "Test podaci su obrisani ili je link istekao" : "Test Data Expired or Cleared"}
                  </h3>
                  <p className="text-slate-600 text-sm mt-2 leading-relaxed max-w-md mx-auto">
                    {errorMessage ||
                      (isTR
                        ? "7 günlük deneme süreniz sona erdiği için sandbox verileriniz güvenlik gereği silinmiştir. Dilediğiniz an tek tıkla yeni bir test portföyü oluşturabilirsiniz."
                        : isSR
                          ? "Vaš 7-dnevni test period je istekao i podaci su obrisani. Možete u bilo kom trenutku ponovo kreirati novi primer portfolija."
                          : "Your 7-day trial period has ended and test data was cleared. You can recreate a fresh sample portfolio anytime.")}
                  </p>
                </div>

                <div className="pt-2 flex flex-col sm:flex-row justify-center gap-3">
                  <button
                    type="button"
                    onClick={() => setIsDemoModalOpen(true)}
                    className="inline-flex justify-center items-center gap-2 px-7 py-3.5 rounded-xl text-white bg-blue-600 hover:bg-blue-700 font-bold text-sm shadow-lg shadow-blue-500/25 transition cursor-pointer"
                  >
                    <RefreshCw className="w-4 h-4" />
                    <span>{isTR ? "Yeni Demo Talebi Gönder" : isSR ? "Zatražite Novi Demo" : "Request New Demo Access"}</span>
                  </button>
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

      <AgencyDemoModal
        isOpen={isDemoModalOpen}
        onClose={() => setIsDemoModalOpen(false)}
        defaultAgencyName={agencyName || ""}
      />
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
