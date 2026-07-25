import type { Metadata } from "next";
import { GuideLayout } from "../../../components/GuideLayout";
import { 
  FileText, 
  ShieldCheck, 
  CheckCircle2, 
  AlertCircle, 
  Sparkles,
  Scale,
  Receipt,
  Clock,
  Lock
} from "lucide-react";

export const metadata: Metadata = {
  title: "Ugovor o zakupu stana u Srbiji: Šta svaki stanodavac mora da zna | Stanomer",
  description: "Kako pravno da se zaštitite prilikom izdavanja stana u Srbiji? Sveobuhvatni vodič o stavkama ugovora o zakupu, depozitu i upravljanju procesima uz Stanomer.",
  keywords: [
    "ugovor o zakupu stana",
    "izdavanje stanova Srbija",
    "ugovor o izdavanju stana Beograd",
    "Novi Sad ugovor o zakupu",
    "prava stanodavaca Srbija",
    "Infostan EPS računi stanari",
    "otkazni rok ugovor o zakupu",
    "stanomer aplikacija"
  ],
  alternates: {
    canonical: "https://www.stanomer.online/guide/ugovor-o-zakupu-stana-srbija",
    languages: {
      "tr": "https://www.stanomer.online/guide/sirbistan-kira-sozlesmesi-rehberi",
      "en": "https://www.stanomer.online/guide/serbia-lease-agreement-guide",
      "sr": "https://www.stanomer.online/guide/ugovor-o-zakupu-stana-srbija",
      "sr-Cyrl": "https://www.stanomer.online/guide/ugovor-o-zakupu-stana-srbija-cirilica",
      "ru": "https://www.stanomer.online/guide/serbia-lease-agreement-guide-ru",
    }
  },
  openGraph: {
    title: "Ugovor o zakupu stana u Srbiji: Šta svaki stanodavac mora da zna | Stanomer",
    description: "Kako pravno da se zaštitite prilikom izdavanja stana u Srbiji? Sveobuhvatni vodič o ugovoru o zakupu i depozitu.",
    url: "https://www.stanomer.online/guide/ugovor-o-zakupu-stana-srbija",
    siteName: "Stanomer",
    locale: "sr_RS",
    type: "article",
  }
};

const jsonLd = {
  "@context": "https://schema.org",
  "@type": "Article",
  "headline": "Ugovor o zakupu stana u Srbiji: Šta svaki stanodavac mora da zna",
  "description": "Kako pravno da se zaštitite prilikom izdavanja stana u Srbiji? Sveobuhvatni vodič o stavkama ugovora o zakupu, depozitu i upravljanju procesima.",
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
  "mainEntityOfPage": "https://www.stanomer.online/guide/ugovor-o-zakupu-stana-srbija",
  "inLanguage": "sr-Latn"
};

