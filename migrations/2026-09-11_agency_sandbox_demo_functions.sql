-- ==============================================================================
-- STANOMER MIGRATION: AGENCY SANDBOX & DEMO ENVIRONMENT FUNCTIONS
-- Target: DEV ONLY (thvbpifahvasyzmngpzp)
-- Date: 2026-09-11
--
-- Features:
--   1. Add is_demo, demo_expires_at, website_url to public.profiles
--   2. Fix auth.users empty string tokens to prevent GoTrue 500 "Database error querying schema"
--   3. public.clear_agency_demo_data(p_agency_id UUID)
--   4. public.generate_agency_demo_data(p_agency_id UUID)
--   5. public.verify_agency_demo_token(p_token UUID)
--   6. public.cleanup_expired_demo_data()
-- ==============================================================================

-- 1. Schema Extensions
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS is_demo BOOLEAN DEFAULT FALSE;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS demo_expires_at TIMESTAMPTZ DEFAULT NULL;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS website_url TEXT DEFAULT NULL;

-- 2. Fix GoTrue 500 "Database error querying schema"
-- Supabase Auth daemon (GoTrue) fails when token columns in auth.users are NULL.
UPDATE auth.users
SET confirmation_token = COALESCE(confirmation_token, ''),
    recovery_token = COALESCE(recovery_token, ''),
    email_change_token_new = COALESCE(email_change_token_new, ''),
    email_change = COALESCE(email_change, ''),
    email_change_token_current = COALESCE(email_change_token_current, ''),
    reauthentication_token = COALESCE(reauthentication_token, ''),
    phone_change = COALESCE(phone_change, ''),
    phone_change_token = COALESCE(phone_change_token, '')
WHERE confirmation_token IS NULL
   OR recovery_token IS NULL
   OR email_change_token_new IS NULL
   OR email_change IS NULL
   OR email_change_token_current IS NULL
   OR reauthentication_token IS NULL;

-- 3. Clear Agency Demo Data Function
CREATE OR REPLACE FUNCTION public.clear_agency_demo_data(p_agency_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_property_ids UUID[];
    v_contract_ids UUID[];
    v_request_ids UUID[];
    v_landlord_ids UUID[];
    v_prop_count INT := 0;
BEGIN
    -- Find properties belonging to this agency
    SELECT ARRAY_AGG(id) INTO v_property_ids
    FROM public.properties
    WHERE agency_id = p_agency_id;

    IF v_property_ids IS NOT NULL AND array_length(v_property_ids, 1) > 0 THEN
        v_prop_count := array_length(v_property_ids, 1);

        -- Find contracts
        SELECT ARRAY_AGG(id) INTO v_contract_ids
        FROM public.contracts
        WHERE property_id = ANY(v_property_ids) OR agency_id = p_agency_id;

        -- Find maintenance requests
        SELECT ARRAY_AGG(id) INTO v_request_ids
        FROM public.maintenance_requests
        WHERE property_id = ANY(v_property_ids);

        -- Delete maintenance messages & charges & activity logs
        IF v_request_ids IS NOT NULL THEN
            DELETE FROM public.maintenance_messages WHERE request_id = ANY(v_request_ids);
            DELETE FROM public.maintenance_charges WHERE maintenance_request_id = ANY(v_request_ids);
        END IF;
        DELETE FROM public.activity_logs WHERE property_id = ANY(v_property_ids);

        -- Delete maintenance requests
        DELETE FROM public.maintenance_requests WHERE property_id = ANY(v_property_ids);

        -- Delete rent payments
        DELETE FROM public.rent_payments WHERE property_id = ANY(v_property_ids);

        -- Delete contracts
        DELETE FROM public.contracts WHERE property_id = ANY(v_property_ids) OR agency_id = p_agency_id;

        -- Delete properties
        DELETE FROM public.properties WHERE id = ANY(v_property_ids);
    END IF;

    -- Clean up demo dummy landlords and tenants linked to this agency
    SELECT ARRAY_AGG(id) INTO v_landlord_ids
    FROM auth.users
    WHERE email LIKE ('%_' || substring(p_agency_id::text from 1 for 8) || '_%@demo.stanomer.local');

    IF v_landlord_ids IS NOT NULL AND array_length(v_landlord_ids, 1) > 0 THEN
        DELETE FROM public.profiles WHERE id = ANY(v_landlord_ids);
        DELETE FROM auth.identities WHERE user_id = ANY(v_landlord_ids);
        DELETE FROM auth.users WHERE id = ANY(v_landlord_ids);
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'agency_id', p_agency_id,
        'deleted_properties_count', v_prop_count
    );
END;
$$;

