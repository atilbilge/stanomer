"use client";

import React, { useMemo, useState, useEffect, useRef } from "react";
import {
  BookOpen,
  Plus,
  Printer,
  Download,
  Search,
  CheckCircle2,
  XCircle,
  Clock,
  Pencil,
  X,
  Building2,
  User,
  FileText,
  ShieldCheck,
  AlertTriangle,
  ChevronDown,
} from "lucide-react";
import translationsJson from "../../../lib/translations.json";
import {
  AgencyClient,
  AgencyListingRow,
  AgencyManagedProperty,
  AgencyPartyType,
  AgencyRegistryInfo,
  AmlPrefill,
  AmlRecord,
  EopClientRole,
  EopCommissionType,
  EopPrefill,
  EopRecord,
  EopStatus,
} from "../types";
import { findMatchingAmlForEop, findRejectedAmlForContext, isAmlMandatoryForEop } from "../../../lib/amlRiskEngine";

const TRANSLATIONS: Record<string, Record<string, string>> = translationsJson as Record<
  string,
  Record<string, string>
>;

export interface EopFormModalProps {
  isOpen: boolean;
  prefill: EopPrefill | null;
  clients: AgencyClient[];
  listings: AgencyListingRow[];
  managedProperties: AgencyManagedProperty[];
  existingRecords?: EopRecord[];
  amlRecords?: AmlRecord[];
  onClose: () => void;
  onSave: (payload: {
    id?: string;
    saveClientToDirectory?: boolean;
    record: Omit<EopRecord, "id" | "agency_id" | "sequence_year" | "sequence_number" | "redni_broj" | "created_at" | "updated_at">;
  }) => Promise<void>;
  onAddCounterparty?: (prefill: EopPrefill) => void;
  t: (key: string) => string;
}

function getLocalTodayIso(): string {
  const now = new Date();
  const local = new Date(now.getTime() - now.getTimezoneOffset() * 60000);
  return local.toISOString().split("T")[0];
}

