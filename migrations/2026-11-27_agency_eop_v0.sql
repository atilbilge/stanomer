-- ==============================================================================
-- Migration: 2026-11-27_agency_eop_v0.sql
-- Description:
--   Module-Independent EOP (Evidencija o posredovanju) & Agency Clients v0.
--   - Adds official agency registry columns to public.profiles (nullable).
--   - Creates public.agency_clients (unified natural/legal client directory).
--   - Adds optional client_id FK (ON DELETE SET NULL) to public.listings and
--     public.property_owners.
--   - Creates public.eop_records with immutable snapshot columns, automatic
--     atomic yearly sequential numbering (redni_broj: 1/2026, 2/2026...),
--     and hard-delete protection (no DELETE RLS policy for authenticated users).
--   - Updates public.clear_agency_demo_data() to clean up eop_records and
--     agency_clients in demo/sandbox resets.
-- Target: Dev Supabase (nbcbfmhztnnhfnapvaet) ONLY — NEVER run on Production!
-- Idempotent: Yes
-- ==============================================================================

BEGIN;

-- 1. Additive official agency registry columns on public.profiles
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS registar_posrednika_no TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS pib TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS maticni_broj TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS official_address TEXT;

-- 2. Create public.agency_clients (reusable natural/legal person directory per agency)
CREATE TABLE IF NOT EXISTS public.agency_clients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agency_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    party_type TEXT NOT NULL DEFAULT 'individual' CHECK (party_type IN ('individual', 'company')),
    full_name TEXT NOT NULL,
    jmbg_pib TEXT,
    maticni_broj TEXT,
    address TEXT,
    phone TEXT,
    email TEXT,
    notes TEXT,
    created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_agency_clients_agency_id ON public.agency_clients(agency_id);
CREATE INDEX IF NOT EXISTS idx_agency_clients_jmbg_pib ON public.agency_clients(agency_id, jmbg_pib);

ALTER TABLE public.agency_clients ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Agency members can view agency clients" ON public.agency_clients;
CREATE POLICY "Agency members can view agency clients" ON public.agency_clients
    FOR SELECT TO authenticated
    USING (public.is_agency_member(agency_id, auth.uid()));

DROP POLICY IF EXISTS "Agency members can insert agency clients" ON public.agency_clients;
CREATE POLICY "Agency members can insert agency clients" ON public.agency_clients
    FOR INSERT TO authenticated
    WITH CHECK (public.is_agency_member(agency_id, auth.uid()));

DROP POLICY IF EXISTS "Agency members can update agency clients" ON public.agency_clients;
CREATE POLICY "Agency members can update agency clients" ON public.agency_clients
    FOR UPDATE TO authenticated
    USING (public.is_agency_member(agency_id, auth.uid()))
    WITH CHECK (public.is_agency_member(agency_id, auth.uid()));

DROP POLICY IF EXISTS "Agency admins can delete agency clients" ON public.agency_clients;
CREATE POLICY "Agency admins can delete agency clients" ON public.agency_clients
    FOR DELETE TO authenticated
    USING (agency_id = auth.uid());

GRANT SELECT, INSERT, UPDATE, DELETE ON public.agency_clients TO authenticated, service_role;

-- 3. Additive optional client_id links on listings & property_owners (ON DELETE SET NULL)
DO $$
BEGIN
    IF to_regclass('public.listings') IS NOT NULL THEN
        ALTER TABLE public.listings
            ADD COLUMN IF NOT EXISTS client_id UUID REFERENCES public.agency_clients(id) ON DELETE SET NULL;
        CREATE INDEX IF NOT EXISTS idx_listings_client_id ON public.listings(client_id);
    END IF;

    IF to_regclass('public.property_owners') IS NOT NULL THEN
        ALTER TABLE public.property_owners
            ADD COLUMN IF NOT EXISTS client_id UUID REFERENCES public.agency_clients(id) ON DELETE SET NULL;
        CREATE INDEX IF NOT EXISTS idx_property_owners_client_id ON public.property_owners(client_id);
    END IF;
