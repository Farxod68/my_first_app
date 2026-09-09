import '../../data/models/product.dart';

/// Product catalog repository interface (Domain Layer)
///
/// Defines the contract for reading the product catalog.
/// Implementations handle the actual communication with backends.
///
/// This abstraction allows:
/// - Easy testing (mock implementations)
/// - Backend independence (swap Supabase for another source)
/// - Clean separation of concerns
///
/// Note: unlike AuthRepository (which returns a domain-only UserEntity),
/// this repository returns Product directly. Product already is the single
/// representation used across data sources, providers, and UI in this
/// codebase (see lib/data/models/product.dart and
/// lib/domain/use_cases/deal_helper.dart) - introducing a separate
/// ProductEntity here would duplicate that model rather than mirror it.
abstract class ProductRepository {
  /// Fetch all active products.
  Future<List<Product>> fetchProducts();

  /// Fetch a single active product by its slug-style id (e.g. "elec-001").
  ///
  /// Returns null if no active product with that id exists.
  Future<Product?> fetchProductById(String id);

  /// Fetch all active products in the given category (a CategoryKeys value,
  /// e.g. "electronics").
  Future<List<Product>> fetchProductsByCategory(String categoryKey);
}
