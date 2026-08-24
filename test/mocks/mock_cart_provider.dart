import 'package:mocktail/mocktail.dart';
import 'package:my_first_app/presentation/providers/cart_provider.dart';

/// Mock CartProvider for testing widgets that depend on cart state
///
/// Use with mocktail's when() to stub behavior and verify() to check interactions.
class MockCartProvider extends Mock implements CartProvider {}
