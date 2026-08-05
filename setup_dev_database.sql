-- ============================================================================
-- STANOMER DEV DATABASE SETUP SCRIPT (COMPLETE & EXACT SCHEMA)
-- Safely sets up public schema, ENUMs, tables, RLS, Realtime & Functions
-- Last Updated: 2026-07-29 — Added B2B2C Agency Support
-- ============================================================================

-- 1. ENUM TYPES
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
        CREATE TYPE public.user_role AS ENUM ('landlord', 'tenant', 'both', 'agency');
    END IF;
    -- Add 'agency' to existing enum if it was created without it
    IF NOT EXISTS (
        SELECT 1 FROM pg_enum
        WHERE enumlabel = 'agency'
          AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'user_role')
    ) THEN
        ALTER TYPE public.user_role ADD VALUE 'agency';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'contract_status') THEN
        CREATE TYPE public.contract_status AS ENUM ('pending', 'negotiating', 'active', 'rejected', 'cancelled', 'terminated', 'expired', 'revision_requested');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'rent_payment_status') THEN
        CREATE TYPE public.rent_payment_status AS ENUM ('pending', 'declared', 'paid', 'overdue', 'disputed', 'rejected');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'tax_type') THEN
        CREATE TYPE public.tax_type AS ENUM ('included', 'excluded_tenant', 'excluded_landlord');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'invitation_status') THEN
        CREATE TYPE public.invitation_status AS ENUM ('pending', 'accepted', 'rejected', 'expired');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'maintenance_status') THEN
        CREATE TYPE public.maintenance_status AS ENUM ('open', 'in_progress', 'resolved', 'cancelled');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'maintenance_category') THEN
        CREATE TYPE public.maintenance_category AS ENUM ('plumbing', 'electrical', 'heating', 'appliance', 'structural', 'internet', 'other');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'maintenance_priority') THEN
        CREATE TYPE public.maintenance_priority AS ENUM ('low', 'medium', 'high', 'urgent');
    END IF;
END $$;

-- 2. PUBLIC TABLES
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT,
    full_name TEXT,
    phone_number TEXT,
    avatar_url TEXT,
    role public.user_role DEFAULT 'landlord',
    active_role TEXT DEFAULT 'landlord',
    -- Agency white-label branding columns
    company_name TEXT,
    logo_url TEXT,
    color_scheme JSONB DEFAULT '{}'::jsonb,
    updated_at TIMESTAMPTZ DEFAULT now(),
    created_at TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS company_name TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS logo_url TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS color_scheme JSONB DEFAULT '{}'::jsonb;

