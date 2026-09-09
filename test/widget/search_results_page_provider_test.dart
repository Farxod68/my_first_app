import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:my_first_app/core/constants/widget_keys.dart';
import 'package:my_first_app/data/models/product.dart';
import 'package:my_first_app/l10n/app_localizations.dart';
import 'package:my_first_app/presentation/providers/currency_provider.dart';
import 'package:my_first_app/presentation/providers/product_provider.dart';
import 'package:my_first_app/presentation/providers/recently_viewed_provider.dart';
import 'package:my_first_app/presentation/providers/search_provider.dart';
import 'package:my_first_app/presentation/providers/wishlist_provider.dart';
import 'package:my_first_app/presentation/screens/product_details/product_details_page.dart';
import 'package:my_first_app/presentation/screens/search/search_results_page.dart';
import 'package:my_first_app/presentation/widgets/product_card.dart';
import '../helpers/test_data.dart';
import '../mocks/mock_persistence_service.dart';
import '../mocks/mock_product_repository.dart';
import '../mocks/mock_recently_viewed_provider.dart';
import '../mocks/mock_wishlist_provider.dart';

/// Real SearchProvider backed by a stubbed MockPersistenceService, matching
/// search_results_page_test.dart's own pattern, so search/filter/sort
/// behaves exactly as in production.
SearchProvider _createSearchProvider() {
  final mockPersistenceService = MockPersistenceService();
  when(() => mockPersistenceService.loadRecentSearches()).thenReturn(const []);
  when(() => mockPersistenceService.saveRecentSearches(any()))
      .thenAnswer((_) async => true);
  return SearchProvider(mockPersistenceService);
}

CurrencyProvider _createCurrencyProvider() {
  final mockPersistenceService = MockPersistenceService();
  when(() => mockPersistenceService.getString('currency_code')).thenReturn(null);
  return CurrencyProvider(mockPersistenceService);
}

/// Pumps [SearchResultsPage] with its required providers.
///
/// [productProvider] is registered in the tree only when non-null, mirroring
/// main.dart's `if (supabaseInitialized)` gate - passing null reproduces the
/// "Supabase not configured" case SearchResultsPage must fall back from
/// gracefully.
Future<void> pumpSearchResultsPage(
  WidgetTester tester, {
  ProductProvider? productProvider,
  SearchProvider? searchProvider,
}) async {
  tester.view.physicalSize = const Size(800, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final mockWishlistProvider = MockWishlistProvider();
  when(() => mockWishlistProvider.isFavorite(any())).thenReturn(false);

  final mockRecentlyViewedProvider = MockRecentlyViewedProvider();
  when(() => mockRecentlyViewedProvider.addProduct(any())).thenReturn(null);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SearchProvider>.value(
          value: searchProvider ?? _createSearchProvider(),
        ),
        ChangeNotifierProvider<WishlistProvider>.value(value: mockWishlistProvider),
        ChangeNotifierProvider<RecentlyViewedProvider>.value(
          value: mockRecentlyViewedProvider,
        ),
        ChangeNotifierProvider<CurrencyProvider>(
          create: (_) => _createCurrencyProvider(),
        ),
        if (productProvider != null)
          ChangeNotifierProvider<ProductProvider>.value(value: productProvider),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('es'),
          Locale('fr'),
          Locale('uz'),
        ],
        home: const SearchResultsPage(),
      ),
    ),
  );

  // A single pump only - not pumpAndSettle, which would hang forever on the
  // loading-state test where ProductProvider's fetch never resolves during
  // the test body. Callers that need the catalog fully loaded/settled call
  // `await tester.pumpAndSettle()` themselves afterwards.
  await tester.pump();
}

