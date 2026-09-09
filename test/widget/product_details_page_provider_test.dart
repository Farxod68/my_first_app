import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:my_first_app/core/constants/widget_keys.dart';
import 'package:my_first_app/core/theme/app_theme.dart';
import 'package:my_first_app/data/data_sources/local/mock_products.dart' as mock_catalog;
import 'package:my_first_app/data/models/product.dart';
import 'package:my_first_app/l10n/app_localizations.dart';
import 'package:my_first_app/presentation/providers/cart_provider.dart';
import 'package:my_first_app/presentation/providers/currency_provider.dart';
import 'package:my_first_app/presentation/providers/product_provider.dart';
import 'package:my_first_app/presentation/providers/recently_viewed_provider.dart';
import 'package:my_first_app/presentation/providers/wishlist_provider.dart';
import 'package:my_first_app/presentation/screens/product_details/product_details_page.dart';
import '../helpers/test_data.dart';
import '../mocks/mock_cart_provider.dart';
import '../mocks/mock_persistence_service.dart';
import '../mocks/mock_product_repository.dart';
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

CurrencyProvider _createCurrencyProvider() {
  final mockPersistenceService = MockPersistenceService();
  when(() => mockPersistenceService.getString('currency_code')).thenReturn(null);
  return CurrencyProvider(mockPersistenceService);
}