-- 4. Generate Agency Demo Data Function
CREATE OR REPLACE FUNCTION public.generate_agency_demo_data(p_agency_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    -- Landlords
    v_l1 UUID := gen_random_uuid();
    v_l2 UUID := gen_random_uuid();
    v_l3 UUID := gen_random_uuid();
    v_l4 UUID := gen_random_uuid();
    v_l5 UUID := gen_random_uuid();
    v_l6 UUID := gen_random_uuid();
    v_l7 UUID := gen_random_uuid();

    -- Tenants
    v_t1 UUID := gen_random_uuid();
    v_t2 UUID := gen_random_uuid();
    v_t3 UUID := gen_random_uuid();
    v_t4 UUID := gen_random_uuid();
    v_t5 UUID := gen_random_uuid();
    v_t6 UUID := gen_random_uuid();
    v_t7 UUID := gen_random_uuid();
    v_t8 UUID := gen_random_uuid();
    v_t9 UUID := gen_random_uuid();
    v_t10 UUID := gen_random_uuid();

    -- Properties
    v_p1 UUID := gen_random_uuid();
    v_p2 UUID := gen_random_uuid();
    v_p3 UUID := gen_random_uuid();
    v_p4 UUID := gen_random_uuid();
    v_p5 UUID := gen_random_uuid();
    v_p6 UUID := gen_random_uuid();
    v_p7 UUID := gen_random_uuid();
    v_p8 UUID := gen_random_uuid();
    v_p9 UUID := gen_random_uuid();
    v_p10 UUID := gen_random_uuid();

    -- Contracts
    v_c1 UUID := gen_random_uuid();
    v_c2 UUID := gen_random_uuid();
    v_c3 UUID := gen_random_uuid();
    v_c4 UUID := gen_random_uuid();
    v_c5 UUID := gen_random_uuid();
    v_c6 UUID := gen_random_uuid();
    v_c7 UUID := gen_random_uuid();
    v_c8 UUID := gen_random_uuid();
    v_c9 UUID := gen_random_uuid();
    v_c10 UUID := gen_random_uuid();

    -- Maintenance Requests
    v_mr1 UUID := gen_random_uuid();
    v_mr2 UUID := gen_random_uuid();
    v_mr3 UUID := gen_random_uuid();
    v_mr4 UUID := gen_random_uuid();
    v_mr5 UUID := gen_random_uuid();

    v_agency_short TEXT;
    v_agency_name TEXT;
    v_instance_id UUID;
BEGIN
    -- Verify target agency exists
    SELECT COALESCE(company_name, full_name, 'Agency') INTO v_agency_name
    FROM public.profiles
    WHERE id = p_agency_id;

    IF v_agency_name IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Agency profile not found for provided ID');
    END IF;

    v_agency_short := substring(p_agency_id::text from 1 for 8);

    SELECT instance_id INTO v_instance_id FROM auth.users WHERE instance_id IS NOT NULL LIMIT 1;
    IF v_instance_id IS NULL THEN
        v_instance_id := '00000000-0000-0000-0000-000000000000'::uuid;
    END IF;

    -- Mark agency profile as active demo
    UPDATE public.profiles
    SET is_demo = TRUE,
        demo_expires_at = (now() + interval '3 days'),
        updated_at = now()
    WHERE id = p_agency_id;

    -- Clean any existing demo data first to ensure 100% idempotent generation
    PERFORM public.clear_agency_demo_data(p_agency_id);

    -- --------------------------------------------------------------------------
    -- 1. Create 7 Landlords
    -- --------------------------------------------------------------------------
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        confirmation_token, recovery_token, email_change_token_new, email_change,
        email_change_token_current, reauthentication_token, phone_change, phone_change_token,
        raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    ) VALUES
        (v_l1, v_instance_id, 'authenticated', 'authenticated', 'landlord_' || v_agency_short || '_1@demo.stanomer.local', extensions.crypt('Stanomer2026!', extensions.gen_salt('bf')), now(), '', '', '', '', '', '', '', '', '{"provider":"email"}'::jsonb, '{"full_name":"Miloš Petrović","role":"landlord"}'::jsonb, now(), now()),
        (v_l2, v_instance_id, 'authenticated', 'authenticated', 'landlord_' || v_agency_short || '_2@demo.stanomer.local', extensions.crypt('Stanomer2026!', extensions.gen_salt('bf')), now(), '', '', '', '', '', '', '', '', '{"provider":"email"}'::jsonb, '{"full_name":"Jelena Đorđević","role":"landlord"}'::jsonb, now(), now()),
        (v_l3, v_instance_id, 'authenticated', 'authenticated', 'landlord_' || v_agency_short || '_3@demo.stanomer.local', extensions.crypt('Stanomer2026!', extensions.gen_salt('bf')), now(), '', '', '', '', '', '', '', '', '{"provider":"email"}'::jsonb, '{"full_name":"Dragan Nikolić","role":"landlord"}'::jsonb, now(), now()),
        (v_l4, v_instance_id, 'authenticated', 'authenticated', 'landlord_' || v_agency_short || '_4@demo.stanomer.local', extensions.crypt('Stanomer2026!', extensions.gen_salt('bf')), now(), '', '', '', '', '', '', '', '', '{"provider":"email"}'::jsonb, '{"full_name":"Marija Vasić","role":"landlord"}'::jsonb, now(), now()),
        (v_l5, v_instance_id, 'authenticated', 'authenticated', 'landlord_' || v_agency_short || '_5@demo.stanomer.local', extensions.crypt('Stanomer2026!', extensions.gen_salt('bf')), now(), '', '', '', '', '', '', '', '', '{"provider":"email"}'::jsonb, '{"full_name":"Zoran Stojanović","role":"landlord"}'::jsonb, now(), now()),
        (v_l6, v_instance_id, 'authenticated', 'authenticated', 'landlord_' || v_agency_short || '_6@demo.stanomer.local', extensions.crypt('Stanomer2026!', extensions.gen_salt('bf')), now(), '', '', '', '', '', '', '', '', '{"provider":"email"}'::jsonb, '{"full_name":"Snežana Popović","role":"landlord"}'::jsonb, now(), now()),
        (v_l7, v_instance_id, 'authenticated', 'authenticated', 'landlord_' || v_agency_short || '_7@demo.stanomer.local', extensions.crypt('Stanomer2026!', extensions.gen_salt('bf')), now(), '', '', '', '', '', '', '', '', '{"provider":"email"}'::jsonb, '{"full_name":"Nenad Kovačević","role":"landlord"}'::jsonb, now(), now());

    INSERT INTO public.profiles (id, email, full_name, phone_number, role, active_role, created_at, updated_at)
    VALUES
        (v_l1, 'landlord_' || v_agency_short || '_1@demo.stanomer.local', 'Miloš Petrović', '+381641122331', 'landlord', 'landlord', now(), now()),
        (v_l2, 'landlord_' || v_agency_short || '_2@demo.stanomer.local', 'Jelena Đorđević', '+381641122332', 'landlord', 'landlord', now(), now()),
        (v_l3, 'landlord_' || v_agency_short || '_3@demo.stanomer.local', 'Dragan Nikolić', '+381641122333', 'landlord', 'landlord', now(), now()),
        (v_l4, 'landlord_' || v_agency_short || '_4@demo.stanomer.local', 'Marija Vasić', '+381641122334', 'landlord', 'landlord', now(), now()),
        (v_l5, 'landlord_' || v_agency_short || '_5@demo.stanomer.local', 'Zoran Stojanović', '+381641122335', 'landlord', 'landlord', now(), now()),
        (v_l6, 'landlord_' || v_agency_short || '_6@demo.stanomer.local', 'Snežana Popović', '+381641122336', 'landlord', 'landlord', now(), now()),
        (v_l7, 'landlord_' || v_agency_short || '_7@demo.stanomer.local', 'Nenad Kovačević', '+381641122337', 'landlord', 'landlord', now(), now())
    ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        full_name = EXCLUDED.full_name,
        phone_number = EXCLUDED.phone_number,
        role = EXCLUDED.role,
        active_role = EXCLUDED.active_role,
        updated_at = now();

    -- --------------------------------------------------------------------------
    -- 2. Create 10 Tenants
    -- --------------------------------------------------------------------------
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        confirmation_token, recovery_token, email_change_token_new, email_change,
        email_change_token_current, reauthentication_token, phone_change, phone_change_token,
        raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    ) VALUES
        (v_t1, v_instance_id, 'authenticated', 'authenticated', 'tenant_' || v_agency_short || '_1@demo.stanomer.local', extensions.crypt('Stanomer2026!', extensions.gen_salt('bf')), now(), '', '', '', '', '', '', '', '', '{"provider":"email"}'::jsonb, '{"full_name":"Nikola Marković","role":"tenant"}'::jsonb, now(), now()),
        (v_t2, v_instance_id, 'authenticated', 'authenticated', 'tenant_' || v_agency_short || '_2@demo.stanomer.local', extensions.crypt('Stanomer2026!', extensions.gen_salt('bf')), now(), '', '', '', '', '', '', '', '', '{"provider":"email"}'::jsonb, '{"full_name":"Ana Simić","role":"tenant"}'::jsonb, now(), now()),
        (v_t3, v_instance_id, 'authenticated', 'authenticated', 'tenant_' || v_agency_short || '_3@demo.stanomer.local', extensions.crypt('Stanomer2026!', extensions.gen_salt('bf')), now(), '', '', '', '', '', '', '', '', '{"provider":"email"}'::jsonb, '{"full_name":"Stefan Ilić","role":"tenant"}'::jsonb, now(), now()),
        (v_t4, v_instance_id, 'authenticated', 'authenticated', 'tenant_' || v_agency_short || '_4@demo.stanomer.local', extensions.crypt('Stanomer2026!', extensions.gen_salt('bf')), now(), '', '', '', '', '', '', '', '', '{"provider":"email"}'::jsonb, '{"full_name":"Milica Todorović","role":"tenant"}'::jsonb, now(), now()),
        (v_t5, v_instance_id, 'authenticated', 'authenticated', 'tenant_' || v_agency_short || '_5@demo.stanomer.local', extensions.crypt('Stanomer2026!', extensions.gen_salt('bf')), now(), '', '', '', '', '', '', '', '', '{"provider":"email"}'::jsonb, '{"full_name":"Aleksandar Jovanović","role":"tenant"}'::jsonb, now(), now()),
        (v_t6, v_instance_id, 'authenticated', 'authenticated', 'tenant_' || v_agency_short || '_6@demo.stanomer.local', extensions.crypt('Stanomer2026!', extensions.gen_salt('bf')), now(), '', '', '', '', '', '', '', '', '{"provider":"email"}'::jsonb, '{"full_name":"Tamara Lukić","role":"tenant"}'::jsonb, now(), now()),
        (v_t7, v_instance_id, 'authenticated', 'authenticated', 'tenant_' || v_agency_short || '_7@demo.stanomer.local', extensions.crypt('Stanomer2026!', extensions.gen_salt('bf')), now(), '', '', '', '', '', '', '', '', '{"provider":"email"}'::jsonb, '{"full_name":"Vladimir Pavlović","role":"tenant"}'::jsonb, now(), now()),
        (v_t8, v_instance_id, 'authenticated', 'authenticated', 'tenant_' || v_agency_short || '_8@demo.stanomer.local', extensions.crypt('Stanomer2026!', extensions.gen_salt('bf')), now(), '', '', '', '', '', '', '', '', '{"provider":"email"}'::jsonb, '{"full_name":"Jovana Bogdanović","role":"tenant"}'::jsonb, now(), now()),
        (v_t9, v_instance_id, 'authenticated', 'authenticated', 'tenant_' || v_agency_short || '_9@demo.stanomer.local', extensions.crypt('Stanomer2026!', extensions.gen_salt('bf')), now(), '', '', '', '', '', '', '', '', '{"provider":"email"}'::jsonb, '{"full_name":"Luka Lazarević","role":"tenant"}'::jsonb, now(), now()),
        (v_t10, v_instance_id, 'authenticated', 'authenticated', 'tenant_' || v_agency_short || '_10@demo.stanomer.local', extensions.crypt('Stanomer2026!', extensions.gen_salt('bf')), now(), '', '', '', '', '', '', '', '', '{"provider":"email"}'::jsonb, '{"full_name":"Sara Savić","role":"tenant"}'::jsonb, now(), now());

    INSERT INTO public.profiles (id, email, full_name, phone_number, role, active_role, created_at, updated_at)
    VALUES
        (v_t1, 'tenant_' || v_agency_short || '_1@demo.stanomer.local', 'Nikola Marković', '+381652233441', 'tenant', 'tenant', now(), now()),
        (v_t2, 'tenant_' || v_agency_short || '_2@demo.stanomer.local', 'Ana Simić', '+381652233442', 'tenant', 'tenant', now(), now()),
        (v_t3, 'tenant_' || v_agency_short || '_3@demo.stanomer.local', 'Stefan Ilić', '+381652233443', 'tenant', 'tenant', now(), now()),
        (v_t4, 'tenant_' || v_agency_short || '_4@demo.stanomer.local', 'Milica Todorović', '+381652233444', 'tenant', 'tenant', now(), now()),
        (v_t5, 'tenant_' || v_agency_short || '_5@demo.stanomer.local', 'Aleksandar Jovanović', '+381652233445', 'tenant', 'tenant', now(), now()),
        (v_t6, 'tenant_' || v_agency_short || '_6@demo.stanomer.local', 'Tamara Lukić', '+381652233446', 'tenant', 'tenant', now(), now()),
        (v_t7, 'tenant_' || v_agency_short || '_7@demo.stanomer.local', 'Vladimir Pavlović', '+381652233447', 'tenant', 'tenant', now(), now()),
        (v_t8, 'tenant_' || v_agency_short || '_8@demo.stanomer.local', 'Jovana Bogdanović', '+381652233448', 'tenant', 'tenant', now(), now()),
        (v_t9, 'tenant_' || v_agency_short || '_9@demo.stanomer.local', 'Luka Lazarević', '+381652233449', 'tenant', 'tenant', now(), now()),
        (v_t10, 'tenant_' || v_agency_short || '_10@demo.stanomer.local', 'Sara Savić', '+381652233450', 'tenant', 'tenant', now(), now())
    ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        full_name = EXCLUDED.full_name,
        phone_number = EXCLUDED.phone_number,
        role = EXCLUDED.role,
        active_role = EXCLUDED.active_role,
        updated_at = now();

    -- --------------------------------------------------------------------------
    -- 3. Create 10 Properties
    -- --------------------------------------------------------------------------
    INSERT INTO public.properties (
        id, landlord_id, agency_id, tenant_id, title, name, address, city,
        default_monthly_rent, default_deposit_amount, currency, default_due_day,
        landlord_name, landlord_phone, landlord_email, property_type, unit_number,
        room_count, area_sqm, floor, total_floors, furnishing, heating_type,
        amenities, is_detailed, description, created_at, updated_at
    ) VALUES
        (v_p1, v_l1, p_agency_id, v_t1, 'Dorćol Modern Two-Bedroom', 'Dorćol Modern', 'Cara Dušana 42, Stari Grad', 'Beograd', 650.00, 650.00, 'EUR', 5, 'Miloš Petrović', '+381641122331', 'milos.petrovic@example.com', 'apartment', '14', '2.0', 58.00, '3', 6, 'furnished', 'cg', '["elevator","balcony","air_conditioning"]'::jsonb, true, 'Renoviran, moderan stan u srcu Dorćola sa odličnim rasporedom.', '2026-04-01 10:00:00+00', now()),
        (v_p2, v_l1, p_agency_id, v_t2, 'Vračar Hram Studio Deluxe', 'Vračar Studio', 'Kneginje Zorke 18, Vračar', 'Beograd', 450.00, 450.00, 'EUR', 1, 'Miloš Petrović', '+381641122331', 'milos.petrovic@example.com', 'apartment', '4', 'studio', 34.00, '1', 5, 'furnished', 'cg', '["elevator","air_conditioning"]'::jsonb, true, 'Udoban studio na korak od Hrama Svetog Save.', '2026-04-01 10:00:00+00', now()),
        (v_p3, v_l2, p_agency_id, v_t3, 'Novi Beograd Blok 21 Three-Room', 'NBG Blok 21', 'Bulevar Mihajla Pupina 85, Novi Beograd', 'Beograd', 800.00, 800.00, 'EUR', 10, 'Jelena Đorđević', '+381641122332', 'jelena.djordjevic@example.com', 'apartment', '22', '3.0', 78.00, '5', 9, 'furnished', 'cg', '["elevator","balcony","parking"]'::jsonb, true, 'Prostran trosoban stan sa prelepim pogledom ka reci.', '2026-04-01 10:00:00+00', now()),
        (v_p4, v_l2, p_agency_id, v_t4, 'Novi Beograd Blok 65 Exing One-Bedroom', 'Exing Blok 65', 'Omladinskih brigada 86, Novi Beograd', 'Beograd', 700.00, 700.00, 'EUR', 5, 'Jelena Đorđević', '+381641122332', 'jelena.djordjevic@example.com', 'apartment', '31', '1.5', 48.00, '6', 10, 'furnished', 'underfloor', '["elevator","balcony","parking","garage"]'::jsonb, true, 'Novogradnja, smart home sistem, recepcija 24/7.', '2026-05-15 10:00:00+00', now()),
        (v_p5, v_l3, p_agency_id, v_t5, 'Belgrade Waterfront Parkview 2BR', 'BW Parkview', 'Hercegovačka 14, Savski Venac', 'Beograd', 1100.00, 1100.00, 'EUR', 1, 'Dragan Nikolić', '+381641122333', 'dragan.nikolic@example.com', 'apartment', '52', '2.0', 62.00, '8', 22, 'furnished', 'cg', '["elevator","balcony","garage","air_conditioning"]'::jsonb, true, 'BW Parkview zgrada, recepcija, konsijerž, direktan izlaz na park.', '2026-04-01 10:00:00+00', now()),
        (v_p6, v_l4, p_agency_id, v_t6, 'Zvezdara Đeram Family Flat', 'Zvezdara Đeram', 'Bulevar Kralja Aleksandra 154, Zvezdara', 'Beograd', 550.00, 550.00, 'EUR', 7, 'Marija Vasić', '+381641122334', 'marija.vasic@example.com', 'apartment', '11', '2.5', 65.00, '2', 6, 'furnished', 'eg', '["elevator","balcony"]'::jsonb, true, 'Odlična lokacija u blizini pijace Đeram i tramvajske linije.', '2026-06-01 10:00:00+00', now()),
        (v_p7, v_l4, p_agency_id, v_t7, 'Palilula Profesorska Kolonija', 'Palilula Prof Kolonija', 'Cvijićeva 60, Palilula', 'Beograd', 500.00, 500.00, 'EUR', 1, 'Marija Vasić', '+381641122334', 'marija.vasic@example.com', 'apartment', '7', '1.5', 45.00, '2', 4, 'furnished', 'cg', '["balcony"]'::jsonb, true, 'Mirna zgrada, salonski plafoni, kompletno namešten stan.', '2026-06-01 10:00:00+00', now()),
        (v_p8, v_l5, p_agency_id, v_t8, 'Voždovac Stepa Stepanović Cozy', 'Stepa Stepanović', 'Generala Štefanika 12, Voždovac', 'Beograd', 420.00, 420.00, 'EUR', 3, 'Zoran Stojanović', '+381641122335', 'zoran.stojanovic@example.com', 'apartment', '18', '1.5', 44.00, '4', 7, 'furnished', 'cg', '["elevator","balcony","parking"]'::jsonb, true, 'Funkcionalan i topao stan u planskom naselju Stepa Stepanović.', '2026-07-01 10:00:00+00', now()),
        (v_p9, v_l6, p_agency_id, v_t9, 'Banovo Brdo Požeška 2BR', 'Banovo Brdo Požeška', 'Požeška 92, Čukarica', 'Beograd', 480.00, 480.00, 'EUR', 1, 'Snežana Popović', '+381641122336', 'snezana.popovic@example.com', 'apartment', '9', '2.0', 54.00, '3', 5, 'furnished', 'gas', '["balcony"]'::jsonb, true, 'Centar Banovog Brda, u blizini Košutnjaka i tržnog centra.', '2026-08-01 10:00:00+00', now()),
        (v_p10, v_l7, p_agency_id, v_t10, 'Zemun Kej Danube View Studio', 'Zemun Kej Studio', 'Kej Oslobođenja 25, Zemun', 'Beograd', 380.00, 380.00, 'EUR', 1, 'Nenad Kovačević', '+381641122337', 'nenad.kovacevic@example.com', 'apartment', '2', 'studio', 30.00, '1', 3, 'furnished', 'ta', '["air_conditioning"]'::jsonb, true, 'Šarmantan studio sa pogledom na Dunavski kej.', '2026-08-15 10:00:00+00', now());

    -- --------------------------------------------------------------------------
    -- 4. Create 10 Contracts
    -- --------------------------------------------------------------------------
    INSERT INTO public.contracts (
        id, property_id, landlord_id, agency_id, tenant_id,
        monthly_rent, deposit_amount, currency, deposit_currency, due_day,
        start_date, end_date, status, invitee_email, inviter_name,
        token, expenses_config, created_at, updated_at
    ) VALUES
        (v_c1, v_p1, v_l1, p_agency_id, v_t1, 650.00, 650.00, 'EUR', 'EUR', 5, '2026-04-01 10:00:00+00', '2027-03-31 10:00:00+00', 'active', 'nikola.markovic@example.com', v_agency_name, 'demo_token_' || v_agency_short || '_1', '[{"title":"Infostan","amount":85,"currency":"EUR","is_included":false},{"title":"Struja","amount":40,"currency":"EUR","is_included":false}]'::jsonb, '2026-04-01 10:00:00+00', now()),
        (v_c2, v_p2, v_l1, p_agency_id, v_t2, 450.00, 450.00, 'EUR', 'EUR', 1, '2026-04-01 10:00:00+00', '2027-03-31 10:00:00+00', 'active', 'ana.simic@example.com', v_agency_name, 'demo_token_' || v_agency_short || '_2', '[{"title":"Infostan","amount":50,"currency":"EUR","is_included":false}]'::jsonb, '2026-04-01 10:00:00+00', now()),
        (v_c3, v_p3, v_l2, p_agency_id, v_t3, 800.00, 800.00, 'EUR', 'EUR', 10, '2026-04-01 10:00:00+00', '2027-03-31 10:00:00+00', 'active', 'stefan.ilic@example.com', v_agency_name, 'demo_token_' || v_agency_short || '_3', '[{"title":"Infostan","amount":110,"currency":"EUR","is_included":false}]'::jsonb, '2026-04-01 10:00:00+00', now()),
        (v_c4, v_p4, v_l2, p_agency_id, v_t4, 700.00, 700.00, 'EUR', 'EUR', 5, '2026-05-15 10:00:00+00', '2027-05-14 10:00:00+00', 'active', 'milica.todorovic@example.com', v_agency_name, 'demo_token_' || v_agency_short || '_4', '[{"title":"Održavanje zgrade","amount":30,"currency":"EUR","is_included":true}]'::jsonb, '2026-05-15 10:00:00+00', now()),
        (v_c5, v_p5, v_l3, p_agency_id, v_t5, 1100.00, 1100.00, 'EUR', 'EUR', 1, '2026-04-01 10:00:00+00', '2027-03-31 10:00:00+00', 'active', 'aleksandar.jovanovic@example.com', v_agency_name, 'demo_token_' || v_agency_short || '_5', '[{"title":"BW Maintenance","amount":120,"currency":"EUR","is_included":true}]'::jsonb, '2026-04-01 10:00:00+00', now()),
        (v_c6, v_p6, v_l4, p_agency_id, v_t6, 550.00, 550.00, 'EUR', 'EUR', 7, '2026-06-01 10:00:00+00', '2027-05-31 10:00:00+00', 'active', 'tamara.lukic@example.com', v_agency_name, 'demo_token_' || v_agency_short || '_6', '[]'::jsonb, '2026-06-01 10:00:00+00', now()),
        (v_c7, v_p7, v_l4, p_agency_id, v_t7, 500.00, 500.00, 'EUR', 'EUR', 1, '2026-06-01 10:00:00+00', '2027-05-31 10:00:00+00', 'active', 'vladimir.pavlovic@example.com', v_agency_name, 'demo_token_' || v_agency_short || '_7', '[]'::jsonb, '2026-06-01 10:00:00+00', now()),
        (v_c8, v_p8, v_l5, p_agency_id, v_t8, 420.00, 420.00, 'EUR', 'EUR', 3, '2026-07-01 10:00:00+00', '2027-06-30 10:00:00+00', 'active', 'jovana.bogdanovic@example.com', v_agency_name, 'demo_token_' || v_agency_short || '_8', '[]'::jsonb, '2026-07-01 10:00:00+00', now()),
        (v_c9, v_p9, v_l6, p_agency_id, v_t9, 480.00, 480.00, 'EUR', 'EUR', 1, '2026-08-01 10:00:00+00', '2027-07-31 10:00:00+00', 'active', 'luka.lazarevic@example.com', v_agency_name, 'demo_token_' || v_agency_short || '_9', '[]'::jsonb, '2026-08-01 10:00:00+00', now()),
        (v_c10, v_p10, v_l7, p_agency_id, v_t10, 380.00, 380.00, 'EUR', 'EUR', 1, '2026-08-15 10:00:00+00', '2027-08-14 10:00:00+00', 'active', 'sara.savic@example.com', v_agency_name, 'demo_token_' || v_agency_short || '_10', '[]'::jsonb, '2026-08-15 10:00:00+00', now())
    ON CONFLICT (id) DO NOTHING;

    -- --------------------------------------------------------------------------
    -- 5. Create Payments (Complete slice across recent months)
    -- --------------------------------------------------------------------------
    INSERT INTO public.rent_payments (property_id, contract_id, landlord_id, tenant_id, title, amount, currency, status, due_date, declared_at, paid_at, receiver_type, created_at, updated_at) VALUES
        -- P1: Dorćol Modern (650 EUR) - Regular past months + September declared + Infostan bills
        (v_p1, v_c1, v_l1, v_t1, 'Kira', 650.00, 'EUR', 'paid', '2026-04-05', '2026-04-04 14:00:00+00', '2026-04-04 16:30:00+00', 'owner', '2026-04-01 00:00:00+00', now()),
        (v_p1, v_c1, v_l1, v_t1, 'Kira', 650.00, 'EUR', 'paid', '2026-05-05', '2026-05-03 11:00:00+00', '2026-05-03 15:00:00+00', 'owner', '2026-05-01 00:00:00+00', now()),
        (v_p1, v_c1, v_l1, v_t1, 'Kira', 650.00, 'EUR', 'paid', '2026-06-05', '2026-06-05 09:00:00+00', '2026-06-05 10:15:00+00', 'owner', '2026-06-01 00:00:00+00', now()),
        (v_p1, v_c1, v_l1, v_t1, 'Kira', 650.00, 'EUR', 'paid', '2026-07-05', '2026-07-04 18:00:00+00', '2026-07-05 09:00:00+00', 'owner', '2026-07-01 00:00:00+00', now()),
        (v_p1, v_c1, v_l1, v_t1, 'Kira', 650.00, 'EUR', 'paid', '2026-08-05', '2026-08-05 12:00:00+00', '2026-08-05 14:00:00+00', 'owner', '2026-08-01 00:00:00+00', now()),
        (v_p1, v_c1, v_l1, v_t1, 'Kira', 650.00, 'EUR', 'declared', '2026-09-05', '2026-09-06 17:30:00+00', NULL, 'owner', '2026-09-01 00:00:00+00', now()),
        (v_p1, v_c1, v_l1, v_t1, 'Infostan', 85.00, 'EUR', 'paid', '2026-08-15', '2026-08-14 10:00:00+00', '2026-08-15 11:00:00+00', 'owner', '2026-08-01 00:00:00+00', now()),
        (v_p1, v_c1, v_l1, v_t1, 'Infostan', 85.00, 'EUR', 'declared', '2026-09-15', '2026-09-07 14:00:00+00', NULL, 'owner', '2026-09-01 00:00:00+00', now()),

        -- P2: Vračar Studio (450 EUR) - Regular past months + September paid
        (v_p2, v_c2, v_l1, v_t2, 'Kira', 450.00, 'EUR', 'paid', '2026-06-01', '2026-06-01 08:30:00+00', '2026-06-01 10:00:00+00', 'owner', '2026-06-01 00:00:00+00', now()),
        (v_p2, v_c2, v_l1, v_t2, 'Kira', 450.00, 'EUR', 'paid', '2026-07-01', '2026-07-01 12:00:00+00', '2026-07-01 14:00:00+00', 'owner', '2026-07-01 00:00:00+00', now()),
        (v_p2, v_c2, v_l1, v_t2, 'Kira', 450.00, 'EUR', 'paid', '2026-08-01', '2026-08-02 09:00:00+00', '2026-08-02 11:30:00+00', 'owner', '2026-08-01 00:00:00+00', now()),
        (v_p2, v_c2, v_l1, v_t2, 'Kira', 450.00, 'EUR', 'paid', '2026-09-01', '2026-08-31 20:00:00+00', '2026-09-01 09:00:00+00', 'owner', '2026-09-01 00:00:00+00', now()),
        (v_p2, v_c2, v_l1, v_t2, 'Infostan', 50.00, 'EUR', 'paid', '2026-09-10', '2026-09-05 11:00:00+00', '2026-09-06 15:00:00+00', 'owner', '2026-09-01 00:00:00+00', now()),

        -- P3: NBG Blok 21 (800 EUR) - Regular past months + September pending
        (v_p3, v_c3, v_l2, v_t3, 'Kira', 800.00, 'EUR', 'paid', '2026-07-10', NULL, '2026-07-10 12:00:00+00', 'owner', '2026-07-01 00:00:00+00', now()),
        (v_p3, v_c3, v_l2, v_t3, 'Kira', 800.00, 'EUR', 'paid', '2026-08-10', NULL, '2026-08-10 12:00:00+00', 'owner', '2026-08-01 00:00:00+00', now()),
        (v_p3, v_c3, v_l2, v_t3, 'Kira', 800.00, 'EUR', 'pending', '2026-09-10', NULL, NULL, 'owner', '2026-09-01 00:00:00+00', now()),
        (v_p3, v_c3, v_l2, v_t3, 'Infostan', 110.00, 'EUR', 'pending', '2026-09-15', NULL, NULL, 'owner', '2026-09-01 00:00:00+00', now()),

        -- P4: Exing Blok 65 (700 EUR) - Regular past months + September paid
        (v_p4, v_c4, v_l2, v_t4, 'Kira', 700.00, 'EUR', 'paid', '2026-06-05', '2026-06-04 10:00:00+00', '2026-06-04 11:30:00+00', 'owner', '2026-06-01 00:00:00+00', now()),
        (v_p4, v_c4, v_l2, v_t4, 'Kira', 700.00, 'EUR', 'paid', '2026-07-05', '2026-07-05 09:00:00+00', '2026-07-05 10:00:00+00', 'owner', '2026-07-01 00:00:00+00', now()),
        (v_p4, v_c4, v_l2, v_t4, 'Kira', 700.00, 'EUR', 'paid', '2026-08-05', '2026-08-05 14:00:00+00', '2026-08-05 15:00:00+00', 'owner', '2026-08-01 00:00:00+00', now()),
        (v_p4, v_c4, v_l2, v_t4, 'Kira', 700.00, 'EUR', 'paid', '2026-09-05', '2026-09-04 16:00:00+00', '2026-09-05 09:30:00+00', 'owner', '2026-09-01 00:00:00+00', now()),

        -- P5: BW Parkview (1100 EUR) - Regular past months + September paid
        (v_p5, v_c5, v_l3, v_t5, 'Kira', 1100.00, 'EUR', 'paid', '2026-06-01', '2026-06-01 10:00:00+00', '2026-06-01 11:00:00+00', 'owner', '2026-06-01 00:00:00+00', now()),
        (v_p5, v_c5, v_l3, v_t5, 'Kira', 1100.00, 'EUR', 'paid', '2026-07-01', '2026-07-01 10:00:00+00', '2026-07-01 11:00:00+00', 'owner', '2026-07-01 00:00:00+00', now()),
        (v_p5, v_c5, v_l3, v_t5, 'Kira', 1100.00, 'EUR', 'paid', '2026-08-01', '2026-08-01 10:00:00+00', '2026-08-01 11:00:00+00', 'owner', '2026-08-01 00:00:00+00', now()),
        (v_p5, v_c5, v_l3, v_t5, 'Kira', 1100.00, 'EUR', 'paid', '2026-09-01', '2026-09-01 09:30:00+00', '2026-09-01 11:00:00+00', 'owner', '2026-09-01 00:00:00+00', now()),

        -- P6: Zvezdara Đeram (550 EUR) - Regular past months + September paid
        (v_p6, v_c6, v_l4, v_t6, 'Kira', 550.00, 'EUR', 'paid', '2026-07-07', '2026-07-06 11:00:00+00', '2026-07-06 14:00:00+00', 'owner', '2026-07-01 00:00:00+00', now()),
        (v_p6, v_c6, v_l4, v_t6, 'Kira', 550.00, 'EUR', 'paid', '2026-08-07', '2026-08-07 10:00:00+00', '2026-08-07 12:00:00+00', 'owner', '2026-08-01 00:00:00+00', now()),
        (v_p6, v_c6, v_l4, v_t6, 'Kira', 550.00, 'EUR', 'paid', '2026-09-07', '2026-09-07 09:15:00+00', '2026-09-07 10:30:00+00', 'owner', '2026-09-01 00:00:00+00', now()),

        -- P7: Palilula Prof Kolonija (500 EUR) - Regular past months + September paid
        (v_p7, v_c7, v_l4, v_t7, 'Kira', 500.00, 'EUR', 'paid', '2026-07-01', '2026-07-01 12:00:00+00', '2026-07-01 15:00:00+00', 'owner', '2026-07-01 00:00:00+00', now()),
        (v_p7, v_c7, v_l4, v_t7, 'Kira', 500.00, 'EUR', 'paid', '2026-08-01', '2026-08-01 11:00:00+00', '2026-08-01 14:00:00+00', 'owner', '2026-08-01 00:00:00+00', now()),
        (v_p7, v_c7, v_l4, v_t7, 'Kira', 500.00, 'EUR', 'paid', '2026-09-01', '2026-09-01 08:45:00+00', '2026-09-01 09:30:00+00', 'owner', '2026-09-01 00:00:00+00', now()),

        -- P8: Stepa Stepanović (420 EUR) - August paid + September OVERDUE (Gecikmiş borç)
        (v_p8, v_c8, v_l5, v_t8, 'Kira', 420.00, 'EUR', 'paid', '2026-08-03', '2026-08-03 10:00:00+00', '2026-08-03 11:00:00+00', 'owner', '2026-08-01 00:00:00+00', now()),
        (v_p8, v_c8, v_l5, v_t8, 'Kira', 420.00, 'EUR', 'overdue', '2026-09-03', NULL, NULL, 'owner', '2026-09-01 00:00:00+00', now()),

        -- P9: Banovo Brdo (480 EUR) - August paid + September paid
        (v_p9, v_c9, v_l6, v_t9, 'Kira', 480.00, 'EUR', 'paid', '2026-08-01', '2026-08-01 09:00:00+00', '2026-08-01 10:30:00+00', 'owner', '2026-08-01 00:00:00+00', now()),
        (v_p9, v_c9, v_l6, v_t9, 'Kira', 480.00, 'EUR', 'paid', '2026-09-01', '2026-09-01 09:00:00+00', '2026-09-01 10:30:00+00', 'owner', '2026-09-01 00:00:00+00', now()),

        -- P10: Zemun Kej (380 EUR) - August paid + September pending
        (v_p10, v_c10, v_l7, v_t10, 'Kira', 380.00, 'EUR', 'paid', '2026-08-15', '2026-08-15 10:00:00+00', '2026-08-15 11:30:00+00', 'owner', '2026-08-15 00:00:00+00', now()),
        (v_p10, v_c10, v_l7, v_t10, 'Kira', 380.00, 'EUR', 'pending', '2026-09-15', NULL, NULL, 'owner', '2026-09-01 00:00:00+00', now())
    ON CONFLICT (id) DO NOTHING;

    -- --------------------------------------------------------------------------
    -- 6. Create Serbian Maintenance Requests, Charges, Messages
    -- --------------------------------------------------------------------------
    INSERT INTO public.maintenance_requests (
        id, property_id, contract_id, reporter_id, title, description, category, priority, status, created_at, updated_at
    ) VALUES
        (v_mr1, v_p1, v_c1, v_t1, 'Curenje vode na slavini u kupatilu', 'Slavina na lavabou kaplje i voda se preliva ispod ormarića. Potrebna hitna zamena mešača ili cele slavine.', 'plumbing', 'urgent', 'resolved', '2026-08-10 08:30:00+00', now()),
        (v_mr2, v_p3, v_c3, v_t3, 'Problem sa grejanjem - radijatori u dnevnoj sobi hladni', 'Centralno grejanje ne prolazi kroz radijatore u dnevnoj sobi. Potrebno odzračivanje ili servis cirkulacione pumpe.', 'heating', 'urgent', 'resolved', '2026-08-22 09:15:00+00', now()),
        (v_mr3, v_p5, v_c5, v_t5, 'Klima uređaj ne hladi (sumnja na curenje gasa)', 'Inverter klima duva topao vazduh, na spoljnoj jedinici čuje se zujanje. Potrebna dopuna freona.', 'electrical', 'normal', 'investigating', '2026-09-02 11:00:00+00', now()),
        (v_mr4, v_p4, v_c4, v_t4, 'Balkonska vrata zapinju pri otvaranju', 'PVC balkonska vrata su se blago opustila i zapinju u donjem desnom uglu okvira. Potrebno je štelovanje šarki.', 'other', 'normal', 'open', '2026-09-10 17:45:00+00', now()),
        (v_mr5, v_p8, v_c8, v_t8, 'Zamena sigurnosne brave na ulaznim vratima', 'Ključ povremeno zapinje u cilindru prilikom zaključavanja spolja. Majstor je preporučio zamenu cilindra radi sigurnosti.', 'other', 'normal', 'resolved', '2026-08-10 10:00:00+00', now())
    ON CONFLICT (id) DO NOTHING;

    -- 7. Insert Maintenance Messages (Conversation History)
    INSERT INTO public.maintenance_messages (id, request_id, user_id, sender_id, message, created_at) VALUES
        (gen_random_uuid(), v_mr1, v_t1, v_t1, 'Poštovani, slavina u kupatilu je počela jače da curi, stavio sam peškir.', '2026-08-10 08:35:00+00'),
        (gen_random_uuid(), v_mr1, p_agency_id, p_agency_id, 'Pozdrav Nikola, poslali smo majstora Sašu. Biće kod vas sutra ujutru u 10h.', '2026-08-10 09:15:00+00'),
        (gen_random_uuid(), v_mr1, v_t1, v_t1, 'Majstor je završio, stavio novu Grohe slavinu. Sve funkcioniše odlično.', '2026-08-12 11:35:00+00'),
        (gen_random_uuid(), v_mr2, v_t3, v_t3, 'Klima slabo hladi već dva dana, molim vas za servis pre najavljenog talasa vrućine.', '2026-09-09 14:35:00+00'),
        (gen_random_uuid(), v_mr2, p_agency_id, p_agency_id, 'Zdravo Stefane, zakazali smo ovlašćeni servis za sutra u 11:00h.', '2026-09-09 15:10:00+00'),
        (gen_random_uuid(), v_mr3, v_t5, v_t5, 'Problem je rešen, električar je zamenio utičnicu i osigurač. Sve funkcioniše odlično.', '2026-08-27 16:25:00+00')
    ON CONFLICT (id) DO NOTHING;

    -- 8. Insert Maintenance Charges
    INSERT INTO public.maintenance_charges (
        id, maintenance_request_id, property_id, created_by, title, charge_type,
        approver_role, debtor_id, creditor_id, contractor_name, amount, settled_amount,
        currency, status, contractor_payment_status, contractor_payment_date, settlement_method,
        declared_at, approved_at, paid_at, created_at, updated_at
    ) VALUES (
        gen_random_uuid(), v_mr1, v_p1, p_agency_id,
        'Nabavka Grohe slavine i rad vodoinstalatera',
        'agency_advance', 'counterparty', v_l1, p_agency_id, 'Vodoinstalater Saša Đorđević',
        85.00, 85.00, 'EUR', 'paid', 'paid', '2026-08-12 11:30:00+00', 'rent_offset',
        '2026-08-11 10:00:00+00', '2026-08-11 14:00:00+00', '2026-08-12 11:30:00+00', '2026-08-11 10:00:00+00', now()
    ), (
        gen_random_uuid(), v_mr2, v_p3, p_agency_id,
        'Zamena cirkulacione pumpe i ventila',
        'reimbursement', 'counterparty', v_l2, v_t3, 'Termo Servis NBG',
        140.00, 140.00, 'EUR', 'paid', 'paid', '2026-08-25 16:30:00+00', 'rent_offset',
        '2026-08-24 12:00:00+00', '2026-08-24 16:00:00+00', '2026-08-25 17:00:00+00', '2026-08-24 12:00:00+00', now()
    )
    ON CONFLICT (id) DO NOTHING;

    RETURN jsonb_build_object(
        'success', true,
        'agency_id', p_agency_id,
        'properties_count', 10,
        'contracts_count', 10,
        'landlords_count', 7,
        'tenants_count', 10,
        'maintenance_requests_count', 5
    );
