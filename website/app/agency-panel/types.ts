export interface DirectoryAgencyMatch {
  id: number;
  acente_adi: string;
  sehir?: string | null;
  web_sitesi?: string | null;
  telefonlar?: string | null;
  eposta_adresleri?: string | null;
}

export interface ListingImageRow {
  id?: string;
  url: string;
  order_index: number;
  is_cover: boolean;
}

export interface AgencyListingRow {
  id: string;
  agency_id: string | null;
  managed_property_id?: string | null;
  external_ref: string | null;
  title: string | null;
  description: string | null;
  transaction_type: string | null;
  property_type: string | null;
  price: number | null;
  deposit_amount?: number | null;
  currency: string | null;
  area_sqm: number | null;
  room_count: string | null;
  floor: string | null;
  total_floors: number | null;
  heating_type: string | null;
  condition: string | null;
  furnishing: string | null;
  city: string | null;
  municipality: string | null;
  neighborhood: string | null;
  address: string | null;
  amenities: string[] | null;
  is_published: boolean;
  listing_status?: "active" | "reserved" | "rented" | "sold" | "archived";
  closed_at?: string | null;
  closing_price?: number | null;
  closing_notes?: string | null;
  closing_contract_id?: string | null;
  published_portals: string[] | null;
  created_at?: string;
  listing_images?: ListingImageRow[];
}

export interface PortalDef {
  id: string;
  name: string;
  file?: string;
  badgeColor: string;
  status: "live" | "on_demand";
  noteKey: string;
}

export interface PortalFeedLogRow {
  id: string;
  portal: string;
  ip_address: string | null;
  user_agent: string | null;
  listing_count: number;
  status_code: number;
  duration_ms: number | null;
  created_at: string;
}

export interface LeadComment {
  id: string;
  author_name: string;
  text: string;
  created_at: string;
}

export type LeadType = "owner_consignment" | "viewing_request" | "general_inquiry";

export type ShowcaseTemplate =
  | "stanomer_modern"
  | "quiet_luxury"
  | "minimal_light"
  | "kolm_dark"
  | "lumira"
  | "aldervik"
  | "sage"
  | "onyx_dark";

export type ShowcasePalette =
  | "royal_blue"
  | "champagne_gold"
  | "emerald_prestige"
  | "burgundy_classic"
  | "kolm_mint"
  | "lumira_coral"
  | "aldervik_amber"
  | "sage_terracotta"
  | "onyx_brass";

export type ShowcaseRadius = "sharp" | "subtle" | "rounded" | "pill";
export type ContactChannels = "both" | "whatsapp" | "viber" | "none";

export type LeadStatus =
  | "new"
  | "contacted"
  | "evaluation"
  | "viewing_scheduled"
  | "offer_made"
  | "contract_signed"
  | "converted"
  | "archived";

export interface AgencyLead {
  id: string;
  agency_id: string;
  lead_type: LeadType;
  status: LeadStatus;
  client_name: string;
  client_phone: string;
  client_email?: string | null;
  transaction_type?: "prodaja" | "izdavanje";
  property_type?: string;
  location?: string | null;
  area_sqm?: number | null;
  expected_price?: number | null;
  currency?: string;
  notes?: string | null;
  listing_id?: string | null;
  listing_title?: string | null;
  agent_notes?: string | null;
  comments?: LeadComment[];
  created_at: string;
}

export type KanbanColId =
  | "incoming"
  | "in_progress"
  | "scheduled"
  | "closed_won"
  | "archived";

