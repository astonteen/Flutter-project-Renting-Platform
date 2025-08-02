-- Fix current_leg check constraint violation
-- The trigger function is inserting 'pending_assignment' but the constraint only allows
-- 'pickup', 'delivery', 'return_pickup', 'return_delivery'

-- Update the check constraint to include 'pending_assignment'
ALTER TABLE public.deliveries 
DROP CONSTRAINT IF EXISTS deliveries_current_leg_check;

ALTER TABLE public.deliveries 
ADD CONSTRAINT deliveries_current_leg_check 
CHECK (current_leg IN ('pending_assignment', 'pickup', 'delivery', 'return_pickup', 'return_delivery'));

-- Add comment for clarity
COMMENT ON CONSTRAINT deliveries_current_leg_check ON public.deliveries IS 
'Ensures current_leg has valid values including pending_assignment for initial state';

-- Verify the constraint was updated successfully
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.check_constraints 
    WHERE constraint_name = 'deliveries_current_leg_check' 
    AND check_clause LIKE '%pending_assignment%'
  ) THEN
    RAISE NOTICE 'SUCCESS: Check constraint updated to include pending_assignment';
  ELSE
    RAISE EXCEPTION 'FAILED: Check constraint was not updated properly';
  END IF;
END $$;