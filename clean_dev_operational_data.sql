-- ==============================================================================
-- STANOMER DEV VERİTABANI OPERASYONEL VERİ TEMİZLİK BETİĞİ (RESET DEV OPERATIONAL DATA)
-- ==============================================================================
-- HEDEF VERİTABANI: YALNIZCA DEV Supabase (`thvbpifahvasyzmngpzp`)
-- KULLANIM AMACI: Test sürecinde oluşturulan mülk, sözleşme, ödeme, bakım talebi ve
--                 bağlantılı tüm operasyonel kayıtları güvenli biçimde siler.
--
-- DİKKAT: CANLI (PRODUCTION) VERİTABANINDA ÇALIŞTIRILAMAZ!
-- ==============================================================================

DO $$ 
BEGIN
    -- 1. Aktivite Logları
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'activity_logs') THEN
        TRUNCATE TABLE public.activity_logs CASCADE;
    END IF;

    -- 2. Bakım Talepleri ve Mesajları
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'maintenance_messages') THEN
        TRUNCATE TABLE public.maintenance_messages CASCADE;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'maintenance_requests') THEN
        TRUNCATE TABLE public.maintenance_requests CASCADE;
    END IF;

    -- 3. Bildirimler (Opsiyonel temizlik)
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'notifications') THEN
        TRUNCATE TABLE public.notifications CASCADE;
    END IF;

    -- 4. Ödemeler
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'rent_payments') THEN
        TRUNCATE TABLE public.rent_payments CASCADE;
    END IF;

    -- 5. Sözleşmeler ve Davetiyeler
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'contracts') THEN
        TRUNCATE TABLE public.contracts CASCADE;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'invitations') THEN
        TRUNCATE TABLE public.invitations CASCADE;
    END IF;

    -- 6. Mülk Ortaklıkları ve Mülkler
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'property_landlords') THEN
        TRUNCATE TABLE public.property_landlords CASCADE;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'properties') THEN
        TRUNCATE TABLE public.properties CASCADE;
    END IF;

END $$;

-- ------------------------------------------------------------------------------
-- TEMİZLİK SONRASI KONTROL QUERY'Sİ (Tablolardaki güncel kayıt sayıları)
-- ------------------------------------------------------------------------------
SELECT 
    (SELECT COUNT(*) FROM public.properties) AS property_count,
    (SELECT COUNT(*) FROM public.contracts) AS contract_count,
    (SELECT COUNT(*) FROM public.rent_payments) AS payment_count,
    (SELECT COUNT(*) FROM public.maintenance_requests) AS maintenance_count,
    (SELECT COUNT(*) FROM public.invitations) AS invitation_count,
    (SELECT COUNT(*) FROM public.activity_logs) AS log_count,
    (SELECT COUNT(*) FROM public.profiles) AS profile_count;
