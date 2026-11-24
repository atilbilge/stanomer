import { NextRequest, NextResponse } from "next/server";
import { supabase } from "../../../../../lib/supabaseClient";
import {
  PortalKey,
  mapTransactionType,
  mapPropertyType,
  mapRoomStructure,
  mapHeatingType,
  mapPropertyCondition,
  mapFurnishingType,
  mapFloorValue,
  map4ZidaStructure,
  map4ZidaFloor,
  mapHaloPropertyPurpose,
  mapHaloPropertyClass,
  mapHaloStructure,
  mapHaloHeating,
  mapHaloFloor,
  mapHaloPropertyState,
  mapHaloPropertyKind,
  mapHaloFurnishing,
  mapHaloAmenities,
  mapHaloAdditional,
  getHaloDeterministicLongId,
} from "../../../../../lib/serbianRealEstateDict";
import { resolve4ZidaKraj } from "../../../../../lib/krajevi4zidaResolver";
import { resolveHaloOglasiLocation } from "../../../../../lib/haloOglasiLocationResolver";

export interface FeedPropertyImage {
  id: string;
  url: string;
  order_index: number;
  is_cover: boolean;
}

export interface FeedPropertyRecord {
  id: string;
  agency_id: string | null;
  external_ref: string | null;
  title: string | null;
  description: string | null;
  transaction_type: string | null;
  property_type: string | null;
  price: number | null;
  deposit_amount: number | null;
  currency: string | null;
  area_sqm: number | null;
  room_count: string | null;
  floor: string | null;
  total_floors: number | null;
  heating_type: string | null;
  condition: string | null;
  furnishing: string | null;
  city: string | null;
  municipality: string | null;
  neighborhood: string | null;
  address: string | null;
  latitude: number | null;
  longitude: number | null;
  amenities: string[] | null;
  published_portals: string[] | null;
  updated_at: string | null;
  created_at: string | null;
  listing_images?: FeedPropertyImage[];
}

interface AgencyMetadata {
  id: string;
  name: string;
  email: string;
  phone: string;
  website: string;
}

function escapeXml(unsafe: string | number | null | undefined): string {
  if (unsafe === null || unsafe === undefined) return "";
  return String(unsafe)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&apos;");
}

function wrapCdata(text: string | null | undefined): string {
  if (!text) return "<![CDATA[]]>";
  const safeText = String(text).replace(/]]>/g, "]]]]><![CDATA[>");
  return `<![CDATA[${safeText}]]>`;
}

function resolvePortalKey(rawPortalParam: string): PortalKey | null {
  const cleaned = rawPortalParam
    .trim()
    .toLowerCase()
    .replace(/\.xml$/i, "");
  if (cleaned === "4zida") return "4zida";
  if (cleaned === "halooglasi" || cleaned === "halo") return "halooglasi";
  if (cleaned === "sasomange") return "sasomange";
  if (cleaned === "nekretnine") return "nekretnine";
  return null;
}

function getEffectivePrice(item: FeedPropertyRecord): number {
  if (item.price && Number(item.price) > 0) {
    return Number(item.price);
  }
  return 0;
}

function getEffectiveTitle(item: FeedPropertyRecord): string {
  if (item.title && item.title.trim().length > 0) return item.title.trim();
  const city = item.city || "Beograd";
  const muni = item.municipality ? `, ${item.municipality}` : "";
  return `Nekretnina - ${city}${muni}`;
}

function getSortedImages(item: FeedPropertyRecord): FeedPropertyImage[] {
  const imgs = Array.isArray(item.listing_images)
    ? [...item.listing_images]
    : [];
  return imgs.sort((a, b) => {
    if (a.is_cover !== b.is_cover) return a.is_cover ? -1 : 1;
    return (a.order_index ?? 0) - (b.order_index ?? 0);
  });
}

function hasAmenity(item: FeedPropertyRecord, key: string): boolean {
  if (!Array.isArray(item.amenities)) return false;
  return item.amenities.some((a) => a.toLowerCase() === key.toLowerCase());
}