CREATE TABLE IF NOT EXISTS public.properties (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    landlord_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    tenant_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    agency_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    title TEXT,
    name TEXT,
    address TEXT NOT NULL,
    default_monthly_rent NUMERIC(12,2),
    default_deposit_amount NUMERIC(12,2),
    currency TEXT NOT NULL DEFAULT 'EUR',
    default_deposit_currency TEXT DEFAULT 'EUR',
    default_due_day INT DEFAULT 1 CHECK (default_due_day >= 1 AND default_due_day <= 31),
    landlord_phone TEXT,
    landlord_email TEXT,
    landlord_name TEXT,
    expenses_template JSONB DEFAULT '[]'::jsonb,
    owner_note TEXT,
    tax_type public.tax_type DEFAULT 'included',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE public.properties ALTER COLUMN landlord_id DROP NOT NULL;
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS agency_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL;
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS landlord_phone TEXT;
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS landlord_email TEXT;
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS landlord_name TEXT;
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS city TEXT;

CREATE TABLE IF NOT EXISTS public.contracts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
    landlord_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    tenant_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    agency_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    inviter_name TEXT,
    invitee_email TEXT,
    token TEXT,
    deposit_currency TEXT DEFAULT 'EUR',
    tenant_feedback TEXT,
    status public.contract_status DEFAULT 'pending',
    start_date DATE NOT NULL,
    end_date DATE,
    monthly_rent NUMERIC(12,2) NOT NULL,
    deposit_amount NUMERIC(12,2),
    currency TEXT NOT NULL DEFAULT 'EUR',
    due_day INT DEFAULT 1 CHECK (due_day >= 1 AND due_day <= 31),
    expenses JSONB DEFAULT '[]'::jsonb,
    additional_documents JSONB DEFAULT '[]'::jsonb,
    tax_type public.tax_type DEFAULT 'included',
    special_conditions TEXT,
    rejection_reason TEXT,
    proposed_by UUID REFERENCES public.profiles(id),
    termination_reason TEXT,
    termination_requested_by UUID REFERENCES public.profiles(id),
    termination_requested_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE public.contracts ADD COLUMN IF NOT EXISTS agency_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL;
ALTER TABLE public.contracts ADD COLUMN IF NOT EXISTS invitee_email TEXT;
ALTER TABLE public.contracts ADD COLUMN IF NOT EXISTS inviter_name TEXT;
ALTER TABLE public.contracts ADD COLUMN IF NOT EXISTS token TEXT;
ALTER TABLE public.contracts ADD COLUMN IF NOT EXISTS deposit_currency TEXT DEFAULT 'EUR';
ALTER TABLE public.contracts ADD COLUMN IF NOT EXISTS tenant_feedback TEXT;

CREATE TABLE IF NOT EXISTS public.invitations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
    contract_id UUID REFERENCES public.contracts(id) ON DELETE SET NULL,
    inviter_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    inviter_name TEXT,
    invitee_email TEXT,
    token TEXT UNIQUE NOT NULL,
    target_role TEXT DEFAULT 'tenant',
    status public.invitation_status DEFAULT 'pending',
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE public.invitations ALTER COLUMN invitee_email DROP NOT NULL;
ALTER TABLE public.invitations ADD COLUMN IF NOT EXISTS inviter_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE public.invitations ADD COLUMN IF NOT EXISTS agency_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL;
ALTER TABLE public.invitations ADD COLUMN IF NOT EXISTS target_role TEXT DEFAULT 'tenant';

CREATE TABLE IF NOT EXISTS public.rent_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
    contract_id UUID REFERENCES public.contracts(id) ON DELETE SET NULL,
    landlord_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    tenant_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    due_date DATE NOT NULL,
    rent_amount NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    expenses_amount NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    total_amount NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    currency TEXT NOT NULL DEFAULT 'EUR',
    status public.rent_payment_status DEFAULT 'pending',
    payment_type TEXT DEFAULT 'rent',
    notes TEXT,
    receipt_url TEXT,
    declared_at TIMESTAMPTZ,
    auto_approval_at TIMESTAMPTZ,
    dispute_reason TEXT,
    disputed_by UUID REFERENCES public.profiles(id),
    disputed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.maintenance_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
    reporter_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    category TEXT DEFAULT 'other',
    priority TEXT DEFAULT 'normal',
    status TEXT DEFAULT 'open',
    photo_urls TEXT[],
    resolved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE public.maintenance_requests ADD COLUMN IF NOT EXISTS category TEXT DEFAULT 'other';
ALTER TABLE public.maintenance_requests ADD COLUMN IF NOT EXISTS priority TEXT DEFAULT 'normal';
ALTER TABLE public.maintenance_requests ADD COLUMN IF NOT EXISTS photos_urls TEXT[] DEFAULT '{}';
ALTER TABLE public.maintenance_requests ADD COLUMN IF NOT EXISTS photo_urls TEXT[] DEFAULT '{}';
ALTER TABLE public.maintenance_requests ADD COLUMN IF NOT EXISTS contract_id UUID REFERENCES public.contracts(id) ON DELETE SET NULL;
ALTER TABLE public.maintenance_requests DROP CONSTRAINT IF EXISTS maintenance_requests_status_check;
ALTER TABLE public.maintenance_requests ADD CONSTRAINT maintenance_requests_status_check CHECK (status IN ('open', 'investigating', 'resolved', 'closed', 'pending', 'in_progress', 'inProgress', 'cancelled'));

ALTER TABLE public.maintenance_requests DROP CONSTRAINT IF EXISTS maintenance_requests_priority_check;
ALTER TABLE public.maintenance_requests ADD CONSTRAINT maintenance_requests_priority_check CHECK (priority IN ('normal', 'medium', 'low', 'urgent', 'high'));

CREATE TABLE IF NOT EXISTS public.maintenance_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    request_id UUID NOT NULL REFERENCES public.maintenance_requests(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    photo_url TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE public.maintenance_messages ADD COLUMN IF NOT EXISTS photo_url TEXT;
ALTER TABLE public.maintenance_messages ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE public.maintenance_messages ADD COLUMN IF NOT EXISTS sender_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE;

CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    type TEXT NOT NULL,
    related_id UUID,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE public.notifications ADD COLUMN IF NOT EXISTS related_id UUID;

CREATE TABLE IF NOT EXISTS public.activity_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    payment_id UUID REFERENCES public.rent_payments(id) ON DELETE SET NULL,
    action_type TEXT NOT NULL,
    description TEXT NOT NULL,
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE public.activity_logs ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE;

-- 3. ENABLE RLS ON ALL TABLES
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.properties ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.contracts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rent_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.maintenance_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.maintenance_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_logs ENABLE ROW LEVEL SECURITY;

-- 4. RLS POLICIES (DROP IF EXISTS & CREATE)
DROP POLICY IF EXISTS "Authenticated users can see all profiles" ON public.profiles;
CREATE POLICY "Authenticated users can see all profiles" ON public.profiles FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
CREATE POLICY "Users can insert their own profile" ON public.profiles FOR INSERT TO authenticated WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
CREATE POLICY "Users can update their own profile" ON public.profiles FOR UPDATE TO authenticated USING (auth.uid() = id);

-- Properties RLS (with agency support)
DROP POLICY IF EXISTS "landlord_select_properties" ON public.properties;
DROP POLICY IF EXISTS "tenant_select_properties" ON public.properties;
DROP POLICY IF EXISTS "tenant_view_invited_properties" ON public.properties;
DROP POLICY IF EXISTS "properties_select_policy" ON public.properties;
CREATE POLICY "properties_select_policy" ON public.properties FOR SELECT TO authenticated
    USING (
        landlord_id = auth.uid()
        OR tenant_id = auth.uid()
        OR agency_id = auth.uid()
        OR EXISTS (SELECT 1 FROM public.invitations i WHERE i.property_id = properties.id AND (LOWER(i.invitee_email) = LOWER(COALESCE(auth.jwt()->>'email', '')) OR i.token IS NOT NULL))
        OR EXISTS (SELECT 1 FROM public.contracts c WHERE c.property_id = properties.id AND (c.tenant_id = auth.uid() OR (c.invitee_email IS NOT NULL AND LOWER(c.invitee_email) = LOWER(COALESCE(auth.jwt()->>'email', ''))) OR c.token IS NOT NULL))
    );

DROP POLICY IF EXISTS "Landlords can insert properties" ON public.properties;
DROP POLICY IF EXISTS "properties_insert_policy" ON public.properties;
CREATE POLICY "properties_insert_policy" ON public.properties FOR INSERT TO authenticated
    WITH CHECK (landlord_id = auth.uid() OR agency_id = auth.uid());

DROP POLICY IF EXISTS "landlord_update_properties" ON public.properties;
DROP POLICY IF EXISTS "properties_update_policy" ON public.properties;
CREATE POLICY "properties_update_policy" ON public.properties FOR UPDATE TO authenticated
    USING (landlord_id = auth.uid() OR agency_id = auth.uid() OR tenant_id = auth.uid() OR tenant_id IS NULL);

-- Contracts RLS (with agency, invitee_email, and token lookup support)
DROP POLICY IF EXISTS "Users can view relevant contracts" ON public.contracts;
DROP POLICY IF EXISTS "contracts_select_policy" ON public.contracts;
CREATE POLICY "contracts_select_policy" ON public.contracts FOR SELECT TO authenticated
    USING (landlord_id = auth.uid() OR tenant_id = auth.uid() OR agency_id = auth.uid() OR (invitee_email IS NOT NULL AND LOWER(invitee_email) = LOWER(COALESCE(auth.jwt()->>'email', ''))) OR (token IS NOT NULL));

DROP POLICY IF EXISTS "Landlords can insert contracts" ON public.contracts;
DROP POLICY IF EXISTS "contracts_insert_policy" ON public.contracts;
CREATE POLICY "contracts_insert_policy" ON public.contracts FOR INSERT TO authenticated
    WITH CHECK (landlord_id = auth.uid() OR agency_id = auth.uid());

DROP POLICY IF EXISTS "Users can update relevant contracts" ON public.contracts;
DROP POLICY IF EXISTS "contracts_update_policy" ON public.contracts;
CREATE POLICY "contracts_update_policy" ON public.contracts FOR UPDATE TO authenticated
    USING (landlord_id = auth.uid() OR agency_id = auth.uid() OR tenant_id = auth.uid() OR tenant_id IS NULL OR (invitee_email IS NOT NULL AND LOWER(invitee_email) = LOWER(COALESCE(auth.jwt()->>'email', ''))));

DROP POLICY IF EXISTS "contracts_delete_policy" ON public.contracts;
CREATE POLICY "contracts_delete_policy" ON public.contracts FOR DELETE TO authenticated
    USING (landlord_id = auth.uid() OR agency_id = auth.uid());

DROP POLICY IF EXISTS "Users can view invitations" ON public.invitations;
CREATE POLICY "Users can view invitations" ON public.invitations FOR SELECT TO authenticated USING (inviter_id = auth.uid() OR public.is_agency_of_property(property_id, auth.uid()) OR LOWER(invitee_email) = LOWER(COALESCE(auth.jwt()->>'email', '')) OR (token IS NOT NULL));

DROP POLICY IF EXISTS "Users can insert invitations" ON public.invitations;
CREATE POLICY "Users can insert invitations" ON public.invitations FOR INSERT TO authenticated WITH CHECK (inviter_id = auth.uid() OR public.is_agency_of_property(property_id, auth.uid()));

DROP POLICY IF EXISTS "Users can view rent payments" ON public.rent_payments;
CREATE POLICY "Users can view rent payments" ON public.rent_payments FOR SELECT TO authenticated USING (landlord_id = auth.uid() OR tenant_id = auth.uid() OR public.is_agency_of_property(property_id, auth.uid()));

DROP POLICY IF EXISTS "Landlords and tenants can update rent payments" ON public.rent_payments;
CREATE POLICY "Landlords and tenants can update rent payments" ON public.rent_payments FOR UPDATE TO authenticated USING (landlord_id = auth.uid() OR tenant_id = auth.uid() OR public.is_agency_of_property(property_id, auth.uid()));

DROP POLICY IF EXISTS "Landlords and agencies can insert rent payments" ON public.rent_payments;
CREATE POLICY "Landlords and agencies can insert rent payments" ON public.rent_payments FOR INSERT TO authenticated WITH CHECK (landlord_id = auth.uid() OR public.is_agency_of_property(property_id, auth.uid()));

-- Maintenance RLS
DROP POLICY IF EXISTS "maintenance_requests_select_policy" ON public.maintenance_requests;
CREATE POLICY "maintenance_requests_select_policy" ON public.maintenance_requests FOR SELECT TO authenticated
    USING (reporter_id = auth.uid() OR public.is_agency_of_property(property_id, auth.uid()) OR EXISTS (SELECT 1 FROM public.properties p WHERE p.id = maintenance_requests.property_id AND (p.landlord_id = auth.uid() OR p.tenant_id = auth.uid() OR p.agency_id = auth.uid())));

DROP POLICY IF EXISTS "maintenance_requests_insert_policy" ON public.maintenance_requests;
CREATE POLICY "maintenance_requests_insert_policy" ON public.maintenance_requests FOR INSERT TO authenticated
    WITH CHECK (reporter_id = auth.uid() OR public.is_agency_of_property(property_id, auth.uid()));

DROP POLICY IF EXISTS "maintenance_requests_update_policy" ON public.maintenance_requests;
CREATE POLICY "maintenance_requests_update_policy" ON public.maintenance_requests FOR UPDATE TO authenticated
    USING (reporter_id = auth.uid() OR public.is_agency_of_property(property_id, auth.uid()) OR EXISTS (SELECT 1 FROM public.properties p WHERE p.id = maintenance_requests.property_id AND (p.landlord_id = auth.uid() OR p.tenant_id = auth.uid() OR p.agency_id = auth.uid())));

DROP POLICY IF EXISTS "maintenance_messages_select_policy" ON public.maintenance_messages;
CREATE POLICY "maintenance_messages_select_policy" ON public.maintenance_messages FOR SELECT TO authenticated
    USING (sender_id = auth.uid() OR EXISTS (SELECT 1 FROM public.maintenance_requests r JOIN public.properties p ON p.id = r.property_id WHERE r.id = maintenance_messages.request_id AND (r.reporter_id = auth.uid() OR p.landlord_id = auth.uid() OR p.tenant_id = auth.uid() OR p.agency_id = auth.uid())));

DROP POLICY IF EXISTS "maintenance_messages_insert_policy" ON public.maintenance_messages;
CREATE POLICY "maintenance_messages_insert_policy" ON public.maintenance_messages FOR INSERT TO authenticated
    WITH CHECK (sender_id = auth.uid());

DROP POLICY IF EXISTS "notifications_select_policy" ON public.notifications;
CREATE POLICY "notifications_select_policy" ON public.notifications FOR SELECT TO authenticated USING (user_id = auth.uid());

DROP POLICY IF EXISTS "notifications_insert_policy" ON public.notifications;
CREATE POLICY "notifications_insert_policy" ON public.notifications FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "notifications_update_policy" ON public.notifications;
CREATE POLICY "notifications_update_policy" ON public.notifications FOR UPDATE TO authenticated USING (user_id = auth.uid());

DROP POLICY IF EXISTS "activity_logs_select_policy" ON public.activity_logs;
CREATE POLICY "activity_logs_select_policy" ON public.activity_logs FOR SELECT TO authenticated
    USING (user_id = auth.uid() OR public.is_agency_of_property(property_id, auth.uid()) OR EXISTS (SELECT 1 FROM public.properties p WHERE p.id = activity_logs.property_id AND (p.landlord_id = auth.uid() OR p.tenant_id = auth.uid() OR p.agency_id = auth.uid())));

DROP POLICY IF EXISTS "activity_logs_insert_policy" ON public.activity_logs;
CREATE POLICY "activity_logs_insert_policy" ON public.activity_logs FOR INSERT TO authenticated WITH CHECK (true);

-- 5. REALTIME PUBLICATION & REPLICA IDENTITY FOR PUBLIC TABLES
ALTER TABLE public.properties REPLICA IDENTITY FULL;
ALTER TABLE public.contracts REPLICA IDENTITY FULL;
ALTER TABLE public.rent_payments REPLICA IDENTITY FULL;
ALTER TABLE public.maintenance_requests REPLICA IDENTITY FULL;
ALTER TABLE public.maintenance_messages REPLICA IDENTITY FULL;
ALTER TABLE public.notifications REPLICA IDENTITY FULL;
ALTER TABLE public.activity_logs REPLICA IDENTITY FULL;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'properties') THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.properties;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'contracts') THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.contracts;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'rent_payments') THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.rent_payments;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'invitations') THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.invitations;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'activity_logs') THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.activity_logs;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'maintenance_requests') THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.maintenance_requests;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'maintenance_messages') THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.maintenance_messages;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'notifications') THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
    END IF;
