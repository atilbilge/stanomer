-- 2026-08-05: Update contract proposal functions (propose_contract_changes, accept_proposed_changes, decline_proposed_changes)
-- Allow Landlords, Tenants AND Agency Managers to propose and manage contract changes with 2-party mutual approval.

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
  v_agency_id UUID;
BEGIN
  SELECT c.status::text, c.landlord_id, c.tenant_id, COALESCE(c.agency_id, p.agency_id)
  INTO v_current_status, v_landlord_id, v_tenant_id, v_agency_id
  FROM contracts c
  LEFT JOIN properties p ON p.id = c.property_id
  WHERE c.id = p_contract_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Contract not found';
  END IF;

  -- Security check: Landlord, Tenant, or Agency can propose changes
  IF auth.uid() NOT IN (v_landlord_id, v_tenant_id, v_agency_id) AND (v_agency_id IS NULL OR auth.uid() <> v_agency_id) THEN
    RAISE EXCEPTION 'Unauthorized: Only landlord, tenant, or managing agency can propose terms/counter-offers';
  END IF;

  -- If contract is in initial draft/invitation phase, direct update by landlord/agency
  IF (auth.uid() = v_landlord_id OR auth.uid() = v_agency_id) AND (v_current_status = 'negotiating' OR v_current_status = 'pending') THEN
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
    -- Revisions on active/joined contracts require 2-party proposal and acceptance
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
  v_agency_id UUID;
  v_proposed_by UUID;
  v_changes JSONB;
  v_current_end_date TIMESTAMPTZ;
  v_prev_status TEXT;
BEGIN
  SELECT c.landlord_id, c.tenant_id, COALESCE(c.agency_id, p.agency_id), c.proposed_by, c.proposed_changes, c.end_date, c.status::text
  INTO v_landlord_id, v_tenant_id, v_agency_id, v_proposed_by, v_changes, v_current_end_date, v_prev_status
  FROM contracts c
  LEFT JOIN properties p ON p.id = c.property_id
  WHERE c.id = p_contract_id AND c.status IN ('revision_requested', 'termination_requested');

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Contract not found or not in a pending state';
  END IF;

  IF auth.uid() NOT IN (v_landlord_id, v_tenant_id, v_agency_id) AND (v_agency_id IS NULL OR auth.uid() <> v_agency_id) THEN
    RAISE EXCEPTION 'Only participants can accept proposed changes';
  END IF;

  IF auth.uid() = v_proposed_by THEN
    RAISE EXCEPTION 'You cannot accept your own proposed changes';
  END IF;

  IF v_changes IS NULL THEN
    RAISE EXCEPTION 'No proposed changes found';
  END IF;

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
      status            = CASE 
                            WHEN v_tenant_id IS NOT NULL THEN 'active'::public.contract_status
                            ELSE 'pending'::public.contract_status
                          END,
      updated_at        = now()
    WHERE id = p_contract_id;
  END IF;
END;
$$;

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
  v_agency_id UUID;
  v_proposed_by UUID;
  v_current_status TEXT;
BEGIN
  SELECT c.landlord_id, c.tenant_id, COALESCE(c.agency_id, p.agency_id), c.proposed_by, c.status::text
  INTO v_landlord_id, v_tenant_id, v_agency_id, v_proposed_by, v_current_status
  FROM contracts c
  LEFT JOIN properties p ON p.id = c.property_id
  WHERE c.id = p_contract_id AND c.status IN ('revision_requested', 'negotiating', 'termination_requested');

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Contract not found or not in a negotiable state';
  END IF;

  IF auth.uid() NOT IN (v_landlord_id, v_tenant_id, v_agency_id) AND (v_agency_id IS NULL OR auth.uid() <> v_agency_id) THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

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
