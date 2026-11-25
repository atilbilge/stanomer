"use client";

import React, { useState, useEffect, useMemo, useCallback, useRef } from "react";
import Link from "next/link";
import {
  ShowcaseTemplate,
  ShowcasePalette,
  ShowcaseRadius,
  ContactChannels,
  ShowcaseCurrency,
  AgencyMaintStatusFilter,
  AgencyTask,
  AgencyTaskPrefill,
  AgencyTaskPriority,
  AgencyTaskSourceType,
  AgencyTaskStatus,
  AgencyAssigneeOption,
} from "./types";
import ManagedPropertiesTab from "./components/ManagedPropertiesTab";
import SettingsTab from "./components/SettingsTab";
import ListingFormTab from "./components/ListingFormTab";
import LeadsTab from "./components/LeadsTab";
import MaintenanceTab from "./components/MaintenanceTab";
import PmDashboardTab from "./components/PmDashboardTab";
import ListingsTab, { CloseAndHandoverParams } from "./components/ListingsTab";
import PaymentsTab from "./components/PaymentsTab";
import XmlFeedsTab from "./components/XmlFeedsTab";
import WelcomeTab from "./components/WelcomeTab";
import AccountSettingsTab from "./components/AccountSettingsTab";
import TasksTab, { TaskFormModal } from "./components/TasksTab";
import DemoVerificationModal from "./components/DemoVerificationModal";
import DemoFloatingNudge from "./components/DemoFloatingNudge";
import { MAINTENANCE_CATEGORIES } from "./categoryAndPaymentIcons";
import { useLanguage, Language } from "../../components/LanguageProvider";
import translations from "../../lib/translations.json";
import { supabase, prodPublicClient } from "../../lib/supabaseClient";
import {
  SERBIAN_LOCATIONS,
  TRANSACTION_TYPES,
  PROPERTY_TYPES,
  ROOM_STRUCTURES,
  HEATING_TYPES,
  PROPERTY_CONDITIONS,
  FURNISHING_TYPES,
  getDictLabel,
} from "../../lib/serbianRealEstateDict";
import { validate4ZidaListing, validateHaloOglasiListing } from "../../lib/portalValidators";
import {
  Building2,
  Compass,
  LayoutDashboard,
  ShieldCheck,
  Plus,
  PlusCircle,
  Edit3,
  Filter,
  Copy,
  Check,
  ExternalLink,
  Upload,
  Trash2,
  Eye,
  EyeOff,
  CheckCircle2,
  ChevronRight,
  AlertCircle,
  Rss,
  MapPin,
  Euro,
  Layers,
  Image as ImageIcon,
  LogOut,
  Info,
  Play,
  UserCheck,
  Columns3,
  RefreshCw,
  Settings,
  Search,
  ArrowLeft,
  ArrowRight,
  Globe,
  Phone,
  MessageCircle,
  Inbox,
  Mail,
  Calendar,
  FileText,
  LayoutGrid,
  List,
  Send,
  Clock,
  User,
  ArrowUpRight,
  Star,
  X,
  Receipt,
  CreditCard,
  Wallet,
  XCircle,
  AlertTriangle,
  Home,
  Wrench,
  CheckCheck,
  Sparkles,
  Share2,
  FileDown,
  UserPlus,
  CalendarOff,
  StickyNote,
  TrendingUp,
  Percent,
  MessageSquare,
  FilePlus,
  FileQuestion,
  Paperclip,
  UploadCloud,
  DollarSign,
  ChevronDown,
  ChevronUp,
  ChevronLeft,
  PanelLeftClose,
  PanelLeftOpen,
  SlidersHorizontal,
  CheckSquare,
  Square,
  Lock,
  Menu,
  Smartphone,
  Zap,
  Bell,
} from "lucide-react";

import {
  DirectoryAgencyMatch,
  ListingImageRow,
  AgencyListingRow,
  PortalDef,
  PortalFeedLogRow,
  LeadComment,
  LeadType,
  LeadStatus,
  AgencyLead,
  KanbanColId,
  AgencyRentPayment,
  AgencyManagedProperty,
  AgencyContract,
  AgencyMaintenanceRequest,
  AgencyPanelTab,
} from "./types";

import {
  AMENITY_KEYS,
  PORTAL_LIST,
  getKanbanColumnForStatus,
  getAllowedStatusesForType,
  STATUS_TRANSLATION_KEYS,
  STATUS_STYLES,
  KANBAN_COLUMNS,
} from "./constants";

import {
  DEMO_AGENCY_LEADS,
  DEMO_AGENCY_PAYMENTS,
  DEMO_AGENCY_MANAGED_PROPERTIES,
  DEMO_AGENCY_CONTRACTS,
  DEMO_AGENCY_MAINTENANCE_REQUESTS,
  DEMO_AGENCY_LISTINGS,
} from "./demoData";

import { processRentPayments } from "./utils";

export default function AgencyPanelPage() {
  const { lang, setLang, t } = useLanguage();
  const activeLocale =
    lang === "TR"
      ? "tr-TR"
      : lang === "EN"
        ? "en-US"
        : lang === "RU"
          ? "ru-RU"
          : "sr-RS";

  // Auth & Mode State
  const [userId, setUserId] = useState<string | null>(null);
  const [agencyRole, setAgencyRole] = useState<"agency_admin" | "agency_operation">("agency_admin");
  const [agencyTasks, setAgencyTasks] = useState<AgencyTask[]>([]);
  const [loadingTasks, setLoadingTasks] = useState(false);
  const [teamAssignees, setTeamAssignees] = useState<AgencyAssigneeOption[]>([]);
  const [isTaskModalOpen, setIsTaskModalOpen] = useState(false);
  const [editingTask, setEditingTask] = useState<AgencyTask | null>(null);
  const [taskPrefill, setTaskPrefill] = useState<AgencyTaskPrefill | null>(null);
  const [taskPropertyFilter, setTaskPropertyFilter] = useState<string | null>(null);
  const [taskListingFilter, setTaskListingFilter] = useState<string | null>(null);
  const [isCheckingSession, setIsCheckingSession] = useState<boolean>(true);
  const [activeModules, setActiveModules] = useState<string[]>([
    "portfolio_distribution",
    "property_lease_management",
  ]);
  const [agencyName, setAgencyName] = useState<string>("");
  const [agencyPhone, setAgencyPhone] = useState<string>("");
  const [agencyEmail, setAgencyEmail] = useState<string>("");
  const [agencyWebsite, setAgencyWebsite] = useState<string>("");
  const [agencyLogoUrl, setAgencyLogoUrl] = useState<string>("");
  const [agencyCity, setAgencyCity] = useState<string>("Beograd");
  const [agencyAddress, setAgencyAddress] = useState<string>("");
  const [contactChannels, setContactChannels] = useState<ContactChannels>("both");
  const [showcaseTemplate, setShowcaseTemplate] = useState<ShowcaseTemplate>("stanomer_modern");
  const [showcasePalette, setShowcasePalette] = useState<ShowcasePalette>("royal_blue");
  const [showcaseRadius, setShowcaseRadius] = useState<ShowcaseRadius>("rounded");
  const [showcaseLanguages, setShowcaseLanguages] = useState<Language[]>([
    "SR_LAT",
    "EN",
    "RU",
    "TR",
  ]);
  const [showcaseCurrencies, setShowcaseCurrencies] = useState<ShowcaseCurrency[]>([
    "EUR",
    "RSD",
  ]);
  const [showcaseDefaultCurrency, setShowcaseDefaultCurrency] = useState<ShowcaseCurrency>("EUR");
  const [agencySlug, setAgencySlug] = useState<string>("");
  const [agencyCustomDomain, setAgencyCustomDomain] = useState<string>("");
  const [feedLogs, setFeedLogs] = useState<PortalFeedLogRow[]>([]);
  const [loadingFeedLogs, setLoadingFeedLogs] = useState<boolean>(false);
  const [dnsCheckLoading, setDnsCheckLoading] = useState<boolean>(false);
  const [dnsCheckResult, setDnsCheckResult] = useState<{
    valid: boolean;
    reason?: string;
    message?: string;
    recordType?: string;
    expectedTarget?: string;
  } | null>(null);
  const [copiedField, setCopiedField] = useState<string | null>(null);

  const copyToClipboard = (text: string, fieldKey: string) => {
    if (typeof navigator !== "undefined" && navigator.clipboard) {
      navigator.clipboard.writeText(text);
      setCopiedField(fieldKey);
      setTimeout(() => setCopiedField(null), 2000);
    }
  };

  const handleVerifyDns = async () => {
    if (!checkEffectiveDemoVerified()) {
      setIsGatekeeperModalOpen(true);
      return;
    }
    if (!agencyCustomDomain.trim()) return;
    setDnsCheckLoading(true);
    setDnsCheckResult(null);
    try {
      const res = await fetch(
        `/api/domain/verify?domain=${encodeURIComponent(agencyCustomDomain.trim())}`
      );
      const json = await res.json();
      setDnsCheckResult(json);
    } catch {
      setDnsCheckResult({
        valid: false,
        reason: "dns_error",
      });
    } finally {
      setDnsCheckLoading(false);
    }
  };

  function handleSelectTemplate(tpl: ShowcaseTemplate) {
    setShowcaseTemplate(tpl);
    if (tpl === "stanomer_modern") {
      setShowcasePalette("royal_blue");
      setShowcaseRadius("rounded");
    } else if (tpl === "quiet_luxury") {
      setShowcasePalette("champagne_gold");
      setShowcaseRadius("subtle");
    } else if (tpl === "minimal_light") {
      setShowcasePalette("emerald_prestige");
      setShowcaseRadius("sharp");
    } else if (tpl === "kolm_dark") {
      setShowcasePalette("kolm_mint");
      setShowcaseRadius("rounded");
    } else if (tpl === "lumira") {
      setShowcasePalette("lumira_coral");
      setShowcaseRadius("rounded");
    } else if (tpl === "aldervik") {
      setShowcasePalette("aldervik_amber");
      setShowcaseRadius("subtle");
    } else if (tpl === "sage") {
      setShowcasePalette("sage_terracotta");
      setShowcaseRadius("rounded");
    } else if (tpl === "onyx_dark") {
      setShowcasePalette("onyx_brass");
      setShowcaseRadius("sharp");
    }
  }

  const showcaseUrl = agencyCustomDomain.trim()
    ? `https://${agencyCustomDomain.trim()}`
    : agencySlug.trim()
      ? `/agencija/${agencySlug.trim()}`
      : `/agencija/${userId || "demo"}`;
  const [showProfilePanel, setShowProfilePanel] = useState<boolean>(false);
  const [savingProfile, setSavingProfile] = useState<boolean>(false);
  const [uploadingLogo, setUploadingLogo] = useState<boolean>(false);

  const [isDemoMode, setIsDemoMode] = useState<boolean>(false);
  const [isDemoVerified, setIsDemoVerified] = useState<boolean>(false);
  const [isGatekeeperModalOpen, setIsGatekeeperModalOpen] = useState<boolean>(false);
  const [isFloatingNudgeVisible, setIsFloatingNudgeVisible] = useState<boolean>(false);
  const [authTab, setAuthTab] = useState<"signin" | "signup" | "reset">("signin");
  const [authEmail, setAuthEmail] = useState("");
  const [resetStep, setResetStep] = useState<1 | 2>(1);
  const [resetCode, setResetCode] = useState("");
  const [resetNewPassword, setResetNewPassword] = useState("");
  const [resetConfirmPassword, setResetConfirmPassword] = useState("");
  const [authPassword, setAuthPassword] = useState("");
  const [signupCompany, setSignupCompany] = useState("");
  const [signupPhone, setSignupPhone] = useState("");
  const [signupWebsite, setSignupWebsite] = useState("");
  const [dirSearchQuery, setDirSearchQuery] = useState("");
  const [dirMatches, setDirMatches] = useState<DirectoryAgencyMatch[]>([]);
  const [selectedDirAgency, setSelectedDirAgency] = useState<DirectoryAgencyMatch | null>(null);
  const [showPassword, setShowPassword] = useState(false);
  const [authError, setAuthError] = useState<string | null>(null);
  const [isRoleError, setIsRoleError] = useState(false);
  const [showRoleErrorDetails, setShowRoleErrorDetails] = useState(false);
  const [authSuccess, setAuthSuccess] = useState<string | null>(null);
  const [authLoading, setAuthLoading] = useState(false);

  // Listings State
  const [listings, setListings] = useState<AgencyListingRow[]>([]);
  const [loadingListings, setLoadingListings] = useState(false);
  const [copiedPortal, setCopiedPortal] = useState<string | null>(null);
  const [statusMessage, setStatusMessage] = useState<{ type: "success" | "error"; text: string } | null>(null);

  // Personal Demo Modal & Session State
  const [isDemoModalOpen, setIsDemoModalOpen] = useState(false);
  const [demoFormAgencyName, setDemoFormAgencyName] = useState("");
  const [demoFormEmail, setDemoFormEmail] = useState("");
  const [demoFormPhone, setDemoFormPhone] = useState("");
  const [demoFormCity, setDemoFormCity] = useState("Beograd");
  const [demoIncludeListings, setDemoIncludeListings] = useState(true);
  const [demoIncludeRental, setDemoIncludeRental] = useState(true);
  const [demoMarketingConsent, setDemoMarketingConsent] = useState(true);
  const [showDemoPeek, setShowDemoPeek] = useState(false);
  const [demoFormError, setDemoFormError] = useState<string | null>(null);
  const [demoFocus, setDemoFocus] = useState<"presales" | "aftersales" | "both">("both");
  const [submittingDemoForm, setSubmittingDemoForm] = useState(false);
  const [demoExpiresAt, setDemoExpiresAt] = useState<string | null>(null);
  const [demoExpiredAlert, setDemoExpiredAlert] = useState<{ expired: boolean; agencyName?: string } | null>(null);

  const SERBIAN_CITIES = useMemo(
    () => [
      "Beograd",
      "Novi Sad",
      "Niš",
      "Kragujevac",
      "Subotica",
      "Pančevo",
      "Zrenjanin",
      "Čačak",
      "Kraljevo",
      "Novi Pazar",
    ],
    []
  );

  // Safe i18n helper with required fallback order: selected locale -> sr (SR_LAT) -> en (EN)
  const tSafe = useCallback(
    (key: string, replacements?: Record<string, string | number>): string => {
      let text = (translations as any)[lang]?.[key];
      if (!text) {
        if ((translations as any)["SR_LAT"]?.[key]) {
          console.warn(`[i18n Fallback] Missing key "${key}" in "${lang}", fallback to SR_LAT`);
          text = (translations as any)["SR_LAT"][key];
        } else if ((translations as any)["EN"]?.[key]) {
          console.warn(`[i18n Fallback] Missing key "${key}" in "${lang}", fallback to EN`);
          text = (translations as any)["EN"][key];
        } else {
          console.warn(`[i18n Missing] Key "${key}" not found in any translation dictionary`);
          return key;
        }
      }
      if (replacements) {
        for (const [rKey, rVal] of Object.entries(replacements)) {
          text = text.replace(new RegExp(`\\{${rKey}\\}`, "g"), String(rVal));
        }
      }
      return text;
    },
    [lang]
  );

  // Active locale code passed to demo environment and consent log
  const activeLocaleCode = useMemo(() => {
    switch (lang) {
      case "SR_CYR":
        return "sr-Cyrl";
      case "EN":
        return "en";
      case "RU":
        return "ru";
      case "TR":
        return "tr";
      case "SR_LAT":
      default:
        return "sr";
    }
  }, [lang]);

  // Derived demo focus from independent module selections
  const derivedDemoFocus = useMemo<"presales" | "aftersales" | "both">(() => {
    if (demoIncludeListings && demoIncludeRental) return "both";
    if (demoIncludeListings) return "presales";
    return "aftersales";
  }, [demoIncludeListings, demoIncludeRental]);

  const demoTimeRemaining = useMemo(() => {
    if (!demoExpiresAt) return "7d";
    const diff = new Date(demoExpiresAt).getTime() - Date.now();
    if (diff <= 0) return "0h";
    const days = Math.floor(diff / (1000 * 60 * 60 * 24));
    const hours = Math.floor((diff % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
    const mins = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
    if (days > 0) {
      return `${days}d ${hours}h`;
    }
    return `${hours}h ${mins}m`;
  }, [demoExpiresAt]);

  const handleStartPersonalDemo = async (e: React.FormEvent) => {
    e.preventDefault();
    setDemoFormError(null);

    // Enforce at least one module
    if (!demoIncludeListings && !demoIncludeRental) {
      setDemoFormError(tSafe("agency_demo_err_min_module"));
      return;
    }

    // Enforce consent
    if (!demoMarketingConsent) {
      setDemoFormError(tSafe("agency_demo_err_consent_required"));
      return;
    }

    if (!demoFormAgencyName.trim()) {
      setDemoFormError(tSafe("agency_demo_err_agency_required"));
      return;
    }

    const emailInput = demoFormEmail.trim().toLowerCase();
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailInput || !emailRegex.test(emailInput)) {
      setDemoFormError(tSafe("agency_demo_err_email_invalid"));
      return;
    }

    const agencyNameInput = demoFormAgencyName.trim();
    const phoneInput = demoFormPhone.trim();
    const cityInput = demoFormCity.trim() || "Beograd";
    const focusInput = derivedDemoFocus;
    const modules: string[] = [];
    if (demoIncludeListings) modules.push("portfolio_distribution");
    if (demoIncludeRental) modules.push("property_lease_management");
    setActiveModules(modules);
    const expiresAtIso = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString();

    setSubmittingDemoForm(true);

    // 1. Immediately launch demo in UI (read-only preview until email is verified)
    setIsDemoVerified(false);
    activatePersonalDemoSandbox({
      agencyName: agencyNameInput,
      email: emailInput,
      phone: phoneInput,
      city: cityInput,
      focus: focusInput,
      active_modules: modules,
      expiresAt: expiresAtIso,
    });
    setIsDemoModalOpen(false);

    // 2. Call backend in background to persist session & dispatch Brevo emails
    try {
      const res = await fetch("/api/agency-demo", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          agencyName: agencyNameInput,
          email: emailInput,
          phone: phoneInput,
          city: cityInput,
          focus: focusInput,
          locale: activeLocaleCode,
          marketingConsent: demoMarketingConsent,
        }),
      });
      const data = await res.json();
      if (!res.ok) {
        if (data.key) {
          console.warn("Agency demo submission rejected:", tSafe(data.key));
        }
      } else if (data.success && data.token && typeof window !== "undefined") {
        const cleanSlug = agencyNameInput.trim().toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "") || "demo";
        localStorage.setItem(
          "stanomer_agency_demo",
          JSON.stringify({
            token: data.token,
            isVerified: false,
            slug: cleanSlug,
            agencyName: agencyNameInput,
            email: emailInput,
            phone: phoneInput,
            city: cityInput,
            focus: focusInput,
            active_modules: modules,
            expiresAt: data.expiresAt || expiresAtIso,
            locale: activeLocaleCode,
          })
        );
      }
    } catch (err) {
      console.warn("Could not dispatch agency demo API:", err);
    } finally {
      setSubmittingDemoForm(false);
    }
  };

  // On-demand Portal Integration Request State
  const [requestingPortal, setRequestingPortal] = useState<PortalDef | null>(null);
  const [customPortalName, setCustomPortalName] = useState("");
  const [portalAccountRef, setPortalAccountRef] = useState("");
  const [portalContactPhone, setPortalContactPhone] = useState("");
  const [portalNotes, setPortalNotes] = useState("");
  const [submittingPortalRequest, setSubmittingPortalRequest] = useState(false);
  const [portalRequestSubmitted, setPortalRequestSubmitted] = useState(false);

  const handleOpenPortalRequest = (portal: PortalDef) => {
    setRequestingPortal(portal);
    setCustomPortalName("");
    setPortalContactPhone(agencyPhone || "");
    setPortalAccountRef("");
    setPortalNotes("");
    setPortalRequestSubmitted(false);
  };

  const handleSubmitPortalRequest = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!requestingPortal) return;
    setSubmittingPortalRequest(true);
    const resolvedPortalName =
      requestingPortal.id === "other" && customPortalName.trim()
        ? customPortalName.trim()
        : requestingPortal.name;
    try {
      await fetch("/api/portal-integration-request", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          agencyId: !isDemoMode ? userId : undefined,
          agencyName: agencyName || "Stanomer Agency",
          portalName: resolvedPortalName,
          contactPhone: portalContactPhone || agencyPhone || "",
          contactEmail: agencyEmail || "",
          portalAccountRef: portalAccountRef || "",
          notes: portalNotes || "",
        }),
      });
      setPortalRequestSubmitted(true);
    } catch (err) {
      console.error("Portal integration request error:", err);
      setPortalRequestSubmitted(true);
    } finally {
      setSubmittingPortalRequest(false);
    }
  };

  // Tab & Filter State
  type AgencyPanelTab =
    | "welcome"
    | "tasks"
    | "listings"
    | "form"
    | "leads"
    | "xml"
    | "settings"
    | "payments"
    | "pm_dashboard"
    | "managed_properties"
    | "contracts"
    | "maintenance"
    | "account_settings";
  const [activeTab, setActiveTab] = useState<AgencyPanelTab>("welcome");
  const [currentUser, setCurrentUser] = useState<any>(null);
  type AgencyModule = "pnd" | "pms";
  const [activeModule, setActiveModule] = useState<AgencyModule>("pnd");
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState<boolean>(false);
  const [isProfileMenuOpen, setIsProfileMenuOpen] = useState<boolean>(false);
  const profileMenuRef = useRef<HTMLDivElement>(null);
  const [isLangMenuOpen, setIsLangMenuOpen] = useState<boolean>(false);
  const langMenuRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (profileMenuRef.current && !profileMenuRef.current.contains(event.target as Node)) {
        setIsProfileMenuOpen(false);
      }
      if (langMenuRef.current && !langMenuRef.current.contains(event.target as Node)) {
        setIsLangMenuOpen(false);
      }
    }
    if (isProfileMenuOpen || isLangMenuOpen) {
      document.addEventListener("mousedown", handleClickOutside);
    }
    return () => {
      document.removeEventListener("mousedown", handleClickOutside);
    };
  }, [isProfileMenuOpen, isLangMenuOpen]);

  useEffect(() => {
    if (["pm_dashboard", "managed_properties", "payments", "maintenance", "contracts"].includes(activeTab)) {
      setActiveModule("pms");
    } else if (["listings", "leads", "form", "xml", "settings"].includes(activeTab)) {
      setActiveModule("pnd");
    }
  }, [activeTab]);
  const [isSidebarCollapsed, setIsSidebarCollapsed] = useState<boolean>(false);
  const [moduleUpgradeRequested, setModuleUpgradeRequested] = useState<boolean>(false);

  async function handleRequestModuleUpgrade(targetCategory?: "portfolio" | "property_lease") {
    const requestedModuleLabel =
      targetCategory === "portfolio"
        ? "Portfolio & Distribution Module Upgrade"
        : "Property & Lease Management Module Upgrade";
    try {
      const res = await fetch("/api/portal-integration-request", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          agencyId: userId || null,
          agencyName: agencyName || "Stanomer Partner",
          portalName: requestedModuleLabel,
          contactEmail: agencyEmail || "",
          contactPhone: agencyPhone || "",
          notes: `Module upgrade requested from Agency Panel (${targetCategory || "property_lease"}).`,
        }),
      });
      if (!res.ok) {
        const errBody = await res.json().catch(() => ({}));
        throw new Error(errBody?.error || `HTTP ${res.status}`);
      }
      setModuleUpgradeRequested(true);
      setStatusMessage({
        type: "success",
        text: t("agency_welcome_upgrade_sent"),
      });
    } catch (err: any) {
      console.error("Upgrade request error:", err);
      setStatusMessage({
        type: "error",
        text: err?.message || t("agency_panel_msg_save_error"),
      });
    }
  }
  const [portfolioSearch, setPortfolioSearch] = useState("");
  const [portfolioTxFilter, setPortfolioTxFilter] = useState<string>("all");
  const [portfolioStatusFilter, setPortfolioStatusFilter] = useState<string>("all");

  // Payments State
  const [payments, setPayments] = useState<AgencyRentPayment[]>([]);
  const [loadingPayments, setLoadingPayments] = useState<boolean>(false);
  const [paymentStatusFilter, setPaymentStatusFilter] = useState<"all" | "awaiting" | "overdue" | "paid">("all");
  const [paymentSearchQuery, setPaymentSearchQuery] = useState<string>("");
  const [selectedReceiptPayment, setSelectedReceiptPayment] = useState<AgencyRentPayment | null>(null);
  const [processingPaymentId, setProcessingPaymentId] = useState<string | null>(null);

  // Property Detail Drawer Deep-link State (from PaymentsTab, etc.)
  const [drawerProperty, setDrawerProperty] = useState<AgencyManagedProperty | null>(null);
  const [drawerTargetPaymentId, setDrawerTargetPaymentId] = useState<string | null>(null);
  const [drawerReturnTab, setDrawerReturnTab] = useState<AgencyPanelTab | null>(null);

  const handleInspectPayment = (payment: AgencyRentPayment) => {
    const prop = managedProperties.find((m) => m.id === payment.property_id);
    if (!prop) return;
    setDrawerProperty(prop);
    setDrawerTargetPaymentId(payment.id);
    setDrawerReturnTab(activeTab);
    setActiveTab("managed_properties");
  };

  const handleInspectProperty = (propertyId: string) => {
    const prop = managedProperties.find((m) => m.id === propertyId);
    if (!prop) return;
    setDrawerProperty(prop);
    setDrawerTargetPaymentId(null);
    setDrawerReturnTab(activeTab);
    setActiveTab("managed_properties");
  };

  const handleBackFromDrawer = () => {
    setDrawerProperty(null);
    setDrawerTargetPaymentId(null);
    if (drawerReturnTab) {
      setActiveTab(drawerReturnTab);
      setDrawerReturnTab(null);
    }
  };

  const paymentStats = useMemo(() => {
    const now = new Date();
    now.setHours(0, 0, 0, 0);
    let collected = 0;
    let awaitingApproval = 0;
    let overdue = 0;
    let totalVolume = 0;

    for (const p of payments) {
      totalVolume += p.amount;
      if (p.status === "paid") {
        collected += p.amount;
      } else if (
        p.status === "declared" ||
        p.status === "disputed" ||
        (p.status === "pending" && p.declared_at)
      ) {
        awaitingApproval += 1;
      } else if (p.status === "overdue" || (p.status === "pending" && p.amount > 0 && p.due_date && new Date(p.due_date) < now)) {
        overdue += 1;
      }
    }
    return {
      collected,
      awaitingApproval,
      overdue,
      totalVolume,
      count: payments.length,
    };
  }, [payments]);

  const filteredPayments = useMemo(() => {
    const now = new Date();
    return payments.filter((p) => {
      if (paymentStatusFilter === "awaiting") {
        if (
          p.status !== "declared" &&
          p.status !== "disputed" &&
          (p.status !== "pending" || !p.declared_at)
        )
          return false;
      } else if (paymentStatusFilter === "overdue") {
        if (
          p.status === "paid" ||
          p.status === "declared" ||
          p.status === "disputed" ||
          p.declared_at ||
          new Date(p.due_date) >= now
        )
          return false;
      } else if (paymentStatusFilter === "paid") {
        if (p.status !== "paid") return false;
      }

      if (paymentSearchQuery.trim()) {
        const q = paymentSearchQuery.toLowerCase().trim();
        const matchProp =
          (p.property_title || "").toLowerCase().includes(q) ||
          (p.property_address || "").toLowerCase().includes(q);
        const matchTenant =
          (p.tenant_name || "").toLowerCase().includes(q) ||
          (p.tenant_phone || "").toLowerCase().includes(q);
        const matchTitle = (p.title || "").toLowerCase().includes(q);
        if (!matchProp && !matchTenant && !matchTitle) return false;
      }
      return true;
    });
  }, [payments, paymentStatusFilter, paymentSearchQuery]);

  // Managed Properties State
  const [managedProperties, setManagedProperties] = useState<AgencyManagedProperty[]>([]);
  const [loadingProperties, setLoadingProperties] = useState<boolean>(false);
  const [propOccupancyFilter, setPropOccupancyFilter] = useState<"all" | "occupied" | "vacant">("all");
  const [propSearchQuery, setPropSearchQuery] = useState<string>("");
  const managedPropertyStats = useMemo(() => {
    const total = managedProperties.length;
    const occupied = managedProperties.filter((p) => p.is_occupied).length;
    const vacant = total - occupied;
    const occupancyRate = total > 0 ? Math.round((occupied / total) * 100) : 0;
    return { total, occupied, vacant, occupancyRate };
  }, [managedProperties]);

  const filteredManagedProperties = useMemo(() => {
    return managedProperties.filter((p) => {
      if (propOccupancyFilter === "occupied" && !p.is_occupied) return false;
      if (propOccupancyFilter === "vacant" && p.is_occupied) return false;
      if (propSearchQuery.trim()) {
        const q = propSearchQuery.toLowerCase().trim();
        const matchTitle = (p.title || "").toLowerCase().includes(q);
        const matchAddress = (p.address || "").toLowerCase().includes(q) || (p.city || "").toLowerCase().includes(q);
        const matchLandlord = (p.landlord_name || "").toLowerCase().includes(q) || (p.landlord_phone || "").toLowerCase().includes(q);
        const matchTenant = (p.active_tenant_name || "").toLowerCase().includes(q);
        if (!matchTitle && !matchAddress && !matchLandlord && !matchTenant) return false;
      }
      return true;
    });
  }, [managedProperties, propOccupancyFilter, propSearchQuery]);

  // Contracts State
  const [contracts, setContracts] = useState<AgencyContract[]>([]);
  const [loadingContracts, setLoadingContracts] = useState<boolean>(false);
  const [contractStatusFilter, setContractStatusFilter] = useState<"all" | "expiring" | "active" | "expired">("all");
  const [contractSearchQuery, setContractSearchQuery] = useState<string>("");

  const contractStats = useMemo(() => {
    const now = new Date();
    const in30Days = new Date(Date.now() + 30 * 86400 * 1000);
    let active = 0;
    let expiringSoon = 0;
    let expired = 0;
    let totalDeposit = 0;

    for (const c of contracts) {
      totalDeposit += c.deposit_amount || 0;
      const end = new Date(c.end_date);
      if (c.status === "expired" || end < now) {
        expired += 1;
      } else if (c.status === "active") {
        active += 1;
        if (end <= in30Days) {
          expiringSoon += 1;
        }
      }
    }
    return { active, expiringSoon, expired, totalDeposit, total: contracts.length };
  }, [contracts]);

  // ICU / Multi-form pluralization for seed preview counts (1 / 2-4 / 5+)
  const pluralForms = useMemo(() => {
    const formatPluralItem = (count: number, type: "ads" | "tenants" | "unpaid") => {
      const intlLocale =
        lang === "SR_LAT"
          ? "sr-Latn"
          : lang === "SR_CYR"
            ? "sr-Cyrl"
            : lang === "EN"
              ? "en"
              : lang === "RU"
                ? "ru"
                : "tr";

      let rule: Intl.LDMLPluralRule = "other";
      try {
        const pr = new Intl.PluralRules(intlLocale);
        rule = pr.select(count);
      } catch {
        rule = count === 1 ? "one" : "other";
      }

      const dict = {
        ads: {
          SR_LAT: { one: "demo oglas", few: "demo oglasa", many: "demo oglasa", other: "demo oglasa" },
          SR_CYR: { one: "демо оглас", few: "демо огласа", many: "демо огласа", other: "демо огласа" },
          EN: { one: "demo listing", other: "demo listings" },
          RU: { one: "демо-объявление", few: "демо-объявления", many: "демо-объявлений", other: "демо-объявлений" },
          TR: { other: "demo ilan" },
        },
        tenants: {
          SR_LAT: { one: "zakupac", few: "zakupca", many: "zakupaca", other: "zakupaca" },
          SR_CYR: { one: "закупац", few: "закупца", many: "закупаца", other: "закупаца" },
          EN: { one: "tenant", other: "tenants" },
          RU: { one: "арендатор", few: "арендатора", many: "арендаторов", other: "арендаторов" },
          TR: { other: "kiracı" },
        },
        unpaid: {
          SR_LAT: { one: "neplaćeni račun", few: "neplaćena računa", many: "neplaćenih računa", other: "neplaćenih računa" },
          SR_CYR: { one: "неплаћени рачун", few: "неплаћена рачуна", many: "неплаћених рачуна", other: "неплаћених рачуна" },
          EN: { one: "unpaid bill", other: "unpaid bills" },
          RU: { one: "неоплаченный счет", few: "неоплаченных счета", many: "неоплаченных счетов", other: "неоплаченных счетов" },
          TR: { other: "ödenmemiş fatura" },
        },
      };

      const forms = ((dict as any)[type]?.[lang] || (dict as any)[type]?.["EN"]) as Record<string, string>;
      const word = forms[rule] || forms["other"] || forms["one"] || "";
      return `${count} ${word}`;
    };

    const adsCount = managedProperties.length > 0 ? managedProperties.length : 10;
    const tenantsCount = contracts.length > 0 ? contracts.length : 10;
    const unpaidCount =
      payments.filter((p) => p.status === "pending" || p.status === "overdue").length || 3;

    return {
      ads: formatPluralItem(adsCount, "ads"),
      tenants: formatPluralItem(tenantsCount, "tenants"),
      unpaid: formatPluralItem(unpaidCount, "unpaid"),
    };
  }, [lang, managedProperties.length, contracts.length, payments]);

  const filteredContracts = useMemo(() => {
    const now = new Date();
    const in30Days = new Date(Date.now() + 30 * 86400 * 1000);
    return contracts.filter((c) => {
      const end = new Date(c.end_date);
      const isExpired = c.status === "expired" || end < now;
      const isExpiringSoon = c.status === "active" && end >= now && end <= in30Days;
      const isActive = c.status === "active" && !isExpired;

      if (contractStatusFilter === "expiring" && !isExpiringSoon) return false;
      if (contractStatusFilter === "active" && !isActive) return false;
      if (contractStatusFilter === "expired" && !isExpired) return false;

      if (contractSearchQuery.trim()) {
        const q = contractSearchQuery.toLowerCase().trim();
        const matchTenant =
          (c.tenant_name || "").toLowerCase().includes(q) ||
          (c.tenant_phone || "").toLowerCase().includes(q) ||
          (c.tenant_id_number || "").toLowerCase().includes(q);
        const matchProp =
          (c.property_title || "").toLowerCase().includes(q) ||
          (c.property_address || "").toLowerCase().includes(q);
        if (!matchTenant && !matchProp) return false;
      }
      return true;
    });
  }, [contracts, contractStatusFilter, contractSearchQuery]);

  // Maintenance State
  const [maintenanceRequests, setMaintenanceRequests] = useState<AgencyMaintenanceRequest[]>([]);
  const [loadingMaintenance, setLoadingMaintenance] = useState<boolean>(false);
  const [selectedMaintRequest, setSelectedMaintRequest] = useState<AgencyMaintenanceRequest | null>(null);
  const [maintStatusFilter, setMaintStatusFilter] = useState<AgencyMaintStatusFilter>("all");
  const [maintSearchQuery, setMaintSearchQuery] = useState<string>("");
  const [updatingMaintId, setUpdatingMaintId] = useState<string | null>(null);

  // New Maintenance Request Modal State
  const [isNewMaintModalOpen, setIsNewMaintModalOpen] = useState<boolean>(false);
  const [newMaintPropId, setNewMaintPropId] = useState<string>("");
  const [newMaintTitle, setNewMaintTitle] = useState<string>("");
  const [newMaintCategory, setNewMaintCategory] = useState<AgencyMaintenanceRequest["category"]>("plumbing");
  const [newMaintPriority, setNewMaintPriority] = useState<AgencyMaintenanceRequest["priority"]>("normal");
  const [newMaintDescription, setNewMaintDescription] = useState<string>("");
  const [newMaintHasExpense, setNewMaintHasExpense] = useState<boolean>(false);
  const [newMaintCost, setNewMaintCost] = useState<string>("");
  const [newMaintCurrency, setNewMaintCurrency] = useState<string>("EUR");
  const [newMaintPaymentDate, setNewMaintPaymentDate] = useState<string>(() => new Date().toISOString().split("T")[0]);
  const [newMaintPayer, setNewMaintPayer] = useState<"landlord" | "tenant" | "agency">("agency");
  const [newMaintIntent, setNewMaintIntent] = useState<string>("fixture_landlord");
  const [newMaintInvoiceFile, setNewMaintInvoiceFile] = useState<File | null>(null);
  const [creatingMaint, setCreatingMaint] = useState<boolean>(false);

  const maintenanceStats = useMemo(() => {
    let openCount = 0;
    let inProgressCount = 0;
    let resolvedCount = 0;
    let urgentCount = 0;
    let totalCost = 0;

    for (const m of maintenanceRequests) {
      const isResolved = m.status === "resolved" || m.status === "closed";
      const isInProgress = m.status === "in_progress";
      const isOpen = m.status === "open" || m.status === "investigating" || m.status === "pending" || (!isResolved && !isInProgress);

      if (isResolved) {
        resolvedCount += 1;
      } else if (isInProgress) {
        inProgressCount += 1;
      } else if (isOpen) {
        openCount += 1;
      }
      if ((isOpen || isInProgress) && (m.priority === "urgent" || m.priority === "high")) {
        urgentCount += 1;
      }
      if (m.cost_amount) {
        totalCost += Number(m.cost_amount);
      }
    }
    return {
      openCount,
      inProgressCount,
      resolvedCount,
      urgentCount,
      totalCost,
      total: maintenanceRequests.length,
    };
  }, [maintenanceRequests]);

  const pmPendingActionsCount = useMemo(() => {
    return (
      paymentStats.awaitingApproval +
      maintenanceStats.openCount +
      contractStats.expiringSoon +
      managedPropertyStats.vacant
    );
  }, [paymentStats, maintenanceStats, contractStats, managedPropertyStats]);

  const filteredMaintenanceRequests = useMemo(() => {
    return maintenanceRequests.filter((m) => {
      const isResolved = m.status === "resolved" || m.status === "closed";
      const isInProgress = m.status === "in_progress";
      const isOpen = m.status === "open" || m.status === "investigating" || m.status === "pending" || (!isResolved && !isInProgress);

      if (maintStatusFilter === "open" && !isOpen) {
        return false;
      }
      if (maintStatusFilter === "in_progress" && !isInProgress) {
        return false;
      }
      if (maintStatusFilter === "pending_approval") {
        const hasExpense =
          m.cost_amount !== null &&
          m.cost_amount !== undefined &&
          Number(m.cost_amount) > 0;
        const pStatus = m.payment_status || "pending_review";
        if (
          !hasExpense ||
          !(
            pStatus === "pending_review" ||
            pStatus === "pending_payment" ||
            pStatus === "pending_agency_approval" ||
            pStatus === "pending_opposite_approval" ||
            pStatus === "pending_landlord_approval" ||
            pStatus === "pending_tenant_approval"
          )
        ) {
          return false;
        }
      }
      if (maintStatusFilter === "resolved" && !isResolved) {
        return false;
      }

      if (maintSearchQuery.trim()) {
        const q = maintSearchQuery.toLowerCase().trim();
        const matchTicket = (m.ticket_number || "").toLowerCase().includes(q);
        const matchTitle = (m.title || "").toLowerCase().includes(q);
        const matchProp = (m.property_title || "").toLowerCase().includes(q) || (m.property_address || "").toLowerCase().includes(q);
        const matchReporter = (m.reporter_name || "").toLowerCase().includes(q);
        if (!matchTicket && !matchTitle && !matchProp && !matchReporter) return false;
      }
      return true;
    });
  }, [maintenanceRequests, maintStatusFilter, maintSearchQuery]);

  // Leads & CRM State
  const demoBtnRef = useRef<HTMLButtonElement | null>(null);
  const [leads, setListingsLeads] = useState<AgencyLead[]>([]);

  useEffect(() => {
    if (userId) return;
    let idleTimer: ReturnType<typeof setTimeout> | null = null;
    const handleWindowMouseMove = (e: MouseEvent) => {
      const btn = demoBtnRef.current;
      if (!btn) return;
      const vw = Math.max(1, window.innerWidth);
      const vh = Math.max(1, window.innerHeight);
      const pctX = Math.max(0, Math.min(100, (e.clientX / vw) * 100));
      const pctY = Math.max(0, Math.min(100, (e.clientY / vh) * 100));
      btn.style.setProperty("--demo-mx", `${pctX.toFixed(1)}%`);
      btn.style.setProperty("--demo-my", `${pctY.toFixed(1)}%`);
      btn.style.setProperty("--demo-mx-pct", `${pctX.toFixed(1)}%`);
      btn.style.setProperty("--demo-glow", "1");
      if (idleTimer) clearTimeout(idleTimer);
      idleTimer = setTimeout(() => {
        if (demoBtnRef.current) {
          demoBtnRef.current.style.setProperty("--demo-glow", "0.25");
        }
      }, 450);
    };
    window.addEventListener("mousemove", handleWindowMouseMove, { passive: true });
    return () => {
      window.removeEventListener("mousemove", handleWindowMouseMove);
      if (idleTimer) clearTimeout(idleTimer);
    };
  }, [userId]);
  const [leadPoolFilter, setLeadPoolFilter] = useState<"all" | LeadType>("all");
  const [leadStatusFilter, setLeadStatusFilter] = useState<string>("all");
  const [leadSearchQuery, setLeadSearchQuery] = useState<string>("");
  const [convertingLeadId, setConvertingLeadId] = useState<string | null>(null);
  const [newCommentText, setNewCommentText] = useState<Record<string, string>>({});

  const leadPoolCounts = useMemo(() => {
    return {
      all: leads.length,
      owner_consignment: leads.filter((l) => l.lead_type === "owner_consignment").length,
      viewing_request: leads.filter((l) => l.lead_type === "viewing_request").length,
      general_inquiry: leads.filter((l) => l.lead_type === "general_inquiry").length,
    };
  }, [leads]);

  const newLeadsCount = useMemo(
    () => leads.filter((l) => l.status === "new").length,
    [leads]
  );

  const filteredLeads = useMemo(() => {
    return leads.filter((lead) => {
      if (leadPoolFilter !== "all" && lead.lead_type !== leadPoolFilter) return false;
      if (leadStatusFilter !== "all" && lead.status !== leadStatusFilter) return false;
      if (leadSearchQuery.trim()) {
        const q = leadSearchQuery.toLowerCase().trim();
        const matchName = (lead.client_name || "").toLowerCase().includes(q);
        const matchPhone = (lead.client_phone || "").toLowerCase().includes(q);
        const matchEmail = (lead.client_email || "").toLowerCase().includes(q);
        const matchLoc = (lead.location || "").toLowerCase().includes(q);
        const matchNotes = (lead.notes || "").toLowerCase().includes(q);
        const matchListing = (lead.listing_title || "").toLowerCase().includes(q);
        const matchComments = (lead.comments || []).some((c) =>
          c.text.toLowerCase().includes(q) || c.author_name.toLowerCase().includes(q)
        );
        if (
          !matchName &&
          !matchPhone &&
          !matchEmail &&
          !matchLoc &&
          !matchNotes &&
          !matchListing &&
          !matchComments
        ) {
          return false;
        }
      }
      return true;
    });
  }, [leads, leadPoolFilter, leadStatusFilter, leadSearchQuery]);

  const filteredListings = useMemo(() => {
    return listings.filter((item) => {
      if (portfolioTxFilter !== "all" && item.transaction_type !== portfolioTxFilter) {
        return false;
      }
      if (portfolioStatusFilter === "live" && !item.is_published) {
        return false;
      }
      if (portfolioStatusFilter === "paused" && item.is_published) {
        return false;
      }
      if (portfolioSearch.trim()) {
        const q = portfolioSearch.toLowerCase().trim();
        const matchTitle = (item.title || "").toLowerCase().includes(q);
        const matchRef = (item.external_ref || "").toLowerCase().includes(q);
        const matchCity = (item.city || "").toLowerCase().includes(q);
        const matchMuni = (item.municipality || "").toLowerCase().includes(q);
        const matchNeigh = (item.neighborhood || "").toLowerCase().includes(q);
        const matchAddr = (item.address || "").toLowerCase().includes(q);
        if (!matchTitle && !matchRef && !matchCity && !matchMuni && !matchNeigh && !matchAddr) {
          return false;
        }
      }
      return true;
    });
  }, [listings, portfolioTxFilter, portfolioStatusFilter, portfolioSearch]);

  // Form State
  const [editingId, setEditingId] = useState<string | null>(null);
  const [transactionType, setTransactionType] = useState<string>("izdavanje");
  const [propertyType, setPropertyType] = useState<string>("apartment");
  const [externalRef, setExternalRef] = useState<string>("");
  const [title, setTitle] = useState<string>("");
  const [description, setDescription] = useState<string>("");
  const [price, setPrice] = useState<string>("");
  const [currency, setCurrency] = useState<string>("EUR");
  const [areaSqm, setAreaSqm] = useState<string>("");
  const [roomCount, setRoomCount] = useState<string>("2.0");
  const [floor, setFloor] = useState<string>("2");
  const [totalFloors, setTotalFloors] = useState<string>("5");
  const [heatingType, setHeatingType] = useState<string>("cg");
  const [condition, setCondition] = useState<string>("novogradnja");
  const [furnishing, setFurnishing] = useState<string>("furnished");
  const [city, setCity] = useState<string>("Beograd");
  const [municipality, setMunicipality] = useState<string>("Vračar");
  const [neighborhood, setNeighborhood] = useState<string>("Hram Svetog Save");
  const [address, setAddress] = useState<string>("");
  const [selectedAmenities, setSelectedAmenities] = useState<string[]>(["elevator", "balcony"]);
  const [isPublished, setIsPublished] = useState<boolean>(true);
  const [images, setImages] = useState<ListingImageRow[]>([]);
  const [manualImageUrl, setManualImageUrl] = useState<string>("");
  const [uploadingPhotos, setUploadingPhotos] = useState<boolean>(false);
  const [isDraggingOver, setIsDraggingOver] = useState<boolean>(false);
  const photoInputRef = React.useRef<HTMLInputElement | null>(null);
  const [savingListing, setSavingListing] = useState<boolean>(false);

  async function verifyAgencyRole(uid: string, userMetadata?: any): Promise<boolean> {
    try {
      const { data: prof } = await supabase
        .from("profiles")
        .select("role, active_role")
        .eq("id", uid)
        .maybeSingle();

      if (prof?.role === "agency" || prof?.active_role === "agency") {
        return true;
      }
    } catch (err) {
      console.warn("Could not check profile role in verifyAgencyRole:", err);
    }

    if (userMetadata?.role === "agency") {
      return true;
    }

    return false;
  }

  async function resolveAgencyAccess(
    uid: string,
    userMetadata?: any
  ): Promise<{
    allowed: boolean;
    effectiveAgencyId: string | null;
    role: "agency_admin" | "agency_operation";
  }> {
    try {
      const { data: membership } = await supabase
        .from("agency_members")
        .select("agency_id, member_role, status")
        .eq("user_id", uid)
        .eq("status", "active")
        .order("created_at", { ascending: true })
        .limit(1)
        .maybeSingle();

      if (membership?.agency_id) {
        return {
          allowed: true,
          effectiveAgencyId: membership.agency_id,
          role: "agency_operation",
        };
      }
    } catch (err) {
      console.warn("Could not check agency_members in resolveAgencyAccess:", err);
    }

    const isAgency = await verifyAgencyRole(uid, userMetadata);
    if (isAgency) {
      return {
        allowed: true,
        effectiveAgencyId: uid,
        role: "agency_admin",
      };
    }

    return {
      allowed: false,
      effectiveAgencyId: null,
      role: "agency_admin",
    };
  }

  async function loadAgencyTasks(effectiveAgencyId: string) {
    if (!effectiveAgencyId || effectiveAgencyId === "demo") {
      setAgencyTasks([]);
      return;
    }
    setLoadingTasks(true);
    try {
      const { data, error } = await supabase
        .from("agency_tasks")
        .select("*")
        .eq("agency_id", effectiveAgencyId)
        .order("created_at", { ascending: false });
      if (!error && Array.isArray(data)) {
        setAgencyTasks(data as AgencyTask[]);
      }
    } catch (err) {
      console.warn("Could not load agency_tasks:", err);
    } finally {
      setLoadingTasks(false);
    }
  }

  async function loadTeamAssignees(effectiveAgencyId: string, authUser?: any) {
    if (!effectiveAgencyId || effectiveAgencyId === "demo") {
      setTeamAssignees([
        {
          id: "demo",
          name: agencyName || "Demo Admin",
          email: agencyEmail || "demo@stanomer.online",
          role: "agency_admin",
        },
      ]);
      return;
    }
    try {
      const list: AgencyAssigneeOption[] = [];
      const { data: adminProf } = await supabase
        .from("profiles")
        .select("id, full_name, company_name, email")
        .eq("id", effectiveAgencyId)
        .maybeSingle();

      list.push({
        id: effectiveAgencyId,
        name: adminProf?.full_name || adminProf?.company_name || adminProf?.email || "Agency Admin",
        email: adminProf?.email || "",
        role: "agency_admin",
      });

      const { data: members } = await supabase
        .from("agency_members")
        .select("user_id, full_name, email, status")
        .eq("agency_id", effectiveAgencyId)
        .eq("status", "active")
        .order("created_at", { ascending: true });

      if (Array.isArray(members)) {
        for (const m of members) {
          if (m.user_id && !list.some((x) => x.id === m.user_id)) {
            list.push({
              id: m.user_id,
              name: m.full_name || m.email || "Operations",
              email: m.email || "",
              role: "agency_operation",
            });
          }
        }
      }

      if (authUser?.id && !list.some((x) => x.id === authUser.id)) {
        list.push({
          id: authUser.id,
          name: authUser.user_metadata?.full_name || authUser.email || "User",
          email: authUser.email || "",
          role: authUser.id === effectiveAgencyId ? "agency_admin" : "agency_operation",
        });
      }

      setTeamAssignees(list);
    } catch (err) {
      console.warn("Could not load team assignees:", err);
    }
  }

  const handleOpenCreateTask = (prefill?: AgencyTaskPrefill) => {
    setEditingTask(null);
    setTaskPrefill(prefill || { source_type: "manual" });
    setIsTaskModalOpen(true);
  };

  const handleSaveTask = async (payload: {
    id?: string;
    title: string;
    description: string | null;
    status: AgencyTaskStatus;
    priority: AgencyTaskPriority;
    due_date: string | null;
    source_type: AgencyTaskSourceType;
    property_id: string | null;
    listing_id: string | null;
    lead_id: string | null;
    maintenance_request_id: string | null;
    assigned_to: string | null;
  }) => {
    const actorId = currentUser?.id || userId || "demo";
    const effectiveAgencyId = userId || "demo";
    const completedAt = payload.status === "done" ? new Date().toISOString() : null;

    if (isDemoMode && (!userId || userId === "demo")) {
      if (payload.id) {
        setAgencyTasks((prev) =>
          prev.map((tk) =>
            tk.id === payload.id
              ? { ...tk, ...payload, completed_at: completedAt, updated_at: new Date().toISOString() }
              : tk
          )
        );
      } else {
        const newDemo: AgencyTask = {
          id: `demo-task-${Date.now()}`,
          agency_id: "demo",
          ...payload,
          created_by: actorId,
          completed_at: completedAt,
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
        };
        setAgencyTasks((prev) => [newDemo, ...prev]);
      }
      return;
    }

    if (payload.id) {
      const { data, error } = await supabase
        .from("agency_tasks")
        .update({
          title: payload.title,
          description: payload.description,
          status: payload.status,
          priority: payload.priority,
          due_date: payload.due_date,
          source_type: payload.source_type,
          property_id: payload.property_id,
          listing_id: payload.listing_id,
          lead_id: payload.lead_id,
          maintenance_request_id: payload.maintenance_request_id,
          assigned_to: payload.assigned_to,
          completed_at: completedAt,
          updated_at: new Date().toISOString(),
        })
        .eq("id", payload.id)
        .select("*")
        .single();
      if (error) throw error;
      if (data) {
        setAgencyTasks((prev) => prev.map((tk) => (tk.id === payload.id ? (data as AgencyTask) : tk)));
      }
    } else {
      const { data, error } = await supabase
        .from("agency_tasks")
        .insert({
          agency_id: effectiveAgencyId,
          title: payload.title,
          description: payload.description,
          status: payload.status,
          priority: payload.priority,
          due_date: payload.due_date,
          source_type: payload.source_type,
          property_id: payload.property_id,
          listing_id: payload.listing_id,
          lead_id: payload.lead_id,
          maintenance_request_id: payload.maintenance_request_id,
          assigned_to: payload.assigned_to,
          created_by: actorId,
          completed_at: completedAt,
        })
        .select("*")
        .single();
      if (error) throw error;
      if (data) {
        setAgencyTasks((prev) => [data as AgencyTask, ...prev]);
      }
    }
  };

  const handleQuickTaskStatus = async (task: AgencyTask, status: AgencyTaskStatus) => {
    const completedAt = status === "done" ? new Date().toISOString() : null;
    setAgencyTasks((prev) =>
      prev.map((tk) => (tk.id === task.id ? { ...tk, status, completed_at: completedAt } : tk))
    );
    if (userId && userId !== "demo") {
      await supabase
        .from("agency_tasks")
        .update({ status, completed_at: completedAt, updated_at: new Date().toISOString() })
        .eq("id", task.id);
    }
  };

  const handleQuickTaskAssign = async (task: AgencyTask, assigneeId: string | null) => {
    setAgencyTasks((prev) =>
      prev.map((tk) => (tk.id === task.id ? { ...tk, assigned_to: assigneeId } : tk))
    );
    if (userId && userId !== "demo") {
      await supabase
        .from("agency_tasks")
        .update({ assigned_to: assigneeId, updated_at: new Date().toISOString() })
        .eq("id", task.id);
    }
  };

  const handleDeleteTask = async (task: AgencyTask) => {
    if (typeof window !== "undefined" && !window.confirm(t("agency_tasks_confirm_delete"))) return;
    setAgencyTasks((prev) => prev.filter((tk) => tk.id !== task.id));
    if (userId && userId !== "demo") {
      await supabase.from("agency_tasks").delete().eq("id", task.id);
    }
  };

  const handleUpdateTaskComments = async (task: AgencyTask, comments: import("./types").AgencyTaskComment[]) => {
    setAgencyTasks((prev) =>
      prev.map((tk) => (tk.id === task.id ? { ...tk, comments } : tk))
    );
    if (userId && userId !== "demo") {
      await supabase
        .from("agency_tasks")
        .update({ comments, updated_at: new Date().toISOString() })
        .eq("id", task.id);
    }
  };

  async function loadAgencyProfile(uid: string, fallbackEmail?: string) {
    const { data: prof } = await supabase
      .from("profiles")
      .select("company_name, full_name, phone_number, email, website_url, logo_url, color_scheme, active_modules, is_demo, demo_expires_at")
      .eq("id", uid)
      .maybeSingle();

    if (prof?.is_demo) {
      setIsDemoMode(true);
      setIsDemoVerified(true);
      if (prof.demo_expires_at) {
        setDemoExpiresAt(prof.demo_expires_at);
      }
    }

    let activeMods = prof?.active_modules;
    if (typeof window !== "undefined") {
      try {
        const s = localStorage.getItem("stanomer_agency_demo");
        if (s) {
          const p = JSON.parse(s);
          if (p.active_modules && Array.isArray(p.active_modules) && p.active_modules.length > 0) {
            activeMods = Array.from(new Set([...(activeMods || []), ...p.active_modules]));
          }
        }
      } catch { }
    }

    if (activeMods && Array.isArray(activeMods) && activeMods.length > 0) {
      setActiveModules(activeMods);
      if (activeMods.includes("portfolio_distribution") && activeMods.includes("property_lease_management")) {
        setDemoFocus("both");
      } else if (activeMods.includes("portfolio_distribution")) {
        setDemoFocus("presales");
      } else if (activeMods.includes("property_lease_management")) {
        setDemoFocus("aftersales");
      }
    }

    const resolvedName =
      prof?.company_name || prof?.full_name || fallbackEmail || "Partner Agencija";
    setAgencyName(resolvedName);
    setAgencyPhone(prof?.phone_number || "");
    setAgencyEmail(prof?.email || fallbackEmail || "");
    setAgencyWebsite(prof?.website_url || "");
    setAgencyLogoUrl(prof?.logo_url || "");
    const scheme = (prof?.color_scheme as Record<string, any> | null) || {};
    const validTemplates: ShowcaseTemplate[] = [
      "stanomer_modern",
      "quiet_luxury",
      "minimal_light",
      "kolm_dark",
      "lumira",
      "aldervik",
      "sage",
      "onyx_dark",
    ];
    if (validTemplates.includes(scheme.template)) {
      setShowcaseTemplate(scheme.template);
    }
    const validPalettes: ShowcasePalette[] = [
      "royal_blue",
      "champagne_gold",
      "emerald_prestige",
      "burgundy_classic",
      "kolm_mint",
      "lumira_coral",
      "aldervik_amber",
      "sage_terracotta",
      "onyx_brass",
    ];
    if (validPalettes.includes(scheme.palette)) {
      setShowcasePalette(scheme.palette);
    }
    if (
      scheme.radius === "sharp" ||
      scheme.radius === "subtle" ||
      scheme.radius === "rounded" ||
      scheme.radius === "pill"
    ) {
      setShowcaseRadius(scheme.radius);
    }
    if (scheme.slug) {
      setAgencySlug(scheme.slug);
    } else if (prof?.company_name) {
      setAgencySlug(
        prof.company_name
          .toLowerCase()
          .replace(/[^a-z0-9]/g, "-")
          .replace(/--+/g, "-")
      );
    }
    if (
      scheme.contactChannels === "both" ||
      scheme.contactChannels === "whatsapp" ||
      scheme.contactChannels === "viber" ||
      scheme.contactChannels === "none"
    ) {
      setContactChannels(scheme.contactChannels);
    }
    if (scheme.custom_domain) setAgencyCustomDomain(scheme.custom_domain);
    if (scheme.city) setAgencyCity(scheme.city);
    if (scheme.address) setAgencyAddress(scheme.address);
    const validLanguages: Language[] = ["SR_LAT", "SR_CYR", "EN", "RU", "TR"];
    if (Array.isArray(scheme.languages)) {
      const filtered = scheme.languages.filter((l: any) => validLanguages.includes(l));
      if (filtered.length > 0) setShowcaseLanguages(filtered);
    }
    const validCurrencies: ShowcaseCurrency[] = ["EUR", "RSD", "USD"];
    if (Array.isArray(scheme.currencies)) {
      const filtered = scheme.currencies.filter((c: any) => validCurrencies.includes(c));
      if (filtered.length > 0) setShowcaseCurrencies(filtered);
    }
    if (validCurrencies.includes(scheme.default_currency as any)) {
      setShowcaseDefaultCurrency(scheme.default_currency as ShowcaseCurrency);
    }
    return Boolean(prof?.is_demo);
  }

  // Responsive sidebar collapse:
  // - >= 1280px (xl): Expanded (w-64) by default
  // - 1024px <= width < 1280px (lg): Collapsed (w-[68px]) by default to maximize workspace
  // - < 1024px: Mobile navigation
  // User can manually toggle at any time; manual toggle persists while staying within the same breakpoint.
  const currentBreakpointRef = useRef<"mobile" | "lg" | "xl">("xl");
  const userManualOverrideRef = useRef<{ breakpoint: string; collapsed: boolean } | null>(null);

  useEffect(() => {
    if (typeof window === "undefined") return;

    // Remove legacy single-boolean localStorage that broke responsive defaults
    try {
      localStorage.removeItem("stanomer_agency_sidebar_collapsed");
    } catch { }

    const evaluateBreakpoint = () => {
      const width = window.innerWidth;
      const bp: "mobile" | "lg" | "xl" = width < 1024 ? "mobile" : width < 1280 ? "lg" : "xl";
      currentBreakpointRef.current = bp;

      if (bp === "mobile") {
        return;
      }

      // If user explicitly toggled on this specific breakpoint in this session, respect it
      if (userManualOverrideRef.current && userManualOverrideRef.current.breakpoint === bp) {
        setIsSidebarCollapsed(userManualOverrideRef.current.collapsed);
        return;
      }

      // Responsive defaults:
      // 1024px <= width < 1280px (lg): Collapsed (true)
      // width >= 1280px (xl): Expanded (false)
      if (bp === "lg") {
        setIsSidebarCollapsed(true);
      } else if (bp === "xl") {
        setIsSidebarCollapsed(false);
      }
    };

    evaluateBreakpoint();
    window.addEventListener("resize", evaluateBreakpoint);
    return () => window.removeEventListener("resize", evaluateBreakpoint);
  }, []);

  const toggleSidebar = () => {
    setIsSidebarCollapsed((prev) => {
      const next = !prev;
      userManualOverrideRef.current = {
        breakpoint: currentBreakpointRef.current,
        collapsed: next,
      };
      return next;
    });
  };

  // Keep showcase theme & template in localStorage for instant preview
  useEffect(() => {
    if (typeof window === "undefined") return;
    try {
      localStorage.setItem(
        "stanomer_showcase_theme",
        JSON.stringify({
          userId: userId && userId !== "demo" ? userId : null,
          isRealAgency: Boolean(userId && userId !== "demo"),
          template: showcaseTemplate,
          palette: showcasePalette,
          radius: showcaseRadius,
          slug: agencySlug.trim(),
          custom_domain: agencyCustomDomain.trim().toLowerCase(),
          contactChannels,
          agencyName: agencyName.trim(),
          agencyPhone: agencyPhone.trim(),
          agencyEmail: agencyEmail.trim(),
          agencyWebsite: agencyWebsite.trim(),
          agencyLogoUrl: agencyLogoUrl.trim(),
          agencyCity: agencyCity.trim(),
          agencyAddress: agencyAddress.trim(),
          languages: showcaseLanguages,
          currencies: showcaseCurrencies,
          default_currency: showcaseDefaultCurrency,
        })
      );
    } catch {
      // Ignore storage error
    }
  }, [
    userId,
    showcaseTemplate,
    showcasePalette,
    showcaseRadius,
    agencySlug,
    agencyCustomDomain,
    contactChannels,
    agencyName,
    agencyPhone,
    agencyEmail,
    agencyWebsite,
    agencyLogoUrl,
    agencyCity,
    agencyAddress,
    showcaseLanguages,
    showcaseCurrencies,
    showcaseDefaultCurrency,
  ]);

  // Synchronize unauthenticated demo listings to localStorage for instant showcase preview at /agencija/demo
  useEffect(() => {
    if (
      isDemoMode &&
      (!userId || userId === "demo") &&
      typeof window !== "undefined" &&
      listings.length > 0
    ) {
      try {
        localStorage.setItem(
          "stanomer_agency_listings_demo",
          JSON.stringify(listings)
        );
      } catch { }
    }
  }, [isDemoMode, userId, listings]);

  // Synchronize leads from localStorage in real time (e.g. appointment or consignment from showcase)
  useEffect(() => {
    if (typeof window === "undefined") return;

    const reloadLeads = () => {
      loadAgencyLeads(userId || "demo");
    };

    let bc: BroadcastChannel | null = null;
    try {
      bc = new BroadcastChannel("stanomer_leads_sync");
      bc.onmessage = () => {
        reloadLeads();
      };
    } catch { }

    const handleStorage = (e: StorageEvent) => {
      if (
        !e.key ||
        e.key.startsWith("stanomer_agency_leads_") ||
        e.key === "stanomer_agency_listings_demo"
      ) {
        reloadLeads();
        if (
          e.key === "stanomer_agency_listings_demo" &&
          e.newValue &&
          (!userId || userId === "demo")
        ) {
          try {
            const parsed = JSON.parse(e.newValue);
            if (Array.isArray(parsed) && parsed.length > 0) {
              setListings(parsed);
            }
          } catch { }
        }
      }
    };

    const handleCustomLead = () => {
      reloadLeads();
    };

    const handleFocus = () => {
      reloadLeads();
    };

    const handleVisibility = () => {
      if (document.visibilityState === "visible") {
        reloadLeads();
      }
    };

    window.addEventListener("storage", handleStorage);
    window.addEventListener("stanomer_lead_created", handleCustomLead);
    window.addEventListener("focus", handleFocus);
    document.addEventListener("visibilitychange", handleVisibility);

    const interval = setInterval(() => {
      if (activeTab === "leads") {
        reloadLeads();
      }
    }, 2500);

    return () => {
      if (bc) bc.close();
      window.removeEventListener("storage", handleStorage);
      window.removeEventListener("stanomer_lead_created", handleCustomLead);
      window.removeEventListener("focus", handleFocus);
      document.removeEventListener("visibilitychange", handleVisibility);
      clearInterval(interval);
    };
  }, [userId, agencySlug, activeTab]);

  // Refresh leads whenever entering the CRM tab
  useEffect(() => {
    if (activeTab === "leads") {
      loadAgencyLeads(userId || "demo");
    }
  }, [activeTab, userId, agencySlug]);

  // Refresh listings whenever entering the Portfolio (listings) tab
  useEffect(() => {
    if (activeTab === "listings") {
      if (userId && userId !== "demo") {
        fetchAgencyListings(userId);
      } else if (isDemoMode && typeof window !== "undefined") {
        try {
          const stored = localStorage.getItem("stanomer_agency_listings_demo");
          if (stored) {
            const parsed = JSON.parse(stored);
            if (Array.isArray(parsed) && parsed.length > 0) {
              setListings(parsed);
            }
          }
        } catch { }
      }
    }
  }, [activeTab, isDemoMode, userId]);

  // Check active session on mount (including magic link ?demo_token=xyz & recovery)
  useEffect(() => {
    let mounted = true;
    async function checkSession() {
      try {
        // 1. Check if ?demo_token=xyz or ?tab=xyz in URL
        if (typeof window !== "undefined") {
          const searchParams = new URLSearchParams(window.location.search);
          const urlTab = searchParams.get("tab") as AgencyPanelTab | null;
          if (
            urlTab &&
            [
              "welcome",
              "listings",
              "leads",
              "form",
              "xml",
              "settings",
              "payments",
              "pm_dashboard",
              "managed_properties",
              "contracts",
              "maintenance",
              "account_settings",
            ].includes(urlTab)
          ) {
            setActiveTab(urlTab);
          }

          const resetToken = searchParams.get("reset_token");
          const resetEmailParam = searchParams.get("reset_email");
          if (resetToken) {
            setAuthTab("reset");
            setResetStep(2);
            setResetCode(resetToken);
            if (resetEmailParam) setAuthEmail(resetEmailParam);
            try {
              const cleanUrl = new URL(window.location.href);
              cleanUrl.searchParams.delete("reset_token");
              cleanUrl.searchParams.delete("reset_email");
              window.history.replaceState({}, "", cleanUrl.toString());
            } catch { }
          }

          const demoToken = searchParams.get("demo_token");
          const isVerifiedDemoRedirect = searchParams.get("verified_demo") === "1";
          if (demoToken && !isVerifiedDemoRedirect) {
            try {
              const res = await fetch(`/api/agency-demo?token=${encodeURIComponent(demoToken)}`);
              const data = await res.json();
              if (data.valid && data.session && mounted) {
                const sessionLocale = data.session.locale || searchParams.get("lang");
                let sessionModules = data.session.active_modules || (
                  data.session.focus === "presales"
                    ? ["portfolio_distribution"]
                    : data.session.focus === "aftersales"
                      ? ["property_lease_management"]
                      : ["portfolio_distribution", "property_lease_management"]
                );

                // Merge any module already activated in localStorage
                try {
                  const s = localStorage.getItem("stanomer_agency_demo");
                  if (s) {
                    const p = JSON.parse(s);
                    if (p.active_modules && Array.isArray(p.active_modules) && p.active_modules.length > 0) {
                      sessionModules = Array.from(new Set([...sessionModules, ...p.active_modules]));
                    }
                  }
                } catch { }

                setIsDemoVerified(true);
                activatePersonalDemoSandbox({
                  agencyName: data.session.agencyName,
                  email: data.session.email,
                  phone: data.session.phone,
                  city: data.session.city,
                  expiresAt: data.session.expiresAt,
                  focus: sessionModules.length > 1 ? "both" : sessionModules[0] === "portfolio_distribution" ? "presales" : "aftersales",
                  active_modules: sessionModules,
                  token: demoToken,
                  locale: sessionLocale,
                });
                const cleanSlug = (data.session.agencyName || "demo")
                  .toLowerCase()
                  .replace(/[^a-z0-9]+/g, "-")
                  .replace(/^-|-$/g, "") || "demo";
                localStorage.setItem(
                  "stanomer_agency_demo",
                  JSON.stringify({
                    token: demoToken,
                    isVerified: true,
                    slug: cleanSlug,
                    focus: sessionModules.length > 1 ? "both" : sessionModules[0] === "portfolio_distribution" ? "presales" : "aftersales",
                    active_modules: sessionModules,
                    locale: sessionLocale,
                    ...data.session,
                  })
                );

                // Clean up demo_token from URL query so page refreshes don't re-trigger and overwrite state
                try {
                  const currentUrl = new URL(window.location.href);
                  currentUrl.searchParams.delete("demo_token");
                  window.history.replaceState({}, "", currentUrl.pathname + (currentUrl.search ? currentUrl.search : ""));
                } catch { }
                return;
              } else if (data.expired && mounted) {
                if (typeof window !== "undefined") {
                  localStorage.removeItem("stanomer_agency_demo");
                }
                setDemoExpiredAlert({ expired: true, agencyName: data.agencyName });
              }
            } catch (e) {
              console.warn("Could not verify demo token:", e);
            }
          }
        }

        const { data } = await supabase.auth.getSession();
        const sessionUser = data.session?.user;
        if (sessionUser && mounted) {
          const access = await resolveAgencyAccess(sessionUser.id, sessionUser.user_metadata);
          if (!access.allowed || !access.effectiveAgencyId) {
            console.warn("Session user does not have agency role. Signing out of agency-panel.");
            await supabase.auth.signOut();
            if (mounted) {
              setUserId(null);
              setCurrentUser(null);
              setAgencyRole("agency_admin");
              setIsRoleError(true);
              setAuthError(t("agency_panel_err_only_agency_allowed"));
            }
            return;
          }

          const effectiveId = access.effectiveAgencyId;
          setAgencyRole(access.role);
          setUserId(effectiveId);
          setCurrentUser(sessionUser);
          const isDemoProfile = await loadAgencyProfile(effectiveId, sessionUser.email);
          fetchAgencyListings(effectiveId, isDemoProfile);
          loadAgencyLeads(effectiveId, isDemoProfile);
          loadAgencyPayments(effectiveId);
          loadAgencyManagedProperties(effectiveId);
          loadAgencyContracts(effectiveId);
          loadAgencyMaintenance(effectiveId);
          loadAgencyTasks(effectiveId);
          loadTeamAssignees(effectiveId, sessionUser);
        } else if (mounted) {
          // 2. Check localStorage for active unexpired demo
          if (typeof window !== "undefined") {
            try {
              const savedDemo = localStorage.getItem("stanomer_agency_demo");
              if (savedDemo) {
                const parsed = JSON.parse(savedDemo);
                if (parsed && parsed.expiresAt && new Date(parsed.expiresAt) > new Date()) {
                  if (parsed.isVerified === true) {
                    setIsDemoVerified(true);
                  } else {
                    setIsDemoVerified(false);
                  }
                  const savedModules = parsed.active_modules || (
                    parsed.focus === "presales"
                      ? ["portfolio_distribution"]
                      : parsed.focus === "aftersales"
                        ? ["property_lease_management"]
                        : ["portfolio_distribution", "property_lease_management"]
                  );
                  parsed.active_modules = savedModules;
                  activatePersonalDemoSandbox(parsed);
                  return;
                } else if (parsed && parsed.expiresAt) {
                  localStorage.removeItem("stanomer_agency_demo");
                  setDemoExpiredAlert({ expired: true, agencyName: parsed.agencyName });
                }
              }
            } catch { }
          }

          // Check if returning from email verification redirect
          if (typeof window !== "undefined") {
            const sp = new URLSearchParams(window.location.search);
            if (sp.get("verified_demo") === "1") {
              setIsDemoVerified(true);
            }
          }

          loadAgencyLeads("demo");
          loadAgencyPayments("demo");
          loadAgencyManagedProperties("demo");
          loadAgencyContracts("demo");
          loadAgencyMaintenance("demo");
          if (typeof window !== "undefined") {
            try {
              const savedListings = localStorage.getItem("stanomer_agency_listings_demo");
              if (savedListings) {
                const parsedL = JSON.parse(savedListings);
                if (Array.isArray(parsedL) && parsedL.length > 0) {
                  setListings(parsedL);
                } else {
                  setListings(DEMO_AGENCY_LISTINGS);
                  localStorage.setItem("stanomer_agency_listings_demo", JSON.stringify(DEMO_AGENCY_LISTINGS));
                }
              } else {
                setListings(DEMO_AGENCY_LISTINGS);
                localStorage.setItem("stanomer_agency_listings_demo", JSON.stringify(DEMO_AGENCY_LISTINGS));
              }
            } catch {
              setListings(DEMO_AGENCY_LISTINGS);
            }
          } else {
            setListings(DEMO_AGENCY_LISTINGS);
          }
          try {
            const saved = localStorage.getItem("stanomer_showcase_theme");
            if (saved) {
              const parsed = JSON.parse(saved);
              if (parsed.custom_domain) setAgencyCustomDomain(parsed.custom_domain);
              if (parsed.slug) setAgencySlug(parsed.slug);
              if (
                parsed.contactChannels === "both" ||
                parsed.contactChannels === "whatsapp" ||
                parsed.contactChannels === "viber" ||
                parsed.contactChannels === "none"
              ) {
                setContactChannels(parsed.contactChannels);
              }
              const validTemplates: ShowcaseTemplate[] = [
                "stanomer_modern",
                "quiet_luxury",
                "minimal_light",
                "kolm_dark",
                "lumira",
                "aldervik",
                "sage",
                "onyx_dark",
              ];
              if (validTemplates.includes(parsed.template)) {
                setShowcaseTemplate(parsed.template);
              }
              const validPalettes: ShowcasePalette[] = [
                "royal_blue",
                "champagne_gold",
                "emerald_prestige",
                "burgundy_classic",
                "kolm_mint",
                "lumira_coral",
                "aldervik_amber",
                "sage_terracotta",
                "onyx_brass",
              ];
              if (validPalettes.includes(parsed.palette)) {
                setShowcasePalette(parsed.palette);
              }
              if (
                parsed.radius === "sharp" ||
                parsed.radius === "subtle" ||
                parsed.radius === "rounded" ||
                parsed.radius === "pill"
              ) {
                setShowcaseRadius(parsed.radius);
              }
              if (Array.isArray(parsed.languages) && parsed.languages.length > 0) {
                setShowcaseLanguages(parsed.languages);
              }
              if (Array.isArray(parsed.currencies) && parsed.currencies.length > 0) {
                setShowcaseCurrencies(parsed.currencies);
              }
              if (parsed.default_currency && (["EUR", "RSD", "USD"] as ShowcaseCurrency[]).includes(parsed.default_currency)) {
                setShowcaseDefaultCurrency(parsed.default_currency as ShowcaseCurrency);
              }
            }
          } catch { }
        }
      } finally {
        if (mounted) {
          setIsCheckingSession(false);
        }
      }
    }
    checkSession();
    return () => {
      mounted = false;
    };
  }, []);

  // Demo floating nudge timer (2 minutes = 120s)
  useEffect(() => {
    if (isDemoMode && !isDemoVerified) {
      if (typeof window !== "undefined") {
        const isDismissed = sessionStorage.getItem("stanomer_demo_nudge_dismissed");
        if (!isDismissed) {
          const timer = setTimeout(() => {
            setIsFloatingNudgeVisible(true);
          }, 120000);
          return () => clearTimeout(timer);
        }
      }
    } else {
      setIsFloatingNudgeVisible(false);
    }
  }, [isDemoMode, isDemoVerified]);

  // Directory agency autocomplete search for signup
  useEffect(() => {
    const q = dirSearchQuery.trim();
    if (q.length < 2) {
      setDirMatches([]);
      return;
    }
    let active = true;
    const timer = setTimeout(async () => {
      try {
        let { data } = await supabase
          .from("view_clean_agencies")
          .select("id, acente_adi, sehir, web_sitesi, telefonlar, eposta_adresleri")
          .ilike("acente_adi", `%${q}%`)
          .limit(6);

        if (!data || data.length === 0) {
          const prodRes = await prodPublicClient
            .from("view_clean_agencies")
            .select("id, acente_adi, sehir, web_sitesi, telefonlar, eposta_adresleri")
            .ilike("acente_adi", `%${q}%`)
            .limit(6);
          data = prodRes.data;
        }
        if (active && data) {
          setDirMatches(data as DirectoryAgencyMatch[]);
        }
      } catch {
        // Ignore directory lookup errors
      }
    }, 250);
    return () => {
      active = false;
      clearTimeout(timer);
    };
  }, [dirSearchQuery]);

  function handleSelectDirAgency(item: DirectoryAgencyMatch) {
    setSelectedDirAgency(item);
    setDirSearchQuery("");
    setDirMatches([]);
    setSignupCompany(item.acente_adi || "");
    const firstPhone = (item.telefonlar || "").split(",")[0]?.trim() || "";
    const firstEmail = (item.eposta_adresleri || "").split(",")[0]?.trim() || "";
    if (firstPhone) setSignupPhone(firstPhone);
    if (item.web_sitesi) setSignupWebsite(item.web_sitesi);
    if (firstEmail && !authEmail) setAuthEmail(firstEmail);
  }

  const availableMunicipalities = useMemo(() => {
    const found = SERBIAN_LOCATIONS.find((c) => c.city === city);
    return found ? found.municipalities : [];
  }, [city]);

  const availableNeighborhoods = useMemo(() => {
    const foundMuni = availableMunicipalities.find((m) => m.name === municipality);
    return foundMuni ? foundMuni.neighborhoods : [];
  }, [availableMunicipalities, municipality]);

  const val4Zida = useMemo(() => {
    return validate4ZidaListing({
      price: price ? Number(price) : null,
      area_sqm: areaSqm ? Number(areaSqm) : null,
      address,
      transaction_type: transactionType,
      property_type: propertyType,
      room_count: roomCount,
      floor,
      heating_type: heatingType,
      city,
      municipality,
      neighborhood,
      description,
      listing_images: images,
    });
  }, [
    price,
    areaSqm,
    address,
    transactionType,
    propertyType,
    roomCount,
    floor,
    heatingType,
    city,
    municipality,
    neighborhood,
    description,
    images,
  ]);

  const valHalo = useMemo(() => {
    return validateHaloOglasiListing({
      price: price ? Number(price) : null,
      area_sqm: areaSqm ? Number(areaSqm) : null,
      address,
      transaction_type: transactionType,
      property_type: propertyType,
      room_count: roomCount,
      floor,
      heating_type: heatingType,
      city,
      municipality,
      neighborhood,
      description,
      listing_images: images,
    });
  }, [
    price,
    areaSqm,
    address,
    transactionType,
    propertyType,
    roomCount,
    floor,
    heatingType,
    city,
    municipality,
    neighborhood,
    description,
    images,
  ]);

  const handleCityChange = (newCity: string) => {
    setCity(newCity);
    const cityObj = SERBIAN_LOCATIONS.find((c) => c.city === newCity);
    const firstMuni = cityObj?.municipalities[0];
    setMunicipality(firstMuni?.name || "");
    setNeighborhood(firstMuni?.neighborhoods[0] || "");
  };

  const handleMunicipalityChange = (newMuni: string) => {
    setMunicipality(newMuni);
    const muniObj = availableMunicipalities.find((m) => m.name === newMuni);
    setNeighborhood(muniObj?.neighborhoods[0] || "");
  };

  const fetchFeedLogs = async () => {
    setLoadingFeedLogs(true);
    try {
      if (userId) {
        const { data, error } = await supabase
          .from("portal_feed_logs")
          .select("id, portal, ip_address, user_agent, listing_count, status_code, duration_ms, created_at")
          .eq("agency_id", userId)
          .order("created_at", { ascending: false })
          .limit(20);

        if (!error && Array.isArray(data) && data.length > 0) {
          setFeedLogs(data as PortalFeedLogRow[]);
          setLoadingFeedLogs(false);
          return;
        }
      }

      // Realistic initial / demo crawl logs for immediate visual monitoring
      const now = Date.now();
      const demoListingsCount = listings.length > 0 ? listings.length : 18;
      setFeedLogs([
        {
          id: "log-demo-1",
          portal: "4zida",
          ip_address: "185.220.101.45",
          user_agent: "4zida-bot/1.0 (crawler; +https://www.4zida.rs)",
          listing_count: demoListingsCount,
          status_code: 200,
          duration_ms: 38,
          created_at: new Date(now - 14 * 60 * 1000).toISOString(),
        },
        {
          id: "log-demo-2",
          portal: "4zida",
          ip_address: "185.220.101.45",
          user_agent: "4zida-bot/1.0 (crawler; +https://www.4zida.rs)",
          listing_count: demoListingsCount,
          status_code: 200,
          duration_ms: 42,
          created_at: new Date(now - 44 * 60 * 1000).toISOString(),
        },
        {
          id: "log-demo-3",
          portal: "halooglasi",
          ip_address: "212.200.65.12",
          user_agent: "HaloOglasi-XML-Feed-Bot/2.4",
          listing_count: demoListingsCount,
          status_code: 200,
          duration_ms: 55,
          created_at: new Date(now - 65 * 60 * 1000).toISOString(),
        },
      ]);
    } catch (e) {
      console.warn("Could not fetch feed logs:", e);
    } finally {
      setLoadingFeedLogs(false);
    }
  };

  useEffect(() => {
    if (activeTab === "xml") {
      fetchFeedLogs();
    }
  }, [activeTab]);

  function formatTimeAgo(dateIso: string): string {
    const diffSec = Math.floor((Date.now() - new Date(dateIso).getTime()) / 1000);
    if (diffSec < 60) return `${diffSec}s`;
    const diffMin = Math.floor(diffSec / 60);
    if (diffMin < 60) return `${diffMin}m`;
    const diffHour = Math.floor(diffMin / 60);
    if (diffHour < 24) return `${diffHour}h`;
    return `${Math.floor(diffHour / 24)}d`;
  }

  async function fetchAgencyListings(activeUserId: string, isDemoProfile = false) {
    setLoadingListings(true);
    try {
      const selectCols = `
          id,
          agency_id,
          managed_property_id,
          external_ref,
          title,
          description,
          transaction_type,
          property_type,
          price,
          currency,
          area_sqm,
          room_count,
          floor,
          total_floors,
          heating_type,
          condition,
          furnishing,
          city,
          municipality,
          neighborhood,
          address,
          amenities,
          is_published,
          listing_status,
          closed_at,
          closing_price,
          closing_notes,
          closing_contract_id,
          published_portals,
          created_at,
          listing_images (
            id,
            url,
            order_index,
            is_cover
          )
        `;

      const { data, error } = await supabase
        .from("listings")
        .select(selectCols)
        .eq("agency_id", activeUserId)
        .order("created_at", { ascending: false });

      if (error) throw error;
      let rows = (data as unknown as AgencyListingRow[]) || [];

      // Seed Portfolio & Distribution demo listings into real Supabase once for verified 7-day demo accounts
      const seedFlagKey = `stanomer_demo_listings_seeded_v2_${activeUserId}`;
      const alreadySeeded = typeof window !== "undefined" && localStorage.getItem(seedFlagKey) === "1";
      if ((isDemoProfile || isDemoMode) && rows.length === 0 && !alreadySeeded) {
        try {
          let insertedCount = 0;
          for (const item of DEMO_AGENCY_LISTINGS) {
            const { data: inserted, error: insErr } = await supabase
              .from("listings")
              .insert({
                agency_id: activeUserId,
                external_ref: item.external_ref || null,
                title: item.title,
                description: item.description || null,
                transaction_type: item.transaction_type,
                property_type: item.property_type,
                price: item.price,
                currency: item.currency || "EUR",
                area_sqm: item.area_sqm || null,
                room_count: item.room_count || null,
                floor: item.floor || null,
                total_floors: item.total_floors || null,
                heating_type: item.heating_type || null,
                condition: item.condition || null,
                furnishing: item.furnishing || null,
                city: item.city || "Beograd",
                municipality: item.municipality || null,
                neighborhood: item.neighborhood || null,
                address: item.address || null,
                amenities: item.amenities || [],
                is_published: item.is_published ?? true,
                published_portals: item.published_portals || ["stanomer"],
              })
              .select("id")
              .single();

            if (!insErr && inserted?.id) {
              insertedCount += 1;
              if (Array.isArray(item.listing_images) && item.listing_images.length > 0) {
                await supabase.from("listing_images").insert(
                  item.listing_images.map((img, idx) => ({
                    listing_id: inserted.id,
                    url: img.url,
                    order_index: img.order_index ?? idx,
                    is_cover: Boolean(img.is_cover),
                  }))
                );
              }
            } else if (insErr) {
              console.warn("Demo listing insert blocked:", insErr.message);
            }
          }
          if (insertedCount > 0 && typeof window !== "undefined") {
            localStorage.setItem(seedFlagKey, "1");
          }
          if (insertedCount > 0) {
            const { data: seededData } = await supabase
              .from("listings")
              .select(selectCols)
              .eq("agency_id", activeUserId)
              .order("created_at", { ascending: false });
            if (seededData) {
              rows = seededData as unknown as AgencyListingRow[];
            }
          }
        } catch (seedErr) {
          console.warn("Could not seed demo listings:", seedErr);
        }
      }

      setListings(rows);
    } catch (err) {
      console.error("Error loading agency listings:", err);
    } finally {
      setLoadingListings(false);
    }
  }

  async function loadAgencyLeads(uid: string, isDemoProfile = false) {
    let combinedLeads: AgencyLead[] = [];
    const seenLeadIds = new Set<string>();
    const hasRealDbUser = Boolean(uid && uid !== "demo");

    if (hasRealDbUser) {
      try {
        let query = supabase
          .from("agency_leads")
          .select("*")
          .order("created_at", { ascending: false })
          .limit(100);

        if (agencySlug) {
          query = query.or(`agency_id.eq.${uid},agency_id.eq.${agencySlug}`);
        } else {
          query = query.eq("agency_id", uid);
        }

        let { data, error } = await query;

        // Seed CRM demo leads into real Supabase once for verified 7-day demo accounts
        const leadsSeedFlagKey = `stanomer_demo_leads_seeded_${uid}`;
        const alreadySeededLeads = typeof window !== "undefined" && localStorage.getItem(leadsSeedFlagKey) === "1";
        if ((isDemoProfile || isDemoMode) && (!data || data.length === 0) && !error && !alreadySeededLeads) {
          try {
            const payload = DEMO_AGENCY_LEADS.map((l) => ({
              agency_id: uid,
              lead_type: l.lead_type,
              status: l.status,
              client_name: l.client_name,
              client_phone: l.client_phone,
              client_email: l.client_email || null,
              transaction_type: l.transaction_type || "prodaja",
              property_type: l.property_type || "apartment",
              location: l.location || null,
              area_sqm: l.area_sqm || null,
              expected_price: l.expected_price || null,
              currency: l.currency || "EUR",
              notes: l.notes || null,
              listing_title: l.listing_title || null,
              comments: l.comments || [],
              created_at: l.created_at,
            }));
            const { error: insErr } = await supabase.from("agency_leads").insert(payload);
            if (!insErr) {
              if (typeof window !== "undefined") {
                localStorage.setItem(leadsSeedFlagKey, "1");
              }
              const refetch = await supabase
                .from("agency_leads")
                .select("*")
                .eq("agency_id", uid)
                .order("created_at", { ascending: false })
                .limit(100);
              data = refetch.data;
              error = refetch.error;
            }
          } catch (seedErr) {
            console.warn("Could not seed demo leads:", seedErr);
          }
        }

        if (data && !error && data.length > 0) {
          for (const item of data) {
            if (!seenLeadIds.has(item.id)) {
              seenLeadIds.add(item.id);
              combinedLeads.push(item as unknown as AgencyLead);
            }
          }
        }
      } catch { }
    } else if (typeof window !== "undefined") {
      const keysToScan = [
        "stanomer_agency_leads_demo",
        agencySlug ? `stanomer_agency_leads_${agencySlug}` : null,
        agencyCustomDomain ? `stanomer_agency_leads_${agencyCustomDomain}` : null,
      ].filter(Boolean) as string[];

      try {
        for (let i = 0; i < localStorage.length; i++) {
          const k = localStorage.key(i);
          if (k && k.startsWith("stanomer_agency_leads_") && !keysToScan.includes(k)) {
            keysToScan.push(k);
          }
        }
      } catch { }

      for (const k of keysToScan) {
        try {
          const raw = localStorage.getItem(k);
          if (raw) {
            const parsed = JSON.parse(raw);
            if (Array.isArray(parsed)) {
              for (const item of parsed) {
                if (item && item.id && !seenLeadIds.has(item.id)) {
                  seenLeadIds.add(item.id);
                  combinedLeads.push(item as AgencyLead);
                }
              }
            }
          }
        } catch { }
      }

      for (const demoLead of DEMO_AGENCY_LEADS) {
        if (!seenLeadIds.has(demoLead.id)) {
          seenLeadIds.add(demoLead.id);
          combinedLeads.push(demoLead);
        }
      }
    }
    combinedLeads = combinedLeads.map((l) => ({
      ...l,
      comments: l.comments || [],
    }));

    combinedLeads.sort(
      (a, b) =>
        new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
    );
    setListingsLeads(combinedLeads);
  }

  async function loadAgencyPayments(uid: string) {
    if (!uid || uid === "demo") {
      setPayments(processRentPayments(DEMO_AGENCY_PAYMENTS));
      return;
    }
    setLoadingPayments(true);
    try {
      // 1. Try querying the Unified Database SSOT View (view_agency_financial_ledger) with pagination
      let ledgerRows: any[] = [];
      try {
        const PAGE_SIZE = 1000;
        let from = 0;
        while (true) {
          const { data: batch, error: viewErr } = await supabase
            .from("view_agency_financial_ledger")
            .select("*")
            .eq("agency_id", uid)
            .order("due_date", { ascending: false })
            .range(from, from + PAGE_SIZE - 1);

          if (viewErr) {
            ledgerRows = [];
            break;
          }
          if (!batch || batch.length === 0) break;
          ledgerRows.push(...batch);
          if (batch.length < PAGE_SIZE) break;
          from += PAGE_SIZE;
        }
      } catch {
        ledgerRows = [];
      }

      if (ledgerRows.length > 0) {
        const formattedFromView: AgencyRentPayment[] = ledgerRows.map((r: any) => {
          const activeCtr = contracts.find((c) => c.property_id === r.property_id);
          return {
            id: r.id,
            property_id: r.property_id,
            contract_id: r.contract_id,
            tenant_id: r.tenant_id,
            property_title: r.property_title || "Mülk",
            property_address: r.property_address ? `${r.property_address}${r.property_city ? `, ${r.property_city}` : ""}` : "",
            tenant_name: r.tenant_name || activeCtr?.tenant_name || null,
            tenant_phone: activeCtr?.tenant_phone || null,
            landlord_name: r.landlord_name || null,
            landlord_email: r.landlord_email || null,
            title: r.title || "Kira",
            amount: Number(r.amount) || 0,
            currency: r.currency || "EUR",
            due_date: r.due_date,
            declared_at: r.declared_at,
            paid_at: r.paid_at,
            status: r.status,
            receiver_type: r.receiver_type || "owner",
            payment_method: r.payment_method,
            receipt_url: r.receipt_url,
            owner_note: r.owner_note,
            dispute_reason: r.dispute_reason || null,
            disputed_at: r.disputed_at || null,
            invoice_url: r.invoice_url || null,
            created_at: r.created_at,
            // View SSOT fields & KPI flags
            source_table: r.source_table,
            raw_title: r.raw_title,
            category: r.category,
            is_maintenance: Boolean(r.is_maintenance),
            cost_amount: r.cost_amount,
            remaining_amount: r.remaining_amount,
            settled_amount: r.settled_amount,
            debtor_id: r.debtor_id,
            is_tenant_debtor: Boolean(r.is_tenant_debtor),
            is_landlord_debtor: Boolean(r.is_landlord_debtor),
            is_pending_approval: Boolean(r.is_pending_approval),
            is_unentered_bill: Boolean(r.is_unentered_bill),
            is_overdue: Boolean(r.is_overdue),
            is_rent_collected: Boolean(r.is_rent_collected),
            is_bills_collected: Boolean(r.is_bills_collected),
            is_bills_to_institutions: Boolean(r.is_bills_to_institutions),
            is_maintenance_paid: Boolean(r.is_maintenance_paid),
            is_maintenance_owed_to_agency: Boolean(r.is_maintenance_owed_to_agency),
            is_unpaid_maintenance: Boolean(r.is_unpaid_maintenance),
            is_unpaid_bills_to_institutions: Boolean(r.is_unpaid_bills_to_institutions),
            is_tenant_offset: Boolean(r.is_tenant_offset),
          };
        });
        setPayments(processRentPayments(formattedFromView));
        return;
      }

      // 2. Fallback: Fetch properties managed by this agency with landlord and tenant info
      const { data: props, error: propsErr } = await supabase
        .from("properties")
        .select("id, title, address, city, default_monthly_rent, currency, landlord_name, landlord_email, landlord_phone, landlord_id, tenant_id")
        .eq("agency_id", uid);

      if (propsErr) throw propsErr;
      const propMap = new Map((props || []).map((p) => [p.id, p]));
      const propIds = Array.from(propMap.keys());

      if (propIds.length === 0) {
        setPayments([]);
        return;
      }

      // 3. Fetch all rent payments for these properties with pagination (matching Flutter SSOT)
      const allRawPays: any[] = [];
      const PAGE_SIZE = 1000;
      let from = 0;
      while (true) {
        const { data: payBatch, error: paysErr } = await supabase
          .from("rent_payments")
          .select("*")
          .in("property_id", propIds)
          .order("due_date", { ascending: false })
          .range(from, from + PAGE_SIZE - 1);

        if (paysErr) throw paysErr;
        if (!payBatch || payBatch.length === 0) break;
        allRawPays.push(...payBatch);
        if (payBatch.length < PAGE_SIZE) break;
        from += PAGE_SIZE;
      }

      // 4. Map to AgencyRentPayment
      const formatted: AgencyRentPayment[] = (allRawPays || []).map((p: any) => {
        const prop = propMap.get(p.property_id);
        const activeCtr = contracts.find((c) => c.property_id === p.property_id);
        return {
          id: p.id,
          property_id: p.property_id,
          contract_id: p.contract_id,
          tenant_id: p.tenant_id,
          property_title: prop?.title || "Mülk",
          property_address: prop?.address ? `${prop.address}${prop.city ? `, ${prop.city}` : ""}` : "",
          tenant_name: activeCtr?.tenant_name || null,
          tenant_phone: activeCtr?.tenant_phone || null,
          title: p.title || "Kira",
          amount: Number(p.amount) || 0,
          currency: p.currency || prop?.currency || "EUR",
          due_date: p.due_date,
          declared_at: p.declared_at,
          paid_at: p.paid_at,
          status: p.status,
          receiver_type: p.receiver_type || "owner",
          payment_method: p.payment_method,
          receipt_url: p.receipt_url,
          owner_note: p.owner_note,
          dispute_reason: p.dispute_reason || null,
          disputed_at: p.disputed_at || null,
          invoice_url: p.invoice_url || null,
          created_at: p.created_at,
        };
      });

      setPayments(processRentPayments(formatted));
    } catch (err) {
      console.error("Error loading agency payments:", err);
    } finally {
      setLoadingPayments(false);
    }
  }

  const handleApprovePayment = async (p: AgencyRentPayment) => {
    if (!checkEffectiveDemoVerified()) {
      setIsGatekeeperModalOpen(true);
      return;
    }
    setProcessingPaymentId(p.id);
    try {
      if (userId && userId !== "demo") {
        const { error } = await supabase
          .from("rent_payments")
          .update({
            status: "paid",
            paid_at: new Date().toISOString(),
            dispute_reason: null,
          })
          .eq("id", p.id);
        if (error) throw error;

        try {
          const isRent = (p.title || "").toLowerCase().includes("kira") || (p.title || "").toLowerCase().includes("rent") || (p.title || "").toLowerCase().includes("kirij");
          const logType = isRent ? "rent_approved" : "payment_toggle";
          await supabase.from("activity_logs").insert({
            property_id: p.property_id,
            user_id: userId,
            type: logType,
            metadata: {
              payment_id: p.id,
              title: p.title,
              amount: p.amount,
              currency: p.currency,
              due_date: p.due_date,
              paid: true,
            },
          });
        } catch (logErr) {
          console.warn("Could not insert activity log for payment approval:", logErr);
        }
      }
      setPayments((prev) =>
        prev.map((item) =>
          item.id === p.id
            ? { ...item, status: "paid", paid_at: new Date().toISOString() }
            : item
        )
      );
      if (selectedReceiptPayment?.id === p.id) {
        setSelectedReceiptPayment(null);
      }
      setStatusMessage({
        type: "success",
        text: t("agency_payments_approved_success"),
      });
    } catch (err) {
      console.error("Approve payment error:", err);
      setStatusMessage({
        type: "error",
        text: t("agency_panel_msg_save_error"),
      });
    } finally {
      setProcessingPaymentId(null);
    }
  };

  const handleRejectPayment = async (p: AgencyRentPayment) => {
    if (!checkEffectiveDemoVerified()) {
      setIsGatekeeperModalOpen(true);
      return;
    }
    setProcessingPaymentId(p.id);
    try {
      if (userId && userId !== "demo") {
        const { error } = await supabase
          .from("rent_payments")
          .update({
            status: "pending",
            declared_at: null,
            dispute_reason: null,
          })
          .eq("id", p.id);
        if (error) throw error;

        try {
          const isRent = (p.title || "").toLowerCase().includes("kira") || (p.title || "").toLowerCase().includes("rent") || (p.title || "").toLowerCase().includes("kirij");
          const logType = isRent ? "rent_rejected" : "payment_toggle";
          await supabase.from("activity_logs").insert({
            property_id: p.property_id,
            user_id: userId,
            type: logType,
            metadata: {
              payment_id: p.id,
              title: p.title,
              amount: p.amount,
              currency: p.currency,
              due_date: p.due_date,
              paid: false,
            },
          });
        } catch (logErr) {
          console.warn("Could not insert activity log for payment rejection:", logErr);
        }
      }
      setPayments((prev) =>
        prev.map((item) =>
          item.id === p.id
            ? { ...item, status: "pending", declared_at: null }
            : item
        )
      );
      if (selectedReceiptPayment?.id === p.id) {
        setSelectedReceiptPayment(null);
      }
      setStatusMessage({
        type: "success",
        text: t("agency_payments_rejected_success"),
      });
    } catch (err) {
      console.error("Reject payment error:", err);
      setStatusMessage({
        type: "error",
        text: t("agency_panel_msg_save_error"),
      });
    } finally {
      setProcessingPaymentId(null);
    }
  };

  async function loadAgencyManagedProperties(uid: string) {
    if (!uid || uid === "demo" || (isDemoMode && uid === "demo")) {
      if (typeof window !== "undefined") {
        try {
          const savedProps = localStorage.getItem("stanomer_agency_managed_props_demo");
          if (savedProps) {
            const parsedP = JSON.parse(savedProps);
            if (Array.isArray(parsedP) && parsedP.length > 0) {
              setManagedProperties(parsedP);
              return;
            }
          }
        } catch { }
      }
      setManagedProperties(DEMO_AGENCY_MANAGED_PROPERTIES);
      return;
    }
    setLoadingProperties(true);
    try {
      const { data: props, error: propsErr } = await supabase
        .from("properties")
        .select("id, agency_id, landlord_id, tenant_id, title, name, address, city, property_type, unit_number, room_count, area_sqm, floor, total_floors, furnishing, heating_type, amenities, description, is_detailed, default_monthly_rent, default_deposit_amount, currency, default_deposit_currency, default_due_day, expenses_template, landlord_name, landlord_email, landlord_phone, last_listing_id, created_at")
        .eq("agency_id", uid)
        .order("created_at", { ascending: false });

      if (propsErr) throw propsErr;

      if (!props || props.length === 0) {
        setManagedProperties([]);
        return;
      }

      const propIds = props.map((p: any) => p.id);
      const landlordIds = props.map((p: any) => p.landlord_id).filter(Boolean);

      // Client-side terminated contract & property cache (resilient against legacy contracts with agency_id = NULL)
      let localTerminatedContracts = new Set<string>();
      let localTerminatedProps = new Map<string, string>();
      if (typeof window !== "undefined") {
        try {
          const rawTerm = localStorage.getItem("stanomer_terminated_contracts_v1");
          if (rawTerm) {
            const parsed = JSON.parse(rawTerm);
            if (Array.isArray(parsed?.contractIds)) {
              localTerminatedContracts = new Set(parsed.contractIds);
            }
            if (parsed?.propertyDates && typeof parsed.propertyDates === "object") {
              localTerminatedProps = new Map(Object.entries(parsed.propertyDates));
            }
          }
        } catch { }
      }

      // Fetch active contracts for these properties
      const { data: activeContracts, error: ctrErr } = await supabase
        .from("contracts")
        .select("id, property_id, tenant_id, tenant_name, tenant_phone, invitee_email, end_date, status, termination_approved, termination_date")
        .in("property_id", propIds)
        .eq("status", "active");

      if (ctrErr) console.warn("Error fetching property contracts:", ctrErr);

      // Also check activity_logs for contract_termination_requested events on these properties
      const { data: termLogs } = await supabase
        .from("activity_logs")
        .select("property_id, metadata, created_at")
        .in("property_id", propIds)
        .in("type", ["contract_termination_requested", "tenant_removed"]);

      const terminatedContractIdsFromLogs = new Set<string>(localTerminatedContracts);
      const terminatedPropertyDatesFromLogs = new Map<string, string>(localTerminatedProps);
      if (termLogs) {
        for (const lg of termLogs) {
          const cid = lg.metadata?.contract_id;
          const tDate = lg.metadata?.termination_date || (lg.created_at ? lg.created_at.split("T")[0] : "");
          if (cid) terminatedContractIdsFromLogs.add(cid);
          if (lg.property_id && tDate) {
            terminatedPropertyDatesFromLogs.set(lg.property_id, tDate);
          }
        }
      }

      // Filter out contracts that were actually terminated
      const trulyActiveContracts = (activeContracts || []).filter((c: any) => {
        const propRow = props.find((pr: any) => pr.id === c.property_id);
        const isTerminatedByFlag = Boolean(c.termination_approved || c.termination_date);
        const isTerminatedByLog =
          terminatedContractIdsFromLogs.has(c.id) ||
          (terminatedPropertyDatesFromLogs.has(c.property_id) && !propRow?.tenant_id);
        return !isTerminatedByFlag && !isTerminatedByLog;
      });

      const contractByProp = new Map(
        trulyActiveContracts.map((c: any) => [c.property_id, c])
      );

      const tenantIds = Array.from(
        new Set([
          ...props.map((p: any) => p.tenant_id).filter(Boolean),
          ...(activeContracts || []).map((c: any) => c.tenant_id).filter(Boolean),
        ])
      );
      const allProfileIds = Array.from(new Set([...landlordIds, ...tenantIds]));

      // Fetch landlord & tenant profiles
      let profileMap = new Map<string, { full_name?: string; phone?: string; email?: string }>();
      if (allProfileIds.length > 0) {
        const { data: profs } = await supabase
          .from("profiles")
          .select("id, full_name, phone_number, email")
          .in("id", allProfileIds);
        if (profs) {
          profileMap = new Map(
            profs.map((l: any) => [
              l.id,
              { full_name: l.full_name, phone: l.phone_number, email: l.email },
            ])
          );
        }
      }

      // Fetch property owners (SSOT corporate & individual co-owners like GROWTH EDGE)
      const { data: ownersData, error: ownersErr } = await supabase
        .from("property_owners")
        .select("*")
        .in("property_id", propIds)
        .order("is_primary", { ascending: false });

      if (ownersErr) console.warn("Error fetching property owners:", ownersErr);

      const ownersByProp = new Map<string, any[]>();
      if (ownersData) {
        for (const o of ownersData) {
          const list = ownersByProp.get(o.property_id) || [];
          list.push(o);
          ownersByProp.set(o.property_id, list);
        }
      }

      const formatted: AgencyManagedProperty[] = props.map((p: any) => {
        const activeCtr = contractByProp.get(p.id);
        const landlord = p.landlord_id ? profileMap.get(p.landlord_id) : null;
        const effectiveTenantId = activeCtr?.tenant_id || p.tenant_id || null;
        const tenantProf = effectiveTenantId ? profileMap.get(effectiveTenantId) : null;
        const isOccupied = Boolean(activeCtr || p.tenant_id);

        const propOwners = ownersByProp.get(p.id) || [];
        const primaryOwner = propOwners.find((o: any) => o.is_primary) || propOwners[0];

        let resolvedLandlordName: string | null = null;
        let resolvedLandlordPhone: string | null = null;
        let resolvedLandlordEmail: string | null = null;

        if (primaryOwner) {
          resolvedLandlordName =
            primaryOwner.owner_type === "company"
              ? primaryOwner.company_name?.trim() || null
              : `${primaryOwner.first_name || ""} ${primaryOwner.last_name || ""}`.trim() || null;
          resolvedLandlordPhone = primaryOwner.phone?.trim() || null;
          resolvedLandlordEmail = primaryOwner.email?.trim() || null;
        }

        // Fallbacks:
        // 1. Registered landlord profile from `profiles`
        // 2. Direct property columns (`properties.landlord_name`, etc.)
        resolvedLandlordName = resolvedLandlordName || landlord?.full_name || p.landlord_name || null;
        resolvedLandlordPhone = resolvedLandlordPhone || landlord?.phone || p.landlord_phone || null;
        resolvedLandlordEmail = resolvedLandlordEmail || landlord?.email || p.landlord_email || null;

        const resolvedTenantName =
          activeCtr?.tenant_name?.trim() ||
          tenantProf?.full_name?.trim() ||
          null;
        const resolvedTenantPhone =
          activeCtr?.tenant_phone?.trim() ||
          tenantProf?.phone?.trim() ||
          null;

        return {
          id: p.id,
          agency_id: p.agency_id || uid,
          landlord_id: p.landlord_id,
          tenant_id: effectiveTenantId,
          landlord_name: resolvedLandlordName,
          landlord_phone: resolvedLandlordPhone,
          landlord_email: resolvedLandlordEmail,
          owners: propOwners,
          title: p.title || p.name || "Kiralık Daire",
          address: p.address || "",
          city: p.city || "",
          property_type: p.property_type || "apartment",
          unit_number: p.unit_number || null,
          room_count: p.room_count ? String(p.room_count) : null,
          area_sqm: p.area_sqm ? Number(p.area_sqm) : null,
          floor: p.floor ? String(p.floor) : null,
          total_floors: p.total_floors != null ? Number(p.total_floors) : null,
          furnishing: p.furnishing || null,
          heating_type: p.heating_type || null,
          amenities: Array.isArray(p.amenities) ? p.amenities : [],
          description: p.description || null,
          is_detailed: Boolean(p.is_detailed ?? true),
          default_monthly_rent: p.default_monthly_rent ? Number(p.default_monthly_rent) : null,
          default_deposit_amount: p.default_deposit_amount != null ? Number(p.default_deposit_amount) : (p.default_monthly_rent ? Number(p.default_monthly_rent) : null),
          currency: p.currency || "EUR",
          default_deposit_currency: p.default_deposit_currency || p.currency || "EUR",
          default_due_day: p.default_due_day != null ? Number(p.default_due_day) : 1,
          expenses_template: Array.isArray(p.expenses_template) ? p.expenses_template : [],
          is_occupied: isOccupied,
          active_contract_id: activeCtr?.id || null,
          active_tenant_name: resolvedTenantName,
          active_tenant_phone: resolvedTenantPhone,
          contract_end_date: activeCtr?.end_date || null,
          last_listing_id: p.last_listing_id || null,
          created_at: p.created_at || new Date().toISOString(),
        };
      });

      setManagedProperties(formatted);
    } catch (err) {
      console.error("Error loading agency managed properties:", err);
    } finally {
      setLoadingProperties(false);
    }
  }

  async function loadAgencyContracts(uid: string) {
    if (!uid || uid === "demo" || (isDemoMode && uid === "demo")) {
      if (typeof window !== "undefined") {
        try {
          const savedCtrs = localStorage.getItem("stanomer_agency_contracts_demo");
          if (savedCtrs) {
            const parsedC = JSON.parse(savedCtrs);
            if (Array.isArray(parsedC) && parsedC.length > 0) {
              setContracts(parsedC);
              return;
            }
          }
        } catch { }
      }
      setContracts(DEMO_AGENCY_CONTRACTS);
      return;
    }
    setLoadingContracts(true);
    try {
      const { data: props } = await supabase
        .from("properties")
        .select("id, title, address, city, tenant_id, last_listing_id")
        .eq("agency_id", uid);

      const propMap = new Map((props || []).map((p: any) => [p.id, p]));
      const propIds = Array.from(propMap.keys());

      let localTerminatedContracts = new Set<string>();
      let localTerminatedProps = new Map<string, string>();
      if (typeof window !== "undefined") {
        try {
          const rawTerm = localStorage.getItem("stanomer_terminated_contracts_v1");
          if (rawTerm) {
            const parsed = JSON.parse(rawTerm);
            if (Array.isArray(parsed?.contractIds)) {
              localTerminatedContracts = new Set(parsed.contractIds);
            }
            if (parsed?.propertyDates && typeof parsed.propertyDates === "object") {
              localTerminatedProps = new Map(Object.entries(parsed.propertyDates));
            }
          }
        } catch { }
      }

      let query = supabase
        .from("contracts")
        .select("id, property_id, source_listing_id, landlord_id, tenant_id, agency_id, invitee_email, tenant_name, tenant_phone, tenant_id_number, tenant_notes, tenant_id_document_url, tenant_secondary_contacts, monthly_rent, deposit_amount, currency, deposit_currency, due_day, start_date, end_date, status, termination_approved, termination_date, expenses_config, contract_url, additional_documents, created_at");
      if (propIds.length > 0) {
        query = query.or(`agency_id.eq.${uid},property_id.in.(${propIds.join(",")})`);
      } else {
        query = query.eq("agency_id", uid);
      }

      const { data: ctrs, error: ctrErr } = await query
        .order("end_date", { ascending: true })
        .limit(150);
      if (ctrErr) throw ctrErr;

      // Also check activity_logs for contract_termination_requested events
      const terminatedContractIdsFromLogs = new Set<string>(localTerminatedContracts);
      const terminatedPropertyDatesFromLogs = new Map<string, string>(localTerminatedProps);
      if (propIds.length > 0) {
        const { data: termLogs } = await supabase
          .from("activity_logs")
          .select("property_id, metadata, created_at")
          .in("property_id", propIds)
          .in("type", ["contract_termination_requested", "tenant_removed"]);
        if (termLogs) {
          for (const lg of termLogs) {
            const cid = lg.metadata?.contract_id;
            const tDate = lg.metadata?.termination_date || (lg.created_at ? lg.created_at.split("T")[0] : "");
            if (cid) terminatedContractIdsFromLogs.add(cid);
            if (lg.property_id && tDate) {
              terminatedPropertyDatesFromLogs.set(lg.property_id, tDate);
            }
          }
        }
      }

      // Resolve tenant profiles for contracts where tenant_name or tenant_phone is missing (e.g. demo accounts)
      const contractTenantIds = Array.from(
        new Set((ctrs || []).map((c: any) => c.tenant_id).filter(Boolean))
      );
      let tenantProfileMap = new Map<string, { full_name?: string; phone?: string; email?: string }>();
      if (contractTenantIds.length > 0) {
        const { data: tenantProfs } = await supabase
          .from("profiles")
          .select("id, full_name, phone_number, email")
          .in("id", contractTenantIds);
        if (tenantProfs) {
          tenantProfileMap = new Map(
            tenantProfs.map((tp: any) => [
              tp.id,
              { full_name: tp.full_name, phone: tp.phone_number, email: tp.email },
            ])
          );
        }
      }

      const formatted: AgencyContract[] = (ctrs || []).map((c: any) => {
        const prop = propMap.get(c.property_id);
        const tProf = c.tenant_id ? tenantProfileMap.get(c.tenant_id) : null;
        const isTerminatedByFlag = Boolean(
          c.status === "terminated" ||
          c.status === "termination_requested" ||
          c.termination_approved ||
          c.termination_date
        );
        const isTerminatedByLog =
          terminatedContractIdsFromLogs.has(c.id) ||
          (terminatedPropertyDatesFromLogs.has(c.property_id) && !prop?.tenant_id);
        const effectiveStatus =
          isTerminatedByFlag || isTerminatedByLog ? "terminated" : (c.status || "active");
        const effectiveEndDate =
          c.termination_date ||
          terminatedPropertyDatesFromLogs.get(c.property_id) ||
          c.end_date;
        return {
          id: c.id,
          property_id: c.property_id,
          source_listing_id: c.source_listing_id || null,
          property_title: prop?.title || "Daire",
          property_address: prop?.address ? `${prop.address}${prop.city ? `, ${prop.city}` : ""}` : "",
          landlord_id: c.landlord_id,
          tenant_id: c.tenant_id,
          agency_id: c.agency_id,
          invitee_email: c.invitee_email || tProf?.email || null,
          tenant_name: c.tenant_name?.trim() || tProf?.full_name?.trim() || null,
          tenant_phone: c.tenant_phone?.trim() || tProf?.phone?.trim() || null,
          tenant_id_number: c.tenant_id_number || null,
          tenant_notes: c.tenant_notes || null,
          tenant_id_document_url: c.tenant_id_document_url || null,
          tenant_secondary_contacts: Array.isArray(c.tenant_secondary_contacts) ? c.tenant_secondary_contacts : [],
          monthly_rent: Number(c.monthly_rent) || 0,
          deposit_amount: Number(c.deposit_amount) || 0,
          currency: c.currency || "EUR",
          deposit_currency: c.deposit_currency || c.currency || "EUR",
          due_day: Number(c.due_day) || 1,
          start_date: c.start_date,
          end_date: effectiveEndDate,
          status: effectiveStatus,
          termination_approved: Boolean(c.termination_approved || isTerminatedByFlag || isTerminatedByLog),
          termination_date: c.termination_date || terminatedPropertyDatesFromLogs.get(c.property_id) || null,
          expenses_config: Array.isArray(c.expenses_config) ? c.expenses_config : [],
          contract_url: c.contract_url || null,
          additional_documents: Array.isArray(c.additional_documents) ? c.additional_documents : [],
          created_at: c.created_at || new Date().toISOString(),
        };
      });

      setContracts(formatted);
    } catch (err) {
      console.error("Error loading agency contracts:", err);
    } finally {
      setLoadingContracts(false);
    }
  }

  const handleConvertPropertyToListing = (prop: AgencyManagedProperty) => {
    setEditingId(null);
    setTransactionType("izdavanje");
    setPropertyType(prop.property_type || "apartment");
    setTitle(prop.title || "");
    setDescription(prop.description || "");
    setAddress(prop.address || "");
    setCity(prop.city || "Beograd");
    setPrice(prop.default_monthly_rent ? String(prop.default_monthly_rent) : "");
    setCurrency(prop.currency || "EUR");
    setAreaSqm(prop.area_sqm ? String(prop.area_sqm) : "");
    setRoomCount(prop.room_count || "2.0");
    if (prop.floor) setFloor(prop.floor);
    if (prop.total_floors != null) setTotalFloors(String(prop.total_floors));
    if (prop.heating_type) setHeatingType(prop.heating_type);
    if (prop.furnishing) setFurnishing(prop.furnishing);
    if (Array.isArray(prop.amenities) && prop.amenities.length > 0) {
      setSelectedAmenities(prop.amenities);
    }
    setActiveTab("form");
  };

  const handleInspectManagedPropertyById = (propertyId: string) => {
    const found = managedProperties.find((mp) => mp.id === propertyId);
    if (found) {
      setDrawerProperty(found);
      setDrawerTargetPaymentId(null);
    }
    setActiveTab("managed_properties");
  };

  const isValidUuid = (val?: string | null): boolean =>
    Boolean(val && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(val));

  const checkEffectiveDemoVerified = (): boolean => {
    if (!isDemoMode) return true;
    if (isDemoVerified) return true;
    if (userId && userId !== "demo") return true;
    if (typeof window !== "undefined") {
      try {
        const s = localStorage.getItem("stanomer_agency_demo");
        if (s) {
          const p = JSON.parse(s);
          if (p && p.isVerified === true) {
            setIsDemoVerified(true);
            return true;
          }
        }
      } catch { }
    }
    return false;
  };

  const handleCloseAndHandoverListing = async (params: CloseAndHandoverParams) => {
    if (!checkEffectiveDemoVerified()) {
      setIsGatekeeperModalOpen(true);
      return;
    }

    const {
      listing,
      closingStatus,
      closingPrice,
      closingNotes,
      handoverToPm,
      targetPropertyMode,
      existingPropertyId,
      landlordName,
      landlordPhone,
      landlordEmail,
      createContract,
      tenantName,
      tenantPhone,
      tenantEmail,
      startDate,
      endDate,
      depositAmount,
      dueDay,
    } = params;

    const nowIso = new Date().toISOString();
    const cur = listing.currency || "EUR";
    const resolvedTenantName = tenantName?.trim() || (createContract ? t("roleTenant") : null);
    const hasRealSupabaseUser = Boolean(userId && userId !== "demo" && isValidUuid(userId));

    let targetPropId =
      targetPropertyMode === "existing" && existingPropertyId
        ? existingPropertyId
        : listing.managed_property_id || null;
    let createdContractId: string | null = null;
    let handedOverPropObj: AgencyManagedProperty | null = null;

    // 1. If logged into Supabase with a real UUID user, persist property/contract/listing to Supabase
    if (hasRealSupabaseUser && userId) {
      try {
        const listingUuidOrNull = isValidUuid(listing.id) ? listing.id : null;

        const defaultExpensesTemplate = [
          { name: "Infostan", receiver: "owner" as const, amount: 0, payment_method: "bank_transfer" as const },
          { name: "Struja", receiver: "owner" as const, amount: 0, payment_method: "bank_transfer" as const },
          { name: "Internet & TV", receiver: "included" as const, amount: 0, payment_method: "bank_transfer" as const },
          { name: "Održavanje zgrade", receiver: "included" as const, amount: 0, payment_method: "bank_transfer" as const },
        ];

        if (handoverToPm) {
          if (targetPropertyMode === "existing" && existingPropertyId && isValidUuid(existingPropertyId)) {
            targetPropId = existingPropertyId;
            await supabase
              .from("properties")
              .update({
                default_monthly_rent: closingPrice,
                default_deposit_amount: depositAmount || listing.deposit_amount || closingPrice,
                currency: cur,
                default_deposit_currency: cur,
                default_due_day: dueDay || 1,
                property_type: listing.property_type || "apartment",
                room_count: listing.room_count || null,
                area_sqm: listing.area_sqm || null,
                floor: listing.floor || null,
                total_floors: listing.total_floors || null,
                furnishing: listing.furnishing || "furnished",
                heating_type: listing.heating_type || "cg",
                amenities: Array.isArray(listing.amenities) ? listing.amenities : [],
                description: listing.description || null,
                is_detailed: true,
                ...(listingUuidOrNull ? { last_listing_id: listingUuidOrNull } : {}),
              })
              .eq("id", existingPropertyId);
          } else {
            const { data: insertedProp, error: propErr } = await supabase
              .from("properties")
              .insert({
                agency_id: userId,
                landlord_id: userId,
                title: listing.title || "Kiralık Daire",
                name: listing.title || "Kiralık Daire",
                address:
                  listing.address ||
                  [listing.neighborhood, listing.municipality, listing.city].filter(Boolean).join(", ") ||
                  "Beograd",
                city: listing.city || "Beograd",
                property_type: listing.property_type || "apartment",
                room_count: listing.room_count || null,
                area_sqm: listing.area_sqm || null,
                floor: listing.floor || null,
                total_floors: listing.total_floors || null,
                furnishing: listing.furnishing || "furnished",
                heating_type: listing.heating_type || "cg",
                amenities: Array.isArray(listing.amenities) ? listing.amenities : [],
                description: listing.description || null,
                is_detailed: true,
                default_monthly_rent: closingPrice,
                default_deposit_amount: depositAmount || listing.deposit_amount || closingPrice,
                currency: cur,
                default_deposit_currency: cur,
                default_due_day: dueDay || 1,
                expenses_template: defaultExpensesTemplate,
                landlord_name: landlordName || null,
                landlord_phone: landlordPhone || null,
                landlord_email: landlordEmail || null,
                ...(listingUuidOrNull ? { last_listing_id: listingUuidOrNull } : {}),
              })
              .select("id")
              .single();

            if (!propErr && insertedProp) {
              targetPropId = insertedProp.id;
            }
          }

          if (createContract && resolvedTenantName && targetPropId && isValidUuid(targetPropId)) {
            const generatedToken = `tenant_${Date.now()}_${Math.floor(Math.random() * 99999)}`;
            const { data: insertedCtr, error: ctrErr } = await supabase
              .from("contracts")
              .insert({
                property_id: targetPropId,
                ...(listingUuidOrNull ? { source_listing_id: listingUuidOrNull } : {}),
                landlord_id: userId,
                agency_id: userId,
                inviter_name: agencyName || "Stanomer",
                invitee_email: tenantEmail || null,
                token: generatedToken,
                tenant_name: resolvedTenantName,
                tenant_phone: tenantPhone || null,
                tenant_notes: closingNotes || null,
                monthly_rent: closingPrice,
                deposit_amount: depositAmount || listing.deposit_amount || closingPrice,
                currency: cur,
                deposit_currency: cur,
                due_day: dueDay || 1,
                start_date: startDate || nowIso.split("T")[0],
                end_date: endDate || nowIso.split("T")[0],
                expenses_config: defaultExpensesTemplate,
                status: "active",
              })
              .select("id")
              .single();

            if (!ctrErr && insertedCtr) {
              createdContractId = insertedCtr.id;
              try {
                await supabase.rpc("generate_missing_rent_payments", { p_property_id: targetPropId });
              } catch { }
            }
          }
        }

        if (listingUuidOrNull) {
          await supabase
            .from("listings")
            .update({
              is_published: false,
              listing_status: closingStatus,
              closed_at: nowIso,
              closing_price: closingPrice,
              closing_notes: closingNotes || null,
              managed_property_id: isValidUuid(targetPropId) ? targetPropId : null,
              closing_contract_id: isValidUuid(createdContractId) ? createdContractId : null,
            })
            .eq("id", listingUuidOrNull)
            .eq("agency_id", userId);
        }
      } catch (err) {
        console.warn("Supabase handover sync warning (continuing with local state update):", err);
      }
    }

    // 2. Always update immediate React state & localStorage so both Live and Demo listings/properties reflect changes instantly
    const defaultHandoverExpenses = [
      { name: "Infostan", receiver: "owner" as const, amount: 0, payment_method: "bank_transfer" as const },
      { name: "Struja", receiver: "owner" as const, amount: 0, payment_method: "bank_transfer" as const },
      { name: "Internet & TV", receiver: "included" as const, amount: 0, payment_method: "bank_transfer" as const },
      { name: "Održavanje zgrade", receiver: "included" as const, amount: 0, payment_method: "bank_transfer" as const },
    ];
    if (handoverToPm) {
      if (targetPropertyMode === "existing" && existingPropertyId) {
        targetPropId = targetPropId || existingPropertyId;
        setManagedProperties((prev) => {
          const next = prev.map((mp) => {
            if (mp.id === existingPropertyId) {
              const updatedMp: AgencyManagedProperty = {
                ...mp,
                property_type: listing.property_type || mp.property_type || "apartment",
                room_count: listing.room_count || mp.room_count || "2.0",
                area_sqm: listing.area_sqm || mp.area_sqm || null,
                floor: listing.floor || mp.floor || null,
                total_floors: listing.total_floors ?? mp.total_floors ?? null,
                furnishing: listing.furnishing || mp.furnishing || "furnished",
                heating_type: listing.heating_type || mp.heating_type || "cg",
                amenities: Array.isArray(listing.amenities) && listing.amenities.length > 0 ? listing.amenities : (mp.amenities || []),
                description: listing.description || mp.description || null,
                is_detailed: true,
                default_monthly_rent: closingPrice || mp.default_monthly_rent,
                default_deposit_amount: depositAmount || listing.deposit_amount || closingPrice || mp.default_deposit_amount,
                currency: cur || mp.currency || "EUR",
                default_deposit_currency: cur || mp.default_deposit_currency || "EUR",
                default_due_day: dueDay || mp.default_due_day || 1,
                last_listing_id: listing.id,
                is_occupied: createContract ? true : mp.is_occupied,
                active_tenant_name: createContract && resolvedTenantName ? resolvedTenantName : mp.active_tenant_name,
                active_tenant_phone: createContract && tenantPhone ? tenantPhone : mp.active_tenant_phone,
                contract_end_date: createContract && endDate ? endDate : mp.contract_end_date,
              };
              handedOverPropObj = updatedMp;
              return updatedMp;
            }
            return mp;
          });
          if (typeof window !== "undefined") {
            try {
              localStorage.setItem("stanomer_agency_managed_props_demo", JSON.stringify(next));
            } catch { }
          }
          return next;
        });
      } else {
        targetPropId = targetPropId || `demo-mp-${Date.now()}`;
        const newProp: AgencyManagedProperty = {
          id: targetPropId,
          agency_id: userId || "demo",
          landlord_id: userId || "demo-landlord",
          tenant_id: createContract ? `demo-tenant-${Date.now()}` : null,
          landlord_name: landlordName || "Miloš Petrović",
          landlord_phone: landlordPhone || "+381 64 112 2334",
          landlord_email: landlordEmail || null,
          title: listing.title || "Kiralık Daire",
          address:
            listing.address ||
            [listing.neighborhood, listing.municipality, listing.city].filter(Boolean).join(", ") ||
            "Beograd",
          city: listing.city || "Beograd",
          property_type: listing.property_type || "apartment",
          room_count: listing.room_count || "2.0",
          area_sqm: listing.area_sqm || null,
          floor: listing.floor || null,
          total_floors: listing.total_floors || null,
          furnishing: listing.furnishing || "furnished",
          heating_type: listing.heating_type || "cg",
          amenities: Array.isArray(listing.amenities) ? listing.amenities : [],
          description: listing.description || null,
          is_detailed: true,
          default_monthly_rent: closingPrice,
          default_deposit_amount: depositAmount || listing.deposit_amount || closingPrice,
          currency: cur,
          default_deposit_currency: cur,
          default_due_day: dueDay || 1,
          expenses_template: defaultHandoverExpenses,
          is_occupied: Boolean(createContract),
          active_contract_id: null,
          active_tenant_name: createContract ? resolvedTenantName : null,
          active_tenant_phone: createContract && tenantPhone ? tenantPhone : null,
          contract_end_date: createContract && endDate ? endDate : null,
          last_listing_id: listing.id,
          created_at: nowIso,
        };
        handedOverPropObj = newProp;
        setManagedProperties((prev) => {
          const next = [newProp, ...prev.filter((p) => p.id !== newProp.id)];
          if (typeof window !== "undefined") {
            try {
              localStorage.setItem("stanomer_agency_managed_props_demo", JSON.stringify(next));
            } catch { }
          }
          return next;
        });
      }

      if (createContract && resolvedTenantName && targetPropId) {
        createdContractId = createdContractId || `demo-ctr-${Date.now()}`;
        const propObj = handedOverPropObj || managedProperties.find((mp) => mp.id === targetPropId);
        const newContract: AgencyContract = {
          id: createdContractId,
          property_id: targetPropId,
          source_listing_id: listing.id,
          property_title: propObj?.title || listing.title || "Daire",
          property_address: propObj?.address || listing.address || "Beograd",
          landlord_id: userId || "demo-landlord",
          tenant_id: `demo-tenant-${Date.now()}`,
          agency_id: userId || "demo",
          invitee_email: tenantEmail || null,
          tenant_name: resolvedTenantName,
          tenant_phone: tenantPhone || null,
          tenant_notes: closingNotes || null,
          monthly_rent: closingPrice,
          deposit_amount: depositAmount || listing.deposit_amount || closingPrice,
          currency: cur,
          deposit_currency: cur,
          due_day: dueDay || 1,
          start_date: startDate || nowIso.split("T")[0],
          end_date: endDate || nowIso.split("T")[0],
          status: "active",
          expenses_config: propObj?.expenses_template?.length ? propObj.expenses_template : defaultHandoverExpenses,
          created_at: nowIso,
        };
        setContracts((prev) => {
          const next = [newContract, ...prev.filter((c) => c.id !== newContract.id)];
          if (typeof window !== "undefined") {
            try {
              localStorage.setItem("stanomer_agency_contracts_demo", JSON.stringify(next));
            } catch { }
          }
          return next;
        });
        setManagedProperties((prev) => {
          const next = prev.map((mp) => {
            if (mp.id === targetPropId) {
              const updatedMp = {
                ...mp,
                active_contract_id: createdContractId,
                is_occupied: true,
                active_tenant_name: resolvedTenantName,
              };
              handedOverPropObj = updatedMp;
              return updatedMp;
            }
            return mp;
          });
          if (typeof window !== "undefined") {
            try {
              localStorage.setItem("stanomer_agency_managed_props_demo", JSON.stringify(next));
            } catch { }
          }
          return next;
        });
      }
    }

    const updatedListing: AgencyListingRow = {
      ...listing,
      is_published: false,
      listing_status: closingStatus,
      closed_at: nowIso,
      closing_price: closingPrice,
      closing_notes: closingNotes || null,
      managed_property_id: targetPropId || listing.managed_property_id || null,
      closing_contract_id: createdContractId || listing.closing_contract_id || null,
    };

    const currentListings =
      Array.isArray(listings) && listings.length > 0
        ? listings
        : (() => {
          try {
            const saved = JSON.parse(localStorage.getItem("stanomer_agency_listings_demo") || "[]");
            return Array.isArray(saved) && saved.length > 0 ? saved : DEMO_AGENCY_LISTINGS;
          } catch {
            return DEMO_AGENCY_LISTINGS;
          }
        })();

    const nextListings = currentListings.map((row) =>
      row.id === listing.id ? updatedListing : row
    );
    setListings(nextListings);

    if (!hasRealSupabaseUser) {
      if (typeof window !== "undefined") {
        try {
          localStorage.setItem("stanomer_agency_listings_demo", JSON.stringify(nextListings));
        } catch { }
      }
    }

    setStatusMessage({
      type: "success",
      text: handoverToPm ? t("agency_bridge_msg_handover_success") : t("agency_bridge_msg_closed_success"),
    });
  };

  const handleQuickRelistProperty = async (params: {
    property: AgencyManagedProperty;
    linkedListing: AgencyListingRow | null;
    title: string;
    price: number;
    currency: string;
    mode: "instant_publish" | "open_form";
  }) => {
    const { property, linkedListing, title: newTitle, price: newPrice, currency: newCur, mode } = params;

    if (mode === "open_form") {
      if (linkedListing) {
        loadListingIntoForm({
          ...linkedListing,
          title: newTitle,
          price: newPrice,
          currency: newCur,
          managed_property_id: property.id,
          is_published: true,
        });
      } else {
        setEditingId(null);
        setTransactionType("izdavanje");
        setPropertyType(property.property_type || "apartment");
        setTitle(newTitle || property.title || "");
        setDescription(property.description || "");
        setAddress(property.address || "");
        setCity(property.city || "Beograd");
        setPrice(newPrice ? String(newPrice) : "");
        setCurrency(newCur || "EUR");
        setAreaSqm(property.area_sqm ? String(property.area_sqm) : "");
        setRoomCount(property.room_count || "2.0");
        if (property.floor) setFloor(property.floor);
        if (property.total_floors != null) setTotalFloors(String(property.total_floors));
        if (property.heating_type) setHeatingType(property.heating_type);
        if (property.furnishing) setFurnishing(property.furnishing);
        if (Array.isArray(property.amenities) && property.amenities.length > 0) {
          setSelectedAmenities(property.amenities);
        }
        setIsPublished(true);
        setActiveTab("form");
      }
      return;
    }

    if (!checkEffectiveDemoVerified()) {
      setIsGatekeeperModalOpen(true);
      return;
    }

    if (isDemoMode && (!userId || userId === "demo")) {
      let targetListingId = linkedListing?.id || `demo-prop-${Date.now()}`;
      let nextListings: AgencyListingRow[] = [];

      if (linkedListing) {
        nextListings = listings.map((row) =>
          row.id === linkedListing.id
            ? {
              ...row,
              title: newTitle,
              price: newPrice,
              currency: newCur,
              property_type: property.property_type || row.property_type || "apartment",
              area_sqm: property.area_sqm ?? row.area_sqm,
              room_count: property.room_count || row.room_count || "2.0",
              floor: property.floor || row.floor,
              total_floors: property.total_floors ?? row.total_floors,
              heating_type: property.heating_type || row.heating_type || "cg",
              furnishing: property.furnishing || row.furnishing || "furnished",
              amenities: Array.isArray(property.amenities) && property.amenities.length > 0 ? property.amenities : row.amenities,
              description: property.description || row.description,
              managed_property_id: property.id,
              is_published: true,
              listing_status: "active",
            }
            : row
        );
      } else {
        const createdDemoListing: AgencyListingRow = {
          id: targetListingId,
          agency_id: "demo",
          managed_property_id: property.id,
          external_ref: `BG-${Math.floor(100 + Math.random() * 900)}`,
          title: newTitle,
          description: property.description || property.address || "",
          transaction_type: "izdavanje",
          property_type: property.property_type || "apartment",
          price: newPrice,
          deposit_amount: property.default_deposit_amount || newPrice,
          currency: newCur,
          area_sqm: property.area_sqm || null,
          room_count: property.room_count || "2.0",
          floor: property.floor || null,
          total_floors: property.total_floors || null,
          heating_type: property.heating_type || "cg",
          condition: "renovirano",
          furnishing: property.furnishing || "furnished",
          city: property.city || "Beograd",
          municipality: null,
          neighborhood: null,
          address: property.address || "",
          amenities: Array.isArray(property.amenities) ? property.amenities : [],
          is_published: true,
          listing_status: "active",
          published_portals: ["stanomer", "4zida", "halooglasi", "sasomange", "nekretnine"],
          created_at: new Date().toISOString(),
          listing_images: [],
        };
        nextListings = [createdDemoListing, ...listings];
      }

      setListings(nextListings);
      setManagedProperties((prev) =>
        prev.map((mp) => (mp.id === property.id ? { ...mp, last_listing_id: targetListingId } : mp))
      );

      if (typeof window !== "undefined") {
        try {
          localStorage.setItem("stanomer_agency_listings_demo", JSON.stringify(nextListings));
        } catch { }
      }

      setStatusMessage({
        type: "success",
        text: linkedListing
          ? t("agency_bridge_relist_success_updated")
          : t("agency_bridge_relist_success_created"),
      });
      return;
    }

    try {
      let targetListingId = linkedListing?.id || null;

      if (linkedListing) {
        const { error: updErr } = await supabase
          .from("listings")
          .update({
            title: newTitle,
            price: newPrice,
            currency: newCur,
            managed_property_id: property.id,
            is_published: true,
            listing_status: "active",
          })
          .eq("id", linkedListing.id)
          .eq("agency_id", userId);
        if (updErr) throw updErr;
      } else {
        const { data: inserted, error: insErr } = await supabase
          .from("listings")
          .insert({
            agency_id: userId,
            managed_property_id: property.id,
            external_ref: `BG-${Math.floor(100 + Math.random() * 900)}`,
            title: newTitle,
            description: property.description || property.address || null,
            transaction_type: "izdavanje",
            property_type: property.property_type || "apartment",
            price: newPrice,
            deposit_amount: property.default_deposit_amount || newPrice,
            currency: newCur,
            area_sqm: property.area_sqm || null,
            room_count: property.room_count || "2.0",
            floor: property.floor || null,
            total_floors: property.total_floors || null,
            heating_type: property.heating_type || "cg",
            furnishing: property.furnishing || "furnished",
            amenities: Array.isArray(property.amenities) ? property.amenities : [],
            city: property.city || "Beograd",
            address: property.address || "",
            is_published: true,
            listing_status: "active",
            published_portals: ["stanomer", "4zida", "halooglasi", "sasomange", "nekretnine"],
          })
          .select("id")
          .single();
        if (insErr) throw insErr;
        targetListingId = inserted.id;
      }

      if (targetListingId) {
        await supabase
          .from("properties")
          .update({ last_listing_id: targetListingId, default_monthly_rent: newPrice })
          .eq("id", property.id);
      }

      await Promise.all([fetchAgencyListings(userId), loadAgencyManagedProperties(userId)]);

      setStatusMessage({
        type: "success",
        text: linkedListing
          ? t("agency_bridge_relist_success_updated")
          : t("agency_bridge_relist_success_created"),
      });
    } catch (err: any) {
      console.error("Quick relist property error:", err);
      setStatusMessage({
        type: "error",
        text: err?.message || t("agency_panel_msg_save_error"),
      });
    }
  };

  async function loadAgencyMaintenance(uid: string) {
    if (!uid || uid === "demo") {
      setMaintenanceRequests(DEMO_AGENCY_MAINTENANCE_REQUESTS);
      return;
    }
    setLoadingMaintenance(true);
    try {
      const { data: props, error: propsErr } = await supabase
        .from("properties")
        .select("id, title, address, city, tenant_id")
        .eq("agency_id", uid);

      if (propsErr) {
        console.warn("Could not fetch properties for maintenance:", propsErr?.message || propsErr);
        setMaintenanceRequests([]);
        return;
      }

      const propMap = new Map((props || []).map((p: any) => [p.id, p]));
      const propIds = Array.from(propMap.keys());

      if (propIds.length === 0) {
        setMaintenanceRequests([]);
        return;
      }

      const { data: reqs, error: reqsErr } = await supabase
        .from("maintenance_requests")
        .select("*")
        .in("property_id", propIds)
        .order("created_at", { ascending: false })
        .limit(100);

      if (reqsErr) {
        console.warn("Could not fetch maintenance requests:", reqsErr?.message || reqsErr);
        setMaintenanceRequests([]);
        return;
      }

      // Fetch reporter profiles separately to avoid PostgREST foreign key relationship errors
      const reporterIds = Array.from(
        new Set((reqs || []).map((r: any) => r.reporter_id).filter(Boolean))
      );
      let profileMap = new Map<string, { full_name?: string; phone?: string }>();
      if (reporterIds.length > 0) {
        const { data: profs } = await supabase
          .from("profiles")
          .select("id, full_name, phone_number")
          .in("id", reporterIds);
        if (profs) {
          profileMap = new Map(
            profs.map((pr: any) => [
              pr.id,
              { full_name: pr.full_name, phone: pr.phone_number },
            ])
          );
        }
      }

      // Fetch maintenance_charges in one batch to derive declaration_intent accurately
      const reqIds = (reqs || []).map((r: any) => r.id).filter(Boolean);
      const chargeByReqId = new Map<string, any>();
      if (reqIds.length > 0) {
        const { data: chargeRows } = await supabase
          .from("maintenance_charges")
          .select("maintenance_request_id, charge_type, debtor_id")
          .in("maintenance_request_id", reqIds);
        (chargeRows || []).forEach((c: any) => {
          if (c.maintenance_request_id && !chargeByReqId.has(c.maintenance_request_id)) {
            chargeByReqId.set(c.maintenance_request_id, c);
          }
        });
      }

      const formatted: AgencyMaintenanceRequest[] = (reqs || []).map((r: any) => {
        const prop = propMap.get(r.property_id);
        const profile = r.reporter_id ? profileMap.get(r.reporter_id) : null;
        const charge = chargeByReqId.get(r.id);
        let derivedIntent: string | null = r.declaration_intent || null;
        if (!derivedIntent && r.paid_by === "agency") {
          derivedIntent =
            charge && charge.debtor_id && charge.debtor_id !== prop?.landlord_id
              ? "damage_tenant"
              : "fixture_landlord";
        } else if (!derivedIntent && r.paid_by === "tenant" && charge) {
          derivedIntent =
            charge.charge_type === "direct_charge" && charge.debtor_id === prop?.tenant_id
              ? "self"
              : "reimburse";
        } else if (!derivedIntent && r.paid_by === "landlord" && charge) {
          derivedIntent =
            charge.debtor_id && charge.debtor_id === prop?.landlord_id
              ? "self"
              : "tenant_due";
        }
        return {
          id: r.id,
          ticket_number: r.ticket_number || `MR-${r.id.slice(0, 5).toUpperCase()}`,
          property_id: r.property_id,
          property_title: prop?.title || "Daire",
          property_address: prop?.address ? `${prop.address}${prop.city ? `, ${prop.city}` : ""}` : "",
          reporter_id: r.reporter_id,
          reporter_name: profile?.full_name || null,
          reporter_phone: profile?.phone || null,
          title: r.title || "Bakım Talebi",
          description: r.description,
          category: r.category || "other",
          priority: r.priority || "normal",
          status: r.status || "open",
          photos_urls: r.photos_urls || r.photo_urls || [],
          cost_amount: r.cost_amount ? Number(r.cost_amount) : null,
          settled_amount: r.settled_amount ? Number(r.settled_amount) : 0,
          currency: r.currency || "EUR",
          paid_by: r.paid_by,
          payment_status: r.payment_status,
          payment_date: r.payment_date || null,
          invoice_pdf_url: r.invoice_pdf_url || null,
          rejection_reason: r.rejection_reason || null,
          declaration_intent: derivedIntent,
          created_at: r.created_at || new Date().toISOString(),
          resolved_at: r.resolved_at,
        };
      });

      setMaintenanceRequests(formatted);
    } catch (err: any) {
      console.error("Error loading agency maintenance requests:", err?.message || err?.details || err);
      setMaintenanceRequests([]);
    } finally {
      setLoadingMaintenance(false);
    }
  }

  async function handleUpdateMaintenanceStatus(reqId: string, newStatus: AgencyMaintenanceRequest["status"]) {
    if (!checkEffectiveDemoVerified()) {
      setIsGatekeeperModalOpen(true);
      return;
    }
    setUpdatingMaintId(reqId);
    try {
      if (userId && userId !== "demo") {
        const updates: any = { status: newStatus, updated_at: new Date().toISOString() };
        if (newStatus === "resolved") {
          updates.resolved_at = new Date().toISOString();
        } else if (newStatus === "open") {
          updates.resolved_at = null;
        }
        const { error } = await supabase.from("maintenance_requests").update(updates).eq("id", reqId);
        if (error) throw error;
      }
      setMaintenanceRequests((prev) =>
        prev.map((m) =>
          m.id === reqId
            ? {
              ...m,
              status: newStatus,
              resolved_at: newStatus === "resolved" ? new Date().toISOString() : newStatus === "open" ? null : m.resolved_at,
            }
            : m
        )
      );
      setStatusMessage({
        type: "success",
        text: t("agency_maint_msg_status_updated"),
      });
    } catch (err) {
      console.error("Update maintenance status error:", err);
      setStatusMessage({
        type: "error",
        text: t("agency_panel_msg_save_error"),
      });
    } finally {
      setUpdatingMaintId(null);
    }
  }

  async function handleCreateMaintenanceRequest(e: React.FormEvent) {
    e.preventDefault();
    if (!checkEffectiveDemoVerified()) {
      setIsGatekeeperModalOpen(true);
      return;
    }
    if (!newMaintPropId || !newMaintTitle.trim()) return;

    setCreatingMaint(true);
    try {
      const selectedProp = managedProperties.find((p) => p.id === newMaintPropId);
      const costNum = newMaintHasExpense && newMaintCost ? parseFloat(newMaintCost) : null;
      const targetPayer = newMaintHasExpense ? newMaintPayer : null;
      const targetIntent = newMaintHasExpense ? newMaintIntent : null;
      const targetStatus = !newMaintHasExpense
        ? "pending_review"
        : newMaintIntent === "self"
          ? "paid"
          : "pending_payment";
      const targetDate =
        newMaintHasExpense && newMaintPaymentDate
          ? new Date(newMaintPaymentDate).toISOString()
          : null;

      let invoiceUrl: string | null = null;
      if (newMaintHasExpense && newMaintInvoiceFile && userId && userId !== "demo") {
        const fileExt = newMaintInvoiceFile.name.split(".").pop();
        const fPath = `maintenance/${newMaintPropId}/${Date.now()}.${fileExt}`;
        const { error: upErr } = await supabase.storage
          .from("maintenance-docs")
          .upload(fPath, newMaintInvoiceFile);
        if (!upErr) {
          const { data: pubData } = supabase.storage
            .from("maintenance-docs")
            .getPublicUrl(fPath);
          invoiceUrl = pubData?.publicUrl || null;
        }
      }

      const ticketNum = `MR-${Math.floor(10000 + Math.random() * 90000)}`;

      let newReq: AgencyMaintenanceRequest;

      if (userId && userId !== "demo") {
        const { data, error } = await supabase
          .from("maintenance_requests")
          .insert({
            property_id: newMaintPropId,
            reporter_id: userId,
            title: newMaintTitle.trim(),
            description: newMaintDescription.trim() || null,
            category: newMaintCategory,
            priority: newMaintPriority,
            status: "open",
            cost_amount: costNum,
            currency: newMaintCurrency,
            paid_by: targetPayer,
            payment_status: targetStatus,
            payment_date: targetDate,
            invoice_pdf_url: invoiceUrl,
          })
          .select()
          .single();

        if (error) throw error;

        // Create maintenance_charge if expense was declared
        if (costNum && selectedProp) {
          let chargeType: "direct_charge" | "agency_advance" | "reimbursement" = "direct_charge";
          let debtorId = selectedProp.tenant_id;
          let creditorId = selectedProp.landlord_id;

          if (targetPayer === "agency") {
            chargeType = "agency_advance";
            debtorId =
              targetIntent === "fixture_landlord"
                ? selectedProp.landlord_id
                : selectedProp.tenant_id;
            creditorId = selectedProp.agency_id || userId;
          } else if (targetPayer === "tenant") {
            chargeType = targetIntent === "self" ? "direct_charge" : "reimbursement";
            debtorId =
              targetIntent === "self"
                ? selectedProp.tenant_id
                : selectedProp.landlord_id;
            creditorId = selectedProp.tenant_id;
          }

          const settlementMethod =
            targetIntent === "self" ? "separate_payment" : "rent_offset";
          const chargeStatus = targetStatus === "paid" ? "paid" : "approved";

          await supabase.from("maintenance_charges").insert({
            maintenance_request_id: data.id,
            property_id: newMaintPropId,
            created_by: userId,
            title: newMaintTitle.trim(),
            charge_type: chargeType,
            approver_role: "agency",
            debtor_id: debtorId,
            creditor_id: creditorId,
            amount: costNum,
            currency: newMaintCurrency,
            status: chargeStatus,
            settlement_method: settlementMethod,
            receipt_url: invoiceUrl,
            paid_at: targetStatus === "paid" ? targetDate : null,
          });
        }

        newReq = {
          id: data.id,
          ticket_number: data.ticket_number || ticketNum,
          property_id: newMaintPropId,
          property_title: selectedProp?.title || "Daire",
          property_address: selectedProp?.address
            ? `${selectedProp.address}${selectedProp.city ? `, ${selectedProp.city}` : ""}`
            : "",
          reporter_name: agencyName,
          title: data.title,
          description: data.description,
          category: data.category,
          priority: data.priority,
          status: data.status,
          cost_amount: data.cost_amount ? Number(data.cost_amount) : null,
          currency: newMaintCurrency,
          paid_by: data.paid_by,
          declaration_intent: data.declaration_intent,
          payment_status: data.payment_status,
          payment_date: data.payment_date,
          invoice_pdf_url: data.invoice_pdf_url,
          created_at: data.created_at,
        };
      } else {
        newReq = {
          id: `demo-mr-${Date.now()}`,
          ticket_number: ticketNum,
          property_id: newMaintPropId,
          property_title: selectedProp?.title || "Daire",
          property_address: selectedProp?.address
            ? `${selectedProp.address}${selectedProp.city ? `, ${selectedProp.city}` : ""}`
            : "",
          reporter_name: selectedProp?.active_tenant_name || agencyName,
          reporter_phone: selectedProp?.active_tenant_phone || agencyPhone,
          title: newMaintTitle.trim(),
          description: newMaintDescription.trim() || null,
          category: newMaintCategory,
          priority: newMaintPriority,
          status: "open",
          cost_amount: costNum,
          currency: newMaintCurrency,
          paid_by: targetPayer,
          declaration_intent: targetIntent,
          payment_status: targetStatus,
          payment_date: targetDate,
          invoice_pdf_url: invoiceUrl,
          created_at: new Date().toISOString(),
        };
      }

      setMaintenanceRequests((prev) => [newReq, ...prev]);
      setIsNewMaintModalOpen(false);
      setNewMaintTitle("");
      setNewMaintDescription("");
      setNewMaintHasExpense(false);
      setNewMaintCost("");
      setNewMaintInvoiceFile(null);
      setStatusMessage({
        type: "success",
        text: t("agency_maint_msg_created"),
      });
    } catch (err) {
      console.error("Create maintenance request error:", err);
      setStatusMessage({
        type: "error",
        text: t("agency_panel_msg_save_error"),
      });
    } finally {
      setCreatingMaint(false);
    }
  }

  async function handleUpdateLeadStatus(
    leadId: string,
    newStatus: AgencyLead["status"]
  ) {
    if (!checkEffectiveDemoVerified()) {
      setIsGatekeeperModalOpen(true);
      return;
    }
    setListingsLeads((prev) =>
      prev.map((l) => (l.id === leadId ? { ...l, status: newStatus } : l))
    );
    const currentKey = userId
      ? `stanomer_agency_leads_${userId}`
      : "stanomer_agency_leads_demo";
    try {
      const stored = JSON.parse(localStorage.getItem(currentKey) || "[]");
      const updated = stored.map((l: AgencyLead) =>
        l.id === leadId ? { ...l, status: newStatus } : l
      );
      localStorage.setItem(currentKey, JSON.stringify(updated));
      const demoStored = JSON.parse(
        localStorage.getItem("stanomer_agency_leads_demo") || "[]"
      );
      const demoUpdated = demoStored.map((l: AgencyLead) =>
        l.id === leadId ? { ...l, status: newStatus } : l
      );
      localStorage.setItem(
        "stanomer_agency_leads_demo",
        JSON.stringify(demoUpdated)
      );
    } catch { }
    try {
      await supabase
        .from("agency_leads")
        .update({ status: newStatus })
        .eq("id", leadId);
    } catch { }
    setStatusMessage({
      type: "success",
      text: t("agency_panel_leads_status_updated"),
    });
  }

  async function handleAddLeadComment(leadId: string) {
    if (!checkEffectiveDemoVerified()) {
      setIsGatekeeperModalOpen(true);
      return;
    }
    const text = (newCommentText[leadId] || "").trim();
    if (!text) return;

    const author = agencyName || agencyEmail?.split("@")[0] || "Acente Yetkilisi";
    const newComment: LeadComment = {
      id: `cmt-${Date.now()}-${Math.floor(Math.random() * 1000)}`,
      author_name: author,
      text,
      created_at: new Date().toISOString(),
    };

    let updatedComments: LeadComment[] = [];

    setListingsLeads((prev) =>
      prev.map((l) => {
        if (l.id === leadId) {
          updatedComments = [...(l.comments || []), newComment];
          return { ...l, comments: updatedComments };
        }
        return l;
      })
    );

    setNewCommentText((prev) => ({ ...prev, [leadId]: "" }));

    const currentKey = userId
      ? `stanomer_agency_leads_${userId}`
      : "stanomer_agency_leads_demo";
    try {
      const stored = JSON.parse(localStorage.getItem(currentKey) || "[]");
      const updated = stored.map((l: AgencyLead) =>
        l.id === leadId ? { ...l, comments: updatedComments } : l
      );
      localStorage.setItem(currentKey, JSON.stringify(updated));
      const demoStored = JSON.parse(
        localStorage.getItem("stanomer_agency_leads_demo") || "[]"
      );
      const demoUpdated = demoStored.map((l: AgencyLead) =>
        l.id === leadId ? { ...l, comments: updatedComments } : l
      );
      localStorage.setItem(
        "stanomer_agency_leads_demo",
        JSON.stringify(demoUpdated)
      );
    } catch { }

    try {
      await supabase
        .from("agency_leads")
        .update({ comments: updatedComments })
        .eq("id", leadId);
    } catch { }
  }

  function handleConvertLeadToListing(lead: AgencyLead) {
    if (!checkEffectiveDemoVerified()) {
      setIsGatekeeperModalOpen(true);
      return;
    }
    resetForm();
    setEditingId(null);
    setConvertingLeadId(lead.id);
    const tx = lead.transaction_type || "prodaja";
    setTransactionType(tx);
    const prop = lead.property_type || "apartment";
    setPropertyType(prop);
    const propTitle = prop === "house" ? "Kuća" : "Stan";
    setTitle(`${propTitle} - ${lead.location || "Odlična lokacija"}`);
    if (lead.expected_price) setPrice(String(lead.expected_price));
    if (lead.area_sqm) setAreaSqm(String(lead.area_sqm));
    if (lead.location) {
      const parts = lead.location.split(",");
      if (parts[0]) setCity(parts[0].trim());
      if (parts[1]) setMunicipality(parts[1].trim());
      if (parts[2]) setNeighborhood(parts[2].trim());
    }
    setDescription(
      `Vlasnik: ${lead.client_name}\nTelefon: ${lead.client_phone}${lead.client_email ? `\nEmail: ${lead.client_email}` : ""
      }\n\nOpis vlasnika:\n${lead.notes || ""}`
    );
    setActiveTab("form");
    setStatusMessage({
      type: "success",
      text: `${lead.client_name} - ${t("agency_panel_converting_banner")}`,
    });
  }

  function activatePersonalDemoSandbox(info?: {
    agencyName?: string;
    email?: string;
    phone?: string;
    city?: string;
    expiresAt?: string;
    token?: string;
    focus?: "presales" | "aftersales" | "both";
    active_modules?: string[];
    locale?: string;
  }) {
    setIsDemoMode(true);
    setUserId("demo");
    if (info?.locale) {
      if (info.locale === "sr-Cyrl") setLang("SR_CYR");
      else if (info.locale === "en") setLang("EN");
      else if (info.locale === "ru") setLang("RU");
      else if (info.locale === "tr") setLang("TR");
      else if (info.locale === "sr") setLang("SR_LAT");
    }
    const name = info?.agencyName?.trim() || "Stanomer Demo Nekretnine";
    setAgencyName(name);
    setAgencyPhone(info?.phone || "+381 11 400 0000");
    setAgencyEmail(info?.email || "partner@stanomer.online");
    const cleanSlug = name.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "") || "demo";
    setAgencyWebsite(`https://${cleanSlug}.stanomer.online`);
    setAgencyLogoUrl("");
    setAgencyCity(info?.city || "Beograd");
    setAgencyAddress(info?.city ? `${info.city} Centar` : "Knez Mihailova 14, Stari Grad");
    setAgencySlug(cleanSlug);
    setShowcaseTemplate("stanomer_modern");
    setShowcasePalette("royal_blue");
    setShowcaseRadius("rounded");
    setContactChannels("both");

    const resolvedFocus = info?.focus || "both";
    setDemoFocus(resolvedFocus);
    let resolvedModules = info?.active_modules && info.active_modules.length > 0
      ? info.active_modules
      : resolvedFocus === "presales"
        ? ["portfolio_distribution"]
        : resolvedFocus === "aftersales"
          ? ["property_lease_management"]
          : ["portfolio_distribution", "property_lease_management"];

    if (typeof window !== "undefined") {
      try {
        const s = localStorage.getItem("stanomer_agency_demo");
        if (s) {
          const p = JSON.parse(s);
          p.slug = cleanSlug;
          if (p.active_modules && Array.isArray(p.active_modules) && p.active_modules.length > 0) {
            resolvedModules = Array.from(new Set([...resolvedModules, ...p.active_modules]));
          }
          localStorage.setItem("stanomer_agency_demo", JSON.stringify(p));
        }
      } catch { }
    }

    setActiveModules(resolvedModules);

    if (resolvedFocus === "presales") {
      setActiveTab("xml");
    } else if (resolvedFocus === "aftersales") {
      setActiveTab("managed_properties");
    } else {
      setActiveTab("pm_dashboard");
    }

    if (info?.expiresAt) {
      setDemoExpiresAt(info.expiresAt);
    } else {
      setDemoExpiresAt(new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString());
    }
    if (typeof window !== "undefined") {
      try {
        const storedListings = localStorage.getItem("stanomer_agency_listings_demo");
        if (storedListings) {
          const parsedL = JSON.parse(storedListings);
          if (Array.isArray(parsedL) && parsedL.length > 0) {
            setListings(parsedL);
          } else {
            setListings(DEMO_AGENCY_LISTINGS);
            localStorage.setItem("stanomer_agency_listings_demo", JSON.stringify(DEMO_AGENCY_LISTINGS));
          }
        } else {
          setListings(DEMO_AGENCY_LISTINGS);
          localStorage.setItem("stanomer_agency_listings_demo", JSON.stringify(DEMO_AGENCY_LISTINGS));
        }
      } catch {
        setListings(DEMO_AGENCY_LISTINGS);
      }
    } else {
      setListings(DEMO_AGENCY_LISTINGS);
    }
    loadAgencyLeads("demo");
    loadAgencyPayments("demo");
    loadAgencyManagedProperties("demo");
    loadAgencyContracts("demo");
    loadAgencyMaintenance("demo");
  }

  function activateDemoSandbox() {
    activatePersonalDemoSandbox();
  }

  async function handleSignIn(e: React.FormEvent) {
    e.preventDefault();
    setAuthError(null);
    setIsRoleError(false);
    setShowRoleErrorDetails(false);
    setAuthSuccess(null);
    setAuthLoading(true);
    try {
      const { data, error } = await supabase.auth.signInWithPassword({
        email: authEmail.trim(),
        password: authPassword,
      });
      if (error) throw error;
      if (data.user) {
        const access = await resolveAgencyAccess(data.user.id, data.user.user_metadata);
        if (!access.allowed || !access.effectiveAgencyId) {
          await supabase.auth.signOut();
          setUserId(null);
          setCurrentUser(null);
          setAgencyRole("agency_admin");
          setIsRoleError(true);
          throw new Error(t("agency_panel_err_only_agency_allowed"));
        }

        const effectiveId = access.effectiveAgencyId;
        setIsDemoMode(false);
        setAgencyRole(access.role);
        setUserId(effectiveId);
        setCurrentUser(data.user);
        await loadAgencyProfile(effectiveId, data.user.email);
        await fetchAgencyListings(effectiveId);
        await loadAgencyLeads(effectiveId);
        await loadAgencyPayments(effectiveId);
        await loadAgencyManagedProperties(effectiveId);
        await loadAgencyContracts(effectiveId);
        await loadAgencyMaintenance(effectiveId);
        await loadAgencyTasks(effectiveId);
        await loadTeamAssignees(effectiveId, data.user);
      }
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : t("agency_panel_msg_auth_error");
      setAuthError(msg);
    } finally {
      setAuthLoading(false);
    }
  }

  async function handleSignUp(e: React.FormEvent) {
    e.preventDefault();
    setAuthError(null);
    setAuthSuccess(null);
    setAuthLoading(true);
    try {
      const cleanEmail = authEmail.trim();
      const cleanCompany = signupCompany.trim();
      const cleanPhone = signupPhone.trim();
      const cleanWebsite = signupWebsite.trim();

      const { data, error } = await supabase.auth.signUp({
        email: cleanEmail,
        password: authPassword,
        options: {
          data: {
            full_name: cleanCompany,
            company_name: cleanCompany,
            role: "agency",
          },
        },
      });
      if (error) throw error;

      if (data.user) {
        const initialSlug = cleanCompany
          .toLowerCase()
          .replace(/[^a-z0-9]+/g, "-")
          .replace(/^-|-$/g, "");

        // Update/upsert agency profile fields
        await supabase.from("profiles").upsert(
          {
            id: data.user.id,
            email: cleanEmail,
            full_name: cleanCompany,
            company_name: cleanCompany,
            phone_number: cleanPhone || null,
            website_url: cleanWebsite || null,
            role: "agency",
            active_role: "agency",
            color_scheme: {
              slug: initialSlug,
              agencyName: cleanCompany,
              template: "stanomer_modern",
              palette: "royal_blue",
              radius: "rounded",
              contactChannels: "both",
            },
          },
          { onConflict: "id" }
        );

        // Link directory agency if selected and present in dev/target DB
        if (selectedDirAgency) {
          await supabase
            .from("agencies")
            .update({ profile_id: data.user.id, uses_stanomer: true })
            .eq("id", selectedDirAgency.id);
        }

        if (data.session) {
          setIsDemoMode(false);
          setUserId(data.user.id);
          await loadAgencyProfile(data.user.id, cleanEmail);
          await fetchAgencyListings(data.user.id);
          await loadAgencyLeads(data.user.id);
          await loadAgencyPayments(data.user.id);
          await loadAgencyManagedProperties(data.user.id);
          await loadAgencyContracts(data.user.id);
          await loadAgencyMaintenance(data.user.id);
        } else {
          setAuthSuccess(t("agency_panel_signup_success"));
          setAuthTab("signin");
        }
      }
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : t("agency_panel_msg_auth_error");
      setAuthError(msg);
    } finally {
      setAuthLoading(false);
    }
  }

  async function handleResetPassword(e: React.FormEvent) {
    e.preventDefault();
    setAuthError(null);
    setAuthSuccess(null);
    setAuthLoading(true);
    try {
      const cleanEmail = authEmail.trim().toLowerCase();
      if (resetStep === 1) {
        const { data: rpcRes, error: rpcErr } = await supabase.rpc("request_password_reset", {
          p_email: cleanEmail,
        });
        if (rpcErr) throw rpcErr;
        if (!rpcRes?.success) {
          const errCode = rpcRes?.error;
          if (errCode === "user_not_found") {
            throw new Error(t("agency_panel_reset_user_not_found"));
          }
          throw new Error(errCode || t("agency_panel_msg_auth_error"));
        }

        const origin =
          typeof window !== "undefined"
            ? window.location.origin
            : "https://www.stanomer.online";
        const mailRes = await fetch("/api/send-password-reset", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            email: cleanEmail,
            name: rpcRes.user_name || "",
            code: rpcRes.code,
            token: rpcRes.token,
            locale: lang,
            origin,
          }),
        });
        if (!mailRes.ok) {
          const mailErr = await mailRes.json().catch(() => ({}));
          throw new Error(mailErr?.error || t("agency_panel_msg_auth_error"));
        }

        setResetStep(2);
        setAuthSuccess(t("agency_panel_reset_code_sent_desc"));
      } else {
        if (resetNewPassword.length < 6) {
          throw new Error(t("agency_panel_password_length"));
        }
        if (resetNewPassword !== resetConfirmPassword) {
          throw new Error(t("agency_panel_password_mismatch"));
        }
        const { data: verifyRes, error: verifyErr } = await supabase.rpc("verify_and_reset_password", {
          p_email: cleanEmail,
          p_token_or_code: resetCode.trim(),
          p_new_password: resetNewPassword,
        });
        if (verifyErr) throw verifyErr;
        if (!verifyRes?.success) {
          const errCode = verifyRes?.error;
          if (errCode === "invalid_or_expired_code") {
            throw new Error(t("agency_panel_reset_invalid_code"));
          }
          if (errCode === "password_too_short") {
            throw new Error(t("agency_panel_password_length"));
          }
          throw new Error(errCode || t("agency_panel_msg_auth_error"));
        }

        setResetStep(1);
        setResetCode("");
        setResetNewPassword("");
        setResetConfirmPassword("");
        setAuthPassword("");
        setAuthTab("signin");
        setAuthSuccess(t("agency_panel_password_success"));
      }
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : t("agency_panel_msg_auth_error");
      setAuthError(msg);
    } finally {
      setAuthLoading(false);
    }
  }

  async function handleSaveAgencyProfile(e: React.FormEvent) {
    e.preventDefault();
    if (!checkEffectiveDemoVerified()) {
      setIsGatekeeperModalOpen(true);
      return;
    }
    if (typeof window !== "undefined") {
      try {
        localStorage.setItem(
          "stanomer_showcase_theme",
          JSON.stringify({
            template: showcaseTemplate,
            palette: showcasePalette,
            radius: showcaseRadius,
            slug: agencySlug.trim(),
            custom_domain: agencyCustomDomain.trim().toLowerCase(),
            contactChannels,
            agencyName: agencyName.trim(),
            agencyPhone: agencyPhone.trim(),
            agencyEmail: agencyEmail.trim(),
            agencyWebsite: agencyWebsite.trim(),
            agencyLogoUrl: agencyLogoUrl.trim(),
            agencyCity: agencyCity.trim(),
            agencyAddress: agencyAddress.trim(),
            languages: showcaseLanguages,
            currencies: showcaseCurrencies,
            default_currency: showcaseDefaultCurrency,
          })
        );
      } catch {
        // Ignore localStorage error
      }
    }
    if (!userId || userId === "demo") {
      setStatusMessage({ type: "success", text: t("agency_panel_profile_saved") });
      setShowProfilePanel(false);
      return;
    }
    setSavingProfile(true);
    setStatusMessage(null);
    try {
      const { error } = await supabase
        .from("profiles")
        .update({
          company_name: agencyName.trim(),
          full_name: agencyName.trim(),
          phone_number: agencyPhone.trim() || null,
          email: agencyEmail.trim() || null,
          website_url: agencyWebsite.trim() || null,
          logo_url: agencyLogoUrl.trim() || null,
          color_scheme: {
            template: showcaseTemplate,
            palette: showcasePalette,
            radius: showcaseRadius,
            slug: agencySlug.trim(),
            custom_domain: agencyCustomDomain.trim().toLowerCase(),
            contactChannels,
            city: agencyCity.trim(),
            address: agencyAddress.trim(),
            languages: showcaseLanguages,
            currencies: showcaseCurrencies,
            default_currency: showcaseDefaultCurrency,
          },
        })
        .eq("id", userId);
      if (error) throw error;
      setStatusMessage({ type: "success", text: t("agency_panel_profile_saved") });
      setShowProfilePanel(false);
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : t("agency_panel_msg_save_error");
      setStatusMessage({ type: "error", text: msg });
    } finally {
      setSavingProfile(false);
    }
  }

  async function handleLogoFileUpload(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (!file || !userId) return;
    if (userId === "demo") {
      setAgencyLogoUrl(URL.createObjectURL(file));
      e.target.value = "";
      return;
    }
    setUploadingLogo(true);
    try {
      const ext = file.name.split(".").pop() || "png";
      const filePath = `${userId}/logo_${Date.now()}.${ext}`;
      const { error: uploadErr } = await supabase.storage
        .from("property-photos")
        .upload(filePath, file, { upsert: true });
      if (uploadErr) throw uploadErr;
      const { data: pubData } = supabase.storage
        .from("property-photos")
        .getPublicUrl(filePath);
      setAgencyLogoUrl(pubData.publicUrl);
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : t("agency_panel_msg_upload_error");
      setStatusMessage({ type: "error", text: msg });
    } finally {
      setUploadingLogo(false);
      e.target.value = "";
    }
  }

  async function handleSignOut() {
    if (userId && userId !== "demo") {
      await supabase.auth.signOut();
    }
    if (typeof window !== "undefined") {
      localStorage.removeItem("stanomer_agency_demo");
    }
    setUserId(null);
    setCurrentUser(null);
    setIsDemoMode(false);
    setIsDemoVerified(false);
    setDemoExpiresAt(null);
    setListings([]);
  }

  function resetForm() {
    setEditingId(null);
    setTransactionType("izdavanje");
    setPropertyType("apartment");
    setExternalRef("");
    setTitle("");
    setDescription("");
    setPrice("");
    setCurrency("EUR");
    setAreaSqm("");
    setRoomCount("2.0");
    setFloor("2");
    setTotalFloors("5");
    setHeatingType("cg");
    setCondition("novogradnja");
    setFurnishing("furnished");
    setAddress("");
    setSelectedAmenities(["elevator", "balcony"]);
    setIsPublished(true);
    setImages([]);
    setManualImageUrl("");
  }

  function loadListingIntoForm(item: AgencyListingRow) {
    setEditingId(item.id);
    setTransactionType(item.transaction_type || "izdavanje");
    setPropertyType(item.property_type || "apartment");
    setExternalRef(item.external_ref || "");
    setTitle(item.title || "");
    setDescription(item.description || "");
    setPrice(String(item.price ?? ""));
    setCurrency(item.currency || "EUR");
    setAreaSqm(item.area_sqm ? String(item.area_sqm) : "");
    setRoomCount(item.room_count || "2.0");
    setFloor(item.floor || "1");
    setTotalFloors(item.total_floors ? String(item.total_floors) : "");
    setHeatingType(item.heating_type || "cg");
    setCondition(item.condition || "renovirano");
    setFurnishing(item.furnishing || "furnished");
    setCity(item.city || "Beograd");
    setMunicipality(item.municipality || "");
    setNeighborhood(item.neighborhood || "");
    setAddress(item.address || "");
    setSelectedAmenities(Array.isArray(item.amenities) ? item.amenities : []);
    setIsPublished(Boolean(item.is_published));
    setImages(Array.isArray(item.listing_images) ? [...item.listing_images] : []);
    setActiveTab("form");
    window.scrollTo({ top: 0, behavior: "smooth" });
  }

  function handleAddNewListingClick() {
    if (!checkEffectiveDemoVerified()) {
      setIsGatekeeperModalOpen(true);
      return;
    }
    resetForm();
    setActiveTab("form");
    window.scrollTo({ top: 0, behavior: "smooth" });
  }

  function readFileAsDataUrl(file: File): Promise<string> {
    return new Promise((resolve) => {
      const reader = new FileReader();
      reader.onload = (ev) => {
        const raw = ev.target?.result as string;
        if (!raw) {
          resolve(URL.createObjectURL(file));
          return;
        }
        const img = new Image();
        img.onload = () => {
          const maxDim = 1280;
          let { width, height } = img;
          if (width > maxDim || height > maxDim) {
            if (width > height) {
              height = Math.round((height * maxDim) / width);
              width = maxDim;
            } else {
              width = Math.round((width * maxDim) / height);
              height = maxDim;
            }
          }
          const canvas = document.createElement("canvas");
          canvas.width = width;
          canvas.height = height;
          const ctx = canvas.getContext("2d");
          if (ctx) {
            ctx.drawImage(img, 0, 0, width, height);
            resolve(canvas.toDataURL("image/jpeg", 0.82));
            return;
          }
          resolve(raw);
        };
        img.onerror = () => resolve(raw);
        img.src = raw;
      };
      reader.onerror = () => resolve(URL.createObjectURL(file));
      reader.readAsDataURL(file);
    });
  }

  async function processFiles(fileList: FileList | File[]) {
    const files = Array.from(fileList).filter((f) => f.type.startsWith("image/"));
    if (files.length === 0) return;

    setUploadingPhotos(true);
    setStatusMessage(null);
    try {
      if (!userId || userId === "demo") {
        const dataUrls = await Promise.all(files.map((f) => readFileAsDataUrl(f)));
        setImages((prev) => {
          const added: ListingImageRow[] = dataUrls.map((url, idx) => ({
            url,
            order_index: prev.length + idx,
            is_cover: prev.length === 0 && idx === 0,
          }));
          return [...prev, ...added];
        });
        return;
      }

      const uploadedRows: ListingImageRow[] = [];
      for (let i = 0; i < files.length; i++) {
        const file = files[i];
        const ext = file.name.split(".").pop() || "jpg";
        const filePath = `${userId || "demo"}/${Date.now()}_${i}.${ext}`;
        const { error: uploadError } = await supabase.storage
          .from("property-photos")
          .upload(filePath, file, { upsert: true });

        if (uploadError) {
          console.warn("Storage upload fallback:", uploadError);
          const dataUrl = await readFileAsDataUrl(file);
          uploadedRows.push({
            url: dataUrl,
            order_index: images.length + i,
            is_cover: images.length === 0 && i === 0,
          });
          continue;
        }

        const { data: publicUrlData } = supabase.storage
          .from("property-photos")
          .getPublicUrl(filePath);

        uploadedRows.push({
          url: publicUrlData.publicUrl,
          order_index: images.length + i,
          is_cover: images.length === 0 && i === 0,
        });
      }
      setImages((prev) => [...prev, ...uploadedRows]);
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : t("agency_panel_msg_upload_error");
      setStatusMessage({ type: "error", text: msg });
    } finally {
      setUploadingPhotos(false);
      if (photoInputRef.current) {
        photoInputRef.current.value = "";
      }
    }
  }

  function handleFileUpload(e: React.ChangeEvent<HTMLInputElement>) {
    if (e.target.files) {
      processFiles(e.target.files);
    }
  }

  function handleAddManualImageUrl() {
    const trimmed = manualImageUrl.trim();
    if (!trimmed) return;
    setImages((prev) => [
      ...prev,
      {
        url: trimmed,
        order_index: prev.length,
        is_cover: prev.length === 0,
      },
    ]);
    setManualImageUrl("");
  }

  function setCoverImage(index: number) {
    setImages((prev) =>
      prev.map((img, i) => ({
        ...img,
        is_cover: i === index,
      }))
    );
  }

  function removeImage(index: number) {
    setImages((prev) => {
      const filtered = prev.filter((_, i) => i !== index);
      if (filtered.length > 0 && !filtered.some((img) => img.is_cover)) {
        filtered[0].is_cover = true;
      }
      return filtered.map((img, idx) => ({ ...img, order_index: idx }));
    });
  }

  function moveImage(index: number, direction: -1 | 1) {
    setImages((prev) => {
      const targetIndex = index + direction;
      if (targetIndex < 0 || targetIndex >= prev.length) return prev;
      const copy = [...prev];
      const temp = copy[index];
      copy[index] = copy[targetIndex];
      copy[targetIndex] = temp;
      return copy.map((img, idx) => ({ ...img, order_index: idx }));
    });
  }

  async function handleDeleteListing(item: AgencyListingRow) {
    if (!checkEffectiveDemoVerified()) {
      setIsGatekeeperModalOpen(true);
      return;
    }
    if (typeof window !== "undefined" && !window.confirm(t("agency_panel_delete_confirm"))) {
      return;
    }
    if (isDemoMode && (!userId || userId === "demo")) {
      const currentListings = Array.isArray(listings) && listings.length > 0
        ? listings
        : (() => {
          try {
            const saved = JSON.parse(localStorage.getItem("stanomer_agency_listings_demo") || "[]");
            return Array.isArray(saved) && saved.length > 0 ? saved : DEMO_AGENCY_LISTINGS;
          } catch {
            return DEMO_AGENCY_LISTINGS;
          }
        })();
      const nextListings = currentListings.filter((row) => row.id !== item.id);
      setListings(nextListings);
      if (typeof window !== "undefined") {
        try {
          localStorage.setItem(
            "stanomer_agency_listings_demo",
            JSON.stringify(nextListings)
          );
        } catch { }
      }
      if (editingId === item.id) resetForm();
      setStatusMessage({ type: "success", text: t("agency_panel_msg_deleted") });
      return;
    }
    try {
      const { error } = await supabase
        .from("listings")
        .delete()
        .eq("id", item.id)
        .eq("agency_id", userId);
      if (error) throw error;
      setListings((prev) => prev.filter((row) => row.id !== item.id));
      if (editingId === item.id) resetForm();
      setStatusMessage({ type: "success", text: t("agency_panel_msg_deleted") });
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : t("agency_panel_msg_save_error");
      setStatusMessage({ type: "error", text: msg });
    }
  }

  async function handleSaveListing(e: React.FormEvent) {
    e.preventDefault();
    if (!checkEffectiveDemoVerified()) {
      setIsGatekeeperModalOpen(true);
      return;
    }
    if (!userId) return;

    setSavingListing(true);
    setStatusMessage(null);

    const numericPrice = Number(price) || 0;
    const numericArea = Number(areaSqm) || null;
    const numericTotalFloors = Number(totalFloors) || null;

    if (isDemoMode && (!userId || userId === "demo")) {
      const demoRecord: AgencyListingRow = {
        id: editingId || `demo-prop-${Date.now()}`,
        agency_id: "demo",
        external_ref: externalRef.trim() || `BG-${Math.floor(100 + Math.random() * 900)}`,
        title: title.trim(),
        description: description.trim(),
        transaction_type: transactionType,
        property_type: propertyType,
        price: numericPrice,
        currency,
        area_sqm: numericArea,
        room_count: roomCount,
        floor,
        total_floors: numericTotalFloors,
        heating_type: heatingType,
        condition,
        furnishing,
        city,
        municipality,
        neighborhood,
        address: address.trim(),
        amenities: selectedAmenities,
        is_published: isPublished,
        published_portals: ["stanomer", "4zida", "halooglasi", "sasomange", "nekretnine"],
        listing_images: images,
      };

      const currentListings = Array.isArray(listings) && listings.length > 0
        ? listings
        : (() => {
          try {
            const saved = JSON.parse(localStorage.getItem("stanomer_agency_listings_demo") || "[]");
            return Array.isArray(saved) && saved.length > 0 ? saved : DEMO_AGENCY_LISTINGS;
          } catch {
            return DEMO_AGENCY_LISTINGS;
          }
        })();

      const nextListings = editingId
        ? currentListings.map((item) => (item.id === editingId ? demoRecord : item))
        : [demoRecord, ...currentListings];

      setListings(nextListings);

      if (typeof window !== "undefined") {
        try {
          localStorage.setItem(
            "stanomer_agency_listings_demo",
            JSON.stringify(nextListings)
          );
        } catch { }
      }

      if (convertingLeadId) {
        const targetLeadId = convertingLeadId;
        const linkedId = demoRecord.id;
        const linkedTitle = demoRecord.title;
        const autoComment: LeadComment = {
          id: `cmt-auto-${Date.now()}`,
          author_name: "Stanomer CRM",
          text: `${t("agency_panel_lead_converted_comment")}: "${linkedTitle}"`,
          created_at: new Date().toISOString(),
        };

        setListingsLeads((prev) =>
          prev.map((l) =>
            l.id === targetLeadId
              ? {
                ...l,
                status: "converted",
                listing_id: linkedId,
                listing_title: linkedTitle,
                comments: [...(l.comments || []), autoComment],
              }
              : l
          )
        );

        try {
          const demoStored = JSON.parse(
            localStorage.getItem("stanomer_agency_leads_demo") || "[]"
          );
          const demoUpdated = demoStored.map((l: AgencyLead) =>
            l.id === targetLeadId
              ? {
                ...l,
                status: "converted",
                listing_id: linkedId,
                listing_title: linkedTitle,
                comments: [...(l.comments || []), autoComment],
              }
              : l
          );
          localStorage.setItem(
            "stanomer_agency_leads_demo",
            JSON.stringify(demoUpdated)
          );
        } catch { }
        setConvertingLeadId(null);
      }

      setStatusMessage({
        type: "success",
        text: t("agency_panel_msg_demo_saved"),
      });
      resetForm();
      setActiveTab("listings");
      setSavingListing(false);
      return;
    }

    try {
      const payload = {
        agency_id: userId,
        external_ref: externalRef.trim() || null,
        title: title.trim(),
        description: description.trim() || null,
        transaction_type: transactionType,
        property_type: propertyType,
        price: numericPrice,
        currency,
        area_sqm: numericArea,
        room_count: roomCount,
        floor,
        total_floors: numericTotalFloors,
        heating_type: heatingType,
        condition,
        furnishing,
        city,
        municipality: municipality || null,
        neighborhood: neighborhood || null,
        address: address.trim(),
        amenities: selectedAmenities,
        is_published: isPublished,
        published_portals: ["stanomer", "4zida", "halooglasi", "sasomange", "nekretnine"],
      };

      let savedListingId = editingId;

      if (editingId) {
        const { error: updateErr } = await supabase
          .from("listings")
          .update(payload)
          .eq("id", editingId)
          .eq("agency_id", userId);
        if (updateErr) throw updateErr;
      } else {
        const { data: inserted, error: insertErr } = await supabase
          .from("listings")
          .insert(payload)
          .select("id")
          .single();
        if (insertErr) throw insertErr;
        savedListingId = inserted.id;
      }

      if (savedListingId) {
        await supabase.from("listing_images").delete().eq("listing_id", savedListingId);
        if (images.length > 0) {
          const imgRows = images.map((img, idx) => ({
            listing_id: savedListingId,
            url: img.url,
            order_index: idx,
            is_cover: img.is_cover,
          }));
          const { error: imgErr } = await supabase.from("listing_images").insert(imgRows);
          if (imgErr) throw imgErr;
        }
      }

      if (convertingLeadId && savedListingId) {
        const targetLeadId = convertingLeadId;
        const linkedId = savedListingId;
        const linkedTitle = title.trim();
        const autoComment: LeadComment = {
          id: `cmt-auto-${Date.now()}`,
          author_name: "Stanomer CRM",
          text: `${t("agency_panel_lead_converted_comment")}: "${linkedTitle}"`,
          created_at: new Date().toISOString(),
        };

        let updatedComments: LeadComment[] = [];
        setListingsLeads((prev) =>
          prev.map((l) => {
            if (l.id === targetLeadId) {
              updatedComments = [...(l.comments || []), autoComment];
              return {
                ...l,
                status: "converted",
                listing_id: linkedId,
                listing_title: linkedTitle,
                comments: updatedComments,
              };
            }
            return l;
          })
        );

        const currentKey = userId
          ? `stanomer_agency_leads_${userId}`
          : "stanomer_agency_leads_demo";
        try {
          const stored = JSON.parse(localStorage.getItem(currentKey) || "[]");
          const updated = stored.map((l: AgencyLead) =>
            l.id === targetLeadId
              ? {
                ...l,
                status: "converted",
                listing_id: linkedId,
                listing_title: linkedTitle,
                comments: updatedComments,
              }
              : l
          );
          localStorage.setItem(currentKey, JSON.stringify(updated));
        } catch { }

        try {
          await supabase
            .from("agency_leads")
            .update({
              status: "converted",
              listing_id: linkedId,
              listing_title: linkedTitle,
              comments: updatedComments,
            })
            .eq("id", targetLeadId);
        } catch { }
        setConvertingLeadId(null);
      }

      await fetchAgencyListings(userId);
      resetForm();
      setActiveTab("listings");
      setStatusMessage({
        type: "success",
        text: t("agency_panel_msg_saved"),
      });
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : t("agency_panel_msg_save_error");
      setStatusMessage({ type: "error", text: msg });
    } finally {
      setSavingListing(false);
    }
  }

  async function togglePublishStatus(item: AgencyListingRow) {
    if (!checkEffectiveDemoVerified()) {
      setIsGatekeeperModalOpen(true);
      return;
    }
    const nextState = !item.is_published;
    if (isDemoMode && (!userId || userId === "demo")) {
      const currentListings = Array.isArray(listings) && listings.length > 0
        ? listings
        : (() => {
          try {
            const saved = JSON.parse(localStorage.getItem("stanomer_agency_listings_demo") || "[]");
            return Array.isArray(saved) && saved.length > 0 ? saved : DEMO_AGENCY_LISTINGS;
          } catch {
            return DEMO_AGENCY_LISTINGS;
          }
        })();

      const nextListings = currentListings.map((row) =>
        row.id === item.id ? { ...row, is_published: nextState } : row
      );
      setListings(nextListings);

      if (typeof window !== "undefined") {
        try {
          localStorage.setItem(
            "stanomer_agency_listings_demo",
            JSON.stringify(nextListings)
          );
        } catch { }
      }
      setStatusMessage({
        type: "success",
        text: nextState
          ? t("agency_panel_msg_status_active")
          : t("agency_panel_msg_status_paused"),
      });
      return;
    }
    try {
      const { error } = await supabase
        .from("listings")
        .update({ is_published: nextState })
        .eq("id", item.id);
      if (error) throw error;
      setListings((prev) =>
        prev.map((row) => (row.id === item.id ? { ...row, is_published: nextState } : row))
      );
      setStatusMessage({
        type: "success",
        text: nextState
          ? t("agency_panel_msg_status_active")
          : t("agency_panel_msg_status_paused"),
      });
    } catch (err) {
      console.error("Toggle publish error:", err);
      setStatusMessage({
        type: "error",
        text: t("agency_panel_msg_save_error"),
      });
    }
  }

  function getFeedUrl(portalFile: string): string {
    const origin =
      typeof window !== "undefined" ? window.location.origin : "https://www.stanomer.online";
    const idSegment = userId || "demo";
    return `${origin}/api/feed/${idSegment}/${portalFile}${isDemoMode ? "?demo=1" : ""}`;
  }

  function handleCopyFeedUrl(portalId: string, portalFile: string) {
    const url = getFeedUrl(portalFile);
    navigator.clipboard.writeText(url);
    setCopiedPortal(portalId);
    setTimeout(() => setCopiedPortal(null), 2000);
  }

  const activeTabTitle =
    activeTab === "welcome"
      ? t("agency_panel_menu_welcome")
      : activeTab === "listings"
        ? t("agency_panel_menu_listings")
        : activeTab === "leads"
          ? t("agency_panel_menu_leads")
          : activeTab === "form"
            ? (editingId ? t("agency_panel_menu_edit_listing") : t("agency_panel_menu_new_listing"))
            : activeTab === "xml"
              ? t("agency_panel_menu_xml")
              : activeTab === "payments"
                ? t("agency_panel_menu_payments")
                : activeTab === "pm_dashboard"
                  ? t("agency_panel_menu_pm_dashboard")
                  : activeTab === "managed_properties"
                    ? t("agency_panel_menu_properties")
                    : activeTab === "contracts"
                      ? t("agency_panel_menu_contracts")
                      : activeTab === "maintenance"
                        ? t("agency_panel_menu_maintenance")
                        : activeTab === "account_settings"
                          ? t("agency_panel_menu_account_settings")
                          : activeTab === "tasks"
                            ? t("agency_tasks_page_title")
                            : t("agency_panel_menu_settings");

  const activeTabDescription =
    activeTab === "welcome"
      ? t("agency_page_desc_welcome")
      : activeTab === "listings"
        ? t("agency_page_desc_listings")
        : activeTab === "leads"
          ? t("agency_page_desc_leads")
          : activeTab === "form"
            ? t("agency_page_desc_form")
            : activeTab === "xml"
              ? t("agency_page_desc_xml")
              : activeTab === "payments"
                ? t("agency_page_desc_payments")
                : activeTab === "pm_dashboard"
                  ? t("agency_page_desc_pm_dashboard")
                  : activeTab === "managed_properties"
                    ? t("agency_page_desc_managed_properties")
                    : activeTab === "contracts"
                      ? t("agency_page_desc_contracts")
                      : activeTab === "maintenance"
                        ? t("agency_page_desc_maintenance")
                        : activeTab === "account_settings"
                          ? t("agency_page_desc_account_settings")
                          : activeTab === "tasks"
                            ? t("agency_tasks_page_subtitle")
                            : t("agency_page_desc_settings");

  const isPortfolioLocked = !activeModules.includes("portfolio_distribution");
  const isPropertyLeaseLocked = !activeModules.includes("property_lease_management");

  const handleActivateDemoModule = async (targetModule?: string) => {
    const allMods = targetModule
      ? Array.from(new Set([...activeModules, targetModule]))
      : ["portfolio_distribution", "property_lease_management"];

    setActiveModules(allMods);
    if (allMods.includes("portfolio_distribution") && allMods.includes("property_lease_management")) {
      setDemoFocus("both");
    } else if (allMods.includes("portfolio_distribution")) {
      setDemoFocus("presales");
    } else if (allMods.includes("property_lease_management")) {
      setDemoFocus("aftersales");
    }

    // 1. Update localStorage
    if (typeof window !== "undefined") {
      try {
        const s = localStorage.getItem("stanomer_agency_demo");
        const p = s ? JSON.parse(s) : {};
        p.focus = allMods.length > 1 ? "both" : allMods.includes("portfolio_distribution") ? "presales" : "aftersales";
        p.active_modules = allMods;
        localStorage.setItem("stanomer_agency_demo", JSON.stringify(p));
      } catch { }
    }

    // 2. Persist to DB profiles if user is authenticated / demo account exists
    if (userId) {
      try {
        await supabase
          .from("profiles")
          .update({
            active_modules: allMods,
            updated_at: new Date().toISOString(),
          })
          .eq("id", userId);
      } catch (err) {
        console.warn("Could not persist active_modules to profiles:", err);
      }
    }

    // 3. Persist to agency_demo_requests if email is available
    const targetEmail = agencyEmail || currentUser?.email;
    if (targetEmail) {
      try {
        await supabase
          .from("agency_demo_requests")
          .update({
            selected_modules: allMods,
            updated_at: new Date().toISOString(),
          })
          .ilike("email", targetEmail.trim());
      } catch { }
    }

    setStatusMessage({
      type: "success",
      text: t("agency_panel_locked_activated_toast"),
    });
  };

  const renderTabWithLockCheck = (
    category: "portfolio" | "property_lease",
    content: React.ReactNode
  ) => {
    const isLocked = category === "portfolio" ? isPortfolioLocked : isPropertyLeaseLocked;
    if (!isLocked) return content;

    return (
      <div className="relative w-full min-h-[520px]">
        {/* Real Screen Content Rendered Blurred & Inactive (Flu Ekran) */}
        <div className="filter blur-[8px] pointer-events-none select-none opacity-40 max-h-[750px] overflow-hidden transition-all duration-300">
          {content}
        </div>

        {/* SaaS Lock & Upgrade Card Overlay */}
        <div className="absolute inset-0 z-30 flex items-center justify-center p-4 sm:p-6 bg-white/45 backdrop-blur-[2px]">
          <div className="max-w-md w-full bg-white rounded-[16px] border border-[#E5E3DF] p-6 sm:p-8 shadow-[0_20px_50px_rgba(0,0,0,0.12)] text-center space-y-4 animate-in fade-in zoom-in-95 duration-200">
            <div className="w-14 h-14 rounded-full bg-[#FBF1DC] border border-[#8A5206]/20 text-[#8A5206] flex items-center justify-center mx-auto shadow-xs">
              <Lock className="w-7 h-7 text-[#8A5206]" />
            </div>

            <div className="space-y-1.5">
              <span className="text-[11px] font-bold uppercase tracking-wider text-[#8A5206] bg-[#FBF1DC] px-2.5 py-0.5 rounded-full inline-block">
                {category === "portfolio"
                  ? t("agency_panel_pkg_portfolio_distribution_title")
                  : t("agency_panel_pkg_property_lease_title")}
              </span>
              <h3 className="text-lg sm:text-xl font-bold text-[#1A1A1A]">
                {t("agency_panel_locked_modal_title")}
              </h3>
              <p className="text-xs sm:text-sm text-[#666666] leading-relaxed">
                {category === "portfolio"
                  ? t("agency_panel_locked_portfolio_desc")
                  : t("agency_panel_locked_pms_desc")}
              </p>
            </div>

            <div className="pt-2 flex flex-col sm:flex-row items-center justify-center gap-2.5">
              <button
                type="button"
                onClick={() => {
                  if (isDemoMode || !userId) {
                    handleActivateDemoModule();
                  } else {
                    handleRequestModuleUpgrade(category);
                  }
                }}
                className="w-full sm:w-auto px-5 py-2.5 rounded-[10px] bg-[#1B5888] hover:bg-[#12406A] active:bg-[#12406A] text-white font-bold text-xs sm:text-sm transition flex items-center justify-center gap-2 cursor-pointer shadow-sm"
              >
                <Sparkles className="w-4 h-4 shrink-0" />
                <span className="text-center">
                  {(() => {
                    const text = isDemoMode
                      ? t("agency_panel_locked_try_now_btn")
                      : t("agency_panel_locked_upgrade_btn");
                    const match = text.match(/^(.*?)(\s*\(.*?\))$/);
                    if (match) {
                      return (
                        <>
                          <span>{match[1]}</span>{" "}
                          <span className="inline-block whitespace-nowrap">{match[2].trim()}</span>
                        </>
                      );
                    }
                    return text;
                  })()}
                </span>
              </button>
              <button
                type="button"
                onClick={() => setActiveTab("account_settings")}
                className="w-full sm:w-auto px-4 py-2.5 rounded-[10px] bg-[#F7F5F0] hover:bg-[#EFECE6] border border-[#E5E3DF] text-[#1A1A1A] font-semibold text-xs sm:text-sm transition cursor-pointer"
              >
                {t("agency_panel_menu_account_settings")}
              </button>
            </div>
          </div>
        </div>
      </div>
    );
  };

  return (
    <div
      className="min-h-screen bg-[#F8F7F5] flex flex-col font-sans text-[#1A1A1A]"
      suppressHydrationWarning
    >
      {/* Dedicated Agency Panel Header */}
      <header className="sticky top-0 z-40 bg-white/95 backdrop-blur-md border-b border-[#E5E3DF]" suppressHydrationWarning>
        <div className="max-w-7xl mx-auto px-3 sm:px-6 lg:px-8 h-14 sm:h-16 flex items-center justify-between gap-1.5 sm:gap-4" suppressHydrationWarning>
          {/* Left: Brand Logo, Agency Name, Breadcrumb & Active Tab Title */}
          <div className="flex items-center gap-2.5 sm:gap-3 min-w-0" suppressHydrationWarning>
            {userId || isDemoMode ? (
              <div className="flex items-center gap-2.5 min-w-0" suppressHydrationWarning>
                {/* Agency Logo */}
                {agencyLogoUrl ? (
                  <img
                    src={agencyLogoUrl}
                    alt={agencyName || "Agency Logo"}
                    className="w-8 h-8 sm:w-9 sm:h-9 rounded-[10px] object-contain bg-white border border-[#E5E3DF] shadow-2xs shrink-0 notranslate"
                    translate="no"
                    suppressHydrationWarning
                  />
                ) : (
                  <div
                    className="w-8 h-8 sm:w-9 sm:h-9 rounded-[10px] bg-[#1B5888] text-white flex items-center justify-center font-bold text-sm shadow-xs shrink-0 notranslate"
                    translate="no"
                    suppressHydrationWarning
                  >
                    {agencyName ? agencyName.charAt(0).toUpperCase() : "A"}
                  </div>
                )}

                {/* Agency Name & Stanomer Hub Breadcrumb */}
                <div className="flex flex-col min-w-0 text-left notranslate" translate="no" suppressHydrationWarning>
                  <div className="flex items-center gap-1.5 leading-tight">
                    <span className="text-sm sm:text-base font-bold tracking-tight text-[#1A1A1A] truncate max-w-[130px] xs:max-w-[170px] sm:max-w-[200px] lg:max-w-[240px]">
                      {agencyName || "Agencija"}
                    </span>
                    {isDemoMode && (
                      <span className="inline-flex items-center px-1.5 py-0.5 rounded-full bg-[#FBF1DC] border border-[#8A5206]/20 text-[#8A5206] text-[9px] font-bold shrink-0">
                        *Demo
                      </span>
                    )}
                  </div>
                  <div className="flex items-center gap-1 text-[10px] font-semibold text-[#666666] leading-tight">
                    <span>Stanomer Hub</span>
                    <span className="hidden sm:inline">/</span>
                    <span className="hidden sm:inline text-[#4A4A4A] truncate max-w-[140px]">{agencyName || "Agencija"}</span>
                  </div>
                </div>
              </div>
            ) : (
              /* Public / Logged Out Header Brand */
              <div className="flex items-center gap-2.5 notranslate" translate="no" suppressHydrationWarning>
                <Link
                  href="/"
                  className="flex items-center gap-2.5 group notranslate"
                  translate="no"
                  title="Stanomer Hub"
                  suppressHydrationWarning
                >
                  <img
                    src="/assets/logo.png"
                    alt="Stanomer Logo"
                    className="w-8 h-8 sm:w-9 sm:h-9 object-contain rounded-[10px] group-hover:scale-105 transition-transform notranslate"
                    translate="no"
                    suppressHydrationWarning
                  />
                  <div className="flex flex-col notranslate" translate="no" suppressHydrationWarning>
                    <div className="flex items-center gap-1.5 leading-tight">
                      <span
                        className="text-base font-bold tracking-tight text-[#1A1A1A] group-hover:text-[#1B5888] transition-colors notranslate"
                        translate="no"
                        suppressHydrationWarning
                      >
                        Stanomer Hub
                      </span>
                    </div>
                    <span className="text-[10px] font-semibold text-[#666666] leading-tight">
                      {t("agency_panel_header_subtitle")}
                    </span>
                  </div>
                </Link>

                <span className="hidden sm:inline-block w-px h-5 bg-slate-200 mx-1" />

                <Link
                  href="/"
                  className="hidden sm:inline-flex items-center gap-1.5 text-xs font-semibold text-[#666666] hover:text-[#1A1A1A] transition-colors notranslate"
                  translate="no"
                  suppressHydrationWarning
                >
                  <ArrowLeft className="w-3.5 h-3.5" />
                  <span className="notranslate" translate="no" suppressHydrationWarning>
                    {t("agency_panel_nav_home")}
                  </span>
                </Link>
              </div>
            )}
          </div>

          {/* Right Header: Action Buttons, Language & User Profile */}
          <div className="flex items-center gap-1.5 sm:gap-2.5 shrink-0">
            {/* Header Action Buttons (Only when logged in / in demo - hidden on mobile, accessible via bottom drawer) */}
            {(userId || isDemoMode) && (
              <div className="hidden sm:flex items-center gap-1.5 sm:gap-2">
                {!isPortfolioLocked ? (
                  <Link
                    href={showcaseUrl}
                    target="_blank"
                    className="inline-flex items-center gap-1.5 px-2.5 py-1.5 rounded-lg bg-white border border-[#E5E3DF] hover:bg-slate-50 text-[#4A4A4A] text-xs font-semibold shadow-2xs transition-colors shrink-0"
                    title={t("agency_panel_preview_tpl")}
                  >
                    <Globe className="w-3.5 h-3.5 text-[#666666]" />
                    <span className="hidden md:inline">{t("agency_panel_preview_tpl")}</span>
                    <ExternalLink className="w-3 h-3 text-[#666666]" />
                  </Link>
                ) : (
                  <button
                    type="button"
                    onClick={() => setActiveTab("account_settings")}
                    className="inline-flex items-center gap-1.5 px-2.5 py-1.5 rounded-lg bg-white border border-[#E5E3DF] hover:bg-slate-50 text-[#4A4A4A] text-xs font-semibold shadow-2xs transition-colors shrink-0 cursor-pointer"
                    title={t("agency_panel_menu_account_settings")}
                  >
                    <Globe className="w-3.5 h-3.5 text-[#666666]" />
                    <span className="hidden md:inline">{t("agency_panel_preview_tpl")}</span>
                    <span className="p-1 rounded bg-amber-50 text-amber-700 border border-amber-200 font-bold inline-flex items-center">
                      <Lock className="w-2.5 h-2.5" />
                    </span>
                  </button>
                )}
              </div>
            )}

            {/* Custom Precision Language Dropdown (Mobile & Desktop) */}
            <div ref={langMenuRef} className="relative shrink-0">
              <button
                type="button"
                id="header-lang-btn"
                aria-label="Language Selector"
                aria-expanded={isLangMenuOpen}
                aria-haspopup="menu"
                onClick={() => {
                  setIsLangMenuOpen((prev) => !prev);
                  setIsProfileMenuOpen(false);
                }}
                className="flex items-center gap-1 sm:gap-1.5 px-2 py-1.5 rounded-lg border border-[#E5E3DF] bg-white text-[#4A4A4A] hover:border-[#8A8A8A] hover:bg-slate-50 text-xs font-semibold transition-colors cursor-pointer shadow-2xs"
              >
                <span className="text-sm leading-none">
                  {lang === "SR_LAT" ? "🇷🇸" : lang === "SR_CYR" ? "🇷🇸" : lang === "EN" ? "🇬🇧" : lang === "RU" ? "🇷🇺" : "🇹🇷"}
                </span>
                <span className="font-bold text-[11px] sm:text-xs text-[#1A1A1A]">
                  {lang === "SR_LAT" ? "SR" : lang === "SR_CYR" ? "СР" : lang === "EN" ? "EN" : lang === "RU" ? "RU" : "TR"}
                </span>
                <ChevronDown
                  className={`w-3.5 h-3.5 text-[#8A8A8A] transition-transform duration-150 ${isLangMenuOpen ? "rotate-180" : ""
                    }`}
                />
              </button>

              {isLangMenuOpen && (
                <div
                  role="menu"
                  aria-orientation="vertical"
                  className="absolute right-0 top-full mt-1.5 w-44 bg-white rounded-xl border border-[#E5E3DF] shadow-xl p-1.5 z-50 animate-in fade-in zoom-in-95 duration-100"
                >
                  {[
                    { code: "SR_LAT", label: "Srpski (Lat)", flag: "🇷🇸" },
                    { code: "SR_CYR", label: "Српски (Ћир)", flag: "🇷🇸" },
                    { code: "EN", label: "English", flag: "🇬🇧" },
                    { code: "RU", label: "Русский", flag: "🇷🇺" },
                    { code: "TR", label: "Türkçe", flag: "🇹🇷" },
                  ].map((item) => (
                    <button
                      key={item.code}
                      type="button"
                      onClick={() => {
                        setLang(item.code as any);
                        setIsLangMenuOpen(false);
                      }}
                      className={`w-full flex items-center justify-between px-2.5 py-2 rounded-lg text-xs font-semibold transition-colors cursor-pointer ${lang === item.code
                        ? "bg-[#1B5888] text-white font-bold shadow-2xs"
                        : "text-[#4A4A4A] hover:bg-[#F8F7F5] hover:text-[#1A1A1A]"
                        }`}
                    >
                      <div className="flex items-center gap-2">
                        <span className="text-base leading-none">{item.flag}</span>
                        <span>{item.label}</span>
                      </div>
                      {lang === item.code && <Check className="w-3.5 h-3.5 text-white shrink-0" />}
                    </button>
                  ))}
                </div>
              )}
            </div>

            {/* User Profile at Far Right (With Dropdown on Mobile) */}
            {userId || isDemoMode ? (
              <div ref={profileMenuRef} className="relative flex items-center sm:pl-2.5 sm:border-l sm:border-[#E5E3DF] shrink-0">
                <button
                  type="button"
                  id="header-profile-btn"
                  aria-expanded={isProfileMenuOpen}
                  aria-haspopup="menu"
                  onClick={() => {
                    setIsProfileMenuOpen((prev) => !prev);
                    setIsLangMenuOpen(false);
                  }}
                  className="flex items-center gap-1.5 sm:gap-2 p-1 sm:px-2 sm:py-1 rounded-lg hover:bg-slate-100 transition-colors text-left cursor-pointer group"
                  title={t("agency_panel_profile_btn")}
                >
                  <div
                    className={`w-8 h-8 sm:w-7 sm:h-7 rounded-lg border flex items-center justify-center font-bold text-xs shrink-0 transition-colors ${isProfileMenuOpen
                      ? "bg-[#1B5888] text-white border-[#1B5888]"
                      : "bg-slate-100 text-[#4A4A4A] border-[#E5E3DF] group-hover:bg-slate-900 group-hover:text-white"
                      }`}
                  >
                    <User className="w-4 h-4 sm:w-3.5 sm:h-3.5" />
                  </div>
                  <div className="hidden lg:block text-left">
                    <p className="text-xs font-bold text-[#1A1A1A] leading-none truncate max-w-[110px] xl:max-w-[140px]">
                      {agencyName || "Agencija"}
                    </p>
                    <p className="text-[10px] text-[#666666] font-medium leading-tight mt-0.5">
                      {isDemoMode
                        ? t("agency_panel_demo_mode_label")
                        : agencyRole === "agency_operation"
                          ? t("agency_role_operation")
                          : t("agency_role_admin")}
                    </p>
                  </div>
                  <ChevronDown
                    className={`w-3.5 h-3.5 text-[#8A8A8A] transition-transform sm:hidden ${isProfileMenuOpen ? "rotate-180" : ""
                      }`}
                  />
                </button>

                {/* Sign Out Button (Desktop Only) */}
                <button
                  type="button"
                  onClick={handleSignOut}
                  className="hidden sm:inline-flex p-1.5 rounded-lg text-[#666666] hover:text-[#1A1A1A] hover:bg-slate-100 transition-colors cursor-pointer shrink-0 ml-1"
                  title={t("agency_panel_signout")}
                  aria-label={t("agency_panel_signout")}
                >
                  <LogOut className="w-4 h-4" />
                </button>

                {/* Profile Dropdown Menu (Mobile Priority, also available on click) */}
                {isProfileMenuOpen && (
                  <div
                    role="menu"
                    aria-orientation="vertical"
                    className="absolute right-0 top-full mt-2 w-72 max-w-[calc(100vw-24px)] bg-white rounded-2xl border border-[#E5E3DF] shadow-2xl p-3 z-50 animate-in fade-in zoom-in-95 duration-150"
                  >
                    {/* 1. Agency & Status Info */}
                    <div className="flex items-center gap-3 p-2.5 bg-[#F8F7F5] rounded-xl border border-[#E5E3DF] mb-3">
                      <div className="w-9 h-9 rounded-lg bg-[#1B5888] text-white flex items-center justify-center font-bold text-sm shrink-0 shadow-xs">
                        {agencyName ? agencyName.charAt(0).toUpperCase() : "A"}
                      </div>
                      <div className="min-w-0 flex-1 text-left">
                        <p className="text-xs font-bold text-[#1A1A1A] truncate">
                          {agencyName || "Agencija"}
                        </p>
                        <p className="text-[10px] text-[#666666] font-medium leading-tight mt-0.5">
                          {isDemoMode
                            ? t("agency_panel_demo_mode_label")
                            : agencyRole === "agency_operation"
                              ? t("agency_role_operation")
                              : t("agency_role_admin")}
                        </p>
                      </div>
                    </div>

                    {/* 2. Language Selection */}
                    <div className="mb-3 px-1">
                      <p className="text-[10px] font-bold text-[#8A8A8A] uppercase tracking-wider mb-2">
                        {t("language")}
                      </p>
                      <div className="grid grid-cols-5 gap-1.5">
                        {[
                          { code: "SR_LAT", label: "SR", flag: "🇷🇸" },
                          { code: "SR_CYR", label: "СР", flag: "🇷🇸" },
                          { code: "EN", label: "EN", flag: "🇬🇧" },
                          { code: "RU", label: "RU", flag: "🇷🇺" },
                          { code: "TR", label: "TR", flag: "🇹🇷" },
                        ].map((l) => (
                          <button
                            key={l.code}
                            type="button"
                            onClick={() => {
                              setLang(l.code as any);
                              setIsProfileMenuOpen(false);
                            }}
                            className={`flex flex-col items-center justify-center py-2 px-1 rounded-xl text-xs transition-all cursor-pointer ${lang === l.code
                              ? "bg-[#1B5888] text-white font-bold shadow-xs scale-102"
                              : "bg-[#F8F7F5] text-[#4A4A4A] hover:bg-[#E5E3DF] border border-[#E5E3DF]"
                              }`}
                          >
                            <span className="text-base leading-none mb-1">{l.flag}</span>
                            <span className="text-[10px] font-bold leading-none">{l.label}</span>
                          </button>
                        ))}
                      </div>
                    </div>

                    <div className="h-px bg-[#E5E3DF] my-2" />

                    {/* 3. General & Account Settings Shortcut */}
                    <button
                      type="button"
                      onClick={() => {
                        setActiveTab("account_settings");
                        setIsProfileMenuOpen(false);
                      }}
                      className="w-full flex items-center justify-between p-2.5 rounded-xl text-xs font-semibold text-[#1A1A1A] hover:bg-[#F8F7F5] transition-colors cursor-pointer"
                    >
                      <div className="flex items-center gap-2.5">
                        <User className="w-4 h-4 text-[#1B5888]" />
                        <span>{t("agency_panel_menu_account_settings")}</span>
                      </div>
                      <ChevronRight className="w-4 h-4 text-[#8A8A8A]" />
                    </button>

                    {/* 4. Logout Action */}
                    <button
                      type="button"
                      onClick={() => {
                        setIsProfileMenuOpen(false);
                        handleSignOut();
                      }}
                      className="w-full flex items-center gap-2.5 p-2.5 rounded-xl text-xs font-semibold text-rose-600 hover:bg-rose-50 transition-colors cursor-pointer mt-0.5"
                    >
                      <LogOut className="w-4 h-4 text-rose-600" />
                      <span>{t("agency_panel_signout")}</span>
                    </button>
                  </div>
                )}
              </div>
            ) : isCheckingSession ? (
              <div className="flex items-center gap-2 text-xs font-semibold text-[#1B5888] shrink-0">
                <span className="hidden sm:inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-[#E5EEF6] text-[#1B5888]">
                  <RefreshCw className="w-3 h-3 animate-spin" />
                  <span>{t("agency_panel_loading")}</span>
                </span>
              </div>
            ) : (
              <div className="flex items-center gap-2 text-xs font-semibold text-[#4A4A4A] shrink-0">
                <span className="hidden sm:inline-block px-2.5 py-1 rounded-full bg-slate-100 text-[#4A4A4A]">
                  {t("agency_panel_not_signed_in")}
                </span>
              </div>
            )}
          </div>
        </div>
      </header>

      {/* Read-Only Preview Banner for Unverified Demo */}
      {isDemoMode && !isDemoVerified && (
        <div className="w-full bg-[#FFFBEB] text-[#1A1A1A] border-b border-amber-200/80 shadow-[0_1px_0_rgba(0,0,0,0.03)]">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-2.5 sm:py-3 flex flex-col sm:flex-row sm:items-center justify-between gap-3 text-xs">
            <div className="flex items-center gap-3 min-w-0">
              <div className="w-8 h-8 rounded-[8px] bg-amber-100 text-amber-800 flex items-center justify-center shrink-0 border border-amber-300/60">
                <Eye className="w-4 h-4 text-amber-800" />
              </div>
              <div className="min-w-0">
                <div className="font-bold text-[#1A1A1A] flex items-center gap-2 flex-wrap">
                  <span className="text-xs px-2 py-0.5 rounded-[6px] font-bold bg-amber-100 text-amber-900 border border-amber-300/60 shrink-0">
                    {t("demo_preview_banner_badge")}
                  </span>
                  {agencyName && <span className="truncate text-[#4A4A4A] font-semibold">{agencyName}</span>}
                </div>
                <p className="text-xs text-[#666666] mt-0.5 leading-relaxed">
                  {t("demo_preview_banner_desc")}
                </p>
              </div>
            </div>

            <button
              type="button"
              onClick={() => setIsGatekeeperModalOpen(true)}
              className="inline-flex items-center justify-center gap-1.5 px-4 py-2 rounded-[10px] bg-[#1B5888] hover:bg-[#12406A] active:bg-[#12406A] text-white font-bold text-xs transition-colors shrink-0 shadow-xs cursor-pointer w-full sm:w-auto"
            >
              <ShieldCheck className="w-3.5 h-3.5" />
              <span>{t("demo_preview_banner_cta")}</span>
              <ArrowRight className="w-3.5 h-3.5" />
            </button>
          </div>
        </div>
      )}

      {/* Full-width Personal Demo Sandbox Banner (Design System v4) */}
      {isDemoMode && isDemoVerified && (
        <div className="w-full bg-white text-[#1A1A1A] border-b border-[#E5E3DF] shadow-[0_1px_0_rgba(0,0,0,0.04)]">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-2.5 sm:py-3 flex flex-col sm:flex-row sm:items-center justify-between gap-3 text-xs">
            <div className="flex items-center gap-3 min-w-0">
              <div className="w-8 h-8 rounded-[8px] bg-[#FBF1DC] text-[#8A5206] flex items-center justify-center shrink-0 border border-[#8A5206]/20">
                <Sparkles className="w-4 h-4 text-[#8A5206]" />
              </div>
              <div className="min-w-0">
                <div className="font-bold text-[#1A1A1A] flex items-center gap-2 flex-wrap">
                  <span className="truncate">{t("agency_panel_demo_banner_tag")}: {agencyName}</span>
                  <span className="text-xs px-2 py-0.5 rounded-[6px] font-mono font-bold bg-[#FBF1DC] text-[#8A5206] border border-[#8A5206]/30 tabular-nums shrink-0">
                    {demoTimeRemaining}
                  </span>
                  <span className="text-xs px-2 py-0.5 rounded-[6px] font-mono font-semibold bg-[#E5EEF6] text-[#1B5888] border border-[#1B5888]/20 shrink-0">
                    {demoFocus === "presales"
                      ? t("agency_panel_demo_focus_badge_presales")
                      : demoFocus === "aftersales"
                        ? t("agency_panel_demo_focus_badge_aftersales")
                        : t("agency_panel_demo_focus_badge_both")}
                  </span>
                  <span className="text-xs px-2 py-0.5 rounded-[6px] font-mono font-bold bg-emerald-50 text-emerald-700 border border-emerald-200 shrink-0">
                    ✓ {t("agency_panel_demo_verified_badge")}
                  </span>
                </div>
                <p className="text-xs text-[#666666] mt-0.5 leading-relaxed">
                  {t("agency_panel_demo_verified_banner_desc")}
                </p>
              </div>
            </div>

            <a
              href={`https://wa.me/381616036556?text=${encodeURIComponent(
                `Pozdrav, želimo da aktiviramo zvanični nalog za agenciju ${agencyName}.`
              )}`}
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center justify-center gap-1.5 px-4 py-2 rounded-[10px] bg-[#1B5888] hover:bg-[#12406A] active:bg-[#12406A] text-white font-bold text-xs transition-colors shrink-0 shadow-[0_1px_0_rgba(0,0,0,0.04),0_2px_8px_rgba(0,0,0,0.06)] cursor-pointer w-full sm:w-auto"
            >
              <span>{t("agency_panel_demo_banner_cta")}</span>
              <ArrowRight className="w-3.5 h-3.5" />
            </a>
          </div>
        </div>
      )}

      <main className={`max-w-7xl mx-auto w-full px-4 sm:px-6 lg:px-8 ${!userId ? "py-3 sm:py-4" : "py-6 sm:py-8"}`}>
        {/* 1. AUTH GATE OR DEMO ENTRY */}
        {!userId && isCheckingSession ? (
          <div
            role="status"
            aria-live="polite"
            className="min-h-[60vh] flex items-center justify-center"
          >
            <div className="bg-white rounded-2xl border border-[#E5E3DF] shadow-xs px-8 py-10 max-w-sm w-full text-center">
              <div className="w-12 h-12 rounded-2xl bg-[#E5EEF6] text-[#1B5888] flex items-center justify-center mx-auto mb-4">
                <RefreshCw className="w-6 h-6 animate-spin" />
              </div>
              <h2 className="text-base font-bold text-[#1A1A1A] mb-1">
                {t("agency_panel_signing_in")}
              </h2>
              <p className="text-sm text-[#666666]">
                {t("agency_panel_loading")}
              </p>
            </div>
          </div>
        ) : !userId ? (
          <div className="max-w-5xl mx-auto grid grid-cols-1 lg:grid-cols-12 rounded-[16px] overflow-hidden border border-[#E5E3DF] bg-white shadow-[0_1px_0_rgba(0,0,0,0.04),0_12px_36px_rgba(18,64,106,0.08)] lg:min-h-[610px]">
            {/* LEFT: Brand Identity Hero & End-to-End Lifecycle Visual */}
            <section className="lg:col-span-6 relative overflow-hidden bg-gradient-to-br from-[#0E3152] via-[#1B5888] to-[#12406A] text-white p-6 sm:p-7 lg:p-8 flex flex-col justify-between gap-5">
              {/* Subtle Stanomer architectural grid & ambient radial light */}
              <div
                aria-hidden="true"
                className="pointer-events-none absolute inset-0 opacity-60"
                style={{
                  backgroundImage:
                    "radial-gradient(rgba(229, 238, 246, 0.16) 1px, transparent 1px)",
                  backgroundSize: "24px 24px",
                }}
              />
              <div
                aria-hidden="true"
                className="pointer-events-none absolute -right-28 top-12 w-[340px] h-[340px] rounded-full bg-[#2A6E43]/30 blur-3xl"
              />
              <div
                aria-hidden="true"
                className="pointer-events-none absolute -left-24 -bottom-24 w-[280px] h-[280px] rounded-full bg-[#E5EEF6]/10 blur-3xl"
              />

              {/* Top Brand Row */}
              <div className="relative z-10 space-y-2.5">
                <div className="flex items-center justify-between gap-3 flex-wrap">
                  <div className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-[6px] bg-white/12 backdrop-blur-xs border border-white/20 text-[#E5EEF6] text-[11px] font-bold tracking-wide">
                    <Sparkles className="w-3 h-3 text-[#FBF1DC]" />
                    <span>{t("agency_panel_badge")}</span>
                  </div>
                  <span className="text-[11px] font-semibold text-[#C8DDF0]">
                    {t("agency_panel_demo_badge")}
                  </span>
                </div>

                <div className="space-y-1.5">
                  <h1 className="font-[family-name:var(--font-outfit)] text-xl sm:text-2xl xl:text-[27px] font-bold text-white leading-[1.15] tracking-tight">
                    {t("agency_panel_demo_title")}
                  </h1>
                  <p className="text-xs text-[#D8E7F5] leading-relaxed">
                    {t("agency_panel_demo_desc")}
                  </p>
                </div>
              </div>

              {/* Centerpiece Animated Listing-to-Lifecycle Visual (Stanomer v4 Palette) */}
              <div className="relative z-10 w-full max-w-[390px] mx-auto hidden sm:block">
                <div className="relative h-[212px]">
                  <svg
                    viewBox="0 0 390 212"
                    className="absolute inset-0 w-full h-full pointer-events-none"
                    aria-hidden="true"
                  >
                    {/* Right portal syndication flows (Stanomer Success Green) */}
                    <path
                      className="st-flow"
                      d="M279 72 C308 72 306 32 322 28"
                      fill="none"
                      stroke="#6EE7B7"
                      strokeWidth="1.8"
                    />
                    <path
                      className="st-flow"
                      d="M279 124 C308 124 306 162 322 166"
                      fill="none"
                      stroke="#6EE7B7"
                      strokeWidth="1.8"
                    />
                    {/* Left & bottom operational lifecycle flows (Stanomer Soft Blue) */}
                    <path
                      className="st-flow"
                      d="M111 70 C86 64 80 35 66 28"
                      fill="none"
                      stroke="#93C5FD"
                      strokeWidth="1.5"
                    />
                    <path
                      className="st-flow"
                      d="M111 128 C86 134 80 164 64 172"
                      fill="none"
                      stroke="#93C5FD"
                      strokeWidth="1.5"
                    />
                  </svg>

                  {/* Center Property Card */}
                  <div className="absolute left-1/2 -translate-x-1/2 top-[14px] w-[168px] bg-white rounded-[9px] border border-[#E5E3DF] text-[#1A1A1A] shadow-[0_12px_26px_rgba(8,24,44,0.34)] overflow-hidden">
                    <svg
                      viewBox="0 0 224 62"
                      className="w-full h-[62px] block"
                      role="img"
                      aria-label="Stanomer property preview"
                    >
                      <rect width="224" height="62" fill="#E5EEF6" />
                      <circle cx="184" cy="17" r="8.5" fill="#A33C29" opacity="0.88" />
                      <rect x="28" y="22" width="54" height="40" rx="2" fill="#1B5888" />
                      <rect x="84" y="11" width="52" height="51" rx="2" fill="#12406A" />
                      <rect x="138" y="28" width="54" height="34" rx="2" fill="#2A6E43" />
                      <g fill="#E5EEF6" opacity="0.92">
                        <rect x="38" y="29" width="9" height="7.5" rx="1.5" />
                        <rect x="58" y="29" width="9" height="7.5" rx="1.5" />
                        <rect x="38" y="43" width="9" height="7.5" rx="1.5" />
                        <rect x="58" y="43" width="9" height="7.5" rx="1.5" />
                        <rect x="95" y="20" width="9" height="7.5" rx="1.5" />
                        <rect x="114" y="20" width="9" height="7.5" rx="1.5" />
                        <rect x="95" y="34" width="9" height="7.5" rx="1.5" />
                        <rect x="114" y="34" width="9" height="7.5" rx="1.5" />
                        <rect x="149" y="37" width="9" height="7.5" rx="1.5" />
                        <rect x="168" y="37" width="9" height="7.5" rx="1.5" />
                      </g>
                    </svg>
                    <div className="p-2">
                      <div className="font-[family-name:var(--font-outfit)] font-bold text-[10.5px] text-[#1A1A1A] leading-tight truncate">
                        Njegoševa 24, Novi Sad
                      </div>
                      <div className="text-[9.5px] text-[#666666] mt-0.5 mb-1.5">
                        2.0 · 54 m² · 3F
                      </div>
                      <div className="flex items-center justify-between gap-1">
                        <span className="font-mono font-medium text-[11px] text-[#1B5888]">
                          €650/mo
                        </span>
                        <span className="inline-flex items-center px-1.5 py-0.5 rounded-[4px] bg-[#E6F3EA] text-[#2A6E43] text-[9px] font-bold">
                          {t("agency_panel_demo_pill_published")}
                        </span>
                      </div>
                    </div>
                  </div>

                  {/* Right Portal Badges */}
                  <div className="absolute right-0 top-[12px] bg-white text-[#1A1A1A] rounded-[7px] px-2 py-1 shadow-[0_6px_16px_rgba(8,24,44,0.26)] border border-[#E5E3DF] flex items-center gap-1.5 text-[10px] font-bold">
                    <span className="w-1.5 h-1.5 rounded-full bg-[#2A6E43] shrink-0" />
                    <span>4zida.rs</span>
                  </div>
                  <div className="absolute right-0 top-[148px] bg-white text-[#1A1A1A] rounded-[7px] px-2 py-1 shadow-[0_6px_16px_rgba(8,24,44,0.26)] border border-[#E5E3DF] flex items-center gap-1.5 text-[10px] font-bold">
                    <span className="w-1.5 h-1.5 rounded-full bg-[#2A6E43] shrink-0" />
                    <span>Halo Oglasi</span>
                  </div>

                  {/* Floating Lifecycle Pills */}
                  <div className="st-bob-1 absolute left-0 top-[10px] bg-[#0E3152]/90 backdrop-blur-xs border border-[#4D8DC0]/40 rounded-[7px] px-2 py-1 text-[9.5px] font-semibold text-white shadow-md flex items-center gap-1">
                    <FileText className="w-2.5 h-2.5 text-[#E5EEF6] shrink-0" />
                    <span>{t("agency_panel_demo_pill_lease")}</span>
                  </div>
                  <div className="st-bob-2 absolute left-0 top-[152px] bg-[#0E3152]/90 backdrop-blur-xs border border-[#4D8DC0]/40 rounded-[7px] px-2 py-1 text-[9.5px] font-semibold text-white shadow-md flex items-center gap-1">
                    <Wallet className="w-2.5 h-2.5 text-[#6EE7B7] shrink-0" />
                    <span>{t("agency_panel_demo_pill_rent")}</span>
                    <span className="font-mono text-[#6EE7B7] font-medium">+€650</span>
                  </div>
                  <div className="st-bob-3 absolute left-1/2 -translate-x-1/2 bottom-0 bg-[#0E3152]/90 backdrop-blur-xs border border-[#4D8DC0]/40 rounded-[7px] px-2 py-1 text-[9.5px] font-semibold text-white shadow-md flex items-center gap-1 whitespace-nowrap">
                    <CheckSquare className="w-2.5 h-2.5 text-[#FBF1DC] shrink-0" />
                    <span>{t("agency_panel_demo_pill_tasks")}</span>
                  </div>
                </div>
              </div>

              {/* Bottom 4-Pillar Compact Strip */}
              <div className="relative z-10 pt-3 border-t border-white/15 grid grid-cols-2 gap-x-3 gap-y-2 text-xs">
                <div className="flex items-start gap-1.5">
                  <Globe className="w-3.5 h-3.5 text-[#A9CBE8] shrink-0 mt-0.5" />
                  <div>
                    <p className="font-bold text-white text-[11px] leading-tight">{t("agency_panel_demo_feat1_title")}</p>
                    <p className="text-[#C8DDF0]/85 text-[10px] leading-snug mt-0.5">{t("agency_panel_demo_feat1_desc")}</p>
                  </div>
                </div>
                <div className="flex items-start gap-1.5">
                  <Home className="w-3.5 h-3.5 text-[#A9CBE8] shrink-0 mt-0.5" />
                  <div>
                    <p className="font-bold text-white text-[11px] leading-tight">{t("agency_panel_demo_feat2_title")}</p>
                    <p className="text-[#C8DDF0]/85 text-[10px] leading-snug mt-0.5">{t("agency_panel_demo_feat2_desc")}</p>
                  </div>
                </div>
                <div className="flex items-start gap-1.5">
                  <Wallet className="w-3.5 h-3.5 text-[#A9CBE8] shrink-0 mt-0.5" />
                  <div>
                    <p className="font-bold text-white text-[11px] leading-tight">{t("agency_panel_demo_feat3_title")}</p>
                    <p className="text-[#C8DDF0]/85 text-[10px] leading-snug mt-0.5">{t("agency_panel_demo_feat3_desc")}</p>
                  </div>
                </div>
                <div className="flex items-start gap-1.5">
                  <CheckSquare className="w-3.5 h-3.5 text-[#A9CBE8] shrink-0 mt-0.5" />
                  <div>
                    <p className="font-bold text-white text-[11px] leading-tight">{t("agency_panel_demo_feat4_title")}</p>
                    <p className="text-[#C8DDF0]/85 text-[10px] leading-snug mt-0.5">{t("agency_panel_demo_feat4_desc")}</p>
                  </div>
                </div>
              </div>
            </section>

            {/* RIGHT: Clean Stanomer Auth Panel + Interactive Demo CTA */}
            <section className="lg:col-span-6 bg-white p-5 sm:p-7 flex flex-col justify-center">
              <div className="w-full max-w-md mx-auto">
                {/* Auth Mode Tabs */}
                <div className="flex gap-1.5 p-1 bg-slate-100 rounded-[10px] mb-6">
                  <button
                    type="button"
                    onClick={() => {
                      setAuthTab("signin");
                      setAuthError(null);
                      setIsRoleError(false);
                      setShowRoleErrorDetails(false);
                      setAuthSuccess(null);
                    }}
                    className={`flex-1 py-2 px-3 rounded-lg text-xs font-semibold transition-colors cursor-pointer ${authTab === "signin"
                      ? "bg-white text-[#1A1A1A] shadow-xs"
                      : "text-[#4A4A4A] hover:text-[#1A1A1A]"
                      }`}
                  >
                    {t("agency_panel_tab_signin")}
                  </button>
                  <button
                    type="button"
                    onClick={() => {
                      setAuthTab("signup");
                      setAuthError(null);
                      setIsRoleError(false);
                      setShowRoleErrorDetails(false);
                      setAuthSuccess(null);
                    }}
                    className={`flex-1 py-2 px-3 rounded-lg text-xs font-semibold transition-colors cursor-pointer ${authTab === "signup"
                      ? "bg-white text-[#1A1A1A] shadow-xs"
                      : "text-[#4A4A4A] hover:text-[#1A1A1A]"
                      }`}
                  >
                    {t("agency_panel_tab_signup")}
                  </button>
                  <button
                    type="button"
                    onClick={() => {
                      setAuthTab("reset");
                      setAuthError(null);
                      setIsRoleError(false);
                      setShowRoleErrorDetails(false);
                      setAuthSuccess(null);
                    }}
                    className={`flex-1 py-2 px-3 rounded-lg text-xs font-semibold transition-colors cursor-pointer ${authTab === "reset"
                      ? "bg-white text-[#1A1A1A] shadow-xs"
                      : "text-[#4A4A4A] hover:text-[#1A1A1A]"
                      }`}
                  >
                    {t("agency_panel_tab_reset")}
                  </button>
                </div>

                <h2
                  id="agency-signin-heading"
                  className="text-xl font-bold text-[#1A1A1A] mb-2"
                >
                  {authTab === "signin"
                    ? t("agency_panel_signin_title")
                    : authTab === "signup"
                      ? t("agency_panel_signup_title")
                      : t("agency_panel_reset_title")}
                </h2>
                <p className="text-sm text-[#4A4A4A] mb-6">
                  {authTab === "signin"
                    ? t("agency_panel_signin_desc")
                    : authTab === "signup"
                      ? t("agency_panel_signup_desc")
                      : t("agency_panel_reset_desc")}
                </p>

                {authError && (
                  <div
                    role="alert"
                    className="mb-4 p-4 rounded-[12px] bg-[#FBEAE6] border border-[#B5432E]/25 text-[#A33C29] text-sm space-y-3"
                  >
                    <div className="flex items-start gap-2.5">
                      <AlertCircle className="w-4 h-4 shrink-0 mt-0.5 text-[#B5432E]" />
                      <div className="flex-1 text-xs sm:text-sm font-medium leading-relaxed">
                        {authError}
                      </div>
                    </div>

                    {isRoleError && (
                      <div className="pt-2 border-t border-[#B5432E]/15">
                        <button
                          type="button"
                          onClick={() => setShowRoleErrorDetails((prev) => !prev)}
                          className="inline-flex items-center gap-1.5 text-xs font-bold text-[#8A2B18] hover:text-[#5E1A0C] transition-colors cursor-pointer"
                        >
                          <span>
                            {showRoleErrorDetails
                              ? t("agency_panel_role_err_hide_details")
                              : t("agency_panel_role_err_show_details")}
                          </span>
                          {showRoleErrorDetails ? (
                            <ChevronUp className="w-3.5 h-3.5" />
                          ) : (
                            <ChevronDown className="w-3.5 h-3.5" />
                          )}
                        </button>

                        {showRoleErrorDetails && (
                          <div className="mt-2.5 p-3.5 bg-white/95 rounded-xl border border-[#B5432E]/20 space-y-2.5 text-xs text-[#2A2A2A] animate-in fade-in duration-200 shadow-2xs">
                            <p className="font-semibold text-[#4A4A4A] leading-relaxed">
                              {t("agency_panel_role_err_app_prompt")}
                            </p>
                            <div className="grid grid-cols-1 sm:grid-cols-3 gap-2 pt-1">
                              {/* iOS App Store */}
                              <a
                                href="https://apps.apple.com/us/app/stanomer/id6762311157"
                                target="_blank"
                                rel="noopener noreferrer"
                                className="flex items-center justify-center gap-1.5 px-3 py-2 rounded-lg bg-black text-white hover:bg-slate-800 transition-colors text-center font-semibold text-xs shadow-xs"
                              >
                                <Smartphone className="w-3.5 h-3.5 shrink-0" />
                                <span>{t("agency_panel_role_err_ios")}</span>
                              </a>
                              {/* Android Google Play */}
                              <a
                                href="https://play.google.com/store/apps/details?id=com.aboptima.stanomer"
                                target="_blank"
                                rel="noopener noreferrer"
                                className="flex items-center justify-center gap-1.5 px-3 py-2 rounded-lg bg-[#0F5132] text-white hover:bg-[#0b3c25] transition-colors text-center font-semibold text-xs shadow-xs"
                              >
                                <Smartphone className="w-3.5 h-3.5 shrink-0" />
                                <span>{t("agency_panel_role_err_android")}</span>
                              </a>
                              {/* Web App */}
                              <a
                                href="/app"
                                target="_blank"
                                rel="noopener noreferrer"
                                className="flex items-center justify-center gap-1.5 px-3 py-2 rounded-lg bg-[#1B5888] text-white hover:bg-blue-700 transition-colors text-center font-semibold text-xs shadow-xs"
                              >
                                <Globe className="w-3.5 h-3.5 shrink-0" />
                                <span>{t("agency_panel_role_err_web")}</span>
                              </a>
                            </div>
                          </div>
                        )}
                      </div>
                    )}
                  </div>
                )}

                {authSuccess && (
                  <div
                    role="status"
                    className="mb-4 p-3.5 rounded-[10px] bg-[#E6F3EA] border border-[#2A6E43]/20 text-[#2A6E43] text-sm flex items-center gap-2.5"
                  >
                    <CheckCircle2 className="w-4 h-4 shrink-0" />
                    <span>{authSuccess}</span>
                  </div>
                )}

                {authTab === "signin" && (
                  <form
                    onSubmit={handleSignIn}
                    aria-labelledby="agency-signin-heading"
                    className="space-y-4"
                  >
                    <div>
                      <label
                        htmlFor="agency-email"
                        className="block text-sm font-semibold text-[#4A4A4A] mb-1"
                      >
                        {t("agency_panel_email_label")} <span aria-hidden="true">*</span>
                      </label>
                      <input
                        id="agency-email"
                        name="email"
                        type="email"
                        autoComplete="username"
                        spellCheck={false}
                        required
                        value={authEmail}
                        onChange={(e) => setAuthEmail(e.target.value)}
                        className="w-full px-3.5 py-2.5 rounded-[10px] border border-[#8A8A8A] text-base focus:outline-2 focus:outline-[#1B5888]"
                        placeholder="agencija@primer.rs"
                      />
                    </div>

                    <div>
                      <div className="flex items-center justify-between mb-1">
                        <label
                          htmlFor="agency-password"
                          className="block text-sm font-semibold text-[#4A4A4A]"
                        >
                          {t("agency_panel_password_label")} <span aria-hidden="true">*</span>
                        </label>
                        <button
                          type="button"
                          aria-pressed={showPassword}
                          onClick={() => setShowPassword((prev) => !prev)}
                          className="text-xs font-medium text-[#1B5888] hover:text-blue-800"
                        >
                          {showPassword
                            ? t("agency_panel_hide_password")
                            : t("agency_panel_show_password")}
                        </button>
                      </div>
                      <input
                        id="agency-password"
                        name="password"
                        type={showPassword ? "text" : "password"}
                        autoComplete="current-password"
                        required
                        value={authPassword}
                        onChange={(e) => setAuthPassword(e.target.value)}
                        className="w-full px-3.5 py-2.5 rounded-[10px] border border-[#8A8A8A] text-base focus:outline-2 focus:outline-[#1B5888]"
                      />
                    </div>

                    <button
                      type="submit"
                      disabled={authLoading}
                      className="w-full py-3 px-5 rounded-[10px] bg-[#1B5888] hover:bg-[#12406A] active:bg-[#12406A] disabled:opacity-60 text-white font-semibold text-sm transition-colors cursor-pointer"
                    >
                      {authLoading
                        ? t("agency_panel_signing_in")
                        : t("agency_panel_signin_btn")}
                    </button>
                  </form>
                )}

                {authTab === "signup" && (
                  <form
                    onSubmit={handleSignUp}
                    aria-labelledby="agency-signin-heading"
                    className="space-y-4"
                  >
                    {/* Directory Agency Autocomplete */}
                    <div className="relative p-3.5 rounded-[10px] bg-slate-50 border border-[#E5E3DF]">
                      <label
                        htmlFor="dir-agency-search"
                        className="block text-xs font-semibold text-[#4A4A4A] mb-1.5 flex items-center gap-1.5"
                      >
                        <Search className="w-3.5 h-3.5 text-[#1B5888]" />
                        <span>{t("agency_panel_dir_search_label")}</span>
                      </label>
                      <input
                        id="dir-agency-search"
                        type="text"
                        value={dirSearchQuery}
                        onChange={(e) => setDirSearchQuery(e.target.value)}
                        placeholder={t("agency_panel_dir_search_placeholder")}
                        className="w-full px-3 py-2 rounded-lg border border-[#8A8A8A] text-sm bg-white"
                      />
                      {selectedDirAgency && (
                        <p className="mt-1.5 text-xs font-semibold text-[#2A6E43] flex items-center gap-1">
                          <CheckCircle2 className="w-3.5 h-3.5" />
                          <span>
                            {t("agency_panel_dir_matched")} {selectedDirAgency.acente_adi} (#{selectedDirAgency.id})
                          </span>
                        </p>
                      )}
                      {dirMatches.length > 0 && (
                        <div className="mt-2 bg-white rounded-[10px] border border-[#E5E3DF] shadow-md divide-y divide-slate-100 max-h-48 overflow-y-auto">
                          {dirMatches.map((m) => (
                            <button
                              key={m.id}
                              type="button"
                              onClick={() => handleSelectDirAgency(m)}
                              className="w-full text-left px-3 py-2 hover:bg-[#E5EEF6] text-xs flex items-center justify-between cursor-pointer"
                            >
                              <span className="font-semibold text-[#1A1A1A]">{m.acente_adi}</span>
                              <span className="text-[#666666]">{m.sehir || ""}</span>
                            </button>
                          ))}
                        </div>
                      )}
                    </div>

                    <div>
                      <label
                        htmlFor="signup-company"
                        className="block text-sm font-semibold text-[#4A4A4A] mb-1"
                      >
                        {t("agency_panel_company_label")} <span aria-hidden="true">*</span>
                      </label>
                      <input
                        id="signup-company"
                        name="organization"
                        type="text"
                        autoComplete="organization"
                        required
                        value={signupCompany}
                        onChange={(e) => setSignupCompany(e.target.value)}
                        className="w-full px-3.5 py-2.5 rounded-[10px] border border-[#8A8A8A] text-sm"
                        placeholder="Alfa Nekretnine Beograd"
                      />
                    </div>

                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                      <div>
                        <label
                          htmlFor="signup-phone"
                          className="block text-sm font-semibold text-[#4A4A4A] mb-1"
                        >
                          {t("agency_panel_phone_label")} <span aria-hidden="true">*</span>
                        </label>
                        <input
                          id="signup-phone"
                          name="phone"
                          type="tel"
                          autoComplete="tel"
                          required
                          value={signupPhone}
                          onChange={(e) => setSignupPhone(e.target.value)}
                          className="w-full px-3.5 py-2.5 rounded-[10px] border border-[#8A8A8A] text-sm"
                          placeholder="+381 64 123 4567"
                        />
                      </div>
                      <div>
                        <label
                          htmlFor="signup-website"
                          className="block text-sm font-semibold text-[#4A4A4A] mb-1"
                        >
                          {t("agency_panel_website_label")}
                        </label>
                        <input
                          id="signup-website"
                          name="website"
                          type="url"
                          autoComplete="url"
                          value={signupWebsite}
                          onChange={(e) => setSignupWebsite(e.target.value)}
                          className="w-full px-3.5 py-2.5 rounded-[10px] border border-[#8A8A8A] text-sm"
                          placeholder="https://..."
                        />
                      </div>
                    </div>

                    <div>
                      <label
                        htmlFor="signup-email"
                        className="block text-sm font-semibold text-[#4A4A4A] mb-1"
                      >
                        {t("agency_panel_email_label")} <span aria-hidden="true">*</span>
                      </label>
                      <input
                        id="signup-email"
                        name="email"
                        type="email"
                        autoComplete="email"
                        spellCheck={false}
                        required
                        value={authEmail}
                        onChange={(e) => setAuthEmail(e.target.value)}
                        className="w-full px-3.5 py-2.5 rounded-[10px] border border-[#8A8A8A] text-sm"
                        placeholder="kontakt@agencija.rs"
                      />
                    </div>

                    <div>
                      <div className="flex items-center justify-between mb-1">
                        <label
                          htmlFor="signup-password"
                          className="block text-sm font-semibold text-[#4A4A4A]"
                        >
                          {t("agency_panel_password_label")} <span aria-hidden="true">*</span>
                        </label>
                        <button
                          type="button"
                          aria-pressed={showPassword}
                          onClick={() => setShowPassword((prev) => !prev)}
                          className="text-xs font-medium text-[#1B5888] hover:text-blue-800"
                        >
                          {showPassword
                            ? t("agency_panel_hide_password")
                            : t("agency_panel_show_password")}
                        </button>
                      </div>
                      <input
                        id="signup-password"
                        name="password"
                        type={showPassword ? "text" : "password"}
                        autoComplete="new-password"
                        minLength={6}
                        required
                        value={authPassword}
                        onChange={(e) => setAuthPassword(e.target.value)}
                        className="w-full px-3.5 py-2.5 rounded-[10px] border border-[#8A8A8A] text-sm"
                      />
                    </div>

                    <button
                      type="submit"
                      disabled={authLoading}
                      className="w-full py-3 px-5 rounded-[10px] bg-[#1B5888] hover:bg-[#12406A] active:bg-[#12406A] disabled:opacity-60 text-white font-semibold text-sm transition-colors cursor-pointer"
                    >
                      {authLoading
                        ? t("agency_panel_signing_up")
                        : t("agency_panel_signup_btn")}
                    </button>
                  </form>
                )}

                {authTab === "reset" && (
                  <form
                    onSubmit={handleResetPassword}
                    aria-labelledby="agency-signin-heading"
                    className="space-y-4"
                  >
                    <div>
                      <label
                        htmlFor="reset-email"
                        className="block text-sm font-semibold text-[#4A4A4A] mb-1"
                      >
                        {t("agency_panel_email_label")} <span aria-hidden="true">*</span>
                      </label>
                      <input
                        id="reset-email"
                        name="email"
                        type="email"
                        autoComplete="email"
                        spellCheck={false}
                        required
                        value={authEmail}
                        onChange={(e) => setAuthEmail(e.target.value)}
                        className="w-full px-3.5 py-2.5 rounded-[10px] border border-[#8A8A8A] text-base focus:outline-2 focus:outline-[#1B5888]"
                        placeholder="agencija@primer.rs"
                      />
                    </div>

                    {resetStep === 2 && (
                      <>
                        <div>
                          <label
                            htmlFor="reset-code"
                            className="block text-sm font-semibold text-[#4A4A4A] mb-1"
                          >
                            {t("agency_panel_reset_code_label")} <span aria-hidden="true">*</span>
                          </label>
                          <input
                            id="reset-code"
                            name="reset-code"
                            type="text"
                            required
                            value={resetCode}
                            onChange={(e) => setResetCode(e.target.value)}
                            className="w-full px-3.5 py-2.5 rounded-[10px] border border-[#8A8A8A] text-base font-mono tracking-widest focus:outline-2 focus:outline-[#1B5888]"
                            placeholder={t("agency_panel_reset_code_placeholder")}
                          />
                        </div>

                        <div>
                          <label
                            htmlFor="reset-new-password"
                            className="block text-sm font-semibold text-[#4A4A4A] mb-1"
                          >
                            {t("agency_panel_new_password")} <span aria-hidden="true">*</span>
                          </label>
                          <input
                            id="reset-new-password"
                            name="new-password"
                            type="password"
                            autoComplete="new-password"
                            required
                            value={resetNewPassword}
                            onChange={(e) => setResetNewPassword(e.target.value)}
                            className="w-full px-3.5 py-2.5 rounded-[10px] border border-[#8A8A8A] text-base focus:outline-2 focus:outline-[#1B5888]"
                            placeholder="••••••••"
                          />
                        </div>

                        <div>
                          <label
                            htmlFor="reset-confirm-password"
                            className="block text-sm font-semibold text-[#4A4A4A] mb-1"
                          >
                            {t("agency_panel_confirm_password")} <span aria-hidden="true">*</span>
                          </label>
                          <input
                            id="reset-confirm-password"
                            name="confirm-password"
                            type="password"
                            autoComplete="new-password"
                            required
                            value={resetConfirmPassword}
                            onChange={(e) => setResetConfirmPassword(e.target.value)}
                            className="w-full px-3.5 py-2.5 rounded-[10px] border border-[#8A8A8A] text-base focus:outline-2 focus:outline-[#1B5888]"
                            placeholder="••••••••"
                          />
                        </div>
                      </>
                    )}

                    <button
                      type="submit"
                      disabled={authLoading}
                      className="w-full py-3 px-5 rounded-[10px] bg-[#1B5888] hover:bg-[#12406A] active:bg-[#12406A] disabled:opacity-60 text-white font-semibold text-sm transition-colors cursor-pointer"
                    >
                      {resetStep === 1
                        ? t("agency_panel_reset_btn")
                        : t("agency_panel_reset_confirm_btn")}
                    </button>

                    {resetStep === 2 && (
                      <button
                        type="button"
                        onClick={() => {
                          setResetStep(1);
                          setResetCode("");
                          setResetNewPassword("");
                          setResetConfirmPassword("");
                          setAuthError(null);
                          setAuthSuccess(null);
                        }}
                        className="w-full py-2 text-xs font-semibold text-[#666666] hover:text-[#1B5888] transition-colors cursor-pointer"
                      >
                        {t("agency_panel_reset_btn")}
                      </button>
                    )}
                  </form>
                )}

                {/* Divider + Interactive Demo CTA */}
                <div className="flex items-center gap-3 my-4 text-xs text-[#666666]">
                  <div className="flex-1 h-px bg-[#E5E3DF]" />
                  <span className="font-semibold">{t("agency_panel_demo_or")}</span>
                  <div className="flex-1 h-px bg-[#E5E3DF]" />
                </div>

                <button
                  ref={demoBtnRef}
                  type="button"
                  onClick={() => {
                    setDemoFormAgencyName("");
                    setDemoFormEmail("");
                    setDemoFormPhone(agencyPhone || "");
                    setDemoFormCity(agencyCity || "Beograd");
                    setIsDemoModalOpen(true);
                  }}
                  className="st-demo-glow-btn w-full min-h-[44px] inline-flex items-center justify-center gap-2 py-2.5 px-5 rounded-[10px] border-[1.5px] border-[#1B5888] text-[#1B5888] font-bold text-sm cursor-pointer"
                >
                  <Play className="w-4 h-4 text-[#1B5888] fill-[#1B5888]" />
                  <span>{t("agency_panel_demo_btn")}</span>
                  <ArrowRight className="w-4 h-4 text-[#1B5888]" />
                </button>
              </div>
            </section>
          </div>
        ) : (
          <div className={`flex flex-col lg:flex-row items-start transition-all duration-300 ${isSidebarCollapsed ? "gap-4 lg:gap-6" : "gap-6 lg:gap-8"
            }`}>
            {/* Desktop Left Sidebar Navigation */}
            <aside
              className={`w-full shrink-0 hidden lg:block sticky top-24 z-20 space-y-3 transition-all duration-300 ease-in-out ${isSidebarCollapsed ? "lg:w-[68px]" : "lg:w-64"
                }`}
            >
              {/* PRIMARY ENTRY: WELCOME & OVERVIEW */}
              <div
                className={`relative bg-white rounded-[10px] border border-[#E5E3DF] shadow-[0_1px_0_rgba(0,0,0,0.04),0_2px_8px_rgba(0,0,0,0.06)] p-1.5 transition-all duration-200 flex items-center gap-1.5`}
              >
                <button
                  type="button"
                  role="tab"
                  id="tab-welcome"
                  aria-controls="tabpanel-welcome"
                  aria-selected={activeTab === "welcome"}
                  onClick={() => setActiveTab("welcome")}
                  title={isSidebarCollapsed ? undefined : t("agency_panel_menu_welcome")}
                  aria-label={t("agency_panel_menu_welcome")}
                  className={`w-full flex items-center ${isSidebarCollapsed ? "justify-center p-2.5 relative group" : "px-3 py-2.5 flex-1 gap-2.5 min-w-0"
                    } rounded-lg text-xs font-semibold transition-all cursor-pointer ${activeTab === "welcome"
                      ? "bg-[#E5EEF6] text-[#1B5888] font-bold shadow-xs"
                      : "text-[#4A4A4A] hover:text-[#1A1A1A] hover:bg-[#F8F7F5]"
                    }`}
                >
                  <Compass className="w-4 h-4 shrink-0" />
                  {!isSidebarCollapsed && (
                    <span className="truncate">{t("agency_panel_menu_welcome")}</span>
                  )}
                  {isSidebarCollapsed && (
                    <div className="absolute left-full ml-3 top-1/2 -translate-y-1/2 px-2.5 py-1.5 bg-slate-900 text-white text-[11px] font-semibold rounded-md shadow-xl whitespace-nowrap opacity-0 pointer-events-none group-hover:opacity-100 transition-opacity duration-100 delay-0 z-50">
                      {t("agency_panel_menu_welcome")}
                      <div className="absolute right-full top-1/2 -translate-y-1/2 -mr-1 border-4 border-transparent border-r-slate-900" />
                    </div>
                  )}
                </button>

                {/* Sidebar Collapse / Expand Toggle Button (Overhanging Tab Handle on Right Edge when Collapsed) */}
                <button
                  type="button"
                  onClick={toggleSidebar}
                  className={
                    isSidebarCollapsed
                      ? "absolute -right-3 top-1/2 -translate-y-1/2 w-6 h-6 rounded-full bg-white border border-[#E5E3DF] shadow-[0_2px_6px_rgba(0,0,0,0.12)] flex items-center justify-center text-[#666666] hover:text-[#1B5888] hover:border-[#1B5888] hover:scale-110 transition-all cursor-pointer z-30 group"
                      : "p-2 rounded-lg text-[#666666] hover:text-[#1A1A1A] hover:bg-[#F8F7F5] transition-colors cursor-pointer shrink-0"
                  }
                  title={isSidebarCollapsed ? undefined : t("agency_panel_sidebar_collapse")}
                  aria-label={isSidebarCollapsed ? t("agency_panel_sidebar_expand") : t("agency_panel_sidebar_collapse")}
                >
                  {isSidebarCollapsed ? (
                    <>
                      <ChevronRight className="w-3.5 h-3.5 text-[#1B5888]" />
                      <div className="absolute left-full ml-3 top-1/2 -translate-y-1/2 px-2.5 py-1.5 bg-slate-900 text-white text-[11px] font-semibold rounded-md shadow-xl whitespace-nowrap opacity-0 pointer-events-none group-hover:opacity-100 transition-opacity duration-100 delay-0 z-50">
                        {t("agency_panel_sidebar_expand")}
                        <div className="absolute right-full top-1/2 -translate-y-1/2 -mr-1 border-4 border-transparent border-r-slate-900" />
                      </div>
                    </>
                  ) : (
                    <PanelLeftClose className="w-4 h-4" />
                  )}
                </button>
              </div>

              {/* Module-Independent Task Management Button (Right after Welcome, before Portfolio & Distribution) */}
              <div className="bg-white rounded-[10px] border border-[#E5E3DF] shadow-[0_1px_0_rgba(0,0,0,0.04),0_2px_8px_rgba(0,0,0,0.06)] p-1.5 transition-all duration-200">
                <button
                  type="button"
                  role="tab"
                  id="tab-tasks"
                  aria-controls="tabpanel-tasks"
                  aria-selected={activeTab === "tasks"}
                  onClick={() => setActiveTab("tasks")}
                  title={isSidebarCollapsed ? undefined : t("agency_tasks_menu_label")}
                  aria-label={t("agency_tasks_menu_label")}
                  className={`w-full flex items-center ${isSidebarCollapsed ? "justify-center p-2.5 relative group" : "justify-between px-3 py-2.5"
                    } rounded-lg text-xs font-semibold transition-all cursor-pointer ${activeTab === "tasks"
                      ? "bg-[#E5EEF6] text-[#1B5888] font-bold shadow-xs"
                      : "text-[#4A4A4A] hover:text-[#1A1A1A] hover:bg-[#F8F7F5]"
                    }`}
                >
                  <div className={`flex items-center ${isSidebarCollapsed ? "justify-center" : "gap-2.5 min-w-0"}`}>
                    <CheckSquare className="w-4 h-4 shrink-0" />
                    {!isSidebarCollapsed && (
                      <span className="truncate">{t("agency_tasks_menu_label")}</span>
                    )}
                  </div>
                  {!isSidebarCollapsed ? (
                    <span
                      className={`text-[10px] px-2 py-0.5 rounded-md font-mono font-bold shrink-0 tabular-nums ${activeTab === "tasks"
                        ? "bg-[#1B5888] text-white"
                        : "bg-[#F8F7F5] text-[#666666] border border-[#E5E3DF]"
                        }`}
                    >
                      {agencyTasks.filter((tk) => tk.status === "todo" || tk.status === "in_progress").length}
                    </span>
                  ) : (
                    <div className="absolute left-full ml-3 top-1/2 -translate-y-1/2 px-2.5 py-1.5 bg-slate-900 text-white text-[11px] font-semibold rounded-md shadow-xl whitespace-nowrap opacity-0 pointer-events-none group-hover:opacity-100 transition-opacity duration-100 delay-0 z-50">
                      {t("agency_tasks_menu_label")}
                      <div className="absolute right-full top-1/2 -translate-y-1/2 -mr-1 border-4 border-transparent border-r-slate-900" />
                    </div>
                  )}
                </button>
              </div>

              {/* CARD 1: MARKETING & SYNDICATION */}
              <div
                className={`bg-white rounded-[10px] border border-[#E5E3DF] shadow-[0_1px_0_rgba(0,0,0,0.04),0_2px_8px_rgba(0,0,0,0.06)] transition-all duration-200 ${isSidebarCollapsed ? "p-2 space-y-2" : "p-3 space-y-2.5"
                  }`}
              >
                {/* Module 1 Header (Portfolio & Distribution / P&D when Collapsed) */}
                {!isSidebarCollapsed ? (
                  <div className="px-2.5 pt-1.5 pb-1 flex items-center justify-between" title={t("agency_panel_nav_group_marketing")}>
                    <span className="text-xs font-semibold text-[#666666] truncate block">
                      {t("agency_panel_nav_group_marketing")}
                    </span>
                    {isPortfolioLocked && (
                      <span className="inline-flex items-center gap-1 text-[10px] font-bold text-[#8A5206] bg-[#FBF1DC] px-1.5 py-0.5 rounded border border-[#8A5206]/20 shrink-0">
                        <Lock className="w-2.5 h-2.5 text-[#8A5206]" />
                        <span>{t("agency_panel_pkg_available")}</span>
                      </span>
                    )}
                  </div>
                ) : (
                  <div
                    className="relative group/header flex items-center justify-center pb-1.5 mb-1 border-b border-[#E5E3DF] cursor-default select-none"
                    aria-label={t("agency_panel_nav_group_marketing")}
                  >
                    <span className="text-xs font-mono font-bold tracking-wider text-[#666666]">
                      P&amp;D
                    </span>
                    {/* Instant Hover Tooltip */}
                    <div className="absolute left-full ml-3 top-1/2 -translate-y-1/2 px-2.5 py-1.5 bg-slate-900 text-white text-[11px] font-semibold rounded-md shadow-xl whitespace-nowrap opacity-0 pointer-events-none group-hover/header:opacity-100 transition-opacity duration-100 delay-0 z-50">
                      {t("agency_panel_nav_group_marketing")}
                      <div className="absolute right-full top-1/2 -translate-y-1/2 -mr-1 border-4 border-transparent border-r-slate-900" />
                    </div>
                  </div>
                )}

                <div>
                  <nav
                    role="tablist"
                    aria-label={t("agency_panel_nav_group_marketing")}
                    className="space-y-1"
                  >
                    {/* 1. İlanlarım */}
                    <button
                      type="button"
                      role="tab"
                      id="tab-listings"
                      aria-controls="tabpanel-listings"
                      aria-selected={activeTab === "listings"}
                      onClick={() => setActiveTab("listings")}
                      title={isSidebarCollapsed ? undefined : `${t("agency_panel_menu_listings")} (${listings.length})`}
                      aria-label={`${t("agency_panel_menu_listings")} (${listings.length})`}
                      className={`w-full flex items-center ${isSidebarCollapsed ? "justify-center p-2.5 relative group" : "justify-between px-3 py-2.5"
                        } rounded-lg text-xs font-semibold transition-all cursor-pointer ${activeTab === "listings"
                          ? "bg-[#E5EEF6] text-[#1B5888] font-bold shadow-xs"
                          : "text-[#4A4A4A] hover:text-[#1A1A1A] hover:bg-[#F8F7F5]"
                        }`}
                    >
                      <div className={`flex items-center ${isSidebarCollapsed ? "justify-center" : "gap-2.5 min-w-0"}`}>
                        <Layers className="w-4 h-4 shrink-0" />
                        {!isSidebarCollapsed && <span className="truncate">{t("agency_panel_menu_listings")}</span>}
                      </div>
                      {!isSidebarCollapsed ? (
                        <span
                          className={`text-[11px] px-2 py-0.5 rounded-full font-bold shrink-0 ${activeTab === "listings" ? "bg-[#1B5888] text-white" : "bg-[#F8F7F5] text-[#666666] border border-[#E5E3DF]"
                            }`}
                        >
                          {listings.length}
                        </span>
                      ) : listings.length > 0 ? (
                        <span
                          className={`absolute -top-1 -right-1 text-[9px] px-1 min-w-[16px] h-4 rounded-full font-bold flex items-center justify-center leading-none ${activeTab === "listings" ? "bg-white text-[#1B5888] shadow-xs" : "bg-[#1B5888] text-white"
                            }`}
                        >
                          {listings.length > 99 ? "99+" : listings.length}
                        </span>
                      ) : null}
                      {isSidebarCollapsed && (
                        <div className="absolute left-full ml-3 top-1/2 -translate-y-1/2 px-2.5 py-1.5 bg-slate-900 text-white text-[11px] font-semibold rounded-md shadow-xl whitespace-nowrap opacity-0 pointer-events-none group-hover:opacity-100 transition-opacity duration-100 delay-0 z-50">
                          {`${t("agency_panel_menu_listings")} (${listings.length})`}
                          <div className="absolute right-full top-1/2 -translate-y-1/2 -mr-1 border-4 border-transparent border-r-slate-900" />
                        </div>
                      )}
                    </button>

                    {/* 2. Gelen Talepler & CRM */}
                    <button
                      type="button"
                      role="tab"
                      id="tab-leads"
                      aria-controls="tabpanel-leads"
                      aria-selected={activeTab === "leads"}
                      onClick={() => setActiveTab("leads")}
                      title={isSidebarCollapsed ? undefined : `${t("agency_panel_menu_leads")} (${leads.length})`}
                      aria-label={`${t("agency_panel_menu_leads")} (${leads.length})`}
                      className={`w-full flex items-center ${isSidebarCollapsed ? "justify-center p-2.5 relative group" : "justify-between px-3 py-2.5"
                        } rounded-lg text-xs font-semibold transition-all cursor-pointer ${activeTab === "leads"
                          ? "bg-[#E5EEF6] text-[#1B5888] font-bold shadow-xs"
                          : "text-[#4A4A4A] hover:text-[#1A1A1A] hover:bg-[#F8F7F5]"
                        }`}
                    >
                      <div className={`flex items-center ${isSidebarCollapsed ? "justify-center" : "gap-2.5 min-w-0"}`}>
                        <Inbox className="w-4 h-4 shrink-0" />
                        {!isSidebarCollapsed && <span className="truncate">{t("agency_panel_menu_leads")}</span>}
                      </div>
                      {!isSidebarCollapsed ? (
                        newLeadsCount > 0 ? (
                          <span
                            className={`text-[10px] px-2 py-0.5 rounded-md font-mono font-bold shrink-0 tabular-nums ${activeTab === "leads"
                              ? "bg-[#1B5888] text-white font-bold"
                              : "bg-[#E6F3EA] text-[#2A6E43]"
                              }`}
                          >
                            {newLeadsCount} {t("agency_panel_status_new")}
                          </span>
                        ) : (
                          <span
                            className={`text-[10px] px-2 py-0.5 rounded-md font-mono font-bold shrink-0 tabular-nums ${activeTab === "leads" ? "bg-[#1B5888] text-white" : "bg-[#F8F7F5] text-[#666666] border border-[#E5E3DF]"
                              }`}
                          >
                            {leads.length}
                          </span>
                        )
                      ) : newLeadsCount > 0 ? (
                        <span className="absolute -top-1 -right-1 w-2.5 h-2.5 rounded-full bg-emerald-500 animate-pulse ring-2 ring-white" />
                      ) : leads.length > 0 ? (
                        <span
                          className={`absolute -top-1 -right-1 text-[9px] px-1 min-w-[16px] h-4 rounded-md font-mono font-bold flex items-center justify-center leading-none tabular-nums ${activeTab === "leads" ? "bg-[#1B5888] text-white shadow-xs" : "bg-[#F8F7F5] text-[#4A4A4A] border border-[#E5E3DF]"
                            }`}
                        >
                          {leads.length > 99 ? "99+" : leads.length}
                        </span>
                      ) : null}
                      {isSidebarCollapsed && (
                        <div className="absolute left-full ml-3 top-1/2 -translate-y-1/2 px-2.5 py-1.5 bg-slate-900 text-white text-[11px] font-semibold rounded-md shadow-xl whitespace-nowrap opacity-0 pointer-events-none group-hover:opacity-100 transition-opacity duration-100 delay-0 z-50">
                          {`${t("agency_panel_menu_leads")} (${leads.length})`}
                          <div className="absolute right-full top-1/2 -translate-y-1/2 -mr-1 border-4 border-transparent border-r-slate-900" />
                        </div>
                      )}
                    </button>

                    {/* 3. XML Dağıtım & Portallar */}
                    <button
                      type="button"
                      role="tab"
                      id="tab-xml"
                      aria-controls="tabpanel-xml"
                      aria-selected={activeTab === "xml"}
                      onClick={() => setActiveTab("xml")}
                      title={isSidebarCollapsed ? undefined : `${t("agency_panel_menu_xml")} (${PORTAL_LIST.filter((p) => p.status === "live").length} ${t("agency_panel_portal_word")})`}
                      aria-label={`${t("agency_panel_menu_xml")} (${PORTAL_LIST.filter((p) => p.status === "live").length} ${t("agency_panel_portal_word")})`}
                      className={`w-full flex items-center ${isSidebarCollapsed ? "justify-center p-2.5 relative group" : "justify-between px-3 py-2.5"
                        } rounded-lg text-xs font-semibold transition-all cursor-pointer ${activeTab === "xml"
                          ? "bg-[#E5EEF6] text-[#1B5888] font-bold shadow-xs"
                          : "text-[#4A4A4A] hover:text-[#1A1A1A] hover:bg-[#F8F7F5]"
                        }`}
                    >
                      <div className={`flex items-center ${isSidebarCollapsed ? "justify-center" : "gap-2.5 min-w-0"}`}>
                        <Rss className="w-4 h-4 shrink-0" />
                        {!isSidebarCollapsed && <span className="truncate">{t("agency_panel_menu_xml")}</span>}
                      </div>
                      {!isSidebarCollapsed ? (
                        <span
                          className={`text-[10px] px-2 py-0.5 rounded-md font-mono font-bold shrink-0 tabular-nums ${activeTab === "xml" ? "bg-[#1B5888] text-white" : "bg-[#F8F7F5] text-[#666666] border border-[#E5E3DF]"
                            }`}
                        >
                          {PORTAL_LIST.filter((p) => p.status === "live").length} {t("agency_panel_portal_word")}
                        </span>
                      ) : (
                        <span
                          className={`absolute -top-1 -right-1 text-[9px] px-1 min-w-[16px] h-4 rounded-md font-mono font-bold flex items-center justify-center leading-none tabular-nums ${activeTab === "xml" ? "bg-[#1B5888] text-white shadow-xs" : "bg-[#F8F7F5] text-[#4A4A4A] border border-[#E5E3DF]"
                            }`}
                        >
                          {PORTAL_LIST.filter((p) => p.status === "live").length}
                        </span>
                      )}
                      {isSidebarCollapsed && (
                        <div className="absolute left-full ml-3 top-1/2 -translate-y-1/2 px-2.5 py-1.5 bg-slate-900 text-white text-[11px] font-semibold rounded-md shadow-xl whitespace-nowrap opacity-0 pointer-events-none group-hover:opacity-100 transition-opacity duration-100 delay-0 z-50">
                          {`${t("agency_panel_menu_xml")} (${PORTAL_LIST.filter((p) => p.status === "live").length} ${t("agency_panel_portal_word")})`}
                          <div className="absolute right-full top-1/2 -translate-y-1/2 -mr-1 border-4 border-transparent border-r-slate-900" />
                        </div>
                      )}
                    </button>

                    {/* 4. Agency Showcase (Canlı Vitrin Kısayolu) */}
                    {!isPortfolioLocked ? (
                      <a
                        href={showcaseUrl}
                        target="_blank"
                        rel="noopener noreferrer"
                        title={isSidebarCollapsed ? undefined : t("agency_panel_sidebar_vitrin_title")}
                        aria-label={t("agency_panel_sidebar_vitrin_title")}
                        className={`w-full flex items-center ${isSidebarCollapsed ? "justify-center p-2.5 relative group" : "justify-between px-3 py-2.5"
                          } rounded-lg text-xs font-semibold transition-all cursor-pointer text-[#4A4A4A] hover:text-[#1A1A1A] hover:bg-[#F8F7F5] group`}
                      >
                        <div className={`flex items-center ${isSidebarCollapsed ? "justify-center" : "gap-2.5 min-w-0"}`}>
                          <Globe className="w-4 h-4 shrink-0 text-[#666666] group-hover:text-[#1A1A1A] group-hover:scale-105 transition-transform" />
                          {!isSidebarCollapsed && <span className="truncate">{t("agency_panel_sidebar_vitrin_title")}</span>}
                        </div>
                        {!isSidebarCollapsed && (
                          <ArrowUpRight className="w-3.5 h-3.5 text-[#8A8A8A] group-hover:text-[#1A1A1A] transition-colors shrink-0" />
                        )}
                        {isSidebarCollapsed && (
                          <div className="absolute left-full ml-3 top-1/2 -translate-y-1/2 px-2.5 py-1.5 bg-slate-900 text-white text-[11px] font-semibold rounded-md shadow-xl whitespace-nowrap opacity-0 pointer-events-none group-hover:opacity-100 transition-opacity duration-100 delay-0 z-50">
                            {t("agency_panel_sidebar_vitrin_title")}
                            <div className="absolute right-full top-1/2 -translate-y-1/2 -mr-1 border-4 border-transparent border-r-slate-900" />
                          </div>
                        )}
                      </a>
                    ) : (
                      <button
                        type="button"
                        onClick={() => setActiveTab("account_settings")}
                        title={isSidebarCollapsed ? undefined : t("agency_panel_sidebar_vitrin_title")}
                        aria-label={t("agency_panel_sidebar_vitrin_title")}
                        className={`w-full flex items-center ${isSidebarCollapsed ? "justify-center p-2.5 relative group" : "justify-between px-3 py-2.5"
                          } rounded-lg text-xs font-semibold transition-all cursor-pointer text-[#4A4A4A] hover:text-[#1A1A1A] hover:bg-[#F8F7F5] group`}
                      >
                        <div className={`flex items-center ${isSidebarCollapsed ? "justify-center" : "gap-2.5 min-w-0"}`}>
                          <Globe className="w-4 h-4 shrink-0 text-[#8A8A8A] group-hover:text-[#1A1A1A] group-hover:scale-105 transition-transform" />
                          {!isSidebarCollapsed && <span className="truncate">{t("agency_panel_sidebar_vitrin_title")}</span>}
                        </div>
                        {!isSidebarCollapsed && (
                          <span className="p-1 rounded bg-amber-50 text-amber-700 border border-amber-200 font-bold shrink-0 inline-flex items-center">
                            <Lock className="w-2.5 h-2.5" />
                          </span>
                        )}
                        {isSidebarCollapsed && (
                          <div className="absolute left-full ml-3 top-1/2 -translate-y-1/2 px-2.5 py-1.5 bg-slate-900 text-white text-[11px] font-semibold rounded-md shadow-xl whitespace-nowrap opacity-0 pointer-events-none group-hover:opacity-100 transition-opacity duration-100 delay-0 z-50">
                            {t("agency_panel_sidebar_vitrin_title")}
                            <div className="absolute right-full top-1/2 -translate-y-1/2 -mr-1 border-4 border-transparent border-r-slate-900" />
                          </div>
                        )}
                      </button>
                    )}

                    {/* 5. Acente & Vitrin Ayarları */}
                    <button
                      type="button"
                      role="tab"
                      id="tab-settings"
                      aria-controls="tabpanel-settings"
                      aria-selected={activeTab === "settings"}
                      onClick={() => setActiveTab("settings")}
                      title={isSidebarCollapsed ? undefined : t("agency_panel_menu_settings")}
                      aria-label={t("agency_panel_menu_settings")}
                      className={`w-full flex items-center ${isSidebarCollapsed ? "justify-center p-2.5 relative group" : "justify-between px-3 py-2.5"
                        } rounded-lg text-xs font-semibold transition-all cursor-pointer ${activeTab === "settings"
                          ? "bg-[#E5EEF6] text-[#1B5888] font-bold shadow-xs"
                          : "text-[#4A4A4A] hover:text-[#1A1A1A] hover:bg-[#F8F7F5]"
                        }`}
                    >
                      <div className={`flex items-center ${isSidebarCollapsed ? "justify-center" : "gap-2.5 min-w-0"}`}>
                        <Settings className="w-4 h-4 shrink-0" />
                        {!isSidebarCollapsed && <span className="truncate">{t("agency_panel_menu_settings")}</span>}
                      </div>
                      {isSidebarCollapsed && (
                        <div className="absolute left-full ml-3 top-1/2 -translate-y-1/2 px-2.5 py-1.5 bg-slate-900 text-white text-[11px] font-semibold rounded-md shadow-xl whitespace-nowrap opacity-0 pointer-events-none group-hover:opacity-100 transition-opacity duration-100 delay-0 z-50">
                          {t("agency_panel_menu_settings")}
                          <div className="absolute right-full top-1/2 -translate-y-1/2 -mr-1 border-4 border-transparent border-r-slate-900" />
                        </div>
                      )}
                    </button>
                  </nav>
                </div>
              </div>

              {/* CARD 2: PROPERTY & LEASE MANAGEMENT (PMS) */}
              <div
                className={`bg-white rounded-[10px] border border-[#E5E3DF] shadow-[0_1px_0_rgba(0,0,0,0.04),0_2px_8px_rgba(0,0,0,0.06)] transition-all duration-200 ${isSidebarCollapsed ? "p-2 space-y-2" : "p-3 space-y-2.5"
                  }`}
              >
                {/* Module 2 Header (Property & Lease Management / P&L when Collapsed) */}
                {!isSidebarCollapsed ? (
                  <div className="px-2.5 pt-1.5 pb-1 flex items-center justify-between" title={t("agency_panel_nav_group_management")}>
                    <span className="text-xs font-semibold text-[#666666] truncate block">
                      {t("agency_panel_nav_group_management")}
                    </span>
                    {isPropertyLeaseLocked && (
                      <span className="inline-flex items-center gap-1 text-[10px] font-bold text-[#8A5206] bg-[#FBF1DC] px-1.5 py-0.5 rounded border border-[#8A5206]/20 shrink-0">
                        <Lock className="w-2.5 h-2.5 text-[#8A5206]" />
                        <span>{t("agency_panel_pkg_available")}</span>
                      </span>
                    )}
                  </div>
                ) : (
                  <div
                    className="relative group/header flex items-center justify-center pb-1.5 mb-1 border-b border-[#E5E3DF] cursor-default select-none"
                    aria-label={t("agency_panel_nav_group_management")}
                  >
                    <span className="text-xs font-mono font-bold tracking-wider text-[#666666]">
                      P&amp;L
                    </span>
                    {/* Instant Hover Tooltip */}
                    <div className="absolute left-full ml-3 top-1/2 -translate-y-1/2 px-2.5 py-1.5 bg-slate-900 text-white text-[11px] font-semibold rounded-md shadow-xl whitespace-nowrap opacity-0 pointer-events-none group-hover/header:opacity-100 transition-opacity duration-100 delay-0 z-50">
                      {t("agency_panel_nav_group_management")}
                      <div className="absolute right-full top-1/2 -translate-y-1/2 -mr-1 border-4 border-transparent border-r-slate-900" />
                    </div>
                  </div>
                )}

                <div>
                  <nav
                    role="tablist"
                    aria-label={t("agency_panel_nav_group_management")}
                    className="space-y-1"
                  >
                    {/* 1. Yönetilen Mülkler */}
                    <button
                      type="button"
                      role="tab"
                      id="tab-managed-properties"
                      aria-controls="tabpanel-managed-properties"
                      aria-selected={activeTab === "managed_properties"}
                      onClick={() => setActiveTab("managed_properties")}
                      title={isSidebarCollapsed ? undefined : `${t("agency_panel_menu_properties")} (${managedProperties.length})`}
                      aria-label={`${t("agency_panel_menu_properties")} (${managedProperties.length})`}
                      className={`w-full flex items-center ${isSidebarCollapsed ? "justify-center p-2.5 relative group" : "justify-between px-3 py-2.5"
                        } rounded-lg text-xs font-semibold transition-all cursor-pointer ${activeTab === "managed_properties"
                          ? "bg-[#E5EEF6] text-[#1B5888] font-bold shadow-xs"
                          : "text-[#4A4A4A] hover:text-[#1A1A1A] hover:bg-[#F8F7F5]"
                        }`}
                    >
                      <div className={`flex items-center ${isSidebarCollapsed ? "justify-center" : "gap-2.5 min-w-0"}`}>
                        <Home className="w-4 h-4 shrink-0" />
                        {!isSidebarCollapsed && <span className="truncate">{t("agency_panel_menu_properties")}</span>}
                      </div>
                      {!isSidebarCollapsed ? (
                        <span
                          className={`text-[10px] px-2 py-0.5 rounded-md font-mono font-bold shrink-0 tabular-nums ${activeTab === "managed_properties" ? "bg-[#1B5888] text-white" : "bg-[#F8F7F5] text-[#666666] border border-[#E5E3DF]"
                            }`}
                        >
                          {managedProperties.length}
                        </span>
                      ) : managedProperties.length > 0 ? (
                        <span
                          className={`absolute -top-1 -right-1 text-[9px] px-1 min-w-[16px] h-4 rounded-md font-mono font-bold flex items-center justify-center leading-none tabular-nums ${activeTab === "managed_properties" ? "bg-[#1B5888] text-white shadow-xs" : "bg-[#F8F7F5] text-[#4A4A4A] border border-[#E5E3DF]"
                            }`}
                        >
                          {managedProperties.length}
                        </span>
                      ) : null}
                      {isSidebarCollapsed && (
                        <div className="absolute left-full ml-3 top-1/2 -translate-y-1/2 px-2.5 py-1.5 bg-slate-900 text-white text-[11px] font-semibold rounded-md shadow-xl whitespace-nowrap opacity-0 pointer-events-none group-hover:opacity-100 transition-opacity duration-100 delay-0 z-50">
                          {`${t("agency_panel_menu_properties")} (${managedProperties.length})`}
                          <div className="absolute right-full top-1/2 -translate-y-1/2 -mr-1 border-4 border-transparent border-r-slate-900" />
                        </div>
                      )}
                    </button>

                    {/* 3. Finance & Payments */}
                    <button
                      type="button"
                      role="tab"
                      id="tab-payments"
                      aria-controls="tabpanel-payments"
                      aria-selected={activeTab === "payments"}
                      onClick={() => setActiveTab("payments")}
                      title={isSidebarCollapsed ? undefined : `${t("agency_panel_menu_payments")} (${payments.length})`}
                      aria-label={`${t("agency_panel_menu_payments")} (${payments.length})`}
                      className={`w-full flex items-center ${isSidebarCollapsed ? "justify-center p-2.5 relative group" : "justify-between px-3 py-2.5"
                        } rounded-lg text-xs font-semibold transition-all cursor-pointer ${activeTab === "payments"
                          ? "bg-[#E5EEF6] text-[#1B5888] font-bold shadow-xs"
                          : "text-[#4A4A4A] hover:text-[#1A1A1A] hover:bg-[#F8F7F5]"
                        }`}
                    >
                      <div className={`flex items-center ${isSidebarCollapsed ? "justify-center" : "gap-2.5 min-w-0"}`}>
                        <Wallet className="w-4 h-4 shrink-0" />
                        {!isSidebarCollapsed && <span className="truncate">{t("agency_panel_menu_payments")}</span>}
                      </div>
                      {!isSidebarCollapsed ? (
                        paymentStats.awaitingApproval > 0 ? (
                          <span
                            className={`text-[10px] px-2 py-0.5 rounded-md font-mono font-bold shrink-0 tabular-nums ${activeTab === "payments"
                              ? "bg-[#1B5888] text-white font-bold"
                              : "bg-[#FBF1DC] text-[#8A5206] animate-pulse"
                              }`}
                          >
                            {paymentStats.awaitingApproval}
                          </span>
                        ) : (
                          <span
                            className={`text-[10px] px-2 py-0.5 rounded-md font-mono font-bold shrink-0 tabular-nums ${activeTab === "payments" ? "bg-[#1B5888] text-white" : "bg-[#F8F7F5] text-[#666666] border border-[#E5E3DF]"
                              }`}
                          >
                            {payments.length}
                          </span>
                        )
                      ) : paymentStats.awaitingApproval > 0 ? (
                        <span className="absolute -top-1 -right-1 w-2.5 h-2.5 rounded-full bg-amber-400 animate-pulse ring-2 ring-white" />
                      ) : payments.length > 0 ? (
                        <span
                          className={`absolute -top-1 -right-1 text-[9px] px-1 min-w-[16px] h-4 rounded-md font-mono font-bold flex items-center justify-center leading-none tabular-nums ${activeTab === "payments" ? "bg-[#1B5888] text-white shadow-xs" : "bg-[#F8F7F5] text-[#4A4A4A] border border-[#E5E3DF]"
                            }`}
                        >
                          {payments.length}
                        </span>
                      ) : null}
                      {isSidebarCollapsed && (
                        <div className="absolute left-full ml-3 top-1/2 -translate-y-1/2 px-2.5 py-1.5 bg-slate-900 text-white text-[11px] font-semibold rounded-md shadow-xl whitespace-nowrap opacity-0 pointer-events-none group-hover:opacity-100 transition-opacity duration-100 delay-0 z-50">
                          {`${t("agency_panel_menu_payments")} (${payments.length})`}
                          <div className="absolute right-full top-1/2 -translate-y-1/2 -mr-1 border-4 border-transparent border-r-slate-900" />
                        </div>
                      )}
                    </button>

                    {/* 4. Arıza & Bakım Talepleri */}
                    <button
                      type="button"
                      role="tab"
                      id="tab-maintenance"
                      aria-controls="tabpanel-maintenance"
                      aria-selected={activeTab === "maintenance"}
                      onClick={() => setActiveTab("maintenance")}
                      title={isSidebarCollapsed ? undefined : `${t("agency_panel_menu_maintenance")} (${maintenanceRequests.length})`}
                      aria-label={`${t("agency_panel_menu_maintenance")} (${maintenanceRequests.length})`}
                      className={`w-full flex items-center ${isSidebarCollapsed ? "justify-center p-2.5 relative group" : "justify-between px-3 py-2.5"
                        } rounded-lg text-xs font-semibold transition-all cursor-pointer ${activeTab === "maintenance"
                          ? "bg-[#E5EEF6] text-[#1B5888] font-bold shadow-xs"
                          : "text-[#4A4A4A] hover:text-[#1A1A1A] hover:bg-[#F8F7F5]"
                        }`}
                    >
                      <div className={`flex items-center ${isSidebarCollapsed ? "justify-center" : "gap-2.5 min-w-0"}`}>
                        <Wrench className="w-4 h-4 shrink-0" />
                        {!isSidebarCollapsed && <span className="truncate">{t("agency_panel_menu_maintenance")}</span>}
                      </div>
                      {!isSidebarCollapsed ? (
                        <div className="flex items-center gap-1.5 shrink-0">
                          {maintenanceStats.openCount > 0 && (
                            <span className="w-2 h-2 rounded-full bg-rose-500 animate-pulse" />
                          )}
                          <span
                            className={`text-[10px] px-2 py-0.5 rounded-md font-mono font-bold tabular-nums ${activeTab === "maintenance"
                              ? "bg-[#1B5888] text-white"
                              : maintenanceStats.openCount > 0
                                ? "bg-[#FBEAE6] text-[#A33C29]"
                                : "bg-[#F8F7F5] text-[#666666] border border-[#E5E3DF]"
                              }`}
                          >
                            {maintenanceRequests.length}
                          </span>
                        </div>
                      ) : maintenanceStats.openCount > 0 ? (
                        <span className="absolute -top-1 -right-1 w-2.5 h-2.5 rounded-full bg-rose-500 animate-pulse ring-2 ring-white" />
                      ) : maintenanceRequests.length > 0 ? (
                        <span
                          className={`absolute -top-1 -right-1 text-[9px] px-1 min-w-[16px] h-4 rounded-md font-mono font-bold flex items-center justify-center leading-none tabular-nums ${activeTab === "maintenance" ? "bg-[#1B5888] text-white shadow-xs" : "bg-[#F8F7F5] text-[#4A4A4A] border border-[#E5E3DF]"
                            }`}
                        >
                          {maintenanceRequests.length}
                        </span>
                      ) : null}
                      {isSidebarCollapsed && (
                        <div className="absolute left-full ml-3 top-1/2 -translate-y-1/2 px-2.5 py-1.5 bg-slate-900 text-white text-[11px] font-semibold rounded-md shadow-xl whitespace-nowrap opacity-0 pointer-events-none group-hover:opacity-100 transition-opacity duration-100 delay-0 z-50">
                          {`${t("agency_panel_menu_maintenance")} (${maintenanceRequests.length})`}
                          <div className="absolute right-full top-1/2 -translate-y-1/2 -mr-1 border-4 border-transparent border-r-slate-900" />
                        </div>
                      )}
                    </button>
                  </nav>
                </div>
              </div>

              {/* Module-Independent App & Profile Settings Button (Desktop Sidebar) */}
              <div className="pt-1">
                <button
                  type="button"
                  role="tab"
                  id="tab-account-settings"
                  aria-controls="tabpanel-account-settings"
                  aria-selected={activeTab === "account_settings"}
                  onClick={() => setActiveTab("account_settings")}
                  title={isSidebarCollapsed ? undefined : t("agency_panel_menu_account_settings")}
                  aria-label={t("agency_panel_menu_account_settings")}
                  className={`w-full flex items-center ${isSidebarCollapsed ? "justify-center p-2.5 relative group" : "justify-between px-3 py-2.5"
                    } rounded-[10px] text-xs font-semibold transition-all cursor-pointer ${activeTab === "account_settings"
                      ? "bg-[#E5EEF6] text-[#1B5888] font-bold shadow-xs border border-[#1B5888]/20"
                      : "text-[#4A4A4A] hover:text-[#1A1A1A] hover:bg-[#F8F7F5] bg-white border border-[#E5E3DF] shadow-[0_1px_0_rgba(0,0,0,0.04)]"
                    }`}
                >
                  <div className={`flex items-center ${isSidebarCollapsed ? "justify-center" : "gap-2.5 min-w-0"}`}>
                    <User className="w-4 h-4 shrink-0" />
                    {!isSidebarCollapsed && (
                      <span className="truncate">{t("agency_panel_menu_account_settings")}</span>
                    )}
                  </div>
                  {!isSidebarCollapsed && <ChevronRight className="w-3.5 h-3.5 text-[#8A8A8A]" />}
                  {isSidebarCollapsed && (
                    <div className="absolute left-full ml-3 top-1/2 -translate-y-1/2 px-2.5 py-1.5 bg-slate-900 text-white text-[11px] font-semibold rounded-md shadow-xl whitespace-nowrap opacity-0 pointer-events-none group-hover:opacity-100 transition-opacity duration-100 delay-0 z-50">
                      {t("agency_panel_menu_account_settings")}
                      <div className="absolute right-full top-1/2 -translate-y-1/2 -mr-1 border-4 border-transparent border-r-slate-900" />
                    </div>
                  )}
                </button>
              </div>
            </aside>

            {/* Right Main Content */}
            <div className="flex-1 min-w-0 w-full space-y-6 pb-24 lg:pb-0">
              {/* Page Title & Subtitle in Right Frame */}
              <div className="pb-4 border-b border-[#E5E3DF] flex flex-col sm:flex-row sm:items-center justify-between gap-3 sm:gap-4">
                <div>
                  <h1 className="text-xl sm:text-2xl font-semibold text-[#1A1A1A] tracking-tight">
                    {activeTabTitle}
                  </h1>
                  {activeTabDescription && (
                    <p className="text-xs text-[#666666] mt-1 leading-normal">
                      {activeTabDescription}
                    </p>
                  )}
                </div>
                {activeTab === "listings" && (
                  <button
                    type="button"
                    onClick={handleAddNewListingClick}
                    className="inline-flex items-center gap-1.5 px-4 py-2 rounded-[10px] text-xs sm:text-sm font-semibold bg-[#1B5888] text-white hover:bg-[#15466d] shadow-2xs transition-colors cursor-pointer"
                  >
                    <Plus className="w-4 h-4" />
                    <span>{t("agency_panel_btn_new_listing")}</span>
                  </button>
                )}
                {activeTab === "maintenance" && !selectedMaintRequest && (
                  <button
                    type="button"
                    onClick={() => {
                      if (isDemoMode && !isDemoVerified) {
                        setIsGatekeeperModalOpen(true);
                        return;
                      }
                      if (managedProperties.length > 0) {
                        setNewMaintPropId(managedProperties[0].id);
                      }
                      setIsNewMaintModalOpen(true);
                    }}
                    className="inline-flex items-center gap-1.5 px-4 py-2 rounded-[10px] text-xs font-bold bg-[#1B5888] text-white hover:bg-[#15466d] transition-colors shadow-2xs cursor-pointer"
                  >
                    <Plus className="w-4 h-4" />
                    <span>{t("agency_maint_btn_new_request")}</span>
                  </button>
                )}
                {activeTab === "form" && (
                  <button
                    type="button"
                    onClick={() => setActiveTab("listings")}
                    className="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-[10px] border border-[#E5E3DF] hover:bg-slate-50 text-xs font-semibold text-[#4A4A4A] cursor-pointer shadow-2xs transition-colors shrink-0"
                  >
                    <ArrowLeft className="w-3.5 h-3.5" />
                    <span>{t("agency_panel_go_to_listings")}</span>
                  </button>
                )}
                {activeTab === "settings" && userId && (
                  <Link
                    href={showcaseUrl}
                    target="_blank"
                    className="inline-flex items-center justify-center gap-1.5 px-3.5 py-2 rounded-[10px] bg-[#E5EEF6] border border-[#1B5888]/20 hover:bg-[#d5e4f1] text-xs font-semibold text-[#1B5888] shadow-xs transition-colors shrink-0"
                  >
                    <Globe className="w-3.5 h-3.5" />
                    <span>{t("agency_panel_preview_tpl")}</span>
                    <ExternalLink className="w-3 h-3" />
                  </Link>
                )}
              </div>

              {/* Status Feedback Toast */}
              {statusMessage && (
                <div
                  role="status"
                  className={`p-4 rounded-[10px] border flex items-center justify-between gap-3 text-sm font-medium shadow-xs ${statusMessage.type === "success"
                    ? "bg-[#E6F3EA] border-[#2A6E43]/20 text-[#2A6E43]"
                    : "bg-[#FBEAE6] border-[#B5432E]/20 text-[#A33C29]"
                    }`}
                >
                  <div className="flex items-center gap-2.5">
                    {statusMessage.type === "success" ? (
                      <CheckCircle2 className="w-5 h-5 text-[#2A6E43] shrink-0" />
                    ) : (
                      <AlertCircle className="w-5 h-5 text-[#A33C29] shrink-0" />
                    )}
                    <span>{statusMessage.text}</span>
                  </div>
                  <button
                    type="button"
                    onClick={() => setStatusMessage(null)}
                    className="p-1 rounded-lg hover:bg-slate-200/50 text-[#666666] hover:text-[#1A1A1A] transition-colors cursor-pointer"
                    aria-label="Close"
                  >
                    <X className="w-4 h-4" />
                  </button>
                </div>
              )}

              {/* TAB 0: WELCOME & ONBOARDING HUB */}
              {activeTab === "welcome" && (
                <WelcomeTab
                  agencyName={agencyName}
                  agencyLogoUrl={agencyLogoUrl}
                  agencyPhone={agencyPhone}
                  agencyAddress={agencyAddress}
                  showcaseUrl={showcaseUrl}
                  isPortfolioEnabled={!isPortfolioLocked}
                  isPropertyLeaseEnabled={!isPropertyLeaseLocked}
                  activeModules={activeModules}
                  isDemoMode={isDemoMode}
                  demoFocus={demoFocus}
                  setDemoFocus={setDemoFocus}
                  listings={listings}
                  managedProperties={managedProperties}
                  managedPropertyStats={managedPropertyStats}
                  leads={leads}
                  payments={payments}
                  contracts={contracts}
                  maintenanceRequests={maintenanceRequests}
                  setActiveTab={setActiveTab}
                  setStatusMessage={setStatusMessage}
                  setPaymentStatusFilter={setPaymentStatusFilter}
                  setPropOccupancyFilter={setPropOccupancyFilter}
                  setLeadPoolFilter={setLeadPoolFilter}
                  setLeadStatusFilter={setLeadStatusFilter}
                  setMaintStatusFilter={setMaintStatusFilter}
                  moduleUpgradeRequested={moduleUpgradeRequested}
                  handleRequestModuleUpgrade={handleRequestModuleUpgrade}
                  handleActivateDemoModule={handleActivateDemoModule}
                  t={t}
                />
              )}

              {/* TAB 1: LISTINGS / PORTFOLIO */}
              {activeTab === "listings" && renderTabWithLockCheck("portfolio", (
                <ListingsTab
                  listings={listings}
                  loadingListings={loadingListings}
                  userId={userId}
                  isDemoMode={isDemoMode}
                  showcaseUrl={showcaseUrl}
                  fetchAgencyListings={fetchAgencyListings}
                  handleAddNewListingClick={handleAddNewListingClick}
                  loadListingIntoForm={loadListingIntoForm}
                  togglePublishStatus={togglePublishStatus}
                  handleDeleteListing={handleDeleteListing}
                  setActiveTab={setActiveTab}
                  t={t}
                  lang={lang}
                  activeModules={activeModules}
                  managedProperties={managedProperties}
                  onCloseAndHandoverListing={handleCloseAndHandoverListing}
                  onInspectManagedProperty={handleInspectManagedPropertyById}
                  onCreateTask={handleOpenCreateTask}
                  tasks={agencyTasks}
                  onViewListingTasks={(listingId) => {
                    setTaskPropertyFilter(null);
                    setTaskListingFilter(listingId);
                    setActiveTab("tasks");
                  }}
                />
              ))}

              {activeTab === "leads" && renderTabWithLockCheck("portfolio", (
                <LeadsTab
                  leads={leads}
                  onCreateTask={handleOpenCreateTask}
                  tasks={agencyTasks}
                  assignees={teamAssignees}
                  onQuickTaskStatus={handleQuickTaskStatus}
                  leadPoolFilter={leadPoolFilter}
                  setLeadPoolFilter={setLeadPoolFilter}
                  leadPoolCounts={leadPoolCounts}
                  leadStatusFilter={leadStatusFilter}
                  setLeadStatusFilter={setLeadStatusFilter}
                  leadSearchQuery={leadSearchQuery}
                  setLeadSearchQuery={setLeadSearchQuery}
                  filteredLeads={filteredLeads}
                  newCommentText={newCommentText}
                  setNewCommentText={setNewCommentText}
                  handleAddLeadComment={handleAddLeadComment}
                  handleConvertLeadToListing={handleConvertLeadToListing}
                  handleUpdateLeadStatus={handleUpdateLeadStatus}
                  activeLocale={activeLocale}
                  t={t}
                />
              ))}

              {/* TAB 2: ADD / EDIT LISTING FORM */}
              {activeTab === "form" && renderTabWithLockCheck("portfolio", (
                <ListingFormTab
                  leads={leads}
                  editingId={editingId}
                  convertingLeadId={convertingLeadId}
                  setConvertingLeadId={setConvertingLeadId}
                  title={title}
                  setTitle={setTitle}
                  externalRef={externalRef}
                  setExternalRef={setExternalRef}
                  transactionType={transactionType}
                  setTransactionType={setTransactionType}
                  propertyType={propertyType}
                  setPropertyType={setPropertyType}
                  price={price}
                  setPrice={setPrice}
                  currency={currency}
                  areaSqm={areaSqm}
                  setAreaSqm={setAreaSqm}
                  roomCount={roomCount}
                  setRoomCount={setRoomCount}
                  floor={floor}
                  setFloor={setFloor}
                  totalFloors={totalFloors}
                  setTotalFloors={setTotalFloors}
                  heatingType={heatingType}
                  setHeatingType={setHeatingType}
                  condition={condition}
                  setCondition={setCondition}
                  furnishing={furnishing}
                  setFurnishing={setFurnishing}
                  city={city}
                  municipality={municipality}
                  neighborhood={neighborhood}
                  setNeighborhood={setNeighborhood}
                  address={address}
                  setAddress={setAddress}
                  description={description}
                  setDescription={setDescription}
                  selectedAmenities={selectedAmenities}
                  setSelectedAmenities={setSelectedAmenities}
                  images={images}
                  manualImageUrl={manualImageUrl}
                  setManualImageUrl={setManualImageUrl}
                  isPublished={isPublished}
                  setIsPublished={setIsPublished}
                  savingListing={savingListing}
                  photoInputRef={photoInputRef}
                  uploadingPhotos={uploadingPhotos}
                  isDraggingOver={isDraggingOver}
                  setIsDraggingOver={setIsDraggingOver}
                  processFiles={processFiles}
                  val4Zida={val4Zida}
                  valHalo={valHalo}
                  availableMunicipalities={availableMunicipalities}
                  availableNeighborhoods={availableNeighborhoods}
                  handleCityChange={handleCityChange}
                  handleMunicipalityChange={handleMunicipalityChange}
                  handleFileUpload={handleFileUpload}
                  handleSaveListing={handleSaveListing}
                  resetForm={resetForm}
                  handleAddManualImageUrl={handleAddManualImageUrl}
                  setCoverImage={setCoverImage}
                  moveImage={moveImage}
                  removeImage={removeImage}
                  setActiveTab={setActiveTab}
                  t={t}
                  lang={lang}
                />
              ))}

              {/* TAB 3: XML DISTRIBUTION & PORTALS */}
              {activeTab === "xml" && renderTabWithLockCheck("portfolio", (
                <XmlFeedsTab
                  feedLogs={feedLogs}
                  loadingFeedLogs={loadingFeedLogs}
                  copiedPortal={copiedPortal}
                  publishedListingsCount={listings.filter((l) => l.is_published).length}
                  getFeedUrl={getFeedUrl}
                  formatTimeAgo={formatTimeAgo}
                  fetchFeedLogs={fetchFeedLogs}
                  handleCopyFeedUrl={handleCopyFeedUrl}
                  handleOpenPortalRequest={handleOpenPortalRequest}
                  t={t}
                />
              ))}

              {activeTab === "settings" && renderTabWithLockCheck("portfolio", (
                <SettingsTab
                  agencyName={agencyName}
                  setAgencyName={setAgencyName}
                  agencyPhone={agencyPhone}
                  setAgencyPhone={setAgencyPhone}
                  agencyEmail={agencyEmail}
                  setAgencyEmail={setAgencyEmail}
                  agencyWebsite={agencyWebsite}
                  setAgencyWebsite={setAgencyWebsite}
                  agencyCity={agencyCity}
                  setAgencyCity={setAgencyCity}
                  agencyAddress={agencyAddress}
                  setAgencyAddress={setAgencyAddress}
                  agencyLogoUrl={agencyLogoUrl}
                  setAgencyLogoUrl={setAgencyLogoUrl}
                  agencySlug={agencySlug}
                  setAgencySlug={setAgencySlug}
                  agencyCustomDomain={agencyCustomDomain}
                  setAgencyCustomDomain={setAgencyCustomDomain}
                  contactChannels={contactChannels}
                  setContactChannels={setContactChannels}
                  showcaseTemplate={showcaseTemplate}
                  handleSelectTemplate={handleSelectTemplate}
                  showcasePalette={showcasePalette}
                  setShowcasePalette={setShowcasePalette}
                  showcaseRadius={showcaseRadius}
                  setShowcaseRadius={setShowcaseRadius}
                  showcaseLanguages={showcaseLanguages}
                  setShowcaseLanguages={setShowcaseLanguages}
                  showcaseCurrencies={showcaseCurrencies}
                  setShowcaseCurrencies={setShowcaseCurrencies}
                  showcaseDefaultCurrency={showcaseDefaultCurrency}
                  setShowcaseDefaultCurrency={setShowcaseDefaultCurrency}
                  showcaseUrl={showcaseUrl}
                  dnsCheckResult={dnsCheckResult}
                  setDnsCheckResult={setDnsCheckResult}
                  dnsCheckLoading={dnsCheckLoading}
                  handleVerifyDns={handleVerifyDns}
                  handleSaveAgencyProfile={handleSaveAgencyProfile}
                  savingProfile={savingProfile}
                  uploadingLogo={uploadingLogo}
                  handleLogoFileUpload={handleLogoFileUpload}
                  userId={userId}
                  t={t}
                />
              ))}

              {/* TAB 4.4: MODULE-INDEPENDENT TASK MANAGEMENT */}
              {activeTab === "tasks" && (
                <TasksTab
                  tasks={agencyTasks}
                  loading={loadingTasks}
                  isAgencyAdmin={agencyRole === "agency_admin"}
                  currentUserId={currentUser?.id || userId}
                  assignees={teamAssignees}
                  properties={managedProperties}
                  listings={listings}
                  leads={leads}
                  maintenanceRequests={maintenanceRequests}
                  onOpenCreateModal={handleOpenCreateTask}
                  onOpenEditModal={(tk) => {
                    setEditingTask(tk);
                    setTaskPrefill(null);
                    setIsTaskModalOpen(true);
                  }}
                  onQuickStatusChange={handleQuickTaskStatus}
                  onQuickAssign={handleQuickTaskAssign}
                  onUpdateComments={handleUpdateTaskComments}
                  onDeleteTask={handleDeleteTask}
                  currentUserName={
                    teamAssignees.find((a) => a.id === (currentUser?.id || userId))?.name ||
                    currentUser?.email ||
                    agencyName ||
                    "User"
                  }
                  activeLocale={activeLocale}
                  onNavigateTab={setActiveTab}
                  initialPropertyFilter={taskPropertyFilter}
                  onClearPropertyFilter={() => setTaskPropertyFilter(null)}
                  initialListingFilter={taskListingFilter}
                  onClearListingFilter={() => setTaskListingFilter(null)}
                  t={t}
                />
              )}

              {/* Global Create / Edit Task Modal (usable from Tasks, Leads, Maintenance, Properties, Listings) */}
              <TaskFormModal
                isOpen={isTaskModalOpen}
                onClose={() => {
                  setIsTaskModalOpen(false);
                  setEditingTask(null);
                  setTaskPrefill(null);
                }}
                editingTask={editingTask}
                prefill={taskPrefill}
                isAgencyAdmin={agencyRole === "agency_admin"}
                currentUserId={currentUser?.id || userId}
                assignees={teamAssignees}
                properties={managedProperties}
                listings={listings}
                leads={leads}
                maintenanceRequests={maintenanceRequests}
                onSave={handleSaveTask}
                t={t}
              />

              {/* TAB 4.5: ACCOUNT & APP SETTINGS (MODULE-INDEPENDENT) */}
              {activeTab === "account_settings" && (
                <AccountSettingsTab
                  user={currentUser}
                  userId={userId}
                  agencyName={agencyName}
                  agencyEmail={agencyEmail}
                  agencyRole={agencyRole}
                  isAgencyAdmin={agencyRole === "agency_admin"}
                  isDemoMode={isDemoMode}
                  lang={lang}
                  setLang={setLang}
                  handleSignOut={handleSignOut}
                  t={t}
                  tSafe={tSafe}
                  activeModules={activeModules}
                  setActiveTab={setActiveTab}
                  moduleUpgradeRequested={moduleUpgradeRequested}
                  handleRequestModuleUpgrade={handleRequestModuleUpgrade}
                  onActivateModule={(modKey) => {
                    handleActivateDemoModule(modKey);
                  }}
                />
              )}

              {/* TAB 5: FINANCE & PAYMENTS */}
              {activeTab === "payments" && renderTabWithLockCheck("property_lease", (
                <PaymentsTab
                  payments={payments}
                  loadingPayments={loadingPayments}
                  paymentStats={paymentStats}
                  filteredPayments={filteredPayments}
                  processingPaymentId={processingPaymentId}
                  paymentStatusFilter={paymentStatusFilter}
                  setPaymentStatusFilter={setPaymentStatusFilter}
                  paymentSearchQuery={paymentSearchQuery}
                  setPaymentSearchQuery={setPaymentSearchQuery}
                  selectedReceiptPayment={selectedReceiptPayment}
                  setSelectedReceiptPayment={setSelectedReceiptPayment}
                  handleApprovePayment={handleApprovePayment}
                  handleRejectPayment={handleRejectPayment}
                  isDemoMode={isDemoMode}
                  activeLocale={activeLocale}
                  agencyName={agencyName}
                  t={t}
                  tSafe={tSafe}
                  managedProperties={managedProperties}
                  maintenanceRequests={maintenanceRequests}
                  contracts={contracts}
                  onInspectPayment={handleInspectPayment}
                />
              ))}

              {/* MANAGED PROPERTIES TAB (Faz 2) */}
              {activeTab === "managed_properties" && renderTabWithLockCheck("property_lease", (
                <ManagedPropertiesTab
                  filteredManagedProperties={filteredManagedProperties}
                  managedProperties={managedProperties}
                  managedPropertyStats={managedPropertyStats}
                  contracts={contracts}
                  setContracts={setContracts}
                  maintenanceRequests={maintenanceRequests}
                  setMaintenanceRequests={setMaintenanceRequests}
                  payments={payments}
                  setPayments={setPayments}
                  loadingProperties={loadingProperties}
                  propOccupancyFilter={propOccupancyFilter}
                  setPropOccupancyFilter={setPropOccupancyFilter}
                  propSearchQuery={propSearchQuery}
                  setPropSearchQuery={setPropSearchQuery}
                  handleConvertPropertyToListing={handleConvertPropertyToListing}
                  handleUpdateMaintenanceStatus={handleUpdateMaintenanceStatus}
                  handleApprovePayment={handleApprovePayment}
                  setSelectedReceiptPayment={setSelectedReceiptPayment}
                  setNewMaintPropId={setNewMaintPropId}
                  setIsNewMaintModalOpen={setIsNewMaintModalOpen}
                  isDemoMode={isDemoMode}
                  userId={userId}
                  t={t}
                  tSafe={tSafe}
                  setStatusMessage={setStatusMessage}
                  setManagedProperties={setManagedProperties}
                  selectedReceiptPayment={selectedReceiptPayment}
                  processingPaymentId={processingPaymentId}
                  setProcessingPaymentId={setProcessingPaymentId}
                  updatingMaintId={updatingMaintId}
                  initialSelectedProperty={drawerProperty}
                  initialExpandedPaymentId={drawerTargetPaymentId}
                  onBackFromDrawer={handleBackFromDrawer}
                  agencyName={agencyName}
                  agencyEmail={agencyEmail}
                  isDemoVerified={isDemoVerified}
                  onRequestVerification={() => setIsGatekeeperModalOpen(true)}
                  listings={listings}
                  activeModules={activeModules}
                  setActiveTab={setActiveTab}
                  onOpenMaintenanceRequest={(req) => {
                    setSelectedMaintRequest(req);
                    setActiveTab("maintenance");
                  }}
                  onQuickRelistProperty={handleQuickRelistProperty}
                  onCreateTask={handleOpenCreateTask}
                  tasks={agencyTasks}
                  onViewPropertyTasks={(propId) => {
                    setTaskListingFilter(null);
                    setTaskPropertyFilter(propId);
                    setActiveTab("tasks");
                  }}
                />
              ))}

              {activeTab === "pm_dashboard" && renderTabWithLockCheck("property_lease", (
                <PmDashboardTab
                  agencyName={agencyName}
                  managedProperties={managedProperties}
                  managedPropertyStats={managedPropertyStats}
                  payments={payments}
                  contracts={contracts}
                  maintenanceRequests={maintenanceRequests}
                  setActiveTab={setActiveTab}
                  setPaymentStatusFilter={setPaymentStatusFilter}
                  setPropOccupancyFilter={setPropOccupancyFilter}
                  resetForm={resetForm}
                  setNewMaintPropId={setNewMaintPropId}
                  setIsNewMaintModalOpen={setIsNewMaintModalOpen}
                  isDemoMode={isDemoMode}
                  isDemoVerified={isDemoVerified}
                  onRequestVerification={() => setIsGatekeeperModalOpen(true)}
                  t={t}
                />
              ))}

              {/* MAINTENANCE & REPAIRS DESK TAB (Faz 3) */}
              {activeTab === "maintenance" && renderTabWithLockCheck("property_lease", (
                <MaintenanceTab
                  maintenanceRequests={maintenanceRequests}
                  loadingMaintenance={loadingMaintenance}
                  maintenanceStats={maintenanceStats}
                  filteredMaintenanceRequests={filteredMaintenanceRequests}
                  managedProperties={managedProperties}
                  setNewMaintPropId={setNewMaintPropId}
                  setIsNewMaintModalOpen={setIsNewMaintModalOpen}
                  maintStatusFilter={maintStatusFilter}
                  setMaintStatusFilter={setMaintStatusFilter}
                  maintSearchQuery={maintSearchQuery}
                  setMaintSearchQuery={setMaintSearchQuery}
                  updatingMaintId={updatingMaintId}
                  handleUpdateMaintenanceStatus={handleUpdateMaintenanceStatus}
                  onSelectRequest={setSelectedMaintRequest}
                  selectedRequest={selectedMaintRequest}
                  onBackFromDetail={() => setSelectedMaintRequest(null)}
                  onNavigateToProperty={handleInspectProperty}
                  onCreateTask={handleOpenCreateTask}
                  tasks={agencyTasks}
                  assignees={teamAssignees}
                  onQuickTaskStatus={handleQuickTaskStatus}
                  onUpdateRequest={(updated) => {
                    setMaintenanceRequests((prev) =>
                      prev.map((m) => (m.id === updated.id ? updated : m))
                    );
                    setSelectedMaintRequest(updated);
                  }}
                  userId={userId}
                  isDemoMode={isDemoMode}
                  isDemoVerified={isDemoVerified}
                  onRequestVerification={() => setIsGatekeeperModalOpen(true)}
                  t={t}
                />
              ))}

              {/* AGENCY PANEL FOOTER */}
              <footer className="mt-12 pt-6 pb-2 border-t border-[#E5E3DF] flex flex-col sm:flex-row items-center justify-between gap-4 text-xs text-[#666666]">
                <div className="flex items-center gap-2.5">
                  <img src="/favicon.png" alt="Stanomer" className="w-4 h-4 rounded-xs object-contain" />
                  <span className="font-medium text-[#4A4A4A]">
                    {t("agency_panel_footer_developed_by")}
                  </span>
                </div>

                <div className="flex items-center gap-3 flex-wrap justify-center">
                  <span className="font-medium text-[#666666]">
                    {t("agency_panel_footer_support_contact")}
                  </span>

                  {/* Official WhatsApp Icon */}
                  <a
                    href="https://wa.me/381616036556?text=Zdravo%2C%20javljam%20se%20u%20vezi%20Stanomer%20platforme."
                    target="_blank"
                    rel="noopener noreferrer"
                    aria-label="WhatsApp"
                    title="WhatsApp"
                    className="inline-flex items-center justify-center w-8 h-8 rounded-full bg-[#25D366] hover:bg-[#20BA5A] active:bg-[#1EAE54] text-white transition-all shadow-2xs hover:scale-105 cursor-pointer"
                  >
                    <svg viewBox="0 0 24 24" width="16" height="16" fill="currentColor" aria-hidden="true">
                      <path d="M17.472 14.382c-.301-.15-1.78-.879-2.056-.98-.276-.1-.477-.15-.678.15-.201.3-.777.98-.953 1.18-.176.2-.352.226-.653.076-.301-.15-1.272-.469-2.423-1.496-.896-.799-1.501-1.786-1.677-2.087-.176-.3-.019-.462.132-.612.136-.135.301-.351.452-.527.15-.176.201-.301.301-.502.1-.201.05-.376-.025-.527-.075-.15-.678-1.634-.929-2.237-.245-.588-.494-.508-.678-.518-.176-.008-.376-.01-.577-.01-.201 0-.527.075-.803.376s-1.054 1.03-1.054 2.511c0 1.481 1.079 2.91 1.23 3.111.15.201 2.124 3.243 5.145 4.548.719.311 1.28.497 1.718.636.722.23 1.378.198 1.898.12.579-.087 1.78-.727 2.031-1.43.251-.703.251-1.305.176-1.43-.075-.125-.276-.201-.577-.351zM12.04 2C6.52 2 2.03 6.49 2.03 12c0 1.96.57 3.84 1.65 5.44L2 22l4.69-1.63c1.55.98 3.36 1.5 5.35 1.5 5.52 0 10.01-4.49 10.01-10s-4.49-10-10.01-10z" />
                    </svg>
                  </a>

                  {/* Official Viber Icon */}
                  <a
                    href="viber://chat?number=%2B381616036556"
                    aria-label="Viber"
                    title="Viber"
                    className="inline-flex items-center justify-center w-8 h-8 rounded-full bg-[#7360F2] hover:bg-[#6350E5] active:bg-[#5744DA] text-white transition-all shadow-2xs hover:scale-105 cursor-pointer"
                  >
                    <svg viewBox="0 0 24 24" width="16" height="16" fill="currentColor" aria-hidden="true">
                      <path d="M11.398.002C9.473.028 5.331.344 3.014 2.467 1.294 4.177.696 6.678.633 9.776c-.066 3.099-.145 8.912 5.468 10.486h.005l-.005 2.404s-.037.973.605 1.17c.773.24 1.227-.497 1.966-1.294.405-.437.963-1.078 1.384-1.57 3.816.32 6.748-.414 7.081-.522.77-.249 5.128-.808 5.837-6.594.731-5.961-.355-9.726-2.318-11.417l-.003-.003c-.605-.557-3.047-2.353-8.485-2.433 0 0-.318-.01-.77-.001zm.074 1.703c.38-.004.651.015.651.015 4.65.034 6.865 1.417 7.382 1.886 1.678 1.437 2.536 4.864 1.964 9.947-.606 4.946-4.184 5.265-4.843 5.479-.284.092-2.912.742-6.215.529 0 0-2.46 2.965-3.226 3.738-.122.123-.264.171-.358.149-.133-.033-.17-.191-.169-.417.003-.331.021-4.113.021-4.113C2.104 17.648 2.38 12.88 2.435 10.23c.055-2.648.554-4.819 2.035-6.277 1.981-1.815 5.424-2.226 7.002-2.248zm.19 2.745a.442.442 0 0 0-.013.884c2.884.022 5.224 2.28 5.257 5.225a.442.442 0 0 0 .884-.01c-.038-3.428-2.762-6.074-6.128-6.099zm.168 1.988a.442.442 0 0 0-.015.884c1.825.032 3.268 1.484 3.307 3.314a.442.442 0 0 0 .884-.018c-.046-2.31-1.874-4.14-4.176-4.18zm-4.104.045c-.368.006-.746.166-1.057.44-.568.5-.863 1.242-.721 1.978.329 1.71 1.183 3.412 2.48 4.777 1.298 1.365 2.95 2.326 4.636 2.757.728.187 1.485-.063 2.017-.6.382-.386.578-.928.431-1.425-.11-.373-.405-.655-.74-.863-.525-.326-1.073-.619-1.615-.92-.437-.243-.968-.263-1.367.06-.202.163-.35.394-.545.565-.225.198-.522.255-.8.133-.95-.418-1.766-1.158-2.244-2.078-.14-.27-.103-.57.082-.808.158-.204.377-.367.526-.578.299-.423.249-.953-.02-1.377-.33-.52-.65-1.05-.999-1.552-.23-.331-.576-.488-.964-.41zm4.274 1.91a.442.442 0 0 0-.027.884c.786.046 1.368.636 1.41 1.425a.442.442 0 0 0 .883-.047c-.065-1.244-1.022-2.19-2.266-2.262z" />
                    </svg>
                  </a>
                </div>
              </footer>
            </div>
          </div>
        )}
        {/* NEW MAINTENANCE REQUEST MODAL */}
        {isNewMaintModalOpen && (
          <div
            role="dialog"
            aria-modal="true"
            aria-labelledby="new-maint-modal-title"
            className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/50 backdrop-blur-xs animate-in fade-in duration-200"
          >
            <div className="bg-white rounded-[10px] border border-[#E5E3DF] shadow-xl max-w-lg w-full p-6 space-y-4 max-h-[90vh] overflow-y-auto">
              <div className="flex items-start justify-between gap-3 border-b border-slate-100 pb-3">
                <div className="flex items-center gap-2.5">
                  <div className="w-10 h-10 rounded-[10px] bg-[#E5EEF6] text-[#1B5888] flex items-center justify-center shrink-0">
                    <Wrench className="w-5 h-5" />
                  </div>
                  <div>
                    <h3 id="new-maint-modal-title" className="text-base font-bold text-[#1A1A1A]">
                      {t("agency_maint_modal_title")}
                    </h3>
                    <p className="text-xs text-[#666666] mt-0.5">
                      {t("agency_maint_modal_desc")}
                    </p>
                  </div>
                </div>
                <button
                  type="button"
                  onClick={() => setIsNewMaintModalOpen(false)}
                  className="text-[#666666] hover:text-[#4A4A4A] p-1 cursor-pointer rounded-lg hover:bg-slate-100 transition-colors"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>

              <form onSubmit={handleCreateMaintenanceRequest} className="space-y-3.5">
                {/* 1. Mülk Seçimi */}
                <div>
                  <label className="block text-xs font-semibold text-[#4A4A4A] mb-1">
                    {t("agency_maint_modal_field_prop")} *
                  </label>
                  <select
                    required
                    value={newMaintPropId}
                    onChange={(e) => setNewMaintPropId(e.target.value)}
                    className="w-full px-3 py-2 rounded-[10px] border border-[#E5E3DF] text-xs text-[#1A1A1A] focus:outline-hidden focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 bg-white"
                  >
                    <option value="" disabled>-- Seçin --</option>
                    {managedProperties.map((p) => (
                      <option key={p.id} value={p.id}>
                        {p.title} ({p.address})
                      </option>
                    ))}
                  </select>
                </div>

                {/* 2. Kategori Seçimi (Visual Category Cards with Icons - Flutter Parity) */}
                <div className="space-y-1.5">
                  <label className="block text-xs font-semibold text-[#4A4A4A]">
                    {t("agency_maint_modal_field_cat")}
                  </label>
                  <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
                    {MAINTENANCE_CATEGORIES.map((cat) => {
                      const isSelected =
                        newMaintCategory === cat.key ||
                        (newMaintCategory === "appliance" && cat.key === "appliances");
                      const CatIcon = cat.icon;
                      return (
                        <button
                          key={cat.key}
                          type="button"
                          onClick={() => setNewMaintCategory(cat.key as any)}
                          className={`p-2 rounded-[10px] border flex items-center gap-2 text-left transition-all cursor-pointer ${isSelected
                            ? "border-[#1B5888] bg-blue-50/70 ring-2 ring-[#1B5888]/20 text-[#1B5888] font-bold shadow-2xs"
                            : "border-[#E5E3DF] bg-white hover:bg-slate-50 text-slate-700"
                            }`}
                        >
                          <div
                            className={`w-7 h-7 rounded-lg flex items-center justify-center shrink-0 ${cat.bgClass} ${cat.textClass} border ${cat.borderClass}`}
                          >
                            <CatIcon className="w-3.5 h-3.5" />
                          </div>
                          <span className="text-xs truncate">{t(cat.translationKey)}</span>
                        </button>
                      );
                    })}
                  </div>
                </div>

                {/* 2.1. Öncelik */}
                <div>
                  <label className="block text-xs font-semibold text-[#4A4A4A] mb-1">
                    {t("agency_maint_modal_field_prio")}
                  </label>
                  <select
                    value={newMaintPriority}
                    onChange={(e) => setNewMaintPriority(e.target.value as any)}
                    className="w-full px-3 py-2 rounded-[10px] border border-[#E5E3DF] text-xs text-[#1A1A1A] focus:outline-hidden focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 bg-white"
                  >
                    <option value="urgent">{t("agency_maint_priority_urgent")}</option>
                    <option value="high">{t("agency_maint_priority_high")}</option>
                    <option value="normal">{t("agency_maint_priority_normal")}</option>
                    <option value="low">{t("agency_maint_priority_low")}</option>
                  </select>
                </div>

                {/* 3. Başlık */}
                <div>
                  <label className="block text-xs font-semibold text-[#4A4A4A] mb-1">
                    {t("agency_maint_modal_field_title")} *
                  </label>
                  <input
                    type="text"
                    required
                    value={newMaintTitle}
                    onChange={(e) => setNewMaintTitle(e.target.value)}
                    placeholder="örn: Mutfak bataryasında su sızıntısı"
                    className="w-full px-3 py-2 rounded-[10px] border border-[#E5E3DF] text-xs text-[#1A1A1A] focus:outline-hidden focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 bg-white"
                  />
                </div>

                {/* 4. Açıklama */}
                <div>
                  <label className="block text-xs font-semibold text-[#4A4A4A] mb-1">
                    {t("agency_maint_modal_field_desc")}
                  </label>
                  <textarea
                    rows={3}
                    value={newMaintDescription}
                    onChange={(e) => setNewMaintDescription(e.target.value)}
                    placeholder="Arızanın boyutu, kiracının belirttiği detaylar..."
                    className="w-full px-3 py-2 rounded-[10px] border border-[#E5E3DF] text-xs text-[#1A1A1A] focus:outline-hidden focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 bg-white resize-none"
                  />
                </div>

                {/* 5. Masraf Durumu: Belli mi, Değil mi? */}
                <div className="space-y-2 pt-1 border-t border-slate-100">
                  <label className="block text-xs font-bold text-[#1A1A1A]">
                    {t("agency_maint_modal_expense_status_label")}
                  </label>
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
                    <button
                      type="button"
                      onClick={() => setNewMaintHasExpense(false)}
                      className={`p-3 rounded-[10px] border text-left transition-all cursor-pointer ${!newMaintHasExpense
                        ? "bg-blue-50/70 border-[#1B5888] text-[#1B5888] shadow-2xs"
                        : "bg-white border-slate-200 text-slate-700 hover:bg-slate-50"
                        }`}
                    >
                      <div className="flex items-center gap-2">
                        <input
                          type="radio"
                          name="maintExpenseStatus"
                          checked={!newMaintHasExpense}
                          onChange={() => setNewMaintHasExpense(false)}
                          className="text-[#1B5888]"
                        />
                        <span className="text-xs font-bold">
                          {t("agency_maint_modal_expense_unknown")}
                        </span>
                      </div>
                      <p className="text-[11px] text-slate-500 mt-1 pl-5">
                        {t("agency_maint_modal_expense_unknown_sub")}
                      </p>
                    </button>

                    <button
                      type="button"
                      onClick={() => setNewMaintHasExpense(true)}
                      className={`p-3 rounded-[10px] border text-left transition-all cursor-pointer ${newMaintHasExpense
                        ? "bg-blue-50/70 border-[#1B5888] text-[#1B5888] shadow-2xs"
                        : "bg-white border-slate-200 text-slate-700 hover:bg-slate-50"
                        }`}
                    >
                      <div className="flex items-center gap-2">
                        <input
                          type="radio"
                          name="maintExpenseStatus"
                          checked={newMaintHasExpense}
                          onChange={() => setNewMaintHasExpense(true)}
                          className="text-[#1B5888]"
                        />
                        <span className="text-xs font-bold">
                          {t("agency_maint_modal_expense_known")}
                        </span>
                      </div>
                      <p className="text-[11px] text-slate-500 mt-1 pl-5">
                        {t("agency_maint_modal_expense_known_sub")}
                      </p>
                    </button>
                  </div>
                </div>

                {/* 6. Finansal Detaylar & Fatura (Masraf Belli ise) */}
                {newMaintHasExpense && (
                  <div className="p-4 rounded-[10px] border border-blue-200 bg-blue-50/30 space-y-3.5 animate-in fade-in duration-150">
                    <div className="flex items-center gap-2 pb-2 border-b border-blue-100">
                      <DollarSign className="w-4 h-4 text-[#1B5888]" />
                      <span className="text-xs font-bold text-slate-900">
                        {t("agency_maint_modal_financial_title")}
                      </span>
                    </div>

                    {/* Cost & Currency & Payment Date */}
                    <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                      <div className="sm:col-span-1">
                        <label className="block text-[11px] font-bold text-slate-700 mb-1">
                          {t("agency_maint_cost_label")} *
                        </label>
                        <input
                          type="number"
                          step="0.01"
                          min="0"
                          required={newMaintHasExpense}
                          value={newMaintCost}
                          onChange={(e) => setNewMaintCost(e.target.value)}
                          placeholder="0.00"
                          className="w-full px-3 py-2 rounded-lg border border-slate-200 text-xs font-mono focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 bg-white"
                        />
                      </div>

                      <div>
                        <label className="block text-[11px] font-bold text-slate-700 mb-1">
                          {t("agency_props_field_currency")}
                        </label>
                        <select
                          value={newMaintCurrency}
                          onChange={(e) => setNewMaintCurrency(e.target.value)}
                          className="w-full px-3 py-2 rounded-lg border border-slate-200 text-xs font-bold text-slate-800 bg-white"
                        >
                          <option value="EUR">EUR (€)</option>
                          <option value="RSD">RSD (дин)</option>
                        </select>
                      </div>

                      <div>
                        <label className="block text-[11px] font-bold text-slate-700 mb-1">
                          {t("agency_maint_payment_date_label")}
                        </label>
                        <input
                          type="date"
                          value={newMaintPaymentDate}
                          onChange={(e) => setNewMaintPaymentDate(e.target.value)}
                          className="w-full px-3 py-2 rounded-lg border border-slate-200 text-xs text-slate-800 bg-white"
                        />
                      </div>
                    </div>

                    {/* Who Paid */}
                    <div>
                      <label className="block text-[11px] font-bold text-slate-700 mb-1.5">
                        {t("agency_maint_payer_label")} *
                      </label>
                      <div className="grid grid-cols-3 gap-2">
                        {(["tenant", "landlord", "agency"] as const).map((p) => (
                          <button
                            key={p}
                            type="button"
                            onClick={() => {
                              setNewMaintPayer(p);
                              if (p === "tenant") setNewMaintIntent("reimburse");
                              else if (p === "landlord") setNewMaintIntent("self");
                              else if (p === "agency") setNewMaintIntent("fixture_landlord");
                            }}
                            className={`py-2 px-2.5 rounded-lg text-xs font-bold border transition-all cursor-pointer ${newMaintPayer === p
                              ? "bg-[#1B5888] text-white border-[#1B5888] shadow-xs"
                              : "bg-white text-slate-700 border-slate-200 hover:bg-slate-50"
                              }`}
                          >
                            {t("agency_maint_payer_" + p)}
                          </button>
                        ))}
                      </div>
                    </div>

                    {/* Settlement Intent based on Payer */}
                    <div className="space-y-1.5">
                      <label className="block text-[11px] font-bold text-slate-700">
                        {t("agency_maint_intent_label")} *
                      </label>

                      {newMaintPayer === "tenant" && (
                        <div className="space-y-2">
                          <label
                            className={`flex items-start gap-2 p-2.5 rounded-lg border cursor-pointer transition-colors ${newMaintIntent === "reimburse"
                              ? "bg-white border-[#1B5888] text-[#1B5888] shadow-2xs"
                              : "bg-white/80 border-slate-200 hover:bg-white text-slate-700"
                              }`}
                          >
                            <input
                              type="radio"
                              name="newMaintIntent"
                              value="reimburse"
                              checked={newMaintIntent === "reimburse"}
                              onChange={() => setNewMaintIntent("reimburse")}
                              className="mt-0.5 text-[#1B5888]"
                            />
                            <div className="text-xs">
                              <span className="font-bold block">
                                {t("agency_maint_intent_tenant_reimburse")}
                              </span>
                              <span className="text-[11px] text-slate-500">
                                {t("agency_maint_intent_tenant_reimburse_sub")}
                              </span>
                            </div>
                          </label>

                          <label
                            className={`flex items-start gap-2 p-2.5 rounded-lg border cursor-pointer transition-colors ${newMaintIntent === "self"
                              ? "bg-white border-[#1B5888] text-[#1B5888] shadow-2xs"
                              : "bg-white/80 border-slate-200 hover:bg-white text-slate-700"
                              }`}
                          >
                            <input
                              type="radio"
                              name="newMaintIntent"
                              value="self"
                              checked={newMaintIntent === "self"}
                              onChange={() => setNewMaintIntent("self")}
                              className="mt-0.5 text-[#1B5888]"
                            />
                            <div className="text-xs">
                              <span className="font-bold block">
                                {t("agency_maint_intent_tenant_self")}
                              </span>
                              <span className="text-[11px] text-slate-500">
                                {t("agency_maint_intent_tenant_self_sub")}
                              </span>
                            </div>
                          </label>
                        </div>
                      )}

                      {newMaintPayer === "landlord" && (
                        <div className="space-y-2">
                          <label
                            className={`flex items-start gap-2 p-2.5 rounded-lg border cursor-pointer transition-colors ${newMaintIntent === "self"
                              ? "bg-white border-[#1B5888] text-[#1B5888] shadow-2xs"
                              : "bg-white/80 border-slate-200 hover:bg-white text-slate-700"
                              }`}
                          >
                            <input
                              type="radio"
                              name="newMaintIntent"
                              value="self"
                              checked={newMaintIntent === "self"}
                              onChange={() => setNewMaintIntent("self")}
                              className="mt-0.5 text-[#1B5888]"
                            />
                            <div className="text-xs">
                              <span className="font-bold block">
                                {t("agency_maint_intent_landlord_self")}
                              </span>
                              <span className="text-[11px] text-slate-500">
                                {t("agency_maint_intent_landlord_self_sub")}
                              </span>
                            </div>
                          </label>

                          <label
                            className={`flex items-start gap-2 p-2.5 rounded-lg border cursor-pointer transition-colors ${newMaintIntent === "charge_tenant"
                              ? "bg-white border-[#1B5888] text-[#1B5888] shadow-2xs"
                              : "bg-white/80 border-slate-200 hover:bg-white text-slate-700"
                              }`}
                          >
                            <input
                              type="radio"
                              name="newMaintIntent"
                              value="charge_tenant"
                              checked={newMaintIntent === "charge_tenant"}
                              onChange={() => setNewMaintIntent("charge_tenant")}
                              className="mt-0.5 text-[#1B5888]"
                            />
                            <div className="text-xs">
                              <span className="font-bold block">
                                {t("agency_maint_intent_landlord_tenant")}
                              </span>
                              <span className="text-[11px] text-slate-500">
                                {t("agency_maint_intent_landlord_tenant_sub")}
                              </span>
                            </div>
                          </label>
                        </div>
                      )}

                      {newMaintPayer === "agency" && (
                        <div className="space-y-2">
                          <label
                            className={`flex items-start gap-2 p-2.5 rounded-lg border cursor-pointer transition-colors ${newMaintIntent === "fixture_landlord"
                              ? "bg-white border-[#1B5888] text-[#1B5888] shadow-2xs"
                              : "bg-white/80 border-slate-200 hover:bg-white text-slate-700"
                              }`}
                          >
                            <input
                              type="radio"
                              name="newMaintIntent"
                              value="fixture_landlord"
                              checked={newMaintIntent === "fixture_landlord"}
                              onChange={() => setNewMaintIntent("fixture_landlord")}
                              className="mt-0.5 text-[#1B5888]"
                            />
                            <div className="text-xs">
                              <span className="font-bold block">
                                {t("agency_maint_intent_agency_fixture")}
                              </span>
                              <span className="text-[11px] text-slate-500">
                                {t("agency_maint_intent_agency_fixture_sub")}
                              </span>
                            </div>
                          </label>

                          <label
                            className={`flex items-start gap-2 p-2.5 rounded-lg border cursor-pointer transition-colors ${newMaintIntent === "tenant_damage"
                              ? "bg-white border-[#1B5888] text-[#1B5888] shadow-2xs"
                              : "bg-white/80 border-slate-200 hover:bg-white text-slate-700"
                              }`}
                          >
                            <input
                              type="radio"
                              name="newMaintIntent"
                              value="tenant_damage"
                              checked={newMaintIntent === "tenant_damage"}
                              onChange={() => setNewMaintIntent("tenant_damage")}
                              className="mt-0.5 text-[#1B5888]"
                            />
                            <div className="text-xs">
                              <span className="font-bold block">
                                {t("agency_maint_intent_agency_damage")}
                              </span>
                              <span className="text-[11px] text-slate-500">
                                {t("agency_maint_intent_agency_damage_sub")}
                              </span>
                            </div>
                          </label>
                        </div>
                      )}
                    </div>

                    {/* Invoice Document Upload */}
                    <div>
                      <label className="block text-[11px] font-bold text-slate-700 mb-1">
                        {t("agency_maint_invoice_doc_label")}
                      </label>
                      <div className="flex items-center gap-2">
                        <label className="flex-1 border border-dashed border-slate-300 rounded-lg p-2 text-center cursor-pointer hover:bg-white bg-white/70 transition-colors">
                          <input
                            type="file"
                            accept="application/pdf,image/*"
                            className="hidden"
                            onChange={(e) => {
                              if (e.target.files && e.target.files[0]) {
                                setNewMaintInvoiceFile(e.target.files[0]);
                              }
                            }}
                          />
                          <span className="text-xs text-slate-600 flex items-center justify-center gap-1.5">
                            <UploadCloud className="w-4 h-4 text-[#1B5888]" />
                            <span>
                              {newMaintInvoiceFile
                                ? newMaintInvoiceFile.name
                                : t("agency_maint_upload_invoice_btn")}
                            </span>
                          </span>
                        </label>
                        {newMaintInvoiceFile && (
                          <button
                            type="button"
                            onClick={() => setNewMaintInvoiceFile(null)}
                            className="p-1.5 text-rose-600 hover:bg-rose-50 rounded-lg cursor-pointer"
                          >
                            <X className="w-4 h-4" />
                          </button>
                        )}
                      </div>
                    </div>
                  </div>
                )}

                <div className="pt-2 border-t border-slate-100 flex items-center justify-end gap-2">
                  <button
                    type="button"
                    onClick={() => setIsNewMaintModalOpen(false)}
                    className="px-4 py-2 rounded-[10px] border border-[#E5E3DF] hover:bg-slate-50 text-xs font-semibold text-[#4A4A4A] cursor-pointer transition-colors"
                  >
                    {t("agency_panel_xml_modal_close")}
                  </button>
                  <button
                    type="submit"
                    disabled={creatingMaint}
                    className="inline-flex items-center gap-1.5 px-4 py-2 rounded-[10px] bg-[#1B5888] hover:bg-[#12406A] active:bg-[#12406A] disabled:opacity-60 text-white text-xs font-bold cursor-pointer shadow-xs transition-colors"
                  >
                    {creatingMaint ? (
                      <RefreshCw className="w-3.5 h-3.5 animate-spin" />
                    ) : (
                      <Plus className="w-3.5 h-3.5" />
                    )}
                    <span>{t("agency_maint_modal_btn_submit")}</span>
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}

        {/* PERSONAL DEMO SANDBOX MODAL */}
        {isDemoModalOpen && (
          <div
            role="dialog"
            aria-modal="true"
            aria-labelledby="demo-modal-title"
            className="fixed inset-0 z-50 bg-slate-900/60 backdrop-blur-xs flex items-center justify-center p-3 sm:p-5 animate-in fade-in duration-150"
          >
            <div className="bg-white rounded-[16px] max-w-3xl w-full max-h-[92vh] border border-[#E5E3DF] shadow-2xl flex flex-col relative overflow-hidden">
              <button
                type="button"
                onClick={() => setIsDemoModalOpen(false)}
                className="absolute top-4 right-4 p-2 rounded-full text-[#666666] hover:text-[#1A1A1A] hover:bg-slate-100 transition-colors cursor-pointer z-10"
                aria-label="Close"
              >
                <X className="w-5 h-5" />
              </button>

              {/* Modal Header (Clean & White matching screenshot) */}
              <div className="p-5 sm:p-6 pb-4 border-b border-[#E5E3DF] bg-white shrink-0">
                <div className="flex flex-wrap items-center gap-2 mb-2.5">
                  <span className="text-[11px] font-bold text-[#2A6E43] bg-[#E6F3EA] border border-[#2A6E43]/20 px-2.5 py-0.5 rounded-full inline-flex items-center gap-1 shadow-xs">
                    {tSafe("agency_demo_badge")}
                  </span>
                  <span className="text-[11px] font-medium text-[#4A4A4A] bg-[#F5F5F3] border border-[#E5E3DF] px-2.5 py-0.5 rounded-full inline-flex items-center gap-1">
                    <Clock className="w-3 h-3 text-[#1B5888]" />
                    {tSafe("agency_demo_trust_speed")}
                  </span>
                  <span className="text-[11px] font-medium text-[#4A4A4A] bg-[#F5F5F3] border border-[#E5E3DF] px-2.5 py-0.5 rounded-full inline-flex items-center gap-1">
                    <ShieldCheck className="w-3 h-3 text-[#2A6E43]" />
                    {tSafe("agency_demo_trust_card")}
                  </span>
                </div>
                <h3 id="demo-modal-title" className="text-xl sm:text-2xl font-extrabold text-[#1A1A1A] tracking-tight leading-tight">
                  {tSafe("agency_demo_title")}
                </h3>
                <p className="text-xs sm:text-sm text-[#4A4A4A] mt-1.5 leading-relaxed max-w-2xl">
                  {tSafe("agency_demo_subtitle")}
                </p>
              </div>

              {/* Form wrapping scrollable content & sticky footer */}
              <form onSubmit={handleStartPersonalDemo} className="flex flex-col flex-1 overflow-hidden min-h-0">
                {/* Scrollable Form Body */}
                <div className="overflow-y-auto px-5 sm:px-6 py-4 space-y-4 flex-1 overscroll-contain">
                  {demoFormError && (
                    <div className="p-3 rounded-[10px] bg-[#FBEAE6] border border-[#B5432E]/20 text-[#A33C29] text-xs font-semibold flex items-center gap-2">
                      <AlertCircle className="w-4 h-4 shrink-0" />
                      <span>{demoFormError}</span>
                    </div>
                  )}

                  {/* Form Fields: Agency, Email, City, Phone in 2x2 Grid */}
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-3.5">
                    {/* Agency Name */}
                    <div>
                      <label className="block text-xs font-semibold text-[#4A4A4A] mb-1">
                        {tSafe("agency_demo_label_agency")} <span className="text-rose-500">*</span>
                      </label>
                      <input
                        type="text"
                        required
                        value={demoFormAgencyName}
                        onChange={(e) => setDemoFormAgencyName(e.target.value)}
                        placeholder={tSafe("agency_demo_ph_agency")}
                        className="w-full px-3 py-2 rounded-[8px] border border-[#E5E3DF] text-xs text-[#1A1A1A] focus:outline-none focus:ring-2 focus:ring-[#1B5888]/20 focus:border-[#1B5888] bg-white font-medium"
                      />
                    </div>

                    {/* Email */}
                    <div>
                      <label className="block text-xs font-semibold text-[#4A4A4A] mb-1">
                        {tSafe("agency_demo_label_email")} <span className="text-rose-500">*</span>
                      </label>
                      <input
                        type="email"
                        required
                        value={demoFormEmail}
                        onChange={(e) => setDemoFormEmail(e.target.value)}
                        placeholder={tSafe("agency_demo_ph_email")}
                        className="w-full px-3 py-2 rounded-[8px] border border-[#E5E3DF] text-xs text-[#1A1A1A] focus:outline-none focus:ring-2 focus:ring-[#1B5888]/20 focus:border-[#1B5888] bg-white font-medium"
                      />
                    </div>

                    {/* City */}
                    <div>
                      <label className="block text-xs font-semibold text-[#4A4A4A] mb-1">
                        {tSafe("agency_demo_label_city")}
                      </label>
                      <div className="relative">
                        <select
                          value={demoFormCity}
                          onChange={(e) => setDemoFormCity(e.target.value)}
                          className="w-full pl-3 pr-8 py-2 rounded-[8px] border border-[#E5E3DF] text-xs text-[#1A1A1A] focus:outline-none focus:ring-2 focus:ring-[#1B5888]/20 focus:border-[#1B5888] bg-white appearance-none cursor-pointer font-medium"
                        >
                          {SERBIAN_CITIES.map((c) => (
                            <option key={c} value={c}>
                              {c}
                            </option>
                          ))}
                        </select>
                        <ChevronDown className="w-4 h-4 text-[#666666] absolute right-2.5 top-1/2 -translate-y-1/2 pointer-events-none" />
                      </div>
                    </div>

                    {/* Phone */}
                    <div>
                      <label className="block text-xs font-semibold text-[#4A4A4A] mb-1">
                        {tSafe("agency_demo_label_phone")}
                      </label>
                      <input
                        type="tel"
                        value={demoFormPhone}
                        onChange={(e) => setDemoFormPhone(e.target.value)}
                        placeholder={tSafe("agency_demo_ph_phone")}
                        className="w-full px-3 py-2 rounded-[8px] border border-[#E5E3DF] text-xs text-[#1A1A1A] focus:outline-none focus:ring-2 focus:ring-[#1B5888]/20 focus:border-[#1B5888] bg-white font-medium"
                      />
                    </div>
                  </div>

                  {/* Scope Selection: 2 Independent Modules */}
                  <div>
                    <div className="flex items-center justify-between gap-1 mb-2">
                      <label className="block text-xs sm:text-sm font-bold text-[#1A1A1A]">
                        {tSafe("agency_demo_section_modules")}
                      </label>
                      <span className="text-xs text-[#666666] font-medium">
                        {tSafe("agency_demo_pick_both")}
                      </span>
                    </div>

                    <div className="grid grid-cols-1 md:grid-cols-2 gap-3.5">
                      {/* Module 1: Listings, Showcase Website & Portals */}
                      <div
                        onClick={() => {
                          if (demoIncludeListings && !demoIncludeRental) return;
                          setDemoIncludeListings((prev) => !prev);
                        }}
                        className={`rounded-[12px] border-2 p-3.5 sm:p-4 text-left transition-all cursor-pointer flex flex-col justify-between relative group ${demoIncludeListings
                          ? "border-[#1B5888] bg-[#F7FAFD] ring-2 ring-[#1B5888]/15 shadow-sm"
                          : "border-[#E5E3DF] bg-white hover:border-[#8A8A8A] opacity-75 hover:opacity-100"
                          }`}
                      >
                        <div>
                          {/* Header with Checkbox */}
                          <div className="flex items-start gap-2.5 mb-2">
                            <div className="shrink-0 mt-0.5">
                              {demoIncludeListings ? (
                                <div className="w-5 h-5 rounded-[5px] bg-[#1B5888] text-white flex items-center justify-center">
                                  <Check className="w-3.5 h-3.5 stroke-[3]" />
                                </div>
                              ) : (
                                <div className="w-5 h-5 rounded-[5px] border-2 border-[#8A8A8A] group-hover:border-[#1B5888]" />
                              )}
                            </div>
                            <div className="min-w-0 flex-1">
                              <h4 className="text-xs sm:text-sm font-bold text-[#1A1A1A] leading-tight">
                                {tSafe("agency_demo_module_listings_title")}
                              </h4>
                            </div>
                          </div>

                          <p className="text-xs text-[#4A4A4A] leading-relaxed mb-3 pl-7">
                            {tSafe("agency_demo_module_listings_desc")}
                          </p>
                        </div>

                        {/* Feature Pills with Simulation Tag */}
                        <div className="flex flex-wrap gap-1.5 pt-2 border-t border-slate-100 pl-7">
                          <span className="text-[10px] font-medium px-2 py-0.5 rounded-full bg-white border border-[#E5E3DF] text-[#4A4A4A]">
                            {tSafe("agency_demo_pill_showcase")}
                          </span>
                          <span className="text-[10px] font-medium px-2 py-0.5 rounded-full bg-white border border-[#E5E3DF] text-[#4A4A4A]">
                            {tSafe("agency_demo_pill_portals")}
                          </span>
                          <span className="text-[10px] font-medium px-2 py-0.5 rounded-full bg-white border border-[#E5E3DF] text-[#4A4A4A]">
                            {tSafe("agency_demo_pill_single_entry")}
                          </span>
                          <span className="text-[10px] font-semibold px-2 py-0.5 rounded-full bg-amber-50 text-[#B78103] border border-amber-200">
                            {tSafe("agency_demo_mock_simulation_badge")}
                          </span>
                        </div>
                      </div>

                      {/* Module 2: Rental & Property Management */}
                      <div
                        onClick={() => {
                          if (demoIncludeRental && !demoIncludeListings) return;
                          setDemoIncludeRental((prev) => !prev);
                        }}
                        className={`rounded-[12px] border-2 p-3.5 sm:p-4 text-left transition-all cursor-pointer flex flex-col justify-between relative group ${demoIncludeRental
                          ? "border-[#1B5888] bg-[#F7FAFD] ring-2 ring-[#1B5888]/15 shadow-sm"
                          : "border-[#E5E3DF] bg-white hover:border-[#8A8A8A] opacity-75 hover:opacity-100"
                          }`}
                      >
                        <div>
                          {/* Header with Checkbox */}
                          <div className="flex items-start gap-2.5 mb-2">
                            <div className="shrink-0 mt-0.5">
                              {demoIncludeRental ? (
                                <div className="w-5 h-5 rounded-[5px] bg-[#1B5888] text-white flex items-center justify-center">
                                  <Check className="w-3.5 h-3.5 stroke-[3]" />
                                </div>
                              ) : (
                                <div className="w-5 h-5 rounded-[5px] border-2 border-[#8A8A8A] group-hover:border-[#1B5888]" />
                              )}
                            </div>
                            <div className="min-w-0 flex-1">
                              <h4 className="text-xs sm:text-sm font-bold text-[#1A1A1A] leading-tight">
                                {tSafe("agency_demo_module_rental_title")}
                              </h4>
                            </div>
                          </div>

                          <p className="text-xs text-[#4A4A4A] leading-relaxed mb-3 pl-7">
                            {tSafe("agency_demo_module_rental_desc")}
                          </p>
                        </div>

                        {/* Feature Pills */}
                        <div className="flex flex-wrap gap-1.5 pt-2 border-t border-slate-100 pl-7">
                          <span className="text-[10px] font-medium px-2 py-0.5 rounded-full bg-white border border-[#E5E3DF] text-[#4A4A4A]">
                            {tSafe("agency_demo_pill_rent_tracking")}
                          </span>
                          <span className="text-[10px] font-medium px-2 py-0.5 rounded-full bg-white border border-[#E5E3DF] text-[#4A4A4A]">
                            {tSafe("agency_demo_pill_infostan")}
                          </span>
                          <span className="text-[10px] font-medium px-2 py-0.5 rounded-full bg-white border border-[#E5E3DF] text-[#4A4A4A]">
                            {tSafe("agency_demo_pill_ledger")}
                          </span>
                        </div>
                      </div>
                    </div>
                  </div>

                  {/* Peek at what you'll get Accordion */}
                  <div className="rounded-[10px] border border-[#E5E3DF] overflow-hidden">
                    <button
                      type="button"
                      onClick={() => setShowDemoPeek((prev) => !prev)}
                      className="w-full px-3.5 py-2.5 bg-slate-50 hover:bg-slate-100/80 transition-colors flex items-center justify-between text-xs font-bold text-[#1A1A1A] cursor-pointer"
                    >
                      <span className="flex items-center gap-2">
                        <ChevronRight
                          className={`w-4 h-4 text-[#1B5888] transition-transform duration-200 ${showDemoPeek ? "rotate-90" : ""
                            }`}
                        />
                        <span>{tSafe("agency_demo_peek_title")}</span>
                      </span>
                      {showDemoPeek ? (
                        <ChevronUp className="w-4 h-4 text-[#666666]" />
                      ) : (
                        <ChevronDown className="w-4 h-4 text-[#666666]" />
                      )}
                    </button>

                    {showDemoPeek && (
                      <div className="p-3.5 bg-white border-t border-[#E5E3DF] space-y-3 animate-in fade-in duration-150">
                        {/* Simulation Transparency Warning */}
                        <div className="p-3 rounded-[8px] bg-amber-50/90 border border-amber-200/90 text-xs text-[#8A5400] flex items-start gap-2.5 leading-relaxed">
                          <Info className="w-4 h-4 text-[#B78103] shrink-0 mt-0.5" />
                          <p className="font-medium">
                            {tSafe("agency_demo_portal_simulated_notice")}
                          </p>
                        </div>

                        {/* Previews Grid */}
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                          {/* Module 1 Preview: Showcase Website + Portal Distribution */}
                          <div className="bg-white rounded-[10px] border border-[#E5E3DF] p-2.5 shadow-2xs space-y-2">
                            <div className="flex items-center justify-between pb-1.5 border-b border-slate-100 text-[10px]">
                              <span className="font-bold text-[#1A1A1A]">
                                {tSafe("agency_demo_module_listings_title")}
                              </span>
                              <span className="px-1.5 py-0.2 rounded bg-amber-50 text-[#B78103] border border-amber-200 font-bold text-[9px]">
                                {tSafe("agency_demo_mock_simulation_badge")}
                              </span>
                            </div>

                            {/* Mini Browser */}
                            <div className="flex items-center gap-1.5 pb-2 border-b border-slate-100">
                              <div className="flex items-center gap-1">
                                <span className="w-2 h-2 rounded-full bg-rose-400" />
                                <span className="w-2 h-2 rounded-full bg-amber-400" />
                                <span className="w-2 h-2 rounded-full bg-emerald-400" />
                              </div>
                              <div className="flex-1 min-w-0 bg-slate-50 border border-slate-200/80 rounded px-2 py-0.5 flex items-center justify-between text-[10px] text-[#4A4A4A] font-mono">
                                <span className="truncate flex items-center gap-1 text-[#1B5888] font-semibold">
                                  <Lock className="w-2.5 h-2.5 text-[#2A6E43]" />
                                  {tSafe("agency_demo_mock_showcase_url")}
                                </span>
                                <ExternalLink className="w-2.5 h-2.5 text-slate-400 shrink-0" />
                              </div>
                            </div>

                            {/* Mini Listing Item inside Browser */}
                            <div className="flex items-center gap-2 p-1.5 rounded-md bg-slate-50/70 border border-slate-100">
                              <div className="w-12 h-10 rounded bg-gradient-to-br from-slate-200 to-slate-300 flex items-center justify-center shrink-0 text-slate-500">
                                <ImageIcon className="w-4 h-4" />
                              </div>
                              <div className="flex-1 min-w-0">
                                <div className="flex items-center justify-between gap-1">
                                  <span className="text-[9px] font-bold px-1.5 py-0.2 rounded bg-[#1B5888]/10 text-[#1B5888]">
                                    {tSafe("agency_demo_mock_listing_tag")}
                                  </span>
                                  <span className="text-[10px] font-bold text-[#1A1A1A]">
                                    {tSafe("agency_demo_mock_listing_price")}
                                  </span>
                                </div>
                                <p className="text-[10px] text-[#666666] truncate mt-0.5">
                                  Beograd, Vračar • 75m²
                                </p>
                              </div>
                            </div>

                            {/* Portal Distribution Flow */}
                            <div className="pt-1 border-t border-dashed border-slate-200">
                              <div className="flex items-center justify-between gap-1 text-[10px] mb-1.5">
                                <span className="font-bold text-[#2A6E43] flex items-center gap-1">
                                  <Zap className="w-3 h-3 text-[#2A6E43]" />
                                  {tSafe("agency_demo_mock_sync_single")}
                                </span>
                                <ArrowRight className="w-3 h-3 text-slate-400" />
                                <span className="font-semibold text-[#1B5888] flex items-center gap-1">
                                  <RefreshCw className="w-3 h-3 text-[#1B5888]" />
                                  {tSafe("agency_demo_mock_sync_auto")}
                                </span>
                              </div>
                              <div className="grid grid-cols-2 gap-1.5">
                                <div className="flex items-center justify-between px-2 py-1 rounded bg-[#FFF5EE] border border-[#F36F21]/30 text-[10px]">
                                  <span className="font-bold text-[#F36F21]">4zida.rs</span>
                                  <span className="text-[9px] font-medium text-[#B78103] flex items-center gap-0.5">
                                    <Check className="w-3 h-3" /> XML
                                  </span>
                                </div>
                                <div className="flex items-center justify-between px-2 py-1 rounded bg-[#F0F7FD] border border-[#0066B3]/30 text-[10px]">
                                  <span className="font-bold text-[#0066B3]">Halo Oglasi</span>
                                  <span className="text-[9px] font-medium text-[#B78103] flex items-center gap-0.5">
                                    <Check className="w-3 h-3" /> XML
                                  </span>
                                </div>
                              </div>
                            </div>
                          </div>

                          {/* Module 2 Preview: Property Tracker + Rent & Bills Ledger */}
                          <div className="bg-white rounded-[10px] border border-[#E5E3DF] p-2.5 shadow-2xs space-y-2">
                            <div className="flex items-center justify-between pb-1.5 border-b border-slate-100 text-[10px]">
                              <span className="font-bold text-[#1A1A1A]">
                                {tSafe("agency_demo_module_rental_title")}
                              </span>
                              <span className="text-[9px] font-bold px-1.5 py-0.2 rounded bg-emerald-50 text-[#2A6E43] border border-emerald-200">
                                Stanomer Active
                              </span>
                            </div>

                            {/* Mini Unit Header */}
                            <div className="flex items-center justify-between pb-1 text-[10px]">
                              <span className="font-bold text-[#1A1A1A] flex items-center gap-1.5">
                                <Home className="w-3.5 h-3.5 text-[#1B5888]" />
                                Dorćol • 2.0 Stan • 58m²
                              </span>
                            </div>

                            {/* Row 1: Rent Payment */}
                            <div className="flex items-center justify-between p-1.5 rounded-md bg-slate-50/70 border border-slate-100 text-[10px]">
                              <span className="text-[#4A4A4A] font-medium flex items-center gap-1.5">
                                <CreditCard className="w-3 h-3 text-slate-500" />
                                {tSafe("agency_demo_mock_rent_label")}: <strong className="text-[#1A1A1A]">850 €</strong>
                              </span>
                              <span className="font-bold text-[9px] px-2 py-0.5 rounded-full bg-[#E6F3EA] text-[#2A6E43] border border-[#2A6E43]/20 flex items-center gap-1">
                                <Check className="w-2.5 h-2.5" />
                                {tSafe("agency_demo_mock_rent_paid")}
                              </span>
                            </div>

                            {/* Row 2: Infostan Bill */}
                            <div className="flex items-center justify-between p-1.5 rounded-md bg-slate-50/70 border border-slate-100 text-[10px]">
                              <span className="text-[#4A4A4A] font-medium flex items-center gap-1.5">
                                <Receipt className="w-3 h-3 text-slate-500" />
                                {tSafe("agency_demo_mock_bill_label")}
                              </span>
                              <span className="font-bold text-[9px] px-2 py-0.5 rounded-full bg-slate-100 text-[#4A4A4A] border border-slate-200">
                                {tSafe("agency_demo_mock_bill_status")}
                              </span>
                            </div>

                            {/* Row 3: Lease Renewal */}
                            <div className="flex items-center justify-between p-1.5 rounded-md bg-amber-50/50 border border-amber-200/60 text-[10px]">
                              <span className="text-[#4A4A4A] font-medium flex items-center gap-1.5">
                                <Calendar className="w-3 h-3 text-amber-600" />
                                {tSafe("agency_demo_mock_contract_label")}
                              </span>
                              <span className="font-bold text-[9px] px-2 py-0.5 rounded-full bg-[#FFF8E1] text-[#B78103] border border-amber-300 inline-flex items-center gap-1">
                                <Bell className="w-2.5 h-2.5 text-[#B78103]" />
                                {tSafe("agency_demo_mock_contract_status")}
                              </span>
                            </div>
                          </div>
                        </div>

                        {/* Realistic sample data notice */}
                        <div className="p-3 rounded-[8px] bg-slate-50 border border-[#E5E3DF] flex items-center gap-2.5 text-xs text-[#4A4A4A]">
                          <Sparkles className="w-4 h-4 text-[#1B5888] shrink-0" />
                          <p className="font-medium leading-relaxed">
                            {tSafe("agency_demo_sample_data_notice")}
                          </p>
                        </div>
                      </div>
                    )}
                  </div>

                  {/* Mandatory Consent Checkbox (Checked by default) */}
                  <label className="flex items-start gap-2.5 text-xs text-[#4A4A4A] cursor-pointer pt-1">
                    <input
                      type="checkbox"
                      checked={demoMarketingConsent}
                      onChange={(e) => {
                        setDemoMarketingConsent(e.target.checked);
                        if (e.target.checked) setDemoFormError(null);
                      }}
                      className="mt-0.5 w-4 h-4 rounded text-[#1B5888] border-[#8A8A8A] focus:ring-blue-500 cursor-pointer shrink-0"
                    />
                    <span className="leading-snug select-none">
                      {tSafe("agency_demo_consent_marketing")} <span className="text-rose-500">*</span>
                    </span>
                  </label>
                </div>

                {/* Sticky Bottom CTA Footer */}
                <div className="sticky bottom-0 bg-white border-t border-[#E5E3DF] p-4 sm:p-5 shadow-[0_-8px_20px_rgba(0,0,0,0.06)] shrink-0 z-20">
                  <button
                    type="submit"
                    disabled={submittingDemoForm || !demoMarketingConsent}
                    className="w-full py-3.5 rounded-[10px] bg-[#1B5888] hover:bg-[#12406A] active:bg-[#12406A] disabled:opacity-40 disabled:cursor-not-allowed text-white text-base font-bold cursor-pointer transition-all flex items-center justify-center gap-2 shadow-md"
                  >
                    <Play className="w-4 h-4 fill-white" />
                    <span>
                      {submittingDemoForm
                        ? tSafe("agency_panel_btn_saving")
                        : tSafe("agency_demo_cta")}
                    </span>
                  </button>

                  {/* Privacy & Terms notice under button */}
                  <p className="text-[11px] text-[#8A8A8A] leading-relaxed text-center mt-2.5">
                    {(() => {
                      const raw = tSafe("agency_demo_privacy_notice");
                      const parts = raw.split("{privacyLink}");
                      return (
                        <>
                          {parts[0]}
                          <Link
                            href="/privacy"
                            target="_blank"
                            rel="noopener noreferrer"
                            className="text-[#1B5888] hover:text-[#12406A] underline font-semibold"
                          >
                            {tSafe("agency_demo_privacy_link")}
                          </Link>
                          {parts[1] || ""}
                        </>
                      );
                    })()}
                  </p>
                </div>
              </form>
            </div>
          </div>
        )}

        {/* DEMO EXPIRED ALERT MODAL */}
        {demoExpiredAlert && (
          <div
            role="dialog"
            aria-modal="true"
            className="fixed inset-0 z-50 bg-slate-900/60 backdrop-blur-xs flex items-center justify-center p-4 animate-in fade-in duration-150"
          >
            <div className="bg-white rounded-[10px] max-w-sm w-full border border-[#E5E3DF] shadow-xl p-6 text-center">
              <div className="w-12 h-12 rounded-full bg-[#FBF1DC] text-[#8A5206] flex items-center justify-center mx-auto mb-3">
                <Clock className="w-6 h-6" />
              </div>
              <h3 className="text-base font-bold text-[#1A1A1A] mb-1">
                {t("agency_panel_demo_expired_title")}
              </h3>
              <p className="text-xs text-[#666666] mb-4 leading-relaxed">
                {t("agency_panel_demo_expired_desc")}
              </p>
              <div className="space-y-2">
                <a
                  href={`https://wa.me/381616036556?text=${encodeURIComponent(
                    `Pozdrav, istekao je demo za agenciju ${demoExpiredAlert.agencyName || ""}. Želimo nastavak saradnje.`
                  )}`}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="w-full block py-2.5 rounded-[10px] bg-[#1B5888] hover:bg-[#12406A] active:bg-[#12406A] text-white text-xs font-semibold transition-colors"
                >
                  {t("agency_panel_demo_banner_cta")}
                </a>
                <button
                  type="button"
                  onClick={() => {
                    setDemoExpiredAlert(null);
                    setDemoFormAgencyName("");
                    setDemoFormEmail("");
                    setIsDemoModalOpen(true);
                  }}
                  className="w-full py-2 rounded-[10px] border border-[#E5E3DF] hover:bg-slate-50 text-[#4A4A4A] text-xs font-semibold transition-colors cursor-pointer"
                >
                  {t("agency_panel_demo_btn")}
                </button>
              </div>
            </div>
          </div>
        )}

        {/* DEMO GATEKEEPER VERIFICATION MODAL */}
        <DemoVerificationModal
          isOpen={isGatekeeperModalOpen}
          onClose={() => setIsGatekeeperModalOpen(false)}
          initialAgencyName={agencyName}
          initialEmail={agencyEmail !== "partner@stanomer.online" ? agencyEmail : ""}
          initialPhone={agencyPhone !== "+381 11 400 0000" ? agencyPhone : ""}
          onSuccess={() => {
            setIsGatekeeperModalOpen(false);
            setIsFloatingNudgeVisible(false);
            if (typeof window !== "undefined") {
              sessionStorage.setItem("stanomer_demo_nudge_dismissed", "1");
            }
          }}
        />

        {/* DEMO 120s FLOATING NUDGE */}
        <DemoFloatingNudge
          isVisible={isFloatingNudgeVisible}
          onOpenVerification={() => setIsGatekeeperModalOpen(true)}
          onDismiss={() => {
            setIsFloatingNudgeVisible(false);
            if (typeof window !== "undefined") {
              sessionStorage.setItem("stanomer_demo_nudge_dismissed", "1");
            }
          }}
        />
      </main>

      {/* Mobile Bottom Navigation Bar & Drawer */}
      {userId && (
        <>
          {/* Bottom Sheet Drawer (More / Menü) */}
          {isMobileMenuOpen && (
            <div className="lg:hidden fixed inset-0 z-50 flex flex-col justify-end">
              {/* Backdrop */}
              <div
                className="fixed inset-0 bg-black/40 backdrop-blur-xs transition-opacity"
                onClick={() => setIsMobileMenuOpen(false)}
                aria-hidden="true"
              />

              {/* Drawer Content */}
              <div
                role="dialog"
                aria-modal="true"
                aria-label={t("agency_panel_mob_drawer_title")}
                className="relative bg-white rounded-t-2xl border-t border-[#E5E3DF] shadow-2xl p-4 max-h-[85vh] overflow-y-auto pb-[max(1.5rem,env(safe-area-inset-bottom))] z-10 animate-in slide-in-from-bottom duration-200"
              >
                {/* Pull Handle */}
                <div className="w-10 h-1 bg-[#E5E3DF] rounded-full mx-auto mb-3" />

                {/* Drawer Header */}
                <div className="flex items-center justify-between pb-3 border-b border-[#E5E3DF] mb-3">
                  <div className="flex items-center gap-2">
                    <span className="text-xs font-bold uppercase tracking-wider text-[#1B5888] bg-[#E5EEF6] px-2 py-0.5 rounded-md">
                      {activeModule === "pnd" ? "P&D" : "P&L"}
                    </span>
                    <h3 className="text-sm font-bold text-[#1A1A1A]">
                      {t("agency_panel_mob_drawer_title")}
                    </h3>
                  </div>
                  <button
                    type="button"
                    onClick={() => setIsMobileMenuOpen(false)}
                    aria-label="Close"
                    className="w-8 h-8 rounded-full bg-[#F8F7F5] border border-[#E5E3DF] flex items-center justify-center text-[#666666] hover:text-[#1A1A1A] cursor-pointer"
                  >
                    <X className="w-4 h-4" />
                  </button>
                </div>

                {/* Module Secondary Actions */}
                <div className="space-y-1 mb-4">
                  <p className="text-[11px] font-semibold text-[#8A8A8A] uppercase tracking-wider px-2 mb-1">
                    {activeModule === "pnd"
                      ? t("agency_panel_nav_group_marketing")
                      : t("agency_panel_nav_group_management")}
                  </p>

                  {activeModule === "pnd" ? (
                    <>
                      {/* New / Edit Listing */}
                      <button
                        type="button"
                        onClick={() => {
                          if (!editingId) resetForm();
                          setActiveTab("form");
                          setIsMobileMenuOpen(false);
                        }}
                        className={`w-full flex items-center justify-between p-3 rounded-xl text-xs font-semibold transition-colors cursor-pointer ${activeTab === "form"
                          ? "bg-[#E5EEF6] text-[#1B5888] font-bold"
                          : "bg-[#F8F7F5] text-[#1A1A1A] hover:bg-[#E5E3DF]/50"
                          }`}
                      >
                        <div className="flex items-center gap-2.5">
                          {editingId ? (
                            <Edit3 className="w-4 h-4 text-[#8A5206]" />
                          ) : (
                            <PlusCircle className="w-4 h-4 text-[#1B5888]" />
                          )}
                          <span>
                            {editingId
                              ? t("agency_panel_menu_edit_listing")
                              : t("agency_panel_menu_new_listing")}
                          </span>
                        </div>
                        <ChevronRight className="w-4 h-4 text-[#8A8A8A]" />
                      </button>

                      {/* XML Feeds */}
                      <button
                        type="button"
                        onClick={() => {
                          setActiveTab("xml");
                          setIsMobileMenuOpen(false);
                        }}
                        className={`w-full flex items-center justify-between p-3 rounded-xl text-xs font-semibold transition-colors cursor-pointer ${activeTab === "xml"
                          ? "bg-[#E5EEF6] text-[#1B5888] font-bold"
                          : "bg-[#F8F7F5] text-[#1A1A1A] hover:bg-[#E5E3DF]/50"
                          }`}
                      >
                        <div className="flex items-center gap-2.5">
                          <Rss className="w-4 h-4 text-[#1B5888]" />
                          <span>{t("agency_panel_menu_xml")}</span>
                        </div>
                        <span className="text-[10px] px-2 py-0.5 rounded-md font-mono font-bold bg-white text-[#666666] border border-[#E5E3DF]">
                          {PORTAL_LIST.filter((p) => p.status === "live").length} {t("agency_panel_portal_word")}
                        </span>
                      </button>

                      {/* Public Showcase Link */}
                      {!isPortfolioLocked ? (
                        <a
                          href={showcaseUrl}
                          target="_blank"
                          rel="noopener noreferrer"
                          onClick={() => setIsMobileMenuOpen(false)}
                          className="w-full flex items-center justify-between p-3 rounded-xl text-xs font-semibold bg-[#F8F7F5] text-[#1A1A1A] hover:bg-[#E5E3DF]/50 transition-colors cursor-pointer"
                        >
                          <div className="flex items-center gap-2.5">
                            <Globe className="w-4 h-4 text-[#1B5888]" />
                            <span>{t("agency_panel_sidebar_vitrin_title")}</span>
                          </div>
                          <ArrowUpRight className="w-4 h-4 text-[#8A8A8A]" />
                        </a>
                      ) : (
                        <button
                          type="button"
                          onClick={() => {
                            setIsMobileMenuOpen(false);
                            setActiveTab("account_settings");
                          }}
                          className="w-full flex items-center justify-between p-3 rounded-xl text-xs font-semibold bg-[#F8F7F5] text-[#1A1A1A] hover:bg-[#E5E3DF]/50 transition-colors cursor-pointer text-left"
                        >
                          <div className="flex items-center gap-2.5">
                            <Globe className="w-4 h-4 text-[#666666]" />
                            <span>{t("agency_panel_sidebar_vitrin_title")}</span>
                          </div>
                          <span className="p-1 rounded bg-amber-50 text-amber-700 border border-amber-200 font-bold inline-flex items-center">
                            <Lock className="w-2.5 h-2.5" />
                          </span>
                        </button>
                      )}
                    </>
                  ) : (
                    <>
                      {/* Managed Properties */}
                      <button
                        type="button"
                        onClick={() => {
                          setActiveTab("managed_properties");
                          setIsMobileMenuOpen(false);
                        }}
                        className={`w-full flex items-center justify-between p-3 rounded-xl text-xs font-semibold transition-colors cursor-pointer ${activeTab === "managed_properties"
                          ? "bg-[#E5EEF6] text-[#1B5888] font-bold"
                          : "bg-[#F8F7F5] text-[#1A1A1A] hover:bg-[#E5E3DF]/50"
                          }`}
                      >
                        <div className="flex items-center gap-2.5">
                          <Building2 className="w-4 h-4 text-[#1B5888]" />
                          <span>{t("agency_panel_menu_managed_props")}</span>
                        </div>
                        <span className="text-[10px] px-2 py-0.5 rounded-md font-mono font-bold bg-[#E6F3EA] text-[#2A6E43]">
                          {managedProperties.length}
                        </span>
                      </button>

                      {/* Payments & Approvals */}
                      <button
                        type="button"
                        onClick={() => {
                          setActiveTab("payments");
                          setIsMobileMenuOpen(false);
                        }}
                        className={`w-full flex items-center justify-between p-3 rounded-xl text-xs font-semibold transition-colors cursor-pointer ${activeTab === "payments"
                          ? "bg-[#E5EEF6] text-[#1B5888] font-bold"
                          : "bg-[#F8F7F5] text-[#1A1A1A] hover:bg-[#E5E3DF]/50"
                          }`}
                      >
                        <div className="flex items-center gap-2.5">
                          <Receipt className="w-4 h-4 text-[#1B5888]" />
                          <span>{t("agency_panel_menu_payments")}</span>
                        </div>
                        {paymentStats.awaitingApproval > 0 ? (
                          <span className="text-[10px] px-2 py-0.5 rounded-md font-mono font-bold bg-amber-500 text-white animate-pulse">
                            {paymentStats.awaitingApproval}
                          </span>
                        ) : (
                          <span className="text-[10px] px-2 py-0.5 rounded-md font-mono font-bold bg-white text-[#666666] border border-[#E5E3DF]">
                            {payments.length}
                          </span>
                        )}
                      </button>
                    </>
                  )}
                </div>

                {/* Shared Operations */}
                <div className="space-y-1 mb-4">
                  <p className="text-[11px] font-semibold text-[#8A8A8A] uppercase tracking-wider px-2 mb-1">
                    {t("agency_panel_settings_title")}
                  </p>
                  {/* Module-Independent Account & App Settings */}
                  <button
                    type="button"
                    onClick={() => {
                      setActiveTab("account_settings");
                      setIsMobileMenuOpen(false);
                    }}
                    className={`w-full flex items-center justify-between p-3 rounded-xl text-xs font-semibold transition-colors cursor-pointer ${activeTab === "account_settings"
                      ? "bg-[#E5EEF6] text-[#1B5888] font-bold"
                      : "bg-[#F8F7F5] text-[#1A1A1A] hover:bg-[#E5E3DF]/50"
                      }`}
                  >
                    <div className="flex items-center gap-2.5">
                      <User className="w-4 h-4 text-[#1B5888]" />
                      <span>{t("agency_panel_menu_account_settings")}</span>
                    </div>
                    <ChevronRight className="w-4 h-4 text-[#8A8A8A]" />
                  </button>

                  {/* Showcase & Vitrin Settings */}
                  <button
                    type="button"
                    onClick={() => {
                      setActiveTab("settings");
                      setIsMobileMenuOpen(false);
                    }}
                    className={`w-full flex items-center justify-between p-3 rounded-xl text-xs font-semibold transition-colors cursor-pointer ${activeTab === "settings"
                      ? "bg-[#E5EEF6] text-[#1B5888] font-bold"
                      : "bg-[#F8F7F5] text-[#1A1A1A] hover:bg-[#E5E3DF]/50"
                      }`}
                  >
                    <div className="flex items-center gap-2.5">
                      <Settings className="w-4 h-4 text-[#666666]" />
                      <span>{t("agency_panel_menu_settings")}</span>
                    </div>
                    <ChevronRight className="w-4 h-4 text-[#8A8A8A]" />
                  </button>
                </div>

                {/* Module Quick Switch Banner */}
                <div className="pt-2 border-t border-[#E5E3DF]">
                  <button
                    type="button"
                    onClick={() => {
                      if (activeModule === "pnd") {
                        setActiveModule("pms");
                        setActiveTab("pm_dashboard");
                      } else {
                        setActiveModule("pnd");
                        setActiveTab("listings");
                      }
                      setIsMobileMenuOpen(false);
                    }}
                    className="w-full p-3 rounded-xl bg-gradient-to-r from-[#1B5888]/10 via-[#1B5888]/5 to-transparent border border-[#1B5888]/20 flex items-center justify-between text-left cursor-pointer hover:bg-[#1B5888]/15 transition-all"
                  >
                    <div className="flex items-center gap-3 min-w-0">
                      <div className="w-9 h-9 rounded-lg bg-[#1B5888] text-white flex items-center justify-center shrink-0 shadow-xs">
                        {activeModule === "pnd" ? (
                          <Building2 className="w-5 h-5" />
                        ) : (
                          <Layers className="w-5 h-5" />
                        )}
                      </div>
                      <div className="min-w-0">
                        <p className="text-[11px] font-semibold text-[#666666]">
                          {activeModule === "pnd"
                            ? t("agency_panel_mob_switch_pms_full")
                            : t("agency_panel_mob_switch_pnd_full")}
                        </p>
                        <p className="text-xs font-bold text-[#1B5888] truncate">
                          {activeModule === "pnd"
                            ? t("agency_panel_nav_group_management")
                            : t("agency_panel_nav_group_marketing")}
                        </p>
                      </div>
                    </div>
                    <ArrowRight className="w-4 h-4 text-[#1B5888] shrink-0 ml-2" />
                  </button>
                </div>
              </div>
            </div>
          )}

          {/* Bottom Navigation Bar */}
          <nav
            role="tablist"
            aria-label={t("agency_panel_sidebar_title")}
            className="lg:hidden fixed bottom-0 left-0 right-0 z-40 bg-white/95 backdrop-blur-md border-t border-[#E5E3DF] shadow-xl px-2 py-1.5 flex items-center justify-around pb-[max(0.5rem,env(safe-area-inset-bottom))]"
          >
            {/* 1. Welcome / Home */}
            <button
              type="button"
              role="tab"
              id="mobtab-welcome"
              aria-controls="tabpanel-welcome"
              aria-selected={activeTab === "welcome"}
              onClick={() => setActiveTab("welcome")}
              className={`flex flex-col items-center justify-center flex-1 py-1 px-0.5 rounded-[10px] transition-colors cursor-pointer relative ${activeTab === "welcome"
                ? "text-[#1B5888] font-bold"
                : "text-[#666666] hover:text-[#1A1A1A]"
                }`}
            >
              <Compass className="w-5 h-5" />
              <span className="text-[10px] mt-1 truncate max-w-[65px]">
                {t("agency_panel_menu_welcome")}
              </span>
            </button>

            {activeModule === "pnd" ? (
              <>
                {/* 2. Listings (P&D) */}
                <button
                  type="button"
                  role="tab"
                  id="mobtab-listings"
                  aria-controls="tabpanel-listings"
                  aria-selected={activeTab === "listings"}
                  onClick={() => setActiveTab("listings")}
                  className={`flex flex-col items-center justify-center flex-1 py-1 px-0.5 rounded-[10px] transition-colors cursor-pointer relative ${activeTab === "listings"
                    ? "text-[#1B5888] font-bold"
                    : "text-[#666666] hover:text-[#1A1A1A]"
                    }`}
                >
                  <div className="relative">
                    <Layers className="w-5 h-5" />
                    {listings.length > 0 && (
                      <span className="absolute -top-1 -right-2 w-4 h-4 rounded-full bg-[#1B5888] text-white text-[9px] font-bold flex items-center justify-center">
                        {listings.length > 99 ? "99+" : listings.length}
                      </span>
                    )}
                  </div>
                  <span className="text-[10px] mt-1 truncate max-w-[65px]">
                    {t("agency_panel_mob_listings")}
                  </span>
                </button>

                {/* 3. Add New Listing (P&D) */}
                <button
                  type="button"
                  role="tab"
                  id="mobtab-add-listing"
                  aria-controls="tabpanel-form"
                  aria-selected={activeTab === "form"}
                  onClick={() => {
                    if (!editingId) resetForm();
                    setActiveTab("form");
                  }}
                  className={`flex flex-col items-center justify-center flex-1 py-1 px-0.5 rounded-[10px] transition-colors cursor-pointer relative ${activeTab === "form"
                    ? "text-[#1B5888] font-bold"
                    : "text-[#666666] hover:text-[#1A1A1A]"
                    }`}
                >
                  <PlusCircle className="w-5 h-5" />
                  <span className="text-[10px] mt-1 truncate max-w-[65px]">
                    {t("agency_panel_mob_add_listing")}
                  </span>
                </button>

                {/* 4. Inquiries / Leads (P&D) */}
                <button
                  type="button"
                  role="tab"
                  id="mobtab-leads"
                  aria-controls="tabpanel-leads"
                  aria-selected={activeTab === "leads"}
                  onClick={() => setActiveTab("leads")}
                  className={`flex flex-col items-center justify-center flex-1 py-1 px-0.5 rounded-[10px] transition-colors cursor-pointer relative ${activeTab === "leads"
                    ? "text-[#1B5888] font-bold"
                    : "text-[#666666] hover:text-[#1A1A1A]"
                    }`}
                >
                  <div className="relative">
                    <Inbox className="w-5 h-5" />
                    {newLeadsCount > 0 && (
                      <span className="absolute -top-1 -right-2 w-4 h-4 rounded-full bg-emerald-500 text-white text-[9px] font-bold flex items-center justify-center animate-pulse">
                        {newLeadsCount > 9 ? "9+" : newLeadsCount}
                      </span>
                    )}
                  </div>
                  <span className="text-[10px] mt-1 truncate max-w-[65px]">
                    {t("agency_panel_mob_leads")}
                  </span>
                </button>
              </>
            ) : (
              <>
                {/* 2. Managed Properties (PMS) */}
                <button
                  type="button"
                  role="tab"
                  id="mobtab-managed-properties"
                  aria-controls="tabpanel-managed-properties"
                  aria-selected={activeTab === "managed_properties"}
                  onClick={() => setActiveTab("managed_properties")}
                  className={`flex flex-col items-center justify-center flex-1 py-1 px-0.5 rounded-[10px] transition-colors cursor-pointer relative ${activeTab === "managed_properties"
                    ? "text-[#1B5888] font-bold"
                    : "text-[#666666] hover:text-[#1A1A1A]"
                    }`}
                >
                  <div className="relative">
                    <Home className="w-5 h-5" />
                    {managedProperties.length > 0 && (
                      <span className="absolute -top-1 -right-2 w-4 h-4 rounded-full bg-[#1B5888] text-white text-[9px] font-bold flex items-center justify-center">
                        {managedProperties.length > 99 ? "99+" : managedProperties.length}
                      </span>
                    )}
                  </div>
                  <span className="text-[10px] mt-1 truncate max-w-[65px]">
                    {t("agency_panel_mob_properties")}
                  </span>
                </button>

                {/* 3. Finance & Payments */}
                <button
                  type="button"
                  role="tab"
                  id="mobtab-payments"
                  aria-controls="tabpanel-payments"
                  aria-selected={activeTab === "payments"}
                  onClick={() => setActiveTab("payments")}
                  className={`flex flex-col items-center justify-center flex-1 py-1 px-0.5 rounded-[10px] transition-colors cursor-pointer relative ${activeTab === "payments"
                    ? "text-[#1B5888] font-bold"
                    : "text-[#666666] hover:text-[#1A1A1A]"
                    }`}
                >
                  <div className="relative">
                    <Wallet className="w-5 h-5" />
                    {paymentStats.awaitingApproval > 0 && (
                      <span className="absolute -top-1 -right-2 w-4 h-4 rounded-full bg-[#8A5206] text-white text-[9px] font-bold flex items-center justify-center animate-pulse">
                        {paymentStats.awaitingApproval > 9 ? "9+" : paymentStats.awaitingApproval}
                      </span>
                    )}
                  </div>
                  <span className="text-[10px] mt-1 truncate max-w-[65px]">
                    {t("agency_panel_mob_payments")}
                  </span>
                </button>

                {/* 4. Maintenance (PMS) */}
                <button
                  type="button"
                  role="tab"
                  id="mobtab-maintenance"
                  aria-controls="tabpanel-maintenance"
                  aria-selected={activeTab === "maintenance"}
                  onClick={() => setActiveTab("maintenance")}
                  className={`flex flex-col items-center justify-center flex-1 py-1 px-0.5 rounded-[10px] transition-colors cursor-pointer relative ${activeTab === "maintenance"
                    ? "text-[#1B5888] font-bold"
                    : "text-[#666666] hover:text-[#1A1A1A]"
                    }`}
                >
                  <div className="relative">
                    <Wrench className="w-5 h-5" />
                    {maintenanceStats.openCount > 0 && (
                      <span className="absolute -top-1 -right-2 w-4 h-4 rounded-full bg-rose-500 text-white text-[9px] font-bold flex items-center justify-center animate-pulse">
                        {maintenanceStats.openCount > 9 ? "9+" : maintenanceStats.openCount}
                      </span>
                    )}
                  </div>
                  <span className="text-[10px] mt-1 truncate max-w-[65px]">
                    {t("agency_panel_mob_maintenance")}
                  </span>
                </button>
              </>
            )}

            {/* 5. More / Menü */}
            <button
              type="button"
              id="mobtab-more"
              aria-label={t("agency_panel_mob_more")}
              aria-haspopup="dialog"
              aria-expanded={isMobileMenuOpen}
              onClick={() => setIsMobileMenuOpen(true)}
              className={`flex flex-col items-center justify-center flex-1 py-1 px-0.5 rounded-[10px] transition-colors cursor-pointer relative ${isMobileMenuOpen
                ? "text-[#1B5888] font-bold"
                : "text-[#666666] hover:text-[#1A1A1A]"
                }`}
            >
              <Menu className="w-5 h-5" />
              <span className="text-[10px] mt-1 truncate max-w-[65px]">
                {t("agency_panel_mob_more")}
              </span>
            </button>
          </nav>
        </>
      )}
    </div>
  );
}
