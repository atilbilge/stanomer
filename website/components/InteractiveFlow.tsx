"use client";

import React, { useState, useEffect } from "react";
import { useLanguage } from "./LanguageProvider";
import { 
  Building, 
  QrCode, 
  UserCheck, 
  Calendar, 
  Clock, 
  CheckCircle2, 
  Receipt, 
  Bell, 
  Send, 
  ChevronLeft, 
  ChevronRight, 
  Play, 
  Pause,
  ShieldCheck,
  Sparkles,
  Wifi,
  Signal,
  Battery,
  Wrench,
  Camera,
  MessageCircle,
  AlertTriangle
} from "lucide-react";

// Step structure:
// 0 → Main Step 1: Property Entry
// 1 → Main Step 2: QR Invite
// 2 → Main Step 3: Tenant Connection
// 3 → Main Step 4: Payment Plan
// 4 → Main Step 5 / Sub-step 5a: Tenant marks rent paid
// 5 → Sub-step 5b: Landlord approves rent
// 6 → Sub-step 5c: Landlord adds utility bill
// 7 → Sub-step 5d: Tenant pays bill
// 8 → Sub-step 5e: Landlord approves bill — all clear
// 9 → Main Step 6: Maintenance tracking

const TOTAL_STEPS = 10;

// Maps step index → display label shown in the dot nav
// 0→1, 1→2, 2→3
// 3→4a, 4→4b, 5→4c  (Step 4 sub-steps: payment plan / mark / approve)
// 6→5a, 7→5b, 8→5c  (Step 5 sub-steps: bill entry / pay / approve)
// 9→6
function getStepLabel(idx: number): string {
  if (idx <= 2) return String(idx + 1);           // 1, 2, 3
  if (idx <= 5) return ["4a", "4b", "4c"][idx - 3]; // 4a, 4b, 4c
  if (idx <= 8) return ["5a", "5b", "5c"][idx - 6]; // 5a, 5b, 5c
  return "6";
}

// Maps step index → main step number for the description panel
function getMainStepNum(idx: number): string {
  if (idx <= 2) return String(idx + 1);
  if (idx <= 5) return "4";
  if (idx <= 8) return "5";
  return "6";
}

// Translation key for the current step description
function getStepTranslationKey(idx: number): string {
  // indices 0-2 → flow_step_1/2/3
  if (idx < 3) return `flow_step_${idx + 1}`;
  // Step 4 sub-steps reuse existing translation keys
  const keyMap: Record<number, string> = {
    3: "flow_step_4",   // 4a: Automatic Payment Plan
    4: "flow_step_5a",  // 4b: Tenant marks rent paid
    5: "flow_step_5b",  // 4c: Landlord approves rent
    6: "flow_step_5c",  // 5a: Utility bill entry
    7: "flow_step_5d",  // 5b: Tenant pays bill
    8: "flow_step_5e",  // 5c: Full approval — zero conflict
    9: "flow_step_6",   // 6:  Maintenance tracking
  };
  return keyMap[idx];
}

