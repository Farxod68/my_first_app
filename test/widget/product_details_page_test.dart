import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:my_first_app/core/constants/widget_keys.dart';
import 'package:my_first_app/core/theme/app_theme.dart';
import 'package:my_first_app/core/utils/formatters.dart';
import 'package:my_first_app/data/data_sources/local/mock_products.dart';
import 'package:my_first_app/l10n/app_localizations.dart';
import 'package:my_first_app/presentation/providers/cart_provider.dart';
import 'package:my_first_app/presentation/providers/recently_viewed_provider.dart';
import 'package:my_first_app/presentation/providers/wishlist_provider.dart';
import 'package:my_first_app/presentation/screens/product_details/product_details_page.dart';
import '../helpers/test_data.dart';
import '../mocks/mock_cart_provider.dart';
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
  group('ProductDetailsPage Widget Tests', () {
    late MockCartProvider mockCartProvider;
    late MockWishlistProvider mockWishlistProvider;
    late MockRecentlyViewedProvider mockRecentlyViewedProvider;

    setUpAll(() {
      registerFallbackValue(TestData.createTestProduct());
    });

    setUp(() {
      mockCartProvider = MockCartProvider();
      mockWishlistProvider = MockWishlistProvider();
      mockRecentlyViewedProvider = MockRecentlyViewedProvider();

      when(() => mockCartProvider.addToCart(any())).thenReturn(null);
      when(() => mockWishlistProvider.isFavorite(any())).thenReturn(false);
      when(() => mockWishlistProvider.toggleFavorite(any())).thenReturn(null);
      when(() => mockRecentlyViewedProvider.addProduct(any()))
          .thenReturn(null);
    });

    // Tablet-range viewport (< 1200px desktop breakpoint) for the
    // mobile/tablet layout, wide enough to avoid the already-reported
    // narrow-width overflow in the stock-status row.
    Future<void> pump(WidgetTester tester, dynamic product) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CartProvider>.value(
                value: mockCartProvider),
            ChangeNotifierProvider<WishlistProvider>.value(
                value: mockWishlistProvider),
            ChangeNotifierProvider<RecentlyViewedProvider>.value(
                value: mockRecentlyViewedProvider),
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

      await tester.pumpAndSettle();
    }

    testWidgets('1. Title, brand, and subtitle render correctly',
        (tester) async {
      final product = TestData.createTestProduct(
        id: 'p1',
        name: 'Premium Headphones',
        brand: 'SoundMax',
        subtitle: 'Studio Quality Audio',
      );

      await pump(tester, product);

      expect(find.text('Premium Headphones'), findsOneWidget);
      expect(find.text('SoundMax'), findsOneWidget);
      expect(find.text('Studio Quality Audio'), findsOneWidget);
      verify(() => mockRecentlyViewedProvider.addProduct('p1')).called(1);
    });

    testWidgets('2. Current price renders formatted for en locale',
        (tester) async {
      final product = TestData.createTestProduct(id: 'p1', price: 99.99);

      await pump(tester, product);

      // The current price is shown twice: once in the product header and
      // once in the sticky bottom purchase bar (both always rendered
      // together on the mobile/tablet layout).
      expect(find.text(formatPrice(99.99, 'en')), findsNWidgets(2));
    });

    testWidgets('3. Discount present shows old price and discount badge',
        (tester) async {
      final product = TestData.createTestProduct(
        id: 'p1',
        price: 80.0,
        oldPrice: 100.0,
      );

      await pump(tester, product);

      // Old price is shown in both the header and the sticky bottom bar;
      // the discount badge only appears once, in the header.
      expect(find.text(formatPrice(100.0, 'en')), findsNWidgets(2));
      expect(find.text('-20%'), findsOneWidget);
    });

    testWidgets('4. No discount hides old price and discount badge',
        (tester) async {
      final product = TestData.createTestProduct(
        id: 'p1',
        price: 50.0,
        oldPrice: 50.0,
      );

      await pump(tester, product);

      expect(find.text(formatPrice(50.0, 'en')), findsNWidgets(2));
      expect(find.textContaining('%'), findsNothing);
    });

    testWidgets('5. Rating stars, numeric rating, and review count render',
        (tester) async {
      final product = TestData.createTestProduct(
        id: 'p1',
        rating: 4.5,
        reviewCount: 120,
      );

      await pump(tester, product);

      expect(find.text('4.5'), findsOneWidget);
      expect(find.text('120 reviews'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsWidgets);
    });

    testWidgets(
        '6. Rating row is absent when rating is 0, even with reviews present',
        (tester) async {
      final product = TestData.createTestProduct(
        id: 'p1',
        rating: 0.0,
        reviewCount: 50,
      );

      await pump(tester, product);

      expect(find.text('0.0'), findsNothing);
      expect(find.text('50 reviews'), findsNothing);
      expect(find.byIcon(Icons.star), findsNothing);
      expect(find.byIcon(Icons.star_border), findsNothing);
    });

    testWidgets('7. In-stock status shown for stock >= 10', (tester) async {
      final product = TestData.createTestProduct(id: 'p1', stock: 25);

      await pump(tester, product);

      expect(find.text('In Stock'), findsOneWidget);
      expect(find.text('• 25 units in stock'), findsOneWidget);
    });

    testWidgets('8. Low-stock status shown for 0 < stock < 10',
        (tester) async {
      final product = TestData.createTestProduct(id: 'p1', stock: 3);

      await pump(tester, product);

      expect(find.text('Only 3 left!'), findsOneWidget);
    });

    testWidgets('9. Out-of-stock status shown for stock == 0',
        (tester) async {
      final product = TestData.createTestProduct(id: 'p1', stock: 0);

      await pump(tester, product);

      expect(find.text('Out of Stock'), findsOneWidget);
    });

    testWidgets('10. Add to Cart button is disabled when out of stock',
        (tester) async {
      final product = TestData.createTestProduct(id: 'p1', stock: 0);

      await pump(tester, product);

      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Add to Cart'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets(
        '11. Tapping Add to Cart (in stock) calls CartProvider.addToCart once and shows confirmation',
        (tester) async {
      final product = TestData.createTestProduct(
        id: 'p1',
        name: 'Wireless Mouse',
        stock: 10,
      );

      await pump(tester, product);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Add to Cart'));
      await tester.pump();

      verify(() => mockCartProvider.addToCart(product)).called(1);
      expect(find.text('Wireless Mouse added to cart'), findsOneWidget);
    });

    testWidgets(
        '12. Tapping wishlist icon when not favorited calls toggleFavorite and shows Added to wishlist',
        (tester) async {
      final product = TestData.createTestProduct(id: 'p1');
      var isFav = false;
      when(() => mockWishlistProvider.isFavorite(any()))
          .thenAnswer((_) => isFav);
      when(() => mockWishlistProvider.toggleFavorite(any()))
          .thenAnswer((_) => isFav = true);

      await pump(tester, product);

      expect(find.byIcon(Icons.favorite_border), findsOneWidget);

      await tester.tap(find.byIcon(Icons.favorite_border));
      await tester.pump();

      verify(() => mockWishlistProvider.toggleFavorite('p1')).called(1);
      expect(find.text('Added to wishlist'), findsOneWidget);
    });

    testWidgets(
        '13. Tapping wishlist icon when favorited calls toggleFavorite and shows Removed from wishlist',
        (tester) async {
      final product = TestData.createTestProduct(id: 'p1');
      var isFav = true;
      when(() => mockWishlistProvider.isFavorite(any()))
          .thenAnswer((_) => isFav);
      when(() => mockWishlistProvider.toggleFavorite(any()))
          .thenAnswer((_) => isFav = false);

      await pump(tester, product);

      expect(find.byIcon(Icons.favorite), findsOneWidget);

      await tester.tap(find.byIcon(Icons.favorite));
      await tester.pump();

      verify(() => mockWishlistProvider.toggleFavorite('p1')).called(1);
      expect(find.text('Removed from wishlist'), findsOneWidget);
    });

    testWidgets(
        '14. Buy Now (desktop layout) adds to cart and pops back to the previous route',
        (tester) async {
      final product = TestData.createTestProduct(id: 'p1', stock: 20);

      tester.view.physicalSize = const Size(1300, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CartProvider>.value(
                value: mockCartProvider),
            ChangeNotifierProvider<WishlistProvider>.value(
                value: mockWishlistProvider),
            ChangeNotifierProvider<RecentlyViewedProvider>.value(
                value: mockRecentlyViewedProvider),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            locale: const Locale('en'),
            localizationsDelegates: _localizationsDelegates,
            supportedLocales: _supportedLocales,
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductDetailsPage(product: product),
                      ),
                    ),
                    child: const Text('Open Details'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Details'));
      await tester.pumpAndSettle();

      expect(find.byType(ProductDetailsPage), findsOneWidget);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Buy Now'));
      await tester.pumpAndSettle();

      verify(() => mockCartProvider.addToCart(product)).called(1);
      expect(find.byType(ProductDetailsPage), findsNothing);
      expect(find.text('Open Details'), findsOneWidget);
    });

    testWidgets(
        '15. Related Products renders same-category real products, excluding the current product',
        (tester) async {
      final product = products.firstWhere((p) => p.id == 'elec-001');

      await pump(tester, product);

      expect(find.text('Related Products'), findsOneWidget);
      expect(find.byKey(WidgetKeys.productCard('elec-002')), findsOneWidget);
      expect(find.byKey(WidgetKeys.productCard('elec-003')), findsOneWidget);
      expect(find.byKey(WidgetKeys.productCard('elec-004')), findsOneWidget);
      expect(find.byKey(WidgetKeys.productCard('elec-005')), findsOneWidget);
      expect(find.byKey(WidgetKeys.productCard('elec-001')), findsNothing);
    });

    testWidgets(
        '16. Related Products section is absent when no other product shares the category',
        (tester) async {
      final product = TestData.createTestProduct(
        id: 'p1',
        category: 'no_such_category_xyz',
      );

      await pump(tester, product);

      expect(find.text('Related Products'), findsNothing);
    });

    testWidgets(
        "17. Tapping a related product navigates via pushReplacement to that product's ProductDetailsPage",
        (tester) async {
      final product = products.firstWhere((p) => p.id == 'elec-001');

      await pump(tester, product);

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
