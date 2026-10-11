-- ============================================================================
-- SAFE NON-DESTRUCTIVE SUPABASE SCHEMA & PERMISSIONS MIGRATION
-- Preserves all existing tables and data. Zero TRUNCATE or DROP TABLE commands.
-- ============================================================================

-- 1. ENSURE TABLE STRUCTURE (NON-DESTRUCTIVE)
CREATE TABLE IF NOT EXISTS public.companies (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  headquarters TEXT,
  website TEXT,
  logo TEXT,
  market_share NUMERIC DEFAULT 0,
  is_reference BOOLEAN DEFAULT false,
  status TEXT DEFAULT 'active',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.products (
  id TEXT PRIMARY KEY,
  company_id TEXT REFERENCES public.companies(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  segment TEXT NOT NULL,
  current_price NUMERIC NOT NULL,
  msrp NUMERIC NOT NULL,
  currency TEXT DEFAULT '₹',
  soc TEXT,
  ram_storage TEXT,
  camera TEXT,
  battery TEXT,
  source_url TEXT,
  last_updated TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.price_observations (
  id TEXT PRIMARY KEY,
  product_id TEXT REFERENCES public.products(id) ON DELETE CASCADE,
  product_name TEXT NOT NULL,
  company_name TEXT NOT NULL,
  price NUMERIC NOT NULL,
  previous_price NUMERIC,
  currency TEXT DEFAULT '₹',
  source_name TEXT,
  source_url TEXT NOT NULL,
  evidence_snippet TEXT,
  observed_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.offers (
  id TEXT PRIMARY KEY,
  company_id TEXT REFERENCES public.companies(id) ON DELETE CASCADE,
  company_name TEXT NOT NULL,
  product_name TEXT,
  title TEXT NOT NULL,
  type TEXT NOT NULL,
  discount_value TEXT NOT NULL,
  valid_until TEXT,
  description TEXT,
  source_url TEXT NOT NULL,
  status TEXT DEFAULT 'active',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.campaigns (
  id TEXT PRIMARY KEY,
  company_id TEXT REFERENCES public.companies(id) ON DELETE CASCADE,
  company_name TEXT NOT NULL,
  headline TEXT NOT NULL,
  platform TEXT NOT NULL,
  audience_target TEXT,
  key_hook TEXT,
  landing_page_url TEXT NOT NULL,
  ad_media_url TEXT,
  estimated_spend_tier TEXT,
  detected_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.change_events (
  id TEXT PRIMARY KEY,
  type TEXT NOT NULL,
  competitor_name TEXT NOT NULL,
  competitor_id TEXT NOT NULL,
  product_name TEXT,
  field_changed TEXT NOT NULL,
  previous_value TEXT,
  new_value TEXT NOT NULL,
  source_url TEXT NOT NULL,
  source_name TEXT,
  verification_status TEXT DEFAULT 'verified',
  detected_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.ai_insights (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  urgency TEXT DEFAULT 'medium',
  category TEXT NOT NULL,
  competitor_affected TEXT NOT NULL,
  summary TEXT NOT NULL,
  strategic_impact TEXT,
  suggested_action TEXT NOT NULL,
  source_name TEXT,
  source_url TEXT NOT NULL,
  observed_value TEXT,
  generated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.collection_jobs (
  id TEXT PRIMARY KEY,
  source_id TEXT NOT NULL,
  source_name TEXT NOT NULL,
  target_url TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('success', 'rate_limited', 'error', 'cors_restricted', 'synthetic')),
  http_status_code INTEGER,
  error_message TEXT,
  timestamp TIMESTAMPTZ DEFAULT NOW()
);

-- SAFE: Add unique index on (product_id, hour-bucket) to prevent duplicate observations
-- within the same hour. Uses IF NOT EXISTS equivalent via DO block.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes
    WHERE tablename = 'price_observations'
    AND indexname = 'uix_obs_product_hour'
  ) THEN
    CREATE UNIQUE INDEX uix_obs_product_hour
      ON public.price_observations (product_id, date_trunc('hour', observed_at::timestamp));
  END IF;
END
$$;

-- 2. GRANT TABLE ACCESS PRIVILEGES TO AUTHENTICATED ROLES ONLY
GRANT SELECT, INSERT, UPDATE, DELETE ON public.companies TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.products TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.price_observations TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.offers TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.campaigns TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.change_events TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.ai_insights TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.collection_jobs TO authenticated;

-- 3. REMOVE SPECIFIC CONFLICTING POLICY NAMES SAFELY
DROP POLICY IF EXISTS "Public All Companies" ON public.companies;
DROP POLICY IF EXISTS "Public Read Companies" ON public.companies;
DROP POLICY IF EXISTS "Public All Products" ON public.products;
DROP POLICY IF EXISTS "Public Read Products" ON public.products;
DROP POLICY IF EXISTS "Public All Observations" ON public.price_observations;
DROP POLICY IF EXISTS "Public Read Observations" ON public.price_observations;
DROP POLICY IF EXISTS "Public All Offers" ON public.offers;
DROP POLICY IF EXISTS "Public Read Offers" ON public.offers;
DROP POLICY IF EXISTS "Public All Campaigns" ON public.campaigns;
DROP POLICY IF EXISTS "Public Read Campaigns" ON public.campaigns;
DROP POLICY IF EXISTS "Public All Changes" ON public.change_events;
DROP POLICY IF EXISTS "Public Read Changes" ON public.change_events;
DROP POLICY IF EXISTS "Public All Insights" ON public.ai_insights;
DROP POLICY IF EXISTS "Public Read Insights" ON public.ai_insights;
DROP POLICY IF EXISTS "Public All Jobs" ON public.collection_jobs;
DROP POLICY IF EXISTS "Public Read Jobs" ON public.collection_jobs;

-- 4. ENABLE ROW LEVEL SECURITY (RLS)
ALTER TABLE public.companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.price_observations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.offers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.change_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_insights ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.collection_jobs ENABLE ROW LEVEL SECURITY;

-- 5. CREATE CLEAN NON-CONFLICTING PERMISSIVE RLS POLICIES FOR AUTHENTICATED USERS
CREATE POLICY "RivalTrack_Companies_Access" ON public.companies FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "RivalTrack_Products_Access" ON public.products FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "RivalTrack_Observations_Access" ON public.price_observations FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "RivalTrack_Offers_Access" ON public.offers FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "RivalTrack_Campaigns_Access" ON public.campaigns FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "RivalTrack_Changes_Access" ON public.change_events FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "RivalTrack_Insights_Access" ON public.ai_insights FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "RivalTrack_Jobs_Access" ON public.collection_jobs FOR ALL TO authenticated USING (true) WITH CHECK (true);
