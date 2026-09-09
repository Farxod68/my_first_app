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
import 'package:my_first_app/presentation/providers/wishlist_provider.dart';
import 'package:my_first_app/presentation/screens/home/tabs/home_tab.dart';
import 'package:my_first_app/presentation/widgets/product_card.dart';
import '../helpers/test_data.dart';
import '../mocks/mock_persistence_service.dart';
import '../mocks/mock_product_repository.dart';
import '../mocks/mock_recently_viewed_provider.dart';
import '../mocks/mock_wishlist_provider.dart';

/// Pumps [HomeTab] with its required providers.
///
/// [productProvider] is registered in the tree only when non-null, mirroring
/// main.dart's `if (supabaseInitialized)` gate - passing null reproduces the
/// "Supabase not configured" case HomeTab must fall back from gracefully.
Future<void> pumpHomeTab(
  WidgetTester tester, {
  ProductProvider? productProvider,
}) async {
  final mockPersistenceService = MockPersistenceService();
  when(() => mockPersistenceService.getString('currency_code')).thenReturn(null);

  final mockWishlistProvider = MockWishlistProvider();
  when(() => mockWishlistProvider.isFavorite(any())).thenReturn(false);

  final mockRecentlyViewedProvider = MockRecentlyViewedProvider();
  when(() => mockRecentlyViewedProvider.getRecentlyViewedProducts(any()))
      .thenReturn(const []);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<WishlistProvider>.value(value: mockWishlistProvider),
        ChangeNotifierProvider<RecentlyViewedProvider>.value(
          value: mockRecentlyViewedProvider,
        ),
        ChangeNotifierProvider<CurrencyProvider>(
          create: (_) => CurrencyProvider(mockPersistenceService),
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
          body: HomeTab(
            onAddToCart: (_, _) {},
            onOpenProduct: (_, _) {},
            onToggleFavorite: (_, _) {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('HomeTab Widget Tests (Phase 29E-1: ProductProvider migration)', () {
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

      await pumpHomeTab(tester, productProvider: productProvider);
      await tester.pump();

      expect(find.byKey(WidgetKeys.homeTabLoading), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byKey(WidgetKeys.homeTabError), findsNothing);
      expect(find.byKey(WidgetKeys.homeTabEmpty), findsNothing);
    });

    testWidgets('renders the product catalog once ProductProvider has loaded',
        (tester) async {
      final mockRepo = MockProductRepository();
      final testProducts = [
        TestData.createTestProduct(id: 'elec-001', name: 'Smart Watch Ultra'),
        TestData.createTestProduct(id: 'cloth-001', name: 'Running Shoes Pro'),
      ];
      when(() => mockRepo.fetchProducts()).thenAnswer((_) async => testProducts);

      final productProvider = ProductProvider(mockRepo);

      await pumpHomeTab(tester, productProvider: productProvider);
      await tester.pumpAndSettle();

      expect(find.byKey(WidgetKeys.homeTabLoading), findsNothing);
      expect(find.byKey(WidgetKeys.homeTabError), findsNothing);
      expect(find.byKey(WidgetKeys.homeTabEmpty), findsNothing);
      expect(find.byType(ProductCard), findsWidgets);
      expect(find.text('Smart Watch Ultra'), findsOneWidget);
    });

    testWidgets('shows the empty state when ProductProvider loads no products',
        (tester) async {
      final mockRepo = MockProductRepository();
      when(() => mockRepo.fetchProducts()).thenAnswer((_) async => const <Product>[]);

      final productProvider = ProductProvider(mockRepo);

      await pumpHomeTab(tester, productProvider: productProvider);
      await tester.pumpAndSettle();

      expect(find.byKey(WidgetKeys.homeTabEmpty), findsOneWidget);
      expect(find.byKey(WidgetKeys.homeTabLoading), findsNothing);
      expect(find.byKey(WidgetKeys.homeTabError), findsNothing);
      expect(find.byType(ProductCard), findsNothing);
    });

    testWidgets('shows the error state when ProductProvider fails to load',
        (tester) async {
      final mockRepo = MockProductRepository();
      when(() => mockRepo.fetchProducts()).thenThrow(Exception('Network error'));

      final productProvider = ProductProvider(mockRepo);

      await pumpHomeTab(tester, productProvider: productProvider);
      await tester.pumpAndSettle();

      expect(find.byKey(WidgetKeys.homeTabError), findsOneWidget);
      expect(find.byKey(WidgetKeys.homeTabLoading), findsNothing);
      expect(find.byKey(WidgetKeys.homeTabEmpty), findsNothing);
      expect(find.byType(ProductCard), findsNothing);
    });

    testWidgets(
        'falls back to the local mock catalog when ProductProvider is not registered (Supabase not configured)',
        (tester) async {
      // No ProductProvider passed - reproduces main.dart's behavior when
      // SupabaseConfig.isConfigured is false, exactly as before this
      // migration.
      await pumpHomeTab(tester, productProvider: null);
      await tester.pumpAndSettle();

      expect(find.byKey(WidgetKeys.homeTabLoading), findsNothing);
      expect(find.byKey(WidgetKeys.homeTabError), findsNothing);
      expect(find.byKey(WidgetKeys.homeTabEmpty), findsNothing);
      // The full 40-product mock catalog renders real product cards, well
      // beyond the 2-product count used in the "loaded from provider" case
      // above - confirming this is genuinely the mock catalog, not an
      // empty/error/loading fallback.
      expect(find.byType(ProductCard).evaluate().length, greaterThan(2));
      // Popular Categories section (built from the same mock-backed
      // HomeTab) is visible without scrolling, confirming the full existing
      // layout still renders.
      expect(find.byKey(WidgetKeys.popularCategoriesSection), findsOneWidget);
    });
  });
}
