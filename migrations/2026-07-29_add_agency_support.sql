-- ============================================================================
-- MIGRATION: 2026-07-29 — Add Agency Support (B2B2C Architecture)
-- Target: Dev DB (thvbpifahvasyzmngpzp) — Test before applying to Production
-- Safe: Idempotent, non-destructive, backward-compatible
-- ============================================================================

-- 1. Add 'agency' value to user_role ENUM (idempotent)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_enum
        WHERE enumlabel = 'agency'
          AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'user_role')
    ) THEN
        ALTER TYPE public.user_role ADD VALUE 'agency';
    END IF;
END $$;

-- 2. Add agency-specific columns to profiles table
-- These store white-label branding data for agency users
ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS company_name TEXT,
    ADD COLUMN IF NOT EXISTS logo_url TEXT,
    ADD COLUMN IF NOT EXISTS color_scheme JSONB DEFAULT '{}'::jsonb;

-- 3. Add agency_id to properties table
-- References profiles(id) — allows an agency to manage a property on behalf of the landlord
ALTER TABLE public.properties
    ADD COLUMN IF NOT EXISTS agency_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL;

-- 4. Add agency_id and missing contract columns to contracts, invitations, and rent_payments tables
ALTER TABLE public.contracts
    ADD COLUMN IF NOT EXISTS agency_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS invitee_email TEXT,
    ADD COLUMN IF NOT EXISTS inviter_name TEXT,
    ADD COLUMN IF NOT EXISTS token TEXT,
    ADD COLUMN IF NOT EXISTS deposit_currency TEXT DEFAULT 'EUR',
    ADD COLUMN IF NOT EXISTS tenant_feedback TEXT;

ALTER TABLE public.invitations
    ADD COLUMN IF NOT EXISTS inviter_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    ADD COLUMN IF NOT EXISTS agency_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL;

ALTER TABLE public.rent_payments
    ADD COLUMN IF NOT EXISTS landlord_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE;

-- 5. Update RLS policies on properties to include agency access
-- Agency users with agency_id = auth.uid() can view/manage their assigned properties

-- 5. Helper functions (SECURITY DEFINER) to prevent RLS circular recursion loops between properties, invitations, and rent_payments
CREATE OR REPLACE FUNCTION public.is_invited_to_property(check_property_id UUID, check_email TEXT)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.invitations
    WHERE property_id = check_property_id
      AND LOWER(invitee_email) = LOWER(COALESCE(check_email, ''))
  );
$$;

CREATE OR REPLACE FUNCTION public.is_agency_of_property(check_property_id UUID, check_user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.properties
    WHERE id = check_property_id
      AND agency_id = check_user_id
  );
$$;

-- 5a. Drop old select policies and recreate with agency support
DROP POLICY IF EXISTS "properties_select_policy" ON public.properties;
DROP POLICY IF EXISTS "landlord_select_properties" ON public.properties;
DROP POLICY IF EXISTS "tenant_select_properties" ON public.properties;
DROP POLICY IF EXISTS "tenant_view_invited_properties" ON public.properties;

CREATE POLICY "properties_select_policy" ON public.properties
    FOR SELECT TO authenticated
    USING (
        landlord_id = auth.uid()
        OR tenant_id = auth.uid()
        OR agency_id = auth.uid()
        OR public.is_invited_to_property(id, auth.jwt()->>'email')
    );

-- 5b. Agency can also update properties they manage
DROP POLICY IF EXISTS "properties_update_policy" ON public.properties;
DROP POLICY IF EXISTS "landlord_update_properties" ON public.properties;
DROP POLICY IF EXISTS "tenant_join_property" ON public.properties;
DROP POLICY IF EXISTS "tenant_leave_property" ON public.properties;

CREATE POLICY "properties_update_policy" ON public.properties
    FOR UPDATE TO authenticated
    USING (
        landlord_id = auth.uid()
        OR agency_id = auth.uid()
        OR tenant_id = auth.uid()
        OR tenant_id IS NULL
    );

-- 5c. INSERT: only landlords or agencies can add properties
DROP POLICY IF EXISTS "properties_insert_policy" ON public.properties;
DROP POLICY IF EXISTS "Landlords can insert properties" ON public.properties;

CREATE POLICY "properties_insert_policy" ON public.properties
    FOR INSERT TO authenticated
    WITH CHECK (
        landlord_id = auth.uid()
        OR agency_id = auth.uid()
    );

-- 6. Update RLS policies on contracts to include agency access and invitee_email access
DROP POLICY IF EXISTS "contracts_select_policy" ON public.contracts;
DROP POLICY IF EXISTS "landlord_manage_contracts" ON public.contracts;
DROP POLICY IF EXISTS "tenant_view_update_contracts" ON public.contracts;
DROP POLICY IF EXISTS "tenant_respond_contract" ON public.contracts;

