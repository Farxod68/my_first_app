import 'package:flutter/foundation.dart';
import '../../data/data_sources/remote/order_remote_data_source.dart';
import '../../data/models/order.dart';
import '../../domain/repositories/order_repository.dart';
import 'auth_provider.dart';
import 'cart_provider.dart';
import 'currency_provider.dart';

/// Where the current checkout attempt stands.
enum CheckoutStatus {
  /// Nothing submitted yet, or [CheckoutProvider.reset] was called.
  idle,

  /// A place_order request is in flight.
  submitting,

  /// The server confirmed the order; see [CheckoutProvider.placedOrder].
  success,

  /// The order was definitely NOT created - rejected before sending, or
  /// rejected by place_order(), which rolls back on every error. Safe to fix
  /// and submit again; see [CheckoutProvider.errorCode].
  failure,

  /// The request may have reached the server but no valid confirmation came
  /// back (network error, timeout, unexpected response). The order may or may
  /// not exist. Never retried automatically; further submissions are blocked
  /// until [CheckoutProvider.reset] is called.
  outcomeUnknown,
}

/// Checkout state management provider (Presentation Layer)
///
/// Turns the cart into a place_order request via [OrderRepository] and
/// tracks the result.
///
/// Guarantees:
/// - At most one request in flight per provider; extra submissions while
///   submitting (or while an unknown outcome is unacknowledged) are ignored.
/// - The cart is cleared only after the server confirms the order.
/// - Nothing is ever retried automatically.
///
/// The in-flight guard only prevents duplicate requests from this app
/// instance. place_order() has no idempotency key, so it does NOT make order
/// creation idempotent on the server.
///
/// Uses ChangeNotifier for state management with Provider pattern.
class CheckoutProvider with ChangeNotifier {
  final OrderRepository _orderRepository;

  CheckoutStatus _status = CheckoutStatus.idle;
  PlacedOrder? _placedOrder;
  CheckoutErrorCode? _errorCode;
  bool _disposed = false;

  CheckoutProvider(this._orderRepository);

  /// Current checkout status
  CheckoutStatus get status => _status;

  /// True while a place_order request is in flight
  bool get isSubmitting => _status == CheckoutStatus.submitting;

  /// The confirmed order, set only when [status] is [CheckoutStatus.success]
  PlacedOrder? get placedOrder => _placedOrder;

  /// Why the last attempt did not succeed, set only when [status] is
  /// [CheckoutStatus.failure] or [CheckoutStatus.outcomeUnknown]. Lets the UI
  /// show a localized message.
  CheckoutErrorCode? get errorCode => _errorCode;

  /// Place an order for everything in [cart].
  ///
  /// [auth] is nullable because AuthProvider is only registered when
  /// Supabase is initialized (see main.dart); null counts as signed out.
  /// [currencyCode] must be one of [CurrencyProvider.supportedCurrencies].
  ///
  /// Returns true only if the order was confirmed. Returns false without
  /// changing any state if a submission is in flight or an unknown outcome
  /// has not been [reset].
  Future<bool> submitOrder({
    required CartProvider cart,
    required AuthProvider? auth,
    required ShippingDetails shipping,
    required String currencyCode,
  }) async {
    if (_status == CheckoutStatus.submitting ||
        _status == CheckoutStatus.outcomeUnknown) {
      return false;
    }

    if (auth == null || !auth.isAuthenticated) {
      return _fail(CheckoutErrorCode.notAuthenticated);
    }
    if (!CurrencyProvider.supportedCurrencies.contains(currencyCode)) {
      return _fail(CheckoutErrorCode.invalidCurrency);
    }

    // Snapshot the cart now: this is exactly what gets ordered.
    final items = [
      for (final product in cart.cartItems)
        OrderLineItem(
          productId: product.id,
          quantity: cart.quantityOf(product.id),
        ),
    ];
    if (items.isEmpty) {
      return _fail(CheckoutErrorCode.emptyCart);
    }

    _status = CheckoutStatus.submitting;
    _placedOrder = null;
    _errorCode = null;
    _notify();

    final PlacedOrder order;
    try {
      order = await _orderRepository.placeOrder(
        items: items,
        shipping: shipping,
        currencyCode: currencyCode,
      );
    } on CheckoutException catch (e) {
      // Log only the code: messages can echo the server response.
      debugPrint('Checkout failed: ${e.code.name}');
      return _isOutcomeUnknown(e.code)
          ? _unknownOutcome(e.code)
          : _fail(e.code);
    } catch (e) {
      debugPrint('Checkout failed: unexpected ${e.runtimeType}');
      return _unknownOutcome(CheckoutErrorCode.unknown);
    }

    cart.clearCart();
    _status = CheckoutStatus.success;
    _placedOrder = order;
    _notify();
    return true;
  }

  /// Return to [CheckoutStatus.idle], e.g. after the user has seen the
  /// result. Ignored while a submission is in flight.
  void reset() {
    if (_status == CheckoutStatus.submitting) return;
    _status = CheckoutStatus.idle;
    _placedOrder = null;
    _errorCode = null;
    _notify();
  }

  /// Codes for which the server may already have created the order.
  static bool _isOutcomeUnknown(CheckoutErrorCode code) =>
      code == CheckoutErrorCode.unknown ||
      code == CheckoutErrorCode.invalidResponse;

  bool _fail(CheckoutErrorCode code) {
    _status = CheckoutStatus.failure;
    _errorCode = code;
    _notify();
    return false;
  }

  bool _unknownOutcome(CheckoutErrorCode code) {
    _status = CheckoutStatus.outcomeUnknown;
    _errorCode = code;
    _notify();
    return false;
  }

  /// notifyListeners() that is safe if the provider was disposed while a
  /// request was in flight.
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
