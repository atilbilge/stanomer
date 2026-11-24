"use client";

import React, { useState, useEffect } from "react";
import Link from "next/link";
import {
  User,
  Shield,
  KeyRound,
  LogOut,
  Trash2,
  Globe,
  HelpCircle,
  FileText,
  CheckCircle2,
  AlertCircle,
  X,
  ExternalLink,
  ChevronRight,
  Sparkles,
  Type,
  Mail,
  Tag,
  Layers,
  Inbox,
  Rss,
  LayoutDashboard,
  Home,
  Wallet,
  Wrench,
  CreditCard,
  Download,
  Eye,
  Check,
  Lock,
  Printer,
  Receipt,
  PackageCheck,
  Clock,
  Calendar,
  Building2,
  ArrowUpRight,
  Boxes,
  Share2,
  ArrowRight,
  Plus,
} from "lucide-react";
import { AgencyPanelTab } from "../types";
import { supabase } from "../../../lib/supabaseClient";

export interface AccountSettingsTabProps {
  user: any;
  userId: string | null;
  agencyName: string;
  agencyEmail: string;
  isDemoMode: boolean;
  lang: string;
  setLang: (l: any) => void;
  handleSignOut: () => Promise<void>;
  t: (key: string) => string;
  tSafe: (key: string, replacements?: Record<string, string | number>) => string;
  activeModules?: string[];
  onActivateModule?: (moduleKey: string) => void;
  setActiveTab?: (tab: AgencyPanelTab) => void;
  moduleUpgradeRequested?: boolean;
  handleRequestModuleUpgrade?: () => void;
}

export interface AgencyInvoice {
  id: string;
  agency_id?: string;
  invoice_number: string;
  period: string;
  amount: number;
  currency: string;
  status: "paid" | "pending" | "overdue";
  due_date?: string | null;
  paid_at?: string | null;
  pdf_url?: string | null;
  created_at?: string;
}

export interface AgencySubscriptionInfo {
  plan: string;
  status: string;
  active_modules: string[];
  monthly_fee: number;
  currency: string;
  next_billing_date: string | null;
}

export interface StanomerPackageDefinition {
  key: "portfolio_distribution" | "property_lease_management";
  titleKey: string;
  descKey: string;
  icon: any;
  color: string;
  badgeBg: string;
  includedTools: {
    key: string;
    titleKey: string;
    icon: any;
  }[];
}

const DEMO_INVOICES: AgencyInvoice[] = [
  {
    id: "demo-inv-11",
    invoice_number: "INV-2026-011",
    period: "11/2026 - Novembar 2026",
    amount: 74.9,
    currency: "EUR",
    status: "paid",
    due_date: "2026-11-05",
    paid_at: "2026-11-02T10:30:00Z",
    created_at: "2026-11-01T08:00:00Z",
  },
  {
    id: "demo-inv-10",
    invoice_number: "INV-2026-010",
    period: "10/2026 - Oktobar 2026",
    amount: 74.9,
    currency: "EUR",
    status: "paid",
    due_date: "2026-10-05",
    paid_at: "2026-10-02T11:15:00Z",
    created_at: "2026-10-01T08:00:00Z",
  },
  {
    id: "demo-inv-09",
    invoice_number: "INV-2026-009",
    period: "09/2026 - Septembar 2026",
    amount: 74.9,
    currency: "EUR",
    status: "paid",
    due_date: "2026-09-05",
    paid_at: "2026-09-03T09:45:00Z",
    created_at: "2026-09-01T08:00:00Z",
  },
  {
    id: "demo-inv-08",
    invoice_number: "INV-2026-008",
    period: "08/2026 - Avgust 2026",
    amount: 74.9,
    currency: "EUR",
    status: "paid",
    due_date: "2026-08-05",
    paid_at: "2026-08-02T14:20:00Z",
    created_at: "2026-08-01T08:00:00Z",
  },
];

// STANOMER 2 CORE MODULE PACKAGES
const STANOMER_PACKAGES: StanomerPackageDefinition[] = [
  {
    key: "portfolio_distribution",
    titleKey: "agency_panel_pkg_portfolio_distribution_title",
    descKey: "agency_panel_pkg_portfolio_distribution_desc",
    icon: Layers,
    color: "text-[#1B5888] bg-[#E5EEF6]",
    badgeBg: "bg-[#E5EEF6] text-[#1B5888] border-[#1B5888]/20",
    includedTools: [
      { key: "listings", titleKey: "agency_panel_pkg_listings_title", icon: Layers },
      { key: "leads", titleKey: "agency_panel_pkg_leads_title", icon: Inbox },
      { key: "xml", titleKey: "agency_panel_pkg_xml_title", icon: Rss },
      { key: "showcase", titleKey: "agency_panel_pkg_showcase_title", icon: Globe },
    ],
  },
  {
    key: "property_lease_management",
    titleKey: "agency_panel_pkg_property_lease_title",
    descKey: "agency_panel_pkg_property_lease_desc",
    icon: Building2,
    color: "text-purple-700 bg-purple-50",
    badgeBg: "bg-purple-50 text-purple-700 border-purple-200",
    includedTools: [
      { key: "pm_dashboard", titleKey: "agency_panel_pkg_pm_dash_title", icon: LayoutDashboard },
      { key: "managed_properties", titleKey: "agency_panel_pkg_managed_props_title", icon: Home },
      { key: "payments", titleKey: "agency_panel_pkg_payments_title", icon: Wallet },
      { key: "maintenance", titleKey: "agency_panel_pkg_maintenance_title", icon: Wrench },
      { key: "contracts", titleKey: "agency_panel_pkg_contracts_title", icon: FileText },
    ],
  },
];

