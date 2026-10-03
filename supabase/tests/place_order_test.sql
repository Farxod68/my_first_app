-- ============================================
-- pgTAP tests for public.place_order() (migration 006)
-- ============================================
--
-- Run locally with: supabase test db
--
-- Everything runs inside one transaction that is rolled back at the end,
-- so no test users, products, orders or stock changes are persisted.
-- All test rows use fixed UUIDs / a "pgtap-" prefix so they cannot collide
-- with real data.
--
-- Callers are simulated the same way PostgREST does it: SET LOCAL ROLE
-- (authenticated / anon) plus request.jwt.claims, which auth.uid() reads.
--
-- ============================================

BEGIN;

CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;

SELECT plan(64);

-- ============================================
-- SETUP (as postgres)
-- ============================================

-- Test users (handle_new_user() creates their profiles rows)
INSERT INTO auth.users (id, email, aud, role)
VALUES
    ('00000000-0000-4000-a000-000000000001', 'pgtap-user1@example.com', 'authenticated', 'authenticated'),
    ('00000000-0000-4000-a000-000000000002', 'pgtap-user2@example.com', 'authenticated', 'authenticated');

INSERT INTO public.categories (id, key, sort_order)
VALUES ('00000000-0000-4000-b000-000000000001', 'pgtap-test-category', 999);

INSERT INTO public.products (id, slug, name, price, old_price, category_id, stock, is_active)
VALUES
    ('00000000-0000-4000-c000-00000000000a', 'pgtap-a',        'PgTAP Product A', 10.00, 12.00, '00000000-0000-4000-b000-000000000001',  5, true),
    ('00000000-0000-4000-c000-00000000000b', 'pgtap-b',        'PgTAP Product B',  2.50,  3.00, '00000000-0000-4000-b000-000000000001',  3, true),
    ('00000000-0000-4000-c000-00000000000c', 'pgtap-inactive', 'PgTAP Inactive',   1.00,  1.00, '00000000-0000-4000-b000-000000000001', 10, false),
    ('00000000-0000-4000-c000-00000000000d', 'pgtap-zero',     'PgTAP Zero Stock', 4.00,  4.00, '00000000-0000-4000-b000-000000000001',  0, true);

-- Captures place_order() results so they can be inspected after the call
CREATE TEMP TABLE pgtap_results (
    label text NOT NULL,
    order_id uuid,
    subtotal_usd numeric
);
GRANT ALL ON pgtap_results TO authenticated;

-- ============================================
-- 1. STRUCTURE AND PRIVILEGES
-- ============================================

SELECT has_function(
    'public', 'place_order',
    ARRAY['jsonb', 'text', 'text', 'text', 'text', 'text', 'text'],
    'place_order(jsonb, text x6) exists'
);

SELECT is_definer(
    'public', 'place_order',
    ARRAY['jsonb', 'text', 'text', 'text', 'text', 'text', 'text'],
    'place_order is SECURITY DEFINER'
);

SELECT is(
    (SELECT proconfig FROM pg_proc
      WHERE oid = 'public.place_order(jsonb, text, text, text, text, text, text)'::regprocedure),
    ARRAY['search_path=public, pg_temp'],
    'place_order has a fixed search_path'
);

SELECT is(
    (SELECT pg_get_function_result(
        'public.place_order(jsonb, text, text, text, text, text, text)'::regprocedure)),
    'TABLE(order_id uuid, subtotal_usd numeric)',
    'place_order returns TABLE(order_id uuid, subtotal_usd numeric)'
);

SELECT ok(
    has_function_privilege('authenticated',
        'public.place_order(jsonb, text, text, text, text, text, text)', 'EXECUTE'),
    'authenticated can execute place_order'
);

SELECT ok(
    NOT has_function_privilege('anon',
        'public.place_order(jsonb, text, text, text, text, text, text)', 'EXECUTE'),
    'anon cannot execute place_order'
);

-- ============================================
-- 2. SUCCESSFUL ORDER (user 1)
-- ============================================

SET LOCAL request.jwt.claims = '{"sub": "00000000-0000-4000-a000-000000000001", "role": "authenticated"}';
SET LOCAL ROLE authenticated;

-- 2 x A (10.00) + 1 x B (2.50) = 22.50; shipping padded with whitespace
INSERT INTO pgtap_results
SELECT 'first', r.order_id, r.subtotal_usd
  FROM public.place_order(
    '[{"slug": "pgtap-a", "quantity": 2}, {"slug": "pgtap-b", "quantity": 1}]'::jsonb,
    '  Jane Doe  ', ' +998901234567 ', ' 1 Main St ', ' Tashkent ', ' Uzbekistan ',
    'EUR'
  ) AS r;

