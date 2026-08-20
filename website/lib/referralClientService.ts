import { supabase } from "./supabaseClient";

export interface ReferralPartner {
  id: string;
  agency_name: string;
  contact_name?: string | null;
  email: string;
  phone?: string | null;
  city: string;
  website?: string | null;
  agency_size?: string | null;
  referral_source?: string | null;
  slug: string;
  referral_code: string;
  created_at: string;
}

const BREVO_API_KEY =
  process.env.NEXT_PUBLIC_BREVO_API_KEY ||
  process.env.BREVO_API_KEY ||
  "";
const BREVO_SENDER_EMAIL =
  process.env.NEXT_PUBLIC_BREVO_SENDER_EMAIL ||
  process.env.BREVO_SENDER_EMAIL ||
  "atilbilge@gmail.com";
const BREVO_SENDER_NAME =
  process.env.NEXT_PUBLIC_BREVO_SENDER_NAME ||
  process.env.BREVO_SENDER_NAME ||
  "Stanomer";

function generateSlug(name: string): string {
  const trMap: Record<string, string> = {
    ç: "c", Ç: "c", ğ: "g", Ğ: "g", ı: "i", İ: "i", ö: "o", Ö: "o", ş: "s", Ş: "s", ü: "u", Ü: "u",
    č: "c", Č: "c", ć: "c", Ć: "c", đ: "dj", Đ: "dj", š: "s", Š: "s", ž: "z", Ž: "z"
  };
  let clean = name.trim().toLowerCase();
  for (const [k, v] of Object.entries(trMap)) {
    clean = clean.split(k).join(v);
  }
  return clean
    .replace(/[^a-z0-9\s-]/g, "")
    .replace(/\s+/g, "-")
    .replace(/-+/g, "-")
    .replace(/^-+|-+$/g, "") || "agency";
}

async function sha256Hex(text: string): Promise<string> {
  const enc = new TextEncoder();
  const hashBuf = await crypto.subtle.digest("SHA-256", enc.encode(text));
  const hashArray = Array.from(new Uint8Array(hashBuf));
  return hashArray.map(b => b.toString(16).padStart(2, "0")).join("");
}

export async function registerReferralAgency(formData: {
  agencyName: string;
  contactName: string;
  email: string;
  phone?: string;
  city: string;
  website?: string;
  agencySize?: string;
  referralSource?: string;
  lang?: string;
}): Promise<{
  success: boolean;
  partner?: ReferralPartner;
  isExisting?: boolean;
  stats?: { totalReferred: number; landlordCount: number; tenantCount: number };
  message?: string;
}> {
  // 1. Try Next.js API Route first
  try {
    const res = await fetch("/api/register-referral-agency", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(formData)
    });
    if (res.ok) {
      const data = await res.json();
      if (data.success && data.partner) {
        return data;
      }
    }
  } catch (err) {
    console.warn("API route unavailable, falling back to direct Supabase client:", err);
  }

  // 2. Client-side direct Supabase fallback
  try {
    const cleanEmail = formData.email.trim().toLowerCase();
    const cleanAgencyName = formData.agencyName.trim();

    // Check if email exists
    const { data: existing } = await supabase
      .from("agency_referral_partners")
      .select("*")
      .ilike("email", cleanEmail)
      .limit(1);

    if (existing && existing.length > 0) {
      const partner = existing[0] as ReferralPartner;
      return { success: true, partner, isExisting: true };
    }

    // Generate unique slug
    const baseSlug = generateSlug(cleanAgencyName);
    let candidateSlug = baseSlug;
    let counter = 2;
    let isUnique = false;

    while (!isUnique && counter <= 20) {
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

    let formattedWebsite: string | null = null;
    if (formData.website?.trim()) {
      const w = formData.website.trim();
      formattedWebsite = /^https?:\/\//i.test(w) ? w : `https://${w}`;
    }

    const newPartnerData = {
      agency_name: cleanAgencyName,
      contact_name: formData.contactName.trim(),
      email: cleanEmail,
      phone: formData.phone?.trim() || "-",
      city: formData.city.trim(),
      website: formattedWebsite,
      agency_size: formData.agencySize || null,
      referral_source: formData.referralSource || null,
      slug: candidateSlug,
      referral_code: candidateSlug
    };

    const { data: dbData, error: dbError } = await supabase
      .from("agency_referral_partners")
      .insert([newPartnerData])
      .select()
      .single();

    if (dbError || !dbData) {
      throw new Error(dbError?.message || "Veritabanı kaydı oluşturulamadı.");
    }

    const partner = dbData as ReferralPartner;

    // Send welcome QR email via Brevo
    sendReferralQrEmail(partner, formData.lang || "TR").catch((e) =>
      console.warn("Background Brevo email send warning:", e)
    );

    return { success: true, partner, isExisting: false };
  } catch (error: any) {
    console.error("Direct registration error:", error);
    return {
      success: false,
      message: error?.message || "Kayıt sırasında bir hata oluştu. Lütfen tekrar deneyiniz."
    };
  }
}

