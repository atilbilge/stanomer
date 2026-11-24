"use client";

import React from "react";
import {
  AlertCircle,
  ArrowLeft,
  ArrowRight,
  CheckCircle2,
  Edit3,
  ImageIcon,
  Info,
  MapPin,
  Plus,
  RefreshCw,
  Star,
  Trash2,
  Upload,
  UserCheck,
} from "lucide-react";
import { AgencyLead, AgencyListingRow, AgencyPanelTab, ListingImageRow } from "../types";
import { AMENITY_KEYS } from "../constants";
import {
  SERBIAN_LOCATIONS,
  TRANSACTION_TYPES,
  PROPERTY_TYPES,
  ROOM_STRUCTURES,
  HEATING_TYPES,
  PROPERTY_CONDITIONS,
  FURNISHING_TYPES,
  getDictLabel,
} from "../../../lib/serbianRealEstateDict";

export interface ListingFormTabProps {
  leads: AgencyLead[];
  editingId: string | null;
  convertingLeadId: string | null;
  setConvertingLeadId: (id: string | null) => void;
  title: string;
  setTitle: (t: string) => void;
  externalRef: string;
  setExternalRef: (ref: string) => void;
  transactionType: string;
  setTransactionType: (t: any) => void;
  propertyType: string;
  setPropertyType: (pt: string) => void;
  price: string;
  setPrice: (p: string) => void;
  currency: string;
  areaSqm: string;
  setAreaSqm: (a: string) => void;
  roomCount: string;
  setRoomCount: (r: string) => void;
  floor: string;
  setFloor: (f: string) => void;
  totalFloors: string;
  setTotalFloors: (tf: string) => void;
  heatingType: string;
  setHeatingType: (ht: string) => void;
  condition: string;
  setCondition: (c: string) => void;
  furnishing: string;
  setFurnishing: (f: string) => void;
  city: string;
  municipality: string;
  neighborhood: string;
  setNeighborhood: (n: string) => void;
  address: string;
  setAddress: (a: string) => void;
  description: string;
  setDescription: (d: string) => void;
  selectedAmenities: string[];
  setSelectedAmenities: React.Dispatch<React.SetStateAction<string[]>>;
  images: ListingImageRow[];
  manualImageUrl: string;
  setManualImageUrl: (u: string) => void;
  isPublished: boolean;
  setIsPublished: (p: boolean) => void;
  savingListing: boolean;
  photoInputRef: React.RefObject<HTMLInputElement | null>;
  uploadingPhotos: boolean;
  isDraggingOver: boolean;
  setIsDraggingOver: (b: boolean) => void;
  processFiles: (files: FileList | null) => void;
  val4Zida: any;
  valHalo: any;
  availableMunicipalities: { name: string; neighborhoods: string[] }[];
  availableNeighborhoods: string[];
  handleCityChange: (newCity: string) => void;
  handleMunicipalityChange: (newMuni: string) => void;
  handleFileUpload: (e: React.ChangeEvent<HTMLInputElement>) => void;
  handleSaveListing: (e: React.FormEvent) => void;
  resetForm: () => void;
  handleAddManualImageUrl: () => void;
  setCoverImage: (idx: number) => void;
  moveImage: (idx: number, delta: number) => void;
  removeImage: (idx: number) => void;
  setActiveTab: (tab: AgencyPanelTab) => void;
  t: (key: string) => string;
  lang: "TR" | "EN" | "SR_LAT" | "SR_CYR" | "RU";
}

