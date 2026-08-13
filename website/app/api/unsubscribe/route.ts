import { NextResponse } from "next/server";

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
    if (brevoResponse.status === 204 || brevoResponse.status === 404) {
      return NextResponse.json({
        success: true,
        message: "E-posta listemizden başarıyla çıkarıldınız.",
      });
    }

    const brevoData = await brevoResponse.json().catch(() => ({}));

    if (!brevoResponse.ok) {
      console.error("Brevo Unsubscribe Error:", brevoData);
      return NextResponse.json(
        {
          success: false,
          message: brevoData.message || "Bir hata oluştu.",
          details: brevoData,
        },
        { status: brevoResponse.status }
      );
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
