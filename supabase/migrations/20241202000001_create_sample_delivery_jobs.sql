-- Migration: Create sample delivery jobs for existing rentals
-- This will help populate the delivery dashboard with data

-- First, let's update existing rentals that should have delivery_required = true
-- We'll assume any rental created recently might need delivery
UPDATE rentals 
SET delivery_required = true 
WHERE created_at >= '2024-12-01' 
AND delivery_required = false
AND total_price > 20; -- Only for rentals above $20

-- Create delivery jobs for rentals that have delivery_required = true but no delivery record
INSERT INTO deliveries (
  rental_id,
  pickup_address,
  dropoff_address,
  fee,
  status,
  delivery_type,
  current_leg,
  estimated_duration,
  distance_km,
  driver_earnings,
  item_name,
  special_instructions,
  customer_tip,
  created_at,
  updated_at
)
SELECT 
  r.id as rental_id,
  i.location as pickup_address,
  'Customer address - ' || COALESCE(p.location, 'Location to be provided') as dropoff_address,
  15.0 as fee,
  'available' as status,
  'pickup_delivery' as delivery_type,
  'pickup' as current_leg,
  30 as estimated_duration,
  5.0 as distance_km,
  12.0 as driver_earnings,
  i.name as item_name,
  'Please handle with care' as special_instructions,
  0.0 as customer_tip,
  r.created_at,
  NOW() as updated_at
FROM rentals r
JOIN items i ON r.item_id = i.id
JOIN profiles p ON r.renter_id = p.id
LEFT JOIN deliveries d ON r.id = d.rental_id
WHERE r.delivery_required = true 
AND d.id IS NULL
AND r.status IN ('pending', 'confirmed');

-- Add some variety to the sample data
UPDATE deliveries 
SET status = 'accepted',
    driver_id = (
      SELECT user_id 
      FROM driver_profiles 
      WHERE is_active = true 
      LIMIT 1
    )
WHERE status = 'available'
AND random() < 0.3; -- 30% chance to be accepted

-- Mark some as completed with earnings
UPDATE deliveries 
SET status = 'delivered',
    dropoff_time = created_at + INTERVAL '2 hours',
    pickup_time = created_at + INTERVAL '30 minutes'
WHERE status = 'accepted'
AND random() < 0.5; -- 50% chance of accepted deliveries are completed

-- Add some customer tips to completed deliveries
UPDATE deliveries 
SET customer_tip = (random() * 5)::decimal(10,2)
WHERE status = 'delivered'
AND random() < 0.4; -- 40% chance of getting a tip

-- Create some return delivery jobs for completed rentals
INSERT INTO deliveries (
  rental_id,
  pickup_address,
  dropoff_address,
  fee,
  status,
  delivery_type,
  current_leg,
  estimated_duration,
  distance_km,
  driver_earnings,
  item_name,
  special_instructions,
  customer_tip,
  created_at,
  updated_at
)
SELECT 
  r.id as rental_id,
  'Customer return location' as pickup_address,
  i.location as dropoff_address,
  15.0 as fee,
  'available' as status,
  'return_pickup' as delivery_type,
  'pickup' as current_leg,
  30 as estimated_duration,
  5.0 as distance_km,
  12.0 as driver_earnings,
  i.name || ' (Return)' as item_name,
  'Return pickup - item rental completed' as special_instructions,
  0.0 as customer_tip,
  r.end_date,
  NOW() as updated_at
FROM rentals r
JOIN items i ON r.item_id = i.id
WHERE r.delivery_required = true 
AND r.status = 'completed'
AND r.end_date < NOW()
AND NOT EXISTS (
  SELECT 1 FROM deliveries d 
  WHERE d.rental_id = r.id 
  AND d.delivery_type = 'return_pickup'
);

COMMENT ON TABLE deliveries IS 'Updated with sample data to demonstrate the delivery system functionality'; 