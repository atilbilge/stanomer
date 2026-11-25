"use client";

import React, { useMemo, useState, useEffect } from "react";
import {
  CheckSquare,
  Plus,
  Search,
  Building2,
  Home,
  Inbox,
  Wrench,
  ClipboardList,
  UserCheck,
  Calendar,
  Flag,
  Pencil,
  Trash2,
  X,
  CheckCircle2,
  Clock,
  AlertCircle,
  UserPlus,
  List,
  LayoutGrid,
  MessageSquare,
  Send,
  Eye,
  Check,
} from "lucide-react";
import {
  AgencyAssigneeOption,
  AgencyLead,
  AgencyListingRow,
  AgencyMaintenanceRequest,
  AgencyManagedProperty,
  AgencyPanelTab,
  AgencyTask,
  AgencyTaskComment,
  AgencyTaskPrefill,
  AgencyTaskPriority,
  AgencyTaskSourceType,
  AgencyTaskStatus,
} from "../types";

export interface TaskFormModalProps {
  isOpen: boolean;
  onClose: () => void;
  editingTask: AgencyTask | null;
  prefill?: AgencyTaskPrefill | null;
  isAgencyAdmin: boolean;
  currentUserId: string | null;
  assignees: AgencyAssigneeOption[];
  properties: AgencyManagedProperty[];
  listings: AgencyListingRow[];
  leads: AgencyLead[];
  maintenanceRequests: AgencyMaintenanceRequest[];
  onSave: (payload: {
    id?: string;
    title: string;
    description: string | null;
    status: AgencyTaskStatus;
    priority: AgencyTaskPriority;
    due_date: string | null;
    source_type: AgencyTaskSourceType;
    property_id: string | null;
    listing_id: string | null;
    lead_id: string | null;
    maintenance_request_id: string | null;
    assigned_to: string | null;
  }) => Promise<void>;
  t: (key: string) => string;
}

