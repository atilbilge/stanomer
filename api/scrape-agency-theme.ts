// api/scrape-agency-theme.ts
// Vercel Serverless / Edge Function for Agency Brandfetch & Theme Scraping
// Deployed automatically by Vercel under /api/scrape-agency-theme

export const config = {
  runtime: 'edge',
};

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
// URL Utilities
// --------------------------------------------------------------------------

function normalizeUrl(input: string): { fullUrl: string; domain: string; cleanDomain: string; domainWithWww: string } {
  let cleaned = input.trim();
  if (!/^https?:\/\//i.test(cleaned)) {
    cleaned = "https://" + cleaned;
  }
  let domain = "";
  try {
    const parsed = new URL(cleaned);
    domain = parsed.hostname;
  } catch {
    domain = cleaned.replace(/^https?:\/\//i, "").split("/")[0];
  }
  const cleanDomain = domain.replace(/^www\./i, "").toLowerCase();
  const domainWithWww = domain.startsWith("www.") ? domain : `www.${domain}`;

  return {
    fullUrl: `https://${domain}`,
    domain,
    cleanDomain,
    domainWithWww,
  };
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

function toCorsSafeUrl(rawUrl: string): string {
  if (!rawUrl) return "";
  // Brandfetch CDN already supports CORS natively
  if (rawUrl.includes("brandfetch.io") || rawUrl.includes("weserv.nl") || rawUrl.includes("supabase.co")) {
    return rawUrl;
  }
  const clean = rawUrl.replace(/^https?:\/\//i, "");
  return `https://images.weserv.nl/?url=${encodeURIComponent(clean)}`;
}

function getBrandfetchLogoUrl(domain: string, clientId = BRANDFETCH_CLIENT_ID): string {
  const cleanDomain = domain.replace(/^www\./i, "").toLowerCase();
  return `https://cdn.brandfetch.io/${cleanDomain}/w/512/h/512/type/logo/fallback/404?c=${clientId}`;
}

const IMAGE_FETCH_HEADERS: Record<string, string> = {
  "User-Agent": USER_AGENT,
  Accept: "image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8",
  "Sec-Fetch-Dest": "image",
  "Sec-Fetch-Mode": "no-cors",
  "Sec-Fetch-Site": "cross-site",
  Referer: "https://www.stanomer.online/",
};

// --------------------------------------------------------------------------
// Color Science Utilities (Pure JS / No Sharp dependency for Edge Runtime)
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
  return s <= 0.08 && v >= 0.92;
}

function isDarkText(hex: string): boolean {
  const [r, g, b] = hexToRgb(hex);
  const [, s, v] = rgbToHsv(r, g, b);
  return v <= 0.35 && s <= 0.40;
}

function isCleanBorder(hex: string): boolean {
  const [r, g, b] = hexToRgb(hex);
  const [, s, v] = rgbToHsv(r, g, b);
  return s <= 0.15 && v >= 0.75 && v <= 0.94;
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

function colorName(hex: string): string {
  const [r, g, b] = hexToRgb(hex);
  const [h, s, v] = rgbToHsv(r, g, b);

  if (v < 0.12) return "black";
  if (s < 0.08 && v > 0.9) return "white";
  if (s < 0.12) return "gray";

  const deg = h * 360;
  const buckets: [number, string][] = [
    [15, "red"],
    [35, "orange"],
    [55, "gold"],
    [70, "yellow"],
    [150, "green"],
    [190, "teal"],
    [250, "blue"],
    [290, "purple"],
    [345, "pink"],
    [360, "red"],
  ];
  for (const [limit, name] of buckets) {
    if (deg <= limit) return name;
  }
  return "blue";
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

function ensureReadableContrast(hex: string): string {
  const [r, g, b] = hexToRgb(hex);
  const [h, s, v] = rgbToHsv(r, g, b);
  if (v > 0.85) {
    const newV = 0.72;
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

  for (const m of allCssAndHtml.matchAll(CSS_VAR_RE)) {
    const val = m[2];
    const hexes = val.match(HEX_RE);
    if (hexes) {
      for (const h of hexes) {
        inc(categories.brand, normalizeHex(h), 10);
      }
    }
  }

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

function buildSemanticPalette(
  categories: ReturnType<typeof categorizeCssColors>,
  extractedBrandColors: string[]
) {
  const lightBgs = [...categories.background.entries()]
    .filter(([h]) => isLightSurface(h))
    .sort((a, b) => b[1] - a[1]);
  const bgHex = lightBgs[0] ? lightBgs[0][0] : "#FFFFFF";

  const darkTexts = [...categories.text.entries()]
    .filter(([h]) => isDarkText(h))
    .sort((a, b) => b[1] - a[1]);
  const textPrimary = darkTexts[0] ? darkTexts[0][0] : "#0F172A";

  const cleanBorders = [...categories.border.entries()]
    .filter(([h]) => isCleanBorder(h))
    .sort((a, b) => b[1] - a[1]);
  const borderHex = cleanBorders[0] ? cleanBorders[0][0] : "#E2E8F0";

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

  const combined = dedupeByHue([...extractedBrandColors, ...cssSaturated]);

  let primaryColor = combined[0] ? ensureReadableContrast(combined[0]) : "#1E3A8A";
  let accentColor = combined[1] ? combined[1].toUpperCase() : "#D97706";
  let brandGold = combined[2] ? combined[2].toUpperCase() : "#F59E0B";

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
// External CSS Fetcher
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
      if (cssUrls.length >= 4) break;
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
// Core Handler
// --------------------------------------------------------------------------

export async function handler(req: Request) {
  const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Authorization",
    "Content-Type": "application/json",
  };

  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ success: false, error: "Only POST method is allowed." }),
      { status: 405, headers: corsHeaders }
    );
  }

  try {
    const body = await req.json().catch(() => ({}));
    const rawUrl = body.url || body.website;
    const agencyId = body.agency_id || body.agencyId;

    if (!rawUrl || typeof rawUrl !== "string") {
      return new Response(
        JSON.stringify({ success: false, error: "URL parameter is required." }),
        { status: 400, headers: corsHeaders }
      );
    }

    const { fullUrl, domain, cleanDomain, domainWithWww } = normalizeUrl(rawUrl);

    // 1. Fetch Target Website HTML
    let html = "";
    let finalBaseUrl = fullUrl;

    // Try www first if apex, or original fullUrl
    const urlsToTry = [
      fullUrl,
      `https://${domainWithWww}`,
      `http://${domain}`,
    ];

    for (const testUrl of urlsToTry) {
      try {
        const fetchRes = await fetch(testUrl, {
          signal: AbortSignal.timeout(4500),
          headers: {
            "User-Agent": USER_AGENT,
            Accept: "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language": "sr-RS,sr;q=0.9,en-US;q=0.8,en;q=0.7,tr;q=0.6",
          },
        });
        if (fetchRes.ok) {
          html = await fetchRes.text();
          finalBaseUrl = testUrl;
          break;
        }
      } catch {
        // Try next candidate
      }
    }

    // 2. Fetch External CSS
    let externalCss = "";
    if (html) {
      externalCss = await fetchExternalCss(html, finalBaseUrl);
    }

    const brandfetchClientId =
      body.brandfetch_client_id || body.brandfetchClientId || BRANDFETCH_CLIENT_ID;

    // 3. LOGO RESOLUTION HIERARCHY:
    //    Priority 1: Web Site HTML / Header / Brand / Apple-Touch-Icon
    //    Priority 2: Brandfetch CDN (512x512)
    //    Priority 3: Google S2 Favicon (with www normalization and weserv proxy)

    let foundLogo: string | null = null;
    let logoSource: "website_html" | "brandfetch" | "google_favicon" = "google_favicon";

    // ── PRIORITY 1: Web Site HTML Search ──────────────────────────────────────
    if (html && html.length > 0) {
      const brandKey = cleanDomain.split(".")[0].toLowerCase();
      const blacklist = [
        "nadjidom", "4zida", "imovina", "facebook", "twitter", "instagram",
        "google", "app-store", "play-store", "card", "visa",
        "mastercard", "kreditni_most", "kredit", "partner", "client", "sponsor", "favicon"
      ];

      // P1.1: Apple Touch Icon with brandKey
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
        foundLogo = resolveRelativeUrl(appleIconMatch[1], finalBaseUrl);
      }

      // P1.2: Img containing brandKey
      if (!foundLogo && brandKey.length > 2) {
        const brandRegex = new RegExp(`<img[^>]+src=["']([^"']*${brandKey}[^"']*)["']`, "i");
        const brandMatch = html.match(brandRegex);
        if (brandMatch && brandMatch[1] && !blacklist.some(b => brandMatch[1].toLowerCase().includes(b))) {
          foundLogo = resolveRelativeUrl(brandMatch[1], finalBaseUrl);
        }
      }

      // P1.3: Link or element with "logo" containing <img>
      if (!foundLogo) {
        const aLogoMatch = html.match(/<a[^>]+(?:class|id)=["'][^"']*logo[^"']*["'][^>]*>[\s\S]{0,500}?<img[^>]+src=["']([^"']+)["']/i);
        if (aLogoMatch && aLogoMatch[1]) {
          const candidate = aLogoMatch[1];
          if (!blacklist.some(b => candidate.toLowerCase().includes(b))) {
            foundLogo = resolveRelativeUrl(candidate, finalBaseUrl);
          }
        }
      }

      // P1.4: First img in <header> or <nav>
      if (!foundLogo) {
        const headerBlock = html.match(/<(?:header|nav)[^>]*>([\s\S]*?)<\/(?:header|nav)>/i);
        if (headerBlock && headerBlock[1]) {
          const headerImgMatch = headerBlock[1].match(/<img[^>]+src=["']([^"']*logo[^"']*)["']/i) ||
                                 headerBlock[1].match(/<img[^>]+src=["']([^"']+)["']/i);
          if (headerImgMatch && headerImgMatch[1]) {
            const candidate = headerImgMatch[1];
            if (!blacklist.some(b => candidate.toLowerCase().includes(b))) {
              foundLogo = resolveRelativeUrl(candidate, finalBaseUrl);
            }
          }
        }
      }

      // P1.5: Any img with "logo" in src
      if (!foundLogo) {
        const anyLogoMatches = html.matchAll(/<img[^>]+src=["']([^"']*logo[^"']*)["']/gi);
        for (const m of anyLogoMatches) {
          const src = m[1];
          if (!blacklist.some(b => src.toLowerCase().includes(b))) {
            foundLogo = resolveRelativeUrl(src, finalBaseUrl);
            break;
          }
        }
      }

      // Verify on-page logo reachable
      if (foundLogo) {
        try {
          const probe = await fetch(foundLogo, {
            headers: IMAGE_FETCH_HEADERS,
            signal: AbortSignal.timeout(3000),
          });
          if (probe.ok && probe.status === 200) {
            logoSource = "website_html";
          } else {
            // Hotlink protected or failed, keep foundLogo but wrap with weserv
            logoSource = "website_html";
          }
        } catch {
          // Still use foundLogo via weserv proxy
          logoSource = "website_html";
        }
      }
    }

    // ── PRIORITY 2: Brandfetch CDN (512x512) ─────────────────────────────────
    if (!foundLogo && cleanDomain) {
      const bfUrl = getBrandfetchLogoUrl(cleanDomain, brandfetchClientId);
      try {
        const bfRes = await fetch(bfUrl, {
          headers: IMAGE_FETCH_HEADERS,
          signal: AbortSignal.timeout(3500),
        });
        if (bfRes.ok && bfRes.status === 200) {
          foundLogo = bfUrl;
          logoSource = "brandfetch";
        }
      } catch (bfErr: any) {
        console.warn("Brandfetch probe note:", bfErr.message);
      }
    }

    // ── PRIORITY 3: Google S2 Favicon (Final Safe Fallback) ───────────────────
    if (!foundLogo) {
      // Use domainWithWww to prevent apex domain redirect loops
      foundLogo = `https://www.google.com/s2/favicons?domain=${encodeURIComponent(domainWithWww)}&sz=128`;
      logoSource = "google_favicon";
    }

    // Proxy harici logolar (Brandfetch hariç) weserv üzerinden CORS-safe yapılır
    const proxiedLogo = toCorsSafeUrl(foundLogo);

    // 4. Color Extraction & Palette Construction
    const allCss = `${html}\n${externalCss}`;
    const categories = categorizeCssColors(allCss);

    // Also look for inline SVG colors if any
    const svgColors: string[] = [];
    if (html.includes("<svg")) {
      const svgMatches = [...html.matchAll(/(?:fill|stroke|stop-color)=["'](#[0-9a-fA-F]{3,6})["']/gi)].map(m => m[1]);
      for (const h of svgMatches) {
        if (!isGrayscale(h) && !isNearWhiteOrBlack(h)) {
          svgColors.push(normalizeHex(h));
        }
      }
    }

    const colorScheme = buildSemanticPalette(categories, svgColors);

    // 5. If agency_id provided, update Dev Supabase profiles
    if (agencyId) {
      try {
        await fetch(`${DEV_SUPABASE_URL}/rest/v1/profiles?id=eq.${agencyId}`, {
          method: "PATCH",
          headers: {
            "Content-Type": "application/json",
            apikey: DEV_SUPABASE_KEY,
            Authorization: `Bearer ${DEV_SUPABASE_KEY}`,
          },
          body: JSON.stringify({
            logo_url: proxiedLogo,
            website_url: `https://${domainWithWww}`,
            color_scheme: colorScheme,
            updated_at: new Date().toISOString(),
          }),
        });
      } catch (dbErr: any) {
        console.warn("Supabase profile update note:", dbErr.message);
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        logo_url: proxiedLogo,
        raw_logo_url: foundLogo,
        logo_source: logoSource,
        website_url: `https://${domainWithWww}`,
        color_scheme: colorScheme,
        detected_logo_colors: [
          colorScheme.primary,
          colorScheme.accent,
          colorScheme.brand_gold,
        ],
      }),
      { status: 200, headers: corsHeaders }
    );
  } catch (error: any) {
    console.error("Scraper handler error:", error);
    return new Response(
      JSON.stringify({ success: false, error: error.message || "Internal server error" }),
      { status: 500, headers: corsHeaders }
    );
  }
}

export { handler as POST };
export default handler;
