import re

with open('migration_contract_revision.sql', 'r') as f:
    content = f.read()

# 1. Add proposed_by to contracts table migration
add_col_regex = r"""-- 1. Add proposed_changes column to contracts
ALTER TABLE public.contracts
ADD COLUMN IF NOT EXISTS proposed_changes JSONB;"""
add_col_replace = """-- 1. Add proposed_changes and proposed_by columns to contracts
ALTER TABLE public.contracts
ADD COLUMN IF NOT EXISTS proposed_changes JSONB,
ADD COLUMN IF NOT EXISTS proposed_by UUID REFERENCES auth.users(id);"""

content = content.replace(add_col_regex, add_col_replace)

# 2. Update propose_contract_changes
propose_regex = r"""DECLARE
  v_landlord_id UUID;
  v_status TEXT;
BEGIN
  SELECT landlord_id, status::text
  INTO v_landlord_id, v_status
  FROM contracts
  WHERE id = p_contract_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Contract not found';
  END IF;

  IF v_landlord_id != auth.uid\(\) THEN
    RAISE EXCEPTION 'Only the landlord can propose changes';
  END IF;

  IF v_status NOT IN \('active', 'revision_requested'\) THEN
    RAISE EXCEPTION 'Cannot propose changes on a contract with status: %', v_status;
  END IF;

  UPDATE contracts
  SET
    proposed_changes = p_changes,
    status = 'revision_requested',
    updated_at = now\(\)
  WHERE id = p_contract_id;
END;"""
propose_replace = """DECLARE
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
    RAISE EXCEPTION 'Only the landlord or tenant can propose changes';
  END IF;

  IF v_status NOT IN ('active', 'revision_requested') THEN
    RAISE EXCEPTION 'Cannot propose changes on a contract with status: %', v_status;
  END IF;

  UPDATE contracts
  SET
    proposed_changes = p_changes,
    proposed_by = auth.uid(),
    status = 'revision_requested',
    updated_at = now()
  WHERE id = p_contract_id;
END;"""
content = re.sub(propose_regex, propose_replace, content)

# 3. Update accept_proposed_changes
accept_regex = r"""DECLARE
  v_tenant_id UUID;
  v_changes JSONB;
BEGIN
  SELECT tenant_id, proposed_changes
  INTO v_tenant_id, v_changes
  FROM contracts
  WHERE id = p_contract_id AND status = 'revision_requested';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Contract not found or not in revision_requested state';
  END IF;

  IF v_tenant_id != auth.uid\(\) THEN
    RAISE EXCEPTION 'Only the tenant can accept proposed changes';
  END IF;

  IF v_changes IS NULL THEN
    RAISE EXCEPTION 'No proposed changes found';
  END IF;

  UPDATE contracts
  SET
    monthly_rent      = COALESCE\(\(v_changes->>'monthly_rent'\)::numeric,         monthly_rent\),
    deposit_amount    = COALESCE\(\(v_changes->>'deposit_amount'\)::numeric,       deposit_amount\),
    due_day           = COALESCE\(\(v_changes->>'due_day'\)::integer,              due_day\),
    currency          = COALESCE\(v_changes->>'currency',                         currency\),
    start_date        = COALESCE\(\(v_changes->>'start_date'\)::timestamptz,       start_date\),
    end_date          = COALESCE\(\(v_changes->>'end_date'\)::timestamptz,         end_date\),
    tax_type          = COALESCE\(\(v_changes->>'tax_type'\)::public.tax_type,     tax_type\),
    expenses_config   = COALESCE\(v_changes->'expenses_config',                  expenses_config\),
    proposed_changes  = NULL,
    status            = 'active',
    updated_at        = now\(\)
  WHERE id = p_contract_id;
END;"""
accept_replace = """DECLARE
  v_landlord_id UUID;
  v_tenant_id UUID;
  v_proposed_by UUID;
  v_changes JSONB;
BEGIN
  SELECT landlord_id, tenant_id, proposed_by, proposed_changes
  INTO v_landlord_id, v_tenant_id, v_proposed_by, v_changes
  FROM contracts
  WHERE id = p_contract_id AND status = 'revision_requested';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Contract not found or not in revision_requested state';
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
    updated_at        = now()
  WHERE id = p_contract_id;
END;"""
content = re.sub(accept_regex, accept_replace, content)

# 4. Update decline_proposed_changes
decline_regex = r"""DECLARE
  v_tenant_id UUID;
BEGIN
  SELECT tenant_id
  INTO v_tenant_id
  FROM contracts
  WHERE id = p_contract_id AND status = 'revision_requested';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Contract not found or not in revision_requested state';
  END IF;

  IF v_tenant_id != auth.uid\(\) THEN
    RAISE EXCEPTION 'Only the tenant can decline proposed changes';
  END IF;

  UPDATE contracts
  SET
    proposed_changes = NULL,
    status           = 'active',
    updated_at       = now\(\)
  WHERE id = p_contract_id;
END;"""
decline_replace = """DECLARE
  v_landlord_id UUID;
  v_tenant_id UUID;
  v_proposed_by UUID;
BEGIN
  SELECT landlord_id, tenant_id, proposed_by
  INTO v_landlord_id, v_tenant_id, v_proposed_by
  FROM contracts
  WHERE id = p_contract_id AND status = 'revision_requested';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Contract not found or not in revision_requested state';
  END IF;

  IF auth.uid() NOT IN (v_landlord_id, v_tenant_id) THEN
    RAISE EXCEPTION 'Only participants can decline proposed changes';
  END IF;

  IF auth.uid() = v_proposed_by THEN
    -- If the proposer declines, it effectively cancels their own proposal
    -- But usually it's the other party. We'll allow either party to cancel/decline.
    NULL;
  END IF;

  UPDATE contracts
  SET
    proposed_changes = NULL,
    proposed_by      = NULL,
    status           = 'active',
    updated_at       = now()
  WHERE id = p_contract_id;
END;"""
content = re.sub(decline_regex, decline_replace, content)

with open('migration_contract_revision.sql', 'w') as f:
    f.write(content)

