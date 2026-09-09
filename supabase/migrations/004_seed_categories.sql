-- ============================================
-- TOPBUY DEALS - Phase 29B Database Migration
-- Product Catalog: Category Seed Data
-- ============================================
--
-- This migration seeds public.categories (created in migration 002, left
-- deliberately unseeded there - see that file's "Categories are NOT seeded
-- in this migration (see Phase 29B)" note).
--
-- IMPORTANT: Run this migration in your Supabase SQL Editor
-- (Supabase Dashboard -> SQL Editor -> New Query -> Paste & Run)
-- or via `supabase db push`. Requires migration 002 to have already run
-- (public.categories must exist).
--
-- SOURCE OF TRUTH FOR THESE SIX ROWS:
-- migration 002's own table comment on public.categories: "key matches the
-- Flutter app's CategoryKeys constants (electronics, clothing, accessories,
-- homeGoods, sports, cosmetics)". That exact set, spelling, and casing is
-- also what CategoriesTab hard-codes as its six category cards
-- (lib/presentation/screens/home/tabs/categories_tab.dart) and what
-- ProductRemoteDataSource.fetchProductsByCategory() filters
-- `categories.key` against (lib/data/data_sources/remote/product_remote_data_source.dart)
-- via the `categories!inner(key)` embed. No category beyond these six is
-- referenced anywhere in the app, and none of the six is optional.
--
-- sort_order mirrors the display order already used by CategoriesTab's own
-- hard-coded category list, purely for admin/database readability - no
-- current query reads categories.sort_order.
--
-- id is intentionally left to its DEFAULT gen_random_uuid(): nothing in the
-- app depends on a specific category UUID. Only the `key` value is a
-- stable, client-referenced identifier, and it is set explicitly for
-- exactly that reason.
--
-- IDEMPOTENCY: categories.key is UNIQUE (migration 002), so ON CONFLICT
-- (key) DO NOTHING makes this migration safe to run multiple times and
-- safe on a freshly-initialized database - re-running it never creates
-- duplicate rows and never errors.
--
-- ============================================

INSERT INTO public.categories (key, sort_order) VALUES
    ('electronics',  0),
    ('clothing',     1),
    ('accessories',  2),
    ('homeGoods',    3),
    ('sports',       4),
    ('cosmetics',    5)
ON CONFLICT (key) DO NOTHING;

-- ============================================
-- VERIFICATION QUERIES
-- ============================================

-- After running this migration, verify with these queries:

-- 1. Confirm all six categories exist, in order
-- SELECT key, sort_order FROM public.categories ORDER BY sort_order;

-- 2. Confirm no duplicates were created (should return 6)
-- SELECT COUNT(*) FROM public.categories;

-- ============================================
-- ROLLBACK (if needed)
-- ============================================

-- To roll back this migration (removes only the six seeded rows):
-- DELETE FROM public.categories
-- WHERE key IN ('electronics', 'clothing', 'accessories', 'homeGoods', 'sports', 'cosmetics');

-- ============================================
-- END OF MIGRATION
-- ============================================
