-- ============================================================================
-- MIGRATION: 2026-07-29 — Allow Token-Based Invitation & Contract RLS Lookup
-- Target: Dev DB (thvbpifahvasyzmngpzp)
-- Reason: Enables tenants scanning QR codes or entering raw tokens/URLs to
-- query contracts & property details before accepting, regardless of invitee_email.
-- ============================================================================

DROP POLICY IF EXISTS "contracts_select_policy" ON public.contracts;
CREATE POLICY "contracts_select_policy" ON public.contracts FOR SELECT TO authenticated
    USING (
        landlord_id = auth.uid()
        OR tenant_id = auth.uid()
        OR agency_id = auth.uid()
        OR (invitee_email IS NOT NULL AND LOWER(invitee_email) = LOWER(COALESCE(auth.jwt()->>'email', '')))
        OR (token IS NOT NULL)
    );

DROP POLICY IF EXISTS "invitations_select_policy" ON public.invitations;
DROP POLICY IF EXISTS "Users can view invitations" ON public.invitations;
CREATE POLICY "invitations_select_policy" ON public.invitations FOR SELECT TO authenticated
    USING (
        inviter_id = auth.uid()
        OR public.is_agency_of_property(property_id, auth.uid())
        OR LOWER(invitee_email) = LOWER(COALESCE(auth.jwt()->>'email', ''))
        OR (token IS NOT NULL)
    );

DROP POLICY IF EXISTS "properties_select_policy" ON public.properties;
CREATE POLICY "properties_select_policy" ON public.properties FOR SELECT TO authenticated
    USING (
        landlord_id = auth.uid()
        OR tenant_id = auth.uid()
        OR agency_id = auth.uid()
        OR EXISTS (SELECT 1 FROM public.invitations i WHERE i.property_id = properties.id AND (LOWER(i.invitee_email) = LOWER(COALESCE(auth.jwt()->>'email', '')) OR i.token IS NOT NULL))
        OR EXISTS (SELECT 1 FROM public.contracts c WHERE c.property_id = properties.id AND (c.tenant_id = auth.uid() OR (c.invitee_email IS NOT NULL AND LOWER(c.invitee_email) = LOWER(COALESCE(auth.jwt()->>'email', ''))) OR c.token IS NOT NULL))
    );
