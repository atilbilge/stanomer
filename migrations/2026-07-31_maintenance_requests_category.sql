-- Migration: 2026-07-31_maintenance_requests_category.sql
-- Description: Add category, priority, contract_id and photo_urls columns to public.maintenance_requests table.

ALTER TABLE public.maintenance_requests ADD COLUMN IF NOT EXISTS category TEXT DEFAULT 'other';
ALTER TABLE public.maintenance_requests ADD COLUMN IF NOT EXISTS priority TEXT DEFAULT 'normal';
ALTER TABLE public.maintenance_requests ADD COLUMN IF NOT EXISTS photos_urls TEXT[] DEFAULT '{}';
ALTER TABLE public.maintenance_requests ADD COLUMN IF NOT EXISTS photo_urls TEXT[] DEFAULT '{}';
ALTER TABLE public.maintenance_requests ADD COLUMN IF NOT EXISTS contract_id UUID REFERENCES public.contracts(id) ON DELETE SET NULL;
