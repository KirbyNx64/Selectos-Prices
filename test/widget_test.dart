import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:super_selectos/main.dart';

void main() {
  testWidgets('Renders M3E search bar and welcome banner', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.byType(M3ESearchBar), findsOneWidget);
    expect(find.text('¿Qué estás buscando?'), findsOneWidget);
  });

  testWidgets('Tapping search bar does not throw MaterialLocalizations error', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    final searchBar = find.byType(M3ESearchBar);
    await tester.tap(searchBar);
    await tester.pumpAndSettle();
    expect(searchBar, findsOneWidget);
  });

  testWidgets('Selecting text in search bar does not throw MaterialLocalizations error', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    final searchBar = find.byType(M3ESearchBar);
    await tester.enterText(searchBar, 'leche');
    await tester.pumpAndSettle();

    await tester.longPress(searchBar);
    await tester.pumpAndSettle();

    expect(find.byType(M3ESearchBar), findsOneWidget);
  });
}
