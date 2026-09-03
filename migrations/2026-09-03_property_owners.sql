-- Migration: Add property_owners table for multiple owners (individual and legal entity)
-- Target: Dev Supabase (thvbpifahvasyzmngpzp)

CREATE TABLE IF NOT EXISTS property_owners (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
  owner_type TEXT NOT NULL DEFAULT 'individual' CHECK (owner_type IN ('individual', 'company')),
  is_primary BOOLEAN NOT NULL DEFAULT false,
  ownership_percentage NUMERIC DEFAULT 100,

  -- Shared / Individual contact
  first_name TEXT,
  last_name TEXT,
  phone TEXT,
  secondary_contact TEXT,
  email TEXT,

  -- Individual ID details
  id_document_number TEXT,
  id_details TEXT,

  -- Legal Entity / Company details
  company_name TEXT,
  registered_address TEXT,
  pib TEXT, -- Tax Identification Number (PIB)
  registration_number TEXT, -- Matični broj
  representative_name TEXT, -- First and last name of legal representative
  representative_id_number TEXT,
  representative_id_details TEXT,

  -- Supporting Documents (JSONB array)
  -- Structure: [{"type": "id_document"|"ownership_proof"|"power_of_attorney"|"other", "name": "...", "url": "...", "uploaded_at": "..."}]
  documents JSONB NOT NULL DEFAULT '[]'::jsonb,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_property_owners_property_id ON property_owners(property_id);
CREATE INDEX IF NOT EXISTS idx_property_owners_email ON property_owners(LOWER(email));

-- Enable Row Level Security
ALTER TABLE property_owners ENABLE ROW LEVEL SECURITY;

-- Policy: Agencies can view and manage owners of their properties
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'property_owners' AND policyname = 'agency_manage_property_owners'
  ) THEN
    CREATE POLICY agency_manage_property_owners ON property_owners
      FOR ALL TO authenticated
      USING (
        EXISTS (
          SELECT 1 FROM properties p
          WHERE p.id = property_owners.property_id
          AND p.agency_id = auth.uid()
        )
      )
      WITH CHECK (
        EXISTS (
          SELECT 1 FROM properties p
          WHERE p.id = property_owners.property_id
          AND p.agency_id = auth.uid()
        )
      );
  END IF;
END $$;

-- Policy: Landlords can view owners of their property or if their email matches
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'property_owners' AND policyname = 'landlords_view_property_owners'
  ) THEN
    CREATE POLICY landlords_view_property_owners ON property_owners
      FOR SELECT TO authenticated
      USING (
        LOWER(email) = LOWER(auth.jwt()->>'email')
        OR EXISTS (
          SELECT 1 FROM properties p
          WHERE p.id = property_owners.property_id
          AND p.landlord_id = auth.uid()
        )
      );
  END IF;
END $$;
