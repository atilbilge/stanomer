import type { Metadata } from "next";

export const metadata: Metadata = {
  robots: { index: false, follow: true },
  alternates: {
    canonical: "https://www.stanomer.online/guide/upravljanje-nekretninama-novi-sad-cirilica",
  },
};

export default function RedirectPage() {
  const targetUrl = "https://www.stanomer.online/guide/upravljanje-nekretninama-novi-sad-cirilica";
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
