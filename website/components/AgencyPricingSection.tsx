"use client";

import React, { useState, useMemo } from "react";
import { useLanguage } from "./LanguageProvider";
import { Sparkles, HelpCircle, CheckCircle2, ArrowRight, Calculator, Globe, Home, Check, Tag } from "lucide-react";

interface AgencyPricingSectionProps {
  onOpenSimulation?: () => void;
}

const BRACKETS = [
  { max: 10, price: 6.0 },
  { max: 20, price: 3.5 },
  { max: 45, price: 2.5 },
  { max: 1e9, price: 1.5 },
];

const BUNDLE_DISCOUNT_RATE = 0.2;

interface TranslationBundle {
  badge: string;
  h1: string;
  lead: string;
  selectModules: string;
  modPortfolio: string;
  modPortfolioSub: string;
  modProperty: string;
  modPropertySub: string;
  bundleBadge: string;
  bundleActiveNote: string;
  bundleUpsellNote: string;
  listingsLabel: string;
  propertiesLabel: string;
  listingsUnit: string;
  propertiesUnit: string;
  totalUnitsLabel: string;
  totalUnitsUnit: string;
  beforeBundle: string;
  bundleSavings: string;
  std: string;
  fnd: string;
  pm: string;
  h2std: string;
  th1: string;
  th2: string;
  ex: string;
  exBundle: string;
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
  details: string;
  goToCalc: string;
  calcAbove: string;
}

