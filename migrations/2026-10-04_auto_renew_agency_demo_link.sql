-- ==============================================================================
-- MIGRATION: 2026-10-04_auto_renew_agency_demo_link.sql
-- ==============================================================================
-- HEDEF: YALNIZCA DEV Supabase (`thvbpifahvasyzmngpzp`)
-- AÇIKLAMA:
-- 1. Süresi dolmuş demo bağlantısına tıklandığında hata fırlatmak yerine:
--    - Token geçerlilik süresi (token_expires_at) now() + 3 days olarak yenilenir.
--    - Acente profili demo_expires_at süresi now() + 3 days yapılır.
-- 2. "Data yoksa tekrar üret, varsa dokunma":
--    - Acentenin mülk kaydı (properties) bulunmuyorsa generate_agency_demo_data()
--      çalıştırılarak 10 dairelik örnek portföy yeniden oluşturulur.
--    - Mülk kayıtları zaten mevcutsa dokunulmaz, veri korunur.
-- 3. FIX: auth.users tablosundaki UNIQUE(phone) kısıtlaması (users_phone_key)
--    nedeniyle phone kolonu boş dize ('') yerine NULL olmalıdır. Aksi halde
--    ikinci acente oluşturulurken duplicate key hatası alınır.
-- ==============================================================================

-- 1. auth.users'daki boş string ('') telefon kayıtlarını NULL yaparak unique index çakışmasını gider:
UPDATE auth.users SET phone = NULL WHERE phone = '';
UPDATE auth.users SET phone_change = NULL WHERE phone_change = '';

-- 2. verify_agency_demo_token fonksiyonunu güncelle:
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
            '', '', NULL, NULL, '',
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
            phone_change = CASE WHEN phone_change = '' THEN NULL ELSE phone_change END,
            phone_change_token = COALESCE(phone_change_token, ''),
            instance_id = COALESCE(instance_id, v_instance_id),
            aud = 'authenticated',
            role = 'authenticated',
            raw_app_meta_data = '{"provider":"email","providers":["email"]}'::jsonb,
            updated_at = now()
        WHERE id = v_user_id;
    END IF;

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
        'temp_password', v_temp_password
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.verify_agency_demo_token(UUID) TO anon, authenticated, service_role;
