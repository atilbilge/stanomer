-- 1. Create maintenance bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('maintenance', 'maintenance', true)
ON CONFLICT (id) DO NOTHING;

-- 2. Setup RLS Policies for maintenance bucket
-- Allow authenticated users to upload to their own folder
DROP POLICY IF EXISTS "Allow authenticated users to upload maintenance photos" ON storage.objects;
CREATE POLICY "Allow authenticated users to upload maintenance photos"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'maintenance' AND (storage.foldername(name))[1] = auth.uid()::text);

-- Allow authenticated users to read maintenance photos
DROP POLICY IF EXISTS "Allow authenticated users to read maintenance photos" ON storage.objects;
CREATE POLICY "Allow authenticated users to read maintenance photos"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'maintenance');

-- 3. Update maintenance_messages table to support optional photo
ALTER TABLE public.maintenance_messages 
ADD COLUMN IF NOT EXISTS photo_url text;
