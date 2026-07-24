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
  title: "Vodič za izdavanje stanova u Beogradu: Od pronalaska do računa | Stanomer",
  description: "Vodič za izdavanje stanova u Beogradu: saveti za pretragu (Vračar, Novi Beograd), ugovor o zakupu, račun za EPS i Infostan i praćenje kirije uz Stanomer.",
  keywords: [
    "Vodič za izdavanje stanova Beograd",
    "izdavanje stanova beograd",
    "stanovi beograd najam",
    "ugovor o zakupu",
    "infostan racuni",
    "eps struja beograd",
    "apartments for rent in belgrade",
    "stanomer"
  ],
  alternates: {
    canonical: "https://www.stanomer.online/guide/vodic-za-izdavanje-stanova-beograd",
    languages: {
      "tr": "https://www.stanomer.online/guide/belgrad-kiralik-daire-rehberi",
      "en": "https://www.stanomer.online/guide/belgrade-apartment-rental-guide",
      "sr": "https://www.stanomer.online/guide/vodic-za-izdavanje-stanova-beograd",
      "sr-Cyrl": "https://www.stanomer.online/guide/vodic-za-izdavanje-stanova-beograd-cirilica",
    }
  },
  openGraph: {
    title: "Vodič za izdavanje stanova u Beogradu | Stanomer",
    description: "Od pronalaska stana i Ugovora o zakupu do praćenja računa za struju i Infostan.",
    url: "https://www.stanomer.online/guide/vodic-za-izdavanje-stanova-beograd",
    siteName: "Stanomer",
    locale: "sr_RS",
    type: "article",
  }
};

const jsonLd = {
  "@context": "https://schema.org",
  "@type": "Article",
  "headline": "Vodič za izdavanje stanova u Beogradu: Od pronalaska do praćenja računa",
  "description": "Sveobuhvatni vodič za zakupce u Beogradu: pretraga, ugovor o zakupu i vođenje računa.",
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
  "mainEntityOfPage": "https://www.stanomer.online/guide/vodic-za-izdavanje-stanova-beograd",
  "inLanguage": "sr-Latn"
};

