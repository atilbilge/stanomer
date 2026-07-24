import type { Metadata } from "next";
import { Outfit } from "next/font/google";
import Script from "next/script";
import { Analytics } from "@vercel/analytics/react";
import { LanguageProvider } from "../components/LanguageProvider";
import "./globals.css";

const outfit = Outfit({
  subsets: ["latin"],
  variable: "--font-outfit",
  weight: ["300", "400", "500", "600", "700", "800"],
});

export const metadata: Metadata = {
  title: "Stanomer | Mülk Yönetiminde Yeni Nesil Şeffaflık",
  description: "Ev sahipleri ve kiracılar için dijital köprü. Kontrat, ödeme ve arıza takibini tek uygulamada yönetin.",
  icons: {
    icon: "/favicon.png",
    shortcut: "/favicon.ico",
    apple: "/favicon.png",
  },
  verification: {
    other: {
      "yandex-verification": "d17cff3e7f334900",
    },
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="tr" suppressHydrationWarning>
      <body className={`${outfit.variable} font-sans antialiased`} suppressHydrationWarning>
        <LanguageProvider>
          {children}
        </LanguageProvider>
        <Analytics />

        {/* Yandex.Metrika Counter */}
        <Script id="yandex-metrika" strategy="afterInteractive">
          {`
            (function(m,e,t,r,i,k,a){
                m[i]=m[i]||function(){(m[i].a=m[i].a||[]).push(arguments)};
                m[i].l=1*new Date();
                for (var j = 0; j < document.scripts.length; j++) {if (document.scripts[j].src === r) { return; }}
                k=e.createElement(t),a=e.getElementsByTagName(t)[0],k.async=1,k.src=r,a.parentNode.insertBefore(k,a)
            })(window, document,'script','https://mc.yandex.ru/metrika/tag.js?id=110922999', 'ym');

            ym(110922999, 'init', {ssr:true, webvisor:true, clickmap:true, ecommerce:"dataLayer", referrer: document.referrer, url: location.href, accurateTrackBounce:true, trackLinks:true});
          `}
        </Script>
        <noscript>
          <div>
            <img src="https://mc.yandex.ru/watch/110922999" style={{ position: "absolute", left: "-9999px" }} alt="" />
          </div>
        </noscript>
      </body>
    </html>
  );
}
