"use client";

import React, { useState, useRef, useEffect } from "react";
import { MessageCircle, X, ArrowUpRight } from "lucide-react";
import { useLanguage } from "./LanguageProvider";

export function FloatingContactWidget() {
  const [isOpen, setIsOpen] = useState(false);
  const widgetRef = useRef<HTMLDivElement>(null);
  const { lang } = useLanguage();

  const phoneNumber = "+381 61 6036556";
  const rawNumber = "381616036556";

  // Translations
  const texts = {
    TR: {
      title: "Hızlı İletişim",
      status: "WhatsApp & Viber üzerinden bize ulaşabilirsiniz.",
      openChat: "Sohbet Başlat",
    },
    SR_LAT: {
      title: "Brzi kontakt",
      status: "Dostupni smo na WhatsApp-u i Viber-u.",
      openChat: "Započni chat",
    },
    SR_CYR: {
      title: "Брзи контакт",
      status: "Доступни смо на WhatsApp-у и Viber-у.",
      openChat: "Започни чет",
    },
    EN: {
      title: "Quick Contact",
      status: "We are available on WhatsApp & Viber.",
      openChat: "Start Chat",
    },
    RU: {
      title: "Быстрая связь",
      status: "Мы доступны в WhatsApp и Viber.",
      openChat: "Начать чат",
    },
  }[lang] || {
    title: "Brzi kontakt",
    status: "Dostupni smo na WhatsApp-u i Viber-u.",
    openChat: "Započni chat",
  };

  // Close when clicking outside
  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (widgetRef.current && !widgetRef.current.contains(event.target as Node)) {
        setIsOpen(false);
      }
    }
    if (isOpen) {
      document.addEventListener("mousedown", handleClickOutside);
    }
    return () => {
      document.removeEventListener("mousedown", handleClickOutside);
    };
  }, [isOpen]);

  const handleViberClick = (e: React.MouseEvent<HTMLAnchorElement>) => {
    // Open viber scheme directly, fallback to viber.click if needed
    const viberUri = `viber://chat?number=%2B${rawNumber}`;
    window.location.href = viberUri;
    setIsOpen(false);
  };

  return (
    <div ref={widgetRef} className="fixed bottom-6 right-6 z-[9999] flex flex-col items-end">
      {/* Expanded Popup Menu */}
      {isOpen && (
        <div className="mb-3 w-72 bg-white rounded-2xl shadow-2xl border border-slate-200/80 p-3.5 animate-in fade-in slide-in-from-bottom-3 duration-200">
          {/* Header */}
          <div className="flex items-center gap-2 pb-2.5 mb-2 border-b border-slate-100">
            <span className="relative flex h-2.5 w-2.5">
              <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
              <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-emerald-500"></span>
            </span>
            <span className="text-xs font-semibold text-slate-700">{texts.title}</span>
          </div>

          <p className="text-[11px] text-slate-500 mb-3 leading-relaxed">
            {texts.status}
          </p>

          {/* Options */}
          <div className="space-y-2">
            {/* WhatsApp */}
            <a
              href={`https://wa.me/${rawNumber}`}
              target="_blank"
              rel="noopener noreferrer"
              onClick={() => setIsOpen(false)}
              className="flex items-center gap-3 p-2.5 rounded-xl border border-slate-100 bg-slate-50/70 hover:bg-emerald-50/60 hover:border-emerald-200/80 transition-all duration-150 group"
            >
              <div className="w-9 h-9 rounded-full bg-[#25D366] flex items-center justify-center text-white shadow-sm flex-shrink-0 group-hover:scale-105 transition-transform">
                <svg viewBox="0 0 24 24" width="18" height="18" fill="currentColor">
                  <path d="M12.031 6.172c-3.181 0-5.767 2.586-5.768 5.766-.001 1.298.38 2.27 1.019 3.287l-.711 2.598 2.664-.698c.969.586 1.761.859 2.796.859 3.179 0 5.766-2.587 5.768-5.766.002-3.181-2.585-5.766-5.768-5.766zm3.364 8.243c-.14.394-.712.723-1.002.766-.279.041-.632.062-1.921-.472-1.649-.684-2.698-2.383-2.78-2.493-.082-.11-.663-.883-.663-1.682 0-.799.418-1.192.567-1.353.149-.161.326-.201.435-.201.109 0 .218.001.314.006.101.005.236-.038.369.281.137.329.467 1.139.508 1.222.041.083.069.179.014.288-.055.11-.082.179-.164.275-.082.096-.173.215-.247.288-.082.082-.168.172-.072.337.096.165.426.703.914 1.138.629.56 1.159.734 1.324.816.165.082.262.069.359-.042.096-.11.413-.481.523-.646.11-.165.22-.138.371-.083.151.055.956.451 1.121.533.165.082.275.124.316.193.041.069.041.401-.099.795z" />
                </svg>
              </div>
              <div className="flex-1 min-w-0">
                <div className="text-xs font-bold text-slate-800">WhatsApp</div>
                <div className="text-[11px] text-slate-500">{phoneNumber}</div>
              </div>
              <ArrowUpRight className="w-4 h-4 text-slate-400 group-hover:text-emerald-600 transition-colors" />
            </a>

            {/* Viber */}
            <a
              href={`viber://chat?number=%2B${rawNumber}`}
              onClick={handleViberClick}
              className="flex items-center gap-3 p-2.5 rounded-xl border border-slate-100 bg-slate-50/70 hover:bg-purple-50/60 hover:border-purple-200/80 transition-all duration-150 group"
            >
              <div className="w-9 h-9 rounded-full bg-[#7360F2] flex items-center justify-center text-white shadow-sm flex-shrink-0 group-hover:scale-105 transition-transform">
                <svg viewBox="0 0 24 24" width="18" height="18" fill="currentColor">
                  <path d="M19.39 15.68c-.68-.39-1.5-.2-1.89.47l-.54.91c-.24.4-.76.54-1.18.31-1.89-1.04-3.41-2.56-4.45-4.45-.23-.42-.09-.94.31-1.18l.91-.54c.67-.39.86-1.21.47-1.89l-1.64-2.85c-.39-.68-1.21-.86-1.89-.47l-.92.53C7.54 7.07 7.02 8.35 7.27 9.68c.67 3.53 3.52 6.38 7.05 7.05 1.33.25 2.61-.27 3.17-1.24l.53-.92c.39-.68.2-1.5-.47-1.89l-2.16-1zM14 6.5c1.93 0 3.5 1.57 3.5 3.5h1.5c0-2.76-2.24-5-5-5v1.5zm0 3c.83 0 1.5.67 1.5 1.5h1.5c0-1.66-1.34-3-3-3v1.5z" />
                </svg>
              </div>
              <div className="flex-1 min-w-0">
                <div className="text-xs font-bold text-slate-800">Viber</div>
                <div className="text-[11px] text-slate-500">{phoneNumber}</div>
              </div>
              <ArrowUpRight className="w-4 h-4 text-slate-400 group-hover:text-purple-600 transition-colors" />
            </a>
          </div>
        </div>
      )}

      {/* Floating Trigger Button */}
      <button
        onClick={() => setIsOpen(!isOpen)}
        aria-label="Open contact options"
        className={`relative w-14 h-14 rounded-full shadow-lg flex items-center justify-center transition-all duration-300 transform hover:scale-105 active:scale-95 focus:outline-none ${
          isOpen
            ? "bg-slate-800 text-white shadow-slate-900/30"
            : "bg-[#1A5EB8] hover:bg-[#154c94] text-white shadow-blue-900/30 hover:shadow-xl"
        }`}
      >
        {isOpen ? (
          <X className="w-6 h-6 transition-transform duration-200 rotate-0" />
        ) : (
          <>
            <MessageCircle className="w-6 h-6" />
            <span className="absolute top-1.5 right-1.5 w-3 h-3 bg-emerald-500 border-2 border-white rounded-full"></span>
          </>
        )}
      </button>
    </div>
  );
}
