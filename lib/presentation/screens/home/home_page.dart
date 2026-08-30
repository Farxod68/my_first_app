import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/ui_helpers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/widget_keys.dart';
import '../../../data/models/product.dart';
import '../../../data/data_sources/local/mock_products.dart';
import '../../../l10n/app_localizations.dart';
import '../../../presentation/providers/cart_provider.dart';
import '../../../presentation/providers/wishlist_provider.dart';
import '../../../presentation/providers/locale_provider.dart';
import '../../../presentation/providers/recently_viewed_provider.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../category/category_page.dart';
import '../product_details/product_details_page.dart';
import '../cart/cart_page.dart';
import '../auth/login_page.dart';
import '../profile/profile_edit_page.dart';
import '../../widgets/product_card.dart';
import '../../widgets/product_search_delegate.dart';
import '../../widgets/home_sections.dart';
import '../../../domain/use_cases/deal_helper.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;
  final TextEditingController searchController = TextEditingController();
  String searchText = '';

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
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Icon(
                      Icons.local_offer,
                      size: 32,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    if (ScreenSize.isDesktop(context)) ...[
                      const SizedBox(height: 8),
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
                  actions: [
                    IconButton(
                      key: WidgetKeys.homeSearchButton,
                      onPressed: () {
                        showSearch(
                          context: context,
                          delegate: ProductSearchDelegate(),
                        );
                      },
                      icon: const Icon(Icons.search),
                    ),
                    Consumer<CartProvider>(
                      builder: (context, cartProvider, child) => Stack(
                        children: [
                          IconButton(
                            key: WidgetKeys.homeCartButton,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      CartPage(cart: cartProvider.cartItems),
                                ),
                              );
                            },
                            icon: const Icon(Icons.shopping_cart_outlined),
                          ),
                          if (cartProvider.itemCount > 0)
                            Positioned(
                              right: 4,
                              top: 4,
                              child: CircleAvatar(
                                key: WidgetKeys.homeCartBadge,
                                radius: 9,
                                backgroundColor: Colors.red,
                                child: Text(
                                  '${cartProvider.itemCount}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
                body: IndexedStack(
                  index: selectedIndex,
                  children: [
                    _buildHome(),
                    _buildCategories(),
                    _buildFavorites(),
                    _buildProfile(),
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
        actions: [
          IconButton(
            key: WidgetKeys.homeSearchButton,
            onPressed: () {
              showSearch(
                context: context,
                delegate: ProductSearchDelegate(),
              );
            },
            icon: const Icon(Icons.search),
          ),
          Consumer<CartProvider>(
            builder: (context, cartProvider, child) => Stack(
              children: [
                IconButton(
                  key: WidgetKeys.homeCartButton,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CartPage(cart: cartProvider.cartItems),
                      ),
                    );
                  },
                  icon: const Icon(Icons.shopping_cart_outlined),
                ),
                if (cartProvider.itemCount > 0)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: CircleAvatar(
                      key: WidgetKeys.homeCartBadge,
                      radius: 9,
                      backgroundColor: Colors.red,
                      child: Text(
                        '${cartProvider.itemCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: selectedIndex,
        children: [
          _buildHome(),
          _buildCategories(),
          _buildFavorites(),
          _buildProfile(),
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

  Widget _buildHome() {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final horizontalPadding = ScreenSize.getHorizontalPadding(context);
    final gridColumns = ScreenSize.getGridColumns(context);
    final isWideScreen = !ScreenSize.isMobile(context);

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // Hero Banner Section
        Container(
          margin: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 16,
          ),
          height: isWideScreen ? 220 : 180,
          constraints: BoxConstraints(
            maxWidth: ScreenSize.isDesktop(context) ? 1200 : double.infinity,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0066CC),
                Color(0xFF0099FF),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0066CC).withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              Positioned(
                right: 20,
                bottom: -30,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(isWideScreen ? 32 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.todaysPromotion,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Colors.white.withValues(alpha: 0.95),
                            letterSpacing: 1.2,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.findBestPrices,
                      style: (isWideScreen
                              ? Theme.of(context).textTheme.headlineLarge
                              : Theme.of(context).textTheme.headlineMedium)
                          ?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Recently Viewed Section (using HorizontalProductSection)
        Consumer<RecentlyViewedProvider>(
          builder: (context, recentlyViewedProvider, child) {
            final recentlyViewed = recentlyViewedProvider.getRecentlyViewedProducts(products);
            return HorizontalProductSection(
              sectionId: 'recently_viewed',
              title: l10n.recentlyViewedTitle,
              subtitle: l10n.continueWhereLeftOff,
              products: recentlyViewed,
              locale: locale,
              horizontalPadding: horizontalPadding,
            );
          },
        ),

        // Popular Categories Section
        PopularCategoriesSection(
          categories: [
            {'key': 'electronics', 'name': l10n.electronics, 'icon': Icons.phone_android},
            {'key': 'clothing', 'name': l10n.clothing, 'icon': Icons.checkroom},
            {'key': 'accessories', 'name': l10n.accessories, 'icon': Icons.watch},
            {'key': 'homeGoods', 'name': l10n.homeGoods, 'icon': Icons.home},
            {'key': 'sports', 'name': l10n.sports, 'icon': Icons.sports_soccer},
            {'key': 'cosmetics', 'name': l10n.cosmetics, 'icon': Icons.face},
          ],
          onCategoryTap: (categoryKey, categoryName) => () {
            final filtered = products.where((p) => p.category == categoryKey).toList();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CategoryPage(
                  title: categoryName,
                  products: filtered,
                  onAddToCart: (product) => addToCart(product, context),
                ),
              ),
            );
          },
          horizontalPadding: horizontalPadding,
        ),

        // Biggest Discounts Section (using DealHelper)
        HorizontalProductSection(
          sectionId: 'biggest_discounts',
          title: l10n.biggestDiscountsTitle,
          subtitle: l10n.savingsUpTo,
          products: DealHelper.getBiggestDiscounts(products)
              .take(DisplayLimits.biggestDiscountsDisplayCount)
              .toList(),
          locale: locale,
          horizontalPadding: horizontalPadding,
        ),

        // Flash Deals Section (using DealHelper)
        HorizontalProductSection(
          sectionId: 'flash_deals',
          title: l10n.flashDealsTitle,
          subtitle: l10n.limitedTimeOffers,
          products: DealHelper.getFlashDeals(products),
          locale: locale,
          horizontalPadding: horizontalPadding,
        ),

        // Today's Deals Section (using DealHelper)
        HorizontalProductSection(
          sectionId: 'todays_deals',
          title: l10n.todaysDealsTitle,
          subtitle: l10n.bestDealsNow,
          products: DealHelper.getTodaysDeals(products)
              .take(DisplayLimits.todaysDealsDisplayCount)
              .toList(),
          locale: locale,
          horizontalPadding: horizontalPadding,
        ),

        // Popular Products Section
        Padding(
          padding:
              EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.popularProducts,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Text(
            l10n.mostLovedItems,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: ScreenSize.isDesktop(context) ? 1400 : double.infinity,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: products.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: gridColumns,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: ScreenSize.isMobile(context) ? 0.60 : 0.65,
                ),
                itemBuilder: (context, index) {
                  final product = products[index];

                  return Consumer<WishlistProvider>(
                    builder: (context, wishlistProvider, child) {
                      final isFavorite =
                          wishlistProvider.isFavorite(product.id);

                      return ProductCard(
                        product: product,
                        isFavorite: isFavorite,
                        onTap: () => openProduct(product, context),
                        onFavoriteToggle: () => toggleFavorite(product, context),
                        locale: locale,
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildCategories() {
    final l10n = AppLocalizations.of(context)!;
    final horizontalPadding = ScreenSize.getHorizontalPadding(context);
    final isWideScreen = !ScreenSize.isMobile(context);

    final categories = [
      {
        'key': 'electronics',
        'name': l10n.electronics,
        'icon': Icons.phone_android
      },
      {'key': 'clothing', 'name': l10n.clothing, 'icon': Icons.checkroom},
      {'key': 'accessories', 'name': l10n.accessories, 'icon': Icons.watch},
      {'key': 'homeGoods', 'name': l10n.homeGoods, 'icon': Icons.home},
      {'key': 'sports', 'name': l10n.sports, 'icon': Icons.sports_soccer},
      {'key': 'cosmetics', 'name': l10n.cosmetics, 'icon': Icons.face},
    ];

    return ListView(
      padding: EdgeInsets.all(horizontalPadding),
      children: [
        if (ScreenSize.isMobile(context))
          Text(
            l10n.categories,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        if (ScreenSize.isMobile(context)) const SizedBox(height: 15),
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isWideScreen ? 800 : double.infinity,
            ),
            child: isWideScreen
                ? GridView.builder(
                    key: WidgetKeys.categoriesGrid,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: categories.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: ScreenSize.isDesktop(context) ? 3 : 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.8,
                    ),
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return Card(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            final filtered = products
                                .where((product) =>
                                    product.category == category['key'])
                                .toList();

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CategoryPage(
                                  title: category['name'] as String,
                                  products: filtered,
                                  onAddToCart: (product) =>
                                      addToCart(product, context),
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  child: Icon(
                                    category['icon'] as IconData,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    category['name'] as String,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios, size: 16),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  )
                : Column(
                    key: WidgetKeys.categoriesGrid,
                    children: [
                      for (final category in categories)
                        Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Icon(category['icon'] as IconData),
                            ),
                            title: Text(category['name'] as String),
                            trailing:
                                const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              final filtered = products
                                  .where((product) =>
                                      product.category == category['key'])
                                  .toList();

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CategoryPage(
                                    title: category['name'] as String,
                                    products: filtered,
                                    onAddToCart: (product) =>
                                      addToCart(product, context),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildFavorites() {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final horizontalPadding = ScreenSize.getHorizontalPadding(context);
    final isWideScreen = !ScreenSize.isMobile(context);

    return Consumer<WishlistProvider>(
      builder: (context, wishlistProvider, child) {
        final favoriteProducts =
            wishlistProvider.getFavoriteProducts(products);

        if (favoriteProducts.isEmpty) {
      return Center(
        key: WidgetKeys.favoritesEmptyState,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noFavoriteProducts,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView(
      key: WidgetKeys.favoritesProductList,
      padding: EdgeInsets.all(horizontalPadding),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isWideScreen ? 800 : double.infinity,
            ),
            child: Column(
              children: [
                for (final product in favoriteProducts)
                  Card(
                    child: ListTile(
                      leading: Icon(product.icon),
                      title: Text(product.name),
                      subtitle: Text(formatPrice(product.price, locale)),
                      trailing: const Icon(
                        Icons.favorite,
                        color: Colors.red,
                      ),
                      onTap: () => openProduct(product, context),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
      },
    );
  }

  Widget _buildProfile() {
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
        const SizedBox(height: 20),
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
              const SizedBox(height: 16),
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
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ] else if (hasAuthProvider) ...[
                const SizedBox(height: 4),
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
        const SizedBox(height: 40),
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
                            if (mounted) {
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
                      onTap: () {
                        setState(() {
                          selectedIndex = 2;
                        });
                      },
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