export interface AgencyRentPayment {
  id: string;
  agency_id?: string;
  property_id: string;
  contract_id?: string | null;
  tenant_id?: string | null;
  landlord_id?: string | null;
  property_title?: string;
  property_address?: string;
  property_city?: string | null;
  landlord_name?: string | null;
  landlord_email?: string | null;
  tenant_name?: string;
  tenant_phone?: string;
  source_table?: "rent_payment" | "maintenance_request";
  title: string;
  raw_title?: string;
  category?: "rent" | "bill" | "maintenance";
  amount: number;
  currency: string;
  due_date: string;
  declared_at?: string | null;
  paid_at?: string | null;
  status: "pending" | "paid" | "disputed" | "overdue" | "cancelled" | "declared" | "pending_payment";
  payment_status?: string | null;
  is_maintenance?: boolean;
  payment_method?: string | null;
  receiver_type?: string | null;
  paid_by?: string | null;
  receipt_url?: string | null;
  owner_note?: string | null;
  dispute_reason?: string | null;
  disputed_at?: string | null;
  invoice_url?: string | null;
  cost_amount?: number | null;
  remaining_amount?: number | null;
  settled_amount?: number | null;
  debtor_id?: string | null;
  is_tenant_debtor?: boolean;
  is_landlord_debtor?: boolean;

  // Pre-calculated KPI Flags (100% SSOT from view_agency_financial_ledger)
  is_pending_approval?: boolean;
  is_unentered_bill?: boolean;
  is_overdue?: boolean;
  is_rent_collected?: boolean;
  is_bills_collected?: boolean;
  is_bills_to_institutions?: boolean;
  is_maintenance_paid?: boolean;
  is_maintenance_owed_to_agency?: boolean;
  is_unpaid_maintenance?: boolean;
  is_unpaid_bills_to_institutions?: boolean;
  is_tenant_offset?: boolean;

  created_at: string;
  updated_at?: string;
}

export interface ContractExpenseItem {
  name: string;
  receiver: "included" | "owner" | "utility" | "unselected";
  amount?: number;
  payment_method?: "bank_transfer" | "cash";
}

export interface ContractAdditionalDocument {
  name: string;
  url: string;
  created_at?: string;
}

export interface TenantSecondaryContact {
  full_name: string;
  relationship: string;
  phone?: string | null;
  email?: string | null;
}

export interface AgencyManagedProperty {
  id: string;
  agency_id: string;
  landlord_id?: string | null;
  tenant_id?: string | null;
  landlord_name?: string | null;
  landlord_phone?: string | null;
  landlord_email?: string | null;
  owners?: any[];
  title: string;
  address: string;
  city?: string | null;
  property_type?: string | null;
  unit_number?: string | null;
  room_count?: string | null;
  area_sqm?: number | null;
  floor?: string | null;
  total_floors?: number | null;
  furnishing?: string | null;
  heating_type?: string | null;
  amenities?: string[];
  description?: string | null;
  is_detailed?: boolean;
  default_monthly_rent?: number | null;
  default_deposit_amount?: number | null;
  currency?: string | null;
  default_deposit_currency?: string | null;
  default_due_day?: number | null;
  expenses_template?: ContractExpenseItem[];
  is_occupied: boolean;
  active_contract_id?: string | null;
  active_tenant_name?: string | null;
  active_tenant_phone?: string | null;
  contract_end_date?: string | null;
  last_listing_id?: string | null;
  created_at: string;
}

export interface AgencyContract {
  id: string;
  property_id: string;
  source_listing_id?: string | null;
  property_title?: string;
  property_address?: string;
  landlord_id?: string | null;
  tenant_id?: string | null;
  agency_id?: string | null;
  invitee_email?: string | null;
  tenant_name?: string | null;
  tenant_phone?: string | null;
  tenant_id_number?: string | null;
  tenant_notes?: string | null;
  tenant_id_document_url?: string | null;
  tenant_secondary_contacts?: TenantSecondaryContact[];
  monthly_rent: number;
  deposit_amount: number;
  currency: string;
  deposit_currency?: string | null;
  due_day: number;
  start_date: string;
  end_date: string;
  status: "active" | "pending" | "expired" | "terminated" | "termination_requested";
  termination_approved?: boolean | null;
  termination_date?: string | null;
  expenses_config?: ContractExpenseItem[];
  contract_url?: string | null;
  additional_documents?: ContractAdditionalDocument[];
  created_at: string;
}

