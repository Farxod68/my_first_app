import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/presentation/providers/base_persistent_provider.dart';

/// Test implementation of PersistentProviderMixin for testing
class TestProvider with ChangeNotifier, PersistentProviderMixin {
  int loadCallCount = 0;

  Future<void> loadData() async {
    loadCallCount++;
    // Simulate async load
    await Future.delayed(Duration.zero);
    markAsLoaded();
  }
}

void main() {
  group('PersistentProviderMixin', () {
    late TestProvider provider;

    setUp(() {
      provider = TestProvider();
    });

    tearDown(() {
      // Some tests may dispose the provider themselves
      // Ignore errors from double dispose
      try {
        provider.dispose();
      } catch (_) {
        // Already disposed
      }
    });

    group('Initial State', () {
      test('isLoaded is false by default', () {
        expect(provider.isLoaded, isFalse);
      });

      test('initial state does not trigger listeners', () {
        var listenerCallCount = 0;
        provider.addListener(() => listenerCallCount++);

        // Initial state should not notify
        expect(listenerCallCount, equals(0));
      });
    });

    group('markAsLoaded', () {
      test('sets isLoaded to true', () async {
        expect(provider.isLoaded, isFalse);

        await provider.loadData();

        expect(provider.isLoaded, isTrue);
      });

      test('notifies listeners when called', () async {
        var listenerCallCount = 0;
        provider.addListener(() => listenerCallCount++);

        await provider.loadData();

        expect(listenerCallCount, equals(1));
      });

      test('is idempotent (safe to call multiple times)', () async {
        var listenerCallCount = 0;
        provider.addListener(() => listenerCallCount++);

        await provider.loadData();
        await provider.loadData();
        await provider.loadData();

        expect(provider.isLoaded, isTrue);
        // Each call notifies (by design)
        expect(listenerCallCount, equals(3));
      });

      test('maintains loaded state across multiple calls', () async {
        await provider.loadData();
        expect(provider.isLoaded, isTrue);

        await provider.loadData();
        expect(provider.isLoaded, isTrue);

        await provider.loadData();
        expect(provider.isLoaded, isTrue);
      });
    });

    group('Integration', () {
      test('typical load pattern works correctly', () async {
        var listenerCallCount = 0;
        provider.addListener(() => listenerCallCount++);

        expect(provider.isLoaded, isFalse);

        // Load data using provider's method
        await provider.loadData();

        expect(provider.isLoaded, isTrue);
        expect(listenerCallCount, equals(1));
      });

      test('load method can be called by provider implementation', () async {
        expect(provider.loadCallCount, equals(0));

        await provider.loadData();

        expect(provider.loadCallCount, equals(1));
        expect(provider.isLoaded, isTrue);
      });

      test('multiple providers have independent state', () async {
        final provider2 = TestProvider();

        await provider.loadData();

        expect(provider.isLoaded, isTrue);
        expect(provider2.isLoaded, isFalse);

        provider2.dispose();
      });
    });

    group('Listener Notifications', () {
      test('loadData triggers single notification', () async {
        var listenerCallCount = 0;
        provider.addListener(() => listenerCallCount++);

        await provider.loadData();

        expect(listenerCallCount, equals(1));
      });

      test('multiple listeners all receive notification', () async {
        var listener1CallCount = 0;
        var listener2CallCount = 0;
        var listener3CallCount = 0;

        provider.addListener(() => listener1CallCount++);
        provider.addListener(() => listener2CallCount++);
        provider.addListener(() => listener3CallCount++);

        await provider.loadData();

        expect(listener1CallCount, equals(1));
        expect(listener2CallCount, equals(1));
        expect(listener3CallCount, equals(1));
      });

      test('removed listener does not receive notification', () async {
        var removedListenerCallCount = 0;
        var activeListenerCallCount = 0;

        void removedListener() => removedListenerCallCount++;
        void activeListener() => activeListenerCallCount++;

        provider.addListener(removedListener);
        provider.addListener(activeListener);

        provider.removeListener(removedListener);
        await provider.loadData();

        expect(removedListenerCallCount, equals(0));
        expect(activeListenerCallCount, equals(1));
      });
    });

    group('Edge Cases', () {
      test('loadData works before any listeners added', () async {
        expect(() async => await provider.loadData(), returnsNormally);
        await provider.loadData();
        expect(provider.isLoaded, isTrue);
      });

      test('loadData works after all listeners removed', () async {
        void listener() {}
        provider.addListener(listener);
        provider.removeListener(listener);

        await provider.loadData();
        expect(provider.isLoaded, isTrue);
      });

      test('can be disposed after markAsLoaded', () async {
        await provider.loadData();
        expect(provider.isLoaded, isTrue);

        // Should not throw when disposing after loaded
        expect(() => provider.dispose(), returnsNormally);
      });
    });
  });
}
