import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_selectos/models/selectos_branch.dart';
import 'package:super_selectos/services/store_selection_controller.dart';
import 'package:super_selectos/services/super_selectos_service.dart';

void main() {
  group('SuperSelectosService link extraction', () {
    test('extracts productId from full web product URLs and formats', () {
      expect(
        SuperSelectosService.extraerProductId(
          'https://www.superselectos.com/products?category=057185&page=1&productId=7894',
        ),
        '7894',
      );
      expect(
        SuperSelectosService.extraerProductId(
          'https://www.superselectos.com/products?productId=7894',
        ),
        '7894',
      );
      expect(
        SuperSelectosService.extraerProductId('productId=7894'),
        '7894',
      );
      expect(
        SuperSelectosService.extraerProductId('productId: 7894'),
        '7894',
      );
      expect(
        SuperSelectosService.extraerProductId('productId 7894'),
        '7894',
      );
      expect(
        SuperSelectosService.extraerProductId('https://www.superselectos.com/products/7894'),
        '7894',
      );
      expect(
        SuperSelectosService.extraerProductId('https://www.superselectos.com/products?category=057185'),
        isNull,
      );
      expect(
        SuperSelectosService.extraerProductId('arroz san francisco'),
        isNull,
      );
    });

    test('extracts categoryCode from category URL', () {
      expect(
        SuperSelectosService.extraerCategoryCode(
          'https://www.superselectos.com/products?category=057185',
        ),
        '057185',
      );
      expect(
        SuperSelectosService.extraerCategoryCode('leche pinito'),
        isNull,
      );
    });

    test('extracts keyword from search URL', () {
      expect(
        SuperSelectosService.extraerKeyword(
          'https://www.superselectos.com/products?keyword=fuze%20tea',
        ),
        'fuze tea',
      );
    });
  });

  group('buscarProductosDetallado with product URL', () {
    test('returns product even if store has branch filter (Sonsonate Los Leones)', () async {
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

      final res = await service.buscarProductosDetallado(
        'https://www.superselectos.com/products?category=057185&page=1&productId=7894',
      );

      expect(res.error, isNull);
      expect(res.esCoincidenciaExacta, isTrue);
      expect(res.productos, hasLength(1));
      expect(res.productos.first.id, '7894');
      expect(res.productos.first.nombre, contains('Fuze'));
      expect(res.productos.first.precio, isNotNull);
    }, timeout: const Timeout(Duration(seconds: 45)));
  });
}
