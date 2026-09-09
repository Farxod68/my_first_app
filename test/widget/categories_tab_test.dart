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
import 'package:my_first_app/presentation/screens/category/category_page.dart';
import 'package:my_first_app/presentation/screens/home/tabs/categories_tab.dart';
import '../helpers/test_data.dart';
import '../mocks/mock_persistence_service.dart';
import '../mocks/mock_product_repository.dart';

/// Pumps [CategoriesTab] with its required providers.
///
/// [productProvider] is registered in the tree only when non-null, mirroring
/// main.dart's `if (supabaseInitialized)` gate - passing null reproduces the
/// "Supabase not configured" case CategoriesTab must fall back from
/// gracefully.
Future<void> pumpCategoriesTab(
  WidgetTester tester, {
  ProductProvider? productProvider,
  void Function(Product product, BuildContext context)? onAddToCart,
}) async {
  final mockPersistenceService = MockPersistenceService();
  when(() => mockPersistenceService.getString('currency_code')).thenReturn(null);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
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
          body: CategoriesTab(
            onAddToCart: onAddToCart ?? (_, _) {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('CategoriesTab Widget Tests (Phase 29E-2: ProductProvider migration)', () {
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

      await pumpCategoriesTab(tester, productProvider: productProvider);
      await tester.pump();

      expect(find.byKey(WidgetKeys.categoriesTabLoading), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byKey(WidgetKeys.categoriesTabError), findsNothing);
      expect(find.byKey(WidgetKeys.categoriesTabEmpty), findsNothing);
      expect(find.byKey(WidgetKeys.categoriesGrid), findsNothing);
    });

    testWidgets(
        'renders the six categories once ProductProvider has loaded products',
        (tester) async {
      final mockRepo = MockProductRepository();
      final testProducts = [
        TestData.createTestProduct(id: 'elec-001', category: 'electronics'),
        TestData.createTestProduct(id: 'cloth-001', category: 'clothing'),
      ];
      when(() => mockRepo.fetchProducts()).thenAnswer((_) async => testProducts);

      final productProvider = ProductProvider(mockRepo);

      await pumpCategoriesTab(tester, productProvider: productProvider);
      await tester.pumpAndSettle();

      expect(find.byKey(WidgetKeys.categoriesTabLoading), findsNothing);
      expect(find.byKey(WidgetKeys.categoriesTabError), findsNothing);
      expect(find.byKey(WidgetKeys.categoriesTabEmpty), findsNothing);
      expect(find.byKey(WidgetKeys.categoriesGrid), findsOneWidget);
      expect(find.text('Electronics'), findsOneWidget);
      expect(find.text('Clothing'), findsOneWidget);
      expect(find.text('Accessories'), findsOneWidget);
      expect(find.text('Home & Living'), findsOneWidget);
      expect(find.text('Sports & Outdoors'), findsOneWidget);
      expect(find.text('Beauty & Personal Care'), findsOneWidget);
    });

    testWidgets('shows the empty state when ProductProvider loads no products',
        (tester) async {
      final mockRepo = MockProductRepository();
      when(() => mockRepo.fetchProducts()).thenAnswer((_) async => const <Product>[]);

      final productProvider = ProductProvider(mockRepo);

      await pumpCategoriesTab(tester, productProvider: productProvider);
      await tester.pumpAndSettle();

      expect(find.byKey(WidgetKeys.categoriesTabEmpty), findsOneWidget);
      expect(find.byKey(WidgetKeys.categoriesTabLoading), findsNothing);
      expect(find.byKey(WidgetKeys.categoriesTabError), findsNothing);
      expect(find.byKey(WidgetKeys.categoriesGrid), findsNothing);
    });

    testWidgets('shows the error state when ProductProvider fails to load',
        (tester) async {
      final mockRepo = MockProductRepository();
      when(() => mockRepo.fetchProducts()).thenThrow(Exception('Network error'));

      final productProvider = ProductProvider(mockRepo);

      await pumpCategoriesTab(tester, productProvider: productProvider);
      await tester.pumpAndSettle();

      expect(find.byKey(WidgetKeys.categoriesTabError), findsOneWidget);
      expect(find.byKey(WidgetKeys.categoriesTabLoading), findsNothing);
      expect(find.byKey(WidgetKeys.categoriesTabEmpty), findsNothing);
      expect(find.byKey(WidgetKeys.categoriesGrid), findsNothing);
    });

    testWidgets(
        'falls back to the local mock catalog when ProductProvider is not registered (Supabase not configured)',
        (tester) async {
      // No ProductProvider passed - reproduces main.dart's behavior when
      // SupabaseConfig.isConfigured is false, exactly as before this
      // migration.
      await pumpCategoriesTab(tester, productProvider: null);
      await tester.pumpAndSettle();

      expect(find.byKey(WidgetKeys.categoriesTabLoading), findsNothing);
      expect(find.byKey(WidgetKeys.categoriesTabError), findsNothing);
      expect(find.byKey(WidgetKeys.categoriesTabEmpty), findsNothing);
      expect(find.byKey(WidgetKeys.categoriesGrid), findsOneWidget);
      expect(find.text('Electronics'), findsOneWidget);
    });

    testWidgets(
        'tapping a category filters ProductProvider-supplied products and opens CategoryPage',
        (tester) async {
      final mockRepo = MockProductRepository();
      final testProducts = [
        TestData.createTestProduct(id: 'elec-001', name: 'Provider Watch', category: 'electronics'),
        TestData.createTestProduct(id: 'elec-002', name: 'Provider Earbuds', category: 'electronics'),
        TestData.createTestProduct(id: 'cloth-001', name: 'Provider Shoes', category: 'clothing'),
      ];
      when(() => mockRepo.fetchProducts()).thenAnswer((_) async => testProducts);

      final productProvider = ProductProvider(mockRepo);

      await pumpCategoriesTab(tester, productProvider: productProvider);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Electronics'));
      await tester.pumpAndSettle();

      expect(find.byType(CategoryPage), findsOneWidget);

      final categoryPage = tester.widget<CategoryPage>(find.byType(CategoryPage));
      expect(categoryPage.title, 'Electronics');
      expect(categoryPage.products.length, 2);
      expect(
        categoryPage.products.every((p) => p.category == 'electronics'),
        isTrue,
      );
      expect(
        categoryPage.products.map((p) => p.id),
        containsAll(['elec-001', 'elec-002']),
      );
    });
  });
}
