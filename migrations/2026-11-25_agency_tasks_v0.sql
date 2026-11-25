-- Migration: Module-Independent Agency Task Management v0
-- Target: Dev Supabase (nbcbfmhztnnhfnapvaet)
-- Supports tasks created from scratch or linked to properties, listings, leads (CRM), and maintenance requests.
-- Permission rules:
--   * Everyone (Agency Admin & active Agency Operations) can create tasks for themselves and claim unassigned tasks.
--   * Agency Admin (agency_id = auth.uid()) can create/assign/reassign tasks to anyone in the agency (including self).
--   * Agency Operations cannot assign tasks to other users (only self or unassigned).

BEGIN;

CREATE TABLE IF NOT EXISTS public.agency_tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agency_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    status TEXT NOT NULL DEFAULT 'todo' CHECK (status IN ('todo', 'in_progress', 'done', 'cancelled')),
    priority TEXT NOT NULL DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    due_date DATE,
    source_type TEXT NOT NULL DEFAULT 'manual' CHECK (source_type IN ('manual', 'property', 'listing', 'lead', 'maintenance')),
    property_id UUID REFERENCES public.properties(id) ON DELETE SET NULL,
    listing_id UUID REFERENCES public.listings(id) ON DELETE SET NULL,
    lead_id UUID REFERENCES public.agency_leads(id) ON DELETE SET NULL,
    maintenance_request_id UUID REFERENCES public.maintenance_requests(id) ON DELETE SET NULL,
    assigned_to UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_agency_tasks_agency_id ON public.agency_tasks(agency_id);
CREATE INDEX IF NOT EXISTS idx_agency_tasks_assigned_to ON public.agency_tasks(assigned_to);
CREATE INDEX IF NOT EXISTS idx_agency_tasks_status ON public.agency_tasks(status);
CREATE INDEX IF NOT EXISTS idx_agency_tasks_source_type ON public.agency_tasks(source_type);

ALTER TABLE public.agency_tasks ENABLE ROW LEVEL SECURITY;

-- All active agency members & admin can view agency tasks
DROP POLICY IF EXISTS "Agency members can view agency tasks" ON public.agency_tasks;
CREATE POLICY "Agency members can view agency tasks" ON public.agency_tasks
    FOR SELECT TO authenticated
    USING (public.is_agency_member(agency_id, auth.uid()));

-- Admin can create tasks assigned to anyone; operations can create unassigned or self-assigned tasks
DROP POLICY IF EXISTS "Agency members can insert agency tasks" ON public.agency_tasks;
CREATE POLICY "Agency members can insert agency tasks" ON public.agency_tasks
    FOR INSERT TO authenticated
    WITH CHECK (
        public.is_agency_member(agency_id, auth.uid())
        AND (
            agency_id = auth.uid()
            OR assigned_to IS NULL
            OR assigned_to = auth.uid()
        )
    );

-- Admin can update/reassign any agency task; operations can claim unassigned tasks or update their own tasks (never assign to someone else)
DROP POLICY IF EXISTS "Agency members can update agency tasks" ON public.agency_tasks;
CREATE POLICY "Agency members can update agency tasks" ON public.agency_tasks
    FOR UPDATE TO authenticated
    USING (
        public.is_agency_member(agency_id, auth.uid())
        AND (
            agency_id = auth.uid()
            OR assigned_to IS NULL
            OR assigned_to = auth.uid()
            OR created_by = auth.uid()
        )
    )
    WITH CHECK (
        public.is_agency_member(agency_id, auth.uid())
        AND (
            agency_id = auth.uid()
            OR assigned_to IS NULL
            OR assigned_to = auth.uid()
        )
    );

-- Admin or task creator can delete tasks
DROP POLICY IF EXISTS "Agency admins and creators can delete agency tasks" ON public.agency_tasks;
CREATE POLICY "Agency admins and creators can delete agency tasks" ON public.agency_tasks
    FOR DELETE TO authenticated
    USING (
        public.is_agency_member(agency_id, auth.uid())
        AND (agency_id = auth.uid() OR created_by = auth.uid())
    );

GRANT SELECT, INSERT, UPDATE, DELETE ON public.agency_tasks TO authenticated, service_role;

COMMIT;

NOTIFY pgrst, 'reload schema';
