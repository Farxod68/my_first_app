import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_first_app/data/data_sources/remote/order_remote_data_source.dart';
import 'package:my_first_app/data/models/order.dart';
import 'package:my_first_app/data/models/product.dart';
import 'package:my_first_app/presentation/providers/cart_provider.dart';
import 'package:my_first_app/presentation/providers/checkout_provider.dart';
import '../../../helpers/test_data.dart';
import '../../../mocks/mock_auth_provider.dart';
import '../../../mocks/mock_cart_provider.dart';
import '../../../mocks/mock_order_repository.dart';
import '../../../mocks/mock_persistence_service.dart';

const _shipping = ShippingDetails(
  fullName: 'Ali Valiyev',
  phone: '+998901234567',
  addressLine: 'Amir Temur 1',
  city: 'Tashkent',
  country: 'Uzbekistan',
);

const _placedOrder = PlacedOrder(
  orderId: '6f1c2e2a-3b4d-4e5f-8a9b-0c1d2e3f4a5b',
  subtotalUsd: 422.48,
);

/// Every code place_order() itself raises - the server rolled back, so the
/// order was definitely not created.
const _backendRejections = [
  CheckoutErrorCode.notAuthenticated,
  CheckoutErrorCode.emptyCart,
  CheckoutErrorCode.invalidQuantity,
  CheckoutErrorCode.duplicateItem,
  CheckoutErrorCode.invalidShipping,
  CheckoutErrorCode.invalidCurrency,
  CheckoutErrorCode.productUnavailable,
  CheckoutErrorCode.insufficientStock,
];

