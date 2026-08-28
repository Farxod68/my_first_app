import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_first_app/presentation/providers/wishlist_provider.dart';
import '../../../mocks/mock_persistence_service.dart';
import '../../../helpers/test_data.dart';

void main() {
  group('WishlistProvider', () {
    late MockPersistenceService mockPersistenceService;
    late WishlistProvider provider;

    setUp(() {
      mockPersistenceService = MockPersistenceService();
      // Default: no saved wishlist (returns empty list)
      when(() => mockPersistenceService.loadWishlist()).thenReturn([]);
      when(() => mockPersistenceService.saveWishlist(any()))
          .thenAnswer((_) async => true);
    });

    tearDown(() {
      try {
        provider.dispose();
      } catch (_) {
        // Already disposed or never initialized
      }
    });

    group('Initialization', () {
      test('constructor calls _loadWishlist', () async {
        provider = WishlistProvider(mockPersistenceService);

        await Future.delayed(Duration.zero);

        verify(() => mockPersistenceService.loadWishlist()).called(1);
      });

      test('initial state with no saved data has empty wishlist', () async {
        provider = WishlistProvider(mockPersistenceService);

        await Future.delayed(Duration.zero);

        expect(provider.favoriteProductIds, isEmpty);
        expect(provider.count, equals(0));
        expect(provider.isLoaded, isTrue);
      });

      test('loads saved product IDs from persistence', () async {
        when(() => mockPersistenceService.loadWishlist())
            .thenReturn(['product1', 'product2', 'product3']);

        provider = WishlistProvider(mockPersistenceService);

        await Future.delayed(Duration.zero);

        expect(provider.favoriteProductIds, equals({'product1', 'product2', 'product3'}));
        expect(provider.count, equals(3));
      });

      test('marks as loaded after initialization', () async {
        provider = WishlistProvider(mockPersistenceService);

        await Future.delayed(Duration.zero);

        expect(provider.isLoaded, isTrue);
      });

      test('handles persistence error gracefully', () async {
        when(() => mockPersistenceService.loadWishlist())
            .thenThrow(Exception('Storage error'));

        provider = WishlistProvider(mockPersistenceService);

        await Future.delayed(Duration.zero);

        expect(provider.favoriteProductIds, isEmpty);
        expect(provider.isLoaded, isTrue);
      });

      test('handles corrupted data gracefully', () async {
        when(() => mockPersistenceService.loadWishlist())
            .thenThrow(FormatException('Invalid format'));

        provider = WishlistProvider(mockPersistenceService);

        await Future.delayed(Duration.zero);

        expect(provider.favoriteProductIds, isEmpty);
        expect(provider.isLoaded, isTrue);
      });

      test('handles empty saved wishlist', () async {
        when(() => mockPersistenceService.loadWishlist()).thenReturn([]);

        provider = WishlistProvider(mockPersistenceService);

        await Future.delayed(Duration.zero);

        expect(provider.favoriteProductIds, isEmpty);
        expect(provider.count, equals(0));
      });
    });

    group('Getters', () {
      setUp(() async {
        provider = WishlistProvider(mockPersistenceService);
        await Future.delayed(Duration.zero);
        reset(mockPersistenceService);
        when(() => mockPersistenceService.saveWishlist(any()))
            .thenAnswer((_) async => true);
      });

      test('favoriteProductIds returns empty set initially', () {
        expect(provider.favoriteProductIds, isEmpty);
        expect(provider.favoriteProductIds, isA<Set<String>>());
      });

      test('favoriteProductIds returns unmodifiable set', () {
        provider.addToFavorites('product1');

        final ids = provider.favoriteProductIds;
        expect(() => ids.add('product2'), throwsUnsupportedError);
      });

      test('count returns 0 initially', () {
        expect(provider.count, equals(0));
      });

      test('count returns correct number of favorites', () {
        provider.addToFavorites('product1');
        provider.addToFavorites('product2');
        provider.addToFavorites('product3');

        expect(provider.count, equals(3));
      });
    });

    group('isFavorite', () {
      setUp(() async {
        provider = WishlistProvider(mockPersistenceService);
        await Future.delayed(Duration.zero);
        reset(mockPersistenceService);
        when(() => mockPersistenceService.saveWishlist(any()))
            .thenAnswer((_) async => true);
      });

      test('returns false for product not in favorites', () {
        expect(provider.isFavorite('product1'), isFalse);
      });

      test('returns true for product in favorites', () {
        provider.addToFavorites('product1');

        expect(provider.isFavorite('product1'), isTrue);
      });

      test('returns false after removing from favorites', () {
        provider.addToFavorites('product1');
        provider.removeFromFavorites('product1');

        expect(provider.isFavorite('product1'), isFalse);
      });

      test('returns false for empty string ID', () {
        expect(provider.isFavorite(''), isFalse);
      });

      test('handles special characters in product ID', () {
        const specialId = 'product-123_abc@test';
        provider.addToFavorites(specialId);

        expect(provider.isFavorite(specialId), isTrue);
      });
    });

    group('addToFavorites', () {
      setUp(() async {
        provider = WishlistProvider(mockPersistenceService);
        await Future.delayed(Duration.zero);
        reset(mockPersistenceService);
        when(() => mockPersistenceService.saveWishlist(any()))
            .thenAnswer((_) async => true);
      });

      test('adds product to favorites', () {
        provider.addToFavorites('product1');

        expect(provider.favoriteProductIds, contains('product1'));
        expect(provider.count, equals(1));
      });

      test('adding duplicate product is idempotent (Set semantics)', () {
        provider.addToFavorites('product1');
        provider.addToFavorites('product1');

        expect(provider.count, equals(1));
        expect(provider.favoriteProductIds, equals({'product1'}));
      });

      test('adds multiple different products', () {
        provider.addToFavorites('product1');
        provider.addToFavorites('product2');
        provider.addToFavorites('product3');

        expect(provider.count, equals(3));
        expect(provider.favoriteProductIds, equals({'product1', 'product2', 'product3'}));
      });

      test('calls _saveWishlist after add', () async {
        provider.addToFavorites('product1');

        await Future.delayed(Duration.zero);

        verify(() => mockPersistenceService.saveWishlist(['product1'])).called(1);
      });

      test('notifies listeners on add', () {
        var notified = false;
        provider.addListener(() => notified = true);

        provider.addToFavorites('product1');

        expect(notified, isTrue);
      });

      test('handles persistence error silently', () async {
        when(() => mockPersistenceService.saveWishlist(any()))
            .thenThrow(Exception('Save failed'));

        expect(() => provider.addToFavorites('product1'), returnsNormally);
        expect(provider.favoriteProductIds, contains('product1'));
      });

      test('can add after clearing favorites', () {
        provider.addToFavorites('product1');
        provider.clearFavorites();
        provider.addToFavorites('product2');

        expect(provider.favoriteProductIds, equals({'product2'}));
        expect(provider.count, equals(1));
      });
    });

    group('removeFromFavorites', () {
      setUp(() async {
        provider = WishlistProvider(mockPersistenceService);
        await Future.delayed(Duration.zero);
        reset(mockPersistenceService);
        when(() => mockPersistenceService.saveWishlist(any()))
            .thenAnswer((_) async => true);
      });

      test('removes product from favorites', () {
        provider.addToFavorites('product1');
        provider.removeFromFavorites('product1');

        expect(provider.favoriteProductIds, isEmpty);
        expect(provider.count, equals(0));
      });

      test('removing non-existent product is safe', () {
        expect(() => provider.removeFromFavorites('product1'), returnsNormally);
        expect(provider.count, equals(0));
      });

      test('removes only specified product', () {
        provider.addToFavorites('product1');
        provider.addToFavorites('product2');
        provider.addToFavorites('product3');

        provider.removeFromFavorites('product2');

        expect(provider.favoriteProductIds, equals({'product1', 'product3'}));
        expect(provider.count, equals(2));
      });

      test('calls _saveWishlist after remove', () async {
        provider.addToFavorites('product1');
        reset(mockPersistenceService);
        when(() => mockPersistenceService.saveWishlist(any()))
            .thenAnswer((_) async => true);

        provider.removeFromFavorites('product1');

        await Future.delayed(Duration.zero);

        verify(() => mockPersistenceService.saveWishlist([])).called(1);
      });

      test('notifies listeners on remove', () {
        provider.addToFavorites('product1');
        var notified = false;
        provider.addListener(() => notified = true);

        provider.removeFromFavorites('product1');

        expect(notified, isTrue);
      });

      test('handles persistence error silently', () async {
        provider.addToFavorites('product1');
        when(() => mockPersistenceService.saveWishlist(any()))
            .thenThrow(Exception('Save failed'));

        expect(() => provider.removeFromFavorites('product1'), returnsNormally);
        expect(provider.favoriteProductIds, isEmpty);
      });
    });

    group('toggleFavorite', () {
      setUp(() async {
        provider = WishlistProvider(mockPersistenceService);
        await Future.delayed(Duration.zero);
        reset(mockPersistenceService);
        when(() => mockPersistenceService.saveWishlist(any()))
            .thenAnswer((_) async => true);
      });

      test('adds product when not in favorites', () {
        provider.toggleFavorite('product1');

        expect(provider.isFavorite('product1'), isTrue);
        expect(provider.count, equals(1));
      });

      test('removes product when in favorites', () {
        provider.addToFavorites('product1');
        provider.toggleFavorite('product1');

        expect(provider.isFavorite('product1'), isFalse);
        expect(provider.count, equals(0));
      });

      test('toggling twice returns to original state', () {
        provider.toggleFavorite('product1');
        provider.toggleFavorite('product1');

        expect(provider.isFavorite('product1'), isFalse);
        expect(provider.count, equals(0));
      });

      test('toggle adds to empty favorites', () {
        provider.toggleFavorite('product1');

        expect(provider.favoriteProductIds, equals({'product1'}));
      });

      test('toggle removes from favorites with multiple items', () {
        provider.addToFavorites('product1');
        provider.addToFavorites('product2');
        provider.addToFavorites('product3');

        provider.toggleFavorite('product2');

        expect(provider.favoriteProductIds, equals({'product1', 'product3'}));
      });

      test('calls _saveWishlist after toggle', () async {
        provider.toggleFavorite('product1');

        await Future.delayed(Duration.zero);

        verify(() => mockPersistenceService.saveWishlist(['product1'])).called(1);
      });

      test('notifies listeners on toggle', () {
        var notified = false;
        provider.addListener(() => notified = true);

        provider.toggleFavorite('product1');

        expect(notified, isTrue);
      });

      test('rapid toggles process correctly', () {
        provider.toggleFavorite('product1'); // add
        provider.toggleFavorite('product1'); // remove
        provider.toggleFavorite('product1'); // add
        provider.toggleFavorite('product1'); // remove
        provider.toggleFavorite('product1'); // add

        expect(provider.isFavorite('product1'), isTrue);
        expect(provider.count, equals(1));
      });
    });

    group('clearFavorites', () {
      setUp(() async {
        provider = WishlistProvider(mockPersistenceService);
        await Future.delayed(Duration.zero);
        reset(mockPersistenceService);
        when(() => mockPersistenceService.saveWishlist(any()))
            .thenAnswer((_) async => true);
      });

      test('removes all favorites', () {
        provider.addToFavorites('product1');
        provider.addToFavorites('product2');
        provider.addToFavorites('product3');

        provider.clearFavorites();

        expect(provider.favoriteProductIds, isEmpty);
        expect(provider.count, equals(0));
      });

      test('clearing empty favorites is safe', () {
        expect(() => provider.clearFavorites(), returnsNormally);
        expect(provider.count, equals(0));
      });

      test('calls _saveWishlist after clear', () async {
        provider.addToFavorites('product1');
        reset(mockPersistenceService);
        when(() => mockPersistenceService.saveWishlist(any()))
            .thenAnswer((_) async => true);

        provider.clearFavorites();

        await Future.delayed(Duration.zero);

        verify(() => mockPersistenceService.saveWishlist([])).called(1);
      });

      test('notifies listeners on clear', () {
        provider.addToFavorites('product1');
        var notified = false;
        provider.addListener(() => notified = true);

        provider.clearFavorites();

        expect(notified, isTrue);
      });

      test('can add favorites after clearing', () {
        provider.addToFavorites('product1');
        provider.clearFavorites();
        provider.addToFavorites('product2');

        expect(provider.favoriteProductIds, equals({'product2'}));
        expect(provider.count, equals(1));
      });

      test('handles persistence error silently', () async {
        provider.addToFavorites('product1');
        when(() => mockPersistenceService.saveWishlist(any()))
            .thenThrow(Exception('Save failed'));

        expect(() => provider.clearFavorites(), returnsNormally);
        expect(provider.favoriteProductIds, isEmpty);
      });
    });

    group('getFavoriteProducts', () {
      setUp(() async {
        provider = WishlistProvider(mockPersistenceService);
        await Future.delayed(Duration.zero);
        reset(mockPersistenceService);
        when(() => mockPersistenceService.saveWishlist(any()))
            .thenAnswer((_) async => true);
      });

      test('returns empty list when no favorites', () {
        final products = TestData.createProductList(5);

        final favoriteProducts = provider.getFavoriteProducts(products);

        expect(favoriteProducts, isEmpty);
      });

      test('returns only favorited products', () {
        final products = TestData.createProductList(5);
        provider.addToFavorites('test_product_1');
        provider.addToFavorites('test_product_3');
        provider.addToFavorites('test_product_5');

        final favoriteProducts = provider.getFavoriteProducts(products);

        expect(favoriteProducts.length, equals(3));
        expect(favoriteProducts.map((p) => p.id), equals(['test_product_1', 'test_product_3', 'test_product_5']));
      });

      test('returns empty list when product list is empty', () {
        provider.addToFavorites('product1');

        final favoriteProducts = provider.getFavoriteProducts([]);

        expect(favoriteProducts, isEmpty);
      });

      test('filters out non-matching products', () {
        final products = TestData.createProductList(3);
        provider.addToFavorites('product_not_in_list');

        final favoriteProducts = provider.getFavoriteProducts(products);

        expect(favoriteProducts, isEmpty);
      });

      test('returns correct Product objects', () {
        final products = TestData.createProductList(3);
        provider.addToFavorites('test_product_2');

        final favoriteProducts = provider.getFavoriteProducts(products);

        expect(favoriteProducts.length, equals(1));
        expect(favoriteProducts.first.id, equals('test_product_2'));
        expect(favoriteProducts.first.name, equals('Test Product 2'));
      });

      test('handles large product list efficiently', () {
        final products = TestData.createProductList(1000);
        provider.addToFavorites('test_product_1');
        provider.addToFavorites('test_product_500');
        provider.addToFavorites('test_product_1000');

        final favoriteProducts = provider.getFavoriteProducts(products);

        expect(favoriteProducts.length, equals(3));
        expect(favoriteProducts.map((p) => p.id), contains('test_product_500'));
      });

      test('works with all products favorited', () {
        final products = TestData.createProductList(5);
        for (var product in products) {
          provider.addToFavorites(product.id);
        }

        final favoriteProducts = provider.getFavoriteProducts(products);

        expect(favoriteProducts.length, equals(5));
      });

      test('returns products in original list order', () {
        final products = TestData.createProductList(5);
        // Add favorites in reverse order
        provider.addToFavorites('test_product_5');
        provider.addToFavorites('test_product_3');
        provider.addToFavorites('test_product_1');

        final favoriteProducts = provider.getFavoriteProducts(products);

        // Should maintain original list order, not favorite addition order
        expect(favoriteProducts.map((p) => p.id).toList(), equals(['test_product_1', 'test_product_3', 'test_product_5']));
      });
    });

    group('Persistence', () {
      setUp(() async {
        provider = WishlistProvider(mockPersistenceService);
        await Future.delayed(Duration.zero);
        reset(mockPersistenceService);
      });

      test('saveWishlist persists product IDs', () async {
        when(() => mockPersistenceService.saveWishlist(any()))
            .thenAnswer((_) async => true);

        provider.addToFavorites('product1');
        provider.addToFavorites('product2');

        await Future.delayed(Duration.zero);

        // Verify the list contains both IDs (order may vary due to Set)
        final captured = verify(() => mockPersistenceService.saveWishlist(captureAny())).captured.last;
        expect(captured, isA<List<String>>());
        expect((captured as List).toSet(), equals({'product1', 'product2'}));
      });

      test('loadWishlist retrieves saved IDs', () async {
        when(() => mockPersistenceService.loadWishlist())
            .thenReturn(['product1', 'product2', 'product3']);

        provider = WishlistProvider(mockPersistenceService);

        await Future.delayed(Duration.zero);

        expect(provider.favoriteProductIds, equals({'product1', 'product2', 'product3'}));
      });

      test('persistence roundtrip works correctly', () async {
        final savedIds = ['product1', 'product2', 'product3'];
        when(() => mockPersistenceService.loadWishlist()).thenReturn(savedIds);

        provider = WishlistProvider(mockPersistenceService);

        await Future.delayed(Duration.zero);

        expect(provider.favoriteProductIds, equals(savedIds.toSet()));
      });

      test('handles save error without throwing', () async {
        when(() => mockPersistenceService.saveWishlist(any()))
            .thenThrow(Exception('Save failed'));

        expect(() => provider.addToFavorites('product1'), returnsNormally);
      });

      test('handles load error without throwing', () async {
        when(() => mockPersistenceService.loadWishlist())
            .thenThrow(Exception('Load failed'));

        expect(() => WishlistProvider(mockPersistenceService), returnsNormally);
      });

      test('saves after each add operation', () async {
        when(() => mockPersistenceService.saveWishlist(any()))
            .thenAnswer((_) async => true);

        provider.addToFavorites('product1');
        provider.addToFavorites('product2');
        provider.addToFavorites('product3');

        await Future.delayed(Duration.zero);

        verify(() => mockPersistenceService.saveWishlist(any())).called(3);
      });

      test('saves after each remove operation', () async {
        when(() => mockPersistenceService.saveWishlist(any()))
            .thenAnswer((_) async => true);

        provider.addToFavorites('product1');
        provider.addToFavorites('product2');
        reset(mockPersistenceService);
        when(() => mockPersistenceService.saveWishlist(any()))
            .thenAnswer((_) async => true);

        provider.removeFromFavorites('product1');
        provider.removeFromFavorites('product2');

        await Future.delayed(Duration.zero);

        verify(() => mockPersistenceService.saveWishlist(any())).called(2);
      });
    });

    group('Edge Cases', () {
      setUp(() async {
        provider = WishlistProvider(mockPersistenceService);
        await Future.delayed(Duration.zero);
        reset(mockPersistenceService);
        when(() => mockPersistenceService.saveWishlist(any()))
            .thenAnswer((_) async => true);
      });

      test('handles empty product ID gracefully', () {
        provider.addToFavorites('');

        expect(provider.favoriteProductIds, contains(''));
        expect(provider.isFavorite(''), isTrue);
      });

      test('handles very long product IDs', () {
        final longId = 'product' * 1000; // 7000+ characters
        provider.addToFavorites(longId);

        expect(provider.isFavorite(longId), isTrue);
      });

      test('handles special characters in product IDs', () {
        const specialId = 'product-123_abc@test#special!';
        provider.addToFavorites(specialId);

        expect(provider.isFavorite(specialId), isTrue);
      });

      test('handles unicode characters in product IDs', () {
        const unicodeId = 'продукт-产品-محصول';
        provider.addToFavorites(unicodeId);

        expect(provider.isFavorite(unicodeId), isTrue);
      });

      test('rapid additions process correctly', () {
        for (int i = 0; i < 100; i++) {
          provider.addToFavorites('product$i');
        }

        expect(provider.count, equals(100));
      });

      test('alternating add and remove operations', () {
        provider.addToFavorites('product1');
        provider.removeFromFavorites('product1');
        provider.addToFavorites('product1');
        provider.removeFromFavorites('product1');
        provider.addToFavorites('product1');

        expect(provider.isFavorite('product1'), isTrue);
        expect(provider.count, equals(1));
      });

      test('can be disposed after operations', () {
        provider.addToFavorites('product1');
        provider.removeFromFavorites('product1');

        expect(() => provider.dispose(), returnsNormally);
      });

      test('getFavoriteProducts with all non-matching IDs', () {
        final products = TestData.createProductList(3);
        provider.addToFavorites('non_existent_1');
        provider.addToFavorites('non_existent_2');

        final favoriteProducts = provider.getFavoriteProducts(products);

        expect(favoriteProducts, isEmpty);
      });

      test('handles duplicate IDs in loaded persistence data', () {
        when(() => mockPersistenceService.loadWishlist())
            .thenReturn(['product1', 'product1', 'product2', 'product2']);

        provider = WishlistProvider(mockPersistenceService);

        // Wait for async init
        return Future.delayed(Duration.zero).then((_) {
          // Set automatically deduplicates
          expect(provider.count, equals(2));
          expect(provider.favoriteProductIds, equals({'product1', 'product2'}));
        });
      });
    });

    group('Listener Notifications', () {
      setUp(() async {
        provider = WishlistProvider(mockPersistenceService);
        await Future.delayed(Duration.zero);
        reset(mockPersistenceService);
        when(() => mockPersistenceService.saveWishlist(any()))
            .thenAnswer((_) async => true);
      });

      test('addToFavorites notifies listeners once', () {
        var notificationCount = 0;
        provider.addListener(() => notificationCount++);

        provider.addToFavorites('product1');

        expect(notificationCount, equals(1));
      });

      test('removeFromFavorites notifies listeners once', () {
        provider.addToFavorites('product1');
        var notificationCount = 0;
        provider.addListener(() => notificationCount++);

        provider.removeFromFavorites('product1');

        expect(notificationCount, equals(1));
      });

      test('toggleFavorite notifies listeners once', () {
        var notificationCount = 0;
        provider.addListener(() => notificationCount++);

        provider.toggleFavorite('product1');

        expect(notificationCount, equals(1));
      });

      test('clearFavorites notifies listeners once', () {
        provider.addToFavorites('product1');
        var notificationCount = 0;
        provider.addListener(() => notificationCount++);

        provider.clearFavorites();

        expect(notificationCount, equals(1));
      });

      test('multiple listeners all receive notification', () {
        var notified1 = false;
        var notified2 = false;
        var notified3 = false;

        provider.addListener(() => notified1 = true);
        provider.addListener(() => notified2 = true);
        provider.addListener(() => notified3 = true);

        provider.addToFavorites('product1');

        expect(notified1, isTrue);
        expect(notified2, isTrue);
        expect(notified3, isTrue);
      });

      test('removed listener does not receive notification', () {
        var notified = false;
        void listener() => notified = true;

        provider.addListener(listener);
        provider.removeListener(listener);

        provider.addToFavorites('product1');

        expect(notified, isFalse);
      });

      test('getFavoriteProducts does not notify listeners', () {
        final products = TestData.createProductList(3);
        provider.addToFavorites('test_product_1');

        var notified = false;
        provider.addListener(() => notified = true);

        provider.getFavoriteProducts(products);

        expect(notified, isFalse);
      });
    });
  });
}
