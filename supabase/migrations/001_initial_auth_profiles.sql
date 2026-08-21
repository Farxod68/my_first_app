-- ============================================
-- TOPBUY DEALS - Phase 5A.1 Database Migration
-- Initial Authentication & Profiles Setup
-- ============================================
--
-- This migration creates the foundation for user authentication
-- and profile management in the TOPBUY DEALS marketplace.
--
-- IMPORTANT: Run this migration in your Supabase SQL Editor
-- (Supabase Dashboard → SQL Editor → New Query → Paste & Run)
--
-- What this creates:
-- 1. profiles table (extends auth.users)
-- 2. Row Level Security (RLS) policies
-- 3. Trigger to auto-create profile on signup
-- 4. Helper functions
--
-- ============================================

-- Enable UUID extension (if not already enabled)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- PROFILES TABLE
-- ============================================

-- Profiles table extends Supabase Auth users
-- Each auth.users row gets a corresponding profiles row
CREATE TABLE IF NOT EXISTS public.profiles (
    -- Primary key references auth.users
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,

    -- Basic profile info
    email TEXT NOT NULL,
    full_name TEXT,
    avatar_url TEXT,
    phone TEXT,

    -- Preferences (migrated from local persistence)
    language_code TEXT DEFAULT 'en' CHECK (language_code IN ('en', 'es', 'fr', 'uz')),
    currency_code TEXT DEFAULT 'USD' CHECK (currency_code IN ('USD', 'EUR', 'UZS')),

    -- Role (for future seller/admin functionality)
    role TEXT DEFAULT 'customer' CHECK (role IN ('customer', 'seller', 'admin')),

    -- Status
    is_active BOOLEAN DEFAULT true,
    email_verified BOOLEAN DEFAULT false,

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),

    -- Constraints
    CONSTRAINT valid_email CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$')
);

-- Indexes for common queries
CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_created_at ON public.profiles(created_at DESC);

-- Comments for documentation
COMMENT ON TABLE public.profiles IS 'User profiles extending auth.users with app-specific data';
COMMENT ON COLUMN public.profiles.id IS 'User ID from auth.users';
COMMENT ON COLUMN public.profiles.email IS 'User email (denormalized from auth.users for convenience)';
COMMENT ON COLUMN public.profiles.language_code IS 'Preferred UI language (en, es, fr, uz)';
COMMENT ON COLUMN public.profiles.currency_code IS 'Preferred currency display (USD, EUR, UZS)';
COMMENT ON COLUMN public.profiles.role IS 'User role (customer, seller, admin)';

-- ============================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================
--
-- SECURITY ARCHITECTURE:
--
-- 1. AUTHENTICATION SOURCE OF TRUTH: Supabase Auth (auth.users)
--    - Email verification status lives in auth.users.email_confirmed_at
--    - profiles.email_verified is synced via trigger (read-only for users)
--
-- 2. ROLE MANAGEMENT:
--    - profiles.role is NOT user-editable
--    - Only admins can change roles (via admin dashboard, future phase)
--    - Default role is 'customer'
--
-- 3. PRIVILEGE ESCALATION PREVENTION:
--    - UPDATE policy checks that role/email/email_verified haven't changed
--    - Users can only modify: full_name, avatar_url, phone, language_code, currency_code
--
-- 4. ADMIN ACCESS:
--    - Admins identified by profiles.role = 'admin'
--    - Admin role can only be set via direct SQL (not through app)
--    - Future: Admin dashboard with proper authorization
--
-- Enable RLS on profiles table
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own profile
CREATE POLICY "Users can view own profile"
    ON public.profiles
    FOR SELECT
    USING (auth.uid() = id);

-- Policy: Users can update their own profile (non-privileged fields only)
-- SECURITY: Users CANNOT modify id, role, email_verified, or other privileged fields
-- Only allows updates to: full_name, avatar_url, phone, language_code, currency_code
CREATE POLICY "Users can update own profile"
    ON public.profiles
    FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (
        auth.uid() = id
        -- Ensure privileged fields haven't changed (prevent privilege escalation)
        AND (SELECT role FROM public.profiles WHERE id = auth.uid()) = role
        AND (SELECT email FROM public.profiles WHERE id = auth.uid()) = email
        AND (SELECT email_verified FROM public.profiles WHERE id = auth.uid()) = email_verified
    );

