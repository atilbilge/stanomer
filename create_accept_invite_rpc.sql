-- Secure Invitation Acceptance RPC
-- Run this in the Supabase SQL Editor

CREATE OR REPLACE FUNCTION accept_invitation(invite_token TEXT)
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
BEGIN
    -- 1. Get the current user ID and email from auth.jwt()
    v_user_id := auth.uid();
    v_user_email := auth.jwt() ->> 'email';

    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- 2. Find and Lock the invitation to prevent race conditions
    SELECT property_id, invitee_email 
    INTO v_property_id, v_invitee_email
    FROM invitations
    WHERE token = invite_token AND status = 'pending'
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Invitation not found or already accepted';
    END IF;

    -- 3. Verify the logged-in user matches the invitee
    IF LOWER(v_invitee_email) != LOWER(v_user_email) THEN
        RAISE EXCEPTION 'This invitation was sent to %, but you are logged in as %', v_invitee_email, v_user_email;
    END IF;

    -- 4. Update the invitation
    UPDATE invitations
    SET status = 'accepted'
    WHERE token = invite_token;

    -- 5. Update the property
    UPDATE properties
    SET tenant_id = v_user_id
    WHERE id = v_property_id;

END;
$$;
