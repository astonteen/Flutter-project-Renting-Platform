-- Fix delivery constraint to allow both pickup and return deliveries per rental
-- The current unique constraint on rental_id prevents return deliveries
-- We need to allow one pickup_delivery and one return_pickup per rental

-- Drop the overly restrictive constraint
ALTER TABLE public.deliveries 
DROP CONSTRAINT IF EXISTS deliveries_rental_id_unique;

-- Add a proper constraint that allows one pickup and one return per rental
ALTER TABLE public.deliveries 
ADD CONSTRAINT deliveries_rental_delivery_type_unique 
UNIQUE (rental_id, delivery_type);

-- Add comment for clarity
COMMENT ON CONSTRAINT deliveries_rental_delivery_type_unique ON public.deliveries IS 
'Allows one pickup_delivery and one return_pickup per rental. Each rental can have both types of deliveries.';

-- Verify the constraint was updated successfully
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'deliveries_rental_delivery_type_unique' 
    AND table_name = 'deliveries'
  ) THEN
    RAISE NOTICE 'SUCCESS: Updated constraint to allow pickup and return deliveries per rental';
  ELSE
    RAISE EXCEPTION 'FAILED: Constraint was not updated properly';
  END IF;
END $$; 