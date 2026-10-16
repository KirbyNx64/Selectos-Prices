import 'dart:async';
import 'dart:convert';

import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import 'package:super_selectos/models/product.dart';

class PaginationInfo {
  final int paginaActual;
  final List<int> paginasDisponibles;
  final bool tieneAnterior;
  final bool tieneSiguiente;

  const PaginationInfo({
    this.paginaActual = 1,
    this.paginasDisponibles = const [],
    this.tieneAnterior = false,
    this.tieneSiguiente = false,
  });

  bool get tienePaginacion => paginasDisponibles.length > 1;
}

class ProductFilterOption {
  final String label;
  final String value;

  const ProductFilterOption({required this.label, required this.value});
}

class ProductFilterGroup {
  final String title;
  final String queryParameter;
  final List<ProductFilterOption> options;

  const ProductFilterGroup({
    required this.title,
    required this.queryParameter,
    required this.options,
  });
}

class ProductFilterSelection {
  final Map<String, Set<String>> values;

  const ProductFilterSelection({this.values = const {}});

  bool get isEmpty => values.values.every((items) => items.isEmpty);

  int get count =>
      values.values.fold(0, (total, items) => total + items.length);

  Set<String> selectedFor(String queryParameter) =>
      values[queryParameter] ?? const <String>{};

  Map<String, dynamic> toQueryParameters() {
    final parameters = <String, dynamic>{};
    for (final entry in values.entries) {
      if (entry.value.isEmpty) continue;
      final selected = entry.value.toList();
      parameters[entry.key] = selected.length == 1 ? selected.first : selected;
    }
    return parameters;
  }
}

class SearchResponse {
  final List<Product> productos;
  final String? codigoDetectado;
  final String? terminoResuelto;
  final bool codigoNoEncontrado;
  final bool esCoincidenciaExacta;
  final String? error;
  final PaginationInfo paginacion;
  final List<ProductFilterGroup> filterGroups;

  const SearchResponse({
    required this.productos,
    this.codigoDetectado,
    this.terminoResuelto,
    this.codigoNoEncontrado = false,
    this.esCoincidenciaExacta = false,
    this.error,
    this.paginacion = const PaginationInfo(),
    this.filterGroups = const [],
  });
}

class SuperSelectosService {
  final http.Client _client;

  SuperSelectosService({http.Client? client})
    : _client = client ?? http.Client();

  /// Resuelve un código de barras (EAN-8, UPC-12, EAN-13, ITF-14)
  /// consultando Open Food Facts, Open Beauty Facts y Open Products Facts.
  Future<BarcodeInfo?> resolverCodigoBarra(String codigo) async {
    final cleanCode = codigo.trim();
    if (cleanCode.isEmpty) return null;

    final fuentes = [
      'https://world.openfoodfacts.org/api/v0/product/$cleanCode.json',
      'https://world.openbeautyfacts.org/api/v0/product/$cleanCode.json',
      'https://world.openproductsfacts.org/api/v0/product/$cleanCode.json',
    ];

    final headers = {'User-Agent': 'AuraApp/1.0 (El Salvador)'};

    for (final url in fuentes) {
      try {
        final response = await _client
            .get(Uri.parse(url), headers: headers)
            .timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final data = json.decode(response.body) as Map<String, dynamic>;
          if (data['status'] == 1) {
            final prod = (data['product'] as Map<String, dynamic>?) ?? {};
            final nombre = (prod['product_name'] as String? ?? '').trim();
            final marca = (prod['brands'] as String? ?? '').trim();

            if (nombre.isEmpty && marca.isEmpty) {
              continue;
            }

            String termino;
            if (marca.isNotEmpty &&
                !nombre.toLowerCase().contains(marca.toLowerCase())) {
              termino = '$marca $nombre'.trim();
            } else {
              termino = nombre.isNotEmpty ? nombre : marca;
            }

            return BarcodeInfo(
              codigo: cleanCode,
              nombre: nombre,
              marca: marca,
              terminoBusqueda: termino,
            );
          }
        }
      } catch (_) {
        // Intenta la siguiente fuente si ocurre un error o timeout
        continue;
      }
    }

