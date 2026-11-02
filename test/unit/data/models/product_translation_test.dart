import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/data/models/product.dart';

/// Product.fromSupabase with embedded `product_translations` rows
/// (migration 008). The `products` columns are the English fallback and each
/// translated field falls back individually.
void main() {
  Map<String, dynamic> row({List<dynamic>? translations}) => {
        'slug': 'elec-001',
        'name': 'Smart Watch Ultra',
        'subtitle': 'Fitness & Health Tracking',
        'description': 'Premium smartwatch.',
        'price': 199.99,
        'old_price': 319.99,
        'rating': 4.6,
        'review_count': 1847,
        'stock': 45,
        'brand': 'TechPro',
        'seller': 'TechPro Official Store',
        'specifications': {'Display': '1.9" AMOLED', 'Battery': '7 days'},
        'features': ['GPS navigation', 'Water resistant'],
        'badges': ['Best Seller'],
        'categories': {'key': 'electronics'},
        'product_images': [
          {'url': 'https://example.test/a.jpg', 'sort_order': 0},
        ],
        'product_translations': ?translations,
      };

  const ru = {
    'locale': 'ru',
    'name': 'Умные часы Ultra',
    'subtitle': 'Фитнес и здоровье',
    'description': 'Умные часы премиум-класса.',
    'features': ['GPS-навигация', 'Водонепроницаемые'],
    'specifications': {'Экран': '1,9" AMOLED', 'Батарея': '7 дней'},
  };

  const uz = {
    'locale': 'uz',
    'name': 'Aqlli soat Ultra',
    'subtitle': "Fitnes va salomatlik",
    'description': "Premium aqlli soat.",
    'features': ['GPS navigatsiya'],
    'specifications': {'Ekran': '1.9" AMOLED'},
  };

  group('Product.fromSupabase translations', () {
    test('Russian: every translated field comes from the ru row', () {
      final p = Product.fromSupabase(row(translations: [ru]), locale: 'ru');

      expect(p.name, 'Умные часы Ultra');
      expect(p.subtitle, 'Фитнес и здоровье');
      expect(p.description, 'Умные часы премиум-класса.');
      expect(p.features, ['GPS-навигация', 'Водонепроницаемые']);
      expect(p.specifications, {'Экран': '1,9" AMOLED', 'Батарея': '7 дней'});
    });

    test('Uzbek (Latin script): every translated field comes from the uz row',
        () {
      final p = Product.fromSupabase(row(translations: [ru, uz]), locale: 'uz');

      expect(p.name, 'Aqlli soat Ultra');
      expect(p.subtitle, 'Fitnes va salomatlik');
      expect(p.description, 'Premium aqlli soat.');
      expect(p.features, ['GPS navigatsiya']);
      expect(p.specifications, {'Ekran': '1.9" AMOLED'});
    });

    test('picks the row matching the locale among several', () {
      final json = row(translations: [uz, ru]);

      expect(Product.fromSupabase(json, locale: 'ru').name, 'Умные часы Ultra');
      expect(Product.fromSupabase(json, locale: 'uz').name, 'Aqlli soat Ultra');
    });

    test('English: no translation rows at all keeps the products columns', () {
      final p = Product.fromSupabase(row(translations: const []), locale: 'en');

      expect(p.name, 'Smart Watch Ultra');
      expect(p.subtitle, 'Fitness & Health Tracking');
      expect(p.description, 'Premium smartwatch.');
      expect(p.features, ['GPS navigation', 'Water resistant']);
      expect(p.specifications, {'Display': '1.9" AMOLED', 'Battery': '7 days'});
    });

    test('English: works when the product_translations key is absent', () {
      final p = Product.fromSupabase(row(), locale: 'en');

      expect(p.name, 'Smart Watch Ultra');
    });

    test('missing row for the requested locale falls back to English', () {
      final p = Product.fromSupabase(row(translations: [ru]), locale: 'uz');

      expect(p.name, 'Smart Watch Ultra');
      expect(p.description, 'Premium smartwatch.');
      expect(p.features, ['GPS navigation', 'Water resistant']);
      expect(p.specifications, {'Display': '1.9" AMOLED', 'Battery': '7 days'});
    });

    test('a null locale ignores translations', () {
      final p = Product.fromSupabase(row(translations: [ru]));

      expect(p.name, 'Smart Watch Ultra');
    });

    test('an English row, when present, is applied like any other locale', () {
      final p = Product.fromSupabase(
        row(translations: [
          {'locale': 'en', 'name': 'Smart Watch Ultra (EN)'},
        ]),
        locale: 'en',
      );

      expect(p.name, 'Smart Watch Ultra (EN)');
    });

    test('missing individual fields fall back one by one', () {
      final p = Product.fromSupabase(
        row(translations: [
          {
            'locale': 'ru',
            'name': 'Умные часы Ultra',
            'subtitle': null,
            'description': null,
            'features': null,
            'specifications': null,
          },
        ]),
        locale: 'ru',
      );

      expect(p.name, 'Умные часы Ultra');
      expect(p.subtitle, 'Fitness & Health Tracking');
      expect(p.description, 'Premium smartwatch.');
      expect(p.features, ['GPS navigation', 'Water resistant']);
      expect(p.specifications, {'Display': '1.9" AMOLED', 'Battery': '7 days'});
    });

    test('translated fields absent from the row fall back too', () {
      final p = Product.fromSupabase(
        row(translations: [
          {'locale': 'ru', 'name': 'Умные часы Ultra', 'description': 'Описание'},
        ]),
        locale: 'ru',
      );

      expect(p.description, 'Описание');
      expect(p.subtitle, 'Fitness & Health Tracking');
      expect(p.features, ['GPS navigation', 'Water resistant']);
    });

    test('blank strings, empty lists and empty maps fall back', () {
      final p = Product.fromSupabase(
        row(translations: [
          {
            'locale': 'ru',
            'name': '   ',
            'subtitle': '',
            'description': ' ',
            'features': ['', '  '],
            'specifications': <String, dynamic>{},
          },
        ]),
        locale: 'ru',
      );

      expect(p.name, 'Smart Watch Ultra');
      expect(p.subtitle, 'Fitness & Health Tracking');
      expect(p.description, 'Premium smartwatch.');
      expect(p.features, ['GPS navigation', 'Water resistant']);
      expect(p.specifications, {'Display': '1.9" AMOLED', 'Battery': '7 days'});
    });

    test('a translation can fill a field the English row lacks', () {
      final json = row(translations: [ru])
        ..['subtitle'] = null
        ..['specifications'] = null;
      final p = Product.fromSupabase(json, locale: 'ru');

      expect(p.subtitle, 'Фитнес и здоровье');
      expect(p.specifications, {'Экран': '1,9" AMOLED', 'Батарея': '7 дней'});
    });

    test('specifications: non-string values are stringified, nulls dropped', () {
      final p = Product.fromSupabase(
        row(translations: [
          {
            'locale': 'ru',
            'name': 'x',
            'specifications': {'Вес': 42, 'Цвет': 'Чёрный', 'Пусто': null},
          },
        ]),
        locale: 'ru',
      );

      expect(p.specifications, {'Вес': '42', 'Цвет': 'Чёрный'});
    });

    test('specifications: all-null translated map falls back to English', () {
      final p = Product.fromSupabase(
        row(translations: [
          {
            'locale': 'ru',
            'name': 'x',
            'specifications': {'Пусто': null},
          },
        ]),
        locale: 'ru',
      );

      expect(p.specifications, {'Display': '1.9" AMOLED', 'Battery': '7 days'});
    });

    test('non-translatable fields are never taken from translations', () {
      final p = Product.fromSupabase(
        row(translations: [
          {
            ...ru,
            'price': 1,
            'slug': 'hacked',
            'brand': 'Other',
            'badges': ['x'],
          },
        ]),
        locale: 'ru',
      );

      expect(p.id, 'elec-001');
      expect(p.price, 199.99);
      expect(p.oldPrice, 319.99);
      expect(p.brand, 'TechPro');
      expect(p.seller, 'TechPro Official Store');
      expect(p.badges, ['Best Seller']);
      expect(p.category, 'electronics');
      expect(p.stock, 45);
      expect(p.images, ['https://example.test/a.jpg']);
    });
  });
}