// ---------------------------------------------------------------------------
// DEMO / SANDBOX SEED LISTINGS FOR IMMEDIATE PORTAL VALIDATION
// ---------------------------------------------------------------------------
function getDemoFeedListings(agencyId: string): FeedPropertyRecord[] {
  const nowIso = new Date().toISOString();
  return [
    {
      id: "demo-prop-001",
      agency_id: agencyId,
      external_ref: "BG-VR-101",
      title: "Luksuzan trosoban stan kod Hrama Svetog Save sa garažom",
      description:
        "Kompletno opremljen, svetao trosoban stan u novogradnji u neposrednoj blizini Hrama Svetog Save. Poseduje prostranu dnevnu sobu sa trpezarijom, dve spavaće sobe, dva kupatila, terasu i garažno mesto u zgradi.",
      transaction_type: "izdavanje",
      property_type: "apartment",
      price: 1250,
      deposit_amount: 1250,
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
      latitude: 44.7981,
      longitude: 20.4689,
      amenities: ["elevator", "balcony", "parking", "ac", "intercom"],
      published_portals: ["stanomer", "4zida", "halooglasi", "sasomange", "nekretnine"],
      created_at: nowIso,
      updated_at: nowIso,
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
      agency_id: agencyId,
      external_ref: "BG-NBG-204",
      title: "Moderan dvosoban stan u A Bloku, Novi Beograd",
      description:
        "Uknjižen, izuzetno funkcionalan dvosoban stan u prestižnom kompleksu A Blok na Novom Beogradu. Odlična investicija i za život i za izdavanje.",
      transaction_type: "prodaja",
      property_type: "apartment",
      price: 215000,
      deposit_amount: null,
      currency: "EUR",
      area_sqm: 56,
      room_count: "2.0",
      floor: "4",
      total_floors: 8,
      heating_type: "cg",
      condition: "novogradnja",
      furnishing: "semi_furnished",
      city: "Beograd",
      municipality: "Novi Beograd",
      neighborhood: "A Blok (Blok 67a)",
      address: "Uroša Martinovića 12",
      latitude: 44.8058,
      longitude: 20.4025,
      amenities: ["elevator", "balcony", "parking", "storage"],
      published_portals: ["stanomer", "4zida", "halooglasi", "sasomange", "nekretnine"],
      created_at: nowIso,
      updated_at: nowIso,
      listing_images: [
        {
          id: "img-204-1",
          url: "https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=1200&q=80",
          order_index: 0,
          is_cover: true,
        },
      ],
    },
  ];
}

// ---------------------------------------------------------------------------
// 4ZIDA.RS HELPER FUNCTIONS (Strict non-empty tag generation & address parsing)
// ---------------------------------------------------------------------------
function emitTag(
  name: string,
  value: string | number | null | undefined
): string {
  if (value === null || value === undefined) return "";
  const str = String(value).trim();
  if (str === "") return "";
  return `    <${name}>${escapeXml(str)}</${name}>\n`;
}

function emitCdataTag(
  name: string,
  value: string | null | undefined
): string {
  if (value === null || value === undefined) return "";
  const str = String(value).trim();
  if (str === "") return "";
  return `    <${name}>${wrapCdata(str)}</${name}>\n`;
}

function parseAddress(
  rawAddress: string | null | undefined,
  fallbackNeighborhood?: string | null,
  fallbackMunicipality?: string | null
): { street: string; number: string | null } {
  if (rawAddress && rawAddress.trim().length > 0) {
    const trimmed = rawAddress.trim();
    const match = trimmed.match(/^(.*?)[,\s]+(\d+[\s\w\/-]*)$/);
    if (match && match[1].trim()) {
      return { street: match[1].trim(), number: match[2].trim() };
    }
    return { street: trimmed, number: null };
  }

  const fallback = (
    fallbackNeighborhood ||
    fallbackMunicipality ||
    "Centar"
  ).trim();
  return { street: fallback, number: null };
}

