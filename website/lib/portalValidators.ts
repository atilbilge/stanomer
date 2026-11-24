import {
  map4ZidaStructure,
  map4ZidaFloor,
  mapHeatingType,
  mapPropertyCondition,
  mapFurnishingType,
  mapTransactionType,
  mapHaloPropertyClass,
  mapHaloStructure,
  PortalKey,
} from "./serbianRealEstateDict";
import { resolve4ZidaKraj } from "./krajevi4zidaResolver";
import { resolveHaloOglasiLocation, ResolvedHaloLocation } from "./haloOglasiLocationResolver";

export interface PortalValidationIssue {
  key: string;
  defaultText: string;
}

export interface PortalValidationItem {
  id?: string;
  external_ref?: string | null;
  title?: string | null;
  description?: string | null;
  transaction_type?: string | null;
  property_type?: string | null;
  price?: number | null;
  area_sqm?: number | null;
  room_count?: string | null;
  floor?: string | null;
  total_floors?: number | null;
  heating_type?: string | null;
  condition?: string | null;
  furnishing?: string | null;
  city?: string | null;
  municipality?: string | null;
  neighborhood?: string | null;
  address?: string | null;
  latitude?: number | null;
  longitude?: number | null;
  listing_images?: { id?: string; url: string; is_cover?: boolean }[] | null;
}

export interface PortalValidationResult {
  portal: PortalKey;
  portalName: string;
  isReady: boolean;
  errors: PortalValidationIssue[];
  warnings: PortalValidationIssue[];
  details: {
    resolvedKrajId?: number;
    strukturaCode?: number;
    tipCode?: string;
  };
}

/**
 * Validates a listing against 4zida.rs official V6 XML requirements before synchronization.
 * Returns translation keys (with fallback defaultText) to ensure 100% i18n support.
 */
export function validate4ZidaListing(
  item: PortalValidationItem
): PortalValidationResult {
  const errors: PortalValidationIssue[] = [];
  const warnings: PortalValidationIssue[] = [];

  // 1. Cena (Mandatory integer in EUR)
  if (!item.price || Number(item.price) <= 0) {
    errors.push({
      key: "agency_val_price_required",
      defaultText: "Cena mora biti veća od 0.",
    });
  }

  // 2. Povrsina / Plac (Mandatory area in m2 or ari)
  const isLand =
    item.property_type === "land" ||
    item.property_type === "plac" ||
    item.property_type === "zemljiste";
  if (!item.area_sqm || Number(item.area_sqm) <= 0) {
    errors.push(
      isLand
        ? {
            key: "agency_val_plot_area_required",
            defaultText: "Površina placa (u arima) je obavezna.",
          }
        : {
            key: "agency_val_area_required",
            defaultText: "Kvadratura (m²) je obavezna.",
          }
    );
  }

  // 3. Adresa (Mandatory street name)
  const rawAddress = (item.address || "").trim();
  if (!rawAddress) {
    if (!item.neighborhood && !item.municipality) {
      errors.push({
        key: "agency_val_address_required",
        defaultText: "Adresa (ulica) je obavezna za 4zida.",
      });
    } else {
      warnings.push({
        key: "agency_val_address_fallback_warn",
        defaultText:
          "Ulica nije navedena; naziv naselja će biti korišćen kao adresa.",
      });
    }
  }

  // 4. Tip transakcije (1 = Prodaja, 2 = Izdavanje)
  const tipCode = mapTransactionType(item.transaction_type, "4zida");
  if (tipCode !== "1" && tipCode !== "2") {
    errors.push({
      key: "agency_val_transaction_invalid",
      defaultText: "Tip transakcije mora biti 'prodaja' ili 'izdavanje'.",
    });
  }

  // 5. Struktura (Mandatory 3-digit numerical code)
  const strukturaCode = map4ZidaStructure(item.property_type, item.room_count);
  if (!strukturaCode || strukturaCode < 100) {
    errors.push({
      key: "agency_val_structure_unmatched",
      defaultText: "Struktura nekretnine ne odgovara 4zida šifarniku.",
    });
  }

  // 6. Kraj (Mandatory location ID from 4zida's 8,061 catalog)
  const resolvedKrajId = resolve4ZidaKraj(
    item.city,
    item.municipality,
    item.neighborhood
  );
  if (!resolvedKrajId || resolvedKrajId <= 0) {
    errors.push({
      key: "agency_val_kraj_not_found",
      defaultText: "Lokacija nije pronađena u 4zida šifarniku.",
    });
  } else if (!item.neighborhood && resolvedKrajId === 541) {
    warnings.push({
      key: "agency_val_micro_location_warn",
      defaultText:
        "Mikrolokacija nije navedena; dodeljen je opšti ID. Unos tačnog naselja znatno poboljšava vidljivost na 4zida.",
    });
  }

  // 7. Fotografije (Slike)
  const images = Array.isArray(item.listing_images) ? item.listing_images : [];
  if (images.length === 0) {
    warnings.push({
      key: "agency_val_no_photos_warn",
      defaultText:
        "Oglas nema fotografija. Oglasi bez slika imaju slabu vidljivost na 4zida.",
    });
  } else if (images.length < 3) {
    warnings.push({
      key: "agency_val_few_photos_warn",
      defaultText:
        "Preporučuje se najmanje 3 fotografije za bolju poziciju na 4zida.",
    });
  }

  // 8. Opis (Açıklama)
  const desc = (item.description || "").trim();
  if (!desc) {
    warnings.push({
      key: "agency_val_no_description_warn",
      defaultText: "Opis oglasa je prazan.",
    });
  } else if (desc.length < 50) {
    warnings.push({
      key: "agency_val_short_description_warn",
      defaultText: "Opis je prekratak (preporučuje se najmanje 50 karaktera).",
    });
  }

  // 9. Sprat (Kat bilgisi)
  if (!isLand && item.property_type === "apartment" && !item.floor) {
    warnings.push({
      key: "agency_val_floor_warn",
      defaultText: "Preporučuje se unos sprata za stanove.",
    });
  }

  return {
    portal: "4zida",
    portalName: "4zida.rs",
    isReady: errors.length === 0,
    errors,
    warnings,
    details: {
      resolvedKrajId,
      strukturaCode,
      tipCode,
    },
  };
}

