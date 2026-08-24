import 'package:flutter/foundation.dart';

/// Centralized widget keys for testing.
///
/// This file contains all widget keys used throughout the application
/// for widget testing purposes. Keys are organized by feature/screen
/// to maintain clarity and prevent duplication.
///
/// Usage:
/// ```dart
/// TextField(
///   key: WidgetKeys.loginEmailField,
///   ...
/// )
/// ```
class WidgetKeys {
  WidgetKeys._();

  // ==========================================================================
  // AUTH FLOW - Login Page
  // ==========================================================================

  static const loginEmailField = Key('login_email_field');
  static const loginPasswordField = Key('login_password_field');
  static const loginPasswordVisibilityToggle = Key('login_password_visibility_toggle');
  static const loginButton = Key('login_button');
  static const loginLoadingIndicator = Key('login_loading_indicator');
  static const loginForgotPasswordButton = Key('login_forgot_password_button');
  static const loginSignUpButton = Key('login_sign_up_button');

  // ==========================================================================
  // AUTH FLOW - Sign Up Page
  // ==========================================================================

  static const signupNameField = Key('signup_name_field');
  static const signupEmailField = Key('signup_email_field');
  static const signupPasswordField = Key('signup_password_field');
  static const signupPasswordVisibilityToggle = Key('signup_password_visibility_toggle');
  static const signupConfirmPasswordField = Key('signup_confirm_password_field');
  static const signupConfirmPasswordVisibilityToggle = Key('signup_confirm_password_visibility_toggle');
  static const signupPasswordStrengthIndicator = Key('signup_password_strength_indicator');
  static const signupButton = Key('signup_button');
  static const signupLoadingIndicator = Key('signup_loading_indicator');
  static const signupLoginButton = Key('signup_login_button');

  // ==========================================================================
  // AUTH FLOW - Forgot Password Page
  // ==========================================================================

  static const forgotPasswordEmailField = Key('forgot_password_email_field');
  static const forgotPasswordSendButton = Key('forgot_password_send_button');
  static const forgotPasswordLoadingIndicator = Key('forgot_password_loading_indicator');
  static const forgotPasswordResendButton = Key('forgot_password_resend_button');
  static const forgotPasswordBackToLoginButton = Key('forgot_password_back_to_login_button');

  // ==========================================================================
  // REUSABLE WIDGETS - Product Card
  // ==========================================================================

  /// Product card wrapper (entire card)
  static Key productCard(String productId) => Key('product_card_$productId');

  /// Favorite/wishlist toggle button
  static Key productCardFavoriteButton(String productId) =>
      Key('product_card_favorite_button_$productId');

  /// Product icon display
  static Key productCardIcon(String productId) =>
      Key('product_card_icon_$productId');

  /// Discount percentage badge
  static Key productCardDiscountBadge(String productId) =>
      Key('product_card_discount_badge_$productId');

  /// Deal badge (Best Seller, Trending, etc.)
  static Key productCardDealBadge(String productId) =>
      Key('product_card_deal_badge_$productId');

  /// Product name text
  static Key productCardName(String productId) =>
      Key('product_card_name_$productId');

  /// Product category text
  static Key productCardCategory(String productId) =>
      Key('product_card_category_$productId');

  /// Product rating display
  static Key productCardRating(String productId) =>
      Key('product_card_rating_$productId');

  /// Current price text
  static Key productCardPrice(String productId) =>
      Key('product_card_price_$productId');

  /// Old/strikethrough price text
  static Key productCardOldPrice(String productId) =>
      Key('product_card_old_price_$productId');

  // ==========================================================================
  // REUSABLE WIDGETS - Horizontal Product Section
  // ==========================================================================

  /// Horizontal product section wrapper
  static Key horizontalProductSection(String sectionId) =>
      Key('horizontal_product_section_$sectionId');

  /// "View All" button in section header
  static Key horizontalProductSectionViewAll(String sectionId) =>
      Key('horizontal_product_section_view_all_$sectionId');

  /// Horizontal scrollable product list
  static Key horizontalProductSectionList(String sectionId) =>
      Key('horizontal_product_section_list_$sectionId');

  // ==========================================================================
  // REUSABLE WIDGETS - Popular Categories Section
  // ==========================================================================

  /// Popular categories section wrapper
  static const popularCategoriesSection = Key('popular_categories_section');

  /// Horizontal scrollable category list
  static const popularCategoriesList = Key('popular_categories_list');

  /// Individual category item
  static Key categoryItem(String categoryKey) =>
      Key('category_item_$categoryKey');

  // ==========================================================================
  // REUSABLE WIDGETS - Product Search Delegate
  // ==========================================================================

  /// Clear search query button
  static const searchClearButton = Key('search_clear_button');

  /// Back button to close search
  static const searchBackButton = Key('search_back_button');

  /// Clear search history button
  static const searchClearHistoryButton = Key('search_clear_history_button');

  /// Search suggestions/history list
  static const searchSuggestionsList = Key('search_suggestions_list');

  /// Individual search suggestion item
  static Key searchSuggestion(int index) => Key('search_suggestion_$index');

  /// Remove recent search button
  static Key searchRemoveRecent(int index) => Key('search_remove_recent_$index');
}
