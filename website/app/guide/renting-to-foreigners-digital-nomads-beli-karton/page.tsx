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
  title: "Renting to Foreigners and Digital Nomads in Belgrade and Novi Sad: A Guide | Stanomer",
  description: "Everything you need to know about the Beli Karton (White Card) process, communication, and tracking rent when leasing to expats in Serbia.",
  keywords: [
    "Beli Karton Serbia",
    "White Card registration Serbia",
    "renting to foreigners Belgrade",
    "digital nomads Novi Sad",
    "MUP eUprava address registration",
    "expat landlord guide Serbia",
    "stanomer property management"
  ],
  alternates: {
    canonical: "https://www.stanomer.online/guide/renting-to-foreigners-digital-nomads-beli-karton",
    languages: {
      "tr": "https://www.stanomer.online/guide/dijital-gocmenlere-ev-kiralama-beli-karton",
      "en": "https://www.stanomer.online/guide/renting-to-foreigners-digital-nomads-beli-karton",
      "sr": "https://www.stanomer.online/guide/izdavanje-stana-strancima-beli-karton",
      "sr-Cyrl": "https://www.stanomer.online/guide/izdavanje-stana-strancima-beli-karton-cirilica",
      "ru": "https://www.stanomer.online/guide/renting-to-foreigners-digital-nomads-beli-karton-ru",
    }
  },
  openGraph: {
    title: "Renting to Foreigners and Digital Nomads in Belgrade and Novi Sad: A Guide | Stanomer",
    description: "Everything you need to know about the Beli Karton (White Card) process, communication, and tracking rent when leasing to expats in Serbia.",
    url: "https://www.stanomer.online/guide/renting-to-foreigners-digital-nomads-beli-karton",
    siteName: "Stanomer",
    locale: "en_US",
    type: "article",
  }
};

const jsonLd = {
  "@context": "https://schema.org",
  "@type": "Article",
  "headline": "Renting to Foreigners and Digital Nomads in Belgrade and Novi Sad: A Guide",
  "description": "Everything you need to know about the Beli Karton (White Card) process, communication, and tracking rent when leasing to expats in Serbia.",
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
  "mainEntityOfPage": "https://www.stanomer.online/guide/renting-to-foreigners-digital-nomads-beli-karton",
  "inLanguage": "en"
};

