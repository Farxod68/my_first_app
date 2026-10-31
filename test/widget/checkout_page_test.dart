import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_first_app/core/constants/widget_keys.dart';
import 'package:my_first_app/core/utils/formatters.dart';
import 'package:my_first_app/data/data_sources/remote/order_remote_data_source.dart';
import 'package:my_first_app/data/models/order.dart';
import 'package:my_first_app/data/models/product.dart';
import 'package:my_first_app/data/models/user_model.dart';
import 'package:my_first_app/presentation/providers/auth_provider.dart';
import 'package:my_first_app/presentation/providers/cart_provider.dart';
import 'package:my_first_app/presentation/providers/checkout_provider.dart';
import 'package:my_first_app/presentation/providers/currency_provider.dart';
import 'package:my_first_app/presentation/screens/checkout/checkout_page.dart';
import 'package:provider/provider.dart';
import '../helpers/test_data.dart';
import '../helpers/widget_test_helpers.dart';
import '../mocks/mock_auth_provider.dart';
import '../mocks/mock_order_repository.dart';
import '../mocks/mock_persistence_service.dart';

const _testShipping = ShippingDetails(
  fullName: 'John Doe',
  phone: '+1234567890',
  addressLine: '123 Main St',
  city: 'New York',
  country: 'USA',
);

const _testPlacedOrder = PlacedOrder(
  orderId: 'order-12345-abcde',
  subtotalUsd: 199.99,
);

/// Fills the shipping form with valid values unless overridden.
Future<void> _fillShipping(
  WidgetTester tester, {
  String fullName = 'John Doe',
  String phone = '+1234567890',
  String address = '123 Main St',
  String city = 'New York',
  String country = 'USA',
}) async {
  await tester.enterText(find.byKey(WidgetKeys.checkoutFullNameField), fullName);
  await tester.enterText(find.byKey(WidgetKeys.checkoutPhoneField), phone);
  await tester.enterText(find.byKey(WidgetKeys.checkoutAddressField), address);
  await tester.enterText(find.byKey(WidgetKeys.checkoutCityField), city);
  await tester.enterText(find.byKey(WidgetKeys.checkoutCountryField), country);
}

/// A real CurrencyProvider that starts in [code] (loaded from persistence).
CurrencyProvider _currencyProviderStartingIn(String code) {
  final persistence = MockPersistenceService();
  when(() => persistence.getString('currency_code')).thenReturn(code);
  return CurrencyProvider(persistence);
}

/// Every code place_order() itself raises, with the message the page shows.
const _serverRejectionMessages = <CheckoutErrorCode, String>{
  CheckoutErrorCode.notAuthenticated: 'You must be signed in to place an order.',
  CheckoutErrorCode.emptyCart: 'Your cart is empty.',
  CheckoutErrorCode.invalidQuantity: 'One or more items have an invalid quantity.',
  CheckoutErrorCode.duplicateItem: 'Duplicate items found in the order.',
  CheckoutErrorCode.invalidShipping: 'Please provide valid shipping details.',
  CheckoutErrorCode.invalidCurrency: 'The selected currency is not supported.',
  CheckoutErrorCode.productUnavailable:
      'One or more products in your cart are no longer available.',
  CheckoutErrorCode.insufficientStock: 'One or more items exceed available stock.',
};

const _unknownOutcomeMessage =
    'We could not verify if your order was completed. Please check your order '
    'history or connection before trying again.';

