-- Migration: Add detailed listing parameters and property metrics
-- Target: Dev Supabase (thvbpifahvasyzmngpzp)
-- Safe, idempotent migration script

DO $$
BEGIN
    -- 1. Detailed Mode Flag
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'properties' AND column_name = 'is_detailed') THEN
        ALTER TABLE public.properties ADD COLUMN is_detailed BOOLEAN DEFAULT FALSE;
    END IF;

    -- 2. Property Type (apartment, house, commercial, garage)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'properties' AND column_name = 'property_type') THEN
        ALTER TABLE public.properties ADD COLUMN property_type TEXT DEFAULT 'apartment';
    END IF;

    -- 3. Unit / Flat Number
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'properties' AND column_name = 'unit_number') THEN
        ALTER TABLE public.properties ADD COLUMN unit_number TEXT;
    END IF;

    -- 4. Room Count (Struktura: studio, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 5.0+)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'properties' AND column_name = 'room_count') THEN
        ALTER TABLE public.properties ADD COLUMN room_count TEXT;
    END IF;

    -- 5. Area in Sqm (Površina m²)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'properties' AND column_name = 'area_sqm') THEN
        ALTER TABLE public.properties ADD COLUMN area_sqm NUMERIC(10,2);
    END IF;

    -- 6. Floor (Bulunduğu Kat: bodrum, suteren, prizemlje, 1, 2, 3, 4+...)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'properties' AND column_name = 'floor') THEN
        ALTER TABLE public.properties ADD COLUMN floor TEXT;
    END IF;

    -- 7. Total Building Floors (Bina Toplam Kat)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'properties' AND column_name = 'total_floors') THEN
        ALTER TABLE public.properties ADD COLUMN total_floors INT;
    END IF;

    -- 8. Furnishing (Nameštenost: furnished, semi_furnished, unfurnished)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'properties' AND column_name = 'furnishing') THEN
        ALTER TABLE public.properties ADD COLUMN furnishing TEXT;
    END IF;

    -- 9. Heating Type (Grejanje: cg, eg, gas, underfloor, ta, other)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'properties' AND column_name = 'heating_type') THEN
        ALTER TABLE public.properties ADD COLUMN heating_type TEXT;
    END IF;

    -- 10. Featured Amenities (Dodatno: JSONB array of strings)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'properties' AND column_name = 'amenities') THEN
        ALTER TABLE public.properties ADD COLUMN amenities JSONB DEFAULT '[]'::jsonb;
    END IF;

    -- 11. Extended Description / Notes (Opis)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'properties' AND column_name = 'description') THEN
        ALTER TABLE public.properties ADD COLUMN description TEXT;
    END IF;
END $$;
