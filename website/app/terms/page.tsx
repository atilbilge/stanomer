"use client";

import { LanguageProvider } from "../../components/LanguageProvider";
import { LegalLayout } from "../../components/LegalLayout";
import { useLanguage } from "../../components/LanguageProvider";

function TermsContent() {
  const { t } = useLanguage();

  return (
    <div className="prose prose-blue max-w-none">
      <h1 className="text-3xl md:text-4xl font-extrabold text-brand-blue mb-8">
        {t("terms_title")}
      </h1>
      
      <div className="whitespace-pre-wrap text-gray-700 leading-relaxed space-y-4">
        {t("eula_content")}
      </div>
    </div>
  );
}

export default function TermsPage() {
  return (
    <LanguageProvider>
      <LegalLayout activeTab="terms">
        <TermsContent />
      </LegalLayout>
    </LanguageProvider>
  );
}
