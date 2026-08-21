# Supabase Setup Guide — TOPBUY DEALS

This guide explains how to set up Supabase backend for TOPBUY DEALS marketplace.

## Phase 5A.1 Status: Foundation Complete ✅

**Implemented**:
- Supabase Flutter SDK integration
- Authentication architecture (repository pattern)
- Database schema (profiles table)
- Row Level Security policies
- User entity and models

**NOT Implemented Yet** (Future Phases):
- Login/Signup UI (Phase 5A.2)
- Products API (Phase 5B)
- Cart/Wishlist sync (Phase 5C)
- Orders & Checkout (Phase 5D-5E)

---

## Prerequisites

1. **Supabase Account**
   - Create free account at [https://supabase.com](https://supabase.com)
   - No credit card required for development

2. **Flutter Development Environment**
   - Flutter 3.13.0+
   - Dart 3.0+

---

## Step 1: Create Supabase Project

1. Go to [https://supabase.com/dashboard](https://supabase.com/dashboard)
2. Click **"New project"**
3. Enter project details:
   - **Name**: topbuy-deals (or your preferred name)
   - **Database Password**: Choose a strong password (save it securely!)
   - **Region**: Choose closest to your users (e.g., us-east-1)
   - **Pricing Plan**: Free (sufficient for development)
4. Click **"Create new project"**
5. Wait 2-3 minutes for project to initialize

---

## Step 2: Get API Credentials

1. In your Supabase project dashboard, go to:
   - **Settings** → **API**

2. Copy two values:
   - **Project URL** (format: `https://xxxxx.supabase.co`)
   - **anon public** key (under "Project API keys")

   **IMPORTANT**:
   - ✅ **anon public key** = SAFE to use in Flutter app
   - ❌ **service_role key** = NEVER use in Flutter app (server-side only)

---

## Step 3: Configure Flutter App

1. Open `lib/core/config/supabase_config.dart`

2. Replace the placeholder values:

```dart
static const String supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://xxxxx.supabase.co', // ← Paste your Project URL here
);

static const String supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...', // ← Paste your anon key here
);
```

3. Save the file

**Security Note**: The anon key is safe to commit to Git. Row Level Security (RLS) policies protect your data.

---

## Step 4: Run Database Migration

1. In Supabase Dashboard, go to:
   - **SQL Editor** (left sidebar)

2. Click **"New query"**

3. Copy the entire contents of:
   - `supabase/migrations/001_initial_auth_profiles.sql`

4. Paste into the SQL Editor

5. Click **"Run"** (or press Ctrl+Enter / Cmd+Enter)

6. Verify success:
   - You should see "Success. No rows returned" (this is correct!)
   - No error messages

7. Verify table created:
   - Go to **Table Editor** (left sidebar)
   - You should see a `profiles` table

---

## Step 5: Test the Integration

1. Run the app:
   ```bash
   flutter run
   ```

2. The app should launch successfully

3. Check console for initialization message:
   ```
   [SUPABASE] Initialized successfully
   ```

**If NOT configured**: App will run in local-only mode (existing functionality preserved)

---

## Step 6: Verify Row Level Security

1. In Supabase Dashboard, go to:
   - **Authentication** → **Policies**

2. Click on the `profiles` table

3. Verify policies exist:
   - ✅ "Users can view own profile"
   - ✅ "Users can update own profile"
   - ✅ "Users can insert own profile"
   - ✅ "Admins can view all profiles"

4. Check policy rules:
   - Users can only access their own data (auth.uid() = id)
   - Users cannot modify role, email, or email_verified

---

## Step 7: Create Test User (Optional)

1. In Supabase Dashboard, go to:
   - **Authentication** → **Users**

2. Click **"Add user"** → **"Create new user"**

3. Enter:
   - **Email**: test@example.com
   - **Password**: TestPassword123!
   - **Auto Confirm User**: ✅ (check this box)

4. Click **"Create user"**

5. Verify profile created:
   - Go to **Table Editor** → `profiles`
   - You should see a row with the user's email

---

## Security Architecture

### Authentication Flow

```
Flutter App
    ↓
AuthProvider (state management)
    ↓
AuthRepository (business logic)
    ↓
AuthDataSource (Supabase API calls)
    ↓
Supabase Auth
    ↓
PostgreSQL (auth.users + profiles)
```

### Key Security Features

1. **Single Source of Truth**: Supabase Auth
   - Email verification status in `auth.users.email_confirmed_at`
   - `profiles.email_verified` synced via database trigger

2. **Role Protection**:
   - Users CANNOT change their own `role`
   - RLS policy prevents privilege escalation
   - Only admins can change roles (via SQL, not app UI)

3. **Row Level Security**:
   - Users can only read/update their own profile
   - Admins can view all profiles
   - Enforced at database level (can't bypass)

4. **No Secrets in Client Code**:
   - Only anon key in Flutter app (safe)
   - Service role key NEVER in client
   - All sensitive operations server-side

---

## Troubleshooting

### "Supabase is not configured" Error

**Cause**: Placeholder values not replaced in `supabase_config.dart`

**Solution**:
1. Check `lib/core/config/supabase_config.dart`
2. Ensure `supabaseUrl` and `supabaseAnonKey` are set
3. Restart the app

---

### "Failed to initialize Supabase" Error

**Cause**: Invalid URL or key

**Solution**:
1. Verify URL format: `https://xxxxx.supabase.co` (no trailing slash)
2. Verify anon key is complete (starts with `eyJ`)
3. Check for typos

---

### "Table profiles does not exist" Error

**Cause**: Database migration not run

**Solution**:
1. Go to Supabase Dashboard → SQL Editor
2. Run the migration script
3. Verify table exists in Table Editor

---

### App Works Without Supabase

**This is intentional!** The app has been designed to work in both modes:

- ✅ **Supabase configured**: Backend-powered features enabled
- ✅ **Supabase NOT configured**: Local-only mode (existing Phase 1-4B features)

All cart, wishlist, locale, and product catalog features work locally regardless of Supabase.

---

## What's Next?

### Phase 5A.2: Authentication UI (Next)

After Supabase is configured, Phase 5A.2 will add:
- Login screen
- Sign up screen
- Password reset screen
- Profile management

### Future Phases

- **Phase 5B**: Products API integration
- **Phase 5C**: Cart/Wishlist sync across devices
- **Phase 5D**: Orders & Checkout
- **Phase 5E**: Payments (Stripe)
- **Phase 5F**: Seller marketplace

---

## Support

**Issues?**
- Check Supabase Dashboard logs: **Logs** → **Postgres Logs**
- Check Flutter console for error messages
- Verify RLS policies in Authentication → Policies

**Need Help?**
- Supabase Discord: [https://discord.supabase.com](https://discord.supabase.com)
- Supabase Docs: [https://supabase.com/docs](https://supabase.com/docs)

---

## Security Checklist

Before deploying to production:

- [ ] Change database password from default
- [ ] Enable email verification in Supabase Dashboard
- [ ] Set up custom SMTP (not Supabase default emails)
- [ ] Enable MFA for admin accounts
- [ ] Review and test all RLS policies
- [ ] Set up monitoring and alerts
- [ ] Configure proper CORS in Supabase API settings
- [ ] Use environment variables for production builds
- [ ] Never commit service_role key to Git
- [ ] Set up proper backup strategy

---

**Last Updated**: Phase 5A.1 Complete
