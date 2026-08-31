import 'package:flutter/material.dart';

/// Corner-radius scale for TOPBUY DEALS.
///
/// Design-token foundation: matches the two radii already dominant across
/// the app — 12 (buttons, inputs, small chips/containers) and 16 (cards,
/// hero banner, images). Consumed across the app's screens and widgets.
class AppRadius {
  AppRadius._();

  /// Buttons, inputs, small chips/containers.
  static const double small = 12;

  /// Cards, hero banner, images.
  static const double large = 16;

  static const BorderRadius smallAll =
      BorderRadius.all(Radius.circular(small));

  static const BorderRadius largeAll =
      BorderRadius.all(Radius.circular(large));
}
