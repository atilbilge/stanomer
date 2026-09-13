import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@supabase/supabase-js";
import sharp from "sharp";

const DEV_SUPABASE_URL = "https://thvbpifahvasyzmngpzp.supabase.co";
const DEV_SUPABASE_KEY =
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRodmJwaWZhaHZhc3l6bW5ncHpwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODUyNjAxNzcsImV4cCI6MjEwMDgzNjE3N30.dNSz66kJcoSjflgCCrS7qw55efuDxF61TEMoYc3r4qU";

const BRANDFETCH_CLIENT_ID = "1idDi7dRCAP3DFQFv4c";

const USER_AGENT =
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36";

const HEX_RE = /#(?:[0-9a-fA-F]{3}){1,2}\b/g;
const PROP_VALUE_RE = /([a-zA-Z-]+)\s*:\s*([^;{}]+)[;}]/g;
const CSS_VAR_RE = /--([a-zA-Z0-9_-]*(?:primary|brand|accent|theme|main|gold)[a-zA-Z0-9_-]*)\s*:\s*([^;{}]+)/gi;

// --------------------------------------------------------------------------
// URL & Helper Utilities
// --------------------------------------------------------------------------

function normalizeUrl(input: string): { fullUrl: string; domain: string } {
  let cleaned = input.trim();
  if (!/^https?:\/\//i.test(cleaned)) {
    cleaned = "https://" + cleaned;
  }
  try {
    const parsed = new URL(cleaned);
    return {
      fullUrl: parsed.origin + (parsed.pathname !== "/" ? parsed.pathname : ""),
      domain: parsed.hostname,
    };
  } catch {
    const domain = cleaned.replace(/^https?:\/\//i, "").split("/")[0];
    return { fullUrl: "https://" + domain, domain };
  }
}

function resolveRelativeUrl(href: string, baseUrl: string): string {
  if (!href) return "";
  const trimmed = href.trim();
  if (trimmed.startsWith("http://") || trimmed.startsWith("https://")) {
    return trimmed;
  }
  if (trimmed.startsWith("//")) {
    return "https:" + trimmed;
  }
  try {
    const base = new URL(baseUrl);
    if (trimmed.startsWith("/")) {
      return `${base.origin}${trimmed}`;
    }
    return `${base.origin}/${trimmed}`;
  } catch {
    return trimmed;
  }
}

function getBrandfetchLogoUrl(domain: string, clientId = BRANDFETCH_CLIENT_ID): string {
  const cleanDomain = domain.replace(/^www\./i, "").toLowerCase();
  return `https://cdn.brandfetch.io/${cleanDomain}/w/512/h/512/type/logo/fallback/lettermark?c=${clientId}`;
}

function toCorsSafeUrl(rawUrl: string): string {
  if (!rawUrl) return "";
  // Brandfetch CDN already supports CORS natively (Access-Control-Allow-Origin: *)
  // and blocks weserv.nl proxy requests with 404, so return direct CDN URL.
  if (rawUrl.includes("brandfetch.io") || rawUrl.includes("weserv.nl")) return rawUrl;
  const clean = rawUrl.replace(/^https?:\/\//i, "");
  return `https://images.weserv.nl/?url=${encodeURIComponent(clean)}`;
}

// --------------------------------------------------------------------------
// Color Science & HSV Utilities
// --------------------------------------------------------------------------

function normalizeHex(hex: string): string {
  let h = hex.replace("#", "").trim();
  if (h.length === 3) {
    h = h.split("").map((c) => c + c).join("");
  }
  if (h.length === 6) {
    return `#${h.toUpperCase()}`;
  }
  return hex.toUpperCase();
}

function hexToRgb(hex: string): [number, number, number] {
  const norm = normalizeHex(hex).replace("#", "");
  const intVal = parseInt(norm, 16);
  if (isNaN(intVal)) return [0, 0, 0];
  return [(intVal >> 16) & 255, (intVal >> 8) & 255, intVal & 255];
}

function rgbToHex(r: number, g: number, b: number): string {
  const toHex = (c: number) => Math.max(0, Math.min(255, Math.round(c))).toString(16).padStart(2, "0");
  return `#${toHex(r)}${toHex(g)}${toHex(b)}`.toUpperCase();
}

function rgbToHsv(r: number, g: number, b: number): [number, number, number] {
  const rNorm = r / 255;
  const gNorm = g / 255;
  const bNorm = b / 255;
  const max = Math.max(rNorm, gNorm, bNorm);
  const min = Math.min(rNorm, gNorm, bNorm);
  const delta = max - min;

  let h = 0;
  if (delta !== 0) {
    if (max === rNorm) {
      h = ((gNorm - bNorm) / delta) % 6;
    } else if (max === gNorm) {
      h = (bNorm - rNorm) / delta + 2;
    } else {
      h = (rNorm - gNorm) / delta + 4;
    }
    h = Math.round(h * 60);
    if (h < 0) h += 360;
  }

  const s = max === 0 ? 0 : delta / max;
  const v = max;
  return [h / 360, s, v];
}

function isLightSurface(hex: string): boolean {
  const [r, g, b] = hexToRgb(hex);
  const [, s, v] = rgbToHsv(r, g, b);
  // High brightness and low saturation (white, off-white, light slate tint)
  return s <= 0.08 && v >= 0.92;
}

function isDarkText(hex: string): boolean {
  const [r, g, b] = hexToRgb(hex);
  const [, s, v] = rgbToHsv(r, g, b);
  // Low brightness for strong contrast against light card/input backgrounds
  return v <= 0.35 && s <= 0.40;
}

function isCleanBorder(hex: string): boolean {
  const [r, g, b] = hexToRgb(hex);
  const [, s, v] = rgbToHsv(r, g, b);
  return s <= 0.15 && v >= 0.75 && v <= 0.94;
}

function colorName(hex: string): string {
  const [r, g, b] = hexToRgb(hex);
  const [h, s, v] = rgbToHsv(r, g, b);

  if (v < 0.12) return "black";
  if (s < 0.08 && v > 0.9) return "white";
  if (s < 0.12) return "gray";

  const deg = h * 360;
  const buckets: [number, string][] = [
    [12, "red"],
    [28, "orange"],
    [48, "gold"],
    [65, "yellow"],
    [90, "lime"],
    [150, "green"],
    [180, "teal"],
    [200, "cyan"],
    [250, "blue"],
    [265, "indigo"],
    [290, "purple"],
    [320, "magenta"],
    [345, "pink"],
    [360, "red"],
  ];
  for (const [limit, name] of buckets) {
    if (deg <= limit) return name;
  }
  return "red";
}

function isGrayscale(hex: string, satThreshold = 0.12): boolean {
  const [r, g, b] = hexToRgb(hex);
  const [, s] = rgbToHsv(r, g, b);
  return s < satThreshold;
}

function isNearWhiteOrBlack(hex: string): boolean {
  const [r, g, b] = hexToRgb(hex);
  const [, s, v] = rgbToHsv(r, g, b);
  return (v > 0.95 && s < 0.1) || v < 0.08;
}

function dedupeByHue(hexList: string[]): string[] {
  const seenNames = new Set<string>();
  const result: string[] = [];
  for (const hexc of hexList) {
    const norm = normalizeHex(hexc);
    const name = colorName(norm);
    if (seenNames.has(name)) continue;
    seenNames.add(name);
    result.push(norm);
  }
  return result;
}

// Contrast guard: ensure primary color is dark enough for white button text
function ensureReadableContrast(hex: string): string {
  const [r, g, b] = hexToRgb(hex);
  const [h, s, v] = rgbToHsv(r, g, b);
  if (v > 0.85) {
    // Darken value to 0.75 so white text has strong contrast
    const newV = 0.72;
    // HSV to RGB
    const i = Math.floor(h * 6);
    const f = h * 6 - i;
    const p = newV * (1 - s);
    const q = newV * (1 - f * s);
    const t = newV * (1 - (1 - f) * s);
    let nr = 0, ng = 0, nb = 0;
    switch (i % 6) {
      case 0: nr = newV; ng = t; nb = p; break;
      case 1: nr = q; ng = newV; nb = p; break;
      case 2: nr = p; ng = newV; nb = t; break;
      case 3: nr = p; ng = q; nb = newV; break;
      case 4: nr = t; ng = p; nb = newV; break;
      case 5: nr = newV; ng = p; nb = q; break;
    }
    return rgbToHex(nr * 255, ng * 255, nb * 255);
  }
  return hex.toUpperCase();
}

// --------------------------------------------------------------------------
// Network & Scraping
// --------------------------------------------------------------------------

async function fetchExternalCss(html: string, baseUrl: string): Promise<string> {
  const linkMatches = [
    ...html.matchAll(/<link[^>]+rel=["'][^"']*stylesheet[^"']*["'][^>]+href=["']([^"']+)["']/gi),
    ...html.matchAll(/<link[^>]+href=["']([^"']+)["'][^>]+rel=["'][^"']*stylesheet[^"']*["']/gi),
  ];

  const cssUrls: string[] = [];
  for (const m of linkMatches) {
    const href = m[1];
    if (href && !cssUrls.includes(href)) {
      cssUrls.push(href);
      if (cssUrls.length >= 5) break;
    }
  }

  if (cssUrls.length === 0) return "";

  const fetchPromises = cssUrls.map(async (relUrl) => {
    const fullCssUrl = resolveRelativeUrl(relUrl, baseUrl);
    try {
      const res = await fetch(fullCssUrl, {
        headers: { "User-Agent": USER_AGENT },
        signal: AbortSignal.timeout(3000),
      });
      if (res.ok) {
        return await res.text();
      }
    } catch {
      // Ignore individual CSS timeouts
    }
    return "";
  });

  const results = await Promise.allSettled(fetchPromises);
  return results
    .filter((r): r is PromiseFulfilledResult<string> => r.status === "fulfilled")
    .map((r) => r.value)
    .join("\n");
}

// --------------------------------------------------------------------------
// Image Color Extraction via Sharp (PNG, JPG, WebP, SVG)
// --------------------------------------------------------------------------

async function extractLogoColors(logoBuffer: Buffer, isSvg: boolean): Promise<string[]> {
  const colors: string[] = [];

  // If SVG, also extract inline vector fills and strokes directly
  if (isSvg) {
    const svgText = logoBuffer.toString("utf-8");
    const svgFills = [...svgText.matchAll(/(?:fill|stroke|stop-color)=["'](#[0-9a-fA-F]{3,6})["']/gi)].map(m => m[1]);
    for (const hex of svgFills) {
      if (!isGrayscale(hex) && !isNearWhiteOrBlack(hex)) {
        colors.push(hex.toUpperCase());
      }
    }
  }

  try {
    // Resize down to 48x48 max for fast color quantization
    const { data, info } = await sharp(logoBuffer)
      .resize(48, 48, { fit: "inside" })
      .ensureAlpha()
      .raw()
      .toBuffer({ resolveWithObject: true });

    const colorBins: Record<string, number> = {};
    const step = 4; // RGBA step

    for (let i = 0; i < data.length; i += step) {
      const a = data[i + 3];
      if (a < 128) continue; // Skip transparent

      const r = data[i];
      const g = data[i + 1];
      const b = data[i + 2];

      // Skip near white and near black
      if (r > 240 && g > 240 && b > 240) continue;
      if (r < 25 && g < 25 && b < 25) continue;

      // Quantize to 16-step bins
      const qr = Math.round(r / 16) * 16;
      const qg = Math.round(g / 16) * 16;
      const qb = Math.round(b / 16) * 16;
      const hex = rgbToHex(qr, qg, qb);

      if (!isGrayscale(hex)) {
        colorBins[hex] = (colorBins[hex] || 0) + 1;
      }
    }

    // Sort quantized bins by frequency
    const sortedBins = Object.entries(colorBins)
      .sort((a, b) => b[1] - a[1])
      .map(([hex]) => hex);

    colors.push(...sortedBins);
  } catch (err: any) {
    console.warn("Sharp logo color extraction warning:", err.message);
  }

  return dedupeByHue(colors);
}

// --------------------------------------------------------------------------
// CSS Color Categorization
// --------------------------------------------------------------------------

function categorizeCssColors(allCssAndHtml: string) {
  const categories = {
    background: new Map<string, number>(),
    text: new Map<string, number>(),
    border: new Map<string, number>(),
    brand: new Map<string, number>(),
  };

  const inc = (map: Map<string, number>, hex: string, weight = 1) => {
    map.set(hex, (map.get(hex) || 0) + weight);
  };

  // 1. Prioritize CSS Custom Properties (e.g., --primary: #..., --brand: #...)
  for (const m of allCssAndHtml.matchAll(CSS_VAR_RE)) {
    const val = m[2];
    const hexes = val.match(HEX_RE);
    if (hexes) {
      for (const h of hexes) {
        inc(categories.brand, normalizeHex(h), 10);
      }
    }
  }

  // 2. Standard Property-Value Scanning
  for (const m of allCssAndHtml.matchAll(PROP_VALUE_RE)) {
    const prop = m[1].toLowerCase().trim();
    const val = m[2];
    const hexes = val.match(HEX_RE);
    if (!hexes || hexes.length === 0) continue;

    const hex = normalizeHex(hexes[0]);

    if (prop.includes("background")) {
      inc(categories.background, hex);
    } else if (prop === "color") {
      inc(categories.text, hex);
    } else if (prop.includes("border") || prop.includes("outline")) {
      inc(categories.border, hex);
    } else if (["fill", "stroke", "accent-color"].includes(prop)) {
      inc(categories.brand, hex, 3);
    }
  }

  return categories;
}

// --------------------------------------------------------------------------
// Semantic Palette Construction
// --------------------------------------------------------------------------

function buildSemanticPalette(
  categories: ReturnType<typeof categorizeCssColors>,
  logoColors: string[]
) {
  // 1. Background Surface (MUST be light surface / near-white for inputs and cards)
  const lightBgs = [...categories.background.entries()]
    .filter(([h]) => isLightSurface(h))
    .sort((a, b) => b[1] - a[1]);
  const bgHex = lightBgs[0] ? lightBgs[0][0] : "#FFFFFF";

  // 2. Text (MUST be dark text for high contrast on light surface inputs)
  const darkTexts = [...categories.text.entries()]
    .filter(([h]) => isDarkText(h))
    .sort((a, b) => b[1] - a[1]);
  const textPrimary = darkTexts[0] ? darkTexts[0][0] : "#0F172A";

  // 3. Border (MUST be clean, subtle border for inputs and dividers)
  const cleanBorders = [...categories.border.entries()]
    .filter(([h]) => isCleanBorder(h))
    .sort((a, b) => b[1] - a[1]);
  const borderHex = cleanBorders[0] ? cleanBorders[0][0] : "#E2E8F0";

  // Brand Colors (combine logo + CSS brand/background/border/text saturated colors)
  const allCss = new Map<string, number>();
  for (const map of [categories.brand, categories.background, categories.border, categories.text]) {
    for (const [hex, count] of map.entries()) {
      allCss.set(hex, (allCss.get(hex) || 0) + count);
    }
  }

  const cssSaturated = [...allCss.entries()]
    .sort((a, b) => b[1] - a[1])
    .map(([h]) => h)
    .filter((h) => !isGrayscale(h) && !isNearWhiteOrBlack(h));

  const combined = dedupeByHue([...logoColors, ...cssSaturated]);

  let primaryColor = combined[0] ? ensureReadableContrast(combined[0]) : "#1E3A8A";
  let accentColor = combined[1] ? combined[1].toUpperCase() : "#D97706";
  let brandGold = combined[2] ? combined[2].toUpperCase() : "#F59E0B";

  // If primary and accent happen to be too similar, fallback accent to standard warm accent
  if (colorName(primaryColor) === colorName(accentColor)) {
    accentColor = "#D97706";
  }

  return {
    primary: primaryColor,
    accent: accentColor,
    brand_gold: brandGold,
    bg_white: bgHex,
    text_primary: textPrimary,
    border: borderHex,
  };
}

// --------------------------------------------------------------------------
// Main POST Handler
// --------------------------------------------------------------------------

export async function POST(req: NextRequest) {
  try {
    const body = await req.json().catch(() => ({}));
    const rawUrl = body.url || body.website;
    const agencyId = body.agency_id || body.agencyId;

    if (!rawUrl || typeof rawUrl !== "string") {
      return NextResponse.json(
        { success: false, error: "URL parametresi zorunludur." },
        { status: 400 }
      );
    }

    const { fullUrl, domain } = normalizeUrl(rawUrl);

    // 1. Fetch HTML
    let html = "";
    try {
      const fetchRes = await fetch(fullUrl, {
        signal: AbortSignal.timeout(6000),
        headers: {
          "User-Agent": USER_AGENT,
          Accept:
            "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
          "Accept-Language": "sr-RS,sr;q=0.9,en-US;q=0.8,en;q=0.7,tr;q=0.6",
        },
      });

      if (fetchRes.ok) {
        html = await fetchRes.text();
      }
    } catch (e: any) {
      console.warn("Direct site fetch warning for:", fullUrl, e.message);
    }

    // 2. Fetch External CSS in Parallel
    let externalCss = "";
    if (html) {
      externalCss = await fetchExternalCss(html, fullUrl);
    }

    const brandfetchClientId =
      body.brandfetch_client_id || body.brandfetchClientId || BRANDFETCH_CLIENT_ID;

    // 3. Logo Discovery
    let foundLogo: string | null = null;

    if (html && html.length > 0) {
      const brandKey = domain.replace(/^www\./i, "").split(".")[0].toLowerCase();
      const blacklist = [
        "nadjidom", "4zida", "imovina", "facebook", "twitter", "instagram",
        "google", "app-store", "play-store", "card", "visa",
        "mastercard", "kreditni_most", "kredit", "partner", "client", "sponsor", "favicon"
      ];

      // Priority 1: Apple Touch Icon containing brandKey (high-res mobile/webclip, excluding favicons)
      const appleIconMatch =
        html.match(/<link[^>]+rel=["']apple-touch-icon(?:-precomposed)?["'][^>]+href=["']([^"']+)["']/i) ||
        html.match(/<link[^>]+href=["']([^"']+)["'][^>]+rel=["']apple-touch-icon(?:-precomposed)?["']/i);

      if (
        appleIconMatch &&
        appleIconMatch[1] &&
        brandKey.length > 2 &&
        appleIconMatch[1].toLowerCase().includes(brandKey) &&
        !appleIconMatch[1].toLowerCase().includes("favicon")
      ) {
        foundLogo = resolveRelativeUrl(appleIconMatch[1], fullUrl);
      }

      // Priority 2: Img containing both brandKey and ("logo" or "brand") in src/alt/class
      if (!foundLogo && brandKey.length > 2) {
        const brandRegex = new RegExp(`<img[^>]+src=["']([^"']*${brandKey}[^"']*)["']`, "i");
        const brandMatch = html.match(brandRegex);
        if (brandMatch && brandMatch[1] && !blacklist.some(b => brandMatch[1].toLowerCase().includes(b))) {
          foundLogo = resolveRelativeUrl(brandMatch[1], fullUrl);
        }
      }

      // Priority 3: Link or container with "logo" containing an <img>
      if (!foundLogo) {
        const aLogoMatch = html.match(/<a[^>]+(?:class|id)=["'][^"']*logo[^"']*["'][^>]*>[\s\S]{0,500}?<img[^>]+src=["']([^"']+)["']/i);
        if (aLogoMatch && aLogoMatch[1]) {
          const candidate = aLogoMatch[1];
          if (!blacklist.some(b => candidate.toLowerCase().includes(b))) {
            foundLogo = resolveRelativeUrl(candidate, fullUrl);
          }
        }
      }

      // Priority 4: First img in <header> or <nav> with "logo" in src or class
      if (!foundLogo) {
        const headerBlock = html.match(/<(?:header|nav)[^>]*>([\s\S]*?)<\/(?:header|nav)>/i);
        if (headerBlock && headerBlock[1]) {
          const headerImgMatch = headerBlock[1].match(/<img[^>]+src=["']([^"']*logo[^"']*)["']/i) ||
                                 headerBlock[1].match(/<img[^>]+src=["']([^"']+)["']/i);
          if (headerImgMatch && headerImgMatch[1]) {
            const candidate = headerImgMatch[1];
            if (!blacklist.some(b => candidate.toLowerCase().includes(b))) {
              foundLogo = resolveRelativeUrl(candidate, fullUrl);
            }
          }
        }
      }

      // Priority 5: Brandfetch 512x512 Logo CDN (high-res brand logo before tiny icons or random page images)
      if (!foundLogo && domain) {
        foundLogo = getBrandfetchLogoUrl(domain, brandfetchClientId);
      }

      // Priority 6: Any img with "logo" in src
      if (!foundLogo) {
        const anyLogoMatches = html.matchAll(/<img[^>]+src=["']([^"']*logo[^"']*)["']/gi);
        for (const m of anyLogoMatches) {
          const src = m[1];
          if (!blacklist.some(b => src.toLowerCase().includes(b))) {
            foundLogo = resolveRelativeUrl(src, fullUrl);
            break;
          }
        }
      }

      // Priority 7: High-res Apple Touch Icon / Large Favicons
      if (!foundLogo) {
        const iconMatch =
          html.match(/<link[^>]+rel=["']apple-touch-icon(?:-precomposed)?["'][^>]+href=["']([^"']+)["']/i) ||
          html.match(/<link[^>]+href=["']([^"']+)["'][^>]+rel=["']apple-touch-icon(?:-precomposed)?["']/i) ||
          html.match(/<link[^>]+rel=["']icon["'][^>]+sizes=["'](?:192x192|512x512|180x180)["'][^>]+href=["']([^"']+)["']/i);

        if (iconMatch && iconMatch[1]) {
          foundLogo = resolveRelativeUrl(iconMatch[1], fullUrl);
        }
      }

      // Priority 8: OpenGraph Image
      if (!foundLogo) {
        const ogImageMatch =
          html.match(/<meta[^>]+property=["']og:image["'][^>]+content=["']([^"']+)["']/i) ||
          html.match(/<meta[^>]+content=["']([^"']+)["'][^>]+property=["']og:image["']/i);

        if (ogImageMatch && ogImageMatch[1]) {
          foundLogo = resolveRelativeUrl(ogImageMatch[1], fullUrl);
        }
      }
    }

    // Fallback if no on-page logo or HTML fetch was bypassed: Brandfetch Logo CDN
    if (!foundLogo && domain) {
      foundLogo = getBrandfetchLogoUrl(domain, brandfetchClientId);
    }

    // Ultimate Fallback: Google Favicon API
    if (!foundLogo) {
      foundLogo = `https://www.google.com/s2/favicons?domain=${domain}&sz=128`;
    }

    // 4. Download Logo & Extract Colors via Sharp
    let logoColors: string[] = [];
    let downloaded = false;

    const imageHeaders: Record<string, string> = {
      "User-Agent": USER_AGENT,
      Accept: "image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8",
      "Sec-Fetch-Dest": "image",
      "Sec-Fetch-Mode": "no-cors",
      "Sec-Fetch-Site": "cross-site",
      Referer: "https://www.stanomer.online/",
    };

    if (foundLogo) {
      try {
        const logoRes = await fetch(foundLogo, {
          headers: imageHeaders,
          signal: AbortSignal.timeout(4000),
        });
        if (logoRes.ok) {
          const buffer = Buffer.from(await logoRes.arrayBuffer());
          const isSvg =
            foundLogo.toLowerCase().includes(".svg") ||
            buffer.toString("utf-8", 0, 100).includes("<svg");
          logoColors = await extractLogoColors(buffer, isSvg);
          downloaded = true;
        }
      } catch (logoErr: any) {
        console.warn("Logo download or analysis note:", logoErr.message);
      }
    }

    // If initial logo candidate failed to download, try Brandfetch fallback
    const bfFallbackUrl = getBrandfetchLogoUrl(domain, brandfetchClientId);
    if (!downloaded && domain && foundLogo !== bfFallbackUrl) {
      try {
        const bfRes = await fetch(bfFallbackUrl, {
          headers: imageHeaders,
          signal: AbortSignal.timeout(4000),
        });
        if (bfRes.ok) {
          const buffer = Buffer.from(await bfRes.arrayBuffer());
          logoColors = await extractLogoColors(buffer, false);
          foundLogo = bfFallbackUrl;
          downloaded = true;
        }
      } catch (bfErr: any) {
        console.warn("Brandfetch fallback download note:", bfErr.message);
      }
    }

    // 5. Categorize CSS Colors
    const fullCssText = html + "\n" + externalCss;
    const categories = categorizeCssColors(fullCssText);

    // 6. Build Harmonious Semantic Palette
    const colorScheme = buildSemanticPalette(categories, logoColors);

    // Wrap logo with weserv for guaranteed CORS headers in Flutter Web
    const proxiedLogo = toCorsSafeUrl(foundLogo);

    // 7. Update Dev Supabase if agencyId provided
    if (agencyId) {
      try {
        const supabase = createClient(DEV_SUPABASE_URL, DEV_SUPABASE_KEY);

        // Try RPC first (SECURITY DEFINER)
        const { error: rpcErr } = await supabase.rpc("update_agency_demo_theme", {
          p_agency_id: agencyId,
          p_logo_url: proxiedLogo,
          p_website_url: fullUrl,
          p_color_scheme: colorScheme,
        });

        if (rpcErr) {
          console.warn("RPC update_agency_demo_theme note:", rpcErr.message);
          // Fallback to direct update
          await supabase
            .from("profiles")
            .update({
              logo_url: proxiedLogo,
              website_url: fullUrl,
              color_scheme: colorScheme,
              updated_at: new Date().toISOString(),
            })
            .eq("id", agencyId);
        }
      } catch (dbErr: any) {
        console.warn("Database theme update error:", dbErr.message);
      }
    }

    return NextResponse.json({
      success: true,
      logo_url: proxiedLogo,
      raw_logo_url: foundLogo,
      website_url: fullUrl,
      color_scheme: colorScheme,
      detected_logo_colors: logoColors,
    });
  } catch (error: any) {
    console.error("Scrape agency theme error:", error);
    return NextResponse.json(
      { success: false, error: error.message || "Bilinmeyen bir hata oluştu." },
      { status: 500 }
    );
  }
}

export async function GET(req: NextRequest) {
  const { searchParams } = new URL(req.url);
  const url = searchParams.get("url");
  const agencyId = searchParams.get("agency_id");

  if (!url) {
    return NextResponse.json(
      { success: false, error: "url query parametresi zorunludur." },
      { status: 400 }
    );
  }

  const fakeReq = new NextRequest(req.url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ url, agency_id: agencyId }),
  });

  return POST(fakeReq);
}
