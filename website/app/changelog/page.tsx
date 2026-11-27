"use client";

import { LanguageProvider, useLanguage } from "../../components/LanguageProvider";
import { LegalLayout } from "../../components/LegalLayout";
import {
  ShieldCheck,
  BookOpen,
  Users,
  Building2,
  Lock,
  Layers,
  CheckCircle2,
} from "lucide-react";

function ChangelogContent() {
  const { t } = useLanguage();

  const v210Cards = [
    {
      icon: ShieldCheck,
      title: t("cl_v210_f1_title"),
      bullets: [t("cl_v210_f1_b1"), t("cl_v210_f1_b2"), t("cl_v210_f1_b3")],
    },
    {
      icon: BookOpen,
      title: t("cl_v210_f2_title"),
      bullets: [t("cl_v210_f2_b1"), t("cl_v210_f2_b2")],
    },
    {
      icon: Users,
      title: t("cl_v210_f3_title"),
      bullets: [t("cl_v210_f3_b1"), t("cl_v210_f3_b2")],
    },
  ];

  const earlierReleases = [
    {
      version: "v2.0.4",
      date: t("cl_v204_date"),
      badge: t("cl_tag_stable"),
      headline: t("cl_v204_headline"),
      icon: Layers,
      bullets: [t("cl_v204_b1"), t("cl_v204_b2"), t("cl_v204_b3")],
    },
    {
      version: "v2.0.0",
      date: t("cl_v200_date"),
      badge: t("cl_tag_stable"),
      headline: t("cl_v200_headline"),
      icon: Building2,
      bullets: [t("cl_v200_b1"), t("cl_v200_b2")],
    },
    {
      version: "v1.3.0",
      date: t("cl_v130_date"),
      badge: t("cl_tag_stable"),
      headline: t("cl_v130_headline"),
      icon: Lock,
      bullets: [t("cl_v130_b1"), t("cl_v130_b2")],
    },
    {
      version: "v1.0 - v1.2",
      date: t("cl_v100_date"),
      badge: t("cl_tag_launch"),
      headline: t("cl_v100_headline"),
      icon: CheckCircle2,
      bullets: [t("cl_v100_b1"), t("cl_v100_b2")],
    },
  ];

  return (
    <div className="text-[#1A1A1A] font-sans max-w-none">
      {/* Header */}
      <header className="mb-10 border-b border-[#E5E3DF] pb-7 text-left space-y-3">
        <span className="inline-block bg-[#E5EEF6] text-[#1B5888] border border-[#1B5888]/20 px-3 py-1 rounded-[6px] text-[11px] font-bold tracking-wider uppercase">
          {t("cl_badge")}
        </span>
        <h1 className="font-[family-name:var(--font-outfit)] text-3xl sm:text-4xl font-bold text-[#1A1A1A] tracking-tight leading-[1.12]">
          {t("cl_title")}
        </h1>
        <p className="text-sm sm:text-base text-[#4A4A4A] leading-relaxed max-w-2xl">
          {t("cl_subtitle")}
        </p>
      </header>

      {/* Timeline */}
      <div className="relative pl-6 sm:pl-8 border-l border-[#E5E3DF] ml-1 sm:ml-2 space-y-12">
        {/* LATEST: v2.1.0 */}
        <section className="relative">
          <div className="absolute -left-[33px] sm:-left-[41px] top-1.5 w-4 h-4 rounded-full bg-[#1B5888] border-[3px] border-white shadow-[0_0_0_4px_#E5EEF6]" />

          <div className="flex flex-wrap items-center gap-2.5 mb-2">
            <span className="font-[family-name:var(--font-outfit)] text-2xl font-bold text-[#1A1A1A]">
              v2.1.0
            </span>
            <span className="text-xs font-semibold text-[#4A4A4A] bg-[#F8F7F5] border border-[#E5E3DF] px-2.5 py-0.5 rounded-[6px]">
              {t("cl_v210_date")}
            </span>
            <span className="text-[11px] font-bold uppercase tracking-wide bg-[#E5EEF6] text-[#1B5888] border border-[#1B5888]/25 px-2.5 py-0.5 rounded-[6px]">
              {t("cl_tag_latest")}
            </span>
          </div>

          <p className="text-sm sm:text-base font-medium text-[#4A4A4A] mb-5">
            {t("cl_v210_headline")}
          </p>

          <div className="space-y-4">
            {v210Cards.map((card) => {
              const Icon = card.icon;
              return (
                <div
                  key={card.title}
                  className="bg-white border border-[#E5E3DF] rounded-[10px] p-5 shadow-[0_1px_0_rgba(0,0,0,0.04),0_2px_8px_rgba(0,0,0,0.06)] space-y-3"
                >
                  <div className="flex items-center gap-2.5">
                    <div className="w-8 h-8 rounded-lg bg-[#E5EEF6] text-[#1B5888] flex items-center justify-center shrink-0">
                      <Icon className="w-4 h-4" />
                    </div>
                    <h3 className="font-[family-name:var(--font-outfit)] text-base font-bold text-[#1A1A1A]">
                      {card.title}
                    </h3>
                  </div>
                  <ul className="space-y-1.5 list-none pl-0">
                    {card.bullets.map((b) => (
                      <li
                        key={b}
                        className="relative pl-4 text-xs sm:text-sm text-[#4A4A4A] leading-relaxed before:content-[''] before:absolute before:left-0 before:top-2 before:w-1.5 before:h-1.5 before:rounded-full before:bg-[#1B5888]"
                      >
                        {b}
                      </li>
                    ))}
                  </ul>
                </div>
              );
            })}
          </div>
        </section>

        {/* EARLIER RELEASES */}
        {earlierReleases.map((rel) => {
          const Icon = rel.icon;
          return (
            <section key={rel.version} className="relative">
              <div className="absolute -left-[31px] sm:-left-[39px] top-2 w-3 h-3 rounded-full bg-[#8A8A8A] border-2 border-white" />

              <div className="flex flex-wrap items-center gap-2.5 mb-1.5">
                <span className="font-[family-name:var(--font-outfit)] text-xl font-bold text-[#1A1A1A]">
                  {rel.version}
                </span>
                <span className="text-xs font-semibold text-[#666666] bg-[#F8F7F5] border border-[#E5E3DF] px-2.5 py-0.5 rounded-[6px]">
                  {rel.date}
                </span>
                <span className="text-[11px] font-semibold text-[#666666] bg-[#F8F7F5] border border-[#E5E3DF] px-2.5 py-0.5 rounded-[6px]">
                  {rel.badge}
                </span>
              </div>

              <div className="bg-white border border-[#E5E3DF] rounded-[10px] p-5 mt-3 space-y-3">
                <div className="flex items-center gap-2.5">
                  <Icon className="w-4 h-4 text-[#1B5888] shrink-0" />
                  <h3 className="font-[family-name:var(--font-outfit)] text-sm sm:text-base font-bold text-[#1A1A1A]">
                    {rel.headline}
                  </h3>
                </div>
                <ul className="space-y-1.5 list-none pl-0">
                  {rel.bullets.map((b) => (
                    <li
                      key={b}
                      className="relative pl-4 text-xs sm:text-sm text-[#4A4A4A] leading-relaxed before:content-[''] before:absolute before:left-0 before:top-2 before:w-1.5 before:h-1.5 before:rounded-full before:bg-[#8A8A8A]"
                    >
                      {b}
                    </li>
                  ))}
                </ul>
              </div>
            </section>
          );
        })}
      </div>
    </div>
  );
}

export default function ChangelogPage() {
  return (
    <LanguageProvider>
      <LegalLayout activeTab="changelog">
        <ChangelogContent />
      </LegalLayout>
    </LanguageProvider>
  );
}
