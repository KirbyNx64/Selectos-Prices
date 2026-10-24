import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:super_selectos/models/shopping_list.dart';

void main() {
  group('ShoppingList model tests', () {
    test('displayName returns name when provided', () {
      final list = ShoppingList(
        id: 1,
        name: 'Despensa del mes',
        createdAt: DateTime(2026, 10, 18, 14, 30),
      );

      expect(list.name, 'Despensa del mes');
      expect(list.displayName, 'Despensa del mes');
      expect(list.dateTimeLabel, '18/10/2026 · 14:30');
    });

    test('displayName trims whitespace in name', () {
      final list = ShoppingList(
        id: 2,
        name: '   Supermercado Semanal   ',
        createdAt: DateTime(2026, 10, 18, 9, 15),
      );

      expect(list.displayName, 'Supermercado Semanal');
    });

    test(
      'displayName falls back to Lista de compras when name is null or empty',
      () {
        final listNull = ShoppingList(
          id: 3,
          name: null,
          createdAt: DateTime(2026, 10, 18, 10, 0),
        );
        final listEmpty = ShoppingList(
          id: 4,
          name: '   ',
          createdAt: DateTime(2026, 10, 18, 10, 0),
        );

        expect(listNull.displayName, 'Lista de compras');
        expect(listEmpty.displayName, 'Lista de compras');
      },
    );

    test('fromMap parses name correctly when present and when null', () {
      final fromMapWithName = ShoppingList.fromMap({
        'id': 10,
        'name': 'Parrillada',
        'created_at': DateTime(2026, 10, 18, 18, 0).millisecondsSinceEpoch,
      });
      final fromMapWithoutName = ShoppingList.fromMap({
        'id': 11,
        'name': null,
        'created_at': DateTime(2026, 10, 18, 18, 0).millisecondsSinceEpoch,
      });

      expect(fromMapWithName.name, 'Parrillada');
      expect(fromMapWithName.displayName, 'Parrillada');
      expect(fromMapWithoutName.name, isNull);
      expect(fromMapWithoutName.displayName, 'Lista de compras');
    });

    test('fromMap restores the saved product sort order', () {
      final list = ShoppingList.fromMap({
        'id': 12,
        'name': 'Compras',
        'created_at': DateTime(2026, 10, 18).millisecondsSinceEpoch,
        'sort_order': 'priceDescending',
      });

      expect(list.sortOrder, ShoppingListSortOrder.priceDescending);
    });

    test('old lists use alphabetical order by default', () {
      final list = ShoppingList.fromMap({
        'id': 13,
        'name': null,
        'created_at': DateTime(2026, 10, 18).millisecondsSinceEpoch,
      });

      expect(list.sortOrder, ShoppingListSortOrder.nameAscending);
    });
  });

  group('Tus listas menu UI widget tests', () {
    testWidgets('renders list name as label and date/time as supportingText', (
      tester,
    ) async {
      final sampleList = ShoppingList(
        id: 1,
        name: 'Fiesta de Cumpleaños',
        createdAt: DateTime(2026, 10, 18, 15, 45),
      );

      await tester.pumpWidget(
        M3ETheme(
          data: M3EThemeData.light(seedColor: const Color(0xFF2E6C37)),
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: M3EMenu(
                  position: M3EMenuAnchorPosition.bottomEnd,
                  selectedValue: sampleList.id,
                  onSelected: (_) {},
                  anchorBuilder: (context, openMenu) => ElevatedButton(
                    onPressed: openMenu,
                    child: const Text('Abrir menú'),
                  ),
                  children: [
                    M3EMenuGroup(
                      label: 'Tus listas',
                      children: [
                        M3EMenuSelectable(
                          label: sampleList.displayName,
                          supportingText: sampleList.dateTimeLabel,
                          value: sampleList.id,
                          selected: true,
                          leading: const Icon(Icons.shopping_bag_outlined),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir menú'));
      await tester.pumpAndSettle();

      expect(find.text('Fiesta de Cumpleaños'), findsOneWidget);
      expect(find.text('18/10/2026 · 15:45'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
