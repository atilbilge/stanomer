import type { Metadata } from "next";
import { GuideLayout } from "../../../components/GuideLayout";
import { 
  Building, 
  FileText, 
  Receipt, 
  ShieldCheck, 
  CheckCircle2, 
  AlertCircle, 
  Sparkles 
} from "lucide-react";

export const metadata: Metadata = {
  title: "Водич за издавање станова у Београду: Од проналаска до рачуна | Stanomer",
  description: "Водич за издавање станова у Београду: савети за претрагу (Врачар, Нови Београд), уговор о закупу, рачуни за ЕПС и Инфостан и дигитално праћење трошкова уз Stanomer.",
  keywords: [
    "Водич за издавање станова Београд",
    "издавање станова београд",
    "станови београд најам",
    "уговор о закупу",
    "инфостан рачуни",
    "епс струја београд",
    "apartments for rent in belgrade",
    "stanomer"
  ],
  alternates: {
    canonical: "https://www.stanomer.online/guide/vodic-za-izdavanje-stanova-beograd-cirilica",
    languages: {
      "tr": "https://www.stanomer.online/guide/belgrad-kiralik-daire-rehberi",
      "en": "https://www.stanomer.online/guide/belgrade-apartment-rental-guide",
      "sr": "https://www.stanomer.online/guide/vodic-za-izdavanje-stanova-beograd",
      "sr-Cyrl": "https://www.stanomer.online/guide/vodic-za-izdavanje-stanova-beograd-cirilica",
    }
  },
  openGraph: {
    title: "Водич за издавање станова у Београду | Stanomer",
    description: "Од проналаска стана и Уговора о закупу до праћења рачуна за струју и Инфостан.",
    url: "https://www.stanomer.online/guide/vodic-za-izdavanje-stanova-beograd-cirilica",
    siteName: "Stanomer",
    locale: "sr_RS",
    type: "article",
  }
};

const jsonLd = {
  "@context": "https://schema.org",
  "@type": "Article",
  "headline": "Водич за издавање станова у Београду: Од проналаска до праћења рачуна",
  "description": "Свеобухватни водич за закупце у Београду: претрага, уговор о закупу и вођење рачуна.",
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
  "mainEntityOfPage": "https://www.stanomer.online/guide/vodic-za-izdavanje-stanova-beograd-cirilica",
  "inLanguage": "sr-Cyrl"
};

