-- Create profiles table that extends the auth.users table
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  full_name TEXT,
  email TEXT UNIQUE NOT NULL,
  phone_number TEXT,
  avatar_url TEXT,
  location TEXT,
  bio TEXT,
  primary_role TEXT DEFAULT 'renter' CHECK (primary_role IN ('renter', 'owner', 'driver')),
  roles TEXT[] DEFAULT ARRAY['renter'],
  enable_notifications BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Create categories table
CREATE TABLE IF NOT EXISTS public.categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL UNIQUE,
  description TEXT,
  icon TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Create items table
CREATE TABLE IF NOT EXISTS public.items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT,
  owner_id UUID REFERENCES public.profiles(id) NOT NULL,
  category_id UUID REFERENCES public.categories(id),
  price_per_day DECIMAL(10, 2) NOT NULL,
  price_per_week DECIMAL(10, 2),
  price_per_month DECIMAL(10, 2),
  security_deposit DECIMAL(10, 2),
  location TEXT,
  latitude DECIMAL(9, 6),
  longitude DECIMAL(9, 6),
  condition TEXT,
  available BOOLEAN DEFAULT TRUE,
  featured BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Create item_images table
CREATE TABLE IF NOT EXISTS public.item_images (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  item_id UUID REFERENCES public.items(id) ON DELETE CASCADE,
  image_url TEXT NOT NULL,
  is_primary BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Create rentals table
CREATE TABLE IF NOT EXISTS public.rentals (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  item_id UUID REFERENCES public.items(id) NOT NULL,
  renter_id UUID REFERENCES public.profiles(id) NOT NULL,
  owner_id UUID REFERENCES public.profiles(id) NOT NULL,
  start_date TIMESTAMP WITH TIME ZONE NOT NULL,
  end_date TIMESTAMP WITH TIME ZONE NOT NULL,
  total_price DECIMAL(10, 2) NOT NULL,
  security_deposit DECIMAL(10, 2),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'in_progress', 'completed', 'cancelled')),
  payment_status TEXT DEFAULT 'pending' CHECK (payment_status IN ('pending', 'paid', 'refunded', 'failed')),
  delivery_required BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Create deliveries table
