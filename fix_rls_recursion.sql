-- ============================================================================
-- FIX RLS INFINITE RECURSION (ERROR 42P17) FOR PROPERTIES & INVITATIONS
-- ============================================================================

-- 1. DROP ALL CONFLICTING POLICIES ON properties
DROP POLICY IF EXISTS "landlord_select_properties" ON public.properties;
DROP POLICY IF EXISTS "tenant_select_properties" ON public.properties;
DROP POLICY IF EXISTS "tenant_view_invited_properties" ON public.properties;
DROP POLICY IF EXISTS "tenant_view_properties" ON public.properties;
DROP POLICY IF EXISTS "Landlords and tenants can view properties" ON public.properties;
DROP POLICY IF EXISTS "landlord_update_properties" ON public.properties;
DROP POLICY IF EXISTS "tenant_join_property" ON public.properties;
DROP POLICY IF EXISTS "tenant_leave_property" ON public.properties;
DROP POLICY IF EXISTS "Landlords can insert properties" ON public.properties;
DROP POLICY IF EXISTS "Landlords can delete properties" ON public.properties;
DROP POLICY IF EXISTS "properties_select_policy" ON public.properties;
DROP POLICY IF EXISTS "properties_insert_policy" ON public.properties;
DROP POLICY IF EXISTS "properties_update_policy" ON public.properties;
DROP POLICY IF EXISTS "properties_delete_policy" ON public.properties;

-- 2. DROP ALL CONFLICTING POLICIES ON invitations
DROP POLICY IF EXISTS "Users can view invitations" ON public.invitations;
DROP POLICY IF EXISTS "Users can insert invitations" ON public.invitations;
DROP POLICY IF EXISTS "invitations_select_policy" ON public.invitations;
DROP POLICY IF EXISTS "invitations_insert_policy" ON public.invitations;
DROP POLICY IF EXISTS "invitations_update_policy" ON public.invitations;
DROP POLICY IF EXISTS "landlord_select_invites" ON public.invitations;
DROP POLICY IF EXISTS "tenant_select_invites" ON public.invitations;
DROP POLICY IF EXISTS "landlord_manage_invites" ON public.invitations;
DROP POLICY IF EXISTS "tenant_update_invite" ON public.invitations;

-- 3. CREATE CLEAN NON-RECURSIVE POLICIES FOR properties
CREATE POLICY "properties_select_policy" ON public.properties
FOR SELECT TO authenticated
USING (
    landlord_id = auth.uid() 
    OR tenant_id = auth.uid()
    OR EXISTS (
        SELECT 1 FROM public.invitations i 
        WHERE i.property_id = properties.id 
        AND LOWER(i.invitee_email) = LOWER(COALESCE(auth.jwt()->>'email', ''))
    )
);

CREATE POLICY "properties_insert_policy" ON public.properties
FOR INSERT TO authenticated
WITH CHECK (landlord_id = auth.uid());

CREATE POLICY "properties_update_policy" ON public.properties
FOR UPDATE TO authenticated
USING (
    landlord_id = auth.uid() 
    OR tenant_id = auth.uid() 
    OR tenant_id IS NULL
);

CREATE POLICY "properties_delete_policy" ON public.properties
FOR DELETE TO authenticated
USING (landlord_id = auth.uid());

-- 4. CREATE CLEAN NON-RECURSIVE POLICIES FOR invitations (NO QUERY TO properties)
CREATE POLICY "invitations_select_policy" ON public.invitations
FOR SELECT TO authenticated
USING (true);

CREATE POLICY "invitations_insert_policy" ON public.invitations
FOR INSERT TO authenticated
WITH CHECK (true);

CREATE POLICY "invitations_update_policy" ON public.invitations
FOR UPDATE TO authenticated
USING (true);
