import 'package:mocktail/mocktail.dart';
import 'package:my_first_app/presentation/providers/recently_viewed_provider.dart';

/// Mock RecentlyViewedProvider for testing widgets that depend on recently viewed state
///
/// Use with mocktail's when() to stub behavior and verify() to check interactions.
class MockRecentlyViewedProvider extends Mock implements RecentlyViewedProvider {}
