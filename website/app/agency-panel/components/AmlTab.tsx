"use client";

import React, { useMemo, useState, useEffect, useRef } from "react";
import {
  ShieldCheck,
  ShieldAlert,
  Lock,
  Plus,
  Search,
  Printer,
  Upload,
  FileText,
  ExternalLink,
  Trash2,
  X,
  CheckCircle2,
  AlertTriangle,
  CopyPlus,
  Building2,
  User,
  ClipboardList,
  BookOpen,
  Clock,
  ChevronDown,
} from "lucide-react";
import translationsJson from "../../../lib/translations.json";
import {
  AgencyClient,
  AgencyContract,
  AgencyLead,
  AgencyManagedProperty,
  AgencyPartyType,
  AgencyRegistryInfo,
  AgencyTaskPrefill,
  AmlDocument,
  AmlDocumentType,
  AmlIdDocType,
  AmlPaymentMethod,
  AmlPrefill,
  AmlRecord,
  AmlRiskLevel,
  AmlSourceOfFundsCategory,
  AmlUboItem,
  EopRecord,
} from "../types";
import { calculateAmlRisk, validateAmlBeforeLock } from "../../../lib/amlRiskEngine";

const TRANSLATIONS: Record<string, Record<string, string>> = translationsJson as Record<
  string,
  Record<string, string>
>;

function getLocalTodayIso(): string {
  const now = new Date();
  const local = new Date(now.getTime() - now.getTimezoneOffset() * 60000);
  return local.toISOString().split("T")[0];
}

