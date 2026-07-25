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
  title: "Kako bezbedno izdati stan strancima i digitalnim nomadima u Beogradu i Novom Sadu | Stanomer",
  description: "Sve što treba da znate o procesu prijave (Beli karton), komunikaciji i praćenju kirija kada izdajete stan strancima u Srbiji.",
  keywords: [
    "Beli karton Srbija",
    "prijava boravista stranca MUP",
    "izdavanje stana strancima Beograd",
    "digitalni nomadi Novi Sad",
    "eUprava prijava stana",
    "stanodavci Srbija",
    "stanomer aplikacija"
  ],
  alternates: {
    canonical: "https://www.stanomer.online/guide/izdavanje-stana-strancima-beli-karton",
    languages: {
      "tr": "https://www.stanomer.online/guide/dijital-gocmenlere-ev-kiralama-beli-karton",
      "en": "https://www.stanomer.online/guide/renting-to-foreigners-digital-nomads-beli-karton",
      "sr": "https://www.stanomer.online/guide/izdavanje-stana-strancima-beli-karton",
      "sr-Cyrl": "https://www.stanomer.online/guide/izdavanje-stana-strancima-beli-karton-cirilica",
      "ru": "https://www.stanomer.online/guide/renting-to-foreigners-digital-nomads-beli-karton-ru",
    }
  },
  openGraph: {
    title: "Kako bezbedno izdati stan strancima i digitalnim nomadima u Beogradu i Novom Sadu | Stanomer",
    description: "Sve što treba da znate o procesu prijave (Beli karton), komunikaciji i praćenju kirija kada izdajete stan strancima u Srbiji.",
    url: "https://www.stanomer.online/guide/izdavanje-stana-strancima-beli-karton",
    siteName: "Stanomer",
    locale: "sr_RS",
    type: "article",
  }
};

const jsonLd = {
  "@context": "https://schema.org",
  "@type": "Article",
  "headline": "Kako bezbedno izdati stan strancima i digitalnim nomadima u Beogradu i Novom Sadu",
  "description": "Sve što treba da znate o procesu prijave (Beli karton), komunikaciji i praćenju kirija kada izdajete stan strancima u Srbiji.",
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
  "mainEntityOfPage": "https://www.stanomer.online/guide/izdavanje-stana-strancima-beli-karton",
  "inLanguage": "sr-Latn"
};

