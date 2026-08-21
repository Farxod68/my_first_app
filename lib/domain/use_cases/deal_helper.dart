/// Deal classification and ranking utilities for TOPBUY DEALS
///
/// Provides deterministic logic for:
/// - Deal type classification
/// - Deal ranking by priority/quality
/// - Deal filtering by type
/// - Savings calculations
///
/// No machine learning - pure business logic that can be
/// replaced by backend recommendations in the future
library;

import '../../data/models/product.dart';
import '../../core/constants/app_constants.dart';

/// Deal type classification
enum DealType {
  flashSale,      // Flash Sale badge
  limitedTime,    // Limited Time badge
  priceDrop,      // Price Drop badge
  bestSeller,     // Best Seller badge
  trending,       // Trending badge
  newArrival,     // New Arrival badge
  bigDiscount,    // High discount percentage (30%+)
  goodDeal,       // Moderate discount (10-29%)
}

/// Deal helper class with static methods
class DealHelper {
  // Prevent instantiation
  DealHelper._();

  /// Get primary deal type for a product
  static DealType? getPrimaryDealType(Product product) {
    // Check badges first (explicit deal markers)
    if (product.badges.contains(DealBadges.flashSale)) {
      return DealType.flashSale;
    }
    if (product.badges.contains(DealBadges.limitedTime)) {
      return DealType.limitedTime;
    }
    if (product.badges.contains(DealBadges.priceDrop)) {
      return DealType.priceDrop;
    }
    if (product.badges.contains(DealBadges.bestSeller)) {
      return DealType.bestSeller;
    }
    if (product.badges.contains(DealBadges.trending)) {
      return DealType.trending;
    }
    if (product.badges.contains(DealBadges.newArrival)) {
      return DealType.newArrival;
    }

    // Classify by discount percentage
    if (product.discount >= DealThresholds.bigDiscountMinPercent) {
      return DealType.bigDiscount;
    }
    if (product.discount >= DealThresholds.goodDealMinPercent) {
      return DealType.goodDeal;
    }

    return null; // Not a deal
  }

  /// Check if product has any deal
  static bool hasDeal(Product product) {
    return product.discount > 0 || product.badges.isNotEmpty;
  }

  /// Calculate savings amount in USD
  static double getSavings(Product product) {
    return product.oldPrice - product.price;
  }

  /// Get deal score for ranking (higher is better)
  ///
  /// Scoring factors:
  /// - Discount percentage (0-50 points)
  /// - Rating (0-25 points)
  /// - Review count / popularity (0-15 points)
  /// - Stock availability (0-10 points)
  /// - Deal type priority (0-20 points)
  static int getDealScore(Product product) {
    int score = 0;

    // Discount contribution (0-50 points, capped at 50% discount)
    score += (product.discount * 1.0).clamp(0, ScoringWeights.maxDiscountScore).toInt();

    // Rating contribution (0-25 points)
    score += (product.rating * ScoringWeights.ratingMultiplier).toInt();

    // Popularity contribution (0-15 points, normalized by review count)
    final popularityScore = (product.reviewCount / ScoringWeights.reviewCountNormalizer)
        .clamp(0, ScoringWeights.maxPopularityScore);
    score += popularityScore.toInt();

    // Stock availability (0-10 points)
    if (product.isInStock) {
      score += ScoringWeights.inStockScore;
    } else if (product.isLowStock) {
      score += ScoringWeights.lowStockScore;
    }

    // Deal type priority (0-20 points)
    final dealType = getPrimaryDealType(product);
    if (dealType != null) {
      score += _getDealTypePriority(dealType);
    }

    return score;
  }

  /// Get priority score for deal type
  static int _getDealTypePriority(DealType dealType) {
    switch (dealType) {
      case DealType.flashSale:
        return DealTypePriority.flashSale;
      case DealType.limitedTime:
        return DealTypePriority.limitedTime;
      case DealType.priceDrop:
        return DealTypePriority.priceDrop;
      case DealType.bigDiscount:
        return DealTypePriority.bigDiscount;
      case DealType.trending:
        return DealTypePriority.trending;
      case DealType.bestSeller:
        return DealTypePriority.bestSeller;
      case DealType.newArrival:
        return DealTypePriority.newArrival;
      case DealType.goodDeal:
        return DealTypePriority.goodDeal;
    }
  }

  /// Rank deals by score (highest first)
  static List<Product> rankDeals(List<Product> products) {
    final deals = products.where((p) => hasDeal(p)).toList();
    deals.sort((a, b) => getDealScore(b).compareTo(getDealScore(a)));
    return deals;
  }

  /// Get products by deal type
  static List<Product> getProductsByDealType(
    List<Product> products,
    DealType dealType,
  ) {
    return products
        .where((p) => getPrimaryDealType(p) == dealType)
        .toList();
  }

  /// Get today's deals (any product with a discount)
  static List<Product> getTodaysDeals(List<Product> products) {
    return products.where((p) => p.discount > 0).toList();
  }

