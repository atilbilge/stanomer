// api/track.ts
// Vercel Edge Function for 24/7 Email Open Tracking Pixel
// Deployed automatically by Vercel under /api/track and /track/open/:id

export const config = {
  runtime: "edge",
};

// 1x1 transparent GIF (42 bytes)
const GIF_BYTES = new Uint8Array([
  71, 73, 70, 56, 57, 97, 1, 0, 1, 0, 128, 0, 0, 0, 0, 0,
  255, 255, 255, 33, 249, 4, 1, 0, 0, 0, 0, 44, 0, 0, 0, 0,
  1, 0, 1, 0, 0, 2, 1, 68, 0, 59
]);

export async function handler(req: Request): Promise<Response> {
  const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, HEAD, OPTIONS",
    "Content-Type": "image/gif",
    "Content-Length": GIF_BYTES.length.toString(),
    "Cache-Control": "no-store, no-cache, must-revalidate, proxy-revalidate, max-age=0",
    "Pragma": "no-cache",
    "Expires": "0",
  };

  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  try {
    const url = new URL(req.url);
    let agencyId = url.searchParams.get("id");
    let campaignId = url.searchParams.get("c") || "";

    // If id is not in query params, try parsing from path
    if (!agencyId) {
      const match = url.pathname.match(/(?:track(?:\/open)?)\/(\d+)/i);
      if (match) {
        agencyId = match[1];
      }
    }

    const ip =
      req.headers.get("cf-connecting-ip") ||
      req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ||
      req.headers.get("x-real-ip") ||
      "Bilinmiyor";

    const userAgent = req.headers.get("user-agent") || "Bilinmiyor";
    const referer = (req.headers.get("referer") || "").toLowerCase();

    // Ignore CRM internal previews or local admin tests
    const isInternal =
      referer.includes("localhost") ||
      referer.includes("127.0.0.1") ||
      referer.includes("stanomer.online/agencies") ||
      referer.includes("stanomer.online/dashboard");

    if (!isInternal && agencyId) {
      const apiKey =
        process.env.BREVO_API_KEY ||
        process.env.NEXT_PUBLIC_BREVO_API_KEY ||
        "";
      const senderEmail =
        process.env.BREVO_SENDER_EMAIL ||
        process.env.NEXT_PUBLIC_BREVO_SENDER_EMAIL ||
        "atilbilge@gmail.com";

      const nowStr = new Date().toLocaleString("tr-TR", { timeZone: "Europe/Belgrade" });

      const emailHtml = [
        "<div style=\"font-family: Arial, sans-serif; max-width: 500px; padding: 20px; border: 1px solid #e2e8f0; border-radius: 12px; background: #ffffff;\">",
        "<h3 style=\"color: #10b981; margin-top: 0;\">✉️ E-posta Açılma Bildirimi</h3>",
        "<p>Bir acente gönderdiğiniz e-postayı görüntüledi.</p>",
        "<table style=\"width: 100%; border-collapse: collapse; font-size: 14px; margin-top: 15px;\">",
        "<tr><td style=\"padding: 6px 0; color: #64748b;\"><strong>Acente ID:</strong></td><td><strong>#" + agencyId + "</strong></td></tr>",
        (campaignId ? "<tr><td style=\"padding: 6px 0; color: #64748b;\"><strong>Kampanya ID:</strong></td><td>#" + campaignId + "</td></tr>" : ""),
        "<tr><td style=\"padding: 6px 0; color: #64748b;\"><strong>İstemci IP:</strong></td><td><code>" + ip + "</code></td></tr>",
        "<tr><td style=\"padding: 6px 0; color: #64748b;\"><strong>Cihaz / İstemci:</strong></td><td><small>" + userAgent + "</small></td></tr>",
        "<tr><td style=\"padding: 6px 0; color: #64748b;\"><strong>Tarih:</strong></td><td>" + nowStr + " (Belgrad)</td></tr>",
        "</table>",
        "</div>"
      ].join("");

      if (apiKey) {
        await fetch("https://api.brevo.com/v3/smtp/email", {
          method: "POST",
          headers: {
            accept: "application/json",
            "content-type": "application/json",
            "api-key": apiKey,
          },
          body: JSON.stringify({
            sender: { name: "Stanomer Takip", email: senderEmail },
            to: [{ email: "atilbilge@gmail.com", name: "Atıl Bilge" }],
            subject: "✉️ E-posta Açıldı: Acente #" + agencyId + (campaignId ? " (Kampanya #" + campaignId + ")" : ""),
            htmlContent: emailHtml,
          }),
        }).catch((err) => {
          console.warn("Brevo tracking notification error:", err);
        });
      }
    }
  } catch (err) {
    console.error("Track handler error:", err);
  }

  return new Response(GIF_BYTES, {
    status: 200,
    headers: corsHeaders,
  });
}

export { handler as GET, handler as HEAD, handler as OPTIONS };
export default handler;
