import 'package:flutter/foundation.dart';
import '../../core/services/persistence_service.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/product.dart';
import 'base_persistent_provider.dart';

/// Recently Viewed Products state management provider with persistence
///
/// Manages recently viewed products including:
/// - List of recently viewed product IDs
/// - Add product to recently viewed
/// - Get recently viewed products from product list
/// - Automatic persistence to local storage
/// - Maximum size limit (configurable via AppConfig)
///
/// Uses ChangeNotifier for state management with Provider pattern
/// Persists recently viewed data using PersistenceService
class RecentlyViewedProvider with ChangeNotifier, PersistentProviderMixin {
  final PersistenceService _persistenceService;
  final List<String> _recentlyViewedIds = [];

  RecentlyViewedProvider(this._persistenceService) {
    _loadRecentlyViewed();
  }

  /// Get immutable list of recently viewed product IDs
  List<String> get recentlyViewedIds => List.unmodifiable(_recentlyViewedIds);

  /// Get count of recently viewed products
  int get count => _recentlyViewedIds.length;

  /// Add a product to recently viewed
  ///
  /// If product already exists, moves it to the front.
  /// Maintains maximum size defined in AppConfig.
  void addProduct(String productId) {
    // Remove if already exists (to move to front)
    _recentlyViewedIds.remove(productId);

    // Add to front
    _recentlyViewedIds.insert(0, productId);

    // Maintain maximum size
    if (_recentlyViewedIds.length > AppConfig.maxRecentlyViewed) {
      _recentlyViewedIds.removeRange(
        AppConfig.maxRecentlyViewed,
        _recentlyViewedIds.length,
      );
    }

    _saveRecentlyViewed();
    notifyListeners();
  }

  /// Clear all recently viewed products
  void clearRecentlyViewed() {
    _recentlyViewedIds.clear();
    _saveRecentlyViewed();
    notifyListeners();
  }

  /// Get recently viewed products from a product list
  ///
  /// Filters and sorts the given product list to return only recently viewed products
  /// in the order they were viewed (most recent first)
  List<Product> getRecentlyViewedProducts(List<Product> allProducts) {
    final productMap = {for (var p in allProducts) p.id: p};
    return _recentlyViewedIds
        .map((id) => productMap[id])
        .where((product) => product != null)
        .cast<Product>()
        .toList();
  }

  /// Load recently viewed from persistence
  ///
  /// Called automatically during initialization.
  /// Handles corrupted data gracefully by starting with empty list.
  Future<void> _loadRecentlyViewed() async {
    try {
      final savedIds = _persistenceService.loadRecentlyViewed();
      _recentlyViewedIds.clear();
      _recentlyViewedIds.addAll(savedIds);
    } catch (e) {
      debugPrint('Failed to load recently viewed: $e');
      // Start with empty list if load fails
      _recentlyViewedIds.clear();
    } finally {
      markAsLoaded();
    }
  }

  /// Save recently viewed to persistence
  ///
  /// Called automatically after recently viewed modifications.
  /// Fails silently to avoid disrupting user experience.
  Future<void> _saveRecentlyViewed() async {
    try {
      await _persistenceService.saveRecentlyViewed(_recentlyViewedIds);
    } catch (e) {
      debugPrint('Failed to save recently viewed: $e');
      // Continue without throwing - persistence failure shouldn't crash app
    }
  }
}
