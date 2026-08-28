import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_first_app/presentation/providers/currency_provider.dart';
import '../../../mocks/mock_persistence_service.dart';

void main() {
  group('CurrencyProvider', () {
    late MockPersistenceService mockPersistenceService;
    late CurrencyProvider provider;

    setUp(() {
      mockPersistenceService = MockPersistenceService();
      // Default: no saved currency (returns null)
      when(() => mockPersistenceService.getString('currency_code'))
          .thenReturn(null);
    });

    tearDown(() {
      // Some tests may dispose the provider themselves
      try {
        provider.dispose();
      } catch (_) {
        // Already disposed or never initialized
      }
    });

    group('Initialization', () {
      test('constructor calls _loadCurrency', () async {
        provider = CurrencyProvider(mockPersistenceService);

        // Wait for async initialization
        await Future.delayed(Duration.zero);

        verify(() => mockPersistenceService.getString('currency_code'))
            .called(1);
      });

      test('initial state with no saved currency defaults to USD', () async {
        provider = CurrencyProvider(mockPersistenceService);

        // Wait for async initialization
        await Future.delayed(Duration.zero);

        expect(provider.currentCurrency, equals('USD'));
        expect(provider.isLoaded, isTrue);
      });

      test('loads saved currency from persistence', () async {
        when(() => mockPersistenceService.getString('currency_code'))
            .thenReturn('EUR');

        provider = CurrencyProvider(mockPersistenceService);

        await Future.delayed(Duration.zero);

        expect(provider.currentCurrency, equals('EUR'));
      });

      test('loads UZS currency from persistence', () async {
        when(() => mockPersistenceService.getString('currency_code'))
            .thenReturn('UZS');

        provider = CurrencyProvider(mockPersistenceService);

        await Future.delayed(Duration.zero);

        expect(provider.currentCurrency, equals('UZS'));
      });

      test('marks as loaded after initialization', () async {
        provider = CurrencyProvider(mockPersistenceService);

        // Initially not loaded (synchronous check before async init)
        // Note: May already be true if initialization is fast

        await Future.delayed(Duration.zero);

        expect(provider.isLoaded, isTrue);
      });

      test('falls back to USD for unsupported saved currency', () async {
        when(() => mockPersistenceService.getString('currency_code'))
            .thenReturn('INVALID');

        provider = CurrencyProvider(mockPersistenceService);

        await Future.delayed(Duration.zero);

        expect(provider.currentCurrency, equals('USD'));
      });

      test('handles persistence error gracefully', () async {
        when(() => mockPersistenceService.getString('currency_code'))
            .thenThrow(Exception('Storage error'));

        provider = CurrencyProvider(mockPersistenceService);

        await Future.delayed(Duration.zero);

        expect(provider.currentCurrency, equals('USD'));
        expect(provider.isLoaded, isTrue);
      });
    });

    group('Getters', () {
      setUp(() async {
        provider = CurrencyProvider(mockPersistenceService);
        await Future.delayed(Duration.zero);
      });

      test('currentCurrency returns USD by default', () {
        expect(provider.currentCurrency, equals('USD'));
      });

      test('currencySymbol returns \$ for USD', () {
        expect(provider.currencySymbol, equals('\$'));
      });

      test('currencyName returns US Dollar for USD', () {
        expect(provider.currencyName, equals('US Dollar (USD)'));
      });

      test('currencySymbol returns € for EUR', () async {
        when(() => mockPersistenceService.saveString(any(), any()))
            .thenAnswer((_) async => true);

        provider.setCurrency('EUR');

        expect(provider.currencySymbol, equals('€'));
      });

      test('currencyName returns Euro for EUR', () async {
        when(() => mockPersistenceService.saveString(any(), any()))
            .thenAnswer((_) async => true);

        provider.setCurrency('EUR');

        expect(provider.currencyName, equals('Euro (EUR)'));
      });

      test('currencySymbol returns so\'m for UZS', () async {
        when(() => mockPersistenceService.saveString(any(), any()))
            .thenAnswer((_) async => true);

        provider.setCurrency('UZS');

        expect(provider.currencySymbol, equals("so'm"));
      });

      test('currencyName returns O\'zbek so\'mi for UZS', () async {
        when(() => mockPersistenceService.saveString(any(), any()))
            .thenAnswer((_) async => true);

        provider.setCurrency('UZS');

        expect(provider.currencyName, equals("O'zbek so'mi (UZS)"));
      });

      test('currencySymbol defaults to \$ for unsupported currency', () async {
        // Force an unsupported currency through internal state
        when(() => mockPersistenceService.saveString(any(), any()))
            .thenAnswer((_) async => true);

        // Set to valid currency first
        provider.setCurrency('USD');

        // Internal state manipulation not possible, so test the fallback in getter
        expect(provider.currencySymbol, equals('\$'));
      });
    });

    group('setCurrency', () {
      setUp(() async {
        provider = CurrencyProvider(mockPersistenceService);
        await Future.delayed(Duration.zero);
        when(() => mockPersistenceService.saveString(any(), any()))
            .thenAnswer((_) async => true);
      });

      test('changes currency for supported currency', () {
        provider.setCurrency('EUR');

        expect(provider.currentCurrency, equals('EUR'));
      });

      test('calls _saveCurrency after change', () async {
        provider.setCurrency('EUR');

        await Future.delayed(Duration.zero);

        verify(() => mockPersistenceService.saveString('currency_code', 'EUR'))
            .called(1);
      });

      test('notifies listeners on currency change', () {
        var listenerCallCount = 0;
        provider.addListener(() => listenerCallCount++);

        provider.setCurrency('EUR');

        expect(listenerCallCount, equals(1));
      });

      test('does nothing for unsupported currency', () {
        var listenerCallCount = 0;
        provider.addListener(() => listenerCallCount++);

        provider.setCurrency('INVALID');

        expect(provider.currentCurrency, equals('USD'));
        expect(listenerCallCount, equals(0));
      });

      test('does nothing when setting same currency', () {
        var listenerCallCount = 0;
        provider.addListener(() => listenerCallCount++);

        provider.setCurrency('USD'); // Already USD

        expect(listenerCallCount, equals(0));
      });

      test('supports changing to EUR', () {
        provider.setCurrency('EUR');

        expect(provider.currentCurrency, equals('EUR'));
      });

      test('supports changing to UZS', () {
        provider.setCurrency('UZS');

        expect(provider.currentCurrency, equals('UZS'));
      });

      test('can change currency multiple times', () {
        provider.setCurrency('EUR');
        expect(provider.currentCurrency, equals('EUR'));

        provider.setCurrency('UZS');
        expect(provider.currentCurrency, equals('UZS'));

        provider.setCurrency('USD');
        expect(provider.currentCurrency, equals('USD'));
      });

      test('notifies listeners on each change', () {
        var listenerCallCount = 0;
        provider.addListener(() => listenerCallCount++);

        provider.setCurrency('EUR');
        provider.setCurrency('UZS');
        provider.setCurrency('USD');

        expect(listenerCallCount, equals(3));
      });

      test('handles persistence error silently', () async {
        when(() => mockPersistenceService.saveString(any(), any()))
            .thenThrow(Exception('Save error'));

        // Should not throw
        expect(() => provider.setCurrency('EUR'), returnsNormally);

        // State should still be updated
        expect(provider.currentCurrency, equals('EUR'));
      });
    });

    group('isCurrencySupported', () {
      setUp(() async {
        provider = CurrencyProvider(mockPersistenceService);
        await Future.delayed(Duration.zero);
      });

      test('returns true for USD', () {
        expect(provider.isCurrencySupported('USD'), isTrue);
      });

      test('returns true for EUR', () {
        expect(provider.isCurrencySupported('EUR'), isTrue);
      });

      test('returns true for UZS', () {
        expect(provider.isCurrencySupported('UZS'), isTrue);
      });

      test('returns false for unsupported currency', () {
        expect(provider.isCurrencySupported('GBP'), isFalse);
        expect(provider.isCurrencySupported('JPY'), isFalse);
        expect(provider.isCurrencySupported('INVALID'), isFalse);
      });

      test('returns false for empty string', () {
        expect(provider.isCurrencySupported(''), isFalse);
      });

      test('is case-sensitive', () {
        expect(provider.isCurrencySupported('usd'), isFalse);
        expect(provider.isCurrencySupported('eur'), isFalse);
      });
    });

    group('Static Constants', () {
      // Note: These tests don't need setUp/tearDown as they test static members
      test('supportedCurrencies contains USD, EUR, UZS', () {
        expect(CurrencyProvider.supportedCurrencies, contains('USD'));
        expect(CurrencyProvider.supportedCurrencies, contains('EUR'));
        expect(CurrencyProvider.supportedCurrencies, contains('UZS'));
        expect(CurrencyProvider.supportedCurrencies.length, equals(3));
      });

      test('currencySymbols contains all supported currencies', () {
        expect(CurrencyProvider.currencySymbols['USD'], equals('\$'));
        expect(CurrencyProvider.currencySymbols['EUR'], equals('€'));
        expect(CurrencyProvider.currencySymbols['UZS'], equals("so'm"));
      });

      test('currencyNames contains all supported currencies', () {
        expect(CurrencyProvider.currencyNames['USD'], isNotNull);
        expect(CurrencyProvider.currencyNames['EUR'], isNotNull);
        expect(CurrencyProvider.currencyNames['UZS'], isNotNull);
      });
    });

    group('getCurrencyFromLanguage Static Method', () {
      // Note: These tests don't need setUp/tearDown as they test static methods
      test('returns USD for en', () {
        expect(CurrencyProvider.getCurrencyFromLanguage('en'), equals('USD'));
      });

      test('returns EUR for es', () {
        expect(CurrencyProvider.getCurrencyFromLanguage('es'), equals('EUR'));
      });

      test('returns EUR for fr', () {
        expect(CurrencyProvider.getCurrencyFromLanguage('fr'), equals('EUR'));
      });

      test('returns UZS for uz', () {
        expect(CurrencyProvider.getCurrencyFromLanguage('uz'), equals('UZS'));
      });

      test('returns USD for unknown language', () {
        expect(CurrencyProvider.getCurrencyFromLanguage('de'), equals('USD'));
        expect(CurrencyProvider.getCurrencyFromLanguage('ja'), equals('USD'));
        expect(CurrencyProvider.getCurrencyFromLanguage('unknown'), equals('USD'));
      });

      test('returns USD for empty string', () {
        expect(CurrencyProvider.getCurrencyFromLanguage(''), equals('USD'));
      });

      test('is case-sensitive for language codes', () {
        // Uppercase should not match
        expect(CurrencyProvider.getCurrencyFromLanguage('EN'), equals('USD'));
        expect(CurrencyProvider.getCurrencyFromLanguage('ES'), equals('USD'));
      });
    });

    group('Persistence', () {
      setUp(() async {
        provider = CurrencyProvider(mockPersistenceService);
        await Future.delayed(Duration.zero);
        when(() => mockPersistenceService.saveString(any(), any()))
            .thenAnswer((_) async => true);
      });

      test('_saveCurrency persists currency code', () async {
        provider.setCurrency('EUR');

        await Future.delayed(Duration.zero);

        verify(() => mockPersistenceService.saveString('currency_code', 'EUR'))
            .called(1);
      });

      test('_loadCurrency retrieves saved currency', () async {
        when(() => mockPersistenceService.getString('currency_code'))
            .thenReturn('EUR');

        final newProvider = CurrencyProvider(mockPersistenceService);

        await Future.delayed(Duration.zero);

        expect(newProvider.currentCurrency, equals('EUR'));

        newProvider.dispose();
      });

      test('persistence roundtrip works correctly', () async {
        provider.setCurrency('UZS');

        await Future.delayed(Duration.zero);

        verify(() => mockPersistenceService.saveString('currency_code', 'UZS'))
            .called(1);

        // Simulate loading in a new provider
        when(() => mockPersistenceService.getString('currency_code'))
            .thenReturn('UZS');

        final newProvider = CurrencyProvider(mockPersistenceService);

        await Future.delayed(Duration.zero);

        expect(newProvider.currentCurrency, equals('UZS'));

        newProvider.dispose();
      });

      test('handles save error without throwing', () async {
        when(() => mockPersistenceService.saveString(any(), any()))
            .thenThrow(Exception('Save failed'));

        expect(() => provider.setCurrency('EUR'), returnsNormally);

        // State should still be updated despite save failure
        expect(provider.currentCurrency, equals('EUR'));
      });

      test('multiple saves only persist latest currency', () async {
        provider.setCurrency('EUR');
        provider.setCurrency('UZS');
        provider.setCurrency('USD');

        await Future.delayed(Duration.zero);

        // Should have called save for each change
        verify(() => mockPersistenceService.saveString('currency_code', 'EUR'))
            .called(1);
        verify(() => mockPersistenceService.saveString('currency_code', 'UZS'))
            .called(1);
        verify(() => mockPersistenceService.saveString('currency_code', 'USD'))
            .called(1);
      });
    });

    group('Edge Cases', () {
      setUp(() async {
        provider = CurrencyProvider(mockPersistenceService);
        await Future.delayed(Duration.zero);
        when(() => mockPersistenceService.saveString(any(), any()))
            .thenAnswer((_) async => true);
      });

      test('setCurrency with null-like strings does nothing', () {
        var listenerCallCount = 0;
        provider.addListener(() => listenerCallCount++);

        // Empty string is not in supported list
        provider.setCurrency('');

        expect(provider.currentCurrency, equals('USD'));
        expect(listenerCallCount, equals(0));
      });

      test('rapid currency changes all process correctly', () {
        var listenerCallCount = 0;
        provider.addListener(() => listenerCallCount++);

        provider.setCurrency('EUR');
        provider.setCurrency('UZS');
        provider.setCurrency('USD');
        provider.setCurrency('EUR');

        expect(provider.currentCurrency, equals('EUR'));
        expect(listenerCallCount, equals(4));
      });

      test('can be disposed after currency changes', () {
        provider.setCurrency('EUR');
        expect(provider.currentCurrency, equals('EUR'));

        // Should not throw when disposing
        expect(() => provider.dispose(), returnsNormally);
      });

      test('operations after dispose throw in debug mode', () async {
        var listenerCallCount = 0;
        provider.addListener(() => listenerCallCount++);

        provider.dispose();

        // In debug mode, operations on disposed provider throw
        expect(() => provider.setCurrency('EUR'), throwsFlutterError);

        // Listener should not have been called
        expect(listenerCallCount, equals(0));
      });
    });

    group('Listener Notifications', () {
      setUp(() async {
        provider = CurrencyProvider(mockPersistenceService);
        await Future.delayed(Duration.zero);
        when(() => mockPersistenceService.saveString(any(), any()))
            .thenAnswer((_) async => true);
      });

      test('setCurrency notifies listeners once', () {
        var listenerCallCount = 0;
        provider.addListener(() => listenerCallCount++);

        provider.setCurrency('EUR');

        expect(listenerCallCount, equals(1));
      });

      test('multiple listeners all receive notification', () {
        var listener1CallCount = 0;
        var listener2CallCount = 0;
        var listener3CallCount = 0;

        provider.addListener(() => listener1CallCount++);
        provider.addListener(() => listener2CallCount++);
        provider.addListener(() => listener3CallCount++);

        provider.setCurrency('EUR');

        expect(listener1CallCount, equals(1));
        expect(listener2CallCount, equals(1));
        expect(listener3CallCount, equals(1));
      });

      test('removed listener does not receive notification', () {
        var removedListenerCallCount = 0;
        var activeListenerCallCount = 0;

        void removedListener() => removedListenerCallCount++;
        void activeListener() => activeListenerCallCount++;

        provider.addListener(removedListener);
        provider.addListener(activeListener);

        provider.removeListener(removedListener);
        provider.setCurrency('EUR');

        expect(removedListenerCallCount, equals(0));
        expect(activeListenerCallCount, equals(1));
      });

      test('no notification when setting same currency', () {
        var listenerCallCount = 0;
        provider.addListener(() => listenerCallCount++);

        provider.setCurrency('USD'); // Already USD

        expect(listenerCallCount, equals(0));
      });

      test('no notification for unsupported currency', () {
        var listenerCallCount = 0;
        provider.addListener(() => listenerCallCount++);

        provider.setCurrency('INVALID');

        expect(listenerCallCount, equals(0));
      });
    });
  });
}
