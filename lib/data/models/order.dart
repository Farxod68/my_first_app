// Order placement models.
//
// These mirror the contract of `public.place_order()` in
// supabase/migrations/006_place_order.sql. The function takes no user id
// and no prices: the ordering user comes from `auth.uid()` and every price
// is re-read from `public.products` server-side, so neither appears here.

/// One cart line sent to `place_order` as `{ "slug": ..., "quantity": ... }`.
///
/// [productId] is the Flutter `Product.id`, which is the `products.slug`
/// (see `Product.fromSupabase`).
class OrderLineItem {
  final String productId;
  final int quantity;

  const OrderLineItem({
    required this.productId,
    required this.quantity,
  });

  /// JSON object for the `p_items` array.
  Map<String, dynamic> toJson() => {
        'slug': productId,
        'quantity': quantity,
      };
}

/// Shipping details sent as the five `p_shipping_*` parameters.
///
/// All fields are required and must be non-blank; the server rejects blank
/// values with `INVALID_SHIPPING` and stores trimmed values.
class ShippingDetails {
  final String fullName;
  final String phone;
  final String addressLine;
  final String city;
  final String country;

  const ShippingDetails({
    required this.fullName,
    required this.phone,
    required this.addressLine,
    required this.city,
    required this.country,
  });
}

/// The order created by a successful `place_order` call.
///
/// [subtotalUsd] is the server-computed subtotal in USD, which can differ
/// from the cart's client-side subtotal if prices changed.
class PlacedOrder {
  final String orderId;
  final double subtotalUsd;

  const PlacedOrder({
    required this.orderId,
    required this.subtotalUsd,
  });

  /// Parses one `(order_id, subtotal_usd)` row.
  ///
  /// Returns null if the row does not have that shape. `subtotal_usd` is a
  /// Postgres numeric, accepted as either a JSON number or a numeric string.
  static PlacedOrder? tryFromRow(Object? row) {
    if (row is! Map) return null;

    final orderId = row['order_id'];
    if (orderId is! String || orderId.isEmpty) return null;

    final rawSubtotal = row['subtotal_usd'];
    final double? subtotal = switch (rawSubtotal) {
      num value => value.toDouble(),
      String value => double.tryParse(value),
      _ => null,
    };
    if (subtotal == null) return null;

    return PlacedOrder(orderId: orderId, subtotalUsd: subtotal);
  }
}
