-- Phase 1: Driver Efficiency Core Database Schema
-- Implementing smart availability, batch delivery, and job assignment improvements

-- 1. Enhanced Delivery Tracking for Batch Deliveries
ALTER TABLE public.deliveries ADD COLUMN IF NOT EXISTS batch_group_id UUID;
ALTER TABLE public.deliveries ADD COLUMN IF NOT EXISTS sequence_order INTEGER DEFAULT 1;
ALTER TABLE public.deliveries ADD COLUMN IF NOT EXISTS estimated_pickup_time TIMESTAMP WITH TIME ZONE;
ALTER TABLE public.deliveries ADD COLUMN IF NOT EXISTS estimated_delivery_time TIMESTAMP WITH TIME ZONE;
ALTER TABLE public.deliveries ADD COLUMN IF NOT EXISTS actual_pickup_time TIMESTAMP WITH TIME ZONE;
ALTER TABLE public.deliveries ADD COLUMN IF NOT EXISTS actual_delivery_time TIMESTAMP WITH TIME ZONE;

-- 2. Driver Performance and Availability Enhancements
ALTER TABLE public.driver_profiles ADD COLUMN IF NOT EXISTS performance_score DECIMAL(3,2) DEFAULT 4.0;
ALTER TABLE public.driver_profiles ADD COLUMN IF NOT EXISTS job_priority_multiplier DECIMAL(3,2) DEFAULT 1.0;
ALTER TABLE public.driver_profiles ADD COLUMN IF NOT EXISTS active_delivery_count INTEGER DEFAULT 0;
ALTER TABLE public.driver_profiles ADD COLUMN IF NOT EXISTS last_location_lat DECIMAL(10,8);
ALTER TABLE public.driver_profiles ADD COLUMN IF NOT EXISTS last_location_lng DECIMAL(11,8);
ALTER TABLE public.driver_profiles ADD COLUMN IF NOT EXISTS last_location_updated TIMESTAMP WITH TIME ZONE;

-- 3. Create Batch Delivery Groups Table
CREATE TABLE IF NOT EXISTS public.delivery_batches (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  driver_id UUID REFERENCES public.profiles(id) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'completed', 'cancelled')),
  total_deliveries INTEGER DEFAULT 0,
  completed_deliveries INTEGER DEFAULT 0,
  estimated_total_time INTEGER, -- in minutes
  actual_total_time INTEGER -- in minutes
);

-- 4. Job Assignment Priority Queue
CREATE TABLE IF NOT EXISTS public.job_assignment_queue (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  delivery_id UUID REFERENCES public.deliveries(id) NOT NULL,
  driver_id UUID REFERENCES public.profiles(id),
  priority_score INTEGER DEFAULT 100,
  assignment_radius_km DECIMAL(5,2) DEFAULT 5.0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  assigned_at TIMESTAMP WITH TIME ZONE,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'assigned', 'expired'))
);

-- 5. Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_deliveries_batch_group ON public.deliveries(batch_group_id);
CREATE INDEX IF NOT EXISTS idx_deliveries_driver_status ON public.deliveries(driver_id, status);
CREATE INDEX IF NOT EXISTS idx_driver_profiles_available ON public.driver_profiles(is_available, performance_score);
CREATE INDEX IF NOT EXISTS idx_job_queue_priority ON public.job_assignment_queue(priority_score DESC, created_at);

-- 6. Smart Job Assignment Function
CREATE OR REPLACE FUNCTION calculate_driver_priority_score(
  driver_user_id UUID,
  pickup_lat DECIMAL,
  pickup_lng DECIMAL
) RETURNS INTEGER AS $$
DECLARE
  driver_score INTEGER := 100;
  rating_multiplier DECIMAL := 1.0;
  distance_penalty INTEGER := 0;
  availability_bonus INTEGER := 0;
  load_penalty INTEGER := 0;
BEGIN
  -- Get driver performance data
  SELECT 
    COALESCE(performance_score, 4.0),
    COALESCE(job_priority_multiplier, 1.0),
    COALESCE(active_delivery_count, 0)
  INTO rating_multiplier, availability_bonus, load_penalty
  FROM driver_profiles 
  WHERE user_id = driver_user_id;
  
  -- Rating-based scoring (4.8+ = 120, 4.0-4.7 = 100, <4.0 = 50)
  IF rating_multiplier >= 4.8 THEN
    driver_score := 120;
  ELSIF rating_multiplier >= 4.0 THEN
    driver_score := 100;
  ELSE
    driver_score := 50;
  END IF;
  
  -- Load penalty (reduce score for drivers with multiple active deliveries)
  load_penalty := load_penalty * 15; -- -15 points per active delivery
  
  -- Distance penalty (calculated separately in application layer)
  -- This function focuses on driver-specific scoring
  
  RETURN GREATEST(driver_score - load_penalty, 10); -- Minimum score of 10
END;
$$ LANGUAGE plpgsql;

