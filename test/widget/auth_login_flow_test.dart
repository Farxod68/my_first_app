import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_first_app/core/constants/widget_keys.dart';
import 'package:my_first_app/presentation/screens/auth/login_page.dart';
import 'package:my_first_app/presentation/screens/auth/signup_page.dart';
import 'package:my_first_app/presentation/screens/auth/forgot_password_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../helpers/auth_test_helpers.dart';
import '../helpers/test_data.dart';

void main() {
  group('Login Flow Tests', () {
    testWidgets('renders all form elements with correct keys', (tester) async {
      await pumpAuthPage(tester, const LoginPage());

      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.byKey(WidgetKeys.loginEmailField), findsOneWidget);
      expect(find.byKey(WidgetKeys.loginPasswordField), findsOneWidget);
      expect(find.byKey(WidgetKeys.loginPasswordVisibilityToggle),
          findsOneWidget);
      expect(find.byKey(WidgetKeys.loginButton), findsOneWidget);
      expect(find.byKey(WidgetKeys.loginForgotPasswordButton),
          findsOneWidget);
      expect(find.byKey(WidgetKeys.loginSignUpButton), findsOneWidget);
    });

    testWidgets('successful login updates provider state', (tester) async {
      final context = await pumpAuthPage(tester, const LoginPage());

      final testUser = TestData.createTestUser(
        email: 'test@example.com',
        fullName: 'Test User',
      );

      when(() => context.mockAuthRepository.signInWithEmail(
            email: 'test@example.com',
            password: 'password123',
          )).thenAnswer((_) async => testUser);

      await tester.enterText(
          find.byKey(WidgetKeys.loginEmailField), 'test@example.com');
      await tester.enterText(
          find.byKey(WidgetKeys.loginPasswordField), 'password123');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(WidgetKeys.loginButton));
      await tester.pumpAndSettle();

      expect(context.authProvider.isAuthenticated, isTrue);
      expect(context.authProvider.currentUser?.email, equals('test@example.com'));
      verify(() => context.mockAuthRepository.signInWithEmail(
            email: 'test@example.com',
            password: 'password123',
          )).called(1);
    });

    testWidgets('invalid email shows validation error', (tester) async {
      final context = await pumpAuthPage(tester, const LoginPage());

      await tester.enterText(
          find.byKey(WidgetKeys.loginEmailField), 'invalid-email');
      await tester.enterText(
          find.byKey(WidgetKeys.loginPasswordField), 'password123');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(WidgetKeys.loginButton));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid email address'), findsOneWidget);

      verifyNever(() => context.mockAuthRepository.signInWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ));
    });

    testWidgets('empty password shows validation error', (tester) async {
      final context = await pumpAuthPage(tester, const LoginPage());

      await tester.enterText(
          find.byKey(WidgetKeys.loginEmailField), 'test@example.com');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(WidgetKeys.loginButton));
      await tester.pumpAndSettle();

      expect(find.text('Password is required'), findsOneWidget);

      verifyNever(() => context.mockAuthRepository.signInWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ));
    });

    testWidgets('authentication failure sets error in provider',
        (tester) async {
      final context = await pumpAuthPage(tester, const LoginPage());

      when(() => context.mockAuthRepository.signInWithEmail(
            email: 'test@example.com',
            password: 'wrongpassword',
          )).thenThrow(AuthException('Invalid credentials'));

      await tester.enterText(
          find.byKey(WidgetKeys.loginEmailField), 'test@example.com');
      await tester.enterText(
          find.byKey(WidgetKeys.loginPasswordField), 'wrongpassword');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(WidgetKeys.loginButton));
      await tester.pumpAndSettle();

      expect(context.authProvider.isAuthenticated, isFalse);
      expect(context.authProvider.error, equals('Invalid credentials'));
    });

    testWidgets('tapping forgot password navigates to ForgotPasswordPage',
        (tester) async {
      await pumpAuthPage(tester, const LoginPage());

      await tester.tap(find.byKey(WidgetKeys.loginForgotPasswordButton));
      await tester.pumpAndSettle();

      expect(find.byType(ForgotPasswordPage), findsOneWidget);
    });

    testWidgets('tapping sign up navigates to SignUpPage', (tester) async {
      await pumpAuthPage(tester, const LoginPage());

      // Scroll to make sign up button visible
      await tester.ensureVisible(find.byKey(WidgetKeys.loginSignUpButton));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(WidgetKeys.loginSignUpButton));
      await tester.pumpAndSettle();

      expect(find.byType(SignUpPage), findsOneWidget);
    });

    testWidgets('password visibility toggle changes icon', (tester) async {
      await pumpAuthPage(tester, const LoginPage());

      await tester.enterText(
          find.byKey(WidgetKeys.loginPasswordField), 'password123');
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);

      await tester.tap(find.byKey(WidgetKeys.loginPasswordVisibilityToggle));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_outlined), findsNothing);
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);

      await tester.tap(find.byKey(WidgetKeys.loginPasswordVisibilityToggle));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);
    });
  });
}
