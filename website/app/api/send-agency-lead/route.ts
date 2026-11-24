import { NextResponse } from "next/server";
import { createClient } from "@supabase/supabase-js";
import { supabase } from "../../../lib/supabaseClient";

function getLeadDbClient() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL || "https://nbcbfmhztnnhfnapvaet.supabase.co";
  const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (serviceKey) {
    return createClient(url, serviceKey, { auth: { persistSession: false } });
  }
  return supabase;
}

interface RateLimitRecord {
  count: number;
  resetAt: number;
}

const rateLimitMap = new Map<string, RateLimitRecord>();
const RATE_LIMIT_WINDOW_MS = 60 * 60 * 1000; // 1 hour
const MAX_REQUESTS_PER_WINDOW = 10;

function getClientIp(request: Request): string {
  const xForwardedFor = request.headers.get("x-forwarded-for");
  if (xForwardedFor) {
    return xForwardedFor.split(",")[0].trim();
  }
  const xRealIp = request.headers.get("x-real-ip");
  if (xRealIp) {
    return xRealIp.trim();
  }
  return "127.0.0.1";
}

function checkRateLimit(ip: string): boolean {
  const now = Date.now();
  const record = rateLimitMap.get(ip);

  if (rateLimitMap.size > 1000) {
    for (const [key, val] of rateLimitMap.entries()) {
      if (now > val.resetAt) rateLimitMap.delete(key);
    }
  }

  if (!record || now > record.resetAt) {
    rateLimitMap.set(ip, { count: 1, resetAt: now + RATE_LIMIT_WINDOW_MS });
    return false;
  }

  if (record.count >= MAX_REQUESTS_PER_WINDOW) {
    return true;
  }

  record.count += 1;
  return false;
}

