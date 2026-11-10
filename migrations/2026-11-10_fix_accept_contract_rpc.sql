-- Migration: Fix accept_contract RPC for idempotent acceptance and active/unclaimed contracts
-- Target: DEV database (thvbpifahvasyzmngpzp)

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
END;
$$;

GRANT ALL ON FUNCTION public.accept_contract(text) TO authenticated;
GRANT ALL ON FUNCTION public.accept_contract(text) TO service_role;

