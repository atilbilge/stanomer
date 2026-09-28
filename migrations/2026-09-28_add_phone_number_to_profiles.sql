-- ==============================================================================
-- Migration: Add missing phone_number and avatar_url to profiles table & harden claim_landlord_ownership
-- Date: 2026-09-28
-- Target Environment: Dev Database (thvbpifahvasyzmngpzp)
-- Safety: 100% idempotent, non-destructive, zero data loss
-- ==============================================================================

-- 1. Ensure phone_number and avatar_url columns exist on public.profiles
ALTER TABLE public.profiles 
    ADD COLUMN IF NOT EXISTS phone_number TEXT,
    ADD COLUMN IF NOT EXISTS avatar_url TEXT;

-- 2. Harden claim_landlord_ownership function
-- Resolves error 42703 (column "phone_number" does not exist) and provides fallback to auth.jwt()
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
    -- Get authenticated user's email
    v_user_email := COALESCE(auth.jwt()->>'email', '');
    
    -- Query profile details with safe fallback
    SELECT 
        full_name, 
        phone_number 
    INTO 
        v_user_name, 
        v_user_phone
    FROM public.profiles
    WHERE id = auth.uid();

    -- Fallback to auth token metadata if phone_number is not set in profile
    IF v_user_phone IS NULL OR v_user_phone = '' THEN
        v_user_phone := COALESCE(auth.jwt()->>'phone', '');
    END IF;

    -- Find matching pending invitation
    SELECT * INTO v_invitation
    FROM public.invitations
    WHERE token = p_token
      AND target_role = 'landlord'
      AND status = 'pending'
      AND expires_at > now();

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false, 
            'message', 'Geçersiz, süresi dolmuş veya ev sahibi rolüne ait olmayan davet bağlantısı.'
        );
    END IF;

    -- Update property ownership & landlord contact info
    UPDATE public.properties
    SET landlord_id = auth.uid(),
        landlord_name = COALESCE(NULLIF(v_user_name, ''), landlord_name),
        landlord_email = COALESCE(NULLIF(v_user_email, ''), landlord_email),
        landlord_phone = COALESCE(NULLIF(v_user_phone, ''), landlord_phone),
        updated_at = now()
    WHERE id = v_invitation.property_id;

    -- Mark invitation as accepted
    UPDATE public.invitations
    SET status = 'accepted'
    WHERE id = v_invitation.id;

    RETURN jsonb_build_object(
        'success', true, 
        'property_id', v_invitation.property_id,
        'message', 'Mülk yönetimi başarıyla üstlenildi.'
    );
END;
$$;
