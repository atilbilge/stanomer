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
    // Aliases
    "/belgrad-kiralik-daire-rehberi",
    "/belgrade-apartment-rental-guide",
    "/vodic-za-izdavanje-stanova-beograd",
    "/vodic-za-izdavanje-stanova-beograd-cirilica",
    "/belgrade-apartment-rental-guide-ru",
    "/novi-sad-mulk-yonetimi-rehberi",
    "/novi-sad-property-management-guide",
    "/upravljanje-nekretninama-novi-sad",
    "/upravljanje-nekretninama-novi-sad-cirilica",
    "/novi-sad-property-management-guide-ru",
    "/sirbistan-kira-sozlesmesi-rehberi",
    "/serbia-lease-agreement-guide",
    "/ugovor-o-zakupu-stana-srbija",
    "/ugovor-o-zakupu-stana-srbija-cirilica",
    "/serbia-lease-agreement-guide-ru",
    "/dijital-gocmenlere-ev-kiralama-beli-karton",
    "/renting-to-foreigners-digital-nomads-beli-karton",
    "/izdavanje-stana-strancima-beli-karton",
    "/izdavanje-stana-strancima-beli-karton-cirilica",
    "/renting-to-foreigners-digital-nomads-beli-karton-ru",
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
