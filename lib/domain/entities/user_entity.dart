/// User entity for TOPBUY DEALS (Domain Layer)
///
/// Pure Dart entity with no Flutter dependencies.
/// Represents the core user concept in the domain model.
///
/// This is separate from Supabase's auth.users and our profiles table.
/// It's the domain representation that the app logic works with.
class UserEntity {
  final String id;
  final String email;
  final String? fullName;
  final String? avatarUrl;
  final String? phone;
  final String languageCode;
  final String currencyCode;
  final String role;
  final bool isActive;
  final bool emailVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserEntity({
    required this.id,
    required this.email,
    this.fullName,
    this.avatarUrl,
    this.phone,
    this.languageCode = 'en',
    this.currencyCode = 'USD',
    this.role = 'customer',
    this.isActive = true,
    this.emailVerified = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if user is a customer
  bool get isCustomer => role == 'customer';

  /// Check if user is a seller
  bool get isSeller => role == 'seller';

  /// Check if user is an admin
  bool get isAdmin => role == 'admin';

  /// Get display name (full name or email)
  String get displayName => fullName ?? email.split('@').first;

  /// Copy with updated fields
  UserEntity copyWith({
    String? id,
    String? email,
    String? fullName,
    String? avatarUrl,
    String? phone,
    String? languageCode,
    String? currencyCode,
    String? role,
    bool? isActive,
    bool? emailVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone,
      languageCode: languageCode ?? this.languageCode,
      currencyCode: currencyCode ?? this.currencyCode,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      emailVerified: emailVerified ?? this.emailVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email;

  @override
  int get hashCode => id.hashCode ^ email.hashCode;

  @override
  String toString() {
    return 'UserEntity{id: $id, email: $email, fullName: $fullName, role: $role}';
  }
}
