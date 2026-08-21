import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_uz.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('uz'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'TopBuy Deals'**
  String get appTitle;

  /// Banner text for today's promotion
  ///
  /// In en, this message translates to:
  /// **'TODAY\'S DEAL 🔥'**
  String get todaysPromotion;

  /// Promotional message on home page
  ///
  /// In en, this message translates to:
  /// **'Find the best deals\nat amazing prices!'**
  String get findBestPrices;

  /// Popular products section title
  ///
  /// In en, this message translates to:
  /// **'Popular Products'**
  String get popularProducts;

  /// Snackbar message when product is added to cart
  ///
  /// In en, this message translates to:
  /// **'{productName} added to cart'**
  String addedToCart(String productName);

  /// Home page navigation label
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homePage;

  /// Categories page navigation label
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// Favorites page navigation label
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// Profile page navigation label
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Electronics category name
  ///
  /// In en, this message translates to:
  /// **'Electronics'**
  String get electronics;

  /// Clothing category name
  ///
  /// In en, this message translates to:
  /// **'Clothing'**
  String get clothing;

  /// Accessories category name
  ///
  /// In en, this message translates to:
  /// **'Accessories'**
  String get accessories;

  /// Home goods category name
  ///
  /// In en, this message translates to:
  /// **'Home & Living'**
  String get homeGoods;

  /// Sports category name
  ///
  /// In en, this message translates to:
  /// **'Sports & Outdoors'**
  String get sports;

  /// Cosmetics category name
  ///
  /// In en, this message translates to:
  /// **'Beauty & Personal Care'**
  String get cosmetics;

  /// Message when favorites list is empty
  ///
  /// In en, this message translates to:
  /// **'No favorite products yet ❤️'**
  String get noFavoriteProducts;

  /// Profile section subtitle
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get profileSection;

  /// Message when category has no products
  ///
  /// In en, this message translates to:
  /// **'No products available in this category'**
  String get noCategoryProducts;

  /// Add to cart button text
  ///
  /// In en, this message translates to:
  /// **'Add to Cart'**
  String get addToCart;

  /// Product details page title
  ///
  /// In en, this message translates to:
  /// **'Product Details'**
  String get product;

  /// Currency symbol
  ///
  /// In en, this message translates to:
  /// **'\$'**
  String get currency;

  /// Discount label
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get discount;

  /// Full add to cart button text
  ///
  /// In en, this message translates to:
  /// **'Add to Cart'**
  String get addToCartFull;

  /// Cart page title
  ///
  /// In en, this message translates to:
  /// **'Shopping Cart'**
  String get cart;

  /// Message when cart is empty
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty'**
  String get emptyCart;

  /// Price formatted with currency
  ///
  /// In en, this message translates to:
  /// **'\${price}'**
  String priceWithCurrency(String price);

  /// Discount percentage badge
  ///
  /// In en, this message translates to:
  /// **'-{percent}%'**
  String discountPercent(int percent);

  /// Discount value text
  ///
  /// In en, this message translates to:
  /// **'Save {percent}%'**
  String discountValue(int percent);

  /// Language selector label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Search input placeholder
  ///
  /// In en, this message translates to:
  /// **'Search products...'**
  String get searchProducts;

  /// Message when search returns no results
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFound;

  /// Recent searches section title
  ///
  /// In en, this message translates to:
  /// **'Recent Searches'**
  String get recentSearches;

  /// Popular searches section title
  ///
  /// In en, this message translates to:
  /// **'Popular Searches'**
  String get popularSearches;

  /// Filter button label
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// Sort selector label
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// Price range filter label
  ///
  /// In en, this message translates to:
  /// **'Price Range'**
  String get priceRange;

  /// Rating label
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// Availability filter label
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get availability;

  /// Brand filter label
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get brand;

  /// Apply filters button
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// Clear filters button
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// Sort by relevance option
  ///
  /// In en, this message translates to:
  /// **'Relevance'**
  String get relevance;

  /// Sort by price ascending
  ///
  /// In en, this message translates to:
  /// **'Price: Low to High'**
  String get priceLowToHigh;

  /// Sort by price descending
  ///
  /// In en, this message translates to:
  /// **'Price: High to Low'**
  String get priceHighToLow;

  /// Sort by newest option
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get newest;

  /// Sort by popularity option
  ///
  /// In en, this message translates to:
  /// **'Popularity'**
  String get popularity;

  /// Today's deals section title
  ///
  /// In en, this message translates to:
  /// **'Today\'s Deals'**
  String get todaysDeals;

  /// Flash deals section title
  ///
  /// In en, this message translates to:
  /// **'Flash Deals'**
  String get flashDeals;

  /// Price drops section title
  ///
  /// In en, this message translates to:
  /// **'Price Drops'**
  String get priceDrops;

  /// Limited time badge
  ///
  /// In en, this message translates to:
  /// **'Limited Time'**
  String get limitedTime;

  /// Deal countdown prefix
  ///
  /// In en, this message translates to:
  /// **'Deal ends in'**
  String get dealEndsIn;

  /// Reviews label
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviews;

  /// In stock badge
  ///
  /// In en, this message translates to:
  /// **'In Stock'**
  String get inStock;

  /// Low stock badge
  ///
  /// In en, this message translates to:
  /// **'Low Stock'**
  String get lowStock;

  /// Out of stock badge
  ///
  /// In en, this message translates to:
  /// **'Out of Stock'**
  String get outOfStock;

  /// Free shipping badge
  ///
  /// In en, this message translates to:
  /// **'Free Shipping'**
  String get freeShipping;

  /// Specifications section title
  ///
  /// In en, this message translates to:
  /// **'Specifications'**
  String get specifications;

  /// Features section title
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get features;

  /// Recently viewed section title
  ///
  /// In en, this message translates to:
  /// **'Recently Viewed'**
  String get recentlyViewed;

  /// Continue shopping button
  ///
  /// In en, this message translates to:
  /// **'Continue Shopping'**
  String get continueShopping;

  /// Best seller badge
  ///
  /// In en, this message translates to:
  /// **'Best Seller'**
  String get bestSeller;

  /// Trending badge
  ///
  /// In en, this message translates to:
  /// **'Trending'**
  String get trending;

  /// New arrival badge
  ///
  /// In en, this message translates to:
  /// **'New Arrival'**
  String get newArrival;

  /// Flash sale badge
  ///
  /// In en, this message translates to:
  /// **'Flash Sale'**
  String get flashSale;

  /// Price drop badge
  ///
  /// In en, this message translates to:
  /// **'Price Drop'**
  String get priceDrop;

  /// Review count display
  ///
  /// In en, this message translates to:
  /// **'{count} reviews'**
  String reviewsCount(int count);

  /// Product details page title
  ///
  /// In en, this message translates to:
  /// **'Product Details'**
  String get productDetails;

  /// Description section label
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// Key features section title
  ///
  /// In en, this message translates to:
  /// **'Key Features'**
  String get keyFeatures;

  /// Shipping information section title
  ///
  /// In en, this message translates to:
  /// **'Shipping Information'**
  String get shippingInfo;

  /// Estimated delivery label
  ///
  /// In en, this message translates to:
  /// **'Estimated Delivery'**
  String get estimatedDelivery;

  /// Seller prefix
  ///
  /// In en, this message translates to:
  /// **'Sold by'**
  String get soldBy;

  /// Snackbar message when product added to wishlist
  ///
  /// In en, this message translates to:
  /// **'Added to wishlist'**
  String get addedToWishlist;

  /// Snackbar message when product removed from wishlist
  ///
  /// In en, this message translates to:
  /// **'Removed from wishlist'**
  String get removedFromWishlist;

  /// Buy now button text
  ///
  /// In en, this message translates to:
  /// **'Buy Now'**
  String get buyNow;

  /// Share button label
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// Related products section title
  ///
  /// In en, this message translates to:
  /// **'Related Products'**
  String get relatedProducts;

  /// Similar deals section title
  ///
  /// In en, this message translates to:
  /// **'Similar Deals'**
  String get similarDeals;

  /// Recommendations section title
  ///
  /// In en, this message translates to:
  /// **'You May Also Like'**
  String get youMayAlsoLike;

  /// Customer reviews section title
  ///
  /// In en, this message translates to:
  /// **'Customer Reviews'**
  String get customerReviews;

  /// Rating distribution label
  ///
  /// In en, this message translates to:
  /// **'Rating Distribution'**
  String get ratingDistribution;

  /// Write review button
  ///
  /// In en, this message translates to:
  /// **'Write a Review'**
  String get writeReview;

  /// Product information section title
  ///
  /// In en, this message translates to:
  /// **'Product Information'**
  String get productInfo;

  /// SKU label
  ///
  /// In en, this message translates to:
  /// **'SKU'**
  String get sku;

  /// Delivery estimate
  ///
  /// In en, this message translates to:
  /// **'Delivery in {days} days'**
  String deliveryIn(String days);

  /// Stock count display
  ///
  /// In en, this message translates to:
  /// **'{count} units in stock'**
  String unitsInStock(int count);

  /// Low stock urgency message
  ///
  /// In en, this message translates to:
  /// **'Only {count} left!'**
  String onlyLeft(int count);

  /// Select variant prompt
  ///
  /// In en, this message translates to:
  /// **'Select {variant}'**
  String selectVariant(String variant);

  /// Color variant label
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// Size variant label
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get size;

  /// Quantity label
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// Search label
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// Search input hint
  ///
  /// In en, this message translates to:
  /// **'Search for products, brands, deals...'**
  String get searchHint;

  /// Search results page title
  ///
  /// In en, this message translates to:
  /// **'Search Results'**
  String get searchResults;

  /// Search results header
  ///
  /// In en, this message translates to:
  /// **'Results for \"{query}\"'**
  String resultsFor(String query);

  /// No search results message
  ///
  /// In en, this message translates to:
  /// **'No products found'**
  String get noResults;

  /// No search results for query
  ///
  /// In en, this message translates to:
  /// **'No results for \"{query}\"'**
  String noResultsFor(String query);

  /// No results suggestion
  ///
  /// In en, this message translates to:
  /// **'Try searching with different keywords'**
  String get tryDifferentSearch;

  /// Filters label
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// Apply filters button
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get applyFilters;

  /// Clear filters button
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearFilters;

  /// Filter by label
  ///
  /// In en, this message translates to:
  /// **'Filter by'**
  String get filterBy;

  /// Category filter label
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// All categories option
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get allCategories;

  /// Minimum price label
  ///
  /// In en, this message translates to:
  /// **'Min Price'**
  String get priceMin;

  /// Maximum price label
  ///
  /// In en, this message translates to:
  /// **'Max Price'**
  String get priceMax;

  /// Minimum rating filter label
  ///
  /// In en, this message translates to:
  /// **'Minimum Rating'**
  String get minRating;

  /// Rating filter option
  ///
  /// In en, this message translates to:
  /// **'{stars} stars & up'**
  String starsAndUp(int stars);

  /// Minimum discount filter label
  ///
  /// In en, this message translates to:
  /// **'Minimum Discount'**
  String get minDiscount;

  /// Discount filter option
  ///
  /// In en, this message translates to:
  /// **'{discount}% & up'**
  String discountAndUp(int discount);

  /// In stock only filter
  ///
  /// In en, this message translates to:
  /// **'In Stock Only'**
  String get inStockOnly;

  /// Deals only filter
  ///
  /// In en, this message translates to:
  /// **'Deals Only'**
  String get dealsOnly;

  /// Sort label
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// Sort by prefix
  ///
  /// In en, this message translates to:
  /// **'Sort by:'**
  String get sortByLabel;

  /// Product count display
  ///
  /// In en, this message translates to:
  /// **'{count} products'**
  String productCount(int count);

  /// Active filters count
  ///
  /// In en, this message translates to:
  /// **'{count} active'**
  String activeFilters(int count);

  /// Recent searches section label
  ///
  /// In en, this message translates to:
  /// **'Recent Searches'**
  String get recentSearchesLabel;

  /// Clear search history button
  ///
  /// In en, this message translates to:
  /// **'Clear History'**
  String get clearSearchHistory;

  /// Search suggestions label
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get suggestions;

  /// Today's deals section title
  ///
  /// In en, this message translates to:
  /// **'Today\'s Deals'**
  String get todaysDealsTitle;

  /// Biggest discounts section title
  ///
  /// In en, this message translates to:
  /// **'Biggest Discounts'**
  String get biggestDiscountsTitle;

  /// Flash deals section title
  ///
  /// In en, this message translates to:
  /// **'Flash Deals'**
  String get flashDealsTitle;

  /// Trending deals section title
  ///
  /// In en, this message translates to:
  /// **'Trending Deals'**
  String get trendingDealsTitle;

  /// Price drops section title
  ///
  /// In en, this message translates to:
  /// **'Price Drops'**
  String get priceDropsTitle;

  /// Recently viewed section title
  ///
  /// In en, this message translates to:
  /// **'Recently Viewed'**
  String get recentlyViewedTitle;

  /// Recommended products section title
  ///
  /// In en, this message translates to:
  /// **'Recommended For You'**
  String get recommendedTitle;

  /// Best sellers section title
  ///
  /// In en, this message translates to:
  /// **'Best Sellers'**
  String get bestSellersTitle;

  /// View all button
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// See more button
  ///
  /// In en, this message translates to:
  /// **'See More'**
  String get seeMore;

  /// Save label for discounts
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Savings amount display
  ///
  /// In en, this message translates to:
  /// **'Save {amount}'**
  String savingsAmount(String amount);

  /// Up to prefix for discounts
  ///
  /// In en, this message translates to:
  /// **'Up to'**
  String get upTo;

  /// OFF suffix for discounts
  ///
  /// In en, this message translates to:
  /// **'OFF'**
  String get off;

  /// Deal of the day label
  ///
  /// In en, this message translates to:
  /// **'Deal of the Day'**
  String get dealOfTheDay;

  /// Limited quantity badge
  ///
  /// In en, this message translates to:
  /// **'Limited Quantity'**
  String get limitedQuantity;

  /// Urgency indicator
  ///
  /// In en, this message translates to:
  /// **'Hurry!'**
  String get hurry;

  /// Low stock urgency message
  ///
  /// In en, this message translates to:
  /// **'Almost Gone!'**
  String get almostGone;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get emailHint;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordHint;

  /// No description provided for @fullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get fullNameHint;

  /// No description provided for @confirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your password'**
  String get confirmPasswordHint;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get emailInvalid;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordTooShort;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// No description provided for @nameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters'**
  String get nameTooShort;

  /// No description provided for @confirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get confirmPasswordRequired;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back!'**
  String get welcomeBack;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue shopping'**
  String get loginSubtitle;

  /// No description provided for @loginSuccess.
  ///
  /// In en, this message translates to:
  /// **'Logged in successfully'**
  String get loginSuccess;

  /// No description provided for @loginError.
  ///
  /// In en, this message translates to:
  /// **'Login failed. Please check your credentials.'**
  String get loginError;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @signUpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join TOPBUY DEALS today'**
  String get signUpSubtitle;

  /// No description provided for @signUpSuccess.
  ///
  /// In en, this message translates to:
  /// **'Account created successfully!'**
  String get signUpSuccess;

  /// No description provided for @signUpError.
  ///
  /// In en, this message translates to:
  /// **'Sign up failed. Please try again.'**
  String get signUpError;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLink;

  /// No description provided for @resetPasswordDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we\'ll send you a link to reset your password'**
  String get resetPasswordDescription;

  /// No description provided for @resetPasswordEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent!'**
  String get resetPasswordEmailSent;

  /// No description provided for @resetPasswordEmailSentDescription.
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent a password reset link to your email. Check your inbox and follow the instructions.'**
  String get resetPasswordEmailSentDescription;

  /// No description provided for @resetPasswordError.
  ///
  /// In en, this message translates to:
  /// **'Failed to send reset email. Please try again.'**
  String get resetPasswordError;

  /// No description provided for @resetPasswordHelpText.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive the email? Check your spam folder or try resending.'**
  String get resetPasswordHelpText;

  /// No description provided for @checkYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Check Your Email'**
  String get checkYourEmail;

  /// No description provided for @resendEmail.
  ///
  /// In en, this message translates to:
  /// **'Resend Email'**
  String get resendEmail;

  /// No description provided for @resendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String resendIn(int seconds);

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get backToLogin;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get or;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @passwordWeak.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get passwordWeak;

  /// No description provided for @passwordMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get passwordMedium;

  /// No description provided for @passwordStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get passwordStrong;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @myAccount.
  ///
  /// In en, this message translates to:
  /// **'My Account'**
  String get myAccount;

  /// No description provided for @accountSettings.
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get accountSettings;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @signedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as'**
  String get signedInAs;

  /// No description provided for @guest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guest;

  /// No description provided for @signInToSeeMore.
  ///
  /// In en, this message translates to:
  /// **'Sign in to access more features'**
  String get signInToSeeMore;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @phoneNumberHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get phoneNumberHint;

  /// No description provided for @phoneNumberInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number'**
  String get phoneNumberInvalid;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdated;

  /// No description provided for @profileUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile'**
  String get profileUpdateFailed;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @currencyPreference.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currencyPreference;

  /// No description provided for @languagePreference.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languagePreference;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'fr', 'uz'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'uz':
      return AppLocalizationsUz();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
