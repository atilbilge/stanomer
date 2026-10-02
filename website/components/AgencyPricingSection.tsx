"use client";

import React, { useState, useMemo } from "react";
import { useLanguage, Language } from "./LanguageProvider";
import { Sparkles, HelpCircle, CheckCircle2, ArrowRight, Calculator } from "lucide-react";

interface AgencyPricingSectionProps {
  onOpenSimulation?: () => void;
}

const BRACKETS = [
  { max: 10, price: 6.0 },
  { max: 20, price: 3.5 },
  { max: 45, price: 2.5 },
  { max: 1e9, price: 1.5 },
];

interface TranslationBundle {
  badge: string;
  h1: string;
  lead: string;
  count: string;
  std: string;
  fnd: string;
  pm: string;
  h2std: string;
  th1: string;
  th2: string;
  ex: string;
  h2f: string;
  fintro: string;
  get: string;
  ask: string;
  g1: string;
  g2: string;
  g3: string;
  a1: string;
  a2: string;
  a3: string;
  a4: string;
  crit: string;
  rem: string;
  conf: string;
  h2q: string;
  q1: string;
  r1: string;
  q2: string;
  r2: string;
  q3: string;
  r3: string;
  h2c: string;
  pc: string;
  btn: string;
  m1: string;
  m2: string;
  m3: string;
  m4: string;
  m5: string;
  rates: [string, string, string, string, string];
  s1: string;
  s2: string;
  s3: string;
  s4: string;
  s5: string;
  r4: string;
  rows: [string, string, string, string];
  lg: string;
}

