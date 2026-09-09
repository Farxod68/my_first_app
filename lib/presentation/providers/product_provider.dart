import 'package:flutter/foundation.dart';
import '../../data/models/product.dart';
import '../../domain/repositories/product_repository.dart';

/// Product catalog state management provider (Presentation Layer)
///
/// Loads the Supabase-backed product catalog and exposes loading/error
/// state to the UI.
///
/// Phase 29C note: this provider is not yet registered in main.dart or
/// consumed by any screen. It is introduced alongside the existing local
/// mock catalog (lib/data/data_sources/local/mock_products.dart), which
/// screens continue to use until a later phase migrates them.
///
/// Uses ChangeNotifier for state management with Provider pattern.
/// Integrates with ProductRepository for backend operations.
class ProductProvider with ChangeNotifier {
  final ProductRepository _productRepository;

  List<Product> _products = [];
  bool _isLoading = false;
  String? _error;

  ProductProvider(this._productRepository) {
    _loadProducts();
  }

  /// Current product list (empty until loaded, or after a failed load)
  List<Product> get products => List.unmodifiable(_products);

  /// Loading state (true while a load/refresh is in flight)
  bool get isLoading => _isLoading;

  /// Error message from the last load/refresh, if it failed
  String? get error => _error;

  /// Load products from the repository
  Future<void> _loadProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _products = await _productRepository.fetchProducts();
    } catch (e) {
      _error = 'Failed to load products: ${e.toString()}';
      _products = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reload products from the repository
  Future<void> refresh() => _loadProducts();
}