RESET ROLE;

SELECT is(
    (SELECT count(*)::int FROM pgtap_results WHERE label = 'first'),
    1,
    'place_order returns exactly one row'
);

SELECT isnt(
    (SELECT order_id FROM pgtap_results WHERE label = 'first'),
    NULL,
    'returned order_id is not null'
);

SELECT is(
    (SELECT subtotal_usd FROM pgtap_results WHERE label = 'first'),
    22.50::numeric,
    'returned subtotal is computed from server prices (2 x 10.00 + 1 x 2.50)'
);

SELECT is(
    (SELECT o.user_id FROM public.orders o
       JOIN pgtap_results r ON r.order_id = o.id WHERE r.label = 'first'),
    '00000000-0000-4000-a000-000000000001'::uuid,
    'order belongs to auth.uid()'
);

SELECT is(
    (SELECT o.status FROM public.orders o
       JOIN pgtap_results r ON r.order_id = o.id WHERE r.label = 'first'),
    'pending',
    'order status is pending'
);

SELECT is(
    (SELECT o.subtotal_usd FROM public.orders o
       JOIN pgtap_results r ON r.order_id = o.id WHERE r.label = 'first'),
    22.50::numeric,
    'stored subtotal_usd matches returned subtotal'
);

SELECT is(
    (SELECT o.currency_code FROM public.orders o
       JOIN pgtap_results r ON r.order_id = o.id WHERE r.label = 'first'),
    'EUR',
    'order stores the requested display currency'
);

SELECT results_eq(
    $$SELECT o.shipping_full_name, o.shipping_phone, o.shipping_address_line,
             o.shipping_city, o.shipping_country
        FROM public.orders o
        JOIN pgtap_results r ON r.order_id = o.id
       WHERE r.label = 'first'$$,
    $$VALUES ('Jane Doe'::text, '+998901234567'::text, '1 Main St'::text,
              'Tashkent'::text, 'Uzbekistan'::text)$$,
    'shipping fields are stored trimmed'
);

SELECT is(
    (SELECT count(*)::int FROM public.order_items oi
       JOIN pgtap_results r ON r.order_id = oi.order_id WHERE r.label = 'first'),
    2,
    'order has two order_items rows'
);

SELECT results_eq(
    $$SELECT oi.product_id, oi.product_slug, oi.product_name, oi.unit_price_usd, oi.quantity
        FROM public.order_items oi
        JOIN pgtap_results r ON r.order_id = oi.order_id
       WHERE r.label = 'first'
       ORDER BY oi.product_slug$$,
    $$VALUES
        ('00000000-0000-4000-c000-00000000000a'::uuid, 'pgtap-a'::text, 'PgTAP Product A'::text, 10.00::numeric, 2),
        ('00000000-0000-4000-c000-00000000000b'::uuid, 'pgtap-b'::text, 'PgTAP Product B'::text,  2.50::numeric, 1)$$,
    'order_items snapshot product id, slug, name, server unit price and quantity'
);

SELECT is(
    (SELECT stock FROM public.products WHERE slug = 'pgtap-a'),
    3,
    'stock of product A reduced from 5 to 3'
);

SELECT is(
    (SELECT stock FROM public.products WHERE slug = 'pgtap-b'),
    2,
    'stock of product B reduced from 3 to 2'
);

SELECT is(
    (SELECT stock FROM public.products WHERE slug = 'pgtap-inactive'),
    10,
    'stock of products not in the cart is unchanged'
);

-- ----------------------------
-- Default currency (p_currency_code omitted)
-- ----------------------------

SET LOCAL ROLE authenticated;

INSERT INTO pgtap_results
SELECT 'default_currency', r.order_id, r.subtotal_usd
  FROM public.place_order(
    '[{"slug": "pgtap-b", "quantity": 1}]'::jsonb,
    'Jane Doe', '+998901234567', '1 Main St', 'Tashkent', 'Uzbekistan'
  ) AS r;

RESET ROLE;

SELECT is(
    (SELECT o.currency_code FROM public.orders o
       JOIN pgtap_results r ON r.order_id = o.id WHERE r.label = 'default_currency'),
    'USD',
    'currency defaults to USD when omitted'
);

SELECT is(
    (SELECT subtotal_usd FROM pgtap_results WHERE label = 'default_currency'),
    2.50::numeric,
    'default-currency order subtotal is 2.50'
);