/**
 * Validates a listing against Halo Oglasi official XSD schema and rules.
 * All user-facing error/warning texts are keys for 100% i18n support.
 */
export function validateHaloOglasiListing(
  item: PortalValidationItem
): PortalValidationResult {
  const errors: PortalValidationIssue[] = [];
  const warnings: PortalValidationIssue[] = [];

  const isRent =
    (item.transaction_type || "").trim().toLowerCase() === "izdavanje" ||
    (item.transaction_type || "").trim().toLowerCase() === "rent";

  const propClass = mapHaloPropertyClass(item.property_type);
  const price = Number(item.price || 0);

  // 1. Price Validation (XSD constraints)
  if (isRent) {
    if (price < 10) {
      errors.push({
        key: "agency_val_halo_min_rent_price",
        defaultText: "Minimalna cena zakupa na Halo oglasima je 10 €.",
      });
    }
  } else {
    if (propClass === "Stan" && price < 10000) {
      errors.push({
        key: "agency_val_halo_min_sale_price",
        defaultText:
          "Za prodaju stanova minimalna cena na Halo oglasima je 10.000 €.",
      });
    } else if (price < 100) {
      errors.push({
        key: "agency_val_halo_min_sale_price_other",
        defaultText: "Minimalna prodajna cena na Halo oglasima je 100 €.",
      });
    }
  }

  // 2. Surface / Kvadratura (>= 1 m2)
  if (!item.area_sqm || Number(item.area_sqm) < 1) {
    errors.push({
      key: "agency_val_area_required",
      defaultText: "Kvadratura (m²) je obavezna.",
    });
  }

  // 3. Description (Mandatory in XSD sequence)
  const desc = (item.description || "").trim();
  if (!desc) {
    errors.push({
      key: "agency_val_halo_description_required",
      defaultText: "Opis oglasa je obavezan za Halo oglase prema XSD specifikaciji.",
    });
  } else if (desc.length < 30) {
    warnings.push({
      key: "agency_val_short_description_warn",
      defaultText: "Opis je prekratak (preporučuje se najmanje 50 karaktera).",
    });
  }

  // 4. Photos (Mandatory in XSD: <Images><Image>...</Image></Images>)
  const images = Array.isArray(item.listing_images) ? item.listing_images : [];
  if (images.length === 0) {
    errors.push({
      key: "agency_val_halo_photo_required",
      defaultText: "Halo oglasi zahtevaju najmanje 1 fotografiju po oglasu.",
    });
  } else if (images.length < 3) {
    warnings.push({
      key: "agency_val_few_photos_warn",
      defaultText: "Preporučuje se najmanje 3 fotografije za bolju poziciju na portalu.",
    });
  }

  // 5. Location resolution
  const resolvedLoc = resolveHaloOglasiLocation(
    item.city,
    item.municipality,
    item.neighborhood
  );
  if (!item.city) {
    warnings.push({
      key: "agency_val_address_fallback_warn",
      defaultText: "Grad nije izričito naveden; Beograd je dodeljen kao podrazumevani grad.",
    });
  }

  const struktura = mapHaloStructure(item.room_count, propClass);

  return {
    portal: "halooglasi",
    portalName: "Halo Oglasi",
    isReady: errors.length === 0,
    errors,
    warnings,
    details: {
      strukturaCode: parseFloat(struktura) || 2.0,
      tipCode: isRent ? "Izdavanje" : "Prodaja",
    },
  };
}

/**
 * Validates a listing for all supported portals.
 */
export function validateAllPortalsListing(
  item: PortalValidationItem
): Record<"4zida" | "halooglasi", PortalValidationResult> {
  return {
    "4zida": validate4ZidaListing(item),
    halooglasi: validateHaloOglasiListing(item),
  };
}
