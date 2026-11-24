import { NextResponse } from "next/server";
import { createClient } from "@supabase/supabase-js";
import { supabase as anonSupabase } from "../../../lib/supabaseClient";

function getServerSupabase() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (url && serviceKey) {
    return createClient(url, serviceKey, { auth: { persistSession: false } });
  }
  return anonSupabase;
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
    const agencyId = body.agencyId ?? body.agency_id ?? null;
    const agencyName = body.agencyName ?? body.agency_name ?? "Stanomer Agency";
    const portalName = body.portalName ?? body.portal_name ?? body.portal_key ?? "";
    const contactPhone = body.contactPhone ?? body.contact_phone ?? "";
    const contactEmail = body.contactEmail ?? body.contact_email ?? "";
    const portalAccountRef = body.portalAccountRef ?? body.portal_account_ref ?? "";
    const notes = body.notes ?? "";

    if (!portalName || typeof portalName !== "string" || !portalName.trim()) {
      return NextResponse.json(
        { error: "Portal name is required." },
        { status: 400 }
      );
    }

    const cleanAgencyName = String(agencyName).trim();
    const cleanPortalName = String(portalName).trim();
    const cleanPhone = String(contactPhone || "").trim();
    const cleanEmail = String(contactEmail || "").trim();
    const cleanRef = String(portalAccountRef || "").trim();
    const cleanNotes = String(notes || "").trim();

    // 1. Insert into Supabase table portal_integration_requests
    let insertedId: string | null = null;
    try {
      const dbClient = getServerSupabase();
      const { data, error } = await dbClient
        .from("portal_integration_requests")
        .insert([
          {
            agency_id: agencyId || null,
            agency_name: cleanAgencyName,
            portal_name: cleanPortalName,
            contact_phone: cleanPhone || null,
            contact_email: cleanEmail || null,
            portal_account_ref: cleanRef || null,
            notes: cleanNotes || null,
            status: "pending",
          },
        ])
        .select("id")
        .single();

      if (error) {
        console.warn("Could not insert to portal_integration_requests:", error.message);
      } else if (data) {
        insertedId = data.id;
      }
    } catch (dbErr) {
      console.warn("DB error in portal-integration-request:", dbErr);
    }

    // 2. Send Email via Brevo API
    const apiKey = process.env.BREVO_API_KEY || "";
    const senderEmail = process.env.BREVO_SENDER_EMAIL || "atilbilge@gmail.com";
    const senderName = process.env.BREVO_SENDER_NAME || "Stanomer";
    const adminNotificationEmail =
      process.env.ADMIN_NOTIFICATION_EMAIL || "atilbilge@gmail.com";

    if (apiKey) {
      const adminSubject = `🚀 [Stanomer] Yeni Portal Entegrasyon Talebi: ${cleanPortalName} (${cleanAgencyName})`;
      const cleanPhoneDigits = cleanPhone.replace(/[^\d+]/g, "");
      const waLink = cleanPhoneDigits ? `https://wa.me/${cleanPhoneDigits.replace(/^\+/, "")}` : null;

      const adminHtmlContent = `
        <!DOCTYPE html>
        <html>
        <head><meta charset="utf-8"></head>
        <body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #f8fafc; margin: 0; padding: 24px; color: #1e293b;">
          <div style="max-width: 600px; margin: 0 auto; background: #ffffff; border-radius: 16px; border: 1px solid #e2e8f0; overflow: hidden; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.05);">
            <div style="background: linear-gradient(135deg, #1e3a8a, #3b82f6); padding: 24px; color: #ffffff;">
              <span style="font-size: 11px; text-transform: uppercase; letter-spacing: 0.1em; background: rgba(255,255,255,0.2); padding: 4px 10px; border-radius: 999px; font-weight: 600;">
                Özel Portal Talebi
              </span>
              <h1 style="margin: 12px 0 0 0; font-size: 20px; font-weight: 700;">
                ${escapeHtml(cleanPortalName)} Entegrasyon Talebi
              </h1>
              <p style="margin: 4px 0 0 0; font-size: 13px; opacity: 0.9;">
                Acente: ${escapeHtml(cleanAgencyName)}
              </p>
            </div>

            <div style="padding: 24px;">
              <table style="width: 100%; border-collapse: collapse; font-size: 13px;">
                <tr>
                  <td style="padding: 10px 0; border-bottom: 1px solid #f1f5f9; color: #64748b; width: 140px; font-weight: 600;">Portal Adı</td>
                  <td style="padding: 10px 0; border-bottom: 1px solid #f1f5f9; color: #0f172a; font-weight: 700;">${escapeHtml(cleanPortalName)}</td>
                </tr>
                <tr>
                  <td style="padding: 10px 0; border-bottom: 1px solid #f1f5f9; color: #64748b; font-weight: 600;">Acente Adı</td>
                  <td style="padding: 10px 0; border-bottom: 1px solid #f1f5f9; color: #0f172a;">${escapeHtml(cleanAgencyName)}</td>
                </tr>
                <tr>
                  <td style="padding: 10px 0; border-bottom: 1px solid #f1f5f9; color: #64748b; font-weight: 600;">İletişim Telefonu</td>
                  <td style="padding: 10px 0; border-bottom: 1px solid #f1f5f9; color: #0f172a;">
                    <strong>${escapeHtml(cleanPhone || "Belirtilmedi")}</strong>
                    ${waLink ? ` &bull; <a href="${waLink}" style="color: #2563eb; text-decoration: none; font-weight: 600;">WhatsApp Aç</a>` : ""}
                  </td>
                </tr>
                <tr>
                  <td style="padding: 10px 0; border-bottom: 1px solid #f1f5f9; color: #64748b; font-weight: 600;">İletişim E-posta</td>
                  <td style="padding: 10px 0; border-bottom: 1px solid #f1f5f9; color: #0f172a;">
                    ${cleanEmail ? `<a href="mailto:${escapeHtml(cleanEmail)}" style="color: #2563eb; text-decoration: none;">${escapeHtml(cleanEmail)}</a>` : "Belirtilmedi"}
                  </td>
                </tr>
                <tr>
                  <td style="padding: 10px 0; border-bottom: 1px solid #f1f5f9; color: #64748b; font-weight: 600;">Portal Hesap No / Ref</td>
                  <td style="padding: 10px 0; border-bottom: 1px solid #f1f5f9; color: #0f172a;">
                    ${escapeHtml(cleanRef || "Belirtilmedi")}
                  </td>
                </tr>
                <tr>
                  <td style="padding: 10px 0; color: #64748b; font-weight: 600; vertical-align: top;">Acente Notları</td>
                  <td style="padding: 10px 0; color: #334155; line-height: 1.5;">
                    ${escapeHtml(cleanNotes || "Not eklenmedi.")}
                  </td>
                </tr>
              </table>

              <div style="margin-top: 24px; padding: 14px; background: #f8fafc; border-radius: 10px; border: 1px solid #e2e8f0; font-size: 12px; color: #64748b;">
                <strong>Ne yapılmalı?</strong> Acentenin portaldaki hesap yöneticisi veya portal teknik birimiyle temasa geçilerek XML gereksinimleri alınmalı ve acenteye özel endpoint oluşturulmalıdır.
              </div>
            </div>

            <div style="background-color: #f1f5f9; padding: 14px 24px; text-align: center; font-size: 11px; color: #64748b;">
              Stanomer Agency Hub &bull; Otomatik Bildirim Sistemi
            </div>
          </div>
        </body>
        </html>
      `;

      // Dispatch to admin
      try {
        await fetch("https://api.brevo.com/v3/smtp/email", {
          method: "POST",
          headers: {
            accept: "application/json",
            "content-type": "application/json",
            "api-key": apiKey,
          },
          body: JSON.stringify({
            sender: { name: senderName, email: senderEmail },
            to: [{ email: adminNotificationEmail, name: "Stanomer Ekibi" }],
            subject: adminSubject,
            htmlContent: adminHtmlContent,
          }),
        });
      } catch (mailErr) {
        console.error("Failed to send admin notification email:", mailErr);
      }

      // If agency provided an email, send confirmation to the agency
      if (cleanEmail && cleanEmail.includes("@")) {
        const agencySubject = `Potvrda prijema zahteva za integraciju portala ${cleanPortalName} - Stanomer`;
        const agencyHtmlContent = `
          <!DOCTYPE html>
          <html>
          <body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #f8fafc; margin: 0; padding: 24px; color: #1e293b;">
            <div style="max-width: 600px; margin: 0 auto; background: #ffffff; border-radius: 16px; border: 1px solid #e2e8f0; padding: 24px;">
              <h2 style="color: #1e3a8a; margin-top: 0;">Zahtev za integraciju je uspešno primljen</h2>
              <p style="font-size: 14px; line-height: 1.6; color: #334155;">
                Poštovani,
              </p>
              <p style="font-size: 14px; line-height: 1.6; color: #334155;">
                Uspešno smo primili Vaš zahtev za integraciju sa portalom <strong>${escapeHtml(cleanPortalName)}</strong>.
              </p>
              <p style="font-size: 14px; line-height: 1.6; color: #334155;">
                Naš tehnički tim će u roku od 24-48 sati stupiti u kontakt sa tehničkom podrškom portala, pripremiti prilagođeni XML feed i obavestiti Vas čim povezivanje bude spremno.
              </p>
              <p style="font-size: 13px; color: #64748b; margin-top: 24px; border-top: 1px solid #f1f5f9; padding-top: 16px;">
                Ukoliko imate dodatnih pitanja, slobodno nam pišite na <a href="mailto:${senderEmail}" style="color: #2563eb;">${senderEmail}</a> ili putem Viber/WhatsApp podrške.
              </p>
              <p style="font-size: 13px; font-weight: 600; color: #0f172a; margin-bottom: 0;">
                Stanomer Tim
              </p>
            </div>
          </body>
          </html>
        `;

        try {
          await fetch("https://api.brevo.com/v3/smtp/email", {
            method: "POST",
            headers: {
              accept: "application/json",
              "content-type": "application/json",
              "api-key": apiKey,
            },
            body: JSON.stringify({
              sender: { name: senderName, email: senderEmail },
              to: [{ email: cleanEmail, name: cleanAgencyName }],
              subject: agencySubject,
              htmlContent: agencyHtmlContent,
            }),
          });
        } catch (agencyMailErr) {
          console.error("Failed to send agency confirmation email:", agencyMailErr);
        }
      }
    }

    return NextResponse.json({
      success: true,
      id: insertedId,
    });
  } catch (err: unknown) {
    console.error("portal-integration-request API error:", err);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 }
    );
  }
}

