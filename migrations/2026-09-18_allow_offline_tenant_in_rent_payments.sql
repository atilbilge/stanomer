-- ==============================================================================
-- Migration: Allow offline/unregistered tenants in generate_missing_rent_payments
-- and add offline activation RPCs for agencies
-- Target Database: Dev & Production Migration
-- Date: 2026-09-18
-- Description:
--   1. Removes the 'OR v_tenant_id IS NULL' exit condition in generate_missing_rent_payments.
--   2. Adds RLS UPDATE policy on public.invitations for agencies and inviters.
--   3. Adds confirm_landlord_offline SECURITY DEFINER RPC.
--   4. Adds activate_contract_offline SECURITY DEFINER RPC.
--
-- Safe & Idempotent
-- ==============================================================================

-- 1. Updated generate_missing_rent_payments
CREATE OR REPLACE FUNCTION public.generate_missing_rent_payments(p_property_id uuid)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER
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

  -- No active contract or monthly rent → nothing to do
  -- Note: v_tenant_id can be NULL for offline / physical contracts managed by agencies
  IF v_contract_id IS NULL OR v_monthly_rent IS NULL THEN
    RETURN;
  END IF;

  -- AUTO-APPROVE: Mark 'declared' as 'paid' after 5 days
  -- NOTE: Only applies to tenant-declared payments (receiver_type = 'owner'),
  --       NOT to landlord-declared included expenses.
  FOR v_approved_row IN
    UPDATE public.rent_payments
    SET status = 'paid', paid_at = (declared_at + interval '5 days')
    WHERE contract_id = v_contract_id
      AND status = 'declared'
      AND receiver_type = 'owner'          -- included satırları otomatik onaylanmaz
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

  -- Generate rows from start up to and including the CURRENT month (not future)
  v_current_date := (date_trunc('month', v_start_date) + (v_due_day - 1) * interval '1 day')::date;
  v_end_date     := (date_trunc('month', now()) + (v_due_day - 1) * interval '1 day')::date;

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

    -- B+C. Masraf kalemleri
    IF jsonb_array_length(v_expenses_cfg) > 0 THEN
      FOR v_expense IN SELECT jsonb_array_elements(v_expenses_cfg)
      LOOP
        v_exp_name     := v_expense->>'name';
        v_exp_amount   := COALESCE((v_expense->>'amount')::numeric, 0);
        v_exp_receiver := v_expense->>'receiver';

        IF v_exp_name IS NULL THEN
          CONTINUE;
        END IF;

        -- B. receiver = 'owner': Kiracı → ev sahibine öder (mevcut davranış)
        IF v_exp_receiver = 'owner' THEN
          INSERT INTO public.rent_payments
            (property_id, contract_id, tenant_id, amount, currency, due_date, status, title, receiver_type)
          VALUES
            (p_property_id, v_contract_id, v_tenant_id, v_exp_amount, v_currency, v_current_date, 'pending', v_exp_name, 'owner')
          ON CONFLICT (contract_id, due_date, title)
          DO UPDATE SET
            amount    = CASE
                          WHEN rent_payments.invoice_url IS NOT NULL THEN rent_payments.amount
                          WHEN rent_payments.amount > 0              THEN rent_payments.amount
                          ELSE EXCLUDED.amount
                        END,
            currency  = CASE
                          WHEN rent_payments.invoice_url IS NOT NULL THEN rent_payments.currency
                          WHEN rent_payments.amount > 0              THEN rent_payments.currency
                          ELSE EXCLUDED.currency
                        END,
            tenant_id = COALESCE(EXCLUDED.tenant_id, rent_payments.tenant_id)
          WHERE rent_payments.status = 'pending';

        -- C. receiver = 'included': Ev sahibi kendi öder, kira içinde gizli
        ELSIF v_exp_receiver = 'included' THEN
          INSERT INTO public.rent_payments
            (property_id, contract_id, tenant_id, amount, currency, due_date, status, title, receiver_type)
          VALUES
            (p_property_id, v_contract_id, v_tenant_id,
             0,              -- Tutar girilmedi; ev sahibi daha sonra girer
             v_currency, v_current_date, 'pending', v_exp_name, 'included')
          ON CONFLICT (contract_id, due_date, title)
          DO UPDATE SET
            tenant_id = COALESCE(EXCLUDED.tenant_id, rent_payments.tenant_id)
          WHERE rent_payments.status = 'pending'
            AND rent_payments.amount = 0;
        END IF;

      END LOOP;
    END IF;

    v_current_date := (date_trunc('month', v_current_date + interval '1.5 month') + (v_due_day - 1) * interval '1 day')::date;
  END LOOP;
