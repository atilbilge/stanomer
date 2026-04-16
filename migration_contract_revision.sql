-- migration_contract_revision.sql
-- Comprehensive Fix for Initial Stage Negotiation & Counter-offers

-- 1. Ensure 'negotiating' status exists
ALTER TYPE public.contract_status ADD VALUE IF NOT EXISTS 'negotiating';

-- 2. CREATE or REPLACE the robust decline function
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
  v_current_status TEXT;
BEGIN
  SELECT landlord_id, status::text
  INTO v_landlord_id, v_current_status
  FROM contracts
  WHERE id = p_contract_id AND status IN ('revision_requested', 'negotiating');

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Contract not found or not in a negotiable state';
  END IF;

  -- Security: Only landlord can decline a tenant's request
  IF auth.uid() != v_landlord_id THEN
    RAISE EXCEPTION 'Unauthorized: Only landlord can decline revision requests';
  END IF;

  UPDATE contracts
  SET
    proposed_changes = NULL,
    proposed_by      = NULL,
    tenant_feedback  = NULL,
    status           = CASE 
                        WHEN v_current_status = 'negotiating' THEN 'pending'::public.contract_status
                        ELSE 'active'::public.contract_status
                      END,
    updated_at       = now()
  WHERE id = p_contract_id;
END;
$$;

-- 3. CREATE or REPLACE the robust propose function
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
BEGIN
  SELECT status::text, landlord_id
  INTO v_current_status, v_landlord_id
  FROM contracts
  WHERE id = p_contract_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Contract not found';
  END IF;

  -- Security check
  IF auth.uid() != v_landlord_id THEN
    RAISE EXCEPTION 'Unauthorized: Only landlord can propose terms/counter-offers';
  END IF;

  IF v_current_status = 'negotiating' OR v_current_status = 'pending' THEN
    -- COUNTER-OFFER or INITIAL PROPOSAL
    -- Update columns directly and set/keep status as 'pending'
    UPDATE contracts
    SET
      monthly_rent     = (p_changes->>'monthly_rent')::NUMERIC,
      currency         = COALESCE(p_changes->>'currency', currency),
      deposit_amount   = (p_changes->>'deposit_amount')::NUMERIC,
      deposit_currency = COALESCE(p_changes->>'deposit_currency', p_changes->>'currency', deposit_currency),
      due_day          = (p_changes->>'due_day')::INTEGER,
      start_date       = (p_changes->>'start_date')::TIMESTAMPTZ,
      end_date         = (p_changes->>'end_date')::TIMESTAMPTZ,
      expenses_config  = COALESCE(p_changes->'expenses_config', expenses_config),
      tenant_feedback  = NULL, -- Clear tenant's feedback as it's been addressed
      proposed_changes = NULL, -- Not using proposal JSON for pending/negotiating
      proposed_by      = NULL,
      status           = 'pending'::public.contract_status,
      updated_at       = now()
    WHERE id = p_contract_id;

  ELSIF v_current_status = 'active' OR v_current_status = 'revision_requested' THEN
    -- REVISION of ACTIVE CONTRACT
    -- Store in JSON proposal and set status to 'revision_requested'
    UPDATE contracts
    SET
      proposed_changes = p_changes,
      proposed_by      = auth.uid(),
      status           = 'revision_requested'::public.contract_status,
      updated_at       = now()
    WHERE id = p_contract_id;
  
  ELSE
    RAISE EXCEPTION 'Contract is in a state (%) that does not allow proposals', v_current_status;
  END IF;
END;
$$;
