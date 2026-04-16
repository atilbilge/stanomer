-- Fix for Tenant Visibility:
-- This policy allows tenants to see property details for invitations/contracts they are part of.
-- Without this, the 'properties' join returns null, and the UI hides the invitation card.

DROP POLICY IF EXISTS tenant_view_invited_properties ON properties;

CREATE POLICY tenant_view_invited_properties ON properties
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM contracts
    WHERE contracts.property_id = properties.id
    AND LOWER(contracts.invitee_email) = LOWER(auth.jwt() ->> 'email')
  )
);
