-- ==============================================================================
-- STANOMER DATABASE MIGRATION - VERSION 2.0.2 RELEASE SYNC
-- Date: 2026-08-19
-- Target: Supabase PostgreSQL (Idempotent & Safe for Live/Production Deployment)
-- Description:
--   1. Marketing & Referral tracking columns on public.profiles
--   2. Agency Demo Requests table & token verification RPC
--   3. Email Unsubscribes table for transactional compliance
--   4. Agency Referral Partners table & indexes (with optional phone support)
--   5. Agency OTP Codes table for passwordless partner portal authentication
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. PROFILES TABLE - MARKETING & AGENCY REFERRAL EXTENSIONS
-- ------------------------------------------------------------------------------
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS referred_by_agency_code TEXT DEFAULT NULL;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS utm_source TEXT DEFAULT NULL;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS utm_medium TEXT DEFAULT NULL;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS utm_campaign TEXT DEFAULT NULL;

CREATE INDEX IF NOT EXISTS profiles_referred_by_agency_code_idx 
    ON public.profiles (referred_by_agency_code);

-- ------------------------------------------------------------------------------
-- 2. AGENCY DEMO REQUESTS (White-Label / Agency Demo Lead Capture)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.agency_demo_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agency_name TEXT NOT NULL,
    email TEXT NOT NULL,
    website TEXT,
    phone_number TEXT,
    special_requests TEXT,
    status TEXT DEFAULT 'pending',
    verification_token UUID DEFAULT gen_random_uuid(),
    is_email_verified BOOLEAN DEFAULT FALSE,
    token_expires_at TIMESTAMPTZ DEFAULT (now() + interval '24 hours'),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    utm_source TEXT DEFAULT NULL,
    utm_medium TEXT DEFAULT NULL,
    utm_campaign TEXT DEFAULT NULL
);

-- Ensure columns exist if table was already created
ALTER TABLE public.agency_demo_requests ADD COLUMN IF NOT EXISTS verification_token UUID DEFAULT gen_random_uuid();
ALTER TABLE public.agency_demo_requests ADD COLUMN IF NOT EXISTS is_email_verified BOOLEAN DEFAULT FALSE;
ALTER TABLE public.agency_demo_requests ADD COLUMN IF NOT EXISTS token_expires_at TIMESTAMPTZ DEFAULT (now() + interval '24 hours');
ALTER TABLE public.agency_demo_requests ADD COLUMN IF NOT EXISTS utm_source TEXT DEFAULT NULL;
ALTER TABLE public.agency_demo_requests ADD COLUMN IF NOT EXISTS utm_medium TEXT DEFAULT NULL;
ALTER TABLE public.agency_demo_requests ADD COLUMN IF NOT EXISTS utm_campaign TEXT DEFAULT NULL;

CREATE INDEX IF NOT EXISTS agency_demo_requests_email_idx ON public.agency_demo_requests (lower(email));
CREATE INDEX IF NOT EXISTS agency_demo_requests_verification_token_idx ON public.agency_demo_requests (verification_token);

ALTER TABLE public.agency_demo_requests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "agency_demo_requests_insert_policy" ON public.agency_demo_requests;
CREATE POLICY "agency_demo_requests_insert_policy" ON public.agency_demo_requests
    FOR INSERT TO public WITH CHECK (true);

DROP POLICY IF EXISTS "agency_demo_requests_select_policy" ON public.agency_demo_requests;
CREATE POLICY "agency_demo_requests_select_policy" ON public.agency_demo_requests
    FOR SELECT TO public USING (true);

