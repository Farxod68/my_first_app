import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_first_app/data/data_sources/remote/order_remote_data_source.dart';
import 'package:my_first_app/data/models/order.dart';

// Mock Supabase client
class MockSupabaseClient extends Mock implements SupabaseClient {}

/// Fake awaitable result of `SupabaseClient.rpc()`, mirroring the fake
/// builders in product_remote_data_source_test.dart. Completes with [data],
/// or fails with [error] when awaited - which is where real PostgREST errors
/// surface, since the request is only sent on await.
class FakeRpcBuilder implements PostgrestFilterBuilder<dynamic> {
  final Object? data;
  final Object? error;

  FakeRpcBuilder({this.data, this.error});

  Future<dynamic> get _future =>
      error != null ? Future<dynamic>.error(error!) : Future<dynamic>.value(data);

  @override
  Future<R> then<R>(
    FutureOr<R> Function(dynamic) onValue,
    {Function? onError}
  ) {
    return _future.then(onValue, onError: onError);
  }

  @override
  Stream<dynamic> asStream() => _future.asStream();

  @override
  Future<dynamic> catchError(Function onError, {bool Function(Object)? test}) {
    return _future.catchError(onError, test: test);
  }

  @override
  Future<dynamic> whenComplete(FutureOr<void> Function() action) {
    return _future.whenComplete(action);
  }

