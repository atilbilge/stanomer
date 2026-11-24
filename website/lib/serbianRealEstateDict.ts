// website/lib/serbianRealEstateDict.ts
//
// Central dictionary and multi-portal XML value mapper for the Serbian real estate market
// (4zida.rs, Halo Oglasi, Sasomange, Nekretnine.rs).
// Bridges Stanomer's internal PostgreSQL/Flutter enums with Serbian portal XML schemas.

export type PortalKey = "4zida" | "halooglasi" | "sasomange" | "nekretnine";

export interface PortalMappedValue {
  /** Internal canonical key in Stanomer DB */
  key: string;
  /** Human-readable Serbian Latin label */
  labelSrLat: string;
  /** Human-readable Serbian Cyrillic label */
  labelSrCyr: string;
  /** Human-readable Turkish label */
  labelTr: string;
  /** Human-readable English label */
  labelEn: string;
  /** Human-readable Russian label */
  labelRu?: string;
  /** Portal-specific XML codes/values */
  portals: {
    "4zida": string;
    halooglasi: string;
    sasomange: string;
    nekretnine: string;
  };
}

export function getDictLabel(
  item: PortalMappedValue,
  lang: "TR" | "EN" | "SR_LAT" | "SR_CYR" | "RU"
): string {
  switch (lang) {
    case "TR":
      return item.labelTr;
    case "EN":
      return item.labelEn;
    case "SR_CYR":
      return item.labelSrCyr;
    case "RU":
      return item.labelRu || item.labelEn;
    case "SR_LAT":
    default:
      return item.labelSrLat;
  }
}

// ---------------------------------------------------------------------------
// 1. TRANSACTION TYPES (Tip transakcije: Prodaja / Izdavanje)
// ---------------------------------------------------------------------------
export const TRANSACTION_TYPES: Record<string, PortalMappedValue> = {
  izdavanje: {
    key: "izdavanje",
    labelSrLat: "Izdavanje",
    labelSrCyr: "Издавање",
    labelTr: "Kiralık",
    labelEn: "For Rent",
    labelRu: "Аренда",
    portals: {
      "4zida": "2",
      halooglasi: "Izdavanje",
      sasomange: "RENT",
      nekretnine: "Izdavanje",
    },
  },
  prodaja: {
    key: "prodaja",
    labelSrLat: "Prodaja",
    labelSrCyr: "Продаја",
    labelTr: "Satılık",
    labelEn: "For Sale",
    labelRu: "Продажа",
    portals: {
      "4zida": "1",
      halooglasi: "Prodaja",
      sasomange: "SALE",
      nekretnine: "Prodaja",
    },
  },
};

// ---------------------------------------------------------------------------
// 2. PROPERTY TYPES (Vrsta nekretnine)
// Supports both existing Flutter DB keys ('apartment', 'house'...) & Serbian keys ('stan', 'kuca'...)
// ---------------------------------------------------------------------------
export const PROPERTY_TYPES: Record<string, PortalMappedValue> = {
  apartment: {
    key: "apartment",
    labelSrLat: "Stan",
    labelSrCyr: "Стан",
    labelTr: "Daire",
    labelEn: "Apartment",
    labelRu: "Квартира",
    portals: {
      "4zida": "apartment",
      halooglasi: "Stan",
      sasomange: "APARTMENT",
      nekretnine: "Stanovi",
    },
  },
  house: {
    key: "house",
    labelSrLat: "Kuća",
    labelSrCyr: "Кућа",
    labelTr: "Müstakil Ev",
    labelEn: "House",
    labelRu: "Дом",
    portals: {
      "4zida": "house",
      halooglasi: "Kuća",
      sasomange: "HOUSE",
      nekretnine: "Kuće",
    },
  },
  commercial: {
    key: "commercial",
    labelSrLat: "Poslovni prostor",
    labelSrCyr: "Пословни простор",
    labelTr: "Ticari / İşyeri",
    labelEn: "Commercial Space",
    labelRu: "Коммерческое помещение",
    portals: {
      "4zida": "office",
      halooglasi: "Poslovni prostor",
      sasomange: "COMMERCIAL",
      nekretnine: "Poslovni prostori",
    },
  },
  land: {
    key: "land",
    labelSrLat: "Plac / Zemljište",
    labelSrCyr: "Плац / Земљиште",
    labelTr: "Arsa / Arazi",
    labelEn: "Land / Plot",
    labelRu: "Участок / Земля",
    portals: {
      "4zida": "lot",
      halooglasi: "Zemljište",
      sasomange: "LAND",
      nekretnine: "Zemljišta",
    },
  },
  garage: {
    key: "garage",
    labelSrLat: "Garaža / Parking",
    labelSrCyr: "Гаража / Паркинг",
    labelTr: "Garaj / Otopark",
    labelEn: "Garage / Parking",
    labelRu: "Гараж / Паркинг",
    portals: {
      "4zida": "garage",
      halooglasi: "Garaža",
      sasomange: "GARAGE",
      nekretnine: "Garaže",
    },
  },
};

