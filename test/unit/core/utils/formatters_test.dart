import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/core/utils/formatters.dart';

void main() {
  group('formatPrice', () {
    group('USD', () {
      test('formats base price with \$ symbol and no conversion', () {
        final result = formatPrice(100.0, 'USD', 'en');

        expect(result, contains('\$'));
        expect(result, contains('100.00'));
      });

      test('keeps exactly 2 decimal digits', () {
        final result = formatPrice(99.9, 'USD', 'en');

        expect(result, contains('99.90'));
      });
    });

    group('EUR', () {
      test('converts price using the existing 0.92 rate', () {
        // 100 USD * 0.92 = 92 EUR
        final result = formatPrice(100.0, 'EUR', 'en');

        expect(result, contains('€'));
        expect(result, contains('92.00'));
      });

      test('keeps exactly 2 decimal digits', () {
        // 10 USD * 0.92 = 9.2 EUR
        final result = formatPrice(10.0, 'EUR', 'en');

        expect(result, contains('9.20'));
      });

      test('does not contain the USD symbol', () {
        final result = formatPrice(100.0, 'EUR', 'en');

        expect(result, isNot(contains('\$')));
      });
    });

    group('UZS', () {
      test('converts price using the existing 12500 rate', () {
        // 100 USD * 12500 = 1,250,000 UZS
        final result = formatPrice(100.0, 'UZS', 'en');

        expect(result, contains('1,250,000'));
        expect(result, contains("so'm"));
      });

      test('has 0 decimal digits', () {
        final result = formatPrice(100.0, 'UZS', 'en');

        expect(result, isNot(contains('.00')));
      });

      test('does not contain the USD or EUR symbol', () {
        final result = formatPrice(100.0, 'UZS', 'en');

        expect(result, isNot(contains('\$')));
        expect(result, isNot(contains('€')));
      });
    });

    group('currency selection is independent of locale', () {
      test('EUR renders with the € symbol across different locales', () {
        for (final locale in ['en', 'es', 'fr', 'uz']) {
          final result = formatPrice(100.0, 'EUR', locale);
          expect(result, contains('€'), reason: 'locale=$locale');
          expect(result, isNot(contains('\$')), reason: 'locale=$locale');
        }
      });

      test('USD renders with the \$ symbol across different locales', () {
        for (final locale in ['en', 'es', 'fr', 'uz']) {
          final result = formatPrice(100.0, 'USD', locale);
          expect(result, contains('\$'), reason: 'locale=$locale');
          expect(result, isNot(contains('€')), reason: 'locale=$locale');
        }
      });

      test('the same currencyCode and price convert identically regardless of locale value',
          () {
        final enResult = formatPrice(50.0, 'EUR', 'en');
        final esResult = formatPrice(50.0, 'EUR', 'es');

        // Both should reflect the same 0.92 conversion (50 * 0.92 = 46),
        // even though 'es' formats the decimal separator differently.
        expect(enResult, contains('46.00'));
        expect(esResult, contains('46,00'));
      });
    });

    test('unrecognized currency code falls back to USD', () {
      final result = formatPrice(100.0, 'GBP', 'en');

      expect(result, contains('\$'));
      expect(result, contains('100.00'));
    });
  });
}
