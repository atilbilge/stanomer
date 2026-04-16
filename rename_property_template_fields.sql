-- SQL Migration: Property/Contract Separation
-- Rename fields in properties to clarify they are templates/defaults

ALTER TABLE properties RENAME COLUMN monthly_rent TO default_monthly_rent;
ALTER TABLE properties RENAME COLUMN deposit_amount TO default_deposit_amount;
ALTER TABLE properties RENAME COLUMN due_day TO default_due_day;

-- contract_start_date, contract_end_date, and contract_url are now strictly template fields
-- We'll rename them too for consistency if we want, but usually 'default' is enough for terms.
ALTER TABLE properties RENAME COLUMN contract_start_date TO default_start_date;
ALTER TABLE properties RENAME COLUMN contract_end_date TO default_end_date;
ALTER TABLE properties RENAME COLUMN contract_url TO default_contract_url;

-- Note: we keep tenant_id on properties as a cache for the current occupant.
