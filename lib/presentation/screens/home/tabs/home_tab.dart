import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/widget_keys.dart';
import '../../../../data/models/product.dart';
import '../../../../data/data_sources/local/mock_products.dart' as mock_catalog;
import '../../../../l10n/app_localizations.dart';
import '../../../providers/wishlist_provider.dart';
import '../../../providers/recently_viewed_provider.dart';
import '../../../providers/product_provider.dart';
import '../../category/category_page.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/product_card.dart';
import '../../../widgets/home_sections.dart';
import '../../../../domain/use_cases/deal_helper.dart';

/// Home tab content.
///
/// Phase 1 structural decomposition: extracted verbatim from
/// `HomePage._buildHome()`. No visual or behavioral change — the callbacks
/// below are the same `HomePage` instance methods the original code called
/// directly, now passed in so this widget has no dependency on `HomePage`'s
/// private state.
///
/// Phase 29E-1: the product catalog now comes from `ProductProvider` when
/// Supabase is configured. `ProductProvider` is only registered in
/// `main.dart` when `supabaseInitialized` is true (same SAFETY CONTRACT as
/// `AuthProvider` there — its data source eagerly resolves
/// `SupabaseService.client`), so this reads it via a NULLABLE lookup and
/// falls back to the local mock catalog when it isn't registered at all,
/// preserving the app's existing local-only-mode behavior. When the
/// provider *is* registered, its loading/error/empty states are handled
/// explicitly instead of ever passing incomplete data to the product grid.
class HomeTab extends StatelessWidget {
  final void Function(Product product, BuildContext context) onAddToCart;
  final void Function(Product product, BuildContext context) onOpenProduct;
  final void Function(Product product, BuildContext context) onToggleFavorite;

  const HomeTab({
    super.key,
    required this.onAddToCart,
    required this.onOpenProduct,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final productProvider = context.watch<ProductProvider?>();

    // Supabase not configured/initialized for this build - ProductProvider
    // isn't registered in the tree at all. Fall back to the static mock
    // catalog exactly as HomeTab behaved before this migration.
    if (productProvider == null) {
      return _HomeTabBody(
        products: mock_catalog.products,
        onAddToCart: onAddToCart,
        onOpenProduct: onOpenProduct,
        onToggleFavorite: onToggleFavorite,
      );
    }

    if (productProvider.isLoading && productProvider.products.isEmpty) {
      return const Center(
        key: WidgetKeys.homeTabLoading,
        child: CircularProgressIndicator(),
      );
    }

    if (productProvider.error != null && productProvider.products.isEmpty) {
      return EmptyState(
        key: WidgetKeys.homeTabError,
        icon: Icons.cloud_off,
        message: l10n.noResults,
      );
    }

    if (productProvider.products.isEmpty) {
      return EmptyState(
        key: WidgetKeys.homeTabEmpty,
        icon: Icons.inventory_2_outlined,
        message: l10n.noResults,
      );
    }

    return _HomeTabBody(
      products: productProvider.products,
      onAddToCart: onAddToCart,
      onOpenProduct: onOpenProduct,
      onToggleFavorite: onToggleFavorite,
    );
  }
}

/// The original HomeTab layout, unchanged, now parameterized by [products]
/// instead of reading the mock catalog's top-level `products` list
/// directly. Every reference to `products` below is this field.
class _HomeTabBody extends StatelessWidget {
  final List<Product> products;
  final void Function(Product product, BuildContext context) onAddToCart;
  final void Function(Product product, BuildContext context) onOpenProduct;
  final void Function(Product product, BuildContext context) onToggleFavorite;

