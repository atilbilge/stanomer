"use client";

import React, { useState, useEffect, useMemo, useRef } from "react";
import { useParams, useRouter } from "next/navigation";
import Link from "next/link";
import { useLanguage, Language } from "../../../components/LanguageProvider";
import { supabase, prodPublicClient } from "../../../lib/supabaseClient";
import {
  TRANSACTION_TYPES,
  PROPERTY_TYPES,
  ROOM_STRUCTURES,
  HEATING_TYPES,
  getDictLabel,
} from "../../../lib/serbianRealEstateDict";
import {
  Building2,
  MapPin,
  Phone,
  Mail,
  ShieldCheck,
  Search,
  Euro,
  Maximize2,
  Layers,
  X,
  ChevronLeft,
  ChevronRight,
  ExternalLink,
  Rss,
  Heart,
  ArrowRight,
  MessageCircle,
  ArrowUpRight,
  Send,
  CheckCircle2,
  AlertCircle,
  Home,
  Calendar,
  SlidersHorizontal,
  RotateCcw,
  Check,
  Menu,
} from "lucide-react";

type ShowcaseTemplate =
  | "stanomer_modern"
  | "quiet_luxury"
  | "minimal_light"
  | "kolm_dark"
  | "lumira"
  | "aldervik"
  | "sage"
  | "onyx_dark";

type ShowcasePalette =
  | "royal_blue"
  | "champagne_gold"
  | "emerald_prestige"
  | "burgundy_classic"
  | "kolm_mint"
  | "lumira_coral"
  | "aldervik_amber"
  | "sage_terracotta"
  | "onyx_brass";
type ShowcaseRadius = "sharp" | "subtle" | "rounded" | "pill";
type ContactChannels = "both" | "whatsapp" | "viber" | "none";

interface ShowcaseImage {
  id: string;
  url: string;
  order_index: number;
  is_cover: boolean;
}

interface ShowcaseListing {
  id: string;
  external_ref: string | null;
  title: string;
  description: string | null;
  transaction_type: string;
  property_type: string;
  price: number;
  currency: string;
  area_sqm: number | null;
  room_count: string | null;
  floor: string | null;
  total_floors: number | null;
  heating_type: string | null;
  condition: string | null;
  furnishing: string | null;
  city: string;
  municipality: string | null;
  neighborhood: string | null;
  address: string | null;
  amenities: string[] | null;
  created_at?: string;
  listing_images?: ShowcaseImage[];
}

interface AgencyInfo {
  id: string;
  name: string;
  phone: string;
  email: string;
  logoUrl: string;
  city: string;
  address: string;
  description?: string;
}

const SHOWCASE_LANG_META: Record<Language, { code: Language; short: string; label: string }> = {
  SR_LAT: { code: "SR_LAT", short: "SR", label: "SR (Latinica)" },
  SR_CYR: { code: "SR_CYR", short: "СР", label: "СР (Ћирилица)" },
  EN: { code: "EN", short: "EN", label: "EN (English)" },
  RU: { code: "RU", short: "RU", label: "RU (Русский)" },
  TR: { code: "TR", short: "TR", label: "TR (Türkçe)" },
};


const PALETTE_TOKENS: Record<
  ShowcasePalette,
  {
    primary: string;
    headerGradient: string;
    badgeBg: string;
    badgeText: string;
  }
> = {
  royal_blue: {
    primary: "#2563eb",
    headerGradient: "from-slate-900 via-slate-900 to-blue-950",
    badgeBg: "bg-blue-50 text-blue-700 border-blue-200",
    badgeText: "text-blue-700",
  },
  champagne_gold: {
    primary: "#003c52",
    headerGradient: "from-[#090B0E] via-[#0d151c] to-[#003c52]",
    badgeBg: "bg-amber-50 text-[#003c52] border-[#c8a97e]",
    badgeText: "text-[#003c52]",
  },
  emerald_prestige: {
    primary: "#059669",
    headerGradient: "from-slate-900 via-emerald-950 to-teal-950",
    badgeBg: "bg-emerald-50 text-emerald-800 border-emerald-200",
    badgeText: "text-emerald-700",
  },
  burgundy_classic: {
    primary: "#be123c",
    headerGradient: "from-slate-950 via-rose-950 to-slate-900",
    badgeBg: "bg-rose-50 text-rose-800 border-rose-200",
    badgeText: "text-rose-700",
  },
  kolm_mint: {
    primary: "#5EF0B8",
    headerGradient: "from-[#111315] via-[#212427] to-[#2A2E32]",
    badgeBg: "bg-emerald-950/60 text-[#5EF0B8] border-[#5EF0B8]/30",
    badgeText: "text-[#5EF0B8]",
  },
  lumira_coral: {
    primary: "#FF6B5A",
    headerGradient: "from-[#164A6E] via-[#1E5D88] to-[#123B58]",
    badgeBg: "bg-rose-50 text-[#FF6B5A] border-[#FF6B5A]/30",
    badgeText: "text-[#FF6B5A]",
  },
  aldervik_amber: {
    primary: "#FFB020",
    headerGradient: "from-[#111A27] via-[#1C293D] to-[#2B3B52]",
    badgeBg: "bg-amber-50 text-[#9E6500] border-[#FFB020]/40",
    badgeText: "text-[#9E6500]",
  },
  sage_terracotta: {
    primary: "#D9663B",
    headerGradient: "from-[#162E25] via-[#24473A] to-[#1C372D]",
    badgeBg: "bg-orange-50 text-[#D9663B] border-[#D9663B]/30",
    badgeText: "text-[#D9663B]",
  },
  onyx_brass: {
    primary: "#D4B26A",
    headerGradient: "from-[#080809] via-[#0F0F10] to-[#1E1E22]",
    badgeBg: "bg-amber-950/40 text-[#D4B26A] border-[#D4B26A]/30",
    badgeText: "text-[#D4B26A]",
  },
};

const UI_TEXT: Record<
  Language,
  {
    verifiedBadge: string;
    luxuryEyebrow: string;
    luxurySubtitle: string;
    allTransactions: string;
    saleFilter: string;
    rentFilter: string;
    allTypes: string;
    searchPlaceholder: string;
    activeListings: string;
    noListingsTitle: string;
    noListingsDesc: string;
    callAgency: string;
    emailAgency: string;
    listPropertyBtn: string;
    viewDetails: string;
    perMonth: string;
    rooms: string;
    floor: string;
    heating: string;
    refCode: string;
    descriptionTitle: string;
    poweredBy: string;
    agencyHubLink: string;
    // Owner Consignment Form
    ownerFormBadge: string;
    ownerFormTitle: string;
    ownerFormDesc: string;
    ownerTxLegend: string;
    ownerPropTypeLabel: string;
    ownerLocationLabel: string;
    ownerLocationPlaceholder: string;
    ownerAreaLabel: string;
    ownerPriceLabel: string;
    ownerNameLabel: string;
    ownerPhoneLabel: string;
    ownerEmailLabel: string;
    ownerNotesLabel: string;
    ownerNotesPlaceholder: string;
    ownerSubmitBtn: string;
    ownerSubmitting: string;
    ownerSuccessMsg: string;
    ownerErrorMsg: string;
    // Standard Footer
    footerAboutDesc: string;
    footerContactHeading: string;
    footerAddressLabel: string;
    footerQuickLinksHeading: string;
    footerMapLink: string;
    // Floating Contact
    floatingTitle: string;
    floatingBothDesc: string;
    floatingWhatsappDesc: string;
    floatingViberDesc: string;
    // Viewing Request
    viewingBtn: string;
    viewingModalTitle: string;
    viewingModalDesc: string;
    viewingPreferredTimeLabel: string;
    viewingPreferredTimePlaceholder: string;
    viewingSubmitBtn: string;
    viewingSuccessMsg: string;
    viewingInitialComment: string;
    systemAuthor: string;
    // Advanced Filters
    advancedFiltersBtn: string;
    hideFiltersBtn: string;
    resetFilters: string;
    priceRange: string;
    minPrice: string;
    maxPrice: string;
    areaRange: string;
    minArea: string;
    maxArea: string;
    roomStructure: string;
    allRooms: string;
    allLocations: string;
    sortBy: string;
    sortNewest: string;
    sortPriceAsc: string;
    sortPriceDesc: string;
    sortAreaDesc: string;
    featuresLabel: string;
    featElevator: string;
    featBalcony: string;
    featParking: string;
    featAc: string;
    featFurnished: string;
    featNewBuild: string;
    closeBtn: string;
  }
> = {
  TR: {
    closeBtn: "Kapat",
    verifiedBadge: "Doğrulanmış Partner Portföyü",
    luxuryEyebrow: "SEÇKİN GAYRİMENKUL KOLEKSİYONU",
    luxurySubtitle:
      "Mimari karakteri olan seçkin konutlar, ticari mülkler ve yatırım fırsatları.",
    allTransactions: "Tümü (Satılık & Kiralık)",
    saleFilter: "Satılık",
    rentFilter: "Kiralık",
    allTypes: "Tüm Emlak Tipleri",
    searchPlaceholder: "İlan başlığı, semt (Opština / Naselje) veya kod ara...",
    activeListings: "Aktif İlan",
    noListingsTitle: "Henüz Aktif İlan Bulunmuyor",
    noListingsDesc:
      "Filtrelerinizi değiştirebilir veya doğrudan acente ile iletişime geçebilirsiniz.",
    callAgency: "Hemen Ara",
    emailAgency: "E-posta",
    listPropertyBtn: "Mülkünüzü Satın / Kiralayın",
    viewDetails: "İncele",
    perMonth: "/ay",
    rooms: "Oda Yapısı",
    floor: "Kat",
    heating: "Isıtma",
    refCode: "İlan Kodu",
    descriptionTitle: "İlan Açıklaması",
    poweredBy: "Stanomer Agency Hub altyapısıyla çalışmaktadır.",
    agencyHubLink: "Acente Yönetim Paneli",
    ownerFormBadge: "Mülk Sahipleri İçin",
    ownerFormTitle: "Mülkünüzü Bizimle Kiralayın veya Satın",
    ownerFormDesc:
      "Gayrimenkulünüzün bilgilerini bırakın; uzman danışmanlarımız değerleme ve pazarlama süreci için sizinle iletişime geçsin.",
    ownerTxLegend: "İşlem Türü",
    ownerPropTypeLabel: "Gayrimenkul Tipi",
    ownerLocationLabel: "Şehir / Semt / Sokak",
    ownerLocationPlaceholder: "Örn: Beograd, Vračar, Krušedolska",
    ownerAreaLabel: "Metrekare (m²)",
    ownerPriceLabel: "Beklenen Fiyat (EUR)",
    ownerNameLabel: "Adınız Soyadınız",
    ownerPhoneLabel: "Telefon Numaranız",
    ownerEmailLabel: "E-posta Adresiniz (Opsiyonel)",
    ownerNotesLabel: "Mülk Hakkında Ek Bilgiler",
    ownerNotesPlaceholder: "Kat, oda sayısı, eşya durumu veya özel notlarınız...",
    ownerSubmitBtn: "Mülk Bilgilerini Acenteye Gönder",
    ownerSubmitting: "Gönderiliyor...",
    ownerSuccessMsg:
      "Talebiniz acentenin e-posta adresine başarıyla iletildi! En kısa sürede sizinle iletişime geçilecektir.",
    ownerErrorMsg: "Gönderim sırasında bir hata oluştu. Lütfen tekrar deneyin.",
    footerAboutDesc:
      "Lisanslı gayrimenkul danışmanlığı, profesyonel portföy yönetimi ve güvenli alım-satım & kiralama hizmetleri.",
    footerContactHeading: "İletişim & Ofis Bilgileri",
    footerAddressLabel: "Ofis Adresi",
    footerQuickLinksHeading: "Hızlı Menü",
    footerMapLink: "Haritada Gör",
    floatingTitle: "Hızlı İletişim",
    floatingBothDesc: "WhatsApp ve Viber üzerinden doğrudan acentemize ulaşabilirsiniz.",
    floatingWhatsappDesc: "WhatsApp üzerinden doğrudan acentemize ulaşabilirsiniz.",
    floatingViberDesc: "Viber üzerinden doğrudan acentemize ulaşabilirsiniz.",
    viewingBtn: "Randevu Al / Yer Görme Talebi",
    viewingModalTitle: "İlan İçin Yer Görme Randevusu",
    viewingModalDesc: "İlanı yerinde incelemek veya danışmanımızla görüşmek için bilgilerinizi iletin.",
    viewingPreferredTimeLabel: "Tercih Ettiğiniz Gün / Saat veya Notunuz",
    viewingPreferredTimePlaceholder: "Örn: Hafta içi saat 17:00'den sonra uygunum...",
    viewingSubmitBtn: "Randevu Talebini Gönder",
    viewingSuccessMsg: "Randevu talebiniz acenteye iletildi! Danışmanımız en kısa sürede sizinle iletişime geçecektir.",
    viewingInitialComment: "Vitrin sitesinden yer görme randevu talebi gönderildi",
    systemAuthor: "Sistem",
    advancedFiltersBtn: "Gelişmiş Filtreler",
    hideFiltersBtn: "Filtreleri Gizle",
    resetFilters: "Filtreleri Temizle",
    priceRange: "Fiyat Aralığı",
    minPrice: "Min Fiyat (€)",
    maxPrice: "Max Fiyat (€)",
    areaRange: "Metrekare",
    minArea: "Min m²",
    maxArea: "Max m²",
    roomStructure: "Oda Sayısı",
    allRooms: "Tüm Odalar",
    allLocations: "Tüm Bölgeler",
    sortBy: "Sıralama",
    sortNewest: "En Yeni İlanlar",
    sortPriceAsc: "Fiyat: Düşükten Yükseğe",
    sortPriceDesc: "Fiyat: Yüksekten Düşüğe",
    sortAreaDesc: "Metrekare: En Büyük",
    featuresLabel: "Öne Çıkan Özellikler",
    featElevator: "Asansör",
    featBalcony: "Teras / Balkon",
    featParking: "Otopark / Garaj",
    featAc: "Klima",
    featFurnished: "Eşyalı",
    featNewBuild: "Yeni Bina",
  },
  EN: {
    closeBtn: "Close",
    verifiedBadge: "Verified Partner Portfolio",
    luxuryEyebrow: "CURATED ARCHITECTURAL PORTFOLIO",
    luxurySubtitle:
      "Distinguished residences, penthouses, and investment properties in prime enclaves.",
    allTransactions: "All (Sale & Rent)",
    saleFilter: "For Sale",
    rentFilter: "For Rent",
    allTypes: "All Property Types",
    searchPlaceholder: "Search title, municipality, neighborhood or ref...",
    activeListings: "Active Listings",
    noListingsTitle: "No Active Listings Found",
    noListingsDesc:
      "Try adjusting your filters or contact the agency directly.",
    callAgency: "Call Agency",
    emailAgency: "Email",
    listPropertyBtn: "List Your Property",
    viewDetails: "View",
    perMonth: "/month",
    rooms: "Rooms",
    floor: "Floor",
    heating: "Heating",
    refCode: "Ref Code",
    descriptionTitle: "Property Description",
    poweredBy: "Powered by Stanomer Agency Hub & Multi-Portal XML Engine.",
    agencyHubLink: "Agency Hub Panel",
    ownerFormBadge: "For Property Owners",
    ownerFormTitle: "Sell or Rent Your Property With Us",
    ownerFormDesc:
      "Submit your property details below and our advisors will contact you for valuation and marketing.",
    ownerTxLegend: "Transaction Type",
    ownerPropTypeLabel: "Property Type",
    ownerLocationLabel: "City / Municipality / Street",
    ownerLocationPlaceholder: "e.g. Belgrade, Vračar",
    ownerAreaLabel: "Area (m²)",
    ownerPriceLabel: "Expected Price (EUR)",
    ownerNameLabel: "Your Full Name",
    ownerPhoneLabel: "Phone Number",
    ownerEmailLabel: "Email Address (Optional)",
    ownerNotesLabel: "Additional Property Details",
    ownerNotesPlaceholder: "Floor, rooms, furnishing, or special notes...",
    ownerSubmitBtn: "Send Property Details to Agency",
    ownerSubmitting: "Sending...",
    ownerSuccessMsg:
      "Your property inquiry has been sent directly to the agency! We will contact you shortly.",
    ownerErrorMsg: "Could not send your request. Please try again.",
    footerAboutDesc:
      "Licensed real estate brokerage, curated property portfolio, and transparent sales & rental advisory.",
    footerContactHeading: "Contact & Office Location",
    footerAddressLabel: "Office Address",
    footerQuickLinksHeading: "Quick Links",
    footerMapLink: "View on Map",
    floatingTitle: "Quick Contact",
    floatingBothDesc: "Reach our agency directly on WhatsApp & Viber.",
    floatingWhatsappDesc: "Reach our agency directly on WhatsApp.",
    floatingViberDesc: "Reach our agency directly on Viber.",
    viewingBtn: "Schedule a Viewing",
    viewingModalTitle: "Schedule an On-Site Viewing",
    viewingModalDesc: "Submit your contact details to book an on-site property tour with our advisor.",
    viewingPreferredTimeLabel: "Preferred Date / Time or Notes",
    viewingPreferredTimePlaceholder: "e.g. Available on weekdays after 5 PM...",
    viewingSubmitBtn: "Send Viewing Request",
    viewingSuccessMsg: "Your viewing request has been sent! Our advisor will contact you shortly.",
    viewingInitialComment: "Viewing request submitted via website",
    systemAuthor: "System",
    advancedFiltersBtn: "Advanced Filters",
    hideFiltersBtn: "Hide Filters",
    resetFilters: "Reset Filters",
    priceRange: "Price Range",
    minPrice: "Min Price (€)",
    maxPrice: "Max Price (€)",
    areaRange: "Area",
    minArea: "Min m²",
    maxArea: "Max m²",
    roomStructure: "Rooms",
    allRooms: "All Rooms",
    allLocations: "All Locations",
    sortBy: "Sort By",
    sortNewest: "Newest First",
    sortPriceAsc: "Price: Low to High",
    sortPriceDesc: "Price: High to Low",
    sortAreaDesc: "Area: Largest First",
    featuresLabel: "Key Features & Amenities",
    featElevator: "Elevator",
    featBalcony: "Terrace / Balcony",
    featParking: "Parking / Garage",
    featAc: "Air Conditioning",
    featFurnished: "Furnished",
    featNewBuild: "New Construction",
  },
  SR_LAT: {
    closeBtn: "Zatvori",
    verifiedBadge: "Verifikovani Portfolio Agencije",
    luxuryEyebrow: "EKSKLUZIVNA KOLEKCIJA NEKRETNINA",
    luxurySubtitle:
      "Pažljivo odabrani stanovi, luksuzne rezidencije i poslovni prostori na najtraženijim lokacijama.",
    allTransactions: "Sve (Prodaja i Izdavanje)",
    saleFilter: "Prodaja",
    rentFilter: "Izdavanje",
    allTypes: "Svi Tipovi Nekretnina",
    searchPlaceholder: "Pretražite naslov, opštinu, naselje ili šifru oglasa...",
    activeListings: "Aktivnih Oglasa",
    noListingsTitle: "Trenutno Nema Aktivnih Oglasa",
    noListingsDesc:
      "Promenite filtere pretrage ili direktno kontaktirajte agenciju.",
    callAgency: "Pozovi",
    emailAgency: "Imejl",
    listPropertyBtn: "Oglasite Vašu Nekretninu",
    viewDetails: "Pogledaj",
    perMonth: "/mesečno",
    rooms: "Struktura",
    floor: "Sprat",
    heating: "Grejanje",
    refCode: "Šifra",
    descriptionTitle: "Opis Nekretnine",
    poweredBy: "Pokreće Stanomer Agency Hub.",
    agencyHubLink: "Panel za Agencije",
    ownerFormBadge: "Za Vlasnike Nekretnina",
    ownerFormTitle: "Prodajte ili Izdajte Vašu Nekretninu Sa Nama",
    ownerFormDesc:
      "Pošaljite osnovne podatke o vašoj nekretnini i naši agenti će vas ubrzo kontaktirati radi procene i oglašavanja.",
    ownerTxLegend: "Tip Transakcije",
    ownerPropTypeLabel: "Tip Nekretnine",
    ownerLocationLabel: "Grad / Opština / Ulica",
    ownerLocationPlaceholder: "Npr. Beograd, Vračar, Krušedolska",
    ownerAreaLabel: "Kvadratura (m²)",
    ownerPriceLabel: "Okvirna Cena (EUR)",
    ownerNameLabel: "Vaše Ime i Prezime",
    ownerPhoneLabel: "Broj Telefona",
    ownerEmailLabel: "Imejl Adresa (Opciono)",
    ownerNotesLabel: "Dodatni Opis Nekretnine",
    ownerNotesPlaceholder: "Sprat, struktura, opremljenost ili napomena...",
    ownerSubmitBtn: "Pošalji Ponudu Agenciji",
    ownerSubmitting: "Slanje...",
    ownerSuccessMsg:
      "Vaša ponuda je uspešno poslata na imejl agencije! Naš tim će vas uskoro kontaktirati.",
    ownerErrorMsg: "Došlo je do greške pri slanju. Pokušajte ponovo.",
    footerAboutDesc:
      "Licencirana agencija za nekretnine, posredovanje u prodaji i izdavanju stambenih i poslovnih objekata.",
    footerContactHeading: "Kontakt Podaci i Adresa",
    footerAddressLabel: "Adresa Kancelarije",
    footerQuickLinksHeading: "Brzi Linkovi",
    footerMapLink: "Prikaži na mapi",
    floatingTitle: "Brzi Kontakt",
    floatingBothDesc: "Dostupni smo direktno putem WhatsApp-a i Viber-a.",
    floatingWhatsappDesc: "Dostupni smo direktno putem WhatsApp-a.",
    floatingViberDesc: "Dostupni smo direktno putem Viber-a.",
    viewingBtn: "Zakažite Razgledanje",
    viewingModalTitle: "Zahtev za Razgledanje Nekretnine",
    viewingModalDesc: "Ostavite Vaše podatke i naš agent će Vas kontaktirati radi dogovora termina obilaska.",
    viewingPreferredTimeLabel: "Željeni Datum / Vreme ili Napomena",
    viewingPreferredTimePlaceholder: "Npr: Odgovara mi radnim danima posle 17h...",
    viewingSubmitBtn: "Pošalji Zahtev za Razgledanje",
    viewingSuccessMsg: "Vaš zahtev za razgledanje je uspešno poslat! Naš agent će Vas uskoro kontaktirati.",
    viewingInitialComment: "Zahtev za razgledanje poslat sa sajta",
    systemAuthor: "Sistem",
    advancedFiltersBtn: "Detaljni Filteri",
    hideFiltersBtn: "Sakrij Filtere",
    resetFilters: "Poništi Filtere",
    priceRange: "Cenovni Raspon",
    minPrice: "Cena od (€)",
    maxPrice: "Cena do (€)",
    areaRange: "Kvadratura",
    minArea: "Od m²",
    maxArea: "Do m²",
    roomStructure: "Struktura",
    allRooms: "Sve Strukture",
    allLocations: "Sve Lokacije",
    sortBy: "Sortiranje",
    sortNewest: "Najnovije",
    sortPriceAsc: "Cena: Rastuće",
    sortPriceDesc: "Cena: Opadajuće",
    sortAreaDesc: "Kvadratura: Najveća",
    featuresLabel: "Karakteristike & Opremljenost",
    featElevator: "Lift",
    featBalcony: "Terasa / Balkon",
    featParking: "Parking / Garaža",
    featAc: "Klima",
    featFurnished: "Namešteno",
    featNewBuild: "Novogradnja",
  },
  SR_CYR: {
    closeBtn: "Затвори",
    verifiedBadge: "Верификовани Портфолио Агенције",
    luxuryEyebrow: "ЕКСКЛУЗИВНА КОЛЕКЦИЈА НЕКРЕТНИНА",
    luxurySubtitle:
      "Пажљиво одабрани станови, луксузне резиденције и пословни простори на најтраженијим локацијама.",
    allTransactions: "Све (Продаја и Издавање)",
    saleFilter: "Продаја",
    rentFilter: "Издавање",
    allTypes: "Сви Типови Некретнина",
    searchPlaceholder: "Претражите наслов, општину, насеље или шифру огласа...",
    activeListings: "Активних Огласа",
    noListingsTitle: "Тренутно Нема Активних Огласа",
    noListingsDesc:
      "Промените филтере претраге или директно контактирајте агенцију.",
    callAgency: "Позови",
    emailAgency: "Имејл",
    listPropertyBtn: "Огласите Вашу Некретнину",
    viewDetails: "Погледај",
    perMonth: "/месечно",
    rooms: "Структура",
    floor: "Спрат",
    heating: "Грејање",
    refCode: "Шифра",
    descriptionTitle: "Опис Некретнине",
    poweredBy: "Покреће Stanomer Agency Hub.",
    agencyHubLink: "Панел за Агенције",
    ownerFormBadge: "За Власнике Некретнина",
    ownerFormTitle: "Продајте или Издајте Вашу Некретнину Са Нама",
    ownerFormDesc:
      "Пошаљите основне податке о вашој некретнини и наши агенти ће вас убрзо контактирати ради процене и оглашавања.",
    ownerTxLegend: "Тип Трансакције",
    ownerPropTypeLabel: "Тип Некретнине",
    ownerLocationLabel: "Град / Општина / Улица",
    ownerLocationPlaceholder: "Нпр. Београд, Врачар, Крушедолска",
    ownerAreaLabel: "Квадратура (m²)",
    ownerPriceLabel: "Оквирна Цена (EUR)",
    ownerNameLabel: "Ваше Име и Презиме",
    ownerPhoneLabel: "Број Телефона",
    ownerEmailLabel: "Имејл Адреса (Опционо)",
    ownerNotesLabel: "Додатни Опис Некретнине",
    ownerNotesPlaceholder: "Спрат, структура, опремљеност или напомена...",
    ownerSubmitBtn: "Пошаљи Понуду Агенцији",
    ownerSubmitting: "Слање...",
    ownerSuccessMsg:
      "Ваша понуда је успешно послата на имејл агенције! Наш тим ће вас ускоро контактирати.",
    ownerErrorMsg: "Дошло је до грешке при слању. Покушајте поново.",
    footerAboutDesc:
      "Лиценцирана агенција за некретнине, посредовање у продаји и издавању стамбених и пословних објеката.",
    footerContactHeading: "Контакт Подаци и Адреса",
    footerAddressLabel: "Адреса Канцеларије",
    footerQuickLinksHeading: "Брзи Линкови",
    footerMapLink: "Прикажи на мапи",
    floatingTitle: "Брзи Контакт",
    floatingBothDesc: "Доступни смо директно путем WhatsApp-а и Viber-а.",
    floatingWhatsappDesc: "Доступни смо директно путем WhatsApp-а.",
    floatingViberDesc: "Доступни смо директно путем Viber-а.",
    viewingBtn: "Закажите Разгледање",
    viewingModalTitle: "Захтев за Разгледање Некретнине",
    viewingModalDesc: "Оставите Ваше податке и наш агент ће Вас контактирати ради договора термина обиласка.",
    viewingPreferredTimeLabel: "Жељени Датум / Време или Напомена",
    viewingPreferredTimePlaceholder: "Нпр: Одговара ми радним данима после 17ч...",
    viewingSubmitBtn: "Пошаљи Захтев за Разгледање",
    viewingSuccessMsg: "Ваш захтев за разгледање је успешно послат! Наш агент ће Вас ускоро контактирати.",
    viewingInitialComment: "Захтев за разгледање послат са сајта",
    systemAuthor: "Систем",
    advancedFiltersBtn: "Детаљни Филтери",
    hideFiltersBtn: "Сакриј Филтере",
    resetFilters: "Поништи Филтере",
    priceRange: "Ценовни Распон",
    minPrice: "Цена од (€)",
    maxPrice: "Цена до (€)",
    areaRange: "Квадратура",
    minArea: "Од м²",
    maxArea: "До м²",
    roomStructure: "Структура",
    allRooms: "Све Структуре",
    allLocations: "Све Локације",
    sortBy: "Сортирање",
    sortNewest: "Најновије",
    sortPriceAsc: "Цена: Растуће",
    sortPriceDesc: "Цена: Опадајуће",
    sortAreaDesc: "Квадратура: Највећа",
    featuresLabel: "Карактеристике & Опремљеност",
    featElevator: "Лифт",
    featBalcony: "Тераса / Балкон",
    featParking: "Паркинг / Гаража",
    featAc: "Клима",
    featFurnished: "Намештено",
    featNewBuild: "Новоградња",
  },
  RU: {
    closeBtn: "Закрыть",
    verifiedBadge: "Проверенное Портфолио Агентства",
    luxuryEyebrow: "ЭКСКЛЮЗИВНАЯ КОЛЛЕКЦИЯ НЕДВИЖИМОСТИ",
    luxurySubtitle:
      "Избранные резиденции, апартаменты и коммерческие объекты в лучших локациях.",
    allTransactions: "Все (Продажа и Аренда)",
    saleFilter: "Продажа",
    rentFilter: "Аренда",
    allTypes: "Все Типы Недвижимости",
    searchPlaceholder: "Поиск по заголовку, району или коду объекта...",
    activeListings: "Активных Объявлений",
    noListingsTitle: "Активных Объявлений Не Найдено",
    noListingsDesc:
      "Измените параметры фильтра или свяжитесь с агентством напрямую.",
    callAgency: "Позвонить",
    emailAgency: "Email",
    listPropertyBtn: "Сдать / Продать Объект",
    viewDetails: "Смотреть",
    perMonth: "/мес",
    rooms: "Структура",
    floor: "Этаж",
    heating: "Отопление",
    refCode: "Код",
    descriptionTitle: "Описание Объекта",
    poweredBy: "Витрина работает на базе Stanomer Agency Hub.",
    agencyHubLink: "Панель Агентства",
    ownerFormBadge: "Для Собственников",
    ownerFormTitle: "Сдайте или Продайте Вашу Недвижимость С Нами",
    ownerFormDesc:
      "Оставьте параметры вашего объекта, и наши специалисты свяжутся с вами для оценки и размещения.",
    ownerTxLegend: "Тип Сделки",
    ownerPropTypeLabel: "Тип Недвижимости",
    ownerLocationLabel: "Город / Район / Улица",
    ownerLocationPlaceholder: "Напр. Белград, Врачар",
    ownerAreaLabel: "Площадь (м²)",
    ownerPriceLabel: "Ожидаемая Цена (EUR)",
    ownerNameLabel: "Ваше Имя и Фамилия",
    ownerPhoneLabel: "Номер Телефона",
    ownerEmailLabel: "Email (Необязательно)",
    ownerNotesLabel: "Дополнительная Информация",
    ownerNotesPlaceholder: "Этаж, количество комнат, мебелировка...",
    ownerSubmitBtn: "Отправить Заявку Агентству",
    ownerSubmitting: "Отправка...",
    ownerSuccessMsg:
      "Ваша заявка успешно отправлена на email агентства! Мы свяжемся с вами в ближайшее время.",
    ownerErrorMsg: "Ошибка при отправке. Пожалуйста, попробуйте снова.",
    footerAboutDesc:
      "Лицензированное агентство недвижимости, профессиональное сопровождение сделок купли-продажи и аренды.",
    footerContactHeading: "Контакты и Адрес Офиса",
    footerAddressLabel: "Адрес Офиса",
    footerQuickLinksHeading: "Быстрые Ссылки",
    footerMapLink: "Показать на карте",
    floatingTitle: "Быстрая Связь",
    floatingBothDesc: "Свяжитесь с нашим агентством напрямую в WhatsApp и Viber.",
    floatingWhatsappDesc: "Свяжитесь с нашим агентством напрямую в WhatsApp.",
    floatingViberDesc: "Свяжитесь с нашим агентством напрямую в Viber.",
    viewingBtn: "Запросить Просмотр",
    viewingModalTitle: "Запрос на Просмотр Объекта",
    viewingModalDesc: "Оставьте контактные данные для согласования даты и времени просмотра с агентом.",
    viewingPreferredTimeLabel: "Желаемая Дата / Время или Заметка",
    viewingPreferredTimePlaceholder: "Например: Удобно в будни после 17:00...",
    viewingSubmitBtn: "Отправить Запрос на Просмотр",
    viewingSuccessMsg: "Ваш запрос на просмотр успешно отправлен! Наш агент свяжется с вами в ближайшее время.",
    viewingInitialComment: "Запрос на просмотр отправлен с сайта",
    systemAuthor: "Система",
    advancedFiltersBtn: "Расширенный Поиск",
    hideFiltersBtn: "Скрыть Фильтры",
    resetFilters: "Сбросить Фильтры",
    priceRange: "Диапазон Цен",
    minPrice: "От (€)",
    maxPrice: "До (€)",
    areaRange: "Площадь",
    minArea: "От м²",
    maxArea: "До м²",
    roomStructure: "Комнаты",
    allRooms: "Все Варианты",
    allLocations: "Все Районы",
    sortBy: "Сортировка",
    sortNewest: "Сначала Новые",
    sortPriceAsc: "Цена: По возрастанию",
    sortPriceDesc: "Цена: По убыванию",
    sortAreaDesc: "Площадь: По убыванию",
    featuresLabel: "Характеристики и Удобства",
    featElevator: "Лифт",
    featBalcony: "Терраса / Балкон",
    featParking: "Парковка / Гараж",
    featAc: "Кондиционер",
    featFurnished: "С мебелью",
    featNewBuild: "Новостройка",
  },
};

