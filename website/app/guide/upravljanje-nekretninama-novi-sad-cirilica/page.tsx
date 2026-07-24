import type { Metadata } from "next";
import { GuideLayout } from "../../../components/GuideLayout";
import { 
  Building, 
  FileText, 
  Receipt, 
  ShieldCheck, 
  CheckCircle2, 
  AlertCircle, 
  Sparkles,
  BarChart3,
  Search,
  Lock
} from "lucide-react";

export const metadata: Metadata = {
  title: "Професионализујте управљање некретнинама у Новом Саду: Дигитални систем за станодавце | Stanomer",
  description: "Практични водич за станодавце у Новом Саду. Проналазак правог станара, праћење кирија, архивирање рачуна и локално складиштење података уз Stanomer.",
  keywords: [
    "izdavanje kuća Novi Sad",
    "издавање станова Нови Сад",
    "управљање некретнинама Нови Сад",
    "водич за станодавце",
    "праћење кирије",
    "архивирање рачуна",
    "stanomer апликација"
  ],
  alternates: {
    canonical: "https://www.stanomer.online/guide/upravljanje-nekretninama-novi-sad-cirilica",
    languages: {
      "en": "https://www.stanomer.online/guide/novi-sad-property-management-guide",
      "sr": "https://www.stanomer.online/guide/upravljanje-nekretninama-novi-sad",
      "sr-Cyrl": "https://www.stanomer.online/guide/upravljanje-nekretninama-novi-sad-cirilica",
      "ru": "https://www.stanomer.online/guide/novi-sad-property-management-guide-ru",
    }
  },
  openGraph: {
    title: "Професионализујте управљање некретнинама у Новом Саду | Stanomer",
    description: "Дигитални систем за станодавце у Новом Саду.",
    url: "https://www.stanomer.online/guide/upravljanje-nekretninama-novi-sad-cirilica",
    siteName: "Stanomer",
    locale: "sr_RS",
    type: "article",
  }
};

const jsonLd = {
  "@context": "https://schema.org",
  "@type": "Article",
  "headline": "Професионализујте управљање некретнинама у Новом Саду: Дигитални систем за станодавце",
  "description": "Водич за станодавце у Новом Саду: проналазак станара, транспарентан прилив новца и дигитализација рачуна.",
  "author": {
    "@type": "Organization",
    "name": "Stanomer",
    "url": "https://www.stanomer.online"
  },
  "publisher": {
    "@type": "Organization",
    "name": "Stanomer",
    "logo": {
      "@type": "ImageObject",
      "url": "https://www.stanomer.online/favicon.png"
    }
  },
  "mainEntityOfPage": "https://www.stanomer.online/guide/upravljanje-nekretninama-novi-sad-cirilica",
  "inLanguage": "sr-Cyrl"
};

