# TopBuy Deals - Test Suite

This directory contains the test suite for the TopBuy Deals Flutter application.

## Test Structure

```
test/
├── unit/               # Unit tests (services, providers, repositories, models)
├── widget/             # Widget tests (UI components, screens)
├── integration/        # Integration tests (end-to-end user flows)
├── helpers/            # Test utilities and helper functions
├── mocks/              # Mock implementations for external dependencies
├── widget_test.dart    # App smoke test
└── README.md           # This file
```

## Test Categories

### Unit Tests (`test/unit/`)
Tests for individual units of code in isolation (functions, classes, methods).

**Coverage target**: 95%+ for business logic

**Planned coverage**:
- Core services: `PersistenceService`, `SupabaseService`
- State providers: `CartProvider`, `WishlistProvider`, `AuthProvider`, `LocaleProvider`, `CurrencyProvider`, `SearchProvider`, `RecentlyViewedProvider`
- Repositories: `AuthRepository`
- Data sources: `AuthDataSource`
- Models: JSON serialization, validation
- Utilities: Formatters, validators, helpers

### Widget Tests (`test/widget/`)
Tests for UI components and their interactions with state.

**Coverage target**: 75%+ for UI layer

**Planned coverage**:
- Reusable components: `ProductCard`, `DealCard`
- Complex widgets: `SearchDelegate`, `HomeSections`
- Full screens: `HomePage`, `ProductDetailsPage`, `CartPage`, `AuthPage`, `ProfileEditPage`
- User interactions: tap, scroll, input
- State updates: provider changes trigger UI updates

### Integration Tests (`test/integration/`)
Tests for complete user flows across multiple screens and services.

**Coverage target**: Critical paths only

**Planned coverage**:
- Shopping flow: browse → add to cart → checkout
- Auth flow: sign up → sign in → update profile → sign out
- Search flow: search → view results → view product
- Preferences flow: change language → restart app → verify persisted

## Running Tests

### Run all tests
```bash
flutter test
```

### Run specific test file
```bash
flutter test test/unit/core/services/persistence_service_test.dart
```

### Run tests by directory
```bash
flutter test test/unit/
flutter test test/widget/
flutter test test/integration/
```

### Run tests with coverage
```bash
flutter test --coverage
```

### View coverage report (HTML)
```bash
# Generate HTML report (requires lcov)
genhtml coverage/lcov.info -o coverage/html

# Open in browser
open coverage/html/index.html  # macOS
start coverage/html/index.html # Windows
```

## Test Infrastructure (Planned)

### Test Helpers (`test/helpers/`)
Common utilities to reduce test boilerplate:
- Mock SharedPreferences setup
- Widget test wrappers with providers
- Widget test wrappers with full app context (localization, theme)
- Finder convenience methods
- Interaction helpers (tap, input, wait for animations)

### Mocks (`test/mocks/`)
Mock implementations for external dependencies:
- `MockPersistenceService` - Mock SharedPreferences wrapper
- `MockSupabaseClient` - Mock Supabase backend
- `MockGoTrueClient` - Mock Supabase Auth
- Other Supabase mocks (Storage, Realtime, Postgrest)

## Testing Approach

### General Principles
- Test behavior, not implementation
- Use descriptive test names
- Follow AAA pattern: Arrange, Act, Assert
- One logical assertion per test
- Use mocks to isolate units under test
- Clean up resources in tearDown()

### Unit Tests
- Test success paths first
- Test error handling and edge cases
- Test null safety and boundary conditions
- Mock external dependencies (SharedPreferences, Supabase)
- Verify method calls on mocks
- Test async operations with async/await

### Widget Tests
- Use widget keys for reliable element finding
- Test user interactions (tap, scroll, input)
- Test state changes trigger UI updates
- Use pumpAndSettle() to wait for animations
- Mock providers to control widget state
- Test responsive layouts (mobile, desktop)

### Integration Tests
- Test critical user journeys end-to-end
- Use real providers when possible
- Test navigation between screens
- Test data persistence across app restarts
- Keep integration tests focused and fast
- Use widget keys for navigation verification

## Coverage Goals

**Overall target**: 80%+

**By layer**:
- Core services: 100%
- Providers: 95%+
- Repositories: 95%+
- Data sources: 90%+
- UI/Widgets: 75%+
- Models: 85%+
- Utilities: 85%+

## Development Workflow

### When adding new features
1. Write tests alongside implementation (or TDD)
2. Aim for 80%+ coverage for new code
3. Run full test suite before committing: `flutter test`
4. Verify no analyzer issues: `flutter analyze`

### When fixing bugs
1. Write a failing test that reproduces the bug
2. Fix the bug
3. Verify test passes
4. Ensure no regressions in existing tests

## Dependencies

### Current testing packages
- `flutter_test` - Flutter testing framework (SDK)

### Planned testing packages
- Mocking library (to be added when writing unit tests)

## Troubleshooting

### SharedPreferences errors in tests
**Problem**: `MissingPluginException` when using SharedPreferences in tests.

**Solution**: Use `SharedPreferences.setMockInitialValues({})` in `setUp()`:
```dart
setUp(() {
  SharedPreferences.setMockInitialValues({});
});
```

### Widget not found in tests
**Problem**: `find.text('Widget')` returns nothing.

**Solution**: 
- Add widget keys to production code
- Use `find.byKey()` instead of `find.text()`
- Call `await tester.pumpAndSettle()` to wait for animations

### Async test timeout
**Problem**: Test hangs and times out.

**Solution**:
- Await all async operations
- Use `await tester.pumpAndSettle()` for widgets
- Mock async dependencies to return immediately

## Resources

- [Flutter Testing Guide](https://docs.flutter.dev/testing)
- [Test-Driven Development](https://en.wikipedia.org/wiki/Test-driven_development)
- [Flutter Widget Testing](https://docs.flutter.dev/cookbook/testing/widget/introduction)
- [Flutter Unit Testing](https://docs.flutter.dev/cookbook/testing/unit/introduction)

## Status

**Phase 2 Progress**:
- ✅ Task 2.1: Test Infrastructure & Setup (directory structure, documentation)
- ⏳ Task 2.2: Unit Tests - Core Services
- ⏳ Task 2.3: Unit Tests - State Management Providers
- ⏳ Task 2.4: Unit Tests - Authentication Flow
- ⏳ Task 2.5: Add Widget Keys for Testability
- ⏳ Task 2.6: Widget Tests - Reusable Components
- ⏳ Task 2.7: Widget Tests - Key User Flows
- ⏳ Task 2.8: Integration Tests - Critical Paths
- ⏳ Task 2.9: Test Coverage Analysis & Report
- ⏳ Task 2.10: Fix Test Gaps & Achieve 80% Coverage
