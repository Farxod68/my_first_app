import 'package:flutter/material.dart';
import '../../core/theme/app_spacing.dart';

/// Shared empty-state UI for TOPBUY DEALS.
///
/// Consolidates the icon + message layout previously duplicated across
/// `CartPage`, `CategoryPage`, and `FavoritesTab`. Every parameter default
/// matches the majority (80px icon, 18px text, left-aligned, no extra text
/// padding) so a call site only needs to override what its original
/// implementation actually differed on - see each call site for the
/// preserved values.
///
/// This widget is purely presentational: the parent screen decides when to
/// show it and supplies an already-localized [message].
class EmptyState extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final String message;
  final double fontSize;
  final TextAlign textAlign;
  final EdgeInsetsGeometry? textPadding;

  const EmptyState({
    super.key,
    required this.icon,
    this.iconSize = 80,
    required this.message,
    this.fontSize = 18,
    this.textAlign = TextAlign.start,
    this.textPadding,
  });

  @override
  Widget build(BuildContext context) {
    final text = Text(
      message,
      style: TextStyle(
        fontSize: fontSize,
        color: Colors.grey.shade600,
      ),
      textAlign: textAlign,
    );

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: iconSize,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: AppSpacing.lg),
          textPadding == null ? text : Padding(padding: textPadding!, child: text),
        ],
      ),
    );
  }
}
