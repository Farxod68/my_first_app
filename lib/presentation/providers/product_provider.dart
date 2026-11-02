import 'package:flutter/foundation.dart';
import '../../data/models/product.dart';
import '../../domain/repositories/product_repository.dart';

/// Product catalog state management provider (Presentation Layer)
///
/// Loads the Supabase-backed product catalog and exposes loading/error
/// state to the UI.
///
/// The catalog is loaded for the app's current language: [locale] selects
/// the `product_translations` rows (migration 008) applied over the English
/// `products` fields. main.dart keeps it in sync with LocaleProvider through
/// [setLocale], which reloads the catalog.
///
/// Uses ChangeNotifier for state management with Provider pattern.
/// Integrates with ProductRepository for backend operations.
class ProductProvider with ChangeNotifier {
  final ProductRepository _productRepository;

  String _locale;
  List<Product> _products = [];
  bool _isLoading = false;
  String? _error;

  /// Identifies the latest load; a response from an older load (e.g. one
  /// started before a language change) is discarded so it can't overwrite
  /// newer, correctly-localized data.
  int _loadId = 0;

  ProductProvider(this._productRepository, {String initialLocale = 'en'})
      : _locale = initialLocale {
    _loadProducts();
  }

  /// Language code the catalog is currently loaded for
  String get locale => _locale;

  /// Current product list (empty until loaded, or after a failed load)
  List<Product> get products => List.unmodifiable(_products);

  /// Loading state (true while a load/refresh is in flight)
  bool get isLoading => _isLoading;

  /// Error message from the last load/refresh, if it failed
  String? get error => _error;

  /// Switch the catalog language and reload it. No-op if unchanged.
  ///
  /// The reload starts in a microtask rather than synchronously: this is
  /// called from a ProxyProvider `update` callback during the widget build,
  /// and notifying listeners there would throw "setState() called during
  /// build".
  Future<void> setLocale(String languageCode) {
    if (languageCode == _locale) return Future.value();
    _locale = languageCode;
    return Future.microtask(_loadProducts);
  }

  /// Returns [product] with its translatable text (name, subtitle,
  /// description, features, specifications) taken from the current catalog,
  /// or [product] itself when it is not in the catalog.
  ///
  /// For products whose text was captured earlier in another language, such
  /// as cart items persisted by CartProvider. Prices, stock, images and
  /// every other field stay as stored, so persistence is unaffected.
  Product localize(Product product) {
    for (final candidate in _products) {
      if (candidate.id == product.id) {
        return product.copyWith(
          name: candidate.name,
          subtitle: candidate.subtitle,
          description: candidate.description,
          features: candidate.features,
          specifications: candidate.specifications,
        );
      }
    }
    return product;
  }

  /// Load products from the repository
  Future<void> _loadProducts() async {
    final loadId = ++_loadId;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final loaded = await _productRepository.fetchProducts(locale: _locale);
      if (loadId != _loadId) return;
      _products = loaded;
    } catch (e) {
      if (loadId != _loadId) return;
      _error = 'Failed to load products: ${e.toString()}';
      _products = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Reload products from the repository
  Future<void> refresh() => _loadProducts();
}
