-- Migration: Cleanup Delivery Data Redundancy
-- Date: 2024-12-01
-- Purpose: Remove redundant delivery fields from rentals table, 
--          use deliveries table as single source of truth

-- Step 1: Data validation and migration (if needed)
-- Skip data migration as columns may not exist yet

-- Step 2: Remove redundant columns from rentals table
-- These fields will now be managed exclusively through the deliveries table

ALTER TABLE rentals 
DROP COLUMN IF EXISTS delivery_address;

ALTER TABLE rentals 
DROP COLUMN IF EXISTS delivery_instructions;

-- Step 3: Add comments for clarity
COMMENT ON COLUMN rentals.delivery_required IS 
'Boolean flag indicating if this rental needs delivery. When true, a corresponding record should exist in deliveries table.';

COMMENT ON TABLE deliveries IS 
'Single source of truth for all delivery information. Contains pickup/dropoff addresses, instructions, and delivery workflow data.';

-- Step 4: Create a view for easy rental + delivery data access (optional)
CREATE OR REPLACE VIEW rental_with_delivery AS
SELECT 
  r.*,
  d.id as delivery_id,
  d.pickup_address,
  d.dropoff_address,
  d.status as delivery_status,
  d.fee as delivery_fee,
  d.driver_id,
  d.pickup_time,
  d.dropoff_time
FROM rentals r
LEFT JOIN deliveries d ON r.id = d.rental_id;

-- Step 5: Add RLS policy for the new view
ALTER VIEW rental_with_delivery OWNER TO postgres;
GRANT SELECT ON rental_with_delivery TO authenticated, anon;

-- Step 6: Update the auto-delivery creation trigger to ensure consistency
-- This trigger ensures a delivery record is created when rental.delivery_required = true
CREATE OR REPLACE FUNCTION create_delivery_on_rental_insert()
RETURNS TRIGGER AS $$
BEGIN
  -- If delivery is required but no delivery record exists, create one
  IF NEW.delivery_required = true THEN
    INSERT INTO deliveries (
      rental_id,
      pickup_address,
      dropoff_address,
      fee,
      status,
      delivery_type,
      current_leg
    ) VALUES (
      NEW.id,
      'TBD - Owner Address', -- Will be updated when owner profile is available
      'TBD - Delivery Address', -- Will be updated when renter provides address
      10.00, -- Default delivery fee
      'pending',
      'pickup_and_delivery',
      'pending_assignment'
    )
    ON CONFLICT (rental_id) DO NOTHING; -- Prevent duplicates
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate the trigger
DROP TRIGGER IF EXISTS trigger_create_delivery_on_rental ON rentals;
CREATE TRIGGER trigger_create_delivery_on_rental
  AFTER INSERT OR UPDATE OF delivery_required ON rentals
  FOR EACH ROW 
  EXECUTE FUNCTION create_delivery_on_rental_insert();

-- Step 7: Data integrity check
-- Verify all rentals requiring delivery have delivery records
DO $$
DECLARE
  missing_deliveries INTEGER;
BEGIN
  SELECT COUNT(*) INTO missing_deliveries
  FROM rentals r
  LEFT JOIN deliveries d ON r.id = d.rental_id
  WHERE r.delivery_required = true AND d.id IS NULL;
  
  IF missing_deliveries > 0 THEN
    RAISE EXCEPTION 'Data integrity error: % rentals require delivery but have no delivery record', missing_deliveries;
  END IF;
  
  RAISE NOTICE 'Data integrity check passed: All rentals requiring delivery have delivery records';
END $$;