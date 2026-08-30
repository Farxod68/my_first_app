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

  /// Maps a persisted icon code point back to the exact const [IconData] it
  /// came from. Reconstructing IconData from a runtime int (as the old code
  /// did) defeats Flutter's release-mode icon tree-shaker, since it can no
  /// longer prove which icons are reachable. Every icon any [Product] can
  /// carry (see mock_products.dart) is a literal here instead, so the
  /// tree-shaker can see them all statically.
  ///
  /// Keys are the literal Material Icons code points (from the Flutter SDK's
  /// icons.dart), not `Icons.x.codePoint` - Dart doesn't allow accessing an
  /// instance field of a const object as a map key in a const expression.
  static const Map<int, IconData> _iconByCodePoint = {
    0xe037: Icons.ac_unit,
    0xe03a: Icons.access_time,
    0xe041: Icons.account_balance_wallet,
    0xe064: Icons.air,
    0xe0c4: Icons.backpack,
    0xe0d7: Icons.bed,
    0xe0e0: Icons.blender,
    0xe113: Icons.brush,
    0xe11c: Icons.business_center,
    0xe130: Icons.camera_alt,
    0xe152: Icons.charging_station,
    0xe15d: Icons.checkroom,
    0xe166: Icons.clean_hands,
    0xe167: Icons.cleaning_services,
    0xe179: Icons.coffee_maker,
    0xe1dc: Icons.directions_run,
    0xe1e1: Icons.directions_walk,
    0xe28d: Icons.fitness_center,
    0xe2ff: Icons.headphones,
    0xe351: Icons.keyboard,
    0xe35e: Icons.kitchen,
    0xe367: Icons.laptop,
    0xe379: Icons.light,
    0xe3c1: Icons.luggage,
    0xe40b: Icons.mouse,
    0xe56f: Icons.self_improvement,
    0xe5c6: Icons.smartphone,
    0xe5db: Icons.speaker,
    0xe5e5: Icons.sports_baseball,
    0xf06c3: Icons.sports_gymnastics,
    0xe609: Icons.storage,
    0xe63e: Icons.tablet_android,
    0xe697: Icons.usb,
    0xe6ce: Icons.watch,
    0xe6cf: Icons.watch_later,
    0xf05a2: Icons.water_drop,
    0xe6d9: Icons.wb_sunny,
  };

  /// Convert JSON map to Product
  Product _productFromJson(Map<String, dynamic> json) {
    return Product(
      // Core fields (required)
      id: json['id'] as String? ?? 'unknown',
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      oldPrice: (json['oldPrice'] as num).toDouble(),
      category: json['category'] as String,
      icon: _iconByCodePoint[json['iconCodePoint'] as int] ??
          Icons.shopping_bag,
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
