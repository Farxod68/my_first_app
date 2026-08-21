import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Supabase service singleton for TOPBUY DEALS
///
/// Provides centralized access to Supabase client.
/// Initializes Supabase once at app startup.
///
/// Architecture:
/// - UI never calls Supabase directly
/// - Data sources use this service
/// - Repository pattern mediates between providers and data sources
///
/// Usage:
/// ```dart
/// await SupabaseService.initialize();
/// final client = SupabaseService.client;
/// ```
class SupabaseService {
  static SupabaseClient? _client;

  /// Get Supabase client instance
  ///
  /// Throws if not initialized. Call initialize() first.
  static SupabaseClient get client {
    if (_client == null) {
      throw Exception(
        'SupabaseService not initialized. Call SupabaseService.initialize() first.',
      );
    }
    return _client!;
  }

  /// Check if Supabase is initialized
  static bool get isInitialized => _client != null;

  /// Initialize Supabase
  ///
  /// Must be called once at app startup before using any Supabase features.
  /// Safe to call multiple times (no-op after first initialization).
  ///
  /// Throws if configuration is invalid.
  static Future<void> initialize() async {
    // Skip if already initialized
    if (_client != null) {
      return;
    }

    // Validate configuration
    SupabaseConfig.validate();

    try {
      // Initialize Supabase
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce, // More secure than implicit flow
        ),
        // Debug mode (disable in production)
        debug: false,
      );

      _client = Supabase.instance.client;
    } catch (e) {
      throw Exception('Failed to initialize Supabase: $e');
    }
  }

  /// Dispose Supabase client
  ///
  /// Rarely needed, but useful for testing
  static Future<void> dispose() async {
    _client = null;
  }

  // Convenience getters for common Supabase features

  /// Get auth client
  static GoTrueClient get auth => client.auth;

  /// Get storage client
  static SupabaseStorageClient get storage => client.storage;

  /// Get realtime client
  static RealtimeClient get realtime => client.realtime;
}
