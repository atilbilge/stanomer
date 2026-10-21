-- ==============================================================================
-- MIGRATION: 2026-10-21_localized_password_reset.sql
-- HEDEF: YALNIZCA DEV Supabase (`thvbpifahvasyzmngpzp`)
-- TANIM: Çok dilli şifre sıfırlama (Brevo entegrasyonlu) token tablosu ve RPC fonksiyonları.
-- IDEMPOTENT: IF NOT EXISTS ve CREATE OR REPLACE ile güvenlidir.
-- ==============================================================================

-- 1. Password Reset Tokens Table
CREATE TABLE IF NOT EXISTS public.password_reset_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT NOT NULL,
    token TEXT NOT NULL UNIQUE,
    code TEXT NOT NULL,
    attempts INTEGER NOT NULL DEFAULT 0,
    expires_at TIMESTAMPTZ NOT NULL DEFAULT (now() + interval '1 hour'),
    used_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS password_reset_tokens_email_idx ON public.password_reset_tokens (lower(email));
CREATE INDEX IF NOT EXISTS password_reset_tokens_token_idx ON public.password_reset_tokens (token);
CREATE INDEX IF NOT EXISTS password_reset_tokens_code_idx ON public.password_reset_tokens (code);

-- RLS: Only accessible via security definer RPC functions
ALTER TABLE public.password_reset_tokens ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "No direct public access to password reset tokens" ON public.password_reset_tokens;
CREATE POLICY "No direct public access to password reset tokens" 
    ON public.password_reset_tokens FOR ALL TO authenticated USING (false);

-- 2. Request Password Reset Function
CREATE OR REPLACE FUNCTION public.request_password_reset(p_email TEXT)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, extensions
AS $$
DECLARE
    v_clean_email TEXT := lower(trim(p_email));
    v_user_id UUID;
    v_provider TEXT;
    v_full_name TEXT;
    v_token TEXT := gen_random_uuid()::text;
    v_code TEXT := lpad(floor(random() * 900000 + 100000)::text, 6, '0');
BEGIN
    IF v_clean_email IS NULL OR v_clean_email = '' OR position('@' in v_clean_email) = 0 THEN
        RETURN jsonb_build_object('success', false, 'error', 'invalid_email');
    END IF;

    -- 1. Check if user exists in auth.users
    SELECT id, COALESCE(raw_app_meta_data->>'provider', 'email')
    INTO v_user_id, v_provider
    FROM auth.users
    WHERE lower(email) = v_clean_email
    LIMIT 1;

    -- 2. If not found in auth.users, check public.profiles
    IF v_user_id IS NULL THEN
        SELECT id INTO v_user_id FROM public.profiles WHERE lower(email) = v_clean_email LIMIT 1;
    END IF;

    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'user_not_found');
    END IF;

    -- 3. If user is registered only via phone or oauth without email password
    IF v_provider = 'phone' THEN
        RETURN jsonb_build_object('success', false, 'error', 'phone_user_no_email');
    END IF;

    -- 4. Get full name for personalized email
    SELECT full_name INTO v_full_name FROM public.profiles WHERE id = v_user_id;

    -- 5. Invalidate previous unused tokens for this email
    UPDATE public.password_reset_tokens
    SET used_at = now()
    WHERE lower(email) = v_clean_email AND used_at IS NULL;

    -- 6. Insert new token & 6-digit code
    INSERT INTO public.password_reset_tokens (email, token, code, expires_at)
    VALUES (v_clean_email, v_token, v_code, now() + interval '1 hour');

    RETURN jsonb_build_object(
        'success', true,
        'token', v_token,
        'code', v_code,
        'user_name', COALESCE(v_full_name, split_part(v_clean_email, '@', 1))
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.request_password_reset(TEXT) TO anon, authenticated, service_role;

-- 3. Verify and Reset Password Function
CREATE OR REPLACE FUNCTION public.verify_and_reset_password(
    p_email TEXT,
    p_token_or_code TEXT,
    p_new_password TEXT
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, extensions
AS $$
DECLARE
    v_clean_email TEXT := lower(trim(p_email));
    v_input TEXT := trim(p_token_or_code);
    v_reset_row RECORD;
    v_user_id UUID;
BEGIN
    IF length(p_new_password) < 6 THEN
        RETURN jsonb_build_object('success', false, 'error', 'password_too_short');
    END IF;

    -- 1. Find valid matching token or 6-digit code
    SELECT * INTO v_reset_row
    FROM public.password_reset_tokens
    WHERE lower(email) = v_clean_email
      AND (token = v_input OR code = v_input)
      AND used_at IS NULL
      AND expires_at > now()
    ORDER BY created_at DESC
    LIMIT 1;

    IF v_reset_row IS NULL THEN
        -- Increment attempt count on active token to prevent brute force
        UPDATE public.password_reset_tokens
        SET attempts = attempts + 1,
            used_at = CASE WHEN attempts + 1 >= 5 THEN now() ELSE used_at END
        WHERE lower(email) = v_clean_email
          AND used_at IS NULL
          AND expires_at > now();

        RETURN jsonb_build_object('success', false, 'error', 'invalid_or_expired_code');
    END IF;

    -- 2. Find user in auth.users
    SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = v_clean_email LIMIT 1;

    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'user_not_found');
    END IF;

    -- 3. Update password in auth.users using bcrypt & mark email confirmed
    UPDATE auth.users
    SET encrypted_password = extensions.crypt(p_new_password, extensions.gen_salt('bf')),
        email_confirmed_at = COALESCE(email_confirmed_at, now()),
        updated_at = now()
    WHERE id = v_user_id;

    -- 4. Invalidate token
    UPDATE public.password_reset_tokens
    SET used_at = now()
    WHERE id = v_reset_row.id;

    RETURN jsonb_build_object('success', true);
END;
$$;

GRANT EXECUTE ON FUNCTION public.verify_and_reset_password(TEXT, TEXT, TEXT) TO anon, authenticated, service_role;
