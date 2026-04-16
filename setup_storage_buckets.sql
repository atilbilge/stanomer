-- UNZIP the following and run in Supabase SQL Editor

-- 1. Create Buckets
INSERT INTO storage.buckets (id, name, public)
VALUES ('receipts', 'receipts', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public)
VALUES ('contracts', 'contracts', true)
ON CONFLICT (id) DO NOTHING;

-- 2. Setup RLS Policies for receipts   
-- Allow authenticated users to upload to their own folder
CREATE POLICY "Allow authenticated users to upload receipts"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'receipts' AND (storage.foldername(name))[1] = auth.uid()::text);

-- Allow authenticated users to read receipts
CREATE POLICY "Allow authenticated users to read receipts"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'receipts');

-- 3. Setup RLS Policies for contracts
-- Allow authenticated users to upload contracts to their own folder
CREATE POLICY "Allow authenticated users to upload contracts"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'contracts' AND (storage.foldername(name))[1] = auth.uid()::text);

-- Allow authenticated users to read contracts
CREATE POLICY "Allow authenticated users to read contracts"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'contracts');
