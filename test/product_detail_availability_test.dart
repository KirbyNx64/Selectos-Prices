import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_selectos/models/product.dart';
import 'package:super_selectos/models/selectos_branch.dart';
import 'package:super_selectos/screens/productDetail/product_detail_screen.dart';
import 'package:super_selectos/services/store_selection_controller.dart';
import 'package:super_selectos/services/super_selectos_service.dart';

class _UnavailableProductService extends SuperSelectosService {
  @override
  Future<bool?> comprobarDisponibilidadEnSalaSeleccionada(String productId) {
    return Future.value(false);
  }

  @override
  Future<Product?> obtenerDetalleProductoWeb(
    String productId, {
    Product? productoBase,
  }) {
    return Future.value(productoBase);
  }
}

void main() {
  testWidgets('muestra producto no disponible y bloquea agregar', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await StoreSelectionController.instance.selectBranch(
      const SelectosBranch(
        id: '64',
        name: 'Sonsonate Los Leones',
        address: 'Avenida Oidor Ramírez de Quiñonez y Paseo 15 de Septiembre, Sonsonate.',
        zoneId: 'c4bc6420-14d7-4956-8271-b41711a9d74b',
      ),
    );
    final service = _UnavailableProductService();
    addTearDown(service.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: ProductDetailScreen(
          producto: const Product(
            id: '102242',
            nombre: 'Producto no disponible',
            precio: 1.25,
            precioFinal: 1.25,
            precioOriginal: 2.00,
            descuento: 0.75,
            tieneDescuento: true,
          ),
          service: service,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No disponible en esta sala'), findsOneWidget);
    expect(find.text('Sonsonate Los Leones'), findsOneWidget);
    expect(find.text('No disponible'), findsOneWidget);
    expect(find.text('Precio regular'), findsOneWidget);
    expect(find.text('Ahorras'), findsOneWidget);
    expect(find.text(r'−$0.75'), findsOneWidget);
    expect(find.text('Total a pagar'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Ahorras')).dy,
      lessThan(tester.getTopLeft(find.text('Total a pagar')).dy),
    );
    expect(
      tester.getTopLeft(find.text('No disponible en esta sala')).dy,
      greaterThan(tester.getTopLeft(find.text(r'$1.25').first).dy),
    );
  });
}
