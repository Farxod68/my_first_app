-- ============================================
-- TOPBUY DEALS - Phase 29A Database Migration
-- Product Catalog: Categories, Products, Product Images
-- ============================================
--
-- This migration creates the product catalog schema for TOPBUY DEALS,
-- replacing the local mock catalog (lib/data/data_sources/local/mock_products.dart)
-- with a real Supabase-backed source.
--
-- IMPORTANT: Run this migration in your Supabase SQL Editor
-- (Supabase Dashboard -> SQL Editor -> New Query -> Paste & Run)
-- or via `supabase db push`.
--
-- What this creates:
-- 1. categories table (flat category list, matches existing CategoryKeys)
-- 2. products table (matches the existing Flutter Product model, minus
--    IconData - see note below)
-- 3. product_images table (backs Product.images: List<String>)
-- 4. Row Level Security (RLS) policies for all three tables
-- 5. updated_at trigger on products, reusing the function created in
--    migration 001 (public.update_updated_at_column()) - that function is
--    NOT redefined here, and migration 001 is not modified in any way.
--
-- NOTE ON IconData: the Flutter Product model currently carries a Material
-- `icon` field. IconData is a Flutter-only type with no meaningful server
-- representation, so it is intentionally NOT stored here. Category/product
-- icon selection remains a client-side concern (e.g. a category -> icon
-- lookup) until real product images replace icon rendering.
--
-- Categories are NOT seeded in this migration (see Phase 29B).
--
-- ============================================

-- ============================================
-- CATEGORIES TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS public.categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    key TEXT UNIQUE NOT NULL,
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.categories IS 'Flat product category list. key matches the Flutter app''s CategoryKeys constants (electronics, clothing, accessories, homeGoods, sports, cosmetics).';
COMMENT ON COLUMN public.categories.key IS 'Stable programmatic category key used by the client (e.g. "electronics")';

-- ============================================
-- PRODUCTS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS public.products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    slug TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    subtitle TEXT,
    description TEXT,
    price NUMERIC(10,2) NOT NULL CHECK (price >= 0),
    old_price NUMERIC(10,2) NOT NULL CHECK (old_price >= 0),
    category_id UUID NOT NULL REFERENCES public.categories(id),
    rating NUMERIC(2,1) NOT NULL DEFAULT 0 CHECK (rating BETWEEN 0 AND 5),
    review_count INT NOT NULL DEFAULT 0 CHECK (review_count >= 0),
    stock INT NOT NULL DEFAULT 0 CHECK (stock >= 0),
    brand TEXT,
    seller TEXT,
    specifications JSONB,
    features TEXT[],
    badges TEXT[] NOT NULL DEFAULT '{}',
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.products IS 'Product catalog. Mirrors the Flutter Product model (lib/data/models/product.dart) except IconData, which has no server-side representation.';
COMMENT ON COLUMN public.products.slug IS 'Stable human-readable identifier preserved from the mock catalog (e.g. "elec-001"). Distinct from the UUID primary key.';
COMMENT ON COLUMN public.products.is_active IS 'Soft visibility flag. Inactive products are hidden from anonymous/authenticated reads (see RLS policies below).';

-- ============================================
-- PRODUCT IMAGES TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS public.product_images (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    url TEXT NOT NULL,
    sort_order INT NOT NULL DEFAULT 0
);

COMMENT ON TABLE public.product_images IS 'Backs Product.images: List<String> in the Flutter model. One row per image; ordered by sort_order.';

-- ============================================
-- INDEXES
-- ============================================

-- categories.key already has a UNIQUE constraint (creates a unique index)
CREATE INDEX IF NOT EXISTS idx_products_category_id ON public.products(category_id);
CREATE INDEX IF NOT EXISTS idx_products_is_active ON public.products(is_active);
CREATE INDEX IF NOT EXISTS idx_products_created_at ON public.products(created_at DESC);
-- products.slug already has a UNIQUE constraint (creates a unique index)
CREATE INDEX IF NOT EXISTS idx_product_images_product_id ON public.product_images(product_id);

