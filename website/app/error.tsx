"use client";

import { useEffect } from "react";

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    console.error("App Error:", error);
  }, [error]);

  return (
    <div className="min-h-screen flex flex-col items-center justify-center bg-gray-50 px-4 text-center">
      <div className="bg-white p-8 rounded-2xl shadow-xl border border-gray-100 max-w-md w-full space-y-4">
        <div className="w-12 h-12 bg-red-50 text-red-500 rounded-full flex items-center justify-center mx-auto text-xl font-bold">
          !
        </div>
        <h2 className="text-xl font-bold text-gray-900">Bir şeyler yanlış gitti</h2>
        <p className="text-sm text-gray-600">
          Sayfa yüklenirken geçici bir hata oluştu.
        </p>
        <button
          onClick={() => reset()}
          className="w-full py-2.5 px-4 bg-brand-blue text-white font-semibold rounded-xl hover:bg-blue-600 transition-all shadow-md"
        >
          Tekrar Deneyin
        </button>
      </div>
    </div>
  );
}