END $$;

-- 4. Create public.eop_records (Official Mediation Ledger - Evidencija o posredovanju)
CREATE TABLE IF NOT EXISTS public.eop_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agency_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,

    -- Sequential legal ledger numbering (auto-assigned via trigger)
    sequence_year INTEGER NOT NULL DEFAULT EXTRACT(YEAR FROM CURRENT_DATE)::INTEGER,
    sequence_number INTEGER NOT NULL,
    redni_broj TEXT NOT NULL,

    -- Mediation contract (Ugovor o posredovanju) details — NOT UNIQUE (umbrella contracts allowed)
    mediation_contract_no TEXT NOT NULL,
    mediation_contract_date DATE NOT NULL DEFAULT CURRENT_DATE,
    contract_valid_until DATE,
    is_exclusive BOOLEAN NOT NULL DEFAULT FALSE,
    client_role TEXT NOT NULL DEFAULT 'landlord' CHECK (client_role IN ('seller', 'buyer', 'landlord', 'tenant')),
    transaction_type TEXT NOT NULL DEFAULT 'izdavanje' CHECK (transaction_type IN ('prodaja', 'izdavanje')),
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'realized', 'cancelled')),
    cancellation_reason TEXT,

    -- Optional non-cascading system references (never delete EOP rows when source objects are removed)
    client_id UUID REFERENCES public.agency_clients(id) ON DELETE SET NULL,
    listing_id UUID REFERENCES public.listings(id) ON DELETE SET NULL,
    property_id UUID REFERENCES public.properties(id) ON DELETE SET NULL,
    lease_contract_id UUID REFERENCES public.contracts(id) ON DELETE SET NULL,

    -- Immutable legal snapshots at time of entry
    client_type TEXT NOT NULL DEFAULT 'individual' CHECK (client_type IN ('individual', 'company')),
    client_name_snapshot TEXT NOT NULL,
    client_jmbg_pib_snapshot TEXT,
    client_address_snapshot TEXT,
    client_phone_snapshot TEXT,
    client_email_snapshot TEXT,

    property_type_snapshot TEXT,
    property_address_snapshot TEXT NOT NULL,
    property_specs_snapshot TEXT,

    -- Financial & realization terms
    asking_price NUMERIC(12,2),
    agreed_price NUMERIC(12,2),
    currency TEXT NOT NULL DEFAULT 'EUR',
    commission_type TEXT NOT NULL DEFAULT 'percent' CHECK (commission_type IN ('percent', 'fixed')),
    commission_value NUMERIC(12,2),
    commission_currency TEXT DEFAULT 'EUR',
    realized_at DATE,
    invoice_ref TEXT,
    contract_pdf_url TEXT,
    notes TEXT,

    created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT eop_records_agency_year_seq_unique UNIQUE (agency_id, sequence_year, sequence_number)
);

CREATE INDEX IF NOT EXISTS idx_eop_records_agency_year ON public.eop_records(agency_id, sequence_year DESC, sequence_number DESC);
CREATE INDEX IF NOT EXISTS idx_eop_records_listing_id ON public.eop_records(listing_id);
CREATE INDEX IF NOT EXISTS idx_eop_records_property_id ON public.eop_records(property_id);
CREATE INDEX IF NOT EXISTS idx_eop_records_lease_contract_id ON public.eop_records(lease_contract_id);
CREATE INDEX IF NOT EXISTS idx_eop_records_client_id ON public.eop_records(client_id);
CREATE INDEX IF NOT EXISTS idx_eop_records_status ON public.eop_records(agency_id, status);

-- 5. Atomic yearly sequential number trigger for eop_records
CREATE OR REPLACE FUNCTION public.assign_eop_sequence_number()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_year INTEGER;
    v_next_seq INTEGER;
