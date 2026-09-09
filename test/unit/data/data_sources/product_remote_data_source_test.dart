import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_first_app/data/data_sources/remote/product_remote_data_source.dart';
import 'package:my_first_app/data/models/product.dart';

// Mock Supabase client
class MockSupabaseClient extends Mock implements SupabaseClient {}

// Fake implementations for Supabase query builder chains, mirroring the
// pattern in auth_remote_data_source_test.dart. These are needed because
// PostgrestTransformBuilder implements Future, which makes it difficult to
// mock with standard mocktail patterns.

/// Fake SupabaseQueryBuilder that returns controlled list/single data.
class FakeProductQueryBuilder implements SupabaseQueryBuilder {
  final List<Map<String, dynamic>>? listData;
  final Map<String, dynamic>? singleData;

  FakeProductQueryBuilder({this.listData, this.singleData});

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> select([String columns = '*']) {
    return FakeProductFilterBuilder(listData: listData, singleData: singleData);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Fake PostgrestFilterBuilder supporting the .eq().order() chains used by
/// ProductRemoteDataSource - chainable, and directly awaitable for list
/// queries (fetchProducts/fetchProductsByCategory), with .maybeSingle() for
/// the single-product query (fetchProductById).
class FakeProductFilterBuilder implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  final List<Map<String, dynamic>>? listData;
  final Map<String, dynamic>? singleData;

  FakeProductFilterBuilder({this.listData, this.singleData});

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> eq(String column, Object? value) {
    return this; // Chainable
  }

  @override
  PostgrestTransformBuilder<List<Map<String, dynamic>>> order(
    String column, {
    bool ascending = false,
    bool nullsFirst = false,
    String? referencedTable,
  }) {
    return this; // Chainable
  }

  @override
  PostgrestTransformBuilder<Map<String, dynamic>?> maybeSingle() {
    return FakeAwaitableSingle(singleData);
  }

  @override
  Future<R> then<R>(
    FutureOr<R> Function(List<Map<String, dynamic>>) onValue,
    {Function? onError}
  ) {
    try {
      final result = onValue(listData ?? const []);
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
  Stream<List<Map<String, dynamic>>> asStream() =>
      Stream.value(listData ?? const <Map<String, dynamic>>[]);

  @override
  Future<List<Map<String, dynamic>>> catchError(Function onError, {bool Function(Object)? test}) {
    return Future.value(listData ?? const <Map<String, dynamic>>[])
        .catchError(onError, test: test);
  }

  @override
  Future<List<Map<String, dynamic>>> whenComplete(FutureOr<void> Function() action) {
    return Future.value(listData ?? const <Map<String, dynamic>>[]).whenComplete(action);
  }

  @override
  Future<List<Map<String, dynamic>>> timeout(
    Duration timeLimit, {
    FutureOr<List<Map<String, dynamic>>> Function()? onTimeout,
  }) {
    return Future.value(listData ?? const <Map<String, dynamic>>[]);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Fake awaitable result for maybeSingle()
class FakeAwaitableSingle implements PostgrestTransformBuilder<Map<String, dynamic>?> {
  final Map<String, dynamic>? data;

  FakeAwaitableSingle(this.data);

  @override
  Future<R> then<R>(
    FutureOr<R> Function(Map<String, dynamic>?) onValue,
    {Function? onError}
  ) {
    try {
      final result = onValue(data);
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
  Stream<Map<String, dynamic>?> asStream() => Stream.value(data);

  @override
  Future<Map<String, dynamic>?> catchError(Function onError, {bool Function(Object)? test}) {
    return Future.value(data).catchError(onError, test: test);
  }

  @override
  Future<Map<String, dynamic>?> whenComplete(FutureOr<void> Function() action) {
    return Future.value(data).whenComplete(action);
  }

  @override
  Future<Map<String, dynamic>?> timeout(
    Duration timeLimit, {
    FutureOr<Map<String, dynamic>?> Function()? onTimeout,
  }) {
    return Future.value(data);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<String, dynamic> _row({
  String slug = 'elec-001',
  String name = 'Smart Watch Ultra',
  String categoryKey = 'electronics',
  double price = 199.99,
  double oldPrice = 319.99,
}) {
  return {
    'slug': slug,
    'name': name,
    'subtitle': 'Fitness & Health Tracking',
    'description': 'Premium smartwatch.',
    'price': price,
    'old_price': oldPrice,
    'rating': 4.6,
    'review_count': 1847,
    'stock': 45,
    'brand': 'TechPro',
    'seller': 'TechPro Official Store',
    'specifications': {'Display': '1.9" AMOLED'},
    'features': ['GPS + GLONASS navigation'],
    'badges': ['Best Seller'],
    'categories': {'key': categoryKey},
    'product_images': const [],
  };
}

void main() {
  group('ProductRemoteDataSource', () {
    late MockSupabaseClient mockSupabase;
    late ProductRemoteDataSource dataSource;

    setUp(() {
      mockSupabase = MockSupabaseClient();
      dataSource = ProductRemoteDataSource(mockSupabase);
    });

    group('Constructor', () {
      test('creates instance with provided SupabaseClient', () {
        expect(dataSource, isA<ProductRemoteDataSource>());
      });
    });

    group('fetchProducts', () {
      test('returns mapped Products from the products table', () async {
        when(() => mockSupabase.from('products')).thenAnswer(
          (_) => FakeProductQueryBuilder(listData: [_row(), _row(slug: 'elec-002', name: 'Wireless Earbuds Pro')]),
        );

        final result = await dataSource.fetchProducts();

        expect(result, hasLength(2));
        expect(result, everyElement(isA<Product>()));
        expect(result[0].id, 'elec-001');
        expect(result[1].id, 'elec-002');
      });

      test('queries the products table', () async {
        when(() => mockSupabase.from('products'))
            .thenAnswer((_) => FakeProductQueryBuilder(listData: [_row()]));

        await dataSource.fetchProducts();

        verify(() => mockSupabase.from('products')).called(1);
      });

      test('returns an empty list when there are no active products', () async {
        when(() => mockSupabase.from('products'))
            .thenAnswer((_) => FakeProductQueryBuilder(listData: const []));

        final result = await dataSource.fetchProducts();

        expect(result, isEmpty);
      });

      test('wraps a database error in ProductException', () async {
        when(() => mockSupabase.from('products'))
            .thenThrow(PostgrestException(message: 'connection refused'));

        expect(
          () => dataSource.fetchProducts(),
          throwsA(isA<ProductException>().having(
            (e) => e.message,
            'message',
            contains('Failed to load products'),
          )),
        );
      });

      test('wraps a generic exception in ProductException', () async {
        when(() => mockSupabase.from('products')).thenThrow(Exception('boom'));

        expect(
          () => dataSource.fetchProducts(),
          throwsA(isA<ProductException>()),
        );
      });
    });

    group('fetchProductById', () {
      test('returns the mapped Product when found', () async {
        when(() => mockSupabase.from('products'))
            .thenAnswer((_) => FakeProductQueryBuilder(singleData: _row()));

        final result = await dataSource.fetchProductById('elec-001');

        expect(result, isNotNull);
        expect(result!.id, 'elec-001');
        expect(result.name, 'Smart Watch Ultra');
      });

      test('returns null when no active product matches', () async {
        when(() => mockSupabase.from('products'))
            .thenAnswer((_) => FakeProductQueryBuilder(singleData: null));

        final result = await dataSource.fetchProductById('does-not-exist');

        expect(result, isNull);
      });

      test('wraps a database error in ProductException', () async {
        when(() => mockSupabase.from('products'))
            .thenThrow(PostgrestException(message: 'timeout'));

        expect(
          () => dataSource.fetchProductById('elec-001'),
          throwsA(isA<ProductException>().having(
            (e) => e.message,
            'message',
            contains('Failed to load product'),
          )),
        );
      });
    });

    group('fetchProductsByCategory', () {
      test('returns products for the given category', () async {
        when(() => mockSupabase.from('products')).thenAnswer(
          (_) => FakeProductQueryBuilder(listData: [_row(categoryKey: 'clothing', slug: 'cloth-001')]),
        );

        final result = await dataSource.fetchProductsByCategory('clothing');

        expect(result, hasLength(1));
        expect(result.single.category, 'clothing');
      });

      test('returns an empty list when the category has no active products', () async {
        when(() => mockSupabase.from('products'))
            .thenAnswer((_) => FakeProductQueryBuilder(listData: const []));

        final result = await dataSource.fetchProductsByCategory('cosmetics');

        expect(result, isEmpty);
      });

      test('wraps a database error in ProductException with the category name', () async {
        when(() => mockSupabase.from('products'))
            .thenThrow(PostgrestException(message: 'bad filter'));

        expect(
          () => dataSource.fetchProductsByCategory('electronics'),
          throwsA(isA<ProductException>().having(
            (e) => e.message,
            'message',
            contains('electronics'),
          )),
        );
      });
    });
  });
}
