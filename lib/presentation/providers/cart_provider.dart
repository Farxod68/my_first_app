import 'dart:convert';
import 'package:flutter/material.dart';
import '../../data/models/product.dart';
import '../../core/services/persistence_service.dart';
import 'base_persistent_provider.dart';

/// Cart state management provider with persistence
///
/// Manages shopping cart state including:
/// - List of products in cart (one entry per product, with a quantity)
/// - Add to cart functionality
/// - Quantity increase/decrease
/// - Remove from cart functionality
/// - Cart item count
/// - Cart total calculation
/// - Automatic persistence to local storage
///
/// Uses ChangeNotifier for state management with Provider pattern
/// Persists cart data using PersistenceService
class CartProvider with ChangeNotifier, PersistentProviderMixin {
  final PersistenceService _persistenceService;

  /// Unique products in the order they were first added.
  final List<Product> _cartItems = [];

  /// Quantity per product ID. Every product in [_cartItems] has an entry >= 1.
  final Map<String, int> _quantities = {};

  CartProvider(this._persistenceService) {
    _loadCart();
  }

  /// Get immutable list of cart items (one entry per product)
  List<Product> get cartItems => List.unmodifiable(_cartItems);

  /// Get total number of units in cart (sum of all quantities)
  ///
  /// Drives the cart badge, which counts every unit added.
  int get itemCount =>
      _quantities.values.fold(0, (sum, quantity) => sum + quantity);

  /// Check if a product is in the cart by ID
  bool isInCart(String productId) {
    return _quantities.containsKey(productId);
  }

  /// Quantity of a product in the cart, or 0 if it is not in the cart
  int quantityOf(String productId) => _quantities[productId] ?? 0;

  /// Add a product to the cart
  ///
  /// A product already in the cart has its quantity increased by 1 instead of
  /// getting a second entry.
  void addToCart(Product product) {
    _addUnits(product, 1);
    _saveCart();
    notifyListeners();
  }

  /// Increase the quantity of a product already in the cart by 1
  ///
  /// Does nothing if the product is not in the cart.
  void increaseQuantity(String productId) {
    final current = _quantities[productId];
    if (current == null) return;
    _quantities[productId] = current + 1;
    _saveCart();
    notifyListeners();
  }

  /// Decrease the quantity of a product in the cart by 1
  ///
  /// Decreasing from 1 removes the product. Does nothing if the product is
  /// not in the cart.
  void decreaseQuantity(String productId) {
    final current = _quantities[productId];
    if (current == null) return;
    if (current <= 1) {
      _cartItems.removeWhere((item) => item.id == productId);
      _quantities.remove(productId);
    } else {
      _quantities[productId] = current - 1;
    }
    _saveCart();
    notifyListeners();
  }

  /// Remove the cart entry at [index], whatever its quantity
  void removeAt(int index) {
    if (index >= 0 && index < _cartItems.length) {
      final removed = _cartItems.removeAt(index);
      _quantities.remove(removed.id);
      _saveCart();
      notifyListeners();
    }
  }

  /// Remove a product's complete cart entry by ID, whatever its quantity
  void removeProduct(Product product) {
    _cartItems.removeWhere((item) => item.id == product.id);
    _quantities.remove(product.id);
    _saveCart();
    notifyListeners();
  }

  /// Clear all items from cart
  void clearCart() {
    _cartItems.clear();
    _quantities.clear();
    _saveCart();
    notifyListeners();
  }

  /// Get cart subtotal
  ///
  /// Sums unit price × quantity for every item (in USD base currency)
  double get subtotal {
    return _cartItems.fold(
        0.0, (sum, item) => sum + item.price * quantityOf(item.id));
  }

  /// Adds [quantity] units of [product], merging with an existing entry
  void _addUnits(Product product, int quantity) {
    final current = _quantities[product.id];
    if (current == null) {
      _cartItems.add(product);
      _quantities[product.id] = quantity;
    } else {
      _quantities[product.id] = current + quantity;
    }
  }

  /// Load cart from persistence
  ///
  /// Called automatically during initialization.
  /// Handles corrupted data gracefully by starting with empty cart.
  /// Legacy entries without a valid `quantity` load as quantity 1, and legacy
  /// duplicate entries for the same product are merged by summing quantities.
  Future<void> _loadCart() async {
    try {
      final cartJson = _persistenceService.loadCart();

      _cartItems.clear();
      _quantities.clear();
      for (final jsonString in cartJson) {
        try {
          final productData = json.decode(jsonString) as Map<String, dynamic>;
          final product = _productFromJson(productData);
          final quantity = productData['quantity'];
          _addUnits(product, quantity is int && quantity > 0 ? quantity : 1);
        } catch (e) {
          // Skip corrupted product data
          debugPrint('Failed to load cart item: $e');
        }
      }
    } catch (e) {
      debugPrint('Failed to load cart: $e');
      // Start with empty cart if load fails
      _cartItems.clear();
      _quantities.clear();
    } finally {
      markAsLoaded();
    }
  }

  /// Save cart to persistence
  ///
  /// Called automatically after cart modifications.
  /// Each entry is the product JSON plus its `quantity`.
  /// Fails silently to avoid disrupting user experience.
  Future<void> _saveCart() async {
    try {
      final cartJson = _cartItems
          .map((product) => json.encode({
                ..._productToJson(product),
                'quantity': quantityOf(product.id),
              }))
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
  /// carry - from mock_products.dart, or from Product.fromSupabase's
  /// per-category fallback icons (lib/data/models/product.dart) - is a
  /// literal here instead, so the tree-shaker can see them all statically.
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
    0xe252: Icons.face,
    0xe28d: Icons.fitness_center,
    0xe2ff: Icons.headphones,
    0xe318: Icons.home,
    0xe351: Icons.keyboard,
    0xe35e: Icons.kitchen,
    0xe367: Icons.laptop,
    0xe379: Icons.light,
    0xe3c1: Icons.luggage,
    0xe40b: Icons.mouse,
    0xe4a3: Icons.phone_android,
    0xe56f: Icons.self_improvement,
    0xe5c6: Icons.smartphone,
    0xe5db: Icons.speaker,
    0xe5e5: Icons.sports_baseball,
    0xf06c3: Icons.sports_gymnastics,
    0xe5f2: Icons.sports_soccer,
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
