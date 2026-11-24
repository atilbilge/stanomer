-- ==============================================================================
-- STANOMER DATABASE MIGRATION - AGENCY HUB & MULTI-PORTAL XML SYNC
-- Date: 2026-11-15
-- Target: Dev Supabase (thvbpifahvasyzmngpzp) — Ready for Production Promotion
-- Checkpoint Tag: pre-agency-hub-xml-sync
-- Description:
--   1. Zero modifications to `public.properties` or `public.properties_with_names`
--      (complete isolation from active rental management & private landlord data).
--   2. Creates `public.listings` table dedicated to public real estate
--      listings (apartments, houses, land/plots, commercial, garages) and
--      multi-portal XML syndication (4zida, Halo Oglasi, Sasomange, Nekretnine.rs).
--   3. Creates `public.listing_images` table (1:N ordered photos with cover flag)
--      and RLS policies for public XML feed access & agency management.
--   4. Creates `property-photos` public storage bucket and storage RLS policies.
--   5. Bridges `public.agencies` & `public.view_clean_agencies` directory tables
--      with `public.profiles` (`profile_id`, `slug`, `logo_url`).
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. CREATE public.listings TABLE
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.listings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agency_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    directory_agency_id BIGINT REFERENCES public.agencies(id) ON DELETE SET NULL,
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
    published_portals JSONB NOT NULL DEFAULT '["stanomer", "4zida", "halooglasi", "sasomange", "nekretnine"]'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes for fast XML Feed and Directory queries
CREATE INDEX IF NOT EXISTS listings_agency_published_idx
    ON public.listings (agency_id, is_published)
    WHERE is_published = TRUE;

CREATE INDEX IF NOT EXISTS listings_city_municipality_idx
    ON public.listings (city, municipality)
    WHERE is_published = TRUE;

CREATE INDEX IF NOT EXISTS listings_external_ref_idx
    ON public.listings (agency_id, external_ref);

-- Trigger to auto-update updated_at
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'update_updated_at_column') THEN
        DROP TRIGGER IF EXISTS set_listings_updated_at ON public.listings;
        CREATE TRIGGER set_listings_updated_at
            BEFORE UPDATE ON public.listings
            FOR EACH ROW
            EXECUTE FUNCTION public.update_updated_at_column();
    END IF;
END $$;

ALTER TABLE public.listings ENABLE ROW LEVEL SECURITY;

-- Public (anonymous XML feed readers & website visitors) can view published listings
DROP POLICY IF EXISTS "public_select_published_listings" ON public.listings;
CREATE POLICY "public_select_published_listings" ON public.listings
    FOR SELECT TO public
    USING (is_published = TRUE);

-- Agencies have full CRUD access to their own listings
DROP POLICY IF EXISTS "agency_select_own_listings" ON public.listings;
CREATE POLICY "agency_select_own_listings" ON public.listings
    FOR SELECT TO authenticated
    USING (agency_id = auth.uid());

DROP POLICY IF EXISTS "agency_insert_own_listings" ON public.listings;
CREATE POLICY "agency_insert_own_listings" ON public.listings
    FOR INSERT TO authenticated
    WITH CHECK (agency_id = auth.uid());

DROP POLICY IF EXISTS "agency_update_own_listings" ON public.listings;
CREATE POLICY "agency_update_own_listings" ON public.listings
    FOR UPDATE TO authenticated
    USING (agency_id = auth.uid())
    WITH CHECK (agency_id = auth.uid());

DROP POLICY IF EXISTS "agency_delete_own_listings" ON public.listings;
CREATE POLICY "agency_delete_own_listings" ON public.listings
    FOR DELETE TO authenticated
    USING (agency_id = auth.uid());

-- ------------------------------------------------------------------------------
-- 2. CREATE public.listing_images TABLE & RLS POLICIES
-- ------------------------------------------------------------------------------
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

-- Public can view images of published listings
DROP POLICY IF EXISTS "public_view_published_listing_images" ON public.listing_images;
CREATE POLICY "public_view_published_listing_images" ON public.listing_images
    FOR SELECT TO public
    USING (
        EXISTS (
            SELECT 1 FROM public.listings l
            WHERE l.id = listing_images.listing_id
              AND l.is_published = TRUE
        )
    );

-- Authenticated agency can view all images of their own listings
DROP POLICY IF EXISTS "agency_view_own_listing_images" ON public.listing_images;
CREATE POLICY "agency_view_own_listing_images" ON public.listing_images
    FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.listings l
            WHERE l.id = listing_images.listing_id
              AND (l.agency_id = auth.uid() OR l.is_published = TRUE)
        )
    );

-- Agency can insert/update/delete images of their own listings
DROP POLICY IF EXISTS "agency_manage_own_listing_images" ON public.listing_images;
CREATE POLICY "agency_manage_own_listing_images" ON public.listing_images
    FOR ALL TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.listings l
            WHERE l.id = listing_images.listing_id
              AND l.agency_id = auth.uid()
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.listings l
            WHERE l.id = listing_images.listing_id
              AND l.agency_id = auth.uid()
        )
    );

-- ------------------------------------------------------------------------------
-- 3. BRIDGE DIRECTORY AGENCIES TABLE WITH PROFILES (`profile_id`, `slug`, `logo_url`)
-- ------------------------------------------------------------------------------
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public'
          AND table_name = 'agencies'
          AND table_type = 'BASE TABLE'
    ) THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'agencies' AND column_name = 'profile_id') THEN
            ALTER TABLE public.agencies ADD COLUMN profile_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'agencies' AND column_name = 'slug') THEN
            ALTER TABLE public.agencies ADD COLUMN slug TEXT DEFAULT NULL;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'agencies' AND column_name = 'logo_url') THEN
            ALTER TABLE public.agencies ADD COLUMN logo_url TEXT DEFAULT NULL;
        END IF;
    END IF;
END $$;

-- ------------------------------------------------------------------------------
-- 4. STORAGE BUCKET: property-photos
-- ------------------------------------------------------------------------------
INSERT INTO storage.buckets (id, name, public)
VALUES ('property-photos', 'property-photos', true)
ON CONFLICT (id) DO UPDATE SET public = true;

DROP POLICY IF EXISTS "Public read access for property-photos" ON storage.objects;
CREATE POLICY "Public read access for property-photos" ON storage.objects
    FOR SELECT TO public
    USING (bucket_id = 'property-photos');

DROP POLICY IF EXISTS "Authenticated users can upload property-photos" ON storage.objects;
CREATE POLICY "Authenticated users can upload property-photos" ON storage.objects
    FOR INSERT TO authenticated
    WITH CHECK (bucket_id = 'property-photos' AND auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Authenticated users can update property-photos" ON storage.objects;
CREATE POLICY "Authenticated users can update property-photos" ON storage.objects
    FOR UPDATE TO authenticated
    USING (bucket_id = 'property-photos' AND auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Authenticated users can delete property-photos" ON storage.objects;
CREATE POLICY "Authenticated users can delete property-photos" ON storage.objects
    FOR DELETE TO authenticated
    USING (bucket_id = 'property-photos' AND auth.uid() IS NOT NULL);

NOTIFY pgrst, 'reload schema';

-- ==============================================================================
-- END OF MIGRATION
-- ==============================================================================
