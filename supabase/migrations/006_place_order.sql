-- ============================================
-- TOPBUY DEALS - Order Placement Migration
-- Server-side order creation: public.place_order()
-- ============================================
--
-- This migration adds the ONLY supported way to create orders.
--
-- IMPORTANT: Run this migration in your Supabase SQL Editor
-- (Supabase Dashboard -> SQL Editor -> New Query -> Paste & Run)
-- or via `supabase db push`.
--
-- What this creates:
-- 1. public.place_order(...) - a SECURITY DEFINER function that validates a
--    cart, re-prices it from public.products, locks and decrements stock,
--    and writes one public.orders row plus its public.order_items rows in a
--    single transaction.
-- 2. Explicit EXECUTE grants: authenticated only (not PUBLIC, not anon).
--
-- What this does NOT change:
-- - No table, column, index or RLS policy is added, changed or dropped.
--   Migration 005 intentionally gives the application NO INSERT/UPDATE/
--   DELETE policy on orders/order_items; that stays true. This function is
--   the only write path, running with its owner's privileges.
-- - Migrations 001-005 are not modified.
--
-- SECURITY NOTES:
-- - Identity: the ordering user is taken ONLY from auth.uid(). The function
--   has no user_id parameter, so a caller cannot order as someone else.
-- - Prices: the function has no price parameter. Every unit price and the
--   subtotal come from the current public.products.price (USD). Cart prices
--   held by the Flutter app are client-side snapshots and are never trusted.
-- - SECURITY DEFINER with a fixed search_path (public, pg_temp), matching
--   public.is_admin() in migration 003, so object lookups cannot be
--   hijacked through the caller's search_path.
-- - Concurrency: the referenced product rows are locked with
--   SELECT ... FOR UPDATE in a fixed order (by id) before stock is checked
--   and decremented, so concurrent orders cannot oversell and cannot
--   deadlock on lock ordering.
-- - Atomicity: the function runs inside the caller's single statement/
--   transaction. Any RAISE EXCEPTION rolls back every insert and stock
--   update made by this call - no partial orders.
--
-- INPUT:
-- - p_items: JSON array of objects { "slug": text, "quantity": integer }.
--   "slug" is products.slug (the Flutter Product.id, e.g. "elec-001").
-- - Shipping fields are stored trimmed.
-- - p_currency_code is the customer's display currency (USD, EUR, UZS).
--   It is stored for display only; all amounts are USD.
--
-- ERRORS (RAISE EXCEPTION message is exactly one of these codes, so the
-- application can map them to localized messages):
-- - NOT_AUTHENTICATED    auth.uid() is null
-- - EMPTY_CART           p_items is null, not an array, or empty
-- - INVALID_QUANTITY     an item has a blank/missing slug, or a quantity
--                        that is missing, non-integer, or < 1
-- - DUPLICATE_ITEM       the same slug appears more than once
-- - INVALID_SHIPPING     any shipping field is null or blank
-- - INVALID_CURRENCY     currency is not USD, EUR or UZS
-- - PRODUCT_UNAVAILABLE  a slug does not exist or the product is inactive
-- - INSUFFICIENT_STOCK   a product's stock is lower than the quantity
--
-- RETURNS: one row (order_id, subtotal_usd) for the created order.
--
-- ============================================

-- ============================================
-- FUNCTION: public.place_order()
-- ============================================

CREATE OR REPLACE FUNCTION public.place_order(
    p_items jsonb,
    p_shipping_full_name text,
    p_shipping_phone text,
    p_shipping_address_line text,
    p_shipping_city text,
    p_shipping_country text,
    p_currency_code text DEFAULT 'USD'
)
RETURNS TABLE (order_id uuid, subtotal_usd numeric)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
-- The RETURNS TABLE names (order_id, subtotal_usd) are also column names
-- of order_items/orders. Resolve any ambiguity in favour of the column;
-- all column references below are table-qualified as well.
#variable_conflict use_column
DECLARE
    v_user_id uuid := auth.uid();
    v_item jsonb;
    v_quantity numeric;
    v_item_count integer;
    v_distinct_slug_count integer;
    v_available_count integer;
    v_order_id uuid;
    v_subtotal numeric(10,2);
