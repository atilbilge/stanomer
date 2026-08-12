"use client";

export interface UtmParams {
  utm_source: string | null;
  utm_medium: string | null;
  utm_campaign: string | null;
}

const STORAGE_KEYS = {
  SOURCE: "stanomer_utm_source",
  MEDIUM: "stanomer_utm_medium",
  CAMPAIGN: "stanomer_utm_campaign",
};

function getUrlSearchParam(key: string): string | null {
  if (typeof window === "undefined") return null;
  try {
    const urlParams = new URLSearchParams(window.location.search);
    const val = urlParams.get(key);
    if (val && val.trim().length > 0) return val.trim();

    // Fallback: parse from full URL string
    const fullUrl = new URL(window.location.href);
    const fallbackVal = fullUrl.searchParams.get(key);
    if (fallbackVal && fallbackVal.trim().length > 0) return fallbackVal.trim();
  } catch (e) {
    // Ignore URL parsing errors
  }
  return null;
}

export function captureUtmParams(): UtmParams {
  if (typeof window === "undefined") {
    return { utm_source: null, utm_medium: null, utm_campaign: null };
  }

  const source = getUrlSearchParam("utm_source");
  const medium = getUrlSearchParam("utm_medium");
  const campaign = getUrlSearchParam("utm_campaign");

  if (source) {
    sessionStorage.setItem(STORAGE_KEYS.SOURCE, source);
    localStorage.setItem(STORAGE_KEYS.SOURCE, source);
  }
  if (medium) {
    sessionStorage.setItem(STORAGE_KEYS.MEDIUM, medium);
    localStorage.setItem(STORAGE_KEYS.MEDIUM, medium);
  }
  if (campaign) {
    sessionStorage.setItem(STORAGE_KEYS.CAMPAIGN, campaign);
    localStorage.setItem(STORAGE_KEYS.CAMPAIGN, campaign);
  }

  return getStoredUtmParams();
}

export function getStoredUtmParams(): UtmParams {
  if (typeof window === "undefined") {
    return { utm_source: null, utm_medium: null, utm_campaign: null };
  }

  const sourceFromUrl = getUrlSearchParam("utm_source");
  const mediumFromUrl = getUrlSearchParam("utm_medium");
  const campaignFromUrl = getUrlSearchParam("utm_campaign");

  const source =
    sourceFromUrl ||
    sessionStorage.getItem(STORAGE_KEYS.SOURCE) ||
    localStorage.getItem(STORAGE_KEYS.SOURCE) ||
    null;

  const medium =
    mediumFromUrl ||
    sessionStorage.getItem(STORAGE_KEYS.MEDIUM) ||
    localStorage.getItem(STORAGE_KEYS.MEDIUM) ||
    null;

  const campaign =
    campaignFromUrl ||
    sessionStorage.getItem(STORAGE_KEYS.CAMPAIGN) ||
    localStorage.getItem(STORAGE_KEYS.CAMPAIGN) ||
    null;

  return {
    utm_source: source,
    utm_medium: medium,
    utm_campaign: campaign,
  };
}
