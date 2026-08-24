import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_first_app/l10n/app_localizations.dart';
import 'package:my_first_app/presentation/providers/auth_provider.dart';
import 'package:my_first_app/presentation/providers/locale_provider.dart';
import 'package:my_first_app/presentation/providers/currency_provider.dart';
import 'package:provider/provider.dart';
import '../mocks/mock_auth_repository.dart';
import '../mocks/mock_persistence_service.dart';

/// Helper to pump authentication pages with all required providers
///
/// Sets up:
/// - AuthProvider with MockAuthRepository
/// - LocaleProvider with MockPersistenceService
/// - CurrencyProvider with MockPersistenceService
/// - MaterialApp with proper localization
Future<AuthTestContext> pumpAuthPage(
  WidgetTester tester,
  Widget page,
) async {
  // Set a larger viewport to avoid layout overflow issues
  tester.view.physicalSize = const Size(800, 600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final mockAuthRepository = MockAuthRepository();
  final mockPersistenceService = MockPersistenceService();

  // Default stubs for AuthRepository
  when(() => mockAuthRepository.getCurrentUser())
      .thenAnswer((_) async => null);
  when(() => mockAuthRepository.authStateChanges)
      .thenAnswer((_) => Stream.value(null));

  // Default stubs for PersistenceService
  when(() => mockPersistenceService.loadLocale()).thenReturn(null);
  when(() => mockPersistenceService.getString(any())).thenReturn(null);
  when(() => mockPersistenceService.saveLocale(any()))
      .thenAnswer((_) async => true);
  when(() => mockPersistenceService.saveString(any(), any()))
      .thenAnswer((_) async => true);

  // Create providers
  final authProvider = AuthProvider(mockAuthRepository);
  final localeProvider = LocaleProvider(mockPersistenceService);
  final currencyProvider = CurrencyProvider(mockPersistenceService);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
        ChangeNotifierProvider<CurrencyProvider>.value(
            value: currencyProvider),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
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
        home: page,
      ),
    ),
  );

  // Let providers initialize
  await tester.pumpAndSettle();

  return AuthTestContext(
    authProvider: authProvider,
    localeProvider: localeProvider,
    currencyProvider: currencyProvider,
    mockAuthRepository: mockAuthRepository,
    mockPersistenceService: mockPersistenceService,
  );
}

/// Context object returned by pumpAuthPage containing all providers and mocks
class AuthTestContext {
  final AuthProvider authProvider;
  final LocaleProvider localeProvider;
  final CurrencyProvider currencyProvider;
  final MockAuthRepository mockAuthRepository;
  final MockPersistenceService mockPersistenceService;

  AuthTestContext({
    required this.authProvider,
    required this.localeProvider,
    required this.currencyProvider,
    required this.mockAuthRepository,
    required this.mockPersistenceService,
  });
}
