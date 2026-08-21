import '../../domain/entities/user_entity.dart';

/// User model for TOPBUY DEALS (Data Layer)
///
/// Extends UserEntity with serialization for Supabase.
/// Handles conversion between Supabase JSON and domain entities.
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    super.fullName,
    super.avatarUrl,
    super.phone,
    super.languageCode,
    super.currencyCode,
    super.role,
    super.isActive,
    super.emailVerified,
    required super.createdAt,
    required super.updatedAt,
  });

  /// Create UserModel from Supabase profiles JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      phone: json['phone'] as String?,
      languageCode: json['language_code'] as String? ?? 'en',
      currencyCode: json['currency_code'] as String? ?? 'USD',
      role: json['role'] as String? ?? 'customer',
      isActive: json['is_active'] as bool? ?? true,
      emailVerified: json['email_verified'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert UserModel to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'phone': phone,
      'language_code': languageCode,
      'currency_code': currencyCode,
      'role': role,
      'is_active': isActive,
      'email_verified': emailVerified,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Convert UserEntity to UserModel
  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      email: entity.email,
      fullName: entity.fullName,
      avatarUrl: entity.avatarUrl,
      phone: entity.phone,
      languageCode: entity.languageCode,
      currencyCode: entity.currencyCode,
      role: entity.role,
      isActive: entity.isActive,
      emailVerified: entity.emailVerified,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Convert UserModel to UserEntity
  UserEntity toEntity() {
    return UserEntity(
      id: id,
      email: email,
      fullName: fullName,
      avatarUrl: avatarUrl,
      phone: phone,
      languageCode: languageCode,
      currencyCode: currencyCode,
      role: role,
      isActive: isActive,
      emailVerified: emailVerified,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  UserModel copyWith({
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
    return UserModel(
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
}
