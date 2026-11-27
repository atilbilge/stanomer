import type {
  AgencyPartyType,
  AmlPaymentMethod,
  AmlRecord,
  AmlRiskFactor,
  AmlRiskLevel,
  AmlUboItem,
  EopRecord,
} from "../app/agency-panel/types";

export interface AmlRiskInput {
  party_type: AgencyPartyType;
  residency_country?: string | null;
  citizenship?: string | null;
  is_pep: boolean;
  ubo_list?: AmlUboItem[];
  ubo_unclear: boolean;
  acts_on_behalf_of_third_party: boolean;
  transaction_type: "prodaja" | "izdavanje";
  transaction_value_eur?: number | null;
  transaction_date?: string | null;
  payment_method: AmlPaymentMethod;
  source_of_funds?: string | null;
  high_risk_country_involved: boolean;
  manual_risk_override?: AmlRiskLevel | null;
}

export interface AmlRiskResult {
  score: number;
  level: AmlRiskLevel;
  autoLevel: AmlRiskLevel;
  factors: AmlRiskFactor[];
  autoHighTriggered: boolean;
  manuallyEscalated: boolean;
  suggestedNextReviewAt: string;
  retentionUntil: string;
}

export interface AmlValidationIssue {
  key: string;
  defaultText: string;
}

function addYearsIso(baseDateIso: string | null | undefined, years: number): string {
  const raw = baseDateIso && /^\d{4}-\d{2}-\d{2}/.test(baseDateIso)
    ? baseDateIso.slice(0, 10)
    : new Date().toISOString().slice(0, 10);
  const [y, m, d] = raw.split("-").map(Number);
  const dt = new Date(Date.UTC(y + years, (m || 1) - 1, d || 1));
  return dt.toISOString().slice(0, 10);
}

/**
 * Deterministic ZSPNFT (Serbian AML/CTF) risk scoring engine.
 * Pure function — zero hardcoded user-facing prose (returns i18n keys only).
 */
export function calculateAmlRisk(input: AmlRiskInput): AmlRiskResult {
  const factors: AmlRiskFactor[] = [];
  let autoHighTriggered = false;

  const uboHasPep = Array.isArray(input.ubo_list) && input.ubo_list.some((u) => Boolean(u.is_pep));
  if (input.is_pep || uboHasPep) {
    factors.push({ key: "aml_rf_pep", points: 45, autoHigh: true });
    autoHighTriggered = true;
  }

  if (input.high_risk_country_involved) {
    factors.push({ key: "aml_rf_high_risk_country", points: 35, autoHigh: true });
    autoHighTriggered = true;
  }

  const valEur = Number(input.transaction_value_eur || 0);
  if ((input.payment_method === "cash" || input.payment_method === "mixed") && valEur >= 10000) {
    factors.push({ key: "aml_rf_cash_threshold", points: 40, autoHigh: true });
    autoHighTriggered = true;
  } else if (input.payment_method === "mixed" || input.payment_method === "crypto") {
    factors.push({ key: "aml_rf_complex_payment", points: 25 });
  } else if (input.payment_method === "cash") {
    factors.push({ key: "aml_rf_cash_payment", points: 15 });
  }

  if (input.ubo_unclear || (input.party_type === "company" && (!input.ubo_list || input.ubo_list.length === 0))) {
    factors.push({ key: "aml_rf_ubo_unclear", points: 30, autoHigh: true });
    autoHighTriggered = true;
  }

  if (input.acts_on_behalf_of_third_party) {
    factors.push({ key: "aml_rf_third_party", points: 25 });
  }

  if (input.party_type === "company") {
    factors.push({ key: "aml_rf_legal_entity", points: 10 });
  }

  const resCountry = (input.residency_country || "RS").trim().toUpperCase();
  if (resCountry && resCountry !== "RS" && resCountry !== "SRB" && resCountry !== "SERBIA" && resCountry !== "SRBIJA") {
    factors.push({ key: "aml_rf_non_resident", points: 15 });
  }

  if (valEur >= 100000) {
    factors.push({ key: "aml_rf_high_value_100k", points: 15 });
  } else if (valEur >= 10000) {
    factors.push({ key: "aml_rf_value_10k", points: 5 });
  }

  if (!input.source_of_funds || !input.source_of_funds.trim()) {
    factors.push({ key: "aml_rf_missing_source_of_funds", points: 20 });
  }

  const rawScore = factors.reduce((sum, f) => sum + f.points, 0);
  const score = Math.min(100, rawScore);

  let autoLevel: AmlRiskLevel = "low";
  if (autoHighTriggered || score >= 50) {
    autoLevel = "high";
  } else if (score >= 25) {
    autoLevel = "medium";
  }

  // Upward-only manual escalation (ZSPNFT: downgrading computed risk is never allowed)
  const rank: Record<AmlRiskLevel, number> = { low: 0, medium: 1, high: 2 };
  let level: AmlRiskLevel = autoLevel;
  let manuallyEscalated = false;
  if (input.manual_risk_override && rank[input.manual_risk_override] > rank[autoLevel]) {
    level = input.manual_risk_override;
    manuallyEscalated = true;
    factors.push({
      key: "aml_rf_manual_escalation",
      points: 0,
      autoHigh: level === "high",
    });
  }

  const reviewYears = level === "high" ? 1 : level === "medium" ? 2 : 3;
  const suggestedNextReviewAt = addYearsIso(input.transaction_date, reviewYears);
  const retentionUntil = addYearsIso(input.transaction_date, 10);

  return {
    score,
    level,
    autoLevel,
    factors,
    autoHighTriggered,
    manuallyEscalated,
    suggestedNextReviewAt,
    retentionUntil,
  };
}