END $$;

-- LANDLORD OWNERSHIP CLAIM RPC
CREATE OR REPLACE FUNCTION public.claim_landlord_ownership(p_token TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_invitation RECORD;
    v_user_email TEXT;
    v_user_name TEXT;
    v_user_phone TEXT;
BEGIN
    v_user_email := COALESCE(auth.jwt()->>'email', '');
    
    SELECT full_name, phone_number INTO v_user_name, v_user_phone
    FROM public.profiles
    WHERE id = auth.uid();

    SELECT * INTO v_invitation
    FROM public.invitations
    WHERE token = p_token
      AND target_role = 'landlord'
      AND status = 'pending'
      AND expires_at > now();

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'message', 'Invalid, expired, or non-landlord invitation token.');
    END IF;

    UPDATE public.properties
    SET landlord_id = auth.uid(),
        landlord_name = COALESCE(NULLIF(v_user_name, ''), landlord_name),
        landlord_email = COALESCE(NULLIF(v_user_email, ''), landlord_email),
        landlord_phone = COALESCE(NULLIF(v_user_phone, ''), landlord_phone),
        updated_at = now()
    WHERE id = v_invitation.property_id;

    UPDATE public.invitations
    SET status = 'accepted'
    WHERE id = v_invitation.id;

    RETURN jsonb_build_object(
        'success', true,
        'property_id', v_invitation.property_id,
        'message', 'Landlord ownership claimed successfully.'
    );
