-- Migration: 2026-08-27_fix_maintenance_storage_buckets.sql
-- Description: Ensure 'maintenance' and 'maintenance-photos' storage buckets exist and configure robust RLS policies for authenticated users.

-- 1. Ensure storage buckets exist
INSERT INTO storage.buckets (id, name, public)
VALUES 
  ('maintenance', 'maintenance', true),
  ('maintenance-photos', 'maintenance-photos', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- 2. Drop existing policies to prevent conflicts
DROP POLICY IF EXISTS "maintenance_select_policy" ON storage.objects;
DROP POLICY IF EXISTS "maintenance_insert_policy" ON storage.objects;
DROP POLICY IF EXISTS "maintenance_update_policy" ON storage.objects;
DROP POLICY IF EXISTS "maintenance_delete_policy" ON storage.objects;

DROP POLICY IF EXISTS "maintenance_photos_select_policy" ON storage.objects;
DROP POLICY IF EXISTS "maintenance_photos_insert_policy" ON storage.objects;
DROP POLICY IF EXISTS "maintenance_photos_update_policy" ON storage.objects;
DROP POLICY IF EXISTS "maintenance_photos_delete_policy" ON storage.objects;

-- 3. Maintenance bucket policies
CREATE POLICY "maintenance_select_policy"
  ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id = 'maintenance');

CREATE POLICY "maintenance_insert_policy"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'maintenance' AND auth.uid() IS NOT NULL);

CREATE POLICY "maintenance_update_policy"
  ON storage.objects FOR UPDATE TO authenticated
  USING (bucket_id = 'maintenance' AND auth.uid() IS NOT NULL);

CREATE POLICY "maintenance_delete_policy"
  ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'maintenance' AND auth.uid() IS NOT NULL);

-- 4. Maintenance-photos bucket policies
CREATE POLICY "maintenance_photos_select_policy"
  ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id = 'maintenance-photos');

CREATE POLICY "maintenance_photos_insert_policy"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'maintenance-photos' AND auth.uid() IS NOT NULL);

CREATE POLICY "maintenance_photos_update_policy"
  ON storage.objects FOR UPDATE TO authenticated
  USING (bucket_id = 'maintenance-photos' AND auth.uid() IS NOT NULL);

CREATE POLICY "maintenance_photos_delete_policy"
  ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'maintenance-photos' AND auth.uid() IS NOT NULL);
