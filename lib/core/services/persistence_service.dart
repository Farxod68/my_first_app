import 'package:shared_preferences/shared_preferences.dart';

/// Persistence service abstraction for TOPBUY DEALS
///
/// Provides a clean interface for persisting app data using shared_preferences.
/// This abstraction allows the storage implementation to be easily replaced
/// with a backend API, database, or other storage mechanism in the future.
///
/// Currently implements:
/// - String storage (for simple values like locale)
/// - List<String> storage (for cart items, favorites)
/// - Safe get/set operations with error handling
/// - Clear/delete operations
///
/// Usage:
/// ```dart
/// final service = await PersistenceService.getInstance();
/// await service.saveString('locale', 'en');
/// final locale = service.getString('locale');
/// ```
class PersistenceService {
  static PersistenceService? _instance;
  final SharedPreferences _prefs;

  PersistenceService._(this._prefs);

  /// Get singleton instance of persistence service
  ///
  /// Must be called at app startup before accessing any persisted data.
  /// Returns cached instance if already initialized.
  static Future<PersistenceService> getInstance() async {
    if (_instance == null) {
      final prefs = await SharedPreferences.getInstance();
      _instance = PersistenceService._(prefs);
    }
    return _instance!;
  }

  // Keys for persisted data
  static const String _cartKey = 'cart_items';
  static const String _wishlistKey = 'wishlist_favorites';
  static const String _localeKey = 'locale_language';
  static const String _recentlyViewedKey = 'recently_viewed';
  static const String _recentSearchesKey = 'recent_searches';

  /// Save a string value
  ///
  /// Returns true if save was successful, false otherwise
  Future<bool> saveString(String key, String value) async {
    try {
      return await _prefs.setString(key, value);
    } catch (e) {
      // Log error in production, for now just return false
      return false;
    }
  }

  /// Get a string value
  ///
  /// Returns the value if found, null otherwise
  String? getString(String key) {
    try {
      return _prefs.getString(key);
    } catch (e) {
      return null;
    }
  }

  /// Save a list of strings
  ///
  /// Returns true if save was successful, false otherwise
  Future<bool> saveStringList(String key, List<String> values) async {
    try {
      return await _prefs.setStringList(key, values);
    } catch (e) {
      return false;
    }
  }

  /// Get a list of strings
  ///
  /// Returns the list if found, empty list otherwise
  List<String> getStringList(String key) {
    try {
      return _prefs.getStringList(key) ?? [];
    } catch (e) {
      return [];
    }
  }

  /// Remove a key from storage
  Future<bool> remove(String key) async {
    try {
      return await _prefs.remove(key);
    } catch (e) {
      return false;
    }
  }

  /// Clear all persisted data
  Future<bool> clearAll() async {
    try {
      return await _prefs.clear();
    } catch (e) {
      return false;
    }
  }

  // Cart-specific methods

  /// Save cart items as JSON strings
  Future<bool> saveCart(List<String> cartItemsJson) async {
    return await saveStringList(_cartKey, cartItemsJson);
  }

  /// Load cart items as JSON strings
  List<String> loadCart() {
    return getStringList(_cartKey);
  }

  /// Clear cart from storage
  Future<bool> clearCart() async {
    return await remove(_cartKey);
  }

  // Wishlist-specific methods

  /// Save wishlist/favorite product names
  Future<bool> saveWishlist(List<String> favoriteNames) async {
    return await saveStringList(_wishlistKey, favoriteNames);
  }

  /// Load wishlist/favorite product names
  List<String> loadWishlist() {
    return getStringList(_wishlistKey);
  }

  /// Clear wishlist from storage
  Future<bool> clearWishlist() async {
    return await remove(_wishlistKey);
  }

  // Locale-specific methods

  /// Save selected locale/language code
  Future<bool> saveLocale(String languageCode) async {
    return await saveString(_localeKey, languageCode);
  }

  /// Load selected locale/language code
  String? loadLocale() {
    return getString(_localeKey);
  }

  /// Clear locale preference from storage
  Future<bool> clearLocale() async {
    return await remove(_localeKey);
  }

  // Recently Viewed-specific methods

  /// Save recently viewed product IDs
  Future<bool> saveRecentlyViewed(List<String> productIds) async {
    return await saveStringList(_recentlyViewedKey, productIds);
  }

  /// Load recently viewed product IDs
  List<String> loadRecentlyViewed() {
    return getStringList(_recentlyViewedKey);
  }

  /// Clear recently viewed from storage
  Future<bool> clearRecentlyViewed() async {
    return await remove(_recentlyViewedKey);
  }

  // Recent Searches-specific methods

  /// Save recent search queries
  Future<bool> saveRecentSearches(List<String> searches) async {
    return await saveStringList(_recentSearchesKey, searches);
  }

  /// Load recent search queries
  List<String> loadRecentSearches() {
    return getStringList(_recentSearchesKey);
  }

  /// Clear recent searches from storage
  Future<bool> clearRecentSearches() async {
    return await remove(_recentSearchesKey);
  }
}
