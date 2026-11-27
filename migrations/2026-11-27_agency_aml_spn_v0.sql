-- ==============================================================================
-- Migration: 2026-11-27_agency_aml_spn_v0.sql
-- Description:
--   Faz 2: Module-Independent AML / SPN (ZSPNFT) Compliance Module v0.
--   - Adds optional compliance officer columns (aml_officer_name, aml_deputy_name)
--     to public.profiles.
--   - Creates public.aml_records (Upitnik za stranku, deterministic risk scoring,
--     atomic yearly reference numbering AML-1/2026, 10-year statutory archive lock).
--   - Creates public.aml_documents (metadata for private KYC/AML attachments).
--   - Creates private storage bucket `aml-documents` (public = false, 10 MB limit)
--     with strict agency-scoped path RLS and 10-year archive delete protection.
--   - Enforces DB-level immutability triggers for locked records & attachments.
--   - Updates public.clear_agency_demo_data() with guarded is_demo-only cleanup.
-- Target: Dev Supabase (nbcbfmhztnnhfnapvaet) ONLY — NEVER run on Production!
-- Idempotent: Yes
-- ==============================================================================

BEGIN;

-- 1. Additive compliance officer columns on public.profiles
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS aml_officer_name TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS aml_deputy_name TEXT;

-- 2. Safe UUID parser helper (prevents cast exceptions on malformed storage paths)
CREATE OR REPLACE FUNCTION public.try_parse_uuid(p_text TEXT)
RETURNS UUID
LANGUAGE plpgsql
IMMUTABLE
AS $$
BEGIN
    IF p_text IS NULL OR p_text !~ '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$' THEN
        RETURN NULL;
    END IF;
    RETURN p_text::UUID;
END;
$$;

-- 3. Create public.aml_records (Upitnik, Risk Scoring & 10-Year Archive Lock)
CREATE TABLE IF NOT EXISTS public.aml_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agency_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,

    -- Atomic yearly reference number (AML-1/2026, AML-2/2026...)
    sequence_year INTEGER NOT NULL DEFAULT EXTRACT(YEAR FROM CURRENT_DATE)::INTEGER,
    sequence_number INTEGER NOT NULL,
    aml_ref_no TEXT NOT NULL,

    -- Optional non-cascading system links (never delete AML archive when source objects are removed)
    client_id UUID REFERENCES public.agency_clients(id) ON DELETE SET NULL,
    eop_record_id UUID REFERENCES public.eop_records(id) ON DELETE SET NULL,
    property_id UUID REFERENCES public.properties(id) ON DELETE SET NULL,
    listing_id UUID REFERENCES public.listings(id) ON DELETE SET NULL,
    superseded_by_id UUID REFERENCES public.aml_records(id) ON DELETE SET NULL,

    -- Immutable Party / KYC Snapshot (Fizičko lice / Pravno lice)
    party_type TEXT NOT NULL DEFAULT 'individual' CHECK (party_type IN ('individual', 'company')),
    client_name_snapshot TEXT NOT NULL,
    jmbg_pib_snapshot TEXT,
    maticni_broj_snapshot TEXT,
    id_doc_type TEXT CHECK (id_doc_type IS NULL OR id_doc_type IN ('licna_karta', 'pasos', 'boravisna', 'apr_izvod', 'other')),
    id_doc_number TEXT,
    id_doc_issuer TEXT,
    id_doc_expiry DATE,
    birth_date DATE,
    citizenship TEXT,
    residency_country TEXT DEFAULT 'RS',
    address_snapshot TEXT,
    phone_snapshot TEXT,
    email_snapshot TEXT,
    occupation_or_activity TEXT,

    -- PEP (Funkcioner) & UBO (Stvarni vlasnik) & Third-Party Representation
    is_pep BOOLEAN NOT NULL DEFAULT FALSE,
    pep_details TEXT,
    ubo_list JSONB NOT NULL DEFAULT '[]'::jsonb,
    ubo_unclear BOOLEAN NOT NULL DEFAULT FALSE,
    acts_on_behalf_of_third_party BOOLEAN NOT NULL DEFAULT FALSE,
    third_party_details TEXT,

    -- Transaction & Source of Funds (Poreklo novca)
    transaction_type TEXT NOT NULL DEFAULT 'prodaja' CHECK (transaction_type IN ('prodaja', 'izdavanje')),
    transaction_value_eur NUMERIC(14,2),
    transaction_date DATE NOT NULL DEFAULT CURRENT_DATE,
    payment_method TEXT NOT NULL DEFAULT 'bank_transfer' CHECK (payment_method IN ('bank_transfer', 'cash', 'mixed', 'crypto')),
    source_of_funds_category TEXT CHECK (
        source_of_funds_category IS NULL OR source_of_funds_category IN (
            'salary', 'savings', 'property_sale', 'loan', 'business', 'inheritance', 'other'
        )
    ),
    source_of_funds TEXT,
    purpose_of_relationship TEXT,
    high_risk_country_involved BOOLEAN NOT NULL DEFAULT FALSE,

    -- Deterministic Risk Assessment
    risk_score INTEGER NOT NULL DEFAULT 0 CHECK (risk_score >= 0 AND risk_score <= 100),
    risk_level TEXT NOT NULL DEFAULT 'low' CHECK (risk_level IN ('low', 'medium', 'high')),
    risk_factors JSONB NOT NULL DEFAULT '[]'::jsonb,
    enhanced_due_diligence_notes TEXT,
    next_review_at DATE,

    -- Lifecycle & 10-Year Statutory Archive Lock (ZSPNFT Art. 95)
    status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'approved', 'rejected', 'superseded')),
    is_locked BOOLEAN NOT NULL DEFAULT FALSE,
    locked_at TIMESTAMPTZ,
    locked_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    retention_until DATE,
    decision_notes TEXT,

    created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT aml_records_agency_year_seq_unique UNIQUE (agency_id, sequence_year, sequence_number)
);

