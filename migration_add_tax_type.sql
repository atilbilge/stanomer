-- Migration to add tax_type to properties and contracts
DO $$ BEGIN
    CREATE TYPE tax_type AS ENUM ('included', 'added');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS tax_type tax_type DEFAULT 'included';
ALTER TABLE public.contracts ADD COLUMN IF NOT EXISTS tax_type tax_type DEFAULT 'included';
