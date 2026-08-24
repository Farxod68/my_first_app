import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_first_app/core/constants/widget_keys.dart';
import 'package:my_first_app/presentation/screens/auth/forgot_password_page.dart';
import '../helpers/auth_test_helpers.dart';

void main() {
  group('Forgot Password Flow Tests', () {
    testWidgets('renders all form elements with correct keys', (tester) async {
      await pumpAuthPage(tester, const ForgotPasswordPage());

      expect(find.byType(ForgotPasswordPage), findsOneWidget);
      expect(find.byKey(WidgetKeys.forgotPasswordEmailField), findsOneWidget);
      expect(find.byKey(WidgetKeys.forgotPasswordSendButton), findsOneWidget);
    });

    testWidgets('successful reset password shows email sent state',
        (tester) async {
      final context = await pumpAuthPage(tester, const ForgotPasswordPage());

      when(() => context.mockAuthRepository.resetPassword('test@example.com'))
          .thenAnswer((_) async => {});

      // Initially should show email field and send button
      expect(find.byKey(WidgetKeys.forgotPasswordEmailField), findsOneWidget);
      expect(find.byKey(WidgetKeys.forgotPasswordSendButton), findsOneWidget);
      expect(find.byKey(WidgetKeys.forgotPasswordResendButton), findsNothing);

      // Enter email
      await tester.enterText(
          find.byKey(WidgetKeys.forgotPasswordEmailField), 'test@example.com');
      await tester.pumpAndSettle();

      // Tap send button
      await tester.tap(find.byKey(WidgetKeys.forgotPasswordSendButton));
      await tester.pumpAndSettle();

      // After success, should show email sent state
      expect(find.byKey(WidgetKeys.forgotPasswordEmailField), findsNothing);
      expect(find.byKey(WidgetKeys.forgotPasswordSendButton), findsNothing);
      expect(find.byKey(WidgetKeys.forgotPasswordResendButton), findsOneWidget);
      expect(find.byKey(WidgetKeys.forgotPasswordBackToLoginButton),
          findsOneWidget);

      verify(() => context.mockAuthRepository.resetPassword('test@example.com'))
          .called(1);

      // Advance timer past cooldown to avoid pending timer warning
      await tester.pump(const Duration(seconds: 61));
    });

    testWidgets('email sent state shows resend button and back button',
        (tester) async {
      final context = await pumpAuthPage(tester, const ForgotPasswordPage());

      when(() => context.mockAuthRepository.resetPassword('test@example.com'))
          .thenAnswer((_) async => {});

      await tester.enterText(
          find.byKey(WidgetKeys.forgotPasswordEmailField), 'test@example.com');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(WidgetKeys.forgotPasswordSendButton));
      await tester.pumpAndSettle();

      // Check email sent state elements
      expect(find.text('Check Your Email'), findsOneWidget);
      expect(find.byKey(WidgetKeys.forgotPasswordResendButton), findsOneWidget);
      expect(find.byKey(WidgetKeys.forgotPasswordBackToLoginButton),
          findsOneWidget);

      // Advance timer past cooldown to avoid pending timer warning
      await tester.pump(const Duration(seconds: 61));
    });

    testWidgets('resend button is disabled during cooldown', (tester) async {
      final context = await pumpAuthPage(tester, const ForgotPasswordPage());

      when(() => context.mockAuthRepository.resetPassword('test@example.com'))
          .thenAnswer((_) async => {});

      await tester.enterText(
          find.byKey(WidgetKeys.forgotPasswordEmailField), 'test@example.com');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(WidgetKeys.forgotPasswordSendButton));
      await tester.pumpAndSettle();

      // Resend button should be disabled (cooldown active)
      final resendButton = tester.widget<OutlinedButton>(
          find.byKey(WidgetKeys.forgotPasswordResendButton));
      expect(resendButton.onPressed, isNull);

      // Should show countdown text
      expect(find.textContaining('Resend in'), findsOneWidget);

      // Advance timer past cooldown to avoid pending timer warning
      await tester.pump(const Duration(seconds: 61));
    });

    testWidgets('invalid email shows validation error', (tester) async {
      final context = await pumpAuthPage(tester, const ForgotPasswordPage());

      await tester.enterText(
          find.byKey(WidgetKeys.forgotPasswordEmailField), 'invalid-email');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(WidgetKeys.forgotPasswordSendButton));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid email address'), findsOneWidget);

      verifyNever(() => context.mockAuthRepository.resetPassword(any()));
    });

    testWidgets('reset password failure keeps form visible', (tester) async {
      final context = await pumpAuthPage(tester, const ForgotPasswordPage());

      when(() => context.mockAuthRepository.resetPassword('test@example.com'))
          .thenThrow(Exception('Network error'));

      await tester.enterText(
          find.byKey(WidgetKeys.forgotPasswordEmailField), 'test@example.com');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(WidgetKeys.forgotPasswordSendButton));
      await tester.pumpAndSettle();

      // Should still show email field (not in success state)
      expect(find.byKey(WidgetKeys.forgotPasswordEmailField), findsOneWidget);
      expect(find.byKey(WidgetKeys.forgotPasswordSendButton), findsOneWidget);
      expect(find.byKey(WidgetKeys.forgotPasswordResendButton), findsNothing);
    });

    testWidgets('back to login button is present in email sent state',
        (tester) async {
      final context = await pumpAuthPage(tester, const ForgotPasswordPage());

      when(() => context.mockAuthRepository.resetPassword('test@example.com'))
          .thenAnswer((_) async => {});

      await tester.enterText(
          find.byKey(WidgetKeys.forgotPasswordEmailField), 'test@example.com');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(WidgetKeys.forgotPasswordSendButton));
      await tester.pumpAndSettle();

      // Back to login button should be visible
      expect(find.byKey(WidgetKeys.forgotPasswordBackToLoginButton),
          findsOneWidget);
      expect(find.text('Back to Login'), findsOneWidget);

      // Advance timer past cooldown to avoid pending timer warning
      await tester.pump(const Duration(seconds: 61));
    });
  });
}