const T: Record<string, TranslationBundle> = {
  en: {
    badge: "Transparent Agency Pricing",
    h1: "Pay only for the modules and units you use",
    lead: "Pick Portfolio & Distribution, Property & Lease Management, or both. Pricing is calculated in progressive brackets — and combining both modules pools your units with an extra 20% bundle discount.",
    selectModules: "Choose your modules",
    modPortfolio: "Portfolio & Distribution",
    modPortfolioSub: "Billed by active listings",
    modProperty: "Property & Lease Management",
    modPropertySub: "Billed by managed properties",
    bundleBadge: "-20% Bundle",
    bundleActiveNote: "Both modules active: listings + managed properties are combined into one bracket total with an extra 20% bundle discount applied.",
    bundleUpsellNote: "Select both modules together to pool your units and unlock 20% off your total.",
    listingsLabel: "Active listings",
    propertiesLabel: "Managed properties",
    listingsUnit: "listings",
    propertiesUnit: "properties",
    totalUnitsLabel: "Combined billable volume",
    totalUnitsUnit: "total units",
    beforeBundle: "Before 20% bundle discount",
    bundleSavings: "20% bundle savings",
    std: "Standard price",
    fnd: "Founding partner, months 2 to 12",
    pm: "EUR per month",
    h2std: "Standard progressive brackets",
    th1: "Units (Listings / Managed Properties)",
    th2: "Price per unit per month (EUR)",
    ex: "Example (single module): 20 units = (10 × 6.00) + (10 × 3.50) = 95.00 EUR per month.",
    exBundle: "Example (both modules): 15 listings + 15 managed properties = 30 combined units (130.00 EUR) − 20% bundle discount = 104.00 EUR per month.",
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
    q2: "Does the price drop when I add units?",
    r2: "No. Each bracket applies only to the units inside it, so your total only grows as your portfolio grows, and the price per additional unit gets lower.",
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
    details: "Details",
    goToCalc: "Go to Price Calculator ↑",
    calcAbove: "Calculate pricing for your portfolio above ↑",
  },
  sr_lat: {
    badge: "Transparentan cenovnik za agencije",
    h1: "Plaćate samo module i jedinice koje koristite",
    lead: "Izaberite Portfelj i distribuciju, Upravljanje nekretninama i zakupom ili oba modula. Cena se računa po stepenima — a uz oba modula zajedno dobijate zbirni obračun i dodatnih 20% paketnog popusta.",
    selectModules: "Izaberite module",
    modPortfolio: "Portfelj i distribucija",
    modPortfolioSub: "Obračun po broju aktivnih oglasa",
    modProperty: "Upravljanje nekretninama i zakupom",
    modPropertySub: "Obračun po broju upravljanih nekretnina",
    bundleBadge: "-20% Paket",
    bundleActiveNote: "Oba modula aktivna: oglasi + upravljane nekretnine se sabiraju u jedinstven stepenasti obračun uz dodatnih 20% popusta.",
    bundleUpsellNote: "Izaberite oba modula zajedno za zbirni obračun i 20% paketnog popusta na ukupan iznos.",
    listingsLabel: "Aktivni oglasi",
    propertiesLabel: "Upravljane nekretnine",
    listingsUnit: "oglasa",
    propertiesUnit: "nekretnina",
    totalUnitsLabel: "Ukupan obim za obračun",
    totalUnitsUnit: "jedinica ukupno",
    beforeBundle: "Pre 20% paketnog popusta",
    bundleSavings: "Ušteda paketom (20%)",
    std: "Standardna cena",
    fnd: "Osnivač partner, 2. do 12. meseca",
    pm: "EUR mesečno",
    h2std: "Standardna stepenasta tarifa",
    th1: "Jedinice (Oglasi / Upravljane nekretnine)",
    th2: "Cena po jedinici mesečno (EUR)",
    ex: "Primer (jedan modul): 20 jedinica = (10 × 6,00) + (10 × 3,50) = 95,00 EUR mesečno.",
    exBundle: "Primer (oba modula): 15 oglasa + 15 upravljanih nekretnina = 30 jedinica (130,00 EUR) − 20% popusta = 104,00 EUR mesečno.",
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
    q2: "Da li cena pada kada dodam jedinice?",
    r2: "Ne. Svaki stepen se odnosi samo na jedinice unutar njega, pa Vaš ukupni račun samo raste kako raste portfelj, dok cena po dodatnoj jedinici postaje niža.",
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
    details: "Detalji",
    goToCalc: "Idi na kalkulator cena ↑",
    calcAbove: "Izračunajte cenu za Vaš portfelj iznad ↑",
  },
  sr_cyr: {
    badge: "Транспарентан ценовник за агенције",
    h1: "Плаћате само модуле и јединице које користите",
    lead: "Изаберите Портфељ и дистрибуцију, Управљање некретнинама и закупом или оба модула. Цена се рачуна по степенима — а уз оба модула заједно добијате збирни обрачун и додатних 20% пакетног попуста.",
    selectModules: "Изаберите модуле",
    modPortfolio: "Портфељ и дистрибуција",
    modPortfolioSub: "Обрачун по броју активних огласа",
    modProperty: "Управљање некретнинама и закупом",
    modPropertySub: "Обрачун по броју управљаних некретнина",
    bundleBadge: "-20% Пакет",
    bundleActiveNote: "Оба модула активна: огласи + управљане некретнине се сабирају у јединствен степенасти обрачун уз додатних 20% попуста.",
    bundleUpsellNote: "Изаберите оба модула заједно за збирни обрачун и 20% пакетног попуста на укупан износ.",
    listingsLabel: "Активни огласи",
    propertiesLabel: "Управљане некретнине",
    listingsUnit: "огласа",
    propertiesUnit: "некретнина",
    totalUnitsLabel: "Укупан обим за обрачун",
    totalUnitsUnit: "јединица укупно",
    beforeBundle: "Пре 20% пакетног попуста",
    bundleSavings: "Уштеда пакетом (20%)",
    std: "Стандардна цена",
    fnd: "Оснивач партнер, 2. до 12. месеца",
    pm: "EUR месечно",
    h2std: "Стандардна степенаста тарифа",
    th1: "Јединице (Огласи / Управљане некретнине)",
    th2: "Цена по јединици месечно (EUR)",
    ex: "Пример (један модул): 20 јединица = (10 × 6,00) + (10 × 3,50) = 95,00 EUR месечно.",
    exBundle: "Пример (оба модула): 15 огласа + 15 управљаних некретнина = 30 јединица (130,00 EUR) − 20% попуста = 104,00 EUR месечно.",
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
    q2: "Да ли цена пада када додам јединице?",
    r2: "Не. Сваки степен се односи само на јединице унутар њега, па Ваш укупни рачун само расте како расте портфељ, док цена по додатној јединици постаје нижа.",
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
    details: "Детаљи",
    goToCalc: "Иди на калкулатор цена ↑",
    calcAbove: "Израчунајте цену за Ваш портфељ изнад ↑",
  },
  tr: {
    badge: "Şeffaf Acente Fiyatlandırması",
    h1: "Yalnızca kullandığınız modül ve hacim için ödeyin",
    lead: "Portföy & Dağıtım, Mülk & Kira Yönetimi veya her ikisini birden seçin. Fiyat kademeli dilimlerle hesaplanır — iki modülü birlikte aldığınızda hacimleriniz birleşir ve toplam tutara ekstra %20 paket indirimi uygulanır.",
    selectModules: "Modüllerinizi seçin",
    modPortfolio: "Portföy & Dağıtım",
    modPortfolioSub: "Aktif ilan sayısına göre hesaplanır",
    modProperty: "Mülk & Kira Yönetimi",
    modPropertySub: "Yönetilen mülk sayısına göre hesaplanır",
    bundleBadge: "%20 Paket İndirimi",
    bundleActiveNote: "İki modül birlikte seçili: ilan + yönetilen mülk sayısı toplanarak tek dilimden hesaplanır ve çıkan ana sonuca %20 paket indirimi uygulanır.",
    bundleUpsellNote: "İki modülü birlikte seçerek hacminizi birleştirin ve toplam tutarda %20 paket indirimi kazanın.",
    listingsLabel: "Aktif ilan sayısı",
    propertiesLabel: "Yönetilen mülk sayısı",
    listingsUnit: "ilan",
    propertiesUnit: "mülk",
    totalUnitsLabel: "Toplam hesaplama hacmi",
    totalUnitsUnit: "toplam birim",
    beforeBundle: "%20 paket indirimi öncesi",
    bundleSavings: "%20 paket kazancı",
    std: "Standart fiyat",
    fnd: "Kurucu ortak, 2 - 12. aylar",
    pm: "EUR / ay",
    h2std: "Standart kademeli fiyat tarifesi",
    th1: "Birim Dilimi (İlan / Yönetilen Mülk)",
    th2: "Birim başına aylık ücret (EUR)",
    ex: "Örnek (tek modül): 20 birim = (10 × 6,00) + (10 × 3,50) = 95,00 EUR / ay.",
    exBundle: "Örnek (iki modül birlikte): 15 ilan + 15 yönetilen mülk = 30 toplam birim (130,00 EUR) − %20 paket indirimi = 104,00 EUR / ay.",
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
    q2: "Birim eklediğimde fiyat düşer mi?",
    r2: "Hayır. Her dilim yalnızca kendi içindeki birimlere uygulanır; portföyünüz büyüdükçe toplam faturanız kontrollü artar ancak eklenen her yeni birimin maliyeti kademeli olarak ucuzlar.",
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
    details: "Detaylar",
    goToCalc: "Fiyat Hesabına Git ↑",
    calcAbove: "Yukarı çıkıp portföyünüze göre fiyatı hesaplayın ↑",
  },
  ru: {
    badge: "Прозрачные тарифы для агентств",
    h1: "Платите только за нужные модули и объём",
    lead: "Выберите «Портфель и дистрибуция», «Управление объектами и арендой» или оба модуля сразу. При выборе обоих модулей объём суммируется, а к итоговой сумме применяется дополнительная скидка 20%.",
    selectModules: "Выберите модули",
    modPortfolio: "Портфель и дистрибуция",
    modPortfolioSub: "Расчёт по числу активных объявлений",
    modProperty: "Управление объектами и арендой",
    modPropertySub: "Расчёт по числу управляемых объектов",
    bundleBadge: "-20% Комплект",
    bundleActiveNote: "Выбраны оба модуля: объявления + управляемые объекты суммируются в единую шкалу со скидкой 20% на итог.",
    bundleUpsellNote: "Выберите оба модуля вместе, чтобы объединить объём и получить скидку 20% на итоговую сумму.",
    listingsLabel: "Активные объявления",
    propertiesLabel: "Управляемые объекты",
    listingsUnit: "объявлений",
    propertiesUnit: "объектов",
    totalUnitsLabel: "Общий расчётный объём",
    totalUnitsUnit: "единиц всего",
    beforeBundle: "До скидки 20% за комплект",
    bundleSavings: "Экономия за комплект (20%)",
    std: "Стандартная цена",
    fnd: "Партнёр-основатель, месяцы 2–12",
    pm: "EUR в месяц",
    h2std: "Стандартный ступенчатый тариф",
    th1: "Единицы (Объявления / Объекты)",
    th2: "Цена за единицу в месяц (EUR)",
    ex: "Пример (один модуль): 20 единиц = (10 × 6,00) + (10 × 3,50) = 95,00 EUR в месяц.",
    exBundle: "Пример (оба модуля): 15 объявлений + 15 объектов = 30 единиц (130,00 EUR) − скидка 20% = 104,00 EUR в месяц.",
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
    q2: "Снижается ли общая цена при добавлении единиц?",
    r2: "Нет. Ступени применяются последовательно: общая сумма растет с портфелем, но стоимость каждой новой добавленной единицы становится ниже.",
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
    details: "Подробнее",
    goToCalc: "Перейти к калькулятору тарифа ↑",
    calcAbove: "Рассчитать стоимость для вашего портфеля выше ↑",
  },
};

