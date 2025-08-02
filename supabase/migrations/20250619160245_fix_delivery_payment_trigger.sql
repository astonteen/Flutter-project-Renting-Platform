-- Fix the delivery trigger function that references non-existent fields
-- The previous trigger tried to access NEW.delivery_address and NEW.delivery_instructions
-- but these fields don't exist in the rentals table

-- Drop the existing trigger and function
DROP TRIGGER IF EXISTS auto_create_delivery_job ON public.rentals;
DROP FUNCTION IF EXISTS create_delivery_job_for_rental();

-- Create a simplified version that works with existing schema
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
      -- Get pickup address from item owner's location
      COALESCE(
        (SELECT i.location FROM public.items i WHERE i.id = NEW.item_id),
        'Pickup location to be provided'
      ),
      -- Use placeholder for delivery address (will be updated when customer provides it)
      'Customer delivery address to be provided',
      15.00, -- Default delivery fee
      'available',
      'pickup_delivery',
      30, -- 30 minutes default
      5.0, -- 5km default distance
      12.0, -- Driver gets 80% of delivery fee
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

COMMENT ON FUNCTION create_delivery_job_for_rental() IS 'Fixed trigger function that works with existing rentals table schema';
