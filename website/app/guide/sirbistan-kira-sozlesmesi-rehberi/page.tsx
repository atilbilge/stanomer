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
  title: "Sırbistan'da Kira Sözleşmesi (Ugovor o Zakupu): Ev Sahiplerinin Bilmesi Gereken 4 Kritik Madde | Stanomer",
  description: "Sırbistan'da ev kiralarken hukuki olarak kendinizi nasıl korursunuz? Ugovor o zakupu maddeleri, depozito hakları, EPS/Infostan fatura sorumlulukları ve Stanomer ile dijital takip rehberi.",
  keywords: [
    "Sırbistan kira sözleşmesi",
    "Ugovor o zakupu stana",
    "Belgrad ev kiralama sözleşmesi",
    "Novi Sad kira sözleşmesi",
    "Sırbistan kiracı ev sahibi hakları",
    "EPS Infostan fatura devri",
    "otkazni rok otkaz süresi",
    "stanomer mülk yönetimi"
  ],
  alternates: {
    canonical: "https://www.stanomer.online/guide/sirbistan-kira-sozlesmesi-rehberi",
    languages: {
      "tr": "https://www.stanomer.online/guide/sirbistan-kira-sozlesmesi-rehberi",
      "en": "https://www.stanomer.online/guide/serbia-lease-agreement-guide",
      "sr": "https://www.stanomer.online/guide/ugovor-o-zakupu-stana-srbija",
      "sr-Cyrl": "https://www.stanomer.online/guide/ugovor-o-zakupu-stana-srbija-cirilica",
      "ru": "https://www.stanomer.online/guide/serbia-lease-agreement-guide-ru",
    }
  },
  openGraph: {
    title: "Sırbistan'da Kira Sözleşmesi: Ev Sahiplerinin Bilmesi Gereken 4 Kritik Madde | Stanomer",
    description: "Sırbistan'da ev kiralarken hukuki olarak kendinizi koruyun. Ugovor o zakupu rehberi.",
    url: "https://www.stanomer.online/guide/sirbistan-kira-sozlesmesi-rehberi",
    siteName: "Stanomer",
    locale: "tr_TR",
    type: "article",
  }
};

const jsonLd = {
  "@context": "https://schema.org",
  "@type": "Article",
  "headline": "Sırbistan'da Kira Sözleşmesi (Ugovor o Zakupu): Ev Sahiplerinin Bilmesi Gereken 4 Kritik Madde",
  "description": "Sırbistan'da ev kiralarken hukuki olarak kendinizi nasıl korursunuz? Sözleşme maddeleri, depozito ve süreç yönetimi.",
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
  "mainEntityOfPage": "https://www.stanomer.online/guide/sirbistan-kira-sozlesmesi-rehberi",
  "inLanguage": "tr"
};