-- ============================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================
--
-- SECURITY ARCHITECTURE:
--
-- 1. PUBLIC READ, ACTIVE ONLY: Anonymous and authenticated users can read
--    categories freely, and can read products/product_images only where
--    the product is_active = true. Inactive products and their images are
--    invisible to non-admin clients.
--
-- 2. NO CLIENT WRITE ACCESS: Anonymous and authenticated (non-admin) users
--    have no INSERT/UPDATE/DELETE policies on any of these three tables.
--    With RLS enabled and no matching policy for an operation, PostgREST
--    denies it by default - there is nothing else to configure to block
--    writes for those roles.
--
-- 3. ADMIN ACCESS: Mirrors the existing "Admins can view all profiles"
--    pattern from migration 001 exactly - profiles.role = 'admin' via an
--    EXISTS subquery keyed off auth.uid(). Admins get full read (including
--    inactive products/images) and full write (INSERT/UPDATE/DELETE) on
--    categories, products, and product_images. Seller self-service product
--    management is explicitly out of scope for this migration.
--
-- Enable RLS
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_images ENABLE ROW LEVEL SECURITY;

-- ----------------------------
-- categories policies
-- ----------------------------

-- Anyone (anonymous or authenticated) can read all categories
CREATE POLICY "Anyone can view categories"
    ON public.categories
    FOR SELECT
    USING (true);

-- Admins can create categories
CREATE POLICY "Admins can insert categories"
    ON public.categories
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Admins can update categories
CREATE POLICY "Admins can update categories"
    ON public.categories
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Admins can delete categories
CREATE POLICY "Admins can delete categories"
    ON public.categories
    FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- ----------------------------
-- products policies
-- ----------------------------

-- Anonymous and authenticated users can view only active products
CREATE POLICY "Anyone can view active products"
    ON public.products
    FOR SELECT
    USING (is_active = true);

-- Admins can view all products, including inactive ones
CREATE POLICY "Admins can view all products"
    ON public.products
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Admins can create products
CREATE POLICY "Admins can insert products"
    ON public.products
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Admins can update products
CREATE POLICY "Admins can update products"
    ON public.products
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Admins can delete products
CREATE POLICY "Admins can delete products"
    ON public.products
    FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- ----------------------------
-- product_images policies
-- ----------------------------

-- Anonymous and authenticated users can view images only for active products
CREATE POLICY "Anyone can view images of active products"
    ON public.product_images
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.products
            WHERE products.id = product_images.product_id
              AND products.is_active = true
        )
    );

-- Admins can view all product images, including those of inactive products
CREATE POLICY "Admins can view all product images"
    ON public.product_images
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Admins can create product images
CREATE POLICY "Admins can insert product images"
    ON public.product_images
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Admins can update product images
CREATE POLICY "Admins can update product images"
    ON public.product_images
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Admins can delete product images
CREATE POLICY "Admins can delete product images"
    ON public.product_images
    FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- ============================================
-- TRIGGERS
-- ============================================

-- Reuses public.update_updated_at_column(), created in migration 001.
-- That function is NOT redefined here and migration 001 is not touched.
DROP TRIGGER IF EXISTS update_products_updated_at ON public.products;
CREATE TRIGGER update_products_updated_at
    BEFORE UPDATE ON public.products
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================
-- VERIFICATION QUERIES
-- ============================================

-- After running this migration, verify with these queries:

-- 1. Check tables exist
-- SELECT table_name FROM information_schema.tables
-- WHERE table_schema = 'public' AND table_name IN ('categories', 'products', 'product_images');

-- 2. Check RLS policies
-- SELECT tablename, policyname, cmd
-- FROM pg_policies
-- WHERE tablename IN ('categories', 'products', 'product_images');

-- 3. Check indexes
-- SELECT indexname, tablename FROM pg_indexes
-- WHERE tablename IN ('categories', 'products', 'product_images');

-- 4. Check trigger
-- SELECT trigger_name, event_manipulation, event_object_table
-- FROM information_schema.triggers
-- WHERE event_object_table = 'products';

-- ============================================
-- ROLLBACK (if needed)
-- ============================================

-- To rollback this migration (USE WITH CAUTION):
-- DROP TRIGGER IF EXISTS update_products_updated_at ON public.products;
-- DROP TABLE IF EXISTS public.product_images CASCADE;
-- DROP TABLE IF EXISTS public.products CASCADE;
-- DROP TABLE IF EXISTS public.categories CASCADE;

-- ============================================
-- END OF MIGRATION
-- ============================================
