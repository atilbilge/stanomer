-- ==============================================================================
-- Migration: 2026-11-17_agency_demo_consents.sql
-- Description: ZZPL (Serbian Data Protection Law) consent and audit log for agency demo
-- Environment: DEV Supabase (thvbpifahvasyzmngpzp) ONLY
-- Rule: Never execute on production DB (ustcsvvkzsmsgzbptvpm)
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.agency_demo_consents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL,
  agency_name TEXT NOT NULL,
  phone TEXT,
  city TEXT,
  marketing_consent BOOLEAN NOT NULL DEFAULT FALSE,
  consent_text_key TEXT NOT NULL DEFAULT 'consent.marketing',
  consent_text_version TEXT NOT NULL DEFAULT 'v1.0',
  shown_locale TEXT NOT NULL DEFAULT 'sr',
  ip_address TEXT,
  user_agent TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_agency_demo_consents_email ON public.agency_demo_consents(email);
CREATE INDEX IF NOT EXISTS idx_agency_demo_consents_created_at ON public.agency_demo_consents(created_at);

ALTER TABLE public.agency_demo_consents ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'agency_demo_consents' AND policyname = 'agency_demo_consents_public_insert'
  ) THEN
    CREATE POLICY "agency_demo_consents_public_insert" ON public.agency_demo_consents FOR INSERT WITH CHECK (true);
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'agency_demo_consents' AND policyname = 'agency_demo_consents_authenticated_select'
  ) THEN
    CREATE POLICY "agency_demo_consents_authenticated_select" ON public.agency_demo_consents FOR SELECT USING (true);
  END IF;
END $$;

