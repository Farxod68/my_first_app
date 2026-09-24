import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_first_app/core/constants/widget_keys.dart';
import 'package:my_first_app/core/utils/formatters.dart';
import 'package:my_first_app/data/models/product.dart';
import 'package:my_first_app/presentation/providers/cart_provider.dart';
import 'package:my_first_app/presentation/providers/currency_provider.dart';
import 'package:my_first_app/presentation/screens/cart/cart_page.dart';
import 'package:provider/provider.dart';
import '../helpers/test_data.dart';
import '../helpers/widget_test_helpers.dart';
import '../mocks/mock_persistence_service.dart';

void main() {
  group('CartPage Widget Tests', () {
    late CartProvider cartProvider;

    setUp(() {
      final mockPersistence = MockPersistenceService();
      when(() => mockPersistence.loadCart()).thenReturn([]);
      when(() => mockPersistence.saveCart(any()))
          .thenAnswer((_) async => true);
      cartProvider = CartProvider(mockPersistence);
    });

    tearDown(() => cartProvider.dispose());

    /// Seeds [cartProvider] with [items] and pumps a [CartPage] observing it.
    Future<void> pumpCartPage(
      WidgetTester tester, [
      List<Product> items = const [],
    ]) async {
      for (final product in items) {
        cartProvider.addToCart(product);
      }
      await pumpAppWithNavigation(
        tester,
        const CartPage(),
        providers: [
          ChangeNotifierProvider<CartProvider>.value(value: cartProvider),
        ],
      );
    }

    testWidgets('1. Empty cart shows cartEmptyState and not cartProductList',
        (tester) async {
      await pumpCartPage(tester);

      expect(find.byKey(WidgetKeys.cartEmptyState), findsOneWidget);
      expect(find.byKey(WidgetKeys.cartProductList), findsNothing);
    });

    testWidgets(
        '2. Populated cart shows cartProductList and not cartEmptyState',
        (tester) async {
      final cart = TestData.createProductList(3);

      await pumpCartPage(tester, cart);

      expect(find.byKey(WidgetKeys.cartProductList), findsOneWidget);
      expect(find.byKey(WidgetKeys.cartEmptyState), findsNothing);
    });

    testWidgets('3. AppBar title shows Shopping Cart', (tester) async {
      await pumpCartPage(tester);

      expect(find.text('Shopping Cart'), findsOneWidget);
    });

    testWidgets(
        '4. Each product renders as a Card keyed by cartProductItem(id, index)',
        (tester) async {
      final cart = TestData.createProductList(3);

      await pumpCartPage(tester, cart);

      for (var i = 0; i < cart.length; i++) {
        expect(find.byKey(WidgetKeys.cartProductItem(cart[i].id, i)),
            findsOneWidget);
      }
    });

    testWidgets('5. Product name is displayed correctly', (tester) async {
      final product = TestData.createTestProduct(
        id: 'p1',
        name: 'Wireless Mouse',
      );

      await pumpCartPage(tester, [product]);

      expect(
        find.descendant(
          of: find.byKey(WidgetKeys.cartProductItem('p1', 0)),
          matching: find.text('Wireless Mouse'),
        ),
        findsOneWidget,
      );
    });

    testWidgets(
        '6. Product price is displayed correctly and formatted for en locale',
        (tester) async {
      final product = TestData.createTestProduct(id: 'p1', price: 99.99);

      await pumpCartPage(tester, [product]);

      final expectedPrice = formatPrice(99.99, 'USD', 'en');
      expect(
        find.descendant(
          of: find.byKey(WidgetKeys.cartProductItem('p1', 0)),
          matching: find.text(expectedPrice),
        ),
        findsOneWidget,
      );
    });

    testWidgets(
        '7. A single-item cart renders exactly one cartProductItem and no empty state',
        (tester) async {
      final product = TestData.createTestProduct(id: 'only_item');

      await pumpCartPage(tester, [product]);

      expect(find.byKey(WidgetKeys.cartProductItem('only_item', 0)),
          findsOneWidget);
      expect(find.byKey(WidgetKeys.cartEmptyState), findsNothing);
    });

    testWidgets(
        '8. Adding the same product twice renders one entry and no duplicate-key error',
        (tester) async {
      final product = TestData.createTestProduct(id: 'elec-001');

      await pumpCartPage(tester, [product, product]);

      // No FlutterError (e.g. duplicate GlobalKey/Key) was thrown during build/pump.
      expect(tester.takeException(), isNull);

      final firstKey = WidgetKeys.cartProductItem('elec-001', 0);
      final secondKey = WidgetKeys.cartProductItem('elec-001', 1);

      // CartProvider merges duplicates into one entry with quantity 2.
      expect(cartProvider.quantityOf('elec-001'), equals(2));
      expect(firstKey, isNot(equals(secondKey)));
      expect(find.byKey(firstKey), findsOneWidget);
      expect(find.byKey(secondKey), findsNothing);
      expect(find.byKey(WidgetKeys.cartProductList), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(firstKey),
          matching: find.byKey(WidgetKeys.cartItemQuantity('elec-001')),
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<Text>(find.byKey(WidgetKeys.cartItemQuantity('elec-001')))
            .data,
        equals('2'),
      );
    });

    group('Reacts to CartProvider changes while open', () {
      testWidgets('9. Initially shows the empty state for an empty provider',
          (tester) async {
        await pumpCartPage(tester);

        expect(cartProvider.cartItems, isEmpty);
        expect(find.byKey(WidgetKeys.cartEmptyState), findsOneWidget);
        expect(find.byKey(WidgetKeys.cartProductList), findsNothing);
      });

      testWidgets('10. addToCart then pump shows the new product row',
          (tester) async {
        await pumpCartPage(tester);
        expect(find.byKey(WidgetKeys.cartEmptyState), findsOneWidget);

        final product =
            TestData.createTestProduct(id: 'live-1', name: 'Live Item');
        cartProvider.addToCart(product);
        await tester.pump();

        expect(find.byType(CartPage), findsOneWidget);
        expect(find.byKey(WidgetKeys.cartEmptyState), findsNothing);
        expect(find.byKey(WidgetKeys.cartProductList), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(WidgetKeys.cartProductItem('live-1', 0)),
            matching: find.text('Live Item'),
          ),
          findsOneWidget,
        );
      });

      testWidgets('11. removeAt(0) then pump shows the empty state',
          (tester) async {
        final product = TestData.createTestProduct(id: 'live-2');
        await pumpCartPage(tester, [product]);
        expect(find.byKey(WidgetKeys.cartProductItem('live-2', 0)),
            findsOneWidget);

        cartProvider.removeAt(0);
        await tester.pump();

        expect(find.byType(CartPage), findsOneWidget);
        expect(find.byKey(WidgetKeys.cartProductItem('live-2', 0)),
            findsNothing);
        expect(find.byKey(WidgetKeys.cartProductList), findsNothing);
        expect(find.byKey(WidgetKeys.cartEmptyState), findsOneWidget);
      });
    });

    group('Quantity controls', () {
      String quantityText(WidgetTester tester, String productId) => tester
          .widget<Text>(find.byKey(WidgetKeys.cartItemQuantity(productId)))
          .data!;

      testWidgets('12. A newly added product displays quantity 1 in its row',
          (tester) async {
        await pumpCartPage(tester, [TestData.createTestProduct(id: 'q1')]);

        final row = find.byKey(WidgetKeys.cartProductItem('q1', 0));
        for (final key in [
          WidgetKeys.cartItemQuantity('q1'),
          WidgetKeys.cartItemDecreaseButton('q1'),
          WidgetKeys.cartItemIncreaseButton('q1'),
        ]) {
          expect(find.descendant(of: row, matching: find.byKey(key)),
              findsOneWidget);
        }
        expect(quantityText(tester, 'q1'), equals('1'));
      });

      testWidgets('13. Tapping plus changes quantity 1 -> 2', (tester) async {
        await pumpCartPage(tester, [TestData.createTestProduct(id: 'q1')]);

        await tester.tap(find.byKey(WidgetKeys.cartItemIncreaseButton('q1')));
        await tester.pump();

        expect(quantityText(tester, 'q1'), equals('2'));
        expect(cartProvider.quantityOf('q1'), equals(2));
        expect(cartProvider.cartItems.length, equals(1));
      });

      testWidgets('14. Tapping minus changes quantity 2 -> 1', (tester) async {
        final product = TestData.createTestProduct(id: 'q1');
        await pumpCartPage(tester, [product, product]);
        expect(quantityText(tester, 'q1'), equals('2'));

        await tester.tap(find.byKey(WidgetKeys.cartItemDecreaseButton('q1')));
        await tester.pump();

        expect(quantityText(tester, 'q1'), equals('1'));
        expect(cartProvider.quantityOf('q1'), equals(1));
        expect(find.byKey(WidgetKeys.cartProductItem('q1', 0)), findsOneWidget);
      });

      testWidgets('15. Tapping minus at quantity 1 removes the product',
          (tester) async {
        await pumpCartPage(tester, [TestData.createTestProduct(id: 'q1')]);

        await tester.tap(find.byKey(WidgetKeys.cartItemDecreaseButton('q1')));
        await tester.pump();

        expect(cartProvider.isInCart('q1'), isFalse);
        expect(find.byKey(WidgetKeys.cartProductItem('q1', 0)), findsNothing);
        expect(find.byKey(WidgetKeys.cartItemQuantity('q1')), findsNothing);
        expect(find.byKey(WidgetKeys.cartEmptyState), findsOneWidget);
      });

      testWidgets(
          '16. Minus removes only the tapped product; other rows keep quantities',
          (tester) async {
        final a = TestData.createTestProduct(id: 'a', name: 'Alpha');
        final b = TestData.createTestProduct(id: 'b', name: 'Beta');
        await pumpCartPage(tester, [a, b, b]);

        await tester.tap(find.byKey(WidgetKeys.cartItemDecreaseButton('a')));
        await tester.pump();

        expect(find.text('Alpha'), findsNothing);
        expect(find.byKey(WidgetKeys.cartProductItem('b', 0)), findsOneWidget);
        expect(quantityText(tester, 'b'), equals('2'));
        expect(find.byKey(WidgetKeys.cartEmptyState), findsNothing);
      });

      testWidgets('17. Adding the same product twice shows one row with quantity 2',
          (tester) async {
        final product = TestData.createTestProduct(id: 'q1', name: 'Twice');
        await pumpCartPage(tester);

        cartProvider.addToCart(product);
        cartProvider.addToCart(product);
        await tester.pump();

        expect(find.text('Twice'), findsOneWidget);
        expect(find.byKey(WidgetKeys.cartProductItem('q1', 0)), findsOneWidget);
        expect(find.byKey(WidgetKeys.cartProductItem('q1', 1)), findsNothing);
        expect(quantityText(tester, 'q1'), equals('2'));
      });

      testWidgets('18. Quantity controls keep the row name and price intact',
          (tester) async {
        final product =
            TestData.createTestProduct(id: 'q1', name: 'Mouse', price: 25.0);
        await pumpCartPage(tester, [product]);

        await tester.tap(find.byKey(WidgetKeys.cartItemIncreaseButton('q1')));
        await tester.pump();

        final row = find.byKey(WidgetKeys.cartProductItem('q1', 0));
        expect(find.descendant(of: row, matching: find.text('Mouse')),
            findsOneWidget);
        expect(
          find.descendant(
            of: row,
            matching: find.text(formatPrice(25.0, 'USD', 'en')),
          ),
          findsOneWidget,
        );
      });
    });

    group('Subtotal', () {
      String subtotalText(WidgetTester tester) => tester
          .widget<Text>(find.byKey(WidgetKeys.cartSubtotalValue))
          .data!;

      testWidgets('19. Subtotal is hidden for an empty cart', (tester) async {
        await pumpCartPage(tester);

        expect(find.byKey(WidgetKeys.cartEmptyState), findsOneWidget);
        expect(find.byKey(WidgetKeys.cartSubtotal), findsNothing);
        expect(find.byKey(WidgetKeys.cartSubtotalValue), findsNothing);
      });

      testWidgets('A. One product at quantity 1: subtotal equals its price',
          (tester) async {
        await pumpCartPage(
            tester, [TestData.createTestProduct(id: 'a', price: 49.99)]);

        expect(cartProvider.quantityOf('a'), equals(1));
        expect(subtotalText(tester), equals(formatPrice(49.99, 'USD', 'en')));
      });

      testWidgets('B. Same product at quantity 2: subtotal equals price × 2',
          (tester) async {
        final a = TestData.createTestProduct(id: 'a', price: 49.99);
        await pumpCartPage(tester, [a, a]);

        expect(cartProvider.quantityOf('a'), equals(2));
        expect(
            subtotalText(tester), equals(formatPrice(49.99 * 2, 'USD', 'en')));
      });

      testWidgets('20. Subtotal row shows the label and the summed amount',
          (tester) async {
        final a = TestData.createTestProduct(id: 'a', price: 10.0);
        final b = TestData.createTestProduct(id: 'b', price: 2.5);
        await pumpCartPage(tester, [a, a, a, b]);

        final row = find.byKey(WidgetKeys.cartSubtotal);
        expect(row, findsOneWidget);
        expect(find.descendant(of: row, matching: find.text('Subtotal')),
            findsOneWidget);
        expect(
          find.descendant(
              of: row, matching: find.byKey(WidgetKeys.cartSubtotalValue)),
          findsOneWidget,
        );
        // 10.0 × 3 + 2.5 × 1
        expect(subtotalText(tester), equals(formatPrice(32.5, 'USD', 'en')));
      });

      testWidgets('21. Subtotal matches CartProvider.subtotal', (tester) async {
        await pumpCartPage(tester, TestData.createProductList(3));

        expect(
          subtotalText(tester),
          equals(formatPrice(cartProvider.subtotal, 'USD', 'en')),
        );
      });

      testWidgets('22. Plus and minus update the subtotal immediately',
          (tester) async {
        final a = TestData.createTestProduct(id: 'a', price: 10.0);
        await pumpCartPage(tester, [a]);
        expect(subtotalText(tester), equals(formatPrice(10.0, 'USD', 'en')));

        await tester.tap(find.byKey(WidgetKeys.cartItemIncreaseButton('a')));
        await tester.pump();
        expect(subtotalText(tester), equals(formatPrice(20.0, 'USD', 'en')));

        await tester.tap(find.byKey(WidgetKeys.cartItemIncreaseButton('a')));
        await tester.pump();
        expect(subtotalText(tester), equals(formatPrice(30.0, 'USD', 'en')));

        await tester.tap(find.byKey(WidgetKeys.cartItemDecreaseButton('a')));
        await tester.pump();
        expect(subtotalText(tester), equals(formatPrice(20.0, 'USD', 'en')));
      });

      testWidgets(
          '23. Removing a product updates the subtotal; removing the last hides it',
          (tester) async {
        final a = TestData.createTestProduct(id: 'a', price: 10.0);
        final b = TestData.createTestProduct(id: 'b', price: 5.0);
        await pumpCartPage(tester, [a, b]);
        expect(subtotalText(tester), equals(formatPrice(15.0, 'USD', 'en')));

        await tester.tap(find.byKey(WidgetKeys.cartItemDecreaseButton('a')));
        await tester.pump();
        expect(subtotalText(tester), equals(formatPrice(5.0, 'USD', 'en')));

        await tester.tap(find.byKey(WidgetKeys.cartItemDecreaseButton('b')));
        await tester.pump();
        expect(find.byKey(WidgetKeys.cartSubtotal), findsNothing);
        expect(find.byKey(WidgetKeys.cartEmptyState), findsOneWidget);
      });

      testWidgets('24. Provider changes made outside the page update the subtotal',
          (tester) async {
        final a = TestData.createTestProduct(id: 'a', price: 10.0);
        await pumpCartPage(tester, [a]);

        cartProvider.addToCart(TestData.createTestProduct(id: 'b', price: 1.0));
        await tester.pump();

        expect(subtotalText(tester), equals(formatPrice(11.0, 'USD', 'en')));
      });

      testWidgets(
          '25. Subtotal follows the selected currency, including live changes',
          (tester) async {
        final currencyPersistence = MockPersistenceService();
        when(() => currencyPersistence.getString('currency_code'))
            .thenReturn('EUR');
        when(() => currencyPersistence.saveString(any(), any()))
            .thenAnswer((_) async => true);
        final currencyProvider = CurrencyProvider(currencyPersistence);
        addTearDown(currencyProvider.dispose);

        cartProvider.addToCart(TestData.createTestProduct(id: 'a', price: 10.0));
        cartProvider.addToCart(TestData.createTestProduct(id: 'a', price: 10.0));
        await pumpAppWithNavigation(
          tester,
          const CartPage(),
          providers: [
            ChangeNotifierProvider<CartProvider>.value(value: cartProvider),
            ChangeNotifierProvider<CurrencyProvider>.value(
                value: currencyProvider),
          ],
        );
        expect(currencyProvider.currentCurrency, equals('EUR'));
        expect(subtotalText(tester), equals(formatPrice(20.0, 'EUR', 'en')));

        currencyProvider.setCurrency('UZS');
        await tester.pump();

        expect(subtotalText(tester), equals(formatPrice(20.0, 'UZS', 'en')));
      });

      testWidgets('26. Subtotal label is localized', (tester) async {
        cartProvider.addToCart(TestData.createTestProduct(id: 'a', price: 10.0));
        await pumpAppWithNavigation(
          tester,
          const CartPage(),
          locale: const Locale('es'),
          providers: [
            ChangeNotifierProvider<CartProvider>.value(value: cartProvider),
          ],
        );

        expect(
          find.descendant(
            of: find.byKey(WidgetKeys.cartSubtotal),
            matching: find.text('Subtotal'),
          ),
          findsOneWidget,
        );
        expect(subtotalText(tester), equals(formatPrice(10.0, 'USD', 'es')));
      });
    });
  });
}
