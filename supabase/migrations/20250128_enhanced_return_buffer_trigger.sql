-- Migration: Enhanced return buffer trigger with dynamic calculation
-- Consolidates all return buffer logic into the database trigger
-- Eliminates the need for duplicate logic in the Dart application

-- Drop existing trigger and function to recreate with enhanced logic
DROP TRIGGER IF EXISTS trig_create_post_rental_block ON public.rentals;
DROP FUNCTION IF EXISTS create_post_rental_block();

-- Create enhanced function that calculates dynamic return buffer
CREATE OR REPLACE FUNCTION create_post_rental_block() RETURNS TRIGGER AS $$
DECLARE
  v_blocking_days INTEGER;
  v_category_name TEXT;
  v_condition TEXT;
  v_total_price NUMERIC;
  v_has_delivery_return BOOLEAN;
  v_base_buffer INTEGER;
  v_condition_adjustment INTEGER;
  v_reason TEXT;
BEGIN
  -- Only proceed if rental status changed to completed
  IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
    
    -- Get item details for dynamic calculation
    SELECT 
      i.blocking_days,
      COALESCE(c.name, 'default') as category_name,
      COALESCE(i.condition, 'good') as condition,
      NEW.total_price
    INTO 
      v_blocking_days,
      v_category_name, 
      v_condition,
      v_total_price
    FROM public.items i
    LEFT JOIN public.categories c ON i.category_id = c.id
    WHERE i.id = NEW.item_id;
    
    -- Check if rental has delivery return
    SELECT EXISTS(
      SELECT 1 FROM public.deliveries d 
      WHERE d.rental_id = NEW.id 
      AND d.delivery_type = 'return_pickup'
    ) INTO v_has_delivery_return;
    
    -- Calculate dynamic buffer days if item doesn't have fixed blocking_days
    IF v_blocking_days IS NULL OR v_blocking_days = 0 THEN
      -- Base buffer by category (simplified mapping)
      v_base_buffer := CASE 
        WHEN v_category_name ILIKE '%electronic%' THEN 3
        WHEN v_category_name ILIKE '%automotive%' THEN 4  
        WHEN v_category_name ILIKE '%photography%' THEN 3
        WHEN v_category_name ILIKE '%musical%' THEN 3
        WHEN v_category_name ILIKE '%tool%' THEN 2
        WHEN v_category_name ILIKE '%sport%' THEN 2
        WHEN v_category_name ILIKE '%outdoor%' THEN 2
        WHEN v_category_name ILIKE '%furniture%' THEN 2
        WHEN v_category_name ILIKE '%clothing%' THEN 1
        ELSE 2 -- default
      END;
      
      -- Condition adjustment
      v_condition_adjustment := CASE v_condition
        WHEN 'fair' THEN 1
        WHEN 'poor' THEN 2
        ELSE 0
      END;
      
      -- Calculate final buffer days
      v_blocking_days := v_base_buffer + v_condition_adjustment;
      
      -- Add delivery return buffer
      IF v_has_delivery_return THEN
        v_blocking_days := v_blocking_days + 1;
      END IF;
      
      -- Add high-value buffer
      IF v_total_price > 500 THEN
        v_blocking_days := v_blocking_days + 1;
      END IF;
      
      -- Clamp to reasonable bounds (1-7 days)
      v_blocking_days := GREATEST(1, LEAST(7, v_blocking_days));
    END IF;
    
    -- Generate descriptive reason
    v_reason := 'Return buffer (' || v_blocking_days || ' day';
    IF v_blocking_days > 1 THEN
      v_reason := v_reason || 's';
    END IF;
    v_reason := v_reason || ') - ' || v_category_name || ' in ' || v_condition || ' condition';
    
    IF v_has_delivery_return THEN
      v_reason := v_reason || ' with delivery return';
    END IF;
    
    -- Create post-rental block only if buffer days > 0
    IF v_blocking_days > 0 THEN
      INSERT INTO public.availability_blocks(
        item_id,
        rental_id,
        blocked_from,
        blocked_until,
        block_type,
        quantity_blocked,
        reason,
        metadata
      )
      VALUES (
        NEW.item_id,
        NEW.id,
        NEW.end_date,
        NEW.end_date + (v_blocking_days || ' days')::INTERVAL,
        'post_rental',
        1,
        v_reason,
        jsonb_build_object(
          'category', v_category_name,
          'condition', v_condition,
          'buffer_days', v_blocking_days,
          'has_delivery_return', v_has_delivery_return,
          'total_price', v_total_price,
          'auto_calculated', true
        )
      );
    END IF;
    
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger that fires on rental status updates
CREATE OR REPLACE TRIGGER trig_create_post_rental_block
  AFTER UPDATE ON public.rentals
  FOR EACH ROW 
  EXECUTE FUNCTION create_post_rental_block();

-- Add comments for documentation
COMMENT ON FUNCTION create_post_rental_block() IS 'Creates post-rental availability blocks with dynamic buffer calculation based on item category, condition, delivery type, and value';
COMMENT ON TRIGGER trig_create_post_rental_block ON public.rentals IS 'Automatically creates return buffer blocks when rentals are completed';