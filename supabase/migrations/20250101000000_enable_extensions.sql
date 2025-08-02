-- Enable required PostgreSQL extensions
-- This should be one of the first migrations to run

-- Enable UUID generation functions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enable cryptographic functions (used by Supabase Auth)
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Enable HTTP functions (if needed for webhooks)
CREATE EXTENSION IF NOT EXISTS "http";

-- Enable PostGIS for location-based features (if needed)
-- CREATE EXTENSION IF NOT EXISTS "postgis";

-- Enable pg_net for network operations (this might be the missing extension)
CREATE EXTENSION IF NOT EXISTS "pg_net";

COMMENT ON EXTENSION "uuid-ossp" IS 'UUID generation functions';
COMMENT ON EXTENSION "pgcrypto" IS 'Cryptographic functions';
COMMENT ON EXTENSION "http" IS 'HTTP client functions';
COMMENT ON EXTENSION "pg_net" IS 'Network functions for async HTTP requests';