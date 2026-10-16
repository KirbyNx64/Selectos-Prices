import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:super_selectos/services/super_selectos_service.dart';

void main() {
  test(
    'parses highlighted campaigns from the Super Selectos home page',
    () async {
      final client = MockClient((_) async {
        return http.Response('''
        <div class="item-categoria-destacada">
          <a href="/products-landing/SABORES-A">
            <img src="https://cdn.example/sabores.jpg" />
          </a>
        </div>
        <div class="item-categoria-destacada">
          <a href="https://www.superselectos.com/products-landing/HOGAR-A">
            <img src="https://cdn.example/hogar.jpg" />
          </a>
        </div>
      ''', 200);
      });
      final service = SuperSelectosService(client: client);
      addTearDown(service.dispose);

      final campaigns = await service.obtenerCampanasDestacadas();

      expect(campaigns, hasLength(2));
      expect(campaigns.first.title, 'Sabores de Fiesta');
      expect(
        campaigns.first.url,
        'https://www.superselectos.com/products-landing/SABORES-A',
      );
      expect(campaigns.last.title, 'Todo para tu hogar');
    },
  );

  test('loads and parses a requested campaign page', () async {
    Uri? requestedUri;
    final client = MockClient((request) async {
      requestedUri = request.url;
      return http.Response('''
        <div class="item-producto">
          <div class="producto-box">
            <div class="prod-images">
              <img src="https://cdn.example/product.jpg" />
            </div>
            <div class="precios"><strong class="precio">\$1.80</strong></div>
            <h5 class="prod-nombre">
              <a href="https://www.superselectos.com/products-landing/SABORES-A?productId=5630">
                Chocolate Snickers
              </a>
            </h5>
          </div>
        </div>
        <ul class="pagination">
          <li class="page-item"><a>Anterior</a></li>
          <li class="page-item"><a>1</a></li>
          <li class="page-item active"><a>2</a></li>
          <li class="page-item"><a>3</a></li>
          <li class="page-item"><a>Siguiente</a></li>
        </ul>
        <div id="filtros">
          <div class="filter-rz-panel">
            <div class="rz-panel-titlebar"><h6>Marcas</h6></div>
            <div class="rz-checkbox">
              <input type="checkbox" value="Mars" />
              <span class="rz-chkbox-label">Mars</span>
            </div>
          </div>
        </div>
      ''', 200);
    });
    final service = SuperSelectosService(client: client);
    addTearDown(service.dispose);

    final response = await service.obtenerProductosLanding(
      'https://www.superselectos.com/products-landing/SABORES-A',
      pagina: 2,
      filters: const ProductFilterSelection(
        values: {
          'brandsnames': {'Mars'},
        },
      ),
    );

    expect(requestedUri?.queryParameters['page'], '2');
    expect(requestedUri?.queryParameters['brandsnames'], 'Mars');
    expect(response.productos, hasLength(1));
    expect(response.productos.single.id, '5630');
    expect(response.productos.single.nombre, 'Chocolate Snickers');
    expect(response.productos.single.precioFinal, 1.80);
    expect(response.paginacion.paginaActual, 2);
    expect(response.paginacion.paginasDisponibles, [1, 2, 3]);
    expect(response.paginacion.tieneAnterior, isTrue);
    expect(response.paginacion.tieneSiguiente, isTrue);
    expect(response.filterGroups.single.title, 'Marcas');
    expect(response.filterGroups.single.options.single.label, 'Mars');
  });
}
