import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:super_selectos/models/category.dart';
import 'package:super_selectos/screens/categories/subcategories_screen.dart';

void main() {
  const testCategory = MainCategory(
    id: '06',
    nombre: 'Cuidado\nmascotas',
    tituloCompleto: 'Cuidado mascotas',
    icon: Icons.pets_rounded,
    grupos: [
      CategoryGroup(
        id: '061',
        nombre: 'Alimento para perros',
        subcategorias: [
          SubcategoryItem(
            id: '06101',
            nombre: 'Alimento seco para perros adultos',
          ),
          SubcategoryItem(
            id: '06102',
            nombre: 'Alimento húmedo para perros adultos',
          ),
        ],
      ),
      CategoryGroup(
        id: '062',
        nombre: 'Alimento para gatos',
        subcategorias: [
          SubcategoryItem(
            id: '06201',
            nombre: 'Alimento seco para gatos adultos',
          ),
        ],
      ),
    ],
  );

  testWidgets('SubcategoriesScreen renders M3E hero banner and groups', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: SubcategoriesScreen(category: testCategory)),
    );
    await tester.pumpAndSettle();

    // Verificamos el botón de regreso M3E
    expect(find.byType(M3EIconButton), findsAtLeast(1));
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);

    // Verificamos que se renderiza el título en el AppBar y en el Hero banner
    expect(find.text('Cuidado mascotas'), findsAtLeast(1));
    expect(find.text('2 grupos · 3 subcategorías'), findsOneWidget);
    expect(find.text('Ver todo en Cuidado mascotas'), findsOneWidget);

    // Verificamos los grupos
    expect(find.text('Alimento para perros'), findsOneWidget);
    expect(find.text('Alimento para gatos'), findsOneWidget);

    // Verificamos las subcategorías con targets táctiles
    expect(find.text('Alimento seco para perros adultos'), findsOneWidget);
    expect(find.text('Alimento húmedo para perros adultos'), findsOneWidget);
    expect(find.text('Alimento seco para gatos adultos'), findsOneWidget);
  });

  testWidgets('SubcategoriesScreen filters groups and subcategories by query', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: SubcategoriesScreen(category: testCategory)),
    );
    await tester.pumpAndSettle();

    // Escribimos en el buscador de subcategorías
    await tester.enterText(find.byType(EditableText).first, 'gatos');
    await tester.pumpAndSettle();

    // Solo debe verse 'Alimento para gatos' y su subcategoría
    expect(find.text('Alimento para gatos'), findsOneWidget);
    expect(find.text('Alimento seco para gatos adultos'), findsOneWidget);
    expect(find.text('Alimento seco para perros adultos'), findsNothing);
  });

  testWidgets('Android back closes the filter without leaving the screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: SubcategoriesScreen(category: testCategory)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(M3ESearchBar));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(SubcategoriesScreen), findsOneWidget);
    expect(find.text('Cuidado mascotas'), findsAtLeast(1));
  });
}
