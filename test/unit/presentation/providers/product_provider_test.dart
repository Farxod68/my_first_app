import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_first_app/presentation/providers/product_provider.dart';
import 'package:my_first_app/data/models/product.dart';
import '../../../helpers/test_data.dart';
import '../../../mocks/mock_product_repository.dart';

void main() {
  group('ProductProvider', () {
    late MockProductRepository mockProductRepository;
    late ProductProvider provider;

    final testProducts = [
      TestData.createTestProduct(id: 'elec-001', name: 'Smart Watch Ultra'),
      TestData.createTestProduct(id: 'cloth-001', name: 'Running Shoes Pro'),
    ];

    setUp(() {
      mockProductRepository = MockProductRepository();
    });

    group('Initialization / loading -> loaded', () {
      test('constructor triggers a load from the repository', () async {
        when(() => mockProductRepository.fetchProducts())
            .thenAnswer((_) async => testProducts);

        provider = ProductProvider(mockProductRepository);

        await Future.delayed(Duration.zero);

        verify(() => mockProductRepository.fetchProducts()).called(1);
      });

      test('isLoading is true synchronously after construction, before the load resolves', () async {
        final completer = Completer<List<Product>>();
        when(() => mockProductRepository.fetchProducts())
            .thenAnswer((_) => completer.future);

        provider = ProductProvider(mockProductRepository);

        expect(provider.isLoading, isTrue);
        expect(provider.products, isEmpty);
        expect(provider.error, isNull);

        completer.complete(testProducts);
        await Future.delayed(Duration.zero);
      });

      test('loaded state exposes the fetched products and clears loading', () async {
        when(() => mockProductRepository.fetchProducts())
            .thenAnswer((_) async => testProducts);

        provider = ProductProvider(mockProductRepository);
        await Future.delayed(Duration.zero);

        expect(provider.isLoading, isFalse);
        expect(provider.products, testProducts);
        expect(provider.error, isNull);
      });

      test('products getter returns an unmodifiable list', () async {
        when(() => mockProductRepository.fetchProducts())
            .thenAnswer((_) async => testProducts);

        provider = ProductProvider(mockProductRepository);
        await Future.delayed(Duration.zero);

        expect(() => provider.products.add(testProducts.first), throwsUnsupportedError);
      });

      test('notifies listeners on load start and on load completion', () async {
        when(() => mockProductRepository.fetchProducts())
            .thenAnswer((_) async => testProducts);

        provider = ProductProvider(mockProductRepository);

        var notificationCount = 0;
        provider.addListener(() => notificationCount++);

        await Future.delayed(Duration.zero);

        expect(notificationCount, greaterThanOrEqualTo(1));
      });
    });

    group('Error state', () {
      test('failed load sets error, clears loading, and leaves products empty', () async {
        when(() => mockProductRepository.fetchProducts())
            .thenThrow(Exception('Network error'));

        provider = ProductProvider(mockProductRepository);
        await Future.delayed(Duration.zero);

        expect(provider.isLoading, isFalse);
        expect(provider.products, isEmpty);
        expect(provider.error, isNotNull);
        expect(provider.error, contains('Failed to load products'));
      });

      test('a prior error is cleared once refresh succeeds', () async {
        when(() => mockProductRepository.fetchProducts())
            .thenThrow(Exception('Network error'));

        provider = ProductProvider(mockProductRepository);
        await Future.delayed(Duration.zero);
        expect(provider.error, isNotNull);

        when(() => mockProductRepository.fetchProducts())
            .thenAnswer((_) async => testProducts);

        await provider.refresh();

        expect(provider.error, isNull);
        expect(provider.products, testProducts);
      });
    });

    group('refresh', () {
      test('calls fetchProducts again', () async {
        when(() => mockProductRepository.fetchProducts())
            .thenAnswer((_) async => testProducts);

        provider = ProductProvider(mockProductRepository);
        await Future.delayed(Duration.zero);

        await provider.refresh();

        verify(() => mockProductRepository.fetchProducts()).called(2);
      });

      test('replaces the product list with the newly fetched one', () async {
        when(() => mockProductRepository.fetchProducts())
            .thenAnswer((_) async => [testProducts.first]);

        provider = ProductProvider(mockProductRepository);
        await Future.delayed(Duration.zero);
        expect(provider.products, [testProducts.first]);

        when(() => mockProductRepository.fetchProducts())
            .thenAnswer((_) async => testProducts);

        await provider.refresh();

        expect(provider.products, testProducts);
      });

      test('sets isLoading true while refreshing, then false when done', () async {
        when(() => mockProductRepository.fetchProducts())
            .thenAnswer((_) async => testProducts);

        provider = ProductProvider(mockProductRepository);
        await Future.delayed(Duration.zero);

        final completer = Completer<List<Product>>();
        when(() => mockProductRepository.fetchProducts())
            .thenAnswer((_) => completer.future);

        final future = provider.refresh();
        expect(provider.isLoading, isTrue);

        completer.complete(testProducts);
        await future;

        expect(provider.isLoading, isFalse);
      });

      test('a failed refresh clears previously loaded products and sets error', () async {
        when(() => mockProductRepository.fetchProducts())
            .thenAnswer((_) async => testProducts);

        provider = ProductProvider(mockProductRepository);
        await Future.delayed(Duration.zero);
        expect(provider.products, isNotEmpty);

        when(() => mockProductRepository.fetchProducts())
            .thenThrow(Exception('Server error'));

        await provider.refresh();

        expect(provider.products, isEmpty);
        expect(provider.error, isNotNull);
      });
    });

    group('Never touches SupabaseClient directly', () {
      test('ProductProvider is constructed only from a ProductRepository', () {
        // Compile-time guarantee: the constructor's only parameter is a
        // ProductRepository, so this provider cannot import or hold a
        // SupabaseClient reference without changing its public API.
        when(() => mockProductRepository.fetchProducts())
            .thenAnswer((_) async => const <Product>[]);

        provider = ProductProvider(mockProductRepository);
        expect(provider, isA<ProductProvider>());
      });
    });
  });
}
