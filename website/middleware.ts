import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";

// Main platform hostnames that should NOT be rewritten to agency showcase
const MAIN_HOSTNAMES = new Set([
  "stanomer.online",
  "www.stanomer.online",
  "stanomer.com",
  "www.stanomer.com",
  "localhost",
  "127.0.0.1",
  "0.0.0.0",
]);

// Paths that should never be rewritten (API, internal, static, etc.)
const STATIC_OR_SYSTEM_PATHS = [
  "/_next",
  "/api",
  "/images",
  "/favicon.ico",
  "/robots.txt",
  "/sitemap.xml",
  "/track",
];

export async function middleware(request: NextRequest) {
  const { pathname, searchParams } = request.nextUrl;

  // 1. Skip static assets, internal paths, and API routes
  if (STATIC_OR_SYSTEM_PATHS.some((prefix) => pathname.startsWith(prefix))) {
    return NextResponse.next();
  }

  // 2. Allow direct access to agency-panel even on custom domains
  if (pathname.startsWith("/agency-panel")) {
    return NextResponse.next();
  }

  // 3. Determine effective hostname
  // Supports local dev testing via ?__domain=kristalnekretnine.rs or x-custom-domain header
  const paramDomain = searchParams.get("__domain");
  const headerDomain = request.headers.get("x-custom-domain");
  const rawHost =
    paramDomain ||
    headerDomain ||
    request.headers.get("x-forwarded-host") ||
    request.headers.get("host") ||
    "";

  const host = rawHost.toLowerCase().replace(/:\d+$/, "").trim();

  // If host is empty or main platform host (or *.vercel.app), allow standard routing
  if (!host || MAIN_HOSTNAMES.has(host) || host.endsWith(".vercel.app")) {
    return NextResponse.next();
  }

  // 4. Resolve agency slug for this custom domain
  let agencySlug: string | null = null;

  try {
    const supabaseUrl =
      process.env.NEXT_PUBLIC_SUPABASE_URL ||
      "https://nbcbfmhztnnhfnapvaet.supabase.co";
    const supabaseAnonKey =
      process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ||
      "sb_publishable_kY2aoizXZkGz2DsG6-sg-Q_Vm2Ef2mq";

    // Clean domain for lookup (also check without www)
    const cleanHost = host.replace(/^www\./, "");

    const res = await fetch(
      `${supabaseUrl}/rest/v1/profiles?select=id,color_scheme&or=(color_scheme->>custom_domain.eq.${cleanHost},color_scheme->>custom_domain.eq.${host},color_scheme->>slug.eq.${cleanHost})&limit=1`,
      {
        headers: {
          apikey: supabaseAnonKey,
          Authorization: `Bearer ${supabaseAnonKey}`,
        },
        // Cache lookup in Next.js fetch for 30s
        next: { revalidate: 30 },
      }
    );

    if (res.ok) {
      const data = await res.json();
      if (data && data.length > 0) {
        const scheme = data[0].color_scheme;
        if (scheme?.slug) {
          agencySlug = scheme.slug;
        } else if (data[0].id) {
          agencySlug = data[0].id;
        }
      }
    }
  } catch (err) {
    console.error("Custom domain middleware lookup error:", err);
  }

  // Fallback for demo or development testing
  if (!agencySlug) {
    if (
      host === "demo.rs" ||
      host === "kristalnekretnine.rs" ||
      host.includes("demo") ||
      host.includes("kristal")
    ) {
      agencySlug = "demo";
    }
  }

  // 5. If agency slug resolved, rewrite internally to showcase
  if (agencySlug) {
    const rewriteUrl = request.nextUrl.clone();

    // If visiting the root or a sub-path that is not /agencija
    if (pathname === "/" || !pathname.startsWith("/agencija")) {
      rewriteUrl.pathname = `/agencija/${agencySlug}${pathname === "/" ? "" : pathname}`;
    }

    const response = NextResponse.rewrite(rewriteUrl);
    response.headers.set("x-stanomer-custom-domain", host);
    response.headers.set("x-stanomer-agency-slug", agencySlug);
    return response;
  }

  return NextResponse.next();
}

export const config = {
  matcher: [
    "/((?!api|_next/static|_next/image|favicon.ico|sitemap.xml|robots.txt).*)",
  ],
};

