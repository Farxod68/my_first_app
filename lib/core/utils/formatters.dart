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

/// Maps an app locale code to the `NumberFormat` locale string used for
/// number-grouping style (decimal/thousands separators) only.
///
/// This is deliberately independent of currency selection - see
/// [formatPrice]. Falls back to 'en_US' style grouping for any locale
/// without a dedicated case, matching the previous default behavior.
String _numberFormatLocaleFor(String locale) {
  switch (locale) {
    case 'uz':
      return 'uz';
    case 'fr':
      return 'fr_FR';
    case 'es':
      return 'es_ES';
    default:
      return 'en_US';
  }
}

/// Formats [price] (stored in USD, the app's base currency) for display in
/// [currencyCode], using [locale] only for locale-specific number-grouping
/// style - never for currency selection. `CurrencyProvider.currentCurrency`
/// is the source of truth callers should pass as [currencyCode].
///
/// Supports the app's existing three currencies, reusing the exact
/// conversion rates and symbols already in use before currency and locale
/// were decoupled:
/// - USD: rate 1, symbol $, 2 decimal digits (base currency, no conversion)
/// - EUR: rate 0.92, symbol €, 2 decimal digits
/// - UZS: rate 12,500, so'm suffix (no leading symbol), 0 decimal digits
///
/// Any unrecognized [currencyCode] falls back to USD, matching the
/// previous function's unrecognized-locale fallback behavior.
///
/// Returns the formatted price string appropriate for the given currency.
String formatPrice(double price, String currencyCode, String locale) {
  final numberFormatLocale = _numberFormatLocaleFor(locale);
  final NumberFormat formatter;

  switch (currencyCode) {
    case 'UZS':
      // Convert USD to UZS (1 USD ≈ 12,500 UZS)
      formatter = NumberFormat.currency(
        locale: numberFormatLocale,
        symbol: '',
        decimalDigits: 0,
      );
      return '${formatter.format(price * 12500)} so\'m';
    case 'EUR':
      // Convert USD to EUR (1 USD ≈ 0.92 EUR)
      formatter = NumberFormat.currency(
        locale: numberFormatLocale,
        symbol: '€',
        decimalDigits: 2,
      );
      return formatter.format(price * 0.92);
    case 'USD':
    default:
      // USD is the base currency - no conversion
      formatter = NumberFormat.currency(
        locale: numberFormatLocale,
        symbol: '\$',
        decimalDigits: 2,
      );
      return formatter.format(price);
  }
}