// Aliases so Serbian raw values ('stan', 'kuca', 'poslovni_prostor', 'plac', 'garaza') resolve cleanly
const PROPERTY_TYPE_ALIASES: Record<string, string> = {
  stan: "apartment",
  kuca: "house",
  kuća: "house",
  poslovni_prostor: "commercial",
  lokal: "commercial",
  plac: "land",
  zemljiste: "land",
  garaza: "garage",
  garaža: "garage",
};

// ---------------------------------------------------------------------------
// 3. ROOM STRUCTURES (Struktura / Broj soba)
// ---------------------------------------------------------------------------
export const ROOM_STRUCTURES: Record<string, PortalMappedValue> = {
  studio: {
    key: "studio",
    labelSrLat: "Garsonjera (0.5)",
    labelSrCyr: "Гарсоњера (0.5)",
    labelTr: "Stüdyo (0.5)",
    labelEn: "Studio (0.5)",
    labelRu: "Студия (0.5)",
    portals: {
      "4zida": "0.5",
      halooglasi: "Garsonjera",
      sasomange: "0.5",
      nekretnine: "Garsonjera",
    },
  },
  "1.0": {
    key: "1.0",
    labelSrLat: "Jednosoban (1.0)",
    labelSrCyr: "Једнособан (1.0)",
    labelTr: "1 Oda (1.0)",
    labelEn: "1 Room (1.0)",
    labelRu: "1 комната (1.0)",
    portals: {
      "4zida": "1.0",
      halooglasi: "Jednosoban",
      sasomange: "1.0",
      nekretnine: "Jednosoban",
    },
  },
  "1.5": {
    key: "1.5",
    labelSrLat: "Jednoiposoban (1.5)",
    labelSrCyr: "Једноипособан (1.5)",
    labelTr: "1.5 Oda (1.5)",
    labelEn: "1.5 Rooms (1.5)",
    labelRu: "1.5 комнаты (1.5)",
    portals: {
      "4zida": "1.5",
      halooglasi: "Jednoiposoban",
      sasomange: "1.5",
      nekretnine: "Jednoiposoban",
    },
  },
  "2.0": {
    key: "2.0",
    labelSrLat: "Dvosoban (2.0)",
    labelSrCyr: "Двособан (2.0)",
    labelTr: "2 Oda (2.0)",
    labelEn: "2 Rooms (2.0)",
    labelRu: "2 комнаты (2.0)",
    portals: {
      "4zida": "2.0",
      halooglasi: "Dvosoban",
      sasomange: "2.0",
      nekretnine: "Dvosoban",
    },
  },
  "2.5": {
    key: "2.5",
    labelSrLat: "Dvoiposoban (2.5)",
    labelSrCyr: "Двоипособан (2.5)",
    labelTr: "2.5 Oda (2.5)",
    labelEn: "2.5 Rooms (2.5)",
    labelRu: "2.5 комнаты (2.5)",
    portals: {
      "4zida": "2.5",
      halooglasi: "Dvoiposoban",
      sasomange: "2.5",
      nekretnine: "Dvoiposoban",
    },
  },
  "3.0": {
    key: "3.0",
    labelSrLat: "Trosoban (3.0)",
    labelSrCyr: "Трособан (3.0)",
    labelTr: "3 Oda (3.0)",
    labelEn: "3 Rooms (3.0)",
    labelRu: "3 комнаты (3.0)",
    portals: {
      "4zida": "3.0",
      halooglasi: "Trosoban",
      sasomange: "3.0",
      nekretnine: "Trosoban",
    },
  },
  "3.5": {
    key: "3.5",
    labelSrLat: "Troiposoban (3.5)",
    labelSrCyr: "Троипособан (3.5)",
    labelTr: "3.5 Oda (3.5)",
    labelEn: "3.5 Rooms (3.5)",
    labelRu: "3.5 комнаты (3.5)",
    portals: {
      "4zida": "3.5",
      halooglasi: "Troiposoban",
      sasomange: "3.5",
      nekretnine: "Troiposoban",
    },
  },
  "4.0": {
    key: "4.0",
    labelSrLat: "Četvorosoban (4.0)",
    labelSrCyr: "Четворособан (4.0)",
    labelTr: "4 Oda (4.0)",
    labelEn: "4 Rooms (4.0)",
    labelRu: "4 комнаты (4.0)",
    portals: {
      "4zida": "4.0",
      halooglasi: "Četvorosoban",
      sasomange: "4.0",
      nekretnine: "Četvorosoban",
    },
  },
  "5.0+": {
    key: "5.0+",
    labelSrLat: "Petosoban+ (5.0+)",
    labelSrCyr: "Петособан+ (5.0+)",
    labelTr: "5+ Oda (5.0+)",
    labelEn: "5+ Rooms (5.0+)",
    labelRu: "5+ комнат (5.0+)",
    portals: {
      "4zida": "5.0+",
      halooglasi: "Petosoban+",
      sasomange: "5.0+",
      nekretnine: "Ostalo",
    },
  },
};

