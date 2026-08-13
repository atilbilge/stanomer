-- Migration: 2026-08-13_create_email_unsubscribes
-- Description: E-posta abonelik iptali kayıtları için tablo
-- Target: DEV (thvbpifahvasyzmngpzp) → production_migration_sync.sql ile canlıya alınacak

CREATE TABLE IF NOT EXISTS public.email_unsubscribes (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email       TEXT NOT NULL,
    unsubscribed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    source      TEXT DEFAULT 'unsubscribe_page', -- nereden geldiği (unsubscribe_page, manual, etc.)
    ip_address  TEXT,                             -- opsiyonel: rate-limiting için
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Unique index: aynı email birden fazla kez kayıt olmasın
CREATE UNIQUE INDEX IF NOT EXISTS email_unsubscribes_email_idx
    ON public.email_unsubscribes (lower(email));

-- RLS
ALTER TABLE public.email_unsubscribes ENABLE ROW LEVEL SECURITY;

-- Herkes insert yapabilir (public unsubscribe endpoint)
DROP POLICY IF EXISTS "email_unsubscribes_insert_policy" ON public.email_unsubscribes;
CREATE POLICY "email_unsubscribes_insert_policy" ON public.email_unsubscribes
    FOR INSERT TO public WITH CHECK (true);

-- Sadece authenticated kullanıcılar (admin) okuyabilir
DROP POLICY IF EXISTS "email_unsubscribes_select_policy" ON public.email_unsubscribes;
CREATE POLICY "email_unsubscribes_select_policy" ON public.email_unsubscribes
    FOR SELECT TO authenticated USING (true);
