import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/core/constants/widget_keys.dart';
import 'package:my_first_app/presentation/widgets/home_sections.dart';
import '../helpers/widget_test_helpers.dart';

void main() {
  group('PopularCategoriesSection Widget Tests', () {
    final testCategories = [
      {
        'key': 'electronics',
        'name': 'Electronics',
        'icon': Icons.devices,
      },
      {
        'key': 'clothing',
        'name': 'Clothing',
        'icon': Icons.checkroom,
      },
      {
        'key': 'accessories',
        'name': 'Accessories',
        'icon': Icons.watch,
      },
    ];

    testWidgets('renders section title', (tester) async {
      await pumpApp(
        tester,
        PopularCategoriesSection(
          categories: testCategories,
          onCategoryTap: (key, name) => () {},
        ),
      );

      // Section title should be localized
      expect(find.text('Categories'), findsOneWidget);
      expect(find.byKey(WidgetKeys.popularCategoriesSection), findsOneWidget);
    });

    testWidgets('renders correct number of category items', (tester) async {
      await pumpApp(
        tester,
        PopularCategoriesSection(
          categories: testCategories,
          onCategoryTap: (key, name) => () {},
        ),
      );

      // Should render 3 category items
      expect(find.byKey(WidgetKeys.categoryItem('electronics')), findsOneWidget);
      expect(find.byKey(WidgetKeys.categoryItem('clothing')), findsOneWidget);
      expect(find.byKey(WidgetKeys.categoryItem('accessories')), findsOneWidget);
    });

    testWidgets('category item displays correct icon', (tester) async {
      await pumpApp(
        tester,
        PopularCategoriesSection(
          categories: testCategories,
          onCategoryTap: (key, name) => () {},
        ),
      );

      // Find icon within the electronics category item
      final electronicsItem = find.byKey(WidgetKeys.categoryItem('electronics'));
      expect(electronicsItem, findsOneWidget);

      // Verify icon is present (Icons.devices)
      final iconFinder = find.descendant(
        of: electronicsItem,
        matching: find.byIcon(Icons.devices),
      );
      expect(iconFinder, findsOneWidget);
    });

    testWidgets('category item displays correct name', (tester) async {
      await pumpApp(
        tester,
        PopularCategoriesSection(
          categories: testCategories,
          onCategoryTap: (key, name) => () {},
        ),
      );

      expect(find.text('Electronics'), findsOneWidget);
      expect(find.text('Clothing'), findsOneWidget);
      expect(find.text('Accessories'), findsOneWidget);
    });

    testWidgets('category tap triggers callback with correct parameters', (tester) async {
      String? tappedKey;
      String? tappedName;

      await pumpApp(
        tester,
        PopularCategoriesSection(
          categories: testCategories,
          onCategoryTap: (key, name) {
            return () {
              tappedKey = key;
              tappedName = name;
            };
          },
        ),
      );

      await tester.tap(find.byKey(WidgetKeys.categoryItem('electronics')));
      await tester.pumpAndSettle();

      expect(tappedKey, equals('electronics'));
      expect(tappedName, equals('Electronics'));
    });

    testWidgets('tapping different categories triggers correct callbacks', (tester) async {
      String? tappedKey;
      String? tappedName;

      await pumpApp(
        tester,
        PopularCategoriesSection(
          categories: testCategories,
          onCategoryTap: (key, name) {
            return () {
              tappedKey = key;
              tappedName = name;
            };
          },
        ),
      );

      // Tap clothing category
      await tester.tap(find.byKey(WidgetKeys.categoryItem('clothing')));
      await tester.pumpAndSettle();

      expect(tappedKey, equals('clothing'));
      expect(tappedName, equals('Clothing'));

      // Tap accessories category
      await tester.tap(find.byKey(WidgetKeys.categoryItem('accessories')));
      await tester.pumpAndSettle();

      expect(tappedKey, equals('accessories'));
      expect(tappedName, equals('Accessories'));
    });

    testWidgets('section has horizontal scrollable list', (tester) async {
      await pumpApp(
        tester,
        PopularCategoriesSection(
          categories: testCategories,
          onCategoryTap: (key, name) => () {},
        ),
      );

      expect(find.byKey(WidgetKeys.popularCategoriesList), findsOneWidget);

      final listView = tester.widget<ListView>(
        find.byKey(WidgetKeys.popularCategoriesList),
      );
      expect(listView.scrollDirection, equals(Axis.horizontal));
    });

    testWidgets('localizes section title for Spanish locale', (tester) async {
      await pumpApp(
        tester,
        PopularCategoriesSection(
          categories: testCategories,
          onCategoryTap: (key, name) => () {},
        ),
        locale: const Locale('es'),
      );

      // Spanish localization for "Categories"
      expect(find.text('Categorías'), findsOneWidget);
    });

    testWidgets('renders empty list when categories is empty', (tester) async {
      await pumpApp(
        tester,
        PopularCategoriesSection(
          categories: [],
          onCategoryTap: (key, name) => () {},
        ),
      );

      // Section should still render with title
      expect(find.byKey(WidgetKeys.popularCategoriesSection), findsOneWidget);
      expect(find.text('Categories'), findsOneWidget);

      // List should be present but empty
      expect(find.byKey(WidgetKeys.popularCategoriesList), findsOneWidget);

      // No category items should be present
      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('handles single category', (tester) async {
      final singleCategory = [
        {
          'key': 'electronics',
          'name': 'Electronics',
          'icon': Icons.devices,
        },
      ];

      await pumpApp(
        tester,
        PopularCategoriesSection(
          categories: singleCategory,
          onCategoryTap: (key, name) => () {},
        ),
      );

      expect(find.byKey(WidgetKeys.categoryItem('electronics')), findsOneWidget);
      expect(find.text('Electronics'), findsOneWidget);
    });

    testWidgets('handles many categories', (tester) async {
      final manyCategories = List.generate(
        10,
        (index) => {
          'key': 'category_$index',
          'name': 'Category $index',
          'icon': Icons.category,
        },
      );

      await pumpApp(
        tester,
        PopularCategoriesSection(
          categories: manyCategories,
          onCategoryTap: (key, name) => () {},
        ),
      );

      // Verify first few categories are rendered (visible without scrolling)
      expect(find.byKey(WidgetKeys.categoryItem('category_0')), findsOneWidget);
      expect(find.byKey(WidgetKeys.categoryItem('category_1')), findsOneWidget);
      expect(find.byKey(WidgetKeys.categoryItem('category_2')), findsOneWidget);

      // Scroll to reveal categories that are off-screen
      await tester.drag(
        find.byKey(WidgetKeys.popularCategoriesList),
        const Offset(-500, 0),
      );
      await tester.pumpAndSettle();

      // Now last category should be visible
      expect(find.byKey(WidgetKeys.categoryItem('category_9')), findsOneWidget);
    });
  });
}