END;
$$;

-- GET INVITE DETAILS RPC
CREATE OR REPLACE FUNCTION public.get_invite_details(p_token TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_invite_json JSONB;
    v_contract_json JSONB;
BEGIN
    SELECT (to_jsonb(i.*) || jsonb_build_object(
        'type', CASE WHEN i.target_role = 'landlord' THEN 'landlord_ownership' ELSE 'invitation' END,
        'properties', jsonb_build_object(
            'id', p.id,
            'name', p.name,
            'title', p.title,
            'address', p.address,
            'default_monthly_rent', p.default_monthly_rent,
            'default_deposit_amount', p.default_deposit_amount,
            'currency', p.currency,
            'landlord_id', p.landlord_id,
            'tenant_id', p.tenant_id,
            'agency_id', p.agency_id,
            'landlord_name', p.landlord_name,
            'landlord_email', p.landlord_email,
            'landlord_phone', p.landlord_phone
        )
    ))
    INTO v_invite_json
    FROM public.invitations i
    JOIN public.properties p ON p.id = i.property_id
    WHERE i.token = p_token
      AND i.status = 'pending'
      AND i.expires_at > now();

    IF v_invite_json IS NOT NULL THEN
        RETURN v_invite_json;
    END IF;

    SELECT (to_jsonb(c.*) || jsonb_build_object(
        'type', 'contract',
        'properties', jsonb_build_object(
            'id', p.id,
            'name', p.name,
            'title', p.title,
            'address', p.address,
            'default_monthly_rent', p.default_monthly_rent,
            'default_deposit_amount', p.default_deposit_amount,
            'currency', p.currency,
            'landlord_id', p.landlord_id,
            'tenant_id', p.tenant_id,
            'agency_id', p.agency_id
        )
    ))
    INTO v_contract_json
    FROM public.contracts c
    JOIN public.properties p ON p.id = c.property_id
    WHERE c.token = p_token
      AND c.status IN ('pending', 'negotiating');

    IF v_contract_json IS NOT NULL THEN
        RETURN v_contract_json;
    END IF;

    RETURN NULL;
END;
$$;

DROP POLICY IF EXISTS "users_view_invited_properties_by_token" ON public.properties;
CREATE POLICY "users_view_invited_properties_by_token" ON public.properties FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.invitations i 
            WHERE i.property_id = properties.id 
              AND i.token IS NOT NULL 
              AND i.status = 'pending'
        )
    );

