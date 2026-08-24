import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_first_app/core/constants/widget_keys.dart';
import 'package:my_first_app/presentation/providers/cart_provider.dart';
import 'package:my_first_app/presentation/providers/recently_viewed_provider.dart';
import 'package:my_first_app/presentation/providers/wishlist_provider.dart';
import 'package:my_first_app/presentation/screens/product_details/product_details_page.dart';
import 'package:my_first_app/presentation/widgets/home_sections.dart';
import 'package:provider/provider.dart';
import '../helpers/test_data.dart';
import '../helpers/widget_test_helpers.dart';
import '../mocks/mock_cart_provider.dart';
import '../mocks/mock_recently_viewed_provider.dart';
import '../mocks/mock_wishlist_provider.dart';

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

class FakeRoute extends Fake implements Route<dynamic> {}

void main() {
  group('HorizontalProductSection Widget Tests', () {
    late MockWishlistProvider mockWishlistProvider;
    late MockCartProvider mockCartProvider;
    late MockRecentlyViewedProvider mockRecentlyViewedProvider;

    setUp(() {
      mockWishlistProvider = MockWishlistProvider();
      mockCartProvider = MockCartProvider();
      mockRecentlyViewedProvider = MockRecentlyViewedProvider();
      // Register fallback values for mocktail
      registerFallbackValue(const RouteSettings());
      registerFallbackValue(TestData.createTestProduct());
      registerFallbackValue(FakeRoute());
      // Setup default behaviors for providers used by ProductDetailsPage
      when(() => mockCartProvider.addToCart(any())).thenReturn(null);
      when(() => mockRecentlyViewedProvider.addProduct(any())).thenReturn(null);
    });

    testWidgets('returns SizedBox.shrink when products list is empty', (tester) async {
      when(() => mockWishlistProvider.isFavorite(any())).thenReturn(false);

      await pumpAppWithProviders(
        tester,
        const HorizontalProductSection(
          sectionId: 'test_section',
          title: 'Test Section',
          products: [],
          locale: 'en',
        ),
        providers: [
          ChangeNotifierProvider<WishlistProvider>.value(
            value: mockWishlistProvider,
          ),
        ],
      );

      // Widget should not be visible
      expect(find.byType(SizedBox), findsWidgets);
      expect(find.text('Test Section'), findsNothing);
      expect(find.byKey(WidgetKeys.horizontalProductSection('test_section')), findsNothing);
    });

    testWidgets('renders section with correct wrapper key', (tester) async {
      final products = TestData.createProductList(3);
      when(() => mockWishlistProvider.isFavorite(any())).thenReturn(false);

      await pumpAppWithProviders(
        tester,
        HorizontalProductSection(
          sectionId: 'featured',
          title: 'Featured Products',
          products: products,
          locale: 'en',
        ),
        providers: [
          ChangeNotifierProvider<WishlistProvider>.value(
            value: mockWishlistProvider,
          ),
        ],
      );

      expect(find.byKey(WidgetKeys.horizontalProductSection('featured')), findsOneWidget);
    });

    testWidgets('renders section title', (tester) async {
      final products = TestData.createProductList(2);
      when(() => mockWishlistProvider.isFavorite(any())).thenReturn(false);

      await pumpAppWithProviders(
        tester,
        HorizontalProductSection(
          sectionId: 'test_section',
          title: 'Amazing Deals',
          products: products,
          locale: 'en',
        ),
        providers: [
          ChangeNotifierProvider<WishlistProvider>.value(
            value: mockWishlistProvider,
          ),
        ],
      );

      expect(find.text('Amazing Deals'), findsOneWidget);
    });

    testWidgets('renders subtitle when provided', (tester) async {
      final products = TestData.createProductList(2);
      when(() => mockWishlistProvider.isFavorite(any())).thenReturn(false);

      await pumpAppWithProviders(
        tester,
        HorizontalProductSection(
          sectionId: 'test_section',
          title: 'Amazing Deals',
          subtitle: 'Limited time offers',
          products: products,
          locale: 'en',
        ),
        providers: [
          ChangeNotifierProvider<WishlistProvider>.value(
            value: mockWishlistProvider,
          ),
        ],
      );

      expect(find.text('Amazing Deals'), findsOneWidget);
      expect(find.text('Limited time offers'), findsOneWidget);
    });

    testWidgets('does not render subtitle when null', (tester) async {
      final products = TestData.createProductList(2);
      when(() => mockWishlistProvider.isFavorite(any())).thenReturn(false);

      await pumpAppWithProviders(
        tester,
        HorizontalProductSection(
          sectionId: 'test_section',
          title: 'Amazing Deals',
          subtitle: null,
          products: products,
          locale: 'en',
        ),
        providers: [
          ChangeNotifierProvider<WishlistProvider>.value(
            value: mockWishlistProvider,
          ),
        ],
      );

      expect(find.text('Amazing Deals'), findsOneWidget);
      // Subtitle should not be present - verify by checking there's no second text widget
      // in the title area (only title, no subtitle)
      final titleArea = find.descendant(
        of: find.byKey(WidgetKeys.horizontalProductSection('test_section')),
        matching: find.byType(Row).first,
      );
      expect(titleArea, findsOneWidget);
    });

    testWidgets('renders View All button when onViewAll is provided', (tester) async {
      final products = TestData.createProductList(2);
      when(() => mockWishlistProvider.isFavorite(any())).thenReturn(false);

      await pumpAppWithProviders(
        tester,
        HorizontalProductSection(
          sectionId: 'test_section',
          title: 'Amazing Deals',
          products: products,
          locale: 'en',
          onViewAll: () {},
        ),
        providers: [
          ChangeNotifierProvider<WishlistProvider>.value(
            value: mockWishlistProvider,
          ),
        ],
      );

      expect(find.byKey(WidgetKeys.horizontalProductSectionViewAll('test_section')), findsOneWidget);
      expect(find.text('View All'), findsOneWidget);
    });

    testWidgets('does not render View All button when onViewAll is null', (tester) async {
      final products = TestData.createProductList(2);
      when(() => mockWishlistProvider.isFavorite(any())).thenReturn(false);

      await pumpAppWithProviders(
        tester,
        HorizontalProductSection(
          sectionId: 'test_section',
          title: 'Amazing Deals',
          products: products,
          locale: 'en',
          onViewAll: null,
        ),
        providers: [
          ChangeNotifierProvider<WishlistProvider>.value(
            value: mockWishlistProvider,
          ),
        ],
      );

      expect(find.byKey(WidgetKeys.horizontalProductSectionViewAll('test_section')), findsNothing);
      expect(find.text('View All'), findsNothing);
    });

    testWidgets('View All button triggers callback when tapped', (tester) async {
      final products = TestData.createProductList(2);
      var viewAllTapped = false;
      when(() => mockWishlistProvider.isFavorite(any())).thenReturn(false);

      await pumpAppWithProviders(
        tester,
        HorizontalProductSection(
          sectionId: 'test_section',
          title: 'Amazing Deals',
          products: products,
          locale: 'en',
          onViewAll: () => viewAllTapped = true,
        ),
        providers: [
          ChangeNotifierProvider<WishlistProvider>.value(
            value: mockWishlistProvider,
          ),
        ],
      );

      await tester.tap(find.byKey(WidgetKeys.horizontalProductSectionViewAll('test_section')));
      await tester.pumpAndSettle();

      expect(viewAllTapped, isTrue);
    });

    testWidgets('renders horizontal ListView with correct key', (tester) async {
      final products = TestData.createProductList(3);
      when(() => mockWishlistProvider.isFavorite(any())).thenReturn(false);

      await pumpAppWithProviders(
        tester,
        HorizontalProductSection(
          sectionId: 'test_section',
          title: 'Amazing Deals',
          products: products,
          locale: 'en',
        ),
        providers: [
          ChangeNotifierProvider<WishlistProvider>.value(
            value: mockWishlistProvider,
          ),
        ],
      );

      expect(find.byKey(WidgetKeys.horizontalProductSectionList('test_section')), findsOneWidget);

      final listView = tester.widget<ListView>(
        find.byKey(WidgetKeys.horizontalProductSectionList('test_section')),
      );
      expect(listView.scrollDirection, equals(Axis.horizontal));
    });

    testWidgets('renders correct number of ProductCards', (tester) async {
      final products = TestData.createProductList(3);
      when(() => mockWishlistProvider.isFavorite(any())).thenReturn(false);

      await pumpAppWithProviders(
        tester,
        HorizontalProductSection(
          sectionId: 'test_section',
          title: 'Amazing Deals',
          products: products,
          locale: 'en',
        ),
        providers: [
          ChangeNotifierProvider<WishlistProvider>.value(
            value: mockWishlistProvider,
          ),
        ],
      );

      // Verify product cards are rendered with correct keys
      expect(find.byKey(WidgetKeys.productCard('test_product_1')), findsOneWidget);
      expect(find.byKey(WidgetKeys.productCard('test_product_2')), findsOneWidget);
      expect(find.byKey(WidgetKeys.productCard('test_product_3')), findsOneWidget);
    });

    testWidgets('favorite product renders with favorite state from WishlistProvider', (tester) async {
      final products = TestData.createProductList(3);
      // First product is favorite, others are not
      when(() => mockWishlistProvider.isFavorite('test_product_1')).thenReturn(true);
      when(() => mockWishlistProvider.isFavorite('test_product_2')).thenReturn(false);
      when(() => mockWishlistProvider.isFavorite('test_product_3')).thenReturn(false);

      await pumpAppWithProviders(
        tester,
        HorizontalProductSection(
          sectionId: 'test_section',
          title: 'Amazing Deals',
          products: products,
          locale: 'en',
        ),
        providers: [
          ChangeNotifierProvider<WishlistProvider>.value(
            value: mockWishlistProvider,
          ),
        ],
      );

      // Verify provider was queried for each product
      verify(() => mockWishlistProvider.isFavorite('test_product_1')).called(1);
      verify(() => mockWishlistProvider.isFavorite('test_product_2')).called(1);
      verify(() => mockWishlistProvider.isFavorite('test_product_3')).called(1);

      // Check first product has filled favorite icon
      final firstFavoriteButton = tester.widget<IconButton>(
        find.byKey(WidgetKeys.productCardFavoriteButton('test_product_1')),
      );
      final firstIcon = firstFavoriteButton.icon as Icon;
      expect(firstIcon.icon, equals(Icons.favorite));

      // Check second product has outlined favorite icon
      final secondFavoriteButton = tester.widget<IconButton>(
        find.byKey(WidgetKeys.productCardFavoriteButton('test_product_2')),
      );
      final secondIcon = secondFavoriteButton.icon as Icon;
      expect(secondIcon.icon, equals(Icons.favorite_border));
    });

    testWidgets('tapping favorite button calls toggleFavorite with correct product ID', (tester) async {
      final products = TestData.createProductList(2);
      when(() => mockWishlistProvider.isFavorite(any())).thenReturn(false);
      when(() => mockWishlistProvider.toggleFavorite(any())).thenReturn(null);

      await pumpAppWithProviders(
        tester,
        HorizontalProductSection(
          sectionId: 'test_section',
          title: 'Amazing Deals',
          products: products,
          locale: 'en',
        ),
        providers: [
          ChangeNotifierProvider<WishlistProvider>.value(
            value: mockWishlistProvider,
          ),
        ],
      );

      // Tap favorite button on first product
      await tester.tap(find.byKey(WidgetKeys.productCardFavoriteButton('test_product_1')));
      await tester.pumpAndSettle();

      verify(() => mockWishlistProvider.toggleFavorite('test_product_1')).called(1);
      verifyNever(() => mockWishlistProvider.toggleFavorite('test_product_2'));
    });

    testWidgets('tapping ProductCard navigates to ProductDetailsPage with correct product', (tester) async {
      final products = TestData.createProductList(3);
      final mockObserver = MockNavigatorObserver();
      when(() => mockWishlistProvider.isFavorite(any())).thenReturn(false);

      await pumpAppWithProviders(
        tester,
        HorizontalProductSection(
          sectionId: 'test_section',
          title: 'Amazing Deals',
          products: products,
          locale: 'en',
        ),
        providers: [
          ChangeNotifierProvider<WishlistProvider>.value(
            value: mockWishlistProvider,
          ),
          ChangeNotifierProvider<CartProvider>.value(
            value: mockCartProvider,
          ),
          ChangeNotifierProvider<RecentlyViewedProvider>.value(
            value: mockRecentlyViewedProvider,
          ),
        ],
        navigatorObserver: mockObserver,
      );

      // Tap on second product card
      await tester.tap(find.byKey(WidgetKeys.productCard('test_product_2')));
      await tester.pumpAndSettle();

      // Verify ProductDetailsPage is on screen with correct product
      expect(find.byType(ProductDetailsPage), findsOneWidget);

      // Verify the correct product was passed
      final productDetailsPage = tester.widget<ProductDetailsPage>(
        find.byType(ProductDetailsPage),
      );
      expect(productDetailsPage.product.id, equals('test_product_2'));
      expect(productDetailsPage.product.name, equals('Test Product 2'));
    });

    testWidgets('multiple products can be navigated independently', (tester) async {
      final products = TestData.createProductList(3);
      final mockObserver = MockNavigatorObserver();
      when(() => mockWishlistProvider.isFavorite(any())).thenReturn(false);

      await pumpAppWithProviders(
        tester,
        HorizontalProductSection(
          sectionId: 'test_section',
          title: 'Amazing Deals',
          products: products,
          locale: 'en',
        ),
        providers: [
          ChangeNotifierProvider<WishlistProvider>.value(
            value: mockWishlistProvider,
          ),
          ChangeNotifierProvider<CartProvider>.value(
            value: mockCartProvider,
          ),
          ChangeNotifierProvider<RecentlyViewedProvider>.value(
            value: mockRecentlyViewedProvider,
          ),
        ],
        navigatorObserver: mockObserver,
      );

      // Tap first product
      await tester.tap(find.byKey(WidgetKeys.productCard('test_product_1')));
      await tester.pumpAndSettle();

      var productDetailsPage = tester.widget<ProductDetailsPage>(
        find.byType(ProductDetailsPage),
      );
      expect(productDetailsPage.product.id, equals('test_product_1'));

      // Go back
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Tap third product
      await tester.tap(find.byKey(WidgetKeys.productCard('test_product_3')));
      await tester.pumpAndSettle();

      productDetailsPage = tester.widget<ProductDetailsPage>(
        find.byType(ProductDetailsPage),
      );
      expect(productDetailsPage.product.id, equals('test_product_3'));
    });
  });
}
