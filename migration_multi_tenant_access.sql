-- Migration: Multi-tenant access and shared leases (RECURSION FIX & ROBUST NAMES)
-- This script updates the contract and invitation acceptance logic to use the 'leases' table.
-- It also updates properties RLS to allow shared access and fixes name visibility.

-- 1. Helper functions to break RLS recursion
CREATE OR REPLACE FUNCTION public.check_is_landlord_of_property(p_id UUID, u_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.properties WHERE id = p_id AND landlord_id = u_id
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.check_is_tenant_of_property(p_id UUID, u_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.leases WHERE property_id = p_id AND tenant_id = u_id
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 2. Ensure RLS on leases table
ALTER TABLE IF EXISTS public.leases ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own leases" ON public.leases;
CREATE POLICY "Users can view their own leases" ON public.leases
    FOR SELECT
    USING (
        auth.uid() = tenant_id 
        OR check_is_landlord_of_property(property_id, auth.uid())
    );

-- 3. Profiles RLS: Ensure names are visible for joins
DROP POLICY IF EXISTS authenticated_select_profiles ON public.profiles;
CREATE POLICY authenticated_select_profiles ON public.profiles
    FOR SELECT
    TO authenticated
    USING (true);

-- 4. Update accept_contract RPC to insert into leases
CREATE OR REPLACE FUNCTION accept_contract(contract_token TEXT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_property_id UUID;
    v_invitee_email TEXT;
    v_user_id UUID;
    v_user_email TEXT;
    v_start_date TIMESTAMPTZ;
    v_end_date TIMESTAMPTZ;
    v_contract_url TEXT;
BEGIN
    v_user_id := auth.uid();
    v_user_email := auth.jwt() ->> 'email';

    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    SELECT property_id, invitee_email, start_date, end_date, contract_url
    INTO v_property_id, v_invitee_email, v_start_date, v_end_date, v_contract_url
    FROM contracts
    WHERE token = contract_token AND status IN ('pending', 'negotiating', 'revision_requested')
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Contract not found or already accepted';
    END IF;

    IF LOWER(v_invitee_email) != LOWER(v_user_email) THEN
        RAISE EXCEPTION 'This contract was sent to %, but you are logged in as %', v_invitee_email, v_user_email;
    END IF;

    -- Update contract
    UPDATE contracts
    SET status = 'active', 
        tenant_id = v_user_id,
        updated_at = now()
    WHERE token = contract_token;

    -- Update property primary tenant
    UPDATE properties
    SET tenant_id = v_user_id
    WHERE id = v_property_id;

    -- INSERT INTO LEASES (The shared source of truth)
    INSERT INTO leases (property_id, tenant_id, tenant_email, start_date, end_date, status, contract_pdf_url, invitation_token)
    VALUES (v_property_id, v_user_id, v_user_email, v_start_date::date, v_end_date::date, 'active', v_contract_url, contract_token)
    ON CONFLICT (invitation_token) DO NOTHING;

    -- Decline other contracts
    UPDATE contracts
    SET status = 'declined',
        updated_at = now()
    WHERE property_id = v_property_id 
      AND token != contract_token
      AND status IN ('pending', 'negotiating', 'revision_requested');

END;
$$;

-- 5. Update accept_invitation RPC to insert into leases
CREATE OR REPLACE FUNCTION accept_invitation(invite_token TEXT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_property_id UUID;
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

    -- Find invitation
    SELECT property_id, invitee_email 
    INTO v_property_id, v_invitee_email
    FROM invitations
    WHERE token = invite_token AND status = 'pending'
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Invitation not found or already accepted';
    END IF;

    IF LOWER(v_invitee_email) != LOWER(v_user_email) THEN
        RAISE EXCEPTION 'This invitation was sent to %, but you are logged in as %', v_invitee_email, v_user_email;
    END IF;

    -- Get terms from the ACTIVE contract to populate lease
    SELECT start_date::date, end_date::date, contract_url
    INTO v_start_date, v_end_date, v_contract_url
    FROM contracts
    WHERE property_id = v_property_id AND status = 'active'
    LIMIT 1;

    -- Update invitation
    UPDATE invitations
    SET status = 'accepted'
    WHERE token = invite_token;

    -- INSERT INTO LEASES (Adding as a co-tenant)
    INSERT INTO leases (property_id, tenant_id, tenant_email, start_date, end_date, status, contract_pdf_url, invitation_token)
    VALUES (v_property_id, v_user_id, v_user_email, v_start_date, v_end_date, 'active', v_contract_url, invite_token)
    ON CONFLICT (invitation_token) DO NOTHING;

    -- Ensure property.tenant_id is set if it's currently null
    UPDATE properties
    SET tenant_id = v_user_id
    WHERE id = v_property_id AND tenant_id IS NULL;

END;
$$;

-- 6. Update properties RLS to allow shared access via leases table
DROP POLICY IF EXISTS tenant_view_properties ON public.properties;
CREATE POLICY tenant_view_properties ON public.properties
    FOR SELECT
    USING (
        auth.uid() = landlord_id 
        OR auth.uid() = tenant_id 
        OR check_is_tenant_of_property(id, auth.uid())
    );

-- 7. Robust View for real-time joins with fallbacks
CREATE OR REPLACE VIEW properties_with_names AS
SELECT 
    p.*,
    COALESCE(
        lp.full_name, 
        (SELECT inviter_name FROM contracts WHERE property_id = p.id AND status = 'active' LIMIT 1),
        'Landlord'
    ) as landlord_name,
    COALESCE(
        tp.full_name, 
        (SELECT invitee_email FROM contracts WHERE property_id = p.id AND status = 'active' LIMIT 1),
        'Tenant'
    ) as tenant_name
FROM properties p
LEFT JOIN profiles lp ON p.landlord_id = lp.id
LEFT JOIN profiles tp ON p.tenant_id = tp.id;

ALTER VIEW properties_with_names SET (security_invoker = on);