  const _HomeTabBody({
    required this.products,
    required this.onAddToCart,
    required this.onOpenProduct,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final horizontalPadding = ScreenSize.getHorizontalPadding(context);
    final gridColumns = ScreenSize.getGridColumns(context);
    final isWideScreen = !ScreenSize.isMobile(context);

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      children: [
        // Hero Banner Section
        Container(
          margin: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: AppSpacing.lg,
          ),
          height: isWideScreen ? 220 : 180,
          constraints: BoxConstraints(
            maxWidth: ScreenSize.isDesktop(context) ? 1200 : double.infinity,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryBlue,
                const Color(0xFF0099FF),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              Positioned(
                right: 20,
                bottom: -30,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(isWideScreen ? AppSpacing.xxxl : AppSpacing.xxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.todaysPromotion,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Colors.white.withValues(alpha: 0.95),
                            letterSpacing: 1.2,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.findBestPrices,
                      style: (isWideScreen
                              ? Theme.of(context).textTheme.headlineLarge
                              : Theme.of(context).textTheme.headlineMedium)
                          ?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Recently Viewed Section (using HorizontalProductSection)
        Consumer<RecentlyViewedProvider>(
          builder: (context, recentlyViewedProvider, child) {
            final recentlyViewed = recentlyViewedProvider.getRecentlyViewedProducts(products);
            return HorizontalProductSection(
              sectionId: 'recently_viewed',
              title: l10n.recentlyViewedTitle,
              subtitle: l10n.continueWhereLeftOff,
              products: recentlyViewed,
              locale: locale,
              horizontalPadding: horizontalPadding,
            );
          },
        ),

        // Popular Categories Section
        PopularCategoriesSection(
          categories: [
            {'key': 'electronics', 'name': l10n.electronics, 'icon': Icons.phone_android},
            {'key': 'clothing', 'name': l10n.clothing, 'icon': Icons.checkroom},
            {'key': 'accessories', 'name': l10n.accessories, 'icon': Icons.watch},
            {'key': 'homeGoods', 'name': l10n.homeGoods, 'icon': Icons.home},
            {'key': 'sports', 'name': l10n.sports, 'icon': Icons.sports_soccer},
            {'key': 'cosmetics', 'name': l10n.cosmetics, 'icon': Icons.face},
          ],
          onCategoryTap: (categoryKey, categoryName) => () {
            final filtered = products.where((p) => p.category == categoryKey).toList();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CategoryPage(
                  title: categoryName,
                  products: filtered,
                  onAddToCart: (product) => onAddToCart(product, context),
                ),
              ),
            );
          },
          horizontalPadding: horizontalPadding,
        ),

        // Biggest Discounts Section (using DealHelper)
        HorizontalProductSection(
          sectionId: 'biggest_discounts',
          title: l10n.biggestDiscountsTitle,
          subtitle: l10n.savingsUpTo,
          products: DealHelper.getBiggestDiscounts(products)
              .take(DisplayLimits.biggestDiscountsDisplayCount)
              .toList(),
          locale: locale,
          horizontalPadding: horizontalPadding,
        ),

        // Flash Deals Section (using DealHelper)
        HorizontalProductSection(
          sectionId: 'flash_deals',
          title: l10n.flashDealsTitle,
          subtitle: l10n.limitedTimeOffers,
          products: DealHelper.getFlashDeals(products),
          locale: locale,
          horizontalPadding: horizontalPadding,
        ),

        // Today's Deals Section (using DealHelper)
        HorizontalProductSection(
          sectionId: 'todays_deals',
          title: l10n.todaysDealsTitle,
          subtitle: l10n.bestDealsNow,
          products: DealHelper.getTodaysDeals(products)
              .take(DisplayLimits.todaysDealsDisplayCount)
              .toList(),
          locale: locale,
          horizontalPadding: horizontalPadding,
        ),

        // Popular Products Section
        Padding(
          padding:
              EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, AppSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.popularProducts,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Text(
            l10n.mostLovedItems,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: ScreenSize.isDesktop(context) ? 1400 : double.infinity,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: products.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: gridColumns,
                  crossAxisSpacing: AppSpacing.lg,
                  mainAxisSpacing: AppSpacing.lg,
                  childAspectRatio: ScreenSize.isMobile(context) ? 0.60 : 0.65,
                ),
                itemBuilder: (context, index) {
                  final product = products[index];

                  return Consumer<WishlistProvider>(
                    builder: (context, wishlistProvider, child) {
                      final isFavorite =
                          wishlistProvider.isFavorite(product.id);

                      return ProductCard(
                        product: product,
                        isFavorite: isFavorite,
                        onTap: () => onOpenProduct(product, context),
                        onFavoriteToggle: () => onToggleFavorite(product, context),
                        locale: locale,
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}
