-- ==============================================================================
-- STANOMER MIGRATION: ENRICH AGENCY DEMO BILLS & UNENTERED INVOICE EXAMPLES
-- Target: DEV ONLY (thvbpifahvasyzmngpzp)
-- Date: 2026-09-13
--
-- Description:
--   1. Enhances contracts.expenses_config across all 10 demo properties with
--      realistic Serbian utility/bill templates (Infostan, Struja, Održavanje,
--      Internet & TV, Grejanje/Gas) using the standard {"name", "amount", "receiver": "owner", "payment_method"}.
--   2. Enriches public.rent_payments with complete bill lifecycle states:
--      - Girilmemiş Faturalar (amount = 0.00, invoice_url IS NULL, status = 'pending')
--      - Girilmiş & Kiracıdan Ödeme Bekleyen Faturalar (amount > 0, status = 'pending')
--      - Kiracının Dekont Yükleyip Onay Bekleyen Faturaları (status = 'declared')
--      - Vadesi Geçmiş Faturalar (status = 'overdue')
--      - Geçmiş Aylarda Ödenmiş Faturalar (status = 'paid')
--   3. Updates public.generate_agency_demo_data(p_agency_id UUID) and re-generates
--      for active demo agencies.
-- ==============================================================================

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
    -- 4. Create 10 Contracts with Standard Expenses Config
    -- --------------------------------------------------------------------------
    INSERT INTO public.contracts (
        id, property_id, landlord_id, agency_id, tenant_id,
        monthly_rent, deposit_amount, currency, deposit_currency, due_day,
        start_date, end_date, status, invitee_email, inviter_name,
        token, expenses_config, created_at, updated_at
    ) VALUES
        (v_c1, v_p1, v_l1, p_agency_id, v_t1, 650.00, 650.00, 'EUR', 'EUR', 5, '2026-04-01 10:00:00+00', '2027-03-31 10:00:00+00', 'active', 'nikola.markovic@example.com', v_agency_name, 'demo_token_' || v_agency_short || '_1', '[{"name":"Infostan","amount":85,"receiver":"owner","payment_method":"bank_transfer"},{"name":"Struja","amount":40,"receiver":"owner","payment_method":"bank_transfer"}]'::jsonb, '2026-04-01 10:00:00+00', now()),
        (v_c2, v_p2, v_l1, p_agency_id, v_t2, 450.00, 450.00, 'EUR', 'EUR', 1, '2026-04-01 10:00:00+00', '2027-03-31 10:00:00+00', 'active', 'ana.simic@example.com', v_agency_name, 'demo_token_' || v_agency_short || '_2', '[{"name":"Infostan","amount":50,"receiver":"owner","payment_method":"bank_transfer"},{"name":"Struja","amount":30,"receiver":"owner","payment_method":"bank_transfer"}]'::jsonb, '2026-04-01 10:00:00+00', now()),
        (v_c3, v_p3, v_l2, p_agency_id, v_t3, 800.00, 800.00, 'EUR', 'EUR', 10, '2026-04-01 10:00:00+00', '2027-03-31 10:00:00+00', 'active', 'stefan.ilic@example.com', v_agency_name, 'demo_token_' || v_agency_short || '_3', '[{"name":"Infostan","amount":110,"receiver":"owner","payment_method":"bank_transfer"},{"name":"Struja","amount":55,"receiver":"owner","payment_method":"bank_transfer"},{"name":"Internet & TV","amount":30,"receiver":"owner","payment_method":"bank_transfer"}]'::jsonb, '2026-04-01 10:00:00+00', now()),
        (v_c4, v_p4, v_l2, p_agency_id, v_t4, 700.00, 700.00, 'EUR', 'EUR', 5, '2026-05-15 10:00:00+00', '2027-05-14 10:00:00+00', 'active', 'milica.todorovic@example.com', v_agency_name, 'demo_token_' || v_agency_short || '_4', '[{"name":"Infostan","amount":90,"receiver":"owner","payment_method":"bank_transfer"},{"name":"Održavanje zgrade","amount":35,"receiver":"owner","payment_method":"bank_transfer"}]'::jsonb, '2026-05-15 10:00:00+00', now()),
        (v_c5, v_p5, v_l3, p_agency_id, v_t5, 1100.00, 1100.00, 'EUR', 'EUR', 1, '2026-04-01 10:00:00+00', '2027-03-31 10:00:00+00', 'active', 'aleksandar.jovanovic@example.com', v_agency_name, 'demo_token_' || v_agency_short || '_5', '[{"name":"Infostan","amount":130,"receiver":"owner","payment_method":"bank_transfer"},{"name":"BW Maintenance","amount":120,"receiver":"owner","payment_method":"bank_transfer"},{"name":"Struja","amount":70,"receiver":"owner","payment_method":"bank_transfer"}]'::jsonb, '2026-04-01 10:00:00+00', now()),
        (v_c6, v_p6, v_l4, p_agency_id, v_t6, 550.00, 550.00, 'EUR', 'EUR', 7, '2026-06-01 10:00:00+00', '2027-05-31 10:00:00+00', 'active', 'tamara.lukic@example.com', v_agency_name, 'demo_token_' || v_agency_short || '_6', '[{"name":"Infostan","amount":70,"receiver":"owner","payment_method":"bank_transfer"},{"name":"Struja","amount":45,"receiver":"owner","payment_method":"bank_transfer"}]'::jsonb, '2026-06-01 10:00:00+00', now()),
        (v_c7, v_p7, v_l4, p_agency_id, v_t7, 500.00, 500.00, 'EUR', 'EUR', 1, '2026-06-01 10:00:00+00', '2027-05-31 10:00:00+00', 'active', 'vladimir.pavlovic@example.com', v_agency_name, 'demo_token_' || v_agency_short || '_7', '[{"name":"Infostan","amount":65,"receiver":"owner","payment_method":"bank_transfer"},{"name":"Struja","amount":35,"receiver":"owner","payment_method":"bank_transfer"}]'::jsonb, '2026-06-01 10:00:00+00', now()),
        (v_c8, v_p8, v_l5, p_agency_id, v_t8, 420.00, 420.00, 'EUR', 'EUR', 3, '2026-07-01 10:00:00+00', '2027-06-30 10:00:00+00', 'active', 'jovana.bogdanovic@example.com', v_agency_name, 'demo_token_' || v_agency_short || '_8', '[{"name":"Infostan","amount":60,"receiver":"owner","payment_method":"bank_transfer"},{"name":"Grejanje","amount":50,"receiver":"owner","payment_method":"bank_transfer"}]'::jsonb, '2026-07-01 10:00:00+00', now()),
        (v_c9, v_p9, v_l6, p_agency_id, v_t9, 480.00, 480.00, 'EUR', 'EUR', 1, '2026-08-01 10:00:00+00', '2027-07-31 10:00:00+00', 'active', 'luka.lazarevic@example.com', v_agency_name, 'demo_token_' || v_agency_short || '_9', '[{"name":"Infostan","amount":55,"receiver":"owner","payment_method":"bank_transfer"},{"name":"Struja","amount":40,"receiver":"owner","payment_method":"bank_transfer"}]'::jsonb, '2026-08-01 10:00:00+00', now()),
        (v_c10, v_p10, v_l7, p_agency_id, v_t10, 380.00, 380.00, 'EUR', 'EUR', 1, '2026-08-15 10:00:00+00', '2027-08-14 10:00:00+00', 'active', 'sara.savic@example.com', v_agency_name, 'demo_token_' || v_agency_short || '_10', '[{"name":"Infostan","amount":45,"receiver":"owner","payment_method":"bank_transfer"},{"name":"Struja","amount":30,"receiver":"owner","payment_method":"bank_transfer"}]'::jsonb, '2026-08-15 10:00:00+00', now())
    ON CONFLICT (id) DO NOTHING;

    -- --------------------------------------------------------------------------
    -- 5. Create Payments: Complete Slice of Rents + Rich Utility Bills
    -- --------------------------------------------------------------------------
    INSERT INTO public.rent_payments (
        property_id, contract_id, landlord_id, tenant_id, title, amount, currency,
        status, due_date, declared_at, paid_at, receiver_type, invoice_url, created_at, updated_at
    ) VALUES
        -- ═════════════════════════════════════════════════════════════════════
        -- P1: Dorćol Modern (650 EUR Rent)
        -- ═════════════════════════════════════════════════════════════════════
        (v_p1, v_c1, v_l1, v_t1, 'Kira', 650.00, 'EUR', 'paid', '2026-04-05', '2026-04-04 14:00:00+00', '2026-04-04 16:30:00+00', 'owner', NULL, '2026-04-01 00:00:00+00', now()),
        (v_p1, v_c1, v_l1, v_t1, 'Kira', 650.00, 'EUR', 'paid', '2026-05-05', '2026-05-03 11:00:00+00', '2026-05-03 15:00:00+00', 'owner', NULL, '2026-05-01 00:00:00+00', now()),
        (v_p1, v_c1, v_l1, v_t1, 'Kira', 650.00, 'EUR', 'paid', '2026-06-05', '2026-06-05 09:00:00+00', '2026-06-05 10:15:00+00', 'owner', NULL, '2026-06-01 00:00:00+00', now()),
        (v_p1, v_c1, v_l1, v_t1, 'Kira', 650.00, 'EUR', 'paid', '2026-07-05', '2026-07-04 18:00:00+00', '2026-07-05 09:00:00+00', 'owner', NULL, '2026-07-01 00:00:00+00', now()),
        (v_p1, v_c1, v_l1, v_t1, 'Kira', 650.00, 'EUR', 'paid', '2026-08-05', '2026-08-05 12:00:00+00', '2026-08-05 14:00:00+00', 'owner', NULL, '2026-08-01 00:00:00+00', now()),
        (v_p1, v_c1, v_l1, v_t1, 'Kira', 650.00, 'EUR', 'declared', '2026-09-05', '2026-09-06 17:30:00+00', NULL, 'owner', NULL, '2026-09-01 00:00:00+00', now()),
        -- P1 Bills: August Paid, September Declared (Acente Onayı Bekleyen)
        (v_p1, v_c1, v_l1, v_t1, 'Infostan', 85.00, 'EUR', 'paid', '2026-08-15', '2026-08-14 10:00:00+00', '2026-08-15 11:00:00+00', 'owner', 'https://stanomer.online/demo/invoices/infostan_p1_aug.pdf', '2026-08-01 00:00:00+00', now()),
        (v_p1, v_c1, v_l1, v_t1, 'Struja', 42.00, 'EUR', 'paid', '2026-08-20', '2026-08-19 12:00:00+00', '2026-08-20 14:00:00+00', 'owner', 'https://stanomer.online/demo/invoices/struja_p1_aug.pdf', '2026-08-01 00:00:00+00', now()),
        (v_p1, v_c1, v_l1, v_t1, 'Infostan', 85.00, 'EUR', 'declared', '2026-09-15', '2026-09-07 14:00:00+00', NULL, 'owner', 'https://stanomer.online/demo/invoices/infostan_p1_sep.pdf', '2026-09-01 00:00:00+00', now()),

        -- ═════════════════════════════════════════════════════════════════════
        -- P2: Vračar Studio (450 EUR Rent)
        -- ═════════════════════════════════════════════════════════════════════
        (v_p2, v_c2, v_l1, v_t2, 'Kira', 450.00, 'EUR', 'paid', '2026-06-01', '2026-06-01 08:30:00+00', '2026-06-01 10:00:00+00', 'owner', NULL, '2026-06-01 00:00:00+00', now()),
        (v_p2, v_c2, v_l1, v_t2, 'Kira', 450.00, 'EUR', 'paid', '2026-07-01', '2026-07-01 12:00:00+00', '2026-07-01 14:00:00+00', 'owner', NULL, '2026-07-01 00:00:00+00', now()),
        (v_p2, v_c2, v_l1, v_t2, 'Kira', 450.00, 'EUR', 'paid', '2026-08-01', '2026-08-02 09:00:00+00', '2026-08-02 11:30:00+00', 'owner', NULL, '2026-08-01 00:00:00+00', now()),
        (v_p2, v_c2, v_l1, v_t2, 'Kira', 450.00, 'EUR', 'paid', '2026-09-01', '2026-08-31 20:00:00+00', '2026-09-01 09:00:00+00', 'owner', NULL, '2026-09-01 00:00:00+00', now()),
        -- P2 Bills: Infostan Paid, Struja Declared (Onay Bekleyen)
        (v_p2, v_c2, v_l1, v_t2, 'Infostan', 50.00, 'EUR', 'paid', '2026-08-10', '2026-08-08 11:00:00+00', '2026-08-09 15:00:00+00', 'owner', 'https://stanomer.online/demo/invoices/infostan_p2_aug.pdf', '2026-08-01 00:00:00+00', now()),
        (v_p2, v_c2, v_l1, v_t2, 'Infostan', 50.00, 'EUR', 'paid', '2026-09-10', '2026-09-05 11:00:00+00', '2026-09-06 15:00:00+00', 'owner', 'https://stanomer.online/demo/invoices/infostan_p2_sep.pdf', '2026-09-01 00:00:00+00', now()),
        (v_p2, v_c2, v_l1, v_t2, 'Struja', 28.50, 'EUR', 'declared', '2026-09-16', '2026-09-09 11:30:00+00', NULL, 'owner', 'https://stanomer.online/demo/invoices/struja_p2_sep.pdf', '2026-09-01 00:00:00+00', now()),

        -- ═════════════════════════════════════════════════════════════════════
        -- P3: NBG Blok 21 (800 EUR Rent)
        -- ═════════════════════════════════════════════════════════════════════
        (v_p3, v_c3, v_l2, v_t3, 'Kira', 800.00, 'EUR', 'paid', '2026-07-10', NULL, '2026-07-10 12:00:00+00', 'owner', NULL, '2026-07-01 00:00:00+00', now()),
        (v_p3, v_c3, v_l2, v_t3, 'Kira', 800.00, 'EUR', 'paid', '2026-08-10', NULL, '2026-08-10 12:00:00+00', 'owner', NULL, '2026-08-01 00:00:00+00', now()),
        (v_p3, v_c3, v_l2, v_t3, 'Kira', 800.00, 'EUR', 'pending', '2026-09-10', NULL, NULL, 'owner', NULL, '2026-09-01 00:00:00+00', now()),
        -- P3 Bills: August Paid, September Pending (Kiracıdan Ödeme Bekleyen)
        (v_p3, v_c3, v_l2, v_t3, 'Infostan', 110.00, 'EUR', 'paid', '2026-08-15', '2026-08-14 14:00:00+00', '2026-08-15 16:00:00+00', 'owner', 'https://stanomer.online/demo/invoices/infostan_p3_aug.pdf', '2026-08-01 00:00:00+00', now()),
        (v_p3, v_c3, v_l2, v_t3, 'Infostan', 110.00, 'EUR', 'pending', '2026-09-18', NULL, NULL, 'owner', 'https://stanomer.online/demo/invoices/infostan_p3_sep.pdf', '2026-09-01 00:00:00+00', now()),
        (v_p3, v_c3, v_l2, v_t3, 'Internet & TV', 30.00, 'EUR', 'pending', '2026-09-20', NULL, NULL, 'owner', NULL, '2026-09-01 00:00:00+00', now()),

        -- ═════════════════════════════════════════════════════════════════════
        -- P4: Exing Blok 65 (700 EUR Rent)
        -- ★ GİRİLMEMİŞ FATURA ÖRNEĞİ: Infostan henüz girilmemiş (Tutar: 0, invoice_url: NULL)
        -- ═════════════════════════════════════════════════════════════════════
        (v_p4, v_c4, v_l2, v_t4, 'Kira', 700.00, 'EUR', 'paid', '2026-06-05', '2026-06-04 10:00:00+00', '2026-06-04 11:30:00+00', 'owner', NULL, '2026-06-01 00:00:00+00', now()),
        (v_p4, v_c4, v_l2, v_t4, 'Kira', 700.00, 'EUR', 'paid', '2026-07-05', '2026-07-05 09:00:00+00', '2026-07-05 10:00:00+00', 'owner', NULL, '2026-07-01 00:00:00+00', now()),
        (v_p4, v_c4, v_l2, v_t4, 'Kira', 700.00, 'EUR', 'paid', '2026-08-05', '2026-08-05 14:00:00+00', '2026-08-05 15:00:00+00', 'owner', NULL, '2026-08-01 00:00:00+00', now()),
        (v_p4, v_c4, v_l2, v_t4, 'Kira', 700.00, 'EUR', 'paid', '2026-09-05', '2026-09-04 16:00:00+00', '2026-09-05 09:30:00+00', 'owner', NULL, '2026-09-01 00:00:00+00', now()),
        -- P4 Bills: Održavanje Paid, Infostan GİRİLMEMİŞ (Amount: 0.00, invoice_url: NULL, status: pending)
        (v_p4, v_c4, v_l2, v_t4, 'Održavanje zgrade', 35.00, 'EUR', 'paid', '2026-08-20', '2026-08-19 10:00:00+00', '2026-08-20 11:00:00+00', 'owner', NULL, '2026-08-01 00:00:00+00', now()),
        (v_p4, v_c4, v_l2, v_t4, 'Održavanje zgrade', 35.00, 'EUR', 'paid', '2026-09-05', '2026-09-04 15:00:00+00', '2026-09-05 10:00:00+00', 'owner', NULL, '2026-09-01 00:00:00+00', now()),
        (v_p4, v_c4, v_l2, v_t4, 'Infostan', 0.00, 'EUR', 'pending', '2026-09-20', NULL, NULL, 'owner', NULL, '2026-09-01 00:00:00+00', now()),

        -- ═════════════════════════════════════════════════════════════════════
        -- P5: BW Parkview (1100 EUR Rent)
        -- ═════════════════════════════════════════════════════════════════════
        (v_p5, v_c5, v_l3, v_t5, 'Kira', 1100.00, 'EUR', 'paid', '2026-06-01', '2026-06-01 10:00:00+00', '2026-06-01 11:00:00+00', 'owner', NULL, '2026-06-01 00:00:00+00', now()),
        (v_p5, v_c5, v_l3, v_t5, 'Kira', 1100.00, 'EUR', 'paid', '2026-07-01', '2026-07-01 10:00:00+00', '2026-07-01 11:00:00+00', 'owner', NULL, '2026-07-01 00:00:00+00', now()),
        (v_p5, v_c5, v_l3, v_t5, 'Kira', 1100.00, 'EUR', 'paid', '2026-08-01', '2026-08-01 10:00:00+00', '2026-08-01 11:00:00+00', 'owner', NULL, '2026-08-01 00:00:00+00', now()),
        (v_p5, v_c5, v_l3, v_t5, 'Kira', 1100.00, 'EUR', 'paid', '2026-09-01', '2026-09-01 09:30:00+00', '2026-09-01 11:00:00+00', 'owner', NULL, '2026-09-01 00:00:00+00', now()),
        -- P5 Bills: Maintenance Paid + Pending, Infostan Declared (Kiracı Dekont Yüklemiş)
        (v_p5, v_c5, v_l3, v_t5, 'BW Maintenance', 120.00, 'EUR', 'paid', '2026-08-15', '2026-08-14 09:00:00+00', '2026-08-15 10:00:00+00', 'owner', NULL, '2026-08-01 00:00:00+00', now()),
        (v_p5, v_c5, v_l3, v_t5, 'BW Maintenance', 120.00, 'EUR', 'pending', '2026-09-15', NULL, NULL, 'owner', NULL, '2026-09-01 00:00:00+00', now()),
        (v_p5, v_c5, v_l3, v_t5, 'Infostan', 134.00, 'EUR', 'declared', '2026-09-14', '2026-09-10 16:00:00+00', NULL, 'owner', 'https://stanomer.online/demo/invoices/infostan_p5_sep.pdf', '2026-09-01 00:00:00+00', now()),

        -- ═════════════════════════════════════════════════════════════════════
        -- P6: Zvezdara Đeram (550 EUR Rent)
        -- ★ GİRİLMEMİŞ FATURA ÖRNEĞİ: Struja henüz girilmemiş (Tutar: 0, invoice_url: NULL)
        -- ═════════════════════════════════════════════════════════════════════
        (v_p6, v_c6, v_l4, v_t6, 'Kira', 550.00, 'EUR', 'paid', '2026-07-07', '2026-07-06 11:00:00+00', '2026-07-06 14:00:00+00', 'owner', NULL, '2026-07-01 00:00:00+00', now()),
        (v_p6, v_c6, v_l4, v_t6, 'Kira', 550.00, 'EUR', 'paid', '2026-08-07', '2026-08-07 10:00:00+00', '2026-08-07 12:00:00+00', 'owner', NULL, '2026-08-01 00:00:00+00', now()),
        (v_p6, v_c6, v_l4, v_t6, 'Kira', 550.00, 'EUR', 'paid', '2026-09-07', '2026-09-07 09:15:00+00', '2026-09-07 10:30:00+00', 'owner', NULL, '2026-09-01 00:00:00+00', now()),
        -- P6 Bills: Infostan Paid, Struja GİRİLMEMİŞ (Amount: 0.00, invoice_url: NULL, status: pending)
        (v_p6, v_c6, v_l4, v_t6, 'Infostan', 70.00, 'EUR', 'paid', '2026-08-15', '2026-08-13 14:00:00+00', '2026-08-14 11:00:00+00', 'owner', 'https://stanomer.online/demo/invoices/infostan_p6_aug.pdf', '2026-08-01 00:00:00+00', now()),
        (v_p6, v_c6, v_l4, v_t6, 'Struja', 0.00, 'EUR', 'pending', '2026-09-22', NULL, NULL, 'owner', NULL, '2026-09-01 00:00:00+00', now()),

        -- ═════════════════════════════════════════════════════════════════════
        -- P7: Palilula Prof Kolonija (500 EUR Rent)
        -- ═════════════════════════════════════════════════════════════════════
        (v_p7, v_c7, v_l4, v_t7, 'Kira', 500.00, 'EUR', 'paid', '2026-07-01', '2026-07-01 12:00:00+00', '2026-07-01 15:00:00+00', 'owner', NULL, '2026-07-01 00:00:00+00', now()),
        (v_p7, v_c7, v_l4, v_t7, 'Kira', 500.00, 'EUR', 'paid', '2026-08-01', '2026-08-01 11:00:00+00', '2026-08-01 14:00:00+00', 'owner', NULL, '2026-08-01 00:00:00+00', now()),
        (v_p7, v_c7, v_l4, v_t7, 'Kira', 500.00, 'EUR', 'paid', '2026-09-01', '2026-09-01 08:45:00+00', '2026-09-01 09:30:00+00', 'owner', NULL, '2026-09-01 00:00:00+00', now()),
        -- P7 Bills: August Paid, September Pending
        (v_p7, v_c7, v_l4, v_t7, 'Infostan', 65.00, 'EUR', 'paid', '2026-08-15', '2026-08-14 11:00:00+00', '2026-08-15 12:00:00+00', 'owner', 'https://stanomer.online/demo/invoices/infostan_p7_aug.pdf', '2026-08-01 00:00:00+00', now()),
        (v_p7, v_c7, v_l4, v_t7, 'Infostan', 65.00, 'EUR', 'pending', '2026-09-17', NULL, NULL, 'owner', 'https://stanomer.online/demo/invoices/infostan_p7_sep.pdf', '2026-09-01 00:00:00+00', now()),

        -- ═════════════════════════════════════════════════════════════════════
        -- P8: Stepa Stepanović (420 EUR Rent - Overdue)
        -- ★ GİRİLMEMİŞ DOĞALGAZ & VADESİ GEÇMİŞ İNFOSTAN ÖRNEKLERİ
        -- ═════════════════════════════════════════════════════════════════════
        (v_p8, v_c8, v_l5, v_t8, 'Kira', 420.00, 'EUR', 'paid', '2026-08-03', '2026-08-03 10:00:00+00', '2026-08-03 11:00:00+00', 'owner', NULL, '2026-08-01 00:00:00+00', now()),
        (v_p8, v_c8, v_l5, v_t8, 'Kira', 420.00, 'EUR', 'overdue', '2026-09-03', NULL, NULL, 'owner', NULL, '2026-09-01 00:00:00+00', now()),
        -- P8 Bills: August Paid, September Infostan OVERDUE (Gecikmiş Fatura), Grejanje GİRİLMEMİŞ (Amount: 0)
        (v_p8, v_c8, v_l5, v_t8, 'Infostan', 60.00, 'EUR', 'paid', '2026-08-15', '2026-08-14 16:00:00+00', '2026-08-15 17:00:00+00', 'owner', 'https://stanomer.online/demo/invoices/infostan_p8_aug.pdf', '2026-08-01 00:00:00+00', now()),
        (v_p8, v_c8, v_l5, v_t8, 'Infostan', 60.00, 'EUR', 'overdue', '2026-09-03', NULL, NULL, 'owner', 'https://stanomer.online/demo/invoices/infostan_p8_sep.pdf', '2026-09-01 00:00:00+00', now()),
        (v_p8, v_c8, v_l5, v_t8, 'Grejanje', 0.00, 'EUR', 'pending', '2026-09-25', NULL, NULL, 'owner', NULL, '2026-09-01 00:00:00+00', now()),

        -- ═════════════════════════════════════════════════════════════════════
        -- P9: Banovo Brdo (480 EUR Rent)
        -- ★ VADESİ GEÇMİŞ ELEKTRİK (STRUJA) ÖRNEĞİ
        -- ═════════════════════════════════════════════════════════════════════
        (v_p9, v_c9, v_l6, v_t9, 'Kira', 480.00, 'EUR', 'paid', '2026-08-01', '2026-08-01 09:00:00+00', '2026-08-01 10:30:00+00', 'owner', NULL, '2026-08-01 00:00:00+00', now()),
        (v_p9, v_c9, v_l6, v_t9, 'Kira', 480.00, 'EUR', 'paid', '2026-09-01', '2026-09-01 09:00:00+00', '2026-09-01 10:30:00+00', 'owner', NULL, '2026-09-01 00:00:00+00', now()),
        -- P9 Bills: Infostan Paid, Struja OVERDUE (Vadesi Geçmiş)
        (v_p9, v_c9, v_l6, v_t9, 'Infostan', 55.00, 'EUR', 'paid', '2026-08-15', '2026-08-14 10:00:00+00', '2026-08-15 11:30:00+00', 'owner', 'https://stanomer.online/demo/invoices/infostan_p9_aug.pdf', '2026-08-01 00:00:00+00', now()),
        (v_p9, v_c9, v_l6, v_t9, 'Infostan', 55.00, 'EUR', 'paid', '2026-09-10', '2026-09-08 09:00:00+00', '2026-09-09 10:30:00+00', 'owner', 'https://stanomer.online/demo/invoices/infostan_p9_sep.pdf', '2026-09-01 00:00:00+00', now()),
        (v_p9, v_c9, v_l6, v_t9, 'Struja', 38.00, 'EUR', 'overdue', '2026-09-05', NULL, NULL, 'owner', 'https://stanomer.online/demo/invoices/struja_p9_sep.pdf', '2026-09-01 00:00:00+00', now()),

        -- ═════════════════════════════════════════════════════════════════════
        -- P10: Zemun Kej (380 EUR Rent)
        -- ═════════════════════════════════════════════════════════════════════
        (v_p10, v_c10, v_l7, v_t10, 'Kira', 380.00, 'EUR', 'paid', '2026-08-15', '2026-08-15 10:00:00+00', '2026-08-15 11:30:00+00', 'owner', NULL, '2026-08-15 00:00:00+00', now()),
        (v_p10, v_c10, v_l7, v_t10, 'Kira', 380.00, 'EUR', 'pending', '2026-09-15', NULL, NULL, 'owner', NULL, '2026-09-01 00:00:00+00', now()),
        -- P10 Bills: August Infostan Paid, September Struja Pending (Ödeme Bekleyen)
        (v_p10, v_c10, v_l7, v_t10, 'Infostan', 45.00, 'EUR', 'paid', '2026-08-20', '2026-08-19 14:00:00+00', '2026-08-20 15:30:00+00', 'owner', 'https://stanomer.online/demo/invoices/infostan_p10_aug.pdf', '2026-08-15 00:00:00+00', now()),
        (v_p10, v_c10, v_l7, v_t10, 'Struja', 32.00, 'EUR', 'pending', '2026-09-19', NULL, NULL, 'owner', 'https://stanomer.online/demo/invoices/struja_p10_sep.pdf', '2026-09-01 00:00:00+00', now())
    ON CONFLICT (id) DO NOTHING;

    -- --------------------------------------------------------------------------
    -- 6. Create Serbian Maintenance Requests, Charges, Messages
    -- --------------------------------------------------------------------------
    INSERT INTO public.maintenance_requests (
        id, property_id, contract_id, reporter_id, title, description, category, priority, status,
        cost_amount, settled_amount, currency, paid_by, payment_date, payment_status, created_at, updated_at
    ) VALUES
        -- MR1: Dorćol Modern (Musluk - Ödenmiş 85 EUR, Ağustos 2026)
        (v_mr1, v_p1, v_c1, v_t1, 'Curenje vode na slavini u kupatilu', 'Slavina na lavabou kaplje i voda se preliva ispod ormarića. Potrebna hitna zamena mešača ili cele slavine.', 'plumbing', 'urgent', 'resolved', 85.00, 85.00, 'EUR', 'agency', '2026-08-12 11:30:00+00', 'paid', '2026-08-10 08:30:00+00', now()),
        -- MR2: NBG Blok 21 (Isıtma/Pompa - Ödenmiş 140 EUR, Eylül 2026 Cari Ay!)
        (v_mr2, v_p3, v_c3, v_t3, 'Problem sa grejanjem - radijatori u dnevnoj sobi hladni', 'Centralno grejanje ne prolazi kroz radijatore u dnevnoj sobi. Potrebno odzračivanje ili servis cirkulacione pumpe.', 'heating', 'urgent', 'resolved', 140.00, 140.00, 'EUR', 'agency', '2026-09-02 11:00:00+00', 'paid', '2026-08-22 09:15:00+00', now()),
        -- MR3: BW Parkview (Klima - Ödenmemiş / Usta Ödemesi Bekleyen 120 EUR, Eylül 2026)
        (v_mr3, v_p5, v_c5, v_t5, 'Klima uređaj ne hladi (sumnja na curenje gasa)', 'Inverter klima duva topao vazduh, na spoljnoj jedinici čuje se zujanje. Potrebna dopuna freona.', 'electrical', 'normal', 'investigating', 120.00, 0.00, 'EUR', 'agency', '2026-09-08 11:00:00+00', 'pending_payment', '2026-09-02 11:00:00+00', now()),
        -- MR4: Exing Blok 65 (Balkon Kapısı - Kiracı Ödemiş Mahsup Onayı Bekleyen 45 EUR, Eylül 2026)
        (v_mr4, v_p4, v_c4, v_t4, 'Balkonska vrata zapinju pri otvaranju', 'PVC balkonska vrata su se blago opustila i zapinju u donjem desnom uglu okvira. Potrebno je štelovanje šarki.', 'other', 'normal', 'open', 45.00, 0.00, 'EUR', 'tenant', '2026-09-10 17:45:00+00', 'pending_agency_approval', '2026-09-10 17:45:00+00', now()),
        -- MR5: Stepa Stepanović (Kilit Değişimi - Tamamlanmış)
        (v_mr5, v_p8, v_c8, v_t8, 'Zamena sigurnosne brave na ulaznim vratima', 'Ključ povremeno zapinje u cilindru prilikom zaključavanja spolja. Majstor je preporučio zamenu cilindra radi sigurnosti.', 'other', 'normal', 'resolved', NULL, 0.00, 'EUR', NULL, NULL, 'pending_review', '2026-08-10 10:00:00+00', now())
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

    -- 8. Insert Maintenance Charges (Paid + Unpaid / Pending)
    INSERT INTO public.maintenance_charges (
        id, maintenance_request_id, property_id, created_by, title, charge_type,
        approver_role, debtor_id, creditor_id, contractor_name, amount, settled_amount,
        currency, status, contractor_payment_status, contractor_payment_date, settlement_method,
        declared_at, approved_at, paid_at, created_at, updated_at
    ) VALUES (
        -- 1. Grohe musluk: Ödenmiş (Paid)
        gen_random_uuid(), v_mr1, v_p1, p_agency_id,
        'Nabavka Grohe slavine i rad vodoinstalatera',
        'agency_advance', 'counterparty', v_l1, p_agency_id, 'Vodoinstalater Saša Đorđević',
        85.00, 85.00, 'EUR', 'paid', 'paid', '2026-08-12 11:30:00+00', 'rent_offset',
        '2026-08-11 10:00:00+00', '2026-08-11 14:00:00+00', '2026-08-12 11:30:00+00', '2026-08-11 10:00:00+00', now()
    ), (
        -- 2. Cirkulaciona pumpa: Ödenmiş (Paid - Eylül 2026 Cari Ay)
        gen_random_uuid(), v_mr2, v_p3, p_agency_id,
        'Zamena cirkulacione pumpe i ventila',
        'agency_advance', 'counterparty', v_l2, p_agency_id, 'Termo Servis NBG',
        140.00, 140.00, 'EUR', 'paid', 'paid', '2026-09-02 11:00:00+00', 'rent_offset',
        '2026-09-01 12:00:00+00', '2026-09-01 16:00:00+00', '2026-09-02 11:00:00+00', '2026-09-01 12:00:00+00', now()
    ), (
        -- 3. Inverter klima: Ödenmemiş / Bekleyen Usta Masrafı (Pending Payment - 120 EUR)
        gen_random_uuid(), v_mr3, v_p5, p_agency_id,
        'Servis inverter klime i dopuna freona R32',
        'agency_advance', 'counterparty', v_l3, p_agency_id, 'Frigo Servis Beograd',
        120.00, 0.00, 'EUR', 'pending', 'unpaid', NULL, 'rent_offset',
        '2026-09-02 11:00:00+00', NULL, NULL, '2026-09-02 11:00:00+00', now()
    ), (
        -- 4. Balkon kapı şarki tamiri: Kiracı Ödemiş Mahsup Onayı Bekleyen (Declared - 45 EUR)
        gen_random_uuid(), v_mr4, v_p4, p_agency_id,
        'Štelovanje PVC balkonskih vrata i zamena šarki',
        'reimbursement', 'agency', v_l2, v_t4, 'Stolarija Majstor Jovan',
        45.00, 0.00, 'EUR', 'declared', 'unpaid', NULL, 'rent_offset',
        '2026-09-10 17:45:00+00', NULL, NULL, '2026-09-10 17:45:00+00', now()
    )
    ON CONFLICT (id) DO NOTHING;

    RETURN jsonb_build_object(
        'success', true,
        'agency_id', p_agency_id,
        'properties_count', 10,
        'contracts_count', 10,
        'requests_count', 5
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.generate_agency_demo_data(UUID) TO anon, authenticated, service_role;

-- 2. Automatically regenerate payments and bills for any active demo agencies
DO $$
DECLARE
    v_demo_agency RECORD;
BEGIN
    FOR v_demo_agency IN SELECT id FROM public.profiles WHERE is_demo = TRUE
    LOOP
        PERFORM public.generate_agency_demo_data(v_demo_agency.id);
    END LOOP;
END;
$$;
