-- Note: This migration creates sample data that matches the actual database schema
-- Removed columns that don't exist: view_count, rating, review_count, image_urls, features, specifications

-- Insert sample categories if they don't exist
INSERT INTO categories (id, name, icon, description) VALUES
  (gen_random_uuid(), 'Electronics', 'devices', 'Cameras, laptops, phones, and gadgets'),
  (gen_random_uuid(), 'Tools & Equipment', 'build', 'Power tools, hand tools, and equipment'),
  (gen_random_uuid(), 'Sports & Recreation', 'sports_soccer', 'Bikes, sports equipment, and outdoor gear'),
  (gen_random_uuid(), 'Vehicles', 'directions_car', 'Cars, motorcycles, and transportation'),
  (gen_random_uuid(), 'Home & Garden', 'home', 'Furniture, appliances, and garden tools'),
  (gen_random_uuid(), 'Fashion & Accessories', 'checkroom', 'Clothing, jewelry, and accessories')
ON CONFLICT (name) DO NOTHING;

-- Create a default user if none exists (for testing purposes)
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at)
SELECT 
  gen_random_uuid(),
  'test@example.com',
  '$2a$10$example_hash',
  NOW(),
  NOW(),
  NOW()
WHERE NOT EXISTS (SELECT 1 FROM auth.users LIMIT 1);

-- Insert the corresponding profile
INSERT INTO profiles (id, full_name, email, primary_role, roles, created_at, updated_at)
SELECT 
  u.id,
  'Eugene Wong',
  'test@example.com',
  'owner',
  ARRAY['owner', 'renter'],
  NOW(),
  NOW()
FROM auth.users u
WHERE u.email = 'test@example.com'
ON CONFLICT (id) DO NOTHING;

-- Insert sample items (only if no items exist)
INSERT INTO items (
  id,
  name,
  description,
  category_id,
  price_per_day,
  price_per_week,
  price_per_month,
  security_deposit,
  location,
  latitude,
  longitude,
  condition,
  available,
  featured,
  owner_id,
  created_at,
  updated_at
)
SELECT 
  gen_random_uuid(),
  'Canon EOS R5 Camera',
  'Professional mirrorless camera perfect for photography and videography. Includes lens, battery, and memory card.',
  (SELECT id FROM categories WHERE name = 'Electronics' LIMIT 1),
  45.0,
  280.0,
  1000.0,
  200.0,
  'Downtown, San Francisco',
  37.7749,
  -122.4194,
  'excellent',
  true,
  true,
  (SELECT id FROM profiles LIMIT 1),
  NOW() - INTERVAL '5 days',
  NOW() - INTERVAL '1 day'
WHERE NOT EXISTS (SELECT 1 FROM items LIMIT 1);

INSERT INTO items (
  id,
  name,
  description,
  category_id,
  price_per_day,
  price_per_week,
  price_per_month,
  security_deposit,
  location,
  latitude,
  longitude,
  condition,
  available,
  featured,
  owner_id,
  created_at,
  updated_at
)
SELECT 
  gen_random_uuid(),
  'Mountain Bike - Trek X-Caliber',
  'High-quality mountain bike perfect for trails and outdoor adventures. 21-speed with front suspension.',
  (SELECT id FROM categories WHERE name = 'Sports & Recreation' LIMIT 1),
  25.0,
  150.0,
  500.0,
  100.0,
  'Mission District, San Francisco',
  37.7599,
  -122.4148,
  'good',
  true,
  true,
  (SELECT id FROM profiles LIMIT 1),
  NOW() - INTERVAL '10 days',
  NOW() - INTERVAL '2 days'
WHERE EXISTS (SELECT 1 FROM items WHERE name LIKE '%Canon%');