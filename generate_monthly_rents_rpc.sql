-- Updated generate_missing_rent_payments RPC
-- LEASE TERMS ARE NOW FETCHED FROM THE ACTIVE CONTRACT ONLY
CREATE OR REPLACE FUNCTION generate_missing_rent_payments(p_property_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_start_date date;
    v_end_date date;
    v_current_date date;
    v_monthly_rent numeric;
    v_currency text;
    v_tenant_id uuid;
    v_due_day integer;
    v_approved_row record;
BEGIN
    -- Get current lease terms from the ACTIVE contract only
    SELECT start_date, monthly_rent, currency, tenant_id, COALESCE(due_day, 1)
    INTO v_start_date, v_monthly_rent, v_currency, v_tenant_id, v_due_day
    FROM contracts
    WHERE property_id = p_property_id AND status = 'active'
    LIMIT 1;

    -- If no active contract exists, we stop here
    IF v_start_date IS NULL OR v_monthly_rent IS NULL OR v_tenant_id IS NULL THEN
        RETURN;
    END IF;

    -- AUTO-APPROVE: Mark 'declared' as 'paid' if it's been more than 5 days
    FOR v_approved_row IN 
        UPDATE rent_payments 
        SET status = 'paid', paid_at = (declared_at + interval '5 days')
        WHERE property_id = p_property_id
          AND status = 'declared'
          AND declared_at < (now() - interval '5 days')
        RETURNING id, due_date
    LOOP
        INSERT INTO activity_logs (property_id, type, metadata)
        VALUES (p_property_id, 'rent_auto_approved', jsonb_build_object('month', v_approved_row.due_date));
    END LOOP;

    -- CLEANUP: Delete any "pending" rows that are now BEFORE the contract start month
    DELETE FROM rent_payments
    WHERE property_id = p_property_id
      AND status = 'pending'
      AND date_trunc('month', due_date) < date_trunc('month', v_start_date);

    -- Loop from start date to today (plus 1 month buffer)
    v_current_date := (date_trunc('month', v_start_date) + (v_due_day - 1) * interval '1 day')::date;
    v_end_date := (date_trunc('month', now() + interval '1 month') + (v_due_day - 1) * interval '1 day')::date;

    WHILE v_current_date <= v_end_date LOOP
        INSERT INTO rent_payments (property_id, tenant_id, amount, currency, due_date, status)
        VALUES (p_property_id, v_tenant_id, v_monthly_rent, v_currency, v_current_date, 'pending')
        ON CONFLICT (property_id, due_date) 
        DO UPDATE SET 
            tenant_id = COALESCE(EXCLUDED.tenant_id, rent_payments.tenant_id), 
            amount = EXCLUDED.amount, 
            currency = EXCLUDED.currency
        WHERE rent_payments.status = 'pending';

        v_current_date := (date_trunc('month', v_current_date + interval '1.5 month') + (v_due_day - 1) * interval '1 day')::date;
    END LOOP;
END;
$$;
