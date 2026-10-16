import 'dart:convert';

import 'package:super_selectos/models/product.dart';

class ShoppingCartItem {
  final String key;
  final Product product;
  final int quantity;

  const ShoppingCartItem({
    required this.key,
    required this.product,
    required this.quantity,
  });

  double get unitPrice => product.precioFinal ?? product.precio ?? 0;

  double get subtotal => unitPrice * quantity;

  Map<String, Object?> toMap() {
    return {
      'product_key': key,
      'product_id': product.id,
      'nombre': product.nombre,
      'precio': product.precio,
      'precio_final': product.precioFinal,
      'precio_original': product.precioOriginal,
      'descuento': product.descuento,
      'tiene_descuento': product.tieneDescuento ? 1 : 0,
      'promocion': product.promocion,
      'imagen': product.imagen,
      'imagenes': jsonEncode(product.imagenes),
      'descripcion': product.descripcion,
      'enlace': product.enlace,
      'supermercado': product.supermercado,
      'codigo_barra': product.codigoBarra,
      'categoria': product.categoria,
      'cantidad': quantity,
    };
  }

  factory ShoppingCartItem.fromMap(Map<String, Object?> map) {
    final rawImages = map['imagenes'] as String?;
    final images = rawImages == null || rawImages.isEmpty
        ? const <String>[]
        : (jsonDecode(rawImages) as List<dynamic>)
              .map((image) => image.toString())
              .toList();

    return ShoppingCartItem(
      key: map['product_key'] as String,
      quantity: map['cantidad'] as int,
      product: Product(
        id: map['product_id'] as String? ?? '',
        nombre: map['nombre'] as String? ?? '',
        precio: (map['precio'] as num?)?.toDouble(),
        precioFinal: (map['precio_final'] as num?)?.toDouble(),
        precioOriginal: (map['precio_original'] as num?)?.toDouble(),
        descuento: (map['descuento'] as num?)?.toDouble() ?? 0,
        tieneDescuento: (map['tiene_descuento'] as int? ?? 0) == 1,
        promocion: map['promocion'] as String?,
        imagen: map['imagen'] as String?,
        imagenes: images,
        descripcion: map['descripcion'] as String?,
        enlace: map['enlace'] as String?,
        supermercado: map['supermercado'] as String? ?? 'Súper Selectos',
        codigoBarra: map['codigo_barra'] as String?,
        categoria: map['categoria'] as String?,
      ),
    );
  }

  static String keyFor(Product product) {
    if (product.id.trim().isNotEmpty) return product.id.trim();
    if (product.codigoBarra?.trim().isNotEmpty ?? false) {
      return 'barcode:${product.codigoBarra!.trim()}';
    }
    return '${product.supermercado}:${product.nombre}:${product.precioFinal ?? product.precio ?? 0}';
  }
}
