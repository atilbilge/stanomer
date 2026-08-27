-- Migration: Fix and robustify invoices storage bucket RLS policies for tenant expense declarations
-- Date: 2026-08-27

-- 1. Ensure 'invoices' bucket exists and is configured
INSERT INTO storage.buckets (id, name, public)
VALUES ('invoices', 'invoices', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- 2. Drop existing policies to replace with robust ones
DROP POLICY IF EXISTS "invoices_select_policy" ON storage.objects;
DROP POLICY IF EXISTS "invoices_insert_policy" ON storage.objects;
DROP POLICY IF EXISTS "invoices_update_policy" ON storage.objects;
DROP POLICY IF EXISTS "invoices_delete_policy" ON storage.objects;

-- 3. Select Policy: Authenticated users can view invoices they uploaded or for their properties/contracts
CREATE POLICY "invoices_select_policy"
  ON storage.objects FOR SELECT TO authenticated
  USING (
    bucket_id = 'invoices' AND (
      (storage.foldername(name))[1] = auth.uid()::text
      OR EXISTS (
        SELECT 1 FROM public.properties p
        WHERE p.id::text = (storage.foldername(name))[1]
          AND (
            p.landlord_id = auth.uid() 
            OR p.tenant_id = auth.uid() 
            OR p.agency_id = auth.uid() 
            OR public.is_agency_of_property(p.id, auth.uid())
          )
      )
      OR EXISTS (
        SELECT 1 FROM public.contracts c
        WHERE (c.property_id::text = (storage.foldername(name))[1] OR c.tenant_id = auth.uid())
          AND (c.tenant_id = auth.uid() OR c.landlord_id = auth.uid())
      )
    )
  );

-- 4. Insert Policy: Any authenticated user can upload under their user folder or property folder
CREATE POLICY "invoices_insert_policy"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'invoices' AND (
      (storage.foldername(name))[1] = auth.uid()::text
      OR EXISTS (
        SELECT 1 FROM public.properties p
        WHERE p.id::text = (storage.foldername(name))[1]
          AND (
            p.landlord_id = auth.uid() 
            OR p.tenant_id = auth.uid() 
            OR p.agency_id = auth.uid() 
            OR public.is_agency_of_property(p.id, auth.uid())
          )
      )
      OR EXISTS (
        SELECT 1 FROM public.contracts c
        WHERE c.property_id::text = (storage.foldername(name))[1]
          AND c.tenant_id = auth.uid()
      )
    )
  );

-- 5. Update Policy
CREATE POLICY "invoices_update_policy"
  ON storage.objects FOR UPDATE TO authenticated
  USING (
    bucket_id = 'invoices' AND (
      (storage.foldername(name))[1] = auth.uid()::text
      OR EXISTS (
        SELECT 1 FROM public.properties p
        WHERE p.id::text = (storage.foldername(name))[1]
          AND (
            p.landlord_id = auth.uid() 
            OR p.agency_id = auth.uid() 
            OR public.is_agency_of_property(p.id, auth.uid())
          )
      )
    )
  );

-- 6. Delete Policy
CREATE POLICY "invoices_delete_policy"
  ON storage.objects FOR DELETE TO authenticated
  USING (
    bucket_id = 'invoices' AND (
      (storage.foldername(name))[1] = auth.uid()::text
      OR EXISTS (
        SELECT 1 FROM public.properties p
        WHERE p.id::text = (storage.foldername(name))[1]
          AND (
            p.landlord_id = auth.uid() 
            OR p.agency_id = auth.uid() 
            OR public.is_agency_of_property(p.id, auth.uid())
          )
      )
    )
  );