/// Pumps [ProductDetailsPage] for [product] with its required providers.
///
/// [productProvider] is registered in the tree only when non-null,
/// mirroring main.dart's `if (supabaseInitialized)` gate - passing null
/// reproduces the "Supabase not configured" case ProductDetailsPage's
/// Related Products section must fall back from gracefully.
Future<void> pumpProductDetailsPage(
  WidgetTester tester,
  Product product, {
  ProductProvider? productProvider,
  MockCartProvider? cartProvider,
  MockWishlistProvider? wishlistProvider,
}) async {
  tester.view.physicalSize = const Size(800, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final mockCartProvider = cartProvider ?? MockCartProvider();
  if (cartProvider == null) {
    when(() => mockCartProvider.addToCart(any())).thenReturn(null);
  }

  final mockWishlistProvider = wishlistProvider ?? MockWishlistProvider();
  if (wishlistProvider == null) {
    when(() => mockWishlistProvider.isFavorite(any())).thenReturn(false);
    when(() => mockWishlistProvider.toggleFavorite(any())).thenReturn(null);
  }

  final mockRecentlyViewedProvider = MockRecentlyViewedProvider();
  when(() => mockRecentlyViewedProvider.addProduct(any())).thenReturn(null);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CartProvider>.value(value: mockCartProvider),
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
        theme: AppTheme.lightTheme,
        locale: const Locale('en'),
        localizationsDelegates: _localizationsDelegates,
        supportedLocales: _supportedLocales,
        home: ProductDetailsPage(product: product),
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
  group('ProductDetailsPage Widget Tests (Phase 29E-4: ProductProvider migration)', () {
    setUpAll(() {
      registerFallbackValue(TestData.createTestProduct());
    });

    testWidgets(
        'falls back to the local mock catalog for Related Products when ProductProvider is not registered',
        (tester) async {
      final product = mock_catalog.products.firstWhere((p) => p.id == 'elec-001');

      await pumpProductDetailsPage(tester, product, productProvider: null);
      await tester.pumpAndSettle();

      expect(find.text('Related Products'), findsOneWidget);
      expect(find.byKey(WidgetKeys.productCard('elec-002')), findsOneWidget);
      expect(find.byKey(WidgetKeys.productDetailsPageLoading), findsNothing);
      expect(find.byKey(WidgetKeys.productDetailsPageError), findsNothing);
      expect(find.byKey(WidgetKeys.productDetailsPageEmpty), findsNothing);
      expect(find.byKey(WidgetKeys.productDetailsPageNotFound), findsNothing);
    });

    testWidgets(
        'shows a loading indicator in the related-products area while ProductProvider is loading, without crashing',
        (tester) async {
      final mockRepo = MockProductRepository();
      final completer = Completer<List<Product>>();
      when(() => mockRepo.fetchProducts()).thenAnswer((_) => completer.future);

      final productProvider = ProductProvider(mockRepo);
      addTearDown(() => completer.complete(const []));

      final product = TestData.createTestProduct(id: 'p1', name: 'Loading Product');

      await pumpProductDetailsPage(tester, product, productProvider: productProvider);

      // The main page content (from widget.product directly) still renders.
      expect(find.text('Loading Product'), findsOneWidget);
      expect(find.byKey(WidgetKeys.productDetailsPageLoading), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byKey(WidgetKeys.productDetailsPageError), findsNothing);
      expect(find.byKey(WidgetKeys.productDetailsPageEmpty), findsNothing);
      expect(find.byKey(WidgetKeys.productDetailsPageNotFound), findsNothing);
    });

    testWidgets(
        'shows a safe error state in the related-products area when ProductProvider fails to load, without crashing',
        (tester) async {
      final mockRepo = MockProductRepository();
      when(() => mockRepo.fetchProducts()).thenThrow(Exception('Network error'));

      final productProvider = ProductProvider(mockRepo);
      final product = TestData.createTestProduct(id: 'p1', name: 'Error Product');

      await pumpProductDetailsPage(tester, product, productProvider: productProvider);
      await tester.pumpAndSettle();

      expect(find.text('Error Product'), findsOneWidget);
      expect(find.byKey(WidgetKeys.productDetailsPageError), findsOneWidget);
      expect(find.byKey(WidgetKeys.productDetailsPageLoading), findsNothing);
      expect(find.byKey(WidgetKeys.productDetailsPageEmpty), findsNothing);
      expect(find.byKey(WidgetKeys.productDetailsPageNotFound), findsNothing);
    });

    testWidgets(
        'shows the empty-catalog state in the related-products area when ProductProvider loads no products',
        (tester) async {
      final mockRepo = MockProductRepository();
      when(() => mockRepo.fetchProducts()).thenAnswer((_) async => const <Product>[]);

      final productProvider = ProductProvider(mockRepo);
      final product = TestData.createTestProduct(id: 'p1', name: 'Empty Catalog Product');

      await pumpProductDetailsPage(tester, product, productProvider: productProvider);
      await tester.pumpAndSettle();

      expect(find.text('Empty Catalog Product'), findsOneWidget);
      expect(find.byKey(WidgetKeys.productDetailsPageEmpty), findsOneWidget);
      expect(find.byKey(WidgetKeys.productDetailsPageLoading), findsNothing);
      expect(find.byKey(WidgetKeys.productDetailsPageError), findsNothing);
      expect(find.byKey(WidgetKeys.productDetailsPageNotFound), findsNothing);
    });

    testWidgets(
        'shows the not-found state (never crashing, never substituting) when the viewed product is absent from a non-empty ProductProvider catalog',
        (tester) async {
      final mockRepo = MockProductRepository();
      final providerProducts = [
        TestData.createTestProduct(id: 'elec-001', name: 'Provider Watch', category: 'electronics'),
        TestData.createTestProduct(id: 'elec-002', name: 'Provider Earbuds', category: 'electronics'),
      ];
      when(() => mockRepo.fetchProducts()).thenAnswer((_) async => providerProducts);

      final productProvider = ProductProvider(mockRepo);
      // Viewed product's id ('unknown-999') is not in the provider's catalog.
      final product = TestData.createTestProduct(
        id: 'unknown-999',
        name: 'Not In Catalog',
        category: 'electronics',
      );

      await pumpProductDetailsPage(tester, product, productProvider: productProvider);
      await tester.pumpAndSettle();

      // Main product content still renders from widget.product directly.
      expect(find.text('Not In Catalog'), findsOneWidget);
      expect(find.byKey(WidgetKeys.productDetailsPageNotFound), findsOneWidget);
      expect(find.byKey(WidgetKeys.productDetailsPageLoading), findsNothing);
      expect(find.byKey(WidgetKeys.productDetailsPageError), findsNothing);
      expect(find.byKey(WidgetKeys.productDetailsPageEmpty), findsNothing);
      // Never silently substitute another product's related items.
      expect(find.text('Provider Watch'), findsNothing);
      expect(find.text('Provider Earbuds'), findsNothing);
      expect(find.text('Related Products'), findsNothing);
    });

    testWidgets(
        'renders Related Products from ProductProvider when the viewed product is present, selecting only its own category and excluding itself',
        (tester) async {
      final mockRepo = MockProductRepository();
      final providerProducts = [
        TestData.createTestProduct(id: 'elec-001', name: 'Viewed Electronics', category: 'electronics'),
        TestData.createTestProduct(id: 'elec-002', name: 'Related Electronics', category: 'electronics'),
        TestData.createTestProduct(id: 'cloth-001', name: 'Unrelated Clothing', category: 'clothing'),
      ];
      when(() => mockRepo.fetchProducts()).thenAnswer((_) async => providerProducts);

      final productProvider = ProductProvider(mockRepo);
      final product = providerProducts.first; // elec-001

      await pumpProductDetailsPage(tester, product, productProvider: productProvider);
      await tester.pumpAndSettle();

      expect(find.text('Viewed Electronics'), findsOneWidget);
      expect(find.text('Related Products'), findsOneWidget);
      expect(find.byKey(WidgetKeys.productCard('elec-002')), findsOneWidget);
      // The viewed product itself must not appear in its own related list.
      expect(find.byKey(WidgetKeys.productCard('elec-001')), findsNothing);
      // A different category must not be pulled in as "related".
      expect(find.byKey(WidgetKeys.productCard('cloth-001')), findsNothing);
      expect(find.byKey(WidgetKeys.productDetailsPageLoading), findsNothing);
      expect(find.byKey(WidgetKeys.productDetailsPageError), findsNothing);
      expect(find.byKey(WidgetKeys.productDetailsPageEmpty), findsNothing);
      expect(find.byKey(WidgetKeys.productDetailsPageNotFound), findsNothing);
    });

    testWidgets(
        'Add to Cart still works when ProductProvider is registered and loaded',
        (tester) async {
      final mockRepo = MockProductRepository();
      final providerProducts = [
        TestData.createTestProduct(id: 'p1', name: 'Cart Product', stock: 10),
      ];
      when(() => mockRepo.fetchProducts()).thenAnswer((_) async => providerProducts);

      final productProvider = ProductProvider(mockRepo);
      final mockCartProvider = MockCartProvider();
      final product = providerProducts.first;

      await pumpProductDetailsPage(
        tester,
        product,
        productProvider: productProvider,
        cartProvider: mockCartProvider,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Add to Cart'));
      await tester.pump();

      verify(() => mockCartProvider.addToCart(product)).called(1);
      expect(find.text('Cart Product added to cart'), findsOneWidget);
    });

    testWidgets(
        'favorite/wishlist toggle still works when ProductProvider is registered and loaded',
        (tester) async {
      final mockRepo = MockProductRepository();
      final providerProducts = [
        TestData.createTestProduct(id: 'p1', name: 'Wishlist Product'),
      ];
      when(() => mockRepo.fetchProducts()).thenAnswer((_) async => providerProducts);

      final productProvider = ProductProvider(mockRepo);
      final mockWishlistProvider = MockWishlistProvider();
      var isFav = false;
      when(() => mockWishlistProvider.isFavorite(any())).thenAnswer((_) => isFav);
      when(() => mockWishlistProvider.toggleFavorite(any()))
          .thenAnswer((_) => isFav = true);
      final product = providerProducts.first;

      await pumpProductDetailsPage(
        tester,
        product,
        productProvider: productProvider,
        wishlistProvider: mockWishlistProvider,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.favorite_border));
      await tester.pump();

      verify(() => mockWishlistProvider.toggleFavorite('p1')).called(1);
      expect(find.text('Added to wishlist'), findsOneWidget);
    });

    testWidgets(
        'tapping a ProductProvider-supplied related product navigates via pushReplacement to that product',
        (tester) async {
      final mockRepo = MockProductRepository();
      final providerProducts = [
        TestData.createTestProduct(id: 'elec-001', name: 'Viewed Electronics', category: 'electronics'),
        TestData.createTestProduct(id: 'elec-002', name: 'Related Electronics', category: 'electronics'),
      ];
      when(() => mockRepo.fetchProducts()).thenAnswer((_) async => providerProducts);

      final productProvider = ProductProvider(mockRepo);
      final product = providerProducts.first;

      await pumpProductDetailsPage(tester, product, productProvider: productProvider);
      await tester.pumpAndSettle();

      final relatedCard = find.byKey(WidgetKeys.productCard('elec-002'));
      await tester.ensureVisible(relatedCard);
      await tester.pumpAndSettle();

      await tester.tap(relatedCard);
      await tester.pumpAndSettle();

      expect(find.byType(ProductDetailsPage), findsOneWidget);
      final detailsPage =
          tester.widget<ProductDetailsPage>(find.byType(ProductDetailsPage));
      expect(detailsPage.product.id, 'elec-002');
    });
  });
}
