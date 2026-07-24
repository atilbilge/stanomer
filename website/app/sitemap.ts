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