/**
 * Validates AML form data before save/lock. Returns i18n keys only.
 */
export function validateAmlBeforeLock(
  input: {
    client_name_snapshot: string;
    jmbg_pib_snapshot?: string | null;
    id_doc_number?: string | null;
    source_of_funds?: string | null;
    risk_level: AmlRiskLevel;
    enhanced_due_diligence_notes?: string | null;
    documentsCount: number;
  }
): { errors: AmlValidationIssue[]; warnings: AmlValidationIssue[] } {
  const errors: AmlValidationIssue[] = [];
  const warnings: AmlValidationIssue[] = [];

  if (!input.client_name_snapshot.trim()) {
    errors.push({ key: "aml_val_client_name_required", defaultText: "Client name is required." });
  }
  if (!input.jmbg_pib_snapshot?.trim()) {
    errors.push({ key: "aml_val_jmbg_pib_required", defaultText: "JMBG / Passport or PIB is required before locking." });
  }
  if (!input.id_doc_number?.trim()) {
    warnings.push({ key: "aml_warn_missing_id_doc_number", defaultText: "ID / APR document number is missing." });
  }
  if (!input.source_of_funds?.trim()) {
    warnings.push({ key: "aml_warn_missing_source_of_funds", defaultText: "Source of funds description is empty." });
  }
  if (input.risk_level === "high" && !input.enhanced_due_diligence_notes?.trim()) {
    warnings.push({ key: "aml_warn_high_risk_edd_recommended", defaultText: "Enhanced due diligence notes are recommended for high-risk clients." });
  }
  if (input.documentsCount === 0) {
    warnings.push({ key: "aml_warn_no_attachment_before_lock", defaultText: "No ID or KYC document is attached. You can still lock, but attaching a copy is recommended." });
  }

  return { errors, warnings };
}

/**
 * Evaluates whether an EOP record requires AML/SPN under Serbian ZSPNFT
 * (all sales, or leases with agreed/asking price >= 10,000 EUR).
 */
export function isAmlMandatoryForEop(eop: EopRecord): boolean {
  if (eop.status === "cancelled") return false;
  if (eop.transaction_type === "prodaja") return true;
  const price = Number(eop.agreed_price ?? eop.asking_price ?? 0);
  return price >= 10000;
}

/**
 * Finds the best matching active (non-superseded) AML record for an EOP row.
 * - Direct eop_record_id match takes priority (preferring finalized approved/rejected over in-progress draft).
 * - Otherwise falls back to the newest finalized (approved/rejected) AML record for the same client_id,
 *   enabling 1 valid AML dossier -> N EOP transactions for repeat clients.
 */
export function findMatchingAmlForEop(eop: EopRecord, amlRecords: AmlRecord[]): AmlRecord | null {
  const activeRecords = amlRecords.filter((r) => r.status !== "superseded");
  const directMatches = activeRecords.filter((r) => r.eop_record_id === eop.id);
  if (directMatches.length > 0) {
    return (
      directMatches.find((r) => r.status === "approved" || r.status === "rejected") ||
      directMatches[0]
    );
  }
  if (eop.client_id) {
    const clientMatches = activeRecords.filter((r) => r.client_id === eop.client_id);
    if (clientMatches.length > 0) {
      return (
        clientMatches.find((r) => r.status === "approved" || r.status === "rejected") ||
        clientMatches[0]
      );
    }
  }
  return null;
}


/**
 * Finds the newest active (non-superseded) REJECTED AML record matching a client,
 * listing, property, or linked EOP record — used to surface non-blocking compliance
 * warning badges across EOP, Listings, and Property Detail views.
 */
export function findRejectedAmlForContext(
  amlRecords: AmlRecord[],
  ctx: {
    clientId?: string | null;
    clientNames?: Array<string | null | undefined>;
    jmbgPib?: string | null;
    listingId?: string | null;
    propertyId?: string | null;
    eopRecords?: EopRecord[];
  }
): AmlRecord | null {
  if (!amlRecords || amlRecords.length === 0) return null;
  const rejected = amlRecords.filter((r) => r.status === "rejected");
  if (rejected.length === 0) return null;

  const normNames = new Set(
    (ctx.clientNames || []).map((n) => (n || "").trim().toLowerCase()).filter(Boolean)
  );
  const normJmbg = (ctx.jmbgPib || "").trim().toLowerCase();

  // Collect any client_ids or eop_ids linked via eopRecords on this listing/property
  const linkedEopIds = new Set<string>();
  const linkedClientIds = new Set<string>();
  if (ctx.clientId) linkedClientIds.add(ctx.clientId);
  if (ctx.eopRecords) {
    for (const eop of ctx.eopRecords) {
      if (
        (ctx.listingId && eop.listing_id === ctx.listingId) ||
        (ctx.propertyId && eop.property_id === ctx.propertyId)
      ) {
        linkedEopIds.add(eop.id);
        if (eop.client_id) linkedClientIds.add(eop.client_id);
        if (eop.client_name_snapshot) normNames.add(eop.client_name_snapshot.trim().toLowerCase());
      }
    }
  }

  for (const r of rejected) {
    if (ctx.listingId && r.listing_id === ctx.listingId) return r;
    if (ctx.propertyId && r.property_id === ctx.propertyId) return r;
    if (r.eop_record_id && linkedEopIds.has(r.eop_record_id)) return r;
    if (r.client_id && linkedClientIds.has(r.client_id)) return r;
    if (normJmbg && (r.jmbg_pib_snapshot || "").trim().toLowerCase() === normJmbg) return r;
    if (normNames.size > 0 && normNames.has(r.client_name_snapshot.trim().toLowerCase())) return r;
  }
  return null;
}