// ---------------------------------------------------------------------------
// 4. HEATING TYPES (Vrsta grejanja)
// ---------------------------------------------------------------------------
export const HEATING_TYPES: Record<string, PortalMappedValue> = {
  cg: {
    key: "cg",
    labelSrLat: "Centralno grejanje (CG)",
    labelSrCyr: "Централно грејање (ЦГ)",
    labelTr: "Merkezi Isıtma (CG)",
    labelEn: "Central Heating (CG)",
    labelRu: "Центральное отопление (CG)",
    portals: {
      "4zida": "1",
      halooglasi: "CG",
      sasomange: "CENTRAL",
      nekretnine: "Centralno grejanje",
    },
  },
  eg: {
    key: "eg",
    labelSrLat: "Etažno grejanje (EG)",
    labelSrCyr: "Етажно грејање (ЕГ)",
    labelTr: "Kat Kaloriferi / Bireysel (EG)",
    labelEn: "Individual Heating (EG)",
    labelRu: "Индивидуальное отопление (EG)",
    portals: {
      "4zida": "2",
      halooglasi: "EG",
      sasomange: "ETAZNO",
      nekretnine: "Etažno grejanje",
    },
  },
  gas: {
    key: "gas",
    labelSrLat: "Gas",
    labelSrCyr: "Гас",
    labelTr: "Doğalgaz",
    labelEn: "Gas",
    labelRu: "Газ",
    portals: {
      "4zida": "4",
      halooglasi: "Gas",
      sasomange: "GAS",
      nekretnine: "Gas",
    },
  },
  underfloor: {
    key: "underfloor",
    labelSrLat: "Podno grejanje",
    labelSrCyr: "Подно грејање",
    labelTr: "Yerden Isıtma",
    labelEn: "Underfloor Heating",
    labelRu: "Теплый пол",
    portals: {
      "4zida": "7",
      halooglasi: "Podno",
      sasomange: "UNDERFLOOR",
      nekretnine: "Podno grejanje",
    },
  },
  ta: {
    key: "ta",
    labelSrLat: "TA peć / Struja",
    labelSrCyr: "ТА пећ / Струја",
    labelTr: "Termoakümülatör (TA) / Elektrik",
    labelEn: "Storage Heater (TA) / Electric",
    labelRu: "ТА печь / Электричество",
    portals: {
      "4zida": "8",
      halooglasi: "TA",
      sasomange: "TA_PEC",
      nekretnine: "TA peć",
    },
  },
  klima: {
    key: "klima",
    labelSrLat: "Klima uređaj / Toplotna pumpa",
    labelSrCyr: "Клима уређај / Топлотна пумпа",
    labelTr: "Klima / Isı Pompası",
    labelEn: "Air Conditioning / Heat Pump",
    labelRu: "Кондиционер / Тепловой насос",
    portals: {
      "4zida": "12",
      halooglasi: "Klima",
      sasomange: "AC",
      nekretnine: "Klima uređaj",
    },
  },
};

