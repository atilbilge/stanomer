import { NextResponse } from "next/server";
import { supabase } from "../../../lib/supabaseClient";

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { email, lang } = body;

    if (!email?.trim()) {
      return NextResponse.json(
        { success: false, message: "Lütfen bir e-posta adresi giriniz." },
        { status: 400 }
      );
    }

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email.trim())) {
      return NextResponse.json(
        { success: false, message: "Geçerli bir e-posta adresi giriniz." },
        { status: 400 }
      );
    }

    const cleanEmail = email.trim().toLowerCase();

    // Query partner strictly by email
    const { data: existingPartners, error: searchError } = await supabase
      .from("agency_referral_partners")
      .select("*")
      .ilike("email", cleanEmail)
      .limit(1);

    if (searchError) {
      console.error("Supabase agency lookup error:", searchError);
      return NextResponse.json(
        { success: false, message: "Veritabanı sorgu hatası." },
        { status: 500 }
      );
    }

    if (!existingPartners || existingPartners.length === 0) {
      return NextResponse.json(
        { success: false, notFound: true, message: "Bu e-posta adresine ait kayıtlı bir acente bulunamadı." },
        { status: 404 }
      );
    }

    const partner = existingPartners[0];
    const code = partner.referral_code || partner.slug;
    const slug = partner.slug;

    // Calculate referral stats
    let totalReferred = 0;
    let landlordCount = 0;
    let tenantCount = 0;

    try {
      const { count: total } = await supabase
        .from("profiles")
        .select("*", { count: "exact", head: true })
        .or(`referred_by_agency_code.ilike.${code},referred_by_agency_code.ilike.${slug}`);

      const { count: landlords } = await supabase
        .from("profiles")
        .select("*", { count: "exact", head: true })
        .eq("role", "landlord")
        .or(`referred_by_agency_code.ilike.${code},referred_by_agency_code.ilike.${slug}`);

      const { count: tenants } = await supabase
        .from("profiles")
        .select("*", { count: "exact", head: true })
        .eq("role", "tenant")
        .or(`referred_by_agency_code.ilike.${code},referred_by_agency_code.ilike.${slug}`);

      totalReferred = total || 0;
      landlordCount = landlords || 0;
      tenantCount = tenants || 0;
    } catch (e) {
      console.warn("Lookup stats calculation error:", e);
    }

    return NextResponse.json({
      success: true,
      isExisting: true,
      partner,
      stats: {
        totalReferred,
        landlordCount,
        tenantCount
      }
    });

  } catch (error: any) {
    console.error("Lookup Referral Agency Error:", error);
    return NextResponse.json(
      { success: false, message: error.message || "Sunucu hatası oluştu." },
      { status: 500 }
    );
  }
}