-- 7. Batch Delivery Management Functions
CREATE OR REPLACE FUNCTION create_delivery_batch(
  driver_user_id UUID,
  delivery_ids UUID[]
) RETURNS UUID AS $$
DECLARE
  batch_id UUID;
  delivery_id UUID;
  sequence_num INTEGER := 1;
BEGIN
  -- Create new batch
  INSERT INTO delivery_batches (driver_id, total_deliveries)
  VALUES (driver_user_id, array_length(delivery_ids, 1))
  RETURNING id INTO batch_id;
  
  -- Assign deliveries to batch
  FOREACH delivery_id IN ARRAY delivery_ids
  LOOP
    UPDATE deliveries 
    SET 
      batch_group_id = batch_id,
      sequence_order = sequence_num,
      updated_at = NOW()
    WHERE id = delivery_id;
    
    sequence_num := sequence_num + 1;
  END LOOP;
  
  -- Update driver active delivery count
  UPDATE driver_profiles 
  SET active_delivery_count = active_delivery_count + array_length(delivery_ids, 1)
  WHERE user_id = driver_user_id;
  
  RETURN batch_id;
END;
$$ LANGUAGE plpgsql;

-- 8. Smart Availability Management
CREATE OR REPLACE FUNCTION request_driver_offline(driver_user_id UUID) 
RETURNS TABLE(can_go_offline BOOLEAN, active_deliveries INTEGER) AS $$
DECLARE
  active_count INTEGER;
BEGIN
  -- Count active deliveries
  SELECT COUNT(*) INTO active_count
  FROM deliveries d
  WHERE d.driver_id = driver_user_id 
  AND d.status NOT IN ('delivered', 'cancelled', 'returned');
  
  IF active_count = 0 THEN
    -- Can go offline immediately
    UPDATE driver_profiles 
    SET is_available = false 
    WHERE user_id = driver_user_id;
    
    RETURN QUERY SELECT true, 0;
  ELSE
    -- Must complete active deliveries first
    RETURN QUERY SELECT false, active_count;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- 9. Auto-offline trigger when all deliveries completed
CREATE OR REPLACE FUNCTION check_driver_auto_offline()
RETURNS TRIGGER AS $$
BEGIN
  -- If driver requested offline and this was their last delivery
  IF NEW.status IN ('delivered', 'cancelled', 'returned') AND OLD.status NOT IN ('delivered', 'cancelled', 'returned') THEN
    -- Check if driver has any remaining active deliveries
    IF NOT EXISTS (
      SELECT 1 FROM deliveries 
      WHERE driver_id = NEW.driver_id 
      AND status NOT IN ('delivered', 'cancelled', 'returned')
      AND id != NEW.id
    ) THEN
      -- Update driver to offline if they have pending offline request
      -- This would be managed by application logic, but we update active count here
      UPDATE driver_profiles 
      SET active_delivery_count = 0
      WHERE user_id = NEW.driver_id;
    ELSE
      -- Decrement active delivery count
      UPDATE driver_profiles 
      SET active_delivery_count = GREATEST(active_delivery_count - 1, 0)
      WHERE user_id = NEW.driver_id;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for auto-offline management
DROP TRIGGER IF EXISTS trigger_check_driver_auto_offline ON deliveries;
CREATE TRIGGER trigger_check_driver_auto_offline
  AFTER UPDATE OF status ON deliveries
  FOR EACH ROW
  EXECUTE FUNCTION check_driver_auto_offline();

-- 10. Add RLS policies for new tables
ALTER TABLE public.delivery_batches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_assignment_queue ENABLE ROW LEVEL SECURITY;

-- Batch policies
CREATE POLICY "Drivers can view their own batches" ON public.delivery_batches
  FOR SELECT USING (auth.uid() = driver_id);

CREATE POLICY "Drivers can update their own batches" ON public.delivery_batches  
  FOR UPDATE USING (auth.uid() = driver_id);

-- Job queue policies  
CREATE POLICY "System can manage job assignments" ON public.job_assignment_queue
  FOR ALL USING (true); -- This would be restricted to service role in production

-- 11. Comments for documentation
COMMENT ON TABLE delivery_batches IS 'Groups multiple deliveries for batch processing by drivers';
COMMENT ON TABLE job_assignment_queue IS 'Priority queue for intelligent job assignment based on driver performance and proximity';
COMMENT ON FUNCTION calculate_driver_priority_score IS 'Calculates priority score for drivers based on rating, availability, and current load';
COMMENT ON FUNCTION create_delivery_batch IS 'Creates a new batch of deliveries for efficient route planning';
COMMENT ON FUNCTION request_driver_offline IS 'Handles driver offline requests with active delivery validation';

-- 12. Initial data setup
-- Update existing driver profiles with default performance scores
UPDATE driver_profiles 
SET 
  performance_score = CASE 
    WHEN average_rating >= 4.8 THEN 4.8
    WHEN average_rating >= 4.0 THEN average_rating
    ELSE 4.0
  END,
  job_priority_multiplier = CASE
    WHEN average_rating >= 4.8 THEN 1.3
    WHEN average_rating >= 4.0 THEN 1.0
    ELSE 0.5
  END
WHERE performance_score IS NULL;