export async function lookupReferralAgency(
  email: string,
  lang: string = "TR"
): Promise<{
  success: boolean;
  partner?: ReferralPartner;
  stats?: { totalReferred: number; landlordCount: number; tenantCount: number };
  message?: string;
}> {
  // 1. Try Next.js API Route first
  try {
    const res = await fetch("/api/lookup-referral-agency", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email, lang })
    });
    if (res.ok) {
      const data = await res.json();
      if (data.success && data.partner) {
        return data;
      }
    }
  } catch (err) {
    console.warn("API route unavailable, falling back to direct Supabase client:", err);
  }

  // 2. Client-side direct Supabase fallback
  try {
    const cleanEmail = email.trim().toLowerCase();
    const { data: partners, error } = await supabase
      .from("agency_referral_partners")
      .select("*")
      .ilike("email", cleanEmail)
      .limit(1);

    if (error || !partners || partners.length === 0) {
      return { success: false, message: "Bu e-posta adresi ile kayıtlı bir acente bulunamadı." };
    }

    const partner = partners[0] as ReferralPartner;

    // Calculate stats
    let totalReferred = 0;
    let landlordCount = 0;
    let tenantCount = 0;

    try {
      const codeToken = partner.referral_code || partner.slug;
      const { data: profiles } = await supabase
        .from("profiles")
        .select("role")
        .or(`referred_by_agency_code.eq.${codeToken},referred_by_agency_code.eq.${partner.slug}`);

      if (profiles) {
        totalReferred = profiles.length;
        landlordCount = profiles.filter((p) => p.role === "landlord" || p.role === "owner").length;
        tenantCount = profiles.filter((p) => p.role === "tenant").length;
      }
    } catch (e) {
      console.warn("Stats calculation fallback error:", e);
    }

    return {
      success: true,
      partner,
      stats: { totalReferred, landlordCount, tenantCount }
    };
  } catch (error: any) {
    console.error("Direct lookup error:", error);
    return { success: false, message: "Bağlantı hatası oluştu." };
  }
}

