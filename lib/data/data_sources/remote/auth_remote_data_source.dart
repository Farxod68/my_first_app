import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../../models/user_model.dart';

/// Authentication remote data source (Data Layer)
///
/// Handles all Supabase Auth operations.
/// Never called directly from UI - always through repository.
class AuthRemoteDataSource {
  final SupabaseClient _supabase;

  AuthRemoteDataSource() : _supabase = SupabaseService.client;

  /// Get current user from Supabase Auth
  Future<UserModel?> getCurrentUser() async {
    final authUser = _supabase.auth.currentUser;
    if (authUser == null) {
      return null;
    }

    // Fetch profile data from profiles table
    final response = await _supabase
        .from('profiles')
        .select()
        .eq('id', authUser.id)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return UserModel.fromJson(response);
  }

  /// Sign up with email and password
  Future<UserModel> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: fullName != null ? {'full_name': fullName} : null,
      );

      if (response.user == null) {
        throw AuthException('Sign up failed: No user returned');
      }

      // Wait briefly for profile to be created by trigger
      await Future.delayed(const Duration(milliseconds: 500));

      // Fetch profile
      final profile = await _supabase
          .from('profiles')
          .select()
          .eq('id', response.user!.id)
          .single();

      return UserModel.fromJson(profile);
    } on AuthException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw AuthException('Sign up failed: $e');
    }
  }

  /// Sign in with email and password
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw AuthException('Sign in failed: No user returned');
      }

      // Fetch profile
      final profile = await _supabase
          .from('profiles')
          .select()
          .eq('id', response.user!.id)
          .single();

      return UserModel.fromJson(profile);
    } on AuthException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw AuthException('Sign in failed: $e');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw AuthException('Sign out failed: $e');
    }
  }

  /// Send password reset email
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw AuthException('Password reset failed: $e');
    }
  }

  /// Update user profile
  Future<UserModel> updateProfile({
    required String userId,
    String? fullName,
    String? avatarUrl,
    String? phone,
    String? languageCode,
    String? currencyCode,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (fullName != null) updates['full_name'] = fullName;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      if (phone != null) updates['phone'] = phone;
      if (languageCode != null) updates['language_code'] = languageCode;
      if (currencyCode != null) updates['currency_code'] = currencyCode;

      if (updates.isEmpty) {
        // No updates, just fetch current profile
        final profile = await _supabase
            .from('profiles')
            .select()
            .eq('id', userId)
            .single();
        return UserModel.fromJson(profile);
      }

      // Update profile
      final response = await _supabase
          .from('profiles')
          .update(updates)
          .eq('id', userId)
          .select()
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      throw AuthException('Profile update failed: $e');
    }
  }

  /// Listen to auth state changes
  Stream<UserModel?> get authStateChanges {
    return _supabase.auth.onAuthStateChange.asyncMap((state) async {
      final user = state.session?.user;
      if (user == null) {
        return null;
      }

      try {
        final profile = await _supabase
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        if (profile == null) {
          return null;
        }

        return UserModel.fromJson(profile);
      } catch (e) {
        return null;
      }
    });
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    return _supabase.auth.currentUser != null;
  }
}
