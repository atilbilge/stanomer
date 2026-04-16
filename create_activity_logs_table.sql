-- Create activity_logs table
CREATE TABLE IF NOT EXISTS public.activity_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL, -- Nullable for system actions
    type TEXT NOT NULL, -- e.g., 'rent_declared', 'rent_approved', 'rent_rejected', 'tenant_joined', 'tenant_left'
    metadata JSONB DEFAULT '{}'::jsonb, -- Store details like month, amount, etc.
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.activity_logs ENABLE ROW LEVEL SECURITY;

-- Landlords can see logs for their properties
CREATE POLICY landlord_select_activity_logs ON public.activity_logs
FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.properties p
        WHERE p.id = property_id AND p.landlord_id = auth.uid()
    )
);

-- Tenants can see logs for their property
CREATE POLICY tenant_select_activity_logs ON public.activity_logs
FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.properties p
        WHERE p.id = property_id AND p.tenant_id = auth.uid()
    )
);

-- Repository/Service will handle insertions via service role or authenticated actions
-- For simplicity, let's allow authenticated users to INSERT logs for their properties
CREATE POLICY user_insert_activity_logs ON public.activity_logs
FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.properties p
        WHERE p.id = property_id AND (p.landlord_id = auth.uid() OR p.tenant_id = auth.uid())
    )
);
