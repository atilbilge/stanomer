import { NextResponse } from "next/server";
import crypto from "crypto";
import { supabase } from "../../../../lib/supabaseClient";

export const dynamic = "force-dynamic";

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { email, code } = body;

    if (!email || !code || typeof code !== "string") {
      return NextResponse.json(
        { success: false, message: "E-posta ve 6 haneli doğrulama kodu zorunludur." },
        { status: 400 }
      );
    }

    const cleanEmail = email.trim().toLowerCase();
    const cleanCode = code.trim();

    if (cleanCode.length !== 6 || !/^\d{6}$/.test(cleanCode)) {
      return NextResponse.json(
        { success: false, message: "Lütfen 6 haneli sayısal kodu giriniz." },
        { status: 400 }
      );
    }

    const now = new Date();

    // 1. Check for Brute-Force Lockout
    const { data: blockedRecords } = await supabase
      .from("agency_otp_codes")
      .select("blocked_until")
      .eq("email", cleanEmail)
      .gt("blocked_until", now.toISOString())
      .limit(1);

    if (blockedRecords && blockedRecords.length > 0) {
      return NextResponse.json(
        {
          success: false,
          message: "Çok fazla hatalı deneme yapıldı. Lütfen 15 dakika bekleyin ve yeni kod isteyin."
        },
        { status: 429 }
      );
    }

    // 2. Fetch latest active, unused OTP code for email
    const { data: otpRecords, error: fetchErr } = await supabase
      .from("agency_otp_codes")
      .select("*")
      .eq("email", cleanEmail)
      .eq("is_used", false)
      .gt("expires_at", now.toISOString())
      .order("created_at", { ascending: false })
      .limit(1);

    if (fetchErr || !otpRecords || otpRecords.length === 0) {
      return NextResponse.json(
        { success: false, message: "Hatalı veya süresi dolmuş kod. Lütfen yeni bir kod isteyin." },
        { status: 400 }
      );
    }

    const activeOtp = otpRecords[0];

    // Check SHA-256 Hash
    const submittedHash = crypto.createHash("sha256").update(cleanCode).digest("hex");

    if (submittedHash !== activeOtp.otp_hash) {
      const newAttempts = (activeOtp.attempts || 0) + 1;
      let blockedUntil = null;

      if (newAttempts >= 5) {
        blockedUntil = new Date(now.getTime() + 15 * 60 * 1000).toISOString(); // 15 minutes lockout
      }

      await supabase
        .from("agency_otp_codes")
        .update({
          attempts: newAttempts,
          ...(blockedUntil ? { blocked_until: blockedUntil } : {})
        })
        .eq("id", activeOtp.id);

      if (newAttempts >= 5) {
        return NextResponse.json(
          {
            success: false,
            message: "5 kez hatalı kod girildi. Hesabınız 15 dakika kilitlendi."
          },
          { status: 429 }
        );
      }

      return NextResponse.json(
        {
          success: false,
          message: `Hatalı kod. Kalan deneme hakkınız: ${5 - newAttempts}`
        },
        { status: 400 }
      );
    }

    // 3. Code is valid -> Mark OTP as used
    await supabase
      .from("agency_otp_codes")
      .update({ is_used: true })
      .eq("id", activeOtp.id);

    // 4. Fetch Partner Record from agency_referral_partners OR profiles
    let partner: any = null;

    const { data: partners } = await supabase
      .from("agency_referral_partners")
      .select("*")
      .ilike("email", cleanEmail)
      .limit(1);

    if (partners && partners.length > 0) {
      partner = partners[0];
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
          slug: prof.id,
          referral_code: prof.id
        };
      }
    }

    if (!partner) {
      return NextResponse.json(
        { success: false, message: "Acente kaydı bulunamadı." },
        { status: 404 }
      );
    }

    // 5. Generate Secure Session Token (Valid 24 hours)
    const sessionPayload = {
      partnerId: partner.id,
      email: partner.email,
      agencyName: partner.agency_name,
      slug: partner.slug,
      referralCode: partner.referral_code,
      exp: Math.floor(Date.now() / 1000) + 86400 // 24 hours
    };

    const secret = process.env.SESSION_SECRET || "stanomer-agency-stats-secret-key-2026";
    const payloadBase64 = Buffer.from(JSON.stringify(sessionPayload)).toString("base64url");
    const signature = crypto.createHmac("sha256", secret).update(payloadBase64).digest("base64url");
    const token = `${payloadBase64}.${signature}`;

    // 6. Set HTTP-Only Session Cookie
    const response = NextResponse.json({
      success: true,
      message: "Giriş başarılı.",
      partner
    });

    response.cookies.set("agency_stats_session", token, {
      httpOnly: true,
      secure: process.env.NODE_ENV === "production",
      sameSite: "lax",
      maxAge: 86400, // 24 hours
      path: "/"
    });

    return response;

  } catch (error: any) {
    console.error("Verify OTP Error:", error);
    return NextResponse.json(
      { success: false, message: "Doğrulama sırasında sunucu hatası oluştu." },
      { status: 500 }
    );
  }
}
