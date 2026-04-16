-- Contracts Table and Negotiation Flow Migration
-- Run this in the Supabase SQL Editor

-- 1. Create status enum if it doesn't exist
DO $$ BEGIN
    CREATE TYPE contract_status AS ENUM ('pending', 'negotiating', 'active', 'declined');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 2. Create the contracts table
CREATE TABLE IF NOT EXISTS public.contracts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
    landlord_id UUID NOT NULL REFERENCES auth.users(id),
    inviter_name TEXT, -- For display in dashboard
    tenant_id UUID REFERENCES auth.users(id),
    invitee_email TEXT NOT NULL,
    
    -- Agreement Terms (Moving from properties to here for negotiation)
    monthly_rent NUMERIC NOT NULL,
    deposit_amount NUMERIC,
    currency TEXT NOT NULL DEFAULT 'EUR',
    due_day INTEGER NOT NULL DEFAULT 1,
    start_date TIMESTAMPTZ,
    end_date TIMESTAMPTZ,
    
    -- Expense Structure (JSONB)
    -- Expected format: [{"name": "infostan", "included": true, "amount": 0.0}, ...]
    expenses_config JSONB DEFAULT '[]'::jsonb,
    
    -- Negotiation & Feedback
    status contract_status DEFAULT 'pending',
    tenant_feedback TEXT,
    token TEXT UNIQUE NOT NULL, -- For deep links
    
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 3. Update properties table to store the template/default expenses
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS expenses_template JSONB DEFAULT '[]'::jsonb;

-- 4. Enable RLS
ALTER TABLE public.contracts ENABLE ROW LEVEL SECURITY;

-- 5. Policies
DROP POLICY IF EXISTS landlord_manage_contracts ON public.contracts;
CREATE POLICY landlord_manage_contracts ON public.contracts
    FOR ALL
    USING (auth.uid() = landlord_id);

DROP POLICY IF EXISTS tenant_view_update_contracts ON public.contracts;
CREATE POLICY tenant_view_update_contracts ON public.contracts
    FOR SELECT
    USING (LOWER(invitee_email) = LOWER(auth.jwt() ->> 'email'));

DROP POLICY IF EXISTS tenant_respond_contract ON public.contracts;
CREATE POLICY tenant_respond_contract ON public.contracts
    FOR UPDATE
    USING (LOWER(invitee_email) = LOWER(auth.jwt() ->> 'email'))
    WITH CHECK (status IN ('negotiating', 'active', 'declined'));

-- 6. Trigger to update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS set_contracts_updated_at ON public.contracts;
CREATE TRIGGER set_contracts_updated_at
    BEFORE UPDATE ON public.contracts
    FOR EACH ROW
    EXECUTE PROCEDURE update_updated_at_column();
