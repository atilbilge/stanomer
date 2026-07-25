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
  title: "Договор аренды в Сербии: что должен знать каждый арендодатель | Stanomer",
  description: "Как юридически защитить себя при сдаче квартиры в Сербии? Подробное руководство по условиям договора аренды (ugovor o zakupu), депозиту, счетам Infostan/EPS и приложению Stanomer.",
  keywords: [
    "договор аренды Сербия",
    "ugovor o zakupu stana",
    "аренда квартиры Белград",
    "аренда Нови-Сад",
    "права арендодателя Сербия",
    "счета Infostan EPS",
    "расторжение договора otkazni rok",
    "приложение stanomer"
  ],
  alternates: {
    canonical: "https://www.stanomer.online/guide/serbia-lease-agreement-guide-ru",
    languages: {
      "tr": "https://www.stanomer.online/guide/sirbistan-kira-sozlesmesi-rehberi",
      "en": "https://www.stanomer.online/guide/serbia-lease-agreement-guide",
      "sr": "https://www.stanomer.online/guide/ugovor-o-zakupu-stana-srbija",
      "sr-Cyrl": "https://www.stanomer.online/guide/ugovor-o-zakupu-stana-srbija-cirilica",
      "ru": "https://www.stanomer.online/guide/serbia-lease-agreement-guide-ru",
    }
  },
  openGraph: {
    title: "Договор аренды в Сербии: что должен знать каждый арендодатель | Stanomer",
    description: "Как юридически защитить себя при сдаче квартиры в Сербии? Подробное руководство по договору аренды и депозиту.",
    url: "https://www.stanomer.online/guide/serbia-lease-agreement-guide-ru",
    siteName: "Stanomer",
    locale: "ru_RU",
    type: "article",
  }
};

const jsonLd = {
  "@context": "https://schema.org",
  "@type": "Article",
  "headline": "Договор аренды в Сербии: что должен знать каждый арендодатель",
  "description": "Как юридически защитить себя при сдаче квартиры в Сербии? Подробное руководство по условиям договора аренды, депозиту и управлению недвижимостью.",
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
  "mainEntityOfPage": "https://www.stanomer.online/guide/serbia-lease-agreement-guide-ru",
  "inLanguage": "ru"
};