const T: Record<string, TranslationBundle> = {
  en: {
    badge: "Transparent Agency Pricing",
    h1: "Pay only for the properties you manage",
    lead: "Price depends on the number of properties and is calculated in brackets. Each bracket applies only to the properties inside it, so adding properties never lowers your total bill.",
    count: "Properties you manage",
    std: "Standard price",
    fnd: "Founding partner, months 2 to 12",
    pm: "EUR per month",
    h2std: "Standard price",
    th1: "Properties",
    th2: "Price per property per month (EUR)",
    ex: "Example: 20 properties = (10 × 6.00) + (10 × 3.50) = 95.00 EUR per month.",
    h2f: "Founding feedback partners",
    fintro: "Agencies that sign up by December 31, 2026 receive:",
    get: "What you get",
    ask: "What we ask in return",
    g1: "A free pilot month with no obligations",
    g2: "40% off for months 2 to 12, then 20% off for months 13 to 24 and 10% off for months 25 to 36 if the feedback cycle continues",
    g3: "Early access: selected new features reach founding partners first, before general availability. Beta features can be switched on or off per agency, and your live data is never moved to a beta feature without your confirmation.",
    a1: "One 20-minute feedback call within your first 60 days",
    a2: "A short written note after the pilot month",
    a3: "One 15-minute call or short written note per quarter",
    a4: "For each early-access feature you enable, tell us within 14 days how it worked, or tell us you are skipping that release",
    crit: "Your feedback can be critical; the discount does not depend on it being positive. With your permission, we may quote it.",
    rem: "If a quarter passes without feedback, we send a reminder and you have 30 days to catch up. After that, standard pricing applies for the following months.",
    conf: "We confirm the terms for months 13 to 24 in writing at least 30 days before your first year ends, and for months 25 to 36 at least 30 days before your second year ends.",
    h2q: "Frequently Asked Questions",
    q1: "What does a normal month look like for my agency?",
    r1: "You add a property and its contract, then invite the owner and tenant or add them yourself. The owner uploads a utility bill, you check it and approve it with a due date, and only then does the tenant see it. If the tenant has a complaint, it comes to you instead of going to the owner. Everything runs on web, Android and iOS under your logo and colors.",
    q2: "Does the price drop when I add properties?",
    r2: "No. Each bracket applies only to the properties inside it, so your total only grows as your portfolio grows, and the price per additional property gets lower.",
    q3: "What does the pilot month include?",
    r3: "Full access under your own brand, with no obligations. We can import your existing property Excel files.",
    h2c: "See your own-branded agency panel in 2 minutes",
    pc: "Request a simulation and see the panel with sample data under your agency's name and logo. No sales call needed.",
    btn: "Simulate for Your Agency",
    m1: "Month 1",
    m2: "Months 2 to 12",
    m3: "Months 13 to 24",
    m4: "Months 25 to 36",
    m5: "Month 37 onward",
    rates: ["100%", "40%", "20%", "10%", "0%"],
    s1: "Free pilot",
    s2: "Discount",
    s3: "With feedback",
    s4: "With feedback",
    s5: "Standard price",
    r4: "76 and above",
    rows: ["1 to 10", "11 to 30", "31 to 75", "76 and above"],
    lg: "properties",
  },
  sr_lat: {
    badge: "Transparentan cenovnik za agencije",
    h1: "Plaćate samo nekretnine koje vodite",
    lead: "Cena zavisi od broja nekretnina i računa se po stepenima. Svaki stepen se odnosi samo na nekretnine unutar njega, tako da dodavanje nekretnina nikada ne smanjuje Vaš ukupni račun.",
    count: "Broj nekretnina koje vodite",
    std: "Standardna cena",
    fnd: "Osnivač partner, 2. do 12. meseca",
    pm: "EUR mesečno",
    h2std: "Standardna cena",
    th1: "Broj nekretnina",
    th2: "Cena po nekretnini mesečno (EUR)",
    ex: "Primer: 20 nekretnina = (10 × 6,00) + (10 × 3,50) = 95,00 EUR mesečno.",
    h2f: "Osnivači partneri (povratne informacije)",
    fintro: "Agencije koje se pridruže do 31. decembra 2026. dobijaju:",
    get: "Šta dobijate",
    ask: "Šta tražimo zauzvrat",
    g1: "Besplatan probni mesec bez obaveza",
    g2: "40% popusta od 2. do 12. meseca, zatim 20% popusta od 13. do 24. meseca i 10% popusta od 25. do 36. meseca ako se nastavi razmena povratnih informacija",
    g3: "Rani pristup: izabrane nove funkcije prvo dobijaju osnivači partneri, pre opšte dostupnosti. Beta funkcije mogu se uključiti ili isključiti po agenciji, a Vaši stvarni podaci se nikada ne prebacuju na beta funkciju bez Vaše potvrde.",
    a1: "Jedan razgovor od 20 minuta u prvih 60 dana",
    a2: "Kratku pisanu belešku nakon probnog meseca",
    a3: "Jedan razgovor od 15 minuta ili kratku pisanu belešku kvartalno",
    a4: "Za svaku funkciju ranog pristupa koju uključite, javite nam u roku od 14 dana kako je funkcionisala, ili nam javite da preskačete to izdanje",
    crit: "Vaša ocena može biti i kritična; popust ne zavisi od toga da li je pozitivna. Uz Vašu dozvolu, možemo je citirati.",
    rem: "Ako prođe kvartal bez povratne informacije, šaljemo podsetnik i imate 30 dana da nadoknadite. Posle toga, za naredne mesece važi standardna cena.",
    conf: "Uslove za period od 13. do 24. meseca potvrđujemo pisanim putem najmanje 30 dana pre isteka prve godine, a za period od 25. do 36. meseca najmanje 30 dana pre isteka druge godine.",
    h2q: "Često postavljana pitanja",
    q1: "Kako izgleda običan mesec za moju agenciju?",
    r1: "Dodate nekretninu i ugovor, pa pozovete vlasnika i zakupca ili ih dodate sami. Vlasnik otpremi račun za režije, Vi ga proverite i odobrite sa rokom plaćanja, i tek tada ga zakupac vidi. Ako zakupac ima primedbu, ona stiže Vama, a ne vlasniku. Sve radi na webu, Androidu i iOS-u pod Vašim logom i bojama.",
    q2: "Da li cena pada kada dodam nekretnine?",
    r2: "Ne. Svaki stepen se odnosi samo na nekretnine unutar njega, pa Vaš ukupni račun samo raste kako raste portfelj, dok cena po dodatnoj nekretnini postaje niža.",
    q3: "Šta uključuje probni mesec?",
    r3: "Potpun pristup pod Vašim brendom, bez obaveza. Možemo uvesti Vaše postojeće Excel fajlove sa nekretninama.",
    h2c: "Pogledajte panel pod Vašim brendom za 2 minuta",
    pc: "Zatražite simulaciju i pogledajte panel sa probnim podacima pod imenom i logom Vaše agencije. Bez prodajnog razgovora.",
    btn: "Simulirajte za Vašu agenciju",
    m1: "1. mesec",
    m2: "2. do 12. meseca",
    m3: "13. do 24. meseca",
    m4: "25. do 36. meseca",
    m5: "Od 37. meseca",
    rates: ["100%", "40%", "20%", "10%", "0%"],
    s1: "Besplatan probni mesec",
    s2: "Popust",
    s3: "Uz povratne informacije",
    s4: "Uz povratne informacije",
    s5: "Standardna cena",
    r4: "76 i više",
    rows: ["1 do 10", "11 do 30", "31 do 75", "76 i više"],
    lg: "nekretnina",
  },
  sr_cyr: {
    badge: "Транспарентан ценовник за агенције",
    h1: "Плаћате само некретнине које водите",
    lead: "Цена зависи од броја некретнина и рачуна се по степенима. Сваки степен се односи само на некретнине унутар њега, тако да додавање некретнина никада не смањује Ваш укупни рачун.",
    count: "Број некретнина које водите",
    std: "Стандардна цена",
    fnd: "Оснивач партнер, 2. до 12. месеца",
    pm: "EUR месечно",
    h2std: "Стандардна цена",
    th1: "Број некретнина",
    th2: "Цена по некретнини месечно (EUR)",
    ex: "Пример: 20 некретнина = (10 × 6,00) + (10 × 3,50) = 95,00 EUR месечно.",
    h2f: "Оснивачи партнери (повратне информације)",
    fintro: "Агенције које се придруже до 31. децембра 2026. добијају:",
    get: "Шта добијате",
    ask: "Шта тражимо заузврат",
    g1: "Бесплатан пробни месец без обавеза",
    g2: "40% попуста од 2. до 12. месеца, затим 20% попуста од 13. до 24. месеца и 10% попуста од 25. до 36. месеца ако се настави размена повратних информација",
    g3: "Рани приступ: изабране нове функције прво добијају оснивачи партнери, пре опште доступности. Бета функције могу се укључити или искључити по агенцији, а Ваши стварни подаци се никада не пребацују на бета функцију без Ваше потврде.",
    a1: "Један разговор од 20 минута у првих 60 дана",
    a2: "Кратку писану белешку након пробног месеца",
    a3: "Један разговор од 15 минута или кратку писану белешку квартално",
    a4: "За сваку функцију раног приступа коју укључите, јавите нам у року од 14 дана како је функционисала, или нам јавите да прескачете то издање",
    crit: "Ваша оцена може бити и критична; попуст не зависи од тога да ли је позитивна. Уз Вашу дозволу, можемо је цитирати.",
    rem: "Ако прође квартал без повратне информације, шаљемо подсетник и имате 30 дана да надокнадите. После тога, за наредне месеце важи стандардна цена.",
    conf: "Услове за период од 13. до 24. месеца потврђујемо писаним путем најмање 30 дана пре истека прве године, а за период од 25. до 36. месеца најмање 30 дана пре истека друге године.",
    h2q: "Често постављана питања",
    q1: "Како изгледа обичан месец за моју агенцију?",
    r1: "Додате некретнину и уговор, па позовете власника и закупца или их додате сами. Власник отпреми рачун за режије, Ви га проверите и одобрите са роком плаћања, и тек тада га закупац види. Ако закупац има примедбу, она стиже Вама, а не власнику. Све ради на вебу, Андроиду и иОС-у под Вашим логом и бојама.",
    q2: "Да ли цена пада када додам некретнине?",
    r2: "Не. Сваки степен се односи само на некретнине унутар њега, па Ваш укупни рачун само расте како расте портфељ, док цена по додатној некретнини постаје нижа.",
    q3: "Шта укључује пробни месец?",
    r3: "Потпун приступ под Вашим брендом, без обавеза. Можемо увести Ваше постојеће Екцел фајлове са некретнинама.",
    h2c: "Погледајте панел под Вашим брендом за 2 минута",
    pc: "Затражите симулацију и погледајте панел са пробним подацима под именом и логом Ваше агенције. Без продајног разговора.",
    btn: "Симулирајте за Вашу агенцију",
    m1: "1. месец",
    m2: "2. до 12. месеца",
    m3: "13. до 24. месеца",
    m4: "25. до 36. месеца",
    m5: "Од 37. месеца",
    rates: ["100%", "40%", "20%", "10%", "0%"],
    s1: "Бесплатан пробни месец",
    s2: "Попуст",
    s3: "Уз повратне информације",
    s4: "Уз повратне информације",
    s5: "Стандардна цена",
    r4: "76 и више",
    rows: ["1 до 10", "11 до 30", "31 до 75", "76 и више"],
    lg: "некретнина",
  },
  tr: {
    badge: "Şeffaf Acente Fiyatlandırması",
    h1: "Yalnızca yönettiğiniz mülkler için ödeyin",
    lead: "Fiyat, yönettiğiniz mülk sayısına göre dilimler halinde hesaplanır. Her dilim yalnızca kendi aralığındaki mülklere uygulanır; bu sayede mülk portföyünüz büyüdükçe birim mülk maliyetiniz kademeli olarak düşer.",
    count: "Yönettiğiniz mülk sayısı",
    std: "Standart fiyat",
    fnd: "Kurucu ortak, 2 - 12. aylar",
    pm: "EUR / ay",
    h2std: "Standart fiyat tarifesi",
    th1: "Mülk Dilimi",
    th2: "Mülk başına aylık ücret (EUR)",
    ex: "Örnek: 20 mülk = (10 × 6,00) + (10 × 3,50) = 95,00 EUR / ay.",
    h2f: "Kurucu geri bildirim ortaklığı",
    fintro: "31 Aralık 2026 tarihine kadar kaydolan acentelerin kazandıkları:",
    get: "Ne kazanıyorsunuz?",
    ask: "Karşılığında ne rica ediyoruz?",
    g1: "Hiçbir taahhüt içermeyen 1 aylık ücretsiz pilot kullanım",
    g2: "2 - 12. aylarda %40 indirim; geri bildirim döngüsü sürdükçe 13 - 24. aylarda %20, 25 - 36. aylarda %10 indirim",
    g3: "Erken erişim: Seçilen yeni özellikler genel kullanıma sunulmadan önce ilk olarak kurucu ortaklara açılır. Beta özellikleri acente bazında açılıp kapatılabilir ve canlı verileriniz onayınız olmadan asla beta özelliklerine taşınmaz.",
    a1: "İlk 60 gün içinde 20 dakikalık bir geri bildirim görüşmesi",
    a2: "Pilot ayın ardından kısa bir yazılı değerlendirme",
    a3: "Her çeyrekte 15 dakikalık bir görüşme veya kısa yazılı not",
    a4: "Aktif ettiğiniz her erken erişim özelliği için 14 gün içinde deneyiminizi iletmeniz veya sürümü atladığınızı bildirmeniz",
    crit: "Geri bildirimleriniz eleştirel olabilir; indiriminiz kesinlikle olumlu yorum yapmanıza bağlı değildir. İzniniz dahilinde anonim veya alıntı olarak kullanabiliriz.",
    rem: "Bir çeyrek geri bildirim olmadan geçerse hatırlatma göndeririz ve telafi için 30 gününüz olur. Sonrasında takip eden aylar için standart fiyat geçerli olur.",
    conf: "13 - 24. aylar için koşulları ilk yılınız dolmadan en az 30 gün önce, 25 - 36. aylar için ise ikinci yılınız dolmadan en az 30 gün önce yazılı olarak teyit ederiz.",
    h2q: "Sıkça Sorulan Sorular",
    q1: "Acentem için normal bir ay nasıl işler?",
    r1: "Bir mülk ve sözleşmesini eklersiniz, ardından ev sahibi ve kiracıyı davet eder veya kendiniz eklersiniz. Ev sahibi fatura yükler, siz kontrol edip son ödeme tarihiyle onaylarsınız ve kiracı ancak o zaman görür. Kiracının bir şikayeti/talebi olursa doğrudan ev sahibine gitmek yerine size gelir. Her şey web, Android ve iOS üzerinde kendi logonuz ve renklerinizle çalışır.",
    q2: "Mülk eklediğimde fiyat düşer mi?",
    r2: "Hayır. Her dilim yalnızca kendi içindeki mülklere uygulanır; portföyünüz büyüdükçe toplam faturanız kontrollü artar ancak eklenen her yeni mülkün birim maliyeti kademeli olarak ucuzlar.",
    q3: "Pilot ay neleri kapsar?",
    r3: "Kendi markanız altında hiçbir taahhüt olmadan tam erişim. Mevcut mülk Excel tablolarınızı sisteme ücretsiz aktarabiliriz.",
    h2c: "Kendi markalı acente panelinizi 2 dakikada görün",
    pc: "Simülasyon talep edin, acentenizin adı ve logosuyla hazırlanmış örnek verili paneli canlı görün. Satış araması gerekmez.",
    btn: "Acentenizi Simüle Edin",
    m1: "1. Ay",
    m2: "2 - 12. Aylar",
    m3: "13 - 24. Aylar",
    m4: "25 - 36. Aylar",
    m5: "37. Ay ve sonrası",
    rates: ["%100", "%40", "%20", "%10", "%0"],
    s1: "Ücretsiz pilot",
    s2: "İndirim",
    s3: "Geri bildirimle",
    s4: "Geri bildirimle",
    s5: "Standart fiyat",
    r4: "76 ve üzeri",
    rows: ["1 - 10", "11 - 30", "31 - 75", "76 ve üzeri"],
    lg: "mülk",
  },
  ru: {
    badge: "Прозрачные тарифы для агентств",
    h1: "Оплата только за управляемые объекты",
    lead: "Цена зависит от количества объектов и рассчитывается по ступеням. Каждая ступень применяется только к объектам внутри неё, поэтому добавление объектов снижает среднюю стоимость за единицу.",
    count: "Объектов под управлением",
    std: "Стандартная цена",
    fnd: "Партнёр-основатель, месяцы 2–12",
    pm: "EUR в месяц",
    h2std: "Стандартный тариф",
    th1: "Количество объектов",
    th2: "Цена за объект в месяц (EUR)",
    ex: "Пример: 20 объектов = (10 × 6,00) + (10 × 3,50) = 95,00 EUR в месяц.",
    h2f: "Партнёры-основатели (обратная связь)",
    fintro: "Агентства, подключившиеся до 31 декабря 2026 года, получают:",
    get: "Что вы получаете",
    ask: "Что мы просим взамен",
    g1: "Бесплатный пилотный месяц без обязательств",
    g2: "Скидка 40% со 2 по 12 месяц, затем 20% с 13 по 24 месяц и 10% с 25 по 36 месяц при продолжении обмена отзывами",
    g3: "Ранний доступ: новые функции поступают партнёрам-основателям первыми. Бета-функции можно включать или отключать по выбору.",
    a1: "Один 20-минутный звонок в первые 60 дней",
    a2: "Краткий отзыв после пилотного месяца",
    a3: "Один 15-минутный созвон или короткая заметка в квартал",
    a4: "Для каждой включённой бета-функции отзыв в течение 14 дней",
    crit: "Отзывы могут быть критическими — скидка не зависит от похвалы. С вашего согласия мы можем публиковать цитаты.",
    rem: "Если квартал проходит без связи, мы отправляем напоминание с 30 днями на ответ. После этого действует стандартный тариф.",
    conf: "Условия на 13–24 месяцы подтверждаем письменно минимум за 30 дней до конца первого года.",
    h2q: "Часто задаваемые вопросы",
    q1: "Как выглядит обычный месяц для моего агентства?",
    r1: "Вы добавляете объект и договор, приглашаете собственника и жильца. Собственник загружает счета, вы проверяете и утверждаете их, и только тогда жилец видит оплату. Все вопросы жильца поступают вам, а не собственнику. Всё работает на web, Android и iOS под вашим логотипом.",
    q2: "Снижается ли общая цена при добавлении объектов?",
    r2: "Нет. Ступени применяются последовательно: общая сумма растет с портфелем, но стоимость каждого нового добавленного объекта становится ниже.",
    q3: "Что включает пилотный месяц?",
    r3: "Полный доступ под вашим брендом без обязательств. Мы можем бесплатно импортировать ваши текущие таблицы Excel.",
    h2c: "Увидьте панель вашего агентства за 2 минуты",
    pc: "Запросите симуляцию с демо-данными под именем и логотипом вашей компании. Без навязчивых продаж.",
    btn: "Симуляция для вашего агентства",
    m1: "1-й месяц",
    m2: "2 – 12 месяцы",
    m3: "13 – 24 месяцы",
    m4: "25 – 36 месяцы",
    m5: "С 37-го месяца",
    rates: ["100%", "40%", "20%", "10%", "0%"],
    s1: "Бесплатный пилот",
    s2: "Скидка",
    s3: "С обратной связью",
    s4: "С обратной связью",
    s5: "Стандартный тариф",
    r4: "76 и более",
    rows: ["1 до 10", "11 до 30", "31 до 75", "76 и более"],
    lg: "объектов",
  },
};

