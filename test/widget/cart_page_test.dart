import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/core/constants/widget_keys.dart';
import 'package:my_first_app/core/utils/formatters.dart';
import 'package:my_first_app/presentation/screens/cart/cart_page.dart';
import '../helpers/test_data.dart';
import '../helpers/widget_test_helpers.dart';

void main() {
  group('CartPage Widget Tests', () {
    testWidgets('1. Empty cart shows cartEmptyState and not cartProductList',
        (tester) async {
      await pumpAppWithNavigation(tester, const CartPage(cart: []));

      expect(find.byKey(WidgetKeys.cartEmptyState), findsOneWidget);
      expect(find.byKey(WidgetKeys.cartProductList), findsNothing);
    });

    testWidgets(
        '2. Populated cart shows cartProductList and not cartEmptyState',
        (tester) async {
      final cart = TestData.createProductList(3);

      await pumpAppWithNavigation(tester, CartPage(cart: cart));

      expect(find.byKey(WidgetKeys.cartProductList), findsOneWidget);
      expect(find.byKey(WidgetKeys.cartEmptyState), findsNothing);
    });

    testWidgets('3. AppBar title shows Shopping Cart', (tester) async {
      await pumpAppWithNavigation(tester, const CartPage(cart: []));

      expect(find.text('Shopping Cart'), findsOneWidget);
    });

    testWidgets(
        '4. Each product renders as a Card keyed by cartProductItem(id)',
        (tester) async {
      final cart = TestData.createProductList(3);

      await pumpAppWithNavigation(tester, CartPage(cart: cart));

      for (final product in cart) {
        expect(find.byKey(WidgetKeys.cartProductItem(product.id)),
            findsOneWidget);
      }
    });

    testWidgets('5. Product name is displayed correctly', (tester) async {
      final product = TestData.createTestProduct(
        id: 'p1',
        name: 'Wireless Mouse',
      );

      await pumpAppWithNavigation(tester, CartPage(cart: [product]));

      expect(
        find.descendant(
          of: find.byKey(WidgetKeys.cartProductItem('p1')),
          matching: find.text('Wireless Mouse'),
        ),
        findsOneWidget,
      );
    });

    testWidgets(
        '6. Product price is displayed correctly and formatted for en locale',
        (tester) async {
      final product = TestData.createTestProduct(id: 'p1', price: 99.99);

      await pumpAppWithNavigation(tester, CartPage(cart: [product]));

      final expectedPrice = formatPrice(99.99, 'USD', 'en');
      expect(
        find.descendant(
          of: find.byKey(WidgetKeys.cartProductItem('p1')),
          matching: find.text(expectedPrice),
        ),
        findsOneWidget,
      );
    });

    testWidgets(
        '7. A single-item cart renders exactly one cartProductItem and no empty state',
        (tester) async {
      final product = TestData.createTestProduct(id: 'only_item');

      await pumpAppWithNavigation(tester, CartPage(cart: [product]));

      expect(find.byKey(WidgetKeys.cartProductItem('only_item')),
          findsOneWidget);
      expect(find.byKey(WidgetKeys.cartEmptyState), findsNothing);
    });
  });
}
