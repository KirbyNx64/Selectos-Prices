import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_selectos/models/product.dart';
import 'package:super_selectos/widgets/product_card.dart';

void main() {
  testWidgets('ProductCard test standard card', (WidgetTester tester) async {
    final product = Product(
      id: '1',
      nombre: 'Papel Higienico Scott Cuidado Completo 3H ...',
      precioFinal: 11.75,
      precioOriginal: 13.05,
      descuento: 1.30,
      tieneDescuento: true,
      categoria: 'Cuidado del Hogar',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 159,
              height: 274,
              child: ProductCard(product: product),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('\$11.75'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('ProductCard test narrow width and large price without overflow', (WidgetTester tester) async {
    final product = Product(
      id: '2',
      nombre: 'Producto Con Nombre Muy Largo Que Ocupa Varias Lineas',
      precioFinal: 1299.99,
      precioOriginal: 1599.99,
      descuento: 300.0,
      tieneDescuento: true,
      categoria: 'Electrodomesticos',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 140, // very narrow
              height: 274,
              child: ProductCard(product: product),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('\$1299.99'), findsOneWidget);
  });

  testWidgets('ProductCard increment and decrement work', (WidgetTester tester) async {
    final product = Product(
      id: '3',
      nombre: 'Leche Dos Pinos 1L',
      precioFinal: 1.95,
      categoria: 'Lácteos',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 160,
              height: 280,
              child: ProductCard(product: product),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget);

    // Tap increment
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('2'), findsOneWidget);

    // Tap decrement
    await tester.tap(find.byIcon(Icons.remove));
    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget);
  });
}
