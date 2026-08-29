-- ==============================================================================
-- Migration: Create maintenance_charges table & Integrate with rent_payments
-- Target Database: DEV ONLY (thvbpifahvasyzmngpzp)
-- Date: 2026-08-29
-- Description:
--   1. Creates public.maintenance_charges table (1:N relationship with maintenance_requests).
--   2. Adds linked_charge_id to public.rent_payments table.
--   3. Sets up RLS policies & performance indexes.
--   4. Ensures 'invoices' storage bucket exists with proper policies.
--   5. Backfills any existing cost data from maintenance_requests into maintenance_charges.
-- ==============================================================================

DO $$
BEGIN
    -- ── 1. Create maintenance_charges table ───────────────────────────────────
    CREATE TABLE IF NOT EXISTS public.maintenance_charges (
        id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        maintenance_request_id      UUID NOT NULL REFERENCES public.maintenance_requests(id) ON DELETE CASCADE,
        property_id                 UUID NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
        created_by                  UUID REFERENCES public.profiles(id) ON DELETE SET NULL,

        -- Charge classification & workflow direction
        title                       TEXT,
        charge_type                 TEXT NOT NULL DEFAULT 'direct_charge' CHECK (charge_type IN ('direct_charge', 'agency_advance', 'reimbursement')),
        approver_role               TEXT NOT NULL DEFAULT 'counterparty' CHECK (approver_role IN ('agency', 'counterparty')),

        -- Parties involved
        debtor_id                   UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
        creditor_id                 UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
        contractor_name             TEXT,

        -- Amount & Partial settlement tracking
        amount                      NUMERIC(12,2) NOT NULL CHECK (amount >= 0),
        settled_amount              NUMERIC(12,2) NOT NULL DEFAULT 0.00 CHECK (settled_amount >= 0),
        currency                    TEXT NOT NULL DEFAULT 'EUR',

        -- Process status
        status                      TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'declared', 'disputed', 'approved', 'rejected', 'paid')),

        -- Agency contractor advance payment tracking
        contractor_payment_status   TEXT CHECK (contractor_payment_status IS NULL OR contractor_payment_status IN ('unpaid', 'paid')),
        contractor_payment_date     TIMESTAMPTZ,

        -- Settlement method
        settlement_method           TEXT CHECK (settlement_method IS NULL OR settlement_method IN ('separate_payment', 'rent_offset')),

        -- Receipts & Rejection / Dispute metadata
        receipt_url                 TEXT,
        dispute_reason              TEXT,
        rejection_reason            TEXT,
        rejected_by                 UUID REFERENCES public.profiles(id) ON DELETE SET NULL,

        -- Audit Timestamps
        declared_at                 TIMESTAMPTZ,
        approved_at                 TIMESTAMPTZ,
        approved_by                 UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
        paid_at                     TIMESTAMPTZ,
        created_at                  TIMESTAMPTZ NOT NULL DEFAULT now(),
        updated_at                  TIMESTAMPTZ NOT NULL DEFAULT now()
    );

    -- ── 2. Add linked_charge_id to rent_payments ─────────────────────────────
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'rent_payments' AND column_name = 'linked_charge_id'
    ) THEN
        ALTER TABLE public.rent_payments 
        ADD COLUMN linked_charge_id UUID REFERENCES public.maintenance_charges(id) ON DELETE SET NULL;
    END IF;

    -- ── 3. Performance Indexes ───────────────────────────────────────────────
    CREATE INDEX IF NOT EXISTS idx_maintenance_charges_request_id ON public.maintenance_charges(maintenance_request_id);
    CREATE INDEX IF NOT EXISTS idx_maintenance_charges_property_id ON public.maintenance_charges(property_id);
    CREATE INDEX IF NOT EXISTS idx_maintenance_charges_status ON public.maintenance_charges(status);
    CREATE INDEX IF NOT EXISTS idx_maintenance_charges_debtor ON public.maintenance_charges(debtor_id);
    CREATE INDEX IF NOT EXISTS idx_maintenance_charges_creditor ON public.maintenance_charges(creditor_id);
    CREATE INDEX IF NOT EXISTS idx_rent_payments_linked_charge ON public.rent_payments(linked_charge_id);

    -- ── 4. Storage Bucket for 'invoices' ─────────────────────────────────────
    INSERT INTO storage.buckets (id, name, public)
    VALUES ('invoices', 'invoices', false)
    ON CONFLICT (id) DO NOTHING;