// ---------------------------------------------------------------------------
// 5. PROPERTY CONDITION (Stanje nekretnine)
// ---------------------------------------------------------------------------
export const PROPERTY_CONDITIONS: Record<string, PortalMappedValue> = {
  novogradnja: {
    key: "novogradnja",
    labelSrLat: "Novogradnja",
    labelSrCyr: "Новоградња",
    labelTr: "Yeni Bina (Novogradnja)",
    labelEn: "New Construction",
    labelRu: "Новостройка",
    portals: {
      "4zida": "2",
      halooglasi: "Novogradnja",
      sasomange: "NEW_BUILD",
      nekretnine: "Novogradnja",
    },
  },
  renovirano: {
    key: "renovirano",
    labelSrLat: "Renovirano",
    labelSrCyr: "Реновирано",
    labelTr: "Yenilenmiş (Renovirano)",
    labelEn: "Renovated",
    labelRu: "После ремонта",
    portals: {
      "4zida": "4",
      halooglasi: "Renovirano",
      sasomange: "RENOVATED",
      nekretnine: "Renovirano",
    },
  },
  lux: {
    key: "lux",
    labelSrLat: "Lux",
    labelSrCyr: "Лукс",
    labelTr: "Lüks (Lux)",
    labelEn: "Luxury (Lux)",
    labelRu: "Люкс (Lux)",
    portals: {
      "4zida": "6",
      halooglasi: "Lux",
      sasomange: "LUX",
      nekretnine: "Lux",
    },
  },
  izvorno: {
    key: "izvorno",
    labelSrLat: "Izvorno stanje",
    labelSrCyr: "Изворно стање",
    labelTr: "Orijinal Durumda (Izvorno)",
    labelEn: "Original Condition",
    labelRu: "Исходное состояние",
    portals: {
      "4zida": "1",
      halooglasi: "Izvorno stanje",
      sasomange: "STANDARD",
      nekretnine: "Standardna gradnja",
    },
  },
  u_izgradnji: {
    key: "u_izgradnji",
    labelSrLat: "U izgradnji",
    labelSrCyr: "У изградњи",
    labelTr: "İnşaat Halinde (U izgradnji)",
    labelEn: "Under Construction",
    labelRu: "Строящийся объект",
    portals: {
      "4zida": "3",
      halooglasi: "U izgradnji",
      sasomange: "UNDER_CONSTRUCTION",
      nekretnine: "U izgradnji",
    },
  },
};

// ---------------------------------------------------------------------------
// 6. FURNISHING (Opremljenost / Nameštenost)
// ---------------------------------------------------------------------------
export const FURNISHING_TYPES: Record<string, PortalMappedValue> = {
  furnished: {
    key: "furnished",
    labelSrLat: "Namešten",
    labelSrCyr: "Намештен",
    labelTr: "Eşyalı",
    labelEn: "Furnished",
    labelRu: "Меблирована",
    portals: {
      "4zida": "3",
      halooglasi: "Namešteno",
      sasomange: "FURNISHED",
      nekretnine: "Namešteno",
    },
  },
  semi_furnished: {
    key: "semi_furnished",
    labelSrLat: "Polunamešten",
    labelSrCyr: "Полунамештен",
    labelTr: "Yarı Eşyalı",
    labelEn: "Semi-Furnished",
    labelRu: "Частично меблирована",
    portals: {
      "4zida": "2",
      halooglasi: "Polunamešteno",
      sasomange: "SEMI_FURNISHED",
      nekretnine: "Polunamešteno",
    },
  },
  unfurnished: {
    key: "unfurnished",
    labelSrLat: "Prazan / Nenamešten",
    labelSrCyr: "Празан / Ненамештен",
    labelTr: "Boş / Eşyasız",
    labelEn: "Unfurnished",
    labelRu: "Без мебели",
    portals: {
      "4zida": "1",
      halooglasi: "Prazno",
      sasomange: "UNFURNISHED",
      nekretnine: "Prazno",
    },
  },
};

// ---------------------------------------------------------------------------
// 7. SERBIAN CITIES, MUNICIPALITIES (OPŠTINE) & NEIGHBORHOODS (NASELJA)
// ---------------------------------------------------------------------------
export interface SerbianMunicipality {
  name: string;
  neighborhoods: string[];
}

export interface SerbianCityLocation {
  city: string;
  cityCyr: string;
  municipalities: SerbianMunicipality[];
}

