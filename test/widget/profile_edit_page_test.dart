import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:my_first_app/domain/entities/user_entity.dart';
import 'package:my_first_app/l10n/app_localizations.dart';
import 'package:my_first_app/presentation/providers/auth_provider.dart';
import 'package:my_first_app/presentation/providers/currency_provider.dart';
import 'package:my_first_app/presentation/providers/locale_provider.dart';
import 'package:my_first_app/presentation/screens/profile/profile_edit_page.dart';
import '../helpers/test_data.dart';
import '../mocks/mock_auth_repository.dart';
import '../mocks/mock_persistence_service.dart';

const _localizationsDelegates = [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

const _supportedLocales = [
  Locale('en'),
  Locale('es'),
  Locale('fr'),
  Locale('uz'),
];

/// Providers + mocks created for a single ProfileEditPage test.
class ProfileEditTestContext {
  final AuthProvider authProvider;
  final LocaleProvider localeProvider;
  final CurrencyProvider currencyProvider;
  final MockAuthRepository mockAuthRepository;

  ProfileEditTestContext({
    required this.authProvider,
    required this.localeProvider,
    required this.currencyProvider,
    required this.mockAuthRepository,
  });

  List<SingleChildWidget> get providers => [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
        ChangeNotifierProvider<CurrencyProvider>.value(
            value: currencyProvider),
      ];

  /// Stubs updateProfile to succeed, returning [result] (or the current
  /// user if none given).
  void stubUpdateProfileSuccess(UserEntity result) {
    when(() => mockAuthRepository.updateProfile(
          fullName: any(named: 'fullName'),
          avatarUrl: any(named: 'avatarUrl'),
          phone: any(named: 'phone'),
          languageCode: any(named: 'languageCode'),
          currencyCode: any(named: 'currencyCode'),
        )).thenAnswer((_) async => result);
  }

  void verifyUpdateProfileNeverCalled() {
    verifyNever(() => mockAuthRepository.updateProfile(
          fullName: any(named: 'fullName'),
          avatarUrl: any(named: 'avatarUrl'),
          phone: any(named: 'phone'),
          languageCode: any(named: 'languageCode'),
          currencyCode: any(named: 'currencyCode'),
        ));
  }
}

/// Creates a fresh AuthProvider/LocaleProvider/CurrencyProvider trio backed
/// by mocks, with [user] as the (possibly null) authenticated user.
///
/// AuthProvider's constructor kicks off an async `_initialize()` that awaits
/// the stubbed `getCurrentUser()`. ProfileEditPage's `initState()` reads
/// `authProvider.currentUser` synchronously exactly once, so we must let
/// that stubbed Future resolve BEFORE the page is ever mounted - otherwise
/// the page's one-time form pre-fill would run against a still-null user.
Future<ProfileEditTestContext> _createContext({UserEntity? user}) async {
  final mockAuthRepository = MockAuthRepository();
  final mockPersistenceService = MockPersistenceService();

  when(() => mockAuthRepository.getCurrentUser())
      .thenAnswer((_) async => user);
  when(() => mockAuthRepository.authStateChanges)
      .thenAnswer((_) => Stream.value(user));
  when(() => mockPersistenceService.loadLocale()).thenReturn(null);
  when(() => mockPersistenceService.getString(any())).thenReturn(null);
  when(() => mockPersistenceService.saveLocale(any()))
      .thenAnswer((_) async => true);
  when(() => mockPersistenceService.saveString(any(), any()))
      .thenAnswer((_) async => true);

  final authProvider = AuthProvider(mockAuthRepository);
  final localeProvider = LocaleProvider(mockPersistenceService);
  final currencyProvider = CurrencyProvider(mockPersistenceService);

  // Let the stubbed async getCurrentUser() resolve before mounting.
  await Future<void>.value();

  return ProfileEditTestContext(
    authProvider: authProvider,
    localeProvider: localeProvider,
    currencyProvider: currencyProvider,
    mockAuthRepository: mockAuthRepository,
  );
}

/// Pumps ProfileEditPage directly as `home`.
Future<ProfileEditTestContext> pumpProfileEditPage(
  WidgetTester tester, {
  UserEntity? user,
}) async {
  tester.view.physicalSize = const Size(800, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final context = await _createContext(user: user);

  await tester.pumpWidget(
    MultiProvider(
      providers: context.providers,
      child: const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: _localizationsDelegates,
        supportedLocales: _supportedLocales,
        home: ProfileEditPage(),
      ),
    ),
  );

  await tester.pumpAndSettle();
  return context;
}

/// Pumps a placeholder page with a button that pushes ProfileEditPage, so
/// that popping it (Save success, Cancel) is observable.
Future<ProfileEditTestContext> pumpProfileEditPageWithPreviousRoute(
  WidgetTester tester, {
  UserEntity? user,
}) async {
  tester.view.physicalSize = const Size(800, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final context = await _createContext(user: user);

  await tester.pumpWidget(
    MultiProvider(
      providers: context.providers,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: _localizationsDelegates,
        supportedLocales: _supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileEditPage()),
                ),
                child: const Text('Open Profile'),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('Open Profile'));
  await tester.pumpAndSettle();

  return context;
}

void main() {
  group('ProfileEditPage Widget Tests', () {
    testWidgets('1. Unauthenticated shows the sign-in fallback and no form',
        (tester) async {
      await pumpProfileEditPage(tester, user: null);

      expect(find.text('Sign in to access more features'), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
    });

    testWidgets(
        '2. Authenticated form pre-fills email (read-only), full name, and phone',
        (tester) async {
      final user = TestData.createTestUser(
        email: 'jane@example.com',
        fullName: 'Jane Doe',
        phone: '5551234567',
      );

      await pumpProfileEditPage(tester, user: user);

      final emailField = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Email'),
      );
      expect(emailField.initialValue, 'jane@example.com');
      expect(emailField.enabled, isFalse);

      final nameField = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Full Name'),
      );
      expect(nameField.controller?.text, 'Jane Doe');

      final phoneField = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Phone Number'),
      );
      expect(phoneField.controller?.text, '5551234567');
    });

    testWidgets(
        "3. Language and Currency preference subtitles reflect the user's saved preferences",
        (tester) async {
      final user = TestData.createTestUser(
        languageCode: 'fr',
        currencyCode: 'EUR',
      );

      await pumpProfileEditPage(tester, user: user);

      expect(find.text('Français'), findsOneWidget);
      expect(find.text('Euro (EUR)'), findsOneWidget);
    });

    testWidgets(
        '4. Full name of 1 character shows a validation error and blocks save',
        (tester) async {
      final context =
          await pumpProfileEditPage(tester, user: TestData.createTestUser());

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Full Name'),
        'A',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save Changes'));
      await tester.pumpAndSettle();

      expect(
        find.text('Name must be at least 2 characters'),
        findsOneWidget,
      );
      context.verifyUpdateProfileNeverCalled();
    });

    testWidgets('5. Empty full name is valid and does not block save',
        (tester) async {
      final user = TestData.createTestUser(phone: '1234567890');
      final context = await pumpProfileEditPage(tester, user: user);
      context.stubUpdateProfileSuccess(user);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Full Name'),
        '',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save Changes'));
      await tester.pumpAndSettle();

      expect(
        find.text('Name must be at least 2 characters'),
        findsNothing,
      );
      verify(() => context.mockAuthRepository.updateProfile(
            fullName: null,
            avatarUrl: any(named: 'avatarUrl'),
            phone: any(named: 'phone'),
            languageCode: any(named: 'languageCode'),
            currencyCode: any(named: 'currencyCode'),
          )).called(1);
    });

    testWidgets(
        '6. Invalid phone number shows a validation error and blocks save',
        (tester) async {
      final context =
          await pumpProfileEditPage(tester, user: TestData.createTestUser());

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Phone Number'),
        '123',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save Changes'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid phone number'), findsOneWidget);
      context.verifyUpdateProfileNeverCalled();
    });

    testWidgets('7. Empty phone number is valid and does not block save',
        (tester) async {
      final user = TestData.createTestUser(fullName: 'Jane Doe');
      final context = await pumpProfileEditPage(tester, user: user);
      context.stubUpdateProfileSuccess(user);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Phone Number'),
        '',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save Changes'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid phone number'), findsNothing);
    });

    testWidgets(
        '8. Selecting a language in the dialog updates the preference subtitle',
        (tester) async {
      final user = TestData.createTestUser(languageCode: 'en');
      await pumpProfileEditPage(tester, user: user);

      await tester.tap(find.widgetWithText(ListTile, 'Language'));
      await tester.pumpAndSettle();

      expect(find.text('Français'), findsOneWidget);
      await tester.tap(find.text('Français'));
      await tester.pumpAndSettle();

      expect(find.text('Français'), findsOneWidget);
    });

    testWidgets(
        '9. Selecting a currency in the dialog updates the preference subtitle',
        (tester) async {
      final user = TestData.createTestUser(currencyCode: 'USD');
      await pumpProfileEditPage(tester, user: user);

      await tester.tap(find.widgetWithText(ListTile, 'Currency'));
      await tester.pumpAndSettle();

      expect(find.text('Euro (EUR)'), findsOneWidget);
      await tester.tap(find.text('Euro (EUR)'));
      await tester.pumpAndSettle();

      expect(find.text('Euro (EUR)'), findsOneWidget);
    });

    testWidgets(
        '10. A successful save updates the profile, syncs preferences, shows confirmation, and pops',
        (tester) async {
      final user = TestData.createTestUser(
        fullName: 'Original Name',
        phone: '1234567890',
        languageCode: 'en',
        currencyCode: 'USD',
      );
      final updatedUser = user.copyWith(fullName: 'Original Name');
      final context =
          await pumpProfileEditPageWithPreviousRoute(tester, user: user);
      context.stubUpdateProfileSuccess(updatedUser);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Save Changes'));
      await tester.pumpAndSettle();

      verify(() => context.mockAuthRepository.updateProfile(
            fullName: 'Original Name',
            avatarUrl: null,
            phone: '1234567890',
            languageCode: 'en',
            currencyCode: 'USD',
          )).called(1);
      expect(context.localeProvider.languageCode, 'en');
      expect(context.currencyProvider.currentCurrency, 'USD');
      expect(find.text('Profile updated successfully'), findsOneWidget);
      expect(find.byType(ProfileEditPage), findsNothing);
      expect(find.text('Open Profile'), findsOneWidget);
    });

    testWidgets(
        '11. A failed save (repository error) shows an error message and does not pop',
        (tester) async {
      final user = TestData.createTestUser();
      final context = await pumpProfileEditPage(tester, user: user);
      when(() => context.mockAuthRepository.updateProfile(
            fullName: any(named: 'fullName'),
            avatarUrl: any(named: 'avatarUrl'),
            phone: any(named: 'phone'),
            languageCode: any(named: 'languageCode'),
            currencyCode: any(named: 'currencyCode'),
          )).thenThrow(Exception('network error'));

      await tester.tap(find.widgetWithText(ElevatedButton, 'Save Changes'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Profile update failed'), findsOneWidget);
      expect(find.byType(ProfileEditPage), findsOneWidget);
    });

    testWidgets('13. Cancel pops the page without calling updateProfile',
        (tester) async {
      final user = TestData.createTestUser();
      final context =
          await pumpProfileEditPageWithPreviousRoute(tester, user: user);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
      await tester.pumpAndSettle();

      context.verifyUpdateProfileNeverCalled();
      expect(find.byType(ProfileEditPage), findsNothing);
      expect(find.text('Open Profile'), findsOneWidget);
    });

    testWidgets(
        '14. While saving, the Save button shows a spinner and Save/Cancel are disabled',
        (tester) async {
      final user = TestData.createTestUser();
      final context = await pumpProfileEditPage(tester, user: user);
      final completer = Completer<UserEntity>();
      when(() => context.mockAuthRepository.updateProfile(
            fullName: any(named: 'fullName'),
            avatarUrl: any(named: 'avatarUrl'),
            phone: any(named: 'phone'),
            languageCode: any(named: 'languageCode'),
            currencyCode: any(named: 'currencyCode'),
          )).thenAnswer((_) => completer.future);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Save Changes'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final saveButton =
          tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(saveButton.onPressed, isNull);
      final cancelButton =
          tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      expect(cancelButton.onPressed, isNull);

      completer.complete(user);
      await tester.pumpAndSettle();
    });
  });
}
