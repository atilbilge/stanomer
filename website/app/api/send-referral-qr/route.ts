import { NextResponse } from "next/server";
import QRCode from "qrcode";

const emailTranslations: Record<string, { subject: string; greeting: string; text: string; downloadTip: string; footer: string }> = {
  TR: {
    subject: "Stanomer Referral QR Kodunuz Hazır!",
    greeting: "Sayın",
    text: "Stanomer Acente Referral Sistemine kaydolduğunuz için teşekkür ederiz. Acentenize özel kalıcı QR kodunuz ve yönlendirme bağlantınız aşağıdadır:",
    downloadTip: "Bu QR kodu ofisinizde, kartvizitinizde veya sözleşme dosyalarınızda kullanabilirsiniz. Kiracı ve ev sahipleri bu kodu tarayarak Stanomer'e doğrudan acenteniz referansıyla kaydolabilir. Ayrıca yüksek çözünürlüklü PNG dosyası bu e-postanın ekinde yer almaktadır.",
    footer: "Tüm hakları saklıdır. Bu e-posta otomatik olarak gönderilmiştir."
  },
  EN: {
    subject: "Your Stanomer Referral QR Code is Ready!",
    greeting: "Dear",
    text: "Thank you for registering with the Stanomer Agency Referral System. Your agency's permanent QR code and referral link are provided below:",
    downloadTip: "You can use this QR code in your office, on business cards, or in contract files. Tenants and landlords can scan this code to join Stanomer directly through your agency's referral. A high-resolution PNG is also attached to this email.",
    footer: "All rights reserved. This email was sent automatically."
  },
  SR_LAT: {
    subject: "Vaš Stanomer Referral QR Kod je Spreman!",
    greeting: "Poštovani",
    text: "Hvala vam što ste se registrovali u Stanomer agencijski sistem preporuka. Vaš stalni QR kod i link za preporuku se nalaze ispod:",
    downloadTip: "Ovaj QR kod možete koristiti u vašoj kancelariji, na vizit kartama ili u dosijima ugovora. Zakupci i vlasnici mogu skenirati ovaj kod i pridružiti se Stanomeru direktno uz preporuku vaše agencije. PNG datoteka visoke rezolucije je takođe priložena uz ovaj imejl.",
    footer: "Sva prava zadržana. Ovaj imejl je automatski poslat."
  },
  SR_CYR: {
    subject: "Ваш Станомер Referral QR Код је Спреман!",
    greeting: "Поштовани",
    text: "Хвала вам што сте се регистровали у Станомер агенцијски систем препорука. Ваш стални QR код и линк за препоруку се налазе испод:",
    downloadTip: "Овај QR код можете користити у вашој канцеларији, на визит картама или у досијима уговора. Закупци и власници могу скенирати овај код и придружити се Станомеру директно уз препоруку ваше агенције. ПНГ датотека високе резолуције је такође приложена уз овај имејл.",
    footer: "Сва права задржана. Овај имејл је аутоматски послат."
  },
  RU: {
    subject: "Ваш Реферальный QR-Код Stanomer Готов!",
    greeting: "Уважаемый(ая)",
    text: "Благодарим вас за регистрацию в Реферальной Системе Stanomer для агентств. Ниже представлены ваш постоянный QR-код и реферальная ссылка:",
    downloadTip: "Вы можете использовать этот QR-код в офисе, на визитках или в договорах. Арендаторы и владельцы могут отсканировать этот код и присоединиться к Stanomer по вашей рекомендации. Файл PNG высокого разрешения также прикреплен к этому письму.",
    footer: "Все права защищены. Это письмо отправлено автоматически."
  }
};

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { email, agencyName, slug, referralCode, lang } = body;

    if (!email || !slug) {
      return NextResponse.json(
        { success: false, message: "E-posta ve slug zorunludur." },
        { status: 400 }
      );
    }

    const selectedLang = (lang && emailTranslations[lang]) ? lang : "TR";
    const tEmail = emailTranslations[selectedLang];

    const apiKey = process.env.BREVO_API_KEY || "";
    const senderEmail = process.env.BREVO_SENDER_EMAIL || "atilbilge@gmail.com";
    const senderName = process.env.BREVO_SENDER_NAME || "Stanomer";

    // QR link target (deeplink format: stanomer://referral?token=...)
    const codeToken = referralCode || slug;
    const targetUrl = `stanomer://referral?token=${codeToken}`;

    // Generate QR code as raw PNG buffer for email attachment
    const qrBuffer = await QRCode.toBuffer(targetUrl, {
      width: 600,
      margin: 2,
      color: {
        dark: "#0f172a",
        light: "#ffffff"
      }
    });
    const qrBase64 = qrBuffer.toString("base64");

    // Public HTTPS QR image URL for 100% email client compatibility (Gmail, Apple Mail, Outlook, etc.)
    const qrImageUrl = `https://api.qrserver.com/v1/create-qr-code/?size=400x400&margin=2&format=png&data=${encodeURIComponent(targetUrl)}`;

    const htmlContent = `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <title>Stanomer Referral QR Code</title>
        <style>
          body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f8fafc; color: #1e293b; margin: 0; padding: 0; }
          .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1); border: 1px solid #e2e8f0; }
          .header { background: linear-gradient(135deg, #7c3aed 0%, #4c1d95 100%); padding: 32px; text-align: center; color: #ffffff; }
          .header h1 { margin: 0; font-size: 28px; font-weight: 800; letter-spacing: -0.5px; }
          .header p { margin: 4px 0 0 0; font-size: 14px; opacity: 0.9; }
          .content { padding: 40px 32px; text-align: center; }
          .content h2 { font-size: 22px; color: #0f172a; margin-top: 0; }
          .content p { font-size: 15px; line-height: 1.6; color: #475569; margin-bottom: 24px; }
          .qr-box { background: #faf5ff; border: 2px dashed #c084fc; border-radius: 16px; padding: 24px; display: inline-block; margin: 16px 0; }
          .qr-box img { width: 220px; height: 220px; display: block; margin: 0 auto; border-radius: 8px; }
          .agency-tag { margin-top: 12px; font-weight: 800; font-size: 16px; color: #6b21a8; letter-spacing: 0.5px; }
          .code-tag { font-size: 12px; color: #9333ea; font-family: monospace; background: #f3e8ff; padding: 4px 12px; border-radius: 20px; display: inline-block; margin-top: 6px; }
          .info-card { background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 12px; padding: 16px; text-align: left; font-size: 13px; color: #475569; margin-top: 24px; line-height: 1.5; }
          .footer { background-color: #f1f5f9; padding: 20px 32px; text-align: center; font-size: 13px; color: #94a3b8; border-top: 1px solid #e2e8f0; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>Stanomer</h1>
            <p>Referral Partner Program</p>
          </div>
          <div class="content">
            <h2>${tEmail.subject}</h2>
            <p>${tEmail.greeting} <strong>${agencyName || "Acente"}</strong>,</p>
            <p>${tEmail.text}</p>

            <div class="qr-box">
              <img src="${qrImageUrl}" alt="Referral QR Code" width="220" height="220" style="display: block; margin: 0 auto; border-radius: 8px;" />
              <div class="agency-tag">${(agencyName || "").toUpperCase()}</div>
              <div class="code-tag">CODE: ${referralCode || slug}</div>
            </div>

            <div class="info-card">
              📌 <strong>${tEmail.downloadTip}</strong><br/><br/>
              🔗 <strong>Referral URL:</strong> <a href="${targetUrl}" style="color: #7c3aed;">${targetUrl}</a>
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
        htmlContent: htmlContent,
        attachment: [
          {
            name: `stanomer-qr-${codeToken}.png`,
            content: qrBase64
          }
        ]
      })
    });

    const brevoData = await brevoResponse.json();

    if (!brevoResponse.ok) {
      console.error("Brevo Email Error:", brevoData);
      return NextResponse.json(
        {
          success: false,
          message: brevoData.message || "Brevo email error.",
          details: brevoData
        },
        { status: brevoResponse.status }
      );
    }

    return NextResponse.json({
      success: true,
      message: "Referral QR email sent successfully.",
      messageId: brevoData.messageId
    });
  } catch (error: any) {
    console.error("Send Referral QR Error:", error);
    return NextResponse.json(
      { success: false, message: error.message || "Server error." },
      { status: 500 }
    );
  }
}
