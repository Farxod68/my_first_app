import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/constants/widget_keys.dart';
import '../../../../data/models/product.dart';
import '../../../../data/data_sources/local/mock_products.dart' as mock_catalog;
import '../../../../l10n/app_localizations.dart';
import '../../../providers/product_provider.dart';
import '../../category/category_page.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/navigation_chevron.dart';

/// Categories tab content.
///
/// Phase 1 structural decomposition: extracted verbatim from
/// `HomePage._buildCategories()`. No visual or behavioral change — the
/// callback below is the same `HomePage` instance method the original code
/// called directly, now passed in so this widget has no dependency on
/// `HomePage`'s private state.
///
/// Phase 29E-2: the product catalog used to filter each category now comes
/// from `ProductProvider` when Supabase is configured, mirroring HomeTab's
/// Phase 29E-1 migration exactly. The six category definitions themselves
/// (key/name/icon) are UI-only metadata — not backed by Supabase's
/// `categories` table — and are unchanged. `ProductProvider` is only
/// registered in `main.dart` when `supabaseInitialized` is true (same
/// SAFETY CONTRACT as `AuthProvider`/`HomeTab` there), so this reads it via
/// a NULLABLE lookup and falls back to the local mock catalog when it isn't
/// registered at all.
class CategoriesTab extends StatelessWidget {
  final void Function(Product product, BuildContext context) onAddToCart;

  const CategoriesTab({
    super.key,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final productProvider = context.watch<ProductProvider?>();

    // Supabase not configured/initialized for this build - ProductProvider
    // isn't registered in the tree at all. Fall back to the static mock
    // catalog exactly as CategoriesTab behaved before this migration.
    if (productProvider == null) {
      return _CategoriesTabBody(
        products: mock_catalog.products,
        onAddToCart: onAddToCart,
      );
    }

    if (productProvider.isLoading && productProvider.products.isEmpty) {
      return const Center(
        key: WidgetKeys.categoriesTabLoading,
        child: CircularProgressIndicator(),
      );
    }

    if (productProvider.error != null && productProvider.products.isEmpty) {
      return EmptyState(
        key: WidgetKeys.categoriesTabError,
        icon: Icons.cloud_off,
        message: l10n.noResults,
      );
    }

    if (productProvider.products.isEmpty) {
      return EmptyState(
        key: WidgetKeys.categoriesTabEmpty,
        icon: Icons.inventory_2_outlined,
        message: l10n.noResults,
      );
    }

    return _CategoriesTabBody(
      products: productProvider.products,
      onAddToCart: onAddToCart,
    );
  }
}

/// The original CategoriesTab layout, unchanged, now parameterized by
/// [products] instead of reading the mock catalog's top-level `products`
/// list directly. Every reference to `products` below is this field. The
/// six category definitions (key/name/icon) remain local UI-only metadata,
/// exactly as before.
class _CategoriesTabBody extends StatelessWidget {
  final List<Product> products;
  final void Function(Product product, BuildContext context) onAddToCart;

  const _CategoriesTabBody({
    required this.products,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final horizontalPadding = ScreenSize.getHorizontalPadding(context);
    final isWideScreen = !ScreenSize.isMobile(context);

    final categories = [
      {
        'key': 'electronics',
        'name': l10n.electronics,
        'icon': Icons.phone_android
      },
      {'key': 'clothing', 'name': l10n.clothing, 'icon': Icons.checkroom},
      {'key': 'accessories', 'name': l10n.accessories, 'icon': Icons.watch},
      {'key': 'homeGoods', 'name': l10n.homeGoods, 'icon': Icons.home},
      {'key': 'sports', 'name': l10n.sports, 'icon': Icons.sports_soccer},
      {'key': 'cosmetics', 'name': l10n.cosmetics, 'icon': Icons.face},
    ];

    return ListView(
      padding: EdgeInsets.all(horizontalPadding),
      children: [
        if (ScreenSize.isMobile(context))
          Text(
            l10n.categories,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        if (ScreenSize.isMobile(context)) const SizedBox(height: 15),
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isWideScreen ? ContentWidth.list : double.infinity,
            ),
            child: isWideScreen
                ? GridView.builder(
                    key: WidgetKeys.categoriesGrid,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: categories.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: ScreenSize.isDesktop(context) ? 3 : 2,
                      crossAxisSpacing: AppSpacing.lg,
                      mainAxisSpacing: AppSpacing.lg,
                      childAspectRatio: 1.8,
                    ),
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return Card(
                        child: InkWell(
                          borderRadius: AppRadius.largeAll,
                          onTap: () {
                            final filtered = products
                                .where((product) =>
                                    product.category == category['key'])
                                .toList();

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CategoryPage(
                                  title: category['name'] as String,
                                  products: filtered,
                                  onAddToCart: (product) =>
                                      onAddToCart(product, context),
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  child: Icon(
                                    category['icon'] as IconData,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.lg),
                                Expanded(
                                  child: Text(
                                    category['name'] as String,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const NavigationChevron(),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  )
                : Column(
                    key: WidgetKeys.categoriesGrid,
                    children: [
                      for (final category in categories)
                        Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Icon(category['icon'] as IconData),
                            ),
                            title: Text(category['name'] as String),
                            trailing:
                                const NavigationChevron(),
                            onTap: () {
                              final filtered = products
                                  .where((product) =>
                                      product.category == category['key'])
                                  .toList();

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CategoryPage(
                                    title: category['name'] as String,
                                    products: filtered,
                                    onAddToCart: (product) =>
                                      onAddToCart(product, context),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
