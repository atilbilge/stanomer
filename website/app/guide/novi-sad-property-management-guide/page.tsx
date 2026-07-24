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
  TrendingUp,
  BarChart3,
  Search,
  Lock
} from "lucide-react";

export const metadata: Metadata = {
  title: "Professionalize Property Management in Novi Sad: A Digital System for Landlords | Stanomer",
  description: "Operational guide for landlords in Novi Sad. Learn best practices for finding tenants, house listings, transparent rent tracking, invoice archiving, and Stanomer's local property management solution.",
  keywords: [
    "houses for rent in Novi Sad",
    "property management Novi Sad",
    "Novi Sad landlord guide",
    "rent tracking Novi Sad",
    "Petrovaradin rental real estate",
    "Liman Detelinara apartments",
    "izdavanje kuca Novi Sad",
    "stanomer app"
  ],
  alternates: {
    canonical: "https://www.stanomer.online/guide/novi-sad-property-management-guide",
    languages: {
      "en": "https://www.stanomer.online/guide/novi-sad-property-management-guide",
      "sr": "https://www.stanomer.online/guide/upravljanje-nekretninama-novi-sad",
      "sr-Cyrl": "https://www.stanomer.online/guide/upravljanje-nekretninama-novi-sad-cirilica",
      "ru": "https://www.stanomer.online/guide/novi-sad-property-management-guide-ru",
    }
  },
  openGraph: {
    title: "Professionalize Property Management in Novi Sad | Stanomer",
    description: "Digital system and operational guide for foreign investors and expat landlords managing properties in Novi Sad, Serbia.",
    url: "https://www.stanomer.online/guide/novi-sad-property-management-guide",
    siteName: "Stanomer",
    locale: "en_US",
    type: "article",
  }
};

const jsonLd = {
  "@context": "https://schema.org",
  "@type": "Article",
  "headline": "Professionalize Property Management in Novi Sad: A Digital System for Landlords",
  "description": "Essential operational guide for landlords and foreign investors managing rental properties in Novi Sad, Serbia.",
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
  "mainEntityOfPage": "https://www.stanomer.online/guide/novi-sad-property-management-guide",
  "inLanguage": "en"
};