-- 6. AUTOMATIC PROFILE TRIGGER ON SIGNUP
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, full_name, role, email, active_role)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email),
        COALESCE((NEW.raw_user_meta_data->>'role')::public.user_role, 'landlord'),
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'role', 'landlord')
    )
    ON CONFLICT (id) DO UPDATE
    SET full_name = EXCLUDED.full_name,
        email = EXCLUDED.email;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 7. STORAGE BUCKETS SETUP
INSERT INTO storage.buckets (id, name, public) VALUES ('property-photos', 'property-photos', true) ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('rent-receipts', 'rent-receipts', true) ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('maintenance-photos', 'maintenance-photos', true) ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('contract-documents', 'contract-documents', false) ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('contracts', 'contracts', false) ON CONFLICT (id) DO NOTHING;

-- 7b. STORAGE RLS POLICIES
-- rent-receipts: landlord/agency/tenant can upload and view
DROP POLICY IF EXISTS "rent_receipts_select_policy"  ON storage.objects;
CREATE POLICY "rent_receipts_select_policy"
  ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id = 'rent-receipts' AND auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "rent_receipts_insert_policy"  ON storage.objects;
CREATE POLICY "rent_receipts_insert_policy"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'rent-receipts' AND auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "rent_receipts_update_policy"  ON storage.objects;
CREATE POLICY "rent_receipts_update_policy"
  ON storage.objects FOR UPDATE TO authenticated
  USING (bucket_id = 'rent-receipts' AND (storage.foldername(name))[1] = auth.uid()::text);

