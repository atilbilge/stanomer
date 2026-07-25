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
  title: "Dijital Göçmenler ve Yabancılara Ev Kiralamak: Beli Karton Süreci | Stanomer",
  description: "Belgrad ve Novi Sad'da yabancılara ve dijital göçmenlere ev kiralarken bilmeniz gerekenler: Beli Karton (Beyaz Kart) polis bildirimi, iki dilli sözleşme ve Stanomer ile güvenli kira takibi.",
  keywords: [
    "Sırbistan Beli Karton",
    "Beyaz Kart Sırbistan ev kiralama",
    "Belgrad dijital göçmen ev kiralama",
    "Novi Sad expat ev kiralama",
    "prijava boravista MUP eUprava",
    "yabancılara ev kiralama rehberi",
    "stanomer mülk yönetimi"
  ],
  alternates: {
    canonical: "https://www.stanomer.online/guide/dijital-gocmenlere-ev-kiralama-beli-karton",
    languages: {
      "tr": "https://www.stanomer.online/guide/dijital-gocmenlere-ev-kiralama-beli-karton",
      "en": "https://www.stanomer.online/guide/renting-to-foreigners-digital-nomads-beli-karton",
      "sr": "https://www.stanomer.online/guide/izdavanje-stana-strancima-beli-karton",
      "sr-Cyrl": "https://www.stanomer.online/guide/izdavanje-stana-strancima-beli-karton-cirilica",
      "ru": "https://www.stanomer.online/guide/renting-to-foreigners-digital-nomads-beli-karton-ru",
    }
  },
  openGraph: {
    title: "Dijital Göçmenler ve Yabancılara Ev Kiralamak: Beli Karton Süreci | Stanomer",
    description: "Belgrad ve Novi Sad'da yabancılara ev kiralarken Beli Karton (Beyaz Kart) polis bildirimi ve güvenli mülk yönetimi rehberi.",
    url: "https://www.stanomer.online/guide/dijital-gocmenlere-ev-kiralama-beli-karton",
    siteName: "Stanomer",
    locale: "tr_TR",
    type: "article",
  }
};

const jsonLd = {
  "@context": "https://schema.org",
  "@type": "Article",
  "headline": "Dijital Göçmenler ve Yabancılara Ev Kiralamak: Beli Karton Süreci ve Güvenli Mülk Yönetimi",
  "description": "Belgrad ve Novi Sad'da yabancılara ve dijital göçmenlere ev kiralarken bilmeniz gerekenler: Beli Karton (Beyaz Kart) bildirimi ve dijital süreç yönetimi.",
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
  "mainEntityOfPage": "https://www.stanomer.online/guide/dijital-gocmenlere-ev-kiralama-beli-karton",
  "inLanguage": "tr"
};

