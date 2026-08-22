import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Mock implementations for Supabase testing
///
/// These mocks isolate tests from the actual Supabase backend.
/// Use with mocktail's when() to stub behavior and verify() to check interactions.

/// Mock SupabaseClient for testing
class MockSupabaseClient extends Mock implements SupabaseClient {}

/// Mock GoTrueClient (Supabase Auth) for testing
class MockGoTrueClient extends Mock implements GoTrueClient {}

/// Mock SupabaseStorageClient for testing
class MockSupabaseStorageClient extends Mock implements SupabaseStorageClient {}

/// Mock RealtimeClient for testing
class MockRealtimeClient extends Mock implements RealtimeClient {}

/// Mock Supabase static class for testing initialization
///
/// Note: Mocking static methods requires special handling.
/// For SupabaseService tests, we'll test the service logic separately
/// from the actual Supabase.initialize() call.
class MockSupabase extends Mock implements Supabase {}