export default function LeaseAgreementRussianGuidePage() {
  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
      />
      <GuideLayout
        currentLang="RU"
        categoryTitle="Юридический Гайд"
        locationName="Сербия"
        title="Договор аренды в Сербии: что должен знать каждый арендодатель"
        subtitle="Как юридически защитить себя при сдаче квартиры в Сербии? Подробное руководство по условиям договора аренды, депозиту и управлению недвижимостью."
        ctaText="Управляйте договорами аренды и процессами без ошибок в Stanomer"
        ctaSubtext="Отслеживайте ежемесячные платежи, счета и даты продления договоров благодаря 100% local storage хранению на вашем устройстве."
        canonicalUrl="https://www.stanomer.online/guide/serbia-lease-agreement-guide-ru"
      >
        {/* Intro */}
        <div className="space-y-4" lang="ru">
          <p className="text-gray-700 leading-relaxed">
            Рынок недвижимости в Сербии, особенно в <strong>Белграде</strong> и <strong>Нови-Саде</strong>, продолжает стремительно расти. Хотя это открывает отличные возможности для арендодателей, отсутствие юридической и организационной базы может привести к серьезным проблемам.
          </p>
          <p className="text-gray-700 leading-relaxed">
            Первый шаг к успешному управлению недвижимостью — это надежный договор аренды (на сербском <strong>ugovor o zakupu stana</strong>), защищающий права обеих сторон.
          </p>
        </div>

        {/* Quick Highlights Box */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 my-8" lang="ru">
          <div className="p-4 rounded-xl bg-blue-50/70 border border-blue-100 flex items-start gap-3">
            <Scale className="w-5 h-5 text-brand-blue flex-shrink-0 mt-0.5" />
            <div>
              <h4 className="font-bold text-xs text-gray-900 tracking-wider mb-1">1. ОБЯЗАТЕЛЬНЫЕ ПУНКТЫ</h4>
              <p className="text-xs text-gray-600">Паспортные данные / JMBG, валюта оплаты и условия срока действия.</p>
            </div>
          </div>

          <div className="p-4 rounded-xl bg-green-50/70 border border-green-100 flex items-start gap-3">
            <Receipt className="w-5 h-5 text-brand-green flex-shrink-0 mt-0.5" />
            <div>
              <h4 className="font-bold text-xs text-gray-900 tracking-wider mb-1">2. ДЕПОЗИТ И СЧЕТА</h4>
              <p className="text-xs text-gray-600">Распределение коммунальных услуг (Infostan, EPS) и акт передачи имущества.</p>
            </div>
          </div>

          <div className="p-4 rounded-xl bg-amber-50/70 border border-amber-100 flex items-start gap-3">
            <Clock className="w-5 h-5 text-amber-600 flex-shrink-0 mt-0.5" />
            <div>
              <h4 className="font-bold text-xs text-gray-900 tracking-wider mb-1">3. СРОК УВЕДОМЛЕНИЯ</h4>
              <p className="text-xs text-gray-600">Стандартные 30 дней (otkazni rok) и контроль без Excel в Stanomer.</p>
            </div>
          </div>
        </div>

        {/* Section 1 */}
        <section className="space-y-4 pt-4 border-t border-gray-100" lang="ru">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-brand-blue rounded-full"></span>
            1. Обязательные пункты договора аренды
          </h2>

          <p className="text-gray-700 leading-relaxed">
            Чем четче составлен договор, тем ниже риск возникновения споров в будущем. Согласно законодательству Сербии, действительный договор должен содержать:
          </p>

          <div className="bg-gray-50/80 p-5 rounded-2xl border border-gray-200/80 space-y-3">
            <ul className="space-y-3 text-sm text-gray-700">
              <li className="flex items-start gap-2.5">
                <CheckCircle2 className="w-4 h-4 text-brand-blue flex-shrink-0 mt-1" />
                <span><strong>Идентификационные данные:</strong> Номера паспортов или <strong>JMBG</strong> (личный идентификационный номер) арендатора и арендодателя.</span>
              </li>
              <li className="flex items-start gap-2.5">
                <CheckCircle2 className="w-4 h-4 text-brand-blue flex-shrink-0 mt-1" />
                <span><strong>Сумма и дата оплаты:</strong> Некоторые договариваются об оплате в евро, другие в динарах. Из-за курсовой разницы валюта и точный день ежемесячной оплаты должны быть четко зафиксированы.</span>
              </li>
              <li className="flex items-start gap-2.5">
                <CheckCircle2 className="w-4 h-4 text-brand-blue flex-shrink-0 mt-1" />
                <span><strong>Срок действия:</strong> Условия для срочных (например, на 1 год) или бессрочных договоров.</span>
              </li>
            </ul>
          </div>
        </section>

        {/* Section 2 */}
        <section className="space-y-4 pt-6 border-t border-gray-100" lang="ru">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-brand-green rounded-full"></span>
            2. Депозит и коммунальные платежи
          </h2>

          <p className="text-gray-700 leading-relaxed">
            Разногласия чаще всего возникают из-за неоплаченных счетов и возврата депозита.
          </p>

          <div className="p-5 rounded-2xl bg-green-50/60 border border-green-200/70 space-y-3">
            <h3 className="font-bold text-gray-900 text-sm flex items-center gap-2 text-green-900">
              <Sparkles className="w-4 h-4 text-brand-green" />
              Распределение ответственности и Акт приемки:
            </h3>

            <p className="text-sm text-gray-700 leading-relaxed">
              В договоре должно быть четко указано, кто оплачивает <strong>Infostan</strong> (отопление и коммунальные услуги дома), электричество (<strong>EPS</strong>) и интернет. Также необходимо прописать условия удержания депозита (обычно в размере одной месячной арендной платы) и приложить акт приема-передачи имущества.
            </p>
          </div>
        </section>

        {/* Section 3 */}
        <section className="space-y-4 pt-6 border-t border-gray-100" lang="ru">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-amber-500 rounded-full"></span>
            3. Уведомление о расторжении (Otkazni Rok)
          </h2>

          <p className="text-gray-700 leading-relaxed">
            Если арендатор хочет досрочно расторгнуть договор или просрочивает платежи, стандартный срок уведомления (на сербском <strong>otkazni rok</strong>) обычно составляет <strong>30 дней</strong> в письменной форме.
          </p>
        </section>

        {/* Section 4 */}
        <section className="space-y-5 pt-6 border-t border-gray-100" lang="ru">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="w-2 h-7 bg-brand-blue rounded-full"></span>
            4. Управляйте процессами без ошибок с вашим цифровым помощником
          </h2>

          <p className="text-gray-700 leading-relaxed">
            Самая главная работа начинается после подписания: отслеживание арендных платежей, проверка счетов и напоминание о датах продления. Если у вас несколько объектов, ведение записей в Excel или на бумаге увеличивает риск ошибок.
          </p>

          <div className="bg-gradient-to-r from-blue-50 via-white to-green-50 p-6 rounded-2xl border border-gray-200 space-y-4">
            <h3 className="font-bold text-gray-900 text-base flex items-center gap-2">
              <ShieldCheck className="w-5 h-5 text-brand-blue" />
              Профессиональное управление с Stanomer:
            </h3>

            <p className="text-sm text-gray-700 leading-relaxed">
              С помощью приложения <strong>Stanomer</strong> вы можете профессионально отслеживать циклы аренды и счета. Благодаря архитектуре <strong>local storage</strong>, все ваши данные хранятся только на вашем устройстве, а не на облачных серверах, обеспечивая 100% конфиденциальность.
            </p>

            {/* CTA Box */}
            <div className="pt-4 text-center sm:text-left border-t border-gray-200/60">
              <div className="p-5 rounded-xl bg-brand-blue text-white space-y-3 shadow-lg">
                <p className="font-bold text-sm leading-snug">
                  📝 Оцифруйте ваши договоры и учет. Скачайте Stanomer прямо сейчас и ведите аренду в Сербии без стресса.
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