BEGIN
    v_year := COALESCE(NEW.sequence_year, EXTRACT(YEAR FROM COALESCE(NEW.mediation_contract_date, CURRENT_DATE))::INTEGER);
    NEW.sequence_year := v_year;

    -- Serialize sequence assignment per (agency_id, year) within the transaction
    PERFORM pg_advisory_xact_lock(hashtext(NEW.agency_id::text || ':' || v_year::text));

    IF NEW.sequence_number IS NULL OR NEW.sequence_number <= 0 THEN
        SELECT COALESCE(MAX(sequence_number), 0) + 1
        INTO v_next_seq
        FROM public.eop_records
        WHERE agency_id = NEW.agency_id
          AND sequence_year = v_year;

        NEW.sequence_number := v_next_seq;
    END IF;

    NEW.redni_broj := NEW.sequence_number::text || '/' || v_year::text;
    NEW.updated_at := now();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_assign_eop_sequence_number ON public.eop_records;
CREATE TRIGGER trg_assign_eop_sequence_number
    BEFORE INSERT ON public.eop_records
    FOR EACH ROW
    EXECUTE FUNCTION public.assign_eop_sequence_number();

-- Auto-update updated_at on UPDATE and prevent tampering with sequence fields
CREATE OR REPLACE FUNCTION public.protect_eop_sequence_on_update()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.sequence_year := OLD.sequence_year;
    NEW.sequence_number := OLD.sequence_number;
    NEW.redni_broj := OLD.redni_broj;
    NEW.updated_at := now();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_protect_eop_sequence_on_update ON public.eop_records;
CREATE TRIGGER trg_protect_eop_sequence_on_update
    BEFORE UPDATE ON public.eop_records
    FOR EACH ROW
    EXECUTE FUNCTION public.protect_eop_sequence_on_update();

-- 6. RLS for eop_records (NO DELETE policy for authenticated users — use status = 'cancelled' / storno)
ALTER TABLE public.eop_records ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Agency members can view eop records" ON public.eop_records;
CREATE POLICY "Agency members can view eop records" ON public.eop_records
    FOR SELECT TO authenticated
    USING (public.is_agency_member(agency_id, auth.uid()));

DROP POLICY IF EXISTS "Agency members can insert eop records" ON public.eop_records;
CREATE POLICY "Agency members can insert eop records" ON public.eop_records
    FOR INSERT TO authenticated
    WITH CHECK (public.is_agency_member(agency_id, auth.uid()));

DROP POLICY IF EXISTS "Agency members can update eop records" ON public.eop_records;
CREATE POLICY "Agency members can update eop records" ON public.eop_records
    FOR UPDATE TO authenticated
    USING (public.is_agency_member(agency_id, auth.uid()))
    WITH CHECK (public.is_agency_member(agency_id, auth.uid()));

GRANT SELECT, INSERT, UPDATE ON public.eop_records TO authenticated;
GRANT ALL ON public.eop_records TO service_role;

