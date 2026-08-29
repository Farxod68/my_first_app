import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/core/constants/widget_keys.dart';
import 'package:my_first_app/core/utils/formatters.dart';
import 'package:my_first_app/data/models/product.dart';
import 'package:my_first_app/presentation/screens/category/category_page.dart';
import '../helpers/test_data.dart';
import '../helpers/widget_test_helpers.dart';

void main() {
  group('CategoryPage Widget Tests', () {
    testWidgets(
        '1. Empty products list shows categoryEmptyState and not categoryProductList',
        (tester) async {
      await pumpAppWithNavigation(
        tester,
        CategoryPage(
          title: 'Electronics',
          products: const [],
          onAddToCart: (_) {},
        ),
      );

      expect(find.byKey(WidgetKeys.categoryEmptyState), findsOneWidget);
      expect(find.byKey(WidgetKeys.categoryProductList), findsNothing);
    });

    testWidgets(
        '2. Populated products list shows categoryProductList and not categoryEmptyState',
        (tester) async {
      final products = TestData.createProductList(3);

      await pumpAppWithNavigation(
        tester,
        CategoryPage(
          title: 'Electronics',
          products: products,
          onAddToCart: (_) {},
        ),
      );

      expect(find.byKey(WidgetKeys.categoryProductList), findsOneWidget);
      expect(find.byKey(WidgetKeys.categoryEmptyState), findsNothing);
    });

    testWidgets('3. AppBar title displays the exact title string passed in',
        (tester) async {
      await pumpAppWithNavigation(
        tester,
        CategoryPage(
          title: 'Home & Living',
          products: const [],
          onAddToCart: (_) {},
        ),
      );

      expect(find.text('Home & Living'), findsOneWidget);
    });

    testWidgets(
        '4. Each product renders as a Card keyed by categoryProductItem(id)',
        (tester) async {
      final products = TestData.createProductList(3);

      await pumpAppWithNavigation(
        tester,
        CategoryPage(
          title: 'Electronics',
          products: products,
          onAddToCart: (_) {},
        ),
      );

      for (final product in products) {
        expect(find.byKey(WidgetKeys.categoryProductItem(product.id)),
            findsOneWidget);
      }
    });

    testWidgets('5. Product name and formatted price are displayed correctly',
        (tester) async {
      final product = TestData.createTestProduct(
        id: 'p1',
        name: 'Bluetooth Speaker',
        price: 49.5,
      );

      await pumpAppWithNavigation(
        tester,
        CategoryPage(
          title: 'Electronics',
          products: [product],
          onAddToCart: (_) {},
        ),
      );

      final itemFinder = find.byKey(WidgetKeys.categoryProductItem('p1'));
      expect(
        find.descendant(
            of: itemFinder, matching: find.text('Bluetooth Speaker')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: itemFinder,
          matching: find.text(formatPrice(49.5, 'en')),
        ),
        findsOneWidget,
      );
    });

    testWidgets(
        '6. Tapping Add to Cart on a specific item invokes onAddToCart exactly once with that exact Product',
        (tester) async {
      final target = TestData.createTestProduct(id: 'target', name: 'Target Product');
      final other = TestData.createTestProduct(id: 'other', name: 'Other Product');

      final calls = <Product>[];

      await pumpAppWithNavigation(
        tester,
        CategoryPage(
          title: 'Electronics',
          products: [other, target],
          onAddToCart: calls.add,
        ),
      );

      final targetButton = find.descendant(
        of: find.byKey(WidgetKeys.categoryProductItem('target')),
        matching: find.byType(ElevatedButton),
      );

      await tester.tap(targetButton);
      await tester.pumpAndSettle();

      expect(calls, hasLength(1));
      expect(calls.single.id, 'target');
    });

    testWidgets(
        '7. Tapping Add to Cart on a different item invokes the callback with that different product',
        (tester) async {
      final first = TestData.createTestProduct(id: 'first', name: 'First Product');
      final second = TestData.createTestProduct(id: 'second', name: 'Second Product');

      final calls = <Product>[];

      await pumpAppWithNavigation(
        tester,
        CategoryPage(
          title: 'Electronics',
          products: [first, second],
          onAddToCart: calls.add,
        ),
      );

      final secondButton = find.descendant(
        of: find.byKey(WidgetKeys.categoryProductItem('second')),
        matching: find.byType(ElevatedButton),
      );

      await tester.tap(secondButton);
      await tester.pumpAndSettle();

      expect(calls, hasLength(1));
      expect(calls.single.id, 'second');
    });
  });
}