CREATE INDEX IF NOT EXISTS idx_aml_records_agency_year ON public.aml_records(agency_id, sequence_year DESC, sequence_number DESC);
CREATE INDEX IF NOT EXISTS idx_aml_records_client_id ON public.aml_records(client_id);
CREATE INDEX IF NOT EXISTS idx_aml_records_eop_record_id ON public.aml_records(eop_record_id);
-- At most 1 draft and at most 1 finalized (approved/rejected) record per EOP; superseded revisions remain in archive
DROP INDEX IF EXISTS public.idx_aml_one_active_per_eop;
CREATE UNIQUE INDEX IF NOT EXISTS idx_aml_one_draft_per_eop
    ON public.aml_records(eop_record_id)
    WHERE eop_record_id IS NOT NULL AND status = 'draft';
CREATE UNIQUE INDEX IF NOT EXISTS idx_aml_one_final_per_eop
    ON public.aml_records(eop_record_id)
    WHERE eop_record_id IS NOT NULL AND status IN ('approved', 'rejected');
CREATE INDEX IF NOT EXISTS idx_aml_records_property_id ON public.aml_records(property_id);
CREATE INDEX IF NOT EXISTS idx_aml_records_listing_id ON public.aml_records(listing_id);
CREATE INDEX IF NOT EXISTS idx_aml_records_status_risk ON public.aml_records(agency_id, status, risk_level);
CREATE INDEX IF NOT EXISTS idx_aml_records_retention ON public.aml_records(agency_id, is_locked, retention_until);