export default function LeaseAgreementTurkishGuidePage() {
  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
      />
      <GuideLayout
        currentLang="TR"
        categoryTitle="Hukuki & Kontrat Rehberi"
        locationName="Sırbistan Genel"
        title="Sırbistan'da Kira Sözleşmesi (Ugovor o Zakupu): Ev Sahiplerinin Bilmesi Gereken 4 Kritik Madde"
        subtitle="Sırbistan'da ev kiralarken hukuki olarak kendinizi nasıl korursunuz? Sözleşme zorunlu maddeleri, depozito hakları, fatura sorumlulukları ve dijital süreç yönetimi rehberi."
        ctaText="Sırbistan'daki Kira Sözleşmelerinizi ve Süreçlerinizi Stanomer ile Yönetin"
        ctaSubtext="Kira ödemelerini, faturaları ve kontrat yenileme tarihlerini Stanomer'in %100 cihaz içi yerel depolama mimarisiyle güvenle takip edin."
        canonicalUrl="https://www.stanomer.online/guide/sirbistan-kira-sozlesmesi-rehberi"
      >
        {/* Intro */}
        <div className="space-y-4" lang="tr">
          <p className="text-gray-700 leading-relaxed">
            Sırbistan&apos;daki gayrimenkul pazarı, özellikle <strong>Belgrad</strong> ve <strong>Novi Sad</strong> başta olmak üzere hızla büyümeye devam ediyor. Bu büyüme ev sahipleri için harika gelir fırsatları sunsa da, doğru hukuki ve operasyonel çerçeve kurulmadığında ciddi operasyonel baş ağrılarına yol açabilir.
          </p>
          <p className="text-gray-700 leading-relaxed">
            Başarılı bir mülk yönetiminin ilk adımı, her iki tarafın da haklarını koruyan sağlam bir kira sözleşmesidir (Sırpça adıyla <strong>Ugovor o zakupu stana</strong>).
          </p>
        </div>

        {/* Quick Highlights Box */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 my-8" lang="tr">
          <div className="p-4 rounded-xl bg-blue-50/70 border border-blue-100 flex items-start gap-3">
            <Scale className="w-5 h-5 text-brand-blue flex-shrink-0 mt-0.5" />
            <div>
              <h4 className="font-bold text-xs text-gray-900 tracking-wider mb-1">1. ZORUNLU MADDELER</h4>
              <p className="text-xs text-gray-600">Pasaport / JMBG kimlik bilgileri, ödeme para birimi ve sözleşme süresi.</p>
            </div>
          </div>

          <div className="p-4 rounded-xl bg-green-50/70 border border-green-100 flex items-start gap-3">
            <Receipt className="w-5 h-5 text-brand-green flex-shrink-0 mt-0.5" />
            <div>
              <h4 className="font-bold text-xs text-gray-900 tracking-wider mb-1">2. FATURALAR & DEPOZİTO</h4>
              <p className="text-xs text-gray-600">Infostan, EPS ve İnternet sorumlulukları ile demirbaş zimmet tutanağı.</p>
            </div>
          </div>

          <div className="p-4 rounded-xl bg-amber-50/70 border border-amber-100 flex items-start gap-3">
            <Clock className="w-5 h-5 text-amber-600 flex-shrink-0 mt-0.5" />
            <div>
              <h4 className="font-bold text-xs text-gray-900 tracking-wider mb-1">3. CAYMA & DİJİTAL TAKİP</h4>
              <p className="text-xs text-gray-600">30 günlük yasal otkazni rok (ihbar süresi) ve Stanomer lokal takibi.</p>
            </div>
          </div>
        </div>

        {/* Section 1 */}
        <section className="space-y-4 pt-4 border-t border-gray-100" lang="tr">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-brand-blue rounded-full"></span>
            1. Kira Sözleşmesinde Olması Gereken Zorunlu Maddeler
          </h2>

          <p className="text-gray-700 leading-relaxed">
            Sözleşme ne kadar net olursa, gelecekte yaşanabilecek anlaşmazlık riski o kadar azalır. Sırbistan yasalarına ve genel uygulamalara göre geçerli bir kira sözleşmesinde şu hususlar açıkça yer almalıdır:
          </p>

          <div className="bg-gray-50/80 p-5 rounded-2xl border border-gray-200/80 space-y-3">
            <ul className="space-y-3 text-sm text-gray-700">
              <li className="flex items-start gap-2.5">
                <CheckCircle2 className="w-4 h-4 text-brand-blue flex-shrink-0 mt-1" />
                <span><strong>Kimlik Bilgileri:</strong> Kiracının ve ev sahibinin pasaport numaraları veya Sırbistan T.C. kimlik numarası karşılığı olan <strong>JMBG</strong> bilgileri tam olarak yazılmalıdır.</span>
              </li>
              <li className="flex items-start gap-2.5">
                <CheckCircle2 className="w-4 h-4 text-brand-blue flex-shrink-0 mt-1" />
                <span><strong>Kira Bedeli ve Ödeme Tarihi:</strong> Sözleşmelerde kira genellikle Euro cinsinden belirlense de ödemenin hangi para biriminde (Euro/Dinar) ve ayın hangi gününe kadar yapılacağı netleştirilmelidir.</span>
              </li>
              <li className="flex items-start gap-2.5">
                <CheckCircle2 className="w-4 h-4 text-brand-blue flex-shrink-0 mt-1" />
                <span><strong>Sözleşme Süresi:</strong> Belirli süreli (örneğin 1 yıllık) veya süresiz sözleşme şartları yazılı olmalıdır.</span>
              </li>
            </ul>
          </div>
        </section>

        {/* Section 2 */}
        <section className="space-y-4 pt-6 border-t border-gray-100" lang="tr">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-brand-green rounded-full"></span>
            2. Depozito ve Fatura Sorumlulukları
          </h2>

          <p className="text-gray-700 leading-relaxed">
            Kiralama süreçlerinde en sık karşılaşılan anlaşmazlıklar fatura ödemeleri ve depozito iadesi etrafında yaşanır.
          </p>

          <div className="p-5 rounded-2xl bg-green-50/60 border border-green-200/70 space-y-3">
            <h3 className="font-bold text-gray-900 text-sm flex items-center gap-2 text-green-900">
              <Sparkles className="w-4 h-4 text-brand-green" />
              Sözleşmeye Eklenmesi Gereken Detaylar:
            </h3>

            <p className="text-sm text-gray-700 leading-relaxed">
              Sözleşmede <strong>Infostan</strong> (merkezi ısıtma ve bina giderleri), <strong>EPS</strong> (elektrik) ve internet faturalarını kimin ödeyeceği açıkça belirtilmelidir. Ayrıca genellikle 1 aylık kira bedeli tutarında alınan depozito iade şartları ile dairedeki mevcut demirbaşların durumu (teslim tutanağı / zimmet listesi) sözleşme ekine eklenmelidir.
            </p>
          </div>
        </section>

        {/* Section 3 */}
        <section className="space-y-4 pt-6 border-t border-gray-100" lang="tr">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-amber-500 rounded-full"></span>
            3. İhbar Süresi (Otkazni Rok) ve Tahliye Süreçleri
          </h2>

          <p className="text-gray-700 leading-relaxed">
            Kiracının sözleşmeyi erken feshetmek istemesi veya ödemeleri aksatması durumunda standart ihbar süresi (Sırpça <strong>otkazni rok</strong>) genellikle <strong>30 gündür</strong>. Bu bildirimin yazılı olarak yapılması hukuki bir zorunluluktur.
          </p>
        </section>

        {/* Section 4 */}
        <section className="space-y-5 pt-6 border-t border-gray-100" lang="tr">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-brand-blue rounded-full"></span>
            4. Süreçleri Dijital Asistanınız ile Hatasız Yönetin
          </h2>

          <p className="text-gray-700 leading-relaxed">
            Asıl iş sözleşme imzalandıktan sonra başlar: Aylık kira takibi, ödenen faturaların kontrolü ve sözleşme yenileme tarihlerinin hatırlanması. Birden fazla mülkünüz varsa bunu Excel&apos;de veya kağıt üzerinde tutmak hata riskini artırır.
          </p>

          <div className="bg-gradient-to-r from-blue-50 via-white to-green-50 p-6 rounded-2xl border border-gray-200 space-y-4">
            <h3 className="font-bold text-gray-900 text-base flex items-center gap-2">
              <ShieldCheck className="w-5 h-5 text-brand-blue" />
              Stanomer ile Tam Profesyonelleşme:
            </h3>

            <p className="text-sm text-gray-700 leading-relaxed">
              <strong>Stanomer</strong> gibi bir dijital asistan kullanarak tüm bu süreçleri profesyonelleştirebilirsiniz. Üstelik Stanomer, tüm verilerinizi bulut sunucuları yerine <strong>sadece kendi cihazınızda (local storage)</strong> saklayarak portföyünüzün %100 gizli ve güvende kalmasını sağlar.
            </p>

            {/* CTA Box */}
            <div className="pt-4 text-center sm:text-left border-t border-gray-200/60">
              <div className="p-5 rounded-xl bg-brand-blue text-white space-y-3 shadow-lg">
                <p className="font-bold text-sm leading-snug">
                  📝 Kontratlarınızı ve faturalarınızı dijitalleştirin. Stanomer&apos;i hemen indirin ve Sırbistan&apos;daki tüm kiralama süreçlerinizi güvenle yönetin.
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