export const SERBIAN_LOCATIONS: SerbianCityLocation[] = [
  {
    city: "Beograd",
    cityCyr: "Београд",
    municipalities: [
      {
        name: "Stari Grad",
        neighborhoods: [
          "Dorćol",
          "Donji Dorćol",
          "Gornji Dorćol",
          "Knez Mihailova",
          "Skadarlija",
          "Kosančićev venac",
          "Trg Republike",
          "Terazije",
          "Kopitareva gradina",
          "Studentski trg",
        ],
      },
      {
        name: "Vračar",
        neighborhoods: [
          "Hram Svetog Save",
          "Crveni Krst",
          "Kalenić pijaca",
          "Čubura",
          "Neimar",
          "Cvetni trg",
          "Slavija",
          "Južni bulevar",
          "Krunski venac",
        ],
      },
      {
        name: "Novi Beograd",
        neighborhoods: [
          "Arena / Blok 29",
          "Belville (Blok 67)",
          "A Blok (Blok 67a)",
          "West 65 (Blok 65)",
          "Airport City",
          "Ušće / Blok 21",
          "Hotel Jugoslavija / Kej",
          "Fontana",
          "Bežanijska kosa",
          "Savski blokovi (Blok 44, 45, 70)",
          "Paviljoni",
          "Tošin bunar",
          "Ledine",
        ],
      },
      {
        name: "Savski Venac",
        neighborhoods: [
          "Beograd na vodi (Belgrade Waterfront)",
          "Dedinje",
          "Senjak",
          "Sarajevska",
          "Klinički centar",
          "Prokop",
          "Topčider",
        ],
      },
      {
        name: "Zvezdara",
        neighborhoods: [
          "Vukov spomenik",
          "Đeram pijaca",
          "Lion",
          "Bulevar kralja Aleksandra",
          "Cvetkova pijaca",
          "Zvezdarska šuma",
          "Mirijevo",
          "Konjarnik",
          "Učiteljsko naselje",
          "Dimitrija Tucovića",
        ],
      },
      {
        name: "Palilula",
        neighborhoods: [
          "Tašmajdan",
          "Profesorska kolonija",
          "Cvijićeva",
          "Bogoslovija",
          "Karaburma",
          "Višnjička banja",
          "Borča",
          "Krnjača",
        ],
      },
      {
        name: "Voždovac",
        neighborhoods: [
          "Autokomanda",
          "Lekino brdo (Pašino brdo)",
          "Dušanovac",
          "Voždovačka crkva",
          "Stepa Stepanović",
          "Banjica",
          "Medaković",
          "Braće Jerković",
          "Šumice",
        ],
      },
      {
        name: "Zemun",
        neighborhoods: [
          "Zemunski kej",
          "Donji grad",
          "Gornji grad",
          "Retenzija",
          "Kalvarija",
          "Altina",
          "Zemun Polje",
          "Batajnica",
        ],
      },
      {
        name: "Čukarica",
        neighborhoods: [
          "Banovo brdo",
          "Ada Ciganlija",
          "Košutnjak",
          "Požeška",
          "Golf naselje",
          "Cerak vinogradi",
          "Vidikovac",
          "Žarkovo",
        ],
      },
      {
        name: "Rakovica",
        neighborhoods: [
          "Miljakovac",
          "Kanarevo brdo",
          "Labudovo brdo",
          "Petlovo brdo",
          "Košutnjak - Rakovica",
        ],
      },
    ],
  },
  {
    city: "Novi Sad",
    cityCyr: "Нови Сад",
    municipalities: [
      {
        name: "Grad Novi Sad",
        neighborhoods: [
          "Grbavica",
          "Liman 1",
          "Liman 2",
          "Liman 3",
          "Liman 4",
          "Centar / Stari Grad",
          "Bulevar oslobođenja",
          "Novo naselje (Bistrica)",
          "Detelinara (Nova / Stara)",
          "Podbara",
          "Rotkvarija",
          "Telep",
          "Sajmište",
          "Petrovaradin",
          "Sremska Kamenica",
        ],
      },
    ],
  },
  {
    city: "Niš",
    cityCyr: "Ниш",
    municipalities: [
      {
        name: "Medijana",
        neighborhoods: [
          "Centar",
          "Bulevar Nemanjića",
          "Čair",
          "Duvanište",
          "Margir",
          "Кičevo",
        ],
      },
      {
        name: "Palilula",
        neighborhoods: ["Palilulska rampa", "Delijski vis", "Bubanj"],
      },
      {
        name: "Pantelej",
        neighborhoods: ["Pantelej", "Durlan", "Somborska"],
      },
    ],
  },
  {
    city: "Kragujevac",
    cityCyr: "Крагујевац",
    municipalities: [
      {
        name: "Grad Kragujevac",
        neighborhoods: ["Centar", "Aerodrom", "Bubanj", "Erdoglija", "Vašarište"],
      },
    ],
  },
  {
    city: "Subotica",
    cityCyr: "Суботица",
    municipalities: [
      {
        name: "Grad Subotica",
        neighborhoods: ["Centar", "Prozivka", "Radijalac", "Palić", "Kertvaroš"],
      },
    ],
  },
  {
    city: "Zlatibor",
    cityCyr: "Златибор",
    municipalities: [
      {
        name: "Čajetina",
        neighborhoods: ["Centar Zlatibora", "Obudojevica", "Kalman", "Zova"],
      },
    ],
  },
];

// ---------------------------------------------------------------------------
// 8. NORMALIZATION & PORTAL VALUE RESOLVERS
// ---------------------------------------------------------------------------

export function mapTransactionType(
  raw: string | null | undefined,
  portal: PortalKey
): string {
  const normalized = (raw || "izdavanje").trim().toLowerCase();
  const key =
    normalized === "prodaja" || normalized === "sale" ? "prodaja" : "izdavanje";
  return TRANSACTION_TYPES[key].portals[portal];
}

