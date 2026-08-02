-- Missing columns & constraints for properties table
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS name TEXT;
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS default_deposit_currency TEXT DEFAULT 'EUR';
ALTER TABLE public.properties ALTER COLUMN title DROP NOT NULL;

-- Refresh PostgREST schema cache
NOTIFY pgrst, 'reload schema';
