-- ========================================
-- EMERGENCY FIX FOR DELIVERY_NOTIFICATIONS RLS ERROR
-- ========================================
-- Execute this IMMEDIATELY in your Supabase SQL Editor
-- to fix the booking creation errors
-- ========================================

-- 1. Create the missing delivery_notifications table
CREATE TABLE IF NOT EXISTS public.delivery_notifications (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  delivery_id UUID REFERENCES public.deliveries(id) NOT NULL,
  recipient_id UUID REFERENCES public.profiles(id) NOT NULL,
  notification_type TEXT NOT NULL CHECK (notification_type IN (
    'delivery_requested', 'driver_assigned', 'item_picked_up', 
    'item_delivered', 'return_scheduled', 'return_completed',
    'delivery_cancelled', 'delivery_delayed'
  )),
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  is_read BOOLEAN DEFAULT FALSE,
  sent_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  read_at TIMESTAMP WITH TIME ZONE,
  push_notification_sent BOOLEAN DEFAULT FALSE,
  email_sent BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- 2. Create essential indexes
CREATE INDEX IF NOT EXISTS delivery_notifications_delivery_id_idx ON public.delivery_notifications (delivery_id);
CREATE INDEX IF NOT EXISTS delivery_notifications_recipient_id_idx ON public.delivery_notifications (recipient_id);

-- 3. Enable Row Level Security
ALTER TABLE public.delivery_notifications ENABLE ROW LEVEL SECURITY;

-- 4. Create RLS policies
CREATE POLICY "Users can view their own notifications" ON public.delivery_notifications
  FOR SELECT USING (auth.uid() = recipient_id);

CREATE POLICY "Users can update their own notifications" ON public.delivery_notifications
  FOR UPDATE USING (auth.uid() = recipient_id);

-- Allow system to create notifications for any user (this fixes the RLS error)
CREATE POLICY "System can create delivery notifications" ON public.delivery_notifications
  FOR INSERT WITH CHECK (true);

-- 5. Create the missing RPC function (this is what the database triggers are calling)
CREATE OR REPLACE FUNCTION create_delivery_notification(
  p_delivery_id UUID,
  p_recipient_id UUID,
  p_notification_type TEXT,
  p_title TEXT,
  p_message TEXT
) RETURNS UUID AS $$
DECLARE
  notification_id UUID;
BEGIN
  INSERT INTO public.delivery_notifications (
    delivery_id, recipient_id, notification_type, title, message
  ) VALUES (
    p_delivery_id, p_recipient_id, p_notification_type, p_title, p_message
  ) RETURNING id INTO notification_id;
  
  RETURN notification_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Add updated_at trigger
CREATE TRIGGER update_delivery_notifications_updated_at
BEFORE UPDATE ON public.delivery_notifications
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 7. Verify table was created
SELECT 'SUCCESS: delivery_notifications table created!' as status
WHERE EXISTS (
  SELECT 1 FROM information_schema.tables 
  WHERE table_name = 'delivery_notifications' 
  AND table_schema = 'public'
);

-- ========================================
-- INSTRUCTIONS:
-- ========================================
-- 1. Copy this entire script
-- 2. Go to your Supabase Dashboard
-- 3. Navigate to SQL Editor
-- 4. Paste and run this script
-- 5. Test booking creation in your app
-- 
-- The RLS errors should be COMPLETELY FIXED!
-- ======================================== 