-- RPC for agency demo token verification
CREATE OR REPLACE FUNCTION public.verify_agency_demo_token(p_token UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_request RECORD;
BEGIN
    SELECT * INTO v_request
    FROM public.agency_demo_requests
    WHERE verification_token = p_token;

    IF v_request IS NULL THEN
        RETURN jsonb_build_object('success', false, 'message', 'Geçersiz veya bulunamayan doğrulama kodu.');
    END IF;

    IF v_request.token_expires_at < now() THEN
        RETURN jsonb_build_object('success', false, 'message', 'Doğrulama bağlantısının süresi dolmuş.');
    END IF;

    IF v_request.is_email_verified THEN
        RETURN jsonb_build_object('success', true, 'already_verified', true, 'message', 'E-posta adresi zaten doğrulanmış.');
    END IF;

    UPDATE public.agency_demo_requests
    SET is_email_verified = TRUE,
        status = 'email_verified',
        updated_at = now()
    WHERE id = v_request.id;

    RETURN jsonb_build_object('success', true, 'message', 'E-posta adresiniz başarıyla doğrulandı.');
END;
$$;

GRANT EXECUTE ON FUNCTION public.verify_agency_demo_token(UUID) TO anon, authenticated;


-- ------------------------------------------------------------------------------
-- 3. EMAIL UNSUBSCRIBES TABLE (Transactional Email Compliance)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.email_unsubscribes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT NOT NULL,
    reason TEXT DEFAULT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS email_unsubscribes_email_idx 
    ON public.email_unsubscribes (lower(email));

ALTER TABLE public.email_unsubscribes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "email_unsubscribes_insert_policy" ON public.email_unsubscribes;
CREATE POLICY "email_unsubscribes_insert_policy" ON public.email_unsubscribes
    FOR INSERT TO public WITH CHECK (true);

DROP POLICY IF EXISTS "email_unsubscribes_select_policy" ON public.email_unsubscribes;
CREATE POLICY "email_unsubscribes_select_policy" ON public.email_unsubscribes
    FOR SELECT TO public USING (true);

-- ------------------------------------------------------------------------------
-- 4. AGENCY REFERRAL PARTNERS (Static QR & Referral Agency Model)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.agency_referral_partners (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agency_name TEXT NOT NULL,
    contact_name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    phone TEXT DEFAULT NULL,
    city TEXT NOT NULL,
    website TEXT DEFAULT NULL,
    agency_size TEXT DEFAULT NULL,
    referral_source TEXT DEFAULT NULL,
    slug TEXT NOT NULL UNIQUE,
    referral_code TEXT NOT NULL UNIQUE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Ensure phone is nullable if table pre-existed
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'agency_referral_partners' AND column_name = 'phone' AND is_nullable = 'NO'
    ) THEN
        ALTER TABLE public.agency_referral_partners ALTER COLUMN phone DROP NOT NULL;
    END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS agency_referral_partners_email_idx
    ON public.agency_referral_partners (lower(email));

CREATE UNIQUE INDEX IF NOT EXISTS agency_referral_partners_agency_name_idx
    ON public.agency_referral_partners (lower(agency_name));

CREATE UNIQUE INDEX IF NOT EXISTS agency_referral_partners_slug_idx
    ON public.agency_referral_partners (lower(slug));

CREATE UNIQUE INDEX IF NOT EXISTS agency_referral_partners_code_idx
    ON public.agency_referral_partners (lower(referral_code));

ALTER TABLE public.agency_referral_partners ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "agency_referral_partners_insert_policy" ON public.agency_referral_partners;
CREATE POLICY "agency_referral_partners_insert_policy" ON public.agency_referral_partners
    FOR INSERT TO public WITH CHECK (true);

DROP POLICY IF EXISTS "agency_referral_partners_select_policy" ON public.agency_referral_partners;
CREATE POLICY "agency_referral_partners_select_policy" ON public.agency_referral_partners
    FOR SELECT TO public USING (true);

-- ------------------------------------------------------------------------------
-- 5. AGENCY OTP CODES (Passwordless Partner Portal Auth)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.agency_otp_codes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT NOT NULL,
    otp_hash TEXT NOT NULL,
    attempts INTEGER DEFAULT 0,
    is_used BOOLEAN DEFAULT FALSE,
    expires_at TIMESTAMPTZ NOT NULL,
    blocked_until TIMESTAMPTZ DEFAULT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS agency_otp_codes_email_idx 
    ON public.agency_otp_codes (lower(email));

ALTER TABLE public.agency_otp_codes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "agency_otp_codes_insert_policy" ON public.agency_otp_codes;
CREATE POLICY "agency_otp_codes_insert_policy" ON public.agency_otp_codes
    FOR INSERT TO public WITH CHECK (true);

DROP POLICY IF EXISTS "agency_otp_codes_select_policy" ON public.agency_otp_codes;
CREATE POLICY "agency_otp_codes_select_policy" ON public.agency_otp_codes
    FOR SELECT TO public USING (true);

DROP POLICY IF EXISTS "agency_otp_codes_update_policy" ON public.agency_otp_codes;
CREATE POLICY "agency_otp_codes_update_policy" ON public.agency_otp_codes
    FOR UPDATE TO public USING (true);

-- ==============================================================================
-- END OF VERSION 2.0.2 MIGRATION SCRIPT
-- ==============================================================================