-- 4. Create public.aml_documents (Private Bucket Attachment Metadata)
CREATE TABLE IF NOT EXISTS public.aml_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agency_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    aml_record_id UUID NOT NULL REFERENCES public.aml_records(id) ON DELETE CASCADE,
    doc_type TEXT NOT NULL DEFAULT 'id_card' CHECK (
        doc_type IN ('id_card', 'passport', 'apr_extract', 'ubo_declaration', 'source_of_funds', 'signed_upitnik', 'sanctions_check', 'other')
    ),
    file_name TEXT NOT NULL,
    storage_path TEXT NOT NULL,
    mime_type TEXT,
    file_size_bytes BIGINT,
    uploaded_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_aml_documents_record_id ON public.aml_documents(aml_record_id);
CREATE INDEX IF NOT EXISTS idx_aml_documents_agency_id ON public.aml_documents(agency_id);

-- 5. Triggers for atomic numbering & 10-year archive lock enforcement

-- 5a. Atomic yearly sequence number on INSERT
CREATE OR REPLACE FUNCTION public.assign_aml_sequence_number()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_year INTEGER;
    v_next_seq INTEGER;
BEGIN
    v_year := COALESCE(NEW.sequence_year, EXTRACT(YEAR FROM COALESCE(NEW.transaction_date, CURRENT_DATE))::INTEGER);
    NEW.sequence_year := v_year;

    PERFORM pg_advisory_xact_lock(hashtext('aml:' || NEW.agency_id::text || ':' || v_year::text));

    IF NEW.sequence_number IS NULL OR NEW.sequence_number <= 0 THEN
        SELECT COALESCE(MAX(sequence_number), 0) + 1
        INTO v_next_seq
        FROM public.aml_records
        WHERE agency_id = NEW.agency_id
          AND sequence_year = v_year;

        NEW.sequence_number := v_next_seq;
    END IF;

    NEW.aml_ref_no := 'AML-' || NEW.sequence_number::text || '/' || v_year::text;

    -- Always start unlocked on INSERT unless service_role explicitly seeds a locked record
    IF NEW.is_locked = TRUE THEN
        IF auth.uid() IS NOT NULL AND auth.uid() <> NEW.agency_id THEN
            RAISE EXCEPTION 'AML_ADMIN_REQUIRED: Only agency admin can lock an AML record';
        END IF;
        NEW.locked_at := COALESCE(NEW.locked_at, now());
        NEW.locked_by := COALESCE(NEW.locked_by, auth.uid());
        NEW.retention_until := COALESCE(NEW.retention_until, (COALESCE(NEW.transaction_date, CURRENT_DATE) + INTERVAL '10 years')::DATE);
    END IF;

    NEW.updated_at := now();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_assign_aml_sequence_number ON public.aml_records;
CREATE TRIGGER trg_assign_aml_sequence_number
    BEFORE INSERT ON public.aml_records
    FOR EACH ROW
    EXECUTE FUNCTION public.assign_aml_sequence_number();

