import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/constants/widget_keys.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/ui_helpers.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/button_loading_indicator.dart';

/// Forgot password page for TOPBUY DEALS
///
/// Features:
/// - Email input for password reset
/// - Form validation
/// - Loading states
/// - Success/error messages
/// - Resend button with timer
/// - Responsive design (mobile/tablet/desktop)
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;
  int _resendCooldown = 0;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.resetPassword(
      _emailController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (success) {
        _emailSent = true;
        _startResendCooldown();
      }
    });

    if (success) {
      UIHelpers.showSuccessMessage(
        context,
        AppLocalizations.of(context)!.resetPasswordEmailSent,
      );
    } else {
      final error = authProvider.error ?? AppLocalizations.of(context)!.resetPasswordError;
      UIHelpers.showErrorMessage(
        context,
        error,
      );
    }
  }

  void _startResendCooldown() {
    setState(() => _resendCooldown = 60);
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _resendCooldown--);
      return _resendCooldown > 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isWideScreen = !ScreenSize.isMobile(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.forgotPassword),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(ScreenSize.getHorizontalPadding(context)),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isWideScreen ? ContentWidth.authForm : double.infinity,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icon
                  Icon(
                    _emailSent ? Icons.mark_email_read_outlined : Icons.lock_reset,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Title
                  Text(
                    _emailSent ? l10n.checkYourEmail : l10n.resetPassword,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Subtitle
                  Text(
                    _emailSent
                        ? l10n.resetPasswordEmailSentDescription
                        : l10n.resetPasswordDescription,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xxxl),

                  if (!_emailSent) ...[
                    // Email field
                    TextFormField(
                      key: WidgetKeys.forgotPasswordEmailField,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      enabled: !_isLoading,
                      onFieldSubmitted: (_) => _handleResetPassword(),
                      decoration: InputDecoration(
                        labelText: l10n.email,
                        hintText: l10n.emailHint,
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) => FormValidators.validateEmail(context, value),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // Send reset link button
                    ElevatedButton(
                      key: WidgetKeys.forgotPasswordSendButton,
                      onPressed: _isLoading ? null : _handleResetPassword,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const ButtonLoadingIndicator(
                              key: WidgetKeys.forgotPasswordLoadingIndicator,
                            )
                          : Text(
                              l10n.sendResetLink,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ] else ...[
                    // Success state - Resend button
                    OutlinedButton.icon(
                      key: WidgetKeys.forgotPasswordResendButton,
                      onPressed: _resendCooldown > 0 ? null : _handleResetPassword,
                      icon: const Icon(Icons.refresh),
                      label: Text(
                        _resendCooldown > 0
                            ? l10n.resendIn(_resendCooldown)
                            : l10n.resendEmail,
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Back to login button
                    ElevatedButton(
                      key: WidgetKeys.forgotPasswordBackToLoginButton,
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        l10n.backToLogin,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.xxl),

                  // Help text
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.info,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            l10n.resetPasswordHelpText,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
