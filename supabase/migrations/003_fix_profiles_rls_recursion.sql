-- ============================================
-- TOPBUY DEALS - RLS Recursion Fix
-- Fixes: 42P17 infinite recursion detected in policy for relation "profiles"
-- ============================================
--
-- ROOT CAUSE (see migration 001):
--   "Admins can view all profiles" ON public.profiles FOR SELECT
--   USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'))
--
--   This policy is defined ON public.profiles, and its own condition runs a
--   SELECT against public.profiles. Because RLS is enabled on profiles, that
--   inner SELECT must itself be filtered by profiles' SELECT policies -
--   including this same policy - so Postgres re-enters it indefinitely,
--   raising 42P17.
--
--   The same unsafe "EXISTS (SELECT 1 FROM public.profiles WHERE id =
--   auth.uid() AND role = 'admin')" pattern is repeated in every "Admins
--   can ..." policy on categories, products, and product_images (migration
--   002). Those don't live on profiles, so they aren't themselves
--   self-recursive, but they still trigger evaluation of profiles' SELECT
--   policies (including the broken one) every time they run.
--
-- FIX:
--   Introduce a SECURITY DEFINER helper, public.is_admin(), that performs
--   the role lookup as the function owner (bypassing the caller's RLS on
--   profiles) instead of as an in-policy subquery subject to RLS. Every
--   "Admins can ..." policy is redefined to call public.is_admin() instead
--   of repeating the raw EXISTS subquery.
--
-- SCOPE:
--   - Does not touch "Users can view own profile", "Users can insert own
--     profile", "Anyone can view categories", "Anyone can view active
--     products", or "Anyone can view images of active products" - these are
--     already correct and are left exactly as migration 001/002 defined
--     them.
--   - Does not touch "Users can update own profile" - its inline
--     self-lookup subqueries are on the *same row* being updated, and once
--     profiles' SELECT policy set no longer contains a self-recursive
--     policy, those subqueries resolve normally (they hit "Users can view
--     own profile" and/or the fixed is_admin()-based policy, neither of
--     which recurses).
--   - Safe to run against the already-deployed database: uses
--     CREATE OR REPLACE FUNCTION and DROP POLICY IF EXISTS / CREATE POLICY,
--     and does not assume migrations 001/002 are rerun.
--   - Does NOT modify migrations 001 or 002.
--
-- ============================================

-- ============================================
-- HELPER FUNCTION: public.is_admin()
-- ============================================
--
-- SECURITY NOTES:
--   - SECURITY DEFINER: the function body runs with the privileges of the
--     function owner (the migration-running role, expected to be a
--     superuser/BYPASSRLS role in Supabase, e.g. `postgres`), NOT the
--     calling anon/authenticated role. Its internal SELECT on
--     public.profiles is therefore not subject to the caller's RLS
--     policies on profiles, which is what breaks the recursion.
--   - SET search_path = public, pg_temp: pins the search path explicitly so
--     the function cannot be tricked into resolving `profiles` (or any
--     other unqualified identifier) against an attacker-controlled schema
--     earlier in a caller's search_path. This is required practice for any
--     SECURITY DEFINER function.
--   - Plain SQL, no dynamic SQL (no EXECUTE/format()): the function cannot
--     be used to run arbitrary SQL. It only ever executes this one fixed
--     query.
--   - Returns boolean only: callers learn "is the current user an admin?"
--     and nothing else. No profile columns (email, role value, etc.) are
--     ever returned to the caller.
--   - STABLE: the result is a function of auth.uid() and current table
--     state only (no side effects), consistent within a single statement.
--
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public, pg_temp
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM public.profiles
        WHERE id = auth.uid()
          AND role = 'admin'
    );
$$;

COMMENT ON FUNCTION public.is_admin() IS
    'Returns true if the currently authenticated user (auth.uid()) has role = ''admin'' in public.profiles. SECURITY DEFINER so the internal lookup bypasses the caller''s RLS on profiles, avoiding self-referential policy recursion (42P17). Exposes only a boolean - no profile data.';

-- Explicit least-privilege grants: do not rely on default PUBLIC EXECUTE.
-- anon/authenticated need EXECUTE because their queries (via RLS policies
-- that call this function) invoke it; this only ever tells them true/false
-- about their own admin status, never returns row data.
REVOKE ALL ON FUNCTION public.is_admin() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_admin() TO anon, authenticated;

-- ============================================
-- POLICY UPDATES
-- ============================================

-- ----------------------------
-- public.profiles
-- ----------------------------

DROP POLICY IF EXISTS "Admins can view all profiles" ON public.profiles;
CREATE POLICY "Admins can view all profiles"
    ON public.profiles
    FOR SELECT
    USING (public.is_admin());

-- ----------------------------
-- public.categories
-- ----------------------------

DROP POLICY IF EXISTS "Admins can insert categories" ON public.categories;
CREATE POLICY "Admins can insert categories"
    ON public.categories
    FOR INSERT
    WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "Admins can update categories" ON public.categories;
CREATE POLICY "Admins can update categories"
    ON public.categories
    FOR UPDATE
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "Admins can delete categories" ON public.categories;
CREATE POLICY "Admins can delete categories"
    ON public.categories
    FOR DELETE
    USING (public.is_admin());

-- ----------------------------
-- public.products
-- ----------------------------

