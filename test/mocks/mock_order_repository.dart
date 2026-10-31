import 'package:mocktail/mocktail.dart';
import 'package:my_first_app/domain/repositories/order_repository.dart';

/// Mock OrderRepository for testing CheckoutProvider
///
/// Use with mocktail's when() to stub behavior and verify() to check interactions.
class MockOrderRepository extends Mock implements OrderRepository {}
