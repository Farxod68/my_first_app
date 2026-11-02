import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_first_app/data/models/product.dart';
import 'package:my_first_app/presentation/providers/cart_provider.dart';
import 'package:my_first_app/presentation/providers/search_provider.dart';
import 'package:my_first_app/presentation/providers/wishlist_provider.dart';

import '../../../mocks/mock_persistence_service.dart';

/// Translated products (Product.fromSupabase with a locale) keep working with
/// search, cart persistence and wishlist persistence.
void main() {
  Map<String, dynamic> row() => {
        'slug': 'elec-001',
        'name': 'Smart Watch Ultra',
        'subtitle': 'Fitness & Health Tracking',
        'description': 'Premium smartwatch with GPS.',
        'price': 199.99,
        'old_price': 319.99,
        'rating': 4.6,
        'review_count': 10,
        'stock': 45,
        'brand': 'TechPro',
        'seller': 'TechPro Official Store',
        'specifications': {'Display': 'AMOLED'},
        'features': ['GPS'],
        'badges': ['Best Seller'],
        'categories': {'key': 'electronics'},
        'product_images': const [],
        'product_translations': [
          {
            'locale': 'ru',
            'name': 'Умные часы Ultra',
            'subtitle': 'Фитнес и здоровье',
            'description': 'Часы премиум-класса с GPS.',
            'features': ['GPS-навигация'],
            'specifications': {'Экран': 'AMOLED'},
          },
          {
            'locale': 'uz',
            'name': 'Aqlli soat Ultra',
            'description': 'GPS bilan premium soat.',
          },
        ],
      };

  group('search over translated text', () {
    late MockPersistenceService persistence;
    late SearchProvider search;

    setUp(() {
      persistence = MockPersistenceService();
      when(() => persistence.loadRecentSearches()).thenReturn([]);
      when(() => persistence.saveRecentSearches(any()))
          .thenAnswer((_) async => true);
      search = SearchProvider(persistence);
    });

    tearDown(() => search.dispose());

    test('Russian query finds the product by its Russian name', () {
      final catalog = [Product.fromSupabase(row(), locale: 'ru')];

      search.setQuery('умные');

      expect(search.searchAndFilter(catalog).map((p) => p.id), ['elec-001']);
    });

    test('Russian query matches the Russian description and subtitle', () {
      final catalog = [Product.fromSupabase(row(), locale: 'ru')];

      search.setQuery('премиум-класса');
      expect(search.searchAndFilter(catalog), hasLength(1));

      search.setQuery('здоровье');
      expect(search.searchAndFilter(catalog), hasLength(1));
    });

    test('Uzbek (Latin) query finds the product by its Uzbek name', () {
      final catalog = [Product.fromSupabase(row(), locale: 'uz')];

      search.setQuery('aqlli');

      expect(search.searchAndFilter(catalog), hasLength(1));
    });

    test('Uzbek product with missing fields still searches the English fallback',
        () {
      final catalog = [Product.fromSupabase(row(), locale: 'uz')];

      // subtitle was not translated, so the English subtitle is searchable.
      search.setQuery('fitness');

      expect(search.searchAndFilter(catalog), hasLength(1));
    });

    test('the English name is not searchable once Russian is loaded', () {
      final catalog = [Product.fromSupabase(row(), locale: 'ru')];

      search.setQuery('smart watch');

      expect(search.searchAndFilter(catalog), isEmpty);
    });

    test('brand search still works in every language (brand is not translated)',
        () {
      final catalog = [Product.fromSupabase(row(), locale: 'ru')];

      search.setQuery('techpro');

      expect(search.searchAndFilter(catalog), hasLength(1));
    });

    test('suggestions use the translated name', () {
      final catalog = [Product.fromSupabase(row(), locale: 'ru')];

      search.setQuery('умные');

      expect(search.getSuggestions(catalog), contains('Умные часы Ultra'));
    });

    test('English catalog without translations searches as before', () {
      final catalog = [Product.fromSupabase(row(), locale: 'en')];

      search.setQuery('smart watch');

      expect(search.searchAndFilter(catalog), hasLength(1));
    });
  });

  group('cart persistence', () {
    test('a translated product round-trips through cart persistence', () async {
      final persistence = MockPersistenceService();
      when(() => persistence.loadCart()).thenReturn([]);
      List<String>? saved;
      when(() => persistence.saveCart(any())).thenAnswer((inv) async {
        saved = inv.positionalArguments.first as List<String>;
        return true;
      });

      final cart = CartProvider(persistence);
      await Future<void>.delayed(Duration.zero);
      cart.addToCart(Product.fromSupabase(row(), locale: 'ru'));
      expect(saved, isNotNull);

      // Restart: a new provider loads exactly what was persisted.
      final loadPersistence = MockPersistenceService();
      when(() => loadPersistence.loadCart()).thenReturn(saved!);
      final restored = CartProvider(loadPersistence);
      await Future<void>.delayed(Duration.zero);

      final item = restored.cartItems.single;
      expect(item.id, 'elec-001'); // slug is still the cart key
      expect(item.name, 'Умные часы Ultra');
      expect(item.specifications, {'Экран': 'AMOLED'});
      expect(item.features, ['GPS-навигация']);
      expect(item.price, 199.99);
      expect(item.badges, ['Best Seller']);
      expect(restored.quantityOf('elec-001'), 1);

      cart.dispose();
      restored.dispose();
    });

    test('the same product added in another language is still one cart line',
        () async {
      final persistence = MockPersistenceService();
      when(() => persistence.loadCart()).thenReturn([]);
      when(() => persistence.saveCart(any())).thenAnswer((_) async => true);
      final cart = CartProvider(persistence);
      await Future<void>.delayed(Duration.zero);

      cart.addToCart(Product.fromSupabase(row(), locale: 'en'));
      cart.addToCart(Product.fromSupabase(row(), locale: 'ru'));

      expect(cart.cartItems, hasLength(1));
      expect(cart.quantityOf('elec-001'), 2);
      cart.dispose();
    });

    test('previously persisted English cart items still load', () async {
      final english = Product.fromSupabase(row(), locale: null);
      final persistence = MockPersistenceService();
      List<String>? saved;
      when(() => persistence.loadCart()).thenReturn([]);
      when(() => persistence.saveCart(any())).thenAnswer((inv) async {
        saved = inv.positionalArguments.first as List<String>;
        return true;
      });
      final writer = CartProvider(persistence);
      await Future<void>.delayed(Duration.zero);
      writer.addToCart(english);

      final reader = MockPersistenceService();
      when(() => reader.loadCart()).thenReturn(saved!);
      final restored = CartProvider(reader);
      await Future<void>.delayed(Duration.zero);

      expect(restored.cartItems.single.name, 'Smart Watch Ultra');
      writer.dispose();
      restored.dispose();
    });
  });

  group('wishlist persistence', () {
    test('wishlist stores only ids, so language never affects it', () async {
      final persistence = MockPersistenceService();
      when(() => persistence.loadWishlist()).thenReturn(['elec-001']);
      when(() => persistence.saveWishlist(any())).thenAnswer((_) async => true);

      final wishlist = WishlistProvider(persistence);
      await Future<void>.delayed(Duration.zero);

      expect(wishlist.isFavorite('elec-001'), isTrue);
      // Ids come from the slug, which translations never change.
      expect(Product.fromSupabase(row(), locale: 'ru').id, 'elec-001');
      expect(Product.fromSupabase(row(), locale: 'uz').id, 'elec-001');
      wishlist.dispose();
    });
  });
}
