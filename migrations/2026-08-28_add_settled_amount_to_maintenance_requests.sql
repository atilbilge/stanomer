-- Migration: Add settled_amount to maintenance_requests
-- Description: Adds settled_amount column to track partially settled/offset amounts on maintenance requests while preserving the original cost_amount.
-- Date: 2026-08-28

DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_schema = 'public' 
      AND table_name = 'maintenance_requests' 
      AND column_name = 'settled_amount'
  ) THEN
    ALTER TABLE public.maintenance_requests 
    ADD COLUMN settled_amount NUMERIC(10,2) DEFAULT 0.00;
  END IF;
END $$;
