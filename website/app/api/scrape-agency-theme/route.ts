import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@supabase/supabase-js";

const DEV_SUPABASE_URL = "https://thvbpifahvasyzmngpzp.supabase.co";
const DEV_SUPABASE_KEY =
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRodmJwaWZhaHZhc3l6bW5ncHpwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODUyNjAxNzcsImV4cCI6MjEwMDgzNjE3N30.dNSz66kJcoSjflgCCrS7qw55efuDxF61TEMoYc3r4qU";

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

function toCorsSafeUrl(rawUrl: string): string {
  if (!rawUrl) return "";
  if (rawUrl.includes("weserv.nl")) return rawUrl;
  const clean = rawUrl.replace(/^https?:\/\//i, "");
  return `https://images.weserv.nl/?url=${encodeURIComponent(clean)}`;
}

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

    let html = "";
    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 7000);

      const fetchRes = await fetch(fullUrl, {
        signal: controller.signal,
        headers: {
          "User-Agent":
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36",
          Accept:
            "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
          "Accept-Language": "sr-RS,sr;q=0.9,en-US;q=0.8,en;q=0.7,tr;q=0.6",
        },
      });
      clearTimeout(timeoutId);

      if (fetchRes.ok) {
        html = await fetchRes.text();
      }
    } catch (e: any) {
      console.warn("Direct site fetch warning for:", fullUrl, e.message);
    }

    let foundLogo: string | null = null;
    let themeColor: string | null = null;

    if (html && html.length > 0) {
      // 1. Theme color extraction
      const themeColorMatch = html.match(
        /<meta[^>]+name=["']theme-color["'][^>]+content=["']([^"']+)["']/i
      );
      if (themeColorMatch && themeColorMatch[1]) {
        themeColor = themeColorMatch[1].trim();
      }

      const brandKey = domain.replace(/^www\./i, "").split(".")[0].toLowerCase();
      const blacklist = ["nadjidom", "4zida", "imovina", "facebook", "twitter", "instagram", "google", "app-store", "play-store", "apple", "card", "visa", "mastercard", "kreditni_most", "kredit", "partner", "client", "sponsor"];

      // Priority 1: Apple Touch Icon or Webclip containing brandKey
      const appleIconMatch =
        html.match(/<link[^>]+rel=["']apple-touch-icon(?:-precomposed)?["'][^>]+href=["']([^"']+)["']/i) ||
        html.match(/<link[^>]+href=["']([^"']+)["'][^>]+rel=["']apple-touch-icon(?:-precomposed)?["']/i) ||
        html.match(/<link[^>]+rel=["'](?:shortcut )?icon["'][^>]+href=["']([^"']+)["']/i);

      if (appleIconMatch && appleIconMatch[1] && brandKey.length > 2 && appleIconMatch[1].toLowerCase().includes(brandKey)) {
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

      // Priority 5: Fallback to apple-touch-icon / high-res icons if available
      if (!foundLogo && appleIconMatch && appleIconMatch[1]) {
        foundLogo = resolveRelativeUrl(appleIconMatch[1], fullUrl);
      }

      // Priority 4: Any img with "logo" in src
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

      // 3. High-res Apple Touch Icon / Large Favicons
      if (!foundLogo) {
        const appleIconMatch =
          html.match(/<link[^>]+rel=["']apple-touch-icon(?:-precomposed)?["'][^>]+href=["']([^"']+)["']/i) ||
          html.match(/<link[^>]+href=["']([^"']+)["'][^>]+rel=["']apple-touch-icon(?:-precomposed)?["']/i) ||
          html.match(/<link[^>]+rel=["']icon["'][^>]+sizes=["'](?:192x192|512x512|180x180)["'][^>]+href=["']([^"']+)["']/i);

        if (appleIconMatch && appleIconMatch[1]) {
          foundLogo = resolveRelativeUrl(appleIconMatch[1], fullUrl);
        }
      }

      // 4. OpenGraph Image
      if (!foundLogo) {
        const ogImageMatch =
          html.match(/<meta[^>]+property=["']og:image["'][^>]+content=["']([^"']+)["']/i) ||
          html.match(/<meta[^>]+content=["']([^"']+)["'][^>]+property=["']og:image["']/i);

        if (ogImageMatch && ogImageMatch[1]) {
          foundLogo = resolveRelativeUrl(ogImageMatch[1], fullUrl);
        }
      }
    }

    // 5. Ultimate Fallback: Google Favicon API (Proxied via weserv to ensure CORS)
    if (!foundLogo) {
      foundLogo = `https://www.google.com/s2/favicons?domain=${domain}&sz=128`;
    }

    // Wrap with weserv for guaranteed CORS headers in Flutter Web
    const proxiedLogo = toCorsSafeUrl(foundLogo);

    // Harmonious color palette based on extracted theme color or classical real estate deep blue
    const primaryColor =
      themeColor && /^#[0-9A-Fa-f]{6}$/.test(themeColor) ? themeColor : "#1E3A8A";
    const colorScheme = {
      primary: primaryColor,
      accent: "#D97706",
      brand_gold: "#F59E0B",
      bg_white: "#FFFFFF",
      text_primary: "#0F172A",
      border: "#E2E8F0",
    };

    // If agencyId is provided, update database
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
