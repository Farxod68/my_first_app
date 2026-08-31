import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/product.dart';
import '../../../data/data_sources/local/mock_products.dart';
import '../../../l10n/app_localizations.dart';
import '../../../presentation/providers/search_provider.dart';
import '../../../presentation/widgets/favoritable_product_card.dart';
import '../../../presentation/screens/product_details/product_details_page.dart';

/// Search Results Page with Filters and Sorting
///
/// Displays filtered and sorted product results with:
/// - Search query display
/// - Active filters chips
/// - Sort dropdown
/// - Filter button (opens filter sheet/dialog)
/// - Product grid with existing ProductCard
/// - Empty states
/// - Result count
///
/// Fully responsive with mobile bottom sheet and desktop sidebar (simplified)
class SearchResultsPage extends StatelessWidget {
  const SearchResultsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.searchResults),
        actions: [
          // Sort button
          _SortButton(),
        ],
      ),
      body: Consumer<SearchProvider>(
        builder: (context, searchProvider, child) {
          final results = searchProvider.searchAndFilter(products);

          return Column(
            children: [
              // Search query and filters header
              _SearchHeader(results: results),

              // Results grid
              Expanded(
                child: results.isEmpty
                    ? _EmptyState()
                    : _ResultsGrid(results: results, locale: locale),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFilters(context),
        icon: const Icon(Icons.filter_list),
        label: Consumer<SearchProvider>(
          builder: (context, searchProvider, child) {
            final filterCount = searchProvider.filters.activeFilterCount;
            return Text(
              filterCount > 0
                  ? AppLocalizations.of(context)!.activeFilters(filterCount)
                  : AppLocalizations.of(context)!.filters,
            );
          },
        ),
      ),
    );
  }

  void _showFilters(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FilterSheet(),
    );
  }
}

class _SearchHeader extends StatelessWidget {
  final List<Product> results;

  const _SearchHeader({required this.results});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final searchProvider = context.watch<SearchProvider>();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Query display
          if (searchProvider.hasSearch)
            Text(
              l10n.resultsFor(searchProvider.query.raw),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),

          const SizedBox(height: AppSpacing.sm),

          // Result count
          Text(
            l10n.productCount(results.length),
            style: TextStyle(color: Colors.grey.shade600),
          ),

          // Active filters chips
          if (searchProvider.hasFilters) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: _buildFilterChips(context, searchProvider),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildFilterChips(BuildContext context, SearchProvider searchProvider) {
    final l10n = AppLocalizations.of(context)!;
    final chips = <Widget>[];
    final filters = searchProvider.filters;

    if (filters.category != null) {
      chips.add(_FilterChip(
        label: getLocalizedCategory(filters.category!, l10n),
        onRemove: () => searchProvider.setCategoryFilter(null),
      ));
    }

    if (filters.brand != null) {
      chips.add(_FilterChip(
        label: filters.brand!,
        onRemove: () => searchProvider.setBrandFilter(null),
      ));
    }

    if (filters.minRating != null) {
      chips.add(_FilterChip(
        label: l10n.starsAndUp(filters.minRating!.toInt()),
        onRemove: () => searchProvider.setRatingFilter(null),
      ));
    }

    if (filters.minDiscount != null) {
      chips.add(_FilterChip(
        label: l10n.discountAndUp(filters.minDiscount!),
        onRemove: () => searchProvider.setDiscountFilter(null),
      ));
    }

    if (filters.inStockOnly == true) {
      chips.add(_FilterChip(
        label: l10n.inStockOnly,
        onRemove: () => searchProvider.setInStockOnlyFilter(null),
      ));
    }

    if (filters.dealsOnly == true) {
      chips.add(_FilterChip(
        label: l10n.dealsOnly,
        onRemove: () => searchProvider.setDealsOnlyFilter(null),
      ));
    }

    // Clear all button
    if (chips.isNotEmpty) {
      chips.add(TextButton.icon(
        onPressed: () => searchProvider.clearFilters(),
        icon: const Icon(Icons.clear_all, size: 18),
        label: Text(l10n.clearFilters),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        ),
      ));
    }

    return chips;
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _FilterChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      deleteIcon: const Icon(Icons.close, size: 18),
      onDeleted: onRemove,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
    );
  }
}

class _ResultsGrid extends StatelessWidget {
  final List<Product> results;
  final String locale;

  const _ResultsGrid({required this.results, required this.locale});

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = ScreenSize.getHorizontalPadding(context);
    final gridColumns = ScreenSize.getGridColumns(context);

