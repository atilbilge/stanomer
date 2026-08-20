-- ==============================================================================
-- MERGED MIGRATION: 2026-08-17 (Agency Referral, Profiles, OTP Auth, Trigger Fix)
-- ==============================================================================

-- 1. CREATE AGENCY_REFERRAL_PARTNERS TABLE
CREATE TABLE IF NOT EXISTS public.agency_referral_partners (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agency_name TEXT NOT NULL,
    contact_name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    phone TEXT NOT NULL,
    city TEXT NOT NULL,
    website TEXT DEFAULT NULL,
    agency_size TEXT DEFAULT NULL,
    referral_source TEXT DEFAULT NULL,
    slug TEXT NOT NULL UNIQUE,
    referral_code TEXT NOT NULL UNIQUE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

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

-- 2. ADD REFERRED_BY_AGENCY_CODE COLUMN TO PROFILES TABLE & ALLOW PUBLIC SELECT
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS referred_by_agency_code TEXT DEFAULT NULL;

DROP POLICY IF EXISTS "profiles_select_policy" ON public.profiles;
CREATE POLICY "profiles_select_policy" ON public.profiles
    FOR SELECT TO public USING (true);


-- ------------------------------------------------------------------------------

-- 3. CREATE AGENCY_OTP_CODES TABLE FOR OTP AUTHENTICATION
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

CREATE INDEX IF NOT EXISTS idx_agency_otp_codes_email ON public.agency_otp_codes(email, created_at DESC);

ALTER TABLE public.agency_otp_codes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "agency_otp_codes_anon_policy" ON public.agency_otp_codes;
CREATE POLICY "agency_otp_codes_anon_policy" ON public.agency_otp_codes
    FOR ALL TO public USING (true) WITH CHECK (true);

-- ------------------------------------------------------------------------------

-- 4. FAIL-SAFE HANDLE_NEW_USER TRIGGER & MISSING PROFILE BACKFILL
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    user_role_val public.user_role := 'landlord';
    user_role_text TEXT := 'landlord';
BEGIN
    IF NEW.raw_user_meta_data->>'role' IS NOT NULL AND NEW.raw_user_meta_data->>'role' IN ('landlord', 'tenant', 'agency') THEN
        user_role_val := (NEW.raw_user_meta_data->>'role')::public.user_role;
        user_role_text := NEW.raw_user_meta_data->>'role';
    END IF;

    INSERT INTO public.profiles (
        id, 
        full_name, 
        role, 
        email, 
        active_role,
        utm_source,
        utm_medium,
        utm_campaign
    )
    VALUES (
        NEW.id,
        COALESCE(NULLIF(NEW.raw_user_meta_data->>'full_name', ''), NEW.email, 'Yeni Kullanıcı'),
        user_role_val,
        NEW.email,
        user_role_text,
        NEW.raw_user_meta_data->>'utm_source',
        NEW.raw_user_meta_data->>'utm_medium',
        NEW.raw_user_meta_data->>'utm_campaign'
    )
    ON CONFLICT (id) DO UPDATE
    SET full_name = COALESCE(EXCLUDED.full_name, public.profiles.full_name),
        email = COALESCE(EXCLUDED.email, public.profiles.email),
        utm_source = COALESCE(EXCLUDED.utm_source, public.profiles.utm_source),
        utm_medium = COALESCE(EXCLUDED.utm_medium, public.profiles.utm_medium),
        utm_campaign = COALESCE(EXCLUDED.utm_campaign, public.profiles.utm_campaign);
    RETURN NEW;
EXCEPTION WHEN OTHERS THEN
    -- Fallback insertion if meta_data parsing fails
    INSERT INTO public.profiles (id, full_name, role, email, active_role)
    VALUES (NEW.id, COALESCE(NEW.email, 'Yeni Kullanıcı'), 'landlord', NEW.email, 'landlord')
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- BACKFILL profiles for any auth.users missing a profile record
INSERT INTO public.profiles (id, full_name, role, email, active_role)
SELECT 
    au.id, 
    COALESCE(au.raw_user_meta_data->>'full_name', au.email, 'Kullanıcı'),
    'landlord'::public.user_role,
    au.email,
    'landlord'
FROM auth.users au
LEFT JOIN public.profiles p ON p.id = au.id
WHERE p.id IS NULL
ON CONFLICT (id) DO NOTHING;
