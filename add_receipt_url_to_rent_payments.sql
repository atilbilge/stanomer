-- Add receipt_url column to rent_payments table
ALTER TABLE public.rent_payments 
ADD COLUMN IF NOT EXISTS receipt_url TEXT;

-- Update the tenant update policy to allow adding a receipt_url
DROP POLICY IF EXISTS tenant_update_rent_payments ON public.rent_payments;

CREATE POLICY tenant_update_rent_payments ON public.rent_payments
FOR UPDATE
TO authenticated
USING (
    tenant_id = auth.uid() AND status = 'pending'
)
WITH CHECK (
    tenant_id = auth.uid() AND status = 'declared' AND declared_at IS NOT NULL
);

-- Note: No specific change to check for receipt_url as it's optional, 
-- but the column is now available for the UPDATE.
