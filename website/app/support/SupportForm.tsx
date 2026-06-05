"use client";

import React, { useState, useEffect } from "react";
import { useLanguage } from "../../components/LanguageProvider";
import { Send, CheckCircle2, AlertCircle, Shield } from "lucide-react";
import { cn } from "../../lib/utils";

export function SupportForm() {
  const { t } = useLanguage();
  const [isPending, setIsPending] = useState(false);
  const [result, setResult] = useState<{ success: boolean; message: string } | null>(null);

  const [captcha, setCaptcha] = useState<{ num1: number; num2: number } | null>(null);

  useEffect(() => {
    setCaptcha({ 
      num1: Math.floor(Math.random() * 10), 
      num2: Math.floor(Math.random() * 10) 
    });
  }, []);

  async function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const formData = new FormData(e.currentTarget);
    
    // Honeypot check
    if (formData.get("website")) return;

    // Captcha check
    if (!captcha) return;
    const userAnswer = parseInt(formData.get("captcha_answer") as string);
    if (userAnswer !== captcha.num1 + captcha.num2) {
      setResult({ success: false, message: t("captcha_error") });
      return;
    }

    setIsPending(true);
    setResult(null);

    try {
      const response = await fetch("/api/notion/", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          subject: formData.get("subject"),
          email: formData.get("email"),
          category: formData.get("category"),
          message: formData.get("message"),
        }),
      });

      const data = await response.json();

      setIsPending(false);
      if (data.success) {
        setResult({ success: true, message: t("success_msg") });
        (e.target as HTMLFormElement).reset();
      } else {
        setResult({ success: false, message: t("error_msg") });
      }
    } catch (error) {
      setIsPending(false);
      setResult({ success: false, message: t("error_msg") });
    }
  }

  if (result?.success) {
    return (
      <div className="bg-emerald-50 border border-emerald-200 rounded-2xl p-8 text-center animate-in zoom-in-95 duration-300">
        <CheckCircle2 className="w-12 h-12 text-emerald-600 mx-auto mb-4" />
        <h3 className="text-xl font-bold text-emerald-900 mb-2">{t("success_msg")}</h3>
        <button 
          onClick={() => {
            setResult(null);
            setCaptcha({ num1: Math.floor(Math.random() * 10), num2: Math.floor(Math.random() * 10) });
          }}
          className="text-emerald-600 font-semibold hover:underline"
        >
          {t("send")}
        </button>
      </div>
    );
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-6">
      {/* Honeypot field (hidden from users) */}
      <input type="text" name="website" className="hidden" tabIndex={-1} autoComplete="off" />

      {result?.success === false && (
        <div className="bg-red-50 border border-red-200/60 rounded-xl p-4 flex items-center gap-3 text-red-900 text-sm">
          <AlertCircle className="w-5 h-5 flex-shrink-0 text-red-500" />
          <p>{result.message}</p>
        </div>
      )}

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div className="space-y-2">
          <label className="text-sm font-bold text-gray-700 ml-1">{t("subject")}</label>
          <input
            required
            name="subject"
            type="text"
            placeholder={t("subject")}
            className="w-full px-4 py-3 rounded-xl border border-gray-200 bg-white text-gray-900 focus:border-brand-blue focus:ring-4 focus:ring-brand-blue/5 transition-all outline-none shadow-sm"
          />
        </div>

        <div className="space-y-2">
          <label className="text-sm font-bold text-gray-700 ml-1">{t("email")}</label>
          <input
            required
            name="email"
            type="email"
            placeholder="example@mail.com"
            className="w-full px-4 py-3 rounded-xl border border-gray-200 bg-white text-gray-900 focus:border-brand-blue focus:ring-4 focus:ring-brand-blue/5 transition-all outline-none shadow-sm"
          />
        </div>
      </div>

      <div className="space-y-2">
        <label className="text-sm font-bold text-gray-700 ml-1">{t("category")}</label>
        <select
          name="category"
          className="w-full px-4 py-3 rounded-xl border border-gray-200 bg-white text-gray-900 focus:border-brand-blue focus:ring-4 focus:ring-brand-blue/5 transition-all outline-none appearance-none shadow-sm"
        >
          <option value="Support" className="bg-white text-gray-900">{t("cat_support")}</option>
          <option value="Bug" className="bg-white text-gray-900">{t("cat_bug")}</option>
          <option value="Other" className="bg-white text-gray-900">{t("cat_other")}</option>
        </select>
      </div>

      <div className="space-y-2">
        <label className="text-sm font-bold text-gray-700 ml-1">{t("message")}</label>
        <textarea
          required
          name="message"
          rows={4}
          placeholder={t("message")}
          className="w-full px-4 py-3 rounded-xl border border-gray-200 bg-white text-gray-900 focus:border-brand-blue focus:ring-4 focus:ring-brand-blue/5 transition-all outline-none resize-none shadow-sm"
        />
      </div>

      {/* Captcha Section */}
      <div className="p-4 bg-gray-50 border border-gray-200 rounded-2xl flex flex-col sm:flex-row items-center gap-4">
        <div className="flex items-center gap-3">
          <Shield className="w-5 h-5 text-brand-blue" />
          <span className="text-sm font-bold text-gray-700">{t("captcha_label")}:</span>
          <span className="px-3 py-1 bg-white border border-gray-200 rounded-lg font-mono font-bold text-brand-blue min-w-[80px] text-center shadow-sm">
            {captcha ? `${captcha.num1} + ${captcha.num2} = ?` : "..."}
          </span>
        </div>
        <input
          required
          name="captcha_answer"
          type="number"
          placeholder={t("captcha_placeholder")}
          className="w-full sm:w-32 px-4 py-2 rounded-xl border border-gray-200 bg-white text-gray-900 focus:border-brand-blue focus:ring-4 focus:ring-brand-blue/5 transition-all outline-none shadow-sm"
        />
      </div>

      <button
        type="submit"
        disabled={isPending}
        className={cn(
          "w-full md:w-auto px-10 py-4 bg-gray-900 text-white rounded-xl font-bold flex items-center justify-center gap-2 transition-all hover:bg-black active:scale-[0.98] disabled:opacity-50 disabled:pointer-events-none shadow-sm",
          isPending && "animate-pulse"
        )}
      >
        {isPending ? t("sending") : (
          <>
            {t("send")}
            <Send className="w-4 h-4" />
          </>
        )}
      </button>
    </form>
  );
}