SELECT is(
    (SELECT stock FROM public.products WHERE slug = 'pgtap-b'),
    1,
    'stock of product B reduced from 2 to 1'
);

-- ============================================
-- 3. SECOND USER / EXACT REMAINING STOCK
-- ============================================

SET LOCAL request.jwt.claims = '{"sub": "00000000-0000-4000-a000-000000000002", "role": "authenticated"}';
SET LOCAL ROLE authenticated;

-- Orders all 3 remaining units of A
INSERT INTO pgtap_results
SELECT 'user2', r.order_id, r.subtotal_usd
  FROM public.place_order(
    '[{"slug": "pgtap-a", "quantity": 3}]'::jsonb,
    'John Roe', '+998907654321', '2 Side St', 'Samarkand', 'Uzbekistan',
    'UZS'
  ) AS r;

-- RLS: user 2 must not see user 1's order
SELECT is(
    (SELECT count(*)::int FROM public.orders o
       JOIN pgtap_results r ON r.order_id = o.id WHERE r.label = 'first'),
    0,
    'user 2 cannot see user 1''s order via RLS'
);

SELECT is(
    (SELECT count(*)::int FROM public.orders o
       JOIN pgtap_results r ON r.order_id = o.id WHERE r.label = 'user2'),
    1,
    'user 2 can see their own order via RLS'
);

RESET ROLE;

SELECT is(
    (SELECT o.user_id FROM public.orders o
       JOIN pgtap_results r ON r.order_id = o.id WHERE r.label = 'user2'),
    '00000000-0000-4000-a000-000000000002'::uuid,
    'second order belongs to user 2'
);

SELECT is(
    (SELECT subtotal_usd FROM pgtap_results WHERE label = 'user2'),
    30.00::numeric,
    'ordering the exact remaining stock succeeds (3 x 10.00)'
);

SELECT is(
    (SELECT stock FROM public.products WHERE slug = 'pgtap-a'),
    0,
    'stock of product A reduced to exactly 0'
);

SELECT is(
    (SELECT count(*)::int FROM public.orders
      WHERE user_id = '00000000-0000-4000-a000-000000000001'),
    2,
    'user 1 still has exactly their own two orders'
);

-- ============================================
-- 4. FAILURE CASES
-- ============================================
-- Stock now: A = 0, B = 1, inactive = 10, zero = 0.
-- Each call uses otherwise-valid input so only the targeted check fails.

SET LOCAL request.jwt.claims = '{"sub": "00000000-0000-4000-a000-000000000001", "role": "authenticated"}';
SET LOCAL ROLE authenticated;

-- ----------------------------
-- NOT_AUTHENTICATED
-- ----------------------------

SET LOCAL request.jwt.claims = '';

SELECT throws_ok(
    $$SELECT * FROM public.place_order('[{"slug": "pgtap-b", "quantity": 1}]'::jsonb,
        'Jane Doe', '+998901234567', '1 Main St', 'Tashkent', 'Uzbekistan')$$,
    'P0001', 'NOT_AUTHENTICATED',
    'no JWT subject raises NOT_AUTHENTICATED'
);

SET LOCAL request.jwt.claims = '{"sub": "00000000-0000-4000-a000-000000000001", "role": "authenticated"}';

-- ----------------------------
-- EMPTY_CART
-- ----------------------------

SELECT throws_ok(
    $$SELECT * FROM public.place_order(NULL,
        'Jane Doe', '+998901234567', '1 Main St', 'Tashkent', 'Uzbekistan')$$,
    'P0001', 'EMPTY_CART',
    'null items raises EMPTY_CART'
);

SELECT throws_ok(
    $$SELECT * FROM public.place_order('[]'::jsonb,
        'Jane Doe', '+998901234567', '1 Main St', 'Tashkent', 'Uzbekistan')$$,
    'P0001', 'EMPTY_CART',
    'empty array raises EMPTY_CART'
);

SELECT throws_ok(
    $$SELECT * FROM public.place_order('{"slug": "pgtap-b", "quantity": 1}'::jsonb,
        'Jane Doe', '+998901234567', '1 Main St', 'Tashkent', 'Uzbekistan')$$,
    'P0001', 'EMPTY_CART',
    'non-array items raises EMPTY_CART'
);

-- ----------------------------
-- INVALID_QUANTITY
-- ----------------------------

