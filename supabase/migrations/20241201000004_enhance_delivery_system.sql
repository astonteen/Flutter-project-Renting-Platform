-- Enhance delivery system for production-quality assignment
-- This migration adds professional delivery features

-- Add enhanced columns to deliveries table
ALTER TABLE public.deliveries ADD COLUMN IF NOT EXISTS delivery_type TEXT DEFAULT 'pickup_delivery' 
  CHECK (delivery_type IN ('pickup_delivery', 'return_pickup'));

ALTER TABLE public.deliveries ADD COLUMN IF NOT EXISTS current_leg TEXT DEFAULT 'pickup' 
  CHECK (current_leg IN ('pickup', 'delivery', 'return_pickup', 'return_delivery'));

ALTER TABLE public.deliveries ADD COLUMN IF NOT EXISTS estimated_duration INTEGER DEFAULT 30; -- minutes

ALTER TABLE public.deliveries ADD COLUMN IF NOT EXISTS distance_km DECIMAL(5,2) DEFAULT 0.0;

ALTER TABLE public.deliveries ADD COLUMN IF NOT EXISTS pickup_proof_image TEXT;

ALTER TABLE public.deliveries ADD COLUMN IF NOT EXISTS delivery_proof_image TEXT;

ALTER TABLE public.deliveries ADD COLUMN IF NOT EXISTS special_instructions TEXT;

ALTER TABLE public.deliveries ADD COLUMN IF NOT EXISTS driver_earnings DECIMAL(10,2) DEFAULT 0.0;

ALTER TABLE public.deliveries ADD COLUMN IF NOT EXISTS customer_rating INTEGER CHECK (customer_rating >= 1 AND customer_rating <= 5);

ALTER TABLE public.deliveries ADD COLUMN IF NOT EXISTS customer_tip DECIMAL(10,2) DEFAULT 0.0;

-- Update delivery status to include more professional statuses
ALTER TABLE public.deliveries DROP CONSTRAINT IF EXISTS deliveries_status_check;
ALTER TABLE public.deliveries ADD CONSTRAINT deliveries_status_check 
  CHECK (status IN ('pending', 'available', 'accepted', 'heading_to_pickup', 'picked_up', 
                   'heading_to_delivery', 'delivered', 'heading_to_return', 'returned', 'cancelled'));

-- Create delivery messages table for driver-customer communication
CREATE TABLE IF NOT EXISTS public.delivery_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  delivery_id UUID REFERENCES public.deliveries(id) NOT NULL,
  sender_id UUID REFERENCES public.profiles(id) NOT NULL,
  receiver_id UUID REFERENCES public.profiles(id) NOT NULL,
  message TEXT NOT NULL,
  message_type TEXT DEFAULT 'text' CHECK (message_type IN ('text', 'location_update', 'photo', 'template')),
  is_template BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Create driver_profiles table for delivery-specific info
CREATE TABLE IF NOT EXISTS public.driver_profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.profiles(id) NOT NULL UNIQUE,
  vehicle_type TEXT NOT NULL CHECK (vehicle_type IN ('bike', 'motorcycle', 'car', 'van')),
  vehicle_model TEXT,
  license_plate TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  is_available BOOLEAN DEFAULT FALSE,
  current_location TEXT,
  total_deliveries INTEGER DEFAULT 0,
  average_rating DECIMAL(3,2) DEFAULT 0.0,
  total_earnings DECIMAL(10,2) DEFAULT 0.0,
  bank_account_number TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Add RLS policies for new tables
ALTER TABLE public.delivery_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.driver_profiles ENABLE ROW LEVEL SECURITY;

-- Policies for delivery_messages
CREATE POLICY "Users can view delivery messages they are part of" ON public.delivery_messages
  FOR SELECT USING (
    auth.uid() = sender_id OR 
    auth.uid() = receiver_id OR
    auth.uid() IN (
      SELECT driver_id FROM public.deliveries WHERE id = delivery_id
    )
  );

CREATE POLICY "Users can send delivery messages" ON public.delivery_messages
  FOR INSERT WITH CHECK (auth.uid() = sender_id);

