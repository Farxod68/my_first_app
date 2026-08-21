import 'package:flutter/material.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/models/product.dart';
import '../../../l10n/app_localizations.dart';

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
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 100,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.emptyCart,
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )
          : ListView(
              padding: EdgeInsets.all(horizontalPadding),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isWideScreen ? 800 : double.infinity,
                    ),
                    child: Column(
                      children: [
                        for (final product in cart)
                          Card(
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
