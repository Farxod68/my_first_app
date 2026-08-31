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

/// Named content-width caps for centered, `isWideScreen`-gated layouts.
///
/// Consolidates the three max-width values that were each already
/// duplicated verbatim (same number, same `isWideScreen` condition) across
/// multiple screens: [authForm] for the login/signup/forgot-password forms,
/// [settings] for the profile edit/settings screens, and [list] for the
/// cart/category/favorites product-row screens. Every value here is
/// unchanged from what those screens already rendered - this class only
/// removes the duplication, not the values themselves.
///
/// Does NOT cover the app's few single-use, `isDesktop`-gated max-widths
/// (e.g. the home hero banner, the home product grid, or the product
/// details image gallery) - those have no duplicate sibling today, so
/// there is nothing to consolidate for them yet.
class ContentWidth {
  ContentWidth._();

  /// Login / sign up / forgot password forms.
  static const double authForm = 400;

  /// Profile edit and profile settings screens.
  static const double settings = 600;

  /// Cart, category, and favorites product-row lists.
  static const double list = 800;
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
