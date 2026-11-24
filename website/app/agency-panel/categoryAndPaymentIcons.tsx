"use client";

import React from "react";
import {
  Building2,
  Car,
  CheckCircle2,
  Droplets,
  Flame,
  Home,
  LucideIcon,
  Receipt,
  ShieldCheck,
  Sparkles,
  Tv,
  Wifi,
  Wrench,
  Zap,
} from "lucide-react";

/**
 * ─────────────────────────────────────────────────────────────────
 * 1. PAYMENT & EXPENSE TYPE ICON MAPPING (100% FLUTTER PARITY)
 * Source of truth: lib/features/property/presentation/property_detail_screen.dart:11063-11089
 * ─────────────────────────────────────────────────────────────────
 */
export interface PaymentIconMeta {
  Icon: LucideIcon;
  bgClass: string;
  textClass: string;
  borderClass: string;
}

/**
 * Human-readable label for Maintenance Ticket Status
 * Guaranteed to NEVER render a raw key like "agency_maint_status_..."
 */
export function getMaintenanceStatusLabel(
  status: string | null | undefined,
  t: (key: string) => string
): string {
  if (!status) return "";
  const key = "agency_maint_status_" + status;
  const translated = t(key);
  if (!translated || translated === key || translated.startsWith("agency_maint_status_")) {
    if (status === "open" || status === "pending") return t("agency_maint_status_open");
    if (status === "in_progress") return t("agency_maint_status_in_progress");
    if (status === "investigating") return t("agency_maint_status_investigating");
    if (status === "resolved") return t("agency_maint_status_resolved");
    if (status === "closed") return t("agency_maint_status_closed");
    if (status === "cancelled") return t("agency_maint_status_cancelled");
    return status;
  }
  return translated;
}

/**
 * Human-readable label for Maintenance Payment/Expense Status
 * Guaranteed to NEVER render a raw key like "agency_maint_status_..."
 */
export function getMaintenanceExpenseStatusLabel(
  status: string | null | undefined,
  t: (key: string) => string
): string {
  if (!status) return t("agency_maint_status_no_expense");
  const key = "agency_maint_status_" + status;
  const translated = t(key);
  // If untranslated or returned raw key
  if (!translated || translated === key || translated.startsWith("agency_maint_status_")) {
    if (status.includes("agency")) {
      return t("agency_maint_status_pending_agency_approval");
    }
    if (status.includes("landlord")) {
      return t("agency_maint_status_pending_landlord_approval");
    }
    if (status.includes("tenant")) {
      return t("agency_maint_status_pending_tenant_approval");
    }
    if (status.includes("approval") || status.includes("review") || status.includes("appr")) {
      return t("agency_maint_status_pending_appr");
    }
    if (status.includes("pay") || status.includes("offset")) {
      return t("agency_maint_status_pending_payment");
    }
    if (status.includes("paid") || status.includes("settle")) {
      return t("agency_maint_status_paid");
    }
    if (status.includes("reject")) {
      return t("agency_maint_status_rejected");
    }
    return t("agency_maint_status_pending_review");
  }
  return translated;
}

