"use client";

import React, { useState, useEffect, useMemo } from "react";
import { 
  Building2, 
  Search, 
  MapPin, 
  Phone, 
  Mail, 
  Globe, 
  Filter, 
  CheckCircle2, 
  ExternalLink, 
  ShieldCheck, 
  Sparkles,
  ChevronDown,
  X,
  RefreshCw,
  ArrowRight,
  Copy,
  Check,
  Star,
  Award,
  Zap
} from "lucide-react";
import { Navbar } from "../../components/Navbar";
import { useLanguage, Language } from "../../components/LanguageProvider";
import { supabase } from "../../lib/supabaseClient";

interface CleanAgency {
  id: number;
  acente_adi: string;
  resmi_tam_unvan?: string | null;
  sehir?: string | null;
  adres?: string | null;
  web_sitesi?: string | null;
  telefonlar?: string | null;
  eposta_adresleri?: string | null;
  is_partner?: boolean | null;
  uses_stanomer?: boolean | null;
  logo_url?: string | null;
}


interface ContactModalState {
  isOpen: boolean;
  type: "phone" | "email";
  agencyName: string;
  items: string[];
}

const PAGE_TEXTS: Record<Language, {
  badge: string;
  title: string;
  subtitle: string;
  searchPlaceholder: string;
  allCities: string;
  filterPartner: string;
  filterStanomer: string;
  foundCount: string;
  noResultsTitle: string;
  noResultsDesc: string;
  clearFilters: string;
  call: string;
  email: string;
  website: string;
  verifiedBadge: string;
  partnerBadge: string;
  stanomerBadge: string;
  loadMore: string;
  showingCount: string;
  footerRights: string;
  showPhones: string;
  showEmails: string;
  phoneModalTitle: string;
  emailModalTitle: string;
  callAction: string;
  emailAction: string;
  copyAction: string;
  copiedAction: string;
  close: string;
  ctaTitle: string;
  ctaButton: string;
  optOutText: string;
  optOutLink: string;
}> = {
  TR: {
    badge: "Sırbistan Emlak Rehberi",
    title: "Emlak Acenteleri",
    subtitle: "Sırbistan genelindeki doğrulanmış emlak acentelerini inceleyin, telefon, e-posta veya web adresleri üzerinden iletişime geçin.",
    searchPlaceholder: "Acente adı, şehir veya adres ara...",
    allCities: "Tüm Şehirler",
    filterStanomer: "Portföyünü Stanomer ile Yönetenler",
    filterPartner: "Anlaşmalı Partnerler",
    foundCount: "Acente Bulundu",
    noResultsTitle: "Acente Bulunamadı",
    noResultsDesc: "Arama kriterlerinize uygun acente bulunamadı. Lütfen farklı bir arama kelimesi veya filtre deneyin.",
    clearFilters: "Filtreleri Temizle",
    call: "Ara",
    email: "E-posta",
    website: "Web Sitesi",
    verifiedBadge: "Kayıtlı Acente",
    partnerBadge: "Stanomer Anlaşmalı Partner",
    stanomerBadge: "Portföyünü Stanomer ile Yönetiyor",
    loadMore: "Daha Fazla Acente Göster",
    showingCount: "Acente Gösteriliyor",
    footerRights: "Tüm Hakları Saklıdır.",
    showPhones: "Telefon Numarasını Göster",
    showEmails: "E-posta Adresini Göster",
    phoneModalTitle: "Telefon Numaraları",
    emailModalTitle: "E-posta Adresleri",
    callAction: "Ara",
    emailAction: "E-posta Gönder",
    copyAction: "Kopyala",
    copiedAction: "Kopyalandı!",
    close: "Kapat",
    ctaTitle: "Bu sizin acenteniz mi?",
    ctaButton: "Partner olun, öne çıkın →",
    optOutText: "Bu bilgiler size mi ait?",
    optOutLink: "Listeden çıkmak için bize ulaşın"
  },
  SR_LAT: {
    badge: "Registar Agencija U Srbiji",
    title: "Agencije Za Nekretnine",
    subtitle: "Pretražite registrovane agencije za nekretnine u Srbiji i kontaktirajte ih direktno putem telefona, email-a ili veb sajta.",
    searchPlaceholder: "Pretraži po nazivu, gradu ili adresi...",
    allCities: "Svi gradovi",
    filterStanomer: "Upravlja Portfolijom Putem Stanomera",
    filterPartner: "Partner Agencije",
    foundCount: "Pronađeno agencija",
    noResultsTitle: "Nijedna agencija nije pronađena",
    noResultsDesc: "Nismo pronašli agencije koje odgovaraju vašim kriterijumima. Pokušajte sa drugim parametrima.",
    clearFilters: "Očisti filtere",
    call: "Pozovi",
    email: "Email",
    website: "Veb sajt",
    verifiedBadge: "Registrovana Agencija",
    partnerBadge: "Stanomer Partner Agencija",
    stanomerBadge: "Upravlja Portfolijom Putem Stanomera",
    loadMore: "Prikaži više agencija",
    showingCount: "Prikazano agencija",
    footerRights: "Sva prava zadržana.",
    showPhones: "Prikaži telefon",
    showEmails: "Prikaži email",
    phoneModalTitle: "Brojevi telefona",
    emailModalTitle: "Email adrese",
    callAction: "Pozovi",
    emailAction: "Pošalji email",
    copyAction: "Kopiraj",
    copiedAction: "Kopirano!",
    close: "Zatvori",
    ctaTitle: "Da li je ovo vaša agencija?",
    ctaButton: "Postanite partner, istaknite se →",
    optOutText: "Da li su ovi podaci vaši?",
    optOutLink: "Kontaktirajte nas za uklanjanje"
  },
  SR_CYR: {
    badge: "Регистар Агенција У Србији",
    title: "Агенције За Некретнине",
    subtitle: "Претражите регистроване агенције за некретнине у Србији и контактирајте их директно путем телефона, емаил-а или веб сајта.",
    searchPlaceholder: "Претражи по називу, граду или адреси...",
    allCities: "Сви градови",
    filterStanomer: "Управља Портфолијом Путем Станомера",
    filterPartner: "Партнер Агенције",
    foundCount: "Пронађено агенција",
    noResultsTitle: "Ниједна агенција није пронађена",
    noResultsDesc: "Нисмо пронашли агенције које одговарају вашим критеријумима.",
    clearFilters: "Очисти филтере",
    call: "Позови",
    email: "Емаил",
    website: "Веб сајт",
    verifiedBadge: "Регистрована Агенција",
    partnerBadge: "Станомер Партнер Агенција",
    stanomerBadge: "Управља Портфолијом Путем Станомера",
    loadMore: "Прикажи више агенција",
    showingCount: "Приказано агенција",
    footerRights: "Сва права задржана.",
    showPhones: "Прикажи телефон",
    showEmails: "Прикажи емаил",
    phoneModalTitle: "Бројеви телефона",
    emailModalTitle: "Емаил адресе",
    callAction: "Позови",
    emailAction: "Пошаљи емаил",
    copyAction: "Копирај",
    copiedAction: "Копирано!",
    close: "Затвори",
    ctaTitle: "Да ли је ово ваша агенција?",
    ctaButton: "Постаните партнер, истакните се →",
    optOutText: "Да ли су ови подаци ваши?",
    optOutLink: "Контактирајте нас за уклањање"
  },
  EN: {
    badge: "Serbia Real Estate Directory",
    title: "Real Estate Agencies",
    subtitle: "Explore registered real estate agencies across Serbia and contact them directly via phone, email, or official website.",
    searchPlaceholder: "Search by agency name, city or address...",
    allCities: "All Cities",
    filterStanomer: "Manages Portfolio with Stanomer",
    filterPartner: "Official Partners",
    foundCount: "Agencies Found",
    noResultsTitle: "No Agencies Found",
    noResultsDesc: "No agencies match your search criteria. Please try adjusting your search or filters.",
    clearFilters: "Clear Filters",
    call: "Call",
    email: "Email",
    website: "Website",
    verifiedBadge: "Registered Agency",
    partnerBadge: "Official Stanomer Partner",
    stanomerBadge: "Manages Portfolio with Stanomer",
    loadMore: "Load More Agencies",
    showingCount: "Agencies Shown",
    footerRights: "All Rights Reserved.",
    showPhones: "Show Phone Number",
    showEmails: "Show Email Address",
    phoneModalTitle: "Phone Numbers",
    emailModalTitle: "Email Addresses",
    callAction: "Call",
    emailAction: "Send Email",
    copyAction: "Copy",
    copiedAction: "Copied!",
    close: "Close",
    ctaTitle: "Is this your agency?",
    ctaButton: "Become a partner, stand out →",
    optOutText: "Do these details belong to you?",
    optOutLink: "Contact us to remove your listing"
  },
  RU: {
    badge: "Каталог Агентств Сербии",
    title: "Агентства Недвижимости",
    subtitle: "Ищите зарегистрированные агентства недвижимости по всей Сербии и связывайтесь с ними напрямую по телефону, email или через сайт.",
    searchPlaceholder: "Поиск по названию, городу или адресу...",
    allCities: "Все города",
    filterStanomer: "Управляет Портфелем через Stanomer",
    filterPartner: "Официальные Партнеры",
    foundCount: "Агентств найдено",
    noResultsTitle: "Агентства не найдены",
    noResultsDesc: "По вашему запросу ничего не найдено. Попробуйте изменить параметры поиска.",
    clearFilters: "Сбросить фильтры",
    call: "Позвонить",
    email: "Email",
    website: "Веб-сайт",
    verifiedBadge: "Проверенное Агентство",
    partnerBadge: "Официальный Партнер Stanomer",
    stanomerBadge: "Управляет Портфелем через Stanomer",
    loadMore: "Показать больше агентств",
    showingCount: "Показано агентств",
    footerRights: "Все права защищены.",
    showPhones: "Показать телефон",
    showEmails: "Показать email",
    phoneModalTitle: "Номера телефонов",
    emailModalTitle: "Email адреса",
    callAction: "Позвонить",
    emailAction: "Написать email",
    copyAction: "Копировать",
    copiedAction: "Скопировано!",
    close: "Закрыть",
    ctaTitle: "Это ваше агентство?",
    ctaButton: "Станьте партнером, выделитесь →",
    optOutText: "Эти данные принадлежат вам?",
    optOutLink: "Свяжитесь с нами для удаления"
  }
};

