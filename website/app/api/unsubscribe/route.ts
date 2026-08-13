import { NextResponse } from "next/server";
import { createClient } from "@supabase/supabase-js";

function getSupabaseClient() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL!;
  const key = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;
  return createClient(url, key);
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { email } = body;

    if (!email || !email.includes("@")) {
      return NextResponse.json(
        { success: false, message: "Geçersiz e-posta adresi." },
        { status: 400 }
      );
    }

    const apiKey = process.env.BREVO_API_KEY || "";

    // Brevo: mark contact as email-blacklisted (unsubscribed)
    const brevoResponse = await fetch(
      `https://api.brevo.com/v3/contacts/${encodeURIComponent(email)}`,
      {
        method: "PUT",
        headers: {
          "accept": "application/json",
          "content-type": "application/json",
          "api-key": apiKey,
        },
        body: JSON.stringify({ emailBlacklisted: true }),
      }
    );

    // 204 = success (no content), 404 = contact not found (still treat as success)
    const brevoOk =
      brevoResponse.status === 204 ||
      brevoResponse.status === 404 ||
      brevoResponse.ok;

    if (!brevoOk) {
      const brevoData = await brevoResponse.json().catch(() => ({}));
      console.error("Brevo Unsubscribe Error:", brevoData);
      return NextResponse.json(
        {
          success: false,
          message: (brevoData as any).message || "Bir hata oluştu.",
          details: brevoData,
        },
        { status: brevoResponse.status }
      );
    }

    // Supabase: kayıt al (duplicate email'e sessizce geç)
    try {
      const supabase = getSupabaseClient();
      const ip =
        request.headers.get("x-forwarded-for")?.split(",")[0]?.trim() || null;
      await supabase.from("email_unsubscribes").upsert(
        {
          email: email.toLowerCase(),
          source: "unsubscribe_page",
          ip_address: ip,
        },
        { onConflict: "email", ignoreDuplicates: true }
      );
    } catch (dbErr) {
      // DB hatası kullanıcıya gösterilmez, sadece logla
      console.error("Supabase unsubscribe insert error:", dbErr);
    }

    return NextResponse.json({
      success: true,
      message: "E-posta listemizden başarıyla çıkarıldınız.",
    });
  } catch (error: any) {
    console.error("Unsubscribe Error:", error);
    return NextResponse.json(
      { success: false, message: error.message || "Sunucu hatası." },
      { status: 500 }
    );
  }
}
