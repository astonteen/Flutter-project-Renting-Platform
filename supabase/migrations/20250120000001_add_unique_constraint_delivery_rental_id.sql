-- Add unique constraint on rental_id in deliveries table
-- This is needed for ON CONFLICT (rental_id) statements to work
-- Each rental should only have one delivery record
-- This fixes the PostgrestException: "there is no unique or exclusion constraint matching the ON CONFLICT specification"

-- Add unique constraint on rental_id
ALTER TABLE public.deliveries 
ADD CONSTRAINT deliveries_rental_id_unique UNIQUE (rental_id);

-- Add comment for clarity
COMMENT ON CONSTRAINT deliveries_rental_id_unique ON public.deliveries IS 
'Ensures each rental can have only one delivery record. Required for ON CONFLICT (rental_id) operations.';

-- Verify the constraint was added successfully
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'deliveries_rental_id_unique' 
    AND table_name = 'deliveries'
  ) THEN
    RAISE NOTICE 'SUCCESS: Unique constraint deliveries_rental_id_unique has been added to deliveries table';
  ELSE
    RAISE EXCEPTION 'FAILED: Unique constraint was not created properly';
  END IF;
END $$;