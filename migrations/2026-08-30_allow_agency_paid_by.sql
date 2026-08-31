-- ==============================================================================
-- Migration: Allow 'agency' in maintenance_requests.paid_by CHECK constraint
-- Target Database: DEV ONLY (thvbpifahvasyzmngpzp)
-- Date: 2026-08-30
-- Description:
--   Updates the CHECK constraint on public.maintenance_requests(paid_by)
--   to include 'agency' alongside 'tenant' and 'landlord'.
-- ==============================================================================

DO $$
BEGIN
    ALTER TABLE public.maintenance_requests DROP CONSTRAINT IF EXISTS maintenance_requests_paid_by_check;
    ALTER TABLE public.maintenance_requests ADD CONSTRAINT maintenance_requests_paid_by_check 
        CHECK (paid_by IS NULL OR paid_by IN ('tenant', 'landlord', 'agency'));
END $$;
