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
  title: "Как безопасно сдать квартиру иностранцам и цифровым кочевникам в Белграде и Нови-Саде | Stanomer",
  description: "Все, что нужно знать о процессе оформления «Белого картона» (Beli karton), коммуникации и отслеживании арендной платы при сдаче жилья экспатам в Сербии.",
  keywords: [
    "Белый картон Сербия",
    "Beli karton регистрация",
    "аренда иностранцам Белград",
    "цифровые кочевники Нови-Сад",
    "MUP eUprava регистрация",
    "сдача квартиры экспатам Сербия",
    "приложение stanomer"
  ],
  alternates: {
    canonical: "https://www.stanomer.online/guide/renting-to-foreigners-digital-nomads-beli-karton-ru",
    languages: {
      "tr": "https://www.stanomer.online/guide/dijital-gocmenlere-ev-kiralama-beli-karton",
      "en": "https://www.stanomer.online/guide/renting-to-foreigners-digital-nomads-beli-karton",
      "sr": "https://www.stanomer.online/guide/izdavanje-stana-strancima-beli-karton",
      "sr-Cyrl": "https://www.stanomer.online/guide/izdavanje-stana-strancima-beli-karton-cirilica",
      "ru": "https://www.stanomer.online/guide/renting-to-foreigners-digital-nomads-beli-karton-ru",
    }
  },
  openGraph: {
    title: "Как безопасно сдать квартиру иностранцам и цифровым кочевникам в Белграде и Нови-Саде | Stanomer",
    description: "Все, что нужно знать о процессе оформления «Белого картона» (Beli karton), коммуникации и отслеживании арендной платы при сдаче жилья экспатам в Сербии.",
    url: "https://www.stanomer.online/guide/renting-to-foreigners-digital-nomads-beli-karton-ru",
    siteName: "Stanomer",
    locale: "ru_RU",
    type: "article",
  }
};

const jsonLd = {
  "@context": "https://schema.org",
  "@type": "Article",
  "headline": "Как безопасно сдать квартиру иностранцам и цифровым кочевникам в Белграде и Нови-Саде",
  "description": "Все, что нужно знать о процессе оформления «Белого картона», коммуникации и отслеживании арендной платы при сдаче жилья экспатам в Сербии.",
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
  "mainEntityOfPage": "https://www.stanomer.online/guide/renting-to-foreigners-digital-nomads-beli-karton-ru",
  "inLanguage": "ru"
};

