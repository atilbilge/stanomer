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

export function captureUtmParams(): UtmParams {
  if (typeof window === "undefined") {
    return { utm_source: null, utm_medium: null, utm_campaign: null };
  }

  const urlParams = new URLSearchParams(window.location.search);
  const source = urlParams.get("utm_source");
  const medium = urlParams.get("utm_medium");
  const campaign = urlParams.get("utm_campaign");

  if (source) {
    sessionStorage.setItem(STORAGE_KEYS.SOURCE, source);
  }
  if (medium) {
    sessionStorage.setItem(STORAGE_KEYS.MEDIUM, medium);
  }
  if (campaign) {
    sessionStorage.setItem(STORAGE_KEYS.CAMPAIGN, campaign);
  }

  return getStoredUtmParams();
}

export function getStoredUtmParams(): UtmParams {
  if (typeof window === "undefined") {
    return { utm_source: null, utm_medium: null, utm_campaign: null };
  }

  const urlParams = new URLSearchParams(window.location.search);
  const sourceFromUrl = urlParams.get("utm_source");
  const mediumFromUrl = urlParams.get("utm_medium");
  const campaignFromUrl = urlParams.get("utm_campaign");

  return {
    utm_source: sourceFromUrl || sessionStorage.getItem(STORAGE_KEYS.SOURCE) || null,
    utm_medium: mediumFromUrl || sessionStorage.getItem(STORAGE_KEYS.MEDIUM) || null,
    utm_campaign: campaignFromUrl || sessionStorage.getItem(STORAGE_KEYS.CAMPAIGN) || null,
  };
}