export function EopFormModal({
  isOpen,
  prefill,
  clients,
  listings,
  managedProperties,
  existingRecords = [],
  amlRecords = [],
  onClose,
  onSave,
  onAddCounterparty,
  t,
}: EopFormModalProps) {
  const existing = prefill?.existingRecord || null;
  const mode = prefill?.mode || (existing ? "edit" : "create");
  const isClosedRecord = Boolean(
    existing && (existing.status === "realized" || existing.status === "cancelled")
  );

  const todayStr = getLocalTodayIso();

  const [selectedClientId, setSelectedClientId] = useState<string>("");
  const [partyType, setPartyType] = useState<AgencyPartyType>("individual");
  const [clientName, setClientName] = useState("");
  const [clientJmbgPib, setClientJmbgPib] = useState("");
  const [clientAddress, setClientAddress] = useState("");
  const [clientPhone, setClientPhone] = useState("");
  const [clientEmail, setClientEmail] = useState("");

  const [contractNo, setContractNo] = useState("");
  const [contractDate, setContractDate] = useState(todayStr);
  const [validUntil, setValidUntil] = useState("");
  const [isExclusive, setIsExclusive] = useState(false);
  const [clientRole, setClientRole] = useState<EopClientRole>("landlord");
  const [transactionType, setTransactionType] = useState<"prodaja" | "izdavanje">("izdavanje");
  const [status, setStatus] = useState<EopStatus>("active");
  const [cancellationReason, setCancellationReason] = useState("");

  const [listingId, setListingId] = useState<string>("");
  const [propertyId, setPropertyId] = useState<string>("");
  const [leaseContractId, setLeaseContractId] = useState<string>("");

  const [propertyType, setPropertyType] = useState("apartment");
  const [propertyAddress, setPropertyAddress] = useState("");
  const [propertySpecs, setPropertySpecs] = useState("");
  const [askingPrice, setAskingPrice] = useState("");
  const [agreedPrice, setAgreedPrice] = useState("");
  const [currency, setCurrency] = useState("EUR");
  const [commissionType, setCommissionType] = useState<EopCommissionType>("percent");
  const [commissionValue, setCommissionValue] = useState("");
  const [commissionCurrency, setCommissionCurrency] = useState("EUR");
  const [realizedAt, setRealizedAt] = useState("");
  const [invoiceRef, setInvoiceRef] = useState("");
  const [notes, setNotes] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  useEffect(() => {
    if (!isOpen) return;
    setErrorMsg(null);
    if (existing) {
      setSelectedClientId(existing.client_id || "");
      setPartyType(existing.client_type || "individual");
      setClientName(existing.client_name_snapshot || "");
      setClientJmbgPib(existing.client_jmbg_pib_snapshot || "");
      setClientAddress(existing.client_address_snapshot || "");
      setClientPhone(existing.client_phone_snapshot || "");
      setClientEmail(existing.client_email_snapshot || "");
      setContractNo(existing.mediation_contract_no || "");
      setContractDate(existing.mediation_contract_date || todayStr);
      setValidUntil(existing.contract_valid_until || "");
      setIsExclusive(Boolean(existing.is_exclusive));
      setClientRole(existing.client_role || "landlord");
      setTransactionType(existing.transaction_type || "izdavanje");
      setStatus(
        mode === "realize" ? "realized" : mode === "cancel" ? "cancelled" : existing.status || "active"
      );
      setCancellationReason(existing.cancellation_reason || "");
      setListingId(prefill?.listing_id ?? existing.listing_id ?? "");
      setPropertyId(prefill?.property_id ?? existing.property_id ?? "");
      setLeaseContractId(prefill?.lease_contract_id ?? existing.lease_contract_id ?? "");
      setPropertyType(existing.property_type_snapshot || "apartment");
      setPropertyAddress(existing.property_address_snapshot || "");
      setPropertySpecs(existing.property_specs_snapshot || "");
      setAskingPrice(existing.asking_price != null ? String(existing.asking_price) : "");
      setAgreedPrice(
        prefill?.agreed_price != null
          ? String(prefill.agreed_price)
          : existing.agreed_price != null
            ? String(existing.agreed_price)
            : mode === "realize" && existing.asking_price != null
              ? String(existing.asking_price)
              : ""
      );
      setCurrency(existing.currency || "EUR");
      setCommissionType(existing.commission_type || "percent");
      setCommissionValue(existing.commission_value != null ? String(existing.commission_value) : "");
      setCommissionCurrency(existing.commission_currency || existing.currency || "EUR");
      setRealizedAt(
        prefill?.realized_at ||
        existing.realized_at ||
        (mode === "realize" ? todayStr : "")
      );
      setInvoiceRef(existing.invoice_ref || "");
      setNotes(existing.notes || "");
    } else {
      const year = new Date().getFullYear();
      setSelectedClientId(prefill?.client_id || "");
      setPartyType(prefill?.client_type || "individual");
      setClientName(prefill?.client_name || "");
      setClientJmbgPib(prefill?.client_jmbg_pib || "");
      setClientAddress(prefill?.client_address || "");
      setClientPhone(prefill?.client_phone || "");
      setClientEmail(prefill?.client_email || "");
      setContractNo(`UP-${Math.floor(100 + Math.random() * 900)}/${year}`);
      setContractDate(todayStr);
      setValidUntil("");
      setIsExclusive(false);
      setClientRole(prefill?.client_role || "landlord");
      setTransactionType(prefill?.transaction_type || "izdavanje");
      setStatus(prefill?.status || "active");
      setCancellationReason("");
      setListingId(prefill?.listing_id || "");
      setPropertyId(prefill?.property_id || "");
      setLeaseContractId(prefill?.lease_contract_id || "");
      setPropertyType(prefill?.property_type || "apartment");
      setPropertyAddress(prefill?.property_address || "");
      setPropertySpecs(prefill?.property_specs || "");
      setAskingPrice(prefill?.asking_price != null ? String(prefill.asking_price) : "");
      setAgreedPrice(prefill?.agreed_price != null ? String(prefill.agreed_price) : "");
      setCurrency(prefill?.currency || "EUR");
      setCommissionType("percent");
      setCommissionValue(prefill?.transaction_type === "prodaja" ? "2" : "50");
      setCommissionCurrency(prefill?.currency || "EUR");
      setRealizedAt(prefill?.realized_at || (prefill?.status === "realized" ? todayStr : ""));
      setInvoiceRef("");
      setNotes(prefill?.notes || "");
    }
  }, [isOpen, prefill, existing, mode, todayStr]);

  const softWarnings = useMemo(() => {
    const warnings: string[] = [];
    const others = existingRecords.filter((r) => r.id !== existing?.id);

    // 1. Active EOP already exists on same property / listing (soft warning — multi-party allowed)
    if (!existing && (propertyId || listingId)) {
      const matchingActive = others.filter(
        (r) =>
          r.status === "active" &&
          ((propertyId && r.property_id === propertyId) ||
            (listingId && r.listing_id === listingId))
      );
      if (matchingActive.length > 0) {
        const refs = matchingActive
          .slice(0, 3)
          .map((r) => `#${r.redni_broj} (${r.client_name_snapshot})`)
          .join(", ");
        warnings.push(`${t("eop_warn_active_exists")} [${refs}]`);
      }

      // 2. Exclusive mandate conflict on same property/listing + transaction type
      if (clientRole === "landlord" || clientRole === "seller") {
        const hasExclusive = matchingActive.some(
          (r) =>
            r.is_exclusive &&
            r.transaction_type === transactionType &&
            (r.client_role === "landlord" || r.client_role === "seller")
        );
        if (hasExclusive) {
          warnings.push(t("eop_warn_exclusive_conflict"));
        }
      }
    }

    // 3. Exact duplicate (same contract_no + client_name + property_address)
    if (!existing && contractNo.trim() && clientName.trim() && propertyAddress.trim()) {
      const cNo = contractNo.trim().toLowerCase();
      const cName = clientName.trim().toLowerCase();
      const pAddr = propertyAddress.trim().toLowerCase();
      const hasDup = others.some(
        (r) =>
          r.status !== "cancelled" &&
          r.mediation_contract_no.trim().toLowerCase() === cNo &&
          r.client_name_snapshot.trim().toLowerCase() === cName &&
          r.property_address_snapshot.trim().toLowerCase() === pAddr
      );
      if (hasDup) {
        warnings.push(t("eop_warn_duplicate_contract"));
      }
    }

    // 4. Realized without agreed_price
    if (status === "realized" && !agreedPrice.trim()) {
      warnings.push(t("eop_warn_realized_no_price"));
    }

    // 5. Realized date earlier than mediation contract date
    if (status === "realized" && realizedAt && contractDate && realizedAt < contractDate) {
      warnings.push(t("eop_warn_realized_before_contract"));
    }

    // 6. Serbian company PIB format (9 digits)
    if (partyType === "company" && clientJmbgPib.trim() && !/^\d{9}$/.test(clientJmbgPib.trim())) {
      warnings.push(t("eop_warn_pib_format"));
    }

    // 7. Client has a locked AML/SPN REJECTED decision
    const rejectedAml = findRejectedAmlForContext(amlRecords, {
      clientId: selectedClientId || null,
      clientNames: [clientName],
      jmbgPib: clientJmbgPib,
      listingId: listingId || null,
      propertyId: propertyId || null,
    });
    if (rejectedAml) {
      warnings.unshift(`${t("aml_warn_client_rejected")} [${rejectedAml.aml_ref_no}]`);
    }

    return warnings;
  }, [
    existingRecords,
    amlRecords,
    selectedClientId,
    existing?.id,
    propertyId,
    listingId,
    clientRole,
    transactionType,
    contractNo,
    clientName,
    propertyAddress,
    status,
    agreedPrice,
    realizedAt,
    contractDate,
    partyType,
    clientJmbgPib,
    t,
  ]);

  if (!isOpen) return null;

  const handleSelectClient = (cid: string) => {
    setSelectedClientId(cid);
    if (!cid) return;
    const found = clients.find((c) => c.id === cid);
    if (found) {
      setPartyType(found.party_type);
      setClientName(found.full_name);
      setClientJmbgPib(found.jmbg_pib || "");
      setClientAddress(found.address || "");
      setClientPhone(found.phone || "");
      setClientEmail(found.email || "");
    }
  };

  const saveRecord = async (addCounterpartyAfter = false) => {
    if (!contractNo.trim() || !clientName.trim() || !propertyAddress.trim()) {
      setErrorMsg(t("eop_val_required"));
      return;
    }
    if (validUntil && contractDate && validUntil < contractDate) {
      setErrorMsg(t("eop_val_valid_until_before_contract"));
      return;
    }
    if (status === "cancelled" && !cancellationReason.trim()) {
      setErrorMsg(t("eop_val_cancel_reason_required"));
      return;
    }
    setSubmitting(true);
    setErrorMsg(null);
    try {
      const normalizedRealizedAt = status === "realized" ? realizedAt || todayStr : null;
      await onSave({
        id: existing?.id,
        saveClientToDirectory: !selectedClientId,
        record: {
          mediation_contract_no: contractNo.trim(),
          mediation_contract_date: contractDate || todayStr,
          contract_valid_until: validUntil || null,
          is_exclusive: isExclusive,
          client_role: clientRole,
          transaction_type: transactionType,
          status,
          cancellation_reason: status === "cancelled" ? cancellationReason.trim() || null : null,
          client_id: selectedClientId || null,
          listing_id: listingId || null,
          property_id: propertyId || null,
          lease_contract_id: leaseContractId || null,
          client_type: partyType,
          client_name_snapshot: clientName.trim(),
          client_jmbg_pib_snapshot: clientJmbgPib.trim() || null,
          client_address_snapshot: clientAddress.trim() || null,
          client_phone_snapshot: clientPhone.trim() || null,
          client_email_snapshot: clientEmail.trim() || null,
          property_type_snapshot: propertyType || null,
          property_address_snapshot: propertyAddress.trim(),
          property_specs_snapshot: propertySpecs.trim() || null,
          asking_price: askingPrice ? Number(askingPrice) : null,
          agreed_price: agreedPrice ? Number(agreedPrice) : null,
          currency: currency || "EUR",
          commission_type: commissionType,
          commission_value: commissionValue ? Number(commissionValue) : null,
          commission_currency: commissionCurrency || currency || "EUR",
          realized_at: normalizedRealizedAt,
          invoice_ref: invoiceRef.trim() || null,
          contract_pdf_url: existing?.contract_pdf_url || null,
          notes: notes.trim() || null,
          created_by: existing?.created_by || null,
        },
      });
      if (addCounterpartyAfter && onAddCounterparty) {
        const flippedRole: EopClientRole =
          clientRole === "seller"
            ? "buyer"
            : clientRole === "buyer"
              ? "seller"
              : clientRole === "landlord"
                ? "tenant"
                : "landlord";
        onAddCounterparty({
          mode: "create",
          status: "realized",
          listing_id: listingId || null,
          property_id: propertyId || null,
          lease_contract_id: leaseContractId || null,
          transaction_type: transactionType,
          client_role: flippedRole,
          property_type: propertyType || "apartment",
          property_address: propertyAddress.trim(),
          property_specs: propertySpecs.trim(),
          asking_price: askingPrice ? Number(askingPrice) : null,
          agreed_price: agreedPrice ? Number(agreedPrice) : null,
          currency: currency || "EUR",
          realized_at: normalizedRealizedAt,
        });
      } else {
        onClose();
      }
    } catch (err: any) {
      setErrorMsg(err?.message || t("eop_msg_error"));
    } finally {
      setSubmitting(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    await saveRecord(false);
  };

  const modalTitle =
    mode === "realize"
      ? t("eop_modal_title_realize")
      : mode === "cancel"
        ? t("eop_modal_title_cancel")
        : existing
          ? `${t("eop_modal_title_edit")} (${existing.redni_broj})`
          : t("eop_modal_title_new");

  return (
    <div className="fixed inset-0 z-[80] flex items-center justify-center bg-slate-900/60 backdrop-blur-sm p-4 print:hidden">
      <div className="bg-white rounded-2xl shadow-2xl border border-[#E5E3DF] w-full max-w-2xl max-h-[90vh] flex flex-col overflow-hidden">
        <div className="px-6 py-4 border-b border-slate-100 flex items-center justify-between bg-[#F8F7F5]">
          <div className="flex items-center gap-2.5">
            <div className="w-9 h-9 rounded-xl bg-[#E5EEF6] text-[#1B5888] flex items-center justify-center">
              <BookOpen className="w-4 h-4" />
            </div>
            <h3 className="text-base font-bold text-[#1A1A1A]">{modalTitle}</h3>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="p-1.5 rounded-lg text-slate-400 hover:text-[#666666] hover:bg-slate-100"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="overflow-y-auto p-6 space-y-5">
          {errorMsg && (
            <div className="p-3 rounded-xl bg-rose-50 border border-rose-200 text-xs font-medium text-rose-700 flex items-center gap-2">
              <AlertTriangle className="w-4 h-4 shrink-0" />
              <span>{errorMsg}</span>
            </div>
          )}

          {isClosedRecord && (
            <div className="p-3 rounded-xl bg-slate-100 border border-[#E5E3DF] text-xs font-medium text-[#4A4A4A] flex items-start gap-2">
              <ShieldCheck className="w-4 h-4 shrink-0 text-[#666666] mt-0.5" />
              <span>{t("eop_warn_closed_record_locked")}</span>
            </div>
          )}

          {softWarnings.length > 0 && (
            <div className="p-3 rounded-xl bg-[#FBF1DC] border border-[#8A5206]/20 text-xs text-[#8A5206] space-y-1.5">
              {softWarnings.map((w, idx) => (
                <div key={idx} className="flex items-start gap-2">
                  <AlertTriangle className="w-3.5 h-3.5 shrink-0 text-[#8A5206] mt-0.5" />
                  <span>{w}</span>
                </div>
              ))}
            </div>
          )}

          {/* Mediation Contract Details */}
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
            <div>
              <label className="block text-xs font-semibold text-[#4A4A4A] mb-1">
                {t("eop_field_contract_no")} *
              </label>
              <input
                type="text"
                value={contractNo}
                onChange={(e) => setContractNo(e.target.value)}
                disabled={isClosedRecord}
                required
                className="w-full px-3 py-2 text-sm border border-[#E5E3DF] rounded-xl focus:outline-none focus:ring-2 focus:ring-[#1B5888]/20 focus:border-[#1B5888] disabled:bg-slate-100 disabled:text-[#666666]"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-[#4A4A4A] mb-1">
                {t("eop_field_contract_date")} *
              </label>
              <input
                type="date"
                value={contractDate}
                onChange={(e) => setContractDate(e.target.value)}
                disabled={isClosedRecord}
                required
                className="w-full px-3 py-2 text-sm border border-[#E5E3DF] rounded-xl focus:outline-none focus:ring-2 focus:ring-[#1B5888]/20 focus:border-[#1B5888] disabled:bg-slate-100 disabled:text-[#666666]"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-[#4A4A4A] mb-1">
                {t("eop_field_valid_until")}
              </label>
              <input
                type="date"
                value={validUntil}
                onChange={(e) => setValidUntil(e.target.value)}
                disabled={isClosedRecord}
                className="w-full px-3 py-2 text-sm border border-[#E5E3DF] rounded-xl focus:outline-none focus:ring-2 focus:ring-[#1B5888]/20 focus:border-[#1B5888] disabled:bg-slate-100 disabled:text-[#666666]"
              />
            </div>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
            <div>
              <label className="block text-xs font-semibold text-[#4A4A4A] mb-1">
                {t("eop_field_tx_type")}
              </label>
              <select
                value={transactionType}
                disabled={isClosedRecord}
                onChange={(e) => {
                  const nextTx = e.target.value as "prodaja" | "izdavanje";
                  setTransactionType(nextTx);
                  if (nextTx === "prodaja" && (clientRole === "landlord" || clientRole === "tenant")) {
                    setClientRole(clientRole === "landlord" ? "seller" : "buyer");
                  } else if (nextTx === "izdavanje" && (clientRole === "seller" || clientRole === "buyer")) {
                    setClientRole(clientRole === "seller" ? "landlord" : "tenant");
                  }
                }}
                className="w-full px-3 py-2 text-sm border border-[#E5E3DF] rounded-xl bg-white disabled:bg-slate-100 disabled:text-[#666666]"
              >
                <option value="izdavanje">{t("eop_tx_izdavanje")}</option>
                <option value="prodaja">{t("eop_tx_prodaja")}</option>
              </select>
            </div>
            <div>
              <label className="block text-xs font-semibold text-[#4A4A4A] mb-1">
                {t("eop_field_client_role")}
              </label>
              <select
                value={clientRole}
                disabled={isClosedRecord}
                onChange={(e) => setClientRole(e.target.value as EopClientRole)}
                className="w-full px-3 py-2 text-sm border border-[#E5E3DF] rounded-xl bg-white disabled:bg-slate-100 disabled:text-[#666666]"
              >
                {transactionType === "prodaja" ? (
                  <>
                    <option value="seller">{t("eop_role_seller")}</option>
                    <option value="buyer">{t("eop_role_buyer")}</option>
                  </>
                ) : (
                  <>
                    <option value="landlord">{t("eop_role_landlord")}</option>
                    <option value="tenant">{t("eop_role_tenant")}</option>
                  </>
                )}
              </select>
            </div>
            <div>
              <label className="block text-xs font-semibold text-[#4A4A4A] mb-1">
                {t("eop_field_status")}
              </label>
              <select
                value={status}
                disabled={existing?.status === "cancelled"}
                onChange={(e) => setStatus(e.target.value as EopStatus)}
                className="w-full px-3 py-2 text-sm border border-[#E5E3DF] rounded-xl bg-white disabled:bg-slate-100 disabled:text-[#666666]"
              >
                {!isClosedRecord && <option value="active">{t("eop_status_active")}</option>}
                {existing?.status !== "cancelled" && (
                  <option value="realized">{t("eop_status_realized")}</option>
                )}
                <option value="cancelled">{t("eop_status_cancelled")}</option>
              </select>
            </div>
          </div>

          <label className="inline-flex items-center gap-2 text-xs font-medium text-[#4A4A4A] cursor-pointer">
            <input
              type="checkbox"
              checked={isExclusive}
              disabled={isClosedRecord}
              onChange={(e) => setIsExclusive(e.target.checked)}
              className="rounded border-[#E5E3DF] text-[#1B5888] focus:ring-[#1B5888] disabled:opacity-50"
            />
            <span>{t("eop_field_is_exclusive")}</span>
          </label>

          {/* Client (Nalogodavac) Section */}
          <div className="p-4 rounded-xl bg-[#F8F7F5] border border-[#E5E3DF] space-y-3">
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <div>
                <label className="block text-xs font-semibold text-[#4A4A4A] mb-1">
                  {t("eop_field_client_select")}
                </label>
                <select
                  value={selectedClientId}
                  disabled={isClosedRecord}
                  onChange={(e) => handleSelectClient(e.target.value)}
                  className="w-full px-3 py-2 text-sm border border-[#E5E3DF] rounded-xl bg-white disabled:bg-slate-100 disabled:text-[#666666]"
                >
                  <option value="">{t("eop_field_client_new_option")}</option>
                  {clients.map((c) => (
                    <option key={c.id} value={c.id}>
                      {c.full_name} {c.jmbg_pib ? `(${c.jmbg_pib})` : ""}
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <label className="block text-xs font-semibold text-[#4A4A4A] mb-1">
                  {t("eop_field_party_type")}
                </label>
                <select
                  value={partyType}
                  disabled={isClosedRecord}
                  onChange={(e) => setPartyType(e.target.value as AgencyPartyType)}
                  className="w-full px-3 py-2 text-sm border border-[#E5E3DF] rounded-xl bg-white disabled:bg-slate-100 disabled:text-[#666666]"
                >
                  <option value="individual">{t("eop_party_individual")}</option>
                  <option value="company">{t("eop_party_company")}</option>
                </select>
              </div>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <div>
                <label className="block text-xs font-semibold text-[#4A4A4A] mb-1">
                  {t("eop_field_client_name")} *
                </label>
                <input
                  type="text"
                  value={clientName}
                  onChange={(e) => setClientName(e.target.value)}
                  disabled={isClosedRecord}
                  required
                  className="w-full px-3 py-2 text-sm border border-[#E5E3DF] rounded-xl bg-white disabled:bg-slate-100 disabled:text-[#666666]"
                />
              </div>
              <div>
                <label className="block text-xs font-semibold text-[#4A4A4A] mb-1">
                  {t("eop_field_client_jmbg_pib")}
                </label>
                <input
                  type="text"
                  value={clientJmbgPib}
                  onChange={(e) => setClientJmbgPib(e.target.value)}
                  className="w-full px-3 py-2 text-sm border border-[#E5E3DF] rounded-xl bg-white"
                />
              </div>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
              <div>
                <label className="block text-xs font-semibold text-[#4A4A4A] mb-1">
                  {t("eop_field_client_address")}
                </label>
                <input
                  type="text"
                  value={clientAddress}
                  onChange={(e) => setClientAddress(e.target.value)}
                  className="w-full px-3 py-2 text-sm border border-[#E5E3DF] rounded-xl bg-white"
                />
              </div>
              <div>
                <label className="block text-xs font-semibold text-[#4A4A4A] mb-1">
                  {t("eop_field_client_phone")}
                </label>
                <input
                  type="text"
                  value={clientPhone}
                  onChange={(e) => setClientPhone(e.target.value)}
                  className="w-full px-3 py-2 text-sm border border-[#E5E3DF] rounded-xl bg-white"
                />
              </div>
              <div>
                <label className="block text-xs font-semibold text-[#4A4A4A] mb-1">
                  {t("eop_field_client_email")}
                </label>
                <input
                  type="email"
                  value={clientEmail}
                  onChange={(e) => setClientEmail(e.target.value)}
                  className="w-full px-3 py-2 text-sm border border-[#E5E3DF] rounded-xl bg-white"
                />
              </div>
            </div>
          </div>

          {/* Optional System Links (Listing / Managed Property) */}
          {(listings.length > 0 || managedProperties.length > 0) && (
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              {listings.length > 0 && (
                <div>
                  <label className="block text-xs font-semibold text-[#4A4A4A] mb-1">
                    {t("eop_field_linked_listing")}
                  </label>
                  <select
                    value={listingId}
                    disabled={isClosedRecord}
                    onChange={(e) => {
                      const lid = e.target.value;
                      setListingId(lid);
                      if (!lid) return;
                      const found = listings.find((l) => l.id === lid);
                      if (found) {
                        if (!propertyId && found.managed_property_id) {
                          setPropertyId(found.managed_property_id);
                        }
                        if (!propertyAddress.trim()) {
                          const addr = [found.address, found.neighborhood, found.municipality, found.city]
                            .filter(Boolean)
                            .join(", ");
                          setPropertyAddress(addr || found.title || "");
                        }
                        if (!propertySpecs.trim()) {
                          const specs = [
                            found.area_sqm ? `${found.area_sqm} m²` : null,
                            found.room_count || null,
                            found.floor ? `${found.floor}` : null,
                          ].filter(Boolean).join(", ");
                          setPropertySpecs(specs);
                        }
                        if (!askingPrice && found.price != null) {
                          setAskingPrice(String(found.price));
                        }
                        if (found.currency) setCurrency(found.currency);
                        if (found.property_type) setPropertyType(found.property_type);
                        setTransactionType(found.transaction_type === "prodaja" ? "prodaja" : "izdavanje");
                      }
                    }}
                    className="w-full px-3 py-2 text-sm border border-[#E5E3DF] rounded-xl bg-white"
                  >
                    <option value="">{t("eop_field_link_none")}</option>
                    {listings.map((l) => (
                      <option key={l.id} value={l.id}>
                        {l.title || l.address || l.id}
                      </option>
                    ))}
                  </select>
                </div>
              )}
              {managedProperties.length > 0 && (
                <div>
                  <label className="block text-xs font-semibold text-[#4A4A4A] mb-1">
                    {t("eop_field_linked_property")}
                  </label>
                  <select
                    value={propertyId}
                    disabled={isClosedRecord}
                    onChange={(e) => {
                      const pid = e.target.value;
                      setPropertyId(pid);
                      if (!pid) return;
                      const found = managedProperties.find((p) => p.id === pid);
                      if (found) {
                        if (!listingId && found.last_listing_id) {
                          setListingId(found.last_listing_id);
                        }
                        if (!propertyAddress.trim()) {
                          const addr = [found.address, found.unit_number ? `#${found.unit_number}` : null, found.city]
                            .filter(Boolean)
                            .join(", ");
                          setPropertyAddress(addr || found.title || "");
                        }
                        if (!propertySpecs.trim()) {
                          const specs = [
                            found.area_sqm ? `${found.area_sqm} m²` : null,
                            found.room_count || null,
                            found.floor ? `${found.floor}` : null,
                          ].filter(Boolean).join(", ");
                          setPropertySpecs(specs);
                        }
                        if (!askingPrice && found.default_monthly_rent != null) {
                          setAskingPrice(String(found.default_monthly_rent));
                        }
                        if (found.currency) setCurrency(found.currency);
                        if (found.property_type) setPropertyType(found.property_type);
                      }
                    }}
                    className="w-full px-3 py-2 text-sm border border-[#E5E3DF] rounded-xl bg-white"
                  >
                    <option value="">{t("eop_field_link_none")}</option>
                    {managedProperties.map((p) => (
                      <option key={p.id} value={p.id}>
                        {p.title || p.address || p.id}
                      </option>
                    ))}
                  </select>
                </div>
              )}
            </div>
          )}

          {/* Property Snapshot Section */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div className="sm:col-span-2">
              <label className="block text-xs font-semibold text-[#4A4A4A] mb-1">
                {t("eop_field_property_address")} *
              </label>
              <input
                type="text"
                value={propertyAddress}
                onChange={(e) => setPropertyAddress(e.target.value)}
                disabled={isClosedRecord}
                required
                className="w-full px-3 py-2 text-sm border border-[#E5E3DF] rounded-xl disabled:bg-slate-100 disabled:text-[#666666]"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-[#4A4A4A] mb-1">
                {t("eop_field_property_type")}
              </label>
              <input
                type="text"
                value={propertyType}
                onChange={(e) => setPropertyType(e.target.value)}
                className="w-full px-3 py-2 text-sm border border-[#E5E3DF] rounded-xl"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-[#4A4A4A] mb-1">
                {t("eop_field_property_specs")}
              </label>
              <input
                type="text"
                value={propertySpecs}
                onChange={(e) => setPropertySpecs(e.target.value)}
                className="w-full px-3 py-2 text-sm border border-[#E5E3DF] rounded-xl"
              />
            </div>
          </div>

          {/* Financial & Commission */}
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
            <div>
              <label className="block text-xs font-semibold text-[#4A4A4A] mb-1">
                {t("eop_field_asking_price")}
              </label>
              <input
                type="number"
                step="0.01"
                value={askingPrice}
                onChange={(e) => setAskingPrice(e.target.value)}
                className="w-full px-3 py-2 text-sm border border-[#E5E3DF] rounded-xl"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-[#4A4A4A] mb-1">
                {t("eop_field_agreed_price")}
              </label>
              <input
                type="number"
                step="0.01"
                value={agreedPrice}
                onChange={(e) => setAgreedPrice(e.target.value)}
                className="w-full px-3 py-2 text-sm border border-[#E5E3DF] rounded-xl"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-[#4A4A4A] mb-1">
                {t("eop_field_currency")}
              </label>
              <select
                value={currency}
                onChange={(e) => setCurrency(e.target.value)}
                className="w-full px-3 py-2 text-sm border border-[#E5E3DF] rounded-xl bg-white"
              >
                <option value="EUR">EUR</option>
                <option value="RSD">RSD</option>
                <option value="USD">USD</option>
              </select>
            </div>
            <div>
              <label className="block text-xs font-semibold text-[#4A4A4A] mb-1">
                {t("eop_field_commission_type")}
              </label>
              <select
                value={commissionType}
                onChange={(e) => setCommissionType(e.target.value as EopCommissionType)}
                className="w-full px-3 py-2 text-sm border border-[#E5E3DF] rounded-xl bg-white"
              >
                <option value="percent">{t("eop_comm_percent")}</option>
                <option value="fixed">{t("eop_comm_fixed")}</option>
              </select>
            </div>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
            <div>
              <label className="block text-xs font-semibold text-[#4A4A4A] mb-1">
                {t("eop_field_commission_value")}
              </label>
              <input
                type="number"
                step="0.01"
                value={commissionValue}
                onChange={(e) => setCommissionValue(e.target.value)}
                className="w-full px-3 py-2 text-sm border border-[#E5E3DF] rounded-xl"
              />
            </div>
            {status === "realized" && (
              <>
                <div>
                  <label className="block text-xs font-semibold text-[#4A4A4A] mb-1">
                    {t("eop_field_realized_at")}
                  </label>
                  <input
                    type="date"
                    value={realizedAt}
                    onChange={(e) => setRealizedAt(e.target.value)}
                    className="w-full px-3 py-2 text-sm border border-[#E5E3DF] rounded-xl"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-[#4A4A4A] mb-1">
                    {t("eop_field_invoice_ref")}
                  </label>
                  <input
                    type="text"
                    value={invoiceRef}
                    onChange={(e) => setInvoiceRef(e.target.value)}
                    className="w-full px-3 py-2 text-sm border border-[#E5E3DF] rounded-xl"
                  />
                </div>
              </>
            )}
          </div>

          {status === "cancelled" && (
            <div>
              <label className="block text-xs font-semibold text-rose-700 mb-1">
                {t("eop_field_cancel_reason")} *
              </label>
              <input
                type="text"
                value={cancellationReason}
                onChange={(e) => setCancellationReason(e.target.value)}
                required
                className="w-full px-3 py-2 text-sm border border-rose-200 rounded-xl bg-rose-50/40"
              />
            </div>
          )}

          <div>
            <label className="block text-xs font-semibold text-[#4A4A4A] mb-1">
              {t("eop_field_notes")}
            </label>
            <textarea
              rows={2}
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              className="w-full px-3 py-2 text-sm border border-[#E5E3DF] rounded-xl"
            />
          </div>

          <div className="flex items-center justify-between pt-2 border-t border-slate-100">
            <p className="text-[11px] text-[#666666] flex items-center gap-1.5">
              <ShieldCheck className="w-3.5 h-3.5 text-[#2A6E43] shrink-0" />
              <span>{t("eop_immutable_hint")}</span>
            </p>
            <div className="flex items-center gap-2 shrink-0">
              <button
                type="button"
                onClick={onClose}
                className="px-4 py-2 text-xs font-semibold text-[#666666] hover:bg-slate-100 rounded-xl"
              >
                {t("eop_btn_cancel")}
              </button>
              {status === "realized" && onAddCounterparty && (
                <button
                  type="button"
                  disabled={submitting}
                  onClick={() => saveRecord(true)}
                  className="px-3.5 py-2 text-xs font-semibold text-[#1B5888] bg-[#E5EEF6] hover:bg-[#1B5888] hover:text-white border border-[#1B5888]/25 rounded-xl disabled:opacity-50 transition-colors cursor-pointer"
                >
                  {t("eop_btn_save_add_counterparty")}
                </button>
              )}
              <button
                type="submit"
                disabled={submitting}
                className="px-4 py-2 text-xs font-semibold text-white bg-[#1B5888] hover:bg-[#12406A] rounded-xl disabled:opacity-50"
              >
                {submitting ? t("eop_btn_saving") : t("eop_btn_save")}
              </button>
            </div>
          </div>
        </form>
      </div>
    </div>
  );
}

export interface EopTabProps {
  records: EopRecord[];
  clients: AgencyClient[];
  amlRecords?: AmlRecord[];
  properties?: AgencyManagedProperty[];
  listings?: AgencyListingRow[];
  agencyName: string;
  registryInfo: AgencyRegistryInfo;
  loading: boolean;
  initialPropertyFilter?: string | null;
  initialListingFilter?: string | null;
  onClearScopeFilter?: () => void;
  onOpenModal: (prefill: EopPrefill) => void;
  onOpenAmlModal?: (prefill: AmlPrefill) => void;
  onOpenSettings: () => void;
  t: (key: string) => string;
}

export default function EopTab({
  records,
  amlRecords = [],
  properties = [],
  listings = [],
  agencyName,
  registryInfo,
  loading,
  initialPropertyFilter = null,
  initialListingFilter = null,
  onClearScopeFilter,
  onOpenModal,
  onOpenAmlModal,
  onOpenSettings,
  t,
}: EopTabProps) {
  const [search, setSearch] = useState("");
  const [yearFilter, setYearFilter] = useState<string>("all");
  const [statusFilter, setStatusFilter] = useState<string>("all");
  const [roleFilter, setRoleFilter] = useState<string>("all");
  const [txFilter, setTxFilter] = useState<string>("all");
  const [printScript, setPrintScript] = useState<"SR_LAT" | "SR_CYR">("SR_LAT");
  const [moreMenuOpen, setMoreMenuOpen] = useState(false);
  const [visibleActionCount, setVisibleActionCount] = useState<number>(4);
  const actionBarRef = useRef<HTMLDivElement | null>(null);
  const measureBarRef = useRef<HTMLDivElement | null>(null);

  useEffect(() => {
    const recalc = () => {
      const container = actionBarRef.current;
      const measure = measureBarRef.current;
      if (!container || !measure) return;
      const containerWidth = container.clientWidth;
      const gap = 8;
      const children = Array.from(measure.children) as HTMLElement[];
      const totalAllWidth = children.reduce(
        (acc, el, idx) => acc + el.offsetWidth + (idx > 0 ? gap : 0),
        0
      );
      if (totalAllWidth <= containerWidth) {
        setVisibleActionCount(children.length);
        return;
      }
      const moreReserved = 104;
      let used = 0;
      let count = 0;
      for (const el of children) {
        const w = el.offsetWidth;
        const needed = (count > 0 ? gap : 0) + w;
        if (used + needed + moreReserved <= containerWidth) {
          used += needed;
          count++;
        } else {
          break;
        }
      }
      setVisibleActionCount(Math.max(1, count));
    };
    recalc();
    const ro = new ResizeObserver(recalc);
    if (actionBarRef.current) ro.observe(actionBarRef.current);
    return () => ro.disconnect();
  }, [printScript, t]);

  const pt = (key: string) => TRANSLATIONS[printScript]?.[key] || TRANSLATIONS.SR_LAT?.[key] || key;

  const availableYears = useMemo(() => {
    const set = new Set<number>([new Date().getFullYear()]);
    records.forEach((r) => {
      if (r.sequence_year) set.add(r.sequence_year);
    });
    return Array.from(set).sort((a, b) => b - a);
  }, [records]);

  const scopedProperty = useMemo(
    () => (initialPropertyFilter ? properties.find((p) => p.id === initialPropertyFilter) || null : null),
    [initialPropertyFilter, properties]
  );

  const scopedListing = useMemo(
    () => (initialListingFilter ? listings.find((l) => l.id === initialListingFilter) || null : null),
    [initialListingFilter, listings]
  );

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase();
    return records.filter((r) => {
      if (initialPropertyFilter) {
        const matchesProp =
          r.property_id === initialPropertyFilter ||
          (scopedProperty?.last_listing_id && r.listing_id === scopedProperty.last_listing_id);
        if (!matchesProp) return false;
      }
      if (initialListingFilter && r.listing_id !== initialListingFilter) return false;
      if (yearFilter !== "all" && String(r.sequence_year) !== yearFilter) return false;
      if (statusFilter !== "all" && r.status !== statusFilter) return false;
      if (roleFilter !== "all" && r.client_role !== roleFilter) return false;
      if (txFilter !== "all" && r.transaction_type !== txFilter) return false;
      if (!q) return true;
      return (
        r.redni_broj.toLowerCase().includes(q) ||
        r.mediation_contract_no.toLowerCase().includes(q) ||
        r.client_name_snapshot.toLowerCase().includes(q) ||
        (r.client_jmbg_pib_snapshot || "").toLowerCase().includes(q) ||
        r.property_address_snapshot.toLowerCase().includes(q)
      );
    });
  }, [records, initialPropertyFilter, initialListingFilter, scopedProperty, yearFilter, statusFilter, roleFilter, txFilter, search]);

  const stats = useMemo(() => {
    return {
      total: filtered.length,
      active: filtered.filter((r) => r.status === "active").length,
      realized: filtered.filter((r) => r.status === "realized").length,
      cancelled: filtered.filter((r) => r.status === "cancelled").length,
    };
  }, [filtered]);

  const missingRegistry =
    !registryInfo.registar_posrednika_no && !registryInfo.pib && !registryInfo.official_address;

  const formatCommission = (r: EopRecord) => {
    if (r.commission_value == null) return "—";
    if (r.commission_type === "percent") return `${r.commission_value}%`;
    return `${r.commission_value} ${r.commission_currency || r.currency}`;
  };

  const handleExportCsv = () => {
    const headers = [
      pt("eop_col_redni_broj"),
      pt("eop_field_contract_no"),
      pt("eop_field_contract_date"),
      pt("eop_col_client"),
      pt("eop_field_client_jmbg_pib"),
      pt("eop_field_client_address"),
      pt("eop_field_client_role"),
      pt("eop_field_tx_type"),
      pt("eop_field_property_address"),
      pt("eop_field_property_specs"),
      pt("eop_field_asking_price"),
      pt("eop_field_agreed_price"),
      pt("eop_field_currency"),
      pt("eop_col_commission"),
      pt("eop_col_status"),
      pt("eop_field_realized_at"),
    ];
    const escapeCell = (v: unknown) => `"${String(v ?? "").replace(/"/g, '""')}"`;
    const rows = filtered.map((r) => [
      r.redni_broj,
      r.mediation_contract_no,
      r.mediation_contract_date,
      r.client_name_snapshot,
      r.client_jmbg_pib_snapshot || "",
      r.client_address_snapshot || "",
      pt(`eop_role_${r.client_role}`),
      pt(`eop_tx_${r.transaction_type}`),
      r.property_address_snapshot,
      r.property_specs_snapshot || "",
      r.asking_price ?? "",
      r.agreed_price ?? "",
      r.currency,
      formatCommission(r),
      pt(`eop_status_${r.status}`),
      r.realized_at || "",
    ]);
    const csv = "\uFEFF" + [headers, ...rows].map((row) => row.map(escapeCell).join(",")).join("\n");
    const blob = new Blob([csv], { type: "text/csv;charset=utf-8;" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `EOP_${yearFilter === "all" ? "all" : yearFilter}_${printScript}.csv`;
    a.click();
    URL.revokeObjectURL(url);
  };

  const handlePrint = () => {
    if (typeof window === "undefined") return;
    const esc = (v: unknown) =>
      String(v ?? "")
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/"/g, "&quot;");

    const rowsHtml = filtered
      .map((r) => {
        const priceText =
          r.agreed_price != null
            ? `${r.agreed_price.toLocaleString()} ${r.currency}`
            : r.asking_price != null
              ? `${r.asking_price.toLocaleString()} ${r.currency}`
              : "—";
        const statusLines = [
          esc(pt(`eop_status_${r.status}`)),
          r.realized_at ? esc(r.realized_at) : "",
          r.status === "cancelled" && r.cancellation_reason ? esc(r.cancellation_reason) : "",
        ]
          .filter(Boolean)
          .join("<br/>");
        const clientLines = [
          `<strong>${esc(r.client_name_snapshot)}</strong>`,
          r.client_jmbg_pib_snapshot ? esc(r.client_jmbg_pib_snapshot) : "",
          r.client_address_snapshot ? esc(r.client_address_snapshot) : "",
        ]
          .filter(Boolean)
          .join("<br/>");
        const propLines = [
          esc(r.property_address_snapshot),
          r.property_specs_snapshot ? esc(r.property_specs_snapshot) : "",
        ]
          .filter(Boolean)
          .join("<br/>");

        return `<tr>
          <td style="font-weight:700;white-space:nowrap;">${esc(r.redni_broj)}</td>
          <td>${esc(r.mediation_contract_no)}<br/>${esc(r.mediation_contract_date)}</td>
          <td>${clientLines}</td>
          <td>${esc(pt(`eop_role_${r.client_role}`))}<br/>${esc(pt(`eop_tx_${r.transaction_type}`))}</td>
          <td>${propLines}</td>
          <td style="white-space:nowrap;">${esc(priceText)}</td>
          <td style="white-space:nowrap;">${esc(formatCommission(r))}</td>
          <td>${statusLines}</td>
        </tr>`;
      })
      .join("");

    const yearLabel = yearFilter === "all" ? pt("eop_filter_all_years") : yearFilter;
    const todayIso = new Date().toISOString().split("T")[0];

    const html = `<!doctype html>
<html lang="sr">
<head>
  <meta charset="utf-8" />
  <title>${esc(pt("eop_print_doc_title"))}</title>
  <style>
    @page { size: A4 landscape; margin: 12mm; }
    * { box-sizing: border-box; }
    body { font-family: Arial, Helvetica, sans-serif; color: #000; background: #fff; margin: 0; padding: 0; font-size: 11px; }
    .header { border-bottom: 2px solid #000; padding-bottom: 10px; margin-bottom: 14px; }
    .title { text-align: center; font-size: 15px; font-weight: 700; text-transform: uppercase; margin: 0; }
    .subtitle { text-align: center; font-size: 11px; margin: 3px 0 0; }
    .meta { display: grid; grid-template-columns: 1fr 1fr; gap: 4px 16px; margin-top: 10px; font-size: 11px; }
    table { width: 100%; border-collapse: collapse; font-size: 10px; }
    th, td { border: 1px solid #000; padding: 5px 6px; text-align: left; vertical-align: top; }
    th { background: #f1f5f9; font-weight: 700; }
    .footer { margin-top: 36px; display: flex; justify-content: flex-end; }
    .sig { width: 240px; text-align: center; border-top: 1px solid #000; padding-top: 5px; font-size: 11px; }
  </style>
</head>
<body>
  <div class="header">
    <h1 class="title">${esc(pt("eop_print_doc_title"))}</h1>
    <p class="subtitle">${esc(pt("eop_print_doc_subtitle"))}</p>
    <div class="meta">
      <div><strong>${esc(pt("eop_print_agency_name"))}:</strong> ${esc(agencyName || "—")}</div>
      <div><strong>${esc(pt("eop_print_registar_no"))}:</strong> ${esc(registryInfo.registar_posrednika_no || "—")}</div>
      <div><strong>${esc(pt("eop_print_pib"))}:</strong> ${esc(registryInfo.pib || "—")} | <strong>${esc(pt("eop_print_maticni"))}:</strong> ${esc(registryInfo.maticni_broj || "—")}</div>
      <div><strong>${esc(pt("eop_print_address"))}:</strong> ${esc(registryInfo.official_address || "—")}</div>
      <div><strong>${esc(pt("eop_print_year"))}:</strong> ${esc(yearLabel)}</div>
      <div><strong>${esc(pt("eop_print_generated_at"))}:</strong> ${esc(todayIso)}</div>
    </div>
  </div>
  <table>
    <thead>
      <tr>
        <th>${esc(pt("eop_col_redni_broj"))}</th>
        <th>${esc(pt("eop_col_contract"))}</th>
        <th>${esc(pt("eop_col_client"))}</th>
        <th>${esc(pt("eop_col_role"))}</th>
        <th>${esc(pt("eop_col_property"))}</th>
        <th>${esc(pt("eop_col_price"))}</th>
        <th>${esc(pt("eop_col_commission"))}</th>
        <th>${esc(pt("eop_col_status"))}</th>
      </tr>
    </thead>
    <tbody>${rowsHtml}</tbody>
  </table>
  <div class="footer">
    <div class="sig">${esc(pt("eop_print_signature_line"))}</div>
  </div>
</body>
</html>`;

    const printWin = window.open("", "_blank", "width=1100,height=780");
    if (!printWin) return;
    printWin.document.open();
    printWin.document.write(html);
    printWin.document.close();
    printWin.focus();
    setTimeout(() => {
      printWin.print();
    }, 250);
  };

  return (
    <div className="space-y-5">
      {/* Single-Row Responsive Action Bar */}
      <div className="bg-white rounded-[10px] border border-[#E5E3DF] px-4 py-3 shadow-xs print:hidden">
        {(() => {
          const actionKeys = ["new_eop", "print_pdf", "export_csv", "print_script"] as const;
          const visibleKeys = actionKeys.slice(0, visibleActionCount);
          const overflowKeys = actionKeys.slice(visibleActionCount);

          const renderScriptToggle = () => (
            <div className="inline-flex items-center rounded-xl border border-[#E5E3DF] bg-[#F8F7F5] p-1 text-xs whitespace-nowrap shrink-0">
              <span className="px-2 text-[11px] font-medium text-[#666666]">
                {t("eop_print_lang_label")}:
              </span>
              <button
                type="button"
                onClick={() => setPrintScript("SR_LAT")}
                className={`px-2.5 py-1 rounded-lg font-semibold transition-colors cursor-pointer ${printScript === "SR_LAT"
                  ? "bg-[#1B5888] text-white"
                  : "text-[#666666] hover:bg-slate-200/60"
                  }`}
              >
                {t("eop_print_lang_sr_lat")}
              </button>
              <button
                type="button"
                onClick={() => setPrintScript("SR_CYR")}
                className={`px-2.5 py-1 rounded-lg font-semibold transition-colors cursor-pointer ${printScript === "SR_CYR"
                  ? "bg-[#1B5888] text-white"
                  : "text-[#666666] hover:bg-slate-200/60"
                  }`}
              >
                {t("eop_print_lang_sr_cyr")}
              </button>
            </div>
          );

          const renderInlineItem = (key: (typeof actionKeys)[number]) => {
            if (key === "new_eop") {
              return (
                <button
                  key={key}
                  type="button"
                  onClick={() => onOpenModal({ mode: "create" })}
                  className="inline-flex items-center gap-1.5 px-4 py-2 rounded-xl bg-[#1B5888] hover:bg-[#12406A] text-xs font-semibold text-white shadow-sm whitespace-nowrap shrink-0 cursor-pointer"
                >
                  <Plus className="w-4 h-4" />
                  <span>{t("eop_btn_new")}</span>
                </button>
              );
            }
            if (key === "print_pdf") {
              return (
                <button
                  key={key}
                  type="button"
                  onClick={handlePrint}
                  className="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl border border-[#1B5888]/25 bg-[#E5EEF6] hover:bg-[#1B5888] hover:text-white text-xs font-semibold text-[#1B5888] whitespace-nowrap shrink-0 cursor-pointer"
                >
                  <Printer className="w-3.5 h-3.5" />
                  <span>{t("eop_btn_print")}</span>
                </button>
              );
            }
            if (key === "export_csv") {
              return (
                <button
                  key={key}
                  type="button"
                  onClick={handleExportCsv}
                  className="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl border border-[#E5E3DF] bg-white hover:bg-[#F8F7F5] text-xs font-semibold text-[#4A4A4A] whitespace-nowrap shrink-0 cursor-pointer"
                >
                  <Download className="w-3.5 h-3.5" />
                  <span>{t("eop_btn_export_csv")}</span>
                </button>
              );
            }
            return <React.Fragment key={key}>{renderScriptToggle()}</React.Fragment>;
          };

          return (
            <div
              ref={actionBarRef}
              className="relative flex items-center gap-2 flex-nowrap"
            >
              {/* Invisible measurement mirror */}
              <div
                ref={measureBarRef}
                aria-hidden="true"
                className="pointer-events-none invisible absolute left-0 top-0 flex items-center gap-2 whitespace-nowrap"
              >
                {actionKeys.map((k) => renderInlineItem(k))}
              </div>

              {visibleKeys.map((k) => renderInlineItem(k))}

              {overflowKeys.length > 0 && (
                <div className="relative ml-auto shrink-0">
                  <button
                    type="button"
                    onClick={() => setMoreMenuOpen((prev) => !prev)}
                    className="px-3.5 py-2 rounded-xl border border-[#E5E3DF] text-xs font-semibold text-[#4A4A4A] hover:bg-[#F8F7F5] hover:text-[#1A1A1A] transition-colors cursor-pointer bg-white inline-flex items-center gap-1.5 whitespace-nowrap"
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
                      <div className="absolute right-0 mt-1.5 w-64 bg-white rounded-xl shadow-lg border border-[#E5E3DF] py-1.5 z-30 animate-in fade-in duration-100">
                        {overflowKeys.includes("print_pdf") && (
                          <button
                            type="button"
                            onClick={() => {
                              setMoreMenuOpen(false);
                              handlePrint();
                            }}
                            className="w-full text-left px-3.5 py-2 text-xs font-semibold text-[#1B5888] hover:bg-[#E5EEF6] flex items-center gap-2 cursor-pointer"
                          >
                            <Printer className="w-3.5 h-3.5" />
                            <span>{t("eop_btn_print")}</span>
                          </button>
                        )}
                        {overflowKeys.includes("export_csv") && (
                          <button
                            type="button"
                            onClick={() => {
                              setMoreMenuOpen(false);
                              handleExportCsv();
                            }}
                            className="w-full text-left px-3.5 py-2 text-xs font-medium text-[#4A4A4A] hover:bg-[#F8F7F5] flex items-center gap-2 cursor-pointer"
                          >
                            <Download className="w-3.5 h-3.5 text-slate-400" />
                            <span>{t("eop_btn_export_csv")}</span>
                          </button>
                        )}
                        {overflowKeys.includes("print_script") && (
                          <div className="px-3.5 py-2 border-t border-slate-100 mt-1 space-y-1.5">
                            <div className="text-[11px] font-semibold text-[#666666]">
                              {t("eop_print_lang_label")}
                            </div>
                            <div className="grid grid-cols-2 gap-1.5">
                              <button
                                type="button"
                                onClick={() => setPrintScript("SR_LAT")}
                                className={`px-2 py-1.5 rounded-lg text-[11px] font-semibold transition-colors cursor-pointer ${printScript === "SR_LAT"
                                  ? "bg-[#1B5888] text-white"
                                  : "bg-slate-100 text-[#4A4A4A] hover:bg-slate-200"
                                  }`}
                              >
                                {t("eop_print_lang_sr_lat")}
                              </button>
                              <button
                                type="button"
                                onClick={() => setPrintScript("SR_CYR")}
                                className={`px-2 py-1.5 rounded-lg text-[11px] font-semibold transition-colors cursor-pointer ${printScript === "SR_CYR"
                                  ? "bg-[#1B5888] text-white"
                                  : "bg-slate-100 text-[#4A4A4A] hover:bg-slate-200"
                                  }`}
                              >
                                {t("eop_print_lang_sr_cyr")}
                              </button>
                            </div>
                          </div>
                        )}
                      </div>
                    </>
                  )}
                </div>
              )}
            </div>
          );
        })()}
      </div>

      {/* Active Property / Listing Scope Filter Banner */}
      {(initialPropertyFilter || initialListingFilter) && (
        <div className="p-3 rounded-xl bg-[#E5EEF6] border border-[#1B5888]/25 flex items-center justify-between gap-3 print:hidden">
          <div className="text-xs font-semibold text-[#12406A] flex items-center gap-2 min-w-0">
            <BookOpen className="w-4 h-4 shrink-0 text-[#1B5888]" />
            <span className="truncate">
              {t("eop_filter_scope_active")}:{" "}
              {scopedProperty?.title ||
                scopedProperty?.address ||
                scopedListing?.title ||
                scopedListing?.address ||
                initialPropertyFilter ||
                initialListingFilter}
            </span>
          </div>
          {onClearScopeFilter && (
            <button
              type="button"
              onClick={onClearScopeFilter}
              className="px-2.5 py-1 rounded-lg bg-white border border-[#1B5888]/25 hover:bg-[#E5EEF6] text-xs font-semibold text-[#1B5888] shrink-0 cursor-pointer"
            >
              {t("eop_filter_clear")}
            </button>
          )}
        </div>
      )}

      {/* Missing Registry Banner */}
      {missingRegistry && (
        <div className="p-3.5 rounded-xl bg-[#FBF1DC] border border-[#8A5206]/20 flex items-center justify-between gap-3 print:hidden">
          <div className="flex items-center gap-2.5 text-xs text-[#8A5206]">
            <AlertTriangle className="w-4 h-4 shrink-0 text-[#8A5206]" />
            <span>{t("eop_print_missing_registry_hint")}</span>
          </div>
          <button
            type="button"
            onClick={onOpenSettings}
            className="px-3 py-1.5 rounded-lg bg-[#8A5206] hover:bg-[#704205] text-white text-xs font-semibold shrink-0"
          >
            {t("eop_btn_edit")}
          </button>
        </div>
      )}

      {/* KPI Strip */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3 print:hidden">
        <div className="bg-white rounded-xl border border-[#E5E3DF] p-4">
          <div className="text-[11px] font-semibold text-[#666666] uppercase">{t("eop_kpi_total")}</div>
          <div className="text-2xl font-bold text-[#1A1A1A] mt-1 tabular-nums">{stats.total}</div>
        </div>
        <div className="bg-white rounded-xl border border-[#E5E3DF] p-4">
          <div className="text-[11px] font-semibold text-[#1B5888] uppercase">{t("eop_kpi_active")}</div>
          <div className="text-2xl font-bold text-[#1B5888] mt-1 tabular-nums">{stats.active}</div>
        </div>
        <div className="bg-white rounded-xl border border-[#E5E3DF] p-4">
          <div className="text-[11px] font-semibold text-[#2A6E43] uppercase">{t("eop_kpi_realized")}</div>
          <div className="text-2xl font-bold text-[#2A6E43] mt-1 tabular-nums">{stats.realized}</div>
        </div>
        <div className="bg-white rounded-xl border border-[#E5E3DF] p-4">
          <div className="text-[11px] font-semibold text-rose-600 uppercase">{t("eop_kpi_cancelled")}</div>
          <div className="text-2xl font-bold text-rose-700 mt-1 tabular-nums">{stats.cancelled}</div>
        </div>
      </div>

      {/* Filters */}
      <div className="bg-white rounded-xl border border-[#E5E3DF] p-3 flex flex-wrap items-center gap-2.5 print:hidden">
        <div className="relative flex-1 min-w-[220px]">
          <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder={t("eop_search_placeholder")}
            className="w-full pl-9 pr-3 py-2 text-xs border border-[#E5E3DF] rounded-xl focus:outline-none focus:ring-2 focus:ring-[#1B5888]/20"
          />
        </div>
        <select
          value={yearFilter}
          onChange={(e) => setYearFilter(e.target.value)}
          className="px-3 py-2 text-xs border border-[#E5E3DF] rounded-xl bg-white"
        >
          <option value="all">{t("eop_filter_all_years")}</option>
          {availableYears.map((y) => (
            <option key={y} value={String(y)}>
              {y}
            </option>
          ))}
        </select>
        <select
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
          className="px-3 py-2 text-xs border border-[#E5E3DF] rounded-xl bg-white"
        >
          <option value="all">{t("eop_filter_all_statuses")}</option>
          <option value="active">{t("eop_status_active")}</option>
          <option value="realized">{t("eop_status_realized")}</option>
          <option value="cancelled">{t("eop_status_cancelled")}</option>
        </select>
        <select
          value={txFilter}
          onChange={(e) => setTxFilter(e.target.value)}
          className="px-3 py-2 text-xs border border-[#E5E3DF] rounded-xl bg-white"
        >
          <option value="all">{t("eop_filter_all_types")}</option>
          <option value="izdavanje">{t("eop_tx_izdavanje")}</option>
          <option value="prodaja">{t("eop_tx_prodaja")}</option>
        </select>
        <select
          value={roleFilter}
          onChange={(e) => setRoleFilter(e.target.value)}
          className="px-3 py-2 text-xs border border-[#E5E3DF] rounded-xl bg-white"
        >
          <option value="all">{t("eop_filter_all_roles")}</option>
          <option value="landlord">{t("eop_role_landlord")}</option>
          <option value="tenant">{t("eop_role_tenant")}</option>
          <option value="seller">{t("eop_role_seller")}</option>
          <option value="buyer">{t("eop_role_buyer")}</option>
        </select>
      </div>

      {/* Screen Table */}
      <div className="bg-white rounded-2xl border border-[#E5E3DF] overflow-hidden print:hidden">
        {loading ? (
          <div className="p-10 text-center text-xs text-slate-400">...</div>
        ) : filtered.length === 0 ? (
          <div className="p-12 text-center space-y-2">
            <BookOpen className="w-8 h-8 text-slate-300 mx-auto" />
            <h3 className="text-sm font-bold text-[#4A4A4A]">{t("eop_empty_title")}</h3>
            <p className="text-xs text-[#666666] max-w-md mx-auto">{t("eop_empty_desc")}</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-[#F8F7F5] border-b border-[#E5E3DF] text-[11px] font-bold text-[#666666] uppercase">
                  <th className="py-3 px-4">{t("eop_col_redni_broj")}</th>
                  <th className="py-3 px-4">{t("eop_col_contract")}</th>
                  <th className="py-3 px-4">{t("eop_col_client")}</th>
                  <th className="py-3 px-4">{t("eop_col_role")}</th>
                  <th className="py-3 px-4">{t("eop_col_property")}</th>
                  <th className="py-3 px-4">{t("eop_col_price")}</th>
                  <th className="py-3 px-4">{t("eop_col_commission")}</th>
                  <th className="py-3 px-4">{t("eop_col_status")}</th>
                  <th className="py-3 px-4">{t("aml_eop_col_aml")}</th>
                  <th className="py-3 px-3 text-center sticky right-0 z-10 bg-[#F8F7F5] border-l border-[#E5E3DF] shadow-[-4px_0_8px_-4px_rgba(0,0,0,0.06)]">
                    {t("eop_col_actions")}
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 text-xs">
                {filtered.map((r) => (
                  <tr key={r.id} className="group hover:bg-[#F8F7F5] transition-colors">
                    <td className="py-3.5 px-4 font-mono font-bold text-[#1A1A1A] whitespace-nowrap">
                      {r.redni_broj}
                    </td>
                    <td className="py-3.5 px-4">
                      <div className="font-semibold text-[#1A1A1A]">{r.mediation_contract_no}</div>
                      <div className="text-[11px] text-[#666666]">{r.mediation_contract_date}</div>
                      {r.is_exclusive && (
                        <span className="inline-block mt-1 px-1.5 py-0.5 rounded bg-purple-50 text-purple-700 text-[10px] font-semibold">
                          {t("eop_exclusive_yes")}
                        </span>
                      )}
                    </td>
                    <td className="py-3.5 px-4">
                      <div className="font-semibold text-[#1A1A1A] flex items-center gap-1.5">
                        {r.client_type === "company" ? (
                          <Building2 className="w-3.5 h-3.5 text-slate-400 shrink-0" />
                        ) : (
                          <User className="w-3.5 h-3.5 text-slate-400 shrink-0" />
                        )}
                        <span>{r.client_name_snapshot}</span>
                      </div>
                      {r.client_jmbg_pib_snapshot && (
                        <div className="text-[11px] text-[#666666] font-mono">
                          {r.client_jmbg_pib_snapshot}
                        </div>
                      )}
                      {r.client_address_snapshot && (
                        <div className="text-[11px] text-slate-400 truncate max-w-[180px]">
                          {r.client_address_snapshot}
                        </div>
                      )}
                    </td>
                    <td className="py-3.5 px-4 whitespace-nowrap">
                      <div className="font-semibold text-[#4A4A4A]">{t(`eop_role_${r.client_role}`)}</div>
                      <div className="text-[11px] text-[#666666]">{t(`eop_tx_${r.transaction_type}`)}</div>
                    </td>
                    <td className="py-3.5 px-4">
                      <div className="font-medium text-[#1A1A1A] max-w-[220px]">
                        {r.property_address_snapshot}
                      </div>
                      {r.property_specs_snapshot && (
                        <div className="text-[11px] text-[#666666]">{r.property_specs_snapshot}</div>
                      )}
                    </td>
                    <td className="py-3.5 px-4 whitespace-nowrap tabular-nums">
                      {r.agreed_price != null ? (
                        <div className="font-bold text-[#2A6E43]">
                          {r.agreed_price.toLocaleString()} {r.currency}
                        </div>
                      ) : null}
                      {r.asking_price != null && (
                        <div className="text-[11px] text-[#666666]">
                          {r.asking_price.toLocaleString()} {r.currency}
                        </div>
                      )}
                    </td>
                    <td className="py-3.5 px-4 whitespace-nowrap font-semibold text-[#1A1A1A]">
                      {formatCommission(r)}
                    </td>
                    <td className="py-3.5 px-4 whitespace-nowrap">
                      {r.status === "realized" ? (
                        <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full bg-[#EAF5EE] text-[#2A6E43] font-semibold text-[11px]">
                          <CheckCircle2 className="w-3 h-3" />
                          <span>{t("eop_status_realized")}</span>
                        </span>
                      ) : r.status === "cancelled" ? (
                        <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full bg-rose-50 text-rose-700 font-semibold text-[11px]">
                          <XCircle className="w-3 h-3" />
                          <span>{t("eop_status_cancelled")}</span>
                        </span>
                      ) : (
                        <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full bg-[#E5EEF6] text-[#1B5888] font-semibold text-[11px]">
                          <Clock className="w-3 h-3" />
                          <span>{t("eop_status_active")}</span>
                        </span>
                      )}
                      {r.realized_at && (
                        <div className="text-[10px] text-[#666666] mt-0.5">{r.realized_at}</div>
                      )}
                      {r.status === "cancelled" && r.cancellation_reason && (
                        <div className="text-[10px] text-rose-600 mt-0.5 max-w-[140px] truncate">
                          {r.cancellation_reason}
                        </div>
                      )}
                    </td>
                    <td className="py-3.5 px-4 whitespace-nowrap">
                      {(() => {
                        if (!onOpenAmlModal) return <span className="text-slate-400">—</span>;
                        const matchedAml = findMatchingAmlForEop(r, amlRecords);
                        const mandatory = isAmlMandatoryForEop(r);
                        if (matchedAml) {
                          const badgeCls =
                            matchedAml.status === "approved"
                              ? "bg-emerald-50 text-emerald-700 border-emerald-200"
                              : matchedAml.status === "rejected"
                                ? "bg-rose-50 text-rose-700 border-rose-200"
                                : "bg-amber-50 text-amber-800 border-amber-200";
                          const label =
                            matchedAml.status === "approved"
                              ? t("aml_eop_badge_ok")
                              : matchedAml.status === "rejected"
                                ? t("aml_eop_badge_rejected")
                                : t("aml_eop_badge_draft");
                          return (
                            <button
                              type="button"
                              onClick={() => onOpenAmlModal({ mode: "edit", existingRecord: matchedAml })}
                              className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[11px] font-semibold border cursor-pointer hover:opacity-85 ${badgeCls}`}
                            >
                              <ShieldCheck className="w-3 h-3" />
                              <span>{label}</span>
                            </button>
                          );
                        }
                        const buildPrefill = (): AmlPrefill => ({
                          mode: "create",
                          client_id: r.client_id || null,
                          eop_record_id: r.id,
                          property_id: r.property_id || null,
                          listing_id: r.listing_id || null,
                          party_type: r.client_type || "individual",
                          client_name: r.client_name_snapshot || "",
                          jmbg_pib: r.client_jmbg_pib_snapshot || "",
                          address: r.client_address_snapshot || "",
                          phone: r.client_phone_snapshot || "",
                          email: r.client_email_snapshot || "",
                          transaction_type: r.transaction_type || "prodaja",
                          transaction_value_eur: r.agreed_price ?? r.asking_price ?? null,
                          transaction_date: r.realized_at || r.mediation_contract_date,
                        });
                        if (mandatory) {
                          return (
                            <button
                              type="button"
                              onClick={() => onOpenAmlModal(buildPrefill())}
                              className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[11px] font-semibold bg-rose-50 text-rose-700 border border-rose-200 hover:bg-rose-600 hover:text-white transition-colors cursor-pointer"
                            >
                              <AlertTriangle className="w-3 h-3" />
                              <span>{t("aml_eop_badge_missing_mandatory")}</span>
                            </button>
                          );
                        }
                        return (
                          <button
                            type="button"
                            onClick={() => onOpenAmlModal(buildPrefill())}
                            className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[11px] font-medium bg-slate-50 text-slate-600 border border-slate-200 hover:bg-[#E5EEF6] hover:text-[#1B5888] transition-colors cursor-pointer"
                          >
                            <span>{t("aml_eop_badge_optional_add")}</span>
                          </button>
                        );
                      })()}
                    </td>
                    <td className="py-2.5 px-2.5 whitespace-nowrap sticky right-0 z-10 bg-white group-hover:bg-[#F8F7F5] border-l border-[#E5E3DF] shadow-[-4px_0_8px_-4px_rgba(0,0,0,0.06)] transition-colors align-middle">
                      <div className="flex flex-col items-center justify-center gap-1">
                        {r.status === "active" && (
                          <button
                            type="button"
                            onClick={() => onOpenModal({ mode: "realize", existingRecord: r })}
                            title={t("eop_btn_mark_realized")}
                            className="p-1.5 rounded-lg text-[#2A6E43] hover:bg-emerald-50 cursor-pointer"
                          >
                            <CheckCircle2 className="w-4 h-4" />
                          </button>
                        )}
                        <button
                          type="button"
                          onClick={() => onOpenModal({ mode: "edit", existingRecord: r })}
                          title={t("eop_btn_edit")}
                          className="p-1.5 rounded-lg text-[#666666] hover:bg-slate-100 cursor-pointer"
                        >
                          <Pencil className="w-4 h-4" />
                        </button>
                        {r.status !== "cancelled" && (
                          <button
                            type="button"
                            onClick={() => onOpenModal({ mode: "cancel", existingRecord: r })}
                            title={t("eop_btn_mark_cancelled")}
                            className="p-1.5 rounded-lg text-rose-500 hover:bg-rose-50 cursor-pointer"
                          >
                            <XCircle className="w-4 h-4" />
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

      {/* End Screen Table */}
    </div>
  );
}
