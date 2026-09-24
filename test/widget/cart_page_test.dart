import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_first_app/core/constants/widget_keys.dart';
import 'package:my_first_app/core/utils/formatters.dart';
import 'package:my_first_app/data/models/product.dart';
import 'package:my_first_app/presentation/providers/cart_provider.dart';
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
        '8. A cart with the same product twice renders both entries with unique keys and no duplicate-key error',
        (tester) async {
      final product = TestData.createTestProduct(id: 'elec-001');

      await pumpCartPage(tester, [product, product]);

      // No FlutterError (e.g. duplicate GlobalKey/Key) was thrown during build/pump.
      expect(tester.takeException(), isNull);

      final firstKey = WidgetKeys.cartProductItem('elec-001', 0);
      final secondKey = WidgetKeys.cartProductItem('elec-001', 1);

      expect(firstKey, isNot(equals(secondKey)));
      expect(find.byKey(firstKey), findsOneWidget);
      expect(find.byKey(secondKey), findsOneWidget);
      expect(find.byKey(WidgetKeys.cartProductList), findsOneWidget);
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
  });
}
