-- Migration: Fix tenant invitation and contract acceptance
-- Target: DEV database (thvbpifahvasyzmngpzp)
-- Ensures idempotent and consistent acceptance across contracts and invitations tables

-- 1. Ensure RLS on contracts allows SELECT by token
DROP POLICY IF EXISTS "Users can view relevant contracts" ON public.contracts;
DROP POLICY IF EXISTS "contracts_select_policy" ON public.contracts;
CREATE POLICY "contracts_select_policy" ON public.contracts FOR SELECT TO authenticated
    USING (landlord_id = auth.uid() OR tenant_id = auth.uid() OR agency_id = auth.uid() OR (invitee_email IS NOT NULL AND LOWER(invitee_email) = LOWER(COALESCE(auth.jwt()->>'email', ''))) OR (token IS NOT NULL));

-- 2. Update get_invite_details to resolve contracts even if status was saved as active but unclaimed
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
      AND (c.status IN ('pending', 'negotiating') OR (c.status = 'active' AND c.tenant_id IS NULL));

    IF v_contract_json IS NOT NULL THEN
        RETURN v_contract_json;
    END IF;

    RETURN NULL;
END;
$$;

-- 3. Update accept_contract to synchronize invitations table
CREATE OR REPLACE FUNCTION public.accept_contract(contract_token text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_contract_id UUID;
    v_property_id UUID;
    v_invitee_email TEXT;
    v_current_tenant_id UUID;
    v_current_status public.contract_status;
    v_user_id UUID;
    v_user_email TEXT;
    v_rent NUMERIC;
    v_deposit NUMERIC;
    v_currency TEXT;
    v_due_day INTEGER;
    v_start_date TIMESTAMPTZ;
    v_end_date TIMESTAMPTZ;
    v_contract_url TEXT;
BEGIN
    v_user_id := auth.uid();
    v_user_email := auth.jwt() ->> 'email';

    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- 1. Find contract by token or fallback to user email
    SELECT 
        id, property_id, invitee_email, tenant_id, status,
        monthly_rent, deposit_amount, currency, due_day, start_date, end_date, contract_url
    INTO 
        v_contract_id, v_property_id, v_invitee_email, v_current_tenant_id, v_current_status,
        v_rent, v_deposit, v_currency, v_due_day, v_start_date, v_end_date, v_contract_url
    FROM public.contracts
    WHERE (
        (contract_token IS NOT NULL AND contract_token != '' AND token = contract_token)
        OR (
            (contract_token IS NULL OR contract_token = '') 
            AND invitee_email IS NOT NULL 
            AND LOWER(invitee_email) = LOWER(v_user_email)
            AND (tenant_id IS NULL OR tenant_id = v_user_id)
        )
    )
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Contract not found or already accepted';
    END IF;

    -- 2. Idempotent check: if user already accepted this contract, succeed gracefully
    IF v_current_tenant_id = v_user_id AND v_current_status = 'active' THEN
        UPDATE public.properties
        SET tenant_id = v_user_id
        WHERE id = v_property_id AND tenant_id IS NULL;
        RETURN;
    END IF;

    -- 3. Prevent overwriting another tenant
    IF v_current_tenant_id IS NOT NULL AND v_current_tenant_id != v_user_id THEN
        RAISE EXCEPTION 'This contract is already assigned to another tenant';
    END IF;

    -- 4. Update contract status and assign tenant
    UPDATE public.contracts
    SET status = 'active',
        tenant_id = v_user_id,
        updated_at = now()
    WHERE id = v_contract_id;

    -- 5. Sync property primary tenant_id
    UPDATE public.properties
    SET tenant_id = v_user_id
    WHERE id = v_property_id;

    -- 6. Sync leases table if it exists
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'leases') THEN
        INSERT INTO public.leases (property_id, tenant_id, tenant_email, start_date, end_date, status, contract_pdf_url, invitation_token)
        VALUES (v_property_id, v_user_id, v_user_email, v_start_date::date, v_end_date::date, 'active', v_contract_url, contract_token)
        ON CONFLICT (invitation_token) DO UPDATE 
        SET tenant_id = v_user_id, status = 'active';
    END IF;

    -- 7. Sync invitations table if invitation exists
    UPDATE public.invitations
    SET status = 'accepted'
    WHERE (contract_id = v_contract_id OR token = contract_token) AND status = 'pending';
