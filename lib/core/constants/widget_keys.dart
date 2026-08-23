import 'package:flutter/foundation.dart';

/// Centralized widget keys for testing.
///
/// This file contains all widget keys used throughout the application
/// for widget testing purposes. Keys are organized by feature/screen
/// to maintain clarity and prevent duplication.
///
/// Usage:
/// ```dart
/// TextField(
///   key: WidgetKeys.loginEmailField,
///   ...
/// )
/// ```
class WidgetKeys {
  WidgetKeys._();

  // ==========================================================================
  // AUTH FLOW - Login Page
  // ==========================================================================

  static const loginEmailField = Key('login_email_field');
  static const loginPasswordField = Key('login_password_field');
  static const loginPasswordVisibilityToggle = Key('login_password_visibility_toggle');
  static const loginButton = Key('login_button');
  static const loginLoadingIndicator = Key('login_loading_indicator');
  static const loginForgotPasswordButton = Key('login_forgot_password_button');
  static const loginSignUpButton = Key('login_sign_up_button');

  // ==========================================================================
  // AUTH FLOW - Sign Up Page
  // ==========================================================================

  static const signupNameField = Key('signup_name_field');
  static const signupEmailField = Key('signup_email_field');
  static const signupPasswordField = Key('signup_password_field');
  static const signupPasswordVisibilityToggle = Key('signup_password_visibility_toggle');
  static const signupConfirmPasswordField = Key('signup_confirm_password_field');
  static const signupConfirmPasswordVisibilityToggle = Key('signup_confirm_password_visibility_toggle');
  static const signupPasswordStrengthIndicator = Key('signup_password_strength_indicator');
  static const signupButton = Key('signup_button');
  static const signupLoadingIndicator = Key('signup_loading_indicator');
  static const signupLoginButton = Key('signup_login_button');

  // ==========================================================================
  // AUTH FLOW - Forgot Password Page
  // ==========================================================================

  static const forgotPasswordEmailField = Key('forgot_password_email_field');
  static const forgotPasswordSendButton = Key('forgot_password_send_button');
  static const forgotPasswordLoadingIndicator = Key('forgot_password_loading_indicator');
  static const forgotPasswordResendButton = Key('forgot_password_resend_button');
  static const forgotPasswordBackToLoginButton = Key('forgot_password_back_to_login_button');
}