  /// Get biggest discounts (sorted by discount percentage)
  static List<Product> getBiggestDiscounts(List<Product> products) {
    final deals = getTodaysDeals(products);
    deals.sort((a, b) => b.discount.compareTo(a.discount));
    return deals;
  }

  /// Get flash deals (products with Flash Sale badge)
  static List<Product> getFlashDeals(List<Product> products) {
    return products
        .where((p) => p.badges.contains(DealBadges.flashSale))
        .toList();
  }

  /// Get trending deals (products with Trending badge)
  static List<Product> getTrendingDeals(List<Product> products) {
    return products
        .where((p) => p.badges.contains(DealBadges.trending))
        .toList();
  }

  /// Get price drops (products with Price Drop badge)
  static List<Product> getPriceDrops(List<Product> products) {
    return products
        .where((p) => p.badges.contains(DealBadges.priceDrop))
        .toList();
  }

  /// Get best sellers (products with Best Seller badge)
  static List<Product> getBestSellers(List<Product> products) {
    return products
        .where((p) => p.badges.contains(DealBadges.bestSeller))
        .toList();
  }

  /// Get limited time deals (products with Limited Time badge)
  static List<Product> getLimitedTimeDeals(List<Product> products) {
    return products
        .where((p) => p.badges.contains(DealBadges.limitedTime))
        .toList();
  }

  /// Get deals by category
  static List<Product> getDealsByCategory(
    List<Product> products,
    String category,
  ) {
    return products
        .where((p) => p.category == category && p.discount > 0)
        .toList();
  }

  /// Get recommended products based on user activity
  ///
  /// Deterministic recommendations based on:
  /// - Recently viewed products (same category)
  /// - Wishlist items (similar products)
  /// - Cart items (complementary products)
  ///
  /// Returns products sorted by relevance score
  static List<Product> getRecommendedProducts(
    List<Product> allProducts, {
    List<String> recentlyViewedIds = const [],
    List<String> wishlistNames = const [],
    List<Product> cartItems = const [],
    int maxResults = DisplayLimits.defaultRecommendationCount,
  }) {
    final recommendations = <Product, int>{};

    // Get categories from recently viewed
    final recentCategories = allProducts
        .where((p) => recentlyViewedIds.contains(p.id))
        .map((p) => p.category)
        .toSet();

    // Get categories from wishlist
    final wishlistCategories = allProducts
        .where((p) => wishlistNames.contains(p.name))
        .map((p) => p.category)
        .toSet();

    // Get categories from cart
    final cartCategories = cartItems.map((p) => p.category).toSet();

    // Score each product
    for (final product in allProducts) {
      // Skip if already in wishlist, cart, or recently viewed
      if (wishlistNames.contains(product.name) ||
          cartItems.any((c) => c.id == product.id) ||
          recentlyViewedIds.contains(product.id)) {
        continue;
      }

      int score = 0;

      // Category match (highest priority)
      if (recentCategories.contains(product.category)) {
        score += RecommendationWeights.recentCategoryScore;
      }
      if (wishlistCategories.contains(product.category)) {
        score += RecommendationWeights.wishlistCategoryScore;
      }
      if (cartCategories.contains(product.category)) {
        score += RecommendationWeights.cartCategoryScore;
      }

      // Quality signals
      if (product.rating >= QualityThresholds.highRatingThreshold) {
        score += RecommendationWeights.highRatingBonus;
      }
      if (product.discount >= DealThresholds.recommendedDiscountPercent) {
        score += RecommendationWeights.discountBonus;
      }
      if (product.badges.contains(DealBadges.bestSeller)) {
        score += RecommendationWeights.bestSellerBonus;
      }
      if (product.isInStock) {
        score += RecommendationWeights.inStockBonus;
      }

      if (score > 0) {
        recommendations[product] = score;
      }
    }

    // Sort by score and return top N
    final sorted = recommendations.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(maxResults).map((e) => e.key).toList();
  }

  /// Format savings amount with currency
  static String formatSavings(double savings, String currencySymbol) {
    return '$currencySymbol${savings.toStringAsFixed(2)}';
  }

  /// Get deal urgency level (for UI indicators)
  static DealUrgency getDealUrgency(Product product) {
    // Check stock first
    if (product.isOutOfStock) {
      return DealUrgency.expired;
    }
    if (product.isLowStock) {
      return DealUrgency.high;
    }

    // Check deal type
    final dealType = getPrimaryDealType(product);
    if (dealType == DealType.flashSale || dealType == DealType.limitedTime) {
      return DealUrgency.high;
    }

    // Check discount
    if (product.discount >= DealThresholds.urgentDiscountPercent) {
      return DealUrgency.medium;
    }

    return DealUrgency.low;
  }
}

/// Deal urgency indicator
enum DealUrgency {
  low,      // Regular deal
  medium,   // Good deal, moderate urgency
  high,     // Flash sale, limited time, low stock
  expired,  // Out of stock
}