DROP POLICY IF EXISTS "Admins can view all products" ON public.products;
CREATE POLICY "Admins can view all products"
    ON public.products
    FOR SELECT
    USING (public.is_admin());

DROP POLICY IF EXISTS "Admins can insert products" ON public.products;
CREATE POLICY "Admins can insert products"
    ON public.products
    FOR INSERT
    WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "Admins can update products" ON public.products;
CREATE POLICY "Admins can update products"
    ON public.products
    FOR UPDATE
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "Admins can delete products" ON public.products;
CREATE POLICY "Admins can delete products"
    ON public.products
    FOR DELETE
    USING (public.is_admin());

-- ----------------------------
-- public.product_images
-- ----------------------------

DROP POLICY IF EXISTS "Admins can view all product images" ON public.product_images;
CREATE POLICY "Admins can view all product images"
    ON public.product_images
    FOR SELECT
    USING (public.is_admin());

DROP POLICY IF EXISTS "Admins can insert product images" ON public.product_images;
CREATE POLICY "Admins can insert product images"
    ON public.product_images
    FOR INSERT
    WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "Admins can update product images" ON public.product_images;
CREATE POLICY "Admins can update product images"
    ON public.product_images
    FOR UPDATE
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "Admins can delete product images" ON public.product_images;
CREATE POLICY "Admins can delete product images"
    ON public.product_images
    FOR DELETE
    USING (public.is_admin());

-- ============================================
-- VERIFICATION QUERIES
-- ============================================

-- After applying this migration, verify with these queries:

-- 1. Confirm the function exists and its security settings
-- SELECT proname, prosecdef, proconfig
-- FROM pg_proc
-- WHERE proname = 'is_admin' AND pronamespace = 'public'::regnamespace;

-- 2. Confirm no policy still contains the raw self-referential subquery
-- SELECT tablename, policyname, qual, with_check
-- FROM pg_policies
-- WHERE schemaname = 'public'
--   AND (qual ILIKE '%FROM public.profiles%' OR with_check ILIKE '%FROM public.profiles%')
--   AND tablename = 'profiles';
-- (Expect zero rows for the "Admins can view all profiles" policy - it
-- should now show `is_admin()` instead.)

-- 3. Sanity check as an authenticated non-admin user (should not error):
-- SELECT * FROM public.profiles WHERE id = auth.uid();

-- 4. Sanity check as an authenticated admin user (should not error and
--    should return all rows):
-- SELECT * FROM public.profiles;

-- ============================================
-- ROLLBACK (if needed)
-- ============================================

-- To roll back this migration (restores the pre-fix, recursive policies -
-- NOT recommended, only for reverting a bad deploy):
--
-- DROP POLICY IF EXISTS "Admins can view all profiles" ON public.profiles;
-- CREATE POLICY "Admins can view all profiles"
--     ON public.profiles FOR SELECT
--     USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));
--
-- DROP POLICY IF EXISTS "Admins can insert categories" ON public.categories;
-- CREATE POLICY "Admins can insert categories"
--     ON public.categories FOR INSERT
--     WITH CHECK (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));
--
-- DROP POLICY IF EXISTS "Admins can update categories" ON public.categories;
-- CREATE POLICY "Admins can update categories"
--     ON public.categories FOR UPDATE
--     USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'))
--     WITH CHECK (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));
--
-- DROP POLICY IF EXISTS "Admins can delete categories" ON public.categories;
-- CREATE POLICY "Admins can delete categories"
--     ON public.categories FOR DELETE
--     USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));
--
-- DROP POLICY IF EXISTS "Admins can view all products" ON public.products;
-- CREATE POLICY "Admins can view all products"
--     ON public.products FOR SELECT
--     USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));
--
-- DROP POLICY IF EXISTS "Admins can insert products" ON public.products;
-- CREATE POLICY "Admins can insert products"
--     ON public.products FOR INSERT
--     WITH CHECK (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));
--
-- DROP POLICY IF EXISTS "Admins can update products" ON public.products;
-- CREATE POLICY "Admins can update products"
--     ON public.products FOR UPDATE
--     USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'))
--     WITH CHECK (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));
--
-- DROP POLICY IF EXISTS "Admins can delete products" ON public.products;
-- CREATE POLICY "Admins can delete products"
--     ON public.products FOR DELETE
--     USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));
--
-- DROP POLICY IF EXISTS "Admins can view all product images" ON public.product_images;
-- CREATE POLICY "Admins can view all product images"
--     ON public.product_images FOR SELECT
--     USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));
--
-- DROP POLICY IF EXISTS "Admins can insert product images" ON public.product_images;
-- CREATE POLICY "Admins can insert product images"
--     ON public.product_images FOR INSERT
--     WITH CHECK (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));
--
-- DROP POLICY IF EXISTS "Admins can update product images" ON public.product_images;
-- CREATE POLICY "Admins can update product images"
--     ON public.product_images FOR UPDATE
--     USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'))
--     WITH CHECK (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));
--
-- DROP POLICY IF EXISTS "Admins can delete product images" ON public.product_images;
-- CREATE POLICY "Admins can delete product images"
--     ON public.product_images FOR DELETE
--     USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));
--
-- DROP FUNCTION IF EXISTS public.is_admin();

-- ============================================
-- END OF MIGRATION
-- ============================================
