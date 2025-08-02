# Manual Supabase Setup for Saved Addresses

Since the Supabase CLI and MCP server are encountering authentication issues, you'll need to manually set up the `saved_addresses` table through the Supabase Dashboard.

## Steps to Set Up the Table

### 1. Access Supabase Dashboard
1. Go to [https://supabase.com/dashboard](https://supabase.com/dashboard)
2. Sign in to your account
3. Navigate to your project: `iwefwascboexieneeaks`

### 2. Create the Table
1. Go to **Table Editor** in the left sidebar
2. Click **Create a new table**
3. Set table name: `saved_addresses`
4. Add the following columns:

| Column Name | Type | Default Value | Constraints |
|-------------|------|---------------|-------------|
| id | uuid | gen_random_uuid() | Primary Key |
| user_id | uuid | - | Foreign Key to auth.users(id), NOT NULL |
| title | varchar(100) | - | NOT NULL |
| street_address | text | - | NOT NULL |
| city | varchar(100) | - | NOT NULL |
| state | varchar(100) | - | NOT NULL |
| postal_code | varchar(20) | - | NOT NULL |
| country | varchar(100) | 'United States' | NOT NULL |
| latitude | numeric(10,8) | - | - |
| longitude | numeric(11,8) | - | - |
| is_default | boolean | false | NOT NULL |
| created_at | timestamptz | now() | - |
| updated_at | timestamptz | now() | - |

### 3. Set Up Row Level Security (RLS)
1. Go to **Authentication** > **Policies** in the left sidebar
2. Find the `saved_addresses` table
3. Click **Enable RLS** if not already enabled
4. Add the following policies:

#### Policy 1: Users can view their own saved addresses
- **Policy name**: `Users can view their own saved addresses`
- **Allowed operation**: SELECT
- **Target roles**: authenticated
- **USING expression**: `auth.uid() = user_id`

#### Policy 2: Users can insert their own saved addresses
- **Policy name**: `Users can insert their own saved addresses`
- **Allowed operation**: INSERT
- **Target roles**: authenticated
- **WITH CHECK expression**: `auth.uid() = user_id`

#### Policy 3: Users can update their own saved addresses
- **Policy name**: `Users can update their own saved addresses`
- **Allowed operation**: UPDATE
- **Target roles**: authenticated
- **USING expression**: `auth.uid() = user_id`

#### Policy 4: Users can delete their own saved addresses
- **Policy name**: `Users can delete their own saved addresses`
- **Allowed operation**: DELETE
- **Target roles**: authenticated
- **USING expression**: `auth.uid() = user_id`

### 4. Create Database Functions and Triggers
1. Go to **SQL Editor** in the left sidebar
2. Run the following SQL commands:

```sql
-- Function to ensure only one default address per user
CREATE OR REPLACE FUNCTION public.ensure_single_default_address()
RETURNS TRIGGER AS $$
BEGIN
    -- If setting this address as default, unset all other defaults for this user
    IF NEW.is_default = true THEN
        UPDATE public.saved_addresses 
        SET is_default = false 
        WHERE user_id = NEW.user_id AND id != NEW.id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for default address management
CREATE TRIGGER trigger_ensure_single_default_address
    BEFORE INSERT OR UPDATE ON public.saved_addresses
    FOR EACH ROW
    EXECUTE FUNCTION public.ensure_single_default_address();

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for updated_at timestamp
CREATE TRIGGER trigger_update_saved_addresses_updated_at
    BEFORE UPDATE ON public.saved_addresses
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();
```

### 5. Create Indexes for Performance
Run these SQL commands in the SQL Editor:

```sql
-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_saved_addresses_user_id ON public.saved_addresses(user_id);
CREATE INDEX IF NOT EXISTS idx_saved_addresses_default ON public.saved_addresses(user_id, is_default) WHERE is_default = true;
CREATE INDEX IF NOT EXISTS idx_saved_addresses_location ON public.saved_addresses(latitude, longitude) WHERE latitude IS NOT NULL AND longitude IS NOT NULL;
```

### 6. Verify Setup
1. Go back to **Table Editor**
2. You should see the `saved_addresses` table with all columns
3. Try inserting a test record to verify everything works

## Alternative: Use the Migration File

If you prefer to use the existing migration file:

1. Go to **SQL Editor**
2. Copy the entire content from `/supabase/migrations/20250101_create_saved_addresses_table.sql`
3. Paste and run it in the SQL Editor

## Troubleshooting CLI Issues

The CLI authentication issues are likely due to:
1. Missing database password
2. Need for service role key instead of anon key
3. Network/firewall restrictions

To fix CLI access:
1. Get your service role key from **Settings** > **API**
2. Add it to your `.env.development` file as `DB_SUPABASE_SERVICE_KEY`
3. Try linking again with proper credentials

## Next Steps

Once the table is set up:
1. Test the Flutter app's saved address functionality
2. Verify that users can create, read, update, and delete addresses
3. Ensure RLS policies are working correctly
4. Test the default address logic

The Flutter app should now be able to interact with the `saved_addresses` table through the existing repository implementation.