import 'package:flutter/material.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/constants/widget_keys.dart';
import '../../../data/models/product.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/empty_state.dart';

/// Shopping cart page displaying added products
///
/// Shows:
/// - List of products added to cart
/// - Empty state when cart is empty
/// - Product name, price for each item
/// - Responsive layout (centered on larger screens)
class CartPage extends StatelessWidget {
  final List<Product> cart;

  const CartPage({
    super.key,
    required this.cart,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final horizontalPadding = ScreenSize.getHorizontalPadding(context);
    final isWideScreen = !ScreenSize.isMobile(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.cart),
      ),
      body: cart.isEmpty
          ? EmptyState(
              key: WidgetKeys.cartEmptyState,
              icon: Icons.shopping_cart_outlined,
              iconSize: 100,
              message: l10n.emptyCart,
              fontSize: 20,
            )
          : ListView(
              key: WidgetKeys.cartProductList,
              padding: EdgeInsets.all(horizontalPadding),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isWideScreen ? ContentWidth.list : double.infinity,
                    ),
                    child: Column(
                      children: [
                        for (final product in cart)
                          Card(
                            key: WidgetKeys.cartProductItem(product.id),
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Icon(product.icon),
                              ),
                              title: Text(product.name),
                              subtitle: Text(
                                formatPrice(product.price, locale),
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