void main() {
  group('CheckoutPage Widget Tests', () {
    late MockPersistenceService mockPersistence;
    late CartProvider cartProvider;
    late MockOrderRepository mockOrderRepo;
    late CheckoutProvider checkoutProvider;
    late MockAuthProvider mockAuth;

    setUpAll(() {
      registerFallbackValue(_testShipping);
      registerFallbackValue(<OrderLineItem>[]);
    });

    setUp(() {
      mockPersistence = MockPersistenceService();
      when(() => mockPersistence.loadCart()).thenReturn([]);
      when(() => mockPersistence.saveCart(any())).thenAnswer((_) async => true);
      cartProvider = CartProvider(mockPersistence);

      mockOrderRepo = MockOrderRepository();
      checkoutProvider = CheckoutProvider(mockOrderRepo);

      mockAuth = MockAuthProvider();
      when(() => mockAuth.isAuthenticated).thenReturn(true);
      when(() => mockAuth.currentUser).thenReturn(null);
    });

    tearDown(() {
      cartProvider.dispose();
      checkoutProvider.dispose();
    });

    Future<void> pumpCheckoutPage(
      WidgetTester tester, {
      List<Product> cartItems = const [],
      String currencyCode = 'USD',
      CurrencyProvider? currencyProvider,
    }) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      for (final p in cartItems) {
        cartProvider.addToCart(p);
      }

      await pumpAppWithNavigation(
        tester,
        const CheckoutPage(),
        providers: [
          ChangeNotifierProvider<CartProvider>.value(value: cartProvider),
          ChangeNotifierProvider<CheckoutProvider>.value(value: checkoutProvider),
          ChangeNotifierProvider<AuthProvider?>.value(value: mockAuth),
          // Listed after the helper's default USD provider, so it wins.
          if (currencyProvider != null)
            ChangeNotifierProvider<CurrencyProvider>.value(value: currencyProvider),
        ],
      );
    }

    void stubPlaceOrderThrows(Object error) {
      when(() => mockOrderRepo.placeOrder(
            items: any(named: 'items'),
            shipping: any(named: 'shipping'),
            currencyCode: any(named: 'currencyCode'),
          )).thenThrow(error);
    }

    void stubPlaceOrderSucceeds() {
      when(() => mockOrderRepo.placeOrder(
            items: any(named: 'items'),
            shipping: any(named: 'shipping'),
            currencyCode: any(named: 'currencyCode'),
          )).thenAnswer((_) async => _testPlacedOrder);
    }

    /// placeOrder calls since the previous check: mocktail's verify() only
    /// counts invocations it has not already verified.
    int newPlaceOrderCalls() => verify(() => mockOrderRepo.placeOrder(
          items: any(named: 'items'),
          shipping: any(named: 'shipping'),
          currencyCode: any(named: 'currencyCode'),
        )).callCount;

    testWidgets('1. Empty cart shows empty cart state', (tester) async {
      await pumpCheckoutPage(tester, cartItems: []);

      expect(find.text('Your cart is empty'), findsOneWidget);
      expect(find.byKey(WidgetKeys.checkoutOrderSummary), findsNothing);
    });

    testWidgets('2. Displays AppBar title and order summary for cart items',
        (tester) async {
      final p1 = TestData.createTestProduct(id: 'p1', name: 'Smart Watch', price: 100.0);
      final p2 = TestData.createTestProduct(id: 'p2', name: 'Headphones', price: 50.0);

      await pumpCheckoutPage(tester, cartItems: [p1, p2]);

      expect(find.text('Checkout'), findsOneWidget);
      expect(find.byKey(WidgetKeys.checkoutOrderSummary), findsOneWidget);
      expect(find.text('Smart Watch × 1'), findsOneWidget);
      expect(find.text('Headphones × 1'), findsOneWidget);
      expect(
        find.byKey(WidgetKeys.checkoutSubtotalValue),
        findsOneWidget,
      );
      expect(
        tester.widget<Text>(find.byKey(WidgetKeys.checkoutSubtotalValue)).data,
        equals(formatPrice(150.0, 'USD', 'en')),
      );
    });

    testWidgets('3. Prepopulates full name and phone from AuthProvider profile',
        (tester) async {
      final testProfile = UserModel(
        id: 'user-1',
        email: 'user@example.com',
        fullName: 'Jane Smith',
        phone: '+998901234567',
        languageCode: 'en',
        currencyCode: 'USD',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      when(() => mockAuth.currentUser).thenReturn(testProfile);

      final p = TestData.createTestProduct(id: 'p1', price: 25.0);
      await pumpCheckoutPage(tester, cartItems: [p]);

      final nameField =
          tester.widget<TextFormField>(find.byKey(WidgetKeys.checkoutFullNameField));
      final phoneField =
          tester.widget<TextFormField>(find.byKey(WidgetKeys.checkoutPhoneField));

      expect(nameField.controller?.text, equals('Jane Smith'));
      expect(phoneField.controller?.text, equals('+998901234567'));
    });

    testWidgets('4. Form validation shows errors when fields are empty',
        (tester) async {
      final p = TestData.createTestProduct(id: 'p1', price: 25.0);
      await pumpCheckoutPage(tester, cartItems: [p]);

      // Tap Place Order without filling form
      await tester.tap(find.byKey(WidgetKeys.checkoutPlaceOrderButton));
      await tester.pumpAndSettle();

      expect(find.text('Full name is required'), findsOneWidget);
      expect(find.text('Phone number is required'), findsOneWidget);
      expect(find.text('Street address is required'), findsOneWidget);
      expect(find.text('City is required'), findsOneWidget);
      expect(find.text('Country is required'), findsOneWidget);

      verifyNever(() => mockOrderRepo.placeOrder(
            items: any(named: 'items'),
            shipping: any(named: 'shipping'),
            currencyCode: any(named: 'currencyCode'),
          ));
    });

    testWidgets('5. Submitting order shows loading indicator and disables button',
        (tester) async {
      final p = TestData.createTestProduct(id: 'p1', price: 50.0);
      final completer = Completer<PlacedOrder>();
      when(() => mockOrderRepo.placeOrder(
            items: any(named: 'items'),
            shipping: any(named: 'shipping'),
            currencyCode: any(named: 'currencyCode'),
          )).thenAnswer((_) => completer.future);

      await pumpCheckoutPage(tester, cartItems: [p]);

      // Fill valid shipping details
      await tester.enterText(
          find.byKey(WidgetKeys.checkoutFullNameField), 'Alice Wonder');
      await tester.enterText(
          find.byKey(WidgetKeys.checkoutPhoneField), '+1234567890');
      await tester.enterText(
          find.byKey(WidgetKeys.checkoutAddressField), '456 Elm St');
      await tester.enterText(
          find.byKey(WidgetKeys.checkoutCityField), 'Boston');
      await tester.enterText(
          find.byKey(WidgetKeys.checkoutCountryField), 'USA');

      // Tap Place Order
      await tester.tap(find.byKey(WidgetKeys.checkoutPlaceOrderButton));
      await tester.pump();

      // Loading indicator should be shown
      expect(find.byKey(WidgetKeys.checkoutLoadingIndicator), findsOneWidget);

      // Button should be disabled (onPressed == null)
      final placeOrderButton =
          tester.widget<ElevatedButton>(find.byKey(WidgetKeys.checkoutPlaceOrderButton));
      expect(placeOrderButton.onPressed, isNull);

      // Complete order
      completer.complete(_testPlacedOrder);
      await tester.pumpAndSettle();

      expect(find.byKey(WidgetKeys.checkoutConfirmationView), findsOneWidget);
    });

    testWidgets(
        '6. Success state displays confirmation view with order ID and USD total',
        (tester) async {
      final p = TestData.createTestProduct(id: 'p1', price: 199.99);
      when(() => mockOrderRepo.placeOrder(
            items: any(named: 'items'),
            shipping: any(named: 'shipping'),
            currencyCode: any(named: 'currencyCode'),
          )).thenAnswer((_) async => _testPlacedOrder);

      await pumpCheckoutPage(tester, cartItems: [p]);

      await tester.enterText(
          find.byKey(WidgetKeys.checkoutFullNameField), 'John Doe');
      await tester.enterText(
          find.byKey(WidgetKeys.checkoutPhoneField), '+1234567890');
      await tester.enterText(
          find.byKey(WidgetKeys.checkoutAddressField), '123 Main St');
      await tester.enterText(find.byKey(WidgetKeys.checkoutCityField), 'New York');
      await tester.enterText(
          find.byKey(WidgetKeys.checkoutCountryField), 'USA');

      await tester.tap(find.byKey(WidgetKeys.checkoutPlaceOrderButton));
      await tester.pumpAndSettle();

      expect(find.byKey(WidgetKeys.checkoutConfirmationView), findsOneWidget);
      expect(find.text('Order Placed Successfully!'), findsOneWidget);
      expect(find.byKey(WidgetKeys.checkoutOrderIdValue), findsOneWidget);
      expect(find.text('order-12345-abcde'), findsOneWidget);
      expect(find.byKey(WidgetKeys.checkoutUsdTotalValue), findsOneWidget);
      expect(find.text(formatPrice(199.99, 'USD', 'en')), findsOneWidget);
      expect(find.byKey(WidgetKeys.checkoutContinueShoppingButton), findsOneWidget);

      // Cart is emptied on success
      expect(cartProvider.cartItems, isEmpty);

      // Tapping Continue Shopping resets provider
      await tester.tap(find.byKey(WidgetKeys.checkoutContinueShoppingButton));
      await tester.pumpAndSettle();

      expect(checkoutProvider.status, equals(CheckoutStatus.idle));
    });

    testWidgets(
        '7. Known failure displays error message and keeps form available for retry',
        (tester) async {
      final p = TestData.createTestProduct(id: 'p1', price: 50.0);
      when(() => mockOrderRepo.placeOrder(
            items: any(named: 'items'),
            shipping: any(named: 'shipping'),
            currencyCode: any(named: 'currencyCode'),
          )).thenThrow(
        const CheckoutException(
          CheckoutErrorCode.insufficientStock,
          'INSUFFICIENT_STOCK',
        ),
      );

      await pumpCheckoutPage(tester, cartItems: [p]);

      await tester.enterText(
          find.byKey(WidgetKeys.checkoutFullNameField), 'John Doe');
      await tester.enterText(
          find.byKey(WidgetKeys.checkoutPhoneField), '+1234567890');
      await tester.enterText(
          find.byKey(WidgetKeys.checkoutAddressField), '123 Main St');
      await tester.enterText(find.byKey(WidgetKeys.checkoutCityField), 'New York');
      await tester.enterText(
          find.byKey(WidgetKeys.checkoutCountryField), 'USA');

      await tester.tap(find.byKey(WidgetKeys.checkoutPlaceOrderButton));
      await tester.pumpAndSettle();

      // Error message container should be shown
      expect(find.byKey(WidgetKeys.checkoutErrorMessage), findsOneWidget);
      expect(find.text('One or more items exceed available stock.'), findsOneWidget);

      // Cart is preserved
      expect(cartProvider.cartItems.length, equals(1));

      // Button is still clickable for retry
      final button =
          tester.widget<ElevatedButton>(find.byKey(WidgetKeys.checkoutPlaceOrderButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets(
        '8. Unknown outcome disables Place Order, shows warning, and provides reset button',
        (tester) async {
      final p = TestData.createTestProduct(id: 'p1', price: 50.0);
      when(() => mockOrderRepo.placeOrder(
            items: any(named: 'items'),
            shipping: any(named: 'shipping'),
            currencyCode: any(named: 'currencyCode'),
          )).thenThrow(
        const CheckoutException(
          CheckoutErrorCode.unknown,
          'Network timeout',
        ),
      );

      await pumpCheckoutPage(tester, cartItems: [p]);

      await tester.enterText(
          find.byKey(WidgetKeys.checkoutFullNameField), 'John Doe');
      await tester.enterText(
          find.byKey(WidgetKeys.checkoutPhoneField), '+1234567890');
      await tester.enterText(
          find.byKey(WidgetKeys.checkoutAddressField), '123 Main St');
      await tester.enterText(find.byKey(WidgetKeys.checkoutCityField), 'New York');
      await tester.enterText(
          find.byKey(WidgetKeys.checkoutCountryField), 'USA');

      await tester.tap(find.byKey(WidgetKeys.checkoutPlaceOrderButton));
      await tester.pumpAndSettle();

      // Warning container should be visible
      expect(find.byKey(WidgetKeys.checkoutUnknownOutcomeMessage), findsOneWidget);

      // Place Order button should be disabled
      final placeOrderButton =
          tester.widget<ElevatedButton>(find.byKey(WidgetKeys.checkoutPlaceOrderButton));
      expect(placeOrderButton.onPressed, isNull);

      // Reset button should be visible
      expect(find.byKey(WidgetKeys.checkoutResetButton), findsOneWidget);

      // Tap Reset button
      await tester.tap(find.byKey(WidgetKeys.checkoutResetButton));
      await tester.pumpAndSettle();

      // Provider status returns to idle, re-enabling Place Order
      expect(checkoutProvider.status, equals(CheckoutStatus.idle));
      expect(find.byKey(WidgetKeys.checkoutUnknownOutcomeMessage), findsNothing);

      final reEnabledButton =
          tester.widget<ElevatedButton>(find.byKey(WidgetKeys.checkoutPlaceOrderButton));
      expect(reEnabledButton.onPressed, isNotNull);
    });

    // ------------------------------------------------------------------
    // Server-error messages
    // ------------------------------------------------------------------

    for (final entry in _serverRejectionMessages.entries) {
      testWidgets(
          '9. ${entry.key.name}: shows its message in the error box, keeps cart and form',
          (tester) async {
        final p = TestData.createTestProduct(id: 'p1', price: 50.0);
        stubPlaceOrderThrows(CheckoutException(entry.key, entry.value));

        await pumpCheckoutPage(tester, cartItems: [p]);
        await _fillShipping(tester);
        await tester.tap(find.byKey(WidgetKeys.checkoutPlaceOrderButton));
        await tester.pumpAndSettle();

        expect(find.byKey(WidgetKeys.checkoutErrorMessage), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(WidgetKeys.checkoutErrorMessage),
            matching: find.text(entry.value),
          ),
          findsOneWidget,
        );
        // A definite rejection is not an unknown outcome.
        expect(find.byKey(WidgetKeys.checkoutUnknownOutcomeMessage), findsNothing);
        expect(find.byKey(WidgetKeys.checkoutConfirmationView), findsNothing);
        expect(cartProvider.cartItems.length, equals(1));
        expect(
          tester
              .widget<ElevatedButton>(find.byKey(WidgetKeys.checkoutPlaceOrderButton))
              .onPressed,
          isNotNull,
        );
      });
    }

    testWidgets('10. Signed-out user sees the sign-in message and no request is sent',
        (tester) async {
      when(() => mockAuth.isAuthenticated).thenReturn(false);
      final p = TestData.createTestProduct(id: 'p1', price: 50.0);

      await pumpCheckoutPage(tester, cartItems: [p]);
      await _fillShipping(tester);
      await tester.tap(find.byKey(WidgetKeys.checkoutPlaceOrderButton));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(WidgetKeys.checkoutErrorMessage),
          matching: find.text('You must be signed in to place an order.'),
        ),
        findsOneWidget,
      );
      verifyNever(() => mockOrderRepo.placeOrder(
            items: any(named: 'items'),
            shipping: any(named: 'shipping'),
            currencyCode: any(named: 'currencyCode'),
          ));
      expect(cartProvider.cartItems.length, equals(1));
    });

    testWidgets('11. Known failure then a successful retry clears the error',
        (tester) async {
      final p = TestData.createTestProduct(id: 'p1', price: 199.99);
      stubPlaceOrderThrows(const CheckoutException(
        CheckoutErrorCode.productUnavailable,
        'PRODUCT_UNAVAILABLE',
      ));

      await pumpCheckoutPage(tester, cartItems: [p]);
      await _fillShipping(tester);
      await tester.tap(find.byKey(WidgetKeys.checkoutPlaceOrderButton));
      await tester.pumpAndSettle();
      expect(find.byKey(WidgetKeys.checkoutErrorMessage), findsOneWidget);

      stubPlaceOrderSucceeds();
      await tester.tap(find.byKey(WidgetKeys.checkoutPlaceOrderButton));
      await tester.pumpAndSettle();

      expect(find.byKey(WidgetKeys.checkoutErrorMessage), findsNothing);
      expect(find.byKey(WidgetKeys.checkoutConfirmationView), findsOneWidget);
      expect(cartProvider.cartItems, isEmpty);
      expect(newPlaceOrderCalls(), equals(2));
    });

    // ------------------------------------------------------------------
    // Unknown outcome
    // ------------------------------------------------------------------

    testWidgets('12. Unknown outcome shows the verify-your-order message, not the error box',
        (tester) async {
      final p = TestData.createTestProduct(id: 'p1', price: 50.0);
      stubPlaceOrderThrows(const CheckoutException(
        CheckoutErrorCode.unknown,
        'Network timeout',
      ));

      await pumpCheckoutPage(tester, cartItems: [p]);
      await _fillShipping(tester);
      await tester.tap(find.byKey(WidgetKeys.checkoutPlaceOrderButton));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(WidgetKeys.checkoutUnknownOutcomeMessage),
          matching: find.text(_unknownOutcomeMessage),
        ),
        findsOneWidget,
      );
      expect(find.text('Try Again'), findsOneWidget);
      expect(find.byKey(WidgetKeys.checkoutErrorMessage), findsNothing);
      // The order may exist, so the cart is kept.
      expect(cartProvider.cartItems.length, equals(1));
    });

    testWidgets(
        '13. An invalid server response is treated as an unknown outcome in the UI',
        (tester) async {
      final p = TestData.createTestProduct(id: 'p1', price: 50.0);
      stubPlaceOrderThrows(const CheckoutException(
        CheckoutErrorCode.invalidResponse,
        'Unexpected place_order response',
      ));

      await pumpCheckoutPage(tester, cartItems: [p]);
      await _fillShipping(tester);
      await tester.tap(find.byKey(WidgetKeys.checkoutPlaceOrderButton));
      await tester.pumpAndSettle();

      expect(find.byKey(WidgetKeys.checkoutUnknownOutcomeMessage), findsOneWidget);
      expect(find.byKey(WidgetKeys.checkoutErrorMessage), findsNothing);
      expect(find.byKey(WidgetKeys.checkoutConfirmationView), findsNothing);
      expect(cartProvider.cartItems.length, equals(1));
      expect(
        tester
            .widget<ElevatedButton>(find.byKey(WidgetKeys.checkoutPlaceOrderButton))
            .onPressed,
        isNull,
      );
    });

    testWidgets('14. An unexpected non-CheckoutException is an unknown outcome in the UI',
        (tester) async {
      final p = TestData.createTestProduct(id: 'p1', price: 50.0);
      stubPlaceOrderThrows(StateError('boom'));

      await pumpCheckoutPage(tester, cartItems: [p]);
      await _fillShipping(tester);
      await tester.tap(find.byKey(WidgetKeys.checkoutPlaceOrderButton));
      await tester.pumpAndSettle();

      expect(find.byKey(WidgetKeys.checkoutUnknownOutcomeMessage), findsOneWidget);
      expect(find.text(_unknownOutcomeMessage), findsOneWidget);
      expect(cartProvider.cartItems.length, equals(1));
    });

    testWidgets(
        '15. After an unknown outcome Place Order sends nothing; Try Again then allows a new order',
        (tester) async {
      final p = TestData.createTestProduct(id: 'p1', price: 199.99);
      stubPlaceOrderThrows(const CheckoutException(
        CheckoutErrorCode.unknown,
        'Network timeout',
      ));

      await pumpCheckoutPage(tester, cartItems: [p]);
      await _fillShipping(tester);
      await tester.tap(find.byKey(WidgetKeys.checkoutPlaceOrderButton));
      await tester.pumpAndSettle();

      // The disabled button must not trigger another request.
      await tester.tap(
        find.byKey(WidgetKeys.checkoutPlaceOrderButton),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      expect(newPlaceOrderCalls(), equals(1));

      stubPlaceOrderSucceeds();
      await tester.tap(find.byKey(WidgetKeys.checkoutResetButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(WidgetKeys.checkoutPlaceOrderButton));
      await tester.pumpAndSettle();

      expect(find.byKey(WidgetKeys.checkoutConfirmationView), findsOneWidget);
      // Exactly one new request since the check above (2 in total).
      expect(newPlaceOrderCalls(), equals(1));
    });

    // ------------------------------------------------------------------
    // Request contents, validation and in-flight behavior
    // ------------------------------------------------------------------

    testWidgets(
        '16. Sends trimmed shipping details, the cart slugs and quantities, and the currency',
        (tester) async {
      final watch = TestData.createTestProduct(id: 'elec-001', name: 'Watch', price: 100.0);
      final jeans = TestData.createTestProduct(id: 'cloth-002', name: 'Jeans', price: 20.0);
      stubPlaceOrderSucceeds();

      await pumpCheckoutPage(tester, cartItems: [watch, jeans, jeans]);
      await _fillShipping(
        tester,
        fullName: '  Ali Valiyev ',
        phone: ' +998901234567 ',
        address: '  Amir Temur 1  ',
        city: ' Tashkent ',
        country: '  Uzbekistan ',
      );
      await tester.tap(find.byKey(WidgetKeys.checkoutPlaceOrderButton));
      await tester.pumpAndSettle();

      final captured = verify(() => mockOrderRepo.placeOrder(
            items: captureAny(named: 'items'),
            shipping: captureAny(named: 'shipping'),
            currencyCode: captureAny(named: 'currencyCode'),
          )).captured;

      final items = captured[0] as List<OrderLineItem>;
      expect(
        items.map((i) => (i.productId, i.quantity)).toList(),
        equals([('elec-001', 1), ('cloth-002', 2)]),
      );
      final shipping = captured[1] as ShippingDetails;
      expect(shipping.fullName, 'Ali Valiyev');
      expect(shipping.phone, '+998901234567');
      expect(shipping.addressLine, 'Amir Temur 1');
      expect(shipping.city, 'Tashkent');
      expect(shipping.country, 'Uzbekistan');
      expect(captured[2], 'USD');
    });

    testWidgets('17. Whitespace-only fields fail validation and send nothing',
        (tester) async {
      final p = TestData.createTestProduct(id: 'p1', price: 50.0);

      await pumpCheckoutPage(tester, cartItems: [p]);
      await _fillShipping(tester, city: '   ', country: '\t ');
      await tester.tap(find.byKey(WidgetKeys.checkoutPlaceOrderButton));
      await tester.pumpAndSettle();

      expect(find.text('City is required'), findsOneWidget);
      expect(find.text('Country is required'), findsOneWidget);
      expect(find.text('Full name is required'), findsNothing);
      verifyNever(() => mockOrderRepo.placeOrder(
            items: any(named: 'items'),
            shipping: any(named: 'shipping'),
            currencyCode: any(named: 'currencyCode'),
          ));
    });

    testWidgets('18. While submitting, the form fields are disabled and only one request is sent',
        (tester) async {
      final p = TestData.createTestProduct(id: 'p1', price: 50.0);
      final completer = Completer<PlacedOrder>();
      when(() => mockOrderRepo.placeOrder(
            items: any(named: 'items'),
            shipping: any(named: 'shipping'),
            currencyCode: any(named: 'currencyCode'),
          )).thenAnswer((_) => completer.future);

      await pumpCheckoutPage(tester, cartItems: [p]);
      await _fillShipping(tester);
      await tester.tap(find.byKey(WidgetKeys.checkoutPlaceOrderButton));
      await tester.pump();

      for (final key in [
        WidgetKeys.checkoutFullNameField,
        WidgetKeys.checkoutPhoneField,
        WidgetKeys.checkoutAddressField,
        WidgetKeys.checkoutCityField,
        WidgetKeys.checkoutCountryField,
      ]) {
        expect(tester.widget<TextFormField>(find.byKey(key)).enabled, isFalse);
      }

      // Tapping the disabled button again must not send a second request.
      await tester.tap(
        find.byKey(WidgetKeys.checkoutPlaceOrderButton),
        warnIfMissed: false,
      );
      await tester.pump();
      expect(newPlaceOrderCalls(), equals(1));

      completer.complete(_testPlacedOrder);
      await tester.pumpAndSettle();
      expect(find.byKey(WidgetKeys.checkoutConfirmationView), findsOneWidget);
    });

    // ------------------------------------------------------------------
    // Currency display
    // ------------------------------------------------------------------

    for (final code in ['EUR', 'UZS']) {
      testWidgets('19. $code: order summary shows line totals and subtotal in $code',
          (tester) async {
        final watch = TestData.createTestProduct(id: 'p1', name: 'Watch', price: 100.0);
        final jeans = TestData.createTestProduct(id: 'p2', name: 'Jeans', price: 20.0);
        final currency = _currencyProviderStartingIn(code);
        addTearDown(currency.dispose);

        await pumpCheckoutPage(
          tester,
          cartItems: [watch, watch, jeans],
          currencyProvider: currency,
        );

        expect(find.text('Watch × 2'), findsOneWidget);
        expect(find.text(formatPrice(200.0, code, 'en')), findsOneWidget);
        expect(find.text(formatPrice(20.0, code, 'en')), findsOneWidget);
        expect(
          tester.widget<Text>(find.byKey(WidgetKeys.checkoutSubtotalValue)).data,
          equals(formatPrice(220.0, code, 'en')),
        );
        // Not shown in the base currency.
        expect(find.text(formatPrice(220.0, 'USD', 'en')), findsNothing);
      });
    }

    testWidgets(
        '20. EUR: the selected currency is sent, but the confirmation total is in USD',
        (tester) async {
      final p = TestData.createTestProduct(id: 'p1', price: 199.99);
      final currency = _currencyProviderStartingIn('EUR');
      addTearDown(currency.dispose);
      stubPlaceOrderSucceeds();

      await pumpCheckoutPage(tester, cartItems: [p], currencyProvider: currency);
      await _fillShipping(tester);
      await tester.tap(find.byKey(WidgetKeys.checkoutPlaceOrderButton));
      await tester.pumpAndSettle();

      final captured = verify(() => mockOrderRepo.placeOrder(
            items: any(named: 'items'),
            shipping: any(named: 'shipping'),
            currencyCode: captureAny(named: 'currencyCode'),
          )).captured;
      expect(captured.single, 'EUR');

      expect(find.byKey(WidgetKeys.checkoutConfirmationView), findsOneWidget);
      expect(find.text('Order Confirmation'), findsOneWidget);
      expect(find.text('Total (USD)'), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(WidgetKeys.checkoutUsdTotalValue)).data,
        equals(formatPrice(_testPlacedOrder.subtotalUsd, 'USD', 'en')),
      );
      expect(
        find.text(formatPrice(_testPlacedOrder.subtotalUsd, 'EUR', 'en')),
        findsNothing,
      );
      // The shipping form is replaced by the confirmation.
      expect(find.byKey(WidgetKeys.checkoutFullNameField), findsNothing);
    });
  });
}
