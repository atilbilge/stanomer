-- ============================================================================
-- MIGRATION: 2026-07-29 — Agency Landlord Ownership Assignment & Sharing
-- Target: Dev DB (thvbpifahvasyzmngpzp)
-- Safe: Idempotent, backward-compatible
-- ============================================================================

-- 1. Make properties.landlord_id nullable (for properties created by an agency prior to landlord claim)
ALTER TABLE public.properties ALTER COLUMN landlord_id DROP NOT NULL;

-- 2. Add landlord contact columns to properties (safe individual statements)
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS landlord_name TEXT;
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS landlord_phone TEXT;
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS landlord_email TEXT;

-- 3. Add target_role column and make invitee_email nullable in invitations table
ALTER TABLE public.invitations ALTER COLUMN invitee_email DROP NOT NULL;
ALTER TABLE public.invitations
    ADD COLUMN IF NOT EXISTS target_role TEXT DEFAULT 'tenant';

-- 4. RPC to claim landlord ownership using invitation token
CREATE OR REPLACE FUNCTION public.claim_landlord_ownership(p_token TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_invitation RECORD;
    v_user_email TEXT;
    v_user_name TEXT;
    v_user_phone TEXT;
BEGIN
    -- Get current authenticated user details
    v_user_email := COALESCE(auth.jwt()->>'email', '');
    
    SELECT full_name, phone_number INTO v_user_name, v_user_phone
    FROM public.profiles
    WHERE id = auth.uid();

    -- Find matching pending invitation
    SELECT * INTO v_invitation
    FROM public.invitations
    WHERE token = p_token
      AND target_role = 'landlord'
      AND status = 'pending'
      AND expires_at > now();

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'message', 'Invalid, expired, or non-landlord invitation token.');
    END IF;

    -- Update property ownership
    UPDATE public.properties
    SET landlord_id = auth.uid(),
        landlord_name = COALESCE(NULLIF(v_user_name, ''), landlord_name),
        landlord_email = COALESCE(NULLIF(v_user_email, ''), landlord_email),
        landlord_phone = COALESCE(NULLIF(v_user_phone, ''), landlord_phone),
        updated_at = now()
    WHERE id = v_invitation.property_id;

    -- Mark invitation accepted
    UPDATE public.invitations
    SET status = 'accepted'
    WHERE id = v_invitation.id;

    RETURN jsonb_build_object(
        'success', true,
        'property_id', v_invitation.property_id,
        'message', 'Landlord ownership claimed successfully.'
    );
END;
$$;

-- 5. RPC to get invite details securely (bypasses RLS for pending invite tokens)
CREATE OR REPLACE FUNCTION public.get_invite_details(p_token TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_invite_json JSONB;
    v_contract_json JSONB;
BEGIN
    -- 1) Try invitations table
    SELECT (to_jsonb(i.*) || jsonb_build_object(
        'type', CASE WHEN i.target_role = 'landlord' THEN 'landlord_ownership' ELSE 'invitation' END,
        'properties', jsonb_build_object(
            'id', p.id,
            'name', p.name,
            'title', p.title,
            'address', p.address,
            'default_monthly_rent', p.default_monthly_rent,
            'default_deposit_amount', p.default_deposit_amount,
            'currency', p.currency,
            'landlord_id', p.landlord_id,
            'tenant_id', p.tenant_id,
            'agency_id', p.agency_id,
            'landlord_name', p.landlord_name,
            'landlord_email', p.landlord_email,
            'landlord_phone', p.landlord_phone
        )
    ))
    INTO v_invite_json
    FROM public.invitations i
    JOIN public.properties p ON p.id = i.property_id
    WHERE i.token = p_token
      AND i.status = 'pending'
      AND i.expires_at > now();

    IF v_invite_json IS NOT NULL THEN
        RETURN v_invite_json;
    END IF;

    -- 2) Try contracts table
    SELECT (to_jsonb(c.*) || jsonb_build_object(
        'type', 'contract',
        'properties', jsonb_build_object(
            'id', p.id,
            'name', p.name,
            'title', p.title,
            'address', p.address,
            'default_monthly_rent', p.default_monthly_rent,
            'default_deposit_amount', p.default_deposit_amount,
            'currency', p.currency,
            'landlord_id', p.landlord_id,
            'tenant_id', p.tenant_id,
            'agency_id', p.agency_id
        )
    ))
    INTO v_contract_json
    FROM public.contracts c
    JOIN public.properties p ON p.id = c.property_id
    WHERE c.token = p_token
      AND c.status IN ('pending', 'negotiating');

    IF v_contract_json IS NOT NULL THEN
        RETURN v_contract_json;
    END IF;

    RETURN NULL;
END;
$$;

-- 6. Add RLS policy on properties allowing token holders to view property info
DROP POLICY IF EXISTS "users_view_invited_properties_by_token" ON public.properties;
CREATE POLICY "users_view_invited_properties_by_token" ON public.properties FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.invitations i 
            WHERE i.property_id = properties.id 
              AND i.token IS NOT NULL 
              AND i.status = 'pending'
        )
    );

-- 7. Update properties_with_names view
DROP VIEW IF EXISTS public.properties_with_names CASCADE;

CREATE VIEW public.properties_with_names AS
SELECT 
    p.id,
    p.landlord_id,
    p.tenant_id,
    p.agency_id,
    p.title,
    p.name,
    p.address,
    p.default_monthly_rent,
    p.default_deposit_amount,
    p.currency,
    p.default_deposit_currency,
    p.default_due_day,
    p.expenses_template,
    p.owner_note,
    p.tax_type,
    p.created_at,
    p.updated_at,
    p.landlord_phone,
    COALESCE(l.full_name, p.landlord_name) AS landlord_name,
    COALESCE(l.email, p.landlord_email) AS landlord_email,
    t.full_name AS tenant_name,
    t.email AS tenant_email,
    a.company_name AS agency_name,
    a.email AS agency_email
FROM public.properties p
LEFT JOIN public.profiles l ON p.landlord_id = l.id
LEFT JOIN public.profiles t ON p.tenant_id = t.id
LEFT JOIN public.profiles a ON p.agency_id = a.id;

ALTER VIEW public.properties_with_names SET (security_invoker = on);

-- 8. Reload schema cache
NOTIFY pgrst, 'reload schema';
