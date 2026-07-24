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
  title: "Novi Sad'da Mülk Yönetimini Profesyonelleştirin: Ev Sahipleri İçin Dijital Sistem | Stanomer",
  description: "Novi Sad'daki ev sahipleri ve yatırımcılar için kiralık ev yönetimi rehberi. Kiracı bulma, kira takibi, fatura arşivleme otomasyonu ve Stanomer lokal mülk yönetim sistemi.",
  keywords: [
    "Novi Sad kiralık ev",
    "Novi Sad mülk yönetimi",
    "Novi Sad ev sahipleri rehberi",
    "Sırbistan kira takibi",
    "Petrovaradin kiralık daire",
    "Liman Detelinara ev kiralama",
    "houses for rent in Novi Sad",
    "stanomer uygulama"
  ],
  alternates: {
    canonical: "https://www.stanomer.online/guide/novi-sad-mulk-yonetimi-rehberi",
    languages: {
      "tr": "https://www.stanomer.online/guide/novi-sad-mulk-yonetimi-rehberi",
      "en": "https://www.stanomer.online/guide/novi-sad-property-management-guide",
      "sr": "https://www.stanomer.online/guide/upravljanje-nekretninama-novi-sad",
      "sr-Cyrl": "https://www.stanomer.online/guide/upravljanje-nekretninama-novi-sad-cirilica",
      "ru": "https://www.stanomer.online/guide/novi-sad-property-management-guide-ru",
    }
  },
  openGraph: {
    title: "Novi Sad'da Mülk Yönetimini Profesyonelleştirin | Stanomer",
    description: "Novi Sad'daki ev sahipleri ve yatırımcılar için dijital kiralık ev ve mülk yönetim rehberi.",
    url: "https://www.stanomer.online/guide/novi-sad-mulk-yonetimi-rehberi",
    siteName: "Stanomer",
    locale: "tr_TR",
    type: "article",
  }
};

const jsonLd = {
  "@context": "https://schema.org",
  "@type": "Article",
  "headline": "Novi Sad'da Mülk Yönetimini Profesyonelleştirin: Ev Sahipleri İçin Dijital Sistem",
  "description": "Novi Sad'daki ev sahipleri ve yatırımcılar için kiralık mülk yönetimi, fatura takibi ve kiracı ilişkileri rehberi.",
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
  "mainEntityOfPage": "https://www.stanomer.online/guide/novi-sad-mulk-yonetimi-rehberi",
  "inLanguage": "tr"
};

