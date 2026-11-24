import { NextResponse } from "next/server";
import { supabase } from "../../../lib/supabaseClient";
import crypto from "crypto";

const TOKEN_SECRET =
  process.env.BREVO_API_KEY ||
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ||
  "stanomer-agency-demo-token-secret-2026";

function escapeHtml(str: string): string {
  return String(str || "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

// In-memory rate limiting: max 5 requests per 10 minutes per IP / email
const rateLimitMap = new Map<string, { count: number; expiresAt: number }>();

function isRateLimited(key: string): boolean {
  const now = Date.now();
  const entry = rateLimitMap.get(key);
  if (!entry || now > entry.expiresAt) {
    rateLimitMap.set(key, { count: 1, expiresAt: now + 10 * 60 * 1000 });
    return false;
  }
  if (entry.count >= 5) {
    return true;
  }
  entry.count += 1;
  return false;
}

// Known disposable email domains
const DISPOSABLE_DOMAINS = new Set([
  "mailinator.com",
  "tempmail.com",
  "10minutemail.com",
  "guerrillamail.com",
  "yopmail.com",
  "throwawaymail.com",
  "trashmail.com",
  "sharklasers.com",
  "dispostable.com",
  "fakeinbox.com",
  "getairmail.com",
  "temp-mail.org",
  "generator.email",
  "emailondeck.com",
  "mohmal.com",
  "tempail.com",
  "mytemp.email",
  "minuteinbox.com",
  "burnerdkim.com",
  "burnermail.io",
]);

const EMAIL_REGEX =
  /^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$/;

export async function POST(request: Request) {
  try {
    const ip =
      request.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ||
      request.headers.get("x-real-ip") ||
      "127.0.0.1";
    const userAgent = request.headers.get("user-agent") || "";

    const body = await request.json();
    const {
      agencyName,
      email,
      phone,
      city = "Beograd",
      focus = "both",
      modules,
      locale = "sr",
      marketingConsent = false,
    } = body;
    const validFocus = ["presales", "aftersales", "both"].includes(focus) ? focus : "both";
    const validModules = Array.isArray(modules) && modules.length > 0
      ? modules
      : validFocus === "presales"
      ? ["portfolio_distribution"]
      : validFocus === "aftersales"
      ? ["property_lease_management"]
      : ["portfolio_distribution", "property_lease_management"];

    // 1. Basic validation
    if (!agencyName || typeof agencyName !== "string" || !agencyName.trim()) {
      return NextResponse.json(
        { error: "agency_required", key: "agency_demo_err_agency_required" },
        { status: 400 }
      );
    }

    if (!email || typeof email !== "string" || !EMAIL_REGEX.test(email.trim())) {
      return NextResponse.json(
        { error: "invalid_email", key: "agency_demo_err_email_invalid" },
        { status: 400 }
      );
    }

    const cleanEmail = String(email).trim().toLowerCase();
    const emailDomain = cleanEmail.split("@")[1] || "";

    // 2. Disposable email check
    if (DISPOSABLE_DOMAINS.has(emailDomain)) {
      return NextResponse.json(
        { error: "disposable_email", key: "agency_demo_err_disposable" },
        { status: 400 }
      );
    }

    // 3. Rate limiting check
    if (isRateLimited(`ip:${ip}`) || isRateLimited(`email:${cleanEmail}`)) {
      return NextResponse.json(
        { error: "rate_limit_exceeded", key: "agency_demo_err_rate_limit" },
        { status: 429 }
      );
    }

    const cleanAgencyName = String(agencyName).trim();
    const cleanPhone = String(phone || "").trim();
    const cleanCity = String(city || "Beograd").trim();
    const cleanLocale = ["sr", "sr-Cyrl", "en", "ru", "tr"].includes(locale)
      ? locale
      : "sr";

    // 4. Generate secure HMAC-signed token & 7-day expiration
    const expTime = Date.now() + 7 * 24 * 60 * 60 * 1000;
    const expiresAt = new Date(expTime).toISOString();
    const payload = {
      a: cleanAgencyName,
      e: cleanEmail,
      p: cleanPhone,
      c: cleanCity,
      exp: expTime,
      f: validFocus,
      m: validModules,
      l: cleanLocale,
      r: crypto.randomBytes(6).toString("hex"),
    };
    const payloadB64 = Buffer.from(JSON.stringify(payload)).toString("base64url");
    const signature = crypto
      .createHmac("sha256", TOKEN_SECRET)
      .update(payloadB64)
      .digest("hex")
      .slice(0, 32);
    const token = `${payloadB64}.${signature}`;

    // 5. Insert into agency_demo_sessions table
    try {
      const { error: dbError } = await supabase
        .from("agency_demo_sessions")
        .insert([
          {
            token,
            agency_name: cleanAgencyName,
            email: cleanEmail,
            phone: cleanPhone || null,
            city: cleanCity,
            expires_at: expiresAt,
          },
        ]);

      if (dbError) {
        console.warn("Could not insert agency_demo_session:", dbError.message);
      }
    } catch (dbErr) {
      console.warn("DB error in agency-demo insert:", dbErr);
    }

    // 6. ZZPL Consent Logging (Section 7)
    if (marketingConsent) {
      try {
        const { error: consentErr } = await supabase
          .from("agency_demo_consents")
          .insert([
            {
              email: cleanEmail,
              agency_name: cleanAgencyName,
              phone: cleanPhone || null,
              city: cleanCity,
              marketing_consent: true,
              consent_text_key: "consent.marketing",
              consent_text_version: "v1.0",
              shown_locale: cleanLocale,
              ip_address: ip,
              user_agent: userAgent,
            },
          ]);
        if (consentErr) {
          console.warn("Consent logging error:", consentErr.message);
        }
      } catch (cErr) {
        console.warn("Consent insert failed:", cErr);
      }
    }

    // 7. Construct Magic Link (retains user locale)
    const host =
      request.headers.get("x-forwarded-host") ||
      request.headers.get("host") ||
      "www.stanomer.online";
    const protocol = host.includes("localhost") ? "http" : "https";
    const magicLink = `${protocol}://${host}/agency-panel?demo_token=${token}&lang=${cleanLocale}`;

    // 8. Send Emails via Brevo API
    const apiKey = process.env.BREVO_API_KEY || "";
    const senderEmail = process.env.BREVO_SENDER_EMAIL || "atilbilge@gmail.com";
    const senderName = process.env.BREVO_SENDER_NAME || "Stanomer";
    const adminNotificationEmail =
      process.env.ADMIN_NOTIFICATION_EMAIL || "atilbilge@gmail.com";

    if (apiKey) {
      // 8a. Admin Notification Email
      const focusLabel =
        validFocus === "presales"
          ? "Oglasi i portali (Pre-sales)"
          : validFocus === "aftersales"
          ? "Upravljanje izdavanjem (After-sales)"
          : "Oba modula (Full Suite)";
      const consentBadge = marketingConsent
        ? "✅ PAZARLAMA / TEKLİF İLETİŞİMİ İZNİ VERİLDİ"
        : "⚠️ YALNIZCA DEMO ERİŞİMİ (Pazarlama İletişimi İzni Yok)";
      const adminSubject = `🔥 [Stanomer Lead] Yeni Acente Demo Başlattı: ${cleanAgencyName} (${cleanCity}) [${validFocus.toUpperCase()}]`;
      const cleanPhoneDigits = cleanPhone.replace(/[^\d+]/g, "");
      const waLink = cleanPhoneDigits
        ? `https://wa.me/${cleanPhoneDigits.replace(/^\+/, "")}`
        : null;

      const adminHtmlContent = `
        <!DOCTYPE html>
        <html>
        <body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background-color: #f8fafc; padding: 24px; color: #0f172a;">
          <div style="max-width: 600px; margin: 0 auto; background: #ffffff; border-radius: 16px; border: 1px solid #e2e8f0; overflow: hidden; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.05);">
            <div style="background: linear-gradient(135deg, #1e3a8a, #2563eb); padding: 24px; color: #ffffff;">
              <span style="font-size: 11px; text-transform: uppercase; letter-spacing: 0.1em; background: rgba(255,255,255,0.25); padding: 4px 10px; border-radius: 999px; font-weight: 700;">
                Yeni Acente Demo Sandbox
              </span>
              <h1 style="margin: 12px 0 0 0; font-size: 22px; font-weight: 700;">
                ${escapeHtml(cleanAgencyName)}
              </h1>
              <p style="margin: 4px 0 0 0; font-size: 13px; opacity: 0.9;">
                Şehir: ${escapeHtml(cleanCity)} &bull; Süre: 7 Günlük Test &bull; Dil: ${escapeHtml(cleanLocale)}
              </p>
            </div>

            <div style="padding: 24px;">
              <div style="margin-bottom: 16px; padding: 10px 14px; border-radius: 8px; font-size: 12px; font-weight: 600; ${
                marketingConsent
                  ? "background: #ecfdf5; color: #065f46; border: 1px solid #a7f3d0;"
                  : "background: #fef3c7; color: #92400e; border: 1px solid #fde68a;"
              }">
                ${consentBadge}
              </div>

              <table style="width: 100%; border-collapse: collapse; font-size: 13px;">
                <tr>
                  <td style="padding: 10px 0; border-bottom: 1px solid #f1f5f9; color: #64748b; font-weight: 600; width: 140px;">Acente Adı</td>
                  <td style="padding: 10px 0; border-bottom: 1px solid #f1f5f9; color: #0f172a; font-weight: 700;">${escapeHtml(cleanAgencyName)}</td>
                </tr>
                <tr>
                  <td style="padding: 10px 0; border-bottom: 1px solid #f1f5f9; color: #64748b; font-weight: 600;">E-posta</td>
                  <td style="padding: 10px 0; border-bottom: 1px solid #f1f5f9; color: #0f172a;">
                    <a href="mailto:${escapeHtml(cleanEmail)}" style="color: #2563eb; text-decoration: none;">${escapeHtml(cleanEmail)}</a>
                  </td>
                </tr>
                <tr>
                  <td style="padding: 10px 0; border-bottom: 1px solid #f1f5f9; color: #64748b; font-weight: 600;">Telefon</td>
                  <td style="padding: 10px 0; border-bottom: 1px solid #f1f5f9; color: #0f172a;">
                    ${escapeHtml(cleanPhone || "Belirtilmedi")}
                    ${waLink ? ` &bull; <a href="${waLink}" style="color: #059669; font-weight: 600; text-decoration: none;">WhatsApp Aç</a>` : ""}
                  </td>
                </tr>
                <tr>
                  <td style="padding: 10px 0; border-bottom: 1px solid #f1f5f9; color: #64748b; font-weight: 600;">Faaliyet Şehri</td>
                  <td style="padding: 10px 0; border-bottom: 1px solid #f1f5f9; color: #0f172a;">${escapeHtml(cleanCity)}</td>
                </tr>
                <tr>
                  <td style="padding: 10px 0; border-bottom: 1px solid #f1f5f9; color: #64748b; font-weight: 600;">Seçilen Modül</td>
                  <td style="padding: 10px 0; border-bottom: 1px solid #f1f5f9; color: #0f172a;">${escapeHtml(focusLabel)}</td>
                </tr>
                <tr>
                  <td style="padding: 10px 0; color: #64748b; font-weight: 600;">Oturum Magic Link</td>
                  <td style="padding: 10px 0; color: #0f172a;">
                    <a href="${magicLink}" style="color: #2563eb; word-break: break-all; font-size: 11px;">${magicLink}</a>
                  </td>
                </tr>
              </table>
            </div>
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
            to: [{ email: adminNotificationEmail, name: "Stanomer Ekibi" }],
            subject: adminSubject,
            htmlContent: adminHtmlContent,
          }),
        });
      } catch (adminMailErr) {
        console.error("Failed to send admin demo notification:", adminMailErr);
      }

      // Initial demo launch: User directly enters in-memory sandbox without waiting for an email.
      // Magic Link verification email will only be dispatched when user performs a mutating action or accepts the 7-day save nudge.
    }

    return NextResponse.json({
      success: true,
      token,
      expiresAt,
      magicLink,
      agencyName: cleanAgencyName,
      focus: validFocus,
      locale: cleanLocale,
    });
  } catch (err: unknown) {
    console.error("agency-demo POST error:", err);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 }
    );
  }
}

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const token = searchParams.get("token");

    if (!token || typeof token !== "string" || !token.trim()) {
      return NextResponse.json({ valid: false, error: "Missing token" }, { status: 400 });
    }

    const trimmed = token.trim();

    // 1. First priority: Verify HMAC-signed self-contained token (100% resilient, zero DB dependency)
    if (trimmed.includes(".")) {
      const [payloadB64, sig] = trimmed.split(".");
      if (payloadB64 && sig) {
        const expectedSig = crypto
          .createHmac("sha256", TOKEN_SECRET)
          .update(payloadB64)
          .digest("hex")
          .slice(0, 32);

        if (sig === expectedSig) {
          try {
            const rawJson = Buffer.from(payloadB64, "base64url").toString("utf-8");
            const payload = JSON.parse(rawJson);

            const now = Date.now();
            if (now > payload.exp) {
              return NextResponse.json({
                valid: false,
                expired: true,
                agencyName: payload.a,
                expiresAt: new Date(payload.exp).toISOString(),
              });
            }

            // Valid signed token!
            return NextResponse.json({
              valid: true,
              session: {
                agencyName: payload.a,
                email: payload.e,
                phone: payload.p,
                city: payload.c,
                expiresAt: new Date(payload.exp).toISOString(),
                focus: payload.f || "both",
                active_modules: payload.m || (
                  payload.f === "presales"
                    ? ["portfolio_distribution"]
                    : payload.f === "aftersales"
                    ? ["property_lease_management"]
                    : ["portfolio_distribution", "property_lease_management"]
                ),
                locale: payload.l || "sr",
              },
            });
          } catch (parseErr) {
            console.warn("Invalid signed token JSON payload:", parseErr);
          }
        }
      }
    }

    // 2. Fallback: Database lookup
    try {
      const { data, error } = await supabase
        .from("agency_demo_sessions")
        .select("id, agency_name, email, phone, city, expires_at")
        .eq("token", trimmed)
        .single();

      if (!error && data) {
        const now = new Date();
        const expiresAt = new Date(data.expires_at);

        if (now > expiresAt) {
          return NextResponse.json({
            valid: false,
            expired: true,
            agencyName: data.agency_name,
            expiresAt: data.expires_at,
          });
        }

        // Update last_accessed_at in background
        supabase
          .from("agency_demo_sessions")
          .update({ last_accessed_at: now.toISOString() })
          .eq("token", trimmed)
          .then();

        return NextResponse.json({
          valid: true,
          session: {
            agencyName: data.agency_name,
            email: data.email,
            phone: data.phone,
            city: data.city,
            expiresAt: data.expires_at,
          },
        });
      }
    } catch (dbErr) {
      console.warn("DB lookup error in agency-demo GET:", dbErr);
    }

    return NextResponse.json({ valid: false, notFound: true });
  } catch (err: unknown) {
    console.error("agency-demo GET error:", err);
    return NextResponse.json(
      { valid: false, error: "Internal server error" },
      { status: 500 }
    );
  }
}
