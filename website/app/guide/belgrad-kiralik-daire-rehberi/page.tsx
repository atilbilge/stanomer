import type { Metadata } from "next";
import { GuideLayout } from "../../../components/GuideLayout";
import { 
  Building, 
  FileText, 
  FileCheck,
  Receipt, 
  ShieldCheck, 
  MapPin, 
  CheckCircle2, 
  AlertCircle, 
  Sparkles,
  Smartphone,
  ArrowRight
} from "lucide-react";

export const metadata: Metadata = {
  title: "Belgrad Kiralık Daire Rehberi: Ev Bulmaktan Fatura Takibine | Stanomer",
  description: "Belgrad'da ev kiralama süreçleri, mahalle rehberi, ugovor o zakupu kira sözleşmesi detayları, EPS ve Infostan fatura yönetimi ve Stanomer ile dijital kira takibi rehberi.",
  keywords: [
    "Belgrad kiralık daire rehberi",
    "Belgrad ev kiralama",
    "Belgrad kiralık ev",
    "apartments for rent in belgrade",
    "izdavanje stanova beograd",
    "ugovor o zakupu",
    "Sırbistan fatura takibi",
    "Stanomer"
  ],
  alternates: {
    canonical: "https://www.stanomer.online/guide/belgrad-kiralik-daire-rehberi",
    languages: {
      "tr": "https://www.stanomer.online/guide/belgrad-kiralik-daire-rehberi",
      "en": "https://www.stanomer.online/guide/belgrade-apartment-rental-guide",
      "sr": "https://www.stanomer.online/guide/vodic-za-izdavanje-stanova-beograd",
      "sr-Cyrl": "https://www.stanomer.online/guide/vodic-za-izdavanje-stanova-beograd-cirilica",
    }
  },
  openGraph: {
    title: "Belgrad Kiralık Daire Rehberi: Ev Bulmaktan Fatura Takibine | Stanomer",
    description: "Belgrad'da ev kiralama süreçleri, ugovor o zakupu sözleşme maddeleri ve fatura yönetimi hakkında rehber.",
    url: "https://www.stanomer.online/guide/belgrad-kiralik-daire-rehberi",
    siteName: "Stanomer",
    locale: "tr_TR",
    type: "article",
  }
};

const jsonLd = {
  "@context": "https://schema.org",
  "@type": "Article",
  "headline": "Belgrad Kiralık Daire Rehberi: Ev Bulmaktan Fatura Takibine Kadar Bilmeniz Gereken Her Şey",
  "description": "Expat'lar, öğrenciler ve kiracılar için Belgrad'da kiralık daire bulma, ugovor o zakupu kira sözleşmesi ve fatura takip rehberi.",
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
  "mainEntityOfPage": "https://www.stanomer.online/guide/belgrad-kiralik-daire-rehberi",
  "inLanguage": "tr"
};

