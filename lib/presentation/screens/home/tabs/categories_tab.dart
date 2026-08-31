import 'package:flutter/material.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/constants/widget_keys.dart';
import '../../../../data/models/product.dart';
import '../../../../data/data_sources/local/mock_products.dart';
import '../../../../l10n/app_localizations.dart';
import '../../category/category_page.dart';

/// Categories tab content.
///
/// Phase 1 structural decomposition: extracted verbatim from
/// `HomePage._buildCategories()`. No visual or behavioral change — the
/// callback below is the same `HomePage` instance method the original code
/// called directly, now passed in so this widget has no dependency on
/// `HomePage`'s private state.
class CategoriesTab extends StatelessWidget {
  final void Function(Product product, BuildContext context) onAddToCart;

  const CategoriesTab({
    super.key,
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
                                const Icon(Icons.arrow_forward_ios, size: 16),
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
                                const Icon(Icons.arrow_forward_ios, size: 16),
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
