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
  | "eop"
  | "aml"
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

export type AgencyPartyType = "individual" | "company";
export type EopStatus = "active" | "realized" | "cancelled";
export type EopClientRole = "seller" | "buyer" | "landlord" | "tenant";
export type EopCommissionType = "percent" | "fixed";

export interface AgencyRegistryInfo {
  registar_posrednika_no?: string | null;
  pib?: string | null;
  maticni_broj?: string | null;
  official_address?: string | null;
  aml_officer_name?: string | null;
  aml_deputy_name?: string | null;
}

export interface AgencyClient {
  id: string;
  agency_id: string;
  party_type: AgencyPartyType;
  full_name: string;
  jmbg_pib?: string | null;
  maticni_broj?: string | null;
  address?: string | null;
  phone?: string | null;
  email?: string | null;
  notes?: string | null;
  created_by?: string | null;
  created_at?: string;
  updated_at?: string;
}

export interface EopRecord {
  id: string;
  agency_id: string;
  sequence_year: number;
  sequence_number: number;
  redni_broj: string;
  mediation_contract_no: string;
  mediation_contract_date: string;
  contract_valid_until?: string | null;
  is_exclusive: boolean;
  client_role: EopClientRole;
  transaction_type: "prodaja" | "izdavanje";
  status: EopStatus;
  cancellation_reason?: string | null;
  client_id?: string | null;
  listing_id?: string | null;
  property_id?: string | null;
  lease_contract_id?: string | null;
  client_type: AgencyPartyType;
  client_name_snapshot: string;
  client_jmbg_pib_snapshot?: string | null;
  client_address_snapshot?: string | null;
  client_phone_snapshot?: string | null;
  client_email_snapshot?: string | null;
  property_type_snapshot?: string | null;
  property_address_snapshot: string;
  property_specs_snapshot?: string | null;
  asking_price?: number | null;
  agreed_price?: number | null;
  currency: string;
  commission_type: EopCommissionType;
  commission_value?: number | null;
  commission_currency?: string | null;
  realized_at?: string | null;
  invoice_ref?: string | null;
  contract_pdf_url?: string | null;
  notes?: string | null;
  created_by?: string | null;
  created_at: string;
  updated_at?: string | null;
}

export interface EopPrefill {
  mode?: "create" | "edit" | "realize" | "cancel";
  existingRecord?: EopRecord | null;
  listing_id?: string | null;
  property_id?: string | null;
  lease_contract_id?: string | null;
  client_id?: string | null;
  client_role?: EopClientRole;
  client_type?: AgencyPartyType;
  client_name?: string;
  client_jmbg_pib?: string;
  client_address?: string;
  client_phone?: string;
  client_email?: string;
  transaction_type?: "prodaja" | "izdavanje";
  property_type?: string;
  property_address?: string;
  property_specs?: string;
  asking_price?: number | null;
  agreed_price?: number | null;
  currency?: string;
  status?: EopStatus;
  realized_at?: string | null;
  notes?: string;
}

export type ShowcaseCurrency = "EUR" | "RSD" | "USD";

export type AgencyMaintStatusFilter =
  | "all"
  | "open"
  | "in_progress"
  | "pending_approval"
  | "resolved";


export type AmlIdDocType = "licna_karta" | "pasos" | "boravisna" | "apr_izvod" | "other";
export type AmlPaymentMethod = "bank_transfer" | "cash" | "mixed" | "crypto";
export type AmlSourceOfFundsCategory =
  | "salary"
  | "savings"
  | "property_sale"
  | "loan"
  | "business"
  | "inheritance"
  | "other";
export type AmlRiskLevel = "low" | "medium" | "high";
export type AmlStatus = "draft" | "approved" | "rejected" | "superseded";
export type AmlDocumentType =
  | "id_card"
  | "passport"
  | "apr_extract"
  | "ubo_declaration"
  | "source_of_funds"
  | "signed_upitnik"
  | "sanctions_check"
  | "other";

export interface AmlUboItem {
  full_name: string;
  jmbg_passport?: string;
  ownership_pct?: number | null;
  citizenship?: string;
  is_pep?: boolean;
}

export interface AmlRiskFactor {
  key: string;
  points: number;
  autoHigh?: boolean;
}

export interface AmlDocument {
  id: string;
  agency_id: string;
  aml_record_id: string;
  doc_type: AmlDocumentType;
  file_name: string;
  storage_path: string;
  mime_type?: string | null;
  file_size_bytes?: number | null;
  uploaded_by?: string | null;
  created_at: string;
}

export interface AmlRecord {
  id: string;
  agency_id: string;
  sequence_year: number;
  sequence_number: number;
  aml_ref_no: string;
  client_id?: string | null;
  eop_record_id?: string | null;
  property_id?: string | null;
  listing_id?: string | null;
  superseded_by_id?: string | null;
  party_type: AgencyPartyType;
  client_name_snapshot: string;
  jmbg_pib_snapshot?: string | null;
  maticni_broj_snapshot?: string | null;
  id_doc_type?: AmlIdDocType | null;
  id_doc_number?: string | null;
  id_doc_issuer?: string | null;
  id_doc_expiry?: string | null;
  birth_date?: string | null;
  citizenship?: string | null;
  residency_country?: string | null;
  address_snapshot?: string | null;
  phone_snapshot?: string | null;
  email_snapshot?: string | null;
  occupation_or_activity?: string | null;
  is_pep: boolean;
  pep_details?: string | null;
  ubo_list: AmlUboItem[];
  ubo_unclear: boolean;
  acts_on_behalf_of_third_party: boolean;
  third_party_details?: string | null;
  transaction_type: "prodaja" | "izdavanje";
  transaction_value_eur?: number | null;
  transaction_date: string;
  payment_method: AmlPaymentMethod;
  source_of_funds_category?: AmlSourceOfFundsCategory | null;
  source_of_funds?: string | null;
  purpose_of_relationship?: string | null;
  high_risk_country_involved: boolean;
  risk_score: number;
  risk_level: AmlRiskLevel;
  risk_factors: AmlRiskFactor[];
  enhanced_due_diligence_notes?: string | null;
  next_review_at?: string | null;
  status: AmlStatus;
  is_locked: boolean;
  locked_at?: string | null;
  locked_by?: string | null;
  retention_until?: string | null;
  decision_notes?: string | null;
  created_by?: string | null;
  created_at: string;
  updated_at?: string | null;
  documents?: AmlDocument[];
}

export interface AmlPrefill {
  mode?: "create" | "edit" | "supersede";
  existingRecord?: AmlRecord | null;
  client_id?: string | null;
  eop_record_id?: string | null;
  property_id?: string | null;
  listing_id?: string | null;
  party_type?: AgencyPartyType;
  client_name?: string;
  jmbg_pib?: string;
  maticni_broj?: string;
  address?: string;
  phone?: string;
  email?: string;
  transaction_type?: "prodaja" | "izdavanje";
  transaction_value_eur?: number | null;
  transaction_date?: string;
}