-- Policies for driver_profiles  
CREATE POLICY "Driver profiles are viewable by delivery participants" ON public.driver_profiles
  FOR SELECT USING (
    auth.uid() = user_id OR
    auth.uid() IN (
      SELECT renter_id FROM public.rentals r 
      JOIN public.deliveries d ON r.id = d.rental_id 
      WHERE d.driver_id = user_id
    ) OR
    auth.uid() IN (
      SELECT owner_id FROM public.rentals r 
      JOIN public.deliveries d ON r.id = d.rental_id 
      WHERE d.driver_id = user_id
    )
  );

CREATE POLICY "Users can manage their own driver profile" ON public.driver_profiles
  FOR ALL USING (auth.uid() = user_id);

-- Enhanced delivery policies
CREATE POLICY "Drivers can view available delivery jobs" ON public.deliveries
  FOR SELECT USING (
    status = 'available' OR 
    auth.uid() = driver_id OR 
    auth.uid() IN (
      SELECT renter_id FROM public.rentals WHERE id = rental_id
    ) OR
    auth.uid() IN (
      SELECT owner_id FROM public.rentals WHERE id = rental_id
    )
  );

CREATE POLICY "System can create delivery jobs" ON public.deliveries
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Drivers can accept available jobs" ON public.deliveries
  FOR UPDATE USING (
    (status = 'available' AND driver_id IS NULL) OR
    auth.uid() = driver_id
  );

-- Create triggers for new tables
CREATE TRIGGER update_delivery_messages_updated_at
BEFORE UPDATE ON public.delivery_messages
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_driver_profiles_updated_at
BEFORE UPDATE ON public.driver_profiles
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to automatically create delivery job when rental requires delivery
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
      special_instructions
    ) VALUES (
      NEW.id,
      (SELECT COALESCE(
        (SELECT location FROM public.profiles WHERE id = NEW.owner_id),
        'Owner Location Not Set'
      )),
      COALESCE(NEW.delivery_address, 'Delivery Address Not Set'),
      15.00, -- Default delivery fee
      'available',
      'pickup_delivery',
      30, -- 30 minutes default
      5.0, -- 5km default distance
      NEW.delivery_instructions
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-create delivery jobs
CREATE TRIGGER auto_create_delivery_job
AFTER INSERT ON public.rentals
FOR EACH ROW EXECUTE FUNCTION create_delivery_job_for_rental();

-- Insert demo driver profiles for assignment demonstration
-- Note: These will be linked to actual user profiles when they register as drivers

-- Create function to calculate delivery earnings
CREATE OR REPLACE FUNCTION calculate_delivery_earnings(delivery_id UUID)
RETURNS DECIMAL(10,2) AS $$
DECLARE
  base_fee DECIMAL(10,2);
  distance_bonus DECIMAL(10,2);
  tip_amount DECIMAL(10,2);
  total_earnings DECIMAL(10,2);
BEGIN
  SELECT 
    fee,
    CASE WHEN distance_km > 3 THEN (distance_km - 3) * 2.00 ELSE 0 END,
    COALESCE(customer_tip, 0)
  INTO base_fee, distance_bonus, tip_amount
  FROM public.deliveries 
  WHERE id = delivery_id;
  
  total_earnings := base_fee + distance_bonus + tip_amount;
  
  -- Update the delivery record
  UPDATE public.deliveries 
  SET driver_earnings = total_earnings 
  WHERE id = delivery_id;
  
  RETURN total_earnings;
END;
$$ LANGUAGE plpgsql;

-- Comments for documentation
COMMENT ON TABLE public.delivery_messages IS 'In-app messaging between drivers and customers for specific deliveries';
COMMENT ON TABLE public.driver_profiles IS 'Driver-specific information and statistics for delivery partners';
COMMENT ON COLUMN public.deliveries.delivery_type IS 'Type of delivery: pickup_delivery (initial) or return_pickup (end of rental)';
COMMENT ON COLUMN public.deliveries.current_leg IS 'Current stage of the delivery process';
COMMENT ON COLUMN public.deliveries.driver_earnings IS 'Total earnings for driver including base fee, distance bonus, and tips'; 