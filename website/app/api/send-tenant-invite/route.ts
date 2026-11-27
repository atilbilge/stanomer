import { NextResponse } from "next/server";
import { createClient } from "@supabase/supabase-js";

// Initialize Supabase Admin / Service Client if available, fallback to anon
const supabaseUrl =
  process.env.NEXT_PUBLIC_SUPABASE_URL ||
  process.env.SUPABASE_URL ||
  "https://nbcbfmhztnnhfnapvaet.supabase.co";
const supabaseKey =
  process.env.SUPABASE_SERVICE_ROLE_KEY ||
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ||
  process.env.SUPABASE_ANON_KEY ||
  "sb_publishable_kY2aoizXZkGz2DsG6-sg-Q_Vm2Ef2mq";
const supabase = createClient(supabaseUrl, supabaseKey);

interface LocalizedTenantEmailContent {
  subject: string;
  body: string;
  html: string;
}

function buildTenantInviteEmail({
  address,
  tenantName,
  tenantEmail,
  agencyName,
  agencyEmail,
  monthlyRent,
  currency = "EUR",
  depositAmount,
  startDate,
  language = "sr",
}: {
  address: string;
  tenantName: string;
  tenantEmail: string;
  agencyName: string;
  agencyEmail: string;
  monthlyRent?: number;
  currency?: string;
  depositAmount?: number;
  startDate?: string;
  language: string;
}): LocalizedTenantEmailContent {
  const effectiveAddress = address?.trim() || "Property";
  const effectiveTenantName = tenantName?.trim() || "Tenant";
  const effectiveAgencyName = agencyName?.trim() || "Stanomer";
  const effectiveEmail = tenantEmail?.trim();
  const effectiveAgencyEmail = agencyEmail?.trim() || "info@stanomer.online";

  const webLink = "https://www.stanomer.online/app";
  const iosLink = "https://apps.apple.com/us/app/stanomer/id6762311157";
  const androidLink = "https://play.google.com/store/apps/details?id=com.aboptima.stanomer";

  const rentFormatted = monthlyRent && monthlyRent > 0 ? `${monthlyRent.toFixed(0)} ${currency}` : null;
  const depositFormatted = depositAmount && depositAmount > 0 ? `${depositAmount.toFixed(0)} ${currency}` : null;
  const dateFormatted = startDate ? startDate.split("-").reverse().join("/") : null;

  const norm = (language || "sr").toLowerCase().replace("_", "-");

  let subject = `[${effectiveAddress}] lease agreement notification`;
  let htmlTitle = "Stanomer - Tenant Notification";
  let salutation = `Hello ${effectiveTenantName},`;
  let intro = `As ${effectiveAgencyName}, we have added your lease agreement for the property located at ${effectiveAddress} to the Stanomer application. This allows you to view all operations related to your leasing process, such as rent payments, receipts, expenses, and maintenance requests, in real-time and track them transparently.`;
  let agreementSummaryTitle = "Agreement Summary";
  let monthlyRentLabel = "Monthly Rent";
  let depositLabel = "Deposit";
  let startDateLabel = "Start Date";
  let toGetStarted = "To get started:";
  let openWebLabel = "Open the web application";
  let orDownloadLabel = "or download the mobile app:";
  let signUpText = `Sign up using your ${effectiveEmail} address.`;
  let warningText = `⚠️ Be sure to use the ${effectiveEmail} address when signing up, otherwise your lease agreement will not match with your account.`;
  let afterRegistration = "Once registered, contract details and property information will appear in your account.";
  let questionsText = `If you have any questions, you can reach us at ${effectiveAgencyEmail}.`;
  let bestRegards = "Best regards,";
  let teamLabel = `${effectiveAgencyName} team`;
  let footerText = `This email was sent to you by ${effectiveAgencyName} as a tenant notification email.`;

  if (norm.startsWith("tr")) {
    subject = `[${effectiveAddress}] mülkü için kira sözleşmesi bildirimi`;
    htmlTitle = "Stanomer - Kira Bildirimi";
    salutation = `Merhaba ${effectiveTenantName},`;
    intro = `${effectiveAgencyName} olarak, ${effectiveAddress} adresli mülk için kira sözleşmenizi Stanomer uygulamasına ekledik. Bu sayede kira ödemeleri, dekontlar, masraflar ve bakım talepleri gibi kiralama sürecinizle ilgili tüm işlemleri anlık olarak görüntüleyebilir, şeffaf bir şekilde takip edebilirsiniz.`;
    agreementSummaryTitle = "Sözleşme Özeti";
    monthlyRentLabel = "Aylık Kira";
    depositLabel = "Depozito";
    startDateLabel = "Başlangıç Tarihi";
    toGetStarted = "Başlamak için:";
    openWebLabel = "Web uygulamasını açın";
    orDownloadLabel = "ya da mobil uygulamayı indirin:";
    signUpText = `${effectiveEmail} adresiniz ile kayıt olun.`;
    warningText = `⚠️ Kayıt olurken mutlaka ${effectiveEmail} adresini kullanın, aksi halde kira sözleşmeniz hesabınızla eşleşmez.`;
    afterRegistration = "Kayıt olduktan sonra sözleşme detayları ve mülk bilgileri hesabınızda görünecektir.";
    questionsText = `Herhangi bir sorunuz olursa bize ${effectiveAgencyEmail} üzerinden ulaşabilirsiniz.`;
    bestRegards = "Saygılarımızla,";
    teamLabel = `${effectiveAgencyName} ekibi`;
    footerText = `Bu e-posta ${effectiveAgencyName} tarafından size kira bildirim daveti olarak gönderilmiştir.`;
  } else if (norm === "sr-cyrl") {
    subject = `[${effectiveAddress}] обавештење о уговору о закупу`;
    htmlTitle = "Stanomer - Обавештење за станара";
    salutation = `Здраво ${effectiveTenantName},`;
    intro = `Као ${effectiveAgencyName}, додали смо ваш уговор о закупу за некретнину на адреси ${effectiveAddress} у Станомер апликацију. На овај начин можете у реалном времену прегледати све процесе у вези са вашим закупом, као што су уплате кирије, рачуни, трошкови и захтеви за одржавање, и пратити их на транспарентан начин.`;
    agreementSummaryTitle = "Преглед уговора";
    monthlyRentLabel = "Месечна кирија";
    depositLabel = "Депозит";
    startDateLabel = "Датум почетка";
    toGetStarted = "За почетак:";
    openWebLabel = "Отворите веб апликацију";
    orDownloadLabel = "или преузмите мобилну апликацију:";
    signUpText = `Региструјте се помоћу ваше ${effectiveEmail} адресе.`;
    warningText = `⚠️ Приликом регистрације обавезно користите ${effectiveEmail} адресу, у супротном се ваш уговор о закупу неће повезати са вашим налогом.`;
    afterRegistration = "Након регистрације, детаљи уговора и информације о некретнини појавиће се на вашем налогу.";
    questionsText = `Ако имате било каквих питања, можете нам се обратити преко ${effectiveAgencyEmail}.`;
    bestRegards = "С поштовањем,";
    teamLabel = `${effectiveAgencyName} тим`;
    footerText = `Овај имејл вам је послала компанија ${effectiveAgencyName} као обавештење за станара.`;
  } else if (norm.startsWith("sr")) {
    subject = `[${effectiveAddress}] obaveštenje o ugovoru o zakupu`;
    htmlTitle = "Stanomer - Obaveštenje za stanara";
    salutation = `Zdravo ${effectiveTenantName},`;
    intro = `Kao ${effectiveAgencyName}, dodali smo vaš ugovor o zakupu za nekretninu na adresi ${effectiveAddress} u Stanomer aplikaciju. Na ovaj način možete u realnom vremenu pregledati sve procese u vezi sa vašim zakupom, kao što su uplate kirije, računi, troškovi i zahtevi za održavanje, i pratiti ih na transparentan način.`;
    agreementSummaryTitle = "Pregled ugovora";
    monthlyRentLabel = "Mesečna kirija";
    depositLabel = "Depozit";
    startDateLabel = "Datum početka";
    toGetStarted = "Za početak:";
    openWebLabel = "Otvorite veb aplikaciju";
    orDownloadLabel = "ili preuzmite mobilnu aplikaciju:";
    signUpText = `Registrujte se pomoću vaše ${effectiveEmail} adrese.`;
    warningText = `⚠️ Prilikom registracije obavezno koristite ${effectiveEmail} adresu, u suprotnom se vaš ugovor o zakupu neće povezati sa vašim nalogom.`;
    afterRegistration = "Nakon registracije, detalji ugovora i informacije o nekretnini pojaviće se na vašem nalogu.";
    questionsText = `Ako imate bilo kakvih pitanja, možete nam se obratiti preko ${effectiveAgencyEmail}.`;
    bestRegards = "S poštovanjem,";
    teamLabel = `${effectiveAgencyName} tim`;
    footerText = `Ovaj imejl vam je poslala kompanija ${effectiveAgencyName} kao obaveštenje za stanara.`;
  } else if (norm.startsWith("ru")) {
    subject = `[${effectiveAddress}] уведомление о договоре аренды`;
    htmlTitle = "Stanomer - Уведомление для арендатора";
    salutation = `Здравствуйте, ${effectiveTenantName},`;
    intro = `Компания ${effectiveAgencyName} добавила ваш договор аренды на недвижимость по адресу ${effectiveAddress} в приложение Stanomer. Благодаря этому вы сможете в режиме реального времени просматривать все операции, связанные с процессом аренды, такие как арендные платежи, квитанции, расходы и запросы на обслуживание, а также прозрачно отслеживать их.`;
    agreementSummaryTitle = "Сводка договора";
    monthlyRentLabel = "Ежемесячная аренда";
    depositLabel = "Депозит";
    startDateLabel = "Дата начала";
    toGetStarted = "Для начала:";
    openWebLabel = "Откройте веб-приложение";
    orDownloadLabel = "или загрузите мобильное приложение:";
    signUpText = `Зарегистрируйтесь, используя ваш адрес ${effectiveEmail}.`;
    warningText = `⚠️ Обязательно используйте адрес ${effectiveEmail} при регистрации, иначе ваш договор аренды не привяжется к вашей учетной записи.`;
    afterRegistration = "После регистрации детали договора и информация о недвижимости появятся в вашем аккаунте.";
    questionsText = `Если у вас возникнут вопросы, вы можете связаться с нами по адресу ${effectiveAgencyEmail}.`;
    bestRegards = "С уважением,";
    teamLabel = `команда ${effectiveAgencyName}`;
    footerText = `Это письмо было отправлено вам компанией ${effectiveAgencyName} в качестве уведомительного письма для арендатора.`;
  }

  const termsRows: string[] = [];
  if (rentFormatted) termsRows.push(`<tr><td style="padding:4px 0;">${monthlyRentLabel}</td><td style="padding:4px 0; text-align:right; font-weight:bold;">${rentFormatted}</td></tr>`);
  if (depositFormatted) termsRows.push(`<tr><td style="padding:4px 0;">${depositLabel}</td><td style="padding:4px 0; text-align:right; font-weight:bold;">${depositFormatted}</td></tr>`);
  if (dateFormatted) termsRows.push(`<tr><td style="padding:4px 0;">${startDateLabel}</td><td style="padding:4px 0; text-align:right; font-weight:bold;">${dateFormatted}</td></tr>`);

  const termsHtmlTable = termsRows.length > 0
    ? `<table role="presentation" cellpadding="0" cellspacing="0" width="100%" style="background-color:#f4f6f8; border-radius:6px; margin:20px 0;">
        <tr>
          <td style="padding:16px 20px;">
            <p style="margin:0 0 8px 0; font-weight:bold; color:#1a5eb8;">${agreementSummaryTitle}</p>
            <table role="presentation" cellpadding="0" cellspacing="0" width="100%" style="font-size:14px; color:#333333;">
              ${termsRows.join("")}
            </table>
          </td>
        </tr>
      </table>`
    : "";

  const termsPlainSummary = [
    rentFormatted ? `• ${monthlyRentLabel}: ${rentFormatted}` : "",
    depositFormatted ? `• ${depositLabel}: ${depositFormatted}` : "",
    dateFormatted ? `• ${startDateLabel}: ${dateFormatted}` : "",
  ].filter(Boolean).join("\n");

  const body = `${salutation}

${intro}

${termsPlainSummary ? `${agreementSummaryTitle}:\n${termsPlainSummary}\n\n` : ""}${toGetStarted}

1. ${openWebLabel} (${webLink}) ${orDownloadLabel}
(${iosLink} ve ${androidLink})
2. ${signUpText}

${warningText}

${afterRegistration}

${questionsText}

${bestRegards}
${teamLabel}`;

  const html = `<!DOCTYPE html>
<html lang="${norm}">
<head>
<meta charset="UTF-8">
<title>${htmlTitle}</title>
</head>
<body style="margin:0; padding:0; background-color:#f4f6f8; font-family: Arial, Helvetica, sans-serif;">
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color:#f4f6f8; padding:24px 0;">
    <tr>
      <td align="center">
        <table role="presentation" width="600" cellpadding="0" cellspacing="0" style="background-color:#ffffff; border-radius:8px; overflow:hidden; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05);">
          <tr>
            <td style="background-color:#1a5eb8; padding:24px 32px;">
              <span style="color:#ffffff; font-size:22px; font-weight:bold; letter-spacing:-0.5px;">Stanomer</span>
            </td>
          </tr>
          <tr>
            <td style="padding:32px; color:#222222; font-size:15px; line-height:1.6;">
              <p>${salutation}</p>
              <p>${intro}</p>
              ${termsHtmlTable}
              <p style="margin-top:24px; margin-bottom:8px;"><strong>${toGetStarted}</strong></p>
              <ol style="margin:0; padding-left:20px;">
                <li style="margin-bottom:8px;">
                  <a href="${webLink}" style="color:#1a5eb8; text-decoration:none; font-weight:bold;">${openWebLabel}</a>
                  ${orDownloadLabel}
                  <a href="${iosLink}" style="color:#1a5eb8; text-decoration:none; font-weight:bold;">App Store</a>
                  /
                  <a href="${androidLink}" style="color:#1a5eb8; text-decoration:none; font-weight:bold;">Google Play</a>
                </li>
                <li>
                  ${signUpText}
                </li>
              </ol>
              <table role="presentation" cellpadding="0" cellspacing="0" style="background-color:#fff4e5; border-left:4px solid #c8503a; border-radius:4px; margin:24px 0; width: 100%;">
                <tr>
                  <td style="padding:12px 16px; color:#7a271a; font-size:13px; line-height:1.4;">
                    ${warningText}
                  </td>
                </tr>
              </table>
              <p style="color:#666666; font-size:13px;">${afterRegistration}</p>
              <p style="margin-top:24px;">${questionsText}</p>
              <p style="margin-top:32px; margin-bottom:0; color:#555555;">
                ${bestRegards}<br>
                <strong>${teamLabel}</strong>
              </p>
            </td>
          </tr>
          <tr>
            <td style="background-color:#f4f6f8; padding:16px 32px; text-align:center; font-size:12px; color:#888888;">
              <p style="margin:0;">${footerText}</p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>`;

  return { subject, body, html };
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const {
      propertyId,
      propertyAddress,
      tenantEmail,
      tenantName,
      agencyName = "Stanomer",
      agencyEmail = "info@stanomer.online",
      monthlyRent,
      currency = "EUR",
      depositAmount,
      startDate,
      language = "sr",
      inviterId,
      token,
    } = body;

    if (!tenantEmail || !tenantEmail.includes("@")) {
      return NextResponse.json(
        { success: false, error: "Invalid recipient email address" },
        { status: 400 }
      );
    }

    if (!propertyId) {
      return NextResponse.json(
        { success: false, error: "Property ID is required" },
        { status: 400 }
      );
    }

    const trimmedEmail = tenantEmail.trim().toLowerCase();
    const trimmedName = tenantName?.trim() || trimmedEmail;

    // 1. Prepare email content
    const emailData = buildTenantInviteEmail({
      address: propertyAddress,
      tenantName: trimmedName,
      tenantEmail: trimmedEmail,
      agencyName,
      agencyEmail,
      monthlyRent: Number(monthlyRent) || undefined,
      currency,
      depositAmount: Number(depositAmount) || undefined,
      startDate,
      language,
    });

    const apiKey = process.env.BREVO_API_KEY || process.env.NEXT_PUBLIC_BREVO_API_KEY || "";
    const senderEmail = process.env.BREVO_SENDER_EMAIL || "atilbilge@gmail.com";
    const senderName = process.env.BREVO_SENDER_NAME || "Stanomer";

    if (!apiKey) {
      console.warn("BREVO_API_KEY is not configured in server environment.");
      return NextResponse.json(
        { success: false, error: "Email service provider key is not configured" },
        { status: 500 }
      );
    }

    // 2. Send email via Brevo SMTP API
    const brevoResponse = await fetch("https://api.brevo.com/v3/smtp/email", {
      method: "POST",
      headers: {
        accept: "application/json",
        "content-type": "application/json",
        "api-key": apiKey,
      },
      body: JSON.stringify({
        sender: {
          name: senderName,
          email: senderEmail,
        },
        to: [
          {
            email: trimmedEmail,
            name: trimmedName,
          },
        ],
        replyTo: {
          email: agencyEmail || senderEmail,
          name: agencyName,
        },
        subject: emailData.subject,
        htmlContent: emailData.html,
        textContent: emailData.body,
      }),
    });

    if (!brevoResponse.ok) {
      const errorText = await brevoResponse.text();
      console.error("Brevo API error:", brevoResponse.status, errorText);
      return NextResponse.json(
        { success: false, error: `Email dispatch failed: ${brevoResponse.statusText}` },
        { status: 502 }
      );
    }

    // 3. Log activity in activity_logs
    try {
      await supabase.from("activity_logs").insert({
        property_id: propertyId,
        user_id: inviterId || null,
        type: "tenant_invite_email_sent",
        metadata: {
          tenant_name: trimmedName,
          tenant_email: trimmedEmail,
          token: token || null,
          monthly_rent: monthlyRent || null,
          provider: "brevo",
          sent_at: new Date().toISOString(),
        },
      });
    } catch (_) {}

    return NextResponse.json({
      success: true,
      message: "Tenant invitation email sent successfully",
    });
  } catch (err: any) {
    console.error("Error sending tenant invite email:", err);
    return NextResponse.json(
      { success: false, error: err?.message || "Internal server error" },
      { status: 500 }
    );
  }
}