export function AgencyPricingSection({ onOpenSimulation }: AgencyPricingSectionProps) {
  const { lang } = useLanguage();
  const [count, setCount] = useState<number>(20);

  // Map Language context to dictionary key
  const tKey = useMemo(() => {
    switch (lang) {
      case "EN":
        return "en";
      case "SR_CYR":
        return "sr_cyr";
      case "TR":
        return "tr";
      case "RU":
        return "ru";
      case "SR_LAT":
      default:
        return "sr_lat";
    }
  }, [lang]);

  const texts = T[tKey] || T.en;

  // Format currency numbers
  const money = (val: number): string => {
    const formatted = val.toFixed(2);
    if (tKey === "en") return formatted;
    return formatted.replace(".", ",");
  };

  // Tier calculation
  const { totalStd, totalFnd, bracketCounts, stepsValues } = useMemo(() => {
    let remainder = count;
    let sum = 0;
    const counts: number[] = [];

    BRACKETS.forEach((bracket) => {
      const c = Math.min(remainder, bracket.max);
      counts.push(c);
      sum += c * bracket.price;
      remainder -= c;
    });

    return {
      totalStd: sum,
      totalFnd: sum * 0.6,
      bracketCounts: counts,
      stepsValues: [0, sum * 0.6, sum * 0.8, sum * 0.9, sum],
    };
  }, [count]);

  const isFoundingActive = useMemo(() => {
    return new Date() < new Date("2027-01-01T00:00:00");
  }, []);

  const handleSimulate = (e: React.MouseEvent) => {
    if (onOpenSimulation) {
      e.preventDefault();
      onOpenSimulation();
    }
  };

  return (
    <section
      id="pricing"
      className="relative py-20 md:py-28 px-4 sm:px-6 lg:px-8 bg-slate-50 border-t border-slate-200/80 scroll-mt-24"
    >
      {/* Anchor alias */}
      <span id="section-pricing" className="sr-only" />

      {/* Background gradients */}
      <div className="absolute top-10 left-1/3 w-96 h-96 bg-blue-400/10 rounded-full blur-3xl pointer-events-none -z-10" />
      <div className="absolute bottom-10 right-1/4 w-96 h-96 bg-emerald-400/10 rounded-full blur-3xl pointer-events-none -z-10" />

      <div className="max-w-4xl mx-auto space-y-12">
        {/* Header */}
        <div className="text-center space-y-4">
          <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-blue-100 text-blue-700 text-xs sm:text-sm font-bold shadow-sm">
            <Calculator className="w-4 h-4 text-blue-600" />
            <span>{texts.badge}</span>
          </div>

          <h2 className="text-3xl sm:text-4xl lg:text-5xl font-extrabold text-slate-900 tracking-tight leading-[1.15]">
            {texts.h1}
          </h2>

          <p className="text-base sm:text-lg text-slate-600 leading-relaxed max-w-2xl mx-auto">
            {texts.lead}
          </p>
        </div>

        {/* Interactive Calculator Card */}
        <div id="pricing-calculator" className="bg-white border border-slate-200/90 rounded-3xl p-6 sm:p-9 shadow-xl shadow-slate-200/50 space-y-6 scroll-mt-28">
          <div className="flex flex-col sm:flex-row sm:items-baseline justify-between gap-2">
            <label htmlFor="property-range-input" className="text-base sm:text-lg font-extrabold text-slate-900 flex items-center gap-2">
              <span>{texts.count}</span>
            </label>
            <div className="flex items-baseline gap-2">
              <span className="font-mono text-3xl sm:text-4xl font-extrabold text-blue-600">
                {count}
              </span>
              <span className="text-sm font-semibold text-slate-500">{texts.lg}</span>
            </div>
          </div>

          {/* Range Slider */}
          <div className="space-y-3">
            <input
              id="property-range-input"
              type="range"
              min="1"
              max="150"
              value={count}
              onChange={(e) => setCount(Number(e.target.value))}
              aria-label={texts.count}
              className="w-full h-3 bg-slate-200 rounded-lg appearance-none cursor-pointer accent-blue-600 transition"
            />

            {/* Segmented Color Bar */}
            <div
              className="flex h-3.5 rounded-full overflow-hidden bg-slate-200 shadow-inner"
              aria-hidden="true"
            >
              {bracketCounts.map((c, i) => {
                const widthPercent = (c / count) * 100;
                const colors = [
                  "bg-[#7fa8dc]",
                  "bg-[#4d83cb]",
                  "bg-[#1a5eb8]",
                  "bg-[#0f3d7a]",
                ];
                return (
                  <div
                    key={i}
                    style={{ width: `${widthPercent}%` }}
                    className={`h-full transition-all duration-150 ${colors[i]}`}
                  />
                );
              })}
            </div>

            {/* Legend */}
            <div className="flex flex-wrap items-center gap-x-4 gap-y-1.5 text-xs sm:text-sm font-medium text-slate-500 pt-1">
              {bracketCounts.map((c, i) => {
                if (!c) return null;
                const dotColors = [
                  "bg-[#7fa8dc]",
                  "bg-[#4d83cb]",
                  "bg-[#1a5eb8]",
                  "bg-[#0f3d7a]",
                ];
                return (
                  <span key={i} className="inline-flex items-center gap-1.5">
                    <span className={`w-2.5 h-2.5 rounded-full ${dotColors[i]}`} />
                    <span className="font-mono font-semibold text-slate-700">
                      {c} × €{money(BRACKETS[i].price)}
                    </span>
                  </span>
                );
              })}
            </div>
          </div>

          {/* Totals Summary */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-6 pt-6 border-t border-slate-100">
            <div className="p-4 rounded-2xl bg-slate-50 border border-slate-200/60">
              <span className="block text-xs sm:text-sm font-bold text-slate-500 mb-1">
                {texts.std}
              </span>
              <div className="flex items-baseline gap-2">
                <span className="font-mono text-3xl sm:text-4xl font-extrabold text-slate-900">
                  €{money(totalStd)}
                </span>
                <span className="text-xs text-slate-500">{texts.pm}</span>
              </div>
            </div>

            {isFoundingActive && (
              <a
                href="#founding-partners"
                onClick={(e) => {
                  e.preventDefault();
                  const el = document.getElementById("founding-partners");
                  if (el) {
                    el.scrollIntoView({ behavior: "smooth" });
                    window.history.pushState(null, "", "#founding-partners");
                  }
                }}
                className="group/fnd p-4 rounded-2xl bg-emerald-50/80 border-2 border-emerald-200 hover:border-emerald-400 hover:bg-emerald-100/40 hover:shadow-lg transition-all cursor-pointer block text-left"
              >
                <div className="flex items-center justify-between mb-1">
                  <span className="text-xs sm:text-sm font-bold text-emerald-800 flex items-center gap-1.5">
                    <Sparkles className="w-3.5 h-3.5 text-emerald-600 group-hover/fnd:scale-110 transition-transform" />
                    {texts.fnd}
                  </span>
                  <span className="text-[11px] font-bold text-emerald-700 bg-emerald-100/90 px-2 py-0.5 rounded-full group-hover/fnd:bg-emerald-600 group-hover/fnd:text-white transition-colors flex items-center gap-1">
                    <span>
                      {tKey === "tr"
                        ? "Detaylar"
                        : tKey === "sr_lat"
                        ? "Detalji"
                        : tKey === "sr_cyr"
                        ? "Детаљи"
                        : tKey === "ru"
                        ? "Подробнее"
                        : "Details"}
                    </span>
                    <ArrowRight className="w-3 h-3 group-hover/fnd:translate-x-0.5 transition-transform" />
                  </span>
                </div>
                <div className="flex items-baseline gap-2">
                  <span className="font-mono text-3xl sm:text-4xl font-extrabold text-emerald-700">
                    €{money(totalFnd)}
                  </span>
                  <span className="text-xs text-emerald-700 font-semibold">{texts.pm}</span>
                </div>
              </a>
            )}
          </div>
        </div>

        {/* Standard Brackets Table */}
        <div className="bg-white border border-slate-200/90 rounded-3xl p-6 sm:p-8 shadow-sm space-y-4">
          <h3 className="text-xl font-bold text-slate-900">{texts.h2std}</h3>
          
          <div className="overflow-x-auto rounded-2xl border border-slate-200">
            <table className="w-full text-sm sm:text-base border-collapse">
              <thead>
                <tr className="bg-slate-100/80 text-slate-800 font-extrabold border-b border-slate-200">
                  <th className="py-3 px-4 text-left font-bold">{texts.th1}</th>
                  <th className="py-3 px-4 text-right font-bold">{texts.th2}</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {texts.rows.map((rowName, idx) => (
                  <tr key={idx} className="hover:bg-slate-50/80 transition-colors">
                    <td className="py-3.5 px-4 font-semibold text-slate-700">{rowName}</td>
                    <td className="py-3.5 px-4 text-right font-mono font-bold text-blue-600">
                      €{money(BRACKETS[idx].price)}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <p className="text-xs sm:text-sm text-slate-500 italic pt-1">{texts.ex}</p>
        </div>

        {/* Founding Partners Section */}
        {isFoundingActive && (
          <div
            id="founding-partners"
            className="scroll-mt-28 bg-gradient-to-br from-emerald-500/10 via-white to-blue-500/10 border-2 border-emerald-300/80 rounded-3xl p-6 sm:p-9 shadow-lg space-y-8"
          >
            {/* Anchor aliases */}
            <span id="founding-feedback-partners" className="sr-only" />

            <div className="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-4">
              <div className="space-y-2">
                <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-emerald-100 text-emerald-800 text-xs font-bold tracking-wide">
                  <Sparkles className="w-3.5 h-3.5 text-emerald-600" />
                  <span>31.12.2026</span>
                </div>
                <h3 className="text-2xl sm:text-3xl font-extrabold text-slate-900">
                  {texts.h2f}
                </h3>
                <p className="text-slate-600 text-sm sm:text-base">{texts.fintro}</p>
              </div>

              <a
                href="#pricing-calculator"
                onClick={(e) => {
                  e.preventDefault();
                  const el = document.getElementById("pricing-calculator") || document.getElementById("pricing");
                  if (el) {
                    el.scrollIntoView({ behavior: "smooth" });
                    window.history.pushState(null, "", "#pricing-calculator");
                  }
                }}
                className="group inline-flex items-center gap-2 px-3.5 py-2 rounded-xl bg-white hover:bg-emerald-50 text-emerald-800 border border-emerald-300 hover:border-emerald-500 text-xs sm:text-sm font-bold shadow-sm hover:shadow transition-all cursor-pointer self-start sm:self-auto flex-shrink-0"
              >
                <Calculator className="w-4 h-4 text-emerald-600 group-hover:scale-110 transition-transform" />
                <span>
                  {tKey === "tr"
                    ? "Fiyat Hesabına Git ↑"
                    : tKey === "sr_lat"
                    ? "Idi na kalkulator cena ↑"
                    : tKey === "sr_cyr"
                    ? "Иди на калкулатор цена ↑"
                    : tKey === "ru"
                    ? "Перейти к калькулятору тарифа ↑"
                    : "Go to Price Calculator ↑"}
                </span>
              </a>
            </div>

            {/* 5-Step Lifecycle Progression (Discount Rates Only) */}
            <div className="grid grid-cols-2 sm:grid-cols-5 gap-3">
              {[texts.m1, texts.m2, texts.m3, texts.m4, texts.m5].map((monthLabel, i) => {
                const subLabels = [texts.s1, texts.s2, texts.s3, texts.s4, texts.s5];
                const isPromo = i === 1; // Month 2 to 12
                return (
                  <div
                    key={i}
                    className={`p-3.5 rounded-2xl border text-center transition-all ${
                      isPromo
                        ? "bg-emerald-600 text-white border-emerald-600 shadow-md scale-[1.02]"
                        : "bg-white border-slate-200/80 text-slate-800"
                    } ${i === 4 ? "col-span-2 sm:col-span-1" : ""}`}
                  >
                    <span
                      className={`block text-[11px] font-bold uppercase tracking-wider mb-1 ${
                        isPromo ? "text-emerald-100" : "text-slate-400"
                      }`}
                    >
                      {monthLabel}
                    </span>
                    <span
                      className={`block font-mono text-xl sm:text-2xl font-extrabold ${
                        isPromo ? "text-white" : "text-slate-900"
                      }`}
                    >
                      {texts.rates[i]}
                    </span>
                    <span
                      className={`block text-xs font-medium mt-1 leading-snug ${
                        isPromo ? "text-emerald-100 font-semibold" : "text-slate-500"
                      }`}
                    >
                      {subLabels[i]}
                    </span>
                  </div>
                );
              })}
            </div>

            {/* What You Get vs What We Ask */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6 pt-2">
              <div className="bg-white/80 backdrop-blur-sm p-6 rounded-2xl border border-slate-200 space-y-4">
                <h4 className="text-base font-extrabold text-slate-900 flex items-center gap-2">
                  <CheckCircle2 className="w-5 h-5 text-emerald-600" />
                  <span>{texts.get}</span>
                </h4>
                <ul className="space-y-3 text-xs sm:text-sm text-slate-600 leading-relaxed">
                  <li className="flex items-start gap-2">
                    <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 mt-1.5 flex-shrink-0" />
                    <span>{texts.g1}</span>
                  </li>
                  <li className="flex items-start gap-2">
                    <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 mt-1.5 flex-shrink-0" />
                    <span>{texts.g2}</span>
                  </li>
                  <li className="flex items-start gap-2">
                    <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 mt-1.5 flex-shrink-0" />
                    <span>{texts.g3}</span>
                  </li>
                </ul>
              </div>

              <div className="bg-white/80 backdrop-blur-sm p-6 rounded-2xl border border-slate-200 space-y-4">
                <h4 className="text-base font-extrabold text-slate-900 flex items-center gap-2">
                  <HelpCircle className="w-5 h-5 text-blue-600" />
                  <span>{texts.ask}</span>
                </h4>
                <ul className="space-y-3 text-xs sm:text-sm text-slate-600 leading-relaxed">
                  <li className="flex items-start gap-2">
                    <span className="w-1.5 h-1.5 rounded-full bg-blue-500 mt-1.5 flex-shrink-0" />
                    <span>{texts.a1}</span>
                  </li>
                  <li className="flex items-start gap-2">
                    <span className="w-1.5 h-1.5 rounded-full bg-blue-500 mt-1.5 flex-shrink-0" />
                    <span>{texts.a2}</span>
                  </li>
                  <li className="flex items-start gap-2">
                    <span className="w-1.5 h-1.5 rounded-full bg-blue-500 mt-1.5 flex-shrink-0" />
                    <span>{texts.a3}</span>
                  </li>
                  <li className="flex items-start gap-2">
                    <span className="w-1.5 h-1.5 rounded-full bg-blue-500 mt-1.5 flex-shrink-0" />
                    <span>{texts.a4}</span>
                  </li>
                </ul>
              </div>
            </div>

            {/* Critical callout */}
            <div className="border-l-4 border-amber-500 bg-amber-50/80 p-4 sm:p-5 rounded-r-2xl">
              <p className="text-xs sm:text-sm font-medium text-amber-900 leading-relaxed">
                {texts.crit}
              </p>
            </div>

            <div className="space-y-2 text-xs sm:text-sm text-slate-500 leading-relaxed">
              <p>{texts.rem}</p>
              <p>{texts.conf}</p>
            </div>

            {/* Bottom Back Link to Calculator */}
            <div className="pt-2 border-t border-emerald-200/60 flex justify-start">
              <a
                href="#pricing-calculator"
                onClick={(e) => {
                  e.preventDefault();
                  const el = document.getElementById("pricing-calculator") || document.getElementById("pricing");
                  if (el) {
                    el.scrollIntoView({ behavior: "smooth" });
                    window.history.pushState(null, "", "#pricing-calculator");
                  }
                }}
                className="inline-flex items-center gap-2 text-xs sm:text-sm font-bold text-emerald-700 hover:text-emerald-900 underline underline-offset-4 decoration-emerald-300 hover:decoration-emerald-600 transition-colors cursor-pointer"
              >
                <Calculator className="w-4 h-4 text-emerald-600" />
                <span>
                  {tKey === "tr"
                    ? "Yukarı çıkıp portföyünüze göre fiyatı hesaplayın ↑"
                    : tKey === "sr_lat"
                    ? "Izračunajte cenu za Vaš portfelj iznad ↑"
                    : tKey === "sr_cyr"
                    ? "Израчунајте цену за Ваш портфељ изнад ↑"
                    : tKey === "ru"
                    ? "Рассчитать стоимость для вашего портфеля выше ↑"
                    : "Calculate pricing for your portfolio above ↑"}
                </span>
              </a>
            </div>
          </div>
        )}

        {/* FAQ Accordions */}
        <div className="space-y-4 pt-4">
          <h3 className="text-2xl font-extrabold text-slate-900 text-center sm:text-left">
            {texts.h2q}
          </h3>

          <div className="space-y-3">
            {[
              { q: texts.q1, a: texts.r1 },
              { q: texts.q2, a: texts.r2 },
              { q: texts.q3, a: texts.r3 },
            ].map((faq, idx) => (
              <details
                key={idx}
                className="group bg-white border border-slate-200/90 rounded-2xl p-5 open:shadow-md transition-all cursor-pointer"
              >
                <summary className="font-extrabold text-slate-900 text-base sm:text-lg flex justify-between items-center list-none select-none">
                  <span>{faq.q}</span>
                  <span className="text-slate-400 group-open:rotate-180 transition-transform text-xl font-mono">
                    ▾
                  </span>
                </summary>
                <p className="mt-3 text-sm sm:text-base text-slate-600 leading-relaxed border-t border-slate-100 pt-3">
                  {faq.a}
                </p>
              </details>
            ))}
          </div>
        </div>

        {/* CTA Bar */}
        <div className="bg-gradient-to-r from-blue-900 to-indigo-950 text-white rounded-3xl p-8 sm:p-12 shadow-2xl space-y-6 text-center sm:text-left sm:flex sm:items-center sm:justify-between sm:space-y-0 gap-6">
          <div className="space-y-2 max-w-xl">
            <h3 className="text-2xl sm:text-3xl font-extrabold tracking-tight">
              {texts.h2c}
            </h3>
            <p className="text-sm sm:text-base text-blue-100/90 leading-relaxed">
              {texts.pc}
            </p>
          </div>

          <div className="flex-shrink-0">
            <button
              type="button"
              onClick={handleSimulate}
              className="inline-flex justify-center items-center gap-2.5 px-7 py-4 rounded-xl text-slate-900 bg-white hover:bg-slate-100 font-bold text-base shadow-xl transition-all transform hover:-translate-y-0.5 active:translate-y-0 cursor-pointer"
            >
              <span>{texts.btn}</span>
              <ArrowRight className="w-5 h-5 text-blue-600" />
            </button>
          </div>
        </div>
      </div>
    </section>
  );
}
