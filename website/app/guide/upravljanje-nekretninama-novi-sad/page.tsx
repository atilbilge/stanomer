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
  title: "Profesionalizujte upravljanje nekretninama u Novom Sadu: Digitalni sistem za stanodavce | Stanomer",
  description: "Praktični vodič za stanodavce u Novom Sadu. Kako pronaći pravog stanara, pratiti kirije, automatizovati arhiviranje računa i digitalizovati portfolio uz Stanomer.",
  keywords: [
    "izdavanje kuca Novi Sad",
    "izdavanje stanova Novi Sad",
    "upravljanje nekretninama Novi Sad",
    "vodič za stanodavce",
    "praćenje kirije",
    "arhiviranje računa",
    "Petrovaradin Liman Detelinara nekretnine",
    "stanomer aplikacija"
  ],
  alternates: {
    canonical: "https://www.stanomer.online/guide/upravljanje-nekretninama-novi-sad",
    languages: {
      "en": "https://www.stanomer.online/guide/novi-sad-property-management-guide",
      "sr": "https://www.stanomer.online/guide/upravljanje-nekretninama-novi-sad",
      "sr-Cyrl": "https://www.stanomer.online/guide/upravljanje-nekretninama-novi-sad-cirilica",
      "ru": "https://www.stanomer.online/guide/novi-sad-property-management-guide-ru",
    }
  },
  openGraph: {
    title: "Profesionalizujte upravljanje nekretninama u Novom Sadu | Stanomer",
    description: "Vodič i digitalni sistem za lokalne stanodavce i investitore u Novom Sadu.",
    url: "https://www.stanomer.online/guide/upravljanje-nekretninama-novi-sad",
    siteName: "Stanomer",
    locale: "sr_RS",
    type: "article",
  }
};

const jsonLd = {
  "@context": "https://schema.org",
  "@type": "Article",
  "headline": "Profesionalizujte upravljanje nekretninama u Novom Sadu: Digitalni sistem za stanodavce",
  "description": "Vodič za stanodavce u Novom Sadu: pronalazak stanara, transparentan priliv novca i digitalizacija računa.",
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
  "mainEntityOfPage": "https://www.stanomer.online/guide/upravljanje-nekretninama-novi-sad",
  "inLanguage": "sr"
};

