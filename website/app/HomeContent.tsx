"use client";

import React, { useState, useEffect } from "react";
import { useLanguage } from "../components/LanguageProvider";
import { Shield, Cloud, Heart, ClipboardList, FileText, Bell, Wrench, Globe } from "lucide-react";

export function HomeContent() {
  const { t } = useLanguage();
  const [deviceOS, setDeviceOS] = useState<string | null>(null);

  useEffect(() => {
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
  }, []);

  return (
    <div className="min-h-screen flex flex-col font-sans bg-transparent text-gray-900">
      {/* Hero Section */}
      <section className="max-w-[680px] mx-auto px-6 pt-16 pb-6 w-full relative overflow-visible">
        {/* Glow Effects */}
        <div className="absolute top-1/4 left-1/4 -translate-x-1/2 -translate-y-1/2 w-80 h-80 rounded-full bg-brand-blue/15 blur-[120px] pointer-events-none z-0" />
        <div className="absolute bottom-1/4 right-1/4 translate-x-1/2 translate-y-1/2 w-64 h-64 rounded-full bg-brand-green/10 blur-[100px] pointer-events-none z-0" />

        <div className="relative z-10 bg-white/80 backdrop-blur-[20px] border border-gray-200 rounded-3xl p-12 text-center shadow-[0_10px_50px_rgba(59,130,246,0.08)] transition-all duration-300 hover:border-gray-300">
          <div className="inline-flex items-center gap-1.5 px-3.5 py-1 rounded-full bg-brand-blue/15 border border-brand-blue/30 text-brand-blue text-[11px] font-bold uppercase tracking-wider mb-6 animate-pulse">
            <span className="w-1.5 h-1.5 rounded-full bg-brand-blue" />
            {t("hero_badge")}
          </div>
          <h1 className="text-[34px] font-extrabold text-gray-900 leading-tight mb-5 tracking-tight" dangerouslySetInnerHTML={{ __html: t("hero_title") }} />
          <p className="text-[15px] text-gray-700 leading-relaxed mb-8 max-w-[480px] mx-auto">
            {t("hero_desc")}
          </p>
          
          {deviceOS === null || deviceOS === 'desktop' ? (
            <div className="flex flex-wrap items-center justify-center gap-4 mb-6">
              <a href="https://apps.apple.com/us/app/stanomer/id6762311157" target="_blank" rel="noopener noreferrer" className="inline-flex transition-opacity hover:opacity-85">
                <img src="https://upload.wikimedia.org/wikipedia/commons/9/91/Download_on_the_App_Store_RGB_blk.svg" alt="Download on the App Store" className="h-10 w-[135px] block" />
              </a>
              <a href="https://play.google.com/store/apps/details?id=com.aboptima.stanomer" target="_blank" rel="noopener noreferrer" className="inline-flex transition-opacity hover:opacity-85">
                <img src="https://upload.wikimedia.org/wikipedia/commons/7/78/Google_Play_Store_badge_EN.svg" alt="Get it on Google Play" className="h-10 w-[135px] block" />
              </a>
              <a href="/app" className="h-10 inline-flex items-center justify-center gap-2 bg-black text-white hover:opacity-85 active:scale-[0.98] font-medium text-[14px] tracking-[0.3px] px-5 rounded-[24px] border border-black transition-all duration-200">
                <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="opacity-90">
                  <circle cx="12" cy="12" r="10"></circle>
                  <line x1="2" y1="12" x2="22" y2="12"></line>
                  <path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"></path>
                </svg>
                {t("btn_web_app")}
              </a>
            </div>
          ) : deviceOS === 'ios' ? (
            <div className="flex flex-wrap justify-center gap-4 mb-6">
              <a href="https://apps.apple.com/us/app/stanomer/id6762311157" target="_blank" rel="noopener noreferrer" className="inline-flex transition-opacity hover:opacity-85">
                <img src="https://upload.wikimedia.org/wikipedia/commons/9/91/Download_on_the_App_Store_RGB_blk.svg" alt="Download on the App Store" className="h-10 w-[135px] block" />
              </a>
            </div>
          ) : (
            <div className="flex flex-wrap justify-center gap-4 mb-6">
              <a href="https://play.google.com/store/apps/details?id=com.aboptima.stanomer" target="_blank" rel="noopener noreferrer" className="inline-flex transition-opacity hover:opacity-85">
                <img src="https://upload.wikimedia.org/wikipedia/commons/7/78/Google_Play_Store_badge_EN.svg" alt="Get it on Google Play" className="h-10 w-[135px] block" />
              </a>
            </div>
          )}

          <p className="text-[12px] text-gray-500">
            {t("hero_note")}
          </p>
        </div>
      </section>

      {/* Pain Strip */}
      <section className="max-w-[680px] mx-auto px-6 py-3 w-full">
        <div className="bg-white/80 backdrop-blur-[16px] border border-gray-200 rounded-xl p-6 text-[14px] text-gray-700 leading-relaxed" dangerouslySetInnerHTML={{ __html: t("pain_strip") }} />
      </section>

      {/* Roles Grid */}
      <section className="max-w-[680px] mx-auto px-6 py-6 w-full">
        <div className="text-[11px] font-bold text-gray-500 uppercase tracking-widest mb-4">
          {t("roles_label")}
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div className="bg-white/80 backdrop-blur-[16px] border border-gray-200 rounded-2xl p-6">
            <h3 className="text-[18px] font-bold text-gray-900 mb-4">{t("roles_landlord")}</h3>
            <div className="space-y-3">
              {[1, 2, 3, 4].map((i) => (
                <div key={i} className="flex gap-3 text-[13px] text-gray-700 items-start py-2 border-b border-gray-100 last:border-0">
                  <div className="w-1.5 h-1.5 rounded-full bg-brand-blue mt-1.5 flex-shrink-0" />
                  <span>{t(`roles_landlord_${i}`)}</span>
                </div>
              ))}
            </div>
          </div>
          <div className="bg-white/80 backdrop-blur-[16px] border border-gray-200 rounded-2xl p-6">
            <h3 className="text-[18px] font-bold text-gray-900 mb-4">{t("roles_tenant")}</h3>
            <div className="space-y-3">
              {[1, 2, 3, 4].map((i) => (
                <div key={i} className="flex gap-3 text-[13px] text-gray-700 items-start py-2 border-b border-gray-100 last:border-0">
                  <div className="w-1.5 h-1.5 rounded-full bg-brand-blue mt-1.5 flex-shrink-0" />
                  <span>{t(`roles_tenant_${i}`)}</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      </section>

      {/* Steps */}
      <section className="max-w-[680px] mx-auto px-6 py-6 w-full">
        <div className="bg-white/80 backdrop-blur-[16px] border border-gray-200 rounded-2xl p-8">
          <h2 className="text-[20px] font-bold text-gray-900 mb-6">{t("steps_title")}</h2>
          <div className="space-y-8">
            {[1, 2, 3].map((i) => (
              <div key={i} className="flex gap-4">
                <div className="w-8 h-8 rounded-full border border-gray-200 bg-gray-100 flex items-center justify-center text-[13px] font-bold text-gray-900 flex-shrink-0">
                  {i}
                </div>
                <div>
                  <h4 className="text-[15px] font-bold text-gray-900 mb-1">{t(`step_${i}_title`)}</h4>
                  <p className="text-[14px] text-gray-700 leading-relaxed">{t(`step_${i}_desc`)}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Trust Grid */}
      <section className="max-w-[680px] mx-auto px-6 py-6 w-full">
        <div className="text-[11px] font-bold text-gray-500 uppercase tracking-widest mb-4">
          {t("trust_label")}
        </div>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
          <div className="bg-white/80 backdrop-blur-[16px] border border-gray-200 rounded-xl p-5 text-center">
            <Shield className="w-6 h-6 text-brand-blue mx-auto mb-3" />
            <h4 className="text-[14px] font-bold text-gray-900 mb-2">{t("trust_1_title")}</h4>
            <p className="text-[12px] text-gray-500 leading-normal">{t("trust_1_desc")}</p>
          </div>
          <div className="bg-white/80 backdrop-blur-[16px] border border-gray-200 rounded-xl p-5 text-center">
            <Cloud className="w-6 h-6 text-brand-blue mx-auto mb-3" />
            <h4 className="text-[14px] font-bold text-gray-900 mb-2">{t("trust_2_title")}</h4>
            <p className="text-[12px] text-gray-500 leading-normal">{t("trust_2_desc")}</p>
          </div>
          <div className="bg-white/80 backdrop-blur-[16px] border border-gray-200 rounded-xl p-5 text-center">
            <Heart className="w-6 h-6 text-brand-blue mx-auto mb-3" />
            <h4 className="text-[14px] font-bold text-gray-900 mb-2">{t("trust_3_title")}</h4>
            <p className="text-[12px] text-gray-500 leading-normal">{t("trust_3_desc")}</p>
          </div>
        </div>
      </section>

      {/* Features List */}
      <section className="max-w-[680px] mx-auto px-6 py-6 w-full">
        <div className="text-[11px] font-bold text-gray-500 uppercase tracking-widest mb-4">
          {t("features_label")}
        </div>
        <div className="bg-white/80 backdrop-blur-[16px] border border-gray-200 rounded-2xl px-8 py-2 shadow-md">
          <div className="space-y-0">
            {[
              { i: 1, icon: ClipboardList },
              { i: 2, icon: FileText },
              { i: 3, icon: Bell },
              { i: 4, icon: Wrench },
              { i: 5, icon: Globe },
            ].map(({ i, icon: Icon }, index, arr) => (
              <div key={i} className={`flex gap-4 py-6 ${index !== arr.length - 1 ? 'border-b border-gray-200' : ''}`}>
                <div className="w-10 h-10 rounded-lg bg-brand-blue/10 flex items-center justify-center flex-shrink-0 text-brand-blue">
                  <Icon className="w-5 h-5" />
                </div>
                <div>
                  <h4 className="text-[15px] font-bold text-gray-900 mb-1">{t(`feature_${i}_title`)}</h4>
                  <p className="text-[14px] text-gray-700 leading-relaxed">{t(`feature_${i}_desc`)}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Footer CTA */}
      <section className="max-w-[680px] mx-auto px-6 py-12 w-full">
        <div className="bg-white/80 backdrop-blur-[16px] border border-gray-200 rounded-3xl p-10 text-center shadow-xl">
          <h2 className="text-[24px] font-bold text-gray-900 mb-3">{t("footer_cta_title")}</h2>
          <p className="text-[14px] text-gray-700 leading-relaxed mb-8" dangerouslySetInnerHTML={{ __html: t("footer_cta_desc") }} />
          
          {deviceOS === null || deviceOS === 'desktop' ? (
            <div className="flex flex-wrap items-center justify-center gap-4 mb-6">
              <a href="https://apps.apple.com/us/app/stanomer/id6762311157" target="_blank" rel="noopener noreferrer" className="inline-flex transition-opacity hover:opacity-85">
                <img src="https://upload.wikimedia.org/wikipedia/commons/9/91/Download_on_the_App_Store_RGB_blk.svg" alt="Download on the App Store" className="h-10 w-[135px] block" />
              </a>
              <a href="https://play.google.com/store/apps/details?id=com.aboptima.stanomer" target="_blank" rel="noopener noreferrer" className="inline-flex transition-opacity hover:opacity-85">
                <img src="https://upload.wikimedia.org/wikipedia/commons/7/78/Google_Play_Store_badge_EN.svg" alt="Get it on Google Play" className="h-10 w-[135px] block" />
              </a>
              <a href="/app" className="h-10 inline-flex items-center justify-center gap-2 bg-black text-white hover:opacity-85 active:scale-[0.98] font-medium text-[14px] tracking-[0.3px] px-5 rounded-[24px] border border-black transition-all duration-200">
                <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="opacity-90">
                  <circle cx="12" cy="12" r="10"></circle>
                  <line x1="2" y1="12" x2="22" y2="12"></line>
                  <path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"></path>
                </svg>
                {t("btn_web_app")}
              </a>
            </div>
          ) : deviceOS === 'ios' ? (
            <div className="flex flex-wrap justify-center gap-4 mb-6">
              <a href="https://apps.apple.com/us/app/stanomer/id6762311157" target="_blank" rel="noopener noreferrer" className="inline-flex transition-opacity hover:opacity-85">
                <img src="https://upload.wikimedia.org/wikipedia/commons/9/91/Download_on_the_App_Store_RGB_blk.svg" alt="Download on the App Store" className="h-10 w-[135px] block" />
              </a>
            </div>
          ) : (
            <div className="flex flex-wrap justify-center gap-4 mb-6">
              <a href="https://play.google.com/store/apps/details?id=com.aboptima.stanomer" target="_blank" rel="noopener noreferrer" className="inline-flex transition-opacity hover:opacity-85">
                <img src="https://upload.wikimedia.org/wikipedia/commons/7/78/Google_Play_Store_badge_EN.svg" alt="Get it on Google Play" className="h-10 w-[135px] block" />
              </a>
            </div>
          )}
        </div>
      </section>

      {/* Footer */}
      <footer className="py-12 border-t border-gray-200 mt-12 w-full">
        <div className="max-w-[680px] mx-auto px-6 text-center">
          <div className="flex items-center justify-center gap-2 opacity-50 mb-6">
            <img src="/assets/logo.png" alt="Stanomer Logo" className="w-6 h-6 object-contain" />
            <span className="font-bold text-sm tracking-tight text-gray-850">Stanomer</span>
          </div>
          
          <div className="flex flex-wrap justify-center gap-x-6 gap-y-2 mb-6 text-[12px] font-medium text-gray-500">
            <a href="/privacy" className="hover:text-brand-blue transition-colors">{t("footer_privacy")}</a>
            <a href="/terms" className="hover:text-brand-blue transition-colors">{t("footer_terms")}</a>
            <a href="/changelog" className="hover:text-brand-blue transition-colors">{t("footer_changelog")}</a>
            <a href="/support" className="hover:text-brand-blue transition-colors">{t("footer_support")}</a>
          </div>

          <p className="text-gray-500 text-[11px]">
            © 2026 Stanomer. {t("footer_rights")}
          </p>
        </div>
      </footer>
    </div>
  );
}
