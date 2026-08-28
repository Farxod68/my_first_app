import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_first_app/data/repositories/auth_repository_impl.dart';
import 'package:my_first_app/data/models/user_model.dart';
import 'package:my_first_app/domain/entities/user_entity.dart';
import '../../../mocks/mock_auth_remote_data_source.dart';

void main() {
  group('AuthRepositoryImpl', () {
    late MockAuthRemoteDataSource mockDataSource;
    late AuthRepositoryImpl repository;

    // Test data
    final testDateTime = DateTime(2024, 1, 15, 10, 30, 0);
    final testUserModel = UserModel(
      id: 'user123',
      email: 'test@example.com',
      fullName: 'Test User',
      languageCode: 'en',
      currencyCode: 'USD',
      role: 'customer',
      isActive: true,
      emailVerified: false,
      createdAt: testDateTime,
      updatedAt: testDateTime,
    );

    setUp(() {
      mockDataSource = MockAuthRemoteDataSource();
      repository = AuthRepositoryImpl(mockDataSource);

      // Register fallback values for any() matchers
      registerFallbackValue(testUserModel);
    });

    group('Constructor', () {
      test('creates instance with data source', () {
        expect(repository, isA<AuthRepositoryImpl>());
      });

      test('implements AuthRepository interface', () {
        expect(repository, isA<AuthRepositoryImpl>());
      });
    });

    group('getCurrentUser', () {
      test('returns UserEntity when data source returns UserModel', () async {
        when(() => mockDataSource.getCurrentUser())
            .thenAnswer((_) async => testUserModel);

        final result = await repository.getCurrentUser();

        expect(result, isA<UserEntity>());
        expect(result, isNotNull);
        expect(result!.id, equals(testUserModel.id));
        expect(result.email, equals(testUserModel.email));
        expect(result.fullName, equals(testUserModel.fullName));
        verify(() => mockDataSource.getCurrentUser()).called(1);
      });

      test('returns null when data source returns null', () async {
        when(() => mockDataSource.getCurrentUser())
            .thenAnswer((_) async => null);

        final result = await repository.getCurrentUser();

        expect(result, isNull);
        verify(() => mockDataSource.getCurrentUser()).called(1);
      });

      test('converts UserModel to UserEntity correctly', () async {
        when(() => mockDataSource.getCurrentUser())
            .thenAnswer((_) async => testUserModel);

        final result = await repository.getCurrentUser();

        expect(result!.id, equals(testUserModel.id));
        expect(result.email, equals(testUserModel.email));
        expect(result.fullName, equals(testUserModel.fullName));
        expect(result.languageCode, equals(testUserModel.languageCode));
        expect(result.currencyCode, equals(testUserModel.currencyCode));
        expect(result.role, equals(testUserModel.role));
        expect(result.isActive, equals(testUserModel.isActive));
        expect(result.emailVerified, equals(testUserModel.emailVerified));
      });

      test('propagates exception from data source', () async {
        when(() => mockDataSource.getCurrentUser())
            .thenThrow(Exception('Network error'));

        expect(
          () => repository.getCurrentUser(),
          throwsA(isA<Exception>()),
        );
        verify(() => mockDataSource.getCurrentUser()).called(1);
      });

      test('can be called multiple times', () async {
        when(() => mockDataSource.getCurrentUser())
            .thenAnswer((_) async => testUserModel);

        await repository.getCurrentUser();
        await repository.getCurrentUser();
        await repository.getCurrentUser();

        verify(() => mockDataSource.getCurrentUser()).called(3);
      });
    });

    group('signUpWithEmail', () {
      test('returns UserEntity on successful sign up', () async {
        when(() => mockDataSource.signUp(
              email: any(named: 'email'),
              password: any(named: 'password'),
              fullName: any(named: 'fullName'),
            )).thenAnswer((_) async => testUserModel);

        final result = await repository.signUpWithEmail(
          email: 'test@example.com',
          password: 'password123',
          fullName: 'Test User',
        );

        expect(result, isA<UserEntity>());
        expect(result.id, equals(testUserModel.id));
        expect(result.email, equals(testUserModel.email));
        verify(() => mockDataSource.signUp(
              email: 'test@example.com',
              password: 'password123',
              fullName: 'Test User',
            )).called(1);
      });

      test('passes all parameters to data source', () async {
        when(() => mockDataSource.signUp(
              email: any(named: 'email'),
              password: any(named: 'password'),
              fullName: any(named: 'fullName'),
            )).thenAnswer((_) async => testUserModel);

        await repository.signUpWithEmail(
          email: 'user@test.com',
          password: 'secure123',
          fullName: 'John Doe',
        );

        verify(() => mockDataSource.signUp(
              email: 'user@test.com',
              password: 'secure123',
              fullName: 'John Doe',
            )).called(1);
      });

      test('handles sign up without fullName', () async {
        when(() => mockDataSource.signUp(
              email: any(named: 'email'),
              password: any(named: 'password'),
              fullName: any(named: 'fullName'),
            )).thenAnswer((_) async => testUserModel);

        await repository.signUpWithEmail(
          email: 'test@example.com',
          password: 'password123',
        );

        verify(() => mockDataSource.signUp(
              email: 'test@example.com',
              password: 'password123',
              fullName: null,
            )).called(1);
      });

      test('converts UserModel to UserEntity', () async {
        final modelWithAllFields = UserModel(
          id: 'user456',
          email: 'full@example.com',
          fullName: 'Full Name',
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

        when(() => mockDataSource.signUp(
              email: any(named: 'email'),
              password: any(named: 'password'),
              fullName: any(named: 'fullName'),
            )).thenAnswer((_) async => modelWithAllFields);

        final result = await repository.signUpWithEmail(
          email: 'test@example.com',
          password: 'password123',
        );

        expect(result.id, equals('user456'));
        expect(result.email, equals('full@example.com'));
        expect(result.fullName, equals('Full Name'));
        expect(result.avatarUrl, equals('https://example.com/avatar.jpg'));
        expect(result.phone, equals('+1234567890'));
        expect(result.languageCode, equals('es'));
        expect(result.currencyCode, equals('EUR'));
        expect(result.role, equals('admin'));
      });

      test('propagates exception from data source', () async {
        when(() => mockDataSource.signUp(
              email: any(named: 'email'),
              password: any(named: 'password'),
              fullName: any(named: 'fullName'),
            )).thenThrow(Exception('Sign up failed'));

        expect(
          () => repository.signUpWithEmail(
            email: 'test@example.com',
            password: 'password123',
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('handles empty email', () async {
        when(() => mockDataSource.signUp(
              email: any(named: 'email'),
              password: any(named: 'password'),
              fullName: any(named: 'fullName'),
            )).thenAnswer((_) async => testUserModel);

        await repository.signUpWithEmail(
          email: '',
          password: 'password123',
        );

        verify(() => mockDataSource.signUp(
              email: '',
              password: 'password123',
              fullName: null,
            )).called(1);
      });

      test('handles empty password', () async {
        when(() => mockDataSource.signUp(
              email: any(named: 'email'),
              password: any(named: 'password'),
              fullName: any(named: 'fullName'),
            )).thenAnswer((_) async => testUserModel);

        await repository.signUpWithEmail(
          email: 'test@example.com',
          password: '',
        );

        verify(() => mockDataSource.signUp(
              email: 'test@example.com',
              password: '',
              fullName: null,
            )).called(1);
      });
    });

    group('signInWithEmail', () {
      test('returns UserEntity on successful sign in', () async {
        when(() => mockDataSource.signIn(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => testUserModel);

        final result = await repository.signInWithEmail(
          email: 'test@example.com',
          password: 'password123',
        );

        expect(result, isA<UserEntity>());
        expect(result.id, equals(testUserModel.id));
        expect(result.email, equals(testUserModel.email));
        verify(() => mockDataSource.signIn(
              email: 'test@example.com',
              password: 'password123',
            )).called(1);
      });

      test('passes all parameters to data source', () async {
        when(() => mockDataSource.signIn(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => testUserModel);

        await repository.signInWithEmail(
          email: 'user@test.com',
          password: 'mypassword',
        );

        verify(() => mockDataSource.signIn(
              email: 'user@test.com',
              password: 'mypassword',
            )).called(1);
      });

      test('converts UserModel to UserEntity', () async {
        when(() => mockDataSource.signIn(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => testUserModel);

        final result = await repository.signInWithEmail(
          email: 'test@example.com',
          password: 'password123',
        );

        expect(result.id, equals(testUserModel.id));
        expect(result.email, equals(testUserModel.email));
        expect(result.fullName, equals(testUserModel.fullName));
      });

      test('propagates exception from data source', () async {
        when(() => mockDataSource.signIn(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenThrow(Exception('Invalid credentials'));

        expect(
          () => repository.signInWithEmail(
            email: 'test@example.com',
            password: 'wrongpassword',
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('handles empty email', () async {
        when(() => mockDataSource.signIn(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => testUserModel);

        await repository.signInWithEmail(
          email: '',
          password: 'password123',
        );

        verify(() => mockDataSource.signIn(
              email: '',
              password: 'password123',
            )).called(1);
      });

      test('handles empty password', () async {
        when(() => mockDataSource.signIn(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => testUserModel);

        await repository.signInWithEmail(
          email: 'test@example.com',
          password: '',
        );

        verify(() => mockDataSource.signIn(
              email: 'test@example.com',
              password: '',
            )).called(1);
      });

      test('can be called multiple times with different credentials', () async {
        when(() => mockDataSource.signIn(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => testUserModel);

        await repository.signInWithEmail(
          email: 'user1@example.com',
          password: 'pass1',
        );
        await repository.signInWithEmail(
          email: 'user2@example.com',
          password: 'pass2',
        );

        verify(() => mockDataSource.signIn(
              email: 'user1@example.com',
              password: 'pass1',
            )).called(1);
        verify(() => mockDataSource.signIn(
              email: 'user2@example.com',
              password: 'pass2',
            )).called(1);
      });
    });

    group('signOut', () {
      test('completes successfully when data source succeeds', () async {
        when(() => mockDataSource.signOut()).thenAnswer((_) async {});

        await repository.signOut();

        verify(() => mockDataSource.signOut()).called(1);
      });

      test('returns Future<void>', () async {
        when(() => mockDataSource.signOut()).thenAnswer((_) async {});

        final result = repository.signOut();

        expect(result, isA<Future<void>>());
        await result;
      });

      test('propagates exception from data source', () async {
        when(() => mockDataSource.signOut())
            .thenThrow(Exception('Sign out failed'));

        expect(
          () => repository.signOut(),
          throwsA(isA<Exception>()),
        );
        verify(() => mockDataSource.signOut()).called(1);
      });

      test('can be called multiple times', () async {
        when(() => mockDataSource.signOut()).thenAnswer((_) async {});

        await repository.signOut();
        await repository.signOut();
        await repository.signOut();

        verify(() => mockDataSource.signOut()).called(3);
      });
    });

    group('resetPassword', () {
      test('completes successfully when data source succeeds', () async {
        when(() => mockDataSource.resetPassword(any()))
            .thenAnswer((_) async {});

        await repository.resetPassword('test@example.com');

        verify(() => mockDataSource.resetPassword('test@example.com'))
            .called(1);
      });

      test('passes email to data source', () async {
        when(() => mockDataSource.resetPassword(any()))
            .thenAnswer((_) async {});

        await repository.resetPassword('user@test.com');

        verify(() => mockDataSource.resetPassword('user@test.com')).called(1);
      });

      test('returns Future<void>', () async {
        when(() => mockDataSource.resetPassword(any()))
            .thenAnswer((_) async {});

        final result = repository.resetPassword('test@example.com');

        expect(result, isA<Future<void>>());
        await result;
      });

      test('propagates exception from data source', () async {
        when(() => mockDataSource.resetPassword(any()))
            .thenThrow(Exception('Reset failed'));

        expect(
          () => repository.resetPassword('test@example.com'),
          throwsA(isA<Exception>()),
        );
      });

      test('handles empty email', () async {
        when(() => mockDataSource.resetPassword(any()))
            .thenAnswer((_) async {});

        await repository.resetPassword('');

        verify(() => mockDataSource.resetPassword('')).called(1);
      });

      test('handles special characters in email', () async {
        when(() => mockDataSource.resetPassword(any()))
            .thenAnswer((_) async {});

        await repository.resetPassword('test+tag@example.com');

        verify(() => mockDataSource.resetPassword('test+tag@example.com'))
            .called(1);
      });
    });

    group('updateProfile', () {
      test('returns UserEntity on successful update', () async {
        final updatedModel = testUserModel.copyWith(
          fullName: 'Updated Name',
        );

        when(() => mockDataSource.getCurrentUser())
            .thenAnswer((_) async => testUserModel);
        when(() => mockDataSource.updateProfile(
              userId: any(named: 'userId'),
              fullName: any(named: 'fullName'),
              avatarUrl: any(named: 'avatarUrl'),
              phone: any(named: 'phone'),
              languageCode: any(named: 'languageCode'),
              currencyCode: any(named: 'currencyCode'),
            )).thenAnswer((_) async => updatedModel);

        final result = await repository.updateProfile(
          fullName: 'Updated Name',
        );

        expect(result, isA<UserEntity>());
        expect(result.fullName, equals('Updated Name'));
        verify(() => mockDataSource.getCurrentUser()).called(1);
        verify(() => mockDataSource.updateProfile(
              userId: testUserModel.id,
              fullName: 'Updated Name',
              avatarUrl: null,
              phone: null,
              languageCode: null,
              currencyCode: null,
            )).called(1);
      });

      test('throws exception when no user is authenticated', () async {
        when(() => mockDataSource.getCurrentUser())
            .thenAnswer((_) async => null);

        expect(
          () => repository.updateProfile(fullName: 'New Name'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('No user authenticated'),
          )),
        );
        verify(() => mockDataSource.getCurrentUser()).called(1);
        verifyNever(() => mockDataSource.updateProfile(
              userId: any(named: 'userId'),
              fullName: any(named: 'fullName'),
              avatarUrl: any(named: 'avatarUrl'),
              phone: any(named: 'phone'),
              languageCode: any(named: 'languageCode'),
              currencyCode: any(named: 'currencyCode'),
            ));
      });

      test('passes all parameters to data source', () async {
        when(() => mockDataSource.getCurrentUser())
            .thenAnswer((_) async => testUserModel);
        when(() => mockDataSource.updateProfile(
              userId: any(named: 'userId'),
              fullName: any(named: 'fullName'),
              avatarUrl: any(named: 'avatarUrl'),
              phone: any(named: 'phone'),
              languageCode: any(named: 'languageCode'),
              currencyCode: any(named: 'currencyCode'),
            )).thenAnswer((_) async => testUserModel);

        await repository.updateProfile(
          fullName: 'John Doe',
          avatarUrl: 'https://example.com/avatar.jpg',
          phone: '+1234567890',
          languageCode: 'es',
          currencyCode: 'EUR',
        );

        verify(() => mockDataSource.updateProfile(
              userId: testUserModel.id,
              fullName: 'John Doe',
              avatarUrl: 'https://example.com/avatar.jpg',
              phone: '+1234567890',
              languageCode: 'es',
              currencyCode: 'EUR',
            )).called(1);
      });

      test('handles partial update with some null parameters', () async {
        when(() => mockDataSource.getCurrentUser())
            .thenAnswer((_) async => testUserModel);
        when(() => mockDataSource.updateProfile(
              userId: any(named: 'userId'),
              fullName: any(named: 'fullName'),
              avatarUrl: any(named: 'avatarUrl'),
              phone: any(named: 'phone'),
              languageCode: any(named: 'languageCode'),
              currencyCode: any(named: 'currencyCode'),
            )).thenAnswer((_) async => testUserModel);

        await repository.updateProfile(
          fullName: 'New Name',
          languageCode: 'fr',
        );

        verify(() => mockDataSource.updateProfile(
              userId: testUserModel.id,
              fullName: 'New Name',
              avatarUrl: null,
              phone: null,
              languageCode: 'fr',
              currencyCode: null,
            )).called(1);
      });

      test('handles update with no parameters', () async {
        when(() => mockDataSource.getCurrentUser())
            .thenAnswer((_) async => testUserModel);
        when(() => mockDataSource.updateProfile(
              userId: any(named: 'userId'),
              fullName: any(named: 'fullName'),
              avatarUrl: any(named: 'avatarUrl'),
              phone: any(named: 'phone'),
              languageCode: any(named: 'languageCode'),
              currencyCode: any(named: 'currencyCode'),
            )).thenAnswer((_) async => testUserModel);

        await repository.updateProfile();

        verify(() => mockDataSource.updateProfile(
              userId: testUserModel.id,
              fullName: null,
              avatarUrl: null,
              phone: null,
              languageCode: null,
              currencyCode: null,
            )).called(1);
      });

      test('converts returned UserModel to UserEntity', () async {
        final updatedModel = UserModel(
          id: testUserModel.id,
          email: testUserModel.email,
          fullName: 'Updated Name',
          avatarUrl: 'https://example.com/new.jpg',
          languageCode: 'fr',
          currencyCode: 'EUR',
          createdAt: testDateTime,
          updatedAt: testDateTime,
        );

        when(() => mockDataSource.getCurrentUser())
            .thenAnswer((_) async => testUserModel);
        when(() => mockDataSource.updateProfile(
              userId: any(named: 'userId'),
              fullName: any(named: 'fullName'),
              avatarUrl: any(named: 'avatarUrl'),
              phone: any(named: 'phone'),
              languageCode: any(named: 'languageCode'),
              currencyCode: any(named: 'currencyCode'),
            )).thenAnswer((_) async => updatedModel);

        final result = await repository.updateProfile(fullName: 'Updated Name');

        expect(result.fullName, equals('Updated Name'));
        expect(result.avatarUrl, equals('https://example.com/new.jpg'));
        expect(result.languageCode, equals('fr'));
        expect(result.currencyCode, equals('EUR'));
      });

      test('propagates exception from getCurrentUser', () async {
        when(() => mockDataSource.getCurrentUser())
            .thenThrow(Exception('Failed to get user'));

        expect(
          () => repository.updateProfile(fullName: 'New Name'),
          throwsA(isA<Exception>()),
        );
      });

      test('propagates exception from updateProfile', () async {
        when(() => mockDataSource.getCurrentUser())
            .thenAnswer((_) async => testUserModel);
        when(() => mockDataSource.updateProfile(
              userId: any(named: 'userId'),
              fullName: any(named: 'fullName'),
              avatarUrl: any(named: 'avatarUrl'),
              phone: any(named: 'phone'),
              languageCode: any(named: 'languageCode'),
              currencyCode: any(named: 'currencyCode'),
            )).thenThrow(Exception('Update failed'));

        expect(
          () => repository.updateProfile(fullName: 'New Name'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('authStateChanges', () {
      test('returns Stream<UserEntity?>', () {
        final controller = StreamController<UserModel?>();
        when(() => mockDataSource.authStateChanges)
            .thenAnswer((_) => controller.stream);

        final stream = repository.authStateChanges;

        expect(stream, isA<Stream<UserEntity?>>());
        controller.close();
      });

      test('maps UserModel to UserEntity in stream', () async {
        final controller = StreamController<UserModel?>();
        when(() => mockDataSource.authStateChanges)
            .thenAnswer((_) => controller.stream);

        final stream = repository.authStateChanges;
        final future = stream.first;

        controller.add(testUserModel);

        final result = await future;

        expect(result, isA<UserEntity>());
        expect(result!.id, equals(testUserModel.id));
        expect(result.email, equals(testUserModel.email));

        controller.close();
      });

      test('maps null to null in stream', () async {
        final controller = StreamController<UserModel?>();
        when(() => mockDataSource.authStateChanges)
            .thenAnswer((_) => controller.stream);

        final stream = repository.authStateChanges;
        final future = stream.first;

        controller.add(null);

        final result = await future;

        expect(result, isNull);

        controller.close();
      });

      test('emits multiple values correctly', () async {
        final controller = StreamController<UserModel?>();
        when(() => mockDataSource.authStateChanges)
            .thenAnswer((_) => controller.stream);

        final stream = repository.authStateChanges;
        final results = <UserEntity?>[];

        final subscription = stream.listen((user) {
          results.add(user);
        });

        controller.add(testUserModel);
        await Future.delayed(Duration.zero);

        controller.add(null);
        await Future.delayed(Duration.zero);

        final updatedModel = testUserModel.copyWith(fullName: 'Updated');
        controller.add(updatedModel);
        await Future.delayed(Duration.zero);

        expect(results.length, equals(3));
        expect(results[0]!.id, equals(testUserModel.id));
        expect(results[1], isNull);
        expect(results[2]!.fullName, equals('Updated'));

        await subscription.cancel();
        controller.close();
      });

      test('stream can be listened to multiple times', () async {
        final controller = StreamController<UserModel?>.broadcast();
        when(() => mockDataSource.authStateChanges)
            .thenAnswer((_) => controller.stream);

        final stream = repository.authStateChanges;

        final listener1Results = <UserEntity?>[];
        final listener2Results = <UserEntity?>[];

        final sub1 = stream.listen((user) => listener1Results.add(user));
        final sub2 = stream.listen((user) => listener2Results.add(user));

        controller.add(testUserModel);
        await Future.delayed(Duration.zero);

        expect(listener1Results.length, equals(1));
        expect(listener2Results.length, equals(1));

        await sub1.cancel();
        await sub2.cancel();
        controller.close();
      });
    });

    group('isAuthenticated', () {
      test('returns true when data source returns true', () async {
        when(() => mockDataSource.isAuthenticated())
            .thenAnswer((_) async => true);

        final result = await repository.isAuthenticated();

        expect(result, isTrue);
        verify(() => mockDataSource.isAuthenticated()).called(1);
      });

      test('returns false when data source returns false', () async {
        when(() => mockDataSource.isAuthenticated())
            .thenAnswer((_) async => false);

        final result = await repository.isAuthenticated();

        expect(result, isFalse);
        verify(() => mockDataSource.isAuthenticated()).called(1);
      });

      test('delegates directly to data source', () async {
        when(() => mockDataSource.isAuthenticated())
            .thenAnswer((_) async => true);

        await repository.isAuthenticated();

        verify(() => mockDataSource.isAuthenticated()).called(1);
        verifyNoMoreInteractions(mockDataSource);
      });

      test('propagates exception from data source', () async {
        when(() => mockDataSource.isAuthenticated())
            .thenThrow(Exception('Check failed'));

        expect(
          () => repository.isAuthenticated(),
          throwsA(isA<Exception>()),
        );
      });

      test('can be called multiple times', () async {
        when(() => mockDataSource.isAuthenticated())
            .thenAnswer((_) async => true);

        await repository.isAuthenticated();
        await repository.isAuthenticated();

        verify(() => mockDataSource.isAuthenticated()).called(2);
      });
    });

    group('Error Handling', () {
      test('does not catch or modify exceptions', () async {
        when(() => mockDataSource.getCurrentUser())
            .thenThrow(Exception('Test error'));

        try {
          await repository.getCurrentUser();
          fail('Should have thrown exception');
        } catch (e) {
          expect(e.toString(), contains('Test error'));
        }
      });

      test('propagates different exception types', () async {
        when(() => mockDataSource.signIn(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenThrow(ArgumentError('Invalid argument'));

        expect(
          () => repository.signInWithEmail(
            email: 'test@example.com',
            password: 'password123',
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('Integration Scenarios', () {
      test('full authentication flow', () async {
        // Sign up
        when(() => mockDataSource.signUp(
              email: any(named: 'email'),
              password: any(named: 'password'),
              fullName: any(named: 'fullName'),
            )).thenAnswer((_) async => testUserModel);

        final signUpResult = await repository.signUpWithEmail(
          email: 'test@example.com',
          password: 'password123',
          fullName: 'Test User',
        );

        expect(signUpResult, isA<UserEntity>());

        // Sign out
        when(() => mockDataSource.signOut()).thenAnswer((_) async {});
        await repository.signOut();

        // Sign in
        when(() => mockDataSource.signIn(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => testUserModel);

        final signInResult = await repository.signInWithEmail(
          email: 'test@example.com',
          password: 'password123',
        );

        expect(signInResult, isA<UserEntity>());

        verify(() => mockDataSource.signUp(
              email: any(named: 'email'),
              password: any(named: 'password'),
              fullName: any(named: 'fullName'),
            )).called(1);
        verify(() => mockDataSource.signOut()).called(1);
        verify(() => mockDataSource.signIn(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).called(1);
      });

      test('profile update flow', () async {
        // Get current user
        when(() => mockDataSource.getCurrentUser())
            .thenAnswer((_) async => testUserModel);

        final currentUser = await repository.getCurrentUser();
        expect(currentUser, isNotNull);

        // Update profile
        final updatedModel = testUserModel.copyWith(
          fullName: 'Updated Name',
          languageCode: 'es',
        );

        when(() => mockDataSource.updateProfile(
              userId: any(named: 'userId'),
              fullName: any(named: 'fullName'),
              avatarUrl: any(named: 'avatarUrl'),
              phone: any(named: 'phone'),
              languageCode: any(named: 'languageCode'),
              currencyCode: any(named: 'currencyCode'),
            )).thenAnswer((_) async => updatedModel);

        final updated = await repository.updateProfile(
          fullName: 'Updated Name',
          languageCode: 'es',
        );

        expect(updated.fullName, equals('Updated Name'));
        expect(updated.languageCode, equals('es'));
      });
    });
  });
}
