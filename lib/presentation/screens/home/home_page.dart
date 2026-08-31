import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/ui_helpers.dart';
import '../../../core/constants/widget_keys.dart';
import '../../../data/models/product.dart';
import '../../../l10n/app_localizations.dart';
import '../../../presentation/providers/cart_provider.dart';
import '../../../presentation/providers/wishlist_provider.dart';
import '../product_details/product_details_page.dart';
import '../../widgets/home_app_bar_actions.dart';
import 'tabs/home_tab.dart';
import 'tabs/categories_tab.dart';
import 'tabs/favorites_tab.dart';
import 'tabs/profile_tab.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;

  void addToCart(Product product, BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    cartProvider.addToCart(product);

    final l10n = AppLocalizations.of(context)!;
    UIHelpers.showInfoMessage(
      context,
      l10n.addedToCart(product.name),
    );
  }

  void toggleFavorite(Product product, BuildContext context) {
    final wishlistProvider =
        Provider.of<WishlistProvider>(context, listen: false);
    wishlistProvider.toggleFavorite(product.id);
  }

  void openProduct(Product product, BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailsPage(product: product),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isWideScreen = !ScreenSize.isMobile(context);

    // Use adaptive layout for tablet and desktop
    if (isWideScreen) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  selectedIndex = index;
                });
              },
              labelType: ScreenSize.isDesktop(context)
                  ? NavigationRailLabelType.selected
                  : NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                child: Column(
                  children: [
                    Icon(
                      Icons.local_offer,
                      size: 32,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    if (ScreenSize.isDesktop(context)) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        l10n.appTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
              destinations: [
                NavigationRailDestination(
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon: const Icon(Icons.home),
                  label: Text(l10n.homePage),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.category_outlined),
                  selectedIcon: const Icon(Icons.category),
                  label: Text(l10n.categories),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.favorite_border),
                  selectedIcon: const Icon(Icons.favorite),
                  label: Text(l10n.favorites),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.person_outline),
                  selectedIcon: const Icon(Icons.person),
                  label: Text(l10n.profile),
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: Scaffold(
                appBar: AppBar(
                  title: Text(
                    _getPageTitle(l10n),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  actions: HomeAppBarActions.build(context, trailingGap: true),
                ),
                body: IndexedStack(
                  index: selectedIndex,
                  children: [
                    HomeTab(
                      onAddToCart: addToCart,
                      onOpenProduct: openProduct,
                      onToggleFavorite: toggleFavorite,
                    ),
                    CategoriesTab(onAddToCart: addToCart),
                    FavoritesTab(onOpenProduct: openProduct),
                    ProfileTab(
                      onNavigateToFavorites: () {
                        setState(() {
                          selectedIndex = 2;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Mobile layout with bottom navigation
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.appTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: HomeAppBarActions.build(context),
      ),
      body: IndexedStack(
        index: selectedIndex,
        children: [
          HomeTab(
            onAddToCart: addToCart,
            onOpenProduct: openProduct,
            onToggleFavorite: toggleFavorite,
          ),
          CategoriesTab(onAddToCart: addToCart),
          FavoritesTab(onOpenProduct: openProduct),
          ProfileTab(
            onNavigateToFavorites: () {
              setState(() {
                selectedIndex = 2;
              });
            },
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        key: WidgetKeys.homeBottomNavigationBar,
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            key: WidgetKeys.homeTab,
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l10n.homePage,
          ),
          NavigationDestination(
            key: WidgetKeys.categoriesTab,
            icon: const Icon(Icons.category_outlined),
            selectedIcon: const Icon(Icons.category),
            label: l10n.categories,
          ),
          NavigationDestination(
            key: WidgetKeys.favoritesTab,
            icon: const Icon(Icons.favorite_border),
            selectedIcon: const Icon(Icons.favorite),
            label: l10n.favorites,
          ),
          NavigationDestination(
            key: WidgetKeys.profileTab,
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: l10n.profile,
          ),
        ],
      ),
    );
  }

  String _getPageTitle(AppLocalizations l10n) {
    switch (selectedIndex) {
      case 0:
        return l10n.appTitle;
      case 1:
        return l10n.categories;
      case 2:
        return l10n.favorites;
      case 3:
        return l10n.profile;
      default:
        return l10n.appTitle;
    }
  }
}
