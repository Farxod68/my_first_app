import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_first_app/presentation/providers/locale_provider.dart';
import '../../../mocks/mock_persistence_service.dart';

void main() {
  group('LocaleProvider', () {
    late MockPersistenceService mockPersistenceService;
    late LocaleProvider provider;

    setUp(() {
      mockPersistenceService = MockPersistenceService();
      // Default: no saved locale (returns null)
      when(() => mockPersistenceService.loadLocale()).thenReturn(null);
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
      test('constructor calls _loadLocale', () async {
        provider = LocaleProvider(mockPersistenceService);

        // Wait for async initialization
        await Future.delayed(Duration.zero);

        verify(() => mockPersistenceService.loadLocale()).called(1);
      });

      test('initial state with no saved locale defaults to en', () async {
        provider = LocaleProvider(mockPersistenceService);

        await Future.delayed(Duration.zero);

        expect(provider.currentLocale, equals(const Locale('en')));
        expect(provider.languageCode, equals('en'));
        expect(provider.isLoaded, isTrue);
      });

      test('loads saved locale from persistence', () async {
        when(() => mockPersistenceService.loadLocale()).thenReturn('es');

        provider = LocaleProvider(mockPersistenceService);

        await Future.delayed(Duration.zero);

        expect(provider.currentLocale, equals(const Locale('es')));
        expect(provider.languageCode, equals('es'));
      });

      test('loads all supported locales from persistence', () async {
        final supportedCodes = ['en', 'es', 'fr', 'uz'];

        for (final code in supportedCodes) {
          when(() => mockPersistenceService.loadLocale()).thenReturn(code);

          final testProvider = LocaleProvider(mockPersistenceService);

          await Future.delayed(Duration.zero);

          expect(testProvider.currentLocale, equals(Locale(code)));
          expect(testProvider.languageCode, equals(code));

          testProvider.dispose();
        }
      });

      test('marks as loaded after initialization', () async {
        provider = LocaleProvider(mockPersistenceService);

        await Future.delayed(Duration.zero);

        expect(provider.isLoaded, isTrue);
      });

      test('falls back to en for unsupported saved locale', () async {
        when(() => mockPersistenceService.loadLocale()).thenReturn('de');

        provider = LocaleProvider(mockPersistenceService);

        await Future.delayed(Duration.zero);

        expect(provider.currentLocale, equals(const Locale('en')));
        expect(provider.languageCode, equals('en'));
      });

      test('handles persistence error gracefully', () async {
        when(() => mockPersistenceService.loadLocale())
            .thenThrow(Exception('Storage error'));

        provider = LocaleProvider(mockPersistenceService);

        await Future.delayed(Duration.zero);

        expect(provider.currentLocale, equals(const Locale('en')));
        expect(provider.isLoaded, isTrue);
      });
    });

    group('Getters', () {
      setUp(() async {
        provider = LocaleProvider(mockPersistenceService);
        await Future.delayed(Duration.zero);
      });

      test('currentLocale returns en by default', () {
        expect(provider.currentLocale, equals(const Locale('en')));
      });

      test('languageCode returns en by default', () {
        expect(provider.languageCode, equals('en'));
      });

      test('currentLocale returns Locale object', () {
        expect(provider.currentLocale, isA<Locale>());
        expect(provider.currentLocale.languageCode, equals('en'));
      });

      test('languageCode matches currentLocale.languageCode', () {
        expect(provider.languageCode, equals(provider.currentLocale.languageCode));
      });

      test('getters reflect locale changes', () async {
        when(() => mockPersistenceService.saveLocale(any()))
            .thenAnswer((_) async => true);

        provider.setLocale(const Locale('es'));

        expect(provider.currentLocale, equals(const Locale('es')));
        expect(provider.languageCode, equals('es'));
      });
    });

    group('setLocale', () {
      setUp(() async {
        provider = LocaleProvider(mockPersistenceService);
        await Future.delayed(Duration.zero);
        when(() => mockPersistenceService.saveLocale(any()))
            .thenAnswer((_) async => true);
      });

      test('changes locale for supported locale', () {
        provider.setLocale(const Locale('es'));

        expect(provider.currentLocale, equals(const Locale('es')));
      });

      test('calls _saveLocale after change', () async {
        provider.setLocale(const Locale('es'));

        await Future.delayed(Duration.zero);

        verify(() => mockPersistenceService.saveLocale('es')).called(1);
      });

      test('notifies listeners on locale change', () {
        var listenerCallCount = 0;
        provider.addListener(() => listenerCallCount++);

        provider.setLocale(const Locale('es'));

        expect(listenerCallCount, equals(1));
      });

      test('does nothing for unsupported locale', () {
        var listenerCallCount = 0;
        provider.addListener(() => listenerCallCount++);

        provider.setLocale(const Locale('de'));

        expect(provider.currentLocale, equals(const Locale('en')));
        expect(listenerCallCount, equals(0));
      });

      test('does nothing when setting same locale', () {
        var listenerCallCount = 0;
        provider.addListener(() => listenerCallCount++);

        provider.setLocale(const Locale('en')); // Already en

        expect(listenerCallCount, equals(0));
      });

      test('supports changing to all supported locales', () {
        final supportedLocales = [
          const Locale('en'),
          const Locale('es'),
          const Locale('fr'),
          const Locale('uz'),
        ];

        for (final locale in supportedLocales) {
          provider.setLocale(locale);
          expect(provider.currentLocale, equals(locale));
        }
      });

      test('can change locale multiple times', () {
        provider.setLocale(const Locale('es'));
        expect(provider.currentLocale, equals(const Locale('es')));

        provider.setLocale(const Locale('fr'));
        expect(provider.currentLocale, equals(const Locale('fr')));

        provider.setLocale(const Locale('uz'));
        expect(provider.currentLocale, equals(const Locale('uz')));

        provider.setLocale(const Locale('en'));
        expect(provider.currentLocale, equals(const Locale('en')));
      });

      test('notifies listeners on each change', () {
        var listenerCallCount = 0;
        provider.addListener(() => listenerCallCount++);

        provider.setLocale(const Locale('es'));
        provider.setLocale(const Locale('fr'));
        provider.setLocale(const Locale('uz'));

        expect(listenerCallCount, equals(3));
      });

      test('handles persistence error silently', () async {
        when(() => mockPersistenceService.saveLocale(any()))
            .thenThrow(Exception('Save error'));

        // Should not throw
        expect(() => provider.setLocale(const Locale('es')), returnsNormally);

        // State should still be updated
        expect(provider.currentLocale, equals(const Locale('es')));
      });
    });

    group('setLocaleByCode', () {
      setUp(() async {
        provider = LocaleProvider(mockPersistenceService);
        await Future.delayed(Duration.zero);
        when(() => mockPersistenceService.saveLocale(any()))
            .thenAnswer((_) async => true);
      });

      test('creates Locale from code and calls setLocale', () {
        provider.setLocaleByCode('es');

        expect(provider.currentLocale, equals(const Locale('es')));
      });

      test('works for all supported language codes', () {
        final codes = ['en', 'es', 'fr', 'uz'];

        for (final code in codes) {
          provider.setLocaleByCode(code);
          expect(provider.languageCode, equals(code));
        }
      });

      test('handles unsupported codes same as setLocale', () {
        provider.setLocaleByCode('de');

        expect(provider.currentLocale, equals(const Locale('en')));
      });

      test('notifies listeners', () {
        var listenerCallCount = 0;
        provider.addListener(() => listenerCallCount++);

        provider.setLocaleByCode('es');

        expect(listenerCallCount, equals(1));
      });

      test('calls saveLocale with correct code', () async {
        provider.setLocaleByCode('fr');

        await Future.delayed(Duration.zero);

        verify(() => mockPersistenceService.saveLocale('fr')).called(1);
      });
    });

    group('isLocaleSupported', () {
      setUp(() async {
        provider = LocaleProvider(mockPersistenceService);
        await Future.delayed(Duration.zero);
      });

      test('returns true for en', () {
        expect(provider.isLocaleSupported(const Locale('en')), isTrue);
      });

      test('returns true for es', () {
        expect(provider.isLocaleSupported(const Locale('es')), isTrue);
      });

      test('returns true for fr', () {
        expect(provider.isLocaleSupported(const Locale('fr')), isTrue);
      });

      test('returns true for uz', () {
        expect(provider.isLocaleSupported(const Locale('uz')), isTrue);
      });

      test('returns false for unsupported locales', () {
        expect(provider.isLocaleSupported(const Locale('de')), isFalse);
        expect(provider.isLocaleSupported(const Locale('ja')), isFalse);
        expect(provider.isLocaleSupported(const Locale('ru')), isFalse);
      });

      test('checks all supported locales', () {
        for (final locale in LocaleProvider.supportedLocales) {
          expect(provider.isLocaleSupported(locale), isTrue);
        }
      });
    });

    group('Static Constants', () {
      test('supportedLocales contains en, es, fr, uz', () {
        expect(LocaleProvider.supportedLocales.length, equals(4));
        expect(LocaleProvider.supportedLocales, contains(const Locale('en')));
        expect(LocaleProvider.supportedLocales, contains(const Locale('es')));
        expect(LocaleProvider.supportedLocales, contains(const Locale('fr')));
        expect(LocaleProvider.supportedLocales, contains(const Locale('uz')));
      });

      test('supportedLocales are all Locale objects', () {
        for (final locale in LocaleProvider.supportedLocales) {
          expect(locale, isA<Locale>());
        }
      });

      test('supportedLocales are const', () {
        expect(LocaleProvider.supportedLocales, isA<List<Locale>>());
      });
    });

    group('Persistence', () {
      setUp(() async {
        provider = LocaleProvider(mockPersistenceService);
        await Future.delayed(Duration.zero);
        when(() => mockPersistenceService.saveLocale(any()))
            .thenAnswer((_) async => true);
      });

      test('_saveLocale persists locale code', () async {
        provider.setLocale(const Locale('es'));

        await Future.delayed(Duration.zero);

        verify(() => mockPersistenceService.saveLocale('es')).called(1);
      });

      test('_loadLocale retrieves saved locale', () async {
        when(() => mockPersistenceService.loadLocale()).thenReturn('fr');

        final newProvider = LocaleProvider(mockPersistenceService);

        await Future.delayed(Duration.zero);

        expect(newProvider.currentLocale, equals(const Locale('fr')));

        newProvider.dispose();
      });

      test('persistence roundtrip works correctly', () async {
        provider.setLocale(const Locale('uz'));

        await Future.delayed(Duration.zero);

        verify(() => mockPersistenceService.saveLocale('uz')).called(1);

        // Simulate loading in a new provider
        when(() => mockPersistenceService.loadLocale()).thenReturn('uz');

        final newProvider = LocaleProvider(mockPersistenceService);

        await Future.delayed(Duration.zero);

        expect(newProvider.currentLocale, equals(const Locale('uz')));

        newProvider.dispose();
      });

      test('handles save error without throwing', () async {
        when(() => mockPersistenceService.saveLocale(any()))
            .thenThrow(Exception('Save failed'));

        expect(() => provider.setLocale(const Locale('es')), returnsNormally);

        // State should still be updated despite save failure
        expect(provider.currentLocale, equals(const Locale('es')));
      });

      test('multiple saves only persist latest locale', () async {
        provider.setLocale(const Locale('es'));
        provider.setLocale(const Locale('fr'));
        provider.setLocale(const Locale('uz'));

        await Future.delayed(Duration.zero);

        // Should have called save for each change
        verify(() => mockPersistenceService.saveLocale('es')).called(1);
        verify(() => mockPersistenceService.saveLocale('fr')).called(1);
        verify(() => mockPersistenceService.saveLocale('uz')).called(1);
      });
    });

    group('Edge Cases', () {
      setUp(() async {
        provider = LocaleProvider(mockPersistenceService);
        await Future.delayed(Duration.zero);
        when(() => mockPersistenceService.saveLocale(any()))
            .thenAnswer((_) async => true);
      });

      test('setLocaleByCode with unsupported code does nothing', () {
        var listenerCallCount = 0;
        provider.addListener(() => listenerCallCount++);

        provider.setLocaleByCode('de'); // Unsupported

        expect(provider.currentLocale, equals(const Locale('en')));
        expect(listenerCallCount, equals(0));
      });

      test('rapid locale changes all process correctly', () {
        var listenerCallCount = 0;
        provider.addListener(() => listenerCallCount++);

        provider.setLocale(const Locale('es'));
        provider.setLocale(const Locale('fr'));
        provider.setLocale(const Locale('uz'));
        provider.setLocale(const Locale('en'));
        provider.setLocale(const Locale('es'));

        expect(provider.currentLocale, equals(const Locale('es')));
        expect(listenerCallCount, equals(5));
      });

      test('can be disposed after locale changes', () {
        provider.setLocale(const Locale('es'));
        expect(provider.currentLocale, equals(const Locale('es')));

        // Should not throw when disposing
        expect(() => provider.dispose(), returnsNormally);
      });

      test('operations after dispose throw in debug mode', () async {
        var listenerCallCount = 0;
        provider.addListener(() => listenerCallCount++);

        provider.dispose();

        // In debug mode, operations on disposed provider throw
        expect(() => provider.setLocale(const Locale('es')), throwsFlutterError);

        // Listener should not have been called
        expect(listenerCallCount, equals(0));
      });

      test('Locale equality works correctly', () {
        expect(const Locale('en'), equals(const Locale('en')));
        expect(const Locale('es'), isNot(equals(const Locale('en'))));
      });
    });

    group('Listener Notifications', () {
      setUp(() async {
        provider = LocaleProvider(mockPersistenceService);
        await Future.delayed(Duration.zero);
        when(() => mockPersistenceService.saveLocale(any()))
            .thenAnswer((_) async => true);
      });

      test('setLocale notifies listeners once', () {
        var listenerCallCount = 0;
        provider.addListener(() => listenerCallCount++);

        provider.setLocale(const Locale('es'));

        expect(listenerCallCount, equals(1));
      });

      test('setLocaleByCode notifies listeners once', () {
        var listenerCallCount = 0;
        provider.addListener(() => listenerCallCount++);

        provider.setLocaleByCode('es');

        expect(listenerCallCount, equals(1));
      });

      test('multiple listeners all receive notification', () {
        var listener1CallCount = 0;
        var listener2CallCount = 0;
        var listener3CallCount = 0;

        provider.addListener(() => listener1CallCount++);
        provider.addListener(() => listener2CallCount++);
        provider.addListener(() => listener3CallCount++);

        provider.setLocale(const Locale('es'));

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
        provider.setLocale(const Locale('es'));

        expect(removedListenerCallCount, equals(0));
        expect(activeListenerCallCount, equals(1));
      });

      test('no notification when setting same locale', () {
        var listenerCallCount = 0;
        provider.addListener(() => listenerCallCount++);

        provider.setLocale(const Locale('en')); // Already en

        expect(listenerCallCount, equals(0));
      });

      test('no notification for unsupported locale', () {
        var listenerCallCount = 0;
        provider.addListener(() => listenerCallCount++);

        provider.setLocale(const Locale('de'));

        expect(listenerCallCount, equals(0));
      });
    });
  });
}
