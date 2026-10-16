import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_selectos/models/selectos_branch.dart';
import 'package:super_selectos/services/store_selection_controller.dart';
import 'package:super_selectos/services/super_selectos_service.dart';

void main() {
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