export default function BeliKartonTurkishGuidePage() {
  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
      />
      <GuideLayout
        currentLang="TR"
        categoryTitle="Yabancılara Kiralama & Beli Karton"
        locationName="Sırbistan (Belgrad & Novi Sad)"
        title="Dijital Göçmenler ve Yabancılara Ev Kiralamak: Beli Karton Süreci ve Güvenli Mülk Yönetimi"
        subtitle="Belgrad ve Novi Sad'da yabancı kiracılara ve dijital göçmenlere ev kiralarken bilmeniz gerekenler: Beli Karton (Beyaz Kart) polis bildirimi, iki dilli sözleşme ve Stanomer ile dijital süreç yönetimi."
        ctaText="Yabancı Kiracılarınızla Süreçleri Stanomer ile Profesyonelleştirin"
        ctaSubtext="Kira ve fatura takibini çok dilli arayüz ve Stanomer'in %100 cihaz içi yerel depolama mimarisiyle güvenle yönetin."
        canonicalUrl="https://www.stanomer.online/guide/dijital-gocmenlere-ev-kiralama-beli-karton"
      >
        {/* Intro */}
        <div className="space-y-4" lang="tr">
          <p className="text-gray-700 leading-relaxed">
            Son yıllarda Sırbistan, Avrupa&apos;nın dijital göçmenler ve expat&apos;lar için en popüler merkezlerinden biri haline geldi. <strong>Belgrad</strong>&apos;ın dinamik şehir yaşamı ve <strong>Novi Sad</strong>&apos;ın huzurlu temposu, dünyanın dört bir yanından uzaktan çalışan profesyonelleri çekiyor.
          </p>
          <p className="text-gray-700 leading-relaxed">
            Yabancılara ev kiralamak genellikle ev sahipleri için daha yüksek getiri sağlasa da, beraberinde belirli idari yükümlülükler de getirir.
          </p>
        </div>

        {/* Quick Highlights Box */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 my-8" lang="tr">
          <div className="p-4 rounded-xl bg-blue-50/70 border border-blue-100 flex items-start gap-3">
            <FileCheck className="w-5 h-5 text-brand-blue flex-shrink-0 mt-0.5" />
            <div>
              <h4 className="font-bold text-xs text-gray-900 tracking-wider mb-1">1. BELİ KARTON</h4>
              <p className="text-xs text-gray-600">Ülkeye girişten itibaren 24 saat içinde MUP veya e-Uprava bildirimi zorunludur.</p>
            </div>
          </div>

          <div className="p-4 rounded-xl bg-green-50/70 border border-green-100 flex items-start gap-3">
            <MessageSquare className="w-5 h-5 text-brand-green flex-shrink-0 mt-0.5" />
            <div>
              <h4 className="font-bold text-xs text-gray-900 tracking-wider mb-1">2. ÇOK DİLLİ İLETİŞİM</h4>
              <p className="text-xs text-gray-600">İki dilli sözleşme ve İngilizce Hoş Geldiniz Rehberi profesyonellik katar.</p>
            </div>
          </div>

          <div className="p-4 rounded-xl bg-amber-50/70 border border-amber-100 flex items-start gap-3">
            <BadgeDollarSign className="w-5 h-5 text-amber-600 flex-shrink-0 mt-0.5" />
            <div>
              <h4 className="font-bold text-xs text-gray-900 tracking-wider mb-1">3. PARA BİRİMİ & TAKİP</h4>
              <p className="text-xs text-gray-600">Euro kira ve Dinar fatura takibini Stanomer lokal altyapısıyla otomatikleştirin.</p>
            </div>
          </div>
        </div>

        {/* Section 1 */}
        <section className="space-y-4 pt-4 border-t border-gray-100" lang="tr">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-brand-blue rounded-full"></span>
            1. &quot;Beli Karton&quot; (Beyaz Kart) Prosedürünü İhmal Etmeyin
          </h2>

          <p className="text-gray-700 leading-relaxed">
            Yabancı bir kiracıya ev kiralarken en önemli yasal zorunluluk, halk arasında <strong>Beli karton</strong> olarak bilinen ikametgah kayıt prosedürüdür.
          </p>

          <div className="bg-gray-50/80 p-5 rounded-2xl border border-gray-200/80 space-y-3">
            <h3 className="font-bold text-gray-900 text-sm tracking-wide flex items-center gap-2">
              <Sparkles className="w-4 h-4 text-brand-blue" />
              YASAL ZORUNLULUK VE SÜRE:
            </h3>

            <p className="text-sm text-gray-700 leading-relaxed">
              Yabancı ülke vatandaşının Sırbistan&apos;a giriş yapmasından itibaren <strong>24 saat içinde</strong> yerel emniyet müdürlüğüne (MUP) veya <strong>e-Uprava</strong> portalı üzerinden kaydının yapılması gerekir. Ev sahibi olarak bu kaydı onaylamak sizin yasal sorumluluğunuzdadır.
            </p>
          </div>
        </section>

        {/* Section 2 */}
        <section className="space-y-4 pt-6 border-t border-gray-100" lang="tr">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-brand-green rounded-full"></span>
            2. İletişim ve Dil Bariyerini Aşmak
          </h2>

          <p className="text-gray-700 leading-relaxed">
            Dijital göçmenlerle iletişim çoğunlukla İngilizce yürütülür. Anlaşmazlıkları önlemek için kira sözleşmenizin <strong>iki dilli (Sırpça ve İngilizce)</strong> hazırlanması hayati önem taşır.
          </p>

          <p className="text-gray-700 leading-relaxed">
            Ayrıca tesisat, elektrik ve acil durum kişilerini içeren İngilizce bir &quot;Hoş Geldiniz Rehberi&quot; sunmak ev sahibi olarak imajınızı son derece profesyonel kılacaktır.
          </p>
        </section>

        {/* Section 3 */}
        <section className="space-y-4 pt-6 border-t border-gray-100" lang="tr">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-amber-500 rounded-full"></span>
            3. Para Birimleri ve Fatura Takibi
          </h2>

          <p className="text-gray-700 leading-relaxed">
            Yabancı kiracılar kirayı sıklıkla Euro olarak öderken, yerel faturalar (elektrik EPS, su, internet) Dinar cinsinden gelir. Yabancı kiracının bu faturaları zamanında ödeyip ödemediğini manuel takip etmek karmaşıklaşabilir.
          </p>
        </section>

        {/* Section 4 */}
        <section className="space-y-5 pt-6 border-t border-gray-100" lang="tr">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-brand-blue rounded-full"></span>
            4. Uluslararası Kiracılar İçin Dijital Mülk Yönetimi
          </h2>

          <p className="text-gray-700 leading-relaxed">
            Uluslararası expat&apos;lar ve dijital göçmenler veri gizliliğine ve şeffaflığa büyük önem verir. WhatsApp üzerinden dekont fotoğrafları mesajlaşmak yerine dijital bir altyapı kullanmak güven inşa eder.
          </p>

          <div className="bg-gradient-to-r from-blue-50 via-white to-green-50 p-6 rounded-2xl border border-gray-200 space-y-4">
            <h3 className="font-bold text-gray-900 text-base flex items-center gap-2">
              <ShieldCheck className="w-5 h-5 text-brand-blue" />
              Stanomer Çok Dilli Yönetim Avantajı:
            </h3>

            <p className="text-sm text-gray-700 leading-relaxed">
              <strong>Stanomer</strong> uygulaması üzerinden tüm ödemeleri ve faturaları tek bir ekranda takip edebilirsiniz. Stanomer Türkçe, İngilizce, Sırpça ve Rusça dillerini destekler. Üstelik <strong>local storage</strong> mimarisi sayesinde, finansal verileriniz ve kiracınızın bilgileri internete sızmadan sadece kendi telefonunuzda %100 gizlilikle saklanır.
            </p>

            {/* CTA Box */}
            <div className="pt-4 text-center sm:text-left border-t border-gray-200/60">
              <div className="p-5 rounded-xl bg-brand-blue text-white space-y-3 shadow-lg">
                <p className="font-bold text-sm leading-snug">
                  🌐 Yabancı kiracılarınızla profesyonel bir sistem kurun. Stanomer&apos;i hemen indirin ve mülklerinizi çok dilli altyapı ile yönetin.
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
