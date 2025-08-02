-- Migration: Trigger auto-blocks on delivery approval instead of rental completion
-- This creates return buffers immediately when lender approves delivery,
-- giving renters the full rental period plus buffer time for return

-- Drop existing rental completion trigger since we're changing the logic
DROP TRIGGER IF EXISTS trig_create_post_rental_block ON public.rentals;
DROP FUNCTION IF EXISTS create_post_rental_block();

-- Drop the auto-completion trigger too since we're changing the workflow
DROP TRIGGER IF EXISTS trig_auto_rental_transitions ON public.rentals;
DROP FUNCTION IF EXISTS trigger_check_rental_completion();

-- Create new function to handle auto-blocks on delivery approval
CREATE OR REPLACE FUNCTION create_auto_block_on_delivery_approval() RETURNS TRIGGER AS $$
DECLARE
  v_blocking_days INTEGER;
  v_rental_record RECORD;
BEGIN
  -- Only proceed if delivery status changed to 'approved' and has lender_approved_at timestamp
  IF NEW.status = 'approved' AND OLD.status != 'approved' AND NEW.lender_approved_at IS NOT NULL THEN
    
    -- Get rental and item details
    SELECT r.*, i.blocking_days, i.id as item_id
    INTO v_rental_record
    FROM public.rentals r
    JOIN public.items i ON r.item_id = i.id
    WHERE r.id = NEW.rental_id;
    
    -- If rental not found or no blocking days configured, skip
    IF NOT FOUND OR v_rental_record.blocking_days IS NULL OR v_rental_record.blocking_days = 0 THEN
      RETURN NEW;
    END IF;
    
    -- Create auto-block starting from rental end date
    INSERT INTO public.availability_blocks(
      item_id,
      rental_id,
      blocked_from,
      blocked_until,
      block_type,
      quantity_blocked,
      reason
    )
    VALUES (
      v_rental_record.item_id,
      v_rental_record.id,
      v_rental_record.end_date,                                              -- Start blocking from rental end date
      v_rental_record.end_date + (v_rental_record.blocking_days || ' days')::INTERVAL,  -- Block for configured days
      'post_rental',
      1,                                                                     -- One unit per rental
      'Return buffer - ' || v_rental_record.blocking_days || ' day' || 
      CASE WHEN v_rental_record.blocking_days > 1 THEN 's' ELSE '' END ||
      ' (activated on delivery approval)'
    );
    
    -- Note: Duplicates are prevented by the unique index on (rental_id) WHERE block_type = 'post_rental'
    
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger that fires on delivery status updates
CREATE OR REPLACE TRIGGER trig_create_auto_block_on_delivery_approval
  AFTER UPDATE ON public.deliveries
  FOR EACH ROW 
  EXECUTE FUNCTION create_auto_block_on_delivery_approval();

-- Create simpler rental completion function (without auto-blocking since that's handled by delivery approval)
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
    status = 'in_progress' 
    AND end_date + INTERVAL '2 hours' < NOW()
    AND end_date < NOW(); -- Ensure we're past the actual end date
  
  GET DIAGNOSTICS v_updated_count = ROW_COUNT;
  
  -- Also handle the transition from 'confirmed' to 'in_progress' for current rentals
  UPDATE public.rentals
  SET 
    status = 'in_progress',
    updated_at = NOW()
  WHERE 
    status = 'confirmed'
    AND start_date <= NOW()
    AND end_date > NOW();
  
  RETURN v_updated_count;
END;
$$ LANGUAGE plpgsql;

-- Keep the cron job for rental status transitions (but not auto-blocking)
-- Note: This requires pg_cron extension to be enabled. Skip if not available.
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    PERFORM cron.schedule(
      'auto-complete-rentals',           -- job name
      '0 * * * *',                      -- run every hour at minute 0
      'SELECT auto_complete_expired_rentals();'
    );
  ELSE
    RAISE NOTICE 'pg_cron extension not available. Skipping cron job setup.';
    RAISE NOTICE 'You can manually call auto_complete_expired_rentals() periodically.';
  END IF;
END
$$;

-- Keep the manual completion function for lender use
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
  IF v_rental.status NOT IN ('confirmed', 'in_progress') THEN
    RAISE EXCEPTION 'Rental cannot be completed from current status: %', v_rental.status;
  END IF;
  
  -- Update rental to completed (no auto-blocking here since it's handled by delivery approval)
  UPDATE public.rentals
  SET 
    status = 'completed',
    updated_at = NOW()
  WHERE id = p_rental_id;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Add constraint to prevent duplicate auto-blocks per rental
-- Using a partial unique index instead of constraint since PostgreSQL doesn't support WHERE in UNIQUE constraints
CREATE UNIQUE INDEX IF NOT EXISTS unique_rental_auto_block 
ON public.availability_blocks (rental_id) 
WHERE block_type = 'post_rental';

-- Add comments for documentation
COMMENT ON FUNCTION create_auto_block_on_delivery_approval() IS 'Creates return buffer blocks when lender approves delivery request';
COMMENT ON FUNCTION auto_complete_expired_rentals() IS 'Automatically transitions rental statuses based on dates';
COMMENT ON FUNCTION complete_rental(UUID, UUID) IS 'Manually complete a rental by lender or system';

-- Initial run to complete any existing expired rentals
SELECT auto_complete_expired_rentals(); 