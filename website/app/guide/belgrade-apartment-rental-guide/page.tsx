import type { Metadata } from "next";
import { GuideLayout } from "../../../components/GuideLayout";
import { 
  Building, 
  FileText, 
  Receipt, 
  ShieldCheck, 
  MapPin, 
  CheckCircle2, 
  AlertCircle, 
  Sparkles,
  Smartphone
} from "lucide-react";

export const metadata: Metadata = {
  title: "The Ultimate Guide to Renting an Apartment in Belgrade | Stanomer",
  description: "Complete Belgrade apartment rental guide for expats, digital nomads, and students. Learn about neighborhood rents, lease agreements (ugovor o zakupu), utility bill management (EPS, Infostan), and Stanomer.",
  keywords: [
    "Belgrade apartment rental guide",
    "rent apartment in belgrade",
    "belgrade rental market",
    "apartments for rent in belgrade",
    "izdavanje stanova beograd",
    "ugovor o zakupu",
    "serbia utility bills",
    "stanomer app"
  ],
  alternates: {
    canonical: "https://www.stanomer.online/guide/belgrade-apartment-rental-guide",
    languages: {
      "tr": "https://www.stanomer.online/guide/belgrad-kiralik-daire-rehberi",
      "en": "https://www.stanomer.online/guide/belgrade-apartment-rental-guide",
      "sr": "https://www.stanomer.online/guide/vodic-za-izdavanje-stanova-beograd",
      "sr-Cyrl": "https://www.stanomer.online/guide/vodic-za-izdavanje-stanova-beograd-cirilica",
    }
  },
  openGraph: {
    title: "The Ultimate Guide to Renting an Apartment in Belgrade | Stanomer",
    description: "From finding a flat in Vračar or Novi Beograd to managing EPS & Infostan utility bills in Serbia.",
    url: "https://www.stanomer.online/guide/belgrade-apartment-rental-guide",
    siteName: "Stanomer",
    locale: "en_US",
    type: "article",
  }
};

const jsonLd = {
  "@context": "https://schema.org",
  "@type": "Article",
  "headline": "The Ultimate Guide to Renting an Apartment in Belgrade: From Searching to Managing Utilities",
  "description": "Essential guide for expats, digital nomads, and students renting in Belgrade, Serbia.",
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
  "mainEntityOfPage": "https://www.stanomer.online/guide/belgrade-apartment-rental-guide",
  "inLanguage": "en"
};

