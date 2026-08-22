import 'package:flutter/material.dart';

/// UI helper utilities for TOPBUY DEALS
///
/// Provides centralized, type-safe methods for common UI operations:
/// - Success notifications (green SnackBar)
/// - Error notifications (red SnackBar)
/// - Info notifications (default SnackBar)
///
/// Usage:
/// ```dart
/// UIHelpers.showSuccessMessage(context, 'Login successful');
/// UIHelpers.showErrorMessage(context, 'Login failed');
/// UIHelpers.showInfoMessage(context, 'Item added to cart');
/// UIHelpers.showInfoMessage(context, 'Added', duration: Duration(seconds: 2));
/// ```
class UIHelpers {
  UIHelpers._(); // Private constructor - utility class

  /// Show success message (green background)
  ///
  /// Used for successful operations like:
  /// - Login success
  /// - Profile updated
  /// - Signup success
  ///
  /// Parameters:
  /// - [context]: BuildContext for showing the SnackBar
  /// - [message]: Message text to display
  /// - [duration]: Optional custom duration (if not provided, uses Flutter default)
  static void showSuccessMessage(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    final snackBar = duration != null
        ? SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            duration: duration,
          )
        : SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
          );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// Show error message (red background)
  ///
  /// Used for error conditions like:
  /// - Login failed
  /// - Profile update failed
  /// - Network errors
  ///
  /// Parameters:
  /// - [context]: BuildContext for showing the SnackBar
  /// - [message]: Error message text to display
  /// - [duration]: Optional custom duration (if not provided, uses Flutter default)
  static void showErrorMessage(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    final snackBar = duration != null
        ? SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            duration: duration,
          )
        : SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
          );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// Show info message (default styling)
  ///
  /// Used for informational messages like:
  /// - Added to cart
  /// - Added to wishlist
  /// - General notifications
  ///
  /// Parameters:
  /// - [context]: BuildContext for showing the SnackBar
  /// - [message]: Info message text to display
  /// - [duration]: Optional custom duration (if not provided, uses Flutter default)
  static void showInfoMessage(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    final snackBar = duration != null
        ? SnackBar(
            content: Text(message),
            duration: duration,
          )
        : SnackBar(
            content: Text(message),
          );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
