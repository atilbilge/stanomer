import type { Metadata } from "next";

export const metadata: Metadata = {
  robots: { index: false, follow: true },
  alternates: {
    canonical: "https://www.stanomer.online/guide/vodic-za-izdavanje-stanova-beograd-cirilica",
  },
};

export default function RedirectPage() {
  const targetUrl = "https://www.stanomer.online/guide/vodic-za-izdavanje-stanova-beograd-cirilica";
  return (
    <html>
      <head>
        <meta httpEquiv="refresh" content={`0; url=${targetUrl}`} />
        <link rel="canonical" href={targetUrl} />
      </head>
      <body>
        <p>Redirecting to <a href={targetUrl}>{targetUrl}</a>...</p>
      </body>
    </html>
  );
}
