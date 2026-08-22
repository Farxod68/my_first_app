import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/ui_helpers.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/currency_provider.dart';

/// Profile Edit Page
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

    final Map<String, String> languages = {
      'en': 'English',
      'es': 'Español',
      'fr': 'Français',
      'uz': "O'zbekcha",
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.editProfile),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(horizontalPadding),
          children: [
            const SizedBox(height: 24),

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

            const SizedBox(height: 32),

            // Personal Information Section
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isWideScreen ? 600 : double.infinity,
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
                    const SizedBox(height: 16),

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

                    const SizedBox(height: 16),

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

                    const SizedBox(height: 16),

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

                    const SizedBox(height: 32),

                    // Preferences Section
                    Text(
                      l10n.preferences,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),

                    // Language Preference
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.language),
                        title: Text(l10n.languagePreference),
                        subtitle: Text(languages[_selectedLanguage] ?? 'English'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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

                    const SizedBox(height: 8),

                    // Currency Preference
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.attach_money),
                        title: Text(l10n.currencyPreference),
                        subtitle: Text(
                            CurrencyProvider.currencyNames[_selectedCurrency] ??
                                'US Dollar'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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

                    const SizedBox(height: 32),

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

                    const SizedBox(height: 16),

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

                    const SizedBox(height: 24),
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
