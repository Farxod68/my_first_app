import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_first_app/core/constants/widget_keys.dart';
import 'package:my_first_app/presentation/screens/auth/reset_password_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../helpers/auth_test_helpers.dart';

void main() {
  group('Reset Password Flow Tests', () {
    testWidgets('renders all form elements with correct keys', (tester) async {
      await pumpAuthPage(tester, const ResetPasswordPage());

      expect(find.byKey(WidgetKeys.resetPasswordNewField), findsOneWidget);
      expect(find.byKey(WidgetKeys.resetPasswordConfirmField), findsOneWidget);
      expect(find.byKey(WidgetKeys.resetPasswordSubmitButton), findsOneWidget);
      expect(find.byKey(WidgetKeys.resetPasswordCancelButton), findsOneWidget);
    });

    testWidgets('short password shows validation error and does not submit',
        (tester) async {
      final context = await pumpAuthPage(tester, const ResetPasswordPage());

      await tester.enterText(find.byKey(WidgetKeys.resetPasswordNewField), '123');
      await tester.enterText(
          find.byKey(WidgetKeys.resetPasswordConfirmField), '123');
      await tester.tap(find.byKey(WidgetKeys.resetPasswordSubmitButton));
      await tester.pump();

      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
      verifyNever(() => context.mockAuthRepository.updatePassword(any()));
    });

    testWidgets('mismatched confirmation shows error and does not submit',
        (tester) async {
      final context = await pumpAuthPage(tester, const ResetPasswordPage());

      await tester.enterText(
          find.byKey(WidgetKeys.resetPasswordNewField), 'secret-123');
      await tester.enterText(
          find.byKey(WidgetKeys.resetPasswordConfirmField), 'secret-124');
      await tester.tap(find.byKey(WidgetKeys.resetPasswordSubmitButton));
      await tester.pump();

      expect(find.text('Passwords do not match'), findsOneWidget);
      verifyNever(() => context.mockAuthRepository.updatePassword(any()));
    });

    testWidgets('valid submit updates the password and shows success',
        (tester) async {
      final context = await pumpAuthPage(tester, const ResetPasswordPage());
      when(() => context.mockAuthRepository.updatePassword(any()))
          .thenAnswer((_) async {});

      await tester.enterText(
          find.byKey(WidgetKeys.resetPasswordNewField), 'secret-123');
      await tester.enterText(
          find.byKey(WidgetKeys.resetPasswordConfirmField), 'secret-123');
      await tester.tap(find.byKey(WidgetKeys.resetPasswordSubmitButton));
      await tester.pumpAndSettle();

      verify(() => context.mockAuthRepository.updatePassword('secret-123'))
          .called(1);
      expect(find.text('Password updated successfully!'), findsOneWidget);
    });

    testWidgets('failed update shows the error message', (tester) async {
      final context = await pumpAuthPage(tester, const ResetPasswordPage());
      when(() => context.mockAuthRepository.updatePassword(any()))
          .thenThrow(AuthException('Link expired'));

      await tester.enterText(
          find.byKey(WidgetKeys.resetPasswordNewField), 'secret-123');
      await tester.enterText(
          find.byKey(WidgetKeys.resetPasswordConfirmField), 'secret-123');
      await tester.tap(find.byKey(WidgetKeys.resetPasswordSubmitButton));
      await tester.pumpAndSettle();

      expect(find.textContaining('Could not update the password'), findsOneWidget);
    });
  });
}
