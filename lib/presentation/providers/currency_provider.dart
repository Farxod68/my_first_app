import 'package:flutter/material.dart';
import '../../core/services/persistence_service.dart';
import 'base_persistent_provider.dart';

/// Currency state management provider with persistence
///
/// Manages application currency preference including:
/// - Current selected currency
/// - Change currency functionality
/// - Supported currencies list
/// - Automatic persistence to local storage
///
/// Supports 4 currencies mapped to languages:
/// - USD (en) → $ symbol
/// - EUR (es/fr) → € symbol
/// - UZS (uz) → so'm
///
/// Uses ChangeNotifier for state management with Provider pattern
/// Persists currency preference using PersistenceService
class CurrencyProvider with ChangeNotifier, PersistentProviderMixin {
  final PersistenceService _persistenceService;
  String _currentCurrency = 'USD';

  CurrencyProvider(this._persistenceService) {
    _loadCurrency();
  }

  /// Supported currencies for the application
  static const List<String> supportedCurrencies = [
    'USD', // US Dollar
    'EUR', // Euro
    'UZS', // Uzbekistan Som
  ];

  /// Currency symbols mapping
  static const Map<String, String> currencySymbols = {
    'USD': '\$',
    'EUR': '€',
    'UZS': "so'm",
  };

  /// Currency names for display
  static const Map<String, String> currencyNames = {
    'USD': 'US Dollar (USD)',
    'EUR': 'Euro (EUR)',
    'UZS': "O'zbek so'mi (UZS)",
  };

  /// Get current currency code
  String get currentCurrency => _currentCurrency;

  /// Get current currency symbol
  String get currencySymbol => currencySymbols[_currentCurrency] ?? '\$';

  /// Get current currency name
  String get currencyName => currencyNames[_currentCurrency] ?? 'US Dollar';

  /// Change the application currency
  ///
  /// Only accepts currencies from the supported currencies list.
  /// Notifies listeners after currency change to trigger rebuild.
  void setCurrency(String newCurrency) {
    if (supportedCurrencies.contains(newCurrency) &&
        _currentCurrency != newCurrency) {
      _currentCurrency = newCurrency;
      _saveCurrency();
      notifyListeners();
    }
  }

  /// Check if a currency is supported
  bool isCurrencySupported(String currency) {
    return supportedCurrencies.contains(currency);
  }

  /// Load currency from persistence
  ///
  /// Called automatically during initialization.
  /// Falls back to USD if no saved currency or if saved currency is unsupported.
  Future<void> _loadCurrency() async {
    try {
      final savedCurrency = _persistenceService.getString('currency_code');

      if (savedCurrency != null) {
        if (supportedCurrencies.contains(savedCurrency)) {
          _currentCurrency = savedCurrency;
        } else {
          // Saved currency is not supported, use default
          debugPrint(
              'Saved currency $savedCurrency not supported, using default');
        }
      }
    } catch (e) {
      debugPrint('Failed to load currency: $e');
      // Continue with default currency
    } finally {
      markAsLoaded();
    }
  }

  /// Save currency to persistence
  ///
  /// Called automatically after currency changes.
  /// Fails silently to avoid disrupting user experience.
  Future<void> _saveCurrency() async {
    try {
      await _persistenceService.saveString('currency_code', _currentCurrency);
    } catch (e) {
      debugPrint('Failed to save currency: $e');
      // Continue without throwing - persistence failure shouldn't crash app
    }
  }

  /// Get currency code from language code
  /// Helper method to map language preferences to default currencies
  static String getCurrencyFromLanguage(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'USD';
      case 'es':
      case 'fr':
        return 'EUR';
      case 'uz':
        return 'UZS';
      default:
        return 'USD';
    }
  }
}
