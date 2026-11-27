"use client";

import React, { useState, useMemo, useEffect, useRef } from "react";
import { findRejectedAmlForContext } from "../../../lib/amlRiskEngine";
import {
  AlertCircle,
  AlertTriangle,
  ArrowDownLeft,
  ArrowDownUp,
  ArrowLeft,
  ArrowRight,
  ArrowUpRight,
  Building,
  Building2,
  Calendar,
  CalendarOff,
  Check,
  CheckCheck,
  CheckCircle2,
  CheckSquare,
  ChevronDown,
  ChevronLeft,
  ChevronRight,
  ChevronUp,
  Clock,
  Euro,
  Eye,
  ExternalLink,
  FileDown,
  FileEdit,
  FilePlus,
  FileQuestion,
  FileText,
  FileUp,
  Hand,
  Home,
  Info,
  Key,
  Landmark,
  Banknote,
  Layers,
  LayoutGrid,
  Mail,
  MapPin,
  Menu,
  MessageCircle,
  MessageSquare,
  Minus,
  MoreHorizontal,
  Percent,
  Phone,
  Pencil,
  Paperclip,
  Plus,
  PlusCircle,
  Receipt,
  RefreshCw,
  RotateCcw,
  Search,
  Settings,
  Share2,
  SlidersHorizontal,
  Sparkles,
  StickyNote,
  TableProperties,
  Trash2,
  TrendingUp,
  UploadCloud,
  User,
  UserCheck,
  UserCog,
  UserPlus,
  Wrench,
  X,
} from "lucide-react";
import { useLanguage } from "../../../components/LanguageProvider";
import { supabase } from "../../../lib/supabaseClient";
import OwnershipInviteModal from "./OwnershipInviteModal";
import EditPropertyOwnersModal from "./EditPropertyOwnersModal";
import {
  AgencyContract,
  AgencyListingRow,
  AgencyMaintenanceRequest,
  AgencyManagedProperty,
  AgencyPanelTab,
  AgencyRentPayment,
  AgencyTask,
  AgencyTaskPrefill,
  ContractAdditionalDocument,
  ContractExpenseItem,
  TenantSecondaryContact,
} from "../types";
import { processRentPayments } from "../utils";
import { PaymentTypeIconBadge, formatCurrencyAmount } from "../categoryAndPaymentIcons";
import { SERBIAN_CITIES } from "../constants";
import {
  getEligibleMaintenanceSettlements,
  getEligibleRentPaymentsForOffset,
  getEligibleCounterpartyMaintenance,
  executeRentOffset,
  executeMaintenanceDebtOffset,
} from "../../../lib/maintenanceSettlementService";

export interface ManagedPropertiesTabProps {
  filteredManagedProperties: AgencyManagedProperty[];
  managedProperties: AgencyManagedProperty[];
  managedPropertyStats: {
    total: number;
    occupied: number;
    vacant: number;
    occupancyRate: number;
  };
  contracts: AgencyContract[];
  setContracts: React.Dispatch<React.SetStateAction<AgencyContract[]>>;
  maintenanceRequests: AgencyMaintenanceRequest[];
  setMaintenanceRequests?: React.Dispatch<React.SetStateAction<AgencyMaintenanceRequest[]>>;
  payments: AgencyRentPayment[];
  setPayments: React.Dispatch<React.SetStateAction<AgencyRentPayment[]>>;
  loadingProperties: boolean;
  propOccupancyFilter: "all" | "occupied" | "vacant" | "expiring" | "expired";
  setPropOccupancyFilter: (filter: "all" | "occupied" | "vacant" | "expiring" | "expired") => void;
  propSearchQuery: string;
  setPropSearchQuery: (query: string) => void;
  handleConvertPropertyToListing: (prop: AgencyManagedProperty) => void;
  handleUpdateMaintenanceStatus: (id: string, status: any) => void;
  handleApprovePayment: (payment: AgencyRentPayment) => void;
  setSelectedReceiptPayment: (payment: AgencyRentPayment | null) => void;
  setNewMaintPropId: (id: string) => void;
  setIsNewMaintModalOpen: (open: boolean) => void;
  isDemoMode: boolean;
  userId: string | null;
  isDemoVerified?: boolean;
  onRequestVerification?: () => void;
  t: (key: string, params?: Record<string, any>) => string;
  tSafe: (key: string, replacements?: Record<string, string | number>) => string;
  setStatusMessage: (msg: { type: "success" | "error"; text: string } | null) => void;
  setManagedProperties: React.Dispatch<React.SetStateAction<AgencyManagedProperty[]>>;
  selectedReceiptPayment: AgencyRentPayment | null;
  processingPaymentId: string | null;
  setProcessingPaymentId: React.Dispatch<React.SetStateAction<string | null>>;
  updatingMaintId: string | null;
  initialSelectedProperty?: AgencyManagedProperty | null;
  initialExpandedPaymentId?: string | null;
  onBackFromDrawer?: () => void;
  agencyName?: string;
  agencyEmail?: string;
  listings?: AgencyListingRow[];
  activeModules?: string[];
  setActiveTab?: (tab: AgencyPanelTab) => void;
  onOpenMaintenanceRequest?: (req: AgencyMaintenanceRequest) => void;
  onCreateTask?: (prefill: AgencyTaskPrefill) => void;
  tasks?: AgencyTask[];
  onViewPropertyTasks?: (propertyId: string) => void;
  eopRecords?: import("../types").EopRecord[];
  agencyClients?: import("../types").AgencyClient[];
  onOpenEopModal?: (prefill: import("../types").EopPrefill) => void;
  onViewPropertyEop?: (propertyId: string) => void;
  amlRecords?: import("../types").AmlRecord[];
  onOpenAmlModal?: (prefill: import("../types").AmlPrefill) => void;
  onQuickRelistProperty?: (params: {
    property: AgencyManagedProperty;
    linkedListing: AgencyListingRow | null;
    title: string;
    price: number;
    currency: string;
    mode: "instant_publish" | "open_form";
  }) => Promise<void>;
}

export default function ManagedPropertiesTab({
  filteredManagedProperties,
  managedProperties,
  managedPropertyStats,
  contracts,
  setContracts,
  maintenanceRequests,
  setMaintenanceRequests,
  payments,
  setPayments,
  loadingProperties,
  propOccupancyFilter,
  setPropOccupancyFilter,
  propSearchQuery,
  setPropSearchQuery,
  handleConvertPropertyToListing,
  handleUpdateMaintenanceStatus,
  handleApprovePayment,
  setSelectedReceiptPayment,
  setNewMaintPropId,
  setIsNewMaintModalOpen,
  isDemoMode,
  isDemoVerified = false,
  onRequestVerification,
  userId,
  t,
  tSafe,
  setStatusMessage,
  setManagedProperties,
  selectedReceiptPayment,
  processingPaymentId,
  setProcessingPaymentId,
  updatingMaintId,
  initialSelectedProperty,
  initialExpandedPaymentId,
  onBackFromDrawer,
  agencyName,
  agencyEmail,
  listings = [],
  activeModules = ["portfolio_distribution", "property_lease_management"],
  setActiveTab,
  onOpenMaintenanceRequest,
  onCreateTask,
  tasks = [],
  onViewPropertyTasks,
  eopRecords = [],
  agencyClients = [],
  onOpenEopModal,
  onViewPropertyEop,
  amlRecords = [],
  onOpenAmlModal,
  onQuickRelistProperty,
}: ManagedPropertiesTabProps) {
  const { lang } = useLanguage();

  const activeLocale = useMemo(() => {
    switch (lang) {
      case "SR_LAT":
        return "sr-Latn";
      case "SR_CYR":
        return "sr-Cyrl";
      case "RU":
        return "ru";
      case "TR":
        return "tr";
      case "EN":
      default:
        return "en";
    }
  }, [lang]);

  const formatPaymentTitle = (title?: string | null) => {
    if (!title) return t("agency_financials_rent");
    const lower = title.trim().toLowerCase();
    if (lower === "kira" || lower === "rent" || lower === "kirija" || lower === "кирија") {
      return t("agency_financials_rent");
    }
    return title;
  };
  const [selectedPropertyDrawer, setSelectedPropertyDrawer] = useState<AgencyManagedProperty | null>(
    initialSelectedProperty || null
  );
  const [targetPaymentId, setTargetPaymentId] = useState<string | null>(
    initialExpandedPaymentId || null
  );
  const [ownershipModalProp, setOwnershipModalProp] = useState<AgencyManagedProperty | null>(null);
  const [drawerLandlordInvites, setDrawerLandlordInvites] = useState<Array<{
    id: string;
    invitee_email?: string | null;
    status: string;
  }>>([]);
  const [drawerActivityLogs, setDrawerActivityLogs] = useState<any[]>([]);
  const [cardActionMenuPropId, setCardActionMenuPropId] = useState<string | null>(null);
  const [propertyDrawerTab, setPropertyDrawerTab] = useState<"payments" | "overview" | "maintenance" | "audit">("overview");
  const [moreMenuOpen, setMoreMenuOpen] = useState(false);
  const [financialTypeFilter, setFinancialTypeFilter] = useState<"all" | "rent" | "bills" | "maintenance">("all");
  const [financialStatusFilter, setFinancialStatusFilter] = useState<"all" | "unentered" | "pending" | "awaiting" | "paid">("all");
  const [financialDueDateFilter, setFinancialDueDateFilter] = useState<"all" | "overdue" | "upcoming">("all");
  const [isAddPaymentModalOpen, setIsAddPaymentModalOpen] = useState(false);
  const [newPaymentTitle, setNewPaymentTitle] = useState("");
  const [newPaymentAmount, setNewPaymentAmount] = useState("");
  const [newPaymentDueDate, setNewPaymentDueDate] = useState("");
  const [newPaymentPayer, setNewPaymentPayer] = useState<"tenant" | "landlord">("tenant");

  // Maintenance Settlements in Payment Plan (Flutter Parity)
  const [isSettlementsSectionCollapsed, setIsSettlementsSectionCollapsed] = useState(false);
  const [selectedSettlementReq, setSelectedSettlementReq] = useState<AgencyMaintenanceRequest | null>(null);
  const [isOffsetModalOpen, setIsOffsetModalOpen] = useState(false);
  const [isExecutingOffset, setIsExecutingOffset] = useState(false);
  const [offsetError, setOffsetError] = useState<string | null>(null);
  const [expandedSettlementIds, setExpandedSettlementIds] = useState<Set<string>>(new Set());
  const [rejectingSettlementReq, setRejectingSettlementReq] = useState<AgencyMaintenanceRequest | null>(null);
  const [settlementRejectReason, setSettlementRejectReason] = useState("");
  const [isExecutingSettlementAction, setIsExecutingSettlementAction] = useState(false);

  // Flutter SSOT Parity: Settlement Options Sheet (_showLandlordSettlementSheet)
  const [isSettlementOptionsModalOpen, setIsSettlementOptionsModalOpen] = useState(false);
  const [settlementOptionsReq, setSettlementOptionsReq] = useState<AgencyMaintenanceRequest | null>(null);
  const [isDirectSettlementModalOpen, setIsDirectSettlementModalOpen] = useState(false);
  const [directSettlementMethod, setDirectSettlementMethod] = useState<"bank" | "cash">("bank");
  const [directSettlementNote, setDirectSettlementNote] = useState("");
  const [directSettlementFile, setDirectSettlementFile] = useState<File | null>(null);
  const [isExecutingDirectSettlement, setIsExecutingDirectSettlement] = useState(false);

  // Month payment card accordion expansion
  const [expandedMonthlyItemIds, setExpandedMonthlyItemIds] = useState<Set<string>>(new Set());
  const toggleMonthlyItemExpand = (id: string) => {
    setExpandedMonthlyItemIds((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  };

  // Operational state for Property Hub (SSOT Flutter Parity)
  // 1. Contract Renewal
  const [isRenewContractModalOpen, setIsRenewContractModalOpen] = useState(false);
  const [renewContractTarget, setRenewContractTarget] = useState<AgencyContract | null>(null);
  const [renewStartDate, setRenewStartDate] = useState("");
  const [renewEndDate, setRenewEndDate] = useState("");
  const [renewIncreaseRate, setRenewIncreaseRate] = useState("0");
  const [renewMonthlyRent, setRenewMonthlyRent] = useState("");
  const [isRenewingContract, setIsRenewingContract] = useState(false);

  // 2. Contract Termination
  const [isTerminateContractModalOpen, setIsTerminateContractModalOpen] = useState(false);
  const [terminateContractTarget, setTerminateContractTarget] = useState<AgencyContract | null>(null);
  const [terminateDate, setTerminateDate] = useState("");
  const [isTerminatingContract, setIsTerminatingContract] = useState(false);
  const [relistAfterTerminate, setRelistAfterTerminate] = useState(false);

  // 2.5 Lifecycle Bridge: Re-List / Update Linked Listing Modal
  const [relistPropertyTarget, setRelistPropertyTarget] = useState<AgencyManagedProperty | null>(null);
  const [relistTitle, setRelistTitle] = useState("");
  const [relistPrice, setRelistPrice] = useState("");
  const [relistCurrency, setRelistCurrency] = useState("EUR");
  const [isSubmittingRelist, setIsSubmittingRelist] = useState(false);

  // Sticky compact property detail header on scroll (with hysteresis to prevent jitter)
  const [isDetailHeaderCompact, setIsDetailHeaderCompact] = useState(false);

  // Responsive Priority+ Action Bar overflow into "More" dropdown
  const actionBarRef = useRef<HTMLDivElement | null>(null);
  const measureBarRef = useRef<HTMLDivElement | null>(null);
  const moreBtnRef = useRef<HTMLButtonElement | null>(null);
  const [visibleActionCount, setVisibleActionCount] = useState<number>(4);

  useEffect(() => {
    if (!selectedPropertyDrawer || isDetailHeaderCompact) return;
    const recalc = () => {
      const container = actionBarRef.current;
      const measure = measureBarRef.current;
      if (!container || !measure) return;
      const containerWidth = container.clientWidth;
      const moreWidth = (moreBtnRef.current?.offsetWidth || 92) + 8;
      const gap = 8;
      const children = Array.from(measure.children) as HTMLElement[];
      let used = 0;
      let count = 0;
      for (const el of children) {
        const w = el.offsetWidth;
        const needed = (count > 0 ? gap : 0) + w;
        if (used + needed + moreWidth <= containerWidth) {
          used += needed;
          count++;
        } else {
          break;
        }
      }
      setVisibleActionCount(count);
    };
    recalc();
    const ro = new ResizeObserver(recalc);
    if (actionBarRef.current) ro.observe(actionBarRef.current);
    return () => ro.disconnect();
  }, [selectedPropertyDrawer?.id, isDetailHeaderCompact, eopRecords.length, lang]);

  useEffect(() => {
    if (!selectedPropertyDrawer) {
      setIsDetailHeaderCompact(false);
      return;
    }
    const handleScroll = () => {
      const y = window.scrollY;
      setIsDetailHeaderCompact((prev) => {
        if (!prev && y > 135) return true;
        if (prev && y < 65) return false;
        return prev;
      });
    };
    handleScroll();
    window.addEventListener("scroll", handleScroll, { passive: true });
    return () => window.removeEventListener("scroll", handleScroll);
  }, [selectedPropertyDrawer?.id]);

  const hasPortfolioModule =
    activeModules.includes("portfolio_distribution") ||
    activeModules.includes("portfolio");

  const findLinkedListing = (prop: AgencyManagedProperty): AgencyListingRow | null => {
    return (
      listings.find(
        (l) =>
          (prop.last_listing_id && l.id === prop.last_listing_id) ||
          l.managed_property_id === prop.id ||
          (l.title && prop.title && l.title.trim().toLowerCase() === prop.title.trim().toLowerCase())
      ) || null
    );
  };

  const openRelistModal = (prop: AgencyManagedProperty) => {
    const linked = findLinkedListing(prop);
    const activeCtr = contracts.find((c) => c.property_id === prop.id && c.status === "active");
    const defaultRent = prop.default_monthly_rent || activeCtr?.monthly_rent || linked?.price || 0;
    setRelistPropertyTarget(prop);
    setRelistTitle(linked?.title || prop.title || "");
    setRelistPrice(defaultRent ? String(defaultRent) : "");
    setRelistCurrency(prop.currency || linked?.currency || "EUR");
  };

  const handleConfirmRelist = async (mode: "instant_publish" | "open_form") => {
    if (!relistPropertyTarget) return;
    if (!onQuickRelistProperty) {
      setRelistPropertyTarget(null);
      handleConvertPropertyToListing(relistPropertyTarget);
      return;
    }
    setIsSubmittingRelist(true);
    try {
      const linked = findLinkedListing(relistPropertyTarget);
      const priceNum = Number(relistPrice) || Number(relistPropertyTarget.default_monthly_rent) || 0;
      await onQuickRelistProperty({
        property: relistPropertyTarget,
        linkedListing: linked,
        title: relistTitle.trim() || relistPropertyTarget.title,
        price: priceNum,
        currency: relistCurrency,
        mode,
      });
      setRelistPropertyTarget(null);
    } finally {
      setIsSubmittingRelist(false);
    }
  };

  // 3. New Contract / Tenant Definition (100% Flutter InviteTenantScreen & PropertySettingsScreen Contract Tab Parity)
  const [newContractProperty, setNewContractProperty] = useState<AgencyManagedProperty | null>(null);
  const [isNewContractModalOpen, setIsNewContractModalOpen] = useState(false);
  const [newContractTenantName, setNewContractTenantName] = useState("");
  const [newContractTenantEmail, setNewContractTenantEmail] = useState("");
  const [newContractTenantPhone, setNewContractTenantPhone] = useState("");
  const [newContractTenantIdNumber, setNewContractTenantIdNumber] = useState("");
  const [newContractTenantNotes, setNewContractTenantNotes] = useState("");
  const [newContractTenantIdDocUrl, setNewContractTenantIdDocUrl] = useState<string | null>(null);
  const [newContractTenantIdDocName, setNewContractTenantIdDocName] = useState("");
  const [isUploadingTenantIdDoc, setIsUploadingTenantIdDoc] = useState(false);
  const [newContractSecondaryContacts, setNewContractSecondaryContacts] = useState<TenantSecondaryContact[]>([]);
  const [newContractRent, setNewContractRent] = useState("");
  const [newContractDeposit, setNewContractDeposit] = useState("");
  const [newContractCurrency, setNewContractCurrency] = useState("EUR");
  const [newContractDepositCurrency, setNewContractDepositCurrency] = useState("EUR");
  const [newContractDueDay, setNewContractDueDay] = useState("1");
  const [newContractStartDate, setNewContractStartDate] = useState("");
  const [newContractEndDate, setNewContractEndDate] = useState("");
  const [newContractExpenses, setNewContractExpenses] = useState<ContractExpenseItem[]>([]);
  const [customExpenseNameInput, setCustomExpenseNameInput] = useState("");
  const [newContractMainDocUrl, setNewContractMainDocUrl] = useState<string | null>(null);
  const [newContractMainDocName, setNewContractMainDocName] = useState("");
  const [isUploadingMainContractDoc, setIsUploadingMainContractDoc] = useState(false);
  const [newContractAdditionalDocs, setNewContractAdditionalDocs] = useState<ContractAdditionalDocument[]>([]);
  const [newAdditionalDocTitle, setNewAdditionalDocTitle] = useState("");
  const [isUploadingAdditionalDoc, setIsUploadingAdditionalDoc] = useState(false);
  const [isCreatingContract, setIsCreatingContract] = useState(false);

  // 3.5 Edit Property Details & Specs Modal State (100% Flutter PropertySpecsFormSection & PropertySettingsScreen Property Tab Parity)
  const [editingSpecsProperty, setEditingSpecsProperty] = useState<AgencyManagedProperty | null>(null);
  const [specTitle, setSpecTitle] = useState("");
  const [specAddress, setSpecAddress] = useState("");
  const [specCity, setSpecCity] = useState("Beograd");
  const [specPropertyType, setSpecPropertyType] = useState("apartment");
  const [specUnitNumber, setSpecUnitNumber] = useState("");
  const [specRoomCount, setSpecRoomCount] = useState("2.0");
  const [specAreaSqm, setSpecAreaSqm] = useState("");
  const [specFloor, setSpecFloor] = useState("1");
  const [specTotalFloors, setSpecTotalFloors] = useState("");
  const [specFurnishing, setSpecFurnishing] = useState("furnished");
  const [specHeatingType, setSpecHeatingType] = useState("cg");
  const [specAmenities, setSpecAmenities] = useState<string[]>([]);
  const [specDescription, setSpecDescription] = useState("");
  const [specDefaultRent, setSpecDefaultRent] = useState("");
  const [specDefaultDeposit, setSpecDefaultDeposit] = useState("");
  const [specCurrency, setSpecCurrency] = useState("EUR");
  const [specDefaultDepositCurrency, setSpecDefaultDepositCurrency] = useState("EUR");
  const [specDefaultDueDay, setSpecDefaultDueDay] = useState("1");
  const [specExpensesTemplate, setSpecExpensesTemplate] = useState<ContractExpenseItem[]>([]);
  const [specCustomExpenseInput, setSpecCustomExpenseInput] = useState("");
  const [isSavingPropertySpecs, setIsSavingPropertySpecs] = useState(false);

  const DEFAULT_STANDARD_EXPENSES: ContractExpenseItem[] = [
    { name: "Infostan", receiver: "owner", amount: 0, payment_method: "bank_transfer" },
    { name: "Struja", receiver: "owner", amount: 0, payment_method: "bank_transfer" },
    { name: "Internet & TV", receiver: "included", amount: 0, payment_method: "bank_transfer" },
    { name: "Održavanje zgrade", receiver: "included", amount: 0, payment_method: "bank_transfer" },
  ];

  const isStandardExpenseName = (name: string) => {
    const lower = (name || "").trim().toLowerCase();
    return (
      lower === "infostan" ||
      lower.startsWith("struja") ||
      lower.startsWith("internet") ||
      lower.startsWith("održavanje") ||
      lower.startsWith("odrzavanje")
    );
  };

  // Whether the user has an authenticated Supabase session (including 7-day verified demo accounts in Supabase)
  const hasSupabaseSession = Boolean(userId && userId !== "demo");

  // Track existing tenant info for prefill & change detection banner
  const [existingContractTarget, setExistingContractTarget] = useState<AgencyContract | null>(null);
  const [hasExistingTenant, setHasExistingTenant] = useState(false);
  const [initialTenantName, setInitialTenantName] = useState("");
  const [initialTenantEmail, setInitialTenantEmail] = useState("");
  const [initialTenantPhone, setInitialTenantPhone] = useState("");

  // A new tenant invitation / pending contract should ONLY be created if the Tenant Email changed to a different non-empty email.
  // Editing the tenant's name, phone, ID number, rent, or dates while keeping the email unchanged must update the existing contract in place.
  const isTenantInfoChanged = useMemo(() => {
    if (!hasExistingTenant) return false;
    const initEmail = initialTenantEmail.trim().toLowerCase();
    const nextEmail = newContractTenantEmail.trim().toLowerCase();
    if (!nextEmail) return false;
    // If there was an existing email and the user changed it to a different email, treat as a new tenant invite
    if (initEmail !== "" && nextEmail !== initEmail) return true;
    // If there was no initial email AND no linked tenant_id on the contract/property, entering an email invites a new tenant
    const hasLinkedTenantUser = Boolean(
      existingContractTarget?.tenant_id || newContractProperty?.tenant_id
    );
    if (initEmail === "" && !hasLinkedTenantUser) return true;
    return false;
  }, [
    hasExistingTenant,
    initialTenantEmail,
    newContractTenantEmail,
    existingContractTarget,
    newContractProperty,
  ]);

  const isUpdatingExistingContract = Boolean(
    existingContractTarget && !isTenantInfoChanged
  );

  // 4. Change Landlord Modal state
  const [changeLandlordProp, setChangeLandlordProp] = useState<AgencyManagedProperty | null>(null);
  const [changeLandlordName, setChangeLandlordName] = useState("");
  const [changeLandlordEmail, setChangeLandlordEmail] = useState("");
  const [changeLandlordPhone, setChangeLandlordPhone] = useState("");
  const [isUpdatingLandlord, setIsUpdatingLandlord] = useState(false);

  // Edit Property Owners Modal state (Flutter SSOT Parity)
  const [editingOwnersProperty, setEditingOwnersProperty] = useState<AgencyManagedProperty | null>(null);

  // 4. Detailed Mark as Paid Modal
  const [isMarkPaidModalOpen, setIsMarkPaidModalOpen] = useState(false);
  const [markPaidPayment, setMarkPaidPayment] = useState<AgencyRentPayment | null>(null);
  const [markPaidMethod, setMarkPaidMethod] = useState<"bank_transfer" | "cash" | "card">("bank_transfer");
  const [markPaidDate, setMarkPaidDate] = useState("");
  const [markPaidNote, setMarkPaidNote] = useState("");
  const [isSubmittingMarkPaid, setIsSubmittingMarkPaid] = useState(false);

  // 5. Dispute Modal
  const [isDisputeModalOpen, setIsDisputeModalOpen] = useState(false);
  const [disputePayment, setDisputePayment] = useState<AgencyRentPayment | null>(null);
  const [disputeReason, setDisputeReason] = useState("");
  const [isSubmittingDispute, setIsSubmittingDispute] = useState(false);

  // Multi-Select / Bulk Payment State (Flutter SSOT Parity)
  const [selectedPaymentIds, setSelectedPaymentIds] = useState<Set<string>>(new Set());
  const [isBulkMarkPaidModalOpen, setIsBulkMarkPaidModalOpen] = useState(false);
  const [bulkMarkPaidMethod, setBulkMarkPaidMethod] = useState<"bank_transfer" | "cash" | "card">("bank_transfer");
  const [bulkMarkPaidDate, setBulkMarkPaidDate] = useState("");
  const [bulkMarkPaidNote, setBulkMarkPaidNote] = useState("");
  const [bulkReceiptFile, setBulkReceiptFile] = useState<File | null>(null);
  const [bulkReceiptFileName, setBulkReceiptFileName] = useState("");
  const [bulkReceiptFileUrl, setBulkReceiptFileUrl] = useState<string | null>(null);
  const [isSubmittingBulkMarkPaid, setIsSubmittingBulkMarkPaid] = useState(false);

  const toggleSelectPayment = (payId: string) => {
    setSelectedPaymentIds((prev) => {
      const next = new Set(prev);
      if (next.has(payId)) {
        next.delete(payId);
      } else {
        next.add(payId);
      }
      return next;
    });
  };

  const toggleSelectMonth = (paymentsInMonth: AgencyRentPayment[]) => {
    const selectableInMonth = paymentsInMonth.filter((p) => p.status !== "paid");
    if (selectableInMonth.length === 0) return;

    const allMonthSelected = selectableInMonth.every((p) => selectedPaymentIds.has(p.id));
    setSelectedPaymentIds((prev) => {
      const next = new Set(prev);
      if (allMonthSelected) {
        selectableInMonth.forEach((p) => next.delete(p.id));
      } else {
        selectableInMonth.forEach((p) => next.add(p.id));
      }
      return next;
    });
  };

  const clearSelectedPayments = () => {
    setSelectedPaymentIds(new Set());
  };

  // Collapsible Filter Deck & Months state
  const [isFilterDeckOpen, setIsFilterDeckOpen] = useState(true);
  const [collapsedMonths, setCollapsedMonths] = useState<Set<string>>(new Set());

  const toggleMonthCollapse = (mKey: string) => {
    setCollapsedMonths((prev) => {
      const next = new Set(prev);
      if (next.has(mKey)) {
        next.delete(mKey);
      } else {
        next.add(mKey);
      }
      return next;
    });
  };

  // Keep selectedPropertyDrawer synchronized whenever managedProperties updates (e.g. after relisting or termination)
  useEffect(() => {
    if (initialSelectedProperty) {
      setSelectedPropertyDrawer(initialSelectedProperty);
      setPropertyDrawerTab("payments");
      inspectProperty(initialSelectedProperty);
    }
  }, [initialSelectedProperty]);

  useEffect(() => {
    if (!selectedPropertyDrawer) return;
    const latest = managedProperties.find((mp) => mp.id === selectedPropertyDrawer.id);
    if (latest) {
      setSelectedPropertyDrawer((prev) => {
        if (!prev || prev.id !== latest.id) return prev;
        if (
          prev.is_occupied === latest.is_occupied &&
          prev.last_listing_id === latest.last_listing_id &&
          prev.active_contract_id === latest.active_contract_id &&
          prev.active_tenant_name === latest.active_tenant_name &&
          prev.default_monthly_rent === latest.default_monthly_rent
        ) {
          return prev;
        }
        return {
          ...prev,
          ...latest,
          owners: prev.owners && prev.owners.length > 0 ? prev.owners : latest.owners,
        };
      });
    }
  }, [managedProperties, selectedPropertyDrawer?.id]);

  useEffect(() => {
    if (initialExpandedPaymentId) {
      setTargetPaymentId(initialExpandedPaymentId);
      setExpandedMonthlyItemIds((prev) => {
        const next = new Set(prev);
        next.add(initialExpandedPaymentId);
        return next;
      });
    }
  }, [initialExpandedPaymentId]);

  useEffect(() => {
    if (targetPaymentId && selectedPropertyDrawer) {
      setExpandedMonthlyItemIds((prev) => {
        const next = new Set(prev);
        next.add(targetPaymentId);
        return next;
      });
      const targetPay = payments.find((pay) => pay.id === targetPaymentId);
      if (targetPay && targetPay.due_date) {
        const monthKey = targetPay.due_date.slice(0, 7);
        setCollapsedMonths((prev) => {
          const next = new Set(prev);
          next.delete(monthKey);
          return next;
        });
      }
      const timer = setTimeout(() => {
        const el = document.getElementById(`payment-row-${targetPaymentId}`);
        if (el) {
          el.scrollIntoView({ behavior: "smooth", block: "center" });
        }
      }, 350);
      return () => clearTimeout(timer);
    }
  }, [targetPaymentId, selectedPropertyDrawer, payments]);

  // Invoice Entry & Upload Modal (Flutter _handleInvoiceUpload SSOT)
  const [isInvoiceModalOpen, setIsInvoiceModalOpen] = useState(false);
  const [invoicePayment, setInvoicePayment] = useState<AgencyRentPayment | null>(null);
  const [invoiceAmount, setInvoiceAmount] = useState("");
  const [invoiceCurrency, setInvoiceCurrency] = useState<"RSD" | "EUR">("RSD");
  const [invoiceDueDate, setInvoiceDueDate] = useState("");
  const [invoiceNote, setInvoiceNote] = useState("");
  const [invoiceFileUrl, setInvoiceFileUrl] = useState<string | null>(null);
  const [invoiceFileName, setInvoiceFileName] = useState<string>("");
  const [isSubmittingInvoice, setIsSubmittingInvoice] = useState(false);

  // 6. Manual Agency Notes (Audit)
  const [isAddNoteModalOpen, setIsAddNoteModalOpen] = useState(false);
  const [newNoteText, setNewNoteText] = useState("");
  const [newNoteDate, setNewNoteDate] = useState("");
  const [isSubmittingNote, setIsSubmittingNote] = useState(false);
  const [isEditNoteModalOpen, setIsEditNoteModalOpen] = useState(false);
  const [editingNoteLog, setEditingNoteLog] = useState<any | null>(null);
  const [editNoteText, setEditNoteText] = useState("");
  const [isSubmittingEditNote, setIsSubmittingEditNote] = useState(false);
  const [auditFilter, setAuditFilter] = useState<"all" | "system" | "manual">("all");
  const [propertyNotes, setPropertyNotes] = useState<Record<string, Array<{ id: string; note: string; created_at: string; user_name?: string }>>>({
    "prop-1": [
      { id: "note-1", note: "Kiracı ile görüşüldü, gelecek ay için klima bakımı talep etti.", created_at: "2026-11-10T14:30:00Z", user_name: "Acente" }
    ]
  });

  // Portfolio filter & display state (Flutter Web Parity)
  const [filterBy, setFilterBy] = useState<"all" | "has_debt" | "occupied" | "vacant" | "expiring" | "expired">(
    propOccupancyFilter || "all"
  );

  useEffect(() => {
    if (propOccupancyFilter) {
      setFilterBy(propOccupancyFilter);
    }
  }, [propOccupancyFilter]);
  const [isFilterExpanded, setIsFilterExpanded] = useState<boolean>(true);
  const [searchQuery, setSearchQuery] = useState<string>("");
  const [selectedCity, setSelectedCity] = useState<string>("all");
  const [selectedLandlord, setSelectedLandlord] = useState<string>("all");
  const [groupBy, setGroupBy] = useState<"none" | "landlord" | "city" | "status" | "debt_consent">("none");
  const [sortBy, setSortBy] = useState<"newest" | "oldest" | "debt" | "rent_desc" | "rent_asc" | "name_asc" | "city_asc" | "landlord_asc">("name_asc");
  const [viewMode, setViewMode] = useState<"table" | "grid">("table");
  const [actionMenuPropId, setActionMenuPropId] = useState<string | null>(null);

  // Add Property Modal state
  const [isAddPropertyModalOpen, setIsAddPropertyModalOpen] = useState(false);
  const [newPropTitle, setNewPropTitle] = useState("");
  const [newPropAddress, setNewPropAddress] = useState("");
  const [newPropCity, setNewPropCity] = useState("Beograd");
  const [newPropRent, setNewPropRent] = useState("");
  const [newPropCurrency, setNewPropCurrency] = useState("EUR");
  const [newPropRooms, setNewPropRooms] = useState("");
  const [newPropArea, setNewPropArea] = useState("");
  const [newPropFloor, setNewPropFloor] = useState("");
  const [newPropUnit, setNewPropUnit] = useState("");
  const [newPropLandlordName, setNewPropLandlordName] = useState("");
  const [newPropLandlordPhone, setNewPropLandlordPhone] = useState("");
  const [newPropLandlordEmail, setNewPropLandlordEmail] = useState("");
  const [newPropTenantName, setNewPropTenantName] = useState("");
  const [newPropIsOccupied, setNewPropIsOccupied] = useState(false);
  const [isSubmittingNewProp, setIsSubmittingNewProp] = useState(false);

  // Map of active contracts by property ID (only truly active/pending contracts, not terminated or relisted)
  const propertyContract = useMemo(() => {
    const map: Record<string, AgencyContract> = {};
    contracts.forEach((c) => {
      const isTerminatedCtr =
        c.status === "terminated" ||
        c.status === "termination_requested" ||
        Boolean(c.termination_approved) ||
        Boolean(c.termination_date);
      if (
        c.property_id &&
        !isTerminatedCtr &&
        (c.status === "active" || c.status === "pending") &&
        (!map[c.property_id] || c.status === "active")
      ) {
        map[c.property_id] = c;
      }
    });
    return map;
  }, [contracts]);

  // Debt Property IDs calculated from payments (Flutter SSOT)
  const debtPropertyIds = useMemo(() => {
    const ids = new Set<string>();
    const now = new Date().toISOString().split("T")[0];
    payments.forEach((pay) => {
      if (pay.status !== "paid" && (pay.amount || 0) > 0) {
        if (
          pay.status === "overdue" ||
          pay.status === "declared" ||
          pay.status === "disputed" ||
          Boolean(pay.declared_at) ||
          (pay.status === "pending" && (!pay.due_date || pay.due_date < now))
        ) {
          ids.add(pay.property_id);
        }
      }
    });
    return ids;
  }, [payments]);

  // Scoped properties (filtered by city, landlord, search — before quick summary card segment)
  const scopedProperties = useMemo(() => {
    let list = [...managedProperties];

    if (selectedCity !== "all") {
      list = list.filter((p) => (p.city || "").toLowerCase() === selectedCity.toLowerCase());
    }

    if (selectedLandlord !== "all") {
      list = list.filter((p) => {
        const lName = p.landlord_name || (p as any).landlord?.full_name || "";
        return lName.toLowerCase() === selectedLandlord.toLowerCase();
      });
    }

    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase().trim();
      list = list.filter((p) =>
        (p.title && p.title.toLowerCase().includes(q)) ||
        (p.address && p.address.toLowerCase().includes(q)) ||
        (p.city && p.city.toLowerCase().includes(q)) ||
        (p.landlord_name && p.landlord_name.toLowerCase().includes(q)) ||
        (p.active_tenant_name && p.active_tenant_name.toLowerCase().includes(q))
      );
    }

    return list;
  }, [managedProperties, selectedCity, selectedLandlord, searchQuery]);

  const scopedPropertyIds = useMemo(() => new Set(scopedProperties.map((p) => p.id)), [scopedProperties]);

  // Counts and metric aggregations for summary filter cards (dynamically scoped by search & filters)
  const totalCount = scopedProperties.length;
  const debtCount = useMemo(() => {
    return scopedProperties.filter((p) => debtPropertyIds.has(p.id)).length;
  }, [scopedProperties, debtPropertyIds]);
  const occupiedCount = useMemo(() => {
    return scopedProperties.filter((p) => p.is_occupied).length;
  }, [scopedProperties]);
  const vacantCount = useMemo(() => {
    return scopedProperties.filter((p) => !p.is_occupied).length;
  }, [scopedProperties]);

  const cityList = useMemo(() => {
    const set = new Set<string>();
    managedProperties.forEach((p) => {
      if (p.city && p.city.trim()) set.add(p.city.trim());
    });
    return Array.from(set).sort();
  }, [managedProperties]);

  const landlordList = useMemo(() => {
    const set = new Set<string>();
    managedProperties.forEach((p) => {
      const lName = p.landlord_name || (p as any).landlord?.full_name;
      if (lName && lName.trim()) set.add(lName.trim());
    });
    return Array.from(set).sort();
  }, [managedProperties]);

  const expiredPropertyIds = useMemo(() => {
    const ids = new Set<string>();
    const todayIso = new Date().toISOString().split("T")[0];
    contracts.forEach((c) => {
      if (c.status === "expired" || (c.status === "active" && c.end_date && c.end_date < todayIso)) {
        ids.add(c.property_id);
      }
    });
    return ids;
  }, [contracts]);

  const expiringPropertyIds = useMemo(() => {
    const ids = new Set<string>();
    const now = Date.now();
    contracts.forEach((c) => {
      if (c.status === "active" && c.end_date) {
        const diffTime = new Date(c.end_date).getTime() - now;
        const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
        if (diffDays >= 0 && diffDays <= 60) {
          ids.add(c.property_id);
        }
      }
    });
    return ids;
  }, [contracts]);

  const expiringCount = useMemo(() => {
    return scopedProperties.filter((p) => expiringPropertyIds.has(p.id)).length;
  }, [scopedProperties, expiringPropertyIds]);

  const totalPortfolioRent = useMemo(() => {
    return scopedProperties.reduce((acc, p) => acc + (p.default_monthly_rent || 0), 0);
  }, [scopedProperties]);

  const totalDebtAmount = useMemo(() => {
    const now = new Date().toISOString().split("T")[0];
    return payments.reduce((acc, pay) => {
      if (scopedPropertyIds.has(pay.property_id) && pay.status !== "paid" && (pay.amount || 0) > 0) {
        if (
          pay.status === "overdue" ||
          pay.status === "declared" ||
          pay.status === "disputed" ||
          Boolean(pay.declared_at) ||
          (pay.status === "pending" && (!pay.due_date || pay.due_date < now))
        ) {
          return acc + pay.amount;
        }
      }
      return acc;
    }, 0);
  }, [payments, scopedPropertyIds]);

  const hasActiveDetailedFilters =
    searchQuery.trim() !== "" ||
    selectedCity !== "all" ||
    selectedLandlord !== "all" ||
    groupBy !== "none" ||
    sortBy !== "name_asc" ||
    filterBy !== "all";

  const handleResetFilters = () => {
    setSearchQuery("");
    setSelectedCity("all");
    setSelectedLandlord("all");
    setGroupBy("none");
    setSortBy("name_asc");
    setFilterBy("all");
    setPropOccupancyFilter("all");
  };

  // Filtered & Sorted properties
  const filteredAndSortedProperties = useMemo(() => {
    let list = [...scopedProperties];

    // Quick filter (from summary cards & cockpit navigation)
    if (filterBy === "has_debt") {
      list = list.filter((p) => debtPropertyIds.has(p.id));
    } else if (filterBy === "occupied") {
      list = list.filter((p) => p.is_occupied);
    } else if (filterBy === "vacant") {
      list = list.filter((p) => !p.is_occupied);
    } else if (filterBy === "expiring") {
      list = list.filter((p) => expiringPropertyIds.has(p.id));
    } else if (filterBy === "expired") {
      list = list.filter((p) => expiredPropertyIds.has(p.id));
    }

    // Sort
    list.sort((a, b) => {
      switch (sortBy) {
        case "newest":
          return (b.created_at || "").localeCompare(a.created_at || "");
        case "oldest":
          return (a.created_at || "").localeCompare(b.created_at || "");
        case "debt": {
          const aHasDebt = debtPropertyIds.has(a.id) ? 1 : 0;
          const bHasDebt = debtPropertyIds.has(b.id) ? 1 : 0;
          if (bHasDebt !== aHasDebt) return bHasDebt - aHasDebt;
          return (b.default_monthly_rent || 0) - (a.default_monthly_rent || 0);
        }
        case "rent_desc":
          return (b.default_monthly_rent || 0) - (a.default_monthly_rent || 0);
        case "rent_asc":
          return (a.default_monthly_rent || 0) - (b.default_monthly_rent || 0);
        case "name_asc":
          return (a.title || "").localeCompare(b.title || "");
        case "city_asc":
          return (a.city || "").localeCompare(b.city || "");
        case "landlord_asc":
          return (a.landlord_name || "").localeCompare(b.landlord_name || "");
        default:
          return 0;
      }
    });

    return list;
  }, [scopedProperties, filterBy, sortBy, debtPropertyIds, expiringPropertyIds, expiredPropertyIds]);

  // Grouped properties
  const groupedProperties = useMemo(() => {
    if (groupBy === "none") {
      return [{ groupName: null, items: filteredAndSortedProperties }];
    }
    const map = new Map<string, AgencyManagedProperty[]>();
    filteredAndSortedProperties.forEach((p) => {
      let g = "";
      if (groupBy === "landlord") {
        g = p.landlord_name || t("vacantLabel");
      } else if (groupBy === "city") {
        g = p.city || "-";
      } else if (groupBy === "status") {
        g = debtPropertyIds.has(p.id) ? t("statusOverdue") : (p.is_occupied ? t("statusClean") : t("vacantLabel"));
      } else if (groupBy === "debt_consent") {
        g = debtPropertyIds.has(p.id) ? t("statusOverdue") : t("statusClean");
      }
      if (!map.has(g)) map.set(g, []);
      map.get(g)!.push(p);
    });
    return Array.from(map.entries()).map(([groupName, items]) => ({
      groupName,
      items,
    }));
  }, [filteredAndSortedProperties, groupBy, debtPropertyIds, t]);

  const handleAddPropertySubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (isDemoMode && !isDemoVerified) {
      onRequestVerification?.();
      return;
    }
    if (!newPropTitle.trim() || !newPropAddress.trim()) return;
    setIsSubmittingNewProp(true);
    try {
      const newPropId = `prop-${Date.now()}`;
      const newPropObj: AgencyManagedProperty = {
        id: newPropId,
        agency_id: userId || "agency-demo",
        title: newPropTitle.trim(),
        address: newPropAddress.trim(),
        city: newPropCity.trim() || "Beograd",
        default_monthly_rent: newPropRent ? parseFloat(newPropRent) : 0,
        currency: newPropCurrency,
        room_count: newPropRooms.trim() || undefined,
        area_sqm: newPropArea ? parseFloat(newPropArea) : undefined,
        floor: newPropFloor.trim() || undefined,
        unit_number: newPropUnit.trim() || undefined,
        landlord_name: newPropLandlordName.trim() || undefined,
        landlord_phone: newPropLandlordPhone.trim() || undefined,
        landlord_email: newPropLandlordEmail.trim() || undefined,
        is_occupied: newPropIsOccupied,
        active_tenant_name: newPropIsOccupied ? (newPropTenantName.trim() || undefined) : undefined,
        created_at: new Date().toISOString(),
      };

      if (hasSupabaseSession) {
        const { data, error } = await supabase.from("properties").insert({
          agency_id: userId,
          title: newPropObj.title,
          name: newPropObj.title,
          address: newPropObj.address,
          city: newPropObj.city,
          default_monthly_rent: newPropObj.default_monthly_rent,
          currency: newPropObj.currency,
          room_count: newPropObj.room_count,
          area_sqm: newPropObj.area_sqm,
          floor: newPropObj.floor,
          unit_number: newPropObj.unit_number,
          landlord_name: newPropObj.landlord_name,
          landlord_phone: newPropObj.landlord_phone,
          landlord_email: newPropObj.landlord_email,
        }).select().single();

        if (error) throw error;
        if (data) {
          newPropObj.id = data.id;
        }
      }

      setManagedProperties((prev) => [newPropObj, ...prev]);
      setStatusMessage({ type: "success", text: t("agency_props_add_success") });
      setIsAddPropertyModalOpen(false);
      // Reset form
      setNewPropTitle("");
      setNewPropAddress("");
      setNewPropCity("Beograd");
      setNewPropRent("");
      setNewPropRooms("");
      setNewPropArea("");
      setNewPropFloor("");
      setNewPropUnit("");
      setNewPropLandlordName("");
      setNewPropLandlordPhone("");
      setNewPropLandlordEmail("");
      setNewPropTenantName("");
      setNewPropIsOccupied(false);
    } catch (err: any) {
      console.error("Error adding property:", err);
      const errMsg =
        err?.message ||
        err?.error_description ||
        err?.details ||
        (typeof err === "string" ? err : "Failed to add property");
      setStatusMessage({ type: "error", text: errMsg });
    } finally {
      setIsSubmittingNewProp(false);
    }
  };

  const inspectProperty = async (
    p: AgencyManagedProperty,
    initialTab: "payments" | "overview" | "maintenance" | "audit" = "payments"
  ) => {
    setSelectedPropertyDrawer(p);
    setPropertyDrawerTab(initialTab);
    setSelectedPaymentIds(new Set());
    if (hasSupabaseSession) {
      try {
        // 1. Fetch fresh property owners (SSOT corporate & co-owners like GROWTH EDGE)
        const { data: ownersData } = await supabase
          .from("property_owners")
          .select("*")
          .eq("property_id", p.id)
          .order("is_primary", { ascending: false });

        let resolvedName: string | null = null;
        let resolvedPhone: string | null = null;
        let resolvedEmail: string | null = null;

        if (ownersData && ownersData.length > 0) {
          const primary = ownersData.find((o: any) => o.is_primary) || ownersData[0];
          resolvedName =
            primary.owner_type === "company"
              ? primary.company_name?.trim() || null
              : `${primary.first_name || ""} ${primary.last_name || ""}`.trim() || null;
          resolvedPhone = primary.phone?.trim() || null;
          resolvedEmail = primary.email?.trim() || null;
          if (!resolvedEmail) {
            const ownerWithEmail = ownersData.find((o: any) => o.email?.trim());
            if (ownerWithEmail) resolvedEmail = ownerWithEmail.email.trim();
          }
        }

        // 2. Fetch landlord profile from profiles table if landlord_id is linked (Flutter SSOT parity)
        if (p.landlord_id) {
          try {
            const { data: landlordProf } = await supabase
              .from("profiles")
              .select("id, full_name, phone_number, email")
              .eq("id", p.landlord_id)
              .maybeSingle();

            if (landlordProf) {
              if (!resolvedName && landlordProf.full_name?.trim()) {
                resolvedName = landlordProf.full_name.trim();
              }
              if (!resolvedEmail && landlordProf.email?.trim()) {
                resolvedEmail = landlordProf.email.trim();
              }
              if (!resolvedPhone && landlordProf.phone_number?.trim()) {
                resolvedPhone = landlordProf.phone_number.trim();
              }
            }
          } catch (profErr) {
            console.warn("Could not fetch landlord profile in inspectProperty:", profErr);
          }
        }

        // 2.5. Resolve tenant profile if tenant_id is linked and active_tenant_name / phone is missing
        const activeCtr =
          contracts.find((c) => c.property_id === p.id && c.status === "active") ||
          contracts.find((c) => c.property_id === p.id && c.status === "pending");
        let resolvedTenantName: string | null =
          activeCtr?.tenant_name || p.active_tenant_name || null;
        let resolvedTenantPhone: string | null =
          activeCtr?.tenant_phone || p.active_tenant_phone || null;
        let resolvedTenantEmail: string | null =
          activeCtr?.invitee_email || null;

        const targetTenantId = activeCtr?.tenant_id || p.tenant_id;
        if (targetTenantId && (!resolvedTenantName || !resolvedTenantPhone || !resolvedTenantEmail)) {
          try {
            const { data: tenantProf } = await supabase
              .from("profiles")
              .select("id, full_name, phone_number, email")
              .eq("id", targetTenantId)
              .maybeSingle();

            if (tenantProf) {
              if (!resolvedTenantName && tenantProf.full_name?.trim()) {
                resolvedTenantName = tenantProf.full_name.trim();
              }
              if (!resolvedTenantPhone && tenantProf.phone_number?.trim()) {
                resolvedTenantPhone = tenantProf.phone_number.trim();
              }
              if (!resolvedTenantEmail && tenantProf.email?.trim()) {
                resolvedTenantEmail = tenantProf.email.trim();
              }
            }
          } catch (tProfErr) {
            console.warn("Could not fetch tenant profile in inspectProperty:", tProfErr);
          }
        }

        if (activeCtr && (resolvedTenantName || resolvedTenantPhone || resolvedTenantEmail)) {
          setContracts((prev) =>
            prev.map((c) =>
              c.id === activeCtr.id
                ? {
                  ...c,
                  tenant_name: c.tenant_name || resolvedTenantName,
                  tenant_phone: c.tenant_phone || resolvedTenantPhone,
                  invitee_email: c.invitee_email || resolvedTenantEmail,
                }
                : c
            )
          );
        }

        const updatedDrawer: AgencyManagedProperty = {
          ...p,
          landlord_name: resolvedName || p.landlord_name,
          landlord_phone: resolvedPhone || p.landlord_phone,
          landlord_email: resolvedEmail || p.landlord_email,
          active_tenant_name: resolvedTenantName || p.active_tenant_name,
          active_tenant_phone: resolvedTenantPhone || p.active_tenant_phone,
          owners: ownersData && ownersData.length > 0 ? ownersData : p.owners,
        };
        setSelectedPropertyDrawer(updatedDrawer);
        setManagedProperties((prev) =>
          prev.map((item) => (item.id === p.id ? { ...item, ...updatedDrawer } : item))
        );

        // 3. Fetch landlord invitations to dynamically determine invitation status per owner/landlord
        try {
          const { data: invitesData } = await supabase
            .from("invitations")
            .select("id, invitee_email, status, created_at")
            .eq("property_id", p.id)
            .eq("target_role", "landlord");
          setDrawerLandlordInvites(invitesData || []);
        } catch (invErr) {
          console.warn("Could not fetch landlord invitations in inspectProperty:", invErr);
        }

        // 4. Auto-generate missing payments & load payments for drawer
        await supabase.rpc("generate_missing_rent_payments", { p_property_id: p.id });
        const { data: propPays } = await supabase
          .from("rent_payments")
          .select("*")
          .eq("property_id", p.id)
          .order("due_date", { ascending: false });
        if (propPays && propPays.length > 0) {
          setPayments((prev) => {
            const others = prev.filter((item) => item.property_id !== p.id);
            const mapped: AgencyRentPayment[] = propPays.map((pay: any) => {
              const isRent = (pay.title || "").toLowerCase().includes("kira") || (pay.title || "").toLowerCase().includes("rent") || (pay.title || "").toLowerCase().includes("kirij");
              const effectiveCurr = (Number(pay.amount) > 0 && pay.currency)
                ? pay.currency
                : (isRent ? (pay.currency || p.currency || "EUR") : "RSD");
              return {
                id: pay.id,
                property_id: pay.property_id,
                contract_id: pay.contract_id,
                tenant_id: pay.tenant_id,
                property_title: p.title,
                property_address: p.address,
                tenant_name: p.active_tenant_name || null,
                tenant_phone: p.active_tenant_phone || null,
                title: pay.title || "Kira",
                amount: Number(pay.amount) || 0,
                currency: effectiveCurr,
                due_date: pay.due_date,
                declared_at: pay.declared_at,
                paid_at: pay.paid_at,
                status: pay.status,
                receiver_type: pay.receiver_type || "owner",
                payment_method: pay.payment_method,
                receipt_url: pay.receipt_url,
                invoice_url: pay.invoice_url || null,
                owner_note: pay.owner_note,
                dispute_reason: pay.dispute_reason || null,
                disputed_at: pay.disputed_at || null,
                created_at: pay.created_at,
              };
            });
            return [...others, ...mapped];
          });
        }
        // 5. Fetch activity logs for drawer
        try {
          const { data: logsData } = await supabase
            .from("activity_logs")
            .select("*")
            .eq("property_id", p.id)
            .order("created_at", { ascending: false });
          if (logsData) {
            setDrawerActivityLogs(logsData);
            const termLog = logsData.find(
              (lg: any) =>
                lg.type === "contract_termination_requested" ||
                lg.type === "tenant_removed"
            );
            if (termLog) {
              const tDate =
                termLog.metadata?.termination_date ||
                (termLog.created_at ? termLog.created_at.split("T")[0] : "");
              const termCid = termLog.metadata?.contract_id;
              setContracts((prev) =>
                prev.map((c) =>
                  c.id === termCid || (c.property_id === p.id && !p.tenant_id)
                    ? {
                      ...c,
                      status: "terminated",
                      termination_approved: true,
                      termination_date: tDate || c.termination_date || c.end_date,
                      end_date: tDate || c.end_date,
                    }
                    : c
                )
              );
            }
          }
        } catch (logErr) {
          console.warn("Could not fetch activity logs in inspectProperty:", logErr);
        }
      } catch (err) {
        console.warn("Could not inspect property details:", err);
      }
    } else {
      // Demo mode: realistic simulation for owner invites
      setDrawerLandlordInvites([
        { id: "demo-inv-2", invitee_email: "owner2@example.com", status: "pending" },
      ]);
      setDrawerActivityLogs([]);
    }
  };

  const handleMarkPaymentPaid = async (pay: AgencyRentPayment) => {
    if (isDemoMode && !isDemoVerified) {
      onRequestVerification?.();
      return;
    }
    setProcessingPaymentId(pay.id);
    try {
      if (hasSupabaseSession) {
        await supabase
          .from("rent_payments")
          .update({
            status: "paid",
            paid_at: new Date().toISOString(),
          })
          .eq("id", pay.id);

        try {
          const isRent = (pay.title || "").toLowerCase().includes("kira") || (pay.title || "").toLowerCase().includes("rent") || (pay.title || "").toLowerCase().includes("kirij");
          const logType = isRent ? "rent_approved" : "payment_toggle";
          await supabase.from("activity_logs").insert({
            property_id: pay.property_id,
            user_id: userId,
            type: logType,
            metadata: {
              payment_id: pay.id,
              title: pay.title,
              amount: pay.amount,
              currency: pay.currency,
              due_date: pay.due_date,
              paid: true,
            },
          });
        } catch (_) { }
      }
      setPayments((prev) =>
        prev.map((item) =>
          item.id === pay.id
            ? { ...item, status: "paid", paid_at: new Date().toISOString() }
            : item
        )
      );
    } catch (err) {
      console.error("Error marking payment as paid:", err);
    } finally {
      setProcessingPaymentId(null);
    }
  };

  const handleCreateManualPayment = async (propId: string) => {
    if (isDemoMode && !isDemoVerified) {
      onRequestVerification?.();
      return;
    }
    if (!newPaymentTitle.trim() || !newPaymentAmount) return;
    const amountNum = parseFloat(newPaymentAmount) || 0;
    const dueDate = newPaymentDueDate || new Date().toISOString().split("T")[0];
    const newId = `pay-custom-${Date.now()}`;
    const prop = managedProperties.find((mp) => mp.id === propId);

    if (hasSupabaseSession) {
      try {
        const { data, error } = await supabase
          .from("rent_payments")
          .insert({
            property_id: propId,
            contract_id: prop?.active_contract_id || null,
            title: newPaymentTitle.trim(),
            amount: amountNum,
            currency: prop?.currency || "EUR",
            due_date: dueDate,
            status: "pending",
          })
          .select()
          .single();
        if (error) throw error;
        if (data) {
          try {
            await supabase.from("activity_logs").insert({
              property_id: propId,
              user_id: userId,
              type: "payment_created",
              metadata: {
                payment_id: data.id,
                title: data.title,
                amount: amountNum,
                currency: prop?.currency || "EUR",
                due_date: dueDate,
              },
            });
          } catch (_) { }
          setPayments((prev) => [
            {
              id: data.id,
              property_id: propId,
              contract_id: data.contract_id,
              tenant_id: data.tenant_id,
              property_title: prop?.title || "Mülk",
              property_address: prop?.address || "",
              tenant_name: prop?.active_tenant_name || null,
              tenant_phone: prop?.active_tenant_phone || null,
              title: data.title,
              amount: Number(data.amount) || 0,
              currency: data.currency || "EUR",
              due_date: data.due_date,
              declared_at: null,
              paid_at: null,
              status: "pending",
              payment_method: null,
              receipt_url: null,
              owner_note: null,
              created_at: data.created_at,
            },
            ...prev,
          ]);
        }
      } catch (err) {
        console.error("Error creating manual payment:", err);
      }
    } else {
      setPayments((prev) => [
        {
          id: newId,
          property_id: propId,
          contract_id: prop?.active_contract_id || null,
          tenant_id: null,
          property_title: prop?.title || "Mülk",
          property_address: prop?.address || "",
          tenant_name: prop?.active_tenant_name || null,
          tenant_phone: prop?.active_tenant_phone || null,
          title: newPaymentTitle.trim(),
          amount: amountNum,
          currency: prop?.currency || "EUR",
          due_date: dueDate,
          declared_at: null,
          paid_at: null,
          status: "pending",
          payment_method: "bank_transfer",
          receipt_url: null,
          owner_note: null,
          created_at: new Date().toISOString(),
        },
        ...prev,
      ]);
    }

    setNewPaymentTitle("");
    setNewPaymentAmount("");
    setNewPaymentDueDate("");
    setIsAddPaymentModalOpen(false);
  };

  // Operational Handlers for Property Hub (SSOT Flutter Parity)
  const openRenewContractModal = (contract: AgencyContract) => {
    setRenewContractTarget(contract);
    const baseRent = contract.monthly_rent || 0;
    setRenewMonthlyRent(baseRent ? baseRent.toString() : "");
    setRenewIncreaseRate("0");

    let start = "";
    if (contract.end_date) {
      const d = new Date(contract.end_date);
      d.setDate(d.getDate() + 1);
      start = d.toISOString().split("T")[0];
    } else {
      const now = new Date();
      now.setDate(now.getDate() + 1);
      start = now.toISOString().split("T")[0];
    }
    setRenewStartDate(start);

    const endD = new Date(start);
    endD.setFullYear(endD.getFullYear() + 1);
    endD.setDate(endD.getDate() - 1);
    setRenewEndDate(endD.toISOString().split("T")[0]);

    setIsRenewContractModalOpen(true);
  };

  const handleRenewRateChange = (rateStr: string) => {
    setRenewIncreaseRate(rateStr);
    const rate = parseFloat(rateStr.replace(",", ".")) || 0;
    const baseRent = renewContractTarget?.monthly_rent || 0;
    const newRent = Math.round(baseRent * (1 + rate / 100));
    setRenewMonthlyRent(newRent.toString());
  };

  const handleRenewRentChange = (rentStr: string) => {
    setRenewMonthlyRent(rentStr);
    const newRent = parseFloat(rentStr.replace(",", ".")) || 0;
    const baseRent = renewContractTarget?.monthly_rent || 0;
    if (baseRent > 0) {
      const rate = (((newRent - baseRent) / baseRent) * 100).toFixed(1);
      setRenewIncreaseRate(rate);
    }
  };

  const handleExecuteRenewContract = async (p: AgencyManagedProperty) => {
    if (isDemoMode && !isDemoVerified) {
      onRequestVerification?.();
      return;
    }
    if (!renewContractTarget) return;
    const newRentNum = parseFloat(renewMonthlyRent.replace(",", ".")) || 0;
    if (newRentNum <= 0 || !renewStartDate || !renewEndDate) return;

    setIsRenewingContract(true);
    try {
      const newContractId = `contract-renewed-${Date.now()}`;
      if (hasSupabaseSession) {
        const { data, error } = await supabase
          .from("contracts")
          .insert({
            property_id: p.id,
            landlord_id: renewContractTarget.landlord_id || p.landlord_id,
            tenant_id: renewContractTarget.tenant_id,
            agency_id: userId,
            inviter_name: "Acente",
            monthly_rent: newRentNum,
            deposit_amount: renewContractTarget.deposit_amount || newRentNum,
            currency: renewContractTarget.currency || p.currency || "EUR",
            deposit_currency: renewContractTarget.currency || p.currency || "EUR",
            due_day: renewContractTarget.due_day || 1,
            start_date: renewStartDate,
            end_date: renewEndDate,
            status: "active",
            tenant_name: renewContractTarget.tenant_name || p.active_tenant_name,
            tenant_id_number: renewContractTarget.tenant_id_number,
            tenant_phone: renewContractTarget.tenant_phone || p.active_tenant_phone,
          })
          .select()
          .single();

        if (error) throw error;

        // Auto schedule new rent payments via RPC
        try {
          await supabase.rpc("generate_missing_rent_payments", { p_property_id: p.id });
        } catch (rpcErr) {
          console.warn("RPC generate_missing_rent_payments warning:", rpcErr);
        }

        // Log activity
        try {
          await supabase.from("activity_logs").insert({
            property_id: p.id,
            user_id: userId,
            type: "contract_renewed_by_agency",
            metadata: {
              contract_id: data.id,
              previous_contract_id: renewContractTarget.id,
              new_start_date: renewStartDate,
              new_end_date: renewEndDate,
              new_monthly_rent: newRentNum,
            },
          });
        } catch (_) { }

        if (data) {
          setContracts((prev) => [data as AgencyContract, ...prev]);
        }
      } else {
        // Demo mode state update
        const newDemoContract: AgencyContract = {
          ...renewContractTarget,
          id: newContractId,
          start_date: renewStartDate,
          end_date: renewEndDate,
          monthly_rent: newRentNum,
          status: "active",
        };
        setContracts((prev) => [newDemoContract, ...prev]);
      }

      setIsRenewContractModalOpen(false);
      setStatusMessage({
        type: "success",
        text: t("agency_contract_renewed_success"),
      });
    } catch (err) {
      console.error("Renew contract error:", err);
      setStatusMessage({
        type: "error",
        text: t("agency_panel_msg_save_error"),
      });
    } finally {
      setIsRenewingContract(false);
    }
  };

  const openTerminateContractModal = (contract: AgencyContract) => {
    if (isDemoMode && !isDemoVerified) {
      onRequestVerification?.();
      return;
    }
    setTerminateContractTarget(contract);
    setTerminateDate(new Date().toISOString().split("T")[0]);
    setRelistAfterTerminate(hasPortfolioModule);
    setIsTerminateContractModalOpen(true);
  };

  const handleExecuteTerminateContract = async (p: AgencyManagedProperty) => {
    if (!terminateContractTarget) return;

    setIsTerminatingContract(true);
    try {
      const allPropContractIds = contracts
        .filter((c) => c.property_id === p.id)
        .map((c) => c.id);

      // Persist termination locally so even if legacy contract row has agency_id=NULL in DB before RLS migration, UI never reverts
      if (typeof window !== "undefined") {
        try {
          const rawTerm = localStorage.getItem("stanomer_terminated_contracts_v1");
          const parsed = rawTerm ? JSON.parse(rawTerm) : {};
          const existingIds: string[] = Array.isArray(parsed?.contractIds) ? parsed.contractIds : [];
          const existingPropDates: Record<string, string> =
            parsed?.propertyDates && typeof parsed.propertyDates === "object"
              ? parsed.propertyDates
              : {};
          const nextIds = Array.from(
            new Set([...existingIds, terminateContractTarget.id, ...allPropContractIds])
          );
          existingPropDates[p.id] = terminateDate;
          localStorage.setItem(
            "stanomer_terminated_contracts_v1",
            JSON.stringify({ contractIds: nextIds, propertyDates: existingPropDates })
          );
        } catch { }
      }

      if (hasSupabaseSession) {
        // Update all contracts for this property to terminated
        const { error: cErr } = await supabase
          .from("contracts")
          .update({
            status: "terminated",
            end_date: terminateDate,
            termination_date: terminateDate,
            termination_approved: true,
          })
          .eq("property_id", p.id)
          .in("status", ["active", "pending", "revision_requested", "termination_requested"]);
        if (cErr) {
          // Fallback without termination_date/termination_approved if columns aren't migrated yet
          await supabase
            .from("contracts")
            .update({
              status: "terminated",
              end_date: terminateDate,
            })
            .eq("property_id", p.id);
        }

        const { error: pErr } = await supabase
          .from("properties")
          .update({ tenant_id: null, tenant_name: null })
          .eq("id", p.id);
        if (pErr) {
          await supabase
            .from("properties")
            .update({ tenant_id: null })
            .eq("id", p.id);
        }

        try {
          const { data: insertedLog } = await supabase
            .from("activity_logs")
            .insert({
              property_id: p.id,
              user_id: userId,
              type: "contract_termination_requested",
              metadata: {
                contract_id: terminateContractTarget.id,
                termination_date: terminateDate,
              },
            })
            .select()
            .single();
          if (insertedLog) {
            setDrawerActivityLogs((prev) => [insertedLog, ...prev]);
          }
        } catch (_) { }
      }

      setContracts((prev) => {
        const next = prev.map((c) =>
          c.id === terminateContractTarget.id || c.property_id === p.id
            ? {
              ...c,
              status: "terminated" as const,
              end_date: terminateDate,
              termination_date: terminateDate,
              termination_approved: true,
            }
            : c
        );
        if (typeof window !== "undefined" && (isDemoMode || !hasSupabaseSession)) {
          try {
            localStorage.setItem("stanomer_agency_contracts_demo", JSON.stringify(next));
          } catch { }
        }
        return next;
      });

      const vacatedProp: AgencyManagedProperty = {
        ...p,
        tenant_id: null,
        is_occupied: false,
        active_contract_id: null,
        active_tenant_name: null,
        active_tenant_phone: null,
        contract_end_date: null,
      };

      setManagedProperties((prev) => {
        const next = prev.map((item) =>
          item.id === p.id ? { ...item, ...vacatedProp } : item
        );
        if (typeof window !== "undefined" && (isDemoMode || !hasSupabaseSession)) {
          try {
            localStorage.setItem("stanomer_agency_managed_props_demo", JSON.stringify(next));
          } catch { }
        }
        return next;
      });

      setSelectedPropertyDrawer((prev) =>
        prev && prev.id === p.id ? { ...prev, ...vacatedProp } : prev
      );

      setIsTerminateContractModalOpen(false);
      setStatusMessage({
        type: "success",
        text: t("agency_contract_terminated_success"),
      });
      if (relistAfterTerminate) {
        openRelistModal(vacatedProp);
      }
    } catch (err) {
      console.error("Terminate contract error:", err);
      setStatusMessage({
        type: "error",
        text: t("agency_panel_msg_save_error"),
      });
    } finally {
      setIsTerminatingContract(false);
    }
  };

  const openOwnershipModalWithCheck = (p: AgencyManagedProperty) => {
    if (isDemoMode && !isDemoVerified) {
      onRequestVerification?.();
      return;
    }
    setOwnershipModalProp(p);
  };

  const openNewContractModal = async (p: AgencyManagedProperty) => {
    if (isDemoMode && !isDemoVerified) {
      onRequestVerification?.();
      return;
    }
    setNewContractProperty(p);

    // Find active contract first, then pending contract or mapped contract
    const existingContract =
      contracts.find((c) => c.property_id === p.id && c.status === "active") ||
      contracts.find((c) => c.property_id === p.id && c.status === "pending") ||
      propertyContract[p.id];

    let tName = existingContract?.tenant_name || p.active_tenant_name || "";
    let tPhone = existingContract?.tenant_phone || p.active_tenant_phone || "";
    let tEmail = (existingContract as any)?.invitee_email || "";
    let tIdNum = existingContract?.tenant_id_number || "";
    let tNotes = existingContract?.tenant_notes || "";
    let tIdDocUrl = existingContract?.tenant_id_document_url || null;
    let tSecContacts: TenantSecondaryContact[] = Array.isArray(existingContract?.tenant_secondary_contacts)
      ? existingContract.tenant_secondary_contacts.map((c) => ({ ...c }))
      : [];

    const defaultRent =
      existingContract?.monthly_rent != null
        ? existingContract.monthly_rent.toString()
        : p.default_monthly_rent
          ? p.default_monthly_rent.toString()
          : "600";

    const defaultDeposit =
      existingContract?.deposit_amount != null
        ? existingContract.deposit_amount.toString()
        : p.default_deposit_amount != null
          ? p.default_deposit_amount.toString()
          : defaultRent;

    const defaultCurrency = existingContract?.currency || p.currency || "EUR";
    const defaultDepCurrency =
      existingContract?.deposit_currency ||
      p.default_deposit_currency ||
      defaultCurrency;
    const defaultDueDay =
      existingContract?.due_day != null
        ? existingContract.due_day.toString()
        : p.default_due_day != null
          ? p.default_due_day.toString()
          : "1";

    const today = new Date().toISOString().split("T")[0];
    const defaultStartDate = existingContract?.start_date
      ? existingContract.start_date.split("T")[0]
      : today;

    let defaultEndDate = existingContract?.end_date
      ? existingContract.end_date.split("T")[0]
      : "";
    if (!defaultEndDate) {
      const endD = new Date();
      endD.setFullYear(endD.getFullYear() + 1);
      endD.setDate(endD.getDate() - 1);
      defaultEndDate = endD.toISOString().split("T")[0];
    }

    const initialExpenses: ContractExpenseItem[] =
      Array.isArray(existingContract?.expenses_config) && existingContract.expenses_config.length > 0
        ? existingContract.expenses_config.map((e) => ({
          name: e.name || (e as any).title || "Infostan",
          receiver: e.receiver || "owner",
          amount: Number(e.amount) || 0,
          payment_method: e.payment_method || "bank_transfer",
        }))
        : Array.isArray(p.expenses_template) && p.expenses_template.length > 0
          ? p.expenses_template.map((e) => ({
            name: e.name || (e as any).title || "Infostan",
            receiver: e.receiver || "owner",
            amount: Number(e.amount) || 0,
            payment_method: e.payment_method || "bank_transfer",
          }))
          : DEFAULT_STANDARD_EXPENSES.map((e) => ({ ...e }));

    setNewContractTenantName(tName);
    setNewContractTenantEmail(tEmail);
    setNewContractTenantPhone(tPhone);
    setNewContractTenantIdNumber(tIdNum);
    setNewContractTenantNotes(tNotes);
    setNewContractTenantIdDocUrl(tIdDocUrl);
    setNewContractTenantIdDocName(tIdDocUrl ? tIdDocUrl.split("/").pop() || "ID_Document.pdf" : "");
    setNewContractSecondaryContacts(tSecContacts);
    setNewContractRent(defaultRent);
    setNewContractDeposit(defaultDeposit);
    setNewContractCurrency(defaultCurrency);
    setNewContractDepositCurrency(defaultDepCurrency);
    setNewContractDueDay(defaultDueDay);
    setNewContractStartDate(defaultStartDate);
    setNewContractEndDate(defaultEndDate);
    setNewContractExpenses(initialExpenses);
    setCustomExpenseNameInput("");
    setNewContractMainDocUrl(existingContract?.contract_url || null);
    setNewContractMainDocName(
      existingContract?.contract_url
        ? existingContract.contract_url.split("/").pop() || "Main_Contract.pdf"
        : ""
    );
    setNewContractAdditionalDocs(
      Array.isArray(existingContract?.additional_documents)
        ? existingContract.additional_documents.map((d) => ({ ...d }))
        : []
    );
    setNewAdditionalDocTitle("");

    const exists = Boolean(tName || tEmail || tPhone || p.is_occupied || existingContract);
    setExistingContractTarget(existingContract || null);
    setHasExistingTenant(exists);
    setInitialTenantName(tName);
    setInitialTenantEmail(tEmail);
    setInitialTenantPhone(tPhone);

    setIsNewContractModalOpen(true);

    // Enrich email / phone from profiles or invitations if missing
    if (hasSupabaseSession && exists) {
      try {
        const tenantProfileId = existingContract?.tenant_id || p.tenant_id;
        if (tenantProfileId) {
          const { data: prof } = await supabase
            .from("profiles")
            .select("email, phone_number, full_name")
            .eq("id", tenantProfileId)
            .maybeSingle();

          if (prof) {
            if (!tEmail && prof.email) {
              setNewContractTenantEmail((prev) => (!prev ? prof.email : prev));
              setInitialTenantEmail(prof.email);
            }
            if (!tPhone && prof.phone_number) {
              setNewContractTenantPhone((prev) => (!prev ? prof.phone_number : prev));
              setInitialTenantPhone(prof.phone_number);
            }
            if (!tName && prof.full_name) {
              setNewContractTenantName((prev) => (!prev ? prof.full_name : prev));
              setInitialTenantName(prof.full_name);
            }
          }
        }

        if (!tEmail) {
          const { data: inv } = await supabase
            .from("invitations")
            .select("invitee_email")
            .eq("property_id", p.id)
            .eq("target_role", "tenant")
            .order("created_at", { ascending: false })
            .limit(1)
            .maybeSingle();

          if (inv?.invitee_email) {
            setNewContractTenantEmail((prev) => (!prev ? inv.invitee_email : prev));
            setInitialTenantEmail(inv.invitee_email);
          }
        }
      } catch (enrichErr) {
        console.warn("Could not enrich existing tenant info:", enrichErr);
      }
    }
  };

  const openChangeLandlordModal = (p: AgencyManagedProperty) => {
    setChangeLandlordProp(p);
    setChangeLandlordName(p.landlord_name || "");
    setChangeLandlordEmail(p.landlord_email || "");
    setChangeLandlordPhone(p.landlord_phone || "");
  };

  const handleSaveChangeLandlord = async () => {
    if (isDemoMode && !isDemoVerified) {
      onRequestVerification?.();
      return;
    }
    if (!changeLandlordProp) return;
    setIsUpdatingLandlord(true);
    try {
      const name = changeLandlordName.trim();
      const email = changeLandlordEmail.trim();
      const phone = changeLandlordPhone.trim();

      if (hasSupabaseSession) {
        const { error: propErr } = await supabase
          .from("properties")
          .update({
            landlord_id: null,
            landlord_name: name || null,
            landlord_email: email || null,
            landlord_phone: phone || null,
          })
          .eq("id", changeLandlordProp.id);

        if (propErr) throw propErr;

        await supabase
          .from("invitations")
          .update({ status: "cancelled" })
          .eq("property_id", changeLandlordProp.id)
          .eq("target_role", "landlord")
          .eq("status", "pending");
      }

      setManagedProperties((prev) =>
        prev.map((item) =>
          item.id === changeLandlordProp.id
            ? {
              ...item,
              landlord_id: undefined,
              landlord_name: name || undefined,
              landlord_email: email || undefined,
              landlord_phone: phone || undefined,
            }
            : item
        )
      );

      setSelectedPropertyDrawer((prev) =>
        prev && prev.id === changeLandlordProp.id
          ? {
            ...prev,
            landlord_id: undefined,
            landlord_name: name || undefined,
            landlord_email: email || undefined,
            landlord_phone: phone || undefined,
          }
          : prev
      );

      const targetProp: AgencyManagedProperty = {
        ...changeLandlordProp,
        landlord_id: undefined,
        landlord_name: name || undefined,
        landlord_email: email || undefined,
        landlord_phone: phone || undefined,
      };

      setChangeLandlordProp(null);
      openOwnershipModalWithCheck(targetProp);
      if (setStatusMessage) {
        setStatusMessage({
          type: "success",
          text: t("changeLandlordSuccess"),
        });
      }
    } catch (err: any) {
      console.error("Error updating landlord:", err);
      if (setStatusMessage) {
        setStatusMessage({
          type: "error",
          text: err.message || t("agency_panel_msg_save_error"),
        });
      }
    } finally {
      setIsUpdatingLandlord(false);
    }
  };

  const handleConfirmOffset = async (targetPayment: AgencyRentPayment) => {
    if (!selectedSettlementReq || !selectedPropertyDrawer) return;
    setIsExecutingOffset(true);
    setOffsetError(null);

    try {
      const isAddToRent =
        selectedSettlementReq.paid_by === "landlord" ||
        (selectedSettlementReq.paid_by === "agency" && selectedSettlementReq.declaration_intent === "damage_tenant");
      const costAmt = Math.max(
        0,
        (selectedSettlementReq.cost_amount || 0) - (selectedSettlementReq.settled_amount || 0)
      );
      const offsetAmount = isAddToRent ? costAmt : Math.min(costAmt, targetPayment.amount);

      const res = await executeRentOffset({
        request: selectedSettlementReq,
        payment: targetPayment,
        offsetAmount,
        propertyId: selectedPropertyDrawer.id,
        actorId: userId,
        isDemoMode: isDemoMode && (!userId || userId === "demo"),
        t,
      });

      if (!res.success) {
        setOffsetError(res.error || t("agency_maint_toast_update_failed"));
        return;
      }

      // 1. Update payments in local state
      setPayments((prev) =>
        prev.map((p) => (p.id === res.updatedPayment.id ? res.updatedPayment : p))
      );

      // 2. Update maintenance requests in local state
      if (setMaintenanceRequests) {
        setMaintenanceRequests((prev) =>
          prev.map((m) => (m.id === res.updatedRequest.id ? res.updatedRequest : m))
        );
      }

      // 3. Close modal & reset
      setIsOffsetModalOpen(false);
      setSelectedSettlementReq(null);

      if (setStatusMessage) {
        setStatusMessage({
          type: "success",
          text: isAddToRent
            ? t("agency_maint_add_to_rent_success")
            : t("agency_maint_offset_success"),
        });
      }
    } catch (err: any) {
      console.error("Offset execution error:", err);
      setOffsetError(err.message || t("agency_maint_toast_update_failed"));
    } finally {
      setIsExecutingOffset(false);
    }
  };

  const handleConfirmMaintenanceCrossOffset = async (targetOtherReq: AgencyMaintenanceRequest) => {
    if (!selectedSettlementReq || !selectedPropertyDrawer) return;
    setIsExecutingOffset(true);
    setOffsetError(null);

    try {
      const isCurrentAddToRent =
        selectedSettlementReq.paid_by === "landlord" ||
        (selectedSettlementReq.paid_by === "agency" && selectedSettlementReq.declaration_intent === "damage_tenant");
      // If current is landlord/agency tenant-damage (debt of tenant), other is credit of tenant
      const creditReq = isCurrentAddToRent ? targetOtherReq : selectedSettlementReq;
      const debtReq = isCurrentAddToRent ? selectedSettlementReq : targetOtherReq;

      const res = await executeMaintenanceDebtOffset({
        creditReq,
        debtReq,
        propertyId: selectedPropertyDrawer.id,
        actorId: userId,
        isDemoMode: isDemoMode && (!userId || userId === "demo"),
        t,
      });

      if (!res.success) {
        setOffsetError(res.error || t("agency_maint_toast_update_failed"));
        return;
      }

      // Update maintenance requests in local state
      if (setMaintenanceRequests) {
        setMaintenanceRequests((prev) =>
          prev.map((m) => {
            if (m.id === res.updatedCreditReq.id) return res.updatedCreditReq;
            if (m.id === res.updatedDebtReq.id) return res.updatedDebtReq;
            return m;
          })
        );
      }

      setIsOffsetModalOpen(false);
      setSelectedSettlementReq(null);

      if (setStatusMessage) {
        setStatusMessage({
          type: "success",
          text: t("maintCrossOffsetSuccess", {
            amount: `${res.offsetAmount.toLocaleString()} ${debtReq.currency || "EUR"}`,
            targetTitle: targetOtherReq.title,
          }),
        });
      }
    } catch (err: any) {
      console.error("Cross offset execution error:", err);
      setOffsetError(err.message || t("agency_maint_toast_update_failed"));
    } finally {
      setIsExecutingOffset(false);
    }
  };

  const handleApproveSettlement = async (req: AgencyMaintenanceRequest, forceMarkPaid = false) => {
    if (isDemoMode && !isDemoVerified) {
      onRequestVerification?.();
      return;
    }
    setIsExecutingSettlementAction(true);
    try {
      const nowIso = new Date().toISOString();
      const isSelfCovered = req.declaration_intent === "self";
      const isTenantReimburse = req.paid_by === "tenant" && !isSelfCovered;
      const isLandlordAddRent = req.paid_by === "landlord" && !isSelfCovered;

      // Check if this is a payment-proof review on an already-approved debt (e.g. tenant uploaded receipt for landlord damage)
      let existingCharge: any = null;
      if (userId && userId !== "demo") {
        try {
          const { data: charges } = await supabase
            .from("maintenance_charges")
            .select("*")
            .eq("maintenance_request_id", req.id);
          if (charges && charges.length > 0) existingCharge = charges[0];
        } catch (cErr) {
          console.warn("Charge fetch warning:", cErr);
        }
      }

      const isPaymentProofConfirmation =
        req.payment_status === "pending_review" &&
        Boolean(req.invoice_pdf_url) &&
        (req.paid_by === "agency" ||
          (existingCharge &&
            existingCharge.status === "approved" &&
            existingCharge.charge_type !== "reimbursement"));

      const nextStatus =
        forceMarkPaid || isPaymentProofConfirmation
          ? "paid"
          : isTenantReimburse || isLandlordAddRent
            ? "pending_payment"
            : "paid";

      const updates: any = {
        payment_status: nextStatus,
        updated_at: nowIso,
      };
      if (nextStatus === "paid") {
        updates.settled_amount = req.cost_amount || 0;
        updates.payment_date = nowIso;
      }

      if (userId && userId !== "demo") {
        await supabase
          .from("maintenance_requests")
          .update(updates)
          .eq("id", req.id);

        try {
          if (existingCharge) {
            await supabase
              .from("maintenance_charges")
              .update({
                status: nextStatus === "paid" ? "paid" : "approved",
                ...(nextStatus === "paid" ? { settled_amount: req.cost_amount || 0, paid_at: nowIso } : {}),
                approved_by: userId,
                updated_at: nowIso,
              })
              .eq("id", existingCharge.id);
          }
        } catch (cErr) {
          console.warn("Charge update warning:", cErr);
        }

        await supabase.from("maintenance_messages").insert({
          request_id: req.id,
          sender_id: userId,
          user_id: userId,
          message: `${t("agency_maint_msg_approved")}: ${req.cost_amount || 0} ${req.currency || "EUR"}`,
          photo_url: req.invoice_pdf_url,
        });

        await supabase.from("activity_logs").insert({
          property_id: req.property_id,
          user_id: userId,
          action_type: "expense_approved",
          entity_type: "maintenance_request",
          entity_id: req.id,
          metadata: {
            ticket_number: req.ticket_number,
            amount: req.cost_amount,
            next_status: nextStatus,
          },
          created_at: nowIso,
        });
      }

      const updatedReq: AgencyMaintenanceRequest = {
        ...req,
        payment_status: nextStatus,
        ...(nextStatus === "paid" ? { settled_amount: req.cost_amount || 0, payment_date: nowIso } : {}),
      };

      if (setMaintenanceRequests) {
        setMaintenanceRequests((prev) =>
          prev.map((m) => (m.id === req.id ? updatedReq : m))
        );
      }

      if (setStatusMessage) {
        setStatusMessage({
          type: "success",
          text: t("agency_maint_approve_success"),
        });
      }
    } catch (err: any) {
      console.error("Error approving expense:", err);
      if (setStatusMessage) {
        setStatusMessage({
          type: "error",
          text: err.message || t("agency_panel_msg_save_error"),
        });
      }
    } finally {
      setIsExecutingSettlementAction(false);
    }
  };

  const handleRejectSettlement = async () => {
    if (isDemoMode && !isDemoVerified) {
      onRequestVerification?.();
      return;
    }
    if (!rejectingSettlementReq || !settlementRejectReason.trim()) return;
    setIsExecutingSettlementAction(true);
    try {
      const nowIso = new Date().toISOString();
      const reason = settlementRejectReason.trim();

      // Match Flutter _handleRejectExpense: if rejecting a payment proof submission on an already-approved debt,
      // revert to pending_payment + charge.status = approved so the debt stays alive for re-submission.
      let existingCharge: any = null;
      if (userId && userId !== "demo") {
        try {
          const { data: charges } = await supabase
            .from("maintenance_charges")
            .select("*")
            .eq("maintenance_request_id", rejectingSettlementReq.id);
          if (charges && charges.length > 0) existingCharge = charges[0];
        } catch (_) { }
      }

      const isPaymentReceiptRejection =
        rejectingSettlementReq.payment_status === "pending_review" &&
        Boolean(rejectingSettlementReq.invoice_pdf_url) &&
        (rejectingSettlementReq.paid_by === "agency" ||
          (existingCharge &&
            existingCharge.status === "approved" &&
            existingCharge.charge_type !== "reimbursement"));

      const targetStatus = isPaymentReceiptRejection ? "pending_payment" : "rejected";
      const targetChargeStatus = isPaymentReceiptRejection ? "approved" : "rejected";

      if (userId && userId !== "demo") {
        await supabase
          .from("maintenance_requests")
          .update({
            payment_status: targetStatus,
            rejection_reason: reason,
            ...(isPaymentReceiptRejection ? { invoice_pdf_url: null } : {}),
            updated_at: nowIso,
          })
          .eq("id", rejectingSettlementReq.id);

        try {
          await supabase
            .from("maintenance_charges")
            .update({
              status: targetChargeStatus,
              ...(isPaymentReceiptRejection ? { receipt_url: null } : {}),
              updated_at: nowIso,
            })
            .eq("maintenance_request_id", rejectingSettlementReq.id);
        } catch (cErr) {
          console.warn("Charge update warning:", cErr);
        }

        await supabase.from("maintenance_messages").insert({
          request_id: rejectingSettlementReq.id,
          sender_id: userId,
          user_id: userId,
          message: `${t("rejectExpenseTitle")}: ${reason}`,
        });

        await supabase.from("activity_logs").insert({
          property_id: rejectingSettlementReq.property_id,
          user_id: userId,
          action_type: "expense_rejected",
          entity_type: "maintenance_request",
          entity_id: rejectingSettlementReq.id,
          metadata: {
            ticket_number: rejectingSettlementReq.ticket_number,
            rejection_reason: reason,
          },
          created_at: nowIso,
        });
      }

      const updatedReq: AgencyMaintenanceRequest = {
        ...rejectingSettlementReq,
        payment_status: targetStatus,
        rejection_reason: reason,
        ...(isPaymentReceiptRejection ? { invoice_pdf_url: null } : {}),
      };

      if (setMaintenanceRequests) {
        setMaintenanceRequests((prev) =>
          prev.map((m) => (m.id === rejectingSettlementReq.id ? updatedReq : m))
        );
      }

      setRejectingSettlementReq(null);
      setSettlementRejectReason("");

      if (setStatusMessage) {
        setStatusMessage({
          type: "success",
          text: t("agency_maint_reject_success"),
        });
      }
    } catch (err: any) {
      console.error("Error rejecting expense:", err);
      if (setStatusMessage) {
        setStatusMessage({
          type: "error",
          text: err.message || t("agency_panel_msg_save_error"),
        });
      }
    } finally {
      setIsExecutingSettlementAction(false);
    }
  };

  const handleConfirmDirectSettlement = async () => {
    if (isDemoMode && !isDemoVerified) {
      onRequestVerification?.();
      return;
    }
    if (!settlementOptionsReq || !selectedPropertyDrawer) return;
    setIsExecutingDirectSettlement(true);
    try {
      const nowIso = new Date().toISOString();
      let uploadedUrl = settlementOptionsReq.invoice_pdf_url;

      if (directSettlementFile && userId && userId !== "demo") {
        const ext = directSettlementFile.name.split(".").pop() || "png";
        const path = `${userId}/${selectedPropertyDrawer.id}_${settlementOptionsReq.id}_${Date.now()}.${ext}`;
        try {
          const { error: upErr } = await supabase.storage
            .from("invoices")
            .upload(path, directSettlementFile);
          if (!upErr) {
            const { data: pubData } = supabase.storage.from("invoices").getPublicUrl(path);
            uploadedUrl = pubData?.publicUrl || uploadedUrl;
          }
        } catch (e) {
          console.warn("Storage upload fallback:", e);
        }
      } else if (directSettlementMethod === "cash" && !uploadedUrl) {
        uploadedUrl = "cash_settlement";
      }

      const costAmt = settlementOptionsReq.cost_amount || 0;
      const cur = settlementOptionsReq.currency || selectedPropertyDrawer.currency || "EUR";

      if (userId && userId !== "demo") {
        // 1. Update maintenance request
        await supabase
          .from("maintenance_requests")
          .update({
            settled_amount: costAmt,
            payment_status: "paid",
            payment_date: nowIso,
            invoice_pdf_url: uploadedUrl,
            updated_at: nowIso,
          })
          .eq("id", settlementOptionsReq.id);

        // 2. Update charges
        try {
          await supabase
            .from("maintenance_charges")
            .update({
              settled_amount: costAmt,
              status: "paid",
              settlement_method: directSettlementMethod === "cash" ? "cash" : "separate_payment",
              updated_at: nowIso,
            })
            .eq("maintenance_request_id", settlementOptionsReq.id);
        } catch (cErr) {
          console.warn("Charge update warning:", cErr);
        }

        // 3. Post chat message
        const methodLabel = directSettlementMethod === "cash"
          ? t("settleOptCashCollected")
          : t("settleOptBankTransferCollected");
        const noteSuffix = directSettlementNote.trim() ? `\n${directSettlementNote.trim()}` : "";
        await supabase.from("maintenance_messages").insert({
          request_id: settlementOptionsReq.id,
          sender_id: userId,
          user_id: userId,
          message: `${settlementOptionsReq.ticket_number}: ${costAmt.toLocaleString()} ${cur} (${methodLabel}) - ${t("collectionConfirmedAndSettled")}${noteSuffix}`,
          photo_url: uploadedUrl && uploadedUrl !== "cash_settlement" ? uploadedUrl : null,
        });

        // 4. Log activity
        await supabase.from("activity_logs").insert({
          property_id: selectedPropertyDrawer.id,
          user_id: userId,
          action_type: "maintenance_settled_direct",
          entity_type: "maintenance_request",
          entity_id: settlementOptionsReq.id,
          metadata: {
            method: directSettlementMethod,
            amount: costAmt,
            currency: cur,
            note: directSettlementNote.trim(),
            ticket_number: settlementOptionsReq.ticket_number,
          },
          created_at: nowIso,
        });
      }

      // Update local state
      const updatedReq: AgencyMaintenanceRequest = {
        ...settlementOptionsReq,
        settled_amount: costAmt,
        payment_status: "paid",
        payment_date: nowIso,
        invoice_pdf_url: uploadedUrl,
      };

      if (setMaintenanceRequests) {
        setMaintenanceRequests((prev) =>
          prev.map((m) => (m.id === settlementOptionsReq.id ? updatedReq : m))
        );
      }

      setIsDirectSettlementModalOpen(false);
      setSettlementOptionsReq(null);
      setDirectSettlementNote("");
      setDirectSettlementFile(null);

      if (setStatusMessage) {
        setStatusMessage({
          type: "success",
          text: t("collectionConfirmedAndSettled"),
        });
      }
    } catch (err: any) {
      console.error("Direct settlement error:", err);
      if (setStatusMessage) {
        setStatusMessage({
          type: "error",
          text: err.message || t("agency_panel_msg_save_error"),
        });
      }
    } finally {
      setIsExecutingDirectSettlement(false);
    }
  };

  const handleExecuteCreateContract = async (p: AgencyManagedProperty) => {
    if (isDemoMode && !isDemoVerified) {
      onRequestVerification?.();
      return;
    }
    const rentNum = parseFloat(newContractRent.replace(",", ".")) || 0;
    const depNum = parseFloat(newContractDeposit.replace(",", ".")) || rentNum;
    const dueDayNum = parseInt(newContractDueDay) || 1;

    if (!newContractTenantName.trim()) {
      setStatusMessage({ type: "error", text: t("fieldRequired") });
      return;
    }
    if (rentNum <= 0) {
      setStatusMessage({ type: "error", text: t("agency_rent_payment_amount_invalid") });
      return;
    }
    if (!newContractStartDate || !newContractEndDate) {
      setStatusMessage({ type: "error", text: t("fieldRequired") });
      return;
    }

    // Scenario B: If recipient email is NOT changed and there is an existing contract, directly update the contract in place
    if (isUpdatingExistingContract && existingContractTarget) {
      setIsCreatingContract(true);
      try {
        const cleanTenantName = newContractTenantName.trim();
        const cleanTenantPhone = newContractTenantPhone.trim() || null;
        const cleanTenantEmail =
          newContractTenantEmail.trim().toLowerCase() ||
          existingContractTarget.invitee_email?.trim().toLowerCase() ||
          null;
        const cleanTenantIdNum = newContractTenantIdNumber.trim() || null;
        const cleanTenantNotes = newContractTenantNotes.trim() || null;
        const cleanSecContacts = newContractSecondaryContacts.filter(
          (c) => c.full_name.trim() || c.relationship.trim() || c.phone?.trim() || c.email?.trim()
        );

        if (hasSupabaseSession) {
          const { data, error } = await supabase
            .from("contracts")
            .update({
              monthly_rent: rentNum,
              deposit_amount: depNum,
              currency: newContractCurrency,
              deposit_currency: newContractDepositCurrency || newContractCurrency,
              due_day: dueDayNum,
              start_date: newContractStartDate,
              end_date: newContractEndDate,
              invitee_email: cleanTenantEmail,
              tenant_name: cleanTenantName,
              tenant_phone: cleanTenantPhone,
              tenant_id_number: cleanTenantIdNum,
              tenant_notes: cleanTenantNotes,
              tenant_id_document_url: newContractTenantIdDocUrl,
              tenant_secondary_contacts: cleanSecContacts,
              expenses_config: newContractExpenses,
              contract_url: newContractMainDocUrl,
              additional_documents: newContractAdditionalDocs,
            })
            .eq("id", existingContractTarget.id)
            .select()
            .single();

          if (error) throw error;

          // Keep property defaults synced
          try {
            await supabase.from("properties").update({
              default_monthly_rent: rentNum,
              default_deposit_amount: depNum,
              currency: newContractCurrency,
              default_deposit_currency: newContractDepositCurrency || newContractCurrency,
              default_due_day: dueDayNum,
              expenses_template: newContractExpenses,
              tenant_name: cleanTenantName,
            }).eq("id", p.id);
          } catch (_) { }

          // Auto-generate or update scheduled rent payments
          try {
            await supabase.rpc("generate_missing_rent_payments", { p_property_id: p.id });
          } catch (_) { }

          // Activity log
          try {
            await supabase.from("activity_logs").insert({
              property_id: p.id,
              user_id: userId,
              type: "contract_updated_by_agency",
              metadata: {
                contract_id: existingContractTarget.id,
                monthly_rent: rentNum,
                start_date: newContractStartDate,
                end_date: newContractEndDate,
              },
            });
          } catch (_) { }

          setContracts((prev) =>
            prev.map((c) =>
              c.id === existingContractTarget.id
                ? {
                  ...c,
                  ...(data || {}),
                  monthly_rent: rentNum,
                  deposit_amount: depNum,
                  currency: newContractCurrency,
                  deposit_currency: newContractDepositCurrency || newContractCurrency,
                  due_day: dueDayNum,
                  start_date: newContractStartDate,
                  end_date: newContractEndDate,
                  invitee_email: cleanTenantEmail,
                  tenant_name: cleanTenantName,
                  tenant_phone: cleanTenantPhone,
                  tenant_id_number: cleanTenantIdNum,
                  tenant_notes: cleanTenantNotes,
                  tenant_id_document_url: newContractTenantIdDocUrl,
                  tenant_secondary_contacts: cleanSecContacts,
                  expenses_config: newContractExpenses,
                  contract_url: newContractMainDocUrl,
                  additional_documents: newContractAdditionalDocs,
                }
                : c
            )
          );
        } else {
          // Demo mode
          setContracts((prev) => {
            const next = prev.map((c) =>
              c.id === existingContractTarget.id
                ? {
                  ...c,
                  monthly_rent: rentNum,
                  deposit_amount: depNum,
                  currency: newContractCurrency,
                  deposit_currency: newContractDepositCurrency || newContractCurrency,
                  due_day: dueDayNum,
                  start_date: newContractStartDate,
                  end_date: newContractEndDate,
                  invitee_email: cleanTenantEmail,
                  tenant_name: cleanTenantName,
                  tenant_phone: cleanTenantPhone,
                  tenant_id_number: cleanTenantIdNum,
                  tenant_notes: cleanTenantNotes,
                  tenant_id_document_url: newContractTenantIdDocUrl,
                  tenant_secondary_contacts: cleanSecContacts,
                  expenses_config: newContractExpenses,
                  contract_url: newContractMainDocUrl,
                  additional_documents: newContractAdditionalDocs,
                }
                : c
            );
            if (typeof window !== "undefined" && (isDemoMode || !hasSupabaseSession)) {
              try {
                localStorage.setItem("stanomer_agency_contracts_demo", JSON.stringify(next));
              } catch { }
            }
            return next;
          });
        }

        // Sync managed properties & active drawer & payments in memory so the updated tenant name/phone appear immediately
        setManagedProperties((prev) => {
          const next = prev.map((item) =>
            item.id === p.id
              ? {
                ...item,
                default_monthly_rent: rentNum,
                default_deposit_amount: depNum,
                currency: newContractCurrency,
                default_deposit_currency: newContractDepositCurrency || newContractCurrency,
                default_due_day: dueDayNum,
                expenses_template: newContractExpenses,
                active_tenant_name: cleanTenantName,
                active_tenant_phone: cleanTenantPhone,
                contract_end_date: newContractEndDate,
              }
              : item
          );
          if (typeof window !== "undefined" && (isDemoMode || !hasSupabaseSession)) {
            try {
              localStorage.setItem("stanomer_agency_managed_props_demo", JSON.stringify(next));
            } catch { }
          }
          return next;
        });

        setSelectedPropertyDrawer((prev) =>
          prev && prev.id === p.id
            ? {
              ...prev,
              default_monthly_rent: rentNum,
              default_deposit_amount: depNum,
              currency: newContractCurrency,
              default_deposit_currency: newContractDepositCurrency || newContractCurrency,
              default_due_day: dueDayNum,
              expenses_template: newContractExpenses,
              active_tenant_name: cleanTenantName,
              active_tenant_phone: cleanTenantPhone,
              contract_end_date: newContractEndDate,
            }
            : prev
        );

        setPayments((prev) =>
          prev.map((pay) =>
            pay.property_id === p.id
              ? {
                ...pay,
                tenant_name: cleanTenantName,
                tenant_phone: cleanTenantPhone || undefined,
              }
              : pay
          )
        );

        setStatusMessage({
          type: "success",
          text: t("agency_contract_updated_success"),
        });
        setIsNewContractModalOpen(false);
        setNewContractProperty(null);
        setExistingContractTarget(null);
      } catch (err: any) {
        console.error("Error updating contract:", err);
        setStatusMessage({
          type: "error",
          text: err.message || t("agency_panel_msg_save_error"),
        });
      } finally {
        setIsCreatingContract(false);
      }
      return;
    }

    setIsCreatingContract(true);
    try {
      const generatedToken = `tenant_${Date.now()}_${Math.floor(Math.random() * 99999)}`;
      const newContractId = `contract-new-${Date.now()}`;
      let createdContractData: any = null;
      const cleanSecContacts = newContractSecondaryContacts.filter(
        (c) => c.full_name.trim() || c.relationship.trim() || c.phone?.trim() || c.email?.trim()
      );

      if (hasSupabaseSession) {
        const { data, error } = await supabase
          .from("contracts")
          .insert({
            property_id: p.id,
            landlord_id: p.landlord_id || userId,
            agency_id: userId,
            inviter_name: agencyName || "Acente",
            invitee_email: newContractTenantEmail.trim().toLowerCase() || null,
            token: generatedToken,
            monthly_rent: rentNum,
            deposit_amount: depNum,
            currency: newContractCurrency,
            deposit_currency: newContractDepositCurrency || newContractCurrency,
            due_day: dueDayNum,
            start_date: newContractStartDate,
            end_date: newContractEndDate,
            status: "pending",
            expenses_config: newContractExpenses.length > 0 ? newContractExpenses : (p.expenses_template || []),
            tenant_name: newContractTenantName.trim(),
            tenant_phone: newContractTenantPhone.trim() || null,
            tenant_id_number: newContractTenantIdNumber.trim() || null,
            tenant_notes: newContractTenantNotes.trim() || null,
            tenant_id_document_url: newContractTenantIdDocUrl,
            tenant_secondary_contacts: cleanSecContacts,
            contract_url: newContractMainDocUrl,
            additional_documents: newContractAdditionalDocs,
          })
          .select()
          .single();

        if (error) throw error;
        createdContractData = data;

        // Keep property tenant_name synced (and clear old tenant_id if tenant changed)
        try {
          await supabase.from("properties").update({
            tenant_name: newContractTenantName.trim(),
            ...(isTenantInfoChanged ? { tenant_id: null } : {}),
          }).eq("id", p.id);
        } catch (_) { }

        // If tenant changed, supersede previous active/pending contracts and cancel pending invitations
        if (isTenantInfoChanged) {
          try {
            await supabase
              .from("contracts")
              .update({
                status: "terminated",
                termination_date: newContractStartDate,
                termination_approved: true,
              })
              .eq("property_id", p.id)
              .neq("id", data.id)
              .in("status", ["active", "pending"]);
          } catch (_) { }

          try {
            await supabase
              .from("invitations")
              .update({ status: "rejected" })
              .eq("property_id", p.id)
              .eq("target_role", "tenant")
              .eq("status", "pending");
          } catch (_) { }
        }

        // Note: For tenant contracts, we do NOT insert a duplicate row into public.invitations!
        // Flutter's pendingInvitesForUserProvider & InvitationAcceptScreen expect tenant invites
        // to come directly from public.contracts (type = 'contract'). Inserting into public.invitations
        // causes get_invite_details to return type = 'invitation' without active_contract (_contract == null -> "Invitation not found or expired").
        if (newContractTenantEmail.trim()) {
          const cleanEmail = newContractTenantEmail.trim().toLowerCase();

          // Trigger automated tenant invitation email via Brevo
          try {
            await fetch("/api/send-tenant-invite", {
              method: "POST",
              headers: { "Content-Type": "application/json" },
              body: JSON.stringify({
                propertyId: p.id,
                propertyAddress: p.address || p.title,
                tenantEmail: cleanEmail,
                tenantName: newContractTenantName.trim(),
                agencyName: agencyName || "Stanomer",
                agencyEmail: agencyEmail || "info@stanomer.online",
                token: generatedToken,
                monthlyRent: rentNum,
                currency: newContractCurrency,
                depositAmount: depNum,
                startDate: newContractStartDate,
                inviterId: userId,
                language: (lang || "sr").toLowerCase(),
              }),
            });
          } catch (emailErr) {
            console.warn("Could not send automated tenant invite email:", emailErr);
          }
        }

        // Auto-generate scheduled rent payment records
        try {
          await supabase.rpc("generate_missing_rent_payments", { p_property_id: p.id });
        } catch (_) { }

        // Fetch fresh rent payments for this property to immediately update financials
        try {
          const { data: propPays } = await supabase
            .from("rent_payments")
            .select("*")
            .eq("property_id", p.id)
            .order("due_date", { ascending: false });

          if (propPays && propPays.length > 0) {
            setPayments((prev) => {
              const others = prev.filter((item) => item.property_id !== p.id);
              const mapped: AgencyRentPayment[] = propPays.map((pay: any) => ({
                id: pay.id,
                property_id: pay.property_id,
                contract_id: pay.contract_id,
                tenant_id: pay.tenant_id,
                property_title: p.title,
                property_address: p.address,
                tenant_name: newContractTenantName.trim(),
                tenant_phone: newContractTenantPhone.trim() || null,
                title: pay.title || "Kira",
                amount: Number(pay.amount || 0),
                currency: pay.currency || p.currency || "EUR",
                due_date: pay.due_date,
                status: pay.status || "pending",
                paid_at: pay.paid_at || null,
                payment_method: pay.payment_method || null,
                is_maintenance: Boolean(pay.is_maintenance),
                declared_at: pay.declared_at || null,
                receipt_url: pay.receipt_url || null,
                owner_note: pay.owner_note || null,
                rejection_reason: pay.rejection_reason || null,
                created_at: pay.created_at || new Date().toISOString(),
              }));
              return [...mapped, ...others];
            });
          }
        } catch (_) { }

        try {
          await supabase.from("activity_logs").insert({
            property_id: p.id,
            user_id: userId,
            type: "contract_created_by_agency",
            metadata: {
              contract_id: data.id,
              tenant_name: newContractTenantName.trim(),
              monthly_rent: rentNum,
            },
          });
        } catch (_) { }

        if (data) {
          setContracts((prev) => {
            const updatedPrev = isTenantInfoChanged
              ? prev.map((c) =>
                c.property_id === p.id &&
                  c.id !== data.id &&
                  (c.status === "active" || c.status === "pending")
                  ? {
                    ...c,
                    status: "terminated" as const,
                    termination_date: newContractStartDate,
                    termination_approved: true,
                  }
                  : c
              )
              : prev;
            return [data as AgencyContract, ...updatedPrev];
          });
        }
      } else {
        const demoContract: AgencyContract = {
          id: newContractId,
          property_id: p.id,
          landlord_id: p.landlord_id || "demo-landlord",
          tenant_id: "demo-tenant-new",
          agency_id: "demo-agency",
          invitee_email: newContractTenantEmail.trim() || null,
          monthly_rent: rentNum,
          deposit_amount: depNum,
          currency: newContractCurrency,
          deposit_currency: newContractDepositCurrency || newContractCurrency,
          due_day: dueDayNum,
          start_date: newContractStartDate,
          end_date: newContractEndDate,
          status: "active",
          tenant_name: newContractTenantName.trim(),
          tenant_phone: newContractTenantPhone.trim() || null,
          tenant_id_number: newContractTenantIdNumber.trim() || null,
          tenant_notes: newContractTenantNotes.trim() || null,
          tenant_id_document_url: newContractTenantIdDocUrl,
          tenant_secondary_contacts: cleanSecContacts,
          expenses_config: newContractExpenses,
          contract_url: newContractMainDocUrl,
          additional_documents: newContractAdditionalDocs,
          created_at: new Date().toISOString(),
        };
        setContracts((prev) => {
          const updatedPrev = prev.map((c) =>
            c.property_id === p.id && (c.status === "active" || c.status === "pending")
              ? {
                ...c,
                status: "terminated" as const,
                termination_date: newContractStartDate,
                termination_approved: true,
              }
              : c
          );
          const next = [demoContract, ...updatedPrev];
          if (typeof window !== "undefined" && (isDemoMode || !hasSupabaseSession)) {
            try {
              localStorage.setItem("stanomer_agency_contracts_demo", JSON.stringify(next));
            } catch { }
          }
          return next;
        });
      }

      const effectiveContractId = createdContractData ? createdContractData.id : newContractId;

      setManagedProperties((prev) => {
        const next = prev.map((item) =>
          item.id === p.id
            ? {
              ...item,
              is_occupied: true,
              active_tenant_name: newContractTenantName.trim(),
              active_tenant_phone: newContractTenantPhone.trim() || null,
              active_contract_id: effectiveContractId,
              contract_end_date: newContractEndDate,
            }
            : item
        );
        if (typeof window !== "undefined" && (isDemoMode || !hasSupabaseSession)) {
          try {
            localStorage.setItem("stanomer_agency_managed_props_demo", JSON.stringify(next));
          } catch { }
        }
        return next;
      });

      setSelectedPropertyDrawer((prev) =>
        prev && prev.id === p.id
          ? {
            ...prev,
            is_occupied: true,
            active_tenant_name: newContractTenantName.trim(),
            active_tenant_phone: newContractTenantPhone.trim() || null,
            active_contract_id: effectiveContractId,
            contract_end_date: newContractEndDate,
          }
          : prev
      );

      setIsNewContractModalOpen(false);
      setNewContractProperty(null);
      setStatusMessage({
        type: "success",
        text: t("agency_contract_created_success"),
      });

      // Lifecycle Scenario #11: New lease contract (Scenario A) -> realize active EOP or offer new realized EOP
      if (onOpenEopModal) {
        const activePropEop = eopRecords.find(
          (r) =>
            (r.property_id === p.id || (p.last_listing_id && r.listing_id === p.last_listing_id)) &&
            r.status === "active"
        );
        const alreadyLinkedToContract = eopRecords.some(
          (r) => r.lease_contract_id === effectiveContractId
        );
        if (activePropEop) {
          onOpenEopModal({
            mode: "realize",
            existingRecord: activePropEop,
            property_id: p.id,
            listing_id: p.last_listing_id || activePropEop.listing_id || null,
            lease_contract_id: effectiveContractId,
            agreed_price: rentNum,
            realized_at: newContractStartDate || new Date().toISOString().split("T")[0],
          });
        } else if (!alreadyLinkedToContract) {
          const specs = [
            p.area_sqm ? `${p.area_sqm} m²` : null,
            p.room_count || null,
            p.floor ? `${p.floor}` : null,
          ].filter(Boolean).join(", ");
          const addr = [p.address, p.unit_number ? `#${p.unit_number}` : null, p.city]
            .filter(Boolean)
            .join(", ");
          onOpenEopModal({
            mode: "create",
            status: "realized",
            property_id: p.id,
            listing_id: p.last_listing_id || null,
            lease_contract_id: effectiveContractId,
            transaction_type: "izdavanje",
            client_role: "landlord",
            client_name: p.landlord_name || "",
            client_phone: p.landlord_phone || "",
            client_email: p.landlord_email || "",
            property_type: p.property_type || "apartment",
            property_address: addr || p.title || "",
            property_specs: specs,
            asking_price: p.default_monthly_rent || rentNum,
            agreed_price: rentNum,
            currency: newContractCurrency || p.currency || "EUR",
            realized_at: newContractStartDate || new Date().toISOString().split("T")[0],
          });
        }
      }
    } catch (err: any) {
      console.error("Create contract error:", err);
      setStatusMessage({
        type: "error",
        text: err?.message || t("agency_panel_msg_save_error"),
      });
    } finally {
      setIsCreatingContract(false);
    }
  };

  // Upload helper for Contract PDF / Tenant ID Document / Additional Documents (Flutter SSOT Parity)
  const uploadContractOrTenantFile = async (
    file: File,
    folderPrefix: string,
    propId: string
  ): Promise<string> => {
    const cleanName = file.name.replace(/[^a-zA-Z0-9.\-_]/g, "").trim() || "document.pdf";
    const path = `${folderPrefix}/${propId}/${Date.now()}_${cleanName}`;
    if (hasSupabaseSession) {
      for (const bucket of ["contracts", "rent-receipts", "documents"]) {
        try {
          const { data: upData, error: upErr } = await supabase.storage
            .from(bucket)
            .upload(path, file, { upsert: true });
          if (!upErr && upData) {
            const { data: pubData } = supabase.storage.from(bucket).getPublicUrl(upData.path);
            if (pubData?.publicUrl) return pubData.publicUrl;
          }
        } catch (_) { }
      }
    }
    return URL.createObjectURL(file);
  };

  const openEditPropertySpecsModal = (p: AgencyManagedProperty) => {
    if (isDemoMode && !isDemoVerified) {
      onRequestVerification?.();
      return;
    }
    setEditingSpecsProperty(p);
    setSpecTitle(p.title || "");
    setSpecAddress(p.address || "");
    setSpecCity(p.city || "Beograd");
    setSpecPropertyType(p.property_type || "apartment");
    setSpecUnitNumber(p.unit_number || "");
    setSpecRoomCount(p.room_count || "2.0");
    setSpecAreaSqm(p.area_sqm != null ? String(p.area_sqm) : "");
    setSpecFloor(p.floor || "1");
    setSpecTotalFloors(p.total_floors != null ? String(p.total_floors) : "");
    setSpecFurnishing(p.furnishing || "furnished");
    setSpecHeatingType(p.heating_type || "cg");
    setSpecAmenities(Array.isArray(p.amenities) ? [...p.amenities] : []);
    setSpecDescription(p.description || "");
    const rentStr = p.default_monthly_rent != null ? String(p.default_monthly_rent) : "600";
    setSpecDefaultRent(rentStr);
    setSpecDefaultDeposit(
      p.default_deposit_amount != null ? String(p.default_deposit_amount) : rentStr
    );
    setSpecCurrency(p.currency || "EUR");
    setSpecDefaultDepositCurrency(p.default_deposit_currency || p.currency || "EUR");
    setSpecDefaultDueDay(p.default_due_day != null ? String(p.default_due_day) : "1");
    setSpecExpensesTemplate(
      Array.isArray(p.expenses_template) && p.expenses_template.length > 0
        ? p.expenses_template.map((e) => ({
          name: e.name || (e as any).title || "Infostan",
          receiver: e.receiver || "owner",
          amount: Number(e.amount) || 0,
          payment_method: e.payment_method || "bank_transfer",
        }))
        : DEFAULT_STANDARD_EXPENSES.map((e) => ({ ...e }))
    );
    setSpecCustomExpenseInput("");
  };

  const handleSavePropertySpecs = async () => {
    if (!editingSpecsProperty) return;
    if (!specTitle.trim() || !specAddress.trim()) {
      setStatusMessage({ type: "error", text: t("fieldRequired") });
      return;
    }
    setIsSavingPropertySpecs(true);
    try {
      const rentNum = parseFloat(specDefaultRent.replace(",", ".")) || 0;
      const depNum = parseFloat(specDefaultDeposit.replace(",", ".")) || rentNum;
      const dueDayNum = parseInt(specDefaultDueDay) || 1;
      const areaNum = specAreaSqm.trim() ? parseFloat(specAreaSqm.replace(",", ".")) || null : null;
      const totalFloorsNum = specTotalFloors.trim() ? parseInt(specTotalFloors) || null : null;

      if (hasSupabaseSession) {
        const { error } = await supabase
          .from("properties")
          .update({
            title: specTitle.trim(),
            name: specTitle.trim(),
            address: specAddress.trim(),
            city: specCity.trim() || "Beograd",
            property_type: specPropertyType,
            unit_number: specUnitNumber.trim() || null,
            room_count: specRoomCount || null,
            area_sqm: areaNum,
            floor: specFloor || null,
            total_floors: totalFloorsNum,
            furnishing: specFurnishing || null,
            heating_type: specHeatingType || null,
            amenities: specAmenities,
            description: specDescription.trim() || null,
            is_detailed: true,
            default_monthly_rent: rentNum,
            default_deposit_amount: depNum,
            currency: specCurrency,
            default_deposit_currency: specDefaultDepositCurrency || specCurrency,
            default_due_day: dueDayNum,
            expenses_template: specExpensesTemplate,
          })
          .eq("id", editingSpecsProperty.id);

        if (error) throw error;
      }

      const updatedProp: AgencyManagedProperty = {
        ...editingSpecsProperty,
        title: specTitle.trim(),
        address: specAddress.trim(),
        city: specCity.trim() || "Beograd",
        property_type: specPropertyType,
        unit_number: specUnitNumber.trim() || null,
        room_count: specRoomCount || null,
        area_sqm: areaNum,
        floor: specFloor || null,
        total_floors: totalFloorsNum,
        furnishing: specFurnishing || null,
        heating_type: specHeatingType || null,
        amenities: specAmenities,
        description: specDescription.trim() || null,
        is_detailed: true,
        default_monthly_rent: rentNum,
        default_deposit_amount: depNum,
        currency: specCurrency,
        default_deposit_currency: specDefaultDepositCurrency || specCurrency,
        default_due_day: dueDayNum,
        expenses_template: specExpensesTemplate,
      };

      setManagedProperties((prev) =>
        prev.map((item) => (item.id === updatedProp.id ? updatedProp : item))
      );
      setSelectedPropertyDrawer((prev) =>
        prev && prev.id === updatedProp.id ? updatedProp : prev
      );
      setEditingSpecsProperty(null);
      setStatusMessage({
        type: "success",
        text: t("agency_prop_specs_saved_success"),
      });
    } catch (err: any) {
      console.error("Error saving property specs:", err);
      setStatusMessage({
        type: "error",
        text: err?.message || t("agency_panel_msg_save_error"),
      });
    } finally {
      setIsSavingPropertySpecs(false);
    }
  };

  const openMarkPaidModal = (pay: AgencyRentPayment) => {
    if (isDemoMode && !isDemoVerified) {
      onRequestVerification?.();
      return;
    }
    setMarkPaidPayment(pay);
    setMarkPaidMethod((pay.payment_method as any) || "bank_transfer");
    setMarkPaidDate(new Date().toISOString().split("T")[0]);
    setMarkPaidNote("");
    setIsMarkPaidModalOpen(true);
  };

  const handleExecuteMarkPaid = async () => {
    if (isDemoMode && !isDemoVerified) {
      onRequestVerification?.();
      return;
    }
    if (!markPaidPayment) return;
    setIsSubmittingMarkPaid(true);
    try {
      if (hasSupabaseSession) {
        const { error } = await supabase
          .from("rent_payments")
          .update({
            status: "paid",
            paid_at: markPaidDate || new Date().toISOString(),
            payment_method: markPaidMethod,
            owner_note: markPaidNote.trim() || null,
          })
          .eq("id", markPaidPayment.id);
        if (error) throw error;

        try {
          const isRent = (markPaidPayment.title || "").toLowerCase().includes("kira") || (markPaidPayment.title || "").toLowerCase().includes("rent") || (markPaidPayment.title || "").toLowerCase().includes("kirij");
          const logType = isRent ? "rent_approved" : "payment_toggle";
          const { data: insertedLog } = await supabase
            .from("activity_logs")
            .insert({
              property_id: markPaidPayment.property_id,
              user_id: userId,
              type: logType,
              metadata: {
                payment_id: markPaidPayment.id,
                title: markPaidPayment.title,
                amount: markPaidPayment.amount,
                currency: markPaidPayment.currency,
                due_date: markPaidPayment.due_date,
                payment_method: markPaidMethod,
                paid: true,
                note: markPaidNote.trim() || undefined,
              },
            })
            .select()
            .single();
          if (insertedLog) {
            setDrawerActivityLogs((prev) => [insertedLog, ...prev]);
          }
        } catch (_) { }
      } else {
        const isRent = (markPaidPayment.title || "").toLowerCase().includes("kira") || (markPaidPayment.title || "").toLowerCase().includes("rent") || (markPaidPayment.title || "").toLowerCase().includes("kirij");
        const demoLog = {
          id: `log-${Date.now()}`,
          property_id: markPaidPayment.property_id,
          user_id: userId || "demo",
          type: isRent ? "rent_approved" : "payment_toggle",
          metadata: {
            payment_id: markPaidPayment.id,
            title: markPaidPayment.title,
            amount: markPaidPayment.amount,
            currency: markPaidPayment.currency,
            due_date: markPaidPayment.due_date,
            payment_method: markPaidMethod,
            paid: true,
            note: markPaidNote.trim() || undefined,
          },
          created_at: new Date().toISOString(),
        };
        setDrawerActivityLogs((prev) => [demoLog, ...prev]);
      }

      setPayments((prev) =>
        prev.map((item) =>
          item.id === markPaidPayment.id
            ? {
              ...item,
              status: "paid",
              paid_at: markPaidDate || new Date().toISOString(),
              payment_method: markPaidMethod,
              owner_note: markPaidNote.trim() || null,
              dispute_reason: null,
            }
            : item
        )
      );

      setIsMarkPaidModalOpen(false);
      setStatusMessage({
        type: "success",
        text: t("agency_payments_paid_success"),
      });
    } catch (err) {
      console.error("Mark paid error:", err);
      setStatusMessage({
        type: "error",
        text: t("agency_panel_msg_save_error"),
      });
    } finally {
      setIsSubmittingMarkPaid(false);
    }
  };

  const openBulkMarkPaidModal = () => {
    if (isDemoMode && !isDemoVerified) {
      onRequestVerification?.();
      return;
    }
    const selectedList = payments.filter((p) => selectedPaymentIds.has(p.id));
    const hasCash = selectedList.some((p) => p.payment_method === "cash");
    setBulkMarkPaidMethod(hasCash ? "cash" : "bank_transfer");
    setBulkMarkPaidDate(new Date().toISOString().split("T")[0]);
    setBulkMarkPaidNote("");
    setBulkReceiptFile(null);
    setBulkReceiptFileName("");
    setBulkReceiptFileUrl(null);
    setIsBulkMarkPaidModalOpen(true);
  };

  const handleExecuteBulkApprove = async (selectedList: AgencyRentPayment[]) => {
    if (isDemoMode && !isDemoVerified) {
      onRequestVerification?.();
      return;
    }
    if (selectedList.length === 0) return;
    const paymentIds = selectedList.map((p) => p.id);
    try {
      if (hasSupabaseSession) {
        const { error } = await supabase
          .from("rent_payments")
          .update({
            status: "paid",
            paid_at: new Date().toISOString(),
          })
          .in("id", paymentIds);
        if (error) throw error;

        try {
          const logsToInsert = selectedList.map((p) => {
            const isRent = (p.title || "").toLowerCase().includes("kira") || (p.title || "").toLowerCase().includes("rent") || (p.title || "").toLowerCase().includes("kirij");
            return {
              property_id: p.property_id,
              user_id: userId,
              type: isRent ? "rent_approved" : "payment_toggle",
              metadata: {
                payment_id: p.id,
                title: p.title,
                amount: p.amount,
                currency: p.currency,
                due_date: p.due_date,
                paid: true,
              },
            };
          });
          if (logsToInsert.length > 0) {
            const { data: insertedLogs } = await supabase
              .from("activity_logs")
              .insert(logsToInsert)
              .select();
            if (insertedLogs && insertedLogs.length > 0) {
              setDrawerActivityLogs((prev) => [...insertedLogs, ...prev]);
            }
          }
        } catch (_) { }
      }

      setPayments((prev) =>
        prev.map((item) =>
          paymentIds.includes(item.id)
            ? { ...item, status: "paid", paid_at: new Date().toISOString(), dispute_reason: null }
            : item
        )
      );

      clearSelectedPayments();
      setStatusMessage({
        type: "success",
        text: t("agency_bulk_approved_success", { count: String(paymentIds.length) }),
      });
    } catch (err: any) {
      console.error("Bulk approve error:", err);
      setStatusMessage({
        type: "error",
        text: err?.message || t("agency_panel_msg_save_error"),
      });
    }
  };

  const handleExecuteBulkMarkPaid = async () => {
    if (isDemoMode && !isDemoVerified) {
      onRequestVerification?.();
      return;
    }
    const selectedList = payments.filter((p) => selectedPaymentIds.has(p.id));
    if (selectedList.length === 0) return;

    setIsSubmittingBulkMarkPaid(true);
    const paymentIds = selectedList.map((p) => p.id);
    try {
      let finalReceiptUrl: string | null = null;

      if (bulkReceiptFile) {
        if (hasSupabaseSession) {
          try {
            const ext = bulkReceiptFile.name.split(".").pop();
            const path = `bulk_${selectedPropertyDrawer?.id || "prop"}_${Date.now()}.${ext}`;
            const { data: uploadData, error: upErr } = await supabase.storage
              .from("receipts")
              .upload(path, bulkReceiptFile, { upsert: true });

            if (!upErr && uploadData) {
              const { data: publicUrlData } = supabase.storage
                .from("receipts")
                .getPublicUrl(uploadData.path);
              finalReceiptUrl = publicUrlData?.publicUrl || uploadData.path;
            }
          } catch (storageErr) {
            console.warn("Storage upload failed, using dataUrl fallback:", storageErr);
          }
        }
        if (!finalReceiptUrl && bulkReceiptFileUrl) {
          finalReceiptUrl = bulkReceiptFileUrl;
        }
      }

      const updatePayload: any = {
        status: "paid",
        paid_at: bulkMarkPaidDate || new Date().toISOString(),
        payment_method: bulkMarkPaidMethod,
      };
      if (bulkMarkPaidNote.trim()) {
        updatePayload.owner_note = bulkMarkPaidNote.trim();
      }
      if (finalReceiptUrl) {
        updatePayload.receipt_url = finalReceiptUrl;
      }

      if (hasSupabaseSession) {
        const { error } = await supabase
          .from("rent_payments")
          .update(updatePayload)
          .in("id", paymentIds);
        if (error) throw error;

        try {
          const logsToInsert = selectedList.map((p) => {
            const isRent = (p.title || "").toLowerCase().includes("kira") || (p.title || "").toLowerCase().includes("rent") || (p.title || "").toLowerCase().includes("kirij");
            return {
              property_id: p.property_id,
              user_id: userId,
              type: isRent ? "rent_approved" : "payment_toggle",
              metadata: {
                payment_id: p.id,
                title: p.title,
                amount: p.amount,
                currency: p.currency,
                due_date: p.due_date,
                payment_method: bulkMarkPaidMethod,
                has_receipt: Boolean(finalReceiptUrl),
                receipt_url: finalReceiptUrl || undefined,
                paid: true,
                note: bulkMarkPaidNote.trim() || undefined,
              },
            };
          });
          if (logsToInsert.length > 0) {
            const { data: insertedLogs } = await supabase
              .from("activity_logs")
              .insert(logsToInsert)
              .select();
            if (insertedLogs && insertedLogs.length > 0) {
              setDrawerActivityLogs((prev) => [...insertedLogs, ...prev]);
            }
          }
        } catch (_) { }
      }

      setPayments((prev) =>
        prev.map((item) =>
          paymentIds.includes(item.id)
            ? {
              ...item,
              ...updatePayload,
              dispute_reason: null,
            }
            : item
        )
      );

      clearSelectedPayments();
      setIsBulkMarkPaidModalOpen(false);
      setStatusMessage({
        type: "success",
        text: t("agency_bulk_paid_success", { count: String(paymentIds.length) }),
      });
    } catch (err: any) {
      console.error("Bulk mark paid error:", err);
      setStatusMessage({
        type: "error",
        text: err?.message || t("agency_panel_msg_save_error"),
      });
    } finally {
      setIsSubmittingBulkMarkPaid(false);
    }
  };

  const openDisputeModal = (pay: AgencyRentPayment) => {
    if (isDemoMode && !isDemoVerified) {
      onRequestVerification?.();
      return;
    }
    setDisputePayment(pay);
    setDisputeReason("");
    setIsDisputeModalOpen(true);
  };

  const handleExecuteDispute = async () => {
    if (!disputePayment) return;
    if (!disputeReason.trim()) return;

    setIsSubmittingDispute(true);
    try {
      if (hasSupabaseSession) {
        const { error } = await supabase
          .from("rent_payments")
          .update({
            status: "pending",
            declared_at: null,
            dispute_reason: disputeReason.trim(),
          })
          .eq("id", disputePayment.id);
        if (error) throw error;

        try {
          const { data: insertedLog } = await supabase
            .from("activity_logs")
            .insert({
              property_id: disputePayment.property_id,
              user_id: userId,
              type: "rent_rejected",
              metadata: {
                payment_id: disputePayment.id,
                title: disputePayment.title,
                amount: disputePayment.amount,
                currency: disputePayment.currency,
                due_date: disputePayment.due_date,
                reason: disputeReason.trim(),
              },
            })
            .select()
            .single();
          if (insertedLog) {
            setDrawerActivityLogs((prev) => [insertedLog, ...prev]);
          }
        } catch (_) { }
      } else {
        const demoLog = {
          id: `log-${Date.now()}`,
          property_id: disputePayment.property_id,
          user_id: userId || "demo",
          type: "rent_rejected",
          metadata: {
            payment_id: disputePayment.id,
            title: disputePayment.title,
            amount: disputePayment.amount,
            currency: disputePayment.currency,
            due_date: disputePayment.due_date,
            reason: disputeReason.trim(),
          },
          created_at: new Date().toISOString(),
        };
        setDrawerActivityLogs((prev) => [demoLog, ...prev]);
      }

      setPayments((prev) =>
        prev.map((item) =>
          item.id === disputePayment.id
            ? { ...item, status: "pending", declared_at: null, dispute_reason: disputeReason.trim() }
            : item
        )
      );

      if (selectedReceiptPayment?.id === disputePayment.id) {
        setSelectedReceiptPayment(null);
      }

      setIsDisputeModalOpen(false);
      setStatusMessage({
        type: "success",
        text: t("agency_payments_rejected_success"),
      });
    } catch (err) {
      console.error("Dispute payment error:", err);
      setStatusMessage({
        type: "error",
        text: t("agency_panel_msg_save_error"),
      });
    } finally {
      setIsSubmittingDispute(false);
    }
  };

  const openInvoiceModal = (pay: AgencyRentPayment) => {
    if (isDemoMode && !isDemoVerified) {
      onRequestVerification?.();
      return;
    }
    setInvoicePayment(pay);
    setInvoiceAmount(pay.amount > 0 ? pay.amount.toString() : "");
    const isRent = (pay.title || "").toLowerCase().includes("kira") || (pay.title || "").toLowerCase().includes("rent") || (pay.title || "").toLowerCase().includes("kirij");
    const effCurr = (pay.amount > 0 && pay.currency)
      ? pay.currency
      : (isRent ? (pay.currency || "EUR") : "RSD");
    setInvoiceCurrency((effCurr === "EUR" ? "EUR" : "RSD"));
    setInvoiceDueDate(pay.due_date || new Date().toISOString().split("T")[0]);
    setInvoiceNote(pay.owner_note || "");
    setInvoiceFileUrl(pay.invoice_url || null);
    setInvoiceFileName(pay.invoice_url ? "fatura_belgesi" : "");
    setIsInvoiceModalOpen(true);
  };

  const handleExecuteSaveInvoice = async (p: AgencyManagedProperty) => {
    if (isDemoMode && !isDemoVerified) {
      onRequestVerification?.();
      return;
    }
    if (!invoicePayment) return;
    const amountNum = parseFloat(invoiceAmount.replace(",", ".")) || 0;
    if (amountNum < 0) return;

    setIsSubmittingInvoice(true);
    try {
      let activeUserId = userId;
      if (!activeUserId) {
        try {
          const { data: authData } = await supabase.auth.getUser();
          activeUserId = authData?.user?.id || null;
        } catch (_) { }
      }

      const isUploaded = Boolean(
        invoiceFileUrl &&
        (invoiceFileUrl.startsWith("http://") ||
          invoiceFileUrl.startsWith("https://") ||
          invoiceFileUrl.startsWith("data:"))
      );
      const logType = isUploaded ? "invoice_uploaded" : "invoice_entered";
      const targetPropId = invoicePayment.property_id || p.id;

      if (activeUserId && activeUserId !== "demo") {
        const { error } = await supabase
          .from("rent_payments")
          .update({
            amount: amountNum,
            currency: invoiceCurrency,
            due_date: invoiceDueDate,
            owner_note: invoiceNote.trim() || null,
            invoice_url: invoiceFileUrl,
            dispute_reason: null,
            status: amountNum === 0 ? "paid" : "pending",
          })
          .eq("id", invoicePayment.id);
        if (error) throw error;

        try {
          const logPayload = {
            property_id: targetPropId,
            user_id: activeUserId,
            type: logType,
            metadata: {
              payment_id: invoicePayment.id,
              title: invoicePayment.title || "Fatura",
              amount: amountNum,
              currency: invoiceCurrency,
              due_date: invoiceDueDate,
              is_agency_approval_pending: false,
              invoice_url: invoiceFileUrl || undefined,
            },
          };

          const { data: insertedLog, error: logErr } = await supabase
            .from("activity_logs")
            .insert(logPayload)
            .select()
            .single();

          if (logErr) {
            console.error("activity_logs insert error in handleExecuteSaveInvoice:", logErr);
          } else if (insertedLog) {
            setDrawerActivityLogs((prev) => [insertedLog, ...prev]);
          }
        } catch (logErr) {
          console.error("activity_logs insert exception:", logErr);
        }
      } else {
        const demoLog = {
          id: `log-${Date.now()}`,
          property_id: targetPropId,
          user_id: activeUserId || "demo",
          type: logType,
          metadata: {
            payment_id: invoicePayment.id,
            title: invoicePayment.title || "Fatura",
            amount: amountNum,
            currency: invoiceCurrency,
            due_date: invoiceDueDate,
            is_agency_approval_pending: false,
            invoice_url: invoiceFileUrl || undefined,
          },
          created_at: new Date().toISOString(),
        };
        setDrawerActivityLogs((prev) => [demoLog, ...prev]);
      }

      setPayments((prev) =>
        prev.map((item) =>
          item.id === invoicePayment.id
            ? {
              ...item,
              amount: amountNum,
              currency: invoiceCurrency,
              due_date: invoiceDueDate,
              owner_note: invoiceNote.trim() || null,
              invoice_url: invoiceFileUrl,
              dispute_reason: null,
              status: amountNum === 0 ? "paid" : "pending",
            }
            : item
        )
      );

      setIsInvoiceModalOpen(false);
      setStatusMessage({
        type: "success",
        text: t("agency_invoice_saved_success"),
      });
    } catch (err) {
      console.error("Save invoice error:", err);
      setStatusMessage({
        type: "error",
        text: t("agency_panel_msg_save_error"),
      });
    } finally {
      setIsSubmittingInvoice(false);
    }
  };

  const formatLogTimestamp = (dateStr?: string | null) => {
    if (!dateStr) return "-";
    try {
      const d = new Date(dateStr);
      if (isNaN(d.getTime())) return "-";
      const datePart = d.toLocaleDateString(activeLocale, {
        day: "2-digit",
        month: "2-digit",
        year: "numeric",
      });
      const timePart = d.toLocaleTimeString(undefined, {
        hour: "2-digit",
        minute: "2-digit",
      });
      return `${datePart} ${timePart}`;
    } catch {
      return "-";
    }
  };

  const openAddNoteModal = (p: AgencyManagedProperty) => {
    setNewNoteText("");
    setNewNoteDate(new Date().toISOString().split("T")[0]);
    setIsAddNoteModalOpen(true);
  };

  const handleExecuteSaveNote = async (p: AgencyManagedProperty) => {
    if (isDemoMode && !isDemoVerified) {
      onRequestVerification?.();
      return;
    }
    if (!newNoteText.trim()) return;

    setIsSubmittingNote(true);
    try {
      let activeUserId = userId;
      if (!activeUserId) {
        try {
          const { data: authData } = await supabase.auth.getUser();
          activeUserId = authData?.user?.id || null;
        } catch (_) { }
      }

      // Parity with Flutter: preserve browser local time so hours & minutes are properly displayed
      const now = new Date();
      let logIsoDate = now.toISOString();
      if (newNoteDate) {
        const todayStr = now.toISOString().split("T")[0];
        if (newNoteDate !== todayStr) {
          const [y, m, d] = newNoteDate.split("-").map(Number);
          const customDate = new Date(y, m - 1, d, now.getHours(), now.getMinutes(), now.getSeconds());
          logIsoDate = customDate.toISOString();
        }
      }

      const noteItem = {
        id: `note-${Date.now()}`,
        note: newNoteText.trim(),
        created_at: logIsoDate,
        user_name: "Acente",
      };

      if (activeUserId && activeUserId !== "demo") {
        const { data: insertedLog, error: logErr } = await supabase
          .from("activity_logs")
          .insert({
            property_id: p.id,
            user_id: activeUserId,
            type: "manual_note",
            metadata: { note: newNoteText.trim() },
            created_at: logIsoDate,
          })
          .select()
          .single();

        if (logErr) {
          console.error("activity_logs insert error in handleExecuteSaveNote:", logErr);
        } else if (insertedLog) {
          setDrawerActivityLogs((prev) => [insertedLog, ...prev]);
        }
      } else {
        const demoLog = {
          id: `note-${Date.now()}`,
          property_id: p.id,
          user_id: "demo",
          type: "manual_note",
          metadata: { note: newNoteText.trim() },
          created_at: logIsoDate,
        };
        setDrawerActivityLogs((prev) => [demoLog, ...prev]);
      }

      setPropertyNotes((prev) => ({
        ...prev,
        [p.id]: [noteItem, ...(prev[p.id] || [])],
      }));

      setIsAddNoteModalOpen(false);
      setStatusMessage({
        type: "success",
        text: t("agency_panel_msg_saved"),
      });
    } catch (err) {
      console.error("Save note error:", err);
      setStatusMessage({
        type: "error",
        text: t("agency_panel_msg_save_error"),
      });
    } finally {
      setIsSubmittingNote(false);
    }
  };

  const openEditNoteModal = (log: any) => {
    setEditingNoteLog(log);
    setEditNoteText(log.metadata?.note || log.note || "");
    setIsEditNoteModalOpen(true);
  };

  const handleExecuteUpdateNote = async (p: AgencyManagedProperty) => {
    if (isDemoMode && !isDemoVerified) {
      onRequestVerification?.();
      return;
    }
    if (!editingNoteLog || !editNoteText.trim()) return;

    setIsSubmittingEditNote(true);
    try {
      let activeUserId = userId;
      if (!activeUserId) {
        try {
          const { data: authData } = await supabase.auth.getUser();
          activeUserId = authData?.user?.id || null;
        } catch (_) { }
      }

      const updatedNote = editNoteText.trim();
      const updatedMetadata = {
        ...(editingNoteLog.metadata || {}),
        note: updatedNote,
        updated_at: new Date().toISOString(),
      };

      if (activeUserId && activeUserId !== "demo") {
        const { error: updateErr } = await supabase
          .from("activity_logs")
          .update({
            metadata: updatedMetadata,
          })
          .eq("id", editingNoteLog.id);

        if (updateErr) {
          console.error("activity_logs update error:", updateErr);
          throw updateErr;
        }
      }

      // Update in drawerActivityLogs
      setDrawerActivityLogs((prev) =>
        prev.map((l) =>
          l.id === editingNoteLog.id
            ? {
              ...l,
              metadata: updatedMetadata,
            }
            : l
        )
      );

      // Also update in propertyNotes if exists
      setPropertyNotes((prev) => ({
        ...prev,
        [p.id]: (prev[p.id] || []).map((n) =>
          n.id === editingNoteLog.id ? { ...n, note: updatedNote } : n
        ),
      }));

      setIsEditNoteModalOpen(false);
      setEditingNoteLog(null);
      setEditNoteText("");
      setStatusMessage({
        type: "success",
        text: t("agency_note_updated_success"),
      });
    } catch (err) {
      console.error("Update note error:", err);
      setStatusMessage({
        type: "error",
        text: t("agency_panel_msg_save_error"),
      });
    } finally {
      setIsSubmittingEditNote(false);
    }
  };

  const handleExecuteDeleteNote = async (p: AgencyManagedProperty, noteId: string) => {
    if (isDemoMode && !isDemoVerified) {
      onRequestVerification?.();
      return;
    }
    if (typeof window !== "undefined" && !window.confirm(t("agency_note_delete_confirm"))) {
      return;
    }

    try {
      let activeUserId = userId;
      if (!activeUserId) {
        try {
          const { data: authData } = await supabase.auth.getUser();
          activeUserId = authData?.user?.id || null;
        } catch (_) { }
      }

      if (activeUserId && activeUserId !== "demo") {
        const { error: delErr } = await supabase
          .from("activity_logs")
          .delete()
          .eq("id", noteId);

        if (delErr) {
          console.error("activity_logs delete error:", delErr);
          throw delErr;
        }
      }

      // Remove from drawerActivityLogs
      setDrawerActivityLogs((prev) => prev.filter((l) => l.id !== noteId));

      // Remove from propertyNotes
      setPropertyNotes((prev) => ({
        ...prev,
        [p.id]: (prev[p.id] || []).filter((n) => n.id !== noteId),
      }));

      setStatusMessage({
        type: "success",
        text: t("agency_note_deleted_success"),
      });
    } catch (err) {
      console.error("Delete note error:", err);
      setStatusMessage({
        type: "error",
        text: t("agency_panel_msg_save_error"),
      });
    }
  };

  const formatActivityLogItem = (
    log: any,
    propPaymentsForLookup: AgencyRentPayment[] = [],
    fallbackPayment?: AgencyRentPayment
  ) => {
    const meta = log.metadata || {};
    const matchedPayment =
      fallbackPayment ||
      (meta.payment_id
        ? propPaymentsForLookup.find((pay) => pay.id === meta.payment_id)
        : undefined) ||
      (Array.isArray(meta.payment_ids) && meta.payment_ids.length > 0
        ? propPaymentsForLookup.find((pay) => meta.payment_ids.includes(pay.id))
        : undefined);

    const rawDueDate = meta.due_date || matchedPayment?.due_date;
    let monthStr = "";
    if (rawDueDate) {
      try {
        const d = new Date(rawDueDate);
        if (!isNaN(d.getTime())) {
          monthStr = d.toLocaleDateString(activeLocale, { month: "long", year: "numeric" });
        } else {
          monthStr = meta.month || "";
        }
      } catch (_) {
        monthStr = meta.month || "";
      }
    } else if (meta.month) {
      monthStr = meta.month;
    }

    const rawTitle = meta.title || matchedPayment?.title || "";
    const itemTitle = rawTitle ? formatPaymentTitle(rawTitle) : "";
    const rawAmount =
      meta.amount !== undefined && meta.amount !== null
        ? Number(meta.amount)
        : matchedPayment?.amount !== undefined
          ? Number(matchedPayment.amount)
          : null;
    const rawCurrency =
      meta.currency ||
      matchedPayment?.currency ||
      (rawTitle &&
        (rawTitle.toLowerCase().includes("kira") ||
          rawTitle.toLowerCase().includes("rent") ||
          rawTitle.toLowerCase().includes("kirij"))
        ? "EUR"
        : "RSD");
    const formattedAmt =
      rawAmount !== null && !isNaN(rawAmount) && rawAmount > 0
        ? `${rawAmount.toLocaleString("de-DE")} ${rawCurrency}`
        : "";

    // Build context prefix showing [Month] • [Payment Title] ([Amount])
    const contextParts: string[] = [];
    if (monthStr) contextParts.push(monthStr);
    if (itemTitle) contextParts.push(itemTitle);
    const contextHeader = contextParts.join(" • ");
    const contextWithAmount =
      contextHeader && formattedAmt
        ? `${contextHeader} (${formattedAmt}): `
        : contextHeader
          ? `${contextHeader}: `
          : formattedAmt
            ? `(${formattedAmt}) `
            : "";
    const monthAndTitlePrefix = contextHeader ? `${contextHeader}: ` : "";

    switch (log.type) {
      case "invoice_entered": {
        const displayAmt = formattedAmt || `0 ${rawCurrency}`;
        return `${monthAndTitlePrefix}${t("agency_audit_invoice_entered", { amount: displayAmt })}`;
      }
      case "invoice_uploaded": {
        const displayAmt = formattedAmt || `0 ${rawCurrency}`;
        return `${monthAndTitlePrefix}${t("agency_audit_invoice_uploaded", { amount: displayAmt })}`;
      }
      case "invoice_approved": {
        const displayAmt = formattedAmt || `0 ${rawCurrency}`;
        return `${monthAndTitlePrefix}${t("agency_audit_invoice_approved", { amount: displayAmt })}`;
      }
      case "invoice_rejected": {
        const reason = meta.reason ? `: ${meta.reason}` : "";
        return `${contextWithAmount}${t("agency_audit_invoice_rejected")}${reason}`;
      }
      case "rent_approved": {
        return `${contextWithAmount}${t("agency_audit_rent_approved")}`;
      }
      case "rent_auto_approved": {
        return `${contextWithAmount}${t("agency_audit_rent_auto_approved")}`;
      }
      case "rent_declared": {
        const cashTag =
          meta.is_cash || matchedPayment?.payment_method === "cash" || matchedPayment?.receipt_url === "CASH"
            ? ` (${t("paymentMethodCash")})`
            : "";
        return `${contextWithAmount}${t("agency_audit_rent_declared")}${cashTag}`;
      }
      case "rent_rejected": {
        const reason = meta.reason ? `: ${meta.reason}` : "";
        return `${contextWithAmount}${t("agency_audit_rent_rejected")}${reason}`;
      }
      case "rent_disputed": {
        const reason = meta.reason ? `: ${meta.reason}` : "";
        return `${contextWithAmount}${t("agency_audit_rent_disputed")}${reason}`;
      }
      case "payment_toggle": {
        const statusText = meta.paid ? t("agency_payments_status_paid") : t("agency_payments_status_pending");
        return `${contextWithAmount}${t("agency_audit_payment_toggle", { status: statusText })}`;
      }
      case "payment_created": {
        const isRent =
          !rawTitle ||
          rawTitle.toLowerCase().includes("kira") ||
          rawTitle.toLowerCase().includes("rent") ||
          rawTitle.toLowerCase().includes("kirij");
        if (fallbackPayment) {
          return isRent
            ? t("agency_audit_payment_created_rent")
            : t("agency_audit_payment_created_expense");
        }
        return `${contextWithAmount}${t("agency_audit_payment_created", {
          title: itemTitle || t("agency_financials_rent"),
        })}`;
      }
      case "maintenance_created": {
        const titleSuffix = meta.title ? `: ${meta.title}` : "";
        return `${t("agency_audit_maintenance_created")}${titleSuffix}`;
      }
      case "maintenance_status_updated": {
        return t("agency_audit_maintenance_status_updated");
      }
      case "maintenance_message_added": {
        return t("agency_audit_maintenance_message_added");
      }
      case "maintenance_reopened": {
        return t("agency_audit_maintenance_reopened");
      }
      case "maintenance_financials_updated": {
        return t("agency_audit_maintenance_financials_updated");
      }
      case "maintenance_charge_created": {
        return t("agency_audit_maintenance_charge_created");
      }
      case "maintenance_charge_settled": {
        return t("agency_audit_maintenance_charge_settled");
      }
      case "invitation_accepted": {
        return t("agency_audit_invitation_accepted");
      }
      case "contract_accepted": {
        return t("agency_audit_contract_accepted");
      }
      case "contract_termination_requested": {
        return t("agency_audit_contract_termination_requested");
      }
      case "contract_changes_accepted": {
        return t("agency_audit_contract_changes_accepted");
      }
      case "contract_changes_declined": {
        return t("agency_audit_contract_changes_declined");
      }
      case "landlord_ownership_claimed": {
        return t("agency_audit_landlord_ownership_claimed");
      }
      case "tenant_removed": {
        return t("agency_audit_tenant_removed");
      }
      case "property_owners_updated": {
        return t("agency_audit_property_owners_updated");
      }
      case "tenant_invite_email_sent": {
        return t("agency_audit_tenant_invite_email_sent");
      }
      case "landlord_invite_email_sent": {
        return t("agency_audit_landlord_invite_email_sent");
      }
      case "manual_note": {
        return meta.note || t("agency_audit_filter_notes");
      }
      default: {
        if (!log.type) return t("agency_audit_generic_event");
        const clean = String(log.type).replace(/_/g, " ");
        return clean.charAt(0).toUpperCase() + clean.slice(1);
      }
    }
  };

  return (
    <div
      role="tabpanel"
      id="tabpanel-managed-properties"
      aria-labelledby="tab-managed-properties"
      className="space-y-6 animate-in fade-in duration-200"
    >
      {/* ZZPL Real Data Notice in Demo */}
      {isDemoMode && (
        <div className="flex items-center gap-2.5 p-3 rounded-[10px] bg-[#FBF1DC] border border-[#8A5206]/20 text-[#8A5206] text-xs font-semibold shadow-2xs">
          <AlertTriangle className="w-4 h-4 text-[#8A5206] shrink-0" />
          <span>{tSafe("agency_demo_warn_real_data")}</span>
        </div>
      )}
      {selectedPropertyDrawer ? (() => {
        const p = selectedPropertyDrawer;
        const linkedPortfolioListing = findLinkedListing(p);
        const isActivelyListedInPortfolio = Boolean(
          linkedPortfolioListing &&
          linkedPortfolioListing.is_published &&
          linkedPortfolioListing.listing_status !== "rented" &&
          linkedPortfolioListing.listing_status !== "sold" &&
          linkedPortfolioListing.listing_status !== "archived"
        );
        const terminationLogForProp = drawerActivityLogs.find(
          (lg) =>
            lg.property_id === p.id &&
            (lg.type === "contract_termination_requested" || lg.type === "tenant_removed")
        );
        const isContractTerminatedOrSuperseded = (c: AgencyContract) => {
          if (
            c.status === "terminated" ||
            c.status === "termination_requested" ||
            Boolean(c.termination_approved) ||
            Boolean(c.termination_date)
          ) {
            return true;
          }
          if (
            terminationLogForProp &&
            (terminationLogForProp.metadata?.contract_id === c.id || !p.tenant_id)
          ) {
            return true;
          }
          return false;
        };
        const rawActiveOrPendingContract =
          contracts.find(
            (c) =>
              c.property_id === p.id &&
              c.status === "active" &&
              !isContractTerminatedOrSuperseded(c)
          ) ||
          contracts.find(
            (c) =>
              c.property_id === p.id &&
              c.status === "pending" &&
              !isContractTerminatedOrSuperseded(c)
          ) ||
          null;
        const propContract = rawActiveOrPendingContract;
        const lastTerminatedContract =
          contracts.find(
            (c) => c.property_id === p.id && isContractTerminatedOrSuperseded(c)
          ) ||
          (isActivelyListedInPortfolio && rawActiveOrPendingContract
            ? rawActiveOrPendingContract
            : null);
        const propPayments = processRentPayments(payments.filter((pay) => pay.property_id === p.id));
        const propMaintenance = maintenanceRequests.filter((m) => m.property_id === p.id);
        const maintenanceSettlements = getEligibleMaintenanceSettlements(maintenanceRequests, p.id);

        // Flutter SSOT currency resolution:
        // If amount > 0 and currency is present, use it.
        // If amount === 0 or missing, rent defaults to EUR (or property currency), whereas utilities/bills default to RSD!
        const getEffectiveCurrency = (pay: AgencyRentPayment): string => {
          const t = (pay.title || "").toLowerCase();
          const isRent = t.includes("kira") || t.includes("rent") || t.includes("kirij");
          if (pay.amount > 0 && pay.currency) {
            return pay.currency;
          }
          return isRent ? (pay.currency || p.currency || "EUR") : "RSD";
        };

        const isPaymentDisputed = (pay: AgencyRentPayment) => pay.status === "disputed";
        const isPaymentAwaiting = (pay: AgencyRentPayment) =>
          pay.status === "declared" || (pay.status === "pending" && Boolean(pay.declared_at));
        const isPaymentPendingUnpaid = (pay: AgencyRentPayment) =>
          pay.status === "pending" && !pay.declared_at;

        // Per-payment activity log matcher (100% Flutter _getPaymentActivityLogs parity)
        const getPaymentActivityLogs = (pay: AgencyRentPayment) => {
          const payDueDateStr = pay.due_date ? pay.due_date.split("T")[0] : "";
          let payMonthStr = "";
          if (pay.due_date) {
            try {
              const d = new Date(pay.due_date);
              if (!isNaN(d.getTime())) {
                payMonthStr = d
                  .toLocaleDateString(activeLocale, { month: "long", year: "numeric" })
                  .toUpperCase();
              }
            } catch (_) { }
          }
          const isRent =
            (pay.title || "").toLowerCase().includes("kira") ||
            (pay.title || "").toLowerCase().includes("rent") ||
            (pay.title || "").toLowerCase().includes("kirij");

          const matched = drawerActivityLogs.filter((log) => {
            const meta = log.metadata || {};
            if (meta.payment_id === pay.id) return true;
            if (Array.isArray(meta.payment_ids) && meta.payment_ids.includes(pay.id)) return true;

            if (!meta.payment_id) {
              const logDueDate = meta.due_date;
              const logMonth = meta.month;
              let isDateMatch = false;
              if (typeof logDueDate === "string" && payDueDateStr) {
                isDateMatch = logDueDate.split("T")[0] === payDueDateStr;
              } else if (typeof logMonth === "string" && payMonthStr) {
                isDateMatch = logMonth.toUpperCase() === payMonthStr;
              }
              if (isDateMatch) {
                if (isRent) {
                  return (
                    log.type === "rent_declared" ||
                    log.type === "rent_approved" ||
                    log.type === "rent_rejected" ||
                    log.type === "rent_disputed" ||
                    log.type === "rent_auto_approved" ||
                    log.type === "payment_toggle"
                  );
                } else {
                  if (
                    log.type === "invoice_uploaded" ||
                    log.type === "invoice_entered" ||
                    log.type === "invoice_approved" ||
                    log.type === "invoice_rejected" ||
                    log.type === "rent_disputed" ||
                    log.type === "payment_toggle"
                  ) {
                    if (meta.title && (meta.title || "").toLowerCase() === (pay.title || "").toLowerCase()) {
                      return true;
                    }
                    const logAmount = Number(meta.amount);
                    if (!isNaN(logAmount) && logAmount === pay.amount) {
                      return true;
                    }
                  }
                }
              }
            }
            return false;
          });

          const sorted = [...matched].sort((a, b) =>
            (a.created_at || "").localeCompare(b.created_at || "")
          );

          // Synthesize fallback logs if DB logs are empty or missing key events
          const result: any[] = [];
          if (isRent) {
            const defaultCreatedDate = pay.created_at
              ? pay.created_at
              : pay.due_date
                ? new Date(new Date(pay.due_date).getTime() - 15 * 86400 * 1000).toISOString()
                : new Date().toISOString();
            result.push({
              id: `creation_${pay.id}`,
              property_id: pay.property_id,
              type: "payment_created",
              created_at: defaultCreatedDate,
              metadata: {
                payment_id: pay.id,
                title: pay.title,
                amount: pay.amount,
                currency: getEffectiveCurrency(pay),
                due_date: pay.due_date,
              },
            });
          }

          result.push(...sorted);

          // If payment is declared/disputed/paid in state/demo but no matching log exists yet, synthesize it so history is never blank
          if (
            (pay.status === "declared" || Boolean(pay.declared_at)) &&
            !result.some((l) => l.type === "rent_declared")
          ) {
            result.push({
              id: `synth_declared_${pay.id}`,
              property_id: pay.property_id,
              type: "rent_declared",
              created_at: pay.declared_at || pay.created_at,
              metadata: {
                payment_id: pay.id,
                title: pay.title,
                amount: pay.amount,
                currency: getEffectiveCurrency(pay),
                due_date: pay.due_date,
                is_cash: pay.payment_method === "cash" || pay.receipt_url === "CASH",
              },
            });
          }
          if (
            pay.status === "disputed" &&
            !result.some((l) => l.type === "rent_disputed")
          ) {
            result.push({
              id: `synth_disputed_${pay.id}`,
              property_id: pay.property_id,
              type: "rent_disputed",
              created_at: pay.disputed_at || pay.updated_at || pay.created_at,
              metadata: {
                payment_id: pay.id,
                title: pay.title,
                amount: pay.amount,
                currency: getEffectiveCurrency(pay),
                due_date: pay.due_date,
                reason: pay.dispute_reason,
              },
            });
          }
          if (
            pay.status === "paid" &&
            !result.some(
              (l) =>
                l.type === "rent_approved" ||
                l.type === "rent_auto_approved" ||
                (l.type === "payment_toggle" && l.metadata?.paid)
            )
          ) {
            result.push({
              id: `synth_paid_${pay.id}`,
              property_id: pay.property_id,
              type: isRent ? "rent_approved" : "payment_toggle",
              created_at: pay.paid_at || pay.created_at,
              metadata: {
                payment_id: pay.id,
                title: pay.title,
                amount: pay.amount,
                currency: getEffectiveCurrency(pay),
                due_date: pay.due_date,
                paid: true,
              },
            });
          }

          return result;
        };

        // Financial metrics
        const paidPayments = propPayments.filter((pay) => pay.status === "paid");
        const awaitingPayments = propPayments.filter(
          (pay) => isPaymentAwaiting(pay) || isPaymentDisputed(pay)
        );
        const overduePayments = propPayments.filter(
          (pay) => isPaymentPendingUnpaid(pay) && new Date(pay.due_date) < new Date()
        );
        const upcomingPayments = propPayments.filter(
          (pay) => isPaymentPendingUnpaid(pay) && new Date(pay.due_date) >= new Date()
        );

        const totalCollected = paidPayments.reduce((acc, pay) => acc + pay.amount, 0);
        const totalAwaiting = awaitingPayments.reduce((acc, pay) => acc + pay.amount, 0);
        const totalOverdue = overduePayments.reduce((acc, pay) => acc + pay.amount, 0);
        const totalUpcoming = upcomingPayments.reduce((acc, pay) => acc + pay.amount, 0);

        const todayStr = new Date().toISOString().split("T")[0];

        // Helper classifiers
        const isRentItem = (pay: AgencyRentPayment) => {
          const t = (pay.title || "").toLowerCase();
          return t.includes("kira") || t.includes("rent") || t.includes("kirij");
        };
        const isMaintItem = (pay: AgencyRentPayment) => {
          const t = (pay.title || "").toLowerCase();
          return Boolean(pay.is_maintenance) || t.includes("bakım") || t.includes("arıza") || t.includes("tamir");
        };

        // 1. Matches Type Filter
        const matchesPaymentType = (p: AgencyRentPayment) => {
          if (financialTypeFilter === "all") return true;
          const isRent = isRentItem(p);
          if (financialTypeFilter === "rent") return isRent;
          if (financialTypeFilter === "bills") return !isRent && !isMaintItem(p);
          if (financialTypeFilter === "maintenance") return isMaintItem(p);
          return false;
        };

        const matchesMaintenanceType = (r: AgencyMaintenanceRequest) => {
          if (financialTypeFilter === "rent" || financialTypeFilter === "bills") return false;
          return true;
        };

        // 2. Matches Due Date Filter
        const matchesPaymentDueDate = (p: AgencyRentPayment) => {
          if (financialDueDateFilter === "all") return true;
          if (!p.due_date) return financialDueDateFilter === "upcoming";
          if (financialDueDateFilter === "overdue") {
            return p.due_date < todayStr;
          }
          if (financialDueDateFilter === "upcoming") {
            return p.due_date >= todayStr;
          }
          return true;
        };

        const matchesMaintenanceDueDate = (r: AgencyMaintenanceRequest) => {
          if (financialDueDateFilter === "all") return true;
          const dStr = r.payment_date || r.created_at;
          const d = dStr ? dStr.split("T")[0] : null;
          if (financialDueDateFilter === "overdue") {
            if (r.payment_status !== "pending_payment") return false;
            return d !== null && d < todayStr;
          }
          if (financialDueDateFilter === "upcoming") {
            return d === null || d >= todayStr;
          }
          return true;
        };

        // 3. Matches Status Filter
        const matchesPaymentStatus = (p: AgencyRentPayment) => {
          if (financialStatusFilter === "all") return true;
          if (financialStatusFilter === "unentered") {
            return (
              p.amount === 0 &&
              !isRentItem(p) &&
              p.status !== "paid" &&
              !isPaymentAwaiting(p) &&
              !isPaymentDisputed(p)
            );
          }
          if (financialStatusFilter === "pending") {
            return isPaymentPendingUnpaid(p) && p.amount > 0;
          }
          if (financialStatusFilter === "awaiting") {
            return isPaymentAwaiting(p) || isPaymentDisputed(p);
          }
          if (financialStatusFilter === "paid") {
            return p.status === "paid";
          }
          return true;
        };

        // Filtered payments (matching all 3 active filters)
        const filteredPayments = propPayments.filter((pay) => {
          return matchesPaymentType(pay) && matchesPaymentDueDate(pay) && matchesPaymentStatus(pay);
        });

        // ── Dynamic Cross-Filter Deck Counts (100% Flutter SSOT Parity) ──
        // Section 1: STATUS CHIP COUNTERS (Cross-filtered by Type & Due Date)
        const unenteredCount = propPayments.filter((p) => {
          if (!matchesPaymentType(p) || !matchesPaymentDueDate(p)) return false;
          return (
            p.amount === 0 &&
            !isRentItem(p) &&
            p.status !== "paid" &&
            !isPaymentAwaiting(p) &&
            !isPaymentDisputed(p)
          );
        }).length;

        const pendingPaymentsCount = propPayments.filter((p) => {
          if (!matchesPaymentType(p) || !matchesPaymentDueDate(p)) return false;
          return isPaymentPendingUnpaid(p) && p.amount > 0;
        }).length;

        const pendingMaintenanceCount = maintenanceSettlements.filter((r) => {
          if (!matchesMaintenanceType(r) || !matchesMaintenanceDueDate(r)) return false;
          return r.payment_status === "pending_payment";
        }).length;

        const pendingCount = pendingPaymentsCount + pendingMaintenanceCount;

        const awaitingPaymentsCount = propPayments.filter((p) => {
          if (!matchesPaymentType(p) || !matchesPaymentDueDate(p)) return false;
          return isPaymentAwaiting(p) || isPaymentDisputed(p);
        }).length;

        const awaitingMaintenanceCount = maintenanceSettlements.filter((r) => {
          if (!matchesMaintenanceType(r) || !matchesMaintenanceDueDate(r)) return false;
          return (
            r.payment_status === "pending_review" ||
            r.payment_status === "pending_agency_approval" ||
            r.payment_status === "pending_opposite_approval"
          );
        }).length;

        const awaitingCount = awaitingPaymentsCount + awaitingMaintenanceCount;

        const paidPaymentsCount = propPayments.filter((p) => {
          if (!matchesPaymentType(p) || !matchesPaymentDueDate(p)) return false;
          return p.status === "paid";
        }).length;

        const paidMaintenanceSettlements = propMaintenance.filter(
          (m) => (m.cost_amount || 0) > 0 && m.payment_status === "paid"
        );

        const paidMaintenanceCount = paidMaintenanceSettlements.filter((r) => {
          if (!matchesMaintenanceType(r)) return false;
          if (financialDueDateFilter === "overdue") return false;
          return true;
        }).length;

        const paidCount = paidPaymentsCount + paidMaintenanceCount;

        // Section 2: DEBT TYPE CHIP COUNTERS (Cross-filtered by Due Date & Status)
        const rentCount = propPayments.filter((p) => {
          if (!isRentItem(p)) return false;
          if (!matchesPaymentDueDate(p)) return false;
          if (!matchesPaymentStatus(p)) return false;
          return true;
        }).length;

        const billsCount = propPayments.filter((p) => {
          if (isRentItem(p) || isMaintItem(p)) return false;
          if (!matchesPaymentDueDate(p)) return false;
          if (!matchesPaymentStatus(p)) return false;
          return true;
        }).length;

        const maintenanceUnsettledCount = maintenanceSettlements.filter((r) => {
          if (!matchesMaintenanceDueDate(r)) return false;
          if (financialStatusFilter === "unentered") return false;
          if (financialStatusFilter === "pending" && r.payment_status !== "pending_payment") return false;
          if (
            financialStatusFilter === "awaiting" &&
            r.payment_status !== "pending_review" &&
            r.payment_status !== "pending_agency_approval" &&
            r.payment_status !== "pending_opposite_approval"
          )
            return false;
          if (financialStatusFilter === "paid") return false;
          return true;
        }).length;

        const maintenancePaidFilteredCount =
          financialStatusFilter === "pending" ||
            financialStatusFilter === "awaiting" ||
            financialStatusFilter === "unentered" ||
            financialDueDateFilter === "overdue"
            ? 0
            : paidMaintenanceSettlements.filter(matchesMaintenanceType).length;

        const maintenanceCount = maintenanceUnsettledCount + maintenancePaidFilteredCount;

        // Section 3: DUE DATE CHIP COUNTERS (Cross-filtered by Type & Status)
        const overduePaymentsCount = propPayments.filter((p) => {
          if (!matchesPaymentType(p)) return false;
          if (p.status === "paid" || isPaymentAwaiting(p) || isPaymentDisputed(p)) return false;
          if (p.amount <= 0) return false;
          if (!p.due_date || p.due_date >= todayStr) return false;
          if (!matchesPaymentStatus(p)) return false;
          return true;
        }).length;

        const overdueMaintenanceCount =
          financialStatusFilter === "paid" || financialStatusFilter === "unentered" || financialStatusFilter === "awaiting"
            ? 0
            : maintenanceSettlements.filter((r) => {
              if (!matchesMaintenanceType(r)) return false;
              if (r.payment_status !== "pending_payment") return false;
              const dStr = r.payment_date || r.created_at;
              const d = dStr ? dStr.split("T")[0] : null;
              if (!d || d >= todayStr) return false;
              return true;
            }).length;

        const overdueCount = overduePaymentsCount + overdueMaintenanceCount;

        const upcomingPaymentsCount = propPayments.filter((p) => {
          if (!matchesPaymentType(p)) return false;
          if (p.due_date && p.due_date < todayStr) return false;
          if (!matchesPaymentStatus(p)) return false;
          return true;
        }).length;

        const upcomingMaintenanceCount =
          financialStatusFilter === "unentered"
            ? 0
            : maintenanceSettlements.filter((r) => {
              if (!matchesMaintenanceType(r)) return false;
              const dStr = r.payment_date || r.created_at;
              const d = dStr ? dStr.split("T")[0] : null;
              if (d && d < todayStr) return false;
              if (financialStatusFilter === "pending" && r.payment_status !== "pending_payment") return false;
              if (
                financialStatusFilter === "awaiting" &&
                r.payment_status !== "pending_review" &&
                r.payment_status !== "pending_agency_approval" &&
                r.payment_status !== "pending_opposite_approval"
              )
                return false;
              if (financialStatusFilter === "paid") return false;
              return true;
            }).length +
            (financialStatusFilter === "pending" || financialStatusFilter === "awaiting"
              ? 0
              : paidMaintenanceSettlements.filter(matchesMaintenanceType).length);

        const upcomingCount = upcomingPaymentsCount + upcomingMaintenanceCount;

        const hasActiveFilter = financialTypeFilter !== "all" || financialStatusFilter !== "all" || financialDueDateFilter !== "all";

        // Unsettled maintenance section filter matching Flutter matchesUnsettledMaintenanceFilters
        const matchesUnsettledMaintenanceFilters = (r: AgencyMaintenanceRequest): boolean => {
          if (!matchesMaintenanceType(r)) return false;
          if (!matchesMaintenanceDueDate(r)) return false;
          if (financialStatusFilter === "unentered") return false;
          if (financialStatusFilter === "pending") {
            if (r.payment_status !== "pending_payment") return false;
          } else if (financialStatusFilter === "awaiting") {
            if (
              r.payment_status !== "pending_review" &&
              r.payment_status !== "pending_agency_approval" &&
              r.payment_status !== "pending_opposite_approval"
            )
              return false;
          } else if (financialStatusFilter === "paid") {
            return false;
          }
          return true;
        };

        const visibleMaintenanceSettlements = maintenanceSettlements.filter(matchesUnsettledMaintenanceFilters);

        const matchesPaidMaintenanceFilters = (r: AgencyMaintenanceRequest): boolean => {
          if (!matchesMaintenanceType(r)) return false;
          if (financialStatusFilter === "pending" || financialStatusFilter === "awaiting" || financialStatusFilter === "unentered") return false;
          if (financialDueDateFilter === "overdue") return false;
          return true;
        };

        const filteredPaidMaintenance = paidMaintenanceSettlements.filter(matchesPaidMaintenanceFilters);

        // Monthly grouped payments
        const monthsMap = new Map<string, AgencyRentPayment[]>();
        filteredPayments.forEach((pay) => {
          const monthKey = pay.due_date ? pay.due_date.slice(0, 7) : "other";
          const list = monthsMap.get(monthKey) || [];
          list.push(pay);
          monthsMap.set(monthKey, list);
        });

        // Monthly grouped completed maintenance settlements
        const paidMaintenanceMap = new Map<string, AgencyMaintenanceRequest[]>();
        filteredPaidMaintenance.forEach((m) => {
          const dateStr = m.payment_date || m.created_at;
          const monthKey = dateStr ? dateStr.slice(0, 7) : "other";
          const list = paidMaintenanceMap.get(monthKey) || [];
          list.push(m);
          paidMaintenanceMap.set(monthKey, list);
        });

        const allMonthKeysSet = new Set<string>([...monthsMap.keys(), ...paidMaintenanceMap.keys()]);
        const sortedMonthKeys = Array.from(allMonthKeysSet).sort((a, b) => b.localeCompare(a));

        // Contract remaining days & renewal banner calculations
        let isContractExpired = false;
        let daysSinceExpired = 0;
        let contractRemainingDays: number | null = null;
        let bannerSeverity: "red" | "orange" | "yellow" | null = null;

        if (propContract?.end_date) {
          const diffTime = new Date(propContract.end_date).getTime() - Date.now();
          const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
          if (diffDays <= 0) {
            isContractExpired = true;
            daysSinceExpired = Math.abs(diffDays);
            contractRemainingDays = 0;
            bannerSeverity = "red";
          } else {
            contractRemainingDays = diffDays;
            if (diffDays <= 30) {
              bannerSeverity = "red";
            } else if (diffDays <= 60) {
              bannerSeverity = "orange";
            } else if (diffDays <= 90) {
              bannerSeverity = "yellow";
            }
          }
        }

        const formatEuropeanDate = (dStr?: string | null) => {
          if (!dStr) return "-";
          const parts = dStr.split("T")[0].split("-");
          if (parts.length === 3) {
            return `${parts[2]}.${parts[1]}.${parts[0]}`;
          }
          return dStr;
        };

        const getInitials = (name?: string | null) => {
          if (!name || !name.trim()) return "??";
          const parts = name.trim().split(" ");
          if (parts.length >= 2) {
            return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
          }
          return name.slice(0, 2).toUpperCase();
        };

        return (
          <div className="space-y-5 animate-in fade-in duration-200">
            {/* 1. Top Navigation / Breadcrumb */}
            <div className="flex items-center justify-between text-xs sm:text-sm">
              <button
                type="button"
                onClick={() => {
                  setSelectedPropertyDrawer(null);
                  setTargetPaymentId(null);
                  if (onBackFromDrawer) onBackFromDrawer();
                }}
                className="inline-flex items-center gap-1.5 font-bold text-[#1B5888] hover:text-[#12406A] transition-colors cursor-pointer"
              >
                <ChevronLeft className="w-4 h-4" />
                <span>{t("agency_props_btn_back_to_list")}</span>
              </button>
              <span className="text-xs text-slate-400 font-mono">
                {t("agency_prop_id_label")} {p.id.slice(0, 8)}...{p.id.slice(-4)}
              </span>
            </div>

            {/* 2. Sticky Unified Property Header + Action Bar + Tabs */}
            <div
              className={`sticky top-14 sm:top-16 z-30 bg-white/95 backdrop-blur-md border border-slate-200/80 transition-all duration-200 ${isDetailHeaderCompact
                  ? "rounded-xl px-4 py-2.5 shadow-md"
                  : "rounded-2xl px-5 sm:px-6 pt-5 sm:pt-6 pb-0 shadow-xs"
                }`}
            >
              {isDetailHeaderCompact ? (
                /* Compact Single-Row Sticky Bar (Title + Status + Tabs merged) */
                <div className="flex items-center justify-between gap-3">
                  <div className="flex items-center gap-2.5 min-w-0">
                    <button
                      type="button"
                      onClick={() => {
                        setSelectedPropertyDrawer(null);
                        setTargetPaymentId(null);
                        if (onBackFromDrawer) onBackFromDrawer();
                      }}
                      title={t("agency_props_btn_back_to_list")}
                      className="p-1.5 rounded-lg text-[#1B5888] hover:bg-[#E5EEF6] transition-colors cursor-pointer shrink-0"
                    >
                      <ChevronLeft className="w-4 h-4" />
                    </button>
                    <div className="w-7 h-7 rounded-lg bg-[#1B5888] text-white flex items-center justify-center shrink-0">
                      <Home className="w-3.5 h-3.5" />
                    </div>
                    <h2 className="text-sm sm:text-base font-bold text-slate-900 tracking-tight truncate">
                      {p.title}
                    </h2>
                    <span
                      className={`hidden md:inline-flex items-center px-2 py-0.5 rounded-full text-[11px] font-semibold shrink-0 ${p.is_occupied && propContract && !isActivelyListedInPortfolio
                          ? "bg-[#EAF5EE] text-[#2A6E43] border border-[#2A6E43]/20"
                          : "bg-slate-100 text-slate-600 border border-slate-200"
                        }`}
                    >
                      {p.is_occupied && propContract && !isActivelyListedInPortfolio
                        ? t("agency_props_status_occupied")
                        : t("agency_props_status_vacant")}
                    </span>
                  </div>

                  {/* Inline Merged Tabs */}
                  <div className="flex items-center gap-1 overflow-x-auto no-scrollbar shrink-0">
                    <button
                      type="button"
                      role="tab"
                      aria-selected={propertyDrawerTab === "overview"}
                      onClick={() => setPropertyDrawerTab("overview")}
                      className={`py-1.5 px-2.5 rounded-lg text-xs font-bold transition-all flex items-center gap-1.5 cursor-pointer whitespace-nowrap ${propertyDrawerTab === "overview"
                          ? "bg-[#E5EEF6] text-[#1B5888]"
                          : "text-[#666666] hover:text-[#1A1A1A] hover:bg-slate-100"
                        }`}
                    >
                      <Home className="w-3.5 h-3.5 shrink-0" />
                      <span className="hidden sm:inline">{t("agency_prop_tab_overview")}</span>
                    </button>
                    <button
                      type="button"
                      role="tab"
                      aria-selected={propertyDrawerTab === "payments"}
                      onClick={() => setPropertyDrawerTab("payments")}
                      className={`py-1.5 px-2.5 rounded-lg text-xs font-bold transition-all flex items-center gap-1.5 cursor-pointer whitespace-nowrap ${propertyDrawerTab === "payments"
                          ? "bg-[#E5EEF6] text-[#1B5888]"
                          : "text-[#666666] hover:text-[#1A1A1A] hover:bg-slate-100"
                        }`}
                    >
                      <Receipt className="w-3.5 h-3.5 shrink-0" />
                      <span className="hidden sm:inline">{t("agency_prop_drawer_tab_payments")}</span>
                      <span className="text-[10px] px-1.5 py-0.5 rounded-full bg-white/80 font-bold tabular-nums">
                        {propPayments.length}
                      </span>
                    </button>
                    <button
                      type="button"
                      role="tab"
                      aria-selected={propertyDrawerTab === "maintenance"}
                      onClick={() => setPropertyDrawerTab("maintenance")}
                      className={`py-1.5 px-2.5 rounded-lg text-xs font-bold transition-all flex items-center gap-1.5 cursor-pointer whitespace-nowrap ${propertyDrawerTab === "maintenance"
                          ? "bg-[#E5EEF6] text-[#1B5888]"
                          : "text-[#666666] hover:text-[#1A1A1A] hover:bg-slate-100"
                        }`}
                    >
                      <Wrench className="w-3.5 h-3.5 shrink-0" />
                      <span className="hidden sm:inline">{t("agency_prop_drawer_tab_maintenance")}</span>
                      <span className="text-[10px] px-1.5 py-0.5 rounded-full bg-white/80 font-bold tabular-nums">
                        {propMaintenance.length}
                      </span>
                    </button>
                    <button
                      type="button"
                      role="tab"
                      aria-selected={propertyDrawerTab === "audit"}
                      onClick={() => setPropertyDrawerTab("audit")}
                      className={`py-1.5 px-2.5 rounded-lg text-xs font-bold transition-all flex items-center gap-1.5 cursor-pointer whitespace-nowrap ${propertyDrawerTab === "audit"
                          ? "bg-[#E5EEF6] text-[#1B5888]"
                          : "text-[#666666] hover:text-[#1A1A1A] hover:bg-slate-100"
                        }`}
                    >
                      <Clock className="w-3.5 h-3.5 shrink-0" />
                      <span className="hidden sm:inline">{t("agency_prop_tab_activity")}</span>
                    </button>
                  </div>
                </div>
              ) : (
                /* Expanded Header + Action Bar + Integrated Tabs */
                <div className="flex flex-col gap-4">
                  <div className="flex items-start sm:items-center gap-4 min-w-0">
                    <div className="w-12 h-12 rounded-xl bg-[#1B5888] text-white flex items-center justify-center shrink-0 shadow-xs">
                      <Home className="w-6 h-6" />
                    </div>
                    <div className="min-w-0 flex-1 space-y-1">
                      <div className="flex items-center gap-2.5 flex-wrap">
                        <h2 className="text-xl sm:text-2xl font-bold text-slate-900 tracking-tight break-words">
                          {p.title}
                        </h2>
                        <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold shrink-0 ${p.is_occupied && propContract && !isActivelyListedInPortfolio
                          ? "bg-[#EAF5EE] text-[#2A6E43] border border-[#2A6E43]/20"
                          : "bg-slate-100 text-slate-600 border border-slate-200"
                          }`}>
                          {p.is_occupied && propContract && !isActivelyListedInPortfolio
                            ? t("agency_props_status_occupied")
                            : t("agency_props_status_vacant")}
                        </span>
                        {isActivelyListedInPortfolio && (
                          <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-semibold shrink-0 bg-[#EFF6FF] text-[#1B5888] border border-[#BFDBFE]">
                            <CheckCircle2 className="w-3.5 h-3.5" />
                            <span>{t("agency_prop_banner_listed_badge")}</span>
                          </span>
                        )}
                        {(() => {
                          const propEopCount = eopRecords.filter(
                            (r) =>
                              r.property_id === p.id ||
                              (p.last_listing_id && r.listing_id === p.last_listing_id)
                          ).length;
                          if (propEopCount === 0 || !onViewPropertyEop) return null;
                          return (
                            <button
                              type="button"
                              onClick={() => onViewPropertyEop(p.id)}
                              className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-semibold shrink-0 bg-[#E5EEF6] text-[#1B5888] border border-[#1B5888]/25 hover:bg-[#1B5888] hover:text-white transition-colors cursor-pointer"
                            >
                              <span>{t("eop_badge_active_eop")} ({propEopCount})</span>
                            </button>
                          );
                        })()}
                        {(() => {
                          const ownerNames = Array.isArray(p.owners)
                            ? p.owners.map((o: any) => o?.full_name || o?.name)
                            : [];
                          const rejAml = findRejectedAmlForContext(amlRecords, {
                            propertyId: p.id,
                            listingId: p.last_listing_id || null,
                            clientNames: [p.landlord_name, p.active_tenant_name, ...ownerNames],
                            eopRecords,
                          });
                          if (!rejAml) return null;
                          return (
                            <button
                              type="button"
                              onClick={() => onOpenAmlModal?.({ mode: "edit", existingRecord: rejAml })}
                              title={`${t("aml_warn_client_rejected")} (${rejAml.aml_ref_no})`}
                              className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-semibold shrink-0 bg-rose-50 text-rose-700 border border-rose-200 hover:bg-rose-600 hover:text-white transition-colors cursor-pointer"
                            >
                              <AlertTriangle className="w-3.5 h-3.5" />
                              <span>{t("aml_eop_badge_rejected")} ({rejAml.aml_ref_no})</span>
                            </button>
                          );
                        })()}
                      </div>
                      <p className="text-xs sm:text-sm text-slate-500">
                        {p.address}{p.city ? `, ${p.city}` : ""}
                      </p>
                    </div>
                  </div>

                  {/* Action Bar (Single-Row Priority+ Overflow into More Dropdown) */}
                  {(() => {
                    const specs = [
                      p.area_sqm ? `${p.area_sqm} m²` : null,
                      p.room_count || null,
                      p.floor ? `${p.floor}` : null,
                    ].filter(Boolean).join(", ");
                    const addr = [p.address, p.unit_number ? `#${p.unit_number}` : null, p.city]
                      .filter(Boolean)
                      .join(", ");

                    type ActionItem = {
                      key: string;
                      label: string;
                      className: string;
                      onClick: () => void;
                    };

                    const primaryActions: ActionItem[] = [];

                    if (onCreateTask) {
                      primaryActions.push({
                        key: "add_task",
                        label: t("agency_tasks_quick_btn"),
                        className:
                          "px-4 py-2 rounded-xl border border-[#1B5888]/30 text-xs font-semibold text-[#1B5888] hover:bg-[#E5EEF6] transition-colors cursor-pointer bg-white whitespace-nowrap shrink-0",
                        onClick: () =>
                          onCreateTask({
                            source_type: "property",
                            property_id: p.id,
                            title: p.title || p.address || "",
                          }),
                      });
                    }

                    if (onOpenEopModal) {
                      primaryActions.push({
                        key: "eop",
                        label: t("eop_btn_add_eop"),
                        className:
                          "px-4 py-2 rounded-xl border border-[#1B5888]/30 text-xs font-semibold text-[#1B5888] hover:bg-[#E5EEF6] transition-colors cursor-pointer bg-white whitespace-nowrap shrink-0",
                        onClick: () =>
                          onOpenEopModal({
                            mode: "create",
                            property_id: p.id,
                            listing_id: p.last_listing_id || null,
                            lease_contract_id: p.active_contract_id || null,
                            transaction_type: "izdavanje",
                            client_role: "landlord",
                            client_name: p.landlord_name || "",
                            client_phone: p.landlord_phone || "",
                            client_email: p.landlord_email || "",
                            property_type: p.property_type || "apartment",
                            property_address: addr || p.title || "",
                            property_specs: specs,
                            asking_price: p.default_monthly_rent || null,
                            currency: p.currency || "EUR",
                          }),
                      });
                    }

                    primaryActions.push({
                      key: "add_bill",
                      label: t("agency_prop_btn_add_bill_expense"),
                      className:
                        "px-4 py-2 rounded-xl border border-slate-300 text-xs font-semibold text-slate-700 hover:bg-slate-50 hover:text-slate-900 transition-colors cursor-pointer bg-white whitespace-nowrap shrink-0",
                      onClick: () => {
                        if (isDemoMode && !isDemoVerified) {
                          onRequestVerification?.();
                          return;
                        }
                        setIsAddPaymentModalOpen(true);
                      },
                    });

                    primaryActions.push({
                      key: "report_issue",
                      label: t("agency_prop_btn_report_issue"),
                      className:
                        "px-4 py-2 rounded-xl border border-slate-300 text-xs font-semibold text-slate-700 hover:bg-slate-50 hover:text-slate-900 transition-colors cursor-pointer bg-white whitespace-nowrap shrink-0",
                      onClick: () => {
                        if (isDemoMode && !isDemoVerified) {
                          onRequestVerification?.();
                          return;
                        }
                        setNewMaintPropId(p.id);
                        setIsNewMaintModalOpen(true);
                      },
                    });

                    const visibleActions = primaryActions.slice(0, visibleActionCount);
                    const overflowActions = primaryActions.slice(visibleActionCount);

                    return (
                      <div
                        ref={actionBarRef}
                        className="relative pt-3.5 border-t border-slate-100 flex items-center gap-2 flex-nowrap"
                      >
                        {/* Invisible width measurement mirror so widening restores overflowed buttons */}
                        <div
                          ref={measureBarRef}
                          aria-hidden="true"
                          className="pointer-events-none invisible absolute left-0 top-0 flex items-center gap-2 whitespace-nowrap"
                        >
                          {primaryActions.map((act) => (
                            <span key={act.key} className={act.className}>
                              {act.label}
                            </span>
                          ))}
                        </div>

                        {visibleActions.map((act) => (
                          <button
                            key={act.key}
                            type="button"
                            onClick={act.onClick}
                            className={act.className}
                          >
                            {act.label}
                          </button>
                        ))}

                        <div className="relative ml-auto shrink-0">
                          <button
                            ref={moreBtnRef}
                            type="button"
                            onClick={() => setMoreMenuOpen(!moreMenuOpen)}
                            className="px-4 py-2 rounded-xl border border-slate-300 text-xs font-semibold text-slate-700 hover:bg-slate-50 hover:text-slate-900 transition-colors cursor-pointer bg-white inline-flex items-center gap-1.5 whitespace-nowrap"
                          >
                            <span>{t("agency_prop_btn_more")}</span>
                            <ChevronDown className="w-3.5 h-3.5" />
                          </button>

                          {moreMenuOpen && (
                            <>
                              <div
                                className="fixed inset-0 z-20"
                                onClick={() => setMoreMenuOpen(false)}
                                aria-hidden="true"
                              />
                              <div className="absolute right-0 mt-1.5 w-56 bg-white rounded-xl shadow-lg border border-slate-200 py-1.5 z-30 animate-in fade-in duration-100">
                                {overflowActions.length > 0 && (
                                  <div className="pb-1.5 mb-1.5 border-b border-slate-100">
                                    {overflowActions.map((act) => (
                                      <button
                                        key={act.key}
                                        type="button"
                                        onClick={() => {
                                          setMoreMenuOpen(false);
                                          act.onClick();
                                        }}
                                        className="w-full text-left px-3.5 py-2 text-xs font-semibold text-slate-800 hover:bg-slate-50 flex items-center gap-2 cursor-pointer"
                                      >
                                        <span>{act.label}</span>
                                      </button>
                                    ))}
                                  </div>
                                )}
                                <button
                                  type="button"
                                  onClick={() => {
                                    setMoreMenuOpen(false);
                                    inspectProperty(p);
                                  }}
                                  className="w-full text-left px-3.5 py-2 text-xs font-medium text-slate-700 hover:bg-slate-50 flex items-center gap-2 cursor-pointer"
                                >
                                  <RefreshCw className="w-3.5 h-3.5 text-slate-400" />
                                  <span>{t("agency_prop_refresh_plan")}</span>
                                </button>
                                <button
                                  type="button"
                                  onClick={() => {
                                    setMoreMenuOpen(false);
                                    setEditingOwnersProperty(p);
                                  }}
                                  className="w-full text-left px-3.5 py-2 text-xs font-medium text-slate-700 hover:bg-slate-50 flex items-center gap-2 cursor-pointer"
                                >
                                  <UserCog className="w-3.5 h-3.5 text-slate-400" />
                                  <span>{t("agency_ownership_btn_edit")}</span>
                                </button>
                                <button
                                  type="button"
                                  onClick={() => {
                                    setMoreMenuOpen(false);
                                    openRelistModal(p);
                                  }}
                                  className="w-full text-left px-3.5 py-2 text-xs font-medium text-slate-700 hover:bg-slate-50 flex items-center gap-2 cursor-pointer"
                                >
                                  <PlusCircle className="w-3.5 h-3.5 text-slate-400" />
                                  <span>{t("agency_bridge_btn_relist_or_update")}</span>
                                </button>
                                {propContract?.contract_url && (
                                  <a
                                    href={propContract.contract_url}
                                    target="_blank"
                                    rel="noopener noreferrer"
                                    onClick={() => setMoreMenuOpen(false)}
                                    className="w-full text-left px-3.5 py-2 text-xs font-medium text-slate-700 hover:bg-slate-50 flex items-center gap-2"
                                  >
                                    <FileDown className="w-3.5 h-3.5 text-slate-400" />
                                    <span>{t("agency_contract_view_pdf")}</span>
                                  </a>
                                )}
                              </div>
                            </>
                          )}
                        </div>
                      </div>
                    );
                  })()}

                  {/* Integrated Tab Bar (bottom of expanded header card) */}
                  <div className="flex items-center gap-1 sm:gap-2 border-t border-slate-100 pt-1 -mx-5 sm:-mx-6 px-5 sm:px-6 overflow-x-auto no-scrollbar">
                    <button
                      type="button"
                      role="tab"
                      aria-selected={propertyDrawerTab === "overview"}
                      onClick={() => setPropertyDrawerTab("overview")}
                      className={`py-3 px-3 sm:px-4 text-xs font-bold border-b-2 transition-all flex items-center gap-2 cursor-pointer whitespace-nowrap ${propertyDrawerTab === "overview"
                          ? "border-[#1B5888] text-[#1B5888]"
                          : "border-transparent text-[#666666] hover:text-[#1A1A1A] hover:border-slate-300"
                        }`}
                    >
                      <Home className={`w-4 h-4 shrink-0 ${propertyDrawerTab === "overview" ? "text-[#1B5888]" : "text-[#8A8A8A]"}`} />
                      <span>{t("agency_prop_tab_overview")}</span>
                    </button>
                    <button
                      type="button"
                      role="tab"
                      aria-selected={propertyDrawerTab === "payments"}
                      onClick={() => setPropertyDrawerTab("payments")}
                      className={`py-3 px-3 sm:px-4 text-xs font-bold border-b-2 transition-all flex items-center gap-2 cursor-pointer whitespace-nowrap ${propertyDrawerTab === "payments"
                          ? "border-[#1B5888] text-[#1B5888]"
                          : "border-transparent text-[#666666] hover:text-[#1A1A1A] hover:border-slate-300"
                        }`}
                    >
                      <Receipt className={`w-4 h-4 shrink-0 ${propertyDrawerTab === "payments" ? "text-[#1B5888]" : "text-[#8A8A8A]"}`} />
                      <span>{t("agency_prop_drawer_tab_payments")}</span>
                      <span className={`text-[11px] px-2 py-0.5 rounded-full font-bold tabular-nums shrink-0 ml-0.5 ${propertyDrawerTab === "payments" ? "bg-[#E5EEF6] text-[#1B5888]" : "bg-slate-100 text-[#666666]"
                        }`}>
                        {propPayments.length}
                      </span>
                    </button>
                    <button
                      type="button"
                      role="tab"
                      aria-selected={propertyDrawerTab === "maintenance"}
                      onClick={() => setPropertyDrawerTab("maintenance")}
                      className={`py-3 px-3 sm:px-4 text-xs font-bold border-b-2 transition-all flex items-center gap-2 cursor-pointer whitespace-nowrap ${propertyDrawerTab === "maintenance"
                          ? "border-[#1B5888] text-[#1B5888]"
                          : "border-transparent text-[#666666] hover:text-[#1A1A1A] hover:border-slate-300"
                        }`}
                    >
                      <Wrench className={`w-4 h-4 shrink-0 ${propertyDrawerTab === "maintenance" ? "text-[#1B5888]" : "text-[#8A8A8A]"}`} />
                      <span>{t("agency_prop_drawer_tab_maintenance")}</span>
                      <span className={`text-[11px] px-2 py-0.5 rounded-full font-bold tabular-nums shrink-0 ml-0.5 ${propertyDrawerTab === "maintenance" ? "bg-[#E5EEF6] text-[#1B5888]" : "bg-slate-100 text-[#666666]"
                        }`}>
                        {propMaintenance.length}
                      </span>
                    </button>
                    <button
                      type="button"
                      role="tab"
                      aria-selected={propertyDrawerTab === "audit"}
                      onClick={() => setPropertyDrawerTab("audit")}
                      className={`py-3 px-3 sm:px-4 text-xs font-bold border-b-2 transition-all flex items-center gap-2 cursor-pointer whitespace-nowrap ${propertyDrawerTab === "audit"
                          ? "border-[#1B5888] text-[#1B5888]"
                          : "border-transparent text-[#666666] hover:text-[#1A1A1A] hover:border-slate-300"
                        }`}
                    >
                      <Clock className={`w-4 h-4 shrink-0 ${propertyDrawerTab === "audit" ? "text-[#1B5888]" : "text-[#8A8A8A]"}`} />
                      <span>{t("agency_prop_tab_activity")}</span>
                    </button>
                  </div>
                </div>
              )}
            </div>

            {/* 3. Renewal / Expiration Banner OR Terminated / Listed Status Banner */}
            {isActivelyListedInPortfolio || (!propContract && (lastTerminatedContract || !p.is_occupied)) ? (
              <div
                className={`rounded-[10px] p-4 sm:p-5 border flex flex-col md:flex-row md:items-center md:justify-between gap-4 transition-all shadow-2xs ${isActivelyListedInPortfolio
                  ? "bg-[#EFF6FF] border-[#BFDBFE] text-[#1E3A8A]"
                  : "bg-slate-50 border-slate-200 text-slate-800"
                  }`}
              >
                <div className="space-y-1">
                  <div className="flex items-center gap-2 flex-wrap">
                    <span className="text-xs font-bold">
                      {lastTerminatedContract
                        ? t("agency_prop_banner_terminated_tag")
                        : t("agency_prop_banner_vacant_tag")}
                    </span>
                    {(lastTerminatedContract?.end_date ||
                      terminationLogForProp?.metadata?.termination_date) && (
                        <span className="font-bold text-sm sm:text-base">
                          •{" "}
                          {t("agency_prop_banner_terminated_msg", {
                            date: formatEuropeanDate(
                              terminationLogForProp?.metadata?.termination_date ||
                              lastTerminatedContract?.termination_date ||
                              lastTerminatedContract?.end_date
                            ),
                          })}
                        </span>
                      )}
                    {isActivelyListedInPortfolio && (
                      <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[11px] font-bold bg-[#1B5888] text-white">
                        <CheckCircle2 className="w-3 h-3" />
                        <span>{t("agency_prop_banner_listed_badge")}</span>
                      </span>
                    )}
                  </div>
                  <p className="text-xs leading-relaxed opacity-90">
                    {isActivelyListedInPortfolio
                      ? t("agency_prop_banner_listed_desc", {
                        price: `${Number(
                          linkedPortfolioListing?.price || p.default_monthly_rent || 0
                        ).toLocaleString("de-DE")} ${linkedPortfolioListing?.currency || p.currency || "EUR"
                          }`,
                      })
                      : t("agency_prop_banner_vacant_desc")}
                  </p>
                </div>

                <div className="flex items-center gap-2 flex-wrap shrink-0">
                  {isActivelyListedInPortfolio && setActiveTab ? (
                    <button
                      type="button"
                      onClick={() => setActiveTab("listings")}
                      className="px-4 py-2.5 rounded-xl bg-white hover:bg-slate-50 text-[#1B5888] border border-[#1B5888]/30 font-bold text-xs sm:text-sm shadow-2xs transition-colors cursor-pointer shrink-0 inline-flex items-center gap-1.5"
                    >
                      <ExternalLink className="w-4 h-4" />
                      <span>{t("agency_prop_banner_btn_view_listing")}</span>
                    </button>
                  ) : (
                    <button
                      type="button"
                      onClick={() => openRelistModal(p)}
                      className="px-4 py-2.5 rounded-xl bg-white hover:bg-slate-50 text-[#1B5888] border border-[#1B5888]/30 font-bold text-xs sm:text-sm shadow-2xs transition-colors cursor-pointer shrink-0 inline-flex items-center gap-1.5"
                    >
                      <PlusCircle className="w-4 h-4" />
                      <span>{t("agency_bridge_btn_relist_or_update")}</span>
                    </button>
                  )}
                  <button
                    type="button"
                    onClick={() => openNewContractModal(p)}
                    className="px-5 py-2.5 rounded-xl bg-[#1B5888] hover:bg-[#12406A] active:bg-[#12406A] text-white font-bold text-xs sm:text-sm shadow-xs transition-colors cursor-pointer shrink-0"
                  >
                    {t("agency_contract_btn_new_contract")}
                  </button>
                </div>
              </div>
            ) : bannerSeverity && propContract ? (
              <div
                className={`rounded-[10px] p-4 sm:p-5 border flex flex-col md:flex-row md:items-center md:justify-between gap-4 transition-all shadow-2xs ${bannerSeverity === "red"
                  ? "bg-[#FEF2F2] border-[#FCA5A5] text-[#991B1B]"
                  : bannerSeverity === "orange"
                    ? "bg-[#FFF7ED] border-[#FDBA74] text-[#C2410C]"
                    : "bg-[#FEFCE8] border-[#FDE047] text-[#854D0E]"
                  }`}
              >
                <div className="space-y-1">
                  <div className="flex items-center gap-2 flex-wrap">
                    <span className="text-xs font-bold">
                      {isContractExpired
                        ? t("agency_prop_renew_tag_ended")
                        : bannerSeverity === "yellow"
                          ? t("agency_prop_renew_tag_renewal_approaching")
                          : t("agency_prop_renew_tag_ending_soon")}
                    </span>
                    <span className="font-bold text-sm sm:text-base">
                      {isContractExpired
                        ? t("agency_prop_renew_msg_ended", {
                          date: formatEuropeanDate(propContract.end_date),
                          days: String(daysSinceExpired),
                        })
                        : t("agency_prop_renew_msg_ending", {
                          date: formatEuropeanDate(propContract.end_date),
                          days: String(contractRemainingDays),
                        })}
                    </span>
                  </div>
                  <p className="text-xs leading-relaxed opacity-90">
                    {t("agency_prop_renew_banner_desc")}
                  </p>
                </div>

                <div className="flex items-center gap-2 flex-wrap shrink-0">
                  <button
                    type="button"
                    onClick={() => openRelistModal(p)}
                    className="px-4 py-2.5 rounded-xl bg-white hover:bg-slate-50 text-[#1B5888] border border-[#1B5888]/30 font-bold text-xs sm:text-sm shadow-2xs transition-colors cursor-pointer shrink-0 inline-flex items-center gap-1.5"
                  >
                    <PlusCircle className="w-4 h-4" />
                    <span>{t("agency_bridge_btn_relist_or_update")}</span>
                  </button>
                  <button
                    type="button"
                    onClick={() => openRenewContractModal(propContract)}
                    className="px-5 py-2.5 rounded-xl bg-[#1B5888] hover:bg-[#12406A] active:bg-[#12406A] text-white font-bold text-xs sm:text-sm shadow-xs transition-colors cursor-pointer shrink-0"
                  >
                    {t("agency_prop_renew_banner_btn")}
                  </button>
                </div>
              </div>
            ) : null}

            {/* 5. Tab Body Content */}
            <div className="space-y-6 pt-2">
              {/* 1. PAYMENTS / FINANCIALS TAB (Flutter _FinancialsTab) */}
              {propertyDrawerTab === "payments" && (
                <div className="space-y-5 animate-in fade-in duration-150">
                  {/* Interactive Financial Filter Card Deck (Flutter _FinancialsTab SSOT) */}
                  <div className="bg-slate-50/75 p-4 rounded-[10px] border border-[#E5E3DF] space-y-4">
                    {/* Filter Deck Header with Dedicated Filter Title & Collapse Toggle */}
                    <div
                      onClick={() => setIsFilterDeckOpen((prev) => !prev)}
                      className="flex items-center justify-between gap-3 cursor-pointer select-none"
                    >
                      <div className="flex items-center gap-2">
                        <SlidersHorizontal className="w-4 h-4 text-[#1B5888]" />
                        <span className="text-xs font-bold text-[#1A1A1A]">
                          {t("agency_financials_filter_title")}
                        </span>
                        {hasActiveFilter && (
                          <div className="flex items-center gap-1.5 ml-1" onClick={(e) => e.stopPropagation()}>
                            <span className="w-2 h-2 rounded-full bg-[#1B5888] animate-pulse" />
                            <button
                              type="button"
                              onClick={() => {
                                setFinancialStatusFilter("all");
                                setFinancialTypeFilter("all");
                                setFinancialDueDateFilter("all");
                              }}
                              className="text-xs font-bold text-[#1B5888] hover:text-blue-800 px-2 py-0.5 rounded-lg bg-[#E5EEF6] hover:bg-[#E5EEF6] transition-colors cursor-pointer"
                            >
                              {t("agency_panel_clear_filters_btn")}
                            </button>
                          </div>
                        )}
                      </div>

                      <div className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-[10px] text-xs font-semibold text-[#4A4A4A] hover:bg-slate-200/60 transition-colors">
                        <span>{isFilterDeckOpen ? t("agency_filter_collapse") : t("agency_filter_expand")}</span>
                        {isFilterDeckOpen ? (
                          <ChevronUp className="w-3.5 h-3.5 text-[#666666]" />
                        ) : (
                          <ChevronDown className="w-3.5 h-3.5 text-[#666666]" />
                        )}
                      </div>
                    </div>

                    {/* Collapsible Filter Cards Body */}
                    {isFilterDeckOpen && (
                      <div className="space-y-4 pt-2 border-t border-[#E5E3DF] animate-in fade-in duration-150">

                        {/* Section 1: STATUS (DURUM) */}
                        <div>
                          <span className="text-xs font-semibold text-[#666666] block mb-2">
                            {t("agency_filter_sec_status")}
                          </span>
                          <div className="grid grid-cols-2 sm:grid-cols-4 gap-2.5">
                            {/* Chip 1: Unentered (Fatura Bekleyen) */}
                            <button
                              type="button"
                              onClick={() => setFinancialStatusFilter((prev) => (prev === "unentered" ? "all" : "unentered"))}
                              className={`p-3 rounded-[10px] border text-left transition-all cursor-pointer flex flex-col justify-between ${financialStatusFilter === "unentered"
                                ? "bg-amber-500/10 border-amber-500 ring-2 ring-amber-500/20 shadow-xs"
                                : "bg-white border-[#E5E3DF] hover:border-[#8A8A8A] hover:bg-slate-50/50"
                                }`}
                            >
                              <div className="flex items-center justify-between">
                                <FileQuestion className={`w-4 h-4 ${financialStatusFilter === "unentered" ? "text-[#8A5206]" : "text-[#666666]"}`} />
                                <span className={`text-xs font-bold px-2 py-0.5 rounded-full ${financialStatusFilter === "unentered" ? "bg-amber-500 text-white" : "bg-[#F8F7F5] text-[#666666] border border-[#E5E3DF]"
                                  }`}>
                                  {unenteredCount}
                                </span>
                              </div>
                              <div className="mt-2 min-w-0">
                                <p className="text-xs font-bold text-[#1A1A1A] truncate">{t("agency_chip_unentered")}</p>
                                <p className="text-[10px] text-[#666666] truncate">{t("agency_chip_unentered_sub")}</p>
                              </div>
                            </button>

                            {/* Chip 2: Pending (Bekleyen) */}
                            <button
                              type="button"
                              onClick={() => setFinancialStatusFilter((prev) => (prev === "pending" ? "all" : "pending"))}
                              className={`p-3 rounded-[10px] border text-left transition-all cursor-pointer flex flex-col justify-between ${financialStatusFilter === "pending"
                                ? "bg-[#E5EEF6] border-[#1B5888] ring-2 ring-[#1B5888]/20 shadow-xs"
                                : "bg-white border-[#E5E3DF] hover:border-[#8A8A8A] hover:bg-slate-50/50"
                                }`}
                            >
                              <div className="flex items-center justify-between">
                                <Clock className={`w-4 h-4 ${financialStatusFilter === "pending" ? "text-[#1B5888]" : "text-[#666666]"}`} />
                                <span className={`text-xs font-bold px-2 py-0.5 rounded-full ${financialStatusFilter === "pending" ? "bg-[#1B5888] text-white" : "bg-[#F8F7F5] text-[#666666] border border-[#E5E3DF]"
                                  }`}>
                                  {pendingCount}
                                </span>
                              </div>
                              <div className="mt-2 min-w-0">
                                <p className="text-xs font-bold text-[#1A1A1A] truncate">{t("agency_chip_pending")}</p>
                                <p className="text-[10px] text-[#666666] truncate">{t("agency_chip_pending_sub")}</p>
                              </div>
                            </button>

                            {/* Chip 3: Awaiting (Onay Bekleyen) */}
                            <button
                              type="button"
                              onClick={() => setFinancialStatusFilter((prev) => (prev === "awaiting" ? "all" : "awaiting"))}
                              className={`p-3 rounded-[10px] border text-left transition-all cursor-pointer flex flex-col justify-between ${financialStatusFilter === "awaiting"
                                ? "bg-amber-600/10 border-amber-600 ring-2 ring-amber-600/20 shadow-xs"
                                : "bg-white border-[#E5E3DF] hover:border-[#8A8A8A] hover:bg-slate-50/50"
                                }`}
                            >
                              <div className="flex items-center justify-between">
                                <AlertCircle className={`w-4 h-4 ${financialStatusFilter === "awaiting" ? "text-[#8A5206]" : "text-[#666666]"}`} />
                                <span className={`text-xs font-bold px-2 py-0.5 rounded-full ${financialStatusFilter === "awaiting" ? "bg-amber-600 text-white animate-pulse" : "bg-[#F8F7F5] text-[#666666] border border-[#E5E3DF]"
                                  }`}>
                                  {awaitingCount}
                                </span>
                              </div>
                              <div className="mt-2 min-w-0">
                                <p className="text-xs font-bold text-[#1A1A1A] truncate">{t("agency_chip_awaiting")}</p>
                                <p className="text-[10px] text-[#666666] truncate">{t("agency_chip_awaiting_sub")}</p>
                              </div>
                            </button>

                            {/* Chip 4: Paid (Ödenen) */}
                            <button
                              type="button"
                              onClick={() => setFinancialStatusFilter((prev) => (prev === "paid" ? "all" : "paid"))}
                              className={`p-3 rounded-[10px] border text-left transition-all cursor-pointer flex flex-col justify-between ${financialStatusFilter === "paid"
                                ? "bg-[#1B5888]/10 border-emerald-600 ring-2 ring-emerald-600/20 shadow-xs"
                                : "bg-white border-[#E5E3DF] hover:border-[#8A8A8A] hover:bg-slate-50/50"
                                }`}
                            >
                              <div className="flex items-center justify-between">
                                <CheckCircle2 className={`w-4 h-4 ${financialStatusFilter === "paid" ? "text-[#2A6E43]" : "text-[#666666]"}`} />
                                <span className={`text-xs font-bold px-2 py-0.5 rounded-full ${financialStatusFilter === "paid" ? "bg-[#1B5888] text-white" : "bg-[#F8F7F5] text-[#666666] border border-[#E5E3DF]"
                                  }`}>
                                  {paidCount}
                                </span>
                              </div>
                              <div className="mt-2 min-w-0">
                                <p className="text-xs font-bold text-[#1A1A1A] truncate">{t("agency_chip_paid")}</p>
                                <p className="text-[10px] text-[#666666] truncate">{t("agency_chip_paid_sub")}</p>
                              </div>
                            </button>
                          </div>
                        </div>

                        {/* Section 2: DEBT TYPE (BORÇ TİPİ) */}
                        <div>
                          <span className="text-xs font-semibold text-[#666666] block mb-2">
                            {t("agency_filter_sec_debt_type")}
                          </span>
                          <div className="grid grid-cols-2 sm:grid-cols-3 gap-2.5">
                            {/* Rent Chip */}
                            <button
                              type="button"
                              onClick={() => setFinancialTypeFilter((prev) => (prev === "rent" ? "all" : "rent"))}
                              className={`p-3 rounded-[10px] border text-left transition-all cursor-pointer flex flex-col justify-between ${financialTypeFilter === "rent"
                                ? "bg-[#E5EEF6] border-[#1B5888] ring-2 ring-[#1B5888]/20 shadow-xs"
                                : "bg-white border-[#E5E3DF] hover:border-[#8A8A8A] hover:bg-slate-50/50"
                                }`}
                            >
                              <div className="flex items-center justify-between">
                                <Home className={`w-4 h-4 ${financialTypeFilter === "rent" ? "text-[#1B5888]" : "text-[#666666]"}`} />
                                <span className={`text-xs font-bold px-2 py-0.5 rounded-full ${financialTypeFilter === "rent" ? "bg-[#1B5888] text-white" : "bg-[#F8F7F5] text-[#666666] border border-[#E5E3DF]"
                                  }`}>
                                  {rentCount}
                                </span>
                              </div>
                              <div className="mt-2 min-w-0">
                                <p className="text-xs font-bold text-[#1A1A1A] truncate">{t("agency_chip_rent")}</p>
                                <p className="text-[10px] text-[#666666] truncate">{t("agency_chip_rent_sub")}</p>
                              </div>
                            </button>

                            {/* Bills Chip */}
                            <button
                              type="button"
                              onClick={() => setFinancialTypeFilter((prev) => (prev === "bills" ? "all" : "bills"))}
                              className={`p-3 rounded-[10px] border text-left transition-all cursor-pointer flex flex-col justify-between ${financialTypeFilter === "bills"
                                ? "bg-[#E5EEF6] border-[#1B5888] ring-2 ring-[#1B5888]/20 shadow-xs"
                                : "bg-white border-[#E5E3DF] hover:border-[#8A8A8A] hover:bg-slate-50/50"
                                }`}
                            >
                              <div className="flex items-center justify-between">
                                <Receipt className={`w-4 h-4 ${financialTypeFilter === "bills" ? "text-[#1B5888]" : "text-[#666666]"}`} />
                                <span className={`text-xs font-bold px-2 py-0.5 rounded-full ${financialTypeFilter === "bills" ? "bg-[#1B5888] text-white" : "bg-[#F8F7F5] text-[#666666] border border-[#E5E3DF]"
                                  }`}>
                                  {billsCount}
                                </span>
                              </div>
                              <div className="mt-2 min-w-0">
                                <p className="text-xs font-bold text-[#1A1A1A] truncate">{t("agency_chip_bills")}</p>
                                <p className="text-[10px] text-[#666666] truncate">{t("agency_chip_bills_sub")}</p>
                              </div>
                            </button>

                            {/* Maintenance Chip */}
                            <button
                              type="button"
                              onClick={() => setFinancialTypeFilter((prev) => (prev === "maintenance" ? "all" : "maintenance"))}
                              className={`p-3 rounded-[10px] border text-left transition-all cursor-pointer flex flex-col justify-between col-span-2 sm:col-span-1 ${financialTypeFilter === "maintenance"
                                ? "bg-purple-600/10 border-purple-600 ring-2 ring-purple-600/20 shadow-xs"
                                : "bg-white border-[#E5E3DF] hover:border-[#8A8A8A] hover:bg-slate-50/50"
                                }`}
                            >
                              <div className="flex items-center justify-between">
                                <Wrench className={`w-4 h-4 ${financialTypeFilter === "maintenance" ? "text-purple-600" : "text-[#666666]"}`} />
                                <span className={`text-xs font-bold px-2 py-0.5 rounded-full ${financialTypeFilter === "maintenance" ? "bg-purple-600 text-white" : "bg-[#F8F7F5] text-[#666666] border border-[#E5E3DF]"
                                  }`}>
                                  {maintenanceCount}
                                </span>
                              </div>
                              <div className="mt-2 min-w-0">
                                <p className="text-xs font-bold text-[#1A1A1A] truncate">{t("agency_chip_maint")}</p>
                                <p className="text-[10px] text-[#666666] truncate">{t("agency_chip_maint_sub")}</p>
                              </div>
                            </button>
                          </div>
                        </div>

                        {/* Section 3: DUE DATE (VADE DURUMU) */}
                        <div>
                          <span className="text-xs font-semibold text-[#666666] block mb-2">
                            {t("agency_filter_sec_due_date")}
                          </span>
                          <div className="grid grid-cols-2 gap-2.5">
                            {/* Overdue Chip */}
                            <button
                              type="button"
                              onClick={() => setFinancialDueDateFilter((prev) => (prev === "overdue" ? "all" : "overdue"))}
                              className={`p-3 rounded-[10px] border text-left transition-all cursor-pointer flex flex-col justify-between ${financialDueDateFilter === "overdue"
                                ? "bg-rose-600/10 border-rose-600 ring-2 ring-rose-600/20 shadow-xs"
                                : "bg-white border-[#E5E3DF] hover:border-[#8A8A8A] hover:bg-slate-50/50"
                                }`}
                            >
                              <div className="flex items-center justify-between">
                                <AlertTriangle className={`w-4 h-4 ${financialDueDateFilter === "overdue" ? "text-[#A33C29]" : "text-[#666666]"}`} />
                                <span className={`text-xs font-bold px-2 py-0.5 rounded-full ${financialDueDateFilter === "overdue" ? "bg-rose-600 text-white" : "bg-[#F8F7F5] text-[#666666] border border-[#E5E3DF]"
                                  }`}>
                                  {overdueCount}
                                </span>
                              </div>
                              <div className="mt-2 min-w-0">
                                <p className="text-xs font-bold text-[#1A1A1A] truncate">{t("agency_chip_overdue")}</p>
                                <p className="text-[10px] text-[#666666] truncate">{t("agency_chip_overdue_sub")}</p>
                              </div>
                            </button>

                            {/* Upcoming Chip */}
                            <button
                              type="button"
                              onClick={() => setFinancialDueDateFilter((prev) => (prev === "upcoming" ? "all" : "upcoming"))}
                              className={`p-3 rounded-[10px] border text-left transition-all cursor-pointer flex flex-col justify-between ${financialDueDateFilter === "upcoming"
                                ? "bg-[#E5EEF6] border-[#1B5888] ring-2 ring-[#1B5888]/20 shadow-xs"
                                : "bg-white border-[#E5E3DF] hover:border-[#8A8A8A] hover:bg-slate-50/50"
                                }`}
                            >
                              <div className="flex items-center justify-between">
                                <Calendar className={`w-4 h-4 ${financialDueDateFilter === "upcoming" ? "text-[#1B5888]" : "text-[#666666]"}`} />
                                <span className={`text-xs font-bold px-2 py-0.5 rounded-full ${financialDueDateFilter === "upcoming" ? "bg-[#1B5888] text-white" : "bg-[#F8F7F5] text-[#666666] border border-[#E5E3DF]"
                                  }`}>
                                  {upcomingCount}
                                </span>
                              </div>
                              <div className="mt-2 min-w-0">
                                <p className="text-xs font-bold text-[#1A1A1A] truncate">{t("agency_chip_upcoming")}</p>
                                <p className="text-[10px] text-[#666666] truncate">{t("agency_chip_upcoming_sub")}</p>
                              </div>
                            </button>
                          </div>
                        </div>
                      </div>
                    )}
                  </div>

                  {/* Maintenance & Repair Settlements Section (SSOT Flutter Parity) */}
                  {visibleMaintenanceSettlements.length > 0 && (
                    <div className="bg-white rounded-[10px] border border-blue-200/90 shadow-xs overflow-hidden">
                      {/* Header Bar */}
                      <div
                        onClick={() => setIsSettlementsSectionCollapsed((prev) => !prev)}
                        className="px-4 py-3 bg-gradient-to-r from-blue-50/60 to-white border-b border-blue-100 flex items-center justify-between gap-3 cursor-pointer select-none hover:bg-blue-50/80 transition-colors"
                      >
                        <div className="flex items-center gap-3">
                          <div className="w-8 h-8 rounded-lg bg-blue-100 text-[#1B5888] flex items-center justify-center shrink-0">
                            <Wrench className="w-4 h-4" />
                          </div>
                          <div>
                            <h4 className="text-xs font-bold text-slate-800">
                              {t("maintenanceSettlementsHeader")}
                            </h4>
                            <p className="text-[11px] text-slate-500 font-medium">
                              {t("maintenanceSettlementsSub")}
                            </p>
                          </div>
                        </div>

                        <div className="flex items-center gap-2">
                          <span className="px-2.5 py-0.5 rounded-full text-xs font-bold bg-blue-100 text-[#1B5888] border border-blue-200">
                            • {visibleMaintenanceSettlements.length}
                          </span>
                          {isSettlementsSectionCollapsed ? (
                            <ChevronRight className="w-4 h-4 text-slate-400" />
                          ) : (
                            <ChevronUp className="w-4 h-4 text-slate-400" />
                          )}
                        </div>
                      </div>

                      {/* Settlements List */}
                      {!isSettlementsSectionCollapsed && (
                        <div className="p-3 space-y-2.5 bg-slate-50/40">
                          {visibleMaintenanceSettlements.map((req) => {
                            const cost = req.cost_amount || 0;
                            const settled = req.settled_amount || 0;
                            const remaining = Math.max(0, cost - settled);
                            const cur = req.currency || p.currency || "EUR";
                            const isPendingReview =
                              req.payment_status === "pending_review" ||
                              req.payment_status === "pending_agency_approval" ||
                              req.payment_status === "pending_opposite_approval";
                            const isAgencyPaid = req.paid_by === "agency";
                            const isAgencyTenantDamage =
                              isAgencyPaid && req.declaration_intent === "damage_tenant";
                            const isDeductFromRent =
                              req.paid_by === "tenant" && req.payment_status !== "paid";
                            const isAddToRent = req.paid_by === "landlord" || isAgencyTenantDamage;

                            const isExpanded =
                              expandedSettlementIds.has(req.id) ||
                              (isPendingReview && !expandedSettlementIds.has(`collapsed_${req.id}`));

                            const toggleExpanded = () => {
                              setExpandedSettlementIds((prev) => {
                                const next = new Set(prev);
                                if (isExpanded) {
                                  next.delete(req.id);
                                  if (isPendingReview) next.add(`collapsed_${req.id}`);
                                } else {
                                  next.add(req.id);
                                  next.delete(`collapsed_${req.id}`);
                                }
                                return next;
                              });
                            };

                            let settlementRoleLabel = "";
                            if (req.paid_by === "tenant") {
                              settlementRoleLabel = t("agency_maint_landlord_debt_sub");
                            } else if (req.paid_by === "landlord") {
                              settlementRoleLabel = t("agency_maint_tenant_debt_sub");
                            } else if (isAgencyPaid) {
                              settlementRoleLabel = isAgencyTenantDamage
                                ? t("agency_maint_tenant_debt_sub")
                                : t("agency_maint_landlord_debt_sub");
                            }

                            let infoBoxText = "";
                            if (isAgencyPaid) {
                              infoBoxText = isAgencyTenantDamage
                                ? t("maintInfoAgencyPaidTenantDamage")
                                : t("maintInfoAgencyPaidPropertyFixture");
                            } else if (isPendingReview) {
                              if (req.paid_by === "landlord") {
                                infoBoxText = t("maintInfoLandlordPaidDamageSettled");
                              } else {
                                infoBoxText = t("maintInfoTenantPaidFixturePendingAgency");
                              }
                            } else {
                              if (isDeductFromRent) {
                                infoBoxText = t("maintInfoTenantPaidFixtureSettled");
                              } else {
                                infoBoxText = t("maintInfoLandlordPaidDamageSettled");
                              }
                            }

                            const accentBorder = isPendingReview
                              ? "border-amber-300"
                              : isAgencyPaid
                                ? "border-purple-200"
                                : isDeductFromRent
                                  ? "border-blue-200"
                                  : "border-amber-200";

                            const accentBar = isPendingReview
                              ? "bg-amber-500"
                              : isAgencyPaid
                                ? "bg-purple-600"
                                : isDeductFromRent
                                  ? "bg-blue-600"
                                  : "bg-amber-500";

                            return (
                              <div
                                key={req.id}
                                className={`bg-white rounded-[12px] border ${accentBorder} p-3.5 hover:border-slate-400 transition-colors shadow-2xs relative overflow-hidden`}
                              >
                                <div className={`absolute left-0 top-0 bottom-0 w-1 ${accentBar} rounded-l`} />
                                <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 pl-1">
                                  <div
                                    onClick={toggleExpanded}
                                    className="flex items-center gap-3 min-w-0 cursor-pointer select-none flex-1"
                                  >
                                    <div
                                      className={`w-9 h-9 rounded-lg flex items-center justify-center shrink-0 ${isPendingReview
                                        ? "bg-amber-100 text-amber-700"
                                        : isAgencyPaid
                                          ? "bg-purple-100 text-purple-700"
                                          : isDeductFromRent
                                            ? "bg-blue-100 text-blue-700"
                                            : "bg-amber-100 text-amber-700"
                                        }`}
                                    >
                                      {isPendingReview ? (
                                        <Clock className="w-4 h-4" />
                                      ) : isDeductFromRent ? (
                                        <ArrowDownLeft className="w-4 h-4" />
                                      ) : (
                                        <ArrowUpRight className="w-4 h-4" />
                                      )}
                                    </div>
                                    <div className="min-w-0">
                                      <div className="flex items-center gap-2">
                                        <span
                                          className={`text-sm font-extrabold font-mono ${isPendingReview
                                            ? "text-amber-800"
                                            : isAgencyPaid
                                              ? "text-purple-700"
                                              : isDeductFromRent
                                                ? "text-blue-700"
                                                : "text-amber-700"
                                            }`}
                                        >
                                          {isDeductFromRent ? "- " : "+ "}
                                          {remaining.toLocaleString()} {cur}
                                        </span>
                                        <span className="text-[10px] font-bold px-1.5 py-0.5 rounded bg-slate-100 text-slate-600 font-mono">
                                          {req.ticket_number}
                                        </span>
                                      </div>
                                      <p className="text-xs text-slate-600 truncate mt-0.5 flex items-center gap-1">
                                        <span className="font-semibold text-slate-800">{req.title}</span>
                                        <span className="text-slate-400">•</span>
                                        <span className="text-slate-500">{settlementRoleLabel}</span>
                                        {req.invoice_pdf_url && (
                                          <Paperclip className="w-3 h-3 text-slate-400 shrink-0 inline ml-0.5" />
                                        )}
                                      </p>
                                    </div>
                                  </div>

                                  <div className="flex items-center gap-2 self-end sm:self-center shrink-0">
                                    {isPendingReview ? (
                                      <div className="flex items-center gap-2">
                                        <span className="px-2.5 py-1 rounded-full text-xs font-bold bg-amber-50 text-amber-800 border border-amber-300">
                                          {t("financialStatusPendingReview")}
                                        </span>
                                        <button
                                          type="button"
                                          onClick={toggleExpanded}
                                          className="p-1 rounded-lg text-slate-400 hover:text-slate-600 hover:bg-slate-100 transition-colors cursor-pointer"
                                        >
                                          {isExpanded ? (
                                            <ChevronUp className="w-4 h-4" />
                                          ) : (
                                            <ChevronDown className="w-4 h-4" />
                                          )}
                                        </button>
                                      </div>
                                    ) : isAgencyPaid && !isAgencyTenantDamage ? (
                                      <div className="flex items-center gap-2">
                                        <button
                                          type="button"
                                          disabled={isExecutingSettlementAction}
                                          onClick={() => handleApproveSettlement(req, true)}
                                          className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-bold transition-colors shadow-2xs cursor-pointer bg-purple-50 text-purple-800 border border-purple-200 hover:bg-emerald-50 hover:text-emerald-800 hover:border-emerald-300 disabled:opacity-50"
                                        >
                                          <CheckCircle2 className="w-3.5 h-3.5" />
                                          <span>{t("agency_maint_btn_mark_collected")}</span>
                                        </button>
                                        <button
                                          type="button"
                                          onClick={toggleExpanded}
                                          className="p-1 rounded-lg text-slate-400 hover:text-slate-600 hover:bg-slate-100 transition-colors cursor-pointer"
                                        >
                                          {isExpanded ? (
                                            <ChevronUp className="w-4 h-4" />
                                          ) : (
                                            <ChevronDown className="w-4 h-4" />
                                          )}
                                        </button>
                                      </div>
                                    ) : (
                                      <div className="flex items-center gap-2">
                                        <button
                                          type="button"
                                          onClick={() => {
                                            setSettlementOptionsReq(req);
                                            setIsSettlementOptionsModalOpen(true);
                                          }}
                                          className={`inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-bold transition-colors shadow-2xs cursor-pointer ${isAddToRent
                                            ? "bg-amber-50 text-amber-800 border border-amber-200 hover:bg-amber-100"
                                            : "bg-blue-50 text-blue-800 border border-blue-200 hover:bg-blue-100"
                                            }`}
                                        >
                                          <span>
                                            {isDeductFromRent
                                              ? t("agency_maint_btn_deduct_rent")
                                              : t("agency_maint_btn_add_rent")}
                                          </span>
                                          <ChevronDown className={`w-3.5 h-3.5 ${isAddToRent ? "text-amber-600" : "text-blue-600"}`} />
                                        </button>
                                        <button
                                          type="button"
                                          onClick={toggleExpanded}
                                          className="p-1 rounded-lg text-slate-400 hover:text-slate-600 hover:bg-slate-100 transition-colors cursor-pointer"
                                        >
                                          {isExpanded ? (
                                            <ChevronUp className="w-4 h-4" />
                                          ) : (
                                            <ChevronDown className="w-4 h-4" />
                                          )}
                                        </button>
                                      </div>
                                    )}
                                  </div>
                                </div>

                                {/* Expanded Details Section */}
                                {isExpanded && (
                                  <div className="mt-3 pt-3 border-t border-slate-100 space-y-2.5 animate-in fade-in duration-150 pl-1">
                                    {/* 1. Info Callout Box */}
                                    {infoBoxText && (
                                      <div className={`p-3 rounded-xl flex items-start gap-2.5 text-xs font-medium border ${isAgencyPaid ? "bg-purple-50/70 border-purple-200/80 text-purple-900" : "bg-amber-50/70 border-amber-200/80 text-amber-800"}`}>
                                        <Info className={`w-4 h-4 shrink-0 mt-0.5 ${isAgencyPaid ? "text-purple-600" : "text-amber-600"}`} />
                                        <span className="leading-relaxed">{infoBoxText}</span>
                                      </div>
                                    )}

                                    {/* 2. Receipt / Invoice Document Link */}
                                    {req.invoice_pdf_url && req.invoice_pdf_url !== "cash_settlement" && (
                                      <a
                                        href={req.invoice_pdf_url}
                                        target="_blank"
                                        rel="noopener noreferrer"
                                        className="p-2.5 bg-slate-50 hover:bg-slate-100 rounded-xl border border-slate-200 flex items-center justify-between text-xs font-semibold text-slate-700 transition-colors cursor-pointer group"
                                      >
                                        <div className="flex items-center gap-2">
                                          <FileText className="w-4 h-4 text-blue-600" />
                                          <span>{t("receiptInvoiceDocument")}</span>
                                        </div>
                                        <ExternalLink className="w-3.5 h-3.5 text-slate-400 group-hover:text-blue-600 transition-colors" />
                                      </a>
                                    )}

                                    {/* 3. Date string */}
                                    <div className="text-[11px] text-slate-400 font-medium">
                                      {new Date(req.payment_date || req.created_at).toLocaleDateString(activeLocale, {
                                        day: "numeric",
                                        month: "long",
                                        year: "numeric",
                                      })}
                                    </div>

                                    {/* 4. Action Buttons Row */}
                                    <div className="flex items-center gap-2 pt-1 flex-wrap">
                                      <button
                                        type="button"
                                        onClick={() => {
                                          if (onOpenMaintenanceRequest) {
                                            onOpenMaintenanceRequest(req);
                                          } else {
                                            setPropertyDrawerTab("maintenance");
                                          }
                                        }}
                                        className="px-3.5 py-2 rounded-xl text-xs font-bold border border-slate-200 text-slate-700 bg-white hover:bg-slate-50 hover:border-slate-300 transition-colors flex items-center justify-center gap-1.5 cursor-pointer shadow-2xs"
                                      >
                                        <ExternalLink className="w-3.5 h-3.5 text-slate-500" />
                                        <span>{t("goToMaintenanceRequest")}</span>
                                      </button>

                                      {isPendingReview && (
                                        <>
                                          <button
                                            type="button"
                                            disabled={isExecutingSettlementAction}
                                            onClick={() => {
                                              setRejectingSettlementReq(req);
                                              setSettlementRejectReason("");
                                            }}
                                            className="px-3.5 py-2 rounded-xl text-xs font-bold border border-rose-200 text-rose-700 bg-white hover:bg-rose-50 transition-colors flex items-center justify-center gap-1.5 cursor-pointer shadow-2xs disabled:opacity-50"
                                          >
                                            <X className="w-3.5 h-3.5 text-rose-600" />
                                            <span>{t("rejectExpenseTitle")}</span>
                                          </button>

                                          <button
                                            type="button"
                                            disabled={isExecutingSettlementAction}
                                            onClick={() => handleApproveSettlement(req)}
                                            className="px-4 py-2 rounded-[10px] text-xs font-bold text-white bg-[#1B5888] hover:bg-[#15466d] transition-colors flex items-center justify-center gap-1.5 shadow-2xs cursor-pointer disabled:opacity-50"
                                          >
                                            {isExecutingSettlementAction ? (
                                              <RefreshCw className="w-3.5 h-3.5 animate-spin" />
                                            ) : (
                                              <CheckCheck className="w-3.5 h-3.5" />
                                            )}
                                            <span>{t("approve")}</span>
                                          </button>
                                        </>
                                      )}

                                      {!isPendingReview && isAgencyPaid && !isAgencyTenantDamage && (
                                        <button
                                          type="button"
                                          disabled={isExecutingSettlementAction}
                                          onClick={() => handleApproveSettlement(req, true)}
                                          className="px-3.5 py-2 rounded-[10px] text-xs font-bold text-white bg-emerald-600 hover:bg-emerald-700 transition-colors flex items-center justify-center gap-1.5 shadow-2xs cursor-pointer disabled:opacity-50"
                                        >
                                          <CheckCircle2 className="w-3.5 h-3.5" />
                                          <span>{t("agency_maint_btn_mark_collected")}</span>
                                        </button>
                                      )}

                                      {!isPendingReview && (!isAgencyPaid || isAgencyTenantDamage) && (
                                        <button
                                          type="button"
                                          onClick={() => {
                                            setSettlementOptionsReq(req);
                                            setIsSettlementOptionsModalOpen(true);
                                          }}
                                          className={`px-3.5 py-2 rounded-[10px] text-xs font-bold text-white transition-colors flex items-center justify-center gap-1.5 shadow-2xs cursor-pointer ${isAddToRent
                                            ? "bg-amber-600 hover:bg-amber-700"
                                            : "bg-[#1B5888] hover:bg-[#15466d]"
                                            }`}
                                        >
                                          {isAddToRent ? (
                                            <ArrowUpRight className="w-3.5 h-3.5" />
                                          ) : (
                                            <ArrowDownLeft className="w-3.5 h-3.5" />
                                          )}
                                          <span>
                                            {isAddToRent
                                              ? t("settleAddToRentTitle")
                                              : t("settleExpenseTitle")}
                                          </span>
                                        </button>
                                      )}
                                    </div>
                                  </div>
                                )}
                              </div>
                            );
                          })}
                        </div>
                      )}
                    </div>
                  )}

                  {/* Monthly Grouped Payment Schedule */}
                  {sortedMonthKeys.length === 0 ? (
                    <div className="p-8 text-center text-xs text-[#666666] bg-slate-50 rounded-[10px] border border-[#E5E3DF] space-y-3">
                      <Receipt className="w-8 h-8 text-slate-300 mx-auto" />
                      <p>{t("agency_prop_drawer_no_payments")}</p>
                      <div className="flex items-center justify-center gap-2 pt-1">
                        <button
                          type="button"
                          onClick={() => inspectProperty(p)}
                          className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-[10px] text-xs font-bold bg-white border border-[#E5E3DF] text-[#4A4A4A] hover:bg-slate-100 transition-colors shadow-xs cursor-pointer"
                        >
                          <RefreshCw className="w-3.5 h-3.5" />
                          <span>{t("agency_financials_btn_generate")}</span>
                        </button>
                      </div>
                    </div>
                  ) : (
                    <div className="space-y-6">
                      {sortedMonthKeys.map((mKey) => {
                        const mList = monthsMap.get(mKey) || [];
                        const mPaidList = paidMaintenanceMap.get(mKey) || [];
                        const totalMonthItems = mList.length + mPaidList.length;

                        if (totalMonthItems === 0) return null;

                        const totalsByCurrency: Record<string, number> = {};
                        mList.forEach((pay) => {
                          if (pay.amount > 0) {
                            const cur = getEffectiveCurrency(pay);
                            totalsByCurrency[cur] = (totalsByCurrency[cur] || 0) + pay.amount;
                          }
                        });
                        mPaidList.forEach((m) => {
                          const amt = m.cost_amount || 0;
                          if (amt > 0) {
                            const cur = (m.currency || p.currency || "EUR").toUpperCase();
                            totalsByCurrency[cur] = (totalsByCurrency[cur] || 0) + amt;
                          }
                        });
                        const totalSegments = Object.entries(totalsByCurrency).map(([cur, amt]) =>
                          cur === "RSD" ? `${amt.toLocaleString("de-DE")} RSD` : `€${amt.toLocaleString("de-DE")}`
                        );
                        const formattedMonthTotal = totalSegments.length > 0 ? totalSegments.join(" + ") : "0 RSD";

                        const monthPaidPaymentsCount = mList.filter((pay) => pay.status === "paid").length;
                        const monthPaidCount = monthPaidPaymentsCount + mPaidList.length;
                        const isComplete = monthPaidCount === totalMonthItems && totalMonthItems > 0;
                        const hasAwaiting = mList.some(isPaymentAwaiting);
                        const allPaid = isComplete;
                        const isMonthCollapsed = collapsedMonths.has(mKey);

                        const monthSelectable = mList.filter((pay) => pay.status !== "paid");
                        const isMonthAllSelected = monthSelectable.length > 0 && monthSelectable.every((pay) => selectedPaymentIds.has(pay.id));
                        const isMonthPartiallySelected = monthSelectable.some((pay) => selectedPaymentIds.has(pay.id)) && !isMonthAllSelected;

                        let monthTitle = mKey;
                        if (mKey === "other") {
                          monthTitle = t("cat_other").toUpperCase();
                        } else {
                          try {
                            const [y, m] = mKey.split("-");
                            const d = new Date(parseInt(y), parseInt(m) - 1, 1);
                            monthTitle = d.toLocaleDateString(activeLocale, { month: "long", year: "numeric" }).toUpperCase();
                          } catch (_) { }
                        }

                        return (
                          <div key={mKey} className="bg-slate-50/75 rounded-[12px] border border-[#E5E3DF] overflow-hidden shadow-xs">
                            {/* Month Header (Collapsible with 100% Flutter Progress Bar Parity) */}
                            <div
                              onClick={() => toggleMonthCollapse(mKey)}
                              className="px-5 py-3.5 bg-slate-100/70 border-b border-[#E5E3DF] flex flex-col sm:flex-row sm:items-center justify-between gap-3 cursor-pointer hover:bg-slate-200/60 transition-colors select-none"
                            >
                              <div className="flex items-center gap-2.5">
                                <span className={`w-2 h-2 rounded-full shrink-0 ${isComplete ? "bg-blue-600" : "bg-amber-600"}`} />

                                {monthSelectable.length > 0 && (
                                  <button
                                    type="button"
                                    onClick={(e) => {
                                      e.stopPropagation();
                                      toggleSelectMonth(mList);
                                    }}
                                    className={`w-4 h-4 rounded border flex items-center justify-center transition-colors cursor-pointer mr-0.5 shrink-0 ${isMonthAllSelected
                                      ? "bg-[#1B5888] border-[#1B5888] text-white"
                                      : isMonthPartiallySelected
                                        ? "bg-blue-100 border-[#1B5888] text-[#1B5888]"
                                        : "bg-white border-slate-300 hover:border-slate-500"
                                      }`}
                                    title={isMonthAllSelected ? t("agency_bulk_clear_selection") : t("agency_bulk_select_all")}
                                  >
                                    {isMonthAllSelected && <Check className="w-3 h-3 stroke-[3]" />}
                                    {isMonthPartiallySelected && <Minus className="w-3 h-3 stroke-[3]" />}
                                  </button>
                                )}

                                <span className="text-xs font-bold tracking-wider text-[#1A1A1A]">
                                  {monthTitle}
                                </span>

                                {/* Linear Progress Bar (e.g. 7 / 7 paid) matching Flutter */}
                                <div className="flex items-center gap-2 ml-2">
                                  <div className="w-16 sm:w-28 h-1.5 bg-slate-200 rounded-full overflow-hidden">
                                    <div
                                      className={`h-full rounded-full transition-all duration-300 ${isComplete ? "bg-blue-600" : "bg-amber-600"}`}
                                      style={{ width: `${totalMonthItems > 0 ? (monthPaidCount / totalMonthItems) * 100 : 0}%` }}
                                    />
                                  </div>
                                  <span className={`text-[11px] font-bold ${isComplete ? "text-blue-600" : "text-amber-700"}`}>
                                    {monthPaidCount} / {totalMonthItems} {t("paidCountSuffix")}
                                  </span>
                                </div>
                              </div>

                              <div className="flex items-center gap-2.5 self-end sm:self-auto">
                                <span className="text-xs font-bold text-[#4A4A4A]">
                                  {t("agency_financials_total_label")}: {formattedMonthTotal}
                                </span>
                                {/* Total Items Pill matching Flutter • 7 */}
                                <span className="px-2 py-0.5 rounded-full text-[11px] font-bold bg-slate-200/80 text-slate-700">
                                  • {totalMonthItems}
                                </span>
                                {isMonthCollapsed ? (
                                  <ChevronDown className="w-4 h-4 text-[#666666] shrink-0" />
                                ) : (
                                  <ChevronUp className="w-4 h-4 text-[#666666] shrink-0" />
                                )}
                              </div>
                            </div>

                            {/* Month Payment Rows (Collapsible) */}
                            {!isMonthCollapsed && (
                              <div className="p-3 space-y-2.5 bg-white animate-in fade-in duration-150">
                                {/* 1. Monthly Utility & Rent Payments */}
                                {mList.map((pay) => {
                                  const isPaid = pay.status === "paid";
                                  const isDisputed = isPaymentDisputed(pay);
                                  const isAwaiting = !isDisputed && isPaymentAwaiting(pay);
                                  const isOverdue =
                                    !isDisputed &&
                                    isPaymentPendingUnpaid(pay) &&
                                    new Date(pay.due_date) < new Date();
                                  const isRent =
                                    (pay.title || "").toLowerCase().includes("kira") ||
                                    (pay.title || "").toLowerCase().includes("rent") ||
                                    (pay.title || "").toLowerCase().includes("kirij");
                                  const isTarget = pay.id === targetPaymentId;
                                  const isSelected = selectedPaymentIds.has(pay.id);
                                  const isCash = pay.payment_method === "cash" || pay.receipt_url === "CASH";
                                  const effCurr = getEffectiveCurrency(pay);
                                  const isExpanded = expandedMonthlyItemIds.has(pay.id);
                                  const itemActivityLogs = isExpanded ? getPaymentActivityLogs(pay) : [];

                                  return (
                                    <div
                                      key={pay.id}
                                      id={`payment-row-${pay.id}`}
                                      className={`rounded-[10px] border transition-all overflow-hidden bg-white shadow-2xs ${isSelected
                                        ? "border-[#1B5888] ring-2 ring-[#1B5888]/50 bg-blue-50/60 shadow-xs"
                                        : isDisputed
                                          ? "border-rose-300 ring-1 ring-rose-200 bg-rose-50/20"
                                          : isTarget
                                            ? "border-[#1B5888] ring-2 ring-[#1B5888]/40 bg-blue-50/40 shadow-sm"
                                            : "border-[#E5E3DF] hover:border-[#8A8A8A]"
                                        }`}
                                    >
                                      {/* Collapsed Header Row (Single Line with Big Bold Amount on Top) */}
                                      <div
                                        onClick={() => toggleMonthlyItemExpand(pay.id)}
                                        className="p-3.5 flex items-center justify-between gap-3 cursor-pointer select-none"
                                      >
                                        <div className="flex items-center gap-3 min-w-0">
                                          {!isPaid && (
                                            <button
                                              type="button"
                                              onClick={(e) => {
                                                e.stopPropagation();
                                                toggleSelectPayment(pay.id);
                                              }}
                                              className={`w-4 h-4 rounded border flex items-center justify-center transition-colors cursor-pointer shrink-0 ${isSelected
                                                ? "bg-[#1B5888] border-[#1B5888] text-white"
                                                : "bg-white border-slate-300 hover:border-slate-500"
                                                }`}
                                            >
                                              {isSelected && <Check className="w-3 h-3 stroke-[3]" />}
                                            </button>
                                          )}

                                          <PaymentTypeIconBadge
                                            title={pay.title}
                                            isMaintenance={pay.is_maintenance}
                                            isPaid={isPaid}
                                            size="md"
                                          />

                                          <div className="min-w-0">
                                            {/* Upper Line: Big Bold Amount (16px) */}
                                            <div>
                                              {pay.amount === 0 ? (
                                                <span className="text-[15px] font-extrabold text-[#1B5888]">
                                                  {t("agency_invoice_status_no_amount")}
                                                </span>
                                              ) : (
                                                <span className="text-base font-extrabold text-[#1A1A1A]">
                                                  {formatCurrencyAmount(pay.amount, effCurr)}
                                                </span>
                                              )}
                                            </div>

                                            {/* Lower Line: Title + Badges (Payment Method: Bank / Cash) */}
                                            <div className="flex items-center gap-2 flex-wrap text-xs text-[#666666] mt-0.5">
                                              <span className="font-semibold text-[#666666]">
                                                {formatPaymentTitle(pay.title)}
                                              </span>

                                              {pay.receiver_type === "included" && (
                                                <span className="px-1.5 py-0.5 rounded text-[10px] font-bold bg-purple-50 text-purple-700 border border-purple-200">
                                                  {t("includedInRentBadge")}
                                                </span>
                                              )}

                                              {/* Payment Method Badge (100% Flutter Parity) */}
                                              {isCash ? (
                                                <span className="inline-flex items-center gap-1 px-1.5 py-0.5 rounded text-[10px] font-bold bg-amber-50 text-amber-900 border border-amber-300">
                                                  <Banknote className="w-2.5 h-2.5" />
                                                  {t("paymentMethodCash")}
                                                </span>
                                              ) : (
                                                <span className="inline-flex items-center gap-1 px-1.5 py-0.5 rounded text-[10px] font-bold bg-blue-50 text-blue-800 border border-blue-200">
                                                  <Landmark className="w-2.5 h-2.5" />
                                                  {t("paymentMethodBank")}
                                                </span>
                                              )}
                                            </div>
                                          </div>
                                        </div>

                                        {/* Right Side: Status Badge + Expand Chevron */}
                                        <div className="flex items-center gap-2 shrink-0">
                                          <span
                                            className={`px-2.5 py-1 rounded-full text-[11px] font-bold ${isPaid
                                              ? "bg-[#E6F3EA] text-[#2A6E43] border border-[#2A6E43]/20"
                                              : isDisputed
                                                ? "bg-[#FFF1F2] text-[#E11D48] border border-[#FDA4AF] animate-pulse"
                                                : isAwaiting
                                                  ? "bg-[#FBF1DC] text-[#8A5206] border border-[#8A5206]/20 animate-pulse"
                                                  : isOverdue
                                                    ? "bg-[#FBEAE6] text-[#A33C29] border border-[#B5432E]/20"
                                                    : pay.amount === 0
                                                      ? "bg-[#FBF1DC] text-[#8A5206] border border-[#8A5206]/20"
                                                      : "bg-slate-100 text-[#4A4A4A] border border-[#E5E3DF]"
                                              }`}
                                          >
                                            {isPaid
                                              ? t("financialsStatusPaidUppercase")
                                              : isDisputed
                                                ? t("agency_maint_status_disputed")
                                                : isAwaiting
                                                  ? t("agency_payments_status_awaiting_approval")
                                                  : isOverdue
                                                    ? t("agency_payments_status_overdue")
                                                    : pay.amount === 0
                                                      ? t("agency_invoice_btn_enter_amount")
                                                      : t("agency_payments_status_pending")}
                                          </span>

                                          <button
                                            type="button"
                                            onClick={(e) => {
                                              e.stopPropagation();
                                              toggleMonthlyItemExpand(pay.id);
                                            }}
                                            className="p-1 hover:bg-slate-100 rounded text-slate-400 hover:text-slate-600 transition-colors"
                                          >
                                            {isExpanded ? <ChevronUp className="w-4 h-4" /> : <ChevronDown className="w-4 h-4" />}
                                          </button>
                                        </div>
                                      </div>

                                      {/* Expanded Accordion Details (100% Flutter _buildPaymentCard Parity: Transaction History + Dispute Banner + Actions) */}
                                      {isExpanded && (
                                        <div className="px-4 pb-3.5 pt-3 border-t border-slate-100 bg-slate-50/50 space-y-3 text-xs">
                                          {/* 1. Transaction History & Documents Row */}
                                          <div className="flex flex-col sm:flex-row sm:items-start justify-between gap-3">
                                            <div className="space-y-1.5 flex-1 min-w-0">
                                              <span className="text-[11px] font-bold text-[#666666] uppercase tracking-wider block">
                                                {t("agency_payment_transaction_history")}
                                              </span>
                                              {itemActivityLogs.length === 0 ? (
                                                <p className="text-xs text-slate-400 italic">
                                                  {t("agency_payment_no_transactions")}
                                                </p>
                                              ) : (
                                                <div className="space-y-1.5 pt-0.5">
                                                  {itemActivityLogs.map((logItem) => (
                                                    <div key={logItem.id} className="flex items-start gap-2">
                                                      <span
                                                        className={`w-1.5 h-1.5 rounded-full mt-1.5 shrink-0 ${logItem.type === "rent_disputed" || logItem.type === "rent_rejected" || logItem.type === "invoice_rejected"
                                                            ? "bg-rose-500"
                                                            : logItem.type === "rent_approved" || logItem.type === "rent_auto_approved" || (logItem.type === "payment_toggle" && logItem.metadata?.paid)
                                                              ? "bg-emerald-600"
                                                              : "bg-slate-400"
                                                          }`}
                                                      />
                                                      <div className="min-w-0 flex-1">
                                                        <p className="text-xs font-semibold text-[#334155] leading-snug">
                                                          {formatActivityLogItem(logItem, propPayments, pay)}
                                                        </p>
                                                        <span className="text-[10px] text-[#666666] font-mono block">
                                                          {formatLogTimestamp(logItem.created_at)}
                                                        </span>
                                                      </div>
                                                    </div>
                                                  ))}
                                                </div>
                                              )}
                                            </div>

                                            {/* Documents Preview Column */}
                                            {(pay.invoice_url || (pay.receipt_url && pay.receipt_url !== "CASH")) && (
                                              <div className="flex sm:flex-col items-end gap-1.5 shrink-0">
                                                {pay.invoice_url && (
                                                  <a
                                                    href={pay.invoice_url}
                                                    target="_blank"
                                                    rel="noopener noreferrer"
                                                    className="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg text-xs font-semibold bg-purple-50 text-purple-700 hover:bg-purple-100 transition-colors"
                                                    title={t("agency_invoice_btn_view_doc")}
                                                  >
                                                    <FileText className="w-3.5 h-3.5" />
                                                    <span>{t("agency_invoice_btn_view_doc")}</span>
                                                  </a>
                                                )}

                                                {pay.receipt_url && pay.receipt_url !== "CASH" && (
                                                  <button
                                                    type="button"
                                                    onClick={() => setSelectedReceiptPayment(pay)}
                                                    className="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg text-xs font-semibold bg-[#E5EEF6] text-[#12406A] hover:bg-blue-100 transition-colors cursor-pointer"
                                                  >
                                                    <Receipt className="w-3.5 h-3.5" />
                                                    <span>{t("agency_payments_btn_view_receipt")}</span>
                                                  </button>
                                                )}
                                              </div>
                                            )}
                                          </div>

                                          {/* 2. Info Banners: Dispute Reason, Cash Declaration, or Owner Note */}
                                          {isDisputed && (
                                            <div className="p-2.5 rounded-lg bg-[#FFF1F2] border border-[#FDA4AF] flex items-start gap-2 text-xs text-[#9F1239]">
                                              <AlertTriangle className="w-4 h-4 text-[#E11D48] shrink-0 mt-0.5" />
                                              <div className="min-w-0 flex-1">
                                                <span className="font-bold">{t("agency_pay_dispute_reason")}: </span>
                                                <span className="font-semibold">
                                                  {pay.dispute_reason || t("agency_maint_status_disputed")}
                                                </span>
                                              </div>
                                            </div>
                                          )}

                                          {pay.owner_note && (
                                            <div className="p-2.5 rounded-lg bg-slate-100/80 border border-slate-200/80 flex items-start gap-2 text-xs text-slate-700">
                                              <Info className="w-3.5 h-3.5 text-slate-500 shrink-0 mt-0.5" />
                                              <span>
                                                <strong className="font-semibold">{t("agency_financials_note_prefix")}:</strong> {pay.owner_note}
                                              </span>
                                            </div>
                                          )}

                                          {/* 3. Footer Due Date & Action Buttons */}
                                          <div className="flex items-center justify-between flex-wrap gap-2 pt-2 border-t border-slate-200/60 text-[#666666]">
                                            <div>
                                              <span>{t("agency_contracts_col_due")}: {pay.due_date || "-"}</span>
                                              {pay.paid_at && (
                                                <span className="ml-2">
                                                  • {t("agency_financials_paid_date_prefix")}: {new Date(pay.paid_at).toLocaleDateString(activeLocale)}
                                                </span>
                                              )}
                                            </div>

                                            <div className="flex items-center gap-2 flex-wrap">
                                              {/* Update / Enter Amount button: shown if unpaid AND (disputed OR non-rent OR amount is 0) — 100% Flutter Parity */}
                                              {!isPaid && (isDisputed || !isRent || pay.amount === 0) && (
                                                <button
                                                  type="button"
                                                  onClick={() => openInvoiceModal(pay)}
                                                  className={`inline-flex items-center gap-1 px-2.5 py-1 rounded-lg text-xs font-semibold transition-colors cursor-pointer ${isDisputed
                                                      ? "bg-[#FFF1F2] text-[#E11D48] hover:bg-rose-100 font-bold border border-[#FDA4AF]"
                                                      : pay.amount === 0
                                                        ? "bg-[#FBF1DC] text-[#8A5206] hover:bg-amber-200 font-bold border border-amber-300 animate-pulse"
                                                        : "bg-slate-100 text-[#4A4A4A] hover:bg-slate-200"
                                                    }`}
                                                  title={isDisputed ? t("agency_payment_btn_update_disputed") : t("agency_invoice_btn_enter_amount")}
                                                >
                                                  {isDisputed ? (
                                                    <Pencil className="w-3.5 h-3.5" />
                                                  ) : (
                                                    <FilePlus className="w-3.5 h-3.5" />
                                                  )}
                                                  <span>
                                                    {isDisputed
                                                      ? t("agency_payment_btn_update_disputed")
                                                      : t("agency_invoice_btn_enter_amount")}
                                                  </span>
                                                </button>
                                              )}

                                              {isAwaiting && (
                                                <div className="flex items-center gap-1">
                                                  <button
                                                    type="button"
                                                    onClick={() => handleApprovePayment(pay)}
                                                    className="px-2.5 py-1 rounded-lg text-xs font-bold bg-[#1B5888] text-white hover:bg-emerald-700 shadow-xs cursor-pointer transition-colors"
                                                  >
                                                    {t("agency_payments_btn_approve")}
                                                  </button>
                                                  <button
                                                    type="button"
                                                    onClick={() => openDisputeModal(pay)}
                                                    className="px-2.5 py-1 rounded-lg text-xs font-semibold text-[#A33C29] hover:bg-[#FBEAE6] cursor-pointer transition-colors"
                                                  >
                                                    {t("agency_payments_btn_reject")}
                                                  </button>
                                                </div>
                                              )}

                                              {!isPaid && !isAwaiting && (
                                                <button
                                                  type="button"
                                                  onClick={() => openMarkPaidModal(pay)}
                                                  className="px-2.5 py-1 rounded-lg text-xs font-semibold text-[#4A4A4A] bg-slate-100 hover:bg-slate-200 cursor-pointer transition-colors"
                                                >
                                                  {t("agency_financials_mark_paid")}
                                                </button>
                                              )}
                                            </div>
                                          </div>
                                        </div>
                                      )}
                                    </div>
                                  );
                                })}

                                {/* 2. Monthly Completed Maintenance Settlements (100% Flutter Parity) */}
                                {mPaidList.map((mReq) => {
                                  const isExpanded = expandedMonthlyItemIds.has(mReq.id);
                                  const currency = (mReq.currency || p.currency || "EUR").toUpperCase();
                                  const cost = mReq.cost_amount || 0;
                                  const isLandlordCredit = mReq.paid_by === "landlord";
                                  const isTenantSelf = mReq.paid_by === "tenant";

                                  let amountDisplay = formatCurrencyAmount(cost, currency);
                                  let settlementRoleLabel = t("financialsAgencyCreditCollected");
                                  if (isLandlordCredit) {
                                    amountDisplay = `+ ${formatCurrencyAmount(cost, currency)}`;
                                    settlementRoleLabel = t("financialsLandlordCreditCollected");
                                  } else if (isTenantSelf) {
                                    amountDisplay = formatCurrencyAmount(cost, currency);
                                    settlementRoleLabel = t("financialsTenantPrivateExpenseClosed");
                                  }

                                  return (
                                    <div
                                      key={`maint-${mReq.id}`}
                                      id={`maint-row-${mReq.id}`}
                                      className="rounded-[10px] border border-emerald-200/80 transition-all overflow-hidden bg-white shadow-2xs hover:border-[#8A8A8A]"
                                    >
                                      <div
                                        onClick={() => toggleMonthlyItemExpand(mReq.id)}
                                        className="p-3.5 flex items-center justify-between gap-3 cursor-pointer select-none"
                                      >
                                        <div className="flex items-center gap-3 min-w-0">
                                          <PaymentTypeIconBadge
                                            title={mReq.title}
                                            isMaintenance={true}
                                            isPaid={true}
                                            size="md"
                                          />

                                          <div className="min-w-0">
                                            {/* Upper Line: Big Bold Amount (16px) */}
                                            <div>
                                              <span className="text-base font-extrabold text-[#1A1A1A]">
                                                {amountDisplay}
                                              </span>
                                            </div>

                                            {/* Lower Line: Title + Settlement Role Label + Paperclip */}
                                            <div className="flex items-center gap-1.5 flex-wrap text-xs text-[#666666] mt-0.5">
                                              <span className="font-semibold text-[#666666] truncate">
                                                {mReq.title}
                                              </span>
                                              <span>•</span>
                                              <span className="text-[#666666]">
                                                {settlementRoleLabel}
                                              </span>
                                              {mReq.invoice_pdf_url && (
                                                <Paperclip className="w-3 h-3 text-[#64748B] shrink-0 ml-0.5" />
                                              )}
                                            </div>
                                          </div>
                                        </div>

                                        {/* Right Side: Status Badge + Expand Chevron */}
                                        <div className="flex items-center gap-2 shrink-0">
                                          <span className="px-2.5 py-1 rounded-full text-[11px] font-bold bg-[#E6F3EA] text-[#2A6E43] border border-[#2A6E43]/20">
                                            {t("financialsStatusPaidUppercase")}
                                          </span>

                                          <button
                                            type="button"
                                            onClick={(e) => {
                                              e.stopPropagation();
                                              toggleMonthlyItemExpand(mReq.id);
                                            }}
                                            className="p-1 hover:bg-slate-100 rounded text-slate-400 hover:text-slate-600 transition-colors"
                                          >
                                            {isExpanded ? <ChevronUp className="w-4 h-4" /> : <ChevronDown className="w-4 h-4" />}
                                          </button>
                                        </div>
                                      </div>

                                      {/* Expanded Accordion Details */}
                                      {isExpanded && (
                                        <div className="px-4 pb-3.5 pt-2 border-t border-slate-100 bg-slate-50/50 space-y-2 text-xs">
                                          <div className="flex items-center justify-between flex-wrap gap-2 text-[#666666]">
                                            <div>
                                              {mReq.payment_date && (
                                                <span>
                                                  {t("agency_financials_paid_date_prefix")}: {new Date(mReq.payment_date).toLocaleDateString(activeLocale)}
                                                </span>
                                              )}
                                              {mReq.description && (
                                                <span className="ml-2">
                                                  • {mReq.description}
                                                </span>
                                              )}
                                            </div>

                                            {mReq.invoice_pdf_url && (
                                              <a
                                                href={mReq.invoice_pdf_url}
                                                target="_blank"
                                                rel="noopener noreferrer"
                                                className="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg text-xs font-semibold bg-emerald-50 text-emerald-700 hover:bg-emerald-100 transition-colors"
                                              >
                                                <FileText className="w-3.5 h-3.5" />
                                                <span>{t("receiptDocTitle")}</span>
                                              </a>
                                            )}
                                          </div>
                                        </div>
                                      )}
                                    </div>
                                  );
                                })}
                              </div>
                            )}
                          </div>
                        );
                      })}
                    </div>
                  )}

                  {/* Sticky / Floating Bulk Action Bar (Agency Only, Flutter Parity) */}
                  {selectedPaymentIds.size > 0 && (() => {
                    const selectedList = payments.filter((pay) => selectedPaymentIds.has(pay.id));
                    const totalsByCurrency: Record<string, number> = {};
                    for (const pay of selectedList) {
                      const cur = getEffectiveCurrency(pay);
                      totalsByCurrency[cur] = (totalsByCurrency[cur] || 0) + (Number(pay.amount) || 0);
                    }
                    const formattedTotal = Object.entries(totalsByCurrency)
                      .map(([cur, amt]) => (cur === "RSD" ? `${amt.toLocaleString()} RSD` : `€${amt.toLocaleString()}`))
                      .join(" + ");

                    const allDeclared = selectedList.length > 0 && selectedList.every(isPaymentAwaiting);

                    return (
                      <div className="fixed bottom-6 left-1/2 -translate-x-1/2 z-40 max-w-xl w-[calc(100%-2rem)] bg-[#0F172A] text-white p-3.5 sm:p-4 rounded-2xl shadow-2xl border border-slate-700 flex items-center justify-between gap-3 sm:gap-4 animate-in slide-in-from-bottom-5 duration-200">
                        <div className="flex items-center gap-3 min-w-0">
                          <button
                            type="button"
                            onClick={clearSelectedPayments}
                            className="w-7 h-7 rounded-full bg-slate-800 hover:bg-slate-700 flex items-center justify-center text-slate-300 hover:text-white transition-colors cursor-pointer shrink-0"
                            title={t("agency_bulk_clear_selection")}
                          >
                            <X className="w-4 h-4" />
                          </button>

                          <div className="min-w-0">
                            <p className="text-xs font-medium text-slate-400 truncate">
                              {t("agency_bulk_debts_selected", { count: String(selectedPaymentIds.size) })}
                            </p>
                            <p className="text-sm sm:text-base font-extrabold text-white truncate">
                              {formattedTotal}
                            </p>
                          </div>
                        </div>

                        <div className="flex items-center gap-2 shrink-0">
                          {allDeclared ? (
                            <button
                              type="button"
                              onClick={() => handleExecuteBulkApprove(selectedList)}
                              className="px-4 py-2 rounded-[10px] text-xs font-bold bg-[#1B5888] hover:bg-[#15466d] text-white transition-colors flex items-center gap-1.5 shadow-2xs cursor-pointer"
                            >
                              <CheckCheck className="w-4 h-4" />
                              <span>{t("agency_bulk_approve")}</span>
                            </button>
                          ) : (
                            <button
                              type="button"
                              onClick={openBulkMarkPaidModal}
                              className="px-4 py-2 rounded-[10px] text-xs font-bold bg-[#1B5888] hover:bg-[#15466d] text-white transition-colors flex items-center gap-1.5 shadow-2xs cursor-pointer"
                            >
                              <CheckCircle2 className="w-4 h-4" />
                              <span>{t("agency_bulk_mark_paid")}</span>
                            </button>
                          )}
                        </div>
                      </div>
                    );
                  })()}
                </div>
              )}

              {/* 2. OVERVIEW & CONTRACT TAB */}
              {propertyDrawerTab === "overview" && (
                <div className="space-y-6 animate-in fade-in duration-150">
                  {/* 4-Metric Lease Overview Strip */}
                  <div className="bg-white rounded-2xl border border-slate-200/80 p-5 sm:p-6 shadow-xs grid grid-cols-2 md:grid-cols-4 gap-6">
                    <div>
                      <span className="text-xs text-slate-500 font-medium block">
                        {t("agency_props_col_rent")}
                      </span>
                      <span className="text-xl sm:text-2xl font-bold text-slate-900 block mt-1 tracking-tight">
                        {propContract?.monthly_rent
                          ? `${Number(propContract.monthly_rent).toLocaleString("de-DE")} EUR`
                          : p.default_monthly_rent
                            ? `${Number(p.default_monthly_rent).toLocaleString("de-DE")} EUR`
                            : "-"}
                      </span>
                    </div>

                    <div>
                      <span className="text-xs text-slate-500 font-medium block">
                        {t("agency_prop_drawer_deposit")}
                      </span>
                      <span className="text-xl sm:text-2xl font-bold text-slate-900 block mt-1 tracking-tight">
                        {propContract?.deposit_amount
                          ? `${Number(propContract.deposit_amount).toLocaleString("de-DE")} EUR`
                          : "-"}
                      </span>
                    </div>

                    <div>
                      <span className="text-xs text-slate-500 font-medium block">
                        {t("agency_prop_drawer_due_day")}
                      </span>
                      <span className="text-sm sm:text-base font-semibold text-slate-900 block mt-1.5">
                        {propContract?.due_day
                          ? t("agency_prop_drawer_due_day_text", {
                            day: String(propContract.due_day),
                          })
                          : "-"}
                      </span>
                    </div>

                    <div>
                      <span className="text-xs text-slate-500 font-medium block">
                        {t("agency_prop_drawer_contract_dates")}
                      </span>
                      <span className="text-sm sm:text-base font-semibold text-slate-900 block mt-1.5">
                        {propContract
                          ? `${formatEuropeanDate(propContract.start_date)} - ${formatEuropeanDate(propContract.end_date)}`
                          : "-"}
                      </span>
                    </div>
                  </div>

                  {/* 2-Column Main Content Grid */}
                  <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 items-start">
                    {/* Left Column: Tenants & Property Details */}
                    <div className="space-y-6">
                      {/* Card 1: Tenants & Contract Details (Flutter _showContractDetailsSheet & _OverviewTab Parity) */}
                      <div className="bg-white rounded-2xl border border-slate-200/80 p-5 sm:p-6 shadow-xs space-y-5">
                        <div className="flex items-center justify-between pb-3 border-b border-slate-100">
                          <h3 className="text-base font-bold text-slate-900">
                            {t("agency_prop_tenants_heading")}
                          </h3>
                          <div className="flex items-center gap-3">
                            {propContract && (
                              <>
                                <button
                                  type="button"
                                  onClick={() => openRenewContractModal(propContract)}
                                  className="text-xs font-semibold text-emerald-700 hover:underline cursor-pointer"
                                >
                                  {t("agency_contract_btn_renew")}
                                </button>
                                <button
                                  type="button"
                                  onClick={() => openTerminateContractModal(propContract)}
                                  className="text-xs font-semibold text-rose-600 hover:underline cursor-pointer"
                                >
                                  {t("agency_contract_btn_terminate")}
                                </button>
                              </>
                            )}
                            <button
                              type="button"
                              onClick={() => openNewContractModal(p)}
                              className="text-xs font-semibold text-[#1B5888] hover:underline cursor-pointer"
                            >
                              {t("agency_prop_edit_tenants")}
                            </button>
                          </div>
                        </div>

                        {(() => {
                          const displayTenantName =
                            propContract?.tenant_name ||
                            p.active_tenant_name ||
                            propContract?.invitee_email ||
                            null;
                          const displayTenantPhone =
                            propContract?.tenant_phone ||
                            p.active_tenant_phone ||
                            null;
                          const displayTenantEmail =
                            propContract?.invitee_email || null;
                          const displayTenantIdNumber =
                            propContract?.tenant_id_number || null;
                          const displayTenantNotes =
                            propContract?.tenant_notes || null;
                          const displayTenantIdDocUrl =
                            propContract?.tenant_id_document_url || null;
                          const displaySecondaryContacts: TenantSecondaryContact[] =
                            Array.isArray(propContract?.tenant_secondary_contacts)
                              ? propContract.tenant_secondary_contacts
                              : [];
                          const displayExpenses: ContractExpenseItem[] =
                            Array.isArray(propContract?.expenses_config) && propContract.expenses_config.length > 0
                              ? propContract.expenses_config
                              : Array.isArray(p.expenses_template) && p.expenses_template.length > 0
                                ? p.expenses_template
                                : [];
                          const displayAdditionalDocs: ContractAdditionalDocument[] =
                            Array.isArray(propContract?.additional_documents)
                              ? propContract.additional_documents
                              : [];

                          return displayTenantName ? (
                            <div className="space-y-4">
                              {/* Primary Tenant Profile Row */}
                              <div className="flex items-center justify-between p-3 rounded-xl bg-slate-50/70 border border-slate-100">
                                <div className="flex items-center gap-3 min-w-0">
                                  <div className="w-10 h-10 rounded-full bg-[#E5EEF6] text-[#1B5888] font-bold flex items-center justify-center text-xs shrink-0">
                                    {getInitials(displayTenantName)}
                                  </div>
                                  <div className="min-w-0 space-y-0.5">
                                    <p className="text-sm font-bold text-slate-900 truncate">
                                      {displayTenantName}
                                    </p>
                                    {displayTenantPhone ? (
                                      <p className="text-xs text-slate-500 font-medium truncate">
                                        {displayTenantPhone}
                                      </p>
                                    ) : (
                                      <button
                                        type="button"
                                        onClick={() => openNewContractModal(p)}
                                        className="text-xs text-[#1B5888] hover:underline font-medium cursor-pointer"
                                      >
                                        {t("agency_prop_add_phone")}
                                      </button>
                                    )}
                                  </div>
                                </div>

                                <div className="flex items-center gap-2 shrink-0">
                                  {displayTenantPhone && (
                                    <a
                                      href={`tel:${displayTenantPhone}`}
                                      className="px-3.5 py-1.5 rounded-lg border border-slate-300 bg-white text-xs font-semibold text-slate-700 hover:bg-slate-100 transition-colors"
                                    >
                                      {t("agency_prop_btn_call")}
                                    </a>
                                  )}
                                  {displayTenantPhone ? (
                                    <a
                                      href={`https://wa.me/${displayTenantPhone.replace(/[^0-9]/g, "")}`}
                                      target="_blank"
                                      rel="noopener noreferrer"
                                      className="px-3.5 py-1.5 rounded-lg border border-slate-300 bg-white text-xs font-semibold text-slate-700 hover:bg-slate-100 transition-colors"
                                    >
                                      {t("agency_prop_btn_message")}
                                    </a>
                                  ) : (
                                    <button
                                      type="button"
                                      onClick={() => openNewContractModal(p)}
                                      className="px-3.5 py-1.5 rounded-lg border border-slate-300 bg-white text-xs font-semibold text-slate-700 hover:bg-slate-100 transition-colors cursor-pointer"
                                    >
                                      {t("agency_prop_btn_message")}
                                    </button>
                                  )}
                                </div>
                              </div>

                              {/* Tenant Extra Details: Email, ID/Passport/JMBG, Notes, ID Document */}
                              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 text-xs">
                                <div className="p-2.5 rounded-xl border border-slate-100 bg-slate-50/40">
                                  <span className="text-[11px] text-slate-400 font-semibold block">
                                    {t("agency_contract_field_tenant_email")}
                                  </span>
                                  <span className="font-semibold text-slate-800 block mt-0.5 truncate">
                                    {displayTenantEmail || t("agency_prop_not_added")}
                                  </span>
                                </div>
                                <div className="p-2.5 rounded-xl border border-slate-100 bg-slate-50/40">
                                  <span className="text-[11px] text-slate-400 font-semibold block">
                                    {t("agency_tenant_id_label")}
                                  </span>
                                  <span className="font-semibold text-slate-800 block mt-0.5 truncate">
                                    {displayTenantIdNumber || t("agency_prop_not_added")}
                                  </span>
                                </div>
                              </div>

                              {displayTenantNotes && (
                                <div className="p-3 rounded-xl bg-amber-50/50 border border-amber-200/60 text-xs space-y-1">
                                  <span className="text-[11px] font-bold text-amber-800 block">
                                    {t("agency_contract_field_tenant_notes")}
                                  </span>
                                  <p className="text-slate-700 leading-relaxed whitespace-pre-line max-h-[195px] overflow-y-auto pr-1">
                                    {displayTenantNotes}
                                  </p>
                                </div>
                              )}

                              {displayTenantIdDocUrl && (
                                <div>
                                  <a
                                    href={displayTenantIdDocUrl}
                                    target="_blank"
                                    rel="noopener noreferrer"
                                    className="inline-flex items-center gap-2 px-3.5 py-2 rounded-xl border border-[#1B5888]/30 bg-blue-50/40 text-xs font-bold text-[#1B5888] hover:bg-blue-50 transition-colors"
                                  >
                                    <FileText className="w-3.5 h-3.5" />
                                    <span>{t("agency_contract_view_id_doc")}</span>
                                    <ExternalLink className="w-3 h-3" />
                                  </a>
                                </div>
                              )}

                              {/* Secondary Contacts (Flutter tenantSecondaryContacts Parity) */}
                              {displaySecondaryContacts.length > 0 && (
                                <div className="pt-3 border-t border-slate-100 space-y-2">
                                  <span className="text-xs font-bold text-slate-700 block">
                                    {t("agency_contract_secondary_contacts_heading")} ({displaySecondaryContacts.length})
                                  </span>
                                  <div className="space-y-2">
                                    {displaySecondaryContacts.map((sc, scIdx) => (
                                      <div
                                        key={scIdx}
                                        className="p-2.5 rounded-xl bg-slate-50 border border-slate-200/70 flex items-center justify-between gap-2 text-xs"
                                      >
                                        <div className="min-w-0">
                                          <div className="flex items-center gap-1.5 flex-wrap">
                                            <span className="font-bold text-slate-800">{sc.full_name}</span>
                                            {sc.relationship && (
                                              <span className="px-2 py-0.5 rounded-full bg-blue-100/80 text-[#1B5888] text-[10px] font-bold">
                                                {sc.relationship}
                                              </span>
                                            )}
                                          </div>
                                          <div className="flex items-center gap-3 text-[11px] text-slate-500 mt-0.5 flex-wrap">
                                            {sc.phone && <span>{sc.phone}</span>}
                                            {sc.email && <span>{sc.email}</span>}
                                          </div>
                                        </div>
                                      </div>
                                    ))}
                                  </div>
                                </div>
                              )}

                              {/* Utility & Expense Responsibilities (Flutter expensesConfig Parity) */}
                              {displayExpenses.length > 0 && (
                                <div className="pt-3 border-t border-slate-100 space-y-2">
                                  <div className="flex items-center justify-between">
                                    <span className="text-xs font-bold text-slate-700">
                                      {t("agency_contract_expenses_heading")}
                                    </span>
                                    <button
                                      type="button"
                                      onClick={() => openNewContractModal(p)}
                                      className="text-[11px] font-semibold text-[#1B5888] hover:underline cursor-pointer"
                                    >
                                      {t("agency_prop_btn_edit_short")}
                                    </button>
                                  </div>
                                  <div className="divide-y divide-slate-100 rounded-xl border border-slate-200/80 overflow-hidden bg-slate-50/40">
                                    {displayExpenses.map((exp, eIdx) => {
                                      const expName = exp.name || (exp as any).title || "Gider";
                                      const isInc = exp.receiver === "included";
                                      const isUtil = exp.receiver === "utility";
                                      const recLabel = isInc
                                        ? t("agency_expense_receiver_included")
                                        : isUtil
                                          ? t("agency_expense_receiver_utility")
                                          : t("agency_expense_receiver_owner");
                                      const methodLabel =
                                        exp.payment_method === "cash"
                                          ? t("agency_pay_method_cash")
                                          : t("agency_pay_method_bank");
                                      return (
                                        <div
                                          key={eIdx}
                                          className="px-3 py-2 flex items-center justify-between gap-2 text-xs"
                                        >
                                          <span className="font-semibold text-slate-800">{expName}</span>
                                          <div className="flex items-center gap-1.5 flex-wrap justify-end">
                                            <span
                                              className={`px-2 py-0.5 rounded-full text-[10px] font-bold ${isInc
                                                ? "bg-emerald-100 text-emerald-800"
                                                : isUtil
                                                  ? "bg-purple-100 text-purple-800"
                                                  : "bg-blue-100 text-[#1B5888]"
                                                }`}
                                            >
                                              {recLabel}
                                            </span>
                                            {!isInc && (
                                              <span className="px-2 py-0.5 rounded-full bg-slate-200/70 text-slate-700 text-[10px] font-semibold">
                                                {methodLabel}
                                              </span>
                                            )}
                                          </div>
                                        </div>
                                      );
                                    })}
                                  </div>
                                </div>
                              )}

                              {/* Contract & Additional Documents (Flutter contractUrl & additionalDocuments Parity) */}
                              <div className="pt-3 border-t border-slate-100 space-y-2">
                                <div className="flex items-center justify-between">
                                  <span className="text-xs font-bold text-slate-700">
                                    {t("agency_contract_docs_heading")}
                                  </span>
                                  <button
                                    type="button"
                                    onClick={() => openNewContractModal(p)}
                                    className="text-[11px] font-semibold text-[#1B5888] hover:underline cursor-pointer"
                                  >
                                    {t("agency_contract_add_additional_doc")}
                                  </button>
                                </div>
                                {propContract?.contract_url || displayAdditionalDocs.length > 0 ? (
                                  <div className="space-y-1.5">
                                    {propContract?.contract_url && (
                                      <a
                                        href={propContract.contract_url}
                                        target="_blank"
                                        rel="noopener noreferrer"
                                        className="flex items-center justify-between p-2.5 rounded-xl border border-slate-200/80 bg-slate-50/60 hover:bg-slate-100/70 transition-colors text-xs"
                                      >
                                        <div className="flex items-center gap-2 min-w-0">
                                          <FileText className="w-4 h-4 text-[#1B5888] shrink-0" />
                                          <span className="font-bold text-slate-800 truncate">
                                            {t("agency_contract_main_doc_label")}
                                          </span>
                                        </div>
                                        <ExternalLink className="w-3.5 h-3.5 text-slate-400 shrink-0" />
                                      </a>
                                    )}
                                    {displayAdditionalDocs.map((doc, dIdx) => (
                                      <a
                                        key={dIdx}
                                        href={doc.url}
                                        target="_blank"
                                        rel="noopener noreferrer"
                                        className="flex items-center justify-between p-2.5 rounded-xl border border-slate-200/80 bg-white hover:bg-slate-50 transition-colors text-xs"
                                      >
                                        <div className="flex items-center gap-2 min-w-0">
                                          <Paperclip className="w-3.5 h-3.5 text-slate-500 shrink-0" />
                                          <span className="font-semibold text-slate-700 truncate">
                                            {doc.name}
                                          </span>
                                        </div>
                                        <ExternalLink className="w-3.5 h-3.5 text-slate-400 shrink-0" />
                                      </a>
                                    ))}
                                  </div>
                                ) : (
                                  <p className="text-xs text-slate-400">
                                    {t("agency_contract_no_docs_yet")}
                                  </p>
                                )}
                              </div>
                            </div>
                          ) : (
                            <div className="text-center py-6 text-xs text-slate-400 space-y-2.5">
                              <p>{t("agency_prop_drawer_no_contract")}</p>
                              <div className="flex items-center justify-center gap-2 flex-wrap">
                                <button
                                  type="button"
                                  onClick={() => openNewContractModal(p)}
                                  className="px-3.5 py-1.5 rounded-lg bg-[#1B5888] text-white text-xs font-bold hover:bg-[#12406A] transition-colors cursor-pointer"
                                >
                                  {t("agency_contract_btn_new_contract")}
                                </button>
                                <button
                                  type="button"
                                  onClick={() => openRelistModal(p)}
                                  className="px-3.5 py-1.5 rounded-lg bg-white border border-[#1B5888]/30 text-[#1B5888] text-xs font-bold hover:bg-blue-50/50 transition-colors cursor-pointer inline-flex items-center gap-1"
                                >
                                  <PlusCircle className="w-3.5 h-3.5" />
                                  <span>{t("agency_bridge_btn_relist_or_update")}</span>
                                </button>
                              </div>
                            </div>
                          );
                        })()}
                      </div>
                    </div>

                    {/* Right Column: Property Details, Owners & Payment Plan */}
                    <div className="space-y-6">
                      {/* Card 2: Property details (100% Flutter PropertySpecsFormSection & PropertySettingsScreen Parity) */}
                      <div className="bg-white rounded-2xl border border-slate-200/80 p-5 sm:p-6 shadow-xs space-y-4">
                        <div className="flex items-center justify-between pb-3 border-b border-slate-100">
                          <h3 className="text-base font-bold text-slate-900">
                            {t("agency_prop_details_card_heading")}
                          </h3>
                          <button
                            type="button"
                            onClick={() => openEditPropertySpecsModal(p)}
                            className="text-xs font-semibold text-[#1B5888] hover:underline cursor-pointer"
                          >
                            {t("agency_prop_edit_details")}
                          </button>
                        </div>

                        {(() => {
                          const propTypeLabel =
                            p.property_type === "house"
                              ? t("agency_prop_type_house")
                              : p.property_type === "commercial"
                                ? t("agency_prop_type_commercial")
                                : p.property_type === "garage"
                                  ? t("agency_prop_type_garage")
                                  : t("agency_prop_type_apartment");

                          const roomLabel =
                            p.room_count === "studio"
                              ? t("agency_prop_room_studio")
                              : p.room_count || t("agency_prop_not_added");

                          const floorLabel =
                            p.floor === "suteren"
                              ? t("agency_prop_floor_suteren")
                              : p.floor === "prizemlje"
                                ? t("agency_prop_floor_prizemlje")
                                : p.floor === "visoko_prizemlje"
                                  ? t("agency_prop_floor_visoko_prizemlje")
                                  : p.floor === "potkrovlje"
                                    ? t("agency_prop_floor_potkrovlje")
                                    : p.floor
                                      ? `${p.floor}${p.total_floors ? ` / ${p.total_floors}` : ""}`
                                      : t("agency_prop_not_added");

                          const furnishingLabel =
                            p.furnishing === "furnished"
                              ? t("agency_prop_furnish_furnished")
                              : p.furnishing === "semi_furnished"
                                ? t("agency_prop_furnish_semi_furnished")
                                : p.furnishing === "unfurnished"
                                  ? t("agency_prop_furnish_unfurnished")
                                  : t("agency_prop_not_added");

                          const heatingLabel =
                            p.heating_type === "cg"
                              ? t("agency_prop_heat_cg")
                              : p.heating_type === "eg"
                                ? t("agency_prop_heat_eg")
                                : p.heating_type === "gas"
                                  ? t("agency_prop_heat_gas")
                                  : p.heating_type === "underfloor"
                                    ? t("agency_prop_heat_underfloor")
                                    : p.heating_type === "ta"
                                      ? t("agency_prop_heat_ta")
                                      : p.heating_type === "klima"
                                        ? t("agency_prop_heat_klima")
                                        : p.heating_type || t("agency_prop_not_added");

                          const amenityLabelMap: Record<string, string> = {
                            elevator: t("agency_panel_amenity_elevator"),
                            balcony: t("agency_panel_amenity_balcony"),
                            parking: t("agency_panel_amenity_parking"),
                            garage: t("agency_panel_amenity_garage"),
                            storage: t("agency_panel_amenity_storage"),
                            air_conditioning: t("agency_panel_amenity_ac"),
                            pets_allowed: t("agency_panel_amenity_pets"),
                            security: t("agency_panel_amenity_security"),
                            intercom: t("agency_panel_amenity_intercom"),
                          };

                          return (
                            <div className="space-y-4 pt-1">
                              <div className="grid grid-cols-2 sm:grid-cols-3 gap-4">
                                <div>
                                  <span className="text-xs text-slate-500 font-medium block">
                                    {t("agency_prop_spec_type")}
                                  </span>
                                  <span className="text-sm font-semibold text-slate-900 block mt-1">
                                    {propTypeLabel}
                                  </span>
                                </div>

                                <div>
                                  <span className="text-xs text-slate-500 font-medium block">
                                    {t("agency_prop_spec_rooms")}
                                  </span>
                                  <span className="text-sm font-semibold text-slate-900 block mt-1">
                                    {roomLabel}
                                  </span>
                                </div>

                                <div>
                                  <span className="text-xs text-slate-500 font-medium block">
                                    {t("agency_prop_spec_size")}
                                  </span>
                                  <span className="text-sm font-semibold text-slate-900 block mt-1">
                                    {p.area_sqm ? `${p.area_sqm} m²` : t("agency_prop_not_added")}
                                  </span>
                                </div>

                                <div>
                                  <span className="text-xs text-slate-500 font-medium block">
                                    {t("agency_prop_spec_floor")}
                                  </span>
                                  <span className="text-sm font-semibold text-slate-900 block mt-1">
                                    {floorLabel}
                                  </span>
                                </div>

                                <div>
                                  <span className="text-xs text-slate-500 font-medium block">
                                    {t("agency_prop_spec_unit")}
                                  </span>
                                  <span className="text-sm font-semibold text-slate-900 block mt-1">
                                    {p.unit_number ? `${p.unit_number}` : t("agency_prop_not_added")}
                                  </span>
                                </div>

                                <div>
                                  <span className="text-xs text-slate-500 font-medium block">
                                    {t("agency_prop_spec_furnishing")}
                                  </span>
                                  <span className="text-sm font-semibold text-slate-900 block mt-1">
                                    {furnishingLabel}
                                  </span>
                                </div>

                                <div className="col-span-2 sm:col-span-3">
                                  <span className="text-xs text-slate-500 font-medium block">
                                    {t("agency_prop_spec_heating")}
                                  </span>
                                  <span className="text-sm font-semibold text-slate-900 block mt-1">
                                    {heatingLabel}
                                  </span>
                                </div>
                              </div>

                              {Array.isArray(p.amenities) && p.amenities.length > 0 && (
                                <div className="pt-3 border-t border-slate-100 space-y-2">
                                  <span className="text-xs text-slate-500 font-medium block">
                                    {t("agency_prop_spec_amenities")}
                                  </span>
                                  <div className="flex flex-wrap gap-1.5">
                                    {p.amenities.map((am) => (
                                      <span
                                        key={am}
                                        className="px-2.5 py-1 rounded-lg bg-slate-100 text-slate-700 text-xs font-semibold"
                                      >
                                        {amenityLabelMap[am] || am}
                                      </span>
                                    ))}
                                  </div>
                                </div>
                              )}

                              {p.description && (
                                <div className="pt-3 border-t border-slate-100 space-y-1">
                                  <span className="text-xs text-slate-500 font-medium block">
                                    {t("agency_prop_spec_description")}
                                  </span>
                                  <p className="text-xs text-slate-700 leading-relaxed whitespace-pre-line max-h-[195px] overflow-y-auto pr-1">
                                    {p.description}
                                  </p>
                                </div>
                              )}
                            </div>
                          );
                        })()}
                      </div>
                      {/* Card 3: Owners */}
                      <div className="bg-white rounded-2xl border border-slate-200/80 p-5 sm:p-6 shadow-xs space-y-4">
                        <div className="flex items-center justify-between pb-3 border-b border-slate-100">
                          <h3 className="text-base font-bold text-slate-900 flex items-center gap-2">
                            <span>{t("agency_prop_owners_heading")}</span>
                            <span className="px-2 py-0.5 rounded-full bg-slate-100 text-slate-600 text-xs font-semibold">
                              {p.owners && p.owners.length > 0 ? p.owners.length : p.landlord_name ? 1 : 0}
                            </span>
                          </h3>
                          <button
                            type="button"
                            onClick={() => setEditingOwnersProperty(p)}
                            className="text-xs font-semibold text-[#1B5888] hover:underline cursor-pointer"
                          >
                            {t("editOwners")}
                          </button>
                        </div>

                        <div className="space-y-3">
                          {p.owners && p.owners.length > 0 ? (
                            p.owners.map((owner: any, oIdx: number) => {
                              const isCompany = owner.owner_type === "company";
                              const displayName = isCompany
                                ? owner.company_name?.trim() || t("ownerCompany")
                                : `${owner.first_name || ""} ${owner.last_name || ""}`.trim() || t("ownerIndividual");

                              const isConfirmed = Boolean(
                                p.landlord_id &&
                                (
                                  (owner.email && p.landlord_email && owner.email.trim().toLowerCase() === p.landlord_email.trim().toLowerCase()) ||
                                  owner.is_primary ||
                                  (p.owners && p.owners.length === 1)
                                )
                              );
                              const cleanEmail = owner.email?.trim().toLowerCase();
                              const hasPendingInvite = drawerLandlordInvites.some(
                                (inv) => inv.status === "pending" && inv.invitee_email?.trim().toLowerCase() === cleanEmail
                              );

                              let badgeClass = "bg-[#FEF6E7] text-[#8A5206]";
                              let badgeText = t("agency_prop_invite_not_sent");
                              let buttonText = t("agency_prop_btn_send_invite_short");
                              let isSendAction = true;

                              if (isConfirmed) {
                                badgeClass = "bg-[#EAF5EE] text-[#2A6E43]";
                                badgeText = t("statusApproved");
                                buttonText = t("agency_prop_btn_edit_short");
                                isSendAction = false;
                              } else if (!cleanEmail) {
                                badgeClass = "bg-slate-100 text-slate-500";
                                badgeText = t("statusNoEmail");
                                buttonText = t("agency_prop_btn_edit_short");
                                isSendAction = false;
                              } else if (hasPendingInvite) {
                                badgeClass = "bg-[#EAF5EE] text-[#2A6E43]";
                                badgeText = t("agency_prop_invite_invited");
                                buttonText = t("agency_prop_btn_edit_short");
                                isSendAction = false;
                              }

                              return (
                                <div
                                  key={owner.id || oIdx}
                                  className="flex items-center justify-between p-3 rounded-xl hover:bg-slate-50/70 transition-colors"
                                >
                                  <div className="space-y-0.5 min-w-0">
                                    <p className="text-sm font-bold text-slate-900 truncate">
                                      {displayName}
                                    </p>
                                    <p className="text-xs text-slate-500 truncate">
                                      {isCompany ? t("ownerCompany") : t("ownerIndividual")} • {owner.email || "-"}
                                    </p>
                                  </div>

                                  <div className="flex items-center gap-2 shrink-0">
                                    <span
                                      className={`px-2.5 py-0.5 rounded-full text-xs font-semibold ${badgeClass}`}
                                    >
                                      {badgeText}
                                    </span>
                                    <button
                                      type="button"
                                      onClick={() => {
                                        if (isSendAction) {
                                          openOwnershipModalWithCheck({
                                            ...p,
                                            landlord_name: displayName,
                                            landlord_email: owner.email || p.landlord_email,
                                            landlord_phone: owner.phone || p.landlord_phone,
                                          });
                                        } else {
                                          setEditingOwnersProperty(p);
                                        }
                                      }}
                                      className="px-3.5 py-1.5 rounded-lg border border-slate-300 text-xs font-semibold text-slate-700 hover:bg-slate-100 transition-colors cursor-pointer"
                                    >
                                      {buttonText}
                                    </button>
                                  </div>
                                </div>
                              );
                            })
                          ) : p.landlord_name || p.landlord_email ? (() => {
                            const isConfirmed = Boolean(p.landlord_id);
                            const cleanEmail = p.landlord_email?.trim().toLowerCase();
                            const hasPendingInvite = drawerLandlordInvites.some(
                              (inv) => inv.status === "pending" && inv.invitee_email?.trim().toLowerCase() === cleanEmail
                            );

                            let badgeClass = "bg-[#FEF6E7] text-[#8A5206]";
                            let badgeText = t("agency_prop_invite_not_sent");
                            let buttonText = t("agency_prop_btn_send_invite_short");
                            let isSendAction = true;

                            if (isConfirmed) {
                              badgeClass = "bg-[#EAF5EE] text-[#2A6E43]";
                              badgeText = t("statusApproved");
                              buttonText = t("agency_prop_btn_edit_short");
                              isSendAction = false;
                            } else if (!cleanEmail) {
                              badgeClass = "bg-slate-100 text-slate-500";
                              badgeText = t("statusNoEmail");
                              buttonText = t("agency_prop_btn_edit_short");
                              isSendAction = false;
                            } else if (hasPendingInvite) {
                              badgeClass = "bg-[#EAF5EE] text-[#2A6E43]";
                              badgeText = t("agency_prop_invite_invited");
                              buttonText = t("agency_prop_btn_edit_short");
                              isSendAction = false;
                            }

                            return (
                              <div className="flex items-center justify-between p-3 rounded-xl hover:bg-slate-50/70 transition-colors">
                                <div className="space-y-0.5 min-w-0">
                                  <p className="text-sm font-bold text-slate-900 truncate">
                                    {p.landlord_name || `[${t("ownerIndividual")}]`}
                                  </p>
                                  <p className="text-xs text-slate-500 truncate">
                                    {t("ownerIndividual")} • {p.landlord_email || "-"}
                                  </p>
                                </div>

                                <div className="flex items-center gap-2 shrink-0">
                                  <span
                                    className={`px-2.5 py-0.5 rounded-full text-xs font-semibold ${badgeClass}`}
                                  >
                                    {badgeText}
                                  </span>
                                  <button
                                    type="button"
                                    onClick={() => {
                                      if (isSendAction) {
                                        openOwnershipModalWithCheck(p);
                                      } else {
                                        setEditingOwnersProperty(p);
                                      }
                                    }}
                                    className="px-3.5 py-1.5 rounded-lg border border-slate-300 text-xs font-semibold text-slate-700 hover:bg-slate-100 transition-colors cursor-pointer"
                                  >
                                    {buttonText}
                                  </button>
                                </div>
                              </div>
                            );
                          })() : (
                            <div className="text-center py-6 text-xs text-slate-400 space-y-2">
                              <p>{t("agency_owner_no_owners")}</p>
                              <button
                                type="button"
                                onClick={() => setEditingOwnersProperty(p)}
                                className="px-3.5 py-1.5 rounded-lg bg-[#1B5888] text-white text-xs font-bold hover:bg-[#12406A] transition-colors cursor-pointer"
                              >
                                {t("agency_prop_add_owner")}
                              </button>
                            </div>
                          )}
                        </div>
                      </div>

                      {/* Card 4: Payment plan */}
                      <div className="bg-white rounded-2xl border border-slate-200/80 p-5 sm:p-6 shadow-xs space-y-4">
                        <div className="flex items-center justify-between pb-3 border-b border-slate-100">
                          <div>
                            <h3 className="text-base font-bold text-slate-900">
                              {t("agency_prop_payment_plan_heading")}
                            </h3>
                            <p className="text-xs text-slate-500 mt-0.5">
                              {t("agency_prop_receipts_on_record", {
                                count: String(propPayments.length),
                              })}
                            </p>
                          </div>
                          <button
                            type="button"
                            onClick={() => inspectProperty(p)}
                            className="px-3.5 py-1.5 rounded-xl border border-slate-300 text-xs font-semibold text-slate-700 hover:bg-slate-50 transition-colors cursor-pointer"
                          >
                            {t("agency_prop_refresh_plan")}
                          </button>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              )}

              {/* 3. MAINTENANCE TAB (Flutter _MaintenanceTab) */}
              {propertyDrawerTab === "maintenance" && (
                <div className="space-y-4 animate-in fade-in duration-150">
                  <div className="flex items-center justify-between">
                    <span className="text-xs font-bold text-[#666666]">
                      {t("agency_prop_drawer_tab_maintenance")} ({propMaintenance.length})
                    </span>
                    <button
                      type="button"
                      onClick={() => {
                        if (isDemoMode && !isDemoVerified) {
                          onRequestVerification?.();
                          return;
                        }
                        setNewMaintPropId(p.id);
                        setIsNewMaintModalOpen(true);
                      }}
                      className="inline-flex items-center gap-1 px-3 py-1.5 rounded-[10px] text-xs font-bold bg-[#1B5888] text-white hover:bg-blue-700 transition-colors shadow-xs cursor-pointer"
                    >
                      <Plus className="w-3.5 h-3.5" />
                      <span>{t("agency_prop_drawer_btn_new_ticket")}</span>
                    </button>
                  </div>

                  {propMaintenance.length === 0 ? (
                    <div className="p-8 text-center text-xs text-[#666666] bg-slate-50 rounded-[10px] border border-[#E5E3DF]">
                      <Wrench className="w-8 h-8 text-slate-300 mx-auto mb-2" />
                      <p>{t("agency_prop_drawer_no_maintenance")}</p>
                    </div>
                  ) : (
                    <div className="space-y-2.5">
                      {propMaintenance.map((m) => (
                        <div
                          key={m.id}
                          onClick={() => onOpenMaintenanceRequest?.(m)}
                          className={`bg-white p-4 rounded-[10px] border border-[#E5E3DF] space-y-2 hover:border-[#1B5888] hover:shadow-xs transition-all group ${onOpenMaintenanceRequest ? "cursor-pointer" : ""}`}
                        >
                          <div className="flex items-start justify-between gap-2">
                            <div className="min-w-0">
                              <div className="flex items-center gap-2">
                                <span className="font-mono text-[11px] font-bold text-[#1B5888] bg-[#E5EEF6] px-1.5 py-0.5 rounded-md shrink-0">
                                  {m.ticket_number}
                                </span>
                                <h5 className="text-sm font-bold text-[#1A1A1A] group-hover:text-[#1B5888] transition-colors truncate">
                                  {m.title}
                                </h5>
                              </div>
                              {m.description && (
                                <p className="text-xs text-[#666666] mt-1 line-clamp-2">
                                  {m.description}
                                </p>
                              )}
                            </div>

                            <select
                              value={m.status}
                              disabled={updatingMaintId === m.id}
                              onClick={(e) => e.stopPropagation()}
                              onChange={(e) =>
                                handleUpdateMaintenanceStatus(
                                  m.id,
                                  e.target.value as AgencyMaintenanceRequest["status"]
                                )
                              }
                              aria-label={t("agency_maint_col_status")}
                              className="text-xs font-bold rounded-lg border border-[#E5E3DF] px-2 py-1 bg-white focus:outline-hidden cursor-pointer shrink-0"
                            >
                              <option value="open">{t("agency_maint_status_open")}</option>
                              <option value="in_progress">{t("agency_maint_status_investigating")}</option>
                              <option value="resolved">{t("agency_maint_status_resolved")}</option>
                              <option value="cancelled">{t("agency_maint_status_cancelled")}</option>
                            </select>
                          </div>

                          <div className="flex items-center justify-between gap-2 pt-1.5 border-t border-slate-100 flex-wrap">
                            <div className="flex items-center gap-3 text-xs text-[#666666] flex-wrap">
                              <span>{t(`agency_maint_cat_${m.category}`)}</span>
                              <span>•</span>
                              <span>{t(`agency_maint_prio_${m.priority}`)}</span>
                              {m.cost_amount && (() => {
                                const orig = Number(m.cost_amount) || 0;
                                const settd = Number(m.settled_amount) || 0;
                                const rem = Math.max(0, orig - settd);
                                const isPart = settd > 0 && rem > 0;
                                const cur = m.currency || "EUR";
                                return (
                                  <>
                                    <span>•</span>
                                    <span className="font-bold text-[#1A1A1A]">
                                      {isPart ? `${rem.toLocaleString()} ${cur}` : `${orig.toLocaleString()} ${cur}`} ({t(`agency_maint_payer_${m.paid_by || "landlord"}`)})
                                    </span>
                                    {isPart && (
                                      <span className="text-[11px] font-semibold text-amber-800 bg-amber-50 px-1.5 py-0.5 rounded border border-amber-200">
                                        {t("agency_maint_partial_offset_note", {
                                          original: `${orig.toLocaleString()} ${cur}`,
                                          settled: `${settd.toLocaleString()} ${cur}`,
                                        })}
                                      </span>
                                    )}
                                  </>
                                );
                              })()}
                              <span>•</span>
                              <span>{new Date(m.created_at).toLocaleDateString(activeLocale)}</span>
                            </div>

                            {onOpenMaintenanceRequest && (
                              <button
                                type="button"
                                onClick={(e) => {
                                  e.stopPropagation();
                                  onOpenMaintenanceRequest(m);
                                }}
                                className="inline-flex items-center gap-1 text-xs font-bold text-[#1B5888] hover:text-[#15466d] transition-colors cursor-pointer shrink-0"
                              >
                                <span>{t("goToMaintenanceRequest")}</span>
                                <ChevronRight className="w-3.5 h-3.5 group-hover:translate-x-0.5 transition-transform" />
                              </button>
                            )}
                          </div>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              )}

              {/* 5. AUDIT LOG TAB (Flutter _ActivityTab) */}
              {propertyDrawerTab === "audit" && (() => {
                const notesList = propertyNotes[p.id] || [];
                const isAll = auditFilter === "all";
                const isSystem = auditFilter === "system";
                const isManual = auditFilter === "manual";

                // Real DB activity logs for this property
                const filteredDbLogs = drawerActivityLogs.filter((log) => {
                  if (isManual) return log.type === "manual_note";
                  if (isSystem) return log.type !== "manual_note";
                  return true;
                });

                const totalLogCount = drawerActivityLogs.length > 0
                  ? drawerActivityLogs.length
                  : notesList.length + paidPayments.length + (propContract ? 1 : 0);

                const manualCount = drawerActivityLogs.length > 0
                  ? drawerActivityLogs.filter((l) => l.type === "manual_note").length
                  : notesList.length;

                return (
                  <div className="space-y-4 animate-in fade-in duration-150">
                    {/* Audit Header & Filter */}
                    <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
                      <div className="flex items-center gap-2">
                        <span className="text-xs font-bold text-[#666666]">
                          {t("agency_prop_drawer_tab_audit")}
                        </span>
                        <span className="text-xs px-2 py-0.5 rounded-full bg-slate-100 font-bold text-[#4A4A4A]">
                          {totalLogCount}
                        </span>
                      </div>

                      <div className="flex items-center gap-2">
                        <div className="inline-flex p-1 bg-slate-100 rounded-[10px] text-xs font-semibold">
                          <button
                            type="button"
                            onClick={() => setAuditFilter("all")}
                            className={`px-2.5 py-1 rounded-lg transition-colors cursor-pointer ${isAll ? "bg-white font-bold text-[#1A1A1A] shadow-xs" : "text-[#4A4A4A] hover:text-[#1A1A1A]"
                              }`}
                          >
                            {t("agency_financials_tab_all")}
                          </button>
                          <button
                            type="button"
                            onClick={() => setAuditFilter("system")}
                            className={`px-2.5 py-1 rounded-lg transition-colors cursor-pointer ${isSystem ? "bg-white font-bold text-[#1A1A1A] shadow-xs" : "text-[#4A4A4A] hover:text-[#1A1A1A]"
                              }`}
                          >
                            {t("agency_audit_filter_system")}
                          </button>
                          <button
                            type="button"
                            onClick={() => setAuditFilter("manual")}
                            className={`px-2.5 py-1 rounded-lg transition-colors cursor-pointer ${isManual ? "bg-white font-bold text-[#1A1A1A] shadow-xs" : "text-[#4A4A4A] hover:text-[#1A1A1A]"
                              }`}
                          >
                            {t("agency_audit_filter_notes")} ({manualCount})
                          </button>
                        </div>

                        <button
                          type="button"
                          onClick={() => openAddNoteModal(p)}
                          className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-[10px] text-xs font-bold bg-[#1B5888] text-white hover:bg-blue-700 transition-colors shadow-xs cursor-pointer shrink-0"
                        >
                          <StickyNote className="w-3.5 h-3.5" />
                          <span>{t("agency_note_add_title")}</span>
                        </button>
                      </div>
                    </div>

                    {/* Dynamic Event Stream */}
                    <div className="space-y-3">
                      {drawerActivityLogs.length > 0 ? (
                        filteredDbLogs.map((log) => {
                          const isNote = log.type === "manual_note";
                          const isDisputeOrReject = log.type === "rent_rejected" || log.type === "rent_disputed" || log.type === "invoice_rejected" || log.type === "contract_changes_declined";
                          const isSuccess = log.type === "rent_approved" || log.type === "rent_auto_approved" || log.type === "invitation_accepted" || log.type === "contract_accepted" || log.type === "contract_changes_accepted" || log.type === "landlord_ownership_claimed" || log.type === "maintenance_charge_settled" || (log.type === "payment_toggle" && log.metadata?.paid);
                          const isInvoice = log.type === "invoice_entered" || log.type === "invoice_uploaded" || log.type === "invoice_approved";

                          return (
                            <div
                              key={log.id}
                              className={`flex items-start gap-3 p-3.5 rounded-[10px] border transition-all ${isNote
                                ? "bg-[#FBF1DC]/60 border-[#8A5206]/20"
                                : isDisputeOrReject
                                  ? "bg-[#FBEAE6]/60 border-[#B5432E]/20"
                                  : isSuccess
                                    ? "bg-[#E6F3EA]/60 border-[#2A6E43]/20"
                                    : "bg-[#E5EEF6]/60 border-[#1B5888]/20"
                                }`}
                            >
                              <div
                                className={`w-8 h-8 rounded-[10px] flex items-center justify-center shrink-0 mt-0.5 ${isNote
                                  ? "bg-[#FBF1DC] text-[#8A5206]"
                                  : isDisputeOrReject
                                    ? "bg-[#FBEAE6] text-[#A33C29]"
                                    : isSuccess
                                      ? "bg-[#E6F3EA] text-[#2A6E43]"
                                      : isInvoice
                                        ? "bg-[#E5EEF6] text-[#12406A]"
                                        : "bg-slate-100 text-slate-600"
                                  }`}
                              >
                                {isNote ? (
                                  <StickyNote className="w-4 h-4" />
                                ) : isDisputeOrReject ? (
                                  <AlertCircle className="w-4 h-4" />
                                ) : isSuccess ? (
                                  <CheckCircle2 className="w-4 h-4" />
                                ) : isInvoice ? (
                                  <Receipt className="w-4 h-4" />
                                ) : (
                                  <Clock className="w-4 h-4" />
                                )}
                              </div>

                              <div className="min-w-0 flex-1">
                                <div className="flex items-center justify-between gap-2">
                                  <p className="text-xs font-bold text-[#1A1A1A]">
                                    {formatActivityLogItem(log, propPayments)}
                                  </p>
                                  <div className="flex items-center gap-2 shrink-0">
                                    <span className="text-[10px] text-[#666666] font-mono">
                                      {formatLogTimestamp(log.created_at)}
                                    </span>
                                    {isNote && (
                                      <div className="flex items-center gap-1">
                                        <button
                                          type="button"
                                          onClick={(e) => {
                                            e.stopPropagation();
                                            openEditNoteModal(log);
                                          }}
                                          className="p-1 rounded text-slate-400 hover:text-[#1B5888] hover:bg-white/80 transition-colors cursor-pointer"
                                          title={t("agency_note_btn_edit")}
                                        >
                                          <Pencil className="w-3.5 h-3.5" />
                                        </button>
                                        <button
                                          type="button"
                                          onClick={(e) => {
                                            e.stopPropagation();
                                            handleExecuteDeleteNote(p, log.id);
                                          }}
                                          className="p-1 rounded text-slate-400 hover:text-rose-600 hover:bg-white/80 transition-colors cursor-pointer"
                                          title={t("agency_note_btn_delete")}
                                        >
                                          <Trash2 className="w-3.5 h-3.5" />
                                        </button>
                                      </div>
                                    )}
                                  </div>
                                </div>

                                {log.metadata?.note && (
                                  <p className="text-xs text-[#1A1A1A] mt-1 whitespace-pre-wrap leading-relaxed">
                                    {log.metadata.note}
                                  </p>
                                )}

                                {log.metadata?.reason && (
                                  <p className="text-xs text-[#A33C29] mt-0.5 font-medium">
                                    {log.metadata.reason}
                                  </p>
                                )}

                                {log.metadata?.invoice_url && (
                                  <div className="mt-1.5">
                                    <a
                                      href={log.metadata.invoice_url}
                                      target="_blank"
                                      rel="noopener noreferrer"
                                      className="inline-flex items-center gap-1 text-[11px] font-bold text-[#1B5888] hover:underline"
                                    >
                                      <FileText className="w-3 h-3" />
                                      <span>{t("agency_invoice_btn_view_doc")}</span>
                                    </a>
                                  </div>
                                )}
                              </div>
                            </div>
                          );
                        })
                      ) : (
                        /* Fallback when no DB logs yet */
                        <>
                          {(isAll || isManual) && notesList.map((n) => (
                            <div key={n.id} className="flex items-start gap-3 p-3.5 bg-[#FBF1DC]/60 rounded-[10px] border border-[#8A5206]/20">
                              <div className="w-8 h-8 rounded-[10px] bg-[#FBF1DC] text-[#8A5206] flex items-center justify-center shrink-0 mt-0.5">
                                <StickyNote className="w-4 h-4" />
                              </div>
                              <div className="min-w-0 flex-1">
                                <div className="flex items-center justify-between gap-2">
                                  <span className="text-xs font-bold text-amber-950">
                                    {t("agency_audit_filter_notes")}
                                  </span>
                                  <div className="flex items-center gap-2 shrink-0">
                                    <span className="text-[10px] text-[#8A5206] font-mono">
                                      {formatLogTimestamp(n.created_at)}
                                    </span>
                                    <div className="flex items-center gap-1">
                                      <button
                                        type="button"
                                        onClick={(e) => {
                                          e.stopPropagation();
                                          openEditNoteModal(n);
                                        }}
                                        className="p-1 rounded text-amber-700/60 hover:text-amber-900 hover:bg-white/80 transition-colors cursor-pointer"
                                        title={t("agency_note_btn_edit")}
                                      >
                                        <Pencil className="w-3.5 h-3.5" />
                                      </button>
                                      <button
                                        type="button"
                                        onClick={(e) => {
                                          e.stopPropagation();
                                          handleExecuteDeleteNote(p, n.id);
                                        }}
                                        className="p-1 rounded text-amber-700/60 hover:text-rose-600 hover:bg-white/80 transition-colors cursor-pointer"
                                        title={t("agency_note_btn_delete")}
                                      >
                                        <Trash2 className="w-3.5 h-3.5" />
                                      </button>
                                    </div>
                                  </div>
                                </div>
                                <p className="text-xs text-[#1A1A1A] mt-1 whitespace-pre-wrap leading-relaxed">
                                  {n.note}
                                </p>
                              </div>
                            </div>
                          ))}

                          {(isAll || isSystem) && (
                            <>
                              {awaitingPayments.map((pay) => {
                                const payMonth = pay.due_date
                                  ? new Date(pay.due_date).toLocaleDateString(activeLocale, { month: "long", year: "numeric" })
                                  : "";
                                const isDisp = pay.status === "disputed";
                                return (
                                  <div
                                    key={`awaiting-${pay.id}`}
                                    className={`flex items-start gap-3 p-3.5 rounded-[10px] border ${isDisp
                                        ? "bg-[#FBEAE6]/60 border-[#B5432E]/20"
                                        : "bg-[#E5EEF6]/60 border-[#1B5888]/20"
                                      }`}
                                  >
                                    <div
                                      className={`w-8 h-8 rounded-[10px] flex items-center justify-center shrink-0 mt-0.5 ${isDisp ? "bg-[#FBEAE6] text-[#A33C29]" : "bg-[#E5EEF6] text-[#12406A]"
                                        }`}
                                    >
                                      {isDisp ? <AlertCircle className="w-4 h-4" /> : <Receipt className="w-4 h-4" />}
                                    </div>
                                    <div className="min-w-0 flex-1">
                                      <div className="flex items-center justify-between gap-2">
                                        <p className="text-xs font-bold text-[#1A1A1A]">
                                          {payMonth ? `${payMonth} • ` : ""}
                                          {formatPaymentTitle(pay.title)} ({formatCurrencyAmount(pay.amount, getEffectiveCurrency(pay))}) -{" "}
                                          {isDisp ? t("agency_maint_status_disputed") : t("agency_payments_status_awaiting")}
                                        </p>
                                        <span className="text-[10px] text-[#666666] font-mono">
                                          {pay.declared_at ? formatLogTimestamp(pay.declared_at) : pay.due_date}
                                        </span>
                                      </div>
                                      <p className="text-[11px] text-[#4A4A4A] mt-0.5">
                                        {pay.tenant_name || p.active_tenant_name || "-"}
                                        {isDisp && pay.dispute_reason ? ` • ${pay.dispute_reason}` : ""}
                                      </p>
                                    </div>
                                  </div>
                                );
                              })}

                              {paidPayments.map((pay) => {
                                const payMonth = pay.due_date
                                  ? new Date(pay.due_date).toLocaleDateString(activeLocale, { month: "long", year: "numeric" })
                                  : "";
                                return (
                                  <div key={`paid-${pay.id}`} className="flex items-start gap-3 p-3.5 bg-[#E6F3EA]/60 rounded-[10px] border border-[#2A6E43]/20">
                                    <div className="w-8 h-8 rounded-[10px] bg-[#E6F3EA] text-[#2A6E43] flex items-center justify-center shrink-0 mt-0.5">
                                      <CheckCircle2 className="w-4 h-4" />
                                    </div>
                                    <div className="min-w-0 flex-1">
                                      <div className="flex items-center justify-between gap-2">
                                        <p className="text-xs font-bold text-[#1A1A1A]">
                                          {payMonth ? `${payMonth} • ` : ""}
                                          {formatPaymentTitle(pay.title)} ({formatCurrencyAmount(pay.amount, getEffectiveCurrency(pay))}) - {t("agency_payments_status_paid")}
                                        </p>
                                        <span className="text-[10px] text-[#666666] font-mono">
                                          {pay.paid_at ? formatLogTimestamp(pay.paid_at) : pay.due_date}
                                        </span>
                                      </div>
                                      <p className="text-[11px] text-[#4A4A4A] mt-0.5">
                                        {pay.payment_method ? t(`agency_pay_method_${pay.payment_method}` as any) || pay.payment_method : ""} {pay.owner_note ? `(${pay.owner_note})` : ""}
                                      </p>
                                    </div>
                                  </div>
                                );
                              })}

                              {propContract && (
                                <div className="flex items-start gap-3 p-3.5 bg-slate-50 rounded-[10px] border border-[#E5E3DF]">
                                  <div className="w-8 h-8 rounded-[10px] bg-purple-100 text-purple-700 flex items-center justify-center shrink-0 mt-0.5">
                                    <FileText className="w-4 h-4" />
                                  </div>
                                  <div className="min-w-0 flex-1">
                                    <div className="flex items-center justify-between gap-2">
                                      <p className="text-xs font-bold text-[#1A1A1A]">
                                        {t("agency_prop_drawer_tab_contract")} ({propContract.status.toUpperCase()})
                                      </p>
                                      <span className="text-[10px] text-[#666666] font-mono">
                                        {propContract.start_date}
                                      </span>
                                    </div>
                                    <p className="text-[11px] text-[#666666] mt-0.5">
                                      {propContract.tenant_name || "-"} • €{propContract.monthly_rent} {t("agency_per_month")} • {propContract.start_date} → {propContract.end_date}
                                    </p>
                                  </div>
                                </div>
                              )}
                            </>
                          )}
                        </>
                      )}

                      {filteredDbLogs.length === 0 && drawerActivityLogs.length > 0 && (
                        <div className="p-8 text-center text-xs text-[#666666] bg-slate-50 rounded-[10px] border border-[#E5E3DF]">
                          <Clock className="w-8 h-8 text-slate-300 mx-auto mb-2" />
                          <p>{t("agency_prop_audit_empty")}</p>
                        </div>
                      )}
                    </div>
                  </div>
                );
              })()}
            </div>

            {/* Add Bill / Expense Modal */}
            {isAddPaymentModalOpen && (
              <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/50 backdrop-blur-xs animate-in fade-in duration-200">
                <div className="bg-white rounded-[10px] border border-[#E5E3DF] shadow-xl max-w-md w-full p-6 space-y-4">
                  <div className="flex items-center justify-between border-b border-slate-100 pb-3">
                    <h3 className="text-sm font-bold text-[#1A1A1A] flex items-center gap-2">
                      <Receipt className="w-4 h-4 text-[#1B5888]" />
                      <span>{t("agency_financials_add_title")}</span>
                    </h3>
                    <button
                      type="button"
                      onClick={() => setIsAddPaymentModalOpen(false)}
                      className="text-[#666666] hover:text-[#4A4A4A] p-1 rounded-lg"
                    >
                      <X className="w-4 h-4" />
                    </button>
                  </div>

                  <div className="space-y-3">
                    <div>
                      <label className="text-xs font-bold text-[#4A4A4A] block mb-1">
                        {t("agency_financials_payer_label")}
                      </label>
                      <div className="grid grid-cols-2 gap-2">
                        <button
                          type="button"
                          onClick={() => setNewPaymentPayer("tenant")}
                          className={`px-3 py-2 rounded-[10px] text-xs font-semibold border transition-colors cursor-pointer ${newPaymentPayer === "tenant"
                            ? "bg-[#E5EEF6] border-[#1B5888] text-[#12406A] font-bold"
                            : "bg-slate-50 border-[#E5E3DF] text-[#4A4A4A] hover:bg-slate-100"
                            }`}
                        >
                          {t("agency_financials_payer_tenant")}
                        </button>
                        <button
                          type="button"
                          onClick={() => setNewPaymentPayer("landlord")}
                          className={`px-3 py-2 rounded-[10px] text-xs font-semibold border transition-colors cursor-pointer ${newPaymentPayer === "landlord"
                            ? "bg-[#FBF1DC] border-amber-600 text-[#8A5206] font-bold"
                            : "bg-slate-50 border-[#E5E3DF] text-[#4A4A4A] hover:bg-slate-100"
                            }`}
                        >
                          {t("agency_financials_payer_landlord")}
                        </button>
                      </div>
                    </div>

                    <div>
                      <label className="text-xs font-bold text-[#4A4A4A] block mb-1">
                        {t("agency_financials_field_title")}
                      </label>
                      <input
                        type="text"
                        value={newPaymentTitle}
                        onChange={(e) => setNewPaymentTitle(e.target.value)}
                        placeholder="Örn: Elektrik Faturası, Bina Aidatı"
                        className="w-full text-xs font-semibold rounded-[10px] border border-[#E5E3DF] px-3 py-2 text-[#1A1A1A] focus:outline-hidden focus:border-[#1B5888]"
                      />
                    </div>

                    <div className="grid grid-cols-2 gap-3">
                      <div>
                        <label className="text-xs font-bold text-[#4A4A4A] block mb-1">
                          {t("agency_financials_field_amount")}
                        </label>
                        <input
                          type="number"
                          value={newPaymentAmount}
                          onChange={(e) => setNewPaymentAmount(e.target.value)}
                          placeholder="0.00"
                          className="w-full text-xs font-semibold rounded-[10px] border border-[#E5E3DF] px-3 py-2 text-[#1A1A1A] focus:outline-hidden focus:border-[#1B5888]"
                        />
                      </div>

                      <div>
                        <label className="text-xs font-bold text-[#4A4A4A] block mb-1">
                          {t("agency_financials_field_due_date")}
                        </label>
                        <input
                          type="date"
                          value={newPaymentDueDate}
                          onChange={(e) => setNewPaymentDueDate(e.target.value)}
                          className="w-full text-xs font-semibold rounded-[10px] border border-[#E5E3DF] px-3 py-2 text-[#1A1A1A] focus:outline-hidden focus:border-[#1B5888]"
                        />
                      </div>
                    </div>
                  </div>

                  <div className="flex items-center justify-end gap-2 pt-2 border-t border-slate-100">
                    <button
                      type="button"
                      onClick={() => setIsAddPaymentModalOpen(false)}
                      className="px-3.5 py-2 rounded-[10px] text-xs font-bold text-[#4A4A4A] hover:bg-slate-100 transition-colors cursor-pointer"
                    >
                      {t("agency_prop_drawer_close")}
                    </button>
                    <button
                      type="button"
                      onClick={() => handleCreateManualPayment(p.id)}
                      className="px-4 py-2 rounded-[10px] text-xs font-bold bg-[#1B5888] text-white hover:bg-blue-700 transition-colors shadow-xs cursor-pointer"
                    >
                      {t("agency_financials_btn_save_item")}
                    </button>
                  </div>
                </div>
              </div>
            )}
            {/* 1. RENEW CONTRACT MODAL */}
            {isRenewContractModalOpen && renewContractTarget && (
              <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/50 backdrop-blur-xs animate-in fade-in duration-200">
                <div className="bg-white rounded-[10px] border border-[#E5E3DF] shadow-xl max-w-lg w-full p-6 space-y-4">
                  <div className="flex items-center justify-between border-b border-slate-100 pb-3">
                    <h3 className="text-sm font-bold text-[#1A1A1A] flex items-center gap-2">
                      <TrendingUp className="w-4 h-4 text-[#1B5888]" />
                      <span>{t("agency_contract_renew_title")}</span>
                    </h3>
                    <button
                      type="button"
                      onClick={() => setIsRenewContractModalOpen(false)}
                      className="text-[#666666] hover:text-[#4A4A4A] p-1 rounded-lg"
                    >
                      <X className="w-4 h-4" />
                    </button>
                  </div>

                  <div className="space-y-4">
                    <div className="p-3 bg-slate-50 rounded-[10px] border border-[#E5E3DF] text-xs text-[#4A4A4A] space-y-1">
                      <div className="flex justify-between">
                        <span>{t("agency_prop_drawer_tenant_card")}:</span>
                        <span className="font-bold text-[#1A1A1A]">{renewContractTarget.tenant_name || "-"}</span>
                      </div>
                      <div className="flex justify-between">
                        <span>{t("agency_props_col_rent")}:</span>
                        <span className="font-bold text-[#1A1A1A]">€{renewContractTarget.monthly_rent}</span>
                      </div>
                    </div>

                    <div className="grid grid-cols-2 gap-3">
                      <div>
                        <label className="text-xs font-bold text-[#4A4A4A] block mb-1">
                          {t("agency_contract_renew_rate_label")}
                        </label>
                        <div className="relative">
                          <input
                            type="number"
                            step="0.5"
                            value={renewIncreaseRate}
                            onChange={(e) => handleRenewRateChange(e.target.value)}
                            className="w-full text-xs font-semibold rounded-[10px] border border-[#E5E3DF] pl-3 pr-8 py-2 text-[#1A1A1A] focus:outline-hidden focus:border-[#1B5888]"
                          />
                          <Percent className="w-3.5 h-3.5 text-[#666666] absolute right-3 top-2.5" />
                        </div>
                      </div>

                      <div>
                        <label className="text-xs font-bold text-[#4A4A4A] block mb-1">
                          {t("agency_contract_renew_new_rent_label")}
                        </label>
                        <div className="relative">
                          <input
                            type="number"
                            value={renewMonthlyRent}
                            onChange={(e) => handleRenewRentChange(e.target.value)}
                            className="w-full text-xs font-semibold rounded-[10px] border border-[#E5E3DF] pl-3 pr-8 py-2 text-[#1A1A1A] focus:outline-hidden focus:border-[#1B5888]"
                          />
                          <Euro className="w-3.5 h-3.5 text-[#666666] absolute right-3 top-2.5" />
                        </div>
                      </div>
                    </div>

                    <div className="grid grid-cols-2 gap-3">
                      <div>
                        <label className="text-xs font-bold text-[#4A4A4A] block mb-1">
                          {t("agency_contract_renew_start_date")}
                        </label>
                        <input
                          type="date"
                          value={renewStartDate}
                          onChange={(e) => setRenewStartDate(e.target.value)}
                          className="w-full text-xs font-semibold rounded-[10px] border border-[#E5E3DF] px-3 py-2 text-[#1A1A1A] focus:outline-hidden focus:border-[#1B5888]"
                        />
                      </div>
                      <div>
                        <label className="text-xs font-bold text-[#4A4A4A] block mb-1">
                          {t("agency_contract_renew_end_date")}
                        </label>
                        <input
                          type="date"
                          value={renewEndDate}
                          onChange={(e) => setRenewEndDate(e.target.value)}
                          className="w-full text-xs font-semibold rounded-[10px] border border-[#E5E3DF] px-3 py-2 text-[#1A1A1A] focus:outline-hidden focus:border-[#1B5888]"
                        />
                      </div>
                    </div>
                  </div>

                  <div className="flex items-center justify-end gap-2 pt-3 border-t border-slate-100">
                    <button
                      type="button"
                      onClick={() => setIsRenewContractModalOpen(false)}
                      className="px-3.5 py-2 rounded-[10px] text-xs font-bold text-[#4A4A4A] hover:bg-slate-100 transition-colors cursor-pointer"
                    >
                      {t("agency_prop_drawer_close")}
                    </button>
                    <button
                      type="button"
                      disabled={isRenewingContract}
                      onClick={() => handleExecuteRenewContract(p)}
                      className="px-4 py-2 rounded-[10px] text-xs font-bold bg-[#1B5888] text-white hover:bg-blue-700 transition-colors shadow-xs cursor-pointer disabled:opacity-50"
                    >
                      {isRenewingContract ? "..." : t("agency_contract_btn_save_renewal")}
                    </button>
                  </div>
                </div>
              </div>
            )}

            {/* 2. TERMINATE CONTRACT MODAL */}
            {isTerminateContractModalOpen && terminateContractTarget && (
              <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/50 backdrop-blur-xs animate-in fade-in duration-200">
                <div className="bg-white rounded-[10px] border border-[#E5E3DF] shadow-xl max-w-md w-full p-6 space-y-4">
                  <div className="flex items-center justify-between border-b border-slate-100 pb-3">
                    <h3 className="text-sm font-bold text-[#A33C29] flex items-center gap-2">
                      <CalendarOff className="w-4 h-4 text-[#A33C29]" />
                      <span>{t("agency_contract_terminate_title")}</span>
                    </h3>
                    <button
                      type="button"
                      onClick={() => setIsTerminateContractModalOpen(false)}
                      className="text-[#666666] hover:text-[#4A4A4A] p-1 rounded-lg"
                    >
                      <X className="w-4 h-4" />
                    </button>
                  </div>

                  <p className="text-xs text-[#4A4A4A] leading-relaxed">
                    {t("agency_contract_terminate_desc")}
                  </p>

                  <div>
                    <label className="text-xs font-bold text-[#4A4A4A] block mb-1">
                      {t("agency_contract_renew_end_label")}
                    </label>
                    <input
                      type="date"
                      value={terminateDate}
                      onChange={(e) => setTerminateDate(e.target.value)}
                      className="w-full text-xs font-semibold rounded-[10px] border border-[#E5E3DF] px-3 py-2 text-[#1A1A1A] focus:outline-hidden focus:border-rose-600"
                    />
                  </div>

                  <label className="flex items-start gap-2.5 p-3 rounded-[10px] bg-blue-50/60 border border-blue-200/70 cursor-pointer select-none">
                    <input
                      type="checkbox"
                      checked={relistAfterTerminate}
                      onChange={(e) => setRelistAfterTerminate(e.target.checked)}
                      className="mt-0.5 w-4 h-4 rounded border-blue-300 text-[#1B5888] focus:ring-[#1B5888] cursor-pointer"
                    />
                    <span className="text-xs font-semibold text-slate-800 leading-snug">
                      {t("agency_bridge_terminate_relist_toggle")}
                    </span>
                  </label>

                  <div className="flex items-center justify-end gap-2 pt-3 border-t border-slate-100">
                    <button
                      type="button"
                      onClick={() => setIsTerminateContractModalOpen(false)}
                      className="px-3.5 py-2 rounded-[10px] text-xs font-bold text-[#4A4A4A] hover:bg-slate-100 transition-colors cursor-pointer"
                    >
                      {t("agency_prop_drawer_close")}
                    </button>
                    <button
                      type="button"
                      disabled={isTerminatingContract}
                      onClick={() => handleExecuteTerminateContract(p)}
                      className="px-4 py-2 rounded-[10px] text-xs font-bold bg-rose-600 text-white hover:bg-rose-700 transition-colors shadow-xs cursor-pointer disabled:opacity-50"
                    >
                      {isTerminatingContract ? "..." : t("agency_contract_btn_terminate")}
                    </button>
                  </div>
                </div>
              </div>
            )}



            {/* 4. MARK AS PAID MODAL */}
            {isMarkPaidModalOpen && markPaidPayment && (
              <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/50 backdrop-blur-xs animate-in fade-in duration-200">
                <div className="bg-white rounded-[10px] border border-[#E5E3DF] shadow-xl max-w-md w-full p-6 space-y-4">
                  <div className="flex items-center justify-between border-b border-slate-100 pb-3">
                    <h3 className="text-sm font-bold text-[#1A1A1A] flex items-center gap-2">
                      <CheckCircle2 className="w-4 h-4 text-[#2A6E43]" />
                      <span>{t("agency_financials_mark_paid")}</span>
                    </h3>
                    <button
                      type="button"
                      onClick={() => setIsMarkPaidModalOpen(false)}
                      className="text-[#666666] hover:text-[#4A4A4A] p-1 rounded-lg"
                    >
                      <X className="w-4 h-4" />
                    </button>
                  </div>

                  <div className="p-3 bg-slate-50 rounded-[10px] border border-[#E5E3DF] text-xs text-[#4A4A4A] space-y-1">
                    <div className="flex justify-between">
                      <span>{markPaidPayment.title}</span>
                      <span className="font-bold text-[#1A1A1A]">€{markPaidPayment.amount}</span>
                    </div>
                    <div className="flex justify-between text-[11px] text-[#666666]">
                      <span>{t("agency_prop_drawer_due_day")}:</span>
                      <span>{markPaidPayment.due_date}</span>
                    </div>
                  </div>

                  <div className="space-y-3">
                    <div>
                      <label className="text-xs font-bold text-[#4A4A4A] block mb-1">
                        {t("agency_pay_method_label")}
                      </label>
                      <div className="grid grid-cols-3 gap-2">
                        <button
                          type="button"
                          onClick={() => setMarkPaidMethod("bank_transfer")}
                          className={`px-2 py-2 rounded-[10px] text-xs font-semibold border transition-colors cursor-pointer text-center ${markPaidMethod === "bank_transfer"
                            ? "bg-[#E5EEF6] border-[#1B5888] text-[#12406A] font-bold"
                            : "bg-slate-50 border-[#E5E3DF] text-[#4A4A4A] hover:bg-slate-100"
                            }`}
                        >
                          {t("agency_pay_method_bank")}
                        </button>
                        <button
                          type="button"
                          onClick={() => setMarkPaidMethod("cash")}
                          className={`px-2 py-2 rounded-[10px] text-xs font-semibold border transition-colors cursor-pointer text-center ${markPaidMethod === "cash"
                            ? "bg-[#FBF1DC] border-amber-600 text-[#8A5206] font-bold"
                            : "bg-slate-50 border-[#E5E3DF] text-[#4A4A4A] hover:bg-slate-100"
                            }`}
                        >
                          {t("agency_pay_method_cash")}
                        </button>
                        <button
                          type="button"
                          onClick={() => setMarkPaidMethod("card")}
                          className={`px-2 py-2 rounded-[10px] text-xs font-semibold border transition-colors cursor-pointer text-center ${markPaidMethod === "card"
                            ? "bg-purple-50 border-purple-600 text-purple-700 font-bold"
                            : "bg-slate-50 border-[#E5E3DF] text-[#4A4A4A] hover:bg-slate-100"
                            }`}
                        >
                          {t("agency_pay_method_card")}
                        </button>
                      </div>
                    </div>

                    <div>
                      <label className="text-xs font-bold text-[#4A4A4A] block mb-1">
                        {t("agency_bulk_collection_date")}
                      </label>
                      <input
                        type="date"
                        value={markPaidDate}
                        onChange={(e) => setMarkPaidDate(e.target.value)}
                        className="w-full text-xs font-semibold rounded-[10px] border border-[#E5E3DF] px-3 py-2 text-[#1A1A1A] focus:outline-hidden focus:border-[#1B5888]"
                      />
                    </div>

                    <div>
                      <label className="text-xs font-bold text-[#4A4A4A] block mb-1">
                        {t("agency_bulk_note_label")}
                      </label>
                      <input
                        type="text"
                        value={markPaidNote}
                        onChange={(e) => setMarkPaidNote(e.target.value)}
                        placeholder={t("agency_bulk_note_placeholder")}
                        className="w-full text-xs font-semibold rounded-[10px] border border-[#E5E3DF] px-3 py-2 text-[#1A1A1A] focus:outline-hidden focus:border-[#1B5888]"
                      />
                    </div>
                  </div>

                  <div className="flex items-center justify-end gap-2 pt-3 border-t border-slate-100">
                    <button
                      type="button"
                      onClick={() => setIsMarkPaidModalOpen(false)}
                      className="px-3.5 py-2 rounded-[10px] text-xs font-bold text-[#4A4A4A] hover:bg-slate-100 transition-colors cursor-pointer"
                    >
                      {t("agency_prop_drawer_close")}
                    </button>
                    <button
                      type="button"
                      disabled={isSubmittingMarkPaid}
                      onClick={handleExecuteMarkPaid}
                      className="px-4 py-2 rounded-[10px] text-xs font-bold bg-[#1B5888] text-white hover:bg-emerald-700 transition-colors shadow-xs cursor-pointer disabled:opacity-50"
                    >
                      {isSubmittingMarkPaid ? "..." : t("agency_financials_mark_paid")}
                    </button>
                  </div>
                </div>
              </div>
            )}

            {/* 4.5. BULK MARK AS PAID MODAL (Flutter SSOT Parity) */}
            {isBulkMarkPaidModalOpen && selectedPaymentIds.size > 0 && (() => {
              const selectedList = payments.filter((pay) => selectedPaymentIds.has(pay.id));
              const totalsByCurrency: Record<string, number> = {};
              for (const pay of selectedList) {
                const cur = getEffectiveCurrency(pay);
                totalsByCurrency[cur] = (totalsByCurrency[cur] || 0) + (Number(pay.amount) || 0);
              }
              const formattedTotal = Object.entries(totalsByCurrency)
                .map(([cur, amt]) => (cur === "RSD" ? `${amt.toLocaleString()} RSD` : `€${amt.toLocaleString()}`))
                .join(" + ");

              return (
                <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/50 backdrop-blur-xs animate-in fade-in duration-200">
                  <div className="bg-white rounded-2xl border border-slate-200 shadow-xl max-w-lg w-full p-6 space-y-4 max-h-[90vh] overflow-y-auto">
                    <div className="flex items-center justify-between border-b border-slate-100 pb-3">
                      <div className="flex items-center gap-2.5">
                        <div className="w-8 h-8 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center shrink-0">
                          <CheckCheck className="w-4 h-4" />
                        </div>
                        <div>
                          <h3 className="text-sm font-bold text-slate-900">
                            {t("agency_bulk_mark_paid_title")}
                          </h3>
                          <p className="text-xs text-slate-500">
                            {t("agency_bulk_mark_paid_sub", { count: String(selectedList.length) })}
                          </p>
                        </div>
                      </div>
                      <button
                        type="button"
                        onClick={() => setIsBulkMarkPaidModalOpen(false)}
                        className="text-slate-400 hover:text-slate-700 p-1 rounded-lg"
                      >
                        <X className="w-4 h-4" />
                      </button>
                    </div>

                    {/* Selected Debts Summary Box */}
                    <div className="p-3.5 bg-slate-50 rounded-xl border border-slate-200 text-xs space-y-2">
                      <div className="flex justify-between items-center font-bold">
                        <span className="text-slate-600">{t("agency_bulk_selected_debts")}:</span>
                        <span className="text-emerald-700 text-sm font-extrabold">{formattedTotal}</span>
                      </div>
                      <div className="border-t border-slate-200 pt-2 space-y-1.5 max-h-36 overflow-y-auto pr-1">
                        {selectedList.map((pay) => (
                          <div key={pay.id} className="flex justify-between items-center text-slate-700">
                            <span className="truncate pr-2 font-medium">
                              {formatPaymentTitle(pay.title)} ({pay.due_date || "-"})
                            </span>
                            <span className="font-bold text-slate-900 shrink-0">
                              {pay.currency === "RSD" ? `${pay.amount.toLocaleString()} RSD` : `€${pay.amount.toLocaleString()}`}
                            </span>
                          </div>
                        ))}
                      </div>
                    </div>

                    {/* Payment Method */}
                    <div className="space-y-3">
                      <div>
                        <label className="text-xs font-bold text-slate-700 block mb-1">
                          {t("agency_pay_method_label")}
                        </label>
                        <div className="grid grid-cols-3 gap-2">
                          <button
                            type="button"
                            onClick={() => setBulkMarkPaidMethod("bank_transfer")}
                            className={`px-2 py-2 rounded-xl text-xs font-semibold border transition-colors cursor-pointer text-center ${bulkMarkPaidMethod === "bank_transfer"
                              ? "bg-[#E5EEF6] border-[#1B5888] text-[#12406A] font-bold"
                              : "bg-slate-50 border-slate-200 text-slate-700 hover:bg-slate-100"
                              }`}
                          >
                            {t("agency_pay_method_bank")}
                          </button>
                          <button
                            type="button"
                            onClick={() => setBulkMarkPaidMethod("cash")}
                            className={`px-2 py-2 rounded-xl text-xs font-semibold border transition-colors cursor-pointer text-center ${bulkMarkPaidMethod === "cash"
                              ? "bg-[#FBF1DC] border-amber-600 text-[#8A5206] font-bold"
                              : "bg-slate-50 border-slate-200 text-slate-700 hover:bg-slate-100"
                              }`}
                          >
                            {t("agency_pay_method_cash")}
                          </button>
                          <button
                            type="button"
                            onClick={() => setBulkMarkPaidMethod("card")}
                            className={`px-2 py-2 rounded-xl text-xs font-semibold border transition-colors cursor-pointer text-center ${bulkMarkPaidMethod === "card"
                              ? "bg-purple-50 border-purple-600 text-purple-700 font-bold"
                              : "bg-slate-50 border-slate-200 text-slate-700 hover:bg-slate-100"
                              }`}
                          >
                            {t("agency_pay_method_card")}
                          </button>
                        </div>
                      </div>

                      <div>
                        <label className="text-xs font-bold text-slate-700 block mb-1">
                          {t("agency_bulk_collection_date")}
                        </label>
                        <input
                          type="date"
                          value={bulkMarkPaidDate}
                          onChange={(e) => setBulkMarkPaidDate(e.target.value)}
                          className="w-full text-xs font-semibold rounded-xl border border-slate-200 px-3 py-2 text-slate-900 focus:outline-hidden focus:border-[#1B5888]"
                        />
                      </div>

                      {/* Shared Receipt File (Optional) */}
                      <div>
                        <label className="text-xs font-bold text-slate-700 block mb-1">
                          {t("agency_bulk_shared_receipt")}
                        </label>
                        {bulkReceiptFileName ? (
                          <div className="flex items-center justify-between p-2.5 rounded-xl border border-emerald-200 bg-emerald-50 text-xs text-emerald-800">
                            <div className="flex items-center gap-2 truncate">
                              <FileText className="w-4 h-4 text-emerald-600 shrink-0" />
                              <span className="truncate font-semibold">{bulkReceiptFileName}</span>
                            </div>
                            <button
                              type="button"
                              onClick={() => {
                                setBulkReceiptFile(null);
                                setBulkReceiptFileName("");
                                setBulkReceiptFileUrl(null);
                              }}
                              className="text-rose-600 hover:text-rose-800 p-1 font-bold cursor-pointer"
                              title={t("agency_doc_remove")}
                            >
                              <X className="w-3.5 h-3.5" />
                            </button>
                          </div>
                        ) : (
                          <label className="flex flex-col items-center justify-center p-3.5 rounded-xl border-2 border-dashed border-slate-200 hover:border-blue-400 bg-slate-50 hover:bg-blue-50/30 transition-colors cursor-pointer text-center">
                            <UploadCloud className="w-5 h-5 text-slate-500 mb-1" />
                            <span className="text-xs font-bold text-slate-700">{t("agency_doc_pick_file")}</span>
                            <span className="text-[10px] text-slate-500 mt-0.5">{t("agency_doc_file_formats")}</span>
                            <input
                              type="file"
                              accept=".pdf,image/png,image/jpeg,image/webp"
                              className="hidden"
                              onChange={(e) => {
                                const file = e.target.files?.[0];
                                if (file) {
                                  setBulkReceiptFile(file);
                                  setBulkReceiptFileName(file.name);
                                  const reader = new FileReader();
                                  reader.onload = (event) => {
                                    setBulkReceiptFileUrl(event.target?.result as string);
                                  };
                                  reader.readAsDataURL(file);
                                }
                              }}
                            />
                          </label>
                        )}
                      </div>

                      <div>
                        <label className="text-xs font-bold text-slate-700 block mb-1">
                          {t("agency_bulk_note_label")}
                        </label>
                        <input
                          type="text"
                          value={bulkMarkPaidNote}
                          onChange={(e) => setBulkMarkPaidNote(e.target.value)}
                          placeholder={t("agency_bulk_note_placeholder")}
                          className="w-full text-xs font-semibold rounded-xl border border-slate-200 px-3 py-2 text-slate-900 focus:outline-hidden focus:border-[#1B5888]"
                        />
                      </div>
                    </div>

                    <div className="flex items-center justify-end gap-2 pt-3 border-t border-slate-100">
                      <button
                        type="button"
                        disabled={isSubmittingBulkMarkPaid}
                        onClick={() => setIsBulkMarkPaidModalOpen(false)}
                        className="px-3.5 py-2 rounded-xl text-xs font-bold text-slate-600 hover:bg-slate-100 transition-colors cursor-pointer"
                      >
                        {t("agency_prop_drawer_close")}
                      </button>
                      <button
                        type="button"
                        disabled={isSubmittingBulkMarkPaid}
                        onClick={handleExecuteBulkMarkPaid}
                        className="px-4 py-2 rounded-xl text-xs font-bold bg-[#059669] hover:bg-emerald-700 text-white transition-colors shadow-xs cursor-pointer disabled:opacity-50 flex items-center gap-1.5"
                      >
                        <Check className="w-3.5 h-3.5" />
                        <span>{isSubmittingBulkMarkPaid ? "..." : t("agency_bulk_btn_save_paid")}</span>
                      </button>
                    </div>
                  </div>
                </div>
              );
            })()}

            {/* 5. DISPUTE / REJECT MODAL */}
            {isDisputeModalOpen && disputePayment && (
              <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/50 backdrop-blur-xs animate-in fade-in duration-200">
                <div className="bg-white rounded-[10px] border border-[#E5E3DF] shadow-xl max-w-md w-full p-6 space-y-4">
                  <div className="flex items-center justify-between border-b border-slate-100 pb-3">
                    <h3 className="text-sm font-bold text-[#A33C29] flex items-center gap-2">
                      <AlertCircle className="w-4 h-4 text-[#A33C29]" />
                      <span>{t("agency_pay_dispute_title")}</span>
                    </h3>
                    <button
                      type="button"
                      onClick={() => setIsDisputeModalOpen(false)}
                      className="text-[#666666] hover:text-[#4A4A4A] p-1 rounded-lg"
                    >
                      <X className="w-4 h-4" />
                    </button>
                  </div>

                  <div className="p-3 bg-slate-50 rounded-[10px] border border-[#E5E3DF] text-xs text-[#4A4A4A]">
                    <p className="font-bold text-[#1A1A1A]">{disputePayment.title} - €{disputePayment.amount}</p>
                    <p className="text-[11px] text-[#666666] mt-0.5">{disputePayment.tenant_name || p.active_tenant_name}</p>
                  </div>

                  <div>
                    <label className="text-xs font-bold text-[#4A4A4A] block mb-1">
                      {t("agency_pay_dispute_reason")} *
                    </label>
                    <textarea
                      rows={3}
                      value={disputeReason}
                      onChange={(e) => setDisputeReason(e.target.value)}
                      placeholder="Örn: Dekont tutarı kira ile uyuşmuyor veya hesap no hatalı"
                      className="w-full text-xs font-semibold rounded-[10px] border border-[#E5E3DF] p-3 text-[#1A1A1A] focus:outline-hidden focus:border-rose-600"
                    />
                  </div>

                  <div className="flex items-center justify-end gap-2 pt-3 border-t border-slate-100">
                    <button
                      type="button"
                      onClick={() => setIsDisputeModalOpen(false)}
                      className="px-3.5 py-2 rounded-[10px] text-xs font-bold text-[#4A4A4A] hover:bg-slate-100 transition-colors cursor-pointer"
                    >
                      {t("agency_prop_drawer_close")}
                    </button>
                    <button
                      type="button"
                      disabled={isSubmittingDispute || !disputeReason.trim()}
                      onClick={handleExecuteDispute}
                      className="px-4 py-2 rounded-[10px] text-xs font-bold bg-rose-600 text-white hover:bg-rose-700 transition-colors shadow-xs cursor-pointer disabled:opacity-50"
                    >
                      {isSubmittingDispute ? "..." : t("agency_pay_btn_confirm_dispute")}
                    </button>
                  </div>
                </div>
              </div>
            )}

            {/* 6. ADD NOTE MODAL */}
            {isAddNoteModalOpen && (
              <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/50 backdrop-blur-xs animate-in fade-in duration-200">
                <div className="bg-white rounded-[10px] border border-[#E5E3DF] shadow-xl max-w-md w-full p-6 space-y-4">
                  <div className="flex items-center justify-between border-b border-slate-100 pb-3">
                    <h3 className="text-sm font-bold text-[#1A1A1A] flex items-center gap-2">
                      <StickyNote className="w-4 h-4 text-[#1B5888]" />
                      <span>{t("agency_note_add_title")}</span>
                    </h3>
                    <button
                      type="button"
                      onClick={() => setIsAddNoteModalOpen(false)}
                      className="text-[#666666] hover:text-[#4A4A4A] p-1 rounded-lg"
                    >
                      <X className="w-4 h-4" />
                    </button>
                  </div>

                  <div className="space-y-3">
                    <div>
                      <label className="text-xs font-bold text-[#4A4A4A] block mb-1">
                        {t("agency_note_field_date")}
                      </label>
                      <input
                        type="date"
                        value={newNoteDate}
                        onChange={(e) => setNewNoteDate(e.target.value)}
                        className="w-full text-xs font-semibold rounded-[10px] border border-[#E5E3DF] px-3 py-2 text-[#1A1A1A] focus:outline-hidden focus:border-[#1B5888]"
                      />
                    </div>

                    <div>
                      <label className="text-xs font-bold text-[#4A4A4A] block mb-1">
                        {t("agency_note_field_content")} *
                      </label>
                      <textarea
                        rows={4}
                        value={newNoteText}
                        onChange={(e) => setNewNoteText(e.target.value)}
                        placeholder={t("agency_note_content_placeholder")}
                        className="w-full text-xs font-semibold rounded-[10px] border border-[#E5E3DF] p-3 text-[#1A1A1A] focus:outline-hidden focus:border-[#1B5888]"
                      />
                    </div>
                  </div>

                  <div className="flex items-center justify-end gap-2 pt-3 border-t border-slate-100">
                    <button
                      type="button"
                      onClick={() => setIsAddNoteModalOpen(false)}
                      className="px-3.5 py-2 rounded-[10px] text-xs font-bold text-[#4A4A4A] hover:bg-slate-100 transition-colors cursor-pointer"
                    >
                      {t("agency_prop_drawer_close")}
                    </button>
                    <button
                      type="button"
                      disabled={isSubmittingNote || !newNoteText.trim()}
                      onClick={() => handleExecuteSaveNote(p)}
                      className="px-4 py-2 rounded-[10px] text-xs font-bold bg-[#1B5888] text-white hover:bg-blue-700 transition-colors shadow-xs cursor-pointer disabled:opacity-50"
                    >
                      {isSubmittingNote ? "..." : t("agency_note_btn_save")}
                    </button>
                  </div>
                </div>
              </div>
            )}

            {/* 6.1 EDIT NOTE MODAL */}
            {isEditNoteModalOpen && editingNoteLog && (
              <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/50 backdrop-blur-xs animate-in fade-in duration-200">
                <div className="bg-white rounded-[10px] border border-[#E5E3DF] shadow-xl max-w-md w-full p-6 space-y-4">
                  <div className="flex items-center justify-between border-b border-slate-100 pb-3">
                    <h3 className="text-sm font-bold text-[#1A1A1A] flex items-center gap-2">
                      <StickyNote className="w-4 h-4 text-[#1B5888]" />
                      <span>{t("agency_note_edit_title")}</span>
                    </h3>
                    <button
                      type="button"
                      onClick={() => {
                        setIsEditNoteModalOpen(false);
                        setEditingNoteLog(null);
                      }}
                      className="text-[#666666] hover:text-[#4A4A4A] p-1 rounded-lg"
                    >
                      <X className="w-4 h-4" />
                    </button>
                  </div>

                  <div className="space-y-3">
                    <div>
                      <label className="text-xs font-bold text-[#4A4A4A] block mb-1">
                        {t("agency_note_field_content")} *
                      </label>
                      <textarea
                        rows={4}
                        value={editNoteText}
                        onChange={(e) => setEditNoteText(e.target.value)}
                        placeholder={t("agency_note_content_placeholder")}
                        className="w-full text-xs font-semibold rounded-[10px] border border-[#E5E3DF] p-3 text-[#1A1A1A] focus:outline-hidden focus:border-[#1B5888]"
                      />
                    </div>
                  </div>

                  <div className="flex items-center justify-end gap-2 pt-3 border-t border-slate-100">
                    <button
                      type="button"
                      onClick={() => {
                        setIsEditNoteModalOpen(false);
                        setEditingNoteLog(null);
                      }}
                      className="px-3.5 py-2 rounded-[10px] text-xs font-bold text-[#4A4A4A] hover:bg-slate-100 transition-colors cursor-pointer"
                    >
                      {t("agency_prop_drawer_close")}
                    </button>
                    <button
                      type="button"
                      disabled={isSubmittingEditNote || !editNoteText.trim()}
                      onClick={() => handleExecuteUpdateNote(p)}
                      className="px-4 py-2 rounded-[10px] text-xs font-bold bg-[#1B5888] text-white hover:bg-blue-700 transition-colors shadow-xs cursor-pointer disabled:opacity-50"
                    >
                      {isSubmittingEditNote ? "..." : t("agency_note_btn_update")}
                    </button>
                  </div>
                </div>
              </div>
            )}
            {/* 7. INVOICE ENTRY & UPLOAD MODAL (Flutter _handleInvoiceUpload SSOT) */}
            {isInvoiceModalOpen && invoicePayment && (
              <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/50 backdrop-blur-xs animate-in fade-in duration-200">
                <div className="bg-white rounded-[10px] border border-[#E5E3DF] shadow-xl max-w-md w-full p-6 space-y-4">
                  <div className="flex items-center justify-between border-b border-slate-100 pb-3">
                    <h3 className="text-sm font-bold text-[#1A1A1A] flex items-center gap-2">
                      <FilePlus className="w-4 h-4 text-[#1B5888]" />
                      <span>{t("agency_invoice_modal_title")}</span>
                    </h3>
                    <button
                      type="button"
                      onClick={() => setIsInvoiceModalOpen(false)}
                      className="text-[#666666] hover:text-[#4A4A4A] p-1 rounded-lg"
                    >
                      <X className="w-4 h-4" />
                    </button>
                  </div>

                  <div className="p-3 bg-slate-50 rounded-[10px] border border-[#E5E3DF] text-xs text-[#4A4A4A] space-y-1">
                    <p className="font-bold text-[#1A1A1A]">{invoicePayment.title}</p>
                    <p className="text-[11px] text-[#666666]">{invoicePayment.property_title || p.title} • {invoicePayment.due_date}</p>
                  </div>

                  <div className="space-y-3">
                    <div className="grid grid-cols-3 gap-3">
                      <div className="col-span-2">
                        <label className="text-xs font-bold text-[#4A4A4A] block mb-1">
                          {t("agency_invoice_field_amount")} *
                        </label>
                        <input
                          type="number"
                          step="0.01"
                          value={invoiceAmount}
                          onChange={(e) => setInvoiceAmount(e.target.value)}
                          placeholder="0.00"
                          className="w-full text-xs font-semibold rounded-[10px] border border-[#E5E3DF] px-3 py-2 text-[#1A1A1A] focus:outline-hidden focus:border-[#1B5888]"
                        />
                      </div>

                      <div>
                        <label className="text-xs font-bold text-[#4A4A4A] block mb-1">
                          {t("agency_invoice_field_currency")}
                        </label>
                        <select
                          value={invoiceCurrency}
                          onChange={(e) => setInvoiceCurrency(e.target.value as any)}
                          className="w-full text-xs font-semibold rounded-[10px] border border-[#E5E3DF] px-3 py-2 text-[#1A1A1A] focus:outline-hidden focus:border-[#1B5888] bg-white"
                        >
                          <option value="RSD">RSD</option>
                          <option value="EUR">EUR</option>
                        </select>
                      </div>
                    </div>

                    <div>
                      <label className="text-xs font-bold text-[#4A4A4A] block mb-1">
                        {t("agency_invoice_field_due_date")}
                      </label>
                      <input
                        type="date"
                        value={invoiceDueDate}
                        onChange={(e) => setInvoiceDueDate(e.target.value)}
                        className="w-full text-xs font-semibold rounded-[10px] border border-[#E5E3DF] px-3 py-2 text-[#1A1A1A] focus:outline-hidden focus:border-[#1B5888]"
                      />
                    </div>

                    <div>
                      <label className="text-xs font-bold text-[#4A4A4A] block mb-1">
                        {t("agency_invoice_field_note")}
                      </label>
                      <input
                        type="text"
                        value={invoiceNote}
                        onChange={(e) => setInvoiceNote(e.target.value)}
                        placeholder={t("agency_invoice_field_note_placeholder")}
                        className="w-full text-xs font-semibold rounded-[10px] border border-[#E5E3DF] px-3 py-2 text-[#1A1A1A] focus:outline-hidden focus:border-[#1B5888]"
                      />
                    </div>

                    <div>
                      <label className="text-xs font-bold text-[#4A4A4A] block mb-1">
                        {t("agency_invoice_field_file")}
                      </label>
                      {invoiceFileUrl ? (
                        <div className="flex items-center justify-between p-2.5 rounded-[10px] border border-[#2A6E43]/20 bg-[#E6F3EA] text-xs text-[#2A6E43]">
                          <div className="flex items-center gap-2 truncate">
                            <FileText className="w-4 h-4 text-[#2A6E43] shrink-0" />
                            <span className="truncate font-semibold">{invoiceFileName || "fatura_belgesi.pdf"}</span>
                          </div>
                          <button
                            type="button"
                            onClick={() => {
                              setInvoiceFileUrl(null);
                              setInvoiceFileName("");
                            }}
                            className="text-[#A33C29] hover:text-[#A33C29] p-1 font-bold cursor-pointer"
                            title="Kaldır"
                          >
                            <X className="w-3.5 h-3.5" />
                          </button>
                        </div>
                      ) : (
                        <label className="flex flex-col items-center justify-center p-4 rounded-[10px] border-2 border-dashed border-[#E5E3DF] hover:border-blue-400 bg-slate-50 hover:bg-[#E5EEF6]/40 transition-colors cursor-pointer text-center">
                          <UploadCloud className="w-6 h-6 text-[#666666] mb-1" />
                          <span className="text-xs font-bold text-[#4A4A4A]">Belge / Dosya Seç</span>
                          <span className="text-[10px] text-[#666666] mt-0.5">PDF, PNG veya JPEG (Maks. 10MB)</span>
                          <input
                            type="file"
                            accept=".pdf,image/png,image/jpeg,image/webp"
                            className="hidden"
                            onChange={(e) => {
                              const file = e.target.files?.[0];
                              if (file) {
                                setInvoiceFileName(file.name);
                                const reader = new FileReader();
                                reader.onload = (event) => {
                                  setInvoiceFileUrl(event.target?.result as string);
                                };
                                reader.readAsDataURL(file);
                              }
                            }}
                          />
                        </label>
                      )}
                    </div>
                  </div>

                  <div className="flex items-center justify-end gap-2 pt-3 border-t border-slate-100">
                    <button
                      type="button"
                      onClick={() => setIsInvoiceModalOpen(false)}
                      className="px-3.5 py-2 rounded-[10px] text-xs font-bold text-[#4A4A4A] hover:bg-slate-100 transition-colors cursor-pointer"
                    >
                      {t("agency_prop_drawer_close")}
                    </button>
                    <button
                      type="button"
                      disabled={isSubmittingInvoice}
                      onClick={() => handleExecuteSaveInvoice(p)}
                      className="px-4 py-2 rounded-[10px] text-xs font-bold bg-[#1B5888] text-white hover:bg-blue-700 transition-colors shadow-xs cursor-pointer disabled:opacity-50"
                    >
                      {isSubmittingInvoice ? "..." : t("agency_financials_btn_save_item")}
                    </button>
                  </div>
                </div>
              </div>
            )}
          </div>
        );
      })() : (
        <>
          {/* ── 1. Top Tier: Collapsible Search & Detailed Filters Panel ── */}
          <div className="bg-[#F8FAFC] border border-[#E2E8F0] rounded-[10px] p-4 shadow-2xs space-y-3">
            <div
              onClick={() => setIsFilterExpanded(!isFilterExpanded)}
              className="flex items-center justify-between cursor-pointer select-none text-[#1B5888] hover:text-[#15466d] transition-colors"
            >
              <div className="flex items-center gap-2 font-bold text-xs sm:text-sm">
                <SlidersHorizontal className="w-4 h-4 text-[#1B5888]" />
                <span>{t("searchAndFilterPanel")}</span>
                {hasActiveDetailedFilters && (
                  <span className="px-2 py-0.5 rounded-md text-[10px] font-bold bg-[#1B5888]/10 text-[#1B5888]">
                    {t("filterActiveLabel")}
                  </span>
                )}
              </div>
              <button type="button" className="p-1 rounded-md text-slate-400 hover:text-slate-600 cursor-pointer">
                {isFilterExpanded ? <ChevronUp className="w-4 h-4" /> : <ChevronDown className="w-4 h-4" />}
              </button>
            </div>

            {isFilterExpanded && (
              <div className="space-y-3 pt-1 text-xs">
                {/* Row 1: Search Input */}
                <div className="relative bg-white rounded-[8px] border border-[#E2E8F0] shadow-2xs">
                  <Search className="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" />
                  <input
                    type="text"
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    placeholder={t("searchPlaceholder")}
                    className="w-full pl-10 pr-9 py-2.5 text-[#0F172A] placeholder:text-slate-400 rounded-[8px] focus:outline-hidden focus:ring-2 focus:ring-[#1B5888]/20 focus:border-[#1B5888]"
                  />
                  {searchQuery && (
                    <button
                      type="button"
                      onClick={() => setSearchQuery("")}
                      className="absolute right-3 top-1/2 -translate-y-1/2 p-1 text-slate-400 hover:text-slate-600 rounded-full cursor-pointer"
                    >
                      <X className="w-3.5 h-3.5" />
                    </button>
                  )}
                </div>

                {/* Row 2: City, Landlord, Group By, Sort By */}
                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3">
                  {/* City Filter */}
                  <div className="relative bg-white rounded-[8px] border border-[#E2E8F0] shadow-2xs">
                    <select
                      value={selectedCity}
                      onChange={(e) => setSelectedCity(e.target.value)}
                      className="w-full pl-9 pr-8 py-2.5 font-medium text-[#0F172A] bg-transparent rounded-[8px] appearance-none focus:outline-hidden focus:ring-2 focus:ring-[#1B5888]/20 focus:border-[#1B5888] cursor-pointer truncate"
                    >
                      <option value="all">{t("propsFilterAllCities")}</option>
                      {cityList.map((c) => (
                        <option key={c} value={c}>
                          {c}
                        </option>
                      ))}
                    </select>
                    <MapPin className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none" />
                    <ChevronDown className="w-4 h-4 text-slate-400 absolute right-3 top-1/2 -translate-y-1/2 pointer-events-none" />
                  </div>

                  {/* Landlord Filter */}
                  <div className="relative bg-white rounded-[8px] border border-[#E2E8F0] shadow-2xs">
                    <select
                      value={selectedLandlord}
                      onChange={(e) => setSelectedLandlord(e.target.value)}
                      className="w-full pl-9 pr-8 py-2.5 font-medium text-[#0F172A] bg-transparent rounded-[8px] appearance-none focus:outline-hidden focus:ring-2 focus:ring-[#1B5888]/20 focus:border-[#1B5888] cursor-pointer truncate"
                    >
                      <option value="all">{t("propsFilterAllLandlords")}</option>
                      {landlordList.map((l) => (
                        <option key={l} value={l}>
                          {l}
                        </option>
                      ))}
                    </select>
                    <UserCheck className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none" />
                    <ChevronDown className="w-4 h-4 text-slate-400 absolute right-3 top-1/2 -translate-y-1/2 pointer-events-none" />
                  </div>

                  {/* Group By Select */}
                  <div className="relative bg-white rounded-[8px] border border-[#E2E8F0] shadow-2xs">
                    <select
                      value={groupBy}
                      onChange={(e) => setGroupBy(e.target.value as any)}
                      className="w-full pl-9 pr-8 py-2.5 font-medium text-[#0F172A] bg-transparent rounded-[8px] appearance-none focus:outline-hidden focus:ring-2 focus:ring-[#1B5888]/20 focus:border-[#1B5888] cursor-pointer truncate"
                    >
                      <option value="none">{t("groupNone")}</option>
                      <option value="landlord">{t("groupByLandlord")}</option>
                      <option value="city">{t("groupByCity")}</option>
                      <option value="status">{t("groupByStatus")}</option>
                      <option value="debt_consent">{t("groupByDebtConsent")}</option>
                    </select>
                    <Layers className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none" />
                    <ChevronDown className="w-4 h-4 text-slate-400 absolute right-3 top-1/2 -translate-y-1/2 pointer-events-none" />
                  </div>

                  {/* Sort By Select */}
                  <div className="relative bg-white rounded-[8px] border border-[#E2E8F0] shadow-2xs">
                    <select
                      value={sortBy}
                      onChange={(e) => setSortBy(e.target.value as any)}
                      className="w-full pl-9 pr-8 py-2.5 font-medium text-[#0F172A] bg-transparent rounded-[8px] appearance-none focus:outline-hidden focus:ring-2 focus:ring-[#1B5888]/20 focus:border-[#1B5888] cursor-pointer truncate"
                    >
                      <option value="newest">{t("sortByNewest")}</option>
                      <option value="oldest">{t("sortByOldest")}</option>
                      <option value="debt">{t("sortByDebt")}</option>
                      <option value="rent_desc">{t("sortByRentDesc")}</option>
                      <option value="rent_asc">{t("sortByRentAsc")}</option>
                      <option value="name_asc">{t("sortByNameAsc")}</option>
                      <option value="city_asc">{t("sortByCityAsc")}</option>
                      <option value="landlord_asc">{t("sortByLandlordAsc")}</option>
                    </select>
                    <ArrowDownUp className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none" />
                    <ChevronDown className="w-4 h-4 text-slate-400 absolute right-3 top-1/2 -translate-y-1/2 pointer-events-none" />
                  </div>
                </div>

                {/* Row 3: Active Filter Badges & Clear Filters Button */}
                {hasActiveDetailedFilters && (
                  <div className="pt-2 border-t border-slate-200/60 flex items-center justify-between flex-wrap gap-2">
                    <div className="flex items-center gap-1.5 flex-wrap">
                      <span className="text-slate-400 font-semibold">{t("financeActiveFilterPrefix")}:</span>

                      {searchQuery.trim() && (
                        <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[11px] font-semibold bg-[#E5EEF6] text-[#1B5888] border border-[#1B5888]/20">
                          "{searchQuery}"
                          <X className="w-3 h-3 cursor-pointer hover:text-[#15466d]" onClick={() => setSearchQuery("")} />
                        </span>
                      )}

                      {selectedCity !== "all" && (
                        <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[11px] font-semibold bg-[#E5EEF6] text-[#1B5888] border border-[#1B5888]/20">
                          {selectedCity}
                          <X className="w-3 h-3 cursor-pointer hover:text-[#15466d]" onClick={() => setSelectedCity("all")} />
                        </span>
                      )}

                      {selectedLandlord !== "all" && (
                        <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[11px] font-semibold bg-[#E5EEF6] text-[#1B5888] border border-[#1B5888]/20">
                          {selectedLandlord}
                          <X className="w-3 h-3 cursor-pointer hover:text-[#15466d]" onClick={() => setSelectedLandlord("all")} />
                        </span>
                      )}

                      {filterBy !== "all" && (
                        <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[11px] font-semibold bg-purple-50 text-purple-700 border border-purple-200">
                          {filterBy === "has_debt" ? t("propsFilterHasDebt") : filterBy === "occupied" ? t("propsFilterOccupied") : filterBy === "vacant" ? t("propsFilterVacant") : filterBy === "expired" ? t("cockpitExpiredContracts") : t("propsFilterExpiring")}
                          <X className="w-3 h-3 cursor-pointer hover:text-purple-900" onClick={() => { setFilterBy("all"); setPropOccupancyFilter("all"); }} />
                        </span>
                      )}
                    </div>

                    <button
                      type="button"
                      onClick={handleResetFilters}
                      className="inline-flex items-center gap-1.5 text-xs font-bold text-rose-600 hover:text-rose-700 cursor-pointer transition-colors"
                    >
                      <RotateCcw className="w-3.5 h-3.5" />
                      <span>{t("financeFilterReset")}</span>
                    </button>
                  </div>
                )}
              </div>
            )}
          </div>

          {/* ── 2. Middle Tier: Summary Filter Cards (KPI Cards with Click-to-Filter) ── */}
          <div className="grid grid-cols-2 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-3">
            {/* Card 1: All Properties */}
            <div
              onClick={() => { setFilterBy("all"); setPropOccupancyFilter("all"); }}
              className={`p-3.5 rounded-[10px] border transition-all cursor-pointer ${filterBy === "all"
                ? "bg-slate-100/90 border-[#1B5888] ring-2 ring-[#1B5888]/30 shadow-xs"
                : "bg-white border-[#E2E8F0] hover:bg-slate-50"
                }`}
            >
              <div className="flex items-center justify-between">
                <span className="text-xs font-semibold text-slate-500 truncate">
                  {t("propsFilterAll")}
                </span>
                <div className="w-6 h-6 rounded-full bg-slate-100 text-[#1B5888] flex items-center justify-center">
                  <Building2 className="w-3.5 h-3.5 text-[#1B5888] shrink-0" />
                </div>
              </div>
              <div className="flex items-baseline gap-2 mt-1.5">
                <div className="text-xl font-semibold text-[#0F172A] font-mono tabular-nums">
                  {totalCount}
                </div>
                <span className="text-[11px] text-slate-400 font-medium truncate">
                  €{totalPortfolioRent.toLocaleString()}
                </span>
              </div>
            </div>

            {/* Card 2: Occupied */}
            <div
              onClick={() => setFilterBy("occupied")}
              className={`p-3.5 rounded-[10px] border transition-all cursor-pointer ${filterBy === "occupied"
                ? "bg-emerald-50/80 border-emerald-300 ring-2 ring-emerald-400/40 shadow-xs"
                : "bg-white border-[#E2E8F0] hover:bg-slate-50"
                }`}
            >
              <div className="flex items-center justify-between">
                <span className="text-xs font-semibold text-slate-500 truncate">
                  {t("propsFilterOccupied")}
                </span>
                <div className="w-6 h-6 rounded-full bg-emerald-50 text-emerald-600 flex items-center justify-center">
                  <Home className="w-3.5 h-3.5 text-emerald-600 shrink-0" />
                </div>
              </div>
              <div className="flex items-baseline gap-2 mt-1.5">
                <div className="text-xl font-semibold text-[#0F172A] font-mono tabular-nums">
                  {occupiedCount}
                </div>
                <span className="text-[11px] text-emerald-600 font-medium truncate">
                  {t("propsFilterActiveContracts")}
                </span>
              </div>
            </div>

            {/* Card 3: Vacant */}
            <div
              onClick={() => setFilterBy("vacant")}
              className={`p-3.5 rounded-[10px] border transition-all cursor-pointer ${filterBy === "vacant"
                ? "bg-sky-50/80 border-sky-300 ring-2 ring-sky-400/40 shadow-xs"
                : "bg-white border-[#E2E8F0] hover:bg-slate-50"
                }`}
            >
              <div className="flex items-center justify-between">
                <span className="text-xs font-semibold text-slate-500 truncate">
                  {t("propsFilterVacant")}
                </span>
                <div className="w-6 h-6 rounded-full bg-sky-50 text-sky-600 flex items-center justify-center">
                  <Key className="w-3.5 h-3.5 text-sky-600 shrink-0" />
                </div>
              </div>
              <div className="flex items-baseline gap-2 mt-1.5">
                <div className="text-xl font-semibold text-[#0F172A] font-mono tabular-nums">
                  {vacantCount}
                </div>
                <span className="text-[11px] text-sky-600 font-medium truncate">
                  {t("propsFilterReadyToRent")}
                </span>
              </div>
            </div>

            {/* Card 4: Has Debt / Overdue */}
            <div
              onClick={() => setFilterBy("has_debt")}
              className={`p-3.5 rounded-[10px] border transition-all cursor-pointer ${filterBy === "has_debt"
                ? "bg-rose-50/80 border-rose-300 ring-2 ring-rose-400/40 shadow-xs"
                : "bg-white border-[#E2E8F0] hover:bg-slate-50"
                }`}
            >
              <div className="flex items-center justify-between">
                <span className="text-xs font-semibold text-slate-500 truncate">
                  {t("propsFilterHasDebt")}
                </span>
                <div className="w-6 h-6 rounded-full bg-rose-50 text-rose-600 flex items-center justify-center">
                  <AlertTriangle className="w-3.5 h-3.5 text-rose-600 shrink-0" />
                </div>
              </div>
              <div className="flex items-baseline gap-2 mt-1.5">
                <div className="text-xl font-semibold text-[#0F172A] font-mono tabular-nums">
                  {debtCount}
                </div>
                {debtCount > 0 ? (
                  <span className="text-[11px] text-rose-600 font-semibold truncate">
                    €{totalDebtAmount.toLocaleString()}
                  </span>
                ) : (
                  <span className="text-[11px] text-emerald-600 font-medium">0 RSD</span>
                )}
              </div>
            </div>

            {/* Card 5: Expiring Soon */}
            <div
              onClick={() => setFilterBy("expiring")}
              className={`p-3.5 rounded-[10px] border transition-all cursor-pointer ${filterBy === "expiring"
                ? "bg-amber-50/80 border-amber-300 ring-2 ring-amber-400/40 shadow-xs"
                : "bg-white border-[#E2E8F0] hover:bg-slate-50"
                }`}
            >
              <div className="flex items-center justify-between">
                <span className="text-xs font-semibold text-slate-500 truncate">
                  {t("propsFilterExpiring")}
                </span>
                <div className="w-6 h-6 rounded-full bg-amber-50 text-amber-600 flex items-center justify-center">
                  <Clock className="w-3.5 h-3.5 text-amber-600 shrink-0" />
                </div>
              </div>
              <div className="flex items-baseline gap-2 mt-1.5">
                <div className="text-xl font-semibold text-[#0F172A] font-mono tabular-nums">
                  {expiringCount}
                </div>
                <span className="text-[11px] text-amber-600 font-medium truncate">
                  {t("propsFilterEndingDays")}
                </span>
              </div>
            </div>
          </div>

          {/* 3. Subheader Toolbar */}
          <div className="flex items-center justify-between pt-1">
            <div className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-slate-100/90 border border-slate-200/60 text-slate-700 text-xs font-bold">
              <Building2 className="w-3.5 h-3.5 text-slate-500" />
              <span>{tSafe("propertiesCount", { count: filteredAndSortedProperties.length })}</span>
            </div>

            <div className="flex items-center gap-2">
              <div className="flex items-center bg-white border border-[#E2E8F0] rounded-[10px] p-0.5 shadow-2xs">
                <button
                  type="button"
                  onClick={() => setViewMode("table")}
                  title={t("viewModeTable")}
                  className={`p-1.5 rounded-lg transition-colors cursor-pointer ${viewMode === "table" ? "bg-slate-100 text-[#0F172A]" : "text-slate-400 hover:text-slate-600"
                    }`}
                >
                  <TableProperties className="w-4 h-4" />
                </button>
                <button
                  type="button"
                  onClick={() => setViewMode("grid")}
                  title={t("viewModeGrid")}
                  className={`p-1.5 rounded-lg transition-colors cursor-pointer ${viewMode === "grid" ? "bg-slate-100 text-[#0F172A]" : "text-slate-400 hover:text-slate-600"
                    }`}
                >
                  <LayoutGrid className="w-4 h-4" />
                </button>
              </div>

              <button
                type="button"
                onClick={() => {
                  if (isDemoMode && !isDemoVerified) {
                    onRequestVerification?.();
                    return;
                  }
                  setIsAddPropertyModalOpen(true);
                }}
                className="inline-flex items-center gap-1.5 px-4 py-2 rounded-[10px] text-xs sm:text-sm font-semibold bg-[#1B5888] hover:bg-[#15466d] text-white transition-colors shadow-2xs cursor-pointer"
              >
                <Plus className="w-4 h-4" />
                <span>{t("agency_props_btn_add")}</span>
              </button>
            </div>
          </div>

          {/* 4. Properties Display (Table or Grid) */}
          {loadingProperties ? (
            <div className="p-12 text-center text-xs text-slate-500 flex items-center justify-center gap-2">
              <RefreshCw className="w-4 h-4 animate-spin text-[#1B5888]" />
              <span>{t("agency_panel_loading")}</span>
            </div>
          ) : filteredAndSortedProperties.length === 0 ? (
            <div className="bg-white rounded-[10px] border border-[#E5E3DF] p-12 text-center shadow-xs space-y-3">
              <div className="w-12 h-12 rounded-[10px] bg-slate-100 text-[#666666] flex items-center justify-center mx-auto">
                <Home className="w-6 h-6" />
              </div>
              <h3 className="text-base font-bold text-[#1A1A1A]">
                {t("agency_props_empty_title")}
              </h3>
              <p className="text-xs text-[#666666] max-w-md mx-auto leading-relaxed">
                {t("agency_props_empty_desc")}
              </p>
            </div>
          ) : viewMode === "table" ? (
            /* Desktop & Tablet Table View */
            <div className="bg-white rounded-[10px] border border-[#E2E8F0] shadow-xs overflow-x-auto min-h-[360px]">
              <table className="w-full text-left border-collapse min-w-[760px]">
                <thead>
                  <tr className="border-b border-[#E2E8F0] bg-[#F8FAFC] text-[11px] font-bold text-slate-500 uppercase tracking-wider">
                    <th className="py-3.5 px-4">{t("tabPortfolio")}</th>
                    <th className="py-3.5 px-4">{t("agency_props_col_landlord")}</th>
                    <th className="py-3.5 px-4">{t("roleTenant")}</th>
                    <th className="py-3.5 px-4">{t("contract")}</th>
                    <th className="py-3.5 px-4">{t("statusLabel")}</th>
                    <th className="py-3.5 px-3 text-right sticky right-0 bg-[#F8FAFC] z-20 shadow-[-6px_0_10px_rgba(0,0,0,0.03)] border-l border-[#E2E8F0]/80 w-14 min-w-[56px]"></th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 text-xs text-slate-700">
                  {groupedProperties.map((group, groupIdx) => (
                    <React.Fragment key={group.groupName || groupIdx}>
                      {group.groupName && (
                        <tr className="bg-slate-50/80 border-y border-[#E2E8F0]">
                          <td colSpan={6} className="py-2.5 px-4 font-bold text-xs text-slate-700">
                            <div className="sticky left-4 inline-flex items-center gap-2">
                              <span>{group.groupName}</span>
                              <span className="text-[11px] font-semibold text-slate-400">({group.items.length})</span>
                            </div>
                          </td>
                        </tr>
                      )}
                      {group.items.map((p, pIdx) => {
                        const hasDebt = debtPropertyIds.has(p.id);
                        const contract = propertyContract[p.id];
                        const isOccupied = p.is_occupied;
                        const tenantName = p.active_tenant_name || (contract?.tenant_name);
                        const rentVal = p.default_monthly_rent || contract?.monthly_rent;
                        const curr = p.currency || contract?.currency || "EUR";
                        const contractEndDate = contract?.end_date || p.contract_end_date || "Unlimited";

                        return (
                          <tr
                            key={p.id}
                            onClick={() => inspectProperty(p)}
                            className="hover:bg-slate-50/80 transition-colors cursor-pointer group"
                          >
                            <td className="py-3.5 px-4">
                              <div className="flex items-center gap-3">
                                <div
                                  className={`w-10 h-10 rounded-xl flex items-center justify-center shrink-0 border ${hasDebt
                                    ? "bg-[#FFF1F2] border-[#FFE4E6] text-[#E11D48]"
                                    : isOccupied
                                      ? "bg-[#E5EEF6] border-[#1B5888]/20 text-[#1B5888]"
                                      : "bg-[#F8FAFC] border-[#E2E8F0] text-[#64748B]"
                                    }`}
                                >
                                  {hasDebt ? (
                                    <AlertTriangle className="w-5 h-5 text-[#E11D48]" />
                                  ) : isOccupied ? (
                                    <Building className="w-5 h-5 text-[#1B5888]" />
                                  ) : (
                                    <Home className="w-5 h-5 text-[#64748B]" />
                                  )}
                                </div>
                                <div className="min-w-0">
                                  <div className="flex items-center gap-2 flex-wrap">
                                    <span className="font-bold text-sm text-[#0F172A] group-hover:text-[#1B5888] transition-colors">
                                      {p.title}
                                    </span>
                                    {p.city && (
                                      <span className="inline-flex items-center px-2 py-0.5 rounded-md text-[11px] font-semibold bg-[#E5EEF6] text-[#1B5888]">
                                        {p.city}
                                      </span>
                                    )}
                                  </div>
                                  <p className="text-xs text-slate-500 truncate max-w-[240px] sm:max-w-[320px] lg:max-w-[360px] mt-0.5">
                                    {p.address}
                                  </p>
                                </div>
                              </div>
                            </td>

                            <td className="py-3.5 px-4">
                              <div className="flex items-center gap-1.5 text-xs font-semibold text-[#1E293B]">
                                <UserCheck className="w-3.5 h-3.5 text-slate-400 shrink-0" />
                                <span>{p.landlord_name || "-"}</span>
                              </div>
                            </td>

                            <td className="py-3.5 px-4">
                              {isOccupied && tenantName ? (
                                <div className="flex items-center gap-1.5 text-xs font-semibold text-[#1E293B]">
                                  <UserCheck className="w-3.5 h-3.5 text-slate-400 shrink-0" />
                                  <span>{tenantName} <span className="text-slate-400 font-normal">(direct)</span></span>
                                </div>
                              ) : (
                                <span className="inline-flex items-center px-2.5 py-1 rounded-md text-xs font-semibold bg-slate-100 text-slate-600">
                                  {t("vacantLabel")}
                                </span>
                              )}
                            </td>

                            <td className="py-3.5 px-4">
                              <div className="font-bold text-xs text-[#0F172A]">
                                {rentVal ? `${rentVal} ${curr}` : "-"}
                              </div>
                              <div className="text-[11px] text-slate-500 mt-0.5">
                                {contractEndDate}
                              </div>
                            </td>

                            <td className="py-3.5 px-4">
                              {hasDebt ? (
                                <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-md text-xs font-bold bg-[#FFF1F2] text-[#E11D48] border border-[#FECDD3]">
                                  <AlertTriangle className="w-3.5 h-3.5 text-[#E11D48]" />
                                  <span>{t("statusOverdue")}</span>
                                </span>
                              ) : isOccupied ? (
                                <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-md text-xs font-bold bg-[#ECFDF5] text-[#059669] border border-[#A7F3D0]">
                                  <Check className="w-3.5 h-3.5 text-[#059669]" />
                                  <span>{t("statusClean")}</span>
                                </span>
                              ) : (
                                <span className="inline-flex items-center px-2.5 py-1 rounded-md text-xs font-bold bg-amber-50 text-amber-700 border border-amber-200">
                                  {t("vacantLabel")}
                                </span>
                              )}
                            </td>

                            <td
                              className={`py-3.5 px-3 text-right sticky right-0 bg-white group-hover:bg-[#F8FAFC] border-l border-slate-100 shadow-[-6px_0_10px_rgba(0,0,0,0.04)] transition-colors ${actionMenuPropId === p.id ? "z-30" : "z-10"
                                }`}
                              onClick={(e) => e.stopPropagation()}
                            >
                              <div className="relative inline-flex items-center justify-end gap-1 text-left">
                                {onViewPropertyTasks && (() => {
                                  const propTaskCount = tasks.filter(
                                    (tk) => tk.property_id === p.id && tk.status !== "done" && tk.status !== "cancelled"
                                  ).length;
                                  return (
                                    <button
                                      type="button"
                                      onClick={(e) => {
                                        e.stopPropagation();
                                        onViewPropertyTasks(p.id);
                                      }}
                                      title={t("agency_tasks_view_property_tasks")}
                                      aria-label={t("agency_tasks_view_property_tasks")}
                                      className={`inline-flex items-center gap-1 px-2 py-1 rounded-lg text-[11px] font-bold transition-colors cursor-pointer ${propTaskCount > 0
                                          ? "bg-[#E5EEF6] text-[#1B5888] hover:bg-[#1B5888] hover:text-white"
                                          : "text-slate-400 hover:text-[#1B5888] hover:bg-slate-100"
                                        }`}
                                    >
                                      <CheckSquare className="w-3.5 h-3.5 shrink-0" />
                                      {propTaskCount > 0 && <span>{propTaskCount}</span>}
                                    </button>
                                  );
                                })()}
                                <button
                                  type="button"
                                  onClick={(e) => {
                                    e.stopPropagation();
                                    setActionMenuPropId(actionMenuPropId === p.id ? null : p.id);
                                  }}
                                  className="p-1.5 rounded-lg text-slate-400 hover:text-slate-700 hover:bg-slate-100 transition-colors cursor-pointer"
                                >
                                  <MoreHorizontal className="w-5 h-5" />
                                </button>

                                {actionMenuPropId === p.id && (
                                  <>
                                    <div
                                      className="fixed inset-0 z-40"
                                      onClick={() => setActionMenuPropId(null)}
                                    />
                                    <div
                                      className={`absolute right-0 w-64 bg-white rounded-2xl shadow-2xl border border-slate-200/90 py-2 z-50 text-left ${pIdx >= group.items.length - 2 && group.items.length > 2
                                        ? "bottom-full mb-1"
                                        : "top-full mt-1"
                                        }`}
                                    >
                                      {/* 1. Invite Tenant / Add Contract */}
                                      <button
                                        type="button"
                                        onClick={() => {
                                          setActionMenuPropId(null);
                                          openNewContractModal(p);
                                        }}
                                        className="w-full px-4 py-2.5 text-xs font-medium text-slate-700 hover:bg-slate-50 hover:text-slate-900 flex items-center gap-3 transition-colors cursor-pointer"
                                      >
                                        <UserCheck className="w-4 h-4 text-slate-500 shrink-0" />
                                        <span className="font-medium">{t("inviteTenantOrAddContract")}</span>
                                      </button>

                                      {/* 2. Landlord Ownership Invitation */}
                                      <button
                                        type="button"
                                        onClick={() => {
                                          setActionMenuPropId(null);
                                          openOwnershipModalWithCheck(p);
                                        }}
                                        className="w-full px-4 py-2.5 text-xs font-medium text-slate-700 hover:bg-slate-50 hover:text-slate-900 flex items-center gap-3 transition-colors cursor-pointer"
                                      >
                                        <Mail className="w-4 h-4 text-slate-500 shrink-0" />
                                        <span className="font-medium">{t("landlordOwnershipInviteTitle")}</span>
                                      </button>

                                      {/* 3. Update Landlord Info (formerly Change Landlord) */}
                                      <button
                                        type="button"
                                        onClick={() => {
                                          setActionMenuPropId(null);
                                          setEditingOwnersProperty(p);
                                        }}
                                        className="w-full px-4 py-2.5 text-xs font-medium text-slate-700 hover:bg-slate-50 hover:text-slate-900 flex items-center gap-3 transition-colors cursor-pointer"
                                      >
                                        <UserPlus className="w-4 h-4 text-slate-500 shrink-0" />
                                        <span className="font-medium">{t("updateLandlordInfo")}</span>
                                      </button>

                                      {/* 4. Property settings */}
                                      <button
                                        type="button"
                                        onClick={() => {
                                          setActionMenuPropId(null);
                                          inspectProperty(p, "overview");
                                        }}
                                        className="w-full px-4 py-2.5 text-xs font-medium text-slate-700 hover:bg-slate-50 hover:text-slate-900 flex items-center gap-3 transition-colors cursor-pointer"
                                      >
                                        <Settings className="w-4 h-4 text-slate-500 shrink-0" />
                                        <span className="font-medium">{t("propertySettingsLabel")}</span>
                                      </button>

                                      {/* 5. Re-List / Update in Portfolio */}
                                      <button
                                        type="button"
                                        onClick={() => {
                                          setActionMenuPropId(null);
                                          openRelistModal(p);
                                        }}
                                        className="w-full px-4 py-2.5 text-xs font-medium text-[#1B5888] hover:bg-blue-50/60 flex items-center gap-3 transition-colors cursor-pointer border-t border-slate-100"
                                      >
                                        <PlusCircle className="w-4 h-4 text-[#1B5888] shrink-0" />
                                        <span className="font-semibold">{t("agency_bridge_btn_relist_or_update")}</span>
                                      </button>
                                    </div>
                                  </>
                                )}
                              </div>
                            </td>
                          </tr>
                        );
                      })}
                    </React.Fragment>
                  ))}
                </tbody>
              </table>
            </div>
          ) : (
            /* Grid View */
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {filteredAndSortedProperties.map((p) => {
                const hasDebt = debtPropertyIds.has(p.id);
                const contract = propertyContract[p.id];
                const isOccupied = p.is_occupied;
                const tenantName = p.active_tenant_name || (contract?.tenant_name);
                const rentVal = p.default_monthly_rent || contract?.monthly_rent;
                const curr = p.currency || contract?.currency || "EUR";

                return (
                  <div
                    key={p.id}
                    onClick={() => inspectProperty(p)}
                    className="bg-white rounded-2xl border border-[#E2E8F0] p-4 shadow-xs hover:shadow-md transition-all cursor-pointer space-y-3 group"
                  >
                    <div className="flex items-start justify-between gap-2">
                      <div className="flex items-center gap-2.5 min-w-0">
                        <div
                          className={`w-10 h-10 rounded-xl flex items-center justify-center shrink-0 border ${hasDebt
                            ? "bg-[#FFF1F2] border-[#FFE4E6] text-[#E11D48]"
                            : isOccupied
                              ? "bg-[#E5EEF6] border-[#1B5888]/20 text-[#1B5888]"
                              : "bg-[#F8FAFC] border-[#E2E8F0] text-[#64748B]"
                            }`}
                        >
                          {hasDebt ? (
                            <AlertTriangle className="w-5 h-5 text-[#E11D48]" />
                          ) : isOccupied ? (
                            <Building className="w-5 h-5 text-[#1B5888]" />
                          ) : (
                            <Home className="w-5 h-5 text-[#64748B]" />
                          )}
                        </div>
                        <div className="min-w-0">
                          <h4 className="font-bold text-sm text-[#0F172A] group-hover:text-[#1B5888] transition-colors truncate">
                            {p.title}
                          </h4>
                          <p className="text-xs text-slate-500 truncate mt-0.5">
                            {p.address}
                          </p>
                        </div>
                      </div>

                      {p.city && (
                        <span className="inline-flex items-center px-2 py-0.5 rounded-md text-[11px] font-semibold bg-[#E5EEF6] text-[#1B5888] shrink-0">
                          {p.city}
                        </span>
                      )}
                    </div>

                    <div className="bg-slate-50 rounded-xl p-3 space-y-2 text-xs">
                      <div className="flex items-center justify-between">
                        <span className="text-slate-500">{t("agency_props_col_landlord")}</span>
                        <span className="font-semibold text-slate-800 truncate max-w-[150px]">{p.landlord_name || "-"}</span>
                      </div>
                      <div className="flex items-center justify-between">
                        <span className="text-slate-500">{t("roleTenant")}</span>
                        {isOccupied && tenantName ? (
                          <span className="font-semibold text-slate-800 truncate max-w-[150px]">{tenantName}</span>
                        ) : (
                          <span className="text-slate-400">{t("vacantLabel")}</span>
                        )}
                      </div>
                      <div className="flex items-center justify-between pt-1 border-t border-slate-200/60">
                        <span className="text-slate-500">{t("contract")}</span>
                        <span className="font-bold text-[#0F172A]">
                          {rentVal ? `${rentVal} ${curr}` : "-"}
                        </span>
                      </div>
                    </div>

                    <div className="flex items-center justify-between pt-1">
                      {hasDebt ? (
                        <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-md text-xs font-bold bg-[#FFF1F2] text-[#E11D48] border border-[#FECDD3]">
                          <AlertTriangle className="w-3.5 h-3.5 text-[#E11D48]" />
                          <span>{t("statusOverdue")}</span>
                        </span>
                      ) : isOccupied ? (
                        <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-md text-xs font-bold bg-[#ECFDF5] text-[#059669] border border-[#A7F3D0]">
                          <Check className="w-3.5 h-3.5 text-[#059669]" />
                          <span>{t("statusClean")}</span>
                        </span>
                      ) : (
                        <span className="inline-flex items-center px-2.5 py-1 rounded-md text-xs font-bold bg-amber-50 text-amber-700 border border-amber-200">
                          {t("vacantLabel")}
                        </span>
                      )}

                      <div className="flex items-center gap-1.5">
                        <button
                          type="button"
                          onClick={(e) => {
                            e.stopPropagation();
                            inspectProperty(p);
                          }}
                          className="inline-flex items-center gap-1 px-3 py-1.5 rounded-lg text-xs font-bold bg-blue-50 text-blue-700 hover:bg-blue-100 transition-colors cursor-pointer"
                        >
                          <Eye className="w-3.5 h-3.5" />
                          <span>{t("agency_prop_drawer_btn_view")}</span>
                        </button>

                        <div className="relative inline-block text-left">
                          <button
                            type="button"
                            onClick={(e) => {
                              e.stopPropagation();
                              setCardActionMenuPropId(cardActionMenuPropId === p.id ? null : p.id);
                            }}
                            className="p-1.5 rounded-lg text-slate-400 hover:text-slate-700 hover:bg-slate-100 transition-colors cursor-pointer"
                          >
                            <MoreHorizontal className="w-5 h-5" />
                          </button>

                          {cardActionMenuPropId === p.id && (
                            <>
                              <div
                                className="fixed inset-0 z-20"
                                onClick={(e) => {
                                  e.stopPropagation();
                                  setCardActionMenuPropId(null);
                                }}
                              />
                              <div className="absolute right-0 bottom-full mb-1 w-64 bg-white rounded-2xl shadow-xl border border-slate-200/80 py-2 z-30 text-left">
                                {/* 1. Invite Tenant / Add Contract */}
                                <button
                                  type="button"
                                  onClick={(e) => {
                                    e.stopPropagation();
                                    setCardActionMenuPropId(null);
                                    openNewContractModal(p);
                                  }}
                                  className="w-full px-4 py-2.5 text-xs font-medium text-slate-700 hover:bg-slate-50 hover:text-slate-900 flex items-center gap-3 transition-colors cursor-pointer"
                                >
                                  <UserCheck className="w-4 h-4 text-slate-500 shrink-0" />
                                  <span className="font-medium">{t("inviteTenantOrAddContract")}</span>
                                </button>

                                {/* 2. Landlord Ownership Invitation */}
                                <button
                                  type="button"
                                  onClick={(e) => {
                                    e.stopPropagation();
                                    setCardActionMenuPropId(null);
                                    openOwnershipModalWithCheck(p);
                                  }}
                                  className="w-full px-4 py-2.5 text-xs font-medium text-slate-700 hover:bg-slate-50 hover:text-slate-900 flex items-center gap-3 transition-colors cursor-pointer"
                                >
                                  <Mail className="w-4 h-4 text-slate-500 shrink-0" />
                                  <span className="font-medium">{t("landlordOwnershipInviteTitle")}</span>
                                </button>

                                {/* 3. Update Landlord Info (formerly Change Landlord) */}
                                <button
                                  type="button"
                                  onClick={(e) => {
                                    e.stopPropagation();
                                    setCardActionMenuPropId(null);
                                    setEditingOwnersProperty(p);
                                  }}
                                  className="w-full px-4 py-2.5 text-xs font-medium text-slate-700 hover:bg-slate-50 hover:text-slate-900 flex items-center gap-3 transition-colors cursor-pointer"
                                >
                                  <UserPlus className="w-4 h-4 text-slate-500 shrink-0" />
                                  <span className="font-medium">{t("updateLandlordInfo")}</span>
                                </button>

                                {/* 4. Property settings */}
                                <button
                                  type="button"
                                  onClick={(e) => {
                                    e.stopPropagation();
                                    setCardActionMenuPropId(null);
                                    inspectProperty(p, "overview");
                                  }}
                                  className="w-full px-4 py-2.5 text-xs font-medium text-slate-700 hover:bg-slate-50 hover:text-slate-900 flex items-center gap-3 transition-colors cursor-pointer"
                                >
                                  <Settings className="w-4 h-4 text-slate-500 shrink-0" />
                                  <span className="font-medium">{t("propertySettingsLabel")}</span>
                                </button>

                                {/* 5. Re-List / Update in Portfolio */}
                                <button
                                  type="button"
                                  onClick={(e) => {
                                    e.stopPropagation();
                                    setCardActionMenuPropId(null);
                                    openRelistModal(p);
                                  }}
                                  className="w-full px-4 py-2.5 text-xs font-medium text-[#1B5888] hover:bg-blue-50/60 flex items-center gap-3 transition-colors cursor-pointer border-t border-slate-100"
                                >
                                  <PlusCircle className="w-4 h-4 text-[#1B5888] shrink-0" />
                                  <span className="font-semibold">{t("agency_bridge_btn_relist_or_update")}</span>
                                </button>
                              </div>
                            </>
                          )}
                        </div>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          )}

          {/* Add Property Modal */}
          {isAddPropertyModalOpen && (
            <div className="fixed inset-0 bg-black/50 backdrop-blur-xs flex items-center justify-center p-4 z-50">
              <div className="bg-white rounded-2xl max-w-lg w-full max-h-[90vh] overflow-y-auto p-6 shadow-2xl space-y-4">
                <div className="flex items-start justify-between">
                  <div>
                    <h3 className="text-base font-bold text-[#0F172A]">
                      {t("agency_props_add_modal_title")}
                    </h3>
                    <p className="text-xs text-slate-500 mt-0.5">
                      {t("agency_props_add_modal_desc")}
                    </p>
                  </div>
                  <button
                    type="button"
                    onClick={() => setIsAddPropertyModalOpen(false)}
                    className="p-1 rounded-lg text-slate-400 hover:text-slate-600 transition-colors cursor-pointer"
                  >
                    <X className="w-5 h-5" />
                  </button>
                </div>

                <form onSubmit={handleAddPropertySubmit} className="space-y-3.5 text-xs">
                  <div>
                    <label className="block font-semibold text-slate-700 mb-1">
                      {t("agency_props_field_title")} *
                    </label>
                    <input
                      type="text"
                      required
                      value={newPropTitle}
                      onChange={(e) => setNewPropTitle(e.target.value)}
                      placeholder="BW Terraces 207"
                      className="w-full px-3 py-2 rounded-xl border border-[#E2E8F0] focus:outline-hidden focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500"
                    />
                  </div>

                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                    <div>
                      <label className="block font-semibold text-slate-700 mb-1">
                        {t("agency_props_field_address")} *
                      </label>
                      <input
                        type="text"
                        required
                        value={newPropAddress}
                        onChange={(e) => setNewPropAddress(e.target.value)}
                        placeholder="Hercegovačka 16"
                        className="w-full px-3 py-2 rounded-xl border border-[#E2E8F0] focus:outline-hidden focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500"
                      />
                    </div>
                    <div>
                      <label className="block font-semibold text-slate-700 mb-1">
                        {t("agency_props_field_city")}
                      </label>
                      <select
                        value={newPropCity || "Beograd"}
                        onChange={(e) => setNewPropCity(e.target.value)}
                        className="w-full px-3 py-2 rounded-xl border border-[#E2E8F0] bg-white focus:outline-hidden focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 cursor-pointer"
                      >
                        {newPropCity && !SERBIAN_CITIES.includes(newPropCity as any) && (
                          <option value={newPropCity}>{newPropCity}</option>
                        )}
                        {SERBIAN_CITIES.map((c) => (
                          <option key={c} value={c}>
                            {c}
                          </option>
                        ))}
                      </select>
                    </div>
                  </div>

                  <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
                    <div className="col-span-2 sm:col-span-2">
                      <label className="block font-semibold text-slate-700 mb-1">
                        {t("agency_props_field_rent")}
                      </label>
                      <input
                        type="number"
                        value={newPropRent}
                        onChange={(e) => setNewPropRent(e.target.value)}
                        placeholder="1500"
                        className="w-full px-3 py-2 rounded-xl border border-[#E2E8F0] focus:outline-hidden focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500"
                      />
                    </div>
                    <div className="col-span-2 sm:col-span-2">
                      <label className="block font-semibold text-slate-700 mb-1">
                        {t("agency_props_field_currency")}
                      </label>
                      <select
                        value={newPropCurrency}
                        onChange={(e) => setNewPropCurrency(e.target.value)}
                        className="w-full px-3 py-2 rounded-xl border border-[#E2E8F0] bg-white focus:outline-hidden focus:ring-2 focus:ring-blue-500/20"
                      >
                        <option value="EUR">EUR</option>
                        <option value="RSD">RSD</option>
                      </select>
                    </div>
                  </div>

                  <div className="grid grid-cols-3 gap-3">
                    <div>
                      <label className="block font-semibold text-slate-700 mb-1">
                        {t("agency_props_field_rooms")}
                      </label>
                      <input
                        type="text"
                        value={newPropRooms}
                        onChange={(e) => setNewPropRooms(e.target.value)}
                        placeholder="2.0"
                        className="w-full px-3 py-2 rounded-xl border border-[#E2E8F0] focus:outline-hidden focus:ring-2 focus:ring-blue-500/20"
                      />
                    </div>
                    <div>
                      <label className="block font-semibold text-slate-700 mb-1">
                        {t("agency_props_field_area")}
                      </label>
                      <input
                        type="number"
                        value={newPropArea}
                        onChange={(e) => setNewPropArea(e.target.value)}
                        placeholder="65"
                        className="w-full px-3 py-2 rounded-xl border border-[#E2E8F0] focus:outline-hidden focus:ring-2 focus:ring-blue-500/20"
                      />
                    </div>
                    <div>
                      <label className="block font-semibold text-slate-700 mb-1">
                        {t("agency_props_field_floor")}
                      </label>
                      <input
                        type="text"
                        value={newPropFloor}
                        onChange={(e) => setNewPropFloor(e.target.value)}
                        placeholder="4"
                        className="w-full px-3 py-2 rounded-xl border border-[#E2E8F0] focus:outline-hidden focus:ring-2 focus:ring-blue-500/20"
                      />
                    </div>
                  </div>

                  <div className="pt-2 border-t border-slate-200">
                    <h4 className="font-bold text-slate-800 mb-2">
                      {t("agency_props_col_landlord")}
                    </h4>
                    <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                      <div>
                        <label className="block text-[11px] text-slate-500 mb-1">
                          {t("agency_props_field_landlord_name")}
                        </label>
                        <input
                          type="text"
                          value={newPropLandlordName}
                          onChange={(e) => setNewPropLandlordName(e.target.value)}
                          placeholder="Marko Markovic"
                          className="w-full px-3 py-2 rounded-xl border border-[#E2E8F0] focus:outline-hidden"
                        />
                      </div>
                      <div>
                        <label className="block text-[11px] text-slate-500 mb-1">
                          {t("agency_props_field_landlord_phone")}
                        </label>
                        <input
                          type="text"
                          value={newPropLandlordPhone}
                          onChange={(e) => setNewPropLandlordPhone(e.target.value)}
                          placeholder="+381..."
                          className="w-full px-3 py-2 rounded-xl border border-[#E2E8F0] focus:outline-hidden"
                        />
                      </div>
                      <div>
                        <label className="block text-[11px] text-slate-500 mb-1">
                          {t("agency_props_field_landlord_email")}
                        </label>
                        <input
                          type="email"
                          value={newPropLandlordEmail}
                          onChange={(e) => setNewPropLandlordEmail(e.target.value)}
                          placeholder="marko@email.com"
                          className="w-full px-3 py-2 rounded-xl border border-[#E2E8F0] focus:outline-hidden"
                        />
                      </div>
                    </div>
                  </div>

                  <div className="pt-2 border-t border-slate-200 space-y-2">
                    <label className="flex items-center gap-2 cursor-pointer">
                      <input
                        type="checkbox"
                        checked={newPropIsOccupied}
                        onChange={(e) => setNewPropIsOccupied(e.target.checked)}
                        className="w-4 h-4 rounded-sm text-blue-600 focus:ring-blue-500 border-slate-300"
                      />
                      <span className="font-semibold text-slate-700">
                        {t("agency_props_field_occupied")}
                      </span>
                    </label>

                    {newPropIsOccupied && (
                      <div>
                        <label className="block text-[11px] text-slate-500 mb-1">
                          {t("agency_props_field_tenant_name")}
                        </label>
                        <input
                          type="text"
                          value={newPropTenantName}
                          onChange={(e) => setNewPropTenantName(e.target.value)}
                          placeholder="Jovan Jovanovic"
                          className="w-full px-3 py-2 rounded-xl border border-[#E2E8F0] focus:outline-hidden"
                        />
                      </div>
                    )}
                  </div>

                  <div className="flex items-center justify-end gap-2 pt-4 border-t border-slate-200">
                    <button
                      type="button"
                      onClick={() => setIsAddPropertyModalOpen(false)}
                      className="px-4 py-2 rounded-xl font-semibold text-slate-600 hover:bg-slate-100 transition-colors cursor-pointer"
                    >
                      {t("agency_prop_drawer_close")}
                    </button>
                    <button
                      type="submit"
                      disabled={isSubmittingNewProp}
                      className="px-5 py-2 rounded-[10px] text-xs sm:text-sm font-semibold bg-[#1B5888] hover:bg-[#15466d] text-white transition-colors shadow-2xs cursor-pointer disabled:opacity-50"
                    >
                      {isSubmittingNewProp ? "..." : t("agency_props_btn_save")}
                    </button>
                  </div>
                </form>
              </div>
            </div>
          )}
        </>
      )}

      {/* Landlord Ownership Invitation Modal (SSOT Flutter OwnershipShareSheet Parity) */}
      {ownershipModalProp && (
        <OwnershipInviteModal
          isOpen={!!ownershipModalProp}
          onClose={() => setOwnershipModalProp(null)}
          property={ownershipModalProp}
          agencyName={agencyName}
          agencyEmail={agencyEmail}
          isDemoMode={isDemoMode}
          userId={userId}
          t={t}
          onInviteSent={(propId, email) => {
            setDrawerLandlordInvites((prev) => [
              ...prev.filter((inv) => inv.invitee_email?.toLowerCase() !== email.toLowerCase()),
              { id: `inv_${Date.now()}`, invitee_email: email, status: "pending" },
            ]);
          }}
          onLandlordConfirmedOffline={(propId) => {
            setSelectedPropertyDrawer((prev) =>
              prev && prev.id === propId
                ? { ...prev, landlord_id: prev.landlord_id || "confirmed_offline" }
                : prev
            );
            setManagedProperties((prev) =>
              prev.map((item) =>
                item.id === propId
                  ? { ...item, landlord_id: item.landlord_id || "confirmed_offline" }
                  : item
              )
            );
          }}
        />
      )}

      {/* Edit Property Owners Modal (SSOT Flutter Parity) */}
      {editingOwnersProperty && (
        <EditPropertyOwnersModal
          isOpen={!!editingOwnersProperty}
          onClose={() => setEditingOwnersProperty(null)}
          property={editingOwnersProperty}
          isDemoMode={isDemoMode}
          userId={userId}
          agencyClients={agencyClients}
          t={t}
          onOwnersSaved={(updatedProperty) => {
            setManagedProperties((prev) =>
              prev.map((item) =>
                item.id === updatedProperty.id ? { ...item, ...updatedProperty } : item
              )
            );
            setSelectedPropertyDrawer((prev) =>
              prev && prev.id === updatedProperty.id
                ? { ...prev, ...updatedProperty }
                : prev
            );
            setEditingOwnersProperty(null);
          }}
        />
      )}

      {/* NEW CONTRACT / INVITE TENANT / UPDATE LEASE TERMS MODAL (100% Flutter Parity) */}
      {isNewContractModalOpen && newContractProperty && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/50 backdrop-blur-xs animate-in fade-in duration-200">
          <div className="bg-white rounded-2xl border border-[#E5E3DF] shadow-2xl max-w-2xl w-full p-6 space-y-5 max-h-[92vh] overflow-y-auto">
            <div className="flex items-center justify-between border-b border-slate-100 pb-3">
              <h3 className="text-sm font-bold text-[#1A1A1A] flex items-center gap-2">
                <UserCheck className="w-4 h-4 text-[#1B5888]" />
                <span>
                  {isUpdatingExistingContract
                    ? t("agency_contract_mode_update_terms")
                    : t("inviteTenantOrAddContract")}
                </span>
              </h3>
              <button
                type="button"
                onClick={() => {
                  setIsNewContractModalOpen(false);
                  setNewContractProperty(null);
                  setExistingContractTarget(null);
                }}
                className="text-[#666666] hover:text-[#4A4A4A] p-1 rounded-lg cursor-pointer"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <div className="p-3 bg-slate-50 rounded-xl border border-slate-200 space-y-1">
              <p className="font-bold text-sm text-[#0F172A]">{newContractProperty.title}</p>
              <p className="text-xs text-slate-500">{newContractProperty.address}</p>
            </div>

            {/* Existing Tenant Loaded Info Notice */}
            {hasExistingTenant && !isTenantInfoChanged && (
              <div className="flex items-center gap-2.5 p-3 rounded-[10px] bg-blue-50/80 border border-blue-200/80 text-blue-900 text-xs font-medium">
                <UserCheck className="w-4 h-4 text-blue-600 shrink-0" />
                <p className="leading-snug">{t("agency_existing_tenant_loaded_info")}</p>
              </div>
            )}

            {/* Informational Warning Banner when Tenant Email is Changed */}
            {isTenantInfoChanged && (
              <div className="flex items-start gap-2.5 p-3 rounded-[10px] bg-amber-50 border border-amber-200 text-amber-900 text-xs font-semibold animate-in fade-in duration-200">
                <AlertTriangle className="w-4 h-4 text-amber-600 shrink-0 mt-0.5" />
                <div className="leading-relaxed">
                  {t("agency_tenant_change_warning_banner")}
                </div>
              </div>
            )}

            {/* SECTION 1: TENANT DETAILS */}
            <div className="space-y-3">
              <div>
                <label className="text-xs font-bold text-[#4A4A4A] block mb-1">
                  {t("agency_contract_field_tenant_name")} *
                </label>
                <input
                  type="text"
                  value={newContractTenantName}
                  onChange={(e) => setNewContractTenantName(e.target.value)}
                  placeholder={t("placeholder_tenant_name_example")}
                  className="w-full text-xs font-semibold rounded-[10px] border border-[#E5E3DF] px-3 py-2 text-[#1A1A1A] focus:outline-hidden focus:border-[#1B5888]"
                />
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div>
                  <label className="text-xs font-bold text-[#4A4A4A] block mb-1">
                    {t("agency_contract_field_tenant_email")}
                  </label>
                  <input
                    type="email"
                    value={newContractTenantEmail}
                    onChange={(e) => setNewContractTenantEmail(e.target.value)}
                    placeholder="nikola@example.com"
                    className="w-full text-xs font-semibold rounded-[10px] border border-[#E5E3DF] px-3 py-2 text-[#1A1A1A] focus:outline-hidden focus:border-[#1B5888]"
                  />
                </div>
                <div>
                  <label className="text-xs font-bold text-[#4A4A4A] block mb-1">
                    {t("agency_contract_field_tenant_phone")}
                  </label>
                  <input
                    type="tel"
                    value={newContractTenantPhone}
                    onChange={(e) => setNewContractTenantPhone(e.target.value)}
                    placeholder="+381 64 123 4567"
                    className="w-full text-xs font-semibold rounded-[10px] border border-[#E5E3DF] px-3 py-2 text-[#1A1A1A] focus:outline-hidden focus:border-[#1B5888]"
                  />
                </div>
              </div>

              <div>
                <label className="text-xs font-bold text-[#4A4A4A] block mb-1">
                  {t("agency_contract_field_tenant_id")}
                </label>
                <input
                  type="text"
                  value={newContractTenantIdNumber}
                  onChange={(e) => setNewContractTenantIdNumber(e.target.value)}
                  placeholder={t("agency_contract_field_tenant_id_placeholder")}
                  className="w-full text-xs font-semibold rounded-[10px] border border-[#E5E3DF] px-3 py-2 text-[#1A1A1A] focus:outline-hidden focus:border-[#1B5888]"
                />
              </div>

              <div>
                <label className="text-xs font-bold text-[#4A4A4A] block mb-1">
                  {t("agency_contract_field_tenant_notes")}
                </label>
                <textarea
                  rows={2}
                  value={newContractTenantNotes}
                  onChange={(e) => setNewContractTenantNotes(e.target.value)}
                  placeholder={t("agency_contract_field_tenant_notes_placeholder")}
                  className="w-full text-xs font-semibold rounded-[10px] border border-[#E5E3DF] px-3 py-2 text-[#1A1A1A] focus:outline-hidden focus:border-[#1B5888] resize-none"
                />
              </div>

              {/* Tenant ID Document Upload */}
              <div className="p-3 rounded-xl border border-slate-200 bg-slate-50/60 flex items-center justify-between gap-3">
                <div className="flex items-center gap-2.5 min-w-0">
                  <FileUp className={`w-4 h-4 shrink-0 ${newContractTenantIdDocUrl ? "text-emerald-600" : "text-[#1B5888]"}`} />
                  <div className="min-w-0">
                    <p className="text-xs font-bold text-slate-800">
                      {t("agency_contract_field_tenant_id_doc")}
                    </p>
                    <p className="text-[11px] text-slate-500 truncate">
                      {newContractTenantIdDocUrl
                        ? newContractTenantIdDocName || t("agency_contract_id_doc_uploaded")
                        : t("agency_doc_file_formats")}
                    </p>
                  </div>
                </div>
                <div className="flex items-center gap-1.5 shrink-0">
                  {newContractTenantIdDocUrl && (
                    <>
                      <a
                        href={newContractTenantIdDocUrl}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="p-1.5 rounded-lg text-[#1B5888] hover:bg-blue-50"
                      >
                        <ExternalLink className="w-4 h-4" />
                      </a>
                      <button
                        type="button"
                        onClick={() => {
                          setNewContractTenantIdDocUrl(null);
                          setNewContractTenantIdDocName("");
                        }}
                        className="p-1.5 rounded-lg text-rose-600 hover:bg-rose-50 cursor-pointer"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </>
                  )}
                  <label className="px-3 py-1.5 rounded-lg border border-[#1B5888]/40 bg-white text-xs font-bold text-[#1B5888] hover:bg-blue-50/50 transition-colors cursor-pointer">
                    <span>{isUploadingTenantIdDoc ? "..." : t("agency_doc_pick_file")}</span>
                    <input
                      type="file"
                      accept="image/*,application/pdf"
                      className="hidden"
                      onChange={async (e) => {
                        const file = e.target.files?.[0];
                        if (!file) return;
                        setIsUploadingTenantIdDoc(true);
                        try {
                          const url = await uploadContractOrTenantFile(file, "tenants", newContractProperty.id);
                          setNewContractTenantIdDocUrl(url);
                          setNewContractTenantIdDocName(file.name);
                        } finally {
                          setIsUploadingTenantIdDoc(false);
                        }
                      }}
                    />
                  </label>
                </div>
              </div>

              {/* Secondary Contacts Section (Flutter TenantSecondaryContactsSection Parity) */}
              <div className="pt-2 space-y-2.5">
                <div className="flex items-center justify-between">
                  <span className="text-xs font-bold text-[#4A4A4A]">
                    {t("agency_contract_secondary_contacts_heading")}
                  </span>
                  <button
                    type="button"
                    onClick={() =>
                      setNewContractSecondaryContacts((prev) => [
                        ...prev,
                        { full_name: "", relationship: "", phone: "", email: "" },
                      ])
                    }
                    className="inline-flex items-center gap-1 text-xs font-bold text-[#1B5888] hover:underline cursor-pointer"
                  >
                    <UserPlus className="w-3.5 h-3.5" />
                    <span>{t("agency_contract_add_secondary_contact")}</span>
                  </button>
                </div>

                {newContractSecondaryContacts.length === 0 ? (
                  <p className="text-[11px] text-slate-400 bg-slate-50 p-2.5 rounded-xl border border-slate-200/70">
                    {t("agency_contract_secondary_contacts_empty")}
                  </p>
                ) : (
                  <div className="space-y-2.5">
                    {newContractSecondaryContacts.map((sc, idx) => {
                      const rolePresets = [
                        t("agency_contract_role_assistant"),
                        t("agency_contract_role_pr"),
                        t("agency_contract_role_family"),
                        t("agency_contract_role_authorized"),
                        t("agency_contract_role_other"),
                      ];
                      return (
                        <div
                          key={idx}
                          className="p-3 rounded-xl bg-slate-50 border border-slate-200 space-y-2.5"
                        >
                          <div className="flex items-center justify-between">
                            <span className="text-xs font-bold text-slate-700">
                              #{idx + 1} {t("agency_contract_secondary_contacts_heading")}
                            </span>
                            <button
                              type="button"
                              onClick={() =>
                                setNewContractSecondaryContacts((prev) =>
                                  prev.filter((_, i) => i !== idx)
                                )
                              }
                              className="text-rose-600 hover:bg-rose-50 p-1 rounded-lg cursor-pointer"
                            >
                              <Trash2 className="w-3.5 h-3.5" />
                            </button>
                          </div>

                          <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
                            <input
                              type="text"
                              value={sc.full_name}
                              onChange={(e) => {
                                const val = e.target.value;
                                setNewContractSecondaryContacts((prev) =>
                                  prev.map((item, i) =>
                                    i === idx ? { ...item, full_name: val } : item
                                  )
                                );
                              }}
                              placeholder={`${t("agency_contract_sec_contact_name")} *`}
                              className="w-full text-xs font-semibold rounded-lg border border-slate-200 bg-white px-2.5 py-1.5 text-slate-900"
                            />
                            <input
                              type="text"
                              value={sc.relationship}
                              onChange={(e) => {
                                const val = e.target.value;
                                setNewContractSecondaryContacts((prev) =>
                                  prev.map((item, i) =>
                                    i === idx ? { ...item, relationship: val } : item
                                  )
                                );
                              }}
                              placeholder={t("agency_contract_sec_contact_role")}
                              className="w-full text-xs font-semibold rounded-lg border border-slate-200 bg-white px-2.5 py-1.5 text-slate-900"
                            />
                          </div>

                          <div className="flex flex-wrap gap-1">
                            {rolePresets.map((rp) => {
                              const active = sc.relationship.trim().toLowerCase() === rp.toLowerCase();
                              return (
                                <button
                                  key={rp}
                                  type="button"
                                  onClick={() =>
                                    setNewContractSecondaryContacts((prev) =>
                                      prev.map((item, i) =>
                                        i === idx ? { ...item, relationship: rp } : item
                                      )
                                    )
                                  }
                                  className={`px-2 py-0.5 rounded-full text-[10px] font-bold border transition-colors cursor-pointer ${active
                                    ? "bg-[#1B5888] text-white border-[#1B5888]"
                                    : "bg-white text-slate-600 border-slate-200 hover:bg-slate-100"
                                    }`}
                                >
                                  {rp}
                                </button>
                              );
                            })}
                          </div>

                          <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
                            <input
                              type="tel"
                              value={sc.phone || ""}
                              onChange={(e) => {
                                const val = e.target.value;
                                setNewContractSecondaryContacts((prev) =>
                                  prev.map((item, i) =>
                                    i === idx ? { ...item, phone: val } : item
                                  )
                                );
                              }}
                              placeholder={t("agency_contract_field_tenant_phone")}
                              className="w-full text-xs font-semibold rounded-lg border border-slate-200 bg-white px-2.5 py-1.5 text-slate-900"
                            />
                            <input
                              type="email"
                              value={sc.email || ""}
                              onChange={(e) => {
                                const val = e.target.value;
                                setNewContractSecondaryContacts((prev) =>
                                  prev.map((item, i) =>
                                    i === idx ? { ...item, email: val } : item
                                  )
                                );
                              }}
                              placeholder={t("agency_contract_field_tenant_email")}
                              className="w-full text-xs font-semibold rounded-lg border border-slate-200 bg-white px-2.5 py-1.5 text-slate-900"
                            />
                          </div>
                        </div>
                      );
                    })}
                  </div>
                )}
              </div>

              {/* SECTION 2: FINANCIAL TERMS & DATES */}
              <div className="pt-3 border-t border-slate-100 space-y-3">
                <div className="grid grid-cols-2 sm:grid-cols-5 gap-2.5">
                  <div className="col-span-1 sm:col-span-2">
                    <label className="text-xs font-bold text-[#4A4A4A] block mb-1">
                      {t("agency_props_col_rent")} *
                    </label>
                    <div className="flex gap-1.5">
                      <input
                        type="number"
                        value={newContractRent}
                        onChange={(e) => setNewContractRent(e.target.value)}
                        placeholder="600"
                        className="w-full text-xs font-semibold rounded-[10px] border border-[#E5E3DF] px-3 py-2 text-[#1A1A1A] focus:outline-hidden focus:border-[#1B5888]"
                      />
                      <select
                        value={newContractCurrency}
                        onChange={(e) => {
                          setNewContractCurrency(e.target.value);
                          setNewContractDepositCurrency(e.target.value);
                        }}
                        className="text-xs font-bold rounded-[10px] border border-[#E5E3DF] px-2 py-2 bg-white text-[#1A1A1A]"
                      >
                        <option value="EUR">EUR</option>
                        <option value="RSD">RSD</option>
                      </select>
                    </div>
                  </div>
                  <div className="col-span-1 sm:col-span-2">
                    <label className="text-xs font-bold text-[#4A4A4A] block mb-1">
                      {t("agency_prop_drawer_deposit")}
                    </label>
                    <div className="flex gap-1.5">
                      <input
                        type="number"
                        value={newContractDeposit}
                        onChange={(e) => setNewContractDeposit(e.target.value)}
                        placeholder="600"
                        className="w-full text-xs font-semibold rounded-[10px] border border-[#E5E3DF] px-3 py-2 text-[#1A1A1A] focus:outline-hidden focus:border-[#1B5888]"
                      />
                      <select
                        value={newContractDepositCurrency}
                        onChange={(e) => setNewContractDepositCurrency(e.target.value)}
                        className="text-xs font-bold rounded-[10px] border border-[#E5E3DF] px-2 py-2 bg-white text-[#1A1A1A]"
                      >
                        <option value="EUR">EUR</option>
                        <option value="RSD">RSD</option>
                      </select>
                    </div>
                  </div>
                  <div className="col-span-2 sm:col-span-1">
                    <label className="text-xs font-bold text-[#4A4A4A] block mb-1">
                      {t("agency_prop_drawer_due_day")}
                    </label>
                    <input
                      type="number"
                      min="1"
                      max="31"
                      value={newContractDueDay}
                      onChange={(e) => setNewContractDueDay(e.target.value)}
                      className="w-full text-xs font-semibold rounded-[10px] border border-[#E5E3DF] px-3 py-2 text-[#1A1A1A] focus:outline-hidden focus:border-[#1B5888]"
                    />
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="text-xs font-bold text-[#4A4A4A] block mb-1">
                      {t("agency_contract_renew_start_date")} *
                    </label>
                    <input
                      type="date"
                      value={newContractStartDate}
                      onChange={(e) => setNewContractStartDate(e.target.value)}
                      className="w-full text-xs font-semibold rounded-[10px] border border-[#E5E3DF] px-3 py-2 text-[#1A1A1A] focus:outline-hidden focus:border-[#1B5888]"
                    />
                  </div>
                  <div>
                    <label className="text-xs font-bold text-[#4A4A4A] block mb-1">
                      {t("agency_contract_renew_end_date")} *
                    </label>
                    <input
                      type="date"
                      value={newContractEndDate}
                      onChange={(e) => setNewContractEndDate(e.target.value)}
                      className="w-full text-xs font-semibold rounded-[10px] border border-[#E5E3DF] px-3 py-2 text-[#1A1A1A] focus:outline-hidden focus:border-[#1B5888]"
                    />
                  </div>
                </div>
              </div>

              {/* SECTION 3: UTILITY & EXPENSE RESPONSIBILITIES (Flutter _buildExpensesSection Parity) */}
              <div className="pt-3 border-t border-slate-100 space-y-2.5">
                <span className="text-xs font-bold text-[#4A4A4A] block">
                  {t("agency_contract_expenses_heading")}
                </span>
                <div className="divide-y divide-slate-200/70 rounded-xl border border-slate-200 overflow-hidden bg-slate-50/40">
                  {newContractExpenses.map((exp, idx) => {
                    const isInc = exp.receiver === "included";
                    return (
                      <div key={idx} className="p-3 space-y-2">
                        <div className="flex items-center justify-between gap-2">
                          <span className="text-xs font-bold text-slate-800">{exp.name}</span>
                          <div className="flex items-center gap-2">
                            <label className="inline-flex items-center gap-1.5 text-[11px] font-semibold text-slate-600 cursor-pointer">
                              <input
                                type="checkbox"
                                checked={isInc}
                                onChange={(e) => {
                                  const checked = e.target.checked;
                                  setNewContractExpenses((prev) =>
                                    prev.map((item, i) =>
                                      i === idx
                                        ? { ...item, receiver: checked ? "included" : "owner" }
                                        : item
                                    )
                                  );
                                }}
                                className="rounded text-[#1B5888]"
                              />
                              <span>{t("agency_expense_receiver_included")}</span>
                            </label>
                            {!isStandardExpenseName(exp.name) && (
                              <button
                                type="button"
                                onClick={() =>
                                  setNewContractExpenses((prev) => prev.filter((_, i) => i !== idx))
                                }
                                className="text-rose-600 hover:bg-rose-50 p-1 rounded cursor-pointer"
                              >
                                <Trash2 className="w-3.5 h-3.5" />
                              </button>
                            )}
                          </div>
                        </div>

                        {!isInc && (
                          <div className="flex flex-wrap items-center justify-between gap-2 pt-1">
                            <div className="flex items-center gap-1.5">
                              <span className="text-[10px] font-semibold text-slate-400">
                                {t("agency_expense_tenant_pays_to")}
                              </span>
                              <button
                                type="button"
                                onClick={() =>
                                  setNewContractExpenses((prev) =>
                                    prev.map((item, i) =>
                                      i === idx ? { ...item, receiver: "owner" } : item
                                    )
                                  )
                                }
                                className={`px-2 py-1 rounded-lg text-[11px] font-bold border cursor-pointer ${exp.receiver === "owner"
                                  ? "bg-[#E5EEF6] border-[#1B5888] text-[#1B5888]"
                                  : "bg-white border-slate-200 text-slate-600"
                                  }`}
                              >
                                {t("agency_expense_receiver_owner")}
                              </button>
                              <button
                                type="button"
                                onClick={() =>
                                  setNewContractExpenses((prev) =>
                                    prev.map((item, i) =>
                                      i === idx ? { ...item, receiver: "utility" } : item
                                    )
                                  )
                                }
                                className={`px-2 py-1 rounded-lg text-[11px] font-bold border cursor-pointer ${exp.receiver === "utility"
                                  ? "bg-purple-50 border-purple-600 text-purple-700"
                                  : "bg-white border-slate-200 text-slate-600"
                                  }`}
                              >
                                {t("agency_expense_receiver_utility")}
                              </button>
                            </div>

                            <div className="flex items-center gap-1">
                              <button
                                type="button"
                                onClick={() =>
                                  setNewContractExpenses((prev) =>
                                    prev.map((item, i) =>
                                      i === idx ? { ...item, payment_method: "bank_transfer" } : item
                                    )
                                  )
                                }
                                className={`px-2 py-1 rounded-lg text-[11px] font-bold border cursor-pointer ${exp.payment_method !== "cash"
                                  ? "bg-blue-50 border-blue-600 text-blue-700"
                                  : "bg-white border-slate-200 text-slate-500"
                                  }`}
                              >
                                {t("agency_pay_method_bank")}
                              </button>
                              <button
                                type="button"
                                onClick={() =>
                                  setNewContractExpenses((prev) =>
                                    prev.map((item, i) =>
                                      i === idx ? { ...item, payment_method: "cash" } : item
                                    )
                                  )
                                }
                                className={`px-2 py-1 rounded-lg text-[11px] font-bold border cursor-pointer ${exp.payment_method === "cash"
                                  ? "bg-amber-50 border-amber-600 text-amber-800"
                                  : "bg-white border-slate-200 text-slate-500"
                                  }`}
                              >
                                {t("agency_pay_method_cash")}
                              </button>
                            </div>
                          </div>
                        )}
                      </div>
                    );
                  })}
                </div>

                {/* Add Custom Expense Row */}
                <div className="flex items-center gap-2">
                  <input
                    type="text"
                    value={customExpenseNameInput}
                    onChange={(e) => setCustomExpenseNameInput(e.target.value)}
                    placeholder={t("agency_expense_custom_placeholder")}
                    className="flex-1 text-xs font-semibold rounded-lg border border-slate-200 px-3 py-1.5 text-slate-900"
                  />
                  <button
                    type="button"
                    onClick={() => {
                      const raw = customExpenseNameInput.trim();
                      if (!raw) return;
                      if (newContractExpenses.some((e) => e.name.toLowerCase() === raw.toLowerCase())) return;
                      setNewContractExpenses((prev) => [
                        ...prev,
                        { name: raw, receiver: "owner", amount: 0, payment_method: "bank_transfer" },
                      ]);
                      setCustomExpenseNameInput("");
                    }}
                    className="px-3 py-1.5 rounded-lg bg-slate-100 hover:bg-slate-200 text-xs font-bold text-slate-700 cursor-pointer shrink-0"
                  >
                    + {t("agency_expense_add_custom")}
                  </button>
                </div>
              </div>

              {/* SECTION 4: CONTRACT & ADDITIONAL DOCUMENTS */}
              <div className="pt-3 border-t border-slate-100 space-y-2.5">
                <span className="text-xs font-bold text-[#4A4A4A] block">
                  {t("agency_contract_docs_heading")}
                </span>

                {/* Main Contract PDF */}
                <div className="p-3 rounded-xl border border-slate-200 bg-slate-50/60 flex items-center justify-between gap-3">
                  <div className="flex items-center gap-2.5 min-w-0">
                    <FileText className={`w-4 h-4 shrink-0 ${newContractMainDocUrl ? "text-emerald-600" : "text-[#1B5888]"}`} />
                    <div className="min-w-0">
                      <p className="text-xs font-bold text-slate-800">
                        {t("agency_contract_main_doc_label")}
                      </p>
                      <p className="text-[11px] text-slate-500 truncate">
                        {newContractMainDocUrl
                          ? newContractMainDocName || "Contract.pdf"
                          : t("agency_doc_file_formats")}
                      </p>
                    </div>
                  </div>
                  <div className="flex items-center gap-1.5 shrink-0">
                    {newContractMainDocUrl && (
                      <>
                        <a
                          href={newContractMainDocUrl}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="p-1.5 rounded-lg text-[#1B5888] hover:bg-blue-50"
                        >
                          <ExternalLink className="w-4 h-4" />
                        </a>
                        <button
                          type="button"
                          onClick={() => {
                            setNewContractMainDocUrl(null);
                            setNewContractMainDocName("");
                          }}
                          className="p-1.5 rounded-lg text-rose-600 hover:bg-rose-50 cursor-pointer"
                        >
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </>
                    )}
                    <label className="px-3 py-1.5 rounded-lg border border-[#1B5888]/40 bg-white text-xs font-bold text-[#1B5888] hover:bg-blue-50/50 transition-colors cursor-pointer">
                      <span>{isUploadingMainContractDoc ? "..." : t("agency_doc_pick_file")}</span>
                      <input
                        type="file"
                        accept="image/*,application/pdf"
                        className="hidden"
                        onChange={async (e) => {
                          const file = e.target.files?.[0];
                          if (!file) return;
                          setIsUploadingMainContractDoc(true);
                          try {
                            const url = await uploadContractOrTenantFile(file, "contracts", newContractProperty.id);
                            setNewContractMainDocUrl(url);
                            setNewContractMainDocName(file.name);
                          } finally {
                            setIsUploadingMainContractDoc(false);
                          }
                        }}
                      />
                    </label>
                  </div>
                </div>

                {/* Additional Documents List */}
                {newContractAdditionalDocs.length > 0 && (
                  <div className="space-y-1.5">
                    {newContractAdditionalDocs.map((doc, idx) => (
                      <div
                        key={idx}
                        className="p-2.5 rounded-xl border border-slate-200 bg-white flex items-center justify-between gap-2 text-xs"
                      >
                        <div className="flex items-center gap-2 min-w-0">
                          <Paperclip className="w-3.5 h-3.5 text-slate-400 shrink-0" />
                          <span className="font-semibold text-slate-800 truncate">{doc.name}</span>
                        </div>
                        <div className="flex items-center gap-1 shrink-0">
                          <a
                            href={doc.url}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="p-1 rounded text-[#1B5888] hover:bg-blue-50"
                          >
                            <ExternalLink className="w-3.5 h-3.5" />
                          </a>
                          <button
                            type="button"
                            onClick={() =>
                              setNewContractAdditionalDocs((prev) => prev.filter((_, i) => i !== idx))
                            }
                            className="p-1 rounded text-rose-600 hover:bg-rose-50 cursor-pointer"
                          >
                            <Trash2 className="w-3.5 h-3.5" />
                          </button>
                        </div>
                      </div>
                    ))}
                  </div>
                )}

                {/* Add Additional Document */}
                <div className="flex items-center gap-2">
                  <input
                    type="text"
                    value={newAdditionalDocTitle}
                    onChange={(e) => setNewAdditionalDocTitle(e.target.value)}
                    placeholder={t("agency_contract_doc_name_placeholder")}
                    className="flex-1 text-xs font-semibold rounded-lg border border-slate-200 px-3 py-1.5 text-slate-900"
                  />
                  <label className="px-3 py-1.5 rounded-lg bg-slate-100 hover:bg-slate-200 text-xs font-bold text-slate-700 cursor-pointer shrink-0">
                    <span>{isUploadingAdditionalDoc ? "..." : `+ ${t("agency_contract_add_additional_doc")}`}</span>
                    <input
                      type="file"
                      accept="image/*,application/pdf"
                      className="hidden"
                      onChange={async (e) => {
                        const file = e.target.files?.[0];
                        if (!file) return;
                        setIsUploadingAdditionalDoc(true);
                        try {
                          const url = await uploadContractOrTenantFile(file, "contracts_extra", newContractProperty.id);
                          const docTitle = newAdditionalDocTitle.trim() || file.name;
                          setNewContractAdditionalDocs((prev) => [
                            ...prev,
                            { name: docTitle, url, created_at: new Date().toISOString() },
                          ]);
                          setNewAdditionalDocTitle("");
                        } finally {
                          setIsUploadingAdditionalDoc(false);
                        }
                      }}
                    />
                  </label>
                </div>
              </div>
            </div>

            <div className="flex items-center justify-end gap-2 pt-3 border-t border-slate-100">
              <button
                type="button"
                onClick={() => {
                  setIsNewContractModalOpen(false);
                  setNewContractProperty(null);
                  setExistingContractTarget(null);
                }}
                className="px-3.5 py-2 rounded-[10px] text-xs font-bold text-[#4A4A4A] hover:bg-slate-100 transition-colors cursor-pointer"
              >
                {t("agency_prop_drawer_close")}
              </button>
              <button
                type="button"
                disabled={isCreatingContract}
                onClick={() => handleExecuteCreateContract(newContractProperty)}
                className="px-4 py-2 rounded-[10px] text-xs font-bold bg-[#1B5888] text-white hover:bg-blue-700 transition-colors shadow-xs cursor-pointer disabled:opacity-50"
              >
                {isCreatingContract
                  ? "..."
                  : isUpdatingExistingContract
                    ? t("agency_contract_btn_update_existing")
                    : t("agency_contract_btn_new_contract")}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* EDIT PROPERTY DETAILS & SPECS MODAL (100% Flutter PropertySpecsFormSection Parity) */}
      {editingSpecsProperty && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/50 backdrop-blur-xs animate-in fade-in duration-200">
          <div className="bg-white rounded-2xl border border-slate-200 shadow-2xl max-w-2xl w-full p-6 space-y-5 max-h-[92vh] overflow-y-auto">
            <div className="flex items-start justify-between border-b border-slate-100 pb-3">
              <div>
                <h3 className="text-base font-bold text-slate-900 flex items-center gap-2">
                  <Home className="w-4 h-4 text-[#1B5888]" />
                  <span>{t("agency_prop_edit_specs_modal_title")}</span>
                </h3>
                <p className="text-xs text-slate-500 mt-0.5">
                  {t("agency_prop_edit_specs_modal_sub")}
                </p>
              </div>
              <button
                type="button"
                onClick={() => setEditingSpecsProperty(null)}
                className="text-slate-400 hover:text-slate-600 p-1 rounded-lg cursor-pointer"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="space-y-4">
              {/* Title, Address, City */}
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                <div className="sm:col-span-2">
                  <label className="text-xs font-bold text-slate-700 block mb-1">
                    {t("agency_props_field_title")} *
                  </label>
                  <input
                    type="text"
                    value={specTitle}
                    onChange={(e) => setSpecTitle(e.target.value)}
                    className="w-full text-xs font-semibold rounded-xl border border-slate-200 px-3 py-2 text-slate-900"
                  />
                </div>
                <div>
                  <label className="text-xs font-bold text-slate-700 block mb-1">
                    {t("agency_props_field_city")}
                  </label>
                  <input
                    type="text"
                    value={specCity}
                    onChange={(e) => setSpecCity(e.target.value)}
                    className="w-full text-xs font-semibold rounded-xl border border-slate-200 px-3 py-2 text-slate-900"
                  />
                </div>
              </div>

              <div>
                <label className="text-xs font-bold text-slate-700 block mb-1">
                  {t("agency_props_field_address")} *
                </label>
                <input
                  type="text"
                  value={specAddress}
                  onChange={(e) => setSpecAddress(e.target.value)}
                  className="w-full text-xs font-semibold rounded-xl border border-slate-200 px-3 py-2 text-slate-900"
                />
              </div>

              {/* Property Type Selector */}
              <div>
                <label className="text-xs font-bold text-slate-700 block mb-1.5">
                  {t("agency_prop_spec_type")}
                </label>
                <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
                  {[
                    { id: "apartment", label: t("agency_prop_type_apartment") },
                    { id: "house", label: t("agency_prop_type_house") },
                    { id: "commercial", label: t("agency_prop_type_commercial") },
                    { id: "garage", label: t("agency_prop_type_garage") },
                  ].map((pt) => (
                    <button
                      key={pt.id}
                      type="button"
                      onClick={() => setSpecPropertyType(pt.id)}
                      className={`px-3 py-2 rounded-xl text-xs font-bold border transition-colors cursor-pointer ${specPropertyType === pt.id
                        ? "bg-[#E5EEF6] border-[#1B5888] text-[#1B5888]"
                        : "bg-slate-50 border-slate-200 text-slate-600 hover:bg-slate-100"
                        }`}
                    >
                      {pt.label}
                    </button>
                  ))}
                </div>
              </div>

              {/* Room Count Pills */}
              <div>
                <label className="text-xs font-bold text-slate-700 block mb-1.5">
                  {t("agency_prop_spec_rooms")}
                </label>
                <div className="flex flex-wrap gap-1.5">
                  {["studio", "1.0", "1.5", "2.0", "2.5", "3.0", "3.5", "4.0", "5.0+"].map((rc) => (
                    <button
                      key={rc}
                      type="button"
                      onClick={() => setSpecRoomCount(rc)}
                      className={`px-3 py-1.5 rounded-full text-xs font-bold border transition-colors cursor-pointer ${specRoomCount === rc
                        ? "bg-[#1B5888] border-[#1B5888] text-white"
                        : "bg-slate-50 border-slate-200 text-slate-700 hover:bg-slate-100"
                        }`}
                    >
                      {rc === "studio" ? t("agency_prop_room_studio") : rc}
                    </button>
                  ))}
                </div>
              </div>

              {/* Area, Floor, Total Floors, Unit Number */}
              <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
                <div>
                  <label className="text-xs font-bold text-slate-700 block mb-1">
                    {t("agency_props_field_area")}
                  </label>
                  <input
                    type="number"
                    step="0.5"
                    value={specAreaSqm}
                    onChange={(e) => setSpecAreaSqm(e.target.value)}
                    placeholder="58"
                    className="w-full text-xs font-semibold rounded-xl border border-slate-200 px-3 py-2 text-slate-900"
                  />
                </div>
                <div>
                  <label className="text-xs font-bold text-slate-700 block mb-1">
                    {t("agency_prop_spec_floor")}
                  </label>
                  <select
                    value={specFloor}
                    onChange={(e) => setSpecFloor(e.target.value)}
                    className="w-full text-xs font-semibold rounded-xl border border-slate-200 px-2.5 py-2 bg-white text-slate-900"
                  >
                    <option value="suteren">{t("agency_prop_floor_suteren")}</option>
                    <option value="prizemlje">{t("agency_prop_floor_prizemlje")}</option>
                    <option value="visoko_prizemlje">{t("agency_prop_floor_visoko_prizemlje")}</option>
                    {["1", "2", "3", "4", "5", "6", "7", "8", "9", "10+"].map((fl) => (
                      <option key={fl} value={fl}>
                        {fl}
                      </option>
                    ))}
                    <option value="potkrovlje">{t("agency_prop_floor_potkrovlje")}</option>
                  </select>
                </div>
                <div>
                  <label className="text-xs font-bold text-slate-700 block mb-1">
                    {t("agency_prop_spec_total_floors")}
                  </label>
                  <input
                    type="number"
                    value={specTotalFloors}
                    onChange={(e) => setSpecTotalFloors(e.target.value)}
                    placeholder="6"
                    className="w-full text-xs font-semibold rounded-xl border border-slate-200 px-3 py-2 text-slate-900"
                  />
                </div>
                <div>
                  <label className="text-xs font-bold text-slate-700 block mb-1">
                    {t("agency_prop_spec_unit")}
                  </label>
                  <input
                    type="text"
                    value={specUnitNumber}
                    onChange={(e) => setSpecUnitNumber(e.target.value)}
                    placeholder="14"
                    className="w-full text-xs font-semibold rounded-xl border border-slate-200 px-3 py-2 text-slate-900"
                  />
                </div>
              </div>

              {/* Furnishing & Heating Type */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div>
                  <label className="text-xs font-bold text-slate-700 block mb-1">
                    {t("agency_prop_spec_furnishing")}
                  </label>
                  <select
                    value={specFurnishing}
                    onChange={(e) => setSpecFurnishing(e.target.value)}
                    className="w-full text-xs font-semibold rounded-xl border border-slate-200 px-3 py-2 bg-white text-slate-900"
                  >
                    <option value="furnished">{t("agency_prop_furnish_furnished")}</option>
                    <option value="semi_furnished">{t("agency_prop_furnish_semi_furnished")}</option>
                    <option value="unfurnished">{t("agency_prop_furnish_unfurnished")}</option>
                  </select>
                </div>
                <div>
                  <label className="text-xs font-bold text-slate-700 block mb-1">
                    {t("agency_prop_spec_heating")}
                  </label>
                  <select
                    value={specHeatingType}
                    onChange={(e) => setSpecHeatingType(e.target.value)}
                    className="w-full text-xs font-semibold rounded-xl border border-slate-200 px-3 py-2 bg-white text-slate-900"
                  >
                    <option value="cg">{t("agency_prop_heat_cg")}</option>
                    <option value="eg">{t("agency_prop_heat_eg")}</option>
                    <option value="gas">{t("agency_prop_heat_gas")}</option>
                    <option value="underfloor">{t("agency_prop_heat_underfloor")}</option>
                    <option value="ta">{t("agency_prop_heat_ta")}</option>
                    <option value="klima">{t("agency_prop_heat_klima")}</option>
                  </select>
                </div>
              </div>

              {/* Featured Amenities */}
              <div>
                <label className="text-xs font-bold text-slate-700 block mb-1.5">
                  {t("agency_prop_spec_amenities")}
                </label>
                <div className="flex flex-wrap gap-2">
                  {[
                    { id: "elevator", label: t("agency_panel_amenity_elevator") },
                    { id: "balcony", label: t("agency_panel_amenity_balcony") },
                    { id: "parking", label: t("agency_panel_amenity_parking") },
                    { id: "garage", label: t("agency_panel_amenity_garage") },
                    { id: "storage", label: t("agency_panel_amenity_storage") },
                    { id: "air_conditioning", label: t("agency_panel_amenity_ac") },
                    { id: "pets_allowed", label: t("agency_panel_amenity_pets") },
                    { id: "security", label: t("agency_panel_amenity_security") },
                    { id: "intercom", label: t("agency_panel_amenity_intercom") },
                  ].map((am) => {
                    const checked = specAmenities.includes(am.id);
                    return (
                      <button
                        key={am.id}
                        type="button"
                        onClick={() =>
                          setSpecAmenities((prev) =>
                            prev.includes(am.id)
                              ? prev.filter((x) => x !== am.id)
                              : [...prev, am.id]
                          )
                        }
                        className={`px-3 py-1.5 rounded-xl text-xs font-bold border transition-colors cursor-pointer ${checked
                          ? "bg-[#E5EEF6] border-[#1B5888] text-[#1B5888]"
                          : "bg-slate-50 border-slate-200 text-slate-600 hover:bg-slate-100"
                          }`}
                      >
                        {checked ? "✓ " : ""}
                        {am.label}
                      </button>
                    );
                  })}
                </div>
              </div>

              {/* Description */}
              <div>
                <label className="text-xs font-bold text-slate-700 block mb-1">
                  {t("agency_prop_spec_description")}
                </label>
                <textarea
                  rows={3}
                  value={specDescription}
                  onChange={(e) => setSpecDescription(e.target.value)}
                  placeholder={t("agency_prop_spec_description_placeholder")}
                  className="w-full text-xs font-semibold rounded-xl border border-slate-200 px-3 py-2 text-slate-900 resize-none"
                />
              </div>

              {/* Default Lease & Expense Template */}
              <div className="pt-3 border-t border-slate-100 space-y-3">
                <span className="text-xs font-bold text-slate-800 block">
                  {t("agency_prop_spec_default_terms_heading")}
                </span>
                <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                  <div>
                    <label className="text-xs font-bold text-slate-700 block mb-1">
                      {t("agency_props_col_rent")}
                    </label>
                    <div className="flex gap-1.5">
                      <input
                        type="number"
                        value={specDefaultRent}
                        onChange={(e) => setSpecDefaultRent(e.target.value)}
                        className="w-full text-xs font-semibold rounded-xl border border-slate-200 px-3 py-2 text-slate-900"
                      />
                      <select
                        value={specCurrency}
                        onChange={(e) => {
                          setSpecCurrency(e.target.value);
                          setSpecDefaultDepositCurrency(e.target.value);
                        }}
                        className="text-xs font-bold rounded-xl border border-slate-200 px-2 py-2 bg-white"
                      >
                        <option value="EUR">EUR</option>
                        <option value="RSD">RSD</option>
                      </select>
                    </div>
                  </div>
                  <div>
                    <label className="text-xs font-bold text-slate-700 block mb-1">
                      {t("agency_prop_drawer_deposit")}
                    </label>
                    <input
                      type="number"
                      value={specDefaultDeposit}
                      onChange={(e) => setSpecDefaultDeposit(e.target.value)}
                      className="w-full text-xs font-semibold rounded-xl border border-slate-200 px-3 py-2 text-slate-900"
                    />
                  </div>
                  <div>
                    <label className="text-xs font-bold text-slate-700 block mb-1">
                      {t("agency_prop_drawer_due_day")}
                    </label>
                    <input
                      type="number"
                      min="1"
                      max="31"
                      value={specDefaultDueDay}
                      onChange={(e) => setSpecDefaultDueDay(e.target.value)}
                      className="w-full text-xs font-semibold rounded-xl border border-slate-200 px-3 py-2 text-slate-900"
                    />
                  </div>
                </div>
              </div>
            </div>

            <div className="flex items-center justify-end gap-2 pt-3 border-t border-slate-100">
              <button
                type="button"
                onClick={() => setEditingSpecsProperty(null)}
                className="px-4 py-2 rounded-xl text-xs font-bold text-slate-600 hover:bg-slate-100 transition-colors cursor-pointer"
              >
                {t("agency_panel_cancel_btn")}
              </button>
              <button
                type="button"
                disabled={isSavingPropertySpecs}
                onClick={handleSavePropertySpecs}
                className="px-5 py-2 rounded-xl text-xs font-bold bg-[#1B5888] text-white hover:bg-[#12406A] transition-colors shadow-xs cursor-pointer disabled:opacity-50"
              >
                {isSavingPropertySpecs ? "..." : t("agency_panel_save_changes")}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* CHANGE LANDLORD MODAL */}
      {changeLandlordProp && (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-xs flex items-center justify-center p-4 z-50 animate-in fade-in duration-200">
          <div className="bg-white rounded-2xl max-w-md w-full p-6 shadow-2xl space-y-4">
            <div className="flex items-start justify-between">
              <div>
                <h3 className="text-base font-bold text-[#0F172A] flex items-center gap-2">
                  <UserPlus className="w-5 h-5 text-[#1B5888]" />
                  <span>{t("changeLandlordDialogTitle")}</span>
                </h3>
                <p className="text-xs text-slate-500 mt-1">
                  {t("changeLandlordDialogDesc")}
                </p>
              </div>
              <button
                type="button"
                onClick={() => setChangeLandlordProp(null)}
                className="text-slate-400 hover:text-slate-600 p-1 rounded-lg"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="p-3 bg-slate-50 rounded-xl border border-slate-200 space-y-1">
              <p className="font-bold text-sm text-[#0F172A]">{changeLandlordProp.title}</p>
              <p className="text-xs text-slate-500">{changeLandlordProp.address}</p>
            </div>

            <div className="space-y-3">
              <div>
                <label className="text-xs font-bold text-slate-700 block mb-1">
                  {t("agency_props_field_landlord_name")} *
                </label>
                <input
                  type="text"
                  value={changeLandlordName}
                  onChange={(e) => setChangeLandlordName(e.target.value)}
                  placeholder="Örn: Marko Petrović"
                  className="w-full text-xs font-semibold rounded-xl border border-slate-200 px-3 py-2.5 text-slate-900 focus:outline-hidden focus:border-[#1B5888]"
                />
              </div>

              <div>
                <label className="text-xs font-bold text-slate-700 block mb-1">
                  {t("agency_props_field_landlord_email")}
                </label>
                <input
                  type="email"
                  value={changeLandlordEmail}
                  onChange={(e) => setChangeLandlordEmail(e.target.value)}
                  placeholder="marko@example.com"
                  className="w-full text-xs font-semibold rounded-xl border border-slate-200 px-3 py-2.5 text-slate-900 focus:outline-hidden focus:border-[#1B5888]"
                />
              </div>

              <div>
                <label className="text-xs font-bold text-slate-700 block mb-1">
                  {t("agency_props_field_landlord_phone")}
                </label>
                <input
                  type="tel"
                  value={changeLandlordPhone}
                  onChange={(e) => setChangeLandlordPhone(e.target.value)}
                  placeholder="+381 60 123 4567"
                  className="w-full text-xs font-semibold rounded-xl border border-slate-200 px-3 py-2.5 text-slate-900 focus:outline-hidden focus:border-[#1B5888]"
                />
              </div>
            </div>

            <div className="flex items-center justify-end gap-2 pt-2 border-t border-slate-100">
              <button
                type="button"
                onClick={() => setChangeLandlordProp(null)}
                className="px-4 py-2 rounded-xl text-xs font-bold text-slate-600 hover:bg-slate-100 transition-colors cursor-pointer"
              >
                {t("agency_panel_cancel_btn")}
              </button>
              <button
                type="button"
                disabled={isUpdatingLandlord || !changeLandlordName.trim()}
                onClick={handleSaveChangeLandlord}
                className="px-4 py-2 rounded-xl text-xs font-bold bg-[#1B5888] text-white hover:bg-blue-700 transition-colors shadow-xs cursor-pointer disabled:opacity-50 flex items-center gap-1.5"
              >
                {isUpdatingLandlord ? "..." : t("agency_panel_save_changes")}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Offset From Rent Modal (SSOT Flutter Parity) */}
      {isOffsetModalOpen && selectedSettlementReq && selectedPropertyDrawer && (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-xs flex items-center justify-center p-4 z-50 animate-in fade-in duration-200">
          <div className="bg-white rounded-2xl max-w-lg w-full p-6 shadow-2xl space-y-4 max-h-[90vh] flex flex-col">
            {/* Modal Header */}
            <div className="flex items-start justify-between shrink-0">
              <div className="flex items-center gap-3">
                <div
                  className={`w-10 h-10 rounded-xl flex items-center justify-center shrink-0 ${selectedSettlementReq.paid_by === "landlord"
                    ? "bg-amber-100 text-amber-700"
                    : "bg-blue-100 text-[#1B5888]"
                    }`}
                >
                  {selectedSettlementReq.paid_by === "landlord" ? (
                    <ArrowUpRight className="w-5 h-5" />
                  ) : (
                    <ArrowDownLeft className="w-5 h-5" />
                  )}
                </div>
                <div>
                  <h3 className="text-base font-bold text-[#0F172A]">
                    {selectedSettlementReq.paid_by === "landlord"
                      ? t("selectRentToAdd")
                      : t("selectRentToOffset")}
                  </h3>
                  <p className="text-xs text-slate-500 mt-0.5">
                    {selectedSettlementReq.paid_by === "landlord"
                      ? t("optionAddToRentDesc")
                      : t("optionOffsetFromRentDesc")}
                  </p>
                </div>
              </div>
              <button
                type="button"
                onClick={() => {
                  setIsOffsetModalOpen(false);
                  setSelectedSettlementReq(null);
                  setOffsetError(null);
                }}
                className="text-slate-400 hover:text-slate-600 p-1.5 rounded-lg hover:bg-slate-100 transition-colors cursor-pointer"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Ticket Summary Banner */}
            <div
              className={`p-3 rounded-xl border flex items-center justify-between shrink-0 ${selectedSettlementReq.paid_by === "landlord"
                ? "bg-amber-50/70 border-amber-200/80"
                : "bg-blue-50/70 border-blue-200/80"
                }`}
            >
              <div className="min-w-0 pr-3">
                <div className="flex items-center gap-1.5">
                  <span
                    className={`text-[10px] font-bold px-1.5 py-0.5 rounded font-mono ${selectedSettlementReq.paid_by === "landlord"
                      ? "bg-amber-100 text-amber-800"
                      : "bg-blue-100 text-blue-800"
                      }`}
                  >
                    {selectedSettlementReq.ticket_number}
                  </span>
                  <p className="text-xs font-bold text-slate-800 truncate">
                    {selectedSettlementReq.title}
                  </p>
                </div>
                <p className="text-[11px] text-slate-500 font-medium mt-0.5">
                  {selectedSettlementReq.paid_by === "tenant"
                    ? t("agency_maint_landlord_debt_sub")
                    : t("agency_maint_tenant_debt_sub")}
                </p>
              </div>
              <div className="text-right shrink-0">
                <span className="text-xs text-slate-400 block font-semibold">{t("agency_maint_modal_cost_amount_label")}</span>
                <span
                  className={`text-sm font-extrabold font-mono ${selectedSettlementReq.paid_by === "landlord"
                    ? "text-amber-700"
                    : "text-blue-700"
                    }`}
                >
                  {selectedSettlementReq.paid_by === "landlord" ? "+ " : "- "}
                  {Math.max(
                    0,
                    (selectedSettlementReq.cost_amount || 0) -
                    (selectedSettlementReq.settled_amount || 0)
                  ).toLocaleString()}{" "}
                  {selectedSettlementReq.currency || selectedPropertyDrawer.currency || "EUR"}
                </span>
              </div>
            </div>

            {/* Error Alert if any */}
            {offsetError && (
              <div className="p-3 bg-red-50 border border-red-200 rounded-xl text-xs text-red-700 flex items-center gap-2 shrink-0">
                <AlertCircle className="w-4 h-4 shrink-0" />
                <span>{offsetError}</span>
              </div>
            )}

            {/* Eligible Payments & Counterparty Maintenance List */}
            <div className="flex-1 overflow-y-auto space-y-2.5 pr-1">
              {(() => {
                const propPayments = payments.filter(
                  (pay) => pay.property_id === selectedPropertyDrawer.id
                );
                const eligiblePayments = getEligibleRentPaymentsForOffset(
                  propPayments,
                  selectedPropertyDrawer.id,
                  selectedSettlementReq.currency,
                  selectedPropertyDrawer.currency
                );

                const eligibleCounterparty = getEligibleCounterpartyMaintenance(
                  maintenanceRequests,
                  selectedSettlementReq,
                  selectedPropertyDrawer.id,
                  selectedPropertyDrawer.currency
                );

                if (eligiblePayments.length === 0 && eligibleCounterparty.length === 0) {
                  return (
                    <div className="p-6 text-center bg-slate-50 rounded-xl border border-slate-200">
                      <Receipt className="w-8 h-8 text-slate-300 mx-auto mb-2" />
                      <p className="text-xs font-semibold text-slate-600">
                        {t("agency_maint_no_eligible_rent")}
                      </p>
                    </div>
                  );
                }

                const isAddToRent =
                  selectedSettlementReq.paid_by === "landlord" ||
                  (selectedSettlementReq.paid_by === "agency" && selectedSettlementReq.declaration_intent === "damage_tenant");
                const reqCost = selectedSettlementReq.cost_amount || 0;
                const reqSettled = selectedSettlementReq.settled_amount || 0;
                const activeRemaining = Math.max(0, reqCost - reqSettled);

                return (
                  <div className="space-y-4">
                    {/* 1. Rent & Utility Payments */}
                    {eligiblePayments.length > 0 && (
                      <div className="space-y-2">
                        {eligibleCounterparty.length > 0 && (
                          <p className="text-[10px] font-extrabold text-slate-500 uppercase tracking-wider px-1">
                            {t("rentAndBillsHeader")}
                          </p>
                        )}
                        {eligiblePayments.map((pay) => {
                          const offsetAmt = isAddToRent
                            ? activeRemaining
                            : Math.min(activeRemaining, pay.amount);
                          const paymentNewAmount = isAddToRent
                            ? pay.amount + offsetAmt
                            : Math.max(0, pay.amount - offsetAmt);
                          const remainingCredit = Math.max(0, activeRemaining - offsetAmt);
                          const monthLabel = pay.due_date ? pay.due_date.slice(0, 7) : "";

                          return (
                            <div
                              key={pay.id}
                              className="p-3.5 bg-slate-50/70 hover:bg-slate-100/70 rounded-xl border border-slate-200 transition-colors flex items-center justify-between gap-3"
                            >
                              <div className="min-w-0 flex items-center gap-3">
                                <div
                                  className={`w-8 h-8 rounded-lg flex items-center justify-center shrink-0 ${isAddToRent
                                    ? "bg-amber-100/70 text-amber-700"
                                    : "bg-blue-100/70 text-blue-700"
                                    }`}
                                >
                                  {isAddToRent ? (
                                    <ArrowUpRight className="w-4 h-4" />
                                  ) : (
                                    <Receipt className="w-4 h-4" />
                                  )}
                                </div>
                                <div className="min-w-0">
                                  <div className="flex items-center gap-1.5 flex-wrap">
                                    <span className="text-xs font-bold text-slate-800">
                                      {pay.title || t("agency_chip_rent")}
                                    </span>
                                    {monthLabel && (
                                      <span className="text-[10px] font-semibold text-slate-500 font-mono">
                                        ({monthLabel})
                                      </span>
                                    )}
                                  </div>

                                  <div className="flex items-center gap-1.5 mt-1 text-xs">
                                    <span
                                      className={`font-mono text-slate-400 ${!isAddToRent && paymentNewAmount <= 0 ? "line-through" : ""
                                        }`}
                                    >
                                      {pay.amount.toLocaleString()} {pay.currency}
                                    </span>
                                    <ArrowRight className="w-3 h-3 text-slate-400" />
                                    <span
                                      className={`font-mono font-bold ${isAddToRent
                                        ? "text-amber-700"
                                        : paymentNewAmount <= 0
                                          ? "text-emerald-600"
                                          : "text-blue-700"
                                        }`}
                                    >
                                      {!isAddToRent && paymentNewAmount <= 0
                                        ? t("agency_maint_offset_paid_full", { cur: pay.currency })
                                        : `${paymentNewAmount.toLocaleString()} ${pay.currency}`}
                                    </span>
                                  </div>

                                  <p
                                    className={`text-[11px] font-medium mt-1 ${isAddToRent ? "text-amber-700/90" : "text-blue-600/90"
                                      }`}
                                  >
                                    {isAddToRent
                                      ? t("agency_maint_offset_subtitle_add", {
                                        offset: `${offsetAmt.toLocaleString()} ${pay.currency}`,
                                        newAmount: `${paymentNewAmount.toLocaleString()} ${pay.currency}`,
                                      })
                                      : remainingCredit > 0
                                        ? t("agency_maint_offset_subtitle_partial", {
                                          offset: `${offsetAmt.toLocaleString()} ${pay.currency}`,
                                          remaining: `${remainingCredit.toLocaleString()} ${pay.currency}`,
                                        })
                                        : t("agency_maint_offset_subtitle_full", {
                                          offset: `${offsetAmt.toLocaleString()} ${pay.currency}`,
                                        })}
                                  </p>
                                </div>
                              </div>

                              <button
                                type="button"
                                disabled={isExecutingOffset}
                                onClick={() => handleConfirmOffset(pay)}
                                className={`px-3.5 py-2 rounded-xl text-xs font-bold text-white transition-colors shadow-2xs cursor-pointer disabled:opacity-50 shrink-0 flex items-center gap-1 ${isAddToRent
                                  ? "bg-amber-600 hover:bg-amber-700"
                                  : "bg-[#1B5888] hover:bg-blue-700"
                                  }`}
                              >
                                {isExecutingOffset ? (
                                  <RefreshCw className="w-3.5 h-3.5 animate-spin" />
                                ) : (
                                  <span>
                                    {isAddToRent
                                      ? t("agency_maint_btn_add_rent")
                                      : t("agency_maint_btn_deduct_rent")}
                                  </span>
                                )}
                              </button>
                            </div>
                          );
                        })}
                      </div>
                    )}

                    {/* 2. Counterparty Maintenance Debts / Credits */}
                    {eligibleCounterparty.length > 0 && (
                      <div className="space-y-2 pt-1">
                        <p className="text-[10px] font-extrabold text-slate-500 uppercase tracking-wider px-1">
                          {isAddToRent
                            ? t("tenantMaintenanceCreditsHeader")
                            : t("tenantMaintenanceDebtsHeader")}
                        </p>
                        {eligibleCounterparty.map((m) => {
                          const costAmt = activeRemaining;
                          const otherAmt = Math.max(0, (m.cost_amount || 0) - (m.settled_amount || 0));
                          const mCurrency = m.currency || selectedSettlementReq.currency || "EUR";
                          const offsetAmt = Math.min(costAmt, otherAmt);
                          const remainingCredit = Math.max(0, costAmt - offsetAmt);
                          const otherNewAmount = Math.max(0, otherAmt - offsetAmt);

                          return (
                            <div
                              key={m.id}
                              className="p-3.5 bg-slate-50/70 hover:bg-slate-100/70 rounded-xl border border-slate-200 transition-colors flex items-center justify-between gap-3"
                            >
                              <div className="min-w-0 flex items-center gap-3">
                                <div className="w-8 h-8 rounded-lg bg-amber-100/80 text-amber-700 flex items-center justify-center shrink-0">
                                  <Wrench className="w-4 h-4" />
                                </div>
                                <div className="min-w-0">
                                  <div className="flex items-center gap-1.5 flex-wrap">
                                    <span className="text-xs font-bold text-slate-800">
                                      {m.ticket_number}: {m.title}
                                    </span>
                                  </div>

                                  <div className="flex items-center gap-1.5 mt-1 text-xs">
                                    <span
                                      className={`font-mono text-slate-400 ${otherNewAmount <= 0 ? "line-through" : ""
                                        }`}
                                    >
                                      {otherAmt.toLocaleString()} {mCurrency}
                                    </span>
                                    <ArrowRight className="w-3 h-3 text-slate-400" />
                                    <span
                                      className={`font-mono font-bold ${otherNewAmount <= 0
                                        ? "text-emerald-600"
                                        : "text-amber-700"
                                        }`}
                                    >
                                      {otherNewAmount <= 0
                                        ? t("agency_maint_offset_paid_full", { cur: mCurrency })
                                        : `${otherNewAmount.toLocaleString()} ${mCurrency}`}
                                    </span>
                                  </div>

                                  <p className="text-[11px] font-medium mt-1 text-amber-700/90">
                                    {remainingCredit > 0
                                      ? t("agency_maint_offset_subtitle_partial", {
                                        offset: `${offsetAmt.toLocaleString()} ${mCurrency}`,
                                        remaining: `${remainingCredit.toLocaleString()} ${mCurrency}`,
                                      })
                                      : t("agency_maint_offset_subtitle_full", {
                                        offset: `${offsetAmt.toLocaleString()} ${mCurrency}`,
                                      })}
                                  </p>
                                </div>
                              </div>

                              <button
                                type="button"
                                disabled={isExecutingOffset}
                                onClick={() => handleConfirmMaintenanceCrossOffset(m)}
                                className="px-3.5 py-2 rounded-xl text-xs font-bold text-white bg-amber-600 hover:bg-amber-700 transition-colors shadow-2xs cursor-pointer disabled:opacity-50 shrink-0 flex items-center gap-1"
                              >
                                {isExecutingOffset ? (
                                  <RefreshCw className="w-3.5 h-3.5 animate-spin" />
                                ) : (
                                  <span>{t("agency_maint_btn_deduct_rent")}</span>
                                )}
                              </button>
                            </div>
                          );
                        })}
                      </div>
                    )}
                  </div>
                );
              })()}
            </div>

            {/* Modal Footer */}
            <div className="flex items-center justify-end pt-3 border-t border-slate-100 shrink-0">
              <button
                type="button"
                disabled={isExecutingOffset}
                onClick={() => {
                  setIsOffsetModalOpen(false);
                  setSelectedSettlementReq(null);
                  setOffsetError(null);
                }}
                className="px-4 py-2 rounded-xl text-xs font-bold text-slate-600 hover:bg-slate-100 transition-colors cursor-pointer"
              >
                {t("agency_panel_cancel_btn")}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Settlement Options Sheet (Flutter _showLandlordSettlementSheet Parity) */}
      {isSettlementOptionsModalOpen && settlementOptionsReq && selectedPropertyDrawer && (() => {
        const isAddToRent =
          settlementOptionsReq.paid_by === "landlord" ||
          (settlementOptionsReq.paid_by === "agency" && settlementOptionsReq.declaration_intent === "damage_tenant");
        const costAmt = Math.max(
          0,
          (settlementOptionsReq.cost_amount || 0) - (settlementOptionsReq.settled_amount || 0)
        );
        const cur = settlementOptionsReq.currency || selectedPropertyDrawer.currency || "EUR";
        const formattedCost = `${costAmt.toLocaleString()} ${cur}`;

        return (
          <div
            className="fixed inset-0 bg-black/50 backdrop-blur-xs flex items-center justify-center p-4 z-50 animate-in fade-in duration-200"
            onClick={() => {
              setIsSettlementOptionsModalOpen(false);
              setSettlementOptionsReq(null);
            }}
          >
            <div
              className="bg-white rounded-2xl max-w-md w-full p-6 shadow-2xl space-y-4 animate-in zoom-in-95 duration-200"
              onClick={(e) => e.stopPropagation()}
            >
              {/* Header */}
              <div className="flex items-start justify-between">
                <div className="flex items-center gap-3">
                  <div
                    className={`w-10 h-10 rounded-xl flex items-center justify-center shrink-0 ${isAddToRent ? "bg-amber-100 text-amber-700" : "bg-blue-100 text-[#1B5888]"
                      }`}
                  >
                    {isAddToRent ? (
                      <ArrowUpRight className="w-5 h-5" />
                    ) : (
                      <ArrowDownLeft className="w-5 h-5" />
                    )}
                  </div>
                  <div>
                    <h3 className="text-base font-bold text-[#0F172A]">
                      {isAddToRent ? t("settleAddToRentTitle") : t("settleExpenseTitle")}
                    </h3>
                    <p className="text-xs text-slate-500 mt-0.5">
                      {isAddToRent
                        ? t("addTenantDebtToRentSub", { cost: formattedCost })
                        : `${formattedCost} - ${t("settleExpenseSub")}`}
                    </p>
                  </div>
                </div>
                <button
                  type="button"
                  onClick={() => {
                    setIsSettlementOptionsModalOpen(false);
                    setSettlementOptionsReq(null);
                  }}
                  className="text-slate-400 hover:text-slate-600 p-1.5 rounded-lg hover:bg-slate-100 transition-colors cursor-pointer"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>

              {/* Options List */}
              <div className="space-y-2.5 pt-1">
                {/* Option 1: Add to Upcoming Rent / Deduct from Rent */}
                <div
                  onClick={() => {
                    const req = settlementOptionsReq;
                    setIsSettlementOptionsModalOpen(false);
                    setSelectedSettlementReq(req);
                    setOffsetError(null);
                    setIsOffsetModalOpen(true);
                  }}
                  className="p-3.5 bg-slate-50 hover:bg-slate-100/80 rounded-xl border border-slate-200/80 transition-all cursor-pointer flex items-center justify-between group"
                >
                  <div className="flex items-center gap-3 min-w-0 pr-2">
                    <div
                      className={`w-9 h-9 rounded-lg flex items-center justify-center shrink-0 ${isAddToRent ? "bg-amber-100/80 text-amber-700" : "bg-blue-100/80 text-blue-700"
                        }`}
                    >
                      {isAddToRent ? (
                        <ArrowUpRight className="w-4 h-4" />
                      ) : (
                        <Layers className="w-4 h-4" />
                      )}
                    </div>
                    <div className="min-w-0">
                      <h4 className="text-xs font-bold text-slate-800">
                        {isAddToRent ? t("settleOptAddUpcomingRent") : t("optionOffsetFromRent")}
                      </h4>
                      <p className="text-[11px] text-slate-500 mt-0.5 truncate">
                        {isAddToRent ? t("settleOptAddUpcomingRentDesc") : t("optionOffsetFromRentDesc")}
                      </p>
                    </div>
                  </div>
                  <ChevronRight className="w-4 h-4 text-slate-400 group-hover:text-slate-600 shrink-0" />
                </div>

                {/* Option 2: Bank Transfer */}
                <div
                  onClick={() => {
                    setIsSettlementOptionsModalOpen(false);
                    setDirectSettlementMethod("bank");
                    setDirectSettlementNote("");
                    setDirectSettlementFile(null);
                    setIsDirectSettlementModalOpen(true);
                  }}
                  className="p-3.5 bg-slate-50 hover:bg-slate-100/80 rounded-xl border border-slate-200/80 transition-all cursor-pointer flex items-center justify-between group"
                >
                  <div className="flex items-center gap-3 min-w-0 pr-2">
                    <div className="w-9 h-9 rounded-lg bg-emerald-100/80 text-emerald-700 flex items-center justify-center shrink-0">
                      <FileUp className="w-4 h-4" />
                    </div>
                    <div className="min-w-0">
                      <h4 className="text-xs font-bold text-slate-800">
                        {isAddToRent ? t("settleOptBankTransferCollected") : t("optionBankTransfer")}
                      </h4>
                      <p className="text-[11px] text-slate-500 mt-0.5 truncate">
                        {isAddToRent ? t("settleOptBankTransferCollectedDesc") : t("optionBankTransferDesc")}
                      </p>
                    </div>
                  </div>
                  <ChevronRight className="w-4 h-4 text-slate-400 group-hover:text-slate-600 shrink-0" />
                </div>

                {/* Option 3: Cash */}
                <div
                  onClick={() => {
                    setIsSettlementOptionsModalOpen(false);
                    setDirectSettlementMethod("cash");
                    setDirectSettlementNote("");
                    setDirectSettlementFile(null);
                    setIsDirectSettlementModalOpen(true);
                  }}
                  className="p-3.5 bg-slate-50 hover:bg-slate-100/80 rounded-xl border border-slate-200/80 transition-all cursor-pointer flex items-center justify-between group"
                >
                  <div className="flex items-center gap-3 min-w-0 pr-2">
                    <div className="w-9 h-9 rounded-lg bg-amber-100/80 text-amber-700 flex items-center justify-center shrink-0">
                      <Hand className="w-4 h-4" />
                    </div>
                    <div className="min-w-0">
                      <h4 className="text-xs font-bold text-slate-800">
                        {isAddToRent ? t("settleOptCashCollected") : t("optionCashPayment")}
                      </h4>
                      <p className="text-[11px] text-slate-500 mt-0.5 truncate">
                        {isAddToRent ? t("settleOptCashCollectedDesc") : t("optionCashPaymentDesc")}
                      </p>
                    </div>
                  </div>
                  <ChevronRight className="w-4 h-4 text-slate-400 group-hover:text-slate-600 shrink-0" />
                </div>
              </div>

              <div className="pt-2 flex justify-end">
                <button
                  type="button"
                  onClick={() => {
                    setIsSettlementOptionsModalOpen(false);
                    setSettlementOptionsReq(null);
                  }}
                  className="px-4 py-2 rounded-xl text-xs font-bold text-slate-600 hover:bg-slate-100 transition-colors cursor-pointer"
                >
                  {t("agency_panel_cancel_btn")}
                </button>
              </div>
            </div>
          </div>
        );
      })()}

      {/* Direct Settlement Modal (Bank Transfer or Cash Confirmation) */}
      {isDirectSettlementModalOpen && settlementOptionsReq && selectedPropertyDrawer && (() => {
        const isCash = directSettlementMethod === "cash";
        const costAmt = settlementOptionsReq.cost_amount || 0;
        const cur = settlementOptionsReq.currency || selectedPropertyDrawer.currency || "EUR";

        return (
          <div
            className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/40 backdrop-blur-xs animate-in fade-in duration-200"
            onClick={() => {
              if (!isExecutingDirectSettlement) {
                setIsDirectSettlementModalOpen(false);
                setSettlementOptionsReq(null);
              }
            }}
          >
            <div
              className="bg-white rounded-2xl shadow-2xl border border-slate-200/80 w-full max-w-md overflow-hidden animate-in zoom-in-95 duration-200"
              onClick={(e) => e.stopPropagation()}
            >
              <div className="p-5 border-b border-slate-100 flex items-center justify-between">
                <div className="flex items-center gap-2.5">
                  <div
                    className={`w-9 h-9 rounded-xl flex items-center justify-center ${isCash ? "bg-amber-100 text-amber-700" : "bg-emerald-100 text-emerald-700"
                      }`}
                  >
                    {isCash ? <Hand className="w-5 h-5" /> : <FileUp className="w-5 h-5" />}
                  </div>
                  <div>
                    <h3 className="font-bold text-slate-800 text-sm">
                      {isCash ? t("settleOptCashCollected") : t("settleOptBankTransferCollected")}
                    </h3>
                    <p className="text-[11px] text-slate-500 font-medium">
                      {settlementOptionsReq.ticket_number} • {costAmt.toLocaleString()} {cur}
                    </p>
                  </div>
                </div>
                <button
                  type="button"
                  disabled={isExecutingDirectSettlement}
                  onClick={() => {
                    setIsDirectSettlementModalOpen(false);
                    setSettlementOptionsReq(null);
                  }}
                  className="p-1.5 rounded-lg text-slate-400 hover:text-slate-600 hover:bg-slate-100 transition-colors cursor-pointer"
                >
                  <X className="w-4 h-4" />
                </button>
              </div>

              <div className="p-5 space-y-4">
                {!isCash && (
                  <div>
                    <label className="block text-xs font-semibold text-slate-700 mb-1.5">
                      {t("directSettlementReceiptUpload")}
                    </label>
                    <input
                      type="file"
                      accept="image/*,application/pdf"
                      onChange={(e) => {
                        if (e.target.files && e.target.files.length > 0) {
                          setDirectSettlementFile(e.target.files[0]);
                        }
                      }}
                      className="w-full text-xs text-slate-600 file:mr-3 file:py-2 file:px-3.5 file:rounded-xl file:border-0 file:text-xs file:font-bold file:bg-emerald-50 file:text-emerald-700 hover:file:bg-emerald-100 cursor-pointer"
                    />
                  </div>
                )}

                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1.5">
                    {t("noteOptional")}
                  </label>
                  <textarea
                    rows={3}
                    value={directSettlementNote}
                    onChange={(e) => setDirectSettlementNote(e.target.value)}
                    placeholder={t("directSettlementNotePlaceholder")}
                    className="w-full text-xs rounded-xl border border-slate-200 p-3 focus:outline-hidden focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 resize-none"
                  />
                </div>
              </div>

              <div className="p-4 bg-slate-50 border-t border-slate-100 flex items-center justify-end gap-2">
                <button
                  type="button"
                  disabled={isExecutingDirectSettlement}
                  onClick={() => {
                    setIsDirectSettlementModalOpen(false);
                    setSettlementOptionsReq(null);
                  }}
                  className="px-4 py-2 rounded-xl text-xs font-bold text-slate-600 hover:bg-slate-200/60 transition-colors cursor-pointer"
                >
                  {t("agency_panel_cancel_btn")}
                </button>
                <button
                  type="button"
                  disabled={isExecutingDirectSettlement}
                  onClick={handleConfirmDirectSettlement}
                  className={`px-4 py-2 rounded-xl text-xs font-bold text-white transition-colors shadow-2xs disabled:opacity-50 flex items-center gap-1.5 cursor-pointer ${isCash
                    ? "bg-amber-600 hover:bg-amber-700"
                    : "bg-emerald-600 hover:bg-emerald-700"
                    }`}
                >
                  {isExecutingDirectSettlement ? (
                    <RefreshCw className="w-3.5 h-3.5 animate-spin" />
                  ) : (
                    <span>{t("confirmAndSettle")}</span>
                  )}
                </button>
              </div>
            </div>
          </div>
        );
      })()}

      {/* Reject Settlement Expense Declaration Modal */}
      {rejectingSettlementReq && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/40 backdrop-blur-xs animate-in fade-in duration-200"
          onClick={() => {
            if (!isExecutingSettlementAction) {
              setRejectingSettlementReq(null);
              setSettlementRejectReason("");
            }
          }}
        >
          <div
            className="bg-white rounded-2xl shadow-2xl border border-slate-200/80 w-full max-w-md overflow-hidden animate-in zoom-in-95 duration-200"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="p-5 border-b border-slate-100 flex items-center justify-between">
              <div className="flex items-center gap-2.5">
                <div className="w-9 h-9 rounded-xl bg-rose-50 flex items-center justify-center text-rose-600">
                  <X className="w-5 h-5" />
                </div>
                <div>
                  <h3 className="font-bold text-slate-800 text-sm">
                    {t("rejectExpenseTitle")}
                  </h3>
                  <p className="text-[11px] text-slate-500 font-medium">
                    {rejectingSettlementReq.ticket_number} • {(rejectingSettlementReq.cost_amount || 0).toLocaleString()} {rejectingSettlementReq.currency || "EUR"}
                  </p>
                </div>
              </div>
              <button
                type="button"
                disabled={isExecutingSettlementAction}
                onClick={() => {
                  setRejectingSettlementReq(null);
                  setSettlementRejectReason("");
                }}
                className="p-1.5 rounded-lg text-slate-400 hover:text-slate-600 hover:bg-slate-100 transition-colors"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <div className="p-5 space-y-4">
              <p className="text-xs text-slate-600">
                {t("rejectExpenseDeclarationDesc")}
              </p>

              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1.5">
                  {t("agency_maint_reject_reason_label")} *
                </label>
                <textarea
                  rows={3}
                  value={settlementRejectReason}
                  onChange={(e) => setSettlementRejectReason(e.target.value)}
                  placeholder={t("agency_maint_reject_reason_placeholder")}
                  className="w-full text-xs rounded-xl border border-slate-200 p-3 focus:outline-hidden focus:ring-2 focus:ring-rose-500/20 focus:border-rose-500 resize-none"
                />
              </div>
            </div>

            <div className="p-4 bg-slate-50 border-t border-slate-100 flex items-center justify-end gap-2">
              <button
                type="button"
                disabled={isExecutingSettlementAction}
                onClick={() => {
                  setRejectingSettlementReq(null);
                  setSettlementRejectReason("");
                }}
                className="px-4 py-2 rounded-xl text-xs font-bold text-slate-600 hover:bg-slate-200/60 transition-colors cursor-pointer"
              >
                {t("agency_panel_cancel_btn")}
              </button>
              <button
                type="button"
                disabled={!settlementRejectReason.trim() || isExecutingSettlementAction}
                onClick={handleRejectSettlement}
                className="px-4 py-2 rounded-xl text-xs font-bold bg-rose-600 text-white hover:bg-rose-700 transition-colors shadow-2xs disabled:opacity-50 flex items-center gap-1.5 cursor-pointer"
              >
                {isExecutingSettlementAction ? (
                  <RefreshCw className="w-3.5 h-3.5 animate-spin" />
                ) : (
                  <span>{t("rejectExpenseTitle")}</span>
                )}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ── LIFECYCLE BRIDGE MODAL: Re-List / Update Linked Portfolio Listing ── */}
      {relistPropertyTarget && (() => {
        const linkedListing = findLinkedListing(relistPropertyTarget);
        return (
          <div
            className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/50 backdrop-blur-xs animate-in fade-in duration-200"
            onClick={() => {
              if (!isSubmittingRelist) setRelistPropertyTarget(null);
            }}
          >
            <div
              className="bg-white rounded-2xl border border-slate-200 shadow-2xl max-w-lg w-full p-6 space-y-5 animate-in zoom-in-95 duration-150"
              onClick={(e) => e.stopPropagation()}
            >
              {/* Header */}
              <div className="flex items-start justify-between gap-3 border-b border-slate-100 pb-4">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-xl bg-blue-50 text-[#1B5888] flex items-center justify-center shrink-0">
                    <PlusCircle className="w-5 h-5" />
                  </div>
                  <div>
                    <div className="flex items-center gap-2 flex-wrap">
                      <h3 className="text-base font-bold text-slate-900">
                        {t("agency_bridge_relist_modal_title")}
                      </h3>
                      <span
                        className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${linkedListing
                            ? "bg-emerald-100 text-emerald-800"
                            : "bg-blue-100 text-[#1B5888]"
                          }`}
                      >
                        {linkedListing
                          ? t("agency_bridge_relist_found_badge")
                          : t("agency_bridge_relist_new_badge")}
                      </span>
                    </div>
                    <p className="text-xs text-slate-500 mt-1 leading-relaxed">
                      {linkedListing
                        ? t("agency_bridge_relist_modal_sub_existing")
                        : t("agency_bridge_relist_modal_sub_new")}
                    </p>
                  </div>
                </div>
                <button
                  type="button"
                  disabled={isSubmittingRelist}
                  onClick={() => setRelistPropertyTarget(null)}
                  className="p-1.5 rounded-lg text-slate-400 hover:text-slate-700 hover:bg-slate-100 transition-colors cursor-pointer"
                >
                  <X className="w-4 h-4" />
                </button>
              </div>

              {hasPortfolioModule ? (
                <div className="space-y-4">
                  {/* Property Summary Card */}
                  <div className="p-3.5 rounded-xl bg-slate-50 border border-slate-200/80 text-xs space-y-1">
                    <div className="flex items-center justify-between gap-2">
                      <span className="font-bold text-slate-900">{relistPropertyTarget.title}</span>
                      {relistPropertyTarget.city && (
                        <span className="text-[11px] font-semibold px-2 py-0.5 rounded bg-[#E5EEF6] text-[#1B5888]">
                          {relistPropertyTarget.city}
                        </span>
                      )}
                    </div>
                    <p className="text-slate-500">{relistPropertyTarget.address}</p>
                    <div className="flex items-center gap-3 pt-1 text-[11px] text-slate-600 font-medium">
                      {relistPropertyTarget.area_sqm && <span>{relistPropertyTarget.area_sqm} m²</span>}
                      {relistPropertyTarget.room_count && (
                        <span>• {relistPropertyTarget.room_count} {t("agency_panel_unit_rooms")}</span>
                      )}
                      {relistPropertyTarget.floor && (
                        <span>• {relistPropertyTarget.floor}. {t("agency_panel_unit_floor")}</span>
                      )}
                    </div>
                  </div>

                  <div>
                    <label className="text-xs font-bold text-slate-700 block mb-1">
                      {t("agency_bridge_relist_title_label")}
                    </label>
                    <input
                      type="text"
                      value={relistTitle}
                      onChange={(e) => setRelistTitle(e.target.value)}
                      className="w-full text-xs font-semibold rounded-xl border border-slate-200 px-3 py-2.5 text-slate-900 focus:outline-hidden focus:border-[#1B5888]"
                    />
                  </div>

                  <div className="grid grid-cols-3 gap-3">
                    <div className="col-span-2">
                      <label className="text-xs font-bold text-slate-700 block mb-1">
                        {t("agency_bridge_relist_price_label")}
                      </label>
                      <input
                        type="number"
                        step="1"
                        value={relistPrice}
                        onChange={(e) => setRelistPrice(e.target.value)}
                        className="w-full text-xs font-semibold rounded-xl border border-slate-200 px-3 py-2.5 text-slate-900 focus:outline-hidden focus:border-[#1B5888]"
                      />
                    </div>
                    <div>
                      <label className="text-xs font-bold text-slate-700 block mb-1">
                        {t("agency_invoice_field_currency")}
                      </label>
                      <select
                        value={relistCurrency}
                        onChange={(e) => setRelistCurrency(e.target.value)}
                        className="w-full text-xs font-semibold rounded-xl border border-slate-200 px-3 py-2.5 text-slate-900 bg-white focus:outline-hidden focus:border-[#1B5888]"
                      >
                        <option value="EUR">EUR</option>
                        <option value="RSD">RSD</option>
                      </select>
                    </div>
                  </div>

                  <div className="flex flex-col sm:flex-row items-stretch sm:items-center justify-end gap-2.5 pt-3 border-t border-slate-100">
                    <button
                      type="button"
                      disabled={isSubmittingRelist}
                      onClick={() => handleConfirmRelist("open_form")}
                      className="px-4 py-2.5 rounded-xl text-xs font-bold border border-slate-300 text-slate-700 hover:bg-slate-50 transition-colors cursor-pointer"
                    >
                      {t("agency_bridge_relist_btn_open_form")}
                    </button>
                    <button
                      type="button"
                      disabled={isSubmittingRelist}
                      onClick={() => handleConfirmRelist("instant_publish")}
                      className="px-4 py-2.5 rounded-xl text-xs font-bold bg-[#1B5888] hover:bg-[#12406A] text-white shadow-xs transition-colors cursor-pointer inline-flex items-center justify-center gap-1.5"
                    >
                      <CheckCircle2 className="w-4 h-4" />
                      <span>
                        {isSubmittingRelist ? "..." : t("agency_bridge_relist_btn_instant")}
                      </span>
                    </button>
                  </div>
                </div>
              ) : (
                <div className="space-y-4">
                  <div className="rounded-xl border border-amber-200 bg-amber-50/70 p-4 space-y-2">
                    <p className="text-xs font-bold text-amber-900">
                      {t("agency_bridge_portfolio_upsell_title")}
                    </p>
                    <p className="text-[11px] text-amber-800 leading-relaxed">
                      {t("agency_bridge_portfolio_upsell_desc")}
                    </p>
                  </div>
                  <div className="flex items-center justify-end gap-2 pt-2 border-t border-slate-100">
                    <button
                      type="button"
                      onClick={() => setRelistPropertyTarget(null)}
                      className="px-4 py-2 rounded-xl text-xs font-bold text-slate-600 hover:bg-slate-100 transition-colors cursor-pointer"
                    >
                      {t("agency_panel_cancel_btn")}
                    </button>
                    {setActiveTab && (
                      <button
                        type="button"
                        onClick={() => {
                          setRelistPropertyTarget(null);
                          setActiveTab("account_settings");
                        }}
                        className="px-4 py-2 rounded-xl text-xs font-bold bg-[#1B5888] text-white hover:bg-[#12406A] transition-colors cursor-pointer"
                      >
                        {t("agency_account_menu_label")}
                      </button>
                    )}
                  </div>
                </div>
              )}
            </div>
          </div>
        );
      })()}
    </div>
  );
}