import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/widget_keys.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/ui_helpers.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/currency_provider.dart';
import '../../widgets/navigation_chevron.dart';

/// Profile Edit Page
///
/// Precondition: only reachable when `AuthProvider` is registered (see the
/// safety contract comment at its registration in `main.dart`). Every
/// entry point into this page must be gated behind a nullable
/// `context.watch<AuthProvider?>()` check first, as `ProfileTab` does -
/// this page itself reads `AuthProvider` non-nullably in several places
/// (e.g. `_initializeForm`, `_saveProfile`, `build`).
///
/// Allows authenticated users to edit their profile information:
/// - Full name
/// - Phone number
/// - Language preference (synced with app locale)
/// - Currency preference
///
/// Email is displayed as read-only (Supabase auth manages email changes separately)
///
/// Data is persisted to:
/// - Supabase profiles table (via AuthProvider)
/// - Local SharedPreferences (via LocaleProvider and CurrencyProvider)
class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  bool _isDeleting = false;
  String? _selectedLanguage;
  String? _selectedCurrency;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  /// Initialize form with current user data
  void _initializeForm() {
    final authProvider = context.read<AuthProvider>();
    final localeProvider = context.read<LocaleProvider>();
    final currencyProvider = context.read<CurrencyProvider>();

    final user = authProvider.currentUser;

    if (user != null) {
      _fullNameController.text = user.fullName ?? '';
      _phoneController.text = user.phone ?? '';
      _selectedLanguage = user.languageCode;
      _selectedCurrency = user.currencyCode;
    } else {
      // Fallback to local preferences if no user profile
      _selectedLanguage = localeProvider.languageCode;
      _selectedCurrency = currencyProvider.currentCurrency;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Validate phone number format (basic validation)
  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Phone is optional
    }

    // Basic phone validation: at least 10 digits
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.length < 10) {
      final l10n = AppLocalizations.of(context)!;
      return l10n.phoneNumberInvalid;
    }

    return null;
  }

  /// Validate full name
  String? _validateName(String? value) {
    final l10n = AppLocalizations.of(context)!;

    if (value == null || value.trim().isEmpty) {
      return null; // Name is optional in profile edit
    }

    if (value.trim().length < 2) {
      return l10n.nameTooShort;
    }

    return null;
  }

  /// Save profile changes
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final l10n = AppLocalizations.of(context)!;
    final authProvider = context.read<AuthProvider>();
    final localeProvider = context.read<LocaleProvider>();
    final currencyProvider = context.read<CurrencyProvider>();

    try {
      // Update profile in Supabase
      final success = await authProvider.updateProfile(
        fullName: _fullNameController.text.trim().isEmpty
            ? null
            : _fullNameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        languageCode: _selectedLanguage,
        currencyCode: _selectedCurrency,
      );

      if (success) {
        // Sync language preference with LocaleProvider
        if (_selectedLanguage != null) {
          localeProvider.setLocaleByCode(_selectedLanguage!);
        }

        // Sync currency preference with CurrencyProvider
        if (_selectedCurrency != null) {
          currencyProvider.setCurrency(_selectedCurrency!);
        }

        if (mounted) {
          UIHelpers.showSuccessMessage(
            context,
            l10n.profileUpdated,
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          UIHelpers.showErrorMessage(
            context,
            authProvider.error ?? l10n.profileUpdateFailed,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        UIHelpers.showErrorMessage(
          context,
          '${l10n.profileUpdateFailed}: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Show the destructive confirmation dialog, then permanently delete the
  /// account if confirmed.
  Future<void> _deleteAccount() async {
    final l10n = AppLocalizations.of(context)!;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteAccountConfirmTitle),
        content: Text(l10n.deleteAccountConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            key: WidgetKeys.deleteAccountConfirmButton,
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.deleteAccountConfirmButton),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) {
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    final authProvider = context.read<AuthProvider>();

    try {
      final success = await authProvider.deleteAccount();

      if (!mounted) {
        return;
      }

      if (success) {
        UIHelpers.showSuccessMessage(context, l10n.deleteAccountSuccess);
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        UIHelpers.showErrorMessage(
          context,
          authProvider.error ?? l10n.deleteAccountFailed,
        );
      }
    } catch (e) {
      if (mounted) {
        UIHelpers.showErrorMessage(context, '${l10n.deleteAccountFailed}: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    final isWideScreen = !ScreenSize.isMobile(context);
    final horizontalPadding = ScreenSize.getHorizontalPadding(context);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.editProfile),
        ),
        body: Center(
          child: Text(l10n.signInToSeeMore),
        ),
      );
    }

    final languages = LanguageNames.byCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.editProfile),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(horizontalPadding),
          children: [
            const SizedBox(height: AppSpacing.xxl),

            // Profile Avatar Placeholder
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: isWideScreen ? 60 : 50,
                    backgroundColor: Colors.green.shade100,
                    child: user.avatarUrl != null
                        ? ClipOval(
                            child: Image.network(
                              user.avatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.person,
                                size: isWideScreen ? 65 : 55,
                                color: Colors.green,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.person,
                            size: isWideScreen ? 65 : 55,
                            color: Colors.green,
                          ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xxxl),

            // Personal Information Section
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isWideScreen ? ContentWidth.settings : double.infinity,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.personalInformation,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Email (Read-only)
                    TextFormField(
                      initialValue: user.email,
                      decoration: InputDecoration(
                        labelText: l10n.email,
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: const OutlineInputBorder(),
                        enabled: false,
                        filled: true,
                        fillColor: Colors.grey.shade100,
                      ),
                      readOnly: true,
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Full Name
                    TextFormField(
                      controller: _fullNameController,
                      decoration: InputDecoration(
                        labelText: l10n.fullName,
                        hintText: l10n.fullNameHint,
                        prefixIcon: const Icon(Icons.person_outline),
                        border: const OutlineInputBorder(),
                        suffixText: l10n.optional,
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: _validateName,
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Phone Number
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: l10n.phoneNumber,
                        hintText: l10n.phoneNumberHint,
                        prefixIcon: const Icon(Icons.phone_outlined),
                        border: const OutlineInputBorder(),
                        suffixText: l10n.optional,
                      ),
                      keyboardType: TextInputType.phone,
                      validator: _validatePhone,
                    ),

                    const SizedBox(height: AppSpacing.xxxl),

                    // Preferences Section
                    Text(
                      l10n.preferences,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Language Preference
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.language),
                        title: Text(l10n.languagePreference),
                        subtitle: Text(languages[_selectedLanguage] ?? 'English'),
                        trailing: const NavigationChevron(),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(l10n.languagePreference),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: languages.entries.map((entry) {
                                  final isSelected =
                                      entry.key == _selectedLanguage;
                                  return ListTile(
                                    title: Text(entry.value),
                                    trailing: isSelected
                                        ? const Icon(
                                            Icons.check,
                                            color: Colors.green,
                                          )
                                        : null,
                                    onTap: () {
                                      setState(() {
                                        _selectedLanguage = entry.key;
                                      });
                                      Navigator.pop(context);
                                    },
                                  );
                                }).toList(),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    // Currency Preference
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.attach_money),
                        title: Text(l10n.currencyPreference),
                        subtitle: Text(
                            CurrencyProvider.currencyNames[_selectedCurrency] ??
                                'US Dollar'),
                        trailing: const NavigationChevron(),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(l10n.currencyPreference),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: CurrencyProvider.supportedCurrencies
                                    .map((currency) {
                                  final isSelected =
                                      currency == _selectedCurrency;
                                  return ListTile(
                                    title: Text(CurrencyProvider
                                            .currencyNames[currency] ??
                                        currency),
                                    trailing: isSelected
                                        ? const Icon(
                                            Icons.check,
                                            color: Colors.green,
                                          )
                                        : null,
                                    onTap: () {
                                      setState(() {
                                        _selectedCurrency = currency;
                                      });
                                      Navigator.pop(context);
                                    },
                                  );
                                }).toList(),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xxxl),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                l10n.saveChanges,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Cancel Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.pop(context),
                        child: Text(
                          l10n.cancel,
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xxxl),

                    // Danger Zone: permanent account deletion
                    Card(
                      color: Colors.red.shade50,
                      child: ListTile(
                        key: WidgetKeys.deleteAccountButton,
                        leading: const Icon(
                          Icons.delete_forever,
                          color: Colors.red,
                        ),
                        title: Text(
                          l10n.deleteAccount,
                          style: const TextStyle(color: Colors.red),
                        ),
                        subtitle: Text(l10n.deleteAccountSubtitle),
                        trailing: _isDeleting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.red,
                                  strokeWidth: 2,
                                ),
                              )
                            : null,
                        onTap: _isDeleting ? null : _deleteAccount,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
