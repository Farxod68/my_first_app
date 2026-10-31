import '../../data/models/order.dart';

/// Order repository interface (Domain Layer)
///
/// Defines the contract for placing orders.
/// Implementations handle the actual communication with backends.
///
/// Like ProductRepository, this works directly with the data-layer models
/// (lib/data/models/order.dart) rather than separate domain entities.
abstract class OrderRepository {
  /// Place an order for the signed-in user.
  ///
  /// [currencyCode] is the customer's display currency (USD, EUR or UZS).
  /// Returns the created order with its server-computed USD subtotal.
  ///
  /// Throws CheckoutException on failure.
  Future<PlacedOrder> placeOrder({
    required List<OrderLineItem> items,
    required ShippingDetails shipping,
    required String currencyCode,
  });
}
