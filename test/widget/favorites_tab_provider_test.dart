import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:my_first_app/core/constants/widget_keys.dart';
import 'package:my_first_app/data/data_sources/local/mock_products.dart' as mock_catalog;
import 'package:my_first_app/data/models/product.dart';
import 'package:my_first_app/l10n/app_localizations.dart';
import 'package:my_first_app/presentation/providers/currency_provider.dart';
import 'package:my_first_app/presentation/providers/product_provider.dart';
import 'package:my_first_app/presentation/providers/wishlist_provider.dart';
import 'package:my_first_app/presentation/screens/home/tabs/favorites_tab.dart';
import '../helpers/test_data.dart';
import '../mocks/mock_persistence_service.dart';
import '../mocks/mock_product_repository.dart';
import '../mocks/mock_wishlist_provider.dart';

CurrencyProvider _createCurrencyProvider() {
  final mockPersistenceService = MockPersistenceService();
  when(() => mockPersistenceService.getString('currency_code')).thenReturn(null);
  return CurrencyProvider(mockPersistenceService);
}

/// Stubs [provider] so `getFavoriteProducts`/`isFavorite` behave like the
/// real `WishlistProvider` would for the given [favoriteIds], filtering
/// whatever catalog is actually passed in - this lets tests prove which
/// catalog (mock vs. ProductProvider) FavoritesTab resolved and handed over,
/// without needing to capture call arguments.
void _stubFavorites(MockWishlistProvider provider, Set<String> favoriteIds) {
  when(() => provider.getFavoriteProducts(any())).thenAnswer((invocation) {
    final catalog = invocation.positionalArguments[0] as List<Product>;
    return catalog.where((p) => favoriteIds.contains(p.id)).toList();
  });
  when(() => provider.isFavorite(any())).thenAnswer(
    (invocation) => favoriteIds.contains(invocation.positionalArguments[0] as String),
  );
  when(() => provider.toggleFavorite(any())).thenReturn(null);
}

