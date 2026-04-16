-- Migration: Add dispute columns to rent_payments
-- Run this in the Supabase SQL Editor

ALTER TABLE public.rent_payments
ADD COLUMN IF NOT EXISTS dispute_reason TEXT,
ADD COLUMN IF NOT EXISTS disputed_at TIMESTAMPTZ;

-- Ensure status column allows 'disputed'
-- (In case there's a check constraint, we'll try to update it)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conrelid = 'public.rent_payments'::regclass 
        AND conname = 'rent_payments_status_check'
    ) THEN
        ALTER TABLE public.rent_payments DROP CONSTRAINT rent_payments_status_check;
        ALTER TABLE public.rent_payments ADD CONSTRAINT rent_payments_status_check 
        CHECK (status IN ('pending', 'declared', 'paid', 'disputed', 'rejected'));
    END IF;
END $$;
