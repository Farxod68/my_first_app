-- ============================================
-- TOPBUY DEALS - Product translations
-- Adds public.product_translations (per-locale product text)
-- ============================================
--
-- STATUS: LOCAL DRAFT. Not applied to any Supabase project. Review, test on
-- a non-production database first, then apply deliberately.
--
-- Purpose: product name/subtitle/description/features/specifications are
-- single-language (English) columns on public.products. This migration adds
-- a separate translation table so the app can show ru / uz (Latin script) /
-- es / fr text without touching the existing columns.
--
-- Design:
-- - ADDITIVE ONLY. public.products and every existing column, policy,
--   function and migration (001-007) are left untouched. No data is moved.
-- - products.name / subtitle / description / features / specifications
--   remain the English FALLBACK. A product with no row for the requested
--   locale simply shows those values. place_order (006) keeps snapshotting
--   products.name, so orders are unaffected.
-- - One row per (product, locale). Composite PK (product_id, locale) doubles
--   as the lookup index for "all translations of a product" and for
--   PostgREST embeds, so it scales to thousands of products x 5 locales.
-- - locale is restricted to the app's supported language codes
--   (en, ru, uz, es, fr), the same set as profiles.language_code (007).
--   Uzbek (uz) text is expected in Latin script.
-- - NOT included on purpose: brand / seller (proper nouns), badges (they are
--   matched against DealBadges constants in app code; localize separately
--   by key), and any data backfill. Translations are inserted in a separate,
--   reviewed step.
--
-- RLS (mirrors products from 002/003):
-- - SELECT: anyone (anon + authenticated) for translations of ACTIVE
--   products; admins can read all.
-- - INSERT / UPDATE / DELETE: admins only, via public.is_admin() (003).
--   No client write policies for anyone else, so writes are denied by default.
--
-- Safe to rerun: IF NOT EXISTS / DROP ... IF EXISTS guards throughout.
--
-- Depends on: 002 (public.products), 003 (public.is_admin()),
--             001 (public.update_updated_at_column()).
-- ============================================

BEGIN;

-- ============================================
-- TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS public.product_translations (
    product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    locale TEXT NOT NULL,
    name TEXT NOT NULL,
    subtitle TEXT,
    description TEXT,
    features TEXT[],
    specifications JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (product_id, locale),
    CONSTRAINT product_translations_locale_check
        CHECK (locale IN ('en', 'ru', 'uz', 'es', 'fr')),
    CONSTRAINT product_translations_name_not_blank
        CHECK (btrim(name) <> ''),
    CONSTRAINT product_translations_specifications_is_object
        CHECK (specifications IS NULL OR jsonb_typeof(specifications) = 'object')
);

COMMENT ON TABLE public.product_translations IS 'Per-locale product text. products.name/subtitle/description/features/specifications stay as the English fallback; the app falls back to them when no row exists for the requested locale. uz text is Latin script.';
COMMENT ON COLUMN public.product_translations.locale IS 'Language code: en, ru, uz (Latin), es, fr. Same set as profiles.language_code.';
COMMENT ON COLUMN public.product_translations.features IS 'Translated feature bullets, same order as products.features.';
COMMENT ON COLUMN public.product_translations.specifications IS 'Translated specifications as a JSON object (translated keys and values), same shape as products.specifications.';

-- ============================================
-- INDEXES
-- ============================================

-- PK (product_id, locale) already serves lookups by product and by
-- (product, locale). This covers locale-first scans, e.g. embedding or
-- listing every translation for one locale.
CREATE INDEX IF NOT EXISTS idx_product_translations_locale
    ON public.product_translations(locale, product_id);

-- ============================================
-- updated_at TRIGGER (reuses function from migration 001, not redefined)
-- ============================================

DROP TRIGGER IF EXISTS update_product_translations_updated_at ON public.product_translations;
CREATE TRIGGER update_product_translations_updated_at
    BEFORE UPDATE ON public.product_translations
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================
-- ROW LEVEL SECURITY
-- ============================================

ALTER TABLE public.product_translations ENABLE ROW LEVEL SECURITY;

-- Anyone can read translations of active products
DROP POLICY IF EXISTS "Anyone can view translations of active products" ON public.product_translations;
CREATE POLICY "Anyone can view translations of active products"
    ON public.product_translations
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.products
            WHERE products.id = product_translations.product_id
              AND products.is_active = true
        )
    );

-- Admins can read all translations, including those of inactive products.
-- (SELECT ...) wrapper lets Postgres evaluate is_admin() once per statement.
DROP POLICY IF EXISTS "Admins can view all product translations" ON public.product_translations;
CREATE POLICY "Admins can view all product translations"
    ON public.product_translations
    FOR SELECT
    USING ((SELECT public.is_admin()));

DROP POLICY IF EXISTS "Admins can insert product translations" ON public.product_translations;
CREATE POLICY "Admins can insert product translations"
    ON public.product_translations
    FOR INSERT
    WITH CHECK ((SELECT public.is_admin()));

DROP POLICY IF EXISTS "Admins can update product translations" ON public.product_translations;
CREATE POLICY "Admins can update product translations"
    ON public.product_translations
    FOR UPDATE
    USING ((SELECT public.is_admin()))
    WITH CHECK ((SELECT public.is_admin()));

DROP POLICY IF EXISTS "Admins can delete product translations" ON public.product_translations;
CREATE POLICY "Admins can delete product translations"
    ON public.product_translations
    FOR DELETE
    USING ((SELECT public.is_admin()));

COMMIT;

-- ============================================
-- VERIFICATION QUERIES (run manually after applying)
-- ============================================

-- 1. Table exists with RLS enabled
-- SELECT relname, relrowsecurity FROM pg_class
-- WHERE relnamespace = 'public'::regnamespace AND relname = 'product_translations';

-- 2. Policies
-- SELECT policyname, cmd FROM pg_policies WHERE tablename = 'product_translations';

-- 3. Constraints and indexes
-- SELECT conname, contype FROM pg_constraint
-- WHERE conrelid = 'public.product_translations'::regclass;
-- SELECT indexname FROM pg_indexes WHERE tablename = 'product_translations';

-- 4. Trigger
-- SELECT trigger_name FROM information_schema.triggers
-- WHERE event_object_table = 'product_translations';

-- ============================================
-- ROLLBACK (USE WITH CAUTION - deletes all translations)
-- ============================================
-- DROP TABLE IF EXISTS public.product_translations CASCADE;

-- ============================================
-- END OF MIGRATION
-- ============================================
