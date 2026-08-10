import { MetadataRoute } from "next";

export const dynamic = "force-static";

export default function sitemap(): MetadataRoute.Sitemap {
  const baseUrl = "https://www.stanomer.online";
  const lastModified = new Date();

  const routes = [
    "",
    "/guide",
    // Belgrade Guides
    "/guide/belgrad-kiralik-daire-rehberi",
    "/guide/belgrade-apartment-rental-guide",
    "/guide/vodic-za-izdavanje-stanova-beograd",
    "/guide/vodic-za-izdavanje-stanova-beograd-cirilica",
    "/guide/belgrade-apartment-rental-guide-ru",
    // Novi Sad Guides
    "/guide/novi-sad-mulk-yonetimi-rehberi",
    "/guide/novi-sad-property-management-guide",
    "/guide/upravljanje-nekretninama-novi-sad",
    "/guide/upravljanje-nekretninama-novi-sad-cirilica",
    "/guide/novi-sad-property-management-guide-ru",
    // Lease Agreement Guides
    "/guide/sirbistan-kira-sozlesmesi-rehberi",
    "/guide/serbia-lease-agreement-guide",
    "/guide/ugovor-o-zakupu-stana-srbija",
    "/guide/ugovor-o-zakupu-stana-srbija-cirilica",
    "/guide/serbia-lease-agreement-guide-ru",
    // Digital Nomads & Beli Karton Guides
    "/guide/dijital-gocmenlere-ev-kiralama-beli-karton",
    "/guide/renting-to-foreigners-digital-nomads-beli-karton",
    "/guide/izdavanje-stana-strancima-beli-karton",
    "/guide/izdavanje-stana-strancima-beli-karton-cirilica",
    "/guide/renting-to-foreigners-digital-nomads-beli-karton-ru",
    // Agency Routes
    "/agencies",
    "/agency-demo",
    // Legal & Support
    "/privacy",
    "/terms",
    "/changelog",
    "/support"
  ];

  return routes.map((route) => ({
    url: `${baseUrl}${route}`,
    lastModified,
    changeFrequency: route === "" || route === "/guide" ? "daily" : "weekly",
    priority: route === "" ? 1.0 : route.startsWith("/guide/") ? 0.8 : 0.7,
  }));
}