// ---------------------------------------------------------------------------
// 1. 4ZIDA.RS XML BUILDER (Official 4zida.rs V6 XML Specification)
// ---------------------------------------------------------------------------
function build4ZidaXml(
  _agency: AgencyMetadata,
  listings: FeedPropertyRecord[]
): string {
  const oglasList = listings
    .map((item) => {
      const code = item.external_ref || item.id;
      const price = Math.round(getEffectivePrice(item));
      const tip = mapTransactionType(item.transaction_type, "4zida"); // "1" prodaja, "2" izdavanje
      const krajId = resolve4ZidaKraj(
        item.city,
        item.municipality,
        item.neighborhood
      );
      const struktura = map4ZidaStructure(item.property_type, item.room_count);
      const { street, number } = parseAddress(
        item.address,
        item.neighborhood,
        item.municipality
      );

      const isLand =
        item.property_type === "land" ||
        item.property_type === "plac" ||
        item.property_type === "zemljiste";
      const area = Math.round(item.area_sqm || 0);

      // Start building <oglas> with NO empty tags
      let xml = "  <oglas>\n";
      // Mandatory tags:
      xml += emitTag("id", code);
      xml += emitTag("tip", tip);
      xml += emitTag("kraj", krajId);
      xml += emitTag("cena", price);
      if (isLand) {
        const ari = item.area_sqm ? (item.area_sqm / 100).toFixed(2) : "1.00";
        xml += emitTag("plac", ari);
      } else {
        xml += emitTag("povrsina", area > 0 ? area : 50);
      }
      xml += emitTag("struktura", struktura);
      xml += emitTag("adresa", street);

      // Optional tags (only emitted if non-empty):
      if (number) xml += emitTag("broj_ulice", number);

      const title = getEffectiveTitle(item);
      if (title) xml += emitTag("podnaslov", title);

      if (item.description && item.description.trim()) {
        xml += emitCdataTag("opis", item.description.trim());
      }

      if (item.condition) {
        const stanje = mapPropertyCondition(item.condition, "4zida");
        if (stanje) xml += emitTag("stanje", stanje);
      }

      if (item.furnishing) {
        const opremljenost = mapFurnishingType(item.furnishing, "4zida");
        if (opremljenost) xml += emitTag("opremljenost", opremljenost);
      }

      const sprat = map4ZidaFloor(item.floor);
      if (sprat !== null) {
        xml += emitTag("sprat", sprat);
      }

      if (item.total_floors && item.total_floors > 0) {
        xml += emitTag("spratnost", item.total_floors);
      }

      if (item.heating_type) {
        const grejanje = mapHeatingType(item.heating_type, "4zida");
        if (grejanje) xml += emitTag("grejanje", grejanje);
      }

      // Amenities (only positive values emitted)
      if (hasAmenity(item, "elevator")) xml += emitTag("lift", 1);
      if (hasAmenity(item, "balcony")) xml += emitTag("terasa", 1);
      if (hasAmenity(item, "garage")) xml += emitTag("garaza", 1);
      if (hasAmenity(item, "parking")) xml += emitTag("parking", 1);
      if (hasAmenity(item, "storage")) xml += emitTag("podrum", 1);
      if (hasAmenity(item, "ac")) xml += emitTag("klima", 1);
      if (hasAmenity(item, "intercom")) xml += emitTag("interfon", 1);
      if (hasAmenity(item, "internet")) xml += emitTag("internet", 1);
      if (hasAmenity(item, "cable_tv")) xml += emitTag("kablovska", 1);

      if (item.latitude) xml += emitTag("latitude", item.latitude);
      if (item.longitude) xml += emitTag("longitude", item.longitude);

      // Slike
      const images = getSortedImages(item);
      if (images.length > 0) {
        xml += "    <slike>\n";
        images.forEach((img, idx) => {
          xml += `      <slika id="${idx + 1}">${escapeXml(img.url)}</slika>\n`;
        });
        xml += "    </slike>\n";
      }

      xml += "  </oglas>";
      return xml;
    })
    .join("\n");

  return `<?xml version="1.0" encoding="UTF-8"?>\n<oglasi>\n${oglasList}\n</oglasi>`;
}

