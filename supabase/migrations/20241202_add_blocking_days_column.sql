-- Migration: Add blocking_days column to items table
-- This allows lenders to configure how many days after rental completion
-- the item should remain blocked for return processing

-- Add blocking_days column with default value of 1 day
ALTER TABLE public.items 
ADD COLUMN IF NOT EXISTS blocking_days INTEGER DEFAULT 1;

-- Add constraint to ensure blocking_days is reasonable (0-30 days)
ALTER TABLE public.items 
ADD CONSTRAINT check_blocking_days_range 
CHECK (blocking_days >= 0 AND blocking_days <= 30);

-- Add comment for documentation
COMMENT ON COLUMN public.items.blocking_days IS 'Number of days to block item after rental completion for return processing (0-30 days)';

-- Update existing items to have the default value
UPDATE public.items SET blocking_days = 1 WHERE blocking_days IS NULL; 