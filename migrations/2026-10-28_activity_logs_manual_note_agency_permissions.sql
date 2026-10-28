-- Migration: 2026-10-28_activity_logs_manual_note_agency_permissions.sql
-- Description: Restrict manual note viewing, insertion, update, and deletion in activity_logs strictly to agency users or creators.
-- Target: DEV ONLY (thvbpifahvasyzmngpzp)

DO $$
BEGIN
    -- 1. Ensure RLS is enabled on public.activity_logs
    ALTER TABLE public.activity_logs ENABLE ROW LEVEL SECURITY;

    -- 2. SELECT Policy: If type is 'manual_note', only agency of property or author can view it
    DROP POLICY IF EXISTS "activity_logs_select_policy" ON public.activity_logs;
    CREATE POLICY "activity_logs_select_policy" ON public.activity_logs FOR SELECT TO authenticated
        USING (
            CASE 
                WHEN type = 'manual_note' THEN
                    (user_id = auth.uid() OR public.is_agency_of_property(property_id, auth.uid()) OR EXISTS (SELECT 1 FROM public.properties p WHERE p.id = activity_logs.property_id AND p.agency_id = auth.uid()))
                ELSE
                    (user_id = auth.uid() OR public.is_agency_of_property(property_id, auth.uid()) OR EXISTS (SELECT 1 FROM public.properties p WHERE p.id = activity_logs.property_id AND (p.landlord_id = auth.uid() OR p.tenant_id = auth.uid() OR p.agency_id = auth.uid())))
            END
        );

    -- 3. INSERT Policy: If type is 'manual_note', only agency of property or author can insert it
    DROP POLICY IF EXISTS "activity_logs_insert_policy" ON public.activity_logs;
    CREATE POLICY "activity_logs_insert_policy" ON public.activity_logs FOR INSERT TO authenticated
        WITH CHECK (
            CASE 
                WHEN type = 'manual_note' THEN
                    (public.is_agency_of_property(property_id, auth.uid()) OR EXISTS (SELECT 1 FROM public.properties p WHERE p.id = activity_logs.property_id AND p.agency_id = auth.uid()) OR user_id = auth.uid())
                ELSE true
            END
        );

    -- 4. UPDATE Policy: Only agency of property or author can update manual notes
    DROP POLICY IF EXISTS "activity_logs_update_policy" ON public.activity_logs;
    CREATE POLICY "activity_logs_update_policy" ON public.activity_logs FOR UPDATE TO authenticated
        USING (
            type = 'manual_note' AND (
                public.is_agency_of_property(property_id, auth.uid()) OR
                EXISTS (
                    SELECT 1 FROM public.properties p
                    WHERE p.id = activity_logs.property_id AND p.agency_id = auth.uid()
                ) OR
                user_id = auth.uid()
            )
        )
        WITH CHECK (
            type = 'manual_note' AND (
                public.is_agency_of_property(property_id, auth.uid()) OR
                EXISTS (
                    SELECT 1 FROM public.properties p
                    WHERE p.id = activity_logs.property_id AND p.agency_id = auth.uid()
                ) OR
                user_id = auth.uid()
            )
        );

    -- 5. DELETE Policy: Only agency of property or author can delete manual notes
    DROP POLICY IF EXISTS "activity_logs_delete_policy" ON public.activity_logs;
    CREATE POLICY "activity_logs_delete_policy" ON public.activity_logs FOR DELETE TO authenticated
        USING (
            type = 'manual_note' AND (
                public.is_agency_of_property(property_id, auth.uid()) OR
                EXISTS (
                    SELECT 1 FROM public.properties p
                    WHERE p.id = activity_logs.property_id AND p.agency_id = auth.uid()
                ) OR
                user_id = auth.uid()
            )
        );
END $$;
