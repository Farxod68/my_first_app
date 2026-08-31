import 'package:flutter/material.dart';

/// Shared submit-button loading spinner for TOPBUY DEALS auth forms.
///
/// Consolidates the icon-sized spinner previously duplicated identically
/// (same 20x20 size, same `strokeWidth`, same white color) across the
/// login, sign up, and forgot-password submit buttons - each of which
/// swaps its button label for this spinner while `_isLoading` is true.
/// The only thing that ever varied between the three was the widget's own
/// `key` (a distinct `WidgetKeys` constant per screen), which callers still
/// supply via the standard `key:` parameter.
class ButtonLoadingIndicator extends StatelessWidget {
  const ButtonLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 20,
      width: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: Colors.white,
      ),
    );
  }
}