END;
$$;

-- 5. Verify Agency Demo Token & Provision User Function
CREATE OR REPLACE FUNCTION public.verify_agency_demo_token(p_token UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_request RECORD;
    v_user_id UUID;
    v_temp_password TEXT := 'Stanomer2026!';
    v_instance_id UUID;
BEGIN
    SELECT * INTO v_request
    FROM public.agency_demo_requests
    WHERE verification_token = p_token;

    IF v_request IS NULL THEN
        RETURN jsonb_build_object('success', false, 'message', 'Geçersiz veya bulunamayan doğrulama kodu.');
    END IF;

    IF v_request.token_expires_at < now() THEN
        RETURN jsonb_build_object('success', false, 'message', 'Doğrulama bağlantısının süresi dolmuş.');
    END IF;

    -- Update demo request
    UPDATE public.agency_demo_requests
    SET is_email_verified = TRUE,
        status = 'active_demo',
        updated_at = now()
    WHERE id = v_request.id;

    -- Determine instance_id from existing users or fallback to default
    SELECT instance_id INTO v_instance_id FROM auth.users WHERE instance_id IS NOT NULL LIMIT 1;
    IF v_instance_id IS NULL THEN
        v_instance_id := '00000000-0000-0000-0000-000000000000'::uuid;
    END IF;

    -- Find or create agency user in auth.users
    SELECT id INTO v_user_id FROM auth.users WHERE email = lower(v_request.email);

    IF v_user_id IS NULL THEN
        v_user_id := gen_random_uuid();
        INSERT INTO auth.users (
            id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
            confirmation_token, recovery_token, email_change_token_new, email_change,
            email_change_token_current, reauthentication_token, phone_change, phone_change_token,
            raw_app_meta_data, raw_user_meta_data, is_super_admin, is_sso_user, is_anonymous, created_at, updated_at
        ) VALUES (
            v_user_id, v_instance_id, 'authenticated', 'authenticated',
            lower(v_request.email), extensions.crypt(v_temp_password, extensions.gen_salt('bf')),
            now(),
            '', '', '', '',
            '', '', '', '',
            '{"provider":"email","providers":["email"]}'::jsonb,
            jsonb_build_object('full_name', v_request.agency_name, 'company_name', v_request.agency_name),
            false, false, false, now(), now()
        );
    ELSE
        UPDATE auth.users
        SET encrypted_password = extensions.crypt(v_temp_password, extensions.gen_salt('bf')),
            email_confirmed_at = COALESCE(email_confirmed_at, now()),
            confirmation_token = COALESCE(confirmation_token, ''),
            recovery_token = COALESCE(recovery_token, ''),
            email_change_token_new = COALESCE(email_change_token_new, ''),
            email_change = COALESCE(email_change, ''),
            email_change_token_current = COALESCE(email_change_token_current, ''),
            reauthentication_token = COALESCE(reauthentication_token, ''),
            phone_change = COALESCE(phone_change, ''),
            phone_change_token = COALESCE(phone_change_token, ''),
            instance_id = COALESCE(instance_id, v_instance_id),
            aud = 'authenticated',
            role = 'authenticated',
            raw_app_meta_data = '{"provider":"email","providers":["email"]}'::jsonb,
            updated_at = now()
        WHERE id = v_user_id;
    END IF;

    -- Ensure matching identity exists in auth.identities for GoTrue password auth
    INSERT INTO auth.identities (
        id, provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at
    ) VALUES (
        gen_random_uuid(),
        v_user_id::text,
        v_user_id,
        jsonb_build_object('sub', v_user_id::text, 'email', lower(v_request.email)),
        'email',
        now(),
        now(),
        now()
    ) ON CONFLICT (provider_id, provider) DO UPDATE SET
        identity_data = EXCLUDED.identity_data,
        updated_at = now();

    -- Upsert public.profiles
    INSERT INTO public.profiles (
        id, email, full_name, role, active_role, company_name, website_url, is_demo, demo_expires_at, created_at, updated_at
    ) VALUES (
        v_user_id, lower(v_request.email), v_request.agency_name, 'agency', 'agency', v_request.agency_name,
        v_request.website, true, (now() + interval '3 days'), now(), now()
    ) ON CONFLICT (id) DO UPDATE SET
        role = 'agency',
        active_role = 'agency',
        company_name = EXCLUDED.company_name,
        website_url = EXCLUDED.website_url,
        is_demo = true,
        demo_expires_at = (now() + interval '3 days'),
        updated_at = now();

    -- Auto-generate demo portfolio if agency has 0 properties
    IF NOT EXISTS (SELECT 1 FROM public.properties WHERE agency_id = v_user_id) THEN
        PERFORM public.generate_agency_demo_data(v_user_id);
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'message', 'Hesabınız başarıyla aktifleştirildi.',
        'user_id', v_user_id,
        'email', lower(v_request.email),
        'agency_name', v_request.agency_name,
        'temp_password', v_temp_password
    );
