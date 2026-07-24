import React from "react";
import Metadata from "next";
import { GuideLayout } from "../../../components/GuideLayout";
import { 
  Building, 
  FileText, 
  Receipt, 
  CheckCircle2, 
  Sparkles, 
  Smartphone, 
  ShieldCheck, 
  HelpCircle,
  Zap,
  Lock,
  ArrowRight
} from "lucide-react";

export const metadata = {
  title: "Руководство по аренде квартир в Белграде: От поиска до счетов | Stanomer",
  description: "Руководство по аренде квартир в Белграде: поиск района (Врачар, Нови Белград), договор аренды (Ugovor o zakupu), коммунальные счета (EPS, Infostan) и контроль в Stanomer.",
  keywords: [
    "аренда квартир в белграде",
    "аренда жилья белград",
    "снять квартиру в белграде",
    "apartments for rent in belgrade",
    "izdavanje stanova Beograd",
    "ugovor o zakupu",
    "коммунальные услуги белград",
    "Stanomer"
  ],
  alternates: {
    canonical: "https://www.stanomer.online/guide/belgrade-apartment-rental-guide-ru",
    languages: {
      "tr": "https://www.stanomer.online/guide/belgrad-kiralik-daire-rehberi",
      "en": "https://www.stanomer.online/guide/belgrade-apartment-rental-guide",
      "sr": "https://www.stanomer.online/guide/vodic-za-izdavanje-stanova-beograd",
      "sr-Cyrl": "https://www.stanomer.online/guide/vodic-za-izdavanje-stanova-beograd-cirilica",
      "ru": "https://www.stanomer.online/guide/belgrade-apartment-rental-guide-ru"
    }
  },
  openGraph: {
    title: "Руководство по аренде квартир в Белграде: От поиска до счетов | Stanomer",
    description: "Полный гайд по аренде жилья в Белграде: поиск, договор аренды (Ugovor o zakupu) и оплата коммунальных услуг.",
    url: "https://www.stanomer.online/guide/belgrade-apartment-rental-guide-ru",
    siteName: "Stanomer",
    locale: "ru_RU",
    type: "article",
  },
  twitter: {
    card: "summary",
    title: "Руководство по аренде квартир в Белграде | Stanomer",
    description: "Полный гайд по аренде жилья в Белграде: поиск, договор аренды и коммуналка.",
  }
};

const jsonLd = {
  "@context": "https://schema.org",
  "@type": "Article",
  "headline": "Руководство по аренде квартир в Белграде: От поиска до управления счетами",
  "description": "Руководство по аренде жилья в Белграде для экспатов, цифровых кочевников и студентов. Поиск, договор Ugovor o zakupu и коммуналка.",
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
      "url": "https://www.stanomer.online/assets/logo.png"
    }
  },
  "mainEntityOfPage": "https://www.stanomer.online/guide/belgrade-apartment-rental-guide-ru",
  "datePublished": "2026-07-24",
  "dateModified": "2026-07-24",
  "inLanguage": "ru"
};

