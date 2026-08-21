import 'package:flutter/material.dart';

/// Responsive design breakpoints for TOPBUY DEALS
///
/// Defines screen width breakpoints for mobile, tablet, and desktop layouts:
/// - Mobile: < 600px
/// - Tablet: 600px - 1200px
/// - Desktop: >= 1200px
class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
}

/// Screen size helper utilities for responsive design
///
/// Provides methods to:
/// - Detect device type (mobile, tablet, desktop)
/// - Calculate grid columns based on screen width
/// - Determine appropriate horizontal padding
class ScreenSize {
  /// Returns true if screen width is less than 600px
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < Breakpoints.mobile;

  /// Returns true if screen width is between 600px and 1200px
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= Breakpoints.mobile &&
      MediaQuery.of(context).size.width < Breakpoints.desktop;

  /// Returns true if screen width is 1200px or greater
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= Breakpoints.desktop;

  /// Calculates optimal grid columns based on screen width
  ///
  /// Returns:
  /// - 2 columns for mobile (< 600px)
  /// - 3 columns for tablet portrait (600px - 900px)
  /// - 4 columns for tablet landscape (900px - 1200px)
  /// - 5 columns for desktop (>= 1200px)
  static int getGridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < Breakpoints.mobile) {
      return 2; // Mobile: 2 columns
    } else if (width < Breakpoints.tablet) {
      return 3; // Tablet portrait: 3 columns
    } else if (width < Breakpoints.desktop) {
      return 4; // Tablet landscape: 4 columns
    } else {
      return 5; // Desktop: 5 columns
    }
  }

  /// Returns adaptive horizontal padding based on screen width
  ///
  /// Returns:
  /// - 16px for mobile (< 600px)
  /// - 24px for tablet (600px - 1200px)
  /// - 32px for desktop (>= 1200px)
  static double getHorizontalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < Breakpoints.mobile) {
      return 16;
    } else if (width < Breakpoints.desktop) {
      return 24;
    } else {
      return 32;
    }
  }
}
