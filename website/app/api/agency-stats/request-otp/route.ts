import { NextResponse } from "next/server";
import crypto from "crypto";
import { supabase } from "../../../../lib/supabaseClient";

export const dynamic = "force-dynamic";

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { email } = body;

    if (!email || typeof email !== "string") {
      return NextResponse.json(
        { success: false, message: "Geçerli bir e-posta adresi giriniz." },
        { status: 400 }
      );
    }

    const cleanEmail = email.trim().toLowerCase();
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(cleanEmail)) {
      return NextResponse.json(
        { success: false, message: "Geçerli bir e-posta adresi giriniz." },
        { status: 400 }
      );
    }

    const now = new Date();
    const oneMinAgo = new Date(now.getTime() - 60 * 1000).toISOString();
    const oneHourAgo = new Date(now.getTime() - 60 * 60 * 1000).toISOString();

    // 1. Rate Limiting Check
    try {
      // Max 1 request per 1 minute
      const { data: recentOneMin } = await supabase
        .from("agency_otp_codes")
        .select("id")
        .eq("email", cleanEmail)
        .gte("created_at", oneMinAgo)
        .limit(1);

      if (recentOneMin && recentOneMin.length > 0) {
        return NextResponse.json({
          success: true,
          message: "Lütfen yeni bir kod istemeden önce 1 dakika bekleyin.",
          isRateLimited: true
        });
      }

      // Max 5 requests per 1 hour
      const { count: hourlyCount } = await supabase
        .from("agency_otp_codes")
        .select("*", { count: "exact", head: true })
        .eq("email", cleanEmail)
        .gte("created_at", oneHourAgo);

      if (hourlyCount && hourlyCount >= 5) {
        return NextResponse.json({
          success: true,
          message: "Çok fazla kod talebinde bulundunuz. Lütfen 1 saat sonra tekrar deneyin.",
          isRateLimited: true
        });
      }
    } catch (e) {
      console.warn("Rate limit check warning:", e);
    }

    // Neutral message returned regardless of registration status
    const neutralMessage = "Eğer bu e-posta sistemimizde kayıtlıysa, birazdan bir kod alacaksınız.";

    // 2. Check if email exists in agency_referral_partners OR profiles
    let partnerAgencyName = "Acente";
    let partnerEmail = cleanEmail;

    const { data: partners } = await supabase
      .from("agency_referral_partners")
      .select("id, agency_name, email")
      .ilike("email", cleanEmail)
      .limit(1);

    if (partners && partners.length > 0) {
      partnerAgencyName = partners[0].agency_name || "Acente";
      partnerEmail = partners[0].email;
    } else {
      const { data: profiles } = await supabase
        .from("profiles")
        .select("id, full_name, company_name, email, role")
        .ilike("email", cleanEmail)
        .limit(1);

      if (profiles && profiles.length > 0) {
        partnerAgencyName = profiles[0].company_name || profiles[0].full_name || "Acente";
        partnerEmail = profiles[0].email || cleanEmail;
      } else {
        console.log(`[OTP Request] Email not found in agency_referral_partners or profiles: ${cleanEmail}`);
        return NextResponse.json({
          success: true,
          message: neutralMessage
        });
      }
    }

    // 3. Generate 6-digit OTP code & SHA-256 Hash
    const rawOtpCode = Math.floor(100000 + Math.random() * 900000).toString();
    const otpHash = crypto.createHash("sha256").update(rawOtpCode).digest("hex");
    const expiresAt = new Date(now.getTime() + 10 * 60 * 1000).toISOString(); // 10 minutes

    // 4. Save to agency_otp_codes table
    try {
      await supabase.from("agency_otp_codes").insert([
        {
          email: cleanEmail,
          otp_hash: otpHash,
          attempts: 0,
          is_used: false,
          expires_at: expiresAt
        }
      ]);
    } catch (e) {
      console.error("Error saving OTP to database:", e);
    }

    // 5. Send OTP via Brevo API
    const apiKey = process.env.BREVO_API_KEY || "";
    const senderEmail = process.env.BREVO_SENDER_EMAIL || "atilbilge@gmail.com";
    const senderName = process.env.BREVO_SENDER_NAME || "Stanomer";

    console.log(`[OTP Generated] ${cleanEmail} -> ${rawOtpCode}`);

    if (apiKey) {
      try {
        const brevoRes = await fetch("https://api.brevo.com/v3/smtp/email", {
          method: "POST",
          headers: {
            "accept": "application/json",
            "api-key": apiKey,
            "content-type": "application/json"
          },
          body: JSON.stringify({
            sender: { name: senderName, email: senderEmail },
            to: [{ email: partnerEmail, name: partnerAgencyName }],
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
                  ⚠️ Bu kod <strong>10 dakika</strong> süreyle geçerlidir ve tek kullanımlıktır. Giriş talebinde bulunmadıysanız bu e-postayı dikkate almayınız.
                </p>
              </div>
            `
          })
        });

        if (!brevoRes.ok) {
          const errData = await brevoRes.json();
          console.error("Brevo OTP Email error response:", errData);
        } else {
          console.log(`[OTP Email Sent] Successfully dispatched OTP email to ${partnerEmail}`);
        }
      } catch (emailErr) {
        console.error("Brevo OTP Email dispatch exception:", emailErr);
      }
    }

    return NextResponse.json({
      success: true,
      message: neutralMessage
    });

  } catch (error: any) {
    console.error("Request OTP Error:", error);
    return NextResponse.json(
      { success: false, message: "Sunucu hatası oluştu." },
      { status: 500 }
    );
  }
}
