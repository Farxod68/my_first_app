import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

/// Deal badge color and label mapping for TOPBUY DEALS
///
/// Single source of truth for the color and localized text associated with
/// each [DealBadges] value. Shared by `ProductCard` and `ProductDetailsPage`
/// so both surfaces render deal badges identically.
class DealBadgeHelper {
  DealBadgeHelper._(); // Private constructor - utility class

  /// Get badge color based on badge type
  static Color color(String badge) {
    switch (badge) {
      case DealBadges.bestSeller:
        return AppColors.info; // Blue
      case DealBadges.trending:
        return const Color(0xFFE91E63); // Pink
      case DealBadges.flashSale:
        return const Color(0xFFFF6F00); // Orange
      case DealBadges.limitedTime:
        return AppColors.warning; // Deep Orange
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
  static String label(String badge, AppLocalizations l10n) {
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
