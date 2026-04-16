-- 1. Enable Realtime for key tables
-- We use a DO block to safely add tables to the publication only if they aren't already there.
DO $$
BEGIN
    -- Add public.contracts to realtime
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'contracts'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.contracts;
    END IF;

    -- Add public.rent_payments to realtime
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'rent_payments'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.rent_payments;
    END IF;

    -- Add public.activity_logs to realtime
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'activity_logs'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.activity_logs;
    END IF;
END $$;

-- 2. Add 'revision_requested' to contract_status enum
-- NOTE: In Postgres, you cannot add enum values inside a transaction block in some versions,
-- so we run it outside if necessary. However, usually inside a script is fine.
-- If it fails, run it separately in the SQL Editor.
ALTER TYPE contract_status ADD VALUE IF NOT EXISTS 'revision_requested';
