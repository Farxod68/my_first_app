import 'package:mocktail/mocktail.dart';
import 'package:my_first_app/data/data_sources/remote/product_remote_data_source.dart';

/// Mock ProductRemoteDataSource for testing ProductRepositoryImpl
///
/// Use with mocktail's when() to stub behavior and verify() to check interactions.
class MockProductRemoteDataSource extends Mock implements ProductRemoteDataSource {}