export default function SerbianLatinGuidePage() {
  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
      />
      <GuideLayout
        currentLang="SR_LAT"
        title="Vodič za izdavanje stanova u Beogradu: Od pronalaska do praćenja računa"
        subtitle="Ovaj vodič pokriva tri ključne faze zakupa stana u Beogradu: potragu, ugovor i upravljanje režijama."
        ctaText="Rešenje: Pratite kiriju i račune na jednom mestu uz Stanomer"
        ctaSubtext="Vaši podaci se čuvaju direktno na vašem uređaju (local storage). Podaci o uplatama i računima se ne šalju na servere u oblaku niti se dele sa trećim licima."
        canonicalUrl="https://www.stanomer.online/guide/vodic-za-izdavanje-stanova-beograd"
      >
        {/* Intro */}
        <div className="space-y-4">
          <p className="text-gray-700 leading-relaxed">
            Bilo da se selite zbog studija, posla ili jednostavno tražite novi dom, potraga za pravim stanom u Beogradu može biti izazov. Ipak, uz prave informacije, ovaj proces može biti znatno lakši. Gubitak vremena na neproverene oglase, previd važnih stavki u ugovoru ili zaboravljanje datuma za plaćanje računa mogu nepotrebno zakomplikovati stvari. Ovaj vodič pokriva tri ključne faze zakupa stana u Beogradu: <strong>potragu, ugovor i upravljanje režijama</strong>.
          </p>
        </div>

        {/* Quick Summary Grid Box */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 my-8" lang="sr">
          <div className="p-4 rounded-xl bg-blue-50/70 border border-blue-100 flex items-start gap-3">
            <Building className="w-5 h-5 text-brand-blue flex-shrink-0 mt-0.5" />
            <div>
              <h4 className="font-bold text-xs text-gray-900 tracking-wider mb-1">1. PRONALAZAK</h4>
              <p className="text-xs text-gray-600">Vračar, Stari Grad, Novi Beograd, Zvezdara i oglasi.</p>
            </div>
          </div>

          <div className="p-4 rounded-xl bg-green-50/70 border border-green-100 flex items-start gap-3">
            <FileText className="w-5 h-5 text-brand-green flex-shrink-0 mt-0.5" />
            <div>
              <h4 className="font-bold text-xs text-gray-900 tracking-wider mb-1">2. UGOVOR O ZAKUPU</h4>
              <p className="text-xs text-gray-600">Otkazni rok, depozit, režije i zapisnik o primopredaji.</p>
            </div>
          </div>

          <div className="p-4 rounded-xl bg-amber-50/70 border border-amber-100 flex items-start gap-3">
            <Receipt className="w-5 h-5 text-amber-600 flex-shrink-0 mt-0.5" />
            <div>
              <h4 className="font-bold text-xs text-gray-900 tracking-wider mb-1">3. REŽIJE I RAČUNI</h4>
              <p className="text-xs text-gray-600">EPS struja, Infostan i internet bez Viber/WhatsApp haosa.</p>
            </div>
          </div>
        </div>

        {/* Section 1 */}
        <section className="space-y-4 pt-4 border-t border-gray-100" lang="sr">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-brand-blue rounded-full"></span>
            Saveti za pronalazak pravog stana u Beogradu
          </h2>

          <p className="text-gray-700 leading-relaxed">
            Tržište nekretnina u Beogradu se drastično razlikuje od opštine do opštine. <strong>Vračar</strong> i <strong>Stari Grad</strong> nude blizinu centru, ali dolaze sa višim cenama. <strong>Novi Beograd</strong> je, sa modernim zgradama i blizinom poslovnih centara, sve popularniji među profesionalcima. Za studente, <strong>Zvezdara</strong> i <strong>Voždovac</strong> nude odličan balans cene i povezanosti sa fakultetima.
          </p>

          <div className="bg-gray-50/80 p-5 rounded-2xl border border-gray-200/80 space-y-3">
            <h3 className="font-bold text-gray-900 text-sm tracking-wide flex items-center gap-2">
              <Sparkles className="w-4 h-4 text-brand-blue" />
              NA ŠTA TREBA OBRATITI PAŽNJU:
            </h3>

            <ul className="space-y-2 text-sm text-gray-700">
              <li className="flex items-start gap-2.5">
                <CheckCircle2 className="w-4 h-4 text-brand-blue flex-shrink-0 mt-1" />
                <span>Kada pretražujete <code className="bg-gray-200 px-1.5 py-0.5 rounded text-brand-blue font-semibold">izdavanje stanova Beograd</code>, obavezno uporedite više platformi. Isti stan može imati različitu cenu na različitim sajtovima.</span>
              </li>
              <li className="flex items-start gap-2.5">
                <CheckCircle2 className="w-4 h-4 text-brand-blue flex-shrink-0 mt-1" />
                <span>Stranci često pretražuju termine poput <i>apartments for rent in Belgrade</i>, ali lokalni oglasi na srpskom jeziku često nude direktan kontakt sa vlasnicima, bez agencijske provizije.</span>
              </li>
              <li className="flex items-start gap-2.5">
                <CheckCircle2 className="w-4 h-4 text-brand-blue flex-shrink-0 mt-1" />
                <span>Jasno definišite depozit. Uglavnom se traži iznos u visini jedne ili dve mesečne kirije. Obavezno tražite da uslovi povraćaja depozita budu napismeno definisani.</span>
              </li>
            </ul>
          </div>
        </section>

        {/* Section 2 */}
        <section className="space-y-4 pt-6 border-t border-gray-100">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-brand-green rounded-full"></span>
            Pravni detalji: Na šta paziti kod Ugovora o zakupu
          </h2>

          <p className="text-gray-700 leading-relaxed">
            U Srbiji, ugovor o zakupu štiti i stanodavca i zakupca. Pre nego što potpišete, proverite sledeće:
          </p>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="p-4 rounded-xl bg-white border border-gray-200 shadow-xs space-y-2">
              <h4 className="font-bold text-gray-900 text-sm flex items-center gap-2">
                <FileText className="w-4 h-4 text-brand-green" />
                Trajanje ugovora i otkazni rok
              </h4>
              <p className="text-xs text-gray-600 leading-relaxed">
                Jasno definišite da li je ugovor na određeno ili neodređeno vreme i koliko ranije morate najaviti iseljenje.
              </p>
            </div>

            <div className="p-4 rounded-xl bg-white border border-gray-200 shadow-xs space-y-2">
              <h4 className="font-bold text-gray-900 text-sm flex items-center gap-2">
                <FileText className="w-4 h-4 text-brand-green" />
                Obaveze plaćanja računa
              </h4>
              <p className="text-xs text-gray-600 leading-relaxed">
                Da li su struja, Infostan i internet uključeni u cenu kirije? Ovo mora biti precizirano kako bi se izbegli nesporazumi.
              </p>
            </div>

            <div className="p-4 rounded-xl bg-white border border-gray-200 shadow-xs space-y-2 md:col-span-2">
              <h4 className="font-bold text-gray-900 text-sm flex items-center gap-2">
                <FileText className="w-4 h-4 text-brand-green" />
                Zapisnik o primopredaji
              </h4>
              <p className="text-xs text-gray-600 leading-relaxed">
                Slikajte stanje stana i nameštaja pri useljenju i priložite to uz ugovor.
              </p>
            </div>
          </div>
        </section>

        {/* Section 3 */}
        <section className="space-y-4 pt-6 border-t border-gray-100">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-amber-500 rounded-full"></span>
            Upravljanje računima za struju, vodu i internet
          </h2>

          <p className="text-gray-700 leading-relaxed">
            Nakon useljenja, kreće svakodnevna rutina: praćenje i plaćanje računa. Računi za EPS (struja), Infostan i internet stižu odvojeno i imaju različite rokove dospeća.
          </p>

          <div className="p-5 rounded-2xl bg-amber-50/60 border border-amber-200/70 space-y-3">
            <p className="text-sm text-gray-700 leading-relaxed">
              Kada se računi dele (npr. sa cimerima) ili kada stanodavac traži dokaz o uplati, komunikacija se često svede na haotične poruke na WhatsApp-u i Viber-u, što dovodi do zaboravljenih uplata.
            </p>
          </div>
        </section>

        {/* Section 4: Solution */}
        <section className="space-y-5 pt-6 border-t border-gray-100">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-brand-blue rounded-full"></span>
            Rešenje: Pratite kiriju i račune na jednom mestu uz Stanomer
          </h2>

          <p className="text-gray-700 leading-relaxed">
            Svi ovi problemi – zagubljeni računi, zaboravljeni rokovi i loša komunikacija – rešavaju se dobrom organizacijom. Stanomer je digitalni asistent dizajniran upravo za to.
          </p>

          <div className="bg-gradient-to-r from-blue-50 via-white to-green-50 p-6 rounded-2xl border border-gray-200 space-y-4">
            <h3 className="font-bold text-gray-900 text-base flex items-center gap-2">
              <ShieldCheck className="w-5 h-5 text-brand-blue" />
              Sa Stanomerom:
            </h3>

            <div className="space-y-2 text-sm text-gray-700">
              <div className="p-3 bg-white rounded-xl border border-gray-200/80">
                <h4 className="font-bold text-gray-900 mb-1">Beležite svaku uplatu kirije</h4>
                <p className="text-xs text-gray-600">Na jednom, preglednom ekranu vidite šta je plaćeno, a šta kasni.</p>
              </div>

              <div className="p-3 bg-white rounded-xl border border-gray-200/80">
                <h4 className="font-bold text-gray-900 mb-1">Digitalno arhivirajte sve račune</h4>
                <p className="text-xs text-gray-600">Sve uplatnice i računi za struju, vodu i internet na jednom mestu. Nema više preturanja po fiokama i porukama.</p>
              </div>

              <div className="p-3 bg-white rounded-xl border border-gray-200/80">
                <h4 className="font-bold text-gray-900 mb-1">Potpuna privatnost podataka</h4>
                <p className="text-xs text-gray-600">Ono što Stanomer izdvaja je privatnost: vaši podaci se čuvaju direktno na vašem uređaju (local storage). Podaci o uplatama i računima se ne šalju na servere u oblaku niti se dele sa trećim licima. Vaše finansije ostaju potpuno privatne.</p>
              </div>
            </div>

            {/* Direct High Converting CTA Button Box */}
            <div className="pt-4 text-center sm:text-left border-t border-gray-200/60">
              <div className="p-5 rounded-xl bg-brand-blue text-white space-y-3 shadow-lg">
                <p className="font-bold text-sm leading-snug">
                  📲 Ako se useljavate u novi stan u Beogradu, budite organizovani od prvog dana. Preuzmite Stanomer sa App Store-a ili Google Play-a i digitalizujte praćenje svojih troškova.
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
