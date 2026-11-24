-- ==============================================================================
-- MIGRATION: 2026-11-16_agency_leads_crm.sql
-- DESCRIPTION: Creates public.agency_leads table for Agency Showcase & Backoffice CRM
-- IDEMPOTENT: Safe to run multiple times without data loss.
-- TARGET: Dev Database ONLY (Never run directly on Production Database)
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.agency_leads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agency_id TEXT NOT NULL,
    lead_type TEXT NOT NULL DEFAULT 'owner_consignment' CHECK (lead_type IN ('owner_consignment', 'viewing_request', 'general_inquiry')),
    status TEXT NOT NULL DEFAULT 'new' CHECK (status IN ('new', 'contacted', 'evaluation', 'viewing_scheduled', 'offer_made', 'contract_signed', 'converted', 'archived')),
    client_name TEXT NOT NULL,
    client_phone TEXT NOT NULL,
    client_email TEXT DEFAULT NULL,
    transaction_type TEXT DEFAULT 'prodaja' CHECK (transaction_type IN ('prodaja', 'izdavanje')),
    property_type TEXT DEFAULT 'apartment',
    location TEXT DEFAULT NULL,
    area_sqm NUMERIC(10,2) DEFAULT NULL,
    expected_price NUMERIC(12,2) DEFAULT NULL,
    currency TEXT NOT NULL DEFAULT 'EUR',
    notes TEXT DEFAULT NULL,
    listing_id UUID DEFAULT NULL REFERENCES public.listings(id) ON DELETE SET NULL,
    listing_title TEXT DEFAULT NULL,
    agent_notes TEXT DEFAULT NULL,
    comments JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS agency_leads_agency_id_idx ON public.agency_leads (agency_id);
CREATE INDEX IF NOT EXISTS agency_leads_status_idx ON public.agency_leads (status);
CREATE INDEX IF NOT EXISTS agency_leads_created_at_idx ON public.agency_leads (created_at DESC);

ALTER TABLE public.agency_leads ENABLE ROW LEVEL SECURITY;

-- Allow showcase visitors (anon) to submit leads
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'agency_leads' AND policyname = 'allow_anon_insert_agency_leads'
    ) THEN
        CREATE POLICY allow_anon_insert_agency_leads ON public.agency_leads
            FOR INSERT
            TO anon, authenticated
            WITH CHECK (true);
    END IF;
END $$;

-- Allow agency owners to read and manage their leads
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'agency_leads' AND policyname = 'allow_agency_select_leads'
    ) THEN
        CREATE POLICY allow_agency_select_leads ON public.agency_leads
            FOR SELECT
            TO authenticated
            USING (agency_id = auth.uid()::text OR agency_id = 'demo');
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'agency_leads' AND policyname = 'allow_agency_update_leads'
    ) THEN
        CREATE POLICY allow_agency_update_leads ON public.agency_leads
            FOR UPDATE
            TO authenticated
            USING (agency_id = auth.uid()::text OR agency_id = 'demo')
            WITH CHECK (agency_id = auth.uid()::text OR agency_id = 'demo');
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'agency_leads' AND policyname = 'allow_agency_delete_leads'
    ) THEN
        CREATE POLICY allow_agency_delete_leads ON public.agency_leads
            FOR DELETE
            TO authenticated
            USING (agency_id = auth.uid()::text OR agency_id = 'demo');
    END IF;
END $$;

