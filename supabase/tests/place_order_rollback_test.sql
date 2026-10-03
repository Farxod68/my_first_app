-- ============================================
-- pgTAP rollback test for public.place_order() (migration 006)
-- ============================================
--
-- Run locally with: supabase test db
-- LOCAL ONLY: this file creates a temporary trigger on public.products.
-- Never run it against a linked/remote project.
--
-- Purpose: prove that place_order() leaves nothing behind when an error
-- occurs AFTER all of its writes (orders insert, order_items insert and
-- products stock update). Every expected failure in place_order_test.sql
-- happens before the first write, so that file cannot prove this.
--
-- How: a test-only AFTER UPDATE OF stock row trigger on public.products,
-- limited by its WHEN clause to one sentinel product, fires at the end of
-- place_order()'s stock UPDATE. Row-level AFTER triggers see every change
-- made by the statement and by the earlier statements in the function, so
-- the trigger first verifies that the order, both order_items rows and both
-- stock decrements really exist, and only then raises
-- PGTAP_INJECTED_FAILURE. If any of those writes is missing it raises
-- PGTAP_PRECONDITION_NOT_MET instead, so the test cannot pass by accident.
--
-- Cleanup: the trigger and its function are dropped explicitly after the
-- failure checks. Everything (test user, category, products, trigger,
-- trigger function, control order) also runs inside one transaction that
-- is rolled back at the end, so nothing is persisted.
--
-- Callers are simulated the same way PostgREST does it: SET LOCAL ROLE
-- authenticated plus request.jwt.claims, which auth.uid() reads.
--
-- ============================================

BEGIN;

CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;

SELECT plan(12);

-- ============================================
-- SETUP (as postgres)
-- ============================================

-- Dedicated test user (handle_new_user() creates the profiles row)
INSERT INTO auth.users (id, email, aud, role)
VALUES ('00000000-0000-4000-a000-000000000003', 'pgtap-rollback-user@example.com', 'authenticated', 'authenticated');

INSERT INTO public.categories (id, key, sort_order)
VALUES ('00000000-0000-4000-b000-000000000002', 'pgtap-rollback-category', 999);

-- Sentinel (only product the trigger fires for) and a partner product
INSERT INTO public.products (id, slug, name, price, old_price, category_id, stock, is_active)
VALUES
    ('00000000-0000-4000-c000-000000000010', 'pgtap-rollback-sentinel', 'PgTAP Rollback Sentinel', 7.00, 8.00, '00000000-0000-4000-b000-000000000002', 5, true),
    ('00000000-0000-4000-c000-000000000011', 'pgtap-rollback-partner',  'PgTAP Rollback Partner',  3.00, 3.50, '00000000-0000-4000-b000-000000000002', 4, true);

-- Captures the control call's place_order() result
CREATE TEMP TABLE pgtap_rollback_results (
    label text NOT NULL,
    order_id uuid,
    subtotal_usd numeric
);
GRANT ALL ON pgtap_rollback_results TO authenticated;

-- ----------------------------
-- Injection trigger
-- ----------------------------
-- Expected state when it fires for the cart used below
-- (2 x sentinel @ 7.00 + 1 x partner @ 3.00 = 17.00):
--   - exactly one order for the test user: pending, subtotal 17.00
--   - exactly two order_items rows for it: sentinel x2, partner x1
--   - sentinel stock 5 -> 3 (OLD/NEW of this row), partner stock 4 -> 3
-- SECURITY DEFINER (owner postgres) so RLS can never hide the rows checked.

CREATE FUNCTION public.pgtap_fail_after_place_order_writes()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_order_id uuid;
BEGIN
    SELECT oi.order_id INTO v_order_id
      FROM public.order_items AS oi
     WHERE oi.product_id = NEW.id;

    IF (SELECT count(*) FROM public.order_items AS oi
         WHERE oi.product_id = NEW.id) = 1
       AND (SELECT count(*) FROM public.orders AS o
             WHERE o.user_id = '00000000-0000-4000-a000-000000000003') = 1
       AND EXISTS (
           SELECT 1 FROM public.orders AS o
            WHERE o.id = v_order_id
              AND o.user_id = '00000000-0000-4000-a000-000000000003'
              AND o.status = 'pending'
              AND o.subtotal_usd = 17.00)
       AND (SELECT count(*) FROM public.order_items AS oi
             WHERE oi.order_id = v_order_id) = 2
       AND EXISTS (
           SELECT 1 FROM public.order_items AS oi
            WHERE oi.order_id = v_order_id
              AND oi.product_id = '00000000-0000-4000-c000-000000000010'
              AND oi.quantity = 2)
       AND EXISTS (
           SELECT 1 FROM public.order_items AS oi
            WHERE oi.order_id = v_order_id
              AND oi.product_id = '00000000-0000-4000-c000-000000000011'
              AND oi.quantity = 1)
       AND OLD.stock = 5
       AND NEW.stock = 3
       AND (SELECT p.stock FROM public.products AS p
             WHERE p.id = '00000000-0000-4000-c000-000000000011') = 3
    THEN
        RAISE EXCEPTION 'PGTAP_INJECTED_FAILURE';
    END IF;

    RAISE EXCEPTION 'PGTAP_PRECONDITION_NOT_MET';
END;
$$;

