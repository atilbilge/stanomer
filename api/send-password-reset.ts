// api/send-password-reset.ts
// Vercel Edge Function for sending localized Agency Panel password reset emails via Brevo
// Deployed automatically by Vercel under /api/send-password-reset

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

function escapeHtml(str: string): string {
  return String(str || "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

interface ResetEmailCopy {
  subject: string;
  badge: string;
  heading: string;
  greeting: string;
  body: string;
  codeLabel: string;
  buttonLabel: string;
  expiryNote: string;
  footer: string;
}

function getCopy(locale: string, name: string): ResetEmailCopy {
  const safeName = name ? escapeHtml(name) : "";
  switch (locale) {
    case "TR":
      return {
        subject: "Stanomer Acente Paneli — Şifre Sıfırlama Kodu",
        badge: "Güvenlik",
        heading: "Şifrenizi Sıfırlayın",
        greeting: safeName ? `Merhaba ${safeName},` : "Merhaba,",
        body: "Stanomer Acente Paneli hesabınız için şifre sıfırlama talebi aldık. Aşağıdaki 6 haneli doğrulama kodunu ekrana girebilir veya doğrudan butona tıklayarak şifrenizi yenileyebilirsiniz.",
        codeLabel: "6 Haneli Doğrulama Kodu",
        buttonLabel: "Acente Panelinde Şifreyi Yenile",
        expiryNote: "Bu kod ve bağlantı 1 saat geçerlidir. Bu talebi siz oluşturmadıysanız bu e-postayı dikkate almayın.",
        footer: "Stanomer Agency Panel • Otomatik Güvenlik Bildirimi",
      };
    case "SR_LAT":
      return {
        subject: "Stanomer Agencijski Panel — Kod za resetovanje lozinke",
        badge: "Bezbednost",
        heading: "Resetujte svoju lozinku",
        greeting: safeName ? `Zdravo ${safeName},` : "Zdravo,",
        body: "Primili smo zahtev za resetovanje lozinke za vaš Stanomer Agencijski Panel nalog. Unesite 6-cifreni kod ispod ili kliknite na dugme da odmah postavite novu lozinku.",
        codeLabel: "6-cifreni verifikacioni kod",
        buttonLabel: "Resetuj lozinku na panelu",
        expiryNote: "Kod i link važe 1 sat. Ako niste vi zatražili promenu, ignorišite ovaj imejl.",
        footer: "Stanomer Agency Panel • Automatsko bezbednosno obaveštenje",
      };
    case "SR_CYR":
      return {
        subject: "Stanomer Агенцијски Панел — Код за ресетовање лозинке",
        badge: "Безбедност",
        heading: "Ресетујте своју лозинку",
        greeting: safeName ? `Здраво ${safeName},` : "Здраво,",
        body: "Примили смо захтев за ресетовање лозинке за ваш Stanomer Агенцијски Панел налог. Унесите 6-цифрени код испод или кликните на дугме да одмах поставите нову лозинку.",
        codeLabel: "6-цифрени верификациони код",
        buttonLabel: "Ресетуј лозинку на панелу",
        expiryNote: "Код и линк важе 1 сат. Ако нисте ви затражили промену, игноришите овај имејл.",
        footer: "Stanomer Agency Panel • Аутоматско безбедносно обавештење",
      };
    case "RU":
      return {
        subject: "Stanomer Панель Агентства — Код сброса пароля",
        badge: "Безопасность",
        heading: "Сброс пароля",
        greeting: safeName ? `Здравствуйте, ${safeName},` : "Здравствуйте,",
        body: "Мы получили запрос на сброс пароля для вашего аккаунта Stanomer. Введите 6-значный код ниже на странице входа или нажмите кнопку, чтобы задать новый пароль.",
        codeLabel: "6-значный код подтверждения",
        buttonLabel: "Сбросить пароль в панели",
        expiryNote: "Код и ссылка действительны 1 час. Если вы не запрашивали сброс, проигнорируйте это письмо.",
        footer: "Stanomer Agency Panel • Автоматическое уведомление безопасности",
      };
    default:
      return {
        subject: "Stanomer Agency Panel — Password Reset Code",
        badge: "Security",
        heading: "Reset Your Password",
        greeting: safeName ? `Hello ${safeName},` : "Hello,",
        body: "We received a password reset request for your Stanomer Agency Panel account. Enter the 6-digit verification code below or click the button to set a new password directly in the Agency Panel.",
        codeLabel: "6-Digit Verification Code",
        buttonLabel: "Reset Password in Agency Panel",
        expiryNote: "This code and link expire in 1 hour. If you did not request this, you can safely ignore this email.",
        footer: "Stanomer Agency Panel • Automated Security Notice",
      };
  }
}

export async function handler(req: Request): Promise<Response> {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  try {
    const body = await req.json();
    const email = String(body?.email || "").trim().toLowerCase();
    const name = String(body?.name || "").trim();
    const code = String(body?.code || "").trim();
    const token = String(body?.token || "").trim();
    const locale = String(body?.locale || "EN").toUpperCase();
    const origin = String(body?.origin || "https://www.stanomer.online").replace(/\/+$/, "");

    if (!email || !code || !token) {
      return jsonResponse({ error: "Missing required password reset fields." }, 400);
    }

    const apiKey = process.env.BREVO_API_KEY || "";
    const senderEmail = process.env.BREVO_SENDER_EMAIL || "atilbilge@gmail.com";
    const senderName = process.env.BREVO_SENDER_NAME || "Stanomer";

    if (!apiKey) {
      return jsonResponse({ error: "Email service is not configured." }, 500);
    }

    const copy = getCopy(locale, name);
    const resetLink = `${origin}/agency-panel?reset_token=${encodeURIComponent(token)}&reset_email=${encodeURIComponent(email)}`;

    const htmlContent = `
      <!DOCTYPE html>
      <html>
      <head><meta charset="utf-8"></head>
      <body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #f8f7f5; margin: 0; padding: 24px; color: #1a1a1a;">
        <div style="max-width: 560px; margin: 0 auto; background: #ffffff; border-radius: 14px; border: 1px solid #e5e3df; overflow: hidden;">
          <div style="background: #1B5888; padding: 24px 28px; color: #ffffff;">
            <span style="font-size: 11px; text-transform: uppercase; letter-spacing: 0.08em; background: rgba(255,255,255,0.18); padding: 4px 10px; border-radius: 999px; font-weight: 600;">
              ${copy.badge}
            </span>
            <h1 style="margin: 12px 0 0 0; font-size: 20px; font-weight: 700;">
              ${copy.heading}
            </h1>
          </div>
          <div style="padding: 28px;">
            <p style="margin: 0 0 12px 0; font-size: 14px; font-weight: 600; color: #1a1a1a;">${copy.greeting}</p>
            <p style="margin: 0 0 22px 0; font-size: 13.5px; line-height: 1.6; color: #4a4a4a;">${copy.body}</p>

            <div style="background: #f8f7f5; border: 1px solid #e5e3df; border-radius: 10px; padding: 16px; text-align: center; margin-bottom: 22px;">
              <div style="font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.06em; color: #666666; margin-bottom: 8px;">
                ${copy.codeLabel}
              </div>
              <div style="font-family: ui-monospace, SFMono-Regular, Menlo, monospace; font-size: 28px; font-weight: 800; letter-spacing: 0.25em; color: #1B5888;">
                ${escapeHtml(code)}
              </div>
            </div>

            <div style="text-align: center; margin-bottom: 22px;">
              <a href="${resetLink}" style="display: inline-block; background: #1B5888; color: #ffffff; text-decoration: none; font-size: 13.5px; font-weight: 700; padding: 12px 24px; border-radius: 10px;">
                ${copy.buttonLabel}
              </a>
            </div>

            <p style="margin: 0; font-size: 12px; line-height: 1.5; color: #666666;">
              ${copy.expiryNote}
            </p>
          </div>
          <div style="background: #f8f7f5; border-top: 1px solid #e5e3df; padding: 14px 24px; text-align: center; font-size: 11px; color: #8a8a8a;">
            ${copy.footer}
          </div>
        </div>
      </body>
      </html>
    `;

    const brevoRes = await fetch("https://api.brevo.com/v3/smtp/email", {
      method: "POST",
      headers: {
        accept: "application/json",
        "content-type": "application/json",
        "api-key": apiKey,
      },
      body: JSON.stringify({
        sender: { name: senderName, email: senderEmail },
        to: [{ email, name: name || email }],
        subject: copy.subject,
        htmlContent,
      }),
    });

    if (!brevoRes.ok) {
      const errTxt = await brevoRes.text().catch(() => "");
      console.error("Brevo password reset error:", brevoRes.status, errTxt);
      return jsonResponse({ error: "Failed to send password reset email." }, 502);
    }

    return jsonResponse({ success: true });
  } catch (err: any) {
    console.error("send-password-reset route error:", err);
    return jsonResponse({ error: err?.message || "Internal server error" }, 500);
  }
}

export { handler as POST };
export default handler;