-- 5b. Immutability & 10-Year Archive Lock on UPDATE/DELETE of public.aml_records
CREATE OR REPLACE FUNCTION public.enforce_aml_archive_lock()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_bypass BOOLEAN := (COALESCE(current_setting('app.bypass_aml_lock_for_demo_reset', true), '') = 'true');
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF OLD.is_locked = TRUE AND (OLD.retention_until IS NULL OR CURRENT_DATE < OLD.retention_until) AND NOT v_bypass THEN
            RAISE EXCEPTION 'AML_ARCHIVE_LOCKED: Cannot delete locked AML record before retention date %', OLD.retention_until;
        END IF;
        RETURN OLD;
    END IF;

    -- Always protect immutable identity / sequence fields
    NEW.agency_id := OLD.agency_id;
    NEW.sequence_year := OLD.sequence_year;
    NEW.sequence_number := OLD.sequence_number;
    NEW.aml_ref_no := OLD.aml_ref_no;
    NEW.created_at := OLD.created_at;

    -- Transitioning from unlocked -> locked (agency_admin only)
    IF OLD.is_locked = FALSE AND NEW.is_locked = TRUE THEN
        IF auth.uid() IS NOT NULL AND auth.uid() <> OLD.agency_id THEN
            RAISE EXCEPTION 'AML_ADMIN_REQUIRED: Only agency admin can lock an AML record for 10-year retention';
        END IF;
        IF NEW.status NOT IN ('approved', 'rejected') THEN
            NEW.status := 'approved';
        END IF;
        NEW.locked_at := now();
        NEW.locked_by := COALESCE(auth.uid(), NEW.locked_by);
        NEW.retention_until := (COALESCE(NEW.transaction_date, CURRENT_DATE) + INTERVAL '10 years')::DATE;
        NEW.updated_at := now();
        RETURN NEW;
    END IF;

    -- Already locked under active 10-year retention
    IF OLD.is_locked = TRUE AND (OLD.retention_until IS NULL OR CURRENT_DATE < OLD.retention_until) THEN
        -- Verify no immutable legal snapshot, risk, or lock fields were mutated
        IF NEW.is_locked = TRUE
           AND NEW.locked_at IS NOT DISTINCT FROM OLD.locked_at
           AND NEW.locked_by IS NOT DISTINCT FROM OLD.locked_by
           AND NEW.retention_until IS NOT DISTINCT FROM OLD.retention_until
           AND NEW.party_type = OLD.party_type
           AND NEW.client_name_snapshot = OLD.client_name_snapshot
           AND NEW.jmbg_pib_snapshot IS NOT DISTINCT FROM OLD.jmbg_pib_snapshot
           AND NEW.id_doc_number IS NOT DISTINCT FROM OLD.id_doc_number
           AND NEW.risk_score = OLD.risk_score
           AND NEW.risk_level = OLD.risk_level
           AND NEW.risk_factors = OLD.risk_factors
           AND NEW.is_pep = OLD.is_pep
           AND NEW.ubo_list = OLD.ubo_list
           AND NEW.transaction_type = OLD.transaction_type
           AND NEW.transaction_value_eur IS NOT DISTINCT FROM OLD.transaction_value_eur
           AND NEW.source_of_funds IS NOT DISTINCT FROM OLD.source_of_funds
           AND NEW.decision_notes IS NOT DISTINCT FROM OLD.decision_notes
        THEN
            -- 1. Allow one-time supersede link when a newer revision replaces this locked record
            IF OLD.superseded_by_id IS NULL
               AND NEW.superseded_by_id IS NOT NULL
               AND NEW.status = 'superseded'
            THEN
                NEW.updated_at := now();
                RETURN NEW;
            END IF;

            -- 2. Allow Postgres FK ON DELETE SET NULL when source client/property/listing/eop is removed
            IF NEW.status = OLD.status
               AND (NEW.client_id IS NULL OR NEW.client_id = OLD.client_id)
               AND (NEW.eop_record_id IS NULL OR NEW.eop_record_id = OLD.eop_record_id)
               AND (NEW.property_id IS NULL OR NEW.property_id = OLD.property_id)
               AND (NEW.listing_id IS NULL OR NEW.listing_id = OLD.listing_id)
               AND (NEW.superseded_by_id IS NULL OR NEW.superseded_by_id = OLD.superseded_by_id)
            THEN
                NEW.updated_at := OLD.updated_at;
                RETURN NEW;
            END IF;
        END IF;

        RAISE EXCEPTION 'AML_ARCHIVE_LOCKED: Record is locked under 10-year statutory retention until %', OLD.retention_until;
    END IF;

    NEW.updated_at := now();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_aml_archive_lock ON public.aml_records;
CREATE TRIGGER trg_enforce_aml_archive_lock
    BEFORE UPDATE OR DELETE ON public.aml_records
    FOR EACH ROW
    EXECUTE FUNCTION public.enforce_aml_archive_lock();

