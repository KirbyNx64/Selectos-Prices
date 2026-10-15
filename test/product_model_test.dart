import 'package:flutter_test/flutter_test.dart';
import 'package:super_selectos/models/product.dart';
import 'package:super_selectos/services/super_selectos_service.dart';

void main() {
  group('Product Model Tests', () {
    test('Product serialization and deserialization', () {
      final json = {
        'id': '12345',
        'nombre': 'Leche Entera 1L',
        'precio': 1.50,
        'precio_final': 1.50,
        'precio_original': 1.80,
        'descuento': 0.30,
        'tiene_descuento': true,
        'promocion': 'Oferta',
        'imagen': 'https://example.com/leche.jpg',
        'enlace': 'https://example.com/p/12345',
        'supermercado': 'Súper Selectos',
        'codigo_barra': '7411001800903',
      };

      final product = Product.fromJson(json);

      expect(product.id, '12345');
      expect(product.nombre, 'Leche Entera 1L');
      expect(product.precioFinal, 1.50);
      expect(product.precioOriginal, 1.80);
      expect(product.tieneDescuento, true);
      expect(product.descuento, 0.30);
      expect(product.codigoBarra, '7411001800903');
    });
  });

  group('BarcodeInfo Model Tests', () {
    test('BarcodeInfo serialization', () {
      final info = BarcodeInfo(
        codigo: '7501055300075',
        nombre: 'Coca-Cola',
        marca: 'Coca-Cola',
        terminoBusqueda: 'Coca-Cola',
      );

      final map = info.toJson();
      expect(map['codigo'], '7501055300075');
      expect(map['termino_busqueda'], 'Coca-Cola');
    });

    test('obtenerProductosInicio returns list of products from home page', () async {
      final service = SuperSelectosService();
      final productos = await service.obtenerProductosInicio();
      expect(productos, isA<List<Product>>());
      service.dispose();
    });

    test('buscarPorCategoria fetches products for category code 051', () async {
      final service = SuperSelectosService();
      final response = await service.buscarPorCategoria('051', categoryNombre: 'Agua');
      expect(response.productos, isA<List<Product>>());
      expect(response.terminoResuelto, 'Agua');
      expect(response.paginacion.paginaActual, 1);
      service.dispose();
    });

    test('buscarPorCategoria with page 2 fetches and parses pagination', () async {
      final service = SuperSelectosService();
      final response = await service.buscarPorCategoria('051', categoryNombre: 'Agua', pagina: 2);
      expect(response.productos, isA<List<Product>>());
      expect(response.paginacion.paginaActual, 2);
      expect(response.paginacion.tienePaginacion, true);
      service.dispose();
    });

    test('buscarPorCodigoBarraAPI returns exact product for 708916031599', () async {
      final service = SuperSelectosService();
      final product = await service.buscarPorCodigoBarraAPI('708916031599');
      expect(product, isNotNull);
      expect(product!.id, '8745');
      expect(product.codigoBarra, '708916031599');
      expect(product.nombre, contains('SAN JULIAN'));
      expect(product.precioFinal, isNotNull);
      expect(product.precioFinal!, greaterThan(0));
      service.dispose();
    });

    test('buscarPorCodigoBarraAPI returns null for non-existent barcode', () async {
      final service = SuperSelectosService();
      final product = await service.buscarPorCodigoBarraAPI('000000000000');
      expect(product, isNull);
      service.dispose();
    });

    test('buscarProductosDetallado performs exact barcode search when barcode matches', () async {
      final service = SuperSelectosService();
      final response = await service.buscarProductosDetallado('708916031599');
      expect(response.codigoDetectado, '708916031599');
      expect(response.esCoincidenciaExacta, true);
      expect(response.productos.length, 1);
      expect(response.productos.first.id, '8745');
      expect(response.productos.first.precioFinal, isNotNull);
      service.dispose();
    });
  });
}
