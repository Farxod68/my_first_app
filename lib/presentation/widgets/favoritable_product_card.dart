import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/product.dart';
import '../providers/wishlist_provider.dart';
import 'product_card.dart';

/// Shared `Consumer<WishlistProvider>` + `ProductCard` wiring for TOPBUY DEALS.
///
/// Consolidates the boilerplate previously duplicated identically across
/// `home_sections.dart` (`HorizontalProductSection`),
/// `search_results_page.dart` (`_ResultsGrid`), and
/// `product_details_page.dart` (`_buildRelatedProducts`): wrap the product
/// in a `Consumer<WishlistProvider>`, look up `isFavorite`, then build a
/// `ProductCard` whose favorite button calls
/// `wishlistProvider.toggleFavorite(product.id)` - identical in all three.
/// `onTap` still varies per call site (different navigation targets, and
/// `product_details_page.dart` uses `pushReplacement` instead of `push`), so
/// it remains a required parameter passed straight through unchanged.
///
/// Deliberately NOT used by `home_tab.dart`: that call site routes
/// favorite-toggling through a parent-supplied callback
/// (`HomeTab.onToggleFavorite` -> `HomePage.toggleFavorite`) instead of
/// calling the Consumer's own `wishlistProvider` directly, so it isn't the
/// same duplication and is left as-is.
///
/// Returns the `Consumer<WishlistProvider>` widget directly (not a wrapping
/// widget), so the resulting widget tree is unchanged from what each call
/// site rendered before - no extra layer is inserted before `ProductCard`.
class FavoritableProductCard {
  FavoritableProductCard._();

  static Widget build({
    required Product product,
    required String locale,
    required VoidCallback onTap,
  }) {
    return Consumer<WishlistProvider>(
      builder: (context, wishlistProvider, child) {
        final isFavorite = wishlistProvider.isFavorite(product.id);
        return ProductCard(
          product: product,
          isFavorite: isFavorite,
          onTap: onTap,
          onFavoriteToggle: () {
            wishlistProvider.toggleFavorite(product.id);
          },
          locale: locale,
        );
      },
    );
  }
}
