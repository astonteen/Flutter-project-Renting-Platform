-- Add is_item_ready column to rentals table
-- This enables lenders to mark items as ready for pickup

-- Add the column with default false for existing records
ALTER TABLE rentals ADD COLUMN is_item_ready BOOLEAN DEFAULT FALSE;

-- Add comment for documentation
COMMENT ON COLUMN rentals.is_item_ready IS 'Indicates if the item is prepared and ready for pickup by the renter';

-- Update any confirmed bookings older than 1 day to ready (assumption: old bookings should be ready)
UPDATE rentals 
SET is_item_ready = TRUE 
WHERE status = 'confirmed' 
  AND created_at < NOW() - INTERVAL '1 day';