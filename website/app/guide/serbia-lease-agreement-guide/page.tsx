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
  title: "Lease Agreements in Serbia: Critical Points Every Landlord Must Know | Stanomer",
  description: "How to legally protect yourself when renting out an apartment in Serbia? A comprehensive guide on lease clauses, deposit rights, Infostan/EPS utility responsibilities, and Stanomer digital management.",
  keywords: [
    "lease agreement Serbia",
    "ugovor o zakupu stana",
    "Belgrade rental contract",
    "Novi Sad apartment lease",
    "Serbian landlord tenant law",
    "EPS Infostan bills Serbia",
    "notice period otkazni rok",
    "stanomer property management"
  ],
  alternates: {
    canonical: "https://www.stanomer.online/guide/serbia-lease-agreement-guide",
    languages: {
      "tr": "https://www.stanomer.online/guide/sirbistan-kira-sozlesmesi-rehberi",
      "en": "https://www.stanomer.online/guide/serbia-lease-agreement-guide",
      "sr": "https://www.stanomer.online/guide/ugovor-o-zakupu-stana-srbija",
      "sr-Cyrl": "https://www.stanomer.online/guide/ugovor-o-zakupu-stana-srbija-cirilica",
      "ru": "https://www.stanomer.online/guide/serbia-lease-agreement-guide-ru",
    }
  },
  openGraph: {
    title: "Lease Agreements in Serbia: Critical Points Every Landlord Must Know | Stanomer",
    description: "How to legally protect yourself when renting out an apartment in Serbia. A complete guide on rental contracts.",
    url: "https://www.stanomer.online/guide/serbia-lease-agreement-guide",
    siteName: "Stanomer",
    locale: "en_US",
    type: "article",
  }
};

const jsonLd = {
  "@context": "https://schema.org",
  "@type": "Article",
  "headline": "Lease Agreements in Serbia: Critical Points Every Landlord Must Know",
  "description": "How to legally protect yourself when renting out an apartment in Serbia? A comprehensive guide on lease clauses, deposit rights, and property management.",
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
  "mainEntityOfPage": "https://www.stanomer.online/guide/serbia-lease-agreement-guide",
  "inLanguage": "en"
};

