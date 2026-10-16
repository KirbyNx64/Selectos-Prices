import 'package:flutter_test/flutter_test.dart';
import 'package:super_selectos/models/product.dart';
import 'package:super_selectos/models/shopping_cart_item.dart';

void main() {
  ShoppingCartItem itemWithQuantity(int quantity) {
    return ShoppingCartItem(
      key: 'sopa-maggi',
      quantity: quantity,
      product: const Product(
        id: 'sopa-maggi',
        nombre: 'Sopa Maggi',
        precioFinal: 0.40,
        promocion: 'Seleccione 4X\$1.25',
      ),
    );
  }

  ShoppingCartItem twoForOneItem(int quantity) {
    return ShoppingCartItem(
      key: 'protex',
      quantity: quantity,
      product: const Product(
        id: '114865',
        nombre: '6 pack Jabón de Tocador Protex',
        precioFinal: 6.40,
        promocion: '2X1',
      ),
    );
  }

  ShoppingCartItem secondUnitDiscountItem(int quantity) {
    return ShoppingCartItem(
      key: 'terso',
      quantity: quantity,
      product: const Product(
        id: '124037',
        nombre: 'Suavizante Terso Elixir Floral Alegre Temporada 2 L',
        precioFinal: 4.60,
        promocion: '2ª unidad con 75% de descuento',
      ),
    );
  }

  group('ShoppingCartItem quantity promotion', () {
    test('parses the quantity and bundle price', () {
      final promotion = itemWithQuantity(1).quantityPromotion;

      expect(promotion, isNotNull);
      expect(promotion!.quantity, 4);
      expect(promotion.price, 1.25);
    });

    test('charges individual units until completing a bundle', () {
      expect(itemWithQuantity(3).subtotal, closeTo(1.20, 0.0001));
    });

    test('applies the bundle price and charges remaining units normally', () {
      expect(itemWithQuantity(4).subtotal, closeTo(1.25, 0.0001));
      expect(itemWithQuantity(5).subtotal, closeTo(1.65, 0.0001));
      expect(itemWithQuantity(8).subtotal, closeTo(2.50, 0.0001));
    });

    test('keeps the regular calculation when the promotion is invalid', () {
      const item = ShoppingCartItem(
        key: 'regular',
        quantity: 4,
        product: Product(
          id: 'regular',
          nombre: 'Producto regular',
          precioFinal: 0.40,
          promocion: 'Oferta especial',
        ),
      );

      expect(item.quantityPromotion, isNull);
      expect(item.subtotal, closeTo(1.60, 0.0001));
    });
  });

  group('ShoppingCartItem take-and-pay promotion', () {
    test('parses a 2X1 promotion without confusing bundle prices', () {
      final promotion = twoForOneItem(1).takeAndPayPromotion;

      expect(promotion, isNotNull);
      expect(promotion!.takeQuantity, 2);
      expect(promotion.payQuantity, 1);
      expect(itemWithQuantity(1).takeAndPayPromotion, isNull);
    });

    test('charges one unit for every started pair', () {
      expect(twoForOneItem(1).subtotal, closeTo(6.40, 0.0001));
      expect(twoForOneItem(2).subtotal, closeTo(6.40, 0.0001));
      expect(twoForOneItem(3).subtotal, closeTo(12.80, 0.0001));
      expect(twoForOneItem(4).subtotal, closeTo(12.80, 0.0001));
    });

    test('reports savings only after completing a promotional pair', () {
      expect(twoForOneItem(1).promotionSavings, 0);
      expect(twoForOneItem(2).promotionSavings, closeTo(6.40, 0.0001));
      expect(twoForOneItem(3).promotionSavings, closeTo(6.40, 0.0001));
      expect(twoForOneItem(4).promotionSavings, closeTo(12.80, 0.0001));
    });
  });

  group('ShoppingCartItem second-unit discount promotion', () {
    test('parses the discount percentage', () {
      final promotion = secondUnitDiscountItem(1).secondUnitDiscountPromotion;

      expect(promotion, isNotNull);
      expect(promotion!.discountPercent, 75);
    });

    test('discounts every second unit in each pair', () {
      expect(secondUnitDiscountItem(1).subtotal, closeTo(4.60, 0.0001));
      expect(secondUnitDiscountItem(2).subtotal, closeTo(5.75, 0.0001));
      expect(secondUnitDiscountItem(3).subtotal, closeTo(10.35, 0.0001));
      expect(secondUnitDiscountItem(4).subtotal, closeTo(11.50, 0.0001));
    });

    test('reports the accumulated savings', () {
      expect(secondUnitDiscountItem(1).promotionSavings, 0);
      expect(secondUnitDiscountItem(2).promotionSavings, closeTo(3.45, 0.0001));
      expect(secondUnitDiscountItem(4).promotionSavings, closeTo(6.90, 0.0001));
    });
  });
}