export default function NoviSadSerbianLatinGuidePage() {
  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
      />
      <GuideLayout
        currentLang="SR_LAT"
        categoryTitle="Vodič za Novi Sad"
        locationName="Novi Sad, Srbija"
        title="Profesionalizujte upravljanje nekretninama u Novom Sadu: Digitalni sistem za stanodavce"
        subtitle="Ovaj vodič se bavi sa tri ključna operativna polja za stanodavce u Novom Sadu: pronalazak pravog stanara, održavanje transparentnog priliva novca i oslobađanje od ručnih sistema praćenja."
        ctaText="Profesionalizujte upravljanje nekretninama uz Stanomer"
        ctaSubtext="Praćenje kirija, automatizacija računa i organizacija prihoda uz 100% privatnost i lokalno skladištenje podataka na vašem uređaju."
        canonicalUrl="https://www.stanomer.online/guide/upravljanje-nekretninama-novi-sad"
      >
        {/* Intro */}
        <div className="space-y-4">
          <p className="text-gray-700 leading-relaxed">
            Novi Sad je poslednjih godina postao jedno od najatraktivnijih tržišta za izdavanje nekretnina u Srbiji, kako za lokalne investitore, tako i za strane vlasnike. Od Petrovaradina do centra grada, i od Limana do Detelinare, potražnja stabilno raste.
          </p>
          <p className="text-gray-700 leading-relaxed">
            Međutim, ovaj potencijal donosi i rastući operativni teret: za stanodavce koji upravljaju sa više nekretnina, praćenje kirija, arhiviranje računa i komunikacija sa stanarima brzo postaju komplikovan posao. Izdavanje jednog stana je relativno jednostavan proces. Ali kada vaš portfolio poraste na dve, tri ili više nekretnina, oslanjanje na pamćenje ili razbacane fajlove o tome ko je platio kiriju, na čije ime glasi račun ili kada ističe ugovor, nije održiva strategija. Ovaj vodič se bavi sa tri ključna operativna polja za stanodavce u Novom Sadu.
          </p>
        </div>

        {/* Quick Summary Grid Box */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 my-8" lang="sr">
          <div className="p-4 rounded-xl bg-blue-50/70 border border-blue-100 flex items-start gap-3">
            <Search className="w-5 h-5 text-brand-blue flex-shrink-0 mt-0.5" />
            <div>
              <h4 className="font-bold text-xs text-gray-900 tracking-wider mb-1">1. PRONALAZAK STANARA</h4>
              <p className="text-xs text-gray-600">Kvalitet oglasa, praćenje cena u kraju i provera istorije stanara.</p>
            </div>
          </div>

          <div className="p-4 rounded-xl bg-green-50/70 border border-green-100 flex items-start gap-3">
            <BarChart3 className="w-5 h-5 text-brand-green flex-shrink-0 mt-0.5" />
            <div>
              <h4 className="font-bold text-xs text-gray-900 tracking-wider mb-1">2. STABILAN PRIHOD</h4>
              <p className="text-xs text-gray-600">Jasni datumi plaćanja, odgovornost za račune i evidencija istorije.</p>
            </div>
          </div>

          <div className="p-4 rounded-xl bg-amber-50/70 border border-amber-100 flex items-start gap-3">
            <Lock className="w-5 h-5 text-amber-600 flex-shrink-0 mt-0.5" />
            <div>
              <h4 className="font-bold text-xs text-gray-900 tracking-wider mb-1">3. DIGITALNI SISTEM</h4>
              <p className="text-xs text-gray-600">Zamena Excel tabela Stanomer lokalnim skladištenjem (local storage).</p>
            </div>
          </div>
        </div>

        {/* Section 1 */}
        <section className="space-y-4 pt-4 border-t border-gray-100" lang="sr">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-brand-blue rounded-full"></span>
            Pronalazak pravog stanara i oglašavanje nekretnine
          </h2>

          <p className="text-gray-700 leading-relaxed">
            Tržište nekretnina u Novom Sadu ima različitu dinamiku u zavisnosti od ciljne grupe. Dok stanovi blizu univerziteta odgovaraju studentima, oni koji pretražuju <strong>izdavanje kuća Novi Sad</strong> su obično porodice ili profesionalci koji rade na daljinu.
          </p>

          <div className="bg-gray-50/80 p-5 rounded-2xl border border-gray-200/80 space-y-3">
            <h3 className="font-bold text-gray-900 text-sm tracking-wide flex items-center gap-2">
              <Sparkles className="w-4 h-4 text-brand-blue" />
              KLJUČNE TAČKE ZA PRONALAZAK PRAVOG STANARA:
            </h3>

            <ul className="space-y-2 text-sm text-gray-700">
              <li className="flex items-start gap-2.5">
                <CheckCircle2 className="w-4 h-4 text-brand-blue flex-shrink-0 mt-1" />
                <span><strong>Kvalitet oglasa je presudan:</strong> Fotografije visoke rezolucije i detalji o grejanju direktno utiču na broj upita.</span>
              </li>
              <li className="flex items-start gap-2.5">
                <CheckCircle2 className="w-4 h-4 text-brand-blue flex-shrink-0 mt-1" />
                <span><strong>Pratite cene u vašem kraju:</strong> Usklađivanje sa cenama sličnih nekretnina smanjuje vreme praznog hoda.</span>
              </li>
              <li className="flex items-start gap-2.5">
                <CheckCircle2 className="w-4 h-4 text-brand-blue flex-shrink-0 mt-1" />
                <span><strong>Proverite istoriju stanara:</strong> Redovnost u prethodnim plaćanjima je najjači indikator za smanjenje rizika od kašnjenja.</span>
              </li>
            </ul>
          </div>
        </section>

        {/* Section 2 */}
        <section className="space-y-4 pt-6 border-t border-gray-100">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-brand-green rounded-full"></span>
            Transparentna komunikacija i stabilan prihod
          </h2>

          <p className="text-gray-700 leading-relaxed">
            Izdavanje nekretnine je početak priliva novca — ne i njegova garancija. Tri elementa su ključna za održavanje stabilnog i predvidivog prihoda:
          </p>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="p-4 rounded-xl bg-white border border-gray-200 shadow-xs space-y-2">
              <h4 className="font-bold text-gray-900 text-sm flex items-center gap-2">
                <FileText className="w-4 h-4 text-brand-green" />
                Jasni datumi plaćanja
              </h4>
              <p className="text-xs text-gray-600 leading-relaxed">
                Precizno definisani rokovi za kiriju i račune smanjuju procenat kašnjenja.
              </p>
            </div>

            <div className="p-4 rounded-xl bg-white border border-gray-200 shadow-xs space-y-2">
              <h4 className="font-bold text-gray-900 text-sm flex items-center gap-2">
                <Receipt className="w-4 h-4 text-brand-green" />
                Odgovornosti za račune
              </h4>
              <p className="text-xs text-gray-600 leading-relaxed">
                Preciziranje odgovornosti za struju, vodu i internet sprečava nesporazume.
              </p>
            </div>

            <div className="p-4 rounded-xl bg-white border border-gray-200 shadow-xs space-y-2">
              <h4 className="font-bold text-gray-900 text-sm flex items-center gap-2">
                <BarChart3 className="w-4 h-4 text-brand-green" />
                Evidencija istorije
              </h4>
              <p className="text-xs text-gray-600 leading-relaxed">
                Uredna evidencija plaćanja gradi direktno poverenje između stanodavca i stanara.
              </p>
            </div>
          </div>
        </section>

        {/* Section 3 */}
        <section className="space-y-4 pt-6 border-t border-gray-100">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-amber-500 rounded-full"></span>
            Oslobađanje od Excel tabela: Prava cena ručnog praćenja
          </h2>

          <p className="text-gray-700 leading-relaxed">
            Većina stanodavaca počinje sa Excel tabelom. Za jednu nekretninu to može biti dovoljno, ali kako portfolio raste, rizik od ljudske greške se povećava.
          </p>

          <div className="p-5 rounded-2xl bg-amber-50/60 border border-amber-200/70 space-y-3">
            <h3 className="font-bold text-gray-900 text-sm flex items-center gap-2 text-amber-900">
              <AlertCircle className="w-4 h-4 text-amber-600" />
              Izazov arhiviranja računa:
            </h3>

            <p className="text-sm text-gray-700 leading-relaxed">
              Fizičko arhiviranje računa za struju, vodu i internet, koji stižu u različitim formatima (email, papir, SMS), vremenom postaje neodrživo. Ručni sistemi jednostavno nisu skalabilni.
            </p>
          </div>
        </section>

        {/* Section 4: Solution */}
        <section className="space-y-5 pt-6 border-t border-gray-100">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-brand-blue rounded-full"></span>
            Rešenje: Stanomer — Digitalni asistent za upravljanje nekretninama
          </h2>

          <p className="text-gray-700 leading-relaxed">
            <strong>Stanomer</strong> je dizajniran da reši ovaj problem skaliranja i zameni razbacane fajlove centralizovanom infrastrukturom.
          </p>

          <div className="bg-gradient-to-r from-blue-50 via-white to-green-50 p-6 rounded-2xl border border-gray-200 space-y-4">
            <h3 className="font-bold text-gray-900 text-base flex items-center gap-2">
              <ShieldCheck className="w-5 h-5 text-brand-blue" />
              Ključne funkcije za stanodavce:
            </h3>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 text-sm">
              <div className="p-3 bg-white rounded-xl border border-gray-200/80">
                <h4 className="font-bold text-gray-900 mb-1">📊 Praćenje ciklusa plaćanja</h4>
                <p className="text-xs text-gray-600">Status plaćanja za svaku nekretninu vidljiv je na jednom ekranu.</p>
              </div>

              <div className="p-3 bg-white rounded-xl border border-gray-200/80">
                <h4 className="font-bold text-gray-900 mb-1">📁 Automatizacija računa</h4>
                <p className="text-xs text-gray-600">Računi se digitalno arhiviraju i sortiraju po nekretnini.</p>
              </div>

              <div className="p-3 bg-white rounded-xl border border-gray-200/80">
                <h4 className="font-bold text-gray-900 mb-1">💼 Organizacija prihoda i rashoda</h4>
                <p className="text-xs text-gray-600">Jasna slika finansija i prihoda celog portfolija na jednom mestu.</p>
              </div>

              <div className="p-3 bg-white rounded-xl border border-gray-200/80">
                <h4 className="font-bold text-gray-900 mb-1">🔒 Privatnost i local storage</h4>
                <p className="text-xs text-gray-600">Podaci o vašim nekretninama ostaju na vašem uređaju; ne šalju se na cloud servere i ne dele sa trećim licima.</p>
              </div>
            </div>

            <p className="text-xs text-gray-600 pt-2 border-t border-gray-200/60 leading-relaxed">
              Ovo je ključna garancija privatnosti za investitore sa više nekretnina u Novom Sadu.
            </p>

            {/* Direct High Converting CTA Button Box */}
            <div className="pt-4 text-center sm:text-left border-t border-gray-200/60">
              <div className="p-5 rounded-xl bg-brand-blue text-white space-y-3 shadow-lg">
                <p className="font-bold text-sm leading-snug">
                  📊 Kako vaš portfolio raste, mora rasti i vaš sistem. Preuzmite Stanomer i počnite da upravljate svojim nekretninama u Novom Sadu preko jedinstvene, profesionalne infrastrukture.
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
