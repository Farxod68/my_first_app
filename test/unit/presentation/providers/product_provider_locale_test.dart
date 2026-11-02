import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_first_app/data/models/product.dart';
import 'package:my_first_app/presentation/providers/product_provider.dart';

import '../../../mocks/mock_product_repository.dart';

/// Locale handling of ProductProvider: the catalog is loaded for the current
/// language, reloaded when the language changes, and stale responses from a
/// previous language are discarded.
void main() {
  late MockProductRepository repo;
  late ProductProvider provider;

  Product product(String name, {double price = 100, String id = 'elec-001'}) =>
      Product(
        id: id,
        name: name,
        price: price,
        oldPrice: price * 2,
        category: 'electronics',
        icon: Icons.watch,
      );

  setUp(() {
    repo = MockProductRepository();
  });

  tearDown(() => provider.dispose());

  group('initial load', () {
    test('defaults to English', () async {
      when(() => repo.fetchProducts(locale: any(named: 'locale')))
          .thenAnswer((_) async => [product('Watch')]);

      provider = ProductProvider(repo);
      await Future<void>.delayed(Duration.zero);

      expect(provider.locale, 'en');
      verify(() => repo.fetchProducts(locale: 'en')).called(1);
    });

    test('loads the locale it was created with', () async {
      when(() => repo.fetchProducts(locale: any(named: 'locale')))
          .thenAnswer((_) async => [product('Часы')]);

      provider = ProductProvider(repo, initialLocale: 'ru');
      await Future<void>.delayed(Duration.zero);

      expect(provider.locale, 'ru');
      expect(provider.products.single.name, 'Часы');
      verify(() => repo.fetchProducts(locale: 'ru')).called(1);
    });

    test('refresh keeps the current locale', () async {
      when(() => repo.fetchProducts(locale: any(named: 'locale')))
          .thenAnswer((_) async => [product('Soat')]);

      provider = ProductProvider(repo, initialLocale: 'uz');
      await Future<void>.delayed(Duration.zero);
      await provider.refresh();

      verify(() => repo.fetchProducts(locale: 'uz')).called(2);
    });
  });

  group('setLocale', () {
    test('reloads the catalog in the new language and notifies', () async {
      when(() => repo.fetchProducts(locale: 'en'))
          .thenAnswer((_) async => [product('Watch')]);
      when(() => repo.fetchProducts(locale: 'ru'))
          .thenAnswer((_) async => [product('Часы')]);
      provider = ProductProvider(repo);
      await Future<void>.delayed(Duration.zero);
      expect(provider.products.single.name, 'Watch');

      var notifications = 0;
      provider.addListener(() => notifications++);
      await provider.setLocale('ru');

      expect(provider.locale, 'ru');
      expect(provider.products.single.name, 'Часы');
      expect(provider.isLoading, isFalse);
      expect(notifications, greaterThan(0));
      verify(() => repo.fetchProducts(locale: 'ru')).called(1);
    });

    test('switching through every supported locale loads each one', () async {
      when(() => repo.fetchProducts(locale: any(named: 'locale')))
          .thenAnswer((inv) async =>
              [product('name-${inv.namedArguments[#locale]}')]);
      provider = ProductProvider(repo);
      await Future<void>.delayed(Duration.zero);

      for (final code in ['ru', 'uz', 'es', 'fr', 'en']) {
        await provider.setLocale(code);
        expect(provider.products.single.name, 'name-$code');
      }
    });

    test('is a no-op for the current locale', () async {
      when(() => repo.fetchProducts(locale: any(named: 'locale')))
          .thenAnswer((_) async => [product('Watch')]);
      provider = ProductProvider(repo);
      await Future<void>.delayed(Duration.zero);

      await provider.setLocale('en');

      verify(() => repo.fetchProducts(locale: 'en')).called(1);
    });

    test('does not notify synchronously (safe to call during build)', () async {
      when(() => repo.fetchProducts(locale: any(named: 'locale')))
          .thenAnswer((_) async => [product('Watch')]);
      provider = ProductProvider(repo);
      await Future<void>.delayed(Duration.zero);

      var notifications = 0;
      provider.addListener(() => notifications++);
      final pending = provider.setLocale('ru');

      expect(notifications, 0);
      await pending;
      expect(notifications, greaterThan(0));
    });

    test('a failed reload sets the error and clears the list', () async {
      when(() => repo.fetchProducts(locale: 'en'))
          .thenAnswer((_) async => [product('Watch')]);
      when(() => repo.fetchProducts(locale: 'ru'))
          .thenThrow(Exception('network'));
      provider = ProductProvider(repo);
      await Future<void>.delayed(Duration.zero);

      await provider.setLocale('ru');

      expect(provider.error, contains('Failed to load products'));
      expect(provider.products, isEmpty);
      expect(provider.isLoading, isFalse);
    });

    test('a slow response for the old locale never overwrites the new one',
        () async {
      final slowEnglish = Completer<List<Product>>();
      when(() => repo.fetchProducts(locale: 'en'))
          .thenAnswer((_) => slowEnglish.future);
      when(() => repo.fetchProducts(locale: 'ru'))
          .thenAnswer((_) async => [product('Часы')]);

      provider = ProductProvider(repo); // English load still in flight
      await provider.setLocale('ru'); // Russian load completes first
      expect(provider.products.single.name, 'Часы');

      slowEnglish.complete([product('Watch')]); // stale English arrives late
      await Future<void>.delayed(Duration.zero);

      expect(provider.products.single.name, 'Часы');
      expect(provider.isLoading, isFalse);
    });
  });

  group('localize (cart compatibility)', () {
    setUp(() async {
      when(() => repo.fetchProducts(locale: any(named: 'locale')))
          .thenAnswer((_) async => [
                Product(
                  id: 'elec-001',
                  name: 'Часы',
                  price: 150,
                  oldPrice: 300,
                  category: 'electronics',
                  icon: Icons.watch,
                  subtitle: 'Фитнес',
                  description: 'Описание',
                  features: const ['GPS'],
                  specifications: const {'Экран': 'AMOLED'},
                ),
              ]);
      provider = ProductProvider(repo, initialLocale: 'ru');
      await Future<void>.delayed(Duration.zero);
    });

    test('replaces only translatable text of a stored product', () {
      final stored = Product(
        id: 'elec-001',
        name: 'Watch',
        price: 99.5,
        oldPrice: 199,
        category: 'electronics',
        icon: Icons.watch,
        stock: 7,
        brand: 'TechPro',
        images: const ['u'],
        badges: const ['Best Seller'],
      );

      final localized = provider.localize(stored);

      expect(localized.name, 'Часы');
      expect(localized.subtitle, 'Фитнес');
      expect(localized.description, 'Описание');
      expect(localized.features, ['GPS']);
      expect(localized.specifications, {'Экран': 'AMOLED'});
      // Id and everything the cart / orders rely on stay as stored.
      expect(localized.id, 'elec-001');
      expect(localized.price, 99.5);
      expect(localized.oldPrice, 199);
      expect(localized.stock, 7);
      expect(localized.brand, 'TechPro');
      expect(localized.images, ['u']);
      expect(localized.badges, ['Best Seller']);
    });

    test('returns a product that is not in the catalog unchanged', () {
      final stored = product('Old item', id: 'gone-999');

      expect(identical(provider.localize(stored), stored), isTrue);
    });
  });
}
