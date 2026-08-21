import 'package:flutter/material.dart';
import '../../core/utils/formatters.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/product.dart';
import '../../l10n/app_localizations.dart';

/// Reusable product card widget for TOPBUY DEALS
///
/// Displays product information in a card format with:
/// - Product icon with gradient background
/// - Discount badge (if applicable)
/// - Favorite toggle button
/// - Product name and category
/// - Current price and old price
///
/// Supports tap gesture to view product details
class ProductCard extends StatelessWidget {
  final Product product;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  final String locale;

  const ProductCard({
    super.key,
    required this.product,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteToggle,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image/icon section
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  // Gradient background
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF0066CC).withValues(alpha: 0.05),
                          const Color(0xFF00C853).withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        product.icon,
                        size: 80,
                        color: const Color(0xFF0066CC),
                      ),
                    ),
                  ),

                  // Badges section (discount + deal badges)
                  if (product.discount > 0 || product.badges.isNotEmpty)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Discount badge
                          if (product.discount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD32F2F),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                l10n.discountPercent(product.discount),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          // Deal badges (show first badge only to avoid clutter)
                          if (product.badges.isNotEmpty) ...[
                            if (product.discount > 0) const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: _getBadgeColor(product.badges.first),
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 3,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Text(
                                _getLocalizedBadge(product.badges.first, l10n),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                  // Favorite button
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      elevation: 2,
                      child: IconButton(
                        iconSize: 20,
                        onPressed: onFavoriteToggle,
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite
                              ? const Color(0xFFD32F2F)
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Product information section
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product name
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 3),

                    // Category and Rating in one line to save space
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            getLocalizedCategory(product.category, l10n),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey.shade600,
                                  fontSize: 11,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (product.hasRating) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.star,
                            size: 12,
                            color: Colors.amber.shade700,
                          ),
                          const SizedBox(width: 1),
                          Text(
                            product.rating.toStringAsFixed(1),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                          ),
                        ],
                      ],
                    ),

                    const Spacer(),

                    // Pricing
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Current price
                        Text(
                          formatPrice(product.price, locale),
                          style: Theme.of(context)
                              .textTheme.titleMedium
                              ?.copyWith(
                                color: const Color(0xFF0066CC),
                                fontWeight: FontWeight.bold,
                              ),
                          maxLines: 1,
                        ),

                        // Old price (strikethrough)
                        if (product.discount > 0)
                          Text(
                            formatPrice(product.oldPrice, locale),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Colors.grey.shade500,
                                  decoration: TextDecoration.lineThrough,
                                  fontSize: 11,
                                ),
                            maxLines: 1,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Get badge color based on badge type
  Color _getBadgeColor(String badge) {
    switch (badge) {
      case DealBadges.bestSeller:
        return const Color(0xFF1976D2); // Blue
      case DealBadges.trending:
        return const Color(0xFFE91E63); // Pink
      case DealBadges.flashSale:
        return const Color(0xFFFF6F00); // Orange
      case DealBadges.limitedTime:
        return const Color(0xFFF57C00); // Deep Orange
      case DealBadges.priceDrop:
        return const Color(0xFF388E3C); // Green
      case DealBadges.newArrival:
        return const Color(0xFF7B1FA2); // Purple
      case DealBadges.freeShipping:
        return const Color(0xFF00796B); // Teal
      default:
        return const Color(0xFF616161); // Gray
    }
  }

  /// Get localized badge text
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
