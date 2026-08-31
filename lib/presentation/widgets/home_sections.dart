import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/constants/widget_keys.dart';
import '../../data/models/product.dart';
import '../../l10n/app_localizations.dart';
import '../../presentation/providers/wishlist_provider.dart';
import '../../presentation/widgets/product_card.dart';
import '../../presentation/screens/product_details/product_details_page.dart';

/// Reusable horizontal product section for Home page
///
/// Features:
/// - Section title and optional subtitle
/// - Horizontal scrollable list of products
/// - Optional "View All" button
/// - Empty state handling (returns SizedBox.shrink)
/// - Responsive spacing
/// - Consistent ProductCard design
class HorizontalProductSection extends StatelessWidget {
  final String sectionId;
  final String title;
  final String? subtitle;
  final List<Product> products;
  final String locale;
  final VoidCallback? onViewAll;
  final double horizontalPadding;

  const HorizontalProductSection({
    super.key,
    required this.sectionId,
    required this.title,
    this.subtitle,
    required this.products,
    required this.locale,
    this.onViewAll,
    this.horizontalPadding = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    // Hide section if no products
    if (products.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      key: WidgetKeys.horizontalProductSection(sectionId),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onViewAll != null)
                TextButton(
                  key: WidgetKeys.horizontalProductSectionViewAll(sectionId),
                  onPressed: onViewAll,
                  child: Text(AppLocalizations.of(context)!.viewAll),
                ),
            ],
          ),
        ),

        // Product carousel
        SizedBox(
          height: 280,
          child: ListView.builder(
            key: WidgetKeys.horizontalProductSectionList(sectionId),
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Container(
                width: 180,
                margin: EdgeInsets.only(right: index < products.length - 1 ? AppSpacing.lg : 0),
                child: Consumer<WishlistProvider>(
                  builder: (context, wishlistProvider, child) {
                    final isFavorite = wishlistProvider.isFavorite(product.id);
                    return ProductCard(
                      product: product,
                      isFavorite: isFavorite,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductDetailsPage(product: product),
                          ),
                        );
                      },
                      onFavoriteToggle: () {
                        wishlistProvider.toggleFavorite(product.id);
                      },
                      locale: locale,
                    );
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}

/// Horizontal category section for Home page
///
/// Features:
/// - Scrollable category chips/cards
/// - Category icon and name
/// - Optional product count
/// - Navigation to category results
/// - Responsive design
class PopularCategoriesSection extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final VoidCallback Function(String categoryKey, String categoryName) onCategoryTap;
  final double horizontalPadding;

  const PopularCategoriesSection({
    super.key,
    required this.categories,
    required this.onCategoryTap,
    this.horizontalPadding = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      key: WidgetKeys.popularCategoriesSection,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, AppSpacing.md),
          child: Text(
            l10n.categories,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),

        // Category chips
        SizedBox(
          height: 100,
          child: ListView.builder(
            key: WidgetKeys.popularCategoriesList,
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final categoryKey = category['key'] as String;
              final categoryName = category['name'] as String;
              final categoryIcon = category['icon'] as IconData;

              return Container(
                width: 100,
                margin: EdgeInsets.only(right: index < categories.length - 1 ? AppSpacing.md : 0),
                child: InkWell(
                  key: WidgetKeys.categoryItem(categoryKey),
                  onTap: onCategoryTap(categoryKey, categoryName),
                  borderRadius: AppRadius.smallAll,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: AppRadius.smallAll,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          categoryIcon,
                          size: 32,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          categoryName,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}

/// Section spacing utility
class SectionSpacing extends StatelessWidget {
  const SectionSpacing({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: AppSpacing.xxl);
  }
}
