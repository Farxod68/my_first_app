import '../../domain/repositories/product_repository.dart';
import '../data_sources/remote/product_remote_data_source.dart';
import '../models/product.dart';

/// Product catalog repository implementation (Data Layer)
///
/// Implements ProductRepository using Supabase backend.
/// Mediates between domain layer and data sources.
///
/// Architecture:
/// Provider -> Repository -> Data Source -> Supabase
class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource _remoteDataSource;

  ProductRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<Product>> fetchProducts({String? locale}) {
    return _remoteDataSource.fetchProducts(locale: locale);
  }

  @override
  Future<Product?> fetchProductById(String id, {String? locale}) {
    return _remoteDataSource.fetchProductById(id, locale: locale);
  }

  @override
  Future<List<Product>> fetchProductsByCategory(String categoryKey,
      {String? locale}) {
    return _remoteDataSource.fetchProductsByCategory(categoryKey,
        locale: locale);
  }
}
