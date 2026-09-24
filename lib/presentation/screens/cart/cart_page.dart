import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/constants/widget_keys.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../presentation/providers/cart_provider.dart';
import '../../../presentation/providers/currency_provider.dart';
import '../../widgets/empty_state.dart';

/// Shopping cart page displaying added products
///
/// Shows:
/// - List of products added to cart
/// - Empty state when cart is empty
/// - Product name, price and quantity controls for each item
/// - Subtotal (unit price × quantity) in the selected currency
/// - Responsive layout (centered on larger screens)
///
/// Reads items from [CartProvider] and rebuilds whenever the cart changes.
class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cartProvider = context.watch<CartProvider>();
    final cart = cartProvider.cartItems;
    final locale = Localizations.localeOf(context).languageCode;
    final currencyCode = context.watch<CurrencyProvider>().currentCurrency;
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
                        for (final entry in cart.asMap().entries)
                          Card(
                            key: WidgetKeys.cartProductItem(
                                entry.value.id, entry.key),
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Icon(entry.value.icon),
                              ),
                              title: Text(entry.value.name),
                              subtitle: Text(
                                formatPrice(entry.value.price, currencyCode, locale),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    key: WidgetKeys.cartItemDecreaseButton(
                                        entry.value.id),
                                    icon: const Icon(
                                        Icons.remove_circle_outline),
                                    onPressed: () => cartProvider
                                        .decreaseQuantity(entry.value.id),
                                  ),
                                  Text(
                                    '${cartProvider.quantityOf(entry.value.id)}',
                                    key: WidgetKeys.cartItemQuantity(
                                        entry.value.id),
                                  ),
                                  IconButton(
                                    key: WidgetKeys.cartItemIncreaseButton(
                                        entry.value.id),
                                    icon: const Icon(Icons.add_circle_outline),
                                    onPressed: () => cartProvider
                                        .increaseQuantity(entry.value.id),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        Padding(
                          key: WidgetKeys.cartSubtotal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  l10n.cartSubtotal,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                              Text(
                                formatPrice(
                                    cartProvider.subtotal, currencyCode, locale),
                                key: WidgetKeys.cartSubtotalValue,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
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
