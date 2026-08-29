import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:my_first_app/core/constants/widget_keys.dart';
import 'package:my_first_app/core/theme/app_theme.dart';
import 'package:my_first_app/l10n/app_localizations.dart';
import 'package:my_first_app/presentation/providers/cart_provider.dart';
import 'package:my_first_app/presentation/providers/recently_viewed_provider.dart';
import 'package:my_first_app/presentation/providers/search_provider.dart';
import 'package:my_first_app/presentation/providers/wishlist_provider.dart';
import 'package:my_first_app/presentation/screens/cart/cart_page.dart';
import 'package:my_first_app/presentation/screens/category/category_page.dart';
import 'package:my_first_app/presentation/screens/home/home_page.dart';
import 'package:my_first_app/presentation/screens/product_details/product_details_page.dart';
import 'package:my_first_app/presentation/widgets/product_card.dart';
import '../helpers/test_data.dart';
import '../mocks/mock_cart_provider.dart';
import '../mocks/mock_recently_viewed_provider.dart';
import '../mocks/mock_search_provider.dart';
import '../mocks/mock_wishlist_provider.dart';

/// Pumps [HomePage] at a mobile viewport width (< 600px) so the bottom
/// [NavigationBar] layout is used instead of the wide-screen NavigationRail
/// layout, with the three providers HomePage requires during build.
Future<void> pumpHomePage(
  WidgetTester tester, {
  required MockCartProvider mockCartProvider,
  required MockWishlistProvider mockWishlistProvider,
  required MockRecentlyViewedProvider mockRecentlyViewedProvider,
  required MockSearchProvider mockSearchProvider,
}) async {
  // Width kept just under the 600px mobile breakpoint (ScreenSize.isMobile)
  // so the bottom NavigationBar layout under test still renders, but wide
  // enough to avoid pre-existing narrow-width text-overflow layout defects
  // in HomePage's "Popular Products" header and ProductDetailsPage's stock
  // row (see final report) that are unrelated to navigation behavior.
  tester.view.physicalSize = const Size(599, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CartProvider>.value(value: mockCartProvider),
        ChangeNotifierProvider<WishlistProvider>.value(
          value: mockWishlistProvider,
        ),
        ChangeNotifierProvider<RecentlyViewedProvider>.value(
          value: mockRecentlyViewedProvider,
        ),
        ChangeNotifierProvider<SearchProvider>.value(
          value: mockSearchProvider,
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
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
        home: const HomePage(),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

void main() {
  group('HomePage Widget Tests', () {
    late MockCartProvider mockCartProvider;
    late MockWishlistProvider mockWishlistProvider;
    late MockRecentlyViewedProvider mockRecentlyViewedProvider;
    late MockSearchProvider mockSearchProvider;

    setUpAll(() {
      registerFallbackValue(TestData.createTestProduct());
      registerFallbackValue(<dynamic>[]);
    });

    setUp(() {
      mockCartProvider = MockCartProvider();
      mockWishlistProvider = MockWishlistProvider();
      mockRecentlyViewedProvider = MockRecentlyViewedProvider();
      mockSearchProvider = MockSearchProvider();

      when(() => mockCartProvider.itemCount).thenReturn(0);
      when(() => mockCartProvider.cartItems).thenReturn(const []);
      when(() => mockCartProvider.addToCart(any())).thenReturn(null);

      when(() => mockWishlistProvider.isFavorite(any())).thenReturn(false);
      when(() => mockWishlistProvider.getFavoriteProducts(any()))
          .thenReturn(const []);
      when(() => mockWishlistProvider.count).thenReturn(0);
      when(() => mockWishlistProvider.toggleFavorite(any())).thenReturn(null);

      when(() => mockRecentlyViewedProvider.getRecentlyViewedProducts(any()))
          .thenReturn(const []);
      when(() => mockRecentlyViewedProvider.addProduct(any()))
          .thenReturn(null);

      when(() => mockSearchProvider.recentSearches).thenReturn(const []);
    });

    Future<void> pump(WidgetTester tester) => pumpHomePage(
          tester,
          mockCartProvider: mockCartProvider,
          mockWishlistProvider: mockWishlistProvider,
          mockRecentlyViewedProvider: mockRecentlyViewedProvider,
          mockSearchProvider: mockSearchProvider,
        );

    group('A. Bottom Navigation', () {
      testWidgets('1. Home tab is initially selected', (tester) async {
        await pump(tester);

        final navBar = tester.widget<NavigationBar>(
          find.byKey(WidgetKeys.homeBottomNavigationBar),
        );
        expect(navBar.selectedIndex, 0);
      });

      testWidgets('2. Categories tab switches correctly', (tester) async {
        await pump(tester);

        await tester.tap(find.byKey(WidgetKeys.categoriesTab));
        await tester.pumpAndSettle();

        final navBar = tester.widget<NavigationBar>(
          find.byKey(WidgetKeys.homeBottomNavigationBar),
        );
        expect(navBar.selectedIndex, 1);
        expect(find.byKey(WidgetKeys.categoriesGrid), findsOneWidget);
      });

      testWidgets('3. Favorites tab switches correctly', (tester) async {
        await pump(tester);

        await tester.tap(find.byKey(WidgetKeys.favoritesTab));
        await tester.pumpAndSettle();

        final navBar = tester.widget<NavigationBar>(
          find.byKey(WidgetKeys.homeBottomNavigationBar),
        );
        expect(navBar.selectedIndex, 2);
        expect(find.byKey(WidgetKeys.favoritesEmptyState), findsOneWidget);
      });

      testWidgets('4. Profile tab switches correctly', (tester) async {
        await pump(tester);

        await tester.tap(find.byKey(WidgetKeys.profileTab));
        await tester.pumpAndSettle();

        final navBar = tester.widget<NavigationBar>(
          find.byKey(WidgetKeys.homeBottomNavigationBar),
        );
        expect(navBar.selectedIndex, 3);
        expect(find.byKey(WidgetKeys.profileAvatar), findsOneWidget);
      });

      testWidgets('5. Home content remains available after switching tabs',
          (tester) async {
        await pump(tester);

        expect(find.byKey(WidgetKeys.categoryItem('electronics')),
            findsOneWidget);

        // Navigate away to another tab...
        await tester.tap(find.byKey(WidgetKeys.categoriesTab));
        await tester.pumpAndSettle();
        expect(find.byKey(WidgetKeys.categoryItem('electronics')),
            findsNothing);

        // ...and back to Home: its content must still be available, not lost.
        await tester.tap(find.byKey(WidgetKeys.homeTab));
        await tester.pumpAndSettle();

        final navBar = tester.widget<NavigationBar>(
          find.byKey(WidgetKeys.homeBottomNavigationBar),
        );
        expect(navBar.selectedIndex, 0);
        expect(find.byKey(WidgetKeys.categoryItem('electronics')),
            findsOneWidget);
      });

      testWidgets('6. NavigationBar can be found through WidgetKeys',
          (tester) async {
        await pump(tester);

        expect(
          find.byKey(WidgetKeys.homeBottomNavigationBar),
          findsOneWidget,
        );
      });

      testWidgets(
          '7. All four navigation destinations have their correct WidgetKeys',
          (tester) async {
        await pump(tester);

        final navBar = find.byKey(WidgetKeys.homeBottomNavigationBar);
        expect(
          find.descendant(
              of: navBar, matching: find.byKey(WidgetKeys.homeTab)),
          findsOneWidget,
        );
        expect(
          find.descendant(
              of: navBar, matching: find.byKey(WidgetKeys.categoriesTab)),
          findsOneWidget,
        );
        expect(
          find.descendant(
              of: navBar, matching: find.byKey(WidgetKeys.favoritesTab)),
          findsOneWidget,
        );
        expect(
          find.descendant(
              of: navBar, matching: find.byKey(WidgetKeys.profileTab)),
          findsOneWidget,
        );
      });
    });

    group('B. AppBar Actions', () {
      testWidgets('8. Search button opens the search flow', (tester) async {
        await pump(tester);

        await tester.tap(find.byKey(WidgetKeys.homeSearchButton));
        await tester.pumpAndSettle();

        expect(find.byKey(WidgetKeys.searchBackButton), findsOneWidget);
      });

      testWidgets('9. Cart button opens CartPage', (tester) async {
        final cartItems = TestData.createProductList(2);
        when(() => mockCartProvider.itemCount).thenReturn(2);
        when(() => mockCartProvider.cartItems).thenReturn(cartItems);

        await pump(tester);

        await tester.tap(find.byKey(WidgetKeys.homeCartButton));
        await tester.pumpAndSettle();

        expect(find.byType(CartPage), findsOneWidget);
      });

      testWidgets('10. Empty cart badge is not shown when cart is empty',
          (tester) async {
        when(() => mockCartProvider.itemCount).thenReturn(0);

        await pump(tester);

        expect(find.byKey(WidgetKeys.homeCartBadge), findsNothing);
      });

      testWidgets('11. Cart badge appears when cart contains products',
          (tester) async {
        when(() => mockCartProvider.itemCount).thenReturn(3);
        when(() => mockCartProvider.cartItems)
            .thenReturn(TestData.createProductList(3));

        await pump(tester);

        expect(find.byKey(WidgetKeys.homeCartBadge), findsOneWidget);
      });

      testWidgets('12. Cart badge displays the correct item count',
          (tester) async {
        when(() => mockCartProvider.itemCount).thenReturn(5);
        when(() => mockCartProvider.cartItems)
            .thenReturn(TestData.createProductList(5));

        await pump(tester);

        expect(
          find.descendant(
            of: find.byKey(WidgetKeys.homeCartBadge),
            matching: find.text('5'),
          ),
          findsOneWidget,
        );
      });
    });

    group('C. Category Navigation', () {
      testWidgets('13. Popular category can be tapped', (tester) async {
        await pump(tester);

        final electronicsCategory =
            find.byKey(WidgetKeys.categoryItem('electronics'));
        await tester.ensureVisible(electronicsCategory);
        await tester.pumpAndSettle();

        await tester.tap(electronicsCategory);
        await tester.pumpAndSettle();

        // No exception thrown and navigation occurred (verified in test 14).
      });

      testWidgets('14. Tapping a category opens CategoryPage',
          (tester) async {
        await pump(tester);

        final electronicsCategory =
            find.byKey(WidgetKeys.categoryItem('electronics'));
        await tester.ensureVisible(electronicsCategory);
        await tester.pumpAndSettle();

        await tester.tap(electronicsCategory);
        await tester.pumpAndSettle();

        expect(find.byType(CategoryPage), findsOneWidget);
      });

      testWidgets(
          '15. CategoryPage receives/filter-displays the correct category products',
          (tester) async {
        await pump(tester);

        final electronicsCategory =
            find.byKey(WidgetKeys.categoryItem('electronics'));
        await tester.ensureVisible(electronicsCategory);
        await tester.pumpAndSettle();

        await tester.tap(electronicsCategory);
        await tester.pumpAndSettle();

        final categoryPage =
            tester.widget<CategoryPage>(find.byType(CategoryPage));

        expect(categoryPage.title, 'Electronics');
        expect(categoryPage.products, isNotEmpty);
        expect(
          categoryPage.products.every((p) => p.category == 'electronics'),
          isTrue,
        );
        expect(
          categoryPage.products.any((p) => p.id == 'cloth-001'),
          isFalse,
        );
      });
    });

    group('D. Product Navigation', () {
      // Scoped to the "Flash Deals" horizontal section rather than the
      // bottom "Popular Products" grid: the same product can legitimately
      // appear in both a deal carousel and the main grid, which makes
      // WidgetKeys.productCard(id) ambiguous once both are built. Scoping
      // to one section's list guarantees a single match regardless of what
      // else is on the page. See the defect noted in the final report for
      // why the main grid section is avoided here.
      Finder flashDealsCards() => find.descendant(
            of: find.byKey(WidgetKeys.horizontalProductSectionList('flash_deals')),
            matching: find.byType(ProductCard),
          );

      // Scrolls the Home tab's list from a fixed on-screen point (rather than
      // anchoring to a Finder, which may itself scroll out of the tree)
      // until at least one Flash Deals product card is built.
      Future<void> scrollToFlashDeals(WidgetTester tester) async {
        for (var i = 0; i < 10 && flashDealsCards().evaluate().isEmpty; i++) {
          await tester.dragFrom(const Offset(200, 400), const Offset(0, -200));
          await tester.pump();
        }
        await tester.pumpAndSettle();
        expect(flashDealsCards(), findsWidgets);

        // Nudge the found card fully into the viewport (the crude fixed-step
        // scroll above may leave it only partially visible).
        await tester.ensureVisible(flashDealsCards().first);
        await tester.pumpAndSettle();
      }

      testWidgets('16. Product card can be tapped from HomePage',
          (tester) async {
        await pump(tester);

        await scrollToFlashDeals(tester);

        await tester.tap(flashDealsCards().first);
        await tester.pumpAndSettle();

        // No exception thrown and navigation occurred (verified in test 17).
      });

      testWidgets('17. Tapping a product opens ProductDetailsPage',
          (tester) async {
        await pump(tester);

        await scrollToFlashDeals(tester);

        final tappedProduct =
            tester.widget<ProductCard>(flashDealsCards().first).product;

        await tester.tap(flashDealsCards().first);
        await tester.pumpAndSettle();

        expect(find.byType(ProductDetailsPage), findsOneWidget);
        final detailsPage =
            tester.widget<ProductDetailsPage>(find.byType(ProductDetailsPage));
        expect(detailsPage.product.id, tappedProduct.id);
      });
    });
  });
}