export default function LeaseAgreementEnglishGuidePage() {
  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
      />
      <GuideLayout
        currentLang="EN"
        categoryTitle="Legal & Contract Guide"
        locationName="Serbia Nationwide"
        title="Lease Agreements in Serbia: Critical Points Every Landlord Must Know"
        subtitle="How to legally protect yourself when renting out an apartment in Serbia? A comprehensive guide on lease clauses, deposit rights, utility responsibilities, and digital process management."
        ctaText="Manage Your Serbian Lease Agreements & Property Workflows with Stanomer"
        ctaSubtext="Track rent payments, utility bills, and lease renewal dates with Stanomer's 100% on-device local storage architecture."
        canonicalUrl="https://www.stanomer.online/guide/serbia-lease-agreement-guide"
      >
        {/* Intro */}
        <div className="space-y-4" lang="en">
          <p className="text-gray-700 leading-relaxed">
            The real estate market in Serbia, particularly in <strong>Belgrade</strong> and <strong>Novi Sad</strong>, continues to grow rapidly. While this presents excellent opportunities for landlords, failing to establish a legal and organized framework can lead to significant operational headaches.
          </p>
          <p className="text-gray-700 leading-relaxed">
            The first step to successful property management is a solid lease agreement (known in Serbian as <strong>ugovor o zakupu stana</strong>) that protects both parties.
          </p>
        </div>

        {/* Quick Highlights Box */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 my-8" lang="en">
          <div className="p-4 rounded-xl bg-blue-50/70 border border-blue-100 flex items-start gap-3">
            <Scale className="w-5 h-5 text-brand-blue flex-shrink-0 mt-0.5" />
            <div>
              <h4 className="font-bold text-xs text-gray-900 tracking-wider mb-1">1. MANDATORY CLAUSES</h4>
              <p className="text-xs text-gray-600">Passport / JMBG ID numbers, rent currency, and lease duration terms.</p>
            </div>
          </div>

          <div className="p-4 rounded-xl bg-green-50/70 border border-green-100 flex items-start gap-3">
            <Receipt className="w-5 h-5 text-brand-green flex-shrink-0 mt-0.5" />
            <div>
              <h4 className="font-bold text-xs text-gray-900 tracking-wider mb-1">2. UTILITIES & DEPOSIT</h4>
              <p className="text-xs text-gray-600">Infostan, EPS & Internet responsibilities plus inventory handover checklist.</p>
            </div>
          </div>

          <div className="p-4 rounded-xl bg-amber-50/70 border border-amber-100 flex items-start gap-3">
            <Clock className="w-5 h-5 text-amber-600 flex-shrink-0 mt-0.5" />
            <div>
              <h4 className="font-bold text-xs text-gray-900 tracking-wider mb-1">3. NOTICE & DIGITAL ASSISTANT</h4>
              <p className="text-xs text-gray-600">Standard 30-day notice (otkazni rok) and local storage tracking with Stanomer.</p>
            </div>
          </div>
        </div>

        {/* Section 1 */}
        <section className="space-y-4 pt-4 border-t border-gray-100" lang="en">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-brand-blue rounded-full"></span>
            1. Mandatory Clauses in a Lease Agreement
          </h2>

          <p className="text-gray-700 leading-relaxed">
            The clearer the contract, the lower the risk of future disputes. According to Serbian law and standard real estate practice, a valid agreement must clearly state:
          </p>

          <div className="bg-gray-50/80 p-5 rounded-2xl border border-gray-200/80 space-y-3">
            <ul className="space-y-3 text-sm text-gray-700">
              <li className="flex items-start gap-2.5">
                <CheckCircle2 className="w-4 h-4 text-brand-blue flex-shrink-0 mt-1" />
                <span><strong>Identification Details:</strong> Passport numbers or JMBG (Personal ID Number) of both the tenant and landlord must be explicitly included.</span>
              </li>
              <li className="flex items-start gap-2.5">
                <CheckCircle2 className="w-4 h-4 text-brand-blue flex-shrink-0 mt-1" />
                <span><strong>Rent Amount and Payment Date:</strong> Some agree on Euros, others on Dinars. Due to exchange rates, the exact currency and the day of the month rent is due must be specified.</span>
              </li>
              <li className="flex items-start gap-2.5">
                <CheckCircle2 className="w-4 h-4 text-brand-blue flex-shrink-0 mt-1" />
                <span><strong>Lease Duration:</strong> Terms for fixed-term (e.g., 1 year) or indefinite agreements must be clearly outlined.</span>
              </li>
            </ul>
          </div>
        </section>

        {/* Section 2 */}
        <section className="space-y-4 pt-6 border-t border-gray-100" lang="en">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-brand-green rounded-full"></span>
            2. Deposit and Utility Responsibilities
          </h2>

          <p className="text-gray-700 leading-relaxed">
            Disputes most frequently arise over bills and deposit returns.
          </p>

          <div className="p-5 rounded-2xl bg-green-50/60 border border-green-200/70 space-y-3">
            <h3 className="font-bold text-gray-900 text-sm flex items-center gap-2 text-green-900">
              <Sparkles className="w-4 h-4 text-brand-green" />
              Essential Contractual Inclusions:
            </h3>

            <p className="text-sm text-gray-700 leading-relaxed">
              The contract must specify who pays for <strong>Infostan</strong> (heating and communal building services), electricity (<strong>EPS</strong>), and internet. The conditions under which the deposit (usually equal to one month&apos;s rent) can be withheld, along with an inventory checklist of items in the apartment, must be attached.
            </p>
          </div>
        </section>

        {/* Section 3 */}
        <section className="space-y-4 pt-6 border-t border-gray-100" lang="en">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-amber-500 rounded-full"></span>
            3. Termination and Eviction Processes (Otkazni Rok)
          </h2>

          <p className="text-gray-700 leading-relaxed">
            If the tenant wishes to terminate the contract early or defaults on payments, the standard notice period (known in Serbian as <strong>otkazni rok</strong>) is usually <strong>30 days</strong>. Providing this notice in written form is a legal requirement.
          </p>
        </section>

        {/* Section 4 */}
        <section className="space-y-5 pt-6 border-t border-gray-100" lang="en">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-brand-blue rounded-full"></span>
            4. Manage Processes Flawlessly with Your Digital Assistant
          </h2>

          <p className="text-gray-700 leading-relaxed">
            The real work begins after signing: tracking monthly rent, checking utility payments, and remembering renewal dates. If you own multiple properties, relying on Excel or paper notes increases the risk of errors.
          </p>

          <div className="bg-gradient-to-r from-blue-50 via-white to-green-50 p-6 rounded-2xl border border-gray-200 space-y-4">
            <h3 className="font-bold text-gray-900 text-base flex items-center gap-2">
              <ShieldCheck className="w-5 h-5 text-brand-blue" />
              Professionalize with Stanomer:
            </h3>

            <p className="text-sm text-gray-700 leading-relaxed">
              By using a digital assistant like <strong>Stanomer</strong>, you can professionalize these processes. Moreover, Stanomer keeps all your data directly on your device (<strong>local storage</strong>) rather than on cloud servers, ensuring your portfolio remains 100% private and secure.
            </p>

            {/* CTA Box */}
            <div className="pt-4 text-center sm:text-left border-t border-gray-200/60">
              <div className="p-5 rounded-xl bg-brand-blue text-white space-y-3 shadow-lg">
                <p className="font-bold text-sm leading-snug">
                  📝 Digitization keeps your properties organized. Download Stanomer now and streamline your lease tracking in Serbia effortlessly.
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
