import 'package:flutter/foundation.dart';
import '../../data/models/product.dart';
import '../../core/services/persistence_service.dart';

/// Wishlist/Favorites state management provider with persistence
///
/// Manages user's favorite products including:
/// - Set of favorited product names
/// - Toggle favorite status
/// - Check if product is favorited
/// - Get list of favorite products
/// - Automatic persistence to local storage
///
/// Uses ChangeNotifier for state management with Provider pattern
/// Persists wishlist data using PersistenceService
class WishlistProvider with ChangeNotifier {
  final PersistenceService _persistenceService;
  final Set<String> _favoriteProductNames = {};
  bool _isLoaded = false;

  WishlistProvider(this._persistenceService) {
    _loadWishlist();
  }

  /// Check if wishlist data has been loaded from storage
  bool get isLoaded => _isLoaded;

  /// Get immutable set of favorited product names
  Set<String> get favoriteProductNames =>
      Set.unmodifiable(_favoriteProductNames);

  /// Get count of favorited products
  int get count => _favoriteProductNames.length;

  /// Check if a product is in favorites by name
  /// Note: Currently using name as identifier. In production, use product ID.
  bool isFavorite(String productName) {
    return _favoriteProductNames.contains(productName);
  }

  /// Toggle favorite status for a product
  ///
  /// If product is already favorited, removes it.
  /// If product is not favorited, adds it.
  void toggleFavorite(String productName) {
    if (_favoriteProductNames.contains(productName)) {
      _favoriteProductNames.remove(productName);
    } else {
      _favoriteProductNames.add(productName);
    }
    _saveWishlist();
    notifyListeners();
  }

  /// Add a product to favorites
  void addToFavorites(String productName) {
    _favoriteProductNames.add(productName);
    _saveWishlist();
    notifyListeners();
  }

  /// Remove a product from favorites
  void removeFromFavorites(String productName) {
    _favoriteProductNames.remove(productName);
    _saveWishlist();
    notifyListeners();
  }

  /// Clear all favorites
  void clearFavorites() {
    _favoriteProductNames.clear();
    _saveWishlist();
    notifyListeners();
  }

  /// Get list of favorite products from a product list
  ///
  /// Filters the given product list to return only favorited products
  List<Product> getFavoriteProducts(List<Product> allProducts) {
    return allProducts
        .where((product) => _favoriteProductNames.contains(product.name))
        .toList();
  }

  /// Load wishlist from persistence
  ///
  /// Called automatically during initialization.
  /// Handles corrupted data gracefully by starting with empty wishlist.
  Future<void> _loadWishlist() async {
    try {
      final favoriteNames = _persistenceService.loadWishlist();
      _favoriteProductNames.clear();
      _favoriteProductNames.addAll(favoriteNames);
    } catch (e) {
      debugPrint('Failed to load wishlist: $e');
      // Start with empty wishlist if load fails
      _favoriteProductNames.clear();
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  /// Save wishlist to persistence
  ///
  /// Called automatically after wishlist modifications.
  /// Fails silently to avoid disrupting user experience.
  Future<void> _saveWishlist() async {
    try {
      await _persistenceService.saveWishlist(_favoriteProductNames.toList());
    } catch (e) {
      debugPrint('Failed to save wishlist: $e');
      // Continue without throwing - persistence failure shouldn't crash app
    }
  }
}
