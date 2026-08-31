import 'package:flutter/material.dart';

import 'app_colors.dart';

/// TOPBUY DEALS App Theme Configuration
///
/// Contains the complete Material 3 theme definition including:
/// - Color scheme (Blue #0066CC primary, Green #00C853 secondary)
/// - Typography scale
/// - Card styling
/// - Button styling
/// - AppBar styling
///
/// Phase 0 design-token foundation: [lightTheme] also registers
/// [AppColorsExtension] so future screens can read brand/semantic colors via
/// `Theme.of(context).extension<AppColorsExtension>()`. This is purely
/// additive — it does not change any existing color, style, or widget
/// currently rendered by the app. See also `app_spacing.dart`,
/// `app_radius.dart`, and `app_elevation.dart` for the rest of the token
/// foundation (spacing/radius/elevation are plain static constants and
/// don't need to be registered on [ThemeData]).
class AppTheme {
  // Brand colors
  static const Color primaryBlue = Color(0xFF0066CC);
  static const Color secondaryGreen = Color(0xFF00C853);
  static const Color errorRed = Color(0xFFD32F2F);

  /// Light theme for TOPBUY DEALS
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: Brightness.light,
      ).copyWith(
        primary: primaryBlue,
        secondary: secondaryGreen,
        surface: Colors.white,
        error: errorRed,
      ),
      cardTheme: const CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
          height: 1.2,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.3,
          height: 1.2,
        ),
        headlineLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.2,
          height: 1.3,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
          height: 1.3,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          height: 1.5,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 2,
      ),
      extensions: const <ThemeExtension<dynamic>>[
        AppColorsExtension.light,
      ],
    );
  }
}
