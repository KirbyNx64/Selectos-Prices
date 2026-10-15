class BarcodeInfo {
  final String codigo;
  final String nombre;
  final String marca;
  final String terminoBusqueda;

  const BarcodeInfo({
    required this.codigo,
    required this.nombre,
    required this.marca,
    required this.terminoBusqueda,
  });

  factory BarcodeInfo.fromJson(Map<String, dynamic> json) {
    return BarcodeInfo(
      codigo: json['codigo'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      marca: json['marca'] as String? ?? '',
      terminoBusqueda: json['termino_busqueda'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'codigo': codigo,
      'nombre': nombre,
      'marca': marca,
      'termino_busqueda': terminoBusqueda,
    };
  }
}

class Product {
  final String id;
  final String nombre;
  final double? precio;
  final double? precioFinal;
  final double? precioOriginal;
  final double descuento;
  final bool tieneDescuento;
  final String? promocion;
  final String? imagen;
  final List<String> imagenes;
  final String? descripcion;
  final String? enlace;
  final String supermercado;
  final String? codigoBarra;
  final String? categoria;

  const Product({
    required this.id,
    required this.nombre,
    this.precio,
    this.precioFinal,
    this.precioOriginal,
    this.descuento = 0.0,
    this.tieneDescuento = false,
    this.promocion,
    this.imagen,
    this.imagenes = const [],
    this.descripcion,
    this.enlace,
    this.supermercado = 'Súper Selectos',
    this.codigoBarra,
    this.categoria,
  });

  List<String> get todasLasImagenes {
    if (imagenes.isNotEmpty) return imagenes;
    if (imagen != null && imagen!.isNotEmpty) return [imagen!];
    return const [];
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      precio: (json['precio'] as num?)?.toDouble(),
      precioFinal: (json['precio_final'] as num?)?.toDouble(),
      precioOriginal: (json['precio_original'] as num?)?.toDouble(),
      descuento: (json['descuento'] as num?)?.toDouble() ?? 0.0,
      tieneDescuento: json['tiene_descuento'] as bool? ?? false,
      promocion: json['promocion'] as String?,
      imagen: json['imagen'] as String?,
      imagenes: (json['imagenes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList() ??
          const [],
      descripcion: json['descripcion'] as String?,
      enlace: json['enlace'] as String?,
      supermercado: json['supermercado'] as String? ?? 'Súper Selectos',
      codigoBarra: json['codigo_barra'] as String?,
      categoria: json['categoria'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'precio': precio,
      'precio_final': precioFinal,
      'precio_original': precioOriginal,
      'descuento': descuento,
      'tiene_descuento': tieneDescuento,
      'promocion': promocion,
      'imagen': imagen,
      if (imagenes.isNotEmpty) 'imagenes': imagenes,
      if (descripcion != null) 'descripcion': descripcion,
      'enlace': enlace,
      'supermercado': supermercado,
      if (codigoBarra != null) 'codigo_barra': codigoBarra,
      if (categoria != null) 'categoria': categoria,
    };
  }

  Product copyWith({
    String? id,
    String? nombre,
    double? precio,
    double? precioFinal,
    double? precioOriginal,
    double? descuento,
    bool? tieneDescuento,
    String? promocion,
    String? imagen,
    List<String>? imagenes,
    String? descripcion,
    String? enlace,
    String? supermercado,
    String? codigoBarra,
    String? categoria,
  }) {
    return Product(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      precio: precio ?? this.precio,
      precioFinal: precioFinal ?? this.precioFinal,
      precioOriginal: precioOriginal ?? this.precioOriginal,
      descuento: descuento ?? this.descuento,
      tieneDescuento: tieneDescuento ?? this.tieneDescuento,
      promocion: promocion ?? this.promocion,
      imagen: imagen ?? this.imagen,
      imagenes: imagenes ?? this.imagenes,
      descripcion: descripcion ?? this.descripcion,
      enlace: enlace ?? this.enlace,
      supermercado: supermercado ?? this.supermercado,
      codigoBarra: codigoBarra ?? this.codigoBarra,
      categoria: categoria ?? this.categoria,
    );
  }
}
