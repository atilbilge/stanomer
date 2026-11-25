-- Migration: Clean up accidental "(Kalan)" entries from expense templates and 0-amount placeholder rent_payments
-- Target: Dev Supabase (nbcbfmhztnnhfnapvaet)
-- Idempotent & data-safe: preserves all rent_payments with amount > 0, paid/declared/disputed status, or receipts.

BEGIN;

-- 1. Remove "(Kalan)" items from properties.expenses_template
UPDATE public.properties
SET expenses_template = COALESCE(
  (
    SELECT jsonb_agg(elem)
    FROM jsonb_array_elements(expenses_template) AS elem
    WHERE COALESCE(elem->>'name', '') NOT ILIKE '%(Kalan)%'
  ),
  '[]'::jsonb
)
WHERE expenses_template IS NOT NULL
  AND jsonb_typeof(expenses_template) = 'array'
  AND EXISTS (
    SELECT 1
    FROM jsonb_array_elements(expenses_template) AS elem
    WHERE COALESCE(elem->>'name', '') ILIKE '%(Kalan)%'
  );

-- 2. Remove "(Kalan)" items from contracts.expenses_config
UPDATE public.contracts
SET expenses_config = COALESCE(
  (
    SELECT jsonb_agg(elem)
    FROM jsonb_array_elements(expenses_config) AS elem
    WHERE COALESCE(elem->>'name', '') NOT ILIKE '%(Kalan)%'
  ),
  '[]'::jsonb
)
WHERE expenses_config IS NOT NULL
  AND jsonb_typeof(expenses_config) = 'array'
  AND EXISTS (
    SELECT 1
    FROM jsonb_array_elements(expenses_config) AS elem
    WHERE COALESCE(elem->>'name', '') ILIKE '%(Kalan)%'
  );

-- 3. Delete 0-amount uncollected "(Kalan)" placeholder rows from rent_payments
DELETE FROM public.rent_payments
WHERE title ILIKE '%(Kalan)%'
  AND COALESCE(amount, 0) = 0
  AND status IN ('pending', 'overdue')
  AND declared_at IS NULL
  AND receipt_url IS NULL;

COMMIT;

