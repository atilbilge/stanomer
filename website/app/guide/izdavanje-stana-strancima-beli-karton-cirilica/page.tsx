import type { Metadata } from "next";
import { GuideLayout } from "../../../components/GuideLayout";
import { 
  Globe2, 
  ShieldCheck, 
  CheckCircle2, 
  AlertCircle, 
  Sparkles,
  FileCheck,
  MessageSquare,
  BadgeDollarSign,
  Lock
} from "lucide-react";

export const metadata: Metadata = {
  title: "Како безбедно издати стан странцима и дигиталним номадима у Београду и Новом Саду | Stanomer",
  description: "Све што треба да знате о процесу пријаве (Бели картон), комуникацији и праћењу кирија када издајете стан странцима у Србији.",
  keywords: [
    "Бели картон Србија",
    "пријава боравишта странца МУП",
    "издавање стана странцима Београд",
    "дигитални номади Нови Сад",
    "еУправа пријава стана",
    "станодавци Србија",
    "станомер апликација"
  ],
  alternates: {
    canonical: "https://www.stanomer.online/guide/izdavanje-stana-strancima-beli-karton-cirilica",
    languages: {
      "tr": "https://www.stanomer.online/guide/dijital-gocmenlere-ev-kiralama-beli-karton",
      "en": "https://www.stanomer.online/guide/renting-to-foreigners-digital-nomads-beli-karton",
      "sr": "https://www.stanomer.online/guide/izdavanje-stana-strancima-beli-karton",
      "sr-Cyrl": "https://www.stanomer.online/guide/izdavanje-stana-strancima-beli-karton-cirilica",
      "ru": "https://www.stanomer.online/guide/renting-to-foreigners-digital-nomads-beli-karton-ru",
    }
  },
  openGraph: {
    title: "Како безбедно издати стан странцима и дигиталним номадима у Београду и Новом Саду | Stanomer",
    description: "Све што треба да знате о процесу пријаве (Бели картон), комуникацији и праћењу кирија када издајете стан странцима у Србији.",
    url: "https://www.stanomer.online/guide/izdavanje-stana-strancima-beli-karton-cirilica",
    siteName: "Stanomer",
    locale: "sr_RS",
    type: "article",
  }
};

const jsonLd = {
  "@context": "https://schema.org",
  "@type": "Article",
  "headline": "Како безбедно издати стан странцима и дигиталним номадима у Београду и Новом Саду",
  "description": "Све што треба да знате о процесу пријаве (Бели картон), комуникацији и праћењу кирија када издајете стан странцима у Србији.",
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
  "mainEntityOfPage": "https://www.stanomer.online/guide/izdavanje-stana-strancima-beli-karton-cirilica",
  "inLanguage": "sr-Cyrl"
};

