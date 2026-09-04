-- Migration: Add tenant details, secondary contacts, and payment methods to contracts and rent_payments
-- Target: Dev Supabase (thvbpifahvasyzmngpzp)

-- 1. Add tenant extra fields to contracts table
ALTER TABLE contracts
  ADD COLUMN IF NOT EXISTS tenant_name TEXT,
  ADD COLUMN IF NOT EXISTS tenant_id_number TEXT,
  ADD COLUMN IF NOT EXISTS tenant_phone TEXT,
  ADD COLUMN IF NOT EXISTS tenant_notes TEXT,
  ADD COLUMN IF NOT EXISTS tenant_id_document_url TEXT,
  ADD COLUMN IF NOT EXISTS tenant_secondary_contacts JSONB DEFAULT '[]'::jsonb;

-- 2. Add payment_method to rent_payments table
ALTER TABLE rent_payments
  ADD COLUMN IF NOT EXISTS payment_method TEXT DEFAULT 'bank_transfer';

-- Ensure constraint for payment_method in rent_payments
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'check_rent_payments_payment_method'
  ) THEN
    ALTER TABLE rent_payments
      ADD CONSTRAINT check_rent_payments_payment_method
      CHECK (payment_method IN ('cash', 'bank_transfer'));
  END IF;
END $$;