export default function EnglishGuidePage() {
  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
      />
      <GuideLayout
        currentLang="EN"
        title="The Ultimate Guide to Renting an Apartment in Belgrade: From Searching to Managing Utilities"
        subtitle="Bringing together the three critical stages of renting in Belgrade—searching, contracting, and managing utilities—into one place for expats, digital nomads, and students."
        ctaText="Centralize Your Rent and Utility Tracking with Stanomer"
        ctaSubtext="Keep your rent records and utility bills in Serbia stored safely and privately on your device with Stanomer's local-first architecture."
        canonicalUrl="https://www.stanomer.online/guide/belgrade-apartment-rental-guide"
      >
        {/* Intro */}
        <div className="space-y-4">
          <p className="text-gray-700 leading-relaxed">
            If you are planning to move to Belgrade—whether for a university program, remote work, or to make the city your permanent home—the first question is always the same: <strong>where do I start?</strong>
          </p>
          <p className="text-gray-700 leading-relaxed">
            Finding the right place doesn&apos;t have to be overwhelming. However, wasting time on outdated listings, missing a critical clause in your lease, or not knowing when your first utility bill is due can make the process unnecessarily stressful. This guide brings together the three critical stages of renting in Belgrade—<strong>searching, contracting, and managing utilities</strong>—into one place for expats, digital nomads, and students.
          </p>
        </div>

        {/* Quick Summary Grid Box */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 my-8" lang="en">
          <div className="p-4 rounded-xl bg-blue-50/70 border border-blue-100 flex items-start gap-3">
            <Building className="w-5 h-5 text-brand-blue flex-shrink-0 mt-0.5" />
            <div>
              <h4 className="font-bold text-xs text-gray-900 tracking-wider mb-1">1. SEARCHING</h4>
              <p className="text-xs text-gray-600">Vračar, Novi Beograd, Zvezdara neighborhood guide and portals.</p>
            </div>
          </div>

          <div className="p-4 rounded-xl bg-green-50/70 border border-green-100 flex items-start gap-3">
            <FileText className="w-5 h-5 text-brand-green flex-shrink-0 mt-0.5" />
            <div>
              <h4 className="font-bold text-xs text-gray-900 tracking-wider mb-1">2. UGOVOR O ZAKUPU</h4>
              <p className="text-xs text-gray-600">Lease clauses, notary validation, utility responsibilities & deposit.</p>
            </div>
          </div>

          <div className="p-4 rounded-xl bg-amber-50/70 border border-amber-100 flex items-start gap-3">
            <Receipt className="w-5 h-5 text-amber-600 flex-shrink-0 mt-0.5" />
            <div>
              <h4 className="font-bold text-xs text-gray-900 tracking-wider mb-1">3. MANAGING BILLS</h4>
              <p className="text-xs text-gray-600">EPS electricity, Infostan city utilities, and internet payments.</p>
            </div>
          </div>
        </div>

        {/* Section 1 */}
        <section className="space-y-4 pt-4 border-t border-gray-100" lang="en">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-brand-blue rounded-full"></span>
            Tips for Finding the Right Rental Apartment in Belgrade
          </h2>

          <p className="text-gray-700 leading-relaxed">
            Belgrade’s rental market varies significantly by neighborhood. <strong>Vračar</strong> and <strong>Stari Grad</strong> stand out with their proximity to the city center and have higher rents accordingly. <strong>Novi Beograd</strong> is popular among remote workers and young professionals due to its modern housing stock and proximity to business hubs. For students, areas like <strong>Zvezdara</strong> and <strong>Voždovac</strong> offer a better balance of price and proximity to campuses.
          </p>

          <div className="bg-gray-50/80 p-5 rounded-2xl border border-gray-200/80 space-y-3">
            <h3 className="font-bold text-gray-900 text-sm tracking-wide flex items-center gap-2">
              <Sparkles className="w-4 h-4 text-brand-blue" />
              THINGS TO KEEP IN MIND DURING YOUR SEARCH:
            </h3>

            <ul className="space-y-2 text-sm text-gray-700">
              <li className="flex items-start gap-2.5">
                <CheckCircle2 className="w-4 h-4 text-brand-blue flex-shrink-0 mt-1" />
                <span><strong>Cross-check listing platforms:</strong> The same flat might be listed on multiple sites at different prices. Compare a few sources to get the most accurate information.</span>
              </li>
              <li className="flex items-start gap-2.5">
                <CheckCircle2 className="w-4 h-4 text-brand-blue flex-shrink-0 mt-1" />
                <span><strong>Language advantage:</strong> If you are searching for <i>apartments for rent in Belgrade</i>, most platforms offer English filters. However, knowing basic Serbian real estate terms gives you an edge in negotiations.</span>
              </li>
              <li className="flex items-start gap-2.5">
                <CheckCircle2 className="w-4 h-4 text-brand-blue flex-shrink-0 mt-1" />
                <span><strong>Deposit and commission:</strong> Clarify deposit and commission terms upfront. Usually, a 1-2 month rent deposit is required; ensure the conditions for its return are written down.</span>
              </li>
              <li className="flex items-start gap-2.5">
                <CheckCircle2 className="w-4 h-4 text-brand-blue flex-shrink-0 mt-1" />
                <span><strong>Search in Serbian for owner listings:</strong> If you search in Serbian, using the phrase <code className="bg-gray-200 px-1.5 py-0.5 rounded text-brand-blue font-semibold">izdavanje stanova Beograd</code> on local classifieds often unlocks a wider pool of direct-from-owner listings without agency fees.</span>
              </li>
            </ul>
          </div>
        </section>

        {/* Section 2 */}
        <section className="space-y-4 pt-6 border-t border-gray-100">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-brand-green rounded-full"></span>
            Legal Details to Watch Out For in Your Lease (Ugovor o Zakupu)
          </h2>

          <p className="text-gray-700 leading-relaxed">
            In Serbia, a lease agreement—locally known as <strong>ugovor o zakupu</strong>—is a legal document that protects both the landlord and the tenant. Before signing, check these clauses:
          </p>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="p-4 rounded-xl bg-white border border-gray-200 shadow-xs space-y-2">
              <h4 className="font-bold text-gray-900 text-sm flex items-center gap-2">
                <FileText className="w-4 h-4 text-brand-green" />
                Lease Term & Renewal
              </h4>
              <p className="text-xs text-gray-600 leading-relaxed">
                Clarify whether it is a fixed-term or open-ended contract, and the required notice period for early termination.
              </p>
            </div>

            <div className="p-4 rounded-xl bg-white border border-gray-200 shadow-xs space-y-2">
              <h4 className="font-bold text-gray-900 text-sm flex items-center gap-2">
                <FileText className="w-4 h-4 text-brand-green" />
                Utility Responsibilities
              </h4>
              <p className="text-xs text-gray-600 leading-relaxed">
                It must be explicitly stated whether electricity, water, heating, and internet are included in the rent. This is one of the most common points of confusion for expats.
              </p>
            </div>

            <div className="p-4 rounded-xl bg-white border border-gray-200 shadow-xs space-y-2">
              <h4 className="font-bold text-gray-900 text-sm flex items-center gap-2">
                <FileText className="w-4 h-4 text-brand-green" />
                Notary Approval
              </h4>
              <p className="text-xs text-gray-600 leading-relaxed">
                For long-term rentals, getting the contract notarized provides legal security for both parties in Serbia.
              </p>
            </div>

            <div className="p-4 rounded-xl bg-white border border-gray-200 shadow-xs space-y-2">
              <h4 className="font-bold text-gray-900 text-sm flex items-center gap-2">
                <FileText className="w-4 h-4 text-brand-green" />
                Inventory & Condition
              </h4>
              <p className="text-xs text-gray-600 leading-relaxed">
                Take photos of furniture and pre-existing damages upon moving in and attach them to the agreement to safeguard your deposit.
              </p>
            </div>
          </div>
        </section>

        {/* Section 3 */}
        <section className="space-y-4 pt-6 border-t border-gray-100">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-amber-500 rounded-full"></span>
            Managing Electricity, Water, and Internet Bills in Serbia
          </h2>

          <p className="text-gray-700 leading-relaxed">
            Once the contract is signed, the daily reality sets in: tracking and paying bills in a foreign country. Electricity (<strong>EPS</strong>), water/city services (<strong>Infostan</strong>), and internet bills usually arrive separately, each with a different due date. An added challenge for expats is that bills are entirely in Serbian.
          </p>

          <div className="p-5 rounded-2xl bg-amber-50/60 border border-amber-200/70 space-y-3">
            <h3 className="font-bold text-gray-900 text-sm flex items-center gap-2 text-amber-900">
              <AlertCircle className="w-4 h-4 text-amber-600" />
              Key points for utility bill tracking:
            </h3>

            <ul className="space-y-2 text-sm text-gray-700">
              <li className="flex items-start gap-2">
                <span className="w-1.5 h-1.5 rounded-full bg-amber-600 mt-2 flex-shrink-0" />
                <span>Find out if the bills are registered in the landlord&apos;s name or yours—this determines who is legally responsible for the payment.</span>
              </li>
              <li className="flex items-start gap-2">
                <span className="w-1.5 h-1.5 rounded-full bg-amber-600 mt-2 flex-shrink-0" />
                <span>Track exact due dates to prevent unexpected service cut-offs.</span>
              </li>
              <li className="flex items-start gap-2">
                <span className="w-1.5 h-1.5 rounded-full bg-amber-600 mt-2 flex-shrink-0" />
                <span>Many tenants and landlords try to track these shared expenses via scattered WhatsApp messages, emails, or paper notes, which inevitably leads to forgotten payments and repeated disputes.</span>
              </li>
            </ul>
          </div>
        </section>

        {/* Section 4: Solution */}
        <section className="space-y-5 pt-6 border-t border-gray-100">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-brand-blue rounded-full"></span>
            The Solution: Centralize Your Rent and Utility Tracking with Stanomer
          </h2>

          <p className="text-gray-700 leading-relaxed">
            The three main issues we mentioned—<strong>losing bills, forgetting rent due dates, and miscommunication with the landlord</strong>—all stem from a disorganized tracking system. Stanomer is designed exactly to fill this gap.
          </p>

          <div className="bg-gradient-to-r from-blue-50 via-white to-green-50 p-6 rounded-2xl border border-gray-200 space-y-4">
            <h3 className="font-bold text-gray-900 text-base flex items-center gap-2">
              <ShieldCheck className="w-5 h-5 text-brand-blue" />
              With Stanomer:
            </h3>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 text-sm">
              <div className="p-3 bg-white rounded-xl border border-gray-200/80">
                <h4 className="font-bold text-gray-900 mb-1">✅ Real-Time Rent Logging</h4>
                <p className="text-xs text-gray-600">You log every rent payment the moment it happens. See what is paid, pending, or overdue on a single dashboard.</p>
              </div>

              <div className="p-3 bg-white rounded-xl border border-gray-200/80">
                <h4 className="font-bold text-gray-900 mb-1">📁 Digital Bill Archive</h4>
                <p className="text-xs text-gray-600">Archive your electricity, water, and internet bills in one digital space. No more searching through message threads.</p>
              </div>

              <div className="p-3 bg-white rounded-xl border border-gray-200/80">
                <h4 className="font-bold text-gray-900 mb-1">📜 Proof of Payment</h4>
                <p className="text-xs text-gray-600">Keep a clear digital history of payments shared with your landlord—eliminating disputes instantly.</p>
              </div>

              <div className="p-3 bg-white rounded-xl border border-gray-200/80">
                <h4 className="font-bold text-gray-900 mb-1">🔒 Local Storage Privacy</h4>
                <p className="text-xs text-gray-600">Stanomer keeps your data on your device using local storage. Financial records are not sent to any cloud server.</p>
              </div>
            </div>

            {/* Direct High Converting CTA Button Box */}
            <div className="pt-4 text-center sm:text-left border-t border-gray-200/60">
              <div className="p-5 rounded-xl bg-brand-blue text-white space-y-3 shadow-lg">
                <p className="font-bold text-sm leading-snug">
                  📲 If you are moving to a new home in Belgrade, stay organized from day one. Download Stanomer from the App Store or Google Play now and digitize your rental experience.
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
