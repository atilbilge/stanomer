"use client";

export default function GlobalError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  return (
    <html lang="tr">
      <body>
        <div className="min-h-screen flex flex-col items-center justify-center bg-gray-50 px-4 text-center">
          <div className="bg-white p-8 rounded-2xl shadow-xl border border-gray-100 max-w-md w-full space-y-4">
            <h2 className="text-xl font-bold text-gray-900">Sistem Hatası</h2>
            <p className="text-sm text-gray-600">
              Kritik bir yükleme hatası oluştu.
            </p>
            <button
              onClick={() => reset()}
              className="w-full py-2.5 px-4 bg-brand-blue text-white font-semibold rounded-xl hover:bg-blue-600 transition-all shadow-md"
            >
              Sayfayı Yenile
            </button>
          </div>
        </div>
      </body>
    </html>
  );
}
