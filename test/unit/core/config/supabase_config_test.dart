import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/core/config/supabase_config.dart';

void main() {
  group('SupabaseConfig.isAllowedUrl', () {
    test('accepts https URLs in debug and release', () {
      for (final isDebug in [true, false]) {
        expect(
          SupabaseConfig.isAllowedUrl('https://abc.supabase.co', isDebug: isDebug),
          isTrue,
        );
      }
    });

    test('accepts http to loopback hosts in debug builds', () {
      for (final url in [
        'http://127.0.0.1:54321',
        'http://localhost:54321',
        'http://10.0.2.2:54321',
      ]) {
        expect(SupabaseConfig.isAllowedUrl(url, isDebug: true), isTrue, reason: url);
      }
    });

    test('rejects http to loopback hosts outside debug builds', () {
      for (final url in [
        'http://127.0.0.1:54321',
        'http://localhost:54321',
        'http://10.0.2.2:54321',
      ]) {
        expect(SupabaseConfig.isAllowedUrl(url, isDebug: false), isFalse, reason: url);
      }
    });

    test('rejects http to non-local hosts even in debug builds', () {
      for (final url in [
        'http://abc.supabase.co',
        'http://192.168.1.10:54321',
        'http://example.com',
      ]) {
        expect(SupabaseConfig.isAllowedUrl(url, isDebug: true), isFalse, reason: url);
      }
    });

    test('rejects look-alike and spoofed hosts', () {
      for (final url in [
        'http://127.0.0.1.evil.com',
        'http://localhost.evil.com',
        'http://localhost@evil.com',
        'http://evil.com/127.0.0.1',
        'http://evil.com?h=localhost',
      ]) {
        expect(SupabaseConfig.isAllowedUrl(url, isDebug: true), isFalse, reason: url);
      }
    });

    test('rejects other schemes, malformed and placeholder values', () {
      for (final url in [
        '',
        'YOUR_SUPABASE_URL_HERE',
        'ftp://localhost',
        'localhost:54321',
        'http://',
        'https://',
        '//localhost',
      ]) {
        expect(SupabaseConfig.isAllowedUrl(url, isDebug: true), isFalse, reason: url);
      }
    });
  });
}