-- 5c. Protect attachments of locked AML records (INSERT / UPDATE / DELETE)
CREATE OR REPLACE FUNCTION public.protect_aml_documents_lock()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_record_id UUID;
    v_locked BOOLEAN := FALSE;
    v_retention DATE;
    v_bypass BOOLEAN := (COALESCE(current_setting('app.bypass_aml_lock_for_demo_reset', true), '') = 'true');
BEGIN
    IF v_bypass THEN
        RETURN COALESCE(NEW, OLD);
    END IF;

    v_record_id := COALESCE(NEW.aml_record_id, OLD.aml_record_id);

    SELECT is_locked, retention_until
    INTO v_locked, v_retention
    FROM public.aml_records
    WHERE id = v_record_id;

    IF v_locked = TRUE AND (v_retention IS NULL OR CURRENT_DATE < v_retention) THEN
        RAISE EXCEPTION 'AML_ARCHIVE_LOCKED: Cannot modify attachments of a locked AML record (retention until %)', v_retention;
    END IF;

    RETURN COALESCE(NEW, OLD);
END;
$$;

DROP TRIGGER IF EXISTS trg_protect_aml_documents_lock ON public.aml_documents;
CREATE TRIGGER trg_protect_aml_documents_lock
    BEFORE INSERT OR UPDATE OR DELETE ON public.aml_documents
    FOR EACH ROW
    EXECUTE FUNCTION public.protect_aml_documents_lock();

-- 6. RLS Policies for public.aml_records
ALTER TABLE public.aml_records ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Agency members can view aml records" ON public.aml_records;
CREATE POLICY "Agency members can view aml records" ON public.aml_records
    FOR SELECT TO authenticated
    USING (public.is_agency_member(agency_id, auth.uid()));

DROP POLICY IF EXISTS "Agency members can insert aml records" ON public.aml_records;
CREATE POLICY "Agency members can insert aml records" ON public.aml_records
    FOR INSERT TO authenticated
    WITH CHECK (public.is_agency_member(agency_id, auth.uid()));

DROP POLICY IF EXISTS "Agency members can update aml records" ON public.aml_records;
CREATE POLICY "Agency members can update aml records" ON public.aml_records
    FOR UPDATE TO authenticated
    USING (public.is_agency_member(agency_id, auth.uid()))
    WITH CHECK (public.is_agency_member(agency_id, auth.uid()));

-- Only agency_admin can delete UNLOCKED draft records; locked records are also blocked by trigger
DROP POLICY IF EXISTS "Agency admins can delete unlocked draft aml records" ON public.aml_records;
CREATE POLICY "Agency admins can delete unlocked draft aml records" ON public.aml_records
    FOR DELETE TO authenticated
    USING (agency_id = auth.uid() AND is_locked = FALSE AND status = 'draft');

GRANT SELECT, INSERT, UPDATE, DELETE ON public.aml_records TO authenticated;
GRANT ALL ON public.aml_records TO service_role;

-- 7. RLS Policies for public.aml_documents
ALTER TABLE public.aml_documents ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Agency members can view aml documents" ON public.aml_documents;
CREATE POLICY "Agency members can view aml documents" ON public.aml_documents
    FOR SELECT TO authenticated
    USING (public.is_agency_member(agency_id, auth.uid()));

DROP POLICY IF EXISTS "Agency members can insert aml documents" ON public.aml_documents;
CREATE POLICY "Agency members can insert aml documents" ON public.aml_documents
    FOR INSERT TO authenticated
    WITH CHECK (public.is_agency_member(agency_id, auth.uid()));

DROP POLICY IF EXISTS "Agency members can delete unlocked aml documents" ON public.aml_documents;
CREATE POLICY "Agency members can delete unlocked aml documents" ON public.aml_documents
    FOR DELETE TO authenticated
    USING (
        public.is_agency_member(agency_id, auth.uid())
        AND NOT EXISTS (
            SELECT 1 FROM public.aml_records r
            WHERE r.id = aml_documents.aml_record_id
              AND r.is_locked = TRUE
              AND (r.retention_until IS NULL OR CURRENT_DATE < r.retention_until)
        )
    );

