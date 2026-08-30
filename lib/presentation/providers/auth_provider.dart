import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

/// Authentication state management provider (Presentation Layer)
///
/// Manages user authentication state including:
/// - Current user
/// - Authentication status
/// - Sign in/up/out operations
/// - Profile updates
/// - Auth state listening
///
/// Uses ChangeNotifier for state management with Provider pattern.
/// Integrates with AuthRepository for backend operations.
class AuthProvider with ChangeNotifier {
  final AuthRepository _authRepository;

  UserEntity? _currentUser;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;
  StreamSubscription<UserEntity?>? _authStateSubscription;

  AuthProvider(this._authRepository) {
    _initialize();
  }

  /// Current authenticated user
  UserEntity? get currentUser => _currentUser;

  /// Loading state (for auth operations)
  bool get isLoading => _isLoading;

  /// Initialization state
  bool get isInitialized => _isInitialized;

  /// Error message
  String? get error => _error;

  /// Check if user is authenticated
  bool get isAuthenticated => _currentUser != null;

  /// Check if user is a guest (not authenticated)
  bool get isGuest => _currentUser == null;

  /// User's display name
  String? get displayName => _currentUser?.displayName;

  /// User's email
  String? get email => _currentUser?.email;

  /// User's language preference
  String get languageCode => _currentUser?.languageCode ?? 'en';

  /// User's currency preference
  String get currencyCode => _currentUser?.currencyCode ?? 'USD';

  /// Initialize auth provider
  ///
  /// - Loads current user if authenticated
  /// - Subscribes to auth state changes
  Future<void> _initialize() async {
    try {
      // Load current user
      _currentUser = await _authRepository.getCurrentUser();

      // Listen to auth state changes
      _authStateSubscription = _authRepository.authStateChanges.listen(
        (user) {
          _currentUser = user;
          notifyListeners();
        },
        onError: (error) {
          debugPrint('Auth state change error: $error');
        },
      );
    } catch (e) {
      debugPrint('Auth initialization error: $e');
      _error = e.toString();
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Get user preferences (language and currency) for syncing with local providers
  ///
  /// Returns a map with 'languageCode' and 'currencyCode' keys.
  /// Used by LocaleProvider and CurrencyProvider to sync on login/profile restore.
  Map<String, String>? getUserPreferences() {
    if (_currentUser == null) {
      return null;
    }
    return {
      'languageCode': _currentUser!.languageCode,
      'currencyCode': _currentUser!.currencyCode,
    };
  }

  /// Sign up with email and password
  Future<bool> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _authRepository.signUpWithEmail(
        email: email,
        password: password,
        fullName: fullName,
      );

      _currentUser = user;
      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Sign up failed: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Sign in with email and password
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _authRepository.signInWithEmail(
        email: email,
        password: password,
      );

      _currentUser = user;
      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Sign in failed: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _setLoading(true);
    _clearError();

    try {
      await _authRepository.signOut();
      _currentUser = null;
    } catch (e) {
      _setError('Sign out failed: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Send password reset email
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await _authRepository.resetPassword(email);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Password reset failed: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Update user profile
  Future<bool> updateProfile({
    String? fullName,
    String? avatarUrl,
    String? phone,
    String? languageCode,
    String? currencyCode,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedUser = await _authRepository.updateProfile(
        fullName: fullName,
        avatarUrl: avatarUrl,
        phone: phone,
        languageCode: languageCode,
        currencyCode: currencyCode,
      );

      _currentUser = updatedUser;
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Profile update failed: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Permanently delete the current user's account
  ///
  /// Clears the local user/session on success. Returns false and sets
  /// [error] on failure (session expired, network error, or unexpected
  /// error), leaving the current session untouched.
  Future<bool> deleteAccount() async {
    _setLoading(true);
    _clearError();

    try {
      await _authRepository.deleteAccount();
      _currentUser = null;
      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Account deletion failed: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  /// Clear error
  void _clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}