export default function TurkishGuidePage() {
  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
      />
      <GuideLayout
        currentLang="TR"
        title="Belgrad Kiralık Daire Rehberi: Ev Bulmaktan Fatura Takibine Kadar Bilmeniz Gereken Her Şey"
        subtitle="Belgrad'da ev kiralama süreçleri, kira sözleşmesi detayları (ugovor o zakupu) ve fatura yönetimini kapsayan kapsamlı rehber."
        ctaText="Kiralarınızı ve Sırbistan'daki faturalarınızı yerel olarak güvenle saklamak ve takip etmek için Stanomer'i indirin"
        ctaSubtext="Stanomer verilerinizi yalnızca cihazınızda (local storage) saklar. Bulut sunucularına göndermez, finansal gizliliğinizi %100 korur."
        canonicalUrl="https://www.stanomer.online/guide/belgrad-kiralik-daire-rehberi"
      >
        {/* Intro */}
        <div className="space-y-4">
          <p className="text-gray-700 leading-relaxed">
            Belgrad'a taşınmayı planlıyorsanız — ister bir üniversite programı için, ister uzaktan çalışma nedeniyle, ister şehri kalıcı olarak yeni yurdunuz yapmak için — karşınıza çıkan ilk soru hep aynı: <strong>nereden başlamalı?</strong>
          </p>
          <p className="text-gray-700 leading-relaxed">
            Belgrad kiralık daire arayışı, doğru bilgiyle oldukça yönetilebilir bir süreç. Ama yanlış ilanlara zaman kaybetmek, kira sözleşmesindeki bir maddeyi atlamak ya da ilk faturanızı ne zaman ödeyeceğinizi bilmemek gibi küçük detaylar, süreci gereksiz yere zorlaştırabilir. Bu rehber, expat&apos;lar, öğrenciler ve şehir içinde taşınmayı düşünen yerel kiracılar için Belgrad&apos;da ev kiralamanın üç kritik aşamasını — <strong>arama, sözleşme ve fatura yönetimi</strong> — tek bir yerde topluyor.
          </p>
        </div>

        {/* Quick Summary Grid Box */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 my-8" lang="tr">
          <div className="p-4 rounded-xl bg-blue-50/70 border border-blue-100 flex items-start gap-3">
            <Building className="w-5 h-5 text-brand-blue flex-shrink-0 mt-0.5" />
            <div>
              <h4 className="font-bold text-xs text-gray-900 tracking-wider mb-1">1. DAİRE ARAMA</h4>
              <p className="text-xs text-gray-600">Vračar, Novi Beograd, Zvezdara mahalle analizi ve ilan platformları.</p>
            </div>
          </div>

          <div className="p-4 rounded-xl bg-green-50/70 border border-green-100 flex items-start gap-3">
            <FileText className="w-5 h-5 text-brand-green flex-shrink-0 mt-0.5" />
            <div>
              <h4 className="font-bold text-xs text-gray-900 tracking-wider mb-1">2. UGOVOR O ZAKUPU</h4>
              <p className="text-xs text-gray-600">Sözleşme süreleri, noter onayı, envanter ve kira artış maddeleri.</p>
            </div>
          </div>

          <div className="p-4 rounded-xl bg-amber-50/70 border border-amber-100 flex items-start gap-3">
            <Receipt className="w-5 h-5 text-amber-600 flex-shrink-0 mt-0.5" />
            <div>
              <h4 className="font-bold text-xs text-gray-900 tracking-wider mb-1">3. FATURA YÖNETİMİ</h4>
              <p className="text-xs text-gray-600">EPS elektrik, Infostan belediye giderleri ve internet takibi.</p>
            </div>
          </div>
        </div>

        {/* Section 1 */}
        <section className="space-y-4 pt-4 border-t border-gray-100" lang="tr">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-brand-blue rounded-full"></span>
            Belgrad&apos;da Doğru Kiralık Daireyi Bulmak İçin İpuçları
          </h2>

          <p className="text-gray-700 leading-relaxed">
            Belgrad&apos;ın kiralık piyasası mahalleye göre büyük farklılık gösterir. <strong>Vračar</strong> ve <strong>Stari Grad</strong> şehir merkezine yakınlığıyla öne çıkar ve buna paralel olarak daha yüksek kiralara sahiptir. <strong>Novi Beograd</strong> ise iş merkezlerine yakınlığı ve modern konut stoğuyla özellikle uzaktan çalışanlar ve genç profesyoneller arasında popüler. Öğrenciler için <strong>Zvezdara</strong> ve <strong>Voždovac</strong> gibi bölgeler, üniversite kampüslerine yakınlık ve daha uygun fiyat dengesi sunuyor.
          </p>

          <div className="bg-gray-50/80 p-5 rounded-2xl border border-gray-200/80 space-y-3">
            <h3 className="font-bold text-gray-900 text-sm tracking-wide flex items-center gap-2">
              <Sparkles className="w-4 h-4 text-brand-blue" />
              ARAMA SÜRECİNDE DİKKAT EDİLMESİ GEREKENLER:
            </h3>

            <ul className="space-y-2 text-sm text-gray-700">
              <li className="flex items-start gap-2.5">
                <CheckCircle2 className="w-4 h-4 text-brand-blue flex-shrink-0 mt-1" />
                <span><strong>İlan platformlarını çapraz kontrol edin:</strong> Aynı daire birden fazla sitede farklı fiyatlarla listelenebilir. En güncel ve doğru bilgiye ulaşmak için birkaç kaynağı karşılaştırın.</span>
              </li>
              <li className="flex items-start gap-2.5">
                <CheckCircle2 className="w-4 h-4 text-brand-blue flex-shrink-0 mt-1" />
                <span><strong>Arama terimleri:</strong> <i>&quot;Apartments for rent in Belgrade&quot;</i> araması yapan expat&apos;lar için ilan siteleri İngilizce filtre sunar; ancak yerel emlakçılarla iletişimde Sırpça temel terimleri bilmek pazarlık gücünüzü artırır.</span>
              </li>
              <li className="flex items-start gap-2.5">
                <CheckCircle2 className="w-4 h-4 text-brand-blue flex-shrink-0 mt-1" />
                <span><strong>Depozito ve komisyon şartları:</strong> Genellikle 1-2 aylık kira tutarında depozito istenir; bu tutarın sözleşme sonunda hangi koşullarla iade edileceğini yazılı olarak isteyin.</span>
              </li>
              <li className="flex items-start gap-2.5">
                <CheckCircle2 className="w-4 h-4 text-brand-blue flex-shrink-0 mt-1" />
                <span><strong>Daireyi yerinde görün:</strong> Fotoğraflarda görünmeyen ısıtma sistemi (mermer radyatör, TA peć, CG merkezi ısıtma), izolasyon kalitesi ve gürültü seviyesi gibi detaylar kışın konforunuzu doğrudan etkiler.</span>
              </li>
              <li className="flex items-start gap-2.5">
                <CheckCircle2 className="w-4 h-4 text-brand-blue flex-shrink-0 mt-1" />
                <span><strong>Sırpça arama terimi:</strong> Sırpça arama yapıyorsanız, <code className="bg-gray-200 px-1.5 py-0.5 rounded text-brand-blue font-semibold">izdavanje stanova Beograd</code> ifadesi yerel ilan sitelerinde en çok kullanılan arama terimlerinden biri ve genellikle daha geniş bir ilan havuzuna erişmenizi sağlar.</span>
              </li>
            </ul>
          </div>
        </section>

        {/* Section 2 */}
        <section className="space-y-4 pt-6 border-t border-gray-100">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-brand-green rounded-full"></span>
            Kira Sözleşmesi (Ugovor o Zakupu) Yaparken Dikkat Edilmesi Gereken Yasal Detaylar
          </h2>

          <p className="text-gray-700 leading-relaxed">
            Sırbistan&apos;da kira sözleşmesi — yerel adıyla <strong>ugovor o zakupu</strong> — hem ev sahibini hem kiracıyı koruyan yasal bir belgedir. Sözleşme imzalamadan önce şu maddeleri mutlaka kontrol edin:
          </p>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="p-4 rounded-xl bg-white border border-gray-200 shadow-xs space-y-2">
              <h4 className="font-bold text-gray-900 text-sm flex items-center gap-2">
                <FileCheck className="w-4 h-4 text-brand-green" />
                Kira Süresi & Yenileme
              </h4>
              <p className="text-xs text-gray-600 leading-relaxed">
                Sözleşmenin belirli süreli mi yoksa süresiz mi olduğunu ve erken fesih durumunda hangi tarafın ne kadar önceden bildirim yapması gerektiğini netleştirin.
              </p>
            </div>

            <div className="p-4 rounded-xl bg-white border border-gray-200 shadow-xs space-y-2">
              <h4 className="font-bold text-gray-900 text-sm flex items-center gap-2">
                <FileCheck className="w-4 h-4 text-brand-green" />
                Kira Artış Şartları
              </h4>
              <p className="text-xs text-gray-600 leading-relaxed">
                Uzun vadeli kiralamalarda kira artışının hangi sıklıkla ve hangi kritere göre (örneğin enflasyon oranı) yapılacağı sözleşmede açıkça belirtilmeli.
              </p>
            </div>

            <div className="p-4 rounded-xl bg-white border border-gray-200 shadow-xs space-y-2">
              <h4 className="font-bold text-gray-900 text-sm flex items-center gap-2">
                <FileCheck className="w-4 h-4 text-brand-green" />
                Faturaların Sorumluluğu
              </h4>
              <p className="text-xs text-gray-600 leading-relaxed">
                Elektrik, su, ısınma ve internet giderlerinin kira bedeline dahil olup olmadığı tek tek yazılmalı. Kiracıların en sık karşılaştığı belirsizlik noktalarından biridir.
              </p>
            </div>

            <div className="p-4 rounded-xl bg-white border border-gray-200 shadow-xs space-y-2">
              <h4 className="font-bold text-gray-900 text-sm flex items-center gap-2">
                <FileCheck className="w-4 h-4 text-brand-green" />
                Noter Onayı & Envanter
              </h4>
              <p className="text-xs text-gray-600 leading-relaxed">
                Uzun süreli kiralamalarda sözleşmenin noterde onaylanması ve fotoğraflı envanter listesi eklenmesi çıkış sürecindeki anlaşmazlıkları önler.
              </p>
            </div>
          </div>
        </section>

        {/* Section 3 */}
        <section className="space-y-4 pt-6 border-t border-gray-100">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-amber-500 rounded-full"></span>
            Sırbistan&apos;da Elektrik, Su ve İnternet Faturalarının Yönetimi
          </h2>

          <p className="text-gray-700 leading-relaxed">
            Sözleşme imzalandıktan sonra asıl gündelik zorluk başlıyor: Sırbistan&apos;da fatura ödeme ve takibi süreci. Elektrik (<strong>EPS</strong>), su/belediye (<strong>Infostan</strong>) ve internet/kablo faturaları genelde ayrı ayrı gelir ve her birinin ödeme tarihi farklıdır. Expat&apos;lar için ek bir zorluk da faturaların çoğunlukla Sırpça düzenlenmesi.
          </p>

          <div className="p-5 rounded-2xl bg-amber-50/60 border border-amber-200/70 space-y-3">
            <h3 className="font-bold text-gray-900 text-sm flex items-center gap-2 text-amber-900">
              <AlertCircle className="w-4 h-4 text-amber-600" />
              Fatura Yönetiminde Kritik Noktalar:
            </h3>

            <ul className="space-y-2 text-sm text-gray-700">
              <li className="flex items-start gap-2">
                <span className="w-1.5 h-1.5 rounded-full bg-amber-600 mt-2 flex-shrink-0" />
                <span>Faturaların ev sahibinin adına mı yoksa kiracının adına mı kayıtlı olduğunu baştan öğrenin — bu, ödeme sorumluluğunu belirler.</span>
              </li>
              <li className="flex items-start gap-2">
                <span className="w-1.5 h-1.5 rounded-full bg-amber-600 mt-2 flex-shrink-0" />
                <span>Gecikme durumunda kesinti riski olabileceğinden, her faturanın son ödeme tarihini ayrı ayrı takip etmek gerekir.</span>
              </li>
              <li className="flex items-start gap-2">
                <span className="w-1.5 h-1.5 rounded-full bg-amber-600 mt-2 flex-shrink-0" />
                <span>Ev sahibi ile fatura paylaşımı yapılan durumlarda (özellikle oda arkadaşlı kiralamalarda), kim ne kadar ödedi sorusu zamanla karmaşıklaşabilir.</span>
              </li>
            </ul>

            <p className="text-xs text-amber-800 pt-2 border-t border-amber-200/60 italic">
              Bu noktada birçok kiracı ve ev sahibi, faturaları WhatsApp mesajlarında, e-postalarda veya kağıt üzerinde dağınık şekilde takip etmeye çalışıyor — ve bu da unutulan ödemelere, tekrarlanan tartışmalara yol açıyor.
            </p>
          </div>
        </section>

        {/* Section 4: Solution */}
        <section className="space-y-5 pt-6 border-t border-gray-100">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-brand-blue rounded-full"></span>
            Çözüm: Stanomer ile Kira ve Fatura Takibini Tek Yerde Toplayın
          </h2>

          <p className="text-gray-700 leading-relaxed">
            Belgrad ev kiralama rehberi boyunca bahsettiğimiz üç sorun — <strong>fatura kaybetme, kira ödeme tarihini unutma ve ev sahibiyle iletişim karmaşası</strong> — aslında tek bir kök nedene bağlanıyor: dağınık takip sistemi. Stanomer, tam olarak bu boşluğu doldurmak için tasarlandı.
          </p>

          <div className="bg-gradient-to-r from-blue-50 via-white to-green-50 p-6 rounded-2xl border border-gray-200 space-y-4">
            <h3 className="font-bold text-gray-900 text-base flex items-center gap-2">
              <ShieldCheck className="w-5 h-5 text-brand-blue" />
              Stanomer Kiracılara Ne Sunuyor?
            </h3>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 text-sm">
              <div className="p-3 bg-white rounded-xl border border-gray-200/80">
                <h4 className="font-bold text-gray-900 mb-1">✅ Anında Kira Kaydı</h4>
                <p className="text-xs text-gray-600">Her kira ödemesini gerçekleştiği anda kaydedersiniz. Ne ödendi, ne bekliyor tek ekranda görürsünüz.</p>
              </div>

              <div className="p-3 bg-white rounded-xl border border-gray-200/80">
                <h4 className="font-bold text-gray-900 mb-1">📁 Dijital Fatura Arşivi</h4>
                <p className="text-xs text-gray-600">Elektrik, su ve internet faturalarınızı tek dijital arşivde saklarsınız. Mesajlarda arama yapmaya son.</p>
              </div>

              <div className="p-3 bg-white rounded-xl border border-gray-200/80">
                <h4 className="font-bold text-gray-900 mb-1">📜 Net Şeffaf Kayıt</h4>
                <p className="text-xs text-gray-600">Ev sahibiyle olan ödeme geçmişiniz net bir kayıt halinde tutulur — anlaşmazlık çıktığında kanıtınız hazır.</p>
              </div>

              <div className="p-3 bg-white rounded-xl border border-gray-200/80">
                <h4 className="font-bold text-gray-900 mb-1">🔒 %100 Cihazda Gizlilik</h4>
                <p className="text-xs text-gray-600">Verileriniz yerel depolama (local storage) ile cihazınızdadır. Bulut sunucularına aktarılmaz, 3. şahıslarla paylaşılmaz.</p>
              </div>
            </div>

            {/* Direct High Converting CTA Button Box */}
            <div className="pt-4 text-center sm:text-left border-t border-gray-200/60">
              <div className="p-5 rounded-xl bg-brand-blue text-white space-y-3 shadow-lg">
                <p className="font-bold text-sm leading-snug">
                  📲 Kiralarınızı ve Sırbistan&apos;daki faturalarınızı yerel olarak güvenle saklamak ve takip etmek için Stanomer&apos;i indirin.
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

        {/* Section 5: Conclusion */}
        <section className="space-y-4 pt-6 border-t border-gray-100">
          <h2 className="text-xl font-bold text-gray-900">Sonuç</h2>
          <p className="text-gray-700 leading-relaxed">
            Belgrad&apos;da kiralık daire bulmak, doğru mahalleyi seçmek, sözleşmenin yasal detaylarını anlamak ve fatura süreçlerini yönetmek kadar basit bir denklem. Her adımı doğru atarsanız, şehirdeki ilk aylarınız stressiz geçer. Arama ve sözleşme aşamasını tamamladıktan sonra geriye kalan tek şey, günlük hayatın rutinini düzenli tutmak — ve bunun için doğru araç fark yaratır.
          </p>

          <div className="p-5 rounded-2xl bg-gray-900 text-white text-center space-y-3 shadow-xl">
            <h3 className="font-bold text-base text-brand-green">
              📲 Kira takibini unutmayın, faturalarınızı kaybetmeyin.
            </h3>
            <p className="text-xs text-gray-300">
              Stanomer&apos;i şimdi indirin ve Belgrad&apos;daki yeni evinizde ilk günden düzen kurun.
            </p>
            <div className="pt-2 flex justify-center gap-3">
              <a 
                href="/app"
                className="px-6 py-2.5 rounded-lg bg-brand-blue hover:bg-blue-600 text-white font-semibold text-xs transition-all shadow-md"
              >
                Web Uygulaması
              </a>
              <a 
                href="https://apps.apple.com/us/app/stanomer/id6762311157" 
                target="_blank" 
                rel="noopener noreferrer"
                className="px-6 py-2.5 rounded-lg bg-white/10 hover:bg-white/20 text-white font-semibold text-xs border border-white/20 transition-all"
              >
                iOS / Android İndir
              </a>
            </div>
          </div>
        </section>
      </GuideLayout>
    </>
  );
}