  @override
  Future<dynamic> timeout(
    Duration timeLimit, {
    FutureOr<dynamic> Function()? onTimeout,
  }) {
    return _future;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _items = [
  OrderLineItem(productId: 'elec-001', quantity: 2),
  OrderLineItem(productId: 'cloth-003', quantity: 1),
];

const _shipping = ShippingDetails(
  fullName: 'Ali Valiyev',
  phone: '+998901234567',
  addressLine: 'Amir Temur 1',
  city: 'Tashkent',
  country: 'Uzbekistan',
);

const _orderId = '6f1c2e2a-3b4d-4e5f-8a9b-0c1d2e3f4a5b';

void main() {
  group('OrderRemoteDataSource', () {
    late MockSupabaseClient mockSupabase;
    late OrderRemoteDataSource dataSource;

    void stubRpc(FakeRpcBuilder builder) {
      when(() => mockSupabase.rpc<dynamic>(
            'place_order',
            params: any(named: 'params'),
          )).thenAnswer((_) => builder);
    }

    Future<PlacedOrder> placeOrder({String currencyCode = 'USD'}) {
      return dataSource.placeOrder(
        items: _items,
        shipping: _shipping,
        currencyCode: currencyCode,
      );
    }

    Matcher throwsCheckout(CheckoutErrorCode code) {
      return throwsA(isA<CheckoutException>().having((e) => e.code, 'code', code));
    }

    setUp(() {
      mockSupabase = MockSupabaseClient();
      dataSource = OrderRemoteDataSource(mockSupabase);
    });

    group('Constructor', () {
      test('creates instance with provided SupabaseClient', () {
        expect(dataSource, isA<OrderRemoteDataSource>());
      });
    });

    group('placeOrder - request', () {
      test('calls place_order with the exact parameters from migration 006', () async {
        stubRpc(FakeRpcBuilder(data: [
          {'order_id': _orderId, 'subtotal_usd': 22.5},
        ]));

        await placeOrder(currencyCode: 'UZS');

        final captured = verify(() => mockSupabase.rpc<dynamic>(
              'place_order',
              params: captureAny(named: 'params'),
            )).captured;
        expect(captured.single, {
          'p_items': [
            {'slug': 'elec-001', 'quantity': 2},
            {'slug': 'cloth-003', 'quantity': 1},
          ],
          'p_shipping_full_name': 'Ali Valiyev',
          'p_shipping_phone': '+998901234567',
          'p_shipping_address_line': 'Amir Temur 1',
          'p_shipping_city': 'Tashkent',
          'p_shipping_country': 'Uzbekistan',
          'p_currency_code': 'UZS',
        });
      });

      test('sends no user id or price parameters', () async {
        stubRpc(FakeRpcBuilder(data: [
          {'order_id': _orderId, 'subtotal_usd': 22.5},
        ]));

        await placeOrder();

        final params = verify(() => mockSupabase.rpc<dynamic>(
              'place_order',
              params: captureAny(named: 'params'),
            )).captured.single as Map<String, dynamic>;
        expect(params.keys, isNot(contains('p_user_id')));
        for (final item in params['p_items'] as List) {
          expect((item as Map).keys, unorderedEquals(['slug', 'quantity']));
        }
      });

      test('calls the RPC exactly once per placeOrder', () async {
        stubRpc(FakeRpcBuilder(data: [
          {'order_id': _orderId, 'subtotal_usd': 22.5},
        ]));

        await placeOrder();

        verify(() => mockSupabase.rpc<dynamic>(
              'place_order',
              params: any(named: 'params'),
            )).called(1);
      });
    });

    group('placeOrder - response parsing', () {
      test('parses a numeric subtotal', () async {
        stubRpc(FakeRpcBuilder(data: [
          {'order_id': _orderId, 'subtotal_usd': 22.5},
        ]));

        final order = await placeOrder();

        expect(order.orderId, _orderId);
        expect(order.subtotalUsd, 22.5);
      });

      test('parses an integer subtotal', () async {
        stubRpc(FakeRpcBuilder(data: [
          {'order_id': _orderId, 'subtotal_usd': 40},
        ]));

        final order = await placeOrder();

        expect(order.subtotalUsd, 40.0);
      });

      test('parses a numeric-string subtotal', () async {
        stubRpc(FakeRpcBuilder(data: [
          {'order_id': _orderId, 'subtotal_usd': '1234.56'},
        ]));

        final order = await placeOrder();

        expect(order.subtotalUsd, 1234.56);
      });

      final invalidResponses = <String, Object?>{
        'null': null,
        'an empty list': <Object>[],
        'two rows': [
          {'order_id': _orderId, 'subtotal_usd': 1},
          {'order_id': _orderId, 'subtotal_usd': 2},
        ],
        'a bare object instead of a list': {'order_id': _orderId, 'subtotal_usd': 1},
        'a list containing a non-object': ['oops'],
        'a missing order_id': [
          {'subtotal_usd': 1},
        ],
        'an empty order_id': [
          {'order_id': '', 'subtotal_usd': 1},
        ],
        'a non-string order_id': [
          {'order_id': 42, 'subtotal_usd': 1},
        ],
        'a missing subtotal_usd': [
          {'order_id': _orderId},
        ],
        'a null subtotal_usd': [
          {'order_id': _orderId, 'subtotal_usd': null},
        ],
        'a non-numeric subtotal_usd string': [
          {'order_id': _orderId, 'subtotal_usd': 'abc'},
        ],
      };

      invalidResponses.forEach((description, data) {
        test('throws invalidResponse for $description', () async {
          stubRpc(FakeRpcBuilder(data: data));

          await expectLater(placeOrder(), throwsCheckout(CheckoutErrorCode.invalidResponse));
        });
      });
    });

    group('placeOrder - backend error codes', () {
      const backendCodes = {
        'NOT_AUTHENTICATED': CheckoutErrorCode.notAuthenticated,
        'EMPTY_CART': CheckoutErrorCode.emptyCart,
        'INVALID_QUANTITY': CheckoutErrorCode.invalidQuantity,
        'DUPLICATE_ITEM': CheckoutErrorCode.duplicateItem,
        'INVALID_SHIPPING': CheckoutErrorCode.invalidShipping,
        'INVALID_CURRENCY': CheckoutErrorCode.invalidCurrency,
        'PRODUCT_UNAVAILABLE': CheckoutErrorCode.productUnavailable,
        'INSUFFICIENT_STOCK': CheckoutErrorCode.insufficientStock,
      };

      backendCodes.forEach((message, code) {
        test('maps $message (P0001) to $code', () async {
          stubRpc(FakeRpcBuilder(
            error: PostgrestException(message: message, code: 'P0001'),
          ));

          await expectLater(
            placeOrder(),
            throwsA(isA<CheckoutException>()
                .having((e) => e.code, 'code', code)
                .having((e) => e.message, 'message', message)),
          );
        });
      });

      test('maps a missing EXECUTE grant (42501) to notAuthenticated', () async {
        stubRpc(FakeRpcBuilder(
          error: const PostgrestException(
            message: 'permission denied for function place_order',
            code: '42501',
          ),
        ));

        await expectLater(placeOrder(), throwsCheckout(CheckoutErrorCode.notAuthenticated));
      });

      test('maps an unknown P0001 message to unknown', () async {
        stubRpc(FakeRpcBuilder(
          error: const PostgrestException(message: 'SOMETHING_ELSE', code: 'P0001'),
        ));

        await expectLater(placeOrder(), throwsCheckout(CheckoutErrorCode.unknown));
      });

      test('does not map a known message carried by a different SQLSTATE', () async {
        stubRpc(FakeRpcBuilder(
          error: const PostgrestException(message: 'EMPTY_CART', code: '23505'),
        ));

        await expectLater(placeOrder(), throwsCheckout(CheckoutErrorCode.unknown));
      });

      test('maps other PostgREST errors to unknown with the original message', () async {
        stubRpc(FakeRpcBuilder(
          error: const PostgrestException(message: 'JWT expired', code: 'PGRST303'),
        ));

        await expectLater(
          placeOrder(),
          throwsA(isA<CheckoutException>()
              .having((e) => e.code, 'code', CheckoutErrorCode.unknown)
              .having((e) => e.message, 'message', contains('JWT expired'))),
        );
      });
    });

    group('placeOrder - network and unexpected errors', () {
      test('maps an error thrown on await to unknown', () async {
        stubRpc(FakeRpcBuilder(error: Exception('SocketException: connection reset')));

        await expectLater(
          placeOrder(),
          throwsA(isA<CheckoutException>()
              .having((e) => e.code, 'code', CheckoutErrorCode.unknown)
              .having((e) => e.message, 'message', contains('connection reset'))),
        );
      });

      test('maps a timeout to unknown', () async {
        stubRpc(FakeRpcBuilder(error: TimeoutException('request timed out')));

        await expectLater(placeOrder(), throwsCheckout(CheckoutErrorCode.unknown));
      });

      test('maps an error thrown synchronously by rpc() to unknown', () async {
        when(() => mockSupabase.rpc<dynamic>(
              'place_order',
              params: any(named: 'params'),
            )).thenThrow(Exception('client disposed'));

        await expectLater(placeOrder(), throwsCheckout(CheckoutErrorCode.unknown));
      });
    });
  });
}
