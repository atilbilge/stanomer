import { MetadataRoute } from "next";

export const dynamic = "force-static";

export default function sitemap(): MetadataRoute.Sitemap {
  const baseUrl = "https://www.stanomer.online";
  const lastModified = new Date();

  const routes: { path: string; priority: number; changeFrequency: "always" | "hourly" | "daily" | "weekly" | "monthly" | "yearly" | "never" }[] = [
    // 1. Core & Main Pages
    { path: "", priority: 1.0, changeFrequency: "daily" },
    { path: "/guide", priority: 0.9, changeFrequency: "daily" },

    // 2. Agency Portal, Referral & Directory
    { path: "/agencies", priority: 0.9, changeFrequency: "weekly" },
    { path: "/agency-referral", priority: 0.9, changeFrequency: "weekly" },
    { path: "/agency-demo", priority: 0.8, changeFrequency: "weekly" },
    { path: "/agency-stats", priority: 0.7, changeFrequency: "weekly" },
    { path: "/real-estate-agencies", priority: 0.8, changeFrequency: "weekly" },
    { path: "/find-agency", priority: 0.8, changeFrequency: "weekly" },
    { path: "/acente-bul", priority: 0.8, changeFrequency: "weekly" },

    // 3. Belgrade Guides
    { path: "/guide/belgrad-kiralik-daire-rehberi", priority: 0.8, changeFrequency: "weekly" },
    { path: "/guide/belgrade-apartment-rental-guide", priority: 0.8, changeFrequency: "weekly" },
    { path: "/guide/vodic-za-izdavanje-stanova-beograd", priority: 0.8, changeFrequency: "weekly" },
    { path: "/guide/vodic-za-izdavanje-stanova-beograd-cirilica", priority: 0.8, changeFrequency: "weekly" },
    { path: "/guide/belgrade-apartment-rental-guide-ru", priority: 0.8, changeFrequency: "weekly" },

    // 4. Novi Sad Guides
    { path: "/guide/novi-sad-mulk-yonetimi-rehberi", priority: 0.8, changeFrequency: "weekly" },
    { path: "/guide/novi-sad-property-management-guide", priority: 0.8, changeFrequency: "weekly" },
    { path: "/guide/upravljanje-nekretninama-novi-sad", priority: 0.8, changeFrequency: "weekly" },
    { path: "/guide/upravljanje-nekretninama-novi-sad-cirilica", priority: 0.8, changeFrequency: "weekly" },
    { path: "/guide/novi-sad-property-management-guide-ru", priority: 0.8, changeFrequency: "weekly" },

    // 5. Lease Agreement Guides
    { path: "/guide/sirbistan-kira-sozlesmesi-rehberi", priority: 0.8, changeFrequency: "weekly" },
    { path: "/guide/serbia-lease-agreement-guide", priority: 0.8, changeFrequency: "weekly" },
    { path: "/guide/ugovor-o-zakupu-stana-srbija", priority: 0.8, changeFrequency: "weekly" },
    { path: "/guide/ugovor-o-zakupu-stana-srbija-cirilica", priority: 0.8, changeFrequency: "weekly" },
    { path: "/guide/serbia-lease-agreement-guide-ru", priority: 0.8, changeFrequency: "weekly" },

    // 6. Digital Nomads & Beli Karton Guides
    { path: "/guide/dijital-gocmenlere-ev-kiralama-beli-karton", priority: 0.8, changeFrequency: "weekly" },
    { path: "/guide/renting-to-foreigners-digital-nomads-beli-karton", priority: 0.8, changeFrequency: "weekly" },
    { path: "/guide/izdavanje-stana-strancima-beli-karton", priority: 0.8, changeFrequency: "weekly" },
    { path: "/guide/izdavanje-stana-strancima-beli-karton-cirilica", priority: 0.8, changeFrequency: "weekly" },
    { path: "/guide/renting-to-foreigners-digital-nomads-beli-karton-ru", priority: 0.8, changeFrequency: "weekly" },

    // 7. Clean Canonical Aliases
    { path: "/belgrad-kiralik-daire-rehberi", priority: 0.7, changeFrequency: "weekly" },
    { path: "/belgrade-apartment-rental-guide", priority: 0.7, changeFrequency: "weekly" },
    { path: "/vodic-za-izdavanje-stanova-beograd", priority: 0.7, changeFrequency: "weekly" },
    { path: "/vodic-za-izdavanje-stanova-beograd-cirilica", priority: 0.7, changeFrequency: "weekly" },
    { path: "/belgrade-apartment-rental-guide-ru", priority: 0.7, changeFrequency: "weekly" },
    { path: "/novi-sad-mulk-yonetimi-rehberi", priority: 0.7, changeFrequency: "weekly" },
    { path: "/novi-sad-property-management-guide", priority: 0.7, changeFrequency: "weekly" },
    { path: "/upravljanje-nekretninama-novi-sad", priority: 0.7, changeFrequency: "weekly" },
    { path: "/upravljanje-nekretninama-novi-sad-cirilica", priority: 0.7, changeFrequency: "weekly" },
    { path: "/novi-sad-property-management-guide-ru", priority: 0.7, changeFrequency: "weekly" },
    { path: "/sirbistan-kira-sozlesmesi-rehberi", priority: 0.7, changeFrequency: "weekly" },
    { path: "/serbia-lease-agreement-guide", priority: 0.7, changeFrequency: "weekly" },
    { path: "/ugovor-o-zakupu-stana-srbija", priority: 0.7, changeFrequency: "weekly" },
    { path: "/ugovor-o-zakupu-stana-srbija-cirilica", priority: 0.7, changeFrequency: "weekly" },
    { path: "/serbia-lease-agreement-guide-ru", priority: 0.7, changeFrequency: "weekly" },
    { path: "/dijital-gocmenlere-ev-kiralama-beli-karton", priority: 0.7, changeFrequency: "weekly" },
    { path: "/renting-to-foreigners-digital-nomads-beli-karton", priority: 0.7, changeFrequency: "weekly" },
    { path: "/izdavanje-stana-strancima-beli-karton", priority: 0.7, changeFrequency: "weekly" },
    { path: "/izdavanje-stana-strancima-beli-karton-cirilica", priority: 0.7, changeFrequency: "weekly" },
    { path: "/renting-to-foreigners-digital-nomads-beli-karton-ru", priority: 0.7, changeFrequency: "weekly" },

    // 8. Legal, Support, Updates
    { path: "/changelog", priority: 0.6, changeFrequency: "weekly" },
    { path: "/support", priority: 0.6, changeFrequency: "monthly" },
    { path: "/tr/support", priority: 0.6, changeFrequency: "monthly" },
    { path: "/privacy", priority: 0.5, changeFrequency: "monthly" },
    { path: "/terms", priority: 0.5, changeFrequency: "monthly" }
  ];

  return routes.map((r) => ({
    url: `${baseUrl}${r.path}`,
    lastModified,
    changeFrequency: r.changeFrequency,
    priority: r.priority
  }));
}
