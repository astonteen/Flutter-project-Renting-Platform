-- Add unique constraint on rental_id in deliveries table
-- This is needed for ON CONFLICT (rental_id) statements to work
-- Each rental should only have one delivery record

-- Add unique constraint on rental_id
ALTER TABLE public.deliveries 
ADD CONSTRAINT deliveries_rental_id_unique UNIQUE (rental_id);

-- Add comment for clarity
COMMENT ON CONSTRAINT deliveries_rental_id_unique ON public.deliveries IS 
'Ensures each rental can have only one delivery record. Required for ON CONFLICT (rental_id) operations.';
