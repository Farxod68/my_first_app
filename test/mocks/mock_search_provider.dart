import 'package:mocktail/mocktail.dart';
import 'package:my_first_app/presentation/providers/search_provider.dart';

/// Mock SearchProvider for testing widgets that depend on search state
///
/// Use with mocktail's when() to stub behavior and verify() to check interactions.
///
/// Example:
/// ```dart
/// final mockSearchProvider = MockSearchProvider();
/// when(() => mockSearchProvider.recentSearches).thenReturn(['laptop', 'phone']);
/// when(() => mockSearchProvider.addRecentSearch(any())).thenReturn(null);
/// when(() => mockSearchProvider.getSuggestions(any(), maxSuggestions: any(named: 'maxSuggestions')))
///     .thenReturn(['suggestion1', 'suggestion2']);
/// ```
class MockSearchProvider extends Mock implements SearchProvider {}
