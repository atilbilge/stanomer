-- Migration: Add UTM tracking columns to agency_demo_requests and profiles tables

-- 1. Add UTM columns to agency_demo_requests
ALTER TABLE public.agency_demo_requests
  ADD COLUMN IF NOT EXISTS utm_source TEXT DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS utm_medium TEXT DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS utm_campaign TEXT DEFAULT NULL;

-- 2. Add UTM columns to profiles
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS utm_source TEXT DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS utm_medium TEXT DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS utm_campaign TEXT DEFAULT NULL;

-- 3. Update handle_new_user trigger function to capture UTM params from raw_user_meta_data
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (
        id, 
        full_name, 
        role, 
        email, 
        active_role,
        utm_source,
        utm_medium,
        utm_campaign
    )
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email),
        COALESCE((NEW.raw_user_meta_data->>'role')::public.user_role, 'landlord'),
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'role', 'landlord'),
        NEW.raw_user_meta_data->>'utm_source',
        NEW.raw_user_meta_data->>'utm_medium',
        NEW.raw_user_meta_data->>'utm_campaign'
    )
    ON CONFLICT (id) DO UPDATE
    SET full_name = EXCLUDED.full_name,
        email = EXCLUDED.email,
        utm_source = COALESCE(EXCLUDED.utm_source, public.profiles.utm_source),
        utm_medium = COALESCE(EXCLUDED.utm_medium, public.profiles.utm_medium),
        utm_campaign = COALESCE(EXCLUDED.utm_campaign, public.profiles.utm_campaign);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