SELECT throws_ok(
    $$SELECT * FROM public.place_order('[{"slug": "pgtap-b", "quantity": 0}]'::jsonb,
        'Jane Doe', '+998901234567', '1 Main St', 'Tashkent', 'Uzbekistan')$$,
    'P0001', 'INVALID_QUANTITY',
    'quantity 0 raises INVALID_QUANTITY'
);

SELECT throws_ok(
    $$SELECT * FROM public.place_order('[{"slug": "pgtap-b", "quantity": -1}]'::jsonb,
        'Jane Doe', '+998901234567', '1 Main St', 'Tashkent', 'Uzbekistan')$$,
    'P0001', 'INVALID_QUANTITY',
    'negative quantity raises INVALID_QUANTITY'
);

SELECT throws_ok(
    $$SELECT * FROM public.place_order('[{"slug": "pgtap-b", "quantity": 1.5}]'::jsonb,
        'Jane Doe', '+998901234567', '1 Main St', 'Tashkent', 'Uzbekistan')$$,
    'P0001', 'INVALID_QUANTITY',
    'fractional quantity raises INVALID_QUANTITY'
);

SELECT throws_ok(
    $$SELECT * FROM public.place_order('[{"slug": "pgtap-b", "quantity": "1"}]'::jsonb,
        'Jane Doe', '+998901234567', '1 Main St', 'Tashkent', 'Uzbekistan')$$,
    'P0001', 'INVALID_QUANTITY',
    'string quantity raises INVALID_QUANTITY'
);

SELECT throws_ok(
    $$SELECT * FROM public.place_order('[{"slug": "pgtap-b"}]'::jsonb,
        'Jane Doe', '+998901234567', '1 Main St', 'Tashkent', 'Uzbekistan')$$,
    'P0001', 'INVALID_QUANTITY',
    'missing quantity raises INVALID_QUANTITY'
);

SELECT throws_ok(
    $$SELECT * FROM public.place_order('[{"slug": "pgtap-b", "quantity": 2147483648}]'::jsonb,
        'Jane Doe', '+998901234567', '1 Main St', 'Tashkent', 'Uzbekistan')$$,
    'P0001', 'INVALID_QUANTITY',
    'quantity above integer range raises INVALID_QUANTITY'
);

SELECT throws_ok(
    $$SELECT * FROM public.place_order('[{"slug": "   ", "quantity": 1}]'::jsonb,
        'Jane Doe', '+998901234567', '1 Main St', 'Tashkent', 'Uzbekistan')$$,
    'P0001', 'INVALID_QUANTITY',
    'blank slug raises INVALID_QUANTITY'
);

SELECT throws_ok(
    $$SELECT * FROM public.place_order('[{"quantity": 1}]'::jsonb,
        'Jane Doe', '+998901234567', '1 Main St', 'Tashkent', 'Uzbekistan')$$,
    'P0001', 'INVALID_QUANTITY',
    'missing slug raises INVALID_QUANTITY'
);

SELECT throws_ok(
    $$SELECT * FROM public.place_order('["pgtap-b"]'::jsonb,
        'Jane Doe', '+998901234567', '1 Main St', 'Tashkent', 'Uzbekistan')$$,
    'P0001', 'INVALID_QUANTITY',
    'non-object item raises INVALID_QUANTITY'
);

-- ----------------------------
-- DUPLICATE_ITEM
-- ----------------------------

SELECT throws_ok(
    $$SELECT * FROM public.place_order(
        '[{"slug": "pgtap-b", "quantity": 1}, {"slug": "pgtap-b", "quantity": 1}]'::jsonb,
        'Jane Doe', '+998901234567', '1 Main St', 'Tashkent', 'Uzbekistan')$$,
    'P0001', 'DUPLICATE_ITEM',
    'same slug twice raises DUPLICATE_ITEM'
);

-- ----------------------------
-- INVALID_SHIPPING
-- ----------------------------

SELECT throws_ok(
    $$SELECT * FROM public.place_order('[{"slug": "pgtap-b", "quantity": 1}]'::jsonb,
        NULL, '+998901234567', '1 Main St', 'Tashkent', 'Uzbekistan')$$,
    'P0001', 'INVALID_SHIPPING',
    'null full name raises INVALID_SHIPPING'
);

SELECT throws_ok(
    $$SELECT * FROM public.place_order('[{"slug": "pgtap-b", "quantity": 1}]'::jsonb,
        'Jane Doe', '   ', '1 Main St', 'Tashkent', 'Uzbekistan')$$,
    'P0001', 'INVALID_SHIPPING',
    'blank phone raises INVALID_SHIPPING'
);

