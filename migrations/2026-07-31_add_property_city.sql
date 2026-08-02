-- Migration: 2026-07-31_add_property_city.sql
-- Description: Add city column to public.properties table for city-based filtering and grouping.

ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS city TEXT;
