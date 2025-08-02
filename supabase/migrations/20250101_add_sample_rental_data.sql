-- Add sample rental data for testing booking management screen

-- First, let's ensure we have some sample items and profiles
INSERT INTO public.profiles (id, full_name, email, phone_number, avatar_url, primary_role, roles) VALUES
  ('550e8400-e29b-41d4-a716-446655440001', 'John Smith', 'john.smith@example.com', '+1 (555) 123-4567', 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=100', 'renter', ARRAY['renter']),
  ('550e8400-e29b-41d4-a716-446655440002', 'Sarah Johnson', 'sarah.johnson@example.com', '+1 (555) 987-6543', 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=100', 'renter', ARRAY['renter']),
  ('550e8400-e29b-41d4-a716-446655440003', 'Mike Chen', 'mike.chen@example.com', '+1 (555) 456-7890', 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100', 'renter', ARRAY['renter']),
  ('550e8400-e29b-41d4-a716-446655440004', 'Emily Davis', 'emily.davis@example.com', '+1 (555) 321-9876', 'https://images.unsplash.com/photo-1494790108755-2616b9f2e0f0?w=100', 'renter', ARRAY['renter'])
ON CONFLICT (id) DO UPDATE SET
  full_name = EXCLUDED.full_name,
  email = EXCLUDED.email,
  phone_number = EXCLUDED.phone_number,
  avatar_url = EXCLUDED.avatar_url;

-- Add sample categories
INSERT INTO public.categories (id, name, description, icon) VALUES
  ('cat-1', 'Electronics', 'Electronic devices and gadgets', 'electronics'),
  ('cat-2', 'Photography', 'Camera equipment and accessories', 'camera')
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description;

-- Add sample items (using the existing user ID from the current session)
INSERT INTO public.items (id, name, description, owner_id, category_id, price_per_day, price_per_week, price_per_month, security_deposit, location, available, featured) VALUES
  ('daae0375-25f3-4294-aeab-9f7254c0931c', 'Professional Camera Kit', 'High-end DSLR camera with professional lenses and accessories. Perfect for photography enthusiasts and professionals.', 'dc45aec1-8c8e-4c2c-8e60-b4ca6d04fa51', 'cat-2', 80.00, 500.00, 1800.00, 200.00, 'San Francisco, CA', true, true),
  ('item-2', 'Laptop - MacBook Pro', 'Latest MacBook Pro with M3 chip, perfect for video editing and development work.', 'dc45aec1-8c8e-4c2c-8e60-b4ca6d04fa51', 'cat-1', 120.00, 750.00, 2500.00, 500.00, 'San Francisco, CA', true, false)
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  price_per_day = EXCLUDED.price_per_day,
  available = EXCLUDED.available;

-- Add sample item images
INSERT INTO public.item_images (id, item_id, image_url, is_primary) VALUES
  ('img-1', 'daae0375-25f3-4294-aeab-9f7254c0931c', 'https://images.unsplash.com/photo-1502920917128-1aa500764cbd?w=400', true),
  ('img-2', 'daae0375-25f3-4294-aeab-9f7254c0931c', 'https://images.unsplash.com/photo-1606983340126-99ab4feaa64a?w=400', false),
  ('img-3', 'item-2', 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=400', true)
ON CONFLICT (id) DO UPDATE SET
  image_url = EXCLUDED.image_url,
  is_primary = EXCLUDED.is_primary;

-- Add sample rental bookings for the camera kit
INSERT INTO public.rentals (id, item_id, renter_id, owner_id, start_date, end_date, total_price, security_deposit, status, payment_status, delivery_required) VALUES
  -- Active today: started yesterday, ends tomorrow
  ('rental-1', 'daae0375-25f3-4294-aeab-9f7254c0931c', '550e8400-e29b-41d4-a716-446655440001', 'dc45aec1-8c8e-4c2c-8e60-b4ca6d04fa51', 
   CURRENT_TIMESTAMP - INTERVAL '1 day', CURRENT_TIMESTAMP + INTERVAL '1 day', 160.00, 200.00, 'in_progress', 'paid', true),
  
  -- Active today: started today, ends in 3 days
  ('rental-2', 'item-2', '550e8400-e29b-41d4-a716-446655440002', 'dc45aec1-8c8e-4c2c-8e60-b4ca6d04fa51', 
   CURRENT_TIMESTAMP, CURRENT_TIMESTAMP + INTERVAL '3 days', 360.00, 500.00, 'confirmed', 'paid', false),
  
  -- Upcoming: starts in 2 days
  ('rental-3', 'daae0375-25f3-4294-aeab-9f7254c0931c', '550e8400-e29b-41d4-a716-446655440003', 'dc45aec1-8c8e-4c2c-8e60-b4ca6d04fa51', 
   CURRENT_TIMESTAMP + INTERVAL '2 days', CURRENT_TIMESTAMP + INTERVAL '5 days', 240.00, 200.00, 'confirmed', 'paid', true),
  
  -- Upcoming: starts in 7 days
  ('rental-4', 'daae0375-25f3-4294-aeab-9f7254c0931c', '550e8400-e29b-41d4-a716-446655440004', 'dc45aec1-8c8e-4c2c-8e60-b4ca6d04fa51', 
   CURRENT_TIMESTAMP + INTERVAL '7 days', CURRENT_TIMESTAMP + INTERVAL '9 days', 160.00, 200.00, 'pending', 'pending', false),
  
  -- Upcoming: starts in 10 days
  ('rental-5', 'item-2', '550e8400-e29b-41d4-a716-446655440001', 'dc45aec1-8c8e-4c2c-8e60-b4ca6d04fa51', 
   CURRENT_TIMESTAMP + INTERVAL '10 days', CURRENT_TIMESTAMP + INTERVAL '17 days', 840.00, 500.00, 'confirmed', 'paid', false)
ON CONFLICT (id) DO UPDATE SET
  status = EXCLUDED.status,
  payment_status = EXCLUDED.payment_status,
  total_price = EXCLUDED.total_price;