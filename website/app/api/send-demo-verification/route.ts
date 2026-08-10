import { NextResponse } from "next/server";

const emailTranslations: Record<string, { subject: string; greeting: string; text: string; btn: string; fallback: string; footer: string }> = {
  TR: {
    subject: "Stanomer Acente Demo Talebi - E-posta Doğrulama",
    greeting: "Sayın",
    text: "Stanomer Emlak Ofisi paneli için yaptığınız demo başvurusunu aldık. Başvurunuzu tamamlamak ve hesabınızı aktifleştirmek için lütfen aşağıdaki butona tıklayarak e-posta adresinizi doğrulayınız:",
    btn: "E-posta Adresimi Doğrula",
    fallback: "Buton çalışmıyorsa aşağıdaki bağlantıyı tarayıcınıza kopyalayabilirsiniz:",
    footer: "Tüm hakları saklıdır. Bu e-posta otomatik olarak gönderilmiştir."
  },
  EN: {
    subject: "Stanomer Agency Demo Request - Email Verification",
    greeting: "Dear",
    text: "We have received your demo request for the Stanomer Real Estate Agency Panel. To complete your request and activate your account, please click the button below to verify your email address:",
    btn: "Verify My Email",
    fallback: "If the button above does not work, copy and paste the following link into your browser:",
    footer: "All rights reserved. This email was sent automatically."
  },
  SR_LAT: {
    subject: "Stanomer Zahtev za Demo Agencije - Potvrda Imejla",
    greeting: "Poštovani",
    text: "Primili smo vaš zahtev za demo verziju agencijskog panela Stanomer. Da biste završili zahtev i aktivirali nalog, molimo kliknite na dugme ispod kako biste potvrdili vašu imejl adresu:",
    btn: "Potvrdi Moj Imejl",
    fallback: "Ako dugme ne radi, kopirajte sledeći link u vaš pregledač:",
    footer: "Sva prava zadržana. Ovaj imejl je automatski poslat."
  },
  SR_CYR: {
    subject: "Stanomer Захтев за Демо Агенције - Потврда Имејла",
    greeting: "Поштовани",
    text: "Примили смо ваш захтев за демо верзију агенцијског панела Станомер. Да бисте завршили захтев и активирали налог, молимо кликните на дугме испод како бисте потврдили вашу имејл адресу:",
    btn: "Потврди Мој Имејл",
    fallback: "Ако дугме не ради, копирајте следећи линк у ваш прегледач:",
    footer: "Сва права задржана. Овај имејл је аутоматски послат."
  },
  RU: {
    subject: "Stanomer Запрос Демо-версии - Подтверждение Email",
    greeting: "Уважаемый(ая)",
    text: "Мы получили ваш запрос на демо-версию панели Stanomer для агентств недвижимости. Чтобы завершить запрос и активировать аккаунт, пожалуйста, нажмите кнопку ниже для подтверждения вашей электронной почты:",
    btn: "Подтвердить Мой Email",
    fallback: "Если кнопка не работает, скопируйте следующую ссылку в браузер:",
    footer: "Все права защищены. Это письмо отправлено автоматически."
  }
};

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { email, agencyName, verificationToken, lang } = body;

    if (!email || !verificationToken) {
      return NextResponse.json(
        { success: false, message: "E-posta ve doğrulama jetonu zorunludur." },
        { status: 400 }
      );
    }

    const selectedLang = (lang && emailTranslations[lang]) ? lang : "TR";
    const tEmail = emailTranslations[selectedLang];

    const apiKey = process.env.BREVO_API_KEY || "";
    const senderEmail = process.env.BREVO_SENDER_EMAIL || "atilbilge@gmail.com";
    const senderName = process.env.BREVO_SENDER_NAME || "Stanomer";

    // Determine host origin from request
    const origin = request.headers.get("origin") || request.headers.get("referer") || "http://localhost:3000";
    const verifyUrl = `${origin.replace(/\/$/, "")}/agency-demo/verify?token=${verificationToken}`;

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