export function mapPropertyType(
  raw: string | null | undefined,
  portal: PortalKey
): string {
  const normalized = (raw || "apartment").trim().toLowerCase();
  const canonical =
    PROPERTY_TYPES[normalized]?.key ||
    PROPERTY_TYPE_ALIASES[normalized] ||
    "apartment";
  return PROPERTY_TYPES[canonical].portals[portal];
}

export function mapRoomStructure(
  raw: string | null | undefined,
  portal: PortalKey
): string {
  const normalized = (raw || "2.0").trim().toLowerCase();
  if (normalized === "0.5" || normalized === "studio" || normalized === "garsonjera") {
    return ROOM_STRUCTURES["studio"].portals[portal];
  }
  if (ROOM_STRUCTURES[normalized]) {
    return ROOM_STRUCTURES[normalized].portals[portal];
  }
  if (normalized.startsWith("4") && normalized.includes("+")) {
    return ROOM_STRUCTURES["4.0"].portals[portal];
  }
  return ROOM_STRUCTURES["2.0"].portals[portal];
}

export function mapHeatingType(
  raw: string | null | undefined,
  portal: PortalKey
): string {
  const normalized = (raw || "cg").trim().toLowerCase();
  const aliasMap: Record<string, string> = {
    centralno: "cg",
    etazno: "eg",
    etažno: "eg",
    podno: "underfloor",
    struja: "ta",
  };
  const canonical = HEATING_TYPES[normalized]
    ? normalized
    : aliasMap[normalized] || "cg";
  return HEATING_TYPES[canonical].portals[portal];
}

export function mapPropertyCondition(
  raw: string | null | undefined,
  portal: PortalKey
): string {
  const normalized = (raw || "renovirano").trim().toLowerCase();
  const canonical = PROPERTY_CONDITIONS[normalized] ? normalized : "renovirano";
  return PROPERTY_CONDITIONS[canonical].portals[portal];
}

export function mapFurnishingType(
  raw: string | null | undefined,
  portal: PortalKey
): string {
  const normalized = (raw || "furnished").trim().toLowerCase();
  const canonical = FURNISHING_TYPES[normalized] ? normalized : "furnished";
  return FURNISHING_TYPES[canonical].portals[portal];
}

export function mapFloorValue(raw: string | null | undefined): string {
  if (!raw) return "1";
  const normalized = raw.trim().toLowerCase();
  if (normalized === "suteren" || normalized === "bodrum") return "-1";
  if (normalized === "prizemlje" || normalized === "visoko_prizemlje") return "0";
  return normalized.replace("+", "");
}

/**
 * Resolves 4zida's mandatory 3-digit numerical <struktura> code:
 * 101 to 118 for apartments (garsonjera = 101, 1.0 = 102, 1.5 = 103, 2.0 = 104, 2.5 = 105, 3.0 = 106, 3.5 = 107, 4.0 = 108...)
 * 201 to 206 for houses (1-etažna kuća = 201...)
 * 300 to 313 for commercial spaces
 * 400 to 403 for land (plac)
 * 500 to 502 for garages/parking
 */
export function map4ZidaStructure(
  propertyType: string | null | undefined,
  roomCount: string | null | undefined
): number {
  const p = (propertyType || "apartment").trim().toLowerCase();

  if (p === "house" || p === "kuca" || p === "kuća") {
    return 201; // 1-etažna kuća
  }
  if (p === "commercial" || p === "poslovni_prostor" || p === "lokal" || p === "office") {
    return 300; // Poslovni prostor
  }
  if (p === "land" || p === "plac" || p === "zemljiste" || p === "zemljište") {
    return 400; // Plac
  }
  if (p === "garage" || p === "garaza" || p === "garaža" || p === "parking") {
    return 501; // Garaža
  }

  // Apartments (default)
  const r = (roomCount || "2.0").trim().toLowerCase();
  if (r === "0.5" || r === "studio" || r === "garsonjera") return 101;
  if (r === "1.0" || r === "1") return 102;
  if (r === "1.5") return 103;
  if (r === "2.0" || r === "2") return 104;
  if (r === "2.5") return 105;
  if (r === "3.0" || r === "3") return 106;
  if (r === "3.5") return 107;
  if (r === "4.0" || r === "4") return 108;
  if (r === "4.5") return 109;
  if (r === "5.0" || r === "5" || r.startsWith("5") || r.startsWith("4+")) return 110;
  if (r === "5.5") return 111;
  if (r === "6.0" || r === "6") return 112;

  return 104; // 2.0 default
}


