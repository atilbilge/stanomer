"use client";

import React, { useState, useEffect } from "react";
import {
  X,
  Users,
  Crown,
  User,
  Building2,
  Trash2,
  Plus,
  FileText,
  UploadCloud,
  Check,
  Mail,
  Phone,
  PhoneCall,
  CreditCard,
  MapPin,
  Hash,
  UserCheck,
  Building,
  AlertTriangle,
} from "lucide-react";
import { AgencyManagedProperty } from "../types";
import { supabase } from "../../../lib/supabaseClient";

export interface PropertyOwnerItem {
  id?: string;
  is_primary: boolean;
  ownership_percentage: number | string;
  owner_type: "individual" | "company";
  first_name?: string;
  last_name?: string;
  phone?: string;
  secondary_contact?: string;
  email?: string;
  id_document_number?: string;
  id_details?: string;
  company_name?: string;
  registered_address?: string;
  pib?: string;
  registration_number?: string;
  representative_name?: string;
  representative_id_number?: string;
  representative_id_details?: string;
  documents?: Array<{
    type: string;
    name: string;
    url: string;
    uploaded_at?: string;
  }>;
}

interface EditPropertyOwnersModalProps {
  isOpen: boolean;
  onClose: () => void;
  property: AgencyManagedProperty | null;
  isDemoMode?: boolean;
  userId?: string | null;
  t: (key: string, params?: Record<string, any>) => string;
  onOwnersSaved: (updatedProperty: AgencyManagedProperty, owners: PropertyOwnerItem[]) => void;
}

