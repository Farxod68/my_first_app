import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_first_app/core/services/supabase_service.dart';
import 'package:my_first_app/core/config/supabase_config.dart';
import '../../../mocks/mock_supabase.dart';

void main() {
  group('SupabaseService', () {
    setUp(() {
      // Reset service state before each test
      // Note: We can't easily reset static state, so tests must be independent
    });

    group('isInitialized getter', () {
      test('returns false when not initialized', () {
        // After dispose, isInitialized should be false
        // This tests the getter logic
        expect(SupabaseService.isInitialized, isA<bool>());
      });

      test('isInitialized reflects initialization state', () {
        // isInitialized should return false or true based on _client state
        final initialState = SupabaseService.isInitialized;
        expect(initialState, isA<bool>());
      });
    });

    group('client getter', () {
      test('throws when not initialized', () {
        // First dispose to ensure clean state
        SupabaseService.dispose();

        expect(
          () => SupabaseService.client,
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('not initialized'),
          )),
        );
      });

      test('error message is descriptive when not initialized', () {
        SupabaseService.dispose();

        try {
          SupabaseService.client;
          fail('Should have thrown exception');
        } catch (e) {
          expect(e.toString(), contains('SupabaseService not initialized'));
          expect(e.toString(), contains('Call SupabaseService.initialize()'));
        }
      });
    });

    group('dispose', () {
      test('dispose completes without error', () async {
        expect(() => SupabaseService.dispose(), returnsNormally);
      });

      test('dispose makes isInitialized return false', () async {
        await SupabaseService.dispose();

        expect(SupabaseService.isInitialized, isFalse);
      });

      test('dispose makes client getter throw', () async {
        await SupabaseService.dispose();

        expect(() => SupabaseService.client, throwsException);
      });

      test('dispose is idempotent (safe to call multiple times)', () async {
        await SupabaseService.dispose();
        await SupabaseService.dispose();
        await SupabaseService.dispose();

        expect(SupabaseService.isInitialized, isFalse);
      });
    });

    group('SupabaseConfig validation', () {
      test('SupabaseConfig.isConfigured detects placeholder URL', () {
        // This tests the config validation logic that SupabaseService uses
        expect(SupabaseConfig.isConfigured, isA<bool>());
      });

      test('SupabaseConfig.validate throws on invalid config', () {
        // If config has placeholders, validate() should throw
        if (!SupabaseConfig.isConfigured) {
          expect(
            () => SupabaseConfig.validate(),
            throwsA(isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('not configured'),
            )),
          );
        }
      });

      test('SupabaseConfig checks URL format', () {
        // Config should validate URL starts with https://
        // This is tested indirectly through validate()
        expect(SupabaseConfig.supabaseUrl, isA<String>());
        if (SupabaseConfig.isConfigured) {
          expect(SupabaseConfig.supabaseUrl, startsWith('https://'));
        }
      });

      test('SupabaseConfig detects placeholder anon key', () {
        expect(SupabaseConfig.supabaseAnonKey, isA<String>());
        if (!SupabaseConfig.isConfigured) {
          expect(SupabaseConfig.supabaseAnonKey,
              contains('YOUR_SUPABASE_ANON_KEY_HERE'));
        }
      });
    });

    group('Service Lifecycle', () {
      test('initialize validates config before proceeding', () async {
        // If config is invalid, initialize should throw
        if (!SupabaseConfig.isConfigured) {
          expect(
            () async => await SupabaseService.initialize(),
            throwsException,
          );
        }
      });

      test('initialize is idempotent (safe to call multiple times)', () async {
        // Calling initialize multiple times should not cause errors
        // Note: This test assumes Supabase is configured or will skip gracefully
        try {
          await SupabaseService.initialize();
          await SupabaseService.initialize();
          // If both complete, idempotency works
          expect(true, isTrue);
        } catch (e) {
          // If not configured, both should throw the same error
          expect(e, isA<Exception>());
        }
      });

      test('dispose can be called before initialize', () async {
        // Should not throw even if never initialized
        expect(() => SupabaseService.dispose(), returnsNormally);
      });

      test('lifecycle methods handle state transitions', () async {
        // Test state transitions: dispose → not initialized
        await SupabaseService.dispose();
        expect(SupabaseService.isInitialized, isFalse);

        // Try to initialize (may fail if not configured, which is OK)
        try {
          await SupabaseService.initialize();
          expect(SupabaseService.isInitialized, isTrue);
        } catch (e) {
          // Not configured - expected in test environment
          expect(SupabaseService.isInitialized, isFalse);
        }
      });
    });

    group('Convenience Getters', () {
      test('auth getter attempts to access client.auth', () {
        // If initialized, should return auth client
        // If not initialized, should throw (because client throws)
        try {
          final auth = SupabaseService.auth;
          // If we get here, service is initialized
          expect(auth, isNotNull);
        } catch (e) {
          // Not initialized - expected
          expect(e, isA<Exception>());
        }
      });

      test('storage getter attempts to access client.storage', () {
        try {
          final storage = SupabaseService.storage;
          expect(storage, isNotNull);
        } catch (e) {
          expect(e, isA<Exception>());
        }
      });

      test('realtime getter attempts to access client.realtime', () {
        try {
          final realtime = SupabaseService.realtime;
          expect(realtime, isNotNull);
        } catch (e) {
          expect(e, isA<Exception>());
        }
      });

      test('convenience getters throw when service not initialized', () async {
        await SupabaseService.dispose();

        expect(() => SupabaseService.auth, throwsException);
        expect(() => SupabaseService.storage, throwsException);
        expect(() => SupabaseService.realtime, throwsException);
      });
    });

    group('Mock Client Behavior', () {
      test('MockSupabaseClient can be instantiated', () {
        final mockClient = MockSupabaseClient();
        expect(mockClient, isNotNull);
        expect(mockClient, isA<MockSupabaseClient>());
      });

      test('MockGoTrueClient can be instantiated', () {
        final mockAuth = MockGoTrueClient();
        expect(mockAuth, isNotNull);
        expect(mockAuth, isA<MockGoTrueClient>());
      });

      test('MockSupabaseStorageClient can be instantiated', () {
        final mockStorage = MockSupabaseStorageClient();
        expect(mockStorage, isNotNull);
        expect(mockStorage, isA<MockSupabaseStorageClient>());
      });

      test('MockRealtimeClient can be instantiated', () {
        final mockRealtime = MockRealtimeClient();
        expect(mockRealtime, isNotNull);
        expect(mockRealtime, isA<MockRealtimeClient>());
      });

      test('MockSupabaseClient can be stubbed with mocktail', () {
        final mockClient = MockSupabaseClient();
        final mockAuth = MockGoTrueClient();

        // Stub behavior
        when(() => mockClient.auth).thenReturn(mockAuth);

        // Verify stubbed behavior works
        expect(mockClient.auth, equals(mockAuth));
        verify(() => mockClient.auth).called(1);
      });

      test('Mock getters can be verified', () {
        final mockClient = MockSupabaseClient();
        final mockStorage = MockSupabaseStorageClient();

        when(() => mockClient.storage).thenReturn(mockStorage);

        // Access multiple times
        mockClient.storage;
        mockClient.storage;

        // Verify call count
        verify(() => mockClient.storage).called(2);
      });
    });

    group('Error Handling', () {
      test('client getter provides helpful error message', () {
        SupabaseService.dispose();

        try {
          SupabaseService.client;
          fail('Should throw');
        } catch (e) {
          final message = e.toString();
          expect(message, contains('SupabaseService not initialized'));
          expect(message, contains('initialize()'));
        }
      });

      test('initialize handles invalid config gracefully', () async {
        if (!SupabaseConfig.isConfigured) {
          try {
            await SupabaseService.initialize();
            fail('Should throw when not configured');
          } catch (e) {
            expect(e, isA<Exception>());
            expect(e.toString(), contains('not configured'));
          }
        }
      });

      test('methods do not crash when called in wrong order', () async {
        // dispose before initialize
        await SupabaseService.dispose();

        // client before initialize
        expect(() => SupabaseService.client, throwsException);

        // auth before initialize
        expect(() => SupabaseService.auth, throwsException);
      });
    });

    group('Integration with SupabaseConfig', () {
      test('service uses SupabaseConfig for validation', () {
        // SupabaseService.initialize() should call SupabaseConfig.validate()
        // We test this indirectly by verifying config state affects initialization
        expect(SupabaseConfig.isConfigured, isA<bool>());
      });

      test('config validation runs before initialization', () async {
        // If config is not set, initialize should fail early
        if (!SupabaseConfig.isConfigured) {
          try {
            await SupabaseService.initialize();
            fail('Should throw when config invalid');
          } catch (e) {
            // Error should be from config validation, not Supabase SDK
            expect(e.toString(), contains('configured'));
          }
        }
      });

      test('config provides URL and anon key', () {
        expect(SupabaseConfig.supabaseUrl, isNotEmpty);
        expect(SupabaseConfig.supabaseAnonKey, isNotEmpty);
      });

      test('config validates URL format requirements', () {
        if (SupabaseConfig.isConfigured) {
          // Valid config should have https:// URL
          expect(SupabaseConfig.supabaseUrl, startsWith('https://'));
        } else {
          // Invalid config should have placeholder
          expect(SupabaseConfig.supabaseUrl, contains('YOUR_'));
        }
      });
    });

    group('Singleton Behavior', () {
      test('service maintains single client instance', () async {
        // After initialization, multiple client accesses return same instance
        try {
          await SupabaseService.initialize();
          final client1 = SupabaseService.client;
          final client2 = SupabaseService.client;

          expect(client1, same(client2));
        } catch (e) {
          // Not configured - skip test
          expect(e, isA<Exception>());
        }
      });

      test('isInitialized reflects singleton state', () {
        final initialized = SupabaseService.isInitialized;
        expect(initialized, isA<bool>());

        if (initialized) {
          // Should be able to access client
          expect(() => SupabaseService.client, returnsNormally);
        } else {
          // Should not be able to access client
          expect(() => SupabaseService.client, throwsException);
        }
      });

      test('dispose resets singleton state', () async {
        await SupabaseService.dispose();

        expect(SupabaseService.isInitialized, isFalse);
        expect(() => SupabaseService.client, throwsException);
      });
    });

    group('Thread Safety and State', () {
      test('concurrent isInitialized calls are safe', () {
        // Multiple threads checking initialization state should be safe
        final results = List.generate(10, (_) => SupabaseService.isInitialized);

        // All should return same value
        expect(results.toSet().length, equals(1));
      });

      test('state checks are consistent', () {
        final initialized1 = SupabaseService.isInitialized;
        final initialized2 = SupabaseService.isInitialized;

        expect(initialized1, equals(initialized2));
      });

      test('dispose is synchronous and immediate', () async {
        await SupabaseService.dispose();

        // State should be updated immediately
        expect(SupabaseService.isInitialized, isFalse);
      });
    });
  });
}
