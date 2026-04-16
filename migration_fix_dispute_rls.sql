-- Migration: Fix RLS for tenant payment disputes
-- This update allows tenants to set the status to 'disputed' 
-- and provides their dispute reason.

DROP POLICY IF EXISTS tenant_update_rent_payments ON public.rent_payments;

CREATE POLICY tenant_update_rent_payments ON public.rent_payments
FOR UPDATE
TO authenticated
USING (
    tenant_id = auth.uid() AND status = 'pending'
)
WITH CHECK (
    tenant_id = auth.uid() AND (
        (status = 'declared' AND declared_at IS NOT NULL) OR 
        (status = 'disputed' AND dispute_reason IS NOT NULL AND disputed_at IS NOT NULL)
    )
);

-- Ensure landlord can resolve the dispute (already allowed by landlord_update_rent_payments 
-- which is based on property ownership, but confirming it's flexible).
