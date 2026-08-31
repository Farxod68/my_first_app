import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_first_app/l10n/app_localizations.dart';
import 'package:my_first_app/presentation/providers/currency_provider.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import '../mocks/mock_persistence_service.dart';

/// Widget test helpers for pumping widgets with proper setup
///
/// Provides helper functions to wrap widgets with MaterialApp,
/// localizations, and providers for testing.
///
/// [pumpApp] and [pumpAppWithNavigation] always include a default
/// `CurrencyProvider` (USD, matching its own real default) because several
/// production widgets - `ProductCard`, `CartPage`, `CategoryPage`, etc. -
/// now read `CurrencyProvider.currentCurrency` reactively to format prices.
/// Without this, any test rendering one of those widgets through these
/// helpers would throw `ProviderNotFoundException`. Pass [providers] to add
/// more providers (e.g. a real `CurrencyProvider` with a different starting
/// currency) alongside this default.
CurrencyProvider _defaultCurrencyProvider() {
  final mockPersistence = MockPersistenceService();
  when(() => mockPersistence.getString('currency_code')).thenReturn(null);
  return CurrencyProvider(mockPersistence);
}

/// Pump a widget wrapped in MaterialApp with localizations
///
/// This is the basic wrapper for testing widgets that require
/// MaterialApp context and localization support.
///
/// Example:
/// ```dart
/// await pumpApp(tester, MyWidget());
/// ```
Future<void> pumpApp(
  WidgetTester tester,
  Widget widget, {
  Locale locale = const Locale('en'),
  ThemeMode themeMode = ThemeMode.light,
  NavigatorObserver? navigatorObserver,
  List<SingleChildWidget> providers = const [],
}) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CurrencyProvider>.value(
          value: _defaultCurrencyProvider(),
        ),
        ...providers,
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('es'),
          Locale('fr'),
          Locale('uz'),
        ],
        themeMode: themeMode,
        navigatorObservers: navigatorObserver != null ? [navigatorObserver] : [],
        home: Scaffold(body: widget),
      ),
    ),
  );
}

/// Pump a widget wrapped in MaterialApp with providers and localizations
///
/// Use this when testing widgets that depend on Provider for state management.
/// Accepts a list of providers to inject into the widget tree.
///
/// Example:
/// ```dart
/// await pumpAppWithProviders(
///   tester,
///   MyWidget(),
///   providers: [
///     ChangeNotifierProvider<MyProvider>.value(value: mockProvider),
///   ],
/// );
/// ```
Future<void> pumpAppWithProviders(
  WidgetTester tester,
  Widget widget, {
  required List<SingleChildWidget> providers,
  Locale locale = const Locale('en'),
  ThemeMode themeMode = ThemeMode.light,
  NavigatorObserver? navigatorObserver,
}) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CurrencyProvider>.value(
          value: _defaultCurrencyProvider(),
        ),
        ...providers,
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('es'),
          Locale('fr'),
          Locale('uz'),
        ],
        themeMode: themeMode,
        navigatorObservers: navigatorObserver != null ? [navigatorObserver] : [],
        home: Scaffold(body: widget),
      ),
    ),
  );
}

/// Pump a widget that needs custom navigation setup
///
/// Use this when testing navigation behavior. Widget is placed directly
/// as the home route without a Scaffold wrapper.
///
/// Example:
/// ```dart
/// await pumpAppWithNavigation(
///   tester,
///   MyPage(),
///   navigatorObserver: mockObserver,
/// );
/// ```
Future<void> pumpAppWithNavigation(
  WidgetTester tester,
  Widget widget, {
  Locale locale = const Locale('en'),
  NavigatorObserver? navigatorObserver,
  List<SingleChildWidget> providers = const [],
}) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CurrencyProvider>.value(
          value: _defaultCurrencyProvider(),
        ),
        ...providers,
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('es'),
          Locale('fr'),
          Locale('uz'),
        ],
        navigatorObservers: navigatorObserver != null ? [navigatorObserver] : [],
        home: widget,
      ),
    ),
  );
}