export async function sendReferralQrEmail(
  partner: ReferralPartner,
  lang: string = "TR"
): Promise<{ success: boolean }> {
  // 1. Try Next.js API Route first
  try {
    const res = await fetch("/api/send-referral-qr", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        email: partner.email,
        agencyName: partner.agency_name,
        slug: partner.slug,
        referralCode: partner.referral_code,
        lang
      })
    });
    if (res.ok) {
      return { success: true };
    }
  } catch (err) {
    console.warn("API route unavailable, calling Brevo direct:", err);
  }

  // 2. Client-side direct Brevo API call
  try {
    const codeToken = partner.referral_code || partner.slug;
    const deepLinkUrl = `stanomer://referral?token=${encodeURIComponent(codeToken)}`;
    const qrImageUrl = `https://api.qrserver.com/v1/create-qr-code/?size=400x400&margin=2&format=png&data=${encodeURIComponent(
      deepLinkUrl
    )}`;

    await fetch("https://api.brevo.com/v3/smtp/email", {
      method: "POST",
      headers: {
        accept: "application/json",
        "api-key": BREVO_API_KEY,
        "content-type": "application/json"
      },
      body: JSON.stringify({
        sender: { name: BREVO_SENDER_NAME, email: BREVO_SENDER_EMAIL },
        to: [{ email: partner.email, name: partner.agency_name }],
        subject: `Stanomer Acente QR Kodunuz — ${partner.agency_name}`,
        htmlContent: `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 24px; border: 1px solid #e2e8f0; border-radius: 16px; background-color: #ffffff;">
            <div style="text-align: center; margin-bottom: 24px;">
              <h1 style="color: #6d28d9; margin: 0; font-size: 24px;">Stanomer Referral Partner</h1>
              <p style="color: #64748b; font-size: 14px; margin-top: 6px;">Acente Özel QR Kodunuz</p>
            </div>
            <div style="background-color: #f8fafc; border: 1px solid #cbd5e1; border-radius: 12px; padding: 24px; text-align: center; margin-bottom: 24px;">
              <img src="${qrImageUrl}" alt="Stanomer Referral QR Code" width="220" height="220" style="display: block; margin: 0 auto; border-radius: 8px; border: 4px solid #ffffff; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.1);" />
              <p style="margin-top: 16px; font-weight: bold; color: #0f172a; font-size: 16px; letter-spacing: 1px;">Referral Kodunuz: ${codeToken}</p>
            </div>
            <p style="color: #334155; font-size: 14px; line-height: 1.6;">
              Sayın <strong>${partner.agency_name}</strong> ekibi,<br/>
              Stanomer Acente Ortaklığı programına hoş geldiniz! Bu QR kodu ofisinizde müşterilerinizle paylaşarak onların Stanomer'i sizin referansınızla kullanmasını sağlayabilirsiniz.
            </p>
            <div style="text-align: center; margin-top: 24px;">
              <a href="https://stanomer.online/agency-stats" style="display: inline-block; background-color: #6d28d9; color: #ffffff; padding: 12px 24px; border-radius: 8px; text-decoration: none; font-weight: bold; font-size: 14px;">Acente İstatistik Panelini Aç</a>
            </div>
          </div>
        `
      })
    });

    return { success: true };
  } catch (error: any) {
    console.error("Direct Brevo dispatch error:", error);
    return { success: false };
  }
}

export async function requestAgencyOtp(email: string): Promise<{
  success: boolean;
  message: string;
  isRateLimited?: boolean;
}> {
  // 1. Try Next.js API Route first
  try {
    const res = await fetch("/api/agency-stats/request-otp", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email })
    });
    if (res.ok) {
      return await res.json();
    }
  } catch (err) {
    console.warn("API route unavailable, falling back to direct Supabase OTP:", err);
  }

  // 2. Client-side direct Supabase fallback
  try {
    const cleanEmail = email.trim().toLowerCase();
    const neutralMessage = "Eğer bu e-posta sistemimizde kayıtlıysa, birazdan bir kod alacaksınız.";

    // Check if partner or profile exists
    let partnerAgencyName = "Acente";
    const { data: partners } = await supabase
      .from("agency_referral_partners")
      .select("id, agency_name, email")
      .ilike("email", cleanEmail)
      .limit(1);

    if (partners && partners.length > 0) {
      partnerAgencyName = partners[0].agency_name || "Acente";
    } else {
      const { data: profiles } = await supabase
        .from("profiles")
        .select("company_name, full_name")
        .ilike("email", cleanEmail)
        .limit(1);

      if (profiles && profiles.length > 0) {
        partnerAgencyName = profiles[0].company_name || profiles[0].full_name || "Acente";
      } else {
        return { success: true, message: neutralMessage };
      }
    }

    // Generate 6-digit OTP code & SHA-256 Hash
    const rawOtpCode = Math.floor(100000 + Math.random() * 900000).toString();
    const otpHash = await sha256Hex(rawOtpCode);
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000).toISOString();

    await supabase.from("agency_otp_codes").insert([
      {
        email: cleanEmail,
        otp_hash: otpHash,
        attempts: 0,
        is_used: false,
        expires_at: expiresAt
      }
    ]);

    // Send Brevo OTP Email
    await fetch("https://api.brevo.com/v3/smtp/email", {
      method: "POST",
      headers: {
        accept: "application/json",
        "api-key": BREVO_API_KEY,
        "content-type": "application/json"
      },
      body: JSON.stringify({
        sender: { name: BREVO_SENDER_NAME, email: BREVO_SENDER_EMAIL },
        to: [{ email: cleanEmail, name: partnerAgencyName }],
        subject: `${rawOtpCode} — Stanomer Giriş Doğrulama Kodunuz`,
        htmlContent: `
          <div style="font-family: Arial, sans-serif; max-width: 500px; margin: 0 auto; padding: 24px; border: 1px solid #e2e8f0; border-radius: 16px; background-color: #ffffff;">
            <div style="text-align: center; margin-bottom: 20px;">
              <h2 style="color: #6d28d9; margin: 0;">Stanomer Referans Paneli</h2>
              <p style="color: #64748b; font-size: 14px; margin-top: 4px;">Tek Kullanımlık Giriş Kodu</p>
            </div>
            <div style="background-color: #f8fafc; border: 1px solid #cbd5e1; padding: 20px; text-align: center; border-radius: 12px; margin-bottom: 20px;">
              <span style="font-size: 32px; font-weight: bold; letter-spacing: 6px; color: #0f172a;">${rawOtpCode}</span>
            </div>
            <p style="color: #334155; font-size: 14px; line-height: 1.5;">
              Sayın <strong>${partnerAgencyName}</strong>,<br/>
              Stanomer Acente Referans Paneli'ne giriş yapmak için yukarıdaki 6 haneli doğrulama kodunu kullanabilirsiniz.
            </p>
            <p style="color: #94a3b8; font-size: 12px; margin-top: 16px;">
              ⚠️ Bu kod <strong>10 dakika</strong> süreyle geçerlidir ve tek kullanımlıktır.
            </p>
          </div>
        `
      })
    });

    return { success: true, message: neutralMessage };
  } catch (e: any) {
    console.error("Direct request OTP error:", e);
    return { success: false, message: "Bağlantı hatası oluştu." };
  }
}

