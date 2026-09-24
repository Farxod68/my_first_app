-- ============================================
-- TOPBUY DEALS - Order Backend Foundation Migration
-- Orders and Order Items (storage + read-only RLS)
-- ============================================
--
-- This migration creates the server-side storage for customer orders.
--
-- IMPORTANT: Run this migration in your Supabase SQL Editor
-- (Supabase Dashboard -> SQL Editor -> New Query -> Paste & Run)
-- or via `supabase db push`.
--
-- What this creates:
-- 1. orders table (one row per placed order, with a shipping snapshot)
-- 2. order_items table (one row per product in an order, with a
--    name/price snapshot taken at order time)
-- 3. Indexes for per-user order history and order item lookup
-- 4. Row Level Security (RLS): READ-ONLY for the application
-- 5. updated_at trigger on orders, reusing the function created in
--    migration 001 (public.update_updated_at_column()) - that function is
--    NOT redefined here, and migration 001 is not modified in any way.
--
-- SECURITY MODEL - THE APPLICATION MUST NOT WRITE ORDERS DIRECTLY:
-- Cart prices and stock in the Flutter app are client-side snapshots and
-- cannot be trusted. This migration therefore creates ONLY SELECT policies.
-- There is intentionally NO INSERT, UPDATE, DELETE or ALL policy on either
-- table, so with RLS enabled every direct write from anon/authenticated is
-- rejected. Orders will be written exclusively by a future server-side
-- order placement function (not part of this migration) that re-prices
-- items from public.products and validates stock.
--
-- PRODUCT REFERENCES: order_items.product_id references the real UUID
-- primary key public.products(id). order_items.product_slug is only an
-- app-facing snapshot of products.slug (the Flutter Product.id), and
-- product_name / unit_price_usd snapshot the product at order time so an
-- order stays correct after the catalog changes. public.products is NOT
-- modified by this migration.
--
-- CURRENCY: all amounts are stored in USD (the catalog's base currency).
-- currency_code only records the display currency the customer had
-- selected; no conversion is performed or stored server-side.
--
-- Migrations 001-004 are not modified by this migration.
--
-- ============================================

-- ============================================
-- ORDERS TABLE
-- ============================================

-- ACCOUNT DELETION / ORDER RETENTION:
-- user_id uses ON DELETE RESTRICT on purpose. Order retention for the
-- existing account-deletion flow (supabase/functions/delete-account, which
-- deletes the auth.users row) is intentionally UNRESOLVED. Until a retention
-- policy is decided, orders must NOT be silently destroyed by a cascade, so
-- deleting an auth user who has orders is blocked at the database level.
-- The delete-account function is not modified by this migration.
CREATE TABLE IF NOT EXISTS public.orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
    status TEXT NOT NULL DEFAULT 'pending'
        CONSTRAINT orders_status_check
        CHECK (status IN ('pending', 'confirmed', 'cancelled')),
    subtotal_usd NUMERIC(10,2) NOT NULL
        CONSTRAINT orders_subtotal_usd_check
        CHECK (subtotal_usd >= 0),
    currency_code TEXT NOT NULL DEFAULT 'USD'
        CONSTRAINT orders_currency_code_check
        CHECK (currency_code IN ('USD', 'EUR', 'UZS')),
    shipping_full_name TEXT NOT NULL,
    shipping_phone TEXT NOT NULL,
    shipping_address_line TEXT NOT NULL,
    shipping_city TEXT NOT NULL,
    shipping_country TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.orders IS 'Customer orders. Written only by a server-side order placement function; the application has read-only access to its own rows (see RLS policies below).';
COMMENT ON COLUMN public.orders.user_id IS 'Ordering user (auth.users.id). ON DELETE RESTRICT: order retention for account deletion is intentionally unresolved, so orders must not be silently destroyed.';
COMMENT ON COLUMN public.orders.status IS 'Order status: pending, confirmed or cancelled';
COMMENT ON COLUMN public.orders.subtotal_usd IS 'Sum of unit_price_usd x quantity over the order items, in USD (base currency)';
COMMENT ON COLUMN public.orders.currency_code IS 'Display currency selected by the customer at order time (USD, EUR, UZS). Amounts are always stored in USD.';

-- ============================================
-- ORDER ITEMS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS public.order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES public.products(id),
    product_slug TEXT NOT NULL,
    product_name TEXT NOT NULL,
    unit_price_usd NUMERIC(10,2) NOT NULL
        CONSTRAINT order_items_unit_price_usd_check
        CHECK (unit_price_usd >= 0),
    quantity INTEGER NOT NULL
        CONSTRAINT order_items_quantity_check
        CHECK (quantity >= 1),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT order_items_order_id_product_id_key UNIQUE (order_id, product_id)
);