function escapeHtml(val: unknown): string {
  return String(val ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

function printOfficialUpitnik(
  record: AmlRecord,
  agencyName: string,
  registryInfo: AgencyRegistryInfo,
  script: "SR_LAT" | "SR_CYR"
) {
  const pt = (key: string) => TRANSLATIONS[script]?.[key] || TRANSLATIONS.SR_LAT?.[key] || key;
  const uboRows = (record.ubo_list || [])
    .map(
      (u, idx) =>
        `<tr><td>${idx + 1}</td><td>${escapeHtml(u.full_name)}</td><td>${escapeHtml(u.jmbg_passport || "—")}</td><td>${u.ownership_pct != null ? `${u.ownership_pct}%` : "—"}</td><td>${escapeHtml(u.citizenship || "—")}</td><td>${u.is_pep ? "DA" : "NE"}</td></tr>`
    )
    .join("");
  const riskFactorsHtml = (record.risk_factors || [])
    .map((f) => `<li>${escapeHtml(pt(f.key))} (+${f.points})</li>`)
    .join("");

  const html = `<!DOCTYPE html>
<html lang="${script === "SR_CYR" ? "sr-Cyrl" : "sr-Latn"}">
<head>
<meta charset="utf-8" />
<title>${escapeHtml(record.aml_ref_no)} — ${escapeHtml(pt("aml_print_title"))}</title>
<style>
  @page { size: A4 portrait; margin: 14mm; }
  body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; color: #111827; font-size: 11px; line-height: 1.45; }
  .header { border-bottom: 2px solid #1B5888; padding-bottom: 10px; margin-bottom: 14px; display: flex; justify-content: space-between; align-items: flex-start; }
  .header h1 { font-size: 14px; margin: 0 0 4px 0; color: #1B5888; }
  .meta { font-size: 10px; color: #374151; }
  .ref-box { border: 1px solid #1B5888; padding: 6px 10px; border-radius: 4px; text-align: right; background: #F8FAFC; }
  .sec { margin-top: 12px; }
  .sec-title { font-size: 11px; font-weight: 700; text-transform: uppercase; background: #E5EEF6; color: #1B5888; padding: 4px 8px; border-left: 3px solid #1B5888; margin-bottom: 6px; }
  table { width: 100%; border-collapse: collapse; margin-bottom: 6px; }
  td, th { border: 1px solid #D1D5DB; padding: 5px 7px; text-align: left; vertical-align: top; }
  th { background: #F9FAFB; font-weight: 600; width: 28%; }
  .risk-badge { display: inline-block; padding: 2px 8px; border-radius: 4px; font-weight: 700; font-size: 11px; }
  .risk-low { background: #DCFCE7; color: #166534; }
  .risk-medium { background: #FEF3C7; color: #92400E; }
  .risk-high { background: #FEE2E2; color: #991B1B; }
  .signatures { margin-top: 24px; display: flex; justify-content: space-between; gap: 24px; }
  .sig-col { flex: 1; text-align: center; }
  .sig-line { border-top: 1px solid #111827; margin-top: 36px; padding-top: 4px; font-size: 10px; }
  .footer { margin-top: 18px; border-top: 1px dashed #9CA3AF; padding-top: 6px; font-size: 9.5px; color: #4B5563; }
</style>
</head>
<body>
  <div class="header">
    <div>
      <h1>${escapeHtml(pt("aml_print_title"))}</h1>
      <div class="meta">
        <strong>${escapeHtml(agencyName)}</strong>
        ${registryInfo.registar_posrednika_no ? ` · Registar: ${escapeHtml(registryInfo.registar_posrednika_no)}` : ""}
        ${registryInfo.pib ? ` · PIB: ${escapeHtml(registryInfo.pib)}` : ""}
        ${registryInfo.maticni_broj ? ` · MB: ${escapeHtml(registryInfo.maticni_broj)}` : ""}
        ${registryInfo.official_address ? `<br/>${escapeHtml(registryInfo.official_address)}` : ""}
      </div>
    </div>
    <div class="ref-box">
      <div style="font-weight:700;font-size:12px;">${escapeHtml(record.aml_ref_no)}</div>
      <div style="font-size:10px;">${escapeHtml(record.transaction_date)}</div>
      <div class="risk-badge risk-${escapeHtml(record.risk_level)}" style="margin-top:4px;">
        ${escapeHtml(pt(`aml_risk_${record.risk_level}`))} (${record.risk_score}/100)
      </div>
    </div>
  </div>

  <div class="sec">
    <div class="sec-title">${escapeHtml(pt("aml_sec_party"))}</div>
    <table>
      <tr><th>${escapeHtml(pt("aml_col_client"))}</th><td>${escapeHtml(record.client_name_snapshot)} (${escapeHtml(record.party_type)})</td></tr>
      <tr><th>JMBG / PIB / MB</th><td>${escapeHtml(record.jmbg_pib_snapshot || "—")}${record.maticni_broj_snapshot ? ` / MB: ${escapeHtml(record.maticni_broj_snapshot)}` : ""}</td></tr>
      <tr><th>${escapeHtml(pt("aml_field_id_doc_type"))}</th><td>${escapeHtml(record.id_doc_type ? pt(`aml_doc_${record.id_doc_type}`) : "—")} · ${escapeHtml(record.id_doc_number || "—")} (${escapeHtml(record.id_doc_issuer || "—")}${record.id_doc_expiry ? `, ${escapeHtml(record.id_doc_expiry)}` : ""})</td></tr>
      <tr><th>${escapeHtml(pt("aml_field_birth_date"))} / ${escapeHtml(pt("aml_field_citizenship"))}</th><td>${escapeHtml(record.birth_date || "—")} / ${escapeHtml(record.citizenship || "—")} (${escapeHtml(record.residency_country || "RS")})</td></tr>
      <tr><th>${escapeHtml(pt("eop_field_client_address"))}</th><td>${escapeHtml(record.address_snapshot || "—")} · ${escapeHtml(record.phone_snapshot || "—")} · ${escapeHtml(record.email_snapshot || "—")}</td></tr>
      <tr><th>${escapeHtml(pt("aml_field_occupation"))}</th><td>${escapeHtml(record.occupation_or_activity || "—")}</td></tr>
    </table>
  </div>

  <div class="sec">
    <div class="sec-title">${escapeHtml(pt("aml_sec_pep_ubo"))}</div>
    <table>
      <tr><th>PEP (Funkcioner)</th><td>${record.is_pep ? "DA" : "NE"}${record.pep_details ? ` — ${escapeHtml(record.pep_details)}` : ""}</td></tr>
      <tr><th>${escapeHtml(pt("aml_field_high_risk_country"))}</th><td>${record.high_risk_country_involved ? "DA" : "NE"}</td></tr>
      <tr><th>${escapeHtml(pt("aml_field_third_party"))}</th><td>${record.acts_on_behalf_of_third_party ? "DA" : "NE"}${record.third_party_details ? ` — ${escapeHtml(record.third_party_details)}` : ""}</td></tr>
    </table>
    ${uboRows ? `<table><tr><th>#</th><th>UBO</th><th>JMBG/Pasoš</th><th>%</th><th>Drž.</th><th>PEP</th></tr>${uboRows}</table>` : ""}
  </div>

  <div class="sec">
    <div class="sec-title">${escapeHtml(pt("aml_sec_transaction"))}</div>
    <table>
      <tr><th>${escapeHtml(pt("aml_col_transaction"))}</th><td>${escapeHtml(pt(`eop_tx_${record.transaction_type}`))} · ${record.transaction_value_eur != null ? `${Number(record.transaction_value_eur).toLocaleString("de-DE")} EUR` : "—"}</td></tr>
      <tr><th>${escapeHtml(pt("aml_field_payment_method"))}</th><td>${escapeHtml(pt(`aml_pay_${record.payment_method}`))}</td></tr>
      <tr><th>${escapeHtml(pt("aml_field_sof_desc"))}</th><td>${record.source_of_funds_category ? `[${escapeHtml(pt(`aml_sof_${record.source_of_funds_category}`))}] ` : ""}${escapeHtml(record.source_of_funds || "—")}</td></tr>
      <tr><th>${escapeHtml(pt("aml_field_purpose"))}</th><td>${escapeHtml(record.purpose_of_relationship || "—")}</td></tr>
    </table>
  </div>

  <div class="sec">
    <div class="sec-title">${escapeHtml(pt("aml_sec_risk"))}</div>
    <table>
      <tr><th>${escapeHtml(pt("aml_col_risk"))}</th><td><strong>${escapeHtml(pt(`aml_risk_${record.risk_level}`))} (${record.risk_score}/100)</strong>${riskFactorsHtml ? `<ul style="margin:4px 0 0 16px;padding:0;">${riskFactorsHtml}</ul>` : ""}</td></tr>
      <tr><th>${escapeHtml(pt("aml_field_edd_notes"))}</th><td>${escapeHtml(record.enhanced_due_diligence_notes || "—")}</td></tr>
      <tr><th>${escapeHtml(pt("aml_field_decision_notes"))}</th><td>${escapeHtml(record.decision_notes || "—")}</td></tr>
    </table>
  </div>

  <div class="signatures">
    <div class="sig-col">
      <div class="sig-line">${escapeHtml(pt("aml_print_signature_client"))}<br/><strong>${escapeHtml(record.client_name_snapshot)}</strong></div>
    </div>
    <div class="sig-col">
      <div class="sig-line">${escapeHtml(pt("aml_print_signature_officer"))}<br/><strong>${escapeHtml(registryInfo.aml_officer_name || agencyName)}</strong></div>
    </div>
  </div>

  <div class="footer">
    ${escapeHtml(pt("aml_print_retention_footer"))} <strong>${escapeHtml(record.retention_until || "—")}</strong>
    ${record.locked_at ? ` · Locked: ${escapeHtml(record.locked_at.slice(0, 10))}` : ""}
  </div>
  <script>window.onload = () => { window.print(); };</script>
</body>
</html>`;

  const w = window.open("", "_blank", "width=920,height=1050");
  if (w) {
    w.document.open();
    w.document.write(html);
    w.document.close();
  }
}

export interface AmlFormModalProps {
  isOpen: boolean;
  prefill: AmlPrefill | null;
  clients: AgencyClient[];
  eopRecords: EopRecord[];
  existingAmlRecords?: AmlRecord[];
  managedProperties?: AgencyManagedProperty[];
  contracts?: AgencyContract[];
  leads?: AgencyLead[];
  agencyRole: "agency_admin" | "agency_operation";
  agencyName: string;
  registryInfo: AgencyRegistryInfo;
  onClose: () => void;
  onSave: (payload: {
    id?: string;
    supersededFromId?: string;
    lockAction?: "approve" | "reject" | null;
    saveClientToDirectory?: boolean;
    record: Omit<
      AmlRecord,
      "id" | "agency_id" | "sequence_year" | "sequence_number" | "aml_ref_no" | "created_at" | "updated_at" | "documents"
    >;
  }) => Promise<AmlRecord | null>;
  onUploadDocument: (amlRecordId: string, file: File, docType: AmlDocumentType) => Promise<void>;
  onOpenDocument: (doc: AmlDocument) => Promise<void>;
  onDeleteDocument: (doc: AmlDocument) => Promise<void>;
  onDeleteDraft?: (record: AmlRecord) => Promise<void>;
  onStartRevision?: (record: AmlRecord) => void;
  t: (key: string) => string;
}

export function AmlFormModal({
  isOpen,
  prefill,
  clients,
  eopRecords,
  existingAmlRecords = [],
  managedProperties = [],
  contracts = [],
  leads = [],
  agencyRole,
  agencyName,
  registryInfo,
  onClose,
  onSave,
  onUploadDocument,
  onOpenDocument,
  onDeleteDocument,
  onDeleteDraft,
  onStartRevision,
  t,
}: AmlFormModalProps) {
  const existing = prefill?.existingRecord || null;
  const mode = prefill?.mode || (existing ? "edit" : "create");
  const isSupersede = mode === "supersede";
  const isLockedReadOnly = Boolean(existing && existing.is_locked && !isSupersede);
  const isAdmin = agencyRole === "agency_admin";
  const todayStr = getLocalTodayIso();

  const [selectedClientId, setSelectedClientId] = useState("");
  const [selectedPartyKey, setSelectedPartyKey] = useState("");
  const [partyDropdownOpen, setPartyDropdownOpen] = useState(false);
  const [partySearch, setPartySearch] = useState("");
  const partyDropdownRef = useRef<HTMLDivElement | null>(null);
  const [selectedEopId, setSelectedEopId] = useState("");
  const [partyType, setPartyType] = useState<AgencyPartyType>("individual");
  const [clientName, setClientName] = useState("");
  const [jmbgPib, setJmbgPib] = useState("");
  const [maticniBroj, setMaticniBroj] = useState("");
  const [idDocType, setIdDocType] = useState<AmlIdDocType>("licna_karta");
  const [idDocNumber, setIdDocNumber] = useState("");
  const [idDocIssuer, setIdDocIssuer] = useState("");
  const [idDocExpiry, setIdDocExpiry] = useState("");
  const [birthDate, setBirthDate] = useState("");
  const [citizenship, setCitizenship] = useState("RS");
  const [residencyCountry, setResidencyCountry] = useState("RS");
  const [address, setAddress] = useState("");
  const [phone, setPhone] = useState("");
  const [email, setEmail] = useState("");
  const [occupation, setOccupation] = useState("");

  const [isPep, setIsPep] = useState(false);
  const [pepDetails, setPepDetails] = useState("");
  const [highRiskCountry, setHighRiskCountry] = useState(false);
  const [actsForThirdParty, setActsForThirdParty] = useState(false);
  const [thirdPartyDetails, setThirdPartyDetails] = useState("");
  const [uboList, setUboList] = useState<AmlUboItem[]>([]);
  const [uboUnclear, setUboUnclear] = useState(false);

  const [transactionType, setTransactionType] = useState<"prodaja" | "izdavanje">("prodaja");
  const [transactionValueEur, setTransactionValueEur] = useState("");
  const [transactionDate, setTransactionDate] = useState(todayStr);
  const [paymentMethod, setPaymentMethod] = useState<AmlPaymentMethod>("bank_transfer");
  const [sofCategory, setSofCategory] = useState<AmlSourceOfFundsCategory>("savings");
  const [sourceOfFunds, setSourceOfFunds] = useState("");
  const [purpose, setPurpose] = useState("");
  const [eddNotes, setEddNotes] = useState("");
  const [decisionNotes, setDecisionNotes] = useState("");
  const [manualRiskOverride, setManualRiskOverride] = useState<"" | "medium" | "high">("");
  const [pendingLockAction, setPendingLockAction] = useState<"approve" | "reject" | null>(null);

  const [uploadDocType, setUploadDocType] = useState<AmlDocumentType>("id_card");
  const [uploadingDoc, setUploadingDoc] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement | null>(null);

  useEffect(() => {
    if (!isOpen) return;
    setErrorMsg(null);
    if (existing) {
      setSelectedClientId(existing.client_id || "");
      setSelectedPartyKey(existing.client_id ? `client:${existing.client_id}` : "");
      setSelectedEopId(existing.eop_record_id || "");
      setPartyType(existing.party_type || "individual");
      setClientName(existing.client_name_snapshot || "");
      setJmbgPib(existing.jmbg_pib_snapshot || "");
      setMaticniBroj(existing.maticni_broj_snapshot || "");
      setIdDocType(existing.id_doc_type || (existing.party_type === "company" ? "apr_izvod" : "licna_karta"));
      setIdDocNumber(existing.id_doc_number || "");
      setIdDocIssuer(existing.id_doc_issuer || "");
      setIdDocExpiry(existing.id_doc_expiry || "");
      setBirthDate(existing.birth_date || "");
      setCitizenship(existing.citizenship || "RS");
      setResidencyCountry(existing.residency_country || "RS");
      setAddress(existing.address_snapshot || "");
      setPhone(existing.phone_snapshot || "");
      setEmail(existing.email_snapshot || "");
      setOccupation(existing.occupation_or_activity || "");
      setIsPep(Boolean(existing.is_pep));
      setPepDetails(existing.pep_details || "");
      setHighRiskCountry(Boolean(existing.high_risk_country_involved));
      setActsForThirdParty(Boolean(existing.acts_on_behalf_of_third_party));
      setThirdPartyDetails(existing.third_party_details || "");
      setUboList(Array.isArray(existing.ubo_list) ? existing.ubo_list : []);
      setUboUnclear(Boolean(existing.ubo_unclear));
      setTransactionType(existing.transaction_type || "prodaja");
      setTransactionValueEur(existing.transaction_value_eur != null ? String(existing.transaction_value_eur) : "");
      setTransactionDate(isSupersede ? todayStr : existing.transaction_date || todayStr);
      setPaymentMethod(existing.payment_method || "bank_transfer");
      setSofCategory(existing.source_of_funds_category || "savings");
      setSourceOfFunds(existing.source_of_funds || "");
      setPurpose(existing.purpose_of_relationship || "");
      setEddNotes(existing.enhanced_due_diligence_notes || "");
      setDecisionNotes(isSupersede ? "" : existing.decision_notes || "");
      const hasManualEsc = Array.isArray(existing.risk_factors) && existing.risk_factors.some((f) => f.key === "aml_rf_manual_escalation");
      setManualRiskOverride(hasManualEsc && (existing.risk_level === "medium" || existing.risk_level === "high") ? existing.risk_level : "");
      setPendingLockAction(null);
    } else {
      setSelectedClientId(prefill?.client_id || "");
      setSelectedPartyKey(prefill?.client_id ? `client:${prefill.client_id}` : "");
      setSelectedEopId(prefill?.eop_record_id || "");
      const pt = prefill?.party_type || "individual";
      setPartyType(pt);
      setClientName(prefill?.client_name || "");
      setJmbgPib(prefill?.jmbg_pib || "");
      setMaticniBroj(prefill?.maticni_broj || "");
      setIdDocType(pt === "company" ? "apr_izvod" : "licna_karta");
      setIdDocNumber("");
      setIdDocIssuer("");
      setIdDocExpiry("");
      setBirthDate("");
      setCitizenship("RS");
      setResidencyCountry("RS");
      setAddress(prefill?.address || "");
      setPhone(prefill?.phone || "");
      setEmail(prefill?.email || "");
      setOccupation("");
      setIsPep(false);
      setPepDetails("");
      setHighRiskCountry(false);
      setActsForThirdParty(false);
      setThirdPartyDetails("");
      setUboList([]);
      setUboUnclear(false);
      setTransactionType(prefill?.transaction_type || "prodaja");
      setTransactionValueEur(prefill?.transaction_value_eur != null ? String(prefill.transaction_value_eur) : "");
      setTransactionDate(prefill?.transaction_date || todayStr);
      setPaymentMethod("bank_transfer");
      setSofCategory("savings");
      setSourceOfFunds("");
      setPurpose("");
      setEddNotes("");
      setDecisionNotes("");
      setManualRiskOverride("");
      setPendingLockAction(null);
      setPartyDropdownOpen(false);
      setPartySearch("");
    }
  }, [isOpen, prefill, existing, isSupersede, todayStr]);

  useEffect(() => {
    if (!partyDropdownOpen) return;
    const onDocMouseDown = (e: MouseEvent) => {
      if (partyDropdownRef.current && !partyDropdownRef.current.contains(e.target as Node)) {
        setPartyDropdownOpen(false);
      }
    };
    document.addEventListener("mousedown", onDocMouseDown);
    return () => document.removeEventListener("mousedown", onDocMouseDown);
  }, [partyDropdownOpen]);

  const riskResult = useMemo(
    () =>
      calculateAmlRisk({
        party_type: partyType,
        residency_country: residencyCountry,
        citizenship,
        is_pep: isPep,
        ubo_list: uboList,
        ubo_unclear: uboUnclear,
        acts_on_behalf_of_third_party: actsForThirdParty,
        transaction_type: transactionType,
        transaction_value_eur: transactionValueEur ? Number(transactionValueEur) : null,
        transaction_date: transactionDate,
        payment_method: paymentMethod,
        source_of_funds: sourceOfFunds,
        high_risk_country_involved: highRiskCountry,
        manual_risk_override: manualRiskOverride || null,
      }),
    [
      partyType,
      residencyCountry,
      citizenship,
      isPep,
      uboList,
      uboUnclear,
      actsForThirdParty,
      transactionType,
      transactionValueEur,
      transactionDate,
      paymentMethod,
      sourceOfFunds,
      highRiskCountry,
      manualRiskOverride,
    ]
  );

  const attachedDocs = useMemo(
    () => (!isSupersede && existing?.documents ? existing.documents : []),
    [existing, isSupersede]
  );

  const validation = useMemo(
    () =>
      validateAmlBeforeLock({
        client_name_snapshot: clientName,
        jmbg_pib_snapshot: jmbgPib,
        id_doc_number: idDocNumber,
        source_of_funds: sourceOfFunds,
        risk_level: riskResult.level,
        enhanced_due_diligence_notes: eddNotes,
        documentsCount: attachedDocs.length,
      }),
    [clientName, jmbgPib, idDocNumber, sourceOfFunds, riskResult.level, eddNotes, attachedDocs.length]
  );

  const groupedPartyOptions = useMemo(() => {
    const seenNames = new Set(clients.map((c) => c.full_name.trim().toLowerCase()));
    const owners: Array<{ key: string; name: string; phone?: string; email?: string; jmbg?: string }> = [];
    const tenants: Array<{ key: string; name: string; phone?: string; email?: string; jmbg?: string }> = [];
    const leadOpts: Array<{ key: string; name: string; phone?: string; email?: string; tx?: "prodaja" | "izdavanje" }> = [];

    for (const p of managedProperties) {
      if (Array.isArray(p.owners) && p.owners.length > 0) {
        for (const o of p.owners) {
          const name = String(o?.full_name || o?.name || "").trim();
          const norm = name.toLowerCase();
          if (!name || seenNames.has(norm)) continue;
          seenNames.add(norm);
          owners.push({
            key: `owner:${p.id}:${owners.length}`,
            name,
            phone: o?.phone || p.landlord_phone || "",
            email: o?.email || p.landlord_email || "",
            jmbg: o?.jmbg_pib || "",
          });
        }
      } else if (p.landlord_name?.trim()) {
        const name = p.landlord_name.trim();
        const norm = name.toLowerCase();
        if (!seenNames.has(norm)) {
          seenNames.add(norm);
          owners.push({
            key: `owner:${p.id}`,
            name,
            phone: p.landlord_phone || "",
            email: p.landlord_email || "",
          });
        }
      }
    }

    for (const c of contracts) {
      const name = (c.tenant_name || "").trim();
      const norm = name.toLowerCase();
      if (!name || seenNames.has(norm)) continue;
      seenNames.add(norm);
      tenants.push({
        key: `tenant:${c.id}`,
        name,
        phone: c.tenant_phone || "",
        email: c.invitee_email || "",
        jmbg: c.tenant_id_number || "",
      });
    }

    for (const l of leads) {
      const name = (l.client_name || "").trim();
      const norm = name.toLowerCase();
      if (!name || seenNames.has(norm)) continue;
      seenNames.add(norm);
      leadOpts.push({
        key: `lead:${l.id}`,
        name,
        phone: l.client_phone || "",
        email: l.client_email || "",
        tx: l.transaction_type,
      });
    }

    return { owners, tenants, leadOpts };
  }, [clients, managedProperties, contracts, leads]);

  const filteredPartyGroups = useMemo(() => {
    const q = partySearch.trim().toLowerCase();
    const matches = (parts: Array<string | null | undefined>) =>
      !q || parts.some((p) => (p || "").toLowerCase().includes(q));

    const directory = clients.filter((c) => matches([c.full_name, c.jmbg_pib, c.phone, c.email]));
    const owners = groupedPartyOptions.owners.filter((o) => matches([o.name, o.jmbg, o.phone, o.email]));
    const tenants = groupedPartyOptions.tenants.filter((tn) => matches([tn.name, tn.jmbg, tn.phone, tn.email]));
    const leadOpts = groupedPartyOptions.leadOpts.filter((ld) => matches([ld.name, ld.phone, ld.email]));
    const totalCount = directory.length + owners.length + tenants.length + leadOpts.length;
    return { directory, owners, tenants, leadOpts, totalCount };
  }, [clients, groupedPartyOptions, partySearch]);

  const selectedPartyLabel = useMemo(() => {
    if (!selectedPartyKey) return "";
    if (selectedPartyKey.startsWith("client:")) {
      const c = clients.find((item) => `client:${item.id}` === selectedPartyKey);
      return c ? `${c.full_name}${c.jmbg_pib ? ` (${c.jmbg_pib})` : ""}` : "";
    }
    const o = groupedPartyOptions.owners.find((item) => item.key === selectedPartyKey);
    if (o) return `${o.name}${o.phone ? ` (${o.phone})` : ""}`;
    const tn = groupedPartyOptions.tenants.find((item) => item.key === selectedPartyKey);
    if (tn) return `${tn.name}${tn.jmbg ? ` (${tn.jmbg})` : tn.phone ? ` (${tn.phone})` : ""}`;
    const ld = groupedPartyOptions.leadOpts.find((item) => item.key === selectedPartyKey);
    if (ld) return `${ld.name}${ld.phone ? ` (${ld.phone})` : ""}`;
    return "";
  }, [selectedPartyKey, clients, groupedPartyOptions]);

  if (!isOpen) return null;

  const handleSelectParty = (val: string) => {
    setSelectedPartyKey(val);
    if (!val) {
      setSelectedClientId("");
      return;
    }
    if (val.startsWith("client:")) {
      const cid = val.slice("client:".length);
      setSelectedClientId(cid);
      const found = clients.find((c) => c.id === cid);
      if (!found) return;
      setPartyType(found.party_type);
      setClientName(found.full_name);
      setJmbgPib(found.jmbg_pib || "");
      setMaticniBroj(found.maticni_broj || "");
      setAddress(found.address || "");
      setPhone(found.phone || "");
      setEmail(found.email || "");
      if (found.party_type === "company") setIdDocType("apr_izvod");
      return;
    }
    // Non-directory sources (Owner / Tenant / Lead) -> will auto-save to agency_clients on submit
    setSelectedClientId("");
    const ownerMatch = groupedPartyOptions.owners.find((o) => o.key === val);
    if (ownerMatch) {
      setPartyType("individual");
      setClientName(ownerMatch.name);
      if (ownerMatch.jmbg) setJmbgPib(ownerMatch.jmbg);
      setPhone(ownerMatch.phone || "");
      setEmail(ownerMatch.email || "");
      return;
    }
    const tenantMatch = groupedPartyOptions.tenants.find((tn) => tn.key === val);
    if (tenantMatch) {
      setPartyType("individual");
      setClientName(tenantMatch.name);
      if (tenantMatch.jmbg) setJmbgPib(tenantMatch.jmbg);
      setPhone(tenantMatch.phone || "");
      setEmail(tenantMatch.email || "");
      return;
    }
    const leadMatch = groupedPartyOptions.leadOpts.find((ld) => ld.key === val);
    if (leadMatch) {
      setPartyType("individual");
      setClientName(leadMatch.name);
      setPhone(leadMatch.phone || "");
      setEmail(leadMatch.email || "");
      if (leadMatch.tx) setTransactionType(leadMatch.tx);
    }
  };

  const handleSelectEop = (eopId: string) => {
    setSelectedEopId(eopId);
    const found = eopRecords.find((r) => r.id === eopId);
    if (!found) return;
    if (!clientName.trim()) {
      setSelectedClientId(found.client_id || "");
      setPartyType(found.client_type || "individual");
      setClientName(found.client_name_snapshot || "");
      setJmbgPib(found.client_jmbg_pib_snapshot || "");
      setAddress(found.client_address_snapshot || "");
      setPhone(found.client_phone_snapshot || "");
      setEmail(found.client_email_snapshot || "");
    }
    setTransactionType(found.transaction_type || "prodaja");
    const price = found.agreed_price ?? found.asking_price;
    if (price != null && !transactionValueEur) {
      setTransactionValueEur(String(price));
    }
  };

  const handleRequestLock = (action: "approve" | "reject") => {
    if (!clientName.trim()) {
      setErrorMsg(t("aml_val_client_name_required"));
      return;
    }
    if (!isAdmin) {
      setErrorMsg(t("aml_lock_admin_only"));
      return;
    }
    if (validation.errors.length > 0) {
      setErrorMsg(t(validation.errors[0].key));
      return;
    }
    setErrorMsg(null);
    setPendingLockAction(action);
  };

  const handleAction = async (lockAction: "approve" | "reject" | null) => {
    if (!clientName.trim()) {
      setErrorMsg(t("aml_val_client_name_required"));
      return;
    }
    if (lockAction) {
      if (!isAdmin) {
        setErrorMsg(t("aml_lock_admin_only"));
        return;
      }
      if (validation.errors.length > 0) {
        setErrorMsg(t(validation.errors[0].key));
        return;
      }
    }
    setPendingLockAction(null);

    setSubmitting(true);
    setErrorMsg(null);
    try {
      const linkedEop = eopRecords.find((r) => r.id === selectedEopId) || null;
      await onSave({
        id: isSupersede ? undefined : existing?.id,
        supersededFromId: isSupersede ? existing?.id : undefined,
        lockAction,
        saveClientToDirectory: !selectedClientId,
        record: {
          client_id: selectedClientId || null,
          eop_record_id: selectedEopId || null,
          property_id: prefill?.property_id ?? linkedEop?.property_id ?? existing?.property_id ?? null,
          listing_id: prefill?.listing_id ?? linkedEop?.listing_id ?? existing?.listing_id ?? null,
          superseded_by_id: null,
          party_type: partyType,
          client_name_snapshot: clientName.trim(),
          jmbg_pib_snapshot: jmbgPib.trim() || null,
          maticni_broj_snapshot: maticniBroj.trim() || null,
          id_doc_type: idDocType || null,
          id_doc_number: idDocNumber.trim() || null,
          id_doc_issuer: idDocIssuer.trim() || null,
          id_doc_expiry: idDocExpiry || null,
          birth_date: birthDate || null,
          citizenship: citizenship.trim() || null,
          residency_country: residencyCountry.trim() || "RS",
          address_snapshot: address.trim() || null,
          phone_snapshot: phone.trim() || null,
          email_snapshot: email.trim() || null,
          occupation_or_activity: occupation.trim() || null,
          is_pep: isPep,
          pep_details: isPep ? pepDetails.trim() || null : null,
          ubo_list: partyType === "company" ? uboList.filter((u) => u.full_name.trim()) : [],
          ubo_unclear: uboUnclear,
          acts_on_behalf_of_third_party: actsForThirdParty,
          third_party_details: actsForThirdParty ? thirdPartyDetails.trim() || null : null,
          transaction_type: transactionType,
          transaction_value_eur: transactionValueEur ? Number(transactionValueEur) : null,
          transaction_date: transactionDate || todayStr,
          payment_method: paymentMethod,
          source_of_funds_category: sofCategory || null,
          source_of_funds: sourceOfFunds.trim() || null,
          purpose_of_relationship: purpose.trim() || null,
          high_risk_country_involved: highRiskCountry,
          risk_score: riskResult.score,
          risk_level: riskResult.level,
          risk_factors: riskResult.factors,
          enhanced_due_diligence_notes: eddNotes.trim() || null,
          next_review_at: riskResult.suggestedNextReviewAt,
          status: lockAction === "approve" ? "approved" : lockAction === "reject" ? "rejected" : "draft",
          is_locked: Boolean(lockAction),
          locked_at: lockAction ? new Date().toISOString() : null,
          locked_by: existing?.locked_by || null,
          retention_until: lockAction ? riskResult.retentionUntil : null,
          decision_notes: decisionNotes.trim() || null,
          created_by: existing?.created_by || null,
        },
      });
      onClose();
    } catch (err: any) {
      setErrorMsg(err?.message || t("aml_msg_error"));
    } finally {
      setSubmitting(false);
    }
  };

  const handleFileSelected = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    e.target.value = "";
    if (!file || !existing?.id || isLockedReadOnly || isSupersede) return;
    setUploadingDoc(true);
    setErrorMsg(null);
    try {
      await onUploadDocument(existing.id, file, uploadDocType);
    } catch (err: any) {
      setErrorMsg(err?.message || t("aml_msg_error"));
    } finally {
      setUploadingDoc(false);
    }
  };

  const modalTitle = isLockedReadOnly
    ? `${t("aml_modal_title_view_locked")} — ${existing?.aml_ref_no}`
    : isSupersede
      ? `${t("aml_modal_title_supersede")} (${existing?.aml_ref_no})`
      : existing
        ? `${t("aml_modal_title_edit")} — ${existing.aml_ref_no}`
        : t("aml_modal_title_create");

  const riskBadgeClass =
    riskResult.level === "high"
      ? "bg-red-50 text-red-700 border-red-200"
      : riskResult.level === "medium"
        ? "bg-amber-50 text-amber-800 border-amber-200"
        : "bg-emerald-50 text-emerald-700 border-emerald-200";

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/50 backdrop-blur-xs p-3 sm:p-5">
      <div className="bg-white w-full max-w-4xl max-h-[92vh] rounded-2xl border border-[#E5E3DF] shadow-2xl flex flex-col overflow-hidden">
        {/* Header */}
        <div className="px-5 py-4 border-b border-[#E5E3DF] flex items-center justify-between gap-3 bg-[#FAF9F7]">
          <div className="flex items-center gap-2.5 min-w-0">
            <div className="w-9 h-9 rounded-xl bg-[#E5EEF6] text-[#1B5888] flex items-center justify-center shrink-0">
              {isLockedReadOnly ? <Lock className="w-4 h-4" /> : <ShieldCheck className="w-5 h-5" />}
            </div>
            <div className="min-w-0">
              <h3 className="text-sm sm:text-base font-bold text-[#1A1A1A] truncate">{modalTitle}</h3>
              <p className="text-xs text-[#666666] truncate">{t("aml_tab_subtitle")}</p>
            </div>
          </div>
          <div className="flex items-center gap-2 shrink-0">
            <span className={`text-xs font-bold px-2.5 py-1 rounded-full border ${riskBadgeClass}`}>
              {t(`aml_risk_${riskResult.level}`)} · {riskResult.score}/100
            </span>
            <button
              type="button"
              onClick={onClose}
              className="p-1.5 rounded-lg text-slate-500 hover:bg-slate-200/70 transition-colors cursor-pointer"
              aria-label="Close"
            >
              <X className="w-4 h-4" />
            </button>
          </div>
        </div>

        {/* Body */}
        <div className="flex-1 overflow-y-auto p-5 space-y-5">
          {isLockedReadOnly && existing && (
            <div className="p-3.5 rounded-xl bg-indigo-50 border border-indigo-200 flex items-start gap-3">
              <Lock className="w-4 h-4 text-indigo-700 shrink-0 mt-0.5" />
              <div className="text-xs text-indigo-900 space-y-0.5">
                <div className="font-bold">{t("aml_lock_banner_title")}</div>
                <div>
                  {t("aml_lock_banner_desc")} <strong>{existing.retention_until || "—"}</strong>
                </div>
              </div>
            </div>
          )}

          {errorMsg && (
            <div className="p-3 rounded-xl bg-red-50 border border-red-200 text-xs text-red-700 flex items-center gap-2">
              <AlertTriangle className="w-4 h-4 shrink-0" />
              <span>{errorMsg}</span>
            </div>
          )}

          {/* Section 1: Party & KYC */}
          <section className="space-y-3 border border-[#E5E3DF] rounded-xl p-4">
            <h4 className="text-xs font-bold uppercase tracking-wide text-[#1B5888]">{t("aml_sec_party")}</h4>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <div ref={partyDropdownRef} className="relative">
                <label className="block text-xs font-semibold text-slate-700 mb-1">{t("aml_field_select_client")}</label>
                <div className="relative flex items-center">
                  <Search className="w-3.5 h-3.5 text-slate-400 absolute left-2.5 pointer-events-none" />
                  <input
                    type="text"
                    disabled={isLockedReadOnly}
                    value={partyDropdownOpen ? partySearch : selectedPartyLabel}
                    onFocus={() => {
                      if (!isLockedReadOnly) {
                        setPartyDropdownOpen(true);
                        setPartySearch("");
                      }
                    }}
                    onChange={(e) => {
                      setPartySearch(e.target.value);
                      if (!partyDropdownOpen) setPartyDropdownOpen(true);
                    }}
                    onKeyDown={(e) => {
                      if (e.key === "Escape") setPartyDropdownOpen(false);
                    }}
                    placeholder={t("aml_client_search_placeholder")}
                    className="w-full h-9 pl-8 pr-14 rounded-lg border border-slate-300 text-xs bg-white disabled:bg-slate-100 focus:outline-none focus:border-[#1B5888]"
                  />
                  <div className="absolute right-1.5 flex items-center gap-0.5">
                    {!isLockedReadOnly && (selectedPartyKey || partySearch) && (
                      <button
                        type="button"
                        onClick={() => {
                          handleSelectParty("");
                          setPartySearch("");
                        }}
                        className="p-1 text-slate-400 hover:text-slate-700 cursor-pointer"
                        aria-label="Clear"
                      >
                        <X className="w-3.5 h-3.5" />
                      </button>
                    )}
                    <button
                      type="button"
                      disabled={isLockedReadOnly}
                      onClick={() => setPartyDropdownOpen((prev) => !prev)}
                      className="p-1 text-slate-400 hover:text-slate-700 cursor-pointer disabled:opacity-50"
                      aria-label="Toggle"
                    >
                      <ChevronDown className="w-3.5 h-3.5" />
                    </button>
                  </div>
                </div>

                {partyDropdownOpen && !isLockedReadOnly && (
                  <div className="absolute left-0 right-0 mt-1 z-30 bg-white border border-slate-200 rounded-xl shadow-xl max-h-64 overflow-y-auto py-1 text-xs">
                    {filteredPartyGroups.totalCount === 0 ? (
                      <div className="px-3 py-3 text-center text-slate-400">{t("aml_client_search_empty")}</div>
                    ) : (
                      <>
                        {filteredPartyGroups.directory.length > 0 && (
                          <div>
                            <div className="px-3 py-1 text-[10px] font-bold uppercase tracking-wide text-[#1B5888] bg-[#FAF9F7]">
                              {t("aml_client_group_directory")}
                            </div>
                            {filteredPartyGroups.directory.map((c) => {
                              const val = `client:${c.id}`;
                              return (
                                <button
                                  key={val}
                                  type="button"
                                  onClick={() => {
                                    handleSelectParty(val);
                                    setPartyDropdownOpen(false);
                                    setPartySearch("");
                                  }}
                                  className={`w-full text-left px-3 py-2 hover:bg-[#E5EEF6] flex items-center justify-between gap-2 cursor-pointer ${
                                    selectedPartyKey === val ? "bg-[#E5EEF6]/70 font-semibold text-[#1B5888]" : "text-slate-700"
                                  }`}
                                >
                                  <span className="truncate">{c.full_name}</span>
                                  {(c.jmbg_pib || c.phone) && (
                                    <span className="text-[11px] text-slate-500 font-mono shrink-0">
                                      {c.jmbg_pib || c.phone}
                                    </span>
                                  )}
                                </button>
                              );
                            })}
                          </div>
                        )}
                        {filteredPartyGroups.owners.length > 0 && (
                          <div>
                            <div className="px-3 py-1 text-[10px] font-bold uppercase tracking-wide text-[#1B5888] bg-[#FAF9F7]">
                              {t("aml_client_group_owners")}
                            </div>
                            {filteredPartyGroups.owners.map((o) => (
                              <button
                                key={o.key}
                                type="button"
                                onClick={() => {
                                  handleSelectParty(o.key);
                                  setPartyDropdownOpen(false);
                                  setPartySearch("");
                                }}
                                className={`w-full text-left px-3 py-2 hover:bg-[#E5EEF6] flex items-center justify-between gap-2 cursor-pointer ${
                                  selectedPartyKey === o.key ? "bg-[#E5EEF6]/70 font-semibold text-[#1B5888]" : "text-slate-700"
                                }`}
                              >
                                <span className="truncate">{o.name}</span>
                                {(o.jmbg || o.phone) && (
                                  <span className="text-[11px] text-slate-500 font-mono shrink-0">
                                    {o.jmbg || o.phone}
                                  </span>
                                )}
                              </button>
                            ))}
                          </div>
                        )}
                        {filteredPartyGroups.tenants.length > 0 && (
                          <div>
                            <div className="px-3 py-1 text-[10px] font-bold uppercase tracking-wide text-[#1B5888] bg-[#FAF9F7]">
                              {t("aml_client_group_tenants")}
                            </div>
                            {filteredPartyGroups.tenants.map((tn) => (
                              <button
                                key={tn.key}
                                type="button"
                                onClick={() => {
                                  handleSelectParty(tn.key);
                                  setPartyDropdownOpen(false);
                                  setPartySearch("");
                                }}
                                className={`w-full text-left px-3 py-2 hover:bg-[#E5EEF6] flex items-center justify-between gap-2 cursor-pointer ${
                                  selectedPartyKey === tn.key ? "bg-[#E5EEF6]/70 font-semibold text-[#1B5888]" : "text-slate-700"
                                }`}
                              >
                                <span className="truncate">{tn.name}</span>
                                {(tn.jmbg || tn.phone) && (
                                  <span className="text-[11px] text-slate-500 font-mono shrink-0">
                                    {tn.jmbg || tn.phone}
                                  </span>
                                )}
                              </button>
                            ))}
                          </div>
                        )}
                        {filteredPartyGroups.leadOpts.length > 0 && (
                          <div>
                            <div className="px-3 py-1 text-[10px] font-bold uppercase tracking-wide text-[#1B5888] bg-[#FAF9F7]">
                              {t("aml_client_group_leads")}
                            </div>
                            {filteredPartyGroups.leadOpts.map((ld) => (
                              <button
                                key={ld.key}
                                type="button"
                                onClick={() => {
                                  handleSelectParty(ld.key);
                                  setPartyDropdownOpen(false);
                                  setPartySearch("");
                                }}
                                className={`w-full text-left px-3 py-2 hover:bg-[#E5EEF6] flex items-center justify-between gap-2 cursor-pointer ${
                                  selectedPartyKey === ld.key ? "bg-[#E5EEF6]/70 font-semibold text-[#1B5888]" : "text-slate-700"
                                }`}
                              >
                                <span className="truncate">{ld.name}</span>
                                {ld.phone && (
                                  <span className="text-[11px] text-slate-500 font-mono shrink-0">{ld.phone}</span>
                                )}
                              </button>
                            ))}
                          </div>
                        )}
                      </>
                    )}
                  </div>
                )}
              </div>
              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">{t("aml_field_select_eop")}</label>
                <select
                  disabled={isLockedReadOnly}
                  value={selectedEopId}
                  onChange={(e) => handleSelectEop(e.target.value)}
                  className="w-full h-9 px-2.5 rounded-lg border border-slate-300 text-xs bg-white disabled:bg-slate-100"
                >
                  <option value="">{t("aml_field_no_eop")}</option>
                  {eopRecords.map((r) => {
                    const existingDraftForEop = existingAmlRecords.find(
                      (a) =>
                        a.eop_record_id === r.id &&
                        a.status === "draft" &&
                        a.id !== (isSupersede ? undefined : existing?.id)
                    );
                    const existingFinalForEop = existingAmlRecords.find(
                      (a) =>
                        a.eop_record_id === r.id &&
                        (a.status === "approved" || a.status === "rejected") &&
                        a.id !== existing?.id
                    );
                    const blocked = Boolean(existingDraftForEop) || (!isSupersede && Boolean(existingFinalForEop));
                    const tag = existingDraftForEop
                      ? ` [${existingDraftForEop.aml_ref_no}]`
                      : existingFinalForEop
                        ? ` [${existingFinalForEop.aml_ref_no}]`
                        : "";
                    return (
                      <option key={r.id} value={r.id} disabled={blocked}>
                        #{r.redni_broj} · {r.client_name_snapshot} ({r.mediation_contract_no}){tag}
                      </option>
                    );
                  })}
                </select>
              </div>
            </div>

            <div className="flex items-center gap-2">
              {(["individual", "company"] as AgencyPartyType[]).map((pt) => (
                <button
                  key={pt}
                  type="button"
                  disabled={isLockedReadOnly}
                  onClick={() => {
                    setPartyType(pt);
                    if (pt === "company") setIdDocType("apr_izvod");
                  }}
                  className={`px-3 py-1.5 rounded-lg text-xs font-semibold border flex items-center gap-1.5 cursor-pointer disabled:opacity-60 ${
                    partyType === pt
                      ? "bg-[#E5EEF6] text-[#1B5888] border-[#1B5888]/40"
                      : "bg-white text-slate-600 border-slate-200"
                  }`}
                >
                  {pt === "company" ? <Building2 className="w-3.5 h-3.5" /> : <User className="w-3.5 h-3.5" />}
                  <span>{pt === "company" ? t("eop_party_company") : t("eop_party_individual")}</span>
                </button>
              ))}
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
              <div className="sm:col-span-2">
                <label className="block text-xs font-semibold text-slate-700 mb-1">{t("eop_field_client_name")} *</label>
                <input
                  disabled={isLockedReadOnly}
                  value={clientName}
                  onChange={(e) => setClientName(e.target.value)}
                  className="w-full h-9 px-2.5 rounded-lg border border-slate-300 text-xs disabled:bg-slate-100"
                />
              </div>
              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">{t("eop_field_client_jmbg_pib")} *</label>
                <input
                  disabled={isLockedReadOnly}
                  value={jmbgPib}
                  onChange={(e) => setJmbgPib(e.target.value)}
                  className="w-full h-9 px-2.5 rounded-lg border border-slate-300 text-xs disabled:bg-slate-100"
                />
              </div>
              {partyType === "company" && (
                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1">{t("aml_field_maticni_broj")}</label>
                  <input
                    disabled={isLockedReadOnly}
                    value={maticniBroj}
                    onChange={(e) => setMaticniBroj(e.target.value)}
                    className="w-full h-9 px-2.5 rounded-lg border border-slate-300 text-xs disabled:bg-slate-100"
                  />
                </div>
              )}
              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">{t("aml_field_id_doc_type")}</label>
                <select
                  disabled={isLockedReadOnly}
                  value={idDocType}
                  onChange={(e) => setIdDocType(e.target.value as AmlIdDocType)}
                  className="w-full h-9 px-2.5 rounded-lg border border-slate-300 text-xs bg-white disabled:bg-slate-100"
                >
                  {(["licna_karta", "pasos", "boravisna", "apr_izvod", "other"] as AmlIdDocType[]).map((dt) => (
                    <option key={dt} value={dt}>
                      {t(`aml_doc_${dt}`)}
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">{t("aml_field_id_doc_number")}</label>
                <input
                  disabled={isLockedReadOnly}
                  value={idDocNumber}
                  onChange={(e) => setIdDocNumber(e.target.value)}
                  className="w-full h-9 px-2.5 rounded-lg border border-slate-300 text-xs disabled:bg-slate-100"
                />
              </div>
              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">{t("aml_field_id_doc_issuer")}</label>
                <input
                  disabled={isLockedReadOnly}
                  value={idDocIssuer}
                  onChange={(e) => setIdDocIssuer(e.target.value)}
                  className="w-full h-9 px-2.5 rounded-lg border border-slate-300 text-xs disabled:bg-slate-100"
                />
              </div>
              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">{t("aml_field_id_doc_expiry")}</label>
                <input
                  type="date"
                  disabled={isLockedReadOnly}
                  value={idDocExpiry}
                  onChange={(e) => setIdDocExpiry(e.target.value)}
                  className="w-full h-9 px-2.5 rounded-lg border border-slate-300 text-xs disabled:bg-slate-100"
                />
              </div>
              {partyType === "individual" && (
                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1">{t("aml_field_birth_date")}</label>
                  <input
                    type="date"
                    disabled={isLockedReadOnly}
                    value={birthDate}
                    onChange={(e) => setBirthDate(e.target.value)}
                    className="w-full h-9 px-2.5 rounded-lg border border-slate-300 text-xs disabled:bg-slate-100"
                  />
                </div>
              )}
              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">{t("aml_field_citizenship")}</label>
                <input
                  disabled={isLockedReadOnly}
                  value={citizenship}
                  onChange={(e) => setCitizenship(e.target.value)}
                  className="w-full h-9 px-2.5 rounded-lg border border-slate-300 text-xs disabled:bg-slate-100"
                />
              </div>
              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">{t("aml_field_residency")}</label>
                <input
                  disabled={isLockedReadOnly}
                  value={residencyCountry}
                  onChange={(e) => setResidencyCountry(e.target.value)}
                  className="w-full h-9 px-2.5 rounded-lg border border-slate-300 text-xs disabled:bg-slate-100"
                />
              </div>
              <div className="sm:col-span-2">
                <label className="block text-xs font-semibold text-slate-700 mb-1">{t("eop_field_client_address")}</label>
                <input
                  disabled={isLockedReadOnly}
                  value={address}
                  onChange={(e) => setAddress(e.target.value)}
                  className="w-full h-9 px-2.5 rounded-lg border border-slate-300 text-xs disabled:bg-slate-100"
                />
              </div>
              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">{t("aml_field_occupation")}</label>
                <input
                  disabled={isLockedReadOnly}
                  value={occupation}
                  onChange={(e) => setOccupation(e.target.value)}
                  className="w-full h-9 px-2.5 rounded-lg border border-slate-300 text-xs disabled:bg-slate-100"
                />
              </div>
            </div>
          </section>

          {/* Section 2: PEP & UBO */}
          <section className="space-y-3 border border-[#E5E3DF] rounded-xl p-4">
            <h4 className="text-xs font-bold uppercase tracking-wide text-[#1B5888]">{t("aml_sec_pep_ubo")}</h4>
            <div className="space-y-2.5">
              <label className="flex items-start gap-2 text-xs text-slate-800 cursor-pointer">
                <input
                  type="checkbox"
                  disabled={isLockedReadOnly}
                  checked={isPep}
                  onChange={(e) => setIsPep(e.target.checked)}
                  className="mt-0.5 rounded border-slate-300"
                />
                <span className="font-medium">{t("aml_field_is_pep")}</span>
              </label>
              {isPep && (
                <input
                  disabled={isLockedReadOnly}
                  placeholder={t("aml_field_pep_details")}
                  value={pepDetails}
                  onChange={(e) => setPepDetails(e.target.value)}
                  className="w-full h-9 px-2.5 rounded-lg border border-red-300 bg-red-50/40 text-xs"
                />
              )}

              <label className="flex items-start gap-2 text-xs text-slate-800 cursor-pointer">
                <input
                  type="checkbox"
                  disabled={isLockedReadOnly}
                  checked={highRiskCountry}
                  onChange={(e) => setHighRiskCountry(e.target.checked)}
                  className="mt-0.5 rounded border-slate-300"
                />
                <span className="font-medium">{t("aml_field_high_risk_country")}</span>
              </label>

              <label className="flex items-start gap-2 text-xs text-slate-800 cursor-pointer">
                <input
                  type="checkbox"
                  disabled={isLockedReadOnly}
                  checked={actsForThirdParty}
                  onChange={(e) => setActsForThirdParty(e.target.checked)}
                  className="mt-0.5 rounded border-slate-300"
                />
                <span className="font-medium">{t("aml_field_third_party")}</span>
              </label>
              {actsForThirdParty && (
                <input
                  disabled={isLockedReadOnly}
                  placeholder={t("aml_field_third_party_details")}
                  value={thirdPartyDetails}
                  onChange={(e) => setThirdPartyDetails(e.target.value)}
                  className="w-full h-9 px-2.5 rounded-lg border border-slate-300 text-xs"
                />
              )}

              {partyType === "company" && (
                <div className="pt-2 border-t border-slate-100 space-y-2">
                  <div className="flex items-center justify-between">
                    <span className="text-xs font-semibold text-slate-700">{t("aml_field_ubo_title")}</span>
                    {!isLockedReadOnly && (
                      <button
                        type="button"
                        onClick={() =>
                          setUboList((prev) => [
                            ...prev,
                            { full_name: "", jmbg_passport: "", ownership_pct: 25, citizenship: "RS", is_pep: false },
                          ])
                        }
                        className="text-xs font-semibold text-[#1B5888] hover:underline cursor-pointer"
                      >
                        {t("aml_btn_add_ubo")}
                      </button>
                    )}
                  </div>
                  {uboList.map((ubo, idx) => (
                    <div key={idx} className="grid grid-cols-12 gap-2 items-center bg-slate-50 p-2 rounded-lg">
                      <input
                        disabled={isLockedReadOnly}
                        placeholder={t("eop_field_client_name")}
                        value={ubo.full_name}
                        onChange={(e) =>
                          setUboList((prev) =>
                            prev.map((item, i) => (i === idx ? { ...item, full_name: e.target.value } : item))
                          )
                        }
                        className="col-span-4 h-8 px-2 rounded border border-slate-300 text-xs bg-white"
                      />
                      <input
                        disabled={isLockedReadOnly}
                        placeholder="JMBG / Pasoš"
                        value={ubo.jmbg_passport || ""}
                        onChange={(e) =>
                          setUboList((prev) =>
                            prev.map((item, i) => (i === idx ? { ...item, jmbg_passport: e.target.value } : item))
                          )
                        }
                        className="col-span-3 h-8 px-2 rounded border border-slate-300 text-xs bg-white"
                      />
                      <input
                        type="number"
                        disabled={isLockedReadOnly}
                        placeholder="%"
                        value={ubo.ownership_pct ?? ""}
                        onChange={(e) =>
                          setUboList((prev) =>
                            prev.map((item, i) =>
                              i === idx ? { ...item, ownership_pct: e.target.value ? Number(e.target.value) : null } : item
                            )
                          )
                        }
                        className="col-span-2 h-8 px-2 rounded border border-slate-300 text-xs bg-white"
                      />
                      <label className="col-span-2 flex items-center gap-1 text-[11px] text-slate-700">
                        <input
                          type="checkbox"
                          disabled={isLockedReadOnly}
                          checked={Boolean(ubo.is_pep)}
                          onChange={(e) =>
                            setUboList((prev) =>
                              prev.map((item, i) => (i === idx ? { ...item, is_pep: e.target.checked } : item))
                            )
                          }
                        />
                        PEP
                      </label>
                      {!isLockedReadOnly && (
                        <button
                          type="button"
                          onClick={() => setUboList((prev) => prev.filter((_, i) => i !== idx))}
                          className="col-span-1 text-red-500 hover:text-red-700 flex justify-center cursor-pointer"
                        >
                          <Trash2 className="w-3.5 h-3.5" />
                        </button>
                      )}
                    </div>
                  ))}
                  <label className="flex items-start gap-2 text-xs text-slate-700 cursor-pointer">
                    <input
                      type="checkbox"
                      disabled={isLockedReadOnly}
                      checked={uboUnclear}
                      onChange={(e) => setUboUnclear(e.target.checked)}
                      className="mt-0.5 rounded border-slate-300"
                    />
                    <span>{t("aml_field_ubo_unclear")}</span>
                  </label>
                </div>
              )}
            </div>
          </section>

          {/* Section 3: Transaction & Source of Funds */}
          <section className="space-y-3 border border-[#E5E3DF] rounded-xl p-4">
            <h4 className="text-xs font-bold uppercase tracking-wide text-[#1B5888]">{t("aml_sec_transaction")}</h4>
            <div className="grid grid-cols-1 sm:grid-cols-4 gap-3">
              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">{t("eop_field_tx_type")}</label>
                <select
                  disabled={isLockedReadOnly}
                  value={transactionType}
                  onChange={(e) => setTransactionType(e.target.value as "prodaja" | "izdavanje")}
                  className="w-full h-9 px-2.5 rounded-lg border border-slate-300 text-xs bg-white disabled:bg-slate-100"
                >
                  <option value="prodaja">{t("eop_tx_prodaja")}</option>
                  <option value="izdavanje">{t("eop_tx_izdavanje")}</option>
                </select>
              </div>
              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">{t("aml_field_tx_value_eur")}</label>
                <input
                  type="number"
                  min="0"
                  disabled={isLockedReadOnly}
                  value={transactionValueEur}
                  onChange={(e) => setTransactionValueEur(e.target.value)}
                  className="w-full h-9 px-2.5 rounded-lg border border-slate-300 text-xs disabled:bg-slate-100"
                />
              </div>
              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">{t("aml_field_tx_date")}</label>
                <input
                  type="date"
                  disabled={isLockedReadOnly}
                  value={transactionDate}
                  onChange={(e) => setTransactionDate(e.target.value)}
                  className="w-full h-9 px-2.5 rounded-lg border border-slate-300 text-xs disabled:bg-slate-100"
                />
              </div>
              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">{t("aml_field_payment_method")}</label>
                <select
                  disabled={isLockedReadOnly}
                  value={paymentMethod}
                  onChange={(e) => setPaymentMethod(e.target.value as AmlPaymentMethod)}
                  className="w-full h-9 px-2.5 rounded-lg border border-slate-300 text-xs bg-white disabled:bg-slate-100"
                >
                  {(["bank_transfer", "cash", "mixed", "crypto"] as AmlPaymentMethod[]).map((pm) => (
                    <option key={pm} value={pm}>
                      {t(`aml_pay_${pm}`)}
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">{t("aml_field_sof_category")}</label>
                <select
                  disabled={isLockedReadOnly}
                  value={sofCategory}
                  onChange={(e) => setSofCategory(e.target.value as AmlSourceOfFundsCategory)}
                  className="w-full h-9 px-2.5 rounded-lg border border-slate-300 text-xs bg-white disabled:bg-slate-100"
                >
                  {(["salary", "savings", "property_sale", "loan", "business", "inheritance", "other"] as AmlSourceOfFundsCategory[]).map(
                    (c) => (
                      <option key={c} value={c}>
                        {t(`aml_sof_${c}`)}
                      </option>
                    )
                  )}
                </select>
              </div>
              <div className="sm:col-span-3">
                <label className="block text-xs font-semibold text-slate-700 mb-1">{t("aml_field_sof_desc")}</label>
                <input
                  disabled={isLockedReadOnly}
                  value={sourceOfFunds}
                  onChange={(e) => setSourceOfFunds(e.target.value)}
                  className="w-full h-9 px-2.5 rounded-lg border border-slate-300 text-xs disabled:bg-slate-100"
                />
              </div>
              <div className="sm:col-span-4">
                <label className="block text-xs font-semibold text-slate-700 mb-1">{t("aml_field_purpose")}</label>
                <input
                  disabled={isLockedReadOnly}
                  value={purpose}
                  onChange={(e) => setPurpose(e.target.value)}
                  className="w-full h-9 px-2.5 rounded-lg border border-slate-300 text-xs disabled:bg-slate-100"
                />
              </div>
            </div>
          </section>

          {/* Section 4: Private Document Vault */}
          <section className="space-y-3 border border-[#E5E3DF] rounded-xl p-4">
            <div className="flex items-center justify-between gap-2">
              <h4 className="text-xs font-bold uppercase tracking-wide text-[#1B5888]">{t("aml_sec_documents")}</h4>
              <span className="text-[11px] text-slate-500">{attachedDocs.length}</span>
            </div>
            <p className="text-[11px] text-slate-500">{t("aml_upload_hint")}</p>

            {!existing?.id || isSupersede ? (
              <div className="p-3 rounded-lg bg-slate-50 border border-dashed border-slate-300 text-xs text-slate-600">
                {t("aml_upload_save_first")}
              </div>
            ) : (
              <>
                {!isLockedReadOnly && (
                  <div className="flex flex-wrap items-center gap-2">
                    <select
                      value={uploadDocType}
                      onChange={(e) => setUploadDocType(e.target.value as AmlDocumentType)}
                      className="h-9 px-2.5 rounded-lg border border-slate-300 text-xs bg-white"
                    >
                      {(
                        [
                          "id_card",
                          "passport",
                          "apr_extract",
                          "ubo_declaration",
                          "source_of_funds",
                          "signed_upitnik",
                          "sanctions_check",
                          "other",
                        ] as AmlDocumentType[]
                      ).map((dt) => (
                        <option key={dt} value={dt}>
                          {t(`aml_att_type_${dt}`)}
                        </option>
                      ))}
                    </select>
                    <input
                      ref={fileInputRef}
                      type="file"
                      accept="application/pdf,image/jpeg,image/png,image/webp"
                      onChange={handleFileSelected}
                      className="hidden"
                    />
                    <button
                      type="button"
                      disabled={uploadingDoc}
                      onClick={() => fileInputRef.current?.click()}
                      className="h-9 px-3.5 rounded-lg bg-[#1B5888] text-white text-xs font-semibold hover:bg-[#16466d] transition-colors inline-flex items-center gap-1.5 cursor-pointer disabled:opacity-60"
                    >
                      <Upload className="w-3.5 h-3.5" />
                      <span>{uploadingDoc ? "..." : t("aml_upload_btn")}</span>
                    </button>
                  </div>
                )}

                {attachedDocs.length > 0 && (
                  <div className="divide-y divide-slate-100 border border-slate-200 rounded-lg overflow-hidden">
                    {attachedDocs.map((doc) => (
                      <div key={doc.id} className="px-3 py-2 flex items-center justify-between gap-2 bg-white text-xs">
                        <div className="flex items-center gap-2 min-w-0">
                          <FileText className="w-4 h-4 text-[#1B5888] shrink-0" />
                          <div className="min-w-0">
                            <div className="font-semibold text-slate-800 truncate">{doc.file_name}</div>
                            <div className="text-[11px] text-slate-500">{t(`aml_att_type_${doc.doc_type}`)}</div>
                          </div>
                        </div>
                        <div className="flex items-center gap-1.5 shrink-0">
                          <button
                            type="button"
                            onClick={() => onOpenDocument(doc)}
                            className="px-2.5 py-1 rounded-md bg-[#E5EEF6] text-[#1B5888] font-semibold hover:bg-[#1B5888] hover:text-white transition-colors inline-flex items-center gap-1 cursor-pointer"
                          >
                            <ExternalLink className="w-3 h-3" />
                            <span>{t("aml_doc_open_signed")}</span>
                          </button>
                          {!isLockedReadOnly && (
                            <button
                              type="button"
                              onClick={() => onDeleteDocument(doc)}
                              className="p-1.5 rounded-md text-red-500 hover:bg-red-50 cursor-pointer"
                            >
                              <Trash2 className="w-3.5 h-3.5" />
                            </button>
                          )}
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </>
            )}
          </section>

          {/* Section 5: Risk Summary & Decision */}
          <section className="space-y-3 border border-[#E5E3DF] rounded-xl p-4 bg-[#FAF9F7]">
            <div className="flex flex-wrap items-center justify-between gap-2">
              <div>
                <h4 className="text-xs font-bold uppercase tracking-wide text-[#1B5888]">{t("aml_sec_risk")}</h4>
                <p className="text-[11px] text-slate-500 mt-0.5">{t("aml_risk_thresholds_hint")}</p>
              </div>
              <span className={`text-xs font-bold px-2.5 py-1 rounded-full border ${riskBadgeClass}`}>
                {t(`aml_risk_${riskResult.level}`)} — {riskResult.score}/100
              </span>
            </div>

            {riskResult.factors.length > 0 ? (
              <div className="flex flex-wrap gap-1.5">
                {riskResult.factors.map((f) => (
                  <span
                    key={f.key}
                    className={`text-[11px] px-2 py-0.5 rounded-md border font-medium ${
                      f.autoHigh ? "bg-red-50 text-red-700 border-red-200" : "bg-white text-slate-700 border-slate-200"
                    }`}
                  >
                    {t(f.key)}{f.points > 0 ? ` (+${f.points})` : ""}
                  </span>
                ))}
              </div>
            ) : (
              <div className="text-[11px] text-emerald-700 font-medium">{t("aml_risk_no_factors")}</div>
            )}

            {!isLockedReadOnly && riskResult.autoLevel !== "high" && (
              <div className="p-3 rounded-lg bg-white border border-slate-200 space-y-1.5">
                <label className="block text-xs font-semibold text-slate-700">
                  {t("aml_manual_escalation_label")}
                </label>
                <select
                  value={manualRiskOverride}
                  onChange={(e) => setManualRiskOverride(e.target.value as "" | "medium" | "high")}
                  className="w-full sm:w-80 h-9 px-2.5 rounded-lg border border-slate-300 text-xs bg-white"
                >
                  <option value="">
                    {t("aml_manual_escalation_auto")} ({t(`aml_risk_${riskResult.autoLevel}`)})
                  </option>
                  {riskResult.autoLevel === "low" && (
                    <option value="medium">{t("aml_risk_medium")}</option>
                  )}
                  <option value="high">{t("aml_risk_high")}</option>
                </select>
                <p className="text-[11px] text-slate-500">{t("aml_manual_escalation_hint")}</p>
              </div>
            )}

            {!isLockedReadOnly && validation.warnings.length > 0 && (
              <div className="p-3 rounded-lg bg-amber-50 border border-amber-200 space-y-1">
                {validation.warnings.map((w) => (
                  <div key={w.key} className="text-xs text-amber-800 flex items-start gap-1.5">
                    <AlertTriangle className="w-3.5 h-3.5 shrink-0 mt-0.5" />
                    <span>{t(w.key)}</span>
                  </div>
                ))}
              </div>
            )}

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">{t("aml_field_edd_notes")}</label>
                <textarea
                  rows={2}
                  disabled={isLockedReadOnly}
                  value={eddNotes}
                  onChange={(e) => setEddNotes(e.target.value)}
                  className="w-full p-2.5 rounded-lg border border-slate-300 text-xs bg-white disabled:bg-slate-100"
                />
              </div>
              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">{t("aml_field_decision_notes")}</label>
                <textarea
                  rows={2}
                  disabled={isLockedReadOnly}
                  value={decisionNotes}
                  onChange={(e) => setDecisionNotes(e.target.value)}
                  className="w-full p-2.5 rounded-lg border border-slate-300 text-xs bg-white disabled:bg-slate-100"
                />
              </div>
            </div>

            {!isLockedReadOnly && !isAdmin && (
              <div className="text-[11px] text-slate-500 flex items-center gap-1.5">
                <Lock className="w-3.5 h-3.5" />
                <span>{t("aml_lock_admin_only")}</span>
              </div>
            )}
          </section>
        </div>

        {/* Footer */}
        <div className="px-5 py-3.5 border-t border-[#E5E3DF] bg-[#FAF9F7] flex flex-wrap items-center justify-between gap-2">
          <div className="flex items-center gap-2">
            {existing && !isSupersede && (
              <button
                type="button"
                onClick={() => printOfficialUpitnik(existing, agencyName, registryInfo, "SR_LAT")}
                className="px-3 py-2 rounded-lg border border-slate-300 bg-white text-xs font-semibold text-slate-700 hover:bg-slate-50 inline-flex items-center gap-1.5 cursor-pointer"
              >
                <Printer className="w-3.5 h-3.5" />
                <span>{t("aml_btn_print_upitnik")}</span>
              </button>
            )}
            {existing && !existing.is_locked && !isSupersede && isAdmin && onDeleteDraft && (
              <button
                type="button"
                onClick={async () => {
                  if (typeof window !== "undefined" && !window.confirm(t("aml_delete_draft_confirm"))) return;
                  await onDeleteDraft(existing);
                  onClose();
                }}
                className="px-3 py-2 rounded-lg border border-red-200 bg-red-50 text-xs font-semibold text-red-700 hover:bg-red-100 inline-flex items-center gap-1.5 cursor-pointer"
              >
                <Trash2 className="w-3.5 h-3.5" />
                <span>{t("aml_btn_delete_draft")}</span>
              </button>
            )}
          </div>

          <div className="flex flex-wrap items-center gap-2">
            {isLockedReadOnly && existing && onStartRevision && (
              <button
                type="button"
                onClick={() => onStartRevision(existing)}
                className="px-3.5 py-2 rounded-lg bg-[#1B5888] text-white text-xs font-semibold hover:bg-[#16466d] inline-flex items-center gap-1.5 cursor-pointer"
              >
                <CopyPlus className="w-3.5 h-3.5" />
                <span>{t("aml_btn_new_revision")}</span>
              </button>
            )}

            {!isLockedReadOnly && (
              <>
                <button
                  type="button"
                  disabled={submitting}
                  onClick={() => handleAction(null)}
                  className="px-3.5 py-2 rounded-lg border border-slate-300 bg-white text-xs font-semibold text-slate-700 hover:bg-slate-50 cursor-pointer disabled:opacity-60"
                >
                  {t("aml_btn_save_draft")}
                </button>
                {isAdmin && (
                  <>
                    <button
                      type="button"
                      disabled={submitting}
                      onClick={() => handleRequestLock("reject")}
                      className="px-3.5 py-2 rounded-lg border border-red-200 bg-red-50 text-xs font-semibold text-red-700 hover:bg-red-100 inline-flex items-center gap-1.5 cursor-pointer disabled:opacity-60"
                    >
                      <Lock className="w-3.5 h-3.5" />
                      <span>{t("aml_btn_reject_lock")}</span>
                    </button>
                    <button
                      type="button"
                      disabled={submitting}
                      onClick={() => handleRequestLock("approve")}
                      className="px-4 py-2 rounded-lg bg-[#1B5888] text-white text-xs font-semibold hover:bg-[#16466d] inline-flex items-center gap-1.5 cursor-pointer disabled:opacity-60"
                    >
                      <Lock className="w-3.5 h-3.5" />
                      <span>{t("aml_btn_lock_archive")}</span>
                    </button>
                  </>
                )}
              </>
            )}
          </div>
        </div>
      </div>

      {/* Transparent Risk Breakdown & 10-Year Lock Confirmation Dialog */}
      {pendingLockAction && (
        <div className="fixed inset-0 z-[60] flex items-center justify-center bg-slate-900/60 backdrop-blur-xs p-4">
          <div className="bg-white w-full max-w-lg rounded-2xl border border-[#E5E3DF] shadow-2xl overflow-hidden">
            <div className="px-5 py-4 border-b border-[#E5E3DF] bg-[#FAF9F7] flex items-center justify-between gap-3">
              <div className="flex items-center gap-2.5 min-w-0">
                <div className={`w-8 h-8 rounded-xl flex items-center justify-center shrink-0 ${pendingLockAction === "reject" ? "bg-red-100 text-red-700" : "bg-[#E5EEF6] text-[#1B5888]"}`}>
                  <Lock className="w-4 h-4" />
                </div>
                <h4 className="text-sm font-bold text-[#1A1A1A] truncate">
                  {pendingLockAction === "reject"
                    ? t("aml_lock_confirm_title_reject")
                    : t("aml_lock_confirm_title_approve")}
                </h4>
              </div>
              <button
                type="button"
                onClick={() => setPendingLockAction(null)}
                className="p-1 rounded-lg text-slate-400 hover:text-slate-700 cursor-pointer"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <div className="p-5 space-y-4 text-xs">
              <div className="flex items-center justify-between gap-2 p-3 rounded-xl border bg-[#FAF9F7] border-[#E5E3DF]">
                <div>
                  <div className="font-bold text-[#1A1A1A]">{clientName}</div>
                  <div className="text-[11px] text-slate-500 mt-0.5">{t("aml_risk_thresholds_hint")}</div>
                </div>
                <span className={`text-xs font-bold px-2.5 py-1 rounded-full border shrink-0 ${riskBadgeClass}`}>
                  {t(`aml_risk_${riskResult.level}`)} · {riskResult.score}/100
                </span>
              </div>

              <div className="space-y-1.5">
                <div className="font-bold text-slate-700">{t("aml_lock_confirm_breakdown")}</div>
                {riskResult.factors.length > 0 ? (
                  <ul className="space-y-1 bg-slate-50 border border-slate-200 rounded-xl p-3">
                    {riskResult.factors.map((f) => (
                      <li key={f.key} className="flex items-center justify-between gap-2">
                        <span className={f.autoHigh ? "text-red-700 font-semibold" : "text-slate-700"}>
                          • {t(f.key)}
                        </span>
                        <span className="font-mono font-bold text-slate-800 shrink-0">
                          {f.points > 0 ? `+${f.points}` : "OVERRIDE"}
                        </span>
                      </li>
                    ))}
                  </ul>
                ) : (
                  <div className="p-3 rounded-xl bg-emerald-50 border border-emerald-200 text-emerald-800">
                    {t("aml_risk_no_factors")}
                  </div>
                )}
              </div>

              {validation.warnings.length > 0 && (
                <div className="p-3 rounded-xl bg-amber-50 border border-amber-200 space-y-1">
                  {validation.warnings.map((w) => (
                    <div key={w.key} className="text-amber-800 flex items-start gap-1.5">
                      <AlertTriangle className="w-3.5 h-3.5 shrink-0 mt-0.5" />
                      <span>{t(w.key)}</span>
                    </div>
                  ))}
                </div>
              )}

              <div className="grid grid-cols-2 gap-2.5">
                <div className="p-2.5 rounded-xl bg-indigo-50 border border-indigo-200">
                  <div className="text-[10px] font-semibold text-indigo-700 uppercase">
                    {t("aml_lock_confirm_retention_label")}
                  </div>
                  <div className="text-xs font-bold text-indigo-900 mt-0.5 font-mono">
                    {riskResult.retentionUntil}
                  </div>
                </div>
                <div className="p-2.5 rounded-xl bg-slate-50 border border-slate-200">
                  <div className="text-[10px] font-semibold text-slate-600 uppercase">
                    {t("aml_lock_confirm_review_label")}
                  </div>
                  <div className="text-xs font-bold text-slate-900 mt-0.5 font-mono">
                    {riskResult.suggestedNextReviewAt}
                  </div>
                </div>
              </div>

              <p className="text-[11px] text-slate-600">{t("aml_lock_confirm")}</p>
            </div>

            <div className="px-5 py-3.5 border-t border-[#E5E3DF] bg-[#FAF9F7] flex items-center justify-end gap-2">
              <button
                type="button"
                disabled={submitting}
                onClick={() => setPendingLockAction(null)}
                className="px-3.5 py-2 rounded-lg border border-slate-300 bg-white text-xs font-semibold text-slate-700 hover:bg-slate-50 cursor-pointer"
              >
                {t("aml_lock_confirm_back")}
              </button>
              <button
                type="button"
                disabled={submitting}
                onClick={() => handleAction(pendingLockAction)}
                className={`px-4 py-2 rounded-lg text-white text-xs font-semibold inline-flex items-center gap-1.5 cursor-pointer disabled:opacity-60 ${
                  pendingLockAction === "reject" ? "bg-red-600 hover:bg-red-700" : "bg-[#1B5888] hover:bg-[#16466d]"
                }`}
              >
                <Lock className="w-3.5 h-3.5" />
                <span>{t("aml_lock_confirm_proceed")}</span>
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

export interface AmlTabProps {
  records: AmlRecord[];
  eopRecords: EopRecord[];
  agencyName: string;
  registryInfo: AgencyRegistryInfo;
  loading: boolean;
  onOpenModal: (prefill: AmlPrefill) => void;
  onCreateTask?: (prefill: AgencyTaskPrefill) => void;
  onOpenEopTab?: () => void;
  t: (key: string) => string;
}

export default function AmlTab({
  records,
  eopRecords,
  agencyName,
  registryInfo,
  loading,
  onOpenModal,
  onCreateTask,
  onOpenEopTab,
  t,
}: AmlTabProps) {
  const [search, setSearch] = useState("");
  const [riskFilter, setRiskFilter] = useState<"all" | AmlRiskLevel>("all");
  const [statusFilter, setStatusFilter] = useState<string>("all");
  const [printScript, setPrintScript] = useState<"SR_LAT" | "SR_CYR">("SR_LAT");

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase();
    return records.filter((r) => {
      if (riskFilter !== "all" && r.risk_level !== riskFilter) return false;
      if (statusFilter !== "all" && r.status !== statusFilter) return false;
      if (!q) return true;
      return (
        r.aml_ref_no.toLowerCase().includes(q) ||
        r.client_name_snapshot.toLowerCase().includes(q) ||
        (r.jmbg_pib_snapshot || "").toLowerCase().includes(q) ||
        (r.id_doc_number || "").toLowerCase().includes(q)
      );
    });
  }, [records, search, riskFilter, statusFilter]);

  const stats = useMemo(
    () => ({
      total: records.length,
      locked: records.filter((r) => r.is_locked).length,
      high: records.filter((r) => r.risk_level === "high" && r.status !== "superseded").length,
      draft: records.filter((r) => r.status === "draft").length,
    }),
    [records]
  );

  const eopById = useMemo(() => {
    const map = new Map<string, EopRecord>();
    eopRecords.forEach((e) => map.set(e.id, e));
    return map;
  }, [eopRecords]);

  return (
    <div id="tabpanel-aml" role="tabpanel" className="space-y-4">
      {/* KPI Strip */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
        <div className="bg-white rounded-xl border border-[#E5E3DF] p-3.5">
          <div className="text-[11px] font-semibold text-[#666666]">{t("aml_kpi_total")}</div>
          <div className="text-xl font-bold text-[#1A1A1A] mt-1 tabular-nums">{stats.total}</div>
        </div>
        <div className="bg-white rounded-xl border border-[#E5E3DF] p-3.5">
          <div className="text-[11px] font-semibold text-indigo-700 flex items-center gap-1">
            <Lock className="w-3.5 h-3.5" />
            <span>{t("aml_kpi_locked")}</span>
          </div>
          <div className="text-xl font-bold text-indigo-800 mt-1 tabular-nums">{stats.locked}</div>
        </div>
        <div className="bg-white rounded-xl border border-[#E5E3DF] p-3.5">
          <div className="text-[11px] font-semibold text-red-700 flex items-center gap-1">
            <ShieldAlert className="w-3.5 h-3.5" />
            <span>{t("aml_kpi_high_risk")}</span>
          </div>
          <div className="text-xl font-bold text-red-700 mt-1 tabular-nums">{stats.high}</div>
        </div>
        <div className="bg-white rounded-xl border border-[#E5E3DF] p-3.5">
          <div className="text-[11px] font-semibold text-amber-700 flex items-center gap-1">
            <Clock className="w-3.5 h-3.5" />
            <span>{t("aml_kpi_draft")}</span>
          </div>
          <div className="text-xl font-bold text-amber-800 mt-1 tabular-nums">{stats.draft}</div>
        </div>
      </div>

      {/* Toolbar */}
      <div className="bg-white rounded-xl border border-[#E5E3DF] p-3 flex flex-wrap items-center justify-between gap-2.5">
        <div className="flex flex-wrap items-center gap-2 flex-1 min-w-[240px]">
          <div className="relative flex-1 min-w-[200px] max-w-sm">
            <Search className="w-3.5 h-3.5 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
            <input
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder={t("aml_search_placeholder")}
              className="w-full h-9 pl-8 pr-3 rounded-lg border border-slate-200 text-xs focus:outline-none focus:border-[#1B5888]"
            />
          </div>
          <select
            value={riskFilter}
            onChange={(e) => setRiskFilter(e.target.value as any)}
            className="h-9 px-2.5 rounded-lg border border-slate-200 text-xs bg-white"
          >
            <option value="all">{t("aml_filter_all_risks")}</option>
            <option value="low">{t("aml_risk_low")}</option>
            <option value="medium">{t("aml_risk_medium")}</option>
            <option value="high">{t("aml_risk_high")}</option>
          </select>
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="h-9 px-2.5 rounded-lg border border-slate-200 text-xs bg-white"
          >
            <option value="all">{t("aml_filter_all_statuses")}</option>
            <option value="draft">{t("aml_status_draft")}</option>
            <option value="approved">{t("aml_status_approved")}</option>
            <option value="rejected">{t("aml_status_rejected")}</option>
            <option value="superseded">{t("aml_status_superseded")}</option>
          </select>
        </div>

        <div className="flex items-center gap-2">
          <div className="inline-flex rounded-lg border border-slate-200 overflow-hidden text-[11px] font-semibold">
            {(["SR_LAT", "SR_CYR"] as const).map((sc) => (
              <button
                key={sc}
                type="button"
                onClick={() => setPrintScript(sc)}
                className={`px-2 py-1.5 cursor-pointer ${
                  printScript === sc ? "bg-[#E5EEF6] text-[#1B5888]" : "bg-white text-slate-600"
                }`}
              >
                {sc === "SR_LAT" ? "LAT" : "ЋИР"}
              </button>
            ))}
          </div>
          <button
            type="button"
            onClick={() => onOpenModal({ mode: "create" })}
            className="h-9 px-3.5 rounded-lg bg-[#1B5888] text-white text-xs font-semibold hover:bg-[#16466d] transition-colors inline-flex items-center gap-1.5 cursor-pointer"
          >
            <Plus className="w-4 h-4" />
            <span>{t("aml_btn_new")}</span>
          </button>
        </div>
      </div>

      {/* Table / Empty State */}
      {loading ? (
        <div className="bg-white rounded-xl border border-[#E5E3DF] p-10 text-center text-xs text-slate-500">
          ...
        </div>
      ) : filtered.length === 0 ? (
        <div className="bg-white rounded-xl border border-[#E5E3DF] p-10 text-center space-y-2.5">
          <div className="w-11 h-11 rounded-2xl bg-[#E5EEF6] text-[#1B5888] mx-auto flex items-center justify-center">
            <ShieldCheck className="w-5 h-5" />
          </div>
          <h3 className="text-sm font-bold text-[#1A1A1A]">{t("aml_empty_title")}</h3>
          <p className="text-xs text-[#666666] max-w-md mx-auto">{t("aml_empty_desc")}</p>
          <button
            type="button"
            onClick={() => onOpenModal({ mode: "create" })}
            className="mt-2 px-4 py-2 rounded-lg bg-[#1B5888] text-white text-xs font-semibold hover:bg-[#16466d] inline-flex items-center gap-1.5 cursor-pointer"
          >
            <Plus className="w-3.5 h-3.5" />
            <span>{t("aml_btn_new")}</span>
          </button>
        </div>
      ) : (
        <div className="bg-white rounded-xl border border-[#E5E3DF] overflow-x-auto">
          <table className="w-full text-left border-collapse min-w-[820px]">
            <thead>
              <tr className="border-b border-[#E5E3DF] bg-[#FAF9F7] text-[11px] font-bold text-[#666666] uppercase">
                <th className="py-2.5 px-3">{t("aml_col_ref")}</th>
                <th className="py-2.5 px-3">{t("aml_col_client")}</th>
                <th className="py-2.5 px-3">{t("aml_col_transaction")}</th>
                <th className="py-2.5 px-3">{t("aml_col_risk")}</th>
                <th className="py-2.5 px-3">{t("aml_col_docs")}</th>
                <th className="py-2.5 px-3">{t("aml_col_archive")}</th>
                <th className="py-2.5 px-3 text-right">{t("aml_col_actions")}</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#F0EFEA] text-xs">
              {filtered.map((rec) => {
                const linkedEop = rec.eop_record_id ? eopById.get(rec.eop_record_id) : null;
                const riskCls =
                  rec.risk_level === "high"
                    ? "bg-red-50 text-red-700 border-red-200"
                    : rec.risk_level === "medium"
                      ? "bg-amber-50 text-amber-800 border-amber-200"
                      : "bg-emerald-50 text-emerald-700 border-emerald-200";
                return (
                  <tr key={rec.id} className="hover:bg-[#FAF9F7] transition-colors">
                    <td className="py-3 px-3 font-mono font-bold text-[#1B5888] whitespace-nowrap">
                      <div>{rec.aml_ref_no}</div>
                      <div className="text-[10px] font-sans font-normal text-slate-500">{rec.transaction_date}</div>
                    </td>
                    <td className="py-3 px-3">
                      <div className="font-semibold text-[#1A1A1A] flex items-center gap-1.5">
                        {rec.party_type === "company" ? (
                          <Building2 className="w-3.5 h-3.5 text-slate-400 shrink-0" />
                        ) : (
                          <User className="w-3.5 h-3.5 text-slate-400 shrink-0" />
                        )}
                        <span>{rec.client_name_snapshot}</span>
                        {rec.is_pep && (
                          <span className="text-[10px] font-bold px-1.5 py-0.5 rounded bg-red-100 text-red-700">PEP</span>
                        )}
                      </div>
                      <div className="text-[11px] text-slate-500">{rec.jmbg_pib_snapshot || "—"}</div>
                    </td>
                    <td className="py-3 px-3 whitespace-nowrap">
                      <div className="font-semibold text-slate-800">
                        {t(`eop_tx_${rec.transaction_type}`)}
                        {rec.transaction_value_eur != null
                          ? ` · €${Number(rec.transaction_value_eur).toLocaleString("de-DE")}`
                          : ""}
                      </div>
                      {linkedEop && onOpenEopTab && (
                        <button
                          type="button"
                          onClick={onOpenEopTab}
                          className="text-[10px] text-[#1B5888] hover:underline inline-flex items-center gap-1 cursor-pointer mt-0.5"
                        >
                          <BookOpen className="w-3 h-3" />
                          <span>EOP #{linkedEop.redni_broj}</span>
                        </button>
                      )}
                    </td>
                    <td className="py-3 px-3 whitespace-nowrap">
                      <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[11px] font-bold border ${riskCls}`}>
                        {t(`aml_risk_${rec.risk_level}`)} ({rec.risk_score})
                      </span>
                    </td>
                    <td className="py-3 px-3 whitespace-nowrap">
                      <span className="inline-flex items-center gap-1 text-slate-600 font-medium">
                        <FileText className="w-3.5 h-3.5 text-slate-400" />
                        <span>{rec.documents?.length || 0}</span>
                      </span>
                    </td>
                    <td className="py-3 px-3 whitespace-nowrap">
                      {rec.is_locked ? (
                        <div className="space-y-0.5">
                          <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[11px] font-semibold bg-indigo-50 text-indigo-700 border border-indigo-200">
                            <Lock className="w-3 h-3" />
                            <span>{t(`aml_status_${rec.status}`)}</span>
                          </span>
                          <div className="text-[10px] text-slate-500">{rec.retention_until || "—"}</div>
                        </div>
                      ) : (
                        <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[11px] font-semibold bg-amber-50 text-amber-800 border border-amber-200">
                          <CheckCircle2 className="w-3 h-3" />
                          <span>{t("aml_status_draft")}</span>
                        </span>
                      )}
                    </td>
                    <td className="py-3 px-3 text-right whitespace-nowrap">
                      <div className="inline-flex items-center gap-1.5">
                        <button
                          type="button"
                          onClick={() => onOpenModal({ mode: "edit", existingRecord: rec })}
                          className="px-2.5 py-1.5 rounded-lg border border-[#E5E3DF] bg-white hover:bg-[#E5EEF6] hover:text-[#1B5888] text-xs font-semibold cursor-pointer"
                        >
                          {rec.is_locked ? t("aml_btn_view") : t("aml_btn_edit")}
                        </button>
                        <button
                          type="button"
                          title={t("aml_btn_print_upitnik")}
                          onClick={() => printOfficialUpitnik(rec, agencyName, registryInfo, printScript)}
                          className="p-1.5 rounded-lg border border-[#E5E3DF] bg-white hover:bg-slate-100 text-slate-600 cursor-pointer"
                        >
                          <Printer className="w-3.5 h-3.5" />
                        </button>
                        {onCreateTask && rec.risk_level === "high" && rec.status !== "superseded" && (
                          <button
                            type="button"
                            title={t("aml_btn_create_review_task")}
                            onClick={() =>
                              onCreateTask({
                                source_type: "manual",
                                title: `AML EDD: ${rec.aml_ref_no} — ${rec.client_name_snapshot}`,
                                priority: "high",
                                property_id: rec.property_id || null,
                                listing_id: rec.listing_id || null,
                              })
                            }
                            className="p-1.5 rounded-lg border border-red-200 bg-red-50 hover:bg-red-100 text-red-700 cursor-pointer"
                          >
                            <ClipboardList className="w-3.5 h-3.5" />
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
