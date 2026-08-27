-- ==============================================================================
-- Migration: Update Maintenance Operational and Financial Payment Statuses
-- Target Database: DEV ONLY (thvbpifahvasyzmngpzp)
-- Date: 2026-08-26
-- Description:
--   1. Normalizes payment_status values:
--      - 'pending_review'  : Inceleme Bekliyor (Default when tenant/landlord submits cost/invoice)
--      - 'pending_payment' : Odeme Bekliyor (Approved by manager; assigned to debtor)
--      - 'paid'            : Odendi (Payment confirmed by manager)
--      - 'rejected'        : Reddedildi (Invoice/cost rejected by manager)
--   2. Updates check constraints idempotently and cleanly.
-- ==============================================================================

DO $$
BEGIN
    -- 1. Drop existing constraint first so existing/transitioning rows don't violate it
    ALTER TABLE public.maintenance_requests 
    DROP CONSTRAINT IF EXISTS maintenance_requests_payment_status_check;

    -- 2. Migrate any existing 'pending', NULL, or unrecognized status rows to 'pending_review'
    UPDATE public.maintenance_requests 
    SET payment_status = 'pending_review' 
    WHERE payment_status IS NULL 
       OR payment_status NOT IN ('pending_review', 'pending_payment', 'paid', 'rejected');

    -- 3. Add updated 4-tier constraint
    ALTER TABLE public.maintenance_requests
    ADD CONSTRAINT maintenance_requests_payment_status_check 
    CHECK (payment_status IN ('pending_review', 'pending_payment', 'paid', 'rejected'));

    -- 4. Set default value to 'pending_review'
    ALTER TABLE public.maintenance_requests
    ALTER COLUMN payment_status SET DEFAULT 'pending_review';
END $$;

