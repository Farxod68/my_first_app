/// Application-wide constants for TOPBUY DEALS
///
/// Contains:
/// - Category keys
/// - Deal types and badges
/// - Sort options
/// - Filter ranges
/// - Default values and limits
library;

/// Category Keys
class CategoryKeys {
  static const String electronics = 'electronics';
  static const String clothing = 'clothing';
  static const String accessories = 'accessories';
  static const String homeGoods = 'homeGoods';
  static const String sports = 'sports';
  static const String cosmetics = 'cosmetics';

  static const List<String> all = [
    electronics,
    clothing,
    accessories,
    homeGoods,
    sports,
    cosmetics,
  ];
}

/// Deal Badge Types
class DealBadges {
  static const String flashSale = 'Flash Sale';
  static const String limitedTime = 'Limited Time';
  static const String priceDrop = 'Price Drop';
  static const String bestSeller = 'Best Seller';
  static const String trending = 'Trending';
  static const String newArrival = 'New Arrival';
  static const String freeShipping = 'Free Shipping';
  static const String lowStock = 'Low Stock';
  static const String outOfStock = 'Out of Stock';
}

/// Product Sort Options
enum ProductSort {
  relevance,
  priceLowToHigh,
  priceHighToLow,
  rating,
  newest,
  discount,
  popularity,
}

/// Stock Status
enum StockStatus {
  inStock,
  lowStock,
  outOfStock,
}

/// App Configuration Constants
class AppConfig {
  /// Maximum number of products in cart
  static const int maxCartItems = 99;

  /// Maximum number of wishlist items
  static const int maxWishlistItems = 100;

  /// Maximum number of recently viewed products
  static const int maxRecentlyViewed = 20;

  /// Maximum number of search history items
  static const int maxSearchHistory = 10;

  /// Low stock threshold
  static const int lowStockThreshold = 10;

  /// Minimum rating value
  static const double minRating = 0.0;

  /// Maximum rating value
  static const double maxRating = 5.0;

  /// Default product image placeholder
  static const String defaultProductImage = 'assets/images/product_placeholder.png';
}

/// Price Filter Ranges (in USD)
class PriceRanges {
  static const List<Map<String, dynamic>> ranges = [
    {'label': 'Under \$25', 'min': 0.0, 'max': 25.0},
    {'label': '\$25 to \$50', 'min': 25.0, 'max': 50.0},
    {'label': '\$50 to \$100', 'min': 50.0, 'max': 100.0},
    {'label': '\$100 to \$200', 'min': 100.0, 'max': 200.0},
    {'label': '\$200 & Above', 'min': 200.0, 'max': double.infinity},
  ];
}

/// Rating Filter Options
class RatingFilters {
  static const double fourStarsAndUp = 4.0;
  static const double threeStarsAndUp = 3.0;
  static const double twoStarsAndUp = 2.0;
  static const double oneStarAndUp = 1.0;
}
