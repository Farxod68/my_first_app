import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/data/models/product.dart';

void main() {
  group('Product.fromSupabase', () {
    Map<String, dynamic> rowFor({
      String slug = 'elec-001',
      String name = 'Smart Watch Ultra',
      String? subtitle = 'Fitness & Health Tracking',
      String? description = 'Premium smartwatch.',
      double price = 199.99,
      double oldPrice = 319.99,
      String? categoryKey = 'electronics',
      double? rating = 4.6,
      int? reviewCount = 1847,
      int? stock = 45,
      String? brand = 'TechPro',
      String? seller = 'TechPro Official Store',
      Map<String, dynamic>? specifications = const {'Display': '1.9" AMOLED'},
      List<dynamic>? features = const ['GPS + GLONASS navigation'],
      List<dynamic>? badges = const ['Best Seller', 'Free Shipping'],
      List<dynamic>? images = const [],
    }) {
      return {
        'slug': slug,
        'name': name,
        'subtitle': subtitle,
        'description': description,
        'price': price,
        'old_price': oldPrice,
        'rating': rating,
        'review_count': reviewCount,
        'stock': stock,
        'brand': brand,
        'seller': seller,
        'specifications': specifications,
        'features': features,
        'badges': badges,
        'categories': categoryKey == null ? null : {'key': categoryKey},
        'product_images': images,
      };
    }

    test('maps slug to id (not a UUID)', () {
      final product = Product.fromSupabase(rowFor(slug: 'elec-001'));
      expect(product.id, 'elec-001');
    });

    test('maps core scalar fields exactly', () {
      final product = Product.fromSupabase(rowFor());

      expect(product.name, 'Smart Watch Ultra');
      expect(product.subtitle, 'Fitness & Health Tracking');
      expect(product.description, 'Premium smartwatch.');
      expect(product.price, 199.99);
      expect(product.oldPrice, 319.99);
      expect(product.rating, 4.6);
      expect(product.reviewCount, 1847);
      expect(product.stock, 45);
      expect(product.brand, 'TechPro');
      expect(product.seller, 'TechPro Official Store');
    });

    test('maps embedded categories.key to category', () {
      final product = Product.fromSupabase(rowFor(categoryKey: 'clothing'));
      expect(product.category, 'clothing');
    });

    test('maps embedded product_images to images, preserving order', () {
      final product = Product.fromSupabase(rowFor(images: [
        {'url': 'https://example.com/1.jpg', 'sort_order': 0},
        {'url': 'https://example.com/2.jpg', 'sort_order': 1},
      ]));

      expect(product.images, [
        'https://example.com/1.jpg',
        'https://example.com/2.jpg',
      ]);
    });

    test('empty product_images maps to an empty images list', () {
      final product = Product.fromSupabase(rowFor(images: const []));
      expect(product.images, isEmpty);
    });

    test('maps specifications JSONB to Map<String, String>', () {
      final product = Product.fromSupabase(rowFor(
        specifications: const {'Display': '1.9" AMOLED', 'Battery': '450mAh'},
      ));

      expect(product.specifications, {
        'Display': '1.9" AMOLED',
        'Battery': '450mAh',
      });
    });

    test('maps features array to List<String>', () {
      final product = Product.fromSupabase(rowFor(
        features: const ['Heart rate & SpO2 monitoring', '7-day battery life'],
      ));

      expect(product.features, [
        'Heart rate & SpO2 monitoring',
        '7-day battery life',
      ]);
    });

    test('maps badges array to List<String>', () {
      final product = Product.fromSupabase(rowFor(
        badges: const ['Best Seller', 'Free Shipping'],
      ));

      expect(product.badges, ['Best Seller', 'Free Shipping']);
    });

    test('empty badges array maps to an empty list, not null', () {
      final product = Product.fromSupabase(rowFor(badges: const []));
      expect(product.badges, isEmpty);
    });

    test('missing rating/reviewCount/stock default like the local model', () {
      final product = Product.fromSupabase(rowFor(
        rating: null,
        reviewCount: null,
        stock: null,
      ));

      expect(product.rating, 0.0);
      expect(product.reviewCount, 0);
      expect(product.stock, 0);
    });

    test('assigns a category fallback icon for a known category', () {
      final product = Product.fromSupabase(rowFor(categoryKey: 'electronics'));
      expect(product.icon, Icons.phone_android);
    });

    test('assigns a generic fallback icon for an unrecognized category', () {
      final product = Product.fromSupabase(rowFor(categoryKey: 'unknown-category'));
      expect(product.icon, Icons.shopping_bag);
    });

    test('does not store Flutter IconData anywhere derived from Supabase data', () {
      // The DB row itself never carries an 'icon' key - fromSupabase must not
      // expect or depend on one.
      final row = rowFor()..remove('subtitle');
      expect(() => Product.fromSupabase(row), returnsNormally);
    });

    test('computed getters still work on a Supabase-sourced product', () {
      final product = Product.fromSupabase(rowFor(price: 100, oldPrice: 200, stock: 5));

      expect(product.discount, 50);
      expect(product.isInStock, isTrue);
      expect(product.isLowStock, isTrue);
      expect(product.isOutOfStock, isFalse);
    });
  });
}
