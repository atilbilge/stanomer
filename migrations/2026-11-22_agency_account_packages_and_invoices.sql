-- Migration: 2026-11-22_agency_account_packages_and_invoices.sql
-- Description: Adds subscription packages and module access columns to profiles, and creates agency_invoices table.
-- Stanomer 2 Core Modules: 'portfolio_distribution' and 'property_lease_management'
-- Targets: Dev Supabase (thvbpifahvasyzmngpzp). Idempotent & safe.

DO $$
BEGIN
    -- 1. Add subscription and active module columns to public.profiles
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'subscription_plan'
    ) THEN
        ALTER TABLE public.profiles ADD COLUMN subscription_plan TEXT DEFAULT 'Property & Lease Management';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'subscription_status'
    ) THEN
        ALTER TABLE public.profiles ADD COLUMN subscription_status TEXT DEFAULT 'active';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'active_modules'
    ) THEN
        ALTER TABLE public.profiles ADD COLUMN active_modules TEXT[] DEFAULT ARRAY['property_lease_management']::TEXT[];
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'monthly_fee'
    ) THEN
        ALTER TABLE public.profiles ADD COLUMN monthly_fee NUMERIC(10, 2) DEFAULT 0.00;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'billing_currency'
    ) THEN
        ALTER TABLE public.profiles ADD COLUMN billing_currency TEXT DEFAULT 'EUR';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'next_billing_date'
    ) THEN
        ALTER TABLE public.profiles ADD COLUMN next_billing_date DATE DEFAULT NULL;
    END IF;
END $$;

-- 2. Create public.agency_invoices table
CREATE TABLE IF NOT EXISTS public.agency_invoices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agency_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    invoice_number TEXT NOT NULL,
    period TEXT NOT NULL,
    amount NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    currency TEXT NOT NULL DEFAULT 'EUR',
    status TEXT NOT NULL DEFAULT 'paid', -- 'paid', 'pending', 'overdue'
    due_date DATE,
    paid_at TIMESTAMPTZ,
    pdf_url TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Index for quick lookup by agency_id
CREATE INDEX IF NOT EXISTS agency_invoices_agency_id_idx ON public.agency_invoices(agency_id);
CREATE INDEX IF NOT EXISTS agency_invoices_status_idx ON public.agency_invoices(status);

-- Enable RLS
ALTER TABLE public.agency_invoices ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DROP POLICY IF EXISTS "agency_invoices_select_policy" ON public.agency_invoices;
CREATE POLICY "agency_invoices_select_policy" ON public.agency_invoices
    FOR SELECT TO authenticated
    USING (agency_id = auth.uid() OR auth.role() = 'service_role');

DROP POLICY IF EXISTS "agency_invoices_admin_all_policy" ON public.agency_invoices;
CREATE POLICY "agency_invoices_admin_all_policy" ON public.agency_invoices
    FOR ALL TO service_role
    USING (true)
    WITH CHECK (true);
