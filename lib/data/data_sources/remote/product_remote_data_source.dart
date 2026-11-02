import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../../models/product.dart';

/// Thrown when a product catalog operation against Supabase fails.
///
/// Mirrors the shape of supabase_flutter's AuthException (a `message`
/// field callers can read) without borrowing an auth-specific type for a
/// catalog-read error.
class ProductException implements Exception {
  final String message;

  const ProductException(this.message);

  @override
  String toString() => message;
}

/// Translation embed (migration 008): per-locale text. The fetches filter it
/// to the requested locale, and Product.fromSupabase falls back to the
/// English `products` columns per field.
const String _translationColumns =
    'product_translations(locale, name, subtitle, description, features, '
    'specifications)';

/// Columns/relations shared by the fetch operations below.
///
/// `categories(key)` embeds the product's category key via the
/// products.category_id -> categories.id foreign key (migration 002).
/// `product_images(url, sort_order)` embeds that product's images.
const String _productSelectColumns =
    'slug, name, subtitle, description, price, old_price, rating, '
    'review_count, stock, brand, seller, specifications, features, badges, '
    'categories(key), product_images(url, sort_order), '
    '$_translationColumns';

/// Product catalog remote data source (Data Layer)
///
/// Handles all Supabase product-catalog reads.
/// Never called directly from UI - always through ProductRepository.
class ProductRemoteDataSource {
  final SupabaseClient _supabase;

  ProductRemoteDataSource([SupabaseClient? supabase])
      : _supabase = supabase ?? SupabaseService.client;

  /// Fetch all active products, including category key and images ordered
  /// by sort_order. With [locale], embedded translations are limited to that
  /// locale and applied (per field) over the English columns.
  Future<List<Product>> fetchProducts({String? locale}) async {
    try {
      var query = _supabase
          .from('products')
          .select(_productSelectColumns)
          .eq('is_active', true);
      if (locale != null) {
        query = query.eq('product_translations.locale', locale);
      }
      final response = await query.order('sort_order',
          referencedTable: 'product_images', ascending: true);

      return response
          .map((row) => Product.fromSupabase(row, locale: locale))
          .toList();
    } catch (e) {
      throw ProductException('Failed to load products: $e');
    }
  }

  /// Fetch a single active product by its human-readable slug (Product.id).
  ///
  /// Returns null if no active product with that slug exists.
  Future<Product?> fetchProductById(String id, {String? locale}) async {
    try {
      var query = _supabase
          .from('products')
          .select(_productSelectColumns)
          .eq('slug', id)
          .eq('is_active', true);
      if (locale != null) {
        query = query.eq('product_translations.locale', locale);
      }
      final response = await query
          .order('sort_order', referencedTable: 'product_images', ascending: true)
          .maybeSingle();

      if (response == null) {
        return null;
      }
      return Product.fromSupabase(response, locale: locale);
    } catch (e) {
      throw ProductException('Failed to load product: $e');
    }
  }

  /// Fetch all active products in the given category (a CategoryKeys value,
  /// e.g. "electronics").
  ///
  /// Uses `categories!inner(key)` so the category filter narrows the
  /// `products` rows themselves, not just the embedded category object.
  /// The translation embed is a regular (left) join, so its locale filter
  /// only narrows the embedded translations, never the products.
  Future<List<Product>> fetchProductsByCategory(String categoryKey,
      {String? locale}) async {
    try {
      var query = _supabase
          .from('products')
          .select(
            'slug, name, subtitle, description, price, old_price, rating, '
            'review_count, stock, brand, seller, specifications, features, badges, '
            'categories!inner(key), product_images(url, sort_order), '
            '$_translationColumns',
          )
          .eq('is_active', true)
          .eq('categories.key', categoryKey);
      if (locale != null) {
        query = query.eq('product_translations.locale', locale);
      }
      final response = await query.order('sort_order',
          referencedTable: 'product_images', ascending: true);

      return response
          .map((row) => Product.fromSupabase(row, locale: locale))
          .toList();
    } catch (e) {
      throw ProductException('Failed to load products for category "$categoryKey": $e');
    }
  }
}
