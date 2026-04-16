-- Migration: Add owner_note column to rent_payments
-- Run this in the Supabase SQL Editor

ALTER TABLE public.rent_payments
ADD COLUMN IF NOT EXISTS owner_note TEXT;

-- Clear owner_note when a tenant declares/pays just in case
-- (Actually it's better to clear it when landlord approves or reject if needed, 
-- but usually owner_note is specifically for the latest update)
