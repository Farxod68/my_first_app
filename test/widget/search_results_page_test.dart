import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:my_first_app/core/constants/widget_keys.dart';
import 'package:my_first_app/core/theme/app_theme.dart';
import 'package:my_first_app/data/data_sources/local/mock_products.dart';
import 'package:my_first_app/l10n/app_localizations.dart';
import 'package:my_first_app/presentation/providers/cart_provider.dart';
import 'package:my_first_app/presentation/providers/currency_provider.dart';
import 'package:my_first_app/presentation/providers/recently_viewed_provider.dart';
import 'package:my_first_app/presentation/providers/search_provider.dart';
import 'package:my_first_app/presentation/providers/wishlist_provider.dart';
import 'package:my_first_app/presentation/screens/product_details/product_details_page.dart';
import 'package:my_first_app/presentation/screens/search/search_results_page.dart';
import 'package:my_first_app/presentation/widgets/product_card.dart';
import '../mocks/mock_cart_provider.dart';
import '../mocks/mock_persistence_service.dart';
import '../mocks/mock_recently_viewed_provider.dart';
import '../mocks/mock_wishlist_provider.dart';

const _localizationsDelegates = [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

const _supportedLocales = [
  Locale('en'),
  Locale('es'),
  Locale('fr'),
  Locale('uz'),
];

void main() {
  group('SearchResultsPage Widget Tests', () {
    late MockWishlistProvider mockWishlistProvider;
    late MockCartProvider mockCartProvider;
    late MockRecentlyViewedProvider mockRecentlyViewedProvider;

    setUpAll(() {
      registerFallbackValue(products.first);
    });

    setUp(() {
      mockWishlistProvider = MockWishlistProvider();
      mockCartProvider = MockCartProvider();
      mockRecentlyViewedProvider = MockRecentlyViewedProvider();
      when(() => mockWishlistProvider.isFavorite(any())).thenReturn(false);
      when(() => mockCartProvider.addToCart(any())).thenReturn(null);
      when(() => mockRecentlyViewedProvider.addProduct(any()))
          .thenReturn(null);
    });

    // Real SearchProvider backed by a stubbed MockPersistenceService, so
    // interactive state changes (sort, filters) behave exactly as in
    // production instead of requiring hand-written stateful mock closures
    // for every one of the filter/sort dimensions.
    SearchProvider createSearchProvider() {
      final mockPersistenceService = MockPersistenceService();
      when(() => mockPersistenceService.loadRecentSearches())
          .thenReturn(const []);
      when(() => mockPersistenceService.saveRecentSearches(any()))
          .thenAnswer((_) async => true);
      return SearchProvider(mockPersistenceService);
    }

    CurrencyProvider createCurrencyProvider() {
      final mockPersistenceService = MockPersistenceService();
      when(() => mockPersistenceService.getString('currency_code'))
          .thenReturn(null);
      return CurrencyProvider(mockPersistenceService);
    }

    Future<void> pumpPage(
      WidgetTester tester,
      SearchProvider searchProvider,
    ) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SearchProvider>.value(
                value: searchProvider),
            ChangeNotifierProvider<WishlistProvider>.value(
                value: mockWishlistProvider),
            ChangeNotifierProvider<CartProvider>.value(
                value: mockCartProvider),
            ChangeNotifierProvider<RecentlyViewedProvider>.value(
                value: mockRecentlyViewedProvider),
            ChangeNotifierProvider<CurrencyProvider>(
              create: (_) => createCurrencyProvider(),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            locale: const Locale('en'),
            localizationsDelegates: _localizationsDelegates,
            supportedLocales: _supportedLocales,
            home: const SearchResultsPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();
    }

    testWidgets(
        '1. No search, no filters shows all products with correct count',
        (tester) async {
      final searchProvider = createSearchProvider();

      await pumpPage(tester, searchProvider);

      expect(find.text('${products.length} products'), findsOneWidget);
    });

    testWidgets(
        '2. A filter matching zero products (no query) shows the generic No products found empty state',
        (tester) async {
      final searchProvider = createSearchProvider();
      searchProvider.setCategoryFilter('no_such_category_xyz');

      await pumpPage(tester, searchProvider);

      expect(find.text('No products found'), findsOneWidget);
      expect(
        find.text('Try searching with different keywords'),
        findsOneWidget,
      );
    });

    testWidgets(
        '3. A query matching zero products shows the query-specific No results for text',
        (tester) async {
      final searchProvider = createSearchProvider();
      searchProvider.setQuery('zzz_no_such_product_zzz');

      await pumpPage(tester, searchProvider);

      expect(
        find.text('No results for "zzz_no_such_product_zzz"'),
        findsOneWidget,
      );
    });

    testWidgets('4. Populated results with an active search show Results for',
        (tester) async {
      final searchProvider = createSearchProvider();
      searchProvider.setQuery('watch');

      await pumpPage(tester, searchProvider);

      expect(find.text('Results for "watch"'), findsOneWidget);
    });

    testWidgets(
        '5. No active search hides the Results for line but still shows the count',
        (tester) async {
      final searchProvider = createSearchProvider();

      await pumpPage(tester, searchProvider);

      expect(find.textContaining('Results for'), findsNothing);
      expect(find.text('${products.length} products'), findsOneWidget);
    });

    testWidgets(
        '6. Filtering by a real category shows exactly its known products and no others',
        (tester) async {
      final electronicsIds = products
          .where((p) => p.category == 'electronics')
          .map((p) => p.id)
          .toList();
      final searchProvider = createSearchProvider();
      searchProvider.setCategoryFilter('electronics');

      await pumpPage(tester, searchProvider);

      // The GridView lazily builds only the cards within the viewport, so
      // assert the reported total count plus that every card actually
      // rendered belongs to the electronics set (nothing else leaks in).
      expect(find.text('${electronicsIds.length} products'), findsOneWidget);
      final builtIds = tester
          .widgetList<ProductCard>(find.byType(ProductCard))
          .map((w) => w.product.id)
          .toList();
      expect(builtIds, isNotEmpty);
      expect(builtIds.every(electronicsIds.contains), isTrue);
    });

    testWidgets(
        '7. Sorting by Price: Low to High orders visible results ascending',
        (tester) async {
      final searchProvider = createSearchProvider();
      searchProvider.setCategoryFilter('electronics');

      await pumpPage(tester, searchProvider);

      await tester.tap(find.byIcon(Icons.sort));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Price: Low to High'));
      await tester.pumpAndSettle();

      final expectedAscending = products
          .where((p) => p.category == 'electronics')
          .toList()
        ..sort((a, b) => a.price.compareTo(b.price));

      final builtIds = tester
          .widgetList<ProductCard>(find.byType(ProductCard))
          .map((w) => w.product.id)
          .toList();

      expect(builtIds, isNotEmpty);
      expect(
        builtIds,
        expectedAscending.take(builtIds.length).map((p) => p.id).toList(),
      );
    });

    testWidgets(
        '8. Sorting by Price: High to Low orders visible results descending',
        (tester) async {
      final searchProvider = createSearchProvider();
      searchProvider.setCategoryFilter('electronics');

      await pumpPage(tester, searchProvider);

      await tester.tap(find.byIcon(Icons.sort));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Price: High to Low'));
      await tester.pumpAndSettle();

      final expectedDescending = products
          .where((p) => p.category == 'electronics')
          .toList()
        ..sort((a, b) => b.price.compareTo(a.price));

      final builtIds = tester
          .widgetList<ProductCard>(find.byType(ProductCard))
          .map((w) => w.product.id)
          .toList();

      expect(builtIds, isNotEmpty);
      expect(
        builtIds,
        expectedDescending.take(builtIds.length).map((p) => p.id).toList(),
      );
    });

    testWidgets(
        '9. An active category filter chip can be removed via its delete icon',
        (tester) async {
      final searchProvider = createSearchProvider();
      searchProvider.setCategoryFilter('electronics');

      await pumpPage(tester, searchProvider);

      final chip = find.widgetWithText(Chip, 'Electronics');
      expect(chip, findsOneWidget);

      await tester.tap(
        find.descendant(of: chip, matching: find.byIcon(Icons.close)),
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(Chip, 'Electronics'), findsNothing);
      expect(find.text('${products.length} products'), findsOneWidget);
    });

    testWidgets(
        '10. Clear All removes every active filter and hides all chips',
        (tester) async {
      final searchProvider = createSearchProvider();
      searchProvider.setCategoryFilter('electronics');
      searchProvider.setDiscountFilter(30);

      await pumpPage(tester, searchProvider);

      expect(find.widgetWithText(Chip, 'Electronics'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Clear All'));
      await tester.pumpAndSettle();

      expect(find.byType(Chip), findsNothing);
      expect(find.text('${products.length} products'), findsOneWidget);
    });

    testWidgets(
        '11. Tapping the filter FAB opens the bottom sheet with all filter sections',
        (tester) async {
      final searchProvider = createSearchProvider();

      await pumpPage(tester, searchProvider);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Minimum Rating'), findsOneWidget);
      expect(find.text('Minimum Discount'), findsOneWidget);
      expect(find.text('Availability'), findsOneWidget);
    });

    testWidgets(
        '12. Selecting a Minimum Discount chip narrows results to real matching products only',
        (tester) async {
      final searchProvider = createSearchProvider();
      searchProvider.setCategoryFilter('electronics');
      final expectedCount = products
          .where((p) => p.category == 'electronics' && p.discount >= 30)
          .length;
      // Sanity: this must be a genuine partial narrowing, not all-or-nothing.
      final totalElectronics =
          products.where((p) => p.category == 'electronics').length;
      expect(expectedCount, greaterThan(0));
      expect(expectedCount, lessThan(totalElectronics));

      await pumpPage(tester, searchProvider);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ChoiceChip, '30% & up'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Apply Filters'));
      await tester.pumpAndSettle();

      expect(find.text('$expectedCount products'), findsOneWidget);
    });

    testWidgets(
        '13. Apply Filters closes the sheet without altering already-applied filters',
        (tester) async {
      final searchProvider = createSearchProvider();
      searchProvider.setCategoryFilter('electronics');

      await pumpPage(tester, searchProvider);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Apply Filters'));
      await tester.pumpAndSettle();

      expect(find.text('Category'), findsNothing);
      expect(searchProvider.filters.category, 'electronics');
    });

    testWidgets(
        '14. Tapping a product card navigates to ProductDetailsPage with the exact product',
        (tester) async {
      final searchProvider = createSearchProvider();
      searchProvider.setCategoryFilter('electronics');

      await pumpPage(tester, searchProvider);

      await tester.tap(find.byKey(WidgetKeys.productCard('elec-001')));
      await tester.pumpAndSettle();

      expect(find.byType(ProductDetailsPage), findsOneWidget);
      final detailsPage =
          tester.widget<ProductDetailsPage>(find.byType(ProductDetailsPage));
      expect(detailsPage.product.id, 'elec-001');
    });
  });
}
