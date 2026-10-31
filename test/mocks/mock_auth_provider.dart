import 'package:mocktail/mocktail.dart';
import 'package:my_first_app/presentation/providers/auth_provider.dart';

/// Mock AuthProvider for testing code that only reads auth state
///
/// Use with mocktail's when() to stub behavior and verify() to check interactions.
class MockAuthProvider extends Mock implements AuthProvider {}
