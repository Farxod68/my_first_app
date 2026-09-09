import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_first_app/data/repositories/product_repository_impl.dart';
import 'package:my_first_app/data/models/product.dart';
import '../../../helpers/test_data.dart';
import '../../../mocks/mock_product_remote_data_source.dart';

void main() {
  group('ProductRepositoryImpl', () {
    late MockProductRemoteDataSource mockDataSource;
    late ProductRepositoryImpl repository;

    final testProducts = [
      TestData.createTestProduct(id: 'elec-001', name: 'Smart Watch Ultra', category: 'electronics'),
      TestData.createTestProduct(id: 'cloth-001', name: 'Running Shoes Pro', category: 'clothing'),
    ];

    setUp(() {
      mockDataSource = MockProductRemoteDataSource();
      repository = ProductRepositoryImpl(mockDataSource);
    });

    group('Constructor', () {
      test('creates instance with data source', () {
        expect(repository, isA<ProductRepositoryImpl>());
      });
    });

    group('fetchProducts', () {
      test('returns products from the data source unchanged', () async {
        when(() => mockDataSource.fetchProducts()).thenAnswer((_) async => testProducts);

        final result = await repository.fetchProducts();

        expect(result, same(testProducts));
        verify(() => mockDataSource.fetchProducts()).called(1);
      });

      test('returns an empty list when the data source returns none', () async {
        when(() => mockDataSource.fetchProducts()).thenAnswer((_) async => const <Product>[]);

        final result = await repository.fetchProducts();

        expect(result, isEmpty);
      });

      test('propagates exception from data source', () async {
        when(() => mockDataSource.fetchProducts()).thenThrow(Exception('Network error'));

        expect(
          () => repository.fetchProducts(),
          throwsA(isA<Exception>()),
        );
      });

      test('can be called multiple times', () async {
        when(() => mockDataSource.fetchProducts()).thenAnswer((_) async => testProducts);

        await repository.fetchProducts();
        await repository.fetchProducts();

        verify(() => mockDataSource.fetchProducts()).called(2);
      });
    });

    group('fetchProductById', () {
      test('returns the product from the data source', () async {
        when(() => mockDataSource.fetchProductById('elec-001'))
            .thenAnswer((_) async => testProducts.first);

        final result = await repository.fetchProductById('elec-001');

        expect(result, same(testProducts.first));
        verify(() => mockDataSource.fetchProductById('elec-001')).called(1);
      });

      test('returns null when the data source returns null', () async {
        when(() => mockDataSource.fetchProductById(any())).thenAnswer((_) async => null);

        final result = await repository.fetchProductById('does-not-exist');

        expect(result, isNull);
      });

      test('propagates exception from data source', () async {
        when(() => mockDataSource.fetchProductById(any())).thenThrow(Exception('Not found'));

        expect(
          () => repository.fetchProductById('elec-001'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('fetchProductsByCategory', () {
      test('returns products from the data source for the given category', () async {
        when(() => mockDataSource.fetchProductsByCategory('electronics'))
            .thenAnswer((_) async => [testProducts.first]);

        final result = await repository.fetchProductsByCategory('electronics');

        expect(result, [testProducts.first]);
        verify(() => mockDataSource.fetchProductsByCategory('electronics')).called(1);
      });

      test('returns an empty list for a category with no products', () async {
        when(() => mockDataSource.fetchProductsByCategory(any()))
            .thenAnswer((_) async => const <Product>[]);

        final result = await repository.fetchProductsByCategory('cosmetics');

        expect(result, isEmpty);
      });

      test('propagates exception from data source', () async {
        when(() => mockDataSource.fetchProductsByCategory(any()))
            .thenThrow(Exception('Category query failed'));

        expect(
          () => repository.fetchProductsByCategory('electronics'),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
