import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/ui_helpers.dart';
import '../../../../core/constants/widget_keys.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/wishlist_provider.dart';
import '../../../providers/locale_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../cart/cart_page.dart';
import '../../auth/login_page.dart';
import '../../profile/profile_edit_page.dart';

/// Profile tab content.
///
/// Phase 1 structural decomposition: extracted verbatim from
/// `HomePage._buildProfile()`. No visual or behavioral change, with one
/// mechanical exception required by the `StatefulWidget` -> `StatelessWidget`
/// move: the original logout handler guarded a post-`await` `setState`-free
/// UI call with `State.mounted`. A `StatelessWidget` has no `State`, so the
/// direct equivalent — `context.mounted` — is used instead. This checks the
/// exact same thing (whether the BuildContext is still in the tree after the
/// async gap) and does not change behavior.
///
/// The "Favorites" row still needs to switch `HomePage`'s shared
/// `selectedIndex` (so the bottom nav / rail highlight updates too), so that
/// one interaction is exposed as [onNavigateToFavorites] instead of calling
/// `setState` directly.
class ProfileTab extends StatelessWidget {
  final VoidCallback onNavigateToFavorites;

  const ProfileTab({
    super.key,
    required this.onNavigateToFavorites,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final horizontalPadding = ScreenSize.getHorizontalPadding(context);
    final isWideScreen = !ScreenSize.isMobile(context);

    final Map<String, String> languages = {
      'en': 'English',
      'es': 'Español',
      'fr': 'Français',
      'uz': 'O\'zbekcha',
    };

    // Check if Supabase is initialized and get auth state
    final hasAuthProvider = context.watch<AuthProvider?>() != null;
    final authProvider = hasAuthProvider ? context.watch<AuthProvider>() : null;
    final isAuthenticated = authProvider?.isAuthenticated ?? false;
    final user = authProvider?.currentUser;

    return ListView(
      padding: EdgeInsets.all(horizontalPadding),
      children: [
        const SizedBox(height: AppSpacing.xl),
        Center(
          child: Column(
            children: [
              CircleAvatar(
                key: WidgetKeys.profileAvatar,
                radius: isWideScreen ? 60 : 50,
                backgroundColor: isAuthenticated
                    ? Colors.green.shade100
                    : Colors.deepOrange.shade100,
                child: isAuthenticated && user?.avatarUrl != null
                    ? ClipOval(
                        child: Image.network(
                          user!.avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.person,
                            size: isWideScreen ? 65 : 55,
                            color: Colors.green,
                          ),
                        ),
                      )
                    : Icon(
                        isAuthenticated ? Icons.person : Icons.person_outline,
                        size: isWideScreen ? 65 : 55,
                        color: isAuthenticated ? Colors.green : Colors.deepOrange,
                      ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                isAuthenticated
                    ? (user?.displayName ?? l10n.myAccount)
                    : l10n.profileSection,
                style: TextStyle(
                  fontSize: isWideScreen ? 28 : 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isAuthenticated && user != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  user.email,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ] else if (hasAuthProvider) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.guest,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxxxl),
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isWideScreen ? 600 : double.infinity,
            ),
            child: Card(
              child: Column(
                children: [
                  // Edit Profile section (for authenticated users)
                  if (hasAuthProvider && isAuthenticated) ...[
                    ListTile(
                      key: WidgetKeys.profileEditButton,
                      leading: const Icon(Icons.edit_outlined),
                      title: Text(l10n.editProfile),
                      subtitle: Text(l10n.updatePersonalInfo),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfileEditPage(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                  ],

                  // Login/Logout section
                  if (hasAuthProvider) ...[
                    if (!isAuthenticated)
                      ListTile(
                        key: WidgetKeys.profileLoginButton,
                        leading: const Icon(Icons.login),
                        title: Text(l10n.login),
                        subtitle: Text(l10n.signInToSeeMore),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginPage(),
                            ),
                          );
                        },
                      )
                    else
                      ListTile(
                        leading: const Icon(Icons.logout),
                        title: Text(l10n.logout),
                        subtitle: Text('${l10n.signedInAs} ${user?.email}'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(l10n.logout),
                              content: Text(l10n.confirmSignOut),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: Text(l10n.cancel),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text(l10n.logout),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await authProvider?.signOut();
                            if (context.mounted) {
                              UIHelpers.showSuccessMessage(
                                context,
                                l10n.signedOutSuccess,
                              );
                            }
                          }
                        },
                      ),
                    const Divider(height: 1),
                  ],
                  ListTile(
                    key: WidgetKeys.profileLanguageDropdown,
                    leading: const Icon(Icons.language),
                    title: Text(l10n.language),
                    subtitle: Text(languages[locale] ?? 'English'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(l10n.language),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: languages.entries.map((entry) {
                              final isSelected = entry.key == locale;
                              return ListTile(
                                title: Text(entry.value),
                                trailing: isSelected
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.deepOrange,
                                      )
                                    : null,
                                onTap: () {
                                  Navigator.pop(context);
                                  context
                                      .read<LocaleProvider>()
                                      .setLocale(Locale(entry.key));
                                  UIHelpers.showInfoMessage(
                                    context,
                                    'Language changed to ${entry.value}',
                                    duration: const Duration(seconds: 1),
                                  );
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  Consumer<CartProvider>(
                    builder: (context, cartProvider, child) => ListTile(
                      leading: const Icon(Icons.shopping_bag),
                      title: Text(l10n.cart),
                      trailing: cartProvider.itemCount > 0
                          ? CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.deepOrange,
                              child: Text(
                                '${cartProvider.itemCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            )
                          : const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CartPage(cart: cartProvider.cartItems),
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  Consumer<WishlistProvider>(
                    builder: (context, wishlistProvider, child) => ListTile(
                      leading: const Icon(Icons.favorite),
                      title: Text(l10n.favorites),
                      trailing: wishlistProvider.count > 0
                          ? CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.red,
                              child: Text(
                                '${wishlistProvider.count}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            )
                          : const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: onNavigateToFavorites,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
