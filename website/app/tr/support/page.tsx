"use client";

import React, { useEffect } from "react";
import SupportPage from "../../support/page";
import { LanguageProvider, useLanguage } from "../../../components/LanguageProvider";

/**
 * Localized wrapper for /tr/support/
 * This component ensures that when someone enters via /tr/spport,
 * the language state is forced to TR.
 */
function TrSupportInner() {
  const { setLang } = useLanguage();

  useEffect(() => {
    // Force language to TR when landing on this specific URL
    setLang("TR");
  }, [setLang]);

  return <SupportPage />;
}

export default function TrSupportPage() {
  return (
    <LanguageProvider>
      <TrSupportInner />
    </LanguageProvider>
  );
}
