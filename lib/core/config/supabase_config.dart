import 'package:flutter/foundation.dart';

/// Supabase configuration for TOPBUY DEALS
///
/// SECURITY NOTICE:
/// - Only the ANON KEY (public key) should be in client code
/// - NEVER commit the SERVICE_ROLE KEY to version control
/// - USE ENVIRONMENT VARIABLES for production builds
///
/// Configuration approach:
/// 1. Development: Use constants below (replace with your values)
/// 2. Production: Use --dart-define for secure builds:
///    flutter build apk --dart-define=SUPABASE_URL=https://xxx.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJxxx
///
/// Row Level Security (RLS) policies protect data even with the anon key exposed.
class SupabaseConfig {
  /// Supabase project URL
  ///
  /// Format: https://[project-ref].supabase.co
  /// Get this from: Supabase Dashboard → Settings → API → Project URL
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'YOUR_SUPABASE_URL_HERE', // Replace with your Supabase project URL
  );

  /// Supabase anonymous (public) key
  ///
  /// This is safe to expose in client code.
  /// RLS policies control what data can be accessed.
  /// Get this from: Supabase Dashboard → Settings → API → Project API keys → anon public
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'YOUR_SUPABASE_ANON_KEY_HERE', // Replace with your Supabase anon key
  );

  /// ⚠️ WARNING: NEVER include the service_role key in client code! ⚠️
  ///
  /// The service_role key bypasses ALL Row Level Security policies.
  /// It should ONLY be used in:
  /// - Backend server environments
  /// - Supabase Edge Functions
  /// - Database migrations
  ///
  /// If you accidentally committed it:
  /// 1. Regenerate it immediately in Supabase Dashboard
  /// 2. Remove it from git history
  /// 3. Update all backend services with new key

  /// Check if Supabase is configured
  ///
  /// Returns true if both URL and anon key are set (not placeholders)
  static bool get isConfigured {
    return supabaseUrl != 'YOUR_SUPABASE_URL_HERE' &&
        supabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY_HERE' &&
        supabaseUrl.isNotEmpty &&
        supabaseAnonKey.isNotEmpty;
  }

  /// Hosts that may use plain HTTP in debug builds (local Supabase stack).
  /// 10.0.2.2 is the Android emulator's alias for the host machine.
  static const Set<String> _localDevHosts = {'localhost', '127.0.0.1', '10.0.2.2'};

  /// Whether [url] may be used as the Supabase URL.
  ///
  /// HTTPS is mandatory, except plain HTTP to a loopback host in debug
  /// builds. The host is compared after parsing, so look-alikes such as
  /// http://127.0.0.1.evil.com are rejected.
  static bool isAllowedUrl(String url, {bool isDebug = kDebugMode}) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasAuthority || uri.host.isEmpty) return false;
    if (uri.scheme == 'https') return true;
    return isDebug && uri.scheme == 'http' && _localDevHosts.contains(uri.host);
  }

  /// Validate configuration
  ///
  /// Throws an exception if configuration is invalid
  static void validate() {
    if (!isConfigured) {
      throw Exception(
        'Supabase is not configured. Please set SUPABASE_URL and SUPABASE_ANON_KEY.\n'
        'Update lib/core/config/supabase_config.dart with your Supabase credentials.\n'
        'Get them from: Supabase Dashboard → Settings → API',
      );
    }

    if (!isAllowedUrl(supabaseUrl)) {
      throw Exception(
        'SUPABASE_URL must use https:// '
        '(http:// is allowed only for localhost in debug builds)',
      );
    }

    if (supabaseUrl.contains('YOUR_')) {
      throw Exception('Please replace placeholder Supabase URL with your actual project URL');
    }

    if (supabaseAnonKey.contains('YOUR_')) {
      throw Exception('Please replace placeholder Supabase anon key with your actual anon key');
    }
  }
}
