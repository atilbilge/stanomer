-- 1. Add contract_url to contracts table
ALTER TABLE public.contracts 
ADD COLUMN IF NOT EXISTS contract_url TEXT;

-- 2. Remove redundant default fields from properties table
-- We keep them for now but they won't be used by the app.
-- To fully remove:
ALTER TABLE public.properties 
DROP COLUMN IF EXISTS default_start_date,
DROP COLUMN IF EXISTS default_end_date,
DROP COLUMN IF EXISTS default_contract_url;
