-- ==============================================================================
-- STANOMER DATABASE MIGRATION - PORTAL FEED ACCESS LOGS
-- Date: 2026-11-16
-- Target: Dev Supabase (thvbpifahvasyzmngpzp) — Ready for Production Promotion
-- Description:
--   Creates `public.portal_feed_logs` table for tracking portal crawler hits
--   (4zida, Halo Oglasi, Sasomange, Nekretnine.rs) with IP, User-Agent,
--   listing count, HTTP status, and latency.
--   Enables agencies to view their synchronization health and last sync timestamp.
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.portal_feed_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agency_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    directory_agency_id BIGINT REFERENCES public.agencies(id) ON DELETE SET NULL,
    portal TEXT NOT NULL,
    ip_address TEXT DEFAULT NULL,
    user_agent TEXT DEFAULT NULL,
    listing_count INTEGER NOT NULL DEFAULT 0,
    status_code INTEGER NOT NULL DEFAULT 200,
    duration_ms INTEGER DEFAULT NULL,
    error_message TEXT DEFAULT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS portal_feed_logs_agency_portal_idx
    ON public.portal_feed_logs (agency_id, portal, created_at DESC);

CREATE INDEX IF NOT EXISTS portal_feed_logs_created_at_idx
    ON public.portal_feed_logs (created_at DESC);

ALTER TABLE public.portal_feed_logs ENABLE ROW LEVEL SECURITY;

-- Allow public API feed route to log crawler hits
DROP POLICY IF EXISTS "allow_insert_portal_feed_logs" ON public.portal_feed_logs;
CREATE POLICY "allow_insert_portal_feed_logs" ON public.portal_feed_logs
    FOR INSERT TO public
    WITH CHECK (true);

-- Allow authenticated agencies to view their own portal feed logs
DROP POLICY IF EXISTS "agency_view_own_portal_feed_logs" ON public.portal_feed_logs;
CREATE POLICY "agency_view_own_portal_feed_logs" ON public.portal_feed_logs
    FOR SELECT TO authenticated
    USING (agency_id = auth.uid());