/**
 * Maps floor value to 4zida's strict floor numerical enumeration:
 * -4: Podrum, -3: Suteren, -2: Nisko prizemlje, -1: Prizemlje, 0: Visoko prizemlje, 1..99: Sprat, 100: Potkrovlje
 */
export function map4ZidaFloor(raw: string | null | undefined): number | null {
  if (!raw) return null;
  const normalized = raw.trim().toLowerCase();
  if (normalized === "podrum") return -4;
  if (normalized === "suteren") return -3;
  if (normalized === "nisko_prizemlje" || normalized === "nisko prizemlje") return -2;
  if (normalized === "prizemlje" || normalized === "pr") return -1;
  if (normalized === "visoko_prizemlje" || normalized === "visoko prizemlje" || normalized === "vpr") return 0;
  if (normalized === "potkrovlje" || normalized === "pk") return 100;

  const parsed = parseInt(normalized.replace(/[^0-9-]/g, ""), 10);
  if (!isNaN(parsed)) return parsed;
  return null;
}

// ---------------------------------------------------------------------------
// 7. HALO OGLASI STRICT XSD MAPPERS
// ---------------------------------------------------------------------------

export function mapHaloPropertyPurpose(propertyType: string | null | undefined): string {
  const p = (propertyType || "").trim().toLowerCase();
  if (p === "commercial" || p === "poslovni_prostor" || p === "lokal" || p === "office") {
    return "Poslovni prostor";
  }
  return "Stambeni prostor";
}

export function mapHaloPropertyClass(propertyType: string | null | undefined): string {
  const p = (propertyType || "").trim().toLowerCase();
  if (p === "house" || p === "kuca" || p === "kuća") return "Kuća";
  if (p === "commercial" || p === "poslovni_prostor" || p === "lokal" || p === "office") return "Lokal";
  if (p === "land" || p === "plac" || p === "zemljiste" || p === "zemljište") return "Plac";
  if (p === "garage" || p === "garaza" || p === "garaža" || p === "parking") return "Garaža";
  return "Stan";
}

export function mapHaloStructure(
  roomCount: string | null | undefined,
  propertyClass: string
): string {
  if (propertyClass === "Plac" || propertyClass === "Garaža") {
    return "1.0";
  }
  const r = (roomCount || "2.0").trim().toLowerCase();
  if (r === "0.5" || r === "studio" || r === "garsonjera") return "0.5";
  if (r === "1.0" || r === "1") return "1.0";
  if (r === "1.5") return "1.5";
  if (r === "2.0" || r === "2") return "2.0";
  if (r === "2.5") return "2.5";
  if (r === "3.0" || r === "3") return "3.0";
  if (r === "3.5") return "3.5";
  if (r === "4.0" || r === "4") return "4.0";
  if (r === "4.5") return "4.5";
  if (r === "5.0" || r === "5" || r.startsWith("5") || r.startsWith("4+")) return "5.0";

  const num = parseFloat(r.replace(",", "."));
  if (!isNaN(num) && num >= 0.5 && num <= 20.0) {
    return num.toFixed(1);
  }
  return "2.0";
}

export function mapHaloHeating(raw: string | null | undefined): string {
  if (!raw) return "EG";
  const normalized = raw.trim().toLowerCase();
  if (normalized === "cg" || normalized === "centralno") return "CG";
  if (normalized === "eg" || normalized === "etazno" || normalized === "etažno") return "EG";
  if (normalized === "ta" || normalized === "ta pec" || normalized === "ta peć") return "TA";
  if (normalized === "gas") return "gas";
  if (normalized === "underfloor" || normalized === "podno") return "podno";
  if (normalized === "toplotne_pumpe" || normalized === "toplotna pumpa") return "toplotne pumpe";
  if (normalized === "norveski_radijatori" || normalized === "norveški radijatori") return "norveški radijatori";
  if (normalized === "mermerni_radijatori" || normalized === "mermerni radijatori") return "mermerni radijatori";
  if (normalized === "kaljeva_pec" || normalized === "kaljeva peć") return "kaljeva peć";
  return "EG";
}

export function mapHaloFloor(raw: string | null | undefined): string {
  if (!raw) return "1";
  const normalized = raw.trim().toLowerCase();
  if (normalized === "suteren" || normalized === "sut") return "sut";
  if (normalized === "polusuteren" || normalized === "psut") return "psut";
  if (normalized === "nisko_prizemlje" || normalized === "nisko prizemlje" || normalized === "npr") return "npr";
  if (normalized === "prizemlje" || normalized === "pr") return "pr";
  if (normalized === "visoko_prizemlje" || normalized === "visoko prizemlje" || normalized === "vpr") return "vpr";
  if (normalized === "potkrovlje" || normalized === "pk") return "vpr";

  const parsed = parseInt(normalized.replace(/[^0-9]/g, ""), 10);
  if (!isNaN(parsed) && parsed >= 1 && parsed <= 30) {
    return String(parsed);
  }
  return "1";
}