void main() {
  group('CheckoutProvider', () {
    late MockOrderRepository mockRepository;
    late MockCartProvider mockCart;
    late MockAuthProvider mockAuth;
    late CheckoutProvider provider;

    final watch = TestData.createTestProduct(id: 'elec-001', name: 'Smart Watch', price: 199.99);
    final jeans = TestData.createTestProduct(id: 'cloth-002', name: 'Denim Jeans', price: 22.50);

    setUpAll(() {
      registerFallbackValue(_shipping);
      registerFallbackValue(<OrderLineItem>[]);
    });

    /// Stubs [mockCart] as holding [products] with the given quantities.
    void stubCart(Map<Product, int> contents) {
      when(() => mockCart.cartItems).thenReturn(contents.keys.toList());
      when(() => mockCart.quantityOf(any())).thenAnswer((invocation) {
        final id = invocation.positionalArguments.single as String;
        return contents.entries
            .firstWhere((entry) => entry.key.id == id, orElse: () => MapEntry(watch, 0))
            .value;
      });
    }

    void stubPlaceOrder(Future<PlacedOrder> Function() answer) {
      when(() => mockRepository.placeOrder(
            items: any(named: 'items'),
            shipping: any(named: 'shipping'),
            currencyCode: any(named: 'currencyCode'),
          )).thenAnswer((_) => answer());
    }

    void stubPlaceOrderThrows(Object error) {
      when(() => mockRepository.placeOrder(
            items: any(named: 'items'),
            shipping: any(named: 'shipping'),
            currencyCode: any(named: 'currencyCode'),
          )).thenThrow(error);
    }

    VerificationResult verifyPlaceOrder() {
      return verify(() => mockRepository.placeOrder(
            items: any(named: 'items'),
            shipping: any(named: 'shipping'),
            currencyCode: any(named: 'currencyCode'),
          ));
    }

    void verifyNoPlaceOrder() {
      verifyNever(() => mockRepository.placeOrder(
            items: any(named: 'items'),
            shipping: any(named: 'shipping'),
            currencyCode: any(named: 'currencyCode'),
          ));
    }

    Future<bool> submit({String currencyCode = 'USD', bool signedIn = true, bool authRegistered = true}) {
      when(() => mockAuth.isAuthenticated).thenReturn(signedIn);
      return provider.submitOrder(
        cart: mockCart,
        auth: authRegistered ? mockAuth : null,
        shipping: _shipping,
        currencyCode: currencyCode,
      );
    }

    /// Records every status the provider notifies with.
    List<CheckoutStatus> recordStatuses() {
      final statuses = <CheckoutStatus>[];
      provider.addListener(() => statuses.add(provider.status));
      return statuses;
    }

    setUp(() {
      mockRepository = MockOrderRepository();
      mockCart = MockCartProvider();
      mockAuth = MockAuthProvider();
      when(() => mockCart.clearCart()).thenReturn(null);
      stubCart({watch: 2, jeans: 1});
      provider = CheckoutProvider(mockRepository);
    });

    group('Initial state', () {
      test('starts idle with no order or error', () {
        expect(provider.status, CheckoutStatus.idle);
        expect(provider.isSubmitting, isFalse);
        expect(provider.placedOrder, isNull);
        expect(provider.errorCode, isNull);
      });
    });

    group('Successful submission', () {
      test('passes exact slugs, quantities, shipping and currency to the repository', () async {
        stubPlaceOrder(() async => _placedOrder);

        await submit(currencyCode: 'UZS');

        final captured = verify(() => mockRepository.placeOrder(
              items: captureAny(named: 'items'),
              shipping: captureAny(named: 'shipping'),
              currencyCode: captureAny(named: 'currencyCode'),
            )).captured;
        final items = captured[0] as List<OrderLineItem>;
        expect(items.map((item) => item.toJson()).toList(), [
          {'slug': 'elec-001', 'quantity': 2},
          {'slug': 'cloth-002', 'quantity': 1},
        ]);
        expect(captured[1], same(_shipping));
        expect(captured[2], 'UZS');
      });

      test('returns true and exposes the confirmed order', () async {
        stubPlaceOrder(() async => _placedOrder);

        final result = await submit();

        expect(result, isTrue);
        expect(provider.status, CheckoutStatus.success);
        expect(provider.placedOrder, same(_placedOrder));
        expect(provider.errorCode, isNull);
      });

      test('clears the cart exactly once', () async {
        stubPlaceOrder(() async => _placedOrder);

        await submit();

        verify(() => mockCart.clearCart()).called(1);
      });

      test('does not clear the cart before the server responds', () async {
        final completer = Completer<PlacedOrder>();
        stubPlaceOrder(() => completer.future);

        final pending = submit();
        await Future.delayed(Duration.zero);

        verifyNever(() => mockCart.clearCart());

        completer.complete(_placedOrder);
        await pending;
        verify(() => mockCart.clearCart()).called(1);
      });

      test('transitions idle -> submitting -> success', () async {
        final completer = Completer<PlacedOrder>();
        stubPlaceOrder(() => completer.future);
        final statuses = recordStatuses();

        final pending = submit();

        expect(provider.status, CheckoutStatus.submitting);
        expect(provider.isSubmitting, isTrue);

        completer.complete(_placedOrder);
        await pending;

        expect(statuses, [CheckoutStatus.submitting, CheckoutStatus.success]);
        expect(provider.isSubmitting, isFalse);
      });
    });

    group('Rejected by the server (failure - safe to retry)', () {
      for (final code in _backendRejections) {
        test('${code.name}: preserves the cart and reports failure', () async {
          stubPlaceOrderThrows(CheckoutException(code, code.name));
          final statuses = recordStatuses();

          final result = await submit();

          expect(result, isFalse);
          expect(provider.status, CheckoutStatus.failure);
          expect(provider.errorCode, code);
          expect(provider.placedOrder, isNull);
          expect(statuses, [CheckoutStatus.submitting, CheckoutStatus.failure]);
          verifyNever(() => mockCart.clearCart());
          verifyPlaceOrder().called(1);
        });
      }

      test('allows a user-initiated resubmission after failure', () async {
        stubPlaceOrderThrows(const CheckoutException(
          CheckoutErrorCode.insufficientStock,
          'INSUFFICIENT_STOCK',
        ));
        await submit();

        stubPlaceOrder(() async => _placedOrder);
        final result = await submit();

        expect(result, isTrue);
        expect(provider.status, CheckoutStatus.success);
        verifyPlaceOrder().called(2);
        verify(() => mockCart.clearCart()).called(1);
      });
    });

    group('Outcome unknown', () {
      for (final code in [CheckoutErrorCode.unknown, CheckoutErrorCode.invalidResponse]) {
        test('${code.name}: preserves the cart and does not retry', () async {
          stubPlaceOrderThrows(CheckoutException(code, 'diagnostic'));

          final result = await submit();
          // Give any (incorrect) background retry a chance to run.
          await Future.delayed(const Duration(milliseconds: 10));

          expect(result, isFalse);
          expect(provider.status, CheckoutStatus.outcomeUnknown);
          expect(provider.errorCode, code);
          verifyNever(() => mockCart.clearCart());
          verifyPlaceOrder().called(1);
        });
      }

      test('a non-CheckoutException is treated as unknown outcome', () async {
        stubPlaceOrderThrows(StateError('unexpected'));

        await submit();

        expect(provider.status, CheckoutStatus.outcomeUnknown);
        expect(provider.errorCode, CheckoutErrorCode.unknown);
        verifyNever(() => mockCart.clearCart());
      });

      test('blocks further submissions until reset', () async {
        stubPlaceOrderThrows(const CheckoutException(CheckoutErrorCode.unknown, 'timeout'));
        await submit();

        final statuses = recordStatuses();
        final blocked = await submit();

        expect(blocked, isFalse);
        expect(statuses, isEmpty);
        expect(provider.status, CheckoutStatus.outcomeUnknown);
        verifyPlaceOrder().called(1);

        provider.reset();
        stubPlaceOrder(() async => _placedOrder);
        final afterReset = await submit();

        expect(afterReset, isTrue);
        verifyPlaceOrder().called(1);
      });
    });

    group('Rejected before sending', () {
      test('empty cart does not call the repository', () async {
        stubCart({});

        final result = await submit();

        expect(result, isFalse);
        expect(provider.status, CheckoutStatus.failure);
        expect(provider.errorCode, CheckoutErrorCode.emptyCart);
        verifyNoPlaceOrder();
        verifyNever(() => mockCart.clearCart());
      });

      test('signed-out user cannot submit', () async {
        final result = await submit(signedIn: false);

        expect(result, isFalse);
        expect(provider.status, CheckoutStatus.failure);
        expect(provider.errorCode, CheckoutErrorCode.notAuthenticated);
        verifyNoPlaceOrder();
      });

      test('missing AuthProvider (Supabase not initialized) cannot submit', () async {
        final result = await submit(authRegistered: false);

        expect(result, isFalse);
        expect(provider.errorCode, CheckoutErrorCode.notAuthenticated);
        verifyNoPlaceOrder();
      });

      test('unsupported currency code does not call the repository', () async {
        final result = await submit(currencyCode: 'GBP');

        expect(result, isFalse);
        expect(provider.errorCode, CheckoutErrorCode.invalidCurrency);
        verifyNoPlaceOrder();
      });

      test('each supported currency is accepted', () async {
        stubPlaceOrder(() async => _placedOrder);

        for (final currency in ['USD', 'EUR', 'UZS']) {
          provider.reset();
          expect(await submit(currencyCode: currency), isTrue);
        }
        verifyPlaceOrder().called(3);
      });
    });

    group('Duplicate submissions', () {
      test('a second submission while submitting does not call the repository again', () async {
        final completer = Completer<PlacedOrder>();
        stubPlaceOrder(() => completer.future);

        final first = submit();
        final second = await submit();

        expect(second, isFalse);
        expect(provider.status, CheckoutStatus.submitting);
        verifyPlaceOrder().called(1);

        completer.complete(_placedOrder);
        expect(await first, isTrue);
        verifyNoMoreInteractions(mockRepository);
        verify(() => mockCart.clearCart()).called(1);
      });

      test('reset is ignored while submitting', () async {
        final completer = Completer<PlacedOrder>();
        stubPlaceOrder(() => completer.future);

        final pending = submit();
        provider.reset();

        expect(provider.status, CheckoutStatus.submitting);

        completer.complete(_placedOrder);
        await pending;
        expect(provider.status, CheckoutStatus.success);
      });
    });

    group('reset', () {
      test('returns to idle and clears order and error', () async {
        stubPlaceOrder(() async => _placedOrder);
        await submit();

        provider.reset();

        expect(provider.status, CheckoutStatus.idle);
        expect(provider.placedOrder, isNull);
        expect(provider.errorCode, isNull);
      });
    });

    group('Disposal', () {
      test('completing after dispose does not throw', () async {
        final completer = Completer<PlacedOrder>();
        stubPlaceOrder(() => completer.future);

        final pending = submit();
        provider.dispose();
        completer.complete(_placedOrder);

        await expectLater(pending, completes);
      });
    });

    group('With a real CartProvider', () {
      late MockPersistenceService mockPersistence;
      late CartProvider cart;

      setUp(() async {
        mockPersistence = MockPersistenceService();
        when(() => mockPersistence.loadCart()).thenReturn([]);
        when(() => mockPersistence.saveCart(any())).thenAnswer((_) async => true);
        cart = CartProvider(mockPersistence);
        await Future.delayed(Duration.zero);
        cart.addToCart(watch);
        cart.addToCart(watch);
        cart.addToCart(jeans);
        when(() => mockAuth.isAuthenticated).thenReturn(true);
      });

      Future<bool> submitRealCart() => provider.submitOrder(
            cart: cart,
            auth: mockAuth,
            shipping: _shipping,
            currencyCode: 'EUR',
          );

      test('sends the real cart contents and empties it on success', () async {
        stubPlaceOrder(() async => _placedOrder);

        await submitRealCart();

        final items = verify(() => mockRepository.placeOrder(
              items: captureAny(named: 'items'),
              shipping: any(named: 'shipping'),
              currencyCode: any(named: 'currencyCode'),
            )).captured.single as List<OrderLineItem>;
        expect(items.map((item) => item.toJson()).toList(), [
          {'slug': 'elec-001', 'quantity': 2},
          {'slug': 'cloth-002', 'quantity': 1},
        ]);
        expect(cart.cartItems, isEmpty);
      });

      test('keeps items and quantities on failure', () async {
        stubPlaceOrderThrows(const CheckoutException(
          CheckoutErrorCode.productUnavailable,
          'PRODUCT_UNAVAILABLE',
        ));

        await submitRealCart();

        expect(cart.cartItems.map((p) => p.id), ['elec-001', 'cloth-002']);
        expect(cart.quantityOf('elec-001'), 2);
        expect(cart.quantityOf('cloth-002'), 1);
      });

      test('keeps items and quantities on unknown outcome', () async {
        stubPlaceOrderThrows(const CheckoutException(CheckoutErrorCode.unknown, 'timeout'));

        await submitRealCart();

        expect(cart.itemCount, 3);
      });
    });
  });
}
