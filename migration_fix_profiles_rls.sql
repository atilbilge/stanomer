-- 1. Add missing updated_at and email columns
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT now();
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS email TEXT;

-- 2. Enable RLS on profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- 2. Allow users to insert their own profile
-- This is necessary during onboarding when a user picks their first role.
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
CREATE POLICY "Users can insert their own profile" ON public.profiles
    FOR INSERT 
    WITH CHECK (auth.uid() = id);

-- 3. Allow users to update their own profile
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
CREATE POLICY "Users can update their own profile" ON public.profiles
    FOR UPDATE 
    USING (auth.uid() = id);

-- 4. Ensure everyone can see profiles (required for property joins etc.)
-- This policy might already exist, but ensuring it is robust.
DROP POLICY IF EXISTS "Authenticated users can see all profiles" ON public.profiles;
CREATE POLICY "Authenticated users can see all profiles" ON public.profiles
    FOR SELECT
    TO authenticated
    USING (true);
