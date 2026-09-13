/**
 * Stanomer Agency Demo Client Service
 * 
 * Handles demo request submissions and magic link email delivery directly
 * from the client browser. Compatible with static hosting and serverless deployments.
 */

const DEV_SUPABASE_URL =
  process.env.NEXT_PUBLIC_SUPABASE_URL || "https://thvbpifahvasyzmngpzp.supabase.co";
const DEV_SUPABASE_KEY =
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ||
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRodmJwaWZhaHZhc3l6bW5ncHpwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODUyNjAxNzcsImV4cCI6MjEwMDgzNjE3N30.dNSz66kJcoSjflgCCrS7qw55efuDxF61TEMoYc3r4qU";

const BREVO_API_KEY =
  process.env.NEXT_PUBLIC_BREVO_API_KEY ||
  process.env.BREVO_API_KEY ||
  "";
const BREVO_SENDER_EMAIL =
  process.env.NEXT_PUBLIC_BREVO_SENDER_EMAIL ||
  process.env.BREVO_SENDER_EMAIL ||
  "atilbilge@gmail.com";
const BREVO_SENDER_NAME =
  process.env.NEXT_PUBLIC_BREVO_SENDER_NAME ||
  process.env.BREVO_SENDER_NAME ||
  "Stanomer";

const emailTranslations: Record<
  string,
  { subject: string; greeting: string; text: string; btn: string; fallback: string; footer: string }
> = {
  TR: {
    subject: "🚀 Stanomer Acente Paneliniz Hazır! (Tek Tıkla Giriş)",
    greeting: "Sayın",
    text: "Acenteniz için 3 günlük kişiselleştirilmiş interaktif demo paneliniz hazırlandı. Şifreye ihtiyaç duymadan, aşağıdaki butona tıklayarak doğrudan acente kokpitinize bağlanabilir; logonuzu ve kurumsal renklerinizi web sitenizden çekerek tek tıkla örnek portföy üretebilirsiniz:",
    btn: "🎯 Acente Panelime Doğrudan Giriş Yap (Magic Link)",
    fallback: "Buton çalışmıyorsa aşağıdaki doğrudan giriş bağlantısını tarayıcınıza kopyalayabilirsiniz:",
    footer: "Bu bağlantı acentenize özel tek tıkla giriş sağlayan güvenli magic linktir. 3 günlük ücretsiz sandbox süreniz bağlantıyı ilk açtığınız an başlar."
  },
  EN: {
    subject: "🚀 Your Stanomer Agency Panel is Ready! (One-Click Magic Link)",
    greeting: "Dear",
    text: "Your 3-day branded agency demo sandbox is ready. No password required! Click the button below to log directly into your agency cockpit, automatically fetch your logo & brand colors, and generate a full sample portfolio with a single click:",
    btn: "🎯 Launch Agency Cockpit (Magic Link)",
    fallback: "If the button above does not work, copy and paste this direct access link into your browser:",
    footer: "This is a secure one-click magic link generated for your agency. Your 3-day free sandbox begins upon your first login."
  },
  SR_LAT: {
    subject: "🚀 Vaš Stanomer Agencijski Panel je Spreman! (Prijava Jednim Klikom)",
    greeting: "Poštovani",
    text: "Vaš 3-dnevni personalizovani interaktivni demo panel za agenciju je pripremljen. Bez potrebe za lozinkom, kliknite na dugme ispod da se direktno prijavite u agencijski kokpit, preuzmete logo i boje sa vašeg sajta i jednim klikom generišete primer portfolija:",
    btn: "🎯 Otvorite Agencijski Panel (Magic Link)",
    fallback: "Ako dugme ne radi, kopirajte sledeći link za direktnu prijavu u vaš pregledač:",
    footer: "Ovaj link je bezbedan jednokratni magic link kreiran za vašu agenciju. Vaš 3-dnevni besplatan sandbox period počinje prvim ulaskom."
  },
  SR_CYR: {
    subject: "🚀 Ваш Станомер Агенцијски Панел је Спреман! (Пријава Једним Кликом)",
    greeting: "Поштовани",
    text: "Ваш 3-дневни персонализовани интерактивни демо панел за агенцију је припремљен. Без потребе за лозинком, кликните на дугме испод да се директно пријавите у агенцијски кокпит, преузмете лого и боје са вашег сајта и једним кликом генеришете пример портфолија:",
    btn: "🎯 Отворите Агенцијски Панел (Magic Link)",
    fallback: "Ако дугме не ради, копирајте следећи линк за директну пријаву у ваш прегледач:",
    footer: "Овај линк је безбедан једнократни magic link креиран за вашу агенцију. Ваш 3-дневни бесплатан sandbox период почиње првим уласком."
  },
  RU: {
    subject: "🚀 Ваша Панель Stanomer для Агентства Готова! (Вход в Один Клик)",
    greeting: "Уважаемый(ая)",
    text: "Ваша 3-дневная персонализированная демо-панель для агентства готова. Без ввода пароля нажмите кнопку ниже, чтобы напрямую войти в панель управления, автоматически загрузить ваш логотип и цвета и в один клик создать тестовое портфолио:",
    btn: "🎯 Войти в Панель Агентства (Magic Link)",
    fallback: "Если кнопка не работает, скопируйте следующую ссылку для прямого входа в браузер:",
    footer: "Это безопасная ссылка прямого доступа (magic link) для вашего агентства. 3-дневный тестовый период начинается с первого входа."
  }
};

