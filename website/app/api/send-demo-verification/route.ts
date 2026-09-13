import { NextResponse } from "next/server";

const emailTranslations: Record<string, { subject: string; greeting: string; text: string; btn: string; fallback: string; footer: string }> = {
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

// In-memory sliding window IP rate limiter
interface RateLimitRecord {
  count: number;
  resetAt: number;
}

const rateLimitMap = new Map<string, RateLimitRecord>();
const RATE_LIMIT_WINDOW_MS = 60 * 60 * 1000; // 1 hour
const MAX_REQUESTS_PER_WINDOW = 5; // Max 5 requests per hour per IP

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

  // Periodic cleanup if map grows
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

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { email, agencyName, website, verificationToken, lang, honeypot } = body;

    // 1. Invisible Honeypot Check (Catches bots that auto-fill all inputs)
    if (honeypot && typeof honeypot === "string" && honeypot.trim().length > 0) {
      // Fake success for bots, do not perform any DB insert or email send
      return NextResponse.json({
        success: true,
        message: "Processed successfully."
      });
    }

    // 2. IP Rate Limiting Check (Max 5 requests/hour/IP)
    const clientIp = getClientIp(request);
    if (checkRateLimit(clientIp)) {
      const isTR = lang === "TR";
      const isSR = lang === "SR_LAT" || lang === "SR_CYR";
      return NextResponse.json(
        {
          success: false,
          message: isTR
            ? "Çok fazla demo talebi gönderildi. Lütfen 1 saat sonra tekrar deneyiniz."
            : isSR
            ? "Previše zahteva za demo. Molimo pokušajte ponovo za 1 sat."
            : "Too many demo requests from this IP. Please try again in 1 hour."
        },
        { status: 429 }
      );
    }

    if (!email) {
      return NextResponse.json(
        { success: false, message: "E-posta adresi zorunludur." },
        { status: 400 }
      );
    }

    // 3. Resolve or generate verificationToken
    let token = verificationToken;
    if (!token) {
      const devSupabaseUrl = "https://thvbpifahvasyzmngpzp.supabase.co";
      const devSupabaseKey =
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRodmJwaWZhaHZhc3l6bW5ncHpwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODUyNjAxNzcsImV4cCI6MjEwMDgzNjE3N30.dNSz66kJcoSjflgCCrS7qw55efuDxF61TEMoYc3r4qU";

      const formattedWebsite = website && typeof website === "string" && website.trim()
        ? (/^https?:\/\//i.test(website.trim()) ? website.trim() : `https://${website.trim()}`)
        : null;

      const dbRes = await fetch(`${devSupabaseUrl}/rest/v1/agency_demo_requests`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          apikey: devSupabaseKey,
          Authorization: `Bearer ${devSupabaseKey}`,
          Prefer: "return=representation",
        },
        body: JSON.stringify({
          agency_name: (agencyName || "Agency").trim(),
          email: email.toLowerCase().trim(),
          website: formattedWebsite,
          status: "pending",
        }),
      });

      if (!dbRes.ok) {
        const errText = await dbRes.text();
        console.error("DB insert error in send-demo-verification:", errText);
        throw new Error("Demo talebi veritabanına kaydedilemedi.");
      }

      const dbData = await dbRes.json();
      token = Array.isArray(dbData) && dbData.length > 0 ? dbData[0].verification_token : null;
    }

    if (!token) {
      throw new Error("Doğrulama bağlantısı oluşturulamadı.");
    }

    const selectedLang = (lang && emailTranslations[lang]) ? lang : "TR";
    const tEmail = emailTranslations[selectedLang];

    const apiKey = process.env.BREVO_API_KEY || "";
    const senderEmail = process.env.BREVO_SENDER_EMAIL || "atilbilge@gmail.com";
    const senderName = process.env.BREVO_SENDER_NAME || "Stanomer";

    // Determine host origin from request
    const origin = request.headers.get("origin") || request.headers.get("referer") || "http://localhost:3000";
    const verifyUrl = `${origin.replace(/\/$/, "")}/agency-demo/verify?token=${token}&lang=${encodeURIComponent(selectedLang)}`;

    const htmlContent = `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <title>Stanomer - Email Verification</title>
        <style>
          body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f8fafc; color: #1e293b; margin: 0; padding: 0; }
          .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1); border: 1px solid #e2e8f0; }
          .header { background-color: #2563eb; padding: 32px; text-align: center; color: #ffffff; }
          .header h1 { margin: 0; font-size: 28px; font-weight: 800; letter-spacing: -0.5px; }
          .content { padding: 40px 32px; text-align: center; }
          .content h2 { font-size: 22px; color: #0f172a; margin-top: 0; }
          .content p { font-size: 16px; line-height: 1.6; color: #475569; margin-bottom: 28px; }
          .btn { display: inline-block; background-color: #2563eb; color: #ffffff !important; font-weight: 700; font-size: 16px; padding: 14px 32px; border-radius: 12px; text-decoration: none; transition: background-color 0.2s; }
          .btn:hover { background-color: #1d4ed8; }
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
            <p>${tEmail.greeting} <strong>${agencyName || "Agency"}</strong>,</p>
            <p>${tEmail.text}</p>
            
            <a href="${verifyUrl}" target="_blank" class="btn">${tEmail.btn}</a>

            <div class="link-box">
              ${tEmail.fallback}<br>
              <a href="${verifyUrl}" style="color: #2563eb;">${verifyUrl}</a>
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
        "accept": "application/json",
        "content-type": "application/json",
        "api-key": apiKey
      },
      body: JSON.stringify({
        sender: {
          name: senderName,
          email: senderEmail
        },
        to: [
          {
            email: email,
            name: agencyName || email
          }
        ],
        subject: tEmail.subject,
        htmlContent: htmlContent
      })
    });

    const brevoData = await brevoResponse.json();

    if (!brevoResponse.ok) {
      console.error("Brevo Email Error:", brevoData);
      return NextResponse.json(
        {
          success: false,
          message: brevoData.message || "Brevo error.",
          details: brevoData
        },
        { status: brevoResponse.status }
      );
    }

    // Send Admin Notification to atilbilge@gmail.com
    try {
      await fetch("https://api.brevo.com/v3/smtp/email", {
        method: "POST",
        headers: {
          "accept": "application/json",
          "content-type": "application/json",
          "api-key": apiKey
        },
        body: JSON.stringify({
          sender: {
            name: "Stanomer Notification",
            email: senderEmail
          },
          to: [
            {
              email: "atilbilge@gmail.com",
              name: "Atil Bilge"
            }
          ],
          subject: `🚀 Yeni Acente Magic Link Talebi: ${agencyName || "Acente"} (${email})`,
          htmlContent: `
            <div style="font-family: sans-serif; max-width: 500px; padding: 20px; border: 1px solid #e2e8f0; border-radius: 12px;">
              <h2 style="color: #2563eb; margin-top: 0;">🎉 Yeni Acente Demo Talebi (Magic Link)</h2>
              <p>Web sitesinden yeni bir acente demo talebi alındı ve kullanıcıya tek tıkla giriş sağlayan <strong>magic link</strong> e-postası gönderildi.</p>
              <table style="width: 100%; border-collapse: collapse; margin-top: 15px;">
                <tr><td style="padding: 8px 0; color: #64748b;"><strong>Acente Adı:</strong></td><td>${agencyName || "-"}</td></tr>
                <tr><td style="padding: 8px 0; color: #64748b;"><strong>E-posta:</strong></td><td><a href="mailto:${email}">${email}</a></td></tr>
                <tr><td style="padding: 8px 0; color: #64748b;"><strong>Web Sitesi:</strong></td><td>${body.website || "-"}</td></tr>
                <tr><td style="padding: 8px 0; color: #64748b;"><strong>Dil:</strong></td><td>${selectedLang}</td></tr>
                <tr><td style="padding: 8px 0; color: #64748b;"><strong>Tarih:</strong></td><td>${new Date().toLocaleString("tr-TR")}</td></tr>
              </table>
              <div style="margin-top: 20px; padding: 12px; background: #f8fafc; border-radius: 8px; font-size: 12px; color: #475569;">
                Magic Link (Doğrudan Giriş): <a href="${verifyUrl}" style="color: #2563eb;">${verifyUrl}</a>
              </div>
            </div>
          `
        })
      });
    } catch (adminErr) {
      console.warn("Admin notification email failed (non-critical):", adminErr);
    }

    return NextResponse.json({
      success: true,
      message: "Verification email sent.",
      messageId: brevoData.messageId
    });
  } catch (error: any) {
    console.error("Send Demo Verification Error:", error);
    return NextResponse.json(
      { success: false, message: error.message || "Server error." },
      { status: 500 }
    );
  }
}