SELECT throws_ok(
    $$SELECT * FROM public.place_order('[{"slug": "pgtap-b", "quantity": 1}]'::jsonb,
        'Jane Doe', '+998901234567', '', 'Tashkent', 'Uzbekistan')$$,
    'P0001', 'INVALID_SHIPPING',
    'empty address line raises INVALID_SHIPPING'
);

SELECT throws_ok(
    $$SELECT * FROM public.place_order('[{"slug": "pgtap-b", "quantity": 1}]'::jsonb,
        'Jane Doe', '+998901234567', '1 Main St', NULL, 'Uzbekistan')$$,
    'P0001', 'INVALID_SHIPPING',
    'null city raises INVALID_SHIPPING'
);

SELECT throws_ok(
    $$SELECT * FROM public.place_order('[{"slug": "pgtap-b", "quantity": 1}]'::jsonb,
        'Jane Doe', '+998901234567', '1 Main St', 'Tashkent', ' ')$$,
    'P0001', 'INVALID_SHIPPING',
    'blank country raises INVALID_SHIPPING'
);

-- ----------------------------
-- INVALID_CURRENCY
-- ----------------------------

SELECT throws_ok(
    $$SELECT * FROM public.place_order('[{"slug": "pgtap-b", "quantity": 1}]'::jsonb,
        'Jane Doe', '+998901234567', '1 Main St', 'Tashkent', 'Uzbekistan', 'GBP')$$,
    'P0001', 'INVALID_CURRENCY',
    'unsupported currency raises INVALID_CURRENCY'
);

SELECT throws_ok(
    $$SELECT * FROM public.place_order('[{"slug": "pgtap-b", "quantity": 1}]'::jsonb,
        'Jane Doe', '+998901234567', '1 Main St', 'Tashkent', 'Uzbekistan', NULL)$$,
    'P0001', 'INVALID_CURRENCY',
    'null currency raises INVALID_CURRENCY'
);

SELECT throws_ok(
    $$SELECT * FROM public.place_order('[{"slug": "pgtap-b", "quantity": 1}]'::jsonb,
        'Jane Doe', '+998901234567', '1 Main St', 'Tashkent', 'Uzbekistan', 'usd')$$,
    'P0001', 'INVALID_CURRENCY',
    'lowercase currency raises INVALID_CURRENCY'
);

-- ----------------------------
-- PRODUCT_UNAVAILABLE
-- ----------------------------

SELECT throws_ok(
    $$SELECT * FROM public.place_order('[{"slug": "pgtap-does-not-exist", "quantity": 1}]'::jsonb,
        'Jane Doe', '+998901234567', '1 Main St', 'Tashkent', 'Uzbekistan')$$,
    'P0001', 'PRODUCT_UNAVAILABLE',
    'unknown slug raises PRODUCT_UNAVAILABLE'
);

SELECT throws_ok(
    $$SELECT * FROM public.place_order('[{"slug": "pgtap-inactive", "quantity": 1}]'::jsonb,
        'Jane Doe', '+998901234567', '1 Main St', 'Tashkent', 'Uzbekistan')$$,
    'P0001', 'PRODUCT_UNAVAILABLE',
    'inactive product raises PRODUCT_UNAVAILABLE'
);

SELECT throws_ok(
    $$SELECT * FROM public.place_order(
        '[{"slug": "pgtap-b", "quantity": 1}, {"slug": "pgtap-does-not-exist", "quantity": 1}]'::jsonb,
        'Jane Doe', '+998901234567', '1 Main St', 'Tashkent', 'Uzbekistan')$$,
    'P0001', 'PRODUCT_UNAVAILABLE',
    'one unknown slug in a mixed cart raises PRODUCT_UNAVAILABLE'
);

-- ----------------------------
-- INSUFFICIENT_STOCK
-- ----------------------------

SELECT throws_ok(
    $$SELECT * FROM public.place_order('[{"slug": "pgtap-b", "quantity": 2}]'::jsonb,
        'Jane Doe', '+998901234567', '1 Main St', 'Tashkent', 'Uzbekistan')$$,
    'P0001', 'INSUFFICIENT_STOCK',
    'quantity above stock raises INSUFFICIENT_STOCK'
);

SELECT throws_ok(
    $$SELECT * FROM public.place_order('[{"slug": "pgtap-zero", "quantity": 1}]'::jsonb,
        'Jane Doe', '+998901234567', '1 Main St', 'Tashkent', 'Uzbekistan')$$,
    'P0001', 'INSUFFICIENT_STOCK',
    'zero-stock product raises INSUFFICIENT_STOCK'
);

