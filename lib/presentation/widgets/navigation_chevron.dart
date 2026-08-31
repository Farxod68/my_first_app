import 'package:flutter/material.dart';

/// Shared trailing "navigate forward" chevron for TOPBUY DEALS list rows.
///
/// Consolidates the icon previously duplicated identically 10 times across
/// `profile_edit_page.dart`, `profile_tab.dart`, and `categories_tab.dart`
/// (always `Icons.arrow_forward_ios` at size 16, no other styling). Has no
/// configurable parameters, since every occurrence was already identical.
class NavigationChevron extends StatelessWidget {
  const NavigationChevron({super.key});

  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.arrow_forward_ios, size: 16);
  }
}