END $$;

-- ── 5. Enable RLS on maintenance_charges ─────────────────────────────────────
ALTER TABLE public.maintenance_charges ENABLE ROW LEVEL SECURITY;

-- SELECT policy: Landlord, Tenant, Agency can view charges for their properties
DROP POLICY IF EXISTS "Users can view maintenance charges" ON public.maintenance_charges;
CREATE POLICY "Users can view maintenance charges"
    ON public.maintenance_charges FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.properties p
            WHERE p.id = maintenance_charges.property_id
              AND (
                  p.landlord_id = auth.uid()
                  OR p.tenant_id = auth.uid()
                  OR p.agency_id = auth.uid()
                  OR public.is_agency_of_property(p.id, auth.uid())
              )
        )
    );

-- INSERT policy: Landlord, Tenant, Agency can create charges for their properties
DROP POLICY IF EXISTS "Users can insert maintenance charges" ON public.maintenance_charges;
CREATE POLICY "Users can insert maintenance charges"
    ON public.maintenance_charges FOR INSERT TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.properties p
            WHERE p.id = property_id
              AND (
                  p.landlord_id = auth.uid()
                  OR p.tenant_id = auth.uid()
                  OR p.agency_id = auth.uid()
                  OR public.is_agency_of_property(p.id, auth.uid())
              )
        )
    );

-- UPDATE policy: Landlord, Tenant, Agency can update charges for their properties
DROP POLICY IF EXISTS "Users can update maintenance charges" ON public.maintenance_charges;
CREATE POLICY "Users can update maintenance charges"
    ON public.maintenance_charges FOR UPDATE TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.properties p
            WHERE p.id = maintenance_charges.property_id
              AND (
                  p.landlord_id = auth.uid()
                  OR p.tenant_id = auth.uid()
                  OR p.agency_id = auth.uid()
                  OR public.is_agency_of_property(p.id, auth.uid())
              )
        )
    );

-- DELETE policy: Landlord or Agency can delete charges
DROP POLICY IF EXISTS "Landlord and Agency can delete maintenance charges" ON public.maintenance_charges;
CREATE POLICY "Landlord and Agency can delete maintenance charges"
    ON public.maintenance_charges FOR DELETE TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.properties p
            WHERE p.id = maintenance_charges.property_id
              AND (
                  p.landlord_id = auth.uid()
                  OR p.agency_id = auth.uid()
                  OR public.is_agency_of_property(p.id, auth.uid())
              )
        )
    );

-- ── 6. Storage RLS Policies for 'invoices' bucket ────────────────────────────
DROP POLICY IF EXISTS "invoices_select_policy" ON storage.objects;
CREATE POLICY "invoices_select_policy"
    ON storage.objects FOR SELECT TO authenticated
    USING (
        bucket_id = 'invoices' AND (
            EXISTS (
                SELECT 1 FROM public.properties p
                WHERE p.id::text = (storage.foldername(name))[1]
                  AND (
                      p.landlord_id = auth.uid() 
                      OR p.tenant_id = auth.uid() 
                      OR p.agency_id = auth.uid() 
                      OR public.is_agency_of_property(p.id, auth.uid())
                  )
            )
            OR (storage.foldername(name))[1] = auth.uid()::text
        )
    );

