import 'dart:convert';
import 'package:flutter/material.dart';
import '../../data/models/product.dart';
import '../../core/services/persistence_service.dart';
import 'base_persistent_provider.dart';

/// Cart state management provider with persistence
///
/// Manages shopping cart state including:
/// - List of products in cart
/// - Add to cart functionality
/// - Remove from cart functionality
/// - Cart item count
/// - Cart total calculation
/// - Automatic persistence to local storage
///
/// Uses ChangeNotifier for state management with Provider pattern
/// Persists cart data using PersistenceService
class CartProvider with ChangeNotifier, PersistentProviderMixin {
  final PersistenceService _persistenceService;
  final List<Product> _cartItems = [];

  CartProvider(this._persistenceService) {
    _loadCart();
  }

  /// Get immutable list of cart items
  List<Product> get cartItems => List.unmodifiable(_cartItems);

  /// Get total number of items in cart
  int get itemCount => _cartItems.length;

  /// Check if a product is in the cart by ID
  bool isInCart(String productId) {
    return _cartItems.any((item) => item.id == productId);
  }

  /// Add a product to the cart
  ///
  /// Currently allows duplicate products (no quantity management yet).
  /// Future enhancement: Add quantity tracking and prevent duplicates.
  void addToCart(Product product) {
    _cartItems.add(product);
    _saveCart();
    notifyListeners();
  }

  /// Remove a product from cart by index
  void removeAt(int index) {
    if (index >= 0 && index < _cartItems.length) {
      _cartItems.removeAt(index);
      _saveCart();
      notifyListeners();
    }
  }

  /// Remove first occurrence of a product from cart by ID
  void removeProduct(Product product) {
    _cartItems.removeWhere((item) => item.id == product.id);
    _saveCart();
    notifyListeners();
  }

  /// Clear all items from cart
  void clearCart() {
    _cartItems.clear();
    _saveCart();
    notifyListeners();
  }

  /// Get cart subtotal
  ///
  /// Calculates total price of all items in cart (in USD base currency)
  double get subtotal {
    return _cartItems.fold(0.0, (sum, item) => sum + item.price);
  }

  /// Load cart from persistence
  ///
  /// Called automatically during initialization.
  /// Handles corrupted data gracefully by starting with empty cart.
  Future<void> _loadCart() async {
    try {
      final cartJson = _persistenceService.loadCart();

      _cartItems.clear();
      for (final jsonString in cartJson) {
        try {
          final productData = json.decode(jsonString) as Map<String, dynamic>;
          final product = _productFromJson(productData);
          _cartItems.add(product);
        } catch (e) {
          // Skip corrupted product data
          debugPrint('Failed to load cart item: $e');
        }
      }
    } catch (e) {
      debugPrint('Failed to load cart: $e');
      // Start with empty cart if load fails
      _cartItems.clear();
    } finally {
      markAsLoaded();
    }
  }

  /// Save cart to persistence
  ///
  /// Called automatically after cart modifications.
  /// Fails silently to avoid disrupting user experience.
  Future<void> _saveCart() async {
    try {
      final cartJson = _cartItems
          .map((product) => json.encode(_productToJson(product)))
          .toList();
      await _persistenceService.saveCart(cartJson);
    } catch (e) {
      debugPrint('Failed to save cart: $e');
      // Continue without throwing - persistence failure shouldn't crash app
    }
  }

  /// Convert Product to JSON map for persistence
  Map<String, dynamic> _productToJson(Product product) {
    return {
      // Core fields (required for backward compatibility)
      'id': product.id,
      'name': product.name,
      'price': product.price,
      'oldPrice': product.oldPrice,
      'category': product.category,
      'iconCodePoint': product.icon.codePoint,
      // Extended fields (Phase 4B)
      'subtitle': product.subtitle,
      'description': product.description,
      'rating': product.rating,
      'reviewCount': product.reviewCount,
      'stock': product.stock,
      'images': product.images,
      'brand': product.brand,
      'seller': product.seller,
      'specifications': product.specifications,
      'features': product.features,
      'badges': product.badges,
    };
  }

  /// Convert JSON map to Product
  Product _productFromJson(Map<String, dynamic> json) {
    return Product(
      // Core fields (required)
      id: json['id'] as String? ?? 'unknown',
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      oldPrice: (json['oldPrice'] as num).toDouble(),
      category: json['category'] as String,
      icon: IconData(
        json['iconCodePoint'] as int, // ignore: non_const_argument_for_const_parameter
        fontFamily: 'MaterialIcons',
      ),
      // Extended fields (optional with defaults)
      subtitle: json['subtitle'] as String?,
      description: json['description'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      stock: json['stock'] as int? ?? 0,
      images: (json['images'] as List<dynamic>?)?.cast<String>() ?? const [],
      brand: json['brand'] as String?,
      seller: json['seller'] as String?,
      specifications: (json['specifications'] as Map<String, dynamic>?)?.cast<String, String>(),
      features: (json['features'] as List<dynamic>?)?.cast<String>(),
      badges: (json['badges'] as List<dynamic>?)?.cast<String>() ?? const [],
    );
  }
}
