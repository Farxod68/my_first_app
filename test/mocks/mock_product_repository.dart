import 'package:mocktail/mocktail.dart';
import 'package:my_first_app/domain/repositories/product_repository.dart';

/// Mock ProductRepository for testing ProductProvider
///
/// Use with mocktail's when() to stub behavior and verify() to check interactions.
class MockProductRepository extends Mock implements ProductRepository {}