function escapeHtml(str: string): string {
  return String(str || "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const {
      agencyEmail,
      agencyName,
      ownerName,
      ownerPhone,
      ownerEmail,
      transactionType,
      propertyType,
      location,
      areaSqm,
      expectedPrice,
      notes,
      lang,
      honeypot,
    } = body;

    const rawName = (body.clientName || body.ownerName || "").trim();
    const rawPhone = (body.clientPhone || body.ownerPhone || "").trim();
    const rawEmail = (body.clientEmail || body.ownerEmail || "").trim();
    const isViewing = body.leadType === "viewing_request";

    // 1. Invisible Honeypot Check
    if (honeypot && typeof honeypot === "string" && honeypot.trim().length > 0) {
      return NextResponse.json({ success: true });
    }

    // 2. Rate Limit Check
    const clientIp = getClientIp(request);
    if (checkRateLimit(clientIp)) {
      return NextResponse.json(
        {
          success: false,
          message:
            lang === "TR"
              ? "Çok fazla talep gönderildi. Lütfen daha sonra tekrar deneyin."
              : "Too many requests. Please try again later.",
        },
        { status: 429 }
      );
    }

    if (!rawName || !rawPhone) {
      return NextResponse.json(
        {
          success: false,
          message:
            lang === "TR"
              ? "Ad Soyad ve Telefon alanları zorunludur."
              : "Name and Phone are required.",
        },
        { status: 400 }
      );
    }

    const targetEmail = (agencyEmail || "").trim();
    if (!targetEmail || !targetEmail.includes("@")) {
      return NextResponse.json(
        {
          success: false,
          message:
            lang === "TR"
              ? "Acente e-posta adresi tanımlı değil."
              : "Agency email address is not configured.",
        },
        { status: 400 }
      );
    }

    // Persist lead in public.agency_leads table if database is available
    try {
      const cleanAgencyId = String(body.agencyId || "").trim() || "demo";
      const normalizedLang = String(body.lang || "SR_LAT").toUpperCase();
      
      const systemAuthorMap: Record<string, string> = {
        SR_LAT: "Sistem",
        SR_CYR: "Систем",
        EN: "System",
        TR: "Sistem",
        RU: "Система",
      };
      const viewingCommentMap: Record<string, string> = {
        SR_LAT: "Zahtev za razgledanje poslat sa sajta",
        SR_CYR: "Захтев за разгледање послат са сајта",
        EN: "Viewing request submitted via website",
        TR: "Vitrin sitesinden yer görme randevu talebi gönderildi",
        RU: "Запрос на просмотр отправлен с сайта",
      };
      const ownerCommentMap: Record<string, string> = {
        SR_LAT: "Prijava vlasnika nekretnine poslata sa sajta",
        SR_CYR: "Пријава власника некретнине послата са сајта",
        EN: "Property owner inquiry submitted via website",
        TR: "Vitrin sitesinden mülk sahibi başvurusu yapıldı",
        RU: "Заявка собственника отправлена с сайта",
      };

      const authorName = systemAuthorMap[normalizedLang] || systemAuthorMap.SR_LAT;
      const commentText = isViewing
        ? (viewingCommentMap[normalizedLang] || viewingCommentMap.SR_LAT)
        : (ownerCommentMap[normalizedLang] || ownerCommentMap.SR_LAT);

      const initialComment = [
        {
          id: "cmt-" + Date.now(),
          author_name: authorName,
          text: commentText,
          created_at: new Date().toISOString(),
        },
      ];

      const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(String(body.listingId || ""));

      const dbClient = getLeadDbClient();
      const { error: insertErr } = await dbClient.from("agency_leads").insert({
        agency_id: cleanAgencyId,
        lead_type: isViewing ? "viewing_request" : "owner_consignment",
        status: "new",
        client_name: rawName,
        client_phone: rawPhone,
        client_email: rawEmail || null,
        transaction_type: transactionType === "izdavanje" ? "izdavanje" : "prodaja",
        property_type: propertyType || "apartment",
        location: location && typeof location === "string" ? location.trim() : null,
        area_sqm: areaSqm && !isNaN(Number(areaSqm)) ? Number(areaSqm) : null,
        expected_price: expectedPrice && !isNaN(Number(expectedPrice)) ? Number(expectedPrice) : null,
        currency: "EUR",
        notes: notes && typeof notes === "string" ? notes.trim() : null,
        listing_id: isUuid ? body.listingId : null,
        listing_title: body.listingTitle || null,
        comments: initialComment,
      });
      if (insertErr) {
        console.error("Failed to insert agency lead into database:", insertErr);
      }
    } catch (dbErr) {
      console.warn("Could not insert agency lead into database:", dbErr);
    }

    const txLabel =
      transactionType === "prodaja"
        ? "Prodaja / Satılık / For Sale"
        : "Izdavanje / Kiralık / For Rent";

    const safeAgencyName = escapeHtml(agencyName || "Partner Agencija");
    const safeOwnerName = escapeHtml(rawName);
    const safeOwnerPhone = escapeHtml(rawPhone);
    const safeOwnerEmail = escapeHtml(rawEmail || "-");
    const safePropertyType = escapeHtml(propertyType || "-");
    const safeLocation = escapeHtml(location || "-");
    const safeArea = escapeHtml(areaSqm ? `${areaSqm} m²` : "-");
    const safePrice = escapeHtml(expectedPrice ? `€${expectedPrice}` : "-");
    const safeNotes = escapeHtml(notes || "-");
    const safeListingTitle = escapeHtml(body.listingTitle || "-");

    const subject = isViewing
      ? `📅 Zahtev za Razgledanje Nekretnine: ${safeOwnerName} - ${safeListingTitle}`
      : `🏠 Nova Ponuda Vlasnika Nekretnine (${txLabel.split(" / ")[0]}): ${safeOwnerName} - ${safeLocation}`;

    const htmlContent = `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <title>${subject}</title>
      </head>
      <body style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f8fafc; color: #0f172a; margin: 0; padding: 24px;">
        <div style="max-width: 600px; margin: 0 auto; background: #ffffff; border-radius: 16px; overflow: hidden; border: 1px solid #e2e8f0;">
          <div style="background-color: #0f172a; padding: 24px 32px; color: #ffffff;">
            <p style="margin: 0 0 6px 0; font-size: 11px; text-transform: uppercase; letter-spacing: 1.5px; color: #94a3b8;">
              ${safeAgencyName} • Stanomer Vitrin Formu
            </p>
            <h1 style="margin: 0; font-size: 20px; font-weight: 700;">
              ${isViewing ? "📅 Yeni İlan Yer Görme / Randevu Talebi" : "🏠 Yeni Mülk Sahibi Yetkilendirme / İlan Talebi"}
            </h1>
          </div>
          <div style="padding: 28px 32px;">
            <p style="margin-top: 0; font-size: 14px; color: #475569; line-height: 1.6;">
              ${
                isViewing
                  ? `Vitrin sitenizdeki ilan için bir alıcı/kiracı adayı <strong>yer görme randevusu</strong> talebinde bulundu:`
                  : `Vitrin sayfanız üzerinden bir mülk sahibi gayrimenkulünü <strong>${escapeHtml(txLabel)}</strong> olarak portföyünüze eklemek için iletişim bıraktı:`
              }
            </p>

            <table style="width: 100%; border-collapse: collapse; margin-top: 16px; font-size: 14px;">
              ${
                isViewing
                  ? `<tr style="border-bottom: 1px solid #f1f5f9; background: #f8fafc;">
                      <td style="padding: 10px 8px; color: #2563eb; width: 40%;"><strong>İlgili İlan / Nekretnina:</strong></td>
                      <td style="padding: 10px 8px; font-weight: 700; color: #1e3a8a;">${safeListingTitle}</td>
                    </tr>`
                  : ""
              }
              <tr style="border-bottom: 1px solid #f1f5f9;">
                <td style="padding: 10px 0; color: #64748b; width: 40%;"><strong>Müşteri / Klijent:</strong></td>
                <td style="padding: 10px 0; font-weight: 600; color: #0f172a;">${safeOwnerName}</td>
              </tr>
              <tr style="border-bottom: 1px solid #f1f5f9;">
                <td style="padding: 10px 0; color: #64748b;"><strong>Telefon:</strong></td>
                <td style="padding: 10px 0; font-weight: 600;"><a href="tel:${safeOwnerPhone}" style="color: #2563eb; text-decoration: none;">${safeOwnerPhone}</a></td>
              </tr>
              <tr style="border-bottom: 1px solid #f1f5f9;">
                <td style="padding: 10px 0; color: #64748b;"><strong>E-posta:</strong></td>
                <td style="padding: 10px 0;">${safeOwnerEmail}</td>
              </tr>
              <tr style="border-bottom: 1px solid #f1f5f9;">
                <td style="padding: 10px 0; color: #64748b;"><strong>İşlem Türü / Transakcija:</strong></td>
                <td style="padding: 10px 0; font-weight: 600;">${escapeHtml(txLabel)}</td>
              </tr>
              <tr style="border-bottom: 1px solid #f1f5f9;">
                <td style="padding: 10px 0; color: #64748b;"><strong>Emlak Tipi / Tip:</strong></td>
                <td style="padding: 10px 0;">${safePropertyType}</td>
              </tr>
              <tr style="border-bottom: 1px solid #f1f5f9;">
                <td style="padding: 10px 0; color: #64748b;"><strong>Konum / Lokacija:</strong></td>
                <td style="padding: 10px 0;">${safeLocation}</td>
              </tr>
              <tr style="border-bottom: 1px solid #f1f5f9;">
                <td style="padding: 10px 0; color: #64748b;"><strong>Alan / Površina:</strong></td>
                <td style="padding: 10px 0;">${safeArea}</td>
              </tr>
              <tr style="border-bottom: 1px solid #f1f5f9;">
                <td style="padding: 10px 0; color: #64748b;"><strong>Fiyat / Cena:</strong></td>
                <td style="padding: 10px 0; font-weight: 600; color: #059669;">${safePrice}</td>
              </tr>
            </table>

            <div style="margin-top: 20px; padding: 16px; background: #f8fafc; border-radius: 12px; border: 1px solid #e2e8f0;">
              <p style="margin: 0 0 6px 0; font-size: 12px; font-weight: 700; text-transform: uppercase; color: #64748b;">
                ${isViewing ? "Müşteri Randevu Tercihi / Notu:" : "Mülk Sahibi Notu / Opis:"}
              </p>
              <p style="margin: 0; font-size: 14px; color: #1e293b; white-space: pre-line;">${safeNotes}</p>
            </div>
          </div>
          <div style="background-color: #f1f5f9; padding: 16px 32px; text-align: center; font-size: 12px; color: #64748b;">
            &copy; ${new Date().getFullYear()} ${safeAgencyName} • Powered by Stanomer Agency Hub
          </div>
        </div>
      </body>
      </html>
    `;

    const apiKey = process.env.BREVO_API_KEY || "";
    const senderEmail = process.env.BREVO_SENDER_EMAIL || "atilbilge@gmail.com";
    const senderName = process.env.BREVO_SENDER_NAME || "Stanomer Agency Hub";

    if (!apiKey) {
      return NextResponse.json({
        success: true,
        simulated: true,
      });
    }

    const payload: Record<string, unknown> = {
      sender: {
        name: `${agencyName || senderName} (via Stanomer)`,
        email: senderEmail,
      },
      to: [
        {
          email: targetEmail,
          name: agencyName || targetEmail,
        },
      ],
      subject,
      htmlContent,
    };

    if (ownerEmail && typeof ownerEmail === "string" && ownerEmail.includes("@")) {
      payload.replyTo = {
        email: ownerEmail.trim(),
        name: ownerName.trim(),
      };
    }

    const brevoRes = await fetch("https://api.brevo.com/v3/smtp/email", {
      method: "POST",
      headers: {
        accept: "application/json",
        "content-type": "application/json",
        "api-key": apiKey,
      },
      body: JSON.stringify(payload),
    });

    if (!brevoRes.ok) {
      const errData = await brevoRes.json().catch(() => ({}));
      console.error("Brevo error in send-agency-lead:", errData);
      return NextResponse.json(
        {
          success: false,
          message: errData.message || "Email send error",
        },
        { status: brevoRes.status }
      );
    }

    return NextResponse.json({
      success: true,
    });
  } catch (err: unknown) {
    console.error("send-agency-lead error:", err);
    return NextResponse.json(
      {
        success: false,
        message: err instanceof Error ? err.message : "Server error",
      },
      { status: 500 }
    );
  }
}

