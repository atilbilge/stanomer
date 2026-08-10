-- Migration: Create agency_demo_requests table for agency demo submissions
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
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Ensure columns exist if table was already created
ALTER TABLE public.agency_demo_requests ADD COLUMN IF NOT EXISTS verification_token UUID DEFAULT gen_random_uuid();
ALTER TABLE public.agency_demo_requests ADD COLUMN IF NOT EXISTS is_email_verified BOOLEAN DEFAULT FALSE;
ALTER TABLE public.agency_demo_requests ADD COLUMN IF NOT EXISTS token_expires_at TIMESTAMPTZ DEFAULT (now() + interval '24 hours');

-- Enable RLS
ALTER TABLE public.agency_demo_requests ENABLE ROW LEVEL SECURITY;

-- Allow anyone (anon + authenticated) to submit demo requests
DROP POLICY IF EXISTS "agency_demo_requests_insert_policy" ON public.agency_demo_requests;
CREATE POLICY "agency_demo_requests_insert_policy" ON public.agency_demo_requests
    FOR INSERT TO public WITH CHECK (true);

-- Allow anyone (anon + authenticated) to view/select demo requests
DROP POLICY IF EXISTS "agency_demo_requests_select_policy" ON public.agency_demo_requests;
CREATE POLICY "agency_demo_requests_select_policy" ON public.agency_demo_requests
    FOR SELECT TO public USING (true);

-- RPC Function: Verify agency demo token
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

