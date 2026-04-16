-- Enable SELECT for tenants and landlords on invitations table
-- Run this in the Supabase SQL Editor

-- Ensure RLS is enabled 
ALTER TABLE invitations ENABLE ROW LEVEL SECURITY;

-- Allow landlords (inviters) to see their invites
CREATE POLICY landlord_select_invites ON invitations
FOR SELECT
USING (auth.uid() = inviter_id);

-- Allow tenants (invitees) to see invites sent to their email
-- This uses the user's email from their auth session
CREATE POLICY tenant_select_invites ON invitations
FOR SELECT
USING (auth.jwt() ->> 'email' = invitee_email);

-- Allow landlords to manage (delete) their invites
CREATE POLICY landlord_manage_invites ON invitations
FOR ALL
USING (auth.uid() = inviter_id);

-- Allow tenants (invitees) to update an invitation to 'accepted'
CREATE POLICY tenant_update_invite ON invitations
FOR UPDATE
USING (auth.jwt() ->> 'email' = invitee_email)
WITH CHECK (status = 'accepted');

-- If policies already exist and you get an error, you can drop them first:
-- DROP POLICY IF EXISTS landlord_select_invites ON invitations;
-- DROP POLICY IF EXISTS tenant_select_invites ON invitations;
-- DROP POLICY IF EXISTS landlord_manage_invites ON invitations;
-- DROP POLICY IF EXISTS tenant_update_invite ON invitations;
