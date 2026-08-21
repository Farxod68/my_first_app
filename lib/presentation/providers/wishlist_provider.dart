import 'package:flutter/foundation.dart';
import '../../data/models/product.dart';
import '../../core/services/persistence_service.dart';

/// Wishlist/Favorites state management provider with persistence
///
/// Manages user's favorite products including:
/// - Set of favorited product IDs
/// - Toggle favorite status
/// - Check if product is favorited
/// - Get list of favorite products
/// - Automatic persistence to local storage
///
/// Uses ChangeNotifier for state management with Provider pattern
/// Persists wishlist data using PersistenceService
class WishlistProvider with ChangeNotifier {
  final PersistenceService _persistenceService;
  final Set<String> _favoriteProductIds = {};
  bool _isLoaded = false;

  WishlistProvider(this._persistenceService) {
    _loadWishlist();
  }

  /// Check if wishlist data has been loaded from storage
  bool get isLoaded => _isLoaded;

  /// Get immutable set of favorited product IDs
  Set<String> get favoriteProductIds =>
      Set.unmodifiable(_favoriteProductIds);

  /// Get count of favorited products
  int get count => _favoriteProductIds.length;

  /// Check if a product is in favorites by ID
  bool isFavorite(String productId) {
    return _favoriteProductIds.contains(productId);
  }

  /// Toggle favorite status for a product
  ///
  /// If product is already favorited, removes it.
  /// If product is not favorited, adds it.
  void toggleFavorite(String productId) {
    if (_favoriteProductIds.contains(productId)) {
      _favoriteProductIds.remove(productId);
    } else {
      _favoriteProductIds.add(productId);
    }
    _saveWishlist();
    notifyListeners();
  }

  /// Add a product to favorites
  void addToFavorites(String productId) {
    _favoriteProductIds.add(productId);
    _saveWishlist();
    notifyListeners();
  }

  /// Remove a product from favorites
  void removeFromFavorites(String productId) {
    _favoriteProductIds.remove(productId);
    _saveWishlist();
    notifyListeners();
  }

  /// Clear all favorites
  void clearFavorites() {
    _favoriteProductIds.clear();
    _saveWishlist();
    notifyListeners();
  }

  /// Get list of favorite products from a product list
  ///
  /// Filters the given product list to return only favorited products
  List<Product> getFavoriteProducts(List<Product> allProducts) {
    return allProducts
        .where((product) => _favoriteProductIds.contains(product.id))
        .toList();
  }

  /// Load wishlist from persistence
  ///
  /// Called automatically during initialization.
  /// Handles corrupted data gracefully by starting with empty wishlist.
  /// Note: Pre-1.5 wishlist data (stored as product names) is incompatible
  /// and will be ignored. Users will start with a clean wishlist.
  Future<void> _loadWishlist() async {
    try {
      final favoriteIds = _persistenceService.loadWishlist();
      _favoriteProductIds.clear();
      _favoriteProductIds.addAll(favoriteIds);
    } catch (e) {
      debugPrint('Failed to load wishlist: $e');
      // Start with empty wishlist if load fails
      _favoriteProductIds.clear();
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
      await _persistenceService.saveWishlist(_favoriteProductIds.toList());
    } catch (e) {
      debugPrint('Failed to save wishlist: $e');
      // Continue without throwing - persistence failure shouldn't crash app
    }
  }
}
