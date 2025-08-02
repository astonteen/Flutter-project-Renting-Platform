-- Migration: Update auto-block trigger to use blocking_days from items table
-- This allows each item to have its own configurable return buffer period

-- Drop existing trigger and function to recreate with new logic
DROP TRIGGER IF EXISTS trig_create_post_rental_block ON public.rentals;
DROP FUNCTION IF EXISTS create_post_rental_block();

-- Create updated function that uses blocking_days from items table
CREATE OR REPLACE FUNCTION create_post_rental_block() RETURNS TRIGGER AS $$
DECLARE
  v_blocking_days INTEGER;
BEGIN
  -- Only proceed if rental status changed to completed
  IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
    
    -- Get blocking_days for this specific item
    SELECT blocking_days INTO v_blocking_days
    FROM public.items
    WHERE id = NEW.item_id;
    
    -- If blocking_days is NULL or 0, no auto-block needed
    IF v_blocking_days IS NULL OR v_blocking_days = 0 THEN
      RETURN NEW;
    END IF;
    
    -- Create post-rental block for the specified duration
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
      NEW.item_id,
      NEW.id,
      NEW.end_date,                                    -- Start blocking from end date
      NEW.end_date + (v_blocking_days || ' days')::INTERVAL,  -- Block for configured days
      'post_rental',
      1,                                               -- One unit per rental
      'Return buffer - ' || v_blocking_days || ' day' || CASE WHEN v_blocking_days > 1 THEN 's' ELSE '' END
    );
    
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger that fires on rental status updates
CREATE OR REPLACE TRIGGER trig_create_post_rental_block
  AFTER UPDATE ON public.rentals
  FOR EACH ROW 
  EXECUTE FUNCTION create_post_rental_block();

-- Add comment for documentation
COMMENT ON FUNCTION create_post_rental_block() IS 'Creates post-rental availability blocks using item-specific blocking_days configuration'; 