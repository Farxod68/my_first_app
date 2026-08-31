/// Application-wide constants for TOPBUY DEALS
///
/// Contains:
/// - Category keys
/// - Deal types and badges
/// - Sort options
/// - Filter ranges
/// - Default values and limits
library;

/// Display names for supported languages, keyed by language code.
///
/// Native-language labels shown in language-picker UI (e.g. "Français" for
/// 'fr'). Kept separate from `LocaleProvider.supportedLocales` - that list
/// holds the `Locale` objects the app actually supports; this map only
/// holds the human-readable strings a picker displays for each of them.
class LanguageNames {
  static const Map<String, String> byCode = {
    'en': 'English',
    'es': 'Español',
    'fr': 'Français',
    'uz': "O'zbekcha",
  };
}

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

/// Deal classification thresholds
class DealThresholds {
  /// Minimum discount percentage for big discount classification (30%)
  static const int bigDiscountMinPercent = 30;

  /// Minimum discount percentage for good deal classification (10%)
  static const int goodDealMinPercent = 10;

  /// Discount threshold for recommendations (20%)
  static const int recommendedDiscountPercent = 20;

  /// Discount threshold for urgent/high-priority deals (40%)
  static const int urgentDiscountPercent = 40;
}

/// Quality thresholds for recommendations and filtering
class QualityThresholds {
  /// Minimum rating for high-quality product classification (4.5 stars)
  static const double highRatingThreshold = 4.5;
}

/// Scoring weights for deal ranking algorithm
class ScoringWeights {
  /// Maximum score contribution from discount percentage (50 points)
  static const int maxDiscountScore = 50;

  /// Multiplier for rating contribution (rating × 5)
  static const int ratingMultiplier = 5;

  /// Normalizer for review count popularity score (reviewCount / 200)
  static const int reviewCountNormalizer = 200;

  /// Maximum score contribution from popularity (15 points)
  static const int maxPopularityScore = 15;

  /// Score bonus for in-stock products (10 points)
  static const int inStockScore = 10;

  /// Score bonus for low-stock products (5 points)
  static const int lowStockScore = 5;
}

/// Priority scores for different deal types
class DealTypePriority {
  /// Flash sale priority score (20 points - highest)
  static const int flashSale = 20;

  /// Limited time offer priority score (18 points)
  static const int limitedTime = 18;

  /// Price drop priority score (16 points)
  static const int priceDrop = 16;

  /// Big discount priority score (14 points)
  static const int bigDiscount = 14;

  /// Trending product priority score (12 points)
  static const int trending = 12;

  /// Best seller priority score (10 points)
  static const int bestSeller = 10;

  /// New arrival priority score (8 points)
  static const int newArrival = 8;

  /// Good deal priority score (6 points)
  static const int goodDeal = 6;
}

/// Recommendation scoring weights
class RecommendationWeights {
  /// Score for matching recently viewed category (50 points)
  static const int recentCategoryScore = 50;

  /// Score for matching wishlist category (40 points)
  static const int wishlistCategoryScore = 40;

  /// Score for matching cart category (30 points)
  static const int cartCategoryScore = 30;

  /// Bonus for high-rated products (20 points)
  static const int highRatingBonus = 20;

  /// Bonus for discounted products (15 points)
  static const int discountBonus = 15;

  /// Bonus for best seller badge (10 points)
  static const int bestSellerBonus = 10;

  /// Bonus for in-stock products (5 points)
  static const int inStockBonus = 5;
}

/// Display limits for home page sections and lists
class DisplayLimits {
  /// Number of products to show in "Biggest Discounts" section
  static const int biggestDiscountsDisplayCount = 10;

  /// Number of products to show in "Today's Deals" section
  static const int todaysDealsDisplayCount = 12;

  /// Default number of recommended products to return
  static const int defaultRecommendationCount = 10;
}
