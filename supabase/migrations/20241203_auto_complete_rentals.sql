-- Migration: Auto-complete rentals after end date to trigger return buffer
-- This ensures that return buffers (auto-blocks) are automatically created
-- when rentals end, without requiring manual intervention

-- Function to automatically complete rentals that have ended
CREATE OR REPLACE FUNCTION auto_complete_expired_rentals() RETURNS INTEGER AS $$
DECLARE
  v_updated_count INTEGER := 0;
BEGIN
  -- Update rentals that have ended but are still in 'inProgress' status
  -- Add a small buffer (2 hours) to account for timezone differences and late returns
  UPDATE public.rentals 
  SET 
    status = 'completed',
    updated_at = NOW()
  WHERE 
    status = 'inProgress' 
    AND end_date + INTERVAL '2 hours' < NOW()
    AND end_date < NOW(); -- Ensure we're past the actual end date
  
  GET DIAGNOSTICS v_updated_count = ROW_COUNT;
  
  -- Also handle the transition from 'confirmed' to 'inProgress' for current rentals
  UPDATE public.rentals
  SET 
    status = 'inProgress',
    updated_at = NOW()
  WHERE 
    status = 'confirmed'
    AND start_date <= NOW()
    AND end_date > NOW();
  
  RETURN v_updated_count;
END;
$$ LANGUAGE plpgsql;

-- Create a scheduled job that runs every hour to auto-complete rentals
-- This uses pg_cron extension (if available) or can be called manually/via external scheduler
SELECT cron.schedule(
  'auto-complete-rentals',           -- job name
  '0 * * * *',                      -- run every hour at minute 0
  'SELECT auto_complete_expired_rentals();'
);

-- Alternative: Create a trigger-based approach for immediate completion
-- This trigger runs after any rental update and checks if completion is needed
CREATE OR REPLACE FUNCTION trigger_check_rental_completion() RETURNS TRIGGER AS $$
BEGIN
  -- Only check if rental is currently inProgress and past end date
  IF NEW.status = 'inProgress' AND NEW.end_date + INTERVAL '2 hours' < NOW() THEN
    -- Mark as completed
    NEW.status = 'completed';
    NEW.updated_at = NOW();
  END IF;
  
  -- Handle confirmed -> inProgress transition
  IF NEW.status = 'confirmed' AND NEW.start_date <= NOW() AND NEW.end_date > NOW() THEN
    NEW.status = 'inProgress';
    NEW.updated_at = NOW();
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for automatic status transitions
CREATE OR REPLACE TRIGGER trig_auto_rental_transitions
  BEFORE UPDATE ON public.rentals
  FOR EACH ROW
  EXECUTE FUNCTION trigger_check_rental_completion();

-- Function to manually complete a rental (for lender use)
CREATE OR REPLACE FUNCTION complete_rental(
  p_rental_id UUID,
  p_lender_id UUID DEFAULT NULL
) RETURNS BOOLEAN AS $$
DECLARE
  v_rental RECORD;
BEGIN
  -- Get rental details
  SELECT r.*, i.owner_id
  INTO v_rental
  FROM public.rentals r
  JOIN public.items i ON r.item_id = i.id
  WHERE r.id = p_rental_id;
  
  -- Check if rental exists
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Rental not found';
  END IF;
  
  -- Check if lender owns the item (if lender_id provided)
  IF p_lender_id IS NOT NULL AND v_rental.owner_id != p_lender_id THEN
    RAISE EXCEPTION 'Not authorized to complete this rental';
  END IF;
  
  -- Check if rental can be completed
  IF v_rental.status NOT IN ('confirmed', 'inProgress') THEN
    RAISE EXCEPTION 'Rental cannot be completed from current status: %', v_rental.status;
  END IF;
  
  -- Update rental to completed
  UPDATE public.rentals
  SET 
    status = 'completed',
    updated_at = NOW()
  WHERE id = p_rental_id;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Add comments for documentation
COMMENT ON FUNCTION auto_complete_expired_rentals() IS 'Automatically completes rentals that have ended to trigger return buffer creation';
COMMENT ON FUNCTION complete_rental(UUID, UUID) IS 'Manually complete a rental by lender or system';
COMMENT ON FUNCTION trigger_check_rental_completion() IS 'Trigger function to automatically transition rental statuses based on dates';

-- Initial run to complete any existing expired rentals
SELECT auto_complete_expired_rentals(); 