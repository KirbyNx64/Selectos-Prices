import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_selectos/models/selectos_branch.dart';
import 'package:super_selectos/services/store_selection_controller.dart';
import 'package:super_selectos/services/super_selectos_service.dart';

void main() {
  test(
    'consulta descuentos de la lista 9006 para la sala seleccionada',
    () async {
      SharedPreferences.setMockInitialValues({});
      await StoreSelectionController.instance.selectBranch(
        const SelectosBranch(
          id: '64',
          name: 'Sonsonate Los Leones',
          address: 'Sonsonate',
          zoneId: '',
        ),
      );

      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.toString(),
          'https://ecom-exploration.superselectos.com/'
          'api/accounts/selectos/products/search',
        );
        final payload = jsonDecode(request.body) as Map<String, dynamic>;
        final filters = payload['basicFilters'] as Map<String, dynamic>;
        expect(filters['productGroupsIds'], isNull);
        expect(filters['price'], {
          'priceListId': '9006',
          'priceSince': null,
          'priceUntil': null,
          'onlyPriceOff': true,
        });
        expect(filters['availableInAnyBranchOfficeId'], ['64']);
        expect(payload['page'], 1);
        expect(payload['top'], 20);
        return http.Response(
          jsonEncode({'items': <dynamic>[], 'totalItemCount': 0}),
          200,
        );
      });
      final service = SuperSelectosService(client: client);
      addTearDown(service.dispose);

      final products = await service.obtenerOfertasAppOficial();

      expect(products, isEmpty);
    },
  );
}