END;
$$;

-- 6. Automatic Cleanup of Expired Demo Portfolios (TTL = 3 days)
CREATE OR REPLACE FUNCTION public.cleanup_expired_demo_data()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_rec RECORD;
    v_cleaned_count INT := 0;
BEGIN
    FOR v_rec IN
        SELECT id, company_name
        FROM public.profiles
        WHERE is_demo = TRUE
          AND demo_expires_at IS NOT NULL
          AND demo_expires_at < now()
    LOOP
        PERFORM public.clear_agency_demo_data(v_rec.id);
        -- Keep is_demo = true and set demo_expires_at = NULL so client knows trial expired
        UPDATE public.profiles
        SET demo_expires_at = NULL,
            updated_at = now()
        WHERE id = v_rec.id;

        v_cleaned_count := v_cleaned_count + 1;
    END LOOP;

    RETURN jsonb_build_object(
        'success', true,
        'cleaned_agencies_count', v_cleaned_count,
        'timestamp', now()
    );
END;
$$;

-- 7. Function to update agency theme and logo safely (SECURITY DEFINER)
CREATE OR REPLACE FUNCTION public.update_agency_demo_theme(
    p_agency_id UUID,
    p_logo_url TEXT,
    p_website_url TEXT DEFAULT NULL,
    p_color_scheme JSONB DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE public.profiles
    SET logo_url = p_logo_url,
        website_url = COALESCE(p_website_url, website_url),
        color_scheme = COALESCE(p_color_scheme, color_scheme),
        updated_at = now()
    WHERE id = p_agency_id;

    RETURN jsonb_build_object(
        'success', true,
        'agency_id', p_agency_id,
        'logo_url', p_logo_url
    );
END;
$$;

-- 8. Permissions
GRANT EXECUTE ON FUNCTION public.clear_agency_demo_data(UUID) TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.generate_agency_demo_data(UUID) TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.verify_agency_demo_token(UUID) TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.cleanup_expired_demo_data() TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.update_agency_demo_theme(UUID, TEXT, TEXT, JSONB) TO anon, authenticated, service_role;

-- 9. Immediate cleanup of any existing NULL token columns in auth.users
UPDATE auth.users
SET confirmation_token = COALESCE(confirmation_token, ''),
    recovery_token = COALESCE(recovery_token, ''),
    email_change_token_new = COALESCE(email_change_token_new, ''),
    email_change = COALESCE(email_change, ''),
    email_change_token_current = COALESCE(email_change_token_current, ''),
    reauthentication_token = COALESCE(reauthentication_token, ''),
    phone_change = COALESCE(phone_change, ''),
    phone_change_token = COALESCE(phone_change_token, '')
WHERE confirmation_token IS NULL
   OR recovery_token IS NULL
   OR email_change_token_new IS NULL
   OR email_change IS NULL
   OR email_change_token_current IS NULL
   OR reauthentication_token IS NULL
   OR phone_change IS NULL
   OR phone_change_token IS NULL;

-- 10. Retroactive fix for any existing demo users missing auth.identities
INSERT INTO auth.identities (
    id, provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at
)
SELECT 
    gen_random_uuid(),
    u.id::text,
    u.id,
    jsonb_build_object('sub', u.id::text, 'email', lower(u.email)),
    'email',
    now(),
    now(),
    now()
FROM auth.users u
WHERE NOT EXISTS (
    SELECT 1 FROM auth.identities i WHERE i.user_id = u.id AND i.provider = 'email'
)
ON CONFLICT (provider_id, provider) DO UPDATE SET
    identity_data = EXCLUDED.identity_data,
    updated_at = now();
