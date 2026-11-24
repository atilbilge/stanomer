-- ==============================================================================
-- Migration: 2026-11-23_agency_demo_7_days_and_phone.sql
-- Description: Extends agency demo sandbox retention to 7 days and ensures phone support
-- Target: Dev Supabase (nbcbfmhztnnhfnapvaet) ONLY
-- Idempotent: Yes
-- ==============================================================================

DO $$
BEGIN
    -- 1. Ensure phone_number column exists on agency_demo_requests
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
          AND table_name = 'agency_demo_requests' 
          AND column_name = 'phone_number'
    ) THEN
        ALTER TABLE public.agency_demo_requests ADD COLUMN phone_number TEXT DEFAULT NULL;
    END IF;
END $$;

-- 2. Update verify_agency_demo_token function to 7 days
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
    v_was_expired BOOLEAN := FALSE;
    v_modules TEXT[];
BEGIN
    SELECT * INTO v_request
    FROM public.agency_demo_requests
    WHERE verification_token = p_token;

    IF v_request IS NULL THEN
        RETURN jsonb_build_object('success', false, 'message', 'Geçersiz veya bulunamayan doğrulama kodu.');
    END IF;

    IF v_request.token_expires_at < now() THEN
        v_was_expired := TRUE;
    END IF;

    -- Mark request as email verified
    UPDATE public.agency_demo_requests
    SET is_email_verified = TRUE,
        status = 'email_verified',
        updated_at = now()
    WHERE id = v_request.id;

    -- Resolve GoTrue-compatible instance_id (auth.instances is empty on Supabase Cloud!)
    SELECT instance_id INTO v_instance_id FROM auth.users WHERE instance_id IS NOT NULL LIMIT 1;
    IF v_instance_id IS NULL THEN
        v_instance_id := '00000000-0000-0000-0000-000000000000'::uuid;
    END IF;

    -- Resolve or create sandbox user in auth.users
    SELECT id INTO v_user_id
    FROM auth.users
    WHERE lower(email) = lower(v_request.email);

    IF v_user_id IS NULL THEN
        v_user_id := gen_random_uuid();

        INSERT INTO auth.users (
            instance_id,
            id,
            aud,
            role,
            email,
            encrypted_password,
            email_confirmed_at,
            confirmation_token,
            recovery_token,
            email_change_token_new,
            email_change,
            email_change_token_current,
            reauthentication_token,
            phone,
            phone_change,
            phone_change_token,
            created_at,
            updated_at,
            raw_app_meta_data,
            raw_user_meta_data,
            is_super_admin,
            is_sso_user,
            is_anonymous
        ) VALUES (
            v_instance_id,
            v_user_id,
            'authenticated',
            'authenticated',
            lower(v_request.email),
            extensions.crypt(v_temp_password, extensions.gen_salt('bf')),
            now(),
            '',
            '',
            '',
            '',
            '',
            '',
            NULL,
            '',
            '',
            now(),
            now(),
            '{"provider":"email","providers":["email"]}'::jsonb,
            jsonb_build_object(
                'full_name', v_request.agency_name,
                'company_name', v_request.agency_name,
                'role', 'agency',
                'active_role', 'agency',
                'phone_number', v_request.phone_number,
                'is_demo', true
            ),
            false,
            false,
            false
        );
    ELSE
        -- Update existing user password, instance_id, and GoTrue token columns
        UPDATE auth.users
        SET instance_id = COALESCE(instance_id, v_instance_id),
            aud = 'authenticated',
            role = 'authenticated',
            encrypted_password = extensions.crypt(v_temp_password, extensions.gen_salt('bf')),
            email_confirmed_at = COALESCE(email_confirmed_at, now()),
            confirmation_token = COALESCE(confirmation_token, ''),
            recovery_token = COALESCE(recovery_token, ''),
            email_change_token_new = COALESCE(email_change_token_new, ''),
            email_change = COALESCE(email_change, ''),
            email_change_token_current = COALESCE(email_change_token_current, ''),
            reauthentication_token = COALESCE(reauthentication_token, ''),
            phone = CASE WHEN phone = '' THEN NULL ELSE phone END,
            phone_change = COALESCE(phone_change, ''),
            phone_change_token = COALESCE(phone_change_token, ''),
            raw_app_meta_data = '{"provider":"email","providers":["email"]}'::jsonb,
            raw_user_meta_data = COALESCE(raw_user_meta_data, '{}'::jsonb) || jsonb_build_object(
                'role', 'agency',
                'active_role', 'agency',
                'is_demo', true,
                'phone_number', COALESCE(v_request.phone_number, raw_user_meta_data->>'phone_number')
            ),
            is_sso_user = COALESCE(is_sso_user, false),
            is_anonymous = COALESCE(is_anonymous, false),
            updated_at = now()
        WHERE id = v_user_id;
    END IF;

    -- Ensure auth.identities has record
    INSERT INTO auth.identities (
        id,
        user_id,
        identity_data,
        provider,
        provider_id,
        last_sign_in_at,
        created_at,
        updated_at
    ) VALUES (
        gen_random_uuid(),
        v_user_id,
        json_build_object('sub', v_user_id::text, 'email', lower(v_request.email)),
        'email',
        lower(v_request.email),
        now(),
        now(),
        now()
    ) ON CONFLICT (provider_id, provider) DO UPDATE SET
        identity_data = EXCLUDED.identity_data,
        updated_at = now();

    v_modules := COALESCE(v_request.selected_modules, ARRAY['portfolio_distribution', 'property_lease_management']::TEXT[]);

    -- Upsert public.profiles with 7 days sandbox expiration
    INSERT INTO public.profiles (
        id, email, full_name, role, active_role, company_name, website_url, phone_number, is_demo, demo_expires_at, active_modules, created_at, updated_at
    ) VALUES (
        v_user_id, lower(v_request.email), v_request.agency_name, 'agency', 'agency', v_request.agency_name,
        v_request.website, v_request.phone_number, true, (now() + interval '7 days'), v_modules, now(), now()
    ) ON CONFLICT (id) DO UPDATE SET
        role = 'agency',
        active_role = 'agency',
        company_name = EXCLUDED.company_name,
        website_url = EXCLUDED.website_url,
        phone_number = COALESCE(EXCLUDED.phone_number, profiles.phone_number),
        is_demo = true,
        demo_expires_at = (now() + interval '7 days'),
        active_modules = COALESCE(v_modules, profiles.active_modules),
        updated_at = now();

    IF NOT EXISTS (SELECT 1 FROM public.properties WHERE agency_id = v_user_id) THEN
        PERFORM public.generate_agency_demo_data(v_user_id);
        -- Ensure 7-day retention is preserved after demo data generation
        UPDATE public.profiles
        SET demo_expires_at = (now() + interval '7 days'),
            updated_at = now()
        WHERE id = v_user_id;
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'message', CASE 
            WHEN v_was_expired THEN 'Demo süreniz 7 gün olarak yenilendi ve portföyünüz hazırlandı.' 
            ELSE 'Hesabınız başarıyla 7 günlük sandbox olarak aktifleştirildi.' 
        END,
        'was_expired', v_was_expired,
        'user_id', v_user_id,
        'email', lower(v_request.email),
        'agency_name', v_request.agency_name,
        'active_modules', v_modules,
        'temp_password', v_temp_password
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.verify_agency_demo_token(UUID) TO anon, authenticated, service_role;

-- 3. Repair any existing demo users created with NULL instance_id or NULL GoTrue token columns
UPDATE auth.users
SET instance_id = COALESCE(instance_id, '00000000-0000-0000-0000-000000000000'::uuid),
    aud = COALESCE(aud, 'authenticated'),
    role = COALESCE(role, 'authenticated'),
    confirmation_token = COALESCE(confirmation_token, ''),
    recovery_token = COALESCE(recovery_token, ''),
    email_change_token_new = COALESCE(email_change_token_new, ''),
    email_change = COALESCE(email_change, ''),
    email_change_token_current = COALESCE(email_change_token_current, ''),
    reauthentication_token = COALESCE(reauthentication_token, ''),
    phone = CASE WHEN phone = '' THEN NULL ELSE phone END,
    phone_change = COALESCE(phone_change, ''),
    phone_change_token = COALESCE(phone_change_token, ''),
    is_sso_user = COALESCE(is_sso_user, false),
    is_anonymous = COALESCE(is_anonymous, false),
    updated_at = now()
WHERE instance_id IS NULL
   OR confirmation_token IS NULL
   OR recovery_token IS NULL
   OR email_change_token_new IS NULL;
