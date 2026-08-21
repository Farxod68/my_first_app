import 'package:flutter/foundation.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/persistence_service.dart';
import '../../data/models/product.dart';
import '../../data/models/filter_models.dart';

/// Search and Discovery state management provider
///
/// Manages:
/// - Search queries with normalization
/// - Product filtering (category, brand, price, rating, etc.)
/// - Product sorting (relevance, price, rating, etc.)
/// - Recent searches with persistence
/// - Search suggestions
/// - Result computation
///
/// Uses ChangeNotifier for state management with Provider pattern
class SearchProvider with ChangeNotifier {
  final PersistenceService _persistenceService;

  SearchQuery _query = SearchQuery('');
  ProductFilters _filters = const ProductFilters();
  ProductSort _sortBy = ProductSort.relevance;
  List<String> _recentSearches = [];
  bool _isLoaded = false;

  SearchProvider(this._persistenceService) {
    _loadRecentSearches();
  }

  /// Check if recent searches have been loaded
  bool get isLoaded => _isLoaded;

  /// Current search query
  SearchQuery get query => _query;

  /// Current filters
  ProductFilters get filters => _filters;

  /// Current sort option
  ProductSort get sortBy => _sortBy;

  /// Recent searches
  List<String> get recentSearches => List.unmodifiable(_recentSearches);

  /// Check if search is active
  bool get hasSearch => _query.isNotEmpty;

  /// Check if filters are active
  bool get hasFilters => _filters.hasActiveFilters;

  /// Check if any discovery criteria is active
  bool get hasActiveDiscovery => hasSearch || hasFilters;

  /// Set search query
  void setQuery(String query) {
    _query = SearchQuery(query);
    notifyListeners();
  }

  /// Clear search query
  void clearQuery() {
    _query = SearchQuery('');
    notifyListeners();
  }

  /// Update filters
  void setFilters(ProductFilters filters) {
    _filters = filters;
    notifyListeners();
  }

  /// Clear all filters
  void clearFilters() {
    _filters = const ProductFilters();
    notifyListeners();
  }

  /// Set category filter
  void setCategoryFilter(String? category) {
    _filters = _filters.copyWith(category: () => category);
    notifyListeners();
  }

  /// Set brand filter
  void setBrandFilter(String? brand) {
    _filters = _filters.copyWith(brand: () => brand);
    notifyListeners();
  }

  /// Set price range filter
  void setPriceRangeFilter(PriceRange priceRange) {
    _filters = _filters.copyWith(priceRange: priceRange);
    notifyListeners();
  }

  /// Set rating filter
  void setRatingFilter(double? minRating) {
    _filters = _filters.copyWith(minRating: () => minRating);
    notifyListeners();
  }

  /// Set discount filter
  void setDiscountFilter(int? minDiscount) {
    _filters = _filters.copyWith(minDiscount: () => minDiscount);
    notifyListeners();
  }

  /// Set in stock only filter
  void setInStockOnlyFilter(bool? inStockOnly) {
    _filters = _filters.copyWith(inStockOnly: () => inStockOnly);
    notifyListeners();
  }

  /// Set seller filter
  void setSellerFilter(String? seller) {
    _filters = _filters.copyWith(seller: () => seller);
    notifyListeners();
  }

  /// Set deals only filter
  void setDealsOnlyFilter(bool? dealsOnly) {
    _filters = _filters.copyWith(dealsOnly: () => dealsOnly);
    notifyListeners();
  }

  /// Set sort option
  void setSortBy(ProductSort sortBy) {
    _sortBy = sortBy;
    notifyListeners();
  }

  /// Add to recent searches
  void addRecentSearch(String query) {
    if (query.trim().isEmpty) return;

    // Remove if already exists
    _recentSearches.remove(query);

    // Add to beginning
    _recentSearches.insert(0, query);

    // Maintain maximum size
    if (_recentSearches.length > AppConfig.maxSearchHistory) {
      _recentSearches = _recentSearches.sublist(0, AppConfig.maxSearchHistory);
    }

    _saveRecentSearches();
    notifyListeners();
  }

  /// Remove from recent searches
  void removeRecentSearch(String query) {
    _recentSearches.remove(query);
    _saveRecentSearches();
    notifyListeners();
  }

  /// Clear all recent searches
  void clearRecentSearches() {
    _recentSearches.clear();
    _saveRecentSearches();
    notifyListeners();
  }

  /// Get search suggestions based on products and recent searches
  List<String> getSuggestions(List<Product> allProducts, {int maxSuggestions = 10}) {
    if (_query.isEmpty) {
      // Return recent searches
      return _recentSearches.take(maxSuggestions).toList();
    }

    final suggestions = <String>{};
    final queryNorm = _query.normalized;

    // Add matching product names
    for (final product in allProducts) {
      if (product.name.toLowerCase().contains(queryNorm)) {
        suggestions.add(product.name);
      }
    }

    // Add matching brands
    final brands = allProducts
        .where((p) => p.brand != null && p.brand!.toLowerCase().contains(queryNorm))
        .map((p) => p.brand!)
        .toSet();
    suggestions.addAll(brands);

    // Add matching categories (would need localization for display)
    final categories = allProducts
        .where((p) => p.category.toLowerCase().contains(queryNorm))
        .map((p) => p.category)
        .toSet();
    suggestions.addAll(categories);

    // Add matching recent searches
    for (final recent in _recentSearches) {
      if (recent.toLowerCase().contains(queryNorm)) {
        suggestions.add(recent);
      }
    }

    return suggestions.take(maxSuggestions).toList();
  }

