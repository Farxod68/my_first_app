import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_first_app/data/data_sources/remote/order_remote_data_source.dart';
import 'package:my_first_app/data/models/order.dart';
import 'package:my_first_app/data/repositories/order_repository_impl.dart';
import '../../../mocks/mock_order_remote_data_source.dart';

void main() {
  group('OrderRepositoryImpl', () {
    late MockOrderRemoteDataSource mockDataSource;
    late OrderRepositoryImpl repository;

    const items = [OrderLineItem(productId: 'elec-001', quantity: 2)];
    const shipping = ShippingDetails(
      fullName: 'Ali Valiyev',
      phone: '+998901234567',
      addressLine: 'Amir Temur 1',
      city: 'Tashkent',
      country: 'Uzbekistan',
    );
    const placedOrder = PlacedOrder(orderId: 'order-1', subtotalUsd: 22.5);

    setUpAll(() {
      registerFallbackValue(shipping);
      registerFallbackValue(<OrderLineItem>[]);
    });

    setUp(() {
      mockDataSource = MockOrderRemoteDataSource();
      repository = OrderRepositoryImpl(mockDataSource);
    });

    group('Constructor', () {
      test('creates instance with data source', () {
        expect(repository, isA<OrderRepositoryImpl>());
      });
    });

    group('placeOrder', () {
      test('passes arguments through and returns the data source result', () async {
        when(() => mockDataSource.placeOrder(
              items: items,
              shipping: shipping,
              currencyCode: 'EUR',
            )).thenAnswer((_) async => placedOrder);

        final result = await repository.placeOrder(
          items: items,
          shipping: shipping,
          currencyCode: 'EUR',
        );

        expect(result, same(placedOrder));
        verify(() => mockDataSource.placeOrder(
              items: items,
              shipping: shipping,
              currencyCode: 'EUR',
            )).called(1);
      });

      test('propagates CheckoutException from data source unchanged', () async {
        const error = CheckoutException(
          CheckoutErrorCode.insufficientStock,
          'INSUFFICIENT_STOCK',
        );
        when(() => mockDataSource.placeOrder(
              items: any(named: 'items'),
              shipping: any(named: 'shipping'),
              currencyCode: any(named: 'currencyCode'),
            )).thenThrow(error);

        expect(
          () => repository.placeOrder(
            items: items,
            shipping: shipping,
            currencyCode: 'USD',
          ),
          throwsA(same(error)),
        );
      });
    });
  });
}
