import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../data_sources/remote/auth_remote_data_source.dart';

/// Authentication repository implementation (Data Layer)
///
/// Implements AuthRepository interface using Supabase backend.
/// Mediates between domain layer and data sources.
///
/// Architecture:
/// Provider → Repository → Data Source → Supabase
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl(this._remoteDataSource);

  @override
  Future<UserEntity?> getCurrentUser() async {
    final userModel = await _remoteDataSource.getCurrentUser();
    return userModel?.toEntity();
  }

  @override
  Future<UserEntity> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final userModel = await _remoteDataSource.signUp(
      email: email,
      password: password,
      fullName: fullName,
    );
    return userModel.toEntity();
  }

  @override
  Future<UserEntity> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final userModel = await _remoteDataSource.signIn(
      email: email,
      password: password,
    );
    return userModel.toEntity();
  }

  @override
  Future<void> signOut() async {
    await _remoteDataSource.signOut();
  }

  @override
  Future<void> resetPassword(String email) async {
    await _remoteDataSource.resetPassword(email);
  }

  @override
  Future<UserEntity> updateProfile({
    String? fullName,
    String? avatarUrl,
    String? phone,
    String? languageCode,
    String? currencyCode,
  }) async {
    final currentUser = await _remoteDataSource.getCurrentUser();
    if (currentUser == null) {
      throw Exception('No user authenticated');
    }

    final updatedModel = await _remoteDataSource.updateProfile(
      userId: currentUser.id,
      fullName: fullName,
      avatarUrl: avatarUrl,
      phone: phone,
      languageCode: languageCode,
      currencyCode: currencyCode,
    );

    return updatedModel.toEntity();
  }

  @override
  Stream<UserEntity?> get authStateChanges {
    return _remoteDataSource.authStateChanges.map(
      (userModel) => userModel?.toEntity(),
    );
  }

  @override
  Future<bool> isAuthenticated() async {
    return await _remoteDataSource.isAuthenticated();
  }

  @override
  Future<void> deleteAccount() async {
    await _remoteDataSource.deleteAccount();
  }
}
