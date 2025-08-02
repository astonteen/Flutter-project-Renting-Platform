-- Update existing rental data to have some active bookings for today

-- Update rental-1 to be active today (started yesterday, ends tomorrow)
UPDATE public.rentals 
SET 
  start_date = CURRENT_TIMESTAMP - INTERVAL '1 day',
  end_date = CURRENT_TIMESTAMP + INTERVAL '1 day',
  status = 'in_progress',
  total_price = 160.00
WHERE id = 'rental-1';

-- Update rental-2 to be active today (started today, ends in 3 days)
UPDATE public.rentals 
SET 
  start_date = CURRENT_TIMESTAMP,
  end_date = CURRENT_TIMESTAMP + INTERVAL '3 days',
  status = 'confirmed',
  total_price = 360.00,
  item_id = 'item-2',
  renter_id = '550e8400-e29b-41d4-a716-446655440002'
WHERE id = 'rental-2';

-- Update rental-3 to be upcoming (starts in 2 days)
UPDATE public.rentals 
SET 
  start_date = CURRENT_TIMESTAMP + INTERVAL '2 days',
  end_date = CURRENT_TIMESTAMP + INTERVAL '5 days',
  status = 'confirmed',
  total_price = 240.00
WHERE id = 'rental-3';

-- Update rental-4 to be upcoming (starts in 7 days)
UPDATE public.rentals 
SET 
  start_date = CURRENT_TIMESTAMP + INTERVAL '7 days',
  end_date = CURRENT_TIMESTAMP + INTERVAL '9 days',
  status = 'pending',
  total_price = 160.00
WHERE id = 'rental-4';

-- Update rental-5 to be upcoming (starts in 10 days)
UPDATE public.rentals 
SET 
  start_date = CURRENT_TIMESTAMP + INTERVAL '10 days',
  end_date = CURRENT_TIMESTAMP + INTERVAL '17 days',
  status = 'confirmed',
  total_price = 840.00
WHERE id = 'rental-5';