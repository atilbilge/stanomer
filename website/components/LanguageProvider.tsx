"use client";

import React, { createContext, useContext, useState, useEffect } from "react";
import translations from "../lib/translations.json";

type Language = "TR" | "EN" | "SR_LAT" | "SR_CYR";

interface LanguageContextType {
  lang: Language;
  setLang: (lang: Language) => void;
  t: (key: string) => string;
}

const LanguageContext = createContext<LanguageContextType | undefined>(undefined);

export function LanguageProvider({ children }: { children: React.ReactNode }) {
  const [lang, setLang] = useState<Language>("TR");

  useEffect(() => {
    const saved = localStorage.getItem("stanomer_lang") as Language;
    if (saved && ["TR", "EN", "SR_LAT", "SR_CYR"].includes(saved)) {
      setLang(saved);
    }
  }, []);

  const handleSetLang = (newLang: Language) => {
    setLang(newLang);
    localStorage.setItem("stanomer_lang", newLang);
  };

  const t = (key: string) => {
    // @ts-ignore
    return translations[lang][key] || key;
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
