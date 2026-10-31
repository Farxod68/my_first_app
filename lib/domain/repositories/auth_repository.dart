import '../entities/user_entity.dart';

/// Thrown by sign-up when the account was created but the user must
/// confirm their email address before a session is issued.
class EmailConfirmationRequiredException implements Exception {
  const EmailConfirmationRequiredException();

  @override
  String toString() => 'EmailConfirmationRequiredException';
}

/// Authentication repository interface (Domain Layer)
///
/// Defines the contract for authentication operations.
/// Implementations handle the actual communication with backends.
///
/// This abstraction allows:
/// - Easy testing (mock implementations)
/// - Backend independence (swap Supabase for Firebase, etc.)
/// - Clean separation of concerns
abstract class AuthRepository {
  /// Get current authenticated user
  ///
  /// Returns null if no user is authenticated.
  Future<UserEntity?> getCurrentUser();

  /// Sign up with email and password
  ///
  /// Creates a new user account and signs them in.
  /// Throws AuthException if signup fails.
  Future<UserEntity> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
  });

  /// Sign in with email and password
  ///
  /// Returns the authenticated user.
  /// Throws AuthException if credentials are invalid.
  Future<UserEntity> signInWithEmail({
    required String email,
    required String password,
  });

  /// Sign out
  ///
  /// Logs out the current user.
  Future<void> signOut();

  /// Send password reset email
  ///
  /// Sends a password reset link to the user's email.
  Future<void> resetPassword(String email);

  /// Emits whenever the user arrives via a password-recovery email link.
  ///
  /// By then a temporary recovery session exists; the UI should ask for a
  /// new password and call [updatePassword].
  Stream<void> get passwordRecoveryEvents;

  /// Set a new password for the currently signed-in (recovery) session.
  Future<void> updatePassword(String newPassword);

  /// Update user profile
  ///
  /// Updates the current user's profile data.
  Future<UserEntity> updateProfile({
    String? fullName,
    String? avatarUrl,
    String? phone,
    String? languageCode,
    String? currencyCode,
  });

  /// Listen to authentication state changes
  ///
  /// Stream emits:
  /// - UserEntity when user signs in
  /// - null when user signs out
  Stream<UserEntity?> get authStateChanges;

  /// Check if user is authenticated
  Future<bool> isAuthenticated();

  /// Permanently delete the currently authenticated user's account
  ///
  /// Deletes the user's auth record and profile data, then clears the
  /// local session. Throws AuthException if deletion fails. If the user has
  /// existing orders, nothing is deleted, the session is kept, and the
  /// AuthException's `code` is [accountHasOrdersCode].
  Future<void> deleteAccount();

  /// AuthException code for an account that cannot be deleted because it
  /// has existing orders (the delete-account Edge Function's 409 response).
  static const accountHasOrdersCode = 'ACCOUNT_HAS_ORDERS';
}
