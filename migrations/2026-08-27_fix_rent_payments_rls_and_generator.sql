-- ============================================================================
-- Migration: 2026-08-27_fix_rent_payments_rls_and_generator.sql
-- Description: 
--   1. Ensures RLS policies on public.rent_payments allow landlords and agencies
--      to view and manage rent payments through properties table join.
--   2. Updates generate_missing_rent_payments RPC to link contract_id properly.
-- Target DB: DEV ONLY (thvbpifahvasyzmngpzp)
-- ============================================================================

-- 1. Ensure contract_id exists on rent_payments
ALTER TABLE public.rent_payments ADD COLUMN IF NOT EXISTS contract_id UUID REFERENCES public.contracts(id) ON DELETE CASCADE;

-- 2. Update RLS Policies on rent_payments for complete multi-role access
DROP POLICY IF EXISTS "Users can view rent payments" ON public.rent_payments;
DROP POLICY IF EXISTS "rent_payments_select_policy" ON public.rent_payments;
DROP POLICY IF EXISTS "landlord_select_rent_payments" ON public.rent_payments;
DROP POLICY IF EXISTS "tenant_select_rent_payments" ON public.rent_payments;

CREATE POLICY "Users can view rent payments" ON public.rent_payments 
FOR SELECT TO authenticated 
USING (
    tenant_id = auth.uid() 
    OR public.is_agency_of_property(property_id, auth.uid())
    OR EXISTS (
        SELECT 1 FROM public.properties p 
        WHERE p.id = rent_payments.property_id 
          AND (p.landlord_id = auth.uid() OR p.tenant_id = auth.uid() OR p.agency_id = auth.uid())
    )
);

DROP POLICY IF EXISTS "Landlords and tenants can update rent payments" ON public.rent_payments;
DROP POLICY IF EXISTS "rent_payments_update_policy" ON public.rent_payments;
DROP POLICY IF EXISTS "landlord_update_rent_payments" ON public.rent_payments;
DROP POLICY IF EXISTS "tenant_update_rent_payments" ON public.rent_payments;

CREATE POLICY "Landlords and tenants can update rent payments" ON public.rent_payments 
FOR UPDATE TO authenticated 
USING (
    tenant_id = auth.uid() 
    OR public.is_agency_of_property(property_id, auth.uid())
    OR EXISTS (
        SELECT 1 FROM public.properties p 
        WHERE p.id = rent_payments.property_id 
          AND (p.landlord_id = auth.uid() OR p.tenant_id = auth.uid() OR p.agency_id = auth.uid())
    )
);

DROP POLICY IF EXISTS "Landlords and agencies can insert rent payments" ON public.rent_payments;
DROP POLICY IF EXISTS "rent_payments_insert_policy" ON public.rent_payments;

CREATE POLICY "Landlords and agencies can insert rent payments" ON public.rent_payments 
FOR INSERT TO authenticated 
WITH CHECK (
    public.is_agency_of_property(property_id, auth.uid())
    OR EXISTS (
        SELECT 1 FROM public.properties p 
        WHERE p.id = rent_payments.property_id 
          AND (p.landlord_id = auth.uid() OR p.agency_id = auth.uid())
    )
);

-- 3. Update generate_missing_rent_payments RPC
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
  -- Get active contract for the property
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

  -- Deduplicate pending rows if paid/declared exists
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

  v_current_date := v_start_date;
  WHILE v_current_date <= v_end_date AND v_current_date <= (date_trunc('month', CURRENT_DATE + INTERVAL '1 month') + (v_due_day - 1) * INTERVAL '1 day')::DATE LOOP
    
    SELECT EXISTS (
      SELECT 1 FROM public.rent_payments
      WHERE property_id = p_property_id
        AND LOWER(TRIM(title)) = 'kira'
        AND date_trunc('month', due_date) = date_trunc('month', v_current_date)
    ) INTO v_exists;

    IF NOT v_exists THEN
      INSERT INTO public.rent_payments (
        property_id, contract_id, tenant_id,
        amount, currency, due_date, status, title, receiver_type
      )
      VALUES (
        p_property_id,
        v_active_contract.id,
        v_active_contract.tenant_id,
        v_active_contract.monthly_rent,
        v_active_contract.currency,
        v_current_date,
        'pending',
        'Kira',
        'owner'
      );
    END IF;

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
            INSERT INTO public.rent_payments (
              property_id, contract_id, tenant_id,
              amount, currency, due_date, status, title, receiver_type
            )
            VALUES (
              p_property_id,
              v_active_contract.id,
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

    v_current_date := (date_trunc('month', v_current_date + INTERVAL '1 month') + (v_due_day - 1) * INTERVAL '1 day')::DATE;
  END LOOP;
END;
$$;
