import { NextResponse } from "next/server";

// 1x1 transparent GIF (43 bytes)
const TRACKING_PIXEL_GIF = Buffer.from(
  "R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7",
  "base64"
);

export async function GET(
  request: Request,
  props: { params: Promise<{ id: string }> }
) {
  try {
    const params = await props.params;
    const agencyId = params?.id;

    const url = new URL(request.url);
    const campaignId = url.searchParams.get("c") || "";

    // Client IP detection (Cloudflare / Vercel Edge / Reverse proxy headers)
    const ip =
      request.headers.get("cf-connecting-ip") ||
      request.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ||
      request.headers.get("x-real-ip") ||
      "Bilinmiyor";

    const userAgent = request.headers.get("user-agent") || "Bilinmiyor";
    const referer = (request.headers.get("referer") || "").toLowerCase();

    // Dahili CRM önizlemelerini yoksay
    const isInternal =
      referer.includes("localhost") ||
      referer.includes("127.0.0.1") ||
      referer.includes("stanomer.online/agencies") ||
      referer.includes("stanomer.online/dashboard");

    if (!isInternal && agencyId) {
      const apiKey =
        process.env.BREVO_API_KEY || "";
      const senderEmail = process.env.BREVO_SENDER_EMAIL || "atilbilge@gmail.com";

      // Arka planda bildirim e-postası gönder
      fetch("https://api.brevo.com/v3/smtp/email", {
        method: "POST",
        headers: {
          accept: "application/json",
          "content-type": "application/json",
          "api-key": apiKey,
        },
        body: JSON.stringify({
          sender: { name: "Stanomer Takip", email: senderEmail },
          to: [{ email: "atilbilge@gmail.com", name: "Atıl Bilge" }],
          subject: `✉️ E-posta Açıldı: Acente #${agencyId}${campaignId ? ` (Kampanya #${campaignId})` : ""}`,
          htmlContent: `
            <div style="font-family: Arial, sans-serif; max-width: 500px; padding: 20px; border: 1px solid #e2e8f0; border-radius: 12px; background: #ffffff;">
              <h3 style="color: #10b981; margin-top: 0;">✉️ E-posta Açılma Bildirimi</h3>
              <p>Bir acente gönderdiğiniz e-postayı görüntüledi.</p>
              <table style="width: 100%; border-collapse: collapse; font-size: 14px; margin-top: 15px;">
                <tr><td style="padding: 6px 0; color: #64748b;"><strong>Acente ID:</strong></td><td><strong>#${agencyId}</strong></td></tr>
                ${campaignId ? `<tr><td style="padding: 6px 0; color: #64748b;"><strong>Kampanya ID:</strong></td><td>#${campaignId}</td></tr>` : ""}
                <tr><td style="padding: 6px 0; color: #64748b;"><strong>İstemci IP:</strong></td><td><code>${ip}</code></td></tr>
                <tr><td style="padding: 6px 0; color: #64748b;"><strong>Cihaz / İstemci:</strong></td><td><small>${userAgent}</small></td></tr>
                <tr><td style="padding: 6px 0; color: #64748b;"><strong>Tarih:</strong></td><td>${new Date().toLocaleString("tr-TR", { timeZone: "Europe/Belgrade" })} (Belgrad)</td></tr>
              </table>
            </div>
          `,
        }),
      }).catch((err) => {
        console.warn("Brevo open tracking notification error:", err);
      });
    }
  } catch (e) {
    console.error("Tracking pixel error:", e);
  }

  // 1x1 GIF dön (her koşulda başarılı)
  return new NextResponse(TRACKING_PIXEL_GIF, {
    status: 200,
    headers: {
      "Content-Type": "image/gif",
      "Cache-Control": "no-store, no-cache, must-revalidate, proxy-revalidate, max-age=0",
      Pragma: "no-cache",
      Expires: "0",
    },
  });
}
