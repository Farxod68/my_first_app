import 'package:flutter/material.dart';

/// Fallback icon for a product sourced from Supabase.
///
/// Supabase's `products` table has no IconData column - IconData is a
/// Flutter-only type with no server-side representation (see
/// supabase/migrations/002_product_catalog.sql). Until real product images
/// replace icon rendering, a product loaded via [Product.fromSupabase] gets
/// a per-category icon instead, matching the icons already shown in
/// CategoriesTab (lib/presentation/screens/home/tabs/categories_tab.dart).
const Map<String, IconData> _categoryFallbackIcons = {
  'electronics': Icons.phone_android,
  'clothing': Icons.checkroom,
  'accessories': Icons.watch,
  'homeGoods': Icons.home,
  'sports': Icons.sports_soccer,
  'cosmetics': Icons.face,
};

/// Product model for TOPBUY DEALS marketplace
///
/// Represents a product with comprehensive information including:
/// - Basic info: ID, name, subtitle, description
/// - Pricing: current price, original price, automatic discount calculation
/// - Category and brand information
/// - Rating and reviews
/// - Stock and availability
/// - Images and visual representation
/// - Product specifications and features
/// - Deal badges and seller information
class Product {
  // Core fields (preserved from Phase 1-4A)
  final String name;
  final double price;
  final double oldPrice;
  final String category;
  final IconData icon;

  // Extended fields (Phase 4B)
  final String id;
  final String? subtitle;
  final String? description;
  final double rating;
  final int reviewCount;
  final int stock;
  final List<String> images;
  final String? brand;
  final String? seller;
  final Map<String, String>? specifications;
  final List<String>? features;
  final List<String> badges;

  const Product({
    // Core fields (required for backward compatibility)
    required this.name,
    required this.price,
    required this.oldPrice,
    required this.category,
    required this.icon,
    // Extended fields (optional with defaults)
    required this.id,
    this.subtitle,
    this.description,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.stock = 0,
    this.images = const [],
    this.brand,
    this.seller,
    this.specifications,
    this.features,
    this.badges = const [],
  });

  /// Create a Product from a Supabase `products` row.
  ///
  /// Expects the shape produced by ProductRemoteDataSource's select:
  /// `slug, name, subtitle, description, price, old_price, rating,
  /// review_count, stock, brand, seller, specifications, features, badges,
  /// categories(key), product_images(url, sort_order)`.
  ///
  /// [id] is set to the row's `slug`, not its UUID primary key, so it stays
  /// compatible with existing wishlist/cart/recently-viewed persistence,
  /// which already keys everything off the human-readable slug-style id
  /// (e.g. "elec-001").
  factory Product.fromSupabase(Map<String, dynamic> json) {
    final categoryJson = json['categories'] as Map<String, dynamic>?;
    final category = categoryJson?['key'] as String? ?? '';

    final imagesJson = json['product_images'] as List<dynamic>? ?? const [];
    final images = imagesJson
        .map((row) => (row as Map<String, dynamic>)['url'] as String)
        .toList();

    return Product(
      id: json['slug'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      oldPrice: (json['old_price'] as num).toDouble(),
      category: category,
      icon: _categoryFallbackIcons[category] ?? Icons.shopping_bag,
      subtitle: json['subtitle'] as String?,
      description: json['description'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['review_count'] as int? ?? 0,
      stock: json['stock'] as int? ?? 0,
      images: images,
      brand: json['brand'] as String?,
      seller: json['seller'] as String?,
      specifications:
          (json['specifications'] as Map<String, dynamic>?)?.cast<String, String>(),
      features: (json['features'] as List<dynamic>?)?.cast<String>(),
      badges: (json['badges'] as List<dynamic>?)?.cast<String>() ?? const [],
    );
  }

  /// Calculates discount percentage based on old price and current price
  ///
  /// Returns the discount as an integer percentage (0-100)
  int get discount {
    return ((oldPrice - price) * 100 / oldPrice).round();
  }

  /// Check if product is in stock
  bool get isInStock => stock > 0;

  /// Check if product has low stock (less than 10 units)
  bool get isLowStock => stock > 0 && stock < 10;

  /// Check if product is out of stock
  bool get isOutOfStock => stock == 0;

  /// Check if product has rating
  bool get hasRating => rating > 0.0;

  /// Check if product has reviews
  bool get hasReviews => reviewCount > 0;

  /// Check if product qualifies for free shipping
  /// (currently based on price threshold, can be enhanced)
  bool get hasFreeShipping => price >= 50.0;

  /// Create a copy of this product with updated fields
  Product copyWith({
    String? id,
    String? name,
    double? price,
    double? oldPrice,
    String? category,
    IconData? icon,
    String? subtitle,
    String? description,
    double? rating,
    int? reviewCount,
    int? stock,
    List<String>? images,
    String? brand,
    String? seller,
    Map<String, String>? specifications,
    List<String>? features,
    List<String>? badges,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      oldPrice: oldPrice ?? this.oldPrice,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      stock: stock ?? this.stock,
      images: images ?? this.images,
      brand: brand ?? this.brand,
      seller: seller ?? this.seller,
      specifications: specifications ?? this.specifications,
      features: features ?? this.features,
      badges: badges ?? this.badges,
    );
  }
}
