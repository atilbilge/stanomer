-- Migration: 2026-08-29_add_agency_approval_statuses_to_maintenance_requests.sql
-- Description: Updates maintenance_requests_payment_status_check constraint to include 'pending_agency_approval' and 'pending_opposite_approval'.
-- Safe, idempotent, zero data-loss migration.

DO $$
BEGIN
    -- Drop the existing constraint if present
    ALTER TABLE public.maintenance_requests DROP CONSTRAINT IF EXISTS maintenance_requests_payment_status_check;

    -- Add the expanded constraint with the new agency approval intermediate statuses
    ALTER TABLE public.maintenance_requests ADD CONSTRAINT maintenance_requests_payment_status_check 
        CHECK (payment_status IN (
            'pending_review', 
            'pending_agency_approval', 
            'pending_opposite_approval', 
            'pending_payment', 
            'paid', 
            'rejected'
        ));
END $$;
