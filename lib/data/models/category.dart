import 'package:flutter/material.dart';

/// Category model for TOPBUY DEALS marketplace
///
/// Represents a product category with:
/// - Unique identifier
/// - Category key (for programmatic access)
/// - Localized name
/// - Icon representation
/// - Subcategories support
class Category {
  final String id;
  final String key;
  final String name;
  final IconData icon;
  final List<Subcategory> subcategories;

  const Category({
    required this.id,
    required this.key,
    required this.name,
    required this.icon,
    this.subcategories = const [],
  });

  /// Create a copy of this category with updated fields
  Category copyWith({
    String? id,
    String? key,
    String? name,
    IconData? icon,
    List<Subcategory>? subcategories,
  }) {
    return Category(
      id: id ?? this.id,
      key: key ?? this.key,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      subcategories: subcategories ?? this.subcategories,
    );
  }
}

/// Subcategory model for TOPBUY DEALS marketplace
///
/// Represents a subcategory within a parent category
class Subcategory {
  final String id;
  final String key;
  final String name;
  final String categoryKey;

  const Subcategory({
    required this.id,
    required this.key,
    required this.name,
    required this.categoryKey,
  });

  /// Create a copy of this subcategory with updated fields
  Subcategory copyWith({
    String? id,
    String? key,
    String? name,
    String? categoryKey,
  }) {
    return Subcategory(
      id: id ?? this.id,
      key: key ?? this.key,
      name: name ?? this.name,
      categoryKey: categoryKey ?? this.categoryKey,
    );
  }
}
