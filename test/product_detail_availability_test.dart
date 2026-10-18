import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_view/photo_view.dart';
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

  testWidgets('abre la imagen del producto en pantalla completa', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await StoreSelectionController.instance.selectBranch(
      const SelectosBranch(
        id: '64',
        name: 'Sonsonate Los Leones',
        address: 'Sonsonate',
        zoneId: '',
      ),
    );
    final service = _UnavailableProductService();
    addTearDown(service.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: ProductDetailScreen(
          producto: const Product(
            id: 'gallery-product',
            nombre: 'Producto con imágenes',
            precio: 2,
            precioFinal: 2,
            descripcion: 'Descripción',
            imagenes: [
              'https://example.invalid/product-1.png',
              'https://example.invalid/product-2.png',
            ],
          ),
          service: service,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('product-image-0')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.byKey(const ValueKey('fullscreen-product-gallery')),
      findsOneWidget,
    );
    expect(find.byType(PhotoView), findsOneWidget);
    expect(find.text('1 de 2'), findsOneWidget);

    final viewerFinder = find.byType(PhotoView);
    final viewer = tester.widget<PhotoView>(viewerFinder);
    final scaleStateCycle = viewer.scaleStateCycle!;
    expect(
      scaleStateCycle(PhotoViewScaleState.initial),
      PhotoViewScaleState.covering,
    );
    expect(
      scaleStateCycle(PhotoViewScaleState.covering),
      PhotoViewScaleState.initial,
    );
    expect(
      scaleStateCycle(PhotoViewScaleState.originalSize),
      PhotoViewScaleState.initial,
    );

    final center = tester.getCenter(viewerFinder);
    final firstFinger = await tester.startGesture(
      center.translate(-24, 0),
      pointer: 1,
    );
    await tester.pump(const Duration(milliseconds: 50));
    final secondFinger = await tester.startGesture(
      center.translate(24, 0),
      pointer: 2,
    );
    await firstFinger.moveBy(const Offset(-70, 0));
    await secondFinger.moveBy(const Offset(70, 0));
    await tester.pump();
    await firstFinger.up();
    await secondFinger.up();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('fullscreen-product-gallery')),
      findsNothing,
    );
  });
}
