"use client";

import { LanguageProvider } from "../../components/LanguageProvider";
import { LegalLayout } from "../../components/LegalLayout";
import { useLanguage } from "../../components/LanguageProvider";

function PrivacyContent() {
  const { t } = useLanguage();

  return (
    <div className="prose prose-blue max-w-none">
      <h1 className="text-[30px] font-bold text-brand-blue mb-6">
        {t("privacy_title")}
      </h1>
      
      <p className="text-[15px] text-gray-600 mb-10 font-medium leading-relaxed">
        {t("intro")}
      </p>

      <div className="space-y-10">
        <section>
          <h2 className="text-[18px] font-bold text-gray-900 mb-4 flex items-center gap-3">
            <span className="w-1.5 h-6 bg-brand-green rounded-full"></span>
            {t("privacy_title")}
          </h2>
          <div className="pl-5 space-y-3 text-[14px] text-gray-700 leading-relaxed">
            <p>{t("data_collect")}</p>
            <p>{t("storage")}</p>
          </div>
        </section>

        <section>
          <h2 className="text-[18px] font-bold text-gray-900 mb-4 flex items-center gap-3">
            <span className="w-1.5 h-6 bg-brand-blue rounded-full"></span>
            {t("rights")}
          </h2>
          <div className="pl-5 text-[14px] text-gray-700 leading-relaxed">
            <p>{t("rights")}</p>
          </div>
        </section>

        <section>
          <h2 className="text-[18px] font-bold text-gray-900 mb-4 flex items-center gap-3">
            <span className="w-1.5 h-6 bg-gray-200 rounded-full"></span>
            {t("legal")}
          </h2>
          <div className="pl-5 text-[14px] text-gray-700 leading-relaxed">
            <p>{t("legal")}</p>
          </div>
        </section>
      </div>
    </div>
  );
}

export default function PrivacyPage() {
  return (
    <LanguageProvider>
      <LegalLayout activeTab="privacy">
        <PrivacyContent />
      </LegalLayout>
    </LanguageProvider>
  );
}
