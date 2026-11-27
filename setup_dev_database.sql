-- ============================================================================
-- STANOMER DEV DATABASE SETUP SCRIPT (COMPLETE & EXACT SCHEMA)
-- Safely sets up public schema, ENUMs, tables, RLS, Realtime & Functions
-- Last Updated: 2026-08-13 — Added email_unsubscribes table
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
    utm_source TEXT DEFAULT NULL,
    utm_medium TEXT DEFAULT NULL,
    utm_campaign TEXT DEFAULT NULL,
    referred_by_agency_code TEXT DEFAULT NULL,
    is_demo BOOLEAN DEFAULT FALSE,
    demo_expires_at TIMESTAMPTZ DEFAULT NULL,
    website_url TEXT DEFAULT NULL,
    updated_at TIMESTAMPTZ DEFAULT now(),
    created_at TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS phone_number TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS avatar_url TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS company_name TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS logo_url TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS color_scheme JSONB DEFAULT '{}'::jsonb;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS utm_source TEXT DEFAULT NULL;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS utm_medium TEXT DEFAULT NULL;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS utm_campaign TEXT DEFAULT NULL;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS referred_by_agency_code TEXT DEFAULT NULL;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS subscription_plan TEXT DEFAULT 'Property & Lease Management';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS subscription_status TEXT DEFAULT 'active';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS active_modules TEXT[] DEFAULT ARRAY['property_lease_management']::TEXT[];
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS monthly_fee NUMERIC(10, 2) DEFAULT 0.00;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS billing_currency TEXT DEFAULT 'EUR';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS next_billing_date DATE DEFAULT NULL;

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
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS landlord_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE public.properties ALTER COLUMN landlord_id DROP NOT NULL;
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS tenant_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL;
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS title TEXT;
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS name TEXT;
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS address TEXT;
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS city TEXT;
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS default_monthly_rent NUMERIC(12,2);
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS default_deposit_amount NUMERIC(12,2);
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS currency TEXT DEFAULT 'EUR';
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS default_deposit_currency TEXT DEFAULT 'EUR';
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS default_due_day INT DEFAULT 1;
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS expenses_template JSONB DEFAULT '[]'::jsonb;
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS owner_note TEXT;
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS tax_type public.tax_type DEFAULT 'included';
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT now();
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS agency_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL;
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS landlord_phone TEXT;
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS landlord_email TEXT;
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS landlord_name TEXT;
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS tenant_name TEXT;
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS is_detailed BOOLEAN DEFAULT FALSE;
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS property_type TEXT DEFAULT 'apartment';
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS unit_number TEXT;
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS room_count TEXT;
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS area_sqm NUMERIC(10,2);
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS floor TEXT;
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS total_floors INT;
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS furnishing TEXT;
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS heating_type TEXT;
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS amenities JSONB DEFAULT '[]'::jsonb;
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS last_listing_id UUID;

CREATE TABLE IF NOT EXISTS public.listings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agency_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    directory_agency_id BIGINT DEFAULT NULL,
    managed_property_id UUID REFERENCES public.properties(id) ON DELETE SET NULL,
    external_ref TEXT DEFAULT NULL,
    title TEXT NOT NULL,
    description TEXT DEFAULT NULL,
    transaction_type TEXT NOT NULL DEFAULT 'izdavanje' CHECK (transaction_type IN ('izdavanje', 'prodaja')),
    property_type TEXT NOT NULL DEFAULT 'apartment',
    price NUMERIC(12,2) NOT NULL DEFAULT 0,
    deposit_amount NUMERIC(12,2) DEFAULT NULL,
    currency TEXT NOT NULL DEFAULT 'EUR',
    area_sqm NUMERIC(10,2) DEFAULT NULL,
    room_count TEXT DEFAULT NULL,
    floor TEXT DEFAULT NULL,
    total_floors INTEGER DEFAULT NULL,
    heating_type TEXT DEFAULT NULL,
    condition TEXT DEFAULT NULL,
    furnishing TEXT DEFAULT NULL,
    city TEXT NOT NULL DEFAULT 'Beograd',
    municipality TEXT DEFAULT NULL,
    neighborhood TEXT DEFAULT NULL,
    address TEXT DEFAULT NULL,
    latitude NUMERIC(10,7) DEFAULT NULL,
    longitude NUMERIC(10,7) DEFAULT NULL,
    amenities JSONB NOT NULL DEFAULT '[]'::jsonb,
    is_published BOOLEAN NOT NULL DEFAULT TRUE,
    listing_status TEXT NOT NULL DEFAULT 'active' CHECK (listing_status IN ('active', 'reserved', 'rented', 'sold', 'archived')),
    closed_at TIMESTAMPTZ DEFAULT NULL,
    closing_price NUMERIC(12,2) DEFAULT NULL,
    closing_notes TEXT DEFAULT NULL,
    closing_contract_id UUID,
    published_portals JSONB NOT NULL DEFAULT '["stanomer", "4zida", "halooglasi", "sasomange", "nekretnine"]'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS listings_agency_published_idx
    ON public.listings (agency_id, is_published)
    WHERE is_published = TRUE;
CREATE INDEX IF NOT EXISTS listings_managed_property_id_idx ON public.listings (managed_property_id);
CREATE INDEX IF NOT EXISTS listings_status_idx ON public.listings (listing_status);
CREATE INDEX IF NOT EXISTS listings_closing_contract_id_idx ON public.listings (closing_contract_id);
ALTER TABLE public.listings ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.listing_images (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    listing_id UUID NOT NULL REFERENCES public.listings(id) ON DELETE CASCADE,
    url TEXT NOT NULL,
    order_index INTEGER NOT NULL DEFAULT 0,
    is_cover BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS listing_images_listing_order_idx
    ON public.listing_images (listing_id, is_cover DESC, order_index ASC);
ALTER TABLE public.listing_images ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.agency_leads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agency_id TEXT NOT NULL,
    lead_type TEXT NOT NULL DEFAULT 'owner_consignment' CHECK (lead_type IN ('owner_consignment', 'viewing_request', 'general_inquiry')),
    status TEXT NOT NULL DEFAULT 'new' CHECK (status IN ('new', 'contacted', 'evaluation', 'viewing_scheduled', 'offer_made', 'contract_signed', 'converted', 'archived')),
    client_name TEXT NOT NULL,
    client_phone TEXT NOT NULL,
    client_email TEXT DEFAULT NULL,
    transaction_type TEXT DEFAULT 'prodaja' CHECK (transaction_type IN ('prodaja', 'izdavanje')),
    property_type TEXT DEFAULT 'apartment',
    location TEXT DEFAULT NULL,
    area_sqm NUMERIC(10,2) DEFAULT NULL,
    expected_price NUMERIC(12,2) DEFAULT NULL,
    currency TEXT NOT NULL DEFAULT 'EUR',
    notes TEXT DEFAULT NULL,
    listing_id UUID DEFAULT NULL REFERENCES public.listings(id) ON DELETE SET NULL,
    listing_title TEXT DEFAULT NULL,
    agent_notes TEXT DEFAULT NULL,
    comments JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS agency_leads_agency_id_idx ON public.agency_leads (agency_id);
CREATE INDEX IF NOT EXISTS agency_leads_status_idx ON public.agency_leads (status);
CREATE INDEX IF NOT EXISTS agency_leads_created_at_idx ON public.agency_leads (created_at DESC);
ALTER TABLE public.agency_leads ENABLE ROW LEVEL SECURITY;

-- RLS Policies for listings, listing_images, and agency_leads
DROP POLICY IF EXISTS "public_select_published_listings" ON public.listings;
CREATE POLICY "public_select_published_listings" ON public.listings
    FOR SELECT TO public USING (is_published = TRUE);
DROP POLICY IF EXISTS "agency_select_own_listings" ON public.listings;
CREATE POLICY "agency_select_own_listings" ON public.listings
    FOR SELECT TO authenticated USING (agency_id = auth.uid());
DROP POLICY IF EXISTS "agency_insert_own_listings" ON public.listings;
CREATE POLICY "agency_insert_own_listings" ON public.listings
    FOR INSERT TO authenticated WITH CHECK (agency_id = auth.uid());
DROP POLICY IF EXISTS "agency_update_own_listings" ON public.listings;
CREATE POLICY "agency_update_own_listings" ON public.listings
    FOR UPDATE TO authenticated USING (agency_id = auth.uid()) WITH CHECK (agency_id = auth.uid());
DROP POLICY IF EXISTS "agency_delete_own_listings" ON public.listings;
CREATE POLICY "agency_delete_own_listings" ON public.listings
    FOR DELETE TO authenticated USING (agency_id = auth.uid());

DROP POLICY IF EXISTS "public_view_published_listing_images" ON public.listing_images;
CREATE POLICY "public_view_published_listing_images" ON public.listing_images
    FOR SELECT TO public USING (EXISTS (SELECT 1 FROM public.listings l WHERE l.id = listing_images.listing_id AND l.is_published = TRUE));
DROP POLICY IF EXISTS "agency_manage_own_listing_images" ON public.listing_images;
CREATE POLICY "agency_manage_own_listing_images" ON public.listing_images
    FOR ALL TO authenticated
    USING (EXISTS (SELECT 1 FROM public.listings l WHERE l.id = listing_images.listing_id AND l.agency_id = auth.uid()))
    WITH CHECK (EXISTS (SELECT 1 FROM public.listings l WHERE l.id = listing_images.listing_id AND l.agency_id = auth.uid()));

DROP POLICY IF EXISTS "allow_anon_insert_agency_leads" ON public.agency_leads;
CREATE POLICY "allow_anon_insert_agency_leads" ON public.agency_leads
    FOR INSERT TO anon, authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "allow_agency_select_leads" ON public.agency_leads;
CREATE POLICY "allow_agency_select_leads" ON public.agency_leads
    FOR SELECT TO authenticated USING (agency_id = auth.uid()::text OR agency_id = 'demo');
DROP POLICY IF EXISTS "allow_agency_update_leads" ON public.agency_leads;
CREATE POLICY "allow_agency_update_leads" ON public.agency_leads
    FOR UPDATE TO authenticated USING (agency_id = auth.uid()::text OR agency_id = 'demo') WITH CHECK (agency_id = auth.uid()::text OR agency_id = 'demo');
DROP POLICY IF EXISTS "allow_agency_delete_leads" ON public.agency_leads;
CREATE POLICY "allow_agency_delete_leads" ON public.agency_leads
    FOR DELETE TO authenticated USING (agency_id = auth.uid()::text OR agency_id = 'demo');
GRANT INSERT ON public.agency_leads TO anon, authenticated;
GRANT SELECT, UPDATE, DELETE ON public.agency_leads TO authenticated;

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
ALTER TABLE public.contracts ADD COLUMN IF NOT EXISTS landlord_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE public.contracts ALTER COLUMN landlord_id DROP NOT NULL;
ALTER TABLE public.contracts ADD COLUMN IF NOT EXISTS tenant_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL;
ALTER TABLE public.contracts ADD COLUMN IF NOT EXISTS agency_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL;
ALTER TABLE public.contracts ADD COLUMN IF NOT EXISTS invitee_email TEXT;
ALTER TABLE public.contracts ADD COLUMN IF NOT EXISTS inviter_name TEXT;
ALTER TABLE public.contracts ADD COLUMN IF NOT EXISTS token TEXT;
ALTER TABLE public.contracts ADD COLUMN IF NOT EXISTS deposit_currency TEXT DEFAULT 'EUR';
ALTER TABLE public.contracts ADD COLUMN IF NOT EXISTS tenant_feedback TEXT;
ALTER TABLE public.contracts ADD COLUMN IF NOT EXISTS tenant_name TEXT;
ALTER TABLE public.contracts ADD COLUMN IF NOT EXISTS tenant_phone TEXT;
ALTER TABLE public.contracts ADD COLUMN IF NOT EXISTS tenant_id_number TEXT;
ALTER TABLE public.contracts ADD COLUMN IF NOT EXISTS tenant_notes TEXT;
ALTER TABLE public.contracts ADD COLUMN IF NOT EXISTS tenant_id_document_url TEXT;
ALTER TABLE public.contracts ADD COLUMN IF NOT EXISTS tenant_secondary_contacts JSONB DEFAULT '[]'::jsonb;
ALTER TABLE public.contracts ADD COLUMN IF NOT EXISTS contract_url TEXT;
ALTER TABLE public.contracts ADD COLUMN IF NOT EXISTS expenses_config JSONB DEFAULT '[]'::jsonb;
ALTER TABLE public.contracts ADD COLUMN IF NOT EXISTS termination_date DATE;
ALTER TABLE public.contracts ADD COLUMN IF NOT EXISTS termination_approved BOOLEAN DEFAULT FALSE;
ALTER TABLE public.contracts ADD COLUMN IF NOT EXISTS proposed_changes JSONB;
ALTER TABLE public.contracts ADD COLUMN IF NOT EXISTS pending_update JSONB;
ALTER TABLE public.contracts ADD COLUMN IF NOT EXISTS source_listing_id UUID REFERENCES public.listings(id) ON DELETE SET NULL;
ALTER TABLE public.contracts ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT now();
ALTER TABLE public.contracts ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT now();
CREATE INDEX IF NOT EXISTS contracts_source_listing_id_idx ON public.contracts (source_listing_id);

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
ALTER TABLE public.invitations ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT now();
ALTER TABLE public.invitations ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT now();

CREATE TABLE IF NOT EXISTS public.rent_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
    contract_id UUID REFERENCES public.contracts(id) ON DELETE SET NULL,
    landlord_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    tenant_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    period_start DATE,
    period_end DATE,
    due_date DATE NOT NULL,
    amount NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    rent_amount NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    expenses_amount NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    total_amount NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    currency TEXT NOT NULL DEFAULT 'EUR',
    status public.rent_payment_status DEFAULT 'pending',
    payment_type TEXT DEFAULT 'rent',
    payment_method TEXT DEFAULT 'bank_transfer',
    notes TEXT,
    receipt_url TEXT,
    invoice_url TEXT,
    declared_at TIMESTAMPTZ,
    paid_at TIMESTAMPTZ,
    auto_approval_at TIMESTAMPTZ,
    linked_charge_id UUID,
    dispute_reason TEXT,
    disputed_by UUID REFERENCES public.profiles(id),
    disputed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE public.rent_payments ADD COLUMN IF NOT EXISTS amount NUMERIC(12,2) DEFAULT 0.00;
ALTER TABLE public.rent_payments ADD COLUMN IF NOT EXISTS paid_at TIMESTAMPTZ;
ALTER TABLE public.rent_payments ADD COLUMN IF NOT EXISTS invoice_url TEXT;
ALTER TABLE public.rent_payments ADD COLUMN IF NOT EXISTS payment_method TEXT DEFAULT 'bank_transfer';
ALTER TABLE public.rent_payments ADD COLUMN IF NOT EXISTS linked_charge_id UUID;
ALTER TABLE public.rent_payments ADD COLUMN IF NOT EXISTS landlord_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE public.rent_payments ALTER COLUMN landlord_id DROP NOT NULL;
ALTER TABLE public.rent_payments ALTER COLUMN period_start DROP NOT NULL;
ALTER TABLE public.rent_payments ALTER COLUMN period_end DROP NOT NULL;
ALTER TABLE public.rent_payments ADD COLUMN IF NOT EXISTS tenant_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL;
ALTER TABLE public.rent_payments ADD COLUMN IF NOT EXISTS contract_id UUID REFERENCES public.contracts(id) ON DELETE SET NULL;
ALTER TABLE public.rent_payments ADD COLUMN IF NOT EXISTS agency_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL;
ALTER TABLE public.rent_payments ADD COLUMN IF NOT EXISTS receiver_type TEXT DEFAULT 'landlord';
ALTER TABLE public.rent_payments ADD COLUMN IF NOT EXISTS title TEXT;
ALTER TABLE public.rent_payments ADD COLUMN IF NOT EXISTS owner_note TEXT;
ALTER TABLE public.rent_payments ADD COLUMN IF NOT EXISTS receipt_url TEXT;
ALTER TABLE public.rent_payments ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT now();
ALTER TABLE public.rent_payments ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT now();
ALTER TABLE public.rent_payments ADD COLUMN IF NOT EXISTS declared_at TIMESTAMPTZ;
ALTER TABLE public.rent_payments ADD COLUMN IF NOT EXISTS auto_approval_at TIMESTAMPTZ;
ALTER TABLE public.rent_payments ADD COLUMN IF NOT EXISTS dispute_reason TEXT;
ALTER TABLE public.rent_payments ADD COLUMN IF NOT EXISTS disputed_by UUID REFERENCES public.profiles(id);
ALTER TABLE public.rent_payments ADD COLUMN IF NOT EXISTS disputed_at TIMESTAMPTZ;

-- Backfill amount from total_amount/rent_amount if available
UPDATE public.rent_payments 
SET amount = COALESCE(NULLIF(amount, 0), NULLIF(total_amount, 0), rent_amount, 0)
WHERE amount IS NULL OR amount = 0;

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

ALTER TABLE public.maintenance_requests ADD COLUMN IF NOT EXISTS cost_amount NUMERIC(10,2);
ALTER TABLE public.maintenance_requests ADD COLUMN IF NOT EXISTS settled_amount NUMERIC(10,2) DEFAULT 0.00;
ALTER TABLE public.maintenance_requests ADD COLUMN IF NOT EXISTS currency TEXT;
ALTER TABLE public.maintenance_requests ADD COLUMN IF NOT EXISTS paid_by TEXT;
ALTER TABLE public.maintenance_requests ADD COLUMN IF NOT EXISTS payment_date TIMESTAMPTZ;
ALTER TABLE public.maintenance_requests ADD COLUMN IF NOT EXISTS payment_status TEXT DEFAULT 'pending_review';
ALTER TABLE public.maintenance_requests ADD COLUMN IF NOT EXISTS invoice_pdf_url TEXT;
ALTER TABLE public.maintenance_requests ADD COLUMN IF NOT EXISTS rejection_reason TEXT;
ALTER TABLE public.maintenance_requests ADD COLUMN IF NOT EXISTS rejected_by UUID REFERENCES auth.users(id) ON DELETE SET NULL;
CREATE SEQUENCE IF NOT EXISTS public.maintenance_ticket_number_seq START WITH 10001;
ALTER TABLE public.maintenance_requests ADD COLUMN IF NOT EXISTS ticket_number TEXT DEFAULT ('MR-' || LPAD(nextval('public.maintenance_ticket_number_seq')::TEXT, 5, '0'));
CREATE UNIQUE INDEX IF NOT EXISTS idx_maintenance_requests_ticket_number ON public.maintenance_requests(ticket_number);

ALTER TABLE public.maintenance_requests DROP CONSTRAINT IF EXISTS maintenance_requests_priority_check;
ALTER TABLE public.maintenance_requests ADD CONSTRAINT maintenance_requests_priority_check CHECK (priority IN ('normal', 'medium', 'low', 'urgent', 'high'));

ALTER TABLE public.maintenance_requests DROP CONSTRAINT IF EXISTS maintenance_requests_paid_by_check;
ALTER TABLE public.maintenance_requests ADD CONSTRAINT maintenance_requests_paid_by_check CHECK (paid_by IS NULL OR paid_by IN ('tenant', 'landlord', 'agency'));

ALTER TABLE public.maintenance_requests DROP CONSTRAINT IF EXISTS maintenance_requests_payment_status_check;
ALTER TABLE public.maintenance_requests ADD CONSTRAINT maintenance_requests_payment_status_check CHECK (payment_status IN ('pending_review', 'pending_agency_approval', 'pending_opposite_approval', 'pending_payment', 'paid', 'rejected'));

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

CREATE TABLE IF NOT EXISTS public.maintenance_charges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    maintenance_request_id UUID NOT NULL REFERENCES public.maintenance_requests(id) ON DELETE CASCADE,
    property_id UUID NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
    created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    title TEXT,
    charge_type TEXT NOT NULL DEFAULT 'direct_charge' CHECK (charge_type IN ('direct_charge', 'agency_advance', 'reimbursement')),
    approver_role TEXT NOT NULL DEFAULT 'counterparty' CHECK (approver_role IN ('agency', 'counterparty')),
    debtor_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    creditor_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    contractor_name TEXT,
    amount NUMERIC(12,2) NOT NULL CHECK (amount >= 0),
    settled_amount NUMERIC(12,2) NOT NULL DEFAULT 0.00 CHECK (settled_amount >= 0),
    currency TEXT NOT NULL DEFAULT 'EUR',
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'declared', 'disputed', 'approved', 'rejected', 'paid')),
    contractor_payment_status TEXT CHECK (contractor_payment_status IS NULL OR contractor_payment_status IN ('unpaid', 'paid')),
    contractor_payment_date TIMESTAMPTZ,
    settlement_method TEXT CHECK (settlement_method IS NULL OR settlement_method IN ('separate_payment', 'rent_offset')),
    receipt_url TEXT,
    dispute_reason TEXT,
    rejection_reason TEXT,
    rejected_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    declared_at TIMESTAMPTZ,
    approved_at TIMESTAMPTZ,
    approved_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    paid_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.rent_payments ADD COLUMN IF NOT EXISTS linked_charge_id UUID REFERENCES public.maintenance_charges(id) ON DELETE SET NULL;