    return GridView.builder(
      padding: EdgeInsets.all(horizontalPadding),
      itemCount: results.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridColumns,
        crossAxisSpacing: AppSpacing.lg,
        mainAxisSpacing: AppSpacing.lg,
        childAspectRatio: ScreenSize.isMobile(context) ? 0.60 : 0.65,
      ),
      itemBuilder: (context, index) {
        final product = results[index];
        return FavoritableProductCard.build(
          product: product,
          locale: locale,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetailsPage(product: product),
              ),
            );
          },
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final searchProvider = context.watch<SearchProvider>();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              searchProvider.hasSearch
                  ? l10n.noResultsFor(searchProvider.query.raw)
                  : l10n.noResults,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.tryDifferentSearch,
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            if (searchProvider.hasFilters) ...[
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                onPressed: () => searchProvider.clearFilters(),
                icon: const Icon(Icons.clear_all),
                label: Text(l10n.clearFilters),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final searchProvider = context.watch<SearchProvider>();

    return PopupMenuButton<ProductSort>(
      icon: const Icon(Icons.sort),
      onSelected: (sort) => searchProvider.setSortBy(sort),
      itemBuilder: (context) => [
        _buildSortItem(ProductSort.relevance, l10n.relevance, searchProvider.sortBy),
        _buildSortItem(ProductSort.priceLowToHigh, l10n.priceLowToHigh, searchProvider.sortBy),
        _buildSortItem(ProductSort.priceHighToLow, l10n.priceHighToLow, searchProvider.sortBy),
        _buildSortItem(ProductSort.rating, l10n.rating, searchProvider.sortBy),
        _buildSortItem(ProductSort.newest, l10n.newest, searchProvider.sortBy),
        _buildSortItem(ProductSort.discount, l10n.discount, searchProvider.sortBy),
        _buildSortItem(ProductSort.popularity, l10n.popularity, searchProvider.sortBy),
      ],
    );
  }

  PopupMenuItem<ProductSort> _buildSortItem(ProductSort value, String label, ProductSort current) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          if (current == value)
            const Icon(Icons.check, size: 18)
          else
            const SizedBox(width: 18),
          const SizedBox(width: AppSpacing.sm),
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

class _FilterSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Consumer<SearchProvider>(
          builder: (context, searchProvider, child) {
            return Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        l10n.filters,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      if (searchProvider.hasFilters)
                        TextButton(
                          onPressed: () => searchProvider.clearFilters(),
                          child: Text(l10n.clearFilters),
                        ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // Filter options
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      // Category filter
                      _FilterSection(
                        title: l10n.category,
                        child: _CategoryFilter(),
                      ),
                      const Divider(height: AppSpacing.xxxl),

                      // Rating filter
                      _FilterSection(
                        title: l10n.minRating,
                        child: _RatingFilter(),
                      ),
                      const Divider(height: AppSpacing.xxxl),

                      // Discount filter
                      _FilterSection(
                        title: l10n.minDiscount,
                        child: _DiscountFilter(),
                      ),
                      const Divider(height: AppSpacing.xxxl),

                      // Availability toggles
                      _FilterSection(
                        title: l10n.availability,
                        child: Column(
                          children: [
                            SwitchListTile(
                              title: Text(l10n.inStockOnly),
                              value: searchProvider.filters.inStockOnly ?? false,
                              onChanged: (value) => searchProvider.setInStockOnlyFilter(value ? true : null),
                            ),
                            SwitchListTile(
                              title: Text(l10n.dealsOnly),
                              value: searchProvider.filters.dealsOnly ?? false,
                              onChanged: (value) => searchProvider.setDealsOnlyFilter(value ? true : null),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Apply button
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          l10n.applyFilters,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _FilterSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _FilterSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.md),
        child,
      ],
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final searchProvider = context.watch<SearchProvider>();

    final categories = [
      null, // All categories
      CategoryKeys.electronics,
      CategoryKeys.clothing,
      CategoryKeys.accessories,
      CategoryKeys.homeGoods,
      CategoryKeys.sports,
      CategoryKeys.cosmetics,
    ];

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: categories.map((category) {
        final isSelected = searchProvider.filters.category == category;
        final label = category == null
            ? l10n.allCategories
            : getLocalizedCategory(category, l10n);

        return ChoiceChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (selected) {
            searchProvider.setCategoryFilter(selected ? category : null);
          },
        );
      }).toList(),
    );
  }
}

class _RatingFilter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final searchProvider = context.watch<SearchProvider>();

    final ratings = [null, 4.0, 3.0, 2.0];

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: ratings.map((rating) {
        final isSelected = searchProvider.filters.minRating == rating;
        final label = rating == null
            ? l10n.allCategories
            : l10n.starsAndUp(rating.toInt());

        return ChoiceChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (selected) {
            searchProvider.setRatingFilter(selected ? rating : null);
          },
        );
      }).toList(),
    );
  }
}

class _DiscountFilter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final searchProvider = context.watch<SearchProvider>();

    final discounts = [null, 50, 30, 20, 10];

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: discounts.map((discount) {
        final isSelected = searchProvider.filters.minDiscount == discount;
        final label = discount == null
            ? l10n.allCategories
            : l10n.discountAndUp(discount);

        return ChoiceChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (selected) {
            searchProvider.setDiscountFilter(selected ? discount : null);
          },
        );
      }).toList(),
    );
  }
}
