-- Secure Contract Acceptance RPC
-- This replaces the old accept_invitation logic
-- Run this in the Supabase SQL Editor

CREATE OR REPLACE FUNCTION accept_contract(contract_token TEXT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER -- Allows bypassing RLS specifically for this transaction
SET search_path = public
AS $$
DECLARE
    v_property_id UUID;
    v_invitee_email TEXT;
    v_user_id UUID;
    v_user_email TEXT;
    
    -- Terms to sync back to property
    v_rent NUMERIC;
    v_deposit NUMERIC;
    v_currency TEXT;
    v_due_day INTEGER;
    v_start_date TIMESTAMPTZ;
    v_end_date TIMESTAMPTZ;
BEGIN
    -- 1. Get the current user ID and email from auth.jwt()
    v_user_id := auth.uid();
    v_user_email := auth.jwt() ->> 'email';

    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- 2. Find and Lock the contract to prevent race conditions
    SELECT 
        property_id, invitee_email, 
        monthly_rent, deposit_amount, currency, due_day, start_date, end_date
    INTO 
        v_property_id, v_invitee_email,
        v_rent, v_deposit, v_currency, v_due_day, v_start_date, v_end_date
    FROM contracts
    WHERE token = contract_token AND status IN ('pending', 'negotiating')
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Contract not found or already accepted';
    END IF;

    -- 3. Verify the logged-in user matches the invitee
    IF LOWER(v_invitee_email) != LOWER(v_user_email) THEN
        RAISE EXCEPTION 'This contract was sent to %, but you are logged in as %', v_invitee_email, v_user_email;
    END IF;

    -- 4. Update the contract status
    UPDATE contracts
    SET status = 'active', 
        tenant_id = v_user_id,
        updated_at = now()
    WHERE token = contract_token;

    -- 5. Sync the tenant_id back to the main properties table for easy filtering
    UPDATE properties
    SET tenant_id = v_user_id
    WHERE id = v_property_id;

    -- 6. (Optional/Policy) Mark other pending/negotiating contracts for this property as declined
    UPDATE contracts
    SET status = 'declined',
        updated_at = now()
    WHERE property_id = v_property_id 
      AND id != (SELECT id FROM contracts WHERE token = contract_token)
      AND status IN ('pending', 'negotiating');

END;
$$;
