-- Enable SELECT for tenants on properties table
-- Run this in the Supabase SQL Editor

-- Ensure RLS is enabled 
ALTER TABLE properties ENABLE ROW LEVEL SECURITY;

-- Allow landlords to see their properties
CREATE POLICY landlord_select_properties ON properties
FOR SELECT
USING (auth.uid() = landlord_id);

-- Allow tenants to see properties assigned to them
CREATE POLICY tenant_select_properties ON properties
FOR SELECT
USING (auth.uid() = tenant_id);

-- ALLOW UPDATES
-- Allow landlords to update their own properties
CREATE POLICY landlord_update_properties ON properties
FOR UPDATE
USING (auth.uid() = landlord_id)
WITH CHECK (auth.uid() = landlord_id);

-- Allow tenants to join a vacant property (set their tenant_id)
CREATE POLICY tenant_join_property ON properties
FOR UPDATE
USING (tenant_id IS NULL)
WITH CHECK (tenant_id = auth.uid());

-- Allow tenants to leave their own property (set their tenant_id to NULL)
CREATE POLICY tenant_leave_property ON properties
FOR UPDATE
USING (auth.uid() = tenant_id)
WITH CHECK (tenant_id IS NULL);

-- If policies already exist and you get an error, you can drop them first:
-- DROP POLICY IF EXISTS landlord_select_properties ON properties;
-- DROP POLICY IF EXISTS tenant_select_properties ON properties;
-- DROP POLICY IF EXISTS landlord_update_properties ON properties;
-- DROP POLICY IF EXISTS tenant_join_property ON properties;
