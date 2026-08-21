// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'TopBuy Deals';

  @override
  String get todaysPromotion => 'TODAY\'S DEAL 🔥';

  @override
  String get findBestPrices => 'Find the best deals\nat amazing prices!';

  @override
  String get popularProducts => 'Popular Products';

  @override
  String addedToCart(String productName) {
    return '$productName added to cart';
  }

  @override
  String get homePage => 'Home';

  @override
  String get categories => 'Categories';

  @override
  String get favorites => 'Favorites';

  @override
  String get profile => 'Profile';

  @override
  String get electronics => 'Electronics';

  @override
  String get clothing => 'Clothing';

  @override
  String get accessories => 'Accessories';

  @override
  String get homeGoods => 'Home & Living';

  @override
  String get sports => 'Sports & Outdoors';

  @override
  String get cosmetics => 'Beauty & Personal Care';

  @override
  String get noFavoriteProducts => 'No favorite products yet ❤️';

  @override
  String get profileSection => 'My Profile';

  @override
  String get noCategoryProducts => 'No products available in this category';

  @override
  String get addToCart => 'Add to Cart';

  @override
  String get product => 'Product Details';

  @override
  String get currency => '\$';

  @override
  String get discount => 'Save';

  @override
  String get addToCartFull => 'Add to Cart';

  @override
  String get cart => 'Shopping Cart';

  @override
  String get emptyCart => 'Your cart is empty';

  @override
  String priceWithCurrency(String price) {
    return '\$$price';
  }

  @override
  String discountPercent(int percent) {
    return '-$percent%';
  }

  @override
  String discountValue(int percent) {
    return 'Save $percent%';
  }

  @override
  String get language => 'Language';

  @override
  String get searchProducts => 'Search products...';

  @override
  String get noResultsFound => 'No results found';

  @override
  String get recentSearches => 'Recent Searches';

  @override
  String get popularSearches => 'Popular Searches';

  @override
  String get filter => 'Filter';

  @override
  String get sortBy => 'Sort by';

  @override
  String get priceRange => 'Price Range';

  @override
  String get rating => 'Rating';

  @override
  String get availability => 'Availability';

  @override
  String get brand => 'Brand';

  @override
  String get apply => 'Apply';

  @override
  String get clear => 'Clear';

  @override
  String get relevance => 'Relevance';

  @override
  String get priceLowToHigh => 'Price: Low to High';

  @override
  String get priceHighToLow => 'Price: High to Low';

  @override
  String get newest => 'Newest';

  @override
  String get popularity => 'Popularity';

  @override
  String get todaysDeals => 'Today\'s Deals';

  @override
  String get flashDeals => 'Flash Deals';

  @override
  String get priceDrops => 'Price Drops';

  @override
  String get limitedTime => 'Limited Time';

  @override
  String get dealEndsIn => 'Deal ends in';

  @override
  String get reviews => 'Reviews';

  @override
  String get inStock => 'In Stock';

  @override
  String get lowStock => 'Low Stock';

  @override
  String get outOfStock => 'Out of Stock';

  @override
  String get freeShipping => 'Free Shipping';

  @override
  String get specifications => 'Specifications';

  @override
  String get features => 'Features';

  @override
  String get recentlyViewed => 'Recently Viewed';

  @override
  String get continueShopping => 'Continue Shopping';

  @override
  String get bestSeller => 'Best Seller';

  @override
  String get trending => 'Trending';

  @override
  String get newArrival => 'New Arrival';

  @override
  String get flashSale => 'Flash Sale';

  @override
  String get priceDrop => 'Price Drop';

  @override
  String reviewsCount(int count) {
    return '$count reviews';
  }

  @override
  String get productDetails => 'Product Details';

  @override
  String get description => 'Description';

  @override
  String get keyFeatures => 'Key Features';

  @override
  String get shippingInfo => 'Shipping Information';

  @override
  String get estimatedDelivery => 'Estimated Delivery';

  @override
  String get soldBy => 'Sold by';

  @override
  String get addedToWishlist => 'Added to wishlist';

  @override
  String get removedFromWishlist => 'Removed from wishlist';

  @override
  String get buyNow => 'Buy Now';

  @override
  String get share => 'Share';

  @override
  String get relatedProducts => 'Related Products';

  @override
  String get similarDeals => 'Similar Deals';

  @override
  String get youMayAlsoLike => 'You May Also Like';

  @override
  String get customerReviews => 'Customer Reviews';

  @override
  String get ratingDistribution => 'Rating Distribution';

  @override
  String get writeReview => 'Write a Review';

  @override
  String get productInfo => 'Product Information';

  @override
  String get sku => 'SKU';

  @override
  String deliveryIn(String days) {
    return 'Delivery in $days days';
  }

  @override
  String unitsInStock(int count) {
    return '$count units in stock';
  }

  @override
  String onlyLeft(int count) {
    return 'Only $count left!';
  }

  @override
  String selectVariant(String variant) {
    return 'Select $variant';
  }

  @override
  String get color => 'Color';

  @override
  String get size => 'Size';

  @override
  String get quantity => 'Quantity';

  @override
  String get search => 'Search';

  @override
  String get searchHint => 'Search for products, brands, deals...';

  @override
  String get searchResults => 'Search Results';

  @override
  String resultsFor(String query) {
    return 'Results for \"$query\"';
  }

  @override
  String get noResults => 'No products found';

  @override
  String noResultsFor(String query) {
    return 'No results for \"$query\"';
  }

  @override
  String get tryDifferentSearch => 'Try searching with different keywords';

  @override
  String get filters => 'Filters';

  @override
  String get applyFilters => 'Apply Filters';

  @override
  String get clearFilters => 'Clear All';

  @override
  String get filterBy => 'Filter by';

  @override
  String get category => 'Category';

  @override
  String get allCategories => 'All Categories';

  @override
  String get priceMin => 'Min Price';

  @override
  String get priceMax => 'Max Price';

  @override
  String get minRating => 'Minimum Rating';

  @override
  String starsAndUp(int stars) {
    return '$stars stars & up';
  }

  @override
  String get minDiscount => 'Minimum Discount';

  @override
  String discountAndUp(int discount) {
    return '$discount% & up';
  }

  @override
  String get inStockOnly => 'In Stock Only';

  @override
  String get dealsOnly => 'Deals Only';

  @override
  String get sort => 'Sort';

  @override
  String get sortByLabel => 'Sort by:';

  @override
  String productCount(int count) {
    return '$count products';
  }

  @override
  String activeFilters(int count) {
    return '$count active';
  }

  @override
  String get recentSearchesLabel => 'Recent Searches';

  @override
  String get clearSearchHistory => 'Clear History';

  @override
  String get suggestions => 'Suggestions';

  @override
  String get todaysDealsTitle => 'Today\'s Deals';

  @override
  String get biggestDiscountsTitle => 'Biggest Discounts';

  @override
  String get flashDealsTitle => 'Flash Deals';

  @override
  String get trendingDealsTitle => 'Trending Deals';

  @override
  String get priceDropsTitle => 'Price Drops';

  @override
  String get recentlyViewedTitle => 'Recently Viewed';

  @override
  String get recommendedTitle => 'Recommended For You';

  @override
  String get bestSellersTitle => 'Best Sellers';

  @override
  String get viewAll => 'View All';

  @override
  String get seeMore => 'See More';

  @override
  String get save => 'Save';

  @override
  String savingsAmount(String amount) {
    return 'Save $amount';
  }

  @override
  String get upTo => 'Up to';

  @override
  String get off => 'OFF';

  @override
  String get dealOfTheDay => 'Deal of the Day';

  @override
  String get limitedQuantity => 'Limited Quantity';

  @override
  String get hurry => 'Hurry!';

  @override
  String get almostGone => 'Almost Gone!';

  @override
  String get login => 'Login';

  @override
  String get signUp => 'Sign Up';

  @override
  String get logout => 'Logout';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get fullName => 'Full Name';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get emailHint => 'Enter your email';

  @override
  String get passwordHint => 'Enter your password';

  @override
  String get fullNameHint => 'Enter your full name';

  @override
  String get confirmPasswordHint => 'Re-enter your password';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get emailInvalid => 'Enter a valid email address';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters';

  @override
  String get nameRequired => 'Name is required';

  @override
  String get nameTooShort => 'Name must be at least 2 characters';

  @override
  String get confirmPasswordRequired => 'Please confirm your password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get welcomeBack => 'Welcome Back!';

  @override
  String get loginSubtitle => 'Sign in to continue shopping';

  @override
  String get loginSuccess => 'Logged in successfully';

  @override
  String get loginError => 'Login failed. Please check your credentials.';

  @override
  String get createAccount => 'Create Account';

  @override
  String get signUpSubtitle => 'Join TOPBUY DEALS today';

  @override
  String get signUpSuccess => 'Account created successfully!';

  @override
  String get signUpError => 'Sign up failed. Please try again.';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get sendResetLink => 'Send Reset Link';

  @override
  String get resetPasswordDescription =>
      'Enter your email and we\'ll send you a link to reset your password';

  @override
  String get resetPasswordEmailSent => 'Password reset email sent!';

  @override
  String get resetPasswordEmailSentDescription =>
      'We\'ve sent a password reset link to your email. Check your inbox and follow the instructions.';

  @override
  String get resetPasswordError =>
      'Failed to send reset email. Please try again.';

  @override
  String get resetPasswordHelpText =>
      'Didn\'t receive the email? Check your spam folder or try resending.';

  @override
  String get checkYourEmail => 'Check Your Email';

  @override
  String get resendEmail => 'Resend Email';

  @override
  String resendIn(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get backToLogin => 'Back to Login';

  @override
  String get or => 'OR';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get passwordWeak => 'Weak';

  @override
  String get passwordMedium => 'Medium';

  @override
  String get passwordStrong => 'Strong';

  @override
  String get signOut => 'Sign Out';

  @override
  String get myAccount => 'My Account';

  @override
  String get accountSettings => 'Account Settings';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get signedInAs => 'Signed in as';

  @override
  String get guest => 'Guest';

  @override
  String get signInToSeeMore => 'Sign in to access more features';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get phoneNumberHint => 'Enter your phone number';

  @override
  String get phoneNumberInvalid => 'Enter a valid phone number';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get cancel => 'Cancel';

  @override
  String get profileUpdated => 'Profile updated successfully';

  @override
  String get profileUpdateFailed => 'Failed to update profile';

  @override
  String get personalInformation => 'Personal Information';

  @override
  String get preferences => 'Preferences';

  @override
  String get currencyPreference => 'Currency';

  @override
  String get languagePreference => 'Language';

  @override
  String get optional => 'Optional';

  @override
  String get continueWhereLeftOff => 'Continue where you left off';

  @override
  String get savingsUpTo => 'Save up to 50% OFF';

  @override
  String get limitedTimeOffers => 'Limited time offers';

  @override
  String get bestDealsNow => 'Best deals available now';

  @override
  String get mostLovedItems => 'Shop our most loved items';

  @override
  String get updatePersonalInfo => 'Update your personal information';

  @override
  String get confirmSignOut => 'Are you sure you want to sign out?';

  @override
  String get signedOutSuccess => 'Signed out successfully';
}
