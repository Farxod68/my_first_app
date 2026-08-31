import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/constants/widget_keys.dart';
import '../providers/cart_provider.dart';
import '../screens/cart/cart_page.dart';
import 'product_search_delegate.dart';

/// Shared HomePage AppBar actions (search button + cart button with badge).
///
/// `HomePage` renders this exact widget tree twice - once for the
/// desktop/tablet AppBar (inside the `NavigationRail` layout) and once for
/// the mobile AppBar (above the bottom `NavigationBar`). Both surrounding
/// `Scaffold`/`AppBar` shells differ (desktop shows the current tab's
/// title; mobile always shows the app title), so only this shared actions
/// fragment is factored out.
///
/// Returns the list of widgets to spread directly into `AppBar.actions`
/// (not a wrapping widget), so the resulting widget tree is unchanged from
/// what each call site rendered before - no extra `Row`/wrapper is
/// inserted between the `AppBar` and these action widgets.
class HomeAppBarActions {
  HomeAppBarActions._();

  /// [trailingGap] preserves the one real difference between the two
  /// original call sites: the desktop AppBar had an extra
  /// `SizedBox(width: AppSpacing.sm)` after the cart button that the
  /// mobile AppBar did not.
  static List<Widget> build(BuildContext context, {bool trailingGap = false}) {
    return [
      IconButton(
        key: WidgetKeys.homeSearchButton,
        onPressed: () {
          showSearch(
            context: context,
            delegate: ProductSearchDelegate(),
          );
        },
        icon: const Icon(Icons.search),
      ),
      Consumer<CartProvider>(
        builder: (context, cartProvider, child) => Stack(
          children: [
            IconButton(
              key: WidgetKeys.homeCartButton,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CartPage(cart: cartProvider.cartItems),
                  ),
                );
              },
              icon: const Icon(Icons.shopping_cart_outlined),
            ),
            if (cartProvider.itemCount > 0)
              Positioned(
                right: AppSpacing.xs,
                top: AppSpacing.xs,
                child: CircleAvatar(
                  key: WidgetKeys.homeCartBadge,
                  radius: 9,
                  backgroundColor: Colors.red,
                  child: Text(
                    '${cartProvider.itemCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      if (trailingGap) const SizedBox(width: AppSpacing.sm),
    ];
  }
}
