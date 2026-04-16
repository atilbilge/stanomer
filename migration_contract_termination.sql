-- 1. Add new enum values to contract_status
ALTER TYPE public.contract_status ADD VALUE IF NOT EXISTS 'termination_requested';
ALTER TYPE public.contract_status ADD VALUE IF NOT EXISTS 'inactive';

-- 2. Add termination_approved column to contracts
ALTER TABLE public.contracts ADD COLUMN IF NOT EXISTS termination_approved BOOLEAN DEFAULT FALSE;

-- 3. Update accept_proposed_changes to handle termination logic
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
BEGIN
  SELECT landlord_id, tenant_id, proposed_by, proposed_changes, end_date
  INTO v_landlord_id, v_tenant_id, v_proposed_by, v_changes, v_current_end_date
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
      status            = 'active',
      termination_approved = CASE 
        WHEN (v_changes->>'end_date') IS NOT NULL 
        THEN ((v_changes->>'end_date')::timestamptz < v_current_end_date)
        ELSE termination_approved 
      END,
      updated_at        = now()
    WHERE id = p_contract_id;
  END IF;
END;
$$;

-- 2. Create RPC for requesting termination specifically
CREATE OR REPLACE FUNCTION public.propose_contract_termination(
  p_contract_id UUID,
  p_termination_date TIMESTAMPTZ
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_landlord_id UUID;
  v_tenant_id UUID;
  v_status TEXT;
BEGIN
  SELECT landlord_id, tenant_id, status::text
  INTO v_landlord_id, v_tenant_id, v_status
  FROM contracts
  WHERE id = p_contract_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Contract not found';
  END IF;

  IF auth.uid() NOT IN (v_landlord_id, v_tenant_id) THEN
    RAISE EXCEPTION 'Only the landlord or tenant can propose termination';
  END IF;

  IF v_status != 'active' THEN
    RAISE EXCEPTION 'Cannot propose termination on a contract with status: %', v_status;
  END IF;

  UPDATE contracts
  SET
    proposed_changes = jsonb_build_object(
      'is_termination', true,
      'new_end_date', p_termination_date
    ),
    proposed_by = auth.uid(),
    status = 'termination_requested',
    updated_at = now()
  WHERE id = p_contract_id;
END;
$$;
