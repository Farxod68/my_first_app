import 'package:mocktail/mocktail.dart';
import 'package:my_first_app/domain/repositories/auth_repository.dart';

/// Mock AuthRepository for testing AuthProvider
///
/// Use with mocktail's when() to stub behavior and verify() to check interactions.
///
/// Example:
/// ```dart
/// final mockRepo = MockAuthRepository();
/// when(() => mockRepo.signInWithEmail(email: any(named: 'email'), password: any(named: 'password')))
///     .thenAnswer((_) async => testUser);
/// ```
class MockAuthRepository extends Mock implements AuthRepository {}
