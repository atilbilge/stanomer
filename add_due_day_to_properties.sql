-- Add due_day column to properties table
ALTER TABLE public.properties 
ADD COLUMN IF NOT EXISTS due_day INTEGER DEFAULT 1 CHECK (due_day >= 1 AND due_day <= 31);

-- Update existing properties to have a default due_day of 1
UPDATE public.properties SET due_day = 1 WHERE due_day IS NULL;