export default function NoviSadEnglishGuidePage() {
  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
      />
      <GuideLayout
        currentLang="EN"
        categoryTitle="Novi Sad Property Guide"
        locationName="Novi Sad, Serbia"
        title="Professionalize Property Management in Novi Sad: A Digital System for Landlords"
        subtitle="Addressing three critical operational areas for landlords who have property investments in Novi Sad or want to manage their rentals professionally: finding the right tenant, keeping cash flow transparent, and breaking free from manual tracking."
        ctaText="Upgrade Your Novi Sad Property Management with Stanomer"
        ctaSubtext="Centralize rent tracking, utility invoice archiving, and portfolio cash flow with Stanomer's 100% on-device local storage architecture."
        canonicalUrl="https://www.stanomer.online/guide/novi-sad-property-management-guide"
      >
        {/* Intro */}
        <div className="space-y-4">
          <p className="text-gray-700 leading-relaxed">
            In recent years, <strong>Novi Sad</strong> has become one of Serbia&apos;s most attractive rental real estate markets for both local investors and foreign property owners. From areas near Petrovaradin to the city center, and from Liman to Detelinara, the demand for <strong>houses for rent in Novi Sad</strong> and apartments is steadily increasing.
          </p>
          <p className="text-gray-700 leading-relaxed">
            However, this potential comes with a growing operational burden: for landlords managing multiple properties, rent tracking, invoice archiving, and tenant communication quickly turn into complex tasks. Renting out a single apartment is a relatively simple process. But when your portfolio grows to two, three, or more properties, relying on your memory or scattered files to track which tenant paid this month&apos;s rent, whose name a utility bill is under, or when a lease is up for renewal is not a sustainable strategy.
          </p>
        </div>

        {/* Quick Summary Grid Box */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 my-8" lang="en">
          <div className="p-4 rounded-xl bg-blue-50/70 border border-blue-100 flex items-start gap-3">
            <Search className="w-5 h-5 text-brand-blue flex-shrink-0 mt-0.5" />
            <div>
              <h4 className="font-bold text-xs text-gray-900 tracking-wider mb-1">1. TENANT SELECTION</h4>
              <p className="text-xs text-gray-600">Listing quality, regional price data, and verifying history in Novi Sad.</p>
            </div>
          </div>

          <div className="p-4 rounded-xl bg-green-50/70 border border-green-100 flex items-start gap-3">
            <BarChart3 className="w-5 h-5 text-brand-green flex-shrink-0 mt-0.5" />
            <div>
              <h4 className="font-bold text-xs text-gray-900 tracking-wider mb-1">2. CASH FLOW</h4>
              <p className="text-xs text-gray-600">Clear due dates, utility responsibilities upfront, and payment logs.</p>
            </div>
          </div>

          <div className="p-4 rounded-xl bg-amber-50/70 border border-amber-100 flex items-start gap-3">
            <Lock className="w-5 h-5 text-amber-600 flex-shrink-0 mt-0.5" />
            <div>
              <h4 className="font-bold text-xs text-gray-900 tracking-wider mb-1">3. DIGITAL SYSTEM</h4>
              <p className="text-xs text-gray-600">Replacing Excel with Stanomer&apos;s private, on-device local storage.</p>
            </div>
          </div>
        </div>

        {/* Section 1 */}
        <section className="space-y-4 pt-4 border-t border-gray-100" lang="en">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-brand-blue rounded-full"></span>
            Finding the Right Tenant and Listing Your Property
          </h2>

          <p className="text-gray-700 leading-relaxed">
            The rental property market in Novi Sad has different dynamics depending on the target audience. While apartments near university districts cater to student demand, audiences searching for detached <strong>houses for rent in Novi Sad</strong> are usually families, long-term tenants, or remote-working professionals. These two segments arrive with different expectations: students focus on price and transit access, whereas those looking for a detached house usually mean longer lease terms, guaranteed steady income, and lower tenant turnover.
          </p>

          <div className="bg-gray-50/80 p-5 rounded-2xl border border-gray-200/80 space-y-3">
            <h3 className="font-bold text-gray-900 text-sm tracking-wide flex items-center gap-2">
              <Sparkles className="w-4 h-4 text-brand-blue" />
              KEY POINTS TO CONSIDER FOR FINDING THE RIGHT TENANT:
            </h3>

            <ul className="space-y-2 text-sm text-gray-700">
              <li className="flex items-start gap-2.5">
                <CheckCircle2 className="w-4 h-4 text-brand-blue flex-shrink-0 mt-1" />
                <span><strong>Listing quality is decisive:</strong> High-resolution photos, clear square footage, and heating/insulation details directly impact inquiry rates, especially in winter.</span>
              </li>
              <li className="flex items-start gap-2.5">
                <CheckCircle2 className="w-4 h-4 text-brand-blue flex-shrink-0 mt-1" />
                <span><strong>Back your pricing with regional data:</strong> Monitoring the rent range for similar properties in the same neighborhood (Liman, Detelinara, Petrovaradin) shortens vacancy periods and prevents income loss.</span>
              </li>
              <li className="flex items-start gap-2.5">
                <CheckCircle2 className="w-4 h-4 text-brand-blue flex-shrink-0 mt-1" />
                <span><strong>Verify tenant history:</strong> Past rent payment consistency and references are among the strongest indicators for reducing the risk of late payments in the long run.</span>
              </li>
            </ul>
          </div>
        </section>

        {/* Section 2 */}
        <section className="space-y-4 pt-6 border-t border-gray-100">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-brand-green rounded-full"></span>
            Ensuring Transparent Communication and Steady Cash Flow
          </h2>

          <p className="text-gray-700 leading-relaxed">
            Renting out a property is the beginning of a cash flow—not a guarantee of it. The real challenge for landlords is ensuring this income remains predictable and steady. This depends heavily on the clarity of communication established with the tenant.
          </p>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="p-4 rounded-xl bg-white border border-gray-200 shadow-xs space-y-2">
              <h4 className="font-bold text-gray-900 text-sm flex items-center gap-2">
                <FileText className="w-4 h-4 text-brand-green" />
                Clear Due Dates
              </h4>
              <p className="text-xs text-gray-600 leading-relaxed">
                Even if the rent due date is stated in the contract, the rate of late payments increases significantly without reminders.
              </p>
            </div>

            <div className="p-4 rounded-xl bg-white border border-gray-200 shadow-xs space-y-2">
              <h4 className="font-bold text-gray-900 text-sm flex items-center gap-2">
                <Receipt className="w-4 h-4 text-brand-green" />
                Utility Responsibilities
              </h4>
              <p className="text-xs text-gray-600 leading-relaxed">
                Defining utility responsibilities upfront. Ambiguity over who pays for electricity, water, and internet is one of the most frequent causes of landlord-tenant disputes.
              </p>
            </div>

            <div className="p-4 rounded-xl bg-white border border-gray-200 shadow-xs space-y-2">
              <h4 className="font-bold text-gray-900 text-sm flex items-center gap-2">
                <BarChart3 className="w-4 h-4 text-brand-green" />
                Payment Histories
              </h4>
              <p className="text-xs text-gray-600 leading-relaxed">
                Keeping payment histories recorded. A system that can instantly answer &quot;who paid what, and when&quot; builds direct trust for both parties.
              </p>
            </div>
          </div>
        </section>

        {/* Section 3 */}
        <section className="space-y-4 pt-6 border-t border-gray-100">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-amber-500 rounded-full"></span>
            Breaking Free from Excel: The True Cost of Manual Tracking
          </h2>

          <p className="text-gray-700 leading-relaxed">
            Most landlords start tracking rent with an Excel spreadsheet. This might seem sufficient for one property. But as the portfolio grows, rows multiply, formulas get complicated, and most importantly—the risk of human error increases.
          </p>

          <div className="p-5 rounded-2xl bg-amber-50/60 border border-amber-200/70 space-y-3">
            <h3 className="font-bold text-gray-900 text-sm flex items-center gap-2 text-amber-900">
              <AlertCircle className="w-4 h-4 text-amber-600" />
              The Physical Invoice & Scale Challenge:
            </h3>

            <p className="text-sm text-gray-700 leading-relaxed">
              Physical invoice archiving is another challenge. Utility bills usually arrive on different dates and in different formats (email, paper, SMS). From a data perspective, the problem is clear: <strong>manual tracking systems do not scale.</strong> When you go from one property to three, the operational burden doesn&apos;t just double; it multiplies.
            </p>
          </div>
        </section>

        {/* Section 4: Solution */}
        <section className="space-y-5 pt-6 border-t border-gray-100">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-brand-blue rounded-full"></span>
            The Solution: Stanomer — The Digital Property Management Assistant for Landlords
          </h2>

          <p className="text-gray-700 leading-relaxed">
            <strong>Stanomer</strong> is designed exactly to solve this scaling problem. It replaces Excel spreadsheets and scattered files with a centralized property management and rent tracking infrastructure.
          </p>

          <div className="bg-gradient-to-r from-blue-50 via-white to-green-50 p-6 rounded-2xl border border-gray-200 space-y-4">
            <h3 className="font-bold text-gray-900 text-base flex items-center gap-2">
              <ShieldCheck className="w-5 h-5 text-brand-blue" />
              Core Capabilities Stanomer Offers Landlords:
            </h3>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 text-sm">
              <div className="p-3 bg-white rounded-xl border border-gray-200/80">
                <h4 className="font-bold text-gray-900 mb-1">📊 Rent Payment Cycle Tracking</h4>
                <p className="text-xs text-gray-600">The payment status for each property—paid, pending, overdue—becomes visible on a single screen.</p>
              </div>

              <div className="p-3 bg-white rounded-xl border border-gray-200/80">
                <h4 className="font-bold text-gray-900 mb-1">📁 Invoice Archiving Automation</h4>
                <p className="text-xs text-gray-600">Utility bills are digitally archived, sorted by property, and accessible whenever you need them.</p>
              </div>

              <div className="p-3 bg-white rounded-xl border border-gray-200/80">
                <h4 className="font-bold text-gray-900 mb-1">💼 Income-Expense Workflows</h4>
                <p className="text-xs text-gray-600">Financial data from multiple properties is gathered under one structure, providing clear revenue visibility across your portfolio.</p>
              </div>

              <div className="p-3 bg-white rounded-xl border border-gray-200/80">
                <h4 className="font-bold text-gray-900 mb-1">🔒 Local Storage Principle</h4>
                <p className="text-xs text-gray-600">Your property and tenant data remain on your device; they are not sent to cloud servers or shared with third parties.</p>
              </div>
            </div>

            <p className="text-xs text-gray-600 pt-2 border-t border-gray-200/60 leading-relaxed">
              For investors with multiple properties in Novi Sad, this architecture provides critical assurance for the privacy of both financial data and tenant information.
            </p>

            {/* Direct High Converting CTA Button Box */}
            <div className="pt-4 text-center sm:text-left border-t border-gray-200/60">
              <div className="p-5 rounded-xl bg-brand-blue text-white space-y-3 shadow-lg">
                <p className="font-bold text-sm leading-snug">
                  📊 As your portfolio grows, your system needs to grow with it. Download Stanomer now and start managing your properties in Novi Sad from a single, professional infrastructure.
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