const DEMO_SHOWCASE_LISTINGS: ShowcaseListing[] = [
  {
    id: "demo-prop-001",
    external_ref: "BG-VR-101",
    title: "Luksuzan trosoban stan kod Hrama Svetog Save sa garažom",
    description:
      "Kompletno opremljen, svetao trosoban stan u novogradnji u neposrednoj blizini Hrama Svetog Save. Poseduje prostranu dnevnu sobu sa kaminom, dve spavaće sobe, dva kupatila, terasu i garažno mesto u zgradi.",
    transaction_type: "izdavanje",
    property_type: "apartment",
    price: 1250,
    currency: "EUR",
    area_sqm: 84,
    room_count: "3.0",
    floor: "3",
    total_floors: 6,
    heating_type: "cg",
    condition: "novogradnja",
    furnishing: "furnished",
    city: "Beograd",
    municipality: "Vračar",
    neighborhood: "Hram Svetog Save",
    address: "Krušedolska 14",
    amenities: ["elevator", "balcony", "parking", "garage"],
    listing_images: [
      {
        id: "img-101-1",
        url: "https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?auto=format&fit=crop&w=1200&q=80",
        order_index: 0,
        is_cover: true,
      },
      {
        id: "img-101-2",
        url: "https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?auto=format&fit=crop&w=1200&q=80",
        order_index: 1,
        is_cover: false,
      },
    ],
  },
  {
    id: "demo-prop-002",
    external_ref: "NS-GR-204",
    title: "Moderan dvosoban stan na Grbavici - Novogradnja",
    description:
      "Funkcionalan dvosoban stan na odličnoj lokaciji u Novom Sadu (Grbavica). Idealan za parove ili IT profesionalce. Niski troškovi održavanja, podno grejanje, velika terasa.",
    transaction_type: "izdavanje",
    property_type: "apartment",
    price: 650,
    currency: "EUR",
    area_sqm: 56,
    room_count: "2.0",
    floor: "2",
    total_floors: 5,
    heating_type: "underfloor",
    condition: "novogradnja",
    furnishing: "furnished",
    city: "Novi Sad",
    municipality: "Grad Novi Sad",
    neighborhood: "Grbavica",
    address: "Miše Dimitrijevića 42",
    amenities: ["elevator", "balcony", "intercom"],
    listing_images: [
      {
        id: "img-204-1",
        url: "https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=1200&q=80",
        order_index: 0,
        is_cover: true,
      },
    ],
  },
  {
    id: "demo-prop-003",
    external_ref: "BG-BW-309",
    title: "Ekskluzivan četvorosoban penthaus u Beogradu na vodi sa panoramom",
    description:
      "Reprezentativan penthaus sa privatnom terasom, panoramskim pogledom na reku Savu, recepcijom 24/7 i dva pripadajuća garažna mesta.",
    transaction_type: "prodaja",
    property_type: "apartment",
    price: 495000,
    currency: "EUR",
    area_sqm: 142,
    room_count: "4.0",
    floor: "18",
    total_floors: 20,
    heating_type: "cg",
    condition: "lux",
    furnishing: "furnished",
    city: "Beograd",
    municipality: "Savski Venac",
    neighborhood: "Beograd na vodi",
    address: "Bulevar Vudroa Vilsona 8",
    amenities: ["elevator", "balcony", "parking", "security", "garage"],
    listing_images: [
      {
        id: "img-309-1",
        url: "https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=1200&q=80",
        order_index: 0,
        is_cover: true,
      },
    ],
  },
  {
    id: "demo-prop-004",
    external_ref: "BG-DD-401",
    title: "Predivna porodična rezidencijalna vila na Dedinju sa bazenom",
    description:
      "Izuzetna samostojeća vila u najlepšem i najmirnijem delu Dedinja. Bazen, uređeno dvorište od 10 ari, velika garaža za 2 automobila, fitnes zona i letnja kuhinja.",
    transaction_type: "prodaja",
    property_type: "house",
    price: 850000,
    currency: "EUR",
    area_sqm: 360,
    room_count: "5.0+",
    floor: "PR+1+PK",
    total_floors: 3,
    heating_type: "gas",
    condition: "lux",
    furnishing: "semi_furnished",
    city: "Beograd",
    municipality: "Savski Venac",
    neighborhood: "Dedinje",
    address: "Tolstojeva",
    amenities: ["parking", "garage", "pool", "garden", "security"],
    listing_images: [
      {
        id: "img-401-1",
        url: "https://images.unsplash.com/photo-1613490493576-7fde63acd811?auto=format&fit=crop&w=1200&q=80",
        order_index: 0,
        is_cover: true,
      },
    ],
  },
  {
    id: "demo-prop-005",
    external_ref: "BG-SN-502",
    title: "Raskošna rezidencijalna kuća sa dvorištem na Senjaku",
    description:
      "Kompletno nameštena luksuzna kuća na Senjaku, idealna za diplomatska predstavništva ili veće porodice. Visoki plafoni, kamin, smart home sistem i prostrane terase.",
    transaction_type: "izdavanje",
    property_type: "house",
    price: 3800,
    currency: "EUR",
    area_sqm: 280,
    room_count: "5.0+",
    floor: "PR+1",
    total_floors: 2,
    heating_type: "gas",
    condition: "lux",
    furnishing: "furnished",
    city: "Beograd",
    municipality: "Savski Venac",
    neighborhood: "Senjak",
    address: "Sanje Živanovića",
    amenities: ["parking", "garage", "garden", "balcony", "security"],
    listing_images: [
      {
        id: "img-502-1",
        url: "https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=1200&q=80",
        order_index: 0,
        is_cover: true,
      },
    ],
  },
  {
    id: "demo-prop-006",
    external_ref: "BG-NBG-603",
    title: "Dizajnerski jednoiposoban stan u A-Bloku sa terasom",
    description:
      "Premium stan u najpopularnijem stambenom kompleksu Novog Beograda. Kompletno opremljen modernim nameštajem, ugradna bela tehnika, podzemna garaža.",
    transaction_type: "izdavanje",
    property_type: "apartment",
    price: 850,
    currency: "EUR",
    area_sqm: 48,
    room_count: "1.5",
    floor: "4",
    total_floors: 7,
    heating_type: "cg",
    condition: "novogradnja",
    furnishing: "furnished",
    city: "Beograd",
    municipality: "Novi Beograd",
    neighborhood: "Blok A (A-Blok)",
    address: "Uroša Martinovića 11",
    amenities: ["elevator", "balcony", "garage"],
    listing_images: [
      {
        id: "img-603-1",
        url: "https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?auto=format&fit=crop&w=1200&q=80",
        order_index: 0,
        is_cover: true,
      },
    ],
  },
  {
    id: "demo-prop-007",
    external_ref: "BG-DR-704",
    title: "Salonski troiposoban stan u srcu Donjeg Dorćola",
    description:
      "Autentičan salonski stan visine plafona 3.2m u predratnoj zgradi sa renoviranom fasadom. Dva balkona, dvostrano orijentisan, izuzetno svetao i miran.",
    transaction_type: "prodaja",
    property_type: "apartment",
    price: 265000,
    currency: "EUR",
    area_sqm: 96,
    room_count: "3.5",
    floor: "2",
    total_floors: 4,
    heating_type: "eg",
    condition: "renovirano",
    furnishing: "semi_furnished",
    city: "Beograd",
    municipality: "Stari Grad",
    neighborhood: "Dorćol",
    address: "Cara Dušana 58",
    amenities: ["balcony", "intercom", "basement"],
    listing_images: [
      {
        id: "img-704-1",
        url: "https://images.unsplash.com/photo-1502005229762-ee1b2b8ab00f?auto=format&fit=crop&w=1200&q=80",
        order_index: 0,
        is_cover: true,
      },
    ],
  },
  {
    id: "demo-prop-008",
    external_ref: "NS-PV-805",
    title: "Moderna nova kuća sa pogledom na Dunav i Frušku Goru",
    description:
      "Novosagrađena vila na obroncima Fruške Gore sa panoramskim pogledom na Novi Sad i Dunav. Plac 9 ari, toplotna pumpa, velika terasa, letnjikovac i zelenilo.",
    transaction_type: "prodaja",
    property_type: "house",
    price: 340000,
    currency: "EUR",
    area_sqm: 210,
    room_count: "4.0",
    floor: "PR+1",
    total_floors: 2,
    heating_type: "heat_pump",
    condition: "novogradnja",
    furnishing: "furnished",
    city: "Novi Sad",
    municipality: "Petrovaradin",
    neighborhood: "Popovica",
    address: "Fruškogorski put",
    amenities: ["parking", "garden", "balcony"],
    listing_images: [
      {
        id: "img-805-1",
        url: "https://images.unsplash.com/photo-1580587771525-78b9dba3b914?auto=format&fit=crop&w=1200&q=80",
        order_index: 0,
        is_cover: true,
      },
    ],
  },
  {
    id: "demo-prop-009",
    external_ref: "BG-ZV-906",
    title: "Nov trosoban stan kod Đeram pijace - Bulevar",
    description:
      "Sveže useljiva novogradnja. Dve spavaće sobe, prostrana terasa, klima uređaj u svakoj sobi, optički internet, mogućnost zakupa parking mesta.",
    transaction_type: "izdavanje",
    property_type: "apartment",
    price: 900,
    currency: "EUR",
    area_sqm: 72,
    room_count: "3.0",
    floor: "5",
    total_floors: 7,
    heating_type: "cg",
    condition: "novogradnja",
    furnishing: "furnished",
    city: "Beograd",
    municipality: "Zvezdara",
    neighborhood: "Đeram",
    address: "Bulevar kralja Aleksandra 192",
    amenities: ["elevator", "balcony", "garage"],
    listing_images: [
      {
        id: "img-906-1",
        url: "https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=1200&q=80",
        order_index: 0,
        is_cover: true,
      },
    ],
  },
  {
    id: "demo-prop-010",
    external_ref: "NS-LM-010",
    title: "Uknjižen trosoban stan na Limanu 2 u blizini Štranda",
    description:
      "Odličan porodični stan na najtraženijoj lokaciji u Novom Sadu. Zgrada u zelenilu, lift, biciklana, blizina univerzitetskog kampusa i keja.",
    transaction_type: "prodaja",
    property_type: "apartment",
    price: 178000,
    currency: "EUR",
    area_sqm: 78,
    room_count: "3.0",
    floor: "3",
    total_floors: 8,
    heating_type: "cg",
    condition: "renovirano",
    furnishing: "semi_furnished",
    city: "Novi Sad",
    municipality: "Grad Novi Sad",
    neighborhood: "Liman 2",
    address: "Ravanička 8",
    amenities: ["elevator", "balcony", "basement"],
    listing_images: [
      {
        id: "img-010-1",
        url: "https://images.unsplash.com/photo-1493809842364-78817add7ffb?auto=format&fit=crop&w=1200&q=80",
        order_index: 0,
        is_cover: true,
      },
    ],
  },
  {
    id: "demo-prop-011",
    external_ref: "BG-VO-011",
    title: "Porodična kuća sa dvorištem i garažom na Voždovcu",
    description:
      "Samostalna porodična kuća u mirnom delu Voždovca. 4 sobe, 2 kupatila, uređeno travnato dvorište i garaža sa rolo vratima.",
    transaction_type: "izdavanje",
    property_type: "house",
    price: 1600,
    currency: "EUR",
    area_sqm: 190,
    room_count: "4.0",
    floor: "PR+1",
    total_floors: 2,
    heating_type: "gas",
    condition: "odrzavano",
    furnishing: "furnished",
    city: "Beograd",
    municipality: "Voždovac",
    neighborhood: "Braće Jerković",
    address: "Vojvode Vlahovića",
    amenities: ["parking", "garage", "garden"],
    listing_images: [
      {
        id: "img-011-1",
        url: "https://images.unsplash.com/photo-1518780664697-55e3ad937233?auto=format&fit=crop&w=1200&q=80",
        order_index: 0,
        is_cover: true,
      },
    ],
  },
  {
    id: "demo-prop-012",
    external_ref: "NI-MD-012",
    title: "Komforan dvosoban stan kod Parka Svetog Save u Nišu",
    description:
      "Funkcionalan stan na atraktivnoj niškoj lokaciji, renovirano kupatilo, uknjižen 1/1, pogodan za stanovanje ili rentiranje.",
    transaction_type: "prodaja",
    property_type: "apartment",
    price: 98000,
    currency: "EUR",
    area_sqm: 62,
    room_count: "2.0",
    floor: "4",
    total_floors: 6,
    heating_type: "cg",
    condition: "renovirano",
    furnishing: "empty",
    city: "Niš",
    municipality: "Medijana",
    neighborhood: "Park Svetog Save",
    address: "Bulevar Nemanjića 25",
    amenities: ["elevator", "balcony"],
    listing_images: [
      {
        id: "img-012-1",
        url: "https://images.unsplash.com/photo-1484154218962-a197022b5858?auto=format&fit=crop&w=1200&q=80",
        order_index: 0,
        is_cover: true,
      },
    ],
  },
];

