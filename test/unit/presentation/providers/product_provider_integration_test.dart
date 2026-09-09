import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_first_app/data/data_sources/remote/product_remote_data_source.dart';
import 'package:my_first_app/data/repositories/product_repository_impl.dart';
import 'package:my_first_app/presentation/providers/product_provider.dart';

/// Integration-style test for the exact production wiring registered in
/// main.dart (Phase 29D):
///
///   ProductProvider(ProductRepositoryImpl(ProductRemoteDataSource()))
///
/// Unlike product_provider_test.dart and product_repository_impl_test.dart
/// (Phase 29C), which each mock only the layer directly below them, this
/// test uses REAL ProductRepositoryImpl and ProductRemoteDataSource
/// instances and mocks only the SupabaseClient boundary - proving the
/// three layers actually compose correctly together, the way main.dart
/// wires them. No live network is used.

class MockSupabaseClient extends Mock implements SupabaseClient {}

/// Minimal fake query builder chain for `.from('products').select(...)
/// .eq(...).order(...)`, awaited directly as a product list. Mirrors the
/// pattern in product_remote_data_source_test.dart.
class FakeProductQueryBuilder implements SupabaseQueryBuilder {
  final List<Map<String, dynamic>> listData;

  FakeProductQueryBuilder(this.listData);

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> select([String columns = '*']) {
    return FakeProductFilterBuilder(listData);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeProductFilterBuilder implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  final List<Map<String, dynamic>> listData;

  FakeProductFilterBuilder(this.listData);

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> eq(String column, Object? value) => this;

  @override
  PostgrestTransformBuilder<List<Map<String, dynamic>>> order(
    String column, {
    bool ascending = false,
    bool nullsFirst = false,
    String? referencedTable,
  }) =>
      this;

  @override
  Future<R> then<R>(
    FutureOr<R> Function(List<Map<String, dynamic>>) onValue,
    {Function? onError}
  ) {
    try {
      final result = onValue(listData);
      if (result is Future<R>) {
        return onError == null ? result : result.catchError(onError);
      }
      return Future.value(result);
    } catch (e) {
      if (onError != null) {
        return Future.sync(() => onError(e));
      }
      return Future.error(e);
    }
  }

  @override
  Stream<List<Map<String, dynamic>>> asStream() => Stream.value(listData);

  @override
  Future<List<Map<String, dynamic>>> catchError(Function onError, {bool Function(Object)? test}) {
    return Future.value(listData).catchError(onError, test: test);
  }

  @override
  Future<List<Map<String, dynamic>>> whenComplete(FutureOr<void> Function() action) {
    return Future.value(listData).whenComplete(action);
  }

  @override
  Future<List<Map<String, dynamic>>> timeout(
    Duration timeLimit, {
    FutureOr<List<Map<String, dynamic>>> Function()? onTimeout,
  }) {
    return Future.value(listData);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ProductProvider + ProductRepositoryImpl + ProductRemoteDataSource wiring', () {
    test('loads products end-to-end through the real repository and data source', () async {
      final mockSupabase = MockSupabaseClient();
      when(() => mockSupabase.from('products')).thenAnswer(
        (_) => FakeProductQueryBuilder([
          {
            'slug': 'elec-001',
            'name': 'Smart Watch Ultra',
            'subtitle': 'Fitness & Health Tracking',
            'description': 'Premium smartwatch.',
            'price': 199.99,
            'old_price': 319.99,
            'rating': 4.6,
            'review_count': 1847,
            'stock': 45,
            'brand': 'TechPro',
            'seller': 'TechPro Official Store',
            'specifications': {'Display': '1.9" AMOLED'},
            'features': ['GPS + GLONASS navigation'],
            'badges': ['Best Seller'],
            'categories': {'key': 'electronics'},
            'product_images': const [],
          },
        ]),
      );

      // Exactly the composition main.dart registers, with the Supabase
      // client boundary swapped for a fake.
      final dataSource = ProductRemoteDataSource(mockSupabase);
      final repository = ProductRepositoryImpl(dataSource);
      final provider = ProductProvider(repository);

      await Future.delayed(Duration.zero);

      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
      expect(provider.products, hasLength(1));
      expect(provider.products.single.id, 'elec-001');
      expect(provider.products.single.name, 'Smart Watch Ultra');
      expect(provider.products.single.category, 'electronics');
    });

    test('a Supabase-layer failure surfaces as a ProductProvider error, not a crash', () async {
      final mockSupabase = MockSupabaseClient();
      when(() => mockSupabase.from('products'))
          .thenThrow(PostgrestException(message: 'connection refused'));

      final dataSource = ProductRemoteDataSource(mockSupabase);
      final repository = ProductRepositoryImpl(dataSource);
      final provider = ProductProvider(repository);

      await Future.delayed(Duration.zero);

      expect(provider.isLoading, isFalse);
      expect(provider.products, isEmpty);
      expect(provider.error, isNotNull);
      expect(provider.error, contains('Failed to load products'));
    });
  });
}
