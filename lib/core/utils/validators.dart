import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

/// Form validation utilities for TOPBUY DEALS
///
/// Provides reusable validators for common form fields including:
/// - Email validation with RFC-compliant regex
/// - Password validation with minimum length
///
/// Usage:
/// ```dart
/// TextFormField(
///   validator: (value) => FormValidators.validateEmail(context, value),
/// )
/// ```
class FormValidators {
  FormValidators._(); // Private constructor - utility class

  /// Email regex pattern (RFC 5322 simplified)
  ///
  /// Matches standard email addresses like:
  /// - user@example.com
  /// - first.last@example.co.uk
  /// - user123@test-domain.org
  static final RegExp emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  /// Minimum password length for security
  static const int minPasswordLength = 6;

  /// Validate email address
  ///
  /// Returns null if valid, error message if invalid.
  /// Checks for:
  /// - Non-empty value
  /// - Valid email format
  static String? validateEmail(BuildContext context, String? value) {
    final l10n = AppLocalizations.of(context)!;
    if (value == null || value.isEmpty) {
      return l10n.emailRequired;
    }
    if (!emailRegex.hasMatch(value)) {
      return l10n.emailInvalid;
    }
    return null;
  }

  /// Validate password
  ///
  /// Returns null if valid, error message if invalid.
  /// Checks for:
  /// - Non-empty value
  /// - Minimum length (6 characters)
  static String? validatePassword(BuildContext context, String? value) {
    final l10n = AppLocalizations.of(context)!;
    if (value == null || value.isEmpty) {
      return l10n.passwordRequired;
    }
    if (value.length < minPasswordLength) {
      return l10n.passwordTooShort;
    }
    return null;
  }
}