export function TaskFormModal({
  isOpen,
  onClose,
  editingTask,
  prefill,
  isAgencyAdmin,
  currentUserId,
  assignees,
  properties,
  listings,
  leads,
  maintenanceRequests,
  onSave,
  t,
}: TaskFormModalProps) {
  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [status, setStatus] = useState<AgencyTaskStatus>("todo");
  const [priority, setPriority] = useState<AgencyTaskPriority>("medium");
  const [dueDate, setDueDate] = useState("");
  const [sourceType, setSourceType] = useState<AgencyTaskSourceType>("manual");
  const [propertyId, setPropertyId] = useState("");
  const [listingId, setListingId] = useState("");
  const [leadId, setLeadId] = useState("");
  const [maintenanceId, setMaintenanceId] = useState("");
  const [assignedTo, setAssignedTo] = useState("");
  const [saving, setSaving] = useState(false);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  useEffect(() => {
    if (!isOpen) return;
    setErrorMsg(null);
    if (editingTask) {
      setTitle(editingTask.title || "");
      setDescription(editingTask.description || "");
      setStatus(editingTask.status || "todo");
      setPriority(editingTask.priority || "medium");
      setDueDate(editingTask.due_date ? editingTask.due_date.split("T")[0] : "");
      setSourceType(editingTask.source_type || "manual");
      setPropertyId(editingTask.property_id || "");
      setListingId(editingTask.listing_id || "");
      setLeadId(editingTask.lead_id || "");
      setMaintenanceId(editingTask.maintenance_request_id || "");
      setAssignedTo(editingTask.assigned_to || "");
    } else {
      setTitle(prefill?.title || "");
      setDescription(prefill?.description || "");
      setStatus("todo");
      setPriority(prefill?.priority || "medium");
      setDueDate("");
      setSourceType(prefill?.source_type || "manual");
      setPropertyId(prefill?.property_id || "");
      setListingId(prefill?.listing_id || "");
      setLeadId(prefill?.lead_id || "");
      setMaintenanceId(prefill?.maintenance_request_id || "");
      setAssignedTo(currentUserId || "");
    }
  }, [isOpen, editingTask, prefill, currentUserId]);

  if (!isOpen) return null;

  const allowedAssignees = isAgencyAdmin
    ? assignees
    : assignees.filter((a) => a.id === currentUserId);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim()) {
      setErrorMsg(t("agency_tasks_err_title_required"));
      return;
    }
    setSaving(true);
    setErrorMsg(null);
    try {
      const effectiveAssignee = isAgencyAdmin
        ? assignedTo || null
        : assignedTo === currentUserId
          ? currentUserId
          : null;

      await onSave({
        id: editingTask?.id,
        title: title.trim(),
        description: description.trim() || null,
        status,
        priority,
        due_date: dueDate || null,
        source_type: sourceType,
        property_id: sourceType === "property" || sourceType === "maintenance" ? propertyId || null : null,
        listing_id: sourceType === "listing" ? listingId || null : null,
        lead_id: sourceType === "lead" ? leadId || null : null,
        maintenance_request_id: sourceType === "maintenance" ? maintenanceId || null : null,
        assigned_to: effectiveAssignee,
      });
      onClose();
    } catch (err: any) {
      setErrorMsg(err?.message || t("agency_tasks_err_save_failed"));
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/50 backdrop-blur-xs">
      <div className="bg-white rounded-2xl border border-[#E5E3DF] shadow-2xl max-w-lg w-full p-6 space-y-4 max-h-[92vh] overflow-y-auto">
        <div className="flex items-center justify-between border-b border-slate-100 pb-3">
          <h3 className="text-sm font-bold text-[#1A1A1A] flex items-center gap-2">
            <CheckSquare className="w-4 h-4 text-[#1B5888]" />
            <span>
              {editingTask ? t("agency_tasks_modal_edit_title") : t("agency_tasks_modal_add_title")}
            </span>
          </h3>
          <button
            type="button"
            onClick={onClose}
            className="text-[#666666] hover:text-[#1A1A1A] p-1 rounded-lg cursor-pointer"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        {errorMsg && (
          <div className="p-3 rounded-[10px] bg-rose-50 border border-rose-200 text-rose-800 text-xs font-semibold flex items-center gap-2">
            <AlertCircle className="w-4 h-4 text-rose-600 shrink-0" />
            <span>{errorMsg}</span>
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-3.5">
          <div>
            <label className="block text-xs font-semibold text-[#1A1A1A] mb-1">
              {t("agency_tasks_field_title")} *
            </label>
            <input
              type="text"
              required
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder={t("agency_tasks_placeholder_title")}
              className="w-full px-3 py-2 rounded-[10px] border border-[#E5E3DF] text-xs focus:outline-hidden focus:border-[#1B5888]"
            />
          </div>

          <div>
            <label className="block text-xs font-semibold text-[#1A1A1A] mb-1">
              {t("agency_tasks_field_description")}
            </label>
            <textarea
              rows={3}
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder={t("agency_tasks_placeholder_description")}
              className="w-full px-3 py-2 rounded-[10px] border border-[#E5E3DF] text-xs focus:outline-hidden focus:border-[#1B5888] resize-none"
            />
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-semibold text-[#1A1A1A] mb-1">
                {t("agency_tasks_field_source")}
              </label>
              <select
                value={sourceType}
                onChange={(e) => setSourceType(e.target.value as AgencyTaskSourceType)}
                className="w-full px-3 py-2 rounded-[10px] border border-[#E5E3DF] text-xs bg-white focus:outline-hidden focus:border-[#1B5888]"
              >
                <option value="manual">{t("agency_tasks_source_manual")}</option>
                <option value="property">{t("agency_tasks_source_property")}</option>
                <option value="listing">{t("agency_tasks_source_listing")}</option>
                <option value="lead">{t("agency_tasks_source_lead")}</option>
                <option value="maintenance">{t("agency_tasks_source_maintenance")}</option>
              </select>
            </div>

            <div>
              <label className="block text-xs font-semibold text-[#1A1A1A] mb-1">
                {t("agency_tasks_field_assignee")}
              </label>
              <select
                value={assignedTo}
                onChange={(e) => setAssignedTo(e.target.value)}
                className="w-full px-3 py-2 rounded-[10px] border border-[#E5E3DF] text-xs bg-white focus:outline-hidden focus:border-[#1B5888]"
              >
                <option value="">{t("agency_tasks_unassigned")}</option>
                {allowedAssignees.map((a) => (
                  <option key={a.id} value={a.id}>
                    {a.name} ({a.role === "agency_admin" ? t("agency_role_admin") : t("agency_role_operation")})
                  </option>
                ))}
              </select>
            </div>
          </div>

          {sourceType === "property" && (
            <div>
              <label className="block text-xs font-semibold text-[#1A1A1A] mb-1">
                {t("agency_tasks_select_property")}
              </label>
              <select
                value={propertyId}
                onChange={(e) => setPropertyId(e.target.value)}
                className="w-full px-3 py-2 rounded-[10px] border border-[#E5E3DF] text-xs bg-white focus:outline-hidden focus:border-[#1B5888]"
              >
                <option value="">{t("agency_tasks_select_none")}</option>
                {properties.map((p) => (
                  <option key={p.id} value={p.id}>
                    {p.title || p.address}
                  </option>
                ))}
              </select>
            </div>
          )}

          {sourceType === "listing" && (
            <div>
              <label className="block text-xs font-semibold text-[#1A1A1A] mb-1">
                {t("agency_tasks_select_listing")}
              </label>
              <select
                value={listingId}
                onChange={(e) => setListingId(e.target.value)}
                className="w-full px-3 py-2 rounded-[10px] border border-[#E5E3DF] text-xs bg-white focus:outline-hidden focus:border-[#1B5888]"
              >
                <option value="">{t("agency_tasks_select_none")}</option>
                {listings.map((l) => (
                  <option key={l.id} value={l.id}>
                    {l.title || l.address || l.id}
                  </option>
                ))}
              </select>
            </div>
          )}

          {sourceType === "lead" && (
            <div>
              <label className="block text-xs font-semibold text-[#1A1A1A] mb-1">
                {t("agency_tasks_select_lead")}
              </label>
              <select
                value={leadId}
                onChange={(e) => setLeadId(e.target.value)}
                className="w-full px-3 py-2 rounded-[10px] border border-[#E5E3DF] text-xs bg-white focus:outline-hidden focus:border-[#1B5888]"
              >
                <option value="">{t("agency_tasks_select_none")}</option>
                {leads.map((ld) => (
                  <option key={ld.id} value={ld.id}>
                    {ld.client_name} {ld.listing_title ? `• ${ld.listing_title}` : ""}
                  </option>
                ))}
              </select>
            </div>
          )}

          {sourceType === "maintenance" && (
            <div>
              <label className="block text-xs font-semibold text-[#1A1A1A] mb-1">
                {t("agency_tasks_select_maintenance")}
              </label>
              <select
                value={maintenanceId}
                onChange={(e) => {
                  const nextId = e.target.value;
                  setMaintenanceId(nextId);
                  const found = maintenanceRequests.find((m) => m.id === nextId);
                  if (found?.property_id) setPropertyId(found.property_id);
                }}
                className="w-full px-3 py-2 rounded-[10px] border border-[#E5E3DF] text-xs bg-white focus:outline-hidden focus:border-[#1B5888]"
              >
                <option value="">{t("agency_tasks_select_none")}</option>
                {maintenanceRequests.map((m) => (
                  <option key={m.id} value={m.id}>
                    {m.title} {m.property_title ? `• ${m.property_title}` : ""}
                  </option>
                ))}
              </select>
            </div>
          )}

          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
            <div>
              <label className="block text-xs font-semibold text-[#1A1A1A] mb-1">
                {t("agency_tasks_field_priority")}
              </label>
              <select
                value={priority}
                onChange={(e) => setPriority(e.target.value as AgencyTaskPriority)}
                className="w-full px-3 py-2 rounded-[10px] border border-[#E5E3DF] text-xs bg-white focus:outline-hidden focus:border-[#1B5888]"
              >
                <option value="low">{t("agency_tasks_priority_low")}</option>
                <option value="medium">{t("agency_tasks_priority_medium")}</option>
                <option value="high">{t("agency_tasks_priority_high")}</option>
                <option value="urgent">{t("agency_tasks_priority_urgent")}</option>
              </select>
            </div>

            <div>
              <label className="block text-xs font-semibold text-[#1A1A1A] mb-1">
                {t("agency_tasks_field_status")}
              </label>
              <select
                value={status}
                onChange={(e) => setStatus(e.target.value as AgencyTaskStatus)}
                className="w-full px-3 py-2 rounded-[10px] border border-[#E5E3DF] text-xs bg-white focus:outline-hidden focus:border-[#1B5888]"
              >
                <option value="todo">{t("agency_tasks_status_todo")}</option>
                <option value="in_progress">{t("agency_tasks_status_in_progress")}</option>
                <option value="done">{t("agency_tasks_status_done")}</option>
              </select>
            </div>

            <div>
              <label className="block text-xs font-semibold text-[#1A1A1A] mb-1">
                {t("agency_tasks_field_due_date")}
              </label>
              <input
                type="date"
                value={dueDate}
                onChange={(e) => setDueDate(e.target.value)}
                className="w-full px-3 py-2 rounded-[10px] border border-[#E5E3DF] text-xs focus:outline-hidden focus:border-[#1B5888]"
              />
            </div>
          </div>

          <div className="flex items-center gap-2 pt-2">
            <button
              type="button"
              onClick={onClose}
              className="flex-1 py-2.5 rounded-[10px] border border-[#E5E3DF] text-xs font-semibold text-[#4A4A4A] hover:bg-slate-50 cursor-pointer"
            >
              {t("agency_panel_cancel_btn")}
            </button>
            <button
              type="submit"
              disabled={saving}
              className="flex-1 py-2.5 rounded-[10px] bg-[#1B5888] hover:bg-[#15466d] text-white text-xs font-bold cursor-pointer disabled:opacity-50"
            >
              {saving
                ? t("sending")
                : editingTask
                  ? t("agency_tasks_btn_save")
                  : t("agency_tasks_btn_create")}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

export interface TasksTabProps {
  tasks: AgencyTask[];
  loading: boolean;
  isAgencyAdmin: boolean;
  currentUserId: string | null;
  assignees: AgencyAssigneeOption[];
  properties: AgencyManagedProperty[];
  listings: AgencyListingRow[];
  leads: AgencyLead[];
  maintenanceRequests: AgencyMaintenanceRequest[];
  onOpenCreateModal: (prefill?: AgencyTaskPrefill) => void;
  onOpenEditModal: (task: AgencyTask) => void;
  onQuickStatusChange: (task: AgencyTask, status: AgencyTaskStatus) => Promise<void>;
  onQuickAssign: (task: AgencyTask, assigneeId: string | null) => Promise<void>;
  onUpdateComments?: (task: AgencyTask, comments: AgencyTaskComment[]) => Promise<void>;
  onDeleteTask: (task: AgencyTask) => Promise<void>;
  currentUserName?: string;
  activeLocale?: string;
  onNavigateTab: (tab: AgencyPanelTab) => void;
  initialPropertyFilter?: string | null;
  onClearPropertyFilter?: () => void;
  initialListingFilter?: string | null;
  onClearListingFilter?: () => void;
  t: (key: string) => string;
}

export default function TasksTab({
  tasks,
  loading,
  isAgencyAdmin,
  currentUserId,
  assignees,
  properties,
  listings,
  leads,
  maintenanceRequests,
  onOpenCreateModal,
  onOpenEditModal,
  onQuickStatusChange,
  onQuickAssign,
  onUpdateComments,
  onDeleteTask,
  currentUserName = "User",
  activeLocale = "en-US",
  onNavigateTab,
  initialPropertyFilter = null,
  onClearPropertyFilter,
  initialListingFilter = null,
  onClearListingFilter,
  t,
}: TasksTabProps) {
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState<"all" | "open" | AgencyTaskStatus>("open");
  const [sourceFilter, setSourceFilter] = useState<"all" | AgencyTaskSourceType>("all");
  const [assigneeFilter, setAssigneeFilter] = useState<string>("all");
  const [urgentOnly, setUrgentOnly] = useState<boolean>(false);
  const [propertyFilter, setPropertyFilter] = useState<string | null>(initialPropertyFilter);
  const [listingFilter, setListingFilter] = useState<string | null>(initialListingFilter);
  const [viewMode, setViewMode] = useState<"list" | "kanban">("list");
  const [draggedTaskId, setDraggedTaskId] = useState<string | null>(null);
  const [dragOverStatus, setDragOverStatus] = useState<AgencyTaskStatus | null>(null);
  const [expandedCommentTaskIds, setExpandedCommentTaskIds] = useState<Set<string>>(new Set());
  const [viewingTaskId, setViewingTaskId] = useState<string | null>(null);
  const [commentDrafts, setCommentDrafts] = useState<Record<string, string>>({});
  const [editingComment, setEditingComment] = useState<{ taskId: string; commentId: string; text: string } | null>(null);

  const viewingTask = useMemo(
    () => (viewingTaskId ? tasks.find((tk) => tk.id === viewingTaskId) || null : null),
    [tasks, viewingTaskId]
  );

  const toggleTaskComments = (taskId: string) => {
    setExpandedCommentTaskIds((prev) => {
      const next = new Set(prev);
      if (next.has(taskId)) next.delete(taskId);
      else next.add(taskId);
      return next;
    });
  };

  const handleAddComment = async (task: AgencyTask) => {
    const text = (commentDrafts[task.id] || "").trim();
    if (!text || !onUpdateComments) return;
    const newComment: AgencyTaskComment = {
      id: typeof crypto !== "undefined" && crypto.randomUUID ? crypto.randomUUID() : `c-${Date.now()}-${Math.random().toString(36).slice(2, 7)}`,
      author_id: currentUserId,
      author_name: currentUserName,
      text,
      created_at: new Date().toISOString(),
    };
    const nextComments = [...(Array.isArray(task.comments) ? task.comments : []), newComment];
    setCommentDrafts((prev) => ({ ...prev, [task.id]: "" }));
    await onUpdateComments(task, nextComments);
  };

  const handleSaveEditedComment = async (task: AgencyTask) => {
    if (!editingComment || editingComment.taskId !== task.id || !onUpdateComments) return;
    const trimmed = editingComment.text.trim();
    if (!trimmed) return;
    const existing = Array.isArray(task.comments) ? task.comments : [];
    const nextComments = existing.map((c) =>
      c.id === editingComment.commentId
        ? { ...c, text: trimmed, updated_at: new Date().toISOString() }
        : c
    );
    setEditingComment(null);
    await onUpdateComments(task, nextComments);
  };

  const handleDeleteComment = async (task: AgencyTask, commentId: string) => {
    if (!onUpdateComments) return;
    const existing = Array.isArray(task.comments) ? task.comments : [];
    const nextComments = existing.filter((c) => c.id !== commentId);
    if (editingComment?.commentId === commentId) setEditingComment(null);
    await onUpdateComments(task, nextComments);
  };

  const renderCommentsSection = (task: AgencyTask, compact = false) => {
    const taskComments = Array.isArray(task.comments) ? task.comments : [];
    const draft = commentDrafts[task.id] || "";
    return (
      <div className={compact ? "mt-2.5 pt-2.5 border-t border-slate-100" : "space-y-3"}>
        <div className={compact ? "border-l-2 border-[#1B5888]/30 pl-3 space-y-2" : "space-y-2.5"}>
          {taskComments.length === 0 ? (
            <p className="text-[11px] text-[#8A8A8A] italic">{t("agency_tasks_comments_empty")}</p>
          ) : (
            <div className="space-y-2">
              {taskComments.map((c) => {
                const isEditingThis =
                  editingComment?.taskId === task.id && editingComment?.commentId === c.id;
                const canModifyComment =
                  isAgencyAdmin || (Boolean(currentUserId) && c.author_id === currentUserId);
                return (
                  <div
                    key={c.id}
                    className="bg-[#F8F7F5] rounded-[8px] border border-[#E5E3DF] px-3 py-2 space-y-1"
                  >
                    <div className="flex items-center justify-between gap-2">
                      <div className="flex items-center gap-1.5 text-[11px] min-w-0 flex-wrap">
                        <span className="font-bold text-[#1A1A1A] truncate">{c.author_name}</span>
                        <span className="text-[10px] text-[#8A8A8A]">
                          {new Date(c.created_at).toLocaleString(activeLocale, {
                            day: "numeric",
                            month: "short",
                            hour: "2-digit",
                            minute: "2-digit",
                          })}
                        </span>
                        {c.updated_at && (
                          <span className="text-[10px] text-[#8A8A8A] italic">
                            ({t("agency_tasks_comment_edited")})
                          </span>
                        )}
                      </div>
                      {canModifyComment && !isEditingThis && onUpdateComments && (
                        <div className="flex items-center gap-1 shrink-0">
                          <button
                            type="button"
                            onClick={() =>
                              setEditingComment({ taskId: task.id, commentId: c.id, text: c.text })
                            }
                            className="p-1 rounded text-[#666666] hover:text-[#1B5888] hover:bg-white cursor-pointer"
                            title={t("agency_tasks_comment_edit_btn")}
                          >
                            <Pencil className="w-3 h-3" />
                          </button>
                          <button
                            type="button"
                            onClick={() => handleDeleteComment(task, c.id)}
                            className="p-1 rounded text-[#666666] hover:text-rose-600 hover:bg-white cursor-pointer"
                            title={t("agency_tasks_btn_delete")}
                          >
                            <Trash2 className="w-3 h-3" />
                          </button>
                        </div>
                      )}
                    </div>

                    {isEditingThis ? (
                      <div className="space-y-1.5 pt-1">
                        <textarea
                          rows={2}
                          value={editingComment.text}
                          onChange={(e) =>
                            setEditingComment({ ...editingComment, text: e.target.value })
                          }
                          className="w-full px-2.5 py-1.5 rounded-[8px] border border-[#1B5888] bg-white text-xs text-[#1A1A1A] focus:outline-hidden resize-none"
                        />
                        <div className="flex items-center justify-end gap-1.5">
                          <button
                            type="button"
                            onClick={() => setEditingComment(null)}
                            className="px-2 py-1 rounded-[6px] border border-[#E5E3DF] bg-white text-[11px] font-semibold text-[#4A4A4A] hover:bg-slate-50 cursor-pointer"
                          >
                            {t("agency_panel_cancel_btn")}
                          </button>
                          <button
                            type="button"
                            onClick={() => handleSaveEditedComment(task)}
                            className="inline-flex items-center gap-1 px-2.5 py-1 rounded-[6px] bg-[#1B5888] hover:bg-[#15466d] text-white text-[11px] font-bold cursor-pointer"
                          >
                            <Check className="w-3 h-3" />
                            <span>{t("agency_tasks_comment_save_btn")}</span>
                          </button>
                        </div>
                      </div>
                    ) : (
                      <p className="text-xs text-[#333333] whitespace-pre-wrap break-words">{c.text}</p>
                    )}
                  </div>
                );
              })}
            </div>
          )}

          {onUpdateComments && (
            <div className="flex items-center gap-2 pt-1">
              <input
                type="text"
                value={draft}
                onChange={(e) =>
                  setCommentDrafts((prev) => ({ ...prev, [task.id]: e.target.value }))
                }
                onKeyDown={(e) => {
                  if (e.key === "Enter" && !e.shiftKey) {
                    e.preventDefault();
                    handleAddComment(task);
                  }
                }}
                placeholder={t("agency_tasks_comment_placeholder")}
                className="flex-1 px-2.5 py-1.5 rounded-[8px] border border-[#E5E3DF] bg-white text-xs text-[#1A1A1A] focus:outline-hidden focus:border-[#1B5888]"
              />
              <button
                type="button"
                disabled={!draft.trim()}
                onClick={() => handleAddComment(task)}
                className="inline-flex items-center gap-1 px-3 py-1.5 rounded-[8px] bg-[#1B5888] hover:bg-[#15466d] text-white text-xs font-bold transition-colors cursor-pointer disabled:opacity-40 shrink-0"
              >
                <Send className="w-3 h-3" />
                <span>{t("agency_tasks_comment_add_btn")}</span>
              </button>
            </div>
          )}
        </div>
      </div>
    );
  };

  useEffect(() => {
    setPropertyFilter(initialPropertyFilter || null);
    if (initialPropertyFilter) {
      setListingFilter(null);
      setStatusFilter("all");
      setSourceFilter("all");
      setAssigneeFilter("all");
    }
  }, [initialPropertyFilter]);

  useEffect(() => {
    setListingFilter(initialListingFilter || null);
    if (initialListingFilter) {
      setPropertyFilter(null);
      setStatusFilter("all");
      setSourceFilter("all");
      setAssigneeFilter("all");
    }
  }, [initialListingFilter]);

  const assigneeMap = useMemo(() => new Map(assignees.map((a) => [a.id, a])), [assignees]);
  const propMap = useMemo(() => new Map(properties.map((p) => [p.id, p])), [properties]);
  const listingMap = useMemo(() => new Map(listings.map((l) => [l.id, l])), [listings]);
  const leadMap = useMemo(() => new Map(leads.map((ld) => [ld.id, ld])), [leads]);
  const maintMap = useMemo(() => new Map(maintenanceRequests.map((m) => [m.id, m])), [maintenanceRequests]);

  const stats = useMemo(() => {
    const open = tasks.filter((tk) => tk.status === "todo" || tk.status === "in_progress").length;
    const mine = tasks.filter(
      (tk) => tk.assigned_to === currentUserId && (tk.status === "todo" || tk.status === "in_progress")
    ).length;
    const urgent = tasks.filter(
      (tk) => (tk.priority === "high" || tk.priority === "urgent") && tk.status !== "done" && tk.status !== "cancelled"
    ).length;
    const done = tasks.filter((tk) => tk.status === "done").length;
    return { open, mine, urgent, done };
  }, [tasks, currentUserId]);

  const filteredTasks = useMemo(() => {
    const q = search.trim().toLowerCase();
    return tasks.filter((tk) => {
      if (propertyFilter && tk.property_id !== propertyFilter) return false;
      if (listingFilter && tk.listing_id !== listingFilter) return false;
      if (viewMode === "list") {
        if (statusFilter === "open" && (tk.status === "done" || tk.status === "cancelled")) return false;
        if (statusFilter !== "all" && statusFilter !== "open" && tk.status !== statusFilter) return false;
      } else {
        if (tk.status === "cancelled") return false;
      }
      if (statusFilter === "open" && (tk.status === "done" || tk.status === "cancelled")) return false;
      if (statusFilter !== "all" && statusFilter !== "open" && tk.status !== statusFilter) return false;
      if (urgentOnly && tk.priority !== "high" && tk.priority !== "urgent") return false;
      if (sourceFilter !== "all" && tk.source_type !== sourceFilter) return false;
      if (assigneeFilter === "mine" && tk.assigned_to !== currentUserId) return false;
      if (assigneeFilter === "unassigned" && tk.assigned_to) return false;
      if (
        assigneeFilter !== "all" &&
        assigneeFilter !== "mine" &&
        assigneeFilter !== "unassigned" &&
        tk.assigned_to !== assigneeFilter
      ) {
        return false;
      }
      if (q) {
        const linkedLabel = getLinkedEntityLabel(tk).toLowerCase();
        const assigneeName = (tk.assigned_to ? assigneeMap.get(tk.assigned_to)?.name : "") || "";
        const match =
          tk.title.toLowerCase().includes(q) ||
          (tk.description || "").toLowerCase().includes(q) ||
          linkedLabel.includes(q) ||
          assigneeName.toLowerCase().includes(q);
        if (!match) return false;
      }
      return true;
    });
  }, [tasks, propertyFilter, listingFilter, statusFilter, urgentOnly, sourceFilter, assigneeFilter, search, currentUserId, assigneeMap, propMap, listingMap, leadMap, maintMap]);

function getLinkedEntityLabel(tk: AgencyTask): string {
  if (tk.source_type === "property" && tk.property_id) {
    const p = propMap.get(tk.property_id);
    return p?.title || p?.address || t("agency_tasks_source_property");
  }
  if (tk.source_type === "listing" && tk.listing_id) {
    const l = listingMap.get(tk.listing_id);
    return l?.title || l?.address || t("agency_tasks_source_listing");
  }
  if (tk.source_type === "lead" && tk.lead_id) {
    const ld = leadMap.get(tk.lead_id);
    return ld ? `${ld.client_name}${ld.listing_title ? ` • ${ld.listing_title}` : ""}` : t("agency_tasks_source_lead");
  }
  if (tk.source_type === "maintenance" && tk.maintenance_request_id) {
    const m = maintMap.get(tk.maintenance_request_id);
    return m ? `${m.title}${m.property_title ? ` • ${m.property_title}` : ""}` : t("agency_tasks_source_maintenance");
  }
  return t("agency_tasks_source_manual");
}

function getSourceMeta(source: AgencyTaskSourceType) {
  switch (source) {
    case "property":
      return { icon: Home, label: t("agency_tasks_source_property"), tab: "managed_properties" as AgencyPanelTab, cls: "bg-blue-50 text-blue-700 border-blue-200" };
    case "listing":
      return { icon: Building2, label: t("agency_tasks_source_listing"), tab: "listings" as AgencyPanelTab, cls: "bg-indigo-50 text-indigo-700 border-indigo-200" };
    case "lead":
      return { icon: Inbox, label: t("agency_tasks_source_lead"), tab: "leads" as AgencyPanelTab, cls: "bg-amber-50 text-amber-800 border-amber-200" };
    case "maintenance":
      return { icon: Wrench, label: t("agency_tasks_source_maintenance"), tab: "maintenance" as AgencyPanelTab, cls: "bg-rose-50 text-rose-700 border-rose-200" };
    default:
      return { icon: ClipboardList, label: t("agency_tasks_source_manual"), tab: null, cls: "bg-slate-100 text-slate-700 border-slate-200" };
  }
}

function getPriorityCls(priority: AgencyTaskPriority) {
  switch (priority) {
    case "urgent":
      return "bg-rose-50 text-rose-700 border-rose-200";
    case "high":
      return "bg-amber-50 text-amber-800 border-amber-200";
    case "low":
      return "bg-slate-100 text-slate-600 border-slate-200";
    default:
      return "bg-sky-50 text-sky-700 border-sky-200";
  }
}

const todayIso = new Date().toISOString().split("T")[0];

return (
  <div className="space-y-5 pb-16">
    {/* Header */}
    <div className="bg-white rounded-[10px] border border-[#E5E3DF] p-5 shadow-[0_1px_0_rgba(0,0,0,0.04),0_2px_8px_rgba(0,0,0,0.06)] flex flex-col sm:flex-row sm:items-center justify-between gap-4">
      <div>
        <h2 className="text-lg font-bold text-[#1A1A1A] flex items-center gap-2">
          <CheckSquare className="w-5 h-5 text-[#1B5888]" />
          <span>{t("agency_tasks_page_title")}</span>
        </h2>
        <p className="text-xs text-[#666666] mt-0.5">{t("agency_tasks_page_subtitle")}</p>
      </div>

      <div className="flex items-center gap-2.5 flex-wrap shrink-0">
        <div className="flex items-center bg-slate-100 p-1 rounded-[10px] border border-[#E5E3DF]">
          <button
            type="button"
            onClick={() => setViewMode("list")}
            className={`inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-bold cursor-pointer transition-all ${viewMode === "list"
              ? "bg-white text-[#1A1A1A] shadow-xs"
              : "text-[#4A4A4A] hover:text-[#1A1A1A]"
              }`}
          >
            <List className="w-3.5 h-3.5" />
            <span>{t("agency_panel_view_list")}</span>
          </button>
          <button
            type="button"
            onClick={() => setViewMode("kanban")}
            className={`inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-bold cursor-pointer transition-all ${viewMode === "kanban"
              ? "bg-white text-[#1A1A1A] shadow-xs"
              : "text-[#4A4A4A] hover:text-[#1A1A1A]"
              }`}
          >
            <LayoutGrid className="w-3.5 h-3.5" />
            <span>{t("agency_panel_view_kanban")}</span>
          </button>
        </div>

        <button
          type="button"
          onClick={() => onOpenCreateModal({ source_type: "manual" })}
          className="inline-flex items-center justify-center gap-1.5 px-4 py-2.5 rounded-[10px] bg-[#1B5888] hover:bg-[#15466d] text-white text-xs font-bold transition-colors cursor-pointer shrink-0"
        >
          <Plus className="w-4 h-4" />
          <span>{t("agency_tasks_btn_new")}</span>
        </button>
      </div>
    </div>

    {/* KPI Row */}
    <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
      <button
        type="button"
        onClick={() => {
          setStatusFilter("open");
          setAssigneeFilter("all");
          setUrgentOnly(false);
        }}
        className={`text-left p-4 bg-white rounded-[10px] border transition-colors cursor-pointer ${
          statusFilter === "open" && assigneeFilter === "all" && !urgentOnly
            ? "border-[#1B5888] ring-1 ring-[#1B5888]/20"
            : "border-[#E5E3DF] hover:border-[#1B5888]/40"
        }`}
      >
        <span className="text-xs font-semibold text-[#666666] flex items-center gap-1.5">
          <Clock className="w-3.5 h-3.5 text-[#1B5888]" />
          {t("agency_tasks_kpi_open")}
        </span>
        <div className="text-2xl font-bold text-[#1A1A1A] mt-1 font-mono">{stats.open}</div>
      </button>

      <button
        type="button"
        onClick={() => {
          setStatusFilter("open");
          setAssigneeFilter("mine");
          setUrgentOnly(false);
        }}
        className={`text-left p-4 bg-white rounded-[10px] border transition-colors cursor-pointer ${
          assigneeFilter === "mine" && !urgentOnly
            ? "border-indigo-500 ring-1 ring-indigo-500/20"
            : "border-[#E5E3DF] hover:border-[#1B5888]/40"
        }`}
      >
        <span className="text-xs font-semibold text-[#666666] flex items-center gap-1.5">
          <UserCheck className="w-3.5 h-3.5 text-indigo-600" />
          {t("agency_tasks_kpi_mine")}
        </span>
        <div className="text-2xl font-bold text-indigo-700 mt-1 font-mono">{stats.mine}</div>
      </button>

      <button
        type="button"
        onClick={() => {
          if (urgentOnly) {
            setUrgentOnly(false);
          } else {
            setStatusFilter("open");
            setAssigneeFilter("all");
            setUrgentOnly(true);
          }
        }}
        className={`text-left p-4 bg-white rounded-[10px] border transition-colors cursor-pointer ${
          urgentOnly
            ? "border-rose-500 ring-1 ring-rose-500/20"
            : "border-[#E5E3DF] hover:border-rose-300"
        }`}
      >
        <span className="text-xs font-semibold text-[#666666] flex items-center gap-1.5">
          <Flag className="w-3.5 h-3.5 text-rose-600" />
          {t("agency_tasks_kpi_urgent")}
        </span>
        <div className="text-2xl font-bold text-rose-600 mt-1 font-mono">{stats.urgent}</div>
      </button>

      <button
        type="button"
        onClick={() => {
          setStatusFilter("done");
          setAssigneeFilter("all");
          setUrgentOnly(false);
        }}
        className={`text-left p-4 bg-white rounded-[10px] border transition-colors cursor-pointer ${
          statusFilter === "done" && !urgentOnly
            ? "border-emerald-500 ring-1 ring-emerald-500/20"
            : "border-[#E5E3DF] hover:border-emerald-300"
        }`}
      >
        <span className="text-xs font-semibold text-[#666666] flex items-center gap-1.5">
          <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600" />
          {t("agency_tasks_kpi_done")}
        </span>
        <div className="text-2xl font-bold text-emerald-700 mt-1 font-mono">{stats.done}</div>
      </button>
    </div>

      {/* Active Property Filter Chip */ }
{
  propertyFilter && (
    <div className="flex items-center gap-2 px-3.5 py-2 rounded-[10px] bg-[#E5EEF6] border border-[#1B5888]/20 text-xs font-semibold text-[#1B5888]">
      <Home className="w-3.5 h-3.5 shrink-0" />
      <span>
        {t("agency_tasks_source_property")}:{" "}
        <strong>{propMap.get(propertyFilter)?.title || propMap.get(propertyFilter)?.address || propertyFilter}</strong>
      </span>
      <button
        type="button"
        onClick={() => {
          setPropertyFilter(null);
          onClearPropertyFilter?.();
        }}
        className="ml-auto p-0.5 rounded hover:bg-[#1B5888]/10 cursor-pointer"
      >
        <X className="w-3.5 h-3.5" />
      </button>
    </div>
  )
}

{/* Active Listing Filter Chip */ }
{
  listingFilter && (
    <div className="flex items-center gap-2 px-3.5 py-2 rounded-[10px] bg-indigo-50 border border-indigo-200 text-xs font-semibold text-indigo-800">
      <Building2 className="w-3.5 h-3.5 shrink-0" />
      <span>
        {t("agency_tasks_source_listing")}:{" "}
        <strong>{listingMap.get(listingFilter)?.title || listingMap.get(listingFilter)?.address || listingFilter}</strong>
      </span>
      <button
        type="button"
        onClick={() => {
          setListingFilter(null);
          onClearListingFilter?.();
        }}
        className="ml-auto p-0.5 rounded hover:bg-indigo-100 cursor-pointer"
      >
        <X className="w-3.5 h-3.5" />
      </button>
    </div>
  )
}

{/* Filters */ }
<div className="bg-white rounded-[10px] border border-[#E5E3DF] p-3.5 flex flex-col md:flex-row gap-2.5">
  <div className="relative flex-1">
    <Search className="w-4 h-4 text-[#8A8A8A] absolute left-3 top-1/2 -translate-y-1/2" />
    <input
      type="text"
      value={search}
      onChange={(e) => setSearch(e.target.value)}
      placeholder={t("agency_tasks_search_placeholder")}
      className="w-full pl-9 pr-3 py-2 rounded-[8px] border border-[#E5E3DF] text-xs focus:outline-hidden focus:border-[#1B5888]"
    />
  </div>

  <select
    value={statusFilter}
    onChange={(e) => setStatusFilter(e.target.value as any)}
    className="px-3 py-2 rounded-[8px] border border-[#E5E3DF] text-xs bg-white"
  >
    <option value="open">{t("agency_tasks_filter_open")}</option>
    <option value="all">{t("agency_tasks_filter_all_status")}</option>
    <option value="todo">{t("agency_tasks_status_todo")}</option>
    <option value="in_progress">{t("agency_tasks_status_in_progress")}</option>
    <option value="done">{t("agency_tasks_status_done")}</option>
  </select>

  <select
    value={sourceFilter}
    onChange={(e) => setSourceFilter(e.target.value as any)}
    className="px-3 py-2 rounded-[8px] border border-[#E5E3DF] text-xs bg-white"
  >
    <option value="all">{t("agency_tasks_filter_all_sources")}</option>
    <option value="manual">{t("agency_tasks_source_manual")}</option>
    <option value="property">{t("agency_tasks_source_property")}</option>
    <option value="listing">{t("agency_tasks_source_listing")}</option>
    <option value="lead">{t("agency_tasks_source_lead")}</option>
    <option value="maintenance">{t("agency_tasks_source_maintenance")}</option>
  </select>

  <select
    value={assigneeFilter}
    onChange={(e) => setAssigneeFilter(e.target.value)}
    className="px-3 py-2 rounded-[8px] border border-[#E5E3DF] text-xs bg-white"
  >
    <option value="all">{t("agency_tasks_filter_all_assignees")}</option>
    <option value="mine">{t("agency_tasks_filter_mine")}</option>
    <option value="unassigned">{t("agency_tasks_unassigned")}</option>
    {assignees.map((a) => (
      <option key={a.id} value={a.id}>
        {a.name}
      </option>
    ))}
  </select>
</div>

{/* Tasks List or Kanban Board */ }
{
  loading ? (
    <div className="bg-white rounded-[10px] border border-[#E5E3DF] py-12 text-center text-xs text-[#666666]">
      {t("loading")}
    </div>
  ) : filteredTasks.length === 0 ? (
    <div className="bg-white rounded-[10px] border border-[#E5E3DF] py-14 px-4 text-center">
      <CheckSquare className="w-9 h-9 text-[#8A8A8A] mx-auto mb-2" />
      <p className="text-sm font-bold text-[#1A1A1A]">{t("agency_tasks_empty_title")}</p>
      <p className="text-xs text-[#666666] mt-1">{t("agency_tasks_empty_desc")}</p>
    </div>
  ) : viewMode === "kanban" ? (
    <div className="grid grid-cols-1 lg:grid-cols-3 gap-4 items-start">
      {(
        [
          {
            status: "todo" as AgencyTaskStatus,
            label: t("agency_tasks_status_todo"),
            columnCls: "bg-slate-50/80 border-[#E5E3DF]",
            badgeCls: "bg-slate-200/80 text-slate-700",
            dotCls: "bg-slate-400",
          },
          {
            status: "in_progress" as AgencyTaskStatus,
            label: t("agency_tasks_status_in_progress"),
            columnCls: "bg-[#E5EEF6]/40 border-[#1B5888]/20",
            badgeCls: "bg-[#E5EEF6] text-[#1B5888]",
            dotCls: "bg-[#1B5888]",
          },
          {
            status: "done" as AgencyTaskStatus,
            label: t("agency_tasks_status_done"),
            columnCls: "bg-emerald-50/50 border-emerald-200/70",
            badgeCls: "bg-emerald-100 text-emerald-800",
            dotCls: "bg-emerald-500",
          },
        ] as const
      ).map((col) => {
        const colTasks = filteredTasks.filter((tk) => tk.status === col.status);
        const isDropTarget = dragOverStatus === col.status;

        return (
          <div
            key={col.status}
            onDragOver={(e) => {
              e.preventDefault();
              if (dragOverStatus !== col.status) setDragOverStatus(col.status);
            }}
            onDragLeave={() => {
              if (dragOverStatus === col.status) setDragOverStatus(null);
            }}
            onDrop={async (e) => {
              e.preventDefault();
              setDragOverStatus(null);
              const taskId = e.dataTransfer.getData("text/plain") || draggedTaskId;
              setDraggedTaskId(null);
              if (!taskId) return;
              const targetTask = tasks.find((tItem) => tItem.id === taskId);
              if (!targetTask || targetTask.status === col.status) return;
              const canMove =
                isAgencyAdmin ||
                targetTask.assigned_to === currentUserId ||
                targetTask.created_by === currentUserId ||
                !targetTask.assigned_to;
              if (canMove) {
                await onQuickStatusChange(targetTask, col.status);
              }
            }}
            className={`rounded-[12px] border p-3 space-y-3 min-h-[260px] transition-all ${col.columnCls} ${isDropTarget ? "ring-2 ring-[#1B5888] bg-[#E5EEF6]/60" : ""
              }`}
          >
            <div className="flex items-center justify-between gap-2 pb-2 border-b border-black/5">
              <div className="flex items-center gap-2 min-w-0">
                <span className={`w-2 h-2 rounded-full shrink-0 ${col.dotCls}`} />
                <h3 className="text-xs font-bold text-[#1A1A1A] truncate">{col.label}</h3>
              </div>
              <span className={`text-[11px] font-bold px-2 py-0.5 rounded-full tabular-nums ${col.badgeCls}`}>
                {colTasks.length}
              </span>
            </div>

            {colTasks.length === 0 ? (
              <div className="py-8 px-3 rounded-[10px] border border-dashed border-[#E5E3DF] text-center text-[11px] text-[#8A8A8A]">
                —
              </div>
            ) : (
              <div className="space-y-2.5">
                {colTasks.map((tk) => {
                  const src = getSourceMeta(tk.source_type);
                  const SrcIcon = src.icon;
                  const linkedLabel = getLinkedEntityLabel(tk);
                  const assignee = tk.assigned_to ? assigneeMap.get(tk.assigned_to) : null;
                  const isOverdue = Boolean(tk.due_date && tk.due_date < todayIso && tk.status !== "done");
                  const canEdit =
                    isAgencyAdmin ||
                    tk.assigned_to === currentUserId ||
                    tk.created_by === currentUserId ||
                    !tk.assigned_to;
                  const canDelete = isAgencyAdmin || tk.created_by === currentUserId;
                  const canClaim = !tk.assigned_to && Boolean(currentUserId);

                  return (
                    <div
                      key={tk.id}
                      draggable={canEdit}
                      onDragStart={(e) => {
                        setDraggedTaskId(tk.id);
                        e.dataTransfer.setData("text/plain", tk.id);
                      }}
                      onDragEnd={() => {
                        setDraggedTaskId(null);
                        setDragOverStatus(null);
                      }}
                      className={`bg-white rounded-[10px] border border-[#E5E3DF] p-3 shadow-2xs hover:border-[#1B5888]/40 hover:shadow-xs transition-all space-y-2.5 ${canEdit ? "cursor-grab active:cursor-grabbing" : ""
                        } ${draggedTaskId === tk.id ? "opacity-50" : ""}`}
                    >
                      <div className="flex items-center justify-between gap-2 flex-wrap">
                        <span
                          className={`text-[10px] font-semibold px-2 py-0.5 rounded-[6px] border inline-flex items-center gap-1 ${src.cls}`}
                        >
                          <SrcIcon className="w-3 h-3" />
                          {src.label}
                        </span>
                        <span
                          className={`text-[10px] font-semibold px-2 py-0.5 rounded-[6px] border ${getPriorityCls(tk.priority)}`}
                        >
                          {t(`agency_tasks_priority_${tk.priority}`)}
                        </span>
                      </div>

                      <div className="space-y-1">
                        <button
                          type="button"
                          onClick={() => setViewingTaskId(tk.id)}
                          className={`text-left text-xs font-bold leading-snug hover:text-[#1B5888] hover:underline cursor-pointer ${tk.status === "done" ? "line-through text-[#8A8A8A]" : "text-[#1A1A1A]"
                            }`}
                        >
                          {tk.title}
                        </button>
                        {tk.description && (
                          <p className="text-[11px] text-[#666666] line-clamp-2">{tk.description}</p>
                        )}
                      </div>

                      <div className="flex items-center gap-2.5 text-[11px] text-[#666666] flex-wrap">
                        {tk.source_type !== "manual" && (
                          <button
                            type="button"
                            onClick={() => src.tab && onNavigateTab(src.tab)}
                            className="font-semibold text-[#1B5888] hover:underline cursor-pointer truncate max-w-full text-left"
                          >
                            {linkedLabel}
                          </button>
                        )}
                        {tk.due_date && (
                          <span
                            className={`inline-flex items-center gap-1 font-medium ${isOverdue ? "text-rose-600 font-bold" : ""
                              }`}
                          >
                            <Calendar className="w-3 h-3" />
                            {tk.due_date}
                          </span>
                        )}
                      </div>

                      <div className="pt-2 border-t border-slate-100 flex items-center justify-between gap-2 flex-wrap">
                        <span className="inline-flex items-center gap-1 text-[11px] text-[#666666] truncate">
                          <UserCheck className="w-3 h-3 text-[#8A8A8A] shrink-0" />
                          <span className="truncate">
                            {assignee ? assignee.name : t("agency_tasks_unassigned")}
                          </span>
                        </span>

                        <div className="flex items-center gap-1.5 flex-wrap">
                          {canClaim && !isAgencyAdmin && (
                            <button
                              type="button"
                              onClick={() => onQuickAssign(tk, currentUserId)}
                              className="inline-flex items-center gap-1 px-2 py-1 rounded-[6px] bg-[#E5EEF6] text-[#1B5888] hover:bg-[#1B5888] hover:text-white text-[10px] font-semibold transition-colors cursor-pointer"
                            >
                              <UserPlus className="w-3 h-3" />
                              <span>{t("agency_tasks_btn_claim")}</span>
                            </button>
                          )}

                          {canEdit && (
                            <select
                              value={tk.status}
                              onChange={(e) => onQuickStatusChange(tk, e.target.value as AgencyTaskStatus)}
                              aria-label={t("agency_tasks_field_status")}
                              className="px-1.5 py-1 rounded-[6px] border border-[#E5E3DF] text-[10px] bg-white font-semibold"
                            >
                              <option value="todo">{t("agency_tasks_status_todo")}</option>
                              <option value="in_progress">{t("agency_tasks_status_in_progress")}</option>
                              <option value="done">{t("agency_tasks_status_done")}</option>
                            </select>
                          )}

                          <button
                            type="button"
                            onClick={() => toggleTaskComments(tk.id)}
                            className={`inline-flex items-center gap-1 px-1.5 py-1 rounded-[6px] border text-[10px] font-bold transition-colors cursor-pointer ${expandedCommentTaskIds.has(tk.id)
                              ? "bg-[#1B5888] text-white border-[#1B5888]"
                              : (tk.comments?.length || 0) > 0
                                ? "bg-[#E5EEF6] text-[#1B5888] border-[#1B5888]/20 hover:bg-[#1B5888] hover:text-white"
                                : "bg-white text-[#666666] border-[#E5E3DF] hover:bg-slate-50"
                              }`}
                            title={t("agency_tasks_comments_title")}
                          >
                            <MessageSquare className="w-3 h-3" />
                            <span>{tk.comments?.length || 0}</span>
                          </button>

                          <button
                            type="button"
                            onClick={() => setViewingTaskId(tk.id)}
                            className="p-1 rounded-[6px] border border-[#E5E3DF] text-[#4A4A4A] hover:bg-slate-50 cursor-pointer"
                            title={t("agency_tasks_btn_view")}
                          >
                            <Eye className="w-3 h-3" />
                          </button>

                          {canEdit && (
                            <button
                              type="button"
                              onClick={() => onOpenEditModal(tk)}
                              className="p-1 rounded-[6px] border border-[#E5E3DF] text-[#4A4A4A] hover:bg-slate-50 cursor-pointer"
                              title={t("agency_tasks_btn_edit")}
                            >
                              <Pencil className="w-3 h-3" />
                            </button>
                          )}

                          {canDelete && (
                            <button
                              type="button"
                              onClick={() => onDeleteTask(tk)}
                              className="p-1 rounded-[6px] border border-rose-200 text-rose-600 hover:bg-rose-50 cursor-pointer"
                              title={t("agency_tasks_btn_delete")}
                            >
                              <Trash2 className="w-3 h-3" />
                            </button>
                          )}
                        </div>
                      </div>
                      {expandedCommentTaskIds.has(tk.id) && renderCommentsSection(tk, true)}
                    </div>
                  );
                })}
              </div>
            )}
          </div>
        );
      })}
    </div>
  ) : (
    <div className="bg-white rounded-[10px] border border-[#E5E3DF] overflow-hidden shadow-[0_1px_0_rgba(0,0,0,0.04)]">
      <div className="divide-y divide-[#E5E3DF]">
        {filteredTasks.map((tk) => {
          const src = getSourceMeta(tk.source_type);
          const SrcIcon = src.icon;
          const linkedLabel = getLinkedEntityLabel(tk);
          const assignee = tk.assigned_to ? assigneeMap.get(tk.assigned_to) : null;
          const isOverdue = Boolean(tk.due_date && tk.due_date < todayIso && tk.status !== "done");
          const canEdit = isAgencyAdmin || tk.assigned_to === currentUserId || tk.created_by === currentUserId || !tk.assigned_to;
          const canDelete = isAgencyAdmin || tk.created_by === currentUserId;
          const canClaim = !tk.assigned_to && Boolean(currentUserId);

          return (
            <div
              key={tk.id}
              className="p-4 hover:bg-[#F8F7F5]/60 transition-colors"
            >
              <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-3">
                <div className="min-w-0 flex-1 space-y-1.5">
                  <div className="flex items-center gap-2 flex-wrap">
                    <button
                      type="button"
                      onClick={() => setViewingTaskId(tk.id)}
                      className={`text-left text-sm font-bold hover:text-[#1B5888] hover:underline cursor-pointer ${tk.status === "done" ? "line-through text-[#8A8A8A]" : "text-[#1A1A1A]"
                        }`}
                    >
                      {tk.title}
                    </button>

                    <span className={`text-[11px] font-semibold px-2 py-0.5 rounded-[6px] border inline-flex items-center gap-1 ${src.cls}`}>
                      <SrcIcon className="w-3 h-3" />
                      {src.label}
                    </span>

                    <span className={`text-[11px] font-semibold px-2 py-0.5 rounded-[6px] border ${getPriorityCls(tk.priority)}`}>
                      {t(`agency_tasks_priority_${tk.priority}`)}
                    </span>
                  </div>

                  {tk.description && (
                    <p className="text-xs text-[#666666] line-clamp-2">{tk.description}</p>
                  )}

                  <div className="flex items-center gap-3 text-[11px] text-[#666666] flex-wrap">
                    {tk.source_type !== "manual" && (
                      <button
                        type="button"
                        onClick={() => src.tab && onNavigateTab(src.tab)}
                        className="font-semibold text-[#1B5888] hover:underline cursor-pointer"
                      >
                        {linkedLabel}
                      </button>
                    )}

                    {tk.due_date && (
                      <span className={`inline-flex items-center gap-1 font-medium ${isOverdue ? "text-rose-600 font-bold" : ""}`}>
                        <Calendar className="w-3 h-3" />
                        {tk.due_date}
                      </span>
                    )}

                    <span className="inline-flex items-center gap-1">
                      <UserCheck className="w-3 h-3 text-[#8A8A8A]" />
                      {assignee ? assignee.name : t("agency_tasks_unassigned")}
                    </span>
                  </div>
                </div>

                <div className="flex items-center gap-2 flex-wrap shrink-0">
                  {canClaim && !isAgencyAdmin && (
                    <button
                      type="button"
                      onClick={() => onQuickAssign(tk, currentUserId)}
                      className="inline-flex items-center gap-1 px-2.5 py-1.5 rounded-[8px] bg-[#E5EEF6] text-[#1B5888] hover:bg-[#1B5888] hover:text-white text-xs font-semibold transition-colors cursor-pointer"
                    >
                      <UserPlus className="w-3.5 h-3.5" />
                      <span>{t("agency_tasks_btn_claim")}</span>
                    </button>
                  )}

                  {isAgencyAdmin && (
                    <select
                      value={tk.assigned_to || ""}
                      onChange={(e) => onQuickAssign(tk, e.target.value || null)}
                      aria-label={t("agency_tasks_field_assignee")}
                      className="px-2.5 py-1.5 rounded-[8px] border border-[#E5E3DF] text-xs bg-white max-w-[160px]"
                    >
                      <option value="">{t("agency_tasks_unassigned")}</option>
                      {assignees.map((a) => (
                        <option key={a.id} value={a.id}>
                          {a.name}
                        </option>
                      ))}
                    </select>
                  )}

                  {canEdit && (
                    <select
                      value={tk.status}
                      onChange={(e) => onQuickStatusChange(tk, e.target.value as AgencyTaskStatus)}
                      aria-label={t("agency_tasks_field_status")}
                      className="px-2.5 py-1.5 rounded-[8px] border border-[#E5E3DF] text-xs bg-white font-semibold"
                    >
                      <option value="todo">{t("agency_tasks_status_todo")}</option>
                      <option value="in_progress">{t("agency_tasks_status_in_progress")}</option>
                      <option value="done">{t("agency_tasks_status_done")}</option>
                    </select>
                  )}

                  <button
                    type="button"
                    onClick={() => toggleTaskComments(tk.id)}
                    className={`inline-flex items-center gap-1 px-2 py-1.5 rounded-[8px] border text-xs font-bold transition-colors cursor-pointer ${expandedCommentTaskIds.has(tk.id)
                      ? "bg-[#1B5888] text-white border-[#1B5888]"
                      : (tk.comments?.length || 0) > 0
                        ? "bg-[#E5EEF6] text-[#1B5888] border-[#1B5888]/20 hover:bg-[#1B5888] hover:text-white"
                        : "bg-white text-[#666666] border-[#E5E3DF] hover:bg-slate-50"
                      }`}
                    title={t("agency_tasks_comments_title")}
                  >
                    <MessageSquare className="w-3.5 h-3.5" />
                    <span>{tk.comments?.length || 0}</span>
                  </button>

                  <button
                    type="button"
                    onClick={() => setViewingTaskId(tk.id)}
                    className="p-1.5 rounded-[8px] border border-[#E5E3DF] text-[#4A4A4A] hover:bg-slate-50 cursor-pointer"
                    title={t("agency_tasks_btn_view")}
                  >
                    <Eye className="w-3.5 h-3.5" />
                  </button>

                  {canEdit && (
                    <button
                      type="button"
                      onClick={() => onOpenEditModal(tk)}
                      className="p-1.5 rounded-[8px] border border-[#E5E3DF] text-[#4A4A4A] hover:bg-slate-50 cursor-pointer"
                      title={t("agency_tasks_btn_edit")}
                    >
                      <Pencil className="w-3.5 h-3.5" />
                    </button>
                  )}

                  {canDelete && (
                    <button
                      type="button"
                      onClick={() => onDeleteTask(tk)}
                      className="p-1.5 rounded-[8px] border border-rose-200 text-rose-600 hover:bg-rose-50 cursor-pointer"
                      title={t("agency_tasks_btn_delete")}
                    >
                      <Trash2 className="w-3.5 h-3.5" />
                    </button>
                  )}
                </div>
              </div>
              {expandedCommentTaskIds.has(tk.id) && renderCommentsSection(tk, true)}
            </div>
          );
        })}
      </div>
    </div>
  )
}

{/* Task View Dialog */ }
{
  viewingTask && (() => {
    const src = getSourceMeta(viewingTask.source_type);
    const SrcIcon = src.icon;
    const linkedLabel = getLinkedEntityLabel(viewingTask);
    const assignee = viewingTask.assigned_to ? assigneeMap.get(viewingTask.assigned_to) : null;
    const isOverdue = Boolean(
      viewingTask.due_date && viewingTask.due_date < todayIso && viewingTask.status !== "done"
    );
    const canEdit =
      isAgencyAdmin ||
      viewingTask.assigned_to === currentUserId ||
      viewingTask.created_by === currentUserId ||
      !viewingTask.assigned_to;

    return (
      <div
        className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/50 backdrop-blur-xs"
        onClick={() => setViewingTaskId(null)}
      >
        <div
          className="bg-white rounded-2xl border border-[#E5E3DF] shadow-2xl max-w-xl w-full p-6 space-y-4 max-h-[90vh] overflow-y-auto"
          onClick={(e) => e.stopPropagation()}
        >
          <div className="flex items-start justify-between gap-3 border-b border-slate-100 pb-3">
            <div className="min-w-0 space-y-1">
              <div className="flex items-center gap-2 flex-wrap">
                <span className={`text-[11px] font-semibold px-2 py-0.5 rounded-[6px] border inline-flex items-center gap-1 ${src.cls}`}>
                  <SrcIcon className="w-3 h-3" />
                  {src.label}
                </span>
                <span className={`text-[11px] font-semibold px-2 py-0.5 rounded-[6px] border ${getPriorityCls(viewingTask.priority)}`}>
                  {t(`agency_tasks_priority_${viewingTask.priority}`)}
                </span>
              </div>
              <h3
                className={`text-base font-bold ${viewingTask.status === "done" ? "line-through text-[#8A8A8A]" : "text-[#1A1A1A]"
                  }`}
              >
                {viewingTask.title}
              </h3>
            </div>
            <div className="flex items-center gap-1.5 shrink-0">
              {canEdit && (
                <button
                  type="button"
                  onClick={() => {
                    const target = viewingTask;
                    setViewingTaskId(null);
                    onOpenEditModal(target);
                  }}
                  className="inline-flex items-center gap-1 px-2.5 py-1.5 rounded-[8px] border border-[#E5E3DF] text-xs font-semibold text-[#4A4A4A] hover:bg-slate-50 cursor-pointer"
                >
                  <Pencil className="w-3.5 h-3.5" />
                  <span>{t("agency_tasks_btn_edit")}</span>
                </button>
              )}
              <button
                type="button"
                onClick={() => setViewingTaskId(null)}
                className="p-1.5 rounded-lg text-[#666666] hover:text-[#1A1A1A] cursor-pointer"
              >
                <X className="w-4 h-4" />
              </button>
            </div>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 text-xs bg-[#F8F7F5] rounded-[10px] border border-[#E5E3DF] p-3">
            <div>
              <span className="text-[11px] text-[#666666] block mb-1">{t("agency_tasks_field_status")}</span>
              {canEdit ? (
                <select
                  value={viewingTask.status}
                  onChange={(e) => onQuickStatusChange(viewingTask, e.target.value as AgencyTaskStatus)}
                  className="w-full px-2 py-1 rounded-[6px] border border-[#E5E3DF] bg-white text-xs font-semibold"
                >
                  <option value="todo">{t("agency_tasks_status_todo")}</option>
                  <option value="in_progress">{t("agency_tasks_status_in_progress")}</option>
                  <option value="done">{t("agency_tasks_status_done")}</option>
                </select>
              ) : (
                <span className="font-semibold text-[#1A1A1A]">
                  {t(`agency_tasks_status_${viewingTask.status}`)}
                </span>
              )}
            </div>

            <div>
              <span className="text-[11px] text-[#666666] block mb-1">{t("agency_tasks_field_assignee")}</span>
              {isAgencyAdmin ? (
                <select
                  value={viewingTask.assigned_to || ""}
                  onChange={(e) => onQuickAssign(viewingTask, e.target.value || null)}
                  className="w-full px-2 py-1 rounded-[6px] border border-[#E5E3DF] bg-white text-xs font-semibold"
                >
                  <option value="">{t("agency_tasks_unassigned")}</option>
                  {assignees.map((a) => (
                    <option key={a.id} value={a.id}>
                      {a.name}
                    </option>
                  ))}
                </select>
              ) : (
                <span className="font-semibold text-[#1A1A1A]">
                  {assignee ? assignee.name : t("agency_tasks_unassigned")}
                </span>
              )}
            </div>

            <div>
              <span className="text-[11px] text-[#666666] block mb-1">{t("agency_tasks_field_due_date")}</span>
              <span className={`font-semibold inline-flex items-center gap-1 ${isOverdue ? "text-rose-600" : "text-[#1A1A1A]"}`}>
                <Calendar className="w-3.5 h-3.5" />
                {viewingTask.due_date || "—"}
              </span>
            </div>
          </div>

          {viewingTask.source_type !== "manual" && (
            <div className="flex items-center gap-2 text-xs">
              <span className="text-[#666666] font-semibold">{t("agency_tasks_field_source")}:</span>
              <button
                type="button"
                onClick={() => {
                  if (src.tab) {
                    setViewingTaskId(null);
                    onNavigateTab(src.tab);
                  }
                }}
                className="font-bold text-[#1B5888] hover:underline cursor-pointer"
              >
                {linkedLabel}
              </button>
            </div>
          )}

          <div>
            <h4 className="text-xs font-bold text-[#1A1A1A] mb-1">
              {t("agency_tasks_field_description")}
            </h4>
            {viewingTask.description ? (
              <p className="text-xs text-[#333333] whitespace-pre-wrap leading-relaxed bg-[#F8F7F5] rounded-[10px] border border-[#E5E3DF] p-3">
                {viewingTask.description}
              </p>
            ) : (
              <p className="text-xs text-[#8A8A8A] italic">{t("agency_tasks_no_description")}</p>
            )}
          </div>

          <div className="pt-2 border-t border-slate-100 space-y-2">
            <h4 className="text-xs font-bold text-[#1A1A1A] flex items-center gap-1.5">
              <MessageSquare className="w-3.5 h-3.5 text-[#1B5888]" />
              <span>{t("agency_tasks_comments_title")}</span>
              <span className="text-[10px] font-bold px-1.5 py-0.5 rounded-full bg-[#E5EEF6] text-[#1B5888]">
                {viewingTask.comments?.length || 0}
              </span>
            </h4>
            {renderCommentsSection(viewingTask, false)}
          </div>
        </div>
      </div>
    );
  })()
}
    </div >
  );
}