DROP POLICY IF EXISTS "invoices_insert_policy" ON storage.objects;
CREATE POLICY "invoices_insert_policy"
    ON storage.objects FOR INSERT TO authenticated
    WITH CHECK (
        bucket_id = 'invoices' AND (
            EXISTS (
                SELECT 1 FROM public.properties p
                WHERE p.id::text = (storage.foldername(name))[1]
                  AND (
                      p.landlord_id = auth.uid() 
                      OR p.tenant_id = auth.uid() 
                      OR p.agency_id = auth.uid() 
                      OR public.is_agency_of_property(p.id, auth.uid())
                  )
            )
            OR (storage.foldername(name))[1] = auth.uid()::text
        )
    );

DROP POLICY IF EXISTS "invoices_update_policy" ON storage.objects;
CREATE POLICY "invoices_update_policy"
    ON storage.objects FOR UPDATE TO authenticated
    USING (
        bucket_id = 'invoices' AND (
            EXISTS (
                SELECT 1 FROM public.properties p
                WHERE p.id::text = (storage.foldername(name))[1]
                  AND (
                      p.landlord_id = auth.uid() 
                      OR p.tenant_id = auth.uid() 
                      OR p.agency_id = auth.uid() 
                      OR public.is_agency_of_property(p.id, auth.uid())
                  )
            )
            OR (storage.foldername(name))[1] = auth.uid()::text
        )
    );

DROP POLICY IF EXISTS "invoices_delete_policy" ON storage.objects;
CREATE POLICY "invoices_delete_policy"
    ON storage.objects FOR DELETE TO authenticated
    USING (
        bucket_id = 'invoices' AND (
            EXISTS (
                SELECT 1 FROM public.properties p
                WHERE p.id::text = (storage.foldername(name))[1]
                  AND (
                      p.landlord_id = auth.uid() 
                      OR p.tenant_id = auth.uid() 
                      OR p.agency_id = auth.uid() 
                      OR public.is_agency_of_property(p.id, auth.uid())
                  )
            )
            OR (storage.foldername(name))[1] = auth.uid()::text
        )
    );

-- ── 7. Data Backfill from existing maintenance_requests ──────────────────────
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'maintenance_requests' AND column_name = 'cost_amount'
    ) THEN
        INSERT INTO public.maintenance_charges (
            maintenance_request_id,
            property_id,
            created_by,
            charge_type,
            approver_role,
            debtor_id,
            creditor_id,
            amount,
            settled_amount,
            currency,
            status,
            settlement_method,
            receipt_url,
            rejection_reason,
            rejected_by,
            declared_at,
            created_at
        )
        SELECT 
            mr.id,
            mr.property_id,
            mr.reporter_id,
            'direct_charge',
            CASE WHEN p.agency_id IS NOT NULL THEN 'agency' ELSE 'counterparty' END,
            CASE WHEN mr.paid_by = 'landlord' THEN p.landlord_id ELSE p.tenant_id END,
            CASE WHEN mr.paid_by = 'landlord' THEN p.tenant_id ELSE p.landlord_id END,
            COALESCE(mr.cost_amount, 0),
            COALESCE(mr.settled_amount, 0.00),
            COALESCE(mr.currency, 'EUR'),
            CASE 
                WHEN mr.payment_status IN ('paid') THEN 'paid'
                WHEN mr.payment_status IN ('rejected') THEN 'rejected'
                WHEN mr.payment_status IN ('pending_payment') THEN 'approved'
                ELSE 'pending'
            END,
            'rent_offset',
            mr.invoice_pdf_url,
            mr.rejection_reason,
            mr.rejected_by,
            COALESCE(mr.payment_date, mr.created_at),
            COALESCE(mr.created_at, now())
        FROM public.maintenance_requests mr
        JOIN public.properties p ON p.id = mr.property_id
        WHERE mr.cost_amount IS NOT NULL 
          AND mr.cost_amount > 0
          AND NOT EXISTS (
              SELECT 1 FROM public.maintenance_charges mc WHERE mc.maintenance_request_id = mr.id
          );
    END IF;
END $$;
