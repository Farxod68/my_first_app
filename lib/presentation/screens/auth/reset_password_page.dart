import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/widget_keys.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/ui_helpers.dart';
import '../../../core/utils/validators.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/button_loading_indicator.dart';

/// Set-new-password page, shown after the user opens a password-recovery
/// email link (`AuthProvider.passwordRecoveryPending`).
///
/// Precondition: only built while `AuthProvider` is registered (see the
/// safety contract at its registration in `main.dart`).
class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.updatePassword(_passwordController.text);

    if (!mounted) return;
    setState(() => _isLoading = false);

    final l10n = AppLocalizations.of(context)!;
    if (success) {
      UIHelpers.showSuccessMessage(context, l10n.resetPasswordSuccess);
    } else {
      UIHelpers.showErrorMessage(context, l10n.resetPasswordFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isWideScreen = !ScreenSize.isMobile(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.resetPasswordTitle),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            key: WidgetKeys.resetPasswordCancelButton,
            onPressed: _isLoading
                ? null
                : () => context.read<AuthProvider>().cancelPasswordRecovery(),
            child: Text(l10n.cancel),
          ),
        ],
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.lock_reset,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  TextFormField(
                    key: WidgetKeys.resetPasswordNewField,
                    controller: _passwordController,
                    obscureText: _obscure,
                    enabled: !_isLoading,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: l10n.newPassword,
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (value) =>
                        FormValidators.validatePassword(context, value),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    key: WidgetKeys.resetPasswordConfirmField,
                    controller: _confirmController,
                    obscureText: _obscure,
                    enabled: !_isLoading,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: l10n.confirmPassword,
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.confirmPasswordRequired;
                      }
                      if (value != _passwordController.text) {
                        return l10n.passwordsDoNotMatch;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  ElevatedButton(
                    key: WidgetKeys.resetPasswordSubmitButton,
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const ButtonLoadingIndicator()
                        : Text(l10n.resetPasswordSubmit),
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
