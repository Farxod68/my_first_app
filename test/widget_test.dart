import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:my_first_app/main.dart';
import 'package:my_first_app/core/services/persistence_service.dart';
import 'package:my_first_app/presentation/providers/cart_provider.dart';
import 'package:my_first_app/presentation/providers/wishlist_provider.dart';
import 'package:my_first_app/presentation/providers/locale_provider.dart';
import 'package:my_first_app/presentation/providers/recently_viewed_provider.dart';
import 'package:my_first_app/presentation/providers/search_provider.dart';

void main() {
  testWidgets('TopBuy Deals loads successfully', (WidgetTester tester) async {
    // Setup test environment for SharedPreferences
    SharedPreferences.setMockInitialValues({});

    // Initialize persistence service
    final persistenceService = await PersistenceService.getInstance();

    // Wrap app with providers
    await tester.pumpWidget(
      MultiProvider(
        providers: [
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
            create: (_) => RecentlyViewedProvider(persistenceService),
          ),
          ChangeNotifierProvider(
            create: (_) => SearchProvider(persistenceService),
          ),
        ],
        child: const TopBuyDealsApp(),
      ),
    );

    // Wait for app to settle
    await tester.pumpAndSettle();

    // Verify app title is displayed
    expect(find.text('TopBuy Deals'), findsOneWidget);
  });
}