-- 7. Update clear_agency_demo_data() so demo sandbox resets also clean EOP & agency_clients
CREATE OR REPLACE FUNCTION public.clear_agency_demo_data(p_agency_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_property_ids UUID[];
    v_contract_ids UUID[];
    v_request_ids UUID[];
    v_listing_ids UUID[];
    v_demo_user_ids UUID[];
    v_agency_short TEXT;
    v_prop_count INT := 0;
    v_listing_count INT := 0;
    v_lead_count INT := 0;
    v_eop_count INT := 0;
BEGIN
    v_agency_short := substring(p_agency_id::text from 1 for 8);

    -- 0. Compliance / EOP & Agency Clients cleanup
    IF to_regclass('public.eop_records') IS NOT NULL THEN
        DELETE FROM public.eop_records WHERE agency_id = p_agency_id;
        GET DIAGNOSTICS v_eop_count = ROW_COUNT;
    END IF;

    -- 1. Property & Lease Management tables
    SELECT ARRAY_AGG(id) INTO v_property_ids
    FROM public.properties
    WHERE agency_id = p_agency_id;

    IF v_property_ids IS NOT NULL AND array_length(v_property_ids, 1) > 0 THEN
        v_prop_count := array_length(v_property_ids, 1);

        SELECT ARRAY_AGG(id) INTO v_contract_ids
        FROM public.contracts
        WHERE property_id = ANY(v_property_ids) OR agency_id = p_agency_id;

        SELECT ARRAY_AGG(id) INTO v_request_ids
        FROM public.maintenance_requests
        WHERE property_id = ANY(v_property_ids);

        IF v_request_ids IS NOT NULL THEN
            DELETE FROM public.maintenance_messages WHERE request_id = ANY(v_request_ids);
            DELETE FROM public.maintenance_charges WHERE maintenance_request_id = ANY(v_request_ids);
        END IF;

        DELETE FROM public.activity_logs WHERE property_id = ANY(v_property_ids);
        DELETE FROM public.maintenance_requests WHERE property_id = ANY(v_property_ids);
        DELETE FROM public.rent_payments WHERE property_id = ANY(v_property_ids);

        IF to_regclass('public.property_owners') IS NOT NULL THEN
            DELETE FROM public.property_owners WHERE property_id = ANY(v_property_ids);
        END IF;
        IF to_regclass('public.invitations') IS NOT NULL THEN
            DELETE FROM public.invitations WHERE property_id = ANY(v_property_ids);
        END IF;

        DELETE FROM public.contracts WHERE property_id = ANY(v_property_ids) OR agency_id = p_agency_id;
        DELETE FROM public.properties WHERE id = ANY(v_property_ids);
    END IF;

    -- 2. Portfolio & Distribution tables (listings, listing_images, agency_leads)
    IF to_regclass('public.listings') IS NOT NULL THEN
        SELECT ARRAY_AGG(id) INTO v_listing_ids
        FROM public.listings
        WHERE agency_id = p_agency_id;

        IF v_listing_ids IS NOT NULL AND array_length(v_listing_ids, 1) > 0 THEN
            v_listing_count := array_length(v_listing_ids, 1);
            IF to_regclass('public.listing_images') IS NOT NULL THEN
                DELETE FROM public.listing_images WHERE listing_id = ANY(v_listing_ids);
            END IF;
            DELETE FROM public.listings WHERE id = ANY(v_listing_ids);
        END IF;
    END IF;

    IF to_regclass('public.agency_leads') IS NOT NULL THEN
        DELETE FROM public.agency_leads WHERE agency_id = p_agency_id::text;
        GET DIAGNOSTICS v_lead_count = ROW_COUNT;
    END IF;

    IF to_regclass('public.agency_clients') IS NOT NULL THEN
        DELETE FROM public.agency_clients WHERE agency_id = p_agency_id;
    END IF;

    -- 3. Synthetic demo landlords & tenants
    SELECT ARRAY_AGG(id) INTO v_demo_user_ids
    FROM public.profiles
    WHERE email LIKE '%@demo.stanomer.local'
      AND (
          email LIKE ('%_' || v_agency_short || '_%@demo.stanomer.local')
          OR email LIKE ('%' || p_agency_id::text || '%')
      );

    IF v_demo_user_ids IS NOT NULL AND array_length(v_demo_user_ids, 1) > 0 THEN
        DELETE FROM public.profiles WHERE id = ANY(v_demo_user_ids);
        DELETE FROM auth.users WHERE id = ANY(v_demo_user_ids);
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'agency_id', p_agency_id,
        'deleted_properties_count', v_prop_count,
        'deleted_listings_count', v_listing_count,
        'deleted_leads_count', v_lead_count,
        'deleted_eop_count', v_eop_count
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.clear_agency_demo_data(UUID) TO anon, authenticated, service_role;

COMMIT;

NOTIFY pgrst, 'reload schema';