export interface SendDemoVerificationParams {
  email: string;
  agencyName: string;
  website?: string | null;
  lang?: string;
  honeypot?: string;
  verificationToken?: string;
}

export async function sendDemoVerification(params: SendDemoVerificationParams): Promise<{
  success: boolean;
  message?: string;
  token?: string;
}> {
  const { email, agencyName, website, lang = "TR", honeypot, verificationToken } = params;

  // Bot honeypot check
  if (honeypot && honeypot.trim().length > 0) {
    return { success: true };
  }

  const cleanEmail = email.toLowerCase().trim();
  if (!cleanEmail || !cleanEmail.includes("@")) {
    throw new Error("Lütfen geçerli bir e-posta adresi giriniz.");
  }

  const cleanAgencyName = (agencyName || "Agency").trim();

  // Normalize website URL if provided
  const formattedWebsite = website && typeof website === "string" && website.trim()
    ? (/^https?:\/\//i.test(website.trim()) ? website.trim() : `https://${website.trim()}`)
    : null;

  // 1. Resolve or insert verification token into agency_demo_requests
  let token = verificationToken;

  if (!token) {
    try {
      const dbRes = await fetch(`${DEV_SUPABASE_URL}/rest/v1/agency_demo_requests`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          apikey: DEV_SUPABASE_KEY,
          Authorization: `Bearer ${DEV_SUPABASE_KEY}`,
          Prefer: "return=representation",
        },
        body: JSON.stringify({
          agency_name: cleanAgencyName,
          email: cleanEmail,
          website: formattedWebsite,
          status: "pending",
        }),
      });

      if (!dbRes.ok) {
        const errText = await dbRes.text();
        console.warn("[sendDemoVerification] agency_demo_requests insert error:", errText);
      } else {
        const rows = await dbRes.json();
        if (Array.isArray(rows) && rows.length > 0 && rows[0].verification_token) {
          token = rows[0].verification_token;
        }
      }
    } catch (dbErr) {
      console.warn("[sendDemoVerification] Database insert exception:", dbErr);
    }
  }

  // Fallback to client-generated UUID if token could not be fetched
  if (!token) {
    if (typeof crypto !== "undefined" && typeof crypto.randomUUID === "function") {
      token = crypto.randomUUID();
    } else {
      token = "demo-" + Math.random().toString(36).substring(2, 15) + "-" + Date.now();
    }
  }

  // 2. Determine target language
  let selectedLang = (lang || "TR").toUpperCase().replace("-", "_");
  if (selectedLang === "SR" || selectedLang === "RS" || selectedLang === "SRB") {
    selectedLang = "SR_LAT";
  }
  const tEmail = emailTranslations[selectedLang] || emailTranslations.TR;

  // 3. Construct direct magic link URL
  let origin = "https://www.stanomer.online";
  if (typeof window !== "undefined" && window.location?.origin) {
    origin = window.location.origin;
  }
  const verifyUrl = `${origin.replace(/\/$/, "")}/agency-demo/verify?token=${token}&lang=${encodeURIComponent(selectedLang)}`;

  // 4. Construct rich, responsive HTML email
  const htmlContent = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <title>Stanomer - Agency Demo</title>
      <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #f8fafc; color: #1e293b; margin: 0; padding: 0; }
        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 20px; overflow: hidden; box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.05), 0 8px 10px -6px rgba(0, 0, 0, 0.01); border: 1px solid #e2e8f0; }
        .header { background: linear-gradient(135deg, #2563eb 0%, #1d4ed8 100%); padding: 36px 32px; text-align: center; color: #ffffff; }
        .header h1 { margin: 0; font-size: 28px; font-weight: 800; letter-spacing: -0.5px; }
        .header p { margin: 6px 0 0 0; font-size: 14px; opacity: 0.9; font-weight: 500; }
        .content { padding: 40px 32px; text-align: center; }
        .content h2 { font-size: 22px; color: #0f172a; margin-top: 0; margin-bottom: 16px; font-weight: 800; }
        .content p { font-size: 15px; line-height: 1.65; color: #475569; margin-bottom: 24px; text-align: left; }
        .btn-wrapper { margin: 32px 0; text-align: center; }
        .btn { display: inline-block; background-color: #2563eb; color: #ffffff !important; font-weight: 700; font-size: 16px; padding: 16px 36px; border-radius: 14px; text-decoration: none; box-shadow: 0 4px 14px rgba(37, 99, 235, 0.35); transition: background-color 0.2s; }
        .features { background-color: #f8fafc; border-radius: 14px; padding: 18px 22px; margin: 24px 0; text-align: left; border: 1px solid #e2e8f0; font-size: 13px; color: #64748b; line-height: 1.6; }
        .link-box { margin-top: 28px; padding: 14px; background: #f8fafc; border: 1px dashed #cbd5e1; border-radius: 10px; word-break: break-all; font-size: 12px; color: #64748b; text-align: left; }
        .footer { background-color: #f1f5f9; padding: 24px 32px; text-align: center; font-size: 12px; color: #94a3b8; border-top: 1px solid #e2e8f0; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>Stanomer</h1>
          <p>Real Estate Property Management Platform</p>
        </div>
        <div class="content">
          <h2>${tEmail.subject}</h2>
          <p>${tEmail.greeting} <strong>${cleanAgencyName}</strong>,</p>
          <p>${tEmail.text}</p>
          
          <div class="btn-wrapper">
            <a href="${verifyUrl}" target="_blank" class="btn">${tEmail.btn}</a>
          </div>

          <div class="link-box">
            ${tEmail.fallback}<br>
            <a href="${verifyUrl}" style="color: #2563eb; font-weight: 600;">${verifyUrl}</a>
          </div>
        </div>
        <div class="footer">
          &copy; 2026 Stanomer. ${tEmail.footer}
        </div>
      </div>
    </body>
    </html>
  `;

  // 5. Send transaction email via Brevo REST API directly
  try {
    const brevoRes = await fetch("https://api.brevo.com/v3/smtp/email", {
      method: "POST",
      headers: {
        accept: "application/json",
        "content-type": "application/json",
        "api-key": BREVO_API_KEY,
      },
      body: JSON.stringify({
        sender: {
          name: BREVO_SENDER_NAME,
          email: BREVO_SENDER_EMAIL,
        },
        to: [
          {
            email: cleanEmail,
            name: cleanAgencyName,
          },
        ],
        subject: tEmail.subject,
        htmlContent: htmlContent,
      }),
    });

    if (!brevoRes.ok) {
      const errData = await brevoRes.json().catch(() => ({}));
      console.error("[sendDemoVerification] Brevo API Error:", errData);
      throw new Error(errData.message || "E-posta gönderimi sırasında bir hata oluştu.");
    }
  } catch (brevoErr: any) {
    console.error("[sendDemoVerification] Brevo fetch exception:", brevoErr);
    throw new Error(brevoErr.message || "E-posta servis sağlayıcısına ulaşılamadı.");
  }

  return {
    success: true,
    token: token,
  };
}
