DROP VIEW IF EXISTS public.view_agency_financial_ledger;
CREATE OR REPLACE VIEW public.view_agency_financial_ledger WITH (security_invoker = true) AS
WITH deduplicated_rent_payments AS (
  SELECT DISTINCT ON (
    rp.property_id,
    EXTRACT(YEAR FROM rp.due_date),
    EXTRACT(MONTH FROM rp.due_date),
    LOWER(TRIM(rp.title))
  )
    rp.id AS id,
    p.agency_id,
    rp.property_id,
    rp.contract_id,
    rp.tenant_id,
    p.landlord_id,
    'rent_payment'::TEXT AS source_table,
    rp.title::TEXT AS title,
    rp.title::TEXT AS raw_title,
    (CASE 
      WHEN LOWER(TRIM(rp.title)) = 'kira' 
        OR LOWER(TRIM(rp.title)) LIKE '%rent%' 
        OR LOWER(TRIM(rp.title)) LIKE '%kira%' 
        OR LOWER(TRIM(rp.title)) LIKE '%zakupnina%' 
        OR LOWER(TRIM(rp.title)) LIKE '%kirija%' 
      THEN 'rent'
      WHEN LOWER(TRIM(rp.title)) LIKE '%bakım%' 
        OR LOWER(TRIM(rp.title)) LIKE '%maintenance%' 
      THEN 'maintenance'
      ELSE 'bill'
    END)::TEXT AS category,
    COALESCE(rp.amount, 0)::NUMERIC AS amount,
    COALESCE(rp.currency, p.currency, 'EUR')::TEXT AS currency,
    rp.due_date::DATE AS due_date,
    rp.declared_at,
    rp.paid_at,
    rp.status::TEXT AS status,
    NULL::TEXT AS payment_status,
    COALESCE(rp.receiver_type, 'owner')::TEXT AS receiver_type,
    'bank_transfer'::TEXT AS payment_method,
    NULL::TEXT AS paid_by,
    rp.receipt_url,
    rp.invoice_url,
    rp.owner_note,
    rp.dispute_reason,
    rp.disputed_at,
    FALSE AS is_maintenance,
    NULL::NUMERIC AS cost_amount,
    NULL::NUMERIC AS remaining_amount,
    NULL::NUMERIC AS settled_amount,
    NULL::UUID AS debtor_id,
    FALSE AS is_tenant_debtor,
    FALSE AS is_landlord_debtor,
    COALESCE(p.name, p.address, 'Mülk')::TEXT AS property_title,
    COALESCE(p.address, '')::TEXT AS property_address,
    COALESCE(p.city, '')::TEXT AS property_city,
    COALESCE(p.landlord_name, lp.full_name, p.landlord_email, lp.email, '')::TEXT AS landlord_name,
    COALESCE(p.landlord_email, lp.email, '')::TEXT AS landlord_email,
    COALESCE(tp.full_name, tp.email, '')::TEXT AS tenant_name,
    rp.created_at,
    rp.created_at AS updated_at
  FROM public.rent_payments rp
  JOIN public.properties p ON p.id = rp.property_id
  LEFT JOIN public.profiles lp ON lp.id = p.landlord_id
  LEFT JOIN public.profiles tp ON tp.id = rp.tenant_id
  WHERE p.agency_id IS NOT NULL
  ORDER BY
    rp.property_id,
    EXTRACT(YEAR FROM rp.due_date),
    EXTRACT(MONTH FROM rp.due_date),
    LOWER(TRIM(rp.title)),
    (CASE WHEN rp.amount > 0 THEN 1 ELSE 0 END) DESC,
    (CASE WHEN rp.status = 'paid' THEN 3 WHEN rp.status IN ('declared', 'disputed') THEN 2 ELSE 1 END) DESC,
    (CASE WHEN rp.receipt_url IS NOT NULL THEN 1 ELSE 0 END) DESC,
    rp.due_date DESC,
    rp.created_at ASC,
    rp.id ASC
),
synthetic_maintenance_payments AS (
  SELECT
    m.id AS id,
    p.agency_id,
    m.property_id,
    m.contract_id,
    p.tenant_id,
    p.landlord_id,
    'maintenance_request'::TEXT AS source_table,
    ('🛠️ ' || m.title)::TEXT AS title,
    m.title::TEXT AS raw_title,
    'maintenance'::TEXT AS category,
    (CASE 
      WHEN (COALESCE(m.cost_amount, 0) - COALESCE(m.settled_amount, 0)) > 0 
      THEN (COALESCE(m.cost_amount, 0) - COALESCE(m.settled_amount, 0)) 
      ELSE m.cost_amount 
    END)::NUMERIC AS amount,
    COALESCE(m.currency, p.currency, 'EUR')::TEXT AS currency,
    COALESCE(m.payment_date, m.updated_at, m.created_at)::DATE AS due_date,
    (CASE WHEN m.payment_status IN ('pending_agency_approval', 'pending_review', 'pending_opposite_approval') THEN m.created_at ELSE NULL END) AS declared_at,
    (CASE WHEN m.payment_status = 'paid' THEN COALESCE(m.payment_date, m.updated_at, m.created_at) ELSE NULL END) AS paid_at,
    (CASE 
      WHEN m.payment_status IN ('pending_agency_approval', 'pending_review', 'pending_opposite_approval') THEN 'declared'
      WHEN m.payment_status = 'pending_payment' THEN 'pending_payment'
      ELSE 'paid'
    END)::TEXT AS status,
    m.payment_status::TEXT AS payment_status,
    (CASE 
      WHEN m.paid_by = 'agency' AND mc.debtor_id IS NOT NULL AND mc.debtor_id != p.landlord_id THEN 'tenant'
      ELSE 'landlord'
    END)::TEXT AS receiver_type,
    'bank_transfer'::TEXT AS payment_method,
    m.paid_by::TEXT AS paid_by,
    m.invoice_pdf_url AS receipt_url,
    m.invoice_pdf_url AS invoice_url,
    m.description AS owner_note,
    m.rejection_reason AS dispute_reason,
    NULL::TIMESTAMPTZ AS disputed_at,
    TRUE AS is_maintenance,
    m.cost_amount,
    GREATEST(0, (COALESCE(m.cost_amount, 0) - COALESCE(m.settled_amount, 0)))::NUMERIC AS remaining_amount,
    COALESCE(m.settled_amount, 0)::NUMERIC AS settled_amount,
    mc.debtor_id,
    (m.paid_by = 'agency' AND mc.debtor_id IS NOT NULL AND mc.debtor_id != p.landlord_id) AS is_tenant_debtor,
    ((m.paid_by = 'agency' AND NOT (mc.debtor_id IS NOT NULL AND mc.debtor_id != p.landlord_id)) OR (m.paid_by = 'tenant')) AS is_landlord_debtor,
    COALESCE(p.name, p.address, 'Mülk')::TEXT AS property_title,
    COALESCE(p.address, '')::TEXT AS property_address,
    COALESCE(p.city, '')::TEXT AS property_city,
    COALESCE(p.landlord_name, lp.full_name, p.landlord_email, lp.email, '')::TEXT AS landlord_name,
    COALESCE(p.landlord_email, lp.email, '')::TEXT AS landlord_email,
    COALESCE(tp.full_name, tp.email, '')::TEXT AS tenant_name,
    m.created_at,
    m.updated_at
  FROM public.maintenance_requests m
  JOIN public.properties p ON p.id = m.property_id
  LEFT JOIN public.profiles lp ON lp.id = p.landlord_id
  LEFT JOIN public.profiles tp ON tp.id = p.tenant_id
  LEFT JOIN LATERAL (
    SELECT debtor_id FROM public.maintenance_charges c 
    WHERE c.maintenance_request_id = m.id 
    ORDER BY c.created_at DESC 
    LIMIT 1
  ) mc ON TRUE
  WHERE p.agency_id IS NOT NULL
    AND COALESCE(m.cost_amount, 0) > 0
    AND m.payment_status IN ('pending_agency_approval', 'pending_review', 'pending_opposite_approval', 'paid', 'pending_payment')
),
raw_combined AS (
  SELECT * FROM deduplicated_rent_payments
  UNION ALL
  SELECT * FROM synthetic_maintenance_payments
)
SELECT
  r.id,
  r.agency_id,
  r.property_id,
  r.contract_id,
  r.tenant_id,
  r.landlord_id,
  r.source_table,
  r.title,
  r.raw_title,
  r.category,
  r.amount,
  r.currency,
  r.due_date,
  r.declared_at,
  r.paid_at,
  r.status,
  r.payment_status,
  r.receiver_type,
  r.payment_method,
  r.paid_by,
  r.receipt_url,
  r.invoice_url,
  r.owner_note,
  r.dispute_reason,
  r.disputed_at,
  r.is_maintenance,
  r.cost_amount,
  r.remaining_amount,
  r.settled_amount,
  r.debtor_id,
  r.is_tenant_debtor,
  r.is_landlord_debtor,
  r.property_title,
  r.property_address,
  r.property_city,
  r.landlord_name,
  r.landlord_email,
  r.tenant_name,
  r.created_at,
  r.updated_at,
  (r.status IN ('declared', 'disputed')) AS is_pending_approval,
  (
    r.status NOT IN ('paid', 'declared', 'disputed') 
    AND (r.receiver_type IN ('owner', 'included') OR r.receiver_type IS NULL) 
    AND r.category != 'rent' 
    AND r.amount = 0
  ) AS is_unentered_bill,
  (
    r.status NOT IN ('declared', 'disputed', 'paid') 
    AND r.amount > 0 
    AND (r.status = 'overdue' OR (r.status = 'pending' AND r.due_date < CURRENT_DATE))
  ) AS is_overdue,
  (
    r.status = 'paid' 
    AND r.category = 'rent'
  ) AS is_rent_collected,
  (
    r.status = 'paid' 
    AND r.category != 'rent' 
    AND r.is_maintenance = FALSE 
    AND r.receiver_type = 'owner'
  ) AS is_bills_collected,
  (
    r.status = 'paid' 
    AND r.category != 'rent' 
    AND r.is_maintenance = FALSE 
    AND r.receiver_type = 'included'
  ) AS is_bills_to_institutions,
  (
    r.is_maintenance = TRUE 
    AND (r.status = 'paid' OR r.payment_status = 'paid') 
    AND (r.paid_by = 'landlord' OR (r.paid_by = 'agency' AND r.is_tenant_debtor = FALSE))
  ) AS is_maintenance_paid,
  (
    r.is_maintenance = TRUE 
    AND r.paid_by = 'agency' 
    AND r.is_tenant_debtor = FALSE 
    AND r.status != 'paid' 
    AND r.payment_status NOT IN ('paid', 'rejected') 
    AND (COALESCE(r.remaining_amount, 0) > 0 OR r.amount > 0)
  ) AS is_maintenance_owed_to_agency,
  (
    r.is_maintenance = TRUE 
    AND r.status NOT IN ('paid', 'declared') 
    AND r.payment_status NOT IN ('pending_agency_approval', 'pending_review', 'pending_opposite_approval') 
    AND (COALESCE(r.cost_amount, 0) > 0 OR r.amount > 0)
  ) AS is_unpaid_maintenance,
  (
    r.category != 'rent' 
    AND r.is_maintenance = FALSE 
    AND r.status != 'paid' 
    AND r.receiver_type = 'included' 
    AND r.amount > 0
  ) AS is_unpaid_bills_to_institutions,
  (
    r.is_maintenance = TRUE 
    AND r.paid_by = 'tenant' 
    AND r.payment_status NOT IN ('paid', 'rejected') 
    AND (COALESCE(r.remaining_amount, 0) > 0 OR COALESCE(r.cost_amount, 0) > 0 OR r.amount > 0)
  ) AS is_tenant_offset
FROM raw_combined r;

GRANT SELECT ON public.view_agency_financial_ledger TO authenticated;
GRANT SELECT ON public.view_agency_financial_ledger TO anon;
GRANT SELECT ON public.view_agency_financial_ledger TO service_role;
