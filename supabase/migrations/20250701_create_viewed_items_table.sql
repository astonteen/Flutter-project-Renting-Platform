-- Create viewed_items table
CREATE TABLE IF NOT EXISTS public.viewed_items (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  item_id UUID NOT NULL REFERENCES public.items(id) ON DELETE CASCADE,
  viewed_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Create unique index to prevent duplicates, but allow updates
CREATE UNIQUE INDEX IF NOT EXISTS viewed_items_user_item_unique ON public.viewed_items (user_id, item_id);

-- Enable Row Level Security
ALTER TABLE public.viewed_items ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can manage their own viewed items" ON public.viewed_items
  FOR ALL USING (auth.uid() = user_id);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS viewed_items_user_id_idx ON public.viewed_items (user_id);
CREATE INDEX IF NOT EXISTS viewed_items_item_id_idx ON public.viewed_items (item_id);
CREATE INDEX IF NOT EXISTS viewed_items_viewed_at_idx ON public.viewed_items (viewed_at DESC);