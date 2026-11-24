-- ==============================================================================
-- MIGRATION: 2026-11-22_agency_demo_selected_modules.sql
-- TARGET DB: DEV ONLY (thvbpifahvasyzmngpzp) - ZERO IMPACT ON PRODUCTION!
-- PURPOSE: Store selected demo modules in agency_demo_requests and sync them
--          directly into public.profiles.active_modules upon demo verification.
-- ==============================================================================

-- 1. Add selected_modules to public.agency_demo_requests
ALTER TABLE public.agency_demo_requests
ADD COLUMN IF NOT EXISTS selected_modules TEXT[] DEFAULT ARRAY['portfolio_distribution', 'property_lease_management']::TEXT[];

-- 2. Update verify_agency_demo_token to assign selected modules to profiles.active_modules
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

    -- Süresi dolmuşsa tespit et ve linki 3 gün daha ötele (hata fırlatmak yerine yenile)
    IF v_request.token_expires_at IS NOT NULL AND v_request.token_expires_at < now() THEN
        v_was_expired := TRUE;
    END IF;

    UPDATE public.agency_demo_requests
    SET is_email_verified = TRUE,
        status = 'active_demo',
        token_expires_at = (now() + interval '3 days'),
        updated_at = now()
    WHERE id = v_request.id;

    -- Determine active modules from request (respect selected_modules from modal)
    IF v_request.selected_modules IS NOT NULL AND array_length(v_request.selected_modules, 1) > 0 THEN
        v_modules := v_request.selected_modules;
    ELSIF v_request.special_requests ILIKE '%portfolio_distribution%' AND v_request.special_requests NOT ILIKE '%property_lease_management%' THEN
        v_modules := ARRAY['portfolio_distribution'];
    ELSIF v_request.special_requests ILIKE '%property_lease_management%' AND v_request.special_requests NOT ILIKE '%portfolio_distribution%' THEN
        v_modules := ARRAY['property_lease_management'];
    ELSE
        v_modules := ARRAY['portfolio_distribution', 'property_lease_management'];
    END IF;

    SELECT instance_id INTO v_instance_id FROM auth.users WHERE instance_id IS NOT NULL LIMIT 1;
    IF v_instance_id IS NULL THEN
        v_instance_id := '00000000-0000-0000-0000-000000000000'::uuid;
    END IF;

    SELECT id INTO v_user_id FROM auth.users WHERE email = lower(v_request.email);

    IF v_user_id IS NULL THEN
        v_user_id := gen_random_uuid();
        INSERT INTO auth.users (
            id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
            confirmation_token, recovery_token, email_change_token_new, email_change,
            email_change_token_current, reauthentication_token, phone, phone_change, phone_change_token,
            raw_app_meta_data, raw_user_meta_data, is_super_admin, is_sso_user, is_anonymous, created_at, updated_at
        ) VALUES (
            v_user_id, v_instance_id, 'authenticated', 'authenticated',
            lower(v_request.email), extensions.crypt(v_temp_password, extensions.gen_salt('bf')),
            now(),
            '', '', '', '',
            '', '', NULL, '', '',
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
            phone = CASE WHEN phone = '' THEN NULL ELSE phone END,
            phone_change = COALESCE(NULLIF(phone_change, ''), ''),
            phone_change_token = COALESCE(phone_change_token, ''),
            instance_id = COALESCE(instance_id, v_instance_id),
            aud = 'authenticated',
            role = 'authenticated',
            raw_app_meta_data = '{"provider":"email","providers":["email"]}'::jsonb,
            updated_at = now()
        WHERE id = v_user_id;
    END IF;

    -- Kullanıcının GoTrue şema uyumluluğunu kesin garantiye al
    UPDATE auth.users
    SET phone = CASE WHEN phone = '' THEN NULL ELSE phone END,
        phone_change = COALESCE(phone_change, ''),
        phone_change_token = COALESCE(phone_change_token, '')
    WHERE id = v_user_id;

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

    INSERT INTO public.profiles (
        id, email, full_name, role, active_role, company_name, website_url, is_demo, demo_expires_at, active_modules, created_at, updated_at
    ) VALUES (
        v_user_id, lower(v_request.email), v_request.agency_name, 'agency', 'agency', v_request.agency_name,
        v_request.website, true, (now() + interval '3 days'), v_modules, now(), now()
    ) ON CONFLICT (id) DO UPDATE SET
        role = 'agency',
        active_role = 'agency',
        company_name = EXCLUDED.company_name,
        website_url = EXCLUDED.website_url,
        is_demo = true,
        demo_expires_at = (now() + interval '3 days'),
        active_modules = v_modules,
        updated_at = now();

    -- Data yoksa tekrar üret, varsa dokunma:
    IF NOT EXISTS (SELECT 1 FROM public.properties WHERE agency_id = v_user_id) THEN
        PERFORM public.generate_agency_demo_data(v_user_id);
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'message', CASE 
            WHEN v_was_expired THEN 'Demo süreniz 3 gün daha uzatıldı ve portföyünüz hazırlandı.' 
            ELSE 'Hesabınız başarıyla aktifleştirildi.' 
        END,
        'was_expired', v_was_expired,
        'user_id', v_user_id,
        'email', lower(v_request.email),
        'agency_name', v_request.agency_name,
        'temp_password', v_temp_password,
        'active_modules', v_modules
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.verify_agency_demo_token(UUID) TO anon, authenticated, service_role;
