-- Add additional_documents column to contracts table
ALTER TABLE public.contracts 
ADD COLUMN IF NOT EXISTS additional_documents JSONB DEFAULT '[]'::jsonb;

-- Update RLS policies to ensure both parties can read documents (handled by table-level RLS usually, but for clarity)
-- The existing landlord_manage_contracts and tenant_view_update_contracts already cover this table.