CREATE TABLE IF NOT EXISTS public.property_owners (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
    owner_type TEXT NOT NULL DEFAULT 'individual' CHECK (owner_type IN ('individual', 'company')),
    is_primary BOOLEAN NOT NULL DEFAULT false,
    ownership_percentage NUMERIC DEFAULT 100,
    first_name TEXT,
    last_name TEXT,
    phone TEXT,
    secondary_contact TEXT,
    email TEXT,
    id_document_number TEXT,
    id_details TEXT,
    company_name TEXT,
    registered_address TEXT,
    pib TEXT,
    registration_number TEXT,
    representative_name TEXT,
    representative_id_number TEXT,
    representative_id_details TEXT,
    documents JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_property_owners_property_id ON public.property_owners(property_id);
CREATE INDEX IF NOT EXISTS idx_property_owners_email ON public.property_owners(LOWER(email));


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
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    payment_id UUID REFERENCES public.rent_payments(id) ON DELETE SET NULL,
    type TEXT NOT NULL DEFAULT 'system_event',
    action_type TEXT,
    description TEXT,
    entity_type TEXT,
    entity_id UUID,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE public.activity_logs ADD COLUMN IF NOT EXISTS type TEXT DEFAULT 'system_event';
ALTER TABLE public.activity_logs ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}'::jsonb;
ALTER TABLE public.activity_logs ADD COLUMN IF NOT EXISTS action_type TEXT;
ALTER TABLE public.activity_logs ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE public.activity_logs ADD COLUMN IF NOT EXISTS entity_type TEXT;
ALTER TABLE public.activity_logs ADD COLUMN IF NOT EXISTS entity_id UUID;
ALTER TABLE public.activity_logs ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE;
DO $$ BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'activity_logs' AND column_name = 'action_type' AND is_nullable = 'NO'
    ) THEN
        ALTER TABLE public.activity_logs ALTER COLUMN action_type DROP NOT NULL;
    END IF;
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'activity_logs' AND column_name = 'description' AND is_nullable = 'NO'
    ) THEN
        ALTER TABLE public.activity_logs ALTER COLUMN description DROP NOT NULL;
    END IF;
END $$;

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
DROP POLICY IF EXISTS "profiles_select_policy" ON public.profiles;
CREATE POLICY "profiles_select_policy" ON public.profiles FOR SELECT TO public USING (true);

DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
CREATE POLICY "Users can insert their own profile" ON public.profiles FOR INSERT TO authenticated WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
CREATE POLICY "Users can update their own profile" ON public.profiles FOR UPDATE TO authenticated USING (auth.uid() = id);

