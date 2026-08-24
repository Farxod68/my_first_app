import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_first_app/core/constants/widget_keys.dart';
import 'package:my_first_app/data/models/filter_models.dart';
import 'package:my_first_app/presentation/providers/search_provider.dart';
import 'package:my_first_app/presentation/providers/wishlist_provider.dart';
import 'package:my_first_app/presentation/screens/search/search_results_page.dart';
import 'package:my_first_app/presentation/widgets/product_search_delegate.dart';
import 'package:provider/provider.dart';
import '../helpers/test_data.dart';
import '../helpers/widget_test_helpers.dart';
import '../mocks/mock_search_provider.dart';
import '../mocks/mock_wishlist_provider.dart';

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

class FakeRoute extends Fake implements Route<dynamic> {}

void main() {
  group('ProductSearchDelegate Widget Tests', () {
    late MockSearchProvider mockSearchProvider;
    late MockWishlistProvider mockWishlistProvider;
    late ProductSearchDelegate searchDelegate;

    setUp(() {
      mockSearchProvider = MockSearchProvider();
      mockWishlistProvider = MockWishlistProvider();
      searchDelegate = ProductSearchDelegate();

      // Register fallback values
      registerFallbackValue(const RouteSettings());
      registerFallbackValue(FakeRoute());

      // Setup default behaviors
      when(() => mockSearchProvider.recentSearches).thenReturn([]);
      when(() => mockSearchProvider.setQuery(any())).thenReturn(null);
      when(() => mockSearchProvider.addRecentSearch(any())).thenReturn(null);
      when(() => mockSearchProvider.clearRecentSearches()).thenReturn(null);
      when(() => mockSearchProvider.removeRecentSearch(any())).thenReturn(null);
      when(() => mockSearchProvider.getSuggestions(any(), maxSuggestions: any(named: 'maxSuggestions')))
          .thenReturn([]);
      when(() => mockSearchProvider.searchAndFilter(any())).thenReturn([]);
      when(() => mockSearchProvider.hasSearch).thenReturn(false);
      when(() => mockSearchProvider.hasFilters).thenReturn(false);
      when(() => mockSearchProvider.filters).thenReturn(const ProductFilters());
      when(() => mockSearchProvider.query).thenReturn(SearchQuery(''));
      when(() => mockWishlistProvider.isFavorite(any())).thenReturn(false);
    });

    /// Helper to pump a widget with the search delegate opened
    Future<void> pumpSearchDelegate(
      WidgetTester tester, {
      NavigatorObserver? observer,
    }) async {
      await pumpAppWithProviders(
        tester,
        Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () {
                showSearch(
                  context: context,
                  delegate: searchDelegate,
                );
              },
              child: const Text('Open Search'),
            );
          },
        ),
        providers: [
          ChangeNotifierProvider<SearchProvider>.value(
            value: mockSearchProvider,
          ),
          ChangeNotifierProvider<WishlistProvider>.value(
            value: mockWishlistProvider,
          ),
        ],
        navigatorObserver: observer,
      );

      // Tap button to open search
      await tester.tap(find.text('Open Search'));
      await tester.pumpAndSettle();
    }

    testWidgets('buildActions shows clear button when query is non-empty', (tester) async {
      await pumpSearchDelegate(tester);

      // Set a query
      searchDelegate.query = 'laptop';
      await tester.pumpAndSettle();

      // Clear button should be visible
      expect(find.byKey(WidgetKeys.searchClearButton), findsOneWidget);
      expect(find.byIcon(Icons.clear), findsOneWidget);
    });

    testWidgets('buildActions hides clear button when query is empty', (tester) async {
      await pumpSearchDelegate(tester);

      // Query is empty by default
      expect(searchDelegate.query, isEmpty);

      // Clear button should not be visible
      expect(find.byKey(WidgetKeys.searchClearButton), findsNothing);
    });

    testWidgets('tapping clear button clears the query', (tester) async {
      await pumpSearchDelegate(tester);

      // Set a query
      searchDelegate.query = 'laptop';
      await tester.pumpAndSettle();

      expect(searchDelegate.query, equals('laptop'));

      // Tap clear button
      await tester.tap(find.byKey(WidgetKeys.searchClearButton));
      await tester.pumpAndSettle();

      // Query should be cleared
      expect(searchDelegate.query, isEmpty);
    });

    testWidgets('buildLeading shows back button with correct key', (tester) async {
      await pumpSearchDelegate(tester);

      // Back button should be visible
      expect(find.byKey(WidgetKeys.searchBackButton), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('tapping back button closes search', (tester) async {
      await pumpSearchDelegate(tester);

      // Verify we're in search by checking for search field
      expect(find.byType(TextField), findsOneWidget);

      // Tap back button
      await tester.tap(find.byKey(WidgetKeys.searchBackButton));
      await tester.pumpAndSettle();

      // Search should be closed - back to main screen
      expect(find.text('Open Search'), findsOneWidget);
      // Search field should be gone
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('buildSuggestions shows empty state when no recent searches and query is empty', (tester) async {
      when(() => mockSearchProvider.recentSearches).thenReturn([]);

      await pumpSearchDelegate(tester);

      // Should show empty state hint
      expect(find.text('Search products, brands, deals...'), findsOneWidget);
    });

    testWidgets('buildSuggestions shows recent searches when query is empty', (tester) async {
      when(() => mockSearchProvider.recentSearches).thenReturn(['laptop', 'phone', 'tablet']);

      await pumpSearchDelegate(tester);

      // Should show recent searches
      expect(find.text('laptop'), findsOneWidget);
      expect(find.text('phone'), findsOneWidget);
      expect(find.text('tablet'), findsOneWidget);
    });

    testWidgets('buildSuggestions shows Recent Searches label and Clear All button', (tester) async {
      when(() => mockSearchProvider.recentSearches).thenReturn(['laptop', 'phone']);

      await pumpSearchDelegate(tester);

      // Should show recent searches label
      expect(find.text('Recent Searches'), findsOneWidget);

      // Should show Clear All button
      expect(find.byKey(WidgetKeys.searchClearHistoryButton), findsOneWidget);
      expect(find.text('Clear History'), findsOneWidget);
    });

    testWidgets('buildSuggestions uses correct widget keys for list and items', (tester) async {
      when(() => mockSearchProvider.recentSearches).thenReturn(['laptop', 'phone', 'tablet']);

      await pumpSearchDelegate(tester);

      // List should have key
      expect(find.byKey(WidgetKeys.searchSuggestionsList), findsOneWidget);

      // Items should have keys
      expect(find.byKey(WidgetKeys.searchSuggestion(0)), findsOneWidget);
      expect(find.byKey(WidgetKeys.searchSuggestion(1)), findsOneWidget);
      expect(find.byKey(WidgetKeys.searchSuggestion(2)), findsOneWidget);
    });

    testWidgets('tapping Clear All button calls clearRecentSearches', (tester) async {
      when(() => mockSearchProvider.recentSearches).thenReturn(['laptop', 'phone']);

      await pumpSearchDelegate(tester);

      // Tap Clear All button
      await tester.tap(find.byKey(WidgetKeys.searchClearHistoryButton));
      await tester.pumpAndSettle();

      // Should call clearRecentSearches
      verify(() => mockSearchProvider.clearRecentSearches()).called(1);
    });

    testWidgets('recent search items have remove buttons with correct keys', (tester) async {
      when(() => mockSearchProvider.recentSearches).thenReturn(['laptop', 'phone']);

      await pumpSearchDelegate(tester);

      // Remove buttons should exist
      expect(find.byKey(WidgetKeys.searchRemoveRecent(0)), findsOneWidget);
      expect(find.byKey(WidgetKeys.searchRemoveRecent(1)), findsOneWidget);
    });

    testWidgets('tapping remove button calls removeRecentSearch with correct query', (tester) async {
      when(() => mockSearchProvider.recentSearches).thenReturn(['laptop', 'phone', 'tablet']);

      await pumpSearchDelegate(tester);

      // Tap remove button for 'phone' (index 1)
      await tester.tap(find.byKey(WidgetKeys.searchRemoveRecent(1)));
      await tester.pumpAndSettle();

      // Should call removeRecentSearch with 'phone'
      verify(() => mockSearchProvider.removeRecentSearch('phone')).called(1);
    });

    testWidgets('buildSuggestions shows suggestions when query is non-empty', (tester) async {
      final products = TestData.createProductList(3);
      when(() => mockSearchProvider.recentSearches).thenReturn([]);
      when(() => mockSearchProvider.getSuggestions(products, maxSuggestions: 8))
          .thenReturn(['Test Product 1', 'Test Product 2']);

      await pumpSearchDelegate(tester);

      // Set query
      searchDelegate.query = 'test';
      await tester.pumpAndSettle();

      // Should call getSuggestions
      verify(() => mockSearchProvider.getSuggestions(any(), maxSuggestions: 8)).called(greaterThan(0));
    });

    testWidgets('tapping a suggestion sets query and shows results', (tester) async {
      when(() => mockSearchProvider.recentSearches).thenReturn(['laptop', 'phone']);

      await pumpSearchDelegate(tester);

      // Initial query is empty
      expect(searchDelegate.query, isEmpty);

      // Tap first suggestion
      await tester.tap(find.byKey(WidgetKeys.searchSuggestion(0)));
      await tester.pumpAndSettle();

      // Query should be set to 'laptop'
      expect(searchDelegate.query, equals('laptop'));

      // Should navigate to search results
      expect(find.byType(SearchResultsPage), findsOneWidget);
    });

    testWidgets('buildResults sets query in SearchProvider', (tester) async {
      await pumpSearchDelegate(tester);

      // Set query and trigger results
      searchDelegate.query = 'laptop';
      await tester.pumpAndSettle();

      // Submit the search (simulate pressing enter or tapping search button)
      // We need to trigger showResults by entering text and submitting
      await tester.enterText(find.byType(TextField), 'laptop');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Should call setQuery
      verify(() => mockSearchProvider.setQuery('laptop')).called(greaterThan(0));
    });

    testWidgets('buildResults adds query to recent searches', (tester) async {
      await pumpSearchDelegate(tester);

      // Set query and submit
      await tester.enterText(find.byType(TextField), 'laptop');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Should call addRecentSearch
      verify(() => mockSearchProvider.addRecentSearch('laptop')).called(greaterThan(0));
    });

    testWidgets('buildResults navigates to SearchResultsPage', (tester) async {
      await pumpSearchDelegate(tester);

      // Set query and submit
      await tester.enterText(find.byType(TextField), 'laptop');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Should navigate to SearchResultsPage
      expect(find.byType(SearchResultsPage), findsOneWidget);
    });

    testWidgets('buildResults does not add empty query to recent searches', (tester) async {
      await pumpSearchDelegate(tester);

      // Submit empty query
      await tester.enterText(find.byType(TextField), '');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Should not call addRecentSearch for empty query
      verifyNever(() => mockSearchProvider.addRecentSearch(''));
    });
  });
}