END;
$$;

-- 2. Ensure updated_at exists on invitations and RLS UPDATE policy
ALTER TABLE public.invitations ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT now();

DROP POLICY IF EXISTS "Users can update invitations" ON public.invitations;
CREATE POLICY "Users can update invitations" ON public.invitations
FOR UPDATE TO authenticated
USING (
    inviter_id = auth.uid() 
    OR public.is_agency_of_property(property_id, auth.uid())
    OR EXISTS (
        SELECT 1 FROM public.properties p 
        WHERE p.id = invitations.property_id AND p.agency_id = auth.uid()
    )
);

-- 3. RPC: Offline Landlord Confirmation by Agency
CREATE OR REPLACE FUNCTION public.confirm_landlord_offline(
    p_property_id UUID,
    p_token TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Verify caller is the agency of the property
    IF NOT EXISTS (
        SELECT 1 FROM public.properties
        WHERE id = p_property_id AND agency_id = auth.uid()
    ) THEN
        RETURN jsonb_build_object('success', false, 'message', 'Yetkisiz erişim: Bu mülkün acentesi değilsiniz.');
    END IF;

    -- Update invitations for this property and landlord
    IF p_token IS NOT NULL AND p_token <> '' THEN
        UPDATE public.invitations
        SET status = 'accepted'
        WHERE token = p_token AND property_id = p_property_id;
    ELSE
        UPDATE public.invitations
        SET status = 'accepted'
        WHERE property_id = p_property_id AND target_role = 'landlord' AND status = 'pending';
    END IF;

    -- Log activity
    INSERT INTO public.activity_logs (property_id, user_id, type, metadata)
    VALUES (p_property_id, auth.uid(), 'landlord_confirmed_offline', jsonb_build_object('confirmed_by', auth.uid(), 'token', p_token));

    RETURN jsonb_build_object('success', true);
END;
$$;

-- 4. RPC: Offline Contract & Tenant Activation by Agency
CREATE OR REPLACE FUNCTION public.activate_contract_offline(
    p_contract_id UUID,
    p_property_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Verify caller is agency or landlord of property
    IF NOT EXISTS (
        SELECT 1 FROM public.properties
        WHERE id = p_property_id AND (agency_id = auth.uid() OR landlord_id = auth.uid())
    ) THEN
        RETURN jsonb_build_object('success', false, 'message', 'Yetkisiz erişim: Bu mülkün yöneticisi değilsiniz.');
    END IF;

    -- Update contract to active
    UPDATE public.contracts
    SET status = 'active', updated_at = now()
    WHERE id = p_contract_id AND property_id = p_property_id;

    -- Generate payment schedule immediately
    PERFORM public.generate_missing_rent_payments(p_property_id);

    -- Log activity
    INSERT INTO public.activity_logs (property_id, user_id, type, metadata)
    VALUES (p_property_id, auth.uid(), 'contract_activated_offline', jsonb_build_object('contract_id', p_contract_id, 'activated_by', auth.uid()));

    RETURN jsonb_build_object('success', true);
END;
$$;

GRANT EXECUTE ON FUNCTION public.confirm_landlord_offline(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.activate_contract_offline(UUID, UUID) TO authenticated;
