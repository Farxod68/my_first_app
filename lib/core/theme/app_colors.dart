import 'package:flutter/material.dart';

/// Design-system color tokens for TOPBUY DEALS.
///
/// Design-token foundation: these values mirror the brand/semantic colors
/// already in use across the app (see [AppTheme]). Consumed across the
/// app's screens and widgets.
class AppColors {
  AppColors._();

  /// Primary brand blue. Matches `AppTheme.primaryBlue`.
  static const Color primaryBlue = Color(0xFF0066CC);

  /// Darker shade of the primary blue, for pressed states and gradients.
  static const Color primaryDark = Color(0xFF004C99);

  /// Secondary/accent green used for savings, success, and in-stock cues.
  static const Color accentGreen = Color(0xFF00C853);

  /// Danger/error color used for discounts, out-of-stock, destructive actions.
  static const Color danger = Color(0xFFD32F2F);

  /// Warning color used for low-stock and caution states.
  static const Color warning = Color(0xFFF57C00);

  /// Informational color used for the "Best Seller" badge and similar cues.
  static const Color info = Color(0xFF1976D2);
}

/// [ThemeExtension] wrapper around [AppColors] so the tokens can eventually
/// be looked up via `Theme.of(context).extension<AppColorsExtension>()`
/// (needed once a dark theme is introduced, so each brightness can supply
/// its own values). Registered on [AppTheme.lightTheme]; not yet consumed
/// by any screen (screens currently read [AppColors] directly).
@immutable
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color primaryBlue;
  final Color primaryDark;
  final Color accentGreen;
  final Color danger;
  final Color warning;
  final Color info;

  const AppColorsExtension({
    required this.primaryBlue,
    required this.primaryDark,
    required this.accentGreen,
    required this.danger,
    required this.warning,
    required this.info,
  });

  /// Token values for the current (and only) light theme.
  static const AppColorsExtension light = AppColorsExtension(
    primaryBlue: AppColors.primaryBlue,
    primaryDark: AppColors.primaryDark,
    accentGreen: AppColors.accentGreen,
    danger: AppColors.danger,
    warning: AppColors.warning,
    info: AppColors.info,
  );

  @override
  AppColorsExtension copyWith({
    Color? primaryBlue,
    Color? primaryDark,
    Color? accentGreen,
    Color? danger,
    Color? warning,
    Color? info,
  }) {
    return AppColorsExtension(
      primaryBlue: primaryBlue ?? this.primaryBlue,
      primaryDark: primaryDark ?? this.primaryDark,
      accentGreen: accentGreen ?? this.accentGreen,
      danger: danger ?? this.danger,
      warning: warning ?? this.warning,
      info: info ?? this.info,
    );
  }

  @override
  AppColorsExtension lerp(ThemeExtension<AppColorsExtension>? other, double t) {
    if (other is! AppColorsExtension) return this;
    return AppColorsExtension(
      primaryBlue: Color.lerp(primaryBlue, other.primaryBlue, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      accentGreen: Color.lerp(accentGreen, other.accentGreen, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
    );
  }
}
