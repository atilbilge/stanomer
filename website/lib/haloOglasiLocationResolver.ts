import locationsRaw from "./locationsHaloOglasi.json";

export interface HaloLocationItem {
  city: string;
  part: string;
  micro: string;
}

interface NormalizedLocation {
  cityNorm: string;
  partNorm: string;
  microNorm: string;
  rawCity: string;
  rawPart: string;
  rawMicro: string;
}

function normalizeStr(s: string | null | undefined): string {
  if (!s) return "";
  return s
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/đ/g, "dj")
    .replace(/opstina/g, "")
    .replace(/[^a-z0-9]/g, "");
}

// Pre-normalize locations
const normalizedLocations: NormalizedLocation[] = (locationsRaw as HaloLocationItem[]).map(
  (loc) => ({
    cityNorm: normalizeStr(loc.city),
    partNorm: normalizeStr(loc.part),
    microNorm: normalizeStr(loc.micro),
    rawCity: loc.city,
    rawPart: loc.part,
    rawMicro: loc.micro,
  })
);

export interface ResolvedHaloLocation {
  city: string;
  cityPart: string;
  cityMicrolocation: string;
}

const DEFAULT_LOCATION: ResolvedHaloLocation = {
  city: "Beograd",
  cityPart: "Opština Stari grad",
  cityMicrolocation: "Centar",
};

/**
 * Resolves Stanomer (city, municipality, neighborhood) to Halo Oglasi official (City, CityPart, CityMicrolocation).
 * Must return values that match Halo Oglasi šifarnik exactly.
 */
export function resolveHaloOglasiLocation(
  city: string | null | undefined,
  municipality: string | null | undefined,
  neighborhood: string | null | undefined
): ResolvedHaloLocation {
  const cNorm = normalizeStr(city || "Beograd");
  const mNorm = normalizeStr(municipality);
  const nNorm = normalizeStr(neighborhood);

  // Filter locations matching city first
  const cityMatches = normalizedLocations.filter(
    (loc) => loc.cityNorm === cNorm || (cNorm && loc.cityNorm.includes(cNorm))
  );

  const pool = cityMatches.length > 0 ? cityMatches : normalizedLocations;

  // 1. Exact match on micro (neighborhood) + part (municipality)
  if (nNorm && mNorm) {
    for (const loc of pool) {
      if (
        (loc.microNorm === nNorm || loc.microNorm.includes(nNorm) || nNorm.includes(loc.microNorm)) &&
        (loc.partNorm.includes(mNorm) || mNorm.includes(loc.partNorm))
      ) {
        return {
          city: loc.rawCity,
          cityPart: loc.rawPart,
          cityMicrolocation: loc.rawMicro,
        };
      }
    }
  }

  // 2. Match on micro (neighborhood) within city pool
  if (nNorm) {
    for (const loc of pool) {
      if (loc.microNorm === nNorm) {
        return {
          city: loc.rawCity,
          cityPart: loc.rawPart,
          cityMicrolocation: loc.rawMicro,
        };
      }
    }
    for (const loc of pool) {
      if (
        loc.microNorm.length >= 4 &&
        (loc.microNorm.includes(nNorm) || nNorm.includes(loc.microNorm))
      ) {
        return {
          city: loc.rawCity,
          cityPart: loc.rawPart,
          cityMicrolocation: loc.rawMicro,
        };
      }
    }
  }

  // 3. Match on municipality within city pool
  if (mNorm) {
    for (const loc of pool) {
      if (loc.partNorm.includes(mNorm) || mNorm.includes(loc.partNorm)) {
        return {
          city: loc.rawCity,
          cityPart: loc.rawPart,
          cityMicrolocation: loc.rawMicro,
        };
      }
    }
  }

  // 4. Fallback to first entry in city pool, or default
  if (cityMatches.length > 0) {
    // Prefer "Centar" if available
    const centar = cityMatches.find((l) => l.microNorm.includes("centar"));
    if (centar) {
      return {
        city: centar.rawCity,
        cityPart: centar.rawPart,
        cityMicrolocation: centar.rawMicro,
      };
    }
    return {
      city: cityMatches[0].rawCity,
      cityPart: cityMatches[0].rawPart,
      cityMicrolocation: cityMatches[0].rawMicro,
    };
  }

  return DEFAULT_LOCATION;
}

