import krajeviRaw from "./krajevi4zida.json";

export interface KrajItem {
  id: number;
  name: string;
  parent: string;
}

interface NormalizedKraj {
  id: number;
  nameNorm: string;
  parentNorm: string;
  rawName: string;
  rawParent: string;
}

function normalizeStr(s: string | null | undefined): string {
  if (!s) return "";
  return s
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/đ/g, "dj")
    .replace(/[^a-z0-9]/g, "");
}

// Pre-normalize and sort by length descending to match most specific (longer) names first
const normalizedKrajevi: NormalizedKraj[] = (krajeviRaw as KrajItem[])
  .map((k) => ({
    id: k.id,
    nameNorm: normalizeStr(k.name),
    parentNorm: normalizeStr(k.parent),
    rawName: k.name,
    rawParent: k.parent,
  }))
  .sort((a, b) => b.rawName.length - a.rawName.length);

// Quick lookup map: "nameNorm|parentNorm" -> id
const directMap = new Map<string, number>();
for (const k of normalizedKrajevi) {
  directMap.set(`${k.nameNorm}|${k.parentNorm}`, k.id);
}

/**
 * Resolves a property's city, municipality and neighborhood to an official 4zida kraj ID.
 * Follows 4zida's strict micro-location recommendation (always prefer specific neighborhood over city).
 */
export function resolve4ZidaKraj(
  city: string | null | undefined,
  municipality: string | null | undefined,
  neighborhood: string | null | undefined
): number {
  const nNorm = normalizeStr(neighborhood);
  const mNorm = normalizeStr(municipality);
  const cNorm = normalizeStr(city || "Beograd");

  // 1. Direct match on neighborhood + municipality
  if (nNorm && mNorm) {
    const directKey = `${nNorm}|${mNorm}`;
    for (const [key, id] of directMap.entries()) {
      if (key.startsWith(nNorm) && (key.includes(mNorm) || key.includes(cNorm))) {
        return id;
      }
    }
  }

  // 2. Exact name match where parent contains municipality or city
  if (nNorm) {
    for (const k of normalizedKrajevi) {
      if (k.nameNorm === nNorm && (k.parentNorm.includes(mNorm) || k.parentNorm.includes(cNorm))) {
        return k.id;
      }
    }

    // Substring match with longest name first
    for (const k of normalizedKrajevi) {
      if (
        k.nameNorm.length >= 3 &&
        (k.nameNorm.includes(nNorm) || nNorm.includes(k.nameNorm)) &&
        (k.parentNorm.includes(mNorm) || k.parentNorm.includes(cNorm))
      ) {
        return k.id;
      }
    }
  }

  // 3. Fallback to Municipality
  if (mNorm) {
    for (const k of normalizedKrajevi) {
      if (k.nameNorm === mNorm && k.parentNorm.includes(cNorm)) {
        return k.id;
      }
    }
    for (const k of normalizedKrajevi) {
      if (
        k.nameNorm.length >= 3 &&
        (k.nameNorm.includes(mNorm) || mNorm.includes(k.nameNorm)) &&
        k.parentNorm.includes(cNorm)
      ) {
        return k.id;
      }
    }
  }

  // 4. Fallback to City default (e.g. Novi Sad, Niš, Kragujevac, Beograd)
  if (cNorm.includes("novisad")) {
    return 601; // Novi Sad Centar / Stari Grad
  }
  if (cNorm.includes("nis")) {
    return 4846; // Niš Medijana
  }
  if (cNorm.includes("kragujevac")) {
    return 2294; // Kragujevac Stari Grad
  }

  // Default fallback: Beograd - Vračar (ID 541)
  return 541;
}

