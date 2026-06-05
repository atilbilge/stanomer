"use client";

import React from "react";
import { LanguageProvider } from "../../components/LanguageProvider";
import { SupportContent } from "./SupportContent";

export default function SupportPage() {
  return (
    <LanguageProvider>
      <SupportContent />
    </LanguageProvider>
  );
}
