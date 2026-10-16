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
}
