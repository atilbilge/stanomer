"use client";

import React, { useState, useEffect } from "react";
import { Navbar } from "./Navbar";
import { useLanguage } from "./LanguageProvider";
import { 
  ShieldCheck, 
  Smartphone, 
  CheckCircle2, 
  BookOpen,
  MapPin
} from "lucide-react";

export interface GuideLayoutProps {
  currentLang: "TR" | "EN" | "SR_LAT" | "SR_CYR" | "RU";
  title: string;
  subtitle?: string;
  readTime?: string;
  lastUpdated?: string;
  ctaText: string;
  ctaSubtext: string;
  canonicalUrl: string;
  categoryTitle?: string;
  locationName?: string;
  children: React.ReactNode;
}

export function GuideLayout({
  currentLang,
  title,
  subtitle,
  readTime = "6 min",
  lastUpdated = "2026",
  ctaText,
  ctaSubtext,
  canonicalUrl,
  categoryTitle = "Property Guide",
  locationName = "Serbia",
  children
}: GuideLayoutProps) {
  const { lang, setLang, t } = useLanguage();
  const [deviceOS, setDeviceOS] = useState<string | null>(null);

  useEffect(() => {
    if (lang !== currentLang) {
      setLang(currentLang);
    }

    const userAgent = window.navigator.userAgent || window.navigator.vendor;
    const isIOS = /iPad|iPhone|iPod/.test(userAgent) || 
      (window.navigator.platform === 'MacIntel' && window.navigator.maxTouchPoints > 1);
    const isAndroid = /android/i.test(userAgent);
    
    if (isIOS) {
      setDeviceOS('ios');
    } else if (isAndroid) {
      setDeviceOS('android');
    } else {
      setDeviceOS('desktop');
    }
  }, [currentLang, lang, setLang]);

  return (
    <div className="min-h-screen flex flex-col font-sans bg-transparent text-gray-900">
      <Navbar />

      {/* Spacer for fixed Navbar */}
      <div className="h-[80px]" />

      {/* Breadcrumbs Sub-bar */}
      <div className="w-full bg-white/70 backdrop-blur-[12px] border-b border-gray-200/80 sticky top-[80px] z-40">
        <div className="max-w-[680px] mx-auto px-6 py-2.5 flex items-center justify-between gap-3 text-xs">
          <div className="flex items-center gap-1.5 text-gray-500 font-medium overflow-x-auto whitespace-nowrap py-0.5">
            <a href="/" className="hover:text-brand-blue transition-colors">
              {currentLang === "TR" ? "Ana Sayfa" : currentLang === "EN" ? "Home" : currentLang === "SR_CYR" ? "Почетна" : currentLang === "RU" ? "Главная" : "Početna"}
            </a>
            <span>/</span>
            <a href="/guide" className="hover:text-brand-blue transition-colors">
              {currentLang === "TR" ? "Rehberler" : currentLang === "EN" ? "Guides" : currentLang === "SR_CYR" ? "Водичи" : currentLang === "RU" ? "Руководства" : "Vodiči"}
            </a>
            <span>/</span>
            <span className="text-gray-900 font-semibold truncate max-w-[220px] sm:max-w-none">
              {categoryTitle} ({currentLang === "TR" ? "TR" : currentLang === "EN" ? "EN" : currentLang === "SR_CYR" ? "СР" : currentLang === "RU" ? "RU" : "SR"})
            </span>
          </div>
        </div>
      </div>

      {/* Main Guide Content */}
      <main className="flex-grow max-w-[680px] mx-auto px-4 sm:px-6 py-8 sm:py-12 w-full">
        {/* Guide Article Card Wrapper */}
        <article className="bg-white/85 backdrop-blur-[20px] rounded-3xl border border-gray-200 shadow-[0_10px_50px_rgba(59,130,246,0.08)] overflow-hidden">
          
          {/* Header Banner */}
          <div className="bg-gradient-to-br from-brand-blue/10 via-white to-brand-green/10 border-b border-gray-200/70 p-6 sm:p-10 relative">
            <div className="inline-flex items-center gap-2 px-3.5 py-1 rounded-full bg-brand-blue/15 border border-brand-blue/30 text-brand-blue text-[11px] font-bold uppercase tracking-wider mb-4">
              <BookOpen className="w-3.5 h-3.5" />
              <span>{categoryTitle}</span>
            </div>

            <h1 className="text-2xl sm:text-3xl font-extrabold text-gray-900 leading-tight tracking-tight mb-4">
              {title}
            </h1>

            {subtitle && (
              <p className="text-sm text-gray-600 leading-relaxed mb-6 font-normal">
                {subtitle}
              </p>
            )}

            {/* Meta info bar */}
            <div className="flex flex-wrap items-center gap-3 text-xs text-gray-500 pt-4 border-t border-gray-200/60 font-medium">
              <span className="flex items-center gap-1.5">
                <MapPin className="w-3.5 h-3.5 text-brand-blue" />
                {locationName}
              </span>
              <span>•</span>
              <span>{readTime}</span>
              <span>•</span>
              <span>Updated {lastUpdated}</span>
              <span>•</span>
              <span className="text-brand-blue font-semibold">Stanomer Verified</span>
            </div>
          </div>

          {/* Article Body */}
          <div className="p-6 sm:p-8 space-y-8 text-gray-800 text-[15px] leading-relaxed">
            {children}

            {/* Mid-Article / Main High-Impact CTA Banner */}
            <section className="my-8 p-6 sm:p-8 rounded-2xl bg-gradient-to-br from-gray-900 via-gray-900 to-slate-800 text-white shadow-2xl relative overflow-hidden">
              <div className="absolute -top-12 -right-12 w-48 h-48 rounded-full bg-brand-blue/25 blur-3xl pointer-events-none" />
              <div className="absolute -bottom-12 -left-12 w-48 h-48 rounded-full bg-brand-green/25 blur-3xl pointer-events-none" />

              <div className="relative z-10 text-center sm:text-left space-y-4">
                <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-white/10 text-brand-blue text-xs font-semibold backdrop-blur-md border border-white/10">
                  <ShieldCheck className="w-4 h-4 text-brand-green" />
                  <span>
                    {currentLang === "TR" ? "Yerel & Güvenli Takip" : currentLang === "EN" ? "Private & Local Storage" : currentLang === "SR_CYR" ? "Локално и безбедно" : currentLang === "RU" ? "Локальное и безопасное хранение" : "Lokalno i bezbedno"}
                  </span>
                </div>

                <h3 className="text-xl font-extrabold text-white leading-snug">
                  {ctaText}
                </h3>

                <p className="text-xs sm:text-sm text-gray-300 max-w-xl leading-relaxed">
                  {ctaSubtext}
                </p>

                {/* App Download Buttons */}
                <div className="pt-2 flex flex-wrap items-center justify-start gap-3">
                  <a 
                    href="https://apps.apple.com/us/app/stanomer/id6762311157" 
                    target="_blank" 
                    rel="noopener noreferrer" 
                    className="inline-flex transition-transform hover:scale-105 active:scale-95"
                  >
                    <img src="https://upload.wikimedia.org/wikipedia/commons/9/91/Download_on_the_App_Store_RGB_blk.svg" alt="Download on the App Store" className="h-10 w-[135px] block" />
                  </a>
                  <a 
                    href="https://play.google.com/store/apps/details?id=com.aboptima.stanomer" 
                    target="_blank" 
                    rel="noopener noreferrer" 
                    className="inline-flex transition-transform hover:scale-105 active:scale-95"
                  >
                    <img src="https://upload.wikimedia.org/wikipedia/commons/7/78/Google_Play_Store_badge_EN.svg" alt="Get it on Google Play" className="h-10 w-[135px] block" />
                  </a>
                  <a 
                    href="/app" 
                    className="h-10 inline-flex items-center justify-center gap-2 bg-brand-blue hover:bg-blue-600 text-white font-semibold text-xs tracking-wide px-4 rounded-lg transition-all shadow-md active:scale-95"
                  >
                    <Smartphone className="w-4 h-4" />
                    <span>{currentLang === "TR" ? "Web Uygulamasını Aç" : currentLang === "EN" ? "Open Web App" : currentLang === "SR_CYR" ? "Отвори Веб Апликацију" : currentLang === "RU" ? "Открыть Веб-Приложение" : "Otvori Web Aplikaciju"}</span>
                  </a>
                </div>

                <div className="pt-1 flex items-center gap-2 text-[11px] text-gray-400 font-medium">
                  <CheckCircle2 className="w-3.5 h-3.5 text-brand-green" />
                  <span>
                    {currentLang === "TR" ? "Ücretsiz indirin • Kredi kartı gerekmez • %100 Cihazınızda Gizli" : currentLang === "EN" ? "Free download • No credit card required • 100% On-device Privacy" : currentLang === "SR_CYR" ? "Бесплатно • Без кредитна картице • 100% Приватност на уређају" : currentLang === "RU" ? "Бесплатно • Без кредитной карты • 100% Конфиденциальность на устройстве" : "Besplatno • Bez kreditne kartice • 100% Privatnost na uređaju"}
                  </span>
                </div>
              </div>
            </section>

            {/* Related Guides / Internal Links Section for SEO */}
            <section className="pt-6 border-t border-gray-200/80 space-y-3">
              <h4 className="text-xs font-bold uppercase tracking-wider text-gray-500">
                {currentLang === "TR" 
                  ? "Sırbistan Emlak ve Mülk Rehberleri" 
                  : currentLang === "EN" 
                  ? "Related Serbia Property Guides" 
                  : currentLang === "SR_CYR" 
                  ? "Повезани водичи у Србији" 
                  : currentLang === "RU"
                  ? "Похожие руководства по Сербии"
                  : "Povezani vodiči u Srbiji"}
              </h4>
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 text-xs">
                <a 
                  href={currentLang === "TR" ? "/guide/belgrad-kiralik-daire-rehberi" : currentLang === "EN" ? "/guide/belgrade-apartment-rental-guide" : currentLang === "SR_CYR" ? "/guide/vodic-za-izdavanje-stanova-beograd-cirilica" : currentLang === "RU" ? "/guide/belgrade-apartment-rental-guide-ru" : "/guide/vodic-za-izdavanje-stanova-beograd"}
                  className="p-3 bg-gray-50 rounded-xl border border-gray-200 hover:border-brand-blue hover:text-brand-blue font-medium transition-all"
                >
                  🏙️ {currentLang === "TR" ? "Belgrad Rehberi" : currentLang === "EN" ? "Belgrade Guide" : currentLang === "SR_CYR" ? "Водич за Београд" : currentLang === "RU" ? "Гайд по Белграду" : "Vodič za Beograd"}
                </a>
                <a 
                  href={currentLang === "TR" ? "/guide/novi-sad-mulk-yonetimi-rehberi" : currentLang === "EN" ? "/guide/novi-sad-property-management-guide" : currentLang === "SR_CYR" ? "/guide/upravljanje-nekretninama-novi-sad-cirilica" : currentLang === "RU" ? "/guide/novi-sad-property-management-guide-ru" : "/guide/upravljanje-nekretninama-novi-sad"}
                  className="p-3 bg-gray-50 rounded-xl border border-gray-200 hover:border-brand-blue hover:text-brand-blue font-medium transition-all"
                >
                  🏡 {currentLang === "TR" ? "Novi Sad Rehberi" : currentLang === "EN" ? "Novi Sad Guide" : currentLang === "SR_CYR" ? "Водич за Нови Сад" : currentLang === "RU" ? "Гайд по Нови-Саду" : "Vodič za Novi Sad"}
                </a>
                <a 
                  href={currentLang === "TR" ? "/guide/sirbistan-kira-sozlesmesi-rehberi" : currentLang === "EN" ? "/guide/serbia-lease-agreement-guide" : currentLang === "SR_CYR" ? "/guide/ugovor-o-zakupu-stana-srbija-cirilica" : currentLang === "RU" ? "/guide/serbia-lease-agreement-guide-ru" : "/guide/ugovor-o-zakupu-stana-srbija"}
                  className="p-3 bg-gray-50 rounded-xl border border-gray-200 hover:border-brand-blue hover:text-brand-blue font-medium transition-all"
                >
                  📝 {currentLang === "TR" ? "Kira Sözleşmesi Rehberi" : currentLang === "EN" ? "Lease Agreement Guide" : currentLang === "SR_CYR" ? "Водич за Уговор" : currentLang === "RU" ? "Гайд по Договору" : "Vodič za Ugovor"}
                </a>
              </div>
            </section>
          </div>

          {/* Footer of the Guide Article */}
          <div className="bg-gray-50 border-t border-gray-200/80 p-6 sm:p-8 text-center space-y-4">
            <h3 className="text-base sm:text-lg font-bold text-gray-900">
              {currentLang === "TR" 
                ? "Sırbistan'daki Yeni Evinizde İlk Günden Düzen Kurun" 
                : currentLang === "EN" 
                ? "Stay Organized From Day One in Serbia" 
                : currentLang === "SR_CYR" 
                ? "Будите организовани од првог дана у Србији" 
                : currentLang === "RU"
                ? "Организуйте свой быт в Сербии с первого дня"
                : "Budite organizovani od prvog dana u Srbiji"}
            </h3>
            
            <p className="text-xs sm:text-sm text-gray-600 max-w-lg mx-auto leading-relaxed">
              {currentLang === "TR"
                ? "Kira ödemelerinizi unutmayın, faturalarınızı kaybetmeyin. Stanomer ile tüm süreç cebinizde güvende."
                : currentLang === "EN"
                ? "Never miss a rent due date, never lose a utility receipt. Manage your home seamlessly with Stanomer."
                : currentLang === "SR_CYR"
                ? "Не губите рачуне, не заборављајте рокове. Станомер је ваш дигитални асистент за стан."
                : currentLang === "RU"
                ? "Не теряйте счета, не забывайте сроки. Stanomer — ваш цифровой ассистент по аренде."
                : "Ne gubite račune, ne zaboravljajte rokove. Stanomer je vaš digitalni asistent za stan."}
            </p>

            <div className="flex flex-wrap items-center justify-center gap-3 pt-2">
              <a 
                href="https://apps.apple.com/us/app/stanomer/id6762311157" 
                target="_blank" 
                rel="noopener noreferrer" 
                className="inline-flex transition-transform hover:scale-105"
              >
                <img src="https://upload.wikimedia.org/wikipedia/commons/9/91/Download_on_the_App_Store_RGB_blk.svg" alt="Download on the App Store" className="h-9 w-[120px] block" />
              </a>
              <a 
                href="https://play.google.com/store/apps/details?id=com.aboptima.stanomer" 
                target="_blank" 
                rel="noopener noreferrer" 
                className="inline-flex transition-transform hover:scale-105"
              >
                <img src="https://upload.wikimedia.org/wikipedia/commons/7/78/Google_Play_Store_badge_EN.svg" alt="Get it on Google Play" className="h-9 w-[120px] block" />
              </a>
            </div>
          </div>
        </article>
      </main>

      {/* Website Global Footer */}
      <footer className="py-12 border-t border-gray-200 mt-12 bg-white/50 backdrop-blur-md">
        <div className="max-w-[680px] mx-auto px-6 text-center space-y-4">
          <div className="flex items-center justify-center gap-2 opacity-60">
            <img src="/assets/logo.png" alt="Stanomer Logo" className="w-6 h-6 object-contain" />
            <span className="font-bold text-sm tracking-tight text-gray-900">Stanomer</span>
          </div>

          <div className="flex flex-wrap justify-center gap-x-6 gap-y-2 text-xs font-medium text-gray-600">
            <a href="/" className="hover:text-brand-blue transition-colors">Home</a>
            <a href="/guide" className="hover:text-brand-blue transition-colors font-semibold text-brand-blue">
              {currentLang === "TR" ? "Rehberler" : currentLang === "EN" ? "Guides" : currentLang === "SR_CYR" ? "Водичи" : currentLang === "RU" ? "Руководства" : "Vodiči"}
            </a>
            <a href="/privacy" className="hover:text-brand-blue transition-colors">{t("footer_privacy")}</a>
            <a href="/terms" className="hover:text-brand-blue transition-colors">{t("footer_terms")}</a>
            <a href="/changelog" className="hover:text-brand-blue transition-colors">{t("footer_changelog")}</a>
            <a href="/support" className="hover:text-brand-blue transition-colors">{t("footer_support")}</a>
          </div>

          <p className="text-gray-400 text-[11px]">
            © 2026 Stanomer. {t("footer_rights")}
          </p>
        </div>
      </footer>
    </div>
  );
}
