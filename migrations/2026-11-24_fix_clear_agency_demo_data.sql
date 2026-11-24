-- ==============================================================================
-- Migration: 2026-11-24_fix_clear_agency_demo_data.sql
-- Description:
--   1. Adds Portfolio & Distribution tables (listings, listing_images, agency_leads)
--      plus property_owners & invitations cleanup to public.clear_agency_demo_data().
--   2. Fixes demo landlord/tenant account matching to use the 8-char agency prefix
--      (landlord_<8char>_*@demo.stanomer.local / tenant_<8char>_*@demo.stanomer.local)
--      instead of the full UUID, so synthetic demo auth/profile accounts are actually deleted.
-- Target: Dev / Sandbox Supabase (nbcbfmhztnnhfnapvaet) ONLY — DO NOT run on Production!
-- Idempotent: Yes
-- ==============================================================================

CREATE OR REPLACE FUNCTION public.clear_agency_demo_data(p_agency_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_property_ids UUID[];
    v_contract_ids UUID[];
    v_request_ids UUID[];
    v_listing_ids UUID[];
    v_demo_user_ids UUID[];
    v_agency_short TEXT;
    v_prop_count INT := 0;
    v_listing_count INT := 0;
    v_lead_count INT := 0;
BEGIN
    v_agency_short := substring(p_agency_id::text from 1 for 8);

    -- 1. Property & Lease Management tables
    SELECT ARRAY_AGG(id) INTO v_property_ids
    FROM public.properties
    WHERE agency_id = p_agency_id;

    IF v_property_ids IS NOT NULL AND array_length(v_property_ids, 1) > 0 THEN
        v_prop_count := array_length(v_property_ids, 1);

        SELECT ARRAY_AGG(id) INTO v_contract_ids
        FROM public.contracts
        WHERE property_id = ANY(v_property_ids) OR agency_id = p_agency_id;

        SELECT ARRAY_AGG(id) INTO v_request_ids
        FROM public.maintenance_requests
        WHERE property_id = ANY(v_property_ids);

        IF v_request_ids IS NOT NULL THEN
            DELETE FROM public.maintenance_messages WHERE request_id = ANY(v_request_ids);
            DELETE FROM public.maintenance_charges WHERE maintenance_request_id = ANY(v_request_ids);
        END IF;

        DELETE FROM public.activity_logs WHERE property_id = ANY(v_property_ids);
        DELETE FROM public.maintenance_requests WHERE property_id = ANY(v_property_ids);
        DELETE FROM public.rent_payments WHERE property_id = ANY(v_property_ids);

        IF to_regclass('public.property_owners') IS NOT NULL THEN
            DELETE FROM public.property_owners WHERE property_id = ANY(v_property_ids);
        END IF;
        IF to_regclass('public.invitations') IS NOT NULL THEN
            DELETE FROM public.invitations WHERE property_id = ANY(v_property_ids);
        END IF;

        DELETE FROM public.contracts WHERE property_id = ANY(v_property_ids) OR agency_id = p_agency_id;
        DELETE FROM public.properties WHERE id = ANY(v_property_ids);
    END IF;

    -- 2. Portfolio & Distribution tables (listings, listing_images, agency_leads)
    IF to_regclass('public.listings') IS NOT NULL THEN
        SELECT ARRAY_AGG(id) INTO v_listing_ids
        FROM public.listings
        WHERE agency_id = p_agency_id;

        IF v_listing_ids IS NOT NULL AND array_length(v_listing_ids, 1) > 0 THEN
            v_listing_count := array_length(v_listing_ids, 1);
            IF to_regclass('public.listing_images') IS NOT NULL THEN
                DELETE FROM public.listing_images WHERE listing_id = ANY(v_listing_ids);
            END IF;
            DELETE FROM public.listings WHERE id = ANY(v_listing_ids);
        END IF;
    END IF;

    IF to_regclass('public.agency_leads') IS NOT NULL THEN
        DELETE FROM public.agency_leads WHERE agency_id = p_agency_id::text;
        GET DIAGNOSTICS v_lead_count = ROW_COUNT;
    END IF;

    -- 3. Synthetic demo landlords & tenants (matched via 8-char prefix OR full UUID)
    SELECT ARRAY_AGG(id) INTO v_demo_user_ids
    FROM public.profiles
    WHERE email LIKE '%@demo.stanomer.local'
      AND (
          email LIKE ('%_' || v_agency_short || '_%@demo.stanomer.local')
          OR email LIKE ('%' || p_agency_id::text || '%')
      );

    IF v_demo_user_ids IS NOT NULL AND array_length(v_demo_user_ids, 1) > 0 THEN
        DELETE FROM public.profiles WHERE id = ANY(v_demo_user_ids);
        DELETE FROM auth.users WHERE id = ANY(v_demo_user_ids);
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'agency_id', p_agency_id,
        'deleted_properties_count', v_prop_count,
        'deleted_listings_count', v_listing_count,
        'deleted_leads_count', v_lead_count
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.clear_agency_demo_data(UUID) TO anon, authenticated, service_role;
