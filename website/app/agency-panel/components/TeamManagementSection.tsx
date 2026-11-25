"use client";

import React, { useEffect, useState } from "react";
import {
  Users,
  Plus,
  Pencil,
  Trash2,
  X,
  CheckCircle2,
  AlertCircle,
  Shield,
  Mail,
  Phone,
  KeyRound,
  UserCheck,
} from "lucide-react";
import { supabase } from "../../../lib/supabaseClient";

export interface AgencyTeamMember {
  id: string;
  agency_id: string;
  user_id: string;
  email: string;
  full_name: string | null;
  phone_number: string | null;
  member_role: "agency_operation";
  status: "active" | "suspended" | "revoked";
  created_at: string;
}

interface TeamManagementSectionProps {
  agencyId: string | null;
  isDemoMode: boolean;
  t: (key: string) => string;
}

export default function TeamManagementSection({
  agencyId,
  isDemoMode,
  t,
}: TeamManagementSectionProps) {
  const [members, setMembers] = useState<AgencyTeamMember[]>([]);
  const [loading, setLoading] = useState(false);
  const [feedback, setFeedback] = useState<{ type: "success" | "error"; text: string } | null>(null);

  // Add / Edit modal state
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingMember, setEditingMember] = useState<AgencyTeamMember | null>(null);
  const [formFullName, setFormFullName] = useState("");
  const [formEmail, setFormEmail] = useState("");
  const [formPhone, setFormPhone] = useState("");
  const [formPassword, setFormPassword] = useState("");
  const [formStatus, setFormStatus] = useState<"active" | "suspended">("active");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [deletingId, setDeletingId] = useState<string | null>(null);

  const hasSession = Boolean(agencyId && agencyId !== "demo");

  const loadMembers = async () => {
    if (!hasSession || !agencyId) {
      setMembers([]);
      return;
    }
    setLoading(true);
    try {
      const { data, error } = await supabase
        .from("agency_members")
        .select("*")
        .eq("agency_id", agencyId)
        .order("created_at", { ascending: false });
      if (!error && Array.isArray(data)) {
        setMembers(data as AgencyTeamMember[]);
      }
    } catch (err) {
      console.warn("Could not load agency_members:", err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadMembers();
  }, [agencyId]);

  const openAddModal = () => {
    setEditingMember(null);
    setFormFullName("");
    setFormEmail("");
    setFormPhone("");
    setFormPassword("");
    setFormStatus("active");
    setFeedback(null);
    setIsModalOpen(true);
  };

  const openEditModal = (member: AgencyTeamMember) => {
    setEditingMember(member);
    setFormFullName(member.full_name || "");
    setFormEmail(member.email || "");
    setFormPhone(member.phone_number || "");
    setFormPassword("");
    setFormStatus(member.status === "suspended" ? "suspended" : "active");
    setFeedback(null);
    setIsModalOpen(true);
  };

  const callTeamApi = async (method: "POST" | "PATCH" | "DELETE", payload: Record<string, any>) => {
    const { data: sessionData } = await supabase.auth.getSession();
    const accessToken = sessionData.session?.access_token;
    if (!accessToken) {
      throw new Error(t("agency_team_err_unauthorized"));
    }

    const res = await fetch("/api/agency-team", {
      method,
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${accessToken}`,
      },
      body: JSON.stringify(payload),
    });

    const rawText = await res.text();
    let parsed: { success?: boolean; errorKey?: string; member?: AgencyTeamMember } = {};
    try {
      parsed = rawText ? JSON.parse(rawText) : {};
    } catch {
      throw new Error(`${t("agency_team_err_save_failed")} (HTTP ${res.status})`);
    }

    if (!res.ok || !parsed.success) {
      throw new Error(parsed.errorKey ? t(parsed.errorKey) : t("agency_team_err_save_failed"));
    }
    return parsed;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setFeedback(null);

    if (!formFullName.trim()) {
      setFeedback({ type: "error", text: t("agency_team_err_name_required") });
      return;
    }

    if (!editingMember) {
      if (!formEmail.trim() || !formEmail.includes("@")) {
        setFeedback({ type: "error", text: t("agency_team_err_invalid_email") });
        return;
      }
      if (formPassword.length < 6) {
        setFeedback({ type: "error", text: t("agency_team_err_password_short") });
        return;
      }
    } else if (formPassword && formPassword.length < 6) {
      setFeedback({ type: "error", text: t("agency_team_err_password_short") });
      return;
    }

    setIsSubmitting(true);
    try {
      if (isDemoMode && !hasSession) {
        if (editingMember) {
          setMembers((prev) =>
            prev.map((m) =>
              m.id === editingMember.id
                ? {
                    ...m,
                    full_name: formFullName.trim(),
                    phone_number: formPhone.trim() || null,
                    status: formStatus,
                  }
                : m
            )
          );
          setFeedback({ type: "success", text: t("agency_team_msg_updated") });
        } else {
          const demoMember: AgencyTeamMember = {
            id: `demo-member-${Date.now()}`,
            agency_id: "demo",
            user_id: `demo-user-${Date.now()}`,
            email: formEmail.trim().toLowerCase(),
            full_name: formFullName.trim(),
            phone_number: formPhone.trim() || null,
            member_role: "agency_operation",
            status: "active",
            created_at: new Date().toISOString(),
          };
          setMembers((prev) => [demoMember, ...prev]);
          setFeedback({ type: "success", text: t("agency_team_msg_added") });
        }
        setIsModalOpen(false);
        return;
      }

      if (editingMember) {
        const res = await callTeamApi("PATCH", {
          memberId: editingMember.id,
          fullName: formFullName.trim(),
          phone: formPhone.trim(),
          status: formStatus,
          ...(formPassword ? { password: formPassword } : {}),
        });
        if (res.member) {
          setMembers((prev) => prev.map((m) => (m.id === editingMember.id ? res.member! : m)));
        } else {
          await loadMembers();
        }
        setFeedback({ type: "success", text: t("agency_team_msg_updated") });
      } else {
        const res = await callTeamApi("POST", {
          email: formEmail.trim().toLowerCase(),
          fullName: formFullName.trim(),
          phone: formPhone.trim(),
          password: formPassword,
        });
        if (res.member) {
          setMembers((prev) => [res.member!, ...prev.filter((m) => m.id !== res.member!.id)]);
        } else {
          await loadMembers();
        }
        setFeedback({ type: "success", text: t("agency_team_msg_added") });
      }
      setIsModalOpen(false);
    } catch (err: any) {
      setFeedback({ type: "error", text: err?.message || t("agency_team_err_save_failed") });
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleRemove = async (member: AgencyTeamMember) => {
    if (typeof window !== "undefined" && !window.confirm(t("agency_team_confirm_remove"))) {
      return;
    }
    setDeletingId(member.id);
    setFeedback(null);
    try {
      if (isDemoMode && !hasSession) {
        setMembers((prev) => prev.filter((m) => m.id !== member.id));
        setFeedback({ type: "success", text: t("agency_team_msg_removed") });
        return;
      }
      await callTeamApi("DELETE", { memberId: member.id });
      setMembers((prev) => prev.filter((m) => m.id !== member.id));
      setFeedback({ type: "success", text: t("agency_team_msg_removed") });
    } catch (err: any) {
      setFeedback({ type: "error", text: err?.message || t("agency_team_err_delete_failed") });
    } finally {
      setDeletingId(null);
    }
  };

  return (
    <div className="space-y-4">
      <div className="bg-white rounded-[10px] border border-[#E5E3DF] p-5 shadow-[0_1px_0_rgba(0,0,0,0.04),0_2px_8px_rgba(0,0,0,0.06)]">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-4 border-b border-[#E5E3DF]">
          <div className="flex items-start gap-3">
            <div className="w-10 h-10 rounded-xl bg-[#1B5888]/10 text-[#1B5888] flex items-center justify-center shrink-0">
              <Users className="w-5 h-5" />
            </div>
            <div>
              <h3 className="text-sm font-bold text-[#1A1A1A]">{t("agency_team_title")}</h3>
              <p className="text-xs text-[#666666] mt-0.5">{t("agency_team_subtitle")}</p>
            </div>
          </div>

          <button
            type="button"
            onClick={openAddModal}
            className="inline-flex items-center justify-center gap-1.5 px-4 py-2 rounded-[10px] bg-[#1B5888] hover:bg-[#15466d] text-white text-xs font-bold transition-colors cursor-pointer shrink-0"
          >
            <Plus className="w-4 h-4" />
            <span>{t("agency_team_btn_add")}</span>
          </button>
        </div>

        {feedback && (
          <div
            className={`mt-4 p-3 rounded-[10px] border text-xs font-semibold flex items-center gap-2 ${
              feedback.type === "success"
                ? "bg-emerald-50 border-emerald-200 text-emerald-800"
                : "bg-rose-50 border-rose-200 text-rose-800"
            }`}
          >
            {feedback.type === "success" ? (
              <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0" />
            ) : (
              <AlertCircle className="w-4 h-4 text-rose-600 shrink-0" />
            )}
            <span>{feedback.text}</span>
          </div>
        )}

        <div className="mt-4">
          {loading ? (
            <div className="py-10 text-center text-xs text-[#666666]">{t("loading")}</div>
          ) : members.length === 0 ? (
            <div className="py-10 px-4 text-center rounded-[10px] border border-dashed border-[#E5E3DF] bg-[#F8F7F5]/60">
              <Users className="w-8 h-8 text-[#8A8A8A] mx-auto mb-2" />
              <p className="text-xs font-bold text-[#1A1A1A]">{t("agency_team_empty_title")}</p>
              <p className="text-xs text-[#666666] mt-1 max-w-md mx-auto">
                {t("agency_team_empty_desc")}
              </p>
            </div>
          ) : (
            <div className="divide-y divide-[#E5E3DF] border border-[#E5E3DF] rounded-[10px] overflow-hidden">
              {members.map((member) => (
                <div
                  key={member.id}
                  className="p-4 flex flex-col sm:flex-row sm:items-center justify-between gap-3 hover:bg-[#F8F7F5]/60 transition-colors"
                >
                  <div className="flex items-center gap-3 min-w-0">
                    <div className="w-10 h-10 rounded-full bg-[#E5EEF6] text-[#1B5888] font-bold text-xs flex items-center justify-center shrink-0">
                      {(member.full_name || member.email || "O").charAt(0).toUpperCase()}
                    </div>
                    <div className="min-w-0">
                      <div className="flex items-center gap-2 flex-wrap">
                        <span className="text-sm font-bold text-[#1A1A1A] truncate">
                          {member.full_name || member.email}
                        </span>
                        <span className="text-[11px] font-semibold px-2 py-0.5 rounded-[6px] bg-slate-100 text-slate-700 border border-slate-200 inline-flex items-center gap-1">
                          <Shield className="w-3 h-3 text-[#1B5888]" />
                          {t("agency_role_operation")}
                        </span>
                        <span
                          className={`text-[11px] font-semibold px-2 py-0.5 rounded-[6px] border ${
                            member.status === "active"
                              ? "bg-emerald-50 text-emerald-700 border-emerald-200"
                              : "bg-amber-50 text-amber-700 border-amber-200"
                          }`}
                        >
                          {member.status === "active"
                            ? t("agency_team_status_active")
                            : t("agency_team_status_suspended")}
                        </span>
                      </div>
                      <div className="flex items-center gap-3 mt-1 text-xs text-[#666666] flex-wrap">
                        <span className="inline-flex items-center gap-1 truncate">
                          <Mail className="w-3.5 h-3.5 text-[#8A8A8A]" />
                          {member.email}
                        </span>
                        {member.phone_number && (
                          <span className="inline-flex items-center gap-1">
                            <Phone className="w-3.5 h-3.5 text-[#8A8A8A]" />
                            {member.phone_number}
                          </span>
                        )}
                      </div>
                    </div>
                  </div>

                  <div className="flex items-center gap-2 shrink-0">
                    <button
                      type="button"
                      onClick={() => openEditModal(member)}
                      className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-[8px] border border-[#E5E3DF] text-xs font-semibold text-[#1A1A1A] hover:bg-slate-50 cursor-pointer"
                    >
                      <Pencil className="w-3.5 h-3.5" />
                      <span>{t("agency_team_btn_edit")}</span>
                    </button>
                    <button
                      type="button"
                      disabled={deletingId === member.id}
                      onClick={() => handleRemove(member)}
                      className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-[8px] border border-rose-200 text-xs font-semibold text-rose-700 hover:bg-rose-50 cursor-pointer disabled:opacity-50"
                    >
                      <Trash2 className="w-3.5 h-3.5" />
                      <span>{t("agency_team_btn_remove")}</span>
                    </button>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* Add / Edit Member Modal */}
      {isModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/50 backdrop-blur-xs">
          <div className="bg-white rounded-2xl border border-[#E5E3DF] shadow-2xl max-w-md w-full p-6 space-y-4">
            <div className="flex items-center justify-between border-b border-slate-100 pb-3">
              <h4 className="text-sm font-bold text-[#1A1A1A] flex items-center gap-2">
                <UserCheck className="w-4 h-4 text-[#1B5888]" />
                <span>
                  {editingMember ? t("agency_team_modal_edit_title") : t("agency_team_modal_add_title")}
                </span>
              </h4>
              <button
                type="button"
                onClick={() => setIsModalOpen(false)}
                className="text-[#666666] hover:text-[#1A1A1A] p-1 rounded-lg cursor-pointer"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <form onSubmit={handleSubmit} className="space-y-3.5">
              <div>
                <label className="block text-xs font-semibold text-[#1A1A1A] mb-1">
                  {t("agency_team_field_name")} *
                </label>
                <input
                  type="text"
                  required
                  value={formFullName}
                  onChange={(e) => setFormFullName(e.target.value)}
                  placeholder={t("agency_team_placeholder_name")}
                  className="w-full px-3 py-2 rounded-[10px] border border-[#E5E3DF] text-xs focus:outline-hidden focus:border-[#1B5888]"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-[#1A1A1A] mb-1">
                  {t("agency_team_field_email")} *
                </label>
                <input
                  type="email"
                  required
                  disabled={Boolean(editingMember)}
                  value={formEmail}
                  onChange={(e) => setFormEmail(e.target.value)}
                  placeholder={t("agency_team_placeholder_email")}
                  className="w-full px-3 py-2 rounded-[10px] border border-[#E5E3DF] text-xs focus:outline-hidden focus:border-[#1B5888] disabled:bg-slate-50 disabled:text-slate-500"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-[#1A1A1A] mb-1">
                  {t("agency_team_field_phone")}
                </label>
                <input
                  type="tel"
                  value={formPhone}
                  onChange={(e) => setFormPhone(e.target.value)}
                  placeholder={t("agency_team_placeholder_phone")}
                  className="w-full px-3 py-2 rounded-[10px] border border-[#E5E3DF] text-xs focus:outline-hidden focus:border-[#1B5888]"
                />
              </div>

              {editingMember && (
                <div>
                  <label className="block text-xs font-semibold text-[#1A1A1A] mb-1">
                    {t("agency_team_field_status")}
                  </label>
                  <select
                    value={formStatus}
                    onChange={(e) => setFormStatus(e.target.value as "active" | "suspended")}
                    className="w-full px-3 py-2 rounded-[10px] border border-[#E5E3DF] text-xs focus:outline-hidden focus:border-[#1B5888] bg-white"
                  >
                    <option value="active">{t("agency_team_status_active")}</option>
                    <option value="suspended">{t("agency_team_status_suspended")}</option>
                  </select>
                </div>
              )}

              <div>
                <label className="block text-xs font-semibold text-[#1A1A1A] mb-1 flex items-center gap-1">
                  <KeyRound className="w-3.5 h-3.5 text-[#8A8A8A]" />
                  <span>
                    {editingMember
                      ? t("agency_team_field_new_password_optional")
                      : `${t("agency_team_field_password")} *`}
                  </span>
                </label>
                <input
                  type="password"
                  required={!editingMember}
                  minLength={6}
                  value={formPassword}
                  onChange={(e) => setFormPassword(e.target.value)}
                  placeholder={t("agency_team_placeholder_password")}
                  className="w-full px-3 py-2 rounded-[10px] border border-[#E5E3DF] text-xs focus:outline-hidden focus:border-[#1B5888]"
                />
              </div>

              <div className="p-2.5 rounded-[10px] bg-[#F8F7F5] border border-[#E5E3DF] text-[11px] text-[#666666] flex items-center gap-2">
                <Shield className="w-4 h-4 text-[#1B5888] shrink-0" />
                <span>{t("agency_team_role_info")}</span>
              </div>

              <div className="flex items-center gap-2 pt-2">
                <button
                  type="button"
                  onClick={() => setIsModalOpen(false)}
                  className="flex-1 py-2.5 rounded-[10px] border border-[#E5E3DF] text-xs font-semibold text-[#4A4A4A] hover:bg-slate-50 cursor-pointer"
                >
                  {t("agency_panel_cancel_btn")}
                </button>
                <button
                  type="submit"
                  disabled={isSubmitting}
                  className="flex-1 py-2.5 rounded-[10px] bg-[#1B5888] hover:bg-[#15466d] text-white text-xs font-bold cursor-pointer disabled:opacity-50"
                >
                  {isSubmitting
                    ? t("sending")
                    : editingMember
                      ? t("agency_team_btn_save")
                      : t("agency_team_btn_create")}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