/// Pumps [FavoritesTab] with its required providers.
///
/// [productProvider] is registered in the tree only when non-null,
/// mirroring main.dart's `if (supabaseInitialized)` gate - passing null
/// reproduces the "Supabase not configured" case FavoritesTab must fall
/// back from gracefully.
Future<void> pumpFavoritesTab(
  WidgetTester tester, {
  required MockWishlistProvider wishlistProvider,
  ProductProvider? productProvider,
  void Function(Product product, BuildContext context)? onOpenProduct,
}) async {
  tester.view.physicalSize = const Size(800, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<WishlistProvider>.value(value: wishlistProvider),
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
        home: Scaffold(
          body: FavoritesTab(onOpenProduct: onOpenProduct ?? (_, _) {}),
        ),
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
  group('FavoritesTab Widget Tests (Phase 29E-5: ProductProvider migration)', () {
    setUpAll(() {
      registerFallbackValue(TestData.createTestProduct());
    });

    testWidgets(
        'falls back to the local mock catalog when ProductProvider is not registered',
        (tester) async {
      final mockWishlistProvider = MockWishlistProvider();
      _stubFavorites(mockWishlistProvider, {'elec-001'});

      await pumpFavoritesTab(
        tester,
        wishlistProvider: mockWishlistProvider,
        productProvider: null,
      );
      await tester.pumpAndSettle();

      final expectedName =
          mock_catalog.products.firstWhere((p) => p.id == 'elec-001').name;
      expect(find.text(expectedName), findsOneWidget);
      expect(find.byKey(WidgetKeys.favoritesProductList), findsOneWidget);
      expect(find.byKey(WidgetKeys.favoritesTabLoading), findsNothing);
      expect(find.byKey(WidgetKeys.favoritesTabError), findsNothing);
    });

    testWidgets(
        'shows a loading state while ProductProvider is loading, without crashing or showing the favorites-empty state',
        (tester) async {
      final mockRepo = MockProductRepository();
      final completer = Completer<List<Product>>();
      when(() => mockRepo.fetchProducts()).thenAnswer((_) => completer.future);

      final productProvider = ProductProvider(mockRepo);
      addTearDown(() => completer.complete(const []));

      final mockWishlistProvider = MockWishlistProvider();
      _stubFavorites(mockWishlistProvider, {'elec-001'});

      await pumpFavoritesTab(
        tester,
        wishlistProvider: mockWishlistProvider,
        productProvider: productProvider,
      );

      expect(find.byKey(WidgetKeys.favoritesTabLoading), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byKey(WidgetKeys.favoritesTabError), findsNothing);
      expect(find.byKey(WidgetKeys.favoritesEmptyState), findsNothing);
      expect(find.byKey(WidgetKeys.favoritesProductList), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'shows a safe error state when ProductProvider fails to load, without crashing or showing the favorites-empty state',
        (tester) async {
      final mockRepo = MockProductRepository();
      when(() => mockRepo.fetchProducts()).thenThrow(Exception('Network error'));

      final productProvider = ProductProvider(mockRepo);

      final mockWishlistProvider = MockWishlistProvider();
      _stubFavorites(mockWishlistProvider, {'elec-001'});

      await pumpFavoritesTab(
        tester,
        wishlistProvider: mockWishlistProvider,
        productProvider: productProvider,
      );
      await tester.pumpAndSettle();

      expect(find.byKey(WidgetKeys.favoritesTabError), findsOneWidget);
      expect(find.byKey(WidgetKeys.favoritesTabLoading), findsNothing);
      expect(find.byKey(WidgetKeys.favoritesEmptyState), findsNothing);
      expect(find.byKey(WidgetKeys.favoritesProductList), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'resolves favorites from ProductProvider.products rather than the mock catalog when registered and loaded',
        (tester) async {
      final mockRepo = MockProductRepository();
      final providerProducts = [
        TestData.createTestProduct(
          id: 'provider-only-1',
          name: 'Provider Exclusive Product',
          category: 'electronics',
        ),
      ];
      when(() => mockRepo.fetchProducts()).thenAnswer((_) async => providerProducts);

      final productProvider = ProductProvider(mockRepo);

      final mockWishlistProvider = MockWishlistProvider();
      // 'elec-001' only exists in the mock catalog, not in providerProducts -
      // if it rendered, that would prove the mock catalog leaked through.
      _stubFavorites(mockWishlistProvider, {'provider-only-1', 'elec-001'});

      await pumpFavoritesTab(
        tester,
        wishlistProvider: mockWishlistProvider,
        productProvider: productProvider,
      );
      await tester.pumpAndSettle();

      expect(find.text('Provider Exclusive Product'), findsOneWidget);
      final mockOnlyName =
          mock_catalog.products.firstWhere((p) => p.id == 'elec-001').name;
      expect(find.text(mockOnlyName), findsNothing);
    });

    testWidgets('existing favorites-empty behavior remains correct when there are no favorites',
        (tester) async {
      final mockWishlistProvider = MockWishlistProvider();
      _stubFavorites(mockWishlistProvider, {});

      await pumpFavoritesTab(
        tester,
        wishlistProvider: mockWishlistProvider,
        productProvider: null,
      );
      await tester.pumpAndSettle();

      expect(find.byKey(WidgetKeys.favoritesEmptyState), findsOneWidget);
      expect(find.byKey(WidgetKeys.favoritesProductList), findsNothing);
      expect(find.byKey(WidgetKeys.favoritesTabLoading), findsNothing);
      expect(find.byKey(WidgetKeys.favoritesTabError), findsNothing);
    });

    testWidgets(
        'tapping a favorite item still calls onOpenProduct with the correct product',
        (tester) async {
      final mockWishlistProvider = MockWishlistProvider();
      _stubFavorites(mockWishlistProvider, {'elec-001'});

      Product? openedProduct;
      await pumpFavoritesTab(
        tester,
        wishlistProvider: mockWishlistProvider,
        productProvider: null,
        onOpenProduct: (product, context) => openedProduct = product,
      );
      await tester.pumpAndSettle();

      final expectedName =
          mock_catalog.products.firstWhere((p) => p.id == 'elec-001').name;
      await tester.tap(find.widgetWithText(ListTile, expectedName));
      await tester.pumpAndSettle();

      expect(openedProduct?.id, 'elec-001');
    });
  });
}
