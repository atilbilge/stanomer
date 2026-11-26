// api/send-demo-verification.ts
// Vercel Edge Function for sending 7-day Agency Demo magic-link verification emails via Brevo
// Deployed automatically by Vercel under /api/send-demo-verification

export const config = {
  runtime: "edge",
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
  "Content-Type": "application/json",
};

function jsonResponse(payload: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: corsHeaders,
  });
}

const emailTranslations: Record<
  string,
  {
    subject: string;
    greeting: string;
    text: string;
    btn: string;
    fallback: string;
    footer: string;
  }
> = {
  TR: {
    subject: "🚀 Stanomer Acente Paneliniz Hazır! (7 Günlük Tam Yetkili Giriş)",
    greeting: "Sayın",
    text: "Acenteniz için 7 günlük kişiselleştirilmiş interaktif demo paneliniz hazırlandı. Şifreye ihtiyaç duymadan, aşağıdaki butona tıklayarak doğrudan acente kokpitinize bağlanabilir; yaptığınız tüm işlemleri güvenle saklayabilirsiniz:",
    btn: "🎯 Acente Panelime Doğrudan Giriş Yap (Magic Link)",
    fallback: "Buton çalışmıyorsa aşağıdaki doğrudan giriş bağlantısını tarayıcınıza kopyalayabilirsiniz:",
    footer: "Bu bağlantı acentenize özel tek tıkla giriş sağlayan güvenli magic linktir. 7 günlük ücretsiz demo süreniz bağlantıyı ilk açtığınız an başlar.",
  },
  EN: {
    subject: "🚀 Your Stanomer Agency Panel is Ready! (7-Day Full Access Magic Link)",
    greeting: "Dear",
    text: "Your 7-day branded agency demo panel is ready. No password required! Click the button below to log directly into your agency cockpit and keep all your changes safely stored:",
    btn: "🎯 Launch Agency Cockpit (Magic Link)",
    fallback: "If the button above does not work, copy and paste this direct access link into your browser:",
    footer: "This is a secure one-click magic link generated for your agency. Your 7-day free demo begins upon your first login.",
  },
  SR_LAT: {
    subject: "🚀 Vaš Stanomer Agencijski Panel je Spreman! (7-dnevna prijava jednim klikom)",
    greeting: "Poštovani",
    text: "Vaš 7-dnevni personalizovani interaktivni demo panel za agenciju je pripremljen. Bez potrebe za lozinkom, kliknite na dugme ispod da se direktno prijavite u agencijski kokpit i bezbedno sačuvate sve podatke:",
    btn: "🎯 Otvorite Agencijski Panel (Magic Link)",
    fallback: "Ako dugme ne radi, kopirajte sledeći link za direktnu prijavu u vaš pregledač:",
    footer: "Ovaj link je bezbedan jednokratni magic link kreiran za vašu agenciju. Vaš 7-dnevni besplatan demo period počinje prvim ulaskom.",
  },
  SR_CYR: {
    subject: "🚀 Ваш Станомер Агенцијски Панел је Спреман! (7-дневна пријава једним кликом)",
    greeting: "Поштовани",
    text: "Ваш 7-дневни персонализовани интерактивни демо панел за агенцију је припремљен. Без потребе за лозинком, кликните на дугме испод да се директно пријавите у агенцијски кокпит и безбедно сачувате све податке:",
    btn: "🎯 Отворите Агенцијски Панел (Magic Link)",
    fallback: "Ако дугме не ради, копирајте следећи линк за директну пријаву у ваш прегледач:",
    footer: "Овај линк је безбедан једнократни magic link креиран за вашу агенцију. Ваш 7-дневни бесплатан демо период почиње првим уласком.",
  },
  RU: {
    subject: "🚀 Ваша Панель Stanomer для Агентства Готова! (Вход в один клик на 7 дней)",
    greeting: "Уважаемый(ая)",
    text: "Ваша 7-дневная персонализированная демо-панель для агентства готова. Без ввода пароля нажмите кнопку ниже, чтобы напрямую войти в панель управления и сохранить все ваши данные:",
    btn: "🎯 Войти в Панель Агентства (Magic Link)",
    fallback: "Если кнопка не работает, скопируйте следующую ссылку для прямого входа в браузер:",
    footer: "Это безопасная ссылка прямого доступа (magic link) для вашего агентства. 7-дневный тестовый период начинается с первого входа.",
  },
};

interface RateLimitRecord {
  count: number;
  resetAt: number;
}

const rateLimitMap = new Map<string, RateLimitRecord>();
const RATE_LIMIT_WINDOW_MS = 60 * 60 * 1000;
const MAX_REQUESTS_PER_WINDOW = 5;

