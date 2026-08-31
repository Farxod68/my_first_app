import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_elevation.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/deal_badge_helper.dart';
import '../../core/utils/formatters.dart';
import '../../core/constants/widget_keys.dart';
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
        borderRadius: AppRadius.largeAll,
      ),
      child: InkWell(
        key: WidgetKeys.productCard(product.id),
        borderRadius: AppRadius.largeAll,
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
                          AppColors.primaryBlue.withValues(alpha: 0.05),
                          AppColors.accentGreen.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(AppRadius.large),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        key: WidgetKeys.productCardIcon(product.id),
                        product.icon,
                        size: 80,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),

                  // Badges section (discount + deal badges)
                  if (product.discount > 0 || product.badges.isNotEmpty)
                    Positioned(
                      top: AppSpacing.sm,
                      left: AppSpacing.sm,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Discount badge
                          if (product.discount > 0)
                            Container(
                              key: WidgetKeys.productCardDiscountBadge(product.id),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.danger,
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
                            if (product.discount > 0) const SizedBox(height: AppSpacing.xs),
                            Container(
                              key: WidgetKeys.productCardDealBadge(product.id),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: DealBadgeHelper.color(product.badges.first),
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
                                DealBadgeHelper.label(product.badges.first, l10n),
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
                    top: AppSpacing.xs,
                    right: AppSpacing.xs,
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      elevation: AppElevation.resting,
                      child: IconButton(
                        key: WidgetKeys.productCardFavoriteButton(product.id),
                        iconSize: 20,
                        onPressed: onFavoriteToggle,
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite
                              ? AppColors.danger
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
                      key: WidgetKeys.productCardName(product.id),
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
                            key: WidgetKeys.productCardCategory(product.id),
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
                          const SizedBox(width: AppSpacing.xs),
                          Icon(
                            key: WidgetKeys.productCardRating(product.id),
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
                          key: WidgetKeys.productCardPrice(product.id),
                          formatPrice(product.price, locale),
                          style: Theme.of(context)
                              .textTheme.titleMedium
                              ?.copyWith(
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.bold,
                              ),
                          maxLines: 1,
                        ),

                        // Old price (strikethrough)
                        if (product.discount > 0)
                          Text(
                            key: WidgetKeys.productCardOldPrice(product.id),
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
}