export function InteractiveFlow() {
  const { lang, t } = useLanguage();
  const [currentStep, setCurrentStep] = useState(0); // 0-9
  const [isPlaying, setIsPlaying] = useState(false);
  const [isZoomed, setIsZoomed] = useState(false);

  // Derive main step (1-6) and sub-step index from currentStep
  const activeMain = currentStep <= 2 ? currentStep + 1
    : currentStep <= 5 ? 4
    : currentStep <= 8 ? 5
    : 6;

  // First render-index of each main step
  const firstIndexOf = (main: number) =>
    main <= 3 ? main - 1 : main === 4 ? 3 : main === 5 ? 6 : 9;

  // Navigate to a main step (goes to its first sub-step if applicable)
  const goToMain = (main: number) => {
    setCurrentStep(firstIndexOf(main));
    setIsPlaying(false);
  };

  // Navigate to a specific sub-step within step 4 or 5
  const goToSub = (main: number, sub: number) => {
    setCurrentStep((main === 4 ? 3 : 6) + sub);
    setIsPlaying(false);
  };

  const infographicImages: Record<string, string> = {
    TR: "/assets/how_it_works_tr.png",
    EN: "/assets/how_it_works_en.png",
    RU: "/assets/how_it_works_ru.jpg",
    SR_LAT: "/assets/how_it_works_sr.png",
    SR_CYR: "/assets/how_it_works_sr.png",
  };

  const currentInfographic = infographicImages[lang] || infographicImages.EN;

  useEffect(() => {
    let interval: NodeJS.Timeout;
    if (isPlaying) {
      interval = setInterval(() => {
        setCurrentStep((prev) => (prev + 1) % TOTAL_STEPS);
      }, 4500);
    }
    return () => clearInterval(interval);
  }, [isPlaying]);

  const handleNext = () => {
    setCurrentStep((prev) => (prev + 1) % TOTAL_STEPS);
  };

  const handlePrev = () => {
    setCurrentStep((prev) => (prev - 1 + TOTAL_STEPS) % TOTAL_STEPS);
  };

  const stepKey = getStepTranslationKey(currentStep);

  return (
    <section id="how-it-works" className="max-w-[680px] mx-auto px-4 sm:px-6 py-6 w-full">
      <div className="text-center mb-6">
        <div className="inline-flex items-center gap-1.5 px-3.5 py-1 rounded-full bg-brand-blue/10 border border-brand-blue/20 text-brand-blue text-[11px] font-bold uppercase tracking-wider mb-2">
          <Sparkles className="w-3.5 h-3.5 text-brand-blue" />
          {t("how_it_works_label")}
        </div>
        <h2 className="text-[22px] sm:text-[26px] font-extrabold text-gray-900 leading-tight tracking-tight mb-1.5">
          {t("how_it_works_title")}
        </h2>
        <p className="text-[13px] text-gray-600 max-w-[500px] mx-auto leading-relaxed">
          {t("how_it_works_subtitle")}
        </p>
      </div>

      {/* Language Specific Process Infographic */}
      <div className="mb-8 bg-white/80 backdrop-blur-[16px] border border-gray-200/90 rounded-2xl p-2.5 shadow-sm overflow-hidden group">
        <div 
          onClick={() => setIsZoomed(true)}
          className="relative cursor-pointer overflow-hidden rounded-xl bg-gray-50 border border-gray-100 hover:shadow-md transition-all duration-300"
        >
          <img 
            src={currentInfographic} 
            alt={t("how_it_works_title")} 
            className="w-full h-auto object-cover group-hover:scale-[1.01] transition-transform duration-300"
            loading="lazy"
          />
          <div className="absolute inset-0 bg-black/0 group-hover:bg-black/5 transition-colors flex items-center justify-center">
            <span className="opacity-0 group-hover:opacity-100 bg-black/75 text-white text-[11px] font-semibold px-3 py-1.5 rounded-full backdrop-blur-md transition-opacity shadow-lg">
              🔍 {lang === "TR" ? "Büyütmek için tıklayın" : lang === "RU" ? "Нажмите для увеличения" : lang === "SR_LAT" || lang === "SR_CYR" ? "Kliknite za uvećanje" : "Click to enlarge"}
            </span>
          </div>
        </div>
      </div>

      {/* Lightbox / Zoom Modal */}
      {isZoomed && (
        <div 
          className="fixed inset-0 z-50 bg-black/80 backdrop-blur-md flex items-center justify-center p-4 cursor-zoom-out animate-fadeIn"
          onClick={() => setIsZoomed(false)}
        >
          <div className="relative max-w-5xl w-full max-h-[90vh] flex flex-col items-center">
            <button 
              onClick={() => setIsZoomed(false)}
              className="absolute -top-10 right-0 text-white font-bold text-sm bg-white/20 hover:bg-white/30 px-3 py-1 rounded-full backdrop-blur-md transition-colors"
            >
              ✕ {lang === "TR" ? "Kapat" : lang === "RU" ? "Закрыть" : lang === "SR_LAT" || lang === "SR_CYR" ? "Zatvori" : "Close"}
            </button>
            <img 
              src={currentInfographic} 
              alt={t("how_it_works_title")} 
              className="w-full h-auto max-h-[85vh] object-contain rounded-xl shadow-2xl"
            />
          </div>
        </div>
      )}

      {/* Control & Step Selection Bar */}
      <div className="bg-white/80 backdrop-blur-[16px] border border-gray-200 rounded-2xl p-3.5 mb-6 shadow-sm">
        <div className="flex flex-col sm:flex-row items-center justify-between gap-2.5">

          {/* ── Main step navigator ── */}
          <div className="flex flex-col items-center gap-1.5 w-full sm:w-auto">

            {/* Row 1: Main dots 1-6 */}
            <div className="flex items-center gap-1.5 justify-center">
              {[1, 2, 3, 4, 5, 6].map((main) => {
                const isActive = activeMain === main;
                const isPast  = activeMain > main;
                const hasSubs = main === 4 || main === 5;
                return (
                  <button
                    key={main}
                    onClick={() => goToMain(main)}
                    title={`Step ${main}`}
                    className={`flex-shrink-0 w-7 h-7 rounded-full text-[11px] font-bold transition-all duration-200 flex items-center justify-center gap-0.5
                      ${isActive
                        ? "bg-brand-blue text-white shadow-md shadow-brand-blue/30 scale-105"
                        : isPast
                        ? "bg-brand-blue/15 text-brand-blue hover:bg-brand-blue/25"
                        : "bg-gray-100 text-gray-500 hover:bg-gray-200"
                      }`}
                  >
                    {main}
                  </button>
                );
              })}
            </div>

            {/* Row 2: Sub-step dots — only shown when step 4 or 5 is active */}
            {(activeMain === 4 || activeMain === 5) && (
              <div className="flex items-center gap-1 justify-center animate-fadeIn">
                {(activeMain === 4
                  ? [["4a",0],["4b",1],["4c",2]]
                  : [["5a",0],["5b",1],["5c",2]]
                ).map(([label, sub]) => {
                  const idx = (activeMain === 4 ? 3 : 6) + (sub as number);
                  return (
                    <button
                      key={label as string}
                      onClick={() => goToSub(activeMain, sub as number)}
                      className={`flex-shrink-0 w-9 h-5 rounded-full text-[10px] font-bold transition-all duration-200 flex items-center justify-center
                        ${currentStep === idx
                          ? activeMain === 4
                            ? "bg-amber-500 text-white shadow-sm scale-105"
                            : "bg-sky-500 text-white shadow-sm scale-105"
                          : currentStep > idx
                          ? activeMain === 4
                            ? "bg-amber-100 text-amber-700 hover:bg-amber-200"
                            : "bg-sky-100 text-sky-700 hover:bg-sky-200"
                          : "bg-gray-100 text-gray-500 hover:bg-gray-200"
                        }`}
                    >
                      {label as string}
                    </button>
                  );
                })}
              </div>
            )}
          </div>

          {/* Navigation Controls */}
          <div className="flex items-center gap-2 w-full sm:w-auto justify-between sm:justify-end border-t sm:border-t-0 pt-2 sm:pt-0 border-gray-100">
            <button
              onClick={() => setIsPlaying(!isPlaying)}
              className="inline-flex items-center gap-1 px-2.5 py-1 rounded-xl border border-gray-200 bg-gray-50 hover:bg-gray-100 text-gray-700 text-xs font-semibold transition-colors"
            >
              {isPlaying ? <Pause className="w-3.5 h-3.5" /> : <Play className="w-3.5 h-3.5" />}
              {isPlaying ? t("flow_btn_pause") : t("flow_btn_play")}
            </button>
            <div className="flex items-center gap-1">
              <button
                onClick={() => {
                  handlePrev();
                  setIsPlaying(false);
                }}
                className="w-7 h-7 rounded-xl border border-gray-200 bg-white hover:bg-gray-50 flex items-center justify-center text-gray-700 transition-colors"
                aria-label="Previous step"
              >
                <ChevronLeft className="w-4 h-4" />
              </button>
              <button
                onClick={() => {
                  handleNext();
                  setIsPlaying(false);
                }}
                className="w-7 h-7 rounded-xl border border-gray-200 bg-white hover:bg-gray-50 flex items-center justify-center text-gray-700 transition-colors"
                aria-label="Next step"
              >
                <ChevronRight className="w-4 h-4" />
              </button>
            </div>
          </div>
        </div>

        {/* Current Step Description Card */}
        <div className="mt-2.5 pt-2.5 border-t border-gray-150 flex flex-col sm:flex-row sm:items-center justify-between gap-1.5">
          <div className="flex items-start gap-2">
            <div className={`min-w-[22px] h-5 rounded-md font-bold flex items-center justify-center text-[10px] flex-shrink-0 mt-0.5 px-1
              ${currentStep >= 3 && currentStep <= 5
                ? "bg-amber-100 text-amber-700"
                : currentStep >= 6 && currentStep <= 8
                ? "bg-blue-100 text-blue-700"
                : currentStep === 9
                ? "bg-rose-100 text-rose-700"
                : "bg-brand-blue/10 text-brand-blue"}`}>
              {getStepLabel(currentStep)}
            </div>
            <div>
              <h3 className="text-xs font-bold text-gray-900">
                {t(`${stepKey}_title`)}
              </h3>
              <p className="text-[11px] text-gray-600 leading-snug mt-0.5">
                {t(`${stepKey}_desc`)}
              </p>
            </div>
          </div>
          <span className="text-[10px] font-semibold text-gray-400 self-end sm:self-center flex-shrink-0">
            {currentStep + 1} / {TOTAL_STEPS}
          </span>
        </div>
      </div>

      {/* Dual Phone Screenshots Container */}
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-6 sm:gap-8 items-start justify-items-center w-full">
        {/* Left Side: Landlord Phone Frame */}
        <div className="flex flex-col items-center w-full max-w-[250px] sm:max-w-[260px]">
          <div className="flex items-center gap-1.5 mb-2.5">
            <span className="w-2 h-2 rounded-full bg-brand-blue animate-pulse" />
            <h4 className="text-[11px] font-bold text-gray-900 uppercase tracking-wider">
              {t("role_landlord_badge")}
            </h4>
          </div>

          <div className="relative w-full bg-slate-950 border-[8px] border-slate-900 rounded-[46px] shadow-[0_25px_60px_-15px_rgba(15,23,42,0.35)] overflow-hidden transition-all duration-300 ring-1 ring-slate-800/80">
            {/* Hardware Side Buttons */}
            <div className="absolute -left-[11px] top-20 w-[3px] h-7 bg-slate-700/80 rounded-l-sm z-30" />
            <div className="absolute -left-[11px] top-30 w-[3px] h-7 bg-slate-700/80 rounded-l-sm z-30" />
            <div className="absolute -right-[11px] top-24 w-[3px] h-11 bg-slate-700/80 rounded-r-sm z-30" />

            {/* Dynamic Island / Notch */}
            <div className="absolute top-2 left-1/2 -translate-x-1/2 w-20 h-4 bg-black rounded-full z-30 flex items-center justify-between px-2.5 shadow-sm border border-slate-900/50">
              <div className="w-2 h-2 rounded-full bg-slate-900 border border-slate-800 flex items-center justify-center">
                <div className="w-1 h-1 bg-blue-900/60 rounded-full" />
              </div>
              <div className="w-1.5 h-1.5 rounded-full bg-slate-900 border border-slate-800" />
            </div>

            {/* Status Bar */}
            <div className="pt-3 px-4 pb-1.5 flex justify-between items-center text-[10px] font-bold text-gray-800 z-20 relative bg-white border-b border-gray-100">
              <span className="font-semibold tracking-tight">09:41</span>
              <div className="flex items-center gap-1.5 text-gray-700">
                <Signal className="w-3 h-3" />
                <Wifi className="w-3 h-3" />
                <Battery className="w-3.5 h-3.5 text-gray-800" />
              </div>
            </div>

            {/* App Top Header Bar */}
            <div className="px-3.5 py-2 bg-white border-b border-gray-100 flex items-center justify-between shadow-xs">
              <div className="flex items-center gap-1.5">
                <img src="/assets/logo.png" alt="Stanomer" className="w-3.5 h-3.5 object-contain" />
                <span className="text-xs font-bold text-gray-900">Stanomer</span>
              </div>
              <span className="text-[9px] bg-blue-50 text-blue-700 px-2 py-0.5 rounded-full font-bold border border-blue-100">
                {t("mockup_landlord_badge")}
              </span>
            </div>

            {/* Simulated Phone Screen Viewport (19.5:9 ratio viewport) */}
            <div className="bg-slate-50 p-3.5 h-[450px] overflow-y-auto flex flex-col justify-start gap-3 relative scrollbar-none">
              {renderLandlordContent(currentStep, t)}
            </div>

            {/* Home Indicator Bar */}
            <div className="py-2 bg-white flex justify-center border-t border-gray-100">
              <div className="w-24 h-1 bg-gray-300 rounded-full" />
            </div>
          </div>
        </div>

        {/* Right Side: Tenant Phone Frame */}
        <div className="flex flex-col items-center w-full max-w-[250px] sm:max-w-[260px]">
          <div className="flex items-center gap-1.5 mb-2.5">
            <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
            <h4 className="text-[11px] font-bold text-gray-900 uppercase tracking-wider">
              {t("role_tenant_badge")}
            </h4>
          </div>

          <div className="relative w-full bg-slate-950 border-[8px] border-slate-900 rounded-[46px] shadow-[0_25px_60px_-15px_rgba(16,185,129,0.2)] overflow-hidden transition-all duration-300 ring-1 ring-slate-800/80">
            {/* Hardware Side Buttons */}
            <div className="absolute -left-[11px] top-20 w-[3px] h-7 bg-slate-700/80 rounded-l-sm z-30" />
            <div className="absolute -left-[11px] top-30 w-[3px] h-7 bg-slate-700/80 rounded-l-sm z-30" />
            <div className="absolute -right-[11px] top-24 w-[3px] h-11 bg-slate-700/80 rounded-r-sm z-30" />

            {/* Dynamic Island / Notch */}
            <div className="absolute top-2 left-1/2 -translate-x-1/2 w-20 h-4 bg-black rounded-full z-30 flex items-center justify-between px-2.5 shadow-sm border border-slate-900/50">
              <div className="w-2 h-2 rounded-full bg-slate-900 border border-slate-800 flex items-center justify-center">
                <div className="w-1 h-1 bg-emerald-900/60 rounded-full" />
              </div>
              <div className="w-1.5 h-1.5 rounded-full bg-slate-900 border border-slate-800" />
            </div>

            {/* Status Bar */}
            <div className="pt-3 px-4 pb-1.5 flex justify-between items-center text-[10px] font-bold text-gray-800 z-20 relative bg-white border-b border-gray-100">
              <span className="font-semibold tracking-tight">09:41</span>
              <div className="flex items-center gap-1.5 text-gray-700">
                <Signal className="w-3 h-3" />
                <Wifi className="w-3 h-3" />
                <Battery className="w-3.5 h-3.5 text-gray-800" />
              </div>
            </div>

            {/* App Top Header Bar */}
            <div className="px-3.5 py-2 bg-white border-b border-gray-100 flex items-center justify-between shadow-xs">
              <div className="flex items-center gap-1.5">
                <img src="/assets/logo.png" alt="Stanomer" className="w-3.5 h-3.5 object-contain" />
                <span className="text-xs font-bold text-gray-900">Stanomer</span>
              </div>
              <span className="text-[9px] bg-emerald-50 text-emerald-700 px-2 py-0.5 rounded-full font-bold border border-emerald-100">
                {t("mockup_tenant_badge")}
              </span>
            </div>

            {/* Simulated Phone Screen Viewport (19.5:9 ratio viewport) */}
            <div className="bg-slate-50 p-3.5 h-[450px] overflow-y-auto flex flex-col justify-start gap-3 relative scrollbar-none">
              {renderTenantContent(currentStep, t)}
            </div>

            {/* Home Indicator Bar */}
            <div className="py-2 bg-white flex justify-center border-t border-gray-100">
              <div className="w-24 h-1 bg-gray-300 rounded-full" />
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}

function renderLandlordContent(step: number, t: (k: string) => string) {
  switch (step) {
    // ─── Step 1: Property Entry ──────────────────────────────────────
    case 0:
      return (
        <div className="space-y-2.5 animate-fadeIn my-auto">
          <div className="bg-white border border-gray-200 rounded-xl p-3 shadow-sm">
            <div className="flex items-center justify-between mb-1.5">
              <span className="text-xs font-bold text-gray-900 flex items-center gap-1.5">
                <Building className="w-3.5 h-3.5 text-brand-blue" />
                Beograd Daire 12
              </span>
              <span className="text-[9px] bg-blue-100 text-blue-700 font-bold px-1.5 py-0.5 rounded">
                {t("mockup_new_property")}
              </span>
            </div>
            <div className="text-[11px] text-gray-600 space-y-0.5">
              <p>{t("mockup_address")}</p>
              <p className="font-semibold text-gray-900">{t("mockup_rent_amount")}</p>
              <p className="text-[10px] text-gray-500">{t("mockup_contract_start")}</p>
            </div>
          </div>
          <div className="bg-blue-50 border-2 border-blue-400 rounded-xl p-2.5 text-center animate-pulse ring-2 ring-blue-400/60 shadow-[0_0_12px_rgba(59,130,246,0.25)]">
            <p className="text-xs text-blue-900 font-semibold mb-1.5">
              {t("mockup_contract_saved")}
            </p>
            <div className="inline-flex items-center gap-1 text-[10px] font-bold text-brand-blue bg-white px-2.5 py-1 rounded-lg border border-blue-200 shadow-sm">
              <QrCode className="w-3 h-3" />
              {t("mockup_generate_code")}
            </div>
          </div>
        </div>
      );

    // ─── Step 2: QR Invite ───────────────────────────────────────────
    case 1:
      return (
        <div className="space-y-2.5 animate-fadeIn text-center my-auto">
          <div className="bg-white border-2 border-brand-blue rounded-xl p-3 shadow-md animate-pulse ring-2 ring-blue-400/60">
            <h4 className="text-xs font-bold text-gray-800 mb-0.5">{t("mockup_qr_title")}</h4>
            <p className="text-[10px] text-gray-500 mb-2">{t("mockup_qr_subtitle")}</p>
            <div className="w-28 h-28 mx-auto bg-white border-2 border-brand-blue/30 rounded-xl p-2 flex flex-col items-center justify-center shadow-inner">
              <div className="w-full h-full bg-slate-900 rounded-lg flex items-center justify-center text-white p-2">
                <QrCode className="w-14 h-14 text-blue-400" />
              </div>
            </div>
            <p className="text-[9px] text-gray-400 mt-1.5 font-mono">stanomer.com/invite?token=c98a72f</p>
          </div>
          <button className="w-full py-1.5 bg-brand-blue text-white rounded-xl text-xs font-bold shadow-sm animate-bounce">
            {t("mockup_share")}
          </button>
        </div>
      );

    // ─── Step 3: Tenant Connected ────────────────────────────────────
    case 2:
      return (
        <div className="space-y-2.5 animate-fadeIn my-auto">
          <div className="bg-emerald-50 border-2 border-emerald-400 rounded-xl p-3 animate-pulse ring-2 ring-emerald-400/60 shadow-[0_0_12px_rgba(16,185,129,0.25)]">
            <div className="flex items-center gap-1.5 text-emerald-800 font-bold text-xs mb-1">
              <UserCheck className="w-3.5 h-3.5 text-emerald-600" />
              {t("mockup_tenant_opened")}
            </div>
            <p className="text-[11px] text-emerald-700">{t("mockup_tenant_joined_desc")}</p>
          </div>
          <div className="bg-white border border-gray-200 rounded-xl p-3 shadow-sm">
            <div className="flex items-center justify-between text-xs mb-1.5">
              <span className="font-bold text-gray-800">{t("mockup_active_contract")}</span>
              <span className="text-[9px] bg-emerald-100 text-emerald-700 font-bold px-1.5 py-0.5 rounded">{t("mockup_status_approved")}</span>
            </div>
            <div className="text-[11px] text-gray-600 space-y-0.5">
              <p>Kiracı: Marko Jovanović</p>
              <p>Ev: Beograd Daire 12</p>
              <p className="font-semibold text-gray-900">{t("mockup_rent_amount")}</p>
            </div>
          </div>
        </div>
      );

    // ─── Step 4: Payment Plan ────────────────────────────────────────
    case 3:
      return (
        <div className="space-y-2.5 animate-fadeIn my-auto">
          <div className="flex items-center justify-between text-xs font-bold text-gray-800">
            <span className="flex items-center gap-1.5 text-[11px]">
              <Calendar className="w-3.5 h-3.5 text-brand-blue" />
              {t("mockup_receivables_schedule")}
            </span>
            <span className="text-[10px] text-brand-blue font-bold">{t("mockup_total")}</span>
          </div>
          <div className="space-y-2">
            <div className="bg-amber-50 border-2 border-amber-400 rounded-xl p-2.5 flex items-center justify-between text-[11px] animate-pulse ring-2 ring-amber-400/60 shadow-[0_0_12px_rgba(245,158,11,0.25)]">
              <div>
                <p className="font-bold text-amber-900">{t("mockup_1st_month_rent")}</p>
                <p className="text-[9px] text-amber-700">{t("mockup_due_date_august")}</p>
              </div>
              <span className="text-[9px] bg-amber-200/80 text-amber-800 font-bold px-1.5 py-0.5 rounded-md">
                {t("mockup_status_pending")}
              </span>
            </div>
            <div className="bg-white border border-gray-200 rounded-xl p-2.5 flex items-center justify-between text-[11px] opacity-75">
              <div>
                <p className="font-semibold text-gray-800">{t("mockup_2nd_month_rent")}</p>
                <p className="text-[9px] text-gray-500">{t("mockup_due_date_september")}</p>
              </div>
              <span className="text-[9px] bg-gray-100 text-gray-600 font-semibold px-1.5 py-0.5 rounded-md">
                {t("mockup_status_upcoming")}
              </span>
            </div>
          </div>
        </div>
      );

    // ─── Sub-step 5a: Tenant marks rent paid → landlord awaits ──────
    case 4:
      return (
        <div className="space-y-2.5 animate-fadeIn my-auto">
          <div className="bg-amber-50 border-2 border-amber-400 rounded-xl p-3 shadow-md animate-pulse ring-2 ring-amber-400/60 shadow-[0_0_12px_rgba(245,158,11,0.25)]">
            <div className="flex items-center justify-between mb-1">
              <span className="text-xs font-bold text-amber-900 flex items-center gap-1.5">
                <Clock className="w-3.5 h-3.5 text-amber-600" />
                {t("mockup_awaiting_approval")}
              </span>
              <span className="text-[9px] bg-amber-200 text-amber-800 font-bold px-1.5 py-0.5 rounded">
                {t("mockup_awaiting_approval")}
              </span>
            </div>
            <p className="text-[11px] text-amber-800 mb-1">{t("mockup_tenant_marked_paid")}</p>
            <p className="text-[9px] text-amber-700 italic">{t("mockup_receipt_attached")}</p>
          </div>
          <div className="bg-white border border-gray-200 rounded-xl p-2.5 text-center shadow-sm">
            <p className="text-[11px] text-gray-600">{t("mockup_check_bank_transfer")}</p>
          </div>
        </div>
      );

    // ─── Sub-step 5b: Landlord approves rent ────────────────────────
    case 5:
      return (
        <div className="space-y-2.5 animate-fadeIn my-auto">
          <div className="bg-emerald-50 border-2 border-emerald-400 rounded-xl p-3 animate-pulse ring-2 ring-emerald-400/60 shadow-[0_0_12px_rgba(16,185,129,0.25)]">
            <div className="flex items-center gap-1.5 text-emerald-900 font-bold text-xs mb-1">
              <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600" />
              {t("mockup_payment_approved_title")}
            </div>
            <p className="text-[11px] text-emerald-800">{t("mockup_payment_approved_desc")}</p>
          </div>
          <div className="bg-white border border-gray-200 rounded-xl p-2.5 flex items-center justify-between text-[11px] shadow-sm">
            <div>
              <p className="font-bold text-gray-900">{t("mockup_1st_month_rent")}</p>
              <p className="text-[9px] text-gray-500">{t("mockup_approval_time")}</p>
            </div>
            <span className="text-[9px] bg-emerald-100 text-emerald-700 font-bold px-2 py-0.5 rounded-full flex items-center gap-1">
              <CheckCircle2 className="w-3 h-3" /> {t("mockup_status_paid")}
            </span>
          </div>
        </div>
      );

    // ─── Sub-step 5c: Landlord adds utility bill ─────────────────────
    case 6:
      return (
        <div className="space-y-2.5 animate-fadeIn my-auto">
          <div className="bg-blue-50 border-2 border-blue-400 rounded-xl p-3 animate-pulse ring-2 ring-blue-400/60 shadow-[0_0_12px_rgba(59,130,246,0.25)]">
            <div className="flex items-center justify-between mb-1">
              <span className="text-xs font-bold text-blue-900 flex items-center gap-1.5">
                <Receipt className="w-3.5 h-3.5 text-brand-blue" />
                {t("mockup_bill_added")}
              </span>
              <span className="text-[9px] bg-blue-200 text-blue-800 font-bold px-1.5 py-0.5 rounded">
                {t("mockup_bill_electricity")}
              </span>
            </div>
            <div className="text-[11px] text-blue-800 space-y-0.5">
              <p className="font-bold">{t("mockup_bill_amount")}</p>
              <p className="text-[9px]">{t("mockup_due_date_august")}</p>
            </div>
          </div>
          <div className="bg-white border border-gray-200 rounded-xl p-2.5 flex items-center gap-2 text-[11px] text-gray-700 shadow-sm">
            <Bell className="w-3.5 h-3.5 text-brand-blue flex-shrink-0" />
            <span>{t("mockup_bill_notification_sent")}</span>
          </div>
        </div>
      );

    // ─── Sub-step 5d: Tenant paid bill, landlord awaits ──────────────
    case 7:
      return (
        <div className="space-y-2.5 animate-fadeIn my-auto">
          <div className="bg-amber-50 border-2 border-amber-400 rounded-xl p-3 shadow-sm animate-pulse ring-2 ring-amber-400/60">
            <div className="flex items-center justify-between mb-1">
              <span className="text-xs font-bold text-amber-900 flex items-center gap-1.5">
                <Clock className="w-3.5 h-3.5 text-amber-600" />
                {t("mockup_bill_awaiting_approval")}
              </span>
              <span className="text-[9px] bg-amber-200 text-amber-800 font-bold px-1.5 py-0.5 rounded">
                {t("mockup_awaiting_approval")}
              </span>
            </div>
            <p className="text-[11px] text-amber-800">{t("mockup_tenant_marked_bill_paid")}</p>
          </div>
          <button className="w-full py-1.5 bg-emerald-600 text-white rounded-xl text-xs font-bold shadow-sm flex items-center justify-center gap-1.5 animate-bounce">
            <CheckCircle2 className="w-3.5 h-3.5" />
            {t("mockup_approve_bill_button")}
          </button>
        </div>
      );

    // ─── Sub-step 5e: All payments done ─────────────────────────────
    case 8:
      return (
        <div className="space-y-2.5 animate-fadeIn text-center my-auto">
          <div className="bg-emerald-50 border-2 border-emerald-400 rounded-xl p-3.5 animate-pulse ring-2 ring-emerald-400/60 shadow-[0_0_12px_rgba(16,185,129,0.25)]">
            <div className="w-8 h-8 rounded-full bg-emerald-100 text-emerald-600 flex items-center justify-center mx-auto mb-1.5">
              <ShieldCheck className="w-5 h-5" />
            </div>
            <h4 className="text-xs font-bold text-emerald-900 mb-0.5">{t("mockup_all_payments_completed")}</h4>
            <p className="text-[10px] text-emerald-700 leading-snug">{t("mockup_all_payments_desc")}</p>
          </div>
          <div className="bg-white border border-gray-200 rounded-xl p-2 flex justify-between text-[11px] shadow-sm">
            <span className="text-gray-600">{t("mockup_balance")}</span>
            <span className="font-bold text-emerald-600">{t("mockup_balance_value")}</span>
          </div>
        </div>
      );

    // ─── Step 6: Maintenance — Landlord sees notification + photo ────
    case 9:
      return (
        <div className="space-y-2.5 animate-fadeIn my-auto">
          <div className="bg-rose-50 border-2 border-rose-400 rounded-xl p-3 animate-pulse ring-2 ring-rose-400/60 shadow-[0_0_12px_rgba(244,63,94,0.25)]">
            <div className="flex items-center gap-1.5 text-rose-900 font-bold text-xs mb-1.5">
              <Bell className="w-3.5 h-3.5 text-rose-500" />
              {t("mockup_maintenance_notif")}
            </div>
            {/* Fake photo thumbnail */}
            <div className="bg-white border border-rose-200 rounded-lg p-2 flex items-center gap-2 mb-2">
              <div className="w-10 h-10 rounded-md bg-rose-100 flex items-center justify-center flex-shrink-0">
                <Camera className="w-5 h-5 text-rose-400" />
              </div>
              <div className="text-[10px] text-gray-600">
                <p className="font-semibold text-gray-800">{t("mockup_maintenance_title")}</p>
                <p className="text-[9px] text-gray-500">{t("mockup_maintenance_desc")}</p>
              </div>
            </div>
            <div className="text-[9px] text-rose-700 italic">{t("mockup_maintenance_photo")}</div>
          </div>

          {/* Landlord replies */}
          <div className="bg-white border border-gray-200 rounded-xl p-2.5 shadow-sm">
            <div className="flex items-start gap-2">
              <div className="w-6 h-6 rounded-full bg-brand-blue/10 flex items-center justify-center flex-shrink-0">
                <MessageCircle className="w-3.5 h-3.5 text-brand-blue" />
              </div>
              <div>
                <p className="text-[10px] font-bold text-gray-800 mb-0.5">{t("mockup_landlord_badge")}</p>
                <p className="text-[11px] text-gray-700 bg-brand-blue/10 px-2 py-1 rounded-lg rounded-tl-none">
                  {t("mockup_maintenance_landlord_reply")}
                </p>
              </div>
            </div>
          </div>
        </div>
      );

    default:
      return null;
  }
}

function renderTenantContent(step: number, t: (k: string) => string) {
  switch (step) {
    // ─── Step 1: No property yet ─────────────────────────────────────
    case 0:
      return (
        <div className="space-y-2.5 animate-fadeIn text-center my-auto py-5">
          <div className="w-10 h-10 rounded-xl bg-gray-100 text-gray-400 flex items-center justify-center mx-auto">
            <Building className="w-5 h-5 opacity-50" />
          </div>
          <div>
            <h4 className="text-xs font-bold text-gray-700 mb-0.5">{t("mockup_tenant_no_properties_title")}</h4>
            <p className="text-[10px] text-gray-500 max-w-[190px] mx-auto leading-tight">
              {t("mockup_tenant_no_properties_desc")}
            </p>
          </div>
        </div>
      );

    // ─── Step 2: Invite arrived ──────────────────────────────────────
    case 1:
      return (
        <div className="space-y-2.5 animate-fadeIn my-auto">
          <div className="bg-blue-50 border border-blue-200 rounded-xl p-3">
            <div className="flex items-center gap-1.5 text-blue-900 font-bold text-xs mb-1.5">
              <Send className="w-3.5 h-3.5 text-brand-blue" />
              {t("mockup_tenant_invite_arrived")}
            </div>
            <p className="text-[11px] text-blue-800 mb-2">{t("mockup_tenant_invited_you")}</p>
            <div className="bg-white border border-blue-200 rounded-lg p-1.5 text-center shadow-sm">
              <span className="text-[11px] font-bold text-brand-blue">
                {t("mockup_click_link_inspect")}
              </span>
            </div>
          </div>
        </div>
      );

    // ─── Step 3: Joined ──────────────────────────────────────────────
    case 2:
      return (
        <div className="space-y-2.5 animate-fadeIn my-auto">
          <div className="bg-emerald-50 border-2 border-emerald-400 rounded-xl p-3 animate-pulse ring-2 ring-emerald-400/60 shadow-[0_0_12px_rgba(16,185,129,0.25)]">
            <div className="flex items-center justify-between mb-1">
              <span className="text-xs font-bold text-emerald-900 flex items-center gap-1.5">
                <Building className="w-3.5 h-3.5 text-emerald-600" />
                Beograd Daire 12
              </span>
              <span className="text-[9px] bg-emerald-200 text-emerald-800 font-bold px-1.5 py-0.5 rounded">
                {t("mockup_tenant_joined")}
              </span>
            </div>
            <div className="text-[11px] text-emerald-800 space-y-0.5">
              <p>{t("mockup_landlord_name")}</p>
              <p className="font-bold">{t("mockup_rent_amount")}</p>
              <p className="text-[9px] text-emerald-700">{t("mockup_payment_day_15")}</p>
            </div>
          </div>
          <div className="bg-white border border-gray-200 rounded-xl p-2 text-center text-[11px] text-gray-700 font-semibold shadow-sm">
            {t("mockup_contract_ready_phone")}
          </div>
        </div>
      );

    // ─── Step 4: Upcoming payment ────────────────────────────────────
    case 3:
      return (
        <div className="space-y-2.5 animate-fadeIn my-auto">
          <div className="flex items-center justify-between text-xs font-bold text-gray-800">
            <span className="flex items-center gap-1.5 text-[11px]">
              <Calendar className="w-3.5 h-3.5 text-emerald-600" />
              {t("mockup_upcoming_debts")}
            </span>
            <span className="text-[9px] text-amber-600 font-bold">{t("mockup_first_payment_august")}</span>
          </div>
          <div className="bg-amber-50 border-2 border-amber-400 rounded-xl p-3 animate-pulse ring-2 ring-amber-400/60 shadow-[0_0_12px_rgba(245,158,11,0.25)]">
            <div className="flex items-center justify-between mb-1.5">
              <div>
                <p className="font-bold text-amber-900 text-xs">{t("mockup_1st_month_rent")}</p>
                <p className="text-[9px] text-amber-700">{t("mockup_rent_amount")}</p>
              </div>
              <span className="text-[9px] bg-amber-200 text-amber-800 font-bold px-1.5 py-0.5 rounded-md">
                {t("mockup_payment_due_badge")}
              </span>
            </div>
            <button className="w-full mt-1 py-1.5 bg-emerald-600 text-white rounded-xl text-xs font-bold shadow-sm animate-bounce">
              {t("mockup_mark_paid_button")}
            </button>
          </div>
        </div>
      );

    // ─── Sub-step 5a: Tenant submitted payment ───────────────────────
    case 4:
      return (
        <div className="space-y-2.5 animate-fadeIn my-auto">
          <div className="bg-amber-50 border-2 border-amber-400 rounded-xl p-3 animate-pulse ring-2 ring-amber-400/60">
            <div className="flex items-center justify-between mb-1">
              <span className="text-xs font-bold text-amber-900 flex items-center gap-1.5">
                <Clock className="w-3.5 h-3.5 text-amber-600" />
                {t("mockup_tenant_payment_declared")}
              </span>
              <span className="text-[9px] bg-amber-200 text-amber-800 font-bold px-1.5 py-0.5 rounded">
                {t("mockup_awaiting_approval")}
              </span>
            </div>
            <p className="text-[11px] text-amber-800 mb-1.5">{t("mockup_tenant_rent_submitted")}</p>
            <div className="bg-white/80 border border-amber-200 rounded-lg p-1.5 text-[9px] text-gray-600 flex items-center gap-1.5">
              <Receipt className="w-3 h-3 text-amber-600" />
              {t("mockup_receipt_uploaded")}
            </div>
          </div>
        </div>
      );

    // ─── Sub-step 5b: Landlord approved rent ─────────────────────────
    case 5:
      return (
        <div className="space-y-2.5 animate-fadeIn my-auto">
          <div className="bg-emerald-50 border-2 border-emerald-400 rounded-xl p-3 animate-pulse ring-2 ring-emerald-400/60 shadow-[0_0_12px_rgba(16,185,129,0.25)]">
            <div className="flex items-center justify-between mb-1">
              <span className="text-xs font-bold text-emerald-900 flex items-center gap-1.5">
                <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600" />
                {t("mockup_landlord_approved_title")}
              </span>
              <span className="text-[9px] bg-emerald-200 text-emerald-900 font-bold px-1.5 py-0.5 rounded-full">
                {t("mockup_status_paid")}
              </span>
            </div>
            <p className="text-[11px] text-emerald-800">{t("mockup_tenant_rent_approved_desc")}</p>
          </div>
          <div className="bg-white border border-gray-200 rounded-xl p-2 flex justify-between text-[11px] text-gray-700 shadow-sm">
            <span>{t("mockup_rent_debt")}</span>
            <span className="font-bold text-emerald-600">{t("mockup_rent_debt_cleared")}</span>
          </div>
        </div>
      );

    // ─── Sub-step 5c: New bill notification ──────────────────────────
    case 6:
      return (
        <div className="space-y-2.5 animate-fadeIn my-auto">
          <div className="bg-amber-50 border-2 border-amber-400 rounded-xl p-3 shadow-md animate-pulse ring-2 ring-amber-400/60 shadow-[0_0_12px_rgba(245,158,11,0.25)]">
            <div className="flex items-center gap-1.5 text-amber-900 font-bold text-xs mb-1">
              <Bell className="w-3.5 h-3.5 text-amber-600" />
              {t("mockup_new_bill_notification")}
            </div>
            <p className="text-[11px] text-amber-800 mb-1.5">{t("mockup_landlord_added_bill")}</p>
            <div className="flex justify-between items-center bg-white p-1.5 rounded-lg border border-amber-200 text-[11px]">
              <span className="font-semibold text-gray-800">{t("mockup_bill_electricity")}</span>
              <span className="font-bold text-amber-900">€45</span>
            </div>
          </div>
        </div>
      );

    // ─── Sub-step 5d: Tenant submitted bill payment ───────────────────
    case 7:
      return (
        <div className="space-y-2.5 animate-fadeIn my-auto">
          <div className="bg-amber-50 border-2 border-amber-400 rounded-xl p-3 animate-pulse ring-2 ring-amber-400/60">
            <div className="flex items-center justify-between mb-1">
              <span className="text-xs font-bold text-amber-900 flex items-center gap-1.5">
                <Clock className="w-3.5 h-3.5 text-amber-600" />
                {t("mockup_tenant_bill_declared")}
              </span>
              <span className="text-[9px] bg-amber-200 text-amber-800 font-bold px-1.5 py-0.5 rounded">
                {t("mockup_awaiting_approval")}
              </span>
            </div>
            <p className="text-[11px] text-amber-800">{t("mockup_tenant_bill_submitted")}</p>
          </div>
        </div>
      );

    // ─── Sub-step 5e: All done ────────────────────────────────────────
    case 8:
      return (
        <div className="space-y-2.5 animate-fadeIn text-center my-auto">
          <div className="bg-emerald-50 border-2 border-emerald-400 rounded-xl p-3.5 animate-pulse ring-2 ring-emerald-400/60 shadow-[0_0_12px_rgba(16,185,129,0.25)]">
            <div className="w-8 h-8 rounded-full bg-emerald-100 text-emerald-600 flex items-center justify-center mx-auto mb-1.5">
              <CheckCircle2 className="w-5 h-5" />
            </div>
            <h4 className="text-xs font-bold text-emerald-900 mb-0.5">{t("mockup_tenant_all_current_title")}</h4>
            <p className="text-[10px] text-emerald-700 leading-snug">{t("mockup_tenant_all_current_desc")}</p>
          </div>
          <div className="bg-white border border-gray-200 rounded-xl p-2 flex justify-between text-[11px] shadow-sm">
            <span className="text-gray-600">{t("mockup_payable_debt")}</span>
            <span className="font-bold text-emerald-600">€0</span>
          </div>
        </div>
      );

    // ─── Step 6: Maintenance — Tenant reports + resolves ─────────────
    case 9:
      return (
        <div className="space-y-2.5 animate-fadeIn my-auto">
          {/* Tenant opens a new issue report */}
          <div className="bg-rose-50 border-2 border-rose-300 rounded-xl p-3 shadow-sm">
            <div className="flex items-center justify-between mb-1.5">
              <span className="text-xs font-bold text-rose-900 flex items-center gap-1.5">
                <AlertTriangle className="w-3.5 h-3.5 text-rose-500" />
                {t("mockup_maintenance_open")}
              </span>
              <span className="text-[9px] bg-rose-200 text-rose-800 font-bold px-1.5 py-0.5 rounded">
                {t("mockup_maintenance_badge")}
              </span>
            </div>
            <p className="text-[11px] text-rose-800 mb-1.5">{t("mockup_maintenance_desc")}</p>
            {/* Photo upload area */}
            <div className="bg-white border-2 border-dashed border-rose-200 rounded-lg p-2 flex items-center gap-2 mb-2">
              <div className="w-8 h-8 rounded bg-rose-50 flex items-center justify-center flex-shrink-0">
                <Camera className="w-4 h-4 text-rose-400" />
              </div>
              <p className="text-[9px] text-rose-600 font-medium">{t("mockup_maintenance_photo")}</p>
            </div>
          </div>

          {/* Landlord's reply visible to tenant */}
          <div className="bg-white border border-gray-200 rounded-xl p-2.5 shadow-sm">
            <div className="flex items-start gap-2 mb-2">
              <div className="w-5 h-5 rounded-full bg-brand-blue/10 flex items-center justify-center flex-shrink-0 mt-0.5">
                <Wrench className="w-3 h-3 text-brand-blue" />
              </div>
              <p className="text-[11px] text-gray-700 bg-brand-blue/10 px-2 py-1 rounded-lg rounded-tl-none">
                {t("mockup_maintenance_landlord_reply")}
              </p>
            </div>
            {/* Resolve button */}
            <button className="w-full py-1.5 bg-emerald-600 text-white rounded-xl text-[10px] font-bold shadow-sm flex items-center justify-center gap-1.5 animate-bounce">
              <CheckCircle2 className="w-3 h-3" />
              {t("mockup_maintenance_resolved_btn")}
            </button>
          </div>
        </div>
      );

    default:
      return null;
  }
}
