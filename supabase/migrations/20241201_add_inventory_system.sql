-- Add inventory quantity support to items table
ALTER TABLE public.items 
ADD COLUMN quantity INTEGER DEFAULT 1 CHECK (quantity > 0);

-- Add post-rental blocking configuration
ALTER TABLE public.items 
ADD COLUMN blocking_days INTEGER DEFAULT 2 CHECK (blocking_days >= 0);

-- Add review/maintenance reason for blocking
ALTER TABLE public.items 
ADD COLUMN blocking_reason TEXT DEFAULT 'Review and maintenance';

-- Create availability_blocks table to track post-rental blocking periods
CREATE TABLE IF NOT EXISTS public.availability_blocks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  item_id UUID REFERENCES public.items(id) ON DELETE CASCADE NOT NULL,
  rental_id UUID REFERENCES public.rentals(id) ON DELETE CASCADE,
  blocked_from TIMESTAMP WITH TIME ZONE NOT NULL,
  blocked_until TIMESTAMP WITH TIME ZONE NOT NULL,
  block_type TEXT DEFAULT 'post_rental' CHECK (block_type IN ('post_rental', 'maintenance', 'manual')),
  reason TEXT,
  quantity_blocked INTEGER DEFAULT 1 CHECK (quantity_blocked > 0),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_availability_blocks_item_id ON public.availability_blocks(item_id);
CREATE INDEX IF NOT EXISTS idx_availability_blocks_date_range ON public.availability_blocks(blocked_from, blocked_until);
CREATE INDEX IF NOT EXISTS idx_rentals_item_dates ON public.rentals(item_id, start_date, end_date);

-- Function to automatically create post-rental blocking periods
CREATE OR REPLACE FUNCTION create_post_rental_block()
RETURNS TRIGGER AS $$
BEGIN
  -- Only create blocks when rental is completed and item has blocking days configured
  IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
    INSERT INTO public.availability_blocks (
      item_id,
      rental_id,
      blocked_from,
      blocked_until,
      block_type,
      reason,
      quantity_blocked
    )
    SELECT 
      i.id,
      NEW.id,
      NEW.end_date,
      NEW.end_date + INTERVAL '1 day' * i.blocking_days,
      'post_rental',
      COALESCE(i.blocking_reason, 'Post-rental review and maintenance'),
      1  -- Block one unit
    FROM public.items i
    WHERE i.id = NEW.item_id 
      AND i.blocking_days > 0
      -- Avoid duplicate blocks
      AND NOT EXISTS (
        SELECT 1 FROM public.availability_blocks ab
        WHERE ab.rental_id = NEW.id
      );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for post-rental blocking
CREATE TRIGGER trigger_create_post_rental_block
  AFTER UPDATE ON public.rentals
  FOR EACH ROW
  EXECUTE FUNCTION create_post_rental_block();

-- Function to check item availability considering quantity and blocks
CREATE OR REPLACE FUNCTION check_item_availability(
  p_item_id UUID,
  p_start_date TIMESTAMP WITH TIME ZONE,
  p_end_date TIMESTAMP WITH TIME ZONE,
  p_quantity_needed INTEGER DEFAULT 1
)
RETURNS TABLE (
  available BOOLEAN,
  total_quantity INTEGER,
  available_quantity INTEGER,
  blocked_quantity INTEGER,
  booked_quantity INTEGER
) AS $$
DECLARE
  v_total_quantity INTEGER;
  v_booked_quantity INTEGER;
  v_blocked_quantity INTEGER;
  v_available_quantity INTEGER;
BEGIN
  -- Get total quantity for the item
  SELECT i.quantity INTO v_total_quantity
  FROM public.items i
  WHERE i.id = p_item_id AND i.available = true;
  
  IF v_total_quantity IS NULL THEN
    RETURN QUERY SELECT false, 0, 0, 0, 0;
    RETURN;
  END IF;
  
  -- Calculate booked quantity during the requested period
  SELECT COALESCE(COUNT(*), 0) INTO v_booked_quantity
  FROM public.rentals r
  WHERE r.item_id = p_item_id
    AND r.status IN ('confirmed', 'in_progress')
    AND (
      (r.start_date <= p_start_date AND r.end_date > p_start_date) OR
      (r.start_date < p_end_date AND r.end_date >= p_end_date) OR
      (r.start_date >= p_start_date AND r.end_date <= p_end_date)
    );
  
  -- Calculate blocked quantity during the requested period
  SELECT COALESCE(SUM(ab.quantity_blocked), 0) INTO v_blocked_quantity
  FROM public.availability_blocks ab
  WHERE ab.item_id = p_item_id
    AND (
      (ab.blocked_from <= p_start_date AND ab.blocked_until > p_start_date) OR
      (ab.blocked_from < p_end_date AND ab.blocked_until >= p_end_date) OR
      (ab.blocked_from >= p_start_date AND ab.blocked_until <= p_end_date)
    );
  
  -- Calculate available quantity
  v_available_quantity := v_total_quantity - v_booked_quantity - v_blocked_quantity;
  
  RETURN QUERY SELECT 
    (v_available_quantity >= p_quantity_needed),
    v_total_quantity,
    v_available_quantity,
    v_blocked_quantity,
    v_booked_quantity;
END;
$$ LANGUAGE plpgsql;

-- Update existing items to have default quantity of 1
UPDATE public.items SET quantity = 1 WHERE quantity IS NULL;

-- Add comment for documentation
COMMENT ON TABLE public.availability_blocks IS 'Tracks periods when item units are blocked for maintenance, review, or other reasons';
COMMENT ON FUNCTION check_item_availability IS 'Checks availability considering total quantity, bookings, and blocked periods';
COMMENT ON COLUMN public.items.quantity IS 'Number of identical units available for rent';
COMMENT ON COLUMN public.items.blocking_days IS 'Days to block after rental completion for review/maintenance'; 