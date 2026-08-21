import 'package:flutter/material.dart';
import '../../core/services/persistence_service.dart';

/// Locale/Language state management provider with persistence
///
/// Manages application locale including:
/// - Current selected locale
/// - Change locale functionality
/// - Supported locales list
/// - Automatic persistence to local storage
///
/// Supports 4 languages:
/// - English (en) → USD currency
/// - Spanish (es) → EUR currency
/// - French (fr) → EUR currency
/// - Uzbek (uz) → UZS currency
///
/// Uses ChangeNotifier for state management with Provider pattern
/// Persists locale preference using PersistenceService
class LocaleProvider with ChangeNotifier {
  final PersistenceService _persistenceService;
  Locale _currentLocale = const Locale('en');
  bool _isLoaded = false;

  LocaleProvider(this._persistenceService) {
    _loadLocale();
  }

  /// Check if locale data has been loaded from storage
  bool get isLoaded => _isLoaded;

  /// Supported locales for the application
  static const List<Locale> supportedLocales = [
    Locale('en'), // English
    Locale('es'), // Spanish
    Locale('fr'), // French
    Locale('uz'), // Uzbek
  ];

  /// Get current locale
  Locale get currentLocale => _currentLocale;

  /// Get current language code
  String get languageCode => _currentLocale.languageCode;

  /// Change the application locale
  ///
  /// Only accepts locales from the supported locales list.
  /// Notifies listeners after locale change to trigger rebuild.
  void setLocale(Locale newLocale) {
    if (supportedLocales.contains(newLocale) && _currentLocale != newLocale) {
      _currentLocale = newLocale;
      _saveLocale();
      notifyListeners();
    }
  }

  /// Set locale by language code string
  void setLocaleByCode(String languageCode) {
    final newLocale = Locale(languageCode);
    setLocale(newLocale);
  }

  /// Check if a locale is supported
  bool isLocaleSupported(Locale locale) {
    return supportedLocales.contains(locale);
  }

  /// Load locale from persistence
  ///
  /// Called automatically during initialization.
  /// Falls back to English if no saved locale or if saved locale is unsupported.
  Future<void> _loadLocale() async {
    try {
      final savedLocaleCode = _persistenceService.loadLocale();

      if (savedLocaleCode != null) {
        final savedLocale = Locale(savedLocaleCode);
        if (supportedLocales.contains(savedLocale)) {
          _currentLocale = savedLocale;
        } else {
          // Saved locale is not supported, use default
          debugPrint('Saved locale $savedLocaleCode not supported, using default');
        }
      }
    } catch (e) {
      debugPrint('Failed to load locale: $e');
      // Continue with default locale
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  /// Save locale to persistence
  ///
  /// Called automatically after locale changes.
  /// Fails silently to avoid disrupting user experience.
  Future<void> _saveLocale() async {
    try {
      await _persistenceService.saveLocale(_currentLocale.languageCode);
    } catch (e) {
      debugPrint('Failed to save locale: $e');
      // Continue without throwing - persistence failure shouldn't crash app
    }
  }
}