export function formatCurrencyAmount(amount: number, currency: string = "EUR"): string {
  const num = Number(amount) || 0;
  const formatted = num.toLocaleString("de-DE", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
  return `${formatted} ${currency.toUpperCase()}`;
}

export function getPaymentIconMeta(
  title?: string,
  isMaintenance?: boolean,
  isPaid?: boolean
): PaymentIconMeta {
  const t = (title || "").toLowerCase().trim();

  // If this is a settled/paid maintenance record:
  if (isMaintenance && isPaid) {
    return {
      Icon: CheckCircle2,
      bgClass: "bg-emerald-50",
      textClass: "text-emerald-600",
      borderClass: "border-emerald-200",
    };
  }

  // Active / pending Maintenance Settlement
  if (isMaintenance) {
    return {
      Icon: Wrench,
      bgClass: "bg-purple-50",
      textClass: "text-purple-600",
      borderClass: "border-purple-200",
    };
  }

  // Building Maintenance / Infostan / Dues / Info / Održavanje
  // Matches Flutter: if (t.contains('info') || t.contains('aidat') || t.contains('maintenance') || t.contains('održavanje')) return LucideIcons.building
  if (
    t.includes("info") ||
    t.includes("aidat") ||
    t.includes("komunal") ||
    t.includes("upravnik") ||
    t.includes("building") ||
    t.includes("bina") ||
    t.includes("održavanje") ||
    t.includes("maintenance")
  ) {
    return {
      Icon: Building2,
      bgClass: "bg-stone-100",
      textClass: "text-stone-700",
      borderClass: "border-stone-200",
    };
  }

  // General maintenance repairs (when not explicitly isMaintenance flag)
  if (
    t.includes("bakım") ||
    t.includes("arıza") ||
    t.includes("tamir") ||
    t.includes("poprav") ||
    t.includes("repair")
  ) {
    return {
      Icon: Wrench,
      bgClass: "bg-purple-50",
      textClass: "text-purple-600",
      borderClass: "border-purple-200",
    };
  }

  // Rent
  if (
    t === "kira" ||
    t === "rent" ||
    t.includes("kira") ||
    t.includes("zakup") ||
    t.includes("kirij")
  ) {
    return {
      Icon: Home,
      bgClass: "bg-[#E5EEF6]",
      textClass: "text-[#1B5888]",
      borderClass: "border-[#1B5888]/20",
    };
  }

  // Internet / TV / Cable
  if (
    t.includes("internet") ||
    t.includes("tv") ||
    t.includes("wifi") ||
    t.includes("kablovsk") ||
    t.includes("sbb") ||
    t.includes("mts")
  ) {
    return {
      Icon: Wifi,
      bgClass: "bg-indigo-50",
      textClass: "text-indigo-600",
      borderClass: "border-indigo-200",
    };
  }

  // Electricity
  if (
    t.includes("elektr") ||
    t.includes("electr") ||
    t.includes("struja") ||
    t.includes("eps")
  ) {
    return {
      Icon: Zap,
      bgClass: "bg-amber-50",
      textClass: "text-amber-700",
      borderClass: "border-amber-200",
    };
  }

  // Water
  if (t.includes("su") || t.includes("water") || t.includes("voda") || t.includes("vodovod")) {
    return {
      Icon: Droplets,
      bgClass: "bg-sky-50",
      textClass: "text-sky-600",
      borderClass: "border-sky-200",
    };
  }

  // Building Maintenance / Infostan / Dues / Info
  if (
    t.includes("info") ||
    t.includes("aidat") ||
    t.includes("komunal") ||
    t.includes("upravnik")
  ) {
    return {
      Icon: Building2,
      bgClass: "bg-stone-100",
      textClass: "text-stone-700",
      borderClass: "border-stone-200",
    };
  }

  // Garage / Parking
  if (t.includes("gara") || t.includes("park") || t.includes("otopark")) {
    return {
      Icon: Car,
      bgClass: "bg-teal-50",
      textClass: "text-teal-700",
      borderClass: "border-teal-200",
    };
  }

  // Gas / Heating / Warmth
  if (
    t.includes("gas") ||
    t.includes("gaz") ||
    t.includes("grejan") ||
    t.includes("ısı") ||
    t.includes("heat") ||
    t.includes("kombi") ||
    t.includes("toplana")
  ) {
    return {
      Icon: Flame,
      bgClass: "bg-orange-50",
      textClass: "text-orange-600",
      borderClass: "border-orange-200",
    };
  }

  // Cleaning
  if (t.includes("temiz") || t.includes("clean") || t.includes("čišć")) {
    return {
      Icon: Sparkles,
      bgClass: "bg-cyan-50",
      textClass: "text-cyan-700",
      borderClass: "border-cyan-200",
    };
  }

  // Security
  if (t.includes("güven") || t.includes("secur") || t.includes("obezb")) {
    return {
      Icon: ShieldCheck,
      bgClass: "bg-slate-100",
      textClass: "text-slate-700",
      borderClass: "border-slate-300",
    };
  }

  // Default Bill
  return {
    Icon: Receipt,
    bgClass: "bg-[#FBF1DC]",
    textClass: "text-[#8A5206]",
    borderClass: "border-[#8A5206]/20",
  };
}

/**
 * Visual badge for Payment Plan items
 */
export function PaymentTypeIconBadge({
  title,
  isMaintenance,
  isPaid,
  size = "md",
  className = "",
}: {
  title?: string;
  isMaintenance?: boolean;
  isPaid?: boolean;
  size?: "sm" | "md" | "lg";
  className?: string;
}) {
  const meta = getPaymentIconMeta(title, isMaintenance, isPaid);
  const IconComponent = meta.Icon;

  const sizeClasses =
    size === "sm"
      ? "w-7 h-7 rounded-lg"
      : size === "lg"
      ? "w-10 h-10 rounded-xl"
      : "w-9 h-9 rounded-[10px]";

  const iconSizes = size === "sm" ? "w-3.5 h-3.5" : size === "lg" ? "w-5 h-5" : "w-4 h-4";

  return (
    <div
      className={`${sizeClasses} ${meta.bgClass} ${meta.textClass} border ${meta.borderClass} flex items-center justify-center shrink-0 ${className}`}
    >
      <IconComponent className={iconSizes} />
    </div>
  );
}

/**
 * ─────────────────────────────────────────────────────────────────
 * 2. MAINTENANCE CATEGORY METADATA & ICONS (100% FLUTTER PARITY)
 * Source of truth: lib/features/maintenance/presentation/create_maintenance_screen.dart:1086-1093
 * ─────────────────────────────────────────────────────────────────
 */
export interface CategoryMeta {
  key: string;
  translationKey: string;
  icon: LucideIcon;
  color: string;
  bgClass: string;
  textClass: string;
  borderClass: string;
  ringClass: string;
}

export const MAINTENANCE_CATEGORIES: CategoryMeta[] = [
  {
    key: "plumbing",
    translationKey: "agency_maint_cat_plumbing",
    icon: Droplets,
    color: "#0284C7",
    bgClass: "bg-sky-50",
    textClass: "text-sky-600",
    borderClass: "border-sky-200",
    ringClass: "ring-sky-500",
  },
  {
    key: "electrical",
    translationKey: "agency_maint_cat_electrical",
    icon: Zap,
    color: "#D97706",
    bgClass: "bg-amber-50",
    textClass: "text-amber-600",
    borderClass: "border-amber-200",
    ringClass: "ring-amber-500",
  },
  {
    key: "heating",
    translationKey: "agency_maint_cat_heating",
    icon: Flame,
    color: "#EA580C",
    bgClass: "bg-orange-50",
    textClass: "text-orange-600",
    borderClass: "border-orange-200",
    ringClass: "ring-orange-500",
  },
  {
    key: "appliances",
    translationKey: "agency_maint_cat_appliances",
    icon: Tv,
    color: "#9333EA",
    bgClass: "bg-purple-50",
    textClass: "text-purple-600",
    borderClass: "border-purple-200",
    ringClass: "ring-purple-500",
  },
  {
    key: "internet",
    translationKey: "agency_maint_cat_internet",
    icon: Wifi,
    color: "#4F46E5",
    bgClass: "bg-indigo-50",
    textClass: "text-indigo-600",
    borderClass: "border-indigo-200",
    ringClass: "ring-indigo-500",
  },
  {
    key: "structural",
    translationKey: "agency_maint_cat_structural",
    icon: Building2,
    color: "#475569",
    bgClass: "bg-slate-100",
    textClass: "text-slate-600",
    borderClass: "border-slate-300",
    ringClass: "ring-slate-500",
  },
  {
    key: "other",
    translationKey: "agency_maint_cat_other",
    icon: Wrench,
    color: "#0F766E",
    bgClass: "bg-teal-50",
    textClass: "text-teal-700",
    borderClass: "border-teal-200",
    ringClass: "ring-teal-500",
  },
];

export function getMaintenanceCategoryMeta(category?: string): CategoryMeta {
  const norm = (category || "").toLowerCase();
  const found = MAINTENANCE_CATEGORIES.find(
    (c) => c.key === norm || (norm === "appliance" && c.key === "appliances")
  );
  return found || MAINTENANCE_CATEGORIES[MAINTENANCE_CATEGORIES.length - 1]; // fallback to other
}

/**
 * Visual badge for Maintenance Category
 */
export function MaintenanceCategoryBadge({
  category,
  label,
  className = "",
}: {
  category?: string;
  label?: string;
  className?: string;
}) {
  const meta = getMaintenanceCategoryMeta(category);
  const IconComponent = meta.icon;

  return (
    <span
      className={`inline-flex items-center gap-1.5 px-2 py-0.5 rounded-md text-[10px] font-semibold border ${meta.bgClass} ${meta.textClass} ${meta.borderClass} ${className}`}
    >
      <IconComponent className="w-3 h-3 shrink-0" />
      {label && <span>{label}</span>}
    </span>
  );
}
