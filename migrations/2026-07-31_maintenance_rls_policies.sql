-- Migration: 2026-07-31_maintenance_rls_policies.sql
-- Description: Enable RLS, fix status/priority check constraints, add policies for maintenance_requests, maintenance_messages, notifications, activity_logs, and add maintenance_messages to supabase_realtime publication.

ALTER TABLE public.maintenance_requests ADD COLUMN IF NOT EXISTS category TEXT DEFAULT 'other';
ALTER TABLE public.maintenance_requests ADD COLUMN IF NOT EXISTS priority TEXT DEFAULT 'normal';
ALTER TABLE public.maintenance_requests ADD COLUMN IF NOT EXISTS photos_urls TEXT[] DEFAULT '{}';
ALTER TABLE public.maintenance_requests ADD COLUMN IF NOT EXISTS photo_urls TEXT[] DEFAULT '{}';
ALTER TABLE public.maintenance_requests ADD COLUMN IF NOT EXISTS contract_id UUID REFERENCES public.contracts(id) ON DELETE SET NULL;
ALTER TABLE public.activity_logs ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE;

ALTER TABLE public.maintenance_messages ADD COLUMN IF NOT EXISTS photo_url TEXT;
ALTER TABLE public.maintenance_messages ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE public.maintenance_messages ADD COLUMN IF NOT EXISTS sender_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE public.notifications ADD COLUMN IF NOT EXISTS related_id UUID;

-- Fix Status & Priority Check Constraints
ALTER TABLE public.maintenance_requests DROP CONSTRAINT IF EXISTS maintenance_requests_status_check;
ALTER TABLE public.maintenance_requests ADD CONSTRAINT maintenance_requests_status_check CHECK (status IN ('open', 'investigating', 'resolved', 'closed', 'pending', 'in_progress', 'inProgress', 'cancelled'));

ALTER TABLE public.maintenance_requests DROP CONSTRAINT IF EXISTS maintenance_requests_priority_check;
ALTER TABLE public.maintenance_requests ADD CONSTRAINT maintenance_requests_priority_check CHECK (priority IN ('normal', 'medium', 'low', 'urgent', 'high'));

-- Enable RLS
ALTER TABLE public.maintenance_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.maintenance_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_logs ENABLE ROW LEVEL SECURITY;

-- 1. maintenance_requests
DROP POLICY IF EXISTS "maintenance_requests_select_policy" ON public.maintenance_requests;
DROP POLICY IF EXISTS "Users can view maintenance requests" ON public.maintenance_requests;
CREATE POLICY "maintenance_requests_select_policy" ON public.maintenance_requests FOR SELECT TO authenticated
    USING (
        reporter_id = auth.uid()
        OR public.is_agency_of_property(property_id, auth.uid())
        OR EXISTS (
            SELECT 1 FROM public.properties p
            WHERE p.id = maintenance_requests.property_id
              AND (p.landlord_id = auth.uid() OR p.tenant_id = auth.uid() OR p.agency_id = auth.uid())
        )
    );

DROP POLICY IF EXISTS "maintenance_requests_insert_policy" ON public.maintenance_requests;
DROP POLICY IF EXISTS "Users can insert maintenance requests" ON public.maintenance_requests;
CREATE POLICY "maintenance_requests_insert_policy" ON public.maintenance_requests FOR INSERT TO authenticated
    WITH CHECK (reporter_id = auth.uid() OR public.is_agency_of_property(property_id, auth.uid()));

DROP POLICY IF EXISTS "maintenance_requests_update_policy" ON public.maintenance_requests;
DROP POLICY IF EXISTS "Users can update maintenance requests" ON public.maintenance_requests;
CREATE POLICY "maintenance_requests_update_policy" ON public.maintenance_requests FOR UPDATE TO authenticated
    USING (
        reporter_id = auth.uid()
        OR public.is_agency_of_property(property_id, auth.uid())
        OR EXISTS (
            SELECT 1 FROM public.properties p
            WHERE p.id = maintenance_requests.property_id
              AND (p.landlord_id = auth.uid() OR p.tenant_id = auth.uid() OR p.agency_id = auth.uid())
        )
    );

-- 2. maintenance_messages
DROP POLICY IF EXISTS "maintenance_messages_select_policy" ON public.maintenance_messages;
DROP POLICY IF EXISTS "Users can view maintenance messages" ON public.maintenance_messages;
CREATE POLICY "maintenance_messages_select_policy" ON public.maintenance_messages FOR SELECT TO authenticated
    USING (
        sender_id = auth.uid()
        OR user_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM public.maintenance_requests r
            JOIN public.properties p ON p.id = r.property_id
            WHERE r.id = maintenance_messages.request_id
              AND (r.reporter_id = auth.uid() OR p.landlord_id = auth.uid() OR p.tenant_id = auth.uid() OR p.agency_id = auth.uid())
        )
    );

DROP POLICY IF EXISTS "maintenance_messages_insert_policy" ON public.maintenance_messages;
DROP POLICY IF EXISTS "Users can insert maintenance messages" ON public.maintenance_messages;
CREATE POLICY "maintenance_messages_insert_policy" ON public.maintenance_messages FOR INSERT TO authenticated
    WITH CHECK (sender_id = auth.uid() OR user_id = auth.uid() OR auth.uid() IS NOT NULL);

-- 3. notifications
DROP POLICY IF EXISTS "notifications_select_policy" ON public.notifications;
DROP POLICY IF EXISTS "Users can view notifications" ON public.notifications;
CREATE POLICY "notifications_select_policy" ON public.notifications FOR SELECT TO authenticated
    USING (user_id = auth.uid());

DROP POLICY IF EXISTS "notifications_insert_policy" ON public.notifications;
DROP POLICY IF EXISTS "Users can insert notifications" ON public.notifications;
CREATE POLICY "notifications_insert_policy" ON public.notifications FOR INSERT TO authenticated
    WITH CHECK (true);

DROP POLICY IF EXISTS "notifications_update_policy" ON public.notifications;
DROP POLICY IF EXISTS "Users can update notifications" ON public.notifications;
CREATE POLICY "notifications_update_policy" ON public.notifications FOR UPDATE TO authenticated
    USING (user_id = auth.uid());

-- 4. activity_logs
DROP POLICY IF EXISTS "activity_logs_select_policy" ON public.activity_logs;
DROP POLICY IF EXISTS "Users can view activity logs" ON public.activity_logs;
CREATE POLICY "activity_logs_select_policy" ON public.activity_logs FOR SELECT TO authenticated
    USING (
        user_id = auth.uid()
        OR public.is_agency_of_property(property_id, auth.uid())
        OR EXISTS (
            SELECT 1 FROM public.properties p
            WHERE p.id = activity_logs.property_id
              AND (p.landlord_id = auth.uid() OR p.tenant_id = auth.uid() OR p.agency_id = auth.uid())
        )
    );

DROP POLICY IF EXISTS "activity_logs_insert_policy" ON public.activity_logs;
DROP POLICY IF EXISTS "Users can insert activity logs" ON public.activity_logs;
CREATE POLICY "activity_logs_insert_policy" ON public.activity_logs FOR INSERT TO authenticated
    WITH CHECK (true);

-- 5. Realtime Publication
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'maintenance_messages') THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.maintenance_messages;
    END IF;
END $$;