export function AgencyPricingSection({ onOpenSimulation }: AgencyPricingSectionProps) {
  const { lang } = useLanguage();
  const [hasPortfolio, setHasPortfolio] = useState<boolean>(true);
  const [hasProperty, setHasProperty] = useState<boolean>(true);
  const [listingCount, setListingCount] = useState<number>(15);
  const [propertyCount, setPropertyCount] = useState<number>(15);

  const togglePortfolio = () => {
    if (hasPortfolio && !hasProperty) return;
    setHasPortfolio((prev) => !prev);
  };

  const toggleProperty = () => {
    if (hasProperty && !hasPortfolio) return;
    setHasProperty((prev) => !prev);
  };

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

  const isBundle = hasPortfolio && hasProperty;
  const effectiveUnits = (hasPortfolio ? listingCount : 0) + (hasProperty ? propertyCount : 0);

  // Tier calculation
  const { rawTotal, bundleSavings, totalStd, totalFnd, bracketCounts } = useMemo(() => {
    let remainder = effectiveUnits;
    let sum = 0;
    const counts: number[] = [];

    BRACKETS.forEach((bracket) => {
      const c = Math.min(remainder, bracket.max);
      counts.push(c);
      sum += c * bracket.price;
      remainder -= c;
    });

    const savings = isBundle ? sum * BUNDLE_DISCOUNT_RATE : 0;
    const finalStd = sum - savings;

    return {
      rawTotal: sum,
      bundleSavings: savings,
      totalStd: finalStd,
      totalFnd: finalStd * 0.6,
      bracketCounts: counts,
    };
  }, [effectiveUnits, isBundle]);

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
      id="section-pricing"
      className="relative py-20 md:py-28 px-4 sm:px-6 lg:px-8 bg-[#F8F7F5] border-t border-[#E5E3DF] scroll-mt-24"
    >
      {/* Anchor alias */}
      <span id="pricing" className="sr-only" />

      <div className="max-w-4xl mx-auto space-y-12">
        {/* Header */}
        <div className="text-center space-y-4">
          <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-[#E5EEF6] text-[#1B5888] text-xs sm:text-sm font-bold shadow-xs">
            <Calculator className="w-4 h-4 text-[#1B5888]" />
            <span>{texts.badge}</span>
          </div>

          <h2 className="font-[family-name:var(--font-outfit)] text-3xl sm:text-4xl lg:text-[42px] font-bold text-[#1A1A1A] tracking-tight leading-[1.15]">
            {texts.h1}
          </h2>

          <p className="text-base sm:text-lg text-[#4A4A4A] leading-relaxed max-w-2xl mx-auto">
            {texts.lead}
          </p>
        </div>

        {/* Interactive Calculator Card */}
        <div id="pricing-calculator" className="bg-white border border-[#E5E3DF] rounded-3xl p-6 sm:p-9 shadow-md shadow-slate-200/40 space-y-6 scroll-mt-28">
          {/* Module Selector */}
          <div className="space-y-3">
            <div className="flex flex-wrap items-center justify-between gap-2">
              <span className="text-sm font-bold text-[#1A1A1A] uppercase tracking-wider">
                {texts.selectModules}
              </span>
              <span
                className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-bold transition-colors ${
                  isBundle
                    ? "bg-[#E6F3EA] text-[#2A6E43] border border-[#2A6E43]/30"
                    : "bg-[#F8F7F5] text-[#666666] border border-[#E5E3DF]"
                }`}
              >
                <Tag className="w-3.5 h-3.5" />
                <span>{texts.bundleBadge}</span>
              </span>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <button
                type="button"
                onClick={togglePortfolio}
                aria-pressed={hasPortfolio}
                className={`p-4 rounded-2xl border-2 text-left transition-all cursor-pointer flex items-start justify-between gap-3 ${
                  hasPortfolio
                    ? "border-[#1B5888] bg-[#E5EEF6]/45 shadow-xs"
                    : "border-[#E5E3DF] bg-white hover:border-[#1B5888]/40"
                }`}
              >
                <div className="flex items-start gap-3">
                  <div
                    className={`w-9 h-9 rounded-xl flex items-center justify-center shrink-0 ${
                      hasPortfolio ? "bg-[#1B5888] text-white" : "bg-[#F8F7F5] text-[#666666]"
                    }`}
                  >
                    <Globe className="w-4 h-4" />
                  </div>
                  <div>
                    <span className="block text-sm font-bold text-[#1A1A1A]">{texts.modPortfolio}</span>
                    <span className="block text-xs text-[#666666] mt-0.5">{texts.modPortfolioSub}</span>
                  </div>
                </div>
                <span
                  className={`w-5 h-5 rounded-md border flex items-center justify-center shrink-0 mt-0.5 ${
                    hasPortfolio ? "bg-[#1B5888] border-[#1B5888] text-white" : "border-slate-300 bg-white"
                  }`}
                >
                  {hasPortfolio && <Check className="w-3.5 h-3.5" />}
                </span>
              </button>

              <button
                type="button"
                onClick={toggleProperty}
                aria-pressed={hasProperty}
                className={`p-4 rounded-2xl border-2 text-left transition-all cursor-pointer flex items-start justify-between gap-3 ${
                  hasProperty
                    ? "border-[#2A6E43] bg-[#E6F3EA]/55 shadow-xs"
                    : "border-[#E5E3DF] bg-white hover:border-[#2A6E43]/40"
                }`}
              >
                <div className="flex items-start gap-3">
                  <div
                    className={`w-9 h-9 rounded-xl flex items-center justify-center shrink-0 ${
                      hasProperty ? "bg-[#2A6E43] text-white" : "bg-[#F8F7F5] text-[#666666]"
                    }`}
                  >
                    <Home className="w-4 h-4" />
                  </div>
                  <div>
                    <span className="block text-sm font-bold text-[#1A1A1A]">{texts.modProperty}</span>
                    <span className="block text-xs text-[#666666] mt-0.5">{texts.modPropertySub}</span>
                  </div>
                </div>
                <span
                  className={`w-5 h-5 rounded-md border flex items-center justify-center shrink-0 mt-0.5 ${
                    hasProperty ? "bg-[#2A6E43] border-[#2A6E43] text-white" : "border-slate-300 bg-white"
                  }`}
                >
                  {hasProperty && <Check className="w-3.5 h-3.5" />}
                </span>
              </button>
            </div>

            <div
              className={`rounded-xl px-3.5 py-2.5 text-xs font-medium flex items-center gap-2 ${
                isBundle
                  ? "bg-[#E6F3EA] text-[#2A6E43] border border-[#2A6E43]/20"
                  : "bg-[#F8F7F5] text-[#4A4A4A] border border-[#E5E3DF]"
              }`}
            >
              <Sparkles className={`w-4 h-4 shrink-0 ${isBundle ? "text-[#2A6E43]" : "text-[#1B5888]"}`} />
              <span>{isBundle ? texts.bundleActiveNote : texts.bundleUpsellNote}</span>
            </div>
          </div>

          {/* Sliders based on active modules */}
          <div className={`grid grid-cols-1 ${isBundle ? "sm:grid-cols-2" : ""} gap-5 pt-2`}>
            {hasPortfolio && (
              <div className="rounded-2xl bg-[#F8F7F5] border border-[#E5E3DF] p-4 space-y-3">
                <div className="flex items-baseline justify-between gap-2">
                  <label htmlFor="listings-range-input" className="text-sm font-bold text-[#1A1A1A]">
                    {texts.listingsLabel}
                  </label>
                  <div className="flex items-baseline gap-1.5">
                    <span className="font-mono text-2xl sm:text-3xl font-semibold text-[#1B5888]">
                      {listingCount}
                    </span>
                    <span className="text-xs font-semibold text-[#666666]">{texts.listingsUnit}</span>
                  </div>
                </div>
                <input
                  id="listings-range-input"
                  type="range"
                  min="1"
                  max="150"
                  value={listingCount}
                  onChange={(e) => setListingCount(Number(e.target.value))}
                  aria-label={texts.listingsLabel}
                  className="w-full h-2.5 bg-slate-200 rounded-lg appearance-none cursor-pointer accent-[#1B5888] transition"
                />
              </div>
            )}

            {hasProperty && (
              <div className="rounded-2xl bg-[#F8F7F5] border border-[#E5E3DF] p-4 space-y-3">
                <div className="flex items-baseline justify-between gap-2">
                  <label htmlFor="property-range-input" className="text-sm font-bold text-[#1A1A1A]">
                    {texts.propertiesLabel}
                  </label>
                  <div className="flex items-baseline gap-1.5">
                    <span className="font-mono text-2xl sm:text-3xl font-semibold text-[#2A6E43]">
                      {propertyCount}
                    </span>
                    <span className="text-xs font-semibold text-[#666666]">{texts.propertiesUnit}</span>
                  </div>
                </div>
                <input
                  id="property-range-input"
                  type="range"
                  min="1"
                  max="150"
                  value={propertyCount}
                  onChange={(e) => setPropertyCount(Number(e.target.value))}
                  aria-label={texts.propertiesLabel}
                  className="w-full h-2.5 bg-slate-200 rounded-lg appearance-none cursor-pointer accent-[#2A6E43] transition"
                />
              </div>
            )}
          </div>

          {/* Combined Volume & Segmented Bracket Bar */}
          <div className="space-y-2.5">
            {isBundle && (
              <div className="flex flex-wrap items-center justify-between gap-2 text-xs sm:text-sm font-semibold text-[#4A4A4A]">
                <span>{texts.totalUnitsLabel}</span>
                <span className="font-mono font-bold text-[#1A1A1A]">
                  {listingCount} + {propertyCount} = {effectiveUnits} {texts.totalUnitsUnit}
                </span>
              </div>
            )}

            <div
              className="flex h-3.5 rounded-full overflow-hidden bg-slate-200 shadow-inner"
              aria-hidden="true"
            >
              {bracketCounts.map((c, i) => {
                const widthPercent = effectiveUnits > 0 ? (c / effectiveUnits) * 100 : 0;
                const colors = [
                  "bg-[#7fa8dc]",
                  "bg-[#4d83cb]",
                  "bg-[#1B5888]",
                  "bg-[#12406A]",
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
                  "bg-[#1B5888]",
                  "bg-[#12406A]",
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
            <div className="p-4 rounded-2xl bg-[#F8F7F5] border border-[#E5E3DF] space-y-1.5">
              <div className="flex items-center justify-between gap-2">
                <span className="text-xs sm:text-sm font-bold text-[#4A4A4A]">
                  {texts.std}
                </span>
                {isBundle && (
                  <span className="text-[11px] font-bold text-[#2A6E43] bg-[#E6F3EA] px-2 py-0.5 rounded-full">
                    {texts.bundleBadge}
                  </span>
                )}
              </div>
              <div className="flex items-baseline gap-2 flex-wrap">
                {isBundle && (
                  <span className="font-mono text-lg font-medium text-slate-400 line-through">
                    €{money(rawTotal)}
                  </span>
                )}
                <span className="font-mono text-3xl sm:text-4xl font-semibold text-[#1A1A1A]">
                  €{money(totalStd)}
                </span>
                <span className="text-xs text-[#666666]">{texts.pm}</span>
              </div>
              {isBundle && (
                <p className="text-xs font-semibold text-[#2A6E43]">
                  {texts.bundleSavings}: −€{money(bundleSavings)}
                </p>
              )}
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
                className="group/fnd p-4 rounded-2xl bg-[#E6F3EA]/75 border-2 border-[#2A6E43]/30 hover:border-[#2A6E43] hover:bg-[#E6F3EA] hover:shadow-md transition-all cursor-pointer block text-left"
              >
                <div className="flex items-center justify-between mb-1">
                  <span className="text-xs sm:text-sm font-bold text-[#2A6E43] flex items-center gap-1.5">
                    <Sparkles className="w-3.5 h-3.5 text-[#2A6E43] group-hover/fnd:scale-110 transition-transform" />
                    {texts.fnd}
                  </span>
                  <span className="text-[11px] font-bold text-[#2A6E43] bg-white/90 px-2 py-0.5 rounded-full group-hover/fnd:bg-[#2A6E43] group-hover/fnd:text-white transition-colors flex items-center gap-1">
                    <span>{texts.details}</span>
                    <ArrowRight className="w-3 h-3 group-hover/fnd:translate-x-0.5 transition-transform" />
                  </span>
                </div>
                <div className="flex items-baseline gap-2">
                  <span className="font-mono text-3xl sm:text-4xl font-semibold text-[#2A6E43]">
                    €{money(totalFnd)}
                  </span>
                  <span className="text-xs text-[#2A6E43] font-semibold">{texts.pm}</span>
                </div>
              </a>
            )}
          </div>
        </div>

        {/* Standard Brackets Table */}
        <div className="bg-white border border-[#E5E3DF] rounded-3xl p-6 sm:p-8 shadow-sm space-y-4">
          <h3 className="font-[family-name:var(--font-outfit)] text-xl font-bold text-[#1A1A1A]">{texts.h2std}</h3>
          
          <div className="overflow-x-auto rounded-2xl border border-[#E5E3DF]">
            <table className="w-full text-sm sm:text-base border-collapse">
              <thead>
                <tr className="bg-[#F8F7F5] text-[#1A1A1A] font-semibold border-b border-[#E5E3DF]">
                  <th className="py-3 px-4 text-left font-bold">{texts.th1}</th>
                  <th className="py-3 px-4 text-right font-bold">{texts.th2}</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {texts.rows.map((rowName, idx) => (
                  <tr key={idx} className="hover:bg-[#F8F7F5]/80 transition-colors">
                    <td className="py-3.5 px-4 font-semibold text-slate-700">{rowName}</td>
                    <td className="py-3.5 px-4 text-right font-mono font-bold text-[#1B5888]">
                      €{money(BRACKETS[idx].price)}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <div className="space-y-1 pt-1">
            <p className="text-xs sm:text-sm text-[#666666] italic">{texts.ex}</p>
            <p className="text-xs sm:text-sm text-[#2A6E43] font-medium">{texts.exBundle}</p>
          </div>
        </div>

        {/* Founding Partners Section */}
        {isFoundingActive && (
          <div
            id="founding-partners"
            className="scroll-mt-28 bg-emerald-500/10 border-2 border-emerald-300/80 rounded-3xl p-6 sm:p-9 shadow-lg space-y-8"
          >
            {/* Anchor aliases */}
            <span id="founding-feedback-partners" className="sr-only" />

            <div className="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-4">
              <div className="space-y-2">
                <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-emerald-100 text-emerald-800 text-xs font-bold tracking-wide">
                  <Sparkles className="w-3.5 h-3.5 text-emerald-600" />
                  <span>31.12.2026</span>
                </div>
                <h3 className="text-2xl sm:text-3xl font-semibold text-slate-900">
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
                <span>{texts.goToCalc}</span>
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
                      className={`block font-mono text-xl sm:text-2xl font-semibold ${
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
                <h4 className="text-base font-semibold text-slate-900 flex items-center gap-2">
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
                <h4 className="text-base font-semibold text-slate-900 flex items-center gap-2">
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
                <span>{texts.calcAbove}</span>
              </a>
            </div>
          </div>
        )}

        {/* FAQ Accordions */}
        <div className="space-y-4 pt-4">
          <h3 className="text-2xl font-semibold text-slate-900 text-center sm:text-left">
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
                <summary className="font-semibold text-slate-900 text-base sm:text-lg flex justify-between items-center list-none select-none">
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
        <div className="bg-blue-900 text-white rounded-3xl p-8 sm:p-12 shadow-md space-y-6 text-center sm:text-left sm:flex sm:items-center sm:justify-between sm:space-y-0 gap-6">
          <div className="space-y-2 max-w-xl">
            <h3 className="text-2xl sm:text-3xl font-semibold tracking-tight">
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
              className="inline-flex justify-center items-center gap-2.5 px-7 py-4 rounded-xl text-slate-900 bg-white hover:bg-slate-100 font-bold text-base shadow-md transition-all transform hover:-translate-y-0.5 active:translate-y-0 cursor-pointer"
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
