-- ==============================================================================
-- MIGRATION: 2026-11-23_listings_properties_lifecycle_bridge.sql
-- DESCRIPTION: Pre-Sales (Listings) & After-Sales (Managed Properties & Contracts)
--              Bidirectional Lifecycle Integration + RLS Helper Functions Safety
-- TARGET: Dev Database ONLY (thvbpifahvasyzmngpzp) - Never run on Production!
-- IDEMPOTENT: Safe to run multiple times without data loss.
-- ==============================================================================

-- 0. RLS HELPER FUNCTIONS (Dynamic SQL - Order Independent, Never Fails on Missing Relations)
CREATE OR REPLACE FUNCTION public.is_invited_to_property(check_property_id UUID, check_email TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_result BOOLEAN := FALSE;
BEGIN
  IF to_regclass('public.invitations') IS NULL THEN
    RETURN FALSE;
  END IF;
  EXECUTE 'SELECT EXISTS (
    SELECT 1 FROM public.invitations
    WHERE property_id = $1
      AND LOWER(invitee_email) = LOWER(COALESCE($2, ''''))
  )' INTO v_result USING check_property_id, check_email;
  RETURN v_result;
END;
$$;

CREATE OR REPLACE FUNCTION public.is_agency_of_property(check_property_id UUID, check_user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_result BOOLEAN := FALSE;
BEGIN
  IF to_regclass('public.properties') IS NULL THEN
    RETURN FALSE;
  END IF;
  EXECUTE 'SELECT EXISTS (
    SELECT 1 FROM public.properties
    WHERE id = $1
      AND agency_id = $2
  )' INTO v_result USING check_property_id, check_user_id;
  RETURN v_result;
END;
$$;

-- 1. Ensure invitations and activity_logs exist defensively with required columns
DO $$
BEGIN
    IF to_regclass('public.invitations') IS NULL THEN
        CREATE TABLE IF NOT EXISTS public.invitations (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            property_id UUID NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
            contract_id UUID REFERENCES public.contracts(id) ON DELETE SET NULL,
            inviter_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
            inviter_name TEXT,
            invitee_email TEXT,
            token TEXT UNIQUE NOT NULL DEFAULT gen_random_uuid()::TEXT,
            target_role TEXT DEFAULT 'tenant',
            status TEXT DEFAULT 'pending',
            expires_at TIMESTAMPTZ NOT NULL DEFAULT (now() + interval '7 days'),
            created_at TIMESTAMPTZ DEFAULT now(),
            updated_at TIMESTAMPTZ DEFAULT now()
        );
    END IF;

    -- Ensure required columns exist when public.invitations already existed
    ALTER TABLE public.invitations ADD COLUMN IF NOT EXISTS contract_id UUID REFERENCES public.contracts(id) ON DELETE SET NULL;
    ALTER TABLE public.invitations ADD COLUMN IF NOT EXISTS inviter_name TEXT;
    ALTER TABLE public.invitations ADD COLUMN IF NOT EXISTS target_role TEXT DEFAULT 'tenant';

    -- Ensure activity_logs table has type column for RLS policies
    IF to_regclass('public.activity_logs') IS NOT NULL THEN
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' AND table_name = 'activity_logs' AND column_name = 'type'
        ) THEN
            ALTER TABLE public.activity_logs ADD COLUMN type TEXT DEFAULT 'system_event';
        END IF;
    END IF;
END $$;

-- 2. BIDIRECTIONAL LIFECYCLE COLUMNS
DO $$
BEGIN
    -- 2.1 Ensure managed_property_id column exists on public.listings
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'listings' AND column_name = 'managed_property_id'
    ) THEN
        ALTER TABLE public.listings 
        ADD COLUMN managed_property_id UUID REFERENCES public.properties(id) ON DELETE SET NULL;
    END IF;

    -- 2.2 Ensure listing_status column exists on public.listings
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'listings' AND column_name = 'listing_status'
    ) THEN
        ALTER TABLE public.listings 
        ADD COLUMN listing_status TEXT NOT NULL DEFAULT 'active' 
        CHECK (listing_status IN ('active', 'reserved', 'rented', 'sold', 'archived'));
    END IF;

    -- 2.3 Ensure closed_at column exists on public.listings
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'listings' AND column_name = 'closed_at'
    ) THEN
        ALTER TABLE public.listings 
        ADD COLUMN closed_at TIMESTAMPTZ DEFAULT NULL;
    END IF;

    -- 2.4 Ensure closing_price column exists on public.listings
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'listings' AND column_name = 'closing_price'
    ) THEN
        ALTER TABLE public.listings 
        ADD COLUMN closing_price NUMERIC(12,2) DEFAULT NULL;
    END IF;

    -- 2.5 Ensure closing_notes column exists on public.listings
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'listings' AND column_name = 'closing_notes'
    ) THEN
        ALTER TABLE public.listings 
        ADD COLUMN closing_notes TEXT DEFAULT NULL;
    END IF;

    -- 2.6 Ensure last_listing_id column exists on public.properties
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'properties' AND column_name = 'last_listing_id'
    ) THEN
        ALTER TABLE public.properties 
        ADD COLUMN last_listing_id UUID REFERENCES public.listings(id) ON DELETE SET NULL;
    END IF;

    -- 2.7 Ensure source_listing_id column exists on public.contracts
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'contracts' AND column_name = 'source_listing_id'
    ) THEN
        ALTER TABLE public.contracts 
        ADD COLUMN source_listing_id UUID REFERENCES public.listings(id) ON DELETE SET NULL;
    END IF;

    -- 2.8 Ensure closing_contract_id column exists on public.listings
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'listings' AND column_name = 'closing_contract_id'
    ) THEN
        ALTER TABLE public.listings 
        ADD COLUMN closing_contract_id UUID REFERENCES public.contracts(id) ON DELETE SET NULL;
    END IF;
END $$;

-- 2.9 Ensure all documented contract & property tenant columns exist on Dev DB
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS tenant_name TEXT;

ALTER TABLE public.contracts ADD COLUMN IF NOT EXISTS tenant_name TEXT;
ALTER TABLE public.contracts ADD COLUMN IF NOT EXISTS tenant_phone TEXT;
ALTER TABLE public.contracts ADD COLUMN IF NOT EXISTS tenant_id_number TEXT;
ALTER TABLE public.contracts ADD COLUMN IF NOT EXISTS tenant_notes TEXT;
ALTER TABLE public.contracts ADD COLUMN IF NOT EXISTS tenant_id_document_url TEXT;
ALTER TABLE public.contracts ADD COLUMN IF NOT EXISTS tenant_secondary_contacts JSONB DEFAULT '[]'::jsonb;
ALTER TABLE public.contracts ADD COLUMN IF NOT EXISTS contract_url TEXT;
ALTER TABLE public.contracts ADD COLUMN IF NOT EXISTS expenses_config JSONB DEFAULT '[]'::jsonb;
ALTER TABLE public.contracts ADD COLUMN IF NOT EXISTS termination_date DATE;
ALTER TABLE public.contracts ADD COLUMN IF NOT EXISTS termination_approved BOOLEAN DEFAULT FALSE;

-- 3. PERFORMANS İNDEKSLERİ (Idempotent)
CREATE INDEX IF NOT EXISTS listings_managed_property_id_idx 
ON public.listings (managed_property_id);

CREATE INDEX IF NOT EXISTS listings_status_idx 
ON public.listings (listing_status);

CREATE INDEX IF NOT EXISTS properties_last_listing_id_idx 
ON public.properties (last_listing_id);

CREATE INDEX IF NOT EXISTS contracts_source_listing_id_idx 
ON public.contracts (source_listing_id);

CREATE INDEX IF NOT EXISTS listings_closing_contract_id_idx 
ON public.listings (closing_contract_id);

-- 4. MEVCUT DEMO VE ACENTE SÖZLEŞMELERİNDE EKSİK OLAN TENANT_NAME / TENANT_PHONE BACKFILL
UPDATE public.contracts c
SET
    tenant_name  = COALESCE(NULLIF(BTRIM(c.tenant_name), ''), p.full_name),
    tenant_phone = COALESCE(NULLIF(BTRIM(c.tenant_phone), ''), p.phone_number)
FROM public.profiles p
WHERE c.tenant_id = p.id
  AND (
    c.tenant_name IS NULL OR BTRIM(c.tenant_name) = ''
    OR c.tenant_phone IS NULL OR BTRIM(c.tenant_phone) = ''
  );

-- 5. CONTRACTS RLS POLICIES: ALLOW MANAGING AGENCY OF PROPERTY TO SELECT/UPDATE/DELETE CONTRACTS EVEN WHEN contracts.agency_id IS NULL
UPDATE public.contracts c
SET agency_id = p.agency_id
FROM public.properties p
WHERE c.property_id = p.id
  AND c.agency_id IS NULL
  AND p.agency_id IS NOT NULL;

DROP POLICY IF EXISTS "contracts_select_policy" ON public.contracts;
CREATE POLICY "contracts_select_policy" ON public.contracts FOR SELECT TO authenticated
    USING (
        landlord_id = auth.uid()
        OR tenant_id = auth.uid()
        OR agency_id = auth.uid()
        OR public.is_agency_of_property(property_id, auth.uid())
        OR (invitee_email IS NOT NULL AND LOWER(invitee_email) = LOWER(COALESCE(auth.jwt()->>'email', '')))
        OR (token IS NOT NULL)
    );

DROP POLICY IF EXISTS "contracts_insert_policy" ON public.contracts;
CREATE POLICY "contracts_insert_policy" ON public.contracts FOR INSERT TO authenticated
    WITH CHECK (
        landlord_id = auth.uid()
        OR agency_id = auth.uid()
        OR public.is_agency_of_property(property_id, auth.uid())
    );

DROP POLICY IF EXISTS "contracts_update_policy" ON public.contracts;
CREATE POLICY "contracts_update_policy" ON public.contracts FOR UPDATE TO authenticated
    USING (
        landlord_id = auth.uid()
        OR agency_id = auth.uid()
        OR public.is_agency_of_property(property_id, auth.uid())
        OR tenant_id = auth.uid()
        OR tenant_id IS NULL
        OR (invitee_email IS NOT NULL AND LOWER(invitee_email) = LOWER(COALESCE(auth.jwt()->>'email', '')))
    );

DROP POLICY IF EXISTS "contracts_delete_policy" ON public.contracts;
CREATE POLICY "contracts_delete_policy" ON public.contracts FOR DELETE TO authenticated
    USING (
        landlord_id = auth.uid()
        OR agency_id = auth.uid()
        OR public.is_agency_of_property(property_id, auth.uid())
    );

-- 6. FIX TENANT INVITATION RESOLUTION: Prioritize contract terms & include active_contract in get_invite_details
-- Also remove duplicate tenant rows in public.invitations that shadowed public.contracts tokens
DELETE FROM public.invitations i
USING public.contracts c
WHERE (i.token = c.token OR i.contract_id = c.id)
  AND COALESCE(i.target_role, 'tenant') = 'tenant';

CREATE OR REPLACE FUNCTION public.get_invite_details(p_token TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_invite_json JSONB;
    v_contract_json JSONB;
BEGIN
    -- 1. First check contracts table (tenant contract invitations always live in public.contracts)
    SELECT (to_jsonb(c.*) || jsonb_build_object(
        'type', 'contract',
        'active_contract', to_jsonb(c.*),
        'properties', jsonb_build_object(
            'id', p.id,
            'name', p.name,
            'title', p.title,
            'address', p.address,
            'default_monthly_rent', p.default_monthly_rent,
            'default_deposit_amount', p.default_deposit_amount,
            'currency', p.currency,
            'landlord_id', p.landlord_id,
            'tenant_id', p.tenant_id,
            'agency_id', p.agency_id,
            'landlord_name', p.landlord_name,
            'landlord_email', p.landlord_email,
            'landlord_phone', p.landlord_phone
        )
    ))
    INTO v_contract_json
    FROM public.contracts c
    JOIN public.properties p ON p.id = c.property_id
    WHERE c.token = p_token
      AND (c.status IN ('pending', 'negotiating', 'revision_requested') OR (c.status = 'active' AND c.tenant_id IS NULL))
    ORDER BY c.created_at DESC
    LIMIT 1;

    -- 2. Next check invitations table (landlord ownership invitations or standalone invitations)
    SELECT (to_jsonb(i.*) || jsonb_build_object(
        'type', CASE WHEN i.target_role = 'landlord' THEN 'landlord_ownership' ELSE COALESCE(v_contract_json->>'type', 'invitation') END,
        'active_contract', COALESCE(
            v_contract_json,
            (
                SELECT to_jsonb(c2.*)
                FROM public.contracts c2
                WHERE (c2.id = i.contract_id OR c2.property_id = i.property_id)
                  AND c2.status IN ('pending', 'negotiating', 'active', 'revision_requested')
                ORDER BY c2.created_at DESC
                LIMIT 1
            )
        ),
        'properties', jsonb_build_object(
            'id', p.id,
            'name', p.name,
            'title', p.title,
            'address', p.address,
            'default_monthly_rent', p.default_monthly_rent,
            'default_deposit_amount', p.default_deposit_amount,
            'currency', p.currency,
            'landlord_id', p.landlord_id,
            'tenant_id', p.tenant_id,
            'agency_id', p.agency_id,
            'landlord_name', p.landlord_name,
            'landlord_email', p.landlord_email,
            'landlord_phone', p.landlord_phone
        )
    ))
    INTO v_invite_json
    FROM public.invitations i
    JOIN public.properties p ON p.id = i.property_id
    WHERE i.token = p_token
      AND i.status = 'pending'
      AND (i.expires_at IS NULL OR i.expires_at > now());

    IF v_invite_json IS NOT NULL AND (v_invite_json->>'target_role' = 'landlord' OR v_contract_json IS NULL) THEN
        RETURN v_invite_json;
    END IF;

    IF v_contract_json IS NOT NULL THEN
        RETURN v_contract_json;
    END IF;

    RETURN v_invite_json;
END;
$$;

-- 7. UPDATE view_agency_financial_ledger: Expose dispute_reason, disputed_at & include 'disputed' in is_pending_approval
DROP VIEW IF EXISTS public.view_agency_financial_ledger;
CREATE OR REPLACE VIEW public.view_agency_financial_ledger WITH (security_invoker = true) AS
WITH deduplicated_rent_payments AS (
  SELECT DISTINCT ON (
    rp.property_id,
    EXTRACT(YEAR FROM rp.due_date),
    EXTRACT(MONTH FROM rp.due_date),
    LOWER(TRIM(rp.title))
  )
    rp.id AS id,
    p.agency_id,
    rp.property_id,
    rp.contract_id,
    rp.tenant_id,
    p.landlord_id,
    'rent_payment'::TEXT AS source_table,
    rp.title::TEXT AS title,
    rp.title::TEXT AS raw_title,
    (CASE 
      WHEN LOWER(TRIM(rp.title)) = 'kira' 
        OR LOWER(TRIM(rp.title)) LIKE '%rent%' 
        OR LOWER(TRIM(rp.title)) LIKE '%kira%' 
        OR LOWER(TRIM(rp.title)) LIKE '%zakupnina%' 
        OR LOWER(TRIM(rp.title)) LIKE '%kirija%' 
      THEN 'rent'
      WHEN LOWER(TRIM(rp.title)) LIKE '%bakım%' 
        OR LOWER(TRIM(rp.title)) LIKE '%maintenance%' 
      THEN 'maintenance'
      ELSE 'bill'
    END)::TEXT AS category,
    COALESCE(rp.amount, 0)::NUMERIC AS amount,
    COALESCE(rp.currency, p.currency, 'EUR')::TEXT AS currency,
    rp.due_date::DATE AS due_date,
    rp.declared_at,
    rp.paid_at,
    rp.status::TEXT AS status,
    NULL::TEXT AS payment_status,
    COALESCE(rp.receiver_type, 'owner')::TEXT AS receiver_type,
    'bank_transfer'::TEXT AS payment_method,
    NULL::TEXT AS paid_by,
    rp.receipt_url,
    rp.invoice_url,
    rp.owner_note,
    rp.dispute_reason,
    rp.disputed_at,
    FALSE AS is_maintenance,
    NULL::NUMERIC AS cost_amount,
    NULL::NUMERIC AS remaining_amount,
    NULL::NUMERIC AS settled_amount,
    NULL::UUID AS debtor_id,
    FALSE AS is_tenant_debtor,
    FALSE AS is_landlord_debtor,
    COALESCE(p.name, p.address, 'Mülk')::TEXT AS property_title,
    COALESCE(p.address, '')::TEXT AS property_address,
    COALESCE(p.city, '')::TEXT AS property_city,
    COALESCE(p.landlord_name, lp.full_name, p.landlord_email, lp.email, '')::TEXT AS landlord_name,
    COALESCE(p.landlord_email, lp.email, '')::TEXT AS landlord_email,
    COALESCE(tp.full_name, tp.email, '')::TEXT AS tenant_name,
    rp.created_at,
    rp.created_at AS updated_at
  FROM public.rent_payments rp
  JOIN public.properties p ON p.id = rp.property_id
  LEFT JOIN public.profiles lp ON lp.id = p.landlord_id
  LEFT JOIN public.profiles tp ON tp.id = rp.tenant_id
  WHERE p.agency_id IS NOT NULL
  ORDER BY
    rp.property_id,
    EXTRACT(YEAR FROM rp.due_date),
    EXTRACT(MONTH FROM rp.due_date),
    LOWER(TRIM(rp.title)),
    (CASE WHEN rp.amount > 0 THEN 1 ELSE 0 END) DESC,
    (CASE WHEN rp.status IN ('declared', 'disputed') THEN 1 ELSE 0 END) DESC,
    (CASE WHEN rp.receipt_url IS NOT NULL THEN 1 ELSE 0 END) DESC,
    rp.created_at ASC,
    rp.id ASC
),
synthetic_maintenance_payments AS (
  SELECT
    m.id AS id,
    p.agency_id,
    m.property_id,
    m.contract_id,
    p.tenant_id,
    p.landlord_id,
    'maintenance_request'::TEXT AS source_table,
    ('🛠️ ' || m.title)::TEXT AS title,
    m.title::TEXT AS raw_title,
    'maintenance'::TEXT AS category,
    (CASE 
      WHEN (COALESCE(m.cost_amount, 0) - COALESCE(m.settled_amount, 0)) > 0 
      THEN (COALESCE(m.cost_amount, 0) - COALESCE(m.settled_amount, 0)) 
      ELSE m.cost_amount 
    END)::NUMERIC AS amount,
    COALESCE(m.currency, p.currency, 'EUR')::TEXT AS currency,
    COALESCE(m.payment_date, m.updated_at, m.created_at)::DATE AS due_date,
    (CASE WHEN m.payment_status IN ('pending_agency_approval', 'pending_review', 'pending_opposite_approval') THEN m.created_at ELSE NULL END) AS declared_at,
    (CASE WHEN m.payment_status = 'paid' THEN COALESCE(m.payment_date, m.updated_at, m.created_at) ELSE NULL END) AS paid_at,
    (CASE 
      WHEN m.payment_status IN ('pending_agency_approval', 'pending_review', 'pending_opposite_approval') THEN 'declared'
      WHEN m.payment_status = 'pending_payment' THEN 'pending_payment'
      ELSE 'paid'
    END)::TEXT AS status,
    m.payment_status::TEXT AS payment_status,
    (CASE 
      WHEN m.paid_by = 'agency' AND mc.debtor_id IS NOT NULL AND mc.debtor_id != p.landlord_id THEN 'tenant'
      ELSE 'landlord'
    END)::TEXT AS receiver_type,
    'bank_transfer'::TEXT AS payment_method,
    m.paid_by::TEXT AS paid_by,
    m.invoice_pdf_url AS receipt_url,
    m.invoice_pdf_url AS invoice_url,
    m.description AS owner_note,
    m.rejection_reason AS dispute_reason,
    NULL::TIMESTAMPTZ AS disputed_at,
    TRUE AS is_maintenance,
    m.cost_amount,
    GREATEST(0, (COALESCE(m.cost_amount, 0) - COALESCE(m.settled_amount, 0)))::NUMERIC AS remaining_amount,
    COALESCE(m.settled_amount, 0)::NUMERIC AS settled_amount,
    mc.debtor_id,
    (m.paid_by = 'agency' AND mc.debtor_id IS NOT NULL AND mc.debtor_id != p.landlord_id) AS is_tenant_debtor,
    ((m.paid_by = 'agency' AND NOT (mc.debtor_id IS NOT NULL AND mc.debtor_id != p.landlord_id)) OR (m.paid_by = 'tenant')) AS is_landlord_debtor,
    COALESCE(p.name, p.address, 'Mülk')::TEXT AS property_title,
    COALESCE(p.address, '')::TEXT AS property_address,
    COALESCE(p.city, '')::TEXT AS property_city,
    COALESCE(p.landlord_name, lp.full_name, p.landlord_email, lp.email, '')::TEXT AS landlord_name,
    COALESCE(p.landlord_email, lp.email, '')::TEXT AS landlord_email,
    COALESCE(tp.full_name, tp.email, '')::TEXT AS tenant_name,
    m.created_at,
    m.updated_at
  FROM public.maintenance_requests m
  JOIN public.properties p ON p.id = m.property_id
  LEFT JOIN public.profiles lp ON lp.id = p.landlord_id
  LEFT JOIN public.profiles tp ON tp.id = p.tenant_id
  LEFT JOIN LATERAL (
    SELECT debtor_id FROM public.maintenance_charges c 
    WHERE c.maintenance_request_id = m.id 
    ORDER BY c.created_at DESC 
    LIMIT 1
  ) mc ON TRUE
  WHERE p.agency_id IS NOT NULL
    AND COALESCE(m.cost_amount, 0) > 0
    AND m.payment_status IN ('pending_agency_approval', 'pending_review', 'pending_opposite_approval', 'paid', 'pending_payment')
),
raw_combined AS (
  SELECT * FROM deduplicated_rent_payments
  UNION ALL
  SELECT * FROM synthetic_maintenance_payments
)
SELECT
  r.id,
  r.agency_id,
  r.property_id,
  r.contract_id,
  r.tenant_id,
  r.landlord_id,
  r.source_table,
  r.title,
  r.raw_title,
  r.category,
  r.amount,
  r.currency,
  r.due_date,
  r.declared_at,
  r.paid_at,
  r.status,
  r.payment_status,
  r.receiver_type,
  r.payment_method,
  r.paid_by,
  r.receipt_url,
  r.invoice_url,
  r.owner_note,
  r.dispute_reason,
  r.disputed_at,
  r.is_maintenance,
  r.cost_amount,
  r.remaining_amount,
  r.settled_amount,
  r.debtor_id,
  r.is_tenant_debtor,
  r.is_landlord_debtor,
  r.property_title,
  r.property_address,
  r.property_city,
  r.landlord_name,
  r.landlord_email,
  r.tenant_name,
  r.created_at,
  r.updated_at,
  (r.status IN ('declared', 'disputed')) AS is_pending_approval,
  (
    r.status NOT IN ('paid', 'declared', 'disputed') 
    AND (r.receiver_type IN ('owner', 'included') OR r.receiver_type IS NULL) 
    AND r.category != 'rent' 
    AND r.amount = 0
  ) AS is_unentered_bill,
  (
    r.status NOT IN ('declared', 'disputed', 'paid') 
    AND r.amount > 0 
    AND (r.status = 'overdue' OR (r.status = 'pending' AND r.due_date < CURRENT_DATE))
  ) AS is_overdue,
  (
    r.status = 'paid' 
    AND r.category = 'rent'
  ) AS is_rent_collected,
  (
    r.status = 'paid' 
    AND r.category != 'rent' 
    AND r.is_maintenance = FALSE 
    AND r.receiver_type = 'owner'
  ) AS is_bills_collected,
  (
    r.status = 'paid' 
    AND r.category != 'rent' 
    AND r.is_maintenance = FALSE 
    AND r.receiver_type = 'included'
  ) AS is_bills_to_institutions,
  (
    r.is_maintenance = TRUE 
    AND (r.status = 'paid' OR r.payment_status = 'paid') 
    AND (r.paid_by = 'landlord' OR (r.paid_by = 'agency' AND r.is_tenant_debtor = FALSE))
  ) AS is_maintenance_paid,
  (
    r.is_maintenance = TRUE 
    AND r.paid_by = 'agency' 
    AND r.is_tenant_debtor = FALSE 
    AND r.status != 'paid' 
    AND r.payment_status NOT IN ('paid', 'rejected') 
    AND (COALESCE(r.remaining_amount, 0) > 0 OR r.amount > 0)
  ) AS is_maintenance_owed_to_agency,
  (
    r.is_maintenance = TRUE 
    AND r.status NOT IN ('paid', 'declared') 
    AND r.payment_status NOT IN ('pending_agency_approval', 'pending_review', 'pending_opposite_approval') 
    AND (COALESCE(r.cost_amount, 0) > 0 OR r.amount > 0)
  ) AS is_unpaid_maintenance,
  (
    r.category != 'rent' 
    AND r.is_maintenance = FALSE 
    AND r.status != 'paid' 
    AND r.receiver_type = 'included' 
    AND r.amount > 0
  ) AS is_unpaid_bills_to_institutions,
  (
    r.is_maintenance = TRUE 
    AND r.paid_by = 'tenant' 
    AND r.payment_status NOT IN ('paid', 'rejected') 
    AND (COALESCE(r.remaining_amount, 0) > 0 OR COALESCE(r.cost_amount, 0) > 0 OR r.amount > 0)
  ) AS is_tenant_offset
FROM raw_combined r;

GRANT SELECT ON public.view_agency_financial_ledger TO authenticated;
GRANT SELECT ON public.view_agency_financial_ledger TO anon;
GRANT SELECT ON public.view_agency_financial_ledger TO service_role;

-- 8. ENSURE 'maintenance' STORAGE BUCKET HAS ITS 4 RLS POLICIES
INSERT INTO storage.buckets (id, name, public)
VALUES ('maintenance', 'maintenance', true)
ON CONFLICT (id) DO UPDATE SET public = true;

DROP POLICY IF EXISTS "maintenance_select_policy" ON storage.objects;
CREATE POLICY "maintenance_select_policy"
  ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id = 'maintenance');

DROP POLICY IF EXISTS "maintenance_insert_policy" ON storage.objects;
CREATE POLICY "maintenance_insert_policy"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'maintenance' AND auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "maintenance_update_policy" ON storage.objects;
CREATE POLICY "maintenance_update_policy"
  ON storage.objects FOR UPDATE TO authenticated
  USING (bucket_id = 'maintenance' AND auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "maintenance_delete_policy" ON storage.objects;
CREATE POLICY "maintenance_delete_policy"
  ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'maintenance' AND auth.uid() IS NOT NULL);

-- 9. DROP LEGACY NOT NULL CONSTRAINTS ON rent_payments.period_start & period_end (if columns exist)
-- (Neither Flutter nor generate_agency_demo_data / generate_missing_rent_payments populates period_start/period_end)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'rent_payments' AND column_name = 'period_start'
    ) THEN
        EXECUTE 'ALTER TABLE public.rent_payments ALTER COLUMN period_start DROP NOT NULL';
    END IF;
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'rent_payments' AND column_name = 'period_end'
    ) THEN
        EXECUTE 'ALTER TABLE public.rent_payments ALTER COLUMN period_end DROP NOT NULL';
    END IF;
END $$;





