-- ============================================
-- TOPBUY DEALS - Allow Russian profile language
-- Widens profiles.language_code CHECK to include 'ru'
-- ============================================
--
-- STATUS: Russian support in profiles_language_code_check was verified in
-- production on 2026-11-02 (the constraint already allows 'ru'). This file
-- records that change in the repo and is safe to rerun.
--
-- Why: the app now offers Russian in the language picker. Without 'ru' in
-- the CHECK ('en', 'es', 'fr', 'uz'), saving 'ru' as a signed-in user's
-- profile language is rejected.
--
-- The constraint was created inline in 001_initial_auth_profiles.sql, so
-- Postgres named it profiles_language_code_check. Verify the name first:
--   SELECT conname FROM pg_constraint
--   WHERE conrelid = 'public.profiles'::regclass AND contype = 'c';
--
-- Apply in the Supabase SQL Editor or via `supabase db push`.
-- Existing rows are unaffected: every current value remains allowed.

BEGIN;

ALTER TABLE public.profiles
    DROP CONSTRAINT IF EXISTS profiles_language_code_check;

ALTER TABLE public.profiles
    ADD CONSTRAINT profiles_language_code_check
    CHECK (language_code IN ('en', 'es', 'fr', 'uz', 'ru'));

COMMENT ON COLUMN public.profiles.language_code IS
    'Preferred UI language (en, es, fr, uz, ru)';

COMMIT;
