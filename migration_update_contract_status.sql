-- Add 'expired' to contract_status enum
-- Since Postgres doesn't allow adding values to enums inside a transaction (usually), 
-- we run this as a standalone statement.
ALTER TYPE contract_status ADD VALUE IF NOT EXISTS 'expired';
