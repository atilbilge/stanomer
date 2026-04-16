-- Add declared_at column to rent_payments table
ALTER TABLE public.rent_payments 
ADD COLUMN IF NOT EXISTS declared_at TIMESTAMPTZ;

-- Drop existing update policy for rent_payments to refresh it
DROP POLICY IF EXISTS tenant_update_rent_payments ON public.rent_payments;

-- Allow tenants to declare a payment as paid (update status to 'declared')
CREATE POLICY tenant_update_rent_payments ON public.rent_payments
FOR UPDATE
TO authenticated
USING (
    tenant_id = auth.uid() AND status = 'pending'
)
WITH CHECK (
    tenant_id = auth.uid() AND status = 'declared' AND declared_at IS NOT NULL
);

-- Note: Landlords already have UPDATE access via property ownership,
-- but we ensure they can also manage 'declared' and 'paid' statuses.
-- Redefining for clarity:
DROP POLICY IF EXISTS landlord_update_rent_payments ON public.rent_payments;
CREATE POLICY landlord_update_rent_payments ON public.rent_payments
FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.properties p
        WHERE p.id = property_id AND p.landlord_id = auth.uid()
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.properties p
        WHERE p.id = property_id AND p.landlord_id = auth.uid()
    )
);