BEGIN
    -- ----------------------------
    -- 1. Identity (auth.uid() only)
    -- ----------------------------
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'NOT_AUTHENTICATED';
    END IF;

    -- ----------------------------
    -- 2. Cart shape
    -- ----------------------------
    IF p_items IS NULL
       OR jsonb_typeof(p_items) <> 'array'
       OR jsonb_array_length(p_items) = 0 THEN
        RAISE EXCEPTION 'EMPTY_CART';
    END IF;

    -- Every item needs a non-blank slug and an integer quantity >= 1.
    -- Quantity is validated as a JSON number before any cast, so a bad
    -- value raises INVALID_QUANTITY instead of a cast error.
    FOR v_item IN SELECT e FROM jsonb_array_elements(p_items) AS e LOOP
        IF jsonb_typeof(v_item) IS DISTINCT FROM 'object'
           OR NULLIF(btrim(v_item->>'slug'), '') IS NULL
           OR jsonb_typeof(v_item->'quantity') IS DISTINCT FROM 'number' THEN
            RAISE EXCEPTION 'INVALID_QUANTITY';
        END IF;

        v_quantity := (v_item->>'quantity')::numeric;
        IF v_quantity <> trunc(v_quantity)
           OR v_quantity < 1
           OR v_quantity > 2147483647 THEN
            RAISE EXCEPTION 'INVALID_QUANTITY';
        END IF;
    END LOOP;

    SELECT count(*), count(DISTINCT e->>'slug')
      INTO v_item_count, v_distinct_slug_count
      FROM jsonb_array_elements(p_items) AS e;

    IF v_distinct_slug_count <> v_item_count THEN
        RAISE EXCEPTION 'DUPLICATE_ITEM';
    END IF;

    -- ----------------------------
    -- 3. Shipping and currency
    -- ----------------------------
    IF NULLIF(btrim(p_shipping_full_name), '') IS NULL
       OR NULLIF(btrim(p_shipping_phone), '') IS NULL
       OR NULLIF(btrim(p_shipping_address_line), '') IS NULL
       OR NULLIF(btrim(p_shipping_city), '') IS NULL
       OR NULLIF(btrim(p_shipping_country), '') IS NULL THEN
        RAISE EXCEPTION 'INVALID_SHIPPING';
    END IF;

    IF p_currency_code IS NULL
       OR p_currency_code NOT IN ('USD', 'EUR', 'UZS') THEN
        RAISE EXCEPTION 'INVALID_CURRENCY';
    END IF;

    -- ----------------------------
    -- 4. Lock the referenced products (fixed order: by id)
    -- ----------------------------
    PERFORM 1
       FROM public.products AS p
      WHERE p.slug IN (SELECT e->>'slug' FROM jsonb_array_elements(p_items) AS e)
      ORDER BY p.id
        FOR UPDATE;

    -- ----------------------------
    -- 5. Availability and stock (checked on the locked rows)
    -- ----------------------------
    SELECT count(*)
      INTO v_available_count
      FROM public.products AS p
      JOIN (SELECT e->>'slug' AS slug FROM jsonb_array_elements(p_items) AS e) AS req
        ON req.slug = p.slug
     WHERE p.is_active = true;

    IF v_available_count <> v_item_count THEN
        RAISE EXCEPTION 'PRODUCT_UNAVAILABLE';
    END IF;

    IF EXISTS (
        SELECT 1
          FROM public.products AS p
          JOIN (SELECT e->>'slug' AS slug,
                       (e->>'quantity')::numeric::integer AS quantity
                  FROM jsonb_array_elements(p_items) AS e) AS req
            ON req.slug = p.slug
         WHERE p.stock < req.quantity
    ) THEN
        RAISE EXCEPTION 'INSUFFICIENT_STOCK';
    END IF;

    -- ----------------------------
    -- 6. Subtotal from current server prices only
    -- ----------------------------
    SELECT sum(p.price * req.quantity)
      INTO v_subtotal
      FROM public.products AS p
      JOIN (SELECT e->>'slug' AS slug,
                   (e->>'quantity')::numeric::integer AS quantity
              FROM jsonb_array_elements(p_items) AS e) AS req
        ON req.slug = p.slug;

    -- ----------------------------
    -- 7. Write the order and its items
    -- ----------------------------
    INSERT INTO public.orders (
        user_id,
        status,
        subtotal_usd,
        currency_code,
        shipping_full_name,
        shipping_phone,
        shipping_address_line,
        shipping_city,
        shipping_country
    ) VALUES (
        v_user_id,
        'pending',
        v_subtotal,
        p_currency_code,
        btrim(p_shipping_full_name),
        btrim(p_shipping_phone),
        btrim(p_shipping_address_line),
        btrim(p_shipping_city),
        btrim(p_shipping_country)
    )
    RETURNING public.orders.id INTO v_order_id;

    INSERT INTO public.order_items (
        order_id,
        product_id,
        product_slug,
        product_name,
        unit_price_usd,
        quantity
    )
    SELECT v_order_id,
           p.id,
           p.slug,
           p.name,
           p.price,
           req.quantity
      FROM public.products AS p
      JOIN (SELECT e->>'slug' AS slug,
                   (e->>'quantity')::numeric::integer AS quantity
              FROM jsonb_array_elements(p_items) AS e) AS req
        ON req.slug = p.slug;

    -- ----------------------------
    -- 8. Decrement stock (rows are already locked by this transaction)
    -- ----------------------------
    UPDATE public.products AS p
       SET stock = p.stock - req.quantity
      FROM (SELECT e->>'slug' AS slug,
                   (e->>'quantity')::numeric::integer AS quantity
              FROM jsonb_array_elements(p_items) AS e) AS req
     WHERE p.slug = req.slug;

    -- ----------------------------
    -- 9. Result
    -- ----------------------------
    RETURN QUERY SELECT v_order_id, v_subtotal::numeric;
