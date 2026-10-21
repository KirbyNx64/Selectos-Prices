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

  testWidgets('QR action becomes search action when text is entered', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    final searchBar = find.byType(M3ESearchBar);
    final qrAction = find.widgetWithIcon(
      M3EIconButton,
      Icons.qr_code_scanner_rounded,
    );
    expect(qrAction, findsOneWidget);

    await tester.enterText(searchBar, 'leche');
    await tester.pump();

    expect(qrAction, findsNothing);
    final searchAction = find.widgetWithIcon(
      M3EIconButton,
      Icons.search_rounded,
    );
    expect(searchAction, findsOneWidget);

    await tester.tap(searchAction);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(SearchResultsScreen), findsOneWidget);
  });

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

  testWidgets('Navigation sections preserve their scroll position', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    final navigationBar = find.byType(M3ENavigationBar);
    await tester.tap(
      find.descendant(of: navigationBar, matching: find.text('Categorías')),
    );
    await tester.pumpAndSettle();

    final categoriesGrid = find.byType(GridView);
    await tester.drag(categoriesGrid, const Offset(0, -300));
    await tester.pumpAndSettle();
    final scrollOffset = tester
        .state<ScrollableState>(
          find.descendant(
            of: categoriesGrid,
            matching: find.byType(Scrollable),
          ),
        )
        .position
        .pixels;
    expect(scrollOffset, greaterThan(0));

    await tester.tap(
      find.descendant(of: navigationBar, matching: find.text('Inicio')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: navigationBar, matching: find.text('Categorías')),
    );
    await tester.pumpAndSettle();

    final restoredOffset = tester
        .state<ScrollableState>(
          find.descendant(
            of: find.byType(GridView),
            matching: find.byType(Scrollable),
          ),
        )
        .position
        .pixels;
    expect(restoredOffset, closeTo(scrollOffset, 0.01));
  });

  testWidgets('Tapping the active navigation section scrolls it to the top', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    final navigationBar = find.byType(M3ENavigationBar);
    final categoriesDestination = find.descendant(
      of: navigationBar,
      matching: find.text('Categorías'),
    );
    await tester.tap(categoriesDestination);
    await tester.pumpAndSettle();

    final categoriesGrid = find.byType(GridView);
    await tester.drag(categoriesGrid, const Offset(0, -300));
    await tester.pumpAndSettle();

    final scrollable = find.descendant(
      of: categoriesGrid,
      matching: find.byType(Scrollable),
    );
    expect(
      tester.state<ScrollableState>(scrollable).position.pixels,
      greaterThan(0),
    );

    await tester.tap(categoriesDestination);
    await tester.pumpAndSettle();

    expect(tester.state<ScrollableState>(scrollable).position.pixels, 0);
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

  testWidgets('Results QR action becomes search action when text is entered', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: SearchResultsScreen(initialQuery: '')),
    );
    await tester.pumpAndSettle();

    final searchBar = find.byType(M3ESearchBar);
    final qrAction = find.widgetWithIcon(
      M3EIconButton,
      Icons.qr_code_scanner_rounded,
    );
    expect(qrAction, findsOneWidget);

    await tester.enterText(searchBar, 'arroz');
    await tester.pump();

    expect(qrAction, findsNothing);
    expect(
      find.widgetWithIcon(M3EIconButton, Icons.search_rounded),
      findsOneWidget,
    );
  });
}
