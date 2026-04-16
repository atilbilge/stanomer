-- This function allows a tenant to leave or a landlord to remove a tenant atomically.
-- It bypasses client-side RLS restrictions by using SECURITY DEFINER.
CREATE OR REPLACE FUNCTION leave_property(p_property_id uuid, p_invite_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER -- Runs with creator (superuser) permissions
AS $$
DECLARE
    v_landlord_id uuid;
    v_tenant_id uuid;
BEGIN
    -- 1. Get property ownership info
    SELECT landlord_id, tenant_id INTO v_landlord_id, v_tenant_id
    FROM properties
    WHERE id = p_property_id;

    -- 2. Security Check: Only the landlord or the current tenant can call this
    IF auth.uid() != v_landlord_id AND auth.uid() != v_tenant_id THEN
        RAISE EXCEPTION 'Unauthorized: Only the landlord or the tenant of this property can perform this action.';
    END IF;

    -- 3. Atomically clear the property and delete the invitation
    
    -- Clear tenant from property
    UPDATE properties
    SET tenant_id = NULL
    WHERE id = p_property_id;

    -- Delete the specific invitation record
    DELETE FROM invitations
    WHERE id = p_invite_id AND property_id = p_property_id;

END;
$$;