-- 3.5 HELPER FUNCTIONS FOR RLS (SECURITY DEFINER)
-- Prevents RLS circular recursion loops between properties, invitations, and rent_payments
-- Uses dynamic SQL (EXECUTE) to prevent compile-time relation dependencies
CREATE OR REPLACE FUNCTION public.is_invited_to_property(check_property_id UUID, check_email TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_result BOOLEAN := FALSE;
BEGIN
  IF to_regclass('public.invitations') IS NULL THEN
    RETURN FALSE;
  END IF;
  EXECUTE 'SELECT EXISTS (
    SELECT 1 FROM public.invitations
    WHERE property_id = $1
      AND LOWER(invitee_email) = LOWER(COALESCE($2, ''''))
  )' INTO v_result USING check_property_id, check_email;
  RETURN v_result;
END;
$$;

CREATE OR REPLACE FUNCTION public.is_agency_of_property(check_property_id UUID, check_user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_result BOOLEAN := FALSE;
BEGIN
  IF to_regclass('public.properties') IS NULL THEN
    RETURN FALSE;
  END IF;
  EXECUTE 'SELECT EXISTS (
    SELECT 1 FROM public.properties
    WHERE id = $1
      AND public.is_agency_member(agency_id, $2)
  )' INTO v_result USING check_property_id, check_user_id;
  RETURN v_result;
END;
$$;

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
    USING (landlord_id = auth.uid() OR tenant_id = auth.uid() OR agency_id = auth.uid() OR public.is_agency_of_property(property_id, auth.uid()) OR (invitee_email IS NOT NULL AND LOWER(invitee_email) = LOWER(COALESCE(auth.jwt()->>'email', ''))) OR (token IS NOT NULL));

DROP POLICY IF EXISTS "Landlords can insert contracts" ON public.contracts;
DROP POLICY IF EXISTS "contracts_insert_policy" ON public.contracts;
CREATE POLICY "contracts_insert_policy" ON public.contracts FOR INSERT TO authenticated
    WITH CHECK (landlord_id = auth.uid() OR agency_id = auth.uid() OR public.is_agency_of_property(property_id, auth.uid()));

DROP POLICY IF EXISTS "Users can update relevant contracts" ON public.contracts;
DROP POLICY IF EXISTS "contracts_update_policy" ON public.contracts;
CREATE POLICY "contracts_update_policy" ON public.contracts FOR UPDATE TO authenticated
    USING (landlord_id = auth.uid() OR agency_id = auth.uid() OR public.is_agency_of_property(property_id, auth.uid()) OR tenant_id = auth.uid() OR tenant_id IS NULL OR (invitee_email IS NOT NULL AND LOWER(invitee_email) = LOWER(COALESCE(auth.jwt()->>'email', ''))));

DROP POLICY IF EXISTS "contracts_delete_policy" ON public.contracts;
CREATE POLICY "contracts_delete_policy" ON public.contracts FOR DELETE TO authenticated
    USING (landlord_id = auth.uid() OR agency_id = auth.uid() OR public.is_agency_of_property(property_id, auth.uid()));

DROP POLICY IF EXISTS "Users can view invitations" ON public.invitations;
CREATE POLICY "Users can view invitations" ON public.invitations FOR SELECT TO authenticated USING (inviter_id = auth.uid() OR public.is_agency_of_property(property_id, auth.uid()) OR LOWER(invitee_email) = LOWER(COALESCE(auth.jwt()->>'email', '')) OR (token IS NOT NULL));

DROP POLICY IF EXISTS "Users can insert invitations" ON public.invitations;
CREATE POLICY "Users can insert invitations" ON public.invitations FOR INSERT TO authenticated WITH CHECK (inviter_id = auth.uid() OR public.is_agency_of_property(property_id, auth.uid()));

DROP POLICY IF EXISTS "Users can view rent payments" ON public.rent_payments;
DROP POLICY IF EXISTS "rent_payments_select_policy" ON public.rent_payments;
DROP POLICY IF EXISTS "landlord_select_rent_payments" ON public.rent_payments;
DROP POLICY IF EXISTS "tenant_select_rent_payments" ON public.rent_payments;

CREATE POLICY "Users can view rent payments" ON public.rent_payments 
FOR SELECT TO authenticated 
USING (
    tenant_id = auth.uid() 
    OR public.is_agency_of_property(property_id, auth.uid())
    OR EXISTS (
        SELECT 1 FROM public.properties p 
        WHERE p.id = rent_payments.property_id 
          AND (p.landlord_id = auth.uid() OR p.tenant_id = auth.uid() OR p.agency_id = auth.uid())
    )
);

DROP POLICY IF EXISTS "Landlords and tenants can update rent payments" ON public.rent_payments;
DROP POLICY IF EXISTS "rent_payments_update_policy" ON public.rent_payments;
DROP POLICY IF EXISTS "landlord_update_rent_payments" ON public.rent_payments;
DROP POLICY IF EXISTS "tenant_update_rent_payments" ON public.rent_payments;

CREATE POLICY "Landlords and tenants can update rent payments" ON public.rent_payments 
FOR UPDATE TO authenticated 
USING (
    tenant_id = auth.uid() 
    OR public.is_agency_of_property(property_id, auth.uid())
    OR EXISTS (
        SELECT 1 FROM public.properties p 
        WHERE p.id = rent_payments.property_id 
          AND (p.landlord_id = auth.uid() OR p.tenant_id = auth.uid() OR p.agency_id = auth.uid())
    )
);

DROP POLICY IF EXISTS "Landlords and agencies can insert rent payments" ON public.rent_payments;
DROP POLICY IF EXISTS "rent_payments_insert_policy" ON public.rent_payments;

CREATE POLICY "Landlords and agencies can insert rent payments" ON public.rent_payments 
FOR INSERT TO authenticated 
WITH CHECK (
    public.is_agency_of_property(property_id, auth.uid())
    OR EXISTS (
        SELECT 1 FROM public.properties p 
        WHERE p.id = rent_payments.property_id 
          AND (p.landlord_id = auth.uid() OR p.agency_id = auth.uid())
    )
);

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
    USING (
        CASE 
            WHEN type = 'manual_note' THEN
                (user_id = auth.uid() OR public.is_agency_of_property(property_id, auth.uid()) OR EXISTS (SELECT 1 FROM public.properties p WHERE p.id = activity_logs.property_id AND p.agency_id = auth.uid()))
            ELSE
                (user_id = auth.uid() OR public.is_agency_of_property(property_id, auth.uid()) OR EXISTS (SELECT 1 FROM public.properties p WHERE p.id = activity_logs.property_id AND (p.landlord_id = auth.uid() OR p.tenant_id = auth.uid() OR p.agency_id = auth.uid())))
        END
    );

DROP POLICY IF EXISTS "activity_logs_insert_policy" ON public.activity_logs;
CREATE POLICY "activity_logs_insert_policy" ON public.activity_logs FOR INSERT TO authenticated
    WITH CHECK (
        CASE 
            WHEN type = 'manual_note' THEN
                (public.is_agency_of_property(property_id, auth.uid()) OR EXISTS (SELECT 1 FROM public.properties p WHERE p.id = activity_logs.property_id AND p.agency_id = auth.uid()) OR user_id = auth.uid())
            ELSE true
        END
    );

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

-- Maintenance Charges RLS
ALTER TABLE public.maintenance_charges ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "maintenance_charges_select_policy" ON public.maintenance_charges;
CREATE POLICY "maintenance_charges_select_policy" ON public.maintenance_charges FOR SELECT TO authenticated
    USING (EXISTS (SELECT 1 FROM public.properties p WHERE p.id = maintenance_charges.property_id AND (p.landlord_id = auth.uid() OR p.tenant_id = auth.uid() OR p.agency_id = auth.uid() OR public.is_agency_of_property(p.id, auth.uid()))));

DROP POLICY IF EXISTS "maintenance_charges_insert_policy" ON public.maintenance_charges;
CREATE POLICY "maintenance_charges_insert_policy" ON public.maintenance_charges FOR INSERT TO authenticated
    WITH CHECK (EXISTS (SELECT 1 FROM public.properties p WHERE p.id = property_id AND (p.landlord_id = auth.uid() OR p.tenant_id = auth.uid() OR p.agency_id = auth.uid() OR public.is_agency_of_property(p.id, auth.uid()))));

DROP POLICY IF EXISTS "maintenance_charges_update_policy" ON public.maintenance_charges;
CREATE POLICY "maintenance_charges_update_policy" ON public.maintenance_charges FOR UPDATE TO authenticated
    USING (EXISTS (SELECT 1 FROM public.properties p WHERE p.id = maintenance_charges.property_id AND (p.landlord_id = auth.uid() OR p.tenant_id = auth.uid() OR p.agency_id = auth.uid() OR public.is_agency_of_property(p.id, auth.uid()))));

DROP POLICY IF EXISTS "maintenance_charges_delete_policy" ON public.maintenance_charges;
CREATE POLICY "maintenance_charges_delete_policy" ON public.maintenance_charges FOR DELETE TO authenticated
    USING (EXISTS (SELECT 1 FROM public.properties p WHERE p.id = maintenance_charges.property_id AND (p.landlord_id = auth.uid() OR p.agency_id = auth.uid() OR public.is_agency_of_property(p.id, auth.uid()))));

-- Property Owners RLS
ALTER TABLE public.property_owners ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "agency_manage_property_owners" ON public.property_owners;
CREATE POLICY "agency_manage_property_owners" ON public.property_owners
    FOR ALL TO authenticated
    USING (EXISTS (SELECT 1 FROM public.properties p WHERE p.id = property_owners.property_id AND p.agency_id = auth.uid()));

DROP POLICY IF EXISTS "landlords_view_property_owners" ON public.property_owners;
CREATE POLICY "landlords_view_property_owners" ON public.property_owners
    FOR SELECT TO authenticated
    USING (LOWER(email) = LOWER(auth.jwt()->>'email') OR EXISTS (SELECT 1 FROM public.properties p WHERE p.id = property_owners.property_id AND p.landlord_id = auth.uid()));

-- 5. REALTIME PUBLICATION & REPLICA IDENTITY FOR PUBLIC TABLES
ALTER TABLE public.properties REPLICA IDENTITY FULL;
ALTER TABLE public.property_owners REPLICA IDENTITY FULL;
ALTER TABLE public.contracts REPLICA IDENTITY FULL;
ALTER TABLE public.rent_payments REPLICA IDENTITY FULL;
ALTER TABLE public.maintenance_requests REPLICA IDENTITY FULL;
ALTER TABLE public.maintenance_charges REPLICA IDENTITY FULL;
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
    IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'maintenance_charges') THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.maintenance_charges;
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

    IF v_user_phone IS NULL OR v_user_phone = '' THEN
        v_user_phone := COALESCE(auth.jwt()->>'phone', '');
    END IF;

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
    -- 1. First check contracts table (tenant contract invitations always live in public.contracts)
    SELECT (to_jsonb(c.*) || jsonb_build_object(
        'type', 'contract',
        'active_contract', to_jsonb(c.*),
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
    INTO v_contract_json
    FROM public.contracts c
    JOIN public.properties p ON p.id = c.property_id
    WHERE c.token = p_token
      AND (c.status IN ('pending', 'negotiating', 'revision_requested') OR (c.status = 'active' AND c.tenant_id IS NULL))
    ORDER BY c.created_at DESC
    LIMIT 1;

    -- 2. Next check invitations table (landlord ownership invitations or standalone invitations)
    SELECT (to_jsonb(i.*) || jsonb_build_object(
        'type', CASE WHEN i.target_role = 'landlord' THEN 'landlord_ownership' ELSE COALESCE(v_contract_json->>'type', 'invitation') END,
        'active_contract', COALESCE(
            v_contract_json,
            (
                SELECT to_jsonb(c2.*)
                FROM public.contracts c2
                WHERE (c2.id = i.contract_id OR c2.property_id = i.property_id)
                  AND c2.status IN ('pending', 'negotiating', 'active', 'revision_requested')
                ORDER BY c2.created_at DESC
                LIMIT 1
            )
        ),
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
      AND (i.expires_at IS NULL OR i.expires_at > now());

    IF v_invite_json IS NOT NULL AND (v_invite_json->>'target_role' = 'landlord' OR v_contract_json IS NULL) THEN
        RETURN v_invite_json;
    END IF;

    IF v_contract_json IS NOT NULL THEN
        RETURN v_contract_json;
    END IF;

    RETURN v_invite_json;
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
DECLARE
    user_role_val public.user_role := 'landlord';
    user_role_text TEXT := 'landlord';
BEGIN
    IF NEW.raw_user_meta_data->>'role' IS NOT NULL AND NEW.raw_user_meta_data->>'role' IN ('landlord', 'tenant', 'agency') THEN
        user_role_val := (NEW.raw_user_meta_data->>'role')::public.user_role;
        user_role_text := NEW.raw_user_meta_data->>'role';
    END IF;

    INSERT INTO public.profiles (
        id, 
        full_name, 
        role, 
        email, 
        active_role,
        utm_source,
        utm_medium,
        utm_campaign
    )
    VALUES (
        NEW.id,
        COALESCE(NULLIF(NEW.raw_user_meta_data->>'full_name', ''), NEW.email, 'Yeni Kullanıcı'),
        user_role_val,
        NEW.email,
        user_role_text,
        NEW.raw_user_meta_data->>'utm_source',
        NEW.raw_user_meta_data->>'utm_medium',
        NEW.raw_user_meta_data->>'utm_campaign'
    )
    ON CONFLICT (id) DO UPDATE
    SET full_name = COALESCE(EXCLUDED.full_name, public.profiles.full_name),
        email = COALESCE(EXCLUDED.email, public.profiles.email),
        utm_source = COALESCE(EXCLUDED.utm_source, public.profiles.utm_source),
        utm_medium = COALESCE(EXCLUDED.utm_medium, public.profiles.utm_medium),
        utm_campaign = COALESCE(EXCLUDED.utm_campaign, public.profiles.utm_campaign);
    RETURN NEW;
EXCEPTION WHEN OTHERS THEN
    -- Fallback insertion if meta_data parsing fails
    INSERT INTO public.profiles (id, full_name, role, email, active_role)
    VALUES (NEW.id, COALESCE(NEW.email, 'Yeni Kullanıcı'), 'landlord', NEW.email, 'landlord')
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- BACKFILL profiles for any auth.users missing a profile record
INSERT INTO public.profiles (id, full_name, role, email, active_role)
SELECT 
    au.id, 
    COALESCE(au.raw_user_meta_data->>'full_name', au.email, 'Kullanıcı'),
    'landlord'::public.user_role,
    au.email,
    'landlord'
FROM auth.users au
LEFT JOIN public.profiles p ON p.id = au.id
WHERE p.id IS NULL
ON CONFLICT (id) DO NOTHING;

-- 7. STORAGE BUCKETS SETUP
INSERT INTO storage.buckets (id, name, public) VALUES ('property-photos', 'property-photos', true) ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('rent-receipts', 'rent-receipts', true) ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('maintenance', 'maintenance', true) ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('maintenance-photos', 'maintenance-photos', true) ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('contract-documents', 'contract-documents', false) ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('contracts', 'contracts', false) ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('invoices', 'invoices', true) ON CONFLICT (id) DO NOTHING;

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

-- maintenance bucket
DROP POLICY IF EXISTS "maintenance_select_policy" ON storage.objects;
CREATE POLICY "maintenance_select_policy"
  ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id = 'maintenance');

DROP POLICY IF EXISTS "maintenance_insert_policy" ON storage.objects;
CREATE POLICY "maintenance_insert_policy"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'maintenance' AND auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "maintenance_update_policy" ON storage.objects;
CREATE POLICY "maintenance_update_policy"
  ON storage.objects FOR UPDATE TO authenticated
  USING (bucket_id = 'maintenance' AND auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "maintenance_delete_policy" ON storage.objects;
CREATE POLICY "maintenance_delete_policy"
  ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'maintenance' AND auth.uid() IS NOT NULL);

-- maintenance-photos bucket
DROP POLICY IF EXISTS "maintenance_photos_select_policy"  ON storage.objects;
CREATE POLICY "maintenance_photos_select_policy"
  ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id = 'maintenance-photos');

DROP POLICY IF EXISTS "maintenance_photos_insert_policy"  ON storage.objects;
CREATE POLICY "maintenance_photos_insert_policy"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'maintenance-photos' AND auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "maintenance_photos_update_policy"  ON storage.objects;
CREATE POLICY "maintenance_photos_update_policy"
  ON storage.objects FOR UPDATE TO authenticated
  USING (bucket_id = 'maintenance-photos' AND auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "maintenance_photos_delete_policy"  ON storage.objects;
CREATE POLICY "maintenance_photos_delete_policy"
  ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'maintenance-photos' AND auth.uid() IS NOT NULL);

-- invoices bucket
DROP POLICY IF EXISTS "invoices_select_policy" ON storage.objects;
CREATE POLICY "invoices_select_policy"
  ON storage.objects FOR SELECT TO authenticated
  USING (
    bucket_id = 'invoices' AND (
      (storage.foldername(name))[1] = auth.uid()::text
      OR EXISTS (
        SELECT 1 FROM public.properties p
        WHERE p.id::text = (storage.foldername(name))[1]
          AND (
            p.landlord_id = auth.uid() 
            OR p.tenant_id = auth.uid() 
            OR p.agency_id = auth.uid() 
            OR public.is_agency_of_property(p.id, auth.uid())
          )
      )
      OR EXISTS (
        SELECT 1 FROM public.contracts c
        WHERE (c.property_id::text = (storage.foldername(name))[1] OR c.tenant_id = auth.uid())
          AND (c.tenant_id = auth.uid() OR c.landlord_id = auth.uid())
      )
    )
  );

DROP POLICY IF EXISTS "invoices_insert_policy" ON storage.objects;
CREATE POLICY "invoices_insert_policy"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'invoices' AND (
      (storage.foldername(name))[1] = auth.uid()::text
      OR EXISTS (
        SELECT 1 FROM public.properties p
        WHERE p.id::text = (storage.foldername(name))[1]
          AND (
            p.landlord_id = auth.uid() 
            OR p.tenant_id = auth.uid() 
            OR p.agency_id = auth.uid() 
            OR public.is_agency_of_property(p.id, auth.uid())
          )
      )
      OR EXISTS (
        SELECT 1 FROM public.contracts c
        WHERE c.property_id::text = (storage.foldername(name))[1]
          AND c.tenant_id = auth.uid()
      )
    )
  );

DROP POLICY IF EXISTS "invoices_update_policy" ON storage.objects;
CREATE POLICY "invoices_update_policy"
  ON storage.objects FOR UPDATE TO authenticated
  USING (
    bucket_id = 'invoices' AND (
      (storage.foldername(name))[1] = auth.uid()::text
      OR EXISTS (
        SELECT 1 FROM public.properties p
        WHERE p.id::text = (storage.foldername(name))[1]
          AND (
            p.landlord_id = auth.uid() 
            OR p.tenant_id = auth.uid() 
            OR p.agency_id = auth.uid() 
            OR public.is_agency_of_property(p.id, auth.uid())
          )
      )
    )
  );

DROP POLICY IF EXISTS "invoices_delete_policy" ON storage.objects;
CREATE POLICY "invoices_delete_policy"
  ON storage.objects FOR DELETE TO authenticated
  USING (
    bucket_id = 'invoices' AND (
      (storage.foldername(name))[1] = auth.uid()::text
      OR EXISTS (
        SELECT 1 FROM public.properties p
        WHERE p.id::text = (storage.foldername(name))[1]
          AND (
            p.landlord_id = auth.uid() 
            OR p.tenant_id = auth.uid() 
            OR p.agency_id = auth.uid() 
            OR public.is_agency_of_property(p.id, auth.uid())
          )
      )
    )
  );

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

-- 9. CONTRACT NEGOTIATION FUNCTIONS
ALTER TYPE public.contract_status ADD VALUE IF NOT EXISTS 'revision_requested';
ALTER TYPE public.contract_status ADD VALUE IF NOT EXISTS 'termination_requested';

CREATE OR REPLACE FUNCTION public.propose_contract_changes(
  p_contract_id UUID,
  p_changes JSONB
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_current_status TEXT;
  v_landlord_id UUID;
  v_tenant_id UUID;
  v_agency_id UUID;
BEGIN
  SELECT c.status::text, c.landlord_id, c.tenant_id, COALESCE(c.agency_id, p.agency_id)
  INTO v_current_status, v_landlord_id, v_tenant_id, v_agency_id
  FROM contracts c
  LEFT JOIN properties p ON p.id = c.property_id
  WHERE c.id = p_contract_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Contract not found';
  END IF;

  IF auth.uid() NOT IN (v_landlord_id, v_tenant_id, v_agency_id) AND (v_agency_id IS NULL OR auth.uid() <> v_agency_id) THEN
    RAISE EXCEPTION 'Unauthorized: Only landlord, tenant, or managing agency can propose terms/counter-offers';
  END IF;

  IF (auth.uid() = v_landlord_id OR auth.uid() = v_agency_id) AND (v_current_status = 'negotiating' OR v_current_status = 'pending') THEN
    UPDATE contracts
    SET
      monthly_rent     = COALESCE((p_changes->>'monthly_rent')::NUMERIC, monthly_rent),
      currency         = COALESCE(p_changes->>'currency', currency),
      deposit_amount   = COALESCE((p_changes->>'deposit_amount')::NUMERIC, deposit_amount),
      deposit_currency = COALESCE(p_changes->>'deposit_currency', p_changes->>'currency', deposit_currency),
      due_day          = COALESCE((p_changes->>'due_day')::INTEGER, due_day),
      start_date       = COALESCE((p_changes->>'start_date')::TIMESTAMPTZ, start_date),
      end_date         = COALESCE((p_changes->>'end_date')::TIMESTAMPTZ, end_date),
      expenses_config  = COALESCE(p_changes->'expenses_config', expenses_config),
      tenant_feedback  = NULL,
      proposed_changes = NULL,
      proposed_by      = NULL,
      status           = 'pending'::public.contract_status,
      updated_at       = now()
    WHERE id = p_contract_id;
  ELSE
    UPDATE contracts
    SET
      proposed_changes = p_changes,
      proposed_by      = auth.uid(),
      status           = 'revision_requested'::public.contract_status,
      updated_at       = now()
    WHERE id = p_contract_id;
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.accept_proposed_changes(
  p_contract_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_landlord_id UUID;
  v_tenant_id UUID;
  v_agency_id UUID;
  v_proposed_by UUID;
  v_changes JSONB;
  v_current_end_date TIMESTAMPTZ;
  v_prev_status TEXT;
BEGIN
  SELECT c.landlord_id, c.tenant_id, COALESCE(c.agency_id, p.agency_id), c.proposed_by, c.proposed_changes, c.end_date, c.status::text
  INTO v_landlord_id, v_tenant_id, v_agency_id, v_proposed_by, v_changes, v_current_end_date, v_prev_status
  FROM contracts c
  LEFT JOIN properties p ON p.id = c.property_id
  WHERE c.id = p_contract_id AND c.status IN ('revision_requested', 'termination_requested');

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Contract not found or not in a pending state';
  END IF;

  IF auth.uid() NOT IN (v_landlord_id, v_tenant_id, v_agency_id) AND (v_agency_id IS NULL OR auth.uid() <> v_agency_id) THEN
    RAISE EXCEPTION 'Only participants can accept proposed changes';
  END IF;

  IF auth.uid() = v_proposed_by THEN
    RAISE EXCEPTION 'You cannot accept your own proposed changes';
  END IF;

  IF v_changes IS NULL THEN
    RAISE EXCEPTION 'No proposed changes found';
  END IF;

  IF v_changes ? 'is_termination' AND (v_changes->>'is_termination')::boolean = true THEN
    UPDATE contracts
    SET
      end_date = (v_changes->>'new_end_date')::timestamptz,
      status = 'active',
      termination_approved = true,
      proposed_changes = NULL,
      proposed_by = NULL,
      updated_at = now()
    WHERE id = p_contract_id;
  ELSE
    UPDATE contracts
    SET
      monthly_rent      = COALESCE((v_changes->>'monthly_rent')::numeric,         monthly_rent),
      deposit_amount    = COALESCE((v_changes->>'deposit_amount')::numeric,       deposit_amount),
      due_day           = COALESCE((v_changes->>'due_day')::integer,              due_day),
      currency          = COALESCE(v_changes->>'currency',                         currency),
      start_date        = COALESCE((v_changes->>'start_date')::timestamptz,       start_date),
      end_date          = COALESCE((v_changes->>'end_date')::timestamptz,         end_date),
      tax_type          = COALESCE((v_changes->>'tax_type')::public.tax_type,     tax_type),
      expenses_config   = COALESCE(v_changes->'expenses_config',                  expenses_config),
      proposed_changes  = NULL,
      proposed_by       = NULL,
      status            = CASE 
                            WHEN v_tenant_id IS NOT NULL THEN 'active'::public.contract_status
                            ELSE 'pending'::public.contract_status
                          END,
      updated_at        = now()
    WHERE id = p_contract_id;
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.decline_proposed_changes(
  p_contract_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_landlord_id UUID;
  v_tenant_id UUID;
  v_agency_id UUID;
  v_proposed_by UUID;
  v_current_status TEXT;
BEGIN
  SELECT c.landlord_id, c.tenant_id, COALESCE(c.agency_id, p.agency_id), c.proposed_by, c.status::text
  INTO v_landlord_id, v_tenant_id, v_agency_id, v_proposed_by, v_current_status
  FROM contracts c
  LEFT JOIN properties p ON p.id = c.property_id
  WHERE c.id = p_contract_id AND c.status IN ('revision_requested', 'negotiating', 'termination_requested');

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Contract not found or not in a negotiable state';
  END IF;

  IF auth.uid() NOT IN (v_landlord_id, v_tenant_id, v_agency_id) AND (v_agency_id IS NULL OR auth.uid() <> v_agency_id) THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  UPDATE contracts
  SET
    proposed_changes = NULL,
    proposed_by      = NULL,
    tenant_feedback  = NULL,
    status           = CASE 
                        WHEN v_current_status = 'termination_requested' THEN 'active'::public.contract_status
                        WHEN v_tenant_id IS NOT NULL THEN 'active'::public.contract_status
                        ELSE 'pending'::public.contract_status
                      END,
    updated_at       = now()
  WHERE id = p_contract_id;
END;
$$;

-- 10. GENERATE MISSING RENT PAYMENTS (STRICT DEDUPLICATION)
CREATE OR REPLACE FUNCTION public.generate_missing_rent_payments(p_property_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_active_contract RECORD;
  v_start_date DATE;
  v_end_date DATE;
  v_current_date DATE;
  v_due_day INTEGER;
  v_expense JSONB;
  v_exp_name TEXT;
  v_exp_amount NUMERIC;
  v_exp_receiver TEXT;
  v_exists BOOLEAN;
BEGIN
  SELECT * INTO v_active_contract
  FROM contracts
  WHERE property_id = p_property_id AND status = 'active'
    AND (start_date IS NULL OR start_date <= CURRENT_DATE)
  ORDER BY 
    CASE 
      WHEN start_date <= CURRENT_DATE AND (end_date IS NULL OR end_date >= CURRENT_DATE) THEN 1
      WHEN start_date <= CURRENT_DATE THEN 2
      ELSE 3
    END,
    start_date DESC NULLS LAST,
    updated_at DESC
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN;
  END IF;

  v_due_day := COALESCE(v_active_contract.due_day, 1);
  v_start_date := (date_trunc('month', COALESCE(v_active_contract.start_date::DATE, CURRENT_DATE)) + (v_due_day - 1) * INTERVAL '1 day')::DATE;
  v_end_date := COALESCE(v_active_contract.end_date::DATE, (v_start_date + INTERVAL '1 year')::DATE);

  DELETE FROM public.rent_payments p1
  USING public.rent_payments p2
  WHERE p1.property_id = p_property_id
    AND p1.property_id = p2.property_id
    AND LOWER(TRIM(p1.title)) = LOWER(TRIM(p2.title))
    AND date_trunc('month', p1.due_date) = date_trunc('month', p2.due_date)
    AND p1.status = 'pending'
    AND (
      p2.status IN ('paid', 'declared')
      OR (p2.status = 'pending' AND p1.id > p2.id)
    );

  v_current_date := v_start_date;
  WHILE v_current_date <= v_end_date AND v_current_date <= (date_trunc('month', CURRENT_DATE + INTERVAL '1 month') + (v_due_day - 1) * INTERVAL '1 day')::DATE LOOP
    
    SELECT EXISTS (
      SELECT 1 FROM public.rent_payments
      WHERE property_id = p_property_id
        AND LOWER(TRIM(title)) = 'kira'
        AND date_trunc('month', due_date) = date_trunc('month', v_current_date)
    ) INTO v_exists;

    IF NOT v_exists THEN
      INSERT INTO public.rent_payments (
        property_id, contract_id, landlord_id, tenant_id, agency_id,
        amount, currency, due_date, status, title, receiver_type
      )
      VALUES (
        p_property_id,
        v_active_contract.id,
        v_active_contract.landlord_id,
        v_active_contract.tenant_id,
        v_active_contract.agency_id,
        v_active_contract.monthly_rent,
        v_active_contract.currency,
        v_current_date,
        'pending',
        'Kira',
        'owner'
      );
    END IF;

    IF v_active_contract.expenses_config IS NOT NULL AND jsonb_array_length(v_active_contract.expenses_config) > 0 THEN
      FOR v_expense IN SELECT jsonb_array_elements(v_active_contract.expenses_config)
      LOOP
        v_exp_name := TRIM(v_expense->>'name');
        v_exp_amount := (v_expense->>'amount')::NUMERIC;
        v_exp_receiver := v_expense->>'receiver';

        IF v_exp_name IS NOT NULL AND v_exp_receiver = 'owner' THEN
          SELECT EXISTS (
            SELECT 1 FROM public.rent_payments
            WHERE property_id = p_property_id
              AND LOWER(TRIM(title)) = LOWER(v_exp_name)
              AND date_trunc('month', due_date) = date_trunc('month', v_current_date)
          ) INTO v_exists;

          IF NOT v_exists THEN
            INSERT INTO public.rent_payments (
              property_id, contract_id, landlord_id, tenant_id, agency_id,
              amount, currency, due_date, status, title, receiver_type
            )
            VALUES (
              p_property_id,
              v_active_contract.id,
              v_active_contract.landlord_id,
              v_active_contract.tenant_id,
              v_active_contract.agency_id,
              COALESCE(v_exp_amount, 0),
              v_active_contract.currency,
              v_current_date,
              'pending',
              v_exp_name,
              'owner'
            );
          END IF;
        END IF;
      END LOOP;
    END IF;

    v_current_date := (date_trunc('month', v_current_date + INTERVAL '1.5 month') + (v_due_day - 1) * INTERVAL '1 day')::DATE;
  END LOOP;
END;
$$;

-- agency_demo_requests table & RLS
CREATE TABLE IF NOT EXISTS public.agency_demo_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agency_name TEXT NOT NULL,
    email TEXT NOT NULL,
    website TEXT,
    phone_number TEXT,
    special_requests TEXT,
    status TEXT DEFAULT 'pending',
    verification_token UUID DEFAULT gen_random_uuid(),
    is_email_verified BOOLEAN DEFAULT FALSE,
    token_expires_at TIMESTAMPTZ DEFAULT (now() + interval '24 hours'),
    utm_source TEXT DEFAULT NULL,
    utm_medium TEXT DEFAULT NULL,
    utm_campaign TEXT DEFAULT NULL,
    selected_modules TEXT[] DEFAULT ARRAY['portfolio_distribution', 'property_lease_management']::TEXT[],
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.agency_demo_requests ADD COLUMN IF NOT EXISTS verification_token UUID DEFAULT gen_random_uuid();
ALTER TABLE public.agency_demo_requests ADD COLUMN IF NOT EXISTS is_email_verified BOOLEAN DEFAULT FALSE;
ALTER TABLE public.agency_demo_requests ADD COLUMN IF NOT EXISTS token_expires_at TIMESTAMPTZ DEFAULT (now() + interval '24 hours');
ALTER TABLE public.agency_demo_requests ADD COLUMN IF NOT EXISTS utm_source TEXT DEFAULT NULL;
ALTER TABLE public.agency_demo_requests ADD COLUMN IF NOT EXISTS utm_medium TEXT DEFAULT NULL;
ALTER TABLE public.agency_demo_requests ADD COLUMN IF NOT EXISTS utm_campaign TEXT DEFAULT NULL;
ALTER TABLE public.agency_demo_requests ADD COLUMN IF NOT EXISTS selected_modules TEXT[] DEFAULT ARRAY['portfolio_distribution', 'property_lease_management']::TEXT[];

ALTER TABLE public.agency_demo_requests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "agency_demo_requests_insert_policy" ON public.agency_demo_requests;
CREATE POLICY "agency_demo_requests_insert_policy" ON public.agency_demo_requests
    FOR INSERT TO public WITH CHECK (true);

DROP POLICY IF EXISTS "agency_demo_requests_select_policy" ON public.agency_demo_requests;
CREATE POLICY "agency_demo_requests_select_policy" ON public.agency_demo_requests
    FOR SELECT TO public USING (true);

CREATE OR REPLACE FUNCTION public.verify_agency_demo_token(p_token UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_request RECORD;
BEGIN
    SELECT * INTO v_request
    FROM public.agency_demo_requests
    WHERE verification_token = p_token;

    IF v_request IS NULL THEN
        RETURN jsonb_build_object('success', false, 'message', 'Geçersiz veya bulunamayan doğrulama kodu.');
    END IF;

    IF v_request.token_expires_at < now() THEN
        RETURN jsonb_build_object('success', false, 'message', 'Doğrulama bağlantısının süresi dolmuş.');
    END IF;

    IF v_request.is_email_verified THEN
        RETURN jsonb_build_object('success', true, 'already_verified', true, 'message', 'E-posta adresi zaten doğrulanmış.');
    END IF;

    UPDATE public.agency_demo_requests
    SET is_email_verified = TRUE,
        status = 'email_verified',
        updated_at = now()
    WHERE id = v_request.id;

    RETURN jsonb_build_object('success', true, 'message', 'E-posta adresiniz başarıyla doğrulandı.');
END;
$$;

GRANT EXECUTE ON FUNCTION public.verify_agency_demo_token(UUID) TO anon, authenticated;

-- EMAIL_UNSUBSCRIBES TABLE (2026-08-13)
CREATE TABLE IF NOT EXISTS public.email_unsubscribes (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email           TEXT NOT NULL,
    unsubscribed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    source          TEXT DEFAULT 'unsubscribe_page',
    ip_address      TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS email_unsubscribes_email_idx
    ON public.email_unsubscribes (lower(email));

ALTER TABLE public.email_unsubscribes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "email_unsubscribes_insert_policy" ON public.email_unsubscribes;
CREATE POLICY "email_unsubscribes_insert_policy" ON public.email_unsubscribes
    FOR INSERT TO public WITH CHECK (true);

DROP POLICY IF EXISTS "email_unsubscribes_select_policy" ON public.email_unsubscribes;
CREATE POLICY "email_unsubscribes_select_policy" ON public.email_unsubscribes
    FOR SELECT TO authenticated USING (true);

-- AGENCY_REFERRAL_PARTNERS TABLE (2026-08-17)
CREATE TABLE IF NOT EXISTS public.agency_referral_partners (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agency_name TEXT NOT NULL,
    contact_name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    phone TEXT DEFAULT NULL,
    city TEXT NOT NULL,
    website TEXT DEFAULT NULL,
    agency_size TEXT DEFAULT NULL,
    referral_source TEXT DEFAULT NULL,
    slug TEXT NOT NULL UNIQUE,
    referral_code TEXT NOT NULL UNIQUE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS agency_referral_partners_email_idx
    ON public.agency_referral_partners (lower(email));

CREATE UNIQUE INDEX IF NOT EXISTS agency_referral_partners_agency_name_idx
    ON public.agency_referral_partners (lower(agency_name));

CREATE UNIQUE INDEX IF NOT EXISTS agency_referral_partners_slug_idx
    ON public.agency_referral_partners (lower(slug));

CREATE UNIQUE INDEX IF NOT EXISTS agency_referral_partners_code_idx
    ON public.agency_referral_partners (lower(referral_code));

ALTER TABLE public.agency_referral_partners ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "agency_referral_partners_insert_policy" ON public.agency_referral_partners;
CREATE POLICY "agency_referral_partners_insert_policy" ON public.agency_referral_partners
    FOR INSERT TO public WITH CHECK (true);

DROP POLICY IF EXISTS "agency_referral_partners_select_policy" ON public.agency_referral_partners;
CREATE POLICY "agency_referral_partners_select_policy" ON public.agency_referral_partners
    FOR SELECT TO public USING (true);

-- CREATE AGENCY_OTP_CODES TABLE (2026-08-17)
CREATE TABLE IF NOT EXISTS public.agency_otp_codes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT NOT NULL,
    otp_hash TEXT NOT NULL,
    attempts INTEGER DEFAULT 0,
    is_used BOOLEAN DEFAULT FALSE,
    expires_at TIMESTAMPTZ NOT NULL,
    blocked_until TIMESTAMPTZ DEFAULT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_agency_otp_codes_email ON public.agency_otp_codes(email, created_at DESC);

ALTER TABLE public.agency_otp_codes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "agency_otp_codes_anon_policy" ON public.agency_otp_codes;
CREATE POLICY "agency_otp_codes_anon_policy" ON public.agency_otp_codes
    FOR ALL TO public USING (true) WITH CHECK (true);

-- CREATE AGENCIES MASTER TABLE
CREATE TABLE IF NOT EXISTS public.agencies (
    id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    name TEXT NOT NULL,
    long_name TEXT DEFAULT NULL,
    city TEXT DEFAULT NULL,
    address TEXT DEFAULT NULL,
    website TEXT DEFAULT NULL,
    is_partner BOOLEAN DEFAULT FALSE,
    uses_stanomer BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS agencies_city_idx ON public.agencies (city);
CREATE INDEX IF NOT EXISTS agencies_name_idx ON public.agencies (name);

ALTER TABLE public.agencies ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "agencies_select_policy" ON public.agencies;
CREATE POLICY "agencies_select_policy" ON public.agencies
    FOR SELECT TO public USING (true);

-- CREATE AGENCY_PHONES CHILD TABLE
CREATE TABLE IF NOT EXISTS public.agency_phones (
    id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    agency_id BIGINT REFERENCES public.agencies(id) ON DELETE CASCADE,
    phone TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS agency_phones_agency_id_idx ON public.agency_phones (agency_id);

ALTER TABLE public.agency_phones ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "agency_phones_select_policy" ON public.agency_phones;
CREATE POLICY "agency_phones_select_policy" ON public.agency_phones
    FOR SELECT TO public USING (true);

-- CREATE AGENCY_EMAILS CHILD TABLE
CREATE TABLE IF NOT EXISTS public.agency_emails (
    id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    agency_id BIGINT REFERENCES public.agencies(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS agency_emails_agency_id_idx ON public.agency_emails (agency_id);

ALTER TABLE public.agency_emails ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "agency_emails_select_policy" ON public.agency_emails;
CREATE POLICY "agency_emails_select_policy" ON public.agency_emails
    FOR SELECT TO public USING (true);

-- CREATE VIEW_CLEAN_AGENCIES TABLE (Agency Directory)
CREATE TABLE IF NOT EXISTS public.view_clean_agencies (
    id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    acente_adi TEXT NOT NULL,
    resmi_tam_unvan TEXT DEFAULT NULL,
    sehir TEXT DEFAULT NULL,
    adres TEXT DEFAULT NULL,
    web_sitesi TEXT DEFAULT NULL,
    telefonlar TEXT DEFAULT NULL,
    eposta_adresleri TEXT DEFAULT NULL,
    is_partner BOOLEAN DEFAULT FALSE,
    uses_stanomer BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS view_clean_agencies_sehir_idx ON public.view_clean_agencies (sehir);
CREATE INDEX IF NOT EXISTS view_clean_agencies_acente_adi_idx ON public.view_clean_agencies (acente_adi);
CREATE INDEX IF NOT EXISTS view_clean_agencies_partner_idx ON public.view_clean_agencies (is_partner);
CREATE INDEX IF NOT EXISTS view_clean_agencies_uses_stanomer_idx ON public.view_clean_agencies (uses_stanomer);

-- ------------------------------------------------------------------------------
-- AGENCY DEMO REQUESTS (White-Label / Agency Demo Lead Capture)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.agency_demo_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agency_name TEXT NOT NULL,
    email TEXT NOT NULL,
    website TEXT,
    phone_number TEXT,
    special_requests TEXT,
    status TEXT DEFAULT 'pending',
    verification_token UUID DEFAULT gen_random_uuid(),
    is_email_verified BOOLEAN DEFAULT FALSE,
    token_expires_at TIMESTAMPTZ DEFAULT (now() + interval '24 hours'),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    utm_source TEXT DEFAULT NULL,
    utm_medium TEXT DEFAULT NULL,
    utm_campaign TEXT DEFAULT NULL,
    selected_modules TEXT[] DEFAULT ARRAY['portfolio_distribution', 'property_lease_management']::TEXT[]
);

CREATE INDEX IF NOT EXISTS agency_demo_requests_email_idx ON public.agency_demo_requests (lower(email));
CREATE INDEX IF NOT EXISTS agency_demo_requests_verification_token_idx ON public.agency_demo_requests (verification_token);

ALTER TABLE public.agency_demo_requests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "agency_demo_requests_insert_policy" ON public.agency_demo_requests;
CREATE POLICY "agency_demo_requests_insert_policy" ON public.agency_demo_requests
    FOR INSERT TO public WITH CHECK (true);

DROP POLICY IF EXISTS "agency_demo_requests_select_policy" ON public.agency_demo_requests;
CREATE POLICY "agency_demo_requests_select_policy" ON public.agency_demo_requests
    FOR SELECT TO public USING (true);

-- RPC for agency demo token verification
CREATE OR REPLACE FUNCTION public.verify_agency_demo_token(p_token UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_request RECORD;
BEGIN
    SELECT * INTO v_request
    FROM public.agency_demo_requests
    WHERE verification_token = p_token;

    IF v_request IS NULL THEN
        RETURN jsonb_build_object('success', false, 'message', 'Geçersiz veya bulunamayan doğrulama kodu.');
    END IF;

    IF v_request.token_expires_at < now() THEN
        RETURN jsonb_build_object('success', false, 'message', 'Doğrulama bağlantısının süresi dolmuş.');
    END IF;

    IF v_request.is_email_verified THEN
        RETURN jsonb_build_object('success', true, 'already_verified', true, 'message', 'E-posta adresi zaten doğrulanmış.');
    END IF;

    UPDATE public.agency_demo_requests
    SET is_email_verified = TRUE,
        status = 'email_verified',
        updated_at = now()
    WHERE id = v_request.id;

    RETURN jsonb_build_object('success', true, 'message', 'E-posta adresiniz başarıyla doğrulandı.');
END;
$$;

GRANT EXECUTE ON FUNCTION public.verify_agency_demo_token(UUID) TO anon, authenticated;

-- ------------------------------------------------------------------------------
-- EMAIL UNSUBSCRIBES TABLE (Transactional Email Compliance)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.email_unsubscribes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT NOT NULL,
    reason TEXT DEFAULT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS email_unsubscribes_email_idx 
    ON public.email_unsubscribes (lower(email));

ALTER TABLE public.email_unsubscribes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "email_unsubscribes_insert_policy" ON public.email_unsubscribes;
CREATE POLICY "email_unsubscribes_insert_policy" ON public.email_unsubscribes
    FOR INSERT TO public WITH CHECK (true);

DROP POLICY IF EXISTS "email_unsubscribes_select_policy" ON public.email_unsubscribes;
CREATE POLICY "email_unsubscribes_select_policy" ON public.email_unsubscribes
    FOR SELECT TO public USING (true);

-- ------------------------------------------------------------------------------
-- AGENCY REFERRAL PARTNERS (Static QR & Referral Agency Model)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.agency_referral_partners (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agency_name TEXT NOT NULL,
    contact_name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    phone TEXT DEFAULT NULL,
    city TEXT NOT NULL,
    website TEXT DEFAULT NULL,
    agency_size TEXT DEFAULT NULL,
    referral_source TEXT DEFAULT NULL,
    slug TEXT NOT NULL UNIQUE,
    referral_code TEXT NOT NULL UNIQUE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS agency_referral_partners_email_idx ON public.agency_referral_partners (lower(email));
CREATE INDEX IF NOT EXISTS agency_referral_partners_slug_idx ON public.agency_referral_partners (lower(slug));
CREATE INDEX IF NOT EXISTS agency_referral_partners_code_idx ON public.agency_referral_partners (lower(referral_code));

ALTER TABLE public.agency_referral_partners ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "agency_referral_partners_insert_policy" ON public.agency_referral_partners;
CREATE POLICY "agency_referral_partners_insert_policy" ON public.agency_referral_partners
    FOR INSERT TO public WITH CHECK (true);

DROP POLICY IF EXISTS "agency_referral_partners_select_policy" ON public.agency_referral_partners;
CREATE POLICY "agency_referral_partners_select_policy" ON public.agency_referral_partners
    FOR SELECT TO public USING (true);

DROP POLICY IF EXISTS "agency_referral_partners_update_policy" ON public.agency_referral_partners;
CREATE POLICY "agency_referral_partners_update_policy" ON public.agency_referral_partners
    FOR UPDATE TO public USING (true) WITH CHECK (true);

-- ------------------------------------------------------------------------------
-- AGENCY OTP CODES (Passwordless Partner Portal Authentication)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.agency_otp_codes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT NOT NULL,
    otp_hash TEXT NOT NULL,
    attempts INT DEFAULT 0,
    is_used BOOLEAN DEFAULT FALSE,
    blocked_until TIMESTAMPTZ DEFAULT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS agency_otp_codes_email_created_idx 
    ON public.agency_otp_codes (email, created_at DESC);

ALTER TABLE public.agency_otp_codes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "agency_otp_codes_anon_insert_policy" ON public.agency_otp_codes;
CREATE POLICY "agency_otp_codes_anon_insert_policy" ON public.agency_otp_codes
    FOR INSERT TO public WITH CHECK (true);

DROP POLICY IF EXISTS "agency_otp_codes_anon_select_policy" ON public.agency_otp_codes;
CREATE POLICY "agency_otp_codes_anon_select_policy" ON public.agency_otp_codes
    FOR SELECT TO public USING (true);

DROP POLICY IF EXISTS "agency_otp_codes_anon_update_policy" ON public.agency_otp_codes;
CREATE POLICY "agency_otp_codes_anon_update_policy" ON public.agency_otp_codes
    FOR UPDATE TO public USING (true) WITH CHECK (true);

-- ------------------------------------------------------------------------------
-- AGENCY SANDBOX & DEMO FUNCTIONS
-- ------------------------------------------------------------------------------
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS is_demo BOOLEAN DEFAULT FALSE;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS demo_expires_at TIMESTAMPTZ DEFAULT NULL;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS website_url TEXT DEFAULT NULL;

-- 0. Verify Agency Demo Token & Provision User Function
CREATE OR REPLACE FUNCTION public.verify_agency_demo_token(p_token UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_request RECORD;
    v_user_id UUID;
    v_temp_password TEXT := 'Stanomer2026!';
    v_instance_id UUID;
    v_was_expired BOOLEAN := FALSE;
    v_modules TEXT[];
BEGIN
    SELECT * INTO v_request
    FROM public.agency_demo_requests
    WHERE verification_token = p_token;

    IF v_request IS NULL THEN
        RETURN jsonb_build_object('success', false, 'message', 'Geçersiz veya bulunamayan doğrulama kodu.');
    END IF;

    -- Süresi dolmuşsa tespit et ve linki 3 gün daha ötele (hata fırlatmak yerine yenile)
    IF v_request.token_expires_at IS NOT NULL AND v_request.token_expires_at < now() THEN
        v_was_expired := TRUE;
    END IF;

    UPDATE public.agency_demo_requests
    SET is_email_verified = TRUE,
        status = 'active_demo',
        token_expires_at = (now() + interval '7 days'),
        updated_at = now()
    WHERE id = v_request.id;

    -- Determine active modules from request (respect selected_modules from modal)
    IF v_request.selected_modules IS NOT NULL AND array_length(v_request.selected_modules, 1) > 0 THEN
        v_modules := v_request.selected_modules;
    ELSIF v_request.special_requests ILIKE '%portfolio_distribution%' AND v_request.special_requests NOT ILIKE '%property_lease_management%' THEN
        v_modules := ARRAY['portfolio_distribution'];
    ELSIF v_request.special_requests ILIKE '%property_lease_management%' AND v_request.special_requests NOT ILIKE '%portfolio_distribution%' THEN
        v_modules := ARRAY['property_lease_management'];
    ELSE
        v_modules := ARRAY['portfolio_distribution', 'property_lease_management'];
    END IF;

    SELECT instance_id INTO v_instance_id FROM auth.users WHERE instance_id IS NOT NULL LIMIT 1;
    IF v_instance_id IS NULL THEN
        v_instance_id := '00000000-0000-0000-0000-000000000000'::uuid;
    END IF;

    SELECT id INTO v_user_id FROM auth.users WHERE email = lower(v_request.email);

    IF v_user_id IS NULL THEN
        v_user_id := gen_random_uuid();
        INSERT INTO auth.users (
            id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
            confirmation_token, recovery_token, email_change_token_new, email_change,
            email_change_token_current, reauthentication_token, phone, phone_change, phone_change_token,
            raw_app_meta_data, raw_user_meta_data, is_super_admin, is_sso_user, is_anonymous, created_at, updated_at
        ) VALUES (
            v_user_id, v_instance_id, 'authenticated', 'authenticated',
            lower(v_request.email), extensions.crypt(v_temp_password, extensions.gen_salt('bf')),
            now(),
            '', '', '', '',
            '', '', NULL, '', '',
            '{"provider":"email","providers":["email"]}'::jsonb,
            jsonb_build_object('full_name', v_request.agency_name, 'company_name', v_request.agency_name),
            false, false, false, now(), now()
        );
    ELSE
        UPDATE auth.users
        SET encrypted_password = extensions.crypt(v_temp_password, extensions.gen_salt('bf')),
            email_confirmed_at = COALESCE(email_confirmed_at, now()),
            confirmation_token = COALESCE(confirmation_token, ''),
            recovery_token = COALESCE(recovery_token, ''),
            email_change_token_new = COALESCE(email_change_token_new, ''),
            email_change = COALESCE(email_change, ''),
            email_change_token_current = COALESCE(email_change_token_current, ''),
            reauthentication_token = COALESCE(reauthentication_token, ''),
            phone = CASE WHEN phone = '' THEN NULL ELSE phone END,
            phone_change = COALESCE(NULLIF(phone_change, ''), ''),
            phone_change_token = COALESCE(phone_change_token, ''),
            instance_id = COALESCE(instance_id, v_instance_id),
            aud = 'authenticated',
            role = 'authenticated',
            raw_app_meta_data = '{"provider":"email","providers":["email"]}'::jsonb,
            updated_at = now()
        WHERE id = v_user_id;
    END IF;

    -- Kullanıcının GoTrue şema uyumluluğunu kesin garantiye al
    UPDATE auth.users
    SET phone = CASE WHEN phone = '' THEN NULL ELSE phone END,
        phone_change = COALESCE(phone_change, ''),
        phone_change_token = COALESCE(phone_change_token, '')
    WHERE id = v_user_id;

    INSERT INTO auth.identities (
        id, provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at
    ) VALUES (
        gen_random_uuid(),
        v_user_id::text,
        v_user_id,
        jsonb_build_object('sub', v_user_id::text, 'email', lower(v_request.email)),
        'email',
        now(),
        now(),
        now()
    ) ON CONFLICT (provider_id, provider) DO UPDATE SET
        identity_data = EXCLUDED.identity_data,
        updated_at = now();

    -- Upsert public.profiles with 7 days sandbox expiration
    INSERT INTO public.profiles (
        id, email, full_name, role, active_role, company_name, website_url, phone_number, is_demo, demo_expires_at, active_modules, created_at, updated_at
    ) VALUES (
        v_user_id, lower(v_request.email), v_request.agency_name, 'agency', 'agency', v_request.agency_name,
        v_request.website, v_request.phone_number, true, (now() + interval '7 days'), v_modules, now(), now()
    ) ON CONFLICT (id) DO UPDATE SET
        role = 'agency',
        active_role = 'agency',
        company_name = EXCLUDED.company_name,
        website_url = EXCLUDED.website_url,
        phone_number = COALESCE(EXCLUDED.phone_number, profiles.phone_number),
        is_demo = true,
        demo_expires_at = (now() + interval '7 days'),
        active_modules = COALESCE(v_modules, profiles.active_modules),
        updated_at = now();

    -- Data yoksa tekrar üret, varsa dokunma:
    IF NOT EXISTS (SELECT 1 FROM public.properties WHERE agency_id = v_user_id) THEN
        PERFORM public.generate_agency_demo_data(v_user_id);
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'message', CASE 
            WHEN v_was_expired THEN 'Demo süreniz 7 gün olarak yenilendi ve portföyünüz hazırlandı.' 
            ELSE 'Hesabınız başarıyla 7 günlük sandbox olarak aktifleştirildi.' 
        END,
        'was_expired', v_was_expired,
        'user_id', v_user_id,
        'email', lower(v_request.email),
        'agency_name', v_request.agency_name,
        'active_modules', v_modules,
        'temp_password', v_temp_password
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.verify_agency_demo_token(UUID) TO anon, authenticated, service_role;

-- 1. Clear Agency Demo Data Function
CREATE OR REPLACE FUNCTION public.clear_agency_demo_data(p_agency_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_property_ids UUID[];
    v_contract_ids UUID[];
    v_request_ids UUID[];
    v_listing_ids UUID[];
    v_demo_user_ids UUID[];
    v_agency_short TEXT;
    v_prop_count INT := 0;
    v_listing_count INT := 0;
    v_lead_count INT := 0;
BEGIN
    v_agency_short := substring(p_agency_id::text from 1 for 8);

    SELECT ARRAY_AGG(id) INTO v_property_ids
    FROM public.properties
    WHERE agency_id = p_agency_id;

    IF v_property_ids IS NOT NULL AND array_length(v_property_ids, 1) > 0 THEN
        v_prop_count := array_length(v_property_ids, 1);

        SELECT ARRAY_AGG(id) INTO v_contract_ids
        FROM public.contracts
        WHERE property_id = ANY(v_property_ids) OR agency_id = p_agency_id;

        SELECT ARRAY_AGG(id) INTO v_request_ids
        FROM public.maintenance_requests
        WHERE property_id = ANY(v_property_ids);

        IF v_request_ids IS NOT NULL THEN
            DELETE FROM public.maintenance_messages WHERE request_id = ANY(v_request_ids);
            DELETE FROM public.maintenance_charges WHERE maintenance_request_id = ANY(v_request_ids);
        END IF;
        DELETE FROM public.activity_logs WHERE property_id = ANY(v_property_ids);
        DELETE FROM public.maintenance_requests WHERE property_id = ANY(v_property_ids);
        DELETE FROM public.rent_payments WHERE property_id = ANY(v_property_ids);
        IF to_regclass('public.property_owners') IS NOT NULL THEN
            DELETE FROM public.property_owners WHERE property_id = ANY(v_property_ids);
        END IF;
        IF to_regclass('public.invitations') IS NOT NULL THEN
            DELETE FROM public.invitations WHERE property_id = ANY(v_property_ids);
        END IF;
        DELETE FROM public.contracts WHERE property_id = ANY(v_property_ids) OR agency_id = p_agency_id;
        DELETE FROM public.properties WHERE id = ANY(v_property_ids);
    END IF;

    -- Portfolio & Distribution tables (listings, listing_images, agency_leads)
    IF to_regclass('public.listings') IS NOT NULL THEN
        SELECT ARRAY_AGG(id) INTO v_listing_ids
        FROM public.listings
        WHERE agency_id = p_agency_id;

        IF v_listing_ids IS NOT NULL AND array_length(v_listing_ids, 1) > 0 THEN
            v_listing_count := array_length(v_listing_ids, 1);
            IF to_regclass('public.listing_images') IS NOT NULL THEN
                DELETE FROM public.listing_images WHERE listing_id = ANY(v_listing_ids);
            END IF;
            DELETE FROM public.listings WHERE id = ANY(v_listing_ids);
        END IF;
    END IF;

    IF to_regclass('public.agency_leads') IS NOT NULL THEN
        DELETE FROM public.agency_leads WHERE agency_id = p_agency_id::text;
        GET DIAGNOSTICS v_lead_count = ROW_COUNT;
    END IF;

    SELECT ARRAY_AGG(id) INTO v_demo_user_ids
    FROM public.profiles
    WHERE email LIKE '%@demo.stanomer.local'
      AND (
          email LIKE ('%_' || v_agency_short || '_%@demo.stanomer.local')
          OR email LIKE ('%' || p_agency_id::text || '%')
      );

    IF v_demo_user_ids IS NOT NULL AND array_length(v_demo_user_ids, 1) > 0 THEN
        DELETE FROM public.profiles WHERE id = ANY(v_demo_user_ids);
        DELETE FROM auth.users WHERE id = ANY(v_demo_user_ids);
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'agency_id', p_agency_id,
        'deleted_properties_count', v_prop_count,
        'deleted_listings_count', v_listing_count,
        'deleted_leads_count', v_lead_count
    );
END;
$$;

-- 2. Generate Agency Demo Data Function
CREATE OR REPLACE FUNCTION public.generate_agency_demo_data(p_agency_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_l1 UUID := gen_random_uuid();
    v_l2 UUID := gen_random_uuid();
    v_l3 UUID := gen_random_uuid();
    v_l4 UUID := gen_random_uuid();
    v_l5 UUID := gen_random_uuid();
    v_l6 UUID := gen_random_uuid();
    v_l7 UUID := gen_random_uuid();

    v_t1 UUID := gen_random_uuid();
    v_t2 UUID := gen_random_uuid();
    v_t3 UUID := gen_random_uuid();
    v_t4 UUID := gen_random_uuid();
    v_t5 UUID := gen_random_uuid();
    v_t6 UUID := gen_random_uuid();
    v_t7 UUID := gen_random_uuid();
    v_t8 UUID := gen_random_uuid();
    v_t9 UUID := gen_random_uuid();
    v_t10 UUID := gen_random_uuid();

    v_p1 UUID := gen_random_uuid();
    v_p2 UUID := gen_random_uuid();
    v_p3 UUID := gen_random_uuid();
    v_p4 UUID := gen_random_uuid();
    v_p5 UUID := gen_random_uuid();
    v_p6 UUID := gen_random_uuid();
    v_p7 UUID := gen_random_uuid();
    v_p8 UUID := gen_random_uuid();
    v_p9 UUID := gen_random_uuid();
    v_p10 UUID := gen_random_uuid();

    v_c1 UUID := gen_random_uuid();
    v_c2 UUID := gen_random_uuid();
    v_c3 UUID := gen_random_uuid();
    v_c4 UUID := gen_random_uuid();
    v_c5 UUID := gen_random_uuid();
    v_c6 UUID := gen_random_uuid();
    v_c7 UUID := gen_random_uuid();
    v_c8 UUID := gen_random_uuid();
    v_c9 UUID := gen_random_uuid();
    v_c10 UUID := gen_random_uuid();

    v_mr1 UUID := gen_random_uuid();
    v_mr2 UUID := gen_random_uuid();
    v_mr3 UUID := gen_random_uuid();
    v_mr4 UUID := gen_random_uuid();
    v_mr5 UUID := gen_random_uuid();

    v_agency_short TEXT;
    v_agency_name TEXT;
BEGIN
    SELECT COALESCE(company_name, full_name, 'Agency') INTO v_agency_name
    FROM public.profiles
    WHERE id = p_agency_id;

    IF v_agency_name IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Agency profile not found for provided ID');
    END IF;

    v_agency_short := substring(p_agency_id::text from 1 for 8);

    UPDATE public.profiles
    SET is_demo = TRUE,
        demo_expires_at = (now() + interval '7 days'),
        updated_at = now()
    WHERE id = p_agency_id;

    PERFORM public.clear_agency_demo_data(p_agency_id);

    INSERT INTO auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
    VALUES
        (v_l1, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'landlord_' || v_agency_short || '_1@demo.stanomer.local', extensions.crypt('Stanomer2026!', extensions.gen_salt('bf')), now(), '{"provider":"email"}'::jsonb, '{"full_name":"Miloš Petrović"}'::jsonb, now(), now()),
        (v_l2, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'landlord_' || v_agency_short || '_2@demo.stanomer.local', extensions.crypt('Stanomer2026!', extensions.gen_salt('bf')), now(), '{"provider":"email"}'::jsonb, '{"full_name":"Jelena Đorđević"}'::jsonb, now(), now()),
        (v_l3, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'landlord_' || v_agency_short || '_3@demo.stanomer.local', extensions.crypt('Stanomer2026!', extensions.gen_salt('bf')), now(), '{"provider":"email"}'::jsonb, '{"full_name":"Dragan Nikolić"}'::jsonb, now(), now()),
        (v_l4, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'landlord_' || v_agency_short || '_4@demo.stanomer.local', extensions.crypt('Stanomer2026!', extensions.gen_salt('bf')), now(), '{"provider":"email"}'::jsonb, '{"full_name":"Marija Vasić"}'::jsonb, now(), now()),
        (v_l5, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'landlord_' || v_agency_short || '_5@demo.stanomer.local', extensions.crypt('Stanomer2026!', extensions.gen_salt('bf')), now(), '{"provider":"email"}'::jsonb, '{"full_name":"Zoran Stojanović"}'::jsonb, now(), now()),
        (v_l6, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'landlord_' || v_agency_short || '_6@demo.stanomer.local', extensions.crypt('Stanomer2026!', extensions.gen_salt('bf')), now(), '{"provider":"email"}'::jsonb, '{"full_name":"Snežana Popović"}'::jsonb, now(), now()),
        (v_l7, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'landlord_' || v_agency_short || '_7@demo.stanomer.local', extensions.crypt('Stanomer2026!', extensions.gen_salt('bf')), now(), '{"provider":"email"}'::jsonb, '{"full_name":"Nenad Kovačević"}'::jsonb, now(), now());

    INSERT INTO public.profiles (id, email, full_name, phone_number, role, active_role, created_at, updated_at)
    VALUES
        (v_l1, 'landlord_' || v_agency_short || '_1@demo.stanomer.local', 'Miloš Petrović', '+381641122331', 'landlord', 'landlord', now(), now()),
        (v_l2, 'landlord_' || v_agency_short || '_2@demo.stanomer.local', 'Jelena Đorđević', '+381641122332', 'landlord', 'landlord', now(), now()),
        (v_l3, 'landlord_' || v_agency_short || '_3@demo.stanomer.local', 'Dragan Nikolić', '+381641122333', 'landlord', 'landlord', now(), now()),
        (v_l4, 'landlord_' || v_agency_short || '_4@demo.stanomer.local', 'Marija Vasić', '+381641122334', 'landlord', 'landlord', now(), now()),
        (v_l5, 'landlord_' || v_agency_short || '_5@demo.stanomer.local', 'Zoran Stojanović', '+381641122335', 'landlord', 'landlord', now(), now()),
        (v_l6, 'landlord_' || v_agency_short || '_6@demo.stanomer.local', 'Snežana Popović', '+381641122336', 'landlord', 'landlord', now(), now()),
        (v_l7, 'landlord_' || v_agency_short || '_7@demo.stanomer.local', 'Nenad Kovačević', '+381641122337', 'landlord', 'landlord', now(), now())
    ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        full_name = EXCLUDED.full_name,
        phone_number = EXCLUDED.phone_number,
        role = EXCLUDED.role,
        active_role = EXCLUDED.active_role,
        updated_at = now();

    INSERT INTO auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
    VALUES
        (v_t1, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'tenant_' || v_agency_short || '_1@demo.stanomer.local', extensions.crypt('Stanomer2026!', extensions.gen_salt('bf')), now(), '{"provider":"email"}'::jsonb, '{"full_name":"Nikola Marković"}'::jsonb, now(), now()),
        (v_t2, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'tenant_' || v_agency_short || '_2@demo.stanomer.local', extensions.crypt('Stanomer2026!', extensions.gen_salt('bf')), now(), '{"provider":"email"}'::jsonb, '{"full_name":"Ana Simić"}'::jsonb, now(), now()),
        (v_t3, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'tenant_' || v_agency_short || '_3@demo.stanomer.local', extensions.crypt('Stanomer2026!', extensions.gen_salt('bf')), now(), '{"provider":"email"}'::jsonb, '{"full_name":"Stefan Ilić"}'::jsonb, now(), now()),
        (v_t4, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'tenant_' || v_agency_short || '_4@demo.stanomer.local', extensions.crypt('Stanomer2026!', extensions.gen_salt('bf')), now(), '{"provider":"email"}'::jsonb, '{"full_name":"Milica Todorović"}'::jsonb, now(), now()),
        (v_t5, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'tenant_' || v_agency_short || '_5@demo.stanomer.local', extensions.crypt('Stanomer2026!', extensions.gen_salt('bf')), now(), '{"provider":"email"}'::jsonb, '{"full_name":"Aleksandar Jovanović"}'::jsonb, now(), now()),
        (v_t6, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'tenant_' || v_agency_short || '_6@demo.stanomer.local', extensions.crypt('Stanomer2026!', extensions.gen_salt('bf')), now(), '{"provider":"email"}'::jsonb, '{"full_name":"Tamara Lukić"}'::jsonb, now(), now()),
        (v_t7, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'tenant_' || v_agency_short || '_7@demo.stanomer.local', extensions.crypt('Stanomer2026!', extensions.gen_salt('bf')), now(), '{"provider":"email"}'::jsonb, '{"full_name":"Vladimir Pavlović"}'::jsonb, now(), now()),
        (v_t8, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'tenant_' || v_agency_short || '_8@demo.stanomer.local', extensions.crypt('Stanomer2026!', extensions.gen_salt('bf')), now(), '{"provider":"email"}'::jsonb, '{"full_name":"Jovana Bogdanović"}'::jsonb, now(), now()),
        (v_t9, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'tenant_' || v_agency_short || '_9@demo.stanomer.local', extensions.crypt('Stanomer2026!', extensions.gen_salt('bf')), now(), '{"provider":"email"}'::jsonb, '{"full_name":"Luka Lazarević"}'::jsonb, now(), now()),
        (v_t10, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'tenant_' || v_agency_short || '_10@demo.stanomer.local', extensions.crypt('Stanomer2026!', extensions.gen_salt('bf')), now(), '{"provider":"email"}'::jsonb, '{"full_name":"Sara Savić"}'::jsonb, now(), now());

    INSERT INTO public.profiles (id, email, full_name, phone_number, role, active_role, created_at, updated_at)
    VALUES
        (v_t1, 'tenant_' || v_agency_short || '_1@demo.stanomer.local', 'Nikola Marković', '+381652233441', 'tenant', 'tenant', now(), now()),
        (v_t2, 'tenant_' || v_agency_short || '_2@demo.stanomer.local', 'Ana Simić', '+381652233442', 'tenant', 'tenant', now(), now()),
        (v_t3, 'tenant_' || v_agency_short || '_3@demo.stanomer.local', 'Stefan Ilić', '+381652233443', 'tenant', 'tenant', now(), now()),
        (v_t4, 'tenant_' || v_agency_short || '_4@demo.stanomer.local', 'Milica Todorović', '+381652233444', 'tenant', 'tenant', now(), now()),
        (v_t5, 'tenant_' || v_agency_short || '_5@demo.stanomer.local', 'Aleksandar Jovanović', '+381652233445', 'tenant', 'tenant', now(), now()),
        (v_t6, 'tenant_' || v_agency_short || '_6@demo.stanomer.local', 'Tamara Lukić', '+381652233446', 'tenant', 'tenant', now(), now()),
        (v_t7, 'tenant_' || v_agency_short || '_7@demo.stanomer.local', 'Vladimir Pavlović', '+381652233447', 'tenant', 'tenant', now(), now()),
        (v_t8, 'tenant_' || v_agency_short || '_8@demo.stanomer.local', 'Jovana Bogdanović', '+381652233448', 'tenant', 'tenant', now(), now()),
        (v_t9, 'tenant_' || v_agency_short || '_9@demo.stanomer.local', 'Luka Lazarević', '+381652233449', 'tenant', 'tenant', now(), now()),
        (v_t10, 'tenant_' || v_agency_short || '_10@demo.stanomer.local', 'Sara Savić', '+381652233450', 'tenant', 'tenant', now(), now())
    ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        full_name = EXCLUDED.full_name,
        phone_number = EXCLUDED.phone_number,
        role = EXCLUDED.role,
        active_role = EXCLUDED.active_role,
        updated_at = now();

    INSERT INTO public.properties (
        id, landlord_id, agency_id, tenant_id, title, name, address, city,
        default_monthly_rent, default_deposit_amount, currency, default_due_day,
        landlord_name, landlord_phone, landlord_email, property_type, unit_number,
        room_count, area_sqm, floor, total_floors, furnishing, heating_type,
        amenities, is_detailed, description, created_at, updated_at
    ) VALUES
        (v_p1, v_l1, p_agency_id, v_t1, 'Dorćol Modern Two-Bedroom', 'Dorćol Modern', 'Cara Dušana 42, Stari Grad', 'Beograd', 650.00, 650.00, 'EUR', 5, 'Miloš Petrović', '+381641122331', 'milos.petrovic@example.com', 'apartment', '14', '2.0', 58.00, '3', 6, 'furnished', 'cg', '["elevator","balcony","air_conditioning"]'::jsonb, true, 'Renoviran, moderan stan u srcu Dorćola sa odličnim rasporedom.', '2026-04-01 10:00:00+00', now()),
        (v_p2, v_l1, p_agency_id, v_t2, 'Vračar Hram Studio Deluxe', 'Vračar Studio', 'Kneginje Zorke 18, Vračar', 'Beograd', 450.00, 450.00, 'EUR', 1, 'Miloš Petrović', '+381641122331', 'milos.petrovic@example.com', 'apartment', '4', 'studio', 34.00, '1', 5, 'furnished', 'cg', '["elevator","air_conditioning"]'::jsonb, true, 'Udoban studio na korak od Hrama Svetog Save.', '2026-04-01 10:00:00+00', now()),
        (v_p3, v_l2, p_agency_id, v_t3, 'Novi Beograd Blok 21 Three-Room', 'NBG Blok 21', 'Bulevar Mihajla Pupina 85, Novi Beograd', 'Beograd', 800.00, 800.00, 'EUR', 10, 'Jelena Đorđević', '+381641122332', 'jelena.djordjevic@example.com', 'apartment', '22', '3.0', 78.00, '5', 9, 'furnished', 'cg', '["elevator","balcony","parking"]'::jsonb, true, 'Prostran trosoban stan sa prelepim pogledom ka reci.', '2026-04-01 10:00:00+00', now()),
        (v_p4, v_l2, p_agency_id, v_t4, 'Novi Beograd Blok 65 Exing One-Bedroom', 'Exing Blok 65', 'Omladinskih brigada 86, Novi Beograd', 'Beograd', 700.00, 700.00, 'EUR', 5, 'Jelena Đorđević', '+381641122332', 'jelena.djordjevic@example.com', 'apartment', '31', '1.5', 48.00, '6', 10, 'furnished', 'underfloor', '["elevator","balcony","parking","garage"]'::jsonb, true, 'Novogradnja, smart home sistem, recepcija 24/7.', '2026-05-15 10:00:00+00', now()),
        (v_p5, v_l3, p_agency_id, v_t5, 'Belgrade Waterfront Parkview 2BR', 'BW Parkview', 'Hercegovačka 14, Savski Venac', 'Beograd', 1100.00, 1100.00, 'EUR', 1, 'Dragan Nikolić', '+381641122333', 'dragan.nikolic@example.com', 'apartment', '52', '2.0', 62.00, '8', 22, 'furnished', 'cg', '["elevator","balcony","garage","air_conditioning"]'::jsonb, true, 'BW Parkview zgrada, recepcija, konsijerž, direktan izlaz na park.', '2026-04-01 10:00:00+00', now()),
        (v_p6, v_l4, p_agency_id, v_t6, 'Zvezdara Đeram Family Flat', 'Zvezdara Đeram', 'Bulevar Kralja Aleksandra 154, Zvezdara', 'Beograd', 550.00, 550.00, 'EUR', 7, 'Marija Vasić', '+381641122334', 'marija.vasic@example.com', 'apartment', '11', '2.5', 65.00, '2', 6, 'furnished', 'eg', '["elevator","balcony"]'::jsonb, true, 'Odlična lokacija u blizini pijace Đeram i tramvajske linije.', '2026-06-01 10:00:00+00', now()),
        (v_p7, v_l4, p_agency_id, v_t7, 'Palilula Profesorska Kolonija', 'Palilula Prof Kolonija', 'Cvijićeva 60, Palilula', 'Beograd', 500.00, 500.00, 'EUR', 1, 'Marija Vasić', '+381641122334', 'marija.vasic@example.com', 'apartment', '7', '1.5', 45.00, '2', 4, 'furnished', 'cg', '["balcony"]'::jsonb, true, 'Mirna zgrada, salonski plafoni, kompletno namešten stan.', '2026-06-01 10:00:00+00', now()),
        (v_p8, v_l5, p_agency_id, v_t8, 'Voždovac Stepa Stepanović Cozy', 'Stepa Stepanović', 'Generala Štefanika 12, Voždovac', 'Beograd', 420.00, 420.00, 'EUR', 3, 'Zoran Stojanović', '+381641122335', 'zoran.stojanovic@example.com', 'apartment', '18', '1.5', 44.00, '4', 7, 'furnished', 'cg', '["elevator","balcony","parking"]'::jsonb, true, 'Funkcionalan i topao stan u planskom naselju Stepa Stepanović.', '2026-07-01 10:00:00+00', now()),
        (v_p9, v_l6, p_agency_id, v_t9, 'Banovo Brdo Požeška 2BR', 'Banovo Brdo Požeška', 'Požeška 92, Čukarica', 'Beograd', 480.00, 480.00, 'EUR', 1, 'Snežana Popović', '+381641122336', 'snezana.popovic@example.com', 'apartment', '9', '2.0', 54.00, '3', 5, 'furnished', 'gas', '["balcony"]'::jsonb, true, 'Centar Banovog Brda, u blizini Košutnjaka i tržnog centra.', '2026-08-01 10:00:00+00', now()),
        (v_p10, v_l7, p_agency_id, v_t10, 'Zemun Kej Danube View Studio', 'Zemun Kej Studio', 'Kej Oslobođenja 25, Zemun', 'Beograd', 380.00, 380.00, 'EUR', 1, 'Nenad Kovačević', '+381641122337', 'nenad.kovacevic@example.com', 'apartment', '2', 'studio', 30.00, '1', 3, 'furnished', 'ta', '["air_conditioning"]'::jsonb, true, 'Šarmantan studio sa pogledom na Dunavski kej.', '2026-08-15 10:00:00+00', now());

    INSERT INTO public.contracts (
        id, property_id, landlord_id, agency_id, tenant_id,
        tenant_name, tenant_phone,
        monthly_rent, deposit_amount, currency, deposit_currency, due_day,
        start_date, end_date, status, invitee_email, inviter_name,
        token, expenses_config, created_at, updated_at
    ) VALUES
        (v_c1, v_p1, v_l1, p_agency_id, v_t1, 'Nikola Marković', '+381652233441', 650.00, 650.00, 'EUR', 'EUR', 5, '2026-04-01 10:00:00+00', '2027-03-31 10:00:00+00', 'active', 'nikola.markovic@example.com', v_agency_name, 'demo_token_' || v_agency_short || '_1', '[{"name":"Infostan","amount":85,"receiver":"owner","payment_method":"bank_transfer"},{"name":"Struja","amount":40,"receiver":"owner","payment_method":"bank_transfer"}]'::jsonb, '2026-04-01 10:00:00+00', now()),
        (v_c2, v_p2, v_l1, p_agency_id, v_t2, 'Ana Simić', '+381652233442', 450.00, 450.00, 'EUR', 'EUR', 1, '2026-04-01 10:00:00+00', '2027-03-31 10:00:00+00', 'active', 'ana.simic@example.com', v_agency_name, 'demo_token_' || v_agency_short || '_2', '[{"name":"Infostan","amount":50,"receiver":"owner","payment_method":"bank_transfer"},{"name":"Struja","amount":30,"receiver":"owner","payment_method":"bank_transfer"}]'::jsonb, '2026-04-01 10:00:00+00', now()),
        (v_c3, v_p3, v_l2, p_agency_id, v_t3, 'Stefan Ilić', '+381652233443', 800.00, 800.00, 'EUR', 'EUR', 10, '2026-04-01 10:00:00+00', '2027-03-31 10:00:00+00', 'active', 'stefan.ilic@example.com', v_agency_name, 'demo_token_' || v_agency_short || '_3', '[{"name":"Infostan","amount":110,"receiver":"owner","payment_method":"bank_transfer"},{"name":"Struja","amount":55,"receiver":"owner","payment_method":"bank_transfer"},{"name":"Internet & TV","amount":30,"receiver":"owner","payment_method":"bank_transfer"}]'::jsonb, '2026-04-01 10:00:00+00', now()),
        (v_c4, v_p4, v_l2, p_agency_id, v_t4, 'Milica Todorović', '+381652233444', 700.00, 700.00, 'EUR', 'EUR', 5, '2026-05-15 10:00:00+00', '2027-05-14 10:00:00+00', 'active', 'milica.todorovic@example.com', v_agency_name, 'demo_token_' || v_agency_short || '_4', '[{"name":"Infostan","amount":90,"receiver":"owner","payment_method":"bank_transfer"},{"name":"Održavanje zgrade","amount":35,"receiver":"owner","payment_method":"bank_transfer"}]'::jsonb, '2026-05-15 10:00:00+00', now()),
        (v_c5, v_p5, v_l3, p_agency_id, v_t5, 'Aleksandar Jovanović', '+381652233445', 1100.00, 1100.00, 'EUR', 'EUR', 1, '2026-04-01 10:00:00+00', '2027-03-31 10:00:00+00', 'active', 'aleksandar.jovanovic@example.com', v_agency_name, 'demo_token_' || v_agency_short || '_5', '[{"name":"Infostan","amount":130,"receiver":"owner","payment_method":"bank_transfer"},{"name":"BW Maintenance","amount":120,"receiver":"owner","payment_method":"bank_transfer"},{"name":"Struja","amount":70,"receiver":"owner","payment_method":"bank_transfer"}]'::jsonb, '2026-04-01 10:00:00+00', now()),
        (v_c6, v_p6, v_l4, p_agency_id, v_t6, 'Tamara Lukić', '+381652233446', 550.00, 550.00, 'EUR', 'EUR', 7, '2026-06-01 10:00:00+00', '2027-05-31 10:00:00+00', 'active', 'tamara.lukic@example.com', v_agency_name, 'demo_token_' || v_agency_short || '_6', '[{"name":"Infostan","amount":70,"receiver":"owner","payment_method":"bank_transfer"},{"name":"Struja","amount":45,"receiver":"owner","payment_method":"bank_transfer"}]'::jsonb, '2026-06-01 10:00:00+00', now()),
        (v_c7, v_p7, v_l4, p_agency_id, v_t7, 'Vladimir Pavlović', '+381652233447', 500.00, 500.00, 'EUR', 'EUR', 1, '2026-06-01 10:00:00+00', '2027-05-31 10:00:00+00', 'active', 'vladimir.pavlovic@example.com', v_agency_name, 'demo_token_' || v_agency_short || '_7', '[{"name":"Infostan","amount":65,"receiver":"owner","payment_method":"bank_transfer"},{"name":"Struja","amount":35,"receiver":"owner","payment_method":"bank_transfer"}]'::jsonb, '2026-06-01 10:00:00+00', now()),
        (v_c8, v_p8, v_l5, p_agency_id, v_t8, 'Jovana Bogdanović', '+381652233448', 420.00, 420.00, 'EUR', 'EUR', 3, '2026-07-01 10:00:00+00', '2027-06-30 10:00:00+00', 'active', 'jovana.bogdanovic@example.com', v_agency_name, 'demo_token_' || v_agency_short || '_8', '[{"name":"Infostan","amount":60,"receiver":"owner","payment_method":"bank_transfer"},{"name":"Grejanje","amount":50,"receiver":"owner","payment_method":"bank_transfer"}]'::jsonb, '2026-07-01 10:00:00+00', now()),
        (v_c9, v_p9, v_l6, p_agency_id, v_t9, 'Luka Lazarević', '+381652233449', 480.00, 480.00, 'EUR', 'EUR', 1, '2026-08-01 10:00:00+00', '2027-07-31 10:00:00+00', 'active', 'luka.lazarevic@example.com', v_agency_name, 'demo_token_' || v_agency_short || '_9', '[{"name":"Infostan","amount":55,"receiver":"owner","payment_method":"bank_transfer"},{"name":"Struja","amount":40,"receiver":"owner","payment_method":"bank_transfer"}]'::jsonb, '2026-08-01 10:00:00+00', now()),
        (v_c10, v_p10, v_l7, p_agency_id, v_t10, 'Sara Savić', '+381652233450', 380.00, 380.00, 'EUR', 'EUR', 1, '2026-08-15 10:00:00+00', '2027-08-14 10:00:00+00', 'active', 'sara.savic@example.com', v_agency_name, 'demo_token_' || v_agency_short || '_10', '[{"name":"Infostan","amount":45,"receiver":"owner","payment_method":"bank_transfer"},{"name":"Struja","amount":30,"receiver":"owner","payment_method":"bank_transfer"}]'::jsonb, '2026-08-15 10:00:00+00', now())
    ON CONFLICT (id) DO UPDATE SET
        tenant_name = COALESCE(public.contracts.tenant_name, EXCLUDED.tenant_name),
        tenant_phone = COALESCE(public.contracts.tenant_phone, EXCLUDED.tenant_phone);

    -- --------------------------------------------------------------------------
    -- 5. Create Payments: Complete Slice of Rents + Rich Utility Bills
    -- --------------------------------------------------------------------------
    INSERT INTO public.rent_payments (
        property_id, contract_id, landlord_id, tenant_id, title, amount, currency,
        status, due_date, declared_at, paid_at, receiver_type, invoice_url, created_at, updated_at
    ) VALUES
        -- P1: Dorćol Modern (650 EUR Rent)
        (v_p1, v_c1, v_l1, v_t1, 'Kira', 650.00, 'EUR', 'paid', '2026-04-05', '2026-04-04 14:00:00+00', '2026-04-04 16:30:00+00', 'owner', NULL, '2026-04-01 00:00:00+00', now()),
        (v_p1, v_c1, v_l1, v_t1, 'Kira', 650.00, 'EUR', 'paid', '2026-05-05', '2026-05-03 11:00:00+00', '2026-05-03 15:00:00+00', 'owner', NULL, '2026-05-01 00:00:00+00', now()),
        (v_p1, v_c1, v_l1, v_t1, 'Kira', 650.00, 'EUR', 'paid', '2026-06-05', '2026-06-05 09:00:00+00', '2026-06-05 10:15:00+00', 'owner', NULL, '2026-06-01 00:00:00+00', now()),
        (v_p1, v_c1, v_l1, v_t1, 'Kira', 650.00, 'EUR', 'paid', '2026-07-05', '2026-07-04 18:00:00+00', '2026-07-05 09:00:00+00', 'owner', NULL, '2026-07-01 00:00:00+00', now()),
        (v_p1, v_c1, v_l1, v_t1, 'Kira', 650.00, 'EUR', 'paid', '2026-08-05', '2026-08-05 12:00:00+00', '2026-08-05 14:00:00+00', 'owner', NULL, '2026-08-01 00:00:00+00', now()),
        (v_p1, v_c1, v_l1, v_t1, 'Kira', 650.00, 'EUR', 'declared', '2026-09-05', '2026-09-06 17:30:00+00', NULL, 'owner', NULL, '2026-09-01 00:00:00+00', now()),
        -- P1 Bills: August Paid, September Declared (Acente Onayı Bekleyen)
        (v_p1, v_c1, v_l1, v_t1, 'Infostan', 85.00, 'EUR', 'paid', '2026-08-15', '2026-08-14 10:00:00+00', '2026-08-15 11:00:00+00', 'owner', 'https://stanomer.online/demo/invoices/infostan_p1_aug.pdf', '2026-08-01 00:00:00+00', now()),
        (v_p1, v_c1, v_l1, v_t1, 'Struja', 42.00, 'EUR', 'paid', '2026-08-20', '2026-08-19 12:00:00+00', '2026-08-20 14:00:00+00', 'owner', 'https://stanomer.online/demo/invoices/struja_p1_aug.pdf', '2026-08-01 00:00:00+00', now()),
        (v_p1, v_c1, v_l1, v_t1, 'Infostan', 85.00, 'EUR', 'declared', '2026-09-15', '2026-09-07 14:00:00+00', NULL, 'owner', 'https://stanomer.online/demo/invoices/infostan_p1_sep.pdf', '2026-09-01 00:00:00+00', now()),

        -- P2: Vračar Studio (450 EUR Rent)
        (v_p2, v_c2, v_l1, v_t2, 'Kira', 450.00, 'EUR', 'paid', '2026-06-01', '2026-06-01 08:30:00+00', '2026-06-01 10:00:00+00', 'owner', NULL, '2026-06-01 00:00:00+00', now()),
        (v_p2, v_c2, v_l1, v_t2, 'Kira', 450.00, 'EUR', 'paid', '2026-07-01', '2026-07-01 12:00:00+00', '2026-07-01 14:00:00+00', 'owner', NULL, '2026-07-01 00:00:00+00', now()),
        (v_p2, v_c2, v_l1, v_t2, 'Kira', 450.00, 'EUR', 'paid', '2026-08-01', '2026-08-02 09:00:00+00', '2026-08-02 11:30:00+00', 'owner', NULL, '2026-08-01 00:00:00+00', now()),
        (v_p2, v_c2, v_l1, v_t2, 'Kira', 450.00, 'EUR', 'paid', '2026-09-01', '2026-08-31 20:00:00+00', '2026-09-01 09:00:00+00', 'owner', NULL, '2026-09-01 00:00:00+00', now()),
        -- P2 Bills: Infostan Paid, Struja Declared (Onay Bekleyen)
        (v_p2, v_c2, v_l1, v_t2, 'Infostan', 50.00, 'EUR', 'paid', '2026-08-10', '2026-08-08 11:00:00+00', '2026-08-09 15:00:00+00', 'owner', 'https://stanomer.online/demo/invoices/infostan_p2_aug.pdf', '2026-08-01 00:00:00+00', now()),
        (v_p2, v_c2, v_l1, v_t2, 'Infostan', 50.00, 'EUR', 'paid', '2026-09-10', '2026-09-05 11:00:00+00', '2026-09-06 15:00:00+00', 'owner', 'https://stanomer.online/demo/invoices/infostan_p2_sep.pdf', '2026-09-01 00:00:00+00', now()),
        (v_p2, v_c2, v_l1, v_t2, 'Struja', 28.50, 'EUR', 'declared', '2026-09-16', '2026-09-09 11:30:00+00', NULL, 'owner', 'https://stanomer.online/demo/invoices/struja_p2_sep.pdf', '2026-09-01 00:00:00+00', now()),

        -- P3: NBG Blok 21 (800 EUR Rent)
        (v_p3, v_c3, v_l2, v_t3, 'Kira', 800.00, 'EUR', 'paid', '2026-07-10', NULL, '2026-07-10 12:00:00+00', 'owner', NULL, '2026-07-01 00:00:00+00', now()),
        (v_p3, v_c3, v_l2, v_t3, 'Kira', 800.00, 'EUR', 'paid', '2026-08-10', NULL, '2026-08-10 12:00:00+00', 'owner', NULL, '2026-08-01 00:00:00+00', now()),
        (v_p3, v_c3, v_l2, v_t3, 'Kira', 800.00, 'EUR', 'pending', '2026-09-10', NULL, NULL, 'owner', NULL, '2026-09-01 00:00:00+00', now()),
        -- P3 Bills: August Paid, September Pending (Kiracıdan Ödeme Bekleyen)
        (v_p3, v_c3, v_l2, v_t3, 'Infostan', 110.00, 'EUR', 'paid', '2026-08-15', '2026-08-14 14:00:00+00', '2026-08-15 16:00:00+00', 'owner', 'https://stanomer.online/demo/invoices/infostan_p3_aug.pdf', '2026-08-01 00:00:00+00', now()),
        (v_p3, v_c3, v_l2, v_t3, 'Infostan', 110.00, 'EUR', 'pending', '2026-09-18', NULL, NULL, 'owner', 'https://stanomer.online/demo/invoices/infostan_p3_sep.pdf', '2026-09-01 00:00:00+00', now()),
        (v_p3, v_c3, v_l2, v_t3, 'Internet & TV', 30.00, 'EUR', 'pending', '2026-09-20', NULL, NULL, 'owner', NULL, '2026-09-01 00:00:00+00', now()),

        -- P4: Exing Blok 65 (700 EUR Rent)
        -- ★ GİRİLMEMİŞ FATURA ÖRNEĞİ: Infostan henüz girilmemiş (Tutar: 0, invoice_url: NULL)
        (v_p4, v_c4, v_l2, v_t4, 'Kira', 700.00, 'EUR', 'paid', '2026-06-05', '2026-06-04 10:00:00+00', '2026-06-04 11:30:00+00', 'owner', NULL, '2026-06-01 00:00:00+00', now()),
        (v_p4, v_c4, v_l2, v_t4, 'Kira', 700.00, 'EUR', 'paid', '2026-07-05', '2026-07-05 09:00:00+00', '2026-07-05 10:00:00+00', 'owner', NULL, '2026-07-01 00:00:00+00', now()),
        (v_p4, v_c4, v_l2, v_t4, 'Kira', 700.00, 'EUR', 'paid', '2026-08-05', '2026-08-05 14:00:00+00', '2026-08-05 15:00:00+00', 'owner', NULL, '2026-08-01 00:00:00+00', now()),
        (v_p4, v_c4, v_l2, v_t4, 'Kira', 700.00, 'EUR', 'paid', '2026-09-05', '2026-09-04 16:00:00+00', '2026-09-05 09:30:00+00', 'owner', NULL, '2026-09-01 00:00:00+00', now()),
        -- P4 Bills: Održavanje Paid, Infostan GİRİLMEMİŞ (Amount: 0.00, invoice_url: NULL, status: pending)
        (v_p4, v_c4, v_l2, v_t4, 'Održavanje zgrade', 35.00, 'EUR', 'paid', '2026-08-20', '2026-08-19 10:00:00+00', '2026-08-20 11:00:00+00', 'owner', NULL, '2026-08-01 00:00:00+00', now()),
        (v_p4, v_c4, v_l2, v_t4, 'Održavanje zgrade', 35.00, 'EUR', 'paid', '2026-09-05', '2026-09-04 15:00:00+00', '2026-09-05 10:00:00+00', 'owner', NULL, '2026-09-01 00:00:00+00', now()),
        (v_p4, v_c4, v_l2, v_t4, 'Infostan', 0.00, 'EUR', 'pending', '2026-09-20', NULL, NULL, 'owner', NULL, '2026-09-01 00:00:00+00', now()),

        -- P5: BW Parkview (1100 EUR Rent)
        (v_p5, v_c5, v_l3, v_t5, 'Kira', 1100.00, 'EUR', 'paid', '2026-06-01', '2026-06-01 10:00:00+00', '2026-06-01 11:00:00+00', 'owner', NULL, '2026-06-01 00:00:00+00', now()),
        (v_p5, v_c5, v_l3, v_t5, 'Kira', 1100.00, 'EUR', 'paid', '2026-07-01', '2026-07-01 10:00:00+00', '2026-07-01 11:00:00+00', 'owner', NULL, '2026-07-01 00:00:00+00', now()),
        (v_p5, v_c5, v_l3, v_t5, 'Kira', 1100.00, 'EUR', 'paid', '2026-08-01', '2026-08-01 10:00:00+00', '2026-08-01 11:00:00+00', 'owner', NULL, '2026-08-01 00:00:00+00', now()),
        (v_p5, v_c5, v_l3, v_t5, 'Kira', 1100.00, 'EUR', 'paid', '2026-09-01', '2026-09-01 09:30:00+00', '2026-09-01 11:00:00+00', 'owner', NULL, '2026-09-01 00:00:00+00', now()),
        -- P5 Bills: Maintenance Paid + Pending, Infostan Declared (Kiracı Dekont Yüklemiş)
        (v_p5, v_c5, v_l3, v_t5, 'BW Maintenance', 120.00, 'EUR', 'paid', '2026-08-15', '2026-08-14 09:00:00+00', '2026-08-15 10:00:00+00', 'owner', NULL, '2026-08-01 00:00:00+00', now()),
        (v_p5, v_c5, v_l3, v_t5, 'BW Maintenance', 120.00, 'EUR', 'pending', '2026-09-15', NULL, NULL, 'owner', NULL, '2026-09-01 00:00:00+00', now()),
        (v_p5, v_c5, v_l3, v_t5, 'Infostan', 134.00, 'EUR', 'declared', '2026-09-14', '2026-09-10 16:00:00+00', NULL, 'owner', 'https://stanomer.online/demo/invoices/infostan_p5_sep.pdf', '2026-09-01 00:00:00+00', now()),

        -- P6: Zvezdara Đeram (550 EUR Rent)
        -- ★ GİRİLMEMİŞ FATURA ÖRNEĞİ: Struja henüz girilmemiş (Tutar: 0, invoice_url: NULL)
        (v_p6, v_c6, v_l4, v_t6, 'Kira', 550.00, 'EUR', 'paid', '2026-07-07', '2026-07-06 11:00:00+00', '2026-07-06 14:00:00+00', 'owner', NULL, '2026-07-01 00:00:00+00', now()),
        (v_p6, v_c6, v_l4, v_t6, 'Kira', 550.00, 'EUR', 'paid', '2026-08-07', '2026-08-07 10:00:00+00', '2026-08-07 12:00:00+00', 'owner', NULL, '2026-08-01 00:00:00+00', now()),
        (v_p6, v_c6, v_l4, v_t6, 'Kira', 550.00, 'EUR', 'paid', '2026-09-07', '2026-09-07 09:15:00+00', '2026-09-07 10:30:00+00', 'owner', NULL, '2026-09-01 00:00:00+00', now()),
        -- P6 Bills: Infostan Paid, Struja GİRİLMEMİŞ (Amount: 0.00, invoice_url: NULL, status: pending)
        (v_p6, v_c6, v_l4, v_t6, 'Infostan', 70.00, 'EUR', 'paid', '2026-08-15', '2026-08-13 14:00:00+00', '2026-08-14 11:00:00+00', 'owner', 'https://stanomer.online/demo/invoices/infostan_p6_aug.pdf', '2026-08-01 00:00:00+00', now()),
        (v_p6, v_c6, v_l4, v_t6, 'Struja', 0.00, 'EUR', 'pending', '2026-09-22', NULL, NULL, 'owner', NULL, '2026-09-01 00:00:00+00', now()),

        -- P7: Palilula Prof Kolonija (500 EUR Rent)
        (v_p7, v_c7, v_l4, v_t7, 'Kira', 500.00, 'EUR', 'paid', '2026-07-01', '2026-07-01 12:00:00+00', '2026-07-01 15:00:00+00', 'owner', NULL, '2026-07-01 00:00:00+00', now()),
        (v_p7, v_c7, v_l4, v_t7, 'Kira', 500.00, 'EUR', 'paid', '2026-08-01', '2026-08-01 11:00:00+00', '2026-08-01 14:00:00+00', 'owner', NULL, '2026-08-01 00:00:00+00', now()),
        (v_p7, v_c7, v_l4, v_t7, 'Kira', 500.00, 'EUR', 'paid', '2026-09-01', '2026-09-01 08:45:00+00', '2026-09-01 09:30:00+00', 'owner', NULL, '2026-09-01 00:00:00+00', now()),
        -- P7 Bills: August Paid, September Pending
        (v_p7, v_c7, v_l4, v_t7, 'Infostan', 65.00, 'EUR', 'paid', '2026-08-15', '2026-08-14 11:00:00+00', '2026-08-15 12:00:00+00', 'owner', 'https://stanomer.online/demo/invoices/infostan_p7_aug.pdf', '2026-08-01 00:00:00+00', now()),
        (v_p7, v_c7, v_l4, v_t7, 'Infostan', 65.00, 'EUR', 'pending', '2026-09-17', NULL, NULL, 'owner', 'https://stanomer.online/demo/invoices/infostan_p7_sep.pdf', '2026-09-01 00:00:00+00', now()),

        -- P8: Stepa Stepanović (420 EUR Rent - Overdue)
        -- ★ GİRİLMEMİŞ DOĞALGAZ & VADESİ GEÇMİŞ İNFOSTAN ÖRNEKLERİ
        (v_p8, v_c8, v_l5, v_t8, 'Kira', 420.00, 'EUR', 'paid', '2026-08-03', '2026-08-03 10:00:00+00', '2026-08-03 11:00:00+00', 'owner', NULL, '2026-08-01 00:00:00+00', now()),
        (v_p8, v_c8, v_l5, v_t8, 'Kira', 420.00, 'EUR', 'overdue', '2026-09-03', NULL, NULL, 'owner', NULL, '2026-09-01 00:00:00+00', now()),
        -- P8 Bills: August Paid, September Infostan OVERDUE (Gecikmiş Fatura), Grejanje GİRİLMEMİŞ (Amount: 0)
        (v_p8, v_c8, v_l5, v_t8, 'Infostan', 60.00, 'EUR', 'paid', '2026-08-15', '2026-08-14 16:00:00+00', '2026-08-15 17:00:00+00', 'owner', 'https://stanomer.online/demo/invoices/infostan_p8_aug.pdf', '2026-08-01 00:00:00+00', now()),
        (v_p8, v_c8, v_l5, v_t8, 'Infostan', 60.00, 'EUR', 'overdue', '2026-09-03', NULL, NULL, 'owner', 'https://stanomer.online/demo/invoices/infostan_p8_sep.pdf', '2026-09-01 00:00:00+00', now()),
        (v_p8, v_c8, v_l5, v_t8, 'Grejanje', 0.00, 'EUR', 'pending', '2026-09-25', NULL, NULL, 'owner', NULL, '2026-09-01 00:00:00+00', now()),

        -- P9: Banovo Brdo (480 EUR Rent)
        -- ★ VADESİ GEÇMİŞ ELEKTRİK (STRUJA) ÖRNEĞİ
        (v_p9, v_c9, v_l6, v_t9, 'Kira', 480.00, 'EUR', 'paid', '2026-08-01', '2026-08-01 09:00:00+00', '2026-08-01 10:30:00+00', 'owner', NULL, '2026-08-01 00:00:00+00', now()),
        (v_p9, v_c9, v_l6, v_t9, 'Kira', 480.00, 'EUR', 'paid', '2026-09-01', '2026-09-01 09:00:00+00', '2026-09-01 10:30:00+00', 'owner', NULL, '2026-09-01 00:00:00+00', now()),
        -- P9 Bills: Infostan Paid, Struja OVERDUE (Vadesi Geçmiş)
        (v_p9, v_c9, v_l6, v_t9, 'Infostan', 55.00, 'EUR', 'paid', '2026-08-15', '2026-08-14 10:00:00+00', '2026-08-15 11:30:00+00', 'owner', 'https://stanomer.online/demo/invoices/infostan_p9_aug.pdf', '2026-08-01 00:00:00+00', now()),
        (v_p9, v_c9, v_l6, v_t9, 'Infostan', 55.00, 'EUR', 'paid', '2026-09-10', '2026-09-08 09:00:00+00', '2026-09-09 10:30:00+00', 'owner', 'https://stanomer.online/demo/invoices/infostan_p9_sep.pdf', '2026-09-01 00:00:00+00', now()),
        (v_p9, v_c9, v_l6, v_t9, 'Struja', 38.00, 'EUR', 'overdue', '2026-09-05', NULL, NULL, 'owner', 'https://stanomer.online/demo/invoices/struja_p9_sep.pdf', '2026-09-01 00:00:00+00', now()),

        -- P10: Zemun Kej (380 EUR Rent)
        (v_p10, v_c10, v_l7, v_t10, 'Kira', 380.00, 'EUR', 'paid', '2026-08-15', '2026-08-15 10:00:00+00', '2026-08-15 11:30:00+00', 'owner', NULL, '2026-08-15 00:00:00+00', now()),
        (v_p10, v_c10, v_l7, v_t10, 'Kira', 380.00, 'EUR', 'pending', '2026-09-15', NULL, NULL, 'owner', NULL, '2026-09-01 00:00:00+00', now()),
        -- P10 Bills: August Infostan Paid, September Struja Pending (Ödeme Bekleyen)
        (v_p10, v_c10, v_l7, v_t10, 'Infostan', 45.00, 'EUR', 'paid', '2026-08-20', '2026-08-19 14:00:00+00', '2026-08-20 15:30:00+00', 'owner', 'https://stanomer.online/demo/invoices/infostan_p10_aug.pdf', '2026-08-15 00:00:00+00', now()),
        (v_p10, v_c10, v_l7, v_t10, 'Struja', 32.00, 'EUR', 'pending', '2026-09-19', NULL, NULL, 'owner', 'https://stanomer.online/demo/invoices/struja_p10_sep.pdf', '2026-09-01 00:00:00+00', now())
    ON CONFLICT (id) DO NOTHING;

    -- --------------------------------------------------------------------------
    -- 6. Create Serbian Maintenance Requests, Charges, Messages
    -- --------------------------------------------------------------------------
    INSERT INTO public.maintenance_requests (
        id, property_id, contract_id, reporter_id, title, description, category, priority, status,
        cost_amount, settled_amount, currency, paid_by, payment_date, payment_status, created_at, updated_at
    ) VALUES
        -- MR1: Dorćol Modern (Musluk - Ödenmiş 85 EUR, Ağustos 2026)
        (v_mr1, v_p1, v_c1, v_t1, 'Curenje vode na slavini u kupatilu', 'Slavina na lavabou kaplje i voda se preliva ispod ormarića. Potrebna hitna zamena mešača ili cele slavine.', 'plumbing', 'urgent', 'resolved', 85.00, 85.00, 'EUR', 'agency', '2026-08-12 11:30:00+00', 'paid', '2026-08-10 08:30:00+00', now()),
        -- MR2: NBG Blok 21 (Isıtma/Pompa - Ödenmiş 140 EUR, Eylül 2026 Cari Ay!)
        (v_mr2, v_p3, v_c3, v_t3, 'Problem sa grejanjem - radijatori u dnevnoj sobi hladni', 'Centralno grejanje ne prolazi kroz radijatore u dnevnoj sobi. Potrebno odzračivanje ili servis cirkulacione pumpe.', 'heating', 'urgent', 'resolved', 140.00, 140.00, 'EUR', 'agency', '2026-09-02 11:00:00+00', 'paid', '2026-08-22 09:15:00+00', now()),
        -- MR3: BW Parkview (Klima - Ödenmemiş / Usta Ödemesi Bekleyen 120 EUR, Eylül 2026)
        (v_mr3, v_p5, v_c5, v_t5, 'Klima uređaj ne hladi (sumnja na curenje gasa)', 'Inverter klima duva topao vazduh, na spoljnoj jedinici čuje se zujanje. Potrebna dopuna freona.', 'electrical', 'normal', 'investigating', 120.00, 0.00, 'EUR', 'agency', '2026-09-08 11:00:00+00', 'pending_payment', '2026-09-02 11:00:00+00', now()),
        -- MR4: Exing Blok 65 (Balkon Kapısı - Kiracı Ödemiş Mahsup Onayı Bekleyen 45 EUR, Eylül 2026)
        (v_mr4, v_p4, v_c4, v_t4, 'Balkonska vrata zapinju pri otvaranju', 'PVC balkonska vrata su se blago opustila i zapinju u donjem desnom uglu okvira. Potrebno je štelovanje šarki.', 'other', 'normal', 'open', 45.00, 0.00, 'EUR', 'tenant', '2026-09-10 17:45:00+00', 'pending_agency_approval', '2026-09-10 17:45:00+00', now()),
        -- MR5: Stepa Stepanović (Kilit Değişimi - Tamamlanmış)
        (v_mr5, v_p8, v_c8, v_t8, 'Zamena sigurnosne brave na ulaznim vratima', 'Ključ povremeno zapinje u cilindru prilikom zaključavanja spolja. Majstor je preporučio zamenu cilindra radi sigurnosti.', 'other', 'normal', 'resolved', NULL, 0.00, 'EUR', NULL, NULL, 'pending_review', '2026-08-10 10:00:00+00', now())
    ON CONFLICT (id) DO NOTHING;

    -- 7. Insert Maintenance Messages (Conversation History)
    INSERT INTO public.maintenance_messages (id, request_id, user_id, sender_id, message, created_at) VALUES
        (gen_random_uuid(), v_mr1, v_t1, v_t1, 'Poštovani, slavina u kupatilu je počela jače da curi, stavio sam peškir.', '2026-08-10 08:35:00+00'),
        (gen_random_uuid(), v_mr1, p_agency_id, p_agency_id, 'Pozdrav Nikola, poslali smo majstora Sašu. Biće kod vas sutra ujutru u 10h.', '2026-08-10 09:15:00+00'),
        (gen_random_uuid(), v_mr1, v_t1, v_t1, 'Majstor je završio, stavio novu Grohe slavinu. Sve funkcioniše odlično.', '2026-08-12 11:35:00+00'),
        (gen_random_uuid(), v_mr2, v_t3, v_t3, 'Klima slabo hladi već dva dana, molim vas za servis pre najavljenog talasa vrućine.', '2026-09-09 14:35:00+00'),
        (gen_random_uuid(), v_mr2, p_agency_id, p_agency_id, 'Zdravo Stefane, zakazali smo ovlašćeni servis za sutra u 11:00h.', '2026-09-09 15:10:00+00'),
        (gen_random_uuid(), v_mr3, v_t5, v_t5, 'Problem je rešen, električar je zamenio utičnicu i osigurač. Sve funkcioniše odlično.', '2026-08-27 16:25:00+00')
    ON CONFLICT (id) DO NOTHING;

    -- 8. Insert Maintenance Charges (Paid + Unpaid / Pending)
    INSERT INTO public.maintenance_charges (
        id, maintenance_request_id, property_id, created_by, title, charge_type,
        approver_role, debtor_id, creditor_id, contractor_name, amount, settled_amount,
        currency, status, contractor_payment_status, contractor_payment_date, settlement_method,
        declared_at, approved_at, paid_at, created_at, updated_at
    ) VALUES (
        -- 1. Grohe musluk: Ödenmiş (Paid)
        gen_random_uuid(), v_mr1, v_p1, p_agency_id,
        'Nabavka Grohe slavine i rad vodoinstalatera',
        'agency_advance', 'counterparty', v_l1, p_agency_id, 'Vodoinstalater Saša Đorđević',
        85.00, 85.00, 'EUR', 'paid', 'paid', '2026-08-12 11:30:00+00', 'rent_offset',
        '2026-08-11 10:00:00+00', '2026-08-11 14:00:00+00', '2026-08-12 11:30:00+00', '2026-08-11 10:00:00+00', now()
    ), (
        -- 2. Cirkulaciona pumpa: Ödenmiş (Paid - Eylül 2026 Cari Ay)
        gen_random_uuid(), v_mr2, v_p3, p_agency_id,
        'Zamena cirkulacione pumpe i ventila',
        'agency_advance', 'counterparty', v_l2, p_agency_id, 'Termo Servis NBG',
        140.00, 140.00, 'EUR', 'paid', 'paid', '2026-09-02 11:00:00+00', 'rent_offset',
        '2026-09-01 12:00:00+00', '2026-09-01 16:00:00+00', '2026-09-02 11:00:00+00', '2026-09-01 12:00:00+00', now()
    ), (
        -- 3. Inverter klima: Ödenmemiş / Bekleyen Usta Masrafı (Pending Payment - 120 EUR)
        gen_random_uuid(), v_mr3, v_p5, p_agency_id,
        'Servis inverter klime i dopuna freona R32',
        'agency_advance', 'counterparty', v_l3, p_agency_id, 'Frigo Servis Beograd',
        120.00, 0.00, 'EUR', 'pending', 'unpaid', NULL, 'rent_offset',
        '2026-09-02 11:00:00+00', NULL, NULL, '2026-09-02 11:00:00+00', now()
    ), (
        -- 4. Balkon kapı şarki tamiri: Kiracı Ödemiş Mahsup Onayı Bekleyen (Declared - 45 EUR)
        gen_random_uuid(), v_mr4, v_p4, p_agency_id,
        'Štelovanje PVC balkonskih vrata i zamena šarki',
        'reimbursement', 'agency', v_l2, v_t4, 'Stolarija Majstor Jovan',
        45.00, 0.00, 'EUR', 'declared', 'unpaid', NULL, 'rent_offset',
        '2026-09-10 17:45:00+00', NULL, NULL, '2026-09-10 17:45:00+00', now()
    )
    ON CONFLICT (id) DO NOTHING;

    RETURN jsonb_build_object(
        'success', true,
        'agency_id', p_agency_id,
        'properties_count', 10,
        'contracts_count', 10,
        'landlords_count', 7,
        'tenants_count', 10,
        'maintenance_requests_count', 5
    );
END;
$$;

-- 3. Automatic Cleanup of Expired Demo Portfolios (TTL = 3 days)
CREATE OR REPLACE FUNCTION public.cleanup_expired_demo_data()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_rec RECORD;
    v_cleaned_count INT := 0;
BEGIN
    FOR v_rec IN
        SELECT id, company_name
        FROM public.profiles
        WHERE is_demo = TRUE
          AND demo_expires_at IS NOT NULL
          AND demo_expires_at < now()
    LOOP
        PERFORM public.clear_agency_demo_data(v_rec.id);
        UPDATE public.profiles
        SET demo_expires_at = NULL,
            updated_at = now()
        WHERE id = v_rec.id;

        v_cleaned_count := v_cleaned_count + 1;
    END LOOP;

    RETURN jsonb_build_object(
        'success', true,
        'cleaned_agencies_count', v_cleaned_count,
        'timestamp', now()
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.clear_agency_demo_data(UUID) TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.generate_agency_demo_data(UUID) TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.cleanup_expired_demo_data() TO anon, authenticated, service_role;

CREATE OR REPLACE FUNCTION public.update_agency_demo_theme(
    p_agency_id UUID,
    p_logo_url TEXT,
    p_website_url TEXT DEFAULT NULL,
    p_color_scheme JSONB DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE public.profiles
    SET logo_url = p_logo_url,
        website_url = COALESCE(p_website_url, website_url),
        color_scheme = COALESCE(p_color_scheme, color_scheme),
        updated_at = now()
    WHERE id = p_agency_id;

    RETURN jsonb_build_object(
        'success', true,
        'agency_id', p_agency_id,
        'logo_url', p_logo_url
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.update_agency_demo_theme(UUID, TEXT, TEXT, JSONB) TO anon, authenticated, service_role;

-- ==============================================================================
-- 15. Password Reset Tokens & Multilingual Password Reset Functions
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.password_reset_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT NOT NULL,
    token TEXT NOT NULL UNIQUE,
    code TEXT NOT NULL,
    attempts INTEGER NOT NULL DEFAULT 0,
    expires_at TIMESTAMPTZ NOT NULL DEFAULT (now() + interval '1 hour'),
    used_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS password_reset_tokens_email_idx ON public.password_reset_tokens (lower(email));
CREATE INDEX IF NOT EXISTS password_reset_tokens_token_idx ON public.password_reset_tokens (token);
CREATE INDEX IF NOT EXISTS password_reset_tokens_code_idx ON public.password_reset_tokens (code);

ALTER TABLE public.password_reset_tokens ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "No direct public access to password reset tokens" ON public.password_reset_tokens;
CREATE POLICY "No direct public access to password reset tokens" 
    ON public.password_reset_tokens FOR ALL TO authenticated USING (false);

CREATE OR REPLACE FUNCTION public.request_password_reset(p_email TEXT)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, extensions
AS $$
DECLARE
    v_clean_email TEXT := lower(trim(p_email));
    v_user_id UUID;
    v_provider TEXT;
    v_full_name TEXT;
    v_token TEXT := gen_random_uuid()::text;
    v_code TEXT := lpad(floor(random() * 900000 + 100000)::text, 6, '0');
BEGIN
    IF v_clean_email IS NULL OR v_clean_email = '' OR position('@' in v_clean_email) = 0 THEN
        RETURN jsonb_build_object('success', false, 'error', 'invalid_email');
    END IF;

    -- 1. Check if user exists in auth.users
    SELECT id, COALESCE(raw_app_meta_data->>'provider', 'email')
    INTO v_user_id, v_provider
    FROM auth.users
    WHERE lower(email) = v_clean_email
    LIMIT 1;

    -- 2. If not found in auth.users, check public.profiles
    IF v_user_id IS NULL THEN
        SELECT id INTO v_user_id FROM public.profiles WHERE lower(email) = v_clean_email LIMIT 1;
    END IF;

    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'user_not_found');
    END IF;

    -- 3. If user is registered only via phone or oauth without email password
    IF v_provider = 'phone' THEN
        RETURN jsonb_build_object('success', false, 'error', 'phone_user_no_email');
    END IF;

    -- 4. Get full name for personalized email
    SELECT full_name INTO v_full_name FROM public.profiles WHERE id = v_user_id;

    -- 5. Invalidate previous unused tokens for this email
    UPDATE public.password_reset_tokens
    SET used_at = now()
    WHERE lower(email) = v_clean_email AND used_at IS NULL;

    -- 6. Insert new token & 6-digit code
    INSERT INTO public.password_reset_tokens (email, token, code, expires_at)
    VALUES (v_clean_email, v_token, v_code, now() + interval '1 hour');

    RETURN jsonb_build_object(
        'success', true,
        'token', v_token,
        'code', v_code,
        'user_name', COALESCE(v_full_name, split_part(v_clean_email, '@', 1))
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.request_password_reset(TEXT) TO anon, authenticated, service_role;

CREATE OR REPLACE FUNCTION public.verify_and_reset_password(
    p_email TEXT,
    p_token_or_code TEXT,
    p_new_password TEXT
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, extensions
AS $$
DECLARE
    v_clean_email TEXT := lower(trim(p_email));
    v_input TEXT := trim(p_token_or_code);
    v_reset_row RECORD;
    v_user_id UUID;
BEGIN
    IF length(p_new_password) < 6 THEN
        RETURN jsonb_build_object('success', false, 'error', 'password_too_short');
    END IF;

    -- 1. Find valid matching token or 6-digit code
    SELECT * INTO v_reset_row
    FROM public.password_reset_tokens
    WHERE lower(email) = v_clean_email
      AND (token = v_input OR code = v_input)
      AND used_at IS NULL
      AND expires_at > now()
    ORDER BY created_at DESC
    LIMIT 1;

    IF v_reset_row IS NULL THEN
        -- Increment attempt count on active token to prevent brute force
        UPDATE public.password_reset_tokens
        SET attempts = attempts + 1,
            used_at = CASE WHEN attempts + 1 >= 5 THEN now() ELSE used_at END
        WHERE lower(email) = v_clean_email
          AND used_at IS NULL
          AND expires_at > now();

        RETURN jsonb_build_object('success', false, 'error', 'invalid_or_expired_code');
    END IF;

    -- 2. Find user in auth.users
    SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = v_clean_email LIMIT 1;

    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'user_not_found');
    END IF;

    -- 3. Update password in auth.users using bcrypt & mark email confirmed
    UPDATE auth.users
    SET encrypted_password = extensions.crypt(p_new_password, extensions.gen_salt('bf')),
        email_confirmed_at = COALESCE(email_confirmed_at, now()),
        updated_at = now()
    WHERE id = v_user_id;

    -- 4. Invalidate token
    UPDATE public.password_reset_tokens
    SET used_at = now()
    WHERE id = v_reset_row.id;

    RETURN jsonb_build_object('success', true);
END;
$$;

GRANT EXECUTE ON FUNCTION public.verify_and_reset_password(TEXT, TEXT, TEXT) TO anon, authenticated, service_role;

-- -------------------------------------------------------------
-- accept_contract RPC (Idempotent Contract Claim & Activation)
-- -------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.accept_contract(contract_token text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_contract_id UUID;
    v_property_id UUID;
    v_invitee_email TEXT;
    v_current_tenant_id UUID;
    v_current_status public.contract_status;
    v_user_id UUID;
    v_user_email TEXT;
    v_rent NUMERIC;
    v_deposit NUMERIC;
    v_currency TEXT;
    v_due_day INTEGER;
    v_start_date TIMESTAMPTZ;
    v_end_date TIMESTAMPTZ;
    v_contract_url TEXT;
BEGIN
    v_user_id := auth.uid();
    v_user_email := auth.jwt() ->> 'email';

    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- 1. Find contract by token or fallback to user email
    SELECT 
        id, property_id, invitee_email, tenant_id, status,
        monthly_rent, deposit_amount, currency, due_day, start_date, end_date, contract_url
    INTO 
        v_contract_id, v_property_id, v_invitee_email, v_current_tenant_id, v_current_status,
        v_rent, v_deposit, v_currency, v_due_day, v_start_date, v_end_date, v_contract_url
    FROM public.contracts
    WHERE (
        (contract_token IS NOT NULL AND contract_token != '' AND token = contract_token)
        OR (
            (contract_token IS NULL OR contract_token = '') 
            AND invitee_email IS NOT NULL 
            AND LOWER(invitee_email) = LOWER(v_user_email)
            AND (tenant_id IS NULL OR tenant_id = v_user_id)
        )
    )
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Contract not found or already accepted';
    END IF;

    -- 2. Idempotent check: if user already accepted this contract, succeed gracefully
    IF v_current_tenant_id = v_user_id AND v_current_status = 'active' THEN
        UPDATE public.properties
        SET tenant_id = v_user_id
        WHERE id = v_property_id AND tenant_id IS NULL;
        RETURN;
    END IF;

    -- 3. Prevent overwriting another tenant
    IF v_current_tenant_id IS NOT NULL AND v_current_tenant_id != v_user_id THEN
        RAISE EXCEPTION 'This contract is already assigned to another tenant';
    END IF;

    -- 4. Update contract status and assign tenant
    UPDATE public.contracts
    SET status = 'active',
        tenant_id = v_user_id,
        updated_at = now()
    WHERE id = v_contract_id;

    -- 5. Sync property primary tenant_id
    UPDATE public.properties
    SET tenant_id = v_user_id
    WHERE id = v_property_id;

    -- 6. Sync leases table if it exists
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'leases') THEN
        INSERT INTO public.leases (property_id, tenant_id, tenant_email, start_date, end_date, status, contract_pdf_url, invitation_token)
        VALUES (v_property_id, v_user_id, v_user_email, v_start_date::date, v_end_date::date, 'active', v_contract_url, contract_token)
        ON CONFLICT (invitation_token) DO UPDATE 
        SET tenant_id = v_user_id, status = 'active';
    END IF;

    -- 7. Sync invitations table if invitation exists
    UPDATE public.invitations
    SET status = 'accepted'
    WHERE (contract_id = v_contract_id OR token = contract_token) AND status = 'pending';
END;
$$;

GRANT ALL ON FUNCTION public.accept_contract(text) TO authenticated;
GRANT ALL ON FUNCTION public.accept_contract(text) TO service_role;

-- ACCEPT INVITATION RPC (Dual contract & invitation compatibility)
CREATE OR REPLACE FUNCTION public.accept_invitation(p_invite_token text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_property_id UUID;
    v_contract_id UUID;
    v_invitee_email TEXT;
    v_user_id UUID;
    v_user_email TEXT;
    v_start_date DATE;
    v_end_date DATE;
    v_contract_url TEXT;
BEGIN
    v_user_id := auth.uid();
    v_user_email := auth.jwt() ->> 'email';

    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    SELECT property_id, contract_id, invitee_email 
    INTO v_property_id, v_contract_id, v_invitee_email
    FROM public.invitations
    WHERE token = p_invite_token AND status = 'pending'
    FOR UPDATE;

    IF NOT FOUND THEN
        -- Fallback: check if this token exists directly in contracts table
        IF EXISTS (SELECT 1 FROM public.contracts WHERE token = p_invite_token) THEN
            PERFORM public.accept_contract(p_invite_token);
            RETURN;
        END IF;
        RAISE EXCEPTION 'Invitation not found or already accepted';
    END IF;

    -- Email soft check
    IF v_invitee_email IS NOT NULL AND v_invitee_email != '' THEN
        IF LOWER(v_invitee_email) != LOWER(COALESCE(v_user_email, ''))
           AND COALESCE(v_user_email, '') NOT LIKE '%@privaterelay.appleid.com' THEN
            RAISE EXCEPTION 'This invitation was sent to %, but you are logged in as %', 
                v_invitee_email, v_user_email;
        END IF;
    END IF;

    -- Update invitation status
    UPDATE public.invitations
    SET status = 'accepted'
    WHERE token = p_invite_token;

    -- Update contract if associated
    IF v_contract_id IS NOT NULL THEN
        SELECT start_date::date, end_date::date, contract_url
        INTO v_start_date, v_end_date, v_contract_url
        FROM public.contracts
        WHERE id = v_contract_id;

        UPDATE public.contracts
        SET status = 'active',
            tenant_id = v_user_id,
            updated_at = now()
        WHERE id = v_contract_id;
    ELSE
        SELECT start_date::date, end_date::date, contract_url
        INTO v_start_date, v_end_date, v_contract_url
        FROM public.contracts
        WHERE property_id = v_property_id AND (status IN ('pending', 'active') AND (tenant_id IS NULL OR tenant_id = v_user_id))
        ORDER BY created_at DESC
        LIMIT 1;

        UPDATE public.contracts
        SET status = 'active',
            tenant_id = v_user_id,
            updated_at = now()
        WHERE property_id = v_property_id AND (status IN ('pending', 'active') AND (tenant_id IS NULL OR tenant_id = v_user_id));
    END IF;

    -- Sync leases
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'leases') THEN
        INSERT INTO public.leases (property_id, tenant_id, tenant_email, start_date, end_date, status, contract_pdf_url, invitation_token)
        VALUES (v_property_id, v_user_id, v_user_email, v_start_date, v_end_date, 'active', v_contract_url, p_invite_token)
        ON CONFLICT (invitation_token) DO UPDATE
        SET tenant_id = v_user_id, status = 'active';
    END IF;

    -- Update property
    UPDATE public.properties
    SET tenant_id = v_user_id
    WHERE id = v_property_id;
END;
$$;

GRANT ALL ON FUNCTION public.accept_invitation(text) TO authenticated;
GRANT ALL ON FUNCTION public.accept_invitation(text) TO service_role;

-- ------------------------------------------------------------------------------
-- PORTAL FEED ACCESS LOGS (Agency Hub & Multi-Portal XML Syndication)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.portal_feed_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agency_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    directory_agency_id BIGINT REFERENCES public.agencies(id) ON DELETE SET NULL,
    portal TEXT NOT NULL,
    ip_address TEXT DEFAULT NULL,
    user_agent TEXT DEFAULT NULL,
    listing_count INTEGER NOT NULL DEFAULT 0,
    status_code INTEGER NOT NULL DEFAULT 200,
    duration_ms INTEGER DEFAULT NULL,
    error_message TEXT DEFAULT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS portal_feed_logs_agency_portal_idx
    ON public.portal_feed_logs (agency_id, portal, created_at DESC);

CREATE INDEX IF NOT EXISTS portal_feed_logs_created_at_idx
    ON public.portal_feed_logs (created_at DESC);

ALTER TABLE public.portal_feed_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "allow_insert_portal_feed_logs" ON public.portal_feed_logs;
CREATE POLICY "allow_insert_portal_feed_logs" ON public.portal_feed_logs
    FOR INSERT TO public
    WITH CHECK (true);

DROP POLICY IF EXISTS "agency_view_own_portal_feed_logs" ON public.portal_feed_logs;
CREATE POLICY "agency_view_own_portal_feed_logs" ON public.portal_feed_logs
    FOR SELECT TO authenticated
    USING (agency_id = auth.uid());

-- ----------------------------------------------------------------------------
-- PORTAL INTEGRATION REQUESTS (Agency Concierge Portal Sync Requests)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.portal_integration_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agency_id TEXT NOT NULL,
    agency_name TEXT NOT NULL,
    portal_name TEXT NOT NULL,
    contact_phone TEXT,
    contact_email TEXT,
    portal_account_ref TEXT,
    notes TEXT,
    status TEXT NOT NULL DEFAULT 'pending',
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_portal_int_req_agency_id ON public.portal_integration_requests(agency_id);
CREATE INDEX IF NOT EXISTS idx_portal_int_req_portal ON public.portal_integration_requests(portal_name);
CREATE INDEX IF NOT EXISTS idx_portal_int_req_status ON public.portal_integration_requests(status);

ALTER TABLE public.portal_integration_requests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Agencies can insert integration requests" ON public.portal_integration_requests;
CREATE POLICY "Agencies can insert integration requests"
    ON public.portal_integration_requests
    FOR INSERT
    TO public
    WITH CHECK (true);

DROP POLICY IF EXISTS "Agencies can view their own integration requests" ON public.portal_integration_requests;
CREATE POLICY "Agencies can view their own integration requests"
    ON public.portal_integration_requests
    FOR SELECT
    TO public
    USING (
        auth.uid()::text = agency_id
        OR agency_id = 'demo'
        OR auth.role() = 'service_role'
    );

-- ==========================================
-- 2.2.6 Agency Personalized Demo Sessions (Ephemeral 48h Sandbox)
-- ==========================================
CREATE TABLE IF NOT EXISTS public.agency_demo_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    token TEXT UNIQUE NOT NULL,
    agency_name TEXT NOT NULL,
    email TEXT NOT NULL,
    phone TEXT,
    city TEXT DEFAULT 'Beograd',
    expires_at TIMESTAMPTZ NOT NULL,
    last_accessed_at TIMESTAMPTZ DEFAULT now(),
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_agency_demo_sessions_token ON public.agency_demo_sessions(token);
CREATE INDEX IF NOT EXISTS idx_agency_demo_sessions_email ON public.agency_demo_sessions(email);

ALTER TABLE public.agency_demo_sessions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "agency_demo_sessions_public_insert" ON public.agency_demo_sessions;
CREATE POLICY "agency_demo_sessions_public_insert" ON public.agency_demo_sessions FOR INSERT TO public WITH CHECK (true);

DROP POLICY IF EXISTS "agency_demo_sessions_public_select" ON public.agency_demo_sessions;
CREATE POLICY "agency_demo_sessions_public_select" ON public.agency_demo_sessions FOR SELECT TO public USING (true);

DROP POLICY IF EXISTS "agency_demo_sessions_public_update" ON public.agency_demo_sessions;
CREATE POLICY "agency_demo_sessions_public_update" ON public.agency_demo_sessions FOR UPDATE TO public USING (true);

-- ==========================================
-- 2.2.7 Agency Demo Consents (ZZPL Audit Log)
-- ==========================================
CREATE TABLE IF NOT EXISTS public.agency_demo_consents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT NOT NULL,
    agency_name TEXT NOT NULL,
    phone TEXT,
    city TEXT,
    marketing_consent BOOLEAN NOT NULL DEFAULT FALSE,
    consent_text_key TEXT NOT NULL DEFAULT 'consent.marketing',
    consent_text_version TEXT NOT NULL DEFAULT 'v1.0',
    shown_locale TEXT NOT NULL DEFAULT 'sr',
    ip_address TEXT,
    user_agent TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_agency_demo_consents_email ON public.agency_demo_consents(email);
CREATE INDEX IF NOT EXISTS idx_agency_demo_consents_created_at ON public.agency_demo_consents(created_at);

ALTER TABLE public.agency_demo_consents ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "agency_demo_consents_public_insert" ON public.agency_demo_consents;
CREATE POLICY "agency_demo_consents_public_insert" ON public.agency_demo_consents FOR INSERT TO public WITH CHECK (true);

DROP POLICY IF EXISTS "agency_demo_consents_authenticated_select" ON public.agency_demo_consents;
CREATE POLICY "agency_demo_consents_authenticated_select" ON public.agency_demo_consents FOR SELECT TO authenticated USING (true);

-- ==========================================
-- 2.2.8 Agency Invoices (Stanomer Platform Faturaları)
-- ==========================================
CREATE TABLE IF NOT EXISTS public.agency_invoices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agency_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    invoice_number TEXT NOT NULL,
    period TEXT NOT NULL,
    amount NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    currency TEXT NOT NULL DEFAULT 'EUR',
    status TEXT NOT NULL DEFAULT 'paid', -- 'paid', 'pending', 'overdue'
    due_date DATE,
    paid_at TIMESTAMPTZ,
    pdf_url TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS agency_invoices_agency_id_idx ON public.agency_invoices(agency_id);
CREATE INDEX IF NOT EXISTS agency_invoices_status_idx ON public.agency_invoices(status);

ALTER TABLE public.agency_invoices ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "agency_invoices_select_policy" ON public.agency_invoices;
CREATE POLICY "agency_invoices_select_policy" ON public.agency_invoices
    FOR SELECT TO authenticated
    USING (agency_id = auth.uid() OR auth.role() = 'service_role');

DROP POLICY IF EXISTS "agency_invoices_admin_all_policy" ON public.agency_invoices;
CREATE POLICY "agency_invoices_admin_all_policy" ON public.agency_invoices
    FOR ALL TO service_role
    USING (true)
    WITH CHECK (true);

-- ==========================================
-- 2.2.8 Unified Agency Financial Ledger View (SSOT)
-- ==========================================
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

  -- Pre-calculated KPI Flags (100% SSOT with Flutter Agency Finance Tab)
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











-- =============================================================================
-- AGENCY TEAM MANAGEMENT v0 (agency_members + helper functions + RLS)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.agency_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agency_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    full_name TEXT,
    phone_number TEXT,
    member_role TEXT NOT NULL DEFAULT 'agency_operation' CHECK (member_role IN ('agency_operation')),
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'suspended', 'revoked')),
    invited_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (agency_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_agency_members_agency_id ON public.agency_members(agency_id);
CREATE INDEX IF NOT EXISTS idx_agency_members_user_id ON public.agency_members(user_id);

ALTER TABLE public.agency_members ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Agency admins and members can view memberships" ON public.agency_members;
CREATE POLICY "Agency admins and members can view memberships" ON public.agency_members
    FOR SELECT TO authenticated
    USING (agency_id = auth.uid() OR user_id = auth.uid());

DROP POLICY IF EXISTS "Agency admins can insert team members" ON public.agency_members;
CREATE POLICY "Agency admins can insert team members" ON public.agency_members
    FOR INSERT TO authenticated
    WITH CHECK (agency_id = auth.uid());

DROP POLICY IF EXISTS "Agency admins can update team members" ON public.agency_members;
CREATE POLICY "Agency admins can update team members" ON public.agency_members
    FOR UPDATE TO authenticated
    USING (agency_id = auth.uid())
    WITH CHECK (agency_id = auth.uid());

DROP POLICY IF EXISTS "Agency admins can delete team members" ON public.agency_members;
CREATE POLICY "Agency admins can delete team members" ON public.agency_members
    FOR DELETE TO authenticated
    USING (agency_id = auth.uid());

CREATE OR REPLACE FUNCTION public.effective_agency_id(p_user_id UUID DEFAULT auth.uid())
RETURNS UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(
    (
      SELECT am.agency_id
      FROM public.agency_members am
      WHERE am.user_id = p_user_id
        AND am.status = 'active'
      ORDER BY am.created_at ASC
      LIMIT 1
    ),
    p_user_id
  );
$$;

CREATE OR REPLACE FUNCTION public.is_agency_member(p_agency_id UUID, p_user_id UUID DEFAULT auth.uid())
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT p_agency_id IS NOT NULL AND (
    p_agency_id = p_user_id
    OR EXISTS (
      SELECT 1
      FROM public.agency_members am
      WHERE am.agency_id = p_agency_id
        AND am.user_id = p_user_id
        AND am.status = 'active'
    )
  );
$$;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.agency_members TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.effective_agency_id(UUID) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.is_agency_member(UUID, UUID) TO authenticated, service_role;

-- =============================================================================
-- MODULE-INDEPENDENT AGENCY TASK MANAGEMENT v0 (public.agency_tasks)
-- =============================================================================
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
    comments JSONB NOT NULL DEFAULT '[]'::jsonb,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_agency_tasks_agency_id ON public.agency_tasks(agency_id);
CREATE INDEX IF NOT EXISTS idx_agency_tasks_assigned_to ON public.agency_tasks(assigned_to);
CREATE INDEX IF NOT EXISTS idx_agency_tasks_status ON public.agency_tasks(status);
CREATE INDEX IF NOT EXISTS idx_agency_tasks_source_type ON public.agency_tasks(source_type);

ALTER TABLE public.agency_tasks ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Agency members can view agency tasks" ON public.agency_tasks;
CREATE POLICY "Agency members can view agency tasks" ON public.agency_tasks
    FOR SELECT TO authenticated
    USING (public.is_agency_member(agency_id, auth.uid()));

DROP POLICY IF EXISTS "Agency members can insert agency tasks" ON public.agency_tasks;
CREATE POLICY "Agency members can insert agency tasks" ON public.agency_tasks
    FOR INSERT TO authenticated
    WITH CHECK (
        public.is_agency_member(agency_id, auth.uid())
        AND (agency_id = auth.uid() OR assigned_to IS NULL OR assigned_to = auth.uid())
    );

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

DROP POLICY IF EXISTS "Agency admins and creators can delete agency tasks" ON public.agency_tasks;
CREATE POLICY "Agency admins and creators can delete agency tasks" ON public.agency_tasks
    FOR DELETE TO authenticated
    USING (
        public.is_agency_member(agency_id, auth.uid())
        AND (agency_id = auth.uid() OR created_by = auth.uid())
    );

GRANT SELECT, INSERT, UPDATE, DELETE ON public.agency_tasks TO authenticated, service_role;


-- ==============================================================================
-- Agency Clients & EOP (Evidencija o posredovanju) v0
-- ==============================================================================
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS registar_posrednika_no TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS pib TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS maticni_broj TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS official_address TEXT;

CREATE TABLE IF NOT EXISTS public.agency_clients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agency_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    party_type TEXT NOT NULL DEFAULT 'individual' CHECK (party_type IN ('individual', 'company')),
    full_name TEXT NOT NULL,
    jmbg_pib TEXT,
    maticni_broj TEXT,
    address TEXT,
    phone TEXT,
    email TEXT,
    notes TEXT,
    created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_agency_clients_agency_id ON public.agency_clients(agency_id);
CREATE INDEX IF NOT EXISTS idx_agency_clients_jmbg_pib ON public.agency_clients(agency_id, jmbg_pib);

ALTER TABLE public.agency_clients ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Agency members can view agency clients" ON public.agency_clients;
CREATE POLICY "Agency members can view agency clients" ON public.agency_clients
    FOR SELECT TO authenticated
    USING (public.is_agency_member(agency_id, auth.uid()));

DROP POLICY IF EXISTS "Agency members can insert agency clients" ON public.agency_clients;
CREATE POLICY "Agency members can insert agency clients" ON public.agency_clients
    FOR INSERT TO authenticated
    WITH CHECK (public.is_agency_member(agency_id, auth.uid()));

DROP POLICY IF EXISTS "Agency members can update agency clients" ON public.agency_clients;
CREATE POLICY "Agency members can update agency clients" ON public.agency_clients
    FOR UPDATE TO authenticated
    USING (public.is_agency_member(agency_id, auth.uid()))
    WITH CHECK (public.is_agency_member(agency_id, auth.uid()));

DROP POLICY IF EXISTS "Agency admins can delete agency clients" ON public.agency_clients;
CREATE POLICY "Agency admins can delete agency clients" ON public.agency_clients
    FOR DELETE TO authenticated
    USING (agency_id = auth.uid());

GRANT SELECT, INSERT, UPDATE, DELETE ON public.agency_clients TO authenticated, service_role;

ALTER TABLE public.listings ADD COLUMN IF NOT EXISTS client_id UUID REFERENCES public.agency_clients(id) ON DELETE SET NULL;
ALTER TABLE public.property_owners ADD COLUMN IF NOT EXISTS client_id UUID REFERENCES public.agency_clients(id) ON DELETE SET NULL;

CREATE TABLE IF NOT EXISTS public.eop_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agency_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    sequence_year INTEGER NOT NULL DEFAULT EXTRACT(YEAR FROM CURRENT_DATE)::INTEGER,
    sequence_number INTEGER NOT NULL,
    redni_broj TEXT NOT NULL,
    mediation_contract_no TEXT NOT NULL,
    mediation_contract_date DATE NOT NULL DEFAULT CURRENT_DATE,
    contract_valid_until DATE,
    is_exclusive BOOLEAN NOT NULL DEFAULT FALSE,
    client_role TEXT NOT NULL DEFAULT 'landlord' CHECK (client_role IN ('seller', 'buyer', 'landlord', 'tenant')),
    transaction_type TEXT NOT NULL DEFAULT 'izdavanje' CHECK (transaction_type IN ('prodaja', 'izdavanje')),
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'realized', 'cancelled')),
    cancellation_reason TEXT,
    client_id UUID REFERENCES public.agency_clients(id) ON DELETE SET NULL,
    listing_id UUID REFERENCES public.listings(id) ON DELETE SET NULL,
    property_id UUID REFERENCES public.properties(id) ON DELETE SET NULL,
    lease_contract_id UUID REFERENCES public.contracts(id) ON DELETE SET NULL,
    client_type TEXT NOT NULL DEFAULT 'individual' CHECK (client_type IN ('individual', 'company')),
    client_name_snapshot TEXT NOT NULL,
    client_jmbg_pib_snapshot TEXT,
    client_address_snapshot TEXT,
    client_phone_snapshot TEXT,
    client_email_snapshot TEXT,
    property_type_snapshot TEXT,
    property_address_snapshot TEXT NOT NULL,
    property_specs_snapshot TEXT,
    asking_price NUMERIC(12,2),
    agreed_price NUMERIC(12,2),
    currency TEXT NOT NULL DEFAULT 'EUR',
    commission_type TEXT NOT NULL DEFAULT 'percent' CHECK (commission_type IN ('percent', 'fixed')),
    commission_value NUMERIC(12,2),
    commission_currency TEXT DEFAULT 'EUR',
    realized_at DATE,
    invoice_ref TEXT,
    contract_pdf_url TEXT,
    notes TEXT,
    created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT eop_records_agency_year_seq_unique UNIQUE (agency_id, sequence_year, sequence_number)
);

CREATE INDEX IF NOT EXISTS idx_eop_records_agency_year ON public.eop_records(agency_id, sequence_year DESC, sequence_number DESC);
CREATE INDEX IF NOT EXISTS idx_eop_records_listing_id ON public.eop_records(listing_id);
CREATE INDEX IF NOT EXISTS idx_eop_records_property_id ON public.eop_records(property_id);
CREATE INDEX IF NOT EXISTS idx_eop_records_lease_contract_id ON public.eop_records(lease_contract_id);
CREATE INDEX IF NOT EXISTS idx_eop_records_client_id ON public.eop_records(client_id);
CREATE INDEX IF NOT EXISTS idx_eop_records_status ON public.eop_records(agency_id, status);

CREATE OR REPLACE FUNCTION public.assign_eop_sequence_number()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
    v_year INTEGER;
    v_next_seq INTEGER;
BEGIN
    v_year := COALESCE(NEW.sequence_year, EXTRACT(YEAR FROM COALESCE(NEW.mediation_contract_date, CURRENT_DATE))::INTEGER);
    NEW.sequence_year := v_year;
    PERFORM pg_advisory_xact_lock(hashtext(NEW.agency_id::text || ':' || v_year::text));
    IF NEW.sequence_number IS NULL OR NEW.sequence_number <= 0 THEN
        SELECT COALESCE(MAX(sequence_number), 0) + 1 INTO v_next_seq
        FROM public.eop_records WHERE agency_id = NEW.agency_id AND sequence_year = v_year;
        NEW.sequence_number := v_next_seq;
    END IF;
    NEW.redni_broj := NEW.sequence_number::text || '/' || v_year::text;
    NEW.updated_at := now();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_assign_eop_sequence_number ON public.eop_records;
CREATE TRIGGER trg_assign_eop_sequence_number
    BEFORE INSERT ON public.eop_records
    FOR EACH ROW EXECUTE FUNCTION public.assign_eop_sequence_number();

CREATE OR REPLACE FUNCTION public.protect_eop_sequence_on_update()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.sequence_year := OLD.sequence_year;
    NEW.sequence_number := OLD.sequence_number;
    NEW.redni_broj := OLD.redni_broj;
    NEW.updated_at := now();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_protect_eop_sequence_on_update ON public.eop_records;
CREATE TRIGGER trg_protect_eop_sequence_on_update
    BEFORE UPDATE ON public.eop_records
    FOR EACH ROW EXECUTE FUNCTION public.protect_eop_sequence_on_update();

ALTER TABLE public.eop_records ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Agency members can view eop records" ON public.eop_records;
CREATE POLICY "Agency members can view eop records" ON public.eop_records
    FOR SELECT TO authenticated USING (public.is_agency_member(agency_id, auth.uid()));

DROP POLICY IF EXISTS "Agency members can insert eop records" ON public.eop_records;
CREATE POLICY "Agency members can insert eop records" ON public.eop_records
    FOR INSERT TO authenticated WITH CHECK (public.is_agency_member(agency_id, auth.uid()));

DROP POLICY IF EXISTS "Agency members can update eop records" ON public.eop_records;
CREATE POLICY "Agency members can update eop records" ON public.eop_records
    FOR UPDATE TO authenticated
    USING (public.is_agency_member(agency_id, auth.uid()))
    WITH CHECK (public.is_agency_member(agency_id, auth.uid()));

GRANT SELECT, INSERT, UPDATE ON public.eop_records TO authenticated;
GRANT ALL ON public.eop_records TO service_role;


-- ==============================================================================
-- Faz 2: Module-Independent AML / SPN (ZSPNFT) Compliance Module v0
-- ==============================================================================
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS aml_officer_name TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS aml_deputy_name TEXT;

CREATE OR REPLACE FUNCTION public.try_parse_uuid(p_text TEXT)
RETURNS UUID LANGUAGE plpgsql IMMUTABLE AS $$
BEGIN
    IF p_text IS NULL OR p_text !~ '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$' THEN
        RETURN NULL;
    END IF;
    RETURN p_text::UUID;
END;
$$;

CREATE TABLE IF NOT EXISTS public.aml_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agency_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    sequence_year INTEGER NOT NULL DEFAULT EXTRACT(YEAR FROM CURRENT_DATE)::INTEGER,
    sequence_number INTEGER NOT NULL,
    aml_ref_no TEXT NOT NULL,
    client_id UUID REFERENCES public.agency_clients(id) ON DELETE SET NULL,
    eop_record_id UUID REFERENCES public.eop_records(id) ON DELETE SET NULL,
    property_id UUID REFERENCES public.properties(id) ON DELETE SET NULL,
    listing_id UUID REFERENCES public.listings(id) ON DELETE SET NULL,
    superseded_by_id UUID REFERENCES public.aml_records(id) ON DELETE SET NULL,
    party_type TEXT NOT NULL DEFAULT 'individual' CHECK (party_type IN ('individual', 'company')),
    client_name_snapshot TEXT NOT NULL,
    jmbg_pib_snapshot TEXT,
    maticni_broj_snapshot TEXT,
    id_doc_type TEXT CHECK (id_doc_type IS NULL OR id_doc_type IN ('licna_karta', 'pasos', 'boravisna', 'apr_izvod', 'other')),
    id_doc_number TEXT,
    id_doc_issuer TEXT,
    id_doc_expiry DATE,
    birth_date DATE,
    citizenship TEXT,
    residency_country TEXT DEFAULT 'RS',
    address_snapshot TEXT,
    phone_snapshot TEXT,
    email_snapshot TEXT,
    occupation_or_activity TEXT,
    is_pep BOOLEAN NOT NULL DEFAULT FALSE,
    pep_details TEXT,
    ubo_list JSONB NOT NULL DEFAULT '[]'::jsonb,
    ubo_unclear BOOLEAN NOT NULL DEFAULT FALSE,
    acts_on_behalf_of_third_party BOOLEAN NOT NULL DEFAULT FALSE,
    third_party_details TEXT,
    transaction_type TEXT NOT NULL DEFAULT 'prodaja' CHECK (transaction_type IN ('prodaja', 'izdavanje')),
    transaction_value_eur NUMERIC(14,2),
    transaction_date DATE NOT NULL DEFAULT CURRENT_DATE,
    payment_method TEXT NOT NULL DEFAULT 'bank_transfer' CHECK (payment_method IN ('bank_transfer', 'cash', 'mixed', 'crypto')),
    source_of_funds_category TEXT CHECK (source_of_funds_category IS NULL OR source_of_funds_category IN ('salary', 'savings', 'property_sale', 'loan', 'business', 'inheritance', 'other')),
    source_of_funds TEXT,
    purpose_of_relationship TEXT,
    high_risk_country_involved BOOLEAN NOT NULL DEFAULT FALSE,
    risk_score INTEGER NOT NULL DEFAULT 0 CHECK (risk_score >= 0 AND risk_score <= 100),
    risk_level TEXT NOT NULL DEFAULT 'low' CHECK (risk_level IN ('low', 'medium', 'high')),
    risk_factors JSONB NOT NULL DEFAULT '[]'::jsonb,
    enhanced_due_diligence_notes TEXT,
    next_review_at DATE,
    status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'approved', 'rejected', 'superseded')),
    is_locked BOOLEAN NOT NULL DEFAULT FALSE,
    locked_at TIMESTAMPTZ,
    locked_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    retention_until DATE,
    decision_notes TEXT,
    created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT aml_records_agency_year_seq_unique UNIQUE (agency_id, sequence_year, sequence_number)
);

CREATE INDEX IF NOT EXISTS idx_aml_records_agency_year ON public.aml_records(agency_id, sequence_year DESC, sequence_number DESC);
CREATE INDEX IF NOT EXISTS idx_aml_records_client_id ON public.aml_records(client_id);
CREATE INDEX IF NOT EXISTS idx_aml_records_eop_record_id ON public.aml_records(eop_record_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_aml_one_draft_per_eop
    ON public.aml_records(eop_record_id)
    WHERE eop_record_id IS NOT NULL AND status = 'draft';
CREATE UNIQUE INDEX IF NOT EXISTS idx_aml_one_final_per_eop
    ON public.aml_records(eop_record_id)
    WHERE eop_record_id IS NOT NULL AND status IN ('approved', 'rejected');
CREATE INDEX IF NOT EXISTS idx_aml_records_property_id ON public.aml_records(property_id);
CREATE INDEX IF NOT EXISTS idx_aml_records_listing_id ON public.aml_records(listing_id);
CREATE INDEX IF NOT EXISTS idx_aml_records_status_risk ON public.aml_records(agency_id, status, risk_level);
CREATE INDEX IF NOT EXISTS idx_aml_records_retention ON public.aml_records(agency_id, is_locked, retention_until);

CREATE TABLE IF NOT EXISTS public.aml_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agency_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    aml_record_id UUID NOT NULL REFERENCES public.aml_records(id) ON DELETE CASCADE,
    doc_type TEXT NOT NULL DEFAULT 'id_card' CHECK (doc_type IN ('id_card', 'passport', 'apr_extract', 'ubo_declaration', 'source_of_funds', 'signed_upitnik', 'sanctions_check', 'other')),
    file_name TEXT NOT NULL,
    storage_path TEXT NOT NULL,
    mime_type TEXT,
    file_size_bytes BIGINT,
    uploaded_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_aml_documents_record_id ON public.aml_documents(aml_record_id);
CREATE INDEX IF NOT EXISTS idx_aml_documents_agency_id ON public.aml_documents(agency_id);

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('aml-documents', 'aml-documents', false, 10485760, ARRAY['application/pdf', 'image/jpeg', 'image/png', 'image/webp'])
ON CONFLICT (id) DO UPDATE SET public = false, file_size_limit = 10485760, allowed_mime_types = ARRAY['application/pdf', 'image/jpeg', 'image/png', 'image/webp'];
