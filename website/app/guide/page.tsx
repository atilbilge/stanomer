"use client";

import React, { useState } from "react";
import { useLanguage, Language } from "../../components/LanguageProvider";
import { Navbar } from "../../components/Navbar";
import { BookOpen, ArrowRight, Building2, Globe2, ChevronDown, ChevronUp } from "lucide-react";

interface GuideItem {
  lang: Language;
  city: "Belgrade" | "Novi Sad";
  flag: string;
  badge: string;
  title: string;
  description: string;
  path: string;
}

const allGuides: GuideItem[] = [
  // Serbia Lease Agreement Guides
  {
    lang: "TR",
    city: "Serbia",
    flag: "🇹🇷",
    badge: "Türkçe Rehber",
    title: "Sırbistan'da Kira Sözleşmesi (Ugovor o Zakupu): Ev Sahiplerinin Bilmesi Gereken 4 Kritik Madde",
    description: "Sırbistan'da ev kiralarken hukuki olarak kendinizi nasıl korursunuz? Ugovor o zakupu maddeleri, depozito hakları ve dijital süreç yönetimi.",
    path: "/guide/sirbistan-kira-sozlesmesi-rehberi"
  },
  {
    lang: "EN",
    city: "Serbia",
    flag: "🇬🇧",
    badge: "English Guide",
    title: "Lease Agreements in Serbia: Critical Points Every Landlord Must Know",
    description: "How to legally protect yourself when renting out an apartment in Serbia? A comprehensive guide on lease clauses, deposit rights, and property management.",
    path: "/guide/serbia-lease-agreement-guide"
  },
  {
    lang: "SR_LAT",
    city: "Srbija",
    flag: "🇷🇸",
    badge: "Srpski (Latinica)",
    title: "Ugovor o zakupu stana u Srbiji: Šta svaki stanodavac mora da zna",
    description: "Kako pravno da se zaštitite prilikom izdavanja stana u Srbiji? Sveobuhvatni vodič o stavkama ugovora o zakupu, depozitu i upravljanju procesima.",
    path: "/guide/ugovor-o-zakupu-stana-srbija"
  },
  {
    lang: "SR_CYR",
    city: "Србија",
    flag: "🇷🇸",
    badge: "Српски (Ћирилица)",
    title: "Уговор о закупу стана у Србији: Шта сваки станодавац мора да зна",
    description: "Како правно да се заштите приликом издавања стана у Србији? Свеобухватни водич о ставкама уговора о закупу, депозиту и управљању процесима.",
    path: "/guide/ugovor-o-zakupu-stana-srbija-cirilica"
  },
  {
    lang: "RU",
    city: "Сербия",
    flag: "🇷🇺",
    badge: "Русский Гайд",
    title: "Договор аренды в Сербии: что должен знать каждый арендодатель",
    description: "Как юридически защитить себя при сдаче квартиры в Сербии? Подробное руководство по условиям договора аренды, депозиту и управлению недвижимостью.",
    path: "/guide/serbia-lease-agreement-guide-ru"
  },

  // Novi Sad Guides
  {
    lang: "TR",
    city: "Novi Sad",
    flag: "🇹🇷",
    badge: "Türkçe Rehber",
    title: "Novi Sad'da Mülk Yönetimini Profesyonelleştirin: Ev Sahipleri İçin Dijital Sistem",
    description: "Novi Sad'daki ev sahipleri ve yatırımcılar için kiralık mülk yönetimi, kira takibi, fatura arşivleme otomasyonu ve Stanomer lokal depolama çözümü.",
    path: "/guide/novi-sad-mulk-yonetimi-rehberi"
  },
  {
    lang: "EN",
    city: "Novi Sad",
    flag: "🇬🇧",
    badge: "English Guide",
    title: "Professionalize Property Management in Novi Sad: A Digital System for Landlords",
    description: "Operational guide for landlords and foreign investors in Novi Sad on finding tenants, houses for rent, cash flow transparency, and automated invoice archiving with Stanomer.",
    path: "/guide/novi-sad-property-management-guide"
  },
  {
    lang: "SR_LAT",
    city: "Novi Sad",
    flag: "🇷🇸",
    badge: "Srpski (Latinica)",
    title: "Profesionalizujte upravljanje nekretninama u Novom Sadu: Digitalni sistem za stanodavce",
    description: "Vodič za stanodavce u Novom Sadu: pronalazak pravog stanara, transparentna komunikacija, oslobađanje od Excel tabela i lokalno skladištenje podataka uz Stanomer.",
    path: "/guide/upravljanje-nekretninama-novi-sad"
  },
  {
    lang: "SR_CYR",
    city: "Novi Sad",
    flag: "🇷🇸",
    badge: "Српски (Ћирилица)",
    title: "Професионализујте управљање некретнинама у Новом Саду: Дигитални систем за станодавце",
    description: "Водич за станодавце у Новом Саду: проналазак станара, евиденција плаћања кирија, дигитализација рачуна и локално складиштење података.",
    path: "/guide/upravljanje-nekretninama-novi-sad-cirilica"
  },
  {
    lang: "RU",
    city: "Novi Sad",
    flag: "🇷🇺",
    badge: "Русский Гайд",
    title: "Профессиональное управление недвижимостью в Нови-Саде: Цифровая система для арендодателей",
    description: "Гайд для арендодателей в Нови-Саде: поиск арендатора, дома в аренду (houses for rent in Novi Sad), управление счетами и local storage конфиденциальность.",
    path: "/guide/novi-sad-property-management-guide-ru"
  },

  // Belgrade Guides
  {
    lang: "TR",
    city: "Belgrade",
    flag: "🇹🇷",
    badge: "Türkçe Rehber",
    title: "Belgrad Kiralık Daire Rehberi: Ev Bulmaktan Fatura Takibine Kadar Bilmeniz Gereken Her Şey",
    description: "Belgrad'da kiralık ev arayan expat'lar ve öğrenciler için mahalleler (Vračar, Novi Beograd), ugovor o zakupu kira sözleşmesi ve EPS/Infostan fatura takip rehberi.",
    path: "/guide/belgrad-kiralik-daire-rehberi"
  },
  {
    lang: "EN",
    city: "Belgrade",
    flag: "🇬🇧",
    badge: "English Guide",
    title: "The Ultimate Guide to Renting an Apartment in Belgrade: From Searching to Managing Utilities",
    description: "Everything expats, digital nomads, and international students need to know about Belgrade rental market, lease contracts, and utility management in Serbia.",
    path: "/guide/belgrade-apartment-rental-guide"
  },
  {
    lang: "SR_LAT",
    city: "Belgrade",
    flag: "🇷🇸",
    badge: "Srpski (Latinica)",
    title: "Vodič za izdavanje stanova u Beogradu: Od pronalaska do praćenja računa",
    description: "Praktični vodič za potragu stana u Beogradu, ključne stavke Ugovora o zakupu i jednostavna organizacija računa za struju i Infostan.",
    path: "/guide/vodic-za-izdavanje-stanova-beograd"
  },
  {
    lang: "SR_CYR",
    city: "Belgrade",
    flag: "🇷🇸",
    badge: "Српски (Ћирилица)",
    title: "Водич за издавање станова у Београду: Од проналаска до праћења рачуна",
    description: "Практични водич за потрагу стана у Београду, кључне ставке Уговора о закупу и једноставна организација рачуна за струју и Инфостан.",
    path: "/guide/vodic-za-izdavanje-stanova-beograd-cirilica"
  },
  {
    lang: "RU",
    city: "Belgrade",
    flag: "🇷🇺",
    badge: "Русский Гайд",
    title: "Руководство по аренде квартир в Белграде: От поиска до управления счетами",
    description: "Полный гайд по аренде жилья в Белграде: поиск района (Врачар, Нови Белград), договор Ugovor o zakupu и оплата коммунальных счетов.",
    path: "/guide/belgrade-apartment-rental-guide-ru"
  }
];

