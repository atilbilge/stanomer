-- Run this script in the Supabase SQL Editor to update read permissions for Storage Buckets.
-- This allows anyone with the direct public URLs to view/download receipts, contracts,
-- and maintenance photos without requiring active Supabase session authentication headers.

-- 1. Update policies for 'receipts' bucket
DROP POLICY IF EXISTS "Allow authenticated users to read receipts" ON storage.objects;
DROP POLICY IF EXISTS "Allow public read access to receipts" ON storage.objects;
CREATE POLICY "Allow public read access to receipts"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'receipts');

-- 2. Update policies for 'contracts' bucket
DROP POLICY IF EXISTS "Allow authenticated users to read contracts" ON storage.objects;
DROP POLICY IF EXISTS "Allow public read access to contracts" ON storage.objects;
CREATE POLICY "Allow public read access to contracts"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'contracts');

-- 3. Update policies for 'maintenance' bucket
DROP POLICY IF EXISTS "Allow authenticated users to read maintenance photos" ON storage.objects;
DROP POLICY IF EXISTS "Allow public read access to maintenance photos" ON storage.objects;
CREATE POLICY "Allow public read access to maintenance photos"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'maintenance');
