import { NextResponse } from "next/server";
import { createClient } from "@supabase/supabase-js";

// Initialize Supabase Admin / Service Client if available, fallback to anon
const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || "https://nbcbfmhztnnhfnapvaet.supabase.co";
const supabaseKey =
  process.env.SUPABASE_SERVICE_ROLE_KEY ||
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ||
  "sb_publishable_kY2aoizXZkGz2DsG6-sg-Q_Vm2Ef2mq";
const supabase = createClient(supabaseUrl, supabaseKey);

interface LocalizedEmailContent {
  subject: string;
  body: string;
  html: string;
}

function buildLandlordInviteEmail({
  address,
  landlordName,
  landlordEmail,
  agencyName,
  agencyEmail,
  language,
}: {
  address: string;
  landlordName: string;
  landlordEmail: string;
  agencyName: string;
  agencyEmail: string;
  language: string;
}): LocalizedEmailContent {
  const effectiveAddress = address?.trim() || "Your Property";
  const effectiveLandlordName = landlordName?.trim() || "Property Owner";
  const effectiveAgencyName = agencyName?.trim() || "Stanomer";
  const effectiveEmail = landlordEmail?.trim();
  const effectiveAgencyEmail = agencyEmail?.trim() || "info@stanomer.online";

  const webLink = "https://www.stanomer.online/app";
  const iosLink = "https://apps.apple.com/us/app/stanomer/id6762311157";
  const androidLink = "https://play.google.com/store/apps/details?id=com.aboptima.stanomer";

  const normalizedLang = (language || "sr").toLowerCase().trim();

  // 1. English (en)
  if (normalizedLang.startsWith("en")) {
    const subject = `[${effectiveAddress}] your property has been added to Stanomer`;
    const body = `Hello ${effectiveLandlordName},

As ${effectiveAgencyName}, we have added your property located at ${effectiveAddress} to the Stanomer application. 
This allows you to view all processes related to your property, such as rent payments, expenses, and maintenance processes, in real-time and track them transparently.

To get started:

1. Open the web application (${webLink}) or download the mobile app:
(${iosLink} and ${androidLink})
2. Sign up using your ${effectiveEmail} address.

⚠️ Be sure to use the ${effectiveEmail} address when signing up, otherwise your property will not match with your account.

Once registered, all details regarding your property will appear in your account.

If you have any questions, you can reach us at ${effectiveAgencyEmail}.

Best regards,
${effectiveAgencyName} team`;

    const html = `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Stanomer - Property Notification</title>
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
              <p>Hello <strong>${effectiveLandlordName}</strong>,</p>
              <p>As <strong>${effectiveAgencyName}</strong>, we have added your property located at <strong>${effectiveAddress}</strong> to the Stanomer application. 
              This allows you to view all processes related to your property, such as rent payments, expenses, and maintenance processes, in real-time and track them transparently.</p>
              <p style="margin-top:24px; margin-bottom:8px;"><strong>To get started:</strong></p>
              <ol style="margin:0; padding-left:20px;">
                <li style="margin-bottom:8px;">
                  <a href="${webLink}" style="color:#1a5eb8; text-decoration:none; font-weight:bold;">Open the web application</a>
                  or download the mobile app:
                  <a href="${iosLink}" style="color:#1a5eb8; text-decoration:none; font-weight:bold;">App Store</a>
                  /
                  <a href="${androidLink}" style="color:#1a5eb8; text-decoration:none; font-weight:bold;">Google Play</a>
                </li>
                <li>
                  Sign up using your <strong>${effectiveEmail}</strong> address.
                </li>
              </ol>
              <table role="presentation" cellpadding="0" cellspacing="0" style="background-color:#fff4e5; border-left:4px solid #c8503a; border-radius:4px; margin:24px 0; width: 100%;">
                <tr>
                  <td style="padding:14px 16px; font-size:14px; color:#7a3b1e;">
                    ⚠️ Be sure to use the <strong>${effectiveEmail}</strong> address when signing up, otherwise your property will not match with your account.
                  </td>
                </tr>
              </table>
              <p>Once registered, all details regarding your property will appear in your account.</p>
              <p>If you have any questions, you can <a href="mailto:${effectiveAgencyEmail}" style="color:#1a5eb8; text-decoration:none;">reach us here</a>.</p>
              <p style="margin-top:32px;">Best regards,<br><strong>${effectiveAgencyName} team</strong></p>
            </td>
          </tr>
          <tr>
            <td style="background-color:#f4f6f8; padding:16px 32px; font-size:12px; color:#888888; text-align:center;">
              This email was sent to you by ${effectiveAgencyName} as a property management notification.
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

  // 2. Serbian Cyrillic (sr-Cyrl)
  if (normalizedLang === "sr-cyrl" || normalizedLang === "sr_cyrl") {
    const subject = `[${effectiveAddress}] ваша некретнина је додата у Станомер`;
    const body = `Здраво ${effectiveLandlordName},

Као ${effectiveAgencyName}, додали смо вашу некретнину на адреси ${effectiveAddress} у Станомер апликацију. 
На овај начин можете у реалном времену прегледати све процесе везане за вашу некретнину, као што су уплате кирије, трошкови и процеси одржавања, и пратити их на транспарентан начин.

За почетак:

1. Отворите веб апликацију (${webLink}) или преузмите мобилну апликацију:
(${iosLink} и ${androidLink})
2. Региструјте се помоћу ваше ${effectiveEmail} адресе.

⚠️ Приликом регистрације обавезно користите ${effectiveEmail} адресу, у супротном се ваша некретнина неће повезати са вашим налогом.

Након регистрације, сви детаљи у вези са вашом некретнином појавиће се на вашем налогу.

Ако имате било каквих питања, можете нам се обратити на ${effectiveAgencyEmail}.

С поштовањем,
${effectiveAgencyName} тим`;

    const html = `<!DOCTYPE html>
<html lang="sr-Cyrl">
<head>
<meta charset="UTF-8">
<title>Stanomer - Обавештење о некретнини</title>
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
              <p>Здраво <strong>${effectiveLandlordName}</strong>,</p>
              <p>Као <strong>${effectiveAgencyName}</strong>, додали смо вашу некретнину на адреси <strong>${effectiveAddress}</strong> у Станомер апликацију. 
              На овај начин можете у реалном времену прегледати све процесе везане за вашу некретнину, као што су уплате кирије, трошкови и процеси одржавања, и пратити их на транспарентан начин.</p>
              <p style="margin-top:24px; margin-bottom:8px;"><strong>За почетак:</strong></p>
              <ol style="margin:0; padding-left:20px;">
                <li style="margin-bottom:8px;">
                  <a href="${webLink}" style="color:#1a5eb8; text-decoration:none; font-weight:bold;">Отворите веб апликацију</a>
                  или преузмите мобилну апликацију:
                  <a href="${iosLink}" style="color:#1a5eb8; text-decoration:none; font-weight:bold;">App Store</a>
                  /
                  <a href="${androidLink}" style="color:#1a5eb8; text-decoration:none; font-weight:bold;">Google Play</a>
                </li>
                <li>
                  Региструјте се помоћу ваше <strong>${effectiveEmail}</strong> адресе.
                </li>
              </ol>
              <table role="presentation" cellpadding="0" cellspacing="0" style="background-color:#fff4e5; border-left:4px solid #c8503a; border-radius:4px; margin:24px 0; width: 100%;">
                <tr>
                  <td style="padding:14px 16px; font-size:14px; color:#7a3b1e;">
                    ⚠️ Приликом регистрације обавезно користите <strong>${effectiveEmail}</strong> адресу, у супротном се ваша некретнина неће повезати са вашим налогом.
                  </td>
                </tr>
              </table>
              <p>Након регистрације, сви детаљи у вези са вашом некретнином појавиће се на вашем налогу.</p>
              <p>Ако имате било каквих питања, можете нам <a href="mailto:${effectiveAgencyEmail}" style="color:#1a5eb8; text-decoration:none;">се обратити овде</a>.</p>
              <p style="margin-top:32px;">С поштовањем,<br><strong>${effectiveAgencyName} тим</strong></p>
            </td>
          </tr>
          <tr>
            <td style="background-color:#f4f6f8; padding:16px 32px; font-size:12px; color:#888888; text-align:center;">
              Овај имејл вам је послао ${effectiveAgencyName} као обавештење о управљању некретнином.
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

  // 3. Turkish (tr)
  if (normalizedLang.startsWith("tr")) {
    const subject = `[${effectiveAddress}] mülkünüz Stanomer'e eklendi`;
    const body = `Merhaba ${effectiveLandlordName},

${effectiveAgencyName} olarak, ${effectiveAddress} adresli mülkünüzü Stanomer uygulamasına ekledik. 
Bu sayede kira ödemeleri, masraflar ve bakım süreçleri gibi mülkünüzle ilgili tüm işlemleri anlık olarak görüntüleyebilir, şeffaf bir şekilde takip edebilirsiniz.

Başlamak için:

1. Web uygulamasını açın (${webLink}) ya da mobil uygulamayı indirin:
(${iosLink} ve ${androidLink})
2. ${effectiveEmail} adresiniz ile kayıt olun.

⚠️ Kayıt olurken mutlaka ${effectiveEmail} adresini kullanın, aksi halde mülkünüz hesabınızla eşleşmez.

Kayıt olduktan sonra mülkünüze dair tüm detaylar hesabınızda görünecektir.

Herhangi bir sorunuz olursa bize ${effectiveAgencyEmail} üzerinden ulaşabilirsiniz.

Saygılarımızla,
${effectiveAgencyName} ekibi`;

    const html = `<!DOCTYPE html>
<html lang="tr">
<head>
<meta charset="UTF-8">
<title>Stanomer - Mülk Bildirimi</title>
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
              <p>Merhaba <strong>${effectiveLandlordName}</strong>,</p>
              <p><strong>${effectiveAgencyName}</strong> olarak, <strong>${effectiveAddress}</strong> adresli mülkünüzü Stanomer uygulamasına ekledik.
              Bu sayede kira ödemeleri, masraflar ve bakım süreçleri gibi mülkünüzle ilgili tüm işlemleri anlık olarak görüntüleyebilir, şeffaf bir şekilde takip edebilirsiniz.</p>
              <p style="margin-top:24px; margin-bottom:8px;"><strong>Başlamak için:</strong></p>
              <ol style="margin:0; padding-left:20px;">
                <li style="margin-bottom:8px;">
                  <a href="${webLink}" style="color:#1a5eb8; text-decoration:none; font-weight:bold;">Web uygulamasını açın</a>
                  ya da mobil uygulamayı indirin:
                  <a href="${iosLink}" style="color:#1a5eb8; text-decoration:none; font-weight:bold;">App Store</a>
                  /
                  <a href="${androidLink}" style="color:#1a5eb8; text-decoration:none; font-weight:bold;">Google Play</a>
                </li>
                <li>
                  <strong>${effectiveEmail}</strong> adresiniz ile kayıt olun.
                </li>
              </ol>
              <table role="presentation" cellpadding="0" cellspacing="0" style="background-color:#fff4e5; border-left:4px solid #c8503a; border-radius:4px; margin:24px 0; width: 100%;">
                <tr>
                  <td style="padding:14px 16px; font-size:14px; color:#7a3b1e;">
                    ⚠️ Kayıt olurken mutlaka <strong>${effectiveEmail}</strong> adresini kullanın, aksi halde mülkünüz hesabınızla eşleşmez.
                  </td>
                </tr>
              </table>
              <p>Kayıt olduktan sonra mülkünüze dair tüm detaylar hesabınızda görünecektir.</p>
              <p>Herhangi bir sorunuz olursa bize <a href="mailto:${effectiveAgencyEmail}" style="color:#1a5eb8; text-decoration:none;">ulaşabilirsiniz</a>.</p>
              <p style="margin-top:32px;">Saygılarımızla,<br><strong>${effectiveAgencyName} ekibi</strong></p>
            </td>
          </tr>
          <tr>
            <td style="background-color:#f4f6f8; padding:16px 32px; font-size:12px; color:#888888; text-align:center;">
              Bu e-posta size ${effectiveAgencyName} tarafından mülk yönetim bildirimi olarak gönderilmiştir.
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

  // 4. Russian (ru)
  if (normalizedLang.startsWith("ru")) {
    const subject = `[${effectiveAddress}] ваша недвижимость добавлена в Stanomer`;
    const body = `Здравствуйте, ${effectiveLandlordName},

Компания ${effectiveAgencyName} добавила вашу недвижимость по адресу ${effectiveAddress} в приложение Stanomer. 
Благодаря этому вы сможете в режиме реального времени просматривать все операции, связанные с вашей недвижимостью, такие как арендные платежи, расходы и процессы обслуживания, а также прозрачно отслеживать их.

Для начала:

1. Откройте веб-приложение (${webLink}) или загрузите мобильное приложение:
(${iosLink} и ${androidLink})
2. Зарегистрируйтесь, используя ваш адрес ${effectiveEmail}.

⚠️ Обязательно используйте адрес ${effectiveEmail} при регистрации, иначе ваша недвижимость не привяжется к вашей учетной записи.

После регистрации все данные о вашей недвижимости появятся в вашем аккаунте.

Если у вас возникнут вопросы, вы можете связаться с нами по адресу ${effectiveAgencyEmail}.

С уважением,
команда ${effectiveAgencyName}`;

    const html = `<!DOCTYPE html>
<html lang="ru">
<head>
<meta charset="UTF-8">
<title>Stanomer - Уведомление о недвижимости</title>
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
              <p>Здравствуйте, <strong>${effectiveLandlordName}</strong>,</p>
              <p>Компания <strong>${effectiveAgencyName}</strong> добавила вашу недвижимость по адресу <strong>${effectiveAddress}</strong> в приложение Stanomer. 
              Благодаря этому вы сможете в режиме реального времени просматривать все операции, связанные с вашей недвижимостью, такие как арендные платежи, расходы и процессы обслуживания, а также прозрачно отслеживать их.</p>
              <p style="margin-top:24px; margin-bottom:8px;"><strong>Для начала:</strong></p>
              <ol style="margin:0; padding-left:20px;">
                <li style="margin-bottom:8px;">
                  <a href="${webLink}" style="color:#1a5eb8; text-decoration:none; font-weight:bold;">Откройте веб-приложение</a>
                  или загрузите мобильное приложение:
                  <a href="${iosLink}" style="color:#1a5eb8; text-decoration:none; font-weight:bold;">App Store</a>
                  /
                  <a href="${androidLink}" style="color:#1a5eb8; text-decoration:none; font-weight:bold;">Google Play</a>
                </li>
                <li>
                  Зарегистрируйтесь, используя ваш адрес <strong>${effectiveEmail}</strong>.
                </li>
              </ol>
              <table role="presentation" cellpadding="0" cellspacing="0" style="background-color:#fff4e5; border-left:4px solid #c8503a; border-radius:4px; margin:24px 0; width: 100%;">
                <tr>
                  <td style="padding:14px 16px; font-size:14px; color:#7a3b1e;">
                    ⚠️ Обязательно используйте адрес <strong>${effectiveEmail}</strong> при регистрации, иначе ваша недвижимость не привяжется к вашей учетной записи.
                  </td>
                </tr>
              </table>
              <p>После регистрации все данные о вашей недвижимости появятся в вашем аккаунте.</p>
              <p>Если у вас возникнут вопросы, вы можете <a href="mailto:${effectiveAgencyEmail}" style="color:#1a5eb8; text-decoration:none;">связаться с нами здесь</a>.</p>
              <p style="margin-top:32px;">С уважением,<br><strong>команда ${effectiveAgencyName}</strong></p>
            </td>
          </tr>
          <tr>
            <td style="background-color:#f4f6f8; padding:16px 32px; font-size:12px; color:#888888; text-align:center;">
              Это письмо было отправлено вам компанией ${effectiveAgencyName} в качестве уведомления об управлении недвижимостью.
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

  // 5. Serbian Latin (sr) - Default
  const subject = `[${effectiveAddress}] vaša nekretnina je dodata u Stanomer`;
  const body = `Zdravo ${effectiveLandlordName},

Kao ${effectiveAgencyName}, dodali smo vašu nekretninu na adresi ${effectiveAddress} u Stanomer aplikaciju. 
Na ovaj način možete u realnom vremenu pregledati sve procese vezane za vašu nekretninu, kao što su uplate kirije, troškovi i procesi održavanja, i pratiti ih na transparentan način.

Za početak:

1. Otvorite veb aplikaciju (${webLink}) ili preuzmite mobilnu aplikaciju:
(${iosLink} i ${androidLink})
2. Registrujte se pomoću vaše ${effectiveEmail} adrese.

⚠️ Prilikom registracije obavezno koristite ${effectiveEmail} adresu, u suprotnom se vaša nekretnina neće povezati sa vašim nalogom.

Nakon registracije, svi detalji u vezi sa vašom nekretninom pojaviće se na vašem nalogu.

Ako imate bilo kakvih pitanja, možete nam se obratiti na ${effectiveAgencyEmail}.

S poštovanjem,
${effectiveAgencyName} tim`;

  const html = `<!DOCTYPE html>
<html lang="sr">
<head>
<meta charset="UTF-8">
<title>Stanomer - Obaveštenje o nekretnini</title>
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
              <p>Zdravo <strong>${effectiveLandlordName}</strong>,</p>
              <p>Kao <strong>${effectiveAgencyName}</strong>, dodali smo vašu nekretninu na adresi <strong>${effectiveAddress}</strong> u Stanomer aplikaciju. 
              Na ovaj način možete u realnom vremenu pregledati sve procese vezane za vašu nekretninu, kao što su uplate kirije, troškovi i procesi održavanja, i pratiti ih na transparentan način.</p>
              <p style="margin-top:24px; margin-bottom:8px;"><strong>Za početak:</strong></p>
              <ol style="margin:0; padding-left:20px;">
                <li style="margin-bottom:8px;">
                  <a href="${webLink}" style="color:#1a5eb8; text-decoration:none; font-weight:bold;">Otvorite veb aplikaciju</a>
                  ili preuzmite mobilnu aplikaciju:
                  <a href="${iosLink}" style="color:#1a5eb8; text-decoration:none; font-weight:bold;">App Store</a>
                  /
                  <a href="${androidLink}" style="color:#1a5eb8; text-decoration:none; font-weight:bold;">Google Play</a>
                </li>
                <li>
                  Registrujte se pomoću vaše <strong>${effectiveEmail}</strong> adrese.
                </li>
              </ol>
              <table role="presentation" cellpadding="0" cellspacing="0" style="background-color:#fff4e5; border-left:4px solid #c8503a; border-radius:4px; margin:24px 0; width: 100%;">
                <tr>
                  <td style="padding:14px 16px; font-size:14px; color:#7a3b1e;">
                    ⚠️ Prilikom registracije obavezno koristite <strong>${effectiveEmail}</strong> adresu, u suprotnom se vaša nekretnina neće povezati sa vašim nalogom.
                  </td>
                </tr>
              </table>
              <p>Nakon registracije, svi detalji u vezi sa vašom nekretninom pojaviće se na vašem nalogu.</p>
              <p>Ako imate bilo kakvih pitanja, možete nam se <a href="mailto:${effectiveAgencyEmail}" style="color:#1a5eb8; text-decoration:none;">obratiti ovde</a>.</p>
              <p style="margin-top:32px;">S poštovanjem,<br><strong>${effectiveAgencyName} tim</strong></p>
            </td>
          </tr>
          <tr>
            <td style="background-color:#f4f6f8; padding:16px 32px; font-size:12px; color:#888888; text-align:center;">
              Ovaj imejl vam je poslao ${effectiveAgencyName} kao obaveštenje o upravljanju nekretninom.
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
      landlordEmail,
      landlordName,
      agencyName = "Stanomer",
      agencyEmail = "info@stanomer.online",
      language = "sr",
      inviterId,
    } = body;

    if (!landlordEmail || !landlordEmail.includes("@")) {
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

    const trimmedEmail = landlordEmail.trim().toLowerCase();
    const trimmedName = landlordName?.trim() || trimmedEmail;
    const token = `landlord_${Date.now()}_${Math.floor(Math.random() * 99999)}`;

    // 1. Create invitation record in Supabase
    try {
      // Cancel previous pending invites for this property & email
      await supabase
        .from("invitations")
        .update({ status: "cancelled" })
        .eq("property_id", propertyId)
        .eq("invitee_email", trimmedEmail)
        .eq("status", "pending");

      // Insert fresh pending invitation
      await supabase.from("invitations").insert({
        property_id: propertyId,
        inviter_id: inviterId || null,
        agency_id: inviterId || null,
        inviter_name: agencyName,
        invitee_email: trimmedEmail,
        token: token,
        target_role: "landlord",
        status: "pending",
        expires_at: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
      });
    } catch (dbErr) {
      console.warn("Could not insert invitation into DB (continuing email dispatch):", dbErr);
    }

    // 2. Prepare email content
    const emailData = buildLandlordInviteEmail({
      address: propertyAddress,
      landlordName: trimmedName,
      landlordEmail: trimmedEmail,
      agencyName,
      agencyEmail,
      language,
    });

    const apiKey = process.env.BREVO_API_KEY || process.env.NEXT_PUBLIC_BREVO_API_KEY || "";
    const senderEmail = process.env.BREVO_SENDER_EMAIL || "atilbilge@gmail.com";
    const senderName = process.env.BREVO_SENDER_NAME || "Stanomer";

    if (!apiKey) {
      console.error("BREVO_API_KEY is not configured in server environment.");
      return NextResponse.json(
        { success: false, error: "Email service provider key is not configured" },
        { status: 500 }
      );
    }

    // 3. Send email via Brevo SMTP API
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
        replyTo: agencyEmail && agencyEmail.includes("@")
          ? {
              email: agencyEmail,
              name: agencyName,
            }
          : undefined,
        subject: emailData.subject,
        textContent: emailData.body,
        htmlContent: emailData.html,
      }),
    });

    if (!brevoResponse.ok) {
      const errorText = await brevoResponse.text();
      console.error(`Brevo SMTP error (${brevoResponse.status}):`, errorText);
      return NextResponse.json(
        { success: false, error: `Email service rejected delivery: ${errorText}` },
        { status: brevoResponse.status }
      );
    }

    const brevoResult = await brevoResponse.json().catch(() => ({}));

    // 4. Log activity in activity_logs
    try {
      await supabase.from("activity_logs").insert({
        property_id: propertyId,
        user_id: inviterId || null,
        type: "landlord_invite_email_sent",
        metadata: {
          landlord_name: trimmedName,
          landlord_email: trimmedEmail,
          token: token,
          sent_at: new Date().toISOString(),
          provider: "brevo",
          message_id: brevoResult.messageId || null,
        },
      });
    } catch (logErr) {
      console.warn("Could not log email dispatch to activity_logs:", logErr);
    }

    return NextResponse.json({
      success: true,
      token,
      messageId: brevoResult.messageId,
    });
  } catch (err: any) {
    console.error("Unhandled error in send-landlord-invite route:", err);
    return NextResponse.json(
      { success: false, error: err.message || "Internal server error" },
      { status: 500 }
    );
  }
}