GRANT SELECT, INSERT, DELETE ON public.aml_documents TO authenticated;
GRANT ALL ON public.aml_documents TO service_role;

-- 8. Private Storage Bucket `aml-documents` & strict agency-isolated RLS
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'aml-documents',
    'aml-documents',
    false,
    10485760,
    ARRAY['application/pdf', 'image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
    public = false,
    file_size_limit = 10485760,
    allowed_mime_types = ARRAY['application/pdf', 'image/jpeg', 'image/png', 'image/webp'];

DROP POLICY IF EXISTS "aml_documents_select_policy" ON storage.objects;
CREATE POLICY "aml_documents_select_policy"
    ON storage.objects FOR SELECT TO authenticated
    USING (
        bucket_id = 'aml-documents'
        AND public.is_agency_member(public.try_parse_uuid((storage.foldername(name))[1]), auth.uid())
    );

DROP POLICY IF EXISTS "aml_documents_insert_policy" ON storage.objects;
CREATE POLICY "aml_documents_insert_policy"
    ON storage.objects FOR INSERT TO authenticated
    WITH CHECK (
        bucket_id = 'aml-documents'
        AND public.is_agency_member(public.try_parse_uuid((storage.foldername(name))[1]), auth.uid())
        AND NOT EXISTS (
            SELECT 1 FROM public.aml_records r
            WHERE r.id = public.try_parse_uuid((storage.foldername(name))[2])
              AND r.is_locked = TRUE
              AND (r.retention_until IS NULL OR CURRENT_DATE < r.retention_until)
        )
    );

DROP POLICY IF EXISTS "aml_documents_delete_policy" ON storage.objects;
CREATE POLICY "aml_documents_delete_policy"
    ON storage.objects FOR DELETE TO authenticated
    USING (
        bucket_id = 'aml-documents'
        AND public.is_agency_member(public.try_parse_uuid((storage.foldername(name))[1]), auth.uid())
        AND NOT EXISTS (
            SELECT 1 FROM public.aml_records r
            WHERE r.id = public.try_parse_uuid((storage.foldername(name))[2])
              AND r.is_locked = TRUE
              AND (r.retention_until IS NULL OR CURRENT_DATE < r.retention_until)
        )
    );

-- 9. Update clear_agency_demo_data() with guarded is_demo-only AML cleanup
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
    v_is_demo BOOLEAN := FALSE;
    v_prop_count INT := 0;
    v_listing_count INT := 0;
    v_lead_count INT := 0;
    v_eop_count INT := 0;
    v_aml_count INT := 0;
BEGIN
    v_agency_short := substring(p_agency_id::text from 1 for 8);

    SELECT COALESCE(is_demo, FALSE) INTO v_is_demo
    FROM public.profiles
    WHERE id = p_agency_id;

    -- 0. Compliance / AML & EOP cleanup (AML lock bypass strictly gated by profiles.is_demo = TRUE)
    IF v_is_demo AND to_regclass('public.aml_records') IS NOT NULL THEN
        PERFORM set_config('app.bypass_aml_lock_for_demo_reset', 'true', true);
        IF to_regclass('public.aml_documents') IS NOT NULL THEN
            DELETE FROM public.aml_documents WHERE agency_id = p_agency_id;
        END IF;
        DELETE FROM public.aml_records WHERE agency_id = p_agency_id;
        GET DIAGNOSTICS v_aml_count = ROW_COUNT;
    END IF;

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

    -- 2. Portfolio & Distribution tables
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
        'deleted_eop_count', v_eop_count,
        'deleted_aml_count', v_aml_count
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.clear_agency_demo_data(UUID) TO anon, authenticated, service_role;

COMMIT;

NOTIFY pgrst, 'reload schema';
