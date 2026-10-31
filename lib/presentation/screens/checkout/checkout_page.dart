import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/widget_keys.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/data_sources/remote/order_remote_data_source.dart';
import '../../../data/models/order.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/checkout_provider.dart';
import '../../providers/currency_provider.dart';
import '../../widgets/button_loading_indicator.dart';

/// Checkout page allowing customers to review items, enter shipping details,
/// and place orders atomically.
class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Prefill full name and phone from profile if authenticated
    final auth = context.read<AuthProvider?>();
    final user = auth?.currentUser;
    if (user != null) {
      if (user.fullName != null && user.fullName!.trim().isNotEmpty) {
        _fullNameController.text = user.fullName!.trim();
      }
      if (user.phone != null && user.phone!.trim().isNotEmpty) {
        _phoneController.text = user.phone!.trim();
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _handlePlaceOrder() async {
    final checkoutProvider = context.read<CheckoutProvider>();
    if (checkoutProvider.isSubmitting ||
        checkoutProvider.status == CheckoutStatus.outcomeUnknown) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final cartProvider = context.read<CartProvider>();
    final authProvider = context.read<AuthProvider?>();
    final currencyProvider = context.read<CurrencyProvider>();

    final shipping = ShippingDetails(
      fullName: _fullNameController.text.trim(),
      phone: _phoneController.text.trim(),
      addressLine: _addressController.text.trim(),
      city: _cityController.text.trim(),
      country: _countryController.text.trim(),
    );

    await checkoutProvider.submitOrder(
      cart: cartProvider,
      auth: authProvider,
      shipping: shipping,
      currencyCode: currencyProvider.currentCurrency,
    );
  }

  String _getErrorMessage(BuildContext context, CheckoutErrorCode? code) {
    final l10n = AppLocalizations.of(context)!;
    return switch (code) {
      CheckoutErrorCode.notAuthenticated => l10n.checkoutErrorNotAuthenticated,
      CheckoutErrorCode.emptyCart => l10n.checkoutErrorEmptyCart,
      CheckoutErrorCode.invalidQuantity => l10n.checkoutErrorInvalidQuantity,
      CheckoutErrorCode.duplicateItem => l10n.checkoutErrorDuplicateItem,
      CheckoutErrorCode.invalidShipping => l10n.checkoutErrorInvalidShipping,
      CheckoutErrorCode.invalidCurrency => l10n.checkoutErrorInvalidCurrency,
      CheckoutErrorCode.productUnavailable =>
        l10n.checkoutErrorProductUnavailable,
      CheckoutErrorCode.insufficientStock => l10n.checkoutErrorInsufficientStock,
      CheckoutErrorCode.invalidResponse => l10n.checkoutErrorInvalidResponse,
      CheckoutErrorCode.unknown => l10n.checkoutErrorOutcomeUnknown,
      null => l10n.checkoutErrorUnknown,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final checkoutProvider = context.watch<CheckoutProvider>();
    final cartProvider = context.watch<CartProvider>();
    final currencyCode = context.watch<CurrencyProvider>().currentCurrency;
    final locale = Localizations.localeOf(context).languageCode;
    final horizontalPadding = ScreenSize.getHorizontalPadding(context);
    final isWideScreen = !ScreenSize.isMobile(context);

    // If order was successfully placed, display the confirmation view
    if (checkoutProvider.status == CheckoutStatus.success &&
        checkoutProvider.placedOrder != null) {
      return Scaffold(
        key: WidgetKeys.checkoutPage,
        appBar: AppBar(
          title: Text(l10n.orderConfirmation),
        ),
        body: _buildOrderConfirmation(
          context,
          l10n,
          checkoutProvider.placedOrder!,
          locale,
          isWideScreen,
        ),
      );
    }

    final isSubmitting = checkoutProvider.isSubmitting;
    final isUnknownOutcome =
        checkoutProvider.status == CheckoutStatus.outcomeUnknown;
    final isFailure = checkoutProvider.status == CheckoutStatus.failure;
    final cartItems = cartProvider.cartItems;

    return Scaffold(
      key: WidgetKeys.checkoutPage,
      appBar: AppBar(
        title: Text(l10n.checkout),
      ),
      body: cartItems.isEmpty
          ? Center(
              child: Text(l10n.emptyCart),
            )
          : ListView(
              padding: EdgeInsets.all(horizontalPadding),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth:
                          isWideScreen ? ContentWidth.list : double.infinity,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Order Summary
                        Card(
                          key: WidgetKeys.checkoutOrderSummary,
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.orderSummary,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                for (final item in cartItems) ...[
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: AppSpacing.xs),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${item.name} × ${cartProvider.quantityOf(item.id)}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium,
                                          ),
                                        ),
                                        Text(
                                          formatPrice(
                                            item.price *
                                                cartProvider
                                                    .quantityOf(item.id),
                                            currencyCode,
                                            locale,
                                          ),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const Divider(height: AppSpacing.lg),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      l10n.cartSubtotal,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      formatPrice(cartProvider.subtotal,
                                          currencyCode, locale),
                                      key: WidgetKeys.checkoutSubtotalValue,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Shipping Details Form
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.shippingDetails,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  TextFormField(
                                    key: WidgetKeys.checkoutFullNameField,
                                    controller: _fullNameController,
                                    enabled: !isSubmitting,
                                    decoration: InputDecoration(
                                      labelText: l10n.fullName,
                                      hintText: l10n.fullNameHint,
                                      border: const OutlineInputBorder(),
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return l10n.fullNameRequired;
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  TextFormField(
                                    key: WidgetKeys.checkoutPhoneField,
                                    controller: _phoneController,
                                    enabled: !isSubmitting,
                                    keyboardType: TextInputType.phone,
                                    decoration: InputDecoration(
                                      labelText: l10n.phone,
                                      hintText: l10n.phoneNumberHint,
                                      border: const OutlineInputBorder(),
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return l10n.phoneRequired;
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  TextFormField(
                                    key: WidgetKeys.checkoutAddressField,
                                    controller: _addressController,
                                    enabled: !isSubmitting,
                                    decoration: InputDecoration(
                                      labelText: l10n.streetAddress,
                                      hintText: l10n.streetAddressHint,
                                      border: const OutlineInputBorder(),
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return l10n.streetAddressRequired;
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  TextFormField(
                                    key: WidgetKeys.checkoutCityField,
                                    controller: _cityController,
                                    enabled: !isSubmitting,
                                    decoration: InputDecoration(
                                      labelText: l10n.city,
                                      hintText: l10n.cityHint,
                                      border: const OutlineInputBorder(),
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return l10n.cityRequired;
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  TextFormField(
                                    key: WidgetKeys.checkoutCountryField,
                                    controller: _countryController,
                                    enabled: !isSubmitting,
                                    decoration: InputDecoration(
                                      labelText: l10n.country,
                                      hintText: l10n.countryHint,
                                      border: const OutlineInputBorder(),
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return l10n.countryRequired;
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Known failure message
                        if (isFailure) ...[
                          const SizedBox(height: AppSpacing.md),
                          Container(
                            key: WidgetKeys.checkoutErrorMessage,
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    _getErrorMessage(
                                        context, checkoutProvider.errorCode),
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onErrorContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Outcome unknown message & explicit reset
                        if (isUnknownOutcome) ...[
                          const SizedBox(height: AppSpacing.md),
                          Container(
                            key: WidgetKeys.checkoutUnknownOutcomeMessage,
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.amber.shade700),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      color: Colors.amber.shade900,
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Text(
                                        l10n.checkoutErrorOutcomeUnknown,
                                        style: TextStyle(
                                          color: Colors.amber.shade900,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: OutlinedButton(
                                    key: WidgetKeys.checkoutResetButton,
                                    onPressed: () => checkoutProvider.reset(),
                                    child: Text(l10n.checkoutResetButton),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: AppSpacing.xl),

                        // Place Order Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            key: WidgetKeys.checkoutPlaceOrderButton,
                            onPressed: (isSubmitting || isUnknownOutcome)
                                ? null
                                : _handlePlaceOrder,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md,
                              ),
                            ),
                            child: isSubmitting
                                ? const ButtonLoadingIndicator(
                                    key: WidgetKeys.checkoutLoadingIndicator,
                                  )
                                : Text(l10n.placeOrder),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildOrderConfirmation(
    BuildContext context,
    AppLocalizations l10n,
    PlacedOrder order,
    String locale,
    bool isWideScreen,
  ) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isWideScreen ? ContentWidth.settings : double.infinity,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            key: WidgetKeys.checkoutConfirmationView,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 80,
                color: Colors.green,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.orderPlacedSuccess,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.orderSuccessMessage,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.orderId,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          SelectableText(
                            order.orderId,
                            key: WidgetKeys.checkoutOrderIdValue,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const Divider(height: AppSpacing.xl),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.subtotalUsd,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            formatPrice(order.subtotalUsd, 'USD', locale),
                            key: WidgetKeys.checkoutUsdTotalValue,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  key: WidgetKeys.checkoutContinueShoppingButton,
                  onPressed: () {
                    context.read<CheckoutProvider>().reset();
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text(l10n.continueShopping),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
