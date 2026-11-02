import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_first_app/core/theme/app_theme.dart';
import 'package:my_first_app/data/models/product.dart';
import 'package:my_first_app/l10n/app_localizations.dart';
import 'package:my_first_app/presentation/providers/cart_provider.dart';
import 'package:my_first_app/presentation/providers/currency_provider.dart';
import 'package:my_first_app/presentation/providers/product_provider.dart';
import 'package:my_first_app/presentation/providers/recently_viewed_provider.dart';
import 'package:my_first_app/presentation/providers/wishlist_provider.dart';
import 'package:my_first_app/presentation/screens/cart/cart_page.dart';
import 'package:my_first_app/presentation/screens/product_details/product_details_page.dart';
import 'package:provider/provider.dart';

import '../helpers/test_data.dart';
import '../helpers/widget_test_helpers.dart';
import '../mocks/mock_cart_provider.dart';
import '../mocks/mock_persistence_service.dart';
import '../mocks/mock_product_repository.dart';
import '../mocks/mock_recently_viewed_provider.dart';
import '../mocks/mock_wishlist_provider.dart';

/// Translated product text in the UI: product details/specifications and the
/// cart (which persists the text it was added with).
void main() {
  Map<String, dynamic> row({List<dynamic>? translations}) => {
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
        'specifications': {'Display': 'AMOLED', 'Battery': '7 days'},
        'features': ['GPS navigation'],
        'badges': ['Best Seller'],
        'categories': {'key': 'electronics'},
        'product_images': const [],
        'product_translations': ?translations,
      };

  const ruTranslation = {
    'locale': 'ru',
    'name': 'Умные часы Ultra',
    'description': 'Часы премиум-класса с GPS.',
    'features': ['GPS-навигация'],
    'specifications': {'Экран': 'AMOLED', 'Батарея': '7 дней'},
  };

  group('ProductDetailsPage with translated products', () {
    late MockCartProvider cart;
    late MockWishlistProvider wishlist;
    late MockRecentlyViewedProvider recentlyViewed;

    setUpAll(() => registerFallbackValue(TestData.createTestProduct()));

    setUp(() {
      cart = MockCartProvider();
      wishlist = MockWishlistProvider();
      recentlyViewed = MockRecentlyViewedProvider();
      when(() => wishlist.isFavorite(any())).thenReturn(false);
      when(() => recentlyViewed.addProduct(any())).thenReturn(null);
    });

    Future<void> pump(WidgetTester tester, Product product) async {
      tester.view.physicalSize = const Size(800, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final persistence = MockPersistenceService();
      when(() => persistence.getString('currency_code')).thenReturn(null);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CartProvider>.value(value: cart),
            ChangeNotifierProvider<WishlistProvider>.value(value: wishlist),
            ChangeNotifierProvider<RecentlyViewedProvider>.value(
                value: recentlyViewed),
            ChangeNotifierProvider<CurrencyProvider>(
              create: (_) => CurrencyProvider(persistence),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            locale: const Locale('ru'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: ProductDetailsPage(product: product),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shows translated name, description, features and '
        'specification keys and values', (tester) async {
      await pump(tester,
          Product.fromSupabase(row(translations: [ruTranslation]), locale: 'ru'));

      expect(find.text('Умные часы Ultra'), findsWidgets);
      expect(find.text('Часы премиум-класса с GPS.'), findsOneWidget);
      expect(find.text('GPS-навигация'), findsOneWidget);
      expect(find.text('Экран'), findsOneWidget);
      expect(find.text('Батарея'), findsOneWidget);
      expect(find.text('7 дней'), findsOneWidget);
      // The English specification labels are not mixed in.
      expect(find.text('Display'), findsNothing);
      expect(find.text('Battery'), findsNothing);
      expect(find.text('Smart Watch Ultra'), findsNothing);
    });

    testWidgets('a product without a translation row shows the English text',
        (tester) async {
      await pump(tester, Product.fromSupabase(row(), locale: 'ru'));

      expect(find.text('Smart Watch Ultra'), findsWidgets);
      expect(find.text('Premium smartwatch with GPS.'), findsOneWidget);
      expect(find.text('Display'), findsOneWidget);
      expect(find.text('7 days'), findsOneWidget);
    });

    testWidgets('partially translated: translated name with English '
        'specifications', (tester) async {
      await pump(
        tester,
        Product.fromSupabase(
          row(translations: [
            {'locale': 'ru', 'name': 'Умные часы Ultra'},
          ]),
          locale: 'ru',
        ),
      );

      expect(find.text('Умные часы Ultra'), findsWidgets);
      expect(find.text('Premium smartwatch with GPS.'), findsOneWidget);
      expect(find.text('Display'), findsOneWidget);
    });
  });

  group('CartPage with translated catalog', () {
    late CartProvider cartProvider;
    late MockProductRepository repo;

    setUp(() {
      final persistence = MockPersistenceService();
      when(() => persistence.loadCart()).thenReturn([]);
      when(() => persistence.saveCart(any())).thenAnswer((_) async => true);
      cartProvider = CartProvider(persistence);
      repo = MockProductRepository();
    });

    tearDown(() => cartProvider.dispose());

    testWidgets('shows the cart item name in the current catalog language '
        'without changing the stored cart item', (tester) async {
      when(() => repo.fetchProducts(locale: any(named: 'locale'))).thenAnswer(
        (_) async => [
          Product.fromSupabase(row(translations: [ruTranslation]), locale: 'ru'),
        ],
      );
      final catalog = ProductProvider(repo, initialLocale: 'ru');
      addTearDown(catalog.dispose);
      await tester.pump();

      // Added earlier, while the app was in English.
      cartProvider.addToCart(Product.fromSupabase(row(), locale: 'en'));

      await pumpAppWithNavigation(
        tester,
        const CartPage(),
        providers: [
          ChangeNotifierProvider<CartProvider>.value(value: cartProvider),
          ChangeNotifierProvider<ProductProvider>.value(value: catalog),
        ],
      );

      expect(find.text('Умные часы Ultra'), findsOneWidget);
      expect(find.text('Smart Watch Ultra'), findsNothing);
      // Persisted cart state is untouched.
      expect(cartProvider.cartItems.single.name, 'Smart Watch Ultra');
      expect(cartProvider.cartItems.single.price, 199.99);
      expect(cartProvider.quantityOf('elec-001'), 1);
    });

    testWidgets('without a ProductProvider the stored name is shown',
        (tester) async {
      cartProvider.addToCart(Product.fromSupabase(row(), locale: 'en'));

      await pumpAppWithNavigation(
        tester,
        const CartPage(),
        providers: [
          ChangeNotifierProvider<CartProvider>.value(value: cartProvider),
        ],
      );

      expect(find.text('Smart Watch Ultra'), findsOneWidget);
    });

    testWidgets('an item missing from the catalog keeps its stored name',
        (tester) async {
      when(() => repo.fetchProducts(locale: any(named: 'locale')))
          .thenAnswer((_) async => const <Product>[]);
      final catalog = ProductProvider(repo, initialLocale: 'ru');
      addTearDown(catalog.dispose);
      await tester.pump();
      cartProvider.addToCart(Product.fromSupabase(row(), locale: 'en'));

      await pumpAppWithNavigation(
        tester,
        const CartPage(),
        providers: [
          ChangeNotifierProvider<CartProvider>.value(value: cartProvider),
          ChangeNotifierProvider<ProductProvider>.value(value: catalog),
        ],
      );

      expect(find.text('Smart Watch Ultra'), findsOneWidget);
    });
  });
}