export default function RussianGuidePage() {
  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
      />
      <GuideLayout
        currentLang="RU"
        title="Руководство по аренде квартир в Белграде: От поиска до управления счетами"
        subtitle="Если вы планируете переезд в Белград — будь то для учебы, удаленной работы или чтобы сделать этот город своим новым домом — первый вопрос всегда один и тот же: с чего начать?"
        ctaText="Безопасно сохраняйте и отслеживайте арендные платежи и счета в Сербии локально с помощью приложения Stanomer"
        ctaSubtext="Stanomer хранит ваши данные прямо на вашем устройстве (local storage). Ваши финансовые записи не отправляются на облачные серверы и не передаются третьим лицам."
        canonicalUrl="https://www.stanomer.online/guide/belgrade-apartment-rental-guide-ru"
      >
        {/* Lead Paragraph */}
        <div className="space-y-4" lang="ru">
          <p className="text-gray-700 leading-relaxed font-normal">
            Поиск подходящей квартиры (<strong>аренда квартир в Белграде</strong>) не должен быть стрессом. Однако потеря времени на неактуальные объявления, упущенный важный пункт в договоре или незнание того, когда оплачивать первый счет за коммунальные услуги, могут неоправданно усложнить процесс. Это руководство объединяет три важнейших этапа аренды в Белграде — <strong>поиск, заключение договора и управление счетами</strong> — в одном месте для экспатов, цифровых кочевников и студентов.
          </p>
        </div>

        {/* Quick Summary Grid Box */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 my-8" lang="ru">
          <div className="p-4 rounded-xl bg-blue-50/70 border border-blue-100 flex items-start gap-3">
            <Building className="w-5 h-5 text-brand-blue flex-shrink-0 mt-0.5" />
            <div>
              <h4 className="font-bold text-xs text-gray-900 tracking-wider mb-1">1. ПОИСК КВАРТИРЫ</h4>
              <p className="text-xs text-gray-600">Врачар, Нови Белград, Звездара и доски объявлений.</p>
            </div>
          </div>

          <div className="p-4 rounded-xl bg-green-50/70 border border-green-100 flex items-start gap-3">
            <FileText className="w-5 h-5 text-brand-green flex-shrink-0 mt-0.5" />
            <div>
              <h4 className="font-bold text-xs text-gray-900 tracking-wider mb-1">2. ДОГОВОР АРЕНДЫ</h4>
              <p className="text-xs text-gray-600">Ugovor o zakupu: сроки, депозит, нотариус и коммуналка.</p>
            </div>
          </div>

          <div className="p-4 rounded-xl bg-amber-50/70 border border-amber-100 flex items-start gap-3">
            <Receipt className="w-5 h-5 text-amber-600 flex-shrink-0 mt-0.5" />
            <div>
              <h4 className="font-bold text-xs text-gray-900 tracking-wider mb-1">3. УПРАВЛЕНИЕ СЧЕТАМИ</h4>
              <p className="text-xs text-gray-600">EPS электричество, Infostan и интернет без хаоса в мессенджерах.</p>
            </div>
          </div>
        </div>

        {/* Section 1 */}
        <section className="space-y-4 pt-4 border-t border-gray-100" lang="ru">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-brand-blue rounded-full"></span>
            Советы по поиску подходящей квартиры в Белграде
          </h2>

          <p className="text-gray-700 leading-relaxed">
            Рынок аренды в Белграде сильно различается в зависимости от района. <strong>Врачар (Vračar)</strong> и <strong>Стари Град (Stari Grad)</strong> выделяются своей близостью к центру и, соответственно, более высокими ценами. <strong>Нови Белград (Novi Beograd)</strong> популярен среди удаленщиков и молодых специалистов благодаря современному жилому фонду и близости к бизнес-центрам. Для студентов районы <strong>Звездара (Zvezdara)</strong> и <strong>Вождовац (Voždovac)</strong> предлагают отличный баланс цены и доступности кампусов.
          </p>

          <div className="bg-gray-50/80 p-5 rounded-2xl border border-gray-200/80 space-y-3">
            <h3 className="font-bold text-gray-900 text-sm tracking-wide flex items-center gap-2">
              <Sparkles className="w-4 h-4 text-brand-blue" />
              НА ЧТО ОБРАТИТЬ ВНИМАНИЕ ПРИ ПОИСКЕ:
            </h3>

            <ul className="space-y-2 text-sm text-gray-700">
              <li className="flex items-start gap-2.5">
                <CheckCircle2 className="w-4 h-4 text-brand-blue flex-shrink-0 mt-1" />
                <span><strong>Сравнивайте платформы объявлений:</strong> Одна и та же квартира может публиковаться на разных сайтах с разной ценой. Сравните источники, чтобы получить наиболее объективную информацию.</span>
              </li>
              <li className="flex items-start gap-2.5">
                <CheckCircle2 className="w-4 h-4 text-brand-blue flex-shrink-0 mt-1" />
                <span><strong>Использование локальных терминов:</strong> Если вы ищете <i>apartments for rent in Belgrade</i>, большинство сайтов предлагают фильтры на английском. Но использование сербского термина <strong>&quot;izdavanje stanova Beograd&quot;</strong> на местных досках объявлений часто открывает доступ к более широкому выбору квартир напрямую от собственников.</span>
              </li>
              <li className="flex items-start gap-2.5">
                <CheckCircle2 className="w-4 h-4 text-brand-blue flex-shrink-0 mt-1" />
                <span><strong>Условия залога (депозита):</strong> Сразу уточняйте размер залога. Обычно требуется залог в размере 1–2 месяцев аренды; обязательно пропишите условия его возврата в договоре.</span>
              </li>
            </ul>
          </div>
        </section>

        {/* Section 2 */}
        <section className="space-y-4 pt-6 border-t border-gray-100" lang="ru">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-brand-green rounded-full"></span>
            Юридические тонкости: На что обратить внимание в договоре аренды (Ugovor o zakupu)
          </h2>

          <p className="text-gray-700 leading-relaxed">
            В Сербии официальный договор аренды (<strong>Ugovor o zakupu</strong>) защищает как арендодателя, так и арендатора. Перед подписанием обязательно проверьте следующие ключевые пункты:
          </p>

          <div className="space-y-3">
            <div className="p-4 rounded-xl bg-white border border-gray-200 shadow-sm space-y-1">
              <h3 className="font-bold text-gray-900 text-sm flex items-center gap-2">
                <FileText className="w-4 h-4 text-brand-blue" />
                Срок аренды и условия расторжения
              </h3>
              <p className="text-xs text-gray-600 leading-relaxed">
                Уточните, заключается ли договор на определенный или неопределенный срок, а также за сколько дней (обычно 30 дней) необходимо официально предупредить о выезде.
              </p>
            </div>

            <div className="p-4 rounded-xl bg-white border border-gray-200 shadow-sm space-y-1">
              <h3 className="font-bold text-gray-900 text-sm flex items-center gap-2">
                <Receipt className="w-4 h-4 text-brand-green" />
                Оплата коммунальных услуг
              </h3>
              <p className="text-xs text-gray-600 leading-relaxed">
                В договоре должно быть четко прописано, включены ли электричество, вода, отопление и интернет в стоимость аренды. Это самый частый источник недопониманий среди экспатов.
              </p>
            </div>

            <div className="p-4 rounded-xl bg-white border border-gray-200 shadow-sm space-y-1">
              <h3 className="font-bold text-gray-900 text-sm flex items-center gap-2">
                <Lock className="w-4 h-4 text-amber-600" />
                Нотариальное заверение
              </h3>
              <p className="text-xs text-gray-600 leading-relaxed">
                При долгосрочной аренде заверение договора у нотариуса (Javni beležnik) обеспечивает высокую юридическую безопасность для обеих сторон.
              </p>
            </div>
          </div>
        </section>

        {/* Section 3 */}
        <section className="space-y-4 pt-6 border-t border-gray-100" lang="ru">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-amber-500 rounded-full"></span>
            Управление счетами за электричество, воду и интернет
          </h2>

          <p className="text-gray-700 leading-relaxed">
            После подписания договора начинается повседневная рутина: отслеживание и оплата счетов в чужой стране. Счета за электричество (<strong>EPS</strong>), воду (<strong>Infostan</strong>) и интернет обычно приходят отдельно, каждый со своим сроком оплаты. Дополнительная сложность для экспатов — все квитанции приходят на сербском языке.
          </p>

          <p className="text-gray-700 leading-relaxed">
            Когда счета делятся (например, при аренде с соседями) или арендодатель просит подтверждение оплаты, общение часто сводится к хаотичным перепискам в WhatsApp, Viber или Telegram, что ведет к забытым платежам.
          </p>
        </section>

        {/* Section 4 */}
        <section className="space-y-4 pt-6 border-t border-gray-100" lang="ru">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-brand-blue rounded-full"></span>
            Решение: Отслеживайте аренду и счета в одном месте с помощью Stanomer
          </h2>

          <p className="text-gray-700 leading-relaxed">
            Все эти проблемы — потерянные счета, пропущенные сроки оплаты и недопонимания с арендодателем — возникают из-за отсутствия удобной системы. <strong>Stanomer</strong> — это цифровой ассистент, созданный именно для этого.
          </p>

          <div className="bg-blue-50/50 p-6 rounded-2xl border border-blue-100 space-y-4">
            <h3 className="font-bold text-gray-900 text-base">С приложением Stanomer вы сможете:</h3>
            
            <div className="grid grid-cols-1 gap-3">
              <div className="flex items-start gap-3 bg-white p-3.5 rounded-xl border border-blue-100/80 shadow-sm">
                <CheckCircle2 className="w-5 h-5 text-brand-blue flex-shrink-0 mt-0.5" />
                <div>
                  <h4 className="font-bold text-xs text-gray-900 mb-0.5">Фиксируйте каждый платеж по аренде</h4>
                  <p className="text-xs text-gray-600">На одном удобном экране вы видите, что оплачено, а что просрочено.</p>
                </div>
              </div>

              <div className="flex items-start gap-3 bg-white p-3.5 rounded-xl border border-blue-100/80 shadow-sm">
                <CheckCircle2 className="w-5 h-5 text-brand-green flex-shrink-0 mt-0.5" />
                <div>
                  <h4 className="font-bold text-xs text-gray-900 mb-0.5">Единый цифровой архив счетов</h4>
                  <p className="text-xs text-gray-600">Храните счета за электричество, воду и интернет в одном месте. Больше не нужно искать квитанции в истории сообщений.</p>
                </div>
              </div>

              <div className="flex items-start gap-3 bg-white p-3.5 rounded-xl border border-blue-100/80 shadow-sm">
                <ShieldCheck className="w-5 h-5 text-indigo-600 flex-shrink-0 mt-0.5" />
                <div>
                  <h4 className="font-bold text-xs text-gray-900 mb-0.5">100% Конфиденциальность (On-device storage)</h4>
                  <p className="text-xs text-gray-600">Главное преимущество — архитектура безопасности: Stanomer хранит ваши данные прямо на вашем устройстве (local storage). Ваши финансовые записи не отправляются на облачные серверы и не передаются третьим лицам.</p>
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* Section 5: Conclusion */}
        <section className="pt-6 border-t border-gray-100" lang="ru">
          <div className="bg-gradient-to-r from-gray-900 to-slate-900 text-white p-6 sm:p-8 rounded-2xl space-y-4 shadow-xl">
            <h3 className="text-lg font-bold text-white flex items-center gap-2">
              <Zap className="w-5 h-5 text-brand-green" />
              Организуйте свой быт с первого дня в Белграде
            </h3>

            <p className="text-xs sm:text-sm text-gray-300 leading-relaxed">
              Если вы переезжаете в новую квартиру в Белграде, организуйте свой быт с первого дня. Скачайте Stanomer в App Store или Google Play прямо сейчас и переведите управление арендой в цифровой формат.
            </p>

            <div className="pt-2 flex flex-wrap items-center gap-3">
              <a 
                href="/app" 
                className="inline-flex items-center gap-2 bg-brand-blue hover:bg-blue-600 text-white font-semibold text-xs px-4 py-2.5 rounded-lg transition-all shadow-md"
              >
                <Smartphone className="w-4 h-4" />
                <span>Открыть Веб-Приложение</span>
              </a>
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
        </section>
      </GuideLayout>
    </>
  );
}
