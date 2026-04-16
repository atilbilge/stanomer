-- Update leave_property RPC to handle both invitations and contracts
CREATE OR REPLACE FUNCTION leave_property(p_property_id uuid, p_invite_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
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

    -- 3. Clear tenant from property
    UPDATE properties
    SET tenant_id = NULL
    WHERE id = p_property_id;

    -- 4. Delete/Deactivate related invitations and contracts
    -- We delete legacy invitations
    DELETE FROM invitations
    WHERE property_id = p_property_id AND (id = p_invite_id OR LOWER(invitee_email) = (SELECT LOWER(email) FROM auth.users WHERE id = v_tenant_id));

    -- We set related active contracts to 'expired' or delete them? 
    -- Deleting pending/negotiating contracts if they match the invitee might be good
    DELETE FROM contracts
    WHERE property_id = p_property_id AND id = p_invite_id;
    
    -- If it was an active tenant leaving, we mark active contracts as expired
    UPDATE contracts
    SET status = 'expired'
    WHERE property_id = p_property_id AND status = 'active';

END;
$$;
