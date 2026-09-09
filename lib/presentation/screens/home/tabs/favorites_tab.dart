import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/constants/widget_keys.dart';
import '../../../../data/models/product.dart';
import '../../../../data/data_sources/local/mock_products.dart' as mock_catalog;
import '../../../../l10n/app_localizations.dart';
import '../../../providers/currency_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/wishlist_provider.dart';
import '../../../widgets/empty_state.dart';

/// Favorites (wishlist) tab content.
///
/// Phase 1 structural decomposition: extracted verbatim from
/// `HomePage._buildFavorites()`. No visual or behavioral change — the
/// callback below is the same `HomePage` instance method the original code
/// called directly, now passed in so this widget has no dependency on
/// `HomePage`'s private state.
///
/// Phase 29E-5: the catalog scanned by `WishlistProvider.getFavoriteProducts`
/// now comes from `ProductProvider` when Supabase is configured, mirroring
/// HomeTab's (29E-1) and CategoriesTab's (29E-2) migrations. `ProductProvider`
/// is only registered in `main.dart` when `supabaseInitialized` is true, so
/// this reads it via a NULLABLE lookup and falls back to the local mock
/// catalog when it isn't registered at all. A distinct loading/error state is
/// shown so a catalog that hasn't loaded yet (or failed to load) is never
/// mistaken for the existing "no favorite products" empty state below.
class FavoritesTab extends StatelessWidget {
  final void Function(Product product, BuildContext context) onOpenProduct;

  const FavoritesTab({
    super.key,
    required this.onOpenProduct,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final productProvider = context.watch<ProductProvider?>();

    if (productProvider != null &&
        productProvider.isLoading &&
        productProvider.products.isEmpty) {
      return const Center(
        key: WidgetKeys.favoritesTabLoading,
        child: CircularProgressIndicator(),
      );
    }

    if (productProvider != null &&
        productProvider.error != null &&
        productProvider.products.isEmpty) {
      return EmptyState(
        key: WidgetKeys.favoritesTabError,
        icon: Icons.cloud_off,
        message: l10n.noResults,
      );
    }

    // Supabase not configured/initialized for this build (productProvider is
    // null), or ProductProvider hasn't produced any error/loading state to
    // special-case above - either way, resolve the catalog to scan for
    // favorites: ProductProvider's when registered, the local mock catalog
    // otherwise (preserving FavoritesTab's pre-migration behavior).
    final catalog = productProvider?.products ?? mock_catalog.products;

    return _FavoritesTabBody(catalog: catalog, onOpenProduct: onOpenProduct);
  }
}

/// The original FavoritesTab body, unchanged, now parameterized by [catalog]
/// instead of reading the mock catalog's top-level `products` list directly.
class _FavoritesTabBody extends StatelessWidget {
  final List<Product> catalog;
  final void Function(Product product, BuildContext context) onOpenProduct;

  const _FavoritesTabBody({
    required this.catalog,
    required this.onOpenProduct,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final currencyCode = context.watch<CurrencyProvider>().currentCurrency;
    final horizontalPadding = ScreenSize.getHorizontalPadding(context);
    final isWideScreen = !ScreenSize.isMobile(context);

    return Consumer<WishlistProvider>(
      builder: (context, wishlistProvider, child) {
        final favoriteProducts =
            wishlistProvider.getFavoriteProducts(catalog);

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
                          subtitle: Text(formatPrice(product.price, currencyCode, locale)),
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
