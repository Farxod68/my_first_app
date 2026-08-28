import 'package:mocktail/mocktail.dart';
import 'package:my_first_app/core/services/persistence_service.dart';

/// Mock PersistenceService for testing providers
///
/// Use with mocktail's when() to stub behavior and verify() to check interactions.
///
/// Example:
/// ```dart
/// final mockService = MockPersistenceService();
/// when(() => mockService.getString('key')).thenReturn('value');
/// ```
class MockPersistenceService extends Mock implements PersistenceService {}
