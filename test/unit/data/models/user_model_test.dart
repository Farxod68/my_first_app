import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/data/models/user_model.dart';
import 'package:my_first_app/domain/entities/user_entity.dart';

void main() {
  group('UserModel', () {
    // Sample data
    final testDateTime = DateTime(2024, 1, 15, 10, 30, 0);
    final testDateTimeString = '2024-01-15T10:30:00.000';

    group('Constructor', () {
      test('creates instance with all required fields', () {
        final model = UserModel(
          id: 'user123',
          email: 'test@example.com',
          createdAt: testDateTime,
          updatedAt: testDateTime,
        );

        expect(model.id, equals('user123'));
        expect(model.email, equals('test@example.com'));
        expect(model.createdAt, equals(testDateTime));
        expect(model.updatedAt, equals(testDateTime));
      });

      test('creates instance with all fields including optional', () {
        final model = UserModel(
          id: 'user123',
          email: 'test@example.com',
          fullName: 'John Doe',
          avatarUrl: 'https://example.com/avatar.jpg',
          phone: '+1234567890',
          languageCode: 'es',
          currencyCode: 'EUR',
          role: 'admin',
          isActive: true,
          emailVerified: true,
          createdAt: testDateTime,
          updatedAt: testDateTime,
        );

        expect(model.id, equals('user123'));
        expect(model.email, equals('test@example.com'));
        expect(model.fullName, equals('John Doe'));
        expect(model.avatarUrl, equals('https://example.com/avatar.jpg'));
        expect(model.phone, equals('+1234567890'));
        expect(model.languageCode, equals('es'));
        expect(model.currencyCode, equals('EUR'));
        expect(model.role, equals('admin'));
        expect(model.isActive, isTrue);
        expect(model.emailVerified, isTrue);
      });

      test('optional fields default to null when not provided', () {
        final model = UserModel(
          id: 'user123',
          email: 'test@example.com',
          createdAt: testDateTime,
          updatedAt: testDateTime,
        );

        expect(model.fullName, isNull);
        expect(model.avatarUrl, isNull);
        expect(model.phone, isNull);
      });

      test('defaults for required optional fields', () {
        final model = UserModel(
          id: 'user123',
          email: 'test@example.com',
          createdAt: testDateTime,
          updatedAt: testDateTime,
        );

        expect(model.languageCode, equals('en'));
        expect(model.currencyCode, equals('USD'));
        expect(model.role, equals('customer'));
        expect(model.isActive, isTrue);
        expect(model.emailVerified, isFalse);
      });
    });

    group('fromJson', () {
      test('creates instance from complete JSON', () {
        final json = {
          'id': 'user123',
          'email': 'test@example.com',
          'full_name': 'John Doe',
          'avatar_url': 'https://example.com/avatar.jpg',
          'phone': '+1234567890',
          'language_code': 'es',
          'currency_code': 'EUR',
          'role': 'admin',
          'is_active': true,
          'email_verified': true,
          'created_at': testDateTimeString,
          'updated_at': testDateTimeString,
        };

        final model = UserModel.fromJson(json);

        expect(model.id, equals('user123'));
        expect(model.email, equals('test@example.com'));
        expect(model.fullName, equals('John Doe'));
        expect(model.avatarUrl, equals('https://example.com/avatar.jpg'));
        expect(model.phone, equals('+1234567890'));
        expect(model.languageCode, equals('es'));
        expect(model.currencyCode, equals('EUR'));
        expect(model.role, equals('admin'));
        expect(model.isActive, isTrue);
        expect(model.emailVerified, isTrue);
        expect(model.createdAt.year, equals(2024));
        expect(model.createdAt.month, equals(1));
        expect(model.createdAt.day, equals(15));
      });

      test('creates instance from minimal JSON with defaults', () {
        final json = {
          'id': 'user123',
          'email': 'test@example.com',
          'created_at': testDateTimeString,
          'updated_at': testDateTimeString,
        };

        final model = UserModel.fromJson(json);

        expect(model.id, equals('user123'));
        expect(model.email, equals('test@example.com'));
        expect(model.fullName, isNull);
        expect(model.avatarUrl, isNull);
        expect(model.phone, isNull);
        expect(model.languageCode, equals('en'));
        expect(model.currencyCode, equals('USD'));
        expect(model.role, equals('customer'));
        expect(model.isActive, isTrue);
        expect(model.emailVerified, isFalse);
      });

      test('handles null optional fields', () {
        final json = {
          'id': 'user123',
          'email': 'test@example.com',
          'full_name': null,
          'avatar_url': null,
          'phone': null,
          'created_at': testDateTimeString,
          'updated_at': testDateTimeString,
        };

        final model = UserModel.fromJson(json);

        expect(model.fullName, isNull);
        expect(model.avatarUrl, isNull);
        expect(model.phone, isNull);
      });

      test('applies defaults for null language_code', () {
        final json = {
          'id': 'user123',
          'email': 'test@example.com',
          'language_code': null,
          'created_at': testDateTimeString,
          'updated_at': testDateTimeString,
        };

        final model = UserModel.fromJson(json);

        expect(model.languageCode, equals('en'));
      });

      test('applies defaults for null currency_code', () {
        final json = {
          'id': 'user123',
          'email': 'test@example.com',
          'currency_code': null,
          'created_at': testDateTimeString,
          'updated_at': testDateTimeString,
        };

        final model = UserModel.fromJson(json);

        expect(model.currencyCode, equals('USD'));
      });

      test('applies defaults for null role', () {
        final json = {
          'id': 'user123',
          'email': 'test@example.com',
          'role': null,
          'created_at': testDateTimeString,
          'updated_at': testDateTimeString,
        };

        final model = UserModel.fromJson(json);

        expect(model.role, equals('customer'));
      });

      test('applies defaults for null is_active', () {
        final json = {
          'id': 'user123',
          'email': 'test@example.com',
          'is_active': null,
          'created_at': testDateTimeString,
          'updated_at': testDateTimeString,
        };

        final model = UserModel.fromJson(json);

        expect(model.isActive, isTrue);
      });

      test('applies defaults for null email_verified', () {
        final json = {
          'id': 'user123',
          'email': 'test@example.com',
          'email_verified': null,
          'created_at': testDateTimeString,
          'updated_at': testDateTimeString,
        };

        final model = UserModel.fromJson(json);

        expect(model.emailVerified, isFalse);
      });

      test('parses ISO8601 datetime strings', () {
        final json = {
          'id': 'user123',
          'email': 'test@example.com',
          'created_at': '2024-03-15T14:30:00.000Z',
          'updated_at': '2024-03-16T16:45:30.500Z',
        };

        final model = UserModel.fromJson(json);

        expect(model.createdAt, isA<DateTime>());
        expect(model.updatedAt, isA<DateTime>());
        expect(model.createdAt.year, equals(2024));
        expect(model.createdAt.month, equals(3));
        expect(model.createdAt.day, equals(15));
      });

      test('handles all supported languages', () {
        final languages = ['en', 'es', 'fr', 'uz'];

        for (final lang in languages) {
          final json = {
            'id': 'user123',
            'email': 'test@example.com',
            'language_code': lang,
            'created_at': testDateTimeString,
            'updated_at': testDateTimeString,
          };

          final model = UserModel.fromJson(json);

          expect(model.languageCode, equals(lang));
        }
      });

      test('handles all supported currencies', () {
        final currencies = ['USD', 'EUR', 'UZS'];

        for (final currency in currencies) {
          final json = {
            'id': 'user123',
            'email': 'test@example.com',
            'currency_code': currency,
            'created_at': testDateTimeString,
            'updated_at': testDateTimeString,
          };

          final model = UserModel.fromJson(json);

          expect(model.currencyCode, equals(currency));
        }
      });

      test('handles all user roles', () {
        final roles = ['customer', 'seller', 'admin'];

        for (final role in roles) {
          final json = {
            'id': 'user123',
            'email': 'test@example.com',
            'role': role,
            'created_at': testDateTimeString,
            'updated_at': testDateTimeString,
          };

          final model = UserModel.fromJson(json);

          expect(model.role, equals(role));
        }
      });

      test('handles empty string for optional fields', () {
        final json = {
          'id': 'user123',
          'email': 'test@example.com',
          'full_name': '',
          'phone': '',
          'created_at': testDateTimeString,
          'updated_at': testDateTimeString,
        };

        final model = UserModel.fromJson(json);

        expect(model.fullName, equals(''));
        expect(model.phone, equals(''));
      });

      test('handles unicode characters in fields', () {
        final json = {
          'id': 'user123',
          'email': 'тест@example.com',
          'full_name': '张三 محمد José',
          'phone': '+998901234567',
          'created_at': testDateTimeString,
          'updated_at': testDateTimeString,
        };

        final model = UserModel.fromJson(json);

        expect(model.email, equals('тест@example.com'));
        expect(model.fullName, equals('张三 محمد José'));
        expect(model.phone, equals('+998901234567'));
      });

      test('handles special characters in fields', () {
        final json = {
          'id': 'user-123_test',
          'email': 'test+tag@example.com',
          'full_name': 'John "Johnny" O\'Doe',
          'created_at': testDateTimeString,
          'updated_at': testDateTimeString,
        };

        final model = UserModel.fromJson(json);

        expect(model.id, equals('user-123_test'));
        expect(model.email, equals('test+tag@example.com'));
        expect(model.fullName, equals('John "Johnny" O\'Doe'));
      });
    });

    group('toJson', () {
      test('converts complete model to JSON', () {
        final model = UserModel(
          id: 'user123',
          email: 'test@example.com',
          fullName: 'John Doe',
          avatarUrl: 'https://example.com/avatar.jpg',
          phone: '+1234567890',
          languageCode: 'es',
          currencyCode: 'EUR',
          role: 'admin',
          isActive: true,
          emailVerified: true,
          createdAt: testDateTime,
          updatedAt: testDateTime,
        );

        final json = model.toJson();

        expect(json['id'], equals('user123'));
        expect(json['email'], equals('test@example.com'));
        expect(json['full_name'], equals('John Doe'));
        expect(json['avatar_url'], equals('https://example.com/avatar.jpg'));
        expect(json['phone'], equals('+1234567890'));
        expect(json['language_code'], equals('es'));
        expect(json['currency_code'], equals('EUR'));
        expect(json['role'], equals('admin'));
        expect(json['is_active'], isTrue);
        expect(json['email_verified'], isTrue);
        expect(json['created_at'], isA<String>());
        expect(json['updated_at'], isA<String>());
      });

      test('converts minimal model to JSON with nulls', () {
        final model = UserModel(
          id: 'user123',
          email: 'test@example.com',
          createdAt: testDateTime,
          updatedAt: testDateTime,
        );

        final json = model.toJson();

        expect(json['id'], equals('user123'));
        expect(json['email'], equals('test@example.com'));
        expect(json['full_name'], isNull);
        expect(json['avatar_url'], isNull);
        expect(json['phone'], isNull);
        expect(json['language_code'], equals('en'));
        expect(json['currency_code'], equals('USD'));
        expect(json['role'], equals('customer'));
        expect(json['is_active'], isTrue);
        expect(json['email_verified'], isFalse);
      });

      test('converts DateTime to ISO8601 string', () {
        final model = UserModel(
          id: 'user123',
          email: 'test@example.com',
          createdAt: DateTime(2024, 3, 15, 10, 30, 45),
          updatedAt: DateTime(2024, 3, 16, 11, 35, 50),
        );

        final json = model.toJson();

        expect(json['created_at'], isA<String>());
        expect(json['updated_at'], isA<String>());
        expect(json['created_at'], contains('2024'));
        expect(json['created_at'], contains('03'));
        expect(json['created_at'], contains('15'));
      });

      test('uses snake_case for field names', () {
        final model = UserModel(
          id: 'user123',
          email: 'test@example.com',
          fullName: 'Test',
          avatarUrl: 'url',
          languageCode: 'en',
          currencyCode: 'USD',
          isActive: true,
          emailVerified: false,
          createdAt: testDateTime,
          updatedAt: testDateTime,
        );

        final json = model.toJson();

        expect(json.containsKey('full_name'), isTrue);
        expect(json.containsKey('avatar_url'), isTrue);
        expect(json.containsKey('language_code'), isTrue);
        expect(json.containsKey('currency_code'), isTrue);
        expect(json.containsKey('is_active'), isTrue);
        expect(json.containsKey('email_verified'), isTrue);
        expect(json.containsKey('created_at'), isTrue);
        expect(json.containsKey('updated_at'), isTrue);

        // Should not have camelCase keys
        expect(json.containsKey('fullName'), isFalse);
        expect(json.containsKey('avatarUrl'), isFalse);
        expect(json.containsKey('languageCode'), isFalse);
        expect(json.containsKey('currencyCode'), isFalse);
        expect(json.containsKey('isActive'), isFalse);
        expect(json.containsKey('emailVerified'), isFalse);
        expect(json.containsKey('createdAt'), isFalse);
        expect(json.containsKey('updatedAt'), isFalse);
      });

      test('preserves unicode characters', () {
        final model = UserModel(
          id: 'user123',
          email: 'тест@example.com',
          fullName: '张三 محمد José',
          createdAt: testDateTime,
          updatedAt: testDateTime,
        );

        final json = model.toJson();

        expect(json['email'], equals('тест@example.com'));
        expect(json['full_name'], equals('张三 محمد José'));
      });

      test('preserves special characters', () {
        final model = UserModel(
          id: 'user-123_test',
          email: 'test+tag@example.com',
          fullName: 'John "Johnny" O\'Doe',
          createdAt: testDateTime,
          updatedAt: testDateTime,
        );

        final json = model.toJson();

        expect(json['id'], equals('user-123_test'));
        expect(json['email'], equals('test+tag@example.com'));
        expect(json['full_name'], equals('John "Johnny" O\'Doe'));
      });
    });

    group('JSON Roundtrip', () {
      test('fromJson -> toJson preserves all data', () {
        final originalJson = {
          'id': 'user123',
          'email': 'test@example.com',
          'full_name': 'John Doe',
          'avatar_url': 'https://example.com/avatar.jpg',
          'phone': '+1234567890',
          'language_code': 'es',
          'currency_code': 'EUR',
          'role': 'admin',
          'is_active': true,
          'email_verified': true,
          'created_at': testDateTimeString,
          'updated_at': testDateTimeString,
        };

        final model = UserModel.fromJson(originalJson);
        final resultJson = model.toJson();

        expect(resultJson['id'], equals(originalJson['id']));
        expect(resultJson['email'], equals(originalJson['email']));
        expect(resultJson['full_name'], equals(originalJson['full_name']));
        expect(resultJson['avatar_url'], equals(originalJson['avatar_url']));
        expect(resultJson['phone'], equals(originalJson['phone']));
        expect(resultJson['language_code'], equals(originalJson['language_code']));
        expect(resultJson['currency_code'], equals(originalJson['currency_code']));
        expect(resultJson['role'], equals(originalJson['role']));
        expect(resultJson['is_active'], equals(originalJson['is_active']));
        expect(resultJson['email_verified'], equals(originalJson['email_verified']));
      });

      test('fromJson -> toJson -> fromJson produces equivalent model', () {
        final originalJson = {
          'id': 'user123',
          'email': 'test@example.com',
          'full_name': 'John Doe',
          'avatar_url': 'https://example.com/avatar.jpg',
          'phone': '+1234567890',
          'language_code': 'fr',
          'currency_code': 'EUR',
          'role': 'seller',
          'is_active': false,
          'email_verified': true,
          'created_at': testDateTimeString,
          'updated_at': testDateTimeString,
        };

        final model1 = UserModel.fromJson(originalJson);
        final intermediateJson = model1.toJson();
        final model2 = UserModel.fromJson(intermediateJson);

        expect(model2.id, equals(model1.id));
        expect(model2.email, equals(model1.email));
        expect(model2.fullName, equals(model1.fullName));
        expect(model2.avatarUrl, equals(model1.avatarUrl));
        expect(model2.phone, equals(model1.phone));
        expect(model2.languageCode, equals(model1.languageCode));
        expect(model2.currencyCode, equals(model1.currencyCode));
        expect(model2.role, equals(model1.role));
        expect(model2.isActive, equals(model1.isActive));
        expect(model2.emailVerified, equals(model1.emailVerified));
      });

      test('roundtrip with minimal data', () {
        final originalJson = {
          'id': 'user123',
          'email': 'test@example.com',
          'created_at': testDateTimeString,
          'updated_at': testDateTimeString,
        };

        final model1 = UserModel.fromJson(originalJson);
        final intermediateJson = model1.toJson();
        final model2 = UserModel.fromJson(intermediateJson);

        expect(model2.id, equals(model1.id));
        expect(model2.email, equals(model1.email));
        expect(model2.languageCode, equals(model1.languageCode));
        expect(model2.currencyCode, equals(model1.currencyCode));
        expect(model2.role, equals(model1.role));
      });
    });

    group('fromEntity', () {
      test('creates UserModel from UserEntity', () {
        final entity = UserEntity(
          id: 'user123',
          email: 'test@example.com',
          fullName: 'John Doe',
          avatarUrl: 'https://example.com/avatar.jpg',
          phone: '+1234567890',
          languageCode: 'es',
          currencyCode: 'EUR',
          role: 'admin',
          isActive: true,
          emailVerified: true,
          createdAt: testDateTime,
          updatedAt: testDateTime,
        );

        final model = UserModel.fromEntity(entity);

        expect(model.id, equals(entity.id));
        expect(model.email, equals(entity.email));
        expect(model.fullName, equals(entity.fullName));
        expect(model.avatarUrl, equals(entity.avatarUrl));
        expect(model.phone, equals(entity.phone));
        expect(model.languageCode, equals(entity.languageCode));
        expect(model.currencyCode, equals(entity.currencyCode));
        expect(model.role, equals(entity.role));
        expect(model.isActive, equals(entity.isActive));
        expect(model.emailVerified, equals(entity.emailVerified));
        expect(model.createdAt, equals(entity.createdAt));
        expect(model.updatedAt, equals(entity.updatedAt));
      });

      test('creates UserModel from minimal UserEntity', () {
        final entity = UserEntity(
          id: 'user123',
          email: 'test@example.com',
          createdAt: testDateTime,
          updatedAt: testDateTime,
        );

        final model = UserModel.fromEntity(entity);

        expect(model.id, equals('user123'));
        expect(model.email, equals('test@example.com'));
        expect(model.fullName, isNull);
        expect(model.languageCode, equals('en'));
        expect(model.currencyCode, equals('USD'));
        expect(model.role, equals('customer'));
      });

      test('preserves all optional fields from entity', () {
        final entity = UserEntity(
          id: 'user123',
          email: 'test@example.com',
          fullName: null,
          avatarUrl: null,
          phone: null,
          createdAt: testDateTime,
          updatedAt: testDateTime,
        );

        final model = UserModel.fromEntity(entity);

        expect(model.fullName, isNull);
        expect(model.avatarUrl, isNull);
        expect(model.phone, isNull);
      });
    });

    group('toEntity', () {
      test('converts UserModel to UserEntity', () {
        final model = UserModel(
          id: 'user123',
          email: 'test@example.com',
          fullName: 'John Doe',
          avatarUrl: 'https://example.com/avatar.jpg',
          phone: '+1234567890',
          languageCode: 'es',
          currencyCode: 'EUR',
          role: 'admin',
          isActive: true,
          emailVerified: true,
          createdAt: testDateTime,
          updatedAt: testDateTime,
        );

        final entity = model.toEntity();

        expect(entity.id, equals(model.id));
        expect(entity.email, equals(model.email));
        expect(entity.fullName, equals(model.fullName));
        expect(entity.avatarUrl, equals(model.avatarUrl));
        expect(entity.phone, equals(model.phone));
        expect(entity.languageCode, equals(model.languageCode));
        expect(entity.currencyCode, equals(model.currencyCode));
        expect(entity.role, equals(model.role));
        expect(entity.isActive, equals(model.isActive));
        expect(entity.emailVerified, equals(model.emailVerified));
        expect(entity.createdAt, equals(model.createdAt));
        expect(entity.updatedAt, equals(model.updatedAt));
      });

      test('converts minimal UserModel to UserEntity', () {
        final model = UserModel(
          id: 'user123',
          email: 'test@example.com',
          createdAt: testDateTime,
          updatedAt: testDateTime,
        );

        final entity = model.toEntity();

        expect(entity.id, equals('user123'));
        expect(entity.email, equals('test@example.com'));
        expect(entity.fullName, isNull);
      });

      test('entity is instance of UserEntity', () {
        final model = UserModel(
          id: 'user123',
          email: 'test@example.com',
          createdAt: testDateTime,
          updatedAt: testDateTime,
        );

        final entity = model.toEntity();

        expect(entity, isA<UserEntity>());
        expect(entity is UserModel, isFalse);
      });
    });

    group('Entity-Model Conversion Roundtrip', () {
      test('fromEntity -> toEntity preserves all data', () {
        final originalEntity = UserEntity(
          id: 'user123',
          email: 'test@example.com',
          fullName: 'John Doe',
          avatarUrl: 'https://example.com/avatar.jpg',
          phone: '+1234567890',
          languageCode: 'fr',
          currencyCode: 'EUR',
          role: 'seller',
          isActive: false,
          emailVerified: true,
          createdAt: testDateTime,
          updatedAt: testDateTime,
        );

        final model = UserModel.fromEntity(originalEntity);
        final resultEntity = model.toEntity();

        expect(resultEntity.id, equals(originalEntity.id));
        expect(resultEntity.email, equals(originalEntity.email));
        expect(resultEntity.fullName, equals(originalEntity.fullName));
        expect(resultEntity.avatarUrl, equals(originalEntity.avatarUrl));
        expect(resultEntity.phone, equals(originalEntity.phone));
        expect(resultEntity.languageCode, equals(originalEntity.languageCode));
        expect(resultEntity.currencyCode, equals(originalEntity.currencyCode));
        expect(resultEntity.role, equals(originalEntity.role));
        expect(resultEntity.isActive, equals(originalEntity.isActive));
        expect(resultEntity.emailVerified, equals(originalEntity.emailVerified));
      });
    });

    group('copyWith', () {
      test('creates copy with updated single field', () {
        final original = UserModel(
          id: 'user123',
          email: 'test@example.com',
          fullName: 'John Doe',
          createdAt: testDateTime,
          updatedAt: testDateTime,
        );

        final updated = original.copyWith(fullName: 'Jane Doe');

        expect(updated.id, equals(original.id));
        expect(updated.email, equals(original.email));
        expect(updated.fullName, equals('Jane Doe'));
        expect(updated.createdAt, equals(original.createdAt));
      });

      test('creates copy with updated multiple fields', () {
        final original = UserModel(
          id: 'user123',
          email: 'test@example.com',
          fullName: 'John Doe',
          languageCode: 'en',
          currencyCode: 'USD',
          createdAt: testDateTime,
          updatedAt: testDateTime,
        );

        final updated = original.copyWith(
          fullName: 'Jane Doe',
          languageCode: 'es',
          currencyCode: 'EUR',
        );

        expect(updated.fullName, equals('Jane Doe'));
        expect(updated.languageCode, equals('es'));
        expect(updated.currencyCode, equals('EUR'));
        expect(updated.id, equals(original.id));
        expect(updated.email, equals(original.email));
      });

      test('creates copy without changes when no parameters provided', () {
        final original = UserModel(
          id: 'user123',
          email: 'test@example.com',
          fullName: 'John Doe',
          createdAt: testDateTime,
          updatedAt: testDateTime,
        );

        final copy = original.copyWith();

        expect(copy.id, equals(original.id));
        expect(copy.email, equals(original.email));
        expect(copy.fullName, equals(original.fullName));
        expect(copy.languageCode, equals(original.languageCode));
      });

      test('creates copy with all fields updated', () {
        final original = UserModel(
          id: 'user123',
          email: 'test@example.com',
          fullName: 'John Doe',
          avatarUrl: 'https://example.com/old.jpg',
          phone: '+1111111111',
          languageCode: 'en',
          currencyCode: 'USD',
          role: 'customer',
          isActive: true,
          emailVerified: false,
          createdAt: testDateTime,
          updatedAt: testDateTime,
        );

        final newDateTime = DateTime(2024, 6, 15);

        final updated = original.copyWith(
          id: 'user456',
          email: 'new@example.com',
          fullName: 'Jane Doe',
          avatarUrl: 'https://example.com/new.jpg',
          phone: '+2222222222',
          languageCode: 'es',
          currencyCode: 'EUR',
          role: 'admin',
          isActive: false,
          emailVerified: true,
          createdAt: newDateTime,
          updatedAt: newDateTime,
        );

        expect(updated.id, equals('user456'));
        expect(updated.email, equals('new@example.com'));
        expect(updated.fullName, equals('Jane Doe'));
        expect(updated.avatarUrl, equals('https://example.com/new.jpg'));
        expect(updated.phone, equals('+2222222222'));
        expect(updated.languageCode, equals('es'));
        expect(updated.currencyCode, equals('EUR'));
        expect(updated.role, equals('admin'));
        expect(updated.isActive, isFalse);
        expect(updated.emailVerified, isTrue);
        expect(updated.createdAt, equals(newDateTime));
        expect(updated.updatedAt, equals(newDateTime));
      });

      test('original instance remains unchanged after copyWith', () {
        final original = UserModel(
          id: 'user123',
          email: 'test@example.com',
          fullName: 'John Doe',
          createdAt: testDateTime,
          updatedAt: testDateTime,
        );

        final originalFullName = original.fullName;
        final originalEmail = original.email;

        original.copyWith(fullName: 'Jane Doe', email: 'new@example.com');

        expect(original.fullName, equals(originalFullName));
        expect(original.email, equals(originalEmail));
      });
    });

    group('Inheritance from UserEntity', () {
      test('UserModel is a UserEntity', () {
        final model = UserModel(
          id: 'user123',
          email: 'test@example.com',
          createdAt: testDateTime,
          updatedAt: testDateTime,
        );

        expect(model, isA<UserEntity>());
      });

      test('UserModel has UserEntity properties', () {
        final model = UserModel(
          id: 'user123',
          email: 'test@example.com',
          fullName: 'John Doe',
          createdAt: testDateTime,
          updatedAt: testDateTime,
        );

        expect(model.displayName, equals('John Doe'));
        expect(model.isCustomer, isTrue);
        expect(model.isSeller, isFalse);
        expect(model.isAdmin, isFalse);
      });

      test('UserModel with role admin', () {
        final model = UserModel(
          id: 'user123',
          email: 'test@example.com',
          role: 'admin',
          createdAt: testDateTime,
          updatedAt: testDateTime,
        );

        expect(model.isAdmin, isTrue);
        expect(model.isCustomer, isFalse);
        expect(model.isSeller, isFalse);
      });

      test('UserModel with role seller', () {
        final model = UserModel(
          id: 'user123',
          email: 'test@example.com',
          role: 'seller',
          createdAt: testDateTime,
          updatedAt: testDateTime,
        );

        expect(model.isSeller, isTrue);
        expect(model.isCustomer, isFalse);
        expect(model.isAdmin, isFalse);
      });

      test('displayName returns email prefix when fullName is null', () {
        final model = UserModel(
          id: 'user123',
          email: 'john.doe@example.com',
          createdAt: testDateTime,
          updatedAt: testDateTime,
        );

        expect(model.displayName, equals('john.doe'));
      });
    });

    group('Edge Cases', () {
      test('handles very long strings', () {
        final longString = 'A' * 10000;
        final json = {
          'id': longString,
          'email': 'test@example.com',
          'full_name': longString,
          'created_at': testDateTimeString,
          'updated_at': testDateTimeString,
        };

        final model = UserModel.fromJson(json);

        expect(model.id.length, equals(10000));
        expect(model.fullName!.length, equals(10000));
      });

      test('handles DateTime with milliseconds', () {
        final preciseDateTime = DateTime(2024, 1, 15, 10, 30, 45, 123);
        final model = UserModel(
          id: 'user123',
          email: 'test@example.com',
          createdAt: preciseDateTime,
          updatedAt: preciseDateTime,
        );

        final json = model.toJson();
        final recreated = UserModel.fromJson(json);

        expect(recreated.createdAt.year, equals(preciseDateTime.year));
        expect(recreated.createdAt.month, equals(preciseDateTime.month));
        expect(recreated.createdAt.day, equals(preciseDateTime.day));
        expect(recreated.createdAt.hour, equals(preciseDateTime.hour));
        expect(recreated.createdAt.minute, equals(preciseDateTime.minute));
        expect(recreated.createdAt.second, equals(preciseDateTime.second));
      });

      test('handles boolean false values correctly', () {
        final json = {
          'id': 'user123',
          'email': 'test@example.com',
          'is_active': false,
          'email_verified': false,
          'created_at': testDateTimeString,
          'updated_at': testDateTimeString,
        };

        final model = UserModel.fromJson(json);

        expect(model.isActive, isFalse);
        expect(model.emailVerified, isFalse);
      });

      test('handles empty optional strings', () {
        final model = UserModel(
          id: 'user123',
          email: 'test@example.com',
          fullName: '',
          phone: '',
          createdAt: testDateTime,
          updatedAt: testDateTime,
        );

        final json = model.toJson();

        expect(json['full_name'], equals(''));
        expect(json['phone'], equals(''));
      });
    });
  });
}
