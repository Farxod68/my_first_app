import 'package:mocktail/mocktail.dart';
import 'package:my_first_app/presentation/providers/wishlist_provider.dart';

/// Mock WishlistProvider for testing widgets that depend on wishlist state
///
/// Use with mocktail's when() to stub behavior and verify() to check interactions.
///
/// Example:
/// ```dart
/// final mockWishlistProvider = MockWishlistProvider();
/// when(() => mockWishlistProvider.isFavorite('product1')).thenReturn(true);
/// when(() => mockWishlistProvider.toggleFavorite(any())).thenReturn(null);
/// ```
class MockWishlistProvider extends Mock implements WishlistProvider {}