const labels = {
  TR: {
    heroTag: "Stanomer Emlak & Kiralık Rehberleri",
    heroTitle: "Sırbistan Emlak ve Mülk Yönetimi Rehberleri",
    heroSub: "Seçtiğiniz dile (TR) uygun rehberler aşağıda listelenmektedir. Üst menüden dili değiştirerek farklı dillerdeki rehberlere ulaşabilirsiniz.",
    featuredHeading: "Öne Çıkan Rehberler (Türkçe & Genel)",
    otherHeading: "Diğer Dillerdeki Tüm Rehberler",
    readGuide: "Rehberi Oku",
  },
  EN: {
    heroTag: "Stanomer Real Estate & Rental Guides",
    heroTitle: "Serbia Real Estate & Property Management Guides",
    heroSub: "Guides matching your selected header language (EN) are displayed below. You can change your language anytime from the top menu.",
    featuredHeading: "Guides for Your Selected Language",
    otherHeading: "All Guides in Other Languages",
    readGuide: "Read Guide",
  },
  SR_LAT: {
    heroTag: "Stanomer Vodiči za Nekretnine i Izdavanje",
    heroTitle: "Vodiči za nekretnine i upravljanje u Srbiji",
    heroSub: "Prikazuju se vodiči usklađeni sa izabranim jezikom (SR). Jezik možete promeniti uvek u gornjem meniju.",
    featuredHeading: "Preporučeni vodiči na vašem jeziku",
    otherHeading: "Svi vodiči na drugim jezicima",
    readGuide: "Pročitaj vodič",
  },
  SR_CYR: {
    heroTag: "Stanomer Водичи за Некретнине и Издавање",
    heroTitle: "Водичи за некретнине и управљање у Србији",
    heroSub: "Приказују се водичи усклађени са изабраним језиком (СРБ). Језик можете променити увек у горњем менију.",
    featuredHeading: "Препоручени водичи на вашем језику",
    otherHeading: "Сви водичи на другим језицима",
    readGuide: "Прочитај водич",
  },
  RU: {
    heroTag: "Stanomer Руководства по Аренде и Недвижимости",
    heroTitle: "Руководства по недвижимости и управлению в Сербии",
    heroSub: "Отображаются руководства на выбранном языке (RU). Вы можете изменить язык в любой момент в верхнем меню.",
    featuredHeading: "Руководства на вашем языке",
    otherHeading: "Все руководства на других языках",
    readGuide: "Читать гайд",
  }
};

