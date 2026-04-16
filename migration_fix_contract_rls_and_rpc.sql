-- CONSOLIDATED FIX: RLS, RPC, and Name Visibility
-- Run this in the Supabase SQL Editor

-- 1. Ensure 'revision_requested' exists in the enum
ALTER TYPE contract_status ADD VALUE IF NOT EXISTS 'revision_requested';

-- 2. Profiles RLS: Allow authenticated users to see full names
-- This is required for the joins in properties_with_names view to work
DROP POLICY IF EXISTS authenticated_select_profiles ON public.profiles;
CREATE POLICY authenticated_select_profiles ON public.profiles
    FOR SELECT
    TO authenticated
    USING (true);

-- 3. Contract UPDATE Policy
DROP POLICY IF EXISTS tenant_respond_contract ON public.contracts;
CREATE POLICY tenant_respond_contract ON public.contracts
    FOR UPDATE
    USING (
        LOWER(invitee_email) = LOWER(auth.jwt() ->> 'email')
        OR tenant_id = auth.uid()
    )
    WITH CHECK (
        status IN ('pending', 'negotiating', 'active', 'declined', 'revision_requested')
    );

-- 4. Property SELECT Policy
DROP POLICY IF EXISTS tenant_view_invited_properties ON public.properties;
CREATE POLICY tenant_view_invited_properties ON public.properties
    FOR SELECT
    USING (
        id IN (
            SELECT property_id 
            FROM public.contracts 
            WHERE (LOWER(invitee_email) = LOWER(auth.jwt() ->> 'email') OR tenant_id = auth.uid())
              AND status IN ('pending', 'negotiating', 'revision_requested', 'active')
        )
    );

-- 5. FIXED: generate_missing_rent_payments RPC
-- Removed the reference to 'contract_start_date' in properties table
CREATE OR REPLACE FUNCTION generate_missing_rent_payments(p_property_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_start_date date;
    v_end_date date;
    v_current_date date;
    v_monthly_rent numeric;
    v_currency text;
    v_tenant_id uuid;
    v_due_day integer;
    v_approved_row record;
BEGIN
    -- Get current lease terms from the ACTIVE contract only
    SELECT start_date, monthly_rent, currency, tenant_id, COALESCE(due_day, 1)
    INTO v_start_date, v_monthly_rent, v_currency, v_tenant_id, v_due_day
    FROM contracts
    WHERE property_id = p_property_id AND status = 'active'
    LIMIT 1;

    -- If no active contract, we stop here
    IF v_start_date IS NULL OR v_monthly_rent IS NULL OR v_tenant_id IS NULL THEN
        RETURN;
    END IF;

    -- AUTO-APPROVE: Mark 'declared' as 'paid' if it's been more than 5 days
    FOR v_approved_row IN 
        UPDATE rent_payments 
        SET status = 'paid', paid_at = (declared_at + interval '5 days')
        WHERE property_id = p_property_id
          AND status = 'declared'
          AND declared_at < (now() - interval '5 days')
        RETURNING id, due_date
    LOOP
        INSERT INTO activity_logs (property_id, type, metadata)
        VALUES (p_property_id, 'rent_auto_approved', jsonb_build_object('month', v_approved_row.due_date));
    END LOOP;

    -- CLEANUP: Delete any "pending" rows that are now BEFORE the contract start month
    DELETE FROM rent_payments
    WHERE property_id = p_property_id
      AND status = 'pending'
      AND date_trunc('month', due_date) < date_trunc('month', v_start_date);

    -- Loop from start date to today (plus 1 month buffer)
    v_current_date := (date_trunc('month', v_start_date) + (v_due_day - 1) * interval '1 day')::date;
    v_end_date := (date_trunc('month', now() + interval '1 month') + (v_due_day - 1) * interval '1 day')::date;

    WHILE v_current_date <= v_end_date LOOP
        INSERT INTO rent_payments (property_id, tenant_id, amount, currency, due_date, status)
        VALUES (p_property_id, v_tenant_id, v_monthly_rent, v_currency, v_current_date, 'pending')
        ON CONFLICT (property_id, due_date) 
        DO UPDATE SET 
            tenant_id = COALESCE(EXCLUDED.tenant_id, rent_payments.tenant_id), 
            amount = EXCLUDED.amount, 
            currency = EXCLUDED.currency
        WHERE rent_payments.status = 'pending';

        v_current_date := (date_trunc('month', v_current_date + interval '1.5 month') + (v_due_day - 1) * interval '1 day')::date;
    END LOOP;
END;
$$;

-- 6. Updated accept_contract RPC
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
BEGIN
    v_user_id := auth.uid();
    v_user_email := auth.jwt() ->> 'email';

    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    SELECT property_id, invitee_email
    INTO v_property_id, v_invitee_email
    FROM contracts
    WHERE token = contract_token AND status IN ('pending', 'negotiating', 'revision_requested')
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Contract not found or already accepted';
    END IF;

    IF LOWER(v_invitee_email) != LOWER(v_user_email) THEN
        RAISE EXCEPTION 'This contract was sent to %, but you are logged in as %', v_invitee_email, v_user_email;
    END IF;

    UPDATE contracts
    SET status = 'active', 
        tenant_id = v_user_id,
        updated_at = now()
    WHERE token = contract_token;

    UPDATE properties
    SET tenant_id = v_user_id
    WHERE id = v_property_id;

    -- Generate initial rent payments
    PERFORM generate_missing_rent_payments(v_property_id);

    -- Decline ALL OTHER contracts for this property to ensure only ONE is active
    UPDATE contracts
    SET status = 'declined',
        updated_at = now()
    WHERE property_id = v_property_id 
      AND id != (SELECT id FROM contracts WHERE token = contract_token LIMIT 1)
      AND status NOT IN ('active'); -- We handle 'active' separately if needed, but for now we want to decline ALL others.

    -- Also handle any existing ACTIVE contract if we want to supersede it
    UPDATE contracts
    SET status = 'declined', -- or 'superseded' if we had such a status
        updated_at = now()
    WHERE property_id = v_property_id 
      AND id != (SELECT id FROM contracts WHERE token = contract_token LIMIT 1)
      AND status = 'active';
END;
$$;

-- 7. View for real-time joins
CREATE OR REPLACE VIEW properties_with_names AS
SELECT 
    p.*,
    lp.full_name as landlord_name,
    tp.full_name as tenant_name
FROM properties p
LEFT JOIN profiles lp ON p.landlord_id = lp.id
LEFT JOIN profiles tp ON p.tenant_id = tp.id;

ALTER VIEW properties_with_names SET (security_invoker = on);
