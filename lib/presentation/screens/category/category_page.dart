import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/constants/widget_keys.dart';
import '../../../data/models/product.dart';
import '../../../l10n/app_localizations.dart';
import '../product_details/product_details_page.dart';

/// Category page displaying filtered products by category
///
/// Shows:
/// - List of products in the selected category
/// - Empty state if no products
/// - Add to cart action for each product
/// - Responsive layout (centered on larger screens)
class CategoryPage extends StatelessWidget {
  final String title;
  final List<Product> products;
  final void Function(Product) onAddToCart;

  const CategoryPage({
    super.key,
    required this.title,
    required this.products,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final horizontalPadding = ScreenSize.getHorizontalPadding(context);
    final isWideScreen = !ScreenSize.isMobile(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: products.isEmpty
          ? Center(
              key: WidgetKeys.categoryEmptyState,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
                    child: Text(
                      l10n.noCategoryProducts,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            )
          : ListView(
              key: WidgetKeys.categoryProductList,
              padding: EdgeInsets.all(horizontalPadding),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isWideScreen ? 800 : double.infinity,
                    ),
                    child: Column(
                      children: [
                        for (final product in products)
                          Card(
                            key: WidgetKeys.categoryProductItem(product.id),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ProductDetailsPage(product: product),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      child: Icon(product.icon),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    // Product name, price, and Add to Cart each
                                    // get the full row width on their own line,
                                    // so a long localized button label never
                                    // has to compete with the text for space.
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            product.name,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium,
                                          ),
                                          const SizedBox(height: AppSpacing.xs),
                                          Text(
                                            formatPrice(product.price, locale),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          const SizedBox(height: AppSpacing.sm),
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: ElevatedButton(
                                              onPressed: () {
                                                onAddToCart(product);
                                              },
                                              style: ElevatedButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: AppSpacing.lg,
                                                  vertical: 10,
                                                ),
                                              ),
                                              child: Text(
                                                l10n.addToCart,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