// ---------------------------------------------------------------------------
// 2. HALO OGLASI XML BUILDER (Official Halo Oglasi XSD & XML Specification)
// ---------------------------------------------------------------------------
function buildHaloOglasiXml(
  agency: AgencyMetadata,
  listings: FeedPropertyRecord[]
): string {
  const saleListings = listings.filter(
    (item) =>
      (item.transaction_type || "").trim().toLowerCase() !== "izdavanje" &&
      (item.transaction_type || "").trim().toLowerCase() !== "rent"
  );
  const rentListings = listings.filter(
    (item) =>
      (item.transaction_type || "").trim().toLowerCase() === "izdavanje" ||
      (item.transaction_type || "").trim().toLowerCase() === "rent"
  );

  const renderPropertyXml = (
    item: FeedPropertyRecord,
    isRent: boolean
  ): string => {
    const longId = getHaloDeterministicLongId(item.external_ref || item.id);
    const purpose = mapHaloPropertyPurpose(item.property_type);
    const action = isRent ? "Izdavanje" : "Prodaja";
    const propClass = mapHaloPropertyClass(item.property_type);
    const structure = mapHaloStructure(item.room_count, propClass);
    const heating = mapHaloHeating(item.heating_type);
    const floor = mapHaloFloor(item.floor);
    const totalFloors =
      item.total_floors && item.total_floors >= 1 && item.total_floors <= 30
        ? item.total_floors
        : 5;
    const isMultifloor = 0;
    const phoneLines = "1";
    const propState = mapHaloPropertyState(item.condition);
    const propKind = mapHaloPropertyKind(item.condition, item.property_type);
    const constrYear = 2005;
    const extRef = (item.external_ref || item.id).slice(0, 15);
    const registered = 1;
    const title = getEffectiveTitle(item);
    const desc =
      item.description && item.description.trim()
        ? item.description.trim()
        : title;
    const amenities = mapHaloAmenities(item.amenities, item.property_type);
    const additional = mapHaloAdditional(item.amenities);
    const furnishing = mapHaloFurnishing(item.furnishing);
    const loc = resolveHaloOglasiLocation(
      item.city,
      item.municipality,
      item.neighborhood
    );
    const { street, number } = parseAddress(
      item.address,
      item.neighborhood,
      item.municipality
    );
    const surface = Math.max(1, Math.round(item.area_sqm || 50));
    const rawPrice = Math.round(getEffectivePrice(item));
    const price = isRent
      ? Math.max(10, rawPrice)
      : Math.max(10000, rawPrice);

    const sortedImages = getSortedImages(item);
    let imagesXml = "";
    if (sortedImages.length > 0) {
      imagesXml = sortedImages
        .map((img, idx) => {
          const isDef = idx === 0 || img.is_cover ? ' IsDefaultImage="1"' : "";
          return `          <Image${isDef}>${wrapCdata(img.url)}</Image>`;
        })
        .join("\n");
    } else {
      imagesXml = `          <Image IsDefaultImage="1"><![CDATA[https://stanomer.rs/placeholder.jpg]]></Image>`;
    }

    let xml = "      <Property>\n";
    xml += `        <PropertyId>${longId}</PropertyId>\n`;
    xml += `        <PropertyPurpose>${purpose}</PropertyPurpose>\n`;
    xml += `        <PropertyAction>${action}</PropertyAction>\n`;
    xml += `        <PropertyClass>${propClass}</PropertyClass>\n`;
    xml += `        <Structure>${structure}</Structure>\n`;
    xml += `        <HeatingType>${heating}</HeatingType>\n`;
    xml += `        <Floor>${floor}</Floor>\n`;
    xml += `        <TotalFloors>${totalFloors}</TotalFloors>\n`;
    xml += `        <IsMultifloor>${isMultifloor}</IsMultifloor>\n`;
    xml += `        <NumberOfPhoneLines>${phoneLines}</NumberOfPhoneLines>\n`;
    if (isRent) {
      xml += `        <RoomRentalPurpose>Standardno</RoomRentalPurpose>\n`;
      xml += `        <RoomUsage>Kupatilo</RoomUsage>\n`;
    }
    xml += `        <PropertyState>${propState}</PropertyState>\n`;
    xml += `        <PropertyTypes></PropertyTypes>\n`;
    xml += `        <PropertyKind>${propKind}</PropertyKind>\n`;
    xml += `        <ConstructionYear>${constrYear}</ConstructionYear>\n`;
    xml += `        <PropertyLister>agencija</PropertyLister>\n`;
    xml += `        <AgencyCommission>100</AgencyCommission>\n`;
    xml += `        <AgencyCommissionUnit>%</AgencyCommissionUnit>\n`;
    xml += `        <AgencyCommissionDescription>Posredovanje</AgencyCommissionDescription>\n`;
    xml += `        <AgencyAdExternalId>${escapeXml(extRef)}</AgencyAdExternalId>\n`;
    xml += `        <PropertyRegistered>${registered}</PropertyRegistered>\n`;
    if (title) xml += `        <Title>${escapeXml(title)}</Title>\n`;
    xml += `        <Description>${wrapCdata(desc)}</Description>\n`;
    xml += `        <IsAvailableNow>1</IsAvailableNow>\n`;
    xml += `        <Amenities>${escapeXml(amenities)}</Amenities>\n`;
    xml += `        <Additional>${escapeXml(additional)}</Additional>\n`;
    xml += `        <Furnishing>${furnishing}</Furnishing>\n`;
    xml += `        <Country>Srbija</Country>\n`;
    xml += `        <City>${escapeXml(loc.city)}</City>\n`;
    xml += `        <CityPart>${escapeXml(loc.cityPart)}</CityPart>\n`;
    xml += `        <CityMicrolocation>${escapeXml(loc.cityMicrolocation)}</CityMicrolocation>\n`;
    xml += `        <Street>${escapeXml(street)}</Street>\n`;
    xml += `        <HouseNumber>${escapeXml(number || "bb")}</HouseNumber>\n`;
    xml += `        <AppartmentNumber></AppartmentNumber>\n`;
    xml += `        <PropertySurface>${surface}</PropertySurface>\n`;
    xml += `        <PropertyLandSurface>${surface}</PropertyLandSurface>\n`;
    xml += `        <PropertyLandSurfaceUnit>m2</PropertyLandSurfaceUnit>\n`;
    if (item.latitude && item.longitude) {
      xml += `        <Geolocation>${item.latitude.toFixed(6)}, ${item.longitude.toFixed(6)}</Geolocation>\n`;
    } else {
      xml += `        <Geolocation>44.816558, 20.503528</Geolocation>\n`;
    }
    xml += `        <Price>${price}</Price>\n`;
    if (isRent) {
      xml += `        <MonthlyUtilities>${item.deposit_amount || 0}</MonthlyUtilities>\n`;
      xml += `        <PaymentType>mesečno</PaymentType>\n`;
      xml += `        <Deposit>${item.deposit_amount && item.deposit_amount > 0 ? 1 : 0}</Deposit>\n`;
    }
    xml += `        <ContactPhone1>${escapeXml(agency.phone || "")}</ContactPhone1>\n`;
    xml += `        <ContactPhone2></ContactPhone2>\n`;
    xml += `        <ContactEmail>${escapeXml(agency.email || "")}</ContactEmail>\n`;
    xml += `        <ContactAddress>${escapeXml(agency.website || "")}</ContactAddress>\n`;
    xml += `        <AgentName>${escapeXml(agency.name || "")}</AgentName>\n`;
    xml += `        <AdType>STANDARD30I</AdType>\n`;
    xml += `        <DisableAutoRenewal>0</DisableAutoRenewal>\n`;
    xml += `        <ThreeDTourUrl></ThreeDTourUrl>\n`;
    xml += `        <VideoUrl></VideoUrl>\n`;
    xml += `        <Images>\n${imagesXml}\n        </Images>\n`;
    xml += "      </Property>";
    return xml;
  };

  const saleXml = saleListings
    .map((it) => renderPropertyXml(it, false))
    .join("\n");
  const rentXml = rentListings
    .map((it) => renderPropertyXml(it, true))
    .join("\n");

  return `<?xml version="1.0" encoding="UTF-8"?>
<Agencies>
  <Agency>
    <AgencyId>${escapeXml(agency.id)}</AgencyId>
    <Name>${escapeXml(agency.name)}</Name>
    <TaxNumber>0</TaxNumber>
    <RegistragionNumber>0</RegistragionNumber>
    <PropertiesForSale>
${saleXml}
    </PropertiesForSale>
    <PropertiesForRent>
${rentXml}
    </PropertiesForRent>
  </Agency>
</Agencies>`;
}

