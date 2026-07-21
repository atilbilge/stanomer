"use client";

import React, { createContext, useContext, useState, useEffect } from "react";
import translations from "../lib/translations.json";

export type Language = "TR" | "EN" | "SR_LAT" | "SR_CYR" | "RU";

interface LanguageContextType {
  lang: Language;
  setLang: (lang: Language) => void;
  t: (key: string) => string;
}

const LanguageContext = createContext<LanguageContextType | undefined>(undefined);

export function LanguageProvider({ children }: { children: React.ReactNode }) {
  const [lang, setLang] = useState<Language>("TR");
  const [isMounted, setIsMounted] = useState(false);

  useEffect(() => {
    setIsMounted(true);
    try {
      // 1. Check URL query param (?lang=EN or ?lang=SR_LAT)
      const params = new URLSearchParams(window.location.search);
      const urlLangRaw = params.get("lang") || params.get("locale");
      if (urlLangRaw) {
        const urlLang = urlLangRaw.toUpperCase().replace("-", "_") as Language;
        if (["TR", "EN", "SR_LAT", "SR_CYR", "RU"].includes(urlLang)) {
          setLang(urlLang);
          localStorage.setItem("stanomer_lang", urlLang);
          return;
        }
      }

      // 2. Check localStorage
      const saved = localStorage.getItem("stanomer_lang") as Language;
      if (saved && ["TR", "EN", "SR_LAT", "SR_CYR", "RU"].includes(saved)) {
        setLang(saved);
        return;
      }

      // 3. Fallback to browser language
      const navLang = (window.navigator.language || "").toLowerCase();
      if (navLang.startsWith("sr")) {
        setLang("SR_LAT");
      } else if (navLang.startsWith("ru")) {
        setLang("RU");
      } else if (navLang.startsWith("en")) {
        setLang("EN");
      } else {
        setLang("TR");
      }
    } catch (e) {
      console.error("LanguageProvider initialization error:", e);
    }
  }, []);

  const handleSetLang = (newLang: Language) => {
    setLang(newLang);
    try {
      localStorage.setItem("stanomer_lang", newLang);
    } catch (e) {
      console.error("Failed to save language to localStorage:", e);
    }
  };

  const t = (key: string): string => {
    // @ts-ignore
    const langDict = translations[lang];
    if (langDict && langDict[key] !== undefined) {
      return langDict[key];
    }
    // Fallback to TR dictionary
    // @ts-ignore
    const trDict = translations["TR"];
    if (trDict && trDict[key] !== undefined) {
      return trDict[key];
    }
    return key;
  };

  return (
    <LanguageContext.Provider value={{ lang, setLang: handleSetLang, t }}>
      {children}
    </LanguageContext.Provider>
  );
}

export function useLanguage() {
  const context = useContext(LanguageContext);
  if (!context) throw new Error("useLanguage must be used within LanguageProvider");
  return context;
}
