import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// Widget test helpers for pumping widgets with proper setup
///
/// Provides helper functions to wrap widgets with MaterialApp,
/// localizations, and providers for testing.

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
}) async {
  await tester.pumpWidget(
    MaterialApp(
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
      providers: providers,
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
}) async {
  await tester.pumpWidget(
    MaterialApp(
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
  );
}
