/// Elevation scale for TOPBUY DEALS.
///
/// Design-token foundation: three tiers spanning the elevations already in
/// use — flat (0, list rows/dividers), resting cards (currently 1-2,
/// represented here by [resting] = 2 to match `CardThemeData`'s existing
/// default), and floating/emphasized surfaces (currently 4-8, represented
/// here by [floating] = 8).
class AppElevation {
  AppElevation._();

  /// Flat surfaces with no shadow (list rows, dividers).
  static const double flat = 0;

  /// Resting cards (e.g. product cards, section cards).
  static const double resting = 2;

  /// Floating/emphasized surfaces (FAB, sticky bars, dialogs, popups).
  static const double floating = 8;
}
