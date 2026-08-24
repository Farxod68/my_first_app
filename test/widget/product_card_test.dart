import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/core/constants/app_constants.dart';
import 'package:my_first_app/core/constants/widget_keys.dart';
import 'package:my_first_app/presentation/widgets/product_card.dart';
import '../helpers/test_data.dart';
import '../helpers/widget_test_helpers.dart';

void main() {
  group('ProductCard Widget Tests', () {
    testWidgets('renders product name', (tester) async {
      final product = TestData.createTestProduct(name: 'Test Smart Watch');

      await pumpApp(
        tester,
        ProductCard(
          product: product,
          isFavorite: false,
          onTap: () {},
          onFavoriteToggle: () {},
          locale: 'en',
        ),
      );

      expect(find.text('Test Smart Watch'), findsOneWidget);
      expect(find.byKey(WidgetKeys.productCardName(product.id)), findsOneWidget);
    });

    testWidgets('renders product icon', (tester) async {
      final product = TestData.createTestProduct(icon: Icons.laptop);

      await pumpApp(
        tester,
        ProductCard(
          product: product,
          isFavorite: false,
          onTap: () {},
          onFavoriteToggle: () {},
          locale: 'en',
        ),
      );

      expect(find.byKey(WidgetKeys.productCardIcon(product.id)), findsOneWidget);
      final iconWidget = tester.widget<Icon>(
        find.byKey(WidgetKeys.productCardIcon(product.id)),
      );
      expect(iconWidget.icon, equals(Icons.laptop));
    });

    testWidgets('renders product category (localized)', (tester) async {
      final product = TestData.createTestProduct(category: 'electronics');

      await pumpApp(
        tester,
        ProductCard(
          product: product,
          isFavorite: false,
          onTap: () {},
          onFavoriteToggle: () {},
          locale: 'en',
        ),
      );

      expect(find.byKey(WidgetKeys.productCardCategory(product.id)), findsOneWidget);
      // Should show localized category name, not the key
      expect(find.text('Electronics'), findsOneWidget);
    });

    testWidgets('renders current price formatted for locale', (tester) async {
      final product = TestData.createTestProduct(price: 99.99);

      await pumpApp(
        tester,
        ProductCard(
          product: product,
          isFavorite: false,
          onTap: () {},
          onFavoriteToggle: () {},
          locale: 'en',
        ),
      );

      expect(find.byKey(WidgetKeys.productCardPrice(product.id)), findsOneWidget);
      // USD formatting for 'en' locale
      expect(find.textContaining('\$99.99'), findsOneWidget);
    });

    testWidgets('renders old price when discount exists', (tester) async {
      final product = TestData.createTestProduct(
        price: 99.99,
        oldPrice: 149.99,
      );

      await pumpApp(
        tester,
        ProductCard(
          product: product,
          isFavorite: false,
          onTap: () {},
          onFavoriteToggle: () {},
          locale: 'en',
        ),
      );

      expect(find.byKey(WidgetKeys.productCardOldPrice(product.id)), findsOneWidget);
      expect(find.textContaining('\$149.99'), findsOneWidget);
    });

    testWidgets('does not render old price when no discount', (tester) async {
      final product = TestData.createTestProduct(
        price: 99.99,
        oldPrice: 99.99, // Same price = no discount
      );

      await pumpApp(
        tester,
        ProductCard(
          product: product,
          isFavorite: false,
          onTap: () {},
          onFavoriteToggle: () {},
          locale: 'en',
        ),
      );

      expect(find.byKey(WidgetKeys.productCardOldPrice(product.id)), findsNothing);
    });

    testWidgets('renders discount badge when discount > 0', (tester) async {
      final product = TestData.createTestProduct(
        price: 99.99,
        oldPrice: 149.99, // 33% discount
      );

      await pumpApp(
        tester,
        ProductCard(
          product: product,
          isFavorite: false,
          onTap: () {},
          onFavoriteToggle: () {},
          locale: 'en',
        ),
      );

      expect(find.byKey(WidgetKeys.productCardDiscountBadge(product.id)), findsOneWidget);
      expect(find.text('-33%'), findsOneWidget);
    });

    testWidgets('does not render discount badge when discount = 0', (tester) async {
      final product = TestData.createTestProduct(
        price: 99.99,
        oldPrice: 99.99, // No discount
      );

      await pumpApp(
        tester,
        ProductCard(
          product: product,
          isFavorite: false,
          onTap: () {},
          onFavoriteToggle: () {},
          locale: 'en',
        ),
      );

      expect(find.byKey(WidgetKeys.productCardDiscountBadge(product.id)), findsNothing);
    });

    testWidgets('renders deal badge when badges list is not empty', (tester) async {
      final product = TestData.createTestProduct(
        badges: [DealBadges.bestSeller],
      );

      await pumpApp(
        tester,
        ProductCard(
          product: product,
          isFavorite: false,
          onTap: () {},
          onFavoriteToggle: () {},
          locale: 'en',
        ),
      );

      expect(find.byKey(WidgetKeys.productCardDealBadge(product.id)), findsOneWidget);
      // Badge should be localized
      expect(find.text('Best Seller'), findsOneWidget);
    });

    testWidgets('does not render deal badge when badges list is empty', (tester) async {
      final product = TestData.createTestProduct(badges: []);

      await pumpApp(
        tester,
        ProductCard(
          product: product,
          isFavorite: false,
          onTap: () {},
          onFavoriteToggle: () {},
          locale: 'en',
        ),
      );

      expect(find.byKey(WidgetKeys.productCardDealBadge(product.id)), findsNothing);
    });

    testWidgets('renders rating when hasRating is true', (tester) async {
      final product = TestData.createTestProduct(rating: 4.5);

      await pumpApp(
        tester,
        ProductCard(
          product: product,
          isFavorite: false,
          onTap: () {},
          onFavoriteToggle: () {},
          locale: 'en',
        ),
      );

      expect(find.byKey(WidgetKeys.productCardRating(product.id)), findsOneWidget);
      expect(find.text('4.5'), findsOneWidget);
    });

    testWidgets('does not render rating when rating is 0', (tester) async {
      final product = TestData.createTestProduct(rating: 0.0);

      await pumpApp(
        tester,
        ProductCard(
          product: product,
          isFavorite: false,
          onTap: () {},
          onFavoriteToggle: () {},
          locale: 'en',
        ),
      );

      expect(find.byKey(WidgetKeys.productCardRating(product.id)), findsNothing);
    });

    testWidgets('favorite button shows filled icon when isFavorite is true', (tester) async {
      final product = TestData.createTestProduct();

      await pumpApp(
        tester,
        ProductCard(
          product: product,
          isFavorite: true,
          onTap: () {},
          onFavoriteToggle: () {},
          locale: 'en',
        ),
      );

      final iconButton = tester.widget<IconButton>(
        find.byKey(WidgetKeys.productCardFavoriteButton(product.id)),
      );
      final icon = iconButton.icon as Icon;
      expect(icon.icon, equals(Icons.favorite));
    });

    testWidgets('favorite button shows outlined icon when isFavorite is false', (tester) async {
      final product = TestData.createTestProduct();

      await pumpApp(
        tester,
        ProductCard(
          product: product,
          isFavorite: false,
          onTap: () {},
          onFavoriteToggle: () {},
          locale: 'en',
        ),
      );

      final iconButton = tester.widget<IconButton>(
        find.byKey(WidgetKeys.productCardFavoriteButton(product.id)),
      );
      final icon = iconButton.icon as Icon;
      expect(icon.icon, equals(Icons.favorite_border));
    });

    testWidgets('triggers onTap callback when card is tapped', (tester) async {
      final product = TestData.createTestProduct();
      var tapped = false;

      await pumpApp(
        tester,
        ProductCard(
          product: product,
          isFavorite: false,
          onTap: () => tapped = true,
          onFavoriteToggle: () {},
          locale: 'en',
        ),
      );

      await tester.tap(find.byKey(WidgetKeys.productCard(product.id)));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('triggers onFavoriteToggle callback when favorite button is tapped', (tester) async {
      final product = TestData.createTestProduct();
      var favoriteTapped = false;

      await pumpApp(
        tester,
        ProductCard(
          product: product,
          isFavorite: false,
          onTap: () {},
          onFavoriteToggle: () => favoriteTapped = true,
          locale: 'en',
        ),
      );

      await tester.tap(find.byKey(WidgetKeys.productCardFavoriteButton(product.id)));
      await tester.pumpAndSettle();

      expect(favoriteTapped, isTrue);
    });

    testWidgets('formats price for Spanish locale (EUR)', (tester) async {
      final product = TestData.createTestProduct(price: 100.0);

      await pumpApp(
        tester,
        ProductCard(
          product: product,
          isFavorite: false,
          onTap: () {},
          onFavoriteToggle: () {},
          locale: 'es',
        ),
        locale: const Locale('es'),
      );

      expect(find.byKey(WidgetKeys.productCardPrice(product.id)), findsOneWidget);
      // Spanish locale should show EUR (100 USD * 0.92 = 92 EUR)
      final priceText = tester.widget<Text>(
        find.byKey(WidgetKeys.productCardPrice(product.id)),
      );
      expect(priceText.data, contains('92'));
      expect(priceText.data, contains('€'));
    });

    testWidgets('localizes category name for Spanish locale', (tester) async {
      final product = TestData.createTestProduct(category: 'electronics');

      await pumpApp(
        tester,
        ProductCard(
          product: product,
          isFavorite: false,
          onTap: () {},
          onFavoriteToggle: () {},
          locale: 'es',
        ),
        locale: const Locale('es'),
      );

      expect(find.byKey(WidgetKeys.productCardCategory(product.id)), findsOneWidget);
      // Spanish localization for electronics
      expect(find.text('Electrónica'), findsOneWidget);
    });

    testWidgets('localizes deal badge for Spanish locale', (tester) async {
      final product = TestData.createTestProduct(
        badges: [DealBadges.trending],
      );

      await pumpApp(
        tester,
        ProductCard(
          product: product,
          isFavorite: false,
          onTap: () {},
          onFavoriteToggle: () {},
          locale: 'es',
        ),
        locale: const Locale('es'),
      );

      expect(find.byKey(WidgetKeys.productCardDealBadge(product.id)), findsOneWidget);
      // Spanish localization for trending
      expect(find.text('Tendencia'), findsOneWidget);
    });
  });
}
