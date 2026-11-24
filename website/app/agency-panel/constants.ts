import { LeadStatus, LeadType, KanbanColId, PortalDef } from "./types";

export const AMENITY_KEYS = [
  { id: "elevator", tKey: "agency_panel_amenity_elevator" },
  { id: "balcony", tKey: "agency_panel_amenity_balcony" },
  { id: "parking", tKey: "agency_panel_amenity_parking" },
  { id: "storage", tKey: "agency_panel_amenity_storage" },
  { id: "pets_allowed", tKey: "agency_panel_amenity_pets" },
];

export const PORTAL_LIST: PortalDef[] = [
  {
    id: "4zida",
    name: "4zida.rs",
    file: "4zida.xml",
    badgeColor: "bg-[#E5EEF6] text-[#12406A] border-[#1B5888]/20",
    status: "live",
    noteKey: "agency_panel_xml_4zida_note",
  },
  {
    id: "halooglasi",
    name: "Halo Oglasi",
    file: "halooglasi.xml",
    badgeColor: "bg-[#FBF1DC] text-[#8A5206] border-[#8A5206]/20",
    status: "live",
    noteKey: "agency_panel_xml_halo_note",
  },
  {
    id: "nekretnine",
    name: "Nekretnine.rs",
    file: "nekretnine.xml",
    badgeColor: "bg-[#E6F3EA] text-[#2A6E43] border-[#2A6E43]/20",
    status: "on_demand",
    noteKey: "agency_panel_xml_nekretnine_note",
  },
  {
    id: "other",
    name: "Ostali portali",
    badgeColor: "bg-slate-100 text-[#4A4A4A] border-[#8A8A8A]",
    status: "on_demand",
    noteKey: "agency_panel_xml_other_note",
  },
];

export function getKanbanColumnForStatus(status: LeadStatus): KanbanColId {
  switch (status) {
    case "new":
      return "incoming";
    case "contacted":
    case "evaluation":
      return "in_progress";
    case "viewing_scheduled":
    case "offer_made":
      return "scheduled";
    case "contract_signed":
    case "converted":
      return "closed_won";
    case "archived":
      return "archived";
  }
}

export function getAllowedStatusesForType(type: LeadType): LeadStatus[] {
  switch (type) {
    case "owner_consignment":
      return ["new", "evaluation", "contacted", "contract_signed", "converted", "archived"];
    case "viewing_request":
      return ["new", "contacted", "viewing_scheduled", "offer_made", "contract_signed", "archived"];
    case "general_inquiry":
      return ["new", "contacted", "archived"];
  }
}

export const STATUS_TRANSLATION_KEYS: Record<LeadStatus, string> = {
  new: "agency_panel_status_new",
  evaluation: "agency_panel_status_evaluation",
  contacted: "agency_panel_status_contacted",
  viewing_scheduled: "agency_panel_status_viewing_scheduled",
  offer_made: "agency_panel_status_offer_made",
  contract_signed: "agency_panel_status_contract_signed",
  converted: "agency_panel_status_converted",
  archived: "agency_panel_status_archived",
};

export const STATUS_TOOLTIP_KEYS: Record<LeadStatus | "all", string> = {
  all: "agency_panel_status_all_desc",
  new: "agency_panel_status_new_desc",
  evaluation: "agency_panel_status_evaluation_desc",
  contacted: "agency_panel_status_contacted_desc",
  viewing_scheduled: "agency_panel_status_viewing_scheduled_desc",
  offer_made: "agency_panel_status_offer_made_desc",
  contract_signed: "agency_panel_status_contract_signed_desc",
  converted: "agency_panel_status_converted_desc",
  archived: "agency_panel_status_archived_desc",
};

export const STATUS_STYLES: Record<LeadStatus, { bg: string; text: string; border: string; dot: string }> = {
  new: { bg: "bg-[#E6F3EA]", text: "text-[#2A6E43]", border: "border-[#2A6E43]/20", dot: "bg-emerald-500" },
  evaluation: { bg: "bg-[#FBF1DC]", text: "text-[#8A5206]", border: "border-[#8A5206]/20", dot: "bg-amber-500" },
  contacted: { bg: "bg-[#E5EEF6]", text: "text-blue-800", border: "border-[#1B5888]/20", dot: "bg-blue-500" },
  viewing_scheduled: { bg: "bg-purple-50", text: "text-purple-800", border: "border-purple-200", dot: "bg-purple-500" },
  offer_made: { bg: "bg-indigo-50", text: "text-indigo-800", border: "border-indigo-200", dot: "bg-indigo-500" },
  contract_signed: { bg: "bg-teal-50", text: "text-teal-800", border: "border-teal-200", dot: "bg-teal-500" },
  converted: { bg: "bg-[#E6F3EA]", text: "text-emerald-900", border: "border-emerald-300", dot: "bg-[#1B5888]" },
  archived: { bg: "bg-slate-100", text: "text-[#4A4A4A]", border: "border-[#E5E3DF]", dot: "bg-slate-400" },
};

export const KANBAN_COLUMNS: { id: KanbanColId; titleKey: string; color: string; badgeColor: string }[] = [
  { id: "incoming", titleKey: "agency_panel_kanban_col_incoming", color: "border-[#2A6E43]/20 bg-[#E6F3EA]/30", badgeColor: "bg-[#E6F3EA] text-[#2A6E43]" },
  { id: "in_progress", titleKey: "agency_panel_kanban_col_in_progress", color: "border-[#1B5888]/20 bg-[#E5EEF6]/30", badgeColor: "bg-[#E5EEF6] text-blue-800" },
  { id: "scheduled", titleKey: "agency_panel_kanban_col_scheduled", color: "border-purple-200 bg-purple-50/30", badgeColor: "bg-purple-100 text-purple-800" },
  { id: "closed_won", titleKey: "agency_panel_kanban_col_closed_won", color: "border-teal-200 bg-teal-50/30", badgeColor: "bg-teal-100 text-teal-800" },
  { id: "archived", titleKey: "agency_panel_kanban_col_archived", color: "border-[#E5E3DF] bg-slate-50/30", badgeColor: "bg-slate-200 text-[#4A4A4A]" },
];

export const SERBIAN_CITIES = [
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
  "Smederevo",
  "Leskovac",
  "Užice",
  "Valjevo",
  "Kruševac",
  "Vranje",
  "Šabac",
  "Sombor",
  "Požarevac",
  "Pirot",
  "Zaječar",
  "Kikinda",
  "Sremska Mitrovica",
  "Jagodina",
  "Vršac",
  "Bor",
  "Prokuplje",
  "Loznica",
  "Gornji Milanovac",
  "Inđija",
  "Ruma",
  "Bačka Palanka",
  "Aranđelovac",
  "Vrbas",
  "Zlatibor",
  "Kopaonik",
  "Vrnjačka Banja",
  "Sokobanja",
] as const;
