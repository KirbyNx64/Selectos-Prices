import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:super_selectos/main.dart';
import 'package:super_selectos/screens/searchResults/search_results_screen.dart';

void main() {
  testWidgets('Renders M3E search bar and welcome banner', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.byType(M3ESearchBar), findsOneWidget);
    expect(find.text('¿Qué estás buscando?'), findsOneWidget);
  });

  testWidgets('Tapping search bar does not throw MaterialLocalizations error', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    final searchBar = find.byType(M3ESearchBar);
    await tester.tap(searchBar);
    await tester.pumpAndSettle();
    expect(searchBar, findsOneWidget);
  });

  testWidgets('Android back closes the home search without leaving the app', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(M3ESearchBar));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(M3ESearchBar), findsOneWidget);
    expect(find.text('Selectos Prices'), findsOneWidget);
  });

  testWidgets(
    'Selecting text in search bar does not throw MaterialLocalizations error',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      final searchBar = find.byType(M3ESearchBar);
      await tester.enterText(searchBar, 'leche');
      await tester.pumpAndSettle();

      await tester.longPress(searchBar);
      await tester.pumpAndSettle();

      expect(find.byType(M3ESearchBar), findsOneWidget);
    },
  );

  testWidgets('Android back returns from a navigation section to Inicio', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    final categoriesDestination = find.descendant(
      of: find.byType(M3ENavigationBar),
      matching: find.text('Categorías'),
    );
    await tester.tap(categoriesDestination);
    await tester.pumpAndSettle();
    expect(find.byType(M3ESearchBar), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(M3ESearchBar), findsOneWidget);
  });

  testWidgets('Android back closes results search without leaving the screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: SearchResultsScreen(initialQuery: '')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(M3ESearchBar));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(SearchResultsScreen), findsOneWidget);
    expect(find.byType(M3ESearchBar), findsOneWidget);
  });
}
