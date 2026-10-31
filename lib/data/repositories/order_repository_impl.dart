import '../../domain/repositories/order_repository.dart';
import '../data_sources/remote/order_remote_data_source.dart';
import '../models/order.dart';

/// Order repository implementation (Data Layer)
///
/// Implements OrderRepository using Supabase backend.
/// Mediates between domain layer and data sources.
///
/// Architecture:
/// Provider -> Repository -> Data Source -> Supabase
class OrderRepositoryImpl implements OrderRepository {
  final OrderRemoteDataSource _remoteDataSource;

  OrderRepositoryImpl(this._remoteDataSource);

  @override
  Future<PlacedOrder> placeOrder({
    required List<OrderLineItem> items,
    required ShippingDetails shipping,
    required String currencyCode,
  }) {
    return _remoteDataSource.placeOrder(
      items: items,
      shipping: shipping,
      currencyCode: currencyCode,
    );
  }
}
