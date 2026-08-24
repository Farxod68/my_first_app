import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_first_app/core/constants/widget_keys.dart';
import 'package:my_first_app/presentation/screens/auth/signup_page.dart';
import 'package:my_first_app/presentation/screens/auth/login_page.dart';
import '../helpers/auth_test_helpers.dart';
import '../helpers/test_data.dart';

void main() {
  group('SignUp Flow Tests', () {
    testWidgets('renders all form elements with correct keys', (tester) async {
      await pumpAuthPage(tester, const SignUpPage());

      expect(find.byType(SignUpPage), findsOneWidget);
      expect(find.byKey(WidgetKeys.signupNameField), findsOneWidget);
      expect(find.byKey(WidgetKeys.signupEmailField), findsOneWidget);
      expect(find.byKey(WidgetKeys.signupPasswordField), findsOneWidget);
      expect(find.byKey(WidgetKeys.signupPasswordVisibilityToggle),
          findsOneWidget);
      expect(find.byKey(WidgetKeys.signupConfirmPasswordField),
          findsOneWidget);
      expect(find.byKey(WidgetKeys.signupConfirmPasswordVisibilityToggle),
          findsOneWidget);
      expect(find.byKey(WidgetKeys.signupButton), findsOneWidget);
      expect(find.byKey(WidgetKeys.signupLoginButton), findsOneWidget);
    });

    testWidgets('successful signup updates provider state', (tester) async {
      final context = await pumpAuthPage(tester, const SignUpPage());

      final testUser = TestData.createTestUser(
        email: 'newuser@example.com',
        fullName: 'New User',
      );

      when(() => context.mockAuthRepository.signUpWithEmail(
            email: 'newuser@example.com',
            password: 'password123',
            fullName: 'New User',
          )).thenAnswer((_) async => testUser);

      await tester.enterText(
          find.byKey(WidgetKeys.signupNameField), 'New User');
      await tester.enterText(
          find.byKey(WidgetKeys.signupEmailField), 'newuser@example.com');
      await tester.enterText(
          find.byKey(WidgetKeys.signupPasswordField), 'password123');
      await tester.enterText(
          find.byKey(WidgetKeys.signupConfirmPasswordField), 'password123');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(WidgetKeys.signupButton));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(WidgetKeys.signupButton));
      await tester.pumpAndSettle();

      expect(context.authProvider.isAuthenticated, isTrue);
      expect(context.authProvider.currentUser?.email,
          equals('newuser@example.com'));
      verify(() => context.mockAuthRepository.signUpWithEmail(
            email: 'newuser@example.com',
            password: 'password123',
            fullName: 'New User',
          )).called(1);
    });

    testWidgets('empty name field shows validation error', (tester) async {
      final context = await pumpAuthPage(tester, const SignUpPage());

      await tester.enterText(
          find.byKey(WidgetKeys.signupEmailField), 'test@example.com');
      await tester.enterText(
          find.byKey(WidgetKeys.signupPasswordField), 'password123');
      await tester.enterText(
          find.byKey(WidgetKeys.signupConfirmPasswordField), 'password123');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(WidgetKeys.signupButton));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(WidgetKeys.signupButton));
      await tester.pumpAndSettle();

      expect(find.text('Name is required'), findsOneWidget);

      verifyNever(() => context.mockAuthRepository.signUpWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
            fullName: any(named: 'fullName'),
          ));
    });

    testWidgets('invalid email shows validation error', (tester) async {
      final context = await pumpAuthPage(tester, const SignUpPage());

      await tester.enterText(
          find.byKey(WidgetKeys.signupNameField), 'Test User');
      await tester.enterText(
          find.byKey(WidgetKeys.signupEmailField), 'invalid-email');
      await tester.enterText(
          find.byKey(WidgetKeys.signupPasswordField), 'password123');
      await tester.enterText(
          find.byKey(WidgetKeys.signupConfirmPasswordField), 'password123');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(WidgetKeys.signupButton));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(WidgetKeys.signupButton));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid email address'), findsOneWidget);

      verifyNever(() => context.mockAuthRepository.signUpWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
            fullName: any(named: 'fullName'),
          ));
    });

    testWidgets('passwords not matching shows validation error',
        (tester) async {
      final context = await pumpAuthPage(tester, const SignUpPage());

      await tester.enterText(
          find.byKey(WidgetKeys.signupNameField), 'Test User');
      await tester.enterText(
          find.byKey(WidgetKeys.signupEmailField), 'test@example.com');
      await tester.enterText(
          find.byKey(WidgetKeys.signupPasswordField), 'password123');
      await tester.enterText(
          find.byKey(WidgetKeys.signupConfirmPasswordField), 'different123');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(WidgetKeys.signupButton));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(WidgetKeys.signupButton));
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);

      verifyNever(() => context.mockAuthRepository.signUpWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
            fullName: any(named: 'fullName'),
          ));
    });

    testWidgets('password strength indicator updates correctly',
        (tester) async {
      await pumpAuthPage(tester, const SignUpPage());

      // Initially no indicator (empty password)
      expect(find.byKey(WidgetKeys.signupPasswordStrengthIndicator),
          findsNothing);

      // Enter weak password
      await tester.enterText(find.byKey(WidgetKeys.signupPasswordField), '123');
      await tester.pumpAndSettle();

      // Strength indicator should appear
      expect(find.byKey(WidgetKeys.signupPasswordStrengthIndicator),
          findsOneWidget);
      expect(find.text('Weak'), findsOneWidget);

      // Enter medium password
      await tester.enterText(
          find.byKey(WidgetKeys.signupPasswordField), 'password123');
      await tester.pumpAndSettle();

      expect(find.text('Medium'), findsOneWidget);

      // Enter strong password
      await tester.enterText(
          find.byKey(WidgetKeys.signupPasswordField), 'Password123!');
      await tester.pumpAndSettle();

      expect(find.text('Strong'), findsOneWidget);
    });

    testWidgets('tapping login navigates to LoginPage', (tester) async {
      await pumpAuthPage(tester, const SignUpPage());

      await tester.ensureVisible(find.byKey(WidgetKeys.signupLoginButton));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(WidgetKeys.signupLoginButton));
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('password visibility toggles work independently',
        (tester) async {
      await pumpAuthPage(tester, const SignUpPage());

      await tester.enterText(
          find.byKey(WidgetKeys.signupPasswordField), 'password123');
      await tester.enterText(
          find.byKey(WidgetKeys.signupConfirmPasswordField), 'password123');
      await tester.pumpAndSettle();

      // Initially both passwords obscured - should find 2 visibility_outlined icons
      expect(find.byIcon(Icons.visibility_outlined), findsNWidgets(2));
      expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);

      // Toggle password visibility
      await tester.tap(find.byKey(WidgetKeys.signupPasswordVisibilityToggle));
      await tester.pumpAndSettle();

      // Password visible, confirm still obscured
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);

      // Toggle confirm password visibility
      await tester
          .tap(find.byKey(WidgetKeys.signupConfirmPasswordVisibilityToggle));
      await tester.pumpAndSettle();

      // Both passwords visible
      expect(find.byIcon(Icons.visibility_outlined), findsNothing);
      expect(find.byIcon(Icons.visibility_off_outlined), findsNWidgets(2));
    });
  });
}
