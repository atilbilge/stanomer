-- ==============================================================================
-- Migration: 2026-11-17_agency_demo_sessions.sql
-- Description: Ephemeral 48-hour personalized agency demo sessions with magic link
-- Environment: DEV Supabase (thvbpifahvasyzmngpzp) ONLY
-- Rule: Never execute on production DB (ustcsvvkzsmsgzbptvpm)
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.agency_demo_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  token TEXT UNIQUE NOT NULL,
  agency_name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT,
  city TEXT DEFAULT 'Beograd',
  expires_at TIMESTAMPTZ NOT NULL,
  last_accessed_at TIMESTAMPTZ DEFAULT now(),
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_agency_demo_sessions_token ON public.agency_demo_sessions(token);
CREATE INDEX IF NOT EXISTS idx_agency_demo_sessions_email ON public.agency_demo_sessions(email);

ALTER TABLE public.agency_demo_sessions ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'agency_demo_sessions' AND policyname = 'agency_demo_sessions_public_insert'
  ) THEN
    CREATE POLICY "agency_demo_sessions_public_insert" ON public.agency_demo_sessions FOR INSERT WITH CHECK (true);
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'agency_demo_sessions' AND policyname = 'agency_demo_sessions_public_select'
  ) THEN
    CREATE POLICY "agency_demo_sessions_public_select" ON public.agency_demo_sessions FOR SELECT USING (true);
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'agency_demo_sessions' AND policyname = 'agency_demo_sessions_public_update'
  ) THEN
    CREATE POLICY "agency_demo_sessions_public_update" ON public.agency_demo_sessions FOR UPDATE USING (true);
  END IF;
END $$;

