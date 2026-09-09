import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:my_first_app/data/data_sources/local/mock_products.dart' as mock_catalog;
import 'package:my_first_app/data/models/filter_models.dart';
import 'package:my_first_app/data/models/product.dart';
import 'package:my_first_app/presentation/providers/product_provider.dart';
import 'package:my_first_app/presentation/providers/search_provider.dart';
import 'package:my_first_app/presentation/providers/wishlist_provider.dart';
import 'package:my_first_app/presentation/screens/search/search_results_page.dart';
import 'package:my_first_app/presentation/widgets/product_search_delegate.dart';
import '../helpers/test_data.dart';
import '../helpers/widget_test_helpers.dart';
import '../mocks/mock_product_repository.dart';
import '../mocks/mock_search_provider.dart';
import '../mocks/mock_wishlist_provider.dart';

void main() {
  group('ProductSearchDelegate Widget Tests (Phase 29E-5: ProductProvider migration)', () {
    late MockSearchProvider mockSearchProvider;
    late MockWishlistProvider mockWishlistProvider;
    late ProductSearchDelegate searchDelegate;

    setUpAll(() {
      registerFallbackValue(TestData.createTestProduct());
    });

    setUp(() {
      mockSearchProvider = MockSearchProvider();
      mockWishlistProvider = MockWishlistProvider();
      searchDelegate = ProductSearchDelegate();

      when(() => mockSearchProvider.recentSearches).thenReturn([]);
      when(() => mockSearchProvider.setQuery(any())).thenReturn(null);
      when(() => mockSearchProvider.addRecentSearch(any())).thenReturn(null);
      when(() => mockSearchProvider.clearRecentSearches()).thenReturn(null);
      when(() => mockSearchProvider.removeRecentSearch(any())).thenReturn(null);
      when(() => mockSearchProvider.getSuggestions(any(), maxSuggestions: any(named: 'maxSuggestions')))
          .thenReturn([]);
      when(() => mockSearchProvider.searchAndFilter(any())).thenReturn([]);
      when(() => mockSearchProvider.hasSearch).thenReturn(false);
      when(() => mockSearchProvider.hasFilters).thenReturn(false);
      when(() => mockSearchProvider.filters).thenReturn(const ProductFilters());
      when(() => mockWishlistProvider.isFavorite(any())).thenReturn(false);
    });

    /// Pumps a button that opens [searchDelegate] via `showSearch()`.
    ///
    /// [productProvider] is registered in the tree only when non-null,
    /// mirroring main.dart's `if (supabaseInitialized)` gate - passing null
    /// reproduces the "Supabase not configured" case this delegate must fall
    /// back from gracefully. `showSearch()` pushes its route on the same
    /// Navigator as this button, which sits below the providers here -
    /// exercising exactly the tree shape `ProductProvider` has in main.dart
    /// (registered above `MaterialApp`).
    Future<void> pumpSearchDelegate(
      WidgetTester tester, {
      ProductProvider? productProvider,
    }) async {
      await pumpAppWithProviders(
        tester,
        Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () {
                showSearch(context: context, delegate: searchDelegate);
              },
              child: const Text('Open Search'),
            );
          },
        ),
        providers: [
          ChangeNotifierProvider<SearchProvider>.value(value: mockSearchProvider),
          ChangeNotifierProvider<WishlistProvider>.value(value: mockWishlistProvider),
          if (productProvider != null)
            ChangeNotifierProvider<ProductProvider>.value(value: productProvider),
        ],
      );

      await tester.tap(find.text('Open Search'));
      await tester.pumpAndSettle();
    }

    testWidgets(
        'buildSuggestions uses the local mock catalog when ProductProvider is not registered',
        (tester) async {
      await pumpSearchDelegate(tester, productProvider: null);

      searchDelegate.query = 'watch';
      await tester.pumpAndSettle();

      verify(() => mockSearchProvider.getSuggestions(mock_catalog.products, maxSuggestions: 8))
          .called(greaterThan(0));
    });

    testWidgets(
        'buildSuggestions uses ProductProvider.products (not the mock catalog) once loaded',
        (tester) async {
      final mockRepo = MockProductRepository();
      final providerProducts = [
        TestData.createTestProduct(id: 'provider-only-1', name: 'Provider Exclusive Product'),
      ];
      when(() => mockRepo.fetchProducts()).thenAnswer((_) async => providerProducts);
      final productProvider = ProductProvider(mockRepo);

      await pumpSearchDelegate(tester, productProvider: productProvider);
      await tester.pumpAndSettle();

      searchDelegate.query = 'provider';
      await tester.pumpAndSettle();

      verify(() => mockSearchProvider.getSuggestions(providerProducts, maxSuggestions: 8))
          .called(greaterThan(0));
      verifyNever(
        () => mockSearchProvider.getSuggestions(mock_catalog.products, maxSuggestions: any(named: 'maxSuggestions')),
      );
    });

    testWidgets(
        'does not crash while ProductProvider is loading (empty catalog passed through safely)',
        (tester) async {
      final mockRepo = MockProductRepository();
      final completer = Completer<List<Product>>();
      when(() => mockRepo.fetchProducts()).thenAnswer((_) => completer.future);
      final productProvider = ProductProvider(mockRepo);
      addTearDown(() => completer.complete(const []));

      await pumpSearchDelegate(tester, productProvider: productProvider);

      searchDelegate.query = 'anything';
      await tester.pump();

      expect(tester.takeException(), isNull);
      verify(() => mockSearchProvider.getSuggestions(const <Product>[], maxSuggestions: 8))
          .called(greaterThan(0));
    });

    testWidgets(
        'does not crash when ProductProvider has failed to load (empty catalog passed through safely)',
        (tester) async {
      final mockRepo = MockProductRepository();
      when(() => mockRepo.fetchProducts()).thenThrow(Exception('Network error'));
      final productProvider = ProductProvider(mockRepo);

      await pumpSearchDelegate(tester, productProvider: productProvider);
      await tester.pumpAndSettle();

      searchDelegate.query = 'anything';
      await tester.pump();

      expect(tester.takeException(), isNull);
      verify(() => mockSearchProvider.getSuggestions(const <Product>[], maxSuggestions: 8))
          .called(greaterThan(0));
    });

    testWidgets(
        'existing search-result navigation remains intact when ProductProvider is registered',
        (tester) async {
      final mockRepo = MockProductRepository();
      when(() => mockRepo.fetchProducts()).thenAnswer((_) async => const <Product>[]);
      final productProvider = ProductProvider(mockRepo);

      await pumpSearchDelegate(tester, productProvider: productProvider);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'laptop');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      verify(() => mockSearchProvider.setQuery('laptop')).called(greaterThan(0));
      verify(() => mockSearchProvider.addRecentSearch('laptop')).called(greaterThan(0));
      expect(find.byType(SearchResultsPage), findsOneWidget);
    });
  });
}
