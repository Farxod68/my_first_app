import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../../models/order.dart';

/// Why an order could not be placed.
///
/// The first eight values match, one-to-one, the error codes that
/// `public.place_order()` raises (supabase/migrations/006_place_order.sql).
enum CheckoutErrorCode {
  /// `NOT_AUTHENTICATED`, or the caller has no EXECUTE grant on the function
  /// (only `authenticated` has it; `anon` is revoked).
  notAuthenticated,

  /// `EMPTY_CART`
  emptyCart,

  /// `INVALID_QUANTITY`
  invalidQuantity,

  /// `DUPLICATE_ITEM`
  duplicateItem,

  /// `INVALID_SHIPPING`
  invalidShipping,

  /// `INVALID_CURRENCY`
  invalidCurrency,

  /// `PRODUCT_UNAVAILABLE`
  productUnavailable,

  /// `INSUFFICIENT_STOCK`
  insufficientStock,

  /// The call succeeded but did not return one `(order_id, subtotal_usd)` row.
  ///
  /// The order may have been created, so callers must not blindly retry.
  invalidResponse,

  /// Any other backend or network failure. The outcome is unknown: the order
  /// may or may not have been created.
  unknown,
}

/// Thrown when placing an order fails.
///
/// [code] is what callers should branch on; [message] is diagnostic only.
class CheckoutException implements Exception {
  final CheckoutErrorCode code;
  final String message;

  const CheckoutException(this.code, this.message);

  @override
  String toString() => message;
}

/// `RAISE EXCEPTION` messages from place_order(), mapped to their codes.
const Map<String, CheckoutErrorCode> _backendErrorCodes = {
  'NOT_AUTHENTICATED': CheckoutErrorCode.notAuthenticated,
  'EMPTY_CART': CheckoutErrorCode.emptyCart,
  'INVALID_QUANTITY': CheckoutErrorCode.invalidQuantity,
  'DUPLICATE_ITEM': CheckoutErrorCode.duplicateItem,
  'INVALID_SHIPPING': CheckoutErrorCode.invalidShipping,
  'INVALID_CURRENCY': CheckoutErrorCode.invalidCurrency,
  'PRODUCT_UNAVAILABLE': CheckoutErrorCode.productUnavailable,
  'INSUFFICIENT_STOCK': CheckoutErrorCode.insufficientStock,
};

/// Postgres `raise_exception` SQLSTATE - what a bare `RAISE EXCEPTION` uses.
const String _raiseExceptionSqlState = 'P0001';

/// Postgres `insufficient_privilege` SQLSTATE - returned when a caller
/// without the EXECUTE grant (i.e. not signed in) calls place_order().
const String _insufficientPrivilegeSqlState = '42501';

/// Order remote data source (Data Layer)
///
/// Places orders through the `public.place_order()` RPC - the only write
/// path for orders (RLS gives the application no direct INSERT on
/// orders/order_items). Never called directly from UI - always through
/// OrderRepository.
class OrderRemoteDataSource {
  final SupabaseClient _supabase;

  OrderRemoteDataSource([SupabaseClient? supabase])
      : _supabase = supabase ?? SupabaseService.client;

  /// Place an order for the signed-in user.
  ///
  /// [currencyCode] is the customer's display currency (USD, EUR or UZS);
  /// amounts are always computed and returned in USD.
  ///
  /// Throws [CheckoutException] on any failure.
  Future<PlacedOrder> placeOrder({
    required List<OrderLineItem> items,
    required ShippingDetails shipping,
    required String currencyCode,
  }) async {
    final Object? response;
    try {
      // <dynamic>: the response shape is validated below, not cast blindly.
      response = await _supabase.rpc<dynamic>(
        'place_order',
        params: {
          'p_items': items.map((item) => item.toJson()).toList(),
          'p_shipping_full_name': shipping.fullName,
          'p_shipping_phone': shipping.phone,
          'p_shipping_address_line': shipping.addressLine,
          'p_shipping_city': shipping.city,
          'p_shipping_country': shipping.country,
          'p_currency_code': currencyCode,
        },
      );
    } on PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      throw CheckoutException(
        CheckoutErrorCode.unknown,
        'Failed to place order: $e',
      );
    }

    // place_order() RETURNS TABLE, which PostgREST returns as a JSON array;
    // the function always returns exactly one row.
    final order = response is List && response.length == 1
        ? PlacedOrder.tryFromRow(response.single)
        : null;
    if (order == null) {
      throw CheckoutException(
        CheckoutErrorCode.invalidResponse,
        'Unexpected place_order response: $response',
      );
    }
    return order;
  }

  CheckoutException _mapPostgrestException(PostgrestException e) {
    if (e.code == _raiseExceptionSqlState) {
      final code = _backendErrorCodes[e.message];
      if (code != null) {
        return CheckoutException(code, e.message);
      }
    }
    if (e.code == _insufficientPrivilegeSqlState) {
      return CheckoutException(CheckoutErrorCode.notAuthenticated, e.message);
    }
    return CheckoutException(
      CheckoutErrorCode.unknown,
      'Failed to place order: ${e.message}',
    );
  }
}
