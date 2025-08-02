-- Fix delivery trigger function that references non-existent delivery_address field
-- This migration ensures the correct trigger function is in place
-- Date: 2025-01-20

-- Drop the existing problematic trigger and function
DROP TRIGGER IF EXISTS auto_create_delivery_job ON public.rentals;
DROP FUNCTION IF EXISTS create_delivery_job_for_rental();

-- Create the corrected trigger function that doesn't reference delivery_address
CREATE OR REPLACE FUNCTION create_delivery_job_for_rental()
RETURNS TRIGGER AS $$
BEGIN
  -- Only create delivery job if delivery is required
  IF NEW.delivery_required = TRUE THEN
    INSERT INTO public.deliveries (
      rental_id,
      pickup_address,
      dropoff_address,
      fee,
      status,
      delivery_type,
      estimated_duration,
      distance_km,
      driver_earnings,
      special_instructions
    ) VALUES (
      NEW.id,
      -- Get pickup address from item owner's location or profile
      COALESCE(
        (SELECT i.location FROM public.items i WHERE i.id = NEW.item_id),
        (SELECT location FROM public.profiles WHERE id = NEW.owner_id),
        'Pickup location to be provided'
      ),
      -- Use placeholder for delivery address (will be updated when customer provides it)
      'Customer delivery address to be provided',
      15.00, -- Default delivery fee
      'available',
      'pickup_delivery',
      30, -- 30 minutes default
      5.0, -- 5km default distance
      12.0, -- Driver gets 80% of delivery fee (15.00 * 0.8)
      'Please handle with care'
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Recreate the trigger with the fixed function
CREATE TRIGGER auto_create_delivery_job
AFTER INSERT ON public.rentals
FOR EACH ROW EXECUTE FUNCTION create_delivery_job_for_rental();

-- Add comment for documentation
COMMENT ON FUNCTION create_delivery_job_for_rental() IS 'Fixed trigger function that works with existing rentals table schema without referencing delivery_address field';

-- Verify the fix by checking if the function exists
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'create_delivery_job_for_rental') THEN
    RAISE NOTICE 'SUCCESS: create_delivery_job_for_rental function has been fixed and recreated';
  ELSE
    RAISE EXCEPTION 'ERROR: Failed to create create_delivery_job_for_rental function';
  END IF;
END $$;