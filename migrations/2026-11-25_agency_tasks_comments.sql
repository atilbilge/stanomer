-- Migration: Task Comments on public.agency_tasks
-- Target: Dev Supabase (nbcbfmhztnnhfnapvaet)
-- Adds JSONB comments array to agency_tasks and allows any active agency member
-- to comment on agency tasks while preserving admin-only reassignment to other users.

BEGIN;

ALTER TABLE public.agency_tasks
    ADD COLUMN IF NOT EXISTS comments JSONB NOT NULL DEFAULT '[]'::jsonb;

DROP POLICY IF EXISTS "Agency members can update agency tasks" ON public.agency_tasks;
CREATE POLICY "Agency members can update agency tasks" ON public.agency_tasks
    FOR UPDATE TO authenticated
    USING (
        public.is_agency_member(agency_id, auth.uid())
    )
    WITH CHECK (
        public.is_agency_member(agency_id, auth.uid())
        AND (
            agency_id = auth.uid()
            OR assigned_to IS NULL
            OR assigned_to = auth.uid()
            OR EXISTS (
                SELECT 1
                FROM public.agency_tasks orig
                WHERE orig.id = agency_tasks.id
                  AND orig.assigned_to IS NOT DISTINCT FROM agency_tasks.assigned_to
            )
        )
    );

COMMIT;

NOTIFY pgrst, 'reload schema';
