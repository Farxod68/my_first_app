import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_first_app/presentation/providers/cart_provider.dart';
import 'package:my_first_app/data/models/product.dart';
import '../../../mocks/mock_persistence_service.dart';
import '../../../helpers/test_data.dart';

void main() {
  group('CartProvider', () {
    late MockPersistenceService mockPersistenceService;
    late CartProvider provider;

    setUp(() {
      mockPersistenceService = MockPersistenceService();
      // Default: no saved cart (returns empty list)
      when(() => mockPersistenceService.loadCart()).thenReturn([]);
      when(() => mockPersistenceService.saveCart(any()))
          .thenAnswer((_) async => true);
    });

    tearDown(() {
      try {
        provider.dispose();
      } catch (_) {
        // Already disposed or never initialized
      }
    });

    group('Initialization', () {
      test('constructor calls _loadCart', () async {
        provider = CartProvider(mockPersistenceService);

        await Future.delayed(Duration.zero);

        verify(() => mockPersistenceService.loadCart()).called(1);
      });

      test('initial state with no saved data has empty cart', () async {
        provider = CartProvider(mockPersistenceService);

        await Future.delayed(Duration.zero);

        expect(provider.cartItems, isEmpty);
        expect(provider.itemCount, equals(0));
        expect(provider.subtotal, equals(0.0));
        expect(provider.isLoaded, isTrue);
      });

      test('loads saved products from persistence', () async {
        final product1 = TestData.createTestProduct(id: 'p1', name: 'Product 1', price: 10.0);
        final product2 = TestData.createTestProduct(id: 'p2', name: 'Product 2', price: 20.0);

        final savedCart = [
          json.encode(_productToJson(product1)),
          json.encode(_productToJson(product2)),
        ];

        when(() => mockPersistenceService.loadCart()).thenReturn(savedCart);

        provider = CartProvider(mockPersistenceService);

        await Future.delayed(Duration.zero);

        expect(provider.itemCount, equals(2));
        expect(provider.cartItems[0].id, equals('p1'));
        expect(provider.cartItems[1].id, equals('p2'));
      });

      test('marks as loaded after initialization', () async {
        provider = CartProvider(mockPersistenceService);

        await Future.delayed(Duration.zero);

        expect(provider.isLoaded, isTrue);
      });

      test('handles persistence error gracefully', () async {
        when(() => mockPersistenceService.loadCart())
            .thenThrow(Exception('Storage error'));

        provider = CartProvider(mockPersistenceService);

        await Future.delayed(Duration.zero);

        expect(provider.cartItems, isEmpty);
        expect(provider.isLoaded, isTrue);
      });

      test('handles corrupted cart data gracefully', () async {
        when(() => mockPersistenceService.loadCart())
            .thenReturn(['invalid json', '{not valid}', '']);

        provider = CartProvider(mockPersistenceService);

        await Future.delayed(Duration.zero);

        expect(provider.cartItems, isEmpty);
        expect(provider.isLoaded, isTrue);
      });

      test('skips corrupted items but loads valid items', () async {
        final validProduct = TestData.createTestProduct(id: 'p1', name: 'Valid');
        final validJson = json.encode(_productToJson(validProduct));

        when(() => mockPersistenceService.loadCart())
            .thenReturn(['invalid json', validJson, '{bad}']);

        provider = CartProvider(mockPersistenceService);

        await Future.delayed(Duration.zero);

        expect(provider.itemCount, equals(1));
        expect(provider.cartItems[0].id, equals('p1'));
      });

      test('handles empty saved cart', () async {
        when(() => mockPersistenceService.loadCart()).thenReturn([]);

        provider = CartProvider(mockPersistenceService);

        await Future.delayed(Duration.zero);

        expect(provider.cartItems, isEmpty);
        expect(provider.itemCount, equals(0));
      });
    });

    group('Getters', () {
      setUp(() async {
        provider = CartProvider(mockPersistenceService);
        await Future.delayed(Duration.zero);
        reset(mockPersistenceService);
        when(() => mockPersistenceService.saveCart(any()))
            .thenAnswer((_) async => true);
      });

      test('cartItems returns empty list initially', () {
        expect(provider.cartItems, isEmpty);
        expect(provider.cartItems, isA<List<Product>>());
      });

      test('cartItems returns unmodifiable list', () {
        final product = TestData.createTestProduct();
        provider.addToCart(product);

        final items = provider.cartItems;
        expect(() => items.add(product), throwsUnsupportedError);
      });

      test('itemCount returns 0 initially', () {
        expect(provider.itemCount, equals(0));
      });

      test('itemCount returns correct number of items', () {
        final products = TestData.createProductList(5);
        for (var product in products) {
          provider.addToCart(product);
        }

        expect(provider.itemCount, equals(5));
      });

      test('subtotal returns 0.0 initially', () {
        expect(provider.subtotal, equals(0.0));
      });

      test('subtotal calculates correctly for single item', () {
        final product = TestData.createTestProduct(price: 99.99);
        provider.addToCart(product);

        expect(provider.subtotal, equals(99.99));
      });

      test('subtotal calculates correctly for multiple items', () {
        final product1 = TestData.createTestProduct(price: 10.0);
        final product2 = TestData.createTestProduct(price: 20.0);
        final product3 = TestData.createTestProduct(price: 30.0);

        provider.addToCart(product1);
        provider.addToCart(product2);
        provider.addToCart(product3);

        expect(provider.subtotal, equals(60.0));
      });

      test('subtotal updates after removing item', () {
        final product1 = TestData.createTestProduct(price: 10.0);
        final product2 = TestData.createTestProduct(price: 20.0);

        provider.addToCart(product1);
        provider.addToCart(product2);
        provider.removeAt(0);

        expect(provider.subtotal, equals(20.0));
      });

      test('subtotal is 0.0 after clearing cart', () {
        final products = TestData.createProductList(3);
        for (var product in products) {
          provider.addToCart(product);
        }

        provider.clearCart();

        expect(provider.subtotal, equals(0.0));
      });
    });

    group('isInCart', () {
      setUp(() async {
        provider = CartProvider(mockPersistenceService);
        await Future.delayed(Duration.zero);
        reset(mockPersistenceService);
        when(() => mockPersistenceService.saveCart(any()))
            .thenAnswer((_) async => true);
      });

      test('returns false for product not in cart', () {
        expect(provider.isInCart('product1'), isFalse);
      });

      test('returns true for product in cart', () {
        final product = TestData.createTestProduct(id: 'product1');
        provider.addToCart(product);

        expect(provider.isInCart('product1'), isTrue);
      });

      test('returns false after removing from cart', () {
        final product = TestData.createTestProduct(id: 'product1');
        provider.addToCart(product);
        provider.removeProduct(product);

        expect(provider.isInCart('product1'), isFalse);
      });

      test('returns false for empty cart', () {
        expect(provider.isInCart('product1'), isFalse);
      });

      test('handles special characters in product ID', () {
        final product = TestData.createTestProduct(id: 'product-123_abc@test');
        provider.addToCart(product);

        expect(provider.isInCart('product-123_abc@test'), isTrue);
      });
    });

    group('addToCart', () {
      setUp(() async {
        provider = CartProvider(mockPersistenceService);
        await Future.delayed(Duration.zero);
        reset(mockPersistenceService);
        when(() => mockPersistenceService.saveCart(any()))
            .thenAnswer((_) async => true);
      });

      test('adds product to cart', () {
        final product = TestData.createTestProduct();
        provider.addToCart(product);

        expect(provider.cartItems, contains(product));
        expect(provider.itemCount, equals(1));
      });

      test('allows duplicate products (no quantity management)', () {
        final product = TestData.createTestProduct(id: 'product1');
        provider.addToCart(product);
        provider.addToCart(product);

        expect(provider.itemCount, equals(2));
        expect(provider.cartItems[0].id, equals('product1'));
        expect(provider.cartItems[1].id, equals('product1'));
      });

      test('adds multiple different products', () {
        final products = TestData.createProductList(5);
        for (var product in products) {
          provider.addToCart(product);
        }

        expect(provider.itemCount, equals(5));
      });

      test('maintains order of added products', () {
        final product1 = TestData.createTestProduct(id: 'p1');
        final product2 = TestData.createTestProduct(id: 'p2');
        final product3 = TestData.createTestProduct(id: 'p3');

        provider.addToCart(product1);
        provider.addToCart(product2);
        provider.addToCart(product3);

        expect(provider.cartItems[0].id, equals('p1'));
        expect(provider.cartItems[1].id, equals('p2'));
        expect(provider.cartItems[2].id, equals('p3'));
      });

      test('calls _saveCart after add', () async {
        final product = TestData.createTestProduct();
        provider.addToCart(product);

        await Future.delayed(Duration.zero);

        verify(() => mockPersistenceService.saveCart(any())).called(1);
      });

      test('notifies listeners on add', () {
        final product = TestData.createTestProduct();
        var notified = false;
        provider.addListener(() => notified = true);

        provider.addToCart(product);

        expect(notified, isTrue);
      });

      test('handles persistence error silently', () async {
        when(() => mockPersistenceService.saveCart(any()))
            .thenThrow(Exception('Save failed'));

        final product = TestData.createTestProduct();
        expect(() => provider.addToCart(product), returnsNormally);
        expect(provider.cartItems, contains(product));
      });

      test('updates subtotal after add', () {
        final product = TestData.createTestProduct(price: 50.0);
        provider.addToCart(product);

        expect(provider.subtotal, equals(50.0));

        provider.addToCart(product);

        expect(provider.subtotal, equals(100.0));
      });

      test('can add after clearing cart', () {
        final product = TestData.createTestProduct();
        provider.addToCart(product);
        provider.clearCart();
        provider.addToCart(product);

        expect(provider.itemCount, equals(1));
      });
    });

    group('removeAt', () {
      setUp(() async {
        provider = CartProvider(mockPersistenceService);
        await Future.delayed(Duration.zero);
        reset(mockPersistenceService);
        when(() => mockPersistenceService.saveCart(any()))
            .thenAnswer((_) async => true);
      });

      test('removes product at specified index', () {
        final product1 = TestData.createTestProduct(id: 'p1');
        final product2 = TestData.createTestProduct(id: 'p2');
        final product3 = TestData.createTestProduct(id: 'p3');

        provider.addToCart(product1);
        provider.addToCart(product2);
        provider.addToCart(product3);

        provider.removeAt(1);

        expect(provider.itemCount, equals(2));
        expect(provider.cartItems[0].id, equals('p1'));
        expect(provider.cartItems[1].id, equals('p3'));
      });

      test('handles invalid index gracefully (negative)', () {
        final product = TestData.createTestProduct();
        provider.addToCart(product);

        expect(() => provider.removeAt(-1), returnsNormally);
        expect(provider.itemCount, equals(1));
      });

      test('handles invalid index gracefully (too large)', () {
        final product = TestData.createTestProduct();
        provider.addToCart(product);

        expect(() => provider.removeAt(5), returnsNormally);
        expect(provider.itemCount, equals(1));
      });

      test('handles empty cart gracefully', () {
        expect(() => provider.removeAt(0), returnsNormally);
        expect(provider.itemCount, equals(0));
      });

      test('calls _saveCart after valid remove', () async {
        final product = TestData.createTestProduct();
        provider.addToCart(product);
        reset(mockPersistenceService);
        when(() => mockPersistenceService.saveCart(any()))
            .thenAnswer((_) async => true);

        provider.removeAt(0);

        await Future.delayed(Duration.zero);

        verify(() => mockPersistenceService.saveCart(any())).called(1);
      });

      test('does not call _saveCart for invalid index', () async {
        final product = TestData.createTestProduct();
        provider.addToCart(product);
        reset(mockPersistenceService);
        when(() => mockPersistenceService.saveCart(any()))
            .thenAnswer((_) async => true);

        provider.removeAt(5);

        await Future.delayed(Duration.zero);

        verifyNever(() => mockPersistenceService.saveCart(any()));
      });

      test('notifies listeners on valid remove', () {
        final product = TestData.createTestProduct();
        provider.addToCart(product);

        var notified = false;
        provider.addListener(() => notified = true);

        provider.removeAt(0);

        expect(notified, isTrue);
      });

      test('does not notify listeners on invalid remove', () {
        var notified = false;
        provider.addListener(() => notified = true);

        provider.removeAt(0);

        expect(notified, isFalse);
      });

      test('updates subtotal after remove', () {
        final product1 = TestData.createTestProduct(price: 10.0);
        final product2 = TestData.createTestProduct(price: 20.0);

        provider.addToCart(product1);
        provider.addToCart(product2);

        provider.removeAt(0);

        expect(provider.subtotal, equals(20.0));
      });

      test('removes last item in cart', () {
        final product = TestData.createTestProduct();
        provider.addToCart(product);

        provider.removeAt(0);

        expect(provider.cartItems, isEmpty);
      });
    });

    group('removeProduct', () {
      setUp(() async {
        provider = CartProvider(mockPersistenceService);
        await Future.delayed(Duration.zero);
        reset(mockPersistenceService);
        when(() => mockPersistenceService.saveCart(any()))
            .thenAnswer((_) async => true);
      });

      test('removes all occurrences of product from cart', () {
        final product = TestData.createTestProduct(id: 'product1');
        provider.addToCart(product);
        provider.addToCart(product);
        provider.addToCart(product);

        provider.removeProduct(product);

        expect(provider.itemCount, equals(0));
        expect(provider.isInCart('product1'), isFalse);
      });

      test('removes only matching product by ID', () {
        final product1 = TestData.createTestProduct(id: 'p1');
        final product2 = TestData.createTestProduct(id: 'p2');
        final product3 = TestData.createTestProduct(id: 'p3');

        provider.addToCart(product1);
        provider.addToCart(product2);
        provider.addToCart(product3);

        provider.removeProduct(product2);

        expect(provider.itemCount, equals(2));
        expect(provider.cartItems[0].id, equals('p1'));
        expect(provider.cartItems[1].id, equals('p3'));
      });

      test('removing non-existent product is safe', () {
        final product = TestData.createTestProduct(id: 'product1');
        expect(() => provider.removeProduct(product), returnsNormally);
        expect(provider.itemCount, equals(0));
      });

      test('calls _saveCart after remove', () async {
        final product = TestData.createTestProduct();
        provider.addToCart(product);
        reset(mockPersistenceService);
        when(() => mockPersistenceService.saveCart(any()))
            .thenAnswer((_) async => true);

        provider.removeProduct(product);

        await Future.delayed(Duration.zero);

        verify(() => mockPersistenceService.saveCart(any())).called(1);
      });

      test('notifies listeners on remove', () {
        final product = TestData.createTestProduct();
        provider.addToCart(product);

        var notified = false;
        provider.addListener(() => notified = true);

        provider.removeProduct(product);

        expect(notified, isTrue);
      });

      test('updates subtotal after remove', () {
        final product1 = TestData.createTestProduct(id: 'p1', price: 10.0);
        final product2 = TestData.createTestProduct(id: 'p2', price: 20.0);

        provider.addToCart(product1);
        provider.addToCart(product2);
        provider.addToCart(product1); // Duplicate

        provider.removeProduct(product1);

        expect(provider.subtotal, equals(20.0));
      });

      test('handles persistence error silently', () async {
        final product = TestData.createTestProduct();
        provider.addToCart(product);
        when(() => mockPersistenceService.saveCart(any()))
            .thenThrow(Exception('Save failed'));

        expect(() => provider.removeProduct(product), returnsNormally);
        expect(provider.cartItems, isEmpty);
      });
    });

    group('clearCart', () {
      setUp(() async {
        provider = CartProvider(mockPersistenceService);
        await Future.delayed(Duration.zero);
        reset(mockPersistenceService);
        when(() => mockPersistenceService.saveCart(any()))
            .thenAnswer((_) async => true);
      });

      test('removes all items from cart', () {
        final products = TestData.createProductList(5);
        for (var product in products) {
          provider.addToCart(product);
        }

        provider.clearCart();

        expect(provider.cartItems, isEmpty);
        expect(provider.itemCount, equals(0));
      });

      test('clearing empty cart is safe', () {
        expect(() => provider.clearCart(), returnsNormally);
        expect(provider.itemCount, equals(0));
      });

      test('calls _saveCart after clear', () async {
        final product = TestData.createTestProduct();
        provider.addToCart(product);
        reset(mockPersistenceService);
        when(() => mockPersistenceService.saveCart(any()))
            .thenAnswer((_) async => true);

        provider.clearCart();

        await Future.delayed(Duration.zero);

        verify(() => mockPersistenceService.saveCart([])).called(1);
      });

      test('notifies listeners on clear', () {
        final product = TestData.createTestProduct();
        provider.addToCart(product);

        var notified = false;
        provider.addListener(() => notified = true);

        provider.clearCart();

        expect(notified, isTrue);
      });

      test('resets subtotal to 0.0 after clear', () {
        final products = TestData.createProductList(5);
        for (var product in products) {
          provider.addToCart(product);
        }

        provider.clearCart();

        expect(provider.subtotal, equals(0.0));
      });

      test('can add items after clearing cart', () {
        final product = TestData.createTestProduct();
        provider.addToCart(product);
        provider.clearCart();

        final newProduct = TestData.createTestProduct(id: 'new_product');
        provider.addToCart(newProduct);

        expect(provider.itemCount, equals(1));
        expect(provider.cartItems[0].id, equals('new_product'));
      });

      test('handles persistence error silently', () async {
        final product = TestData.createTestProduct();
        provider.addToCart(product);
        when(() => mockPersistenceService.saveCart(any()))
            .thenThrow(Exception('Save failed'));

        expect(() => provider.clearCart(), returnsNormally);
        expect(provider.cartItems, isEmpty);
      });
    });

    group('JSON Serialization', () {
      setUp(() async {
        provider = CartProvider(mockPersistenceService);
        await Future.delayed(Duration.zero);
        reset(mockPersistenceService);
        when(() => mockPersistenceService.saveCart(any()))
            .thenAnswer((_) async => true);
      });

      test('serializes and deserializes core product fields', () async {
        final product = TestData.createTestProduct(
          id: 'test123',
          name: 'Test Product',
          price: 99.99,
          oldPrice: 149.99,
          category: 'Electronics',
        );

        provider.addToCart(product);
        await Future.delayed(Duration.zero);

        final captured = verify(() => mockPersistenceService.saveCart(captureAny())).captured.last;
        final jsonStrings = captured as List<String>;

        final decodedJson = json.decode(jsonStrings[0]) as Map<String, dynamic>;
        expect(decodedJson['id'], equals('test123'));
        expect(decodedJson['name'], equals('Test Product'));
        expect(decodedJson['price'], equals(99.99));
        expect(decodedJson['oldPrice'], equals(149.99));
        expect(decodedJson['category'], equals('Electronics'));
      });

      test('serializes extended product fields', () async {
        final product = TestData.createTestProduct(
          subtitle: 'Great Product',
          description: 'A wonderful product',
          rating: 4.5,
          reviewCount: 100,
          stock: 50,
          images: ['img1.jpg', 'img2.jpg'],
          brand: 'TestBrand',
          seller: 'TestSeller',
          specifications: {'Weight': '1kg', 'Color': 'Blue'},
          features: ['Feature 1', 'Feature 2'],
          badges: ['New', 'Sale'],
        );

        provider.addToCart(product);
        await Future.delayed(Duration.zero);

        final captured = verify(() => mockPersistenceService.saveCart(captureAny())).captured.last;
        final jsonStrings = captured as List<String>;
        final decodedJson = json.decode(jsonStrings[0]) as Map<String, dynamic>;

        expect(decodedJson['subtitle'], equals('Great Product'));
        expect(decodedJson['description'], equals('A wonderful product'));
        expect(decodedJson['rating'], equals(4.5));
        expect(decodedJson['reviewCount'], equals(100));
        expect(decodedJson['stock'], equals(50));
        expect(decodedJson['images'], equals(['img1.jpg', 'img2.jpg']));
        expect(decodedJson['brand'], equals('TestBrand'));
        expect(decodedJson['seller'], equals('TestSeller'));
        expect(decodedJson['specifications'], equals({'Weight': '1kg', 'Color': 'Blue'}));
        expect(decodedJson['features'], equals(['Feature 1', 'Feature 2']));
        expect(decodedJson['badges'], equals(['New', 'Sale']));
      });

      test('serializes icon data', () async {
        final product = TestData.createTestProduct(
          icon: Icons.shopping_cart,
        );

        provider.addToCart(product);
        await Future.delayed(Duration.zero);

        final captured = verify(() => mockPersistenceService.saveCart(captureAny())).captured.last;
        final jsonStrings = captured as List<String>;
        final decodedJson = json.decode(jsonStrings[0]) as Map<String, dynamic>;

        expect(decodedJson['iconCodePoint'], isA<int>());
        expect(decodedJson['iconCodePoint'], equals(Icons.shopping_cart.codePoint));
      });

      test('roundtrip preserves all product data', () async {
        final originalProduct = TestData.createTestProduct(
          id: 'test123',
          name: 'Test Product',
          price: 99.99,
          oldPrice: 149.99,
          category: 'Electronics',
          subtitle: 'Great',
          description: 'Description',
          rating: 4.5,
          reviewCount: 100,
          stock: 50,
          images: ['img1.jpg'],
          brand: 'Brand',
          seller: 'Seller',
          specifications: {'Key': 'Value'},
          features: ['Feature'],
          badges: ['Badge'],
        );

        // Serialize
        provider.addToCart(originalProduct);
        await Future.delayed(Duration.zero);

        final captured = verify(() => mockPersistenceService.saveCart(captureAny())).captured.last;
        final jsonStrings = captured as List<String>;

        // Deserialize by creating new provider with saved data
        when(() => mockPersistenceService.loadCart()).thenReturn(jsonStrings);
        final newProvider = CartProvider(mockPersistenceService);
        await Future.delayed(Duration.zero);

        final loadedProduct = newProvider.cartItems[0];
        expect(loadedProduct.id, equals(originalProduct.id));
        expect(loadedProduct.name, equals(originalProduct.name));
        expect(loadedProduct.price, equals(originalProduct.price));
        expect(loadedProduct.oldPrice, equals(originalProduct.oldPrice));
        expect(loadedProduct.category, equals(originalProduct.category));
        expect(loadedProduct.subtitle, equals(originalProduct.subtitle));
        expect(loadedProduct.description, equals(originalProduct.description));
        expect(loadedProduct.rating, equals(originalProduct.rating));
        expect(loadedProduct.reviewCount, equals(originalProduct.reviewCount));
        expect(loadedProduct.stock, equals(originalProduct.stock));
        expect(loadedProduct.images, equals(originalProduct.images));
        expect(loadedProduct.brand, equals(originalProduct.brand));
        expect(loadedProduct.seller, equals(originalProduct.seller));

        newProvider.dispose();
      });

      test('handles missing optional fields with defaults', () async {
        final minimalJson = json.encode({
          'id': 'test123',
          'name': 'Test Product',
          'price': 99.99,
          'oldPrice': 149.99,
          'category': 'Electronics',
          'iconCodePoint': Icons.devices.codePoint,
          // No optional fields
        });

        when(() => mockPersistenceService.loadCart()).thenReturn([minimalJson]);

        provider = CartProvider(mockPersistenceService);
        await Future.delayed(Duration.zero);

        final product = provider.cartItems[0];
        expect(product.id, equals('test123'));
        expect(product.name, equals('Test Product'));
        expect(product.rating, equals(0.0)); // Default
        expect(product.reviewCount, equals(0)); // Default
        expect(product.stock, equals(0)); // Default
        expect(product.images, isEmpty); // Default
        expect(product.badges, isEmpty); // Default
      });

      test('handles missing id field with default', () async {
        final jsonWithoutId = json.encode({
          'name': 'Test Product',
          'price': 99.99,
          'oldPrice': 149.99,
          'category': 'Electronics',
          'iconCodePoint': Icons.devices.codePoint,
        });

        when(() => mockPersistenceService.loadCart()).thenReturn([jsonWithoutId]);

        provider = CartProvider(mockPersistenceService);
        await Future.delayed(Duration.zero);

        final product = provider.cartItems[0];
        expect(product.id, equals('unknown')); // Default fallback
      });

      test('serializes multiple products correctly', () async {
        final products = TestData.createProductList(3);
        for (var product in products) {
          provider.addToCart(product);
        }

        await Future.delayed(Duration.zero);

        final captured = verify(() => mockPersistenceService.saveCart(captureAny())).captured.last;
        final jsonStrings = captured as List<String>;

        expect(jsonStrings.length, equals(3));
        for (var jsonString in jsonStrings) {
          expect(() => json.decode(jsonString), returnsNormally);
        }
      });

      test('handles empty strings in fields', () async {
        final product = TestData.createTestProduct(
          name: '',
          subtitle: '',
          description: '',
          brand: '',
          seller: '',
        );

        provider.addToCart(product);
        await Future.delayed(Duration.zero);

        final captured = verify(() => mockPersistenceService.saveCart(captureAny())).captured.last;
        final jsonStrings = captured as List<String>;

        expect(() => json.decode(jsonStrings[0]), returnsNormally);
      });

      test('handles special characters in fields', () async {
        final product = TestData.createTestProduct(
          name: 'Product "Special" <Tag>',
          description: 'Line 1\nLine 2\tTab',
        );

        provider.addToCart(product);
        await Future.delayed(Duration.zero);

        final captured = verify(() => mockPersistenceService.saveCart(captureAny())).captured.last;
        final jsonStrings = captured as List<String>;
        final decodedJson = json.decode(jsonStrings[0]) as Map<String, dynamic>;

        expect(decodedJson['name'], equals('Product "Special" <Tag>'));
        expect(decodedJson['description'], equals('Line 1\nLine 2\tTab'));
      });

      test('handles unicode characters in fields', () async {
        final product = TestData.createTestProduct(
          name: 'محصول - 产品 - продукт',
          description: 'Unicode: 你好 مرحبا Привет',
        );

        provider.addToCart(product);
        await Future.delayed(Duration.zero);

        final captured = verify(() => mockPersistenceService.saveCart(captureAny())).captured.last;
        final jsonStrings = captured as List<String>;
        final decodedJson = json.decode(jsonStrings[0]) as Map<String, dynamic>;

        expect(decodedJson['name'], equals('محصول - 产品 - продукт'));
        expect(decodedJson['description'], equals('Unicode: 你好 مرحبا Привет'));
      });
    });

    group('Persistence', () {
      setUp(() async {
        provider = CartProvider(mockPersistenceService);
        await Future.delayed(Duration.zero);
        reset(mockPersistenceService);
      });

      test('saveCart persists serialized products', () async {
        when(() => mockPersistenceService.saveCart(any()))
            .thenAnswer((_) async => true);

        final product = TestData.createTestProduct();
        provider.addToCart(product);

        await Future.delayed(Duration.zero);

        final captured = verify(() => mockPersistenceService.saveCart(captureAny())).captured.last;
        expect(captured, isA<List<String>>());
        expect((captured as List).length, equals(1));
      });

      test('loadCart retrieves saved products', () async {
        final product = TestData.createTestProduct(id: 'p1', name: 'Product 1');
        final savedCart = [json.encode(_productToJson(product))];

        when(() => mockPersistenceService.loadCart()).thenReturn(savedCart);

        provider = CartProvider(mockPersistenceService);
        await Future.delayed(Duration.zero);

        expect(provider.itemCount, equals(1));
        expect(provider.cartItems[0].id, equals('p1'));
      });

      test('persistence roundtrip works correctly', () async {
        final products = TestData.createProductList(3);
        final savedCart = products
            .map((p) => json.encode(_productToJson(p)))
            .toList();

        when(() => mockPersistenceService.loadCart()).thenReturn(savedCart);

        provider = CartProvider(mockPersistenceService);
        await Future.delayed(Duration.zero);

        expect(provider.itemCount, equals(3));
      });

      test('handles save error without throwing', () async {
        when(() => mockPersistenceService.saveCart(any()))
            .thenThrow(Exception('Save failed'));

        final product = TestData.createTestProduct();
        expect(() => provider.addToCart(product), returnsNormally);
      });

      test('handles load error without throwing', () async {
        when(() => mockPersistenceService.loadCart())
            .thenThrow(Exception('Load failed'));

        expect(() => CartProvider(mockPersistenceService), returnsNormally);
      });

      test('saves after each add operation', () async {
        when(() => mockPersistenceService.saveCart(any()))
            .thenAnswer((_) async => true);

        final products = TestData.createProductList(3);
        for (var product in products) {
          provider.addToCart(product);
        }

        await Future.delayed(Duration.zero);

        verify(() => mockPersistenceService.saveCart(any())).called(3);
      });

      test('saves after each remove operation', () async {
        when(() => mockPersistenceService.saveCart(any()))
            .thenAnswer((_) async => true);

        final products = TestData.createProductList(2);
        provider.addToCart(products[0]);
        provider.addToCart(products[1]);

        reset(mockPersistenceService);
        when(() => mockPersistenceService.saveCart(any()))
            .thenAnswer((_) async => true);

        provider.removeAt(0);
        provider.removeAt(0);

        await Future.delayed(Duration.zero);

        verify(() => mockPersistenceService.saveCart(any())).called(2);
      });
    });

    group('Edge Cases', () {
      setUp(() async {
        provider = CartProvider(mockPersistenceService);
        await Future.delayed(Duration.zero);
        reset(mockPersistenceService);
        when(() => mockPersistenceService.saveCart(any()))
            .thenAnswer((_) async => true);
      });

      test('handles very large cart', () {
        final products = TestData.createProductList(1000);
        for (var product in products) {
          provider.addToCart(product);
        }

        expect(provider.itemCount, equals(1000));
        expect(provider.subtotal, greaterThan(0));
      });

      test('handles product with zero price', () {
        final product = TestData.createTestProduct(price: 0.0);
        provider.addToCart(product);

        expect(provider.subtotal, equals(0.0));
      });

      test('handles product with very large price', () {
        final product = TestData.createTestProduct(price: 999999.99);
        provider.addToCart(product);

        expect(provider.subtotal, equals(999999.99));
      });

      test('handles product with negative price (edge case)', () {
        final product = TestData.createTestProduct(price: -10.0);
        provider.addToCart(product);

        expect(provider.subtotal, equals(-10.0));
      });

      test('subtotal precision with decimal prices', () {
        final product1 = TestData.createTestProduct(price: 10.99);
        final product2 = TestData.createTestProduct(price: 20.99);

        provider.addToCart(product1);
        provider.addToCart(product2);

        expect(provider.subtotal, closeTo(31.98, 0.001));
      });

      test('rapid additions process correctly', () {
        final product = TestData.createTestProduct();
        for (int i = 0; i < 100; i++) {
          provider.addToCart(product);
        }

        expect(provider.itemCount, equals(100));
      });

      test('alternating add and remove operations', () {
        final product = TestData.createTestProduct();

        provider.addToCart(product);
        provider.removeAt(0);
        provider.addToCart(product);
        provider.removeAt(0);
        provider.addToCart(product);

        expect(provider.itemCount, equals(1));
      });

      test('can be disposed after operations', () {
        final product = TestData.createTestProduct();
        provider.addToCart(product);
        provider.removeAt(0);

        expect(() => provider.dispose(), returnsNormally);
      });

      test('handles empty product name', () {
        final product = TestData.createTestProduct(name: '');
        provider.addToCart(product);

        expect(provider.cartItems[0].name, isEmpty);
      });

      test('removeProduct with no matching items is safe', () {
        final product = TestData.createTestProduct(id: 'product1');
        expect(() => provider.removeProduct(product), returnsNormally);
      });

      test('multiple clears are safe', () {
        final product = TestData.createTestProduct();
        provider.addToCart(product);

        provider.clearCart();
        provider.clearCart();
        provider.clearCart();

        expect(provider.itemCount, equals(0));
      });
    });

    group('Listener Notifications', () {
      setUp(() async {
        provider = CartProvider(mockPersistenceService);
        await Future.delayed(Duration.zero);
        reset(mockPersistenceService);
        when(() => mockPersistenceService.saveCart(any()))
            .thenAnswer((_) async => true);
      });

      test('addToCart notifies listeners once', () {
        final product = TestData.createTestProduct();
        var notificationCount = 0;
        provider.addListener(() => notificationCount++);

        provider.addToCart(product);

        expect(notificationCount, equals(1));
      });

      test('removeAt notifies listeners once for valid index', () {
        final product = TestData.createTestProduct();
        provider.addToCart(product);

        var notificationCount = 0;
        provider.addListener(() => notificationCount++);

        provider.removeAt(0);

        expect(notificationCount, equals(1));
      });

      test('removeAt does not notify listeners for invalid index', () {
        var notificationCount = 0;
        provider.addListener(() => notificationCount++);

        provider.removeAt(0);

        expect(notificationCount, equals(0));
      });

      test('removeProduct notifies listeners once', () {
        final product = TestData.createTestProduct();
        provider.addToCart(product);

        var notificationCount = 0;
        provider.addListener(() => notificationCount++);

        provider.removeProduct(product);

        expect(notificationCount, equals(1));
      });

      test('clearCart notifies listeners once', () {
        final product = TestData.createTestProduct();
        provider.addToCart(product);

        var notificationCount = 0;
        provider.addListener(() => notificationCount++);

        provider.clearCart();

        expect(notificationCount, equals(1));
      });

      test('multiple listeners all receive notification', () {
        final product = TestData.createTestProduct();
        var notified1 = false;
        var notified2 = false;
        var notified3 = false;

        provider.addListener(() => notified1 = true);
        provider.addListener(() => notified2 = true);
        provider.addListener(() => notified3 = true);

        provider.addToCart(product);

        expect(notified1, isTrue);
        expect(notified2, isTrue);
        expect(notified3, isTrue);
      });

      test('removed listener does not receive notification', () {
        final product = TestData.createTestProduct();
        var notified = false;
        void listener() => notified = true;

        provider.addListener(listener);
        provider.removeListener(listener);

        provider.addToCart(product);

        expect(notified, isFalse);
      });

      test('getters do not notify listeners', () {
        final product = TestData.createTestProduct();
        provider.addToCart(product);

        var notified = false;
        provider.addListener(() => notified = true);

        // Access getters
        provider.cartItems;
        provider.itemCount;
        provider.subtotal;
        provider.isInCart('product1');

        expect(notified, isFalse);
      });
    });
  });
}

/// Helper function to convert Product to JSON (mirrors CartProvider's implementation)
Map<String, dynamic> _productToJson(Product product) {
  return {
    'id': product.id,
    'name': product.name,
    'price': product.price,
    'oldPrice': product.oldPrice,
    'category': product.category,
    'iconCodePoint': product.icon.codePoint,
    'subtitle': product.subtitle,
    'description': product.description,
    'rating': product.rating,
    'reviewCount': product.reviewCount,
    'stock': product.stock,
    'images': product.images,
    'brand': product.brand,
    'seller': product.seller,
    'specifications': product.specifications,
    'features': product.features,
    'badges': product.badges,
  };
}