export default function BeliKartonRussianGuidePage() {
  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
      />
      <GuideLayout
        currentLang="RU"
        categoryTitle="Аренда Иностранцам & Белый Картон"
        locationName="Сербия (Белград & Нови-Сад)"
        title="Как безопасно сдать квартиру иностранцам и цифровым кочевникам в Белграде и Нови-Саде"
        subtitle="Все, что нужно знать о процессе оформления «Белого картона» (Beli karton), коммуникации и отслеживании арендной платы при сдаче жилья экспатам в Сербии."
        ctaText="Профессиональный подход к аренде для иностранных жильцов с Stanomer"
        ctaSubtext="Отслеживайте все платежи и счета в многоязычном интерфейсе Stanomer с 100% local storage хранением на вашем устройстве."
        canonicalUrl="https://www.stanomer.online/guide/renting-to-foreigners-digital-nomads-beli-karton-ru"
      >
        {/* Intro */}
        <div className="space-y-4" lang="ru">
          <p className="text-gray-700 leading-relaxed">
            Сербия стала одним из самых популярных центров для цифровых кочевников и экспатов в Европе. Динамичность <strong>Белграда</strong> и размеренность <strong>Нови-Сада</strong> привлекают специалистов со всего мира.
          </p>
          <p className="text-gray-700 leading-relaxed">
            Сдача квартиры иностранцам обычно приносит более высокий доход, но требует от арендодателя знания важных административных нюансов.
          </p>
        </div>

        {/* Quick Highlights Box */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 my-8" lang="ru">
          <div className="p-4 rounded-xl bg-blue-50/70 border border-blue-100 flex items-start gap-3">
            <FileCheck className="w-5 h-5 text-brand-blue flex-shrink-0 mt-0.5" />
            <div>
              <h4 className="font-bold text-xs text-gray-900 tracking-wider mb-1">1. БЕЛЫЙ КАРТОН</h4>
              <p className="text-xs text-gray-600">Регистрация в полиции (MUP) или e-Uprava в течение 24 часов обязательна.</p>
            </div>
          </div>

          <div className="p-4 rounded-xl bg-green-50/70 border border-green-100 flex items-start gap-3">
            <MessageSquare className="w-5 h-5 text-brand-green flex-shrink-0 mt-0.5" />
            <div>
              <h4 className="font-bold text-xs text-gray-900 tracking-wider mb-1">2. ДВУЯЗЫЧНЫЙ ДОГОВОР</h4>
              <p className="text-xs text-gray-600">Двуязычный договор (сербский и английский/русский) и приветственное руководство.</p>
            </div>
          </div>

          <div className="p-4 rounded-xl bg-amber-50/70 border border-amber-100 flex items-start gap-3">
            <BadgeDollarSign className="w-5 h-5 text-amber-600 flex-shrink-0 mt-0.5" />
            <div>
              <h4 className="font-bold text-xs text-gray-900 tracking-wider mb-1">3. ВАЛЮТА И УЧЕТ</h4>
              <p className="text-xs text-gray-600">Контроль арендной платы в евро и счетов в динарах с local storage в Stanomer.</p>
            </div>
          </div>
        </div>

        {/* Section 1 */}
        <section className="space-y-4 pt-4 border-t border-gray-100" lang="ru">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-brand-blue rounded-full"></span>
            1. Не игнорируйте «Белый картон» (Beli Karton)
          </h2>

          <p className="text-gray-700 leading-relaxed">
            Главное юридическое обязательство при сдаче жилья иностранному гражданину — регистрация по месту пребывания, известная как <strong>Beli karton (Белый картон)</strong>.
          </p>

          <div className="bg-gray-50/80 p-5 rounded-2xl border border-gray-200/80 space-y-3">
            <h3 className="font-bold text-gray-900 text-sm tracking-wide flex items-center gap-2">
              <Sparkles className="w-4 h-4 text-brand-blue" />
              СРОКИ И ПОРЯДОК ОФОРМЛЕНИЯ:
            </h3>

            <p className="text-sm text-gray-700 leading-relaxed">
              Иностранец должен быть зарегистрирован в местном отделении полиции (<strong>MUP</strong>) или через портал <strong>e-Uprava</strong> в течение <strong>24 часов</strong> после въезда в страну. Вы, как владелец недвижимости, обязаны официально подтвердить эту регистрацию.
            </p>
          </div>
        </section>

        {/* Section 2 */}
        <section className="space-y-4 pt-6 border-t border-gray-100" lang="ru">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-brand-green rounded-full"></span>
            2. Преодоление языкового барьера
          </h2>

          <p className="text-gray-700 leading-relaxed">
            Общение с цифровыми кочевниками чаще всего происходит на английском языке. Договор аренды обязательно должен быть <strong>двуязычным (на сербском и английском/русском)</strong>.
          </p>

          <p className="text-gray-700 leading-relaxed">
            Краткое «Приветственное руководство» на английском с контактами экстренных служб и сантехников подчеркнет ваш высокий уровень профессионализма.
          </p>
        </section>

        {/* Section 3 */}
        <section className="space-y-4 pt-6 border-t border-gray-100" lang="ru">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-amber-500 rounded-full"></span>
            3. Валюта и контроль коммунальных платежей
          </h2>

          <p className="text-gray-700 leading-relaxed">
            Аренда часто оплачивается в евро, а коммунальные счета (электричество EPS, вода, интернет) приходят в динарах. Контролировать их своевременную оплату иностранным жильцом бывает непросто без удобной цифровой системы.
          </p>
        </section>

        {/* Section 4 */}
        <section className="space-y-5 pt-6 border-t border-gray-100" lang="ru">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-brand-blue rounded-full"></span>
            4. Профессиональный подход с цифровым помощником
          </h2>

          <p className="text-gray-700 leading-relaxed">
            Иностранные арендаторы очень ценят конфиденциальность и прозрачность. Вместо бесконечной пересылки фотографий квитанций в WhatsApp, используйте удобную специализированную платформу.
          </p>

          <div className="bg-gradient-to-r from-blue-50 via-white to-green-50 p-6 rounded-2xl border border-gray-200 space-y-4">
            <h3 className="font-bold text-gray-900 text-base flex items-center gap-2">
              <ShieldCheck className="w-5 h-5 text-brand-blue" />
              Преимущества Stanomer для арендодателей:
            </h3>

            <p className="text-sm text-gray-700 leading-relaxed">
              С помощью приложения <strong>Stanomer</strong> вы можете отслеживать все платежи и счета на одном экране. Благодаря архитектуре <strong>local storage</strong>, все ваши финансовые данные и данные ваших жильцов остаются исключительно на вашем устройстве, обеспечивая 100% конфиденциальность.
            </p>

            {/* CTA Box */}
            <div className="pt-4 text-center sm:text-left border-t border-gray-200/60">
              <div className="p-5 rounded-xl bg-brand-blue text-white space-y-3 shadow-lg">
                <p className="font-bold text-sm leading-snug">
                  🌐 Создайте премиальный сервис для иностранных жильцов. Скачайте Stanomer прямо сейчас и контролируйте аренду без стресса.
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