    return null;
  }

  /// Busca productos directamente por código de categoría oficial de Súper Selectos
  /// (ej: "05" para Bebidas, "051" para Agua, "057185" para Bebidas a base de té)
  Future<SearchResponse> buscarPorCategoria(
    String categoryCode, {
    String? categoryNombre,
    int pagina = 1,
    ProductFilterSelection filters = const ProductFilterSelection(),
  }) async {
    final cleanCode = categoryCode.trim();
    if (cleanCode.isEmpty) {
      return const SearchResponse(productos: []);
    }

    try {
      final uri = _buildProductsUri(
        primaryParameter: 'category',
        primaryValue: cleanCode,
        pagina: pagina,
        filters: filters,
      );

      final response = await _client
          .get(
            uri,
            headers: {
              'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
              'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
              'Accept-Language': 'es-ES,es;q=0.9,en;q=0.8',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return SearchResponse(
          productos: const [],
          terminoResuelto: categoryNombre ?? cleanCode,
          error: 'Error al conectar con el servidor (${response.statusCode})',
        );
      }

      final productos = _parsearProductos(response.body, null);
      final paginacion = _parsearPaginacion(response.body);
      final filterGroups = _parsearFiltros(response.body);

      return SearchResponse(
        productos: productos,
        terminoResuelto: categoryNombre ?? cleanCode,
        paginacion: paginacion,
        filterGroups: filterGroups,
      );
    } catch (e) {
      return SearchResponse(
        productos: const [],
        terminoResuelto: categoryNombre ?? cleanCode,
        error: 'Error de conexión: $e',
      );
    }
  }

  /// Consulta la API oficial de Súper Selectos para buscar un producto por su código de barras exacto.
  /// Retorna un [Product] si existe una coincidencia exacta en el arreglo barcodes,
  /// o `null` si no hay coincidencias o si la API devuelve una respuesta no válida.
  Future<Product?> buscarPorCodigoBarraAPI(String codigo) async {
    final cleanCode = codigo.trim();
    if (cleanCode.isEmpty) return null;

    final uri = Uri.parse(
      'https://ecom-exploration.superselectos.com/api/accounts/selectos/products/search',
    );

    final payload = json.encode({
      'basicFilters': {
        'isActive': true,
        'availableOnly': true,
        'barcodes': [cleanCode],
        'productGroupsIds': null,
        'price': null,
        'availableInAnySchemeId': null,
      },
      'searchText': null,
      'page': null,
      'top': null,
    });

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    };

    final response = await _client
        .post(uri, headers: headers, body: payload)
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      return null;
    }

    final data = json.decode(response.body);
    if (data is! Map<String, dynamic>) {
      return null;
    }

    final items = data['items'] as List<dynamic>?;
    if (items == null || items.isEmpty) {
      return null;
    }

    // Buscar dentro de items un producto cuyo arreglo barcodes contenga exactamente el código
    Map<String, dynamic>? itemExacto;
    for (final it in items) {
      if (it is! Map<String, dynamic>) continue;
      final barcodes = (it['barcodes'] as List<dynamic>?)
          ?.map((b) => b.toString().trim())
          .toList();
      if (barcodes != null && barcodes.contains(cleanCode)) {
        itemExacto = it;
        break;
      }
    }

    if (itemExacto == null) {
      return null;
    }

    final productId = itemExacto['productId']?.toString() ?? '';
    final nombre = (itemExacto['name'] as String? ?? '').trim();

    // Extraer categoría simplificada desde la jerarquía de categorías
    String? categoria;
    final categories = itemExacto['categories'] as List<dynamic>?;
    if (categories != null && categories.isNotEmpty) {
      final firstCat = categories.first as Map<String, dynamic>?;
      final catFullName = firstCat?['name']?.toString() ?? '';
      if (catFullName.contains('->')) {
        categoria = catFullName.split('->').last.trim();
      } else if (catFullName.isNotEmpty) {
        categoria = catFullName.trim();
      }
    }

    // Extraer URL de imagen principal (priorizando versión Medium o primera disponible)
    String? imagenUrl;
    final mainMedia = itemExacto['mainMedia'] as Map<String, dynamic>?;
    final versions = mainMedia?['versions'] as List<dynamic>?;
    if (versions != null && versions.isNotEmpty) {
      for (final v in versions) {
        if (v is Map<String, dynamic> && v['url'] != null) {
          final url = v['url'].toString();
          if (v['version'] == 'Medium') {
            imagenUrl = url;
            break;
          } else {
            imagenUrl ??= url;
          }
        }
      }
    }

    final productoBase = Product(
      id: productId,
      nombre: nombre.isNotEmpty
          ? nombre
          : (itemExacto['largeDescription'] as String? ?? cleanCode),
      imagen: imagenUrl,
      enlace: 'https://www.superselectos.com/products?productId=$productId',
      supermercado: 'Súper Selectos',
      codigoBarra: cleanCode,
      categoria: categoria,
    );

    // Integrar con el catálogo web para recuperar precio actual y promociones
    if (productId.isNotEmpty) {
      try {
        final productoWeb = await obtenerDetalleProductoWeb(
          productId,
          productoBase: productoBase,
        );
        if (productoWeb != null) {
          return productoWeb;
        }
      } catch (_) {
        // Si la consulta web falla, se conserva la información base del producto
      }
    }

    return productoBase;
  }

  /// Consulta la página web de Súper Selectos por productId para obtener precio actual,
  /// precios anteriores, ahorro y estado de promociones.
  Future<Product?> obtenerDetalleProductoWeb(
    String productId, {
    Product? productoBase,
  }) async {
    final cleanId = productId.trim();
    if (cleanId.isEmpty) return productoBase;

    try {
      final uri = Uri.parse(
        'https://www.superselectos.com/products?productId=$cleanId',
      );
      final response = await _client
          .get(
            uri,
            headers: {
              'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
              'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
              'Accept-Language': 'es-ES,es;q=0.9,en;q=0.8',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return productoBase;
      }

      final document = html_parser.parse(response.body);
      final modal =
          document.querySelector('.producto-detalle-modal') ??
          document.querySelector('.producto-detalle-content') ??
          document.querySelector('body');

      if (modal == null) {
        return productoBase;
      }

      final nombreElem = modal.querySelector('.det-nom, h1.det-nom, h1');
      final nombre = nombreElem?.text.trim();

      final precioElem = modal.querySelector('.precios .precio, strong.precio');
      final antesElem = modal.querySelector('.precios .antes, span.antes');
      final ahorroElem = modal.querySelector('.precios .ahorro, span.ahorro');
      final promoElem = modal.querySelector(
        '.vinetas-top .badge, .vinetas-producto .badge, .vinetas .badge',
      );

      double? precioFinal = _parsePrice(precioElem?.text);
      if (precioFinal == null) {
        final matches = RegExp(r'\$\s*\d+(?:,\d{3})*(?:\.\d{2})?')
            .allMatches(modal.text);
        if (matches.isNotEmpty) {
          precioFinal = _parsePrice(matches.first.group(0));
        }
      }

      final precioOriginal = _parsePrice(antesElem?.text);
      final descuentoRaw = _parsePrice(ahorroElem?.text);
      final tieneDescuento =
          precioOriginal != null && precioOriginal > (precioFinal ?? 0);

      double descuento = 0.0;
      if (tieneDescuento) {
        if (descuentoRaw != null) {
          descuento = descuentoRaw;
        } else if (precioFinal != null) {
          descuento = double.parse(
            (precioOriginal - precioFinal).toStringAsFixed(2),
          );
        }
      }

      final catElem = modal.querySelector('.det-cat a, .det-cat');
      final categoria = catElem?.text.trim();

      // Extraer todas las imágenes del slider de producto
      final imagenes = <String>[];
      final imgElements = modal.querySelectorAll(
        '.thumbs-media-slider img, .main-media-slider img, .producto-slider-container img, .media-slider-container img, .prod-slider img',
      );
      for (final el in imgElements) {
        String? src = el.attributes['src'] ?? el.attributes['data-src'];
        if (src != null && src.isNotEmpty) {
          if (src.startsWith('//')) {
            src = 'https:$src';
          }
          if (!imagenes.contains(src)) {
            imagenes.add(src);
          }
        }
      }

      String? imagenUrl = imagenes.isNotEmpty
          ? imagenes.first
          : productoBase?.imagen;
      if (imagenUrl == null) {
        final imgElem = modal.querySelector('img');
        imagenUrl =
            imgElem?.attributes['src'] ?? imgElem?.attributes['data-src'];
        if (imagenUrl != null && imagenUrl.startsWith('//')) {
          imagenUrl = 'https:$imagenUrl';
        }
        if (imagenUrl != null && !imagenes.contains(imagenUrl)) {
          imagenes.add(imagenUrl);
        }
      }

      // Extraer descripción del producto
      final descElem = modal.querySelector('.det-des p, .det-des');
      String? descripcion = descElem?.text.trim();
      if (descripcion != null) {
        if (descripcion.toLowerCase().startsWith('descripción')) {
          descripcion = descripcion.substring('descripción'.length).trim();
        }
        if (descripcion.isEmpty) {
          descripcion = null;
        }
      }
      descripcion ??= productoBase?.descripcion;

      final promocion = promoElem?.text.trim();

      return Product(
        id: cleanId,
        nombre: (nombre != null && nombre.isNotEmpty)
            ? nombre
            : (productoBase?.nombre ?? ''),
        precio: precioFinal ?? productoBase?.precio,
        precioFinal: precioFinal ?? productoBase?.precioFinal,
        precioOriginal: tieneDescuento
            ? precioOriginal
            : (precioFinal ?? productoBase?.precioOriginal),
        descuento: descuento,
        tieneDescuento: tieneDescuento,
        promocion: (promocion != null && promocion.isNotEmpty)
            ? promocion
            : productoBase?.promocion,
        imagen: imagenUrl,
        imagenes: imagenes.isNotEmpty
            ? imagenes
            : (productoBase?.imagenes ??
                  (imagenUrl != null ? [imagenUrl] : const [])),
        descripcion: descripcion,
        enlace: 'https://www.superselectos.com/products?productId=$cleanId',
        supermercado: 'Súper Selectos',
        codigoBarra: productoBase?.codigoBarra,
        categoria: (categoria != null && categoria.isNotEmpty)
            ? categoria
            : productoBase?.categoria,
      );
    } catch (_) {
      return productoBase;
    }
  }

  /// Busca productos en Súper Selectos por término o código de barras
  Future<SearchResponse> buscarProductosDetallado(
    String busqueda, {
    String? categoryCode,
    int pagina = 1,
    ProductFilterSelection filters = const ProductFilterSelection(),
  }) async {
    if (categoryCode != null && categoryCode.isNotEmpty) {
      return buscarPorCategoria(
        categoryCode,
        categoryNombre: busqueda,
        pagina: pagina,
        filters: filters,
      );
    }

    String? codigoDetectado;
    String terminoBusqueda = busqueda.trim();

    if (terminoBusqueda.isEmpty) {
      return const SearchResponse(productos: []);
    }

    // Detectar si el término ingresado es un código de barras numérico (8 a 14 dígitos)
    final esCodigoBarra =
        RegExp(r'^\d+$').hasMatch(terminoBusqueda) &&
        terminoBusqueda.length >= 8 &&
        terminoBusqueda.length <= 14;

    if (esCodigoBarra) {
      codigoDetectado = terminoBusqueda;

      // 1. Intentar primero búsqueda exacta en la API oficial de Súper Selectos
      try {
        final productoExacto = await buscarPorCodigoBarraAPI(terminoBusqueda);
        if (productoExacto != null) {
          return SearchResponse(
            productos: [productoExacto],
            codigoDetectado: codigoDetectado,
            terminoResuelto: productoExacto.nombre,
            esCoincidenciaExacta: true,
          );
        }
      } on http.ClientException catch (e) {
        return SearchResponse(
          productos: const [],
          codigoDetectado: codigoDetectado,
          error: 'Error de conexión: ${e.message}',
        );
      } on TimeoutException {
        return SearchResponse(
          productos: const [],
          codigoDetectado: codigoDetectado,
          error: 'Tiempo de espera agotado al conectar con el servidor.',
        );
      } catch (e) {
        if (e.toString().contains('SocketException')) {
          return SearchResponse(
            productos: const [],
            codigoDetectado: codigoDetectado,
            error: 'Error de conexión con el servidor: $e',
          );
        }
        // En caso de otros errores no críticos de API, continuar al fallback
      }

      // 2. Si la API oficial no devuelve coincidencia exacta, ejecutar el procedimiento
      // anterior de fallback: resolver nombre mediante base de datos pública (Open Food Facts)
      try {
        final infoCodigo = await resolverCodigoBarra(terminoBusqueda);
        if (infoCodigo != null && infoCodigo.terminoBusqueda.isNotEmpty) {
          terminoBusqueda = infoCodigo.terminoBusqueda;
        } else {
          return SearchResponse(
            productos: const [],
            codigoDetectado: terminoBusqueda,
            codigoNoEncontrado: true,
          );
        }
      } on http.ClientException catch (e) {
        return SearchResponse(
          productos: const [],
          codigoDetectado: codigoDetectado,
          error: 'Error de conexión: ${e.message}',
        );
      } on TimeoutException {
        return SearchResponse(
          productos: const [],
          codigoDetectado: codigoDetectado,
          error: 'Tiempo de espera agotado al conectar con el servidor.',
        );
      } catch (e) {
        if (e.toString().contains('SocketException')) {
          return SearchResponse(
            productos: const [],
            codigoDetectado: codigoDetectado,
            error: 'Error de conexión con el servidor: $e',
          );
        }
        return SearchResponse(
          productos: const [],
          codigoDetectado: terminoBusqueda,
          codigoNoEncontrado: true,
        );
      }
    }

    try {
      final uri = _buildProductsUri(
        primaryParameter: 'keyword',
        primaryValue: terminoBusqueda,
        pagina: pagina,
        filters: filters,
      );

      final response = await _client
          .get(
            uri,
            headers: {
              'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
              'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
              'Accept-Language': 'es-ES,es;q=0.9,en;q=0.8',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return SearchResponse(
          productos: const [],
          codigoDetectado: codigoDetectado,
          terminoResuelto: terminoBusqueda,
          error: 'Error al conectar con el servidor (${response.statusCode})',
        );
      }

      var productos = _parsearProductos(response.body, codigoDetectado);
      var paginacion = _parsearPaginacion(response.body);
      var filterGroups = _parsearFiltros(response.body);

      // Si no hay resultados y el término contiene guiones o caracteres especiales,
      // intentar reemplazando guiones por espacios (ej: Coca-Cola -> Coca Cola)
      if (productos.isEmpty && terminoBusqueda.contains('-')) {
        final terminoSinGuion = terminoBusqueda.replaceAll('-', ' ').trim();
        final fallbackUri = _buildProductsUri(
          primaryParameter: 'keyword',
          primaryValue: terminoSinGuion,
          pagina: pagina,
          filters: filters,
        );
        final fallbackResponse = await _client
            .get(
              fallbackUri,
              headers: {
                'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
              },
            )
            .timeout(const Duration(seconds: 10));

        if (fallbackResponse.statusCode == 200) {
          final fallbackProductos = _parsearProductos(
            fallbackResponse.body,
            codigoDetectado,
          );
          if (fallbackProductos.isNotEmpty) {
            productos = fallbackProductos;
            terminoBusqueda = terminoSinGuion;
            paginacion = _parsearPaginacion(fallbackResponse.body);
            filterGroups = _parsearFiltros(fallbackResponse.body);
          }
        }
      }

      return SearchResponse(
        productos: productos,
        codigoDetectado: codigoDetectado,
        terminoResuelto: terminoBusqueda,
        paginacion: paginacion,
        filterGroups: filterGroups,
      );
    } catch (e) {
      return SearchResponse(
        productos: const [],
        codigoDetectado: codigoDetectado,
        terminoResuelto: terminoBusqueda,
        error: 'Error de conexión: $e',
      );
    }
  }

  Uri _buildProductsUri({
    required String primaryParameter,
    required String primaryValue,
    required int pagina,
    required ProductFilterSelection filters,
  }) {
    final queryParameters = <String, dynamic>{
      primaryParameter: primaryValue,
      if (pagina > 1 || !filters.isEmpty) 'page': pagina.toString(),
      ...filters.toQueryParameters(),
    };

    return Uri.https('www.superselectos.com', '/products', queryParameters);
  }

  /// Conveniencia para obtener directamente la lista de productos
  Future<List<Product>> buscarProductos(String busqueda) async {
    final res = await buscarProductosDetallado(busqueda);
    return res.productos;
  }

  List<Product>? _productosInicioCache;

  /// Obtiene los productos destacados de la página de inicio de Súper Selectos
  Future<List<Product>> obtenerProductosInicio({
    bool forzarRefresco = false,
  }) async {
    if (!forzarRefresco &&
        _productosInicioCache != null &&
        _productosInicioCache!.isNotEmpty) {
      return _productosInicioCache!;
    }

    try {
      final uri = Uri.parse('https://www.superselectos.com/');
      final response = await _client
          .get(
            uri,
            headers: {
              'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
              'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
              'Accept-Language': 'es-ES,es;q=0.9,en;q=0.8',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return _productosInicioCache ?? [];
      }

      final productos = _parsearProductos(response.body, null);
      if (productos.isNotEmpty) {
        _productosInicioCache = productos;
      }
      return productos;
    } catch (_) {
      return _productosInicioCache ?? [];
    }
  }

  /// Parsea el HTML de Súper Selectos extrayendo los productos
  List<Product> _parsearProductos(String html, String? codigoDetectado) {
    final document = html_parser.parse(html);
    final resultados = <String, Product>{};

    // Remover elementos del carrito antes de buscar productos
    for (final cartElem in document.querySelectorAll(
      '.carr-productos, #carretilla-resumen-wrap',
    )) {
      cartElem.remove();
    }

    var tarjetas = document.querySelectorAll(
      '.listado-productos .producto-box',
    );
    if (tarjetas.isEmpty) {
      tarjetas = document.querySelectorAll(
        '.listado-productos li.item-producto',
      );
    }
    if (tarjetas.isEmpty) {
      tarjetas = document.querySelectorAll('.item-producto .producto-box');
    }
    if (tarjetas.isEmpty) {
      tarjetas = document.querySelectorAll('.producto-box');
    }

    for (final tarjeta in tarjetas) {
      // Buscar enlace con productId o h5
      final enlace =
          tarjeta.querySelector('h5 a[href*="productId="]') ??
          tarjeta.querySelector('h5.prod-nombre a') ??
          tarjeta.querySelector('h5 a') ??
          tarjeta.querySelector('a[href*="productId="]');

      if (enlace == null) continue;

      final href =
          enlace.attributes['href'] ??
          tarjeta.querySelector('a[href*="productId="]')?.attributes['href'] ??
          '';
      String? id;

      // Extraer productId de la URL o tarjeta
      final idMatch =
          RegExp(r'productId=(\d+)').firstMatch(href) ??
          RegExp(r'productId=(\d+)').firstMatch(tarjeta.outerHtml);
      if (idMatch != null) {
        id = idMatch.group(1);
      }

      if (id == null || id.isEmpty || resultados.containsKey(id)) {
        continue;
      }

      final nombreElem =
          tarjeta.querySelector('h5 a') ??
          tarjeta.querySelector('h5') ??
          tarjeta.querySelector('.prod-nombre') ??
          enlace;
      final nombre = nombreElem.text.trim();
      if (nombre.isEmpty) continue;

      // Precios
      final precioElem = tarjeta.querySelector(
        '.precios .precio, strong.precio',
      );
      final antesElem = tarjeta.querySelector('.precios .antes, span.antes');
      final ahorroElem = tarjeta.querySelector('.precios .ahorro, span.ahorro');
      final promoElem = tarjeta.querySelector(
        '.vinetas-producto .badge, .vinetas-top .badge',
      );

      double? precioFinal = _parsePrice(precioElem?.text);

      // Fallback para precio si no se encuentra en el elemento específico
      if (precioFinal == null) {
        final matches = RegExp(r'\$\s*\d+(?:,\d{3})*(?:\.\d{2})?')
            .allMatches(tarjeta.text);
        if (matches.isEmpty) continue;
        precioFinal = _parsePrice(matches.first.group(0));
      }

      final precioOriginal = _parsePrice(antesElem?.text);
      final descuentoRaw = _parsePrice(ahorroElem?.text);
      final tieneDescuento =
          precioOriginal != null && precioOriginal > (precioFinal ?? 0);

      double descuento = 0.0;
      if (tieneDescuento) {
        if (descuentoRaw != null) {
          descuento = descuentoRaw;
        } else if (precioFinal != null) {
          descuento = double.parse(
            (precioOriginal - precioFinal).toStringAsFixed(2),
          );
        }
      }

      // Imagen
      final imgElem = tarjeta.querySelector('.prod-images img, img');
      String? imagenUrl =
          imgElem?.attributes['src'] ?? imgElem?.attributes['data-src'];
      if (imagenUrl != null && imagenUrl.startsWith('//')) {
        imagenUrl = 'https:$imagenUrl';
      }

      // Enlace completo
      String urlCompleta = href;
      if (!urlCompleta.startsWith('http')) {
        urlCompleta =
            'https://www.superselectos.com${urlCompleta.startsWith('/') ? '' : '/'}$urlCompleta';
      }

      // Promoción
      final promocion = promoElem?.text.trim();

      // Categoría
      final catElem = tarjeta.querySelector(
        '.medio .cat a, .cat a, .medio .cat, .cat',
      );
      final categoria = catElem?.text.trim();

      resultados[id] = Product(
        id: id,
        nombre: nombre,
        precio: precioFinal,
        precioFinal: precioFinal,
        precioOriginal: tieneDescuento ? precioOriginal : precioFinal,
        descuento: descuento,
        tieneDescuento: tieneDescuento,
        promocion: (promocion != null && promocion.isNotEmpty)
            ? promocion
            : null,
        imagen: imagenUrl,
        enlace: urlCompleta,
        supermercado: 'Súper Selectos',
        codigoBarra: codigoDetectado,
        categoria: (categoria != null && categoria.isNotEmpty)
            ? categoria
            : null,
      );
    }

    return resultados.values.toList();
  }

  PaginationInfo _parsearPaginacion(String html) {
    final document = html_parser.parse(html);
    final ul = document.querySelector('ul.pagination');
    if (ul == null) {
      return const PaginationInfo();
    }

    int paginaActual = 1;
    final paginas = <int>[];
    bool tieneAnterior = false;
    bool tieneSiguiente = false;

    final items = ul.querySelectorAll('li.page-item');
    for (final li in items) {
      final text = li.text.trim();
      final classes = li.classes;
      final disabled = classes.contains('disabled');
      final active = classes.contains('active');

      if (text.contains('Anterior')) {
        tieneAnterior = !disabled;
      } else if (text.contains('Siguiente')) {
        tieneSiguiente = !disabled;
      } else {
        final num = int.tryParse(text);
        if (num != null) {
          paginas.add(num);
          if (active) {
            paginaActual = num;
          }
        }
      }
    }

    return PaginationInfo(
      paginaActual: paginaActual,
      paginasDisponibles: paginas,
      tieneAnterior: tieneAnterior,
      tieneSiguiente: tieneSiguiente,
    );
  }

  List<ProductFilterGroup> _parsearFiltros(String html) {
    final document = html_parser.parse(html);
    final groups = <ProductFilterGroup>[];

    for (final panel in document.querySelectorAll(
      '#filtros .filter-rz-panel',
    )) {
      final title = panel.querySelector('.rz-panel-titlebar h6')?.text.trim();
      if (title == null || title.isEmpty) continue;

      final normalizedTitle = title.toLowerCase();
      final queryParameter = switch (normalizedTitle) {
        'rango de precios' => 'prices',
        'categorías' || 'categorias' => 'categoriesnames',
        'marcas' => 'brandsnames',
        _ => null,
      };
      if (queryParameter == null) continue;

      final options = <ProductFilterOption>[];
      for (final checkbox in panel.querySelectorAll('.rz-checkbox')) {
        final input = checkbox.querySelector('input[type="checkbox"]');
        final label = checkbox.querySelector('.rz-chkbox-label')?.text.trim();
        final value = input?.attributes['value']?.trim();
        if (label == null || label.isEmpty || value == null || value.isEmpty) {
          continue;
        }
        options.add(ProductFilterOption(label: label, value: value));
      }

      if (options.isNotEmpty) {
        groups.add(
          ProductFilterGroup(
            title: title,
            queryParameter: queryParameter,
            options: options,
          ),
        );
      }
    }

    return groups;
  }

  double? _parsePrice(String? text) {
    if (text == null) return null;
    final clean = text.replaceAll(',', '');
    final match = RegExp(r'\d+(?:\.\d+)?').firstMatch(clean);
    if (match != null) {
      return double.tryParse(match.group(0)!);
    }
    return null;
  }

  void dispose() {
    _client.close();
  }
}
