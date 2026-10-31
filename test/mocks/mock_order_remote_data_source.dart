import 'package:mocktail/mocktail.dart';
import 'package:my_first_app/data/data_sources/remote/order_remote_data_source.dart';

/// Mock OrderRemoteDataSource for testing OrderRepositoryImpl
///
/// Use with mocktail's when() to stub behavior and verify() to check interactions.
class MockOrderRemoteDataSource extends Mock implements OrderRemoteDataSource {}
