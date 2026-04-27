-- Migration to add profile details to the profiles table
-- Created at: 2026-04-26 23:20:00

ALTER TABLE IF EXISTS public.profiles 
ADD COLUMN IF NOT EXISTS phone_number TEXT,
ADD COLUMN IF NOT EXISTS about TEXT,
ADD COLUMN IF NOT EXISTS office_address TEXT,
ADD COLUMN IF NOT EXISTS specialties TEXT[] DEFAULT '{}';

-- Optional: Add indexes for search if needed
-- CREATE INDEX IF NOT EXISTS profiles_phone_number_idx ON public.profiles(phone_number);
