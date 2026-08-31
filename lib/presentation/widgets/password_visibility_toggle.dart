import 'package:flutter/material.dart';

/// Shared password-visibility toggle for TOPBUY DEALS auth forms.
///
/// Consolidates the icon-toggle button previously duplicated identically
/// across `LoginPage` and `SignUpPage` (password + confirm password). This
/// widget is purely presentational: the parent screen still owns the
/// `obscureText` boolean and its `setState` call, and supplies it here via
/// [obscured] and [onToggle].
class PasswordVisibilityToggle extends StatelessWidget {
  final bool obscured;
  final VoidCallback onToggle;

  const PasswordVisibilityToggle({
    super.key,
    required this.obscured,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
      ),
      onPressed: onToggle,
    );
  }
}
