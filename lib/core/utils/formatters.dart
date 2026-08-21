import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';

/// Localization and formatting utilities for TOPBUY DEALS
///
/// Provides functions for:
/// - Price formatting with currency conversion
/// - Category name localization

/// Returns localized category name based on category key
///
/// Supports categories: electronics, clothing, accessories, homeGoods, sports, cosmetics
String getLocalizedCategory(String categoryKey, AppLocalizations l10n) {
  switch (categoryKey) {
    case 'electronics':
      return l10n.electronics;
    case 'clothing':
      return l10n.clothing;
    case 'accessories':
      return l10n.accessories;
    case 'homeGoods':
      return l10n.homeGoods;
    case 'sports':
      return l10n.sports;
    case 'cosmetics':
      return l10n.cosmetics;
    default:
      return categoryKey;
  }
}

/// Formats price with currency conversion based on locale
///
/// Supports:
/// - English (en): USD with $ symbol
/// - Spanish (es): EUR with € symbol (0.92 conversion rate)
/// - French (fr): EUR with € symbol (0.92 conversion rate)
/// - Uzbek (uz): UZS with so'm suffix (12,500 conversion rate)
///
/// Returns formatted price string appropriate for the locale
String formatPrice(double price, String locale) {
  final NumberFormat formatter;

  switch (locale) {
    case 'uz':
      // Convert USD to UZS (1 USD ≈ 12,500 UZS)
      formatter = NumberFormat.currency(
        locale: 'uz',
        symbol: '',
        decimalDigits: 0,
      );
      return '${formatter.format(price * 12500)} so\'m';
    case 'fr':
      // Convert USD to EUR (1 USD ≈ 0.92 EUR) - French locale
      formatter = NumberFormat.currency(
        locale: 'fr_FR',
        symbol: '€',
        decimalDigits: 2,
      );
      return formatter.format(price * 0.92);
    case 'es':
      // Convert USD to EUR (1 USD ≈ 0.92 EUR) - Spanish locale
      formatter = NumberFormat.currency(
        locale: 'es_ES',
        symbol: '€',
        decimalDigits: 2,
      );
      return formatter.format(price * 0.92);
    default:
      // English - USD (base currency)
      formatter = NumberFormat.currency(
        locale: 'en_US',
        symbol: '\$',
        decimalDigits: 2,
      );
      return formatter.format(price);
  }
}
