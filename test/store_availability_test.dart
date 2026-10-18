import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_selectos/models/selectos_branch.dart';
import 'package:super_selectos/services/store_selection_controller.dart';
import 'package:super_selectos/services/super_selectos_service.dart';

void main() {
  test('Sabores incluye el producto 108992 en Sonsonate Los Leones', () async {
    SharedPreferences.setMockInitialValues({});
    final storeController = StoreSelectionController.instance;
    await storeController.selectBranch(
      const SelectosBranch(
        id: '64',
        name: 'Sonsonate Los Leones',
        address: 'Avenida Oidor Ramírez de Quiñonez y Paseo 15 de Septiembre, Sonsonate.',
        zoneId: 'c4bc6420-14d7-4956-8271-b41711a9d74b',
      ),
    );

    final service = SuperSelectosService();
    addTearDown(service.dispose);
    final response = await service.buscarPorCategoria(
      '053178',
      categoryNombre: 'Sabores',
    );

    expect(response.error, isNull);
    expect(response.productos.take(3).map((product) => product.id), [
      '83324',
      '108992',
      '84725',
    ]);
    expect(response.productos.any((product) => product.id == '108992'), isTrue);
  }, timeout: const Timeout(Duration(seconds: 45)));

  test('Sabores ordena los precios dentro de Sonsonate Los Leones', () async {
    SharedPreferences.setMockInitialValues({});
    final storeController = StoreSelectionController.instance;
    await storeController.selectBranch(
      const SelectosBranch(
        id: '64',
        name: 'Sonsonate Los Leones',
        address: 'Avenida Oidor Ramírez de Quiñonez y Paseo 15 de Septiembre, Sonsonate.',
        zoneId: 'c4bc6420-14d7-4956-8271-b41711a9d74b',
      ),
    );

    final service = SuperSelectosService();
    addTearDown(service.dispose);
    final highest = await service.buscarPorCategoria(
      '053178',
      categoryNombre: 'Sabores',
      filters: const ProductFilterSelection(
        sortOrder: ProductSortOrder.highestPrice,
      ),
    );
    final lowest = await service.buscarPorCategoria(
      '053178',
      categoryNombre: 'Sabores',
      filters: const ProductFilterSelection(
        sortOrder: ProductSortOrder.lowestPrice,
      ),
    );

    expect(highest.error, isNull);
    expect(lowest.error, isNull);
    expect(highest.productos, hasLength(20));
    expect(lowest.productos, hasLength(20));
    expect(highest.productos.any((product) => product.id == '108992'), isTrue);
    final highestPrices = highest.productos
        .map((product) => product.precioFinal ?? product.precio)
        .whereType<double>()
        .toList();
    final lowestPrices = lowest.productos
        .map((product) => product.precioFinal ?? product.precio)
        .whereType<double>()
        .toList();
    expect(
      highestPrices,
      orderedEquals([...highestPrices]..sort((a, b) => b.compareTo(a))),
    );
    expect(lowestPrices, orderedEquals([...lowestPrices]..sort()));
  }, timeout: const Timeout(Duration(seconds: 60)));

  test(
    'Telefonía muestra el Nokia disponible en Sonsonate Metrocentro',
    () async {
      SharedPreferences.setMockInitialValues({});
      final storeController = StoreSelectionController.instance;
      await storeController.selectBranch(
        const SelectosBranch(
          id: '63',
          name: 'Sonsonate Metrocentro',
          address: 'Centro Comercial Metrocentro, Sonsonate.',
          zoneId: '',
        ),
      );

      final service = SuperSelectosService();
      addTearDown(service.dispose);
      final response = await service.buscarPorCategoria(
        '111313',
        categoryNombre: 'Telefonía',
      );

      expect(response.error, isNull);
      expect(response.productos, hasLength(1));
      expect(response.productos.single.id, '107358');
      expect(
        response.productos.single.nombre,
        'TELEFONO CELULAR NOKIA 5.4 DR. DOOM',
      );
      expect(response.productos.single.precioFinal, 285.00);
    },
    timeout: const Timeout(Duration(seconds: 45)),
  );
}
