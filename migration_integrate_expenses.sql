-- Migration: Integrate Expenses into Financials
-- This script adds categorization to payments and updates generation logic

-- 1. Update rent_payments table structure & cleanup
UPDATE public.rent_payments SET title = 'Kira' WHERE title IS NULL;
UPDATE public.rent_payments SET receiver_type = 'owner' WHERE receiver_type IS NULL;

ALTER TABLE public.rent_payments 
ALTER COLUMN title SET DEFAULT 'Kira',
ALTER COLUMN title SET NOT NULL,
ALTER COLUMN receiver_type SET DEFAULT 'owner';

-- Ensure invoice_url exists
ALTER TABLE public.rent_payments ADD COLUMN IF NOT EXISTS invoice_url TEXT;

-- 2. Update the unique constraint (Idempotent)
DO $$ 
BEGIN
    ALTER TABLE public.rent_payments DROP CONSTRAINT IF EXISTS rent_payments_property_id_due_date_key;
    ALTER TABLE public.rent_payments DROP CONSTRAINT IF EXISTS rent_payments_property_id_due_date_title_key;
EXCEPTION
    WHEN undefined_object THEN null;
END $$;

ALTER TABLE public.rent_payments 
ADD CONSTRAINT rent_payments_property_id_due_date_title_key UNIQUE (property_id, due_date, title);

-- 3. Robust generation RPC
CREATE OR REPLACE FUNCTION generate_missing_rent_payments(p_property_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_active_contract RECORD;
    v_start_date DATE;
    v_end_date DATE;
    v_current_date DATE;
    v_expense JSONB;
    v_exp_name TEXT;
    v_exp_amount NUMERIC;
    v_exp_receiver TEXT;
BEGIN
    -- 1. Get the active contract
    SELECT * INTO v_active_contract
    FROM contracts
    WHERE property_id = p_property_id AND status = 'active'
    LIMIT 1;

    IF NOT FOUND THEN
        RETURN;
    END IF;

    -- 2. Date ranges
    v_start_date := COALESCE(v_active_contract.start_date::DATE, CURRENT_DATE);
    v_end_date := COALESCE(v_active_contract.end_date::DATE, (v_start_date + INTERVAL '1 year')::DATE);

    -- 3. Iterate through months
    v_current_date := v_start_date;
    WHILE v_current_date <= v_end_date AND v_current_date <= (CURRENT_DATE + INTERVAL '1 month') LOOP
        
        -- A. Rent Record
        INSERT INTO rent_payments (property_id, tenant_id, amount, currency, due_date, status, title, receiver_type)
        VALUES (
            p_property_id,
            v_active_contract.tenant_id,
            v_active_contract.monthly_rent,
            v_active_contract.currency,
            v_current_date,
            'pending',
            'Kira',
            'owner'
        )
        ON CONFLICT (property_id, due_date, title) DO NOTHING;

        -- B. Expense Records (Manual iteration for robustness)
        IF v_active_contract.expenses_config IS NOT NULL AND jsonb_array_length(v_active_contract.expenses_config) > 0 THEN
            FOR v_expense IN SELECT jsonb_array_elements(v_active_contract.expenses_config)
            LOOP
                v_exp_name := v_expense->>'name';
                v_exp_amount := (v_expense->>'amount')::NUMERIC;
                v_exp_receiver := v_expense->>'receiver';

                -- Only tenant-to-owner payments are tracked in Financials
                IF v_exp_name IS NOT NULL AND v_exp_receiver = 'owner' THEN
                    INSERT INTO rent_payments (property_id, tenant_id, amount, currency, due_date, status, title, receiver_type)
                    VALUES (
                        p_property_id,
                        v_active_contract.tenant_id,
                        COALESCE(v_exp_amount, 0),
                        v_active_contract.currency,
                        v_current_date,
                        'pending',
                        v_exp_name,
                        'owner'
                    )
                    ON CONFLICT (property_id, due_date, title) DO NOTHING;
                END IF;
            END LOOP;
        END IF;

        v_current_date := (v_current_date + INTERVAL '1 month')::DATE;
    END LOOP;
END;
$$;
