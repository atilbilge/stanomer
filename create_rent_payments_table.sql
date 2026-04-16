-- Create the rent_payments table
CREATE TABLE IF NOT EXISTS public.rent_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
    tenant_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    amount NUMERIC NOT NULL,
    currency TEXT NOT NULL,
    due_date DATE NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending', -- 'pending' or 'paid'
    paid_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now(),
    
    -- Ensure only one record per month per property
    UNIQUE(property_id, due_date)
);

-- Enable RLS
ALTER TABLE public.rent_payments ENABLE ROW LEVEL SECURITY;

-- Landlords can see all payments for their properties
CREATE POLICY landlord_select_rent_payments ON public.rent_payments
FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.properties p
        WHERE p.id = property_id AND p.landlord_id = auth.uid()
    )
);

-- Tenants can see payments assigned to them or their current property
CREATE POLICY tenant_select_rent_payments ON public.rent_payments
FOR SELECT
USING (
    tenant_id = auth.uid() OR
    EXISTS (
        SELECT 1 FROM public.properties p
        WHERE p.id = property_id AND p.tenant_id = auth.uid()
    )
);

-- Landlords can mark payments as paid
CREATE POLICY landlord_update_rent_payments ON public.rent_payments
FOR UPDATE
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