export default function GuideHubPage() {
  const { lang } = useLanguage();
  const [showOtherLangs, setShowOtherLangs] = useState(false);

  const currentLabels = labels[lang] || labels.EN;

  // Primary matching guides for current header language
  const primaryGuides = allGuides.filter((g) => g.lang === lang);

  // Non-primary guides (other languages)
  const otherGuides = allGuides.filter((g) => !primaryGuides.includes(g));

  return (
    <div className="min-h-screen flex flex-col font-sans bg-transparent text-gray-900">
      <Navbar />
      <div className="h-[80px]" />

      <main className="flex-grow max-w-[760px] mx-auto px-4 sm:px-6 py-10 w-full space-y-8">
        {/* Header Hero Banner */}
        <div className="bg-white/80 backdrop-blur-[20px] rounded-3xl border border-gray-200 p-8 text-center shadow-lg space-y-4">
          <div className="inline-flex items-center gap-2 px-3.5 py-1 rounded-full bg-brand-blue/15 border border-brand-blue/30 text-brand-blue text-[11px] font-bold uppercase tracking-wider">
            <BookOpen className="w-3.5 h-3.5" />
            <span>{currentLabels.heroTag}</span>
          </div>

          <h1 className="text-2xl sm:text-3xl font-extrabold text-gray-900 tracking-tight">
            {currentLabels.heroTitle}
          </h1>

          <p className="text-sm text-gray-600 max-w-lg mx-auto leading-relaxed">
            {currentLabels.heroSub}
          </p>
        </div>

        {/* Primary Matching Guides for Header Language */}
        <section className="space-y-4">
          <div className="flex items-center gap-2 px-2">
            <Building2 className="w-5 h-5 text-brand-blue" />
            <h2 className="text-xl font-bold text-gray-900 tracking-tight">
              {currentLabels.featuredHeading}
            </h2>
          </div>

          <div className="space-y-3">
            {primaryGuides.map((guide) => (
              <a
                key={guide.path}
                href={guide.path}
                className="block p-6 bg-white/90 backdrop-blur-[16px] rounded-2xl border-2 border-brand-blue/30 shadow-md hover:shadow-lg hover:border-brand-blue transition-all group no-underline relative overflow-hidden"
              >
                <div className="flex items-center justify-between gap-2 mb-3">
                  <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-lg bg-brand-blue/10 border border-brand-blue/20 text-xs font-bold text-brand-blue">
                    <span>{guide.flag}</span>
                    <span>{guide.badge}</span>
                  </span>
                  <span className="text-xs text-brand-blue font-bold group-hover:translate-x-1 transition-transform flex items-center gap-1">
                    {currentLabels.readGuide} <ArrowRight className="w-4 h-4" />
                  </span>
                </div>

                <h3 className="text-lg font-bold text-gray-900 group-hover:text-brand-blue transition-colors mb-2 leading-snug">
                  {guide.title}
                </h3>

                <p className="text-xs sm:text-sm text-gray-600 leading-relaxed">
                  {guide.description}
                </p>
              </a>
            ))}
          </div>
        </section>

        {/* Accordion / Toggle for Other Languages */}
        <section className="pt-4 border-t border-gray-200/80 space-y-4">
          <button
            type="button"
            onClick={() => setShowOtherLangs(!showOtherLangs)}
            className="w-full flex items-center justify-between p-4 bg-white/70 backdrop-blur-md rounded-xl border border-gray-200 text-xs font-bold text-gray-700 hover:text-brand-blue hover:border-brand-blue/40 transition-all cursor-pointer"
          >
            <div className="flex items-center gap-2">
              <Globe2 className="w-4 h-4 text-gray-500" />
              <span>{currentLabels.otherHeading} ({otherGuides.length})</span>
            </div>
            {showOtherLangs ? (
              <ChevronUp className="w-4 h-4 text-gray-500" />
            ) : (
              <ChevronDown className="w-4 h-4 text-gray-500" />
            )}
          </button>

          {showOtherLangs && (
            <div className="space-y-3 pt-2">
              {otherGuides.map((guide) => (
                <a
                  key={guide.path}
                  href={guide.path}
                  className="block p-4 bg-white/60 backdrop-blur-[12px] rounded-xl border border-gray-200 hover:border-gray-300 hover:bg-white/90 transition-all group no-underline opacity-90 hover:opacity-100"
                >
                  <div className="flex items-center justify-between gap-2 mb-2">
                    <span className="inline-flex items-center gap-1.5 px-2 py-0.5 rounded bg-gray-100 border border-gray-200 text-[11px] font-semibold text-gray-700">
                      <span>{guide.flag}</span>
                      <span>{guide.badge}</span>
                    </span>
                    <span className="text-xs text-gray-500 group-hover:text-brand-blue flex items-center gap-1">
                      {currentLabels.readGuide} <ArrowRight className="w-3 h-3" />
                    </span>
                  </div>

                  <h4 className="text-sm font-bold text-gray-900 group-hover:text-brand-blue transition-colors mb-1 leading-snug">
                    {guide.title}
                  </h4>

                  <p className="text-xs text-gray-500 line-clamp-2 leading-relaxed">
                    {guide.description}
                  </p>
                </a>
              ))}
            </div>
          )}
        </section>
      </main>

      <footer className="py-10 border-t border-gray-200 mt-12 text-center text-xs text-gray-500">
        © 2026 Stanomer. All rights reserved.
      </footer>
    </div>
  );
}
