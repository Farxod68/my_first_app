import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/constants/widget_keys.dart';
import '../../../../data/models/product.dart';
import '../../../../data/data_sources/local/mock_products.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../providers/wishlist_provider.dart';
import '../../../widgets/empty_state.dart';

/// Favorites (wishlist) tab content.
///
/// Phase 1 structural decomposition: extracted verbatim from
/// `HomePage._buildFavorites()`. No visual or behavioral change — the
/// callback below is the same `HomePage` instance method the original code
/// called directly, now passed in so this widget has no dependency on
/// `HomePage`'s private state.
class FavoritesTab extends StatelessWidget {
  final void Function(Product product, BuildContext context) onOpenProduct;

  const FavoritesTab({
    super.key,
    required this.onOpenProduct,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final horizontalPadding = ScreenSize.getHorizontalPadding(context);
    final isWideScreen = !ScreenSize.isMobile(context);

    return Consumer<WishlistProvider>(
      builder: (context, wishlistProvider, child) {
        final favoriteProducts =
            wishlistProvider.getFavoriteProducts(products);

        if (favoriteProducts.isEmpty) {
          return EmptyState(
            key: WidgetKeys.favoritesEmptyState,
            icon: Icons.favorite_border,
            message: l10n.noFavoriteProducts,
            textAlign: TextAlign.center,
          );
        }

        return ListView(
          key: WidgetKeys.favoritesProductList,
          padding: EdgeInsets.all(horizontalPadding),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isWideScreen ? ContentWidth.list : double.infinity,
                ),
                child: Column(
                  children: [
                    for (final product in favoriteProducts)
                      Card(
                        child: ListTile(
                          leading: Icon(product.icon),
                          title: Text(product.name),
                          subtitle: Text(formatPrice(product.price, locale)),
                          trailing: const Icon(
                            Icons.favorite,
                            color: Colors.red,
                          ),
                          onTap: () => onOpenProduct(product, context),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