DROP POLICY IF EXISTS "rent_receipts_delete_policy"  ON storage.objects;
CREATE POLICY "rent_receipts_delete_policy"
  ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'rent-receipts' AND (storage.foldername(name))[1] = auth.uid()::text);

-- contracts bucket
DROP POLICY IF EXISTS "contracts_select_policy"  ON storage.objects;
CREATE POLICY "contracts_select_policy"
  ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id = 'contracts' AND auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "contracts_insert_policy"  ON storage.objects;
CREATE POLICY "contracts_insert_policy"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'contracts' AND auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "contracts_update_policy"  ON storage.objects;
CREATE POLICY "contracts_update_policy"
  ON storage.objects FOR UPDATE TO authenticated
  USING (bucket_id = 'contracts' AND auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "contracts_delete_policy"  ON storage.objects;
CREATE POLICY "contracts_delete_policy"
  ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'contracts' AND auth.uid() IS NOT NULL);

-- contract-documents bucket
DROP POLICY IF EXISTS "contract_documents_select_policy"  ON storage.objects;
CREATE POLICY "contract_documents_select_policy"
  ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id = 'contract-documents' AND auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "contract_documents_insert_policy"  ON storage.objects;
CREATE POLICY "contract_documents_insert_policy"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'contract-documents' AND auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "contract_documents_delete_policy"  ON storage.objects;
CREATE POLICY "contract_documents_delete_policy"
  ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'contract-documents' AND auth.uid() IS NOT NULL);