// ---------------------------------------------------------------------------
// 3. SASOMANGE & NEKRETNINE.RS XML BUILDER
// ---------------------------------------------------------------------------
function buildSasomangeOrNekretnineXml(
  portal: "sasomange" | "nekretnine",
  agency: AgencyMetadata,
  listings: FeedPropertyRecord[]
): string {
  const generatedAt = new Date().toISOString();
  const rootTag = portal === "sasomange" ? "Ads" : "Nekretnine";
  const itemTag = portal === "sasomange" ? "Ad" : "Nekretnina";

  const itemsXml = listings
    .map((item) => {
      const code = item.external_ref || item.id;
      const price = getEffectivePrice(item);
      const currency = item.currency || "EUR";
      const images = getSortedImages(item);
      const imagesXml = images
        .map((img) => `        <Photo>${escapeXml(img.url)}</Photo>`)
        .join("\n");

      return `    <${itemTag}>
      <Id>${escapeXml(item.id)}</Id>
      <Code>${escapeXml(code)}</Code>
      <DealType>${escapeXml(mapTransactionType(item.transaction_type, portal))}</DealType>
      <Category>${escapeXml(mapPropertyType(item.property_type, portal))}</Category>
      <Title>${wrapCdata(getEffectiveTitle(item))}</Title>
      <Description>${wrapCdata(item.description || "")}</Description>
      <Price currency="${escapeXml(currency)}">${price}</Price>
      <Area>${item.area_sqm ?? 0}</Area>
      <Rooms>${escapeXml(mapRoomStructure(item.room_count, portal))}</Rooms>
      <Floor>${escapeXml(mapFloorValue(item.floor))}</Floor>
      <TotalFloors>${item.total_floors ?? ""}</TotalFloors>
      <Heating>${escapeXml(mapHeatingType(item.heating_type, portal))}</Heating>
      <Condition>${escapeXml(mapPropertyCondition(item.condition, portal))}</Condition>
      <Furnished>${escapeXml(mapFurnishingType(item.furnishing, portal))}</Furnished>
      <City>${escapeXml(item.city || "Beograd")}</City>
      <Municipality>${escapeXml(item.municipality || "")}</Municipality>
      <Quarter>${escapeXml(item.neighborhood || "")}</Quarter>
      <Address>${escapeXml(item.address || "")}</Address>
      <Latitude>${item.latitude ?? ""}</Latitude>
      <Longitude>${item.longitude ?? ""}</Longitude>
      <AgencyName>${escapeXml(agency.name)}</AgencyName>
      <ContactPhone>${escapeXml(agency.phone)}</ContactPhone>
      <ContactEmail>${escapeXml(agency.email)}</ContactEmail>
      <Photos>
${imagesXml}
      </Photos>
      <LastModified>${escapeXml(item.updated_at || item.created_at || generatedAt)}</LastModified>
    </${itemTag}>`;
    })
    .join("\n");

  return `<?xml version="1.0" encoding="UTF-8"?>
<${rootTag} generator="Stanomer Agency Hub" generatedAt="${escapeXml(generatedAt)}">
${itemsXml}
</${rootTag}>`;
}

