-- Fix delivery trigger to use renter's saved address instead of placeholder
-- This ensures delivery addresses are properly populated when delivery jobs are created

-- Drop the existing trigger and function
DROP TRIGGER IF EXISTS auto_create_delivery_job ON public.rentals;
DROP FUNCTION IF EXISTS create_delivery_job_for_rental();

-- Create improved trigger function that uses renter's saved address
CREATE OR REPLACE FUNCTION create_delivery_job_for_rental()
RETURNS TRIGGER AS $$
DECLARE
  dropoff_addr TEXT;
BEGIN
  -- Only create delivery job if delivery is required
  IF NEW.delivery_required = TRUE THEN
    
    -- Get the renter's default saved address
    SELECT CONCAT_WS(', ',
      address_line_1,
      CASE WHEN address_line_2 IS NOT NULL AND address_line_2 != '' THEN address_line_2 END,
      city,
      state,
      postal_code,
      country
    ) INTO dropoff_addr
    FROM public.saved_addresses 
    WHERE user_id = NEW.renter_id AND is_default = true
    LIMIT 1;
    
    -- If no saved address found, use placeholder
    IF dropoff_addr IS NULL OR dropoff_addr = '' THEN
      dropoff_addr := 'Customer delivery address to be provided';
    END IF;
    
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
      special_instructions,
      lender_approval_required,
      estimated_pickup_time
    ) VALUES (
      NEW.id,
      -- Get pickup address from item owner's location or profile
      COALESCE(
        (SELECT i.location FROM public.items i WHERE i.id = NEW.item_id),
        (SELECT location FROM public.profiles WHERE id = NEW.owner_id),
        'Pickup location to be provided'
      ),
      dropoff_addr, -- Use the renter's saved address or placeholder
      15.00, -- Default delivery fee
      'pending_approval', -- Require approval before making available to drivers
      'pickup_delivery',
      30, -- 30 minutes default
      5.0, -- 5km default distance
      12.0, -- Driver gets 80% of delivery fee (15.00 * 0.8)
      'Please handle with care',
      true, -- Require lender approval
      -- Set estimated pickup time to 1 day before rental start (can be adjusted)
      NEW.start_date - INTERVAL '1 day'
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Recreate the trigger with the improved function
CREATE TRIGGER auto_create_delivery_job
AFTER INSERT ON public.rentals
FOR EACH ROW EXECUTE FUNCTION create_delivery_job_for_rental();

-- Add comment for documentation
COMMENT ON FUNCTION create_delivery_job_for_rental() IS 'Improved trigger function that uses renter saved address for delivery dropoff location';

-- Update existing delivery records that have placeholder addresses
UPDATE public.deliveries 
SET dropoff_address = (
  SELECT CONCAT_WS(', ',
    sa.address_line_1,
    CASE WHEN sa.address_line_2 IS NOT NULL AND sa.address_line_2 != '' THEN sa.address_line_2 END,
    sa.city,
    sa.state,
    sa.postal_code,
    sa.country
  )
  FROM public.rentals r
  JOIN public.saved_addresses sa ON r.renter_id = sa.user_id AND sa.is_default = true
  WHERE r.id = deliveries.rental_id
)
WHERE dropoff_address = 'Customer delivery address to be provided'
  AND EXISTS (
    SELECT 1 FROM public.rentals r
    JOIN public.saved_addresses sa ON r.renter_id = sa.user_id AND sa.is_default = true
    WHERE r.id = deliveries.rental_id
  );