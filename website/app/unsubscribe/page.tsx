"use client";

import { useEffect, useState } from "react";
import { useSearchParams } from "next/navigation";
import { Suspense } from "react";

type Status = "idle" | "loading" | "success" | "error";

function UnsubscribeContent() {
  const searchParams = useSearchParams();
  const email = searchParams.get("email") || "";
  const [status, setStatus] = useState<Status>("idle");
  const [message, setMessage] = useState("");

  const handleUnsubscribe = async () => {
    if (!email) return;
    setStatus("loading");
    try {
      const res = await fetch("/api/unsubscribe", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email }),
      });
      const data = await res.json();
      if (data.success) {
        setStatus("success");
      } else {
        setStatus("error");
        setMessage(data.message || "Bir hata oluştu.");
      }
    } catch {
      setStatus("error");
      setMessage("Bağlantı hatası. Lütfen tekrar deneyin.");
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 via-blue-50 to-slate-100 flex items-center justify-center p-4">
      <div className="w-full max-w-md">
        {/* Card */}
        <div className="bg-white rounded-2xl shadow-xl border border-slate-100 overflow-hidden">
          {/* Header */}
          <div className="bg-gradient-to-r from-blue-600 to-blue-700 px-8 py-6 text-center">
            <span className="text-white text-2xl font-bold tracking-tight">
              Stanomer
            </span>
          </div>

          {/* Content */}
          <div className="px-8 py-10 text-center">
            {status === "idle" && (
              <>
                {/* Icon */}
                <div className="w-16 h-16 bg-blue-50 rounded-full flex items-center justify-center mx-auto mb-6">
                  <svg
                    className="w-8 h-8 text-blue-600"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                    strokeWidth={1.5}
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      d="M21.75 6.75v10.5a2.25 2.25 0 01-2.25 2.25h-15a2.25 2.25 0 01-2.25-2.25V6.75m19.5 0A2.25 2.25 0 0019.5 4.5h-15a2.25 2.25 0 00-2.25 2.25m19.5 0v.243a2.25 2.25 0 01-1.07 1.916l-7.5 4.615a2.25 2.25 0 01-2.36 0L3.32 8.91a2.25 2.25 0 01-1.07-1.916V6.75"
                    />
                  </svg>
                </div>

                <h1 className="text-xl font-bold text-slate-800 mb-2">
                  E-posta Aboneliğini İptal Et
                </h1>
                <p className="text-slate-500 text-sm mb-6 leading-relaxed">
                  Aşağıdaki e-posta adresini tüm Stanomer bülten ve bildirim
                  listelerinden çıkarmak istediğinizi onaylıyor musunuz?
                </p>

                {email ? (
                  <div className="bg-slate-50 border border-slate-200 rounded-xl px-4 py-3 mb-8 break-all">
                    <span className="text-blue-600 font-semibold text-sm">
                      {email}
                    </span>
                  </div>
                ) : (
                  <div className="bg-red-50 border border-red-200 rounded-xl px-4 py-3 mb-8">
                    <span className="text-red-500 text-sm">
                      E-posta adresi bulunamadı.
                    </span>
                  </div>
                )}

                <button
                  onClick={handleUnsubscribe}
                  disabled={!email}
                  className="w-full bg-blue-600 hover:bg-blue-700 disabled:bg-slate-300 disabled:cursor-not-allowed text-white font-semibold py-3 px-6 rounded-xl transition-all duration-200 text-sm shadow-sm hover:shadow-md active:scale-[0.98]"
                >
                  Aboneliği İptal Et
                </button>

                <p className="text-xs text-slate-400 mt-4">
                  Bu işlem geri alınamaz. Tekrar abone olmak için
                  uygulamayı kullanabilirsiniz.
                </p>
              </>
            )}

            {status === "loading" && (
              <>
                <div className="w-16 h-16 bg-blue-50 rounded-full flex items-center justify-center mx-auto mb-6">
                  <svg
                    className="w-8 h-8 text-blue-600 animate-spin"
                    fill="none"
                    viewBox="0 0 24 24"
                  >
                    <circle
                      className="opacity-25"
                      cx="12"
                      cy="12"
                      r="10"
                      stroke="currentColor"
                      strokeWidth="4"
                    />
                    <path
                      className="opacity-75"
                      fill="currentColor"
                      d="M4 12a8 8 0 018-8v8H4z"
                    />
                  </svg>
                </div>
                <p className="text-slate-600 font-medium">İşleniyor...</p>
              </>
            )}

            {status === "success" && (
              <>
                <div className="w-16 h-16 bg-green-50 rounded-full flex items-center justify-center mx-auto mb-6">
                  <svg
                    className="w-8 h-8 text-green-500"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                    strokeWidth={2}
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      d="M4.5 12.75l6 6 9-13.5"
                    />
                  </svg>
                </div>
                <h2 className="text-lg font-bold text-slate-800 mb-2">
                  Abonelik İptal Edildi
                </h2>
                <p className="text-slate-500 text-sm leading-relaxed">
                  <span className="font-semibold text-slate-700">{email}</span>{" "}
                  adresi e-posta listemizden başarıyla çıkarıldı. Artık bu
                  adrse pazarlama e-postası göndermeyeceğiz.
                </p>
              </>
            )}

            {status === "error" && (
              <>
                <div className="w-16 h-16 bg-red-50 rounded-full flex items-center justify-center mx-auto mb-6">
                  <svg
                    className="w-8 h-8 text-red-500"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                    strokeWidth={2}
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126zM12 15.75h.007v.008H12v-.008z"
                    />
                  </svg>
                </div>
                <h2 className="text-lg font-bold text-slate-800 mb-2">
                  Bir Hata Oluştu
                </h2>
                <p className="text-slate-500 text-sm mb-6">
                  {message}
                </p>
                <button
                  onClick={() => setStatus("idle")}
                  className="w-full border border-slate-200 hover:border-blue-300 text-slate-700 hover:text-blue-600 font-semibold py-3 px-6 rounded-xl transition-all duration-200 text-sm"
                >
                  Tekrar Dene
                </button>
              </>
            )}
          </div>

          {/* Footer */}
          <div className="bg-slate-50 border-t border-slate-100 px-8 py-4 text-center">
            <p className="text-xs text-slate-400">
              © 2026 Stanomer. Tüm hakları saklıdır.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}

export default function UnsubscribePage() {
  return (
    <Suspense
      fallback={
        <div className="min-h-screen bg-slate-50 flex items-center justify-center">
          <div className="text-slate-400 text-sm">Yükleniyor...</div>
        </div>
      }
    >
      <UnsubscribeContent />
    </Suspense>
  );
}
