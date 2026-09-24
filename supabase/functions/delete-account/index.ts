// TOPBUY DEALS - Account Deletion Edge Function
//
// Deployed to the linked Supabase project as the `delete-account` Edge
// Function. Changes to this file take effect only after the project owner
// redeploys it:
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
//
// ORDERS
// - public.orders.user_id references auth.users ON DELETE RESTRICT
//   (supabase/migrations/005_orders.sql): order retention on account
//   deletion is intentionally unresolved. A caller who has at least one
//   order therefore gets 409 { error: "account_has_orders",
//   code: "ACCOUNT_HAS_ORDERS" } and nothing is deleted. The foreign key
//   still blocks the delete if an order appears after this check.
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

  // Refuse deletion while the verified caller has any orders. user.id comes
  // only from the verified session above, never from the request.
  const { data: orders, error: ordersError } = await adminClient
    .from('orders')
    .select('id')
    .eq('user_id', user.id)
    .limit(1);

  if (ordersError) {
    return new Response(
      JSON.stringify({ error: ordersError.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } },
    );
  }

  if (orders.length > 0) {
    return new Response(
      JSON.stringify({ error: 'account_has_orders', code: 'ACCOUNT_HAS_ORDERS' }),
      { status: 409, headers: { 'Content-Type': 'application/json' } },
    );
  }

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
