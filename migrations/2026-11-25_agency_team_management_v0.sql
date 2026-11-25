-- Migration: Agency Team Management v0 (Agency Admin + Agency Operations multi-user login)
-- Target: Dev Supabase (nbcbfmhztnnhfnapvaet)
-- Idempotent & backward-compatible: existing `agency` accounts act as Agency Admin automatically.

BEGIN;

-- 1. Create public.agency_members table
CREATE TABLE IF NOT EXISTS public.agency_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agency_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    full_name TEXT,
    phone_number TEXT,
    member_role TEXT NOT NULL DEFAULT 'agency_operation' CHECK (member_role IN ('agency_operation')),
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'suspended', 'revoked')),
    invited_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (agency_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_agency_members_agency_id ON public.agency_members(agency_id);
CREATE INDEX IF NOT EXISTS idx_agency_members_user_id ON public.agency_members(user_id);

ALTER TABLE public.agency_members ENABLE ROW LEVEL SECURITY;

-- Only Agency Admin (agency_id = auth.uid()) can manage team members; members can read their own row
DROP POLICY IF EXISTS "Agency admins and members can view memberships" ON public.agency_members;
CREATE POLICY "Agency admins and members can view memberships" ON public.agency_members
    FOR SELECT TO authenticated
    USING (agency_id = auth.uid() OR user_id = auth.uid());

DROP POLICY IF EXISTS "Agency admins can insert team members" ON public.agency_members;
CREATE POLICY "Agency admins can insert team members" ON public.agency_members
    FOR INSERT TO authenticated
    WITH CHECK (agency_id = auth.uid());

DROP POLICY IF EXISTS "Agency admins can update team members" ON public.agency_members;
CREATE POLICY "Agency admins can update team members" ON public.agency_members
    FOR UPDATE TO authenticated
    USING (agency_id = auth.uid())
    WITH CHECK (agency_id = auth.uid());

DROP POLICY IF EXISTS "Agency admins can delete team members" ON public.agency_members;
CREATE POLICY "Agency admins can delete team members" ON public.agency_members
    FOR DELETE TO authenticated
    USING (agency_id = auth.uid());

-- 2. Helper functions: effective_agency_id & is_agency_member
CREATE OR REPLACE FUNCTION public.effective_agency_id(p_user_id UUID DEFAULT auth.uid())
RETURNS UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(
    (
      SELECT am.agency_id
      FROM public.agency_members am
      WHERE am.user_id = p_user_id
        AND am.status = 'active'
      ORDER BY am.created_at ASC
      LIMIT 1
    ),
    p_user_id
  );
$$;

CREATE OR REPLACE FUNCTION public.is_agency_member(p_agency_id UUID, p_user_id UUID DEFAULT auth.uid())
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT p_agency_id IS NOT NULL AND (
    p_agency_id = p_user_id
    OR EXISTS (
      SELECT 1
      FROM public.agency_members am
      WHERE am.agency_id = p_agency_id
        AND am.user_id = p_user_id
        AND am.status = 'active'
    )
  );
$$;

-- 3. Update is_agency_of_property to include active agency_members
CREATE OR REPLACE FUNCTION public.is_agency_of_property(check_property_id UUID, check_user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_result BOOLEAN := FALSE;
BEGIN
  IF to_regclass('public.properties') IS NULL THEN
    RETURN FALSE;
  END IF;
  EXECUTE 'SELECT EXISTS (
    SELECT 1 FROM public.properties
    WHERE id = $1
      AND public.is_agency_member(agency_id, $2)
  )' INTO v_result USING check_property_id, check_user_id;
  RETURN v_result;
END;
$$;

-- 4. Additive RLS policies so active agency_operation members can access their parent agency's data
-- (v0: same operational permissions as agency admin, except managing agency_members)

DO $$
BEGIN
  IF to_regclass('public.properties') IS NOT NULL THEN
    DROP POLICY IF EXISTS "Agency members can manage agency properties" ON public.properties;
    CREATE POLICY "Agency members can manage agency properties" ON public.properties
      FOR ALL TO authenticated
      USING (public.is_agency_member(agency_id, auth.uid()))
      WITH CHECK (public.is_agency_member(agency_id, auth.uid()));
  END IF;

  IF to_regclass('public.contracts') IS NOT NULL THEN
    DROP POLICY IF EXISTS "Agency members can manage agency contracts" ON public.contracts;
    CREATE POLICY "Agency members can manage agency contracts" ON public.contracts
      FOR ALL TO authenticated
      USING (public.is_agency_member(agency_id, auth.uid()) OR public.is_agency_of_property(property_id, auth.uid()))
      WITH CHECK (public.is_agency_member(agency_id, auth.uid()) OR public.is_agency_of_property(property_id, auth.uid()));
  END IF;

  IF to_regclass('public.rent_payments') IS NOT NULL THEN
    DROP POLICY IF EXISTS "Agency members can manage agency rent_payments" ON public.rent_payments;
    CREATE POLICY "Agency members can manage agency rent_payments" ON public.rent_payments
      FOR ALL TO authenticated
      USING (public.is_agency_member(agency_id, auth.uid()) OR public.is_agency_of_property(property_id, auth.uid()))
      WITH CHECK (public.is_agency_member(agency_id, auth.uid()) OR public.is_agency_of_property(property_id, auth.uid()));
  END IF;

  IF to_regclass('public.listings') IS NOT NULL THEN
    DROP POLICY IF EXISTS "Agency members can manage agency listings" ON public.listings;
    CREATE POLICY "Agency members can manage agency listings" ON public.listings
      FOR ALL TO authenticated
      USING (public.is_agency_member(agency_id, auth.uid()))
      WITH CHECK (public.is_agency_member(agency_id, auth.uid()));
  END IF;

  IF to_regclass('public.listing_images') IS NOT NULL THEN
    DROP POLICY IF EXISTS "Agency members can manage agency listing_images" ON public.listing_images;
    CREATE POLICY "Agency members can manage agency listing_images" ON public.listing_images
      FOR ALL TO authenticated
      USING (EXISTS (SELECT 1 FROM public.listings l WHERE l.id = listing_images.listing_id AND public.is_agency_member(l.agency_id, auth.uid())))
      WITH CHECK (EXISTS (SELECT 1 FROM public.listings l WHERE l.id = listing_images.listing_id AND public.is_agency_member(l.agency_id, auth.uid())));
  END IF;

  IF to_regclass('public.agency_leads') IS NOT NULL THEN
    DROP POLICY IF EXISTS "Agency members can manage agency leads" ON public.agency_leads;
    CREATE POLICY "Agency members can manage agency leads" ON public.agency_leads
      FOR ALL TO authenticated
      USING (agency_id = public.effective_agency_id(auth.uid())::text)
      WITH CHECK (agency_id = public.effective_agency_id(auth.uid())::text);
  END IF;

  IF to_regclass('public.maintenance_requests') IS NOT NULL THEN
    DROP POLICY IF EXISTS "Agency members can manage agency maintenance_requests" ON public.maintenance_requests;
    CREATE POLICY "Agency members can manage agency maintenance_requests" ON public.maintenance_requests
      FOR ALL TO authenticated
      USING (public.is_agency_of_property(property_id, auth.uid()))
      WITH CHECK (public.is_agency_of_property(property_id, auth.uid()));
  END IF;

  IF to_regclass('public.maintenance_messages') IS NOT NULL THEN
    DROP POLICY IF EXISTS "Agency members can manage agency maintenance_messages" ON public.maintenance_messages;
    CREATE POLICY "Agency members can manage agency maintenance_messages" ON public.maintenance_messages
      FOR ALL TO authenticated
      USING (EXISTS (SELECT 1 FROM public.maintenance_requests r WHERE r.id = maintenance_messages.request_id AND public.is_agency_of_property(r.property_id, auth.uid())))
      WITH CHECK (EXISTS (SELECT 1 FROM public.maintenance_requests r WHERE r.id = maintenance_messages.request_id AND public.is_agency_of_property(r.property_id, auth.uid())));
  END IF;

  IF to_regclass('public.activity_logs') IS NOT NULL THEN
    DROP POLICY IF EXISTS "Agency members can manage agency activity_logs" ON public.activity_logs;
    CREATE POLICY "Agency members can manage agency activity_logs" ON public.activity_logs
      FOR ALL TO authenticated
      USING (public.is_agency_of_property(property_id, auth.uid()))
      WITH CHECK (public.is_agency_of_property(property_id, auth.uid()));
  END IF;

  IF to_regclass('public.invitations') IS NOT NULL THEN
    DROP POLICY IF EXISTS "Agency members can manage agency invitations" ON public.invitations;
    CREATE POLICY "Agency members can manage agency invitations" ON public.invitations
      FOR ALL TO authenticated
      USING (public.is_agency_member(agency_id, auth.uid()) OR public.is_agency_of_property(property_id, auth.uid()))
      WITH CHECK (public.is_agency_member(agency_id, auth.uid()) OR public.is_agency_of_property(property_id, auth.uid()));
  END IF;

  IF to_regclass('public.property_owners') IS NOT NULL THEN
    DROP POLICY IF EXISTS "Agency members can manage agency property_owners" ON public.property_owners;
    CREATE POLICY "Agency members can manage agency property_owners" ON public.property_owners
      FOR ALL TO authenticated
      USING (public.is_agency_of_property(property_id, auth.uid()))
      WITH CHECK (public.is_agency_of_property(property_id, auth.uid()));
  END IF;

  IF to_regclass('public.agency_invoices') IS NOT NULL THEN
    DROP POLICY IF EXISTS "Agency members can view agency invoices" ON public.agency_invoices;
    CREATE POLICY "Agency members can view agency invoices" ON public.agency_invoices
      FOR SELECT TO authenticated
      USING (public.is_agency_member(agency_id, auth.uid()));
  END IF;
END $$;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.agency_members TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.effective_agency_id(UUID) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.is_agency_member(UUID, UUID) TO authenticated, service_role;

COMMIT;

NOTIFY pgrst, 'reload schema';