export default function SerbianCyrillicGuidePage() {
  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
      />
      <GuideLayout
        currentLang="SR_CYR"
        title="Водич за издавање станова у Београду: Од проналаска до праћења рачуна"
        subtitle="Овај водич покрива три кључне фазе закупа стана у Београду: потрагу, уговор и управљање режијама."
        ctaText="Решење: Пратите кирију и рачуне на једном месту уз Stanomer"
        ctaSubtext="Ваши подаци се чувају директно на вашем уређају (local storage). Подаци о уплатама и рачунима се не шаљу на сервере у облаку нити се деле са трећим лицима."
        canonicalUrl="https://www.stanomer.online/guide/vodic-za-izdavanje-stanova-beograd-cirilica"
      >
        {/* Intro */}
        <div className="space-y-4">
          <p className="text-gray-700 leading-relaxed">
            Било да се селите због студија, посла или једноставно тражите нови дом, потрага за правим станом у Београду може бити изазов. Ипак, уз праве информације, овај процес може бити знатно лакши. Губитак времена на непроверене огласе, превид важних ставки у уговору или заборављање датума за плаћање рачуна могу непотребно закомпликовати ствари. Овај водич покрива три кључне фазе закупа стана у Београду: <strong>потрагу, уговор и управљање режијама</strong>.
          </p>
        </div>

        {/* Quick Summary Grid Box */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 my-8" lang="sr-Cyrl">
          <div className="p-4 rounded-xl bg-blue-50/70 border border-blue-100 flex items-start gap-3">
            <Building className="w-5 h-5 text-brand-blue flex-shrink-0 mt-0.5" />
            <div>
              <h4 className="font-bold text-xs text-gray-900 tracking-wider mb-1">1. ПРОНАЛАЗАК</h4>
              <p className="text-xs text-gray-600">Врачар, Стари Град, Нови Београд, Звездара и огласи.</p>
            </div>
          </div>

          <div className="p-4 rounded-xl bg-green-50/70 border border-green-100 flex items-start gap-3">
            <FileText className="w-5 h-5 text-brand-green flex-shrink-0 mt-0.5" />
            <div>
              <h4 className="font-bold text-xs text-gray-900 tracking-wider mb-1">2. УГОВОР О ЗАКУПУ</h4>
              <p className="text-xs text-gray-600">Отказни рок, депозит, режије и записник о примопредаји.</p>
            </div>
          </div>

          <div className="p-4 rounded-xl bg-amber-50/70 border border-amber-100 flex items-start gap-3">
            <Receipt className="w-5 h-5 text-amber-600 flex-shrink-0 mt-0.5" />
            <div>
              <h4 className="font-bold text-xs text-gray-900 tracking-wider mb-1">3. РЕЖИЈЕ И РАЧУНИ</h4>
              <p className="text-xs text-gray-600">ЕПС струја, Инфостан и интернет без Viber/WhatsApp хаоса.</p>
            </div>
          </div>
        </div>

        {/* Section 1 */}
        <section className="space-y-4 pt-4 border-t border-gray-100" lang="sr-Cyrl">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-brand-blue rounded-full"></span>
            Савети за проналазак правог стана у Београду
          </h2>

          <p className="text-gray-700 leading-relaxed">
            Тржиште некретнина у Београду се драстично разликује од општине до општине. <strong>Врачар</strong> и <strong>Стари Град</strong> нуде близину центру, али долазе са вишим ценама. <strong>Нови Београд</strong> је, са модерним зградама и близином пословних центара, све популарнији међу професионалцима. За студенте, <strong>Звездара</strong> и <strong>Вождовац</strong> нуде одличан баланс цене и повезаности са факултетима.
          </p>

          <div className="bg-gray-50/80 p-5 rounded-2xl border border-gray-200/80 space-y-3">
            <h3 className="font-bold text-gray-900 text-sm tracking-wide flex items-center gap-2">
              <Sparkles className="w-4 h-4 text-brand-blue" />
              НА ШТА ТРЕБА ОБРАТИТИ ПАЖЊУ:
            </h3>

            <ul className="space-y-2 text-sm text-gray-700">
              <li className="flex items-start gap-2.5">
                <CheckCircle2 className="w-4 h-4 text-brand-blue flex-shrink-0 mt-1" />
                <span>Када претражујете <code className="bg-gray-200 px-1.5 py-0.5 rounded text-brand-blue font-semibold">издавање станова Београд</code>, обавезно упоредите више платформи. Исти стан може имати различиту цену на различитим сајтовима.</span>
              </li>
              <li className="flex items-start gap-2.5">
                <CheckCircle2 className="w-4 h-4 text-brand-blue flex-shrink-0 mt-1" />
                <span>Странци често претражују термине попут <i>apartments for rent in Belgrade</i>, али локални огласи на српском језику често нуде директан контакт са власницима, без агенцијске провизије.</span>
              </li>
              <li className="flex items-start gap-2.5">
                <CheckCircle2 className="w-4 h-4 text-brand-blue flex-shrink-0 mt-1" />
                <span>Јасно дефинишите депозит. Углавном се тражи износ у висини једне или две месечне кирије. Обавезно тражите да услови повраћаја депозита буду написмено дефинисани.</span>
              </li>
            </ul>
          </div>
        </section>

        {/* Section 2 */}
        <section className="space-y-4 pt-6 border-t border-gray-100">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-brand-green rounded-full"></span>
            Правни детаљи: На шта пазити код Уговора о закупу
          </h2>

          <p className="text-gray-700 leading-relaxed">
            У Србији, уговор о закупу штити и станодавца и закупца. Пре него што потпишете, проверите следеће:
          </p>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="p-4 rounded-xl bg-white border border-gray-200 shadow-xs space-y-2">
              <h4 className="font-bold text-gray-900 text-sm flex items-center gap-2">
                <FileText className="w-4 h-4 text-brand-green" />
                Трајање уговора и отказни рок
              </h4>
              <p className="text-xs text-gray-600 leading-relaxed">
                Јасно дефинишите да ли је уговор на одређено или неодређено време и колико раније морате најавити исељење.
              </p>
            </div>

            <div className="p-4 rounded-xl bg-white border border-gray-200 shadow-xs space-y-2">
              <h4 className="font-bold text-gray-900 text-sm flex items-center gap-2">
                <FileText className="w-4 h-4 text-brand-green" />
                Обавезе плаћања рачуна
              </h4>
              <p className="text-xs text-gray-600 leading-relaxed">
                Да ли су струја, Инфостан и интернет укључени у цену кирије? Ово мора бити прецизирано како би се избегли неспоразуми.
              </p>
            </div>

            <div className="p-4 rounded-xl bg-white border border-gray-200 shadow-xs space-y-2 md:col-span-2">
              <h4 className="font-bold text-gray-900 text-sm flex items-center gap-2">
                <FileText className="w-4 h-4 text-brand-green" />
                Записник о примопредаји
              </h4>
              <p className="text-xs text-gray-600 leading-relaxed">
                Сликајте стање стана и намештаја при усељењу и приложите то уз уговор.
              </p>
            </div>
          </div>
        </section>

        {/* Section 3 */}
        <section className="space-y-4 pt-6 border-t border-gray-100">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-amber-500 rounded-full"></span>
            Управљање рачунима за струју, воду и интернет
          </h2>

          <p className="text-gray-700 leading-relaxed">
            Након усељења, креће свакодневна рутина: праћење и плаћање рачуна. Рачуни за ЕПС (струја), Инфостан и интернет стижу одвојено и имају различите рокове доспећа.
          </p>

          <div className="p-5 rounded-2xl bg-amber-50/60 border border-amber-200/70 space-y-3">
            <p className="text-sm text-gray-700 leading-relaxed">
              Када се рачуни деле (нпр. са цимерима) или када станодавац тражи доказ о уплати, комуникација се често сведе на хаотичне поруке на WhatsApp-у и Viber-у, што доводи до заборављених уплата.
            </p>
          </div>
        </section>

        {/* Section 4: Solution */}
        <section className="space-y-5 pt-6 border-t border-gray-100">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-brand-blue rounded-full"></span>
            Решење: Пратите кирију и рачуне на једном месту уз Stanomer
          </h2>

          <p className="text-gray-700 leading-relaxed">
            Сви ови проблеми – загубљени рачуни, заборављени рокови и лоша комуникација – решавају се добром организацијом. Stanomer је дигитални асистент дизајниран управо за то.
          </p>

          <div className="bg-gradient-to-r from-blue-50 via-white to-green-50 p-6 rounded-2xl border border-gray-200 space-y-4">
            <h3 className="font-bold text-gray-900 text-base flex items-center gap-2">
              <ShieldCheck className="w-5 h-5 text-brand-blue" />
              Са Stanomer-ом:
            </h3>

            <div className="space-y-2 text-sm text-gray-700">
              <div className="p-3 bg-white rounded-xl border border-gray-200/80">
                <h4 className="font-bold text-gray-900 mb-1">Бележите сваку уплату кирије</h4>
                <p className="text-xs text-gray-600">На једном, прегледном екрану видите шта је плаћено, а шта касни.</p>
              </div>

              <div className="p-3 bg-white rounded-xl border border-gray-200/80">
                <h4 className="font-bold text-gray-900 mb-1">Дигитално архивирајте све рачуне</h4>
                <p className="text-xs text-gray-600">Дигитално архивирајте све рачуне за струју, воду и интернет. Нема више претурања по фиокама и порукама.</p>
              </div>

              <div className="p-3 bg-white rounded-xl border border-gray-200/80">
                <h4 className="font-bold text-gray-900 mb-1">Потпуна приватност података</h4>
                <p className="text-xs text-gray-600">Оно што Stanomer издваја је приватност: ваши подаци се чувају директно на вашем уређају (local storage). Подаци о уплатама и рачунима се не шаљу на сервере у облаку нити се деле са трећим лицима. Ваше финансије остају потпуно приватне.</p>
              </div>
            </div>

            {/* Direct High Converting CTA Button Box */}
            <div className="pt-4 text-center sm:text-left border-t border-gray-200/60">
              <div className="p-5 rounded-xl bg-brand-blue text-white space-y-3 shadow-lg">
                <p className="font-bold text-sm leading-snug">
                  📲 Ако се усељавате у нови стан у Београду, будите организовани од првог дана. Преузмите Stanomer са App Store-а или Google Play-а и дигитализујте праћење својих трошкова.
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
