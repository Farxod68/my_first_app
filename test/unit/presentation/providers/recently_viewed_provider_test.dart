import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_first_app/presentation/providers/recently_viewed_provider.dart';
import 'package:my_first_app/core/constants/app_constants.dart';
import '../../../mocks/mock_persistence_service.dart';
import '../../../helpers/test_data.dart';

void main() {
  group('RecentlyViewedProvider', () {
    late MockPersistenceService mockPersistenceService;
    late RecentlyViewedProvider provider;

    setUp(() {
      mockPersistenceService = MockPersistenceService();
      // Default: no saved recently viewed (returns empty list)
      when(() => mockPersistenceService.loadRecentlyViewed()).thenReturn([]);
    });

    tearDown(() {
      try {
        provider.dispose();
      } catch (_) {
        // Already disposed or never initialized
      }
    });

    group('Initialization', () {
      test('constructor calls _loadRecentlyViewed', () async {
        provider = RecentlyViewedProvider(mockPersistenceService);

        await Future.delayed(Duration.zero);

        verify(() => mockPersistenceService.loadRecentlyViewed()).called(1);
      });

      test('initial state with no saved data has empty list', () async {
        provider = RecentlyViewedProvider(mockPersistenceService);

        await Future.delayed(Duration.zero);

        expect(provider.recentlyViewedIds, isEmpty);
        expect(provider.count, equals(0));
        expect(provider.isLoaded, isTrue);
      });

      test('loads saved IDs from persistence', () async {
        when(() => mockPersistenceService.loadRecentlyViewed())
            .thenReturn(['product1', 'product2', 'product3']);

        provider = RecentlyViewedProvider(mockPersistenceService);

        await Future.delayed(Duration.zero);

        expect(provider.recentlyViewedIds, equals(['product1', 'product2', 'product3']));
        expect(provider.count, equals(3));
      });

      test('marks as loaded after initialization', () async {
        provider = RecentlyViewedProvider(mockPersistenceService);

        await Future.delayed(Duration.zero);

        expect(provider.isLoaded, isTrue);
      });

      test('handles persistence error gracefully', () async {
        when(() => mockPersistenceService.loadRecentlyViewed())
            .thenThrow(Exception('Storage error'));

        provider = RecentlyViewedProvider(mockPersistenceService);

        await Future.delayed(Duration.zero);

        expect(provider.recentlyViewedIds, isEmpty);
        expect(provider.isLoaded, isTrue);
      });

      test('handles corrupted data gracefully', () async {
        when(() => mockPersistenceService.loadRecentlyViewed())
            .thenThrow(FormatException('Invalid format'));

        provider = RecentlyViewedProvider(mockPersistenceService);

        await Future.delayed(Duration.zero);

        expect(provider.recentlyViewedIds, isEmpty);
        expect(provider.isLoaded, isTrue);
      });
    });

    group('Getters', () {
      setUp(() async {
        provider = RecentlyViewedProvider(mockPersistenceService);
        await Future.delayed(Duration.zero);
      });

      test('recentlyViewedIds returns empty list initially', () {
        expect(provider.recentlyViewedIds, isEmpty);
      });

      test('count returns 0 for empty list', () {
        expect(provider.count, equals(0));
      });

      test('recentlyViewedIds returns unmodifiable list', () {
        expect(provider.recentlyViewedIds, isA<List<String>>());
        // Should not be able to modify the returned list
        expect(
          () => (provider.recentlyViewedIds as List).add('test'),
          throwsUnsupportedError,
        );
      });

      test('count reflects list length', () async {
        when(() => mockPersistenceService.saveRecentlyViewed(any()))
            .thenAnswer((_) async => true);

        provider.addProduct('product1');
        expect(provider.count, equals(1));

        provider.addProduct('product2');
        expect(provider.count, equals(2));

        provider.addProduct('product3');
        expect(provider.count, equals(3));
      });
    });

    group('addProduct', () {
      setUp(() async {
        provider = RecentlyViewedProvider(mockPersistenceService);
        await Future.delayed(Duration.zero);
        when(() => mockPersistenceService.saveRecentlyViewed(any()))
            .thenAnswer((_) async => true);
      });

      test('adds product ID to front of list', () {
        provider.addProduct('product1');

        expect(provider.recentlyViewedIds, equals(['product1']));
        expect(provider.count, equals(1));
      });

      test('adds multiple products in order (most recent first)', () {
        provider.addProduct('product1');
        provider.addProduct('product2');
        provider.addProduct('product3');

        expect(provider.recentlyViewedIds, equals(['product3', 'product2', 'product1']));
      });

      test('moves existing product to front', () {
        provider.addProduct('product1');
        provider.addProduct('product2');
        provider.addProduct('product3');

        // Re-view product1
        provider.addProduct('product1');

        expect(provider.recentlyViewedIds, equals(['product1', 'product3', 'product2']));
        expect(provider.count, equals(3)); // Still 3, not 4
      });

      test('maintains max size limit', () {
        // Add max + 5 products
        for (int i = 1; i <= AppConfig.maxRecentlyViewed + 5; i++) {
          provider.addProduct('product$i');
        }

        expect(provider.count, equals(AppConfig.maxRecentlyViewed));
        expect(provider.recentlyViewedIds.length, equals(AppConfig.maxRecentlyViewed));
      });

      test('removes oldest when exceeding max size', () {
        // Add 21 products (max is 20)
        for (int i = 1; i <= 21; i++) {
          provider.addProduct('product$i');
        }

        // Should contain products 21 down to 2 (product1 removed)
        expect(provider.recentlyViewedIds.first, equals('product21'));
        expect(provider.recentlyViewedIds, isNot(contains('product1')));
        expect(provider.recentlyViewedIds.length, equals(20));
      });

      test('calls _saveRecentlyViewed after add', () async {
        provider.addProduct('product1');

        await Future.delayed(Duration.zero);

        verify(() => mockPersistenceService.saveRecentlyViewed(['product1']))
            .called(1);
      });

      test('notifies listeners on add', () {
        var listenerCallCount = 0;
        provider.addListener(() => listenerCallCount++);

        provider.addProduct('product1');

        expect(listenerCallCount, equals(1));
      });

      test('handles duplicate additions correctly', () {
        provider.addProduct('product1');
        provider.addProduct('product1');
        provider.addProduct('product1');

        expect(provider.recentlyViewedIds, equals(['product1']));
        expect(provider.count, equals(1));
      });

      test('preserves order (most recent first)', () {
        provider.addProduct('A');
        provider.addProduct('B');
        provider.addProduct('C');

        expect(provider.recentlyViewedIds[0], equals('C')); // Most recent
        expect(provider.recentlyViewedIds[1], equals('B'));
        expect(provider.recentlyViewedIds[2], equals('A')); // Oldest
      });

      test('handles persistence error silently', () async {
        when(() => mockPersistenceService.saveRecentlyViewed(any()))
            .thenThrow(Exception('Save failed'));

        // Should not throw
        expect(() => provider.addProduct('product1'), returnsNormally);

        // State should still be updated
        expect(provider.recentlyViewedIds, contains('product1'));
      });

      test('notifies listeners on each add', () {
        var listenerCallCount = 0;
        provider.addListener(() => listenerCallCount++);

        provider.addProduct('product1');
        provider.addProduct('product2');
        provider.addProduct('product3');

        expect(listenerCallCount, equals(3));
      });

      test('moving existing product to front notifies listeners', () {
        provider.addProduct('product1');
        provider.addProduct('product2');

        var listenerCallCount = 0;
        provider.addListener(() => listenerCallCount++);

        provider.addProduct('product1'); // Move to front

        expect(listenerCallCount, equals(1));
      });
    });

    group('clearRecentlyViewed', () {
      setUp(() async {
        provider = RecentlyViewedProvider(mockPersistenceService);
        await Future.delayed(Duration.zero);
        when(() => mockPersistenceService.saveRecentlyViewed(any()))
            .thenAnswer((_) async => true);
      });

      test('removes all items', () {
        provider.addProduct('product1');
        provider.addProduct('product2');
        provider.addProduct('product3');

        provider.clearRecentlyViewed();

        expect(provider.recentlyViewedIds, isEmpty);
      });

      test('sets count to 0', () {
        provider.addProduct('product1');
        provider.addProduct('product2');

        provider.clearRecentlyViewed();

        expect(provider.count, equals(0));
      });

      test('calls _saveRecentlyViewed after clear', () async {
        provider.addProduct('product1');

        // Reset mock to only count clearRecentlyViewed call
        reset(mockPersistenceService);
        when(() => mockPersistenceService.saveRecentlyViewed(any()))
            .thenAnswer((_) async => true);

        provider.clearRecentlyViewed();

        await Future.delayed(Duration.zero);

        verify(() => mockPersistenceService.saveRecentlyViewed([])).called(1);
      });

      test('notifies listeners', () {
        provider.addProduct('product1');

        var listenerCallCount = 0;
        provider.addListener(() => listenerCallCount++);

        provider.clearRecentlyViewed();

        expect(listenerCallCount, equals(1));
      });

      test('is idempotent (safe to call on empty list)', () {
        provider.clearRecentlyViewed();
        provider.clearRecentlyViewed();

        expect(provider.recentlyViewedIds, isEmpty);
      });

      test('handles persistence error silently', () async {
        when(() => mockPersistenceService.saveRecentlyViewed(any()))
            .thenThrow(Exception('Save failed'));

        provider.addProduct('product1');

        // Should not throw
        expect(() => provider.clearRecentlyViewed(), returnsNormally);

        // State should still be updated
        expect(provider.recentlyViewedIds, isEmpty);
      });
    });

    group('getRecentlyViewedProducts', () {
      setUp(() async {
        provider = RecentlyViewedProvider(mockPersistenceService);
        await Future.delayed(Duration.zero);
        when(() => mockPersistenceService.saveRecentlyViewed(any()))
            .thenAnswer((_) async => true);
      });

      test('returns empty list for empty recently viewed', () {
        final products = TestData.createProductList(10);

        final result = provider.getRecentlyViewedProducts(products);

        expect(result, isEmpty);
      });

      test('returns products in viewed order', () {
        final products = TestData.createProductList(5);

        provider.addProduct('test_product_3');
        provider.addProduct('test_product_1');
        provider.addProduct('test_product_5');

        final result = provider.getRecentlyViewedProducts(products);

        expect(result.length, equals(3));
        expect(result[0].id, equals('test_product_5')); // Most recent
        expect(result[1].id, equals('test_product_1'));
        expect(result[2].id, equals('test_product_3')); // Oldest
      });

      test('filters out non-existent product IDs', () {
        final products = TestData.createProductList(3);

        provider.addProduct('test_product_1');
        provider.addProduct('nonexistent_product');
        provider.addProduct('test_product_2');

        final result = provider.getRecentlyViewedProducts(products);

        expect(result.length, equals(2));
        expect(result[0].id, equals('test_product_2'));
        expect(result[1].id, equals('test_product_1'));
      });

      test('handles large product list efficiently', () {
        final products = TestData.createProductList(100);

        provider.addProduct('test_product_50');
        provider.addProduct('test_product_10');
        provider.addProduct('test_product_90');

        final result = provider.getRecentlyViewedProducts(products);

        expect(result.length, equals(3));
        expect(result[0].id, equals('test_product_90'));
        expect(result[1].id, equals('test_product_10'));
        expect(result[2].id, equals('test_product_50'));
      });

      test('returns empty list when no products match', () {
        final products = TestData.createProductList(5);

        provider.addProduct('nonexistent1');
        provider.addProduct('nonexistent2');

        final result = provider.getRecentlyViewedProducts(products);

        expect(result, isEmpty);
      });

      test('maintains recency order with partial matches', () {
        final products = TestData.createProductList(10);

        // Add some IDs that exist and some that don't
        provider.addProduct('test_product_1');
        provider.addProduct('nonexistent');
        provider.addProduct('test_product_5');
        provider.addProduct('another_nonexistent');
        provider.addProduct('test_product_3');

        final result = provider.getRecentlyViewedProducts(products);

        expect(result.length, equals(3));
        expect(result[0].id, equals('test_product_3')); // Most recent match
        expect(result[1].id, equals('test_product_5'));
        expect(result[2].id, equals('test_product_1')); // Oldest match
      });

      test('works with empty product list', () {
        provider.addProduct('product1');
        provider.addProduct('product2');

        final result = provider.getRecentlyViewedProducts([]);

        expect(result, isEmpty);
      });

      test('returns correct Product objects', () {
        final products = TestData.createProductList(3);

        provider.addProduct('test_product_2');

        final result = provider.getRecentlyViewedProducts(products);

        expect(result.length, equals(1));
        expect(result[0].id, equals('test_product_2'));
        expect(result[0].name, equals('Test Product 2'));
        expect(result[0].category, equals('Electronics'));
      });
    });

    group('Persistence', () {
      setUp(() async {
        provider = RecentlyViewedProvider(mockPersistenceService);
        await Future.delayed(Duration.zero);
        when(() => mockPersistenceService.saveRecentlyViewed(any()))
            .thenAnswer((_) async => true);
      });

      test('_saveRecentlyViewed persists IDs', () async {
        provider.addProduct('product1');

        // Reset mock to only count product2 call
        reset(mockPersistenceService);
        when(() => mockPersistenceService.saveRecentlyViewed(any()))
            .thenAnswer((_) async => true);

        provider.addProduct('product2');

        await Future.delayed(Duration.zero);

        verify(() => mockPersistenceService
            .saveRecentlyViewed(['product2', 'product1'])).called(1);
      });

      test('_loadRecentlyViewed retrieves saved IDs', () async {
        when(() => mockPersistenceService.loadRecentlyViewed())
            .thenReturn(['id1', 'id2', 'id3']);

        final newProvider = RecentlyViewedProvider(mockPersistenceService);

        await Future.delayed(Duration.zero);

        expect(newProvider.recentlyViewedIds, equals(['id1', 'id2', 'id3']));

        newProvider.dispose();
      });

      test('persistence roundtrip works correctly', () async {
        provider.addProduct('product1');
        provider.addProduct('product2');
        provider.addProduct('product3');

        await Future.delayed(Duration.zero);

        final savedIds = ['product3', 'product2', 'product1'];
        // Verify that the final state was saved (may be called 3 times, once per add)
        verify(() => mockPersistenceService.saveRecentlyViewed(savedIds))
            .called(greaterThanOrEqualTo(1));

        // Simulate loading in a new provider
        when(() => mockPersistenceService.loadRecentlyViewed())
            .thenReturn(savedIds);

        final newProvider = RecentlyViewedProvider(mockPersistenceService);

        await Future.delayed(Duration.zero);

        expect(newProvider.recentlyViewedIds, equals(savedIds));
        expect(newProvider.count, equals(3));

        newProvider.dispose();
      });

      test('handles save error without throwing', () async {
        when(() => mockPersistenceService.saveRecentlyViewed(any()))
            .thenThrow(Exception('Save failed'));

        expect(() => provider.addProduct('product1'), returnsNormally);

        // State should still be updated despite save failure
        expect(provider.recentlyViewedIds, contains('product1'));
      });

      test('handles load error without throwing', () async {
        when(() => mockPersistenceService.loadRecentlyViewed())
            .thenThrow(Exception('Load failed'));

        final newProvider = RecentlyViewedProvider(mockPersistenceService);

        await Future.delayed(Duration.zero);

        expect(newProvider.recentlyViewedIds, isEmpty);
        expect(newProvider.isLoaded, isTrue);

        newProvider.dispose();
      });

      test('saves after each operation', () async {
        provider.addProduct('product1');
        await Future.delayed(Duration.zero);

        provider.addProduct('product2');
        await Future.delayed(Duration.zero);

        provider.clearRecentlyViewed();
        await Future.delayed(Duration.zero);

        // Should have saved 3 times
        verify(() => mockPersistenceService.saveRecentlyViewed(any()))
            .called(3);
      });
    });

    group('Edge Cases', () {
      setUp(() async {
        provider = RecentlyViewedProvider(mockPersistenceService);
        await Future.delayed(Duration.zero);
        when(() => mockPersistenceService.saveRecentlyViewed(any()))
            .thenAnswer((_) async => true);
      });

      test('handles empty product ID gracefully', () {
        provider.addProduct('');

        expect(provider.recentlyViewedIds, contains(''));
        expect(provider.count, equals(1));
      });

      test('handles very long product IDs', () {
        final longId = 'x' * 1000;
        provider.addProduct(longId);

        expect(provider.recentlyViewedIds, contains(longId));
      });

      test('handles special characters in IDs', () {
        provider.addProduct('product-123_ABC.test');
        provider.addProduct('product@#\$%');

        expect(provider.count, equals(2));
      });

      test('rapid additions process correctly', () {
        for (int i = 1; i <= 50; i++) {
          provider.addProduct('product$i');
        }

        expect(provider.count, equals(AppConfig.maxRecentlyViewed));
        expect(provider.recentlyViewedIds.first, equals('product50'));
      });

      test('can be disposed after operations', () {
        provider.addProduct('product1');
        provider.clearRecentlyViewed();

        expect(() => provider.dispose(), returnsNormally);
      });

      test('operations after dispose throw in debug mode', () {
        provider.dispose();

        expect(() => provider.addProduct('product1'), throwsFlutterError);
      });

      test('addProduct with same ID multiple times in succession', () {
        provider.addProduct('product1');
        provider.addProduct('product1');
        provider.addProduct('product1');

        expect(provider.count, equals(1));
        expect(provider.recentlyViewedIds, equals(['product1']));
      });

      test('alternating add and clear operations', () {
        provider.addProduct('product1');
        provider.clearRecentlyViewed();
        provider.addProduct('product2');
        provider.clearRecentlyViewed();
        provider.addProduct('product3');

        expect(provider.recentlyViewedIds, equals(['product3']));
        expect(provider.count, equals(1));
      });

      test('getRecentlyViewedProducts with all non-existent IDs', () {
        final products = TestData.createProductList(5);

        provider.addProduct('fake1');
        provider.addProduct('fake2');
        provider.addProduct('fake3');

        final result = provider.getRecentlyViewedProducts(products);

        expect(result, isEmpty);
      });

      test('maximum size boundary exactly at limit', () {
        for (int i = 1; i <= AppConfig.maxRecentlyViewed; i++) {
          provider.addProduct('product$i');
        }

        expect(provider.count, equals(AppConfig.maxRecentlyViewed));

        // Add one more
        provider.addProduct('product_new');

        expect(provider.count, equals(AppConfig.maxRecentlyViewed));
        expect(provider.recentlyViewedIds.first, equals('product_new'));
        expect(provider.recentlyViewedIds, isNot(contains('product1')));
      });
    });

    group('Listener Notifications', () {
      setUp(() async {
        provider = RecentlyViewedProvider(mockPersistenceService);
        await Future.delayed(Duration.zero);
        when(() => mockPersistenceService.saveRecentlyViewed(any()))
            .thenAnswer((_) async => true);
      });

      test('addProduct notifies listeners once', () {
        var listenerCallCount = 0;
        provider.addListener(() => listenerCallCount++);

        provider.addProduct('product1');

        expect(listenerCallCount, equals(1));
      });

      test('clearRecentlyViewed notifies listeners once', () {
        provider.addProduct('product1');

        var listenerCallCount = 0;
        provider.addListener(() => listenerCallCount++);

        provider.clearRecentlyViewed();

        expect(listenerCallCount, equals(1));
      });

      test('multiple listeners all receive notifications', () {
        var listener1CallCount = 0;
        var listener2CallCount = 0;
        var listener3CallCount = 0;

        provider.addListener(() => listener1CallCount++);
        provider.addListener(() => listener2CallCount++);
        provider.addListener(() => listener3CallCount++);

        provider.addProduct('product1');

        expect(listener1CallCount, equals(1));
        expect(listener2CallCount, equals(1));
        expect(listener3CallCount, equals(1));
      });

      test('removed listener does not receive notification', () {
        var removedListenerCallCount = 0;
        var activeListenerCallCount = 0;

        void removedListener() => removedListenerCallCount++;
        void activeListener() => activeListenerCallCount++;

        provider.addListener(removedListener);
        provider.addListener(activeListener);

        provider.removeListener(removedListener);
        provider.addProduct('product1');

        expect(removedListenerCallCount, equals(0));
        expect(activeListenerCallCount, equals(1));
      });

      test('getRecentlyViewedProducts does not notify listeners', () {
        final products = TestData.createProductList(3);
        provider.addProduct('test_product_1');

        var listenerCallCount = 0;
        provider.addListener(() => listenerCallCount++);

        provider.getRecentlyViewedProducts(products);

        expect(listenerCallCount, equals(0));
      });
    });
  });
}