export default function AgencyShowcasePage() {
  const router = useRouter();
  const params = useParams();
  const rawSlug = String(params?.slug || "demo");
  const { lang, setLang } = useLanguage();
  const ui = UI_TEXT[lang] || UI_TEXT.SR_LAT;

  const [template, setTemplate] = useState<ShowcaseTemplate>("stanomer_modern");
  const [palette, setPalette] = useState<ShowcasePalette>("royal_blue");
  const [radius, setRadius] = useState<ShowcaseRadius | null>(null);
  const [contactChannels, setContactChannels] = useState<ContactChannels>("both");
  const [showcaseLanguages, setShowcaseLanguages] = useState<Language[]>([
    "SR_LAT",
    "EN",
    "RU",
    "TR",
  ]);
  const [showcaseCurrencies, setShowcaseCurrencies] = useState<Array<"EUR" | "RSD" | "USD">>([
    "EUR",
    "RSD",
  ]);
  const [displayCurrency, setDisplayCurrency] = useState<"EUR" | "RSD" | "USD">("EUR");
  const [favorites, setFavorites] = useState<Record<string, boolean>>({});

  // Ensure active language is among allowed showcaseLanguages
  useEffect(() => {
    if (showcaseLanguages.length > 0 && !showcaseLanguages.includes(lang)) {
      setLang(showcaseLanguages[0]);
    }
  }, [showcaseLanguages, lang, setLang]);

  // Ensure active displayCurrency is among allowed showcaseCurrencies
  useEffect(() => {
    if (showcaseCurrencies.length > 0 && !showcaseCurrencies.includes(displayCurrency)) {
      setDisplayCurrency(showcaseCurrencies[0]);
    }
  }, [showcaseCurrencies, displayCurrency]);

  // Floating Contact Widget state
  const [isFloatingOpen, setIsFloatingOpen] = useState(false);
  const floatingRef = useRef<HTMLDivElement>(null);

  const [agency, setAgency] = useState<AgencyInfo>({
    id: rawSlug,
    name: "Stanomer Partner Agencija",
    phone: "",
    email: "",
    logoUrl: "",
    city: "Beograd",
    address: "",
  });
  const [listings, setListings] = useState<ShowcaseListing[]>([]);
  const [loading, setLoading] = useState(true);

  // Filters
  const [filterTx, setFilterTx] = useState<string>("all");
  const [filterType, setFilterType] = useState<string>("all");
  const [searchQuery, setSearchQuery] = useState<string>("");

  // Advanced filters
  const [filterLocation, setFilterLocation] = useState<string>("all");
  const [filterMinPrice, setFilterMinPrice] = useState<string>("");
  const [filterMaxPrice, setFilterMaxPrice] = useState<string>("");
  const [filterMinArea, setFilterMinArea] = useState<string>("");
  const [filterMaxArea, setFilterMaxArea] = useState<string>("");
  const [filterRooms, setFilterRooms] = useState<string>("all");
  const [filterAmenities, setFilterAmenities] = useState<string[]>([]);
  const [sortBy, setSortBy] = useState<string>("newest");
  const [showAdvancedFilters, setShowAdvancedFilters] = useState<boolean>(false);
  const [mobileMenuOpen, setMobileMenuOpen] = useState<boolean>(false);

  // Selected listing modal & gallery index
  const [selectedListing, setSelectedListing] = useState<ShowcaseListing | null>(null);
  const [activePhotoIdx, setActivePhotoIdx] = useState<number>(0);

  // Owner Consignment / Lead Form state
  const [leadTx, setLeadTx] = useState<"prodaja" | "izdavanje">("prodaja");
  const [leadPropType, setLeadPropType] = useState<string>("apartment");
  const [leadLocation, setLeadLocation] = useState<string>("");
  const [leadArea, setLeadArea] = useState<string>("");
  const [leadPrice, setLeadPrice] = useState<string>("");
  const [leadOwnerName, setLeadOwnerName] = useState<string>("");
  const [leadOwnerPhone, setLeadOwnerPhone] = useState<string>("");
  const [leadOwnerEmail, setLeadOwnerEmail] = useState<string>("");
  const [leadNotes, setLeadNotes] = useState<string>("");
  const [leadHoneypot, setLeadHoneypot] = useState<string>("");
  const [leadSubmitting, setLeadSubmitting] = useState<boolean>(false);
  const [leadFeedback, setLeadFeedback] = useState<{
    type: "success" | "error";
    text: string;
  } | null>(null);

  // Viewing Request State
  const [isViewingFormOpen, setIsViewingFormOpen] = useState<boolean>(false);
  const [viewingName, setViewingName] = useState<string>("");
  const [viewingPhone, setViewingPhone] = useState<string>("");
  const [viewingEmail, setViewingEmail] = useState<string>("");
  const [viewingNotes, setViewingNotes] = useState<string>("");
  const [viewingHoneypot, setViewingHoneypot] = useState<string>("");
  const [viewingSubmitting, setViewingSubmitting] = useState<boolean>(false);
  const [viewingFeedback, setViewingFeedback] = useState<{
    type: "success" | "error";
    text: string;
  } | null>(null);

  // Close floating contact popup when clicking outside
  useEffect(() => {
    function handleOutside(e: MouseEvent) {
      if (floatingRef.current && !floatingRef.current.contains(e.target as Node)) {
        setIsFloatingOpen(false);
      }
    }
    if (isFloatingOpen) {
      document.addEventListener("mousedown", handleOutside);
    }
    return () => {
      document.removeEventListener("mousedown", handleOutside);
    };
  }, [isFloatingOpen]);

  // Load saved theme/template & contact channels from localStorage (set in Agency & Showcase Settings)
  useEffect(() => {
    if (typeof window === "undefined") return;
    try {
      const saved = localStorage.getItem("stanomer_showcase_theme");
      if (saved) {
        const parsed = JSON.parse(saved);
        const validTemplates: ShowcaseTemplate[] = [
          "stanomer_modern",
          "quiet_luxury",
          "minimal_light",
          "kolm_dark",
          "lumira",
          "aldervik",
          "sage",
          "onyx_dark",
        ];
        if (validTemplates.includes(parsed.template)) {
          setTemplate(parsed.template);
        }
        const validPalettes: ShowcasePalette[] = [
          "royal_blue",
          "champagne_gold",
          "emerald_prestige",
          "burgundy_classic",
          "kolm_mint",
          "lumira_coral",
          "aldervik_amber",
          "sage_terracotta",
          "onyx_brass",
        ];
        if (validPalettes.includes(parsed.palette)) {
          setPalette(parsed.palette);
        }
        if (
          parsed.radius === "sharp" ||
          parsed.radius === "subtle" ||
          parsed.radius === "rounded" ||
          parsed.radius === "pill"
        ) {
          setRadius(parsed.radius);
        }
        if (
          parsed.contactChannels === "both" ||
          parsed.contactChannels === "whatsapp" ||
          parsed.contactChannels === "viber" ||
          parsed.contactChannels === "none"
        ) {
          setContactChannels(parsed.contactChannels);
        }
        const validLanguages: Language[] = ["SR_LAT", "SR_CYR", "EN", "RU", "TR"];
        if (Array.isArray(parsed.languages)) {
          const filtered = parsed.languages.filter((l: any) => validLanguages.includes(l));
          if (filtered.length > 0) setShowcaseLanguages(filtered);
        }
        const validCurrencies: Array<"EUR" | "RSD" | "USD"> = ["EUR", "RSD", "USD"];
        if (Array.isArray(parsed.currencies)) {
          const filtered = parsed.currencies.filter((c: any) => validCurrencies.includes(c));
          if (filtered.length > 0) setShowcaseCurrencies(filtered);
        }
        if (validCurrencies.includes(parsed.default_currency as any)) {
          setDisplayCurrency(parsed.default_currency as "EUR" | "RSD" | "USD");
        }
        const matchesLocalSlug =
          rawSlug.toLowerCase() === "demo" ||
          rawSlug.toLowerCase().endsWith("-demo") ||
          rawSlug.toLowerCase().startsWith("demo-") ||
          rawSlug.toLowerCase().includes("-demo-") ||
          (parsed.slug &&
            rawSlug.toLowerCase() === String(parsed.slug).toLowerCase()) ||
          (parsed.custom_domain &&
            rawSlug.toLowerCase() === String(parsed.custom_domain).toLowerCase());

        if (matchesLocalSlug) {
          setAgency((prev) => ({
            ...prev,
            name: parsed.agencyName || prev.name,
            phone: parsed.agencyPhone || prev.phone,
            email: parsed.agencyEmail || prev.email,
            logoUrl: parsed.agencyLogoUrl || prev.logoUrl,
            city: parsed.agencyCity || prev.city,
            address: parsed.agencyAddress || prev.address,
          }));
        }
      }
    } catch {
      // ignore storage errors
    }

    const handleStorageChange = (e: StorageEvent) => {
      if (e.key === "stanomer_showcase_theme" && e.newValue) {
        try {
          const parsed = JSON.parse(e.newValue);
          if (
            parsed.contactChannels === "both" ||
            parsed.contactChannels === "whatsapp" ||
            parsed.contactChannels === "viber" ||
            parsed.contactChannels === "none"
          ) {
            setContactChannels(parsed.contactChannels);
          }
          if (parsed.agencyPhone) {
            setAgency((prev) => ({ ...prev, phone: parsed.agencyPhone }));
          }
          if (parsed.agencyName) {
            setAgency((prev) => ({ ...prev, name: parsed.agencyName }));
          }
        } catch { }
      }
      if (e.key === "stanomer_agency_listings_demo" && e.newValue) {
        try {
          const themeStr = localStorage.getItem("stanomer_showcase_theme");
          const parsedTheme = themeStr ? JSON.parse(themeStr) : null;
          if (parsedTheme?.isRealAgency && parsedTheme?.userId) return;
          const parsed = JSON.parse(e.newValue);
          if (Array.isArray(parsed)) {
            const published = parsed.filter(
              (l: any) =>
                l.is_published !== false &&
                l.listing_status !== "rented" &&
                l.listing_status !== "sold" &&
                l.listing_status !== "archived"
            );
            setListings(published as ShowcaseListing[]);
          }
        } catch { }
      }
    };
    window.addEventListener("storage", handleStorageChange);
    return () => {
      window.removeEventListener("storage", handleStorageChange);
    };
  }, [rawSlug]);

  useEffect(() => {
    let mounted = true;
    async function loadShowcase() {
      setLoading(true);
      try {
        const { data: sessionData } = await supabase.auth.getSession();
        const activeSessionUserId = sessionData?.session?.user?.id || null;

        let localThemeUserId: string | null = null;
        if (typeof window !== "undefined") {
          try {
            const themeStr = localStorage.getItem("stanomer_showcase_theme");
            if (themeStr) {
              const parsedTheme = JSON.parse(themeStr);
              if (
                parsedTheme?.userId &&
                parsedTheme.userId !== "demo" &&
                (rawSlug.toLowerCase() === "demo" ||
                  (parsedTheme.slug &&
                    parsedTheme.slug.toLowerCase() === rawSlug.toLowerCase()))
              ) {
                localThemeUserId = parsedTheme.userId;
              }
            }
          } catch {}
        }

        let isDemoSlug =
          !activeSessionUserId &&
          !localThemeUserId &&
          (rawSlug.toLowerCase() === "demo" ||
            rawSlug.toLowerCase().endsWith("-demo") ||
            rawSlug.toLowerCase().startsWith("demo-") ||
            rawSlug.toLowerCase().includes("-demo-"));

        if (!isDemoSlug && !activeSessionUserId && !localThemeUserId && typeof window !== "undefined") {
          try {
            const demoStr = localStorage.getItem("stanomer_agency_demo");
            if (demoStr) {
              const parsedDemo = JSON.parse(demoStr);
              const demoSlug = (
                parsedDemo.slug ||
                (parsedDemo.agencyName
                  ? parsedDemo.agencyName
                      .toLowerCase()
                      .replace(/[^a-z0-9]+/g, "-")
                      .replace(/^-|-$/g, "")
                  : "")
              ).toLowerCase();
              if (demoSlug && demoSlug === rawSlug.toLowerCase()) {
                isDemoSlug = true;
              }
            }
            if (!isDemoSlug) {
              const themeStr = localStorage.getItem("stanomer_showcase_theme");
              if (themeStr) {
                const parsedTheme = JSON.parse(themeStr);
                if (
                  !parsedTheme.isRealAgency &&
                  parsedTheme.slug &&
                  parsedTheme.slug.toLowerCase() === rawSlug.toLowerCase()
                ) {
                  isDemoSlug = true;
                }
              }
            }
          } catch {}
        }

        function getDemoShowcaseListings(): ShowcaseListing[] {
          if (typeof window !== "undefined") {
            try {
              const savedListings = localStorage.getItem("stanomer_agency_listings_demo");
              if (savedListings) {
                const parsed = JSON.parse(savedListings);
                if (Array.isArray(parsed)) {
                  const published = parsed.filter(
                    (l: any) =>
                      l.is_published !== false &&
                      l.listing_status !== "rented" &&
                      l.listing_status !== "sold" &&
                      l.listing_status !== "archived"
                  );
                  return published as ShowcaseListing[];
                }
              }
            } catch { }
          }
          return DEMO_SHOWCASE_LISTINGS;
        }

        function getDemoAgencyMeta() {
          let name = "";
          let phone = "+381 11 400 0000";
          let email = "partner@stanomer.online";
          let logoUrl = "";
          let city = "Beograd";
          let address = "Knez Mihailova 14, Stari Grad";

          if (typeof window !== "undefined") {
            try {
              const themeStr = localStorage.getItem("stanomer_showcase_theme");
              if (themeStr) {
                const parsed = JSON.parse(themeStr);
                if (parsed.agencyName) name = parsed.agencyName;
                if (parsed.agencyPhone) phone = parsed.agencyPhone;
                if (parsed.agencyEmail) email = parsed.agencyEmail;
                if (parsed.agencyLogoUrl) logoUrl = parsed.agencyLogoUrl;
                if (parsed.agencyCity) city = parsed.agencyCity;
                if (parsed.agencyAddress) address = parsed.agencyAddress;
              }
            } catch { }

            if (!name) {
              try {
                const demoStr = localStorage.getItem("stanomer_agency_demo");
                if (demoStr) {
                  const parsed = JSON.parse(demoStr);
                  if (parsed.agencyName) name = parsed.agencyName;
                  if (parsed.phone) phone = parsed.phone;
                  if (parsed.email) email = parsed.email;
                  if (parsed.city) {
                    city = parsed.city;
                    address = `${parsed.city} Centar`;
                  }
                }
              } catch { }
            }
          }

          if (!name) {
            const formatted = rawSlug
              .replace(/-demo$/i, "")
              .replace(/^demo-/i, "")
              .replace(/-/g, " ")
              .trim();
            name = formatted
              ? formatted
                .split(" ")
                .map((w) => w.charAt(0).toUpperCase() + w.slice(1).toLowerCase())
                .join(" ")
              : "Beograd Exclusive Nekretnine";
          }

          return { name, phone, email, logoUrl, city, address };
        }

        if (isDemoSlug) {
          // If demo does not have Portfolio & Distribution package active, redirect to Account Settings
          if (typeof window !== "undefined") {
            try {
              const demoRaw = localStorage.getItem("stanomer_agency_demo");
              if (demoRaw) {
                const parsedDemo = JSON.parse(demoRaw);
                const activeMods = parsedDemo.active_modules || (
                  parsedDemo.focus === "presales"
                    ? ["portfolio_distribution"]
                    : parsedDemo.focus === "aftersales"
                    ? ["property_lease_management"]
                    : ["portfolio_distribution", "property_lease_management"]
                );
                if (Array.isArray(activeMods) && !activeMods.includes("portfolio_distribution")) {
                  router.replace("/agency-panel?tab=account_settings");
                  return;
                }
              }
            } catch { }
          }

          if (mounted) {
            const meta = getDemoAgencyMeta();
            setAgency((prev) => ({
              ...prev,
              id: "demo",
              name: prev.name !== "Stanomer Partner Agencija" ? prev.name : meta.name,
              phone: prev.phone || meta.phone,
              email: prev.email || meta.email,
              logoUrl: prev.logoUrl || meta.logoUrl,
              city: prev.city || meta.city,
              address: prev.address || meta.address,
            }));
            setListings(getDemoShowcaseListings());
          }
          return;
        }

        const isUuid =
          /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(
            rawSlug
          );
        const isNumeric = /^\d+$/.test(rawSlug);
        let profileId: string | null = isUuid
          ? rawSlug
          : localThemeUserId ||
            (rawSlug.toLowerCase() === "demo" && activeSessionUserId
              ? activeSessionUserId
              : null);

        if (!isUuid && !isNumeric && rawSlug.toLowerCase() !== "demo") {
          // Look up profile by slug stored in color_scheme JSONB
          const { data: profBySlug } = await supabase
            .from("profiles")
            .select("id")
            .filter("color_scheme->>slug", "eq", rawSlug.toLowerCase())
            .maybeSingle();

          if (profBySlug?.id) {
            profileId = profBySlug.id;
          } else {
            // Also try matching slug against company_name in profiles
            const cleanSearch = rawSlug.replace(/-/g, " ").trim();
            const { data: profsByName } = await supabase
              .from("profiles")
              .select("id, company_name, full_name")
              .or(`company_name.ilike.%${cleanSearch}%,full_name.ilike.%${cleanSearch}%`)
              .limit(10);

            if (profsByName && profsByName.length > 0) {
              const matched =
                profsByName.find((p) => {
                  const s = (p.company_name || p.full_name || "")
                    .toLowerCase()
                    .replace(/[^a-z0-9]+/g, "-")
                    .replace(/^-|-$/g, "");
                  return s === rawSlug.toLowerCase();
                }) || profsByName[0];
              profileId = matched.id;
            } else if (activeSessionUserId) {
              profileId = activeSessionUserId;
            } else if (typeof window !== "undefined") {
              try {
                const saved = localStorage.getItem("stanomer_showcase_theme");
                if (saved) {
                  const parsed = JSON.parse(saved);
                  if (
                    parsed.slug &&
                    rawSlug.toLowerCase() === String(parsed.slug).toLowerCase()
                  ) {
                    if (mounted) {
                      setAgency((prev) => ({
                        ...prev,
                        id: "demo",
                        name: parsed.agencyName || prev.name,
                        phone: parsed.agencyPhone || prev.phone,
                        email: parsed.agencyEmail || prev.email,
                        logoUrl: parsed.agencyLogoUrl || prev.logoUrl,
                        city: parsed.agencyCity || prev.city,
                        address: parsed.agencyAddress || prev.address,
                      }));
                      setListings(getDemoShowcaseListings());
                    }
                    return;
                  }
                }
              } catch { }
            }
          }
        }

        if (isNumeric) {
          let { data: cleanRow } = await supabase
            .from("view_clean_agencies")
            .select("id, acente_adi, sehir, adres, telefonlar, eposta_adresleri")
            .eq("id", Number(rawSlug))
            .maybeSingle();

          if (!cleanRow) {
            const prodRes = await prodPublicClient
              .from("view_clean_agencies")
              .select("id, acente_adi, sehir, adres, telefonlar, eposta_adresleri")
              .eq("id", Number(rawSlug))
              .maybeSingle();
            cleanRow = prodRes.data;
          }

          const { data: baseRow } = await supabase
            .from("agencies")
            .select("profile_id, logo_url")
            .eq("id", Number(rawSlug))
            .maybeSingle();

          if (baseRow?.profile_id) {
            profileId = baseRow.profile_id;
          }

          if (cleanRow && mounted) {
            setAgency({
              id: String(cleanRow.id),
              name: cleanRow.acente_adi || "Partner Agencija",
              phone: (cleanRow.telefonlar || "").split(",")[0]?.trim() || "",
              email: (cleanRow.eposta_adresleri || "").split(",")[0]?.trim() || "",
              logoUrl: baseRow?.logo_url || "",
              city: cleanRow.sehir || "Beograd",
              address: cleanRow.adres || "",
            });
          }
        }

        if (profileId) {
          const { data: prof } = await supabase
            .from("profiles")
            .select(
              "id, company_name, full_name, phone_number, email, logo_url, color_scheme, active_modules"
            )
            .eq("id", profileId)
            .maybeSingle();

          if (prof && mounted) {
            // If agency does not have Portfolio & Distribution package active, redirect to Account Settings
            if (prof.active_modules && Array.isArray(prof.active_modules) && !prof.active_modules.includes("portfolio_distribution")) {
              router.replace("/agency-panel?tab=account_settings");
              return;
            }
            const scheme = (prof.color_scheme as Record<string, string> | null) || {};
            setAgency((prev) => ({
              ...prev,
              id: prof.id,
              name: prof.company_name || prof.full_name || prev.name,
              phone: prof.phone_number || prev.phone,
              email: prof.email || prev.email,
              logoUrl: prof.logo_url || prev.logoUrl,
              city: scheme.city || prev.city || "Beograd",
              address: scheme.address || prev.address || "",
            }));

            const validTemplates: ShowcaseTemplate[] = [
              "stanomer_modern",
              "quiet_luxury",
              "minimal_light",
              "kolm_dark",
              "lumira",
              "aldervik",
              "sage",
              "onyx_dark",
            ];
            if (validTemplates.includes(scheme.template as ShowcaseTemplate)) {
              setTemplate(scheme.template as ShowcaseTemplate);
            }
            const validPalettes: ShowcasePalette[] = [
              "royal_blue",
              "champagne_gold",
              "emerald_prestige",
              "burgundy_classic",
              "kolm_mint",
              "lumira_coral",
              "aldervik_amber",
              "sage_terracotta",
              "onyx_brass",
            ];
            if (validPalettes.includes(scheme.palette as ShowcasePalette)) {
              setPalette(scheme.palette as ShowcasePalette);
            }
            if (
              scheme.radius === "sharp" ||
              scheme.radius === "subtle" ||
              scheme.radius === "rounded" ||
              scheme.radius === "pill"
            ) {
              setRadius(scheme.radius as ShowcaseRadius);
            }
            if (
              scheme.contactChannels === "both" ||
              scheme.contactChannels === "whatsapp" ||
              scheme.contactChannels === "viber" ||
              scheme.contactChannels === "none"
            ) {
              setContactChannels(scheme.contactChannels);
            }
            const validLanguages: Language[] = ["SR_LAT", "SR_CYR", "EN", "RU", "TR"];
            if (Array.isArray(scheme.languages)) {
              const filtered = scheme.languages.filter((l: any) => validLanguages.includes(l));
              if (filtered.length > 0) setShowcaseLanguages(filtered);
            }
            const validCurrencies: Array<"EUR" | "RSD" | "USD"> = ["EUR", "RSD", "USD"];
            if (Array.isArray(scheme.currencies)) {
              const filtered = scheme.currencies.filter((c: any) => validCurrencies.includes(c));
              if (filtered.length > 0) setShowcaseCurrencies(filtered);
            }
            if (validCurrencies.includes(scheme.default_currency as any)) {
              setDisplayCurrency(scheme.default_currency as "EUR" | "RSD" | "USD");
            }
          }

          const { data: rows } = await supabase
            .from("listings")
            .select(
              `
              id,
              external_ref,
              title,
              description,
              transaction_type,
              property_type,
              price,
              currency,
              area_sqm,
              room_count,
              floor,
              total_floors,
              heating_type,
              condition,
              furnishing,
              city,
              municipality,
              neighborhood,
              address,
              amenities,
              listing_status,
              created_at,
              listing_images (
                id,
                url,
                order_index,
                is_cover
              )
            `
            )
            .eq("agency_id", profileId)
            .eq("is_published", true)
            .order("created_at", { ascending: false });

          if (mounted) {
            const activeRows = (rows || []).filter(
              (r: any) =>
                r.listing_status !== "rented" &&
                r.listing_status !== "sold" &&
                r.listing_status !== "archived"
            );
            setListings((activeRows as unknown as ShowcaseListing[]) || []);
          }
        } else {
          if (mounted) {
            let hasActiveDemo = false;
            if (typeof window !== "undefined") {
              try {
                const savedDemo = localStorage.getItem("stanomer_agency_demo");
                const savedTheme = localStorage.getItem("stanomer_showcase_theme");
                if (savedDemo || savedTheme) hasActiveDemo = true;
              } catch { }
            }
            if (hasActiveDemo) {
              const meta = getDemoAgencyMeta();
              setAgency((prev) => ({
                ...prev,
                id: "demo",
                name: prev.name !== "Stanomer Partner Agencija" ? prev.name : meta.name,
                phone: prev.phone || meta.phone,
                email: prev.email || meta.email,
                logoUrl: prev.logoUrl || meta.logoUrl,
                city: prev.city || meta.city,
                address: prev.address || meta.address,
              }));
              setListings(getDemoShowcaseListings());
            } else {
              setListings([]);
            }
          }
        }
      } finally {
        if (mounted) setLoading(false);
      }
    }
    loadShowcase();
    return () => {
      mounted = false;
    };
  }, [rawSlug]);

  const toggleAmenity = (key: string) => {
    setFilterAmenities((prev) =>
      prev.includes(key) ? prev.filter((k) => k !== key) : [...prev, key]
    );
  };

  const availableLocations = useMemo(() => {
    const locs = new Set<string>();
    for (const item of listings) {
      if (item.municipality && item.municipality.trim()) {
        locs.add(item.municipality.trim());
      } else if (item.city && item.city.trim()) {
        locs.add(item.city.trim());
      }
    }
    return Array.from(locs).sort();
  }, [listings]);

  const activeFiltersCount = useMemo(() => {
    let count = 0;
    if (filterLocation !== "all") count++;
    if (filterMinPrice.trim() !== "") count++;
    if (filterMaxPrice.trim() !== "") count++;
    if (filterMinArea.trim() !== "") count++;
    if (filterMaxArea.trim() !== "") count++;
    if (filterRooms !== "all") count++;
    if (filterAmenities.length > 0) count += filterAmenities.length;
    if (sortBy !== "newest") count++;
    return count;
  }, [
    filterLocation,
    filterMinPrice,
    filterMaxPrice,
    filterMinArea,
    filterMaxArea,
    filterRooms,
    filterAmenities,
    sortBy,
  ]);

  const resetAllFilters = () => {
    setFilterTx("all");
    setFilterType("all");
    setSearchQuery("");
    setFilterLocation("all");
    setFilterMinPrice("");
    setFilterMaxPrice("");
    setFilterMinArea("");
    setFilterMaxArea("");
    setFilterRooms("all");
    setFilterAmenities([]);
    setSortBy("newest");
  };

  const AMENITY_OPTIONS = [
    { key: "elevator", label: ui.featElevator },
    { key: "balcony", label: ui.featBalcony },
    { key: "parking", label: ui.featParking },
    { key: "ac", label: ui.featAc },
    { key: "furnished", label: ui.featFurnished },
    { key: "new_build", label: ui.featNewBuild },
  ];

  const SORT_OPTIONS = [
    { key: "newest", label: ui.sortNewest },
    { key: "price_asc", label: ui.sortPriceAsc },
    { key: "price_desc", label: ui.sortPriceDesc },
    { key: "area_desc", label: ui.sortAreaDesc },
  ];

  const filteredListings = useMemo(() => {
    const list = listings.filter((item) => {
      if (filterTx !== "all" && item.transaction_type !== filterTx) return false;
      if (filterType !== "all" && item.property_type !== filterType) return false;
      if (filterLocation !== "all") {
        const itemLoc = (item.municipality || item.city || "").toLowerCase();
        if (itemLoc !== filterLocation.toLowerCase()) return false;
      }
      const p = Number(item.price || 0);
      if (filterMinPrice) {
        const minP = Number(filterMinPrice);
        if (!isNaN(minP) && p < minP) return false;
      }
      if (filterMaxPrice) {
        const maxP = Number(filterMaxPrice);
        if (!isNaN(maxP) && p > maxP) return false;
      }
      const a = Number(item.area_sqm || 0);
      if (filterMinArea) {
        const minA = Number(filterMinArea);
        if (!isNaN(minA) && a < minA) return false;
      }
      if (filterMaxArea) {
        const maxA = Number(filterMaxArea);
        if (!isNaN(maxA) && a > maxA) return false;
      }
      if (filterRooms !== "all") {
        const rc = (item.room_count || "").trim();
        if (filterRooms === "4.0+") {
          const num = parseFloat(rc);
          if (isNaN(num) || num < 4.0) return false;
        } else {
          const num = parseFloat(rc);
          const target = parseFloat(filterRooms);
          if (isNaN(num) || isNaN(target) || Math.abs(num - target) > 0.05) return false;
        }
      }
      if (filterAmenities.length > 0) {
        const itemAmenities = (item.amenities || []).map((x) => x.toLowerCase());
        const hasElevator = itemAmenities.some((x) => x.includes("elevator") || x.includes("lift"));
        const hasBalcony = itemAmenities.some((x) => x.includes("balcony") || x.includes("terrace") || x.includes("terasa"));
        const hasParking = itemAmenities.some((x) => x.includes("park") || x.includes("gara"));
        const hasAc = itemAmenities.some((x) => x.includes("ac") || x.includes("klima") || x.includes("air_conditioning"));
        const isFurnished = item.furnishing === "furnished" || itemAmenities.some((x) => x.includes("furnish") || x.includes("namest"));
        const isNewBuild = item.condition === "novogradnja" || itemAmenities.some((x) => x.includes("novogradnja") || x.includes("new"));

        for (const am of filterAmenities) {
          if (am === "elevator" && !hasElevator) return false;
          if (am === "balcony" && !hasBalcony) return false;
          if (am === "parking" && !hasParking) return false;
          if (am === "ac" && !hasAc) return false;
          if (am === "furnished" && !isFurnished) return false;
          if (am === "new_build" && !isNewBuild) return false;
        }
      }
      if (searchQuery.trim()) {
        const q = searchQuery.toLowerCase();
        const hay = [
          item.title,
          item.city,
          item.municipality,
          item.neighborhood,
          item.address,
          item.external_ref,
        ]
          .filter(Boolean)
          .join(" ")
          .toLowerCase();
        if (!hay.includes(q)) return false;
      }
      return true;
    });

    return [...list].sort((a, b) => {
      if (sortBy === "price_asc") {
        return Number(a.price || 0) - Number(b.price || 0);
      }
      if (sortBy === "price_desc") {
        return Number(b.price || 0) - Number(a.price || 0);
      }
      if (sortBy === "area_desc") {
        return Number(b.area_sqm || 0) - Number(a.area_sqm || 0);
      }
      if (sortBy === "area_asc") {
        return Number(a.area_sqm || 0) - Number(b.area_sqm || 0);
      }
      return 0;
    });
  }, [
    listings,
    filterTx,
    filterType,
    filterLocation,
    filterMinPrice,
    filterMaxPrice,
    filterMinArea,
    filterMaxArea,
    filterRooms,
    filterAmenities,
    sortBy,
    searchQuery,
  ]);

  function formatDisplayPrice(item: ShowcaseListing): string {
    const raw = Number(item.price || 0);
    if (displayCurrency === "RSD") {
      const rsd = item.currency === "RSD" ? raw : Math.round(raw * 117.2);
      return `${rsd.toLocaleString()} дин`;
    }
    if (displayCurrency === "USD") {
      const usd = item.currency === "USD" ? raw : Math.round(raw * 1.08);
      return `$${usd.toLocaleString()}`;
    }
    return `€${raw.toLocaleString()}`;
  }

  function toggleFav(id: string, e: React.MouseEvent) {
    e.stopPropagation();
    setFavorites((prev) => ({ ...prev, [id]: !prev[id] }));
  }

  async function handleOwnerLeadSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLeadSubmitting(true);
    setLeadFeedback(null);

    // 1. Immediately persist locally to agency leads so agency-panel CRM reflects it without delay
    const effectiveAgencyId = agency.id || "demo";
    const leadObj = {
      id: "lead-" + Date.now(),
      agency_id: effectiveAgencyId,
      lead_type: "owner_consignment",
      status: "new",
      client_name: leadOwnerName.trim(),
      client_phone: leadOwnerPhone.trim(),
      client_email: leadOwnerEmail.trim() || null,
      transaction_type: leadTx,
      property_type: leadPropType,
      location: leadLocation.trim(),
      area_sqm: leadArea.trim() ? Number(leadArea.trim()) : null,
      expected_price: leadPrice.trim() ? Number(leadPrice.trim()) : null,
      currency: "EUR",
      notes: leadNotes.trim() || null,
      created_at: new Date().toISOString(),
    };

    if (typeof window !== "undefined") {
      try {
        const targetKey = `stanomer_agency_leads_${effectiveAgencyId}`;
        const currentList = JSON.parse(localStorage.getItem(targetKey) || "[]").filter(
          (item: any) => item && item.id !== leadObj.id
        );
        currentList.unshift(leadObj);
        localStorage.setItem(targetKey, JSON.stringify(currentList));

        if (targetKey !== "stanomer_agency_leads_demo") {
          const demoList = JSON.parse(
            localStorage.getItem("stanomer_agency_leads_demo") || "[]"
          ).filter((item: any) => item && item.id !== leadObj.id);
          demoList.unshift(leadObj);
          localStorage.setItem("stanomer_agency_leads_demo", JSON.stringify(demoList));
        }

        if (rawSlug && rawSlug !== effectiveAgencyId && rawSlug !== "demo") {
          const slugKey = `stanomer_agency_leads_${rawSlug}`;
          const slugList = JSON.parse(
            localStorage.getItem(slugKey) || "[]"
          ).filter((item: any) => item && item.id !== leadObj.id);
          slugList.unshift(leadObj);
          localStorage.setItem(slugKey, JSON.stringify(slugList));
        }

        try {
          const bc = new BroadcastChannel("stanomer_leads_sync");
          bc.postMessage({ type: "NEW_LEAD", lead: leadObj });
          bc.close();
        } catch { }

        try {
          window.dispatchEvent(new CustomEvent("stanomer_lead_created", { detail: leadObj }));
        } catch { }
      } catch { }
    }

    try {
      const propObj = PROPERTY_TYPES[leadPropType] || PROPERTY_TYPES.apartment;
      await fetch("/api/send-agency-lead", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          agencyEmail: agency.email || "partner@stanomer.online",
          agencyName: agency.name,
          agencyId: effectiveAgencyId,
          ownerName: leadOwnerName.trim(),
          ownerPhone: leadOwnerPhone.trim(),
          ownerEmail: leadOwnerEmail.trim(),
          transactionType: leadTx,
          propertyType: getDictLabel(propObj, lang),
          location: leadLocation.trim(),
          areaSqm: leadArea.trim(),
          expectedPrice: leadPrice.trim(),
          notes: leadNotes.trim(),
          lang,
          honeypot: leadHoneypot,
        }),
      });

      setLeadFeedback({ type: "success", text: ui.ownerSuccessMsg });
      setLeadLocation("");
      setLeadArea("");
      setLeadPrice("");
      setLeadOwnerName("");
      setLeadOwnerPhone("");
      setLeadOwnerEmail("");
      setLeadNotes("");
    } catch {
      // Even if network notification fails, lead is already saved locally
      setLeadFeedback({ type: "success", text: ui.ownerSuccessMsg });
      setLeadLocation("");
      setLeadArea("");
      setLeadPrice("");
      setLeadOwnerName("");
      setLeadOwnerPhone("");
      setLeadOwnerEmail("");
      setLeadNotes("");
    } finally {
      setLeadSubmitting(false);
    }
  }

  async function handleViewingLeadSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!selectedListing) return;
    setViewingSubmitting(true);
    setViewingFeedback(null);

    const listingTitle = selectedListing.title;
    const listingId = selectedListing.id;
    const locText = [
      selectedListing.city,
      selectedListing.municipality,
      selectedListing.neighborhood,
    ]
      .filter(Boolean)
      .join(", ");

    // 1. Immediately persist viewing request locally so agency-panel CRM reflects it without delay
    const effectiveAgencyId = agency.id || "demo";
    const leadObj = {
      id: "lead-" + Date.now(),
      agency_id: effectiveAgencyId,
      lead_type: "viewing_request",
      status: "new",
      client_name: viewingName.trim(),
      client_phone: viewingPhone.trim(),
      client_email: viewingEmail.trim() || null,
      transaction_type: selectedListing.transaction_type,
      property_type: selectedListing.property_type,
      location: locText,
      area_sqm: selectedListing.area_sqm,
      expected_price: selectedListing.price,
      currency: selectedListing.currency || "EUR",
      listing_id: listingId,
      listing_title: listingTitle,
      notes: viewingNotes.trim() || null,
      comments: [
        {
          id: "cmt-" + Date.now(),
          author_name: ui.systemAuthor || "Sistem",
          text: ui.viewingInitialComment || "Zahtev za razgledanje poslat sa sajta",
          created_at: new Date().toISOString(),
        },
      ],
      created_at: new Date().toISOString(),
    };

    if (typeof window !== "undefined") {
      try {
        const targetKey = `stanomer_agency_leads_${effectiveAgencyId}`;
        const currentList = JSON.parse(localStorage.getItem(targetKey) || "[]").filter(
          (item: any) => item && item.id !== leadObj.id
        );
        currentList.unshift(leadObj);
        localStorage.setItem(targetKey, JSON.stringify(currentList));

        if (targetKey !== "stanomer_agency_leads_demo") {
          const demoList = JSON.parse(
            localStorage.getItem("stanomer_agency_leads_demo") || "[]"
          ).filter((item: any) => item && item.id !== leadObj.id);
          demoList.unshift(leadObj);
          localStorage.setItem("stanomer_agency_leads_demo", JSON.stringify(demoList));
        }

        if (rawSlug && rawSlug !== effectiveAgencyId && rawSlug !== "demo") {
          const slugKey = `stanomer_agency_leads_${rawSlug}`;
          const slugList = JSON.parse(
            localStorage.getItem(slugKey) || "[]"
          ).filter((item: any) => item && item.id !== leadObj.id);
          slugList.unshift(leadObj);
          localStorage.setItem(slugKey, JSON.stringify(slugList));
        }

        try {
          const bc = new BroadcastChannel("stanomer_leads_sync");
          bc.postMessage({ type: "NEW_LEAD", lead: leadObj });
          bc.close();
        } catch { }

        try {
          window.dispatchEvent(new CustomEvent("stanomer_lead_created", { detail: leadObj }));
        } catch { }
      } catch { }
    }

    try {
      await fetch("/api/send-agency-lead", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          agencyEmail: agency.email || "partner@stanomer.online",
          agencyName: agency.name,
          agencyId: effectiveAgencyId,
          leadType: "viewing_request",
          clientName: viewingName.trim(),
          clientPhone: viewingPhone.trim(),
          clientEmail: viewingEmail.trim(),
          ownerName: viewingName.trim(),
          ownerPhone: viewingPhone.trim(),
          ownerEmail: viewingEmail.trim(),
          listingId,
          listingTitle,
          transactionType: selectedListing.transaction_type,
          propertyType: selectedListing.property_type,
          location: locText,
          expectedPrice: selectedListing.price,
          areaSqm: selectedListing.area_sqm,
          notes: viewingNotes.trim(),
          lang,
          honeypot: viewingHoneypot,
        }),
      });

      setViewingFeedback({ type: "success", text: ui.viewingSuccessMsg });
      setViewingName("");
      setViewingPhone("");
      setViewingEmail("");
      setViewingNotes("");
    } catch {
      // Even if network notification fails, viewing lead is already saved locally
      setViewingFeedback({ type: "success", text: ui.viewingSuccessMsg });
      setViewingName("");
      setViewingPhone("");
      setViewingEmail("");
      setViewingNotes("");
    } finally {
      setViewingSubmitting(false);
    }
  }

  const effectivePhone =
    agency.phone && agency.phone.trim().length > 3
      ? agency.phone
      : "+381 11 400 0000";
  const cleanPhoneDigits = effectivePhone.replace(/[^\d+]/g, "");
  const rawDigitsOnly = cleanPhoneDigits.replace(/^\+/, "");
  const palTokens = PALETTE_TOKENS[palette] || PALETTE_TOKENS.royal_blue;
  const isOnyx = template === "onyx_dark";
  const isQuietLuxury = template === "quiet_luxury";
  const isMinimal = template === "minimal_light";
  const isKolm = template === "kolm_dark";
  const isLumira = template === "lumira";
  const isAldervik = template === "aldervik";
  const isSage = template === "sage";
  const isDarkCanvas = isQuietLuxury || isKolm || isOnyx;

  const effectiveRadius: ShowcaseRadius =
    radius ||
    (isQuietLuxury || isOnyx
      ? "subtle"
      : isMinimal
        ? "sharp"
        : isAldervik
          ? "subtle"
          : "rounded");

  const luxRadius =
    effectiveRadius === "sharp"
      ? "rounded-none"
      : effectiveRadius === "subtle"
        ? "rounded-[4px]"
        : effectiveRadius === "pill"
          ? "rounded-full"
          : "rounded-xl";

  const luxCardRadius =
    effectiveRadius === "sharp"
      ? "rounded-none"
      : effectiveRadius === "subtle"
        ? "rounded-[4px]"
        : effectiveRadius === "pill"
          ? "rounded-3xl"
          : "rounded-2xl";

  const luxBadgeRadius =
    effectiveRadius === "sharp"
      ? "rounded-none"
      : effectiveRadius === "subtle"
        ? "rounded-[3px]"
        : effectiveRadius === "pill"
          ? "rounded-full"
          : "rounded-lg";

  const showWhatsApp =
    contactChannels === "both" || contactChannels === "whatsapp";
  const showViber = contactChannels === "both" || contactChannels === "viber";
  const isWAOnly = contactChannels === "whatsapp";
  const isViberOnly = contactChannels === "viber";
  const isBothChannels = contactChannels === "both";

  const floatingAccentColor = isQuietLuxury
    ? "#c8a97e"
    : isOnyx
      ? "#D4B26A"
      : isKolm
        ? "#5EF0B8"
        : isLumira
          ? "#FF6B5A"
          : isAldervik
            ? "#FFB020"
            : isSage
              ? "#D9663B"
              : palTokens.primary;

  const buttonBgColor = isFloatingOpen
    ? isQuietLuxury
      ? "#10151c"
      : "#0f172a"
    : isWAOnly
      ? "#25D366"
      : isViberOnly
        ? "#7360F2"
        : isQuietLuxury
          ? "#090B0E"
          : floatingAccentColor;

  const buttonTextColor = isFloatingOpen
    ? isQuietLuxury
      ? "#c8a97e"
      : "#ffffff"
    : isWAOnly || isViberOnly
      ? "#ffffff"
      : !isFloatingOpen && isQuietLuxury
        ? "#c8a97e"
        : "#ffffff";

  const buttonBorderColor = isQuietLuxury
    ? isFloatingOpen
      ? "rgba(200, 169, 126, 0.55)"
      : isWAOnly
        ? "rgba(37, 211, 102, 0.7)"
        : isViberOnly
          ? "rgba(115, 96, 242, 0.7)"
          : "rgba(200, 169, 126, 0.55)"
    : "transparent";

  const floatingContactNode =
    contactChannels !== "none" && rawDigitsOnly ? (
      <div
        ref={floatingRef}
        className="fixed bottom-6 right-6 z-[9999] flex flex-col items-end"
      >
        {isFloatingOpen && isBothChannels && (
          <div
            className={`mb-3 w-76 p-4 shadow-2xl border transition-all ${luxCardRadius} ${isQuietLuxury
              ? "bg-[#10151c]/95 backdrop-blur-md text-[#e5e1db] border-[#c8a97e]/40"
              : isMinimal
                ? "bg-stone-50 text-stone-900 border-stone-300"
                : "bg-white text-slate-900 border-slate-200"
              }`}
          >
            {/* Dialog Header */}
            <div
              className={`flex items-center gap-2.5 pb-2.5 mb-2.5 border-b ${isQuietLuxury
                ? "border-white/10"
                : isMinimal
                  ? "border-stone-200"
                  : "border-slate-100"
                }`}
            >
              <span
                className="inline-block w-2.5 h-2.5 rounded-full shrink-0"
                style={{
                  backgroundColor: isWAOnly
                    ? "#25D366"
                    : isViberOnly
                      ? "#7360F2"
                      : floatingAccentColor,
                }}
              />
              <span
                className={`text-xs font-bold truncate ${isQuietLuxury
                  ? "text-[#e5e1db] tracking-wide"
                  : "text-slate-900"
                  }`}
                style={
                  isQuietLuxury
                    ? { fontFamily: "'Cormorant Garamond', Georgia, serif", fontSize: "14px" }
                    : undefined
                }
              >
                {agency.name} • {isWAOnly ? "WhatsApp" : isViberOnly ? "Viber" : ui.floatingTitle}
              </span>
            </div>

            <p
              className={`text-[11px] mb-3.5 leading-relaxed ${isQuietLuxury ? "text-[#9ca6b0]" : "text-slate-500"
                }`}
            >
              {contactChannels === "both"
                ? ui.floatingBothDesc
                : contactChannels === "whatsapp"
                  ? ui.floatingWhatsappDesc
                  : ui.floatingViberDesc}
            </p>

            <div className="space-y-2">
              {showWhatsApp && (
                <a
                  href={`https://wa.me/${rawDigitsOnly}`}
                  target="_blank"
                  rel="noopener noreferrer"
                  onClick={() => setIsFloatingOpen(false)}
                  className={`flex items-center gap-3 p-2.5 border transition-all duration-150 group ${luxRadius} ${isQuietLuxury
                    ? "border-white/10 bg-white/5 hover:border-[#c8a97e]/60 hover:bg-[#c8a97e]/10"
                    : isMinimal
                      ? "border-stone-200 bg-white hover:border-stone-900"
                      : "border-slate-100 bg-slate-50/80 hover:bg-slate-100/80 hover:border-slate-300"
                    }`}
                >
                  <div
                    className={`w-9 h-9 flex items-center justify-center shrink-0 ${isQuietLuxury
                      ? "rounded-[4px] border border-[#c8a97e]/40"
                      : isMinimal
                        ? "rounded-none"
                        : "rounded-xl"
                      }`}
                    style={{
                      backgroundColor: isQuietLuxury
                        ? "#003c52"
                        : palTokens.primary,
                      color: isQuietLuxury ? "#c8a97e" : "#ffffff",
                    }}
                  >
                    <svg viewBox="0 0 24 24" width="18" height="18" fill="currentColor" aria-hidden="true">
                      <path d="M12.031 6.172c-3.181 0-5.767 2.586-5.768 5.766-.001 1.298.38 2.27 1.019 3.287l-.711 2.598 2.664-.698c.969.586 1.761.859 2.796.859 3.179 0 5.766-2.587 5.768-5.766.002-3.181-2.585-5.766-5.768-5.766zm3.364 8.243c-.14.394-.712.723-1.002.766-.279.041-.632.062-1.921-.472-1.649-.684-2.698-2.383-2.78-2.493-.082-.11-.663-.883-.663-1.682 0-.799.418-1.192.567-1.353.149-.161.326-.201.435-.201.109 0 .218.001.314.006.101.005.236-.038.369.281.137.329.467 1.139.508 1.222.041.083.069.179.014.288-.055.11-.082.179-.164.275-.082.096-.173.215-.247.288-.082.082-.168.172-.072.337.096.165.426.703.914 1.138.629.56 1.159.734 1.324.816.165.082.262.069.359-.042.096-.11.413-.481.523-.646.11-.165.22-.138.371-.083.151.055.956.451 1.121.533.165.082.275.124.316.193.041.069.041.401-.099.795z" />
                    </svg>
                  </div>
                  <div className="flex-1 min-w-0">
                    <div
                      className={`text-xs font-bold ${isQuietLuxury ? "text-[#e5e1db]" : "text-slate-900"
                        }`}
                    >
                      WhatsApp
                    </div>
                    <div
                      className={`text-[11px] ${isQuietLuxury ? "text-[#9ca6b0]" : "text-slate-500"
                        }`}
                    >
                      {effectivePhone}
                    </div>
                  </div>
                  <ArrowUpRight
                    className="w-4 h-4 transition-transform group-hover:translate-x-0.5 group-hover:-translate-y-0.5"
                    style={{ color: isWAOnly ? "#25D366" : floatingAccentColor }}
                  />
                </a>
              )}

              {showViber && (
                <a
                  href={`viber://chat?number=%2B${rawDigitsOnly}`}
                  onClick={() => setIsFloatingOpen(false)}
                  className={`flex items-center gap-3 p-2.5 border transition-all duration-150 group ${luxRadius} ${isQuietLuxury
                    ? "border-white/10 bg-white/5 hover:border-[#c8a97e]/60 hover:bg-[#c8a97e]/10"
                    : isMinimal
                      ? "border-stone-200 bg-white hover:border-stone-900"
                      : "border-slate-100 bg-slate-50/80 hover:bg-slate-100/80 hover:border-slate-300"
                    }`}
                >
                  <div
                    className={`w-9 h-9 flex items-center justify-center shrink-0 ${isQuietLuxury
                      ? "rounded-[4px] border border-[#c8a97e]/40"
                      : isMinimal
                        ? "rounded-none"
                        : "rounded-xl"
                      }`}
                    style={{
                      backgroundColor: isQuietLuxury
                        ? "#003c52"
                        : palTokens.primary,
                      color: isQuietLuxury ? "#c8a97e" : "#ffffff",
                    }}
                  >
                    <svg viewBox="0 0 24 24" width="18" height="18" fill="currentColor" aria-hidden="true">
                      <path d="M19.39 15.68c-.68-.39-1.5-.2-1.89.47l-.54.91c-.24.4-.76.54-1.18.31-1.89-1.04-3.41-2.56-4.45-4.45-.23-.42-.09-.94.31-1.18l.91-.54c.67-.39.86-1.21.47-1.89l-1.64-2.85c-.39-.68-1.21-.86-1.89-.47l-.92.53C7.54 7.07 7.02 8.35 7.27 9.68c.67 3.53 3.52 6.38 7.05 7.05 1.33.25 2.61-.27 3.17-1.24l.53-.92c.39-.68.2-1.5-.47-1.89l-2.16-1zM14 6.5c1.93 0 3.5 1.57 3.5 3.5h1.5c0-2.76-2.24-5-5-5v1.5zm0 3c.83 0 1.5.67 1.5 1.5h1.5c0-1.66-1.34-3-3-3v1.5z" />
                    </svg>
                  </div>
                  <div className="flex-1 min-w-0">
                    <div
                      className={`text-xs font-bold ${isQuietLuxury ? "text-[#e5e1db]" : "text-slate-900"
                        }`}
                    >
                      Viber
                    </div>
                    <div
                      className={`text-[11px] ${isQuietLuxury ? "text-[#9ca6b0]" : "text-slate-500"
                        }`}
                    >
                      {effectivePhone}
                    </div>
                  </div>
                  <ArrowUpRight
                    className="w-4 h-4 transition-transform group-hover:translate-x-0.5 group-hover:-translate-y-0.5"
                    style={{ color: isViberOnly ? "#7360F2" : floatingAccentColor }}
                  />
                </a>
              )}
            </div>
          </div>
        )}

        <div className="flex items-center gap-2.5">
          {/* Channel Label Pill on Desktop / Tablet */}
          <div
            className={`px-3 py-1.5 shadow-lg border text-xs font-bold rounded-full pointer-events-none transition-all duration-200 hidden sm:flex items-center ${isQuietLuxury
                ? "bg-[#10151c]/95 text-[#e5e1db] border-[#c8a97e]/40"
                : "bg-white/95 text-slate-800 border-slate-200"
              }`}
          >
            {isWAOnly && <span>WhatsApp</span>}
            {isViberOnly && <span>Viber</span>}
            {isBothChannels && <span>WhatsApp • Viber</span>}
          </div>

          {isWAOnly ? (
            <a
              href={`https://wa.me/${rawDigitsOnly}`}
              target="_blank"
              rel="noopener noreferrer"
              aria-label="WhatsApp"
              style={{
                backgroundColor: "#25D366",
                color: "#ffffff",
                borderColor: isQuietLuxury ? "rgba(37, 211, 102, 0.7)" : "transparent",
              }}
              className={`relative w-14 h-14 shadow-xl border flex items-center justify-center transition-transform duration-200 hover:scale-105 cursor-pointer ${isQuietLuxury
                  ? "rounded-[4px]"
                  : isMinimal
                    ? "rounded-none"
                    : "rounded-2xl"
                }`}
            >
              <svg viewBox="0 0 24 24" className="w-7 h-7 fill-current" aria-hidden="true">
                <path d="M12.031 6.172c-3.181 0-5.767 2.586-5.768 5.766-.001 1.298.38 2.27 1.019 3.287l-.711 2.598 2.664-.698c.969.586 1.761.859 2.796.859 3.179 0 5.766-2.587 5.768-5.766.002-3.181-2.585-5.766-5.768-5.766zm3.364 8.243c-.14.394-.712.723-1.002.766-.279.041-.632.062-1.921-.472-1.649-.684-2.698-2.383-2.78-2.493-.082-.11-.663-.883-.663-1.682 0-.799.418-1.192.567-1.353.149-.161.326-.201.435-.201.109 0 .218.001.314.006.101.005.236-.038.369.281.137.329.467 1.139.508 1.222.041.083.069.179.014.288-.055.11-.082.179-.164.275-.082.096-.173.215-.247.288-.082.082-.168.172-.072.337.096.165.426.703.914 1.138.629.56 1.159.734 1.324.816.165.082.262.069.359-.042.096-.11.413-.481.523-.646.11-.165.22-.138.371-.083.151.055.956.451 1.121.533.165.082.275.124.316.193.041.069.041.401-.099.795z" />
              </svg>
            </a>
          ) : isViberOnly ? (
            <a
              href={`viber://chat?number=%2B${rawDigitsOnly}`}
              target="_blank"
              rel="noopener noreferrer"
              aria-label="Viber"
              style={{
                backgroundColor: "#7360F2",
                color: "#ffffff",
                borderColor: isQuietLuxury ? "rgba(115, 96, 242, 0.7)" : "transparent",
              }}
              className={`relative w-14 h-14 shadow-xl border flex items-center justify-center transition-transform duration-200 hover:scale-105 cursor-pointer ${isQuietLuxury
                  ? "rounded-[4px]"
                  : isMinimal
                    ? "rounded-none"
                    : "rounded-2xl"
                }`}
            >
              <svg viewBox="0 0 24 24" className="w-7 h-7 fill-current" aria-hidden="true">
                <path d="M19.39 15.68c-.68-.39-1.5-.2-1.89.47l-.54.91c-.24.4-.76.54-1.18.31-1.89-1.04-3.41-2.56-4.45-4.45-.23-.42-.09-.94.31-1.18l.91-.54c.67-.39.86-1.21.47-1.89l-1.64-2.85c-.39-.68-1.21-.86-1.89-.47l-.92.53C7.54 7.07 7.02 8.35 7.27 9.68c.67 3.53 3.52 6.38 7.05 7.05 1.33.25 2.61-.27 3.17-1.24l.53-.92c.39-.68.2-1.5-.47-1.89l-2.16-1zM14 6.5c1.93 0 3.5 1.57 3.5 3.5h1.5c0-2.76-2.24-5-5-5v1.5zm0 3c.83 0 1.5.67 1.5 1.5h1.5c0-1.66-1.34-3-3-3v1.5z" />
              </svg>
            </a>
          ) : (
            <button
              type="button"
              onClick={() => setIsFloatingOpen((prev) => !prev)}
              aria-label={ui.floatingTitle}
              aria-expanded={isFloatingOpen}
              style={{
                backgroundColor: buttonBgColor,
                color: buttonTextColor,
                borderColor: buttonBorderColor,
              }}
              className={`relative w-14 h-14 shadow-xl border flex items-center justify-center transition-transform duration-200 hover:scale-105 cursor-pointer ${isQuietLuxury
                  ? "rounded-[4px]"
                  : isMinimal
                    ? "rounded-none"
                    : "rounded-2xl"
                }`}
            >
              {isFloatingOpen ? (
                <X className="w-6 h-6" />
              ) : (
                <MessageCircle className="w-6 h-6" />
              )}
            </button>
          )}
        </div>
      </div>
    ) : null;

  // ============================================================================
  // SHARED NODE 2: PROPERTY OWNER CONSIGNMENT / LISTING SUBMISSION FORM
  // ============================================================================

  const isDarkForm = isQuietLuxury || isKolm || isOnyx;

  const ownerConsignmentSectionNode = (
    <section
      id="owner-lead-section"
      aria-labelledby="owner-lead-heading"
      className="max-w-7xl mx-auto w-full px-4 sm:px-6 lg:px-8 py-12"
    >
      <div
        className={`${luxCardRadius} p-6 sm:p-10 border ${isQuietLuxury
          ? "bg-[#10151c] border-[#c8a97e]/30 text-[#e5e1db]"
          : isOnyx
            ? "bg-[#2A2A2D] border-[#3A3A3E] text-[#F5F1E8]"
            : isKolm
              ? "bg-[#2A2E32] border-[#3C434A] text-white"
              : isMinimal
                ? "bg-white border-stone-200 text-slate-900"
                : "bg-white border-slate-200 shadow-xs text-slate-900"
          }`}
      >
        <div className="max-w-3xl mb-8">
          <span
            className={`inline-flex items-center gap-1.5 text-xs font-bold uppercase tracking-wider px-3 py-1 ${isQuietLuxury || isOnyx ? "rounded-[4px]" : "rounded-full"
              } mb-3`}
            style={{
              backgroundColor: isQuietLuxury
                ? "rgba(200, 169, 126, 0.14)"
                : isOnyx
                  ? "rgba(212, 178, 106, 0.15)"
                  : isKolm
                    ? "rgba(94, 240, 184, 0.15)"
                    : isLumira
                      ? "rgba(255, 107, 90, 0.12)"
                      : isAldervik
                        ? "rgba(255, 176, 32, 0.15)"
                        : isSage
                          ? "rgba(217, 102, 59, 0.15)"
                          : "rgba(37, 99, 235, 0.08)",
              color: isQuietLuxury
                ? "#c8a97e"
                : isOnyx
                  ? "#D4B26A"
                  : isKolm
                    ? "#5EF0B8"
                    : isLumira
                      ? "#FF6B5A"
                      : isAldervik
                        ? "#FFB020"
                        : isSage
                          ? "#D9663B"
                          : palTokens.primary,
            }}
          >
            <Home className="w-3.5 h-3.5" aria-hidden="true" />
            <span>{ui.ownerFormBadge}</span>
          </span>
          <h2
            id="owner-lead-heading"
            className="text-2xl sm:text-3xl font-bold tracking-tight"
            style={
              isQuietLuxury
                ? { fontFamily: "'Cormorant Garamond', Georgia, serif", color: "#ffffff" }
                : isOnyx
                  ? { fontFamily: "Georgia, serif", color: "#F5F1E8", fontWeight: 400 }
                  : isKolm
                    ? { color: "#ffffff" }
                    : undefined
            }
          >
            {ui.ownerFormTitle}
          </h2>
          <p
            className={`text-sm mt-2 leading-relaxed ${isQuietLuxury
              ? "text-[#9ca6b0]"
              : isOnyx
                ? "text-[#A8A39A]"
                : isKolm
                  ? "text-[#A0AAB5]"
                  : "text-slate-600"
              }`}
          >
            {ui.ownerFormDesc}
          </p>
        </div>

        {leadFeedback && (
          <div
            role={leadFeedback.type === "error" ? "alert" : "status"}
            className={`mb-6 p-4 ${luxRadius} border text-sm flex items-center gap-2.5 ${leadFeedback.type === "success"
              ? "bg-emerald-50 border-emerald-200 text-emerald-900"
              : "bg-red-50 border-red-200 text-red-800"
              }`}
          >
            {leadFeedback.type === "success" ? (
              <CheckCircle2 className="w-5 h-5 text-emerald-600 shrink-0" aria-hidden="true" />
            ) : (
              <AlertCircle className="w-5 h-5 text-red-600 shrink-0" aria-hidden="true" />
            )}
            <span>{leadFeedback.text}</span>
          </div>
        )}

        <form
          method="POST"
          action="/api/send-agency-lead"
          onSubmit={handleOwnerLeadSubmit}
          aria-labelledby="owner-lead-heading"
          className="space-y-5"
        >
          {/* Honeypot field hidden from assistive tech */}
          <div
            style={{
              position: "absolute",
              clipPath: "inset(50%)",
              overflow: "hidden",
              width: "1px",
              height: "1px",
              margin: "-1px",
            }}
            aria-hidden="true"
          >
            <label htmlFor="lead-company-hp">Website</label>
            <input
              id="lead-company-hp"
              name="honeypot"
              type="text"
              tabIndex={-1}
              autoComplete="off"
              value={leadHoneypot}
              onChange={(e) => setLeadHoneypot(e.target.value)}
            />
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            {/* 2 mutually exclusive options exposed as visible radio buttons inside fieldset+legend */}
            <fieldset className="border-0 p-0 m-0">
              <legend
                className={`block text-xs font-semibold mb-1.5 ${isDarkForm ? "text-[#e5e1db]" : "text-slate-700"
                  }`}
              >
                {ui.ownerTxLegend} <span aria-hidden="true">*</span>
              </legend>
              <div className="grid grid-cols-2 gap-2.5">
                {[
                  { key: "prodaja" as const, label: ui.saleFilter },
                  { key: "izdavanje" as const, label: ui.rentFilter },
                ].map((opt) => (
                  <div
                    key={opt.key}
                    className={`flex items-center gap-2 px-3 py-2.5 ${luxRadius} border text-sm font-medium ${leadTx === opt.key
                      ? isQuietLuxury
                        ? "border-[#c8a97e] bg-[#c8a97e]/15 text-white"
                        : isOnyx
                          ? "border-[#D4B26A] bg-[#D4B26A]/15 text-[#F5F1E8]"
                          : isKolm
                            ? "border-[#5EF0B8] bg-[#5EF0B8]/15 text-white"
                            : "border-slate-900 bg-slate-900 text-white"
                      : isDarkForm
                        ? "border-white/15 bg-white/5 text-[#c5cbd1]"
                        : "border-slate-300 bg-white text-slate-700"
                      }`}
                  >
                    <input
                      type="radio"
                      id={`lead-tx-${opt.key}`}
                      name="transactionType"
                      value={opt.key}
                      checked={leadTx === opt.key}
                      onChange={() => setLeadTx(opt.key)}
                      style={{
                        accentColor: isQuietLuxury
                          ? "#c8a97e"
                          : isOnyx
                            ? "#D4B26A"
                            : isKolm
                              ? "#5EF0B8"
                              : isLumira
                                ? "#FF6B5A"
                                : isAldervik
                                  ? "#FFB020"
                                  : isSage
                                    ? "#D9663B"
                                    : palTokens.primary,
                      }}
                    />
                    <label htmlFor={`lead-tx-${opt.key}`} className="cursor-pointer flex-1">
                      {opt.label}
                    </label>
                  </div>
                ))}
              </div>
            </fieldset>

            <div>
              <label
                htmlFor="lead-prop-type"
                className={`block text-xs font-semibold mb-1.5 ${isDarkForm ? "text-[#e5e1db]" : "text-slate-700"
                  }`}
              >
                {ui.ownerPropTypeLabel}
              </label>
              <select
                id="lead-prop-type"
                name="propertyType"
                value={leadPropType}
                onChange={(e) => setLeadPropType(e.target.value)}
                className={`w-full px-3.5 py-2.5 ${luxRadius} border text-sm ${isQuietLuxury
                  ? "bg-[#090B0E] border-white/15 text-white"
                  : isOnyx
                    ? "bg-[#212124] border-[#8A857C] text-[#F5F1E8]"
                    : isKolm
                      ? "bg-[#212427] border-[#8B95A5] text-white"
                      : "bg-white border-slate-300 text-slate-900"
                  }`}
              >
                {Object.values(PROPERTY_TYPES).map((pt) => (
                  <option key={pt.key} value={pt.key}>
                    {getDictLabel(pt, lang)}
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label
                htmlFor="lead-location"
                className={`block text-xs font-semibold mb-1.5 ${isDarkForm ? "text-[#e5e1db]" : "text-slate-700"
                  }`}
              >
                {ui.ownerLocationLabel} <span aria-hidden="true">*</span>
              </label>
              <input
                id="lead-location"
                name="location"
                type="text"
                required
                autoComplete="street-address"
                value={leadLocation}
                onChange={(e) => setLeadLocation(e.target.value)}
                placeholder={ui.ownerLocationPlaceholder}
                className={`w-full px-3.5 py-2.5 ${luxRadius} border text-sm ${isQuietLuxury
                  ? "bg-white/5 border-white/15 text-white placeholder:text-slate-500"
                  : isOnyx
                    ? "bg-[#212124] border-[#8A857C] text-[#F5F1E8] placeholder:text-[#8A857C]"
                    : isKolm
                      ? "bg-[#212427] border-[#8B95A5] text-white placeholder:text-[#8B95A5]"
                      : "bg-white border-slate-300 text-slate-900"
                  }`}
              />
            </div>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-5 gap-4">
            <div>
              <label
                htmlFor="lead-area"
                className={`block text-xs font-semibold mb-1.5 ${isDarkForm ? "text-[#e5e1db]" : "text-slate-700"
                  }`}
              >
                {ui.ownerAreaLabel}
              </label>
              <input
                id="lead-area"
                name="areaSqm"
                type="text"
                inputMode="numeric"
                value={leadArea}
                onChange={(e) => setLeadArea(e.target.value)}
                placeholder="72"
                className={`w-full px-3.5 py-2.5 ${luxRadius} border text-sm ${isQuietLuxury
                  ? "bg-white/5 border-white/15 text-white placeholder:text-slate-500"
                  : isOnyx
                    ? "bg-[#212124] border-[#8A857C] text-[#F5F1E8] placeholder:text-[#8A857C]"
                    : isKolm
                      ? "bg-[#212427] border-[#8B95A5] text-white placeholder:text-[#8B95A5]"
                      : "bg-white border-slate-300 text-slate-900"
                  }`}
              />
            </div>

            <div>
              <label
                htmlFor="lead-price"
                className={`block text-xs font-semibold mb-1.5 ${isDarkForm ? "text-[#e5e1db]" : "text-slate-700"
                  }`}
              >
                {ui.ownerPriceLabel}
              </label>
              <input
                id="lead-price"
                name="expectedPrice"
                type="text"
                inputMode="numeric"
                value={leadPrice}
                onChange={(e) => setLeadPrice(e.target.value)}
                placeholder="165000"
                className={`w-full px-3.5 py-2.5 ${luxRadius} border text-sm ${isQuietLuxury
                  ? "bg-white/5 border-white/15 text-white placeholder:text-slate-500"
                  : isOnyx
                    ? "bg-[#212124] border-[#8A857C] text-[#F5F1E8] placeholder:text-[#8A857C]"
                    : isKolm
                      ? "bg-[#212427] border-[#8B95A5] text-white placeholder:text-[#8B95A5]"
                      : "bg-white border-slate-300 text-slate-900"
                  }`}
              />
            </div>

            <div>
              <label
                htmlFor="lead-owner-name"
                className={`block text-xs font-semibold mb-1.5 ${isDarkForm ? "text-[#e5e1db]" : "text-slate-700"
                  }`}
              >
                {ui.ownerNameLabel} <span aria-hidden="true">*</span>
              </label>
              <input
                id="lead-owner-name"
                name="ownerName"
                type="text"
                required
                autoComplete="name"
                value={leadOwnerName}
                onChange={(e) => setLeadOwnerName(e.target.value)}
                className={`w-full px-3.5 py-2.5 ${luxRadius} border text-sm ${isQuietLuxury
                  ? "bg-white/5 border-white/15 text-white placeholder:text-slate-500"
                  : isOnyx
                    ? "bg-[#212124] border-[#8A857C] text-[#F5F1E8] placeholder:text-[#8A857C]"
                    : isKolm
                      ? "bg-[#212427] border-[#8B95A5] text-white placeholder:text-[#8B95A5]"
                      : "bg-white border-slate-300 text-slate-900"
                  }`}
              />
            </div>

            <div>
              <label
                htmlFor="lead-owner-phone"
                className={`block text-xs font-semibold mb-1.5 ${isDarkForm ? "text-[#e5e1db]" : "text-slate-700"
                  }`}
              >
                {ui.ownerPhoneLabel} <span aria-hidden="true">*</span>
              </label>
              <input
                id="lead-owner-phone"
                name="ownerPhone"
                type="tel"
                required
                autoComplete="tel"
                value={leadOwnerPhone}
                onChange={(e) => setLeadOwnerPhone(e.target.value)}
                placeholder="+381 64 ..."
                className={`w-full px-3.5 py-2.5 ${luxRadius} border text-sm ${isQuietLuxury
                  ? "bg-white/5 border-white/15 text-white placeholder:text-slate-500"
                  : isOnyx
                    ? "bg-[#212124] border-[#8A857C] text-[#F5F1E8] placeholder:text-[#8A857C]"
                    : isKolm
                      ? "bg-[#212427] border-[#8B95A5] text-white placeholder:text-[#8B95A5]"
                      : "bg-white border-slate-300 text-slate-900"
                  }`}
              />
            </div>

            <div>
              <label
                htmlFor="lead-owner-email"
                className={`block text-xs font-semibold mb-1.5 ${isDarkForm ? "text-[#e5e1db]" : "text-slate-700"
                  }`}
              >
                {ui.ownerEmailLabel}
              </label>
              <input
                id="lead-owner-email"
                name="ownerEmail"
                type="email"
                autoComplete="email"
                spellCheck={false}
                autoCapitalize="none"
                autoCorrect="off"
                value={leadOwnerEmail}
                onChange={(e) => setLeadOwnerEmail(e.target.value)}
                className={`w-full px-3.5 py-2.5 ${luxRadius} border text-sm ${isQuietLuxury
                  ? "bg-white/5 border-white/15 text-white placeholder:text-slate-500"
                  : isOnyx
                    ? "bg-[#212124] border-[#8A857C] text-[#F5F1E8] placeholder:text-[#8A857C]"
                    : isKolm
                      ? "bg-[#212427] border-[#8B95A5] text-white placeholder:text-[#8B95A5]"
                      : "bg-white border-slate-300 text-slate-900"
                  }`}
              />
            </div>
          </div>

          <div>
            <label
              htmlFor="lead-notes"
              className={`block text-xs font-semibold mb-1.5 ${isDarkForm ? "text-[#e5e1db]" : "text-slate-700"
                }`}
            >
              {ui.ownerNotesLabel}
            </label>
            <div className="flex flex-col sm:flex-row sm:items-stretch gap-3">
              <textarea
                id="lead-notes"
                name="notes"
                rows={1}
                value={leadNotes}
                onChange={(e) => setLeadNotes(e.target.value)}
                placeholder={ui.ownerNotesPlaceholder}
                className={`block flex-1 min-h-[46px] px-3.5 py-2.5 ${luxRadius} border text-sm leading-snug ${isQuietLuxury
                  ? "bg-white/5 border-white/15 text-white placeholder:text-slate-500"
                  : isOnyx
                    ? "bg-[#212124] border-[#8A857C] text-[#F5F1E8] placeholder:text-[#8A857C]"
                    : isKolm
                      ? "bg-[#212427] border-[#8B95A5] text-white placeholder:text-[#8B95A5]"
                      : "bg-white border-slate-300 text-slate-900"
                  }`}
              />

              <button
                type="submit"
                disabled={leadSubmitting}
                style={{
                  backgroundColor: isQuietLuxury
                    ? "#c8a97e"
                    : isOnyx
                      ? "#D4B26A"
                      : isKolm
                        ? "#5EF0B8"
                        : isLumira
                          ? "#FF6B5A"
                          : isAldervik
                            ? "#FFB020"
                            : isSage
                              ? "#D9663B"
                              : palTokens.primary,
                  color: isQuietLuxury || isOnyx || isKolm || isAldervik ? "#111815" : "#ffffff",
                }}
                className={`inline-flex items-center justify-center gap-2 px-6 min-h-[46px] ${luxRadius} font-bold text-sm transition-opacity hover:opacity-90 disabled:opacity-60 cursor-pointer shrink-0`}
              >
                <Send className="w-4 h-4" aria-hidden="true" />
                <span>{leadSubmitting ? ui.ownerSubmitting : ui.ownerSubmitBtn}</span>
              </button>
            </div>
          </div>
        </form>
      </div>
    </section>
  );

  // ============================================================================
  // SHARED NODE 3: STANDARD CORPORATE FOOTER WITH FULL CONTACT & ADDRESS INFO
  // ============================================================================
  const fullAddressText = [agency.address, agency.city].filter(Boolean).join(", ");
  const googleMapsUrl = fullAddressText
    ? `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(fullAddressText)}`
    : null;

  const footerAccentColor = isOnyx
    ? "#D4B26A"
    : isQuietLuxury
      ? "#c8a97e"
      : isSage
        ? "#D9663B"
        : isKolm
          ? "#5EF0B8"
          : isLumira
            ? "#FF6B5A"
            : isAldervik
              ? "#FFB020"
              : "#60a5fa";

  const footerSubtleLinkColor = isOnyx
    ? "#E6CB93"
    : isQuietLuxury
      ? "#e5e1db"
      : isSage
        ? "#F3D5C8"
        : isKolm
          ? "#B2F8DC"
          : isLumira
            ? "#FFC4BD"
            : isAldervik
              ? "#FFE099"
              : "#93c5fd";

  const standardFooterNode = (
    <footer
      className={`border-t mt-8 ${isOnyx
        ? "bg-[#0F0F10] border-[#3A3A3E] text-[#A8A39A]"
        : isQuietLuxury
          ? "bg-[#07090c] border-white/10 text-[#9ca6b0]"
          : isKolm
            ? "bg-[#181A1C] border-[#3C434A] text-[#A0AAB5]"
            : isLumira
              ? "bg-[#164A6E] border-[#164A6E] text-slate-200"
              : isAldervik
                ? "bg-[#1C293D] border-[#1C293D] text-slate-200"
                : isSage
                  ? "bg-[#24473A] border-[#24473A] text-[#E6EDE8]"
                  : "bg-slate-900 border-slate-800 text-slate-300"
        }`}
    >
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div className="grid grid-cols-1 md:grid-cols-12 gap-8 pb-10 border-b border-white/10">
          {/* Column 1: Agency Identity */}
          <div className="md:col-span-5 space-y-3">
            <div className="flex items-center gap-3">
              {agency.logoUrl ? (
                <img
                  src={agency.logoUrl}
                  alt={agency.name}
                  className={`h-11 w-auto ${luxRadius} bg-white p-1.5 object-contain`}
                />
              ) : (
                <div
                  className={`w-10 h-10 ${luxRadius} flex items-center justify-center text-white`}
                  style={{
                    backgroundColor: footerAccentColor,
                    color: isQuietLuxury || isOnyx || isKolm || isAldervik ? "#111815" : "#ffffff",
                  }}
                >
                  <Building2 className="w-5 h-5" aria-hidden="true" />
                </div>
              )}
              <div>
                <p className="text-base font-bold text-white">{agency.name}</p>
                <p
                  className="text-xs font-medium"
                  style={{ color: footerAccentColor }}
                >
                  {ui.verifiedBadge}
                </p>
              </div>
            </div>
            <p className="text-xs leading-relaxed text-slate-400 max-w-sm">
              {ui.footerAboutDesc}
            </p>
          </div>

          {/* Column 2: Consolidated Contact & Physical Address */}
          <div className="md:col-span-4 space-y-2.5">
            <h3 className="text-xs font-bold uppercase tracking-wider text-white mb-3">
              {ui.footerContactHeading}
            </h3>

            {fullAddressText && (
              <div className="flex items-start gap-2.5 text-xs">
                <MapPin
                  className="w-4 h-4 shrink-0 mt-0.5"
                  style={{ color: footerAccentColor }}
                  aria-hidden="true"
                />
                <div>
                  <span className="text-slate-200 font-medium block">{fullAddressText}</span>
                  {googleMapsUrl && (
                    <a
                      href={googleMapsUrl}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-[11px] underline opacity-80 hover:opacity-100"
                      style={{ color: footerSubtleLinkColor }}
                    >
                      {ui.footerMapLink} ↗
                    </a>
                  )}
                </div>
              </div>
            )}

            {agency.phone && (
              <div className="flex items-center gap-2.5 text-xs">
                <Phone
                  className="w-4 h-4 shrink-0"
                  style={{ color: footerAccentColor }}
                  aria-hidden="true"
                />
                <a
                  href={`tel:${cleanPhoneDigits}`}
                  className="text-slate-200 hover:text-white font-semibold"
                >
                  {agency.phone}
                </a>
              </div>
            )}

            {agency.email && (
              <div className="flex items-center gap-2.5 text-xs">
                <Mail
                  className="w-4 h-4 shrink-0"
                  style={{ color: footerAccentColor }}
                  aria-hidden="true"
                />
                <a
                  href={`mailto:${agency.email}`}
                  className="text-slate-200 hover:text-white"
                >
                  {agency.email}
                </a>
              </div>
            )}
          </div>

          {/* Column 3: Quick Links */}
          <div className="md:col-span-3 space-y-2">
            <h3 className="text-xs font-bold uppercase tracking-wider text-white mb-3">
              {ui.footerQuickLinksHeading}
            </h3>
            <ul className="space-y-1.5 text-xs">
              <li>
                <button
                  type="button"
                  onClick={() => {
                    setFilterTx("all");
                    window.scrollTo({ top: 0, behavior: "smooth" });
                  }}
                  className="hover:text-white cursor-pointer"
                >
                  {ui.allTransactions}
                </button>
              </li>
              <li>
                <button
                  type="button"
                  onClick={() => {
                    setFilterTx("prodaja");
                    window.scrollTo({ top: 0, behavior: "smooth" });
                  }}
                  className="hover:text-white cursor-pointer"
                >
                  {ui.saleFilter}
                </button>
              </li>
              <li>
                <button
                  type="button"
                  onClick={() => {
                    setFilterTx("izdavanje");
                    window.scrollTo({ top: 0, behavior: "smooth" });
                  }}
                  className="hover:text-white cursor-pointer"
                >
                  {ui.rentFilter}
                </button>
              </li>
              <li className="pt-1">
                <a
                  href="#owner-lead-section"
                  className="font-semibold hover:underline"
                  style={{ color: footerSubtleLinkColor }}
                >
                  + {ui.listPropertyBtn}
                </a>
              </li>
            </ul>
          </div>
        </div>

        {/* Bottom Copyright & Hub Link */}
        <div className="pt-6 flex flex-col sm:flex-row items-center justify-between gap-4 text-xs text-slate-400">
          <div className="flex items-center gap-2">
            <Rss
              className="w-3.5 h-3.5"
              style={{ color: footerAccentColor }}
              aria-hidden="true"
            />
            <span>
              © {new Date().getFullYear()} {agency.name} • {ui.poweredBy}
            </span>
          </div>
          <Link
            href="/agency-panel"
            className="hover:text-white inline-flex items-center gap-1 font-medium"
          >
            <span>{ui.agencyHubLink}</span>
            <ExternalLink className="w-3.5 h-3.5" aria-hidden="true" />
          </Link>
        </div>
      </div>
    </footer>
  );

  // ============================================================================
  // SHARED NODE 4: LISTING DETAIL MODAL
  // ============================================================================
  const detailModalNode = selectedListing ? (
    <div
      role="dialog"
      aria-modal="true"
      className="fixed inset-0 z-50 bg-slate-900/75 backdrop-blur-xs flex items-center justify-center p-4 overflow-y-auto"
      onClick={() => {
        setSelectedListing(null);
        setIsViewingFormOpen(false);
        setViewingFeedback(null);
      }}
    >
      <div
        className={`bg-white ${luxCardRadius} max-w-3xl w-full overflow-hidden shadow-xl my-8 text-slate-900`}
        onClick={(e) => e.stopPropagation()}
      >
        <div className="relative h-72 sm:h-96 bg-slate-900">
          {selectedListing.listing_images &&
            selectedListing.listing_images.length > 0 ? (
            <>
              <img
                src={
                  selectedListing.listing_images[activePhotoIdx]?.url ||
                  selectedListing.listing_images[0].url
                }
                alt={selectedListing.title}
                className="w-full h-full object-cover"
              />
              {selectedListing.listing_images.length > 1 && (
                <>
                  <button
                    type="button"
                    onClick={() =>
                      setActivePhotoIdx((prev) =>
                        prev === 0
                          ? selectedListing.listing_images!.length - 1
                          : prev - 1
                      )
                    }
                    className="absolute left-3 top-1/2 -translate-y-1/2 w-9 h-9 rounded-full bg-slate-900/70 text-white flex items-center justify-center hover:bg-slate-900 cursor-pointer"
                  >
                    <ChevronLeft className="w-5 h-5" />
                  </button>
                  <button
                    type="button"
                    onClick={() =>
                      setActivePhotoIdx((prev) =>
                        prev === selectedListing.listing_images!.length - 1
                          ? 0
                          : prev + 1
                      )
                    }
                    className="absolute right-3 top-1/2 -translate-y-1/2 w-9 h-9 rounded-full bg-slate-900/70 text-white flex items-center justify-center hover:bg-slate-900 cursor-pointer"
                  >
                    <ChevronRight className="w-5 h-5" />
                  </button>
                </>
              )}
            </>
          ) : (
            <div className="w-full h-full flex items-center justify-center text-slate-500">
              <Building2 className="w-16 h-16" />
            </div>
          )}

          <button
            type="button"
            onClick={() => {
              setSelectedListing(null);
              setIsViewingFormOpen(false);
              setViewingFeedback(null);
            }}
            className="absolute top-3 right-3 w-9 h-9 rounded-full bg-slate-900/70 text-white flex items-center justify-center hover:bg-slate-900 cursor-pointer"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        <div className="p-6 space-y-5">
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 pb-4 border-b border-slate-100">
            <div>
              <p
                className="text-xs font-semibold mb-1"
                style={{ color: palTokens.primary }}
              >
                {[
                  selectedListing.city,
                  selectedListing.municipality,
                  selectedListing.neighborhood,
                  selectedListing.address,
                ]
                  .filter(Boolean)
                  .join(" • ")}
              </p>
              <h2 className="text-xl font-bold text-slate-900">
                {selectedListing.title}
              </h2>
            </div>
            <div
              className="text-2xl font-extrabold shrink-0"
              style={{ color: palTokens.primary }}
            >
              {formatDisplayPrice(selectedListing)}
            </div>
          </div>

          <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 text-xs">
            {selectedListing.area_sqm && (
              <div className="p-3 rounded-xl bg-slate-50 border border-slate-200">
                <p className="text-slate-500">Površina / m²</p>
                <p className="font-bold text-slate-900 text-sm mt-0.5">
                  {selectedListing.area_sqm} m²
                </p>
              </div>
            )}
            {selectedListing.room_count && (
              <div className="p-3 rounded-xl bg-slate-50 border border-slate-200">
                <p className="text-slate-500">{ui.rooms}</p>
                <p className="font-bold text-slate-900 text-sm mt-0.5">
                  {ROOM_STRUCTURES[selectedListing.room_count]
                    ? getDictLabel(ROOM_STRUCTURES[selectedListing.room_count], lang)
                    : selectedListing.room_count}
                </p>
              </div>
            )}
            {selectedListing.floor && (
              <div className="p-3 rounded-xl bg-slate-50 border border-slate-200">
                <p className="text-slate-500">{ui.floor}</p>
                <p className="font-bold text-slate-900 text-sm mt-0.5">
                  {selectedListing.floor}
                  {selectedListing.total_floors
                    ? ` / ${selectedListing.total_floors}`
                    : ""}
                </p>
              </div>
            )}
            {selectedListing.heating_type && (
              <div className="p-3 rounded-xl bg-slate-50 border border-slate-200">
                <p className="text-slate-500">{ui.heating}</p>
                <p className="font-bold text-slate-900 text-sm mt-0.5">
                  {HEATING_TYPES[selectedListing.heating_type]
                    ? getDictLabel(HEATING_TYPES[selectedListing.heating_type], lang)
                    : selectedListing.heating_type}
                </p>
              </div>
            )}
          </div>

          {selectedListing.description && (
            <div>
              <h3 className="text-xs font-bold uppercase tracking-wider text-slate-500 mb-1.5">
                {ui.descriptionTitle}
              </h3>
              <p className="text-sm text-slate-700 whitespace-pre-line leading-relaxed">
                {selectedListing.description}
              </p>
            </div>
          )}

          {/* Viewing Request Inline Box */}
          {isViewingFormOpen && (
            <div className="p-4 sm:p-5 rounded-2xl bg-blue-50/70 border border-blue-200/90 space-y-3">
              <div className="flex items-start justify-between gap-2">
                <div>
                  <h4 className="text-sm font-bold text-blue-950 flex items-center gap-1.5">
                    <Calendar className="w-4 h-4 text-blue-700" />
                    <span>{ui.viewingModalTitle}</span>
                  </h4>
                  <p className="text-xs text-blue-800/80 mt-0.5">
                    {ui.viewingModalDesc}
                  </p>
                </div>
                <button
                  type="button"
                  onClick={() => setIsViewingFormOpen(false)}
                  className="p-1 rounded-lg text-blue-700 hover:bg-blue-100 cursor-pointer"
                >
                  <X className="w-4 h-4" />
                </button>
              </div>

              {viewingFeedback ? (
                <div
                  className={`p-3 rounded-xl text-xs font-medium ${viewingFeedback.type === "success"
                    ? "bg-emerald-100 text-emerald-900 border border-emerald-300"
                    : "bg-red-100 text-red-900 border border-red-300"
                    }`}
                >
                  {viewingFeedback.text}
                </div>
              ) : (
                <form onSubmit={handleViewingLeadSubmit} className="space-y-3">
                  <input
                    type="text"
                    name="website_url_check"
                    value={viewingHoneypot}
                    onChange={(e) => setViewingHoneypot(e.target.value)}
                    tabIndex={-1}
                    autoComplete="off"
                    style={{
                      position: "absolute",
                      opacity: 0,
                      height: 0,
                      width: 0,
                      pointerEvents: "none",
                    }}
                    aria-hidden="true"
                  />

                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                    <div>
                      <label className="block text-xs font-semibold text-slate-700 mb-1">
                        {ui.ownerNameLabel} <span className="text-red-500">*</span>
                      </label>
                      <input
                        type="text"
                        required
                        value={viewingName}
                        onChange={(e) => setViewingName(e.target.value)}
                        placeholder="Nikola Petrović"
                        className="w-full px-3 py-2 rounded-xl bg-white border border-slate-300 text-xs focus:ring-2 focus:ring-blue-500 focus:outline-none"
                      />
                    </div>
                    <div>
                      <label className="block text-xs font-semibold text-slate-700 mb-1">
                        {ui.ownerPhoneLabel} <span className="text-red-500">*</span>
                      </label>
                      <input
                        type="tel"
                        required
                        value={viewingPhone}
                        onChange={(e) => setViewingPhone(e.target.value)}
                        placeholder="+381 6..."
                        className="w-full px-3 py-2 rounded-xl bg-white border border-slate-300 text-xs focus:ring-2 focus:ring-blue-500 focus:outline-none"
                      />
                    </div>
                  </div>

                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                    <div>
                      <label className="block text-xs font-semibold text-slate-700 mb-1">
                        {ui.ownerEmailLabel}
                      </label>
                      <input
                        type="email"
                        value={viewingEmail}
                        onChange={(e) => setViewingEmail(e.target.value)}
                        placeholder="nikola@example.com"
                        className="w-full px-3 py-2 rounded-xl bg-white border border-slate-300 text-xs focus:ring-2 focus:ring-blue-500 focus:outline-none"
                      />
                    </div>
                    <div>
                      <label className="block text-xs font-semibold text-slate-700 mb-1">
                        {ui.viewingPreferredTimeLabel}
                      </label>
                      <input
                        type="text"
                        value={viewingNotes}
                        onChange={(e) => setViewingNotes(e.target.value)}
                        placeholder={ui.viewingPreferredTimePlaceholder}
                        className="w-full px-3 py-2 rounded-xl bg-white border border-slate-300 text-xs focus:ring-2 focus:ring-blue-500 focus:outline-none"
                      />
                    </div>
                  </div>

                  <div className="flex items-center justify-end gap-2 pt-1">
                    <button
                      type="button"
                      onClick={() => setIsViewingFormOpen(false)}
                      className="px-3 py-1.5 rounded-lg text-xs font-semibold text-slate-600 hover:bg-slate-200/60 cursor-pointer"
                    >
                      {ui.closeBtn}
                    </button>
                    <button
                      type="submit"
                      disabled={viewingSubmitting}
                      style={{
                        backgroundColor: palTokens.primary,
                        color: isKolm || isAldervik || isOnyx ? "#111815" : "#ffffff",
                      }}
                      className="px-4 py-2 rounded-xl text-xs font-bold shadow-xs hover:opacity-95 disabled:opacity-50 cursor-pointer flex items-center gap-1.5"
                    >
                      <Calendar className="w-3.5 h-3.5" />
                      <span>{viewingSubmitting ? ui.ownerSubmitting : ui.viewingSubmitBtn}</span>
                    </button>
                  </div>
                </form>
              )}
            </div>
          )}

          <div className="pt-4 border-t border-slate-100 flex flex-wrap items-center justify-between gap-3">
            <div className="text-xs text-slate-500 font-semibold">
              {agency.name}
              {selectedListing.external_ref
                ? ` • ${ui.refCode}: #${selectedListing.external_ref}`
                : ""}
            </div>
            <div className="flex flex-wrap items-center gap-2">
              <button
                type="button"
                onClick={() => {
                  setIsViewingFormOpen((prev) => !prev);
                  setViewingFeedback(null);
                }}
                style={{
                  backgroundColor: palTokens.primary,
                  color: isKolm || isAldervik || isOnyx ? "#111815" : "#ffffff",
                }}
                className="inline-flex items-center gap-1.5 px-4 py-2 rounded-xl text-xs font-bold shadow-xs hover:opacity-95 transition-opacity cursor-pointer"
              >
                <Calendar className="w-3.5 h-3.5" />
                <span>{ui.viewingBtn}</span>
              </button>

              {agency.phone && (
                <a
                  href={`tel:${cleanPhoneDigits}`}
                  className="inline-flex items-center gap-1.5 px-4 py-2 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-800 text-xs font-semibold"
                >
                  <Phone className="w-3.5 h-3.5" />
                  <span>{agency.phone}</span>
                </a>
              )}
              {agency.email && (
                <a
                  href={`mailto:${agency.email}`}
                  className="inline-flex items-center gap-1.5 px-4 py-2 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-800 text-xs font-semibold"
                >
                  <Mail className="w-3.5 h-3.5" />
                  <span>{ui.emailAgency}</span>
                </a>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  ) : null;

  // ============================================================================
  // TEMPLATE A: QUIET LUXURY (Architectural Obsidian + Travertine Stone)
  // ============================================================================
  if (isQuietLuxury) {
    return (
      <div
        className="min-h-screen flex flex-col"
        style={{
          backgroundColor: "#090B0E",
          color: "#ffffff",
          backgroundImage:
            "radial-gradient(circle at 18% 10%, rgba(0, 60, 82, 0.28) 0%, transparent 45%), radial-gradient(circle at 82% 70%, rgba(200, 169, 126, 0.06) 0%, transparent 45%)",
        }}
      >
        {/* Top Luxury Header Bar */}
        <header
          style={{
            backgroundColor: "rgba(9, 11, 14, 0.92)",
            backdropFilter: "blur(16px)",
            borderBottom: "1px solid rgba(229, 225, 219, 0.1)",
          }}
          className="sticky top-0 z-40"
        >
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 sm:h-20 flex items-center justify-between gap-3 sm:gap-4">
            <div className="flex items-center gap-2.5 sm:gap-3.5 min-w-0">
              {agency.logoUrl ? (
                <img
                  src={agency.logoUrl}
                  alt={agency.name}
                  className="h-9 sm:h-11 w-auto object-contain shrink-0"
                />
              ) : (
                <div
                  className="w-9 h-9 sm:w-10 sm:h-10 flex items-center justify-center border rounded-[4px] shrink-0"
                  style={{
                    borderColor: "#c8a97e",
                    color: "#c8a97e",
                    backgroundColor: "rgba(200, 169, 126, 0.08)",
                  }}
                >
                  <Building2 className="w-4 h-4 sm:w-5 sm:h-5" />
                </div>
              )}
              <div className="min-w-0">
                <span
                  className="block text-base sm:text-xl tracking-wide font-serif truncate"
                  style={{
                    color: "#e5e1db",
                    fontFamily: "'Cormorant Garamond', Georgia, serif",
                  }}
                >
                  {agency.name}
                </span>
                <span
                  className="block text-[10px] uppercase tracking-[0.2em] truncate"
                  style={{ color: "#c8a97e" }}
                >
                  {[agency.address, agency.city].filter(Boolean).join(" • ") || "Beograd"}
                </span>
              </div>
            </div>

            {/* Desktop Actions */}
            <div className="hidden md:flex items-center gap-2.5 shrink-0">
              <a
                href="#owner-lead-section"
                className="inline-flex items-center gap-1.5 px-3.5 py-2 text-xs font-semibold border transition-colors rounded-[4px]"
                style={{
                  borderColor: "rgba(200, 169, 126, 0.45)",
                  color: "#c8a97e",
                }}
              >
                <Home className="w-3.5 h-3.5" aria-hidden="true" />
                <span>{ui.listPropertyBtn}</span>
              </a>

              {/* Currency Switcher */}
              {showcaseCurrencies.length > 1 && (
                <div
                  className="flex items-center px-2 py-1 border text-xs rounded-[4px] gap-1"
                  style={{
                    backgroundColor: "rgba(255,255,255,0.04)",
                    borderColor: "rgba(229, 225, 219, 0.12)",
                  }}
                >
                  {showcaseCurrencies.map((c, idx) => (
                    <React.Fragment key={c}>
                      {idx > 0 && <span className="text-white/20">|</span>}
                      <button
                        type="button"
                        onClick={() => setDisplayCurrency(c)}
                        className="px-1.5 cursor-pointer uppercase font-semibold"
                        style={{
                          color: displayCurrency === c ? "#c8a97e" : "#7d8892",
                          fontWeight: displayCurrency === c ? 700 : 400,
                        }}
                      >
                        {c}
                      </button>
                    </React.Fragment>
                  ))}
                </div>
              )}

              {/* Language Switcher */}
              {showcaseLanguages.length > 1 && (
                <div
                  className="flex items-center px-2 py-1 border text-xs rounded-[4px]"
                  style={{
                    backgroundColor: "rgba(255,255,255,0.04)",
                    borderColor: "rgba(229, 225, 219, 0.12)",
                  }}
                >
                  {showcaseLanguages.map((l) => (
                    <button
                      key={l}
                      type="button"
                      onClick={() => setLang(l)}
                      className="px-1.5 uppercase cursor-pointer"
                      style={{
                        color: lang === l ? "#c8a97e" : "#7d8892",
                        fontWeight: lang === l ? 700 : 400,
                      }}
                    >
                      {SHOWCASE_LANG_META[l]?.short || l}
                    </button>
                  ))}
                </div>
              )}

              {agency.phone && (
                <a
                  href={`tel:${cleanPhoneDigits}`}
                  className="inline-flex items-center gap-2 px-4 py-2 text-xs font-semibold uppercase tracking-wider transition-colors rounded-[4px]"
                  style={{
                    backgroundColor: "#c8a97e",
                    color: "#090B0E",
                  }}
                >
                  <Phone className="w-3.5 h-3.5" />
                  <span>{agency.phone}</span>
                </a>
              )}
            </div>

            {/* Mobile Actions: Call Icon Button + Luxury Hamburger Toggle */}
            <div className="flex md:hidden items-center gap-2 shrink-0">
              {agency.phone && (
                <a
                  href={`tel:${cleanPhoneDigits}`}
                  style={{ backgroundColor: "#c8a97e", color: "#090B0E" }}
                  className="w-9 h-9 rounded-[4px] flex items-center justify-center shadow-xs active:scale-95 transition-transform"
                  aria-label={agency.phone}
                >
                  <Phone className="w-4 h-4" />
                </a>
              )}

              <button
                type="button"
                onClick={() => setMobileMenuOpen((prev) => !prev)}
                className="w-9 h-9 rounded-[4px] flex items-center justify-center border transition-colors cursor-pointer"
                style={{
                  borderColor: "rgba(200, 169, 126, 0.45)",
                  color: "#c8a97e",
                  backgroundColor: "rgba(200, 169, 126, 0.08)",
                }}
                aria-label="Toggle Menu"
              >
                {mobileMenuOpen ? (
                  <X className="w-5 h-5" />
                ) : (
                  <Menu className="w-5 h-5" />
                )}
              </button>
            </div>
          </div>

          {/* Quiet Luxury Mobile Drawer */}
          {mobileMenuOpen && (
            <div
              className="md:hidden border-t px-4 py-4 space-y-4 animate-in slide-in-from-top-2 duration-150"
              style={{
                backgroundColor: "rgba(9, 11, 14, 0.98)",
                borderColor: "rgba(200, 169, 126, 0.2)",
              }}
            >
              {/* Agency Details */}
              <div className="flex items-center justify-between pb-3 border-b border-white/10">
                <div className="min-w-0">
                  <p
                    className="text-sm font-serif truncate"
                    style={{
                      color: "#e5e1db",
                      fontFamily: "'Cormorant Garamond', Georgia, serif",
                    }}
                  >
                    {agency.name}
                  </p>
                  <p className="text-[11px] text-[#c8a97e] mt-0.5 truncate">
                    {[agency.address, agency.city].filter(Boolean).join(" • ") || "Beograd"}
                  </p>
                </div>
              </div>

              {/* List Property Action */}
              <a
                href="#owner-lead-section"
                onClick={() => setMobileMenuOpen(false)}
                className="w-full flex items-center justify-center gap-2 py-2.5 px-4 text-xs font-semibold uppercase tracking-wider border rounded-[4px] transition-colors"
                style={{
                  borderColor: "rgba(200, 169, 126, 0.45)",
                  color: "#c8a97e",
                  backgroundColor: "rgba(200, 169, 126, 0.08)",
                }}
              >
                <Home className="w-4 h-4" />
                <span>{ui.listPropertyBtn}</span>
              </a>

              {/* Direct Phone / Contact */}
              {agency.phone && (
                <a
                  href={`tel:${cleanPhoneDigits}`}
                  className="w-full flex items-center justify-center gap-2 py-2.5 px-4 text-xs font-semibold uppercase tracking-wider rounded-[4px] transition-colors"
                  style={{
                    backgroundColor: "#c8a97e",
                    color: "#090B0E",
                  }}
                >
                  <Phone className="w-3.5 h-3.5" />
                  <span>{agency.phone}</span>
                </a>
              )}

              {/* Currency & Language Row */}
              <div className="pt-2 border-t border-white/10 space-y-3">
                {/* Currency Switcher */}
                {showcaseCurrencies.length > 1 && (
                  <div className="flex items-center justify-between">
                    <span className="text-[11px] uppercase tracking-wider text-white/50">
                      Valuta / Currency
                    </span>
                    <div
                      className="flex items-center px-2 py-1 border text-xs rounded-[4px] gap-1"
                      style={{
                        backgroundColor: "rgba(255,255,255,0.04)",
                        borderColor: "rgba(229, 225, 219, 0.12)",
                      }}
                    >
                      {showcaseCurrencies.map((c, idx) => (
                        <React.Fragment key={c}>
                          {idx > 0 && <span className="text-white/20">|</span>}
                          <button
                            type="button"
                            onClick={() => setDisplayCurrency(c)}
                            className="px-1.5 py-0.5 cursor-pointer uppercase font-semibold"
                            style={{
                              color: displayCurrency === c ? "#c8a97e" : "#7d8892",
                              fontWeight: displayCurrency === c ? 700 : 400,
                            }}
                          >
                            {c}
                          </button>
                        </React.Fragment>
                      ))}
                    </div>
                  </div>
                )}

                {/* Language Switcher */}
                {showcaseLanguages.length > 1 && (
                  <div>
                    <span className="block text-[11px] uppercase tracking-wider text-white/50 mb-1.5">
                      Jezik / Language
                    </span>
                    <div
                      className="grid gap-1.5"
                      style={{
                        gridTemplateColumns: `repeat(${Math.min(showcaseLanguages.length, 5)}, minmax(0, 1fr))`,
                      }}
                    >
                      {showcaseLanguages.map((l) => {
                        const item = SHOWCASE_LANG_META[l] || { code: l, short: l, label: l };
                        return (
                          <button
                            key={item.code}
                            type="button"
                            onClick={() => {
                              setLang(item.code);
                              setMobileMenuOpen(false);
                            }}
                            className="py-2 rounded-[4px] text-xs font-semibold uppercase tracking-wider border cursor-pointer text-center transition-colors"
                            style={{
                              borderColor:
                                lang === item.code
                                  ? "#c8a97e"
                                  : "rgba(229, 225, 219, 0.12)",
                              backgroundColor:
                                lang === item.code
                                  ? "rgba(200, 169, 126, 0.2)"
                                  : "rgba(255,255,255,0.04)",
                              color: lang === item.code ? "#c8a97e" : "#7d8892",
                            }}
                          >
                            {item.short}
                          </button>
                        );
                      })}
                    </div>
                  </div>
                )}
              </div>
            </div>
          )}
        </header>

        {/* Cinematic Architectural Hero */}
        <section className="relative py-20 sm:py-28 px-4 overflow-hidden">
          <div
            className="absolute inset-0 z-0"
            style={{
              backgroundImage:
                "linear-gradient(to bottom, rgba(9, 11, 14, 0.45) 0%, rgba(9, 11, 14, 0.82) 70%, #090B0E 100%), url('https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=2400&q=85')",
              backgroundSize: "cover",
              backgroundPosition: "center 40%",
            }}
          />

          <div className="relative z-10 max-w-5xl mx-auto text-center">
            <div className="inline-flex items-center gap-2.5 mb-4">
              <span className="w-6 h-px" style={{ backgroundColor: "#c8a97e" }} />
              <span
                className="text-xs font-semibold uppercase tracking-[0.22em]"
                style={{ color: "#c8a97e" }}
              >
                {ui.luxuryEyebrow}
              </span>
              <span className="w-6 h-px" style={{ backgroundColor: "#c8a97e" }} />
            </div>

            <h1
              className="text-3xl sm:text-5xl lg:text-6xl font-normal tracking-tight mb-5"
              style={{
                fontFamily: "'Cormorant Garamond', Georgia, serif",
                color: "#ffffff",
              }}
            >
              {agency.name}
            </h1>

            <p
              className="text-sm sm:text-base max-w-2xl mx-auto mb-10 font-light leading-relaxed"
              style={{ color: "#c5cbd1" }}
            >
              {ui.luxurySubtitle}
            </p>

            {/* Floating Glass Filter Bar */}
            <div
              className="max-w-4xl mx-auto p-4 text-left rounded-[4px]"
              style={{
                backgroundColor: "rgba(9, 11, 14, 0.88)",
                backdropFilter: "blur(16px)",
                border: "1px solid rgba(200, 169, 126, 0.35)",
                boxShadow: "0 24px 60px rgba(0,0,0,0.55)",
              }}
            >
              <div className="flex flex-wrap items-center justify-between gap-2 pb-3 mb-3 border-b border-white/10">
                <div className="flex flex-wrap items-center gap-2">
                  {[
                    { key: "all", label: ui.allTransactions },
                    { key: "prodaja", label: ui.saleFilter },
                    { key: "izdavanje", label: ui.rentFilter },
                  ].map((tab) => (
                    <button
                      key={tab.key}
                      type="button"
                      onClick={() => setFilterTx(tab.key)}
                      className="px-3 py-1 text-xs uppercase tracking-wider font-semibold cursor-pointer transition-colors rounded-[4px]"
                      style={{
                        backgroundColor:
                          filterTx === tab.key ? "#c8a97e" : "transparent",
                        color: filterTx === tab.key ? "#090B0E" : "#c5cbd1",
                      }}
                    >
                      {tab.label}
                    </button>
                  ))}
                </div>

                <div className="flex items-center gap-2">
                  {activeFiltersCount > 0 && (
                    <button
                      type="button"
                      onClick={resetAllFilters}
                      className="flex items-center gap-1 px-2 py-1 text-xs text-[#c8a97e] hover:text-white transition-colors cursor-pointer"
                      title={ui.resetFilters}
                    >
                      <RotateCcw className="w-3.5 h-3.5" />
                      <span>{ui.resetFilters}</span>
                    </button>
                  )}
                  <button
                    type="button"
                    onClick={() => setShowAdvancedFilters((prev) => !prev)}
                    className="flex items-center gap-1.5 px-3 py-1 text-xs uppercase tracking-wider font-semibold cursor-pointer transition-colors rounded-[4px] border"
                    style={{
                      borderColor:
                        showAdvancedFilters || activeFiltersCount > 0
                          ? "#c8a97e"
                          : "rgba(255,255,255,0.2)",
                      backgroundColor: showAdvancedFilters
                        ? "rgba(200, 169, 126, 0.15)"
                        : "transparent",
                      color:
                        showAdvancedFilters || activeFiltersCount > 0
                          ? "#c8a97e"
                          : "#c5cbd1",
                    }}
                  >
                    <SlidersHorizontal className="w-3.5 h-3.5" />
                    <span>
                      {showAdvancedFilters ? ui.hideFiltersBtn : ui.advancedFiltersBtn}
                    </span>
                    {activeFiltersCount > 0 && (
                      <span className="ml-1 px-1.5 py-0.2 bg-[#c8a97e] text-[#090B0E] font-bold text-[10px] rounded-full">
                        {activeFiltersCount}
                      </span>
                    )}
                  </button>
                </div>
              </div>

              <div className="grid grid-cols-12 gap-2.5 sm:gap-3 items-center">
                <div className="col-span-12 sm:col-span-5 relative">
                  <Search className="w-4 h-4 text-[#c8a97e] absolute left-3 top-1/2 -translate-y-1/2" />
                  <input
                    type="search"
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    placeholder={ui.searchPlaceholder}
                    aria-label={ui.searchPlaceholder}
                    className={`w-full pl-9 pr-3 py-2 text-sm bg-white/5 border border-white/10 text-white placeholder:text-slate-400 focus:outline-none focus:border-[#c8a97e] ${luxRadius}`}
                  />
                </div>
                <div className="col-span-6 sm:col-span-4">
                  <select
                    value={filterType}
                    onChange={(e) => setFilterType(e.target.value)}
                    aria-label={ui.allTypes}
                    className={`w-full px-3 py-2 text-xs sm:text-sm bg-[#101419] border border-white/10 text-white focus:outline-none focus:border-[#c8a97e] ${luxRadius}`}
                  >
                    <option value="all">{ui.allTypes}</option>
                    {Object.values(PROPERTY_TYPES).map((pt) => (
                      <option key={pt.key} value={pt.key}>
                        {getDictLabel(pt, lang)}
                      </option>
                    ))}
                  </select>
                </div>
                <div className="col-span-6 sm:col-span-3">
                  <select
                    value={sortBy}
                    onChange={(e) => setSortBy(e.target.value)}
                    aria-label={ui.sortBy}
                    className={`w-full px-3 py-2 text-sm bg-[#101419] border border-white/10 text-white focus:outline-none focus:border-[#c8a97e] ${luxRadius}`}
                  >
                    {SORT_OPTIONS.map((opt) => (
                      <option key={opt.key} value={opt.key}>
                        {opt.label}
                      </option>
                    ))}
                  </select>
                </div>
              </div>

              {/* Advanced Filters Expandable Drawer */}
              {showAdvancedFilters && (
                <div className="mt-4 pt-4 border-t border-white/10 space-y-4">
                  <div className="grid grid-cols-1 sm:grid-cols-12 gap-3 items-end">
                    {/* Location */}
                    <div className="sm:col-span-4">
                      <label className="block text-xs uppercase tracking-wider text-[#c8a97e] mb-1 font-medium">
                        {ui.allLocations}
                      </label>
                      <select
                        value={filterLocation}
                        onChange={(e) => setFilterLocation(e.target.value)}
                        className={`w-full px-3 py-2 text-sm bg-[#101419] border border-white/10 text-white focus:outline-none focus:border-[#c8a97e] ${luxRadius}`}
                      >
                        <option value="all">{ui.allLocations}</option>
                        {availableLocations.map((loc) => (
                          <option key={loc} value={loc}>
                            {loc}
                          </option>
                        ))}
                      </select>
                    </div>

                    {/* Price Range */}
                    <div className="sm:col-span-4">
                      <label className="block text-xs uppercase tracking-wider text-[#c8a97e] mb-1 font-medium">
                        {ui.priceRange} (€)
                      </label>
                      <div className="grid grid-cols-2 gap-2">
                        <input
                          type="number"
                          value={filterMinPrice}
                          onChange={(e) => setFilterMinPrice(e.target.value)}
                          placeholder={ui.minPrice}
                          className={`w-full px-3 py-2 text-sm bg-white/5 border border-white/10 text-white placeholder:text-slate-500 focus:outline-none focus:border-[#c8a97e] ${luxRadius}`}
                        />
                        <input
                          type="number"
                          value={filterMaxPrice}
                          onChange={(e) => setFilterMaxPrice(e.target.value)}
                          placeholder={ui.maxPrice}
                          className={`w-full px-3 py-2 text-sm bg-white/5 border border-white/10 text-white placeholder:text-slate-500 focus:outline-none focus:border-[#c8a97e] ${luxRadius}`}
                        />
                      </div>
                    </div>

                    {/* Area Range */}
                    <div className="sm:col-span-4">
                      <label className="block text-xs uppercase tracking-wider text-[#c8a97e] mb-1 font-medium">
                        {ui.areaRange} (m²)
                      </label>
                      <div className="grid grid-cols-2 gap-2">
                        <input
                          type="number"
                          value={filterMinArea}
                          onChange={(e) => setFilterMinArea(e.target.value)}
                          placeholder={ui.minArea}
                          className={`w-full px-3 py-2 text-sm bg-white/5 border border-white/10 text-white placeholder:text-slate-500 focus:outline-none focus:border-[#c8a97e] ${luxRadius}`}
                        />
                        <input
                          type="number"
                          value={filterMaxArea}
                          onChange={(e) => setFilterMaxArea(e.target.value)}
                          placeholder={ui.maxArea}
                          className={`w-full px-3 py-2 text-sm bg-white/5 border border-white/10 text-white placeholder:text-slate-500 focus:outline-none focus:border-[#c8a97e] ${luxRadius}`}
                        />
                      </div>
                    </div>
                  </div>

                  {/* Room Structure Pills */}
                  <div>
                    <label className="block text-xs uppercase tracking-wider text-[#c8a97e] mb-1.5 font-medium">
                      {ui.roomStructure}
                    </label>
                    <div className="flex flex-wrap gap-1.5">
                      {["all", "1.0", "1.5", "2.0", "2.5", "3.0", "3.5", "4.0+"].map((r) => (
                        <button
                          key={r}
                          type="button"
                          onClick={() => setFilterRooms(r)}
                          className={`px-3 py-1 text-xs font-semibold rounded-[4px] border transition-colors cursor-pointer ${filterRooms === r
                            ? "bg-[#c8a97e] text-[#090B0E] border-[#c8a97e]"
                            : "bg-white/5 text-[#c5cbd1] border-white/10 hover:border-white/30"
                            }`}
                        >
                          {r === "all" ? ui.allRooms : r}
                        </button>
                      ))}
                    </div>
                  </div>

                  {/* Amenities / Key Features */}
                  <div>
                    <label className="block text-xs uppercase tracking-wider text-[#c8a97e] mb-1.5 font-medium">
                      {ui.featuresLabel}
                    </label>
                    <div className="flex flex-wrap gap-2">
                      {AMENITY_OPTIONS.map((am) => {
                        const isChecked = filterAmenities.includes(am.key);
                        return (
                          <button
                            key={am.key}
                            type="button"
                            onClick={() => toggleAmenity(am.key)}
                            className={`flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium rounded-[4px] border transition-colors cursor-pointer ${isChecked
                              ? "bg-[#c8a97e]/20 text-[#c8a97e] border-[#c8a97e]"
                              : "bg-white/5 text-[#c5cbd1] border-white/10 hover:border-white/30"
                              }`}
                          >
                            <div
                              className={`w-3.5 h-3.5 rounded flex items-center justify-center border ${isChecked
                                ? "bg-[#c8a97e] border-[#c8a97e] text-[#090B0E]"
                                : "border-white/30"
                                }`}
                            >
                              {isChecked && <Check className="w-3 h-3 stroke-[3]" />}
                            </div>
                            <span>{am.label}</span>
                          </button>
                        );
                      })}
                    </div>
                  </div>
                </div>
              )}
            </div>
          </div>
        </section>

        {/* Travertine Stone Monograph Cards Grid */}
        <main className="max-w-7xl mx-auto w-full px-4 sm:px-6 lg:px-8 pb-8 flex-1">
          {filteredListings.length === 0 ? (
            <div
              className={`p-12 text-center border ${luxCardRadius}`}
              style={{
                backgroundColor: "rgba(16, 21, 28, 0.75)",
                borderColor: "rgba(229, 225, 219, 0.12)",
              }}
            >
              <p className="text-lg font-serif text-[#e5e1db]">{ui.noListingsTitle}</p>
              <p className="text-xs text-[#7d8892] mt-1">{ui.noListingsDesc}</p>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-7">
              {filteredListings.map((item) => {
                const imgs = item.listing_images || [];
                const cover = imgs.find((i) => i.is_cover)?.url || imgs[0]?.url;
                const isFav = Boolean(favorites[item.id]);

                return (
                  <article
                    key={item.id}
                    id={`listing-${item.id}`}
                    onClick={() => {
                      setSelectedListing(item);
                      setActivePhotoIdx(0);
                    }}
                    className={`group cursor-pointer flex flex-col overflow-hidden transition-transform duration-300 hover:-translate-y-1 ${luxCardRadius}`}
                    style={{
                      backgroundColor: "#EAE6DF",
                      border: "1px solid rgba(255, 255, 255, 0.08)",
                      boxShadow: "0 8px 24px rgba(0, 0, 0, 0.35)",
                    }}
                  >
                    <div
                      className="relative w-full overflow-hidden"
                      style={{
                        paddingTop: "66.66%",
                        backgroundColor: "#002938",
                      }}
                    >
                      {cover ? (
                        <img
                          src={cover}
                          alt={item.title}
                          className="absolute inset-0 w-full h-full object-cover group-hover:scale-105 transition-transform duration-700"
                        />
                      ) : (
                        <div className="absolute inset-0 flex items-center justify-center text-white/30">
                          <Building2 className="w-12 h-12" />
                        </div>
                      )}

                      <button
                        type="button"
                        onClick={(e) => toggleFav(item.id, e)}
                        className="absolute top-3.5 right-3.5 w-9 h-9 rounded-full flex items-center justify-center cursor-pointer"
                        style={{
                          backgroundColor: "rgba(8, 12, 16, 0.55)",
                          backdropFilter: "blur(8px)",
                          border: "1px solid rgba(255, 255, 255, 0.18)",
                          color: isFav ? "#E5A96D" : "#F0ECE6",
                        }}
                      >
                        <Heart
                          className="w-4 h-4"
                          fill={isFav ? "#E5A96D" : "none"}
                        />
                      </button>

                      <div
                        className="absolute bottom-3 right-3 px-2.5 py-0.5 text-[11px] font-semibold"
                        style={{
                          backgroundColor: "rgba(5, 8, 11, 0.72)",
                          color: "#F0ECE6",
                          border: "1px solid rgba(255, 255, 255, 0.12)",
                        }}
                      >
                        1 / {Math.max(imgs.length, 1)}
                      </div>
                    </div>

                    <div
                      className="p-6 flex flex-col flex-1"
                      style={{ backgroundColor: "#EAE6DF", color: "#1A1D20" }}
                    >
                      <div className="mb-1.5">
                        <span
                          className="text-xs font-bold uppercase tracking-[0.14em]"
                          style={{ color: "#003C52" }}
                        >
                          {[item.municipality || item.city, item.neighborhood]
                            .filter(Boolean)
                            .join(" • ")}
                        </span>
                      </div>

                      <div className="mb-2 flex items-baseline gap-1.5">
                        <span
                          className="text-2xl font-bold tracking-tight"
                          style={{ color: "#003C52" }}
                        >
                          {formatDisplayPrice(item)}
                        </span>
                        {item.transaction_type === "izdavanje" && (
                          <span className="text-xs font-medium text-[#6F665C]">
                            {ui.perMonth}
                          </span>
                        )}
                      </div>

                      <h2
                        className="text-xl font-semibold leading-snug mb-3 line-clamp-2"
                        style={{
                          fontFamily: "'Cormorant Garamond', Georgia, serif",
                          color: "#003C52",
                        }}
                      >
                        {item.title}
                      </h2>

                      <div
                        className="pt-3 mt-auto flex flex-wrap items-center justify-between gap-2 text-xs"
                        style={{
                          borderTop: "1px solid #D6CFCC",
                          color: "#5C544B",
                        }}
                      >
                        <div className="flex items-center gap-2 font-medium">
                          {item.area_sqm && <span>{item.area_sqm} m²</span>}
                          {item.room_count && (
                            <>
                              <span>·</span>
                              <span>{item.room_count}</span>
                            </>
                          )}
                          {item.floor && (
                            <>
                              <span>·</span>
                              <span>
                                {ui.floor} {item.floor}
                              </span>
                            </>
                          )}
                        </div>

                        <div className="flex items-center gap-3">
                          <button
                            type="button"
                            onClick={(e) => {
                              e.stopPropagation();
                              setSelectedListing(item);
                              setActivePhotoIdx(0);
                              setIsViewingFormOpen(true);
                            }}
                            className="inline-flex items-center gap-1 font-bold hover:underline cursor-pointer text-xs"
                            style={{ color: "#003C52" }}
                            title={ui.viewingBtn}
                          >
                            <Calendar className="w-3.5 h-3.5" />
                            <span className="hidden sm:inline">{ui.viewingBtn}</span>
                          </button>
                          <span
                            className="inline-flex items-center gap-1 font-bold"
                            style={{ color: "#003C52" }}
                          >
                            <span>{ui.viewDetails}</span>
                            <ArrowRight className="w-3.5 h-3.5 group-hover:translate-x-1 transition-transform" />
                          </span>
                        </div>
                      </div>
                    </div>
                  </article>
                );
              })}
            </div>
          )}
        </main>

        {/* Property Owner Consignment Form */}
        {ownerConsignmentSectionNode}

        {detailModalNode}
        {floatingContactNode}
        {standardFooterNode}
      </div>
    );
  }

  // ============================================================================
  // TEMPLATE B & C: MODERN CORPORATE, NORDIC MINIMALIST, KOLM, LUMIRA, ALDERVIK, SAGE, ONYX
  // ============================================================================
  const isLightHeader = isMinimal || isLumira || isAldervik || isSage;

  return (
    <div
      className={`min-h-screen flex flex-col font-sans ${isOnyx
        ? "bg-[#0F0F10] text-[#F5F1E8]"
        : isKolm
          ? "bg-[#212427] text-[#F8FAFC]"
          : isLumira
            ? "bg-[#ECF3F8] text-[#164A6E]"
            : isAldervik
              ? "bg-[#F3EFEA] text-[#1C293D]"
              : isSage
                ? "bg-[#F6F4EE] text-[#24473A]"
                : isMinimal
                  ? "bg-stone-50 text-slate-900"
                  : "bg-slate-50 text-slate-900"
        }`}
    >
      {/* CORPORATE AGENCY STICKY HEADER */}
      <header
        className={`sticky top-0 z-40 shadow-xs ${isOnyx
          ? "bg-[#0F0F10]/95 backdrop-blur-md text-[#F5F1E8] border-b border-[#3A3A3E]"
          : isKolm
            ? "bg-[#212427]/95 backdrop-blur-md text-white border-b border-[#3C434A]"
            : isLumira
              ? "bg-white/95 backdrop-blur-md text-[#164A6E] border-b border-[#C5D6E2]"
              : isAldervik
                ? "bg-[#F3EFEA]/95 backdrop-blur-md text-[#1C293D] border-b border-[#DAD3CA]"
                : isSage
                  ? "bg-[#F6F4EE]/95 backdrop-blur-md text-[#24473A] border-b border-[#DDD6C8]"
                  : isMinimal
                    ? "bg-white/95 backdrop-blur-md text-slate-900 border-b border-stone-200"
                    : `bg-gradient-to-r ${palTokens.headerGradient} text-white border-b border-slate-800`
          }`}
      >
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-3 sm:py-4">
          <div className="flex items-center justify-between gap-3 sm:gap-4">
            <div className="flex items-center gap-2.5 sm:gap-3.5 min-w-0">
              {agency.logoUrl ? (
                <img
                  src={agency.logoUrl}
                  alt={agency.name}
                  className="w-10 h-10 sm:w-12 sm:h-12 rounded-xl object-contain bg-white p-1.5 shadow-xs border border-slate-200 shrink-0"
                />
              ) : (
                <div
                  className={`w-10 h-10 sm:w-12 sm:h-12 rounded-xl flex items-center justify-center shrink-0 ${isLightHeader
                    ? "bg-stone-100 border border-stone-200 text-stone-800"
                    : isOnyx
                      ? "bg-[#2A2A2D] border border-[#3A3A3E] text-[#D4B26A]"
                      : "bg-white/10 border border-white/20 text-white"
                    }`}
                >
                  <Building2 className="w-5 h-5 sm:w-6 sm:h-6" />
                </div>
              )}

              <div className="min-w-0">
                <div className="flex items-center gap-1.5 sm:gap-2">
                  <h1
                    className={`text-base sm:text-xl font-bold tracking-tight truncate ${isOnyx
                      ? "font-serif tracking-[3px] uppercase !text-[#F5F1E8]"
                      : isAldervik
                        ? "font-serif !text-[#1C293D]"
                        : isLightHeader
                          ? "!text-slate-900"
                          : "!text-white"
                      }`}
                  >
                    {agency.name}
                  </h1>
                  <span
                    className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] sm:text-[11px] font-semibold shrink-0 ${isLightHeader
                      ? "bg-black/5 border border-black/10 text-slate-700"
                      : isOnyx
                        ? "bg-[#D4B26A]/20 border border-[#D4B26A]/30 text-[#D4B26A]"
                        : "bg-emerald-500/20 border border-emerald-400/30 text-emerald-300"
                      }`}
                  >
                    <ShieldCheck className="w-3 h-3" />
                    <span className="hidden sm:inline">{ui.verifiedBadge}</span>
                  </span>
                </div>
                {(agency.city || agency.address) && (
                  <p
                    className={`text-xs flex items-center gap-1 mt-0.5 truncate ${isLightHeader ? "text-slate-500" : isOnyx ? "text-[#A8A39A]" : "text-slate-300"
                      }`}
                  >
                    <MapPin className="w-3 h-3 shrink-0" />
                    <span className="truncate">{[agency.address, agency.city].filter(Boolean).join(", ")}</span>
                  </p>
                )}
              </div>
            </div>

            {/* Desktop Actions */}
            <div className="hidden md:flex items-center gap-2.5 shrink-0">
              <a
                href="#owner-lead-section"
                className={`inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl text-xs sm:text-sm font-semibold transition-colors ${isLightHeader
                  ? "bg-black/5 hover:bg-black/10 text-slate-800"
                  : isOnyx
                    ? "bg-[#2A2A2D] hover:bg-[#3A3A3E] text-[#D4B26A] border border-[#3A3A3E]"
                    : "bg-white/10 hover:bg-white/20 text-white"
                  }`}
              >
                <Home className="w-4 h-4" aria-hidden="true" />
                <span>{ui.listPropertyBtn}</span>
              </a>

              {agency.phone && (
                <a
                  href={`tel:${cleanPhoneDigits}`}
                  style={{
                    backgroundColor: isOnyx
                      ? "#D4B26A"
                      : isKolm
                        ? "#5EF0B8"
                        : isLumira
                          ? "#FF6B5A"
                          : isAldervik
                            ? "#FFB020"
                            : isSage
                              ? "#D9663B"
                              : palTokens.primary,
                    color: isOnyx || isKolm || isAldervik ? "#111815" : "#ffffff",
                  }}
                  className="inline-flex items-center gap-2 px-4 py-2 rounded-xl text-xs sm:text-sm font-semibold transition-opacity hover:opacity-90 shadow-xs"
                >
                  <Phone className="w-4 h-4" />
                  <span>{agency.phone}</span>
                </a>
              )}

              {/* Currency Switcher in Desktop Header */}
              {showcaseCurrencies.length > 1 && (
                <div
                  className={`flex items-center gap-1 rounded-xl px-2 py-1.5 text-xs font-semibold ${isLightHeader
                    ? "bg-black/5 border border-black/10 text-slate-700"
                    : isOnyx
                      ? "bg-[#2A2A2D] border border-[#3A3A3E] text-[#F5F1E8]"
                      : isKolm
                        ? "bg-[#2A2E32] border border-[#3C434A] text-white"
                        : "bg-white/10 text-white"
                    }`}
                >
                  {showcaseCurrencies.map((c) => (
                    <button
                      key={c}
                      type="button"
                      onClick={() => setDisplayCurrency(c)}
                      className={`px-1.5 py-0.5 rounded cursor-pointer transition-colors uppercase ${displayCurrency === c
                        ? isLightHeader
                          ? "bg-slate-900 text-white font-bold"
                          : isOnyx
                            ? "bg-[#D4B26A] text-[#1A1405] font-bold"
                            : isKolm
                              ? "bg-[#5EF0B8] text-[#111815] font-bold"
                              : "bg-white text-slate-900 font-bold"
                        : isLightHeader
                          ? "text-slate-600 hover:text-slate-900"
                          : isOnyx
                            ? "text-[#A8A39A] hover:text-[#F5F1E8]"
                            : isKolm
                              ? "text-[#8B95A5] hover:text-white"
                              : "opacity-75 hover:opacity-100"
                        }`}
                    >
                      {c}
                    </button>
                  ))}
                </div>
              )}

              {/* Language Switcher in Desktop Header */}
              {showcaseLanguages.length > 1 && (
                <div
                  className={`flex items-center gap-1 rounded-xl px-2 py-1.5 text-xs ${isLightHeader
                    ? "bg-black/5 border border-black/10 text-slate-700"
                    : isOnyx
                      ? "bg-[#2A2A2D] border border-[#3A3A3E] text-[#F5F1E8]"
                      : isKolm
                        ? "bg-[#2A2E32] border border-[#3C434A] text-white"
                        : "bg-white/10 text-white"
                    }`}
                >
                  {showcaseLanguages.map((l) => (
                    <button
                      key={l}
                      type="button"
                      onClick={() => setLang(l)}
                      className={`px-1.5 py-0.5 rounded cursor-pointer transition-colors ${lang === l
                        ? isLightHeader
                          ? "bg-slate-900 text-white font-bold"
                          : isOnyx
                            ? "bg-[#D4B26A] text-[#1A1405] font-bold"
                            : isKolm
                              ? "bg-[#5EF0B8] text-[#111815] font-bold"
                              : "bg-white text-slate-900 font-bold"
                        : isLightHeader
                          ? "text-slate-600 hover:text-slate-900"
                          : isOnyx
                            ? "text-[#A8A39A] hover:text-[#F5F1E8]"
                            : isKolm
                              ? "text-[#8B95A5] hover:text-white"
                              : "opacity-75 hover:opacity-100"
                        }`}
                    >
                      {SHOWCASE_LANG_META[l]?.short || l}
                    </button>
                  ))}
                </div>
              )}
            </div>

            {/* Mobile Actions: Call Icon Button + Hamburger Menu Toggle */}
            <div className="flex md:hidden items-center gap-2 shrink-0">
              {agency.phone && (
                <a
                  href={`tel:${cleanPhoneDigits}`}
                  style={{
                    backgroundColor: isOnyx
                      ? "#D4B26A"
                      : isKolm
                        ? "#5EF0B8"
                        : palTokens.primary,
                    color: isOnyx || isKolm ? "#111815" : "#ffffff",
                  }}
                  className="w-9 h-9 rounded-xl flex items-center justify-center shadow-xs active:scale-95 transition-transform"
                  aria-label={agency.phone}
                >
                  <Phone className="w-4 h-4" />
                </a>
              )}

              <button
                type="button"
                onClick={() => setMobileMenuOpen((prev) => !prev)}
                className={`w-9 h-9 rounded-xl flex items-center justify-center border transition-colors cursor-pointer ${isLightHeader
                  ? "border-stone-200 bg-stone-100 text-stone-800 hover:bg-stone-200"
                  : isOnyx
                    ? "border-[#3A3A3E] bg-[#2A2A2D] text-[#D4B26A] hover:bg-[#3A3A3E]"
                    : "border-white/20 bg-white/10 text-white hover:bg-white/20"
                  }`}
                aria-label="Toggle Menu"
              >
                {mobileMenuOpen ? (
                  <X className="w-5 h-5" />
                ) : (
                  <Menu className="w-5 h-5" />
                )}
              </button>
            </div>
          </div>
        </div>

        {/* Mobile Dropdown Menu Drawer */}
        {mobileMenuOpen && (
          <div
            className={`md:hidden border-t px-4 py-4 space-y-4 animate-in slide-in-from-top-2 duration-150 ${isLightHeader
              ? "bg-white border-stone-200 text-slate-900 shadow-xl"
              : isOnyx
                ? "bg-[#0F0F10]/98 backdrop-blur-md border-[#3A3A3E] text-[#F5F1E8] shadow-2xl"
                : isKolm
                  ? "bg-[#212427]/98 backdrop-blur-md border-[#3C434A] text-white shadow-2xl"
                  : "bg-slate-900/98 backdrop-blur-md border-slate-800 text-white shadow-2xl"
              }`}
          >
            {/* Quick Agency Details */}
            <div className={`flex items-center justify-between pb-3 border-b ${isLightHeader ? "border-slate-200" : isOnyx ? "border-[#3A3A3E]" : "border-white/10"}`}>
              <div className="min-w-0">
                <p
                  className={`text-xs font-bold leading-tight truncate ${isOnyx
                    ? "!text-[#F5F1E8] font-serif uppercase tracking-wider"
                    : isLightHeader
                      ? "!text-slate-900"
                      : "!text-white"
                    }`}
                >
                  {agency.name}
                </p>
                <p className={`text-[11px] mt-0.5 truncate ${isLightHeader ? "text-slate-500" : isOnyx ? "text-[#A8A39A]" : "text-slate-400"}`}>
                  {[agency.address, agency.city].filter(Boolean).join(", ") || "Srbija"}
                </p>
              </div>
              <span
                className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-semibold shrink-0 ${isLightHeader
                  ? "bg-black/5 text-slate-700"
                  : isOnyx
                    ? "bg-[#D4B26A]/20 text-[#D4B26A]"
                    : "bg-emerald-500/20 text-emerald-300"
                  }`}
              >
                <ShieldCheck className="w-3 h-3" />
                <span>{ui.verifiedBadge}</span>
              </span>
            </div>

            {/* List Property CTA Button */}
            <a
              href="#owner-lead-section"
              onClick={() => setMobileMenuOpen(false)}
              style={{
                backgroundColor: isOnyx ? "#D4B26A" : undefined,
                color: isOnyx ? "#1A1405" : undefined,
              }}
              className={`w-full flex items-center justify-center gap-2 py-2.5 px-4 rounded-xl text-xs font-bold transition-colors shadow-xs ${isOnyx
                ? "hover:bg-[#E6CB93]"
                : isLightHeader
                  ? "bg-slate-900 text-white hover:bg-slate-800"
                  : "bg-white text-slate-900 hover:bg-white/90"
                }`}
            >
              <Home className="w-4 h-4" />
              <span>{ui.listPropertyBtn}</span>
            </a>

            {/* Direct Phone / Contact Actions */}
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
              {agency.phone && (
                <a
                  href={`tel:${cleanPhoneDigits}`}
                  style={{
                    backgroundColor: isOnyx
                      ? "#D4B26A"
                      : isKolm
                        ? "#5EF0B8"
                        : isLumira
                          ? "#FF6B5A"
                          : isAldervik
                            ? "#FFB020"
                            : isSage
                              ? "#D9663B"
                              : palTokens.primary,
                    color: isOnyx || isKolm || isAldervik ? "#111815" : "#ffffff",
                  }}
                  className="w-full flex items-center justify-center gap-2 py-2.5 px-3 rounded-xl text-xs font-bold shadow-xs"
                >
                  <Phone className="w-3.5 h-3.5" />
                  <span>{agency.phone}</span>
                </a>
              )}
              {agency.email && (
                <a
                  href={`mailto:${agency.email}`}
                  className={`w-full flex items-center justify-center gap-2 py-2.5 px-3 rounded-xl text-xs font-semibold border ${isLightHeader
                    ? "bg-slate-50 border-slate-200 text-slate-800 hover:bg-slate-100"
                    : isOnyx
                      ? "bg-[#212124] border-[#3A3A3E] text-[#F5F1E8] hover:bg-[#2A2A2D]"
                      : "bg-white/10 border-white/15 text-white hover:bg-white/20"
                    }`}
                >
                  <Mail className="w-3.5 h-3.5" />
                  <span className="truncate">{agency.email}</span>
                </a>
              )}
            </div>

            {/* Currency Selector in Mobile Drawer */}
            {showcaseCurrencies.length > 1 && (
              <div className={`pt-2 border-t ${isLightHeader ? "border-slate-200" : isOnyx ? "border-[#3A3A3E]" : "border-white/10"}`}>
                <p className={`text-[10px] font-bold uppercase tracking-wider mb-2 ${isLightHeader ? "text-slate-500" : isOnyx ? "text-[#A8A39A]" : "text-slate-400"}`}>
                  Valuta / Currency
                </p>
                <div
                  className="grid gap-1.5"
                  style={{
                    gridTemplateColumns: `repeat(${showcaseCurrencies.length}, minmax(0, 1fr))`,
                  }}
                >
                  {showcaseCurrencies.map((c) => (
                    <button
                      key={c}
                      type="button"
                      onClick={() => {
                        setDisplayCurrency(c);
                        setMobileMenuOpen(false);
                      }}
                      className={`py-2 rounded-lg text-xs font-bold transition-colors cursor-pointer text-center uppercase ${displayCurrency === c
                        ? isLightHeader
                          ? "bg-slate-900 text-white"
                          : isOnyx
                            ? "bg-[#D4B26A] text-[#1A1405]"
                            : isKolm
                              ? "bg-[#5EF0B8] text-[#111815]"
                              : "bg-white text-slate-900"
                        : isLightHeader
                          ? "bg-stone-100 text-stone-700 hover:bg-stone-200"
                          : isOnyx
                            ? "bg-[#2A2A2D] text-[#A8A39A] hover:text-[#F5F1E8]"
                            : isKolm
                              ? "bg-[#2A2E32] text-[#8B95A5] hover:text-white"
                              : "bg-white/10 text-white hover:bg-white/20"
                        }`}
                    >
                      {c}
                    </button>
                  ))}
                </div>
              </div>
            )}

            {/* Language Selector in Mobile Drawer */}
            {showcaseLanguages.length > 1 && (
              <div className={`pt-2 border-t ${isLightHeader ? "border-slate-200" : isOnyx ? "border-[#3A3A3E]" : "border-white/10"}`}>
                <p className={`text-[10px] font-bold uppercase tracking-wider mb-2 ${isLightHeader ? "text-slate-500" : isOnyx ? "text-[#A8A39A]" : "text-slate-400"}`}>
                  Jezik / Language
                </p>
                <div
                  className="grid gap-1.5"
                  style={{
                    gridTemplateColumns: `repeat(${Math.min(showcaseLanguages.length, 5)}, minmax(0, 1fr))`,
                  }}
                >
                  {showcaseLanguages.map((l) => {
                    const item = SHOWCASE_LANG_META[l] || { code: l, short: l, label: l };
                    return (
                      <button
                        key={item.code}
                        type="button"
                        onClick={() => {
                          setLang(item.code);
                          setMobileMenuOpen(false);
                        }}
                        className={`py-2 rounded-lg text-xs font-bold transition-colors cursor-pointer text-center ${lang === item.code
                          ? isLightHeader
                            ? "bg-slate-900 text-white"
                            : isOnyx
                              ? "bg-[#D4B26A] text-[#1A1405]"
                              : isKolm
                                ? "bg-[#5EF0B8] text-[#111815]"
                                : "bg-white text-slate-900"
                          : isLightHeader
                            ? "bg-stone-100 text-stone-700 hover:bg-stone-200"
                            : isOnyx
                              ? "bg-[#2A2A2D] text-[#A8A39A] hover:text-[#F5F1E8]"
                              : isKolm
                                ? "bg-[#2A2E32] text-[#8B95A5] hover:text-white"
                                : "bg-white/10 text-white hover:bg-white/20"
                          }`}
                      >
                        {item.short}
                      </button>
                    );
                  })}
                </div>
              </div>
            )}
          </div>
        )}
      </header>

      {/* TEMPLATE HERO BANNERS */}
      {isOnyx && (
        <section className="bg-[#0F0F10] text-[#F5F1E8] py-16 sm:py-20 px-4 sm:px-6 lg:px-8 border-b border-[#3A3A3E]">
          <div className="max-w-7xl mx-auto">
            <span className="text-xs uppercase tracking-[2px] text-[#D4B26A] font-semibold block mb-3 font-serif">
              {agency.name} • {agency.city || "Srbija"}
            </span>
            <h2 className="text-4xl sm:text-5xl lg:text-6xl font-serif font-normal max-w-3xl leading-[1.1] mb-4 !text-[#F5F1E8]">
              Retke adrese za retke ukuse
            </h2>
            <p className="text-base sm:text-lg text-[#A8A39A] max-w-xl mb-8 font-sans leading-relaxed">
              {agency.description || ui.luxurySubtitle}
            </p>
            <a
              href="#owner-lead-section"
              className="inline-flex items-center gap-2 px-6 py-3 rounded-[4px] bg-[#D4B26A] text-[#1A1405] font-semibold text-sm shadow-sm hover:bg-[#E6CB93] transition-colors"
            >
              <span>{ui.listPropertyBtn}</span>
              <ArrowRight className="w-4 h-4" />
            </a>
          </div>
        </section>
      )}

      {isAldervik && (
        <section className="bg-[#1C293D] text-white py-12 px-4 sm:px-6 lg:px-8 border-b border-[#111A27]">
          <div className="max-w-7xl mx-auto">
            <span className="text-xs uppercase tracking-widest text-[#FFB020] font-mono font-bold block mb-2">
              {agency.name} • {agency.city || "Nekretnine"}
            </span>
            <h2 className="text-3xl sm:text-4xl font-serif font-normal max-w-2xl leading-tight mb-3 !text-white">
              Nekretnine sa pažnjom prema detaljima
            </h2>
            <p className="text-sm sm:text-base text-slate-300 max-w-xl mb-6 font-sans">
              {[agency.address, agency.city].filter(Boolean).join(", ") || "Ekskluzivna ponuda nekretnina"}
            </p>
            <a
              href="#owner-lead-section"
              className="inline-flex items-center gap-2 px-5 py-2.5 rounded-lg bg-[#FFB020] text-[#1C293D] font-bold text-sm shadow-sm hover:opacity-95 transition-opacity font-sans"
            >
              <span>{ui.listPropertyBtn}</span>
              <ArrowRight className="w-4 h-4" />
            </a>
          </div>
        </section>
      )}

      {isSage && (
        <section className="bg-[#24473A] text-white pt-12 pb-14 px-4 sm:px-6 lg:px-8 text-center">
          <div className="max-w-3xl mx-auto">
            <span className="inline-block text-xs uppercase tracking-widest text-[#D9663B] font-bold mb-2">
              {agency.name}
            </span>
            <h2 className="text-3xl sm:text-4xl font-medium max-w-xl mx-auto leading-tight mb-3 !text-white">
              Kuća u kojoj se osećate kao kod kuće
            </h2>
            <p className="text-sm sm:text-base text-[#E6EDE8] max-w-md mx-auto">
              {[agency.address, agency.city].filter(Boolean).join(", ") || "Vaš pouzdan vodič kroz nekretnine"}
            </p>
          </div>
        </section>
      )}

      {isLumira && (
        <section className="max-w-7xl mx-auto w-full px-4 sm:px-6 lg:px-8 pt-8 pb-1">
          <div className="flex flex-col md:flex-row items-start md:items-center justify-between gap-4">
            <div>
              <span className="text-xs font-bold uppercase tracking-wider text-[#FF6B5A]">
                {agency.city || "Srbija"} • {ui.verifiedBadge}
              </span>
              <h2 className="text-2xl sm:text-3xl font-bold text-[#164A6E] mt-1">
                Dom koji vam odgovara, bez muke
              </h2>
              <p className="text-sm text-[#3F6078] mt-1">
                {[agency.address, agency.city].filter(Boolean).join(", ")}
              </p>
            </div>
          </div>
        </section>
      )}

      {isKolm && (
        <section className="max-w-7xl mx-auto w-full px-4 sm:px-6 lg:px-8 pt-8 pb-1">
          <div>
            <span className="text-xs font-bold uppercase tracking-widest text-[#5EF0B8]">
              {agency.city || "Srbija"}
            </span>
            <h2 className="text-2xl sm:text-3xl font-medium text-white mt-1">
              Pronađite svoj sledeći dom
            </h2>
            <p className="text-sm text-[#A0AAB5] mt-1">
              {[agency.address, agency.city].filter(Boolean).join(", ")}
            </p>
          </div>
        </section>
      )}

      {/* FILTER BAR */}
      <section className={`max-w-7xl mx-auto w-full px-4 sm:px-6 lg:px-8 ${isSage ? "-mt-8" : "pt-6"}`}>
        <div
          className={`${isOnyx
            ? "bg-[#2A2A2D] border border-[#3A3A3E] text-[#F5F1E8]"
            : isKolm
              ? "bg-[#2A2E32] border border-[#3C434A] text-white"
              : isLumira
                ? "bg-white border border-[#C5D6E2] text-[#164A6E]"
                : isAldervik
                  ? "bg-white border border-[#DAD3CA] text-[#1C293D]"
                  : isSage
                    ? "bg-white border border-[#DDD6C8] text-[#24473A]"
                    : isMinimal
                      ? "bg-white border border-stone-200 text-slate-900"
                      : "bg-white border border-slate-200 text-slate-900"
            } ${luxCardRadius} p-4 shadow-xs`}
        >
          {/* Top Row: Search + Tx + PropType + Sort + Advanced Toggle */}
          <div className="grid grid-cols-12 gap-2.5 sm:gap-3 items-center">
            <div className="col-span-12 sm:col-span-4 relative">
              <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
              <input
                type="search"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder={ui.searchPlaceholder}
                aria-label={ui.searchPlaceholder}
                className={`w-full pl-9 pr-3.5 py-2.5 ${luxRadius} border ${isOnyx
                  ? "bg-[#212124] text-[#F5F1E8] border-[#8A857C] placeholder:text-[#8A857C]"
                  : isKolm
                    ? "bg-[#212427] text-white border-[#8B95A5] placeholder:text-[#8B95A5]"
                    : isLumira
                      ? "bg-white text-[#164A6E] border-[#C5D6E2]"
                      : isAldervik
                        ? "bg-white text-[#1C293D] border-[#DAD3CA]"
                        : isSage
                          ? "bg-white text-[#24473A] border-[#DDD6C8]"
                          : isMinimal
                            ? "bg-white text-slate-900 border-stone-300"
                            : "bg-white text-slate-900 border-slate-300"
                  } text-sm focus:outline-none focus:ring-1 focus:ring-blue-500`}
              />
            </div>

            <div className="col-span-6 sm:col-span-2">
              <select
                value={filterTx}
                onChange={(e) => setFilterTx(e.target.value)}
                aria-label={ui.allTransactions}
                className={`w-full px-3 py-2.5 ${luxRadius} border ${isOnyx
                  ? "bg-[#212124] text-[#F5F1E8] border-[#8A857C]"
                  : isKolm
                    ? "bg-[#212427] text-white border-[#8B95A5]"
                    : isLumira
                      ? "bg-white text-[#164A6E] border-[#C5D6E2]"
                      : isAldervik
                        ? "bg-white text-[#1C293D] border-[#DAD3CA]"
                        : isSage
                          ? "bg-white text-[#24473A] border-[#DDD6C8]"
                          : isMinimal
                            ? "bg-white text-slate-900 border-stone-300"
                            : "bg-white text-slate-900 border-slate-300"
                  } text-xs sm:text-sm cursor-pointer`}
              >
                <option value="all">{ui.allTransactions}</option>
                {Object.values(TRANSACTION_TYPES).map((tItem) => (
                  <option key={tItem.key} value={tItem.key}>
                    {getDictLabel(tItem, lang)}
                  </option>
                ))}
              </select>
            </div>

            <div className="col-span-6 sm:col-span-2">
              <select
                value={filterType}
                onChange={(e) => setFilterType(e.target.value)}
                aria-label={ui.allTypes}
                className={`w-full px-3 py-2.5 ${luxRadius} border ${isOnyx
                  ? "bg-[#212124] text-[#F5F1E8] border-[#8A857C]"
                  : isKolm
                    ? "bg-[#212427] text-white border-[#8B95A5]"
                    : isLumira
                      ? "bg-white text-[#164A6E] border-[#C5D6E2]"
                      : isAldervik
                        ? "bg-white text-[#1C293D] border-[#DAD3CA]"
                        : isSage
                          ? "bg-white text-[#24473A] border-[#DDD6C8]"
                          : isMinimal
                            ? "bg-white text-slate-900 border-stone-300"
                            : "bg-white text-slate-900 border-slate-300"
                  } text-xs sm:text-sm cursor-pointer`}
              >
                <option value="all">{ui.allTypes}</option>
                {Object.values(PROPERTY_TYPES).map((pt) => (
                  <option key={pt.key} value={pt.key}>
                    {getDictLabel(pt, lang)}
                  </option>
                ))}
              </select>
            </div>

            <div className="col-span-6 sm:col-span-2">
              <select
                value={sortBy}
                onChange={(e) => setSortBy(e.target.value)}
                aria-label={ui.sortBy}
                className={`w-full px-3 py-2.5 ${luxRadius} border ${isOnyx
                  ? "bg-[#212124] text-[#F5F1E8] border-[#8A857C]"
                  : isKolm
                    ? "bg-[#212427] text-white border-[#8B95A5]"
                    : isLumira
                      ? "bg-white text-[#164A6E] border-[#C5D6E2]"
                      : isAldervik
                        ? "bg-white text-[#1C293D] border-[#DAD3CA]"
                        : isSage
                          ? "bg-white text-[#24473A] border-[#DDD6C8]"
                          : isMinimal
                            ? "bg-white text-slate-900 border-stone-300"
                            : "bg-white text-slate-900 border-slate-300"
                  } text-xs sm:text-sm cursor-pointer`}
              >
                {SORT_OPTIONS.map((opt) => (
                  <option key={opt.key} value={opt.key}>
                    {opt.label}
                  </option>
                ))}
              </select>
            </div>

            <div className="col-span-6 sm:col-span-2 flex items-center justify-end gap-1.5 sm:gap-2">
              <button
                type="button"
                onClick={() => setShowAdvancedFilters((prev) => !prev)}
                className={`flex-1 flex items-center justify-center gap-1 sm:gap-1.5 px-2.5 sm:px-3 py-2.5 ${luxRadius} border text-xs sm:text-sm font-semibold transition-colors cursor-pointer ${showAdvancedFilters || activeFiltersCount > 0
                  ? isOnyx
                    ? "bg-[#D4B26A] text-[#1A1405] border-[#D4B26A]"
                    : isKolm
                      ? "bg-[#5EF0B8] text-[#111815] border-[#5EF0B8]"
                      : isMinimal
                        ? "bg-stone-900 text-white border-stone-900"
                        : "bg-blue-600 text-white border-blue-600"
                  : isOnyx
                    ? "bg-[#212124] text-[#F5F1E8] border-[#8A857C] hover:bg-[#2A2A2D]"
                    : isKolm
                      ? "bg-[#212427] text-white border-[#3C434A] hover:bg-[#2A2E32]"
                      : isMinimal
                        ? "bg-stone-100 text-stone-700 border-stone-300 hover:bg-stone-200"
                        : "bg-slate-100 text-slate-700 border-slate-300 hover:bg-slate-200"
                  }`}
              >
                <SlidersHorizontal className="w-3.5 h-3.5 shrink-0" />
                <span className="truncate">
                  {showAdvancedFilters ? ui.hideFiltersBtn : ui.advancedFiltersBtn}
                </span>
                {activeFiltersCount > 0 && (
                  <span
                    className={`ml-0.5 sm:ml-1 px-1.5 py-0.5 rounded-full text-[10px] sm:text-xs font-bold ${showAdvancedFilters || activeFiltersCount > 0
                      ? "bg-white text-slate-900"
                      : "bg-blue-600 text-white"
                      }`}
                  >
                    {activeFiltersCount}
                  </span>
                )}
              </button>

              <span
                className={`text-xs font-bold border px-2.5 py-2.5 ${luxBadgeRadius} ${isOnyx ? "bg-[#212124] text-[#D4B26A] border-[#8A857C]" : isKolm ? "bg-[#212427] text-[#5EF0B8] border-[#3C434A]" : palTokens.badgeBg} shrink-0`}
                title={ui.activeListings}
              >
                {filteredListings.length}
              </span>
            </div>
          </div>

          {/* Advanced Filters Expandable Drawer */}
          {showAdvancedFilters && (
            <div
              className={`mt-4 pt-4 border-t ${isMinimal ? "border-stone-200" : "border-slate-200"
                } space-y-4`}
            >
              <div className="grid grid-cols-1 sm:grid-cols-12 gap-3 items-end">
                {/* Location / Opština */}
                <div className="sm:col-span-4">
                  <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 mb-1">
                    {ui.allLocations}
                  </label>
                  <select
                    value={filterLocation}
                    onChange={(e) => setFilterLocation(e.target.value)}
                    className={`w-full px-3 py-2 text-sm bg-white border ${isMinimal ? "border-stone-300" : "border-slate-300"
                      } ${luxRadius}`}
                  >
                    <option value="all">{ui.allLocations}</option>
                    {availableLocations.map((loc) => (
                      <option key={loc} value={loc}>
                        {loc}
                      </option>
                    ))}
                  </select>
                </div>

                {/* Price Range */}
                <div className="sm:col-span-4">
                  <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 mb-1">
                    {ui.priceRange} (€)
                  </label>
                  <div className="grid grid-cols-2 gap-2">
                    <input
                      type="number"
                      value={filterMinPrice}
                      onChange={(e) => setFilterMinPrice(e.target.value)}
                      placeholder={ui.minPrice}
                      className={`w-full px-3 py-2 text-sm bg-white border ${isMinimal ? "border-stone-300" : "border-slate-300"
                        } ${luxRadius}`}
                    />
                    <input
                      type="number"
                      value={filterMaxPrice}
                      onChange={(e) => setFilterMaxPrice(e.target.value)}
                      placeholder={ui.maxPrice}
                      className={`w-full px-3 py-2 text-sm bg-white border ${isMinimal ? "border-stone-300" : "border-slate-300"
                        } ${luxRadius}`}
                    />
                  </div>
                </div>

                {/* Area Range */}
                <div className="sm:col-span-4">
                  <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 mb-1">
                    {ui.areaRange} (m²)
                  </label>
                  <div className="grid grid-cols-2 gap-2">
                    <input
                      type="number"
                      value={filterMinArea}
                      onChange={(e) => setFilterMinArea(e.target.value)}
                      placeholder={ui.minArea}
                      className={`w-full px-3 py-2 text-sm bg-white border ${isMinimal ? "border-stone-300" : "border-slate-300"
                        } ${luxRadius}`}
                    />
                    <input
                      type="number"
                      value={filterMaxArea}
                      onChange={(e) => setFilterMaxArea(e.target.value)}
                      placeholder={ui.maxArea}
                      className={`w-full px-3 py-2 text-sm bg-white border ${isMinimal ? "border-stone-300" : "border-slate-300"
                        } ${luxRadius}`}
                    />
                  </div>
                </div>
              </div>

              {/* Room Structure Pills */}
              <div>
                <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 mb-1.5">
                  {ui.roomStructure}
                </label>
                <div className="flex flex-wrap gap-1.5">
                  {["all", "1.0", "1.5", "2.0", "2.5", "3.0", "3.5", "4.0+"].map((r) => (
                    <button
                      key={r}
                      type="button"
                      onClick={() => setFilterRooms(r)}
                      className={`px-3 py-1.5 text-xs font-semibold ${luxRadius} border transition-colors cursor-pointer ${filterRooms === r
                        ? isMinimal
                          ? "bg-stone-900 text-white border-stone-900"
                          : "bg-blue-600 text-white border-blue-600"
                        : isMinimal
                          ? "bg-white text-stone-700 border-stone-300 hover:bg-stone-100"
                          : "bg-white text-slate-700 border-slate-300 hover:bg-slate-100"
                        }`}
                    >
                      {r === "all" ? ui.allRooms : r}
                    </button>
                  ))}
                </div>
              </div>

              {/* Key Amenities */}
              <div>
                <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 mb-1.5">
                  {ui.featuresLabel}
                </label>
                <div className="flex flex-wrap gap-2">
                  {AMENITY_OPTIONS.map((am) => {
                    const isChecked = filterAmenities.includes(am.key);
                    return (
                      <button
                        key={am.key}
                        type="button"
                        onClick={() => toggleAmenity(am.key)}
                        className={`flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium ${luxRadius} border transition-colors cursor-pointer ${isChecked
                          ? isMinimal
                            ? "bg-stone-900 text-white border-stone-900"
                            : "bg-blue-50 text-blue-700 border-blue-400 font-semibold"
                          : isMinimal
                            ? "bg-white text-stone-700 border-stone-300 hover:bg-stone-100"
                            : "bg-white text-slate-700 border-slate-300 hover:bg-slate-100"
                          }`}
                      >
                        <div
                          className={`w-3.5 h-3.5 rounded flex items-center justify-center border ${isChecked
                            ? isMinimal
                              ? "bg-white text-stone-900 border-white"
                              : "bg-blue-600 text-white border-blue-600"
                            : "border-slate-400"
                            }`}
                        >
                          {isChecked && <Check className="w-3 h-3 stroke-[3]" />}
                        </div>
                        <span>{am.label}</span>
                      </button>
                    );
                  })}
                </div>
              </div>

              {/* Reset button bar if filters active */}
              {activeFiltersCount > 0 && (
                <div className="flex items-center justify-between pt-2">
                  <span className="text-xs text-slate-500">
                    {filteredListings.length} {ui.activeListings}
                  </span>
                  <button
                    type="button"
                    onClick={resetAllFilters}
                    className="flex items-center gap-1.5 text-xs font-semibold text-rose-600 hover:text-rose-800 transition-colors cursor-pointer"
                  >
                    <RotateCcw className="w-3.5 h-3.5" />
                    <span>{ui.resetFilters}</span>
                  </button>
                </div>
              )}
            </div>
          )}
        </div>
      </section>

      {/* PORTFOLIO GRID */}
      <main className="max-w-7xl mx-auto w-full px-4 sm:px-6 lg:px-8 py-8 flex-1">
        {loading ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {[1, 2, 3].map((n) => (
              <div
                key={n}
                className={`h-80 ${luxCardRadius} bg-white border border-slate-200 animate-pulse p-4`}
              />
            ))}
          </div>
        ) : filteredListings.length === 0 ? (
          <div className={`bg-white ${luxCardRadius} border border-slate-200 p-12 text-center`}>
            <Building2 className="w-12 h-12 text-slate-300 mx-auto mb-3" />
            <h2 className="text-lg font-bold text-slate-800">{ui.noListingsTitle}</h2>
            <p className="text-sm text-slate-500 mt-1">{ui.noListingsDesc}</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {filteredListings.map((item) => {
              const imgs = item.listing_images || [];
              const cover = imgs.find((i) => i.is_cover)?.url || imgs[0]?.url;
              const txObj =
                item.transaction_type === "prodaja"
                  ? TRANSACTION_TYPES.prodaja
                  : TRANSACTION_TYPES.izdavanje;
              const typeObj =
                PROPERTY_TYPES[item.property_type] || PROPERTY_TYPES.apartment;

              return (
                <article
                  key={item.id}
                  id={`listing-${item.id}`}
                  onClick={() => {
                    setSelectedListing(item);
                    setActivePhotoIdx(0);
                  }}
                  className={`group overflow-hidden transition-all cursor-pointer flex flex-col ${luxCardRadius} ${isOnyx
                    ? "bg-[#2A2A2D] border border-[#3A3A3E] hover:border-[#D4B26A] text-[#F5F1E8] shadow-xs"
                    : isKolm
                      ? "bg-[#2A2E32] border border-[#3C434A] hover:border-[#5EF0B8] text-white shadow-xs"
                      : isLumira
                        ? "bg-white border border-[#C5D6E2] hover:border-[#FF6B5A] text-[#164A6E] shadow-xs"
                        : isAldervik
                          ? "bg-white border border-[#DAD3CA] hover:border-[#FFB020] text-[#1C293D] shadow-xs"
                          : isSage
                            ? "bg-white border border-[#DDD6C8] hover:border-[#D9663B] text-[#24473A] shadow-xs"
                            : isMinimal
                              ? "bg-white border border-stone-200 hover:border-stone-900 text-slate-900"
                              : "bg-white border border-slate-200 shadow-xs hover:shadow-md hover:border-slate-300 text-slate-900"
                    }`}
                >
                  <div className={`relative h-56 bg-slate-100 overflow-hidden ${isOnyx ? "border-b border-[#D4B26A]" : ""}`}>
                    {cover ? (
                      <img
                        src={cover}
                        alt={item.title}
                        className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                      />
                    ) : (
                      <div className="w-full h-full flex items-center justify-center text-slate-300">
                        <Building2 className="w-12 h-12" />
                      </div>
                    )}

                    <div className="absolute top-3 left-3 flex items-center gap-1.5">
                      <span
                        style={{
                          backgroundColor:
                            item.transaction_type === "prodaja"
                              ? isOnyx
                                ? "#D4B26A"
                                : "#d97706"
                              : isOnyx
                                ? "#D4B26A"
                                : isKolm
                                  ? "#5EF0B8"
                                  : isLumira
                                    ? "#FF6B5A"
                                    : isAldervik
                                      ? "#FFB020"
                                      : isSage
                                        ? "#D9663B"
                                        : palTokens.primary,
                          color: isOnyx || isKolm || isAldervik ? "#111815" : "#ffffff",
                        }}
                        className={`text-xs font-bold px-2.5 py-1 ${luxBadgeRadius} shadow-xs`}
                      >
                        {getDictLabel(txObj, lang)}
                      </span>
                      <span className={`text-xs font-semibold px-2.5 py-1 ${luxBadgeRadius} bg-slate-900/75 text-white backdrop-blur-xs`}>
                        {getDictLabel(typeObj, lang)}
                      </span>
                    </div>

                    {item.external_ref && (
                      <span className={`absolute bottom-2.5 right-2.5 text-[11px] font-mono bg-slate-900/75 text-white px-2 py-0.5 ${luxBadgeRadius}`}>
                        #{item.external_ref}
                      </span>
                    )}
                  </div>

                  <div className="p-5 flex-1 flex flex-col justify-between">
                    <div>
                      <div
                        className={`flex items-center gap-1 text-xs mb-1.5 ${isOnyx
                          ? "text-[#A8A39A]"
                          : isKolm
                            ? "text-[#A0AAB5]"
                            : isLumira
                              ? "text-[#3F6078]"
                              : isAldervik
                                ? "text-[#535B67]"
                                : isSage
                                  ? "text-[#4E6358]"
                                  : "text-slate-500"
                          }`}
                      >
                        <MapPin
                          className="w-3.5 h-3.5 shrink-0"
                          style={{
                            color: isOnyx
                              ? "#D4B26A"
                              : isKolm
                                ? "#5EF0B8"
                                : isLumira
                                  ? "#FF6B5A"
                                  : isAldervik
                                    ? "#FFB020"
                                    : isSage
                                      ? "#D9663B"
                                      : palTokens.primary,
                          }}
                        />
                        <span className="truncate">
                          {[item.city, item.municipality, item.neighborhood]
                            .filter(Boolean)
                            .join(" • ")}
                        </span>
                      </div>

                      <h2
                        className={`text-base font-bold line-clamp-2 ${isOnyx
                          ? "!text-[#F5F1E8]"
                          : isKolm
                            ? "!text-white"
                            : isLumira
                              ? "text-[#164A6E]"
                              : isAldervik
                                ? "text-[#1C293D] font-serif"
                                : isSage
                                  ? "text-[#24473A]"
                                  : "text-slate-900"
                          }`}
                      >
                        {item.title}
                      </h2>
                    </div>

                    <div className={`mt-4 pt-3.5 border-t ${isOnyx ? "border-[#3A3A3E]" : isKolm ? "border-[#3C434A]" : isLumira ? "border-[#C5D6E2]" : isAldervik ? "border-[#DAD3CA]" : isSage ? "border-[#DDD6C8]" : "border-slate-100"}`}>
                      <div className="flex flex-wrap items-center justify-between gap-2">
                        <span
                          className={`text-base sm:text-lg font-extrabold flex items-center gap-1 ${isOnyx ? "font-serif text-xl sm:text-2xl" : isAldervik ? "font-serif" : ""
                            }`}
                          style={{
                            color: isOnyx
                              ? "#D4B26A"
                              : isKolm
                                ? "#5EF0B8"
                                : isLumira
                                  ? "#164A6E"
                                  : isAldervik
                                    ? "#1C293D"
                                    : isSage
                                      ? "#24473A"
                                      : palTokens.primary,
                          }}
                        >
                          {formatDisplayPrice(item)}
                        </span>

                        <div className={`flex items-center gap-2.5 sm:gap-3 text-xs font-semibold ${isOnyx ? "text-[#A8A39A]" : isKolm ? "text-[#A0AAB5]" : "text-slate-600"} shrink-0`}>
                          {item.area_sqm && (
                            <span className="flex items-center gap-1">
                              <Maximize2 className="w-3.5 h-3.5 text-slate-400" />
                              {item.area_sqm} m²
                            </span>
                          )}
                          {item.room_count && (
                            <span className="flex items-center gap-1">
                              <Layers className="w-3.5 h-3.5 text-slate-400" />
                              {item.room_count}
                            </span>
                          )}
                        </div>
                      </div>

                      <div className={`mt-3 pt-2.5 border-t flex items-center justify-between ${isOnyx ? "border-[#3A3A3E]" : isKolm ? "border-[#3C434A]" : isLumira ? "border-[#C5D6E2]" : isAldervik ? "border-[#DAD3CA]" : isSage ? "border-[#DDD6C8]" : "border-slate-100"}`}>
                        <span className={`text-xs font-semibold flex items-center gap-1 ${isOnyx ? "text-[#D4B26A]" : isKolm ? "text-[#A0AAB5]" : isLumira ? "text-[#3F6078]" : isAldervik ? "text-[#535B67]" : isSage ? "text-[#4E6358]" : "text-slate-500"}`}>
                          <span>{ui.viewDetails}</span>
                          <ArrowRight className="w-3.5 h-3.5 group-hover:translate-x-0.5 transition-transform" />
                        </span>
                        <button
                          type="button"
                          onClick={(e) => {
                            e.stopPropagation();
                            setSelectedListing(item);
                            setActivePhotoIdx(0);
                            setIsViewingFormOpen(true);
                          }}
                          style={{
                            color: isOnyx
                              ? "#D4B26A"
                              : isKolm
                                ? "#5EF0B8"
                                : isLumira
                                  ? "#FF6B5A"
                                  : isAldervik
                                    ? "#FFB020"
                                    : isSage
                                      ? "#D9663B"
                                      : palTokens.primary,
                          }}
                          className={`inline-flex items-center gap-1 text-xs font-bold hover:underline cursor-pointer py-1 px-2 rounded-lg transition-colors ${isOnyx ? "hover:bg-white/5" : isKolm ? "hover:bg-white/5" : "hover:bg-slate-50"}`}
                        >
                          <Calendar className="w-3.5 h-3.5" />
                          <span>{ui.viewingBtn}</span>
                        </button>
                      </div>
                    </div>
                  </div>
                </article>
              );
            })}
          </div>
        )}
      </main>

      {/* PROPERTY OWNER CONSIGNMENT FORM */}
      {ownerConsignmentSectionNode}

      {detailModalNode}
      {floatingContactNode}
      {standardFooterNode}
    </div>
  );
}
