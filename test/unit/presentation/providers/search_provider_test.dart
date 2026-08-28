import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_first_app/presentation/providers/search_provider.dart';
import 'package:my_first_app/data/models/filter_models.dart';
import 'package:my_first_app/core/constants/app_constants.dart';
import '../../../mocks/mock_persistence_service.dart';
import '../../../helpers/test_data.dart';

void main() {
  group('SearchProvider', () {
    late MockPersistenceService mockPersistenceService;
    late SearchProvider provider;

    setUp(() {
      mockPersistenceService = MockPersistenceService();
      // Default: no saved recent searches
      when(() => mockPersistenceService.loadRecentSearches()).thenReturn([]);
      when(() => mockPersistenceService.saveRecentSearches(any()))
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
      test('constructor calls _loadRecentSearches', () async {
        provider = SearchProvider(mockPersistenceService);

        await Future.delayed(Duration.zero);

        verify(() => mockPersistenceService.loadRecentSearches()).called(1);
      });

      test('initial state has empty query', () async {
        provider = SearchProvider(mockPersistenceService);

        await Future.delayed(Duration.zero);

        expect(provider.query.raw, isEmpty);
        expect(provider.query.isEmpty, isTrue);
      });

      test('initial state has default filters', () async {
        provider = SearchProvider(mockPersistenceService);

        await Future.delayed(Duration.zero);

        expect(provider.filters.hasActiveFilters, isFalse);
      });

      test('initial state has relevance sort', () async {
        provider = SearchProvider(mockPersistenceService);

        await Future.delayed(Duration.zero);

        expect(provider.sortBy, equals(ProductSort.relevance));
      });

      test('initial state has empty recent searches', () async {
        provider = SearchProvider(mockPersistenceService);

        await Future.delayed(Duration.zero);

        expect(provider.recentSearches, isEmpty);
      });

      test('loads saved recent searches from persistence', () async {
        when(() => mockPersistenceService.loadRecentSearches())
            .thenReturn(['laptop', 'phone', 'tablet']);

        provider = SearchProvider(mockPersistenceService);

        await Future.delayed(Duration.zero);

        expect(provider.recentSearches, equals(['laptop', 'phone', 'tablet']));
      });

      test('marks as loaded after initialization', () async {
        provider = SearchProvider(mockPersistenceService);

        await Future.delayed(Duration.zero);

        expect(provider.isLoaded, isTrue);
      });

      test('handles persistence error gracefully', () async {
        when(() => mockPersistenceService.loadRecentSearches())
            .thenThrow(Exception('Storage error'));

        provider = SearchProvider(mockPersistenceService);

        await Future.delayed(Duration.zero);

        expect(provider.recentSearches, isEmpty);
        expect(provider.isLoaded, isTrue);
      });
    });

    group('Query Management', () {
      setUp(() async {
        provider = SearchProvider(mockPersistenceService);
        await Future.delayed(Duration.zero);
        reset(mockPersistenceService);
        when(() => mockPersistenceService.saveRecentSearches(any()))
            .thenAnswer((_) async => true);
      });

      test('setQuery updates query', () {
        provider.setQuery('laptop');

        expect(provider.query.raw, equals('laptop'));
        expect(provider.query.normalized, equals('laptop'));
      });

      test('setQuery normalizes query (lowercase, trim, whitespace)', () {
        provider.setQuery('  LAPTOP  Computer  ');

        expect(provider.query.normalized, equals('laptop computer'));
      });

      test('setQuery removes punctuation in normalized form', () {
        provider.setQuery('laptop-computer!');

        expect(provider.query.normalized, equals('laptopcomputer'));
      });

      test('setQuery notifies listeners', () {
        var notified = false;
        provider.addListener(() => notified = true);

        provider.setQuery('laptop');

        expect(notified, isTrue);
      });

      test('clearQuery clears query', () {
        provider.setQuery('laptop');
        expect(provider.query.isNotEmpty, isTrue);

        provider.clearQuery();

        expect(provider.query.isEmpty, isTrue);
        expect(provider.query.raw, isEmpty);
      });

      test('clearQuery notifies listeners', () {
        provider.setQuery('laptop');

        var notified = false;
        provider.addListener(() => notified = true);

        provider.clearQuery();

        expect(notified, isTrue);
      });

      test('hasSearch returns false for empty query', () {
        expect(provider.hasSearch, isFalse);
      });

      test('hasSearch returns true for non-empty query', () {
        provider.setQuery('laptop');

        expect(provider.hasSearch, isTrue);
      });
    });

    group('Filter Management', () {
      setUp(() async {
        provider = SearchProvider(mockPersistenceService);
        await Future.delayed(Duration.zero);
      });

      test('setFilters updates filters', () {
        final filters = ProductFilters(category: 'Electronics');

        provider.setFilters(filters);

        expect(provider.filters, equals(filters));
        expect(provider.filters.category, equals('Electronics'));
      });

      test('setFilters notifies listeners', () {
        var notified = false;
        provider.addListener(() => notified = true);

        provider.setFilters(ProductFilters(category: 'Electronics'));

        expect(notified, isTrue);
      });

      test('clearFilters resets to default filters', () {
        provider.setFilters(ProductFilters(category: 'Electronics', brand: 'Apple'));
        expect(provider.filters.hasActiveFilters, isTrue);

        provider.clearFilters();

        expect(provider.filters.hasActiveFilters, isFalse);
      });

      test('clearFilters notifies listeners', () {
        provider.setFilters(ProductFilters(category: 'Electronics'));

        var notified = false;
        provider.addListener(() => notified = true);

        provider.clearFilters();

        expect(notified, isTrue);
      });

      test('hasFilters returns false for default filters', () {
        expect(provider.hasFilters, isFalse);
      });

      test('hasFilters returns true when filters are active', () {
        provider.setFilters(ProductFilters(category: 'Electronics'));

        expect(provider.hasFilters, isTrue);
      });

      test('hasActiveDiscovery returns false when no query or filters', () {
        expect(provider.hasActiveDiscovery, isFalse);
      });

      test('hasActiveDiscovery returns true when query is active', () {
        provider.setQuery('laptop');

        expect(provider.hasActiveDiscovery, isTrue);
      });

      test('hasActiveDiscovery returns true when filters are active', () {
        provider.setFilters(ProductFilters(category: 'Electronics'));

        expect(provider.hasActiveDiscovery, isTrue);
      });
    });

    group('Individual Filter Setters', () {
      setUp(() async {
        provider = SearchProvider(mockPersistenceService);
        await Future.delayed(Duration.zero);
      });

      test('setCategoryFilter updates category', () {
        provider.setCategoryFilter('Electronics');

        expect(provider.filters.category, equals('Electronics'));
      });

      test('setCategoryFilter notifies listeners', () {
        var notified = false;
        provider.addListener(() => notified = true);

        provider.setCategoryFilter('Electronics');

        expect(notified, isTrue);
      });

      test('setBrandFilter updates brand', () {
        provider.setBrandFilter('Apple');

        expect(provider.filters.brand, equals('Apple'));
      });

      test('setBrandFilter notifies listeners', () {
        var notified = false;
        provider.addListener(() => notified = true);

        provider.setBrandFilter('Apple');

        expect(notified, isTrue);
      });

      test('setPriceRangeFilter updates price range', () {
        final range = PriceRange(min: 100, max: 500);

        provider.setPriceRangeFilter(range);

        expect(provider.filters.priceRange, equals(range));
      });

      test('setPriceRangeFilter notifies listeners', () {
        var notified = false;
        provider.addListener(() => notified = true);

        provider.setPriceRangeFilter(PriceRange(min: 100, max: 500));

        expect(notified, isTrue);
      });

      test('setRatingFilter updates min rating', () {
        provider.setRatingFilter(4.0);

        expect(provider.filters.minRating, equals(4.0));
      });

      test('setRatingFilter notifies listeners', () {
        var notified = false;
        provider.addListener(() => notified = true);

        provider.setRatingFilter(4.0);

        expect(notified, isTrue);
      });

      test('setDiscountFilter updates min discount', () {
        provider.setDiscountFilter(20);

        expect(provider.filters.minDiscount, equals(20));
      });

      test('setDiscountFilter notifies listeners', () {
        var notified = false;
        provider.addListener(() => notified = true);

        provider.setDiscountFilter(20);

        expect(notified, isTrue);
      });

      test('setInStockOnlyFilter updates in stock only', () {
        provider.setInStockOnlyFilter(true);

        expect(provider.filters.inStockOnly, isTrue);
      });

      test('setInStockOnlyFilter notifies listeners', () {
        var notified = false;
        provider.addListener(() => notified = true);

        provider.setInStockOnlyFilter(true);

        expect(notified, isTrue);
      });

      test('setSellerFilter updates seller', () {
        provider.setSellerFilter('Amazon');

        expect(provider.filters.seller, equals('Amazon'));
      });

      test('setSellerFilter notifies listeners', () {
        var notified = false;
        provider.addListener(() => notified = true);

        provider.setSellerFilter('Amazon');

        expect(notified, isTrue);
      });

      test('setDealsOnlyFilter updates deals only', () {
        provider.setDealsOnlyFilter(true);

        expect(provider.filters.dealsOnly, isTrue);
      });

      test('setDealsOnlyFilter notifies listeners', () {
        var notified = false;
        provider.addListener(() => notified = true);

        provider.setDealsOnlyFilter(true);

        expect(notified, isTrue);
      });

      test('can set multiple filters together', () {
        provider.setCategoryFilter('Electronics');
        provider.setBrandFilter('Apple');
        provider.setRatingFilter(4.5);

        expect(provider.filters.category, equals('Electronics'));
        expect(provider.filters.brand, equals('Apple'));
        expect(provider.filters.minRating, equals(4.5));
      });

      test('can clear individual filters by setting to null', () {
        provider.setCategoryFilter('Electronics');
        expect(provider.filters.category, isNotNull);

        provider.setCategoryFilter(null);

        expect(provider.filters.category, isNull);
      });
    });

    group('Sort Management', () {
      setUp(() async {
        provider = SearchProvider(mockPersistenceService);
        await Future.delayed(Duration.zero);
      });

      test('setSortBy updates sort option', () {
        provider.setSortBy(ProductSort.priceLowToHigh);

        expect(provider.sortBy, equals(ProductSort.priceLowToHigh));
      });

      test('setSortBy notifies listeners', () {
        var notified = false;
        provider.addListener(() => notified = true);

        provider.setSortBy(ProductSort.rating);

        expect(notified, isTrue);
      });

      test('setSortBy works for all sort options', () {
        final sortOptions = [
          ProductSort.relevance,
          ProductSort.priceLowToHigh,
          ProductSort.priceHighToLow,
          ProductSort.rating,
          ProductSort.newest,
          ProductSort.discount,
          ProductSort.popularity,
        ];

        for (final sort in sortOptions) {
          provider.setSortBy(sort);
          expect(provider.sortBy, equals(sort));
        }
      });
    });

    group('Recent Searches', () {
      setUp(() async {
        provider = SearchProvider(mockPersistenceService);
        await Future.delayed(Duration.zero);
        reset(mockPersistenceService);
        when(() => mockPersistenceService.saveRecentSearches(any()))
            .thenAnswer((_) async => true);
      });

      test('addRecentSearch adds to front of list', () {
        provider.addRecentSearch('laptop');

        expect(provider.recentSearches.first, equals('laptop'));
      });

      test('addRecentSearch removes duplicates', () {
        provider.addRecentSearch('laptop');
        provider.addRecentSearch('phone');
        provider.addRecentSearch('laptop');

        expect(provider.recentSearches, equals(['laptop', 'phone']));
      });

      test('addRecentSearch maintains max size', () {
        for (int i = 0; i < AppConfig.maxSearchHistory + 5; i++) {
          provider.addRecentSearch('search$i');
        }

        expect(provider.recentSearches.length, equals(AppConfig.maxSearchHistory));
      });

      test('addRecentSearch ignores empty query', () {
        provider.addRecentSearch('');

        expect(provider.recentSearches, isEmpty);
      });

      test('addRecentSearch ignores whitespace-only query', () {
        provider.addRecentSearch('   ');

        expect(provider.recentSearches, isEmpty);
      });

      test('addRecentSearch calls _saveRecentSearches', () async {
        provider.addRecentSearch('laptop');

        await Future.delayed(Duration.zero);

        verify(() => mockPersistenceService.saveRecentSearches(['laptop'])).called(1);
      });

      test('addRecentSearch notifies listeners', () {
        var notified = false;
        provider.addListener(() => notified = true);

        provider.addRecentSearch('laptop');

        expect(notified, isTrue);
      });

      test('removeRecentSearch removes search from list', () {
        provider.addRecentSearch('laptop');
        provider.addRecentSearch('phone');

        provider.removeRecentSearch('laptop');

        expect(provider.recentSearches, equals(['phone']));
      });

      test('removeRecentSearch handles non-existent search gracefully', () {
        provider.addRecentSearch('laptop');

        expect(() => provider.removeRecentSearch('phone'), returnsNormally);
        expect(provider.recentSearches, equals(['laptop']));
      });

      test('removeRecentSearch calls _saveRecentSearches', () async {
        provider.addRecentSearch('laptop');
        reset(mockPersistenceService);
        when(() => mockPersistenceService.saveRecentSearches(any()))
            .thenAnswer((_) async => true);

        provider.removeRecentSearch('laptop');

        await Future.delayed(Duration.zero);

        verify(() => mockPersistenceService.saveRecentSearches([])).called(1);
      });

      test('removeRecentSearch notifies listeners', () {
        provider.addRecentSearch('laptop');

        var notified = false;
        provider.addListener(() => notified = true);

        provider.removeRecentSearch('laptop');

        expect(notified, isTrue);
      });

      test('clearRecentSearches removes all searches', () {
        provider.addRecentSearch('laptop');
        provider.addRecentSearch('phone');
        provider.addRecentSearch('tablet');

        provider.clearRecentSearches();

        expect(provider.recentSearches, isEmpty);
      });

      test('clearRecentSearches calls _saveRecentSearches', () async {
        provider.addRecentSearch('laptop');
        reset(mockPersistenceService);
        when(() => mockPersistenceService.saveRecentSearches(any()))
            .thenAnswer((_) async => true);

        provider.clearRecentSearches();

        await Future.delayed(Duration.zero);

        verify(() => mockPersistenceService.saveRecentSearches([])).called(1);
      });

      test('clearRecentSearches notifies listeners', () {
        provider.addRecentSearch('laptop');

        var notified = false;
        provider.addListener(() => notified = true);

        provider.clearRecentSearches();

        expect(notified, isTrue);
      });

      test('recentSearches returns unmodifiable list', () {
        provider.addRecentSearch('laptop');

        final searches = provider.recentSearches;

        expect(() => searches.add('phone'), throwsUnsupportedError);
      });

      test('recent searches maintain order (most recent first)', () {
        provider.addRecentSearch('laptop');
        provider.addRecentSearch('phone');
        provider.addRecentSearch('tablet');

        expect(provider.recentSearches, equals(['tablet', 'phone', 'laptop']));
      });
    });

    group('Search Suggestions', () {
      setUp(() async {
        provider = SearchProvider(mockPersistenceService);
        await Future.delayed(Duration.zero);
      });

      test('empty query returns recent searches', () {
        provider.addRecentSearch('laptop');
        provider.addRecentSearch('phone');

        final suggestions = provider.getSuggestions([]);

        expect(suggestions, equals(['phone', 'laptop']));
      });

      test('empty query respects max suggestions', () {
        for (int i = 0; i < 15; i++) {
          provider.addRecentSearch('search$i');
        }

        final suggestions = provider.getSuggestions([], maxSuggestions: 5);

        expect(suggestions.length, equals(5));
      });

      test('query matches product names', () {
        final products = [
          TestData.createTestProduct(id: '1', name: 'Laptop Computer'),
          TestData.createTestProduct(id: '2', name: 'Phone Case'),
        ];

        provider.setQuery('laptop');

        final suggestions = provider.getSuggestions(products);

        expect(suggestions, contains('Laptop Computer'));
      });

      test('query matches brands', () {
        final products = [
          TestData.createTestProduct(id: '1', brand: 'Apple'),
          TestData.createTestProduct(id: '2', brand: 'Samsung'),
        ];

        provider.setQuery('apple');

        final suggestions = provider.getSuggestions(products);

        expect(suggestions, contains('Apple'));
      });

      test('query matches categories', () {
        final products = [
          TestData.createTestProduct(id: '1', category: 'Electronics'),
          TestData.createTestProduct(id: '2', category: 'Clothing'),
        ];

        provider.setQuery('electron');

        final suggestions = provider.getSuggestions(products);

        expect(suggestions, contains('Electronics'));
      });

      test('query matches recent searches', () {
        provider.addRecentSearch('laptop computer');
        provider.addRecentSearch('phone case');

        provider.setQuery('laptop');

        final suggestions = provider.getSuggestions([]);

        expect(suggestions, contains('laptop computer'));
      });

      test('suggestions are case-insensitive', () {
        final products = [
          TestData.createTestProduct(id: '1', name: 'LAPTOP'),
        ];

        provider.setQuery('laptop');

        final suggestions = provider.getSuggestions(products);

        expect(suggestions, contains('LAPTOP'));
      });

      test('suggestions respect max limit', () {
        final products = TestData.createProductList(20);

        provider.setQuery('product');

        final suggestions = provider.getSuggestions(products, maxSuggestions: 5);

        expect(suggestions.length, lessThanOrEqualTo(5));
      });

      test('suggestions are unique', () {
        final products = [
          TestData.createTestProduct(id: '1', name: 'Laptop', brand: 'Apple'),
          TestData.createTestProduct(id: '2', name: 'Laptop', brand: 'Dell'),
        ];

        provider.setQuery('laptop');

        final suggestions = provider.getSuggestions(products);

        final uniqueSuggestions = suggestions.toSet();
        expect(suggestions.length, equals(uniqueSuggestions.length));
      });
    });

    group('Search and Filter', () {
      setUp(() async {
        provider = SearchProvider(mockPersistenceService);
        await Future.delayed(Duration.zero);
      });

      test('returns all products when no search or filters', () {
        final products = TestData.createProductList(5);

        final results = provider.searchAndFilter(products);

        expect(results.length, equals(5));
      });

      test('searches by product name', () {
        final products = [
          TestData.createTestProduct(id: '1', name: 'Laptop Computer'),
          TestData.createTestProduct(id: '2', name: 'Phone Case'),
          TestData.createTestProduct(id: '3', name: 'Laptop Bag'),
        ];

        provider.setQuery('laptop');

        final results = provider.searchAndFilter(products);

        expect(results.length, equals(2));
        expect(results.every((p) => p.name.toLowerCase().contains('laptop')), isTrue);
      });

      test('search prioritizes exact match', () {
        final products = [
          TestData.createTestProduct(id: '1', name: 'phone'),
          TestData.createTestProduct(id: '2', name: 'smartphone'),
          TestData.createTestProduct(id: '3', name: 'phone case'),
        ];

        provider.setQuery('phone');

        final results = provider.searchAndFilter(products);

        expect(results.first.name, equals('phone')); // Exact match first
      });

      test('search prioritizes starts with over contains', () {
        final products = [
          TestData.createTestProduct(id: '1', name: 'smartphone'),
          TestData.createTestProduct(id: '2', name: 'phone'),
          TestData.createTestProduct(id: '3', name: 'my phone'),
        ];

        provider.setQuery('phone');

        final results = provider.searchAndFilter(products);

        expect(results.first.name, equals('phone')); // Exact match
        expect(results[1].name, equals('smartphone')); // Starts with
      });

      test('search matches brand', () {
        final products = [
          TestData.createTestProduct(id: '1', name: 'Product 1', brand: 'Apple'),
          TestData.createTestProduct(id: '2', name: 'Product 2', brand: 'Samsung'),
        ];

        provider.setQuery('apple');

        final results = provider.searchAndFilter(products);

        expect(results.length, equals(1));
        expect(results.first.brand, equals('Apple'));
      });

      test('search matches category', () {
        final products = [
          TestData.createTestProduct(id: '1', category: 'Electronics'),
          TestData.createTestProduct(id: '2', category: 'Clothing'),
        ];

        provider.setQuery('electron');

        final results = provider.searchAndFilter(products);

        expect(results.length, equals(1));
        expect(results.first.category, equals('Electronics'));
      });

      test('filters by category', () {
        final products = [
          TestData.createTestProduct(id: '1', category: 'Electronics'),
          TestData.createTestProduct(id: '2', category: 'Clothing'),
        ];

        provider.setCategoryFilter('Electronics');

        final results = provider.searchAndFilter(products);

        expect(results.length, equals(1));
        expect(results.first.category, equals('Electronics'));
      });

      test('filters by brand', () {
        final products = [
          TestData.createTestProduct(id: '1', brand: 'Apple'),
          TestData.createTestProduct(id: '2', brand: 'Samsung'),
        ];

        provider.setBrandFilter('Apple');

        final results = provider.searchAndFilter(products);

        expect(results.length, equals(1));
        expect(results.first.brand, equals('Apple'));
      });

      test('filters by price range', () {
        final products = [
          TestData.createTestProduct(id: '1', price: 50.0),
          TestData.createTestProduct(id: '2', price: 150.0),
          TestData.createTestProduct(id: '3', price: 250.0),
        ];

        provider.setPriceRangeFilter(PriceRange(min: 100.0, max: 200.0));

        final results = provider.searchAndFilter(products);

        expect(results.length, equals(1));
        expect(results.first.price, equals(150.0));
      });

      test('filters by min rating', () {
        final products = [
          TestData.createTestProduct(id: '1', rating: 3.0),
          TestData.createTestProduct(id: '2', rating: 4.5),
          TestData.createTestProduct(id: '3', rating: 5.0),
        ];

        provider.setRatingFilter(4.0);

        final results = provider.searchAndFilter(products);

        expect(results.length, equals(2));
        expect(results.every((p) => p.rating >= 4.0), isTrue);
      });

      test('filters by min discount', () {
        final products = [
          TestData.createTestProduct(id: '1', price: 80.0, oldPrice: 100.0), // 20% discount
          TestData.createTestProduct(id: '2', price: 50.0, oldPrice: 100.0), // 50% discount
          TestData.createTestProduct(id: '3', price: 100.0, oldPrice: 100.0), // 0% discount
        ];

        provider.setDiscountFilter(30);

        final results = provider.searchAndFilter(products);

        expect(results.length, equals(1));
        expect(results.first.discount, greaterThanOrEqualTo(30));
      });

      test('filters by in stock only', () {
        final products = [
          TestData.createTestProduct(id: '1', stock: 10),
          TestData.createTestProduct(id: '2', stock: 0),
          TestData.createTestProduct(id: '3', stock: 5),
        ];

        provider.setInStockOnlyFilter(true);

        final results = provider.searchAndFilter(products);

        expect(results.length, equals(2));
        expect(results.every((p) => p.isInStock), isTrue);
      });

      test('filters by seller', () {
        final products = [
          TestData.createTestProduct(id: '1', seller: 'Amazon'),
          TestData.createTestProduct(id: '2', seller: 'eBay'),
        ];

        provider.setSellerFilter('Amazon');

        final results = provider.searchAndFilter(products);

        expect(results.length, equals(1));
        expect(results.first.seller, equals('Amazon'));
      });

      test('filters by deals only', () {
        final products = [
          TestData.createTestProduct(id: '1', price: 80.0, oldPrice: 100.0), // Has discount
          TestData.createTestProduct(id: '2', price: 100.0, oldPrice: 100.0), // No discount
        ];

        provider.setDealsOnlyFilter(true);

        final results = provider.searchAndFilter(products);

        expect(results.length, equals(1));
        expect(results.first.discount, greaterThan(0));
      });

      test('combines search and filters', () {
        final products = [
          TestData.createTestProduct(id: '1', name: 'Laptop', category: 'Electronics'),
          TestData.createTestProduct(id: '2', name: 'Laptop Bag', category: 'Accessories'),
          TestData.createTestProduct(id: '3', name: 'Phone', category: 'Electronics'),
        ];

        provider.setQuery('laptop');
        provider.setCategoryFilter('Electronics');

        final results = provider.searchAndFilter(products);

        expect(results.length, equals(1));
        expect(results.first.name, equals('Laptop'));
      });
    });

    group('Sorting', () {
      setUp(() async {
        provider = SearchProvider(mockPersistenceService);
        await Future.delayed(Duration.zero);
      });

      test('relevance sort maintains search score order', () {
        final products = [
          TestData.createTestProduct(id: '1', name: 'phone'),
          TestData.createTestProduct(id: '2', name: 'smartphone'),
          TestData.createTestProduct(id: '3', name: 'my phone'),
        ];

        provider.setQuery('phone');
        provider.setSortBy(ProductSort.relevance);

        final results = provider.searchAndFilter(products);

        expect(results.first.name, equals('phone')); // Exact match first
      });

      test('price low to high sort', () {
        final products = [
          TestData.createTestProduct(id: '1', price: 300.0),
          TestData.createTestProduct(id: '2', price: 100.0),
          TestData.createTestProduct(id: '3', price: 200.0),
        ];

        provider.setSortBy(ProductSort.priceLowToHigh);

        final results = provider.searchAndFilter(products);

        expect(results[0].price, equals(100.0));
        expect(results[1].price, equals(200.0));
        expect(results[2].price, equals(300.0));
      });

      test('price high to low sort', () {
        final products = [
          TestData.createTestProduct(id: '1', price: 100.0),
          TestData.createTestProduct(id: '2', price: 300.0),
          TestData.createTestProduct(id: '3', price: 200.0),
        ];

        provider.setSortBy(ProductSort.priceHighToLow);

        final results = provider.searchAndFilter(products);

        expect(results[0].price, equals(300.0));
        expect(results[1].price, equals(200.0));
        expect(results[2].price, equals(100.0));
      });

      test('rating sort (highest first)', () {
        final products = [
          TestData.createTestProduct(id: '1', rating: 3.0),
          TestData.createTestProduct(id: '2', rating: 5.0),
          TestData.createTestProduct(id: '3', rating: 4.0),
        ];

        provider.setSortBy(ProductSort.rating);

        final results = provider.searchAndFilter(products);

        expect(results[0].rating, equals(5.0));
        expect(results[1].rating, equals(4.0));
        expect(results[2].rating, equals(3.0));
      });

      test('discount sort (highest first)', () {
        final products = [
          TestData.createTestProduct(id: '1', price: 90.0, oldPrice: 100.0), // 10%
          TestData.createTestProduct(id: '2', price: 50.0, oldPrice: 100.0), // 50%
          TestData.createTestProduct(id: '3', price: 70.0, oldPrice: 100.0), // 30%
        ];

        provider.setSortBy(ProductSort.discount);

        final results = provider.searchAndFilter(products);

        expect(results[0].discount, equals(50));
        expect(results[1].discount, equals(30));
        expect(results[2].discount, equals(10));
      });

      test('popularity sort by review count', () {
        final products = [
          TestData.createTestProduct(id: '1', reviewCount: 10),
          TestData.createTestProduct(id: '2', reviewCount: 100),
          TestData.createTestProduct(id: '3', reviewCount: 50),
        ];

        provider.setSortBy(ProductSort.popularity);

        final results = provider.searchAndFilter(products);

        expect(results[0].reviewCount, equals(100));
        expect(results[1].reviewCount, equals(50));
        expect(results[2].reviewCount, equals(10));
      });
    });

    group('Persistence', () {
      setUp(() async {
        provider = SearchProvider(mockPersistenceService);
        await Future.delayed(Duration.zero);
        reset(mockPersistenceService);
      });

      test('saves recent searches after add', () async {
        when(() => mockPersistenceService.saveRecentSearches(any()))
            .thenAnswer((_) async => true);

        provider.addRecentSearch('laptop');

        await Future.delayed(Duration.zero);

        verify(() => mockPersistenceService.saveRecentSearches(['laptop'])).called(1);
      });

      test('saves recent searches after remove', () async {
        when(() => mockPersistenceService.saveRecentSearches(any()))
            .thenAnswer((_) async => true);

        provider.addRecentSearch('laptop');
        reset(mockPersistenceService);
        when(() => mockPersistenceService.saveRecentSearches(any()))
            .thenAnswer((_) async => true);

        provider.removeRecentSearch('laptop');

        await Future.delayed(Duration.zero);

        verify(() => mockPersistenceService.saveRecentSearches([])).called(1);
      });

      test('saves recent searches after clear', () async {
        when(() => mockPersistenceService.saveRecentSearches(any()))
            .thenAnswer((_) async => true);

        provider.addRecentSearch('laptop');
        reset(mockPersistenceService);
        when(() => mockPersistenceService.saveRecentSearches(any()))
            .thenAnswer((_) async => true);

        provider.clearRecentSearches();

        await Future.delayed(Duration.zero);

        verify(() => mockPersistenceService.saveRecentSearches([])).called(1);
      });

      test('handles save error without throwing', () async {
        when(() => mockPersistenceService.saveRecentSearches(any()))
            .thenThrow(Exception('Save failed'));

        expect(() => provider.addRecentSearch('laptop'), returnsNormally);
      });

      test('loads recent searches on initialization', () async {
        when(() => mockPersistenceService.loadRecentSearches())
            .thenReturn(['laptop', 'phone']);

        final newProvider = SearchProvider(mockPersistenceService);

        await Future.delayed(Duration.zero);

        expect(newProvider.recentSearches, equals(['laptop', 'phone']));

        newProvider.dispose();
      });

      test('handles load error without throwing', () async {
        when(() => mockPersistenceService.loadRecentSearches())
            .thenThrow(Exception('Load failed'));

        expect(() => SearchProvider(mockPersistenceService), returnsNormally);
      });
    });

    group('Edge Cases', () {
      setUp(() async {
        provider = SearchProvider(mockPersistenceService);
        await Future.delayed(Duration.zero);
      });

      test('empty query returns all products', () {
        final products = TestData.createProductList(5);

        final results = provider.searchAndFilter(products);

        expect(results.length, equals(5));
      });

      test('query with special characters normalizes punctuation', () {
        final products = [
          TestData.createTestProduct(id: '1', name: 'Product123'),
        ];

        // Query normalization removes punctuation, so "product-123" becomes "product123"
        // Product name "Product123" normalized is "product123"
        // They match!
        provider.setQuery('product-123');

        final results = provider.searchAndFilter(products);

        expect(results.length, equals(1));
      });

      test('query with unicode characters', () {
        final products = [
          TestData.createTestProduct(id: '1', name: 'محصول'),
        ];

        provider.setQuery('محصول');

        final results = provider.searchAndFilter(products);

        expect(results.length, equals(1));
      });

      test('whitespace-only query is treated as empty', () {
        final products = TestData.createProductList(3);

        provider.setQuery('   ');

        final results = provider.searchAndFilter(products);

        expect(results.length, equals(3));
      });

      test('search with no matching products returns empty', () {
        final products = TestData.createProductList(3);

        provider.setQuery('nonexistent');

        final results = provider.searchAndFilter(products);

        expect(results, isEmpty);
      });

      test('filters with no matching products returns empty', () {
        final products = TestData.createProductList(3);

        provider.setCategoryFilter('NonexistentCategory');

        final results = provider.searchAndFilter(products);

        expect(results, isEmpty);
      });

      test('multiple filters narrow down results', () {
        final products = [
          TestData.createTestProduct(id: '1', category: 'Electronics', brand: 'Apple', price: 100.0),
          TestData.createTestProduct(id: '2', category: 'Electronics', brand: 'Samsung', price: 100.0),
          TestData.createTestProduct(id: '3', category: 'Clothing', brand: 'Apple', price: 100.0),
        ];

        provider.setCategoryFilter('Electronics');
        provider.setBrandFilter('Apple');

        final results = provider.searchAndFilter(products);

        expect(results.length, equals(1));
        expect(results.first.id, equals('1'));
      });

      test('can dispose after operations', () {
        provider.setQuery('laptop');
        provider.addRecentSearch('laptop');

        expect(() => provider.dispose(), returnsNormally);
      });
    });

    group('Listener Notifications', () {
      setUp(() async {
        provider = SearchProvider(mockPersistenceService);
        await Future.delayed(Duration.zero);
      });

      test('setQuery notifies listeners once', () {
        var notificationCount = 0;
        provider.addListener(() => notificationCount++);

        provider.setQuery('laptop');

        expect(notificationCount, equals(1));
      });

      test('multiple operations notify listeners correctly', () {
        var notificationCount = 0;
        provider.addListener(() => notificationCount++);

        provider.setQuery('laptop');
        provider.setCategoryFilter('Electronics');
        provider.setSortBy(ProductSort.priceLowToHigh);

        expect(notificationCount, equals(3));
      });

      test('multiple listeners all receive notifications', () {
        var count1 = 0, count2 = 0, count3 = 0;
        provider.addListener(() => count1++);
        provider.addListener(() => count2++);
        provider.addListener(() => count3++);

        provider.setQuery('laptop');

        expect(count1, equals(1));
        expect(count2, equals(1));
        expect(count3, equals(1));
      });

      test('removed listener does not receive notifications', () {
        var removedCount = 0;
        var activeCount = 0;

        void removedListener() => removedCount++;
        void activeListener() => activeCount++;

        provider.addListener(removedListener);
        provider.addListener(activeListener);

        provider.removeListener(removedListener);

        provider.setQuery('laptop');

        expect(removedCount, equals(0));
        expect(activeCount, equals(1));
      });
    });
  });
}
