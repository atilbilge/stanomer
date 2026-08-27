-- Migration: Add financial fields to maintenance_requests & setup invoices storage bucket
-- Target: Dev Supabase (thvbpifahvasyzmngpzp)
-- Safe, idempotent migration script

DO $$
BEGIN
    -- 1. Cost Amount (numeric/decimal, nullable)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'maintenance_requests' AND column_name = 'cost_amount') THEN
        ALTER TABLE public.maintenance_requests ADD COLUMN cost_amount NUMERIC(10,2);
    END IF;

    -- 2. Currency (text, nullable, e.g. 'EUR', 'RSD')
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'maintenance_requests' AND column_name = 'currency') THEN
        ALTER TABLE public.maintenance_requests ADD COLUMN currency TEXT;
    END IF;

    -- 3. Paid By (text, nullable, allowed values: 'tenant', 'landlord')
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'maintenance_requests' AND column_name = 'paid_by') THEN
        ALTER TABLE public.maintenance_requests ADD COLUMN paid_by TEXT;
    END IF;

    -- 4. Payment Date (timestamptz, nullable)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'maintenance_requests' AND column_name = 'payment_date') THEN
        ALTER TABLE public.maintenance_requests ADD COLUMN payment_date TIMESTAMPTZ;
    END IF;

    -- 5. Payment Status (text, default 'pending_review', allowed values: 'pending_review', 'pending_payment', 'paid', 'rejected')
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'maintenance_requests' AND column_name = 'payment_status') THEN
        ALTER TABLE public.maintenance_requests ADD COLUMN payment_status TEXT DEFAULT 'pending_review';
    END IF;

    -- 6. Invoice PDF URL (text, nullable)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'maintenance_requests' AND column_name = 'invoice_pdf_url') THEN
        ALTER TABLE public.maintenance_requests ADD COLUMN invoice_pdf_url TEXT;
    END IF;
END $$;

-- Check Constraints for paid_by and payment_status
ALTER TABLE public.maintenance_requests DROP CONSTRAINT IF EXISTS maintenance_requests_paid_by_check;
ALTER TABLE public.maintenance_requests ADD CONSTRAINT maintenance_requests_paid_by_check 
    CHECK (paid_by IS NULL OR paid_by IN ('tenant', 'landlord'));

ALTER TABLE public.maintenance_requests DROP CONSTRAINT IF EXISTS maintenance_requests_payment_status_check;
ALTER TABLE public.maintenance_requests ADD CONSTRAINT maintenance_requests_payment_status_check 
    CHECK (payment_status IN ('pending_review', 'pending_payment', 'paid', 'rejected'));

-- ── 7. Storage Bucket & RLS for 'invoices' ──────────────────────────────────
INSERT INTO storage.buckets (id, name, public)
VALUES ('invoices', 'invoices', false)
ON CONFLICT (id) DO NOTHING;

-- Storage RLS: Authenticated users can read invoices related to their properties
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

-- Storage RLS: Authenticated users can upload invoices for their properties
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

-- Storage RLS: Authenticated users can update invoices for their properties
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

-- Storage RLS: Authenticated users can delete invoices for their properties
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
