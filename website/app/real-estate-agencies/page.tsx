"use client";

import React, { useState, useEffect, useMemo } from "react";
import Link from "next/link";
import { 
  Building2, 
  Search, 
  MapPin, 
  Phone, 
  Mail, 
  Globe, 
  Filter, 
  CheckCircle2, 
  ArrowUpRight,
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
import { supabase, prodPublicClient } from "../../lib/supabaseClient";

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
        // Parallel fetch: profiles (for logos & Stanomer usage), referral partners (for official partner badges) and directory agencies
        const [profilesRes, partnersRes, agenciesRes] = await Promise.all([
          supabase
            .from("profiles")
            .select("email, company_name, full_name, logo_url, role"),
          supabase
            .from("agency_referral_partners")
            .select("agency_name, email"),
          supabase
            .from("view_clean_agencies")
            .select("*")
            .order("id", { ascending: true })
        ]);

        const partnerNames = new Set<string>();
        const partnerEmails = new Set<string>();
        (partnersRes.data || []).forEach((p: any) => {
          if (p.agency_name) partnerNames.add(p.agency_name.toLowerCase().trim());
          if (p.email) partnerEmails.add(p.email.toLowerCase().trim());
        });

        const stanomerUserNames = new Set<string>();
        const stanomerUserEmails = new Set<string>();
        const logoMap = new Map<string, string>();

        (profilesRes.data || []).forEach((p: any) => {
          const email = p.email ? p.email.toLowerCase().trim() : null;
          const company = p.company_name ? p.company_name.toLowerCase().trim() : null;
          const fullName = p.full_name ? p.full_name.toLowerCase().trim() : null;

          if (p.logo_url) {
            if (email) logoMap.set(email, p.logo_url);
            if (company) logoMap.set(company, p.logo_url);
          }

          // If profile has role='agency' or company_name, it's managing on Stanomer
          if (p.role === "agency" || company) {
            if (company) stanomerUserNames.add(company);
            if (fullName && p.role === "agency") stanomerUserNames.add(fullName);
            if (email) stanomerUserEmails.add(email);
          }
        });

        const checkMatch = (
          name: string | null | undefined,
          longName: string | null | undefined,
          emailsStr: string | null | undefined,
          namesSet: Set<string>,
          emailsSet: Set<string>
        ): boolean => {
          if (name && namesSet.has(name.toLowerCase().trim())) return true;
          if (longName && namesSet.has(longName.toLowerCase().trim())) return true;
          if (emailsStr) {
            const emails = emailsStr.split(",").map((e: string) => e.toLowerCase().trim());
            for (const em of emails) {
              if (emailsSet.has(em)) return true;
            }
          }
          return false;
        };

        let data = agenciesRes.data;
        let error = agenciesRes.error;

        // If current database has 0 agencies (e.g. empty dev database on localhost),
        // fallback to public production directory to ensure realistic listing
        if (error || !data || data.length === 0) {
          try {
            const prodRes = await prodPublicClient
              .from("view_clean_agencies")
              .select("*")
              .order("id", { ascending: true });
            if (prodRes.data && prodRes.data.length > 0) {
              data = prodRes.data;
              error = null;
            }
          } catch (e) {
            console.warn("Production directory public fallback error:", e);
          }
        }

        if (error) {
          console.error("Supabase view query error, trying fallback:", error);
          const { data: rawAgencies, error: rawError } = await supabase
            .from("agencies")
            .select("id, name, long_name, city, address, website, is_partner, uses_stanomer");

          if (rawError) throw rawError;

          const mapped = (rawAgencies || []).map((a: any) => {
            const isMatchedPartner = checkMatch(a.name, a.long_name, null, partnerNames, partnerEmails);
            const isMatchedStanomer = checkMatch(a.name, a.long_name, null, stanomerUserNames, stanomerUserEmails);
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
              is_partner: !!a.is_partner || isMatchedPartner,
              uses_stanomer: !!a.uses_stanomer || isMatchedStanomer,
              logo_url: logo || null
            };
          });
          setAgencies(mapped);
        } else {
          const enriched = (data || []).map((a: any) => {
            const isMatchedPartner = checkMatch(a.acente_adi, a.resmi_tam_unvan, a.eposta_adresleri, partnerNames, partnerEmails);
            const isMatchedStanomer = checkMatch(a.acente_adi, a.resmi_tam_unvan, a.eposta_adresleri, stanomerUserNames, stanomerUserEmails);

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
              is_partner: !!a.is_partner || isMatchedPartner,
              uses_stanomer: !!a.uses_stanomer || isMatchedStanomer,
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

            <div className="flex flex-wrap items-center gap-2.5">
              {/* PRIMARY #1 FILTER: Stanomer User Agency Toggle */}
              <label className={`inline-flex items-center gap-2 px-3.5 py-2 rounded-lg text-xs sm:text-sm font-medium border cursor-pointer transition select-none ${
                stanomerOnly 
                  ? "bg-amber-50 border-amber-300 text-amber-900 shadow-xs" 
                  : "bg-white border-slate-200 text-slate-700 hover:bg-slate-50"
              }`}>
                <input
                  type="checkbox"
                  checked={stanomerOnly}
                  onChange={(e) => setStanomerOnly(e.target.checked)}
                  className="rounded border-slate-300 text-amber-600 focus:ring-amber-500"
                />
                <Zap className={`w-3.5 h-3.5 ${stanomerOnly ? "text-amber-600 fill-amber-500" : "text-slate-400"}`} />
                <span>{t.filterStanomer}</span>
              </label>

              {/* SECONDARY #2 FILTER: Partner Only Toggle */}
              <label className={`inline-flex items-center gap-2 px-3.5 py-2 rounded-lg text-xs sm:text-sm font-medium border cursor-pointer transition select-none ${
                partnerOnly 
                  ? "bg-slate-900 border-slate-900 text-white shadow-xs" 
                  : "bg-white border-slate-200 text-slate-700 hover:bg-slate-50"
              }`}>
                <input
                  type="checkbox"
                  checked={partnerOnly}
                  onChange={(e) => setPartnerOnly(e.target.checked)}
                  className="rounded border-slate-300 text-slate-900 focus:ring-slate-900"
                />
                <Award className={`w-3.5 h-3.5 ${partnerOnly ? "text-amber-400" : "text-slate-400"}`} />
                <span>{t.filterPartner}</span>
              </label>

              {(searchQuery || selectedCity || partnerOnly || stanomerOnly) && (
                <button
                  type="button"
                  onClick={resetFilters}
                  className="inline-flex items-center gap-1.5 px-3 py-2 rounded-lg text-xs sm:text-sm font-medium text-slate-600 hover:text-slate-900 hover:bg-slate-100 border border-slate-200 transition cursor-pointer"
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
                  className={`bg-white rounded-xl p-5 sm:p-6 border transition-all duration-200 flex flex-col justify-between space-y-4 group relative ${
                    usesStanomer
                      ? "border-amber-300 shadow-sm hover:border-amber-400 hover:shadow-md ring-1 ring-amber-200/60"
                      : isPartner 
                      ? "border-slate-300 shadow-sm hover:border-slate-400 hover:shadow-md"
                      : "border-slate-200 hover:border-slate-300 hover:shadow-md shadow-xs"
                  }`}
                >
                  {/* BADGES CONTAINER */}
                  {(usesStanomer || isPartner) && (
                    <div className="flex flex-wrap items-center gap-2">
                      {usesStanomer && (
                        <div className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-md text-xs font-semibold bg-amber-50 text-amber-900 border border-amber-200/80">
                          <Zap className="w-3.5 h-3.5 text-amber-600 fill-amber-500" />
                          <span>{t.stanomerBadge}</span>
                        </div>
                      )}

                      {isPartner && (
                        <div className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-md text-xs font-semibold bg-slate-900 text-white">
                          <Award className="w-3.5 h-3.5 text-amber-400" />
                          <span>{t.partnerBadge}</span>
                        </div>
                      )}
                    </div>
                  )}

                  <div className="space-y-2.5">
                    <div className="flex items-start justify-between gap-3">
                      <div className="flex items-center gap-3 min-w-0">
                        {agency.logo_url ? (
                          <div className="w-10 h-10 rounded-lg bg-white p-1 border border-slate-200 shadow-xs flex items-center justify-center flex-shrink-0 overflow-hidden">
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
                        <div className={`w-10 h-10 rounded-lg flex items-center justify-center flex-shrink-0 bg-slate-50 border border-slate-200 text-slate-500 ${
                          agency.logo_url ? "hidden" : ""
                        }`}>
                          <Building2 className="w-5 h-5 text-slate-500" />
                        </div>

                        <div className="min-w-0">
                          <h3 className="font-semibold text-slate-900 text-base leading-snug group-hover:text-blue-600 transition-colors truncate" title={agency.acente_adi}>
                            {agency.acente_adi}
                          </h3>
                          {agency.sehir && (
                            <span className="inline-flex items-center gap-1 text-xs text-slate-500 mt-0.5">
                              <MapPin className="w-3.5 h-3.5 text-slate-400" />
                              {agency.sehir}
                            </span>
                          )}
                        </div>
                      </div>

                      <div className="flex-shrink-0 pt-0.5" title={t.verifiedBadge}>
                        <CheckCircle2 className="w-4 h-4 text-emerald-600" />
                      </div>
                    </div>

                    {agency.resmi_tam_unvan && agency.resmi_tam_unvan !== agency.acente_adi && (
                      <p className="text-xs text-slate-500 font-normal line-clamp-1">
                        {agency.resmi_tam_unvan}
                      </p>
                    )}

                    {agency.adres && (
                      <p className="text-xs text-slate-500 flex items-start gap-1.5 leading-relaxed">
                        <MapPin className="w-3.5 h-3.5 text-slate-400 flex-shrink-0 mt-0.5" />
                        <span className="line-clamp-2">{agency.adres}</span>
                      </p>
                    )}
                  </div>

                  {/* ACTION BUTTONS (PHONE, EMAIL, WEBSITES) */}
                  <div className="pt-3 border-t border-slate-100 space-y-2 text-xs">
                    {/* Single Phone Button */}
                    {phoneCount > 0 && (
                      <button
                        type="button"
                        onClick={() => openPhoneModal(agency.acente_adi, agency.telefonlar!)}
                        className="w-full flex items-center justify-between px-3 py-2 rounded-lg bg-white hover:bg-slate-50 text-slate-700 hover:text-slate-900 border border-slate-200 hover:border-slate-300 font-medium transition cursor-pointer group/btn"
                      >
                        <div className="flex items-center gap-2">
                          <Phone className="w-3.5 h-3.5 text-slate-500 group-hover/btn:text-blue-600 transition-colors" />
                          <span>{t.showPhones}</span>
                          {phoneCount > 1 && (
                            <span className="text-[10px] bg-slate-100 group-hover/btn:bg-slate-200 text-slate-600 px-1.5 py-0.5 rounded font-medium">
                              {phoneCount}
                            </span>
                          )}
                        </div>
                        <span className="text-[11px] text-slate-400 group-hover/btn:text-slate-600 font-normal">
                          {t.callAction} →
                        </span>
                      </button>
                    )}

                    {/* Single Email Button */}
                    {emailCount > 0 && (
                      <button
                        type="button"
                        onClick={() => openEmailModal(agency.acente_adi, agency.eposta_adresleri!)}
                        className="w-full flex items-center justify-between px-3 py-2 rounded-lg bg-white hover:bg-slate-50 text-slate-700 hover:text-slate-900 border border-slate-200 hover:border-slate-300 font-medium transition cursor-pointer group/btn"
                      >
                        <div className="flex items-center gap-2">
                          <Mail className="w-3.5 h-3.5 text-slate-500 group-hover/btn:text-violet-600 transition-colors" />
                          <span>{t.showEmails}</span>
                          {emailCount > 1 && (
                            <span className="text-[10px] bg-slate-100 group-hover/btn:bg-slate-200 text-slate-600 px-1.5 py-0.5 rounded font-medium">
                              {emailCount}
                            </span>
                          )}
                        </div>
                        <span className="text-[11px] text-slate-400 group-hover/btn:text-slate-600 font-normal">
                          {t.emailAction} →
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
                            className="inline-flex items-center gap-1.5 px-2.5 py-1.5 rounded-lg bg-slate-50 hover:bg-slate-100 text-slate-600 hover:text-slate-900 border border-slate-200 hover:border-slate-300 text-xs font-medium transition truncate max-w-full group/web"
                          >
                            <Globe className="w-3.5 h-3.5 text-slate-400 group-hover/web:text-blue-600 flex-shrink-0 transition-colors" />
                            <span className="truncate">{web.replace(/^https?:\/\//, '').replace(/\/$/, '')}</span>
                            <ArrowUpRight className="w-3 h-3 text-slate-400 group-hover/web:text-slate-600 flex-shrink-0 opacity-70 group-hover/web:opacity-100 transition" />
                          </a>
                        ))}
                      </div>
                    )}
                  </div>

                  {/* CTA + OPT-OUT FOOTER (non-partner, non-stanomer only) */}
                  {!isPartner && !usesStanomer && (
                    <div className="pt-3 border-t border-slate-100 space-y-2">
                      <Link
                        href="/agencies"
                        className="flex items-center justify-between w-full px-3 py-2 rounded-lg bg-slate-50 hover:bg-slate-100 border border-slate-200/80 text-slate-700 hover:text-slate-900 font-medium text-xs transition-colors group/cta"
                      >
                        <span className="flex items-center gap-1.5 text-slate-600">
                          <Building2 className="w-3.5 h-3.5 text-slate-400 group-hover/cta:text-slate-600" />
                          <span>{t.ctaTitle}</span>
                        </span>
                        <span className="inline-flex items-center gap-1 text-blue-600 group-hover/cta:text-blue-700 font-semibold text-[11px]">
                          {t.ctaButton}
                          <ArrowUpRight className="w-3 h-3 transition-transform group-hover/cta:translate-x-0.5 group-hover/cta:-translate-y-0.5" />
                        </span>
                      </Link>
                      <div className="text-center pt-0.5">
                        <Link
                          href="/support"
                          className="inline-flex items-center gap-1 text-[11px] text-slate-400 hover:text-slate-600 transition"
                        >
                          <span>{t.optOutText}</span>
                          <span className="underline underline-offset-2">{t.optOutLink}</span>
                        </Link>
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
        <div className="fixed inset-0 bg-slate-900/50 backdrop-blur-xs z-[2000] flex items-center justify-center p-4 animate-in fade-in duration-150">
          <div 
            className="bg-white rounded-xl max-w-md w-full p-6 shadow-xl border border-slate-200 space-y-5 relative animate-in zoom-in-95 duration-150"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-start justify-between gap-4 border-b border-slate-100 pb-4">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-lg flex items-center justify-center bg-slate-100 text-slate-700 border border-slate-200/80">
                  {modal.type === "phone" ? <Phone className="w-5 h-5 text-slate-600" /> : <Mail className="w-5 h-5 text-slate-600" />}
                </div>
                <div>
                  <h3 className="font-semibold text-slate-900 text-base">
                    {modal.type === "phone" ? t.phoneModalTitle : t.emailModalTitle}
                  </h3>
                  <p className="text-xs text-slate-500 font-medium">{modal.agencyName}</p>
                </div>
              </div>
              <button
                type="button"
                onClick={() => setModal({ ...modal, isOpen: false })}
                className="p-1.5 rounded-lg text-slate-400 hover:text-slate-600 hover:bg-slate-100 transition cursor-pointer"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <div className="space-y-2 max-h-60 overflow-y-auto pr-1">
              {modal.items.map((item, idx) => (
                <div
                  key={idx}
                  className="flex items-center justify-between p-3 bg-slate-50 rounded-lg border border-slate-200/80 hover:bg-white hover:border-slate-300 transition-colors gap-3"
                >
                  <span className="font-medium text-slate-800 text-sm tracking-normal truncate">
                    {item}
                  </span>

                  <div className="flex items-center gap-1.5 flex-shrink-0">
                    <button
                      type="button"
                      onClick={() => handleCopy(item)}
                      className="px-2.5 py-1.5 rounded-md bg-white hover:bg-slate-100 border border-slate-200 text-slate-600 hover:text-slate-900 text-xs font-medium flex items-center gap-1 transition cursor-pointer"
                      title={t.copyAction}
                    >
                      {copiedItem === item ? (
                        <>
                          <Check className="w-3.5 h-3.5 text-emerald-600" />
                          <span className="text-emerald-700 font-semibold">{t.copiedAction}</span>
                        </>
                      ) : (
                        <>
                          <Copy className="w-3.5 h-3.5 text-slate-400" />
                          <span className="hidden sm:inline">{t.copyAction}</span>
                        </>
                      )}
                    </button>

                    {modal.type === "phone" ? (
                      <a
                        href={"tel:" + item.replace(/\s+/g, '')}
                        className="px-3 py-1.5 rounded-md bg-slate-900 hover:bg-slate-800 text-white font-medium text-xs flex items-center gap-1.5 transition"
                      >
                        <Phone className="w-3 h-3 text-slate-300" />
                        <span>{t.callAction}</span>
                      </a>
                    ) : (
                      <a
                        href={"mailto:" + item}
                        className="px-3 py-1.5 rounded-md bg-slate-900 hover:bg-slate-800 text-white font-medium text-xs flex items-center gap-1.5 transition"
                      >
                        <Mail className="w-3 h-3 text-slate-300" />
                        <span>{t.emailAction}</span>
                      </a>
                    )}
                  </div>
                </div>
              ))}
            </div>

            <div className="pt-1">
              <button
                type="button"
                onClick={() => setModal({ ...modal, isOpen: false })}
                className="w-full py-2.5 bg-slate-100 hover:bg-slate-200 text-slate-700 font-medium text-sm rounded-lg transition cursor-pointer"
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