const POPULAR_CITIES = ["Beograd", "Novi Sad", "Niš", "Kragujevac", "Subotica", "Pančevo", "Šabac", "Kruševac", "Inđija"];

export default function FindAgencyPage() {
  const { lang } = useLanguage();
  const t = PAGE_TEXTS[lang] || PAGE_TEXTS.TR;

  const [agencies, setAgencies] = useState<CleanAgency[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  const [searchQuery, setSearchQuery] = useState<string>("");
  const [selectedCity, setSelectedCity] = useState<string>("");
  const [partnerOnly, setPartnerOnly] = useState<boolean>(false);
  const [stanomerOnly, setStanomerOnly] = useState<boolean>(false);

  const [displayCount, setDisplayCount] = useState<number>(24);

  // Modal State
  const [modal, setModal] = useState<ContactModalState>({
    isOpen: false,
    type: "phone",
    agencyName: "",
    items: []
  });

  const [copiedItem, setCopiedItem] = useState<string | null>(null);

  useEffect(() => {
    async function fetchAgencies() {
      setLoading(true);
      setError(null);

      try {
        // Fetch profiles with logos to enrich directory agencies
        const { data: agencyProfiles } = await supabase
          .from("profiles")
          .select("email, company_name, logo_url")
          .not("logo_url", "is", null);

        const logoMap = new Map<string, string>();
        (agencyProfiles || []).forEach((p: any) => {
          if (p.logo_url) {
            if (p.email) logoMap.set(p.email.toLowerCase().trim(), p.logo_url);
            if (p.company_name) logoMap.set(p.company_name.toLowerCase().trim(), p.logo_url);
          }
        });

        const { data, error } = await supabase
          .from("view_clean_agencies")
          .select("*")
          .order("id", { ascending: true });

        if (error) {
          console.error("Supabase view query error, trying fallback:", error);
          const { data: rawAgencies, error: rawError } = await supabase
            .from("agencies")
            .select("id, name, long_name, city, address, website, is_partner, uses_stanomer");

          if (rawError) throw rawError;

          const mapped = (rawAgencies || []).map((a: any) => {
            const logo = a.name ? logoMap.get(a.name.toLowerCase().trim()) : null;
            return {
              id: a.id,
              acente_adi: a.name,
              resmi_tam_unvan: a.long_name,
              sehir: a.city,
              adres: a.address,
              web_sitesi: a.website || null,
              telefonlar: null,
              eposta_adresleri: null,
              is_partner: !!a.is_partner,
              uses_stanomer: !!a.uses_stanomer,
              logo_url: logo || null
            };
          });
          setAgencies(mapped);
        } else {
          const enriched = (data || []).map((a: any) => {
            let logo = a.logo_url || null;
            if (!logo) {
              if (a.acente_adi && logoMap.has(a.acente_adi.toLowerCase().trim())) {
                logo = logoMap.get(a.acente_adi.toLowerCase().trim());
              } else if (a.resmi_tam_unvan && logoMap.has(a.resmi_tam_unvan.toLowerCase().trim())) {
                logo = logoMap.get(a.resmi_tam_unvan.toLowerCase().trim());
              } else if (a.eposta_adresleri) {
                const emails = a.eposta_adresleri.split(",").map((e: string) => e.toLowerCase().trim());
                for (const em of emails) {
                  if (logoMap.has(em)) {
                    logo = logoMap.get(em);
                    break;
                  }
                }
              }
            }
            return {
              ...a,
              logo_url: logo || null
            };
          });
          setAgencies(enriched);
        }
      } catch (err: any) {
        console.error("Error fetching agencies:", err);
        setError("Veriler yüklenirken bir hata oluştu.");
      } finally {
        setLoading(false);
      }
    }


    fetchAgencies();
  }, []);

  const filteredAgencies = useMemo(() => {
    // Priority 1: uses_stanomer is MOST IMPORTANT, Priority 2: is_partner
    const sorted = [...agencies].sort((a, b) => {
      const aScore = (a.uses_stanomer ? 10 : 0) + (a.is_partner ? 5 : 0);
      const bScore = (b.uses_stanomer ? 10 : 0) + (b.is_partner ? 5 : 0);
      if (aScore !== bScore) return bScore - aScore;
      return a.id - b.id;
    });

    return sorted.filter((item) => {
      if (searchQuery.trim()) {
        const q = searchQuery.toLowerCase().trim();
        const matchName = (item.acente_adi || "").toLowerCase().includes(q);
        const matchLongName = (item.resmi_tam_unvan || "").toLowerCase().includes(q);
        const matchCity = (item.sehir || "").toLowerCase().includes(q);
        const matchAddress = (item.adres || "").toLowerCase().includes(q);

        if (!matchName && !matchLongName && !matchCity && !matchAddress) {
          return false;
        }
      }

      if (selectedCity) {
        if ((item.sehir || "").toLowerCase() !== selectedCity.toLowerCase()) {
          return false;
        }
      }

      if (partnerOnly && !item.is_partner) return false;
      if (stanomerOnly && !item.uses_stanomer) return false;

      return true;
    });
  }, [agencies, searchQuery, selectedCity, partnerOnly, stanomerOnly]);

  const citiesList = useMemo(() => {
    const set = new Set<string>();
    agencies.forEach((a) => {
      if (a.sehir && a.sehir.trim()) {
        set.add(a.sehir.trim());
      }
    });
    return Array.from(set).sort();
  }, [agencies]);

  const visibleAgencies = filteredAgencies.slice(0, displayCount);

  const resetFilters = () => {
    setSearchQuery("");
    setSelectedCity("");
    setPartnerOnly(false);
    setStanomerOnly(false);
    setDisplayCount(24);
  };

  const openPhoneModal = (agencyName: string, phoneStr: string) => {
    const items = phoneStr.split(",").map(p => p.trim()).filter(Boolean);
    setModal({
      isOpen: true,
      type: "phone",
      agencyName,
      items
    });
  };

  const openEmailModal = (agencyName: string, emailStr: string) => {
    const items = emailStr.split(",").map(e => e.trim()).filter(Boolean);
    setModal({
      isOpen: true,
      type: "email",
      agencyName,
      items
    });
  };

  const handleCopy = (text: string) => {
    navigator.clipboard.writeText(text);
    setCopiedItem(text);
    setTimeout(() => setCopiedItem(null), 2000);
  };

  return (
    <div className="min-h-screen bg-slate-50 flex flex-col font-sans selection:bg-blue-500 selection:text-white">
      <Navbar />

      <section className="pt-28 pb-16 md:pt-36 md:pb-20 bg-gradient-to-b from-slate-900 via-blue-950 to-slate-900 text-white relative overflow-hidden border-b border-slate-800">
        <div className="absolute -top-32 -right-32 w-96 h-96 bg-blue-600/20 rounded-full blur-3xl pointer-events-none" />
        <div className="absolute -bottom-32 -left-32 w-96 h-96 bg-violet-600/20 rounded-full blur-3xl pointer-events-none" />

        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10 text-center space-y-6">
          <div className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full bg-blue-500/10 border border-blue-400/30 text-blue-300 text-xs sm:text-sm font-semibold tracking-wide backdrop-blur-md">
            <Sparkles className="w-4 h-4 text-blue-400" />
            <span>{t.badge}</span>
          </div>

          <h1 className="text-3xl sm:text-5xl lg:text-6xl font-extrabold tracking-tight text-white max-w-4xl mx-auto leading-tight">
            {t.title}
          </h1>

          <p className="text-slate-300 text-base sm:text-lg max-w-2xl mx-auto font-normal leading-relaxed">
            {t.subtitle}
          </p>

          <div className="max-w-3xl mx-auto pt-4">
            <div className="relative flex items-center bg-white/95 backdrop-blur-md rounded-2xl shadow-2xl p-2 border border-white/20 focus-within:ring-4 focus-within:ring-blue-500/30 transition-all">
              <Search className="w-6 h-6 text-slate-400 ml-4 flex-shrink-0" />
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder={t.searchPlaceholder}
                className="w-full bg-transparent px-4 py-3 text-slate-900 placeholder-slate-400 font-medium text-base focus:outline-none"
              />
              {searchQuery && (
                <button
                  type="button"
                  onClick={() => setSearchQuery("")}
                  className="p-2 hover:bg-slate-100 rounded-xl text-slate-400 hover:text-slate-600 transition mr-2"
                >
                  <X className="w-5 h-5" />
                </button>
              )}
            </div>
          </div>
        </div>
      </section>

      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10 w-full flex-grow space-y-8">
        <div className="bg-white rounded-2xl p-6 shadow-sm border border-slate-200/80 space-y-6">
          <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4">
            <div className="flex items-center gap-3 w-full lg:w-auto">
              <div className="relative w-full sm:w-64">
                <select
                  value={selectedCity}
                  onChange={(e) => setSelectedCity(e.target.value)}
                  className="w-full appearance-none bg-slate-50 border border-slate-300 text-slate-800 rounded-xl py-3 pl-10 pr-10 font-semibold text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:bg-white transition cursor-pointer"
                >
                  <option value="">📍 {t.allCities}</option>
                  {citiesList.map((city) => (
                    <option key={city} value={city}>
                      {city}
                    </option>
                  ))}
                </select>
                <MapPin className="w-4 h-4 text-slate-500 absolute left-3.5 top-1/2 -translate-y-1/2 pointer-events-none" />
                <ChevronDown className="w-4 h-4 text-slate-500 absolute right-3.5 top-1/2 -translate-y-1/2 pointer-events-none" />
              </div>
            </div>

            <div className="flex flex-wrap items-center gap-3">
              {/* PRIMARY #1 FILTER: Stanomer User Agency Toggle */}
              <label className={`inline-flex items-center gap-2 px-4 py-2.5 rounded-xl text-xs sm:text-sm font-extrabold border cursor-pointer transition select-none ${
                stanomerOnly 
                  ? "bg-gradient-to-r from-amber-500 to-yellow-500 text-white shadow-md shadow-amber-500/30 border-transparent ring-2 ring-amber-400" 
                  : "bg-amber-50/80 border-amber-200 text-amber-900 hover:bg-amber-100"
              }`}>
                <input
                  type="checkbox"
                  checked={stanomerOnly}
                  onChange={(e) => setStanomerOnly(e.target.checked)}
                  className="rounded border-amber-400 text-amber-600 focus:ring-amber-500"
                />
                <Zap className={`w-4 h-4 ${stanomerOnly ? "text-yellow-100" : "text-amber-600"}`} />
                <span>{t.filterStanomer}</span>
              </label>

              {/* SECONDARY #2 FILTER: Partner Only Toggle */}
              <label className={`inline-flex items-center gap-2 px-4 py-2.5 rounded-xl text-xs sm:text-sm font-extrabold border cursor-pointer transition select-none ${
                partnerOnly 
                  ? "bg-gradient-to-r from-indigo-500 to-violet-600 text-white shadow-md shadow-indigo-500/25 border-transparent ring-2 ring-indigo-400" 
                  : "bg-indigo-50/80 border-indigo-200 text-indigo-900 hover:bg-indigo-100"
              }`}>
                <input
                  type="checkbox"
                  checked={partnerOnly}
                  onChange={(e) => setPartnerOnly(e.target.checked)}
                  className="rounded border-indigo-400 text-indigo-600 focus:ring-indigo-500"
                />
                <Award className={`w-4 h-4 ${partnerOnly ? "text-indigo-200" : "text-indigo-600"}`} />
                <span>{t.filterPartner}</span>
              </label>

              {(searchQuery || selectedCity || partnerOnly || stanomerOnly) && (
                <button
                  type="button"
                  onClick={resetFilters}
                  className="inline-flex items-center gap-1.5 px-3.5 py-2.5 rounded-xl text-xs sm:text-sm font-semibold text-rose-600 hover:bg-rose-50 border border-rose-200 transition"
                >
                  <RefreshCw className="w-3.5 h-3.5" />
                  <span>{t.clearFilters}</span>
                </button>
              )}
            </div>
          </div>

          <div className="pt-2 border-t border-slate-100 flex items-center gap-2 overflow-x-auto pb-1 scrollbar-none">
            <span className="text-xs font-bold text-slate-400 uppercase tracking-wider flex-shrink-0 mr-1">Popüler:</span>
            {POPULAR_CITIES.map((city) => (
              <button
                key={city}
                type="button"
                onClick={() => setSelectedCity(selectedCity === city ? "" : city)}
                className={`text-xs font-semibold px-3 py-1.5 rounded-full transition-all flex-shrink-0 cursor-pointer ${
                  selectedCity === city
                    ? "bg-blue-600 text-white shadow-md shadow-blue-500/20"
                    : "bg-slate-100 text-slate-600 hover:bg-slate-200"
                }`}
              >
                {city}
              </button>
            ))}
          </div>
        </div>

        <div className="flex items-center justify-between text-sm text-slate-600 px-1 font-medium">
          <div>
            <span className="font-extrabold text-slate-900 text-lg mr-2">{filteredAgencies.length}</span>
            <span>{t.foundCount}</span>
          </div>

          {filteredAgencies.length > 0 && (
            <div className="text-xs text-slate-500">
              {t.showingCount}: <span className="font-bold text-slate-700">{visibleAgencies.length}</span> / {filteredAgencies.length}
            </div>
          )}
        </div>

        {loading && (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {[...Array(6)].map((_, i) => (
              <div key={i} className="bg-white rounded-2xl p-6 border border-slate-200 space-y-4 animate-pulse">
                <div className="flex items-center gap-3">
                  <div className="w-12 h-12 bg-slate-200 rounded-xl" />
                  <div className="space-y-2 flex-grow">
                    <div className="h-4 bg-slate-200 rounded w-3/4" />
                    <div className="h-3 bg-slate-100 rounded w-1/2" />
                  </div>
                </div>
                <div className="h-3 bg-slate-100 rounded w-full" />
                <div className="h-3 bg-slate-100 rounded w-2/3" />
                <div className="pt-4 border-t border-slate-100 flex gap-2">
                  <div className="h-9 bg-slate-100 rounded-xl flex-grow" />
                  <div className="h-9 bg-slate-100 rounded-xl flex-grow" />
                </div>
              </div>
            ))}
          </div>
        )}

        {error && !loading && (
          <div className="bg-rose-50 border border-rose-200 text-rose-700 p-8 rounded-2xl text-center space-y-3">
            <p className="font-semibold">{error}</p>
            <button
              onClick={() => window.location.reload()}
              className="px-4 py-2 bg-rose-600 text-white font-bold rounded-xl text-sm hover:bg-rose-700 transition"
            >
              Tekrar Deneyin
            </button>
          </div>
        )}

        {!loading && !error && filteredAgencies.length === 0 && (
          <div className="bg-white rounded-3xl p-12 border border-slate-200 text-center space-y-4 max-w-lg mx-auto my-12 shadow-sm">
            <div className="w-16 h-16 bg-slate-100 text-slate-400 rounded-full flex items-center justify-center mx-auto">
              <Search className="w-8 h-8" />
            </div>
            <h3 className="text-xl font-bold text-slate-800">{t.noResultsTitle}</h3>
            <p className="text-sm text-slate-500 leading-relaxed">{t.noResultsDesc}</p>
            <button
              onClick={resetFilters}
              className="px-6 py-3 bg-blue-600 text-white font-bold text-sm rounded-xl hover:bg-blue-700 transition shadow-lg shadow-blue-500/20"
            >
              {t.clearFilters}
            </button>
          </div>
        )}

        {!loading && !error && visibleAgencies.length > 0 && (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {visibleAgencies.map((agency) => {
              const phoneCount = agency.telefonlar ? agency.telefonlar.split(",").filter(Boolean).length : 0;
              const emailCount = agency.eposta_adresleri ? agency.eposta_adresleri.split(",").filter(Boolean).length : 0;
              const websites = agency.web_sitesi ? agency.web_sitesi.split(",").map(w => w.trim()).filter(Boolean) : [];
              const isPartner = !!agency.is_partner;
              const usesStanomer = !!agency.uses_stanomer;

              return (
                <div
                  key={agency.id}
                  className={`bg-white rounded-2xl p-6 border transition-all duration-300 flex flex-col justify-between space-y-5 group relative overflow-hidden ${
                    usesStanomer
                      ? "border-amber-500 shadow-xl shadow-amber-500/20 bg-gradient-to-br from-amber-50/50 via-white to-yellow-50/30 hover:border-amber-600 hover:shadow-2xl ring-2 ring-amber-400/50"
                      : isPartner 
                      ? "border-indigo-400/90 shadow-lg shadow-indigo-500/10 bg-gradient-to-br from-indigo-50/20 via-white to-blue-50/20 hover:border-indigo-500 hover:shadow-xl ring-1 ring-indigo-400/30"
                      : "border-slate-200/80 hover:border-blue-400 hover:shadow-xl hover:shadow-blue-500/5"
                  }`}
                >
                  {/* BADGES CONTAINER - STANOMER IS #1 HIGHEST PRIORITY */}
                  <div className="flex flex-col gap-1.5 mb-1">
                    {/* STANOMER USER BADGE (#1 TOP PRIORITY) */}
                    {usesStanomer && (
                      <div className="flex items-center justify-between bg-gradient-to-r from-amber-500 via-yellow-500 to-amber-600 text-white px-3.5 py-1.5 rounded-xl text-xs font-extrabold shadow-md shadow-amber-500/30">
                        <div className="flex items-center gap-1.5">
                          <Zap className="w-4 h-4 fill-yellow-100 text-white animate-pulse" />
                          <span>{t.stanomerBadge}</span>
                        </div>
                        <CheckCircle2 className="w-4 h-4 text-yellow-100" />
                      </div>
                    )}

                    {/* PARTNER BADGE */}
                    {isPartner && (
                      <div className="flex items-center justify-between bg-gradient-to-r from-indigo-500 via-blue-600 to-violet-600 text-white px-3.5 py-1.5 rounded-xl text-xs font-extrabold shadow-md shadow-indigo-500/20">
                        <div className="flex items-center gap-1.5">
                          <Sparkles className="w-3.5 h-3.5 fill-indigo-200 text-white" />
                          <span>{t.partnerBadge}</span>
                        </div>
                        <Award className="w-4 h-4 text-indigo-200" />
                      </div>
                    )}
                  </div>

                  <div className="space-y-3">
                    <div className="flex items-start justify-between gap-3">
                      <div className="flex items-center gap-3">
                        {agency.logo_url ? (
                          <div className="w-11 h-11 rounded-xl bg-white p-1 border border-slate-200 shadow-sm flex items-center justify-center flex-shrink-0 group-hover:scale-105 transition-transform overflow-hidden">
                            <img
                              src={agency.logo_url}
                              alt={agency.acente_adi}
                              className="w-full h-full object-contain"
                              onError={(e) => {
                                (e.currentTarget.parentElement as HTMLElement).style.display = "none";
                                const nextEl = (e.currentTarget.parentElement as HTMLElement).nextElementSibling;
                                if (nextEl) (nextEl as HTMLElement).classList.remove("hidden");
                              }}
                            />
                          </div>
                        ) : null}
                        <div className={`w-11 h-11 rounded-xl flex items-center justify-center group-hover:scale-105 transition-transform flex-shrink-0 ${
                          agency.logo_url ? "hidden" : ""
                        } ${
                          usesStanomer
                            ? "bg-gradient-to-br from-amber-400 to-yellow-500 text-white shadow-md shadow-amber-500/25"
                            : isPartner 
                            ? "bg-gradient-to-br from-indigo-100 to-blue-100 text-indigo-700 border border-indigo-300" 
                            : "bg-gradient-to-br from-blue-50 to-indigo-50 border border-blue-100 text-blue-600"
                        }`}>
                          <Building2 className="w-5 h-5" />
                        </div>

                        <div>
                          <h3 className="font-extrabold text-slate-900 text-lg leading-snug group-hover:text-blue-600 transition-colors">
                            {agency.acente_adi}
                          </h3>
                          {agency.sehir && (
                            <span className="inline-flex items-center gap-1 text-xs font-bold text-slate-500">
                              <MapPin className="w-3.5 h-3.5 text-rose-500" />
                              {agency.sehir}
                            </span>
                          )}
                        </div>
                      </div>

                      <div className="flex-shrink-0" title={t.verifiedBadge}>
                        <ShieldCheck className={`w-5 h-5 ${
                          usesStanomer ? "text-amber-500" : isPartner ? "text-indigo-500" : "text-emerald-500"
                        }`} />
                      </div>
                    </div>

                    {agency.resmi_tam_unvan && agency.resmi_tam_unvan !== agency.acente_adi && (
                      <p className="text-xs text-slate-500 font-medium line-clamp-1 italic bg-slate-50 p-2 rounded-lg border border-slate-100">
                        {agency.resmi_tam_unvan}
                      </p>
                    )}

                    {agency.adres && (
                      <p className="text-xs text-slate-600 flex items-start gap-1.5 leading-relaxed">
                        <MapPin className="w-3.5 h-3.5 text-slate-400 flex-shrink-0 mt-0.5" />
                        <span className="line-clamp-2">{agency.adres}</span>
                      </p>
                    )}
                  </div>

                  {/* SINGLE MASKED BUTTONS PER TYPE */}
                  <div className="pt-4 border-t border-slate-100 space-y-2.5 text-xs">
                    {/* Single Phone Button */}
                    {phoneCount > 0 && (
                      <button
                        type="button"
                        onClick={() => openPhoneModal(agency.acente_adi, agency.telefonlar!)}
                        className="w-full flex items-center justify-between px-3.5 py-2.5 rounded-xl bg-blue-50/80 hover:bg-blue-100 text-blue-700 font-bold border border-blue-200/60 transition group/btn cursor-pointer"
                      >
                        <div className="flex items-center gap-2">
                          <Phone className="w-4 h-4 text-blue-600 flex-shrink-0" />
                          <span>{t.showPhones}</span>
                          {phoneCount > 1 && (
                            <span className="text-[10px] bg-blue-600 text-white px-1.5 py-0.5 rounded-full font-extrabold">
                              {phoneCount}
                            </span>
                          )}
                        </div>
                        <span className="text-xs opacity-70 group-hover/btn:opacity-100 group-hover/btn:translate-x-0.5 transition-transform">
                          •••••••••
                        </span>
                      </button>
                    )}

                    {/* Single Email Button */}
                    {emailCount > 0 && (
                      <button
                        type="button"
                        onClick={() => openEmailModal(agency.acente_adi, agency.eposta_adresleri!)}
                        className="w-full flex items-center justify-between px-3.5 py-2.5 rounded-xl bg-violet-50/80 hover:bg-violet-100 text-violet-700 font-bold border border-violet-200/60 transition group/btn cursor-pointer"
                      >
                        <div className="flex items-center gap-2">
                          <Mail className="w-4 h-4 text-violet-600 flex-shrink-0" />
                          <span>{t.showEmails}</span>
                          {emailCount > 1 && (
                            <span className="text-[10px] bg-violet-600 text-white px-1.5 py-0.5 rounded-full font-extrabold">
                              {emailCount}
                            </span>
                          )}
                        </div>
                        <span className="text-xs opacity-70 group-hover/btn:opacity-100 group-hover/btn:translate-x-0.5 transition-transform">
                          ••••@••••.com
                        </span>
                      </button>
                    )}

                    {/* Websites */}
                    {websites.length > 0 && (
                      <div className="flex flex-wrap gap-1.5 pt-1">
                        {websites.map((web, idx) => (
                          <a
                            key={idx}
                            href={web.startsWith("http") ? web : "https://" + web}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-emerald-50 hover:bg-emerald-100 text-emerald-700 font-semibold border border-emerald-200/60 transition truncate max-w-full"
                          >
                            <Globe className="w-3.5 h-3.5 flex-shrink-0" />
                            <span className="truncate">{web.replace(/^https?:\/\//, '')}</span>
                            <ExternalLink className="w-3 h-3 flex-shrink-0 opacity-70" />
                          </a>
                        ))}
                      </div>
                    )}
                  </div>

                  {/* CTA + OPT-OUT FOOTER (non-partner, non-stanomer only) */}
                  {!isPartner && !usesStanomer && (
                    <div className="pt-3 mt-1 border-t border-slate-100/80 space-y-2">
                      <a
                        href="/agency-referral"
                        className="flex items-center justify-between w-full px-3.5 py-2.5 rounded-xl bg-gradient-to-r from-amber-50 to-yellow-50 hover:from-amber-100 hover:to-yellow-100 border border-amber-200/70 text-amber-800 font-bold text-xs transition group/cta"
                      >
                        <span className="flex items-center gap-1.5">
                          <Sparkles className="w-3.5 h-3.5 text-amber-500 group-hover/cta:animate-spin" />
                          <span>{t.ctaTitle}</span>
                        </span>
                        <span className="text-amber-600 group-hover/cta:translate-x-0.5 transition-transform text-[11px] font-extrabold">
                          {t.ctaButton}
                        </span>
                      </a>
                      <div className="text-center">
                        <a
                          href="/support"
                          className="inline-flex items-center gap-1 text-[10px] text-slate-400 hover:text-slate-600 transition underline underline-offset-2 decoration-dotted"
                        >
                          <span>{t.optOutText}</span>
                          <span className="font-semibold">{t.optOutLink}</span>
                        </a>
                      </div>
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        )}

        {!loading && !error && visibleAgencies.length < filteredAgencies.length && (
          <div className="text-center pt-8">
            <button
              onClick={() => setDisplayCount(prev => prev + 24)}
              className="inline-flex items-center gap-2 px-8 py-4 bg-slate-900 hover:bg-blue-600 text-white font-bold text-sm rounded-xl shadow-lg transition-all transform hover:-translate-y-0.5 active:translate-y-0 cursor-pointer"
            >
              <span>{t.loadMore}</span>
              <ArrowRight className="w-4 h-4" />
            </button>
          </div>
        )}
      </main>

      {/* CONTACT DETAILS POPOVER / DIALOG MODAL */}
      {modal.isOpen && (
        <div className="fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-[2000] flex items-center justify-center p-4 animate-in fade-in duration-200">
          <div 
            className="bg-white rounded-3xl max-w-md w-full p-6 sm:p-8 shadow-2xl border border-slate-100 space-y-6 relative animate-in zoom-in-95 duration-200"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-start justify-between gap-4 border-b border-slate-100 pb-4">
              <div className="flex items-center gap-3">
                <div className={`w-12 h-12 rounded-2xl flex items-center justify-center ${
                  modal.type === "phone" ? "bg-blue-100 text-blue-600" : "bg-violet-100 text-violet-600"
                }`}>
                  {modal.type === "phone" ? <Phone className="w-6 h-6" /> : <Mail className="w-6 h-6" />}
                </div>
                <div>
                  <h3 className="font-extrabold text-slate-900 text-lg">
                    {modal.type === "phone" ? t.phoneModalTitle : t.emailModalTitle}
                  </h3>
                  <p className="text-xs font-semibold text-slate-500">{modal.agencyName}</p>
                </div>
              </div>
              <button
                type="button"
                onClick={() => setModal({ ...modal, isOpen: false })}
                className="p-2 rounded-xl text-slate-400 hover:text-slate-600 hover:bg-slate-100 transition"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="space-y-3 max-h-60 overflow-y-auto pr-1">
              {modal.items.map((item, idx) => (
                <div
                  key={idx}
                  className="flex items-center justify-between p-3.5 bg-slate-50 rounded-2xl border border-slate-200/80 hover:bg-white hover:shadow-md transition-all gap-3"
                >
                  <span className="font-bold text-slate-800 text-sm tracking-wide truncate">
                    {item}
                  </span>

                  <div className="flex items-center gap-2 flex-shrink-0">
                    <button
                      type="button"
                      onClick={() => handleCopy(item)}
                      className="p-2 rounded-xl bg-slate-200/70 hover:bg-slate-300 text-slate-700 text-xs font-semibold flex items-center gap-1 transition"
                      title={t.copyAction}
                    >
                      {copiedItem === item ? (
                        <>
                          <Check className="w-3.5 h-3.5 text-emerald-600" />
                          <span className="text-emerald-700 font-bold">{t.copiedAction}</span>
                        </>
                      ) : (
                        <>
                          <Copy className="w-3.5 h-3.5" />
                          <span className="hidden sm:inline">{t.copyAction}</span>
                        </>
                      )}
                    </button>

                    {modal.type === "phone" ? (
                      <a
                        href={"tel:" + item.replace(/\s+/g, '')}
                        className="px-3 py-2 rounded-xl bg-blue-600 hover:bg-blue-700 text-white font-bold text-xs flex items-center gap-1.5 shadow-md shadow-blue-600/20 transition"
                      >
                        <Phone className="w-3.5 h-3.5" />
                        <span>{t.callAction}</span>
                      </a>
                    ) : (
                      <a
                        href={"mailto:" + item}
                        className="px-3 py-2 rounded-xl bg-violet-600 hover:bg-violet-700 text-white font-bold text-xs flex items-center gap-1.5 shadow-md shadow-violet-600/20 transition"
                      >
                        <Mail className="w-3.5 h-3.5" />
                        <span>{t.emailAction}</span>
                      </a>
                    )}
                  </div>
                </div>
              ))}
            </div>

            <div className="pt-2">
              <button
                type="button"
                onClick={() => setModal({ ...modal, isOpen: false })}
                className="w-full py-3 bg-slate-100 hover:bg-slate-200 text-slate-700 font-bold text-sm rounded-xl transition"
              >
                {t.close}
              </button>
            </div>
          </div>
        </div>
      )}

      <footer className="py-12 border-t border-slate-200/80 bg-white w-full mt-auto">
        <div className="max-w-7xl mx-auto px-6 text-center space-y-4">
          <div className="flex items-center justify-center gap-2 opacity-60">
            <img src="/assets/logo.png" alt="Stanomer Logo" className="w-6 h-6 object-contain" />
            <span className="font-bold text-sm tracking-tight text-slate-900">Stanomer</span>
          </div>
          <p className="text-slate-400 text-xs">
            © 2026 Stanomer. {t.footerRights}
          </p>
        </div>
      </footer>
    </div>
  );
}
