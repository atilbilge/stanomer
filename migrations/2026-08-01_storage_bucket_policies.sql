-- Migration: 2026-08-01_storage_bucket_policies.sql
-- Description: Create Storage buckets (idempotent) and set RLS policies for
--   rent-receipts, contracts, property-photos, maintenance-photos, contract-documents.
--   Fixes 403 "new row violates row-level security policy" error when agency/landlord
--   tries to upload invoices (receipts) to the rent-receipts bucket.
--   Also fixes: code was using wrong bucket name 'receipts' (changed to 'rent-receipts').

-- ── 1. Ensure buckets exist ──────────────────────────────────────────────────
INSERT INTO storage.buckets (id, name, public)
VALUES
  ('rent-receipts',       'rent-receipts',       true),
  ('contracts',           'contracts',           false),
  ('property-photos',     'property-photos',     true),
  ('maintenance-photos',  'maintenance-photos',  true),
  ('contract-documents',  'contract-documents',  false)
ON CONFLICT (id) DO NOTHING;

-- ── 2. rent-receipts bucket ──────────────────────────────────────────────────
DROP POLICY IF EXISTS "rent_receipts_select_policy"  ON storage.objects;
CREATE POLICY "rent_receipts_select_policy"
  ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id = 'rent-receipts' AND auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "rent_receipts_insert_policy"  ON storage.objects;
CREATE POLICY "rent_receipts_insert_policy"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'rent-receipts' AND auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "rent_receipts_update_policy"  ON storage.objects;
CREATE POLICY "rent_receipts_update_policy"
  ON storage.objects FOR UPDATE TO authenticated
  USING  (bucket_id = 'rent-receipts' AND (storage.foldername(name))[1] = auth.uid()::text);

DROP POLICY IF EXISTS "rent_receipts_delete_policy"  ON storage.objects;
CREATE POLICY "rent_receipts_delete_policy"
  ON storage.objects FOR DELETE TO authenticated
  USING  (bucket_id = 'rent-receipts' AND (storage.foldername(name))[1] = auth.uid()::text);

-- ── 3. contracts bucket ──────────────────────────────────────────────────────
DROP POLICY IF EXISTS "contracts_select_policy"  ON storage.objects;
CREATE POLICY "contracts_select_policy"
  ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id = 'contracts' AND auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "contracts_insert_policy"  ON storage.objects;
CREATE POLICY "contracts_insert_policy"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'contracts' AND auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "contracts_update_policy"  ON storage.objects;
CREATE POLICY "contracts_update_policy"
  ON storage.objects FOR UPDATE TO authenticated
  USING (bucket_id = 'contracts' AND auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "contracts_delete_policy"  ON storage.objects;
CREATE POLICY "contracts_delete_policy"
  ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'contracts' AND auth.uid() IS NOT NULL);

-- ── 4. contract-documents bucket ─────────────────────────────────────────────
DROP POLICY IF EXISTS "contract_documents_select_policy"  ON storage.objects;
CREATE POLICY "contract_documents_select_policy"
  ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id = 'contract-documents' AND auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "contract_documents_insert_policy"  ON storage.objects;
CREATE POLICY "contract_documents_insert_policy"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'contract-documents' AND auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "contract_documents_delete_policy"  ON storage.objects;
CREATE POLICY "contract_documents_delete_policy"
  ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'contract-documents' AND auth.uid() IS NOT NULL);

-- ── 5. property-photos bucket ─────────────────────────────────────────────────
DROP POLICY IF EXISTS "property_photos_select_policy"  ON storage.objects;
CREATE POLICY "property_photos_select_policy"
  ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id = 'property-photos');

DROP POLICY IF EXISTS "property_photos_insert_policy"  ON storage.objects;
CREATE POLICY "property_photos_insert_policy"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'property-photos' AND auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "property_photos_delete_policy"  ON storage.objects;
CREATE POLICY "property_photos_delete_policy"
  ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'property-photos' AND auth.uid() IS NOT NULL);

-- ── 6. maintenance-photos bucket ──────────────────────────────────────────────
DROP POLICY IF EXISTS "maintenance_photos_select_policy"  ON storage.objects;
CREATE POLICY "maintenance_photos_select_policy"
  ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id = 'maintenance-photos');

DROP POLICY IF EXISTS "maintenance_photos_insert_policy"  ON storage.objects;
CREATE POLICY "maintenance_photos_insert_policy"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'maintenance-photos' AND auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "maintenance_photos_delete_policy"  ON storage.objects;
CREATE POLICY "maintenance_photos_delete_policy"
  ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'maintenance-photos' AND auth.uid() IS NOT NULL);