export function mapHaloPropertyState(condition: string | null | undefined): string {
  if (!condition) return "renoviran";
  const c = condition.trim().toLowerCase();
  if (c === "lux") return "lux";
  if (c === "izvorno" || c === "izvorno stanje") return "izvorno stanje";
  if (c === "za_renoviranje" || c === "za renoviranje") return "za renoviranje";
  if (c === "za_rusenje" || c === "za rušenje") return "za rušenje";
  return "renoviran";
}

export function mapHaloPropertyKind(
  condition: string | null | undefined,
  propertyType: string | null | undefined
): string {
  const p = (propertyType || "").trim().toLowerCase();
  if (p === "garage" || p === "garaza" || p === "garaža") return "garažno mesto";

  const c = (condition || "").trim().toLowerCase();
  if (c === "novogradnja" || c === "u_izgradnji") return "novogradnja";
  return "stara gradnja";
}

export function mapHaloFurnishing(raw: string | null | undefined): string {
  if (!raw) return "Namešten";
  const f = raw.trim().toLowerCase();
  if (f === "unfurnished" || f === "prazan" || f === "empty") return "Prazan";
  if (f === "semi_furnished" || f === "polunamesten" || f === "polunamešten") return "Polunamešten";
  return "Namešten";
}

export function mapHaloAmenities(
  amenities: string[] | null | undefined,
  propertyType?: string | null
): string {
  const allowed = [
    "Lift", "Terasa", "Lođa", "Garaža", "Parking", "Podrum",
    "Klima", "Interfon", "Internet", "KATV", "Telefon", "Video nadzor",
    "Bazen", "Kamin", "Bašta", "Sa baštom"
  ];
  const list: string[] = [];
  const amSet = new Set((amenities || []).map((a) => a.trim().toLowerCase()));

  if (amSet.has("elevator") || amSet.has("lift")) list.push("Lift");
  if (amSet.has("balcony") || amSet.has("terasa")) list.push("Terasa");
  if (amSet.has("loggia") || amSet.has("lodja") || amSet.has("lođa")) list.push("Lođa");
  if (amSet.has("garage") || amSet.has("garaza") || amSet.has("garaža")) list.push("Garaža");
  if (amSet.has("parking")) list.push("Parking");
  if (amSet.has("storage") || amSet.has("podrum")) list.push("Podrum");
  if (amSet.has("ac") || amSet.has("klima")) list.push("Klima");
  if (amSet.has("intercom") || amSet.has("interfon")) list.push("Interfon");
  if (amSet.has("internet")) list.push("Internet");
  if (amSet.has("cable_tv") || amSet.has("katv") || amSet.has("kablovska")) list.push("KATV");
  if (amSet.has("video_surveillance") || amSet.has("video_nadzor")) list.push("Video nadzor");
  if (amSet.has("pool") || amSet.has("bazen")) list.push("Bazen");
  if (amSet.has("fireplace") || amSet.has("kamin")) list.push("Kamin");
  if (amSet.has("garden") || amSet.has("basta") || amSet.has("bašta")) list.push("Bašta");

  if (list.length === 0) {
    list.push("Internet");
  }
  return list.join(", ");
}

export function mapHaloAdditional(
  amenities: string[] | null | undefined,
  isPetFriendly?: boolean | null
): string {
  const list: string[] = [];
  const amSet = new Set((amenities || []).map((a) => a.trim().toLowerCase()));

  if (isPetFriendly || amSet.has("pet_friendly") || amSet.has("ljubimci")) {
    list.push("Dozvoljeni kućni ljubimci");
  }
  return list.join(", ");
}

/**
 * Deterministic positive integer (long) generator for Halo Oglasi <PropertyId>.
 * Halo Oglasi requires PropertyId to be a pure number without letters (xs:long).
 */
export function getHaloDeterministicLongId(idOrRef: string): number {
  if (!idOrRef) return 100001;
  const numericOnly = idOrRef.replace(/\D/g, "");
  if (numericOnly.length >= 4 && numericOnly.length <= 15) {
    const parsed = parseInt(numericOnly, 10);
    if (!isNaN(parsed) && parsed > 0) return parsed;
  }

  // DJB2 hash variant that produces safe positive 52-bit integer
  let hash = 5381;
  for (let i = 0; i < idOrRef.length; i++) {
    hash = ((hash << 5) + hash) + idOrRef.charCodeAt(i);
    hash = Math.abs(hash % 9000000000000);
  }
  return 1000000 + (hash % 8999999999);
}



