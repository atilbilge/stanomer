"use client";

import React from "react";
import { LegalLayout } from "../../components/LegalLayout";
import { useLanguage } from "../../components/LanguageProvider";
import { 
  FileText, 
  ShieldCheck, 
  CreditCard, 
  Smartphone, 
  UserCheck, 
  Scale, 
  AlertTriangle,
  ExternalLink,
  CheckCircle2
} from "lucide-react";

function TermsContent() {
  const { t } = useLanguage();
  const rawText = t("eula_content") || "";

  // Split raw content by section numbers like "1. ", "2. ", "3. " etc.
  const rawSections = rawText.split(/(?=\b[1-7]\.\s)/);
  const headerText = rawSections[0] || "";
  const sections = rawSections.slice(1);

  const sectionIcons = [
    <FileText key="1" className="w-5 h-5 text-brand-blue" />,
    <Smartphone key="2" className="w-5 h-5 text-purple-600" />,
    <CreditCard key="3" className="w-5 h-5 text-emerald-600" />,
    <UserCheck key="4" className="w-5 h-5 text-amber-600" />,
    <ShieldCheck key="5" className="w-5 h-5 text-brand-green" />,
    <Scale key="6" className="w-5 h-5 text-indigo-600" />,
    <AlertTriangle key="7" className="w-5 h-5 text-red-500" />,
  ];

  const subKeyKeywords = [
    "Apple App Store:",
    "Google Play Store:",
    "Ödeme:",
    "Yenileme:",
    "Yönetim:",
    "Payment:",
    "Renewal:",
    "Management:",
    "Plaćanje:",
    "Obnavljanje:",
    "Upravljanje:",
    "Плаћање:",
    "Обнављање:",
    "Управљање:",
    "Sırbistan Yasası (ZZPL):",
    "Serbian Law (ZZPL):",
    "Zakon Srbije (ZZPL):",
    "Закон Србије (ZZPL):",
    "GDPR:",
    "KVKK:",
  ];

  return (
    <div className="space-y-8">
      {/* Page Header Banner */}
      <div className="border-b border-gray-200/80 pb-6">
        <h1 className="text-2xl sm:text-3xl font-extrabold text-gray-900 mb-3 tracking-tight flex items-center gap-3">
          <FileText className="w-7 h-7 text-brand-blue" />
          {t("terms_title")}
        </h1>
        {headerText && (
          <div className="text-sm text-gray-600 leading-relaxed font-medium bg-blue-50/50 p-4 rounded-xl border border-blue-100 flex items-start gap-3">
            <CheckCircle2 className="w-5 h-5 text-brand-blue flex-shrink-0 mt-0.5" />
            <div>
              <p className="font-semibold text-gray-900 mb-1">Stanomer End User License Agreement (EULA)</p>
              <p>{headerText.trim()}</p>
            </div>
          </div>
        )}
      </div>

      {/* Structured Section Cards */}
      <div className="space-y-6">
        {sections.map((section, idx) => {
          const trimmed = section.trim();
          
          // Match section number and title (e.g. "1. Giriş")
          const titleMatch = trimmed.match(/^([1-7]\.\s+[^.\n]+)(?:\.|\s|$)/);
          let title = titleMatch ? titleMatch[1] : `Section ${idx + 1}`;
          let body = titleMatch ? trimmed.substring(titleMatch[0].length).trim() : trimmed;

          // If title contains too much text, cut at first sentence
          if (title.length > 60) {
            const firstSentence = title.split(". ")[0];
            title = firstSentence;
          }

          const hasAppleLink = body.includes("apple.com");

          // Format body by highlighting subkeys like "Apple App Store:", "Ödeme:", etc.
          let formattedContent: React.ReactNode[] = [body];
          subKeyKeywords.forEach((keyword) => {
            const newContent: React.ReactNode[] = [];
            formattedContent.forEach((item) => {
              if (typeof item === "string" && item.includes(keyword)) {
                const parts = item.split(keyword);
                parts.forEach((part, pIdx) => {
                  newContent.push(part);
                  if (pIdx < parts.length - 1) {
                    newContent.push(
                      <span key={`${keyword}-${pIdx}`} className="block font-bold text-gray-900 mt-2 mb-0.5">
                        • {keyword}
                      </span>
                    );
                  }
                });
              } else {
                newContent.push(item);
              }
            });
            formattedContent = newContent;
          });

          return (
            <div 
              key={idx} 
              className="p-5 sm:p-6 rounded-2xl bg-white border border-gray-200/90 shadow-xs hover:shadow-md transition-all space-y-3"
            >
              {/* Section Header */}
              <div className="flex items-center gap-3 border-b border-gray-100 pb-3">
                <div className="p-2 rounded-xl bg-gray-50 border border-gray-100 shadow-2xs">
                  {sectionIcons[idx] || <FileText className="w-5 h-5 text-gray-600" />}
                </div>
                <h2 className="text-base sm:text-lg font-extrabold text-gray-900 tracking-tight">
                  {title}
                </h2>
              </div>

              {/* Section Content */}
              <div className="text-sm text-gray-700 leading-relaxed pl-1 space-y-2">
                {formattedContent.map((chunk, cIdx) => (
                  <React.Fragment key={cIdx}>
                    {typeof chunk === "string" ? (
                      <span className="inline">{chunk}</span>
                    ) : (
                      chunk
                    )}
                  </React.Fragment>
                ))}
              </div>

              {/* Apple EULA Link Badge */}
              {hasAppleLink && (
                <div className="pt-3 border-t border-gray-100 mt-3">
                  <a
                    href="https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-flex items-center gap-2 text-xs font-semibold text-brand-blue hover:text-blue-700 bg-blue-50/80 px-3.5 py-2 rounded-xl border border-blue-100 transition-all"
                  >
                    <span>Apple Standard Licensed Application EULA</span>
                    <ExternalLink className="w-3.5 h-3.5" />
                  </a>
                </div>
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
}

export default function TermsPage() {
  return (
    <LegalLayout activeTab="terms">
      <TermsContent />
    </LegalLayout>
  );
}