export default function NoviSadSerbianCyrillicGuidePage() {
  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
      />
      <GuideLayout
        currentLang="SR_CYR"
        categoryTitle="Водич за Нови Сад"
        locationName="Нови Сад, Србија"
        title="Професионализујте управљање некретнинама у Новом Саду: Дигитални систем за станодавце"
        subtitle="Овај водич се бави са три кључна оперативна поља: проналазак правог станара, одржавање транспарентног прилива новца и ослобађање од ручних система праћења."
        ctaText="Дигитализујте управљање некретнинама уз Stanomer"
        ctaSubtext="Праћење кирија, аутоматизација архивирања рачуна и организација прихода уз 100% приватност и локално складиштење података."
        canonicalUrl="https://www.stanomer.online/guide/upravljanje-nekretninama-novi-sad-cirilica"
      >
        {/* Intro */}
        <div className="space-y-4">
          <p className="text-gray-700 leading-relaxed">
            Нови Сад је последњих година постао једно од најатрактивнијих тржишта за издавање некретнина у Србији. Међутим, овај потенцијал доноси и растући оперативни терет: за станодавце који управљају са више некретнина, праћење кирија, архивирање рачуна и комуникација са станарима брзо постају компликован посао.
          </p>
          <p className="text-gray-700 leading-relaxed">
            Издавање једног стана је релативно једноставан процес. Али када ваш портфолио порасте на две, три или више некретнина, ослањање на памћење или разбацане фајлове није одржива стратегија. Овај водич се бави са три кључна оперативна поља: проналазак правог станара, одржавање транспарентног прилива новца и ослобађање од ручних система праћења.
          </p>
        </div>

        {/* Quick Summary Grid Box */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 my-8" lang="sr">
          <div className="p-4 rounded-xl bg-blue-50/70 border border-blue-100 flex items-start gap-3">
            <Search className="w-5 h-5 text-brand-blue flex-shrink-0 mt-0.5" />
            <div>
              <h4 className="font-bold text-xs text-gray-900 tracking-wider mb-1">1. ПРОНАЛАЗАК СТАНАРА</h4>
              <p className="text-xs text-gray-600">Квалитет огласа, цене у крају и историја станара.</p>
            </div>
          </div>

          <div className="p-4 rounded-xl bg-green-50/70 border border-green-100 flex items-start gap-3">
            <BarChart3 className="w-5 h-5 text-brand-green flex-shrink-0 mt-0.5" />
            <div>
              <h4 className="font-bold text-xs text-gray-900 tracking-wider mb-1">2. СТАБИЛАН ПРИХОД</h4>
              <p className="text-xs text-gray-600">Датуми плаћања, одговорност за рачуне и евиденција.</p>
            </div>
          </div>

          <div className="p-4 rounded-xl bg-amber-50/70 border border-amber-100 flex items-start gap-3">
            <Lock className="w-5 h-5 text-amber-600 flex-shrink-0 mt-0.5" />
            <div>
              <h4 className="font-bold text-xs text-gray-900 tracking-wider mb-1">3. ДИГИТАЛНИ СИСТЕМ</h4>
              <p className="text-xs text-gray-600">Замена Excel табела локалним складиштењем (local storage).</p>
            </div>
          </div>
        </div>

        {/* Section 1 */}
        <section className="space-y-4 pt-4 border-t border-gray-100" lang="sr">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-brand-blue rounded-full"></span>
            Проналазак правог станара и оглашавање некретнине
          </h2>

          <p className="text-gray-700 leading-relaxed">
            Тржиште некретнина у Новом Саду има различиту динамику у зависности од циљне групе. Они који претражују <code className="bg-gray-100 px-1.5 py-0.5 rounded text-brand-blue font-semibold">izdavanje kuća Novi Sad</code> су обично породице или професионалци који раде на даљину.
          </p>

          <div className="bg-gray-50/80 p-5 rounded-2xl border border-gray-200/80 space-y-3">
            <h3 className="font-bold text-gray-900 text-sm tracking-wide flex items-center gap-2">
              <Sparkles className="w-4 h-4 text-brand-blue" />
              КЉУЧНЕ ТАЧКЕ:
            </h3>

            <ul className="space-y-2 text-sm text-gray-700">
              <li className="flex items-start gap-2.5">
                <CheckCircle2 className="w-4 h-4 text-brand-blue flex-shrink-0 mt-1" />
                <span><strong>Квалитет огласа је пресудан:</strong> Детаљни описи и квалитетне слике директно утичу на број упита.</span>
              </li>
              <li className="flex items-start gap-2.5">
                <CheckCircle2 className="w-4 h-4 text-brand-blue flex-shrink-0 mt-1" />
                <span><strong>Пратите цене у вашем крају:</strong> Усклађивање цена смањује време празног хода.</span>
              </li>
              <li className="flex items-start gap-2.5">
                <CheckCircle2 className="w-4 h-4 text-brand-blue flex-shrink-0 mt-1" />
                <span><strong>Проверите историју станара:</strong> Редовност у претходним плаћањима је најбољи индикатор.</span>
              </li>
            </ul>
          </div>
        </section>

        {/* Section 2 */}
        <section className="space-y-4 pt-6 border-t border-gray-100">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-brand-green rounded-full"></span>
            Транспарентна комуникација и стабилан приход
          </h2>

          <p className="text-gray-700 leading-relaxed">
            Три елемента су кључна за сигуран и стабилан приход:
          </p>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="p-4 rounded-xl bg-white border border-gray-200 shadow-xs space-y-2">
              <h4 className="font-bold text-gray-900 text-sm flex items-center gap-2">
                <FileText className="w-4 h-4 text-brand-green" />
                Јасни датуми плаћања
              </h4>
              <p className="text-xs text-gray-600 leading-relaxed">
                Прецизни рокови смањују проценат кашњења.
              </p>
            </div>

            <div className="p-4 rounded-xl bg-white border border-gray-200 shadow-xs space-y-2">
              <h4 className="font-bold text-gray-900 text-sm flex items-center gap-2">
                <Receipt className="w-4 h-4 text-brand-green" />
                Прецизирање одговорности
              </h4>
              <p className="text-xs text-gray-600 leading-relaxed">
                Јасна подела рачуна спречава евентуалне спорове.
              </p>
            </div>

            <div className="p-4 rounded-xl bg-white border border-gray-200 shadow-xs space-y-2">
              <h4 className="font-bold text-gray-900 text-sm flex items-center gap-2">
                <BarChart3 className="w-4 h-4 text-brand-green" />
                Евиденција историје
              </h4>
              <p className="text-xs text-gray-600 leading-relaxed">
                Вођење евиденције плаћања гради међусобно поверење.
              </p>
            </div>
          </div>
        </section>

        {/* Section 3 */}
        <section className="space-y-4 pt-6 border-t border-gray-100">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-amber-500 rounded-full"></span>
            Ослобађање од Excel табела
          </h2>

          <p className="text-gray-700 leading-relaxed">
            Већина станодаваца почиње са Excel табелом. За једну некретнину то може бити довољно, али како портфолио расте, ризик од људске грешке се повећава. Ручни системи једноставно нису скалабилни.
          </p>
        </section>

        {/* Section 4: Solution */}
        <section className="space-y-5 pt-6 border-t border-gray-100">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-brand-blue rounded-full"></span>
            Решење: Stanomer — Дигитални асистент за станодавце
          </h2>

          <p className="text-gray-700 leading-relaxed">
            Stanomer је дизајниран да реши овај проблем и пружи модерно решење за управљање некретнинама.
          </p>

          <div className="bg-gradient-to-r from-blue-50 via-white to-green-50 p-6 rounded-2xl border border-gray-200 space-y-4">
            <h3 className="font-bold text-gray-900 text-base flex items-center gap-2">
              <ShieldCheck className="w-5 h-5 text-brand-blue" />
              Кључне функције:
            </h3>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 text-sm">
              <div className="p-3 bg-white rounded-xl border border-gray-200/80">
                <h4 className="font-bold text-gray-900 mb-1">📊 Праћење циклуса плаћања</h4>
                <p className="text-xs text-gray-600">Статус плаћања кирије за сваку некретнину је видљив на једном екрану.</p>
              </div>

              <div className="p-3 bg-white rounded-xl border border-gray-200/80">
                <h4 className="font-bold text-gray-900 mb-1">📁 Аутоматизација архивирања рачуна</h4>
                <p className="text-xs text-gray-600">Рачуни се дигитално архивирају и сортирају по некретнинама.</p>
              </div>

              <div className="p-3 bg-white rounded-xl border border-gray-200/80">
                <h4 className="font-bold text-gray-900 mb-1">💼 Организација прихода и расхода</h4>
                <p className="text-xs text-gray-600">Приходи целог портфолија сакупљени под једном структуром.</p>
              </div>

              <div className="p-3 bg-white rounded-xl border border-gray-200/80">
                <h4 className="font-bold text-gray-900 mb-1">🔒 Локално складиштење (local storage)</h4>
                <p className="text-xs text-gray-600">Подаци о вашим некретнинама остају на вашем уређају; не шаљу се на cloud сервере. Ово је кључна гаранција приватности.</p>
              </div>
            </div>

            {/* Direct High Converting CTA Button Box */}
            <div className="pt-4 text-center sm:text-left border-t border-gray-200/60">
              <div className="p-5 rounded-xl bg-brand-blue text-white space-y-3 shadow-lg">
                <p className="font-bold text-sm leading-snug">
                  📊 Како ваш портфолио расте, мора расти и ваш систем. Преузмите Stanomer и дигитализујте управљање некретнинама.
                </p>
                <div className="flex flex-wrap items-center justify-center sm:justify-start gap-3 pt-1">
                  <a 
                    href="https://apps.apple.com/us/app/stanomer/id6762311157" 
                    target="_blank" 
                    rel="noopener noreferrer" 
                    className="inline-flex transition-transform hover:scale-105"
                  >
                    <img src="https://upload.wikimedia.org/wikipedia/commons/9/91/Download_on_the_App_Store_RGB_blk.svg" alt="App Store" className="h-9 w-[120px] block" />
                  </a>
                  <a 
                    href="https://play.google.com/store/apps/details?id=com.aboptima.stanomer" 
                    target="_blank" 
                    rel="noopener noreferrer" 
                    className="inline-flex transition-transform hover:scale-105"
                  >
                    <img src="https://upload.wikimedia.org/wikipedia/commons/7/78/Google_Play_Store_badge_EN.svg" alt="Google Play" className="h-9 w-[120px] block" />
                  </a>
                </div>
              </div>
            </div>
          </div>
        </section>
      </GuideLayout>
    </>
  );
}