-- property-photos bucket
DROP POLICY IF EXISTS "property_photos_select_policy"  ON storage.objects;
CREATE POLICY "property_photos_select_policy"
  ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id = 'property-photos');

DROP POLICY IF EXISTS "property_photos_insert_policy"  ON storage.objects;
CREATE POLICY "property_photos_insert_policy"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'property-photos' AND auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "property_photos_delete_policy"  ON storage.objects;
CREATE POLICY "property_photos_delete_policy"
  ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'property-photos' AND auth.uid() IS NOT NULL);

-- maintenance-photos bucket
DROP POLICY IF EXISTS "maintenance_photos_select_policy"  ON storage.objects;
CREATE POLICY "maintenance_photos_select_policy"
  ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id = 'maintenance-photos');

DROP POLICY IF EXISTS "maintenance_photos_insert_policy"  ON storage.objects;
CREATE POLICY "maintenance_photos_insert_policy"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'maintenance-photos' AND auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "maintenance_photos_delete_policy"  ON storage.objects;
CREATE POLICY "maintenance_photos_delete_policy"
  ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'maintenance-photos' AND auth.uid() IS NOT NULL);

-- 8. VIEWS
DROP VIEW IF EXISTS public.properties_with_names CASCADE;

CREATE VIEW public.properties_with_names AS
SELECT 
    p.id,
    p.landlord_id,
    p.tenant_id,
    p.agency_id,
    p.title,
    p.name,
    p.address,
    p.default_monthly_rent,
    p.default_deposit_amount,
    p.currency,
    p.default_deposit_currency,
    p.default_due_day,
    p.expenses_template,
    p.owner_note,
    p.tax_type,
    p.created_at,
    p.updated_at,
    p.landlord_phone,
    COALESCE(l.full_name, p.landlord_name) AS landlord_name,
    COALESCE(l.email, p.landlord_email) AS landlord_email,
    t.full_name AS tenant_name,
    t.email AS tenant_email,
    a.company_name AS agency_name,
    a.email AS agency_email
FROM public.properties p
LEFT JOIN public.profiles l ON p.landlord_id = l.id
LEFT JOIN public.profiles t ON p.tenant_id = t.id
LEFT JOIN public.profiles a ON p.agency_id = a.id;

ALTER VIEW public.properties_with_names SET (security_invoker = on);
