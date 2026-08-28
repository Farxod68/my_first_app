import 'package:flutter/material.dart';
import 'package:my_first_app/data/models/product.dart';
import 'package:my_first_app/domain/entities/user_entity.dart';

/// Test data fixtures and helpers
///
/// Provides factory methods for creating test instances of domain objects
/// with reasonable defaults and customizable fields.
class TestData {
  /// Create a test Product with default values
  ///
  /// All fields can be overridden. Default creates a valid product with:
  /// - id: 'test_product_1'
  /// - name: 'Test Product'
  /// - price: 99.99
  /// - oldPrice: 149.99 (33% discount)
  /// - category: 'Electronics'
  /// - rating: 4.5
  /// - stock: 10
  static Product createTestProduct({
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
      id: id ?? 'test_product_1',
      name: name ?? 'Test Product',
      price: price ?? 99.99,
      oldPrice: oldPrice ?? 149.99,
      category: category ?? 'Electronics',
      icon: icon ?? Icons.devices,
      subtitle: subtitle,
      description: description,
      rating: rating ?? 4.5,
      reviewCount: reviewCount ?? 100,
      stock: stock ?? 10,
      images: images ?? const [],
      brand: brand,
      seller: seller,
      specifications: specifications,
      features: features,
      badges: badges ?? const [],
    );
  }

  /// Create a list of test products
  ///
  /// Generates [count] products with unique IDs and names.
  /// Useful for testing list operations and search/filter functionality.
  static List<Product> createProductList(int count, {String? category}) {
    return List.generate(
      count,
      (index) => createTestProduct(
        id: 'test_product_${index + 1}',
        name: 'Test Product ${index + 1}',
        price: 50.0 + (index * 10.0),
        oldPrice: 100.0 + (index * 10.0),
        category: category ?? 'Electronics',
        rating: 3.0 + (index % 3),
        reviewCount: 50 + (index * 10),
        stock: 5 + (index % 20),
        brand: index % 2 == 0 ? 'Brand A' : 'Brand B',
      ),
    );
  }

  /// Create a test UserEntity with default values
  ///
  /// Default user:
  /// - id: 'test_user_123'
  /// - email: 'test@example.com'
  /// - fullName: 'Test User'
  /// - languageCode: 'en'
  /// - currencyCode: 'USD'
  static UserEntity createTestUser({
    String? id,
    String? email,
    String? fullName,
    String? avatarUrl,
    String? phone,
    String? languageCode,
    String? currencyCode,
    String? role,
    bool? isActive,
    bool? emailVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime(2024, 1, 1);
    return UserEntity(
      id: id ?? 'test_user_123',
      email: email ?? 'test@example.com',
      fullName: fullName ?? 'Test User',
      avatarUrl: avatarUrl,
      phone: phone,
      languageCode: languageCode ?? 'en',
      currencyCode: currencyCode ?? 'USD',
      role: role ?? 'customer',
      isActive: isActive ?? true,
      emailVerified: emailVerified ?? false,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
    );
  }
}