  /// Search and filter products
  List<Product> searchAndFilter(List<Product> allProducts) {
    var results = allProducts;

    // Apply search
    if (_query.isNotEmpty) {
      results = _searchProducts(results);
    }

    // Apply filters
    results = _filterProducts(results);

    // Apply sorting
    results = _sortProducts(results);

    return results;
  }

  /// Search products by query
  List<Product> _searchProducts(List<Product> products) {
    final queryNorm = _query.normalized;
    if (queryNorm.isEmpty) return products;

    // Score each product for relevance
    final scored = <MapEntry<Product, int>>[];

    for (final product in products) {
      int score = 0;
      final nameNorm = product.name.toLowerCase();
      final brandNorm = product.brand?.toLowerCase() ?? '';
      final categoryNorm = product.category.toLowerCase();

      // Exact match (highest priority)
      if (nameNorm == queryNorm) {
        score += 1000;
      }
      // Title starts with query
      else if (nameNorm.startsWith(queryNorm)) {
        score += 500;
      }
      // Title contains query
      else if (nameNorm.contains(queryNorm)) {
        score += 250;
      }

      // Brand match
      if (brandNorm.contains(queryNorm)) {
        score += 200;
      }

      // Category match
      if (categoryNorm.contains(queryNorm)) {
        score += 100;
      }

      // Subtitle match
      if (product.subtitle != null && product.subtitle!.toLowerCase().contains(queryNorm)) {
        score += 50;
      }

      // Description match (lower priority)
      if (product.description != null && product.description!.toLowerCase().contains(queryNorm)) {
        score += 25;
      }

      // Only include products with some relevance
      if (score > 0) {
        scored.add(MapEntry(product, score));
      }
    }

    // Sort by relevance score
    scored.sort((a, b) => b.value.compareTo(a.value));

    return scored.map((e) => e.key).toList();
  }

  /// Filter products
  List<Product> _filterProducts(List<Product> products) {
    return products.where((product) {
      // Category filter
      if (_filters.category != null && product.category != _filters.category) {
        return false;
      }

      // Brand filter
      if (_filters.brand != null && product.brand != _filters.brand) {
        return false;
      }

      // Price range filter
      if (!_filters.priceRange.matches(product.price)) {
        return false;
      }

      // Rating filter
      if (_filters.minRating != null && product.rating < _filters.minRating!) {
        return false;
      }

      // Discount filter
      if (_filters.minDiscount != null && product.discount < _filters.minDiscount!) {
        return false;
      }

      // In stock only filter
      if (_filters.inStockOnly == true && !product.isInStock) {
        return false;
      }

      // Seller filter
      if (_filters.seller != null && product.seller != _filters.seller) {
        return false;
      }

      // Deals only filter (products with discount)
      if (_filters.dealsOnly == true && product.discount <= 0) {
        return false;
      }

      return true;
    }).toList();
  }

  /// Sort products
  List<Product> _sortProducts(List<Product> products) {
    final sorted = List<Product>.from(products);

    switch (_sortBy) {
      case ProductSort.relevance:
        // Already sorted by relevance in search, or natural order if no search
        break;

      case ProductSort.priceLowToHigh:
        sorted.sort((a, b) => a.price.compareTo(b.price));
        break;

      case ProductSort.priceHighToLow:
        sorted.sort((a, b) => b.price.compareTo(a.price));
        break;

      case ProductSort.rating:
        sorted.sort((a, b) => b.rating.compareTo(a.rating));
        break;

      case ProductSort.newest:
        // Would use createdAt if available, for now use product order
        // Reverse to show "newest" first (assuming products added in order)
        sorted.sort((a, b) => products.indexOf(b).compareTo(products.indexOf(a)));
        break;

      case ProductSort.discount:
        sorted.sort((a, b) => b.discount.compareTo(a.discount));
        break;

      case ProductSort.popularity:
        sorted.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
        break;
    }

    return sorted;
  }

  /// Load recent searches from persistence
  Future<void> _loadRecentSearches() async {
    try {
      final searches = _persistenceService.loadRecentSearches();
      _recentSearches = searches;
    } catch (e) {
      debugPrint('Failed to load recent searches: $e');
      _recentSearches = [];
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  /// Save recent searches to persistence
  Future<void> _saveRecentSearches() async {
    try {
      await _persistenceService.saveRecentSearches(_recentSearches);
    } catch (e) {
      debugPrint('Failed to save recent searches: $e');
    }
  }
}
