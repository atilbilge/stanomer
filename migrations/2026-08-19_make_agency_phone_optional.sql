-- Migration: Make phone column optional in agency_referral_partners table
-- Date: 2026-08-19

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'agency_referral_partners' AND column_name = 'phone' AND is_nullable = 'NO'
    ) THEN
        ALTER TABLE public.agency_referral_partners ALTER COLUMN phone DROP NOT NULL;
    END IF;
END $$;