function getClientIp(request: Request): string {
  const xForwardedFor = request.headers.get("x-forwarded-for");
  if (xForwardedFor) return xForwardedFor.split(",")[0].trim();
  const xRealIp = request.headers.get("x-real-ip");
  if (xRealIp) return xRealIp.trim();
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

function resolveOrigin(request: Request): string {
  const candidate = request.headers.get("origin") || request.headers.get("referer") || "";
  if (candidate) {
    try {
      return new URL(candidate).origin;
    } catch {
      // fallback below
    }
  }
  return "https://www.stanomer.online";
}

function escapeHtml(str: string): string {
  return String(str || "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

export async function handler(request: Request): Promise<Response> {
  if (request.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  if (request.method !== "POST") {
    return jsonResponse({ success: false, message: "Method not allowed" }, 405);
  }

  try {
    const body = await request.json();
    const { email, agencyName, website, phone, verificationToken, lang, honeypot } = body || {};

    if (honeypot && typeof honeypot === "string" && honeypot.trim().length > 0) {
      return jsonResponse({ success: true, message: "Processed successfully." });
    }

    const clientIp = getClientIp(request);
    if (checkRateLimit(clientIp)) {
      const isTR = lang === "TR";
      const isSR = lang === "SR_LAT" || lang === "SR_CYR";
      return jsonResponse(
        {
          success: false,
          message: isTR
            ? "Çok fazla demo talebi gönderildi. Lütfen 1 saat sonra tekrar deneyiniz."
            : isSR
              ? "Previše zahteva za demo. Molimo pokušajte ponovo za 1 sat."
              : "Too many demo requests from this IP. Please try again in 1 hour.",
        },
        429
      );
    }

    if (!email) {
      return jsonResponse({ success: false, message: "Email is required." }, 400);
    }

    let token = verificationToken;
    if (!token) {
      const devSupabaseUrl = "https://nbcbfmhztnnhfnapvaet.supabase.co";
      const devSupabaseKey = "sb_publishable_kY2aoizXZkGz2DsG6-sg-Q_Vm2Ef2mq";

      const formattedWebsite =
        website && typeof website === "string" && website.trim()
          ? /^https?:\/\//i.test(website.trim())
            ? website.trim()
            : `https://${website.trim()}`
          : null;

      const formattedPhone =
        phone && typeof phone === "string" && phone.trim() ? phone.trim() : null;

      const dbRes = await fetch(`${devSupabaseUrl}/rest/v1/agency_demo_requests`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          apikey: devSupabaseKey,
          Authorization: `Bearer ${devSupabaseKey}`,
          Prefer: "return=representation",
        },
        body: JSON.stringify({
          agency_name: String(agencyName || "Agency").trim(),
          email: String(email).toLowerCase().trim(),
          phone_number: formattedPhone,
          website: formattedWebsite,
          status: "pending",
        }),
      });

      if (!dbRes.ok) {
        const errText = await dbRes.text();
        console.error("DB insert error in send-demo-verification:", errText);
        throw new Error("Could not save demo verification request.");
      }

      const dbData = await dbRes.json();
      token = Array.isArray(dbData) && dbData.length > 0 ? dbData[0].verification_token : null;
    }

    if (!token) {
      throw new Error("Could not generate verification link.");
    }

    const selectedLang = lang && emailTranslations[lang] ? lang : "TR";
    const tEmail = emailTranslations[selectedLang];

    const apiKey = process.env.BREVO_API_KEY || "";
    const senderEmail = process.env.BREVO_SENDER_EMAIL || "atilbilge@gmail.com";
    const senderName = process.env.BREVO_SENDER_NAME || "Stanomer";

    if (!apiKey) {
      return jsonResponse({ success: false, message: "Email service is not configured." }, 500);
    }

    const origin = resolveOrigin(request);
    const verifyUrl = `${origin}/agency-demo/verify?token=${encodeURIComponent(String(token))}&lang=${encodeURIComponent(selectedLang)}`;
    const safeAgencyName = escapeHtml(String(agencyName || "Agency"));
    const safeEmail = escapeHtml(String(email));

    const htmlContent = `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <title>Stanomer - Email Verification</title>
        <style>
          body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f8fafc; color: #1e293b; margin: 0; padding: 0; }
          .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1); border: 1px solid #e2e8f0; }
          .header { background-color: #1B5888; padding: 32px; text-align: center; color: #ffffff; }
          .header h1 { margin: 0; font-size: 28px; font-weight: 800; letter-spacing: -0.5px; }
          .content { padding: 40px 32px; text-align: center; }
          .content h2 { font-size: 22px; color: #0f172a; margin-top: 0; }
          .content p { font-size: 16px; line-height: 1.6; color: #475569; margin-bottom: 28px; }
          .btn { display: inline-block; background-color: #1B5888; color: #ffffff !important; font-weight: 700; font-size: 16px; padding: 14px 32px; border-radius: 12px; text-decoration: none; }
          .footer { background-color: #f1f5f9; padding: 20px 32px; text-align: center; font-size: 13px; color: #94a3b8; border-top: 1px solid #e2e8f0; }
          .link-box { margin-top: 24px; padding: 12px; background: #f8fafc; border: 1px solid #cbd5e1; border-radius: 8px; word-break: break-all; font-size: 12px; color: #64748b; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>Stanomer</h1>
          </div>
          <div class="content">
            <h2>${tEmail.subject}</h2>
            <p>${tEmail.greeting} <strong>${safeAgencyName}</strong>,</p>
            <p>${tEmail.text}</p>
            <a href="${verifyUrl}" target="_blank" class="btn">${tEmail.btn}</a>
            <div class="link-box">
              ${tEmail.fallback}<br>
              <a href="${verifyUrl}" style="color: #1B5888;">${verifyUrl}</a>
            </div>
          </div>
          <div class="footer">
            &copy; 2026 Stanomer. ${tEmail.footer}
          </div>
        </div>
      </body>
      </html>
    `;

    const brevoResponse = await fetch("https://api.brevo.com/v3/smtp/email", {
      method: "POST",
      headers: {
        accept: "application/json",
        "content-type": "application/json",
        "api-key": apiKey,
      },
      body: JSON.stringify({
        sender: { name: senderName, email: senderEmail },
        to: [{ email, name: agencyName || email }],
        subject: tEmail.subject,
        htmlContent,
      }),
    });

    const brevoData = await brevoResponse.json().catch(() => ({}));

    if (!brevoResponse.ok) {
      console.error("Brevo Email Error:", brevoData);
      return jsonResponse(
        {
          success: false,
          message: brevoData.message || "Brevo error.",
          details: brevoData,
        },
        brevoResponse.status
      );
    }

    try {
      await fetch("https://api.brevo.com/v3/smtp/email", {
        method: "POST",
        headers: {
          accept: "application/json",
          "content-type": "application/json",
          "api-key": apiKey,
        },
        body: JSON.stringify({
          sender: { name: "Stanomer Notification", email: senderEmail },
          to: [{ email: "atilbilge@gmail.com", name: "Atil Bilge" }],
          subject: `🚀 Yeni Acente Magic Link Talebi: ${agencyName || "Acente"} (${email})`,
          htmlContent: `
            <div style="font-family: sans-serif; max-width: 500px; padding: 20px; border: 1px solid #e2e8f0; border-radius: 12px;">
              <h2 style="color: #1B5888; margin-top: 0;">🎉 Yeni Acente Demo Talebi (Magic Link)</h2>
              <p>Web sitesinden yeni bir acente demo talebi alındı ve kullanıcıya tek tıkla giriş sağlayan <strong>magic link</strong> e-postası gönderildi.</p>
              <table style="width: 100%; border-collapse: collapse; margin-top: 15px;">
                <tr><td style="padding: 8px 0; color: #64748b;"><strong>Acente Adı:</strong></td><td>${safeAgencyName}</td></tr>
                <tr><td style="padding: 8px 0; color: #64748b;"><strong>E-posta:</strong></td><td><a href="mailto:${safeEmail}">${safeEmail}</a></td></tr>
                <tr><td style="padding: 8px 0; color: #64748b;"><strong>Telefon:</strong></td><td>${escapeHtml(String(phone || "-"))}</td></tr>
                <tr><td style="padding: 8px 0; color: #64748b;"><strong>Web Sitesi:</strong></td><td>${escapeHtml(String(website || "-"))}</td></tr>
                <tr><td style="padding: 8px 0; color: #64748b;"><strong>Dil:</strong></td><td>${escapeHtml(selectedLang)}</td></tr>
                <tr><td style="padding: 8px 0; color: #64748b;"><strong>Tarih:</strong></td><td>${new Date().toLocaleString("tr-TR")}</td></tr>
              </table>
              <div style="margin-top: 20px; padding: 12px; background: #f8fafc; border-radius: 8px; font-size: 12px; color: #475569;">
                Magic Link (Doğrudan Giriş): <a href="${verifyUrl}" style="color: #1B5888;">${verifyUrl}</a>
              </div>
            </div>
          `,
        }),
      });
    } catch (adminErr) {
      console.warn("Admin notification email failed (non-critical):", adminErr);
    }

    return jsonResponse({
      success: true,
      message: "Verification email sent.",
      messageId: brevoData.messageId,
    });
  } catch (error: any) {
    console.error("Send Demo Verification Error:", error);
    return jsonResponse({ success: false, message: error?.message || "Server error." }, 500);
  }
}

export { handler as POST };
export default handler;
