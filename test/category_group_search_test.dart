import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_selectos/models/selectos_branch.dart';
import 'package:super_selectos/services/store_selection_controller.dart';
import 'package:super_selectos/services/super_selectos_service.dart';

void main() {
  test('category group search returns products in selected store', () async {
    SharedPreferences.setMockInitialValues({});
    await StoreSelectionController.instance.selectBranch(
      const SelectosBranch(
        id: '64',
        name: 'Sonsonate Los Leones',
        address: 'Avenida Oidor Ramírez de Quiñonez y Paseo 15 de Septiembre, Sonsonate.',
        zoneId: 'c4bc6420-14d7-4956-8271-b41711a9d74b',
      ),
    );

    final service = SuperSelectosService();
    addTearDown(service.dispose);

    // Group categories with 3-digit codes (e.g., Alimentos preparados, Frutas y verduras)
    for (final cat in ['018', '012']) {
      final res = await service.buscarPorCategoria(cat);
      expect(res.error, isNull);
      expect(res.productos, isNotEmpty);
    }
  }, timeout: const Timeout(Duration(seconds: 45)));
}
