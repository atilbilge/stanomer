-- SQL Script to backfill payment_id in metadata of existing activity_logs
-- Run this in your Supabase SQL Editor to associate old logs with their specific payments.
-- This ensures the history lists do not get mixed up.

DO $$
DECLARE
    r_log RECORD;
    v_payment_id UUID;
    v_due_date DATE;
    v_month TEXT;
    v_amount NUMERIC;
    v_log_date DATE;
BEGIN
    FOR r_log IN 
        SELECT id, property_id, type, metadata, created_at::date as log_date FROM public.activity_logs 
        WHERE (metadata->>'payment_id') IS NULL AND type IN ('rent_declared', 'rent_approved', 'rent_rejected', 'rent_disputed', 'invoice_uploaded', 'payment_toggle', 'rent_auto_approved')
    LOOP
        v_payment_id := NULL;
        v_due_date := (r_log.metadata->>'due_date')::date;
        v_month := r_log.metadata->>'month';
        v_amount := (r_log.metadata->>'amount')::numeric;
        v_log_date := COALESCE(v_due_date, r_log.log_date);

        IF r_log.type = 'invoice_uploaded' THEN
            -- Find matching utility payment in the same month/year with matching amount (if amount matches)
            SELECT id INTO v_payment_id
            FROM public.rent_payments
            WHERE property_id = r_log.property_id
              AND title != 'Kira'
              AND date_trunc('month', due_date) = date_trunc('month', v_log_date)
              AND (v_amount IS NULL OR amount = v_amount)
            LIMIT 1;
        ELSE
            -- Rent payments (always title = 'Kira')
            SELECT id INTO v_payment_id
            FROM public.rent_payments
            WHERE property_id = r_log.property_id
              AND title = 'Kira'
              AND date_trunc('month', due_date) = date_trunc('month', v_log_date)
            LIMIT 1;
        END IF;

        IF v_payment_id IS NOT NULL THEN
            UPDATE public.activity_logs
            SET metadata = metadata || jsonb_build_object('payment_id', v_payment_id)
            WHERE id = r_log.id;
        END IF;
    END LOOP;
END $$;