COMMENT ON TABLE public.order_items IS 'Line items of an order, one row per product. Snapshots product name and unit price at order time.';
COMMENT ON COLUMN public.order_items.product_id IS 'Real product UUID (public.products.id)';
COMMENT ON COLUMN public.order_items.product_slug IS 'App-facing snapshot of products.slug (the Flutter Product.id), e.g. "elec-001"';
COMMENT ON COLUMN public.order_items.unit_price_usd IS 'Server-side unit price in USD at order time';

-- ============================================
-- INDEXES
-- ============================================

CREATE INDEX IF NOT EXISTS idx_orders_user_id ON public.orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON public.orders(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON public.order_items(order_id);

-- ============================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================
--
-- READ-ONLY for the application. SELECT policies only.
-- NO INSERT / UPDATE / DELETE / ALL policies are created on purpose:
-- the application must never write orders directly.
--
-- Admin checks use public.is_admin() (migration 003) instead of querying
-- public.profiles inline, avoiding the RLS recursion fixed in 003.

-- Enable RLS
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;

-- ----------------------------
-- orders policies
-- ----------------------------

-- Authenticated users can read only their own orders
DROP POLICY IF EXISTS "Users can view own orders" ON public.orders;
CREATE POLICY "Users can view own orders"
    ON public.orders
    FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

-- Admins can read all orders
DROP POLICY IF EXISTS "Admins can view all orders" ON public.orders;
CREATE POLICY "Admins can view all orders"
    ON public.orders
    FOR SELECT
    TO authenticated
    USING (public.is_admin());

-- ----------------------------
-- order_items policies
-- ----------------------------

-- Authenticated users can read items belonging to their own orders
DROP POLICY IF EXISTS "Users can view own order items" ON public.order_items;
CREATE POLICY "Users can view own order items"
    ON public.order_items
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.orders
            WHERE orders.id = order_items.order_id
              AND orders.user_id = auth.uid()
        )
    );

-- Admins can read all order items
DROP POLICY IF EXISTS "Admins can view all order items" ON public.order_items;
CREATE POLICY "Admins can view all order items"
    ON public.order_items
    FOR SELECT
    TO authenticated
    USING (public.is_admin());

-- ============================================
-- TRIGGERS
-- ============================================

-- Reuses public.update_updated_at_column(), created in migration 001.
-- That function is NOT redefined here and migration 001 is not touched.
DROP TRIGGER IF EXISTS update_orders_updated_at ON public.orders;
CREATE TRIGGER update_orders_updated_at
    BEFORE UPDATE ON public.orders
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================
-- VERIFICATION QUERIES
-- ============================================

-- After running this migration, verify with these queries:

-- 1. Check tables exist
-- SELECT table_name FROM information_schema.tables
-- WHERE table_schema = 'public' AND table_name IN ('orders', 'order_items');

-- 2. Check RLS is enabled on both tables (both rows: relrowsecurity = true)
-- SELECT relname, relrowsecurity FROM pg_class
-- WHERE relnamespace = 'public'::regnamespace
--   AND relname IN ('orders', 'order_items');

-- 3. Check policies - expect exactly 4 rows, all with cmd = 'SELECT'
-- SELECT tablename, policyname, cmd
-- FROM pg_policies
-- WHERE tablename IN ('orders', 'order_items');

-- 4. Confirm there are NO write policies (should return 0)
-- SELECT COUNT(*) FROM pg_policies
-- WHERE tablename IN ('orders', 'order_items') AND cmd <> 'SELECT';

-- 5. Check foreign keys and their delete rules
--    (expect orders.user_id RESTRICT, order_items.order_id CASCADE,
--     order_items.product_id NO ACTION)
-- SELECT tc.table_name, kcu.column_name, rc.delete_rule
-- FROM information_schema.table_constraints tc
-- JOIN information_schema.key_column_usage kcu
--   ON tc.constraint_name = kcu.constraint_name
-- JOIN information_schema.referential_constraints rc
--   ON tc.constraint_name = rc.constraint_name
-- WHERE tc.constraint_type = 'FOREIGN KEY'
--   AND tc.table_name IN ('orders', 'order_items');

-- 6. Check indexes
-- SELECT indexname, tablename FROM pg_indexes
-- WHERE tablename IN ('orders', 'order_items');

-- 7. Check trigger
-- SELECT trigger_name, event_manipulation, event_object_table
-- FROM information_schema.triggers
-- WHERE event_object_table = 'orders';

-- ============================================
-- ROLLBACK (if needed)
-- ============================================

-- To rollback this migration (USE WITH CAUTION - destroys all orders):
-- DROP TRIGGER IF EXISTS update_orders_updated_at ON public.orders;
-- DROP TABLE IF EXISTS public.order_items CASCADE;
-- DROP TABLE IF EXISTS public.orders CASCADE;

-- ============================================
-- END OF MIGRATION
-- ============================================
