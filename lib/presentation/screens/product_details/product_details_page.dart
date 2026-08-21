import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/product.dart';
import '../../../data/data_sources/local/mock_products.dart';
import '../../../l10n/app_localizations.dart';
import '../../../presentation/providers/cart_provider.dart';
import '../../../presentation/providers/wishlist_provider.dart';
import '../../../presentation/providers/recently_viewed_provider.dart';
import '../../../presentation/widgets/product_card.dart';

/// Premium Product Details Page for TOPBUY DEALS
///
/// Displays comprehensive product information including:
/// - Image gallery with product visualization
/// - Product title, brand, rating, and reviews
/// - Pricing with discounts and deal badges
/// - Stock status and availability
/// - Detailed description
/// - Key features list
/// - Technical specifications
/// - Shipping information
/// - Seller information
/// - Add to cart and Buy Now actions
/// - Wishlist toggle
/// - Share functionality
/// - Related products recommendations
/// - Recently viewed tracking
///
/// Fully responsive with optimized layouts for mobile, tablet, and desktop
class ProductDetailsPage extends StatefulWidget {
  final Product product;

  const ProductDetailsPage({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {

  @override
  void initState() {
    super.initState();
    // Track this product as recently viewed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecentlyViewedProvider>().addProduct(widget.product.id);
    });
  }

  void _addToCart() {
    context.read<CartProvider>().addToCart(widget.product);
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.addedToCart(widget.product.name)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _buyNow() {
    // Add to cart and navigate to cart page
    context.read<CartProvider>().addToCart(widget.product);
    Navigator.pop(context); // Go back to previous screen
    // In a real app, would navigate to checkout
  }

  void _toggleWishlist() {
    final wishlistProvider = context.read<WishlistProvider>();
    wishlistProvider.toggleFavorite(widget.product.name);

    final l10n = AppLocalizations.of(context)!;
    final isFavorite = wishlistProvider.isFavorite(widget.product.name);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFavorite ? l10n.addedToWishlist : l10n.removedFromWishlist,
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _share() {
    // In a real app, would use share plugin
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality would be implemented here'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final isWideScreen = !ScreenSize.isMobile(context);
    final isDesktop = ScreenSize.isDesktop(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.productDetails),
        actions: [
          // Share button
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: _share,
            tooltip: l10n.share,
          ),
          // Wishlist button
          Consumer<WishlistProvider>(
            builder: (context, wishlistProvider, child) {
              final isFavorite = wishlistProvider.isFavorite(widget.product.name);
              return IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : null,
                ),
                onPressed: _toggleWishlist,
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isDesktop ? _buildDesktopLayout(l10n, locale) : _buildMobileTabletLayout(l10n, locale, isWideScreen),
      // Sticky bottom bar for mobile/tablet with purchase actions
      bottomNavigationBar: !isDesktop ? _buildStickyBottomBar(l10n, locale) : null,
    );
  }

  /// Desktop layout with side-by-side image gallery and product info
  Widget _buildDesktopLayout(AppLocalizations l10n, String locale) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: Image gallery
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _buildImageGallery(true),
          ),
        ),
        // Right: Product information
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProductHeader(l10n, locale),
                const SizedBox(height: 24),
                _buildPurchaseActions(l10n, locale),
                const Divider(height: 40),
                _buildProductSections(l10n, locale),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Mobile/Tablet layout with scrollable content
  Widget _buildMobileTabletLayout(AppLocalizations l10n, String locale, bool isWideScreen) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image gallery
          _buildImageGallery(false),

          // Product information
          Padding(
            padding: EdgeInsets.all(isWideScreen ? 24 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProductHeader(l10n, locale),
                const SizedBox(height: 16),
                _buildProductSections(l10n, locale),
                const SizedBox(height: 80), // Space for sticky bottom bar
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Image gallery with product visualization
  Widget _buildImageGallery(bool isDesktop) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: isDesktop ? 600 : double.infinity,
      ),
      child: Column(
        children: [
          // Main image
          Container(
            height: isDesktop ? 500 : 300,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF0066CC).withValues(alpha: 0.05),
                  const Color(0xFF00C853).withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Center(
              child: Icon(
                widget.product.icon,
                size: isDesktop ? 200 : 120,
                color: const Color(0xFF0066CC),
              ),
            ),
          ),
          // In a real app, would show thumbnail navigation here
          // For now, just show the icon as placeholder
        ],
      ),
    );
  }

  /// Product header with title, brand, rating, price
  Widget _buildProductHeader(AppLocalizations l10n, String locale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Brand
        if (widget.product.brand != null) ...[
          Text(
            widget.product.brand!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
        ],

        // Product title
        Text(
          widget.product.name,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),

        // Subtitle
        if (widget.product.subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.product.subtitle!,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
          ),
        ],

        const SizedBox(height: 12),

        // Rating and reviews
        if (widget.product.hasRating)
          Wrap(
            children: [
              Wrap(
                children: List.generate(5, (index) {
                  return Icon(
                    index < widget.product.rating.floor()
                        ? Icons.star
                        : (index < widget.product.rating ? Icons.star_half : Icons.star_border),
                    color: Colors.amber.shade700,
                    size: 20,
                  );
                }),
              ),
              const SizedBox(width: 8),
              Text(
                widget.product.rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (widget.product.hasReviews) ...[
                const SizedBox(width: 8),
                Text(
                  l10n.reviewsCount(widget.product.reviewCount),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ],
          ),

        const SizedBox(height: 16),

        // Pricing section
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            // Current price
            Text(
              formatPrice(widget.product.price, locale),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0066CC),
              ),
            ),
            const SizedBox(width: 12),

            // Old price
            if (widget.product.discount > 0) ...[
              Text(
                formatPrice(widget.product.oldPrice, locale),
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade500,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              const SizedBox(width: 8),

              // Discount badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  l10n.discountPercent(widget.product.discount),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ],
        ),

        const SizedBox(height: 12),

        // Deal badges
        if (widget.product.badges.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.product.badges.take(3).map((badge) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _getBadgeColor(badge).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _getBadgeColor(badge),
                    width: 1,
                  ),
                ),
                child: Text(
                  _getLocalizedBadge(badge, l10n),
                  style: TextStyle(
                    color: _getBadgeColor(badge),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              );
            }).toList(),
          ),

        const SizedBox(height: 16),

        // Stock status
        _buildStockStatus(l10n),
      ],
    );
  }

  /// Stock status indicator
  Widget _buildStockStatus(AppLocalizations l10n) {
    if (widget.product.isOutOfStock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cancel, size: 18, color: Colors.red.shade700),
            const SizedBox(width: 8),
            Text(
              l10n.outOfStock,
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    } else if (widget.product.isLowStock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber, size: 18, color: Colors.orange.shade700),
            const SizedBox(width: 8),
            Text(
              l10n.onlyLeft(widget.product.stock),
              style: TextStyle(
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 18, color: Colors.green.shade700),
            const SizedBox(width: 8),
            Text(
              l10n.inStock,
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '• ${l10n.unitsInStock(widget.product.stock)}',
              style: TextStyle(
                color: Colors.green.shade600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }
  }

  /// Purchase actions (Add to Cart, Buy Now) - for desktop
  Widget _buildPurchaseActions(AppLocalizations l10n, String locale) {
    final isOutOfStock = widget.product.isOutOfStock;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Add to Cart button
        SizedBox(
          height: 56,
          child: ElevatedButton.icon(
            onPressed: isOutOfStock ? null : _addToCart,
            icon: const Icon(Icons.shopping_cart),
            label: Text(
              l10n.addToCartFull,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Buy Now button
        SizedBox(
          height: 56,
          child: OutlinedButton.icon(
            onPressed: isOutOfStock ? null : _buyNow,
            icon: const Icon(Icons.flash_on),
            label: Text(
              l10n.buyNow,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(
                width: 2,
                color: isOutOfStock ? Colors.grey : Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),

        // Free shipping indicator
        if (widget.product.hasFreeShipping && !isOutOfStock) ...[
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              Icon(Icons.local_shipping, size: 18, color: Colors.green.shade700),
              const SizedBox(width: 6),
              Text(
                l10n.freeShipping,
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Sticky bottom bar for mobile/tablet
  Widget _buildStickyBottomBar(AppLocalizations l10n, String locale) {
    final isOutOfStock = widget.product.isOutOfStock;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Price
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatPrice(widget.product.price, locale),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0066CC),
                    ),
                  ),
                  if (widget.product.discount > 0)
                    Text(
                      formatPrice(widget.product.oldPrice, locale),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Add to Cart button
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: isOutOfStock ? null : _addToCart,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    l10n.addToCartFull,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Product information sections
  Widget _buildProductSections(AppLocalizations l10n, String locale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Description
        if (widget.product.description != null) ...[
          _buildSectionTitle(l10n.description),
          const SizedBox(height: 12),
          Text(
            widget.product.description!,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Key Features
        if (widget.product.features != null && widget.product.features!.isNotEmpty) ...[
          _buildSectionTitle(l10n.keyFeatures),
          const SizedBox(height: 12),
          ...widget.product.features!.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 20,
                      color: Colors.green.shade600,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        feature,
                        style: const TextStyle(fontSize: 15, height: 1.5),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 24),
        ],

        // Specifications
        if (widget.product.specifications != null && widget.product.specifications!.isNotEmpty) ...[
          _buildSectionTitle(l10n.specifications),
          const SizedBox(height: 12),
          _buildSpecificationsTable(),
          const SizedBox(height: 24),
        ],

        // Shipping Information
        _buildSectionTitle(l10n.shippingInfo),
        const SizedBox(height: 12),
        _buildShippingInfo(l10n),
        const SizedBox(height: 24),

        // Seller Information
        if (widget.product.seller != null) ...[
          _buildSectionTitle(l10n.soldBy),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF0066CC).withValues(alpha: 0.1),
                  child: const Icon(Icons.store, color: Color(0xFF0066CC)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.product.seller!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Related Products
        _buildRelatedProducts(l10n, locale),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSpecificationsTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: widget.product.specifications!.entries.map((entry) {
          final isLast = entry == widget.product.specifications!.entries.last;
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: isLast
                  ? null
                  : Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    entry.key,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    entry.value,
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildShippingInfo(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            children: [
              Icon(Icons.local_shipping, color: Colors.blue.shade700),
              const SizedBox(width: 12),
              Text(
                l10n.deliveryIn('3-5'),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          if (widget.product.hasFreeShipping) ...[
            const SizedBox(height: 8),
            Wrap(
              children: [
                Icon(Icons.check_circle, size: 18, color: Colors.green.shade600),
                const SizedBox(width: 12),
                Text(
                  l10n.freeShipping,
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRelatedProducts(AppLocalizations l10n, String locale) {
    // Get products from same category, excluding current product
    final relatedProducts = products
        .where((p) => p.category == widget.product.category && p.id != widget.product.id)
        .take(4)
        .toList();

    if (relatedProducts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(l10n.relatedProducts),
        const SizedBox(height: 16),
        SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: relatedProducts.length,
            itemBuilder: (context, index) {
              final product = relatedProducts[index];
              return Container(
                width: 180,
                margin: EdgeInsets.only(
                  right: index < relatedProducts.length - 1 ? 16 : 0,
                ),
                child: Consumer<WishlistProvider>(
                  builder: (context, wishlistProvider, child) {
                    final isFavorite = wishlistProvider.isFavorite(product.name);
                    return ProductCard(
                      product: product,
                      isFavorite: isFavorite,
                      onTap: () {
                        // Navigate to this product's details
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductDetailsPage(product: product),
                          ),
                        );
                      },
                      onFavoriteToggle: () {
                        wishlistProvider.toggleFavorite(product.name);
                      },
                      locale: locale,
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Color _getBadgeColor(String badge) {
    switch (badge) {
      case DealBadges.bestSeller:
        return const Color(0xFF1976D2);
      case DealBadges.trending:
        return const Color(0xFFE91E63);
      case DealBadges.flashSale:
        return const Color(0xFFFF6F00);
      case DealBadges.limitedTime:
        return const Color(0xFFF57C00);
      case DealBadges.priceDrop:
        return const Color(0xFF388E3C);
      case DealBadges.newArrival:
        return const Color(0xFF7B1FA2);
      case DealBadges.freeShipping:
        return const Color(0xFF00796B);
      default:
        return const Color(0xFF616161);
    }
  }

  String _getLocalizedBadge(String badge, AppLocalizations l10n) {
    switch (badge) {
      case DealBadges.bestSeller:
        return l10n.bestSeller;
      case DealBadges.trending:
        return l10n.trending;
      case DealBadges.flashSale:
        return l10n.flashSale;
      case DealBadges.limitedTime:
        return l10n.limitedTime;
      case DealBadges.priceDrop:
        return l10n.priceDrop;
      case DealBadges.newArrival:
        return l10n.newArrival;
      case DealBadges.freeShipping:
        return l10n.freeShipping;
      default:
        return badge;
    }
  }
}
