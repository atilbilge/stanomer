"use client";

import React from "react";
import {
  Check,
  CheckCircle2,
  Copy,
  ExternalLink,
  Info,
  Layers,
  MessageCircle,
  RefreshCw,
  Rss,
  ShieldCheck,
} from "lucide-react";
import { PortalDef, PortalFeedLogRow } from "../types";
import { PORTAL_LIST } from "../constants";

export interface XmlFeedsTabProps {
  feedLogs: PortalFeedLogRow[];
  loadingFeedLogs: boolean;
  copiedPortal: string | null;
  publishedListingsCount: number;
  getFeedUrl: (file: string) => string;
  formatTimeAgo: (dateIso: string) => string;
  fetchFeedLogs: () => void;
  handleCopyFeedUrl: (portalId: string, file: string) => void;
  handleOpenPortalRequest: (portal: PortalDef) => void;
  t: (key: string) => string;
}

export default function XmlFeedsTab({
  feedLogs,
  loadingFeedLogs,
  copiedPortal,
  publishedListingsCount,
  getFeedUrl,
  formatTimeAgo,
  fetchFeedLogs,
  handleCopyFeedUrl,
  handleOpenPortalRequest,
  t,
}: XmlFeedsTabProps) {
  return (
<div
                  role="tabpanel"
                  id="tabpanel-xml"
                  aria-labelledby="tab-xml"
                  className="space-y-6"
                >
                  <section
                    aria-labelledby="xml-feeds-heading"
                    className="bg-white rounded-[10px] border border-[#E5E3DF] p-6 shadow-xs"
                  >
                    <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2 mb-4">
                      <div>
                        <h2
                          id="xml-feeds-heading"
                          className="text-lg font-bold text-[#1A1A1A] flex items-center gap-2"
                        >
                          <Rss className="w-5 h-5 text-[#1B5888]" />
                          <span>{t("agency_panel_xml_heading")}</span>
                        </h2>
                        <p className="text-xs text-[#666666] mt-0.5">
                          {t("agency_panel_xml_desc")}
                        </p>
                      </div>
                      <span className="inline-flex items-center gap-1.5 text-xs font-semibold text-[#2A6E43] bg-[#E6F3EA] border border-[#2A6E43]/20 px-3 py-1 rounded-full self-start">
                        <CheckCircle2 className="w-3.5 h-3.5" />
                        <span>
                          {publishedListingsCount}{" "}
                          {t("agency_panel_xml_active_count")}
                        </span>
                      </span>
                    </div>

                    {/* Commercial Prerequisite Note */}
                    <div className="mb-4 px-3.5 py-2.5 rounded-[10px] bg-slate-50 border border-[#E5E3DF] flex items-center gap-2.5">
                      <ShieldCheck className="w-4 h-4 text-[#1B5888] shrink-0" />
                      <p className="text-xs text-[#4A4A4A] leading-relaxed">
                        {t("agency_panel_xml_prerequisite_short")}
                      </p>
                    </div>

                    {/* 2x2 Clean Portal Cards Grid */}
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-3.5">
                      {PORTAL_LIST.map((portal) => {
                        const feedUrl = portal.file ? getFeedUrl(portal.file) : "";
                        const isCopied = copiedPortal === portal.id;
                        const isLive = portal.status === "live";
                        const displayName =
                          portal.id === "other"
                            ? t("agency_panel_xml_portal_other_name")
                            : portal.name;

                        return (
                          <div
                            key={portal.id}
                            className="flex flex-col justify-between gap-3 p-4 rounded-[10px] bg-slate-50 border border-[#E5E3DF] hover:border-[#8A8A8A] transition-colors"
                          >
                            <div>
                              <div className="flex items-center justify-between gap-2 mb-2">
                                <span
                                  className={`text-xs font-bold px-2.5 py-0.5 rounded-md border ${portal.badgeColor}`}
                                >
                                  {displayName}
                                </span>
                                <span
                                  className={`text-[10px] font-semibold px-2 py-0.5 rounded-full border ${isLive
                                    ? "bg-[#E6F3EA] text-[#2A6E43] border-[#2A6E43]/20"
                                    : "bg-[#E5EEF6] text-[#1B5888] border-[#1B5888]/20"
                                    }`}
                                >
                                  {isLive
                                    ? t("agency_panel_xml_status_live")
                                    : t("agency_panel_xml_status_on_demand")}
                                </span>
                              </div>

                              <p className="text-xs text-[#666666] mb-2 leading-relaxed">
                                {t(portal.noteKey)}
                              </p>

                              {isLive && (
                                <p className="text-[11px] font-mono text-[#4A4A4A] truncate bg-white px-2.5 py-1.5 rounded-[10px] border border-[#E5E3DF] select-all">
                                  {feedUrl}
                                </p>
                              )}
                            </div>

                            <div className="flex items-center justify-end gap-2 pt-2 border-t border-[#E5E3DF]">
                              {isLive ? (
                                <>
                                  <button
                                    type="button"
                                    onClick={() => handleCopyFeedUrl(portal.id, portal.file!)}
                                    className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-[10px] bg-white border border-[#8A8A8A] hover:bg-slate-100 text-xs font-semibold text-[#4A4A4A] cursor-pointer shadow-2xs"
                                  >
                                    {isCopied ? (
                                      <>
                                        <Check className="w-3.5 h-3.5 text-[#2A6E43]" />
                                        <span>{t("agency_panel_copied")}</span>
                                      </>
                                    ) : (
                                      <>
                                        <Copy className="w-3.5 h-3.5 text-[#666666]" />
                                        <span>{t("agency_panel_copy")}</span>
                                      </>
                                    )}
                                  </button>
                                  <a
                                    href={feedUrl}
                                    target="_blank"
                                    rel="noopener noreferrer"
                                    className="inline-flex items-center gap-1 px-3 py-1.5 rounded-[10px] bg-[#E5EEF6] hover:bg-[#d5e4f1] text-xs font-semibold text-[#1B5888] border border-[#1B5888]/20 shadow-2xs"
                                  >
                                    <span>XML</span>
                                    <ExternalLink className="w-3.5 h-3.5" />
                                  </a>
                                </>
                              ) : (
                                <button
                                  type="button"
                                  onClick={() => handleOpenPortalRequest(portal)}
                                  className="w-full sm:w-auto inline-flex items-center justify-center gap-1.5 px-3.5 py-1.5 rounded-[10px] bg-[#E5EEF6] hover:bg-[#d5e4f1] text-xs font-semibold text-[#1B5888] border border-[#1B5888]/20 cursor-pointer transition-colors shadow-2xs"
                                >
                                  <MessageCircle className="w-3.5 h-3.5 text-[#1B5888]" />
                                  <span>{t("agency_panel_xml_btn_activate")}</span>
                                </button>
                              )}
                            </div>
                          </div>
                        );
                      })}
                    </div>

                    {/* Unified Workflow & Quota Guidance Card */}
                    <div className="mt-4 p-4 rounded-[10px] bg-slate-50 border border-[#E5E3DF] space-y-3.5">
                      <div className="flex items-center gap-2">
                        <Layers className="w-4 h-4 text-[#4A4A4A]" />
                        <h3 className="text-xs font-bold text-[#1A1A1A]">
                          {t("agency_panel_xml_workflow_card_title")}
                        </h3>
                      </div>

                      <div className="grid grid-cols-1 md:grid-cols-2 gap-3 text-xs">
                        {/* Halo Oglasi Guide (Test Environment) */}
                        <div className="p-3.5 rounded-lg bg-white border border-[#E5E3DF] flex flex-col justify-between">
                          <div>
                            <div className="flex items-center justify-between gap-2 mb-2 pb-2 border-b border-slate-100">
                              <p className="font-bold text-[#1A1A1A] flex items-center gap-1.5">
                                <span className="w-2 h-2 rounded-full bg-amber-500" />
                                <span>{t("agency_panel_xml_halo_guide_title")}</span>
                              </p>
                              <span className="text-[10px] font-semibold px-2 py-0.5 rounded-full bg-[#FBF1DC] text-[#8A5206] border border-[#8A5206]/20">
                                {t("agency_panel_xml_halo_guide_badge")}
                              </span>
                            </div>
                            <ol className="space-y-1.5 text-[11px] text-[#4A4A4A] leading-relaxed list-decimal list-inside pl-0.5">
                              <li>{t("agency_panel_xml_halo_guide_step1")}</li>
                              <li>{t("agency_panel_xml_halo_guide_step2")}</li>
                              <li>{t("agency_panel_xml_halo_guide_step3")}</li>
                            </ol>
                          </div>
                        </div>

                        {/* 4zida.rs Guide (Direct Production) */}
                        <div className="p-3.5 rounded-lg bg-white border border-[#E5E3DF] flex flex-col justify-between">
                          <div>
                            <div className="flex items-center justify-between gap-2 mb-2 pb-2 border-b border-slate-100">
                              <p className="font-bold text-[#1A1A1A] flex items-center gap-1.5">
                                <span className="w-2 h-2 rounded-full bg-blue-500" />
                                <span>{t("agency_panel_xml_4zida_guide_title")}</span>
                              </p>
                              <span className="text-[10px] font-semibold px-2 py-0.5 rounded-full bg-[#E5EEF6] text-[#12406A] border border-[#1B5888]/20">
                                {t("agency_panel_xml_4zida_guide_badge")}
                              </span>
                            </div>
                            <ol className="space-y-1.5 text-[11px] text-[#4A4A4A] leading-relaxed list-decimal list-inside pl-0.5">
                              <li>{t("agency_panel_xml_4zida_guide_step1")}</li>
                              <li>{t("agency_panel_xml_4zida_guide_step2")}</li>
                              <li>{t("agency_panel_xml_4zida_guide_step3")}</li>
                            </ol>
                          </div>
                        </div>
                      </div>

                      <div className="pt-2 border-t border-[#E5E3DF] flex items-start gap-2">
                        <Info className="w-3.5 h-3.5 text-[#1B5888] shrink-0 mt-0.5" />
                        <p className="text-[11px] text-[#666666] leading-relaxed">
                          {t("agency_panel_xml_quota_short")}
                        </p>
                      </div>
                    </div>
                  </section>

                  {/* SECTION 2: PORTAL CRAWLER & SYNCHRONIZATION LOGS */}
                  <section
                    aria-labelledby="portal-logs-heading"
                    className="bg-white rounded-[10px] border border-[#E5E3DF] p-6 shadow-xs"
                  >
                    <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 pb-4 mb-4 border-b border-slate-100">
                      <div>
                        <div className="flex items-center gap-2">
                          <h2
                            id="portal-logs-heading"
                            className="text-lg font-bold text-[#1A1A1A] flex items-center gap-2"
                          >
                            <Layers className="w-5 h-5 text-[#1B5888]" />
                            <span>{t("agency_panel_logs_title")}</span>
                          </h2>
                          <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-[#E6F3EA] text-[#2A6E43] border border-[#2A6E43]/20 flex items-center gap-1">
                            <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse" />
                            <span>{t("agency_panel_logs_live_badge")}</span>
                          </span>
                        </div>
                        <p className="text-xs text-[#666666] mt-1">
                          {t("agency_panel_logs_desc")}
                        </p>
                      </div>

                      <button
                        type="button"
                        onClick={fetchFeedLogs}
                        disabled={loadingFeedLogs}
                        className="inline-flex items-center gap-1.5 px-3.5 py-1.5 rounded-[10px] border border-[#E5E3DF] hover:bg-slate-50 text-xs font-semibold text-[#4A4A4A] cursor-pointer transition-colors self-start sm:self-auto shrink-0"
                      >
                        <RefreshCw
                          className={`w-3.5 h-3.5 text-[#666666] ${loadingFeedLogs ? "animate-spin" : ""}`}
                        />
                        <span>{t("agency_panel_logs_refresh")}</span>
                      </button>
                    </div>

                    {/* Summary cards by portal */}
                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 mb-5">
                      {PORTAL_LIST.filter((p) => p.status === "live").map((p) => {
                        const lastLog = feedLogs.find((l) =>
                          l.portal.toLowerCase().includes(p.id)
                        );
                        return (
                          <div
                            key={p.id}
                            className="p-3.5 rounded-[10px] border border-slate-100 bg-slate-50/70 flex flex-col justify-between"
                          >
                            <div className="flex items-center justify-between">
                              <span className="text-xs font-bold text-[#1A1A1A]">
                                {p.name}
                              </span>
                              <span
                                className={`w-2 h-2 rounded-full ${lastLog ? "bg-emerald-500" : "bg-slate-300"
                                  }`}
                              />
                            </div>
                            <div className="mt-2">
                              <p className="text-[11px] text-[#666666]">
                                {lastLog
                                  ? formatTimeAgo(lastLog.created_at)
                                  : t("agency_panel_logs_col_time")}
                              </p>
                              <p className="text-xs font-mono font-semibold text-[#4A4A4A]">
                                {lastLog
                                  ? `${lastLog.listing_count} ${t("agency_panel_xml_active_count")}`
                                  : "30 min sync"}
                              </p>
                            </div>
                          </div>
                        );
                      })}
                    </div>

                    {/* Logs Table */}
                    <div className="overflow-x-auto rounded-[10px] border border-[#E5E3DF]">
                      <table className="w-full text-left text-xs border-collapse">
                        <thead>
                          <tr className="bg-slate-50 border-b border-[#E5E3DF] text-[#4A4A4A] font-bold">
                            <th className="py-2.5 px-3.5">{t("agency_panel_logs_col_portal")}</th>
                            <th className="py-2.5 px-3.5">{t("agency_panel_logs_col_time")}</th>
                            <th className="py-2.5 px-3.5">{t("agency_panel_logs_col_status")}</th>
                            <th className="py-2.5 px-3.5">{t("agency_panel_logs_col_listings")}</th>
                            <th className="py-2.5 px-3.5">{t("agency_panel_logs_col_latency")}</th>
                            <th className="py-2.5 px-3.5">{t("agency_panel_logs_col_ip")}</th>
                          </tr>
                        </thead>
                        <tbody className="divide-y divide-slate-100">
                          {feedLogs.length === 0 ? (
                            <tr>
                              <td colSpan={6} className="py-8 text-center text-[#666666]">
                                {t("agency_panel_logs_empty")}
                              </td>
                            </tr>
                          ) : (
                            feedLogs.map((log) => (
                              <tr key={log.id} className="hover:bg-slate-50/50 transition-colors">
                                <td className="py-2.5 px-3.5 font-bold text-[#1A1A1A]">
                                  <span className="uppercase">{log.portal}</span>
                                </td>
                                <td className="py-2.5 px-3.5 text-[#4A4A4A] font-mono">
                                  {new Date(log.created_at).toLocaleString("sr-RS")}
                                </td>
                                <td className="py-2.5 px-3.5">
                                  <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-md font-mono text-[10px] font-bold bg-[#E6F3EA] text-[#2A6E43] border border-[#2A6E43]/20">
                                    <Check className="w-3 h-3" />
                                    <span>{log.status_code || 200} OK</span>
                                  </span>
                                </td>
                                <td className="py-2.5 px-3.5 font-mono font-semibold text-[#4A4A4A]">
                                  {log.listing_count}
                                </td>
                                <td className="py-2.5 px-3.5 text-[#666666] font-mono">
                                  {log.duration_ms ? `${log.duration_ms} ms` : "< 50 ms"}
                                </td>
                                <td
                                  className="py-2.5 px-3.5 text-[#666666] font-mono text-[11px] truncate max-w-[200px]"
                                  title={log.user_agent || log.ip_address || ""}
                                >
                                  {log.ip_address || "bot"} •{" "}
                                  {log.user_agent ? log.user_agent.split("/")[0] : "crawler"}
                                </td>
                              </tr>
                            ))
                          )}
                        </tbody>
                      </table>
                    </div>
                  </section>
                </div>
  );
}
