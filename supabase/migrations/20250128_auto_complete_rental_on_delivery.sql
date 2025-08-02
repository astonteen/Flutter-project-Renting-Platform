-- Migration: Auto-complete rental when delivery is completed
-- This ensures that rental status is updated when item is delivered

-- Function to automatically complete rental when delivery is finished
CREATE OR REPLACE FUNCTION auto_complete_rental_on_delivery() RETURNS TRIGGER AS $$
DECLARE
  v_rental_record RECORD;
BEGIN
  -- Only proceed if delivery status changed to 'item_delivered'
  IF NEW.status = 'item_delivered' AND OLD.status != 'item_delivered' THEN
    
    -- Get rental details
    SELECT r.*
    INTO v_rental_record
    FROM public.rentals r
    WHERE r.id = NEW.rental_id;
    
    -- If rental not found, skip
    IF NOT FOUND THEN
      RETURN NEW;
    END IF;
    
    -- Only update if rental is currently in_progress or confirmed
    -- Don't override completed/cancelled statuses
    IF v_rental_record.status IN ('in_progress', 'confirmed') THEN
      -- Update rental status to completed since item has been delivered
      UPDATE public.rentals
      SET 
        status = 'completed',
        updated_at = NOW()
      WHERE id = NEW.rental_id;
      
      RAISE NOTICE 'Auto-completed rental % due to delivery completion', NEW.rental_id;
    END IF;
    
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger that fires when delivery status is updated
CREATE OR REPLACE TRIGGER trig_auto_complete_rental_on_delivery
  AFTER UPDATE ON public.deliveries
  FOR EACH ROW 
  EXECUTE FUNCTION auto_complete_rental_on_delivery();

-- Add comment for documentation
COMMENT ON FUNCTION auto_complete_rental_on_delivery() IS 'Automatically completes rental when delivery status becomes item_delivered';

-- One-time fix for existing delivered items that haven't been completed
UPDATE public.rentals
SET 
  status = 'completed',
  updated_at = NOW()
FROM public.deliveries d
WHERE 
  d.rental_id = rentals.id
  AND d.status = 'item_delivered'
  AND rentals.status IN ('in_progress', 'confirmed')
  AND d.delivery_type = 'pickup_delivery';