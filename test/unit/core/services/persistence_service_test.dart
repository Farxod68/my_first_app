import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_first_app/core/services/persistence_service.dart';

void main() {
  group('PersistenceService', () {
    setUp(() {
      // Reset SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    group('Singleton Pattern', () {
      test('getInstance returns same instance on multiple calls', () async {
        final instance1 = await PersistenceService.getInstance();
        final instance2 = await PersistenceService.getInstance();

        expect(instance1, same(instance2));
      });

      test('getInstance initializes SharedPreferences', () async {
        final instance = await PersistenceService.getInstance();

        expect(instance, isNotNull);
        expect(instance, isA<PersistenceService>());
      });

      test('getInstance returns cached instance without re-initialization',
          () async {
        final instance1 = await PersistenceService.getInstance();

        // Call getInstance again - should return cached instance immediately
        final stopwatch = Stopwatch()..start();
        final instance2 = await PersistenceService.getInstance();
        stopwatch.stop();

        expect(instance1, same(instance2));
        // Cached instance should be much faster (< 10ms)
        expect(stopwatch.elapsedMilliseconds, lessThan(10));
      });
    });

    group('saveString / getString', () {
      late PersistenceService service;

      setUp(() async {
        service = await PersistenceService.getInstance();
      });

      test('saveString returns true on success', () async {
        final result = await service.saveString('test_key', 'test_value');

        expect(result, isTrue);
      });

      test('saveString persists value retrievable by getString', () async {
        await service.saveString('test_key', 'test_value');

        final value = service.getString('test_key');

        expect(value, equals('test_value'));
      });

      test('getString returns saved value', () async {
        await service.saveString('locale', 'en');

        expect(service.getString('locale'), equals('en'));
      });

      test('getString returns null when key does not exist', () {
        expect(service.getString('nonexistent_key'), isNull);
      });

      test('saveString overwrites existing value', () async {
        await service.saveString('key', 'value1');
        await service.saveString('key', 'value2');

        expect(service.getString('key'), equals('value2'));
      });

      test('saveString handles empty string', () async {
        final result = await service.saveString('empty_key', '');

        expect(result, isTrue);
        expect(service.getString('empty_key'), equals(''));
      });

      test('saveString handles special characters', () async {
        const specialValue = 'test!@#\$%^&*()_+-=[]{}|;:,.<>?';
        await service.saveString('special', specialValue);

        expect(service.getString('special'), equals(specialValue));
      });

      test('saveString handles unicode characters', () async {
        const unicodeValue = 'Hello 世界 🌍 Привет';
        await service.saveString('unicode', unicodeValue);

        expect(service.getString('unicode'), equals(unicodeValue));
      });
    });

    group('saveStringList / getStringList', () {
      late PersistenceService service;

      setUp(() async {
        service = await PersistenceService.getInstance();
      });

      test('saveStringList returns true on success', () async {
        final result =
            await service.saveStringList('test_list', ['item1', 'item2']);

        expect(result, isTrue);
      });

      test('saveStringList persists list retrievable by getStringList',
          () async {
        final list = ['item1', 'item2', 'item3'];
        await service.saveStringList('test_list', list);

        final retrieved = service.getStringList('test_list');

        expect(retrieved, equals(list));
      });

      test('getStringList returns saved list', () async {
        await service.saveStringList('my_list', ['a', 'b', 'c']);

        expect(service.getStringList('my_list'), equals(['a', 'b', 'c']));
      });

      test('getStringList returns empty list when key does not exist', () {
        expect(service.getStringList('nonexistent_list'), isEmpty);
      });

      test('saveStringList handles empty list', () async {
        final result = await service.saveStringList('empty_list', []);

        expect(result, isTrue);
        expect(service.getStringList('empty_list'), isEmpty);
      });

      test('saveStringList overwrites existing list', () async {
        await service.saveStringList('list', ['old1', 'old2']);
        await service.saveStringList('list', ['new1', 'new2', 'new3']);

        expect(
            service.getStringList('list'), equals(['new1', 'new2', 'new3']));
      });

      test('saveStringList handles list with 100+ items', () async {
        final largeList = List.generate(150, (i) => 'item_$i');
        await service.saveStringList('large_list', largeList);

        final retrieved = service.getStringList('large_list');

        expect(retrieved.length, equals(150));
        expect(retrieved, equals(largeList));
      });

      test('saveStringList handles list with empty strings', () async {
        final list = ['', 'non-empty', '', 'another'];
        await service.saveStringList('mixed_list', list);

        expect(service.getStringList('mixed_list'), equals(list));
      });
    });

    group('remove / clearAll', () {
      late PersistenceService service;

      setUp(() async {
        service = await PersistenceService.getInstance();
        // Pre-populate with test data
        await service.saveString('key1', 'value1');
        await service.saveString('key2', 'value2');
        await service.saveStringList('list1', ['a', 'b']);
      });

      test('remove deletes key and returns true', () async {
        final result = await service.remove('key1');

        expect(result, isTrue);
        expect(service.getString('key1'), isNull);
      });

      test('remove makes getString return null for removed key', () async {
        await service.remove('key1');

        expect(service.getString('key1'), isNull);
        // Other keys should remain
        expect(service.getString('key2'), equals('value2'));
      });

      test('remove returns true even when key does not exist', () async {
        final result = await service.remove('nonexistent');

        expect(result, isTrue);
      });

      test('clearAll removes all keys and returns true', () async {
        final result = await service.clearAll();

        expect(result, isTrue);
        expect(service.getString('key1'), isNull);
        expect(service.getString('key2'), isNull);
        expect(service.getStringList('list1'), isEmpty);
      });

      test('clearAll makes all getString calls return null', () async {
        await service.clearAll();

        expect(service.getString('key1'), isNull);
        expect(service.getString('key2'), isNull);
      });

      test('methods work after clearAll', () async {
        await service.clearAll();

        // Should be able to save new data
        await service.saveString('new_key', 'new_value');
        expect(service.getString('new_key'), equals('new_value'));
      });
    });

    group('Cart Methods', () {
      late PersistenceService service;

      setUp(() async {
        service = await PersistenceService.getInstance();
      });

      test('saveCart returns true on success', () async {
        final result = await service.saveCart(['item1', 'item2']);

        expect(result, isTrue);
      });

      test('loadCart returns saved cart items', () async {
        final cartItems = ['product1_json', 'product2_json', 'product3_json'];
        await service.saveCart(cartItems);

        final loaded = service.loadCart();

        expect(loaded, equals(cartItems));
      });

      test('loadCart returns empty list when no cart saved', () async {
        // Ensure cart is cleared for this test
        await service.clearCart();
        expect(service.loadCart(), isEmpty);
      });

      test('clearCart removes cart items', () async {
        await service.saveCart(['item1', 'item2']);
        await service.clearCart();

        expect(service.loadCart(), isEmpty);
      });

      test('clearCart returns true on success', () async {
        await service.saveCart(['item1']);
        final result = await service.clearCart();

        expect(result, isTrue);
      });

      test('saveCart handles empty list', () async {
        await service.saveCart([]);

        expect(service.loadCart(), isEmpty);
      });

      test('saveCart handles large list (100+ items)', () async {
        final largeCart = List.generate(150, (i) => 'product_$i');
        await service.saveCart(largeCart);

        expect(service.loadCart().length, equals(150));
      });

      test('saveCart handles JSON strings', () async {
        const jsonItem =
            '{"id":"1","name":"Product","price":99.99,"category":"Electronics"}';
        await service.saveCart([jsonItem]);

        expect(service.loadCart(), equals([jsonItem]));
      });

      test('loadCart returns empty list after clearCart', () async {
        await service.saveCart(['item1', 'item2']);
        await service.clearCart();

        expect(service.loadCart(), isEmpty);
      });

      test('saveCart overwrites previous cart', () async {
        await service.saveCart(['old1', 'old2']);
        await service.saveCart(['new1', 'new2', 'new3']);

        expect(service.loadCart(), equals(['new1', 'new2', 'new3']));
      });

      test('clearCart does not affect other keys', () async {
        await service.saveCart(['cart_item']);
        await service.saveString('other_key', 'other_value');

        await service.clearCart();

        expect(service.getString('other_key'), equals('other_value'));
      });

      test('cart operations use correct internal key', () async {
        // Verify cart uses 'cart_items' key by saving directly
        await service.saveStringList('cart_items', ['direct_item']);

        expect(service.loadCart(), equals(['direct_item']));
      });
    });

    group('Wishlist Methods', () {
      late PersistenceService service;

      setUp(() async {
        service = await PersistenceService.getInstance();
      });

      test('saveWishlist returns true on success', () async {
        final result = await service.saveWishlist(['fav1', 'fav2']);

        expect(result, isTrue);
      });

      test('loadWishlist returns saved wishlist', () async {
        final favorites = ['product1', 'product2', 'product3'];
        await service.saveWishlist(favorites);

        final loaded = service.loadWishlist();

        expect(loaded, equals(favorites));
      });

      test('loadWishlist returns empty list when no wishlist saved', () async {
        // Ensure wishlist is cleared for this test
        await service.clearWishlist();
        expect(service.loadWishlist(), isEmpty);
      });

      test('clearWishlist removes wishlist items', () async {
        await service.saveWishlist(['fav1', 'fav2']);
        await service.clearWishlist();

        expect(service.loadWishlist(), isEmpty);
      });

      test('clearWishlist returns true on success', () async {
        await service.saveWishlist(['fav1']);
        final result = await service.clearWishlist();

        expect(result, isTrue);
      });

      test('saveWishlist handles empty list', () async {
        await service.saveWishlist([]);

        expect(service.loadWishlist(), isEmpty);
      });

      test('saveWishlist handles large list (50+ favorites)', () async {
        final largeWishlist = List.generate(75, (i) => 'favorite_$i');
        await service.saveWishlist(largeWishlist);

        expect(service.loadWishlist().length, equals(75));
      });

      test('loadWishlist returns empty list after clearWishlist', () async {
        await service.saveWishlist(['fav1', 'fav2']);
        await service.clearWishlist();

        expect(service.loadWishlist(), isEmpty);
      });

      test('saveWishlist overwrites previous wishlist', () async {
        await service.saveWishlist(['old1', 'old2']);
        await service.saveWishlist(['new1', 'new2', 'new3']);

        expect(service.loadWishlist(), equals(['new1', 'new2', 'new3']));
      });

      test('clearWishlist does not affect other keys', () async {
        await service.saveWishlist(['fav']);
        await service.saveCart(['cart_item']);

        await service.clearWishlist();

        expect(service.loadCart(), isNotEmpty);
      });

      test('wishlist operations do not affect cart', () async {
        await service.saveCart(['cart1', 'cart2']);
        await service.saveWishlist(['fav1', 'fav2']);

        expect(service.loadCart(), equals(['cart1', 'cart2']));
        expect(service.loadWishlist(), equals(['fav1', 'fav2']));

        await service.clearWishlist();

        expect(service.loadCart(), equals(['cart1', 'cart2']));
      });

      test('wishlist operations use correct internal key', () async {
        // Verify wishlist uses 'wishlist_favorites' key
        await service.saveStringList('wishlist_favorites', ['direct_fav']);

        expect(service.loadWishlist(), equals(['direct_fav']));
      });
    });

    group('Locale Methods', () {
      late PersistenceService service;

      setUp(() async {
        service = await PersistenceService.getInstance();
      });

      test('saveLocale returns true on success', () async {
        final result = await service.saveLocale('en');

        expect(result, isTrue);
      });

      test('loadLocale returns saved locale', () async {
        await service.saveLocale('es');

        expect(service.loadLocale(), equals('es'));
      });

      test('loadLocale returns null when no locale saved', () async {
        // Ensure locale is cleared for this test
        await service.clearLocale();
        expect(service.loadLocale(), isNull);
      });

      test('clearLocale removes locale', () async {
        await service.saveLocale('fr');
        await service.clearLocale();

        expect(service.loadLocale(), isNull);
      });

      test('clearLocale returns true on success', () async {
        await service.saveLocale('uz');
        final result = await service.clearLocale();

        expect(result, isTrue);
      });

      test('saveLocale handles all supported locales', () async {
        final locales = ['en', 'es', 'fr', 'uz'];

        for (final locale in locales) {
          await service.saveLocale(locale);
          expect(service.loadLocale(), equals(locale));
        }
      });

      test('loadLocale returns null after clearLocale', () async {
        await service.saveLocale('en');
        await service.clearLocale();

        expect(service.loadLocale(), isNull);
      });

      test('locale operations do not affect other keys', () async {
        await service.saveLocale('en');
        await service.saveCart(['cart_item']);

        await service.clearLocale();

        expect(service.loadCart(), isNotEmpty);
      });

      test('locale operations use correct internal key', () async {
        // Verify locale uses 'locale_language' key
        await service.saveString('locale_language', 'direct_locale');

        expect(service.loadLocale(), equals('direct_locale'));
      });
    });

    group('Recently Viewed Methods', () {
      late PersistenceService service;

      setUp(() async {
        service = await PersistenceService.getInstance();
      });

      test('saveRecentlyViewed returns true on success', () async {
        final result = await service.saveRecentlyViewed(['prod1', 'prod2']);

        expect(result, isTrue);
      });

      test('loadRecentlyViewed returns saved product IDs', () async {
        final productIds = ['id1', 'id2', 'id3'];
        await service.saveRecentlyViewed(productIds);

        expect(service.loadRecentlyViewed(), equals(productIds));
      });

      test('loadRecentlyViewed returns empty list when none saved', () async {
        // Ensure recently viewed is cleared for this test
        await service.clearRecentlyViewed();
        expect(service.loadRecentlyViewed(), isEmpty);
      });

      test('clearRecentlyViewed removes items', () async {
        await service.saveRecentlyViewed(['id1', 'id2']);
        await service.clearRecentlyViewed();

        expect(service.loadRecentlyViewed(), isEmpty);
      });

      test('clearRecentlyViewed returns true on success', () async {
        await service.saveRecentlyViewed(['id1']);
        final result = await service.clearRecentlyViewed();

        expect(result, isTrue);
      });

      test('saveRecentlyViewed handles up to 20 items', () async {
        final productIds = List.generate(20, (i) => 'product_$i');
        await service.saveRecentlyViewed(productIds);

        expect(service.loadRecentlyViewed().length, equals(20));
      });

      test('loadRecentlyViewed returns empty list after clear', () async {
        await service.saveRecentlyViewed(['id1', 'id2']);
        await service.clearRecentlyViewed();

        expect(service.loadRecentlyViewed(), isEmpty);
      });

      test('recently viewed operations do not affect other keys', () async {
        await service.saveRecentlyViewed(['id1']);
        await service.saveCart(['cart_item']);

        await service.clearRecentlyViewed();

        expect(service.loadCart(), isNotEmpty);
      });

      test('recently viewed uses correct internal key', () async {
        await service.saveStringList('recently_viewed', ['direct_id']);

        expect(service.loadRecentlyViewed(), equals(['direct_id']));
      });
    });

    group('Recent Searches Methods', () {
      late PersistenceService service;

      setUp(() async {
        service = await PersistenceService.getInstance();
      });

      test('saveRecentSearches returns true on success', () async {
        final result =
            await service.saveRecentSearches(['search1', 'search2']);

        expect(result, isTrue);
      });

      test('loadRecentSearches returns saved searches', () async {
        final searches = ['laptop', 'phone', 'tablet'];
        await service.saveRecentSearches(searches);

        expect(service.loadRecentSearches(), equals(searches));
      });

      test('loadRecentSearches returns empty list when none saved', () async {
        // Ensure searches are cleared for this test
        await service.clearRecentSearches();
        expect(service.loadRecentSearches(), isEmpty);
      });

      test('clearRecentSearches removes searches', () async {
        await service.saveRecentSearches(['search1', 'search2']);
        await service.clearRecentSearches();

        expect(service.loadRecentSearches(), isEmpty);
      });

      test('clearRecentSearches returns true on success', () async {
        await service.saveRecentSearches(['search1']);
        final result = await service.clearRecentSearches();

        expect(result, isTrue);
      });

      test('saveRecentSearches handles up to 10 searches', () async {
        final searches = List.generate(10, (i) => 'search_$i');
        await service.saveRecentSearches(searches);

        expect(service.loadRecentSearches().length, equals(10));
      });

      test('loadRecentSearches returns empty list after clear', () async {
        await service.saveRecentSearches(['search1', 'search2']);
        await service.clearRecentSearches();

        expect(service.loadRecentSearches(), isEmpty);
      });

      test('search operations do not affect other keys', () async {
        await service.saveRecentSearches(['search1']);
        await service.saveWishlist(['fav1']);

        await service.clearRecentSearches();

        expect(service.loadWishlist(), isNotEmpty);
      });

      test('recent searches use correct internal key', () async {
        await service.saveStringList('recent_searches', ['direct_search']);

        expect(service.loadRecentSearches(), equals(['direct_search']));
      });
    });

    group('Edge Cases and Integration', () {
      late PersistenceService service;

      setUp(() async {
        service = await PersistenceService.getInstance();
      });

      test('multiple save operations in sequence', () async {
        await service.saveString('key1', 'value1');
        await service.saveString('key2', 'value2');
        await service.saveStringList('list1', ['a', 'b']);
        await service.saveCart(['cart1']);
        await service.saveWishlist(['fav1']);

        expect(service.getString('key1'), equals('value1'));
        expect(service.getString('key2'), equals('value2'));
        expect(service.getStringList('list1'), equals(['a', 'b']));
        expect(service.loadCart(), equals(['cart1']));
        expect(service.loadWishlist(), equals(['fav1']));
      });

      test('all domain-specific methods use correct keys', () async {
        // Save using domain methods
        await service.saveCart(['cart']);
        await service.saveWishlist(['wish']);
        await service.saveLocale('en');
        await service.saveRecentlyViewed(['viewed']);
        await service.saveRecentSearches(['search']);

        // Verify using generic methods with internal keys
        expect(service.getStringList('cart_items'), equals(['cart']));
        expect(service.getStringList('wishlist_favorites'), equals(['wish']));
        expect(service.getString('locale_language'), equals('en'));
        expect(service.getStringList('recently_viewed'), equals(['viewed']));
        expect(service.getStringList('recent_searches'), equals(['search']));
      });

      test('clearing one domain does not affect others', () async {
        await service.saveCart(['cart']);
        await service.saveWishlist(['wish']);
        await service.saveLocale('en');
        await service.saveRecentlyViewed(['viewed']);
        await service.saveRecentSearches(['search']);

        await service.clearCart();

        expect(service.loadCart(), isEmpty);
        expect(service.loadWishlist(), equals(['wish']));
        expect(service.loadLocale(), equals('en'));
        expect(service.loadRecentlyViewed(), equals(['viewed']));
        expect(service.loadRecentSearches(), equals(['search']));
      });

      test('saveString handles very long strings (10KB+)', () async {
        final longString = 'x' * 15000; // 15KB string
        await service.saveString('long', longString);

        expect(service.getString('long'), equals(longString));
        expect(service.getString('long')!.length, equals(15000));
      });

      test('persistence survives multiple getInstance cycles', () async {
        final service1 = await PersistenceService.getInstance();
        await service1.saveString('persistent_key', 'persistent_value');

        // Get another instance (should be same singleton)
        final service2 = await PersistenceService.getInstance();

        expect(service2.getString('persistent_key'),
            equals('persistent_value'));
      });

      test('all async methods complete successfully', () async {
        // All these should complete without hanging
        await service.saveString('key', 'value');
        await service.saveStringList('list', ['item']);
        await service.remove('key');
        await service.saveCart(['cart']);
        await service.saveWishlist(['wish']);
        await service.saveLocale('en');
        await service.saveRecentlyViewed(['id']);
        await service.saveRecentSearches(['search']);
        await service.clearCart();
        await service.clearWishlist();
        await service.clearLocale();
        await service.clearRecentlyViewed();
        await service.clearRecentSearches();
        await service.clearAll();

        // If we get here, all async operations completed
        expect(true, isTrue);
      });

      test('getString does not throw on missing key', () {
        expect(() => service.getString('nonexistent'), returnsNormally);
        expect(service.getString('nonexistent'), isNull);
      });

      test('getStringList does not throw on missing key', () {
        expect(() => service.getStringList('nonexistent'), returnsNormally);
        expect(service.getStringList('nonexistent'), isEmpty);
      });

      test('concurrent operations complete correctly', () async {
        // Start multiple operations concurrently
        final futures = [
          service.saveString('key1', 'value1'),
          service.saveString('key2', 'value2'),
          service.saveStringList('list1', ['a', 'b']),
          service.saveCart(['cart1']),
          service.saveWishlist(['fav1']),
        ];

        await Future.wait(futures);

        // All should have completed successfully
        expect(service.getString('key1'), equals('value1'));
        expect(service.getString('key2'), equals('value2'));
        expect(service.getStringList('list1'), equals(['a', 'b']));
        expect(service.loadCart(), equals(['cart1']));
        expect(service.loadWishlist(), equals(['fav1']));
      });
    });
  });
}