-- Policy: Users can insert their own profile (used by trigger)
CREATE POLICY "Users can insert own profile"
    ON public.profiles
    FOR INSERT
    WITH CHECK (auth.uid() = id);

-- Policy: Admins can view all profiles (for future admin dashboard)
CREATE POLICY "Admins can view all profiles"
    ON public.profiles
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- ============================================
-- FUNCTIONS & TRIGGERS
-- ============================================

-- Function to automatically create profile on user signup
-- SECURITY: Syncs email_verified from auth.users to maintain single source of truth
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO public.profiles (id, email, email_verified)
    VALUES (
        NEW.id,
        NEW.email,
        NEW.email_confirmed_at IS NOT NULL
    );
    RETURN NEW;
END;
$$;

-- Function to sync email_verified when auth.users.email_confirmed_at changes
-- SECURITY: Keeps profiles.email_verified in sync with Supabase Auth
CREATE OR REPLACE FUNCTION public.sync_email_verified()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    UPDATE public.profiles
    SET email_verified = (NEW.email_confirmed_at IS NOT NULL)
    WHERE id = NEW.id;
    RETURN NEW;
END;
$$;

-- Trigger: Create profile when user signs up
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- Trigger: Sync email_verified when auth.users.email_confirmed_at changes
-- SECURITY: Maintains Supabase Auth as single source of truth
DROP TRIGGER IF EXISTS on_auth_user_email_verified ON auth.users;
CREATE TRIGGER on_auth_user_email_verified
    AFTER UPDATE OF email_confirmed_at ON auth.users
    FOR EACH ROW
    WHEN (OLD.email_confirmed_at IS DISTINCT FROM NEW.email_confirmed_at)
    EXECUTE FUNCTION public.sync_email_verified();

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

-- Trigger: Update updated_at on profile changes
DROP TRIGGER IF EXISTS update_profiles_updated_at ON public.profiles;
CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================
-- INITIAL DATA (Optional)
-- ============================================

-- Create a test admin user profile (if you have a test user)
-- IMPORTANT: Replace this UUID with your test user's UUID from auth.users
-- You can get it from: Supabase Dashboard → Authentication → Users → Copy UUID
--
-- INSERT INTO public.profiles (id, email, full_name, role, language_code, currency_code)
-- VALUES (
--     'YOUR_TEST_USER_UUID_HERE',
--     'test@example.com',
--     'Test User',
--     'customer',
--     'en',
--     'USD'
-- )
-- ON CONFLICT (id) DO NOTHING;

-- ============================================
-- VERIFICATION QUERIES
-- ============================================

-- After running this migration, verify with these queries:

-- 1. Check if profiles table exists
-- SELECT table_name FROM information_schema.tables
-- WHERE table_schema = 'public' AND table_name = 'profiles';

-- 2. Check RLS policies
-- SELECT policyname, permissive, roles, cmd, qual
-- FROM pg_policies
-- WHERE tablename = 'profiles';

-- 3. Check triggers
-- SELECT trigger_name, event_manipulation, event_object_table
-- FROM information_schema.triggers
-- WHERE event_object_table = 'users' OR event_object_table = 'profiles';

-- ============================================
-- ROLLBACK (if needed)
-- ============================================

-- To rollback this migration (USE WITH CAUTION):
-- DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
-- DROP TRIGGER IF EXISTS update_profiles_updated_at ON public.profiles;
-- DROP FUNCTION IF EXISTS public.handle_new_user();
-- DROP FUNCTION IF EXISTS public.update_updated_at_column();
-- DROP TABLE IF EXISTS public.profiles CASCADE;

-- ============================================
-- END OF MIGRATION
-- ============================================