export default function NoviSadTurkishGuidePage() {
  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
      />
      <GuideLayout
        currentLang="TR"
        categoryTitle="Novi Sad Mülk Rehberi"
        locationName="Novi Sad, Sırbistan"
        title="Novi Sad'da Mülk Yönetimini Profesyonelleştirin: Ev Sahipleri İçin Dijital Sistem"
        subtitle="Novi Sad'da mülk yatırımı olan veya kiralamalarını profesyonelce yönetmek isteyen ev sahipleri için üç kritik operasyonel alan: doğru kiracıyı bulmak, nakit akışını şeffaf tutmak ve manuel takip sistemlerinden kurtulmak."
        ctaText="Novi Sad'daki Mülk Yönetiminizi Stanomer ile Dijitalleştirin"
        ctaSubtext="Kira takibini, fatura arşivlemeyi ve portföy nakit akışınızı Stanomer'in %100 cihaz içi lokal depolama mimarisiyle güvenle yönetin."
        canonicalUrl="https://www.stanomer.online/guide/novi-sad-mulk-yonetimi-rehberi"
      >
        {/* Intro */}
        <div className="space-y-4">
          <p className="text-gray-700 leading-relaxed">
            Son yıllarda <strong>Novi Sad</strong>, hem yerel yatırımcılar hem de yabancı ev sahipleri için Sırbistan&apos;ın en cazip kiralık gayrimenkul pazarlarından biri haline geldi. Petrovaradin yakınlarındaki bölgelerden şehir merkezine, Liman&apos;dan Detelinara&apos;ya kadar Novi Sad&apos;da kiralık ev ve daire talebi istikrarlı bir şekilde artıyor.
          </p>
          <p className="text-gray-700 leading-relaxed">
            Ancak bu potansiyel, büyüyen bir operasyonel yükü de beraberinde getiriyor: Birden fazla mülkü yöneten ev sahipleri için kira takibi, fatura arşivleme ve kiracı iletişimi kısa sürede karmaşık görevlere dönüşür. Tek bir daireyi kiraya vermek nispeten basit bir süreçtir. Ancak portföyünüz iki, üç veya daha fazla mülke ulaştığında; hangi kiracının bu ayki kirayı ödediğini, bir faturanın kimin adına olduğunu veya bir sözleşmenin ne zaman yenileneceğini takip etmek için hafızanıza veya dağınık dosyalara güvenmek sürdürülebilir bir strateji değildir.
          </p>
        </div>

        {/* Quick Summary Grid Box */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 my-8" lang="tr">
          <div className="p-4 rounded-xl bg-blue-50/70 border border-blue-100 flex items-start gap-3">
            <Search className="w-5 h-5 text-brand-blue flex-shrink-0 mt-0.5" />
            <div>
              <h4 className="font-bold text-xs text-gray-900 tracking-wider mb-1">1. KİRACI SEÇİMİ</h4>
              <p className="text-xs text-gray-600">İlan kalitesi, bölgesel fiyat verileri ve kiracı geçmişi doğrulaması.</p>
            </div>
          </div>

          <div className="p-4 rounded-xl bg-green-50/70 border border-green-100 flex items-start gap-3">
            <BarChart3 className="w-5 h-5 text-brand-green flex-shrink-0 mt-0.5" />
            <div>
              <h4 className="font-bold text-xs text-gray-900 tracking-wider mb-1">2. NAKİT AKIŞI</h4>
              <p className="text-xs text-gray-600">Net ödeme tarihleri, fatura sorumlulukları ve ödeme geçmişi kaydı.</p>
            </div>
          </div>

          <div className="p-4 rounded-xl bg-amber-50/70 border border-amber-100 flex items-start gap-3">
            <Lock className="w-5 h-5 text-amber-600 flex-shrink-0 mt-0.5" />
            <div>
              <h4 className="font-bold text-xs text-gray-900 tracking-wider mb-1">3. DİJİTAL SİSTEM</h4>
              <p className="text-xs text-gray-600">Excel tabloları yerine Stanomer&apos;in gizli, cihaz içi lokal depolaması.</p>
            </div>
          </div>
        </div>

        {/* Section 1 */}
        <section className="space-y-4 pt-4 border-t border-gray-100" lang="tr">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-brand-blue rounded-full"></span>
            Doğru Kiracıyı Bulmak ve Mülkünüzü İlan Etmek
          </h2>

          <p className="text-gray-700 leading-relaxed">
            Novi Sad kiralık mülk piyasası hedef kitleye göre farklı dinamiklere sahiptir. Üniversite bölgelerine yakın daireler öğrenci talebine hitap ederken, müstakil <strong>kiralık ev</strong> arayanlar genellikle aileler, uzun dönemli kiracılar veya uzaktan çalışan profesyonellerdir. Bu iki segment farklı beklentilerle gelir: Öğrenciler fiyat ve ulaşıma odaklanırken, müstakil veya uzun dönem kiralayanlar daha uzun sözleşme süresi, garantili düzenli gelir ve düşük kiracı sirkülasyonu anlamına gelir.
          </p>

          <div className="bg-gray-50/80 p-5 rounded-2xl border border-gray-200/80 space-y-3">
            <h3 className="font-bold text-gray-900 text-sm tracking-wide flex items-center gap-2">
              <Sparkles className="w-4 h-4 text-brand-blue" />
              DOĞRU KİRACIYI BULMAK İÇİN DİKKAT EDİLECEK HUSUSLAR:
            </h3>

            <ul className="space-y-2 text-sm text-gray-700">
              <li className="flex items-start gap-2.5">
                <CheckCircle2 className="w-4 h-4 text-brand-blue flex-shrink-0 mt-1" />
                <span><strong>İlan kalitesi belirleyicidir:</strong> Yüksek çözünürlüklü fotoğraflar, net metrekare bilgisi ve ısıtma/yalıtım detayları, özellikle kış aylarında sorgulama oranlarını doğrudan etkiler.</span>
              </li>
              <li className="flex items-start gap-2.5">
                <CheckCircle2 className="w-4 h-4 text-brand-blue flex-shrink-0 mt-1" />
                <span><strong>Fiyatlandırmanızı bölgesel verilerle destekleyin:</strong> Aynı mahalledeki (Liman, Detelinara, Petrovaradin) benzer mülklerin kira aralığını izlemek boş kalma sürelerini kısaltır ve gelir kaybını önler.</span>
              </li>
              <li className="flex items-start gap-2.5">
                <CheckCircle2 className="w-4 h-4 text-brand-blue flex-shrink-0 mt-1" />
                <span><strong>Kiracı geçmişini doğrulayın:</strong> Geçmiş kira ödeme tutarlılığı ve referanslar, uzun vadede geç ödeme riskini azaltmak için en güçlü göstergeler arasındadır.</span>
              </li>
            </ul>
          </div>
        </section>

        {/* Section 2 */}
        <section className="space-y-4 pt-6 border-t border-gray-100">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-brand-green rounded-full"></span>
            Şeffaf İletişim ve Düzenli Nakit Akışı Sağlamak
          </h2>

          <p className="text-gray-700 leading-relaxed">
            Bir mülkü kiraya vermek nakit akışının başlangıcıdır — garantisi değil. Ev sahipleri için asıl zorluk, bu gelirin öngörülebilir ve istikrarlı kalmasını sağlamaktır. Bu da kiracı ile kurulan iletişimin netliğine bağlıdır.
          </p>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="p-4 rounded-xl bg-white border border-gray-200 shadow-xs space-y-2">
              <h4 className="font-bold text-gray-900 text-sm flex items-center gap-2">
                <FileText className="w-4 h-4 text-brand-green" />
                Net Ödeme Tarihleri
              </h4>
              <p className="text-xs text-gray-600 leading-relaxed">
                Kira son ödeme tarihi sözleşmede belirtilmiş olsa bile, hatırlatıcılar olmadan gecikmeli ödeme oranı önemli ölçüde artar.
              </p>
            </div>

            <div className="p-4 rounded-xl bg-white border border-gray-200 shadow-xs space-y-2">
              <h4 className="font-bold text-gray-900 text-sm flex items-center gap-2">
                <Receipt className="w-4 h-4 text-brand-green" />
                Fatura Sorumlulukları
              </h4>
              <p className="text-xs text-gray-600 leading-relaxed">
                Elektrik, su ve internet ödemelerini kimin yapacağı konusundaki belirsizlik, ev sahibi-kiracı anlaşmazlıklarının en sık nedenlerinden biridir.
              </p>
            </div>

            <div className="p-4 rounded-xl bg-white border border-gray-200 shadow-xs space-y-2">
              <h4 className="font-bold text-gray-900 text-sm flex items-center gap-2">
                <BarChart3 className="w-4 h-4 text-brand-green" />
                Ödeme Geçmişi Kaydı
              </h4>
              <p className="text-xs text-gray-600 leading-relaxed">
                &quot;Kimin neyi ne zaman ödediğine&quot; anında yanıt verebilen bir sistem, her iki taraf için de doğrudan güven inşa eder.
              </p>
            </div>
          </div>
        </section>

        {/* Section 3 */}
        <section className="space-y-4 pt-6 border-t border-gray-100">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-amber-500 rounded-full"></span>
            Excel&apos;den Kurtulmak: Manuel Takibin Gerçek Maliyeti
          </h2>

          <p className="text-gray-700 leading-relaxed">
            Çoğu ev sahibi kira takibine bir Excel tablosu ile başlar. Bu tek bir mülk için yeterli görünebilir. Ancak portföy büyüdükçe satırlar çoğalır, formüller karmaşıklaşır ve en önemlisi—insan hatası riski artar.
          </p>

          <div className="p-5 rounded-2xl bg-amber-50/60 border border-amber-200/70 space-y-3">
            <h3 className="font-bold text-gray-900 text-sm flex items-center gap-2 text-amber-900">
              <AlertCircle className="w-4 h-4 text-amber-600" />
              Fiziksel Fatura Arşivleme ve Ölçeklenme Zorluğu:
            </h3>

            <p className="text-sm text-gray-700 leading-relaxed">
              Fiziksel fatura arşivleme başka bir zorluktur. Elektrik, su ve internet faturaları genellikle farklı tarihlerde ve farklı formatlarda (e-posta, kağıt, SMS) gelir. Veri açısından sorun nettir: <strong>manuel takip sistemleri ölçeklenemez.</strong> Bir mülkten üçe çıktığınızda operasyonel yük sadece iki katına çıkmaz, katlanarak artar.
            </p>
          </div>
        </section>

        {/* Section 4: Solution */}
        <section className="space-y-5 pt-6 border-t border-gray-100">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-brand-blue rounded-full"></span>
            Çözüm: Stanomer — Ev Sahipleri İçin Dijital Mülk Yönetim Asistanı
          </h2>

          <p className="text-gray-700 leading-relaxed">
            <strong>Stanomer</strong> tam da bu ölçeklenme sorununu çözmek için tasarlanmıştır. Excel tablolarının ve dağınık dosyaların yerini merkezi bir mülk yönetimi ve kira takip altyapısı alır.
          </p>

          <div className="bg-gradient-to-r from-blue-50 via-white to-green-50 p-6 rounded-2xl border border-gray-200 space-y-4">
            <h3 className="font-bold text-gray-900 text-base flex items-center gap-2">
              <ShieldCheck className="w-5 h-5 text-brand-blue" />
              Stanomer&apos;in Ev Sahiplerine Sunduğu Temel Yetenekler:
            </h3>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 text-sm">
              <div className="p-3 bg-white rounded-xl border border-gray-200/80">
                <h4 className="font-bold text-gray-900 mb-1">📊 Kira Ödeme Döngüsü Takibi</h4>
                <p className="text-xs text-gray-600">Her mülk için ödeme durumu—ödendi, bekliyor, gecikti—tek bir ekranda görünür hale gelir.</p>
              </div>

              <div className="p-3 bg-white rounded-xl border border-gray-200/80">
                <h4 className="font-bold text-gray-900 mb-1">📁 Fatura Arşivleme Otomasyonu</h4>
                <p className="text-xs text-gray-600">Faturalar dijital olarak arşivlenir, mülke göre sıralanır ve ihtiyaç duyduğunuz her an erişilebilir olur.</p>
              </div>

              <div className="p-3 bg-white rounded-xl border border-gray-200/80">
                <h4 className="font-bold text-gray-900 mb-1">💼 Gelir-Gider İş Akışları</h4>
                <p className="text-xs text-gray-600">Birden fazla mülkten elde edilen finansal veriler tek bir yapı altında toplanarak tüm portföyünüzde net gelir görünürlüğü sağlar.</p>
              </div>

              <div className="p-3 bg-white rounded-xl border border-gray-200/80">
                <h4 className="font-bold text-gray-900 mb-1">🔒 Lokal Depolama (Local Storage) İlkesi</h4>
                <p className="text-xs text-gray-600">Mülk ve kiracı verileriniz cihazınızda kalır; bulut sunucularına gönderilmez veya üçüncü şahıslarla paylaşılmaz.</p>
              </div>
            </div>

            <p className="text-xs text-gray-600 pt-2 border-t border-gray-200/60 leading-relaxed">
              Novi Sad&apos;da birden fazla mülkü olan yatırımcılar için bu mimari, hem finansal verilerin hem de kiracı bilgilerinin gizliliği için kritik bir güvencedir.
            </p>

            {/* Direct High Converting CTA Button Box */}
            <div className="pt-4 text-center sm:text-left border-t border-gray-200/60">
              <div className="p-5 rounded-xl bg-brand-blue text-white space-y-3 shadow-lg">
                <p className="font-bold text-sm leading-snug">
                  📊 Portföyünüz büyüdükçe sisteminiz de büyümeli. Stanomer&apos;i hemen indirin ve Novi Sad&apos;daki mülklerinizi tek bir profesyonel altyapıdan yönetmeye başlayın.
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