END;
$$;

COMMENT ON FUNCTION public.place_order(jsonb, text, text, text, text, text, text) IS
    'Creates a pending order for auth.uid() from p_items ([{slug, quantity}]). Re-prices every item from public.products.price (USD) - no client price is accepted - locks product rows FOR UPDATE, checks is_active and stock, decrements stock, and inserts orders + order_items atomically. SECURITY DEFINER with fixed search_path; the only write path for orders (RLS in 005 allows the application no direct writes). Errors: NOT_AUTHENTICATED, EMPTY_CART, INVALID_QUANTITY, DUPLICATE_ITEM, INVALID_SHIPPING, INVALID_CURRENCY, PRODUCT_UNAVAILABLE, INSUFFICIENT_STOCK. Returns (order_id, subtotal_usd).';

-- Explicit least-privilege grants: do not rely on default PUBLIC EXECUTE.
-- Only signed-in users may place orders; anon cannot call this function.
REVOKE ALL ON FUNCTION public.place_order(jsonb, text, text, text, text, text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.place_order(jsonb, text, text, text, text, text, text) TO authenticated;

-- ============================================
-- VERIFICATION QUERIES
-- ============================================

-- After running this migration, verify with these queries (read-only):

-- 1. Function exists, is SECURITY DEFINER, and has the fixed search_path
--    (expect prosecdef = true, proconfig = {"search_path=public, pg_temp"})
-- SELECT proname, prosecdef, proconfig, pg_get_function_identity_arguments(oid) AS args
-- FROM pg_proc
-- WHERE proname = 'place_order' AND pronamespace = 'public'::regnamespace;

-- 2. EXECUTE privileges by role
--    (expect anon = false, authenticated = true)
-- SELECT r.rolname,
--        has_function_privilege(r.rolname,
--          'public.place_order(jsonb, text, text, text, text, text, text)', 'EXECUTE') AS can_execute
-- FROM pg_roles r
-- WHERE r.rolname IN ('anon', 'authenticated');

-- 3. No RLS policy was added to orders/order_items (expect 4 rows, all SELECT)
-- SELECT tablename, policyname, cmd
-- FROM pg_policies
-- WHERE tablename IN ('orders', 'order_items');

-- 4. Orders tables still empty after migration (expect 0 and 0)
-- SELECT (SELECT count(*) FROM public.orders) AS orders,
--        (SELECT count(*) FROM public.order_items) AS order_items;

-- ============================================
-- ROLLBACK (if needed)
-- ============================================

-- To rollback this migration (removes only the function; no data is touched):
-- DROP FUNCTION IF EXISTS public.place_order(jsonb, text, text, text, text, text, text);

-- ============================================
-- END OF MIGRATION
-- ============================================
