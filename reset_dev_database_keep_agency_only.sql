-- ==============================================================================
-- STANOMER DEV: TAM TEMİZLİK BETİĞİ (RESET DEV DATA - KEEP AGENCIES ONLY)
-- ==============================================================================
-- HEDEF VERİTABANI: YALNIZCA DEV Supabase (`thvbpifahvasyzmngpzp`)
-- 
-- DİKKAT: CANLI (PRODUCTION) VERİTABANINDA KESİNLİKLE ÇALIŞTIRILAMAZ!
-- Bu script; tüm mülkleri, sözleşmeleri, kira/borç kayıtlarını, arıza taleplerini,
-- logları, bildirimleri ve 'agency' HARİCİNDEKİ tüm ev sahibi ve kiracı
-- kullanıcılarını/profillerini sıfırlar.
-- SADECE rolü 'agency' olan kullanıcılar ve profiller korunur.
-- ==============================================================================

BEGIN;

-- 1. Aktivite & Bildirim Kayıtları
TRUNCATE TABLE public.activity_logs CASCADE;
TRUNCATE TABLE public.notifications CASCADE;

-- 2. Bakım & Arıza Modülü (Mesajlar, Masraflar, Talepler)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'maintenance_messages') THEN
        TRUNCATE TABLE public.maintenance_messages CASCADE;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'maintenance_charges') THEN
        TRUNCATE TABLE public.maintenance_charges CASCADE;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'maintenance_requests') THEN
        TRUNCATE TABLE public.maintenance_requests CASCADE;
    END IF;

    -- Arıza bilet numarası sequence'ini sıfırla (varsa)
    IF EXISTS (SELECT 1 FROM pg_sequences WHERE schemaname = 'public' AND sequencename = 'maintenance_request_ticket_seq') THEN
        ALTER SEQUENCE public.maintenance_request_ticket_seq RESTART WITH 1;
    END IF;
END $$;

-- 3. Finans & Kira Ödemeleri
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'rent_payments') THEN
        TRUNCATE TABLE public.rent_payments CASCADE;
    END IF;
END $$;

-- 4. Sözleşmeler ve Davetler
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'contracts') THEN
        TRUNCATE TABLE public.contracts CASCADE;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'invitations') THEN
        TRUNCATE TABLE public.invitations CASCADE;
    END IF;
END $$;

-- 5. Mülkler ve Hissedarlar / Malikler
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'property_owners') THEN
        TRUNCATE TABLE public.property_owners CASCADE;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'property_landlords') THEN
        TRUNCATE TABLE public.property_landlords CASCADE;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'properties') THEN
        TRUNCATE TABLE public.properties CASCADE;
    END IF;
END $$;

-- 6. Kullanıcılar & Profiller (YALNIZCA 'agency' rolündekiler KORUNUR)
-- Acente olmayan tüm kullanıcıları auth.users'dan sil
-- (public.profiles tablosu ON DELETE CASCADE ile otomatik olarak temizlenir)
DELETE FROM auth.users 
WHERE id NOT IN (
    SELECT id FROM public.profiles WHERE role = 'agency'
);

-- Varsa auth kaydı kalmamış yetkisiz/bağlantısız profil artıklarını temizle
DELETE FROM public.profiles 
WHERE role IS NULL OR role != 'agency';

COMMIT;

-- ==============================================================================
-- DOĞRULAMA SORGUSU (Temizlik sonrası veritabanı durumu)
-- ==============================================================================
SELECT 
    (SELECT COUNT(*) FROM public.properties) AS properties_count,
    (SELECT COUNT(*) FROM public.contracts) AS contracts_count,
    (SELECT COUNT(*) FROM public.rent_payments) AS rent_payments_count,
    (SELECT COUNT(*) FROM public.maintenance_requests) AS maintenance_requests_count,
    (SELECT COUNT(*) FROM public.invitations) AS invitations_count,
    (SELECT COUNT(*) FROM public.activity_logs) AS activity_logs_count,
    (SELECT COUNT(*) FROM public.notifications) AS notifications_count,
    (SELECT COUNT(*) FROM public.property_owners) AS property_owners_count,
    (SELECT COUNT(*) FROM public.profiles WHERE role = 'agency') AS remaining_agency_profiles,
    (SELECT COUNT(*) FROM public.profiles WHERE role != 'agency') AS remaining_non_agency_profiles,
    (SELECT COUNT(*) FROM auth.users) AS remaining_auth_users;
