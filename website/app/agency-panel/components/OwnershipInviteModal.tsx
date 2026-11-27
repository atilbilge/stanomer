"use client";

import React, { useState, useEffect } from "react";
import {
  Mail,
  X,
  Check,
  Copy,
  Share2,
  ExternalLink,
  MessageCircle,
  Building,
  UserCheck,
  Clock,
  AlertCircle,
  ShieldCheck,
  Loader2,
  AlertTriangle,
} from "lucide-react";
import { AgencyManagedProperty } from "../types";
import { supabase } from "../../../lib/supabaseClient";

interface OwnershipInviteModalProps {
  isOpen: boolean;
  onClose: () => void;
  property: AgencyManagedProperty | null;
  agencyName?: string;
  agencyEmail?: string;
  isDemoMode?: boolean;
  userId?: string | null;
  t: (key: string, params?: Record<string, any>) => string;
  onLandlordConfirmedOffline?: (propId: string) => void;
  onInviteSent?: (propId: string, email: string) => void;
}

export default function OwnershipInviteModal({
  isOpen,
  onClose,
  property,
  agencyName,
  agencyEmail,
  isDemoMode = false,
  userId,
  t,
  onLandlordConfirmedOffline,
  onInviteSent,
}: OwnershipInviteModalProps) {
  const [selectedLanguage, setSelectedLanguage] = useState<"sr" | "sr_cyrl" | "en" | "tr" | "ru">("sr");
  const [viewMode, setViewMode] = useState<"visual" | "plain">("visual");
  const [copiedState, setCopiedState] = useState<"text" | "link" | null>(null);
  const [inviteStatus, setInviteStatus] = useState<"confirmed" | "pending" | "notSent" | "noEmail">("notSent");
  const [isConfirmingOffline, setIsConfirmingOffline] = useState(false);
  const [showConfirmOfflineDialog, setShowConfirmOfflineDialog] = useState(false);

  const [isSendingEmail, setIsSendingEmail] = useState(false);
  const [emailSuccessMessage, setEmailSuccessMessage] = useState<string | null>(null);
  const [emailErrorMessage, setEmailErrorMessage] = useState<string | null>(null);

  const [resolvedEmail, setResolvedEmail] = useState<string>(property?.landlord_email || "");
  const [resolvedName, setResolvedName] = useState<string>(property?.landlord_name || "");
  const [resolvedPhone, setResolvedPhone] = useState<string>(property?.landlord_phone || "");

  useEffect(() => {
    if (!property || !isOpen) return;

    let isMounted = true;

    const checkAndResolve = async () => {
      let email = property.landlord_email?.trim() || "";
      let name = property.landlord_name?.trim() || "";
      let phone = property.landlord_phone?.trim() || "";

      // 1. Direct query to property_owners table (SSOT for all owner data)
      if ((!isDemoMode || (userId && userId !== "demo")) && property.id) {
        try {
          const { data: ownersData, error: ownersErr } = await supabase
            .from("property_owners")
            .select("*")
            .eq("property_id", property.id)
            .order("is_primary", { ascending: false });

          if (!ownersErr && ownersData && ownersData.length > 0) {
            const primary = ownersData.find((o: any) => o.is_primary) || ownersData[0];
            if (primary) {
              if (primary.email && primary.email.trim()) {
                email = primary.email.trim();
              }
              if (primary.phone && primary.phone.trim()) {
                phone = primary.phone.trim();
              }
              const computedName =
                primary.owner_type === "company"
                  ? primary.company_name?.trim() || ""
                  : `${primary.first_name || ""} ${primary.last_name || ""}`.trim();
              if (computedName) {
                name = computedName;
              }
            }

            // If primary owner didn't have an email, find if any co-owner has email
            if (!email) {
              const coOwnerWithEmail = ownersData.find((o: any) => o.email && o.email.trim());
              if (coOwnerWithEmail) {
                email = coOwnerWithEmail.email.trim();
              }
            }
          }
        } catch (err) {
          console.warn("Could not fetch property_owners in OwnershipInviteModal:", err);
        }
      }

      // 2. If still no email from DB query, fallback to property.owners in memory
      if (!email && property.owners && property.owners.length > 0) {
        const primary = property.owners.find((o: any) => o.is_primary) || property.owners[0];
        if (primary) {
          if (!email && primary.email) email = primary.email.trim();
          if (!phone && primary.phone) phone = primary.phone.trim();
          if (!name) {
            name =
              primary.owner_type === "company"
                ? primary.company_name?.trim() || ""
                : `${primary.first_name || ""} ${primary.last_name || ""}`.trim();
          }
        }
        if (!email) {
          const coOwnerWithEmail = property.owners.find((o: any) => o.email && o.email.trim());
          if (coOwnerWithEmail) email = coOwnerWithEmail.email.trim();
        }
      }

      // 3. If landlord_id exists, fetch from profiles table (Flutter SSOT Parity)
      if (property.landlord_id && !isDemoMode) {
        try {
          const { data: landlordProf } = await supabase
            .from("profiles")
            .select("id, full_name, phone_number, email")
            .eq("id", property.landlord_id)
            .maybeSingle();

          if (landlordProf) {
            if (!email && landlordProf.email?.trim()) {
              email = landlordProf.email.trim();
            }
            if (!name && landlordProf.full_name?.trim()) {
              name = landlordProf.full_name.trim();
            }
            if (!phone && landlordProf.phone_number?.trim()) {
              phone = landlordProf.phone_number.trim();
            }
          }
        } catch (profErr) {
          console.warn("Could not fetch landlord profile in OwnershipInviteModal:", profErr);
        }
      }

      // 4. If still no email, check invitations table for pending/existing invite
      let latestInviteToken: string | null = null;
      let latestInviteStatus: string | null = null;
      if ((!isDemoMode || (userId && userId !== "demo")) && property.id) {
        try {
          const { data: inviteData } = await supabase
            .from("invitations")
            .select("invitee_email, token, status")
            .eq("property_id", property.id)
            .eq("target_role", "landlord")
            .order("created_at", { ascending: false })
            .limit(1)
            .maybeSingle();

          if (inviteData) {
            latestInviteToken = inviteData.token || null;
            latestInviteStatus = inviteData.status || null;
            if (!email && inviteData.invitee_email?.trim()) {
              email = inviteData.invitee_email.trim();
            }
          }
        } catch (invErr) {
          console.warn("Could not fetch invitations in OwnershipInviteModal:", invErr);
        }
      }

      if (isMounted) {
        setResolvedEmail(email);
        setResolvedName(name);
        setResolvedPhone(phone);

        if (property.landlord_id) {
          setInviteStatus("confirmed");
          return;
        }

        if (!email) {
          setInviteStatus("noEmail");
          return;
        }

        if (latestInviteStatus === "pending") {
          setInviteStatus("pending");
        } else {
          setInviteStatus("notSent");
        }
      }
    };

    checkAndResolve();

    return () => {
      isMounted = false;
    };
  }, [property, isOpen, isDemoMode, userId]);

  if (!isOpen || !property) return null;

  const effectiveAddress = property.address || property.title || t("portfolio");
  const effectiveLandlordName = resolvedName || property.landlord_name?.trim() || t("roleLandlord");
  const effectiveLandlordEmail = resolvedEmail || property.landlord_email?.trim() || "";
  const effectiveLandlordPhone = resolvedPhone || property.landlord_phone?.trim() || "";
  const effectiveAgencyName = agencyName?.trim() || "Stanomer";
  const effectiveAgencyEmail = agencyEmail?.trim() || "info@stanomer.online";

  const webLink = "https://www.stanomer.online/app";
  const iosLink = "https://apps.apple.com/us/app/stanomer/id6762311157";
  const androidLink = "https://play.google.com/store/apps/details?id=com.aboptima.stanomer";

  // Build localized email text matching Flutter's OwnershipShareSheet
  const buildEmailContent = (lang: "sr" | "sr_cyrl" | "en" | "tr" | "ru") => {
    if (lang === "en") {
      const subject = `[${effectiveAddress}] your property has been added to Stanomer`;
      const body = `Hello ${effectiveLandlordName},

As ${effectiveAgencyName}, we have added your property located at ${effectiveAddress} to the Stanomer application. 
This allows you to view all processes related to your property, such as rent payments, expenses, and maintenance processes, in real-time and track them transparently.

To get started:

1. Open the web application (${webLink}) or download the mobile app:
(${iosLink} and ${androidLink})
2. Sign up using your ${effectiveLandlordEmail} address.

Important: Be sure to use the ${effectiveLandlordEmail} address when signing up, otherwise your property will not match with your account.

Once registered, all details regarding your property will appear in your account.

If you have any questions, you can reach us at ${effectiveAgencyEmail}.

Best regards,
${effectiveAgencyName} team`;
      return { subject, body };
    }

    if (lang === "sr_cyrl") {
      const subject = `[${effectiveAddress}] ваша некретнина је додата у Станомер`;
      const body = `Здраво ${effectiveLandlordName},

Као ${effectiveAgencyName}, додали смо вашу некретнину на адреси ${effectiveAddress} у Станомер апликацију. 
На овај начин можете у реалном времену прегледати све процесе везане за вашу некретнину, као што су уплате кирије, трошкови и процеси одржавања, и пратити их на транспарентан начин.

За почетак:

1. Отворите веб апликацију (${webLink}) или преузмите мобилну апликацију:
(${iosLink} и ${androidLink})
2. Региструјте се помоћу ваше ${effectiveLandlordEmail} адресе.

Важно: Приликом регистрације обавезно користите ${effectiveLandlordEmail} адресу, у супротном се ваша некретнина неће повезати са вашим налогом.

Након регистрације, сви детаљи у вези са вашом некретнином појавиће се на вашем налогу.

Ако имате било каквих питања, можете нам се обратити на ${effectiveAgencyEmail}.

С поштовањем,
${effectiveAgencyName} тим`;
      return { subject, body };
    }

    if (lang === "tr") {
      const subject = `[${effectiveAddress}] mülkünüz Stanomer'e eklendi`;
      const body = `Merhaba ${effectiveLandlordName},

${effectiveAgencyName} olarak, ${effectiveAddress} adresli mülkünüzü Stanomer uygulamasına ekledik. 
Bu sayede kira ödemeleri, masraflar ve bakım süreçleri gibi mülkünüzle ilgili tüm işlemleri anlık olarak görüntüleyebilir, şeffaf bir şekilde takip edebilirsiniz.

Başlamak için:

1. Web uygulamasını açın (${webLink}) ya da mobil uygulamayı indirin:
(${iosLink} ve ${androidLink})
2. ${effectiveLandlordEmail} adresiniz ile kayıt olun.

Önemli: Kayıt olurken mutlaka ${effectiveLandlordEmail} adresini kullanın, aksi halde mülkünüz hesabınızla eşleşmez.

Kayıt olduktan sonra mülkünüze dair tüm detaylar hesabınızda görünecektir.

Herhangi bir sorunuz olursa bize ${effectiveAgencyEmail} üzerinden ulaşabilirsiniz.

Saygılarımızla,
${effectiveAgencyName} ekibi`;
      return { subject, body };
    }

    if (lang === "ru") {
      const subject = `[${effectiveAddress}] ваша недвижимость добавлена в Stanomer`;
      const body = `Здравствуйте, ${effectiveLandlordName},

Компания ${effectiveAgencyName} добавила вашу недвижимость по адресу ${effectiveAddress} в приложение Stanomer. 
Благодаря этому вы сможете в режиме реального времени просматривать все операции, связанные с вашей недвижимостью, такие как арендные платежи, расходы и процессы обслуживания, а также прозрачно отслеживать их.

Для начала:

1. Откройте веб-приложение (${webLink}) или загрузите мобильное приложение:
(${iosLink} и ${androidLink})
2. Зарегистрируйтесь, используя ваш адрес ${effectiveLandlordEmail}.

Важно: Обязательно используйте адрес ${effectiveLandlordEmail} при регистрации, иначе ваша недвижимость не привяжется к вашей учетной записи.

После регистрации все данные о вашей недвижимости появятся в вашем аккаунте.

Если у вас возникнут вопросы, вы можете связаться с нами по адресу ${effectiveAgencyEmail}.

С уважением,
команда ${effectiveAgencyName}`;
      return { subject, body };
    }

    // Default: Serbian Latin (sr)
    const subject = `[${effectiveAddress}] vaša nekretnina je dodata u Stanomer`;
    const body = `Zdravo ${effectiveLandlordName},

Kao ${effectiveAgencyName}, dodali smo vašu nekretninu na adresi ${effectiveAddress} u Stanomer aplikaciju. 
Na ovaj način možete u realnom vremenu pregledati sve procese vezane za vašu nekretninu, kao što su uplate kirije, troškovi i procesi održavanja, i pratiti ih na transparentan način.

Za početak:

1. Otvorite veb aplikaciju (${webLink}) ili preuzmite mobilnu aplikaciju:
(${iosLink} i ${androidLink})
2. Registrujte se pomoću vaše ${effectiveLandlordEmail} adrese.

Važno: Prilikom registracije obavezno koristite ${effectiveLandlordEmail} adresu, u suprotnom se vaša nekretnina neće povezati sa vašim nalogom.

Nakon registracije, svi detalji u vezi sa vašom nekretninom pojaviće se na vašem nalogu.

Ako imate bilo kakvih pitanja, možete nam se obratiti na ${effectiveAgencyEmail}.

S poštovanjem,
${effectiveAgencyName} tim`;
    return { subject, body };
  };

  const emailData = buildEmailContent(selectedLanguage);

  const handleCopyText = () => {
    navigator.clipboard.writeText(emailData.body);
    setCopiedState("text");
    setTimeout(() => setCopiedState(null), 2500);
  };

  const handleCopyLink = () => {
    navigator.clipboard.writeText(webLink);
    setCopiedState("link");
    setTimeout(() => setCopiedState(null), 2500);
  };

  const handleSendEmail = async () => {
    if (!effectiveLandlordEmail || isSendingEmail) return;

    setIsSendingEmail(true);
    setEmailSuccessMessage(null);
    setEmailErrorMessage(null);

    if (isDemoMode && (!userId || userId === "demo")) {
      setTimeout(() => {
        setInviteStatus("pending");
        setEmailSuccessMessage(t("landlordInviteSentSuccess", { email: effectiveLandlordEmail }));
        onInviteSent?.(property.id, effectiveLandlordEmail);
        setIsSendingEmail(false);
        setTimeout(() => {
          setEmailSuccessMessage(null);
        }, 6000);
      }, 500);
      return;
    }

    try {
      const normalizedEmail = effectiveLandlordEmail.trim().toLowerCase();
      const generatedToken = `landlord_${Date.now()}_${Math.floor(Math.random() * 99999)}`;
      let invitationCreatedByClient = false;

      // Persist invitation under the agency's authenticated browser session first
      // so it works reliably even without a server-side service role key.
      if (userId && userId !== "demo") {
        await supabase
          .from("invitations")
          .update({ status: "cancelled" })
          .eq("property_id", property.id)
          .eq("target_role", "landlord")
          .eq("status", "pending");

        const { error: invErr } = await supabase.from("invitations").insert({
          property_id: property.id,
          inviter_id: userId,
          agency_id: userId,
          inviter_name: effectiveAgencyName,
          invitee_email: normalizedEmail,
          token: generatedToken,
          target_role: "landlord",
          status: "pending",
          expires_at: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
        });
        if (!invErr) {
          invitationCreatedByClient = true;
        } else {
          console.warn("Client-side invitation insert failed, delegating to server API:", invErr.message);
        }
      }

      const res = await fetch("/api/send-landlord-invite", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          propertyId: property.id,
          propertyAddress: effectiveAddress,
          landlordEmail: normalizedEmail,
          landlordName: effectiveLandlordName,
          agencyName: effectiveAgencyName,
          agencyEmail: effectiveAgencyEmail,
          language: selectedLanguage,
          inviterId: userId,
          token: generatedToken,
          invitationCreatedByClient,
        }),
      });

      const rawText = await res.text();
      let data: { success?: boolean; error?: string } = {};
      try {
        data = rawText ? JSON.parse(rawText) : {};
      } catch {
        throw new Error(`${t("inviteEmailSendError")} (HTTP ${res.status})`);
      }

      if (!res.ok || !data.success) {
        throw new Error(data.error || t("inviteEmailSendError"));
      }

      setInviteStatus("pending");
      setEmailSuccessMessage(t("landlordInviteSentSuccess", { email: effectiveLandlordEmail }));
      onInviteSent?.(property.id, effectiveLandlordEmail);
      setTimeout(() => {
        setEmailSuccessMessage(null);
      }, 6000);
    } catch (err: any) {
      console.error("Failed to send landlord invite email:", err);
      setEmailErrorMessage(err.message || t("inviteEmailSendError"));
    } finally {
      setIsSendingEmail(false);
    }
  };

  const handleOpenMailto = () => {
    const mailto = `mailto:${encodeURIComponent(effectiveLandlordEmail)}?subject=${encodeURIComponent(
      emailData.subject
    )}&body=${encodeURIComponent(emailData.body)}`;
    window.open(mailto, "_blank");
  };

  const handleShareWhatsApp = () => {
    const waUrl = `https://wa.me/?text=${encodeURIComponent(emailData.body)}`;
    window.open(waUrl, "_blank");
  };

  const handleConfirmOffline = async () => {
    setIsConfirmingOffline(true);
    try {
      if (userId && userId !== "demo") {
        await supabase
          .from("properties")
          .update({ landlord_name: effectiveLandlordName })
          .eq("id", property.id);
      }
      setInviteStatus("confirmed");
      setShowConfirmOfflineDialog(false);
      onLandlordConfirmedOffline?.(property.id);
    } catch (err) {
      console.error("Confirm offline error:", err);
    } finally {
      setIsConfirmingOffline(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-xs animate-in fade-in duration-200">
      <div className="bg-white rounded-2xl shadow-2xl border border-slate-200/80 max-w-2xl w-full max-h-[92vh] flex flex-col overflow-hidden">
        {/* Header */}
        <div className="px-6 py-4 border-b border-slate-100 flex items-center justify-between bg-slate-50/75 shrink-0">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-blue-50 text-[#1B5888] flex items-center justify-center">
              <Mail className="w-5 h-5" />
            </div>
            <div>
              <h3 className="text-base font-bold text-slate-900">
                {t("landlordOwnershipInviteTitle")}
              </h3>
              <p className="text-xs text-slate-500 flex items-center gap-1.5 mt-0.5">
                <Building className="w-3.5 h-3.5 text-slate-400" />
                <span className="font-semibold text-slate-700">{property.title}</span>
                <span>•</span>
                <span>{property.address}</span>
              </p>
            </div>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="p-1.5 rounded-lg text-slate-400 hover:text-slate-700 hover:bg-slate-200/60 transition-colors cursor-pointer"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Modal Body */}
        <div className="p-6 overflow-y-auto space-y-5 grow">
          {/* Email Send Feedback Banners */}
          {emailSuccessMessage && (
            <div className="p-3.5 bg-emerald-50 border border-emerald-200 rounded-xl text-xs font-semibold text-emerald-800 flex items-center gap-2 animate-in fade-in duration-200">
              <Check className="w-4 h-4 text-emerald-600 shrink-0" />
              <span>{emailSuccessMessage}</span>
            </div>
          )}

          {emailErrorMessage && (
            <div className="p-3.5 bg-rose-50 border border-rose-200 rounded-xl text-xs font-semibold text-rose-800 flex items-center gap-2 animate-in fade-in duration-200">
              <AlertCircle className="w-4 h-4 text-rose-600 shrink-0" />
              <span>{emailErrorMessage}</span>
            </div>
          )}
          {/* Landlord Info & Status Card */}
          <div className="p-4 rounded-xl border border-slate-200/80 bg-slate-50/50 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
            <div className="space-y-1">
              <div className="flex items-center gap-2">
                <span className="text-xs font-bold text-slate-500">
                  {t("roleLandlord")}
                </span>
                <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-blue-100/70 text-blue-800">
                  {t("primaryOwnerBadge")}
                </span>
              </div>
              <p className="text-sm font-bold text-slate-900">{effectiveLandlordName}</p>
              <p className="text-xs text-slate-500">
                {effectiveLandlordEmail || t("noEmailAddressDefined")}
                {effectiveLandlordPhone && ` • ${effectiveLandlordPhone}`}
              </p>
            </div>

            <div className="flex items-center gap-2">
              {inviteStatus === "confirmed" ? (
                <span className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-bold bg-emerald-50 text-emerald-700 border border-emerald-200">
                  <UserCheck className="w-3.5 h-3.5" />
                  <span>{t("statusApproved")}</span>
                </span>
              ) : inviteStatus === "pending" ? (
                <span className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-bold bg-amber-50 text-amber-800 border border-amber-200">
                  <Clock className="w-3.5 h-3.5" />
                  <span>{t("invitePending")}</span>
                </span>
              ) : inviteStatus === "noEmail" ? (
                <span className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-bold bg-rose-50 text-rose-700 border border-rose-200">
                  <AlertCircle className="w-3.5 h-3.5" />
                  <span>{t("statusNoEmail")}</span>
                </span>
              ) : (
                <span className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-bold bg-slate-100 text-slate-600 border border-slate-200">
                  <Clock className="w-3.5 h-3.5 text-slate-400" />
                  <span>{t("statusNotSent")}</span>
                </span>
              )}
            </div>
          </div>

          {/* If Confirmed Banner */}
          {inviteStatus === "confirmed" && (
            <div className="p-3.5 rounded-xl bg-emerald-50/80 border border-emerald-200/80 flex items-start gap-2.5 text-xs text-emerald-900">
              <ShieldCheck className="w-4 h-4 text-emerald-600 shrink-0 mt-0.5" />
              <span>{t("ownerConfirmedBanner", { name: effectiveLandlordName })}</span>
            </div>
          )}

          {/* Language Selector & View Mode Switcher */}
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pt-1">
            <div className="flex items-center gap-1 overflow-x-auto pb-1 sm:pb-0">
              <span className="text-xs font-semibold text-slate-500 mr-1.5 shrink-0">
                {t("language")}:
              </span>
              {[
                { code: "sr", label: "SR (Latin)" },
                { code: "sr_cyrl", label: "SR (Кир)" },
                { code: "en", label: "EN" },
                { code: "tr", label: "TR" },
                { code: "ru", label: "RU" },
              ].map((lang) => (
                <button
                  key={lang.code}
                  type="button"
                  onClick={() => setSelectedLanguage(lang.code as any)}
                  className={`px-2.5 py-1 text-xs font-bold rounded-lg transition-all cursor-pointer whitespace-nowrap ${
                    selectedLanguage === lang.code
                      ? "bg-[#1B5888] text-white shadow-xs"
                      : "bg-slate-100 text-slate-600 hover:bg-slate-200"
                  }`}
                >
                  {lang.label}
                </button>
              ))}
            </div>

            <div className="flex items-center bg-slate-100 p-0.5 rounded-lg shrink-0 self-start sm:self-auto">
              <button
                type="button"
                onClick={() => setViewMode("visual")}
                className={`px-3 py-1 text-xs font-bold rounded-md transition-all cursor-pointer ${
                  viewMode === "visual"
                    ? "bg-white text-slate-900 shadow-xs"
                    : "text-slate-600 hover:text-slate-900"
                }`}
              >
                {t("tabVisual")}
              </button>
              <button
                type="button"
                onClick={() => setViewMode("plain")}
                className={`px-3 py-1 text-xs font-bold rounded-md transition-all cursor-pointer ${
                  viewMode === "plain"
                    ? "bg-white text-slate-900 shadow-xs"
                    : "text-slate-600 hover:text-slate-900"
                }`}
              >
                {t("tabPlainText")}
              </button>
            </div>
          </div>

          {/* Email Preview */}
          <div className="space-y-2">
            <div className="flex items-center justify-between">
              <span className="text-xs font-bold text-slate-700 flex items-center gap-1.5">
                <Mail className="w-3.5 h-3.5 text-slate-500" />
                <span>{t("emailPreviewTitle")}</span>
              </span>
              <span className="text-[11px] text-slate-400">
                {t("recipientWillReceiveThisFormat", { email: effectiveLandlordEmail || "landlord" })}
              </span>
            </div>

            {viewMode === "visual" ? (
              <div className="rounded-xl border border-slate-200 overflow-hidden shadow-xs bg-slate-50/50">
                {/* Email Header */}
                <div className="bg-[#1B5888] px-6 py-4 flex items-center justify-between text-white">
                  <span className="font-extrabold text-base tracking-wide">Stanomer</span>
                  <span className="text-xs font-medium text-blue-100">
                    {effectiveAgencyName}
                  </span>
                </div>

                {/* Subject Line */}
                <div className="px-6 py-2.5 bg-slate-100/80 border-b border-slate-200 text-xs font-medium text-slate-700 flex items-center gap-2">
                  <span className="font-bold text-slate-500 uppercase text-[10px]">
                    {t("subjectHeader")}:
                  </span>
                  <span className="font-bold text-slate-800">{emailData.subject}</span>
                </div>

                {/* Email Body */}
                <div className="p-6 bg-white space-y-4 text-xs text-slate-700 leading-relaxed">
                  <p className="font-medium">
                    {selectedLanguage === "tr"
                      ? `Merhaba ${effectiveLandlordName},`
                      : selectedLanguage === "en"
                      ? `Hello ${effectiveLandlordName},`
                      : selectedLanguage === "ru"
                      ? `Здравствуйте, ${effectiveLandlordName},`
                      : selectedLanguage === "sr_cyrl"
                      ? `Здраво ${effectiveLandlordName},`
                      : `Zdravo ${effectiveLandlordName},`}
                  </p>
                  <p>
                    <strong>{effectiveAgencyName}</strong>{" "}
                    {selectedLanguage === "tr"
                      ? `olarak, ${effectiveAddress} adresli mülkünüzü Stanomer uygulamasına ekledik. Bu sayede kira ödemeleri, masraflar ve bakım süreçleri gibi tüm işlemleri şeffaf bir şekilde takip edebilirsiniz.`
                      : selectedLanguage === "en"
                      ? `has added your property located at ${effectiveAddress} to the Stanomer application. This allows you to view all processes related to your property in real-time.`
                      : selectedLanguage === "ru"
                      ? `добавила вашу недвижимость по адресу ${effectiveAddress} в приложение Stanomer.`
                      : selectedLanguage === "sr_cyrl"
                      ? `додали смо вашу некретнину на адреси ${effectiveAddress} у Станомер апликацију.`
                      : `dodali smo vašu nekretninu na adresi ${effectiveAddress} u Stanomer aplikaciju.`}
                  </p>

                  <div className="p-3 bg-amber-50/80 rounded-[10px] border border-amber-200 text-amber-900 text-[11px] font-medium flex items-center gap-2">
                    <AlertTriangle className="w-4 h-4 text-amber-600 shrink-0" />
                    <span>
                      {selectedLanguage === "tr"
                        ? `Kayıt olurken mutlaka ${effectiveLandlordEmail || "e-posta"} adresinizi kullanın.`
                        : selectedLanguage === "en"
                        ? `Be sure to sign up with ${effectiveLandlordEmail || "your email"} address.`
                        : `Obavezno se registrujte sa ${effectiveLandlordEmail || "vašom email"} adresom.`}
                    </span>
                  </div>

                  <div className="pt-2 flex items-center gap-3">
                    <a
                      href={webLink}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-blue-50 text-[#1B5888] font-bold text-xs hover:bg-blue-100 transition-colors"
                    >
                      <span>Stanomer Web</span>
                      <ExternalLink className="w-3 h-3" />
                    </a>
                    <a
                      href={iosLink}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-xs font-semibold text-slate-500 hover:text-slate-800 underline"
                    >
                      App Store
                    </a>
                    <span className="text-slate-300">•</span>
                    <a
                      href={androidLink}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-xs font-semibold text-slate-500 hover:text-slate-800 underline"
                    >
                      Google Play
                    </a>
                  </div>
                </div>

                {/* Email Footer */}
                <div className="px-6 py-3 bg-slate-50 border-t border-slate-100 text-[11px] text-slate-400 text-center">
                  Stanomer • {effectiveAgencyName}
                </div>
              </div>
            ) : (
              <div className="space-y-2">
                <div className="p-3 bg-slate-50 rounded-xl border border-slate-200 text-xs">
                  <span className="font-bold text-slate-500 uppercase text-[10px] block mb-1">
                    {t("subjectHeader")}:
                  </span>
                  <span className="font-bold text-slate-800 font-mono text-xs">{emailData.subject}</span>
                </div>
                <textarea
                  readOnly
                  rows={8}
                  value={emailData.body}
                  className="w-full p-4 rounded-xl border border-slate-200 font-mono text-xs bg-slate-50 text-slate-800 focus:outline-hidden"
                />
              </div>
            )}
          </div>
        </div>

        {/* Modal Footer / Actions */}
        <div className="px-6 py-4 border-t border-slate-100 bg-slate-50/75 flex flex-wrap items-center justify-between gap-3 shrink-0">
          <div className="flex items-center gap-2">
            <button
              type="button"
              onClick={handleCopyLink}
              className="inline-flex items-center gap-1.5 px-3 py-2 rounded-xl text-xs font-bold bg-white border border-slate-200 text-slate-700 hover:bg-slate-100 transition-colors cursor-pointer shadow-xs"
            >
              {copiedState === "link" ? (
                <>
                  <Check className="w-3.5 h-3.5 text-emerald-600" />
                  <span className="text-emerald-700">{t("copied")}</span>
                </>
              ) : (
                <>
                  <Copy className="w-3.5 h-3.5 text-slate-500" />
                  <span>{t("copyAppLink")}</span>
                </>
              )}
            </button>

            {inviteStatus !== "confirmed" && (
              <button
                type="button"
                onClick={() => setShowConfirmOfflineDialog(true)}
                className="text-xs font-semibold text-slate-500 hover:text-slate-800 underline px-2 py-1 cursor-pointer"
              >
                {t("startWithoutInviteBtn")}
              </button>
            )}
          </div>

          <div className="flex items-center gap-2">
            <button
              type="button"
              onClick={handleShareWhatsApp}
              className="inline-flex items-center gap-1.5 px-3 py-2 rounded-xl text-xs font-bold bg-[#E6F3EA] text-[#2A6E43] hover:bg-[#d8edd0] transition-colors cursor-pointer shadow-xs"
              title="WhatsApp"
            >
              <MessageCircle className="w-4 h-4" />
              <span>{t("shareWhatsApp")}</span>
            </button>

            <button
              type="button"
              onClick={handleCopyText}
              className="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl text-xs font-bold bg-slate-200/80 text-slate-700 hover:bg-slate-300 transition-colors cursor-pointer shadow-xs"
            >
              {copiedState === "text" ? (
                <>
                  <Check className="w-4 h-4 text-emerald-600" />
                  <span className="text-emerald-700">{t("copied")}</span>
                </>
              ) : (
                <>
                  <Copy className="w-4 h-4" />
                  <span>{t("copyInvitationText")}</span>
                </>
              )}
            </button>

            {effectiveLandlordEmail && (
              <div className="flex items-center gap-1.5">
                <button
                  type="button"
                  disabled={isSendingEmail}
                  onClick={handleSendEmail}
                  className="inline-flex items-center gap-1.5 px-4 py-2 rounded-xl text-xs font-bold bg-[#1B5888] text-white hover:bg-blue-700 transition-colors shadow-xs cursor-pointer disabled:opacity-60"
                >
                  {isSendingEmail ? (
                    <>
                      <Loader2 className="w-4 h-4 animate-spin text-white" />
                      <span>{t("sendingInviteEmail")}</span>
                    </>
                  ) : (
                    <>
                      <Mail className="w-4 h-4" />
                      <span>
                        {inviteStatus === "pending"
                          ? t("resendInviteEmailBtn")
                          : t("sendLandlordInviteEmailBtn")}
                      </span>
                    </>
                  )}
                </button>

                <button
                  type="button"
                  onClick={handleOpenMailto}
                  title={t("openInEmailClient")}
                  className="p-2 rounded-xl text-slate-500 hover:text-slate-800 hover:bg-slate-100 transition-colors cursor-pointer border border-transparent hover:border-slate-200"
                >
                  <ExternalLink className="w-4 h-4" />
                </button>
              </div>
            )}
          </div>
        </div>

        {/* Offline Confirmation Sub-Dialog */}
        {showConfirmOfflineDialog && (
          <div className="fixed inset-0 z-60 bg-black/50 backdrop-blur-xs flex items-center justify-center p-4">
            <div className="bg-white rounded-2xl max-w-sm w-full p-5 shadow-2xl space-y-3">
              <h4 className="text-sm font-bold text-slate-900">
                {t("startWithoutInviteConfirmTitle")}
              </h4>
              <p className="text-xs text-slate-600 leading-relaxed">
                {t("startWithoutInviteConfirmLandlord")}
              </p>
              <div className="flex items-center justify-end gap-2 pt-2 border-t border-slate-100">
                <button
                  type="button"
                  onClick={() => setShowConfirmOfflineDialog(false)}
                  className="px-3 py-1.5 rounded-lg text-xs font-semibold text-slate-600 hover:bg-slate-100 cursor-pointer"
                >
                  {t("cancel")}
                </button>
                <button
                  type="button"
                  disabled={isConfirmingOffline}
                  onClick={handleConfirmOffline}
                  className="px-3.5 py-1.5 rounded-lg text-xs font-bold bg-[#1B5888] text-white hover:bg-blue-700 cursor-pointer disabled:opacity-50"
                >
                  {isConfirmingOffline ? "..." : t("confirm")}
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
