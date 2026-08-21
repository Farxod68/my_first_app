/// Filter and sorting models for TOPBUY DEALS search and discovery
///
/// Contains data models for:
/// - Product filters (category, brand, price, rating, discount, etc.)
/// - Sort options
/// - Price range
/// - Search query
library;


/// Price range filter
class PriceRange {
  final double? min;
  final double? max;

  const PriceRange({this.min, this.max});

  bool matches(double price) {
    if (min != null && price < min!) return false;
    if (max != null && price > max!) return false;
    return true;
  }

  bool get hasFilter => min != null || max != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PriceRange &&
          runtimeType == other.runtimeType &&
          min == other.min &&
          max == other.max;

  @override
  int get hashCode => min.hashCode ^ max.hashCode;

  PriceRange copyWith({double? Function()? min, double? Function()? max}) {
    return PriceRange(
      min: min != null ? min() : this.min,
      max: max != null ? max() : this.max,
    );
  }
}

/// Product filters container
class ProductFilters {
  final String? category;
  final String? brand;
  final PriceRange priceRange;
  final double? minRating;
  final int? minDiscount;
  final bool? inStockOnly;
  final String? seller;
  final bool? dealsOnly;

  const ProductFilters({
    this.category,
    this.brand,
    this.priceRange = const PriceRange(),
    this.minRating,
    this.minDiscount,
    this.inStockOnly,
    this.seller,
    this.dealsOnly,
  });

  /// Check if any filters are active
  bool get hasActiveFilters =>
      category != null ||
      brand != null ||
      priceRange.hasFilter ||
      minRating != null ||
      minDiscount != null ||
      inStockOnly == true ||
      seller != null ||
      dealsOnly == true;

  /// Count of active filters
  int get activeFilterCount {
    int count = 0;
    if (category != null) count++;
    if (brand != null) count++;
    if (priceRange.hasFilter) count++;
    if (minRating != null) count++;
    if (minDiscount != null) count++;
    if (inStockOnly == true) count++;
    if (seller != null) count++;
    if (dealsOnly == true) count++;
    return count;
  }

  /// Clear all filters
  ProductFilters clearAll() {
    return const ProductFilters();
  }

  ProductFilters copyWith({
    String? Function()? category,
    String? Function()? brand,
    PriceRange? priceRange,
    double? Function()? minRating,
    int? Function()? minDiscount,
    bool? Function()? inStockOnly,
    String? Function()? seller,
    bool? Function()? dealsOnly,
  }) {
    return ProductFilters(
      category: category != null ? category() : this.category,
      brand: brand != null ? brand() : this.brand,
      priceRange: priceRange ?? this.priceRange,
      minRating: minRating != null ? minRating() : this.minRating,
      minDiscount: minDiscount != null ? minDiscount() : this.minDiscount,
      inStockOnly: inStockOnly != null ? inStockOnly() : this.inStockOnly,
      seller: seller != null ? seller() : this.seller,
      dealsOnly: dealsOnly != null ? dealsOnly() : this.dealsOnly,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductFilters &&
          runtimeType == other.runtimeType &&
          category == other.category &&
          brand == other.brand &&
          priceRange == other.priceRange &&
          minRating == other.minRating &&
          minDiscount == other.minDiscount &&
          inStockOnly == other.inStockOnly &&
          seller == other.seller &&
          dealsOnly == other.dealsOnly;

  @override
  int get hashCode =>
      category.hashCode ^
      brand.hashCode ^
      priceRange.hashCode ^
      minRating.hashCode ^
      minDiscount.hashCode ^
      inStockOnly.hashCode ^
      seller.hashCode ^
      dealsOnly.hashCode;
}

/// Search query with normalization
class SearchQuery {
  final String raw;
  final String normalized;

  SearchQuery(this.raw)
      : normalized = _normalize(raw);

  static String _normalize(String query) {
    return query
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
        .replaceAll(RegExp(r'[^\w\s]'), ''); // Remove punctuation
  }

  bool get isEmpty => raw.isEmpty;
  bool get isNotEmpty => raw.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchQuery &&
          runtimeType == other.runtimeType &&
          raw == other.raw;

  @override
  int get hashCode => raw.hashCode;
}
