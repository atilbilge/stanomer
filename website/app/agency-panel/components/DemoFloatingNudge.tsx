"use client";

import React, { useState, useEffect } from "react";
import { X, Sparkles, ArrowRight } from "lucide-react";
import { useLanguage } from "../../../components/LanguageProvider";

interface DemoFloatingNudgeProps {
  isVisible: boolean;
  onOpenVerification: () => void;
  onDismiss: () => void;
}

export default function DemoFloatingNudge({
  isVisible,
  onOpenVerification,
  onDismiss,
}: DemoFloatingNudgeProps) {
  const { t } = useLanguage();

  if (!isVisible) return null;

  return (
    <div
      role="complementary"
      aria-label={t("demo_nudge_title")}
      className="fixed bottom-4 right-4 sm:bottom-6 sm:right-6 z-40 max-w-sm w-[calc(100vw-2rem)] sm:w-96 bg-white rounded-[12px] shadow-[0_8px_30px_rgb(0,0,0,0.12)] border border-[#E5E3DF] p-4 sm:p-5 space-y-3 animate-in slide-in-from-bottom-5 fade-in duration-300"
    >
      <div className="flex items-start justify-between gap-3">
        <div className="flex items-center gap-2.5">
          <div className="w-8 h-8 rounded-lg bg-[#E5EEF6] text-[#1B5888] flex items-center justify-center shrink-0 border border-[#1B5888]/20">
            <Sparkles className="w-4 h-4" />
          </div>
          <h4 className="text-xs font-bold text-[#1A1A1A] tracking-tight">
            {t("demo_nudge_title")}
          </h4>
        </div>

        <button
          type="button"
          onClick={onDismiss}
          className="text-[#8A8A8A] hover:text-[#1A1A1A] p-1 rounded-md transition-colors cursor-pointer"
          aria-label={t("close")}
        >
          <X className="w-4 h-4" />
        </button>
      </div>

      <p className="text-xs text-[#666666] leading-relaxed">
        {t("demo_nudge_text")}
      </p>

      <div className="pt-1 flex items-center gap-2">
        <button
          type="button"
          onClick={() => {
            onOpenVerification();
            onDismiss();
          }}
          className="flex-1 py-2 px-3 rounded-[8px] bg-[#1B5888] hover:bg-[#12406A] active:bg-[#12406A] text-white text-xs font-bold transition-colors flex items-center justify-center gap-1.5 cursor-pointer shadow-2xs"
        >
          <span>{t("demo_nudge_btn_save")}</span>
          <ArrowRight className="w-3.5 h-3.5" />
        </button>

        <button
          type="button"
          onClick={onDismiss}
          className="py-2 px-3 rounded-[8px] border border-[#E5E3DF] text-[#666666] hover:text-[#1A1A1A] hover:bg-[#F8F7F5] text-xs font-semibold transition-colors cursor-pointer"
        >
          {t("demo_nudge_btn_later")}
        </button>
      </div>
    </div>
  );
}