export async function verifyAgencyOtp(
  email: string,
  code: string
): Promise<{
  success: boolean;
  message: string;
  partner?: ReferralPartner;
}> {
  // 1. Try Next.js API Route first
  try {
    const res = await fetch("/api/agency-stats/verify-otp", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email, code })
    });
    if (res.ok) {
      return await res.json();
    }
  } catch (err) {
    console.warn("API route unavailable, falling back to direct Supabase verify:", err);
  }

  // 2. Client-side direct Supabase fallback
  try {
    const cleanEmail = email.trim().toLowerCase();
    const cleanCode = code.trim();
    const submittedHash = await sha256Hex(cleanCode);
    const nowIso = new Date().toISOString();

    const { data: otpRecords, error: fetchErr } = await supabase
      .from("agency_otp_codes")
      .select("*")
      .eq("email", cleanEmail)
      .eq("is_used", false)
      .gt("expires_at", nowIso)
      .order("created_at", { ascending: false })
      .limit(1);

    if (fetchErr || !otpRecords || otpRecords.length === 0) {
      return { success: false, message: "Hatalı veya süresi dolmuş kod. Lütfen yeni bir kod isteyin." };
    }

    const activeOtp = otpRecords[0];
    if (submittedHash !== activeOtp.otp_hash) {
      return { success: false, message: "Hatalı doğrulama kodu." };
    }

    // Mark as used
    await supabase.from("agency_otp_codes").update({ is_used: true }).eq("id", activeOtp.id);

    // Get partner
    const { data: partners } = await supabase
      .from("agency_referral_partners")
      .select("*")
      .ilike("email", cleanEmail)
      .limit(1);

    let partner: ReferralPartner | null = null;
    if (partners && partners.length > 0) {
      partner = partners[0] as ReferralPartner;
    } else {
      const { data: profiles } = await supabase
        .from("profiles")
        .select("*")
        .ilike("email", cleanEmail)
        .limit(1);

      if (profiles && profiles.length > 0) {
        const prof = profiles[0];
        partner = {
          id: prof.id,
          agency_name: prof.company_name || prof.full_name || "Acente",
          email: prof.email || cleanEmail,
          city: prof.city || "-",
          slug: prof.id,
          referral_code: prof.id,
          created_at: prof.created_at || nowIso
        };
      }
    }

    if (!partner) {
      return { success: false, message: "Acente kaydı bulunamadı." };
    }

    // Store in localStorage for client session
    try {
      localStorage.setItem("stanomer_agency_partner", JSON.stringify(partner));
    } catch (e) {}

    return { success: true, message: "Giriş başarılı.", partner };
  } catch (e: any) {
    console.error("Direct verify OTP error:", e);
    return { success: false, message: "Doğrulama sırasında hata oluştu." };
  }
}