export default function BeliKartonEnglishGuidePage() {
  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
      />
      <GuideLayout
        currentLang="EN"
        categoryTitle="Expats & Beli Karton Guide"
        locationName="Serbia (Belgrade & Novi Sad)"
        title="Renting to Foreigners and Digital Nomads in Belgrade and Novi Sad: A Guide"
        subtitle="How to safely rent your property to foreigners and digital nomads in Belgrade and Novi Sad. Everything you need to know about Beli Karton, communication, and tracking rent."
        ctaText="Professionalize Your Workflow with International Tenants Using Stanomer"
        ctaSubtext="Track rent and utility payments with Stanomer's multilingual interface and 100% on-device local storage architecture."
        canonicalUrl="https://www.stanomer.online/guide/renting-to-foreigners-digital-nomads-beli-karton"
      >
        {/* Intro */}
        <div className="space-y-4" lang="en">
          <p className="text-gray-700 leading-relaxed">
            In recent years, Serbia has become one of Europe&apos;s top hubs for digital nomads and expats. The vibrancy of <strong>Belgrade</strong> and the laid-back nature of <strong>Novi Sad</strong> attract remote workers globally.
          </p>
          <p className="text-gray-700 leading-relaxed">
            While renting to foreigners often yields higher returns, it comes with administrative responsibilities that landlords must handle diligently.
          </p>
        </div>

        {/* Quick Highlights Box */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 my-8" lang="en">
          <div className="p-4 rounded-xl bg-blue-50/70 border border-blue-100 flex items-start gap-3">
            <FileCheck className="w-5 h-5 text-brand-blue flex-shrink-0 mt-0.5" />
            <div>
              <h4 className="font-bold text-xs text-gray-900 tracking-wider mb-1">1. BELI KARTON</h4>
              <p className="text-xs text-gray-600">Address registration at MUP or e-Uprava within 24 hours of arrival is mandatory.</p>
            </div>
          </div>

          <div className="p-4 rounded-xl bg-green-50/70 border border-green-100 flex items-start gap-3">
            <MessageSquare className="w-5 h-5 text-brand-green flex-shrink-0 mt-0.5" />
            <div>
              <h4 className="font-bold text-xs text-gray-900 tracking-wider mb-1">2. BILINGUAL AGREEMENT</h4>
              <p className="text-xs text-gray-600">Bilingual lease (Serbian & English) and a Welcome Guide elevate your image.</p>
            </div>
          </div>

          <div className="p-4 rounded-xl bg-amber-50/70 border border-amber-100 flex items-start gap-3">
            <BadgeDollarSign className="w-5 h-5 text-amber-600 flex-shrink-0 mt-0.5" />
            <div>
              <h4 className="font-bold text-xs text-gray-900 tracking-wider mb-1">3. CURRENCY & TRACKING</h4>
              <p className="text-xs text-gray-600">Automate Euro rent & Dinar bill tracking with Stanomer local storage.</p>
            </div>
          </div>
        </div>

        {/* Section 1 */}
        <section className="space-y-4 pt-4 border-t border-gray-100" lang="en">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-brand-blue rounded-full"></span>
            1. Don&apos;t Skip the &quot;Beli Karton&quot; (White Card) Process
          </h2>

          <p className="text-gray-700 leading-relaxed">
            The most crucial legal obligation when renting to a foreigner is the address registration, known in Serbia as <strong>Beli karton</strong>.
          </p>

          <div className="bg-gray-50/80 p-5 rounded-2xl border border-gray-200/80 space-y-3">
            <h3 className="font-bold text-gray-900 text-sm tracking-wide flex items-center gap-2">
              <Sparkles className="w-4 h-4 text-brand-blue" />
              LEGAL REQUIREMENT & TIMELINE:
            </h3>

            <p className="text-sm text-gray-700 leading-relaxed">
              Your foreign tenant must be registered at the local police station (<strong>MUP</strong>) or via the <strong>e-Uprava</strong> portal within <strong>24 hours</strong> of entering the country. As the landlord, your authorization is legally required to complete this process.
            </p>
          </div>
        </section>

        {/* Section 2 */}
        <section className="space-y-4 pt-6 border-t border-gray-100" lang="en">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-brand-green rounded-full"></span>
            2. Communication and Language Barrier
          </h2>

          <p className="text-gray-700 leading-relaxed">
            Communication with digital nomads is mostly conducted in English. It is critical that your lease agreement is <strong>bilingual (Serbian and English)</strong> to prevent misunderstandings.
          </p>

          <p className="text-gray-700 leading-relaxed">
            Providing a brief &quot;Welcome Guide&quot; in English with emergency contacts for plumbing or electricity will significantly elevate your professional image.
          </p>
        </section>

        {/* Section 3 */}
        <section className="space-y-4 pt-6 border-t border-gray-100" lang="en">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-amber-500 rounded-full"></span>
            3. Currency and Payment Tracking
          </h2>

          <p className="text-gray-700 leading-relaxed">
            Foreigners often pay rent in Euros, while local utility bills (electricity EPS, water, internet) arrive in Dinars. Tracking whether these local bills are paid on time can become complex without a structured tool.
          </p>
        </section>

        {/* Section 4 */}
        <section className="space-y-5 pt-6 border-t border-gray-100" lang="en">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-brand-blue rounded-full"></span>
            4. Professional Tracking for International Tenants
          </h2>

          <p className="text-gray-700 leading-relaxed">
            Expats highly value data privacy and transparency. Instead of exchanging photos of receipts via WhatsApp messages, using a dedicated digital system builds long-term trust.
          </p>

          <div className="bg-gradient-to-r from-blue-50 via-white to-green-50 p-6 rounded-2xl border border-gray-200 space-y-4">
            <h3 className="font-bold text-gray-900 text-base flex items-center gap-2">
              <ShieldCheck className="w-5 h-5 text-brand-blue" />
              Multilingual Management with Stanomer:
            </h3>

            <p className="text-sm text-gray-700 leading-relaxed">
              By managing your properties through the <strong>Stanomer</strong> app, you can track all payments and utility receipts on a single screen in English, Serbian, Turkish, or Russian. Thanks to its <strong>local storage</strong> architecture, all financial data stays securely on your phone, ensuring 100% privacy and delivering a premium tenant experience.
            </p>

            {/* CTA Box */}
            <div className="pt-4 text-center sm:text-left border-t border-gray-200/60">
              <div className="p-5 rounded-xl bg-brand-blue text-white space-y-3 shadow-lg">
                <p className="font-bold text-sm leading-snug">
                  🌐 Build a seamless experience for your international tenants. Download Stanomer now and manage your rentals effortlessly.
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
