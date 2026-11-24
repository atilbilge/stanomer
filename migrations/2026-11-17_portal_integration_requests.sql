-- ============================================================================
-- Migration: 2026-11-17_portal_integration_requests.sql
-- Description: Table for agency concierge portal integration requests (Nekretnine.rs, Sasomange, etc.)
-- Target: DEV ONLY (thvbpifahvasyzmngpzp)
-- Zero Impact on Production: Do NOT run on production DB (ustcsvvkzsmsgzbptvpm)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.portal_integration_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agency_id TEXT NOT NULL,
    agency_name TEXT NOT NULL,
    portal_name TEXT NOT NULL,
    contact_phone TEXT,
    contact_email TEXT,
    portal_account_ref TEXT,
    notes TEXT,
    status TEXT NOT NULL DEFAULT 'pending',
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_portal_int_req_agency_id ON public.portal_integration_requests(agency_id);
CREATE INDEX IF NOT EXISTS idx_portal_int_req_portal ON public.portal_integration_requests(portal_name);
CREATE INDEX IF NOT EXISTS idx_portal_int_req_status ON public.portal_integration_requests(status);

-- Enable RLS
ALTER TABLE public.portal_integration_requests ENABLE ROW LEVEL SECURITY;

-- Idempotent RLS Policies
DO $$
BEGIN
    DROP POLICY IF EXISTS "Agencies can insert integration requests" ON public.portal_integration_requests;
    DROP POLICY IF EXISTS "Agencies can view their own integration requests" ON public.portal_integration_requests;
END $$;

CREATE POLICY "Agencies can insert integration requests"
    ON public.portal_integration_requests
    FOR INSERT
    TO public
    WITH CHECK (true);

CREATE POLICY "Agencies can view their own integration requests"
    ON public.portal_integration_requests
    FOR SELECT
    TO public
    USING (
        auth.uid()::text = agency_id
        OR agency_id = 'demo'
        OR auth.role() = 'service_role'
    );

