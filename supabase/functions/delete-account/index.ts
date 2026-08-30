// TOPBUY DEALS - Account Deletion Edge Function
//
// NOT YET DEPLOYED. This file only exists in the repo for review. To make
// account deletion actually work in the running app, the project owner
// must deploy it:
//
//   supabase functions deploy delete-account
//
// SUPABASE_URL, SUPABASE_ANON_KEY, and SUPABASE_SERVICE_ROLE_KEY are
// provided automatically as built-in secrets in every Supabase Edge
// Function runtime - do NOT set them manually, and NEVER copy the
// service_role key into the Flutter app or any other client-side code.
//
// SECURITY
// - Runs entirely server-side. The service_role key never leaves this
//   function's runtime.
// - The caller's identity comes only from their own verified JWT (the
//   Authorization header the Supabase Flutter SDK attaches automatically
//   to every authenticated request) - it cannot be supplied or spoofed by
//   the client, so this function can only ever delete the caller's own
//   account, never another user's.
// - Deleting the auth user cascades to their `profiles` row automatically
//   via the ON DELETE CASCADE foreign key already defined in
//   supabase/migrations/001_initial_auth_profiles.sql - no extra cleanup
//   needed.
import { createClient } from 'jsr:@supabase/supabase-js@2';

Deno.serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 });
  }

  const authHeader = req.headers.get('Authorization');
  if (!authHeader) {
    return new Response(
      JSON.stringify({ error: 'Missing Authorization header' }),
      { status: 401, headers: { 'Content-Type': 'application/json' } },
    );
  }

  // Scoped to the caller's own JWT - used only to verify who is asking.
  const callerClient = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
    { global: { headers: { Authorization: authHeader } } },
  );

  const {
    data: { user },
    error: userError,
  } = await callerClient.auth.getUser();

  if (userError || !user) {
    return new Response(
      JSON.stringify({ error: 'Invalid or expired session' }),
      { status: 401, headers: { 'Content-Type': 'application/json' } },
    );
  }

  // Privileged client - the service_role key is used only here, server-side,
  // and only to delete the id we just verified above.
  const adminClient = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  );

  const { error: deleteError } = await adminClient.auth.admin.deleteUser(user.id);

  if (deleteError) {
    return new Response(
      JSON.stringify({ error: deleteError.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } },
    );
  }

  return new Response(
    JSON.stringify({ success: true }),
    { status: 200, headers: { 'Content-Type': 'application/json' } },
  );
});
