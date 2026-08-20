import { NextResponse } from "next/server";
import crypto from "crypto";
import { supabase } from "../../../../lib/supabaseClient";

export const dynamic = "force-dynamic";

export async function GET(request: Request) {
  try {
    const cookieHeader = request.headers.get("cookie") || "";
    const sessionCookieMatch = cookieHeader.match(/agency_stats_session=([^;]+)/);

    if (!sessionCookieMatch) {
      return NextResponse.json(
        { success: false, message: "Oturum bulunamadı. Lütfen giriş yapın." },
        { status: 401 }
      );
    }

    const token = sessionCookieMatch[1];
    const parts = token.split(".");
    if (parts.length !== 2) {
      return NextResponse.json(
        { success: false, message: "Geçersiz oturum." },
        { status: 401 }
      );
    }

    const [payloadBase64, signature] = parts;
    const secret = process.env.SESSION_SECRET || "stanomer-agency-stats-secret-key-2026";
    const expectedSignature = crypto.createHmac("sha256", secret).update(payloadBase64).digest("base64url");

    if (signature !== expectedSignature) {
      return NextResponse.json(
        { success: false, message: "Oturum imzası geçersiz." },
        { status: 401 }
      );
    }

    const payload = JSON.parse(Buffer.from(payloadBase64, "base64url").toString("utf-8"));
    if (!payload.exp || payload.exp < Math.floor(Date.now() / 1000)) {
      return NextResponse.json(
        { success: false, message: "Oturum süreniz doldu. Lütfen tekrar giriş yapın." },
        { status: 401 }
      );
    }

    // Partner details
    const { data: partners } = await supabase
      .from("agency_referral_partners")
      .select("*")
      .eq("id", payload.partnerId)
      .limit(1);

    if (!partners || partners.length === 0) {
      return NextResponse.json(
        { success: false, message: "Acente kaydı bulunamadı." },
        { status: 404 }
      );
    }

    const partner = partners[0];
    const code = partner.referral_code || partner.slug;
    const slug = partner.slug || "";
    const cleanSlug = slug.split("-")[0] || slug;

    // Build comprehensive OR conditions to catch exact, slug, referral_code, and partial matches
    const matchConditions = [
      `referred_by_agency_code.ilike.${code}`,
      `referred_by_agency_code.ilike.${slug}`,
      `referred_by_agency_code.ilike.%${slug}%`,
      `referred_by_agency_code.ilike.%${code}%`
    ];

    if (cleanSlug && cleanSlug.length >= 3) {
      matchConditions.push(`referred_by_agency_code.ilike.%${cleanSlug}%`);
    }

    const orFilter = matchConditions.join(",");

    // 1. Total referred counts (AGGREGATE ONLY - NO PII)
    const { count: totalReferred } = await supabase
      .from("profiles")
      .select("*", { count: "exact", head: true })
      .or(orFilter);

    const { count: landlordCount } = await supabase
      .from("profiles")
      .select("*", { count: "exact", head: true })
      .eq("role", "landlord")
      .or(orFilter);

    const { count: tenantCount } = await supabase
      .from("profiles")
      .select("*", { count: "exact", head: true })
      .eq("role", "tenant")
      .or(orFilter);

    // 2. Time-Based Trend (Last 12 Weeks / 90 Days Aggregate)
    const { data: trendProfiles } = await supabase
      .from("profiles")
      .select("created_at")
      .or(orFilter)
      .order("created_at", { ascending: true });

    // Group referrals by month / week
    const now = new Date();
    const trendMap: Record<string, number> = {};

    // Generate last 6 months buckets
    for (let i = 5; i >= 0; i--) {
      const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
      const monthLabel = d.toLocaleString("tr-TR", { month: "short", year: "2-digit" });
      trendMap[monthLabel] = 0;
    }

    if (trendProfiles) {
      for (const p of trendProfiles) {
        if (p.created_at) {
          const d = new Date(p.created_at);
          const monthLabel = d.toLocaleString("tr-TR", { month: "short", year: "2-digit" });
          if (trendMap[monthLabel] !== undefined) {
            trendMap[monthLabel] += 1;
          }
        }
      }
    }

    const trend = Object.entries(trendMap).map(([label, count]) => ({
      label,
      count
    }));

    return NextResponse.json({
      success: true,
      partner: {
        id: partner.id,
        agency_name: partner.agency_name,
        contact_name: partner.contact_name,
        email: partner.email,
        slug: partner.slug,
        referral_code: partner.referral_code,
        city: partner.city
      },
      stats: {
        totalReferred: totalReferred || 0,
        landlordCount: landlordCount || 0,
        tenantCount: tenantCount || 0
      },
      trend
    });

  } catch (error: any) {
    console.error("Agency Dashboard API Error:", error);
    return NextResponse.json(
      { success: false, message: "Sunucu hatası oluştu." },
      { status: 500 }
    );
  }
}