export default function EditPropertyOwnersModal({
  isOpen,
  onClose,
  property,
  isDemoMode = false,
  userId,
  t,
  onOwnersSaved,
}: EditPropertyOwnersModalProps) {
  const [owners, setOwners] = useState<PropertyOwnerItem[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  const [validationError, setValidationError] = useState<string | null>(null);

  useEffect(() => {
    if (!property || !isOpen) return;

    let isMounted = true;
    const fetchOwners = async () => {
      setIsLoading(true);
      try {
        if (userId && userId !== "demo") {
          const { data, error } = await supabase
            .from("property_owners")
            .select("*")
            .eq("property_id", property.id)
            .order("is_primary", { ascending: false });

          if (!error && data && data.length > 0 && isMounted) {
            setOwners(
              data.map((row: any) => ({
                id: row.id,
                is_primary: row.is_primary ?? false,
                ownership_percentage: row.ownership_percentage ?? 100,
                owner_type: row.owner_type === "company" ? "company" : "individual",
                first_name: row.first_name || "",
                last_name: row.last_name || "",
                phone: row.phone || "",
                secondary_contact: row.secondary_contact || "",
                email: row.email || "",
                id_document_number: row.id_document_number || "",
                id_details: row.id_details || "",
                company_name: row.company_name || "",
                registered_address: row.registered_address || "",
                pib: row.pib || "",
                registration_number: row.registration_number || "",
                representative_name: row.representative_name || "",
                representative_id_number: row.representative_id_number || "",
                representative_id_details: row.representative_id_details || "",
                documents: Array.isArray(row.documents) ? row.documents : [],
              }))
            );
            return;
          }
        }
      } catch (err) {
        console.warn("Could not load property_owners, falling back to property fields:", err);
      } finally {
        if (isMounted) setIsLoading(false);
      }

      // Fallback: populate from current property fields or landlord profile (Flutter SSOT parity)
      let fallbackName = property.landlord_name?.trim() || "";
      let fallbackPhone = property.landlord_phone?.trim() || "";
      let fallbackEmail = property.landlord_email?.trim() || "";

      if ((!fallbackName || !fallbackEmail) && property.landlord_id && userId && userId !== "demo") {
        try {
          const { data: landlordProf } = await supabase
            .from("profiles")
            .select("id, full_name, phone_number, email")
            .eq("id", property.landlord_id)
            .maybeSingle();

          if (landlordProf) {
            if (!fallbackName && landlordProf.full_name) fallbackName = landlordProf.full_name.trim();
            if (!fallbackEmail && landlordProf.email) fallbackEmail = landlordProf.email.trim();
            if (!fallbackPhone && landlordProf.phone_number) fallbackPhone = landlordProf.phone_number.trim();
          }
        } catch (_) {}
      }

      const parts = fallbackName.split(" ");
      const firstName = parts[0] || "";
      const lastName = parts.slice(1).join(" ") || "";

      if (isMounted) {
        setOwners([
          {
            is_primary: true,
            ownership_percentage: 100,
            owner_type: "individual",
            first_name: firstName,
            last_name: lastName,
            phone: fallbackPhone,
            email: fallbackEmail,
            documents: [],
          },
        ]);
      }
    };

    fetchOwners();
    return () => {
      isMounted = false;
    };
  }, [property, isOpen, isDemoMode, userId]);

  if (!isOpen || !property) return null;

  const updateOwner = (index: number, updates: Partial<PropertyOwnerItem>) => {
    setOwners((prev) => {
      const copy = [...prev];
      copy[index] = { ...copy[index], ...updates };
      return copy;
    });
  };

  const handleAddCoOwner = () => {
    setOwners((prev) => {
      const isSecond = prev.length === 1;
      let newPerc = 50;
      let updatedPrev = [...prev];
      if (isSecond && prev[0].ownership_percentage === 100) {
        updatedPrev[0] = { ...updatedPrev[0], ownership_percentage: 50 };
      }
      return [
        ...updatedPrev,
        {
          is_primary: false,
          ownership_percentage: newPerc,
          owner_type: "individual",
          first_name: "",
          last_name: "",
          phone: "",
          email: "",
          documents: [],
        },
      ];
    });
  };

  const handleRemoveOwner = (index: number) => {
    if (owners.length <= 1) return;
    setOwners((prev) => {
      const copy = prev.filter((_, i) => i !== index);
      if (!copy.some((o) => o.is_primary)) {
        copy[0] = { ...copy[0], is_primary: true };
      }
      return copy;
    });
  };

  const handleFileUpload = (index: number, e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    const fakeUrl = URL.createObjectURL(file);
    const newDoc = {
      type: "ownership_proof",
      name: file.name,
      url: fakeUrl,
      uploaded_at: new Date().toISOString(),
    };

    updateOwner(index, {
      documents: [...(owners[index].documents || []), newDoc],
    });
  };

  const handleRemoveDocument = (ownerIndex: number, docIndex: number) => {
    const docs = [...(owners[ownerIndex].documents || [])];
    docs.splice(docIndex, 1);
    updateOwner(ownerIndex, { documents: docs });
  };

  const handleSave = async () => {
    setValidationError(null);

    // Validate Primary Owner
    const primary = owners.find((o) => o.is_primary) || owners[0];
    if (!primary) return;

    if (primary.owner_type === "individual") {
      if (!primary.first_name?.trim() || !primary.last_name?.trim()) {
        setValidationError(t("fieldRequired") + ` (${t("firstNameRequired")} / ${t("lastNameRequired")})`);
        return;
      }
    } else {
      if (!primary.company_name?.trim()) {
        setValidationError(t("fieldRequired") + ` (${t("companyLegalNameRequired")})`);
        return;
      }
    }

    if (!primary.phone?.trim()) {
      setValidationError(t("fieldRequired") + ` (${t("contactPhoneRequired")})`);
      return;
    }

    if (!primary.email?.trim()) {
      setValidationError(t("fieldRequired") + ` (${t("emailAddressRequiredForPrimary")})`);
      return;
    }

    setIsSaving(true);
    try {
      const primaryDisplayName =
        primary.owner_type === "company"
          ? primary.company_name?.trim() || ""
          : `${primary.first_name?.trim() || ""} ${primary.last_name?.trim() || ""}`.trim();

      const updatedProperty: AgencyManagedProperty = {
        ...property,
        landlord_name: primaryDisplayName || undefined,
        landlord_email: primary.email?.trim() || undefined,
        landlord_phone: primary.phone?.trim() || undefined,
        owners: owners,
      };

      if (userId && userId !== "demo") {
        // 1. Delete and insert to property_owners
        await supabase.from("property_owners").delete().eq("property_id", property.id);

        const insertPayload = owners.map((o) => ({
          property_id: property.id,
          owner_type: o.owner_type,
          is_primary: o.is_primary,
          ownership_percentage: parseFloat(o.ownership_percentage as any) || 100,
          first_name: o.owner_type === "individual" ? o.first_name?.trim() || null : null,
          last_name: o.owner_type === "individual" ? o.last_name?.trim() || null : null,
          company_name: o.owner_type === "company" ? o.company_name?.trim() || null : null,
          registered_address: o.owner_type === "company" ? o.registered_address?.trim() || null : null,
          pib: o.owner_type === "company" ? o.pib?.trim() || null : null,
          registration_number: o.owner_type === "company" ? o.registration_number?.trim() || null : null,
          representative_name: o.owner_type === "company" ? o.representative_name?.trim() || null : null,
          representative_id_number: o.owner_type === "company" ? o.representative_id_number?.trim() || null : null,
          representative_id_details: o.owner_type === "company" ? o.representative_id_details?.trim() || null : null,
          phone: o.phone?.trim() || null,
          secondary_contact: o.secondary_contact?.trim() || null,
          email: o.email?.trim() || null,
          id_document_number: o.id_document_number?.trim() || null,
          id_details: o.id_details?.trim() || null,
          documents: o.documents || [],
        }));

        await supabase.from("property_owners").insert(insertPayload);

        // 2. Update properties table with primary owner
        await supabase
          .from("properties")
          .update({
            landlord_name: primaryDisplayName || null,
            landlord_email: primary.email?.trim() || null,
            landlord_phone: primary.phone?.trim() || null,
          })
          .eq("id", property.id);

        // 3. Log activity
        try {
          await supabase.from("activity_logs").insert({
            property_id: property.id,
            user_id: userId,
            type: "property_owners_updated",
            metadata: {
              primary_owner: primaryDisplayName,
              owner_count: owners.length,
            },
          });
        } catch (_) {}
      }

      onOwnersSaved(updatedProperty, owners);
      onClose();
    } catch (err: any) {
      console.error("Save property owners error:", err);
      setValidationError(err.message || "Failed to save owners");
    } finally {
      setIsSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-xs animate-in fade-in duration-200">
      <div className="bg-white rounded-3xl shadow-2xl border border-slate-200/80 max-w-2xl w-full max-h-[92vh] flex flex-col overflow-hidden">
        {/* Top Drag Handle (Flutter BottomSheet Parity) */}
        <div className="pt-3 pb-1 flex justify-center shrink-0">
          <div className="w-10 h-1 bg-slate-300 rounded-full" />
        </div>

        {/* Modal Header */}
        <div className="px-6 py-3 border-b border-slate-100 flex items-center justify-between shrink-0">
          <h3 className="text-lg font-bold text-slate-900">{t("editPropertyOwners")}</h3>
          <button
            type="button"
            onClick={onClose}
            className="p-1.5 rounded-lg text-slate-400 hover:text-slate-700 hover:bg-slate-100 transition-colors cursor-pointer"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Modal Scrollable Body */}
        <div className="p-6 overflow-y-auto space-y-6 grow">
          {/* Section Header */}
          <div className="flex items-start gap-3">
            <div className="w-10 h-10 rounded-xl bg-blue-50 text-[#1B5888] flex items-center justify-center shrink-0">
              <Users className="w-5 h-5" />
            </div>
            <div>
              <h4 className="text-sm font-bold text-slate-900">{t("propertyOwnerInfoTitle")}</h4>
              <p className="text-xs text-slate-500 mt-0.5 leading-relaxed">
                {t("propertyOwnerInfoSubtitle")}
              </p>
            </div>
          </div>

          {/* Validation Error Banner */}
          {validationError && (
            <div className="p-3 bg-rose-50 border border-rose-200 rounded-[10px] text-xs font-semibold text-rose-700 flex items-center gap-2">
              <AlertTriangle className="w-4 h-4 text-rose-600 shrink-0" />
              <span>{validationError}</span>
            </div>
          )}

          {/* Owner Cards */}
          <div className="space-y-5">
            {owners.map((owner, index) => {
              const isPrimary = owner.is_primary;
              const isCompany = owner.owner_type === "company";

              return (
                <div
                  key={index}
                  className={`p-5 rounded-2xl border transition-all ${
                    isPrimary
                      ? "border-blue-300/80 bg-white shadow-xs"
                      : "border-slate-200 bg-slate-50/40"
                  }`}
                >
                  {/* Card Header: Badge, Share %, Delete */}
                  <div className="flex items-center justify-between gap-3 mb-4">
                    <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-lg text-xs font-bold bg-blue-50 text-[#1B5888] border border-blue-200/60">
                      <Crown className="w-3.5 h-3.5 text-blue-600" />
                      <span>
                        {isPrimary
                          ? t("primaryOwnerLabel")
                          : `${index + 1}. ${t("addCoOwner")}`}
                      </span>
                    </div>

                    <div className="flex items-center gap-3">
                      <div className="flex flex-col items-center justify-center border border-blue-200/90 rounded-xl px-3 py-1 bg-white min-w-[72px]">
                        <span className="text-[10px] font-semibold text-slate-500">
                          {t("sharePercentage")}
                        </span>
                        <input
                          type="number"
                          value={owner.ownership_percentage}
                          onChange={(e) => updateOwner(index, { ownership_percentage: e.target.value })}
                          className="w-14 text-center text-sm font-bold text-slate-900 focus:outline-hidden"
                        />
                      </div>

                      {!isPrimary && (
                        <button
                          type="button"
                          onClick={() => handleRemoveOwner(index)}
                          className="p-1.5 text-rose-500 hover:bg-rose-50 rounded-lg transition-colors cursor-pointer"
                          title={t("removeOwner")}
                        >
                          <Trash2 className="w-4 h-4" />
                        </button>
                      )}
                    </div>
                  </div>

                  {/* Owner Type Toggle */}
                  <div className="space-y-1.5 mb-4">
                    <label className="text-[11px] font-bold text-slate-500 block">
                      {t("ownerType")}
                    </label>
                    <div className="flex items-center gap-2">
                      <button
                        type="button"
                        onClick={() => updateOwner(index, { owner_type: "individual" })}
                        className={`inline-flex items-center gap-1.5 px-4 py-2 rounded-xl text-xs font-bold transition-all cursor-pointer ${
                          !isCompany
                            ? "bg-[#00C9A7] text-slate-950 border border-[#00C9A7] shadow-xs"
                            : "bg-white border-2 border-slate-900 text-slate-900 hover:bg-slate-50"
                        }`}
                      >
                        {!isCompany && <Check className="w-3.5 h-3.5 text-slate-950 stroke-[3]" />}
                        <User className="w-3.5 h-3.5" />
                        <span>{t("ownerIndividual")}</span>
                      </button>

                      <button
                        type="button"
                        onClick={() => updateOwner(index, { owner_type: "company" })}
                        className={`inline-flex items-center gap-1.5 px-4 py-2 rounded-xl text-xs font-bold transition-all cursor-pointer ${
                          isCompany
                            ? "bg-[#00C9A7] text-slate-950 border border-[#00C9A7] shadow-xs"
                            : "bg-white border-2 border-slate-900 text-slate-900 hover:bg-slate-50"
                        }`}
                      >
                        {isCompany && <Check className="w-3.5 h-3.5 text-slate-950 stroke-[3]" />}
                        <Building2 className="w-3.5 h-3.5" />
                        <span>{t("ownerCompany")}</span>
                      </button>
                    </div>
                  </div>

                  {/* Form Inputs */}
                  <div className="space-y-3">
                    {!isCompany ? (
                      <>
                        {/* Individual: First Name & Last Name */}
                        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                          <div>
                            <label className="text-xs font-bold text-slate-700 block mb-1">
                              {t("firstNameRequired")}
                            </label>
                            <div className="relative">
                              <User className="w-4 h-4 text-slate-400 absolute left-3 top-3" />
                              <input
                                type="text"
                                value={owner.first_name || ""}
                                onChange={(e) => updateOwner(index, { first_name: e.target.value })}
                                placeholder="Marko"
                                className="w-full pl-9 pr-3 py-2 text-xs font-semibold rounded-xl border border-slate-200 text-slate-900 focus:outline-hidden focus:border-[#1B5888]"
                              />
                            </div>
                          </div>

                          <div>
                            <label className="text-xs font-bold text-slate-700 block mb-1">
                              {t("lastNameRequired")}
                            </label>
                            <input
                              type="text"
                              value={owner.last_name || ""}
                              onChange={(e) => updateOwner(index, { last_name: e.target.value })}
                              placeholder="Petrović"
                              className="w-full px-3 py-2 text-xs font-semibold rounded-xl border border-slate-200 text-slate-900 focus:outline-hidden focus:border-[#1B5888]"
                            />
                          </div>
                        </div>

                        {/* ID & Details */}
                        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                          <div>
                            <label className="text-xs font-bold text-slate-700 block mb-1">
                              {t("idOrPassportOrJmbg")}
                            </label>
                            <div className="relative">
                              <CreditCard className="w-4 h-4 text-slate-400 absolute left-3 top-3" />
                              <input
                                type="text"
                                value={owner.id_document_number || ""}
                                onChange={(e) => updateOwner(index, { id_document_number: e.target.value })}
                                placeholder="JMBG / Pasaport No"
                                className="w-full pl-9 pr-3 py-2 text-xs font-semibold rounded-xl border border-slate-200 text-slate-900 focus:outline-hidden focus:border-[#1B5888]"
                              />
                            </div>
                          </div>

                          <div>
                            <label className="text-xs font-bold text-slate-700 block mb-1">
                              {t("idIssuingAuthority")}
                            </label>
                            <input
                              type="text"
                              value={owner.id_details || ""}
                              onChange={(e) => updateOwner(index, { id_details: e.target.value })}
                              placeholder="MUP Beograd"
                              className="w-full px-3 py-2 text-xs font-semibold rounded-xl border border-slate-200 text-slate-900 focus:outline-hidden focus:border-[#1B5888]"
                            />
                          </div>
                        </div>
                      </>
                    ) : (
                      <>
                        {/* Company: Company Name */}
                        <div>
                          <label className="text-xs font-bold text-slate-700 block mb-1">
                            {t("companyLegalNameRequired")}
                          </label>
                          <div className="relative">
                            <Building className="w-4 h-4 text-slate-400 absolute left-3 top-3" />
                            <input
                              type="text"
                              value={owner.company_name || ""}
                              onChange={(e) => updateOwner(index, { company_name: e.target.value })}
                              placeholder="Alpha Real Estate d.o.o."
                              className="w-full pl-9 pr-3 py-2 text-xs font-semibold rounded-xl border border-slate-200 text-slate-900 focus:outline-hidden focus:border-[#1B5888]"
                            />
                          </div>
                        </div>

                        {/* Registered Address */}
                        <div>
                          <label className="text-xs font-bold text-slate-700 block mb-1">
                            {t("registeredOfficeAddress")}
                          </label>
                          <div className="relative">
                            <MapPin className="w-4 h-4 text-slate-400 absolute left-3 top-3" />
                            <input
                              type="text"
                              value={owner.registered_address || ""}
                              onChange={(e) => updateOwner(index, { registered_address: e.target.value })}
                              placeholder="Kneza Miloša 12, Beograd"
                              className="w-full pl-9 pr-3 py-2 text-xs font-semibold rounded-xl border border-slate-200 text-slate-900 focus:outline-hidden focus:border-[#1B5888]"
                            />
                          </div>
                        </div>

                        {/* PIB & Matični broj */}
                        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                          <div>
                            <label className="text-xs font-bold text-slate-700 block mb-1">
                              {t("taxIdPibRequired")}
                            </label>
                            <div className="relative">
                              <Hash className="w-4 h-4 text-slate-400 absolute left-3 top-3" />
                              <input
                                type="text"
                                value={owner.pib || ""}
                                onChange={(e) => updateOwner(index, { pib: e.target.value })}
                                placeholder="109876543"
                                className="w-full pl-9 pr-3 py-2 text-xs font-semibold rounded-xl border border-slate-200 text-slate-900 focus:outline-hidden focus:border-[#1B5888]"
                              />
                            </div>
                          </div>

                          <div>
                            <label className="text-xs font-bold text-slate-700 block mb-1">
                              {t("companyRegNo")}
                            </label>
                            <input
                              type="text"
                              value={owner.registration_number || ""}
                              onChange={(e) => updateOwner(index, { registration_number: e.target.value })}
                              placeholder="20123456"
                              className="w-full px-3 py-2 text-xs font-semibold rounded-xl border border-slate-200 text-slate-900 focus:outline-hidden focus:border-[#1B5888]"
                            />
                          </div>
                        </div>

                        {/* Legal Representative */}
                        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                          <div>
                            <label className="text-xs font-bold text-slate-700 block mb-1">
                              {t("legalRepFullNameRequired")}
                            </label>
                            <div className="relative">
                              <UserCheck className="w-4 h-4 text-slate-400 absolute left-3 top-3" />
                              <input
                                type="text"
                                value={owner.representative_name || ""}
                                onChange={(e) => updateOwner(index, { representative_name: e.target.value })}
                                placeholder="Aleksandar Jovanović"
                                className="w-full pl-9 pr-3 py-2 text-xs font-semibold rounded-xl border border-slate-200 text-slate-900 focus:outline-hidden focus:border-[#1B5888]"
                              />
                            </div>
                          </div>

                          <div>
                            <label className="text-xs font-bold text-slate-700 block mb-1">
                              {t("repIdJmbg")}
                            </label>
                            <input
                              type="text"
                              value={owner.representative_id_number || ""}
                              onChange={(e) => updateOwner(index, { representative_id_number: e.target.value })}
                              placeholder="JMBG / Pasaport No"
                              className="w-full px-3 py-2 text-xs font-semibold rounded-xl border border-slate-200 text-slate-900 focus:outline-hidden focus:border-[#1B5888]"
                            />
                          </div>
                        </div>
                      </>
                    )}

                    {/* Shared Contact Phones */}
                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                      <div>
                        <label className="text-xs font-bold text-slate-700 block mb-1">
                          {t("contactPhoneRequired")}
                        </label>
                        <div className="relative">
                          <Phone className="w-4 h-4 text-slate-400 absolute left-3 top-3" />
                          <input
                            type="tel"
                            value={owner.phone || ""}
                            onChange={(e) => updateOwner(index, { phone: e.target.value })}
                            placeholder="+381 60 123 4567"
                            className="w-full pl-9 pr-3 py-2 text-xs font-semibold rounded-xl border border-slate-200 text-slate-900 focus:outline-hidden focus:border-[#1B5888]"
                          />
                        </div>
                      </div>

                      <div>
                        <label className="text-xs font-bold text-slate-700 block mb-1">
                          {t("secondaryContactOptional")}
                        </label>
                        <div className="relative">
                          <PhoneCall className="w-4 h-4 text-slate-400 absolute left-3 top-3" />
                          <input
                            type="tel"
                            value={owner.secondary_contact || ""}
                            onChange={(e) => updateOwner(index, { secondary_contact: e.target.value })}
                            placeholder="+381 11 234 5678"
                            className="w-full pl-9 pr-3 py-2 text-xs font-semibold rounded-xl border border-slate-200 text-slate-900 focus:outline-hidden focus:border-[#1B5888]"
                          />
                        </div>
                      </div>
                    </div>

                    {/* Email */}
                    <div>
                      <label className="text-xs font-bold text-slate-700 block mb-1">
                        {isPrimary
                          ? t("emailAddressRequiredForPrimary")
                          : t("emailAddressOptional")}
                      </label>
                      <div className="relative">
                        <Mail className="w-4 h-4 text-slate-400 absolute left-3 top-3" />
                        <input
                          type="email"
                          value={owner.email || ""}
                          onChange={(e) => updateOwner(index, { email: e.target.value })}
                          placeholder="marko@example.com"
                          className="w-full pl-9 pr-3 py-2 text-xs font-semibold rounded-xl border border-slate-200 text-slate-900 focus:outline-hidden focus:border-[#1B5888]"
                        />
                      </div>
                    </div>

                    {/* Supporting Documents */}
                    <div className="pt-2 border-t border-slate-100 space-y-2">
                      <div className="flex items-center justify-between">
                        <span className="text-xs font-bold text-slate-700 flex items-center gap-1.5">
                          <FileText className="w-3.5 h-3.5 text-slate-400" />
                          <span>{t("supportingPdfDocuments")}</span>
                        </span>

                        <label className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-bold bg-blue-50 text-[#1B5888] hover:bg-blue-100 transition-colors cursor-pointer">
                          <UploadCloud className="w-3.5 h-3.5" />
                          <span>{t("addPdfDocument")}</span>
                          <input
                            type="file"
                            accept=".pdf,image/*"
                            onChange={(e) => handleFileUpload(index, e)}
                            className="hidden"
                          />
                        </label>
                      </div>

                      {owner.documents && owner.documents.length > 0 ? (
                        <div className="flex flex-wrap gap-2 pt-1">
                          {owner.documents.map((doc, docIdx) => (
                            <div
                              key={docIdx}
                              className="inline-flex items-center gap-2 px-2.5 py-1 rounded-lg text-xs font-semibold bg-slate-100 text-slate-800 border border-slate-200"
                            >
                              <FileText className="w-3 h-3 text-slate-500" />
                              <span className="truncate max-w-[140px]">{doc.name}</span>
                              <button
                                type="button"
                                onClick={() => handleRemoveDocument(index, docIdx)}
                                className="text-slate-400 hover:text-rose-600 transition-colors"
                              >
                                <X className="w-3 h-3" />
                              </button>
                            </div>
                          ))}
                        </div>
                      ) : (
                        <p className="text-[11px] text-slate-400 italic">
                          {t("noDocumentsAttachedYet")}
                        </p>
                      )}
                    </div>
                  </div>
                </div>
              );
            })}
          </div>

          {/* Add Co-Owner Button */}
          <button
            type="button"
            onClick={handleAddCoOwner}
            className="w-full py-3 rounded-2xl border-2 border-dashed border-[#1B5888]/40 hover:border-[#1B5888] text-[#1B5888] font-bold text-xs hover:bg-blue-50/50 transition-all flex items-center justify-center gap-2 cursor-pointer"
          >
            <Plus className="w-4 h-4" />
            <span>{t("addCoOwner")}</span>
          </button>
        </div>

        {/* Modal Sticky Bottom Bar */}
        <div className="p-4 border-t border-slate-100 bg-white shrink-0">
          <button
            type="button"
            disabled={isSaving}
            onClick={handleSave}
            className="w-full py-3.5 rounded-xl font-bold bg-[#1B5888] hover:bg-blue-700 text-white transition-all shadow-md flex items-center justify-center gap-2 cursor-pointer disabled:opacity-50"
          >
            {isSaving ? "..." : t("saveChanges")}
          </button>
        </div>
      </div>
    </div>
  );
}
