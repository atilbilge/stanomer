-- Migration: Link rent_payments to contract_id
-- Run this in the Supabase SQL Editor

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. Add contract_id column to rent_payments
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE public.rent_payments
ADD COLUMN IF NOT EXISTS contract_id UUID REFERENCES public.contracts(id) ON DELETE SET NULL;

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. Back-fill contract_id for existing rows
--    Match by property_id and pick the active/revision_requested contract.
--    For rows already paid/declared, try to find the closest-dated contract.
-- ─────────────────────────────────────────────────────────────────────────────
UPDATE public.rent_payments rp
SET contract_id = c.id
FROM public.contracts c
WHERE c.property_id = rp.property_id
  AND c.status IN ('active', 'revision_requested')
  AND rp.contract_id IS NULL;

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. Drop old unique constraint on (property_id, due_date)
--    and create a new one on (contract_id, due_date, title)
--    so each contract generates exactly one bill per month per bill type.
-- ─────────────────────────────────────────────────────────────────────────────
-- Find and drop whichever constraint covers (property_id, due_date):
DO $$
DECLARE
  v_constraint text;
BEGIN
  SELECT conname INTO v_constraint
  FROM pg_constraint
  WHERE conrelid = 'public.rent_payments'::regclass
    AND contype = 'u'
    AND array_to_string(
          ARRAY(
            SELECT attname FROM pg_attribute
            WHERE attrelid = conrelid AND attnum = ANY(conkey)
          ), ',') LIKE '%property_id%due_date%'
       OR array_to_string(
          ARRAY(
            SELECT attname FROM pg_attribute
            WHERE attrelid = conrelid AND attnum = ANY(conkey)
          ), ',') LIKE '%due_date%property_id%';
  IF v_constraint IS NOT NULL THEN
    EXECUTE format('ALTER TABLE public.rent_payments DROP CONSTRAINT IF EXISTS %I', v_constraint);
  END IF;
END;
$$;

-- Hard-drop by common legacy name (safe to ignore if not exists):
ALTER TABLE public.rent_payments
  DROP CONSTRAINT IF EXISTS rent_payments_property_id_due_date_key;

ALTER TABLE public.rent_payments
  DROP CONSTRAINT IF EXISTS rent_payments_property_id_due_date_title_key;

ALTER TABLE public.rent_payments
  DROP CONSTRAINT IF EXISTS rent_payments_contract_due_date_title_key;

-- New unique constraint per contract:
ALTER TABLE public.rent_payments
  ADD CONSTRAINT rent_payments_contract_due_date_title_key
  UNIQUE NULLS NOT DISTINCT (contract_id, due_date, title);

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. Update the generate RPC to be contract-aware + include owner expenses
CREATE OR REPLACE FUNCTION public.generate_missing_rent_payments(p_property_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_contract_id   uuid;
  v_start_date    date;
  v_end_date      date;
  v_current_date  date;
  v_monthly_rent  numeric;
  v_currency      text;
  v_tenant_id     uuid;
  v_due_day       integer;
  v_expenses_cfg  jsonb;
  v_expense       jsonb;
  v_exp_name      text;
  v_exp_amount    numeric;
  v_exp_receiver  text;
  v_approved_row  record;
BEGIN
  -- Get the ACTIVE contract for the property
  SELECT id, start_date, monthly_rent, currency, tenant_id,
         COALESCE(due_day, 1), COALESCE(expenses_config, '[]'::jsonb)
  INTO v_contract_id, v_start_date, v_monthly_rent, v_currency, v_tenant_id, v_due_day, v_expenses_cfg
  FROM public.contracts
  WHERE property_id = p_property_id AND status = 'active'
  ORDER BY updated_at DESC
  LIMIT 1;

  -- No active contract → nothing to do
  IF v_contract_id IS NULL OR v_monthly_rent IS NULL OR v_tenant_id IS NULL THEN
    RETURN;
  END IF;

  -- AUTO-APPROVE: Mark 'declared' as 'paid' after 5 days
  FOR v_approved_row IN
    UPDATE public.rent_payments
    SET status = 'paid', paid_at = (declared_at + interval '5 days')
    WHERE contract_id = v_contract_id
      AND status = 'declared'
      AND declared_at < (now() - interval '5 days')
    RETURNING id, due_date
  LOOP
    INSERT INTO public.activity_logs (property_id, type, metadata)
    VALUES (p_property_id, 'rent_auto_approved',
            jsonb_build_object('month', v_approved_row.due_date));
  END LOOP;

  -- CLEANUP: Remove pending rows before contract start month
  DELETE FROM public.rent_payments
  WHERE contract_id = v_contract_id
    AND status = 'pending'
    AND date_trunc('month', due_date) < date_trunc('month', v_start_date);

  -- Generate rows from start to 1 month from now
  v_current_date := (date_trunc('month', v_start_date) + (v_due_day - 1) * interval '1 day')::date;
  v_end_date     := (date_trunc('month', now() + interval '1 month') + (v_due_day - 1) * interval '1 day')::date;

  WHILE v_current_date <= v_end_date LOOP

    -- A. Ana kira satırı
    INSERT INTO public.rent_payments
      (property_id, contract_id, tenant_id, amount, currency, due_date, status, title, receiver_type)
    VALUES
      (p_property_id, v_contract_id, v_tenant_id, v_monthly_rent, v_currency, v_current_date, 'pending', 'Kira', 'owner')
    ON CONFLICT (contract_id, due_date, title)
    DO UPDATE SET
      amount    = EXCLUDED.amount,
      currency  = EXCLUDED.currency,
      tenant_id = COALESCE(EXCLUDED.tenant_id, rent_payments.tenant_id)
    WHERE rent_payments.status = 'pending';

    -- B. Masraf kalemleri: sadece receiver = 'owner' (kiracı → ev sahibi) olanlar
    IF jsonb_array_length(v_expenses_cfg) > 0 THEN
      FOR v_expense IN SELECT jsonb_array_elements(v_expenses_cfg)
      LOOP
        v_exp_name     := v_expense->>'name';
        v_exp_amount   := COALESCE((v_expense->>'amount')::numeric, 0);
        v_exp_receiver := v_expense->>'receiver';

        IF v_exp_name IS NOT NULL AND v_exp_receiver = 'owner' THEN
          INSERT INTO public.rent_payments
            (property_id, contract_id, tenant_id, amount, currency, due_date, status, title, receiver_type)
          VALUES
            (p_property_id, v_contract_id, v_tenant_id, v_exp_amount, v_currency, v_current_date, 'pending', v_exp_name, 'owner')
          ON CONFLICT (contract_id, due_date, title)
          DO UPDATE SET
            -- If an invoice was uploaded, DO NOT overwrite the manually set amount and currency!
            amount    = CASE WHEN rent_payments.invoice_url IS NOT NULL THEN rent_payments.amount ELSE EXCLUDED.amount END,
            currency  = CASE WHEN rent_payments.invoice_url IS NOT NULL THEN rent_payments.currency ELSE EXCLUDED.currency END,
            tenant_id = COALESCE(EXCLUDED.tenant_id, rent_payments.tenant_id)
          WHERE rent_payments.status = 'pending';
        END IF;
      END LOOP;
    END IF;

    v_current_date := (date_trunc('month', v_current_date + interval '1.5 month') + (v_due_day - 1) * interval '1 day')::date;
  END LOOP;
END;
$$;