export default function BeliKartonSerbianCyrillicGuidePage() {
  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
      />
      <GuideLayout
        currentLang="SR_CYR"
        categoryTitle="Издавање Странцима & Бели Картон"
        locationName="Београд & Нови Сад"
        title="Како безбедно издати стан странцима и дигиталним номадима у Београду и Новом Саду"
        subtitle="Све што треба да знате о процесу пријаве (Бели картон), комуникацији и праћењу кирија када издајете стан странцима у Србији."
        ctaText="Професионализујте управљање за интернационалне закупце уз Станомер"
        ctaSubtext="Пратите све уплате и рачуне уз Станомер двојезички систем и 100% локално складиштење података на вашем телефону."
        canonicalUrl="https://www.stanomer.online/guide/izdavanje-stana-strancima-beli-karton-cirilica"
      >
        {/* Intro */}
        <div className="space-y-4" lang="sr">
          <p className="text-gray-700 leading-relaxed">
            Последњих година Србија је постала један од најпопуларнијих центара за дигиталне номаде и странце у Европи. Динамика <strong>Београда</strong> и миран темпо <strong>Новог Сада</strong> привлаче професионалце из целог света.
          </p>
          <p className="text-gray-700 leading-relaxed">
            Иако издавање стана странцима често доноси већи приход, оно са собом носи и одређене административне обавезе за станодавце.
          </p>
        </div>

        {/* Quick Highlights Box */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 my-8" lang="sr">
          <div className="p-4 rounded-xl bg-blue-50/70 border border-blue-100 flex items-start gap-3">
            <FileCheck className="w-5 h-5 text-brand-blue flex-shrink-0 mt-0.5" />
            <div>
              <h4 className="font-bold text-xs text-gray-900 tracking-wider mb-1">1. БЕЛИ КАРТОН</h4>
              <p className="text-xs text-gray-600">Пријава боравишта у МУП-у или е-Управи у року од 24х је законска обавеза.</p>
            </div>
          </div>

          <div className="p-4 rounded-xl bg-green-50/70 border border-green-100 flex items-start gap-3">
            <MessageSquare className="w-5 h-5 text-brand-green flex-shrink-0 mt-0.5" />
            <div>
              <h4 className="font-bold text-xs text-gray-900 tracking-wider mb-1">2. ДВОЈЕЗИЧНИ УГОВОР</h4>
              <p className="text-xs text-gray-600">Двојезични уговор (српски и енглески) и кратак Водич добродошлице.</p>
            </div>
          </div>

          <div className="p-4 rounded-xl bg-amber-50/70 border border-amber-100 flex items-start gap-3">
            <BadgeDollarSign className="w-5 h-5 text-amber-600 flex-shrink-0 mt-0.5" />
            <div>
              <h4 className="font-bold text-xs text-gray-900 tracking-wider mb-1">3. ЕВИДЕНЦИЈА & ПРИВАТНОСТ</h4>
              <p className="text-xs text-gray-600">Праћење евро кирија и динарских рачуна уз Станомер local storage приватност.</p>
            </div>
          </div>
        </div>

        {/* Section 1 */}
        <section className="space-y-4 pt-4 border-t border-gray-100" lang="sr">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-brand-blue rounded-full"></span>
            1. Не прескачите процедуру за &quot;Бели картон&quot;
          </h2>

          <p className="text-gray-700 leading-relaxed">
            Најважнија законска обавеза када издајете стан странцу је пријава боравишта, позната као <strong>Бели картон</strong>.
          </p>

          <div className="bg-gray-50/80 p-5 rounded-2xl border border-gray-200/80 space-y-3">
            <h3 className="font-bold text-gray-900 text-sm tracking-wide flex items-center gap-2">
              <Sparkles className="w-4 h-4 text-brand-blue" />
              ЗАКОНСКИ РОК И ПРИЈАВА:
            </h3>

            <p className="text-sm text-gray-700 leading-relaxed">
              Страни држављанин мора бити пријављен у локалној полицијској станици (<strong>МУП</strong>) или преко портала <strong>е-Управа</strong> у року од <strong>24 сата</strong> од уласка у земљу. Ви, као станодавац, морате одобрити ову пријаву.
            </p>
          </div>
        </section>

        {/* Section 2 */}
        <section className="space-y-4 pt-6 border-t border-gray-100" lang="sr">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-brand-green rounded-full"></span>
            2. Комуникација и језичка баријера
          </h2>

          <p className="text-gray-700 leading-relaxed">
            Комуникација са дигиталним номадима се углавном одвија на енглеском језику. Веома је важно да ваш уговор о закупу буде <strong>двојезичан (српски и енглески)</strong>.
          </p>

          <p className="text-gray-700 leading-relaxed">
            Такође, кратак &quot;Водич добродошлице&quot; на енглеском језику са контактима за хитне поправке учиниће да изгледате много професионалније.
          </p>
        </section>

        {/* Section 3 */}
        <section className="space-y-4 pt-6 border-t border-gray-100" lang="sr">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-amber-500 rounded-full"></span>
            3. Валуте и праћење плаћања
          </h2>

          <p className="text-gray-700 leading-relaxed">
            Плаћање кирије се често врши у еврима, док локални рачуни (струја, интернет) стижу у динарима. Праћење да ли је странац на време платио ове рачуне може постати компликовано.
          </p>
        </section>

        {/* Section 4 */}
        <section className="space-y-5 pt-6 border-t border-gray-100" lang="sr">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-brand-blue rounded-full"></span>
            4. Професионално управљање за интернационалне закупце
          </h2>

          <p className="text-gray-700 leading-relaxed">
            Страни закупци веома цене приватност података и транспарентност. Уместо размене слика уплатница преко WhatsApp-а, коришћење дигиталног система гради поверење.
          </p>

          <div className="bg-gradient-to-r from-blue-50 via-white to-green-50 p-6 rounded-2xl border border-gray-200 space-y-4">
            <h3 className="font-bold text-gray-900 text-base flex items-center gap-2">
              <ShieldCheck className="w-5 h-5 text-brand-blue" />
              Управљање уз Станомер апликацију:
            </h3>

            <p className="text-sm text-gray-700 leading-relaxed">
              Управљањем преко <strong>Станомер</strong> апликације, на једном екрану можете видети све уплате и рачуне. Захваљујући <strong>local storage</strong> архитектури, финансијски подаци вас и ваших станара остају искључиво на вашем телефону, пружајући максималну приватност и премијум искуство.
            </p>

            {/* CTA Box */}
            <div className="pt-4 text-center sm:text-left border-t border-gray-200/60">
              <div className="p-5 rounded-xl bg-brand-blue text-white space-y-3 shadow-lg">
                <p className="font-bold text-sm leading-snug">
                  🌐 Пружите врхунско искуство страним станарима. Преузмите Станомер и водите уплате без стреса.
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