export default function ListingFormTab({
  leads,
  editingId,
  convertingLeadId,
  setConvertingLeadId,
  title,
  setTitle,
  externalRef,
  setExternalRef,
  transactionType,
  setTransactionType,
  propertyType,
  setPropertyType,
  price,
  setPrice,
  currency,
  areaSqm,
  setAreaSqm,
  roomCount,
  setRoomCount,
  floor,
  setFloor,
  totalFloors,
  setTotalFloors,
  heatingType,
  setHeatingType,
  condition,
  setCondition,
  furnishing,
  setFurnishing,
  city,
  municipality,
  neighborhood,
  setNeighborhood,
  address,
  setAddress,
  description,
  setDescription,
  selectedAmenities,
  setSelectedAmenities,
  images,
  manualImageUrl,
  setManualImageUrl,
  isPublished,
  setIsPublished,
  savingListing,
  photoInputRef,
  uploadingPhotos,
  isDraggingOver,
  setIsDraggingOver,
  processFiles,
  val4Zida,
  valHalo,
  availableMunicipalities,
  availableNeighborhoods,
  handleCityChange,
  handleMunicipalityChange,
  handleFileUpload,
  handleSaveListing,
  resetForm,
  handleAddManualImageUrl,
  setCoverImage,
  moveImage,
  removeImage,
  setActiveTab,
  t,
  lang,
}: ListingFormTabProps) {
  return (
    <div
      role="tabpanel"
      id="tabpanel-form"
      aria-labelledby="tab-form"
      className="max-w-4xl mx-auto space-y-6"
    >
      {/* Converting Lead Notice Banner */}
      {convertingLeadId && (
        <div className="p-4 rounded-[10px] bg-[#E5EEF6] border border-[#1B5888]/20 flex flex-col sm:flex-row sm:items-center justify-between gap-3 shadow-xs">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-[10px] bg-[#E5EEF6] text-blue-800 flex items-center justify-center shrink-0">
              <UserCheck className="w-5 h-5" />
            </div>
            <div>
              <p className="text-xs font-bold text-blue-950 flex items-center gap-1.5">
                <span>{t("agency_panel_converting_banner")}</span>
                <strong className="underline">
                  {leads.find((l) => l.id === convertingLeadId)?.client_name}
                </strong>
              </p>
              <p className="text-xs text-[#12406A] mt-0.5">
                {t("agency_panel_converting_hint")}
              </p>
            </div>
          </div>
          <button
            type="button"
            onClick={() => setConvertingLeadId(null)}
            className="px-3 py-1.5 rounded-lg bg-white border border-blue-300 text-blue-800 hover:bg-[#E5EEF6] text-xs font-semibold cursor-pointer self-end sm:self-auto"
          >
            {t("agency_panel_cancel_edit_btn")}
          </button>
        </div>
      )}

      {/* Editing Notice Banner */}
      {editingId && (
        <div className="p-4 rounded-[10px] bg-[#FBF1DC] border border-[#8A5206]/20 flex flex-col sm:flex-row sm:items-center justify-between gap-3 shadow-xs">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-[10px] bg-[#FBF1DC] text-[#8A5206] flex items-center justify-center shrink-0">
              <Edit3 className="w-5 h-5" />
            </div>
            <div>
              <p className="text-xs font-bold text-[#8A5206]">
                {t("agency_panel_editing_banner")} {title || t("agency_panel_untitled_listing")}
              </p>
              <p className="text-xs text-[#8A5206] mt-0.5">
                Ref: #{externalRef || editingId}
              </p>
            </div>
          </div>
          <div className="flex items-center gap-2 self-end sm:self-auto">
            <button
              type="button"
              onClick={resetForm}
              className="px-3 py-1.5 rounded-lg bg-white border border-amber-300 text-[#8A5206] hover:bg-[#FBF1DC] text-xs font-semibold cursor-pointer"
            >
              {t("agency_panel_cancel_edit_btn")}
            </button>
            <button
              type="button"
              onClick={() => setActiveTab("listings")}
              className="px-3 py-1.5 rounded-lg bg-amber-200 text-[#8A5206] hover:bg-amber-300 text-xs font-semibold cursor-pointer"
            >
              {t("agency_panel_go_to_listings")}
            </button>
          </div>
        </div>
      )}

      <div className="bg-white rounded-[10px] border border-[#E5E3DF] p-6 sm:p-8 shadow-xs">
        <form
          onSubmit={handleSaveListing}
          aria-labelledby="listing-form-heading"
          className="space-y-6"
        >
          {/* Group 1: Transaction Type & Property Type */}
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
            <fieldset>
              <legend className="block text-xs font-semibold text-[#4A4A4A] mb-1.5">
                {t("agency_panel_tx_type_label")}
              </legend>
              <div className="flex gap-3 pt-1">
                {Object.values(TRANSACTION_TYPES).map((tItem) => (
                  <label
                    key={tItem.key}
                    htmlFor={`tx-${tItem.key}`}
                    className="inline-flex items-center gap-1.5 text-sm font-medium text-[#1A1A1A] cursor-pointer"
                  >
                    <input
                      type="radio"
                      id={`tx-${tItem.key}`}
                      name="transaction_type"
                      value={tItem.key}
                      checked={transactionType === tItem.key}
                      onChange={(e) => setTransactionType(e.target.value)}
                    />
                    <span>{getDictLabel(tItem, lang)}</span>
                  </label>
                ))}
              </div>
            </fieldset>

            <div>
              <label
                htmlFor="property-type"
                className="block text-xs font-semibold text-[#4A4A4A] mb-1"
              >
                {t("agency_panel_prop_type_label")}
              </label>
              <select
                id="property-type"
                name="property_type"
                value={propertyType}
                onChange={(e) => setPropertyType(e.target.value)}
                className="w-full px-3 py-2 rounded-[10px] border border-[#8A8A8A] text-sm bg-white"
              >
                {Object.values(PROPERTY_TYPES).map((pt) => (
                  <option key={pt.key} value={pt.key}>
                    {getDictLabel(pt, lang)}
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label
                htmlFor="external-ref"
                className="block text-xs font-semibold text-[#4A4A4A] mb-1"
              >
                {t("agency_panel_ext_ref_label")}
              </label>
              <input
                id="external-ref"
                name="external_ref"
                type="text"
                spellCheck={false}
                autoCorrect="off"
                value={externalRef}
                onChange={(e) => setExternalRef(e.target.value)}
                placeholder="BG-2041"
                className="w-full px-3 py-2 rounded-[10px] border border-[#8A8A8A] text-sm"
              />
            </div>
          </div>

          {/* Group 2: Title & Description */}
          <div className="space-y-4">
            <div>
              <label
                htmlFor="listing-title"
                className="block text-xs font-semibold text-[#4A4A4A] mb-1"
              >
                {t("agency_panel_listing_title_label")} <span aria-hidden="true">*</span>
              </label>
              <input
                id="listing-title"
                name="title"
                type="text"
                required
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                placeholder={t("agency_panel_listing_title_placeholder")}
                className="w-full px-3.5 py-2.5 rounded-[10px] border border-[#8A8A8A] text-sm"
              />
            </div>

            <div>
              <label
                htmlFor="listing-desc"
                className="block text-xs font-semibold text-[#4A4A4A] mb-1"
              >
                {t("agency_panel_listing_desc_label")}
              </label>
              <textarea
                id="listing-desc"
                name="description"
                rows={3}
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                placeholder={t("agency_panel_listing_desc_placeholder")}
                className="w-full px-3.5 py-2.5 rounded-[10px] border border-[#8A8A8A] text-sm"
              />
            </div>
          </div>

          {/* Group 3: Location (Grad -> Opština -> Naselje -> Adresa) */}
          <fieldset className="p-4 rounded-[10px] bg-slate-50 border border-[#E5E3DF] space-y-3">
            <legend className="text-xs font-bold text-[#4A4A4A] px-1 flex items-center gap-2 flex-wrap">
              <span className="flex items-center gap-1.5">
                <MapPin className="w-3.5 h-3.5 text-[#1B5888]" />
                <span>{t("agency_panel_loc_legend")}</span>
              </span>
              <span className="inline-flex items-center text-[10px] font-semibold text-[#1B5888] bg-[#E5EEF6] px-2 py-0.5 rounded-full border border-[#1B5888]/15">
                {t("agency_panel_loc_portal_badge")}
              </span>
            </legend>
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
              <div>
                <label
                  htmlFor="loc-city"
                  className="block text-xs font-semibold text-[#4A4A4A] mb-1"
                >
                  {t("agency_panel_city_label")}
                </label>
                <select
                  id="loc-city"
                  name="city"
                  value={city}
                  onChange={(e) => handleCityChange(e.target.value)}
                  className="w-full px-3 py-2 rounded-lg border border-[#8A8A8A] text-sm bg-white"
                >
                  {SERBIAN_LOCATIONS.map((c) => (
                    <option key={c.city} value={c.city}>
                      {lang === "SR_CYR" ? c.cityCyr : c.city}
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label
                  htmlFor="loc-municipality"
                  className="block text-xs font-semibold text-[#4A4A4A] mb-1"
                >
                  {t("agency_panel_municipality_label")}
                </label>
                <select
                  id="loc-municipality"
                  name="municipality"
                  value={municipality}
                  onChange={(e) => handleMunicipalityChange(e.target.value)}
                  className="w-full px-3 py-2 rounded-lg border border-[#8A8A8A] text-sm bg-white"
                >
                  {availableMunicipalities.map((m) => (
                    <option key={m.name} value={m.name}>
                      {m.name}
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label
                  htmlFor="loc-neighborhood"
                  className="block text-xs font-semibold text-[#4A4A4A] mb-1"
                >
                  {t("agency_panel_neighborhood_label")}
                </label>
                <select
                  id="loc-neighborhood"
                  name="neighborhood"
                  value={neighborhood}
                  onChange={(e) => setNeighborhood(e.target.value)}
                  className="w-full px-3 py-2 rounded-lg border border-[#8A8A8A] text-sm bg-white"
                >
                  {availableNeighborhoods.map((n) => (
                    <option key={n} value={n}>
                      {n}
                    </option>
                  ))}
                </select>
              </div>
            </div>

            <div>
              <label
                htmlFor="loc-address"
                className="block text-xs font-semibold text-[#4A4A4A] mb-1"
              >
                {t("agency_panel_address_label")} <span aria-hidden="true">*</span>
              </label>
              <input
                id="loc-address"
                name="address"
                type="text"
                autoComplete="street-address"
                required
                value={address}
                onChange={(e) => setAddress(e.target.value)}
                placeholder={t("agency_panel_address_placeholder")}
                className="w-full px-3 py-2 rounded-lg border border-[#8A8A8A] text-sm bg-white"
              />
            </div>
          </fieldset>

          {/* Group 4: Price, Area, Rooms, Floor */}
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
            <div>
              <label
                htmlFor="listing-price"
                className="block text-xs font-semibold text-[#4A4A4A] mb-1"
              >
                {t("agency_panel_price_label")} ({currency}) <span aria-hidden="true">*</span>
              </label>
              <input
                id="listing-price"
                name="price"
                type="text"
                inputMode="decimal"
                required
                value={price}
                onChange={(e) => setPrice(e.target.value)}
                placeholder="1200"
                className="w-full px-3 py-2 rounded-[10px] border border-[#8A8A8A] text-sm"
              />
            </div>

            <div>
              <label
                htmlFor="listing-area"
                className="block text-xs font-semibold text-[#4A4A4A] mb-1"
              >
                {t("agency_panel_area_label")} <span aria-hidden="true">*</span>
              </label>
              <input
                id="listing-area"
                name="area_sqm"
                type="text"
                inputMode="decimal"
                required
                value={areaSqm}
                onChange={(e) => setAreaSqm(e.target.value)}
                placeholder="75"
                className="w-full px-3 py-2 rounded-[10px] border border-[#8A8A8A] text-sm"
              />
            </div>

            <div>
              <label
                htmlFor="listing-rooms"
                className="block text-xs font-semibold text-[#4A4A4A] mb-1"
              >
                {t("agency_panel_rooms_label")}
              </label>
              <select
                id="listing-rooms"
                name="room_count"
                value={roomCount}
                onChange={(e) => setRoomCount(e.target.value)}
                className="w-full px-3 py-2 rounded-[10px] border border-[#8A8A8A] text-sm bg-white"
              >
                {Object.values(ROOM_STRUCTURES).map((rm) => (
                  <option key={rm.key} value={rm.key}>
                    {getDictLabel(rm, lang)}
                  </option>
                ))}
              </select>
            </div>

            <div className="grid grid-cols-2 gap-2">
              <div>
                <label
                  htmlFor="listing-floor"
                  className="block text-xs font-semibold text-[#4A4A4A] mb-1"
                >
                  {t("agency_panel_floor_label")}
                </label>
                <input
                  id="listing-floor"
                  name="floor"
                  type="text"
                  value={floor}
                  onChange={(e) => setFloor(e.target.value)}
                  placeholder="3"
                  className="w-full px-2.5 py-2 rounded-[10px] border border-[#8A8A8A] text-sm"
                />
              </div>
              <div>
                <label
                  htmlFor="listing-total-floors"
                  className="block text-xs font-semibold text-[#4A4A4A] mb-1"
                >
                  {t("agency_panel_total_floors_label")}
                </label>
                <input
                  id="listing-total-floors"
                  name="total_floors"
                  type="text"
                  inputMode="numeric"
                  value={totalFloors}
                  onChange={(e) => setTotalFloors(e.target.value)}
                  placeholder="6"
                  className="w-full px-2.5 py-2 rounded-[10px] border border-[#8A8A8A] text-sm"
                />
              </div>
            </div>
          </div>

          {/* Group 5: Heating, Condition, Furnishing */}
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
            <div>
              <label
                htmlFor="listing-heating"
                className="block text-xs font-semibold text-[#4A4A4A] mb-1"
              >
                {t("agency_panel_heating_label")}
              </label>
              <select
                id="listing-heating"
                name="heating_type"
                value={heatingType}
                onChange={(e) => setHeatingType(e.target.value)}
                className="w-full px-3 py-2 rounded-[10px] border border-[#8A8A8A] text-sm bg-white"
              >
                {Object.values(HEATING_TYPES).map((ht) => (
                  <option key={ht.key} value={ht.key}>
                    {getDictLabel(ht, lang)}
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label
                htmlFor="listing-condition"
                className="block text-xs font-semibold text-[#4A4A4A] mb-1"
              >
                {t("agency_panel_condition_label")}
              </label>
              <select
                id="listing-condition"
                name="condition"
                value={condition}
                onChange={(e) => setCondition(e.target.value)}
                className="w-full px-3 py-2 rounded-[10px] border border-[#8A8A8A] text-sm bg-white"
              >
                {Object.values(PROPERTY_CONDITIONS).map((cd) => (
                  <option key={cd.key} value={cd.key}>
                    {getDictLabel(cd, lang)}
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label
                htmlFor="listing-furnishing"
                className="block text-xs font-semibold text-[#4A4A4A] mb-1"
              >
                {t("agency_panel_furnishing_label")}
              </label>
              <select
                id="listing-furnishing"
                name="furnishing"
                value={furnishing}
                onChange={(e) => setFurnishing(e.target.value)}
                className="w-full px-3 py-2 rounded-[10px] border border-[#8A8A8A] text-sm bg-white"
              >
                {Object.values(FURNISHING_TYPES).map((fn) => (
                  <option key={fn.key} value={fn.key}>
                    {getDictLabel(fn, lang)}
                  </option>
                ))}
              </select>
            </div>
          </div>

          {/* Group 6: Amenities Checkboxes */}
          <fieldset>
            <legend className="block text-xs font-semibold text-[#4A4A4A] mb-2">
              {t("agency_panel_amenities_legend")}
            </legend>
            <div className="flex flex-wrap gap-4">
              {AMENITY_KEYS.map((am) => {
                const checked = selectedAmenities.includes(am.id);
                return (
                  <label
                    key={am.id}
                    htmlFor={`amenity-${am.id}`}
                    className="inline-flex items-center gap-2 text-sm text-[#4A4A4A] cursor-pointer"
                  >
                    <input
                      type="checkbox"
                      id={`amenity-${am.id}`}
                      name="amenities"
                      value={am.id}
                      checked={checked}
                      onChange={(e) => {
                        if (e.target.checked) {
                          setSelectedAmenities((prev) => [...prev, am.id]);
                        } else {
                          setSelectedAmenities((prev) =>
                            prev.filter((item) => item !== am.id)
                          );
                        }
                      }}
                    />
                    <span>{t(am.tKey)}</span>
                  </label>
                );
              })}
            </div>
          </fieldset>

          {/* Group 7: Multi-Photo Upload & Drag-and-Drop */}
          <div className="p-4 sm:p-5 rounded-[10px] bg-slate-50 border border-[#E5E3DF] space-y-4">
            {/* Header with counter and portal guidance */}
            <div className="flex flex-wrap items-center justify-between gap-2">
              <div className="flex items-center gap-2">
                <div className="w-8 h-8 rounded-[10px] bg-[#E5EEF6]/70 border border-[#1B5888]/20 text-[#12406A] flex items-center justify-center shrink-0">
                  <ImageIcon className="w-4 h-4" />
                </div>
                <div>
                  <label
                    htmlFor="photo-upload-input"
                    className="text-xs font-bold text-[#1A1A1A] block"
                  >
                    {t("agency_panel_photos_label")}
                  </label>
                  <p className="text-[11px] text-[#666666]">
                    {images.length}{" "}
                    {t("agency_panel_photos_count_badge")}{" "}
                    {images.length < 3 && (
                      <span className="text-[#8A5206] font-medium">
                        {t("agency_panel_photos_min_hint")}
                      </span>
                    )}
                  </p>
                </div>
              </div>

              <label
                htmlFor="photo-upload-input"
                className="inline-flex items-center gap-1.5 px-3.5 py-1.5 rounded-[10px] bg-[#1B5888] hover:bg-[#12406A] active:bg-[#12406A] text-white text-xs font-bold shadow-xs transition-colors cursor-pointer"
              >
                <Upload className="w-3.5 h-3.5" />
                <span>
                  {uploadingPhotos
                    ? t("agency_panel_photos_uploading")
                    : t("agency_panel_photos_choose")}
                </span>
              </label>
              <input
                ref={photoInputRef}
                id="photo-upload-input"
                name="photos"
                type="file"
                accept="image/png,image/jpeg,image/webp,image/jpg"
                multiple
                onChange={handleFileUpload}
                className="sr-only"
              />
            </div>

            {/* Visual Drag & Drop Dropzone */}
            <div
              onDragOver={(e) => {
                e.preventDefault();
                e.stopPropagation();
                setIsDraggingOver(true);
              }}
              onDragEnter={(e) => {
                e.preventDefault();
                e.stopPropagation();
                setIsDraggingOver(true);
              }}
              onDragLeave={(e) => {
                e.preventDefault();
                e.stopPropagation();
                setIsDraggingOver(false);
              }}
              onDrop={(e) => {
                e.preventDefault();
                e.stopPropagation();
                setIsDraggingOver(false);
                if (e.dataTransfer.files && e.dataTransfer.files.length > 0) {
                  processFiles(e.dataTransfer.files);
                }
              }}
              onClick={() => photoInputRef.current?.click()}
              className={`relative rounded-[10px] border-2 border-dashed p-6 text-center cursor-pointer transition-all duration-200 flex flex-col items-center justify-center gap-2 ${isDraggingOver
                ? "border-blue-500 bg-[#E5EEF6]/80 ring-4 ring-blue-500/10 scale-[1.01]"
                : "border-[#8A8A8A] hover:border-blue-400 bg-white/70 hover:bg-[#E5EEF6]/20"
                }`}
            >
              <div
                className={`w-12 h-12 rounded-[10px] flex items-center justify-center transition-transform ${isDraggingOver
                  ? "bg-[#1B5888] text-white scale-110 shadow-md"
                  : "bg-[#E5EEF6] text-[#1B5888] border border-[#1B5888]/20 shadow-xs"
                  }`}
              >
                {uploadingPhotos ? (
                  <RefreshCw className="w-6 h-6 animate-spin text-[#1B5888]" />
                ) : (
                  <Upload className="w-6 h-6" />
                )}
              </div>

              <div>
                <p className="text-xs sm:text-sm font-bold text-[#1A1A1A]">
                  {uploadingPhotos
                    ? t("agency_panel_photos_uploading")
                    : t("agency_panel_photos_dropzone_title")}
                </p>
                <p className="text-[11px] text-[#666666] mt-0.5">
                  {t("agency_panel_photos_dropzone_sub")}
                </p>
              </div>
            </div>

            {/* Optional direct image URL input */}
            <div className="flex gap-2">
              <input
                id="manual-image-url"
                name="manual_image_url"
                type="url"
                value={manualImageUrl}
                onChange={(e) => setManualImageUrl(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === "Enter") {
                    e.preventDefault();
                    handleAddManualImageUrl();
                  }
                }}
                placeholder={t("agency_panel_photos_url_placeholder")}
                className="flex-1 px-3 py-2 rounded-[10px] border border-[#8A8A8A] text-xs bg-white focus:outline-none focus:ring-2 focus:ring-[#1B5888]/20 focus:border-[#1B5888] placeholder:text-[#666666]"
              />
              <button
                type="button"
                onClick={handleAddManualImageUrl}
                disabled={!manualImageUrl.trim()}
                className="px-3.5 py-2 rounded-[10px] bg-slate-200 hover:bg-slate-300 disabled:opacity-40 text-xs font-semibold text-[#4A4A4A] cursor-pointer transition-colors shrink-0"
              >
                {t("agency_panel_photos_add_url")}
              </button>
            </div>

            {/* Uploaded Images Grid */}
            {images.length > 0 && (
              <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-3 pt-2">
                {images.map((img, idx) => (
                  <div
                    key={`${img.url.slice(0, 32)}-${idx}`}
                    className={`relative group rounded-[10px] overflow-hidden border-2 transition-all bg-slate-100 aspect-[4/3] shadow-xs ${img.is_cover
                      ? "border-amber-500 ring-2 ring-amber-500/20 shadow-md"
                      : "border-[#E5E3DF] hover:border-[#8A8A8A]"
                      }`}
                  >
                    <img
                      src={img.url}
                      alt={`Foto ${idx + 1}`}
                      className="w-full h-full object-cover"
                      loading="lazy"
                    />

                    {/* Badges: Cover or Index */}
                    <div className="absolute top-2 left-2 flex items-center gap-1.5 z-10 pointer-events-none">
                      {img.is_cover ? (
                        <span className="px-2 py-0.5 rounded-md bg-amber-500 text-white text-[10px] font-bold shadow-md flex items-center gap-1">
                          <Star className="w-3 h-3 fill-current" />
                          <span>{t("agency_panel_photos_cover_badge")}</span>
                        </span>
                      ) : (
                        <span className="px-1.5 py-0.5 rounded-md bg-slate-900/60 text-white font-mono text-[10px] backdrop-blur-xs">
                          #{idx + 1}
                        </span>
                      )}
                    </div>

                    {/* Delete button (top right) */}
                    <button
                      type="button"
                      onClick={(e) => {
                        e.stopPropagation();
                        removeImage(idx);
                      }}
                      className="absolute top-2 right-2 p-1.5 rounded-lg bg-slate-900/60 hover:bg-red-600 text-white transition-colors cursor-pointer z-10 shadow-md"
                      title={t("agency_panel_photos_delete")}
                    >
                      <Trash2 className="w-3.5 h-3.5" />
                    </button>

                    {/* Bottom Action Bar */}
                    <div className="absolute bottom-0 inset-x-0 p-1.5 bg-gradient-to-t from-slate-950/80 via-slate-900/60 to-transparent flex items-center justify-between text-white text-[11px] z-10">
                      {!img.is_cover ? (
                        <button
                          type="button"
                          onClick={() => setCoverImage(idx)}
                          className="px-2 py-0.5 rounded text-[10px] font-bold bg-white/20 hover:bg-white/30 transition-colors cursor-pointer flex items-center gap-1"
                        >
                          <Star className="w-2.5 h-2.5" />
                          <span>{t("agency_panel_photos_make_cover")}</span>
                        </button>
                      ) : (
                        <span className="text-[10px] text-amber-300 font-bold px-1">
                          {t("agency_panel_photos_cover_badge")}
                        </span>
                      )}

                      <div className="flex items-center gap-1">
                        <button
                          type="button"
                          disabled={idx === 0}
                          onClick={() => moveImage(idx, -1)}
                          className="p-1 rounded bg-black/30 hover:bg-black/50 disabled:opacity-20 cursor-pointer"
                          title={t("agency_panel_photo_left")}
                        >
                          <ArrowLeft className="w-3 h-3" />
                        </button>
                        <button
                          type="button"
                          disabled={idx === images.length - 1}
                          onClick={() => moveImage(idx, 1)}
                          className="p-1 rounded bg-black/30 hover:bg-black/50 disabled:opacity-20 cursor-pointer"
                          title={t("agency_panel_photo_right")}
                        >
                          <ArrowRight className="w-3 h-3" />
                        </button>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>

          {/* Multi-Portal Pre-Flight Validation (4zida & Halo Oglasi) */}
          <div className="space-y-2.5">
            {/* 4zida validator card */}
            <div
              className={`p-3.5 rounded-[10px] border transition-all duration-200 ${val4Zida.isReady
                ? "bg-[#E6F3EA]/70 border-[#2A6E43]/20"
                : "bg-[#FBF1DC]/70 border-[#8A5206]/20"
                }`}
            >
              <div className="flex items-start justify-between gap-3">
                <div className="flex items-start gap-2.5">
                  {val4Zida.isReady ? (
                    <CheckCircle2 className="w-4 h-4 text-[#2A6E43] shrink-0 mt-0.5" />
                  ) : (
                    <AlertCircle className="w-4 h-4 text-[#8A5206] shrink-0 mt-0.5" />
                  )}
                  <div>
                    <div className="flex items-center gap-2 flex-wrap">
                      <h4 className="text-xs font-bold text-[#1A1A1A] flex items-center gap-1.5">
                        <img
                          src="/assets/portals/4zida.png"
                          alt="4zida.rs"
                          className="w-4 h-4 object-contain rounded-xs shrink-0"
                        />
                        <span>4zida.rs {t("agency_panel_validator_title")}</span>
                      </h4>
                      <span
                        className={`text-[10px] font-mono px-2 py-0.5 rounded-md font-bold ${val4Zida.isReady
                          ? "bg-[#E6F3EA] text-[#2A6E43]"
                          : "bg-[#FBF1DC] text-[#8A5206]"
                          }`}
                      >
                        {val4Zida.isReady
                          ? t("agency_panel_validator_ready")
                          : `${val4Zida.errors.length} ${t("agency_panel_validator_errors_count")}`}
                      </span>
                    </div>
                    <p className="text-[11px] text-[#4A4A4A] mt-0.5">
                      {val4Zida.isReady
                        ? `${t("agency_panel_validator_ready_desc")} (Kraj ID: ${val4Zida.details.resolvedKrajId} • Struktura: ${val4Zida.details.strukturaCode})`
                        : t("agency_panel_validator_errors_desc")}
                    </p>
                  </div>
                </div>
              </div>

              {!val4Zida.isReady && (
                <ul className="mt-2 pt-2 border-t border-[#8A5206]/20 list-disc list-inside text-[11px] text-[#8A5206] space-y-0.5">
                  {val4Zida.errors.map((err) => (
                    <li key={err.key}>{t(err.key) || err.defaultText}</li>
                  ))}
                </ul>
              )}

              {val4Zida.warnings.length > 0 && (
                <div className="mt-1.5 text-[11px] text-[#666666] space-y-0.5">
                  {val4Zida.warnings.map((w) => (
                    <p key={w.key} className="flex items-start gap-1.5">
                      <Info className="w-3.5 h-3.5 text-[#8A5206] shrink-0 mt-0.5" />
                      <span>{t(w.key) || w.defaultText}</span>
                    </p>
                  ))}
                </div>
              )}
            </div>

            {/* Halo Oglasi validator card */}
            <div
              className={`p-3.5 rounded-[10px] border transition-all duration-200 ${valHalo.isReady
                ? "bg-[#E6F3EA]/70 border-[#2A6E43]/20"
                : "bg-[#FBF1DC]/70 border-[#8A5206]/20"
                }`}
            >
              <div className="flex items-start justify-between gap-3">
                <div className="flex items-start gap-2.5">
                  {valHalo.isReady ? (
                    <CheckCircle2 className="w-4 h-4 text-[#2A6E43] shrink-0 mt-0.5" />
                  ) : (
                    <AlertCircle className="w-4 h-4 text-[#8A5206] shrink-0 mt-0.5" />
                  )}
                  <div>
                    <div className="flex items-center gap-2 flex-wrap">
                      <h4 className="text-xs font-bold text-[#1A1A1A] flex items-center gap-1.5">
                        <img
                          src="/assets/portals/halooglasi.png"
                          alt="Halo Oglasi"
                          className="w-4 h-4 object-contain rounded-xs shrink-0"
                        />
                        <span>Halo Oglasi {t("agency_panel_validator_title")}</span>
                      </h4>
                      <span
                        className={`text-[10px] font-mono px-2 py-0.5 rounded-md font-bold ${valHalo.isReady
                          ? "bg-[#E6F3EA] text-[#2A6E43]"
                          : "bg-[#FBF1DC] text-[#8A5206]"
                          }`}
                      >
                        {valHalo.isReady
                          ? t("agency_panel_validator_ready")
                          : `${valHalo.errors.length} ${t("agency_panel_validator_errors_count")}`}
                      </span>
                    </div>
                    <p className="text-[11px] text-[#4A4A4A] mt-0.5">
                      {valHalo.isReady
                        ? `${t("agency_panel_validator_ready_desc")} (XSD Struktura: ${valHalo.details.strukturaCode})`
                        : t("agency_panel_validator_errors_desc")}
                    </p>
                  </div>
                </div>
              </div>

              {!valHalo.isReady && (
                <ul className="mt-2 pt-2 border-t border-[#8A5206]/20 list-disc list-inside text-[11px] text-[#8A5206] space-y-0.5">
                  {valHalo.errors.map((err) => (
                    <li key={err.key}>{t(err.key) || err.defaultText}</li>
                  ))}
                </ul>
              )}

              {valHalo.warnings.length > 0 && (
                <div className="mt-1.5 text-[11px] text-[#666666] space-y-0.5">
                  {valHalo.warnings.map((w) => (
                    <p key={w.key} className="flex items-start gap-1.5">
                      <Info className="w-3.5 h-3.5 text-[#8A5206] shrink-0 mt-0.5" />
                      <span>{t(w.key) || w.defaultText}</span>
                    </p>
                  ))}
                </div>
              )}
            </div>
          </div>

          {/* Publish toggle & Submit */}
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pt-2">
            <div className="flex flex-col gap-0.5">
              <label
                htmlFor="publish-immediately"
                className="inline-flex items-center gap-2 text-sm font-semibold text-[#1A1A1A] cursor-pointer"
              >
                <input
                  type="checkbox"
                  id="publish-immediately"
                  name="is_published"
                  checked={isPublished}
                  onChange={(e) => setIsPublished(e.target.checked)}
                  className="w-4 h-4 rounded text-[#1B5888] focus:ring-[#1B5888] border-[#8A8A8A] cursor-pointer"
                />
                <span>{t("agency_panel_publish_checkbox")}</span>
              </label>
              <p className="text-[11px] text-[#666666] pl-6 max-w-md leading-relaxed">
                {t("agency_panel_publish_checkbox_hint")}
              </p>
            </div>

            <div className="flex items-center gap-2">
              <button
                type="button"
                onClick={() => {
                  resetForm();
                  setActiveTab("listings");
                }}
                className="px-4 py-3 rounded-[10px] border border-[#8A8A8A] hover:bg-slate-50 text-xs font-semibold text-[#4A4A4A] cursor-pointer"
              >
                {t("agency_panel_go_to_listings")}
              </button>
              <button
                type="submit"
                disabled={savingListing}
                className="py-3 px-6 rounded-[10px] bg-[#1B5888] hover:bg-[#12406A] active:bg-[#12406A] disabled:opacity-60 text-white font-semibold text-sm transition-colors cursor-pointer"
              >
                {savingListing
                  ? t("agency_panel_saving")
                  : editingId
                    ? t("agency_panel_save_changes")
                    : t("agency_panel_publish_submit")}
              </button>
            </div>
          </div>
        </form>
      </div>
    </div>
  );
}