END;
$$;

GRANT ALL ON FUNCTION public.accept_contract(text) TO authenticated;
GRANT ALL ON FUNCTION public.accept_contract(text) TO service_role;

-- 4. Update accept_invitation to synchronize contracts and properties properly
CREATE OR REPLACE FUNCTION public.accept_invitation(p_invite_token text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_property_id UUID;
    v_contract_id UUID;
    v_invitee_email TEXT;
    v_user_id UUID;
    v_user_email TEXT;
    v_start_date DATE;
    v_end_date DATE;
    v_contract_url TEXT;
BEGIN
    v_user_id := auth.uid();
    v_user_email := auth.jwt() ->> 'email';

    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    SELECT property_id, contract_id, invitee_email 
    INTO v_property_id, v_contract_id, v_invitee_email
    FROM public.invitations
    WHERE token = p_invite_token AND status = 'pending'
    FOR UPDATE;

    IF NOT FOUND THEN
        -- Fallback: check if this token exists directly in contracts table
        IF EXISTS (SELECT 1 FROM public.contracts WHERE token = p_invite_token) THEN
            PERFORM public.accept_contract(p_invite_token);
            RETURN;
        END IF;
        RAISE EXCEPTION 'Invitation not found or already accepted';
    END IF;

    -- Email soft check
    IF v_invitee_email IS NOT NULL AND v_invitee_email != '' THEN
        IF LOWER(v_invitee_email) != LOWER(COALESCE(v_user_email, ''))
           AND COALESCE(v_user_email, '') NOT LIKE '%@privaterelay.appleid.com' THEN
            RAISE EXCEPTION 'This invitation was sent to %, but you are logged in as %', 
                v_invitee_email, v_user_email;
        END IF;
    END IF;

    -- Update invitation status
    UPDATE public.invitations
    SET status = 'accepted'
    WHERE token = p_invite_token;

    -- Update contract if associated
    IF v_contract_id IS NOT NULL THEN
        SELECT start_date::date, end_date::date, contract_url
        INTO v_start_date, v_end_date, v_contract_url
        FROM public.contracts
        WHERE id = v_contract_id;

        UPDATE public.contracts
        SET status = 'active',
            tenant_id = v_user_id,
            updated_at = now()
        WHERE id = v_contract_id;
    ELSE
        SELECT start_date::date, end_date::date, contract_url
        INTO v_start_date, v_end_date, v_contract_url
        FROM public.contracts
        WHERE property_id = v_property_id AND (status IN ('pending', 'active') AND (tenant_id IS NULL OR tenant_id = v_user_id))
        ORDER BY created_at DESC
        LIMIT 1;

        UPDATE public.contracts
        SET status = 'active',
            tenant_id = v_user_id,
            updated_at = now()
        WHERE property_id = v_property_id AND (status IN ('pending', 'active') AND (tenant_id IS NULL OR tenant_id = v_user_id));
    END IF;

    -- Sync leases
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'leases') THEN
        INSERT INTO public.leases (property_id, tenant_id, tenant_email, start_date, end_date, status, contract_pdf_url, invitation_token)
        VALUES (v_property_id, v_user_id, v_user_email, v_start_date, v_end_date, 'active', v_contract_url, p_invite_token)
        ON CONFLICT (invitation_token) DO UPDATE
        SET tenant_id = v_user_id, status = 'active';
    END IF;

    -- Update property
    UPDATE public.properties
    SET tenant_id = v_user_id
    WHERE id = v_property_id;
END;
$$;

GRANT ALL ON FUNCTION public.accept_invitation(text) TO authenticated;
GRANT ALL ON FUNCTION public.accept_invitation(text) TO service_role;
