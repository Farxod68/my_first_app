import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/providers/locale_provider.dart';
import '../../presentation/providers/currency_provider.dart';

/// Authentication helper utilities for TOPBUY DEALS
///
/// Provides shared authentication-related functionality including:
/// - Preference synchronization from user profile
///
/// These utilities are used across multiple authentication flows
/// to maintain consistency.
class AuthHelpers {
  AuthHelpers._(); // Private constructor - utility class

  /// Sync language and currency preferences from authenticated user profile
  ///
  /// Called after login/signup or on app start to ensure local preferences
  /// match the user's saved preferences in Supabase.
  ///
  /// Parameters:
  /// - [context]: BuildContext for accessing providers
  /// - [logPrefix]: Optional prefix for debug logs (default: 'AUTH')
  ///
  /// Behavior:
  /// - Does nothing if AuthProvider is not available
  /// - Does nothing if user is not authenticated
  /// - Syncs language preference if different from local
  /// - Syncs currency preference if different from local
  /// - Fails silently on errors to not disrupt user flow
  static void syncPreferencesFromProfile(
    BuildContext context, {
    String logPrefix = 'AUTH',
  }) {
    try {
      final authProvider = context.read<AuthProvider?>();
      if (authProvider == null || !authProvider.isAuthenticated) {
        return; // No auth provider or not authenticated, keep local preferences
      }

      final prefs = authProvider.getUserPreferences();
      if (prefs == null) {
        return;
      }

      final localeProvider = context.read<LocaleProvider>();
      final currencyProvider = context.read<CurrencyProvider>();

      // Sync language preference
      if (prefs['languageCode'] != null &&
          prefs['languageCode'] != localeProvider.languageCode) {
        localeProvider.setLocaleByCode(prefs['languageCode']!);
        debugPrint('[$logPrefix] Synced language preference: ${prefs['languageCode']}');
      }

      // Sync currency preference
      if (prefs['currencyCode'] != null &&
          prefs['currencyCode'] != currencyProvider.currentCurrency) {
        currencyProvider.setCurrency(prefs['currencyCode']!);
        debugPrint('[$logPrefix] Synced currency preference: ${prefs['currencyCode']}');
      }
    } catch (e) {
      debugPrint('[$logPrefix] Failed to sync preferences: $e');
      // Continue with existing local preferences - sync failure shouldn't block user
    }
  }
}