export interface AgencyMaintenanceRequest {
  id: string;
  ticket_number: string;
  property_id: string;
  property_title?: string;
  property_address?: string;
  reporter_id?: string | null;
  reporter_name?: string | null;
  reporter_phone?: string | null;
  title: string;
  description?: string | null;
  category: "plumbing" | "electrical" | "heating" | "appliance" | "appliances" | "other" | "structural" | "internet";
  priority: "low" | "normal" | "high" | "urgent";
  status: "open" | "investigating" | "in_progress" | "resolved" | "closed" | "cancelled" | "pending";
  photos_urls?: string[];
  cost_amount?: number | null;
  settled_amount?: number | null;
  currency?: string;
  paid_by?: "landlord" | "tenant" | "agency" | null;
  payment_status?: string;
  payment_date?: string | null;
  invoice_pdf_url?: string | null;
  rejection_reason?: string | null;
  declaration_intent?: string | null;
  charge_status?: string | null;
  charge_type?: string | null;
  created_at: string;
  updated_at?: string | null;
  resolved_at?: string | null;
}

export interface MaintenanceMessage {
  id: string;
  request_id: string;
  sender_id: string;
  sender_name?: string | null;
  sender_role?: string | null;
  message: string;
  photo_url?: string | null;
  created_at: string;
}

export interface MaintenanceChargeItem {
  id: string;
  maintenance_request_id: string;
  property_id: string;
  title?: string;
  charge_type: "direct_charge" | "agency_advance" | "reimbursement";
  approver_role: "agency" | "counterparty";
  debtor_id?: string | null;
  creditor_id?: string | null;
  amount: number;
  currency: string;
  status: "pending" | "declared" | "disputed" | "approved" | "rejected" | "paid";
  settlement_method?: "separate_payment" | "rent_offset" | null;
  receipt_url?: string | null;
  paid_at?: string | null;
  declared_at?: string | null;
  contractor_payment_date?: string | null;
}

export type AgencyTaskSourceType =
  | "manual"
  | "property"
  | "listing"
  | "lead"
  | "maintenance";

export type AgencyTaskStatus = "todo" | "in_progress" | "done" | "cancelled";
export type AgencyTaskPriority = "low" | "medium" | "high" | "urgent";

export interface AgencyAssigneeOption {
  id: string;
  name: string;
  email: string;
  role: "agency_admin" | "agency_operation";
}

export interface AgencyTaskComment {
  id: string;
  author_id?: string | null;
  author_name: string;
  text: string;
  created_at: string;
  updated_at?: string | null;
}

export interface AgencyTask {
  id: string;
  agency_id: string;
  title: string;
  description?: string | null;
  status: AgencyTaskStatus;
  priority: AgencyTaskPriority;
  due_date?: string | null;
  source_type: AgencyTaskSourceType;
  property_id?: string | null;
  listing_id?: string | null;
  lead_id?: string | null;
  maintenance_request_id?: string | null;
  assigned_to?: string | null;
  created_by?: string | null;
  comments?: AgencyTaskComment[] | null;
  completed_at?: string | null;
  created_at: string;
  updated_at?: string | null;
}

export interface AgencyTaskPrefill {
  source_type: AgencyTaskSourceType;
  title?: string;
  description?: string;
  property_id?: string | null;
  listing_id?: string | null;
  lead_id?: string | null;
  maintenance_request_id?: string | null;
  priority?: AgencyTaskPriority;
}

export type AgencyPanelTab =
  | "welcome"
  | "tasks"
  | "listings"
  | "leads"
  | "form"
  | "xml"
  | "settings"
  | "payments"
  | "pm_dashboard"
  | "managed_properties"
  | "contracts"
  | "maintenance"
  | "account_settings";

export type ShowcaseCurrency = "EUR" | "RSD" | "USD";

export type AgencyMaintStatusFilter =
  | "all"
  | "open"
  | "in_progress"
  | "pending_approval"
  | "resolved";

