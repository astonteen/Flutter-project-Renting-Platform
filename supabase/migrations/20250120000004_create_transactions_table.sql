-- Create transactions table for payment tracking
-- This table will store transaction records for rental payments

CREATE TABLE IF NOT EXISTS public.transactions (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  rental_id UUID REFERENCES public.rentals(id) NOT NULL,
  transaction_id TEXT NOT NULL, -- External transaction ID from payment processor
  amount DECIMAL(10, 2) NOT NULL,
  payment_method TEXT,
  payment_status TEXT DEFAULT 'pending' CHECK (payment_status IN ('pending', 'processing', 'completed', 'failed', 'cancelled', 'refunded')),
  gateway_response JSONB, -- For storing payment gateway response data
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS transactions_rental_id_idx ON public.transactions (rental_id);
CREATE INDEX IF NOT EXISTS transactions_transaction_id_idx ON public.transactions (transaction_id);
CREATE INDEX IF NOT EXISTS transactions_payment_status_idx ON public.transactions (payment_status);
CREATE INDEX IF NOT EXISTS transactions_created_at_idx ON public.transactions (created_at);

-- Enable Row Level Security
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;

-- Create policies for transactions
CREATE POLICY "Users can view transactions for their rentals" ON public.transactions
  FOR SELECT USING (
    auth.uid() IN (
      SELECT renter_id FROM public.rentals WHERE id = rental_id
    ) OR 
    auth.uid() IN (
      SELECT owner_id FROM public.rentals WHERE id = rental_id
    )
  );

CREATE POLICY "Users can insert transactions for their rentals" ON public.transactions
  FOR INSERT WITH CHECK (
    auth.uid() IN (
      SELECT renter_id FROM public.rentals WHERE id = rental_id
    )
  );

CREATE POLICY "Users can update transactions for their rentals" ON public.transactions
  FOR UPDATE USING (
    auth.uid() IN (
      SELECT renter_id FROM public.rentals WHERE id = rental_id
    ) OR 
    auth.uid() IN (
      SELECT owner_id FROM public.rentals WHERE id = rental_id
    )
  );

-- Create trigger to automatically update updated_at column
CREATE TRIGGER update_transactions_updated_at
BEFORE UPDATE ON public.transactions
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();