SELECT throws_ok(
    $$SELECT * FROM public.place_order('[{"slug": "pgtap-a", "quantity": 1}]'::jsonb,
        'Jane Doe', '+998901234567', '1 Main St', 'Tashkent', 'Uzbekistan')$$,
    'P0001', 'INSUFFICIENT_STOCK',
    'product sold out by an earlier order raises INSUFFICIENT_STOCK'
);

-- ----------------------------
-- Mixed cart: valid B + sold-out A is rejected before any write.
-- ----------------------------

SELECT throws_ok(
    $$SELECT * FROM public.place_order(
        '[{"slug": "pgtap-b", "quantity": 1}, {"slug": "pgtap-a", "quantity": 1}]'::jsonb,
        'Jane Doe', '+998901234567', '1 Main St', 'Tashkent', 'Uzbekistan')$$,
    'P0001', 'INSUFFICIENT_STOCK',
    'mixed cart with one sold-out item raises INSUFFICIENT_STOCK'
);

-- ----------------------------
-- anon cannot call the function at all
-- ----------------------------

SET LOCAL ROLE anon;
SET LOCAL request.jwt.claims = '{"role": "anon"}';

SELECT throws_ok(
    $$SELECT * FROM public.place_order('[{"slug": "pgtap-b", "quantity": 1}]'::jsonb,
        'Jane Doe', '+998901234567', '1 Main St', 'Tashkent', 'Uzbekistan')$$,
    '42501', NULL,
    'anon calling place_order is denied'
);

RESET ROLE;

-- ============================================
-- 5. NO SIDE EFFECTS FROM FAILED CALLS
-- ============================================

SELECT is(
    (SELECT count(*)::int FROM public.orders
      WHERE user_id IN ('00000000-0000-4000-a000-000000000001',
                        '00000000-0000-4000-a000-000000000002')),
    3,
    'failed calls created no orders (still 3 test orders)'
);

SELECT is(
    (SELECT count(*)::int FROM public.order_items oi
       JOIN public.orders o ON o.id = oi.order_id
      WHERE o.user_id IN ('00000000-0000-4000-a000-000000000001',
                          '00000000-0000-4000-a000-000000000002')),
    4,
    'failed calls created no order_items (still 4 test items)'
);

SELECT results_eq(
    $$SELECT slug, stock FROM public.products WHERE slug LIKE 'pgtap-%' ORDER BY slug$$,
    $$VALUES ('pgtap-a'::text, 0), ('pgtap-b'::text, 1),
             ('pgtap-inactive'::text, 10), ('pgtap-zero'::text, 0)$$,
    'failed calls left all stock unchanged'
);

-- ============================================
-- 6. CLIENT-SUPPLIED PRICE IS IGNORED
-- ============================================
-- Runs last so earlier stock assertions are unaffected. A is sold out
-- (stock 0) at this point, so restock one unit as postgres first.

UPDATE public.products SET stock = 1 WHERE slug = 'pgtap-a';

SET LOCAL request.jwt.claims = '{"sub": "00000000-0000-4000-a000-000000000001", "role": "authenticated"}';
SET LOCAL ROLE authenticated;

-- Client claims A costs 0.01; server price is 10.00
INSERT INTO pgtap_results
SELECT 'client_price', r.order_id, r.subtotal_usd
  FROM public.place_order(
    '[{"slug": "pgtap-a", "quantity": 1, "price": 0.01}]'::jsonb,
    'Jane Doe', '+998901234567', '1 Main St', 'Tashkent', 'Uzbekistan'
  ) AS r;

RESET ROLE;

SELECT is(
    (SELECT subtotal_usd FROM pgtap_results WHERE label = 'client_price'),
    10.00::numeric,
    'returned subtotal uses the server price (10.00), not the client price (0.01)'
);

SELECT is(
    (SELECT o.subtotal_usd FROM public.orders o
       JOIN pgtap_results r ON r.order_id = o.id WHERE r.label = 'client_price'),
    10.00::numeric,
    'stored subtotal_usd uses the server price, not the client price'
);

SELECT is(
    (SELECT oi.unit_price_usd FROM public.order_items oi
       JOIN pgtap_results r ON r.order_id = oi.order_id WHERE r.label = 'client_price'),
    10.00::numeric,
    'order_items unit_price_usd uses the server price, not the client price'
);

SELECT * FROM finish();

ROLLBACK;
