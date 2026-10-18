import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_selectos/models/selectos_branch.dart';
import 'package:super_selectos/services/store_selection_controller.dart';
import 'package:super_selectos/services/super_selectos_service.dart';

void main() {
  group('ProductFilterSelection sorting', () {
    test('maps the normal A-Z order to AlphabeticallyAsc', () {
      const selection = ProductFilterSelection();

      expect(selection.toQueryParameters(), {'orderBy': 'AlphabeticallyAsc'});
      expect(selection.count, 0);
    });

    test('maps every non-default order to the website parameter', () {
      const expectedValues = {
        ProductSortOrder.alphabeticallyDesc: 'AlphabeticallyDesc',
        ProductSortOrder.highestPrice: 'HighestPrice',
        ProductSortOrder.lowestPrice: 'LowestPrice',
      };

      for (final entry in expectedValues.entries) {
        final selection = ProductFilterSelection(sortOrder: entry.key);

        expect(selection.toQueryParameters()['orderBy'], entry.value);
        expect(selection.count, 1);
      }
    });

    test('keeps sorting compatible with the other filters', () {
      const selection = ProductFilterSelection(
        values: {
          'brandsnames': {'Mars'},
        },
        sortOrder: ProductSortOrder.highestPrice,
      );

      expect(selection.toQueryParameters(), {
        'brandsnames': 'Mars',
        'orderBy': 'HighestPrice',
      });
      expect(selection.count, 2);
    });

    test('omits sorting when the website does not support it', () {
      const selection = ProductFilterSelection(
        values: {
          'brandsnames': {'Mazola'},
        },
        sortOrder: ProductSortOrder.highestPrice,
      );

      expect(selection.toQueryParameters(includeSortOrder: false), {
        'brandsnames': 'Mazola',
      });
    });

    test(
      'loads exact pages and checks only their products in the selected store',
      () async {
        SharedPreferences.setMockInitialValues({});
        await StoreSelectionController.instance.selectBranch(
          const SelectosBranch(
            id: '63',
            name: 'Sonsonate Metrocentro',
            address: 'Centro Comercial Metrocentro, Sonsonate.',
            zoneId: '',
          ),
        );

        Uri? catalogUri;
        var requestCount = 0;
        final branchPayloads = <Map<String, dynamic>>[];
        final client = MockClient((request) async {
          requestCount++;
          if (request.method == 'GET') {
            catalogUri = request.url;
            final cookie = request.headers['cookie'];
            expect(cookie, isNotNull);
            final encodedBranch = RegExp(r'BranchOfficeIdselectos=([^;]+)')
                .firstMatch(cookie!)!
                .group(1)!;
            final branchSelection = jsonDecode(
              utf8.decode(base64Decode(encodedBranch)),
            ) as Map<String, dynamic>;
            expect(branchSelection['BranchOfficeId'], '63');
            expect(branchSelection['IsHomeDelivery'], isFalse);
            expect(branchSelection['IsExpired'], isFalse);
            return http.Response('''
              <div class="item-producto">
                <div class="producto-box">
                  <div class="precios"><strong class="precio">\$2.00</strong></div>
                  <h5><a href="/products?productId=2053">Producto página 2</a></h5>
                </div>
              </div>
            ''', 200);
          }

          final payload = jsonDecode(request.body) as Map<String, dynamic>;
          branchPayloads.add(payload);
          expect(payload['basicFilters']['productGroupsIds'], ['053178']);
          expect(payload['top'], 20);
          return http.Response(
            jsonEncode({
              'items': [
                {'productId': '2053', 'name': 'Producto página 2'},
              ],
              'totalItemCount': 1,
            }),
            200,
          );
        });
        final service = SuperSelectosService(client: client);
        addTearDown(service.dispose);

        final response = await service.buscarPorCategoria(
          '053178',
          pagina: 2,
          filters: const ProductFilterSelection(
            sortOrder: ProductSortOrder.alphabeticallyDesc,
          ),
        );

        expect(
          catalogUri.toString(),
          'https://www.superselectos.com/products?category=053178&orderBy=AlphabeticallyDesc&page=2',
        );
        expect(requestCount, 2);
        expect(branchPayloads.first['page'], 2);
        expect(branchPayloads.first['orderBy'], [
          {'field': 'Name', 'orderType': 'Descending'},
        ]);
        expect(response.productos.single.id, '2053');

        final normalResponse = await service.buscarPorCategoria(
          '053178',
          pagina: 1,
        );

        expect(
          catalogUri.toString(),
          'https://www.superselectos.com/products?category=053178&orderBy=AlphabeticallyAsc&page=1',
        );
        expect(requestCount, 4);
        expect(branchPayloads.last['page'], 1);
        expect(branchPayloads.last['orderBy'], [
          {'field': 'Name', 'orderType': 'Ascending'},
        ]);
        expect(normalResponse.productos.single.id, '2053');
      },
    );

    test('keeps the website ranking for keyword searches', () async {
      SharedPreferences.setMockInitialValues({});
      await StoreSelectionController.instance.selectBranch(
        const SelectosBranch(
          id: '64',
          name: 'Sonsonate Los Leones',
          address: 'Sonsonate',
          zoneId: '',
        ),
      );

      var requestCount = 0;
      final client = MockClient((request) async {
        requestCount++;
        if (request.method == 'GET') {
          expect(
            request.url.toString(),
            'https://www.superselectos.com/products?keyword=aceite&page=1',
          );
          return http.Response('''
              <div class="listado-productos">
                <div class="producto-box">
                  <div class="precios"><strong class="precio">\$1.70</strong></div>
                  <h5><a href="/products?productId=100">Aceite Nutrioli de Soya 400 mL</a></h5>
                </div>
              </div>
            ''', 200);
        }

        final payload = jsonDecode(request.body) as Map<String, dynamic>;
        expect(payload['basicFilters']['productIds'], ['100']);
        expect(payload['basicFilters']['availableInAnyBranchOfficeId'], ['64']);
        expect(payload['searchText'], isNull);
        return http.Response(
          jsonEncode({
            'items': [
              {'productId': '100'},
            ],
            'totalItemCount': 1,
          }),
          200,
        );
      });
      final service = SuperSelectosService(client: client);
      addTearDown(service.dispose);

      final response = await service.buscarProductosDetallado('aceite');

      expect(requestCount, 2);
      expect(response.productos.single.id, '100');
      expect(
        response.productos.single.nombre,
        'Aceite Nutrioli de Soya 400 mL',
      );
    });
  });
}
