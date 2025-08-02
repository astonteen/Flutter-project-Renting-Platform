-- Fix Delivery Timing Issue
-- This migration fixes the issue where drivers can be called before the booking start date
-- by adding proper date validation and scheduling logic

-- Drop the existing problematic trigger and function
DROP TRIGGER IF EXISTS auto_create_delivery_job ON public.rentals;
DROP FUNCTION IF EXISTS create_delivery_job_for_rental();

-- Create the improved trigger function with proper status management
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
      -- Use placeholder for delivery address (will be updated when customer provides it)
      'Customer delivery address to be provided',
      15.00, -- Default delivery fee
      'pending_approval', -- Changed from 'available' to prevent immediate driver assignment
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

-- Recreate the trigger with the fixed function
CREATE TRIGGER auto_create_delivery_job
AFTER INSERT ON public.rentals
FOR EACH ROW EXECUTE FUNCTION create_delivery_job_for_rental();

-- Create function to make deliveries available at appropriate time
CREATE OR REPLACE FUNCTION make_deliveries_available()
RETURNS INTEGER AS $$
DECLARE
  v_updated_count INTEGER := 0;
  v_max_days_early INTEGER := 2; -- Maximum days before rental start to make delivery available
BEGIN
  -- Update deliveries to 'approved' status when they're within the appropriate timeframe
  -- This considers both lender approval and timing
  UPDATE public.deliveries 
  SET 
    status = 'approved',
    updated_at = NOW()
  FROM public.rentals r
  WHERE 
    deliveries.rental_id = r.id
    AND deliveries.status = 'pending_approval'
    AND deliveries.lender_approved_at IS NOT NULL  -- Lender has approved
    AND r.start_date <= NOW() + (v_max_days_early || ' days')::INTERVAL  -- Within delivery window
    AND r.start_date > NOW() - INTERVAL '1 day'; -- Not past rental dates
  
  GET DIAGNOSTICS v_updated_count = ROW_COUNT;
  
  RETURN v_updated_count;
END;
$$ LANGUAGE plpgsql;

-- Create function to handle delivery approval by lender
CREATE OR REPLACE FUNCTION approve_delivery_request(p_delivery_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  v_rental_start_date TIMESTAMP;
  v_max_days_early INTEGER := 2;
BEGIN
  -- Get the rental start date
  SELECT r.start_date INTO v_rental_start_date
  FROM public.deliveries d
  JOIN public.rentals r ON d.rental_id = r.id
  WHERE d.id = p_delivery_id;
  
  -- Update delivery with lender approval
  UPDATE public.deliveries
  SET 
    lender_approved_at = NOW(),
    updated_at = NOW(),
    -- Only set to 'approved' if within delivery window, otherwise keep as 'pending_approval'
    status = CASE 
      WHEN v_rental_start_date <= NOW() + (v_max_days_early || ' days')::INTERVAL 
      THEN 'approved'
      ELSE 'pending_approval'
    END
  WHERE id = p_delivery_id;
  
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

-- Add comment for documentation
COMMENT ON FUNCTION create_delivery_job_for_rental() IS 'Fixed delivery creation function that prevents premature driver assignment by using proper status management';
COMMENT ON FUNCTION make_deliveries_available() IS 'Function to transition approved deliveries to available status at appropriate times';
COMMENT ON FUNCTION approve_delivery_request(UUID) IS 'Function to handle lender approval of delivery requests with proper timing validation';

-- Verify the functions exist
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'create_delivery_job_for_rental') AND
     EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'make_deliveries_available') AND
     EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'approve_delivery_request') THEN
    RAISE NOTICE 'SUCCESS: All delivery timing functions have been created successfully';
  ELSE
    RAISE EXCEPTION 'ERROR: Failed to create one or more delivery timing functions';
  END IF;
END $$;