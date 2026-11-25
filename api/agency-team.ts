// api/agency-team.ts
// Vercel Edge Function for Agency Team Management v0 (Agency Admin manages agency_operation users)
// Deployed automatically by Vercel under /api/agency-team

export const config = {
  runtime: "edge",
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, PATCH, DELETE, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
  "Content-Type": "application/json",
};

function jsonResponse(payload: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(payload), { status, headers: corsHeaders });
}

function getSupabaseConfig() {
  const url =
    process.env.NEXT_PUBLIC_SUPABASE_URL ||
    process.env.VERCEL_PROD_SUPABASE_URL ||
    "https://nbcbfmhztnnhfnapvaet.supabase.co";
  const anonKey =
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ||
    process.env.VERCEL_PROD_SUPABASE_ANON_KEY ||
    "sb_publishable_kY2aoizXZkGz2DsG6-sg-Q_Vm2Ef2mq";
  const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY || "";
  return { url, anonKey, serviceKey };
}

async function verifyAgencyAdmin(
  req: Request,
  supabaseUrl: string,
  anonKey: string,
  serviceKey: string
): Promise<{ userId: string } | { error: string; status: number }> {
  const authHeader = req.headers.get("authorization") || req.headers.get("Authorization") || "";
  const token = authHeader.replace(/^Bearer\s+/i, "").trim();
  if (!token) {
    return { error: "agency_team_err_unauthorized", status: 401 };
  }

  const userRes = await fetch(`${supabaseUrl}/auth/v1/user`, {
    headers: {
      apikey: anonKey,
      Authorization: `Bearer ${token}`,
    },
  });
  if (!userRes.ok) {
    return { error: "agency_team_err_unauthorized", status: 401 };
  }
  const userData = (await userRes.json()) as { id?: string };
  if (!userData?.id) {
    return { error: "agency_team_err_unauthorized", status: 401 };
  }

  const adminHeaders = {
    apikey: serviceKey,
    Authorization: `Bearer ${serviceKey}`,
    "Content-Type": "application/json",
  };

  // Verify caller is an agency profile
  const profRes = await fetch(
    `${supabaseUrl}/rest/v1/profiles?id=eq.${encodeURIComponent(userData.id)}&select=id,role,active_role&limit=1`,
    { headers: adminHeaders }
  );
  const profRows = profRes.ok ? ((await profRes.json()) as Array<{ role?: string; active_role?: string }>) : [];
  const prof = profRows[0];
  if (!prof || (prof.role !== "agency" && prof.active_role !== "agency")) {
    return { error: "agency_team_err_admin_only", status: 403 };
  }

  // Verify caller is NOT an operations member of another agency
  const memRes = await fetch(
    `${supabaseUrl}/rest/v1/agency_members?user_id=eq.${encodeURIComponent(userData.id)}&status=eq.active&select=id&limit=1`,
    { headers: adminHeaders }
  );
  const memRows = memRes.ok ? ((await memRes.json()) as Array<{ id: string }>) : [];
  if (memRows.length > 0) {
    return { error: "agency_team_err_admin_only", status: 403 };
  }

  return { userId: userData.id };
}

