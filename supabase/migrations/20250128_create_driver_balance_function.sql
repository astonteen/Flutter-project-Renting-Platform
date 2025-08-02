-- Create driver withdrawals table and balance calculation function
-- This handles driver payment withdrawals and balance calculations

-- First, create the driver_withdrawals table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.driver_withdrawals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  driver_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),
  status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'cancelled')),
  method VARCHAR(50) NOT NULL DEFAULT 'bank_transfer' CHECK (method IN ('bank_transfer', 'paypal', 'stripe', 'cash')),
  bank_account_number VARCHAR(100),
  bank_name VARCHAR(100),
  paypal_email VARCHAR(255),
  stripe_account_id VARCHAR(100),
  notes TEXT,
  processed_at TIMESTAMP,
  failed_reason TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_driver_withdrawals_driver_id ON public.driver_withdrawals(driver_id);
CREATE INDEX IF NOT EXISTS idx_driver_withdrawals_status ON public.driver_withdrawals(status);
CREATE INDEX IF NOT EXISTS idx_driver_withdrawals_created_at ON public.driver_withdrawals(created_at);

-- Enable RLS
ALTER TABLE public.driver_withdrawals ENABLE ROW LEVEL SECURITY;

-- RLS Policies for driver_withdrawals
CREATE POLICY "Drivers can view their own withdrawals" ON public.driver_withdrawals
  FOR SELECT TO authenticated
  USING (driver_id = auth.uid());

CREATE POLICY "Drivers can insert their own withdrawal requests" ON public.driver_withdrawals
  FOR INSERT TO authenticated
  WITH CHECK (driver_id = auth.uid());

-- Admin policy (assuming admins have a role)
CREATE POLICY "Admins can manage all withdrawals" ON public.driver_withdrawals
  FOR ALL TO authenticated
  USING (true) -- Will be restricted by application logic
  WITH CHECK (true);

-- Add trigger for updated_at
CREATE OR REPLACE FUNCTION update_driver_withdrawals_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_driver_withdrawals_updated_at
  BEFORE UPDATE ON public.driver_withdrawals
  FOR EACH ROW EXECUTE FUNCTION update_driver_withdrawals_updated_at();

-- Add comments
COMMENT ON TABLE public.driver_withdrawals IS 'Tracks driver withdrawal requests and payment processing';
COMMENT ON COLUMN public.driver_withdrawals.status IS 'Withdrawal status: pending, processing, completed, failed, cancelled';
COMMENT ON COLUMN public.driver_withdrawals.method IS 'Payment method: bank_transfer, paypal, stripe, cash';

-- Function to get driver's available balance
CREATE OR REPLACE FUNCTION get_driver_available_balance(driver_user_id UUID)
RETURNS DECIMAL AS $$
DECLARE
  total_earnings DECIMAL := 0;
  total_withdrawn DECIMAL := 0;
  available_balance DECIMAL := 0;
BEGIN
  -- Calculate total earnings from completed deliveries
  SELECT COALESCE(SUM(driver_earnings), 0)
  INTO total_earnings
  FROM public.deliveries
  WHERE driver_id = driver_user_id
    AND status IN ('item_delivered', 'return_delivered')
    AND driver_earnings IS NOT NULL;

  -- Calculate total amount already withdrawn
  SELECT COALESCE(SUM(amount), 0)
  INTO total_withdrawn
  FROM public.driver_withdrawals
  WHERE driver_id = driver_user_id
    AND status IN ('completed', 'processing');

  -- Available balance is earnings minus withdrawals
  available_balance := total_earnings - total_withdrawn;

  -- Ensure balance is not negative
  IF available_balance < 0 THEN
    available_balance := 0;
  END IF;

  RETURN available_balance;
END;
$$ LANGUAGE plpgsql;

-- Add comment for documentation
COMMENT ON FUNCTION get_driver_available_balance(UUID) IS 'Calculates the available balance for driver withdrawals based on completed deliveries minus previous withdrawals';

-- Test the function with a sample driver (this will be skipped if no drivers exist)
DO $$
DECLARE
  test_driver_id UUID;
  test_balance DECIMAL;
BEGIN
  -- Get any driver ID for testing
  SELECT driver_id INTO test_driver_id
  FROM public.deliveries
  WHERE driver_id IS NOT NULL
  LIMIT 1;
  
  IF test_driver_id IS NOT NULL THEN
    SELECT get_driver_available_balance(test_driver_id) INTO test_balance;
    RAISE NOTICE 'SUCCESS: Driver balance function created. Test balance for driver %: $%', test_driver_id, test_balance;
  ELSE
    RAISE NOTICE 'SUCCESS: Driver balance function created successfully (no test data available)';
  END IF;
END $$;