// ---------------------------------------------------------------------------
// ROUTE HANDLER: GET /api/feed/[agency_id]/[portal]
// ---------------------------------------------------------------------------
export async function GET(
  request: NextRequest,
  context: { params: Promise<{ agency_id: string; portal: string }> }
) {
  const startTime = Date.now();
  let resolvedProfileId: string | null = null;
  try {
    const resolvedParams = await context.params;
    const rawAgencyId = (resolvedParams.agency_id || "").trim();
    const rawPortal = (resolvedParams.portal || "").trim();

    const portalKey = resolvePortalKey(rawPortal);
    if (!portalKey) {
      return new NextResponse(
        `<?xml version="1.0" encoding="UTF-8"?><Error>Unsupported portal '${escapeXml(
          rawPortal
        )}'. Supported feeds: 4zida.xml, halooglasi.xml, sasomange.xml, nekretnine.xml</Error>`,
        {
          status: 400,
          headers: {
            "Content-Type": "application/xml; charset=utf-8",
          },
        }
      );
    }

    const isDemoMode =
      rawAgencyId.toLowerCase() === "demo" ||
      request.nextUrl.searchParams.get("demo") === "1" ||
      request.nextUrl.searchParams.get("demo") === "true";

    let agencyMeta: AgencyMetadata = {
      id: rawAgencyId,
      name: "Stanomer Partner Agencija",
      email: "office@stanomer.online",
      phone: "+381 60 000 0000",
      website: "https://www.stanomer.online",
    };

    let listings: FeedPropertyRecord[] = [];

    if (isDemoMode) {
      agencyMeta = {
        id: rawAgencyId,
        name: "Stanomer Demo Nekretnine Beograd",
        email: "partner@stanomer.online",
        phone: "+381 11 400 0000",
        website: "https://www.stanomer.online/agencies",
      };
      listings = getDemoFeedListings(rawAgencyId);
    } else {
      // 1. Resolve agency profile (UUID) or directory agency (BIGINT / slug)
      const isUuid =
        /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(
          rawAgencyId
        );

      resolvedProfileId = isUuid ? rawAgencyId : null;

      if (!isUuid) {
        // Try looking up in agencies + view_clean_agencies or agency_referral_partners by id or slug
        const isNumericId = /^\d+$/.test(rawAgencyId);
        if (isNumericId) {
          const [{ data: dirAgency }, { data: baseAgency }] = await Promise.all([
            supabase
              .from("view_clean_agencies")
              .select("id, acente_adi, eposta_adresleri, telefonlar, web_sitesi")
              .eq("id", Number(rawAgencyId))
              .maybeSingle(),
            supabase
              .from("agencies")
              .select("id, name, website, profile_id")
              .eq("id", Number(rawAgencyId))
              .maybeSingle(),
          ]);

          if (dirAgency || baseAgency) {
            agencyMeta = {
              id: String(rawAgencyId),
              name: dirAgency?.acente_adi || baseAgency?.name || agencyMeta.name,
              email:
                (dirAgency?.eposta_adresleri || "").split(",")[0]?.trim() ||
                agencyMeta.email,
              phone:
                (dirAgency?.telefonlar || "").split(",")[0]?.trim() ||
                agencyMeta.phone,
              website:
                dirAgency?.web_sitesi || baseAgency?.website || agencyMeta.website,
            };
            if (baseAgency?.profile_id) {
              resolvedProfileId = baseAgency.profile_id;
            }
          }
        } else {
          const { data: refAgency } = await supabase
            .from("agency_referral_partners")
            .select("agency_name, email, phone, website, slug")
            .eq("slug", rawAgencyId.toLowerCase())
            .maybeSingle();

          if (refAgency) {
            agencyMeta = {
              id: refAgency.slug,
              name: refAgency.agency_name || agencyMeta.name,
              email: refAgency.email || agencyMeta.email,
              phone: refAgency.phone || agencyMeta.phone,
              website: refAgency.website || agencyMeta.website,
            };
          }
        }
      }

      if (resolvedProfileId) {
        const { data: profileData } = await supabase
          .from("profiles")
          .select("id, company_name, full_name, email, phone_number, website_url")
          .eq("id", resolvedProfileId)
          .maybeSingle();

        if (profileData) {
          agencyMeta = {
            id: profileData.id,
            name:
              profileData.company_name ||
              profileData.full_name ||
              agencyMeta.name,
            email: profileData.email || agencyMeta.email,
            phone: profileData.phone_number || agencyMeta.phone,
            website: profileData.website_url || agencyMeta.website,
          };
        }

        // 2. Fetch published listings + images from isolated `listings`
        const { data: propsData, error: propsError } = await supabase
          .from("listings")
          .select(
            `
            id,
            agency_id,
            external_ref,
            title,
            description,
            transaction_type,
            property_type,
            price,
            deposit_amount,
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
            latitude,
            longitude,
            amenities,
            published_portals,
            updated_at,
            created_at,
            listing_images (
              id,
              url,
              order_index,
              is_cover
            )
          `
          )
          .eq("agency_id", resolvedProfileId)
          .eq("is_published", true)
          .order("updated_at", { ascending: false })
          .limit(500);

        if (!propsError && Array.isArray(propsData)) {
          listings = (propsData as unknown as FeedPropertyRecord[]).filter(
            (item) => {
              if (!Array.isArray(item.published_portals)) return true;
              return item.published_portals.includes(portalKey);
            }
          );
        }
      }
    }

    let xmlOutput = "";
    if (portalKey === "4zida") {
      xmlOutput = build4ZidaXml(agencyMeta, listings);
    } else if (portalKey === "halooglasi") {
      xmlOutput = buildHaloOglasiXml(agencyMeta, listings);
    } else {
      xmlOutput = buildSasomangeOrNekretnineXml(
        portalKey,
        agencyMeta,
        listings
      );
    }

    const durationMs = Date.now() - startTime;
    const ip =
      request.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ||
      request.headers.get("x-real-ip") ||
      null;
    const userAgent = request.headers.get("user-agent") || null;

    // Asynchronously log crawler hit in background (zero impact on XML response latency)
    if (!isDemoMode && resolvedProfileId) {
      (async () => {
        try {
          const { error: logErr } = await supabase
            .from("portal_feed_logs")
            .insert({
              agency_id: resolvedProfileId,
              portal: portalKey,
              ip_address: ip,
              user_agent: userAgent,
              listing_count: listings.length,
              status_code: 200,
              duration_ms: durationMs,
            });
          if (logErr) {
            console.warn("Could not insert portal_feed_log:", logErr.message);
          }
        } catch (e) {
          console.warn("Portal feed log catch:", e);
        }
      })();
    }

    return new NextResponse(xmlOutput, {
      status: 200,
      headers: {
        "Content-Type": "application/xml; charset=utf-8",
        "Cache-Control": "public, s-maxage=1800, stale-while-revalidate=3600",
        "X-Stanomer-Portal": portalKey,
        "X-Stanomer-Listing-Count": String(listings.length),
        "X-Stanomer-Duration-Ms": String(durationMs),
      },
    });
  } catch (err) {
    console.error("XML Feed generation error:", err);
    return new NextResponse(
      `<?xml version="1.0" encoding="UTF-8"?><Error>Internal XML Feed Error</Error>`,
      {
        status: 500,
        headers: {
          "Content-Type": "application/xml; charset=utf-8",
        },
      }
    );
  }
}

