import 'package:flutter/material.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/models/product.dart';
import '../../../l10n/app_localizations.dart';

/// Product details page displaying full product information
///
/// Shows:
/// - Product image/icon
/// - Product name and category
/// - Current price and old price
/// - Discount percentage
/// - Add to cart button
/// - Responsive layout (larger on desktop)
class ProductDetailsPage extends StatelessWidget {
  final Product product;
  final VoidCallback onAddToCart;

  const ProductDetailsPage({
    super.key,
    required this.product,
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
        title: Text(l10n.product),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isWideScreen ? 800 : double.infinity,
          ),
          child: ListView(
            padding: EdgeInsets.all(horizontalPadding),
            children: [
              // Product image
              Container(
                height: isWideScreen ? 340 : 260,
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  product.icon,
                  size: isWideScreen ? 160 : 120,
                  color: Colors.deepOrange,
                ),
              ),
              SizedBox(height: isWideScreen ? 32 : 20),

              // Product name
              Text(
                product.name,
                style: TextStyle(
                  fontSize: isWideScreen ? 32 : 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Category
              Text(
                getLocalizedCategory(product.category, l10n),
                style: TextStyle(
                  fontSize: isWideScreen ? 18 : 16,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: isWideScreen ? 24 : 20),

              // Current price
              Text(
                formatPrice(product.price, locale),
                style: TextStyle(
                  fontSize: isWideScreen ? 32 : 28,
                  color: Colors.deepOrange,
                  fontWeight: FontWeight.bold,
                ),
              ),

              // Old price
              Text(
                formatPrice(product.oldPrice, locale),
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: isWideScreen ? 18 : 16,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              const SizedBox(height: 16),

              // Discount
              Text(
                l10n.discountValue(product.discount),
                style: TextStyle(
                  color: Colors.red,
                  fontSize: isWideScreen ? 20 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: isWideScreen ? 40 : 30),

              // Add to cart button
              SizedBox(
                height: isWideScreen ? 60 : 55,
                child: ElevatedButton.icon(
                  onPressed: () {
                    onAddToCart();
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.shopping_cart),
                  label: Text(
                    l10n.addToCartFull,
                    style: TextStyle(fontSize: isWideScreen ? 20 : 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
