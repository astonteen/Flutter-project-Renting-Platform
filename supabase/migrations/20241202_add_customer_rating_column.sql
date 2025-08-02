-- Add customer_rating column to rentals table
ALTER TABLE rentals 
ADD COLUMN customer_rating DECIMAL(2,1) CHECK (customer_rating >= 1.0 AND customer_rating <= 5.0);

-- Add index for customer_rating for performance
CREATE INDEX IF NOT EXISTS idx_rentals_customer_rating ON rentals(customer_rating);

-- Add comment for documentation
COMMENT ON COLUMN rentals.customer_rating IS 'Customer rating for the rental experience (1.0 to 5.0)'; 