import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/auth_helpers.dart';
import 'core/services/persistence_service.dart';
import 'core/services/supabase_service.dart';
import 'core/config/supabase_config.dart';
import 'data/data_sources/remote/auth_remote_data_source.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'presentation/providers/cart_provider.dart';
import 'presentation/providers/wishlist_provider.dart';
import 'presentation/providers/locale_provider.dart';
import 'presentation/providers/currency_provider.dart';
import 'presentation/providers/recently_viewed_provider.dart';
import 'presentation/providers/search_provider.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/screens/home/home_page.dart';
import 'l10n/app_localizations.dart';

void main() async {
  // Ensure Flutter is initialized before accessing native plugins
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize persistence service
  final persistenceService = await PersistenceService.getInstance();

  // Initialize Supabase (optional - app works without it)
  bool supabaseInitialized = false;
  try {
    if (SupabaseConfig.isConfigured) {
      await SupabaseService.initialize();
      supabaseInitialized = true;
      debugPrint('[SUPABASE] Initialized successfully');
    } else {
      debugPrint('[SUPABASE] Not configured - running in local-only mode');
    }
  } catch (e) {
    debugPrint('[SUPABASE] Initialization failed: $e');
    debugPrint('[SUPABASE] Continuing in local-only mode');
  }

  runApp(
    MultiProvider(
      providers: [
        // Core providers (always available)
        ChangeNotifierProvider(
          create: (_) => CartProvider(persistenceService),
        ),
        ChangeNotifierProvider(
          create: (_) => WishlistProvider(persistenceService),
        ),
        ChangeNotifierProvider(
          create: (_) => LocaleProvider(persistenceService),
        ),
        ChangeNotifierProvider(
          create: (_) => CurrencyProvider(persistenceService),
        ),
        ChangeNotifierProvider(
          create: (_) => RecentlyViewedProvider(persistenceService),
        ),
        ChangeNotifierProvider(
          create: (_) => SearchProvider(persistenceService),
        ),

        // Auth provider (conditional on Supabase)
        //
        // SAFETY CONTRACT — do not remove this `if` without reading this:
        // `AuthRemoteDataSource()` (used below via `AuthRepositoryImpl`)
        // eagerly resolves `SupabaseService.client` in its constructor
        // initializer list, and that getter throws synchronously if
        // `SupabaseService.initialize()` was never called (see
        // supabase_service.dart). Because `HomePage`'s body is an
        // `IndexedStack`, ALL FOUR tabs - including ProfileTab - build
        // eagerly on first frame, so registering this provider
        // unconditionally would throw during app launch itself whenever
        // Supabase isn't configured, not just on a guarded screen.
        //
        // Every widget that reads `AuthProvider` non-nullably
        // (`context.read/watch<AuthProvider>()`, without the `?`) — the
        // auth screens and ProfileEditPage — is therefore only safe to
        // reach through navigation gated behind a NULLABLE lookup first,
        // e.g. `final hasAuthProvider = context.watch<AuthProvider?>() !=
        // null;` as ProfileTab does before ever linking to them. If you
        // add a new way to reach LoginPage/SignUpPage/ForgotPasswordPage/
        // ProfileEditPage, gate it the same way.
        if (supabaseInitialized)
          ChangeNotifierProvider(
            create: (_) => AuthProvider(
              AuthRepositoryImpl(
                AuthRemoteDataSource(),
              ),
            ),
          ),
      ],
      child: const TopBuyDealsApp(),
    ),
  );
}

class TopBuyDealsApp extends StatefulWidget {
  const TopBuyDealsApp({super.key});

  @override
  State<TopBuyDealsApp> createState() => _TopBuyDealsAppState();
}

class _TopBuyDealsAppState extends State<TopBuyDealsApp> {
  @override
  void initState() {
    super.initState();
    // Sync preferences on app start if user is authenticated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AuthHelpers.syncPreferencesFromProfile(context, logPrefix: 'PROFILE');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
          locale: localeProvider.currentLocale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: LocaleProvider.supportedLocales,
          theme: AppTheme.lightTheme,
          home: const HomePage(),
        );
      },
    );
  }
}

