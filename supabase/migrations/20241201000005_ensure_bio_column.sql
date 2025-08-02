-- Ensure bio column exists in profiles table
-- This migration is safe to run multiple times

-- Add bio column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' 
        AND column_name = 'bio'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.profiles ADD COLUMN bio TEXT;
        RAISE NOTICE 'Added bio column to profiles table';
    ELSE
        RAISE NOTICE 'Bio column already exists in profiles table';
    END IF;
END $$; 