export default function LeaseAgreementSerbianLatinGuidePage() {
  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
      />
      <GuideLayout
        currentLang="SR_LAT"
        categoryTitle="Pravni & Ugovorni Vodič"
        locationName="Srbija Cela"
        title="Ugovor o zakupu stana u Srbiji: Šta svaki stanodavac mora da zna"
        subtitle="Kako pravno da se zaštitite prilikom izdavanja stana u Srbiji? Sveobuhvatni vodič o stavkama ugovora o zakupu, depozitu i upravljanju procesima."
        ctaText="Upravljajte ugovorima o zakupu i evidencijom uz Stanomer"
        ctaSubtext="Pratite uplate kirija, račune i datume obnove ugovora uz Stanomer 100% lokalno skladištenje na vašem uređaju."
        canonicalUrl="https://www.stanomer.online/guide/ugovor-o-zakupu-stana-srbija"
      >
        {/* Intro */}
        <div className="space-y-4" lang="sr">
          <p className="text-gray-700 leading-relaxed">
            Tržište nekretnina u Srbiji, posebno u <strong>Beogradu</strong> i <strong>Novom Sadu</strong>, nastavlja ubrzano da raste. Iako ovaj rast pruža odlične prilike za stanodavce, nepostavljanje pravnog i organizovanog okvira može dovesti do ozbiljnih operativnih glavobolja.
          </p>
          <p className="text-gray-700 leading-relaxed">
            Prvi korak uspešnog upravljanja nekretninama je čvrst <strong>ugovor o zakupu stana</strong> koji štiti prava obe strane.
          </p>
        </div>

        {/* Quick Highlights Box */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 my-8" lang="sr">
          <div className="p-4 rounded-xl bg-blue-50/70 border border-blue-100 flex items-start gap-3">
            <Scale className="w-5 h-5 text-brand-blue flex-shrink-0 mt-0.5" />
            <div>
              <h4 className="font-bold text-xs text-gray-900 tracking-wider mb-1">1. OBAVEZNE STAVKE</h4>
              <p className="text-xs text-gray-600">JMBG / pasoš podaci, valuta i datum plaćanja kirije, trajanje ugovora.</p>
            </div>
          </div>

          <div className="p-4 rounded-xl bg-green-50/70 border border-green-100 flex items-start gap-3">
            <Receipt className="w-5 h-5 text-brand-green flex-shrink-0 mt-0.5" />
            <div>
              <h4 className="font-bold text-xs text-gray-900 tracking-wider mb-1">2. DEPOZIT I RAČUNI</h4>
              <p className="text-xs text-gray-600">Odgovornost za Infostan, EPS i internet te zapisnik o stanju inventara.</p>
            </div>
          </div>

          <div className="p-4 rounded-xl bg-amber-50/70 border border-amber-100 flex items-start gap-3">
            <Clock className="w-5 h-5 text-amber-600 flex-shrink-0 mt-0.5" />
            <div>
              <h4 className="font-bold text-xs text-gray-900 tracking-wider mb-1">3. OTKAZNI ROK & DIGITALIZACIJA</h4>
              <p className="text-xs text-gray-600">Standardni rok od 30 dana i vođenje evidencije bez Excel tabela.</p>
            </div>
          </div>
        </div>

        {/* Section 1 */}
        <section className="space-y-4 pt-4 border-t border-gray-100" lang="sr">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-brand-blue rounded-full"></span>
            1. Obavezne stavke u ugovoru o zakupu
          </h2>

          <p className="text-gray-700 leading-relaxed">
            Što je ugovor jasniji, to je manji rizik od budućih sporova. Prema zakonima u Srbiji, važeći ugovor mora jasno navesti sledeće:
          </p>

          <div className="bg-gray-50/80 p-5 rounded-2xl border border-gray-200/80 space-y-3">
            <ul className="space-y-3 text-sm text-gray-700">
              <li className="flex items-start gap-2.5">
                <CheckCircle2 className="w-4 h-4 text-brand-blue flex-shrink-0 mt-1" />
                <span><strong>Identifikacioni podaci:</strong> Brojevi pasoša ili <strong>JMBG</strong> zakupca i stanodavca.</span>
              </li>
              <li className="flex items-start gap-2.5">
                <CheckCircle2 className="w-4 h-4 text-brand-blue flex-shrink-0 mt-1" />
                <span><strong>Iznos i datum plaćanja kirije:</strong> Neki stanodavci dogovaraju plaćanje u evrima, drugi u dinarima. Zbog kursnih razlika, mora se precizirati u kojoj valuti i kog datuma u mesecu se kirija plaća.</span>
              </li>
              <li className="flex items-start gap-2.5">
                <CheckCircle2 className="w-4 h-4 text-brand-blue flex-shrink-0 mt-1" />
                <span><strong>Trajanje ugovora:</strong> Uslovi za ugovore na određeno (npr. 1 godina) ili neodređeno vreme moraju biti jasno napisani.</span>
              </li>
            </ul>
          </div>
        </section>

        {/* Section 2 */}
        <section className="space-y-4 pt-6 border-t border-gray-100" lang="sr">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-brand-green rounded-full"></span>
            2. Depozit i odgovornost za račune
          </h2>

          <p className="text-gray-700 leading-relaxed">
            Najčešći sporovi nastaju oko računa. U ugovoru mora biti precizirano ko plaća Infostan, struju (EPS) i internet.
          </p>

          <div className="p-5 rounded-2xl bg-green-50/60 border border-green-200/70 space-y-3">
            <h3 className="font-bold text-gray-900 text-sm flex items-center gap-2 text-green-900">
              <Sparkles className="w-4 h-4 text-brand-green" />
              Depozit i Inventarski Zapisnik:
            </h3>

            <p className="text-sm text-gray-700 leading-relaxed">
              Takođe, uslovi pod kojima se depozit (obično u visini jedne mesečne kirije) zadržava, kao i trenutno stanje inventara u stanu, moraju biti dodati ugovoru u vidu zapisnika.
            </p>
          </div>
        </section>

        {/* Section 3 */}
        <section className="space-y-4 pt-6 border-t border-gray-100" lang="sr">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-amber-500 rounded-full"></span>
            3. Otkazni rok i proces iseljenja
          </h2>

          <p className="text-gray-700 leading-relaxed">
            Ukoliko zakupac želi ranije da raskine ugovor ili kasni sa uplatama, standardni otkazni rok je obično <strong>30 dana</strong>. Pisano obaveštenje o ovom roku je zakonska obaveza.
          </p>
        </section>

        {/* Section 4 */}
        <section className="space-y-5 pt-6 border-t border-gray-100" lang="sr">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-brand-blue rounded-full"></span>
            4. Upravljajte procesima bez greške uz vašeg digitalnog asistenta
          </h2>

          <p className="text-gray-700 leading-relaxed">
            Pravi posao počinje nakon potpisivanja ugovora: praćenje mesečne kirije, provera plaćenih računa i podsećanje na datume obnove ugovora. Ako imate više nekretnina, vođenje evidencije u Excel-u ili na papiru povećava rizik od grešaka.
          </p>

          <div className="bg-gradient-to-r from-blue-50 via-white to-green-50 p-6 rounded-2xl border border-gray-200 space-y-4">
            <h3 className="font-bold text-gray-900 text-base flex items-center gap-2">
              <ShieldCheck className="w-5 h-5 text-brand-blue" />
              Profesionalizacija uz Stanomer:
            </h3>

            <p className="text-sm text-gray-700 leading-relaxed">
              Uz digitalnog asistenta kao što je <strong>Stanomer</strong>, možete potpuno profesionalizovati procese. Štaviše, Stanomer čuva sve vaše podatke isključivo na vašem uređaju (<strong>local storage</strong>) umesto na cloud serverima, osiguravajući da vaš portfolio ostane 100% privatan i bezbedan.
            </p>

            {/* CTA Box */}
            <div className="pt-4 text-center sm:text-left border-t border-gray-200/60">
              <div className="p-5 rounded-xl bg-brand-blue text-white space-y-3 shadow-lg">
                <p className="font-bold text-sm leading-snug">
                  📝 Digitalizujte evidenciju ugovora. Preuzmite Stanomer i vodite svoje nekretnine u Srbiji bez stresa.
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
