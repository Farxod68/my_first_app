import 'package:flutter/foundation.dart';

/// Mixin for providers that need persistent loading state management
///
/// Provides common loading state tracking for providers that load data
/// from persistence on initialization.
///
/// Usage:
/// ```dart
/// class MyProvider with ChangeNotifier, PersistentProviderMixin {
///   MyProvider() {
///     _loadData();
///   }
///
///   Future<void> _loadData() async {
///     try {
///       // Load data logic
///     } catch (e) {
///       // Error handling
///     } finally {
///       markAsLoaded();
///     }
///   }
/// }
/// ```
mixin PersistentProviderMixin on ChangeNotifier {
  bool _isLoaded = false;

  /// Check if data has been loaded from storage
  bool get isLoaded => _isLoaded;

  /// Mark loading as complete
  ///
  /// Should be called in the finally block of load methods.
  /// Sets the loaded flag and notifies listeners.
  @protected
  void markAsLoaded() {
    _isLoaded = true;
    notifyListeners();
  }
}
