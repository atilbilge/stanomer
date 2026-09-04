-- Migration: Add ticket_number to maintenance_requests
-- Description: Adds a sequence and ticket_number column (e.g. 'MR-10001') to maintenance_requests for human-readable, database-backed tracking numbers.
-- Date: 2026-09-04

-- 1. Create sequence for ticket numbers starting at 10001
CREATE SEQUENCE IF NOT EXISTS public.maintenance_ticket_number_seq START WITH 10001;

-- 2. Add ticket_number column with sequence default
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_schema = 'public' 
      AND table_name = 'maintenance_requests' 
      AND column_name = 'ticket_number'
  ) THEN
    ALTER TABLE public.maintenance_requests 
    ADD COLUMN ticket_number TEXT DEFAULT ('MR-' || LPAD(nextval('public.maintenance_ticket_number_seq')::TEXT, 5, '0'));
    
    -- Populate existing rows that don't have a ticket_number yet
    UPDATE public.maintenance_requests 
    SET ticket_number = 'MR-' || LPAD(nextval('public.maintenance_ticket_number_seq')::TEXT, 5, '0')
    WHERE ticket_number IS NULL;

    -- Add unique constraint/index on ticket_number
    CREATE UNIQUE INDEX IF NOT EXISTS idx_maintenance_requests_ticket_number 
    ON public.maintenance_requests(ticket_number);
  END IF;
END $$;