export default function BeliKartonSerbianLatinGuidePage() {
  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
      />
      <GuideLayout
        currentLang="SR_LAT"
        categoryTitle="Izdavanje Strancima & Beli Karton"
        locationName="Beograd & Novi Sad"
        title="Kako bezbedno izdati stan strancima i digitalnim nomadima u Beogradu i Novom Sadu"
        subtitle="Sve što treba da znate o procesu prijave (Beli karton), komunikaciji i praćenju kirija kada izdajete stan strancima u Srbiji."
        ctaText="Profesionalizujte upravljanje za internacionalne zakupce uz Stanomer"
        ctaSubtext="Pratite sve uplate i račune uz Stanomer dvojezički sistem i 100% lokalno skladištenje podataka na vašem telefonu."
        canonicalUrl="https://www.stanomer.online/guide/izdavanje-stana-strancima-beli-karton"
      >
        {/* Intro */}
        <div className="space-y-4" lang="sr">
          <p className="text-gray-700 leading-relaxed">
            Poslednjih godina Srbija je postala jedan od najpopularnijih centara za digitalne nomade i strance u Evropi. Dinamika <strong>Beograda</strong> i miran tempo <strong>Novog Sada</strong> privlače profesionalce iz celog sveta.
          </p>
          <p className="text-gray-700 leading-relaxed">
            Iako izdavanje stana strancima često donosi veći prihod, ono sa sobom nosi i određene administrativne obaveze za stanodavce.
          </p>
        </div>

        {/* Quick Highlights Box */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 my-8" lang="sr">
          <div className="p-4 rounded-xl bg-blue-50/70 border border-blue-100 flex items-start gap-3">
            <FileCheck className="w-5 h-5 text-brand-blue flex-shrink-0 mt-0.5" />
            <div>
              <h4 className="font-bold text-xs text-gray-900 tracking-wider mb-1">1. BELI KARTON</h4>
              <p className="text-xs text-gray-600">Prijava boravišta u MUP-u ili e-Upravi u roku od 24h je zakonska obaveza.</p>
            </div>
          </div>

          <div className="p-4 rounded-xl bg-green-50/70 border border-green-100 flex items-start gap-3">
            <MessageSquare className="w-5 h-5 text-brand-green flex-shrink-0 mt-0.5" />
            <div>
              <h4 className="font-bold text-xs text-gray-900 tracking-wider mb-1">2. DVOJEZIČNI UGOVOR</h4>
              <p className="text-xs text-gray-600">Dvojezični ugovor (srpski i engleski) i kratak Vodič dobrodošlice.</p>
            </div>
          </div>

          <div className="p-4 rounded-xl bg-amber-50/70 border border-amber-100 flex items-start gap-3">
            <BadgeDollarSign className="w-5 h-5 text-amber-600 flex-shrink-0 mt-0.5" />
            <div>
              <h4 className="font-bold text-xs text-gray-900 tracking-wider mb-1">3. EVIDENCIJA & PRIVATNOST</h4>
              <p className="text-xs text-gray-600">Praćenje evro kirija i dinarskih računa uz Stanomer local storage privatnost.</p>
            </div>
          </div>
        </div>

        {/* Section 1 */}
        <section className="space-y-4 pt-4 border-t border-gray-100" lang="sr">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-brand-blue rounded-full"></span>
            1. Ne preskačite proceduru za &quot;Beli karton&quot;
          </h2>

          <p className="text-gray-700 leading-relaxed">
            Najvažnija zakonska obaveza kada izdajete stan strancu je prijava boravišta, poznata kao <strong>Beli karton</strong>.
          </p>

          <div className="bg-gray-50/80 p-5 rounded-2xl border border-gray-200/80 space-y-3">
            <h3 className="font-bold text-gray-900 text-sm tracking-wide flex items-center gap-2">
              <Sparkles className="w-4 h-4 text-brand-blue" />
              ZAKONSKI ROK I PRIJAVA:
            </h3>

            <p className="text-sm text-gray-700 leading-relaxed">
              Strani državljanin mora biti prijavljen u lokalnoj policijskoj stanici (<strong>MUP</strong>) ili preko portala <strong>e-Uprava</strong> u roku od <strong>24 sata</strong> od ulaska u zemlju. Vi, kao stanodavac, morate odobriti ovu prijavu.
            </p>
          </div>
        </section>

        {/* Section 2 */}
        <section className="space-y-4 pt-6 border-t border-gray-100" lang="sr">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-brand-green rounded-full"></span>
            2. Komunikacija i jezička barijera
          </h2>

          <p className="text-gray-700 leading-relaxed">
            Komunikacija sa digitalnim nomadima se uglavnom odvija na engleskom jeziku. Veoma je važno da vaš ugovor o zakupu bude <strong>dvojezičan (srpski i engleski)</strong>.
          </p>

          <p className="text-gray-700 leading-relaxed">
            Takođe, kratak &quot;Vodič dobrodošlice&quot; na engleskom jeziku sa kontaktima za hitne popravke učiniće da izgledate mnogo profesionalnije.
          </p>
        </section>

        {/* Section 3 */}
        <section className="space-y-4 pt-6 border-t border-gray-100" lang="sr">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-amber-500 rounded-full"></span>
            3. Valute i praćenje plaćanja
          </h2>

          <p className="text-gray-700 leading-relaxed">
            Plaćanje kirije se često vrši u evrima, dok lokalni računi (struja, internet) stižu u dinarima. Praćenje da li je stranac na vreme platio ove račune može postati komplikovano.
          </p>
        </section>

        {/* Section 4 */}
        <section className="space-y-5 pt-6 border-t border-gray-100" lang="sr">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-brand-blue rounded-full"></span>
            4. Profesionalno upravljanje za internacionalne zakupce
          </h2>

          <p className="text-gray-700 leading-relaxed">
            Strani zakupci veoma cene privatnost podataka i transparentnost. Umesto razmene slika uplatnica preko WhatsApp-a, korišćenje digitalnog sistema gradi poverenje.
          </p>

          <div className="bg-gradient-to-r from-blue-50 via-white to-green-50 p-6 rounded-2xl border border-gray-200 space-y-4">
            <h3 className="font-bold text-gray-900 text-base flex items-center gap-2">
              <ShieldCheck className="w-5 h-5 text-brand-blue" />
              Upravljanje uz Stanomer aplikaciju:
            </h3>

            <p className="text-sm text-gray-700 leading-relaxed">
              Upravljanjem preko <strong>Stanomer</strong> aplikacije, na jednom ekranu možete videti sve uplate i račune. Zahvaljujući <strong>local storage</strong> arhitekturi, finansijski podaci vas i vaših stanara ostaju isključivo na vašem telefonu, pružajući maksimalnu privatnost i premijum iskustvo.
            </p>

            {/* CTA Box */}
            <div className="pt-4 text-center sm:text-left border-t border-gray-200/60">
              <div className="p-5 rounded-xl bg-brand-blue text-white space-y-3 shadow-lg">
                <p className="font-bold text-sm leading-snug">
                  🌐 Pružite vrhunsko iskustvo stranim stanarima. Preuzmite Stanomer i vodite uplate bez stresa.
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
