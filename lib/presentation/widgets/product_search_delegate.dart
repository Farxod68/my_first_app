import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/constants/widget_keys.dart';
import '../../data/models/product.dart';
import '../../data/data_sources/local/mock_products.dart' as mock_catalog;
import '../../l10n/app_localizations.dart';
import '../../presentation/providers/product_provider.dart';
import '../../presentation/providers/search_provider.dart';
import '../../presentation/screens/search/search_results_page.dart';

/// Enhanced search delegate with SearchProvider integration
///
/// Provides:
/// - Search with SearchProvider integration
/// - Recent searches display
/// - Search suggestions
/// - Navigation to full search results page
/// - Direct product navigation
///
/// Phase 29E-5: the catalog scanned by `SearchProvider.getSuggestions` in
/// [buildSuggestions] now comes from `ProductProvider` when Supabase is
/// configured, mirroring HomeTab's (29E-1), CategoriesTab's (29E-2),
/// SearchResultsPage's (29E-3), and FavoritesTab's (29E-5) migrations.
/// `ProductProvider` is registered above `MaterialApp` in main.dart, so it's
/// reachable from the `BuildContext` this delegate's build methods receive
/// via `showSearch()`'s route, same as any other screen. [buildResults]
/// itself doesn't read the catalog - it only forwards the query to
/// `SearchResultsPage`, already migrated in 29E-3.
class ProductSearchDelegate extends SearchDelegate<Product?> {
  ProductSearchDelegate();

  @override
  String get searchFieldLabel => 'Search products, brands, deals...';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          key: WidgetKeys.searchClearButton,
          onPressed: () {
            query = '';
          },
          icon: const Icon(Icons.clear),
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      key: WidgetKeys.searchBackButton,
      onPressed: () {
        close(context, null);
      },
      icon: const Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final searchProvider = context.read<SearchProvider>();
    searchProvider.setQuery(query);
    if (query.isNotEmpty) {
      searchProvider.addRecentSearch(query);
    }

    // Navigate to full results page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const SearchResultsPage(),
        ),
      );
    });

    return const SizedBox.shrink();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final productProvider = context.watch<ProductProvider?>();

    // Supabase not configured/initialized for this build - ProductProvider
    // isn't registered in the tree at all. Fall back to the static mock
    // catalog exactly as this delegate behaved before this migration. While
    // ProductProvider is registered but still loading, or has errored,
    // `products` is empty - `getSuggestions` on an empty catalog safely
    // yields no suggestions rather than crashing.
    final catalog = productProvider == null
        ? mock_catalog.products
        : productProvider.products;

    return Consumer<SearchProvider>(
      builder: (context, searchProvider, child) {
        final suggestions = query.isEmpty
            ? searchProvider.recentSearches
            : searchProvider.getSuggestions(catalog, maxSuggestions: 8);

        if (suggestions.isEmpty && query.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxxl),
              child: Text(
                l10n.searchHint,
                style: TextStyle(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView(
          key: WidgetKeys.searchSuggestionsList,
          children: [
            // Section header
            if (query.isEmpty && suggestions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
                child: Row(
                  children: [
                    Text(
                      l10n.recentSearchesLabel,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const Spacer(),
                    if (suggestions.isNotEmpty)
                      TextButton(
                        key: WidgetKeys.searchClearHistoryButton,
                        onPressed: () => searchProvider.clearRecentSearches(),
                        child: Text(l10n.clearSearchHistory),
                      ),
                  ],
                ),
              ),

            // Suggestions
            ...suggestions.asMap().entries.map((entry) {
              final index = entry.key;
              final suggestion = entry.value;
              return ListTile(
                key: WidgetKeys.searchSuggestion(index),
                leading: Icon(
                  query.isEmpty ? Icons.history : Icons.search,
                  color: Colors.grey.shade600,
                ),
                title: Text(suggestion),
                onTap: () {
                  query = suggestion;
                  showResults(context);
                },
                trailing: query.isEmpty
                    ? IconButton(
                        key: WidgetKeys.searchRemoveRecent(index),
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => searchProvider.removeRecentSearch(suggestion),
                      )
                    : null,
              );
            }),
          ],
        );
      },
    );
  }
}