CREATE POLICY "contracts_select_policy" ON public.contracts
    FOR SELECT TO authenticated
    USING (
        landlord_id = auth.uid()
        OR tenant_id = auth.uid()
        OR agency_id = auth.uid()
        OR (invitee_email IS NOT NULL AND LOWER(invitee_email) = LOWER(COALESCE(auth.jwt()->>'email', '')))
    );

DROP POLICY IF EXISTS "contracts_insert_policy" ON public.contracts;
CREATE POLICY "contracts_insert_policy" ON public.contracts
    FOR INSERT TO authenticated
    WITH CHECK (
        landlord_id = auth.uid()
        OR agency_id = auth.uid()
    );

DROP POLICY IF EXISTS "contracts_update_policy" ON public.contracts;
CREATE POLICY "contracts_update_policy" ON public.contracts
    FOR UPDATE TO authenticated
    USING (
        landlord_id = auth.uid()
        OR agency_id = auth.uid()
        OR tenant_id = auth.uid()
        OR tenant_id IS NULL
        OR (invitee_email IS NOT NULL AND LOWER(invitee_email) = LOWER(COALESCE(auth.jwt()->>'email', '')))
    );

DROP POLICY IF EXISTS "contracts_delete_policy" ON public.contracts;
CREATE POLICY "contracts_delete_policy" ON public.contracts
    FOR DELETE TO authenticated
    USING (
        landlord_id = auth.uid()
        OR agency_id = auth.uid()
    );

-- 6b. Agency RLS access for rent_payments
DROP POLICY IF EXISTS "rent_payments_select_policy" ON public.rent_payments;
DROP POLICY IF EXISTS "Users can view rent payments" ON public.rent_payments;
CREATE POLICY "rent_payments_select_policy" ON public.rent_payments
    FOR SELECT TO authenticated
    USING (
        landlord_id = auth.uid()
        OR tenant_id = auth.uid()
        OR public.is_agency_of_property(property_id, auth.uid())
    );

DROP POLICY IF EXISTS "rent_payments_insert_policy" ON public.rent_payments;
CREATE POLICY "rent_payments_insert_policy" ON public.rent_payments
    FOR INSERT TO authenticated
    WITH CHECK (
        landlord_id = auth.uid()
        OR public.is_agency_of_property(property_id, auth.uid())
    );

DROP POLICY IF EXISTS "rent_payments_update_policy" ON public.rent_payments;
DROP POLICY IF EXISTS "Landlords and tenants can update rent payments" ON public.rent_payments;
CREATE POLICY "rent_payments_update_policy" ON public.rent_payments
    FOR UPDATE TO authenticated
    USING (
        landlord_id = auth.uid()
        OR tenant_id = auth.uid()
        OR public.is_agency_of_property(property_id, auth.uid())
    );

-- 6c. Agency RLS access for invitations
DROP POLICY IF EXISTS "invitations_select_policy" ON public.invitations;
DROP POLICY IF EXISTS "Users can view invitations" ON public.invitations;
CREATE POLICY "invitations_select_policy" ON public.invitations
    FOR SELECT TO authenticated
    USING (
        inviter_id = auth.uid()
        OR public.is_agency_of_property(property_id, auth.uid())
        OR LOWER(invitee_email) = LOWER(COALESCE(auth.jwt()->>'email', ''))
    );

DROP POLICY IF EXISTS "invitations_insert_policy" ON public.invitations;
DROP POLICY IF EXISTS "Users can insert invitations" ON public.invitations;
CREATE POLICY "invitations_insert_policy" ON public.invitations
    FOR INSERT TO authenticated
    WITH CHECK (
        inviter_id = auth.uid()
        OR public.is_agency_of_property(property_id, auth.uid())
    );

-- 7. Recreate properties_with_names view to include newly added agency_id column
-- DROP VIEW CASCADE is required when column positions in p.* change
DROP VIEW IF EXISTS public.properties_with_names CASCADE;

CREATE VIEW public.properties_with_names AS
SELECT 
    p.*,
    l.full_name AS landlord_name,
    l.email AS landlord_email,
    t.full_name AS tenant_name,
    t.email AS tenant_email,
    a.company_name AS agency_name,
    a.email AS agency_email
FROM public.properties p
LEFT JOIN public.profiles l ON p.landlord_id = l.id
LEFT JOIN public.profiles t ON p.tenant_id = t.id
LEFT JOIN public.profiles a ON p.agency_id = a.id;

ALTER VIEW public.properties_with_names SET (security_invoker = on);

-- 8. Notify PostgREST to reload schema cache
NOTIFY pgrst, 'reload schema';
