import 'package:flutter/material.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/constants/widget_keys.dart';
import '../../../data/models/product.dart';
import '../../../l10n/app_localizations.dart';

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
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
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
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Icon(product.icon),
                              ),
                              title: Text(product.name),
                              subtitle: Text(
                                formatPrice(product.price, locale),
                              ),
                              trailing: ElevatedButton(
                                onPressed: () {
                                  onAddToCart(product);
                                },
                                child: Text(l10n.addToCart),
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
