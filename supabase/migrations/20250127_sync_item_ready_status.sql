-- Sync is_item_ready field with booking status for existing bookings
-- This fixes the inconsistency where status indicates item should be ready but is_item_ready is false

UPDATE rentals 
SET is_item_ready = true, updated_at = NOW()
WHERE status IN (
  'ready_for_pickup',
  'in_transit', 
  'picked_up',
  'in_progress',
  'ready_to_return',
  'returning',
  'completed'
) 
AND is_item_ready = false;

-- Add a comment to track this migration
COMMENT ON TABLE rentals IS 'Updated 2025-01-27: Synced is_item_ready field with booking status for consistency';