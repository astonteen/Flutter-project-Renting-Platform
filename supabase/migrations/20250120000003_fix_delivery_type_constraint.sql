-- Fix delivery_type check constraint violation
-- The trigger function is inserting 'pickup_and_delivery' but the constraint only allows
-- 'pickup_delivery' and 'return_pickup'

-- Update the check constraint to include 'pickup_and_delivery'
ALTER TABLE public.deliveries 
DROP CONSTRAINT IF EXISTS deliveries_delivery_type_check;

ALTER TABLE public.deliveries 
ADD CONSTRAINT deliveries_delivery_type_check 
CHECK (delivery_type IN ('pickup_delivery', 'return_pickup', 'pickup_and_delivery'));

-- Add comment for clarity
COMMENT ON CONSTRAINT deliveries_delivery_type_check ON public.deliveries IS 
'Ensures delivery_type has valid values including pickup_and_delivery for combined pickup and delivery operations';

-- Verify the constraint was updated successfully
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.check_constraints 
    WHERE constraint_name = 'deliveries_delivery_type_check' 
    AND check_clause LIKE '%pickup_and_delivery%'
  ) THEN
    RAISE NOTICE 'SUCCESS: Check constraint updated to include pickup_and_delivery';
  ELSE
    RAISE EXCEPTION 'FAILED: Check constraint was not updated properly';
  END IF;
END $$;