CREATE TABLE IF NOT EXISTS public.deliveries (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  rental_id UUID REFERENCES public.rentals(id) NOT NULL,
  driver_id UUID REFERENCES public.profiles(id),
  pickup_address TEXT NOT NULL,
  pickup_latitude DECIMAL(9, 6),
  pickup_longitude DECIMAL(9, 6),
  dropoff_address TEXT NOT NULL,
  dropoff_latitude DECIMAL(9, 6),
  dropoff_longitude DECIMAL(9, 6),
  pickup_time TIMESTAMP WITH TIME ZONE,
  dropoff_time TIMESTAMP WITH TIME ZONE,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'in_transit', 'delivered', 'cancelled')),
  fee DECIMAL(10, 2) NOT NULL,
  payment_status TEXT DEFAULT 'pending' CHECK (payment_status IN ('pending', 'paid', 'refunded', 'failed')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Create messages table
CREATE TABLE IF NOT EXISTS public.messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  sender_id UUID REFERENCES public.profiles(id) NOT NULL,
  receiver_id UUID REFERENCES public.profiles(id) NOT NULL,
  content TEXT NOT NULL,
  related_item_id UUID REFERENCES public.items(id),
  related_rental_id UUID REFERENCES public.rentals(id),
  read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Create reviews table
CREATE TABLE IF NOT EXISTS public.reviews (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  reviewer_id UUID REFERENCES public.profiles(id) NOT NULL,
  reviewed_id UUID REFERENCES public.profiles(id) NOT NULL,
  rental_id UUID REFERENCES public.rentals(id),
  item_id UUID REFERENCES public.items(id),
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Set up Row Level Security (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.item_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rentals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.deliveries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;

-- Create policies for profiles
CREATE POLICY "Public profiles are viewable by everyone" ON public.profiles
  FOR SELECT USING (true);

CREATE POLICY "Users can insert their own profile" ON public.profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON public.profiles
  FOR UPDATE USING (auth.uid() = id);

-- Create policies for items
CREATE POLICY "Items are viewable by everyone" ON public.items
  FOR SELECT USING (true);

CREATE POLICY "Users can insert their own items" ON public.items
  FOR INSERT WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Users can update their own items" ON public.items
  FOR UPDATE USING (auth.uid() = owner_id);

CREATE POLICY "Users can delete their own items" ON public.items
  FOR DELETE USING (auth.uid() = owner_id);

-- Create policies for item_images
CREATE POLICY "Item images are viewable by everyone" ON public.item_images
  FOR SELECT USING (true);

CREATE POLICY "Users can insert images for their own items" ON public.item_images
  FOR INSERT WITH CHECK (
    auth.uid() IN (
      SELECT owner_id FROM public.items WHERE id = item_id
    )
  );

CREATE POLICY "Users can update images for their own items" ON public.item_images
  FOR UPDATE USING (
    auth.uid() IN (
      SELECT owner_id FROM public.items WHERE id = item_id
    )
  );

CREATE POLICY "Users can delete images for their own items" ON public.item_images
  FOR DELETE USING (
    auth.uid() IN (
      SELECT owner_id FROM public.items WHERE id = item_id
    )
  );

-- Create policies for rentals
CREATE POLICY "Users can view rentals they are part of" ON public.rentals
  FOR SELECT USING (
    auth.uid() = renter_id OR auth.uid() = owner_id
  );

CREATE POLICY "Users can insert rentals for items they don't own" ON public.rentals
  FOR INSERT WITH CHECK (
    auth.uid() = renter_id AND auth.uid() != owner_id
  );

CREATE POLICY "Users can update rentals they are part of" ON public.rentals
  FOR UPDATE USING (
    auth.uid() = renter_id OR auth.uid() = owner_id
  );

-- Create policies for deliveries
CREATE POLICY "Users can view deliveries they are part of" ON public.deliveries
  FOR SELECT USING (
    auth.uid() = driver_id OR 
    auth.uid() IN (
      SELECT renter_id FROM public.rentals WHERE id = rental_id
    ) OR
    auth.uid() IN (
      SELECT owner_id FROM public.rentals WHERE id = rental_id
    )
  );

CREATE POLICY "Drivers can update deliveries assigned to them" ON public.deliveries
  FOR UPDATE USING (
    auth.uid() = driver_id
  );

-- Create policies for messages
CREATE POLICY "Users can view messages they sent or received" ON public.messages
  FOR SELECT USING (
    auth.uid() = sender_id OR auth.uid() = receiver_id
  );

CREATE POLICY "Users can send messages" ON public.messages
  FOR INSERT WITH CHECK (
    auth.uid() = sender_id
  );

CREATE POLICY "Users can update messages they sent" ON public.messages
  FOR UPDATE USING (
    auth.uid() = sender_id
  );

-- Create policies for reviews
CREATE POLICY "Reviews are viewable by everyone" ON public.reviews
  FOR SELECT USING (true);

CREATE POLICY "Users can insert reviews for completed rentals" ON public.reviews
  FOR INSERT WITH CHECK (
    auth.uid() = reviewer_id AND
    (rental_id IS NULL OR EXISTS (
      SELECT 1 FROM public.rentals
      WHERE id = rental_id AND status = 'completed' AND
      (auth.uid() = renter_id OR auth.uid() = owner_id)
    ))
  );

-- Create function to update updated_at column
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = TIMEZONE('utc', NOW());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers to automatically update updated_at column
CREATE TRIGGER update_profiles_updated_at
BEFORE UPDATE ON public.profiles
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_items_updated_at
BEFORE UPDATE ON public.items
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_rentals_updated_at
BEFORE UPDATE ON public.rentals
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_deliveries_updated_at
BEFORE UPDATE ON public.deliveries
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert some initial categories
INSERT INTO public.categories (name, description, icon) VALUES
  ('Electronics', 'Electronic devices and gadgets', 'electronics'),
  ('Tools', 'Hand tools, power tools, and equipment', 'tools'),
  ('Sports', 'Sports equipment and gear', 'sports'),
  ('Outdoor', 'Camping, hiking, and outdoor equipment', 'outdoor'),
  ('Party', 'Party supplies and equipment', 'party'),
  ('Vehicles', 'Cars, bikes, and other vehicles', 'vehicles'),
  ('Clothing', 'Costumes, formal wear, and specialty clothing', 'clothing'),
  ('Photography', 'Cameras, lenses, and photography equipment', 'photography'),
  ('Music', 'Musical instruments and equipment', 'music'),
  ('Gaming', 'Video game consoles and accessories', 'gaming');

-- Create a trigger to create a profile entry when a new user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, email)
  VALUES (NEW.id, NEW.raw_user_meta_data->>'full_name', NEW.email);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user(); 