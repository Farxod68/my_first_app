-- TOPBUY DEALS - Tighten product translation table privileges
BEGIN;

REVOKE ALL PRIVILEGES ON TABLE public.product_translations FROM anon;
REVOKE ALL PRIVILEGES ON TABLE public.product_translations FROM authenticated;

GRANT SELECT ON TABLE public.product_translations TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE
    ON TABLE public.product_translations TO authenticated;

GRANT ALL PRIVILEGES ON TABLE public.product_translations TO service_role;

COMMIT;
