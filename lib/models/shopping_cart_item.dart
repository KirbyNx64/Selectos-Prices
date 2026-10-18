import 'dart:convert';

import 'package:super_selectos/models/product.dart';

class QuantityPromotion {
  final int quantity;
  final double price;

  const QuantityPromotion({required this.quantity, required this.price});

  static QuantityPromotion? tryParse(String? label) {
    if (label == null || label.trim().isEmpty) return null;

    final match = RegExp(r'(\d+)\s*[xX]\s*\$\s*(\d+(?:[\.,]\d+)?)')
        .firstMatch(label);
    if (match == null) return null;

    final quantity = int.tryParse(match.group(1)!);
    final price = double.tryParse(match.group(2)!.replaceAll(',', '.'));
    if (quantity == null || quantity <= 0 || price == null || price < 0) {
      return null;
    }

    return QuantityPromotion(quantity: quantity, price: price);
  }
}

/// Promotion where the customer takes [takeQuantity] units but only pays for
/// [payQuantity] of them (for example, `2X1`).
class TakeAndPayPromotion {
  final int takeQuantity;
  final int payQuantity;

  const TakeAndPayPromotion({
    required this.takeQuantity,
    required this.payQuantity,
  });

  static TakeAndPayPromotion? tryParse(String? label) {
    if (label == null || label.trim().isEmpty) return null;

    // The negative lookahead prevents price promotions such as `4X$1.25`
    // from being interpreted as "take 4 and pay 1".
    final match = RegExp(r'(?<!\d)(\d+)\s*[xX]\s*(?!\$)(\d+)(?![\d.,])')
        .firstMatch(label);
    if (match == null) return null;

    final takeQuantity = int.tryParse(match.group(1)!);
    final payQuantity = int.tryParse(match.group(2)!);
    if (takeQuantity == null ||
        payQuantity == null ||
        takeQuantity <= 1 ||
        payQuantity <= 0 ||
        payQuantity >= takeQuantity) {
      return null;
    }

    return TakeAndPayPromotion(
      takeQuantity: takeQuantity,
      payQuantity: payQuantity,
    );
  }

  int chargedUnitsFor(int quantity) {
    final completeGroups = quantity ~/ takeQuantity;
    final remainingUnits = quantity % takeQuantity;
    return (completeGroups * payQuantity) +
        (remainingUnits < payQuantity ? remainingUnits : payQuantity);
  }
}

/// Promotion that discounts every second unit by [discountPercent].
class SecondUnitDiscountPromotion {
  final int discountPercent;

  const SecondUnitDiscountPromotion({required this.discountPercent});

  static SecondUnitDiscountPromotion? tryParse(String? label) {
    if (label == null || label.trim().isEmpty) return null;

    final match = RegExp(
      r'(?:2\s*(?:da|do|[ªº])?|segund[ao])(?:\s+unidad)?[^\d%]{0,30}(\d{1,3})\s*%',
      caseSensitive: false,
    ).firstMatch(label);
    if (match == null) return null;

    final discountPercent = int.tryParse(match.group(1)!);
    if (discountPercent == null ||
        discountPercent <= 0 ||
        discountPercent >= 100) {
      return null;
    }

    return SecondUnitDiscountPromotion(discountPercent: discountPercent);
  }

  int discountedUnitsFor(int quantity) => quantity ~/ 2;
}

String compactPromotionLabel(String label) {
  final quantityDeal = QuantityPromotion.tryParse(label);
  if (quantityDeal != null) {
    return '${quantityDeal.quantity}x\$${quantityDeal.price.toStringAsFixed(2)}';
  }

  final takeAndPayDeal = TakeAndPayPromotion.tryParse(label);
  if (takeAndPayDeal != null) {
    return '${takeAndPayDeal.takeQuantity}x${takeAndPayDeal.payQuantity}';
  }

  final secondUnitDeal = SecondUnitDiscountPromotion.tryParse(label);
  if (secondUnitDeal != null) {
    return '2.ª -${secondUnitDeal.discountPercent}%';
  }

  return label;
}

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

  double get regularUnitPrice {
    final originalPrice = product.precioOriginal;
    if (originalPrice != null && originalPrice > unitPrice) {
      return originalPrice;
    }
    if (product.tieneDescuento && product.descuento > 0) {
      return unitPrice + product.descuento;
    }
    return unitPrice;
  }

  double get unitDiscount {
    final discount = regularUnitPrice - unitPrice;
    return discount > 0 ? discount : 0;
  }

  QuantityPromotion? get quantityPromotion =>
      QuantityPromotion.tryParse(product.promocion);

  TakeAndPayPromotion? get takeAndPayPromotion =>
      TakeAndPayPromotion.tryParse(product.promocion);

  SecondUnitDiscountPromotion? get secondUnitDiscountPromotion =>
      SecondUnitDiscountPromotion.tryParse(product.promocion);

  int get appliedPromotionBundles {
    final quantityDeal = quantityPromotion;
    if (quantityDeal != null) return quantity ~/ quantityDeal.quantity;

    final takeAndPayDeal = takeAndPayPromotion;
    if (takeAndPayDeal != null) {
      return quantity ~/ takeAndPayDeal.takeQuantity;
    }

    final secondUnitDeal = secondUnitDiscountPromotion;
    return secondUnitDeal == null
        ? 0
        : secondUnitDeal.discountedUnitsFor(quantity);
  }

  double get regularSubtotal => regularUnitPrice * quantity;

  double get discountedSubtotal => unitPrice * quantity;

  double get subtotal {
    final quantityDeal = quantityPromotion;
    if (quantityDeal != null) {
      final bundles = quantity ~/ quantityDeal.quantity;
      final remainingUnits = quantity % quantityDeal.quantity;
      return (bundles * quantityDeal.price) + (remainingUnits * unitPrice);
    }

    final takeAndPayDeal = takeAndPayPromotion;
    if (takeAndPayDeal != null) {
      return takeAndPayDeal.chargedUnitsFor(quantity) * unitPrice;
    }

    final secondUnitDeal = secondUnitDiscountPromotion;
    if (secondUnitDeal != null) {
      final discountPerUnit =
          unitPrice * (secondUnitDeal.discountPercent / 100);
      return discountedSubtotal -
          (secondUnitDeal.discountedUnitsFor(quantity) * discountPerUnit);
    }

    return discountedSubtotal;
  }

  double get promotionSavings {
    final savings = discountedSubtotal - subtotal;
    return savings > 0 ? savings : 0;
  }

  double get totalSavings {
    final savings = regularSubtotal - subtotal;
    return savings > 0 ? savings : 0;
  }

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
