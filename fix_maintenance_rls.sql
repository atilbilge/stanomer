-- Ensure reporter and landlord can update maintenance requests
ALTER TABLE public.maintenance_requests ENABLE ROW LEVEL SECURITY;

-- Allow selection
DROP POLICY IF EXISTS "Users can view maintenance requests" ON public.maintenance_requests;
CREATE POLICY "Users can view maintenance requests" 
ON public.maintenance_requests FOR SELECT 
USING (
  reporter_id = auth.uid() 
  OR EXISTS (
    SELECT 1 FROM public.properties p 
    WHERE p.id = maintenance_requests.property_id 
      AND p.landlord_id = auth.uid()
  )
);

-- Allow updates (reopen by tenant, resolve by landlord)
DROP POLICY IF EXISTS "Users can update maintenance requests" ON public.maintenance_requests;
CREATE POLICY "Users can update maintenance requests" 
ON public.maintenance_requests FOR UPDATE 
USING (
  reporter_id = auth.uid() 
  OR EXISTS (
    SELECT 1 FROM public.properties p 
    WHERE p.id = maintenance_requests.property_id 
      AND p.landlord_id = auth.uid()
  )
)
WITH CHECK (
  reporter_id = auth.uid() 
  OR EXISTS (
    SELECT 1 FROM public.properties p 
    WHERE p.id = maintenance_requests.property_id 
      AND p.landlord_id = auth.uid()
  )
);

-- Allow deletion (cancel by tenant)
DROP POLICY IF EXISTS "Users can delete maintenance requests" ON public.maintenance_requests;
CREATE POLICY "Users can delete maintenance requests" 
ON public.maintenance_requests FOR DELETE 
USING (
  reporter_id = auth.uid()
);
