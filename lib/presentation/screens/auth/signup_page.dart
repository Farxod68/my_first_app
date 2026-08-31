import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/constants/widget_keys.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/auth_helpers.dart';
import '../../../core/utils/ui_helpers.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/password_visibility_toggle.dart';
import 'login_page.dart';

/// Sign up page for TOPBUY DEALS
///
/// Features:
/// - Full name, email, and password registration
/// - Password confirmation
/// - Form validation
/// - Password strength indicator
/// - Password visibility toggle
/// - Loading states
/// - Error handling with user-friendly messages
/// - Navigation to login
/// - Responsive design (mobile/tablet/desktop)
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      fullName: _nameController.text.trim(),
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      // Sync preferences from user profile to local providers
      AuthHelpers.syncPreferencesFromProfile(context, logPrefix: 'SIGNUP');

      // Sign up successful - navigate back to home
      Navigator.pop(context);
      UIHelpers.showSuccessMessage(
        context,
        AppLocalizations.of(context)!.signUpSuccess,
      );
    } else {
      // Show error message
      final error = authProvider.error ?? AppLocalizations.of(context)!.signUpError;
      UIHelpers.showErrorMessage(
        context,
        error,
      );
    }
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return AppLocalizations.of(context)!.nameRequired;
    }
    if (value.length < 2) {
      return AppLocalizations.of(context)!.nameTooShort;
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppLocalizations.of(context)!.confirmPasswordRequired;
    }
    if (value != _passwordController.text) {
      return AppLocalizations.of(context)!.passwordsDoNotMatch;
    }
    return null;
  }

  PasswordStrength _getPasswordStrength(String password) {
    if (password.isEmpty) return PasswordStrength.empty;
    if (password.length < 6) return PasswordStrength.weak;

    int strength = 0;
    if (password.length >= 8) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength++;
    if (RegExp(r'[a-z]').hasMatch(password)) strength++;
    if (RegExp(r'[0-9]').hasMatch(password)) strength++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength++;

    if (strength <= 2) return PasswordStrength.weak;
    if (strength <= 3) return PasswordStrength.medium;
    return PasswordStrength.strong;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isWideScreen = !ScreenSize.isMobile(context);
    final passwordStrength = _getPasswordStrength(_passwordController.text);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.signUp),
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
                  // Logo/Icon
                  Icon(
                    Icons.person_add_outlined,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Title
                  Text(
                    l10n.createAccount,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Subtitle
                  Text(
                    l10n.signUpSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xxxl),

                  // Full name field
                  TextFormField(
                    key: WidgetKeys.signupNameField,
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      labelText: l10n.fullName,
                      hintText: l10n.fullNameHint,
                      prefixIcon: const Icon(Icons.person_outlined),
                      border: const OutlineInputBorder(),
                    ),
                    validator: _validateName,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Email field
                  TextFormField(
                    key: WidgetKeys.signupEmailField,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      labelText: l10n.email,
                      hintText: l10n.emailHint,
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) => FormValidators.validateEmail(context, value),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Password field
                  TextFormField(
                    key: WidgetKeys.signupPasswordField,
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    enabled: !_isLoading,
                    onChanged: (_) => setState(() {}), // Update strength indicator
                    decoration: InputDecoration(
                      labelText: l10n.password,
                      hintText: l10n.passwordHint,
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: PasswordVisibilityToggle(
                        key: WidgetKeys.signupPasswordVisibilityToggle,
                        obscured: _obscurePassword,
                        onToggle: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) => FormValidators.validatePassword(context, value),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Password strength indicator
                  if (passwordStrength != PasswordStrength.empty)
                    Column(
                      key: WidgetKeys.signupPasswordStrengthIndicator,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: LinearProgressIndicator(
                                value: passwordStrength.value,
                                backgroundColor: Colors.grey.shade300,
                                color: passwordStrength.color,
                                minHeight: 4,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Text(
                              passwordStrength.label(l10n),
                              style: TextStyle(
                                fontSize: 12,
                                color: passwordStrength.color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                    ),

                  // Confirm password field
                  TextFormField(
                    key: WidgetKeys.signupConfirmPasswordField,
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    textInputAction: TextInputAction.done,
                    enabled: !_isLoading,
                    onFieldSubmitted: (_) => _handleSignUp(),
                    decoration: InputDecoration(
                      labelText: l10n.confirmPassword,
                      hintText: l10n.confirmPasswordHint,
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: PasswordVisibilityToggle(
                        key: WidgetKeys.signupConfirmPasswordVisibilityToggle,
                        obscured: _obscureConfirmPassword,
                        onToggle: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    validator: _validateConfirmPassword,
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Sign up button
                  ElevatedButton(
                    key: WidgetKeys.signupButton,
                    onPressed: _isLoading ? null : _handleSignUp,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            key: WidgetKeys.signupLoadingIndicator,
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            l10n.signUp,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Divider
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        child: Text(
                          l10n.or,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Login link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(child: Text(l10n.alreadyHaveAccount)),
                      TextButton(
                        key: WidgetKeys.signupLoginButton,
                        onPressed: _isLoading
                            ? null
                            : () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const LoginPage(),
                                  ),
                                );
                              },
                        child: Text(
                          l10n.login,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
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

/// Password strength enum
enum PasswordStrength {
  empty(0, Colors.transparent),
  weak(0.33, Colors.red),
  medium(0.66, Colors.orange),
  strong(1.0, Colors.green);

  final double value;
  final Color color;

  const PasswordStrength(this.value, this.color);

  String label(AppLocalizations l10n) {
    switch (this) {
      case PasswordStrength.empty:
        return '';
      case PasswordStrength.weak:
        return l10n.passwordWeak;
      case PasswordStrength.medium:
        return l10n.passwordMedium;
      case PasswordStrength.strong:
        return l10n.passwordStrong;
    }
  }
}