export async function handler(req: Request): Promise<Response> {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  const { url: supabaseUrl, anonKey, serviceKey } = getSupabaseConfig();
  if (!serviceKey) {
    return jsonResponse({ success: false, errorKey: "agency_team_err_service_key_missing" }, 500);
  }

  const authCheck = await verifyAgencyAdmin(req, supabaseUrl, anonKey, serviceKey);
  if ("error" in authCheck) {
    return jsonResponse({ success: false, errorKey: authCheck.error }, authCheck.status);
  }
  const agencyAdminId = authCheck.userId;

  const adminHeaders = {
    apikey: serviceKey,
    Authorization: `Bearer ${serviceKey}`,
    "Content-Type": "application/json",
    Prefer: "return=representation",
  };

  try {
    const body = (await req.json().catch(() => ({}))) as Record<string, any>;

    // POST: Create or attach an agency_operation member
    if (req.method === "POST") {
      const email = String(body.email || "").trim().toLowerCase();
      const fullName = String(body.fullName || "").trim();
      const phone = String(body.phone || "").trim() || null;
      const password = String(body.password || "");

      if (!email || !email.includes("@")) {
        return jsonResponse({ success: false, errorKey: "agency_team_err_invalid_email" }, 400);
      }
      if (!fullName) {
        return jsonResponse({ success: false, errorKey: "agency_team_err_name_required" }, 400);
      }
      if (password.length < 6) {
        return jsonResponse({ success: false, errorKey: "agency_team_err_password_short" }, 400);
      }

      // 1. Create Supabase Auth user with email confirmed
      let targetUserId: string | null = null;
      const createRes = await fetch(`${supabaseUrl}/auth/v1/admin/users`, {
        method: "POST",
        headers: adminHeaders,
        body: JSON.stringify({
          email,
          password,
          email_confirm: true,
          user_metadata: {
            full_name: fullName,
            role: "agency",
            member_role: "agency_operation",
            agency_id: agencyAdminId,
          },
        }),
      });

      if (createRes.ok) {
        const created = (await createRes.json()) as { id?: string; user?: { id?: string } };
        targetUserId = created.id || created.user?.id || null;
      } else {
        // Check if user already exists in profiles by email
        const existingProfRes = await fetch(
          `${supabaseUrl}/rest/v1/profiles?email=ilike.${encodeURIComponent(email)}&select=id&limit=1`,
          { headers: adminHeaders }
        );
        const existingProfs = existingProfRes.ok
          ? ((await existingProfRes.json()) as Array<{ id: string }>)
          : [];
        if (existingProfs.length > 0) {
          targetUserId = existingProfs[0].id;
        } else {
          const errText = await createRes.text().catch(() => "");
          console.error("Auth admin create user failed:", createRes.status, errText);
          return jsonResponse({ success: false, errorKey: "agency_team_err_create_failed" }, 400);
        }
      }

      if (!targetUserId || targetUserId === agencyAdminId) {
        return jsonResponse({ success: false, errorKey: "agency_team_err_create_failed" }, 400);
      }

      // 2. Ensure profile exists with role = agency
      await fetch(`${supabaseUrl}/rest/v1/profiles`, {
        method: "POST",
        headers: {
          ...adminHeaders,
          Prefer: "resolution=merge-duplicates,return=minimal",
        },
        body: JSON.stringify({
          id: targetUserId,
          email,
          full_name: fullName,
          phone_number: phone,
          role: "agency",
          active_role: "agency",
        }),
      });

      // 3. Upsert into public.agency_members
      const insertRes = await fetch(
        `${supabaseUrl}/rest/v1/agency_members?on_conflict=agency_id,user_id`,
        {
          method: "POST",
          headers: {
            ...adminHeaders,
            Prefer: "resolution=merge-duplicates,return=representation",
          },
          body: JSON.stringify({
            agency_id: agencyAdminId,
            user_id: targetUserId,
            email,
            full_name: fullName,
            phone_number: phone,
            member_role: "agency_operation",
            status: "active",
            invited_by: agencyAdminId,
            updated_at: new Date().toISOString(),
          }),
        }
      );

      if (!insertRes.ok) {
        const errTxt = await insertRes.text().catch(() => "");
        console.error("Insert agency_members failed:", insertRes.status, errTxt);
        return jsonResponse(
          { success: false, errorKey: "agency_team_err_save_failed", detail: `${insertRes.status}: ${errTxt}` },
          500
        );
      }

      const rows = (await insertRes.json()) as any[];
      return jsonResponse({ success: true, member: rows[0] || null }, 201);
    }

    // PATCH: Update existing team member
    if (req.method === "PATCH") {
      const memberId = String(body.memberId || "").trim();
      const fullName = body.fullName !== undefined ? String(body.fullName).trim() : undefined;
      const phone = body.phone !== undefined ? String(body.phone).trim() || null : undefined;
      const status = body.status !== undefined ? String(body.status).trim() : undefined;
      const password = body.password ? String(body.password) : "";

      if (!memberId) {
        return jsonResponse({ success: false, errorKey: "agency_team_err_member_not_found" }, 400);
      }
      if (status && !["active", "suspended", "revoked"].includes(status)) {
        return jsonResponse({ success: false, errorKey: "agency_team_err_invalid_status" }, 400);
      }
      if (password && password.length < 6) {
        return jsonResponse({ success: false, errorKey: "agency_team_err_password_short" }, 400);
      }

      const patchPayload: Record<string, any> = { updated_at: new Date().toISOString() };
      if (fullName !== undefined) patchPayload.full_name = fullName;
      if (phone !== undefined) patchPayload.phone_number = phone;
      if (status !== undefined) patchPayload.status = status;

      const patchRes = await fetch(
        `${supabaseUrl}/rest/v1/agency_members?id=eq.${encodeURIComponent(memberId)}&agency_id=eq.${encodeURIComponent(agencyAdminId)}`,
        {
          method: "PATCH",
          headers: adminHeaders,
          body: JSON.stringify(patchPayload),
        }
      );

      if (!patchRes.ok) {
        return jsonResponse({ success: false, errorKey: "agency_team_err_save_failed" }, 500);
      }
      const updatedRows = (await patchRes.json()) as any[];
      const updated = updatedRows[0];
      if (!updated) {
        return jsonResponse({ success: false, errorKey: "agency_team_err_member_not_found" }, 404);
      }

      // Sync profile fields
      if (updated.user_id && (fullName !== undefined || phone !== undefined)) {
        const profPatch: Record<string, any> = {};
        if (fullName !== undefined) profPatch.full_name = fullName;
        if (phone !== undefined) profPatch.phone_number = phone;
        await fetch(
          `${supabaseUrl}/rest/v1/profiles?id=eq.${encodeURIComponent(updated.user_id)}`,
          { method: "PATCH", headers: adminHeaders, body: JSON.stringify(profPatch) }
        );
      }

      // Optional password reset by admin
      if (updated.user_id && password.length >= 6) {
        await fetch(`${supabaseUrl}/auth/v1/admin/users/${encodeURIComponent(updated.user_id)}`, {
          method: "PUT",
          headers: adminHeaders,
          body: JSON.stringify({ password }),
        });
      }

      return jsonResponse({ success: true, member: updated });
    }

    // DELETE: Remove team member from agency
    if (req.method === "DELETE") {
      const memberId = String(body.memberId || "").trim();
      if (!memberId) {
        return jsonResponse({ success: false, errorKey: "agency_team_err_member_not_found" }, 400);
      }

      const delRes = await fetch(
        `${supabaseUrl}/rest/v1/agency_members?id=eq.${encodeURIComponent(memberId)}&agency_id=eq.${encodeURIComponent(agencyAdminId)}`,
        {
          method: "DELETE",
          headers: adminHeaders,
        }
      );

      if (!delRes.ok) {
        return jsonResponse({ success: false, errorKey: "agency_team_err_delete_failed" }, 500);
      }

      return jsonResponse({ success: true });
    }

    return jsonResponse({ success: false, errorKey: "agency_team_err_method_not_allowed" }, 405);
  } catch (err: any) {
    console.error("Unhandled error in /api/agency-team:", err);
    return jsonResponse(
      { success: false, errorKey: "agency_team_err_save_failed", detail: err?.message || String(err) },
      500
    );
  }
}

export { handler as POST, handler as PATCH, handler as DELETE };
export default handler;