CREATE TRIGGER pgtap_fail_after_place_order_writes
    AFTER UPDATE OF stock ON public.products
    FOR EACH ROW
    WHEN (NEW.id = '00000000-0000-4000-c000-000000000010')
    EXECUTE FUNCTION public.pgtap_fail_after_place_order_writes();

SELECT has_trigger(
    'public', 'products', 'pgtap_fail_after_place_order_writes',
    'injection trigger is installed on the sentinel product table'
);

-- ============================================
-- 1. FAILURE AFTER ALL WRITES
-- ============================================

SET LOCAL request.jwt.claims = '{"sub": "00000000-0000-4000-a000-000000000003", "role": "authenticated"}';
SET LOCAL ROLE authenticated;

-- throws_ok runs the call in a subtransaction; the injected error rolls
-- back to it. The exact message proves the writes existed when it fired.
SELECT throws_ok(
    $$SELECT * FROM public.place_order(
        '[{"slug": "pgtap-rollback-sentinel", "quantity": 2}, {"slug": "pgtap-rollback-partner", "quantity": 1}]'::jsonb,
        'Jane Doe', '+998901234567', '1 Main St', 'Tashkent', 'Uzbekistan')$$,
    'P0001', 'PGTAP_INJECTED_FAILURE',
    'error raised after order, items and stock writes propagates out of place_order'
);

RESET ROLE;

-- ============================================
-- 2. NOTHING FROM THE FAILED CALL REMAINS (as postgres, so RLS hides nothing)
-- ============================================

SELECT is(
    (SELECT count(*)::int FROM public.orders
      WHERE user_id = '00000000-0000-4000-a000-000000000003'),
    0,
    'failed call left no order'
);

SELECT is(
    (SELECT count(*)::int FROM public.order_items
      WHERE product_id IN ('00000000-0000-4000-c000-000000000010',
                           '00000000-0000-4000-c000-000000000011')),
    0,
    'failed call left no order_items'
);

SELECT results_eq(
    $$SELECT slug, stock FROM public.products
       WHERE slug LIKE 'pgtap-rollback-%' ORDER BY slug$$,
    $$VALUES ('pgtap-rollback-partner'::text, 4), ('pgtap-rollback-sentinel'::text, 5)$$,
    'failed call left stock of every involved product unchanged'
);

-- ============================================
-- 3. REMOVE THE INJECTION TRIGGER
-- ============================================
-- Explicit cleanup; the final ROLLBACK is the safeguard.

DROP TRIGGER pgtap_fail_after_place_order_writes ON public.products;
DROP FUNCTION public.pgtap_fail_after_place_order_writes();

SELECT hasnt_trigger(
    'public', 'products', 'pgtap_fail_after_place_order_writes',
    'injection trigger has been removed'
);

SELECT hasnt_function(
    'public'::name, 'pgtap_fail_after_place_order_writes'::name, ARRAY[]::name[],
    'injection trigger function has been removed'
);

-- ============================================
-- 4. CONTROL: SAME CART SUCCEEDS WITHOUT THE TRIGGER
-- ============================================
-- Proves the input was valid and the only cause of the failure above was
-- the injected trigger.

SET LOCAL request.jwt.claims = '{"sub": "00000000-0000-4000-a000-000000000003", "role": "authenticated"}';
SET LOCAL ROLE authenticated;

INSERT INTO pgtap_rollback_results
SELECT 'control', r.order_id, r.subtotal_usd
  FROM public.place_order(
    '[{"slug": "pgtap-rollback-sentinel", "quantity": 2}, {"slug": "pgtap-rollback-partner", "quantity": 1}]'::jsonb,
    'Jane Doe', '+998901234567', '1 Main St', 'Tashkent', 'Uzbekistan'
  ) AS r;

RESET ROLE;

SELECT is(
    (SELECT count(*)::int FROM pgtap_rollback_results WHERE label = 'control'),
    1,
    'control call returns exactly one row'
);

SELECT is(
    (SELECT subtotal_usd FROM pgtap_rollback_results WHERE label = 'control'),
    17.00::numeric,
    'control call subtotal is 2 x 7.00 + 1 x 3.00'
);

SELECT results_eq(
    $$SELECT o.id, o.user_id FROM public.orders o
       WHERE o.user_id = '00000000-0000-4000-a000-000000000003'$$,
    $$SELECT r.order_id, '00000000-0000-4000-a000-000000000003'::uuid
        FROM pgtap_rollback_results r WHERE r.label = 'control'$$,
    'test user has exactly the control order'
);

SELECT results_eq(
    $$SELECT oi.product_slug, oi.quantity
        FROM public.order_items oi
        JOIN pgtap_rollback_results r ON r.order_id = oi.order_id
       WHERE r.label = 'control'
       ORDER BY oi.product_slug$$,
    $$VALUES ('pgtap-rollback-partner'::text, 1), ('pgtap-rollback-sentinel'::text, 2)$$,
    'control order has the sentinel and partner items'
);

SELECT results_eq(
    $$SELECT slug, stock FROM public.products
       WHERE slug LIKE 'pgtap-rollback-%' ORDER BY slug$$,
    $$VALUES ('pgtap-rollback-partner'::text, 3), ('pgtap-rollback-sentinel'::text, 3)$$,
    'control call decremented stock (partner 4 -> 3, sentinel 5 -> 3)'
);

SELECT * FROM finish();

ROLLBACK;
