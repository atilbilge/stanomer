-- migration_bilateral_negotiation.sql
-- Enables both Landlords and Tenants to propose, accept, and decline contract changes.

-- 1. Update propose_contract_changes to allow both participants
CREATE OR REPLACE FUNCTION public.propose_contract_changes(
  p_contract_id UUID,
  p_changes JSONB
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_current_status TEXT;
  v_landlord_id UUID;
  v_tenant_id UUID;
BEGIN
  SELECT status::text, landlord_id, tenant_id
  INTO v_current_status, v_landlord_id, v_tenant_id
  FROM contracts
  WHERE id = p_contract_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Contract not found';
  END IF;

  -- Security check: Only participants can propose changes
  IF auth.uid() NOT IN (v_landlord_id, v_tenant_id) THEN
    RAISE EXCEPTION 'Unauthorized: Only landlord or tenant can propose terms/counter-offers';
  END IF;

  -- Logic depends on who is proposing and what is the current state
  IF auth.uid() = v_landlord_id AND (v_current_status = 'negotiating' OR v_current_status = 'pending') THEN
    -- LANDLORD updating initial draft/invite
    UPDATE contracts
    SET
      monthly_rent     = COALESCE((p_changes->>'monthly_rent')::NUMERIC, monthly_rent),
      currency         = COALESCE(p_changes->>'currency', currency),
      deposit_amount   = COALESCE((p_changes->>'deposit_amount')::NUMERIC, deposit_amount),
      deposit_currency = COALESCE(p_changes->>'deposit_currency', p_changes->>'currency', deposit_currency),
      due_day          = COALESCE((p_changes->>'due_day')::INTEGER, due_day),
      start_date       = COALESCE((p_changes->>'start_date')::TIMESTAMPTZ, start_date),
      end_date         = COALESCE((p_changes->>'end_date')::TIMESTAMPTZ, end_date),
      expenses_config  = COALESCE(p_changes->'expenses_config', expenses_config),
      tenant_feedback  = NULL,
      proposed_changes = NULL,
      proposed_by      = NULL,
      status           = 'pending'::public.contract_status,
      updated_at       = now()
    WHERE id = p_contract_id;
  ELSE
    -- ANY PARTY proposing a revision to be accepted by the other
    UPDATE contracts
    SET
      proposed_changes = p_changes,
      proposed_by      = auth.uid(),
      status           = 'revision_requested'::public.contract_status,
      updated_at       = now()
    WHERE id = p_contract_id;
  END IF;
END;
$$;

-- 2. Update decline_proposed_changes to allow the non-proposing party to decline
CREATE OR REPLACE FUNCTION public.decline_proposed_changes(
  p_contract_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_landlord_id UUID;
  v_tenant_id UUID;
  v_proposed_by UUID;
  v_current_status TEXT;
  v_has_active_invite BOOLEAN;
BEGIN
  SELECT landlord_id, tenant_id, proposed_by, status::text
  INTO v_landlord_id, v_tenant_id, v_proposed_by, v_current_status
  FROM contracts
  WHERE id = p_contract_id AND status IN ('revision_requested', 'negotiating', 'termination_requested');

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Contract not found or not in a negotiable state';
  END IF;

  -- Security: Anyone who is a participant can decline/cancel
  IF auth.uid() NOT IN (v_landlord_id, v_tenant_id) THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  -- Determine the fallback status
  -- Logic: If it has a tenant_id, it means the tenant has already joined, so return to 'active'.
  -- If it was a termination request, it must go back to 'active'.
  -- If no tenant_id, it's still in the invitation/draft phase, so return to 'pending'.
  UPDATE contracts
  SET
    proposed_changes = NULL,
    proposed_by      = NULL,
    tenant_feedback  = NULL,
    status           = CASE 
                        WHEN v_current_status = 'termination_requested' THEN 'active'::public.contract_status
                        WHEN v_tenant_id IS NOT NULL THEN 'active'::public.contract_status
                        ELSE 'pending'::public.contract_status
                      END,
    updated_at       = now()
  WHERE id = p_contract_id;
END;
$$;

-- 3. Ensure accept_proposed_changes handles the bilateral logic correctly
CREATE OR REPLACE FUNCTION public.accept_proposed_changes(
  p_contract_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_landlord_id UUID;
  v_tenant_id UUID;
  v_proposed_by UUID;
  v_changes JSONB;
  v_current_end_date TIMESTAMPTZ;
  v_prev_status TEXT;
BEGIN
  -- We assume if status was revision_requested, and it wasn't active, it should go back to its transition state
  SELECT landlord_id, tenant_id, proposed_by, proposed_changes, end_date, status::text
  INTO v_landlord_id, v_tenant_id, v_proposed_by, v_changes, v_current_end_date, v_prev_status
  FROM contracts
  WHERE id = p_contract_id AND status IN ('revision_requested', 'termination_requested');

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Contract not found or not in a pending state';
  END IF;

  IF auth.uid() NOT IN (v_landlord_id, v_tenant_id) THEN
    RAISE EXCEPTION 'Only participants can accept proposed changes';
  END IF;

  IF auth.uid() = v_proposed_by THEN
    RAISE EXCEPTION 'You cannot accept your own proposed changes';
  END IF;

  IF v_changes IS NULL THEN
    RAISE EXCEPTION 'No proposed changes found';
  END IF;

  -- Handle Termination Proposal
  IF v_changes ? 'is_termination' AND (v_changes->>'is_termination')::boolean = true THEN
    UPDATE contracts
    SET
      end_date = (v_changes->>'new_end_date')::timestamptz,
      status = 'active',
      termination_approved = true,
      proposed_changes = NULL,
      proposed_by = NULL,
      updated_at = now()
    WHERE id = p_contract_id;
  ELSE
    -- Handle standard Revision Proposal
    UPDATE contracts
    SET
      monthly_rent      = COALESCE((v_changes->>'monthly_rent')::numeric,         monthly_rent),
      deposit_amount    = COALESCE((v_changes->>'deposit_amount')::numeric,       deposit_amount),
      due_day           = COALESCE((v_changes->>'due_day')::integer,              due_day),
      currency          = COALESCE(v_changes->>'currency',                         currency),
      start_date        = COALESCE((v_changes->>'start_date')::timestamptz,       start_date),
      end_date          = COALESCE((v_changes->>'end_date')::timestamptz,         end_date),
      tax_type          = COALESCE((v_changes->>'tax_type')::public.tax_type,     tax_type),
      expenses_config   = COALESCE(v_changes->'expenses_config',                  expenses_config),
      proposed_changes  = NULL,
      proposed_by       = NULL,
      -- If tenant has already joined, it stays active, else stays pending
      status            = CASE 
                            WHEN v_tenant_id IS NOT NULL THEN 'active'::public.contract_status
                            ELSE 'pending'::public.contract_status
                          END,
      updated_at        = now()
    WHERE id = p_contract_id;
  END IF;
END;
$$;
