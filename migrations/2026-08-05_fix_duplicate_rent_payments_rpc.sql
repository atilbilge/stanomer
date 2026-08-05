-- 2026-08-05: Fix duplicate rent and expense payments generation RPC
-- Ensures only 1 payment row exists per (property_id, title, month) and cleans up orphaned/duplicate pending rows.

CREATE OR REPLACE FUNCTION public.generate_missing_rent_payments(p_property_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_active_contract RECORD;
  v_start_date DATE;
  v_end_date DATE;
  v_current_date DATE;
  v_due_day INTEGER;
  v_expense JSONB;
  v_exp_name TEXT;
  v_exp_amount NUMERIC;
  v_exp_receiver TEXT;
  v_exists BOOLEAN;
BEGIN
  -- 1. Get the active contract
  SELECT * INTO v_active_contract
  FROM contracts
  WHERE property_id = p_property_id AND status = 'active'
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN;
  END IF;

  v_due_day := COALESCE(v_active_contract.due_day, 1);
  v_start_date := (date_trunc('month', COALESCE(v_active_contract.start_date::DATE, CURRENT_DATE)) + (v_due_day - 1) * INTERVAL '1 day')::DATE;
  v_end_date := COALESCE(v_active_contract.end_date::DATE, (v_start_date + INTERVAL '1 year')::DATE);

  -- 2. Cleanup any orphaned dummy pending rows where a paid, declared or duplicate pending record exists for the same title & month
  DELETE FROM public.rent_payments p1
  USING public.rent_payments p2
  WHERE p1.property_id = p_property_id
    AND p1.property_id = p2.property_id
    AND LOWER(TRIM(p1.title)) = LOWER(TRIM(p2.title))
    AND date_trunc('month', p1.due_date) = date_trunc('month', p2.due_date)
    AND p1.status = 'pending'
    AND (
      p2.status IN ('paid', 'declared')
      OR (p2.status = 'pending' AND p1.id > p2.id)
    );

  -- 3. Iterate through months and create missing payment entries safely
  v_current_date := v_start_date;
  WHILE v_current_date <= v_end_date AND v_current_date <= (date_trunc('month', CURRENT_DATE + INTERVAL '1 month') + (v_due_day - 1) * INTERVAL '1 day')::DATE LOOP
    
    -- A. Rent Record: Check if ANY record for Kira exists in this month
    SELECT EXISTS (
      SELECT 1 FROM public.rent_payments
      WHERE property_id = p_property_id
        AND LOWER(TRIM(title)) = 'kira'
        AND date_trunc('month', due_date) = date_trunc('month', v_current_date)
    ) INTO v_exists;

    IF NOT v_exists THEN
      INSERT INTO public.rent_payments (property_id, tenant_id, amount, currency, due_date, status, title, receiver_type)
      VALUES (
        p_property_id,
        v_active_contract.tenant_id,
        v_active_contract.monthly_rent,
        v_active_contract.currency,
        v_current_date,
        'pending',
        'Kira',
        'owner'
      );
    END IF;

    -- B. Expense Records: Check if ANY record for this expense exists in this month
    IF v_active_contract.expenses_config IS NOT NULL AND jsonb_array_length(v_active_contract.expenses_config) > 0 THEN
      FOR v_expense IN SELECT jsonb_array_elements(v_active_contract.expenses_config)
      LOOP
        v_exp_name := TRIM(v_expense->>'name');
        v_exp_amount := (v_expense->>'amount')::NUMERIC;
        v_exp_receiver := v_expense->>'receiver';

        IF v_exp_name IS NOT NULL AND v_exp_receiver = 'owner' THEN
          SELECT EXISTS (
            SELECT 1 FROM public.rent_payments
            WHERE property_id = p_property_id
              AND LOWER(TRIM(title)) = LOWER(v_exp_name)
              AND date_trunc('month', due_date) = date_trunc('month', v_current_date)
          ) INTO v_exists;

          IF NOT v_exists THEN
            INSERT INTO public.rent_payments (property_id, tenant_id, amount, currency, due_date, status, title, receiver_type)
            VALUES (
              p_property_id,
              v_active_contract.tenant_id,
              COALESCE(v_exp_amount, 0),
              v_active_contract.currency,
              v_current_date,
              'pending',
              v_exp_name,
              'owner'
            );
          END IF;
        END IF;
      END LOOP;
    END IF;

    v_current_date := (date_trunc('month', v_current_date + INTERVAL '1.5 month') + (v_due_day - 1) * INTERVAL '1 day')::DATE;
  END LOOP;
END;
$$;

-- Run global cleanup across all properties once to remove existing duplicate DB rows
DELETE FROM public.rent_payments p1
USING public.rent_payments p2
WHERE p1.property_id = p2.property_id
  AND LOWER(TRIM(p1.title)) = LOWER(TRIM(p2.title))
  AND date_trunc('month', p1.due_date) = date_trunc('month', p2.due_date)
  AND p1.status = 'pending'
  AND (
    p2.status IN ('paid', 'declared')
    OR (p2.status = 'pending' AND p1.id > p2.id)
  );