export default function AccountSettingsTab({
  user,
  userId,
  agencyName,
  agencyEmail,
  isDemoMode,
  lang,
  setLang,
  handleSignOut,
  t,
  tSafe,
  activeModules,
  onActivateModule,
  setActiveTab,
  moduleUpgradeRequested = false,
  handleRequestModuleUpgrade,
}: AccountSettingsTabProps) {
  // Sub-tab state: "account" (Packages & Invoices) vs "profile" (Profile, Security & Preferences)
  const [activeSubTab, setActiveSubTab] = useState<"account" | "profile">("account");

  // Profile update state
  const [fullName, setFullName] = useState<string>(
    user?.user_metadata?.full_name || agencyName || ""
  );
  const [isUpdatingName, setIsUpdatingName] = useState<boolean>(false);
  const [nameSuccessMessage, setNameSuccessMessage] = useState<string | null>(null);
  const [nameErrorMessage, setNameErrorMessage] = useState<string | null>(null);

  // Change Password State
  const [isPasswordModalOpen, setIsPasswordModalOpen] = useState<boolean>(false);
  const [newPassword, setNewPassword] = useState<string>("");
  const [confirmPassword, setConfirmPassword] = useState<string>("");
  const [isUpdatingPassword, setIsUpdatingPassword] = useState<boolean>(false);
  const [passwordSuccessMessage, setPasswordSuccessMessage] = useState<string | null>(null);
  const [passwordErrorMessage, setPasswordErrorMessage] = useState<string | null>(null);

  // Delete Account State
  const [isDeleteModalOpen, setIsDeleteModalOpen] = useState<boolean>(false);
  const [isDeleting, setIsDeleting] = useState<boolean>(false);
  const [deleteErrorMessage, setDeleteErrorMessage] = useState<string | null>(null);

  // Support Ticket Modal state
  const [isSupportModalOpen, setIsSupportModalOpen] = useState<boolean>(false);
  const [supportSubject, setSupportSubject] = useState<string>("");
  const [supportEmail, setSupportEmail] = useState<string>(
    user?.email || agencyEmail || ""
  );
  const [supportCategory, setSupportCategory] = useState<string>("Support");
  const [supportMessage, setSupportMessage] = useState<string>("");
  const [isSendingSupport, setIsSendingSupport] = useState<boolean>(false);
  const [supportSuccess, setSupportSuccess] = useState<boolean>(false);
  const [supportError, setSupportError] = useState<string | null>(null);
  const [supportValidationErrors, setSupportValidationErrors] = useState<{
    subject?: string;
    email?: string;
    message?: string;
  }>({});

  // Subscription and Invoices State
  const [subscription, setSubscription] = useState<AgencySubscriptionInfo>({
    plan: "Stanomer Professional Agency Suite",
    status: "active",
    active_modules: ["portfolio_distribution", "property_lease_management"],
    monthly_fee: 74.9,
    currency: "EUR",
    next_billing_date: "2026-12-01",
  });
  const [invoices, setInvoices] = useState<AgencyInvoice[]>([]);
  const [loadingBilling, setLoadingBilling] = useState<boolean>(false);

  // Invoice Preview Modal State
  const [selectedInvoice, setSelectedInvoice] = useState<AgencyInvoice | null>(null);

  // Load Subscription & Invoices from DB
  useEffect(() => {
    let mounted = true;
    async function loadSubscriptionAndInvoices() {
      if (isDemoMode || !userId) {
        const currentModules = activeModules && activeModules.length > 0
          ? activeModules
          : ["portfolio_distribution", "property_lease_management"];

        let planTitle = "Stanomer All-in-One Professional Suite";
        if (currentModules.length === 1) {
          planTitle = currentModules[0] === "portfolio_distribution"
            ? "Portfolio & Distribution Suite"
            : "Property & Lease Management Suite";
        }

        setSubscription({
          plan: planTitle,
          status: "active",
          active_modules: currentModules,
          monthly_fee: 74.9,
          currency: "EUR",
          next_billing_date: "2026-12-01",
        });
        setInvoices([]);
        setLoadingBilling(false);
        return;
      }

      setLoadingBilling(true);
      try {
        // 1. Fetch profile subscription data
        const { data: profData } = await supabase
          .from("profiles")
          .select(
            "subscription_plan, subscription_status, active_modules, monthly_fee, billing_currency, next_billing_date, color_scheme"
          )
          .eq("id", userId)
          .maybeSingle();

        if (profData && mounted) {
          let rawModules =
            profData.active_modules ||
            (profData.color_scheme as any)?.active_modules ||
            (profData.color_scheme as any)?.packages;

          if (typeof window !== "undefined") {
            try {
              const s = localStorage.getItem("stanomer_agency_demo");
              if (s) {
                const p = JSON.parse(s);
                if (p.active_modules && Array.isArray(p.active_modules)) {
                  rawModules = Array.from(new Set([...(rawModules || []), ...p.active_modules]));
                }
              }
            } catch {}
          }
          if (activeModules && activeModules.length > 0) {
            rawModules = Array.from(new Set([...(rawModules || []), ...activeModules]));
          }

          const parsedModules = Array.isArray(rawModules) && rawModules.length > 0
            ? rawModules
            : ["portfolio_distribution", "property_lease_management"];

          setSubscription({
            plan: profData.subscription_plan || "Stanomer Standard",
            status: profData.subscription_status || "active",
            active_modules: parsedModules,
            monthly_fee: profData.monthly_fee ? Number(profData.monthly_fee) : 0,
            currency: profData.billing_currency || "EUR",
            next_billing_date: profData.next_billing_date || null,
          });
        }

        // 2. Fetch agency invoices (capped at 50 to minimize egress)
        const { data: invData } = await supabase
          .from("agency_invoices")
          .select("id, agency_id, invoice_number, period, amount, currency, status, due_date, paid_at, pdf_url, created_at")
          .eq("agency_id", userId)
          .order("created_at", { ascending: false })
          .limit(50);

        if (mounted) {
          if (invData && invData.length > 0) {
            setInvoices(invData as unknown as AgencyInvoice[]);
          } else {
            setInvoices([]);
          }
        }
      } catch (err) {
        console.warn("Could not load billing data:", err);
      } finally {
        if (mounted) setLoadingBilling(false);
      }
    }

    loadSubscriptionAndInvoices();
    return () => {
      mounted = false;
    };
  }, [userId, isDemoMode, activeModules]);

  // Check if a package is active (supports package key or constituent tools)
  function isPackageActive(pkgKey: "portfolio_distribution" | "property_lease_management"): boolean {
    const activeList = subscription.active_modules || [];
    if (activeList.includes(pkgKey)) return true;
    if (pkgKey === "portfolio_distribution") {
      return activeList.some((k) =>
        ["portfolio_distribution", "listings", "leads", "xml", "showcase"].includes(k)
      );
    }
    if (pkgKey === "property_lease_management") {
      return activeList.some((k) =>
        [
          "property_lease_management",
          "pm_dashboard",
          "managed_properties",
          "payments",
          "maintenance",
          "contracts",
        ].includes(k)
      );
    }
    return false;
  }

  // Update Name Handler
  async function handleUpdateName(e: React.FormEvent) {
    e.preventDefault();
    if (!fullName.trim()) return;

    setIsUpdatingName(true);
    setNameSuccessMessage(null);
    setNameErrorMessage(null);

    try {
      if (!userId || userId === "demo") {
        await new Promise((res) => setTimeout(res, 400));
        setNameSuccessMessage(t("agency_panel_profile_success"));
      } else {
        const { error } = await supabase.auth.updateUser({
          data: { full_name: fullName.trim() },
        });
        if (error) throw error;
        setNameSuccessMessage(t("agency_panel_profile_success"));
      }
    } catch (err: any) {
      setNameErrorMessage(err?.message || "Failed to update profile.");
    } finally {
      setIsUpdatingName(false);
    }
  }

  // Change Password Handler
  async function handleChangePassword(e: React.FormEvent) {
    e.preventDefault();
    setPasswordErrorMessage(null);
    setPasswordSuccessMessage(null);

    if (newPassword.length < 6) {
      setPasswordErrorMessage(t("agency_panel_password_length"));
      return;
    }
    if (newPassword !== confirmPassword) {
      setPasswordErrorMessage(t("agency_panel_password_mismatch"));
      return;
    }

    setIsUpdatingPassword(true);
    try {
      if (!userId || userId === "demo") {
        await new Promise((res) => setTimeout(res, 500));
        setPasswordSuccessMessage(t("agency_panel_password_success"));
        setNewPassword("");
        setConfirmPassword("");
        setTimeout(() => setIsPasswordModalOpen(false), 1500);
      } else {
        const { error } = await supabase.auth.updateUser({ password: newPassword });
        if (error) throw error;
        setPasswordSuccessMessage(t("agency_panel_password_success"));
        setNewPassword("");
        setConfirmPassword("");
        setTimeout(() => setIsPasswordModalOpen(false), 1500);
      }
    } catch (err: any) {
      setPasswordErrorMessage(err?.message || "Failed to update password.");
    } finally {
      setIsUpdatingPassword(false);
    }
  }

  // Delete Account Handler
  async function handleDeleteAccount() {
    setIsDeleting(true);
    setDeleteErrorMessage(null);
    try {
      if (isDemoMode) {
        if (typeof window !== "undefined") {
          localStorage.removeItem("stanomer_agency_demo_auth");
          localStorage.removeItem("stanomer_agency_demo_active_user");
        }
        window.location.href = "/";
      } else {
        await handleSignOut();
      }
    } catch (err: any) {
      setDeleteErrorMessage(err?.message || "Failed to delete account.");
      setIsDeleting(false);
    }
  }

  // Support Ticket Handler
  async function handleSupportSubmit(e: React.FormEvent) {
    e.preventDefault();
    const errors: { subject?: string; email?: string; message?: string } = {};

    if (!supportSubject.trim()) {
      errors.subject = t("required");
    }
    if (!supportEmail.trim() || !supportEmail.includes("@")) {
      errors.email = t("invalid_email");
    }
    if (!supportMessage.trim()) {
      errors.message = t("required");
    }

    if (Object.keys(errors).length > 0) {
      setSupportValidationErrors(errors);
      return;
    }

    setSupportValidationErrors({});
    setIsSendingSupport(true);
    setSupportError(null);
    setSupportSuccess(false);

    try {
      const response = await fetch("/api/notion/", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          subject: supportSubject.trim(),
          email: supportEmail.trim(),
          category: supportCategory,
          message: supportMessage.trim(),
          platform: "Web",
          appVersion: "1.1.0",
        }),
      });

      const data = await response.json().catch(() => ({}));

      if (response.ok && data?.success) {
        setSupportSuccess(true);
        setSupportSubject("");
        setSupportMessage("");
        setTimeout(() => {
          setIsSupportModalOpen(false);
          setSupportSuccess(false);
        }, 2000);
      } else {
        setSupportError(t("error_msg"));
      }
    } catch {
      setSupportError(t("error_msg"));
    } finally {
      setIsSendingSupport(false);
    }
  }

  // Open upgrade request ticket
  function handleOpenUpgradeTicket(pkgName?: string) {
    setSupportSubject(
      pkgName
        ? `Stanomer Paket Aktivasyonu: ${pkgName}`
        : "Stanomer Paket & Modül Aktivasyon Talebi"
    );
    setSupportCategory("Support");
    setSupportMessage(
      `Merhaba Stanomer Ekibi,\n\nAcentemiz (${agencyName}) için paketimizi genişletmek istiyoruz.\nİlgili modül paketi: ${pkgName || "Portfolio & Distribution / Property & Lease Management"}\n`
    );
    setSupportError(null);
    setSupportSuccess(false);
    setSupportValidationErrors({});
    setIsSupportModalOpen(true);
  }

  const initials = (agencyName || fullName || "User")
    .split(" ")
    .map((w) => (w.length > 0 ? w[0] : ""))
    .slice(0, 2)
    .join("")
    .toUpperCase();

  const activePackageCount = STANOMER_PACKAGES.filter((p) => isPackageActive(p.key)).length;

  return (
    <div
      role="tabpanel"
      id="tabpanel-account-settings"
      aria-labelledby="tab-account-settings"
      className="w-full space-y-6 pb-20"
    >
      {/* 1. Full-width Hero Profile Card */}
      <div className="w-full bg-white rounded-[10px] border border-[#E5E3DF] p-6 shadow-[0_1px_0_rgba(0,0,0,0.04),0_2px_8px_rgba(0,0,0,0.06)]">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div className="flex items-center gap-4 min-w-0">
            <div className="w-16 h-16 rounded-full bg-[#1B5888]/10 text-[#1B5888] border border-[#1B5888]/20 flex items-center justify-center font-bold text-xl shrink-0 shadow-2xs">
              {initials || "A"}
            </div>
            <div className="min-w-0 flex-1">
              <div className="flex items-center gap-2 flex-wrap">
                <h2 className="text-lg sm:text-xl font-semibold text-[#1A1A1A] tracking-tight truncate">
                  {fullName || agencyName || "Stanomer Agencija"}
                </h2>
                <span className="text-xs font-semibold px-2 py-0.5 rounded-[6px] bg-[#1B5888]/10 text-[#1B5888] border border-[#1B5888]/20 shrink-0">
                  {isDemoMode ? t("agency_panel_demo_mode_label") : "Acente"}
                </span>
                <span className="text-xs font-semibold px-2 py-0.5 rounded-[6px] bg-emerald-50 text-emerald-700 border border-emerald-200 shrink-0 flex items-center gap-1.5">
                  <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse" />
                  <span>{subscription.plan}</span>
                </span>
              </div>
              <p className="text-xs text-[#666666] truncate mt-0.5 font-medium">
                {agencyEmail || user?.email || "agencija@stanomer.com"}
              </p>
            </div>
          </div>

          <div className="flex items-center gap-2 shrink-0">
            <span className="text-[11px] font-mono font-bold text-[#1B5888] bg-[#E5EEF6] px-3 py-1.5 rounded-lg border border-[#1B5888]/20">
              {t("agency_panel_app_version")}
            </span>
          </div>
        </div>

        {/* Sub-tab Navigation Switcher */}
        <div className="flex items-center gap-1 sm:gap-2 border-b border-[#E5E3DF] mt-5 overflow-x-auto no-scrollbar">
          <button
            type="button"
            role="tab"
            aria-selected={activeSubTab === "account"}
            onClick={() => setActiveSubTab("account")}
            className={`py-3 px-3 sm:px-4 text-xs font-bold border-b-2 transition-all flex items-center gap-2 cursor-pointer whitespace-nowrap -mb-px ${
              activeSubTab === "account"
                ? "border-[#1B5888] text-[#1B5888]"
                : "border-transparent text-[#666666] hover:text-[#1A1A1A] hover:border-slate-300"
            }`}
          >
            <CreditCard className={`w-4 h-4 shrink-0 ${activeSubTab === "account" ? "text-[#1B5888]" : "text-[#8A8A8A]"}`} />
            <span>{t("agency_panel_tab_account_settings")}</span>
          </button>

          <button
            type="button"
            role="tab"
            aria-selected={activeSubTab === "profile"}
            onClick={() => setActiveSubTab("profile")}
            className={`py-3 px-3 sm:px-4 text-xs font-bold border-b-2 transition-all flex items-center gap-2 cursor-pointer whitespace-nowrap -mb-px ${
              activeSubTab === "profile"
                ? "border-[#1B5888] text-[#1B5888]"
                : "border-transparent text-[#666666] hover:text-[#1A1A1A] hover:border-slate-300"
            }`}
          >
            <User className={`w-4 h-4 shrink-0 ${activeSubTab === "profile" ? "text-[#1B5888]" : "text-[#8A8A8A]"}`} />
            <span>{t("agency_panel_tab_profile_security")}</span>
          </button>
        </div>
      </div>

      {/* ========================================================================= */}
      {/* SUBTAB 1: ACCOUNT SETTINGS (PORTFOLIO & DISTRIBUTION / PROPERTY & LEASE)  */}
      {/* ========================================================================= */}
      {activeSubTab === "account" && (
        <div className="space-y-6">
          {/* 1. Subscription & Package Summary Cards */}
          <div className="space-y-2">
            <div className="flex items-center justify-between px-1">
              <p className="text-xs font-bold text-[#8A8A8A]">
                {t("agency_panel_account_overview_title")}
              </p>
              <button
                type="button"
                onClick={() => handleOpenUpgradeTicket()}
                className="text-xs font-bold text-[#1B5888] hover:text-[#12406A] flex items-center gap-1 transition-colors cursor-pointer"
              >
                <span>{t("agency_panel_invoice_contact_support")}</span>
                <ChevronRight className="w-3.5 h-3.5" />
              </button>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
              {/* Card 1: Plan */}
              <div className="bg-white rounded-[10px] border border-[#E5E3DF] p-5 shadow-xs">
                <div className="flex items-center justify-between mb-2">
                  <span className="text-xs font-bold text-[#666666]">
                    {t("agency_panel_account_plan_label")}
                  </span>
                  <div className="w-7 h-7 rounded-lg bg-[#E5EEF6] text-[#1B5888] flex items-center justify-center">
                    <Sparkles className="w-4 h-4" />
                  </div>
                </div>
                <h3 className="text-base font-bold text-[#1A1A1A] truncate">
                  {subscription.plan}
                </h3>
                <div className="flex items-center gap-1.5 mt-2">
                  <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
                  <span className="text-[11px] font-bold text-emerald-700">
                    {t("agency_panel_account_status_active")}
                  </span>
                </div>
              </div>

              {/* Card 2: Active Packages (Total 2) */}
              <div className="bg-white rounded-[10px] border border-[#E5E3DF] p-5 shadow-xs">
                <div className="flex items-center justify-between mb-2">
                  <span className="text-xs font-bold text-[#666666]">
                    {t("agency_panel_account_active_modules_count")}
                  </span>
                  <div className="w-7 h-7 rounded-lg bg-emerald-50 text-emerald-700 flex items-center justify-center">
                    <Boxes className="w-4 h-4" />
                  </div>
                </div>
                <div className="flex items-baseline gap-1">
                  <span className="text-2xl font-extrabold text-[#1A1A1A]">
                    {activePackageCount}
                  </span>
                  <span className="text-xs font-bold text-[#8A8A8A]">
                    / {STANOMER_PACKAGES.length} {t("agency_panel_account_modules_unit")}
                  </span>
                </div>
                <p className="text-[11px] font-semibold text-emerald-700 mt-1">
                  {activePackageCount === 2
                    ? t("agency_panel_account_pkg_all_in_one")
                    : activePackageCount === 1
                      ? t("agency_panel_account_pkg_single_active")
                      : t("agency_panel_account_pkg_none_active")}
                </p>
              </div>

              {/* Card 3: Next Billing */}
              <div className="bg-white rounded-[10px] border border-[#E5E3DF] p-5 shadow-xs">
                <div className="flex items-center justify-between mb-2">
                  <span className="text-xs font-bold text-[#666666]">
                    {t("agency_panel_account_next_billing")}
                  </span>
                  <div className="w-7 h-7 rounded-lg bg-sky-50 text-sky-700 flex items-center justify-center">
                    <Calendar className="w-4 h-4" />
                  </div>
                </div>
                <h3 className="text-base font-bold text-[#1A1A1A]">
                  {subscription.next_billing_date || "01.12.2026"}
                </h3>
                <p className="text-[11px] font-semibold text-sky-700 mt-2 flex items-center gap-1">
                  <Clock className="w-3 h-3" />
                  <span>{t("agency_panel_account_billing_cycle_auto")}</span>
                </p>
              </div>
            </div>
          </div>

          {/* 2. THE 2 CORE STANOMER PACKAGES (Your License & Module Entitlements) */}
          <div className="space-y-3">
            <div>
              <h3 className="text-base font-bold text-[#1A1A1A] tracking-tight">
                {t("agency_welcome_modules_sec_title")}
              </h3>
              <p className="text-xs text-[#666666] mt-0.5">
                {t("agency_welcome_modules_sec_desc")}
              </p>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
              {/* Module Card 1: Marketing & Syndication (Portfolio & Distribution) */}
              <div className="bg-white rounded-[10px] border border-[#E5E3DF] p-5 shadow-2xs flex flex-col justify-between hover:border-[#8A8A8A] transition-colors">
                <div>
                  <div className="flex items-center justify-between gap-2 pb-3 mb-3 border-b border-slate-100">
                    <div className="flex items-center gap-2">
                      <div className="w-8 h-8 rounded-lg bg-slate-100 text-[#4A4A4A] flex items-center justify-center shrink-0">
                        <Share2 className="w-4 h-4" />
                      </div>
                      <h4 className="text-sm font-bold text-[#1A1A1A]">
                        {t("agency_panel_nav_group_marketing")}
                      </h4>
                    </div>

                    {isPackageActive("portfolio_distribution") ? (
                      <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-md border border-[#E5E3DF] bg-white text-[11px] font-medium text-[#4A4A4A] shadow-2xs">
                        <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 ring-2 ring-emerald-500/20" />
                        {t("agency_welcome_mod_active_badge")}
                      </span>
                    ) : (
                      <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-md border border-[#8A5206]/20 bg-[#FBF1DC] text-[11px] font-medium text-[#8A5206]">
                        <span className="w-1.5 h-1.5 rounded-full bg-amber-500" />
                        {t("agency_welcome_mod_locked_badge")}
                      </span>
                    )}
                  </div>

                  <ul className="space-y-2 text-xs text-[#4A4A4A] mb-5">
                    <li className="flex items-center gap-2">
                      <Check className="w-3.5 h-3.5 text-[#1A1A1A] shrink-0" />
                      <span>{t("agency_welcome_mod_marketing_f1")}</span>
                    </li>
                    <li className="flex items-center gap-2">
                      <Check className="w-3.5 h-3.5 text-[#1A1A1A] shrink-0" />
                      <span>{t("agency_welcome_mod_marketing_f2")}</span>
                    </li>
                    <li className="flex items-center gap-2">
                      <Check className="w-3.5 h-3.5 text-[#1A1A1A] shrink-0" />
                      <span>{t("agency_welcome_mod_marketing_f3")}</span>
                    </li>
                    <li className="flex items-center gap-2">
                      <Check className="w-3.5 h-3.5 text-[#1A1A1A] shrink-0" />
                      <span>{t("agency_welcome_mod_marketing_f4")}</span>
                    </li>
                  </ul>
                </div>

                <div className="flex items-center gap-2 pt-3 border-t border-slate-100">
                  {isPackageActive("portfolio_distribution") ? (
                    <>
                      {setActiveTab && (
                        <>
                          <button
                            type="button"
                            onClick={() => setActiveTab("listings")}
                            className="inline-flex items-center justify-center gap-1.5 px-3.5 py-2 rounded-[10px] bg-[#1B5888] hover:bg-[#15466d] active:bg-[#12406A] text-white text-xs font-bold shadow-xs transition-colors cursor-pointer"
                          >
                            <span>{t("agency_panel_menu_listings")}</span>
                            <ArrowRight className="w-3.5 h-3.5" />
                          </button>
                          <button
                            type="button"
                            onClick={() => setActiveTab("xml")}
                            className="inline-flex items-center justify-center gap-1.5 px-3.5 py-2 rounded-[10px] bg-white border-[1.5px] border-[#1B5888] hover:bg-[#E5EEF6] text-[#1B5888] text-xs font-semibold transition-colors cursor-pointer"
                          >
                            <span>{t("agency_panel_menu_xml")}</span>
                          </button>
                        </>
                      )}
                    </>
                  ) : isDemoMode ? (
                    <button
                      type="button"
                      onClick={() => {
                        if (onActivateModule) {
                          onActivateModule("portfolio_distribution");
                          setSubscription((prev) => ({
                            ...prev,
                            active_modules: Array.from(new Set([...prev.active_modules, "portfolio_distribution"])),
                          }));
                        }
                      }}
                      className="inline-flex items-center justify-center gap-1.5 px-4 py-2 rounded-[10px] bg-[#1B5888] hover:bg-[#15466d] active:bg-[#12406A] text-white text-xs font-bold shadow-xs transition-colors cursor-pointer"
                    >
                      <Plus className="w-3.5 h-3.5" />
                      <span>{t("agency_welcome_cta_demo_add")}</span>
                    </button>
                  ) : (
                    <button
                      type="button"
                      disabled={moduleUpgradeRequested}
                      onClick={() => {
                        if (handleRequestModuleUpgrade) {
                          handleRequestModuleUpgrade();
                        } else {
                          handleOpenUpgradeTicket(t("agency_panel_nav_group_marketing"));
                        }
                      }}
                      className="inline-flex items-center justify-center gap-1.5 px-4 py-2 rounded-[10px] bg-[#1B5888] hover:bg-[#15466d] active:bg-[#12406A] disabled:opacity-38 text-white text-xs font-bold shadow-xs transition-colors cursor-pointer"
                    >
                      <Plus className="w-3.5 h-3.5" />
                      <span>
                        {moduleUpgradeRequested
                          ? t("agency_welcome_upgrade_sent")
                          : t("agency_welcome_cta_upgrade_request")}
                      </span>
                    </button>
                  )}
                </div>
              </div>

              {/* Module Card 2: Property & Lease Management (PMS) */}
              <div className="bg-white rounded-[10px] border border-[#E5E3DF] p-5 shadow-2xs flex flex-col justify-between hover:border-[#8A8A8A] transition-colors">
                <div>
                  <div className="flex items-center justify-between gap-2 pb-3 mb-3 border-b border-slate-100">
                    <div className="flex items-center gap-2">
                      <div className="w-8 h-8 rounded-lg bg-slate-100 text-[#4A4A4A] flex items-center justify-center shrink-0">
                        <Building2 className="w-4 h-4" />
                      </div>
                      <h4 className="text-sm font-bold text-[#1A1A1A] flex items-center gap-1.5">
                        <span>{t("agency_panel_nav_group_management")}</span>
                        <span className="text-[9px] px-1.5 py-0.2 rounded font-mono font-bold bg-slate-900 text-white">
                          PMS
                        </span>
                      </h4>
                    </div>

                    {isPackageActive("property_lease_management") ? (
                      <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-md border border-[#E5E3DF] bg-white text-[11px] font-medium text-[#4A4A4A] shadow-2xs">
                        <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 ring-2 ring-emerald-500/20" />
                        {t("agency_welcome_mod_active_badge")}
                      </span>
                    ) : (
                      <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-md border border-[#8A5206]/20 bg-[#FBF1DC] text-[11px] font-medium text-[#8A5206]">
                        <span className="w-1.5 h-1.5 rounded-full bg-amber-500" />
                        {t("agency_welcome_mod_locked_badge")}
                      </span>
                    )}
                  </div>

                  <ul className="space-y-2 text-xs text-[#4A4A4A] mb-5">
                    <li className="flex items-center gap-2">
                      <Check className="w-3.5 h-3.5 text-[#1A1A1A] shrink-0" />
                      <span>{t("agency_welcome_mod_pms_f1")}</span>
                    </li>
                    <li className="flex items-center gap-2">
                      <Check className="w-3.5 h-3.5 text-[#1A1A1A] shrink-0" />
                      <span>{t("agency_welcome_mod_pms_f2")}</span>
                    </li>
                    <li className="flex items-center gap-2">
                      <Check className="w-3.5 h-3.5 text-[#1A1A1A] shrink-0" />
                      <span>{t("agency_welcome_mod_pms_f3")}</span>
                    </li>
                    <li className="flex items-center gap-2">
                      <Check className="w-3.5 h-3.5 text-[#1A1A1A] shrink-0" />
                      <span>{t("agency_welcome_mod_pms_f4")}</span>
                    </li>
                  </ul>
                </div>

                <div className="flex items-center gap-2 pt-3 border-t border-slate-100">
                  {isPackageActive("property_lease_management") ? (
                    <>
                      {setActiveTab && (
                        <button
                          type="button"
                          onClick={() => setActiveTab("pm_dashboard")}
                          className="inline-flex items-center justify-center gap-1.5 px-3.5 py-2 rounded-[10px] bg-[#1B5888] hover:bg-[#15466d] active:bg-[#12406A] text-white text-xs font-bold shadow-xs transition-colors cursor-pointer"
                        >
                          <span>{t("agency_panel_menu_pm_dashboard")}</span>
                          <ArrowRight className="w-3.5 h-3.5" />
                        </button>
                      )}
                    </>
                  ) : isDemoMode ? (
                    <button
                      type="button"
                      onClick={() => {
                        if (onActivateModule) {
                          onActivateModule("property_lease_management");
                          setSubscription((prev) => ({
                            ...prev,
                            active_modules: Array.from(new Set([...prev.active_modules, "property_lease_management"])),
                          }));
                        }
                      }}
                      className="inline-flex items-center justify-center gap-1.5 px-4 py-2 rounded-[10px] bg-[#1B5888] hover:bg-[#15466d] active:bg-[#12406A] text-white text-xs font-bold shadow-xs transition-colors cursor-pointer"
                    >
                      <Plus className="w-3.5 h-3.5" />
                      <span>{t("agency_welcome_cta_demo_add")}</span>
                    </button>
                  ) : (
                    <button
                      type="button"
                      disabled={moduleUpgradeRequested}
                      onClick={() => {
                        if (handleRequestModuleUpgrade) {
                          handleRequestModuleUpgrade();
                        } else {
                          handleOpenUpgradeTicket(t("agency_panel_nav_group_management"));
                        }
                      }}
                      className="inline-flex items-center justify-center gap-1.5 px-4 py-2 rounded-[10px] bg-[#1B5888] hover:bg-[#15466d] active:bg-[#12406A] disabled:opacity-38 text-white text-xs font-bold shadow-xs transition-colors cursor-pointer"
                    >
                      <Plus className="w-3.5 h-3.5" />
                      <span>
                        {moduleUpgradeRequested
                          ? t("agency_welcome_upgrade_sent")
                          : t("agency_welcome_cta_upgrade_request")}
                      </span>
                    </button>
                  )}
                </div>
              </div>
            </div>
          </div>

          {/* 3. Monthly Invoices & Billing History */}
          <div className="space-y-2">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-1 px-1">
              <div>
                <p className="text-xs font-bold text-[#8A8A8A]">
                  {t("agency_panel_account_invoices_title")}
                </p>
                <p className="text-xs text-[#666666] mt-0.5">
                  {t("agency_panel_account_invoices_desc")}
                </p>
              </div>

              <button
                type="button"
                onClick={() => handleOpenUpgradeTicket()}
                className="self-start sm:self-auto px-3.5 py-1.5 rounded-[10px] bg-[#E5EEF6] hover:bg-[#d5e4f1] text-[#1B5888] text-xs font-bold transition-colors cursor-pointer shrink-0"
              >
                {t("agency_panel_invoice_upgrade_prompt")}
              </button>
            </div>

            <div className="bg-white rounded-[10px] border border-[#E5E3DF] shadow-xs overflow-hidden">
              {isDemoMode ? (
                <div className="p-8 sm:p-10 text-center space-y-3">
                  <div className="w-12 h-12 rounded-full bg-[#E5EEF6] text-[#1B5888] flex items-center justify-center mx-auto">
                    <Receipt className="w-6 h-6" />
                  </div>
                  <div className="space-y-1">
                    <h4 className="text-sm font-bold text-[#1A1A1A]">
                      {t("agency_panel_demo_invoices_info_title")}
                    </h4>
                    <p className="text-xs text-[#666666] max-w-md mx-auto leading-relaxed">
                      {t("agency_panel_demo_invoices_info_desc")}
                    </p>
                  </div>
                </div>
              ) : loadingBilling ? (
                <div className="p-8 text-center">
                  <div className="w-6 h-6 border-2 border-[#1B5888] border-t-transparent rounded-full animate-spin mx-auto mb-2" />
                  <p className="text-xs text-[#666666] font-semibold">
                    {t("agency_panel_invoice_loading")}
                  </p>
                </div>
              ) : invoices.length === 0 ? (
                <div className="p-8 text-center space-y-2">
                  <Receipt className="w-8 h-8 text-[#8A8A8A] mx-auto opacity-50" />
                  <p className="text-xs font-bold text-[#4A4A4A]">
                    {t("agency_panel_invoice_no_invoices")}
                  </p>
                  <p className="text-xs text-[#8A8A8A] max-w-sm mx-auto">
                    {t("agency_panel_invoice_empty_subtext")}
                  </p>
                </div>
              ) : (
                <div className="overflow-x-auto">
                  <table className="w-full text-left text-xs border-collapse">
                    <thead>
                      <tr className="bg-[#FAF9F7] border-b border-[#E5E3DF] text-[#666666] font-bold">
                        <th className="py-3 px-4">{t("agency_panel_invoice_number")}</th>
                        <th className="py-3 px-4">{t("agency_panel_invoice_period")}</th>
                        <th className="py-3 px-4">{t("agency_panel_invoice_amount")}</th>
                        <th className="py-3 px-4">{t("agency_panel_invoice_status")}</th>
                        <th className="py-3 px-4 hidden md:table-cell">
                          {t("agency_panel_invoice_due_date")}
                        </th>
                        <th className="py-3 px-4 text-right">{t("agency_panel_invoice_action_col")}</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-[#E5E3DF]">
                      {invoices.map((inv) => (
                        <tr
                          key={inv.id}
                          className="hover:bg-[#FAF9F7] transition-colors"
                        >
                          <td className="py-3.5 px-4 font-mono font-bold text-[#1A1A1A]">
                            <div className="flex items-center gap-2">
                              <Receipt className="w-3.5 h-3.5 text-[#1B5888]" />
                              <span>{inv.invoice_number}</span>
                            </div>
                          </td>
                          <td className="py-3.5 px-4 font-semibold text-[#4A4A4A]">
                            {inv.period}
                          </td>
                          <td className="py-3.5 px-4 font-bold text-[#1A1A1A] tabular-nums">
                            {Number(inv.amount).toFixed(2)} {inv.currency}
                          </td>
                          <td className="py-3.5 px-4">
                            {inv.status === "paid" ? (
                              <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-bold bg-emerald-50 text-emerald-700 border border-emerald-200">
                                <Check className="w-3 h-3 text-emerald-600" />
                                <span>{t("agency_panel_invoice_status_paid")}</span>
                              </span>
                            ) : inv.status === "pending" ? (
                              <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-bold bg-amber-50 text-amber-700 border border-amber-200">
                                <Clock className="w-3 h-3 text-amber-600" />
                                <span>{t("agency_panel_invoice_status_pending")}</span>
                              </span>
                            ) : (
                              <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-bold bg-rose-50 text-rose-700 border border-rose-200">
                                <AlertCircle className="w-3 h-3 text-rose-600" />
                                <span>{t("agency_panel_invoice_status_overdue")}</span>
                              </span>
                            )}
                          </td>
                          <td className="py-3.5 px-4 hidden md:table-cell text-[#666666] font-medium">
                            {inv.due_date || inv.paid_at?.slice(0, 10) || "—"}
                          </td>
                          <td className="py-3.5 px-4 text-right">
                            <div className="flex items-center justify-end gap-2">
                              <button
                                type="button"
                                onClick={() => setSelectedInvoice(inv)}
                                className="px-2.5 py-1 rounded-lg border border-[#E5E3DF] hover:bg-white text-xs font-bold text-[#1B5888] flex items-center gap-1 transition-colors cursor-pointer"
                              >
                                <Eye className="w-3.5 h-3.5" />
                                <span className="hidden sm:inline">
                                  {t("agency_panel_invoice_action_view")}
                                </span>
                              </button>

                              {inv.pdf_url ? (
                                <a
                                  href={inv.pdf_url}
                                  target="_blank"
                                  rel="noopener noreferrer"
                                  className="px-2.5 py-1 rounded-lg bg-[#1B5888] hover:bg-[#15466d] text-white text-xs font-bold flex items-center gap-1 transition-colors cursor-pointer"
                                >
                                  <Download className="w-3.5 h-3.5" />
                                  <span className="hidden sm:inline">PDF</span>
                                </a>
                              ) : (
                                <button
                                  type="button"
                                  onClick={() => setSelectedInvoice(inv)}
                                  className="px-2.5 py-1 rounded-lg bg-[#E5EEF6] hover:bg-[#d5e4f1] text-[#1B5888] text-xs font-bold flex items-center gap-1 transition-colors cursor-pointer"
                                >
                                  <Download className="w-3.5 h-3.5" />
                                  <span className="hidden sm:inline">PDF</span>
                                </button>
                              )}
                            </div>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </div>
          </div>
        </div>
      )}

      {/* ========================================================================= */}
      {/* SUBTAB 2: PROFILE & SECURITY (NAME, PASSWORD, LANGUAGE & SUPPORT)        */}
      {/* ========================================================================= */}
      {activeSubTab === "profile" && (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 items-start">
          {/* Left Column: Profile Info & Security */}
          <div className="space-y-6">
            {/* Profile & Name Update Card */}
            <div className="space-y-2">
              <p className="text-xs font-bold text-[#8A8A8A] px-1">
                {t("agency_panel_update_name_title")}
              </p>
              <div className="bg-white rounded-[10px] border border-[#E5E3DF] p-6 shadow-xs">
                <form onSubmit={handleUpdateName} className="space-y-4">
                  <div>
                    <label className="block text-xs font-bold text-[#4A4A4A] mb-1.5">
                      {t("agency_panel_full_name_label")}
                    </label>
                    <div className="relative">
                      <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-[#8A8A8A]">
                        <User className="w-4 h-4" />
                      </div>
                      <input
                        type="text"
                        value={fullName}
                        onChange={(e) => setFullName(e.target.value)}
                        placeholder={agencyName || "Nikola Petrović"}
                        className="w-full pl-9 pr-3 py-2.5 rounded-[10px] border border-[#E5E3DF] bg-[#F8F7F5] focus:bg-white text-xs text-[#1A1A1A] font-semibold focus:outline-none focus:ring-1 focus:ring-[#1B5888] transition-all"
                      />
                    </div>
                  </div>

                  {nameSuccessMessage && (
                    <div className="p-3 rounded-[10px] bg-emerald-50 border border-emerald-200 text-emerald-800 text-xs font-semibold flex items-center gap-2">
                      <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0" />
                      <span>{nameSuccessMessage}</span>
                    </div>
                  )}

                  {nameErrorMessage && (
                    <div className="p-3 rounded-[10px] bg-rose-50 border border-rose-200 text-rose-800 text-xs font-semibold flex items-center gap-2">
                      <AlertCircle className="w-4 h-4 text-rose-600 shrink-0" />
                      <span>{nameErrorMessage}</span>
                    </div>
                  )}

                  <div className="flex justify-end pt-1">
                    <button
                      type="submit"
                      disabled={isUpdatingName || !fullName.trim()}
                      className="w-full sm:w-auto px-6 py-2.5 rounded-[10px] bg-[#1B5888] hover:bg-[#15466d] active:bg-[#12406A] text-white text-xs font-bold transition-colors cursor-pointer disabled:opacity-50 shadow-xs flex items-center justify-center gap-2"
                    >
                      {isUpdatingName ? (
                        <span className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                      ) : (
                        <span>{t("agency_panel_save_changes")}</span>
                      )}
                    </button>
                  </div>
                </form>
              </div>
            </div>

            {/* Account & Security Card */}
            <div className="space-y-2">
              <p className="text-xs font-bold text-[#8A8A8A] px-1">
                {t("agency_panel_account_header")}
              </p>
              <div className="bg-white rounded-[10px] border border-[#E5E3DF] divide-y divide-[#E5E3DF] shadow-xs overflow-hidden">
                {/* Change Password (Inline Expandable — matches Flutter in-page flow) */}
                <div>
                  <button
                    type="button"
                    onClick={() => {
                      setIsPasswordModalOpen((prev) => !prev);
                      setPasswordErrorMessage(null);
                      setPasswordSuccessMessage(null);
                    }}
                    className="w-full flex items-center justify-between p-4 hover:bg-[#F8F7F5] transition-colors cursor-pointer text-left"
                  >
                    <div className="flex items-center gap-3">
                      <KeyRound className="w-4 h-4 text-[#666666]" />
                      <span className="text-xs font-semibold text-[#1A1A1A]">
                        {t("agency_panel_update_password_title")}
                      </span>
                    </div>
                    <ChevronRight
                      className={`w-4 h-4 text-[#8A8A8A] transition-transform ${
                        isPasswordModalOpen ? "rotate-90 text-[#1B5888]" : ""
                      }`}
                    />
                  </button>

                  {isPasswordModalOpen && (
                    <form
                      onSubmit={handleChangePassword}
                      className="px-4 pb-4 pt-2 bg-[#F8F7F5]/60 border-t border-[#E5E3DF] space-y-3 animate-in fade-in duration-150"
                    >
                      <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                        <div>
                          <label className="block text-[11px] font-bold text-[#4A4A4A] mb-1">
                            {t("agency_panel_new_password")}
                          </label>
                          <input
                            type="password"
                            value={newPassword}
                            onChange={(e) => setNewPassword(e.target.value)}
                            placeholder="••••••••"
                            autoComplete="new-password"
                            className="w-full px-3 py-2 rounded-[10px] border border-[#E5E3DF] bg-white text-xs text-[#1A1A1A] font-semibold focus:outline-none focus:ring-1 focus:ring-[#1B5888]"
                            required
                          />
                        </div>

                        <div>
                          <label className="block text-[11px] font-bold text-[#4A4A4A] mb-1">
                            {t("agency_panel_confirm_password")}
                          </label>
                          <input
                            type="password"
                            value={confirmPassword}
                            onChange={(e) => setConfirmPassword(e.target.value)}
                            placeholder="••••••••"
                            autoComplete="new-password"
                            className="w-full px-3 py-2 rounded-[10px] border border-[#E5E3DF] bg-white text-xs text-[#1A1A1A] font-semibold focus:outline-none focus:ring-1 focus:ring-[#1B5888]"
                            required
                          />
                        </div>
                      </div>

                      {passwordSuccessMessage && (
                        <div className="p-2.5 rounded-[10px] bg-emerald-50 border border-emerald-200 text-emerald-800 text-xs font-semibold flex items-center gap-2">
                          <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0" />
                          <span>{passwordSuccessMessage}</span>
                        </div>
                      )}

                      {passwordErrorMessage && (
                        <div className="p-2.5 rounded-[10px] bg-rose-50 border border-rose-200 text-rose-800 text-xs font-semibold flex items-center gap-2">
                          <AlertCircle className="w-4 h-4 text-rose-600 shrink-0" />
                          <span>{passwordErrorMessage}</span>
                        </div>
                      )}

                      <div className="flex items-center justify-end gap-2 pt-1">
                        <button
                          type="button"
                          onClick={() => {
                            setIsPasswordModalOpen(false);
                            setNewPassword("");
                            setConfirmPassword("");
                            setPasswordErrorMessage(null);
                            setPasswordSuccessMessage(null);
                          }}
                          className="px-3.5 py-2 rounded-[10px] border border-[#E5E3DF] bg-white text-xs font-semibold text-[#4A4A4A] hover:bg-slate-50 cursor-pointer"
                        >
                          {t("agency_panel_cancel_btn")}
                        </button>
                        <button
                          type="submit"
                          disabled={isUpdatingPassword || !newPassword}
                          className="px-4 py-2 rounded-[10px] bg-[#1B5888] hover:bg-[#15466d] active:bg-[#12406A] text-white text-xs font-bold cursor-pointer disabled:opacity-50"
                        >
                          {isUpdatingPassword ? (
                            <span className="w-3.5 h-3.5 border-2 border-white/30 border-t-white rounded-full animate-spin inline-block" />
                          ) : (
                            t("agency_panel_save_changes")
                          )}
                        </button>
                      </div>
                    </form>
                  )}
                </div>

                {/* Sign Out */}
                <button
                  type="button"
                  onClick={handleSignOut}
                  className="w-full flex items-center justify-between p-4 hover:bg-rose-50/50 transition-colors cursor-pointer text-left text-rose-600"
                >
                  <div className="flex items-center gap-3">
                    <LogOut className="w-4 h-4" />
                    <span className="text-xs font-bold">
                      {t("agency_panel_signout")}
                    </span>
                  </div>
                  <ChevronRight className="w-4 h-4 text-rose-400" />
                </button>

                {/* Delete Account */}
                <button
                  type="button"
                  onClick={() => setIsDeleteModalOpen(true)}
                  className="w-full flex items-center justify-between p-4 hover:bg-rose-50/50 transition-colors cursor-pointer text-left text-rose-600"
                >
                  <div className="flex items-center gap-3">
                    <Trash2 className="w-4 h-4" />
                    <span className="text-xs font-bold">
                      {t("agency_panel_delete_account_title")}
                    </span>
                  </div>
                  <ChevronRight className="w-4 h-4 text-rose-400" />
                </button>
              </div>
            </div>
          </div>

          {/* Right Column: App Preferences & Support / Legal */}
          <div className="space-y-6">
            {/* App Preferences (Language) Card */}
            <div className="space-y-2">
              <p className="text-xs font-bold text-[#8A8A8A] px-1">
                {t("agency_panel_app_settings_header")}
              </p>
              <div className="bg-white rounded-[10px] border border-[#E5E3DF] shadow-xs overflow-hidden p-5">
                <div className="flex items-center gap-2.5 mb-3">
                  <Globe className="w-4 h-4 text-[#1B5888]" />
                  <span className="text-xs font-bold text-[#1A1A1A]">
                    {t("language")}
                  </span>
                </div>
                <div className="grid grid-cols-2 sm:grid-cols-5 gap-2">
                  {[
                    { code: "SR_LAT", flag: "🇷🇸", codeName: "SR", sub: "Latinica" },
                    { code: "SR_CYR", flag: "🇷🇸", codeName: "СР", sub: "Ћирилица" },
                    { code: "EN", flag: "🇬🇧", codeName: "EN", sub: "English" },
                    { code: "RU", flag: "🇷🇺", codeName: "RU", sub: "Русский" },
                    { code: "TR", flag: "🇹🇷", codeName: "TR", sub: "Türkçe" },
                  ].map((item) => (
                    <button
                      key={item.code}
                      type="button"
                      onClick={() => setLang(item.code as any)}
                      className={`flex flex-col items-center justify-center p-2.5 rounded-[10px] border text-center transition-all cursor-pointer ${
                        lang === item.code
                          ? "bg-[#1B5888] text-white border-[#1B5888] shadow-xs font-bold"
                          : "bg-[#F8F7F5] text-[#4A4A4A] border-[#E5E3DF] hover:bg-[#E5E3DF]/50"
                      }`}
                    >
                      <span className="text-lg leading-none mb-1">{item.flag}</span>
                      <span className="text-xs font-bold leading-tight">{item.codeName}</span>
                      <span
                        className={`text-[10px] leading-tight mt-0.5 truncate max-w-full ${
                          lang === item.code ? "text-white/80" : "text-[#8A8A8A]"
                        }`}
                      >
                        {item.sub}
                      </span>
                    </button>
                  ))}
                </div>
              </div>
            </div>

            {/* Support & Legal Card */}
            <div className="space-y-2">
              <p className="text-xs font-bold text-[#8A8A8A] px-1">
                {t("agency_panel_support_legal_header")}
              </p>
              <div className="bg-white rounded-[10px] border border-[#E5E3DF] divide-y divide-[#E5E3DF] shadow-xs overflow-hidden">
                {/* Support */}
                <button
                  type="button"
                  onClick={() => {
                    setSupportSubject("");
                    setSupportMessage("");
                    setSupportError(null);
                    setSupportSuccess(false);
                    setSupportValidationErrors({});
                    setIsSupportModalOpen(true);
                  }}
                  className="w-full flex items-center justify-between p-4 hover:bg-[#F8F7F5] transition-colors cursor-pointer text-left"
                >
                  <div className="flex items-center gap-3">
                    <HelpCircle className="w-4 h-4 text-[#666666]" />
                    <span className="text-xs font-semibold text-[#1A1A1A]">
                      {t("support_title")}
                    </span>
                  </div>
                  <ChevronRight className="w-4 h-4 text-[#8A8A8A]" />
                </button>

                {/* Terms of Service & Privacy */}
                <Link
                  href="/terms"
                  target="_blank"
                  className="w-full flex items-center justify-between p-4 hover:bg-[#F8F7F5] transition-colors cursor-pointer text-left"
                >
                  <div className="flex items-center gap-3">
                    <FileText className="w-4 h-4 text-[#666666]" />
                    <span className="text-xs font-semibold text-[#1A1A1A]">
                      {t("agency_panel_terms_link")}
                    </span>
                  </div>
                  <ExternalLink className="w-4 h-4 text-[#8A8A8A]" />
                </Link>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* ========================================================================= */}
      {/* INVOICE PREVIEW / RECEIPT MODAL                                           */}
      {/* ========================================================================= */}
      {selectedInvoice && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-xs">
          {/* Print Isolation Styles to ensure 100% clean single-page printing */}
          <style
            dangerouslySetInnerHTML={{
              __html: `
                @media print {
                  @page {
                    size: A4 portrait;
                    margin: 12mm 15mm;
                  }
                  html, body {
                    margin: 0 !important;
                    padding: 0 !important;
                    background: #ffffff !important;
                    height: auto !important;
                    overflow: visible !important;
                  }
                  body * {
                    visibility: hidden !important;
                  }
                  #printable-invoice-modal,
                  #printable-invoice-modal * {
                    visibility: visible !important;
                  }
                  #printable-invoice-modal {
                    position: absolute !important;
                    left: 0 !important;
                    top: 0 !important;
                    width: 100% !important;
                    max-width: 100% !important;
                    margin: 0 !important;
                    padding: 0 !important;
                    border: none !important;
                    box-shadow: none !important;
                    background: #ffffff !important;
                  }
                  #printable-invoice {
                    position: relative !important;
                    width: 100% !important;
                    border: 1px solid #d1d5db !important;
                    border-radius: 8px !important;
                    padding: 22px !important;
                    background: #ffffff !important;
                    page-break-inside: avoid !important;
                    break-inside: avoid !important;
                    page-break-after: avoid !important;
                  }
                  .print-hide {
                    display: none !important;
                  }
                }
              `,
            }}
          />

          <div
            id="printable-invoice-modal"
            className="bg-white rounded-[10px] border border-[#E5E3DF] p-6 max-w-lg w-full shadow-2xl animate-in fade-in zoom-in-95 duration-150 max-h-[92vh] overflow-y-auto"
          >
            {/* Header */}
            <div className="flex items-center justify-between pb-3 border-b border-[#E5E3DF] mb-4 print-hide">
              <div className="flex items-center gap-2.5">
                <div className="w-8 h-8 rounded-lg bg-[#E5EEF6] text-[#1B5888] flex items-center justify-center">
                  <Receipt className="w-4 h-4" />
                </div>
                <div>
                  <h3 className="text-sm font-bold text-[#1A1A1A]">
                    {t("agency_panel_invoice_preview_title")}
                  </h3>
                  <span className="text-[11px] font-mono text-[#666666]">
                    {selectedInvoice.invoice_number}
                  </span>
                </div>
              </div>
              <button
                type="button"
                onClick={() => setSelectedInvoice(null)}
                className="w-8 h-8 rounded-full bg-[#F8F7F5] border border-[#E5E3DF] flex items-center justify-center text-[#666666] hover:text-[#1A1A1A] cursor-pointer"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            {/* Printable Invoice Sheet */}
            <div
              id="printable-invoice"
              className="relative overflow-hidden bg-[#FAF9F7] rounded-[10px] border border-[#E5E3DF] p-5 space-y-4 text-xs text-[#1A1A1A]"
            >
              {/* Watermark for Demo / Sample Invoices */}
              {(isDemoMode || !selectedInvoice.agency_id || selectedInvoice.id.startsWith("demo")) && (
                <div className="absolute inset-0 flex items-center justify-center pointer-events-none select-none z-10 overflow-hidden">
                  <div className="transform -rotate-25 border-4 border-dashed border-rose-500/25 px-8 py-3 rounded-[10px] text-center bg-rose-50/10">
                    <span className="text-3xl sm:text-4xl font-black tracking-widest text-rose-500/20 uppercase block">
                      ÖRNEKTİR
                    </span>
                    <span className="text-[10px] sm:text-xs font-bold tracking-widest text-rose-500/25 uppercase block mt-0.5">
                      SAMPLE • PRIMERAK • UZORAK
                    </span>
                  </div>
                </div>
              )}

              {/* Issuer & Client Row */}
              <div className="flex flex-col sm:flex-row sm:items-start justify-between gap-4 pb-4 border-b border-[#E5E3DF]">
                <div>
                  <span className="text-[10px] font-bold text-[#8A8A8A] uppercase tracking-wider block mb-1">
                    {t("agency_panel_invoice_service_provider")}
                  </span>
                  <h4 className="font-extrabold text-sm text-[#1B5888]">
                    GIZEM ORUM PR Konsultantske aktivnosti Lilanova
                  </h4>
                  <p className="text-[11px] text-[#666666] mt-0.5">
                    Bulevar Patrijarha Pavla 91, sprat 4, stan 44, 21000 Novi Sad, Srbija
                  </p>
                  <p className="text-[11px] text-[#666666]">
                    PIB: 115512104 • MB: 68423937
                  </p>
                </div>

                <div className="sm:text-right">
                  <span className="text-[10px] font-bold text-[#8A8A8A] uppercase tracking-wider block mb-1">
                    {t("agency_panel_invoice_client_agency")}
                  </span>
                  <h4 className="font-bold text-xs text-[#1A1A1A]">
                    {agencyName || fullName || "Stanomer Partner Agencija"}
                  </h4>
                  <p className="text-[11px] text-[#666666] mt-0.5">
                    {agencyEmail || user?.email || "agencija@stanomer.com"}
                  </p>
                </div>
              </div>

              {/* Invoice Meta */}
              <div className="grid grid-cols-2 sm:grid-cols-3 gap-3 py-1">
                <div>
                  <span className="text-[10px] text-[#8A8A8A] block font-bold">
                    {t("agency_panel_invoice_period")}
                  </span>
                  <span className="font-semibold text-xs text-[#1A1A1A]">
                    {selectedInvoice.period}
                  </span>
                </div>
                <div>
                  <span className="text-[10px] text-[#8A8A8A] block font-bold">
                    {t("agency_panel_invoice_due_date")}
                  </span>
                  <span className="font-semibold text-xs text-[#1A1A1A]">
                    {selectedInvoice.due_date || "05.11.2026"}
                  </span>
                </div>
                <div>
                  <span className="text-[10px] text-[#8A8A8A] block font-bold">
                    {t("agency_panel_invoice_status")}
                  </span>
                  <span className="inline-flex items-center gap-1 text-[11px] font-bold text-emerald-700">
                    <Check className="w-3 h-3 text-emerald-600" />
                    <span>{t("agency_panel_invoice_status_paid")}</span>
                  </span>
                </div>
              </div>

              {/* Line Items Table */}
              <div className="border border-[#E5E3DF] rounded-lg overflow-hidden bg-white">
                <table className="w-full text-left text-xs">
                  <thead className="bg-[#F0EFEB] text-[#666666] font-bold">
                    <tr>
                      <th className="py-2 px-3">{t("agency_panel_invoice_item_desc")}</th>
                      <th className="py-2 px-3 text-right">{t("agency_panel_invoice_amount")}</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-[#E5E3DF]">
                    <tr>
                      <td className="py-2.5 px-3">
                        <span className="font-bold block text-[#1A1A1A]">
                          {t("agency_panel_invoice_item_title")}
                        </span>
                        <span className="text-[11px] text-[#8A8A8A]">
                          {selectedInvoice.period} {t("agency_panel_invoice_item_sub")}
                        </span>
                      </td>
                      <td className="py-2.5 px-3 text-right font-bold text-[#1A1A1A] tabular-nums">
                        {Number(selectedInvoice.amount).toFixed(2)} {selectedInvoice.currency}
                      </td>
                    </tr>
                  </tbody>
                  <tfoot className="bg-[#FAF9F7] font-bold border-t border-[#E5E3DF]">
                    <tr>
                      <td className="py-2.5 px-3 text-[#4A4A4A]">{t("agency_panel_invoice_total")}</td>
                      <td className="py-2.5 px-3 text-right text-sm text-[#1B5888] tabular-nums">
                        {Number(selectedInvoice.amount).toFixed(2)} {selectedInvoice.currency}
                      </td>
                    </tr>
                  </tfoot>
                </table>
              </div>

              <div className="text-[10px] text-[#8A8A8A] leading-relaxed pt-1">
                {t("agency_panel_invoice_disclaimer")}
              </div>
            </div>

            {/* Actions */}
            <div className="flex items-center gap-2 pt-4 print-hide">
              <button
                type="button"
                onClick={() => setSelectedInvoice(null)}
                className="flex-1 py-2.5 rounded-[10px] border border-[#E5E3DF] text-xs font-semibold text-[#4A4A4A] hover:bg-slate-50 cursor-pointer"
              >
                {t("agency_panel_cancel_btn")}
              </button>

              <button
                type="button"
                onClick={() => {
                  if (typeof window !== "undefined") {
                    window.print();
                  }
                }}
                className="flex-1 py-2.5 rounded-[10px] bg-[#1B5888] hover:bg-[#15466d] active:bg-[#12406A] text-white text-xs font-bold cursor-pointer flex items-center justify-center gap-1.5 shadow-xs"
              >
                <Printer className="w-3.5 h-3.5" />
                <span>{t("agency_panel_invoice_print_btn")}</span>
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Change Password is now handled inline inside the Account & Security card above */}

      {/* Delete Account Confirmation Modal */}
      {isDeleteModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/40 backdrop-blur-xs">
          <div className="bg-white rounded-[10px] border border-rose-200 p-6 max-w-md w-full shadow-2xl animate-in fade-in zoom-in-95 duration-150">
            <div className="flex items-center gap-3 text-rose-600 mb-3">
              <div className="w-10 h-10 rounded-full bg-rose-100 flex items-center justify-center shrink-0">
                <Trash2 className="w-5 h-5 text-rose-600" />
              </div>
              <h3 className="text-base font-bold text-[#1A1A1A]">
                {t("agency_panel_delete_account_title")}
              </h3>
            </div>
            <p className="text-xs text-[#666666] leading-relaxed mb-6">
              {t("agency_panel_delete_account_warning")}
            </p>

            {deleteErrorMessage && (
              <div className="p-3 rounded-[10px] bg-rose-50 border border-rose-200 text-rose-800 text-xs font-semibold flex items-center gap-2 mb-4">
                <AlertCircle className="w-4 h-4 text-rose-600 shrink-0" />
                <span>{deleteErrorMessage}</span>
              </div>
            )}

            <div className="flex items-center gap-2">
              <button
                type="button"
                onClick={() => setIsDeleteModalOpen(false)}
                className="flex-1 py-2.5 rounded-[10px] border border-[#E5E3DF] text-xs font-semibold text-[#4A4A4A] hover:bg-slate-50 cursor-pointer"
              >
                {t("agency_panel_cancel_btn")}
              </button>
              <button
                type="button"
                disabled={isDeleting}
                onClick={handleDeleteAccount}
                className="flex-1 py-2.5 rounded-[10px] bg-rose-600 hover:bg-rose-700 text-white text-xs font-bold cursor-pointer disabled:opacity-50"
              >
                {isDeleting ? (
                  <span className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin inline-block" />
                ) : (
                  t("agency_panel_delete_confirm_btn")
                )}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Support Ticket Modal */}
      {isSupportModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/40 backdrop-blur-xs">
          <div className="bg-white rounded-[10px] border border-[#E5E3DF] p-6 max-w-lg w-full shadow-2xl animate-in fade-in zoom-in-95 duration-150 max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between pb-3 border-b border-[#E5E3DF] mb-4">
              <div className="flex items-center gap-2">
                <HelpCircle className="w-5 h-5 text-[#1B5888]" />
                <h3 className="text-sm font-bold text-[#1A1A1A]">
                  {t("support_title")}
                </h3>
              </div>
              <button
                type="button"
                onClick={() => setIsSupportModalOpen(false)}
                className="w-8 h-8 rounded-full bg-[#F8F7F5] border border-[#E5E3DF] flex items-center justify-center text-[#666666] hover:text-[#1A1A1A] cursor-pointer"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <p className="text-xs text-[#666666] mb-5">
              {t("support_desc")}
            </p>

            {supportSuccess ? (
              <div className="p-6 bg-emerald-50 border border-emerald-200 rounded-[10px] text-center space-y-2">
                <CheckCircle2 className="w-10 h-10 text-emerald-600 mx-auto" />
                <p className="text-sm font-bold text-emerald-900">
                  {t("success_msg")}
                </p>
              </div>
            ) : (
              <form onSubmit={handleSupportSubmit} className="space-y-4">
                {/* Subject */}
                <div>
                  <label className="block text-xs font-bold text-[#4A4A4A] mb-1">
                    {t("subject")}
                  </label>
                  <div className="relative">
                    <Type className="w-4 h-4 text-[#8A8A8A] absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none" />
                    <input
                      type="text"
                      value={supportSubject}
                      onChange={(e) => {
                        setSupportSubject(e.target.value);
                        if (supportValidationErrors.subject) {
                          setSupportValidationErrors((prev) => ({
                            ...prev,
                            subject: undefined,
                          }));
                        }
                      }}
                      placeholder={t("subject")}
                      className={`w-full pl-9 pr-3 py-2.5 rounded-[10px] border ${
                        supportValidationErrors.subject
                          ? "border-rose-400 bg-rose-50/20"
                          : "border-[#E5E3DF] bg-[#F8F7F5]"
                      } focus:bg-white text-xs text-[#1A1A1A] font-semibold focus:outline-none focus:ring-1 focus:ring-[#1B5888]`}
                    />
                  </div>
                  {supportValidationErrors.subject && (
                    <p className="text-[11px] text-rose-600 font-semibold mt-1">
                      {supportValidationErrors.subject}
                    </p>
                  )}
                </div>

                {/* Email */}
                <div>
                  <label className="block text-xs font-bold text-[#4A4A4A] mb-1">
                    {t("email")}
                  </label>
                  <div className="relative">
                    <Mail className="w-4 h-4 text-[#8A8A8A] absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none" />
                    <input
                      type="email"
                      value={supportEmail}
                      onChange={(e) => {
                        setSupportEmail(e.target.value);
                        if (supportValidationErrors.email) {
                          setSupportValidationErrors((prev) => ({
                            ...prev,
                            email: undefined,
                          }));
                        }
                      }}
                      placeholder="example@mail.com"
                      className={`w-full pl-9 pr-3 py-2.5 rounded-[10px] border ${
                        supportValidationErrors.email
                          ? "border-rose-400 bg-rose-50/20"
                          : "border-[#E5E3DF] bg-[#F8F7F5]"
                      } focus:bg-white text-xs text-[#1A1A1A] font-semibold focus:outline-none focus:ring-1 focus:ring-[#1B5888]`}
                    />
                  </div>
                  {supportValidationErrors.email && (
                    <p className="text-[11px] text-rose-600 font-semibold mt-1">
                      {supportValidationErrors.email}
                    </p>
                  )}
                </div>

                {/* Category */}
                <div>
                  <label className="block text-xs font-bold text-[#4A4A4A] mb-1">
                    {t("category")}
                  </label>
                  <div className="relative">
                    <Tag className="w-4 h-4 text-[#8A8A8A] absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none" />
                    <select
                      value={supportCategory}
                      onChange={(e) => setSupportCategory(e.target.value)}
                      className="w-full pl-9 pr-3 py-2.5 rounded-[10px] border border-[#E5E3DF] bg-[#F8F7F5] focus:bg-white text-xs text-[#1A1A1A] font-semibold focus:outline-none focus:ring-1 focus:ring-[#1B5888] appearance-none cursor-pointer"
                    >
                      <option value="Support">{t("cat_support")}</option>
                      <option value="Bug">{t("cat_bug")}</option>
                      <option value="Other">{t("cat_other")}</option>
                    </select>
                  </div>
                </div>

                {/* Message */}
                <div>
                  <label className="block text-xs font-bold text-[#4A4A4A] mb-1">
                    {t("message")}
                  </label>
                  <textarea
                    rows={5}
                    value={supportMessage}
                    onChange={(e) => {
                      setSupportMessage(e.target.value);
                      if (supportValidationErrors.message) {
                        setSupportValidationErrors((prev) => ({
                          ...prev,
                          message: undefined,
                        }));
                      }
                    }}
                    placeholder={t("message")}
                    className={`w-full p-3 rounded-[10px] border ${
                      supportValidationErrors.message
                        ? "border-rose-400 bg-rose-50/20"
                        : "border-[#E5E3DF] bg-[#F8F7F5]"
                    } focus:bg-white text-xs text-[#1A1A1A] font-semibold focus:outline-none focus:ring-1 focus:ring-[#1B5888] resize-none`}
                  />
                  {supportValidationErrors.message && (
                    <p className="text-[11px] text-rose-600 font-semibold mt-1">
                      {supportValidationErrors.message}
                    </p>
                  )}
                </div>

                {supportError && (
                  <div className="p-3 rounded-[10px] bg-rose-50 border border-rose-200 text-rose-800 text-xs font-semibold flex items-center gap-2">
                    <AlertCircle className="w-4 h-4 text-rose-600 shrink-0" />
                    <span>{supportError}</span>
                  </div>
                )}

                <div className="flex items-center gap-2 pt-2">
                  <button
                    type="button"
                    onClick={() => setIsSupportModalOpen(false)}
                    className="flex-1 py-3 rounded-[10px] border border-[#E5E3DF] text-xs font-semibold text-[#4A4A4A] hover:bg-slate-50 cursor-pointer"
                  >
                    {t("agency_panel_cancel_btn")}
                  </button>
                  <button
                    type="submit"
                    disabled={isSendingSupport}
                    className="flex-1 py-3 rounded-[10px] bg-[#1B5888] hover:bg-[#15466d] active:bg-[#12406A] text-white text-xs font-bold cursor-pointer disabled:opacity-50 flex items-center justify-center gap-2 shadow-xs"
                  >
                    {isSendingSupport ? (
                      <>
                        <span className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin inline-block" />
                        <span>{t("sending")}</span>
                      </>
                    ) : (
                      <span>{t("send")}</span>
                    )}
                  </button>
                </div>
              </form>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
