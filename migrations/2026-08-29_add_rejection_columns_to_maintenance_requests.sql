-- ==============================================================================
-- Migration: Add rejection columns to maintenance_requests
-- Date: 2026-08-29
-- Description: Adds rejection_reason and rejected_by columns to support 
--              rejection and agency approval workflow for financial declarations.
-- ==============================================================================

DO $$
BEGIN
  -- 1. Add rejection_reason column if not exists
  IF NOT EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_schema = 'public' 
      AND table_name = 'maintenance_requests' 
      AND column_name = 'rejection_reason'
  ) THEN
    ALTER TABLE public.maintenance_requests 
    ADD COLUMN rejection_reason TEXT DEFAULT NULL;
  END IF;

  -- 2. Add rejected_by column if not exists
  IF NOT EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_schema = 'public' 
      AND table_name = 'maintenance_requests' 
      AND column_name = 'rejected_by'
  ) THEN
    ALTER TABLE public.maintenance_requests 
    ADD COLUMN rejected_by UUID REFERENCES auth.users(id) ON DELETE SET NULL DEFAULT NULL;
  END IF;
END $$;
