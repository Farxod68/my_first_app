import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_first_app/presentation/providers/auth_provider.dart';
import 'package:my_first_app/domain/entities/user_entity.dart';
import '../../../mocks/mock_auth_repository.dart';
import '../../../helpers/test_data.dart';

void main() {
  group('AuthProvider', () {
    late MockAuthRepository mockAuthRepository;
    late AuthProvider provider;
    late StreamController<UserEntity?> authStateController;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      authStateController = StreamController<UserEntity?>.broadcast();

      // Default: no current user
      when(() => mockAuthRepository.getCurrentUser())
          .thenAnswer((_) async => null);
      when(() => mockAuthRepository.authStateChanges)
          .thenAnswer((_) => authStateController.stream);

      // Register fallback values for any() matchers
      registerFallbackValue(TestData.createTestUser());
    });

    tearDown(() {
      authStateController.close();
      try {
        provider.dispose();
      } catch (_) {
        // Already disposed or never initialized
      }
    });

    group('Initialization', () {
      test('constructor calls _initialize', () async {
        provider = AuthProvider(mockAuthRepository);

        await Future.delayed(Duration.zero);

        verify(() => mockAuthRepository.getCurrentUser()).called(1);
        verify(() => mockAuthRepository.authStateChanges).called(1);
      });

      test('initial state with no user', () async {
        provider = AuthProvider(mockAuthRepository);

        await Future.delayed(Duration.zero);

        expect(provider.currentUser, isNull);
        expect(provider.isAuthenticated, isFalse);
        expect(provider.isGuest, isTrue);
        expect(provider.isLoading, isFalse);
        expect(provider.isInitialized, isTrue);
        expect(provider.error, isNull);
      });

      test('loads current user during initialization', () async {
        final testUser = TestData.createTestUser();
        when(() => mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => testUser);

        provider = AuthProvider(mockAuthRepository);

        await Future.delayed(Duration.zero);

        expect(provider.currentUser, equals(testUser));
        expect(provider.isAuthenticated, isTrue);
        expect(provider.isGuest, isFalse);
      });

      test('marks as initialized after loading user', () async {
        provider = AuthProvider(mockAuthRepository);

        await Future.delayed(Duration.zero);

        expect(provider.isInitialized, isTrue);
      });

      test('handles initialization error gracefully', () async {
        when(() => mockAuthRepository.getCurrentUser())
            .thenThrow(Exception('Init failed'));

        provider = AuthProvider(mockAuthRepository);

        await Future.delayed(Duration.zero);

        expect(provider.isInitialized, isTrue);
        expect(provider.error, contains('Init failed'));
        expect(provider.currentUser, isNull);
      });

      test('subscribes to auth state changes', () async {
        provider = AuthProvider(mockAuthRepository);

        await Future.delayed(Duration.zero);

        verify(() => mockAuthRepository.authStateChanges).called(1);
      });

      test('auth state changes update current user', () async {
        provider = AuthProvider(mockAuthRepository);
        await Future.delayed(Duration.zero);

        final testUser = TestData.createTestUser();
        authStateController.add(testUser);

        await Future.delayed(Duration.zero);

        expect(provider.currentUser, equals(testUser));
        expect(provider.isAuthenticated, isTrue);
      });

      test('auth state changes notify listeners', () async {
        provider = AuthProvider(mockAuthRepository);
        await Future.delayed(Duration.zero);

        var notified = false;
        provider.addListener(() => notified = true);

        final testUser = TestData.createTestUser();
        authStateController.add(testUser);

        await Future.delayed(Duration.zero);

        expect(notified, isTrue);
      });

      test('handles auth state change error gracefully', () async {
        provider = AuthProvider(mockAuthRepository);
        await Future.delayed(Duration.zero);

        authStateController.addError(Exception('State error'));

        await Future.delayed(Duration.zero);

        // Should not crash, error is logged
        expect(() => provider.currentUser, returnsNormally);
      });
    });

    group('Getters', () {
      setUp(() async {
        provider = AuthProvider(mockAuthRepository);
        await Future.delayed(Duration.zero);
      });

      test('isAuthenticated returns false when no user', () {
        expect(provider.isAuthenticated, isFalse);
      });

      test('isAuthenticated returns true when user exists', () async {
        final testUser = TestData.createTestUser();
        authStateController.add(testUser);
        await Future.delayed(Duration.zero);

        expect(provider.isAuthenticated, isTrue);
      });

      test('isGuest returns true when no user', () {
        expect(provider.isGuest, isTrue);
      });

      test('isGuest returns false when user exists', () async {
        final testUser = TestData.createTestUser();
        authStateController.add(testUser);
        await Future.delayed(Duration.zero);

        expect(provider.isGuest, isFalse);
      });

      test('displayName returns null when no user', () {
        expect(provider.displayName, isNull);
      });

      test('displayName returns user displayName when authenticated', () async {
        final testUser = TestData.createTestUser(fullName: 'John Doe');
        authStateController.add(testUser);
        await Future.delayed(Duration.zero);

        expect(provider.displayName, equals('John Doe'));
      });

      test('email returns null when no user', () {
        expect(provider.email, isNull);
      });

      test('email returns user email when authenticated', () async {
        final testUser = TestData.createTestUser(email: 'test@example.com');
        authStateController.add(testUser);
        await Future.delayed(Duration.zero);

        expect(provider.email, equals('test@example.com'));
      });

      test('languageCode returns en by default when no user', () {
        expect(provider.languageCode, equals('en'));
      });

      test('languageCode returns user languageCode when authenticated', () async {
        final testUser = TestData.createTestUser(languageCode: 'es');
        authStateController.add(testUser);
        await Future.delayed(Duration.zero);

        expect(provider.languageCode, equals('es'));
      });

      test('currencyCode returns USD by default when no user', () {
        expect(provider.currencyCode, equals('USD'));
      });

      test('currencyCode returns user currencyCode when authenticated', () async {
        final testUser = TestData.createTestUser(currencyCode: 'EUR');
        authStateController.add(testUser);
        await Future.delayed(Duration.zero);

        expect(provider.currencyCode, equals('EUR'));
      });
    });

    group('getUserPreferences', () {
      setUp(() async {
        provider = AuthProvider(mockAuthRepository);
        await Future.delayed(Duration.zero);
      });

      test('returns null when no user', () {
        expect(provider.getUserPreferences(), isNull);
      });

      test('returns preferences map when user authenticated', () async {
        final testUser = TestData.createTestUser(
          languageCode: 'fr',
          currencyCode: 'EUR',
        );
        authStateController.add(testUser);
        await Future.delayed(Duration.zero);

        final prefs = provider.getUserPreferences();

        expect(prefs, isNotNull);
        expect(prefs!['languageCode'], equals('fr'));
        expect(prefs['currencyCode'], equals('EUR'));
      });

      test('returns default values in preferences map', () async {
        final testUser = TestData.createTestUser(); // Uses defaults
        authStateController.add(testUser);
        await Future.delayed(Duration.zero);

        final prefs = provider.getUserPreferences();

        expect(prefs, isNotNull);
        expect(prefs!['languageCode'], equals('en'));
        expect(prefs['currencyCode'], equals('USD'));
      });
    });

    group('signUp', () {
      setUp(() async {
        provider = AuthProvider(mockAuthRepository);
        await Future.delayed(Duration.zero);
      });

      test('successful sign up returns true and sets user', () async {
        final testUser = TestData.createTestUser();
        when(() => mockAuthRepository.signUpWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
              fullName: any(named: 'fullName'),
            )).thenAnswer((_) async => testUser);

        final result = await provider.signUp(
          email: 'test@example.com',
          password: 'password123',
          fullName: 'Test User',
        );

        expect(result, isTrue);
        expect(provider.currentUser, equals(testUser));
        expect(provider.isLoading, isFalse);
        expect(provider.error, isNull);
      });

      test('sets loading state during sign up', () async {
        final testUser = TestData.createTestUser();
        final completer = Completer<UserEntity>();
        when(() => mockAuthRepository.signUpWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
              fullName: any(named: 'fullName'),
            )).thenAnswer((_) => completer.future);

        final future = provider.signUp(
          email: 'test@example.com',
          password: 'password123',
        );

        await Future.delayed(Duration.zero);
        expect(provider.isLoading, isTrue);

        completer.complete(testUser);
        await future;

        expect(provider.isLoading, isFalse);
      });

      test('clears error before sign up', () async {
        final testUser = TestData.createTestUser();
        when(() => mockAuthRepository.signUpWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
              fullName: any(named: 'fullName'),
            )).thenAnswer((_) async => testUser);

        // Set an error first
        when(() => mockAuthRepository.signInWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenThrow(AuthException('Previous error'));

        await provider.signIn(email: 'test@example.com', password: 'wrong');
        expect(provider.error, isNotNull);

        await provider.signUp(
          email: 'test@example.com',
          password: 'password123',
        );

        expect(provider.error, isNull);
      });

      test('failed sign up with AuthException returns false and sets error', () async {
        when(() => mockAuthRepository.signUpWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
              fullName: any(named: 'fullName'),
            )).thenThrow(AuthException('Email already exists'));

        final result = await provider.signUp(
          email: 'test@example.com',
          password: 'password123',
        );

        expect(result, isFalse);
        expect(provider.currentUser, isNull);
        expect(provider.isLoading, isFalse);
        expect(provider.error, equals('Email already exists'));
      });

      test('failed sign up with generic exception returns false and sets error', () async {
        when(() => mockAuthRepository.signUpWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
              fullName: any(named: 'fullName'),
            )).thenThrow(Exception('Network error'));

        final result = await provider.signUp(
          email: 'test@example.com',
          password: 'password123',
        );

        expect(result, isFalse);
        expect(provider.error, contains('Sign up failed'));
        expect(provider.error, contains('Network error'));
      });

      test('notifies listeners on successful sign up', () async {
        final testUser = TestData.createTestUser();
        when(() => mockAuthRepository.signUpWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
              fullName: any(named: 'fullName'),
            )).thenAnswer((_) async => testUser);

        var notificationCount = 0;
        provider.addListener(() => notificationCount++);

        await provider.signUp(
          email: 'test@example.com',
          password: 'password123',
        );

        expect(notificationCount, greaterThan(0));
      });

      test('sign up with optional fullName', () async {
        final testUser = TestData.createTestUser();
        when(() => mockAuthRepository.signUpWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
              fullName: any(named: 'fullName'),
            )).thenAnswer((_) async => testUser);

        await provider.signUp(
          email: 'test@example.com',
          password: 'password123',
        );

        verify(() => mockAuthRepository.signUpWithEmail(
              email: 'test@example.com',
              password: 'password123',
              fullName: null,
            )).called(1);
      });
    });

    group('signIn', () {
      setUp(() async {
        provider = AuthProvider(mockAuthRepository);
        await Future.delayed(Duration.zero);
      });

      test('successful sign in returns true and sets user', () async {
        final testUser = TestData.createTestUser();
        when(() => mockAuthRepository.signInWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => testUser);

        final result = await provider.signIn(
          email: 'test@example.com',
          password: 'password123',
        );

        expect(result, isTrue);
        expect(provider.currentUser, equals(testUser));
        expect(provider.isLoading, isFalse);
        expect(provider.error, isNull);
      });

      test('sets loading state during sign in', () async {
        final testUser = TestData.createTestUser();
        final completer = Completer<UserEntity>();
        when(() => mockAuthRepository.signInWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) => completer.future);

        final future = provider.signIn(
          email: 'test@example.com',
          password: 'password123',
        );

        await Future.delayed(Duration.zero);
        expect(provider.isLoading, isTrue);

        completer.complete(testUser);
        await future;

        expect(provider.isLoading, isFalse);
      });

      test('clears error before sign in', () async {
        final testUser = TestData.createTestUser();

        // Set an error first
        when(() => mockAuthRepository.signInWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenThrow(AuthException('Wrong password'));

        await provider.signIn(email: 'test@example.com', password: 'wrong');
        expect(provider.error, isNotNull);

        // Successful sign in should clear error
        when(() => mockAuthRepository.signInWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => testUser);

        await provider.signIn(
          email: 'test@example.com',
          password: 'correct',
        );

        expect(provider.error, isNull);
      });

      test('failed sign in with AuthException returns false and sets error', () async {
        when(() => mockAuthRepository.signInWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenThrow(AuthException('Invalid credentials'));

        final result = await provider.signIn(
          email: 'test@example.com',
          password: 'wrongpassword',
        );

        expect(result, isFalse);
        expect(provider.currentUser, isNull);
        expect(provider.isLoading, isFalse);
        expect(provider.error, equals('Invalid credentials'));
      });

      test('failed sign in with generic exception returns false and sets error', () async {
        when(() => mockAuthRepository.signInWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenThrow(Exception('Network error'));

        final result = await provider.signIn(
          email: 'test@example.com',
          password: 'password123',
        );

        expect(result, isFalse);
        expect(provider.error, contains('Sign in failed'));
        expect(provider.error, contains('Network error'));
      });

      test('notifies listeners on successful sign in', () async {
        final testUser = TestData.createTestUser();
        when(() => mockAuthRepository.signInWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => testUser);

        var notificationCount = 0;
        provider.addListener(() => notificationCount++);

        await provider.signIn(
          email: 'test@example.com',
          password: 'password123',
        );

        expect(notificationCount, greaterThan(0));
      });
    });

    group('signOut', () {
      setUp(() async {
        provider = AuthProvider(mockAuthRepository);
        await Future.delayed(Duration.zero);

        // Sign in first
        final testUser = TestData.createTestUser();
        authStateController.add(testUser);
        await Future.delayed(Duration.zero);
      });

      test('successful sign out clears user', () async {
        when(() => mockAuthRepository.signOut()).thenAnswer((_) async {});

        expect(provider.currentUser, isNotNull);

        await provider.signOut();

        expect(provider.currentUser, isNull);
        expect(provider.isAuthenticated, isFalse);
        expect(provider.isLoading, isFalse);
        expect(provider.error, isNull);
      });

      test('sets loading state during sign out', () async {
        final completer = Completer<void>();
        when(() => mockAuthRepository.signOut())
            .thenAnswer((_) => completer.future);

        final future = provider.signOut();

        await Future.delayed(Duration.zero);
        expect(provider.isLoading, isTrue);

        completer.complete();
        await future;

        expect(provider.isLoading, isFalse);
      });

      test('clears error before sign out', () async {
        // Set an error
        when(() => mockAuthRepository.signOut())
            .thenThrow(Exception('Sign out failed'));

        await provider.signOut();
        expect(provider.error, isNotNull);

        // Successful sign out should clear error
        when(() => mockAuthRepository.signOut()).thenAnswer((_) async {});

        await provider.signOut();

        expect(provider.error, isNull);
      });

      test('failed sign out sets error but still clears loading state', () async {
        when(() => mockAuthRepository.signOut())
            .thenThrow(Exception('Network error'));

        await provider.signOut();

        expect(provider.isLoading, isFalse);
        expect(provider.error, contains('Sign out failed'));
        expect(provider.error, contains('Network error'));
      });

      test('notifies listeners on sign out', () async {
        when(() => mockAuthRepository.signOut()).thenAnswer((_) async {});

        var notificationCount = 0;
        provider.addListener(() => notificationCount++);

        await provider.signOut();

        expect(notificationCount, greaterThan(0));
      });

      test('sign out when already signed out is safe', () async {
        when(() => mockAuthRepository.signOut()).thenAnswer((_) async {});

        await provider.signOut();
        expect(provider.currentUser, isNull);

        // Sign out again
        expect(() => provider.signOut(), returnsNormally);
      });
    });

    group('resetPassword', () {
      setUp(() async {
        provider = AuthProvider(mockAuthRepository);
        await Future.delayed(Duration.zero);
      });

      test('successful password reset returns true', () async {
        when(() => mockAuthRepository.resetPassword(any()))
            .thenAnswer((_) async {});

        final result = await provider.resetPassword('test@example.com');

        expect(result, isTrue);
        expect(provider.isLoading, isFalse);
        expect(provider.error, isNull);
      });

      test('sets loading state during password reset', () async {
        final completer = Completer<void>();
        when(() => mockAuthRepository.resetPassword(any()))
            .thenAnswer((_) => completer.future);

        final future = provider.resetPassword('test@example.com');

        await Future.delayed(Duration.zero);
        expect(provider.isLoading, isTrue);

        completer.complete();
        await future;

        expect(provider.isLoading, isFalse);
      });

      test('clears error before password reset', () async {
        // Set an error first
        when(() => mockAuthRepository.resetPassword(any()))
            .thenThrow(Exception('Failed'));

        await provider.resetPassword('test@example.com');
        expect(provider.error, isNotNull);

        // Successful reset should clear error
        when(() => mockAuthRepository.resetPassword(any()))
            .thenAnswer((_) async {});

        await provider.resetPassword('test@example.com');

        expect(provider.error, isNull);
      });

      test('failed password reset returns false and sets error', () async {
        when(() => mockAuthRepository.resetPassword(any()))
            .thenThrow(Exception('Email not found'));

        final result = await provider.resetPassword('test@example.com');

        expect(result, isFalse);
        expect(provider.isLoading, isFalse);
        expect(provider.error, contains('Password reset failed'));
        expect(provider.error, contains('Email not found'));
      });

      test('notifies listeners on password reset', () async {
        when(() => mockAuthRepository.resetPassword(any()))
            .thenAnswer((_) async {});

        var notificationCount = 0;
        provider.addListener(() => notificationCount++);

        await provider.resetPassword('test@example.com');

        expect(notificationCount, greaterThan(0));
      });
    });

    group('updateProfile', () {
      setUp(() async {
        provider = AuthProvider(mockAuthRepository);
        await Future.delayed(Duration.zero);

        // Sign in first
        final testUser = TestData.createTestUser();
        authStateController.add(testUser);
        await Future.delayed(Duration.zero);
      });

      test('successful profile update returns true and updates user', () async {
        final updatedUser = TestData.createTestUser(fullName: 'Updated Name');
        when(() => mockAuthRepository.updateProfile(
              fullName: any(named: 'fullName'),
              avatarUrl: any(named: 'avatarUrl'),
              phone: any(named: 'phone'),
              languageCode: any(named: 'languageCode'),
              currencyCode: any(named: 'currencyCode'),
            )).thenAnswer((_) async => updatedUser);

        final result = await provider.updateProfile(fullName: 'Updated Name');

        expect(result, isTrue);
        expect(provider.currentUser, equals(updatedUser));
        expect(provider.currentUser!.fullName, equals('Updated Name'));
        expect(provider.isLoading, isFalse);
        expect(provider.error, isNull);
      });

      test('sets loading state during profile update', () async {
        final updatedUser = TestData.createTestUser();
        final completer = Completer<UserEntity>();
        when(() => mockAuthRepository.updateProfile(
              fullName: any(named: 'fullName'),
              avatarUrl: any(named: 'avatarUrl'),
              phone: any(named: 'phone'),
              languageCode: any(named: 'languageCode'),
              currencyCode: any(named: 'currencyCode'),
            )).thenAnswer((_) => completer.future);

        final future = provider.updateProfile(fullName: 'New Name');

        await Future.delayed(Duration.zero);
        expect(provider.isLoading, isTrue);

        completer.complete(updatedUser);
        await future;

        expect(provider.isLoading, isFalse);
      });

      test('clears error before profile update', () async {
        final updatedUser = TestData.createTestUser();

        // Set an error first
        when(() => mockAuthRepository.updateProfile(
              fullName: any(named: 'fullName'),
              avatarUrl: any(named: 'avatarUrl'),
              phone: any(named: 'phone'),
              languageCode: any(named: 'languageCode'),
              currencyCode: any(named: 'currencyCode'),
            )).thenThrow(Exception('Update failed'));

        await provider.updateProfile(fullName: 'Name');
        expect(provider.error, isNotNull);

        // Successful update should clear error
        when(() => mockAuthRepository.updateProfile(
              fullName: any(named: 'fullName'),
              avatarUrl: any(named: 'avatarUrl'),
              phone: any(named: 'phone'),
              languageCode: any(named: 'languageCode'),
              currencyCode: any(named: 'currencyCode'),
            )).thenAnswer((_) async => updatedUser);

        await provider.updateProfile(fullName: 'New Name');

        expect(provider.error, isNull);
      });

      test('failed profile update returns false and sets error', () async {
        when(() => mockAuthRepository.updateProfile(
              fullName: any(named: 'fullName'),
              avatarUrl: any(named: 'avatarUrl'),
              phone: any(named: 'phone'),
              languageCode: any(named: 'languageCode'),
              currencyCode: any(named: 'currencyCode'),
            )).thenThrow(Exception('Network error'));

        final result = await provider.updateProfile(fullName: 'New Name');

        expect(result, isFalse);
        expect(provider.isLoading, isFalse);
        expect(provider.error, contains('Profile update failed'));
        expect(provider.error, contains('Network error'));
      });

      test('notifies listeners on profile update', () async {
        final updatedUser = TestData.createTestUser();
        when(() => mockAuthRepository.updateProfile(
              fullName: any(named: 'fullName'),
              avatarUrl: any(named: 'avatarUrl'),
              phone: any(named: 'phone'),
              languageCode: any(named: 'languageCode'),
              currencyCode: any(named: 'currencyCode'),
            )).thenAnswer((_) async => updatedUser);

        var notificationCount = 0;
        provider.addListener(() => notificationCount++);

        await provider.updateProfile(fullName: 'New Name');

        expect(notificationCount, greaterThan(0));
      });

      test('update profile with multiple fields', () async {
        final updatedUser = TestData.createTestUser(
          fullName: 'John Doe',
          phone: '+1234567890',
          languageCode: 'es',
          currencyCode: 'EUR',
        );
        when(() => mockAuthRepository.updateProfile(
              fullName: any(named: 'fullName'),
              avatarUrl: any(named: 'avatarUrl'),
              phone: any(named: 'phone'),
              languageCode: any(named: 'languageCode'),
              currencyCode: any(named: 'currencyCode'),
            )).thenAnswer((_) async => updatedUser);

        await provider.updateProfile(
          fullName: 'John Doe',
          phone: '+1234567890',
          languageCode: 'es',
          currencyCode: 'EUR',
        );

        verify(() => mockAuthRepository.updateProfile(
              fullName: 'John Doe',
              avatarUrl: null,
              phone: '+1234567890',
              languageCode: 'es',
              currencyCode: 'EUR',
            )).called(1);
      });
    });

    group('State Transitions', () {
      setUp(() async {
        provider = AuthProvider(mockAuthRepository);
        await Future.delayed(Duration.zero);
      });

      test('guest -> authenticated -> guest transition', () async {
        expect(provider.isGuest, isTrue);

        // Sign in
        final testUser = TestData.createTestUser();
        when(() => mockAuthRepository.signInWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => testUser);

        await provider.signIn(email: 'test@example.com', password: 'pass');
        expect(provider.isAuthenticated, isTrue);
        expect(provider.isGuest, isFalse);

        // Sign out
        when(() => mockAuthRepository.signOut()).thenAnswer((_) async {});
        await provider.signOut();
        expect(provider.isGuest, isTrue);
        expect(provider.isAuthenticated, isFalse);
      });

      test('loading state transitions correctly', () async {
        expect(provider.isLoading, isFalse);

        final testUser = TestData.createTestUser();
        final completer = Completer<UserEntity>();
        when(() => mockAuthRepository.signInWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) => completer.future);

        final future = provider.signIn(email: 'test@example.com', password: 'pass');

        await Future.delayed(Duration.zero);
        expect(provider.isLoading, isTrue);

        completer.complete(testUser);
        await future;

        expect(provider.isLoading, isFalse);
      });

      test('error is cleared when starting new operation', () async {
        // Fail sign in
        when(() => mockAuthRepository.signInWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenThrow(AuthException('Error'));

        await provider.signIn(email: 'test@example.com', password: 'wrong');
        expect(provider.error, isNotNull);

        // Start new operation (sign up)
        final testUser = TestData.createTestUser();
        when(() => mockAuthRepository.signUpWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
              fullName: any(named: 'fullName'),
            )).thenAnswer((_) async => testUser);

        final completer = Completer();
        provider.addListener(() {
          if (provider.error == null && !completer.isCompleted) {
            completer.complete();
          }
        });

        provider.signUp(email: 'test@example.com', password: 'pass');

        await completer.future;
        // Error cleared before sign up completes
      });
    });

    group('Disposal', () {
      test('cancels auth state subscription on dispose', () async {
        provider = AuthProvider(mockAuthRepository);
        await Future.delayed(Duration.zero);

        expect(authStateController.hasListener, isTrue);

        provider.dispose();

        await Future.delayed(Duration.zero);
        expect(authStateController.hasListener, isFalse);
      });

      test('dispose cancels subscription', () async {
        provider = AuthProvider(mockAuthRepository);
        await Future.delayed(Duration.zero);

        expect(authStateController.hasListener, isTrue);

        provider.dispose();

        await Future.delayed(Duration.zero);
        expect(authStateController.hasListener, isFalse);
      });
    });

    group('Edge Cases', () {
      setUp(() async {
        provider = AuthProvider(mockAuthRepository);
        await Future.delayed(Duration.zero);
      });

      test('handles empty email gracefully', () async {
        when(() => mockAuthRepository.signInWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenThrow(AuthException('Invalid email'));

        final result = await provider.signIn(email: '', password: 'password');

        expect(result, isFalse);
        expect(provider.error, isNotNull);
      });

      test('handles empty password gracefully', () async {
        when(() => mockAuthRepository.signInWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenThrow(AuthException('Invalid password'));

        final result = await provider.signIn(email: 'test@example.com', password: '');

        expect(result, isFalse);
        expect(provider.error, isNotNull);
      });

      test('handles rapid sign in attempts', () async {
        final testUser = TestData.createTestUser();
        when(() => mockAuthRepository.signInWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => testUser);

        final futures = <Future<bool>>[];
        for (int i = 0; i < 5; i++) {
          futures.add(provider.signIn(email: 'test@example.com', password: 'pass'));
        }

        final results = await Future.wait(futures);

        expect(results, everyElement(isTrue));
      });

      test('update profile without authenticated user handles gracefully', () async {
        // No user authenticated
        expect(provider.currentUser, isNull);

        when(() => mockAuthRepository.updateProfile(
              fullName: any(named: 'fullName'),
              avatarUrl: any(named: 'avatarUrl'),
              phone: any(named: 'phone'),
              languageCode: any(named: 'languageCode'),
              currencyCode: any(named: 'currencyCode'),
            )).thenThrow(Exception('Not authenticated'));

        final result = await provider.updateProfile(fullName: 'Name');

        expect(result, isFalse);
        expect(provider.error, isNotNull);
      });
    });

    group('Listener Notifications', () {
      setUp(() async {
        provider = AuthProvider(mockAuthRepository);
        await Future.delayed(Duration.zero);
      });

      test('initialization notifies listeners', () async {
        var notificationCount = 0;

        // Create new provider with listener
        final newProvider = AuthProvider(mockAuthRepository);
        newProvider.addListener(() => notificationCount++);

        await Future.delayed(Duration.zero);

        expect(notificationCount, greaterThan(0));

        newProvider.dispose();
      });

      test('sign in notifies listeners multiple times (loading, success)', () async {
        final testUser = TestData.createTestUser();
        when(() => mockAuthRepository.signInWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => testUser);

        var notificationCount = 0;
        provider.addListener(() => notificationCount++);

        await provider.signIn(email: 'test@example.com', password: 'pass');

        expect(notificationCount, greaterThanOrEqualTo(2)); // At least loading + success
      });

      test('multiple listeners all receive notifications', () async {
        final testUser = TestData.createTestUser();
        when(() => mockAuthRepository.signInWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => testUser);

        var count1 = 0, count2 = 0, count3 = 0;
        provider.addListener(() => count1++);
        provider.addListener(() => count2++);
        provider.addListener(() => count3++);

        await provider.signIn(email: 'test@example.com', password: 'pass');

        expect(count1, greaterThan(0));
        expect(count2, greaterThan(0));
        expect(count3, greaterThan(0));
      });

      test('removed listener does not receive notifications', () async {
        final testUser = TestData.createTestUser();
        when(() => mockAuthRepository.signInWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => testUser);

        var removedCount = 0;
        var activeCount = 0;

        void removedListener() => removedCount++;
        void activeListener() => activeCount++;

        provider.addListener(removedListener);
        provider.addListener(activeListener);

        provider.removeListener(removedListener);

        await provider.signIn(email: 'test@example.com', password: 'pass');

        expect(removedCount, equals(0));
        expect(activeCount, greaterThan(0));
      });
    });
  });
}
