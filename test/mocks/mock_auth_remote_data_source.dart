import 'package:mocktail/mocktail.dart';
import 'package:my_first_app/data/data_sources/remote/auth_remote_data_source.dart';

/// Mock AuthRemoteDataSource for testing AuthRepositoryImpl
///
/// Use with mocktail's when() to stub behavior and verify() to check interactions.
class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}
