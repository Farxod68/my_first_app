import 'package:flutter/material.dart';

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
