-- Fix RLS policy for rentals table to allow proper booking creation
-- The current policy is too restrictive and blocks legitimate booking creation

-- Drop the existing restrictive policy
DROP POLICY IF EXISTS "Users can insert rentals for items they don't own" ON public.rentals;

-- Create a more comprehensive policy that allows:
-- 1. Users to create rentals as renters (for items they don't own)
-- 2. Proper validation that the renter_id matches the authenticated user
-- 3. Validation that the item exists and the user is not the owner
CREATE POLICY "Users can create bookings as renters" ON public.rentals
  FOR INSERT WITH CHECK (
    -- User must be authenticated
    auth.uid() IS NOT NULL AND
    -- The renter_id must match the authenticated user
    auth.uid() = renter_id AND
    -- The user must not be the owner of the item (prevent self-booking)
    auth.uid() != owner_id AND
    -- The item must exist (implicit through foreign key, but good to be explicit)
    EXISTS (
      SELECT 1 FROM public.items 
      WHERE id = item_id 
      AND owner_id != auth.uid()
    )
  );

-- Also ensure users can update rentals they are part of (keep existing policy)
-- This policy should already exist, but let's make sure it's correct
DROP POLICY IF EXISTS "Users can update rentals they are part of" ON public.rentals;

CREATE POLICY "Users can update rentals they are part of" ON public.rentals
  FOR UPDATE USING (
    auth.uid() = renter_id OR auth.uid() = owner_id
  );

-- Ensure the SELECT policy is also correct
DROP POLICY IF EXISTS "Users can view rentals they are part of" ON public.rentals;

CREATE POLICY "Users can view rentals they are part of" ON public.rentals
  FOR SELECT USING (
    auth.uid() = renter_id OR auth.uid() = owner_id
  ); 