void main() {
  group('SearchResultsPage Widget Tests (Phase 29E-3: ProductProvider migration)', () {
    setUpAll(() {
      registerFallbackValue(TestData.createTestProduct());
    });

    testWidgets('shows a loading indicator while ProductProvider is loading',
        (tester) async {
      final mockRepo = MockProductRepository();
      final completer = Completer<List<Product>>();
      when(() => mockRepo.fetchProducts()).thenAnswer((_) => completer.future);

      final productProvider = ProductProvider(mockRepo);
      addTearDown(() => completer.complete(const []));

      await pumpSearchResultsPage(tester, productProvider: productProvider);

      expect(find.byKey(WidgetKeys.searchResultsPageLoading), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byKey(WidgetKeys.searchResultsPageError), findsNothing);
      expect(find.byKey(WidgetKeys.searchResultsPageEmpty), findsNothing);
    });

    testWidgets('renders search results from products supplied by ProductProvider',
        (tester) async {
      final mockRepo = MockProductRepository();
      final testProducts = [
        TestData.createTestProduct(id: 'elec-001', name: 'Provider Watch', category: 'electronics'),
        TestData.createTestProduct(id: 'cloth-001', name: 'Provider Shoes', category: 'clothing'),
        TestData.createTestProduct(id: 'acc-001', name: 'Provider Bag', category: 'accessories'),
      ];
      when(() => mockRepo.fetchProducts()).thenAnswer((_) async => testProducts);

      final productProvider = ProductProvider(mockRepo);

      await pumpSearchResultsPage(tester, productProvider: productProvider);
      await tester.pumpAndSettle();

      expect(find.byKey(WidgetKeys.searchResultsPageLoading), findsNothing);
      expect(find.byKey(WidgetKeys.searchResultsPageError), findsNothing);
      expect(find.byKey(WidgetKeys.searchResultsPageEmpty), findsNothing);
      expect(find.text('3 products'), findsOneWidget);
      expect(find.byType(ProductCard), findsNWidgets(3));
    });

    testWidgets('shows the empty state when ProductProvider loads no products',
        (tester) async {
      final mockRepo = MockProductRepository();
      when(() => mockRepo.fetchProducts()).thenAnswer((_) async => const <Product>[]);

      final productProvider = ProductProvider(mockRepo);

      await pumpSearchResultsPage(tester, productProvider: productProvider);
      await tester.pumpAndSettle();

      expect(find.byKey(WidgetKeys.searchResultsPageEmpty), findsOneWidget);
      expect(find.byKey(WidgetKeys.searchResultsPageLoading), findsNothing);
      expect(find.byKey(WidgetKeys.searchResultsPageError), findsNothing);
    });

    testWidgets('shows the error state when ProductProvider fails to load',
        (tester) async {
      final mockRepo = MockProductRepository();
      when(() => mockRepo.fetchProducts()).thenThrow(Exception('Network error'));

      final productProvider = ProductProvider(mockRepo);

      await pumpSearchResultsPage(tester, productProvider: productProvider);
      await tester.pumpAndSettle();

      expect(find.byKey(WidgetKeys.searchResultsPageError), findsOneWidget);
      expect(find.byKey(WidgetKeys.searchResultsPageLoading), findsNothing);
      expect(find.byKey(WidgetKeys.searchResultsPageEmpty), findsNothing);
    });

    testWidgets(
        'falls back to the local mock catalog when ProductProvider is not registered (Supabase not configured)',
        (tester) async {
      // No ProductProvider passed - reproduces main.dart's behavior when
      // SupabaseConfig.isConfigured is false, exactly as before this
      // migration.
      await pumpSearchResultsPage(tester, productProvider: null);
      await tester.pumpAndSettle();

      expect(find.byKey(WidgetKeys.searchResultsPageLoading), findsNothing);
      expect(find.byKey(WidgetKeys.searchResultsPageError), findsNothing);
      expect(find.byKey(WidgetKeys.searchResultsPageEmpty), findsNothing);
      // 40 mock products, no active search/filters.
      expect(find.text('40 products'), findsOneWidget);
    });

    testWidgets(
        'category filtering narrows results to only the matching provider-supplied products',
        (tester) async {
      final mockRepo = MockProductRepository();
      final testProducts = [
        TestData.createTestProduct(id: 'elec-001', name: 'Provider Watch', category: 'electronics'),
        TestData.createTestProduct(id: 'elec-002', name: 'Provider Earbuds', category: 'electronics'),
        TestData.createTestProduct(id: 'cloth-001', name: 'Provider Shoes', category: 'clothing'),
      ];
      when(() => mockRepo.fetchProducts()).thenAnswer((_) async => testProducts);

      final productProvider = ProductProvider(mockRepo);
      final searchProvider = _createSearchProvider();
      searchProvider.setCategoryFilter('electronics');

      await pumpSearchResultsPage(
        tester,
        productProvider: productProvider,
        searchProvider: searchProvider,
      );
      await tester.pumpAndSettle();

      expect(find.text('2 products'), findsOneWidget);
      expect(find.text('Provider Watch'), findsOneWidget);
      expect(find.text('Provider Earbuds'), findsOneWidget);
      expect(find.text('Provider Shoes'), findsNothing);
    });

    testWidgets(
        'tapping a provider-supplied product card navigates to ProductDetailsPage',
        (tester) async {
      final mockRepo = MockProductRepository();
      final testProducts = [
        TestData.createTestProduct(id: 'elec-001', name: 'Provider Watch', category: 'electronics'),
      ];
      when(() => mockRepo.fetchProducts()).thenAnswer((_) async => testProducts);

      final productProvider = ProductProvider(mockRepo);

      await pumpSearchResultsPage(tester, productProvider: productProvider);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ProductCard));
      await tester.pumpAndSettle();

      expect(find.byType(ProductDetailsPage), findsOneWidget);
      final detailsPage =
          tester.widget<ProductDetailsPage>(find.byType(ProductDetailsPage));
      expect(detailsPage.product.id, 'elec-001');
    });
  });
}
