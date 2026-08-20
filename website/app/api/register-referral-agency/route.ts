import { NextResponse } from "next/server";
import { supabase } from "../../../lib/supabaseClient";

function slugify(text: string): string {
  const map: Record<string, string> = {
    ç: "c", Ç: "c", ğ: "g", Ğ: "g", ı: "i", İ: "i",
    ö: "o", Ö: "o", ş: "s", Ş: "s", ü: "u", Ü: "u",
    č: "c", Č: "c", ć: "c", Ć: "c", đ: "dj", Đ: "dj",
    š: "s", Š: "s", ž: "z", Ž: "z"
  };

  const converted = text
    .split("")
    .map((char) => map[char] || char)
    .join("");

  return converted
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9\s-]/g, "")
    .replace(/[\s_]+/g, "-")
    .replace(/-+/g, "-")
    .replace(/^-+|-+$/g, "");
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const {
      agencyName,
      contactName,
      email,
      phone,
      city,
      website,
      agencySize,
      referralSource,
      lang
    } = body;

    // Validate required fields
    if (!agencyName?.trim() || !contactName?.trim() || !email?.trim() || !city?.trim()) {
      return NextResponse.json(
        { success: false, message: "Lütfen tüm zorunlu alanları doldurunuz." },
        { status: 400 }
      );
    }

    // Basic email format validation
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email.trim())) {
      return NextResponse.json(
        { success: false, message: "Geçerli bir e-posta adresi giriniz." },
        { status: 400 }
      );
    }

    const cleanEmail = email.trim().toLowerCase();
    const cleanAgencyName = agencyName.trim();

    async function getReferralStats(code: string, slug: string) {
      try {
        const { count: totalReferred } = await supabase
          .from("profiles")
          .select("*", { count: "exact", head: true })
          .or(`referred_by_agency_code.ilike.${code},referred_by_agency_code.ilike.${slug}`);

        const { count: landlordCount } = await supabase
          .from("profiles")
          .select("*", { count: "exact", head: true })
          .eq("role", "landlord")
          .or(`referred_by_agency_code.ilike.${code},referred_by_agency_code.ilike.${slug}`);

        const { count: tenantCount } = await supabase
          .from("profiles")
          .select("*", { count: "exact", head: true })
          .eq("role", "tenant")
          .or(`referred_by_agency_code.ilike.${code},referred_by_agency_code.ilike.${slug}`);

        return {
          totalReferred: totalReferred || 0,
          landlordCount: landlordCount || 0,
          tenantCount: tenantCount || 0
        };
      } catch (e) {
        console.warn("Error calculating referral stats:", e);
        return { totalReferred: 0, landlordCount: 0, tenantCount: 0 };
      }
    }

    // 1. Idempotency Check: check if partner already exists by email or agency_name
    try {
      const { data: existingPartners, error: searchError } = await supabase
        .from("agency_referral_partners")
        .select("*")
        .or(`email.ilike.${cleanEmail},agency_name.ilike.${cleanAgencyName}`)
        .limit(1);

      if (!searchError && existingPartners && existingPartners.length > 0) {
        const existing = existingPartners[0];
        const stats = await getReferralStats(existing.referral_code || existing.slug, existing.slug);
        
        // Trigger email notification for existing partner
        try {
          const origin = request.headers.get("origin") || request.headers.get("referer") || "https://stanomer.online";
          await fetch(`${origin.replace(/\/$/, "")}/api/send-referral-qr`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
              email: existing.email,
              agencyName: existing.agency_name,
              slug: existing.slug,
              referralCode: existing.referral_code,
              lang: lang || "TR"
            })
          });
        } catch (e) {
          console.error("Existing partner QR email trigger error:", e);
        }

        return NextResponse.json({
          success: true,
          isExisting: true,
          partner: existing,
          stats
        });
      }
    } catch (e) {
      console.warn("Database lookup warning:", e);
    }

    // 2. Slug Generation (Format compatible with app deeplink: agency_ref_{slug})
    let rawSlug = slugify(cleanAgencyName) || "acente";
    let baseSlug = rawSlug.startsWith("agency_ref_") ? rawSlug : `agency_ref_${rawSlug}`;
    let candidateSlug = baseSlug;
    let counter = 2;

    // Check slug collision
    try {
      let isUnique = false;
      while (!isUnique && counter < 50) {
        const { data: slugCheck } = await supabase
          .from("agency_referral_partners")
          .select("id")
          .eq("slug", candidateSlug)
          .limit(1);

        if (slugCheck && slugCheck.length > 0) {
          candidateSlug = `${baseSlug}-${counter}`;
          counter++;
        } else {
          isUnique = true;
        }
      }
    } catch (e) {
      console.warn("Slug uniqueness check fallback:", e);
    }

    const referralCode = candidateSlug;

    let formattedWebsite: string | null = null;
    if (website?.trim()) {
      const trimmedWebsite = website.trim();
      formattedWebsite = /^https?:\/\//i.test(trimmedWebsite) ? trimmedWebsite : `https://${trimmedWebsite}`;
    }

    const newPartnerData = {
      agency_name: cleanAgencyName,
      contact_name: contactName.trim(),
      email: cleanEmail,
      phone: phone?.trim() || "-",
      city: city.trim(),
      website: formattedWebsite,
      agency_size: agencySize || null,
      referral_source: referralSource || null,
      slug: candidateSlug,
      referral_code: referralCode
    };

    // 3. Save to Supabase DB with Unique Constraint Race Condition Handling
    let createdPartner = {
      ...newPartnerData,
      id: crypto.randomUUID(),
      created_at: new Date().toISOString()
    };
    let isExistingRecord = false;

    try {
      const { data: dbData, error: dbError } = await supabase
        .from("agency_referral_partners")
        .insert([newPartnerData])
        .select()
        .single();

      if (!dbError && dbData) {
        createdPartner = dbData;
      } else if (dbError) {
        console.warn("Supabase insert response:", dbError.code, dbError.message);
        
        // Handle race condition or unique constraint violation (PostgreSQL 23505)
        if (dbError.code === "23505" || dbError.message?.toLowerCase().includes("duplicate") || dbError.message?.toLowerCase().includes("unique")) {
          const { data: existingRacePartner } = await supabase
            .from("agency_referral_partners")
            .select("*")
            .ilike("email", cleanEmail)
            .limit(1);

          if (existingRacePartner && existingRacePartner.length > 0) {
            createdPartner = existingRacePartner[0];
            isExistingRecord = true;
          }
        }
      }
    } catch (e) {
      console.warn("Supabase insert exception (using fallback):", e);
    }

    const stats = await getReferralStats(createdPartner.referral_code || createdPartner.slug, createdPartner.slug);

    // 4. Trigger Email dispatch with Brevo
    try {
      const origin = request.headers.get("origin") || request.headers.get("referer") || "https://stanomer.online";
      await fetch(`${origin.replace(/\/$/, "")}/api/send-referral-qr`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          email: createdPartner.email,
          agencyName: createdPartner.agency_name,
          slug: createdPartner.slug,
          referralCode: createdPartner.referral_code,
          lang: lang || "TR"
        })
      });
    } catch (e) {
      console.error("QR email trigger error:", e);
    }

    return NextResponse.json({
      success: true,
      isExisting: isExistingRecord,
      partner: createdPartner,
      stats
    });

  } catch (error: any) {
    console.error("Register Referral Agency Error:", error);
    return NextResponse.json(
      { success: false, message: error.message || "Sunucu hatası oluştu." },
      { status: 500 }
    );
  }
}
