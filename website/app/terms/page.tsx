"use client";

import { LanguageProvider } from "../../components/LanguageProvider";
import { LegalLayout } from "../../components/LegalLayout";
import { useLanguage } from "../../components/LanguageProvider";

function TermsContent() {
  const { t } = useLanguage();

  return (
    <div className="prose prose-blue max-w-none">
      <h1 className="text-4xl md:text-5xl font-extrabold text-brand-blue mb-8">
        {t("terms_title")}
      </h1>
      
      <p className="text-xl text-gray-600 mb-12 font-medium leading-relaxed">
        {t("intro")}
      </p>

      <div className="space-y-12">
        <section>
          <h2 className="text-2xl font-bold text-gray-900 mb-4 flex items-center gap-3">
            <span className="w-1.5 h-8 bg-brand-green rounded-full"></span>
            {t("terms_title")}
          </h2>
          <div className="pl-5 space-y-4 text-gray-700 leading-relaxed">
            <p>{t("legal")}</p>
            <p>{t("intro")}</p>
          </div>
        </section>

        <section>
          <h2 className="text-2xl font-bold text-gray-900 mb-4 flex items-center gap-3">
            <span className="w-1.5 h-8 bg-brand-blue rounded-full"></span>
            {t("data_collect")}
          </h2>
          <div className="pl-5 text-gray-700 leading-relaxed space-y-4">
            <p>{t("data_collect")}</p>
            <p>{t("storage")}</p>
          </div>
        </section>

        <section>
          <h2 className="text-2xl font-bold text-gray-900 mb-4 flex items-center gap-3">
            <span className="w-1.5 h-8 bg-gray-200 rounded-full"></span>
            {t("rights")}
          </h2>
          <div className="pl-5 text-gray-700 leading-relaxed">
            <p>{t("rights")}</p>
          </div>
        </section>
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
